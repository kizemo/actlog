// =============================================================================
// l10n part：习惯打卡（W5 波次拥有本文件）
// =============================================================================
// 覆盖三块 UI：心态卡片（`widgets\mood_section.dart`）、习惯打卡
// （`widgets\habit_section.dart` / `widgets\habit_checkin_strip.dart` /
// `pages\habits_page.dart`）、优先级（`widgets\priority_chips.dart` /
// `widgets\priority_marks.dart` / `widgets\priority_hover_bubble.dart`）。
//
// 三条纪律：
//   1. zh 逐字对齐旧串（含全角括号、`·`、`—`、句末 `。`）。差一个空格，
//      「纯重构、零语义变化」就不成立。每条 zh 上方标了出处。
//   2. en 没有旧代码可对齐 ⇒ 是新定文案，只保证语义对应。
//   3. **落库值不翻译**：`targetUnit`（`次`）的显示映射、心态维度的落库 key、
//      领域芯片的 6 个中文落库值都留在调用点，本文件只承载「显示文案」。
//
// 复用声明：`重要 / 不重要 / 紧急 / 不紧急`、`是 / 否`、`清除 / 清除优先级`、
// `关闭`、`取消`、`次` 都已由 `parts\common.dart` 提供，本文件**不重复建键**。
// =============================================================================

/// 习惯打卡文案（心态 + 习惯 + 优先级）。
abstract class HabitL10n {
  // ---------------------------------------------------------------------------
  // 心态卡片：分组与标题
  // ---------------------------------------------------------------------------

  /// 心态分组名：每日核心。
  String get moodGroupDayTitle;

  /// 心态分组名：每周补充。
  String get moodGroupWeekTitle;

  /// 心态卡片副标题：`每日 3 项 + 每周 2 项，各 0–10 分；留空表示不作评`。
  String get moodSectionSubtitle;

  // ---------------------------------------------------------------------------
  // 心态卡片：操作与状态
  // ---------------------------------------------------------------------------

  /// 按钮：全部清空。
  String get moodClearAll;

  /// 空态：今天没打分。
  String get moodMarkFailed;

  /// 输入框标签：明日改进点。
  String get moodNextActionLabel;

  /// 输入框提示：明天先做的一件具体事。
  String get moodNextActionHint;

  /// 输入框标签：情绪备注。
  String get moodNoteLabel;

  /// 输入框提示：今天状态如何？为什么？
  String get moodNoteHint;

  /// 维度未评标记。
  String get moodUnrated;

  /// 无障碍/提示：清除这一维。
  String get moodClearDimension;

  // ---------------------------------------------------------------------------
  // 心态维度：5 个新维度（出处：`packages\core_data\lib\src\mood_dimensions.dart`
  // 的 `moodDimensionDefs`，按 `key` 取用）
  // ---------------------------------------------------------------------------

  /// 维度名：履约负责。
  String get moodDimFulfillmentLabel;

  /// 维度说明：履约负责。
  String get moodDimFulfillmentDesc;

  /// 维度名：高效高质。
  String get moodDimEfficiencyLabel;

  /// 维度说明：高效高质。
  String get moodDimEfficiencyDesc;

  /// 维度名：积极思维。
  String get moodDimPositiveMindLabel;

  /// 维度说明：积极思维。
  String get moodDimPositiveMindDesc;

  /// 维度名：自我效能。
  String get moodDimSelfEfficacyLabel;

  /// 维度说明：自我效能。
  String get moodDimSelfEfficacyDesc;

  /// 维度名：利他贡献。
  String get moodDimContributionLabel;

  /// 维度说明：利他贡献。
  String get moodDimContributionDesc;

  // ---------------------------------------------------------------------------
  // 心态维度：8 个 legacy 列（出处：`packages\core_domain\lib\src\entities.dart`
  // 的 `MoodDimension` 枚举 `label`；仅历史数据展示用）
  // ---------------------------------------------------------------------------

  /// legacy 维度名：认真。
  String get moodLegacyDiligent;

  /// legacy 维度名：快。
  String get moodLegacyFast;

