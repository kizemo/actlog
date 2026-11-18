// =============================================================================
// 轻量本地化：只管**本波新增的设置页 / 关于页**文案
// =============================================================================
// 为什么不用 `flutter_localizations` / `intl`：本波零新增 pub 依赖，而且既有
// 全应用的中文硬编码属于后续批次 —— 现在只给「语言」设置项一个真实可切换的
// 落点，切了 English 就真的能看到英文，而不是造一个空开关。
//
// 为什么用抽象基类 + 两个 const 子类，而不是 `Map<String, String>`：
// 漏翻会在**编译期**变成未实现成员的 error；Map 方案漏一个 key 只会在运行期
// 静默回落到中文，那种「看起来能跑」的缺失最难被发现。
// =============================================================================

/// 界面语言。
///
/// 取值只用于持久化与切换，不参与 `Locale` 解析 —— 本项目没有引入
/// `flutter_localizations`，`MaterialApp.locale` 保持默认。
enum AppLanguage {
  /// 简体中文（默认）。
  zh('zh'),

  /// English。
  en('en');

  const AppLanguage(this.code);

  /// 持久化码值。
  final String code;

  /// 解析持久化码值；无法识别（含 null）一律回落中文。
  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.zh;
}

/// 设置页 / 关于页的文案表。
abstract class AppLocalizations {
  /// 子类构造。
  const AppLocalizations();

  /// 简体中文。
  static const AppLocalizations zh = _AppLocalizationsZh();

  /// English。
  static const AppLocalizations en = _AppLocalizationsEn();

  /// 按语言取文案表。
  static AppLocalizations forLanguage(AppLanguage language) =>
      language == AppLanguage.en ? en : zh;

  /// 设置页标题。
  String get settingsTitle;

  /// 设置页副标题（说明保存时机）。
  String get settingsSubtitle;

  /// 分组：外观。
  String get sectionAppearance;

  /// 主题：跟随系统。
  String get themeSystem;

  /// 主题：浅色。
  String get themeLight;

  /// 主题：深色。
  String get themeDark;

  /// 分组：语言。
  String get sectionLanguage;

  /// 语言：简体中文。
  String get languageChinese;

  /// 语言：English。
  String get languageEnglish;

  /// 分组：系统集成。
  String get sectionSystem;

  /// 开机启动。
  String get launchOnBoot;

  /// 开机启动说明。
  String get launchOnBootHint;

  /// 创建桌面快捷方式。
  String get desktopShortcut;

  /// 创建桌面快捷方式说明。
  String get desktopShortcutHint;

  /// 快捷方式创建成功。
  String get shortcutCreated;

  /// 分组：每天计划起止时间。
  String get sectionPlanWindow;

  /// 起点。
  String get planStart;

  /// 终点。
  String get planEnd;

  /// 起止时间说明。
  String get planWindowHint;

  /// 分组：数据。
  String get sectionData;

  /// 打开数据目录。
  String get openDataDir;

  /// 打开数据目录说明。
  String get openDataDirHint;

  /// 分组：其它。
  String get sectionOther;

  /// 界面密度。
  String get density;

  /// 密度：紧凑。
  String get densityCompact;

  /// 密度：舒适。
  String get densityComfortable;

  /// 密度：宽松。
  String get densityRoomy;

  /// 今日面板的优先级显示口径。
  String get priorityDisplayMode;

  /// 优先级显示：四象限。
  String get priorityQuadrant;

  /// 优先级显示：ABC 分级。
  String get priorityAbc;

  /// 恢复默认设置。
  String get resetPreferences;

  /// 恢复默认设置的确认问句。
  String get resetPreferencesConfirm;

  /// 恢复默认设置说明。
  String get resetPreferencesHint;

  /// 取消。
  String get cancel;

  /// 确认。
  String get confirm;

  /// 已恢复默认。
  String get resetDone;

  /// 当前程序路径。
  String get executablePath;

  /// 操作失败（附带原因）。
  String get operationFailed;

  /// 关于页标题。
  String get aboutTitle;

  /// 产品简介。
  String get aboutIntro;

  /// 分组：版本。
  String get sectionVersion;

  /// 版本标签。
  String get versionLabel;

