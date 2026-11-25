// =============================================================================
// l10n part：对话框 / 确认气泡（W6 波次拥有本文件）
// =============================================================================
// W0 只搭骨架、不搬文案。注意对话框按钮「取消 / 确定」已经有 `CommonL10n`
// 的一份，W6 不要在这里再声明同义 getter —— 两份同名文案是将来最容易被改歪的
// 地方，需要不同措辞时用不同的名字。
//
// 复用纪律：本文件只收「确实没有既有 getter 可用」的串。凡 `CommonL10n` /
// `DomainL10n` 已有同句同义的，一律在调用点直接用（`t.cancel`、`t.commonSave`、
// `t.commonTitle`、`t.commonClose`、`t.commonDelete`、`t.commonUnitDay`、
// `t.commonUnitWeek`、`t.commonUnitTimes`、`t.calendarWeekdaysShort`、
// `t.domainWeekdayFull`、`t.minutesCount`），不在此重建。
//
// 落库值 / 判定值不迁：
//   * `habit_quick_dialog.dart:198` 的 `targetUnit: '次'` 是写进 `habit.target_unit`
//     的列值，不随语言变；
//   * 全角 `＋`（U+FF0B）是按钮字形，不是文案。
// =============================================================================

/// 对话框文案。
abstract class DialogL10n {
  // ---------------------------------------------------------------------------
  // 预估时长单位（出处：`widgets\est_duration_text.dart:14-37` 的 `EstUnit.label`）
  //
  // 枚举自带的 `label` 字段保持中文不动（`test\task39_est_unit_test.dart` 直接
  // 引用它），单位词的显示一律走这 5 条 getter；`formatEstDuration` 与
  // `EstUnitPicker` 改为运行时注入 `AppLocalizations`。
  // ---------------------------------------------------------------------------

  /// 预估时长单位：分钟。
  String get dialogEstUnitMinute;

  /// 预估时长单位：小时。
  String get dialogEstUnitHour;

  /// 预估时长单位：日。
  String get dialogEstUnitDay;

  /// 预估时长单位：周。
  String get dialogEstUnitWeek;

  /// 预估时长单位：月。
  String get dialogEstUnitMonth;

  // ---------------------------------------------------------------------------
  // 「添加习惯」面板（出处：`widgets\habit_quick_dialog.dart`）
  // ---------------------------------------------------------------------------

  /// 校验失败：习惯名为空。
  String get dialogHabitNameRequired;

  /// 校验失败：没选任何星期。
  String get dialogHabitWeekdayRequired;

  /// 习惯已落库但自动进计划失败（附带原始错误）。
  String dialogHabitSavedWarn(String error);

  /// 字段名：习惯名（必填）。
  String get dialogHabitNameLabel;

  /// 字段名：说明（可选）。
  String get dialogHabitNoteLabel;

  /// 小节名：排程。
  String get dialogHabitSchedule;

  /// 排程选项：每天。
  String get dialogHabitDaily;

  /// 排程选项：每隔 N 天。
  String get dialogHabitEveryDays;

  /// 排程选项：每隔 N 周。
  String get dialogHabitEveryWeeks;

  /// 排程选项：每周指定几天。
  String get dialogHabitWeeklyPick;

  /// 间隔行前缀：每隔。
  String get dialogHabitEvery;

  /// 小节名：星期。
  String get dialogHabitWeekday;

  /// 小节名：起始日期。
  String get dialogHabitStartDate;

  /// 小节名：每日至少完成。
  String get dialogHabitDailyMin;

  /// 面板标题：添加习惯。
  String get dialogHabitCreate;

  /// 面板副标题：排程与目标的说明。
  String get dialogHabitCreateSubtitle;

  // ---------------------------------------------------------------------------
  // 「手写一条」/「从待办池捞」面板（出处：`widgets\quick_todo_dialog.dart`）
  //
  // `dialogTodoTitleRequired` 与 `dialogTodoEstInvalid` 两句在 W7 的
  // `pages\todo_pool_page.dart` 里逐字同句出现 ⇒ 两波复用同一键，W7 不许另立。
  // ---------------------------------------------------------------------------

  /// 校验失败：标题为空（W7 `todo_pool_page` 复用）。
  String get dialogTodoTitleRequired;

  /// 校验失败：预估时间不是正数（W7 `todo_pool_page` 复用）。
  String get dialogTodoEstInvalid;

  /// 面板标题：手写一条。
  String get dialogTodoCreateTitle;

  /// 面板副标题：先存进待办池（夹带目标日期）。
  String dialogTodoCreateSubtitle(String target);

  /// 输入框占位：要做什么？
  String get dialogTodoTitleHint;

  /// 字段名：预估时间（可选）。
  String get dialogTodoEstLabel;

  /// 输入框占位：例如 25。
  String get dialogTodoEstHint;

  /// 字段名：优先级（可选）。
  String get dialogTodoPriorityLabel;

  /// 复选项：同时捞入今天。
  String get dialogTodoPullToday;

  /// 主按钮：保存中…。
  String get dialogTodoSaving;

  /// 面板标题：从待办池捞。
  String get dialogTodoPullTitle;

  /// 面板副标题：捞进目标日计划（夹带目标日期）。
  String dialogTodoPullSubtitle(String target);

  /// 空态：待办池是空的（短版）。
  String get dialogTodoPoolEmpty;

  /// 主按钮：捞入中…。
  String get dialogTodoPulling;

