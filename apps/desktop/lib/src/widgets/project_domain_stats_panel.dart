// =============================================================================
// 领域分布面板（Task 59）
// =============================================================================
// 分桶口径不在这里：统计由 `data/project_domain_stats.dart` 的纯函数算好
// （空串恒排最后、数量降序、同数按 key 升序），本文件只负责画。
//
// 为什么不内置译名表：领域 key 的显示文案属于 l10n，面板既拿不到也不该猜。
// `labelOf` 由页面注入（未知 key 由页面原样回传 key；空串 = 未分类也走
// `labelOf('')`）—— 面板里因此没有一处领域中文名。
//
// 比例条照抄 `calendar_month_view.dart:114-129` 的完成度洗底 house style：
// 轨道 `sunken` 底，填充 `Color.alphaBlend(inkWash.withValues(alpha: ratio),
// sunken)`；`ratio <= 0` 不画填充。条长 = 轨道宽 × ratio（严格正比）。
// 颜色一律取 `context.tokens`，本文件没有一处静态色值。
// =============================================================================

import 'package:flutter/material.dart';

import '../data/project_domain_stats.dart';
import '../theme/app_tokens.dart';

/// 项目领域分布面板：一行一个领域桶（标签 + 项目数 + 比例条）。
///
/// 面板是**纯展示**：不读库、不持有状态、不弹窗、不做动画。数据与文案都由
/// 调用方给（页面拿 `projectDomainStats()` 的结果 + 当前语言的 getter）。
class ProjectDomainStatsPanel extends StatelessWidget {
  /// 创建面板。
  const ProjectDomainStatsPanel({
    super.key,
    required this.title,
    required this.stats,
    required this.labelOf,
    required this.countText,
  });

  /// 面板标题（如「领域分布」）。
  final String title;

  /// 各领域的统计行（顺序即渲染顺序，由统计函数定）。
  final List<ProjectDomainStat> stats;

  /// 领域 key ⇒ 本地化标签。
  ///
  /// 未知 key 由调用方原样回传 key；空串（未分类）也走这里。
  final String Function(String domainKey) labelOf;

  /// 计数文案模板，带 `{n}` 占位符（如「{n} 个项目」）。
  final String countText;

  /// 比例条轨道的定位 key（满宽参考；测试用它量条长）。
  static Key barTrackKey(String domainKey) =>
      ValueKey<String>('project-domain-bar-track-$domainKey');

  /// 比例条填充的定位 key（宽度 = 轨道宽 × ratio）。
  static Key barFillKey(String domainKey) =>
      ValueKey<String>('project-domain-bar-fill-$domainKey');

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.hairSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: tokens.meta,
            ),
          ),
          const SizedBox(height: 6),
          if (stats.isEmpty)
            // 空态不另造文案：`labelOf('')` 就是「未分类」，语义上等价于
            // 「一个桶都没有」。页面侧另有一道 `isNotEmpty` 闸门，这里只兜底。
            Text(
              labelOf(''),
              style: TextStyle(fontSize: 11.5, color: tokens.faint),
            )
          else
            for (final ProjectDomainStat stat in stats)
              _DomainStatRow(
                domainKey: stat.domain,
                label: labelOf(stat.domain),
                countLabel: countText.replaceAll('{n}', '${stat.count}'),
                ratio: stat.ratio,
              ),
        ],
      ),
    );
  }
}

/// 一个领域桶：标签 + 项目数一行，比例条一行。
class _DomainStatRow extends StatelessWidget {
  const _DomainStatRow({
    required this.domainKey,
    required this.label,
    required this.countLabel,
    required this.ratio,
  });

  /// 领域 key（同时用作比例条的定位 key 后缀）。
  final String domainKey;

  /// 已本地化的标签（未知 key 就是原样 key）。
  final String label;

  /// 已插值的计数文案。
  final String countLabel;

  /// 该桶占比（0..1）。
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.ink2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countLabel,
                style: TextStyle(fontSize: 11.5, color: tokens.meta),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RatioBar(domainKey: domainKey, ratio: ratio),
        ],
      ),
    );
  }
}

/// 比例条：`sunken` 轨道 + 按 ratio 宽度与浓度的填充。
///
/// 用 `LayoutBuilder` 取轨道实宽再乘 ratio（不用 `FractionallySizedBox`）：
/// 条长与 ratio 是**同一条算式**，测试量 `getSize()` 就能钉住「严格正比」。
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.domainKey, required this.ratio});

  /// 领域 key（定位 key 用）。
  final String domainKey;

  /// 该桶占比（0..1）。
  final double ratio;

  /// 条高（细条，不抢标签行）。
  static const double _height = 5;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    // 统计函数的 ratio 天然落在 (0, 1]；这里再夹一次是防御（面板是公开组件，
    // 调用方可能传进脏值）。
    final double clamped = ratio.isNaN ? 0 : ratio.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double trackWidth = constraints.maxWidth;
        final BorderRadius radius = BorderRadius.circular(AppTokens.radius);
        return Container(
          key: ProjectDomainStatsPanel.barTrackKey(domainKey),
          height: _height,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: tokens.sunken, borderRadius: radius),
          child: clamped <= 0
              // `ratio <= 0` 只留轨道，不画填充（house style 同款闸门）。
              ? const SizedBox.shrink()
              : Container(
                  key: ProjectDomainStatsPanel.barFillKey(domainKey),
                  width: trackWidth * clamped,
                  height: _height,
                  decoration: BoxDecoration(
                    // 填充浓度也按 ratio 走 —— 与日历格完成度洗底同一条口径。
                    color: Color.alphaBlend(
                      tokens.inkWash.withValues(alpha: clamped),
                      tokens.sunken,
                    ),
                    borderRadius: radius,
                  ),
                ),
        );
      },
    );
  }
}