// =============================================================================
// 四维度优先级标记 · 悬停气泡（Task 36 · T1）
// =============================================================================
// 解决的真问题：
//   `PriorityMarks` 只画两枚标记（星 + 铃，各自实心/空心）—— 用户看得见结论，
//   看不见**为什么**，也没有任何入口在「这条已经在时间轴上」之后改分级。
//   标记因此是死的。
//
// 本组件把标记变成活入口：
//   悬停（或点标记）⇒ 气泡浮出，写明这条所处的紧急/重要两维取值 + 人话结论 +
//   行动建议；气泡内两个维度各二选一，点一下就落库，标记随数据流自动回写。
//
// 三条硬约束（改这个文件前先读）：
//   1. **不推动布局、不被裁剪**：气泡挂在 `OverlayPortal` 上，用
//      `CompositedTransformFollower` 贴着标记浮起。方格容器的
//      `clipBehavior: Clip.antiAlias`（`day_grid.dart`）会裁掉任何子树内的浮层，
//      留在子树里必被切；`OverlayPortal` 同时也不占父级尺寸，不会挤动排版。
//   2. **不污染既有标记通道**：气泡内容**只在打开时**构建，关闭态零 `Text`、
//      零 `Icon`，所以 `find.byKey` / `find.byIcon` 之类的精确计数断言不受影响。
//      标记本身仍由 `PriorityMarks` 原样渲染（值级 `Key` 与尺寸语义不变）。
//   3. **未分级不渲染**：`quadrant == null` 时本组件直接退化成
//      `PriorityMarks(quadrant: null)`（零尺寸），不画标记、不留占位、不出气泡。
//
// 赭石纪律（`TOKENS.md` §1）：气泡里**没有**赭石。当前取值只走
// 「`--ink` 反白 / `--card` 空底」两档，赭石只表缺口与警示，不当选中色。
// =============================================================================

import 'dart:async';

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'focus_ring.dart';
import 'priority_marks.dart';

/// 气泡卡片宽度（与 `task36-a-roulette.html` 的 `.bub` 同宽）。
const double kPriorityBubbleWidth = 344;

/// 指针三角宽 7 / 高 12 之外再留的呼吸（对齐 `.bub` 的 `left: 36px` 节奏）。
const double _kPointerWidth = 7;

/// 悬停离开后延迟收起（毫秒）：留出「从标记挪到气泡」的通过时间。
const int _kHideDelayMs = 200;

/// 名称前的优先级标记 + **悬停气泡**（读两维取值、点一下改分级）。
///
/// 用法：替换掉原来的 `PriorityMarks(quadrant: q)` —— 字形渲染完全一致，
/// 只是多了一层可悬停/可点击的锚点与一个 overlay 气泡。
class PriorityHoverBubble extends StatefulWidget {
  /// 创建悬停气泡锚点。
  ///
  /// [onChanged] 为 null 表示**只读气泡**：气泡照样显示两维取值与建议，
  /// 但维度芯片不可点、不进 Tab 序列（例如待办池里的待办：`TodoRepository`
  /// 目前没有 `setQuadrant`，写入端还没开放）。
  const PriorityHoverBubble({
    required this.quadrant,
    required this.title,
    this.onChanged,
    this.markSize = 10,
    this.ownerKey,
    super.key,
  });

  /// 要渲染并解释的象限；null = 未分级（不渲染任何东西）。
  final Quadrant? quadrant;

  /// 计划名（气泡抬头；过长省略）。
  final String title;

  /// 维度改选回调；`null` = 只读气泡。
  final ValueChanged<Quadrant?>? onChanged;

  /// 字形字号，透传给 [PriorityMarks]（默认 10，与行内元信息同级）。
  final double markSize;

  /// 气泡内控件的 key 前缀，用于同一屏多条目并存时区分（测试也靠它定位）。
  final String? ownerKey;

  @override
  State<PriorityHoverBubble> createState() => _PriorityHoverBubbleState();
}

class _PriorityHoverBubbleState extends State<PriorityHoverBubble> {
  /// overlay 层开关（`show()` / `hide()` 直接增删 overlay 子节点）。
  final OverlayPortalController _portal = OverlayPortalController();

  /// 锚点 → 气泡的跟随链，保证滚动时气泡贴着标记走。
  final LayerLink _link = LayerLink();

  /// 气泡自己的焦点节点：打开即请求焦点，Esc 才有接收者。
  final FocusNode _bubbleFocus = FocusNode(debugLabel: 'priority-bubble');

  /// 收起定时器（悬停离开后的宽限期）。
  Timer? _hideTimer;

  /// 是否已展开。
  bool _open = false;

  /// 右侧空间不够时翻到锚点左边（防止 344px 气泡越出窗口右缘）。
  bool _flipLeft = false;

