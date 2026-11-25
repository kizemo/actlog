// =============================================================================
// 文案键表：camelCase getter 名 ↔ kebab-case 稳定键
// =============================================================================
// 这层**不做转发**。它不进渲染路径 —— 页面上仍然写 `t.settingsTitle`，编译器
// 仍然保证漏翻是 error。键的作用只有两个：
//   1. 测试能遍历 key 集合，校验「445 条 getter 一条不少」「中英两态都不为空」
//      「除白名单外中英必须不同」；
//   2. 将来若要把文案导出成 ARB / 交给翻译工具，键名是稳定的对接面，不必从
//      Dart 标识符里反推。
//
// 为什么 kebab-case 而不是直接复用 camelCase：键是要交给外部工具与人看的，
// `settingsLaunchOnBootHint` 这种长驼峰在表格里难读；中间横线也更像业界惯例
// （ARB / Flutter gen_l10n 的 key 习惯）。
//
// 加键的规矩：新增 getter 必须同时在这里登记 + 在 `byGetter` 里加一行，
// 否则 `test\l10n_base_test.dart` 的「键数与 getter 数一致」会红。
// =============================================================================

/// 文案键常量（kebab-case）与「Dart 名字 → 键」对照表。
abstract final class L10nKeys {
  // ---------------------------------------------------------------------------
  // 设置页（parts\settings.dart，32 条）
  // ---------------------------------------------------------------------------

  /// 设置页标题。
  static const String settingsTitle = 'settings-title';

  /// 设置页副标题。
  static const String settingsSubtitle = 'settings-subtitle';

  /// 分组：外观。
  static const String settingsSectionAppearance = 'settings-section-appearance';

  /// 主题：跟随系统。
  static const String settingsThemeSystem = 'settings-theme-system';

  /// 主题：浅色。
  static const String settingsThemeLight = 'settings-theme-light';

  /// 主题：深色。
  static const String settingsThemeDark = 'settings-theme-dark';

  /// 分组：语言。
  static const String settingsSectionLanguage = 'settings-section-language';

  /// 语言：简体中文。
  static const String settingsLanguageZh = 'settings-language-zh';

  /// 语言：English。
  static const String settingsLanguageEn = 'settings-language-en';

  /// 分组：系统集成。
  static const String settingsSectionSystem = 'settings-section-system';

  /// 开机启动。
  static const String settingsLaunchOnBoot = 'settings-launch-on-boot';

  /// 开机启动说明。
  static const String settingsLaunchOnBootHint = 'settings-launch-on-boot-hint';

  /// 创建桌面快捷方式。
  static const String settingsDesktopShortcut = 'settings-desktop-shortcut';

  /// 创建桌面快捷方式说明。
  static const String settingsDesktopShortcutHint =
      'settings-desktop-shortcut-hint';

  /// 快捷方式创建成功。
  static const String settingsShortcutCreated = 'settings-shortcut-created';

  /// 分组：每天计划起止时间。
  static const String settingsSectionPlanWindow = 'settings-section-plan-window';

  /// 起点。
  static const String settingsPlanStart = 'settings-plan-start';

  /// 终点。
  static const String settingsPlanEnd = 'settings-plan-end';

  /// 起止时间说明。
  static const String settingsPlanWindowHint = 'settings-plan-window-hint';

  /// 分组：其它。
  static const String settingsSectionOther = 'settings-section-other';

  /// 界面密度。
  static const String settingsDensity = 'settings-density';

  /// 密度：紧凑。
  static const String settingsDensityCompact = 'settings-density-compact';

  /// 密度：舒适。
  static const String settingsDensityComfortable = 'settings-density-comfortable';

  /// 密度：宽松。
  static const String settingsDensityRoomy = 'settings-density-roomy';

  /// 优先级显示方式。
  static const String settingsPriorityDisplayMode =
      'settings-priority-display-mode';

  /// 优先级显示：四象限。
  static const String settingsPriorityQuadrant = 'settings-priority-quadrant';

  /// 优先级显示：ABC 分级。
  static const String settingsPriorityAbc = 'settings-priority-abc';

  /// 恢复默认设置。
  static const String settingsReset = 'settings-reset';

  /// 恢复默认设置的确认问句。
  static const String settingsResetConfirm = 'settings-reset-confirm';

  /// 恢复默认设置说明。
  static const String settingsResetHint = 'settings-reset-hint';

  /// 已恢复默认。
  static const String settingsResetDone = 'settings-reset-done';

  /// 设置页底部说明。
  static const String settingsFootnote = 'settings-footnote';

  // ---------------------------------------------------------------------------
  // 关于页（parts\about.dart，28 条：19 条原文 + 9 条正文/列表）
  // ---------------------------------------------------------------------------

  /// 关于页标题。
  static const String aboutTitle = 'about-title';

  /// 产品简介。
  static const String aboutIntro = 'about-intro';

  /// 分组：版本。
  static const String aboutSectionVersion = 'about-section-version';

  /// 版本标签。
  static const String aboutVersionLabel = 'about-version-label';

  /// 检查新版本。
  static const String aboutCheckUpdate = 'about-check-update';

  /// 检查中。
  static const String aboutChecking = 'about-checking';

  /// 暂无可用发布版本。
  static const String aboutNoRelease = 'about-no-release';

  /// 网络不可用。
  static const String aboutNetworkError = 'about-network-error';

  /// 已是最新。
  static const String aboutUpToDate = 'about-up-to-date';

  /// 有新版本。
  static const String aboutNewVersion = 'about-new-version';

  /// 在线升级。
  static const String aboutOnlineUpgrade = 'about-online-upgrade';

  /// 在线升级被禁用的原因。
  static const String aboutOnlineUpgradeDisabled =
      'about-online-upgrade-disabled';

  /// 分组：仓库。
  static const String aboutSectionRepository = 'about-section-repository';

  /// 分组：开发者。
  static const String aboutSectionDeveloper = 'about-section-developer';

  /// 开发者简介。
  static const String aboutDeveloperIntro = 'about-developer-intro';

  /// 分组：其它软件。
  static const String aboutSectionOtherSoftware =
      'about-section-other-software';

  /// Alpha File Manager 一句话说明。
  static const String aboutAlphaFileManager = 'about-alpha-file-manager';

  /// PageWeaver 一句话说明。
  static const String aboutPageWeaver = 'about-page-weaver';

  /// 「仓库地址待核实」标注。
  static const String aboutUnverifiedLink = 'about-unverified-link';

  /// 关于页目录（列表型 getter）。
  static const String aboutToc = 'about-toc';

  /// 分组：最近变更。
  static const String aboutChangelogTitle = 'about-changelog-title';

  /// 最近变更条目（列表型 getter）。
  static const String aboutChangelog = 'about-changelog';

  /// 分组：数据与隐私。
  static const String aboutPrivacyTitle = 'about-privacy-title';

  /// 数据与隐私正文。
  static const String aboutPrivacy = 'about-privacy';

  /// 分组：许可证。
  static const String aboutLicensesTitle = 'about-licenses-title';

  /// 许可证正文。
  static const String aboutLicenses = 'about-licenses';

  /// 复制结果按钮。
  static const String aboutCopyResult = 'about-copy-result';

  /// 打开发布页按钮。
  static const String aboutReleases = 'about-releases';

  // ---------------------------------------------------------------------------
  // 外壳（窗口标题 / 顶栏 / 托盘，9 条；暂寄 parts\about.dart —— Task 61 的
  // parts\shell.dart 已立项，但这 9 条本轮**未**迁过去）
  // ---------------------------------------------------------------------------

  /// 窗口标题（含英文标识）。
  static const String shellAppTitle = 'shell-app-title';

  /// 应用名（只中文/只英文，不含标识）。
  static const String shellAppName = 'shell-app-name';

  /// 顶栏：最小化。
  static const String shellWindowMinimize = 'shell-window-minimize';

  /// 顶栏：最大化。
  static const String shellWindowMaximize = 'shell-window-maximize';

  /// 顶栏：还原。
  static const String shellWindowRestore = 'shell-window-restore';

  /// 顶栏：关闭。
  static const String shellWindowClose = 'shell-window-close';

  /// 托盘菜单：显示窗口。
  static const String shellTrayShow = 'shell-tray-show';

  /// 托盘菜单：隐藏到托盘。
  static const String shellTrayHide = 'shell-tray-hide';

  /// 托盘菜单：退出。
  static const String shellTrayQuit = 'shell-tray-quit';

  // ---------------------------------------------------------------------------
  // 应用外壳（parts\shell.dart，23 条：左导航 6 项 / 快捷键面板与 8 条快捷键说明 /
  // 导航底注「页面切换」/ 右轨 4 个面板的 7 条文案）
  // ---------------------------------------------------------------------------

  /// 左导航：日志。
  static const String shellNavToday = 'shell-nav-today';

  /// 左导航：待办池。
  static const String shellNavInbox = 'shell-nav-inbox';

  /// 左导航：习惯。
  static const String shellNavHabits = 'shell-nav-habits';

  /// 左导航：项目。
  static const String shellNavProjects = 'shell-nav-projects';

  /// 左导航：日历。
  static const String shellNavCalendar = 'shell-nav-calendar';

  /// 左导航：设置。
  static const String shellNavSettings = 'shell-nav-settings';

  /// 左导航：目标（Task 64：第 6 项由「设置」换成「目标」）。
  static const String shellNavGoals = 'shell-nav-goals';

  /// 左导航：蓝图（Task 72 / D-72-b：第 7 个导航项）。
  static const String shellNavBlueprint = 'shell-nav-blueprint';

  /// 左导航：蓝图（快捷键说明口径）。
  static const String shellNavBlueprintDesc = 'shell-nav-blueprint-desc';

  /// 右轨「快捷键」面板标题。
  static const String shellShortcutsTitle = 'shell-shortcuts-title';

  /// 导航底注：页面切换。
  static const String shellPageSwitch = 'shell-page-switch';

  /// 快捷键：＋ 手写一条。
  static const String shellKeyAddEntry = 'shell-key-add-entry';

  /// 快捷键：打卡第一条未打习惯。
  static const String shellKeyCheckFirstHabit = 'shell-key-check-first-habit';

  /// 快捷键：切日期。
  static const String shellKeySwitchDate = 'shell-key-switch-date';

  /// 快捷键：勾选 / 取消勾选。
  static const String shellKeyToggleCheck = 'shell-key-toggle-check';

  /// 快捷键：展开回填。
  static const String shellKeyExpandBackfill = 'shell-key-expand-backfill';

  /// 快捷键：关闭弹层。
  static const String shellKeyClosePopup = 'shell-key-close-popup';

  /// 快捷键：切页。
  static const String shellKeySwitchTab = 'shell-key-switch-tab';

  /// 快捷键：切到项目。
  static const String shellKeyGoProjects = 'shell-key-go-projects';

  /// 快捷键：切到目标（Task 65 UI 半批：Ctrl+6）。
  static const String shellKeyGoGoals = 'shell-key-go-goals';

  /// 右轨面板：待办列表。
  static const String shellPanelTodoList = 'shell-panel-todo-list';

  /// 右轨面板：添加待办。
  static const String shellPanelAddTodo = 'shell-panel-add-todo';

  /// 右轨面板：习惯速览。
  static const String shellPanelHabitOverview = 'shell-panel-habit-overview';

  /// 右轨面板：添加习惯。
  static const String shellPanelAddHabit = 'shell-panel-add-habit';

  /// 右轨面板：循环任务。
  static const String shellPanelRecurringTasks = 'shell-panel-recurring-tasks';

  /// 右轨面板：添加循环任务。
  static const String shellPanelAddRecurringTask =
      'shell-panel-add-recurring-task';

  /// 右轨面板：闭环提示。
  static const String shellPanelLoopHint = 'shell-panel-loop-hint';

  // ---------------------------------------------------------------------------
  // 跨页共用（parts\common.dart，20 条）
  // ---------------------------------------------------------------------------

  /// 取消。
  static const String commonCancel = 'common-cancel';

  /// 确认。
  static const String commonConfirm = 'common-confirm';

  /// 当前程序路径。
  static const String commonExecutablePath = 'common-executable-path';

  /// 操作失败。
  static const String commonOperationFailed = 'common-operation-failed';

  /// 复制。
  static const String commonCopy = 'common-copy';

  /// 已复制。
  static const String commonCopied = 'common-copied';

  /// 打开。
  static const String commonOpen = 'common-open';

  // Task 63 轮二 16 条：二元取值 / 动作 / 优先级轴 / 单位

  /// 标题（表单字段名 / 分组标题）。
  static const String commonTitle = 'common-title';

  /// 保存（表单主按钮）。
  static const String commonSave = 'common-save';

  /// 删除（破坏性动作按钮）。
  static const String commonDelete = 'common-delete';

  /// 关闭（关掉浮层 / 对话框的按钮，不是关窗口）。
  static const String commonClose = 'common-close';

  /// 清除（把已分级打回未分级 / 清空选择）。
  static const String commonClear = 'common-clear';

  /// 清除优先级（完整措辞，用于芯片与提示文案）。
  static const String commonClearPriority = 'common-clear-priority';

  /// 优先级轴：重要。
  static const String commonAxisImportant = 'common-axis-important';

  /// 优先级轴：不重要。
  static const String commonAxisNotImportant = 'common-axis-not-important';

  /// 优先级轴：紧急。
  static const String commonAxisUrgent = 'common-axis-urgent';

  /// 优先级轴：不紧急。
  static const String commonAxisNotUrgent = 'common-axis-not-urgent';

