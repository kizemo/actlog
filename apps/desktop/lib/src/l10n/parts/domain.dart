// =============================================================================
// l10n part：领域口径文案（W0 建立，各波次按需追加到自己的 part）
// =============================================================================
// 两类成员：
//   1. 无参 getter：优先级展示文案的 id 化落点。包层（core_data / core_domain）
//      只出 **文案 id**（如 `domain-quadrant-q1-label`），文案本体在这里按语言给；
//      纯 Dart 包没有 `BuildContext`，所以包层不得调 `AppLocalizations.of`。
//   2. 带参方法：页面里现成的拼串形态（`共 N 分钟`、`已顺延 N 天`），形态与
//      getter 不同，单列在文件末尾。
//
// 为什么中文实现要逐字对着旧代码抄：这些文案存在的唯一理由，就是把包层/页面里
// 现成的中文原样搬过来。只要中文输出与旧串差一个空格，这一轮「纯重构、零语义
// 变化」就不成立。文件内注释标了各自的出处。
//
// 英文实现没有旧代码可对齐（旧代码里没有任何英文态），因此英文措辞是新定文案，
// 只保证语义对应，不声称「等价于旧代码」。
// =============================================================================

/// 领域口径文案。
abstract class DomainL10n {
  // ---------------------------------------------------------------------------
  // 四象限（出处：`packages\core_data\lib\src\priority.dart` 的 `QuadrantStyle`）
  // ---------------------------------------------------------------------------

  /// 象限全名：Q1。
  String get quadrantQ1Label;

  /// 象限短名：Q1。
  String get quadrantQ1ShortLabel;

  /// 象限全名：Q2。
  String get quadrantQ2Label;

  /// 象限短名：Q2。
  String get quadrantQ2ShortLabel;

  /// 象限全名：Q3。
  String get quadrantQ3Label;

  /// 象限短名：Q3。
  String get quadrantQ3ShortLabel;

  /// 象限全名：Q4。
  String get quadrantQ4Label;

  /// 象限短名：Q4。
  String get quadrantQ4ShortLabel;

  // ---------------------------------------------------------------------------
  // ABC 分级（出处：同文件的 `AbcStyle`）
  // ---------------------------------------------------------------------------

  /// A 级标签。
  String get abcALabel;

  /// B 级标签。
  String get abcBLabel;

  /// C 级标签。
  String get abcCLabel;

  // ---------------------------------------------------------------------------
  // 未分级（出处：同文件 `PriorityDisplay.labelFor` 的两个兜底分支 +
  // `widgets\timeline\unscheduled_strip.dart:125` 的独立硬编码 —— 三处同一文案）
  // ---------------------------------------------------------------------------

  /// 未分级标签。
  String get priorityUnsetLabel;

  // ---------------------------------------------------------------------------
  // 带参数的插值文案
  // ---------------------------------------------------------------------------

  /// 时长：`N 小时`。
  String hoursCount(int hours);

  /// 时长：`共 N 分钟` / `N 分钟`。
  String minutesCount(int minutes);

  /// 顺延天数：`已顺延 N 天`。
  String deferredDays(int days);

  /// 心态维度分值标签：`<维度>分值`（用于校验失败信息）。
  String moodScoreLabel(String dimensionLabel);
}

/// 文案：简体中文（逐字对齐旧常量）。
mixin DomainZhL10n implements DomainL10n {
  @override
  String get quadrantQ1Label => '重要且紧急';

  @override
  String get quadrantQ1ShortLabel => '立即做';

  @override
  String get quadrantQ2Label => '重要不紧急';

  @override
  String get quadrantQ2ShortLabel => '计划做';

  @override
  String get quadrantQ3Label => '紧急不重要';

  @override
  String get quadrantQ3ShortLabel => '委托做';

  @override
  String get quadrantQ4Label => '不重要不紧急';

  @override
  String get quadrantQ4ShortLabel => '少做';

  @override
  String get abcALabel => 'A 类要事';

  @override
  String get abcBLabel => 'B 类次要';

  @override
  String get abcCLabel => 'C 类一般';

  @override
  String get priorityUnsetLabel => '未分级';

  /// 旧代码：`widgets\est_duration_text.dart:64` —— `'${minutes ~/ 60} 小时'`。
  @override
  String hoursCount(int hours) => '$hours 小时';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:137` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:351` —— `'共 N 分钟'`。
  /// 这里不带 `共` 前缀：需要前缀的调用点自己拼，避免把 `共` 也变成强制。
  @override
  String minutesCount(int minutes) => '$minutes 分钟';

  /// 旧代码：`packages\core_data\lib\src\standup.dart:293` —— `'已顺延 N 天'`。
  @override
  String deferredDays(int days) => '已顺延 $days 天';

  /// 旧代码：`packages\core_domain\lib\src\entities.dart:240` ——
  /// `'${entry.key.label}分值'`。
  @override
  String moodScoreLabel(String dimensionLabel) => '$dimensionLabel分值';
}

/// 文案：English。
mixin DomainEnL10n implements DomainL10n {
  @override
  String get quadrantQ1Label => 'Urgent and important';

  @override
  String get quadrantQ1ShortLabel => 'Do now';

  @override
  String get quadrantQ2Label => 'Important, not urgent';

  @override
  String get quadrantQ2ShortLabel => 'Schedule it';

  @override
  String get quadrantQ3Label => 'Urgent, not important';

  @override
  String get quadrantQ3ShortLabel => 'Delegate it';

  @override
  String get quadrantQ4Label => 'Neither urgent nor important';

  @override
  String get quadrantQ4ShortLabel => 'Do less';

  @override
  String get abcALabel => 'Class A must-do';

  @override
  String get abcBLabel => 'Class B secondary';

  @override
  String get abcCLabel => 'Class C optional';

  @override
  String get priorityUnsetLabel => 'Unclassified';

  @override
  String hoursCount(int hours) => '$hours h';

  @override
  String minutesCount(int minutes) => '$minutes min';

  @override
  String deferredDays(int days) => 'Carried over $days day(s)';

  @override
  String moodScoreLabel(String dimensionLabel) => '$dimensionLabel score';
}