import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final brief = ref.watch(standupBriefProvider);

    return SectionCard(
      icon: Icons.groups_outlined,
      title: '站会',
      subtitle: '昨天做成了什么 · 今天最重要的事 · 卡在哪',
      child: brief.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => Text(
          '$error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (data) {
          if (data.isEmpty) {
            return Text(
              '三段都还没有内容 —— 先给今天加几条计划，或者去补昨天的记录。',
              style: theme.textTheme.bodySmall,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Block(
                label: '昨日亮点',
                icon: Icons.emoji_events_outlined,
                entries: data.yesterdayHighlights,
                emptyHint: '昨天没有已完成的条目',
              ),
              const SizedBox(height: 10),
              _Block(
                label: '今日优先',
                icon: Icons.playlist_add_check,
                entries: data.todayPriorities,
                emptyHint: '今天还没有待办条目',
              ),
              const SizedBox(height: 10),
              _Block(
                label: '阻塞项',
                icon: Icons.report_problem_outlined,
                entries: data.blockers,
                emptyHint: '没有检测到阻塞 — 保持住',
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
    required this.label,
    required this.icon,
    required this.entries,
    required this.emptyHint,
  });

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
              '$label（${entries.length}）',
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
                        text: _tagOf(entry),
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

  static String _tagOf(StandupEntry entry) {
    if (entry.quadrant != null) {
      return QuadrantStyle.of(entry.quadrant).shortLabel;
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