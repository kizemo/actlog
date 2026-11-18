import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_version.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 关于页（指令 8 / B9）：简介 / 仓库地址（可点开 + 可复制）/ 检查新版本 /
/// 在线升级（禁用并说明原因）/ 开发者 / 其它软件推荐。
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

  Future<void> _checkUpdate() async {
    if (_checking) {
      return;
    }
    setState(() {
      _checking = true;
      _result = null;
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

  Future<void> _open(String url) async {
    await ref.read(systemIntegrationProvider).openUrl(url);
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

          // ---------------- 版本 ----------------
          _sectionTitle(t.sectionVersion),
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
            Text(
              _resultText(t, result),
              key: const ValueKey<String>('about-check-result'),
              style: _monoStyle(tokens).copyWith(color: tokens.ink2),
            ),
          ],

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 仓库 ----------------
          _sectionTitle(t.sectionRepository),
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
          _sectionTitle(t.sectionDeveloper),
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
          _sectionTitle(t.sectionOtherSoftware),
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
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
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

/// 文字按钮；`onTap == null` 即禁用（在线升级用这个态）。
class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final bool enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: buttonKey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: enabled ? tokens.hairStrong : tokens.hair,
          ),
        ),
        child: Text(
          label,
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
