// =============================================================================
// l10n part：今日面板（Task 63 批次二 W4 填实）
// =============================================================================
// 覆盖范围（4 个文件、唯一前缀 `today-`）：
//   pages\today_page.dart            今日页正文 / 手写条 / 右轨闭环提示 / 页内横幅
//   widgets\review_section.dart      复盘三段 + 记到项目
//   widgets\loop_progress_ring.dart  闭环脊线（四段比例条）
//   widgets\standup_section.dart     站会三段
//
// 键前缀一律 `today-`：侦察底稿里 `review-*` / `standup-*` / `loop-ring-*` 三个
// 前缀已作废（`waves\task63-batch2-w4.md` §1），避免同一块 UI 出现多套命名。
//
// 复用而不新建：计划 / 回填 / 复盘 / 心态四个段名，以及「当日日志尚未建立」
// 「今天没有待打卡的习惯」两条空态，已在 `parts\domain.dart` 有同句同义的
// getter（多波次共用口径），本文件**不再自建同形键**。
//
// 中文实现逐字对着旧字面量抄（空格、全角括号、`·`、`—`、`；` 都不能少），
// 这一轮是「纯重构、零语义变化」；英文实现没有旧代码可对齐，是新定措辞，
// 只保证语义对应。文件内注释标了各自的出处。
// =============================================================================

/// 今日面板文案。
abstract class TodayL10n {
  // ---------------------------------------------------------------------------
  // 今日页：未来日占位与预排提示
  // ---------------------------------------------------------------------------

  /// 未来日锁定卡标题：复盘与心态在当天开放。
  String get todayReviewFutureTitle;

  /// 未来日锁定卡说明。
  String get todayReviewFutureDetail;

  /// 未来日「只可预排」提示（正文，手写条下方）。
  String get todayFuturePlanOnly;

  /// 未来日锁定卡副标题。
  String get todayFuturePlanning;

  // ---------------------------------------------------------------------------
  // 今日页：手写条的日期 / 时刻按钮
  // ---------------------------------------------------------------------------

  /// 菜单项：改日期。
  String get todayChangeDate;

  /// 菜单项：改时刻。
  String get todayChangeTime;

  /// 菜单项：清除时刻（仅已排时刻时出现）。
  String get todayClearTime;

  /// 未排时刻：`时间 · 未排`。
  String get todayTimeUnset;

  /// 已排时刻：`时间 · <时刻>`。
  String todayTimeSet(String time);

  /// 日期芯片文案：`日期 · <日期>`。
  String todayDateLabel(String date);

  /// 日期按钮的无障碍标签（日期 + 时刻 + 可做什么）。
  String todayDateChipA11y(String date, String time);

  /// 时刻选择器的标题。
  String get todayPickStartTime;

  /// 方格时间轴起点提示（选了过早的时刻时）。
  String todayGridStartHint(String time);

  // ---------------------------------------------------------------------------
  // 今日页：手写条与右轨
  // ---------------------------------------------------------------------------

  /// 手写输入框占位：添加计划条目…
  String get todayAddPlanHint;

  /// 手写按钮：+ 手写一条。
  String get todayAddManual;

  /// 右轨习惯速览：加载失败。
  String get todayHabitLoadFailed;

  /// 右轨习惯速览：正在加载。
  String get todayHabitLoading;

  /// 右轨习惯速览：所选日无排程习惯。
  String get todayHabitEmpty;

  // ---------------------------------------------------------------------------
  // 今日页：右轨闭环提示的四段标签与两个状态词
  // ---------------------------------------------------------------------------

  /// 闭环提示第一行：计划缺口。
  String get todayStatPlanGap;

  /// 闭环提示第二行：回填缺口。
  String get todayStatFillGap;

  /// 复盘状态：已写。
  String get todayStatWritten;

  /// 复盘状态：未写。
  String get todayStatUnwritten;

  /// 心态状态：已记。
  String get todayStatRecorded;

  /// 心态状态：未记。
  String get todayStatUnrecorded;

  /// 项目停滞提醒正文。
  String todayStallHint(String name, int days);

  /// 项目停滞提醒的抑制按钮：今天不再提。
  String get todayStallDismiss;

  // ---------------------------------------------------------------------------
  // 今日页：快捷键提示与页内横幅
  // ---------------------------------------------------------------------------

