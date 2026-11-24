// =============================================================================
// l10n 测试装置：中英双态 pump + 「键 → 取值」访问器表
// =============================================================================
// 为什么这些放在 test\ 而不是 lib\：它只为测试服务，进 lib 就是又造一层生产代码
// 里的转发（本项目明令不要 `AppStrings.xxx => t.xxx` 那种壳）。
//
// `l10nAccessors` 是**测试数据**：把 170 条 getter 一条一条列成「键 → 取值闭包」
// （列表型 3 条在 `l10nListAccessors`）。
// 有了它，测试才能不看 getter 名地遍历全部文案（校验非空、校验中英不同、校验
// 键数与条数一致）。新增 getter 时两侧都要加一行 —— 少了就会在
// `l10n_base_test.dart` 的「条数一致」用例上红。
//
// 用法（W1…W8 通用）：
//   await pumpL10n(tester, const SettingsPage());            // 中文态
//   await pumpL10n(tester, const SettingsPage(), language: AppLanguage.en);
//   expect(find.text(AppLocalizations.en.settingsTitle), findsOneWidget);
// 页面自己已经带 MaterialApp / ProviderScope 时，只用 `l10nScope(...)` 包一层，
// 不要用 `l10nWrap`（会套出两个 MaterialApp）。
// =============================================================================

