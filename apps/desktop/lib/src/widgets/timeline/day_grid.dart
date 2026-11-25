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

import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/goal_store.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../providers_p1.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../day_timeline.dart';
import '../focus_ring.dart';
import '../ledger_checkbox.dart';
import '../priority_hover_bubble.dart';
import '../week_goal_rail_panel.dart';
import 'plan_item_detail_dialog.dart';
import 'slot_context_menu.dart';
import 'slot_fill.dart';
import 'slot_hover_card.dart';
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

/// 条目该用哪个**底色**：类型轴（习惯）+ 完成轴叠加后的结果。
///
/// Task 54 · 诉求 2 的落点：用户打完勾，格子底色要退到去彩度的 `slotDone`，
/// 没做完的才留在 `slotPlan` / `slotBackfill` 的暖色里 —— 未完成的因此更显眼。
///
/// 为什么不能只看 `kind`：四态判定顺序是铁律 `habit → backfill → done →
/// plannedOpen`（见 `slot_state.dart` 文件头）。任何「计划起点已到」的条目
/// `kind` 恒为 `SlotKind.backfill`，**打勾之后也还是 `backfill`** —— 完成态从
/// `kind` 上根本读不出来。完成状态因此挂在 `GridEntry.completed`（显式位
/// `isDone`）上，由这一层叠加到 `kind` 的底色之上。
///
/// [colorOfSlotKind] 的映射本身不动：它仍是「kind → 该 kind 的底色」，
/// 既有逐值断言（`timeline_contrast_test.dart` / `task54_done_desaturate_test.dart`）
/// 因此逐字不变。
Color fillOfSlot(GridEntry entry, ThemeTokens tokens) {
  // 习惯是**类型轴**，优先级最高、不受完成态影响：打卡条目的底色不随勾选变化。
  if (entry.kind == SlotKind.habit) {
    return tokens.slotHabit;
  }
  if (entry.completed) {
    return tokens.slotDone;
  }
  // 未完成的回填仍是 `slotBackfill`，未完成的计划仍是 `slotPlan` —— 与改动前一致。
  return colorOfSlotKind(entry.kind, tokens);
}