  /// 主按钮：捞入。
  String get dialogTodoPull;

  // ---------------------------------------------------------------------------
  // 「添加循环任务」面板（出处：`widgets\recurring_task_dialog.dart`）
  // ---------------------------------------------------------------------------

  /// 校验失败：没选任何星期。
  String get dialogRecurringWeekdayRequired;

  /// 校验失败：开始时刻格式不对。
  String get dialogRecurringTimeInvalid;

  /// 校验失败：时长越界。
  String get dialogRecurringDurationInvalid;

  /// 校验失败：选中日不是合法日历日。
  String dialogRecurringBadDate(String date);

  /// 提示：为了让规则今天就生效，已把今天并入重复日。
  String dialogRecurringMergedWeekday(String weekday);

  /// 提示：开始时刻早于时间轴下界，已夹到边界。
  String dialogRecurringTimeClamped(String boundary, String actual);

  /// 字段名：标题（必填）。
  String get dialogRecurringTitleLabel;

  /// 字段名：开始 HH:mm（06:00 起）。
  String get dialogRecurringStartLabel;

  /// 字段名：时长（分钟）。
  String get dialogRecurringDurationLabel;

  /// 字段名：备注（可选）。
  String get dialogRecurringNoteLabel;

  /// 主按钮：确认保存（上面有夹取提示时才用它）。
  String get dialogRecurringSaveConfirm;

  /// 面板标题：添加循环任务。
  String get dialogRecurringCreateTitle;

  /// 面板副标题：按星期与开始时刻自动排进计划。
  String get dialogRecurringCreateSubtitle;

  // ---------------------------------------------------------------------------
  // 右轨「循环任务」面板（出处：`widgets\recurring_rail_panel.dart`）
  // ---------------------------------------------------------------------------

  /// 规则动作（停用 / 启用 / 删除）失败（附带原始错误）。
  String dialogRuleActionFailed(String error);

  /// 确认框标题：删除循环任务。
  String get dialogRecurringDeleteTitle;

  /// 确认框正文：归档语义说明（夹带规则标题）。
  String dialogRecurringDeleteMessage(String title);

  /// 物化失败（附带原始错误）。
  String dialogAutoScheduleFailed(String error);

  /// 段落标题：规则。
  String get dialogRecurringSection;

  /// 读取中占位。
  String get dialogRecurringLoading;

  /// 规则列表读取失败（附带原始错误）。
  String dialogRecurringLoadFailed(String error);

  /// 空态：还没有循环规则。
  String get dialogRecurringNone;

  /// 空态提示：怎么添加一条。
  String get dialogRecurringNoneHint;

  /// 计数行：共 N 条规则。
  String dialogRecurringCount(int count);

  /// 掩码为 0 时的兜底显示（`每日`，与排程选项的 `每天` 不是同一句）。
  String get dialogRecurringDaily;

  /// 规则行摘要：星期 · 时长 · 状态。
  String dialogRecurringSummary(String weekday, int minutes, String status);

  /// 规则状态：启用中。
  String get dialogRuleActiveOn;

  /// 规则状态：已停用。
  String get dialogRuleActiveOff;

  /// 规则动作：停用。
  String get dialogRuleDisable;

  /// 规则动作：启用。
  String get dialogRuleEnable;

  // ---------------------------------------------------------------------------
  // 预估时长芯片（出处：`widgets\duration_chips.dart`）
  // ---------------------------------------------------------------------------

  /// 芯片：自定义…。
  String get dialogDurationCustom;

  /// 提示：自定义时长怎么输入（引用键条上的手写入口）。
  String get dialogDurationCustomHint;

  // ---------------------------------------------------------------------------
  // 结果撰写（出处：`widgets\outcome_composer.dart`）
  //
  // 注意：本组**只**收三段合成器的 UI 文案。`OutcomeComposer.outcomeLabels` /
  // `reasonLabels` / `nextStepLabels` 那 21 条芯片短语是**落库值**（`_setSegment`
  // 原样塞进 `ResultNote`，`:203` 还靠 `contains` 回显）—— **落库值的字面量不在
  // 本文件出现**，它们仍原样写在 `outcome_composer.dart` 的常量里。
  // ---------------------------------------------------------------------------

  /// 按钮：把未能解析的原文重新拆成三段。
  String get dialogNoteRestructure;

  /// `[下一步]` 自由文本框的标签（全角括号逐字保留）。
  String get dialogNoteNextStepLabel;

  /// 按钮：只存进展、不标记完成。
  String get dialogNoteSaveProgressOnly;

  /// 按钮：标记完成（是按钮，不是 `PlanStatus` 的「完成」标签）。
  String get dialogNoteDone;

  // ---------------------------------------------------------------------------
  // 结果撰写的三段短语（**显示层**；出处：`widgets\outcome_composer.dart:27-57`）
  //
  // 上一组说的是「落库值的字面量不落在这个文件里」；本组是这些短语的**同名显示
  // 文案键**：zh 侧与落库值逐字相同（中文界面零视觉变化），en 侧是译文。
  //
  // 落库值本身仍然一个字节都不改 —— 渲染点一律走
  // `OutcomeComposer.displayLabel(t, stored)`（按落库值查本组），历史数据里的
  // 未知短语原样返回，不猜译名。
  //
  // 「取消」复用 `CommonL10n.cancel`，本组不另立同义键（见文件头的复用纪律）。
  // ---------------------------------------------------------------------------

