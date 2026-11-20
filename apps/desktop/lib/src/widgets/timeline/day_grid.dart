// =============================================================================
// 方格时间轴 · 18×4 网格本体
// =============================================================================
// 为什么背景用 `CustomPaint` 而不是 72 个 `InkWell`：
//   72 个可聚焦控件会把 Tab 序列撑成一场灾难，而且每格一个 `InkWell` 的
//   命中测试开销与重建面积都远超收益。这里只有**一个**右键入口 + **一个**
//   `DragTarget`，坐标由像素反算分钟。
//
// 为什么条目单独一层 `Positioned`：
//   格子是 15 分钟的**刻度**，条目是**连续区间**。两者混在一层会让「条目
//   跨格」这件事变得表达不出来。
// =============================================================================

import 'package:core_data/core_data.dart' show weekdayLabel;
import 'package:core_db/core_db.dart';
// `core_data` 与 `core_domain` 都导出 `weekdayLabel`：前者收日期字符串
// （`calendar.dart`），后者收 ISO 星期数（`recurring_task.dart`）。表头要的是
// 「日期 → 周三」，所以留前者、隐掉后者。
import 'package:core_domain/core_domain.dart' hide weekdayLabel;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../providers_p1.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../day_timeline.dart';
import '../focus_ring.dart';
import '../ledger_checkbox.dart';
import '../priority_hover_bubble.dart';
import 'plan_item_detail_dialog.dart';
import 'slot_context_menu.dart';
import 'slot_fill.dart';
import 'slot_layout.dart';
import 'slot_range_dialog.dart';
import 'slot_state.dart';
import 'timeline_store.dart';

/// 四态 → 底色。绘制层只做这一处映射，判定顺序在 `slot_state.dart`。
///
/// 颜色由调用方传入（`build` 顶部取一次 `context.tokens`）：`CustomPainter`
/// 与条目外壳都要用它，而它们都不该各自去碰 `BuildContext`。
Color colorOfSlotKind(SlotKind kind, ThemeTokens tokens) => switch (kind) {
  SlotKind.habit => tokens.slotHabit,
  SlotKind.backfill => tokens.slotBackfill,
  SlotKind.done => tokens.slotDone,
  SlotKind.plannedOpen => tokens.slotPlan,
};

/// 条目正文的最小可排版宽度。
///
/// 为什么需要它：条目宽度现在由「起始分钟 → 列」决定（`slot_layout.dart` 的
/// `col`）。窄视口下 15 分钟只占 `658 / 4 = 164.5px`，减掉左右各 2px 缝与
/// 内边距 8px 只剩 152.5px；而正文那串**不可压缩**的子项（复选框 22 +
/// 起始时刻 50 + 字形 11 + 习惯回填徽标 50 及各处 3–6px 间隔）在测试字体
/// （Ahem，每字符宽 = 字号）下就要 180px 左右，`Row` 会在窄档当场
/// `RenderFlex overflowed`。
///
/// 260 = 上述工况（再算上优先级标记）留足呼吸的**上限**。Task 45 · W2 把
/// 「未分级 30 + 状态词 20 + 删除 30」从正文里删掉后实际需求降到 180 左右，
/// 但这里**不下调**：宽视口（1400 ⇒ 内宽 262.5）本来就走 `maxWidth` 原值、
/// 逐像素不变；窄档与 2 倍字号档多裁一点，比让 `Row` 溢出安全。
const double kChipContentMinWidth = 260;

/// 纵轴小时 / 横轴分钟的方格时间轴。
///
/// 数据全部走现有 provider；只有真正发生写操作时才去碰 `TimelineStore`，
/// 所以纯渲染路径不需要数据库（widget 测试因此可以裸 pump）。
class DayGrid extends ConsumerStatefulWidget {
  /// 创建网格。
  const DayGrid({super.key, required this.date, this.minimal = false});

  /// 所属日期（`YYYY-MM-DD`）。
  final String date;

  /// 极简模式：只藏条目的次级信息（进展串），不藏数据。
  ///
  /// 「今日计划」段删掉后，页头的极简/完整开关只剩这一个可见回落；
  /// 没有它这个开关就是假按钮。
  final bool minimal;

  @override
  ConsumerState<DayGrid> createState() => _DayGridState();
}

class _DayGridState extends ConsumerState<DayGrid> {
  final GlobalKey _gridKey = GlobalKey();

  /// 最近一次 build 的条目，供拖动/右键反查时长。
  List<GridEntry> _entries = const <GridEntry>[];

  /// 最近一次 build 的布局（行高 + 车道 + 段）。
  ///
  /// 存成字段而不是每次现算：`_minuteAt` 在右键 / 拖放回调里要用它做
  /// 「像素 → 分钟」，而那时 `build` 的局部变量已经不在了。它与 [_entries]
  /// 同为「上一次渲染的输入」，两者永远同步更新。
  SlotLayout? _layout;

  /// 写操作串行化，避免连点产生重复行。
  bool _busy = false;

  TimelineStore? _store;

  TimelineStore get _storeOf =>
      _store ??= TimelineStore(ref.read(repositoriesProvider));

  /// 最近一次 build 的计划行原始数据，供条目按 id 反查状态 / 进展串。
  List<PlanItemData> _rows = const <PlanItemData>[];

  /// 选中日是否晚于今天（未来日只可预排：不可勾选、不回填）。
  ///
  /// Task 45 · W6 收窄了它的作用面：**只拦「完成 / 打勾」类动作**
  /// （[_toggleStatus]）。编辑与删除搬进详情窗后，未来日若仍拦
  /// [_openDetail]，预排的条目就既改不了级别 / 内容 / 时长、也删不掉 ——
  /// 与 [_setQuadrant] 既有口径（分级不拦未来日）自相矛盾。
  bool _future = false;

