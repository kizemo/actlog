// =============================================================================
// 方格时间轴 · 条目悬停浮窗
// =============================================================================
// 为什么需要它：Task 50 之后条目 chip 里**只剩标题**（起始时刻与「进展：」
// 都被删掉了，因为 15 分钟格只有 20px 高、两个纸片上的字互相挤）。删掉不等于
// 丢掉 —— 起止时间、详情、进展、状态、级别全部搬进这只悬停浮窗，鼠标停在
// 条目上就能看全，不占格内一个像素。
//
// 为什么必须挂 `OverlayPortal`：方格区外层 `Container` 是
// `clipBehavior: Clip.antiAlias`（`day_grid.dart` 的 `day-grid`），任何直接
// 画在条目子树里的浮层都会被裁掉。`OverlayPortal` 把浮层挂到最近的 `Overlay`
// 上，因此能被裁切区域之外的坐标系承载。
//
// 关闭态纪律：`overlayChildBuilder` 在未展开时返回零尺寸 `SizedBox`，
// **不渲染任何 `Text` / `Icon`**。否则既有的 `find.text('...')` 精确计数
// （`_expectNoChipText`、`find.text('✓')`）会凭空多出匹配项。
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_tokens.dart';
import 'slot_state.dart';

/// 悬停浮窗的固定宽度。
///
/// 260 与「条目正文最小排版宽度」（`kChipContentMinWidth`）同阶：再窄会让
/// 「09:00–10:00」这类起止串与标题折成两三行；再宽会在窄视口里越出窗口右缘，
/// 反而要更频繁地翻边。
const double kSlotHoverCardWidth = 260;

/// 指针离开后到收起之间的宽限期。
///
/// 200ms 是「从条目挪进浮窗」所需的最小缓冲：太短会在两者之间的 8px 间隙里
/// 误收，太长会让鼠标路过时满屏都是残留浮窗。
const int _kHideDelayMs = 200;

/// 条目悬停浮窗：包一个子控件，鼠标进入即在它旁边展开信息卡。
///
/// 只做展示，不写库、不改状态 —— 所有字段都是构造时传入的只读快照，
/// 因此它不依赖 `ProviderContainer`，widget 测试可以裸 pump。
class SlotHoverCard extends StatefulWidget {
  /// 创建悬停浮窗。
  const SlotHoverCard({
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.child,
    this.detail = '',
    this.note = '',
    this.stateLabel,
    this.levelLabel,
    this.showNote = true,
    super.key,
  });

  /// 条目标题（浮窗正文首行）。
  final String title;

  /// 条目起点分钟（当日零点起算）。
  final int startMinute;

  /// 条目终点分钟。
  final int endMinute;

  /// 详情串；空串时不渲染该行。
  final String detail;

  /// 进展串（`result_note`）；空串或 [showNote] 为假时不渲染该行。
  final String note;

  /// 四态中文名（`打卡 / 回填 / 完成 / 计划`）；null 时不渲染该行。
  final String? stateLabel;

  /// 四象限中文名（`重要且紧急` 等）；null（未分级）时不渲染该行。
  final String? levelLabel;

  /// 是否显示进展行 —— 极简模式下为假（见 `DayGrid.minimal`）。
  final bool showNote;

  /// 锚点子树（条目正文）。
  final Widget child;

  @override
  State<SlotHoverCard> createState() => _SlotHoverCardState();
}

class _SlotHoverCardState extends State<SlotHoverCard> {
  /// overlay 层开关（`show()` / `hide()` 直接增删 overlay 子节点）。
  final OverlayPortalController _portal = OverlayPortalController();

  /// 锚点 → 浮窗的跟随链：滚动时浮窗贴着条目走，不会停在旧坐标。
  final LayerLink _link = LayerLink();

  /// 浮窗自己的焦点节点：打开即请求焦点，Esc 才有接收者。
  final FocusNode _cardFocus = FocusNode(debugLabel: 'slot-hover-card');

  /// 收起定时器（悬停离开后的宽限期）。
  Timer? _hideTimer;

  /// 是否已展开。
  bool _open = false;

  /// 右侧空间不够时翻到锚点左边（防止 260px 卡片越出窗口右缘）。
  bool _flipLeft = false;

