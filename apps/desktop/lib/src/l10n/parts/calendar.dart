// =============================================================================
// l10n part：日历与日期（计划 §47 W2 波次拥有本文件）
// =============================================================================
// 三件套的形状与 `parts\settings.dart` / `parts\projects.dart` 完全一致：
//   1. `CalendarL10n` 只声明成员，不带实现；
//   2. `CalendarZhL10n` / `CalendarEnL10n` 用 `mixin` 实现接口，`@override` 齐全
//      —— 少一条就是编译期错误；
//   3. 聚合在 `app_localizations.dart`（`CalendarZhL10n` / `CalendarEnL10n` 两个
//      mixin 已经在里面，本文件不需要改）。
//
// 为什么本文件**允许** `import 'package:core_data/core_data.dart'`：
// 依赖方向永远是「应用 → 包」，包层不依赖应用层。日历的几处日期算法（网格、
// 星期名、日期标题）本来就住在 `core_data`，日期标题直接复用它的 `dateTitle`
// 才能保证中文态与改动前**同源**（一字之差都不可能发生）。
//
// 为什么日期/星期这类**格式**走方法（method）而不是 getter：
//   - 「月份标题」「日期标题」都要带参数（年月串 / 日期串），无参 getter 装不下；
//   - 星期表头是**一列**词（周一起 7 个），拆成 7 个 getter 再在页面里拼是
//     反模式（骨架文件的头注释早就写明过），所以给一个 `List<String>` getter。
// 这两类成员由登记侧分别放进 `byMethod` / `byListGetter`。
//
// 中文取值一律**逐字**等于改动前的字面量（详见 `reports\task61-calendar-getters.md`）；
// 英文取值是新译文案，风格与 `parts\settings.dart` 的英文段一致：简洁名词短语。
// =============================================================================

import 'package:core_data/core_data.dart';

/// 日历与日期文案。
abstract class CalendarL10n {
  // ---------------------------------------------------------------------------
  // 日历页（pages\calendar_page.dart）
  // ---------------------------------------------------------------------------

  /// 日历页标题。
  String get calendarPageTitle;

  /// 翻月按钮：上个月。
  String get calendarPrevMonth;

  /// 翻月按钮：下个月。
  String get calendarNextMonth;

  // ---------------------------------------------------------------------------
  // 月视图（widgets\calendar_month_view.dart）
  // ---------------------------------------------------------------------------

  /// 月历格右上角的「今天」角标。
  String get calendarTodayBadge;

  // ---------------------------------------------------------------------------
  // 日期条（widgets\date_bar.dart）
  // ---------------------------------------------------------------------------

  /// 日期条左箭头：前一天。
  String get calendarPrevDay;

  /// 日期条右箭头：后一天。
  String get calendarNextDay;

  /// 日期条只读徽标：过去日（补录模式）。
  String get calendarBackfillMode;

  /// 日期条只读徽标：未来日（预排）。
  String get calendarPrePlanMode;

  // ---------------------------------------------------------------------------
  // 日期选择弹层（widgets\date_picker_sheet.dart）
  // ---------------------------------------------------------------------------

  /// 弹层翻月按钮：上一月。
  String get calendarPickerPrevMonth;

  /// 弹层翻月按钮：下一月。
  String get calendarPickerNextMonth;

  /// 快捷芯片：今天。
  String get calendarToday;

  /// 快捷芯片：昨天。
  String get calendarYesterday;

  /// 快捷芯片：前天。
  String get calendarDayBeforeYesterday;

  /// 快捷芯片：明天。
  String get calendarTomorrow;

  /// 快捷芯片：本周内。
  String get calendarThisWeek;

  /// 快捷芯片：无期限。
  String get calendarNoDeadline;

  // ---------------------------------------------------------------------------
  // 列表型与插值方法（locale 敏感格式）
  // ---------------------------------------------------------------------------

  /// 星期短名（周一起、周日末，共 7 条）。
  List<String> get calendarWeekdaysShort;

