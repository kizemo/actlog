import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart' show Quadrant;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../providers_p1.dart';
import 'priority_chips.dart';
import 'section_card.dart';

/// 站会三段视图（P1-2）：昨日亮点 / 今日优先 / 阻塞项。
///
/// 三段的取舍与排序全部由 `StandupBuilder` 决定，UI 只做渲染 ——
/// 这样「自动生成逻辑」能留在 `core_data` 里被单测覆盖。
class StandupSection extends ConsumerWidget {
  /// 创建站会区块。
  const StandupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final brief = ref.watch(standupBriefProvider);

    return SectionCard(
      icon: Icons.groups_outlined,
      title: l10n.todayStandupTitle,
      subtitle: l10n.todayStandupSubtitle,
      child: brief.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => Text(
          '$error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (data) {
          if (data.isEmpty) {
            return Text(
              l10n.todayStandupEmpty,
              style: theme.textTheme.bodySmall,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Block(
                l10n: l10n,
                label: l10n.todayStandupYesterday,
                icon: Icons.emoji_events_outlined,
                entries: data.yesterdayHighlights,
                emptyHint: l10n.todayStandupYesterdayEmpty,
              ),
              const SizedBox(height: 10),
              _Block(
                l10n: l10n,
                label: l10n.todayStandupToday,
                icon: Icons.playlist_add_check,
                entries: data.todayPriorities,
                emptyHint: l10n.todayStandupTodayEmpty,
              ),
              const SizedBox(height: 10),
              _Block(
                l10n: l10n,
                label: l10n.todayStandupBlockers,
                icon: Icons.report_problem_outlined,
                entries: data.blockers,
                emptyHint: l10n.todayStandupBlockersEmpty,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.l10n,
    required this.label,
    required this.icon,
    required this.entries,
    required this.emptyHint,
  });

  final AppLocalizations l10n;
  final String label;
  final IconData icon;
  final List<StandupEntry> entries;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              l10n.todayStandupSectionCount(label, entries.length),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 2),
            child: Text(
              emptyHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title, style: theme.textTheme.bodyMedium),
                        if (entry.note.isNotEmpty)
                          Text(
                            entry.note,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (entry.quadrant != null || entry.priorityAbc != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _MiniTag(
                        text: _tagOf(entry, l10n),
                        color: colorFromHex(
                          QuadrantStyle.of(entry.quadrant).colorHex,
                          fallback: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }

  /// 行尾小标签：象限走 l10n 短名（`domain-quadrant-q{1..4}-short-label`），
  /// ABC 分级暂沿用包层文案（R63-12 已裁决接受，W9 复核）。
  static String _tagOf(StandupEntry entry, AppLocalizations l10n) {
    final Quadrant? quadrant = entry.quadrant;
    if (quadrant != null) {
      return switch (quadrant) {
        Quadrant.q1 => l10n.quadrantQ1ShortLabel,
        Quadrant.q2 => l10n.quadrantQ2ShortLabel,
        Quadrant.q3 => l10n.quadrantQ3ShortLabel,
        Quadrant.q4 => l10n.quadrantQ4ShortLabel,
      };
    }
    final abc = entry.priorityAbc;
    return abc == null ? '' : AbcStyle.of(abc).label;
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontSize: 12),
      ),
    );
  }
}