  /// 次数单位（显示层用；落库值 `次` 不随语言变）。
  static const String commonUnitTimes = 'common-unit-times';

  /// 天数单位。
  static const String commonUnitDay = 'common-unit-day';

  /// 周数单位。
  static const String commonUnitWeek = 'common-unit-week';

  // ---------------------------------------------------------------------------
  // 插值方法（parts\domain.dart，4 条；不是 getter，单列一张表）
  // ---------------------------------------------------------------------------

  /// 时长：N 小时。
  static const String domainHoursCount = 'domain-hours-count';

  /// 时长：N 分钟。
  static const String domainMinutesCount = 'domain-minutes-count';

  /// 已顺延 N 天。
  static const String domainDeferredDays = 'domain-deferred-days';

  /// 心态维度分值标签。
  static const String domainMoodScoreLabel = 'domain-mood-score-label';

  // ---------------------------------------------------------------------------
  // 优先级展示文案（parts\domain.dart，12 条 getter；W0.5 域层 id 化）
  // ---------------------------------------------------------------------------
  // 这 12 条的中文取值与 `packages\core_data\lib\src\priority.dart` 里
  // `QuadrantStyle` / `AbcStyle` / `PriorityDisplay` 的旧常量**逐字一致**（由
  // `test\l10n_base_test.dart` 的「id ↔ l10n 对齐」用例守着）。包层出 id，UI 侧
  // 查这张表拿到当前语言的文案。

  /// 象限全名：Q1。
  static const String domainQuadrantQ1Label = 'domain-quadrant-q1-label';

  /// 象限短名：Q1。
  static const String domainQuadrantQ1ShortLabel =
      'domain-quadrant-q1-short-label';

  /// 象限全名：Q2。
  static const String domainQuadrantQ2Label = 'domain-quadrant-q2-label';

  /// 象限短名：Q2。
  static const String domainQuadrantQ2ShortLabel =
      'domain-quadrant-q2-short-label';

  /// 象限全名：Q3。
  static const String domainQuadrantQ3Label = 'domain-quadrant-q3-label';

  /// 象限短名：Q3。
  static const String domainQuadrantQ3ShortLabel =
      'domain-quadrant-q3-short-label';

  /// 象限全名：Q4。
  static const String domainQuadrantQ4Label = 'domain-quadrant-q4-label';

  /// 象限短名：Q4。
  static const String domainQuadrantQ4ShortLabel =
      'domain-quadrant-q4-short-label';

  /// A 级标签。
  static const String domainAbcALabel = 'domain-abc-a-label';

  /// B 级标签。
  static const String domainAbcBLabel = 'domain-abc-b-label';

  /// C 级标签。
  static const String domainAbcCLabel = 'domain-abc-c-label';

  /// 未分级标签。
  static const String domainPriorityUnsetLabel = 'domain-priority-unset-label';

  // Task 63 轮二：9 条标签 getter + 1 条列表型 getter（domainWeekdayFull）

  /// 复盘段标题：结论（chip 分组名）。
  static const String domainConclusionLabel = 'domain-conclusion-label';

  /// 复盘段标题：原因（chip 分组名）。
  static const String domainReasonLabel = 'domain-reason-label';

  /// 复盘段标题：下一步（chip 分组名）。
  static const String domainNextStepLabel = 'domain-next-step-label';

  /// 日循环段名：计划。
  static const String domainPlanLabel = 'domain-plan-label';

  /// 日循环段名：回填。
  static const String domainBackfillLabel = 'domain-backfill-label';

  /// 日循环段名：复盘。
  static const String domainReviewLabel = 'domain-review-label';

  /// 日循环段名：心态。
  static const String domainMoodLabel = 'domain-mood-label';

  /// 空态：所选日还没有当日日志。
  static const String domainDayLogNotStarted = 'domain-day-log-not-started';

  /// 空态：当天没有待打卡的习惯。
  static const String domainNoHabitsDueToday = 'domain-no-habits-due-today';

  /// 星期全名（周一起、周日末，共 7 条）。按 `1..7` 取 `[day - 1]`；  zh 自带「周」字，en 只有短名 ⇒ 调用点**不要**再拼前缀。
  static const String domainWeekdayFull = 'domain-weekday-full';

  // Task 68 W9：星期名单条 7 条 + 循环任务整词 4 条

  /// 星期名：周一。
  static const String domainWeekdayMon = 'domain-weekday-mon';

  /// 星期名：周二。
  static const String domainWeekdayTue = 'domain-weekday-tue';

  /// 星期名：周三。
  static const String domainWeekdayWed = 'domain-weekday-wed';

  /// 星期名：周四。
  static const String domainWeekdayThu = 'domain-weekday-thu';

  /// 星期名：周五。
  static const String domainWeekdayFri = 'domain-weekday-fri';

  /// 星期名：周六。
  static const String domainWeekdaySat = 'domain-weekday-sat';

  /// 星期名：周日。
  static const String domainWeekdaySun = 'domain-weekday-sun';

  /// 循环任务整词：每天。
  static const String domainRecurringEvery = 'domain-recurring-every';

  /// 循环任务整词：工作日。
  static const String domainRecurringWorkdays = 'domain-recurring-workdays';

  /// 循环任务整词：周末。
  static const String domainRecurringWeekend = 'domain-recurring-weekend';

  /// 循环任务整词：未选。
  static const String domainRecurringNone = 'domain-recurring-none';

  // ---------------------------------------------------------------------------
  // 项目页（parts\projects.dart，49 条）
  // ---------------------------------------------------------------------------

  /// 项目页标题。
  static const String projectsTitle = 'projects-title';

  /// 项目页副标题。
  static const String projectsSubtitle = 'projects-subtitle';

  /// 项目页空态。
  static const String projectsEmpty = 'projects-empty';

  /// 新建项目。
  static const String projectsNewProjectAction = 'projects-new-project-action';

  /// 项目名称提示。
  static const String projectsNameHint = 'projects-name-hint';

  /// 项目目标提示。
  static const String projectsGoalHint = 'projects-goal-hint';

  /// 开始日期提示。
  static const String projectsStartHint = 'projects-start-hint';

  /// 结束日期提示。
  static const String projectsEndHint = 'projects-end-hint';

  /// 任务标题提示。
  static const String projectsTaskTitleHint = 'projects-task-title-hint';

  /// 目标日期提示。
  static const String projectsTargetDateHint = 'projects-target-date-hint';

  /// 添加任务。
  static const String projectsAddTaskAction = 'projects-add-task-action';

  /// 改期。
  static const String projectsRescheduleAction = 'projects-reschedule-action';

  /// 未排期条数（`{n}` 占位符）。
  static const String projectsUnscheduled = 'projects-unscheduled';

  /// 项目下没有任务。
  static const String projectsNoTask = 'projects-no-task';

  /// 项目未设定起止日期。
  static const String projectsNoDateRange = 'projects-no-date-range';

  /// 甘特图无可排期日期。
  static const String projectsEmptyChart = 'projects-empty-chart';

  /// 项目整体排进今天（Task 57）。
  static const String projectsScheduleTodayAction =
      'projects-schedule-today-action';

  /// 已排到某一天。
  static const String projectsScheduledOn = 'projects-scheduled-on';

  /// 增量区块标题。
  static const String projectsIncrementTitle = 'projects-increment-title';

  /// 无增量时的提交按钮。
  static const String projectsIncrementEmptyAction =
      'projects-increment-empty-action';

  /// 增量「进展」提示。
  static const String projectsIncrementProgressHint =
      'projects-increment-progress-hint';

  /// 增量「阻塞项」提示。
  static const String projectsIncrementBlockersHint =
      'projects-increment-blockers-hint';

  /// 增量「下一步」提示。
  static const String projectsIncrementNextStepHint =
      'projects-increment-next-step-hint';

  /// 追加增量按钮。
  static const String projectsIncrementAddAction =
      'projects-increment-add-action';

  /// 把一条增量排进今天。
  static const String projectsIncrementToTodayAction =
      'projects-increment-to-today-action';

  /// 增量只能追加。
  static const String projectsIncrementAppendOnly =
      'projects-increment-append-only';

  /// 里程碑逾期标记。
  static const String projectsMilestoneOverdue = 'projects-milestone-overdue';

  // Task 57 补轮：增量摘要的「摘录」标注 + 回原文入口。

  /// 增量摘要上的「摘录」标注。
  static const String projectsIncrementExcerptTag =
      'projects-increment-excerpt-tag';

  /// 「摘录」标注的说明（原文在当天的日志里）。
  static const String projectsIncrementExcerptHint =
      'projects-increment-excerpt-hint';

  /// 打开该条增量对应的日志原文。
  static const String projectsIncrementOpenOriginalAction =
      'projects-increment-open-original-action';

  // Task 59：按领域汇总的项目分布 + 新建项目的「所属领域」字段。

  /// 领域分布面板标题。
  static const String projectsDomainStatsTitle = 'projects-domain-stats-title';

  /// 没有所属领域的项目归到这一类。
  static const String projectsDomainStatsUncategorized =
      'projects-domain-stats-uncategorized';

  /// 某个领域下的项目数（`{n}` 占位符）。
  static const String projectsDomainStatsCount = 'projects-domain-stats-count';

  /// 「所属领域」字段标签。
  static const String projectsDomainFieldLabel = 'projects-domain-field-label';

  /// 所属领域未选时的占位。
  static const String projectsDomainUnset = 'projects-domain-unset';

  /// 领域：事业。
  static const String projectsDomainCareer = 'projects-domain-career';

  /// 领域：财富。
  static const String projectsDomainWealth = 'projects-domain-wealth';

  /// 领域：家庭。
  static const String projectsDomainFamily = 'projects-domain-family';

  /// 领域：学习。
  static const String projectsDomainLearning = 'projects-domain-learning';

  /// 领域：人际。
  static const String projectsDomainSocial = 'projects-domain-social';

  /// 领域：健康。
  static const String projectsDomainHealth = 'projects-domain-health';

  /// 校验失败：日期不是 `YYYY-MM-DD` 格式。
  static const String projectsInvalidDateFormat =
      'projects-invalid-date-format';

  /// 校验失败：格式对，但日历上没有这一天。
  static const String projectsDateNotExist = 'projects-date-not-exist';

  /// 校验失败：项目名称为空。
  static const String projectsNameRequired = 'projects-name-required';

  /// 校验失败：任务标题为空。
  static const String projectsTaskTitleRequired =
      'projects-task-title-required';

  /// 校验失败：增量没有写进展。
  static const String projectsProgressRequired = 'projects-progress-required';

  /// 任务不存在（`{id}` 由页面插值）。
  static const String projectsMilestoneMissing = 'projects-milestone-missing';

  /// 项目不存在（`{id}` 由页面插值）。
  static const String projectsProjectMissing = 'projects-project-missing';

  /// 校验失败：排期来源类型既不是 `project` 也不是 `increment`。
  static const String projectsSourceTypeInvalid =
      'projects-source-type-invalid';

  // ---------------------------------------------------------------------------
  // 日历与日期（parts\calendar.dart，19 条：16 条无参 getter + 1 条列表型
  // getter + 2 条插值方法）
  // ---------------------------------------------------------------------------
  // 中文取值逐字等于改动前的字面量；英文取值是新译文案（完整对照表见
  // `reports\task61-calendar-getters.md`）。

  /// 日历页标题。
  static const String calendarPageTitle = 'calendar-page-title';

  /// 翻月按钮：上个月。
  static const String calendarPrevMonth = 'calendar-prev-month';

  /// 翻月按钮：下个月。
  static const String calendarNextMonth = 'calendar-next-month';

  /// 月历格右上角的「今天」角标。
  static const String calendarTodayBadge = 'calendar-today-badge';

  /// 日期条左箭头：前一天。
  static const String calendarPrevDay = 'calendar-prev-day';

  /// 日期条右箭头：后一天。
  static const String calendarNextDay = 'calendar-next-day';

  /// 日期条只读徽标：过去日（补录模式）。
  static const String calendarBackfillMode = 'calendar-backfill-mode';

  /// 日期条只读徽标：未来日（预排）。
  static const String calendarPrePlanMode = 'calendar-pre-plan-mode';

  /// 弹层翻月按钮：上一月。
  static const String calendarPickerPrevMonth = 'calendar-picker-prev-month';

  /// 弹层翻月按钮：下一月。
  static const String calendarPickerNextMonth = 'calendar-picker-next-month';

  /// 快捷芯片：今天。
  static const String calendarToday = 'calendar-today';

  /// 快捷芯片：昨天。
  static const String calendarYesterday = 'calendar-yesterday';

  /// 快捷芯片：前天。
  static const String calendarDayBeforeYesterday =
      'calendar-day-before-yesterday';

  /// 快捷芯片：明天。
  static const String calendarTomorrow = 'calendar-tomorrow';

  /// 快捷芯片：本周内。
  static const String calendarThisWeek = 'calendar-this-week';

  /// 快捷芯片：无期限。
  static const String calendarNoDeadline = 'calendar-no-deadline';

  /// 星期短名（列表型 getter，7 条）。
  static const String calendarWeekdaysShort = 'calendar-weekdays-short';

  /// 插值方法：月份标题（`yyyy-MM` → 当前语言的月份标题）。
  static const String calendarMonthLabel = 'calendar-month-label';

  /// 插值方法：日期标题（`yyyy-MM-dd` → 当前语言的日期标题）。
  static const String calendarDateTitle = 'calendar-date-title';

  // ---------------------------------------------------------------------------
  // 方格时间轴（parts\timeline.dart，42 条：30 条 getter + 12 条插值方法）
  // ---------------------------------------------------------------------------