  /// 月份标题：`2026-11` → `2026-11` / `Nov 2026`。
  String calendarMonthLabel(String yearMonth);

  /// 日期标题：`2026-11-07` → `2026-11-07 周六` / `2026-11-07 Sat`。
  String calendarDateTitle(String date);
}

/// 日历与日期文案：简体中文（逐字对齐改动前的字面量）。
mixin CalendarZhL10n implements CalendarL10n {
  @override
  String get calendarPageTitle => '日历';

  @override
  String get calendarPrevMonth => '上个月';

  @override
  String get calendarNextMonth => '下个月';

  @override
  String get calendarTodayBadge => '今';

  @override
  String get calendarPrevDay => '前一天';

  @override
  String get calendarNextDay => '后一天';

  @override
  String get calendarBackfillMode => '补录模式';

  @override
  String get calendarPrePlanMode => '预排';

  @override
  String get calendarPickerPrevMonth => '上一月';

  @override
  String get calendarPickerNextMonth => '下一月';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarYesterday => '昨天';

  @override
  String get calendarDayBeforeYesterday => '前天';

  @override
  String get calendarTomorrow => '明天';

  @override
  String get calendarThisWeek => '本周内';

  @override
  String get calendarNoDeadline => '无期限';

  /// 改动前月历表头就是这 7 个单字（`widgets\calendar_month_view.dart:48`）。
  @override
  List<String> get calendarWeekdaysShort => const <String>[
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  /// 中文态的月份标题**原样返回** `yyyy-MM` —— 改动前页面里渲染的就是这个串，
  /// 逐字不变。
  @override
  String calendarMonthLabel(String yearMonth) => yearMonth;

  /// 中文态的日期标题直接复用包层 [dateTitle]（`2026-11-07 周六`）：
  /// 与改动前**同源同字**，不可能出现一字之差；非法输入的兜底行为也完全一致。
  @override
  String calendarDateTitle(String date) => dateTitle(date);
}

/// 日历与日期文案：English。
mixin CalendarEnL10n implements CalendarL10n {
  @override
  String get calendarPageTitle => 'Calendar';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarTodayBadge => 'Today';

  @override
  String get calendarPrevDay => 'Previous day';

  @override
  String get calendarNextDay => 'Next day';

  @override
  String get calendarBackfillMode => 'Backfill';

  @override
  String get calendarPrePlanMode => 'Scheduled';

  @override
  String get calendarPickerPrevMonth => 'Previous month';

  @override
  String get calendarPickerNextMonth => 'Next month';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarYesterday => 'Yesterday';

  @override
  String get calendarDayBeforeYesterday => 'Day before yesterday';

  @override
  String get calendarTomorrow => 'Tomorrow';

  @override
  String get calendarThisWeek => 'This week';

  @override
  String get calendarNoDeadline => 'No deadline';

  /// 英文月历表头：三字母缩写（`Mon`…`Sun`），与中文的单字表头一一对应。
  @override
  List<String> get calendarWeekdaysShort => const <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// 英文月份标题：`2026-11` → `Nov 2026`。
  ///
  /// 解析失败时原样返回（与中文态同口径：不猜、不崩）。
  @override
  String calendarMonthLabel(String yearMonth) {
    final List<String> parts = yearMonth.split('-');
    if (parts.length != 2) {
      return yearMonth;
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return yearMonth;
    }
    return '${_enMonths[month - 1]} $year';
  }

  /// 英文日期标题：`2026-11-07` → `2026-11-07 Sat`。
  ///
  /// 星期名与表头共用同一份短名表（[calendarWeekdaysShort]），两者不会走偏。
  @override
  String calendarDateTitle(String date) {
    final DateTime? parsed = parseIsoDate(date);
    if (parsed == null) {
      return date;
    }
    return '$date ${calendarWeekdaysShort[parsed.weekday - 1]}';
  }
}

/// 英文月份短名（1 月起）。
const List<String> _enMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