  /// 未来日拒绝打卡的提示。
  String get todayNoticeFutureCheckin;

  /// 习惯数据加载失败提示。
  String todayHabitLoadError(String error);

  /// 打卡成功提示。
  String todayCheckedIn(String name);

  /// 打卡失败提示。
  String todayCheckinFailed(String error);

  /// 提示横幅的关闭按钮：知道了。
  String get todayGotIt;

  // ---------------------------------------------------------------------------
  // 复盘区块
  // ---------------------------------------------------------------------------

  /// 复盘字段一标题。
  String get todayReviewFieldLearn;

  /// 复盘字段一占位。
  String get todayReviewFieldLearnHint;

  /// 复盘字段二标题。
  String get todayReviewFieldGood;

  /// 复盘字段二占位。
  String get todayReviewFieldGoodHint;

  /// 复盘字段三标题。
  String get todayReviewFieldImprove;

  /// 复盘字段三占位。
  String get todayReviewFieldImproveHint;

  /// 复盘区块副标题。
  String get todayReviewSubtitle;

  /// 三段全空时的行内提示。
  String get todayReviewEmptyNotice;

  /// 选项目对话框标题。
  String get todayReviewPickProject;

  /// 「记到项目」按钮文案。
  String get todayReviewFileToProject;

  /// 已记到某项目。
  String todayReviewFiledTo(String project);

  /// 把两段摘录拼成一条增量正文（中文分号 / 英文分号加空格）。
  String todayReviewJoinSegments(List<String> segments);

  // ---------------------------------------------------------------------------
  // 闭环脊线（LoopProgressRing）
  // ---------------------------------------------------------------------------

  /// 脊线抬头：闭环环 · 四段比例条。
  String get todayLoopRingA11y;

  /// 脊线刻度说明：刻度 0—100。
  String get todayLoopRingScale;

  // ---------------------------------------------------------------------------
  // 站会区块
  // ---------------------------------------------------------------------------

  /// 站会区块标题。
  String get todayStandupTitle;

  /// 站会区块副标题。
  String get todayStandupSubtitle;

  /// 三段全空时的整块提示。
  String get todayStandupEmpty;

  /// 第一段：昨日亮点。
  String get todayStandupYesterday;

  /// 第一段空态。
  String get todayStandupYesterdayEmpty;

  /// 第二段：今日优先。
  String get todayStandupToday;

  /// 第二段空态。
  String get todayStandupTodayEmpty;

  /// 第三段：阻塞项。
  String get todayStandupBlockers;

  /// 第三段空态。
  String get todayStandupBlockersEmpty;

  /// 段标题 + 条目数：`<标签>（N）`。
  String todayStandupSectionCount(String label, int count);
}

