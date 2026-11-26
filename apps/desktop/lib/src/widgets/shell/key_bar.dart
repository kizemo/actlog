import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_scope.dart';
import '../../theme/app_fonts.dart';
import '../../theme/density_profile.dart';
import '../../theme/theme_tokens.dart';

/// 一条快捷键提示：一个或多个键帽 + 一句动作说明。
@immutable
class ShellKeyHint {
  /// 创建快捷键提示。
  const ShellKeyHint({required this.keys, required this.label});

  /// 键帽文案（单键或多键组合，如 `Ctrl+N`）。
  final List<String> keys;

  /// 动作说明。
  final String label;
}

/// 骨架自带的快捷键清单（文案取自原型 `.keybar` 渲染脚本）。
///
/// 口径（C7 / K1 / K2）：**每一条都必须有真实绑定，且行为与文案一致**——
/// 留一条没有落点的提示就是假承诺，不允许。
///
/// 10 条的绑定位置：
/// - `Ctrl+N` → 今日页的 `Shortcuts`（手写一条弹层）；
/// - `Ctrl+D` → 同处（打卡第一条未打习惯）；
/// - `←→` → 同处 `_ShiftDayIntent`（输入态自动让位给光标移动）；
/// - `Space` → 今日计划**行级**焦点：切勾选（`done ⇄ pending`）；
/// - `Enter` → 今日计划**行级**焦点：打开「成果 / 进展」回填弹层；
/// - `Esc` → Flutter 框架 `WidgetsApp` 默认快捷键 `escape → DismissIntent`，
///   弹层由 `ModalRoute` 处理 `DismissIntent` 关闭；
/// - `Ctrl+1…4` → 壳宿主（`ShellHost`）的 `Shortcuts`：今日 / 待办池 / 习惯 / 日历；
/// - `Ctrl+5` → 同一处：项目页（Task 56 起有真实落点）；
/// - `Ctrl+6` → 同一处：目标页（Task 65 UI 半批 B1 起有真实落点）；
/// - `Ctrl+7` → 同一处：人生蓝图页（Task 72 补齐漏登的键条提示）。
///
/// 文案口径（Task 20 / K3）：`Space` 写「勾选 / 取消勾选」，不写原型那种
/// 「把这一行加进 / 拿出今日计划」的说法——本应用里这一行本来就在今日计划里，
/// 再这么说会误导用户；两者的动作等价（原型那边的计数 == 本应用 `done` 计数），
/// 只取更准的说法。差异登记在 Task 20 的 worker 报告里。
///
/// 口径（Task 61）：这一份**中文常量**保留不动（既有测试直接断言它），
/// 但运行期不再用它渲染 —— 渲染走 [shellKeyHintsFor]，按当前语言现搭。
const List<ShellKeyHint> kShellKeyHints = <ShellKeyHint>[
  ShellKeyHint(keys: <String>['Ctrl+N'], label: '＋ 手写一条'),
  ShellKeyHint(keys: <String>['Ctrl+D'], label: '打卡第一条未打习惯'),
  ShellKeyHint(keys: <String>['←→'], label: '切日期'),
  ShellKeyHint(keys: <String>['Space'], label: '勾选 / 取消勾选'),
  ShellKeyHint(keys: <String>['Enter'], label: '展开回填'),
  ShellKeyHint(keys: <String>['Esc'], label: '关闭弹层'),
  ShellKeyHint(keys: <String>['Ctrl+1…4'], label: '切页'),
  ShellKeyHint(keys: <String>['Ctrl+5'], label: '切到项目'),
  ShellKeyHint(keys: <String>['Ctrl+6'], label: '切到目标'),
  ShellKeyHint(keys: <String>['Ctrl+7'], label: '切到蓝图'),
];

/// 取当前语言的文案表；不在 [L10nScope] 之下时回落中文态。
///
/// 口径与 `widgets\shell\app_top_bar.dart` 同一形状：既有 widget 测试直接构造
/// 本目录的控件、**不套** `L10nScope`，用 `AppLocalizations.of(context)`
/// （缺失即抛 `FlutterError`）会把那些用例打挂；取不到 scope 时回落中文态。
/// 生产路径（应用根 widget 挂了 `L10nScope`）永远拿得到真实语言，
/// 所以「回落中文」只在测试与孤立构造场景发生。
///
/// 为什么住在 `key_bar.dart`：壳层三个文件（`nav_rail.dart` / `key_bar.dart` /
/// `ledger_shell.dart`）互相引用，`key_bar.dart` 是唯一被另外两个**都已 import**
/// 的底层文件 ⇒ 放这里不产生新的 import 环，也不新造第三套取法。
AppLocalizations shellLocalizationsOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<L10nScope>()?.localizations ??
    AppLocalizations.zh;