import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/l10n/l10n_keys.dart';
import 'package:actlog/src/l10n/l10n_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 170 条 String getter 的访问器表：键 → 在当前语言下取该条文案。
final Map<String, String Function(AppLocalizations)> l10nAccessors =
    <String, String Function(AppLocalizations)>{
  // 设置页 35 条
  L10nKeys.settingsTitle: (AppLocalizations t) => t.settingsTitle,
  L10nKeys.settingsSubtitle: (AppLocalizations t) => t.settingsSubtitle,
  L10nKeys.settingsSectionAppearance: (AppLocalizations t) =>
      t.sectionAppearance,
  L10nKeys.settingsThemeSystem: (AppLocalizations t) => t.themeSystem,
  L10nKeys.settingsThemeLight: (AppLocalizations t) => t.themeLight,
  L10nKeys.settingsThemeDark: (AppLocalizations t) => t.themeDark,
  L10nKeys.settingsSectionLanguage: (AppLocalizations t) => t.sectionLanguage,
  L10nKeys.settingsLanguageZh: (AppLocalizations t) => t.languageChinese,
  L10nKeys.settingsLanguageEn: (AppLocalizations t) => t.languageEnglish,
  L10nKeys.settingsSectionSystem: (AppLocalizations t) => t.sectionSystem,
  L10nKeys.settingsLaunchOnBoot: (AppLocalizations t) => t.launchOnBoot,
  L10nKeys.settingsLaunchOnBootHint: (AppLocalizations t) => t.launchOnBootHint,
  L10nKeys.settingsDesktopShortcut: (AppLocalizations t) => t.desktopShortcut,
  L10nKeys.settingsDesktopShortcutHint: (AppLocalizations t) =>
      t.desktopShortcutHint,
  L10nKeys.settingsShortcutCreated: (AppLocalizations t) => t.shortcutCreated,
  L10nKeys.settingsSectionPlanWindow: (AppLocalizations t) =>
      t.sectionPlanWindow,
  L10nKeys.settingsPlanStart: (AppLocalizations t) => t.planStart,
  L10nKeys.settingsPlanEnd: (AppLocalizations t) => t.planEnd,
  L10nKeys.settingsPlanWindowHint: (AppLocalizations t) => t.planWindowHint,
  L10nKeys.settingsSectionData: (AppLocalizations t) => t.sectionData,
  L10nKeys.settingsOpenDataDir: (AppLocalizations t) => t.openDataDir,
  L10nKeys.settingsOpenDataDirHint: (AppLocalizations t) => t.openDataDirHint,
  L10nKeys.settingsSectionOther: (AppLocalizations t) => t.sectionOther,
  L10nKeys.settingsDensity: (AppLocalizations t) => t.density,
  L10nKeys.settingsDensityCompact: (AppLocalizations t) => t.densityCompact,
  L10nKeys.settingsDensityComfortable: (AppLocalizations t) =>
      t.densityComfortable,
  L10nKeys.settingsDensityRoomy: (AppLocalizations t) => t.densityRoomy,
  L10nKeys.settingsPriorityDisplayMode: (AppLocalizations t) =>
      t.priorityDisplayMode,
  L10nKeys.settingsPriorityQuadrant: (AppLocalizations t) => t.priorityQuadrant,
  L10nKeys.settingsPriorityAbc: (AppLocalizations t) => t.priorityAbc,
  L10nKeys.settingsReset: (AppLocalizations t) => t.resetPreferences,
  L10nKeys.settingsResetConfirm: (AppLocalizations t) =>
      t.resetPreferencesConfirm,
  L10nKeys.settingsResetHint: (AppLocalizations t) => t.resetPreferencesHint,
  L10nKeys.settingsResetDone: (AppLocalizations t) => t.resetDone,
  L10nKeys.settingsFootnote: (AppLocalizations t) => t.settingsFootnote,
  // 关于页 19 条
  L10nKeys.aboutTitle: (AppLocalizations t) => t.aboutTitle,
  L10nKeys.aboutIntro: (AppLocalizations t) => t.aboutIntro,
  L10nKeys.aboutSectionVersion: (AppLocalizations t) => t.sectionVersion,
  L10nKeys.aboutVersionLabel: (AppLocalizations t) => t.versionLabel,
  L10nKeys.aboutCheckUpdate: (AppLocalizations t) => t.checkUpdate,
  L10nKeys.aboutChecking: (AppLocalizations t) => t.checking,
  L10nKeys.aboutNoRelease: (AppLocalizations t) => t.noRelease,
  L10nKeys.aboutNetworkError: (AppLocalizations t) => t.networkError,
  L10nKeys.aboutUpToDate: (AppLocalizations t) => t.upToDate,
  L10nKeys.aboutNewVersion: (AppLocalizations t) => t.newVersionAvailable,
  L10nKeys.aboutOnlineUpgrade: (AppLocalizations t) => t.onlineUpgrade,
  L10nKeys.aboutOnlineUpgradeDisabled: (AppLocalizations t) =>
      t.onlineUpgradeDisabled,
  L10nKeys.aboutSectionRepository: (AppLocalizations t) => t.sectionRepository,
  L10nKeys.aboutSectionDeveloper: (AppLocalizations t) => t.sectionDeveloper,
  L10nKeys.aboutDeveloperIntro: (AppLocalizations t) => t.developerIntro,
  L10nKeys.aboutSectionOtherSoftware: (AppLocalizations t) =>
      t.sectionOtherSoftware,
  L10nKeys.aboutAlphaFileManager: (AppLocalizations t) =>
      t.alphaFileManagerIntro,
  L10nKeys.aboutPageWeaver: (AppLocalizations t) => t.pageWeaverIntro,
  L10nKeys.aboutUnverifiedLink: (AppLocalizations t) => t.unverifiedLink,
  // 关于页正文 7 条（W1 新增；列表型 2 条见 l10nListAccessors）
  L10nKeys.aboutChangelogTitle: (AppLocalizations t) => t.aboutChangelogTitle,
  L10nKeys.aboutPrivacyTitle: (AppLocalizations t) => t.aboutPrivacyTitle,
  L10nKeys.aboutPrivacy: (AppLocalizations t) => t.aboutPrivacy,
  L10nKeys.aboutLicensesTitle: (AppLocalizations t) => t.aboutLicensesTitle,
  L10nKeys.aboutLicenses: (AppLocalizations t) => t.aboutLicenses,
  L10nKeys.aboutCopyResult: (AppLocalizations t) => t.aboutCopyResult,
  L10nKeys.aboutReleases: (AppLocalizations t) => t.aboutReleases,
  // 外壳 9 条（W1 新增）
  L10nKeys.shellAppTitle: (AppLocalizations t) => t.appTitle,
  L10nKeys.shellAppName: (AppLocalizations t) => t.appName,
  L10nKeys.shellWindowMinimize: (AppLocalizations t) => t.windowMinimize,
  L10nKeys.shellWindowMaximize: (AppLocalizations t) => t.windowMaximize,
  L10nKeys.shellWindowRestore: (AppLocalizations t) => t.windowRestore,
  L10nKeys.shellWindowClose: (AppLocalizations t) => t.windowClose,
  L10nKeys.shellTrayShow: (AppLocalizations t) => t.trayShow,
  L10nKeys.shellTrayHide: (AppLocalizations t) => t.trayHide,
  L10nKeys.shellTrayQuit: (AppLocalizations t) => t.trayQuit,
  // 应用外壳 23 条（Task 61：左导航 / 快捷键面板 / 快捷键说明 / 右轨面板）
  L10nKeys.shellNavToday: (AppLocalizations t) => t.shellNavToday,
  L10nKeys.shellNavInbox: (AppLocalizations t) => t.shellNavInbox,
  L10nKeys.shellNavHabits: (AppLocalizations t) => t.shellNavHabits,
  L10nKeys.shellNavProjects: (AppLocalizations t) => t.shellNavProjects,
  L10nKeys.shellNavCalendar: (AppLocalizations t) => t.shellNavCalendar,
  L10nKeys.shellNavSettings: (AppLocalizations t) => t.shellNavSettings,
  L10nKeys.shellShortcutsTitle: (AppLocalizations t) => t.shellShortcutsTitle,
  L10nKeys.shellPageSwitch: (AppLocalizations t) => t.shellPageSwitch,
  L10nKeys.shellKeyAddEntry: (AppLocalizations t) => t.shellKeyAddEntry,
  L10nKeys.shellKeyCheckFirstHabit: (AppLocalizations t) =>
      t.shellKeyCheckFirstHabit,
  L10nKeys.shellKeySwitchDate: (AppLocalizations t) => t.shellKeySwitchDate,
  L10nKeys.shellKeyToggleCheck: (AppLocalizations t) => t.shellKeyToggleCheck,
  L10nKeys.shellKeyExpandBackfill: (AppLocalizations t) =>
      t.shellKeyExpandBackfill,
  L10nKeys.shellKeyClosePopup: (AppLocalizations t) => t.shellKeyClosePopup,
  L10nKeys.shellKeySwitchTab: (AppLocalizations t) => t.shellKeySwitchTab,
  L10nKeys.shellKeyGoProjects: (AppLocalizations t) => t.shellKeyGoProjects,
  L10nKeys.shellPanelTodoList: (AppLocalizations t) => t.shellPanelTodoList,
  L10nKeys.shellPanelAddTodo: (AppLocalizations t) => t.shellPanelAddTodo,
  L10nKeys.shellPanelHabitOverview: (AppLocalizations t) =>
      t.shellPanelHabitOverview,
  L10nKeys.shellPanelAddHabit: (AppLocalizations t) => t.shellPanelAddHabit,
  L10nKeys.shellPanelRecurringTasks: (AppLocalizations t) =>
      t.shellPanelRecurringTasks,
  L10nKeys.shellPanelAddRecurringTask: (AppLocalizations t) =>
      t.shellPanelAddRecurringTask,
  L10nKeys.shellPanelLoopHint: (AppLocalizations t) => t.shellPanelLoopHint,
  // 跨页共用 7 条
  L10nKeys.commonCancel: (AppLocalizations t) => t.cancel,
  L10nKeys.commonConfirm: (AppLocalizations t) => t.confirm,
  L10nKeys.commonExecutablePath: (AppLocalizations t) => t.executablePath,
  L10nKeys.commonOperationFailed: (AppLocalizations t) => t.operationFailed,
  L10nKeys.commonCopy: (AppLocalizations t) => t.copy,
  L10nKeys.commonCopied: (AppLocalizations t) => t.copied,
  L10nKeys.commonOpen: (AppLocalizations t) => t.open,
  // 域层文案 12 条（四象限 label/shortLabel + ABC label + 未分级）
  L10nKeys.domainQuadrantQ1Label: (AppLocalizations t) => t.quadrantQ1Label,
  L10nKeys.domainQuadrantQ1ShortLabel: (AppLocalizations t) =>
      t.quadrantQ1ShortLabel,
  L10nKeys.domainQuadrantQ2Label: (AppLocalizations t) => t.quadrantQ2Label,
  L10nKeys.domainQuadrantQ2ShortLabel: (AppLocalizations t) =>
      t.quadrantQ2ShortLabel,
  L10nKeys.domainQuadrantQ3Label: (AppLocalizations t) => t.quadrantQ3Label,
  L10nKeys.domainQuadrantQ3ShortLabel: (AppLocalizations t) =>
      t.quadrantQ3ShortLabel,
  L10nKeys.domainQuadrantQ4Label: (AppLocalizations t) => t.quadrantQ4Label,
  L10nKeys.domainQuadrantQ4ShortLabel: (AppLocalizations t) =>
      t.quadrantQ4ShortLabel,
  L10nKeys.domainAbcALabel: (AppLocalizations t) => t.abcALabel,
  L10nKeys.domainAbcBLabel: (AppLocalizations t) => t.abcBLabel,
  L10nKeys.domainAbcCLabel: (AppLocalizations t) => t.abcCLabel,
  L10nKeys.domainPriorityUnsetLabel: (AppLocalizations t) =>
      t.priorityUnsetLabel,
  // 项目页 42 条（Task 56 新增 17 条 + Task 57 新增 11 条 + 补轮 3 条 +
  // Task 59 新增 11 条）
  L10nKeys.projectsTitle: (AppLocalizations t) => t.projectsTitle,
  L10nKeys.projectsSubtitle: (AppLocalizations t) => t.projectsSubtitle,
  L10nKeys.projectsEmpty: (AppLocalizations t) => t.projectsEmpty,
  L10nKeys.projectsNewProjectAction: (AppLocalizations t) =>
      t.projectsNewProjectAction,
  L10nKeys.projectsNameHint: (AppLocalizations t) => t.projectsNameHint,
  L10nKeys.projectsGoalHint: (AppLocalizations t) => t.projectsGoalHint,
  L10nKeys.projectsStartHint: (AppLocalizations t) => t.projectsStartHint,
  L10nKeys.projectsEndHint: (AppLocalizations t) => t.projectsEndHint,
  L10nKeys.projectsTaskTitleHint: (AppLocalizations t) => t.projectsTaskTitleHint,
  L10nKeys.projectsTargetDateHint: (AppLocalizations t) =>
      t.projectsTargetDateHint,
  L10nKeys.projectsAddTaskAction: (AppLocalizations t) => t.projectsAddTaskAction,
  L10nKeys.projectsRescheduleAction: (AppLocalizations t) =>
      t.projectsRescheduleAction,
  L10nKeys.projectsUnscheduled: (AppLocalizations t) => t.projectsUnscheduled,
  L10nKeys.projectsNoTask: (AppLocalizations t) => t.projectsNoTask,
  L10nKeys.projectsNoDateRange: (AppLocalizations t) => t.projectsNoDateRange,
  L10nKeys.projectsEmptyChart: (AppLocalizations t) => t.projectsEmptyChart,
  L10nKeys.projectsLoadFailed: (AppLocalizations t) => t.projectsLoadFailed,
  L10nKeys.projectsScheduleTodayAction: (AppLocalizations t) =>
      t.projectsScheduleTodayAction,
  L10nKeys.projectsScheduledOn: (AppLocalizations t) => t.projectsScheduledOn,
  L10nKeys.projectsIncrementTitle: (AppLocalizations t) =>
      t.projectsIncrementTitle,
  L10nKeys.projectsIncrementEmptyAction: (AppLocalizations t) =>
      t.projectsIncrementEmptyAction,
  L10nKeys.projectsIncrementProgressHint: (AppLocalizations t) =>
      t.projectsIncrementProgressHint,
  L10nKeys.projectsIncrementBlockersHint: (AppLocalizations t) =>
      t.projectsIncrementBlockersHint,
  L10nKeys.projectsIncrementNextStepHint: (AppLocalizations t) =>
      t.projectsIncrementNextStepHint,
  L10nKeys.projectsIncrementAddAction: (AppLocalizations t) =>
      t.projectsIncrementAddAction,
  L10nKeys.projectsIncrementToTodayAction: (AppLocalizations t) =>
      t.projectsIncrementToTodayAction,
  L10nKeys.projectsIncrementAppendOnly: (AppLocalizations t) =>
      t.projectsIncrementAppendOnly,
  L10nKeys.projectsMilestoneOverdue: (AppLocalizations t) =>
      t.projectsMilestoneOverdue,
  // Task 57 补轮 3 条：摘录标注 + 回原文入口
  L10nKeys.projectsIncrementExcerptTag: (AppLocalizations t) =>
      t.projectsIncrementExcerptTag,
  L10nKeys.projectsIncrementExcerptHint: (AppLocalizations t) =>
      t.projectsIncrementExcerptHint,
  L10nKeys.projectsIncrementOpenOriginalAction: (AppLocalizations t) =>
      t.projectsIncrementOpenOriginalAction,
  // Task 59 共 11 条：领域分布面板 + 所属领域字段
  L10nKeys.projectsDomainStatsTitle: (AppLocalizations t) =>
      t.projectsDomainStatsTitle,
  L10nKeys.projectsDomainStatsUncategorized: (AppLocalizations t) =>
      t.projectsDomainStatsUncategorized,
  L10nKeys.projectsDomainStatsCount: (AppLocalizations t) =>
      t.projectsDomainStatsCount,
  L10nKeys.projectsDomainFieldLabel: (AppLocalizations t) =>
      t.projectsDomainFieldLabel,
  L10nKeys.projectsDomainUnset: (AppLocalizations t) => t.projectsDomainUnset,
  L10nKeys.projectsDomainCareer: (AppLocalizations t) => t.projectsDomainCareer,
  L10nKeys.projectsDomainWealth: (AppLocalizations t) => t.projectsDomainWealth,
  L10nKeys.projectsDomainFamily: (AppLocalizations t) => t.projectsDomainFamily,
  L10nKeys.projectsDomainLearning: (AppLocalizations t) =>
      t.projectsDomainLearning,
  L10nKeys.projectsDomainSocial: (AppLocalizations t) => t.projectsDomainSocial,
  L10nKeys.projectsDomainHealth: (AppLocalizations t) => t.projectsDomainHealth,
  // 日历与日期 16 条（Task 61：日历页 / 月视图 / 日期条 / 日期选择弹层）
  L10nKeys.calendarPageTitle: (AppLocalizations t) => t.calendarPageTitle,
  L10nKeys.calendarPrevMonth: (AppLocalizations t) => t.calendarPrevMonth,
  L10nKeys.calendarNextMonth: (AppLocalizations t) => t.calendarNextMonth,
  L10nKeys.calendarTodayBadge: (AppLocalizations t) => t.calendarTodayBadge,
  L10nKeys.calendarPrevDay: (AppLocalizations t) => t.calendarPrevDay,
  L10nKeys.calendarNextDay: (AppLocalizations t) => t.calendarNextDay,
  L10nKeys.calendarBackfillMode: (AppLocalizations t) => t.calendarBackfillMode,
  L10nKeys.calendarPrePlanMode: (AppLocalizations t) => t.calendarPrePlanMode,
  L10nKeys.calendarPickerPrevMonth: (AppLocalizations t) =>
      t.calendarPickerPrevMonth,
  L10nKeys.calendarPickerNextMonth: (AppLocalizations t) =>
      t.calendarPickerNextMonth,
  L10nKeys.calendarToday: (AppLocalizations t) => t.calendarToday,
  L10nKeys.calendarYesterday: (AppLocalizations t) => t.calendarYesterday,
  L10nKeys.calendarDayBeforeYesterday: (AppLocalizations t) =>
      t.calendarDayBeforeYesterday,
  L10nKeys.calendarTomorrow: (AppLocalizations t) => t.calendarTomorrow,
  L10nKeys.calendarThisWeek: (AppLocalizations t) => t.calendarThisWeek,
  L10nKeys.calendarNoDeadline: (AppLocalizations t) => t.calendarNoDeadline,
};