  /// legacy 维度名：坚守承诺。
  String get moodLegacyKeepPromise;

  /// legacy 维度名：保证完成任务。
  String get moodLegacyFinishTask;

  /// legacy 维度名：乐观。
  String get moodLegacyOptimistic;

  /// legacy 维度名：自信。
  String get moodLegacyConfident;

  /// legacy 维度名：爱与奉献。
  String get moodLegacyLoveAndDedication;

  /// legacy 维度名：决不找借口。
  String get moodLegacyNoExcuses;

  // ---------------------------------------------------------------------------
  // 习惯打卡：区块 / 吸底条 / 习惯页
  // ---------------------------------------------------------------------------

  /// 区块标题：习惯打卡。
  String get habitSectionTitle;

  /// 区块副标题：`打勾会同步生成今日计划里的回填行`。
  String get habitSectionSubtitle;

  /// 区块空态：`今天没有排程内的习惯。`（注意句末句号，与
  /// `domainNoHabitsDueToday` 不是同一条）。
  String get habitSectionEmpty;

  /// 吸底条加载中。
  String get habitCheckinLoading;

  /// 吸底条加载失败。
  String get habitCheckinError;

  /// 吸底条标题：`习惯打卡 · 吸底不滚动`。
  String get habitCheckinHeadTitle;

  /// 吸底条提示：`· 一点即打，跳过需理由`。
  String get habitCheckinHeadHint;

  /// 习惯页标题：习惯。
  String get habitPageTitle;

  /// 习惯页未来日提示：`未来日只做预排：习惯打卡在当天开放。`。
  String get habitPageFutureHint;

  /// 习惯页空态：还没有习惯。
  String get habitPageEmpty;

  // ---------------------------------------------------------------------------
  // 优先级
  // ---------------------------------------------------------------------------

  /// 象限选择对话框标题。
  String get priorityPickQuadrant;

  /// ABC 选择对话框标题。
  String get priorityPickAbc;

  /// 悬停气泡徽标：当前。
  String get priorityBubbleCurrent;

  /// 悬停气泡脚注（只读态）。
  String get priorityBubbleReadonly;

  /// 悬停气泡脚注（可编辑态）。
  String get priorityBubbleEditable;

  // ---------------------------------------------------------------------------
  // 带参数的插值文案
  // ---------------------------------------------------------------------------

  /// 心态计分：`已评 N/M 维`。
  String moodRatedCount(int rated, int total);

  /// 心态均分：`均分 <value>`（`value` 为已格式化串，可能为 `—`）。
  String moodAverage(String value);

  /// 分组头：`<title> · 每日更新` / `<title> · 每周更新`。
  String moodGroupHeader(String title, bool isDay);

  /// 分组进度：`N 项 · 已评 M`。
  String moodGroupProgress(int total, int rated);

  /// 佐证行：`佐证：<joined>`。
  String moodEvidence(String joined);

  /// 习惯目标：`目标 N<unit>`。
  String habitTarget(String amount, String unit);

  /// 习惯加载失败：`习惯加载失败：<error>`。
  String habitLoadFailed(String error);

  /// 打卡记录加载失败：`打卡记录加载失败：<error>`。
  String habitCheckinLoadFailed(String error);

  /// 象限气泡无障碍摘要：`<象限>，紧急：是，重要：否`。
  String priorityBubbleA11y(
    String quadrantLabel,
    bool urgent,
    bool important,
  );
}

