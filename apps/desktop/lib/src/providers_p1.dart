import 'package:core_data/core_data.dart';
// `core_db` 与 `core_domain` 都导出叫 `Todo` 的名字（drift 表 vs 实体），
// 本文件只用实体，故把表的那个藏掉。
import 'package:core_db/core_db.dart' hide Todo;
import 'package:core_domain/core_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// 昨天（本地时区的日历日）。
final yesterdayProvider = Provider<String>(
  (ref) => previousIsoDate(ref.watch(todayProvider)),
);

/// 昨天的计划条目快照 —— 站会「昨日亮点」「阻塞项」的数据源。
final yesterdayPlanItemsProvider = FutureProvider<List<PlanItemData>>((ref) {
  final date = ref.watch(yesterdayProvider);
  return ref.watch(repositoriesProvider).planItem.listByDate(date);
});

/// 站会三段视图（P1-2）。
///
/// 生成逻辑全在 `core_data` 的 `StandupBuilder` 里（已单测覆盖）；
/// 这里只负责把「今天/昨天的行 + 昨天日志的『做得好』」喂进去。
final standupBriefProvider = FutureProvider<StandupBrief>((ref) async {
  final todayDate = ref.watch(todayProvider);
  final yesterday = ref.watch(yesterdayProvider);
  final repos = ref.watch(repositoriesProvider);

  final todayItems = await ref.watch(planItemsProvider.future);
  final yesterdayItems = await ref.watch(yesterdayPlanItemsProvider.future);
  final yesterdayLog = await repos.dayLog.findByDate(yesterday);

  return StandupBuilder.build(
    input: StandupInput(
      date: todayDate,
      todayItems: todayItems.map(toStandupPlanRow).toList(),
      yesterdayItems: yesterdayItems.map(toStandupPlanRow).toList(),
      yesterdayGoodText: yesterdayLog?.good ?? '',
    ),
  );
});

/// `PlanItemData` → `StandupPlanRow`。
///
/// `carriedOverDays` 恒为 0：`plan_item.moveToDate` 只改 `date`、不保留原始计划日，
/// 所以「顺延 N 天」在 P1 无从计算。等 P3 的排期模型落地后再补真实值。
StandupPlanRow toStandupPlanRow(PlanItemData item) => StandupPlanRow(
  id: item.id,
  title: item.title,
  date: item.date,
  status: PlanStatus.fromCode(item.status) ?? PlanStatus.pending,
  quadrant: Quadrant.fromCode(item.quadrant ?? ''),
  priorityAbc: PriorityAbc.fromCode(item.priorityAbc ?? ''),
  resultNote: item.resultNote,
  carriedOverDays: 0,
);

/// 所选日排程内的习惯（P1-6 的习惯回填行）。
///
/// 数据源是 `selectedDateProvider` 而不是 `todayProvider`：卡带与回填行都跟随
/// 用户当前选中的日期（spec §13.3），「今天」只是所选日的初值。
final habitsForTodayProvider = FutureProvider<List<HabitData>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).habit.listScheduledFor(date);
});

/// 所选日的习惯打卡记录。
///
/// 与 [habitsForTodayProvider] 同口径：切日即切数据，补录过去某天时
/// 勾选状态必须是那一天的，而不是今天的。
final habitCheckinsProvider = StreamProvider<List<HabitCheckinData>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).habit.watchCheckinsByDate(date);
});

/// 待办池：`status='open'` 且未删除的待办，按创建时间升序。
///
/// 池子与日期**无关** —— 它是全局收件箱，切日不该让列表重建。
/// 只有「捞到哪一天」跟随选中日，见 [todoPullTargetDateProvider]。
final todoPoolProvider = FutureProvider<List<Todo>>(
  (ref) => ref.watch(repositoriesProvider).todo.listOpen(),
);

/// 待办池「捞入」的目标日期（= 当前选中日）。
///
/// 单独拆一个 provider，是为了让 `todoPoolProvider` 不因切日而失效：
/// 切日只改落点，不改池子内容。
final todoPullTargetDateProvider = Provider<String>(
  (ref) => ref.watch(selectedDateProvider),
);

/// 当日心态（P1-8）。
///
/// 直接从 `DayLogData` 的 `mood_1..mood_8` 列还原；未打分的维度不出现在 map 里，
/// 与数据库 NULL 语义保持一致（`MoodRules.toColumns` 也不写空维度）。
final moodProvider = Provider.family<MoodSummary, DayLogData>((ref, log) {
  final columns = <String, int?>{
    for (final dimension in MoodDimension.all)
      dimension.column: _moodColumnValue(log, dimension),
  };
  return MoodSummary(
    scores: Map<MoodDimension, int>.unmodifiable(
      MoodRules.fromColumns(columns),
    ),
    failed: log.moodFailed != 0,
    note: log.moodNote,
  );
});

int? _moodColumnValue(DayLogData log, MoodDimension dimension) {
  return switch (dimension) {
    MoodDimension.diligent => log.mood1,
    MoodDimension.fast => log.mood2,
    MoodDimension.keepPromise => log.mood3,
    MoodDimension.finishTask => log.mood4,
    MoodDimension.optimistic => log.mood5,
    MoodDimension.confident => log.mood6,
    MoodDimension.loveAndDedication => log.mood7,
    MoodDimension.noExcuses => log.mood8,
  };
}