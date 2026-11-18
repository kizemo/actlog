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
import '../confirm_dialog.dart';
import '../day_timeline.dart';
import '../focus_ring.dart';
import '../ledger_checkbox.dart';
import '../priority_hover_bubble.dart';
import 'slot_context_menu.dart';
import 'slot_fill.dart';
import 'slot_range_dialog.dart';
import 'slot_state.dart';
import 'timeline_store.dart';

/// 四态 → 底色。绘制层只做这一处映射，判定顺序在 `slot_state.dart`。
Color colorOfSlotKind(SlotKind kind) => switch (kind) {
  SlotKind.habit => AppTokens.slotHabit,
  SlotKind.backfill => AppTokens.slotBackfill,
  SlotKind.done => AppTokens.slotDone,
  SlotKind.plannedOpen => AppTokens.slotPlan,
};

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

  /// 写操作串行化，避免连点产生重复行。
  bool _busy = false;

  TimelineStore? _store;

  TimelineStore get _storeOf =>
      _store ??= TimelineStore(ref.read(repositoriesProvider));

  /// 最近一次 build 的计划行原始数据，供条目按 id 反查状态 / 进展串。
  List<PlanItemData> _rows = const <PlanItemData>[];

  /// 选中日是否晚于今天（未来日只可预排：不可勾选、不回填、不聚焦）。
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
    _rows = items;
    _future = widget.date.compareTo(todayIso) > 0;
    _minimal = widget.minimal;
    _entries = gridEntriesOf(
      items,
      date: widget.date,
      todayIso: todayIso,
      nowMinute: nowMinute ?? -1,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double axisWidth = tlWidthFor(box.maxWidth);
        final double axisGap = tlGapFor(box.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _headerStrip(axisWidth, axisGap),
            const SizedBox(height: 6),
            // 表头的「表格感」来自一条下沿发丝线，而不是多套一层容器：
            // 线用 `hair`，与格子区边框同阶，不引入新色。
            Container(height: 1, color: AppTokens.hair),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: axisWidth,
                  height: win.height,
                  child: _axis(win),
                ),
                SizedBox(width: axisGap),
                Expanded(child: _gridArea(win)),
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
  Widget _headerStrip(double axisWidth, double axisGap) {
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
              color: AppTokens.accentWash,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppTokens.hair),
            ),
            child: Text(
              weekday.isEmpty ? widget.date : '${widget.date} $weekday',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.25,
                color: AppTokens.ink,
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
  Widget _axis(DayWindow win) {
    return Stack(
      key: const ValueKey<String>('day-grid-ruler'),
      children: <Widget>[
        Positioned.fill(child: CustomPaint(painter: _RulerPainter(win))),
        for (int row = 0; row < win.rows; row++)
          Positioned(
            top: row * kHourRowHeight,
            left: 0,
            right: 0,
            height: kHourRowHeight,
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
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1,
                    color: AppTokens.faint,
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
        for (final int hour in _kSegmentStartHours)
          if (win.contains(hour * 60))
            Positioned(
              top: win.yOf(hour * 60) + (kHourRowHeight - 1) / 2,
              left: 0,
              child: Container(
                key: ValueKey<String>('day-grid-segment-mark-$hour'),
                width: 8,
                height: 1,
                color: AppTokens.hairStrong,
              ),
            ),
      ],
    );
  }

  /// 三段起点（06:00 / 12:00 / 18:00）的整点小时数。
  ///
  /// 与格子区三段底色的切分点**同一份真源**（`_kSegmentTints` 的顺序即本表
  /// 的顺序）：改这里就得改那里，否则短横线会落在色带之外，标记与底色互相打脸。
  static const List<int> _kSegmentStartHours = <int>[6, 12, 18];

  /// 三段底色，顺序与 [_kSegmentStartHours] 一一对应（06–12 / 12–18 / 18–24）。
  ///
  /// 只取既有中性阶（`card` / `paper` / `sunken`），不新造 hex、不引入新色相；
  /// 赭石在方格区仍然禁用。差异刻意轻微：这是「分区提示」，不是三块卡片。
  static const List<Color> _kSegmentTints = <Color>[
    AppTokens.gridSectionMorning,
    AppTokens.gridSectionNoon,
    AppTokens.gridSectionEvening,
  ];

  Widget _gridArea(DayWindow win) {
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
                height: win.height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppTokens.card,
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(
                    color: candidate.isEmpty
                        ? AppTokens.hair
                        : AppTokens.hairStrong,
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
                    Positioned.fill(
                      child: Column(
                        key: const ValueKey<String>('day-grid-section-tint'),
                        children: _sectionTintChildren(win),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _SlotPainter(_entries, win)),
                    ),
                    for (final GridEntry entry in _entries)
                      if (entry.startMinute < win.endMinute &&
                          entry.endMinute > win.startMinute)
                        _entryTile(entry, win),
                    if (_entries.isEmpty)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 12,
                        child: Text(
                          '右键任意一格开始排期',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTokens.faint,
                          ),
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
  /// 只画与 [win] 可见区间相交的部分，`Expanded.flex` 直接取**分钟数**，
  /// 因此默认窗口 `06–24` 得到 `360 / 360 / 360`（与参数化之前的三等分
  /// 逐像素一致），窗口收窄到 `09–18` 则得到 `180 / 360`，比例天然正确。
  List<Widget> _sectionTintChildren(DayWindow win) {
    final List<Widget> children = <Widget>[];
    for (int i = -1; i < _kSegmentTints.length; i++) {
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
      children.add(
        Expanded(
          flex: to - from,
          child: ColoredBox(color: i < 0 ? AppTokens.card : _kSegmentTints[i]),
        ),
      );
    }
    return children;
  }

  Widget _entryTile(GridEntry entry, DayWindow win) {
    final int visibleStart = entry.startMinute < win.startMinute
        ? win.startMinute
        : entry.startMinute;
    final double top = win.yOf(visibleStart);
    final double height = (entry.durationMinutes / 60 * kHourRowHeight).clamp(
      22.0,
      win.height,
    );
    return Positioned(
      top: top + 1,
      left: 2,
      right: 2,
      height: height - 2,
      child: Draggable<String>(
        data: 'plan:${entry.id}',
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 180, child: _chipShell(entry, live: false)),
        ),
        child: GestureDetector(
          onDoubleTap: () => _editRange(entry),
          child: _chipShell(entry, live: true),
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
  Widget _chipShell(GridEntry entry, {required bool live}) {
    final Widget body = _chipBody(entry);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: ValueKey<String>('day-grid-entry-${entry.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: colorOfSlotKind(entry.kind),
          border: Border(
            left: BorderSide(color: foregroundOfSlotKind(entry.kind), width: 2),
            top: BorderSide(color: AppTokens.hair),
            right: BorderSide(color: AppTokens.hair),
            bottom: BorderSide(color: AppTokens.hair),
          ),
        ),
        child: ClipRect(
          child: OverflowBox(
            maxHeight: double.infinity,
            alignment: Alignment.centerLeft,
            child: live ? _liveBody(entry, body) : body,
          ),
        ),
      ),
    );
  }

  /// 可交互外壳：`Space` 切勾选、`Enter` 开回填、点整条开回填。
  ///
  /// 语义直接沿用被删掉的「今日计划」行（`_PlanItemTile`）：行级焦点 +
  /// `requirePrimaryFocus` 的焦点环，焦点落到复选框上时行环**不**跟着亮。
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
            _openResult(entry);
            return null;
          },
        ),
      },
      child: Focus(
        key: ValueKey<String>('plan-row-focus-${entry.id}'),
        focusNode: node,
        canRequestFocus: !_future,
        onKeyEvent: (FocusNode target, KeyEvent event) =>
            _onKey(target, event, entry),
        child: FocusRing(
          focusNode: node,
          requirePrimaryFocus: true,
          ringKey: const ValueKey<String>('focus-ring-border-plan-row'),
          child: InkWell(
            onTap: _future ? null : () => _openResult(entry),
            canRequestFocus: false,
            child: body,
          ),
        ),
      ),
    );
  }

  /// 一行内容：字形 · 状态词 · 复选框 · 起始时间 · 标题 · 进展 · 习惯回填徽标 · 删除。
  ///
  /// 全部单行、全部可省略，唯一会撑宽的是标题与进展（都带省略号）。
  ///
  /// 字形与状态词是四态背景色之外的**冗余通道**（形状 + 文字），
  /// `--slot-done` 与 `--slot-plan` 近乎同色时靠它们才分得出来。
  Widget _chipBody(GridEntry entry) {
    final PlanItemData? row = _rowOf(entry.id);
    final bool done = row?.status == PlanStatus.done.code;
    // 行里存的是码值字符串，渲染层自己解析；无法识别（未来 schema）就当作
    // 未分级 —— 不画标记，也不抛异常。
    final Quadrant? quadrant = Quadrant.fromCode(row?.quadrant);
    final String note = row?.resultNote ?? '';
    final Color ink = foregroundOfSlotKind(entry.kind);
    return Row(
      children: <Widget>[
        // 账页行序（方向 A）：勾选框 → 四维标记 → 标题 → mono 元信息 →
        // 四态字形 + 状态词 → 未分级 → 进展 → 习惯回填 → 删除。
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
              color: AppTokens.ink2,
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
          style: const TextStyle(
            fontSize: 10,
            color: AppTokens.faint,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        // 未分级：不画标记（不是画空标记）、不留占位 —— 但「没有标记」与
        // 「分级没渲染出来」在界面上必须可分，所以补一处 meta 说明。
        if (quadrant == null) ...<Widget>[
          const SizedBox(width: 4),
          const Text(
            '未分级',
            style: TextStyle(fontSize: 10, color: AppTokens.faint),
          ),
        ],
        const SizedBox(width: 5),
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
        const SizedBox(width: 3),
        Text(
          stateLabelOfSlotKind(entry.kind),
          style: TextStyle(fontSize: 10, color: ink),
        ),
        if (note.isNotEmpty && !_minimal) ...<Widget>[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '进展：$note',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppTokens.meta),
            ),
          ),
        ],
        if (entry.kind == SlotKind.habit) ...<Widget>[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppTokens.paper,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppTokens.hair),
            ),
            child: const Text(
              '习惯回填',
              style: TextStyle(fontSize: 10, color: AppTokens.meta),
            ),
          ),
        ],
        if (!_future) ...<Widget>[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _delete(entry),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '删除',
                style: TextStyle(fontSize: 10, color: AppTokens.meta),
              ),
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
  /// 与 [_toggleStatus] 的唯一差别：**不拦未来日**。状态是「做没做完」的事实，
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

  Future<void> _openResult(GridEntry entry) async {
    if (_future) {
      return;
    }
    final PlanItemData? row = _rowOf(entry.id);
    if (row == null) {
      return;
    }
    final SlotFillEdit? edit = await showSlotFillDialog(
      context,
      title: row.title,
      initialNote: row.resultNote,
    );
    if (edit == null) {
      return;
    }
    await _write(
      () => ref
          .read(repositoriesProvider)
          .planItem
          .setStatus(
            row.id,
            slotStatusAfterFill(edit, row.status),
            resultNote: edit.note.isEmpty ? null : edit.note,
          ),
    );
  }

  /// 删除前先走一次确认（需求 9）：取消 ⇒ 一行都不动，也不弹错误。
  ///
  /// 「删除」按钮的文案与样式仍是原样，只是多了一道确认；确认后依旧走原来那条
  /// 软删路径（循环 occurrence 联动在仓储层，见 `repositories.dart`）。
  Future<void> _delete(GridEntry entry) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: '删除计划项',
      message: '确认删除「${entry.title}」？删除后它不再出现在清单里。',
    );
    // 弹窗期间条目可能已被别处重建/卸载，而 `_write` 要用 `ref` 与 `context`。
    if (!mounted || !confirmed) {
      return;
    }
    await _write(
      () => ref.read(repositoriesProvider).planItem.softDelete(entry.id),
    );
  }

  /// 条目级按键：`Space` 切勾选、`Enter` 开回填。
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
    final double y = local.dy.clamp(0.0, win.height - 1);
    final double raw = win.startMinute + y / kHourRowHeight * 60;
    final int aligned = alignMinuteDown(raw.round());
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
  _SlotPainter(this.entries, this.window);

  final List<GridEntry> entries;
  final DayWindow window;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / kGridCols;
    final double rowHeight = size.height / window.rows;
    final Paint fill = Paint();

    for (int row = 0; row < window.rows; row++) {
      for (int col = 0; col < kGridCols; col++) {
        final int cellStart =
            window.startMinute + row * 60 + col * kSlotMinutes;
        final int cellEnd = cellStart + kSlotMinutes;
        for (final GridEntry entry in entries) {
          if (entry.startMinute < cellEnd && entry.endMinute > cellStart) {
            fill.color = colorOfSlotKind(entry.kind);
            canvas.drawRect(
              Rect.fromLTWH(
                col * cellWidth,
                row * rowHeight,
                cellWidth,
                rowHeight,
              ),
              fill,
            );
            break;
          }
        }
      }
    }

    final Paint line = Paint()
      ..color = AppTokens.hairSoft
      ..strokeWidth = 1;
    for (int row = 0; row <= window.rows; row++) {
      final double y = row * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (int col = 0; col <= kGridCols; col++) {
      final double x = col * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_SlotPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.window != window;
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
  const _RulerPainter(this.window);

  final DayWindow window;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    // 半像素偏移让 1px 线压在像素中心，否则发虚成两列浅灰。
    final double x = size.width - 0.5;

    final Paint spine = Paint()
      ..color = AppTokens.hair
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), spine);

    // 整点：起点 → 终点共 `window.rows + 1` 个，含收尾那一条。
    final Paint hourTick = Paint()
      ..color = AppTokens.hairStrong
      ..strokeWidth = 1;
    for (int row = 0; row <= window.rows; row++) {
      final double y = row * kHourRowHeight;
      canvas.drawLine(
        Offset(x - AppTokens.axisTickHour, y),
        Offset(x, y),
        hourTick,
      );
    }

    // 半点：每个整点行中点一条短刻，构成「整点 + 半点」双档。
    final Paint halfTick = Paint()
      ..color = AppTokens.hair
      ..strokeWidth = 1;
    for (int row = 0; row < window.rows; row++) {
      final double y = row * kHourRowHeight + kHourRowHeight / 2;
      canvas.drawLine(
        Offset(x - AppTokens.axisTickHalf, y),
        Offset(x, y),
        halfTick,
      );
    }
  }

  /// 只在窗口变化时需要重绘。
  @override
  bool shouldRepaint(_RulerPainter oldDelegate) => oldDelegate.window != window;
}
