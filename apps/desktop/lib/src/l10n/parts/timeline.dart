// =============================================================================
// l10n part：方格时间轴（Task 63 · W3 波次拥有本文件）
// =============================================================================
// W0 只搭骨架、不搬文案。时间轴里时间与时长文案特别多（`共 N 分钟`、
// `HH:mm–HH:mm`），搬进来时优先用 `DomainL10n` 已有的插值方法，不要另造一套
// 分隔符 —— 否则中文态会出现「、」与「-」混用。
//
// 本波次实际复用（不新建同义键）：
//   `t.cancel`、`t.commonTitle`、`t.commonSave`、`t.commonDelete`、
//   `t.priorityUnsetLabel`、`t.domainPlanLabel`、`t.domainBackfillLabel`、
//   `t.domainConclusionLabel`、`t.domainReasonLabel`、`t.domainNextStepLabel`。
//
// 中文实现逐字对齐旧代码（出处标在各自注释里）；英文是新定措辞，只保证语义
// 对应。键名口径：kebab-case、前缀 `timeline-`、由 `l10n_keys.dart` 登记。
// =============================================================================

/// 方格时间轴文案。
abstract class TimelineL10n {
  // ---------------------------------------------------------------------------
  // 空态 / 提示
  // ---------------------------------------------------------------------------

  /// 空格子上的引导语。
  String get timelineEmptyGridHint;

  /// 习惯入格条目的角标。
  String get timelineHabitBackfill;

  /// 手填弹窗的输入框提示。
  String get timelinePlanTitleHint;

  /// 手填弹窗的确认按钮（≠ `confirm`/「确定」）。
  String get timelineScheduleAction;

  // ---------------------------------------------------------------------------
  // 右键三级菜单
  // ---------------------------------------------------------------------------

  /// 菜单分组名：手填。
  String get timelineManualGroup;

  /// 菜单项：手填一条。
  String get timelineManualEntry;

  /// 菜单分组名：待办。
  String get timelineTodoGroup;

  /// 待办分支空态。
  String get timelineTodoPoolEmpty;

  /// 菜单分组名：习惯。
  String get timelineHabitGroup;

  /// 习惯分支空态。
  String get timelineHabitEmpty;

  /// 起止弹窗的确认按钮（zh 是「确认」，与 `confirm` 的「确定」不是一条）。
  String get timelineConfirmAction;

  // ---------------------------------------------------------------------------
  // 起止 / 时长
  // ---------------------------------------------------------------------------

  /// 步进行标签：开始。
  String get timelineStartLabel;

  /// 步进行标签：结束。
  String get timelineEndLabel;

  /// 时长行标签：持续时间。
  String get timelineDurationLabel;

  // ---------------------------------------------------------------------------
  // 回填与详情
  // ---------------------------------------------------------------------------

  /// 回填弹层标题。
  String get timelineSlotFillTitle;

  /// 回填模板按钮。
  String get timelineOutcomeTemplateTitle;

  /// 详情窗标题。
  String get timelineTaskDetailTitle;

  /// 详情窗字段名：内容。
  String get timelineContentLabel;

  /// 详情窗字段名：级别。
  String get timelineLevelLabel;

  /// 详情窗字段名：回填内容。
  String get timelineBackfillContentLabel;

  /// 未来日的回填锁定提示。
  String get timelineFutureDayBackfillBlocked;

  /// 删除计划项的确认框标题。
  String get timelineDeletePlanItemTitle;

  // ---------------------------------------------------------------------------
  // 四态文字通道（两态复用 `domainPlanLabel` / `domainBackfillLabel`）
  // ---------------------------------------------------------------------------

  /// 状态词：打卡。
  String get timelineKindHabitLabel;

  /// 状态词：完成。
  String get timelineKindDoneLabel;

  // ---------------------------------------------------------------------------
  // 右轨待办面板
  // ---------------------------------------------------------------------------

  /// 待办加载失败。
  String get timelineTodoLoadFailed;

  /// 待办加载中。
  String get timelineTodoLoading;

  /// 待办空态。
  String get timelineTodoEmpty;

  /// 已排期徽标。
  String get timelineTodoSlotted;

  // ---------------------------------------------------------------------------
  // 时间轴节点（`day_timeline.dart`；产品侧已无调用方，仅测试使用）
  // ---------------------------------------------------------------------------

  /// 节点文字：有缺口。
  String get timelineNodeGap;

  /// 节点文字：已闭合。
  String get timelineNodeClosed;

  // ---------------------------------------------------------------------------
  // 带参数的插值文案
  // ---------------------------------------------------------------------------

  /// 菜单标题：`HH:mm 这一格`。
  String timelineSlotMenuTitle(String time);

  /// 起止弹窗标题：`YYYY-MM-DD · 起止`。
  String timelineRangeTitle(String date);