  /// 空格子上的引导语。
  static const String timelineEmptyGridHint = 'timeline-empty-grid-hint';

  /// 习惯入格条目的角标。
  static const String timelineHabitBackfill = 'timeline-habit-backfill';

  /// 手填弹窗的输入框提示。
  static const String timelinePlanTitleHint = 'timeline-plan-title-hint';

  /// 手填弹窗的确认按钮（≠ `confirm`/「确定」）。
  static const String timelineScheduleAction = 'timeline-schedule-action';

  /// 菜单分组名：手填。
  static const String timelineManualGroup = 'timeline-manual-group';

  /// 菜单项：手填一条。
  static const String timelineManualEntry = 'timeline-manual-entry';

  /// 菜单分组名：待办。
  static const String timelineTodoGroup = 'timeline-todo-group';

  /// 待办分支空态。
  static const String timelineTodoPoolEmpty = 'timeline-todo-pool-empty';

  /// 菜单分组名：习惯。
  static const String timelineHabitGroup = 'timeline-habit-group';

  /// 习惯分支空态。
  static const String timelineHabitEmpty = 'timeline-habit-empty';

  /// 起止弹窗的确认按钮（zh 是「确认」，与 `confirm` 的「确定」不是一条）。
  static const String timelineConfirmAction = 'timeline-confirm-action';

  /// 步进行标签：开始。
  static const String timelineStartLabel = 'timeline-start-label';

  /// 步进行标签：结束。
  static const String timelineEndLabel = 'timeline-end-label';

  /// 时长行标签：持续时间。
  static const String timelineDurationLabel = 'timeline-duration-label';

  /// 回填弹层标题。
  static const String timelineSlotFillTitle = 'timeline-slot-fill-title';

  /// 回填模板按钮。
  static const String timelineOutcomeTemplateTitle =
      'timeline-outcome-template-title';

  /// 详情窗标题。
  static const String timelineTaskDetailTitle = 'timeline-task-detail-title';

  /// 详情窗字段名：内容。
  static const String timelineContentLabel = 'timeline-content-label';

  /// 详情窗字段名：级别。
  static const String timelineLevelLabel = 'timeline-level-label';

  /// 详情窗字段名：回填内容。
  static const String timelineBackfillContentLabel =
      'timeline-backfill-content-label';

  /// 未来日的回填锁定提示。
  static const String timelineFutureDayBackfillBlocked =
      'timeline-future-day-backfill-blocked';

  /// 删除计划项的确认框标题。
  static const String timelineDeletePlanItemTitle =
      'timeline-delete-plan-item-title';

  /// 状态词：打卡。
  static const String timelineKindHabitLabel = 'timeline-kind-habit-label';

  /// 状态词：完成。
  static const String timelineKindDoneLabel = 'timeline-kind-done-label';

  /// 待办加载失败。
  static const String timelineTodoLoadFailed = 'timeline-todo-load-failed';

  /// 待办加载中。
  static const String timelineTodoLoading = 'timeline-todo-loading';

  /// 待办空态。
  static const String timelineTodoEmpty = 'timeline-todo-empty';

  /// 已排期徽标。
  static const String timelineTodoSlotted = 'timeline-todo-slotted';

  /// 节点文字：有缺口。
  static const String timelineNodeGap = 'timeline-node-gap';

  /// 节点文字：已闭合。
  static const String timelineNodeClosed = 'timeline-node-closed';

  /// 菜单标题：`HH:mm 这一格`。
  static const String timelineSlotMenuTitle = 'timeline-slot-menu-title';

  /// 起止弹窗标题：`YYYY-MM-DD · 起止`。
  static const String timelineRangeTitle = 'timeline-range-title';

  /// 时长：`共 N 分钟`（`slot_range_dialog.dart` 与  `plan_item_detail_dialog.dart` 共用）。
  static const String timelineTotalMinutes = 'timeline-total-minutes';

  /// 步进按钮 tooltip：`<标签> 减一格`。
  static const String timelineStepDown = 'timeline-step-down';

  /// 步进按钮 tooltip：`<标签> 加一格`。
  static const String timelineStepUp = 'timeline-step-up';

  /// 手填弹窗标题：`HH:mm 要做什么？`。
  static const String timelineSlotPrompt = 'timeline-slot-prompt';

  /// 写库失败提示：`写入失败：<error>`（两处共用同一条）。
  static const String timelineWriteFailed = 'timeline-write-failed';

  /// 删除确认正文：`确认删除「<title>」？…`。
  static const String timelineDeletePlanItemMessage =
      'timeline-delete-plan-item-message';

  /// 悬停卡片：详情行。
  static const String timelineHoverDetail = 'timeline-hover-detail';

  /// 悬停卡片：进展行。
  static const String timelineHoverNote = 'timeline-hover-note';

  /// 悬停卡片：状态行。
  static const String timelineHoverState = 'timeline-hover-state';

  /// 悬停卡片：级别行。
  static const String timelineHoverLevel = 'timeline-hover-level';

  // ---------------------------------------------------------------------------
  // 今日面板（parts\today.dart，55 条：44 条 getter + 11 条插值方法）
  // ---------------------------------------------------------------------------

  /// 未来日锁定卡标题：复盘与心态在当天开放。
  static const String todayReviewFutureTitle = 'today-review-future-title';

  /// 未来日锁定卡说明。
  static const String todayReviewFutureDetail = 'today-review-future-detail';

  /// 未来日「只可预排」提示（正文，手写条下方）。
  static const String todayFuturePlanOnly = 'today-future-plan-only';

  /// 未来日锁定卡副标题。
  static const String todayFuturePlanning = 'today-future-planning';

  /// 菜单项：改日期。
  static const String todayChangeDate = 'today-change-date';

  /// 菜单项：改时刻。
  static const String todayChangeTime = 'today-change-time';

  /// 菜单项：清除时刻（仅已排时刻时出现）。
  static const String todayClearTime = 'today-clear-time';

  /// 未排时刻：`时间 · 未排`。
  static const String todayTimeUnset = 'today-time-unset';

  /// 时刻选择器的标题。
  static const String todayPickStartTime = 'today-pick-start-time';

  /// 手写输入框占位：添加计划条目…
  static const String todayAddPlanHint = 'today-add-plan-hint';

  /// 手写按钮：+ 手写一条。
  static const String todayAddManual = 'today-add-manual';

  /// 右轨习惯速览：加载失败。
  static const String todayHabitLoadFailed = 'today-habit-load-failed';

  /// 右轨习惯速览：正在加载。
  static const String todayHabitLoading = 'today-habit-loading';

  /// 右轨习惯速览：所选日无排程习惯。
  static const String todayHabitEmpty = 'today-habit-empty';

  /// 闭环提示第一行：计划缺口。
  static const String todayStatPlanGap = 'today-stat-plan-gap';

  /// 闭环提示第二行：回填缺口。
  static const String todayStatFillGap = 'today-stat-fill-gap';

  /// 复盘状态：已写。
  static const String todayStatWritten = 'today-stat-written';

  /// 复盘状态：未写。
  static const String todayStatUnwritten = 'today-stat-unwritten';

  /// 心态状态：已记。
  static const String todayStatRecorded = 'today-stat-recorded';

  /// 心态状态：未记。
  static const String todayStatUnrecorded = 'today-stat-unrecorded';

  /// 项目停滞提醒的抑制按钮：今天不再提。
  static const String todayStallDismiss = 'today-stall-dismiss';

  /// 未来日拒绝打卡的提示。
  static const String todayNoticeFutureCheckin = 'today-notice-future-checkin';

  /// 提示横幅的关闭按钮：知道了。
  static const String todayGotIt = 'today-got-it';

  /// 复盘字段一标题。
  static const String todayReviewFieldLearn = 'today-review-field-learn';

  /// 复盘字段一占位。
  static const String todayReviewFieldLearnHint =
      'today-review-field-learn-hint';

  /// 复盘字段二标题。
  static const String todayReviewFieldGood = 'today-review-field-good';

  /// 复盘字段二占位。
  static const String todayReviewFieldGoodHint = 'today-review-field-good-hint';

  /// 复盘字段三标题。
  static const String todayReviewFieldImprove = 'today-review-field-improve';

  /// 复盘字段三占位。
  static const String todayReviewFieldImproveHint =
      'today-review-field-improve-hint';

  /// 复盘区块副标题。
  static const String todayReviewSubtitle = 'today-review-subtitle';

  /// 三段全空时的行内提示。
  static const String todayReviewEmptyNotice = 'today-review-empty-notice';

  /// 选项目对话框标题。
  static const String todayReviewPickProject = 'today-review-pick-project';

  /// 「记到项目」按钮文案。
  static const String todayReviewFileToProject = 'today-review-file-to-project';

  /// 脊线抬头：闭环环 · 四段比例条。
  static const String todayLoopRingA11y = 'today-loop-ring-a11y';

  /// 脊线刻度说明：刻度 0—100。
  static const String todayLoopRingScale = 'today-loop-ring-scale';

  /// 站会区块标题。
  static const String todayStandupTitle = 'today-standup-title';

  /// 站会区块副标题。
  static const String todayStandupSubtitle = 'today-standup-subtitle';

  /// 三段全空时的整块提示。
  static const String todayStandupEmpty = 'today-standup-empty';

  /// 第一段：昨日亮点。
  static const String todayStandupYesterday = 'today-standup-yesterday';

  /// 第一段空态。
  static const String todayStandupYesterdayEmpty =
      'today-standup-yesterday-empty';

  /// 第二段：今日优先。
  static const String todayStandupToday = 'today-standup-today';

  /// 第二段空态。
  static const String todayStandupTodayEmpty = 'today-standup-today-empty';

  /// 第三段：阻塞项。
  static const String todayStandupBlockers = 'today-standup-blockers';

  /// 第三段空态。
  static const String todayStandupBlockersEmpty =
      'today-standup-blockers-empty';

  /// 已排时刻：`时间 · <时刻>`。
  static const String todayTimeSet = 'today-time-set';

  /// 日期芯片文案：`日期 · <日期>`。
  static const String todayDateLabel = 'today-date-label';

  /// 日期按钮的无障碍标签（日期 + 时刻 + 可做什么）。
  static const String todayDateChipA11y = 'today-date-chip-a11y';

  /// 方格时间轴起点提示（选了过早的时刻时）。
  static const String todayGridStartHint = 'today-grid-start-hint';

  /// 项目停滞提醒正文。
  static const String todayStallHint = 'today-stall-hint';

  /// 习惯数据加载失败提示。
  static const String todayHabitLoadError = 'today-habit-load-error';

  /// 打卡成功提示。
  static const String todayCheckedIn = 'today-checked-in';

  /// 打卡失败提示。
  static const String todayCheckinFailed = 'today-checkin-failed';

  /// 已记到某项目。
  static const String todayReviewFiledTo = 'today-review-filed-to';

  /// 把两段摘录拼成一条增量正文（中文分号 / 英文分号加空格）。
  static const String todayReviewJoinSegments = 'today-review-join-segments';

  /// 段标题 + 条目数：`<标签>（N）`。
  static const String todayStandupSectionCount = 'today-standup-section-count';

  // ---------------------------------------------------------------------------
  // 习惯打卡（parts\habit.dart，53 条：44 条 getter + 9 条插值方法）
  // ---------------------------------------------------------------------------

  /// 心态分组名：每日核心。
  static const String moodGroupDayTitle = 'mood-group-day-title';

  /// 心态分组名：每周补充。
  static const String moodGroupWeekTitle = 'mood-group-week-title';

  /// 心态卡片副标题：`每日 3 项 + 每周 2 项，各 0–10 分；留空表示不作评`。
  static const String moodSectionSubtitle = 'mood-section-subtitle';

  /// 按钮：全部清空。
  static const String moodClearAll = 'mood-clear-all';

  /// 空态：今天没打分。
  static const String moodMarkFailed = 'mood-mark-failed';

  /// 输入框标签：明日改进点。
  static const String moodNextActionLabel = 'mood-next-action-label';

  /// 输入框提示：明天先做的一件具体事。
  static const String moodNextActionHint = 'mood-next-action-hint';

  /// 输入框标签：情绪备注。
  static const String moodNoteLabel = 'mood-note-label';

  /// 输入框提示：今天状态如何？为什么？
  static const String moodNoteHint = 'mood-note-hint';

  /// 维度未评标记。
  static const String moodUnrated = 'mood-unrated';

  /// 无障碍/提示：清除这一维。
  static const String moodClearDimension = 'mood-clear-dimension';

  /// 维度名：履约负责。
  static const String moodDimFulfillmentLabel = 'mood-dim-fulfillment-label';

  /// 维度说明：履约负责。
  static const String moodDimFulfillmentDesc = 'mood-dim-fulfillment-desc';

  /// 维度名：高效高质。
  static const String moodDimEfficiencyLabel = 'mood-dim-efficiency-label';

  /// 维度说明：高效高质。
  static const String moodDimEfficiencyDesc = 'mood-dim-efficiency-desc';

  /// 维度名：积极思维。
  static const String moodDimPositiveMindLabel = 'mood-dim-positive-mind-label';

  /// 维度说明：积极思维。
  static const String moodDimPositiveMindDesc = 'mood-dim-positive-mind-desc';

  /// 维度名：自我效能。
  static const String moodDimSelfEfficacyLabel = 'mood-dim-self-efficacy-label';

  /// 维度说明：自我效能。
  static const String moodDimSelfEfficacyDesc = 'mood-dim-self-efficacy-desc';

