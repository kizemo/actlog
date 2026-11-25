// =============================================================================
// l10n part：应用外壳（导航 / 快捷键 / 右轨面板，Task 61）
// =============================================================================
// 一个 part = 一个模块的「接口 + 中英两态实现」。形状照 `parts\settings.dart`：
//  1. `ShellL10n` 只声明 getter，不带任何实现；
//  2. `ShellZhL10n` / `ShellEnL10n` 用 `mixin` 实现接口，`@override` 必须齐全；
//  3. 聚合在 `app_localizations.dart`：zh / en 两个子类各混一个 mixin。
//
// 本 part 只收**外壳自己**的文案：左导航 6 项、导航底注「页面切换」、快捷键面板
// 标题与 8 条快捷键说明、右轨 4 个面板的 7 条标题/按钮文案。
//
// 品牌标题（知行日志 / actlog）**不新增 getter** —— 复用 `parts\about.dart` 里
// 既有的 `appName`（zh `知行日志` / en `actlog`）。
//
// 中文取值与迁入前的 UI 字面量**逐字一致**（含全角 `＋` 与斜杠两侧的空格），
// 所以中文界面的渲染结果不变。
// =============================================================================

/// 应用外壳文案。
abstract class ShellL10n {
  // --- 左导航 6 项 -----------------------------------------------------------

  /// 左导航：日志。
  String get shellNavToday;

  /// 左导航：待办池。
  String get shellNavInbox;

  /// 左导航：习惯。
  String get shellNavHabits;

  /// 左导航：项目。
  String get shellNavProjects;

  /// 左导航：日历。
  String get shellNavCalendar;

  /// 左导航：设置。
  String get shellNavSettings;

  /// 左导航：目标。
  ///
  /// Task 64 起「设置」沉底成齿轮（左栏项数仍是 6），第 6 项换成「目标」。
  String get shellNavGoals;

  // --- 面板标题 / 导航底注 ---------------------------------------------------

  /// 右轨「快捷键」面板标题。
  String get shellShortcutsTitle;

  /// 导航底注：页面切换。
  String get shellPageSwitch;

  // --- 快捷键说明 8 条 -------------------------------------------------------

  /// 快捷键：＋ 手写一条。
  String get shellKeyAddEntry;

  /// 快捷键：打卡第一条未打习惯。
  String get shellKeyCheckFirstHabit;

  /// 快捷键：切日期。
  String get shellKeySwitchDate;

  /// 快捷键：勾选 / 取消勾选。
  String get shellKeyToggleCheck;

  /// 快捷键：展开回填。
  String get shellKeyExpandBackfill;

  /// 快捷键：关闭弹层。
  String get shellKeyClosePopup;

  /// 快捷键：切页。
  String get shellKeySwitchTab;

  /// 快捷键：切到项目。
  String get shellKeyGoProjects;

  /// 快捷键：切到目标。
  String get shellKeyGoGoals;

  // --- 右轨 4 个面板的 7 条文案 ----------------------------------------------

  /// 右轨面板：待办列表。
  String get shellPanelTodoList;

  /// 右轨面板：添加待办。
  String get shellPanelAddTodo;

  /// 右轨面板：习惯速览。
  String get shellPanelHabitOverview;

  /// 右轨面板：添加习惯。
  String get shellPanelAddHabit;

  /// 右轨面板：循环任务。
  String get shellPanelRecurringTasks;

  /// 右轨面板：添加循环任务。
  String get shellPanelAddRecurringTask;

  /// 右轨面板：闭环提示。
  String get shellPanelLoopHint;
}

/// 应用外壳文案：简体中文。
mixin ShellZhL10n implements ShellL10n {
  @override
  String get shellNavToday => '日志';

  @override
  String get shellNavInbox => '待办池';

  @override
  String get shellNavHabits => '习惯';

  @override
  String get shellNavProjects => '项目';

  @override
  String get shellNavCalendar => '日历';

  @override
  String get shellNavSettings => '设置';

  @override
  String get shellNavGoals => '目标';

  @override
  String get shellShortcutsTitle => '快捷键';

  @override
  String get shellPageSwitch => '页面切换';

  @override
  String get shellKeyAddEntry => '＋ 手写一条';

  @override
  String get shellKeyCheckFirstHabit => '打卡第一条未打习惯';

  @override
  String get shellKeySwitchDate => '切日期';

  @override
  String get shellKeyToggleCheck => '勾选 / 取消勾选';

  @override
  String get shellKeyExpandBackfill => '展开回填';

  @override
  String get shellKeyClosePopup => '关闭弹层';

  @override
  String get shellKeySwitchTab => '切页';

  @override
  String get shellKeyGoProjects => '切到项目';

  @override
  String get shellKeyGoGoals => '切到目标';

  @override
  String get shellPanelTodoList => '待办列表';

  @override
  String get shellPanelAddTodo => '添加待办';

  @override
  String get shellPanelHabitOverview => '习惯速览';

  @override
  String get shellPanelAddHabit => '添加习惯';

  @override
  String get shellPanelRecurringTasks => '循环任务';

  @override
  String get shellPanelAddRecurringTask => '添加循环任务';

  @override
  String get shellPanelLoopHint => '闭环提示';
}

/// 应用外壳文案：English。
mixin ShellEnL10n implements ShellL10n {
  @override
  String get shellNavToday => 'Journal';

  @override
  String get shellNavInbox => 'To-do Pool';

  @override
  String get shellNavHabits => 'Habits';

  @override
  String get shellNavProjects => 'Projects';

  @override
  String get shellNavCalendar => 'Calendar';

  @override
  String get shellNavSettings => 'Settings';

  @override
  String get shellNavGoals => 'Goals';

  @override
  String get shellShortcutsTitle => 'Shortcuts';

  @override
  String get shellPageSwitch => 'Page switch';

  @override
  String get shellKeyAddEntry => '+ Add an entry';

  @override
  String get shellKeyCheckFirstHabit => 'Check the first unchecked habit';

  @override
  String get shellKeySwitchDate => 'Switch date';

  @override
  String get shellKeyToggleCheck => 'Check / uncheck';

  @override
  String get shellKeyExpandBackfill => 'Expand backfill';

  @override
  String get shellKeyClosePopup => 'Close popup';

  @override
  String get shellKeySwitchTab => 'Switch tab';

  @override
  String get shellKeyGoProjects => 'Go to Projects';

  @override
  String get shellKeyGoGoals => 'Go to Goals';

  @override
  String get shellPanelTodoList => 'To-do list';

  @override
  String get shellPanelAddTodo => 'Add to-do';

  @override
  String get shellPanelHabitOverview => 'Habit overview';

  @override
  String get shellPanelAddHabit => 'Add habit';

  @override
  String get shellPanelRecurringTasks => 'Recurring tasks';

  @override
  String get shellPanelAddRecurringTask => 'Add recurring task';

  @override
  String get shellPanelLoopHint => 'Loop hint';
}
