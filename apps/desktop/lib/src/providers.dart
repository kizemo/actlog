import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'widgets/timeline/timeline_store.dart';

/// 数据库实例；由 `main()` 用真实文件 override。
///
/// 不给默认实现，是因为「哪一天的数据」必须由启动时解析出的库路径决定，
/// 静默回落到临时库会让用户以为数据丢了。
final databaseProvider = Provider<ActLogDatabase>(
  (ref) => throw UnimplementedError('databaseProvider 必须在 main() 中被覆盖'),
);

/// P1 全部仓储的入口（dayLog / planItem / habit / settings）。
final repositoriesProvider = Provider<ActLogRepositories>(
  (ref) => ActLogRepositories(ref.watch(databaseProvider)),
);

/// 今天（本地时区的日历日，`yyyy-MM-dd`）。
///
/// 单独提出来是为了让测试能 override 成固定日期。
final todayProvider = Provider<String>((ref) => today());

/// 选中日期（本地时区的日历日，`yyyy-MM-dd`）。
///
/// 初值读 [todayProvider]，因此测试里 override `todayProvider` 依然生效；
/// 界面上的任何日期写入都只读这一个 provider（spec §13.3）。
final selectedDateProvider = StateProvider<String>(
  (ref) => ref.watch(todayProvider),
);

/// 当日日志；读取前先 `ensureByDate` 补建（幂等，不写库也不写 oplog）。
final dayLogProvider = StreamProvider<DayLogData?>((ref) async* {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(repositoriesProvider).dayLog;
  await repo.ensureByDate(date);
  yield* repo.watchByDate(date);
});

/// 当日计划条目（含习惯回填行），已按「收口沉底 + 优先级权重 + 创建时间」排好序。
final planItemsProvider = StreamProvider<List<PlanItemData>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).planItem.watchByDate(date);
});

/// 已排期的待办（`todo.id` → 排期事实）。
///
/// 「已填时间」是**派生**事实（§0）：存在未删除的 `plan_item` 且
/// `source_todo_id = todo.id`。待办池用它显示只读徽标 `已排期 09:15`。
final slottedTodosProvider = FutureProvider<Map<String, SlottedTodo>>((ref) {
  return TimelineStore(ref.watch(repositoriesProvider)).slottedTodosAll();
});

/// 优先级展示模式（四象限 / ABC）。
final priorityDisplayModeProvider = FutureProvider<PriorityDisplayMode>(
  (ref) => ref.watch(repositoriesProvider).settings.priorityDisplayMode(),
);

/// 当日闭环统计（闭环环口径唯一实现处）。
final dayStatsProvider = Provider<DayStats>((ref) {
  final items =
      ref.watch(planItemsProvider).whenOrNull(data: (rows) => rows) ??
      const <PlanItemData>[];
  final log = ref.watch(dayLogProvider).whenOrNull(data: (row) => row);

  final hasReview =
      log != null &&
      (log.good.trim().isNotEmpty ||
          log.improve.trim().isNotEmpty ||
          log.learning.trim().isNotEmpty);
  final hasMood =
      log != null &&
      (log.moodFailed == 1 ||
          log.mood1 != null ||
          log.mood2 != null ||
          log.mood3 != null ||
          log.mood4 != null ||
          log.mood5 != null ||
          log.mood6 != null ||
          log.mood7 != null ||
          log.mood8 != null);

  return computeDayStats(
    items: items.map(
      (item) => PlanItemStat(
        status: item.status,
        hasResultNote: item.resultNote.trim().isNotEmpty,
      ),
    ),
    hasReview: hasReview,
    hasMood: hasMood,
  );
});

/// 某个月的日历摘要（月历用；一次查区间，禁止按格子 N+1）。
final calendarMonthProvider =
    FutureProvider.family<CalendarMonthSummary, String>((ref, month) async {
  final repos = ref.watch(repositoriesProvider);
  final todayIso = ref.watch(todayProvider);
  final parts = month.split('-');
  final first = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  final last = DateTime(first.year, first.month + 1, 0);
  final start = isoDate(first);
  final end = isoDate(last);

  final items = await repos.planItem.listRange(start, end);
  final checkins = await repos.habit.listCheckinsRange(start, end);
  final logs = await repos.dayLog.listRange(start, end);
  final habits = await repos.habit.listActive();

  final byDate = <String, CalendarDaySummary>{};
  for (var day = first;
      !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1)) {
    final date = isoDate(day);
    byDate[date] = CalendarDaySummary(
      date: date,
      future: date.compareTo(todayIso) > 0,
    );
  }

  for (final item in items) {
    final summary = byDate[item.date];
    if (summary == null || item.status == PlanStatus.cancelled.code) {
      continue;
    }
    byDate[item.date] = CalendarDaySummary(
      date: item.date,
      planDone:
          summary.planDone + (item.status == PlanStatus.done.code ? 1 : 0),
      planTotal: summary.planTotal + 1,
      habitDone: summary.habitDone,
      habitTotal: summary.habitTotal,
      moodAverage: summary.moodAverage,
      moodFailed: summary.moodFailed,
      future: summary.future,
    );
  }

  for (final checkin in checkins) {
    final summary = byDate[checkin.date];
    if (summary == null) {
      continue;
    }
    byDate[checkin.date] = CalendarDaySummary(
      date: checkin.date,
      planDone: summary.planDone,
      planTotal: summary.planTotal,
      habitDone: summary.habitDone +
          (checkin.status == CheckinStatus.done.code ? 1 : 0),
      habitTotal: summary.habitTotal,
      moodAverage: summary.moodAverage,
      moodFailed: summary.moodFailed,
      future: summary.future,
    );
  }

  for (final log in logs) {
    final summary = byDate[log.date];
    if (summary == null) {
      continue;
    }
    final scores = <int?>[
      log.mood1,
      log.mood2,
      log.mood3,
      log.mood4,
      log.mood5,
      log.mood6,
      log.mood7,
      log.mood8,
    ].whereType<int>().toList(growable: false);
    byDate[log.date] = CalendarDaySummary(
      date: log.date,
      planDone: summary.planDone,
      planTotal: summary.planTotal,
      habitDone: summary.habitDone,
      habitTotal: summary.habitTotal,
      moodAverage: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length,
      moodFailed: log.moodFailed == 1,
      future: summary.future,
    );
  }

  for (final habit in habits) {
    for (var day = first;
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final date = isoDate(day);
      final summary = byDate[date];
      if (summary == null ||
          !HabitRepository.isScheduledFor(habit, date) ||
          habit.startDate.compareTo(date) > 0) {
        continue;
      }
      byDate[date] = CalendarDaySummary(
        date: date,
        planDone: summary.planDone,
        planTotal: summary.planTotal,
        habitDone: summary.habitDone,
        habitTotal: summary.habitTotal + 1,
        moodAverage: summary.moodAverage,
        moodFailed: summary.moodFailed,
        future: summary.future,
      );
    }
  }

  return CalendarMonthSummary(
    month: month,
    days: byDate.values.toList(growable: false),
  );
});