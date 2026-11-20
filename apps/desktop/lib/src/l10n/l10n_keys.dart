// =============================================================================
// 文案键表：camelCase getter 名 ↔ kebab-case 稳定键
// =============================================================================
// 这层**不做转发**。它不进渲染路径 —— 页面上仍然写 `t.settingsTitle`，编译器
// 仍然保证漏翻是 error。键的作用只有两个：
//   1. 测试能遍历 key 集合，校验「89 条 getter 一条不少」「中英两态都不为空」
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
  // 外壳（窗口标题 / 顶栏 / 托盘，9 条；暂寄 parts\about.dart，待 parts\shell.dart
  // 立项时整体挪走）
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
  // 对照表
  // ---------------------------------------------------------------------------

  /// getter 名 → 键（89 条，覆盖 `AppLocalizations` 全部无参 String getter；
  /// 另有 2 条列表型 getter 在 `byListGetter`）。
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
  };

  /// 列表型 getter 名 → 键（2 条；`byGetter` 只收 String getter）。
  ///
  /// 列表型 getter（`List<String>`）无法塞进 `Map<String, String>`，单列一张表，
  /// 好让测试同样能遍历「键一条不少 + 中英两态都非空且不同」。
  static const Map<String, String> byListGetter = <String, String>{
    'aboutToc': aboutToc,
    'aboutChangelog': aboutChangelog,
  };

  /// 插值方法名 → 键（4 条）。
  static const Map<String, String> byMethod = <String, String>{
    'hoursCount': domainHoursCount,
    'minutesCount': domainMinutesCount,
    'deferredDays': domainDeferredDays,
    'moodScoreLabel': domainMoodScoreLabel,
  };
}