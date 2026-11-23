// =============================================================================
// l10n part：项目页（Task 56）
// =============================================================================
// 17 条，全部是无参 String getter（不新增插值方法 ⇒ `byMethod` 仍是 4 条）。
// 带数量的那一条（「未排期 {n} 条」）用 `{n}` 占位符，由页面侧 `replaceAll` 插值。
//
// 键前缀统一 `projects-`（与 `settings-` / `about-` / `common-` / `shell-` /
// `domain-` 同一套规矩）。键登记在 `l10n_keys.dart` 的 `byGetter` 里。
// =============================================================================

/// 项目页文案。
abstract class ProjectsL10n {
  /// 页面标题。
  String get projectsTitle;

  /// 页面副标题。
  String get projectsSubtitle;

  /// 一个项目都没有时的空态。
  String get projectsEmpty;

  /// 新建项目按钮。
  String get projectsNewProjectAction;

  /// 项目名称输入框提示。
  String get projectsNameHint;

  /// 项目目标输入框提示。
  String get projectsGoalHint;

  /// 开始日期输入框提示。
  String get projectsStartHint;

  /// 结束日期输入框提示。
  String get projectsEndHint;

  /// 任务标题输入框提示。
  String get projectsTaskTitleHint;

  /// 目标日期输入框提示。
  String get projectsTargetDateHint;

  /// 添加任务按钮。
  String get projectsAddTaskAction;

  /// 改期按钮。
  String get projectsRescheduleAction;

  /// 未排期条数（`{n}` 由页面插值）。
  String get projectsUnscheduled;

  /// 项目下还没有任务时的空态。
  String get projectsNoTask;

  /// 项目没有设定起止日期。
  String get projectsNoDateRange;

  /// 甘特图画不出任何日期时的空态。
  String get projectsEmptyChart;

  /// 读取失败。
  String get projectsLoadFailed;

  /// 把项目整体排进今天。
  String get projectsScheduleTodayAction;

  /// 已排到某一天（`{date}` 由页面插值）。
  String get projectsScheduledOn;

  /// 增量区块标题。
  String get projectsIncrementTitle;

  /// 还没有增量时的提交按钮（动作即空态）。
  String get projectsIncrementEmptyAction;

  /// 增量「进展」输入提示。
  String get projectsIncrementProgressHint;

  /// 增量「阻塞项」输入提示。
  String get projectsIncrementBlockersHint;

  /// 增量「下一步」输入提示。
  String get projectsIncrementNextStepHint;

  /// 追加增量按钮（已有增量时）。
  String get projectsIncrementAddAction;

  /// 把一条增量排进今天。
  String get projectsIncrementToTodayAction;

  /// 增量只能追加的说明。
  String get projectsIncrementAppendOnly;

  /// 里程碑逾期标记。
  String get projectsMilestoneOverdue;

  /// 增量行摘要上的「摘录」标注。
  String get projectsIncrementExcerptTag;

  /// 「摘录」标注的悬停说明：原文在当天的日志里。
  String get projectsIncrementExcerptHint;

  /// 打开该条增量对应的当天日志原文。
  String get projectsIncrementOpenOriginalAction;
}