  /// 维度名：利他贡献。
  static const String moodDimContributionLabel = 'mood-dim-contribution-label';

  /// 维度说明：利他贡献。
  static const String moodDimContributionDesc = 'mood-dim-contribution-desc';

  /// legacy 维度名：认真。
  static const String moodLegacyDiligent = 'mood-legacy-diligent';

  /// legacy 维度名：快。
  static const String moodLegacyFast = 'mood-legacy-fast';

  /// legacy 维度名：坚守承诺。
  static const String moodLegacyKeepPromise = 'mood-legacy-keep-promise';

  /// legacy 维度名：保证完成任务。
  static const String moodLegacyFinishTask = 'mood-legacy-finish-task';

  /// legacy 维度名：乐观。
  static const String moodLegacyOptimistic = 'mood-legacy-optimistic';

  /// legacy 维度名：自信。
  static const String moodLegacyConfident = 'mood-legacy-confident';

  /// legacy 维度名：爱与奉献。
  static const String moodLegacyLoveAndDedication =
      'mood-legacy-love-and-dedication';

  /// legacy 维度名：决不找借口。
  static const String moodLegacyNoExcuses = 'mood-legacy-no-excuses';

  /// 区块标题：习惯打卡。
  static const String habitSectionTitle = 'habit-section-title';

  /// 区块副标题：`打勾会同步生成今日计划里的回填行`。
  static const String habitSectionSubtitle = 'habit-section-subtitle';

  /// 区块空态：`今天没有排程内的习惯。`（注意句末句号，与  `domainNoHabitsDueToday` 不是同一条）。
  static const String habitSectionEmpty = 'habit-section-empty';

  /// 吸底条加载中。
  static const String habitCheckinLoading = 'habit-checkin-loading';

  /// 吸底条加载失败。
  static const String habitCheckinError = 'habit-checkin-error';

  /// 吸底条标题：`习惯打卡 · 吸底不滚动`。
  static const String habitCheckinHeadTitle = 'habit-checkin-head-title';

  /// 吸底条提示：`· 一点即打，跳过需理由`。
  static const String habitCheckinHeadHint = 'habit-checkin-head-hint';

  /// 习惯页标题：习惯。
  static const String habitPageTitle = 'habit-page-title';

  /// 习惯页未来日提示：`未来日只做预排：习惯打卡在当天开放。`。
  static const String habitPageFutureHint = 'habit-page-future-hint';

  /// 习惯页空态：还没有习惯。
  static const String habitPageEmpty = 'habit-page-empty';

  /// 象限选择对话框标题。
  static const String priorityPickQuadrant = 'priority-pick-quadrant';

  /// ABC 选择对话框标题。
  static const String priorityPickAbc = 'priority-pick-abc';

  /// 悬停气泡徽标：当前。
  static const String priorityBubbleCurrent = 'priority-bubble-current';

  /// 悬停气泡脚注（只读态）。
  static const String priorityBubbleReadonly = 'priority-bubble-readonly';

  /// 悬停气泡脚注（可编辑态）。
  static const String priorityBubbleEditable = 'priority-bubble-editable';

  /// 心态计分：`已评 N/M 维`。
  static const String moodRatedCount = 'mood-rated-count';

  /// 心态均分：`均分 <value>`（`value` 为已格式化串，可能为 `—`）。
  static const String moodAverage = 'mood-average';

  /// 分组头：`<title> · 每日更新` / `<title> · 每周更新`。
  static const String moodGroupHeader = 'mood-group-header';

  /// 分组进度：`N 项 · 已评 M`。
  static const String moodGroupProgress = 'mood-group-progress';

  /// 佐证行：`佐证：<joined>`。
  static const String moodEvidence = 'mood-evidence';

  /// 习惯目标：`目标 N<unit>`。
  static const String habitTarget = 'habit-target';

  /// 习惯加载失败：`习惯加载失败：<error>`。
  static const String habitLoadFailed = 'habit-load-failed';

  /// 打卡记录加载失败：`打卡记录加载失败：<error>`。
  static const String habitCheckinLoadFailed = 'habit-checkin-load-failed';

  /// 象限气泡无障碍摘要：`<象限>，紧急：是，重要：否`。
  static const String priorityBubbleA11y = 'priority-bubble-a11y';

  // ---------------------------------------------------------------------------
  // 对话框（parts\dialog.dart，108 条：93 条 getter + 15 条插值方法）
  // ---------------------------------------------------------------------------

  /// 预估时长单位：分钟。
  static const String dialogEstUnitMinute = 'dialog-est-unit-minute';

  /// 预估时长单位：小时。
  static const String dialogEstUnitHour = 'dialog-est-unit-hour';

  /// 预估时长单位：日。
  static const String dialogEstUnitDay = 'dialog-est-unit-day';

  /// 预估时长单位：周。
  static const String dialogEstUnitWeek = 'dialog-est-unit-week';

  /// 预估时长单位：月。
  static const String dialogEstUnitMonth = 'dialog-est-unit-month';

  /// 校验失败：习惯名为空。
  static const String dialogHabitNameRequired = 'dialog-habit-name-required';

  /// 校验失败：没选任何星期。
  static const String dialogHabitWeekdayRequired =
      'dialog-habit-weekday-required';

  /// 字段名：习惯名（必填）。
  static const String dialogHabitNameLabel = 'dialog-habit-name-label';

  /// 字段名：说明（可选）。
  static const String dialogHabitNoteLabel = 'dialog-habit-note-label';

  /// 小节名：排程。
  static const String dialogHabitSchedule = 'dialog-habit-schedule';

  /// 排程选项：每天。
  static const String dialogHabitDaily = 'dialog-habit-daily';

  /// 排程选项：每隔 N 天。
  static const String dialogHabitEveryDays = 'dialog-habit-every-days';

  /// 排程选项：每隔 N 周。
  static const String dialogHabitEveryWeeks = 'dialog-habit-every-weeks';

  /// 排程选项：每周指定几天。
  static const String dialogHabitWeeklyPick = 'dialog-habit-weekly-pick';

  /// 间隔行前缀：每隔。
  static const String dialogHabitEvery = 'dialog-habit-every';

  /// 小节名：星期。
  static const String dialogHabitWeekday = 'dialog-habit-weekday';

  /// 小节名：起始日期。
  static const String dialogHabitStartDate = 'dialog-habit-start-date';

  /// 小节名：每日至少完成。
  static const String dialogHabitDailyMin = 'dialog-habit-daily-min';

  /// 面板标题：添加习惯。
  static const String dialogHabitCreate = 'dialog-habit-create';

  /// 面板副标题：排程与目标的说明。
  static const String dialogHabitCreateSubtitle =
      'dialog-habit-create-subtitle';

  /// 校验失败：标题为空（W7 `todo_pool_page` 复用）。
  static const String dialogTodoTitleRequired = 'dialog-todo-title-required';

  /// 校验失败：预估时间不是正数（W7 `todo_pool_page` 复用）。
  static const String dialogTodoEstInvalid = 'dialog-todo-est-invalid';

  /// 面板标题：手写一条。
  static const String dialogTodoCreateTitle = 'dialog-todo-create-title';

  /// 输入框占位：要做什么？
  static const String dialogTodoTitleHint = 'dialog-todo-title-hint';

  /// 字段名：预估时间（可选）。
  static const String dialogTodoEstLabel = 'dialog-todo-est-label';

  /// 输入框占位：例如 25。
  static const String dialogTodoEstHint = 'dialog-todo-est-hint';

  /// 字段名：优先级（可选）。
  static const String dialogTodoPriorityLabel = 'dialog-todo-priority-label';

  /// 复选项：同时捞入今天。
  static const String dialogTodoPullToday = 'dialog-todo-pull-today';

  /// 主按钮：保存中…。
  static const String dialogTodoSaving = 'dialog-todo-saving';

  /// 面板标题：从待办池捞。
  static const String dialogTodoPullTitle = 'dialog-todo-pull-title';

  /// 空态：待办池是空的（短版）。
  static const String dialogTodoPoolEmpty = 'dialog-todo-pool-empty';

  /// 主按钮：捞入中…。
  static const String dialogTodoPulling = 'dialog-todo-pulling';

  /// 主按钮：捞入。
  static const String dialogTodoPull = 'dialog-todo-pull';

  /// 校验失败：没选任何星期。
  static const String dialogRecurringWeekdayRequired =
      'dialog-recurring-weekday-required';

  /// 校验失败：开始时刻格式不对。
  static const String dialogRecurringTimeInvalid =
      'dialog-recurring-time-invalid';

  /// 校验失败：时长越界。
  static const String dialogRecurringDurationInvalid =
      'dialog-recurring-duration-invalid';

  /// 字段名：标题（必填）。
  static const String dialogRecurringTitleLabel =
      'dialog-recurring-title-label';

  /// 字段名：开始 HH:mm（06:00 起）。
  static const String dialogRecurringStartLabel =
      'dialog-recurring-start-label';

  /// 字段名：时长（分钟）。
  static const String dialogRecurringDurationLabel =
      'dialog-recurring-duration-label';

  /// 字段名：备注（可选）。
  static const String dialogRecurringNoteLabel = 'dialog-recurring-note-label';

  /// 主按钮：确认保存（上面有夹取提示时才用它）。
  static const String dialogRecurringSaveConfirm =
      'dialog-recurring-save-confirm';

  /// 面板标题：添加循环任务。
  static const String dialogRecurringCreateTitle =
      'dialog-recurring-create-title';

  /// 面板副标题：按星期与开始时刻自动排进计划。
  static const String dialogRecurringCreateSubtitle =
      'dialog-recurring-create-subtitle';

  /// 确认框标题：删除循环任务。
  static const String dialogRecurringDeleteTitle =
      'dialog-recurring-delete-title';

  /// 段落标题：规则。
  static const String dialogRecurringSection = 'dialog-recurring-section';

  /// 读取中占位。
  static const String dialogRecurringLoading = 'dialog-recurring-loading';

  /// 空态：还没有循环规则。
  static const String dialogRecurringNone = 'dialog-recurring-none';

  /// 空态提示：怎么添加一条。
  static const String dialogRecurringNoneHint = 'dialog-recurring-none-hint';

  /// 掩码为 0 时的兜底显示（`每日`，与排程选项的 `每天` 不是同一句）。
  static const String dialogRecurringDaily = 'dialog-recurring-daily';

  /// 规则状态：启用中。
  static const String dialogRuleActiveOn = 'dialog-rule-active-on';

  /// 规则状态：已停用。
  static const String dialogRuleActiveOff = 'dialog-rule-active-off';

  /// 规则动作：停用。
  static const String dialogRuleDisable = 'dialog-rule-disable';

  /// 规则动作：启用。
  static const String dialogRuleEnable = 'dialog-rule-enable';

  /// 芯片：自定义…。
  static const String dialogDurationCustom = 'dialog-duration-custom';

  /// 提示：自定义时长怎么输入（引用键条上的手写入口）。
  static const String dialogDurationCustomHint = 'dialog-duration-custom-hint';

  /// 按钮：把未能解析的原文重新拆成三段。
  static const String dialogNoteRestructure = 'dialog-note-restructure';

  /// `[下一步]` 自由文本框的标签（全角括号逐字保留）。
  static const String dialogNoteNextStepLabel = 'dialog-note-next-step-label';

  /// 按钮：只存进展、不标记完成。
  static const String dialogNoteSaveProgressOnly =
      'dialog-note-save-progress-only';

  /// 按钮：标记完成（是按钮，不是 `PlanStatus` 的「完成」标签）。
  static const String dialogNoteDone = 'dialog-note-done';

  /// 结论：按时完成。
  static const String dialogOutcomeOnTime = 'dialog-outcome-on-time';

  /// 结论：延后完成。
  static const String dialogOutcomeLate = 'dialog-outcome-late';

  /// 结论：提前完成。
  static const String dialogOutcomeEarly = 'dialog-outcome-early';

  /// 结论：部分完成。
  static const String dialogOutcomePartial = 'dialog-outcome-partial';

  /// 结论：受阻。
  static const String dialogOutcomeBlocked = 'dialog-outcome-blocked';

  /// 结论：顺延到明天。
  static const String dialogOutcomeDeferredTomorrow =
      'dialog-outcome-deferred-tomorrow';

  /// 原因：预估不足。
  static const String dialogReasonUnderestimated =
      'dialog-reason-underestimated';

  /// 原因：被打断。
  static const String dialogReasonInterrupted = 'dialog-reason-interrupted';

  /// 原因：依赖外部。
  static const String dialogReasonExternal = 'dialog-reason-external';

  /// 原因：优先级变了。
  static const String dialogReasonPriorityChanged =
      'dialog-reason-priority-changed';

  /// 原因：状态不好。
  static const String dialogReasonPoorState = 'dialog-reason-poor-state';

  /// 原因：时间不够。
  static const String dialogReasonNoTime = 'dialog-reason-no-time';

  /// 原因：信息不清。
  static const String dialogReasonUnclear = 'dialog-reason-unclear';

  /// 原因：其他。
  static const String dialogReasonOther = 'dialog-reason-other';

  /// 下一步：明天继续。
  static const String dialogNextStepContinueTomorrow =
      'dialog-next-step-continue-tomorrow';

  /// 下一步：转成待办。
  static const String dialogNextStepToTodo = 'dialog-next-step-to-todo';

  /// 下一步：交出去。
  static const String dialogNextStepHandOff = 'dialog-next-step-hand-off';

  /// 下一步：缩小范围。
  static const String dialogNextStepNarrowScope =
      'dialog-next-step-narrow-scope';