/// 列表型 getter（`List<String>`）的访问器表（3 条）。
///
/// 与 `l10nAccessors` 同一套键空间，只是取值返回 `List<String>`，所以单列一张
/// 表，避免把 `Map<String, String Function(...)>` 撑成动态类型。
final Map<String, List<String> Function(AppLocalizations)> l10nListAccessors =
    <String, List<String> Function(AppLocalizations)>{
  L10nKeys.aboutToc: (AppLocalizations t) => t.aboutToc,
  L10nKeys.aboutChangelog: (AppLocalizations t) => t.aboutChangelog,
  L10nKeys.calendarWeekdaysShort: (AppLocalizations t) =>
      t.calendarWeekdaysShort,
};

/// 允许中英同值的键（白名单）。
///
/// 只有两条，理由都是**产品事实**而非省事：
///  - `settings-language-zh`：语言选项要显示目标语言自己的写法，英文界面里
///    「简体中文」依然是「简体中文」；
///  - `settings-language-en`：「English」在中文界面里也写作「English」。
///
/// 白名单必须保持最小：往里加一条，就等于放弃了「这个 key 到底翻了没有」的
/// 自动检查。
const Set<String> sameValueWhitelist = <String>{
  L10nKeys.settingsLanguageZh,
  L10nKeys.settingsLanguageEn,
};

/// 只包一层 [L10nScope]，不加 MaterialApp —— 给「页面自己已经有 MaterialApp /
/// ProviderScope」的测试用。
Widget l10nScope(Widget child, {AppLanguage language = AppLanguage.zh}) =>
    L10nScope(
      localizations: AppLocalizations.forLanguage(language),
      child: child,
    );

/// 包 [L10nScope] + `MaterialApp` —— 给只测一段控件的测试用。
Widget l10nWrap(Widget child, {AppLanguage language = AppLanguage.zh}) =>
    l10nScope(MaterialApp(home: child), language: language);

/// 以指定语言 pump 被测 widget（默认中文态）。
Future<void> pumpL10n(
  WidgetTester tester,
  Widget child, {
  AppLanguage language = AppLanguage.zh,
}) async {
  await tester.pumpWidget(l10nWrap(child, language: language));
}