/// 文案：简体中文（逐字对齐旧常量）。
mixin HabitZhL10n implements HabitL10n {
  /// 旧代码：`widgets\mood_section.dart:39` 的 `_groupTitle` 日分支。
  @override
  String get moodGroupDayTitle => '每日核心';

  /// 旧代码：`widgets\mood_section.dart:41` 的 `_groupTitle` 周分支。
  @override
  String get moodGroupWeekTitle => '每周补充';

  /// 旧代码：`widgets\mood_section.dart:73`。注意是 `0–10`（U+2013 en dash）。
  @override
  String get moodSectionSubtitle => '每日 3 项 + 每周 2 项，各 0–10 分；留空表示不作评';

  /// 旧代码：`widgets\mood_section.dart:219`。
  @override
  String get moodClearAll => '全部清空';

  /// 旧代码：`widgets\mood_section.dart:236`。
  @override
  String get moodMarkFailed => '今天没打分';

  /// 旧代码：`packages\core_data\lib\src\mood_dimensions.dart:148`
  /// 的 `moodNextActionLabel`。
  @override
  String get moodNextActionLabel => '明日改进点';

  /// 旧代码：`widgets\mood_section.dart:262`。
  @override
  String get moodNextActionHint => '明天先做的一件具体事';

  /// 旧代码：`widgets\mood_section.dart:270`。
  @override
  String get moodNoteLabel => '情绪备注';

  /// 旧代码：`widgets\mood_section.dart:273`。
  @override
  String get moodNoteHint => '今天状态如何？为什么？';

  /// 旧代码：`widgets\mood_section.dart:355`。
  @override
  String get moodUnrated => '未评';

  /// 旧代码：`widgets\mood_section.dart:367` 的 `tooltip`。
  @override
  String get moodClearDimension => '清除这一维';

  /// 旧代码：`mood_dimensions.dart:89`。
  @override
  String get moodDimFulfillmentLabel => '履约负责';

  /// 旧代码：`mood_dimensions.dart:90`。
  @override
  String get moodDimFulfillmentDesc => '说到就做到：先守住已经答应的交付。';

  /// 旧代码：`mood_dimensions.dart:100`。
  @override
  String get moodDimEfficiencyLabel => '高效高质';

  /// 旧代码：`mood_dimensions.dart:101`。
  @override
  String get moodDimEfficiencyDesc => '要事优先：先把可支配的时间给最重要的那件事。';

  /// 旧代码：`mood_dimensions.dart:108`。
  @override
  String get moodDimPositiveMindLabel => '积极思维';

  /// 旧代码：`mood_dimensions.dart:109`。
  @override
  String get moodDimPositiveMindDesc => '积极主动：把注意力放在自己能影响的部分。';

  /// 旧代码：`mood_dimensions.dart:115`。
  @override
  String get moodDimSelfEfficacyLabel => '自我效能';

  /// 旧代码：`mood_dimensions.dart:116`。
  @override
  String get moodDimSelfEfficacyDesc => '以终为始：这周是否完成了自己认定的关键一步。';

  /// 旧代码：`mood_dimensions.dart:122`。
  @override
  String get moodDimContributionLabel => '利他贡献';

  /// 旧代码：`mood_dimensions.dart:123`。
  @override
  String get moodDimContributionDesc => '贡献而非努力：这一周为别人解决了什么具体问题。';

  /// 旧代码：`packages\core_domain\lib\src\entities.dart:17`。
  @override
  String get moodLegacyDiligent => '认真';

  /// 旧代码：`entities.dart:20`。
  @override
  String get moodLegacyFast => '快';

  /// 旧代码：`entities.dart:23`。
  @override
  String get moodLegacyKeepPromise => '坚守承诺';

  /// 旧代码：`entities.dart:26`。
  @override
  String get moodLegacyFinishTask => '保证完成任务';

  /// 旧代码：`entities.dart:29`。
  @override
  String get moodLegacyOptimistic => '乐观';

  /// 旧代码：`entities.dart:32`。
  @override
  String get moodLegacyConfident => '自信';

  /// 旧代码：`entities.dart:35`。
  @override
  String get moodLegacyLoveAndDedication => '爱与奉献';

  /// 旧代码：`entities.dart:38`。
  @override
  String get moodLegacyNoExcuses => '决不找借口';

  /// 旧代码：`widgets\habit_section.dart:23`。
  @override
  String get habitSectionTitle => '习惯打卡';

  /// 旧代码：`widgets\habit_section.dart:24`。
  @override
  String get habitSectionSubtitle => '打勾会同步生成今日计划里的回填行';

  /// 旧代码：`widgets\habit_section.dart:41`。
  @override
  String get habitSectionEmpty => '今天没有排程内的习惯。';

  /// 旧代码：`widgets\habit_checkin_strip.dart:40`。
  @override
  String get habitCheckinLoading => '正在加载打卡状态…';

  /// 旧代码：`widgets\habit_checkin_strip.dart:43`。
  @override
  String get habitCheckinError => '打卡状态加载失败，请稍后重试';

  /// 旧代码：`widgets\habit_checkin_strip.dart:46`。
  @override
  String get habitCheckinHeadTitle => '习惯打卡 · 吸底不滚动';

  /// 旧代码：`widgets\habit_checkin_strip.dart:49`。
  @override
  String get habitCheckinHeadHint => '· 一点即打，跳过需理由';

  /// 旧代码：`pages\habits_page.dart:75`。
  @override
  String get habitPageTitle => '习惯';

  /// 旧代码：`pages\habits_page.dart:99`。
  @override
  String get habitPageFutureHint => '未来日只做预排：习惯打卡在当天开放。';

  /// 旧代码：`pages\habits_page.dart:118`。
  @override
  String get habitPageEmpty => '还没有习惯';

  /// 旧代码：`widgets\priority_chips.dart:76`。
  @override
  String get priorityPickQuadrant => '选择四象限';

  /// 旧代码：`widgets\priority_chips.dart:236`。
  @override
  String get priorityPickAbc => '选择 ABC 优先级';

  /// 旧代码：`widgets\priority_hover_bubble.dart:425`。
  @override
  String get priorityBubbleCurrent => '当前';

  /// 旧代码：`widgets\priority_hover_bubble.dart:493`。
  @override
  String get priorityBubbleReadonly => '点标记开关 · 分级写入未开放';

  /// 旧代码：`widgets\priority_hover_bubble.dart:493`。
  @override
  String get priorityBubbleEditable => '点标记开关 · 点维度改分级';

  /// 旧代码：`widgets\mood_section.dart:207`。
  @override
  String moodRatedCount(int rated, int total) => '已评 $rated/$total 维';

  /// 旧代码：`widgets\mood_section.dart:213`。
  @override
  String moodAverage(String value) => '均分 $value';

  /// 旧代码：`widgets\mood_section.dart` 的 `_MoodGroupHeader` 标题拼接。
  @override
  String moodGroupHeader(String title, bool isDay) =>
      '$title · ${isDay ? '每日' : '每周'}更新';

  /// 旧代码：`widgets\mood_section.dart` 的 `_MoodGroupHeader` 进度拼接。
  @override
  String moodGroupProgress(int total, int rated) => '$total 项 · 已评 $rated';

  /// 旧代码：`widgets\mood_section.dart:379` 的 `' · '` 连接。
  @override
  String moodEvidence(String joined) => '佐证：$joined';

  /// 旧代码：`widgets\habit_section.dart:139`、`pages\habits_page.dart:196`。
  @override
  String habitTarget(String amount, String unit) => '目标 $amount$unit';

  /// 旧代码：`pages\habits_page.dart:104`。
  @override
  String habitLoadFailed(String error) => '习惯加载失败：$error';

  /// 旧代码：`pages\habits_page.dart:157`。
  @override
  String habitCheckinLoadFailed(String error) => '打卡记录加载失败：$error';

  /// 旧代码：`widgets\priority_hover_bubble.dart:231-233`。
  @override
  String priorityBubbleA11y(
    String quadrantLabel,
    bool urgent,
    bool important,
  ) =>
      '$quadrantLabel，紧急：${urgent ? '是' : '否'}，重要：${important ? '是' : '否'}';
}