/// 条目正文的最小可排版宽度。
///
/// 为什么需要它：条目宽度现在由「起始分钟 → 列」决定（`slot_layout.dart` 的
/// `col`）。窄视口下 15 分钟只占 `658 / 4 = 164.5px`，减掉左右各 2px 缝与
/// 内边距 8px 只剩 152.5px；而正文那串**不可压缩**的子项（复选框 22 +
/// 字形 11 + 习惯回填徽标 50 及各处 3–6px 间隔）在测试字体
/// （Ahem，每字符宽 = 字号）下就要 180px 左右，`Row` 会在窄档当场
/// `RenderFlex overflowed`。
///
/// Task 50 把「起始时刻」与「进展：」从正文里搬进了悬停浮窗
/// （`slot_hover_card.dart`），正文的实际需求又降了一档；跨行续接的弯折箭头
/// 另各占 12px。这里仍**不下调**：宽视口（1400 ⇒ 内宽 262.5）本来就走
/// `maxWidth` 原值、逐像素不变；窄档与 2 倍字号档多裁一点，比让 `Row` 溢出安全。
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

  /// 极简模式：悬停浮窗里不显示详情与进展串，不藏数据。
  ///
  /// Task 50 把起始时刻与「进展：」从条目正文搬进了悬停浮窗
  /// （`slot_hover_card.dart`），正文因此只剩标题。极简/完整开关的可见回落
  /// 也跟着搬进浮窗：完整档浮窗给起止时间、标题、详情、进展、状态、级别；
  /// 极简档去掉详情与进展两行。没有它这个开关就是假按钮。
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

  /// 极简模式的当前值（见 [DayGrid.minimal]）：只影响悬停浮窗的内容行。
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
            // Task 49：日期表头整行删除（日期只由顶部日期模块表达），
            // 这里保留一条上沿发丝线把网格区与上方内容分开 —— 「表格感」
            // 来自这条线，而不是多套一层容器：线用 `hair`，与格子区边框同阶，
            // 不引入新色。
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
        // 前缀分流全部落在 `_onDrop`：`plan:<id>` / `todo:<id>` / `habit:<id>` /
        // `goal://<goalId>`（右栏未完成周目标）在这里只要求带分隔符。
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
                    // 三段底色必须在**最底层**（Stack 第一子层）：它是格子的
                    // 本来底色，`_SlotPainter` 的网格线要画在它**之上**，否则
                    // 1px 格线会被整片盖掉。放第一子层后：底色在最底 ✅、
                    // 网格线仍可见 ✅，且色带不参与 hit-test（点选仍落在格子上）。
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
                        painter: _SlotPainter(layout, t),
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
                          AppLocalizations.of(context).timelineEmptyGridHint,
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
      seg: seg,
      layout: layout,
      gridWidth: gridWidth,
    );
    // 跨行续接的弯折箭头（需求 e）画在**外壳之外**的 `Stack` 里，而不是塞进
    // `_chipShell` 的内容行：外壳里还有 `ClipRRect` + `ClipRect` +
    // `OverflowBox(minWidth: 260)`，塞进去会被裁掉，`Positioned` 也会相对
    // 那 260px 的溢出内容而不是相对条目本身。这里 `Positioned.fill` 给外壳
    // 的紧约束与原实现逐像素相同，箭头因此稳定落在条目的左上 / 右下角。
    final Widget tile = Stack(
      children: <Widget>[
        Positioned.fill(child: shell),
        if (seg.continuesAbove)
          Positioned(
            left: 2,
            top: 0,
            width: 12,
            height: 20,
            child: CustomPaint(
              key: ValueKey<String>(
                'day-grid-continue-up-${entry.id}-${seg.row}',
              ),
              painter: _ContinueArrowPainter(up: true, color: t.ink),
            ),
          ),
        if (seg.continuesBelow)
          Positioned(
            right: 2,
            bottom: 0,
            width: 12,
            height: 20,
            child: CustomPaint(
              key: ValueKey<String>(
                'day-grid-continue-down-${entry.id}-${seg.row}',
              ),
              painter: _ContinueArrowPainter(up: false, color: t.ink),
            ),
          ),
      ],
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
                child: tile,
              ),
            )
          // Task 53 · 诉求 2：续段**不画文字**，但它仍是同一条任务的一部分 ——
          // 悬停要能看任务信息、左键要能进详情窗。这里只补交互、不补内容：
          // `_chipShell` 的续段分支仍是空壳（`showBody: false`），所以
          // 「续段里一个 `Text` 都没有」的判据不受影响。
          //
          // 为什么复用 [_hoverCardAround] 而不是再写一份 `SlotHoverCard`：
          // 浮窗的锚点取 `SlotHoverCard` 内部 `MouseRegion` 自己的矩形，
          // 包住续段外壳即锚在续段上（而不是锚在首段那一行）。
          //
          // 为什么不加 `Draggable` / `onDoubleTap`：拖动与「改起止时间」都
          // 是**整条任务**的操作，入口留在首段即可；两个分支的命中区互不
          // 重叠，不会和首段的 `GestureDetector` 抢同一次点击。
          : _hoverCardAround(
              entry,
              InkWell(
                onTap: () => _openDetail(entry),
                canRequestFocus: false,
                child: tile,
              ),
            ),
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
    SlotSegment? seg,
    SlotLayout? layout,
    double gridWidth = 0,
  }) {
    final Widget body = showBody
        ? _chipBody(
            entry,
            t,
            seg: seg,
            layout: layout,
            gridWidth: gridWidth,
            hover: live,
          )
        : const SizedBox();
    final Color kindInk = foregroundOfSlotKind(entry.kind, t);
    // Task 51 · 诉求 4：跨小时的「接续段」不再每段都顶 2px 深色左边框 ——
    // 那会让同一任务在跨行处看起来像「两个任务各自起头」。现在只有**首段**
    // （不是从上一行接下来的）保留左边框，任务真正的末端（接下、但不再往下）
    // 把 2px 深色画在**右缘**，读者顺着行读到的是一条连续的带子 + 一个收尾。
    final bool continuesAbove = seg?.continuesAbove ?? false;
    final bool continuesBelow = seg?.continuesBelow ?? false;
    final bool tail = continuesAbove && !continuesBelow;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: ValueKey<String>(keyValue),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: fillOfSlot(entry, t),
          border: Border(
            left: continuesAbove
                ? BorderSide(color: t.hair)
                : BorderSide(color: kindInk, width: 2),
            top: BorderSide(color: t.hair),
            right: tail
                ? BorderSide(color: kindInk, width: 2)
                : BorderSide(color: t.hair),
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

  /// 一行内容：复选框 · 四维标记 · 标题 · 四态字形 · 习惯回填徽标。
  ///
  /// 全部单行、全部可省略，唯一会撑宽的是标题（带省略号）。
  ///
  /// Task 50 · W2 又从这里搬走两样东西（用户当轮需求 h）：**起始时刻**与
  /// **「进展：」串**。它们没有消失，只是改挂到悬停浮窗
  /// （`slot_hover_card.dart`）里 —— 单行芯片只留标题，横向空间才够让同一
  /// 小时里的并发条目并排，也才够给内嵌小盒留出标题避让位。
  ///
  /// Task 45 · W2 已从这里移除三样东西（用户当轮需求 2 前半）：**状态词**
  /// （`stateLabelOfSlotKind` 的「打卡 / 回填 / 完成 / 计划」）、**「未分级」
  /// 文本**、**「删除」入口**。状态表达只留背景色 + 四态字形 + 左缘竖条；
  /// 「未分级」靠「不画标记、不留占位」表达（空白本身是信息）；删除移进
  /// 详情窗（`plan_item_detail_dialog.dart`）。
  ///
  /// [hover] 只对 head 段为真：`Draggable.feedback` 的子树不保证有
  /// `Overlay` 祖先，且拖动幽灵不需要悬停卡。
  Widget _chipBody(
    GridEntry entry,
    ThemeTokens t, {
    SlotSegment? seg,
    SlotLayout? layout,
    double gridWidth = 0,
    bool hover = false,
  }) {
    final PlanItemData? row = _rowOf(entry.id);
    final bool done = row?.status == PlanStatus.done.code;
    // 行里存的是码值字符串，渲染层自己解析；无法识别（未来 schema）就当作
    // 未分级 —— 不画标记，也不抛异常。
    final Quadrant? quadrant = Quadrant.fromCode(row?.quadrant);
    
    final Color ink = foregroundOfSlotKind(entry.kind, t);
    // 需求 g：被更高层的条目包含时，本条的标题必须让出「内嵌小盒左缘」之前
    // 的空间 —— 上限由布局层逐像素算出（宿主标题右缘 / 小盒左缘），这里只
    // 负责把宽度钉死。`null` = 没有宿主，按原样 `Flexible` 铺满。
    final double? titleLimit = seg == null || layout == null || gridWidth <= 0
        ? null
        : layout.titleLimitOf(seg, gridWidth);
    // 标题左侧的固定开销：左缘竖条 2 + 外壳内边距 4 + 勾选框 22 + 与四维标记
    // 的间隔 5 + 四维标记 14（含其后的 4）+ 跨行向上箭头占位 12 + 右侧留白 6。
    final double chrome =
        2 +
        4 +
        22 +
        5 +
        (quadrant != null ? 14 : 0) +
        ((seg?.continuesAbove ?? false) ? 12 : 0) +
        6;
    final Widget titleText = Text(
      entry.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        color: t.ink2,
        // Task 53 · 诉求 3：完成态**不再**画删除线（用户原话「不要显示删除
        // 线」）。「已完成」已由前置勾选框（第一重）与四态底色（第二重）表达，
        // 删除线是同一件事的第三遍重复，代价却是标题本身变得难读。
      ),
    );
    final double? titleWidth = titleLimit == null ? null : titleLimit - chrome;
    final Widget title;
    if (titleWidth == null) {
      title = Flexible(child: titleText);
    } else if (titleWidth <= 8) {
      // 宿主标题已经吃掉这一行：连一个字都放不下时宁可不画，也不画一串
      // 省略号去和宿主的文字叠在一起。
      title = const SizedBox.shrink();
    } else {
      title = SizedBox(width: titleWidth, child: titleText);
    }
    // Task 54 · 诉求 1：尾部字形只留给习惯态（用户原话「去除主界面中，任务
    // 标题后面的三角形」—— 那个三角形是回填态的 `▶` U+25B6）。回填态不再带
    // 任何标记；完成/计划的判定交给前置勾选框，不给尾部留重复信息。
    final String? tailGlyph =
        entry.kind == SlotKind.habit ? glyphOfSlotKind(entry.kind) : null;
    final Widget content = Row(
      children: <Widget>[
        // 账页行序（方向 A）：勾选框 → 四维标记 → 标题 → 四态字形 →
        // 习惯回填。
        // 勾选框提到最左是「账页行」与「横排芯片」的差别所在：勾是行的第一列，
        // 不是标题的尾巴。行落位仍由 15 分钟格引擎决定。
        //
        // 跨行箭头（需求 e）画在外壳之上的 `Stack` 里；这两个占位块只把文字
        // 让开那 12px，避免标题压到箭头上。
        if (seg?.continuesAbove ?? false) const SizedBox(width: 12),
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
        // 标题：宽度未知（无宿主）时自己 `Flexible` 吃满剩余空间；有宿主时
        // 宽度已被 [titleWidth] 钉死，不再参与弹性分配。
        title,
        // 尾部字形只留给习惯态；回填态不带任何标记 —— Task 54 诉求①。
        // 计划 `○` 与完成 `✓` 早在 Task 53 已由前置勾选框表达，尾部再画一遍
        // 是重复 —— 用户原话「后面的圆圈可以去除 / 也不用显示后面的对号」。
        //
        // 仍然用 `RichText` 而非 `Text`：这个字形与 `LedgerCheckbox` 自绘的
        // 勾选符是同一批码位，用 `Text` 会让既有的 `find.text('✓')` 精确计数
        // 从 1 变 2。`find.text` 只认 `Text` / `EditableText`，不匹配
        // `RichText`，所以这里既保住了字形通道，也不污染既有断言。
        if (tailGlyph != null)
          RichText(
            textDirection: TextDirection.ltr,
            text: TextSpan(
              text: tailGlyph,
              style: TextStyle(
                fontSize: 11,
                color: ink,
                // 两个字形都不在 Inter 里，只能靠 `Noto Sans SC` 兜底；
                // 这里必须显式声明族，继承 `DefaultTextStyle` 会渲染成豆腐块。
                fontFamily: AppFonts.body,
                fontFamilyFallback: AppFonts.bodyFallback,
              ),
            ),
          ),
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
              AppLocalizations.of(context).timelineHabitBackfill,
              style: TextStyle(fontSize: 10, color: t.meta),
            ),
          ),
        ],
        // 向下跨行的箭头占在右下角（需求 e），末尾同样让开 12px。
        if (seg?.continuesBelow ?? false) const SizedBox(width: 12),
      ],
    );
    if (!hover) {
      return content;
    }
    // 需求 h：起始时刻 / 标题 / 详情 / 进展 / 状态 / 级别都搬进悬停浮窗。
    return _hoverCardAround(entry, content);
  }

  /// 给一段条目外壳套上悬停浮窗。
  ///
  /// 抽出来是因为它有**两个**调用点：首段的正文（[_chipBody] 的 `hover`
  /// 分支）与跨行续段（[_segmentTile] 的非 head 分支）。两处的浮窗内容必须
  /// 逐字段相同 —— 用户看到的「同一条任务」，不该因为悬停在第二行就少几个
  /// 字段。
  ///
  /// 浮窗必须走 `OverlayPortal`（`SlotHoverCard` 内部）：格子区外层是
  /// `Clip.antiAlias`，普通 `Overlay` 子树会被裁在这一格里。
  Widget _hoverCardAround(GridEntry entry, Widget child) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlanItemData? row = _rowOf(entry.id);
    final Quadrant? quadrant = Quadrant.fromCode(row?.quadrant);
    return SlotHoverCard(
      title: entry.title,
      startMinute: entry.startMinute,
      endMinute: entry.endMinute,
      detail: _minimal ? '' : (row?.detail ?? ''),
      note: row?.resultNote ?? '',
      stateLabel: stateLabelOfSlotKind(entry.kind, localizations: l10n),
      levelLabel: _levelLabelOf(quadrant, l10n),
      showNote: !_minimal,
      child: child,
    );
  }

  /// 悬停浮窗「级别」行的文案。
  ///
  /// 为什么不再用 `QuadrantStyle.of(quadrant).label`：那是 `core_data` 里的
  /// 硬编码中文 —— 英文界面下这一行会漏出中文（R63-15）。
  ///
  /// 为什么用 `switch` 穷举而不是 `??` 兜底：兜底会把「将来新增象限」静静
  /// 变成某条固定文案，编译期发现不了；穷举后新增枚举值会直接编译报错。
  /// 四个分支的中文与域层 `QuadrantStyle.label` **逐字相同**（见
  /// `l10n\parts\domain.dart` 的 `quadrantQ1Label` … `quadrantQ4Label`），
  /// 所以中文态显示一个字都没变。
  String _levelLabelOf(Quadrant? quadrant, AppLocalizations t) =>
      switch (quadrant) {
        null => t.priorityUnsetLabel,
        Quadrant.q1 => t.quadrantQ1Label,
        Quadrant.q2 => t.quadrantQ2Label,
        Quadrant.q3 => t.quadrantQ3Label,
        Quadrant.q4 => t.quadrantQ4Label,
      };

  /// 写操作统一入口：失败只提示、不吞掉。
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).timelineWriteFailed('$error'),
          ),
        ),
      );
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
      case SlotMenuGoals():
        // Task 72 / B7 第三条通道：勾选式多选，确认后逐条走唯一写入入口
        // `addWeekGoalToPlan`（与面板点击 / 拖拽共用同一份幂等判据）。
        final List<GoalRow> goals =
            ref.read(weekOpenGoalsProvider).asData?.value ?? const <GoalRow>[];
        final List<GoalRow>? picked = await WeekGoalPickDialog.show(
          context,
          goals: goals,
        );
        if (picked == null || picked.isEmpty || !mounted) {
          return;
        }
        final SlotRange slotRange = range;
        await _guard(() async {
          for (final GoalRow goal in picked) {
            await addWeekGoalToPlan(
              ref,
              goal: goal,
              date: widget.date,
              startMinute: slotRange.startMinute,
              endMinute: slotRange.endMinute,
            );
          }
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
      case 'goal':
        // Task 72 / B7 第二条通道：右栏「未完成周目标」拖进来。
        // payload 逐字 `goal://<goalId>` ⇒ `split(':')` 得
        // `['goal', '//<goalId>']`，所以 id 上还挂着 `//` 前缀要剥掉。
        final String goalId = id.startsWith('//') ? id.substring(2) : id;
        final List<GoalRow> goals =
            ref.read(weekOpenGoalsProvider).asData?.value ?? const <GoalRow>[];
        for (final GoalRow goal in goals) {
          if (goal.id != goalId) {
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
            await addWeekGoalToPlan(
              ref,
              goal: goal,
              date: widget.date,
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.timelineSlotPrompt(formatMinute(widget.startMinute))),
      content: TextField(
        key: const ValueKey<String>('slot-title-field'),
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: l10n.timelinePlanTitleHint),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('slot-title-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('slot-title-confirm'),
          onPressed: _submit,
          child: Text(l10n.timelineScheduleAction),
        ),
      ],
    );
  }
}

