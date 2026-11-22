import 'package:flutter/material.dart';

/// 账页（B 版「墨径 · 账页流」正文卷）。
///
/// 原型 `design-demos/v2-ledger.html` 的 `.ledger` 曾用
/// `repeating-linear-gradient(to bottom, transparent 0 31px, rgba(122,110,88,.055) 31px 32px)`
/// 在纸面铺 32px 一档的 1px 规则横线，本组件早期用 `LedgerRulePainter` 等价复刻。
/// **Task 54 诉求③按用户要求把这层背景横线移除了**：真机取帧判定 `J5=LEDGER_RULES_ONLY`
/// 证明整屏只剩这一种线、且 21 条等距线（间距 56 设备 px = 32 逻辑 px × 1.75）全部来自它，
/// 证据见 `reports/task54-accept/j5-base.log`。现存纸面只有底色，不再画横线。
///
/// 结构等价原型 `div.ledger > div.ledger-pad`：
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
  /// 非 `null` 时结构变成 `Column[ 头部行, Expanded(滚动区) ]`：
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
      return paperBody(resolved.top);
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
        Expanded(child: paperBody(0)),
      ],
    );
  }
}