  /// 检查新版本。
  String get checkUpdate;

  /// 检查中。
  String get checking;

  /// 暂无可用发布版本。
  String get noRelease;

  /// 网络不可用。
  String get networkError;

  /// 已是最新。
  String get upToDate;

  /// 有新版本。
  String get newVersionAvailable;

  /// 在线升级。
  String get onlineUpgrade;

  /// 在线升级被禁用的原因。
  String get onlineUpgradeDisabled;

  /// 分组：仓库。
  String get sectionRepository;

  /// 复制。
  String get copy;

  /// 已复制。
  String get copied;

  /// 打开。
  String get open;

  /// 分组：开发者。
  String get sectionDeveloper;

  /// 开发者简介。
  String get developerIntro;

  /// 分组：其它软件。
  String get sectionOtherSoftware;

  /// Alpha File Manager 一句话说明。
  String get alphaFileManagerIntro;

  /// PageWeaver 一句话说明（仓库对应关系未坐实时也要如实）。
  String get pageWeaverIntro;

  /// 「仓库地址待核实」标注。
  String get unverifiedLink;

  /// 分组：快捷键提示（设置页底部说明）。
  String get settingsFootnote;
}

class _AppLocalizationsZh extends AppLocalizations {
  const _AppLocalizationsZh();

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '改动即时保存，无需点确认。';

  @override
  String get sectionAppearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get sectionLanguage => '语言';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get sectionSystem => '系统集成';

  @override
  String get launchOnBoot => '开机启动';

  @override
  String get launchOnBootHint =>
      r'写入 HKCU\Software\Microsoft\Windows\CurrentVersion\Run 的 ActLog 值';

  @override
  String get desktopShortcut => '创建桌面快捷方式';

  @override
  String get desktopShortcutHint => '在桌面生成 actlog.lnk，指向当前程序';

  @override
  String get shortcutCreated => '已在桌面创建 actlog.lnk';

  @override
  String get sectionPlanWindow => '每天计划起止时间';

  @override
  String get planStart => '起点';

  @override
  String get planEnd => '终点';

  @override
  String get planWindowHint => '方格时间轴按这个区间裁剪，默认 06:00–24:00';

  @override
  String get sectionData => '数据';

  @override
  String get openDataDir => '打开数据目录';

  @override
  String get openDataDirHint => '数据库文件所在文件夹（资源管理器）';

  @override
  String get sectionOther => '其它';

  @override
  String get density => '界面密度';

  @override
  String get densityCompact => '紧凑';

  @override
  String get densityComfortable => '舒适';

  @override
  String get densityRoomy => '宽松';

  @override
  String get priorityDisplayMode => '优先级显示方式';

  @override
  String get priorityQuadrant => '四象限';

  @override
  String get priorityAbc => 'ABC 分级';

  @override
  String get resetPreferences => '恢复默认设置';

  @override
  String get resetPreferencesConfirm =>
      '把主题、语言、起止时间、密度等偏好写回默认值？（不动你的待办与计划数据）';

  @override
  String get resetPreferencesHint => '只清偏好，不动数据';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get resetDone => '已恢复默认设置';

  @override
  String get executablePath => '当前程序路径';

  @override
  String get operationFailed => '操作失败';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutIntro =>
      '知行日志是一款本地优先的日常计划与复盘工具：以方格时间轴排一天的计划，'
      '用待办池收住零散念头，用习惯打卡沉淀长期节奏，再用当日复盘把做过的事写下来。'
      '数据存在本机的 SQLite 文件里，不联网、不上传。';

  @override
  String get sectionVersion => '版本';

  @override
  String get versionLabel => '版本';

  @override
  String get checkUpdate => '检查新版本';

  @override
  String get checking => '检查中…';

  @override
  String get noRelease => '暂无可用发布版本';

  @override
  String get networkError => '网络不可用或请求超时，未能检查更新';

  @override
  String get upToDate => '已是最新版本';

  @override
  String get newVersionAvailable => '发现新版本';

  @override
  String get onlineUpgrade => '在线升级';

  @override
  String get onlineUpgradeDisabled => '当前仓库暂无发布版本';

  @override
  String get sectionRepository => '仓库';

  @override
  String get copy => '复制地址';