  /// 下一步：定日复盘。
  static const String dialogNextStepReviewLater =
      'dialog-next-step-review-later';

  /// 下一步：就此停止。
  static const String dialogNextStepStopHere = 'dialog-next-step-stop-here';

  /// 副标前半的「加载中」占位。
  static const String dialogPoolLoading = 'dialog-pool-loading';

  /// 页标题。
  static const String dialogPoolTitle = 'dialog-pool-title';

  /// 新建表单：标题输入框提示（必填）。
  static const String dialogPoolTitleHint = 'dialog-pool-title-hint';

  /// 新建表单：起始时间输入框提示。
  static const String dialogPoolStartHint = 'dialog-pool-start-hint';

  /// 新建表单：到期日输入框提示。
  static const String dialogPoolDueHint = 'dialog-pool-due-hint';

  /// 新建表单：主按钮（全角 `＋` 是字形，不是文案）。
  static const String dialogPoolNew = 'dialog-pool-new';

  /// 表头：优先级列。
  static const String dialogPoolColPriority = 'dialog-pool-col-priority';

  /// 表头：预估时长列。
  static const String dialogPoolColEst = 'dialog-pool-col-est';

  /// 表头：象限列。
  static const String dialogPoolColQuadrant = 'dialog-pool-col-quadrant';

  /// 表头：到期日列。
  static const String dialogPoolColDue = 'dialog-pool-col-due';

  /// 表头：动作列。
  static const String dialogPoolColAction = 'dialog-pool-col-action';

  /// 起始时间格式非法时的行内错误。
  static const String dialogPoolStartInvalid = 'dialog-pool-start-invalid';

  /// 行内动作：加入主页计划。
  static const String dialogPoolAddToToday = 'dialog-pool-add-to-today';

  /// 空态长句（与手写面板的短版「待办池是空的」并存，两句不是同一条）。
  static const String dialogPoolEmptyLong = 'dialog-pool-empty-long';

  /// 习惯已落库但自动进计划失败（附带原始错误）。
  static const String dialogHabitSavedWarn = 'dialog-habit-saved-warn';

  /// 面板副标题：先存进待办池（夹带目标日期）。
  static const String dialogTodoCreateSubtitle = 'dialog-todo-create-subtitle';

  /// 面板副标题：捞进目标日计划（夹带目标日期）。
  static const String dialogTodoPullSubtitle = 'dialog-todo-pull-subtitle';

  /// 校验失败：选中日不是合法日历日。
  static const String dialogRecurringBadDate = 'dialog-recurring-bad-date';

  /// 提示：为了让规则今天就生效，已把今天并入重复日。
  static const String dialogRecurringMergedWeekday =
      'dialog-recurring-merged-weekday';

  /// 提示：开始时刻早于时间轴下界，已夹到边界。
  static const String dialogRecurringTimeClamped =
      'dialog-recurring-time-clamped';

  /// 规则动作（停用 / 启用 / 删除）失败（附带原始错误）。
  static const String dialogRuleActionFailed = 'dialog-rule-action-failed';

  /// 确认框正文：归档语义说明（夹带规则标题）。
  static const String dialogRecurringDeleteMessage =
      'dialog-recurring-delete-message';

  /// 物化失败（附带原始错误）。
  static const String dialogAutoScheduleFailed = 'dialog-auto-schedule-failed';

  /// 规则列表读取失败（附带原始错误）。
  static const String dialogRecurringLoadFailed =
      'dialog-recurring-load-failed';

  /// 计数行：共 N 条规则。
  static const String dialogRecurringCount = 'dialog-recurring-count';

  /// 规则行摘要：星期 · 时长 · 状态。
  static const String dialogRecurringSummary = 'dialog-recurring-summary';

  /// 副标前半：池内待捞条数。
  static const String dialogPoolAvailable = 'dialog-pool-available';

  /// 副标：「条数 · 捞入 目标日」。
  static const String dialogPoolHead = 'dialog-pool-head';

  /// 行内只读徽标：已排期 + 起始时刻。
  static const String dialogPoolScheduled = 'dialog-pool-scheduled';

  // ---------------------------------------------------------------------------
  // 目标页（parts\goals.dart，25 条；Task 65 UI 半批 B1）
  // ---------------------------------------------------------------------------

  /// 目标页标题。
  static const String goalsTitle = 'goal-title';

  /// 页签：周。
  static const String goalsTabWeek = 'goal-tab-week';

  /// 页签：月。
  static const String goalsTabMonth = 'goal-tab-month';

  /// 页签：年。
  static const String goalsTabYear = 'goal-tab-year';

  /// 页签：蓝图。
  static const String goalsTabBlueprint = 'goal-tab-blueprint';

  /// 上游面板：未完成年目标。
  static const String goalsUpstreamYearTitle = 'goal-upstream-year-title';

  /// 上游面板：未完成月目标。
  static const String goalsUpstreamMonthTitle = 'goal-upstream-month-title';

  /// 上游面板：未完成周目标。
  static const String goalsUpstreamWeekTitle = 'goal-upstream-week-title';

  /// 上游面板：点击或拖拽添加到当前周期的提示。
  static const String goalsUpstreamAddHint = 'goal-upstream-add-hint';

  /// 上游面板：空态。
  static const String goalsUpstreamEmpty = 'goal-upstream-empty';

  /// 上游面板：添加到计划的动作位。
  static const String goalsUpstreamAddMenu = 'goal-upstream-add-menu';

  /// 周视图区块标题。
  static const String goalsWeekSection = 'goal-week-section';

  /// 周视图空态。
  static const String goalsWeekEmpty = 'goal-week-empty';

  /// 周视图表头：优先顺序。
  static const String goalsColumnOrder = 'goal-column-order';

  /// 周视图表头：目标。
  static const String goalsColumnGoal = 'goal-column-goal';

  /// 周视图表头：象限。
  static const String goalsColumnQuadrant = 'goal-column-quadrant';

  /// 周视图表头：完成期限。
  static const String goalsColumnDue = 'goal-column-due';

  /// 周视图表头：完成。
  static const String goalsColumnDone = 'goal-column-done';

  /// 周视图表头：服务于。
  static const String goalsColumnServes = 'goal-column-serves';

  /// 完成度标签。
  static const String goalsCompletion = 'goal-completion';

  /// 关联计划项标签。
  static const String goalsPlanItems = 'goal-plan-items';

  /// 未落位标记。
  static const String goalsUnplaced = 'goal-unplaced';

  /// 草稿滚动区标题。
  static const String goalsDraftSection = 'goal-draft-section';

  /// 草稿滚动区空态。
  static const String goalsDraftEmpty = 'goal-draft-empty';

  /// 草稿滚动区：确认写入按钮。
  static const String goalsDraftConfirm = 'goal-draft-confirm';

  /// 草稿写入成功后的提示。
  static const String goalsDraftSaved = 'goal-draft-saved';

  /// 滚动候选来源：结转。
  static const String goalsDraftCarryOver = 'goal-draft-carry-over';

  /// 滚动候选来源：由本月目标派生。
  static const String goalsDraftFromMonthly = 'goal-draft-from-monthly';

  /// 月页骨架占位。
  static const String goalsPlaceholderMonth = 'goal-placeholder-month';

  /// 年页骨架占位。
  static const String goalsPlaceholderYear = 'goal-placeholder-year';

  /// 蓝图页骨架占位。
  static const String goalsPlaceholderBlueprint = 'goal-placeholder-blueprint';

  // ---------------------------------------------------------------------------
  // 目标页 B2（parts\goals.dart，58 条；Task 66 UI 半批 B2）
  // ---------------------------------------------------------------------------

  /// 目标状态：草稿。
  static const String goalStatusDraft = 'goal-status-draft';

  /// 目标状态：进行中。
  static const String goalStatusActive = 'goal-status-active';

  /// 目标状态：已完成。
  static const String goalStatusDone = 'goal-status-done';

  /// 目标状态：已取消。
  static const String goalStatusCancelled = 'goal-status-cancelled';

  /// 自评标签（用户自评，不是达成率）。
  static const String goalSelfScore = 'goal-self-score';

  /// 待确认草稿区标题（草稿只落在本页，点确认才落库）。
  static const String goalDraftPending = 'goal-draft-pending';

  /// 月页顶部年度汇总条标题。
  static const String goalMonthYearBar = 'goal-month-year-bar';

  /// 月页「上月复盘」区块标题。
  static const String goalMonthReviewSection = 'goal-month-review-section';

  /// 月页「上月复盘」空态。
  static const String goalMonthReviewEmpty = 'goal-month-review-empty';

  /// 月页复盘行：未完成原因标签。
  static const String goalMonthReviewReason = 'goal-month-review-reason';

  /// 月页复盘行：未完成原因缺失的提示（只提示，不阻断）。
  static const String goalMonthReviewReasonMissing =
      'goal-month-review-reason-missing';

  /// 月页复盘行：改进措施标签。
  static const String goalMonthImprove = 'goal-month-improve';

  /// 月页复盘行：改进措施为空时的占位。
  static const String goalMonthImproveEmpty = 'goal-month-improve-empty';

  /// 月页复盘行：转为本月目标草稿的动作。
  static const String goalMonthConvertDraft = 'goal-month-convert-draft';

  /// 月页「本月目标」区块标题。
  static const String goalMonthGoalsSection = 'goal-month-goals-section';

  /// 月页「本月目标」空态。
  static const String goalMonthGoalsEmpty = 'goal-month-goals-empty';

  /// 月页表头：类别。
  static const String goalMonthColumnCategory = 'goal-month-column-category';

  /// 月页表头：序号。
  static const String goalMonthColumnIndex = 'goal-month-column-index';

  /// 月页表头：方法和措施。
  static const String goalMonthColumnMethods = 'goal-month-column-methods';

  /// 月页表头：完成。
  static const String goalMonthColumnDone = 'goal-month-column-done';

  /// 月页行标记：没有上层目标的「临时事项」。
  static const String goalMonthAdHoc = 'goal-month-ad-hoc';

  /// 月页行标记：服务于某个年目标。
  static const String goalMonthServesYearly = 'goal-month-serves-yearly';

  /// 月页滚动候选空态。
  static const String goalMonthDraftEmpty = 'goal-month-draft-empty';

  /// 年页「年度目标」区块标题。
  static const String goalYearGoalsSection = 'goal-year-goals-section';

  /// 年页「年度目标」空态。
  static const String goalYearGoalsEmpty = 'goal-year-goals-empty';

  /// 年页表一头：起止时间。
  static const String goalYearColumnPeriod = 'goal-year-column-period';

  /// 年页表二标题：月度展开（1–12 月）。
  static const String goalYearMonthsSection = 'goal-year-months-section';

  /// 年页表二列头：月目标。
  static const String goalYearMonthColumn = 'goal-year-month-column';

  /// 年页表二空格：该月未展开。
  static const String goalYearCellEmpty = 'goal-year-cell-empty';

  /// 年页表二空格输入框的提示文案。
  static const String goalYearCellInputHint = 'goal-year-cell-input-hint';

  /// 年页表二空格：加入待确认草稿的动作。
  static const String goalYearCellAddDraft = 'goal-year-cell-add-draft';

  /// 年页「年度复盘」区块标题。
  static const String goalYearReviewSection = 'goal-year-review-section';

  /// 年页年度复盘：完成项数标签。
  static const String goalYearReviewDone = 'goal-year-review-done';

  /// 年页年度复盘：自评总分标签。
  static const String goalYearReviewScoreTotal = 'goal-year-review-score-total';

  /// 年页年度复盘：自评均值标签。
  static const String goalYearReviewScoreAverage =
      'goal-year-review-score-average';

  /// 年页年度复盘：自评口径说明（用户自评，不是达成率）。
  static const String goalYearReviewSelfNote = 'goal-year-review-self-note';

  /// 年页「80/20 视角」区块标题（只呈现，不评分、不排名）。
  static const String goalYear8020Section = 'goal-year-8020-section';

  /// 年页「80/20 视角」空态。
  static const String goalYear8020Empty = 'goal-year-8020-empty';

  /// 年页「80/20 视角」：执行记录条数单位。
  static const String goalYear8020Tracks = 'goal-year-8020-tracks';

  /// 年页滚动候选空态。
  static const String goalYearDraftEmpty = 'goal-year-draft-empty';

  /// 蓝图页矩阵区块标题。
  static const String goalBlueprintMatrixSection =
      'goal-blueprint-matrix-section';

  /// 蓝图页矩阵行头：目标。
  static const String goalBlueprintColumnGoal = 'goal-blueprint-column-goal';

  /// 蓝图档位：终极。
  static const String goalBlueprintHorizonUltimate =
      'goal-blueprint-horizon-ultimate';

  /// 蓝图档位：远期。
  static const String goalBlueprintHorizonLong = 'goal-blueprint-horizon-long';

  /// 蓝图档位：中期。
  static const String goalBlueprintHorizonMid = 'goal-blueprint-horizon-mid';

  /// 蓝图档位：短期。
  static const String goalBlueprintHorizonShort = 'goal-blueprint-horizon-short';

  /// 蓝图档位：近期（1 年）。
  static const String goalBlueprintHorizonNear = 'goal-blueprint-horizon-near';

  /// 蓝图格为空时的占位（空格合法，不报错）。
  static const String goalBlueprintEmptyCell = 'goal-blueprint-empty-cell';

  /// 蓝图页说明：整行留空合法。
  static const String goalBlueprintBlankRowHint = 'goal-blueprint-blank-row-hint';

  /// 蓝图页说明：近期列的数据来源（与年视图同一份数据）。
  static const String goalBlueprintNearSource = 'goal-blueprint-near-source';

