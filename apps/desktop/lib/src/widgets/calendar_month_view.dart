import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 月历网格（spec §8.1）。
///
/// 每格三层信息：完成度底色 · 打卡热力点 · 心态迷你条 + 形状徽标。
class CalendarMonthView extends StatelessWidget {
  /// 创建月历。
  const CalendarMonthView({
    super.key,
    required this.month,
    required this.days,
    this.today,
    this.onPickDay,
  });

  /// 月份 `YYYY-MM`。
  final String month;

  /// 逐日摘要。
  final List<CalendarDaySummary> days;

  /// 今天（用于描边）。
  final String? today;

  /// 点某天的回调。
  final void Function(String date)? onPickDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byDate = <String, CalendarDaySummary>{
      for (final day in days) day.date: day,
    };
    final grid = buildMonthGrid(month, today: today ?? '');
    final pick = onPickDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(month, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label
                in const <String>['一', '二', '三', '四', '五', '六', '日'])
              Expanded(
                child: Center(
                  child: Text(label, style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
        GridView.count(
          key: const ValueKey('month-grid'),
          crossAxisCount: 7,
          mainAxisExtent: 52,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final cell in grid)
              _DayCell(
                key: ValueKey('day-${cell.date}'),
                cell: cell,
                summary: byDate[cell.date],
                onTap: pick == null ? null : () => pick(cell.date),
              ),
          ],
        ),
      ],
    );
  }
}

/// 日号（不补零）：`2026-11-07` → `7`。
String _dayNumber(String date) {
  final parsed = parseIsoDate(date);
  return parsed == null ? date : parsed.day.toString();
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.cell,
    required this.summary,
    required this.onTap,
  });

  final CalendarCell cell;
  final CalendarDaySummary? summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = summary;
    final ratio = (day == null || day.planTotal == 0)
        ? 0.0
        : day.planDone / day.planTotal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: cell.isToday ? AppTokens.ink : AppTokens.hairStrong,
            width: cell.isToday ? 2 : 1,
          ),
          color: day == null ? null : AppTokens.inkWash.withValues(alpha: ratio),
        ),
        child: Column(
          children: [
            Text(
              _dayNumber(cell.date),
              style: theme.textTheme.labelLarge?.copyWith(
                color: cell.inMonth ? AppTokens.ink : AppTokens.faint,
              ),
            ),
            if (day != null)
              Text(
                day.badge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTokens.meta,
                ),
              ),
          ],
        ),
      ),
    );
  }
}