/// 今日面板文案：简体中文（逐字对齐旧字面量）。
mixin TodayZhL10n implements TodayL10n {
  /// 旧代码：`pages\today_page.dart:168` —— `'复盘与心态在当天开放'`。
  @override
  String get todayReviewFutureTitle => '复盘与心态在当天开放';

  /// 旧代码：`pages\today_page.dart:169` —— `'未来日只做预排：到了那天再写复盘与心态。'`。
  @override
  String get todayReviewFutureDetail => '未来日只做预排：到了那天再写复盘与心态。';

  /// 旧代码：`pages\today_page.dart:439` ——
  /// `'未来日只可预排：可以先写计划，到了那天才能打卡与回填。'`。
  @override
  String get todayFuturePlanOnly => '未来日只可预排：可以先写计划，到了那天才能打卡与回填。';

  /// 旧代码：`pages\today_page.dart:703` —— `'未来日只做预排'`。
  @override
  String get todayFuturePlanning => '未来日只做预排';

  /// 旧代码：`pages\today_page.dart:330` —— `'改日期'`。
  @override
  String get todayChangeDate => '改日期';

  /// 旧代码：`pages\today_page.dart:334` —— `'改时刻'`。
  @override
  String get todayChangeTime => '改时刻';

  /// 旧代码：`pages\today_page.dart:342` —— `'清除时刻'`。
  @override
  String get todayClearTime => '清除时刻';

  /// 旧代码：`pages\today_page.dart:364` —— `'时间 · 未排'`。
  @override
  String get todayTimeUnset => '时间 · 未排';

  /// 旧代码：`pages\today_page.dart:365` —— `'时间 · ${formatMinute(...)}'`。
  @override
  String todayTimeSet(String time) => '时间 · $time';

  /// 旧代码：`pages\today_page.dart:403` —— `'日期 · ${widget.date}'`。
  @override
  String todayDateLabel(String date) => '日期 · $date';

  /// 旧代码：`pages\today_page.dart:375` ——
  /// `'日期 ${widget.date}，$timeLabel，点击修改日期或时刻'`。
  @override
  String todayDateChipA11y(String date, String time) =>
      '日期 $date，$time，点击修改日期或时刻';

  /// 旧代码：`pages\today_page.dart:569` —— `'选择开始时刻'`。
  @override
  String get todayPickStartTime => '选择开始时刻';

  /// 旧代码：`pages\today_page.dart:585`–`:586` 的两段相邻字面量拼接。
  @override
  String todayGridStartHint(String time) =>
      '方格时间轴从 $time 开始：更早的时刻排不进格子，这条会落在下方未排期带。';

  /// 旧代码：`pages\today_page.dart:608` —— `'添加计划条目…'`。
  @override
  String get todayAddPlanHint => '添加计划条目…';

  /// 旧代码：`pages\today_page.dart:625` —— `'+ 手写一条'`（半角加号）。
  @override
  String get todayAddManual => '+ 手写一条';

  /// 旧代码：`pages\today_page.dart:795` —— `'习惯速览加载失败'`。
  @override
  String get todayHabitLoadFailed => '习惯速览加载失败';

  /// 旧代码：`pages\today_page.dart:798` —— `'正在加载习惯…'`。
  @override
  String get todayHabitLoading => '正在加载习惯…';

  /// 旧代码：`pages\today_page.dart:803` —— `'所选日没有排程习惯'`。
  @override
  String get todayHabitEmpty => '所选日没有排程习惯';

  /// 旧代码：`pages\today_page.dart:921` —— `'计划缺口'`。
  @override
  String get todayStatPlanGap => '计划缺口';

  /// 旧代码：`pages\today_page.dart:922` —— `'回填缺口'`。
  @override
  String get todayStatFillGap => '回填缺口';

  /// 旧代码：`pages\today_page.dart:935` —— `'已写'`。
  @override
  String get todayStatWritten => '已写';

  /// 旧代码：`pages\today_page.dart:935` —— `'未写'`。
  @override
  String get todayStatUnwritten => '未写';

  /// 旧代码：`pages\today_page.dart:936` —— `'已记'`。
  @override
  String get todayStatRecorded => '已记';

  /// 旧代码：`pages\today_page.dart:936` —— `'未记'`。
  @override
  String get todayStatUnrecorded => '未记';

  /// 旧代码：`pages\today_page.dart:1021`–`:1022` 的两段相邻字面量拼接。
  @override
  String todayStallHint(String name, int days) =>
      '「$name」$days 天没有增量了，想起它的时候再推一步。';

  /// 旧代码：`pages\today_page.dart:1045` —— `'今天不再提'`。
  @override
  String get todayStallDismiss => '今天不再提';

  /// 旧代码：`pages\today_page.dart:1232` —— `'未来日只做预排：到了那天再打卡。'`。
  @override
  String get todayNoticeFutureCheckin => '未来日只做预排：到了那天再打卡。';

  /// 旧代码：`pages\today_page.dart:1244` —— `'习惯数据加载失败：$error'`。
  @override
  String todayHabitLoadError(String error) => '习惯数据加载失败：$error';

  /// 旧代码：`pages\today_page.dart:1267` —— `'已打卡：${target.name}'`。
  @override
  String todayCheckedIn(String name) => '已打卡：$name';

  /// 旧代码：`pages\today_page.dart:1269` —— `'打卡失败：$error'`。
  @override
  String todayCheckinFailed(String error) => '打卡失败：$error';

  /// 旧代码：`pages\today_page.dart:1304` —— `'知道了'`。
  @override
  String get todayGotIt => '知道了';

  /// 旧代码：`widgets\review_section.dart:40` —— `'学到了什么'`。
  @override
  String get todayReviewFieldLearn => '学到了什么';

  /// 旧代码：`widgets\review_section.dart:40` —— `'今天最大的一个认知收获'`。
  @override
  String get todayReviewFieldLearnHint => '今天最大的一个认知收获';

  /// 旧代码：`widgets\review_section.dart:41` —— `'做得好'`。
  @override
  String get todayReviewFieldGood => '做得好';

  /// 旧代码：`widgets\review_section.dart:41` —— `'值得保留的做法'`。
  @override
  String get todayReviewFieldGoodHint => '值得保留的做法';

  /// 旧代码：`widgets\review_section.dart:42` —— `'待改进'`。
  @override
  String get todayReviewFieldImprove => '待改进';

  /// 旧代码：`widgets\review_section.dart:42` —— `'下次换个做法的地方'`。
  @override
  String get todayReviewFieldImproveHint => '下次换个做法的地方';

  /// 旧代码：`widgets\review_section.dart:289` ——
  /// `'哪几段有想法就写哪几段，留白不影响保存'`。
  @override
  String get todayReviewSubtitle => '哪几段有想法就写哪几段，留白不影响保存';

  /// 旧代码：`widgets\review_section.dart:167` —— `'三段都还空着，先写一句再记'`。
  @override
  String get todayReviewEmptyNotice => '三段都还空着，先写一句再记';

  /// 旧代码：`widgets\review_section.dart:216` —— `'记到哪个项目'`。
  @override
  String get todayReviewPickProject => '记到哪个项目';

  /// 旧代码：`widgets\review_section.dart:265` —— `'→ 记到项目'`。
  @override
  String get todayReviewFileToProject => '→ 记到项目';

  /// 旧代码：`widgets\review_section.dart:198` —— `'已记到「${chosen.name}」'`。
  @override
  String todayReviewFiledTo(String project) => '已记到「$project」';

  /// 旧代码：`widgets\review_section.dart:164` —— `.join('；')`。
  @override
  String todayReviewJoinSegments(List<String> segments) => segments.join('；');

  /// 旧代码：`widgets\loop_progress_ring.dart:146` —— `'闭环环 · 四段比例条'`。
  @override
  String get todayLoopRingA11y => '闭环环 · 四段比例条';

  /// 旧代码：`widgets\loop_progress_ring.dart:154` —— `'刻度 0—100'`。
  @override
  String get todayLoopRingScale => '刻度 0—100';

  /// 旧代码：`widgets\standup_section.dart:24` —— `'站会'`。
  @override
  String get todayStandupTitle => '站会';

  /// 旧代码：`widgets\standup_section.dart:25` ——
  /// `'昨天做成了什么 · 今天最重要的事 · 卡在哪'`。
  @override
  String get todayStandupSubtitle => '昨天做成了什么 · 今天最重要的事 · 卡在哪';

  /// 旧代码：`widgets\standup_section.dart:35` ——
  /// `'三段都还没有内容 —— 先给今天加几条计划，或者去补昨天的记录。'`。
  @override
  String get todayStandupEmpty => '三段都还没有内容 —— 先给今天加几条计划，或者去补昨天的记录。';

  /// 旧代码：`widgets\standup_section.dart:43` —— `'昨日亮点'`。
  @override
  String get todayStandupYesterday => '昨日亮点';

  /// 旧代码：`widgets\standup_section.dart:46` —— `'昨天没有已完成的条目'`。
  @override
  String get todayStandupYesterdayEmpty => '昨天没有已完成的条目';

  /// 旧代码：`widgets\standup_section.dart:50` —— `'今日优先'`。
  @override
  String get todayStandupToday => '今日优先';

  /// 旧代码：`widgets\standup_section.dart:53` —— `'今天还没有待办条目'`。
  @override
  String get todayStandupTodayEmpty => '今天还没有待办条目';

  /// 旧代码：`widgets\standup_section.dart:57` —— `'阻塞项'`。
  @override
  String get todayStandupBlockers => '阻塞项';

  /// 旧代码：`widgets\standup_section.dart:60` —— `'没有检测到阻塞 — 保持住'`。
  @override
  String get todayStandupBlockersEmpty => '没有检测到阻塞 — 保持住';

  /// 旧代码：`widgets\standup_section.dart:94` —— `'$label（${entries.length}）'`。
  @override
  String todayStandupSectionCount(String label, int count) => '$label（$count）';
}