  /// 蓝图格：做法条数单位。
  static const String goalBlueprintActionsCount = 'goal-blueprint-actions-count';

  /// 蓝图格展开：周目标标签。
  static const String goalBlueprintWeeklyTarget = 'goal-blueprint-weekly-target';

  /// 蓝图格：拆成 3 条待办的动作。
  static const String goalBlueprintSplitTodos = 'goal-blueprint-split-todos';

  /// 蓝图页：待确认待办区标题。
  static const String goalBlueprintPendingTodos = 'goal-blueprint-pending-todos';

  /// 蓝图页：确认写入待办的动作。
  static const String goalBlueprintConfirmTodos = 'goal-blueprint-confirm-todos';

  /// 蓝图格：新建目标入口（B8-W1）。
  static const String goalBlueprintAddGoal = 'goal-blueprint-add-goal';

  /// 蓝图卡片：编辑入口。
  static const String goalBlueprintEditGoal = 'goal-blueprint-edit-goal';

  /// 蓝图卡片：删除入口 + 二次确认框标题。
  static const String goalBlueprintDeleteGoal = 'goal-blueprint-delete-goal';

  /// 蓝图：目标保存成功提示。
  static const String goalBlueprintGoalSaved = 'goal-blueprint-goal-saved';

  /// 蓝图：目标删除成功提示。
  static const String goalBlueprintGoalDeleted = 'goal-blueprint-goal-deleted';

  /// 蓝图表单：领域。
  static const String goalBlueprintFieldDomain = 'goal-blueprint-field-domain';

  /// 蓝图表单：档位。
  static const String goalBlueprintFieldHorizon = 'goal-blueprint-field-horizon';

  /// 蓝图表单：备注。
  static const String goalBlueprintFieldNote = 'goal-blueprint-field-note';

  /// 蓝图表单：关键词。
  static const String goalBlueprintFieldKeywords =
      'goal-blueprint-field-keywords';

  /// 蓝图表单：期限（`YYYY-MM-DD`）。
  static const String goalBlueprintFieldDue = 'goal-blueprint-field-due';

  /// 蓝图表单：未设置（领域置空）。
  static const String goalBlueprintFieldUnset = 'goal-blueprint-field-unset';

  /// 蓝图表单：期限格式非法提示。
  static const String goalBlueprintFieldDueInvalid =
      'goal-blueprint-field-due-invalid';

  /// 蓝图页平衡轮区块标题（纯派生，不落库）。
  static const String goalBlueprintBalanceSection =
      'goal-blueprint-balance-section';

  /// 蓝图页平衡轮空态。
  static const String goalBlueprintBalanceEmpty = 'goal-blueprint-balance-empty';

  /// 蓝图页平衡轮：习惯打卡标签。
  static const String goalBlueprintBalanceHabit = 'goal-blueprint-balance-habit';

  // ---------------------------------------------------------------------------
  // 对照表
  // ---------------------------------------------------------------------------