/// 项目页文案：简体中文。
mixin ProjectsZhL10n implements ProjectsL10n {
  @override
  String get projectsTitle => '项目';

  @override
  String get projectsSubtitle => '按目标日期排期，自动进入待办池';

  @override
  String get projectsEmpty => '还没有项目。先建一个项目，再往里加任务。';

  @override
  String get projectsNewProjectAction => '新建项目';

  @override
  String get projectsNameHint => '项目名称';

  @override
  String get projectsGoalHint => '目标（可留空）';

  @override
  String get projectsStartHint => '开始日期 YYYY-MM-DD';

  @override
  String get projectsEndHint => '结束日期 YYYY-MM-DD';

  @override
  String get projectsTaskTitleHint => '任务标题';

  @override
  String get projectsTargetDateHint => '目标日期 YYYY-MM-DD';

  @override
  String get projectsAddTaskAction => '添加任务';

  @override
  String get projectsRescheduleAction => '改期';

  @override
  String get projectsUnscheduled => '未排期 {n} 条';

  @override
  String get projectsNoTask => '还没有任务';

  @override
  String get projectsNoDateRange => '未设定起止日期';

  @override
  String get projectsEmptyChart => '没有可排期的日期';

  @override
  String get projectsLoadFailed => '加载失败';

  @override
  String get projectsScheduleTodayAction => '＋ 排进今天';

  @override
  String get projectsScheduledOn => '已排 {date}';

  @override
  String get projectsIncrementTitle => '增量';

  @override
  String get projectsIncrementEmptyAction => '写第一条增量';

  @override
  String get projectsIncrementProgressHint => '这次推进了什么';

  @override
  String get projectsIncrementBlockersHint => '卡在哪里（可留空）';

  @override
  String get projectsIncrementNextStepHint => '下一步做什么（可留空）';

  @override
  String get projectsIncrementAddAction => '追加增量';

  @override
  String get projectsIncrementToTodayAction => '→ 今天';

  @override
  String get projectsIncrementAppendOnly => '增量只能追加；写错了就再写一条更正。';

  @override
  String get projectsMilestoneOverdue => '逾期';

  @override
  String get projectsIncrementExcerptTag => '摘录';

  @override
  String get projectsIncrementExcerptHint => '从当天的复盘摘录，原文在日志里';

  @override
  String get projectsIncrementOpenOriginalAction => '查看原文';
}

/// 项目页文案：English。
mixin ProjectsEnL10n implements ProjectsL10n {
  @override
  String get projectsTitle => 'Projects';

  @override
  String get projectsSubtitle =>
      'Schedule tasks by target date; they land in the todo pool';

  @override
  String get projectsEmpty =>
      'No project yet. Create one, then add tasks to it.';

  @override
  String get projectsNewProjectAction => 'New project';

  @override
  String get projectsNameHint => 'Project name';

  @override
  String get projectsGoalHint => 'Goal (optional)';

  @override
  String get projectsStartHint => 'Start date YYYY-MM-DD';

  @override
  String get projectsEndHint => 'End date YYYY-MM-DD';

  @override
  String get projectsTaskTitleHint => 'Task title';

  @override
  String get projectsTargetDateHint => 'Target date YYYY-MM-DD';

  @override
  String get projectsAddTaskAction => 'Add task';

  @override
  String get projectsRescheduleAction => 'Reschedule';

  @override
  String get projectsUnscheduled => '{n} unscheduled';

  @override
  String get projectsNoTask => 'No task yet';

  @override
  String get projectsNoDateRange => 'No start / end date';

  @override
  String get projectsEmptyChart => 'No date to lay out';

  @override
  String get projectsLoadFailed => 'Failed to load';

  @override
  String get projectsScheduleTodayAction => '+ Plan today';

  @override
  String get projectsScheduledOn => 'Planned {date}';

  @override
  String get projectsIncrementTitle => 'Increments';

  @override
  String get projectsIncrementEmptyAction => 'Write the first increment';

  @override
  String get projectsIncrementProgressHint => 'What moved forward';

  @override
  String get projectsIncrementBlockersHint => 'What is blocking it (optional)';

  @override
  String get projectsIncrementNextStepHint => 'Next step (optional)';

  @override
  String get projectsIncrementAddAction => 'Add increment';

  @override
  String get projectsIncrementToTodayAction => '→ Today';

  @override
  String get projectsIncrementAppendOnly =>
      'Increments are append-only; write a new one to correct.';

  @override
  String get projectsMilestoneOverdue => 'Overdue';

  @override
  String get projectsIncrementExcerptTag => 'Excerpt';

  @override
  String get projectsIncrementExcerptHint =>
      "Excerpted from that day's review; the original is in the log";

  @override
  String get projectsIncrementOpenOriginalAction => 'Open original';
}
