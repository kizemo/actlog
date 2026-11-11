// =============================================================================
// core_domain · 循环任务的纯领域工具
// =============================================================================
// 本文件只做两件与 IO 无关的事，因此可以放在领域层并被 UI / 仓储共同复用：
//   1. `weekday_mask` 的位序换算（**bit0 = 周一** … bit6 = 周日，取值 0..127）；
//   2. 「一天中的第几分钟」（0..1439）↔ `HH:mm` 文本的互转。
//
// 位序为什么以**周一**为 bit0：
//   Dart 的 `DateTime.weekday` 是 1=周一 … 7=周日，`bit = 1 << (weekday - 1)`
//   是最短的一条映射；若以周日为 bit0，映射里就要多一次取模，容易写错。
//   换算只在 [WeekdayMask.bitOf] 一处发生，其余代码一律走这个函数。
//
// 时间为什么存「分钟数」而不是 `HH:mm` 文本：
//   排期比较、排序、加时长都要做算术，文本每次都要解析；而且 `plan_item` 的
//   `planned_start` / `planned_end` 本来就是毫秒时间戳，分钟数离它更近。
//   文本形式只在**输入与展示**两个边界出现，边界上各转一次即可。
// =============================================================================

/// 星期位掩码工具。
///
/// 掩码是 7 位整数：bit0 = 周一、bit1 = 周二、…、bit6 = 周日。
/// 合法范围 0..127；0 表示「一天都不排」，仓储层会拒绝这种任务（见
/// `RecurringRepository.create` 的校验）。
abstract final class WeekdayMask {
  /// 周一（bit0）。
  static const int monday = 1 << 0;

  /// 周二（bit1）。
  static const int tuesday = 1 << 1;

  /// 周三（bit2）。
  static const int wednesday = 1 << 2;

  /// 周四（bit3）。
  static const int thursday = 1 << 3;

  /// 周五（bit4）。
  static const int friday = 1 << 4;

  /// 周六（bit5）。
  static const int saturday = 1 << 5;

  /// 周日（bit6）。
  static const int sunday = 1 << 6;

  /// 一天都不排（空掩码）。
  static const int none = 0;

  /// 工作日：周一至周五（`0x1F` = 31）。
  static const int workdays = monday | tuesday | wednesday | thursday | friday;

  /// 周末：周六 + 周日（`0x60` = 96）。
  static const int weekend = saturday | sunday;

  /// 每天（`0x7F` = 127）。
  static const int all =
      monday |
      tuesday |
      wednesday |
      thursday |
      friday |
      saturday |
      sunday;

  /// 掩码上界（7 位全开）。
  static const int maxValue = all;

  /// 掩码是否落在合法范围 0..127。
  static bool isValid(int mask) => mask >= none && mask <= maxValue;

  /// ISO 星期（1 = 周一 … 7 = 周日）对应的单个比特。
  static int bitOf(int isoWeekday) {
    if (isoWeekday < 1 || isoWeekday > 7) {
      throw ArgumentError.value(isoWeekday, 'isoWeekday', '必须在 1..7');
    }
    return 1 << (isoWeekday - 1);
  }

  /// 掩码是否包含某个 ISO 星期（1 = 周一 … 7 = 周日）。
  static bool includes(int mask, int isoWeekday) =>
      (mask & bitOf(isoWeekday)) != 0;

  /// 掩码里选中的 ISO 星期列表（升序，1..7）。
  static List<int> weekdaysOf(int mask) => <int>[
    for (var weekday = 1; weekday <= 7; weekday++)
      if (includes(mask, weekday)) weekday,
  ];

  /// 某个日期落在星期几上的单比特（用来判断「今天是否该排」）。
  static int bitOfDate(DateTime date) => bitOf(date.weekday);

  /// 掩码的中文摘要：`每天` / `工作日` / `周末` / `周一、周三` / `未选`。
  static String label(int mask) {
    if (mask == none) {
      return '未选';
    }
    if (mask == all) {
      return '每天';
    }
    if (mask == workdays) {
      return '工作日';
    }
    if (mask == weekend) {
      return '周末';
    }
    return weekdaysOf(mask).map(weekdayLabel).join('、');
  }
}

/// ISO 星期（1..7）的中文名。
String weekdayLabel(int isoWeekday) {
  const List<String> names = <String>[
    '',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];
  if (isoWeekday < 1 || isoWeekday > 7) {
    throw ArgumentError.value(isoWeekday, 'isoWeekday', '必须在 1..7');
  }
  return names[isoWeekday];
}

/// 一天的分钟数（`00:00` 到 `23:59` 共 1440 个取值点）。
const int minutesPerDay = 1440;

/// 把「一天中的第几分钟」格式化成 `HH:mm`。
///
/// 越界直接抛 [ArgumentError]：这是**程序内部**的取值，越界属于 bug，
/// 不该像解析用户输入那样静默兜底。
String formatMinuteOfDay(int minuteOfDay) {
  if (minuteOfDay < 0 || minuteOfDay >= minutesPerDay) {
    throw ArgumentError.value(
      minuteOfDay,
      'minuteOfDay',
      '必须在 0..1439',
    );
  }
  final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// 把用户输入的 `HH:mm` / `H:mm` 解析成「一天中的第几分钟」。
///
/// 非法输入返回 null（不抛异常）—— 与 `parseIsoDate` / 枚举 `fromCode` 的
/// 约定一致：解析用户输入不该把界面搞崩，错误由调用方就地显示。
int? parseMinuteOfDay(String raw) {
  final parts = raw.trim().split(':');
  if (parts.length != 2) {
    return null;
  }
  if (parts[0].isEmpty || parts[1].length != 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}