  /// 时长：`共 N 分钟`（`slot_range_dialog.dart` 与
  /// `plan_item_detail_dialog.dart` 共用）。
  String timelineTotalMinutes(int minutes);

  /// 步进按钮 tooltip：`<标签> 减一格`。
  String timelineStepDown(String label);

  /// 步进按钮 tooltip：`<标签> 加一格`。
  String timelineStepUp(String label);

  /// 手填弹窗标题：`HH:mm 要做什么？`。
  String timelineSlotPrompt(String time);

  /// 写库失败提示：`写入失败：<error>`（两处共用同一条）。
  String timelineWriteFailed(String error);

  /// 删除确认正文：`确认删除「<title>」？…`。
  String timelineDeletePlanItemMessage(String title);

  /// 悬停卡片：详情行。
  String timelineHoverDetail(String detail);

  /// 悬停卡片：进展行。
  String timelineHoverNote(String note);

  /// 悬停卡片：状态行。
  String timelineHoverState(String state);

  /// 悬停卡片：级别行。
  String timelineHoverLevel(String level);
}

/// 方格时间轴文案：简体中文。
mixin TimelineZhL10n implements TimelineL10n {
  /// 旧代码：`widgets\timeline\day_grid.dart:397`。
  @override
  String get timelineEmptyGridHint => '右键任意一格开始排期';

  /// 旧代码：`widgets\timeline\day_grid.dart:838`。
  @override
  String get timelineHabitBackfill => '习惯回填';

  /// 旧代码：`widgets\timeline\day_grid.dart:1307`。
  @override
  String get timelinePlanTitleHint => '计划标题';

  /// 旧代码：`widgets\timeline\day_grid.dart:1318`。
  @override
  String get timelineScheduleAction => '排上';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:109`。
  @override
  String get timelineManualGroup => '手填';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:113`。
  @override
  String get timelineManualEntry => '手填一条';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:118`。
  @override
  String get timelineTodoGroup => '待办';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:120`。
  @override
  String get timelineTodoPoolEmpty => '待办池里没有可入格的条目';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:131`。
  @override
  String get timelineHabitGroup => '习惯';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:133`。
  @override
  String get timelineHabitEmpty => '这天没有排程内的习惯';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:151`。
  @override
  String get timelineConfirmAction => '确认';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:121` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:482`。
  @override
  String get timelineStartLabel => '开始';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:129` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:490`。
  @override
  String get timelineEndLabel => '结束';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:479`。
  @override
  String get timelineDurationLabel => '持续时间';

  /// 旧代码：`widgets\timeline\slot_fill.dart:46`。
  @override
  String get timelineSlotFillTitle => '成果 / 进展';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:475`。
  @override
  String get timelineOutcomeTemplateTitle => '成果 / 进展模板';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:389`。
  @override
  String get timelineTaskDetailTitle => '任务详情';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:422`。
  @override
  String get timelineContentLabel => '内容';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:428`。
  @override
  String get timelineLevelLabel => '级别';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:450`。
  @override
  String get timelineBackfillContentLabel => '回填内容';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:458`。
  @override
  String get timelineFutureDayBackfillBlocked =>
      '未来日不可回填：打卡 / 回填 / 复盘 / 心态只允许今天与过去。';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:351`。
  @override
  String get timelineDeletePlanItemTitle => '删除计划项';

  /// 旧代码：`widgets\timeline\slot_state.dart:281`。
  @override
  String get timelineKindHabitLabel => '打卡';

  /// 旧代码：`widgets\timeline\slot_state.dart:285`。
  @override
  String get timelineKindDoneLabel => '完成';

  /// 旧代码：`widgets\timeline\todo_rail_panel.dart:36`。
  @override
  String get timelineTodoLoadFailed => '待办加载失败';

  /// 旧代码：`widgets\timeline\todo_rail_panel.dart:38`。
  @override
  String get timelineTodoLoading => '正在加载待办…';

  /// 旧代码：`widgets\timeline\todo_rail_panel.dart:44`。
  @override
  String get timelineTodoEmpty => '暂无待办';

  /// 旧代码：`widgets\timeline\todo_rail_panel.dart:187`。
  @override
  String get timelineTodoSlotted => '已排期';

  /// 旧代码：`widgets\day_timeline.dart:34`。
  @override
  String get timelineNodeGap => '▸ 有缺口';

  /// 旧代码：`widgets\day_timeline.dart:34`。
  @override
  String get timelineNodeClosed => '✓ 已闭合';

  /// 旧代码：`widgets\timeline\slot_context_menu.dart:99`。
  @override
  String timelineSlotMenuTitle(String time) => '$time 这一格';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:113`。
  @override
  String timelineRangeTitle(String date) => '$date · 起止';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:137` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:498`。
  @override
  String timelineTotalMinutes(int minutes) => '共 $minutes 分钟';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:190` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:567`。
  @override
  String timelineStepDown(String label) => '$label 减一格';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:208` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:585`。
  @override
  String timelineStepUp(String label) => '$label 加一格';

  /// 旧代码：`widgets\timeline\day_grid.dart:1301`。
  @override
  String timelineSlotPrompt(String time) => '$time 要做什么？';

  /// 旧代码：`widgets\timeline\day_grid.dart:888` 与
  /// `widgets\timeline\unscheduled_strip.dart:88`。
  @override
  String timelineWriteFailed(String error) => '写入失败：$error';

  /// 旧代码：`widgets\timeline\plan_item_detail_dialog.dart:352`。
  @override
  String timelineDeletePlanItemMessage(String title) =>
      '确认删除「$title」？删除后它不再出现在清单里。';

  /// 旧代码：`widgets\timeline\slot_hover_card.dart:436`。
  @override
  String timelineHoverDetail(String detail) => '详情：$detail';

  /// 旧代码：`widgets\timeline\slot_hover_card.dart:439`。
  @override
  String timelineHoverNote(String note) => '进展：$note';

  /// 旧代码：`widgets\timeline\slot_hover_card.dart:442`。
  @override
  String timelineHoverState(String state) => '状态：$state';

  /// 旧代码：`widgets\timeline\slot_hover_card.dart:445`。
  @override
  String timelineHoverLevel(String level) => '级别：$level';
}