  /// 打开前的焦点，收起时还回去（键盘用户不会因为悬停一次就丢焦点）。
  FocusNode? _returnFocus;

  bool get _readOnly => widget.onChanged == null;

  @override
  void didUpdateWidget(PriorityHoverBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 分级被清空（或换到别的条目）⇒ 气泡必须立刻消失，否则会解释一个
    // 已经不存在的象限。
    if (widget.quadrant == null && _open) {
      _close();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _bubbleFocus.dispose();
    super.dispose();
  }

  /// 指针进入锚点：立即展开。
  void _handleEnter() {
    _cancelHide();
    _openBubble();
  }

  /// 指针离开锚点 / 气泡：给一个宽限期再收，允许挪进气泡继续操作。
  void _handleExit() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: _kHideDelayMs), () {
      if (mounted) {
        _close();
      }
    });
  }

  void _cancelHide() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _openBubble() {
    if (_open || widget.quadrant == null) {
      return;
    }
    _cancelHide();
    _flipLeft = _shouldFlipLeft();
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _open = true);
    _portal.show();
    // overlay 子节点这一帧才挂上，焦点只能下一帧请求。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open) {
        _bubbleFocus.requestFocus();
      }
    });
  }

  void _close() {
    if (!_open) {
      return;
    }
    _cancelHide();
    setState(() => _open = false);
    _portal.hide();
    final FocusNode? back = _returnFocus;
    _returnFocus = null;
    if (back != null && back.context != null) {
      back.requestFocus();
    } else {
      _bubbleFocus.unfocus();
    }
  }

  /// 锚点右侧放不下整只气泡时翻到左边。
  bool _shouldFlipLeft() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final double anchorRight =
        renderObject.localToGlobal(Offset(renderObject.size.width, 0)).dx;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return anchorRight + _kPointerWidth + kPriorityBubbleWidth + 12 >
        screenWidth;
  }

  /// 改选某一维：**另一维保持不变**（与 `PriorityMarkPicker` 同一口径）。
  void _pick({required bool isUrgency, required bool value}) {
    final Quadrant? current = widget.quadrant;
    if (current == null) {
      return;
    }
    final Quadrant next = isUrgency
        ? quadrantOf(important: current.isImportant, urgent: value)
        : quadrantOf(important: value, urgent: current.isUrgent);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final Quadrant? value = widget.quadrant;
    if (value == null) {
      // 未分级：与 `PriorityMarks` 完全一致（零尺寸、无占位、无气泡）。
      return PriorityMarks(quadrant: null, size: widget.markSize);
    }
    final QuadrantStyle style = QuadrantStyle.of(value);
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (BuildContext overlayContext) =>
          _buildOverlay(overlayContext, value),
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (PointerEnterEvent event) => _handleEnter(),
          onExit: (PointerExitEvent event) => _handleExit(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open ? _close() : _openBubble(),
            child: Semantics(
              button: true,
              // 读屏通道：象限结论 + **两维取值**，"悬停"对读屏用户无意义，
              // 所以换成「可按下」语义（Enter/Space 由按钮语义带动点击）。
              label: '${style.label}，紧急：'
                  '${value.isUrgent ? '是' : '否'}，重要：'
                  '${value.isImportant ? '是' : '否'}',
              child: PriorityMarks(quadrant: value, size: widget.markSize),
            ),
          ),
        ),
      ),
    );
  }

  /// overlay 层：跟随锚点、固定尺寸、不参与父级布局。
  Widget _buildOverlay(BuildContext overlayContext, Quadrant value) {
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: _flipLeft ? Alignment.topLeft : Alignment.topRight,
        followerAnchor: _flipLeft ? Alignment.topRight : Alignment.topLeft,
        offset: Offset(_flipLeft ? -8 : 8, -10),
        child: Focus(
          focusNode: _bubbleFocus,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _close();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (PointerEnterEvent event) => _cancelHide(),
            onExit: (PointerExitEvent event) => _handleExit(),
            child: _BubbleShell(
              pointerOnLeft: !_flipLeft,
              child: _bubbleCard(value),
            ),
          ),
        ),
      ),
    );
  }

  /// 气泡本体（抬头 · 两维 · 结论 · 建议 · 快捷键）。
  Widget _bubbleCard(Quadrant value) {
    final ThemeTokens tokens = context.tokens;
    final QuadrantStyle style = QuadrantStyle.of(value);
    return Container(
      key: const ValueKey<String>('priority-hover-bubble'),
      width: kPriorityBubbleWidth,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.ink),
        boxShadow: <BoxShadow>[
          // 硬投影 `6px 6px 0 rgba(50,43,35,.09)`（浅色档 ink 的 9%），不是柔和阴影。
          // `shadowTint` 无静态别名，必须从 `ThemeTokens` 取 ⇒ 深色档自动跟随。
          BoxShadow(
            color: tokens.shadowTint.withValues(alpha: 0.09),
            offset: const Offset(6, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(value),
          const SizedBox(height: 9),
          _dimensionRow(isUrgency: true, current: value.isUrgent),
          const SizedBox(height: 5),
          _dimensionRow(isUrgency: false, current: value.isImportant),
          const SizedBox(height: 9),
          _conclusion(style),
          const SizedBox(height: 9),
          _footer(),
        ],
      ),
    );
  }

  /// 抬头：`Q1` 方框 + 计划名 + `Esc` 键帽。
  Widget _header(Quadrant value) {
    final ThemeTokens tokens = context.tokens;
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: tokens.ink),
          ),
          child: Text(
            _quadrantCode(value),
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 10.5,
              height: 1.2,
              color: tokens.ink,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: tokens.ink,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const _Keycap(text: 'Esc'),
      ],
    );
  }

  /// 一个维度一行：维度名 + 两枚二选一芯片（当前取值反白）。
  Widget _dimensionRow({required bool isUrgency, required bool current}) {
    final ThemeTokens tokens = context.tokens;
    final bool enabled = !_readOnly;
    final String onLabel = isUrgency ? '紧急' : '重要';
    final String offLabel = isUrgency ? '不紧急' : '不重要';
    final String prefix = '${widget.ownerKey ?? 'priority'}-'
        '${isUrgency ? 'urgent' : 'important'}';
    return Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          child: Text(
            onLabel,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 11,
              height: 1.2,
              color: tokens.meta,
            ),
          ),
        ),
        _DimensionChip(
          key: ValueKey<String>('$prefix-on'),
          // 取值只走 `markOf` —— 气泡与主通道共用同一份标记描述，
          // 不许在这里另写一套字形/图标（同 key、同 Icon 才谈得上「一致」）。
          mark: markOf(
            axis: isUrgency ? PriorityAxis.urgency : PriorityAxis.importance,
            positive: true,
          ),
          label: onLabel,
          selected: current,
          enabled: enabled,
          onTap: () => _pick(isUrgency: isUrgency, value: true),
        ),
        const SizedBox(width: 6),
        _DimensionChip(
          key: ValueKey<String>('$prefix-off'),
          mark: markOf(
            axis: isUrgency ? PriorityAxis.urgency : PriorityAxis.importance,
            positive: false,
          ),
          label: offLabel,
          selected: !current,
          enabled: enabled,
          onTap: () => _pick(isUrgency: isUrgency, value: false),
        ),
      ],
    );
  }

  /// 人话结论 + 行动建议。
  Widget _conclusion(QuadrantStyle style) {
    final ThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              '当前',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 10.5,
                height: 1.2,
                color: tokens.faint,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              style.label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontFamilyFallback: AppFonts.bodyFallback,
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: tokens.ink,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              style.shortLabel,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontFamilyFallback: AppFonts.bodyFallback,
                fontSize: 12.5,
                height: 1.3,
                color: tokens.meta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          style.advice,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 13,
            height: 1.4,
            color: tokens.meta,
          ),
        ),
      ],
    );
  }

  /// 底部快捷键提示。
  Widget _footer() {
    final ThemeTokens tokens = context.tokens;
    return Row(
      children: <Widget>[
        const _Keycap(text: 'Esc'),
        const SizedBox(width: 4),
        Text(
          '关闭',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 12,
            height: 1.2,
            color: tokens.faint,
          ),
        ),
        const Spacer(),
        Text(
          _readOnly ? '点标记开关 · 分级写入未开放' : '点标记开关 · 点维度改分级',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 12,
            height: 1.2,
            color: tokens.faint,
          ),
        ),
      ],
    );
  }
}