  /// 极简模式的当前值（见 [DayGrid.minimal]）。
  bool _minimal = false;

  /// 每个条目一个稳定焦点节点：条目会被拖动/重建，节点不能跟着重建。
  final Map<String, FocusNode> _rowNodes = <String, FocusNode>{};

  FocusNode _nodeFor(String id) =>
      _rowNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'grid-row-$id'));

  PlanItemData? _rowOf(String id) {
    for (final PlanItemData row in _rows) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  @override
  void dispose() {
    for (final FocusNode node in _rowNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(planItemsProvider).asData?.value;
    final String todayIso = ref.watch(todayProvider);
    final DayWindow win = ref.watch(dayWindowProvider);
    if (items == null) {
      return SizedBox(height: win.height);
    }
    final int? nowMinute = widget.date == todayIso ? _nowMinute() : null;
    // 颜色只在 build 这里取一次，往下按参数传：`CustomPainter` 与条目外壳都不碰
    // `BuildContext`，一次 build 内的整棵子树拿到的是同一份 token。
    final ThemeTokens t = context.tokens;
    _rows = items;
    _future = widget.date.compareTo(todayIso) > 0;
    _minimal = widget.minimal;
    _entries = gridEntriesOf(
      items,
      date: widget.date,
      todayIso: todayIso,
      nowMinute: nowMinute ?? -1,
    );
    // 并发车道与行高都在这一处算完：刻度尺、格线、条目、右键落点全部从这里
    // 取几何，任何一方另起换算都会让「起始分钟」与「横轴坐标」重新分叉。
    final SlotLayout layout = layoutSlots(win, _entries);
    _layout = layout;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double axisWidth = tlWidthFor(box.maxWidth);
        final double axisGap = tlGapFor(box.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _headerStrip(axisWidth, axisGap, t),
            const SizedBox(height: 6),
            // 表头的「表格感」来自一条下沿发丝线，而不是多套一层容器：
            // 线用 `hair`，与格子区边框同阶，不引入新色。
            Container(height: 1, color: t.hair),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: axisWidth,
                  height: layout.totalHeight,
                  child: _axis(layout, t),
                ),
                SizedBox(width: axisGap),
                Expanded(
                  child: _gridArea(
                    layout,
                    box.maxWidth - axisWidth - axisGap,
                    t,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 表头带：日期落在最左单元格，右侧留给条目列。
  ///
  /// 为什么是「表头 + 复用同一套列宽」而不是 `Table`：`Table` 会把整棵子树的
  /// 约束重算一遍，格子区那套 `Stack` + `Positioned` + 像素反算分钟的坐标体系
  /// （见文件头）会跟着漂。这里只复用 body 的同一组列宽（[tlWidthFor] /
  /// [tlGapFor]），表头第一列与刻度列天然同宽、同左缘。
  ///
  /// 为什么左缘不留任何边距：`_TodayBody`（`today_page.dart`）的各个 section 都
  /// 是内容列的直接子节点、自己不设横向 padding，页面级左右内边距由外层
  /// `LedgerPaper`（`ledger_paper.dart`）统一给。所以「与今日页主体左对齐」
  /// 就等于从内容列 x=0 起画 —— 在这里再造一个近似 padding 只会把表头推歪。
  Widget _headerStrip(double axisWidth, double axisGap, ThemeTokens t) {
    final String weekday = weekdayLabel(widget.date);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        // 最左单元格 = 日期。`minWidth` 与刻度列同源（轴宽 + 轴右间隙），所以它
        // 落在「最左列」这一列宽体系内；日期文本按内容自然增长，但**绝不反向
        // 压缩**刻度列（`_axis` 的宽度在调用点就是定值）。
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: axisWidth + axisGap),
          child: Container(
            key: const ValueKey<String>('day-grid-header-date'),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              // 底色只用既有 token：`accentWash` 是纸面上唯一的暖色浅底，与四态
              // 格底（slotPlan / slotHabit / slotBackfill / slotDone）明显不同。
              // `slot_state.dart` 的赭石纪律只约束四态**前景色**，不约束表头底。
              color: t.accentWash,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: t.hair),
            ),
            child: Text(
              weekday.isEmpty ? widget.date : '${widget.date} $weekday',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                color: t.ink,
              ),
            ),
          ),
        ),
        // 第二单元格留白：这里**不能**写字。四态状态词里 `plannedOpen` 的文案
        // 就是「计划」，表头再写一遍会让域外测试的 `find.text('计划')` 命中两个。
        const Expanded(child: SizedBox()),
      ],
    );
  }

  /// 全天刻度尺（06:00–24:00）：连续竖轴 + 整点/半点双档刻度 + `晨`/`午`/`晚`。
  ///
  /// 竖轴与刻度由 [_RulerPainter] 画（纯装饰，不进语义树），小时数字与锚标仍是
  /// 真 `Text`。三者共用 `kGridRows` / `kHourRowHeight` / `kGridStartHour` 这一套
  /// 基准，和格子区逐行对齐 —— 不另起一份换算，否则刻度尺会随视口漂移。
  ///
  /// 锚标为什么排在整点数字**下方**而不是原型那样放在轴右侧：轴列在窄视口只有
  /// 52px（`tlWidthNarrow`），横排「晨 + 06:00」必然撑出 `RenderFlex`；竖排只是
  /// 读序变了，三锚与三个整点仍一一对应。
  ///
  /// 为什么用 `Stack` 而不是 `Column` + `SizedBox` 堆行：`Positioned` 子节点不参与
  /// `RenderFlex` 的溢出判定，测试字体（每字符等宽方块）把 `06:00` 折成多行时
  /// 只会被裁掉，不会把「看不全」变成一条测试错误。
  Widget _axis(SlotLayout layout, ThemeTokens t) {
    // 窗口仍从布局取：行数、起始整点、可见区间都还是 `DayWindow` 的语义，
    // 变的只有「每行多高、行顶在哪」——那两项必须走 [`SlotLayout`] 的实际
    // 行高表，否则并发任务撑高某一行后，刻度尺会与格线错开。
    final DayWindow win = layout.window;
    return Stack(
      key: const ValueKey<String>('day-grid-ruler'),
      children: <Widget>[
        Positioned.fill(child: CustomPaint(painter: _RulerPainter(layout, t))),
        for (int row = 0; row < win.rows; row++)
          Positioned(
            top: layout.rowTops[row],
            left: 0,
            right: 0,
            height: layout.rowHeights[row],
            child: Align(
              // 垂直居中：文本中心恒等于行中心（`row*44+22`），与右侧 8px
              // 短横线同一条水平中轴。用 `center` 而不是 `top`，是为了不管
              // 测试字体把 `06:00` 折成几行，中心都还是行中心 —— 这样
              // 「数字与短线对齐」才能被几何断言（|Δy| ≤ 2px），而不是靠肉眼。
              alignment: Alignment.centerRight,
              child: Padding(
                // 右侧让出刻度长度（6px）+ 呼吸，数字不压在刻度上。
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  formatMinute(win.startMinute + row * 60),
                  key: ValueKey<String>('day-grid-hour-${win.startHour + row}'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    color: t.faint,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        // 三段起点标记：**只留 8px 短横线，「晨 / 午 / 晚」文字已移除**。
        // 三个时段的名字在段头（`晚 · 复盘与心态`）与复盘区已有语言表达，
        // 52px 宽的窄轴上再写一遍只会把整列撑满，且与 06:00 数字抢同一行。
        // 短横线用绝对 `top` 直接落在行中心：`row*44 + (44-1)/2` ⇒ 中心恰为
        // `row*44 + 22`，与整点数字的 `centerRight` 中心同值，无需再套一层
        // 测量链（避免 `IntrinsicHeight`/`LayoutBuilder` 那类布局坑）。
        // 短横线用绝对 `top` 直接落在**该行**中心：`rowTops[row] +
        // (rowHeights[row]-1)/2`。并发把某行撑到 66px 后，中心也跟着下移
        // 半个增量 —— 与整点数字的 `centerRight` 中心仍同值。
        for (final int hour in _kSegmentStartHours)
          if (win.contains(hour * 60))
            Positioned(
              top:
                  layout.yOfMinute(hour * 60) +
                  (layout.rowHeights[layout.rowOfMinute(hour * 60)] - 1) / 2,
              left: 0,
              child: Container(
                key: ValueKey<String>('day-grid-segment-mark-$hour'),
                width: 8,
                height: 1,
                color: t.hairStrong,
              ),
            ),
      ],
    );
  }

  /// 三段起点（06:00 / 12:00 / 18:00）的整点小时数。
  ///
  /// 与格子区三段底色的切分点**同一份真源**（[_segmentTintsOf] 的顺序即本表
  /// 的顺序）：改这里就得改那里，否则短横线会落在色带之外，标记与底色互相打脸。
  static const List<int> _kSegmentStartHours = <int>[6, 12, 18];

  /// 三段底色，顺序与 [_kSegmentStartHours] 一一对应（06–12 / 12–18 / 18–24）。
  ///
  /// 只取既有中性阶（`card` / `paper` / `sunken`），不新造 hex、不引入新色相；
  /// 赭石在方格区仍然禁用。差异刻意轻微：这是「分区提示」，不是三块卡片。
  ///
  /// 为什么是函数而不是 `static const`：深色主题下这三段底色必须跟着
  /// `ThemeTokens` 换，运行期颜色进不了编译期常量表。
  static List<Color> _segmentTintsOf(ThemeTokens t) => <Color>[
    t.gridSectionMorning,
    t.gridSectionNoon,
    t.gridSectionEvening,
  ];

  Widget _gridArea(SlotLayout layout, double gridOuterWidth, ThemeTokens t) {
    // 段矩形的横轴换算要用**内容区**宽度：`day-grid` 这个 `Container` 的 1px
    // 边框左右各吃 1px，组件堆里所有条目与列线都画在边框之内。
    final double gridWidth = gridOuterWidth - 2 < 0 ? 0 : gridOuterWidth - 2;
    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) =>
          _onContextMenu(_minuteAt(details.localPosition)),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (DragTargetDetails<String> details) =>
            details.data.contains(':'),
        onAcceptWithDetails: (DragTargetDetails<String> details) =>
            _onDrop(details.data, details.offset),
        builder:
            (
              BuildContext context,
              List<String?> candidate,
              List<dynamic> rejected,
            ) {
              return Container(
                key: const ValueKey<String>('day-grid'),
                height: layout.totalHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(
                    color: candidate.isEmpty ? t.hair : t.hairStrong,
                  ),
                ),
                child: Stack(
                  key: _gridKey,
                  children: <Widget>[
                    // 三段底色必须在**最底层**（Stack 第一子层）。
                    // `_SlotPainter` 的绘制顺序是「先格填充、后网格线」；若把底色
                    // 插在两者之间（brief 字面的「填充之下、线之上」），1px 网格线
                    // 会被整片盖掉。放第一子层后：底色在格填充之下 ✅、网格线仍可见 ✅，
                    // 且命中测试仍落在格填充上（底色不参与 hit-test）。
                    // 高度取布局总高（而不是 `Positioned.fill` 的内容区高度）：
                    // 色带与格线必须共用同一套 `rowTops` 坐标；差那 1px 边框就会
                    // 让色带边界与格线错开。多出的 1–2px 由 `Stack` 的硬裁切吃掉
                    // （`Stack` 不像 `RenderFlex` 那样断言溢出），视觉上只是最后
                    // 一段色带的底边贴着容器边框。
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: layout.totalHeight,
                      child: Column(
                        key: const ValueKey<String>('day-grid-section-tint'),
                        children: _sectionTintChildren(layout, t),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SlotPainter(_entries, layout, t),
                      ),
                    ),
                    // 条目按**段**渲染（一条条目跨行时切成多段），不再整条满宽
                    // 占位：左缘由起点分钟换算的列决定，纵向落位由车道决定。
                    for (final SlotSegment seg in layout.segments)
                      _segmentTile(seg, layout, gridWidth, t),
                    if (_entries.isEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 12,
                        child: Text(
                          '右键任意一格开始排期',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: t.faint),
                        ),
                      ),
                  ],
                ),
              );
            },
      ),
    );
  }

  /// 分段底衬：`0–6` 用 `card` 打底，`06–12 / 12–18 / 18–24` 用 [_kSegmentTints]。
  ///
  /// 只画与 [win] 可见区间相交的部分，高度直接问布局要像素（[SlotLayout.yOfMinute]），
  /// 因此默认窗口 `06–24` 得到 `360 / 360 / 360`（与参数化之前的三等分
  /// 逐像素一致），窗口收窄到 `09–18` 则得到 `180 / 360`，比例天然正确。
  List<Widget> _sectionTintChildren(SlotLayout layout, ThemeTokens t) {
    final List<Widget> children = <Widget>[];
    final List<Color> tints = _segmentTintsOf(t);
    final DayWindow win = layout.window;
    for (int i = -1; i < tints.length; i++) {
      final int segStartHour = i < 0 ? 0 : _kSegmentStartHours[i];
      final int segEndHour = i + 1 < _kSegmentStartHours.length
          ? _kSegmentStartHours[i + 1]
          : 24;
      final int from = segStartHour * 60 > win.startMinute
          ? segStartHour * 60
          : win.startMinute;
      final int to = segEndHour * 60 < win.endMinute
          ? segEndHour * 60
          : win.endMinute;
      if (to <= from) {
        continue;
      }
      // 显式高度而不是 `Expanded(flex: 分钟数)`：并发会把某一行撑高，
      // 「按分钟数等分」只在所有行同高时才与色带边界重合。这里直接问布局要
      // 两端像素，色带因此永远与格线对齐。
      final double top = layout.yOfMinute(from);
      final double bottom = layout.yOfMinute(to);
      children.add(
        SizedBox(
          width: double.infinity,
          height: bottom - top < 0 ? 0 : bottom - top,
          child: ColoredBox(color: i < 0 ? t.card : tints[i]),
        ),
      );
    }
    return children;
  }

  /// 一条**段**的落位：横向由「起点分钟 → 列」决定，纵向由「车道 → 行内偏移」决定。
  ///
  /// 为什么按段画而不是按条目画：一条 09:50–10:20 的条目跨两行，两行的实际
  /// 高度可能不同（并发只撑高了其中一行），单一矩形表达不了；切成两段后每段
  /// 各自落在自己的行里，行高怎么变都不会错位。
  ///
  /// 只有 head 段挂正文与行级焦点（见 [SlotSegment.isHead]）。续段画成同色
  /// 空壳、只负责「跨行不断线」：同一条目挂两个 `Focus` 会抢同一个 `FocusNode`
  /// （`_nodeFor(id)` 按 id 缓存），Tab 序里就会出现焦点跳两次的怪象。
  Widget _segmentTile(
    SlotSegment seg,
    SlotLayout layout,
    double gridWidth,
    ThemeTokens t,
  ) {
    final GridEntry entry = seg.entry;
    final Rect rect = layout.tileRect(seg, gridWidth);
    // head 段沿用并发之前的 key（`day-grid-entry-<id>`），续段另起后缀：
    // 既有断言按 id 取到的是「条目第一段」的矩形，语义没变。
    final String key = seg.isHead
        ? 'day-grid-entry-${entry.id}'
        : 'day-grid-entry-${entry.id}-seg-${seg.row}';
    final Widget shell = _chipShell(
      entry,
      t,
      keyValue: key,
      live: seg.isHead,
      showBody: seg.isHead,
    );
    return Positioned(
      top: rect.top,
      left: rect.left,
      width: rect.width < 0 ? 0 : rect.width,
      height: rect.height < 0 ? 0 : rect.height,
      child: seg.isHead
          ? Draggable<String>(
              data: 'plan:${entry.id}',
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 180,
                  child: _chipShell(
                    entry,
                    t,
                    keyValue: key,
                    live: false,
                    showBody: true,
                  ),
                ),
              ),
              child: GestureDetector(
                onDoubleTap: () => _editRange(entry),
                child: shell,
              ),
            )
          : shell,
    );
  }

  /// 条目外壳：四态底色 + 左缘 2px 竖条 + 圆角 + 细边。
  ///
  /// 内容用 `OverflowBox` 拿到自然高度、再由 `ClipRect` 裁掉：15 分钟格只有
  /// 20px 可用，而复选框自己就 22px —— 直接塞进有界约束会触发
  /// 「RenderFlex overflowed」，把「看不全」变成一条测试错误。
  ///
  /// 竖条为什么用**边框**画而不是 `Row` 里的一个 `Container`：边框天然贴在
  /// 外壳最左缘（含圆角），不受 `padding` 影响，也不会被内层 `ClipRect` 裁掉。
  /// 代价是 `BoxBorder` 不允许「非均匀颜色 + `borderRadius`」同时出现
  /// （`box_border.dart` 里有明确断言），所以圆角改由外层 `ClipRRect` 提供 ——
  /// 视觉半径仍是 `AppTokens.radius`，断言也不会触发。
  Widget _chipShell(
    GridEntry entry,
    ThemeTokens t, {
    required String keyValue,
    required bool live,
    bool showBody = true,
  }) {
    final Widget body = showBody ? _chipBody(entry, t) : const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: ValueKey<String>(keyValue),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: colorOfSlotKind(entry.kind, t),
          border: Border(
            left: BorderSide(
              color: foregroundOfSlotKind(entry.kind, t),
              width: 2,
            ),
            top: BorderSide(color: t.hair),
            right: BorderSide(color: t.hair),
            bottom: BorderSide(color: t.hair),
          ),
        ),
        child: ClipRect(
          // 宽度保底：窄条目（15 分钟只占一列，内宽可能一百五十来像素）装不下
          // 「勾选框 + 四维标记 + 标题」这串不可压缩的固定子项，`Row` 会溢出。
          // 这里给内容一个**固定**宽度（`min == max`，只增不减），右端交给外层
          // `ClipRect` 裁掉：文本节点仍在树里、内容一个不少，只是被切断 ——
          // 比隐藏内容或缩字号更守既有 token 纪律。宽条目（内宽已 ≥ 该值）
          // 走的是 `maxWidth` 原值，逐像素不变。
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final double width = box.maxWidth < kChipContentMinWidth
                  ? kChipContentMinWidth
                  : box.maxWidth;
              return OverflowBox(
                maxHeight: double.infinity,
                minWidth: width,
                maxWidth: width,
                alignment: Alignment.centerLeft,
                child: live ? _liveBody(entry, body) : body,
              );
            },
          ),
        ),
      ),
    );
  }

  /// 可交互外壳：`Space` 切勾选、`Enter` 开详情、点整条开详情。
  ///
  /// 语义直接沿用被删掉的「今日计划」行（`_PlanItemTile`）：行级焦点 +
  /// `requirePrimaryFocus` 的焦点环，焦点落到复选框上时行环**不**跟着亮。
  ///
  /// Task 45 · W2：`Enter` / 左键的目标从「成果 / 进展」回填层改成**任务详情
  /// 窗**。意图类名仍是 [OpenSlotResultIntent]（`slot_fill.dart` 不归本波次
  /// 改），但它的**消费端**已经换成本窗 —— 回填能力没有被删，只是搬进了详情
  /// 窗（回填内容框 + 「成果 / 进展模板」按钮）。
  Widget _liveBody(GridEntry entry, Widget body) {
    final FocusNode node = _nodeFor(entry.id);
    return Actions(
      actions: <Type, Action<Intent>>{
        ToggleSlotStatusIntent: CallbackAction<ToggleSlotStatusIntent>(
          onInvoke: (_) {
            _toggleStatus(entry);
            return null;
          },
        ),
        OpenSlotResultIntent: CallbackAction<OpenSlotResultIntent>(
          onInvoke: (_) {
            _openDetail(entry);
            return null;
          },
        ),
      },
      child: Focus(
        key: ValueKey<String>('plan-row-focus-${entry.id}'),
        focusNode: node,
        // 行级焦点对**所有**日子开放：焦点本身不是「做完了」的记录，
        // 而 `Enter` 是详情窗的键盘入口（未来日也要能编辑 / 删除）。
        // 「未来日不可勾选」由 `LedgerCheckbox` 的 `onChanged: null` 与
        // [_toggleStatus] 的双重守卫保证。
        canRequestFocus: true,
        onKeyEvent: (FocusNode target, KeyEvent event) =>
            _onKey(target, event, entry),
        child: FocusRing(
          focusNode: node,
          requirePrimaryFocus: true,
          ringKey: const ValueKey<String>('focus-ring-border-plan-row'),
          child: InkWell(
            onTap: () => _openDetail(entry),
            canRequestFocus: false,
            child: body,
          ),
        ),
      ),
    );
  }

  /// 一行内容：复选框 · 四维标记 · 标题 · 起始时间 · 四态字形 · 进展 ·
  /// 习惯回填徽标。
  ///
  /// 全部单行、全部可省略，唯一会撑宽的是标题与进展（都带省略号）。
  ///
  /// Task 45 · W2 从这里移除三样东西（用户当轮需求 2 前半）：**状态词**
  /// （`stateLabelOfSlotKind` 的「打卡 / 回填 / 完成 / 计划」）、**「未分级」
  /// 文本**、**「删除」入口**。状态表达只留背景色 + 四态字形 + 左缘竖条；
  /// 「未分级」靠「不画标记、不留占位」表达（空白本身是信息）；删除移进
  /// 详情窗（`plan_item_detail_dialog.dart`）。
  Widget _chipBody(GridEntry entry, ThemeTokens t) {
    final PlanItemData? row = _rowOf(entry.id);
    final bool done = row?.status == PlanStatus.done.code;
    // 行里存的是码值字符串，渲染层自己解析；无法识别（未来 schema）就当作
    // 未分级 —— 不画标记，也不抛异常。
    final Quadrant? quadrant = Quadrant.fromCode(row?.quadrant);
    final String note = row?.resultNote ?? '';
    final Color ink = foregroundOfSlotKind(entry.kind, t);
    return Row(
      children: <Widget>[
        // 账页行序（方向 A）：勾选框 → 四维标记 → 标题 → mono 元信息 →
        // 四态字形 → 进展 → 习惯回填。
        // 勾选框提到最左是「账页行」与「横排芯片」的差别所在：勾是行的第一列，
        // 不是标题的尾巴。行落位仍由 15 分钟格引擎决定，真实时刻走后面的元信息。
        LedgerCheckbox(
          value: done,
          semanticLabel: entry.title,
          onChanged: _future ? null : (_) => _toggleStatus(entry),
        ),
        const SizedBox(width: 5),
        if (quadrant != null) ...<Widget>[
          // 悬停/点击标记 ⇒ 气泡说明两维取值，气泡内改选即落库
          // （字形随 `planItemsProvider` 的流自动回写）。
          PriorityHoverBubble(
            quadrant: quadrant,
            title: entry.title,
            onChanged: (Quadrant? next) => _setQuadrant(entry, next),
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: t.ink2,
              // 完成态加删除线：第三重通道，不必依赖颜色感知。
              // `decorationColor` 显式钉死该态前景色，避免继承出别的颜色。
              decoration: entry.kind == SlotKind.done
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: entry.kind == SlotKind.done ? ink : null,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // mono 元信息：起始时刻。表格数字宽度固定，条目再长也不抖。
        Text(
          formatMinute(entry.startMinute),
          style: TextStyle(
            fontSize: 10,
            color: t.faint,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
        // 故意用 `RichText` 而非 `Text`：字形字符（`\u25CB` `\u2713`
        // `\u25B6` `\u25CF`）与 `LedgerCheckbox` 自绘的勾选符是同一批码位，
        // 用 `Text` 会让既有的 `find.text('✓')` 精确计数从 1 变 2。
        // `find.text` 不匹配 `RichText`（只认 `Text` / `EditableText`），
        // 所以这里既保住了字形通道，也不污染既有断言。
        RichText(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: glyphOfSlotKind(entry.kind),
            style: TextStyle(
              fontSize: 11,
              color: ink,
              // 四个字形都不在 Inter 里，只能靠 `Noto Sans SC` 兜底；
              // 这里必须显式声明族，继承 `DefaultTextStyle` 会渲染成豆腐块。
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
            ),
          ),
        ),
        if (note.isNotEmpty && !_minimal) ...<Widget>[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '进展：$note',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: t.meta),
            ),
          ),
        ],
        if (entry.kind == SlotKind.habit) ...<Widget>[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: t.paper,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: t.hair),
            ),
            child: Text(
              '习惯回填',
              style: TextStyle(fontSize: 10, color: t.meta),
            ),
          ),
        ],
      ],
    );
  }

  /// 写操作统一入口：失败只提示、不吞掉。
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text('写入失败：$error')));
    }
  }

  Future<void> _toggleStatus(GridEntry entry) async {
    if (_future) {
      return;
    }
    final PlanItemData? row = _rowOf(entry.id);
    if (row == null) {
      return;
    }
    final bool done = row.status == PlanStatus.done.code;
    await _write(
      () => ref
          .read(repositoriesProvider)
          .planItem
          .setStatus(row.id, done ? PlanStatus.pending : PlanStatus.done),
    );
  }

  /// 改条目的四象限（`null` = 取消分级）。
  ///
  /// 与 [_toggleStatus] 的差别：**不拦未来日**（[_openDetail] 起同样不拦）。
  /// 状态是「做没做完」的事实，
  /// 未来日不该有；分级是排期前的判断，预排时就该能定下来 —— 在未来日改分级
  /// 不构成伪造记录。
  Future<void> _setQuadrant(GridEntry entry, Quadrant? quadrant) async {
    final PlanItemData? row = _rowOf(entry.id);
    if (row == null) {
      return;
    }
    await _write(
      () =>
          ref.read(repositoriesProvider).planItem.setQuadrant(row.id, quadrant),
    );
  }

  /// 打开任务详情窗（左键 / `Enter`）。
  ///
  /// 一次提交里最多同时改五列（`title` / `detail` / `quadrant` /
  /// `result_note` / `planned_start` + `planned_end`），但只写**确实变了**的
  /// 那些 —— 没改的字段不落库，避免凭空多出 oplog 条目。删除走独立分支：
  /// 详情窗里已经二次确认过（`showConfirmDialog`），这里只负责软删。
  ///
  /// **未来日只拦回填**（Task 46 · W2）：标题 / 内容 / 级别 / 持续时间 /
  /// 删除都是「排期本身的编辑」，预排时就该能改；回填（`result_note`）是
  /// 「做完了」的产物，未来日一律不落 —— 详情窗里输入框已禁用，这里再拦
  /// 一道，窗被别处放开也不会写脏。完成状态仍只由 [_toggleStatus] 管，
  /// 详情窗里没有「标记完成」按钮。
  Future<void> _openDetail(GridEntry entry) async {
    final PlanItemData? row = _rowOf(entry.id);
    if (row == null) {
      return;
    }
    // 在 `await` 之前算定：弹窗期间不保证再 build，`_future` 可能已是旧值。
    final bool isFuture = widget.date.compareTo(_todayIso) > 0;
    final PlanItemDetailResult? result = await showPlanItemDetailDialog(
      context,
      item: row,
      todayIso: _todayIso,
      defaultStart: entry.startMinute,
      defaultEnd: entry.startMinute + entry.durationMinutes,
    );
    // 弹窗期间条目可能已被别处重建/卸载，而 `_write` 要用 `ref` 与 `context`。
    if (!mounted || result == null) {
      return;
    }
    await _write(() async {
      final planItem = ref.read(repositoriesProvider).planItem;
      if (result.delete) {
        await planItem.softDelete(row.id);
        return;
      }
      if (result.title != null && result.title != row.title) {
        await planItem.setTitle(row.id, result.title!);
      }
      if (result.detail != row.detail) {
        await planItem.setDetail(row.id, result.detail);
      }
      if (result.quadrant != Quadrant.fromCode(row.quadrant)) {
        await planItem.setQuadrant(row.id, result.quadrant);
      }
      if (!isFuture && result.resultNote != row.resultNote) {
        await planItem.setResultNote(row.id, result.resultNote);
      }
      if (result.startMinute != row.plannedStart ||
          result.endMinute != row.plannedEnd) {
        await _storeOf.reschedule(
          planItemId: row.id,
          startMinute: result.startMinute,
          endMinute: result.endMinute,
        );
      }
    });
  }

  /// 条目级按键：`Space` 切勾选、`Enter` 开任务详情窗。
  ///
  /// 焦点不在条目上（落在复选框等子控件上）时让位 —— 就近优先，
  /// 复选框上的 `Space` 因此仍然只切勾选。
  KeyEventResult _onKey(FocusNode node, KeyEvent event, GridEntry entry) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (FocusManager.instance.primaryFocus != node) {
      return KeyEventResult.ignored;
    }
    final Intent intent;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        intent = const ToggleSlotStatusIntent();
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        intent = const OpenSlotResultIntent();
      default:
        return KeyEventResult.ignored;
    }
    final BuildContext? target = node.context;
    if (target != null) {
      Actions.invoke(target, intent);
    }
    return KeyEventResult.handled;
  }

  /// 像素 → 分钟：先落到 15 分钟格线，再夹进网格范围。
  int _minuteAt(Offset local) {
    final DayWindow win = ref.read(dayWindowProvider);
    final SlotLayout? layout = _layout;
    // 像素 → 分钟必须走**实际行高**表：并发把某行撑到 66px 后，等行高近似
    // 会把落点算偏。`_layout` 在 `build` 里写入，任何交互回调都晚于首帧；
    // 为 null 只可能是首帧之前的极端路径，退回等行高近似即可。
    final int raw = layout == null
        ? win.startMinute +
              (local.dy.clamp(0.0, win.height - 1) / kHourRowHeight * 60)
                  .round()
        : layout.minuteAt(local.dy);
    final int aligned = alignMinuteDown(raw);
    if (aligned < win.startMinute) {
      return win.startMinute;
    }
    return aligned > win.endMinute ? win.endMinute : aligned;
  }

  int _nowMinute() {
    final DateTime now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  /// 写入通道的「今天」：与 `build` 里派生四态读的是同一个 provider。
  ///
  /// 不在这里另算日期，是为了让「格子怎么画」与「落库打不打勾」不可能分叉。
  String get _todayIso => ref.read(todayProvider);

  /// 拖入待办 / 习惯的前置起止弹窗（两条路径共用，免得再次只改一边）。
  ///
  /// 返回 `null` 即用户取消 —— 调用方必须原样返回、不落库。
  Future<SlotRange?> _askDropRange(int startMinute) {
    return SlotRangeDialog.show(
      context,
      date: widget.date,
      initialStart: startMinute,
    );
  }

  /// 从 [start] 起取 [minutes] 分钟，越界就往前让，保证 `end > start`。
  int _endFor(int start, int minutes) {
    final int gridEnd = ref.read(dayWindowProvider).endMinute;
    int end = start + minutes;
    if (end > gridEnd) {
      end = gridEnd;
    }
    if (end <= start) {
      end = start + kSlotMinutes;
    }
    return end;
  }

  GridEntry? _entryOf(String id) {
    for (final GridEntry entry in _entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _onContextMenu(int startMinute) async {
    if (_busy || !mounted) {
      return;
    }
    final todos = ref.read(todoPoolProvider).asData?.value ?? const <Never>[];
    final habits =
        ref.read(habitsForTodayProvider).asData?.value ?? const <Never>[];
    final Map<String, SlottedTodo> slotted = await _storeOf.slottedTodosOf(
      widget.date,
    );
    if (!mounted) {
      return;
    }
    final SlotMenuChoice? choice = await SlotContextMenu.show(
      context,
      startMinute: startMinute,
      todos: todos,
      habits: habits,
      slottedTodoIds: slotted.keys.toSet(),
    );
    if (choice == null || !mounted) {
      return;
    }
    final SlotRange? range = await SlotRangeDialog.show(
      context,
      date: widget.date,
      initialStart: startMinute,
    );
    if (range == null || !mounted) {
      return;
    }
    switch (choice) {
      case SlotMenuManual():
        final String? title = await _askTitle(startMinute);
        if (title == null || !mounted) {
          return;
        }
        await _guard(() async {
          await _storeOf.createManual(
            date: widget.date,
            title: title,
            startMinute: range.startMinute,
            endMinute: range.endMinute,
            todayIso: _todayIso,
            nowMinute: _nowMinute(),
          );
        });
      case SlotMenuTodo(:final todo):
        await _guard(() async {
          await _storeOf.createFromTodo(
            date: widget.date,
            todo: todo,
            startMinute: range.startMinute,
            endMinute: range.endMinute,
            todayIso: _todayIso,
            nowMinute: _nowMinute(),
          );
        });
      case SlotMenuHabit(:final habit):
        // 习惯入格恒为 `done`（打卡即已做），没有「回填才打勾」这条分叉，
        // 所以这里不传时钟两参数。
        await _guard(() async {
          await _storeOf.createFromHabit(
            date: widget.date,
            habit: habit,
            startMinute: range.startMinute,
            endMinute: range.endMinute,
          );
        });
    }
  }

  Future<void> _onDrop(String payload, Offset globalOffset) async {
    if (_busy || !mounted) {
      return;
    }
    final RenderBox? box =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final int start = _minuteAt(box.globalToLocal(globalOffset));
    final List<String> parts = payload.split(':');
    if (parts.length != 2) {
      return;
    }
    final String kind = parts.first;
    final String id = parts.last;

    switch (kind) {
      case 'plan':
        final GridEntry? entry = _entryOf(id);
        if (entry == null) {
          return;
        }
        await _guard(() async {
          await _storeOf.reschedule(
            planItemId: id,
            startMinute: start,
            endMinute: _endFor(start, entry.durationMinutes),
          );
        });
      case 'todo':
        final todos =
            ref.read(todoPoolProvider).asData?.value ?? const <Never>[];
        for (final todo in todos) {
          if (todo.id != id) {
            continue;
          }
          if (!mounted) {
            return;
          }
          final SlotRange? range = await _askDropRange(start);
          if (range == null || !mounted) {
            return;
          }
          await _guard(() async {
            await _storeOf.createFromTodo(
              date: widget.date,
              todo: todo,
              startMinute: range.startMinute,
              endMinute: range.endMinute,
              todayIso: _todayIso,
              nowMinute: _nowMinute(),
            );
          });
          return;
        }
      case 'habit':
        final habits =
            ref.read(habitsForTodayProvider).asData?.value ?? const <Never>[];
        for (final habit in habits) {
          if (habit.id != id) {
            continue;
          }
          if (!mounted) {
            return;
          }
          // 习惯入格同样必须先定起止：过去只写死 30 分钟，用户对
          // 「这一格到底占了多久」没有任何话语权。
          final SlotRange? range = await _askDropRange(start);
          if (range == null || !mounted) {
            return;
          }
          await _guard(() async {
            await _storeOf.createFromHabit(
              date: widget.date,
              habit: habit,
              startMinute: range.startMinute,
              endMinute: range.endMinute,
            );
          });
          return;
        }
    }
  }

  Future<void> _editRange(GridEntry entry) async {
    if (_busy || !mounted) {
      return;
    }
    final SlotRange? range = await SlotRangeDialog.show(
      context,
      date: widget.date,
      initialStart: entry.startMinute,
      initialEnd: entry.endMinute,
    );
    if (range == null || !mounted) {
      return;
    }
    await _guard(() async {
      await _storeOf.reschedule(
        planItemId: entry.id,
        startMinute: range.startMinute,
        endMinute: range.endMinute,
      );
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  Future<String?> _askTitle(int startMinute) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _TitleDialog(startMinute: startMinute),
    );
  }
}

/// 手填标题输入（起止已在上一弹窗定好，这里只差名字）。
class _TitleDialog extends StatefulWidget {
  const _TitleDialog({required this.startMinute});

  final int startMinute;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${formatMinute(widget.startMinute)} 要做什么？'),
      content: TextField(
        key: const ValueKey<String>('slot-title-field'),
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: '计划标题'),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('slot-title-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const ValueKey<String>('slot-title-confirm'),
          onPressed: _submit,
          child: const Text('排上'),
        ),
      ],
    );
  }
}

