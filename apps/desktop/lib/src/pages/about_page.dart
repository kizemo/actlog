import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_version.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 关于页（指令 8 / B9，Task 45 · W4 补齐 G1–G9）：简介 / 本页导航 /
/// 版本（检查更新 + 在线升级禁用说明 + 有更新时的「打开发布页」）/ 最近变更 /
/// 数据与隐私 / 仓库 / 开发者 / 其它软件 / 许可证。
///
/// 与设置页同构：壳内**内容体**，不自建 `Scaffold`，根是 `mainAxisSize: min`
/// 的 `Column`，外面套一层透明 `Material`（`InkWell` / `AlertDialog` 需要）。
///
/// 零新增依赖：打开链接走 [SystemIntegration.openUrl]（`rundll32`），复制走
/// `Clipboard.setData`，检查版本走 `dart:io HttpClient`（见 `providers.dart`）。
class AboutPage extends ConsumerStatefulWidget {
  /// 创建关于页。
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  /// 是否正在请求 releases API（按钮置灰、文案换成「检查中…」）。
  bool _checking = false;

  /// 最近一次检查结果（`null` = 还没点过）。
  ReleaseCheckResult? _result;

  /// 仓库地址是否刚被复制（复制反馈只留一小会儿，不弹窗）。
  bool _copied = false;

  /// 检查结果是否刚被复制（Task 46 · G4：结果行可复制）。复用 `_copied`
  /// 同一套「原地换文案、不弹窗」反馈机制，但**独立一个标志位** —— 复用同一个
  /// 字段会让「复制结果」把「复制仓库」按钮的文案一起换掉。
  bool _resultCopied = false;

  /// 七个区块的滚动锚点（G8：本页导航点击后 `ensureVisible`）。
  ///
  /// 用 `GlobalKey` 只为了拿 `currentContext` 做滚动定位，**不是**测试锚点：
  /// 测试锚点仍然是文档 §4 指定的 `ValueKey`，一个都没自造。
  final List<GlobalKey> _anchors = List<GlobalKey>.generate(
    7,
    (int _) => GlobalKey(),
  );

  /// 有更新时「打开发布页」的目标：仓库 releases 页。
  static String get _releasesUrl => '$kAppRepositoryUrl/releases';

  Future<void> _checkUpdate() async {
    if (_checking) {
      return;
    }
    setState(() {
      _checking = true;
      _result = null;
      // 新结果即将替换旧结果 ⇒ 上一轮的「已复制」反馈必须复位，
      // 否则新结果会顶着「已复制」标签出现（Task 46 · G4）。
      _resultCopied = false;
    });
    // `check()` 的契约是「自行吞掉所有网络异常」：这里不需要 try/catch，
    // 但仍要 mounted 保护 —— 请求最长 10s，用户可能已经离开本页。
    final ReleaseCheckResult result =
        await ref.read(releaseCheckerProvider).check();
    if (!mounted) {
      return;
    }
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _copyRepoUrl() async {
    await Clipboard.setData(const ClipboardData(text: kAppRepositoryUrl));
    if (!mounted) {
      return;
    }
    setState(() {
      _copied = true;
    });
  }

  /// Task 46 · G4：把当前检查结果整段写进剪贴板（结果行右侧的「复制」按钮）。
  ///
  /// 结果文案本身就是页面上的那句（同一份 [_resultText]），不另拼一份 ——
  /// 复制到的必须与用户看到的一致。
  Future<void> _copyResult(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() {
      _resultCopied = true;
    });
  }

  Future<void> _open(String url) async {
    await ref.read(systemIntegrationProvider).openUrl(url);
  }