/// `Quadrant` → 抬头里的 `Q1`～`Q4`（穷尽 switch，枚举加了新值这里会编译失败）。
String _quadrantCode(Quadrant quadrant) {
  switch (quadrant) {
    case Quadrant.q1:
      return 'Q1';
    case Quadrant.q2:
      return 'Q2';
    case Quadrant.q3:
      return 'Q3';
    case Quadrant.q4:
      return 'Q4';
  }
}

/// 气泡外框：左（或右）向指针三角 + 卡片。
class _BubbleShell extends StatelessWidget {
  const _BubbleShell({required this.pointerOnLeft, required this.child});

  /// 指针在左（气泡在标记右边）还是右（翻了边）。
  final bool pointerOnLeft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final Widget pointer = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CustomPaint(
        size: const Size(_kPointerWidth, 12),
        painter: _PointerPainter(
          pointsLeft: pointerOnLeft,
          outline: tokens.ink,
          fill: tokens.card,
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pointerOnLeft
          ? <Widget>[pointer, child]
          : <Widget>[child, pointer],
    );
  }
}

/// 指针三角：墨色外描边 + 卡片色内填充（对齐 `.bub::before/::after`）。
class _PointerPainter extends CustomPainter {
  const _PointerPainter({
    required this.pointsLeft,
    required this.outline,
    required this.fill,
  });