  @override
  String get copied => '已复制';

  @override
  String get open => '打开';

  @override
  String get sectionDeveloper => '开发者';

  @override
  String get developerIntro => 'kizemo · GitHub 主页 github.com/kizemo';

  @override
  String get sectionOtherSoftware => '其它软件推荐';

  @override
  String get alphaFileManagerIntro => 'Alpha File Manager · 本地文件管理工具';

  @override
  String get pageWeaverIntro => 'PageWeaver · 页面/文档排版工具';

  @override
  String get unverifiedLink => '仓库地址待核实';

  @override
  String get settingsFootnote => '偏好存于本机数据库的 settings 表，随数据目录一起迁移。';
}

class _AppLocalizationsEn extends AppLocalizations {
  const _AppLocalizationsEn();

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Changes are saved immediately.';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get sectionSystem => 'System integration';

  @override
  String get sectionPlanWindow => 'Daily plan hours';

  @override
  String get planStart => 'Start';

  @override
  String get planEnd => 'End';

  @override
  String get launchOnBoot => 'Launch at startup';

  @override
  String get launchOnBootHint =>
      r'Writes the ActLog value under HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  @override
  String get desktopShortcut => 'Create desktop shortcut';

  @override
  String get desktopShortcutHint =>
      'Creates actlog.lnk on your desktop pointing at this executable';

  @override
  String get shortcutCreated => 'Created actlog.lnk on your desktop';

  @override
  String get planWindowHint =>
      'The day grid is cropped to this range; default 06:00-24:00';

  @override
  String get sectionData => 'Data';

  @override
  String get openDataDir => 'Open data folder';

  @override
  String get openDataDirHint => 'Folder that holds the database file';

  @override
  String get sectionOther => 'Other';

  @override
  String get density => 'Density';

  @override
  String get densityCompact => 'Compact';

  @override
  String get densityComfortable => 'Comfortable';

  @override
  String get densityRoomy => 'Roomy';

  @override
  String get priorityDisplayMode => 'Priority display';

  @override
  String get priorityQuadrant => 'Quadrants';

  @override
  String get priorityAbc => 'ABC grading';

  @override
  String get resetPreferences => 'Reset preferences';

  @override
  String get resetPreferencesConfirm =>
      'Write theme, language, plan hours and density back to defaults? '
      'Your tasks and plans are not touched.';

  @override
  String get resetPreferencesHint => 'Preferences only, data untouched';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get resetDone => 'Preferences reset to defaults';

  @override
  String get executablePath => 'Executable path';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutIntro =>
      'ActLog is a local-first planner and review tool: lay out the day on a '
      'grid timeline, park loose thoughts in the todo pool, build long-term '
      'rhythm with habit check-ins, then write down what happened in the '
      'daily review. Everything lives in a local SQLite file - no network, '
      'no upload.';

  @override
  String get sectionVersion => 'Version';

  @override
  String get versionLabel => 'Version';

  @override
  String get checkUpdate => 'Check for updates';

  @override
  String get checking => 'Checking...';

  @override
  String get noRelease => 'No releases available yet';

  @override
  String get networkError => 'Network unavailable or timed out';

  @override
  String get upToDate => 'You are on the latest version';

  @override
  String get newVersionAvailable => 'A newer version is available';

  @override
  String get onlineUpgrade => 'Upgrade online';

  @override
  String get onlineUpgradeDisabled => 'This repository has no releases yet';

  @override
  String get sectionRepository => 'Repository';

  @override
  String get copy => 'Copy URL';

  @override
  String get copied => 'Copied';

  @override
  String get open => 'Open';

  @override
  String get sectionDeveloper => 'Developer';

  @override
  String get developerIntro => 'kizemo - GitHub profile github.com/kizemo';

  @override
  String get sectionOtherSoftware => 'Other software';

  @override
  String get alphaFileManagerIntro =>
      'Alpha File Manager - a local file manager';

  @override
  String get pageWeaverIntro => 'PageWeaver - a page/document layout tool';

  @override
  String get unverifiedLink => 'repository link unverified';

  @override
  String get settingsFootnote =>
      'Preferences live in the local settings table and travel with your data '
      'folder.';
}