/// 运行时构建 10 条快捷键说明（文案走 l10n）。
///
/// `const` 顶层列表不能在编译期常量里调 `t.xxx`，所以运行期的清单在这里现搭；
/// zh 态的取值与 [kShellKeyHints] 逐字相同（那一份常量保留下来，供既有测试
/// 直接断言，也留作中文快照）。
List<ShellKeyHint> shellKeyHintsFor(AppLocalizations t) => <ShellKeyHint>[
  ShellKeyHint(keys: <String>['Ctrl+N'], label: t.shellKeyAddEntry),
  ShellKeyHint(keys: <String>['Ctrl+D'], label: t.shellKeyCheckFirstHabit),
  ShellKeyHint(keys: <String>['←→'], label: t.shellKeySwitchDate),
  ShellKeyHint(keys: <String>['Space'], label: t.shellKeyToggleCheck),
  ShellKeyHint(keys: <String>['Enter'], label: t.shellKeyExpandBackfill),
  ShellKeyHint(keys: <String>['Esc'], label: t.shellKeyClosePopup),
  ShellKeyHint(keys: <String>['Ctrl+1…4'], label: t.shellKeySwitchTab),
  ShellKeyHint(keys: <String>['Ctrl+5'], label: t.shellKeyGoProjects),
  ShellKeyHint(keys: <String>['Ctrl+6'], label: t.shellKeyGoGoals),
  ShellKeyHint(keys: <String>['Ctrl+7'], label: t.shellKeyGoBlueprint),
];

/// 键帽（等价原型 `kbd`）。
///
/// 口径：mono 11.5px + 1px 边框 + **下边 2px** + 3px 圆角 + `1px 5px` 内边距，
/// 底用 `card`、字用 `ink`（两色都从当前 `ThemeTokens` 解析）。
/// 公开出来是因为 `.nav-foot` 也要用同一枚键帽（原型同一套 `kbd` 规则）。
class KeyCap extends StatelessWidget {
  /// 创建键帽。
  const KeyCap(this.label, {super.key});

  /// 键帽文案。
  final String label;

  /// 键帽字号（原型 `.keybar kbd{font-size:11.5px}`）。
  static const double fontSize = 11.5;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          top: BorderSide(color: tokens.hair),
          left: BorderSide(color: tokens.hair),
          right: BorderSide(color: tokens.hair),
          bottom: BorderSide(color: tokens.hair, width: 2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: fontSize,
          height: 1.2,
          color: tokens.ink,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// 底部快捷键条（等价原型 `footer.keybar`）。
///
/// 口径：`keybg` 底 + 上边 `hair` + `7px 24px` 内边距 + `7px 14px` 间距；
/// 只作提示，不承载任何点击。
class KeyBar extends StatelessWidget {
  /// 创建快捷键条。
  const KeyBar({this.hints, super.key});

  /// 快捷键清单；`null` ⇒ 按当前语言现搭（[shellKeyHintsFor]）。
  final List<ShellKeyHint>? hints;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final List<ShellKeyHint> resolved =
        hints ?? shellKeyHintsFor(shellLocalizationsOf(context));
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.keybg,
        border: Border(top: BorderSide(color: tokens.hair)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final ShellKeyHint hint in resolved)
            _KeyHintItem(hint: hint, labelSize: labelSize),
        ],
      ),
    );
  }
}

/// 单条提示：键帽 + 说明。
class _KeyHintItem extends StatelessWidget {
  const _KeyHintItem({required this.hint, required this.labelSize});

  final ShellKeyHint hint;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String key in hint.keys) ...<Widget>[
          KeyCap(key),
          const SizedBox(width: 6),
        ],
        Text(
          hint.label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontFamilyFallback: AppFonts.bodyFallback,
            fontSize: labelSize,
            height: 1.3,
            color: tokens.meta,
          ),
        ),
      ],
    );
  }
}

/// 右轨「快捷键」面板里的竖排清单。
///
/// 与 [KeyBar] 共用同一份清单（都由 [shellKeyHintsFor] 按当前语言现搭），
/// 因此面板里显示的全是真实快捷键，不存在占位按钮。
class KeyHintList extends StatelessWidget {
  /// 创建竖排快捷键清单。
  const KeyHintList({this.hints, super.key});

  /// 快捷键清单；`null` ⇒ 按当前语言现搭（[shellKeyHintsFor]）。
  final List<ShellKeyHint>? hints;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final List<ShellKeyHint> resolved =
        hints ?? shellKeyHintsFor(shellLocalizationsOf(context));
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final ShellKeyHint hint in resolved)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String key in hint.keys)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: KeyCap(key),
                  ),
                Expanded(
                  child: Text(
                    hint.label,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontFamilyFallback: AppFonts.bodyFallback,
                      fontSize: labelSize,
                      height: 1.35,
                      color: tokens.meta,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}