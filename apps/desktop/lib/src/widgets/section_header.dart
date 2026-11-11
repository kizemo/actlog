import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 段头（标题 + 完成徽章 + 缺项高亮）。
///
/// 视觉口径（`v2-ledger.html:187-189`）：段头下沿一条 1px `--hair` 线，
/// 前端**不带 Material 图标**；标题走 display 字族。
/// 缺项时整行加 2px 赭石描边（`--accent`）并给出提示 —— 这是 B 版允许的
/// 赭石位置之一（缺口语义）。
class SectionHeader extends StatelessWidget {
  /// 创建段头。
  const SectionHeader({
    super.key,
    required this.title,
    this.done,
    this.total,
    this.hasGap = false,
    this.gapHint,
    this.trailing,
  });

  /// 段标题。
  final String title;

  /// 已完成数（为空则不显示徽章）。
  final int? done;

  /// 总数。
  final int? total;

  /// 是否存在缺项。
  final bool hasGap;

  /// 缺项提示文案。
  final String? gapHint;

  /// 标题行右侧动作。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadge = done != null && total != null;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: AppTokens.ink),
        ),
        if (hasBadge) ...[
          const SizedBox(width: 10),
          Text(
            '$done/$total',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTokens.meta,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
        if (hasGap && gapHint != null) ...[
          const SizedBox(width: 8),
          Text(
            gapHint!,
            style: theme.textTheme.labelLarge?.copyWith(color: AppTokens.accentInk),
          ),
        ],
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTokens.hair, width: 1)),
        ),
        child: hasGap
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: AppTokens.accent, width: 2),
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}