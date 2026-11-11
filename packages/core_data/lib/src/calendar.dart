// packages/core_data/lib/src/calendar.dart
import 'support.dart';

/// 月历网格的一格。
final class CalendarCell {
  /// 创建一个格子。
  const CalendarCell({
    required this.date,
    required this.inMonth,
    required this.isWeekend,
    required this.isToday,
  });

  /// 该格的日历日 `yyyy-MM-dd`。
  final String date;

  /// 是否属于当前显示的月份。
  final bool inMonth;

  /// 是否周六或周日。
  final bool isWeekend;

  /// 是否今天。
  final bool isToday;
}

const List<String> _weekdayNames = <String>[
  '周一',
  '周二',
  '周三',
  '周四',
  '周五',
  '周六',
  '周日',
];

/// 生成 [yearMonth]（`YYYY-MM`）的 6×7 月历网格。
///
/// [weekStart] 为每周首日的 `DateTime.weekday`：1 = 周一，7 = 周日。
List<CalendarCell> buildMonthGrid(
  String yearMonth, {
  required String today,
  int weekStart = 1,
}) {
  final parts = yearMonth.split('-');
  if (parts.length != 2) {
    return const <CalendarCell>[];
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return const <CalendarCell>[];
  }
  final first = DateTime(year, month, 1);
  final offset = (first.weekday - weekStart + 7) % 7;
  final start = DateTime(year, month, 1 - offset);

  return List<CalendarCell>.generate(42, (index) {
    final day = DateTime(start.year, start.month, start.day + index);
    final date = isoDate(day);
    return CalendarCell(
      date: date,
      inMonth: day.month == month && day.year == year,
      isWeekend: day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday,
      isToday: date == today,
    );
  });
}

/// 星期中文名（周一…周日）。
///
/// 非法日期返回空串 —— 解析层不抛异常，与 `parseIsoDate` 的约定一致。
String weekdayLabel(String date) {
  final parsed = parseIsoDate(date);
  if (parsed == null) {
    return '';
  }
  return _weekdayNames[parsed.weekday - 1];
}

/// 标题文案（`2026-11-07 周六`）。
String dateTitle(String date) {
  final label = weekdayLabel(date);
  if (label.isEmpty) {
    return date;
  }
  return '$date $label';
}

/// 相对日期标签（今天 / 昨天 / 前天 / 明天 / 周X）。
String relativeDayLabel(String date, {required String today}) {
  if (date == today) {
    return '今天';
  }
  if (date == shiftIsoDate(today, -1)) {
    return '昨天';
  }
  if (date == shiftIsoDate(today, -2)) {
    return '前天';
  }
  if (date == shiftIsoDate(today, 1)) {
    return '明天';
  }
  return weekdayLabel(date);
}