/// 今日面板文案：English。
mixin TodayEnL10n implements TodayL10n {
  @override
  String get todayReviewFutureTitle => 'Review and mood open on the day';

  @override
  String get todayReviewFutureDetail =>
      'Future days are for planning only: write the review and mood once the day arrives.';

  @override
  String get todayFuturePlanOnly =>
      'Future days are plan-only: you can write plans now, but check-in and backfill open on the day.';

  @override
  String get todayFuturePlanning => 'Future days are plan-only';

  @override
  String get todayChangeDate => 'Change date';

  @override
  String get todayChangeTime => 'Change time';

  @override
  String get todayClearTime => 'Clear time';

  @override
  String get todayTimeUnset => 'Time · Unset';

  @override
  String todayTimeSet(String time) => 'Time · $time';

  @override
  String todayDateLabel(String date) => 'Date · $date';

  @override
  String todayDateChipA11y(String date, String time) =>
      'Date $date, $time. Tap to change the date or time.';

  @override
  String get todayPickStartTime => 'Pick a start time';

  @override
  String todayGridStartHint(String time) =>
      'The grid starts at $time: earlier times do not fit a cell, so this item lands in the unscheduled strip below.';

  @override
  String get todayAddPlanHint => 'Add a plan item…';

  @override
  String get todayAddManual => '+ Write one';

  @override
  String get todayHabitLoadFailed => 'Failed to load the habit overview';

  @override
  String get todayHabitLoading => 'Loading habits…';

  @override
  String get todayHabitEmpty => 'No habits scheduled for this day';

  @override
  String get todayStatPlanGap => 'Plan gap';

  @override
  String get todayStatFillGap => 'Backfill gap';

  @override
  String get todayStatWritten => 'Written';

  @override
  String get todayStatUnwritten => 'Not written';

  @override
  String get todayStatRecorded => 'Logged';

  @override
  String get todayStatUnrecorded => 'Not logged';

  @override
  String todayStallHint(String name, int days) =>
      '"$name" has had no progress for $days days; push it one step when it comes to mind.';

  @override
  String get todayStallDismiss => "Don't mention it today";

  @override
  String get todayNoticeFutureCheckin =>
      'Future days are plan-only: check in once the day arrives.';

  @override
  String todayHabitLoadError(String error) => 'Failed to load habit data: $error';

  @override
  String todayCheckedIn(String name) => 'Checked in: $name';

  @override
  String todayCheckinFailed(String error) => 'Check-in failed: $error';

  @override
  String get todayGotIt => 'Got it';

  @override
  String get todayReviewFieldLearn => 'What I learned';

  @override
  String get todayReviewFieldLearnHint => 'The biggest insight from today';

  @override
  String get todayReviewFieldGood => 'What went well';

  @override
  String get todayReviewFieldGoodHint => 'Practices worth keeping';

  @override
  String get todayReviewFieldImprove => 'What to improve';

  @override
  String get todayReviewFieldImproveHint =>
      'Where to try a different approach next time';

  @override
  String get todayReviewSubtitle =>
      'Write whichever sections you have thoughts on; blanks do not affect saving';

  @override
  String get todayReviewEmptyNotice =>
      'All three sections are empty — write a line before filing';

  @override
  String get todayReviewPickProject => 'Which project to file to';

  @override
  String get todayReviewFileToProject => '→ File to project';

  @override
  String todayReviewFiledTo(String project) => 'Filed to "$project"';

  @override
  String todayReviewJoinSegments(List<String> segments) => segments.join('; ');

  @override
  String get todayLoopRingA11y => 'Loop ring · four-segment bars';

  @override
  String get todayLoopRingScale => 'Scale 0-100';

  @override
  String get todayStandupTitle => 'Standup';

  @override
  String get todayStandupSubtitle =>
      "What got done yesterday · Today's most important thing · Where you are stuck";

  @override
  String get todayStandupEmpty =>
      "All three sections are empty — add a few plans for today, or fill in yesterday's record.";

  @override
  String get todayStandupYesterday => "Yesterday's highlights";

  @override
  String get todayStandupYesterdayEmpty => 'Nothing was completed yesterday';

  @override
  String get todayStandupToday => "Today's priorities";

  @override
  String get todayStandupTodayEmpty => 'No to-dos for today yet';

  @override
  String get todayStandupBlockers => 'Blockers';

  @override
  String get todayStandupBlockersEmpty => 'No blockers detected — keep it up';

  @override
  String todayStandupSectionCount(String label, int count) => '$label ($count)';
}