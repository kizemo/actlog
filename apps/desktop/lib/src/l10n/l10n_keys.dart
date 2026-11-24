// =============================================================================
// 文案键表：camelCase getter 名 ↔ kebab-case 稳定键
// =============================================================================
// 这层**不做转发**。它不进渲染路径 —— 页面上仍然写 `t.settingsTitle`，编译器
// 仍然保证漏翻是 error。键的作用只有两个：
//   1. 测试能遍历 key 集合，校验「170 条 getter 一条不少」「中英两态都不为空」
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
  // 设置页（parts\settings.dart，35 条）
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

  /// 分组：数据。
  static const String settingsSectionData = 'settings-section-data';

  /// 打开数据目录。
  static const String settingsOpenDataDir = 'settings-open-data-dir';

  /// 打开数据目录说明。
  static const String settingsOpenDataDirHint = 'settings-open-data-dir-hint';

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
  // 跨页共用（parts\common.dart，7 条）
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

  // ---------------------------------------------------------------------------
  // 项目页（parts\projects.dart，42 条）
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

  /// 项目页加载失败。
  static const String projectsLoadFailed = 'projects-load-failed';

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
  // 对照表
  // ---------------------------------------------------------------------------

  /// getter 名 → 键（170 条，覆盖 `AppLocalizations` 全部无参 String getter；
  /// 另有 3 条列表型 getter 在 `byListGetter`）。
  ///
  /// 顺序与 `parts\*.dart` 的声明顺序一致，方便对读。
  static const Map<String, String> byGetter = <String, String>{
    // 设置页 35 条
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
    'sectionData': settingsSectionData,
    'openDataDir': settingsOpenDataDir,
    'openDataDirHint': settingsOpenDataDirHint,
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
    // 应用外壳 23 条（Task 61：左导航 / 快捷键面板 / 快捷键说明 / 右轨面板）
    'shellNavToday': shellNavToday,
    'shellNavInbox': shellNavInbox,
    'shellNavHabits': shellNavHabits,
    'shellNavProjects': shellNavProjects,
    'shellNavCalendar': shellNavCalendar,
    'shellNavSettings': shellNavSettings,
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
    'shellPanelTodoList': shellPanelTodoList,
    'shellPanelAddTodo': shellPanelAddTodo,
    'shellPanelHabitOverview': shellPanelHabitOverview,
    'shellPanelAddHabit': shellPanelAddHabit,
    'shellPanelRecurringTasks': shellPanelRecurringTasks,
    'shellPanelAddRecurringTask': shellPanelAddRecurringTask,
    'shellPanelLoopHint': shellPanelLoopHint,
    // 项目页 42 条（Task 56 的 17 条 + Task 57 的 11 条 + 补轮 3 条 +
    // Task 59 的 11 条）
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
    'projectsLoadFailed': projectsLoadFailed,
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
  };

  /// 列表型 getter 名 → 键（3 条；`byGetter` 只收 String getter）。
  ///
  /// 列表型 getter（`List<String>`）无法塞进 `Map<String, String>`，单列一张表，
  /// 好让测试同样能遍历「键一条不少 + 中英两态都非空且不同」。
  static const Map<String, String> byListGetter = <String, String>{
    'aboutToc': aboutToc,
    'aboutChangelog': aboutChangelog,
    'calendarWeekdaysShort': calendarWeekdaysShort,
  };

  /// 插值方法名 → 键（6 条）。
  static const Map<String, String> byMethod = <String, String>{
    'hoursCount': domainHoursCount,
    'minutesCount': domainMinutesCount,
    'deferredDays': domainDeferredDays,
    'moodScoreLabel': domainMoodScoreLabel,
    'calendarMonthLabel': calendarMonthLabel,
    'calendarDateTitle': calendarDateTitle,
  };
}