  /// getter 名 → 键（503 条，覆盖 `AppLocalizations` 全部无参 String getter；
  /// 另有 4 条列表型 getter 在 `byListGetter`）。
  ///
  /// 顺序与 `parts\*.dart` 的声明顺序一致，方便对读。
  static const Map<String, String> byGetter = <String, String>{
    // 设置页 32 条
    'settingsTitle': settingsTitle,
    'settingsSubtitle': settingsSubtitle,
    'sectionAppearance': settingsSectionAppearance,
    'themeSystem': settingsThemeSystem,
    'themeLight': settingsThemeLight,
    'themeDark': settingsThemeDark,
    'sectionLanguage': settingsSectionLanguage,
    'languageChinese': settingsLanguageZh,
    'languageEnglish': settingsLanguageEn,
    'sectionSystem': settingsSectionSystem,
    'launchOnBoot': settingsLaunchOnBoot,
    'launchOnBootHint': settingsLaunchOnBootHint,
    'desktopShortcut': settingsDesktopShortcut,
    'desktopShortcutHint': settingsDesktopShortcutHint,
    'shortcutCreated': settingsShortcutCreated,
    'sectionPlanWindow': settingsSectionPlanWindow,
    'planStart': settingsPlanStart,
    'planEnd': settingsPlanEnd,
    'planWindowHint': settingsPlanWindowHint,
    'sectionOther': settingsSectionOther,
    'density': settingsDensity,
    'densityCompact': settingsDensityCompact,
    'densityComfortable': settingsDensityComfortable,
    'densityRoomy': settingsDensityRoomy,
    'priorityDisplayMode': settingsPriorityDisplayMode,
    'priorityQuadrant': settingsPriorityQuadrant,
    'priorityAbc': settingsPriorityAbc,
    'resetPreferences': settingsReset,
    'resetPreferencesConfirm': settingsResetConfirm,
    'resetPreferencesHint': settingsResetHint,
    'resetDone': settingsResetDone,
    'settingsFootnote': settingsFootnote,
    // 关于页 19 条
    'aboutTitle': aboutTitle,
    'aboutIntro': aboutIntro,
    'sectionVersion': aboutSectionVersion,
    'versionLabel': aboutVersionLabel,
    'checkUpdate': aboutCheckUpdate,
    'checking': aboutChecking,
    'noRelease': aboutNoRelease,
    'networkError': aboutNetworkError,
    'upToDate': aboutUpToDate,
    'newVersionAvailable': aboutNewVersion,
    'onlineUpgrade': aboutOnlineUpgrade,
    'onlineUpgradeDisabled': aboutOnlineUpgradeDisabled,
    'sectionRepository': aboutSectionRepository,
    'sectionDeveloper': aboutSectionDeveloper,
    'developerIntro': aboutDeveloperIntro,
    'sectionOtherSoftware': aboutSectionOtherSoftware,
    'alphaFileManagerIntro': aboutAlphaFileManager,
    'pageWeaverIntro': aboutPageWeaver,
    'unverifiedLink': aboutUnverifiedLink,
    // 跨页共用 7 条
    'cancel': commonCancel,
    'confirm': commonConfirm,
    'executablePath': commonExecutablePath,
    'operationFailed': commonOperationFailed,
    'copy': commonCopy,
    'copied': commonCopied,
    'open': commonOpen,
    // 优先级展示文案 12 条（W0.5 域层 id 化）
    'quadrantQ1Label': domainQuadrantQ1Label,
    'quadrantQ1ShortLabel': domainQuadrantQ1ShortLabel,
    'quadrantQ2Label': domainQuadrantQ2Label,
    'quadrantQ2ShortLabel': domainQuadrantQ2ShortLabel,
    'quadrantQ3Label': domainQuadrantQ3Label,
    'quadrantQ3ShortLabel': domainQuadrantQ3ShortLabel,
    'quadrantQ4Label': domainQuadrantQ4Label,
    'quadrantQ4ShortLabel': domainQuadrantQ4ShortLabel,
    'abcALabel': domainAbcALabel,
    'abcBLabel': domainAbcBLabel,
    'abcCLabel': domainAbcCLabel,
    'priorityUnsetLabel': domainPriorityUnsetLabel,
    // 关于页正文 7 条（W1 新增；另 2 条列表型见 byListGetter）
    'aboutChangelogTitle': aboutChangelogTitle,
    'aboutPrivacyTitle': aboutPrivacyTitle,
    'aboutPrivacy': aboutPrivacy,
    'aboutLicensesTitle': aboutLicensesTitle,
    'aboutLicenses': aboutLicenses,
    'aboutCopyResult': aboutCopyResult,
    'aboutReleases': aboutReleases,
    // 外壳 9 条（W1 新增）
    'appTitle': shellAppTitle,
    'appName': shellAppName,
    'windowMinimize': shellWindowMinimize,
    'windowMaximize': shellWindowMaximize,
    'windowRestore': shellWindowRestore,
    'windowClose': shellWindowClose,
    'trayShow': shellTrayShow,
    'trayHide': shellTrayHide,
    'trayQuit': shellTrayQuit,
    // 目标页 25 条（Task 65 UI 半批 B1：页壳 / 周视图 / 草稿滚动区）
    'goalsTitle': goalsTitle,
    'goalsTabWeek': goalsTabWeek,
    'goalsTabMonth': goalsTabMonth,
    'goalsTabYear': goalsTabYear,
    'goalsTabBlueprint': goalsTabBlueprint,
    'goalsUpstreamYearTitle': goalsUpstreamYearTitle,
    'goalsUpstreamMonthTitle': goalsUpstreamMonthTitle,
    'goalsUpstreamWeekTitle': goalsUpstreamWeekTitle,
    'goalsUpstreamAddHint': goalsUpstreamAddHint,
    'goalsUpstreamEmpty': goalsUpstreamEmpty,
    'goalsUpstreamAddMenu': goalsUpstreamAddMenu,
    'goalsWeekSection': goalsWeekSection,
    'goalsWeekEmpty': goalsWeekEmpty,
    'goalsColumnOrder': goalsColumnOrder,
    'goalsColumnGoal': goalsColumnGoal,
    'goalsColumnQuadrant': goalsColumnQuadrant,
    'goalsColumnDue': goalsColumnDue,
    'goalsColumnDone': goalsColumnDone,
    'goalsColumnServes': goalsColumnServes,
    'goalsCompletion': goalsCompletion,
    'goalsPlanItems': goalsPlanItems,
    'goalsUnplaced': goalsUnplaced,
    'goalsDraftSection': goalsDraftSection,
    'goalsDraftEmpty': goalsDraftEmpty,
    'goalsDraftConfirm': goalsDraftConfirm,
    'goalsDraftSaved': goalsDraftSaved,
    'goalsDraftCarryOver': goalsDraftCarryOver,
    'goalsDraftFromMonthly': goalsDraftFromMonthly,
    'goalsPlaceholderMonth': goalsPlaceholderMonth,
    'goalsPlaceholderYear': goalsPlaceholderYear,
    'goalsPlaceholderBlueprint': goalsPlaceholderBlueprint,
    // Task 66 UI 半批 B2：状态 4 + 共用 2 + 月 17 + 年 17 + 蓝图 18
    'goalStatusDraft': goalStatusDraft,
    'goalStatusActive': goalStatusActive,
    'goalStatusDone': goalStatusDone,
    'goalStatusCancelled': goalStatusCancelled,
    'goalSelfScore': goalSelfScore,
    'goalDraftPending': goalDraftPending,
    'goalMonthYearBar': goalMonthYearBar,
    'goalMonthReviewSection': goalMonthReviewSection,
    'goalMonthReviewEmpty': goalMonthReviewEmpty,
    'goalMonthReviewReason': goalMonthReviewReason,
    'goalMonthReviewReasonMissing': goalMonthReviewReasonMissing,
    'goalMonthImprove': goalMonthImprove,
    'goalMonthImproveEmpty': goalMonthImproveEmpty,
    'goalMonthConvertDraft': goalMonthConvertDraft,
    'goalMonthGoalsSection': goalMonthGoalsSection,
    'goalMonthGoalsEmpty': goalMonthGoalsEmpty,
    'goalMonthColumnCategory': goalMonthColumnCategory,
    'goalMonthColumnIndex': goalMonthColumnIndex,
    'goalMonthColumnMethods': goalMonthColumnMethods,
    'goalMonthColumnDone': goalMonthColumnDone,
    'goalMonthAdHoc': goalMonthAdHoc,
    'goalMonthServesYearly': goalMonthServesYearly,
    'goalMonthDraftEmpty': goalMonthDraftEmpty,
    'goalYearGoalsSection': goalYearGoalsSection,
    'goalYearGoalsEmpty': goalYearGoalsEmpty,
    'goalYearColumnPeriod': goalYearColumnPeriod,
    'goalYearMonthsSection': goalYearMonthsSection,
    'goalYearMonthColumn': goalYearMonthColumn,
    'goalYearCellEmpty': goalYearCellEmpty,
    'goalYearCellInputHint': goalYearCellInputHint,
    'goalYearCellAddDraft': goalYearCellAddDraft,
    'goalYearReviewSection': goalYearReviewSection,
    'goalYearReviewDone': goalYearReviewDone,
    'goalYearReviewScoreTotal': goalYearReviewScoreTotal,
    'goalYearReviewScoreAverage': goalYearReviewScoreAverage,
    'goalYearReviewSelfNote': goalYearReviewSelfNote,
    'goalYear8020Section': goalYear8020Section,
    'goalYear8020Empty': goalYear8020Empty,
    'goalYear8020Tracks': goalYear8020Tracks,
    'goalYearDraftEmpty': goalYearDraftEmpty,
    'goalBlueprintMatrixSection': goalBlueprintMatrixSection,
    'goalBlueprintColumnGoal': goalBlueprintColumnGoal,
    'goalBlueprintHorizonUltimate': goalBlueprintHorizonUltimate,
    'goalBlueprintHorizonLong': goalBlueprintHorizonLong,
    'goalBlueprintHorizonMid': goalBlueprintHorizonMid,
    'goalBlueprintHorizonShort': goalBlueprintHorizonShort,
    'goalBlueprintHorizonNear': goalBlueprintHorizonNear,
    'goalBlueprintEmptyCell': goalBlueprintEmptyCell,
    'goalBlueprintBlankRowHint': goalBlueprintBlankRowHint,
    'goalBlueprintNearSource': goalBlueprintNearSource,
    'goalBlueprintActionsCount': goalBlueprintActionsCount,
    'goalBlueprintWeeklyTarget': goalBlueprintWeeklyTarget,
    'goalBlueprintSplitTodos': goalBlueprintSplitTodos,
    'goalBlueprintPendingTodos': goalBlueprintPendingTodos,
    'goalBlueprintConfirmTodos': goalBlueprintConfirmTodos,
    'goalBlueprintBalanceSection': goalBlueprintBalanceSection,
    'goalBlueprintBalanceEmpty': goalBlueprintBalanceEmpty,
    'goalBlueprintBalanceHabit': goalBlueprintBalanceHabit,
    // 蓝图页目标编辑 12 条（B8-W1）
    'goalBlueprintAddGoal': goalBlueprintAddGoal,
    'goalBlueprintEditGoal': goalBlueprintEditGoal,
    'goalBlueprintDeleteGoal': goalBlueprintDeleteGoal,
    'goalBlueprintGoalSaved': goalBlueprintGoalSaved,
    'goalBlueprintGoalDeleted': goalBlueprintGoalDeleted,
    'goalBlueprintFieldDomain': goalBlueprintFieldDomain,
    'goalBlueprintFieldHorizon': goalBlueprintFieldHorizon,
    'goalBlueprintFieldNote': goalBlueprintFieldNote,
    'goalBlueprintFieldKeywords': goalBlueprintFieldKeywords,
    'goalBlueprintFieldDue': goalBlueprintFieldDue,
    'goalBlueprintFieldUnset': goalBlueprintFieldUnset,
    'goalBlueprintFieldDueInvalid': goalBlueprintFieldDueInvalid,
    // 应用外壳 25 条（Task 61 的 23 条 + Task 64 的 2 条：导航「目标」/ 快捷键「切到目标」）
    'shellNavToday': shellNavToday,
    'shellNavInbox': shellNavInbox,
    'shellNavHabits': shellNavHabits,
    'shellNavProjects': shellNavProjects,
    'shellNavCalendar': shellNavCalendar,
    'shellNavSettings': shellNavSettings,
    'shellNavGoals': shellNavGoals,
    'shellNavBlueprint': shellNavBlueprint,
    'shellNavBlueprintDesc': shellNavBlueprintDesc,
    'shellShortcutsTitle': shellShortcutsTitle,
    'shellPageSwitch': shellPageSwitch,
    'shellKeyAddEntry': shellKeyAddEntry,
    'shellKeyCheckFirstHabit': shellKeyCheckFirstHabit,
    'shellKeySwitchDate': shellKeySwitchDate,
    'shellKeyToggleCheck': shellKeyToggleCheck,
    'shellKeyExpandBackfill': shellKeyExpandBackfill,
    'shellKeyClosePopup': shellKeyClosePopup,
    'shellKeySwitchTab': shellKeySwitchTab,
    'shellKeyGoProjects': shellKeyGoProjects,
    'shellKeyGoGoals': shellKeyGoGoals,
    'shellPanelTodoList': shellPanelTodoList,
    'shellPanelAddTodo': shellPanelAddTodo,
    'shellPanelHabitOverview': shellPanelHabitOverview,
    'shellPanelAddHabit': shellPanelAddHabit,
    'shellPanelRecurringTasks': shellPanelRecurringTasks,
    'shellPanelAddRecurringTask': shellPanelAddRecurringTask,
    'shellPanelLoopHint': shellPanelLoopHint,
    // 项目页 48 条（Task 56 的 17 条 + Task 57 的 11 条 + 补轮 3 条 +
    // Task 59 的 11 条 + Stage 4 的 7 条）
    'projectsTitle': projectsTitle,
    'projectsSubtitle': projectsSubtitle,
    'projectsEmpty': projectsEmpty,
    'projectsNewProjectAction': projectsNewProjectAction,
    'projectsNameHint': projectsNameHint,
    'projectsGoalHint': projectsGoalHint,
    'projectsStartHint': projectsStartHint,
    'projectsEndHint': projectsEndHint,
    'projectsTaskTitleHint': projectsTaskTitleHint,
    'projectsTargetDateHint': projectsTargetDateHint,
    'projectsAddTaskAction': projectsAddTaskAction,
    'projectsRescheduleAction': projectsRescheduleAction,
    'projectsUnscheduled': projectsUnscheduled,
    'projectsNoTask': projectsNoTask,
    'projectsNoDateRange': projectsNoDateRange,
    'projectsEmptyChart': projectsEmptyChart,
    'projectsScheduleTodayAction': projectsScheduleTodayAction,
    'projectsScheduledOn': projectsScheduledOn,
    'projectsIncrementTitle': projectsIncrementTitle,
    'projectsIncrementEmptyAction': projectsIncrementEmptyAction,
    'projectsIncrementProgressHint': projectsIncrementProgressHint,
    'projectsIncrementBlockersHint': projectsIncrementBlockersHint,
    'projectsIncrementNextStepHint': projectsIncrementNextStepHint,
    'projectsIncrementAddAction': projectsIncrementAddAction,
    'projectsIncrementToTodayAction': projectsIncrementToTodayAction,
    'projectsIncrementAppendOnly': projectsIncrementAppendOnly,
    'projectsMilestoneOverdue': projectsMilestoneOverdue,
    // Task 57 补轮 3 条（摘录标注 + 回原文入口）
    'projectsIncrementExcerptTag': projectsIncrementExcerptTag,
    'projectsIncrementExcerptHint': projectsIncrementExcerptHint,
    'projectsIncrementOpenOriginalAction': projectsIncrementOpenOriginalAction,
    // Task 59 共 11 条（领域分布面板 + 所属领域字段）
    'projectsDomainStatsTitle': projectsDomainStatsTitle,
    'projectsDomainStatsUncategorized': projectsDomainStatsUncategorized,
    'projectsDomainStatsCount': projectsDomainStatsCount,
    'projectsDomainFieldLabel': projectsDomainFieldLabel,
    'projectsDomainUnset': projectsDomainUnset,
    'projectsDomainCareer': projectsDomainCareer,
    'projectsDomainWealth': projectsDomainWealth,
    'projectsDomainFamily': projectsDomainFamily,
    'projectsDomainLearning': projectsDomainLearning,
    'projectsDomainSocial': projectsDomainSocial,
    'projectsDomainHealth': projectsDomainHealth,
    // 校验失败 / 实体缺失 7 条（Stage 4：英文态可见中文收口）
    'projectsInvalidDateFormat': projectsInvalidDateFormat,
    'projectsDateNotExist': projectsDateNotExist,
    'projectsNameRequired': projectsNameRequired,
    'projectsTaskTitleRequired': projectsTaskTitleRequired,
    'projectsProgressRequired': projectsProgressRequired,
    'projectsMilestoneMissing': projectsMilestoneMissing,
    'projectsProjectMissing': projectsProjectMissing,
    'projectsSourceTypeInvalid': projectsSourceTypeInvalid,
    // 日历与日期 16 条（Task 61：日历页 / 月视图 / 日期条 / 日期选择弹层）
    'calendarPageTitle': calendarPageTitle,
    'calendarPrevMonth': calendarPrevMonth,
    'calendarNextMonth': calendarNextMonth,
    'calendarTodayBadge': calendarTodayBadge,
    'calendarPrevDay': calendarPrevDay,
    'calendarNextDay': calendarNextDay,
    'calendarBackfillMode': calendarBackfillMode,
    'calendarPrePlanMode': calendarPrePlanMode,
    'calendarPickerPrevMonth': calendarPickerPrevMonth,
    'calendarPickerNextMonth': calendarPickerNextMonth,
    'calendarToday': calendarToday,
    'calendarYesterday': calendarYesterday,
    'calendarDayBeforeYesterday': calendarDayBeforeYesterday,
    'calendarTomorrow': calendarTomorrow,
    'calendarThisWeek': calendarThisWeek,
    'calendarNoDeadline': calendarNoDeadline,
    // common 13 条（Task 63 轮二）
    'commonTitle': commonTitle,
    'commonSave': commonSave,
    'commonDelete': commonDelete,
    'commonClose': commonClose,
    'commonClear': commonClear,
    'commonClearPriority': commonClearPriority,
    'commonAxisImportant': commonAxisImportant,
    'commonAxisNotImportant': commonAxisNotImportant,
    'commonAxisUrgent': commonAxisUrgent,
    'commonAxisNotUrgent': commonAxisNotUrgent,
    'commonUnitTimes': commonUnitTimes,
    'commonUnitDay': commonUnitDay,
    'commonUnitWeek': commonUnitWeek,
    // domain 9 条（Task 63 轮二）
    'domainConclusionLabel': domainConclusionLabel,
    'domainReasonLabel': domainReasonLabel,
    'domainNextStepLabel': domainNextStepLabel,
    'domainPlanLabel': domainPlanLabel,
    'domainBackfillLabel': domainBackfillLabel,
    'domainReviewLabel': domainReviewLabel,
    'domainMoodLabel': domainMoodLabel,
    'domainDayLogNotStarted': domainDayLogNotStarted,
    'domainNoHabitsDueToday': domainNoHabitsDueToday,
    // domain 11 条（Task 68 W9）
    'mon': domainWeekdayMon,
    'tue': domainWeekdayTue,
    'wed': domainWeekdayWed,
    'thu': domainWeekdayThu,
    'fri': domainWeekdayFri,
    'sat': domainWeekdaySat,
    'sun': domainWeekdaySun,
    'every': domainRecurringEvery,
    'workdays': domainRecurringWorkdays,
    'weekend': domainRecurringWeekend,
    'none': domainRecurringNone,
    // timeline 30 条（Task 63 轮二）
    'timelineEmptyGridHint': timelineEmptyGridHint,
    'timelineHabitBackfill': timelineHabitBackfill,
    'timelinePlanTitleHint': timelinePlanTitleHint,
    'timelineScheduleAction': timelineScheduleAction,
    'timelineManualGroup': timelineManualGroup,
    'timelineManualEntry': timelineManualEntry,
    'timelineTodoGroup': timelineTodoGroup,
    'timelineTodoPoolEmpty': timelineTodoPoolEmpty,
    'timelineHabitGroup': timelineHabitGroup,
    'timelineHabitEmpty': timelineHabitEmpty,
    'timelineConfirmAction': timelineConfirmAction,
    'timelineStartLabel': timelineStartLabel,
    'timelineEndLabel': timelineEndLabel,
    'timelineDurationLabel': timelineDurationLabel,
    'timelineSlotFillTitle': timelineSlotFillTitle,
    'timelineOutcomeTemplateTitle': timelineOutcomeTemplateTitle,
    'timelineTaskDetailTitle': timelineTaskDetailTitle,
    'timelineContentLabel': timelineContentLabel,
    'timelineLevelLabel': timelineLevelLabel,
    'timelineBackfillContentLabel': timelineBackfillContentLabel,
    'timelineFutureDayBackfillBlocked': timelineFutureDayBackfillBlocked,
    'timelineDeletePlanItemTitle': timelineDeletePlanItemTitle,
    'timelineKindHabitLabel': timelineKindHabitLabel,
    'timelineKindDoneLabel': timelineKindDoneLabel,
    'timelineTodoLoadFailed': timelineTodoLoadFailed,
    'timelineTodoLoading': timelineTodoLoading,
    'timelineTodoEmpty': timelineTodoEmpty,
    'timelineTodoSlotted': timelineTodoSlotted,
    'timelineNodeGap': timelineNodeGap,
    'timelineNodeClosed': timelineNodeClosed,
    // today 44 条（Task 63 轮二）
    'todayReviewFutureTitle': todayReviewFutureTitle,
    'todayReviewFutureDetail': todayReviewFutureDetail,
    'todayFuturePlanOnly': todayFuturePlanOnly,
    'todayFuturePlanning': todayFuturePlanning,
    'todayChangeDate': todayChangeDate,
    'todayChangeTime': todayChangeTime,
    'todayClearTime': todayClearTime,
    'todayTimeUnset': todayTimeUnset,
    'todayPickStartTime': todayPickStartTime,
    'todayAddPlanHint': todayAddPlanHint,
    'todayAddManual': todayAddManual,
    'todayHabitLoadFailed': todayHabitLoadFailed,
    'todayHabitLoading': todayHabitLoading,
    'todayHabitEmpty': todayHabitEmpty,
    'todayStatPlanGap': todayStatPlanGap,
    'todayStatFillGap': todayStatFillGap,
    'todayStatWritten': todayStatWritten,
    'todayStatUnwritten': todayStatUnwritten,
    'todayStatRecorded': todayStatRecorded,
    'todayStatUnrecorded': todayStatUnrecorded,
    'todayStallDismiss': todayStallDismiss,
    'todayNoticeFutureCheckin': todayNoticeFutureCheckin,
    'todayGotIt': todayGotIt,
    'todayReviewFieldLearn': todayReviewFieldLearn,
    'todayReviewFieldLearnHint': todayReviewFieldLearnHint,
    'todayReviewFieldGood': todayReviewFieldGood,
    'todayReviewFieldGoodHint': todayReviewFieldGoodHint,
    'todayReviewFieldImprove': todayReviewFieldImprove,
    'todayReviewFieldImproveHint': todayReviewFieldImproveHint,
    'todayReviewSubtitle': todayReviewSubtitle,
    'todayReviewEmptyNotice': todayReviewEmptyNotice,
    'todayReviewPickProject': todayReviewPickProject,
    'todayReviewFileToProject': todayReviewFileToProject,
    'todayLoopRingA11y': todayLoopRingA11y,
    'todayLoopRingScale': todayLoopRingScale,
    'todayStandupTitle': todayStandupTitle,
    'todayStandupSubtitle': todayStandupSubtitle,
    'todayStandupEmpty': todayStandupEmpty,
    'todayStandupYesterday': todayStandupYesterday,
    'todayStandupYesterdayEmpty': todayStandupYesterdayEmpty,
    'todayStandupToday': todayStandupToday,
    'todayStandupTodayEmpty': todayStandupTodayEmpty,
    'todayStandupBlockers': todayStandupBlockers,
    'todayStandupBlockersEmpty': todayStandupBlockersEmpty,
    // habit 44 条（Task 63 轮二）
    'moodGroupDayTitle': moodGroupDayTitle,
    'moodGroupWeekTitle': moodGroupWeekTitle,
    'moodSectionSubtitle': moodSectionSubtitle,
    'moodClearAll': moodClearAll,
    'moodMarkFailed': moodMarkFailed,
    'moodNextActionLabel': moodNextActionLabel,
    'moodNextActionHint': moodNextActionHint,
    'moodNoteLabel': moodNoteLabel,
    'moodNoteHint': moodNoteHint,
    'moodUnrated': moodUnrated,
    'moodClearDimension': moodClearDimension,
    'moodDimFulfillmentLabel': moodDimFulfillmentLabel,
    'moodDimFulfillmentDesc': moodDimFulfillmentDesc,
    'moodDimEfficiencyLabel': moodDimEfficiencyLabel,
    'moodDimEfficiencyDesc': moodDimEfficiencyDesc,
    'moodDimPositiveMindLabel': moodDimPositiveMindLabel,
    'moodDimPositiveMindDesc': moodDimPositiveMindDesc,
    'moodDimSelfEfficacyLabel': moodDimSelfEfficacyLabel,
    'moodDimSelfEfficacyDesc': moodDimSelfEfficacyDesc,
    'moodDimContributionLabel': moodDimContributionLabel,
    'moodDimContributionDesc': moodDimContributionDesc,
    'moodLegacyDiligent': moodLegacyDiligent,
    'moodLegacyFast': moodLegacyFast,
    'moodLegacyKeepPromise': moodLegacyKeepPromise,
    'moodLegacyFinishTask': moodLegacyFinishTask,
    'moodLegacyOptimistic': moodLegacyOptimistic,
    'moodLegacyConfident': moodLegacyConfident,
    'moodLegacyLoveAndDedication': moodLegacyLoveAndDedication,
    'moodLegacyNoExcuses': moodLegacyNoExcuses,
    'habitSectionTitle': habitSectionTitle,
    'habitSectionSubtitle': habitSectionSubtitle,
    'habitSectionEmpty': habitSectionEmpty,
    'habitCheckinLoading': habitCheckinLoading,
    'habitCheckinError': habitCheckinError,
    'habitCheckinHeadTitle': habitCheckinHeadTitle,
    'habitCheckinHeadHint': habitCheckinHeadHint,
    'habitPageTitle': habitPageTitle,
    'habitPageFutureHint': habitPageFutureHint,
    'habitPageEmpty': habitPageEmpty,
    'priorityPickQuadrant': priorityPickQuadrant,
    'priorityPickAbc': priorityPickAbc,
    'priorityBubbleCurrent': priorityBubbleCurrent,
    'priorityBubbleReadonly': priorityBubbleReadonly,
    'priorityBubbleEditable': priorityBubbleEditable,
    // dialog 93 条（Task 63 轮二 73 条 + Stage 4 的 20 条）
    'dialogEstUnitMinute': dialogEstUnitMinute,
    'dialogEstUnitHour': dialogEstUnitHour,
    'dialogEstUnitDay': dialogEstUnitDay,
    'dialogEstUnitWeek': dialogEstUnitWeek,
    'dialogEstUnitMonth': dialogEstUnitMonth,
    'dialogHabitNameRequired': dialogHabitNameRequired,
    'dialogHabitWeekdayRequired': dialogHabitWeekdayRequired,
    'dialogHabitNameLabel': dialogHabitNameLabel,
    'dialogHabitNoteLabel': dialogHabitNoteLabel,
    'dialogHabitSchedule': dialogHabitSchedule,
    'dialogHabitDaily': dialogHabitDaily,
    'dialogHabitEveryDays': dialogHabitEveryDays,
    'dialogHabitEveryWeeks': dialogHabitEveryWeeks,
    'dialogHabitWeeklyPick': dialogHabitWeeklyPick,
    'dialogHabitEvery': dialogHabitEvery,
    'dialogHabitWeekday': dialogHabitWeekday,
    'dialogHabitStartDate': dialogHabitStartDate,
    'dialogHabitDailyMin': dialogHabitDailyMin,
    'dialogHabitCreate': dialogHabitCreate,
    'dialogHabitCreateSubtitle': dialogHabitCreateSubtitle,
    'dialogTodoTitleRequired': dialogTodoTitleRequired,
    'dialogTodoEstInvalid': dialogTodoEstInvalid,
    'dialogTodoCreateTitle': dialogTodoCreateTitle,
    'dialogTodoTitleHint': dialogTodoTitleHint,
    'dialogTodoEstLabel': dialogTodoEstLabel,
    'dialogTodoEstHint': dialogTodoEstHint,
    'dialogTodoPriorityLabel': dialogTodoPriorityLabel,
    'dialogTodoPullToday': dialogTodoPullToday,
    'dialogTodoSaving': dialogTodoSaving,
    'dialogTodoPullTitle': dialogTodoPullTitle,
    'dialogTodoPoolEmpty': dialogTodoPoolEmpty,
    'dialogTodoPulling': dialogTodoPulling,
    'dialogTodoPull': dialogTodoPull,
    'dialogRecurringWeekdayRequired': dialogRecurringWeekdayRequired,
    'dialogRecurringTimeInvalid': dialogRecurringTimeInvalid,
    'dialogRecurringDurationInvalid': dialogRecurringDurationInvalid,
    'dialogRecurringTitleLabel': dialogRecurringTitleLabel,
    'dialogRecurringStartLabel': dialogRecurringStartLabel,
    'dialogRecurringDurationLabel': dialogRecurringDurationLabel,
    'dialogRecurringNoteLabel': dialogRecurringNoteLabel,
    'dialogRecurringSaveConfirm': dialogRecurringSaveConfirm,
    'dialogRecurringCreateTitle': dialogRecurringCreateTitle,
    'dialogRecurringCreateSubtitle': dialogRecurringCreateSubtitle,
    'dialogRecurringDeleteTitle': dialogRecurringDeleteTitle,
    'dialogRecurringSection': dialogRecurringSection,
    'dialogRecurringLoading': dialogRecurringLoading,
    'dialogRecurringNone': dialogRecurringNone,
    'dialogRecurringNoneHint': dialogRecurringNoneHint,
    'dialogRecurringDaily': dialogRecurringDaily,
    'dialogRuleActiveOn': dialogRuleActiveOn,
    'dialogRuleActiveOff': dialogRuleActiveOff,
    'dialogRuleDisable': dialogRuleDisable,
    'dialogRuleEnable': dialogRuleEnable,
    'dialogDurationCustom': dialogDurationCustom,
    'dialogDurationCustomHint': dialogDurationCustomHint,
    'dialogNoteRestructure': dialogNoteRestructure,
    'dialogNoteNextStepLabel': dialogNoteNextStepLabel,
    'dialogNoteSaveProgressOnly': dialogNoteSaveProgressOnly,
    'dialogNoteDone': dialogNoteDone,
    // 结果撰写的三段短语 20 条（显示层；落库值本身在 outcome_composer.dart）
    'dialogOutcomeOnTime': dialogOutcomeOnTime,
    'dialogOutcomeLate': dialogOutcomeLate,
    'dialogOutcomeEarly': dialogOutcomeEarly,
    'dialogOutcomePartial': dialogOutcomePartial,
    'dialogOutcomeBlocked': dialogOutcomeBlocked,
    'dialogOutcomeDeferredTomorrow': dialogOutcomeDeferredTomorrow,
    'dialogReasonUnderestimated': dialogReasonUnderestimated,
    'dialogReasonInterrupted': dialogReasonInterrupted,
    'dialogReasonExternal': dialogReasonExternal,
    'dialogReasonPriorityChanged': dialogReasonPriorityChanged,
    'dialogReasonPoorState': dialogReasonPoorState,
    'dialogReasonNoTime': dialogReasonNoTime,
    'dialogReasonUnclear': dialogReasonUnclear,
    'dialogReasonOther': dialogReasonOther,
    'dialogNextStepContinueTomorrow': dialogNextStepContinueTomorrow,
    'dialogNextStepToTodo': dialogNextStepToTodo,
    'dialogNextStepHandOff': dialogNextStepHandOff,
    'dialogNextStepNarrowScope': dialogNextStepNarrowScope,
    'dialogNextStepReviewLater': dialogNextStepReviewLater,
    'dialogNextStepStopHere': dialogNextStepStopHere,
    'dialogPoolLoading': dialogPoolLoading,
    'dialogPoolTitle': dialogPoolTitle,
    'dialogPoolTitleHint': dialogPoolTitleHint,
    'dialogPoolStartHint': dialogPoolStartHint,
    'dialogPoolDueHint': dialogPoolDueHint,
    'dialogPoolNew': dialogPoolNew,
    'dialogPoolColPriority': dialogPoolColPriority,
    'dialogPoolColEst': dialogPoolColEst,
    'dialogPoolColQuadrant': dialogPoolColQuadrant,
    'dialogPoolColDue': dialogPoolColDue,
    'dialogPoolColAction': dialogPoolColAction,
    'dialogPoolStartInvalid': dialogPoolStartInvalid,
    'dialogPoolAddToToday': dialogPoolAddToToday,
    'dialogPoolEmptyLong': dialogPoolEmptyLong,
  };

