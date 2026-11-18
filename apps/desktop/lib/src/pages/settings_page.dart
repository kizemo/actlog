import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../theme/density_profile.dart';

/// 设置页：`kShellNavItems` 里「设置」项的真实落点（B1 / B2）。
///
/// 本页是壳内**内容体**，不自建 `Scaffold`：滚动由 `LedgerPaper` 负责。
/// 因此根节点是 `mainAxisSize: min` 的 `Column` —— 换成 `ListView` 会在
/// 壳的滚动容器里拿到无界高度而抛 `RenderBox was not laid out`。
///
/// 为什么套一层 `Material`：`Switch` / `InkWell` / `AlertDialog` 的 `InkResponse`
/// 都要求 `Material` 祖先。壳内虽然有，但 widget test 会**直接 pump 本页**
/// （brief §5「必须是普通 widget，能被 widget test 直接 pump」），没有这一层
/// 就会在 `Material.of(context)` 断言里崩掉。
///
/// 持久化口径：一律走既有 `SettingsRepository` 的通用 KV（键见
/// `providers.dart` 的 `settingsKey*` 常量），**不新增仓库方法、不改 schema**。
class SettingsPage extends ConsumerStatefulWidget {
  /// 创建设置页。
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// 上一次操作的反馈文案（创建快捷方式 / 开机启动失败等）。
  ///
  /// 为什么不用 `SnackBar`：本页是壳内内容体，没有自己的 `Scaffold`，拿不到
  /// `ScaffoldMessenger`。行内一行灰字既够用，也不会在测试里要求额外的脚手架。
  String? _status;

  /// 注册表里「开机启动」的**真实**状态（读完之前开关不可操作）。
  bool _bootOn = false;

  /// 是否已从注册表读回过一次。
  bool _bootLoaded = false;