/// 文案：English。
mixin HabitEnL10n implements HabitL10n {
  @override
  String get moodGroupDayTitle => 'Daily core';

  @override
  String get moodGroupWeekTitle => 'Weekly add-on';

  @override
  String get moodSectionSubtitle =>
      '3 daily + 2 weekly items, 0–10 each; leave blank to skip';

  @override
  String get moodClearAll => 'Clear all';

  @override
  String get moodMarkFailed => 'Not scored today';

  @override
  String get moodNextActionLabel => 'Tomorrow’s improvement point';

  @override
  String get moodNextActionHint => 'One concrete thing to do first tomorrow';

  @override
  String get moodNoteLabel => 'Mood note';

  @override
  String get moodNoteHint => 'How was today? Why?';

  @override
  String get moodUnrated => 'Unrated';

  @override
  String get moodClearDimension => 'Clear this dimension';

  @override
  String get moodDimFulfillmentLabel => 'Keeps promises';

  @override
  String get moodDimFulfillmentDesc =>
      'Do what you said: protect the commitments you already made.';

  @override
  String get moodDimEfficiencyLabel => 'Effective and high quality';

  @override
  String get moodDimEfficiencyDesc =>
      'First things first: spend your available time on what matters most.';

  @override
  String get moodDimPositiveMindLabel => 'Positive mindset';

  @override
  String get moodDimPositiveMindDesc =>
      'Be proactive: focus on the part you can influence.';

  @override
  String get moodDimSelfEfficacyLabel => 'Self-efficacy';

  @override
  String get moodDimSelfEfficacyDesc =>
      'Begin with the end in mind: did you complete the key step you set this week?';

  @override
  String get moodDimContributionLabel => 'Contribution';

  @override
  String get moodDimContributionDesc =>
      'Contribution over effort: what concrete problem did you solve for others this week?';

  @override
  String get moodLegacyDiligent => 'Diligent';

  @override
  String get moodLegacyFast => 'Fast';

  @override
  String get moodLegacyKeepPromise => 'Keep promises';

  @override
  String get moodLegacyFinishTask => 'Finish the task';

  @override
  String get moodLegacyOptimistic => 'Optimistic';

  @override
  String get moodLegacyConfident => 'Confident';

  @override
  String get moodLegacyLoveAndDedication => 'Love and dedication';

  @override
  String get moodLegacyNoExcuses => 'No excuses';

  @override
  String get habitSectionTitle => 'Habit check-in';

  @override
  String get habitSectionSubtitle =>
      'Checking a habit also adds a backfill row to today’s plan';

  @override
  String get habitSectionEmpty => 'No habits are scheduled today.';

  @override
  String get habitCheckinLoading => 'Loading check-in status…';

  @override
  String get habitCheckinError => 'Failed to load check-in status, try again later';

  @override
  String get habitCheckinHeadTitle => 'Habit check-in · pinned, no scroll';

  @override
  String get habitCheckinHeadHint => '· one tap to log, a reason is required to skip';

  @override
  String get habitPageTitle => 'Habits';

  @override
  String get habitPageFutureHint =>
      'Future days are for scheduling only: check-in opens on the day itself.';

  @override
  String get habitPageEmpty => 'No habits yet';

  @override
  String get priorityPickQuadrant => 'Choose a quadrant';

  @override
  String get priorityPickAbc => 'Choose an ABC priority';

  @override
  String get priorityBubbleCurrent => 'Current';

  @override
  String get priorityBubbleReadonly => 'Tap a mark to toggle · grading is read-only';

  @override
  String get priorityBubbleEditable => 'Tap a mark to toggle · tap a dimension to regrade';

  @override
  String moodRatedCount(int rated, int total) => '$rated/$total rated';

  @override
  String moodAverage(String value) => 'Avg $value';

  @override
  String moodGroupHeader(String title, bool isDay) =>
      '$title · updated ${isDay ? 'daily' : 'weekly'}';

  @override
  String moodGroupProgress(int total, int rated) => '$total items · $rated rated';

  @override
  String moodEvidence(String joined) => 'Evidence: $joined';

  @override
  String habitTarget(String amount, String unit) => 'Target $amount $unit';

  @override
  String habitLoadFailed(String error) => 'Failed to load habits: $error';

  @override
  String habitCheckinLoadFailed(String error) =>
      'Failed to load check-in records: $error';

  @override
  String priorityBubbleA11y(
    String quadrantLabel,
    bool urgent,
    bool important,
  ) =>
      '$quadrantLabel, urgent: ${urgent ? 'yes' : 'no'}, '
      'important: ${important ? 'yes' : 'no'}';
}