  final bool pointsLeft;

  /// 外三角描边色（浅色档 = `ink`）。
  final Color outline;

  /// 内三角填充色（浅色档 = `card`）。
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // 外三角：墨色，7×12。
    final Path outer = Path();
    // 内三角：卡片色，收进 1px 边线，视觉上只剩描边。
    final Path inner = Path();
    if (pointsLeft) {
      outer
        ..moveTo(0, size.height / 2)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..close();
      inner
        ..moveTo(1, size.height / 2)
        ..lineTo(size.width, 1)
        ..lineTo(size.width, size.height - 1)
        ..close();
    } else {
      outer
        ..moveTo(size.width, size.height / 2)
        ..lineTo(0, 0)
        ..lineTo(0, size.height)
        ..close();
      inner
        ..moveTo(size.width - 1, size.height / 2)
        ..lineTo(0, 1)
        ..lineTo(0, size.height - 1)
        ..close();
    }
    canvas.drawPath(outer, Paint()..color = outline);
    canvas.drawPath(inner, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) =>
      oldDelegate.pointsLeft != pointsLeft ||
      oldDelegate.outline != outline ||
      oldDelegate.fill != fill;
}

/// 键帽（`Esc`）：等宽小字 + 细边 + 下沉底。
class _Keycap extends StatelessWidget {
  const _Keycap({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.keybg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: tokens.hair),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: 10,
          height: 1.2,
          color: tokens.meta,
        ),
      ),
    );
  }
}

/// 一枚维度芯片：字形 + 中文标签；选中 = `--ink` 反白。
///
/// 选中态**只**走墨色反白，不用象限提示色 —— 赭石/红绿在气泡里当选中色会
/// 破坏「赭石只表缺口」的纪律，也会让「当前」变成四个颜色之一而不是一个状态。
class _DimensionChip extends StatefulWidget {
  const _DimensionChip({
    required this.mark,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  /// 该维度取值对应的标记描述（与 `PriorityMarks` 同一份来源）。
  final PriorityMark mark;
  final String label;
  final bool selected;

  /// 只读气泡里为 false：不包 `InkWell`、不进 Tab 序列。
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_DimensionChip> createState() => _DimensionChipState();
}

class _DimensionChipState extends State<_DimensionChip> {
  /// 芯片自己的焦点节点（既给 `InkWell`，也给 `FocusRing`）。
  final FocusNode _node = FocusNode(debugLabel: 'priority-bubble-chip');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  /// 标记本体：Material 图标（同一枚图标的实心 / 空心，由 `filled` 决定）。
  ///
  /// 配色刻意**不取** `mark.color`（赭石 / 弱化色）—— 气泡里的选中色只走
  /// 墨色反白，赭石不得进气泡（见文件头「赭石纪律」）；重要 / 不重要的区分
  /// 在这里由**填充 / 空心**承担，与主通道同一套语义（共用 `resolvedIcon`，
  /// 不许在气泡里另写一套图标）。
  Widget _markBody(bool on) {
    final ThemeTokens tokens = context.tokens;
    final Color color = on ? tokens.paper : tokens.meta;
    final String? glyph = widget.mark.glyph;
    if (glyph != null) {
      return Text(
        glyph,
        // 与 `PriorityMarks` 用**同一枚**值级 key：气泡与主通道同 key，
        // 「同一份描述对象」这件事在两处必须能对上号。
        key: widget.mark.key,
        style: TextStyle(
          // 文本通道当前无 spec 使用；族声明与 `PriorityMarks` 保持一致。
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
          fontSize: 10,
          height: 1.1,
          fontWeight: widget.mark.emphasis,
          color: color,
        ),
      );
    }
    return Icon(
      widget.mark.resolvedIcon,
      key: widget.mark.key,
      size: 11,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final bool on = widget.selected;
    final Widget body = Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: on ? tokens.ink : tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: on ? tokens.ink : tokens.hairStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _markBody(on),
          const SizedBox(width: 3),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 12.5,
              height: 1.2,
              color: on ? tokens.paper : tokens.ink2,
            ),
          ),
        ],
      ),
    );
    if (!widget.enabled) {
      return body;
    }
    return Semantics(
      button: true,
      selected: on,
      label: widget.label,
      excludeSemantics: true,
      child: FocusRing(
        focusNode: _node,
        ringKey: const ValueKey<String>('focus-ring-border-priority-bubble'),
        child: InkWell(
          focusNode: _node,
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: body,
        ),
      ),
    );
  }
}