import 'dart:math';

import 'package:flutter/material.dart';

import '../data/quotes.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import 'marquee_line.dart';

/// 日期条下方的一句中英对照警句（随机 + 刷新换句）。
///
/// 纯 [StatefulWidget]：**不读任何 provider**，也不持久化。理由：警句的
/// 「随机一次」只属于这一屏 —— 若挂在 provider 上，页面里任何无关数据变化
/// 都会重掷一句，用户会觉得句子在自己眼前乱跳。
///
/// 版面纪律（Task 54 之后）：**无卡片底、无分隔线**。只有文字 + 右侧刷新钮，
/// 颜色一律走 `context.tokens`，不写静态色值。
///
/// 语言：中文态两行（中文在上、英文在下），英文态只有英文行。两行**各自**
/// 判溢出（[MarqueeLine] 内部处理），长的那行自己滚，不带着另一行一起动。
class QuoteBanner extends StatefulWidget {
  /// 创建警句横幅。
  ///
  /// [initialIndex] 只用于定初值（测试与截图复现）；为空时随机抽一条。
  const QuoteBanner({super.key, this.initialIndex});

  /// 首帧展示的条目下标；为空则从全表随机取。
  final int? initialIndex;

  /// 刷新钮的 tooltip。
  ///
  /// 本 SDK（Flutter 3.47.9）的 `MaterialLocalizations` **没有**
  /// `refreshButtonTooltip` 这个成员（只有 back / close / delete / more 等），
  /// 而本轮禁止新增 l10n key，故按约定回落固定字面量 `Refresh`。
  static const String refreshTooltip = 'Refresh';

  /// 刷新钮尺寸（28×28）。
  static const double refreshButtonSize = 28;

  /// 刷新钮图标尺寸。
  static const double refreshIconSize = 18;

  @override
  State<QuoteBanner> createState() => _QuoteBannerState();
}

class _QuoteBannerState extends State<QuoteBanner> {
  /// 当前条目下标；始终落在 `[0, kQuotes.length)` 内（空表时为 0）。
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final int n = kQuotes.length;
    final int initial = widget.initialIndex ?? _randomIndex();
    _index = n == 0 ? 0 : initial % n;
  }

  @override
  void didUpdateWidget(covariant QuoteBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int? next = widget.initialIndex;
    final int n = kQuotes.length;
    if (next != null && next != oldWidget.initialIndex && n > 0) {
      _index = next % n;
    }
  }

  /// 随机取一条。空表时返回 0（调用方另有空表短路，不许崩）。
  int _randomIndex() {
    final int n = kQuotes.length;
    if (n == 0) {
      return 0;
    }
    return Random().nextInt(n);
  }

  /// 换到**另一条**。
  ///
  /// `(_index + 1 + nextInt(n - 1)) % n` 是「在其余 n-1 条里取偏移」的写法，
  /// 数学上保证结果一定不是当前这条；`n == 1` 时无处可换，直接不动。
  void _showAnother() {
    final int n = kQuotes.length;
    if (n <= 1) {
      return;
    }
    final Random rnd = Random();
    setState(() => _index = (_index + 1 + rnd.nextInt(n - 1)) % n);
  }

  @override
  Widget build(BuildContext context) {
    // 空表防御：不渲染空横幅，也不抛 RangeError。
    if (kQuotes.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isZh = l10n.language == AppLanguage.zh;
    final q = kQuotes[_index % kQuotes.length];

    // 字号按设计口径写常量（token 表里没有字号档位）；颜色必须走 tokens。
    final TextStyle? base = Theme.of(context).textTheme.bodySmall;
    final TextStyle zhStyle = (base ?? const TextStyle()).copyWith(
      fontSize: 13.5,
      height: 1.2,
      color: t.ink,
    );
    final TextStyle enStyle = (base ?? const TextStyle()).copyWith(
      fontSize: 12,
      height: 1.2,
      color: t.meta,
    );

    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 中文环境：中文行在上、英文行在下；英文环境：只有英文行。
              if (isZh) ...<Widget>[
                MarqueeLine(
                  key: const Key('quote.zh'),
                  text: q.zh,
                  style: zhStyle,
                ),
                const SizedBox(height: 2),
              ],
              MarqueeLine(
                key: const Key('quote.en'),
                text: q.en,
                style: enStyle,
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(child: _buildRefreshButton(t)),
        ),
      ],
    );
  }

  /// 右侧 28×28 刷新钮。
  ///
  /// `Material(type: transparency)` 只为给 [IconButton] 一个就地 Material
  /// 祖先（它断言必须有 Material），既不加卡片底也不加线。
  Widget _buildRefreshButton(ThemeTokens t) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: QuoteBanner.refreshButtonSize,
        height: QuoteBanner.refreshButtonSize,
        child: IconButton(
          key: const Key('quote.refresh'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: QuoteBanner.refreshButtonSize,
            height: QuoteBanner.refreshButtonSize,
          ),
          iconSize: QuoteBanner.refreshIconSize,
          color: t.meta,
          tooltip: QuoteBanner.refreshTooltip,
          onPressed: _showAnother,
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}