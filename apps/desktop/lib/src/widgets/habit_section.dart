import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../providers_p1.dart';
import 'section_card.dart';

/// 习惯打卡区（P1-6 的习惯回填行）。
///
/// 打卡写入的是 `habit_checkin`，与今日计划列表里的「习惯回填行」是两回事：
/// 删除回填行只写 `plan_item` 墓碑，**不触碰打卡记录** —— 这条契约在
/// `core_data` 里已有单测（`softDelete` 只动 plan_item）。
///
/// 写入日期一律取 `selectedDateProvider`（与习惯清单、打卡流同源）：用户
/// 在日历里选中过去某天补录时，勾选必须落在**那一天**，不能落到今天
/// （M18-2）。未来日由宿主页（`TodayPage`）整体替换为占位卡、不渲染本区块，
/// 因此这里不再另做一层未来日判断。
class HabitSection extends ConsumerWidget {
  /// 创建习惯区块。
  const HabitSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(appLocalizationsProvider);
    final habits = ref.watch(habitsForTodayProvider);
    final checkins = ref.watch(habitCheckinsProvider);

    return SectionCard(
      icon: Icons.repeat,
      title: t.habitSectionTitle,
      subtitle: t.habitSectionSubtitle,
      child: habits.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => Text(
          '$error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Text(
              t.habitSectionEmpty,
              style: theme.textTheme.bodySmall,
            );
          }
          return checkins.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => Text(
              '$error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            data: (todayCheckins) {
              final byHabit = <String, HabitCheckinData>{
                for (final checkin in todayCheckins) checkin.habitId: checkin,
              };
              return Column(
                children: [
                  for (final habit in rows)
                    _HabitRow(
                      habit: habit,
                      checkin: byHabit[habit.id],
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.habit, required this.checkin});

  final HabitData habit;
  final HabitCheckinData? checkin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(appLocalizationsProvider);
    final repo = ref.read(repositoriesProvider).habit;
    // 与 `habitsForTodayProvider` / `habitCheckinsProvider` 同源：显示哪一天
    // 的打卡状态，写入就必须落在同一天（M18-2 的根因是这里读 `todayProvider`）。
    final date = ref.watch(selectedDateProvider);
    final done =
        checkin != null && checkin!.status == CheckinStatus.done.code;

    // targetCount 是可空的 double，整数时不显示小数位（3 次 / 2.5 小时）。
    final targetCount = habit.targetCount;
    final target = targetCount != null && targetCount > 1
        ? t.habitTarget(
            targetCount % 1 == 0
                ? targetCount.toStringAsFixed(0)
                : targetCount.toStringAsFixed(1),
            _displayUnit(habit.targetUnit, t),
          )
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        if (done) {
          final row = checkin;
          if (row != null) {
            await repo.deleteCheckin(row.id);
          }
        } else {
          await repo.upsertCheckin(habitId: habit.id, date: date);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: done,
              onChanged: (checked) async {
                if (checked ?? false) {
                  await repo.upsertCheckin(habitId: habit.id, date: date);
                } else {
                  final row = checkin;
                  if (row != null) {
                    await repo.deleteCheckin(row.id);
                  }
                }
              },
            ),
            Expanded(
              child: Text(
                habit.name,
                style: done
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
            ),
            if (target != null)
              Text(
                target,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 落库单位（`次`）在非中文态需要显示映射；其余单位（`天` / `周` / 自定义）
/// 原样展示。映射只作用于**显示**，落库值不变。
String _displayUnit(String stored, AppLocalizations t) =>
    stored == '次' ? t.commonUnitTimes : stored;