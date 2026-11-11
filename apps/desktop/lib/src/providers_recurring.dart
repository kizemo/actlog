import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// 选中日的循环任务实例（规则行 + 物化行，按开始时刻升序）。
///
/// 走 drift 流：`recurring_occurrence` 或 `plan_item` 一有写入就会自动重发，
/// 因此右轨面板不需要「手动刷新」按钮。
final recurringOccurrencesProvider =
    StreamProvider<List<RecurringOccurrenceView>>((ref) {
  final String date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).recurring.watchOccurrencesByDate(date);
});

/// 启用中的循环规则（按开始时刻升序）。
final activeRecurringTasksProvider =
    StreamProvider<List<RecurringTaskData>>((ref) {
  return ref.watch(repositoriesProvider).recurring.watchActive();
});

/// 物化触发器：保证选中日里该跑的循环任务已经落成 `plan_item`。
///
/// **幂等**（应用层先查后写 + 库层 `UNIQUE(task_id, date)` 兜底），
/// 所以每次进入某一天都重算一次是安全的；返回值是「本次新建的条数」，
/// 正常重入时为 0。
///
/// 不在这里 `invalidate` 自己：物化会写 `plan_item`，而本 provider 只依赖
/// [selectedDateProvider] 与仓储，不会因为自己的写入而重跑（不会自激）。
final recurringMaterializeProvider = FutureProvider<int>((ref) async {
  final String date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).recurring.materializeDate(date);
});