/// 网格线 + 重叠叠色。
///
/// Task 51 · 追加诉求：这里**不再**给格子铺条目四态底色。用户判据是「没有任务的
/// 位置显示单元格原本的背景色」，而原先按「条目与整格相交」铺色，会连格内没有
/// 任务的分钟也铺满整行高（行高 44，条目芯片只有 18 逻辑高），把三段分区底色
/// 整片吃掉 —— 视觉上就成了「空白格也有底色」。条目色由芯片自己承载
/// （`_chipShell`），格底只留三段色带（`_sectionTintChildren`）+ 本类的网格线。
class _SlotPainter extends CustomPainter {
  _SlotPainter(this.layout, this.tokens);

  /// 行高表与车道几何的唯一真源（见 `slot_layout.dart`）。
  final SlotLayout layout;

  /// 颜色 token：`paint` 拿不到 `BuildContext`，只能由调用方注入。
  final ThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / kGridCols;
    final DayWindow window = layout.window;

    // 需求 f：三条带都换不出空位时，重叠处**格底加深**（数据层已在
    // `LaneConflict` 里记下区间），提示读者「这里叠了两条」。
    //
    // 加深一律用 `ink` 叠色，不用 `accent` / `accentWash` —— 方格区是中性
    // 账页，赭石只归「当前/强调」。透明度 0.05 是既有底色之上的最浅一档：
    // 能看出差别，又不至于把四态底色本身染脏。
    //
    // Task 51 · 诉求 3：从 0.08 降到 0.05 —— 四态底色整体变浅之后，0.08 的
    // `ink` 叠色会在浅底上显出一块明显发灰的方块，读起来像「脏」而不是「挤」。
    final Paint conflictFill = Paint()
      ..color = tokens.ink.withValues(alpha: 0.05);
    for (final LaneConflict conflict in layout.conflicts) {
      final int rowStart = window.startMinute + conflict.row * 60;
      final int colStart = ((conflict.startMinute - rowStart) ~/ kSlotMinutes)
          .clamp(0, kGridCols - 1);
      final int colEnd =
          ((conflict.endMinute - rowStart + kSlotMinutes - 1) ~/ kSlotMinutes)
              .clamp(colStart + 1, kGridCols);
      canvas.drawRect(
        Rect.fromLTWH(
          colStart * cellWidth,
          layout.rowTops[conflict.row],
          (colEnd - colStart) * cellWidth,
          layout.rowHeights[conflict.row],
        ),
        conflictFill,
      );
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
      oldDelegate.layout != layout || oldDelegate.tokens != tokens;
}

/// 跨行弯折箭头（需求 e）：一条任务在未完成的小时结束处 / 下一小时开始处
/// 各画一个「折回箭头」，提示「这条还接着上面 / 下面」。
///
/// 为什么必须自绘：`↳`(U+21B3) 与 `↰`(U+21B0) 在随包的 10 个字体里覆盖率
/// 是 0/10，用字符只会渲染成豆腐块。`CustomPainter` + `Path` 不依赖任何
/// 字体，也不进语义树 —— 它纯装饰，信息由布局层（`continuesAbove/Below`）
/// 与悬停浮窗承载。
///
/// 线宽 1.2 + 圆头圆角：落在 20px 高的条目里既不糊成一团，也比 1px 更像
/// 「方向」而非「边框」。
/// 跨行箭头的「竖笔 + 折笔」两个折点序列（`up:true` 指向上方）。
///
/// Task 51 · 诉求 4：`up:false` 的走向由「先上再左」改成「先下再左」——竖笔
/// 从上方起点**往下**画到折点，再折向左，箭尖仍朝左。原先竖笔自下而上，读者
/// 顺着笔画读到的方向是「往上一小时」，与「接续到下一行」的语义相反。
///
/// 只翻竖笔方向、保留折点与箭尖位置：箭头挂在 `Positioned(right: 2,
/// bottom: 0)` 的 20px 底部盒里，整幅上下镜像会把箭头从条目底部搬到顶部，
/// 那样既改方向又改位置，超出「视觉方向」这一诉求。
List<Offset> continueArrowStem(bool up) => up
    ? const <Offset>[Offset(3.5, 1.5), Offset(3.5, 6.5), Offset(9.5, 6.5)]
    : const <Offset>[Offset(8.5, 6.5), Offset(8.5, 13.5), Offset(2.5, 13.5)];

/// 跨行箭头的箭尖（两条短线，从折点张开）。
List<Offset> continueArrowHead(bool up) => up
    ? const <Offset>[Offset(6.8, 3.8), Offset(9.5, 6.5), Offset(6.8, 9.2)]
    : const <Offset>[Offset(5.2, 10.8), Offset(2.5, 13.5), Offset(5.2, 16.2)];

class _ContinueArrowPainter extends CustomPainter {
  const _ContinueArrowPainter({required this.up, required this.color});

  /// `true` = 指向上方（本段是某一小时的首段，任务从上一小时接过来）。
  final bool up;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path path = Path();
    _addPolyline(path, continueArrowStem(up));
    _addPolyline(path, continueArrowHead(up));
    canvas.drawPath(path, stroke);
  }

  static void _addPolyline(Path path, List<Offset> points) {
    if (points.isEmpty) {
      return;
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
  }

  @override
  bool shouldRepaint(_ContinueArrowPainter oldDelegate) =>
      oldDelegate.up != up || oldDelegate.color != color;
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