/// 方格时间轴文案：English。
mixin TimelineEnL10n implements TimelineL10n {
  @override
  String get timelineEmptyGridHint => 'Right-click any cell to start scheduling';

  @override
  String get timelineHabitBackfill => 'Habit backfill';

  @override
  String get timelinePlanTitleHint => 'Plan title';

  @override
  String get timelineScheduleAction => 'Schedule';

  @override
  String get timelineManualGroup => 'Manual';

  @override
  String get timelineManualEntry => 'Write one entry';

  @override
  String get timelineTodoGroup => 'To-dos';

  @override
  String get timelineTodoPoolEmpty => 'No to-dos available to slot';

  @override
  String get timelineHabitGroup => 'Habits';

  @override
  String get timelineHabitEmpty => 'No habits scheduled for this day';

  @override
  String get timelineConfirmAction => 'Confirm';

  @override
  String get timelineStartLabel => 'Start';

  @override
  String get timelineEndLabel => 'End';

  @override
  String get timelineDurationLabel => 'Duration';

  @override
  String get timelineSlotFillTitle => 'Outcome / progress';

  @override
  String get timelineOutcomeTemplateTitle => 'Outcome / progress template';

  @override
  String get timelineTaskDetailTitle => 'Task details';

  @override
  String get timelineContentLabel => 'Content';

  @override
  String get timelineLevelLabel => 'Level';

  @override
  String get timelineBackfillContentLabel => 'Backfill content';

  @override
  String get timelineFutureDayBackfillBlocked =>
      'Future days cannot be backfilled: check-in / backfill / review / mood '
      'are limited to today and the past.';

  @override
  String get timelineDeletePlanItemTitle => 'Delete plan item';

  @override
  String get timelineKindHabitLabel => 'Checked in';

  @override
  String get timelineKindDoneLabel => 'Done';

  @override
  String get timelineTodoLoadFailed => 'Failed to load to-dos';

  @override
  String get timelineTodoLoading => 'Loading to-dos…';

  @override
  String get timelineTodoEmpty => 'No to-dos';

  @override
  String get timelineTodoSlotted => 'Scheduled';

  @override
  String get timelineNodeGap => '▸ Gap';

  @override
  String get timelineNodeClosed => '✓ Closed';

  @override
  String timelineSlotMenuTitle(String time) => 'Slot at $time';

  @override
  String timelineRangeTitle(String date) => '$date · Start / end';

  @override
  String timelineTotalMinutes(int minutes) => '$minutes min total';

  @override
  String timelineStepDown(String label) => 'Decrease $label by one step';

  @override
  String timelineStepUp(String label) => 'Increase $label by one step';

  @override
  String timelineSlotPrompt(String time) => 'What are you doing at $time?';

  @override
  String timelineWriteFailed(String error) => 'Write failed: $error';

  @override
  String timelineDeletePlanItemMessage(String title) =>
      'Delete "$title"? It will no longer appear in the list.';

  @override
  String timelineHoverDetail(String detail) => 'Details: $detail';

  @override
  String timelineHoverNote(String note) => 'Progress: $note';

  @override
  String timelineHoverState(String state) => 'Status: $state';

  @override
  String timelineHoverLevel(String level) => 'Level: $level';
}