  /// 结论：按时完成。
  String get dialogOutcomeOnTime;

  /// 结论：延后完成。
  String get dialogOutcomeLate;

  /// 结论：提前完成。
  String get dialogOutcomeEarly;

  /// 结论：部分完成。
  String get dialogOutcomePartial;

  /// 结论：受阻。
  String get dialogOutcomeBlocked;

  /// 结论：顺延到明天。
  String get dialogOutcomeDeferredTomorrow;

  /// 原因：预估不足。
  String get dialogReasonUnderestimated;

  /// 原因：被打断。
  String get dialogReasonInterrupted;

  /// 原因：依赖外部。
  String get dialogReasonExternal;

  /// 原因：优先级变了。
  String get dialogReasonPriorityChanged;

  /// 原因：状态不好。
  String get dialogReasonPoorState;

  /// 原因：时间不够。
  String get dialogReasonNoTime;

  /// 原因：信息不清。
  String get dialogReasonUnclear;

  /// 原因：其他。
  String get dialogReasonOther;

  /// 下一步：明天继续。
  String get dialogNextStepContinueTomorrow;

  /// 下一步：转成待办。
  String get dialogNextStepToTodo;

  /// 下一步：交出去。
  String get dialogNextStepHandOff;

  /// 下一步：缩小范围。
  String get dialogNextStepNarrowScope;

  /// 下一步：定日复盘。
  String get dialogNextStepReviewLater;

  /// 下一步：就此停止。
  String get dialogNextStepStopHere;

  // ---------------------------------------------------------------------------
  // 待办池（出处：`pages\todo_pool_page.dart`）
  // ---------------------------------------------------------------------------

  /// 副标前半：池内待捞条数。
  String dialogPoolAvailable(int count);

  /// 副标前半的「加载中」占位。
  String get dialogPoolLoading;

  /// 副标：「条数 · 捞入 目标日」。
  String dialogPoolHead(String countLabel, String target);

  /// 页标题。
  String get dialogPoolTitle;

  /// 新建表单：标题输入框提示（必填）。
  String get dialogPoolTitleHint;

  /// 新建表单：起始时间输入框提示。
  String get dialogPoolStartHint;

  /// 新建表单：到期日输入框提示。
  String get dialogPoolDueHint;

  /// 新建表单：主按钮（全角 `＋` 是字形，不是文案）。
  String get dialogPoolNew;

  /// 表头：优先级列。
  String get dialogPoolColPriority;

  /// 表头：预估时长列。
  String get dialogPoolColEst;

  /// 表头：象限列。
  String get dialogPoolColQuadrant;

  /// 表头：到期日列。
  String get dialogPoolColDue;

  /// 表头：动作列。
  String get dialogPoolColAction;

  /// 起始时间格式非法时的行内错误。
  String get dialogPoolStartInvalid;

  /// 行内只读徽标：已排期 + 起始时刻。
  String dialogPoolScheduled(String time);

  /// 行内动作：加入主页计划。
  String get dialogPoolAddToToday;

  /// 空态长句（与手写面板的短版「待办池是空的」并存，两句不是同一条）。
  String get dialogPoolEmptyLong;
}

