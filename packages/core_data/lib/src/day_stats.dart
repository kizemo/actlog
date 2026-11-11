/// 参与闭环统计的一条计划条目（只看状态与是否回填）。
final class PlanItemStat {
  /// 创建一条统计输入。
  const PlanItemStat({required this.status, required this.hasResultNote});

  /// 计划状态（`pending` / `done` / `deferred` / `cancelled`）。
  final String status;

  /// 是否已回填（`result_note` 去空白后非空）。
  final bool hasResultNote;
}

/// 一天的闭环统计（spec §G-1 的**唯一口径实现处**）。
///
/// 口径：
/// - 计划 `x/y`：`y` = 状态非 `cancelled` 的条目数；`x` = `done` 数；
/// - 回填 `m/x`：`m` = `done` 且已回填的条目数；
/// - 复盘 ✓ / 心态 ✓ 由调用方按 `day_log` 字段传入。
final class DayStats {
  /// 创建统计结果。
  const DayStats({
    required this.planTotal,
    required this.planDone,
    required this.backfilled,
    required this.reviewDone,
    required this.moodDone,
  });

  /// 计划分母（不含 cancelled）。
  final int planTotal;

  /// 计划分子（done）。
  final int planDone;

  /// 已回填数。
  final int backfilled;

  /// 复盘是否已处理。
  final bool reviewDone;

  /// 心态是否已处理。
  final bool moodDone;

  /// 未完成数。
  int get planPending => planTotal - planDone;

  /// 回填率；分母为 0 时返回 null（显示 `—`，**不算 100%**）。
  double? get backfillRate {
    if (planDone == 0) {
      return null;
    }
    return backfilled / planDone;
  }
}

/// 计算一天的闭环统计（纯函数，便于单测）。
DayStats computeDayStats({
  required Iterable<PlanItemStat> items,
  required bool hasReview,
  required bool hasMood,
}) {
  var total = 0;
  var done = 0;
  var backfilled = 0;
  for (final item in items) {
    if (item.status == 'cancelled') {
      continue;
    }
    total++;
    if (item.status == 'done') {
      done++;
      if (item.hasResultNote) {
        backfilled++;
      }
    }
  }
  return DayStats(
    planTotal: total,
    planDone: done,
    backfilled: backfilled,
    reviewDone: hasReview,
    moodDone: hasMood,
  );
}
