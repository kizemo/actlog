// =============================================================================
// l10n part：关于页（W1 波次拥有本文件）
// =============================================================================
// 注意 `developerIntro` / `alphaFileManagerIntro` / `pageWeaverIntro` 三条里含
// 人名、产品名与 URL —— 这些不是「可翻译文案」，英文态只把连接词换成英文，专有
// 名词与域名保持原样。
// =============================================================================

import '../../app_version.dart';

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

  // ---------------------------------------------------------------------------
  // 关于页正文（Task 47 · W1：从页面内的私有文案类收进 l10n）
  // ---------------------------------------------------------------------------

  /// 本页导航条目，顺序与 `_anchors`（七个区块）一一对应。
  List<String> get aboutToc;

  /// 分组：最近变更。
  String get aboutChangelogTitle;

  /// 最近变更条目（一条一行，页面用 `\n` 拼）。
  List<String> get aboutChangelog;

  /// 分组：数据与隐私。
  String get aboutPrivacyTitle;

  /// 数据与隐私正文。
  String get aboutPrivacy;

  /// 分组：许可证。
  String get aboutLicensesTitle;

  /// 许可证正文。
  String get aboutLicenses;

  /// 「复制结果」按钮（检查更新结果行；不复用 `copy`，那条专指仓库 URL）。
  String get aboutCopyResult;

  /// 「打开发布页」按钮。
  String get aboutReleases;

  // ---------------------------------------------------------------------------
  // 外壳（窗口标题 / 顶栏三钮 / 托盘菜单）
  // ---------------------------------------------------------------------------
  // 这几条**暂时寄放**在关于页 part 上：`l10n\app_localizations.dart` 与
  // `l10n\parts\common.dart` 都不在 W1 写集内，而 `AppLocalizations` 由各 part
  // 的 mixin 组合而成 ⇒ 只在 `about.dart` 里加 getter 才能被自动继承。
  // 键前缀已改用 `shell-`，等 `parts\shell.dart` 立项时整体挪过去。

  /// 窗口标题与托盘 tooltip（zh 带产品名，en 只留品牌）。
  String get appTitle;

  /// `MaterialApp.title`（窗口标题里 `kAppTitle` 的品牌后缀在桌面标题栏才需要）。
  String get appName;

  /// 顶栏：最小化。
  String get windowMinimize;

  /// 顶栏：最大化。
  String get windowMaximize;

  /// 顶栏：还原。
  String get windowRestore;

  /// 顶栏：关闭。
  String get windowClose;

  /// 托盘菜单：显示窗口。
  String get trayShow;

  /// 托盘菜单：隐藏到托盘。
  String get trayHide;

  /// 托盘菜单：退出。
  String get trayQuit;
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

  @override
  List<String> get aboutToc => <String>[
        '版本',
        '最近变更',
        '数据与隐私',
        '仓库',
        '开发者',
        '其它软件',
        '许可证',
      ];

  @override
  String get aboutChangelogTitle => '最近变更';

  @override
  List<String> get aboutChangelog => <String>[
        // 版本串取自 `app_version.dart`（Task 46 起版本口径统一），
        // 不在文案里硬编码 —— 否则关于页会与真实版本脱节。
        '$kAppVersionFull · 首个可分发版本；仓库尚无对外发布。',
        '今日 / 待办池 / 习惯 / 日历 四个主页面，数据写在本机 SQLite。',
        '中文 / English 双语界面，明暗两套主题。',
        '文字缩放到 200% 时页面不溢出、不截断。',
        '关于页新增：最近变更、数据与隐私、许可证。',
      ];

  @override
  String get aboutPrivacyTitle => '数据与隐私';

  @override
  String get aboutPrivacy =>
      '待办、日志、习惯与设置都写在本机的 SQLite 数据库里，不出这台电脑。'
      '除「检查更新」会向 GitHub releases API 发一次请求外，应用不发起任何网络请求；'
      '没有账号系统，也不收集任何遥测数据。';

  @override
  String get aboutLicensesTitle => '许可证';

  // 逐条列出 pubspec.yaml 里真实存在的依赖与真实许可证名（MIT / BSD-3-Clause
  // 已实测，不许把 BSD 写成 MIT）；随包字体按「字体族 + OFL-1.1」分组表述，
  // **不写死数量**（W1 会新增第 5 个字体族）。
  @override
  String get aboutLicenses =>
      '第三方软件与许可证 · 本应用以 Flutter 构建，随包分发下列第三方组件：'
      'cupertino_icons（MIT）、drift（MIT）、flutter_riverpod（MIT）、'
      'window_manager（MIT）、tray_manager（MIT）、sqlite3（MIT）、'
      'flutter_local_notifications（BSD-3-Clause）、path（BSD-3-Clause）、'
      'path_provider（BSD-3-Clause）。随包字体族（Fraunces / Inter / '
      'JetBrains Mono / Noto Sans SC 等）均以 SIL Open Font License 1.1 授权；'
      'SQLite 运行库 sqlite3.dll 归公有领域。本仓库自身的 core_domain / '
      'core_db / core_data 三个包不在第三方之列。许可证全文除 OFL 外未随包'
      '分发，OFL 全文见仓库 apps/desktop/assets/fonts/licenses/（OFL-*.txt），'
      '完整依赖清单见 apps/desktop/pubspec.yaml。';

  @override
  String get aboutCopyResult => '复制结果';

  @override
  String get aboutReleases => '打开发布页';

  // --- 外壳 -----------------------------------------------------------------

  @override
  String get appTitle => '知行日志 actlog';

  @override
  String get appName => '知行日志';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '还原';

  @override
  String get windowClose => '关闭';

  @override
  String get trayShow => '显示窗口';

  @override
  String get trayHide => '隐藏到托盘';

  @override
  String get trayQuit => '退出';
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

  @override
  List<String> get aboutToc => <String>[
        'Version',
        'Recent changes',
        'Data & privacy',
        'Repository',
        'Developer',
        'Other software',
        'Licenses',
      ];

  @override
  String get aboutChangelogTitle => 'Recent changes';

  @override
  List<String> get aboutChangelog => <String>[
        // 版本串同样取自 `app_version.dart`，与 zh 保持同一真源。
        '$kAppVersionFull - first distributable build; the repository has no '
            'public release yet.',
        'Four main pages - Today / Todo pool / Habits / Calendar - with data '
            'stored in a local SQLite file.',
        'Chinese / English UI and light / dark themes.',
        'Pages do not overflow or truncate at 200% text scale.',
        'About page additions: recent changes, data & privacy, licenses.',
      ];

  @override
  String get aboutPrivacyTitle => 'Data & privacy';

  @override
  String get aboutPrivacy =>
      'Todos, logs, habits and settings all live in a local SQLite database on '
      'this machine - they never leave it. Apart from a single request to the '
      'GitHub releases API when you check for updates, the app makes no network '
      'calls; there is no account system and no telemetry is collected.';

  @override
  String get aboutLicensesTitle => 'Licenses';

  // 与 zh 同源同构：依赖与许可证名不得改写（MIT 不能写成 BSD）。
  @override
  String get aboutLicenses =>
      'Third-party software and licenses - this app is built with Flutter and '
      'bundles the following third-party components: cupertino_icons (MIT), '
      'drift (MIT), flutter_riverpod (MIT), window_manager (MIT), '
      'tray_manager (MIT), sqlite3 (MIT), flutter_local_notifications '
      '(BSD-3-Clause), path (BSD-3-Clause), path_provider (BSD-3-Clause). '
      'Bundled font families (Fraunces / Inter / JetBrains Mono / Noto Sans SC '
      'and others) are licensed under the SIL Open Font License 1.1; the SQLite '
      'runtime sqlite3.dll is in the public domain. The core_domain / core_db / '
      'core_data packages in this repository are not third-party. Only the '
      'OFL text ships with the app, under apps/desktop/assets/fonts/licenses/ '
      '(OFL-*.txt); the full dependency list is in apps/desktop/pubspec.yaml.';

  @override
  String get aboutCopyResult => 'Copy result';

  @override
  String get aboutReleases => 'Open releases page';

  // --- 外壳 -----------------------------------------------------------------

  @override
  String get appTitle => 'actlog';

  @override
  String get appName => 'actlog';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowRestore => 'Restore';

  @override
  String get windowClose => 'Close';

  @override
  String get trayShow => 'Show window';

  @override
  String get trayHide => 'Hide to tray';

  @override
  String get trayQuit => 'Quit';
}