/// 对话框文案：简体中文。
mixin DialogZhL10n implements DialogL10n {
  @override
  String get dialogEstUnitMinute => '分钟';

  @override
  String get dialogEstUnitHour => '小时';

  @override
  String get dialogEstUnitDay => '日';

  @override
  String get dialogEstUnitWeek => '周';

  @override
  String get dialogEstUnitMonth => '月';

  /// 旧代码：`widgets\habit_quick_dialog.dart:169` —— `'习惯名不能为空'`。
  @override
  String get dialogHabitNameRequired => '习惯名不能为空';

  /// 旧代码：`widgets\habit_quick_dialog.dart:173` —— `'请至少选择一个星期'`。
  @override
  String get dialogHabitWeekdayRequired => '请至少选择一个星期';

  /// 旧代码：`widgets\habit_quick_dialog.dart:220` ——
  /// `'习惯已保存，但未能自动加入日计划：${_errorMessage(error)}'`。
  @override
  String dialogHabitSavedWarn(String error) => '习惯已保存，但未能自动加入日计划：$error';

  /// 旧代码：`widgets\habit_quick_dialog.dart:259` —— `'习惯名（必填）'`。
  @override
  String get dialogHabitNameLabel => '习惯名（必填）';

  /// 旧代码：`widgets\habit_quick_dialog.dart:268` —— `'说明（可选）'`。
  @override
  String get dialogHabitNoteLabel => '说明（可选）';

  /// 旧代码：`widgets\habit_quick_dialog.dart:319` —— `'排程'`。
  @override
  String get dialogHabitSchedule => '排程';

  /// 旧代码：`widgets\habit_quick_dialog.dart:328` —— `'每天'`。
  @override
  String get dialogHabitDaily => '每天';

  /// 旧代码：`widgets\habit_quick_dialog.dart:334` —— `'每隔 N 天'`。
  @override
  String get dialogHabitEveryDays => '每隔 N 天';

  /// 旧代码：`widgets\habit_quick_dialog.dart:341` —— `'每隔 N 周'`。
  @override
  String get dialogHabitEveryWeeks => '每隔 N 周';

  /// 旧代码：`widgets\habit_quick_dialog.dart:349` —— `'每周指定几天'`。
  @override
  String get dialogHabitWeeklyPick => '每周指定几天';

  /// 旧代码：`widgets\habit_quick_dialog.dart:371` —— `'每隔'`。
  @override
  String get dialogHabitEvery => '每隔';

  /// 旧代码：`widgets\habit_quick_dialog.dart:406` —— `'星期'`。
  /// 循环任务面板的同一句 `'星期'`（`:223`）复用它。
  @override
  String get dialogHabitWeekday => '星期';

  /// 旧代码：`widgets\habit_quick_dialog.dart:439` —— `'起始日期'`。
  @override
  String get dialogHabitStartDate => '起始日期';

  /// 旧代码：`widgets\habit_quick_dialog.dart:471` —— `'每日至少完成'`。
  @override
  String get dialogHabitDailyMin => '每日至少完成';

  /// 旧代码：`widgets\habit_quick_dialog.dart:534` —— `'添加习惯'`。
  @override
  String get dialogHabitCreate => '添加习惯';

  /// 旧代码：`widgets\habit_quick_dialog.dart:546` ——
  /// `'定义排程与目标，间隔型习惯保存后自动进入未来 14 天日计划'`。
  @override
  String get dialogHabitCreateSubtitle => '定义排程与目标，间隔型习惯保存后自动进入未来 14 天日计划';

  /// 旧代码：`widgets\quick_todo_dialog.dart:78` —— `'标题不能为空'`。
  @override
  String get dialogTodoTitleRequired => '标题不能为空';

  /// 旧代码：`widgets\quick_todo_dialog.dart:87` —— `'预估时间要填正数，或留空'`。
  @override
  String get dialogTodoEstInvalid => '预估时间要填正数，或留空';

  /// 旧代码：`widgets\quick_todo_dialog.dart:141` —— `'手写一条'`。
  @override
  String get dialogTodoCreateTitle => '手写一条';

  /// 旧代码：`widgets\quick_todo_dialog.dart:142` ——
  /// `'先存进待办池；勾选后同时落进 $target 的计划。'`。
  @override
  String dialogTodoCreateSubtitle(String target) => '先存进待办池；勾选后同时落进 $target 的计划。';

  /// 旧代码：`widgets\quick_todo_dialog.dart:154` —— `'要做什么？'`。
  @override
  String get dialogTodoTitleHint => '要做什么？';

  /// 旧代码：`widgets\quick_todo_dialog.dart:158` —— `'预估时间（可选）'`。
  @override
  String get dialogTodoEstLabel => '预估时间（可选）';

  /// 旧代码：`widgets\quick_todo_dialog.dart:175` —— `'例如 25'`。
  @override
  String get dialogTodoEstHint => '例如 25';

  /// 旧代码：`widgets\quick_todo_dialog.dart:191` —— `'优先级（可选）'`。
  @override
  String get dialogTodoPriorityLabel => '优先级（可选）';

  /// 旧代码：`widgets\quick_todo_dialog.dart:213` —— `'同时捞入今天'`。
  @override
  String get dialogTodoPullToday => '同时捞入今天';

  /// 旧代码：`widgets\quick_todo_dialog.dart:237` —— `'保存中…'`。
  @override
  String get dialogTodoSaving => '保存中…';

  /// 旧代码：`widgets\quick_todo_dialog.dart:305` —— `'从待办池捞'`。
  @override
  String get dialogTodoPullTitle => '从待办池捞';

  /// 旧代码：`widgets\quick_todo_dialog.dart:306` ——
  /// `'捞进 $target 的计划；待办池本身不会被删。'`。
  @override
  String dialogTodoPullSubtitle(String target) => '捞进 $target 的计划；待办池本身不会被删。';

  /// 旧代码：`widgets\quick_todo_dialog.dart:324` —— `'待办池是空的'`。
  @override
  String get dialogTodoPoolEmpty => '待办池是空的';

  /// 旧代码：`widgets\quick_todo_dialog.dart:431` —— `'捞入中…'`。
  @override
  String get dialogTodoPulling => '捞入中…';

  /// 旧代码：`widgets\quick_todo_dialog.dart:431` —— `'捞入'`。
  @override
  String get dialogTodoPull => '捞入';

  /// 旧代码：`widgets\recurring_task_dialog.dart:112` —— `'至少要选一个星期'`。
  @override
  String get dialogRecurringWeekdayRequired => '至少要选一个星期';

  /// 旧代码：`widgets\recurring_task_dialog.dart:117` ——
  /// `'开始时刻要写成 HH:mm（例如 09:00）'`。
  @override
  String get dialogRecurringTimeInvalid => '开始时刻要写成 HH:mm（例如 09:00）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:122` ——
  /// `'时长必须是 1..1440 之间的整数（分钟）'`。
  @override
  String get dialogRecurringDurationInvalid => '时长必须是 1..1440 之间的整数（分钟）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:129` ——
  /// `'选中日不是合法日历日：$date'`。
  @override
  String dialogRecurringBadDate(String date) => '选中日不是合法日历日：$date';

  /// 旧代码：`widgets\recurring_task_dialog.dart:141-142` ——
  /// `'已把 ${weekdayLabel(createdOn.weekday)} 并入重复日，' '以便今天就出现在计划里'`。
  @override
  String dialogRecurringMergedWeekday(String weekday) =>
      '已把 $weekday 并入重复日，以便今天就出现在计划里';

  /// 旧代码：`widgets\recurring_task_dialog.dart:150-151` ——
  /// `'开始时刻早于 ${formatMinuteOfDay(_timelineFirstMinute)}，' '已改到
  /// ${formatMinuteOfDay(startMinute)}（时间轴只显示 06:00 之后）'`。
  @override
  String dialogRecurringTimeClamped(String boundary, String actual) =>
      '开始时刻早于 $boundary，已改到 $actual（时间轴只显示 06:00 之后）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:217` —— `'标题（必填）'`。
  @override
  String get dialogRecurringTitleLabel => '标题（必填）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:254` —— `'开始 HH:mm（06:00 起）'`。
  @override
  String get dialogRecurringStartLabel => '开始 HH:mm（06:00 起）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:272` —— `'时长（分钟）'`。
  @override
  String get dialogRecurringDurationLabel => '时长（分钟）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:284` —— `'备注（可选）'`。
  @override
  String get dialogRecurringNoteLabel => '备注（可选）';

  /// 旧代码：`widgets\recurring_task_dialog.dart:308` —— `'确认保存'`。
  @override
  String get dialogRecurringSaveConfirm => '确认保存';

  /// 旧代码：`widgets\recurring_task_dialog.dart:402` —— `'添加循环任务'`。
  @override
  String get dialogRecurringCreateTitle => '添加循环任务';

  /// 旧代码：`widgets\recurring_task_dialog.dart:414` ——
  /// `'按星期与开始时刻，自动排进每一天的计划'`。
  @override
  String get dialogRecurringCreateSubtitle => '按星期与开始时刻，自动排进每一天的计划';

  /// 旧代码：`widgets\recurring_rail_panel.dart:64` —— `'规则操作失败：$error'`。
  @override
  String dialogRuleActionFailed(String error) => '规则操作失败：$error';

  /// 旧代码：`widgets\recurring_rail_panel.dart:103` —— `'删除循环任务'`。
  @override
  String get dialogRecurringDeleteTitle => '删除循环任务';

  /// 旧代码：`widgets\recurring_rail_panel.dart:104-105` ——
  /// `'「${rule.title}」将从循环任务列表中移除，之后不再自动排入计划；'
  /// '已经排入计划的条目会保留。'`。
  @override
  String dialogRecurringDeleteMessage(String title) =>
      '「$title」将从循环任务列表中移除，之后不再自动排入计划；已经排入计划的条目会保留。';

  /// 旧代码：`widgets\recurring_rail_panel.dart:125` —— `'自动排程失败：$error'`。
  @override
  String dialogAutoScheduleFailed(String error) => '自动排程失败：$error';

  /// 旧代码：`widgets\recurring_rail_panel.dart:132` —— `'规则'`。
  @override
  String get dialogRecurringSection => '规则';

  /// 旧代码：`widgets\recurring_rail_panel.dart:151` —— `'读取规则…'`。
  @override
  String get dialogRecurringLoading => '读取规则…';

  /// 旧代码：`widgets\recurring_rail_panel.dart:153` —— `'规则读取失败：$error'`。
  @override
  String dialogRecurringLoadFailed(String error) => '规则读取失败：$error';

  /// 旧代码：`widgets\recurring_rail_panel.dart:158` —— `'还没有循环规则'`。
  @override
  String get dialogRecurringNone => '还没有循环规则';

  /// 旧代码：`widgets\recurring_rail_panel.dart:159` —— `'点右上角 ＋ 添加一条'`。
  @override
  String get dialogRecurringNoneHint => '点右上角 ＋ 添加一条';

  /// 旧代码：`widgets\recurring_rail_panel.dart:174` ——
  /// `'共 ${rows.length} 条规则 · 命中日自动排入计划'`。
  @override
  String dialogRecurringCount(int count) => '共 $count 条规则 · 命中日自动排入计划';

  /// 旧代码：`widgets\recurring_rail_panel.dart:239` —— `'每日'`。
  ///
  /// 注意：与排程选项的 `'每天'`（`:328`）**不是同一句**，不能复用
  /// `dialogHabitDaily` —— 本波的口径是中文逐字不变。
  @override
  String get dialogRecurringDaily => '每日';

  /// 旧代码：`widgets\recurring_rail_panel.dart:267-268` ——
  /// `'$weekdayText · ${rule.durationMinutes} 分钟 · ${active ? '启用中' : '已停用'}'`。
  @override
  String dialogRecurringSummary(String weekday, int minutes, String status) =>
      '$weekday · $minutes 分钟 · $status';

  /// 旧代码：`widgets\recurring_rail_panel.dart:268` —— `'启用中'`。
  @override
  String get dialogRuleActiveOn => '启用中';

  /// 旧代码：`widgets\recurring_rail_panel.dart:268` —— `'已停用'`。
  @override
  String get dialogRuleActiveOff => '已停用';

  /// 旧代码：`widgets\recurring_rail_panel.dart:293` —— `'停用'`。
  @override
  String get dialogRuleDisable => '停用';

  /// 旧代码：`widgets\recurring_rail_panel.dart:293` —— `'启用'`。
  @override
  String get dialogRuleEnable => '启用';

  /// 旧代码：`widgets\duration_chips.dart:36` —— `'自定义…'`。
  @override
  String get dialogDurationCustom => '自定义…';

  /// 旧代码：`widgets\duration_chips.dart:50` ——
  /// `'自定义时长：点「+ 手写」里输入分钟数'`。
  @override
  String get dialogDurationCustomHint => '自定义时长：点「+ 手写」里输入分钟数';

  /// 旧代码：`widgets\outcome_composer.dart:154` —— `'重新结构化'`。
  @override
  String get dialogNoteRestructure => '重新结构化';

  /// 旧代码：`widgets\outcome_composer.dart:216` ——
  /// `'下一步（自由文本，仅此处可打字）'`（全角括号）。
  @override
  String get dialogNoteNextStepLabel => '下一步（自由文本，仅此处可打字）';

  /// 旧代码：`widgets\outcome_composer.dart:232` —— `'只存进展'`。
  @override
  String get dialogNoteSaveProgressOnly => '只存进展';

  /// 旧代码：`widgets\outcome_composer.dart:237` —— `'完成'`。
  @override
  String get dialogNoteDone => '完成';

  /// 旧代码：`widgets\outcome_composer.dart:28` —— `'按时完成'`（落库值，显示同形）。
  @override
  String get dialogOutcomeOnTime => '按时完成';

  /// 旧代码：`widgets\outcome_composer.dart:29` —— `'延后完成'`（落库值，显示同形）。
  @override
  String get dialogOutcomeLate => '延后完成';

  /// 旧代码：`widgets\outcome_composer.dart:30` —— `'提前完成'`（落库值，显示同形）。
  @override
  String get dialogOutcomeEarly => '提前完成';

  /// 旧代码：`widgets\outcome_composer.dart:31` —— `'部分完成'`（落库值，显示同形）。
  @override
  String get dialogOutcomePartial => '部分完成';

  /// 旧代码：`widgets\outcome_composer.dart:32` —— `'受阻'`（落库值，显示同形）。
  @override
  String get dialogOutcomeBlocked => '受阻';

  /// 旧代码：`widgets\outcome_composer.dart:33` —— `'顺延到明天'`（落库值，显示同形）。
  @override
  String get dialogOutcomeDeferredTomorrow => '顺延到明天';

  /// 旧代码：`widgets\outcome_composer.dart:39` —— `'预估不足'`（落库值，显示同形）。
  @override
  String get dialogReasonUnderestimated => '预估不足';

  /// 旧代码：`widgets\outcome_composer.dart:40` —— `'被打断'`（落库值，显示同形）。
  @override
  String get dialogReasonInterrupted => '被打断';

  /// 旧代码：`widgets\outcome_composer.dart:41` —— `'依赖外部'`（落库值，显示同形）。
  @override
  String get dialogReasonExternal => '依赖外部';

  /// 旧代码：`widgets\outcome_composer.dart:42` —— `'优先级变了'`（落库值，显示同形）。
  @override
  String get dialogReasonPriorityChanged => '优先级变了';

  /// 旧代码：`widgets\outcome_composer.dart:43` —— `'状态不好'`（落库值，显示同形）。
  @override
  String get dialogReasonPoorState => '状态不好';

  /// 旧代码：`widgets\outcome_composer.dart:44` —— `'时间不够'`（落库值，显示同形）。
  @override
  String get dialogReasonNoTime => '时间不够';

  /// 旧代码：`widgets\outcome_composer.dart:45` —— `'信息不清'`（落库值，显示同形）。
  @override
  String get dialogReasonUnclear => '信息不清';

  /// 旧代码：`widgets\outcome_composer.dart:46` —— `'其他'`（落库值，显示同形）。
  @override
  String get dialogReasonOther => '其他';

  /// 旧代码：`widgets\outcome_composer.dart:51` —— `'明天继续'`（落库值，显示同形）。
  @override
  String get dialogNextStepContinueTomorrow => '明天继续';

  /// 旧代码：`widgets\outcome_composer.dart:52` —— `'转成待办'`（落库值，显示同形）。
  @override
  String get dialogNextStepToTodo => '转成待办';

  /// 旧代码：`widgets\outcome_composer.dart:53` —— `'交出去'`（落库值，显示同形）。
  @override
  String get dialogNextStepHandOff => '交出去';

  /// 旧代码：`widgets\outcome_composer.dart:54` —— `'缩小范围'`（落库值，显示同形）。
  @override
  String get dialogNextStepNarrowScope => '缩小范围';

  /// 旧代码：`widgets\outcome_composer.dart:55` —— `'定日复盘'`（落库值，显示同形）。
  @override
  String get dialogNextStepReviewLater => '定日复盘';

  /// 旧代码：`widgets\outcome_composer.dart:56` —— `'就此停止'`（落库值，显示同形）。
  @override
  String get dialogNextStepStopHere => '就此停止';

  /// 旧代码：`pages\todo_pool_page.dart:78` —— `'${rows.length} 条待捞'`。
  @override
  String dialogPoolAvailable(int count) => '$count 条待捞';

  /// 旧代码：`pages\todo_pool_page.dart:79` —— `'加载中'`。
  @override
  String get dialogPoolLoading => '加载中';

  /// 旧代码：`pages\todo_pool_page.dart:89` —— `'$countLabel · 捞入 $target'`。
  @override
  String dialogPoolHead(String countLabel, String target) =>
      '$countLabel · 捞入 $target';

  /// 旧代码：`pages\todo_pool_page.dart:464` —— `'待办池'`。
  @override
  String get dialogPoolTitle => '待办池';

  /// 旧代码：`pages\todo_pool_page.dart:143` —— `'待办标题（必填）'`。
  @override
  String get dialogPoolTitleHint => '待办标题（必填）';

  /// 旧代码：`pages\todo_pool_page.dart:185` —— `'起始 09:15'`。
  @override
  String get dialogPoolStartHint => '起始 09:15';

  /// 旧代码：`pages\todo_pool_page.dart:194` —— `'到期 yyyy-MM-dd'`。
  @override
  String get dialogPoolDueHint => '到期 yyyy-MM-dd';

  /// 旧代码：`pages\todo_pool_page.dart:218` —— `'＋ 新建待办'`（全角 `＋`）。
  @override
  String get dialogPoolNew => '＋ 新建待办';

  /// 旧代码：`pages\todo_pool_page.dart:251` —— `'优先级'`。
  @override
  String get dialogPoolColPriority => '优先级';

  /// 旧代码：`pages\todo_pool_page.dart:252` —— `'预估'`。
  @override
  String get dialogPoolColEst => '预估';

  /// 旧代码：`pages\todo_pool_page.dart:253` —— `'象限'`。
  @override
  String get dialogPoolColQuadrant => '象限';

  /// 旧代码：`pages\todo_pool_page.dart:254` —— `'到期'`。
  @override
  String get dialogPoolColDue => '到期';

  /// 旧代码：`pages\todo_pool_page.dart:255` —— `'动作'`。
  @override
  String get dialogPoolColAction => '动作';

  /// 旧代码：`pages\todo_pool_page.dart:317` ——
  /// `'起始时间要填 HH:mm，或留空'`。
  @override
  String get dialogPoolStartInvalid => '起始时间要填 HH:mm，或留空';

  /// 旧代码：`pages\todo_pool_page.dart:266` ——
  /// `'已排期 ${formatMinute(...)}'`。
  @override
  String dialogPoolScheduled(String time) => '已排期 $time';

  /// 旧代码：`pages\todo_pool_page.dart:578` —— `'加入主页计划'`。
  @override
  String get dialogPoolAddToToday => '加入主页计划';

  /// 旧代码：`pages\todo_pool_page.dart:608` ——
  /// `'待办池是空的：先在上面新建一条，再捞到选中日。'`。
  @override
  String get dialogPoolEmptyLong => '待办池是空的：先在上面新建一条，再捞到选中日。';
}