  /// 恢复默认的确认弹窗是否打开（防连点重复叠三层）。
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    // 首帧之后再读注册表：`readLaunchOnBoot` 起子进程，不能在 `initState`
    // 里同步等；同时避免在 build 阶段触发 `setState`。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBootState();
    });
  }

  Future<void> _loadBootState() async {
    final SystemIntegration system = ref.read(systemIntegrationProvider);
    final String? value = await system.readLaunchOnBoot();
    if (!mounted) {
      return;
    }
    setState(() {
      _bootLoaded = true;
      _bootOn = value != null && value.isNotEmpty;
    });
  }

  Future<void> _toggleBoot(bool enabled) async {
    final AppLocalizations t = ref.read(appLocalizationsProvider);
    final SystemIntegration system = ref.read(systemIntegrationProvider);
    // 顺序：先动系统，成功才写偏好。反过来会出现「偏好说开机启动、注册表
    // 里其实没有」的假绿状态。
    final bool ok = await system.setLaunchOnBoot(enabled);
    if (!mounted) {
      return;
    }
    if (!ok) {
      setState(() {
        _status = t.operationFailed;
      });
      return;
    }
    await ref.read(preferencesStoreProvider).setLaunchOnBoot(enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _bootOn = enabled;
      _status = null;
    });
  }

  Future<void> _createShortcut() async {
    final AppLocalizations t = ref.read(appLocalizationsProvider);
    final bool ok =
        await ref.read(systemIntegrationProvider).createDesktopShortcut();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = ok ? t.shortcutCreated : t.operationFailed;
    });
  }

  Future<void> _setPriorityMode(PriorityDisplayMode mode) async {
    await ref.read(repositoriesProvider).settings.setPriorityDisplayMode(mode);
    ref.invalidate(priorityDisplayModeProvider);
  }

  Future<void> _confirmReset() async {
    if (_resetting) {
      return;
    }
    final AppLocalizations t = ref.read(appLocalizationsProvider);
    _resetting = true;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t.resetPreferences),
        content: Text(t.resetPreferencesConfirm),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('settings-reset-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            key: const ValueKey<String>('settings-reset-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
    _resetting = false;
    if (ok != true || !mounted) {
      return;
    }
    await ref.read(preferencesStoreProvider).resetToDefaults();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = t.resetDone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeTokens tokens = context.tokens;
    final AppPreferences prefs = ref.watch(currentPreferencesProvider);
    final AppLocalizations t = ref.watch(appLocalizationsProvider);
    // 该 provider 是 `FutureProvider`：首帧还没有值时按默认档（四象限）渲染，
    // 值到了再重建 —— 不让设置页为一次数据库读取卡成空屏。
    final PriorityDisplayMode priorityMode =
        ref.watch(priorityDisplayModeProvider).asData?.value ??
            PriorityDisplayMode.quadrant;
    final String exePath = ref.watch(systemIntegrationProvider).executablePath();

    return Material(
      type: MaterialType.transparency,
      child: Column(
        key: const ValueKey<String>('settings-page'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.settingsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.settingsSubtitle,
            style: _hintStyle(tokens),
          ),
          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 外观 ----------------
          _sectionTitle(t.sectionAppearance),
          _SettingRow(
            label: t.sectionAppearance,
            hint: null,
            control: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-theme-system'),
                  label: t.themeSystem,
                  selected: prefs.themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setThemeMode(ThemeMode.system),
                ),
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-theme-light'),
                  label: t.themeLight,
                  selected: prefs.themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setThemeMode(ThemeMode.light),
                ),
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-theme-dark'),
                  label: t.themeDark,
                  selected: prefs.themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.gapSec),

          // ---------------- 语言 ----------------
          _SettingRow(
            label: t.sectionLanguage,
            hint: null,
            control: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-lang-zh'),
                  label: t.languageChinese,
                  selected: prefs.language == AppLanguage.zh,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setLanguage(AppLanguage.zh),
                ),
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-lang-en'),
                  label: t.languageEnglish,
                  selected: prefs.language == AppLanguage.en,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setLanguage(AppLanguage.en),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 系统集成 ----------------
          _sectionTitle(t.sectionSystem),
          _SettingRow(
            label: t.launchOnBoot,
            hint: t.launchOnBootHint,
            control: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Switch(
                  key: const ValueKey<String>('settings-launch-on-boot'),
                  value: _bootOn,
                  onChanged: _bootLoaded ? _toggleBoot : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.gapSec),
          _SettingRow(
            label: t.desktopShortcut,
            hint: t.desktopShortcutHint,
            control: Align(
              alignment: Alignment.centerLeft,
              child: _ActionButton(
                buttonKey: const ValueKey<String>('settings-shortcut-button'),
                label: t.desktopShortcut,
                onTap: _createShortcut,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${t.executablePath}  $exePath',
            key: const ValueKey<String>('settings-executable-path'),
            style: _monoStyle(tokens),
          ),
          if (_status != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _status!,
              key: const ValueKey<String>('settings-status'),
              style: _monoStyle(tokens).copyWith(color: tokens.ink2),
            ),
          ],

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 每天计划窗口（驱动网格裁剪，B8） ----------------
          _sectionTitle(t.sectionPlanWindow),
          _SettingRow(
            label: t.planStart,
            hint: null,
            control: _HourDropdown(
              dropdownKey: const ValueKey<String>('settings-plan-start'),
              value: prefs.dailyStartHour,
              first: 0,
              last: 23,
              onChanged: (int hour) => ref
                  .read(preferencesStoreProvider)
                  .setDailyWindow(hour, prefs.dailyEndHour),
            ),
          ),
          const SizedBox(height: AppTokens.gapSec),
          _SettingRow(
            label: t.planEnd,
            hint: null,
            control: _HourDropdown(
              dropdownKey: const ValueKey<String>('settings-plan-end'),
              value: prefs.dailyEndHour,
              first: 1,
              last: 24,
              onChanged: (int hour) => ref
                  .read(preferencesStoreProvider)
                  .setDailyWindow(prefs.dailyStartHour, hour),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.planWindowHint,
            key: const ValueKey<String>('settings-plan-window-hint'),
            style: _hintStyle(tokens),
          ),

          const SizedBox(height: AppTokens.gapCard),

          // ---------------- 其它（自选项） ----------------
          _sectionTitle(t.sectionOther),
          _SettingRow(
            label: t.density,
            hint: null,
            control: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-density-compact'),
                  label: t.densityCompact,
                  selected: prefs.density == DensityProfile.compact,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setDensity(DensityProfile.compact),
                ),
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-density-comfortable'),
                  label: t.densityComfortable,
                  selected: prefs.density == DensityProfile.comfortable,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setDensity(DensityProfile.comfortable),
                ),
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-density-roomy'),
                  label: t.densityRoomy,
                  selected: prefs.density == DensityProfile.roomy,
                  onTap: () => ref
                      .read(preferencesStoreProvider)
                      .setDensity(DensityProfile.roomy),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.gapSec),
          _SettingRow(
            label: t.priorityDisplayMode,
            hint: null,
            control: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-priority-quadrant'),
                  label: t.priorityQuadrant,
                  selected: priorityMode == PriorityDisplayMode.quadrant,
                  onTap: () => _setPriorityMode(PriorityDisplayMode.quadrant),
                ),
                _ChoiceChip(
                  chipKey: const ValueKey<String>('settings-priority-abc'),
                  label: t.priorityAbc,
                  selected: priorityMode == PriorityDisplayMode.abc,
                  onTap: () => _setPriorityMode(PriorityDisplayMode.abc),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.gapSec),
          _SettingRow(
            label: t.resetPreferences,
            hint: t.resetPreferencesHint,
            control: Align(
              alignment: Alignment.centerLeft,
              child: _ActionButton(
                buttonKey: const ValueKey<String>('settings-reset-button'),
                label: t.resetPreferences,
                onTap: _confirmReset,
              ),
            ),
          ),

          const SizedBox(height: AppTokens.gapCard),
          Text(
            t.settingsFootnote,
            style: _hintStyle(tokens),
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

/// 一行设置：标题 +（可选）说明 + 控件。
///
/// 为什么**竖排**而不是惯常的「左标题右控件」：本页控件里有三连 chip 与下拉，
/// 横排在 800px 测试视口 + 等宽测试字体下必然 `RenderFlex overflowed` ——
/// 那会让「看不全」变成一条测试错误，而不是一个视觉问题。
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.hint,
    required this.control,
  });

  final String label;
  final String? hint;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 13,
              height: 1.4,
              color: tokens.ink,
            ),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(hint!, style: _hintStyle(tokens)),
          ],
          const SizedBox(height: 6),
          control,
        ],
      ),
    );
  }
}