  /// 滚到第 [index] 个区块。桌面壳的滚动容器在外层，`ensureVisible` 会自己
  /// 找到最近的 `Scrollable`，不依赖本页自建滚动视图。
  void _scrollToSection(int index) {
    final BuildContext? target = _anchors[index].currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 200),
      alignment: 0,
    );
  }

  /// 结果 → 文案。四种状态都必须有话说（B10：404 与网络失败都不许静默）。
  String _resultText(AppLocalizations t, ReleaseCheckResult result) {
    return switch (result.status) {
      ReleaseCheckStatus.upToDate => t.upToDate,
      ReleaseCheckStatus.newer =>
        '${t.newVersionAvailable} ${result.latestVersion ?? ''}'.trim(),
      ReleaseCheckStatus.noRelease => t.noRelease,
      ReleaseCheckStatus.networkError => t.networkError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations t = ref.watch(appLocalizationsProvider);
    final ThemeTokens tokens = context.tokens;
    final ReleaseCheckResult? result = _result;
    final bool hasNewer = result?.status == ReleaseCheckStatus.newer;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        key: const ValueKey<String>('about-page'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.aboutTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: AppTokens.gapSec),
          Text(
            t.aboutIntro,
            style: _paragraphStyle(tokens),
          ),
          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 本页导航（G8） ----------------
          // 只做锚点跳转，不新增色值 / 字号；条目文字就是七个区块标题。
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (int i = 0; i < t.aboutToc.length; i++)
                _TocEntry(
                  label: t.aboutToc[i],
                  onTap: () => _scrollToSection(i),
                ),
            ],
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 版本 ----------------
          _sectionTitle(t.sectionVersion, anchorKey: _anchors[0]),
          Text(
            '${t.versionLabel}  $kAppVersionFull',
            key: const ValueKey<String>('about-version'),
            style: _monoStyle(tokens).copyWith(color: tokens.ink2),
          ),
          const SizedBox(height: AppTokens.gapSec),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LinkButton(
                buttonKey: const ValueKey<String>('about-check-update'),
                label: _checking ? t.checking : t.checkUpdate,
                onTap: _checking ? null : _checkUpdate,
              ),
              // 在线升级：仓库当前 0 个 release ⇒ 必须禁用并给原因，
              // 不许伪造下载链接（指令 8 的硬要求）。
              _LinkButton(
                buttonKey: const ValueKey<String>('about-online-upgrade'),
                label: t.onlineUpgrade,
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.onlineUpgradeDisabled,
            key: const ValueKey<String>('about-online-upgrade-reason'),
            style: _hintStyle(tokens),
          ),
          if (result != null) ...<Widget>[
            const SizedBox(height: 6),
            // Task 46 · G4：结果原来是不可选中的单个 `Text`（鼠标划不中、
            // 也复制不了）⇒ 换成「结果文本 + 复制按钮」一行。`about-check-result`
            // 仍挂在那枚 `Text` 上（Task 39 的逐字断言依赖它），新增的
            // `about-copy-result` 挂在按钮上。
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    _resultText(t, result),
                    key: const ValueKey<String>('about-check-result'),
                    style: _monoStyle(tokens).copyWith(color: tokens.ink2),
                  ),
                ),
                const SizedBox(width: 8),
                _LinkButton(
                  buttonKey: const ValueKey<String>('about-copy-result'),
                  label: _resultCopied ? t.copied : t.aboutCopyResult,
                  onTap: () => _copyResult(_resultText(t, result)),
                ),
              ],
            ),
          ],
          // G5：有更新时才给「打开发布页」，目标由常量拼出，不伪造任何直链。
          if (hasNewer) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _LinkButton(
                buttonKey: const ValueKey<String>('about-open-releases'),
                label: t.aboutReleases,
                onTap: () => _open(_releasesUrl),
              ),
            ),
          ],

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 最近变更（G1） ----------------
          _sectionTitle(t.aboutChangelogTitle, anchorKey: _anchors[1]),
          Text(
            t.aboutChangelog.join('\n'),
            key: const ValueKey<String>('about-changelog'),
            style: _paragraphStyle(tokens),
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 数据与隐私（G3） ----------------
          _sectionTitle(t.aboutPrivacyTitle, anchorKey: _anchors[2]),
          Text(
            t.aboutPrivacy,
            key: const ValueKey<String>('about-privacy'),
            style: _paragraphStyle(tokens),
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 仓库 ----------------
          _sectionTitle(t.sectionRepository, anchorKey: _anchors[3]),
          Text(
            kAppRepositoryUrl,
            key: const ValueKey<String>('about-repo-url'),
            style: _monoStyle(tokens),
          ),
          const SizedBox(height: AppTokens.gapSec),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LinkButton(
                buttonKey: const ValueKey<String>('about-open-repo'),
                label: t.open,
                onTap: () => _open(kAppRepositoryUrl),
              ),
              _LinkButton(
                buttonKey: const ValueKey<String>('about-copy-repo'),
                label: _copied ? t.copied : t.copy,
                onTap: _copyRepoUrl,
              ),
            ],
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 开发者 ----------------
          _sectionTitle(t.sectionDeveloper, anchorKey: _anchors[4]),
          Text(
            kAppDeveloperName,
            key: const ValueKey<String>('about-developer'),
            style: _paragraphStyle(tokens).copyWith(color: tokens.ink),
          ),
          const SizedBox(height: 4),
          Text(
            t.developerIntro,
            style: _paragraphStyle(tokens),
          ),
          const SizedBox(height: AppTokens.gapSec),
          _LinkButton(
            buttonKey: const ValueKey<String>('about-open-developer'),
            label: kAppDeveloperUrl,
            onTap: () => _open(kAppDeveloperUrl),
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 其它软件 ----------------
          _sectionTitle(t.sectionOtherSoftware, anchorKey: _anchors[5]),
          Text(
            t.alphaFileManagerIntro,
            style: _paragraphStyle(tokens),
          ),
          const SizedBox(height: 4),
          _LinkButton(
            buttonKey: const ValueKey<String>('about-open-alpha'),
            label: kAlphaFileManagerUrl,
            onTap: () => _open(kAlphaFileManagerUrl),
          ),
          const SizedBox(height: AppTokens.gapSec),
          Text(
            t.pageWeaverIntro,
            style: _paragraphStyle(tokens),
          ),
          if (!kPageWeaverVerified) ...<Widget>[
            const SizedBox(height: 2),
            // 「PageWeaver ↔ kizemo/weavepage」的对应关系**未坐实**（本轮没有
            // 联网核实仓库 README 的产品名）⇒ 如实标注，不替它编产品名。
            Text(
              t.unverifiedLink,
              key: const ValueKey<String>('about-pageweaver-unverified'),
              style: _hintStyle(tokens),
            ),
          ],
          const SizedBox(height: 4),
          _LinkButton(
            buttonKey: const ValueKey<String>('about-open-pageweaver'),
            label: kPageWeaverUrl,
            onTap: () => _open(kPageWeaverUrl),
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 许可证（G2） ----------------
          _sectionTitle(t.aboutLicensesTitle, anchorKey: _anchors[6]),
          Text(
            t.aboutLicenses,
            key: const ValueKey<String>('about-licenses'),
            style: _hintStyle(tokens),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {Key? anchorKey}) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      key: anchorKey,
      padding: const EdgeInsets.only(bottom: AppTokens.gapSec),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: tokens.ink,
        ),
      ),
    );
  }
}