  /// 打开前的焦点，收起时还回去（键盘用户不会因为悬停一次就丢焦点）。
  FocusNode? _returnFocus;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _cardFocus.dispose();
    super.dispose();
  }

  /// 指针进入锚点：立即展开。
  void _handleEnter() {
    _cancelHide();
    _openCard();
  }

  /// 指针离开锚点 / 浮窗：给一个宽限期再收，允许挪进浮窗继续读。
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

  void _openCard() {
    if (_open) {
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
        _cardFocus.requestFocus();
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
      _cardFocus.unfocus();
    }
  }

  /// 锚点右侧放不下整只浮窗时翻到左边。
  bool _shouldFlipLeft() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final double anchorRight =
        renderObject.localToGlobal(Offset(renderObject.size.width, 0)).dx;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return anchorRight + kSlotHoverCardWidth + 12 > screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (BuildContext overlayContext) {
        // 关闭态必须是零尺寸、零文本：否则既有的 `find.text(...)` 精确计数
        // 会被一只「看不见但存在」的卡片污染。
        if (!_open) {
          return const SizedBox.shrink();
        }
        return _buildOverlay();
      },
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (PointerEnterEvent event) => _handleEnter(),
          onExit: (PointerExitEvent event) => _handleExit(),
          child: widget.child,
        ),
      ),
    );
  }

  /// overlay 层：跟随锚点、固定宽度、不参与父级布局。
  Widget _buildOverlay() {
    final ThemeTokens t = context.tokens;
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: _flipLeft ? Alignment.topRight : Alignment.topLeft,
        followerAnchor: _flipLeft ? Alignment.topRight : Alignment.topLeft,
        offset: Offset(_flipLeft ? -8 : 8, 0),
        child: Focus(
          focusNode: _cardFocus,
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
            child: _card(t),
          ),
        ),
      ),
    );
  }

  /// 卡片本体：起止时间 / 标题 / 详情 / 进展 / 状态 / 级别。
  ///
  /// 颜色全部走既有中性阶（`card` / `ink` / `ink2` / `meta` / `faint` /
  /// `hair` / `shadowTint`）：方格区禁用赭石 `accent`，浮窗同理 —— 它是方格区
  /// 的一部分，换色会让「同一屏两种色系」自相矛盾。
  Widget _card(ThemeTokens t) {
    final List<Widget> lines = <Widget>[
      Text(
        '${formatMinute(widget.startMinute)}–${formatMinute(widget.endMinute)}',
        key: const ValueKey<String>('slot-hover-card-time'),
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          color: t.faint,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 3),
      Text(
        widget.title,
        key: const ValueKey<String>('slot-hover-card-title'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, height: 1.3, color: t.ink),
      ),
    ];
    if (widget.detail.isNotEmpty) {
      lines.add(_metaLine('slot-hover-card-detail', '详情：${widget.detail}', t));
    }
    if (widget.showNote && widget.note.isNotEmpty) {
      lines.add(_metaLine('slot-hover-card-note', '进展：${widget.note}', t));
    }
    if (widget.stateLabel != null) {
      lines.add(_footLine('slot-hover-card-state', '状态：${widget.stateLabel}', t));
    }
    if (widget.levelLabel != null) {
      lines.add(_footLine('slot-hover-card-level', '级别：${widget.levelLabel}', t));
    }
    return Container(
      key: const ValueKey<String>('slot-hover-card'),
      width: kSlotHoverCardWidth,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.ink),
        boxShadow: <BoxShadow>[
          BoxShadow(
            offset: const Offset(6, 6),
            color: t.shadowTint.withValues(alpha: 0.09),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  /// 正文级信息行（详情 / 进展）：12.5px、`meta`、最多三行。
  Widget _metaLine(String keyValue, String text, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: ValueKey<String>(keyValue),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, height: 1.35, color: t.meta),
      ),
    );
  }

  /// 脚注级信息行（状态 / 级别）：12px、`faint`、单行。
  Widget _footLine(String keyValue, String text, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        text,
        key: ValueKey<String>(keyValue),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, height: 1.3, color: t.faint),
      ),
    );
  }
}