// apps/desktop/lib/src/widgets/day_timeline.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';

/// `TOKENS.md:238-239` 的 `<1280px` 断点边界。
const double tlNarrowBreakpoint = 1280;

/// 时间轴左栏宽度：窄视口 52px，宽视口 64px。
double tlWidthFor(double width) =>
    width < tlNarrowBreakpoint ? AppTokens.tlWidthNarrow : AppTokens.tlWidth;

/// 时间轴左栏与内容的间距：窄视口 10px，宽视口 12px。
double tlGapFor(double width) =>
    width < tlNarrowBreakpoint ? AppTokens.tlGapNarrow : AppTokens.tlGap;

/// 时段节点形状与赭石纪律（`TOKENS.md:300`、`§6:328`、`§7:306-307`）：
/// 两态都是**圆点**，**只有「有缺口」态用赭石**，非缺口态一律透明底 + 描边。
BoxDecoration tlNodeDecoration({
  required bool hasGap,
  required ThemeTokens tokens,
}) =>
    BoxDecoration(
      shape: BoxShape.circle,
      color: hasGap ? tokens.accent : Colors.transparent,
      border: Border.all(
        color: hasGap ? tokens.accent : tokens.hairStrong,
        width: 1.5,
      ),
    );

/// 节点下方文字通道（`TOKENS.md:254-255`，12px 允许换行）。
///
/// 本层是纯函数（没有 `BuildContext`），所以文案表由调用方传入 —— 与
/// [tlNodeDecoration] 收 `ThemeTokens` 值对象是同一条口径。`localizations`
/// 缺省取中文表：`test\day_timeline_test.dart` 直接断这一层返回的中文，
/// 且本文件的产品侧已无调用方（`today_page.dart:159` 注），缺省值不会漏到
/// 英文界面。
String tlNodeLabel({
  required bool hasGap,
  String? gapLabel,
  AppLocalizations? localizations,
}) {
  final AppLocalizations l10n = localizations ?? AppLocalizations.zh;
  return gapLabel ?? (hasGap ? l10n.timelineNodeGap : l10n.timelineNodeClosed);
}

/// 节点文字颜色：缺口态用赭石**文字**（`accentInk` 保证对比度），其余用次级色。
Color tlNodeTextColor({required bool hasGap, required ThemeTokens tokens}) =>
    hasGap ? tokens.accentInk : tokens.meta;

/// 一天时间轴上的一个时段（晨/午/晚）：左栏 = 节点 + 段名，右栏 = 内容。
class TimelineSection extends StatelessWidget {
  /// 创建时段。
  const TimelineSection({
    required this.label,
    required this.child,
    this.hasGap = false,
    this.gapLabel,
    this.localizations,
    super.key,
  });

  /// 段名（≥12px，允许换行，**不用** `SectionHeader`，见 R9 J3）。
  final String label;

  /// 该时段是否存在缺口。
  final bool hasGap;

  /// 缺口说明（可空）：有缺口时优先显示它，否则显示默认缺口文字。
  final String? gapLabel;

  /// 文案表（可空）。本控件**产品侧已无调用方**（`today_page.dart:159` 起
  /// 「复盘 + 心态不再走 `DayTimeline` / `TimelineSection`」），只剩测试在用；
  /// 缺省取中文表，避免测试因「没有 `L10nScope`」抛错。
  final AppLocalizations? localizations;

  /// 时段内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = localizations ?? AppLocalizations.zh;
    final t = context.tokens;
    final double width = MediaQuery.of(context).size.width;
    return Row(
      key: ValueKey<String>('tl-section-$label'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: tlWidthFor(width),
          child: Column(
            children: [
              Container(
                key: const ValueKey<String>('tl-node'),
                width: 10,
                height: 10,
                decoration: tlNodeDecoration(hasGap: hasGap, tokens: t),
              ),
              const SizedBox(height: 4),
              Text(
                tlNodeLabel(
                  hasGap: hasGap,
                  gapLabel: gapLabel,
                  localizations: l10n,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: tlNodeTextColor(hasGap: hasGap, tokens: t),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(width: tlGapFor(width)),
        Expanded(child: child),
      ],
    );
  }
}

/// 今日页三段骨架：三段**同时渲染、永不折叠**（骨架铁律）。
class DayTimeline extends StatelessWidget {
  /// 创建三段骨架，段间用 `AppTokens.gapSec`（R9 J10）。
  const DayTimeline({required this.sections, super.key});

  /// 时段列表。
  final List<TimelineSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.gapSec),
          sections[i],
        ],
      ],
    );
  }
}