/// 本页导航里的一条（G8）。只用 `InkWell` + `Text`：与 `_LinkButton` 同源，
/// 但不带外框，避免一屏里出现两套按钮视觉。
class _TocEntry extends StatelessWidget {
  const _TocEntry({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 12,
            height: 1.4,
            color: tokens.ink2,
          ),
        ),
      ),
    );
  }
}

/// 文字按钮；`onTap == null` 即禁用（在线升级用这个态）。
///
/// Task 45 · G6 / G7：改为 `StatefulWidget`，靠 `InkWell` 自带的焦点节点 +
/// `ActivateIntent` 处理拿到键盘可达性（Tab 进入、Enter / Space 触发），
/// 只额外跟踪 focus 态换边框色 —— 不引入 `FocusableActionDetector` 这类
/// 需要另建焦点节点的封装，避免一枚按钮出现两个 Tab 停点。
class _LinkButton extends StatefulWidget {
  const _LinkButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  /// 是否是键盘焦点所在（G7：focus 边框用 `ink`，与 hover / 默认的
  /// `hairStrong` 区分）。
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final bool enabled = widget.onTap != null;
    final Color border = !enabled
        ? tokens.hair
        : (_focused ? tokens.ink : tokens.hairStrong);
    return InkWell(
      onTap: widget.onTap,
      // 禁用态不进 Tab 序（G6 规格第 4 条）。
      canRequestFocus: enabled,
      onFocusChange: (bool focused) {
        if (focused != _focused) {
          setState(() {
            _focused = focused;
          });
        }
      },
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: widget.buttonKey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: border),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 12,
            height: 1.2,
            color: enabled ? tokens.ink : tokens.faint,
          ),
        ),
      ),
    );
  }
}

/// 正文段落样式。
TextStyle _paragraphStyle(ThemeTokens tokens) => TextStyle(
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: 13,
      height: 1.6,
      color: tokens.ink2,
    );

/// 说明文字样式。
TextStyle _hintStyle(ThemeTokens tokens) => TextStyle(
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: 12,
      height: 1.5,
      color: tokens.meta,
    );

/// 机器可读文字样式（URL / 结果）。
TextStyle _monoStyle(ThemeTokens tokens) => TextStyle(
      fontFamily: AppFonts.mono,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: 11,
      height: 1.4,
      color: tokens.meta,
    );