/// 对话框文案：English。
mixin DialogEnL10n implements DialogL10n {
  @override
  String get dialogEstUnitMinute => 'min';

  @override
  String get dialogEstUnitHour => 'hr';

  @override
  String get dialogEstUnitDay => 'day';

  @override
  String get dialogEstUnitWeek => 'wk';

  @override
  String get dialogEstUnitMonth => 'mo';

  @override
  String get dialogHabitNameRequired => 'Habit name is required';

  @override
  String get dialogHabitWeekdayRequired => 'Pick at least one weekday';

  @override
  String dialogHabitSavedWarn(String error) =>
      'Habit saved, but it could not be added to the plan: $error';

  @override
  String get dialogHabitNameLabel => 'Habit name (required)';

  @override
  String get dialogHabitNoteLabel => 'Note (optional)';

  @override
  String get dialogHabitSchedule => 'Schedule';

  @override
  String get dialogHabitDaily => 'Every day';

  @override
  String get dialogHabitEveryDays => 'Every N days';

  @override
  String get dialogHabitEveryWeeks => 'Every N weeks';

  @override
  String get dialogHabitWeeklyPick => 'Specific weekdays';

  @override
  String get dialogHabitEvery => 'Every';

  @override
  String get dialogHabitWeekday => 'Weekday';

  @override
  String get dialogHabitStartDate => 'Start date';

  @override
  String get dialogHabitDailyMin => 'Minimum per day';

  @override
  String get dialogHabitCreate => 'Add habit';

  @override
  String get dialogHabitCreateSubtitle =>
      'Define schedule and target; interval habits enter the next 14 days automatically';

  @override
  String get dialogTodoTitleRequired => 'Title is required';

  @override
  String get dialogTodoEstInvalid => 'Estimate must be a positive number, or left blank';

  @override
  String get dialogTodoCreateTitle => 'Write a todo';

  @override
  String dialogTodoCreateSubtitle(String target) =>
      'Saved to the pool first; ticking also drops it into the $target plan.';

  @override
  String get dialogTodoTitleHint => 'What to do?';

  @override
  String get dialogTodoEstLabel => 'Estimate (optional)';

  @override
  String get dialogTodoEstHint => 'e.g. 25';

  @override
  String get dialogTodoPriorityLabel => 'Priority (optional)';

  @override
  String get dialogTodoPullToday => 'Also pull into today';

  @override
  String get dialogTodoSaving => 'Saving…';

  @override
  String get dialogTodoPullTitle => 'Pull from the pool';

  @override
  String dialogTodoPullSubtitle(String target) =>
      'Pulled into the $target plan; the pool entry stays.';

  @override
  String get dialogTodoPoolEmpty => 'The pool is empty';

  @override
  String get dialogTodoPulling => 'Pulling…';

  @override
  String get dialogTodoPull => 'Pull in';

  @override
  String get dialogRecurringWeekdayRequired => 'Pick at least one weekday';

  @override
  String get dialogRecurringTimeInvalid => 'Start time must be HH:mm (e.g. 09:00)';

  @override
  String get dialogRecurringDurationInvalid =>
      'Duration must be an integer in 1..1440 (minutes)';

  @override
  String dialogRecurringBadDate(String date) =>
      'The selected day is not a valid calendar date: $date';

  @override
  String dialogRecurringMergedWeekday(String weekday) =>
      '$weekday was merged into the repeat days so it shows up today';

  @override
  String dialogRecurringTimeClamped(String boundary, String actual) =>
      'Start time was before $boundary, moved to $actual (the timeline only shows after 06:00)';

  @override
  String get dialogRecurringTitleLabel => 'Title (required)';

  @override
  String get dialogRecurringStartLabel => 'Start HH:mm (from 06:00)';

  @override
  String get dialogRecurringDurationLabel => 'Duration (minutes)';

  @override
  String get dialogRecurringNoteLabel => 'Note (optional)';

  @override
  String get dialogRecurringSaveConfirm => 'Confirm save';

  @override
  String get dialogRecurringCreateTitle => 'Add recurring task';

  @override
  String get dialogRecurringCreateSubtitle =>
      'Scheduled into each day by weekday and start time';

  @override
  String dialogRuleActionFailed(String error) => 'Rule action failed: $error';

  @override
  String get dialogRecurringDeleteTitle => 'Delete recurring task';

  @override
  String dialogRecurringDeleteMessage(String title) =>
      '“$title” will be removed from recurring tasks and no longer auto-scheduled; '
      'items already scheduled stay.';

  @override
  String dialogAutoScheduleFailed(String error) => 'Auto-scheduling failed: $error';

  @override
  String get dialogRecurringSection => 'Rules';

  @override
  String get dialogRecurringLoading => 'Loading rules…';

  @override
  String dialogRecurringLoadFailed(String error) => 'Failed to load rules: $error';

  @override
  String get dialogRecurringNone => 'No recurring rule yet';

  @override
  String get dialogRecurringNoneHint => 'Use ＋ at the top right to add one';

  @override
  String dialogRecurringCount(int count) =>
      '$count rule(s) · auto-scheduled on matching days';

  @override
  String get dialogRecurringDaily => 'Daily';

  @override
  String dialogRecurringSummary(String weekday, int minutes, String status) =>
      '$weekday · $minutes min · $status';

  @override
  String get dialogRuleActiveOn => 'Enabled';

  @override
  String get dialogRuleActiveOff => 'Disabled';

  @override
  String get dialogRuleDisable => 'Disable';

  @override
  String get dialogRuleEnable => 'Enable';

  @override
  String get dialogDurationCustom => 'Custom…';

  @override
  String get dialogDurationCustomHint => 'Custom duration: enter the minutes in "+ Write one"';

  @override
  String get dialogNoteRestructure => 'Re-structure';

  @override
  String get dialogNoteNextStepLabel => 'Next step (free text, only editable here)';

  @override
  String get dialogNoteSaveProgressOnly => 'Save progress only';

  @override
  String get dialogNoteDone => 'Done';

  @override
  String get dialogOutcomeOnTime => 'Completed on time';

  @override
  String get dialogOutcomeLate => 'Completed late';

  @override
  String get dialogOutcomeEarly => 'Completed early';

  @override
  String get dialogOutcomePartial => 'Partially completed';

  @override
  String get dialogOutcomeBlocked => 'Blocked';

  @override
  String get dialogOutcomeDeferredTomorrow => 'Deferred to tomorrow';

  @override
  String get dialogReasonUnderestimated => 'Underestimated';

  @override
  String get dialogReasonInterrupted => 'Interrupted';

  @override
  String get dialogReasonExternal => 'Depends on external input';

  @override
  String get dialogReasonPriorityChanged => 'Priority changed';

  @override
  String get dialogReasonPoorState => 'Poor condition';

  @override
  String get dialogReasonNoTime => 'Not enough time';

  @override
  String get dialogReasonUnclear => 'Information unclear';

  @override
  String get dialogReasonOther => 'Other';

  @override
  String get dialogNextStepContinueTomorrow => 'Continue tomorrow';

  @override
  String get dialogNextStepToTodo => 'Convert to a to-do';

  @override
  String get dialogNextStepHandOff => 'Hand off';

  @override
  String get dialogNextStepNarrowScope => 'Narrow the scope';

  @override
  String get dialogNextStepReviewLater => 'Review on a set date';

  @override
  String get dialogNextStepStopHere => 'Stop here';

  @override
  String dialogPoolAvailable(int count) => '$count to pull';

  @override
  String get dialogPoolLoading => 'Loading';

  @override
  String dialogPoolHead(String countLabel, String target) =>
      '$countLabel · pull into $target';

  @override
  String get dialogPoolTitle => 'Todo pool';

  @override
  String get dialogPoolTitleHint => 'Todo title (required)';

  @override
  String get dialogPoolStartHint => 'Start 09:15';

  @override
  String get dialogPoolDueHint => 'Due yyyy-MM-dd';

  @override
  String get dialogPoolNew => '＋ New todo';

  @override
  String get dialogPoolColPriority => 'Priority';

  @override
  String get dialogPoolColEst => 'Est.';

  @override
  String get dialogPoolColQuadrant => 'Quadrant';

  @override
  String get dialogPoolColDue => 'Due';

  @override
  String get dialogPoolColAction => 'Action';

  @override
  String get dialogPoolStartInvalid => 'Start time must be HH:mm, or left blank';

  @override
  String dialogPoolScheduled(String time) => 'Scheduled $time';

  @override
  String get dialogPoolAddToToday => 'Add to today’s plan';

  @override
  String get dialogPoolEmptyLong =>
      'The pool is empty: create one above, then pull it into the selected day.';
}