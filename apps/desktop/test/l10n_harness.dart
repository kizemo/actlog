// =============================================================================
// l10n 测试装置：中英双态 pump + 「键 → 取值」访问器表
// =============================================================================
// 为什么这些放在 test\ 而不是 lib\：它只为测试服务，进 lib 就是又造一层生产代码
// 里的转发（本项目明令不要 `AppStrings.xxx => t.xxx` 那种壳）。
//
// `l10nAccessors` 是**测试数据**：把 523 条 getter 一条一条列成「键 → 取值闭包」
// （列表型 4 条在 `l10nListAccessors`）。
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

/// 523 条 String getter 的访问器表：键 → 在当前语言下取该条文案。
final Map<String, String Function(AppLocalizations)> l10nAccessors =
    <String, String Function(AppLocalizations)>{
  // 设置页 32 条
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
  // 目标页 25 条（Task 65 UI 半批 B1：页壳 / 周视图 / 草稿滚动区）
  L10nKeys.goalsTitle: (AppLocalizations t) => t.goalsTitle,
  L10nKeys.goalsTabWeek: (AppLocalizations t) => t.goalsTabWeek,
  L10nKeys.goalsTabMonth: (AppLocalizations t) => t.goalsTabMonth,
  L10nKeys.goalsTabYear: (AppLocalizations t) => t.goalsTabYear,
  L10nKeys.goalsTabBlueprint: (AppLocalizations t) => t.goalsTabBlueprint,
  // 未完成目标上游面板 6 条（Batch 7 · D-72-c）
  L10nKeys.goalsUpstreamYearTitle: (AppLocalizations t) =>
      t.goalsUpstreamYearTitle,
  L10nKeys.goalsUpstreamMonthTitle: (AppLocalizations t) =>
      t.goalsUpstreamMonthTitle,
  L10nKeys.goalsUpstreamWeekTitle: (AppLocalizations t) =>
      t.goalsUpstreamWeekTitle,
  L10nKeys.goalsUpstreamAddHint: (AppLocalizations t) => t.goalsUpstreamAddHint,
  L10nKeys.goalsUpstreamEmpty: (AppLocalizations t) => t.goalsUpstreamEmpty,
  L10nKeys.goalsUpstreamAddMenu: (AppLocalizations t) => t.goalsUpstreamAddMenu,
  L10nKeys.goalsWeekSection: (AppLocalizations t) => t.goalsWeekSection,
  L10nKeys.goalsWeekEmpty: (AppLocalizations t) => t.goalsWeekEmpty,
  L10nKeys.goalsColumnOrder: (AppLocalizations t) => t.goalsColumnOrder,
  L10nKeys.goalsColumnGoal: (AppLocalizations t) => t.goalsColumnGoal,
  L10nKeys.goalsColumnQuadrant: (AppLocalizations t) => t.goalsColumnQuadrant,
  L10nKeys.goalsColumnDue: (AppLocalizations t) => t.goalsColumnDue,
  L10nKeys.goalsColumnDone: (AppLocalizations t) => t.goalsColumnDone,
  L10nKeys.goalsColumnServes: (AppLocalizations t) => t.goalsColumnServes,
  L10nKeys.goalsCompletion: (AppLocalizations t) => t.goalsCompletion,
  L10nKeys.goalsPlanItems: (AppLocalizations t) => t.goalsPlanItems,
  L10nKeys.goalsUnplaced: (AppLocalizations t) => t.goalsUnplaced,
  L10nKeys.goalsDraftSection: (AppLocalizations t) => t.goalsDraftSection,
  L10nKeys.goalsDraftEmpty: (AppLocalizations t) => t.goalsDraftEmpty,
  L10nKeys.goalsDraftConfirm: (AppLocalizations t) => t.goalsDraftConfirm,
  L10nKeys.goalsDraftSaved: (AppLocalizations t) => t.goalsDraftSaved,
  L10nKeys.goalsDraftCarryOver: (AppLocalizations t) => t.goalsDraftCarryOver,
  L10nKeys.goalsDraftFromMonthly: (AppLocalizations t) => t.goalsDraftFromMonthly,
  L10nKeys.goalsPlaceholderMonth: (AppLocalizations t) => t.goalsPlaceholderMonth,
  L10nKeys.goalsPlaceholderYear: (AppLocalizations t) => t.goalsPlaceholderYear,
  L10nKeys.goalsPlaceholderBlueprint: (AppLocalizations t) =>
      t.goalsPlaceholderBlueprint,
  // 目标页 58 条（Task 66 UI 半批 B2：状态 4 + 共用 2 + 月 17 + 年 17 + 蓝图 18）
  L10nKeys.goalStatusDraft: (AppLocalizations t) => t.goalStatusDraft,
  L10nKeys.goalStatusActive: (AppLocalizations t) => t.goalStatusActive,
  L10nKeys.goalStatusDone: (AppLocalizations t) => t.goalStatusDone,
  L10nKeys.goalStatusCancelled: (AppLocalizations t) => t.goalStatusCancelled,
  L10nKeys.goalSelfScore: (AppLocalizations t) => t.goalSelfScore,
  L10nKeys.goalDraftPending: (AppLocalizations t) => t.goalDraftPending,
  L10nKeys.goalMonthYearBar: (AppLocalizations t) => t.goalMonthYearBar,
  L10nKeys.goalMonthReviewSection: (AppLocalizations t) =>
      t.goalMonthReviewSection,
  L10nKeys.goalMonthReviewEmpty: (AppLocalizations t) => t.goalMonthReviewEmpty,
  L10nKeys.goalMonthReviewReason: (AppLocalizations t) => t.goalMonthReviewReason,
  L10nKeys.goalMonthReviewReasonMissing: (AppLocalizations t) =>
      t.goalMonthReviewReasonMissing,
  L10nKeys.goalMonthImprove: (AppLocalizations t) => t.goalMonthImprove,
  L10nKeys.goalMonthImproveEmpty: (AppLocalizations t) => t.goalMonthImproveEmpty,
  L10nKeys.goalMonthConvertDraft: (AppLocalizations t) => t.goalMonthConvertDraft,
  L10nKeys.goalMonthGoalsSection: (AppLocalizations t) =>
      t.goalMonthGoalsSection,
  L10nKeys.goalMonthGoalsEmpty: (AppLocalizations t) => t.goalMonthGoalsEmpty,
  L10nKeys.goalMonthColumnCategory: (AppLocalizations t) =>
      t.goalMonthColumnCategory,
  L10nKeys.goalMonthColumnIndex: (AppLocalizations t) => t.goalMonthColumnIndex,
  L10nKeys.goalMonthColumnMethods: (AppLocalizations t) =>
      t.goalMonthColumnMethods,
  L10nKeys.goalMonthColumnDone: (AppLocalizations t) => t.goalMonthColumnDone,
  L10nKeys.goalMonthAdHoc: (AppLocalizations t) => t.goalMonthAdHoc,
  L10nKeys.goalMonthServesYearly: (AppLocalizations t) => t.goalMonthServesYearly,
  L10nKeys.goalMonthDraftEmpty: (AppLocalizations t) => t.goalMonthDraftEmpty,
  L10nKeys.goalYearGoalsSection: (AppLocalizations t) => t.goalYearGoalsSection,
  L10nKeys.goalYearGoalsEmpty: (AppLocalizations t) => t.goalYearGoalsEmpty,
  L10nKeys.goalYearColumnPeriod: (AppLocalizations t) => t.goalYearColumnPeriod,
  L10nKeys.goalYearMonthsSection: (AppLocalizations t) => t.goalYearMonthsSection,
  L10nKeys.goalYearMonthColumn: (AppLocalizations t) => t.goalYearMonthColumn,
  L10nKeys.goalYearCellEmpty: (AppLocalizations t) => t.goalYearCellEmpty,
  L10nKeys.goalYearCellInputHint: (AppLocalizations t) =>
      t.goalYearCellInputHint,
  L10nKeys.goalYearCellAddDraft: (AppLocalizations t) => t.goalYearCellAddDraft,
  L10nKeys.goalYearReviewSection: (AppLocalizations t) => t.goalYearReviewSection,
  L10nKeys.goalYearReviewDone: (AppLocalizations t) => t.goalYearReviewDone,
  L10nKeys.goalYearReviewScoreTotal: (AppLocalizations t) =>
      t.goalYearReviewScoreTotal,
  L10nKeys.goalYearReviewScoreAverage: (AppLocalizations t) =>
      t.goalYearReviewScoreAverage,
  L10nKeys.goalYearReviewSelfNote: (AppLocalizations t) =>
      t.goalYearReviewSelfNote,
  L10nKeys.goalYear8020Section: (AppLocalizations t) => t.goalYear8020Section,
  L10nKeys.goalYear8020Empty: (AppLocalizations t) => t.goalYear8020Empty,
  L10nKeys.goalYear8020Tracks: (AppLocalizations t) => t.goalYear8020Tracks,
  L10nKeys.goalYearDraftEmpty: (AppLocalizations t) => t.goalYearDraftEmpty,
  L10nKeys.goalBlueprintMatrixSection: (AppLocalizations t) =>
      t.goalBlueprintMatrixSection,
  L10nKeys.goalBlueprintColumnGoal: (AppLocalizations t) =>
      t.goalBlueprintColumnGoal,
  L10nKeys.goalBlueprintHorizonUltimate: (AppLocalizations t) =>
      t.goalBlueprintHorizonUltimate,
  L10nKeys.goalBlueprintHorizonLong: (AppLocalizations t) =>
      t.goalBlueprintHorizonLong,
  L10nKeys.goalBlueprintHorizonMid: (AppLocalizations t) =>
      t.goalBlueprintHorizonMid,
  L10nKeys.goalBlueprintHorizonShort: (AppLocalizations t) =>
      t.goalBlueprintHorizonShort,
  L10nKeys.goalBlueprintHorizonNear: (AppLocalizations t) =>
      t.goalBlueprintHorizonNear,
  L10nKeys.goalBlueprintEmptyCell: (AppLocalizations t) =>
      t.goalBlueprintEmptyCell,
  L10nKeys.goalBlueprintBlankRowHint: (AppLocalizations t) =>
      t.goalBlueprintBlankRowHint,
  L10nKeys.goalBlueprintNearSource: (AppLocalizations t) =>
      t.goalBlueprintNearSource,
  L10nKeys.goalBlueprintActionsCount: (AppLocalizations t) =>
      t.goalBlueprintActionsCount,
  L10nKeys.goalBlueprintWeeklyTarget: (AppLocalizations t) =>
      t.goalBlueprintWeeklyTarget,
  L10nKeys.goalBlueprintSplitTodos: (AppLocalizations t) =>
      t.goalBlueprintSplitTodos,
  L10nKeys.goalBlueprintPendingTodos: (AppLocalizations t) =>
      t.goalBlueprintPendingTodos,
  L10nKeys.goalBlueprintConfirmTodos: (AppLocalizations t) =>
      t.goalBlueprintConfirmTodos,
  L10nKeys.goalBlueprintBalanceSection: (AppLocalizations t) =>
      t.goalBlueprintBalanceSection,
  L10nKeys.goalBlueprintBalanceEmpty: (AppLocalizations t) =>
      t.goalBlueprintBalanceEmpty,
  L10nKeys.goalBlueprintBalanceHabit: (AppLocalizations t) =>
      t.goalBlueprintBalanceHabit,
  // 蓝图页目标编辑 12 条（B8-W1）
  L10nKeys.goalBlueprintAddGoal: (AppLocalizations t) => t.goalBlueprintAddGoal,
  L10nKeys.goalBlueprintEditGoal: (AppLocalizations t) =>
      t.goalBlueprintEditGoal,
  L10nKeys.goalBlueprintDeleteGoal: (AppLocalizations t) =>
      t.goalBlueprintDeleteGoal,
  L10nKeys.goalBlueprintGoalSaved: (AppLocalizations t) =>
      t.goalBlueprintGoalSaved,
  L10nKeys.goalBlueprintGoalDeleted: (AppLocalizations t) =>
      t.goalBlueprintGoalDeleted,
  L10nKeys.goalBlueprintFieldDomain: (AppLocalizations t) =>
      t.goalBlueprintFieldDomain,
  L10nKeys.goalBlueprintFieldHorizon: (AppLocalizations t) =>
      t.goalBlueprintFieldHorizon,
  L10nKeys.goalBlueprintFieldNote: (AppLocalizations t) =>
      t.goalBlueprintFieldNote,
  L10nKeys.goalBlueprintFieldKeywords: (AppLocalizations t) =>
      t.goalBlueprintFieldKeywords,
  L10nKeys.goalBlueprintFieldDue: (AppLocalizations t) =>
      t.goalBlueprintFieldDue,
  L10nKeys.goalBlueprintFieldUnset: (AppLocalizations t) =>
      t.goalBlueprintFieldUnset,
  L10nKeys.goalBlueprintFieldDueInvalid: (AppLocalizations t) =>
      t.goalBlueprintFieldDueInvalid,
  // 应用外壳 25 条（Task 61 的 23 条 + Task 64 的 2 条）
  L10nKeys.shellNavToday: (AppLocalizations t) => t.shellNavToday,
  L10nKeys.shellNavInbox: (AppLocalizations t) => t.shellNavInbox,
  L10nKeys.shellNavHabits: (AppLocalizations t) => t.shellNavHabits,
  L10nKeys.shellNavProjects: (AppLocalizations t) => t.shellNavProjects,
  L10nKeys.shellNavCalendar: (AppLocalizations t) => t.shellNavCalendar,
  L10nKeys.shellNavSettings: (AppLocalizations t) => t.shellNavSettings,
  L10nKeys.shellNavGoals: (AppLocalizations t) => t.shellNavGoals,
  // 左栏第 7 项「蓝图」2 条（Batch 7 · D-72-a / D-72-b）
  L10nKeys.shellNavBlueprint: (AppLocalizations t) => t.shellNavBlueprint,
  L10nKeys.shellNavBlueprintDesc: (AppLocalizations t) =>
      t.shellNavBlueprintDesc,
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
  L10nKeys.shellKeyGoGoals: (AppLocalizations t) => t.shellKeyGoGoals,
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
  // 项目页 48 条（Task 56 新增 17 条 + Task 57 新增 11 条 + 补轮 3 条 +
  // Task 59 新增 11 条 + Stage 4 新增 7 条）
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
  // 校验失败 / 实体缺失 7 条（Stage 4：英文态可见中文收口）
  L10nKeys.projectsInvalidDateFormat: (AppLocalizations t) =>
      t.projectsInvalidDateFormat,
  L10nKeys.projectsDateNotExist: (AppLocalizations t) => t.projectsDateNotExist,
  L10nKeys.projectsNameRequired: (AppLocalizations t) => t.projectsNameRequired,
  L10nKeys.projectsTaskTitleRequired: (AppLocalizations t) =>
      t.projectsTaskTitleRequired,
  L10nKeys.projectsProgressRequired: (AppLocalizations t) =>
      t.projectsProgressRequired,
  L10nKeys.projectsMilestoneMissing: (AppLocalizations t) =>
      t.projectsMilestoneMissing,
  L10nKeys.projectsProjectMissing: (AppLocalizations t) =>
      t.projectsProjectMissing,
  L10nKeys.projectsSourceTypeInvalid: (AppLocalizations t) =>
      t.projectsSourceTypeInvalid,
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
  // common 13 条（Task 63 轮二）
  L10nKeys.commonTitle: (AppLocalizations t) => t.commonTitle,
  L10nKeys.commonSave: (AppLocalizations t) => t.commonSave,
  L10nKeys.commonDelete: (AppLocalizations t) => t.commonDelete,
  L10nKeys.commonClose: (AppLocalizations t) => t.commonClose,
  L10nKeys.commonClear: (AppLocalizations t) => t.commonClear,
  L10nKeys.commonClearPriority: (AppLocalizations t) => t.commonClearPriority,
  L10nKeys.commonAxisImportant: (AppLocalizations t) => t.commonAxisImportant,
  L10nKeys.commonAxisNotImportant: (AppLocalizations t) =>
      t.commonAxisNotImportant,
  L10nKeys.commonAxisUrgent: (AppLocalizations t) => t.commonAxisUrgent,
  L10nKeys.commonAxisNotUrgent: (AppLocalizations t) => t.commonAxisNotUrgent,
  L10nKeys.commonUnitTimes: (AppLocalizations t) => t.commonUnitTimes,
  L10nKeys.commonUnitDay: (AppLocalizations t) => t.commonUnitDay,
  L10nKeys.commonUnitWeek: (AppLocalizations t) => t.commonUnitWeek,
  // domain 9 条（Task 63 轮二）
  L10nKeys.domainConclusionLabel: (AppLocalizations t) =>
      t.domainConclusionLabel,
  L10nKeys.domainReasonLabel: (AppLocalizations t) => t.domainReasonLabel,
  L10nKeys.domainNextStepLabel: (AppLocalizations t) => t.domainNextStepLabel,
  L10nKeys.domainPlanLabel: (AppLocalizations t) => t.domainPlanLabel,
  L10nKeys.domainBackfillLabel: (AppLocalizations t) => t.domainBackfillLabel,
  L10nKeys.domainReviewLabel: (AppLocalizations t) => t.domainReviewLabel,
  L10nKeys.domainMoodLabel: (AppLocalizations t) => t.domainMoodLabel,
  L10nKeys.domainDayLogNotStarted: (AppLocalizations t) =>
      t.domainDayLogNotStarted,
  L10nKeys.domainNoHabitsDueToday: (AppLocalizations t) =>
      t.domainNoHabitsDueToday,
  // domain 11 条（Task 68 W9）
  L10nKeys.domainWeekdayMon: (AppLocalizations t) => t.mon,
  L10nKeys.domainWeekdayTue: (AppLocalizations t) => t.tue,
  L10nKeys.domainWeekdayWed: (AppLocalizations t) => t.wed,
  L10nKeys.domainWeekdayThu: (AppLocalizations t) => t.thu,
  L10nKeys.domainWeekdayFri: (AppLocalizations t) => t.fri,
  L10nKeys.domainWeekdaySat: (AppLocalizations t) => t.sat,
  L10nKeys.domainWeekdaySun: (AppLocalizations t) => t.sun,
  L10nKeys.domainRecurringEvery: (AppLocalizations t) => t.every,
  L10nKeys.domainRecurringWorkdays: (AppLocalizations t) => t.workdays,
  L10nKeys.domainRecurringWeekend: (AppLocalizations t) => t.weekend,
  L10nKeys.domainRecurringNone: (AppLocalizations t) => t.none,
  // timeline 30 条（Task 63 轮二）
  L10nKeys.timelineEmptyGridHint: (AppLocalizations t) =>
      t.timelineEmptyGridHint,
  L10nKeys.timelineHabitBackfill: (AppLocalizations t) =>
      t.timelineHabitBackfill,
  L10nKeys.timelinePlanTitleHint: (AppLocalizations t) =>
      t.timelinePlanTitleHint,
  L10nKeys.timelineScheduleAction: (AppLocalizations t) =>
      t.timelineScheduleAction,
  L10nKeys.timelineManualGroup: (AppLocalizations t) => t.timelineManualGroup,
  L10nKeys.timelineManualEntry: (AppLocalizations t) => t.timelineManualEntry,
  L10nKeys.timelineTodoGroup: (AppLocalizations t) => t.timelineTodoGroup,
  L10nKeys.timelineTodoPoolEmpty: (AppLocalizations t) =>
      t.timelineTodoPoolEmpty,
  L10nKeys.timelineHabitGroup: (AppLocalizations t) => t.timelineHabitGroup,
  L10nKeys.timelineHabitEmpty: (AppLocalizations t) => t.timelineHabitEmpty,
  L10nKeys.timelineConfirmAction: (AppLocalizations t) =>
      t.timelineConfirmAction,
  L10nKeys.timelineStartLabel: (AppLocalizations t) => t.timelineStartLabel,
  L10nKeys.timelineEndLabel: (AppLocalizations t) => t.timelineEndLabel,
  L10nKeys.timelineDurationLabel: (AppLocalizations t) =>
      t.timelineDurationLabel,
  L10nKeys.timelineSlotFillTitle: (AppLocalizations t) =>
      t.timelineSlotFillTitle,
  L10nKeys.timelineOutcomeTemplateTitle: (AppLocalizations t) =>
      t.timelineOutcomeTemplateTitle,
  L10nKeys.timelineTaskDetailTitle: (AppLocalizations t) =>
      t.timelineTaskDetailTitle,
  L10nKeys.timelineContentLabel: (AppLocalizations t) => t.timelineContentLabel,
  L10nKeys.timelineLevelLabel: (AppLocalizations t) => t.timelineLevelLabel,
  L10nKeys.timelineBackfillContentLabel: (AppLocalizations t) =>
      t.timelineBackfillContentLabel,
  L10nKeys.timelineFutureDayBackfillBlocked: (AppLocalizations t) =>
      t.timelineFutureDayBackfillBlocked,
  L10nKeys.timelineDeletePlanItemTitle: (AppLocalizations t) =>
      t.timelineDeletePlanItemTitle,
  L10nKeys.timelineKindHabitLabel: (AppLocalizations t) =>
      t.timelineKindHabitLabel,
  L10nKeys.timelineKindDoneLabel: (AppLocalizations t) =>
      t.timelineKindDoneLabel,
  L10nKeys.timelineTodoLoadFailed: (AppLocalizations t) =>
      t.timelineTodoLoadFailed,
  L10nKeys.timelineTodoLoading: (AppLocalizations t) => t.timelineTodoLoading,
  L10nKeys.timelineTodoEmpty: (AppLocalizations t) => t.timelineTodoEmpty,
  L10nKeys.timelineTodoSlotted: (AppLocalizations t) => t.timelineTodoSlotted,
  L10nKeys.timelineNodeGap: (AppLocalizations t) => t.timelineNodeGap,
  L10nKeys.timelineNodeClosed: (AppLocalizations t) => t.timelineNodeClosed,
  // today 44 条（Task 63 轮二）
  L10nKeys.todayReviewFutureTitle: (AppLocalizations t) =>
      t.todayReviewFutureTitle,
  L10nKeys.todayReviewFutureDetail: (AppLocalizations t) =>
      t.todayReviewFutureDetail,
  L10nKeys.todayFuturePlanOnly: (AppLocalizations t) => t.todayFuturePlanOnly,
  L10nKeys.todayFuturePlanning: (AppLocalizations t) => t.todayFuturePlanning,
  L10nKeys.todayChangeDate: (AppLocalizations t) => t.todayChangeDate,
  L10nKeys.todayChangeTime: (AppLocalizations t) => t.todayChangeTime,
  L10nKeys.todayClearTime: (AppLocalizations t) => t.todayClearTime,
  L10nKeys.todayTimeUnset: (AppLocalizations t) => t.todayTimeUnset,
  L10nKeys.todayPickStartTime: (AppLocalizations t) => t.todayPickStartTime,
  L10nKeys.todayAddPlanHint: (AppLocalizations t) => t.todayAddPlanHint,
  L10nKeys.todayAddManual: (AppLocalizations t) => t.todayAddManual,
  L10nKeys.todayHabitLoadFailed: (AppLocalizations t) => t.todayHabitLoadFailed,
  L10nKeys.todayHabitLoading: (AppLocalizations t) => t.todayHabitLoading,
  L10nKeys.todayHabitEmpty: (AppLocalizations t) => t.todayHabitEmpty,
  L10nKeys.todayStatPlanGap: (AppLocalizations t) => t.todayStatPlanGap,
  L10nKeys.todayStatFillGap: (AppLocalizations t) => t.todayStatFillGap,
  L10nKeys.todayStatWritten: (AppLocalizations t) => t.todayStatWritten,
  L10nKeys.todayStatUnwritten: (AppLocalizations t) => t.todayStatUnwritten,
  L10nKeys.todayStatRecorded: (AppLocalizations t) => t.todayStatRecorded,
  L10nKeys.todayStatUnrecorded: (AppLocalizations t) => t.todayStatUnrecorded,
  L10nKeys.todayStallDismiss: (AppLocalizations t) => t.todayStallDismiss,
  L10nKeys.todayNoticeFutureCheckin: (AppLocalizations t) =>
      t.todayNoticeFutureCheckin,
  L10nKeys.todayGotIt: (AppLocalizations t) => t.todayGotIt,
  L10nKeys.todayReviewFieldLearn: (AppLocalizations t) =>
      t.todayReviewFieldLearn,
  L10nKeys.todayReviewFieldLearnHint: (AppLocalizations t) =>
      t.todayReviewFieldLearnHint,
  L10nKeys.todayReviewFieldGood: (AppLocalizations t) => t.todayReviewFieldGood,
  L10nKeys.todayReviewFieldGoodHint: (AppLocalizations t) =>
      t.todayReviewFieldGoodHint,
  L10nKeys.todayReviewFieldImprove: (AppLocalizations t) =>
      t.todayReviewFieldImprove,
  L10nKeys.todayReviewFieldImproveHint: (AppLocalizations t) =>
      t.todayReviewFieldImproveHint,
  L10nKeys.todayReviewSubtitle: (AppLocalizations t) => t.todayReviewSubtitle,
  L10nKeys.todayReviewEmptyNotice: (AppLocalizations t) =>
      t.todayReviewEmptyNotice,
  L10nKeys.todayReviewPickProject: (AppLocalizations t) =>
      t.todayReviewPickProject,
  L10nKeys.todayReviewFileToProject: (AppLocalizations t) =>
      t.todayReviewFileToProject,
  L10nKeys.todayLoopRingA11y: (AppLocalizations t) => t.todayLoopRingA11y,
  L10nKeys.todayLoopRingScale: (AppLocalizations t) => t.todayLoopRingScale,
  L10nKeys.todayStandupTitle: (AppLocalizations t) => t.todayStandupTitle,
  L10nKeys.todayStandupSubtitle: (AppLocalizations t) => t.todayStandupSubtitle,
  L10nKeys.todayStandupEmpty: (AppLocalizations t) => t.todayStandupEmpty,
  L10nKeys.todayStandupYesterday: (AppLocalizations t) =>
      t.todayStandupYesterday,
  L10nKeys.todayStandupYesterdayEmpty: (AppLocalizations t) =>
      t.todayStandupYesterdayEmpty,
  L10nKeys.todayStandupToday: (AppLocalizations t) => t.todayStandupToday,
  L10nKeys.todayStandupTodayEmpty: (AppLocalizations t) =>
      t.todayStandupTodayEmpty,
  L10nKeys.todayStandupBlockers: (AppLocalizations t) => t.todayStandupBlockers,
  L10nKeys.todayStandupBlockersEmpty: (AppLocalizations t) =>
      t.todayStandupBlockersEmpty,
  // habit 44 条（Task 63 轮二）
  L10nKeys.moodGroupDayTitle: (AppLocalizations t) => t.moodGroupDayTitle,
  L10nKeys.moodGroupWeekTitle: (AppLocalizations t) => t.moodGroupWeekTitle,
  L10nKeys.moodSectionSubtitle: (AppLocalizations t) => t.moodSectionSubtitle,
  L10nKeys.moodClearAll: (AppLocalizations t) => t.moodClearAll,
  L10nKeys.moodMarkFailed: (AppLocalizations t) => t.moodMarkFailed,
  L10nKeys.moodNextActionLabel: (AppLocalizations t) => t.moodNextActionLabel,
  L10nKeys.moodNextActionHint: (AppLocalizations t) => t.moodNextActionHint,
  L10nKeys.moodNoteLabel: (AppLocalizations t) => t.moodNoteLabel,
  L10nKeys.moodNoteHint: (AppLocalizations t) => t.moodNoteHint,
  L10nKeys.moodUnrated: (AppLocalizations t) => t.moodUnrated,
  L10nKeys.moodClearDimension: (AppLocalizations t) => t.moodClearDimension,
  L10nKeys.moodDimFulfillmentLabel: (AppLocalizations t) =>
      t.moodDimFulfillmentLabel,
  L10nKeys.moodDimFulfillmentDesc: (AppLocalizations t) =>
      t.moodDimFulfillmentDesc,
  L10nKeys.moodDimEfficiencyLabel: (AppLocalizations t) =>
      t.moodDimEfficiencyLabel,
  L10nKeys.moodDimEfficiencyDesc: (AppLocalizations t) =>
      t.moodDimEfficiencyDesc,
  L10nKeys.moodDimPositiveMindLabel: (AppLocalizations t) =>
      t.moodDimPositiveMindLabel,
  L10nKeys.moodDimPositiveMindDesc: (AppLocalizations t) =>
      t.moodDimPositiveMindDesc,
  L10nKeys.moodDimSelfEfficacyLabel: (AppLocalizations t) =>
      t.moodDimSelfEfficacyLabel,
  L10nKeys.moodDimSelfEfficacyDesc: (AppLocalizations t) =>
      t.moodDimSelfEfficacyDesc,
  L10nKeys.moodDimContributionLabel: (AppLocalizations t) =>
      t.moodDimContributionLabel,
  L10nKeys.moodDimContributionDesc: (AppLocalizations t) =>
      t.moodDimContributionDesc,
  L10nKeys.moodLegacyDiligent: (AppLocalizations t) => t.moodLegacyDiligent,
  L10nKeys.moodLegacyFast: (AppLocalizations t) => t.moodLegacyFast,
  L10nKeys.moodLegacyKeepPromise: (AppLocalizations t) =>
      t.moodLegacyKeepPromise,
  L10nKeys.moodLegacyFinishTask: (AppLocalizations t) => t.moodLegacyFinishTask,
  L10nKeys.moodLegacyOptimistic: (AppLocalizations t) => t.moodLegacyOptimistic,
  L10nKeys.moodLegacyConfident: (AppLocalizations t) => t.moodLegacyConfident,
  L10nKeys.moodLegacyLoveAndDedication: (AppLocalizations t) =>
      t.moodLegacyLoveAndDedication,
  L10nKeys.moodLegacyNoExcuses: (AppLocalizations t) => t.moodLegacyNoExcuses,
  L10nKeys.habitSectionTitle: (AppLocalizations t) => t.habitSectionTitle,
  L10nKeys.habitSectionSubtitle: (AppLocalizations t) => t.habitSectionSubtitle,
  L10nKeys.habitSectionEmpty: (AppLocalizations t) => t.habitSectionEmpty,
  L10nKeys.habitCheckinLoading: (AppLocalizations t) => t.habitCheckinLoading,
  L10nKeys.habitCheckinError: (AppLocalizations t) => t.habitCheckinError,
  L10nKeys.habitCheckinHeadTitle: (AppLocalizations t) =>
      t.habitCheckinHeadTitle,
  L10nKeys.habitCheckinHeadHint: (AppLocalizations t) => t.habitCheckinHeadHint,
  L10nKeys.habitPageTitle: (AppLocalizations t) => t.habitPageTitle,
  L10nKeys.habitPageFutureHint: (AppLocalizations t) => t.habitPageFutureHint,
  L10nKeys.habitPageEmpty: (AppLocalizations t) => t.habitPageEmpty,
  L10nKeys.priorityPickQuadrant: (AppLocalizations t) => t.priorityPickQuadrant,
  L10nKeys.priorityPickAbc: (AppLocalizations t) => t.priorityPickAbc,
  L10nKeys.priorityBubbleCurrent: (AppLocalizations t) =>
      t.priorityBubbleCurrent,
  L10nKeys.priorityBubbleReadonly: (AppLocalizations t) =>
      t.priorityBubbleReadonly,
  L10nKeys.priorityBubbleEditable: (AppLocalizations t) =>
      t.priorityBubbleEditable,
  // dialog 93 条（Task 63 轮二 73 条 + Stage 4 新增 20 条）
  L10nKeys.dialogEstUnitMinute: (AppLocalizations t) => t.dialogEstUnitMinute,
  L10nKeys.dialogEstUnitHour: (AppLocalizations t) => t.dialogEstUnitHour,
  L10nKeys.dialogEstUnitDay: (AppLocalizations t) => t.dialogEstUnitDay,
  L10nKeys.dialogEstUnitWeek: (AppLocalizations t) => t.dialogEstUnitWeek,
  L10nKeys.dialogEstUnitMonth: (AppLocalizations t) => t.dialogEstUnitMonth,
  L10nKeys.dialogHabitNameRequired: (AppLocalizations t) =>
      t.dialogHabitNameRequired,
  L10nKeys.dialogHabitWeekdayRequired: (AppLocalizations t) =>
      t.dialogHabitWeekdayRequired,
  L10nKeys.dialogHabitNameLabel: (AppLocalizations t) => t.dialogHabitNameLabel,
  L10nKeys.dialogHabitNoteLabel: (AppLocalizations t) => t.dialogHabitNoteLabel,
  L10nKeys.dialogHabitSchedule: (AppLocalizations t) => t.dialogHabitSchedule,
  L10nKeys.dialogHabitDaily: (AppLocalizations t) => t.dialogHabitDaily,
  L10nKeys.dialogHabitEveryDays: (AppLocalizations t) => t.dialogHabitEveryDays,
  L10nKeys.dialogHabitEveryWeeks: (AppLocalizations t) =>
      t.dialogHabitEveryWeeks,
  L10nKeys.dialogHabitWeeklyPick: (AppLocalizations t) =>
      t.dialogHabitWeeklyPick,
  L10nKeys.dialogHabitEvery: (AppLocalizations t) => t.dialogHabitEvery,
  L10nKeys.dialogHabitWeekday: (AppLocalizations t) => t.dialogHabitWeekday,
  L10nKeys.dialogHabitStartDate: (AppLocalizations t) => t.dialogHabitStartDate,
  L10nKeys.dialogHabitDailyMin: (AppLocalizations t) => t.dialogHabitDailyMin,
  L10nKeys.dialogHabitCreate: (AppLocalizations t) => t.dialogHabitCreate,
  L10nKeys.dialogHabitCreateSubtitle: (AppLocalizations t) =>
      t.dialogHabitCreateSubtitle,
  L10nKeys.dialogTodoTitleRequired: (AppLocalizations t) =>
      t.dialogTodoTitleRequired,
  L10nKeys.dialogTodoEstInvalid: (AppLocalizations t) => t.dialogTodoEstInvalid,
  L10nKeys.dialogTodoCreateTitle: (AppLocalizations t) =>
      t.dialogTodoCreateTitle,
  L10nKeys.dialogTodoTitleHint: (AppLocalizations t) => t.dialogTodoTitleHint,
  L10nKeys.dialogTodoEstLabel: (AppLocalizations t) => t.dialogTodoEstLabel,
  L10nKeys.dialogTodoEstHint: (AppLocalizations t) => t.dialogTodoEstHint,
  L10nKeys.dialogTodoPriorityLabel: (AppLocalizations t) =>
      t.dialogTodoPriorityLabel,
  L10nKeys.dialogTodoPullToday: (AppLocalizations t) => t.dialogTodoPullToday,
  L10nKeys.dialogTodoSaving: (AppLocalizations t) => t.dialogTodoSaving,
  L10nKeys.dialogTodoPullTitle: (AppLocalizations t) => t.dialogTodoPullTitle,
  L10nKeys.dialogTodoPoolEmpty: (AppLocalizations t) => t.dialogTodoPoolEmpty,
  L10nKeys.dialogTodoPulling: (AppLocalizations t) => t.dialogTodoPulling,
  L10nKeys.dialogTodoPull: (AppLocalizations t) => t.dialogTodoPull,
  L10nKeys.dialogRecurringWeekdayRequired: (AppLocalizations t) =>
      t.dialogRecurringWeekdayRequired,
  L10nKeys.dialogRecurringTimeInvalid: (AppLocalizations t) =>
      t.dialogRecurringTimeInvalid,
  L10nKeys.dialogRecurringDurationInvalid: (AppLocalizations t) =>
      t.dialogRecurringDurationInvalid,
  L10nKeys.dialogRecurringTitleLabel: (AppLocalizations t) =>
      t.dialogRecurringTitleLabel,
  L10nKeys.dialogRecurringStartLabel: (AppLocalizations t) =>
      t.dialogRecurringStartLabel,
  L10nKeys.dialogRecurringDurationLabel: (AppLocalizations t) =>
      t.dialogRecurringDurationLabel,
  L10nKeys.dialogRecurringNoteLabel: (AppLocalizations t) =>
      t.dialogRecurringNoteLabel,
  L10nKeys.dialogRecurringSaveConfirm: (AppLocalizations t) =>
      t.dialogRecurringSaveConfirm,
  L10nKeys.dialogRecurringCreateTitle: (AppLocalizations t) =>
      t.dialogRecurringCreateTitle,
  L10nKeys.dialogRecurringCreateSubtitle: (AppLocalizations t) =>
      t.dialogRecurringCreateSubtitle,
  L10nKeys.dialogRecurringDeleteTitle: (AppLocalizations t) =>
      t.dialogRecurringDeleteTitle,
  L10nKeys.dialogRecurringSection: (AppLocalizations t) =>
      t.dialogRecurringSection,
  L10nKeys.dialogRecurringLoading: (AppLocalizations t) =>
      t.dialogRecurringLoading,
  L10nKeys.dialogRecurringNone: (AppLocalizations t) => t.dialogRecurringNone,
  L10nKeys.dialogRecurringNoneHint: (AppLocalizations t) =>
      t.dialogRecurringNoneHint,
  L10nKeys.dialogRecurringDaily: (AppLocalizations t) => t.dialogRecurringDaily,
  L10nKeys.dialogRuleActiveOn: (AppLocalizations t) => t.dialogRuleActiveOn,
  L10nKeys.dialogRuleActiveOff: (AppLocalizations t) => t.dialogRuleActiveOff,
  L10nKeys.dialogRuleDisable: (AppLocalizations t) => t.dialogRuleDisable,
  L10nKeys.dialogRuleEnable: (AppLocalizations t) => t.dialogRuleEnable,
  L10nKeys.dialogDurationCustom: (AppLocalizations t) => t.dialogDurationCustom,
  L10nKeys.dialogDurationCustomHint: (AppLocalizations t) =>
      t.dialogDurationCustomHint,
  L10nKeys.dialogNoteRestructure: (AppLocalizations t) =>
      t.dialogNoteRestructure,
  L10nKeys.dialogNoteNextStepLabel: (AppLocalizations t) =>
      t.dialogNoteNextStepLabel,
  L10nKeys.dialogNoteSaveProgressOnly: (AppLocalizations t) =>
      t.dialogNoteSaveProgressOnly,
  L10nKeys.dialogNoteDone: (AppLocalizations t) => t.dialogNoteDone,
  // 结果撰写的三段短语 20 条（显示层；落库值本身在 outcome_composer.dart）
  L10nKeys.dialogOutcomeOnTime: (AppLocalizations t) => t.dialogOutcomeOnTime,
  L10nKeys.dialogOutcomeLate: (AppLocalizations t) => t.dialogOutcomeLate,
  L10nKeys.dialogOutcomeEarly: (AppLocalizations t) => t.dialogOutcomeEarly,
  L10nKeys.dialogOutcomePartial: (AppLocalizations t) => t.dialogOutcomePartial,
  L10nKeys.dialogOutcomeBlocked: (AppLocalizations t) => t.dialogOutcomeBlocked,
  L10nKeys.dialogOutcomeDeferredTomorrow: (AppLocalizations t) =>
      t.dialogOutcomeDeferredTomorrow,
  L10nKeys.dialogReasonUnderestimated: (AppLocalizations t) =>
      t.dialogReasonUnderestimated,
  L10nKeys.dialogReasonInterrupted: (AppLocalizations t) =>
      t.dialogReasonInterrupted,
  L10nKeys.dialogReasonExternal: (AppLocalizations t) => t.dialogReasonExternal,
  L10nKeys.dialogReasonPriorityChanged: (AppLocalizations t) =>
      t.dialogReasonPriorityChanged,
  L10nKeys.dialogReasonPoorState: (AppLocalizations t) =>
      t.dialogReasonPoorState,
  L10nKeys.dialogReasonNoTime: (AppLocalizations t) => t.dialogReasonNoTime,
  L10nKeys.dialogReasonUnclear: (AppLocalizations t) => t.dialogReasonUnclear,
  L10nKeys.dialogReasonOther: (AppLocalizations t) => t.dialogReasonOther,
  L10nKeys.dialogNextStepContinueTomorrow: (AppLocalizations t) =>
      t.dialogNextStepContinueTomorrow,
  L10nKeys.dialogNextStepToTodo: (AppLocalizations t) => t.dialogNextStepToTodo,
  L10nKeys.dialogNextStepHandOff: (AppLocalizations t) => t.dialogNextStepHandOff,
  L10nKeys.dialogNextStepNarrowScope: (AppLocalizations t) =>
      t.dialogNextStepNarrowScope,
  L10nKeys.dialogNextStepReviewLater: (AppLocalizations t) =>
      t.dialogNextStepReviewLater,
  L10nKeys.dialogNextStepStopHere: (AppLocalizations t) =>
      t.dialogNextStepStopHere,
  L10nKeys.dialogPoolLoading: (AppLocalizations t) => t.dialogPoolLoading,
  L10nKeys.dialogPoolTitle: (AppLocalizations t) => t.dialogPoolTitle,
  L10nKeys.dialogPoolTitleHint: (AppLocalizations t) => t.dialogPoolTitleHint,
  L10nKeys.dialogPoolStartHint: (AppLocalizations t) => t.dialogPoolStartHint,
  L10nKeys.dialogPoolDueHint: (AppLocalizations t) => t.dialogPoolDueHint,
  L10nKeys.dialogPoolNew: (AppLocalizations t) => t.dialogPoolNew,
  L10nKeys.dialogPoolColPriority: (AppLocalizations t) =>
      t.dialogPoolColPriority,
  L10nKeys.dialogPoolColEst: (AppLocalizations t) => t.dialogPoolColEst,
  L10nKeys.dialogPoolColQuadrant: (AppLocalizations t) =>
      t.dialogPoolColQuadrant,
  L10nKeys.dialogPoolColDue: (AppLocalizations t) => t.dialogPoolColDue,
  L10nKeys.dialogPoolColAction: (AppLocalizations t) => t.dialogPoolColAction,
  L10nKeys.dialogPoolStartInvalid: (AppLocalizations t) =>
      t.dialogPoolStartInvalid,
  L10nKeys.dialogPoolAddToToday: (AppLocalizations t) => t.dialogPoolAddToToday,
  L10nKeys.dialogPoolEmptyLong: (AppLocalizations t) => t.dialogPoolEmptyLong,
};

/// 列表型 getter（`List<String>`）的访问器表（4 条）。
///
/// 与 `l10nAccessors` 同一套键空间，只是取值返回 `List<String>`，所以单列一张
/// 表，避免把 `Map<String, String Function(...)>` 撑成动态类型。
final Map<String, List<String> Function(AppLocalizations)> l10nListAccessors =
    <String, List<String> Function(AppLocalizations)>{
  L10nKeys.aboutToc: (AppLocalizations t) => t.aboutToc,
  L10nKeys.aboutChangelog: (AppLocalizations t) => t.aboutChangelog,
  L10nKeys.calendarWeekdaysShort: (AppLocalizations t) =>
      t.calendarWeekdaysShort,
  L10nKeys.domainWeekdayFull: (AppLocalizations t) => t.domainWeekdayFull,
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