  /// 列表型 getter 名 → 键（4 条；`byGetter` 只收 String getter）。
  ///
  /// 列表型 getter（`List<String>`）无法塞进 `Map<String, String>`，单列一张表，
  /// 好让测试同样能遍历「键一条不少 + 中英两态都非空且不同」。
  static const Map<String, String> byListGetter = <String, String>{
    'aboutToc': aboutToc,
    'aboutChangelog': aboutChangelog,
    'calendarWeekdaysShort': calendarWeekdaysShort,
    'domainWeekdayFull': domainWeekdayFull,
  };

  /// 插值方法名 → 键（53 条）。
  static const Map<String, String> byMethod = <String, String>{
    'hoursCount': domainHoursCount,
    'minutesCount': domainMinutesCount,
    'deferredDays': domainDeferredDays,
    'moodScoreLabel': domainMoodScoreLabel,
    'calendarMonthLabel': calendarMonthLabel,
    'calendarDateTitle': calendarDateTitle,
    // timeline 12 条（Task 63 轮二）
    'timelineSlotMenuTitle': timelineSlotMenuTitle,
    'timelineRangeTitle': timelineRangeTitle,
    'timelineTotalMinutes': timelineTotalMinutes,
    'timelineStepDown': timelineStepDown,
    'timelineStepUp': timelineStepUp,
    'timelineSlotPrompt': timelineSlotPrompt,
    'timelineWriteFailed': timelineWriteFailed,
    'timelineDeletePlanItemMessage': timelineDeletePlanItemMessage,
    'timelineHoverDetail': timelineHoverDetail,
    'timelineHoverNote': timelineHoverNote,
    'timelineHoverState': timelineHoverState,
    'timelineHoverLevel': timelineHoverLevel,
    // today 11 条（Task 63 轮二）
    'todayTimeSet': todayTimeSet,
    'todayDateLabel': todayDateLabel,
    'todayDateChipA11y': todayDateChipA11y,
    'todayGridStartHint': todayGridStartHint,
    'todayStallHint': todayStallHint,
    'todayHabitLoadError': todayHabitLoadError,
    'todayCheckedIn': todayCheckedIn,
    'todayCheckinFailed': todayCheckinFailed,
    'todayReviewFiledTo': todayReviewFiledTo,
    'todayReviewJoinSegments': todayReviewJoinSegments,
    'todayStandupSectionCount': todayStandupSectionCount,
    // habit 9 条（Task 63 轮二）
    'moodRatedCount': moodRatedCount,
    'moodAverage': moodAverage,
    'moodGroupHeader': moodGroupHeader,
    'moodGroupProgress': moodGroupProgress,
    'moodEvidence': moodEvidence,
    'habitTarget': habitTarget,
    'habitLoadFailed': habitLoadFailed,
    'habitCheckinLoadFailed': habitCheckinLoadFailed,
    'priorityBubbleA11y': priorityBubbleA11y,
    // dialog 15 条（Task 63 轮二）
    'dialogHabitSavedWarn': dialogHabitSavedWarn,
    'dialogTodoCreateSubtitle': dialogTodoCreateSubtitle,
    'dialogTodoPullSubtitle': dialogTodoPullSubtitle,
    'dialogRecurringBadDate': dialogRecurringBadDate,
    'dialogRecurringMergedWeekday': dialogRecurringMergedWeekday,
    'dialogRecurringTimeClamped': dialogRecurringTimeClamped,
    'dialogRuleActionFailed': dialogRuleActionFailed,
    'dialogRecurringDeleteMessage': dialogRecurringDeleteMessage,
    'dialogAutoScheduleFailed': dialogAutoScheduleFailed,
    'dialogRecurringLoadFailed': dialogRecurringLoadFailed,
    'dialogRecurringCount': dialogRecurringCount,
    'dialogRecurringSummary': dialogRecurringSummary,
    'dialogPoolAvailable': dialogPoolAvailable,
    'dialogPoolHead': dialogPoolHead,
    'dialogPoolScheduled': dialogPoolScheduled,
  };
}