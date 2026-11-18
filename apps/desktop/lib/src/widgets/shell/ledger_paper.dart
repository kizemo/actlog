import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// 账页横线绘制器（等价原型 `.ledger` 的 CSS 背景）。
///
/// 原型 `design-demos/v2-ledger.html`：
/// `repeating-linear-gradient(to bottom, transparent 0 31px, rgba(122,110,88,.055) 31px 32px)`
/// —— 每 [LedgerPaper.ruleHeight] 像素在格子底部画一条 1px 横线。
///
/// 用 [CustomPainter] 自绘而不是 `Divider` / `ListView.separated`：
/// 横线必须铺满**滚动视口**（不随内容高度增长、不参与布局、不接收点击）。
/// 颜色取 [AppTokens.meta] + 0.055 alpha，等价原型那条极淡暖灰线，
/// 同时满足「颜色只来自 AppTokens、不写死 hex」的口径。
class LedgerRulePainter extends CustomPainter {
  /// 创建横线绘制器。
  const LedgerRulePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppTokens.meta.withValues(alpha: 0.055);
    for (double top = LedgerPaper.ruleHeight - 1;
        top < size.height;
        top += LedgerPaper.ruleHeight) {
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LedgerRulePainter oldDelegate) => false;
}

/// 账页（B 版「墨径 · 账页流」正文卷）。
///
/// 结构等价原型 `div.ledger > div.ledger-pad`：
/// - 外层 [CustomPaint] 负责横线底（铺满滚动视口）；
/// - [SingleChildScrollView] 负责滚动（等价 `.ledger{overflow:auto}`）；
/// - [Center] + [ConstrainedBox] 限宽（标准 770 / 宽屏 860），等价 `.ledger-pad{max-width:770px;margin:0 auto}`；
/// - [SizedBox.width.infinity] 让正文按列宽撑满，等价 block 元素的默认行为。
class LedgerPaper extends StatelessWidget {
  /// 创建账页容器。
  const LedgerPaper({
    required this.child,
    this.maxWidth = standardMaxWidth,
    this.padding = const EdgeInsets.fromLTRB(26, 20, 26, 30),
    this.pinnedHeader,
    super.key,
  });

  /// 标准视口账页限宽（`.ledger-pad{max-width:770px}`）。
  static const double standardMaxWidth = 770;

  /// `>= 1920` 视口账页限宽（`.ledger-pad{max-width:860px}`）。
  static const double wideMaxWidth = 860;

  /// 横线间距（原型 32px 一档）。
  static const double ruleHeight = 32;

  /// 限宽盒子的固定 Key，供版式测试断言 `maxWidth`。
  static const Key bodyKey = Key('shell-paper-body');

  /// 账页正文。
  final Widget child;

  /// 正文最大宽度；窄视口传 [double.infinity]（原型窄屏取消限宽）。
  final double maxWidth;

  /// 内边距；标准 `20/26/30`，窄视口 `16/16/22`（原型 `@media max-width:1279px`）。
  final EdgeInsetsGeometry padding;

  /// 吸顶头：放在滚动区**之外**、正文之上，纵向滚动时不动。
  ///
  /// `null`（默认）时整棵子树与引入本参数之前**逐字一致** —— 不加包裹层、
  /// 不改内边距，既有版式断言（`shell-paper-body` 的 `maxWidth`）不受影响。
  ///
  /// 非 `null` 时结构变成 `Column[ 头部行, Expanded(横线底 + 滚动区) ]`：
  /// 横线底只铺**滚动区**，头部行本身不画账页横线（它是页签，不是纸面）。
  /// 头部行与正文共用同一套左右内边距 + 同一 `maxWidth`，所以吸顶头与
  /// 正文列左右对齐，不会一宽一窄。
  final Widget? pinnedHeader;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets resolved = padding.resolve(Directionality.of(context));

    // 正文滚动区：`bodyKey` 必须留在滚动区内的 `ConstrainedBox` 上
    // （`shell_ledger_shell_test.dart` 用它读 `maxWidth` 断言 770 / 860）。
    Widget paperBody(double topInset) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          resolved.left,
          topInset,
          resolved.right,
          resolved.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            key: bodyKey,
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
    }

    final Widget? header = pinnedHeader;
    if (header == null) {
      return CustomPaint(
        painter: const LedgerRulePainter(),
        child: paperBody(resolved.top),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          // 上边距取纸张内边距的上沿：吸顶头和正文第一行离纸边的距离一致。
          // 下沿留 0 —— 头部自带的 1px 底边就是它和正文的分界。
          padding: EdgeInsets.fromLTRB(
            resolved.left,
            resolved.top,
            resolved.right,
            0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: header),
            ),
          ),
        ),
        Expanded(
          // 横线底包住滚动区而不是整张纸：否则吸顶头底下也会有一条横线，
          // 随正文滚动时看起来像「头部在动」。
          child: CustomPaint(
            painter: const LedgerRulePainter(),
            child: paperBody(0),
          ),
        ),
      ],
    );
  }
}
