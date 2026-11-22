import 'package:flutter/material.dart';
// `OverflowBoxFit` 只在 rendering 层定义，`material.dart` 不导出它。
import 'package:flutter/rendering.dart' show OverflowBoxFit;

/// 单行文本：装得下就居中静态，装不下就从右向左滚动。
///
/// 判定口径（硬契约）：用 [TextPainter] 按「实际生效样式 + 真实 textScaler」量出
/// 单行宽 `measured`；`measured <= maxWidth`（留 [widthTolerance] 容差）走**静态
/// 分支** —— 只渲染一个 [Text]（[staticTextKey]），居中、不滚；否则走**滚动分支**
/// —— 两份文本 + [gapPixels] 间隔，循环动画把整条内容向左推 `measured + gap`，
/// 推完恰好等于一个周期，首尾相接、无缝回卷。
///
/// 为什么不交给 `TextOverflow.ellipsis`：省略号会丢字，而这里要的是「长句也能
/// 读全」。长句由**这一行自己**处理溢出，调用方不需要预先知道哪一行会超。
///
/// 无障碍：`MediaQuery.disableAnimations`（系统「减少动态效果」）为真时退回静态
/// 单副本 —— 宁可裁掉尾巴，也不做持续运动。
class MarqueeLine extends StatefulWidget {
  /// 创建单行跑马灯。
  const MarqueeLine({
    super.key,
    required this.text,
    this.style,
    this.speedPixelsPerSecond = 40,
    this.gapPixels = 48,
  });

  /// 要显示的单行文本。
  final String text;

  /// 文本样式；为空时沿用 [DefaultTextStyle]（外层再强制 `height: 1.2`）。
  final TextStyle? style;

  /// 滚动速度（逻辑 px/s）。
  final double speedPixelsPerSecond;

  /// 两份文本之间的间隔（逻辑 px）。
  final double gapPixels;

  /// 静态分支里那唯一一个 [Text] 的 key。
  static const Key staticTextKey = Key('marquee.static');

  /// 滚动分支第一副本的 key。
  static const Key animatedTextKeyA = Key('marquee.animated.a');

  /// 滚动分支第二副本的 key。
  static const Key animatedTextKeyB = Key('marquee.animated.b');

  /// 判宽容差（逻辑 px）。
  ///
  /// [TextPainter] 量宽与 [Text] 的布局宽存在亚像素差；不留容差的话，
  /// 「只超三分之一像素」也会被判成滚动分支，短句白白开始滚。
  static const double widthTolerance = 0.5;

  @override
  State<MarqueeLine> createState() => _MarqueeLineState();
}

class _MarqueeLineState extends State<MarqueeLine>
    with SingleTickerProviderStateMixin {
  /// 循环驱动器；静态分支下保持停止。
  late final AnimationController _controller;

  /// 上一次交给控制器的目标（是否滚动 + 周期），用于避免每帧重复排回调。
  bool? _appliedScroll;
  Duration? _appliedDuration;

  /// 文本 / 样式 / 速度 / 间隔变了 ⇒ 下一帧把相位重置回 0。
  bool _restartPending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // 真实周期在布局后按量宽结算；这里只给一个合法初值。
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(covariant MarqueeLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.speedPixelsPerSecond != widget.speedPixelsPerSecond ||
        oldWidget.gapPixels != widget.gapPixels) {
      // 旧位移是按旧量宽算的，必须重算相位，否则会跳帧。
      _restartPending = true;
      _appliedScroll = null;
      _appliedDuration = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 把「这一帧量出来的结论」交给控制器。
  ///
  /// 为什么不在 build 里直接动控制器：`reset()` / `stop()` 会 `notifyListeners`，
  /// 在构建期触发 [AnimatedBuilder] 的 `setState` 会撞上
  /// 「setState() called during build」。所以判定仍在构建期完成，副作用推迟到
  /// 帧末 —— 第一帧相位恒为 0，肉眼无跳变。
  void _syncController(bool scroll, Duration? duration) {
    if (!_restartPending &&
        _appliedScroll == scroll &&
        _appliedDuration == duration) {
      return;
    }
    _appliedScroll = scroll;
    _appliedDuration = duration;
    final bool restart = _restartPending;
    _restartPending = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _applyToController(scroll: scroll, duration: duration, restart: restart);
    });
  }

  /// 帧末落地：静态 ⇒ 停表归零；滚动 ⇒ 定周期、必要时归零、再循环。
  void _applyToController({
    required bool scroll,
    required Duration? duration,
    required bool restart,
  }) {
    if (!scroll || duration == null) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.reset();
      return;
    }
    final bool durationChanged = _controller.duration != duration;
    if (durationChanged) {
      _controller.duration = duration;
    }
    if (restart || durationChanged) {
      _controller.reset();
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle =
        widget.style ?? DefaultTextStyle.of(context).style;
    // 行盒高度锁定 1.2：两行堆叠时不因字体度量差异抖动，也避免贴边溢出。
    final TextStyle effectiveStyle = baseStyle.copyWith(height: 1.2);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          textDirection: Directionality.of(context),
          maxLines: 1,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final double measured = painter.width;
        painter.dispose();

        final bool shouldScroll =
            measured - constraints.maxWidth > MarqueeLine.widthTolerance &&
                !MediaQuery.of(context).disableAnimations;
        final double gap = widget.gapPixels;
        final double travel = measured + gap;
        final double speed =
            widget.speedPixelsPerSecond > 0 ? widget.speedPixelsPerSecond : 1;
        final Duration duration = Duration(
          milliseconds: (travel / speed * 1000).round(),
        );
        _syncController(shouldScroll, shouldScroll ? duration : null);

        if (!shouldScroll) {
          return ClipRect(
            child: Center(
              child: Text(
                widget.text,
                key: MarqueeLine.staticTextKey,
                style: effectiveStyle,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 两份文本 + 间隔的总宽必然大于可用宽度 ⇒ 不能被父约束挤窄，
        // 否则 Row 会报 RenderFlex overflow。OverflowBox 放行宽度，
        // `deferToChild` 保证自身高度仍是自然文字高（不写死像素）。
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              // 偏移为负、随时间增大 ⇒ 固定从右向左。
              return Transform.translate(
                offset: Offset(-_controller.value * travel, 0),
                child: child,
              );
            },
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              fit: OverflowBoxFit.deferToChild,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.text,
                    key: MarqueeLine.animatedTextKeyA,
                    style: effectiveStyle,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  SizedBox(width: gap),
                  Text(
                    widget.text,
                    key: MarqueeLine.animatedTextKeyB,
                    style: effectiveStyle,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}