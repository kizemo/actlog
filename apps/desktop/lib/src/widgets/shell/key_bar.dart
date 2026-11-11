import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../../theme/density_profile.dart';

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
/// 7 条的绑定位置：
/// - `Ctrl+N` → 今日页的 `Shortcuts`（手写一条弹层）；
/// - `Ctrl+D` → 同处（打卡第一条未打习惯）；
/// - `←→` → 同处 `_ShiftDayIntent`（输入态自动让位给光标移动）；
/// - `Space` → 今日计划**行级**焦点：切勾选（`done ⇄ pending`）；
/// - `Enter` → 今日计划**行级**焦点：打开「成果 / 进展」回填弹层；
/// - `Esc` → Flutter 框架 `WidgetsApp` 默认快捷键 `escape → DismissIntent`，
///   弹层由 `ModalRoute` 处理 `DismissIntent` 关闭；
/// - `Ctrl+1…3` → 壳宿主（`ShellHost`）的 `Shortcuts`：今日 / 待办池 / 日历。
///
/// 文案口径（Task 20 / K3）：`Space` 写「勾选 / 取消勾选」，不写原型那种
/// 「把这一行加进 / 拿出今日计划」的说法——本应用里这一行本来就在今日计划里，
/// 再这么说会误导用户；两者的动作等价（原型那边的计数 == 本应用 `done` 计数），
/// 只取更准的说法。差异登记在 Task 20 的 worker 报告里。
const List<ShellKeyHint> kShellKeyHints = <ShellKeyHint>[
  ShellKeyHint(keys: <String>['Ctrl+N'], label: '＋ 手写一条'),
  ShellKeyHint(keys: <String>['Ctrl+D'], label: '打卡第一条未打习惯'),
  ShellKeyHint(keys: <String>['←→'], label: '切日期'),
  ShellKeyHint(keys: <String>['Space'], label: '勾选 / 取消勾选'),
  ShellKeyHint(keys: <String>['Enter'], label: '展开回填'),
  ShellKeyHint(keys: <String>['Esc'], label: '关闭弹层'),
  ShellKeyHint(keys: <String>['Ctrl+1…3'], label: '切页'),
];

/// 键帽（等价原型 `kbd`）。
///
/// 口径：mono 11.5px + 1px 边框 + **下边 2px** + 3px 圆角 + `1px 5px` 内边距，
/// 底用 [AppTokens.card]、字用 [AppTokens.ink]。
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(3),
        border: const Border(
          top: BorderSide(color: AppTokens.hair),
          left: BorderSide(color: AppTokens.hair),
          right: BorderSide(color: AppTokens.hair),
          bottom: BorderSide(color: AppTokens.hair, width: 2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: fontSize,
          height: 1.2,
          color: AppTokens.ink,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
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
  const KeyBar({this.hints = kShellKeyHints, super.key});

  /// 快捷键清单。
  final List<ShellKeyHint> hints;

  @override
  Widget build(BuildContext context) {
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      decoration: const BoxDecoration(
        color: AppTokens.keybg,
        border: Border(top: BorderSide(color: AppTokens.hair)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final ShellKeyHint hint in hints)
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
            color: AppTokens.meta,
          ),
        ),
      ],
    );
  }
}

/// 右轨「快捷键」面板里的竖排清单。
///
/// 与 [KeyBar] 共用同一份 [kShellKeyHints]，因此面板里显示的全是真实快捷键，
/// 不存在占位按钮。
class KeyHintList extends StatelessWidget {
  /// 创建竖排快捷键清单。
  const KeyHintList({this.hints = kShellKeyHints, super.key});

  /// 快捷键清单。
  final List<ShellKeyHint> hints;

  @override
  Widget build(BuildContext context) {
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final ShellKeyHint hint in hints)
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
                      color: AppTokens.meta,
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