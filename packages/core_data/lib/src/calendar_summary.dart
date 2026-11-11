// packages/core_data/lib/src/calendar_summary.dart

/// 一天在月历格里的摘要（spec §8.1 的三层信息）。
final class CalendarDaySummary {
  /// 创建一天摘要。
  const CalendarDaySummary({
    required this.date,
    this.planDone = 0,
    this.planTotal = 0,
    this.habitDone = 0,
    this.habitTotal = 0,
    this.moodAverage,
    this.moodFailed = false,
    this.future = false,
  });

  /// 日历日。
  final String date;

  /// 当天完成数。
  final int planDone;

  /// 当天计划总数（不含 cancelled）。
  final int planTotal;

  /// 当天打卡完成数。
  final int habitDone;

  /// 当天应打卡总数。
  final int habitTotal;

  /// 当天心态八维均值（全 NULL 时为 null）。
  final double? moodAverage;

  /// 当天是否「今天没打分」。
  final bool moodFailed;

  /// 是否未来日期（未来只可预排）。
  final bool future;

  /// 形状徽标（不只靠颜色）。
  ///
  /// `✓` 全完成 · `●` 有未完成 · `○` 完全空白 · `▸` 未来带排期。
  String get badge {
    if (future && planTotal > 0) {
      return '▸';
    }
    if (planTotal == 0 &&
        habitTotal == 0 &&
        moodAverage == null &&
        !moodFailed) {
      return '○';
    }
    if (planTotal > 0 && planDone == planTotal) {
      return '✓';
    }
    return '●';
  }
}

/// 一个月历月的摘要。
final class CalendarMonthSummary {
  /// 创建月度摘要。
  const CalendarMonthSummary({required this.month, required this.days});

  /// 月份 `YYYY-MM`。
  final String month;

  /// 逐日摘要。
  final List<CalendarDaySummary> days;
}