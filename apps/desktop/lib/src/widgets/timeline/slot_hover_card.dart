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
// 锚点纪律（Task 51 · 诉求 1）：浮窗**锚在鼠标指针上**，不锚在条目几何上。
// 指到条目里就出卡，卡片落在光标右下（右侧放不下翻左下、两边都放不下夹进屏内），
// 并且**硬约束「卡片顶边 ≥ 条目下缘 + 8px」** —— 卡片永不去盖当条任务，否则
// 左键打开详情、右键弹上下文菜单都会打到浮窗本体上（Task 50 的浮窗与 chip 同
// 一水平带并排，正是「点不动」的确切成因）。下方装不下时整体翻到光标 / 条目
// 上方，并同样退让为「卡片底边 ≤ 条目上缘 − 8px」。
//
// 焦点纪律：**打开浮窗不抢焦点**。焦点只在指针真的进入卡片本体时才请求
// （Esc 才有接收者），收起时把打开前的焦点还回去（`_returnFocus`）。
//
// 关闭态纪律：`overlayChildBuilder` 在未展开时返回零尺寸 `SizedBox`，
// **不渲染任何 `Text` / `Icon`**。否则既有的 `find.text('...')` 精确计数
// （`_expectNoChipText`、`find.text('✓')`）会凭空多出匹配项。
//
// 锚点仍算在 chip 的局部坐标系里（`CompositedTransformFollower` + `LayerLink`），
// 所以滚动时浮窗跟着条目一起走 —— 指针坐标只用来算这一次的偏移量。
// =============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
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
/// 200ms 是「从条目挪进浮窗」所需的最小缓冲：太短会在两者之间的间隙里误收，
/// 太长会让鼠标路过时满屏都是残留浮窗。Task 51 之后条目下缘到卡片顶边只有
/// ≥ [_kChipClearance] 的死区，这段宽限期正好是穿过死区的缓冲。
const int _kHideDelayMs = 200;

/// 卡片与光标的横向间距（用户原话「保持一定距离」）。
const double _kCursorGapX = 12;

/// 卡片与光标的纵向间距。
const double _kCursorGapY = 14;

/// 卡片与当条 chip 的最小净空。
///
/// 「不遮掩当条任务」的唯一可验判据：放得下时卡片顶边 ≥ chip 下缘 + 8，
/// 翻到上方时卡片底边 ≤ chip 顶边 − 8。中间这条 8px 死区保证指针停在条目上
/// 时左键 / 右键一定打在任务本身，而不是浮窗。
const double _kChipClearance = 8;

/// 指针位移超过它才通知重排。
///
/// 鼠标微动 1px 就重排会让浮窗逐帧抖动，也会连锁重绘卡片子树；2px 是人类
/// 无感、但足以让小位移被折叠的阈值。
const double _kCursorStepPx = 2;

/// 卡片高度的首帧兜底估算值。
///
/// 卡片高度只有布局后才知道，而「是否翻到上方」的判据需要它。首帧用这个
/// 估算值落位，同一帧的 post-frame 回调把实测高度换回来并重排一次；估算值
/// 只影响「贴近窗口下缘那一帧」的过渡，不影响任何稳态判据。
const double _kAssumedCardHeight = 120;