/// 二/三选一的文字块（主题、语言、密度、优先级显示）。
///
/// 为什么不用 `ChoiceChip`：Material 的 chip 有自己的高度与内边距，既撑高行距，
/// 也把 `AppTokens` 的字号体系撕开一个口子。这里只用 `InkWell` + `Container`。
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: chipKey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? tokens.ink : tokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: selected ? tokens.ink : tokens.hair,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 12,
            height: 1.2,
            color: selected ? tokens.paper : tokens.ink2,
          ),
        ),
      ),
    );
  }
}

/// 文字按钮（创建快捷方式 / 恢复默认）。
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        key: buttonKey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: tokens.hairStrong),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: 12,
            height: 1.2,
            color: tokens.ink,
          ),
        ),
      ),
    );
  }
}

/// 整点小时下拉（0..23 / 1..24）。
///
/// 为什么只给整点：网格的纵向单位是「一小时一行」（`kHourRowHeight`），起点
/// 落在 06:15 会让整点数字与刻度整体错开 15 分钟（详见 `DayWindow` 的注释）。
class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.dropdownKey,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
  });

  final Key dropdownKey;
  final int value;
  final int first;
  final int last;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return SizedBox(
      width: 96,
      child: DropdownButton<int>(
        key: dropdownKey,
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.bodyFallback,
          fontSize: 12,
          color: tokens.ink,
        ),
        onChanged: (int? next) {
          if (next != null) {
            onChanged(next);
          }
        },
        items: <DropdownMenuItem<int>>[
          for (int hour = first; hour <= last; hour++)
            DropdownMenuItem<int>(
              value: hour,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                key: ValueKey<String>('settings-hour-option-$hour'),
              ),
            ),
        ],
      ),
    );
  }
}

/// 说明文字的统一样式（11px 等宽 + `meta` 灰，与习惯页副信息同源）。
TextStyle _hintStyle(ThemeTokens tokens) => TextStyle(
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: 12,
      height: 1.5,
      color: tokens.meta,
    );

/// 机器可读文字的统一样式（路径、执行结果）。
TextStyle _monoStyle(ThemeTokens tokens) => TextStyle(
      fontFamily: AppFonts.mono,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: 11,
      height: 1.4,
      color: tokens.meta,
    );