/// 格子底色 + 网格线。
class _SlotPainter extends CustomPainter {
  _SlotPainter(this.entries, this.layout, this.tokens);

  final List<GridEntry> entries;

  /// 行高表与车道几何的唯一真源（见 `slot_layout.dart`）。
  final SlotLayout layout;

  /// 颜色 token：`paint` 拿不到 `BuildContext`，只能由调用方注入。
  final ThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / kGridCols;
    final DayWindow window = layout.window;
    final Paint fill = Paint();

    for (int row = 0; row < window.rows; row++) {
      final double top = layout.rowTops[row];
      final double rowHeight = layout.rowHeights[row];
      for (int col = 0; col < kGridCols; col++) {
        final int cellStart =
            window.startMinute + row * 60 + col * kSlotMinutes;
        final int cellEnd = cellStart + kSlotMinutes;
        for (final GridEntry entry in entries) {
          if (entry.startMinute < cellEnd && entry.endMinute > cellStart) {
            fill.color = colorOfSlotKind(entry.kind, tokens);
            canvas.drawRect(
              Rect.fromLTWH(col * cellWidth, top, cellWidth, rowHeight),
              fill,
            );
            break;
          }
        }
      }
    }

    final Paint line = Paint()
      ..color = tokens.hairSoft
      ..strokeWidth = 1;
    for (int row = 0; row <= window.rows; row++) {
      final double y = layout.rowTops[row];
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (int col = 0; col <= kGridCols; col++) {
      final double x = col * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_SlotPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.layout != layout ||
      oldDelegate.tokens != tokens;
}

/// 刻度尺：1px 连续竖轴 + 整点 6px 刻 + 半点 3px 刻。
///
/// 刻度长度取 `AppTokens.axisTickHour` / `axisTickHalf`（原型 `.ax-hour` /
/// `.ax-half`），颜色复用 `hair` / `hairStrong`。三者都是**装饰线**：不承载
/// 信息、不进语义树、不参与命中测试 —— 这也是它敢用 `CustomPaint` 的原因。
///
/// 分钟基准与格子区共用 `kHourRowHeight`：整点刻 `row * kHourRowHeight`、
/// 半点刻 `+ kHourRowHeight / 2`，与 `_SlotPainter` 的行高完全同源。另起一套
/// 换算会随视口变化漂移，刻度就指不准格线。
class _RulerPainter extends CustomPainter {
  const _RulerPainter(this.layout, this.tokens);

  /// 行高表 + 车道几何的唯一真源（见 `slot_layout.dart`）。
  final SlotLayout layout;

  /// 颜色 token：`paint` 拿不到 `BuildContext`，只能由调用方注入。
  final ThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    // 半像素偏移让 1px 线压在像素中心，否则发虚成两列浅灰。
    final double x = size.width - 0.5;
    final DayWindow window = layout.window;

    final Paint spine = Paint()
      ..color = tokens.hair
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), spine);

    // 整点：起点 → 终点共 `window.rows + 1` 个，含收尾那一条。
    final Paint hourTick = Paint()
      ..color = tokens.hairStrong
      ..strokeWidth = 1;
    for (int row = 0; row <= window.rows; row++) {
      final double y = layout.rowTops[row];
      canvas.drawLine(
        Offset(x - AppTokens.axisTickHour, y),
        Offset(x, y),
        hourTick,
      );
    }

    // 半点：每个整点行中点一条短刻，构成「整点 + 半点」双档。
    final Paint halfTick = Paint()
      ..color = tokens.hair
      ..strokeWidth = 1;
    for (int row = 0; row < window.rows; row++) {
      final double y = layout.rowTops[row] + layout.rowHeights[row] / 2;
      canvas.drawLine(
        Offset(x - AppTokens.axisTickHalf, y),
        Offset(x, y),
        halfTick,
      );
    }
  }

  /// 只在窗口变化时需要重绘。
  @override
  bool shouldRepaint(_RulerPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.tokens != tokens;
}
