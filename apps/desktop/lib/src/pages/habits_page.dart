import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/date_bar.dart';
import '../widgets/ledger_checkbox.dart';

/// 习惯页：`kShellNavItems` 里「习惯」项的真实落点（B2 / T11）。
///
/// 打卡写入日期一律取 [selectedDateProvider]（与 `habitsForTodayProvider` /
/// `habitCheckinsProvider` 同源）：在日历里选中过去某天补录时，勾选必须落在
/// **那一天**，不能落到今天。未来日只读 —— 勾选框 `onChanged` 为 `null`，
/// 库里不会出现未来日的打卡记录（spec §H-1）。
///
/// 本页是壳内**内容体**，不自建 `Scaffold`：滚动由 `LedgerPaper` 负责。
class HabitsPage extends ConsumerWidget {
  /// 创建习惯页。
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final l10n = ref.watch(appLocalizationsProvider);
    final String date = ref.watch(selectedDateProvider);
    final String today = ref.watch(todayProvider);
    final bool future = date.compareTo(today) > 0;
    final habits = ref.watch(habitsForTodayProvider);
    final checkins = ref.watch(habitCheckinsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const DateBar(),
        const SizedBox(height: AppTokens.gapCard),
        Text(
          l10n.habitPageTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            color: t.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$date · ${weekdayLabelOf(date, l10n)}',
          key: const ValueKey<String>('habits-page-date'),
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 11,
            height: 1.4,
            color: t.meta,
          ),
        ),
        if (future) ...<Widget>[
          const SizedBox(height: AppTokens.gapSec),
          Text(
            l10n.habitPageFutureHint,
            key: const ValueKey<String>('habits-page-future-hint'),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 12,
              height: 1.5,
              color: t.meta,
            ),
          ),
        ],
        const SizedBox(height: AppTokens.gapSec),
        Container(
          decoration: BoxDecoration(
            color: t.paper,
            border: Border.all(color: t.hairStrong),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: habits.when(
            loading: () => const LinearProgressIndicator(),
            error: (Object error, StackTrace stack) => Text(
              l10n.habitLoadFailed('$error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            data: (List<HabitData> rows) {
              if (rows.isEmpty) {
                return Text(
                  l10n.habitPageEmpty,
                  key: const ValueKey<String>('habits-page-empty'),
                  style: TextStyle(color: t.meta),
                );
              }
              return checkins.when(
                loading: () => const LinearProgressIndicator(),
                error: (Object error, StackTrace stack) => Text(
                  l10n.habitCheckinLoadFailed('$error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                data: (List<HabitCheckinData> dayCheckins) {
                  final byHabit = <String, HabitCheckinData>{
                    for (final checkin in dayCheckins) checkin.habitId: checkin,
                  };
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final habit in rows)
                        _HabitRow(
                          habit: habit,
                          checkin: byHabit[habit.id],
                          date: date,
                          future: future,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 一行习惯：勾选框 + 名称 + 目标量。
class _HabitRow extends ConsumerWidget {
  const _HabitRow({
    required this.habit,
    required this.checkin,
    required this.date,
    required this.future,
  });

  final HabitData habit;
  final HabitCheckinData? checkin;
  final String date;
  final bool future;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l10n = ref.watch(appLocalizationsProvider);
    final repo = ref.read(repositoriesProvider).habit;
    final bool done = checkin?.status == CheckinStatus.done.code;
    final double? targetCount = habit.targetCount;
    final String? target = targetCount != null && targetCount > 1
        ? l10n.habitTarget(
            targetCount % 1 == 0
                ? targetCount.toStringAsFixed(0)
                : targetCount.toStringAsFixed(1),
            _displayUnit(habit.targetUnit, l10n),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          LedgerCheckbox(
            key: ValueKey<String>('habit-check-${habit.id}'),
            value: done,
            semanticLabel: habit.name,
            onChanged: future
                ? null
                : (bool checked) async {
                    if (checked) {
                      await repo.upsertCheckin(
                        habitId: habit.id,
                        date: date,
                      );
                    } else {
                      final row = checkin;
                      if (row != null) {
                        await repo.deleteCheckin(row.id);
                      }
                    }
                  },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontFamilyFallback: AppFonts.bodyFallback,
                fontSize: 14,
                height: 1.5,
                color: t.ink,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (target != null)
            Text(
              target,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.bodyFallback,
                fontSize: 11,
                height: 1.4,
                color: t.meta,
              ),
            ),
        ],
      ),
    );
  }
}

/// `2026-11-05` ⇒ `周四`。解析失败返回空串（不抛异常，不打断渲染）。
///
/// [t] 省略时回落中文档（保持既有单参调用点不变）。
String weekdayLabelOf(String date, [AppLocalizations? t]) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return '';
  }
  return (t ?? AppLocalizations.zh).domainWeekdayFull[parsed.weekday - 1];
}

/// 落库单位 `次` 显示成当前语言；其它单位原样返回。
String _displayUnit(String stored, AppLocalizations t) =>
    stored == '次' ? t.commonUnitTimes : stored;