/// 条目悬停浮窗：包一个子控件，鼠标进入即在光标右下（或左下）展开信息卡。
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

  /// 锚点 → 浮窗的跟随链。
  ///
  /// 卡片位置不再「贴 chip 右缘」，而是用 [_cursor] 算出 card 的左上 / 右上角
  /// 相对 chip 左上角的偏移，再交给这条链承载 —— 好处是滚动时卡片仍随 chip
  /// 走（偏移跟着 leader 变换），不会停在旧坐标。
  final LayerLink _link = LayerLink();

  /// chip 自己的几何：卡片「不遮当条任务」硬约束的基准。
  final GlobalKey _chipKey = GlobalKey();

  /// 卡片本体的几何：卡片高度决定「是否翻到光标上方」，布局后才知道。
  final GlobalKey _cardKey = GlobalKey();

  /// 浮窗自己的焦点节点：**指针进入卡片本体**才请求焦点，Esc 才有接收者。
  final FocusNode _cardFocus = FocusNode(debugLabel: 'slot-hover-card');

  /// 指针全局坐标（`null` = 还没进过条目）。
  ///
  /// 用 `ValueNotifier` 而不是 `setState`：指针移动只重排浮窗子树，
  /// 不会把整张时间轴网格拖进重建。
  final ValueNotifier<Offset?> _cursor = ValueNotifier<Offset?>(null);

  /// 卡片实测高度（首帧前为 null，用 [_kAssumedCardHeight] 兜底）。
  double? _cardHeight;

  /// 收起定时器（悬停离开后的宽限期）。
  Timer? _hideTimer;

  /// 是否已展开。
  bool _open = false;

  /// 打开前的焦点，收起时还回去（键盘用户不会因为悬停一次就丢焦点）。
  FocusNode? _returnFocus;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _cursor.dispose();
    _cardFocus.dispose();
    super.dispose();
  }

  /// 指针进入锚点：先记坐标（打开的第一帧就要按光标落位），再立即展开。
  void _handleEnter(PointerEnterEvent event) {
    _cancelHide();
    _setCursor(event.position, force: true);
    _openCard();
  }

  /// 指针在锚点内移动：卡片跟着光标走（位移 ≤ [_kCursorStepPx] 时不动）。
  void _handleHover(PointerHoverEvent event) {
    _setCursor(event.position);
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

  /// 记指针坐标。位移不超过 [_kCursorStepPx] 时**不通知**（避免微动重排）。
  void _setCursor(Offset position, {bool force = false}) {
    final Offset? previous = _cursor.value;
    if (!force &&
        previous != null &&
        (position - previous).distance <= _kCursorStepPx) {
      return;
    }
    _cursor.value = position;
  }

  void _openCard() {
    if (_open) {
      return;
    }
    _cancelHide();
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _open = true);
    _portal.show();
    // 卡片高度要布局后才知道；同一帧末尾量一次，用来决定「是否翻到上方」。
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCardHeight());
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

  /// 量一次卡片高度；与已记值不同就重排一次（首帧用的是估算值）。
  void _measureCardHeight() {
    if (!mounted || !_open) {
      return;
    }
    final RenderObject? renderObject = _cardKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }
    final double height = renderObject.size.height;
    final double? previous = _cardHeight;
    if (previous != null && (previous - height).abs() < 0.5) {
      return;
    }
    _cardHeight = height;
    setState(() {});
  }

  /// 当条 chip 的全局矩形（`null` = 还没布局）。
  Rect? _chipRect() {
    final BuildContext? chipContext = _chipKey.currentContext;
    if (chipContext == null) {
      return null;
    }
    final RenderObject? renderObject = chipContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// 按光标算出卡片落位（follower 锚点 + 相对 chip 左上角的偏移）。
  ///
  /// 水平：默认光标右下（`cardLeft = cursor.dx + 12`）；右侧放不下 260 宽就翻
  /// 左下（`cardRight = cursor.dx - 12`）；左边也放不下就夹进屏内
  /// `0 .. screenWidth - 260`。
  ///
  /// 垂直：默认 `max(光标下 14px, chip 下缘 + 8px)`（后者是硬约束，保证不遮
  /// 当条任务）；底部放不下就整体翻到上方，此时改为
  /// `cardBottom = min(光标上 14px, chip 上缘 − 8px)`。
  _CardPlacement _placementFor(Size screen) {
    final Rect? chip = _chipRect();
    final Offset chipOrigin = chip?.topLeft ?? Offset.zero;
    final Offset cursor = _cursor.value ?? chip?.center ?? Offset.zero;
    final double cardWidth = kSlotHoverCardWidth;
    final double cardHeight = _cardHeight ?? _kAssumedCardHeight;

    // 水平：先试光标右下，再试光标左下，最后夹进屏内。
    bool leftSide = false;
    double cardLeft = cursor.dx + _kCursorGapX;
    if (cardLeft + cardWidth > screen.width) {
      final double flippedLeft = cursor.dx - _kCursorGapX - cardWidth;
      if (flippedLeft >= 0) {
        leftSide = true;
        cardLeft = flippedLeft;
      } else {
        // 两边都放不下：整只夹进屏内（此时不再强调「在光标哪一侧」）。
        cardLeft = math.max(0, screen.width - cardWidth);
      }
    }
    final double cardRight = cardLeft + cardWidth;

    // 垂直：先试光标下方（但绝不低于 chip 下缘 + 8px），放不下翻上方。
    final double cardTop = math.max(
      cursor.dy + _kCursorGapY,
      (chip?.bottom ?? 0) + _kChipClearance,
    );
    if (cardTop + cardHeight > screen.height) {
      double cardBottom = math.min(
        cursor.dy - _kCursorGapY,
        (chip?.top ?? screen.height) - _kChipClearance,
      );
      if (cardBottom - cardHeight < 0) {
        // 窗口太矮 / chip 已贴顶：上下都放不下时保「整只在屏内」，
        // 宁可压住 chip 也不把内容推到屏幕外（可用性优先于这条退让）。
        cardBottom = math.min(screen.height, cardHeight);
      }
      return _CardPlacement(
        leftSide ? Alignment.bottomRight : Alignment.bottomLeft,
        Offset(
          (leftSide ? cardRight : cardLeft) - chipOrigin.dx,
          cardBottom - chipOrigin.dy,
        ),
      );
    }

    return _CardPlacement(
      leftSide ? Alignment.topRight : Alignment.topLeft,
      Offset(
        (leftSide ? cardRight : cardLeft) - chipOrigin.dx,
        cardTop - chipOrigin.dy,
      ),
    );
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
        return _buildOverlay(overlayContext);
      },
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          // chip 的几何经由这只 key 取（`RenderMouseRegion` 的尺寸就是 chip 尺寸）。
          key: _chipKey,
          onEnter: (PointerEnterEvent event) => _handleEnter(event),
          onHover: (PointerHoverEvent event) => _handleHover(event),
          onExit: (PointerExitEvent event) => _handleExit(),
          child: widget.child,
        ),
      ),
    );
  }

  /// overlay 层：跟随锚点（读光标坐标重排）、固定宽度、不参与父级布局。
  Widget _buildOverlay(BuildContext overlayContext) {
    final ThemeTokens t = context.tokens;
    final Size screen = MediaQuery.sizeOf(overlayContext);
    return ValueListenableBuilder<Offset?>(
      valueListenable: _cursor,
      builder: (BuildContext _, Offset? _, Widget? _) {
        final _CardPlacement placement = _placementFor(screen);
        return Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: placement.followerAnchor,
            offset: placement.offset,
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
                onEnter: (PointerEnterEvent event) {
                  _cancelHide();
                  // 指针真的进了卡片本体才要焦点 —— 打开时就抢焦点会让
                  // 左键 / 右键打到浮窗上（Task 51 点击失效的成因之一）。
                  _cardFocus.requestFocus();
                },
                onExit: (PointerExitEvent event) => _handleExit(),
                child: SizedBox(key: _cardKey, child: _card(t)),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 卡片本体：起止时间 / 标题 / 详情 / 进展 / 状态 / 级别。
  ///
  /// 颜色全部走既有中性阶（`card` / `ink` / `ink2` / `meta` / `faint` /
  /// `hair` / `shadowTint`）：方格区禁用赭石 `accent`，浮窗同理 —— 它是方格区
  /// 的一部分，换色会让「同一屏两种色系」自相矛盾。
  Widget _card(ThemeTokens t) {
    final AppLocalizations l10n = AppLocalizations.of(context);
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
      lines.add(
        _metaLine(
          'slot-hover-card-detail',
          l10n.timelineHoverDetail(widget.detail),
          t,
        ),
      );
    }
    if (widget.showNote && widget.note.isNotEmpty) {
      lines.add(
        _metaLine('slot-hover-card-note', l10n.timelineHoverNote(widget.note), t),
      );
    }
    if (widget.stateLabel != null) {
      lines.add(
        _footLine(
          'slot-hover-card-state',
          l10n.timelineHoverState(widget.stateLabel!),
          t,
        ),
      );
    }
    if (widget.levelLabel != null) {
      lines.add(
        _footLine(
          'slot-hover-card-level',
          l10n.timelineHoverLevel(widget.levelLabel!),
          t,
        ),
      );
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

/// 卡片落位：`targetAnchor` 恒为 `topLeft`（LayerLink 的 leader 点 = chip 左上
/// 角），换边只改 follower 自己贴哪个角、以及「那个角 − chip 左上角」的偏移。
@immutable
class _CardPlacement {
  const _CardPlacement(this.followerAnchor, this.offset);

  /// 卡片自身贴向 leader 点的角。
  final Alignment followerAnchor;

  /// 该角落相对 chip 左上角的偏移。
  final Offset offset;
}