// =============================================================================
// l10n part：设置页（W1 波次拥有本文件）
// =============================================================================
// 一个 part = 一个模块的「接口 + 中英两态实现」。这样某一波次改文案时只碰
// 自己那一个文件，八波并行也不会在同一处 `app_localizations.dart` 里撞车。
//
// 三件套的约束：
//  1. `SettingsL10n` 只声明 getter，不带任何实现；
//  2. `SettingsZhL10n` / `SettingsEnL10n` 用 `mixin` 实现接口，`@override` 必须
//     齐全 —— 少一条就是编译期错误（这正是当初不用 `Map<String, String>` 的理由）；
//  3. 聚合在 `app_localizations.dart`：`_AppLocalizationsZh` 用 `with` 把 9 个
//     zh mixin 拼起来，`_AppLocalizationsEn` 拼 9 个 en mixin。
// =============================================================================

/// 设置页文案。
abstract class SettingsL10n {
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

  /// 已恢复默认。
  String get resetDone;

  /// 分组：快捷键提示（设置页底部说明）。
  String get settingsFootnote;
}

/// 设置页文案：简体中文。
mixin SettingsZhL10n implements SettingsL10n {
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
  String get resetDone => '已恢复默认设置';

  @override
  String get settingsFootnote => '偏好存于本机数据库的 settings 表，随数据目录一起迁移。';
}

/// 设置页文案：English。
mixin SettingsEnL10n implements SettingsL10n {
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
  String get sectionPlanWindow => 'Daily plan hours';

  @override
  String get planStart => 'Start';

  @override
  String get planEnd => 'End';

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
  String get resetDone => 'Preferences reset to defaults';

  @override
  String get settingsFootnote =>
      'Preferences live in the local settings table and travel with your data '
      'folder.';
}