// =============================================================================
// l10n part：关于页（W1 波次拥有本文件）
// =============================================================================
// 注意 `developerIntro` / `alphaFileManagerIntro` / `pageWeaverIntro` 三条里含
// 人名、产品名与 URL —— 这些不是「可翻译文案」，英文态只把连接词换成英文，专有
// 名词与域名保持原样。
// =============================================================================

/// 关于页文案。
abstract class AboutL10n {
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
}

/// 关于页文案：简体中文。
mixin AboutZhL10n implements AboutL10n {
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
}

/// 关于页文案：English。
mixin AboutEnL10n implements AboutL10n {
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
}