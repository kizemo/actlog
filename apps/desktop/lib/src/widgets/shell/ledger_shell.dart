import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme_tokens.dart';
import 'key_bar.dart';
import 'ledger_paper.dart';
import 'nav_rail.dart';
import 'tool_rail.dart';

/// B 版「墨径 · 账页流」骨架（等价原型 `div.app`）。
///
/// 结构（标准 / 宽屏，`>= 1280`）：
/// ```
/// Row[ 导航 214, Expanded( Column[ Expanded( Row[ 账页, 右轨 290, (宽屏) 第三栏 286 ] ), (可选) dock 行 ] ) ]
/// ```
/// 快捷键清单只有一份：渲染在右轨的「快捷键」面板里（`KeyHintList`）。
/// 底部快捷键条已按 Task 56 诉求③删除，壳层底部不再有第二份重复提示。
///
/// 底线：`dock` 行是**列里的兄弟**，不是浮层 —— 严禁 `Stack` + `Positioned`
/// 叠在正文上，否则正文最后一行会被行压住。
///
/// 窄屏（`< 1280`）：导航折叠成顶栏横排，右轨落到账页下方、与正文同一滚动区。
///
/// 骨架不认识业务：导航项、右轨面板、快捷键清单、正文一律由调用方注入
/// （裁定 G），本文件不得 import `pages/*`。
class LedgerShell extends StatelessWidget {
  /// 创建骨架。
  const LedgerShell({
    required this.content,
    this.navItems,
    this.currentNavId,
    this.onNavSelected,
    this.railPanels = const <ShellRailPanel>[],
    this.secondaryRailPanels = const <ShellRailPanel>[],
    this.keyHints,
    this.dock,
    this.pinnedHeader,
    super.key,
  });

  /// 导航栏宽度（`--nav-w`）。
  static const double navWidth = NavRail.width;

  /// 右工具轨宽度（`--rail-w`）。
  static const double railWidth = ToolRail.railWidth;

  /// 宽屏第三栏宽度（`--rail2-w`）。
  static const double rail2Width = ToolRail.rail2Width;

  /// 折叠断点：`< 1280` 导航转顶栏、右轨落到底部。
  static const double narrowBreakpoint = 1280;

  /// 第三栏断点：`>= 1920` 出现第三栏、账页放宽到 860。
  static const double wideBreakpoint = 1920;

  /// 账页正文。
  final Widget content;

  /// 导航项；`null` ⇒ 按当前语言现搭（[shellNavItemsFor]）。
  final List<ShellNavItem>? navItems;

  /// 当前页 id。
  final String? currentNavId;

  /// 导航选中回调。
  final ValueChanged<String>? onNavSelected;

  /// 右轨面板（第一栏）。
  final List<ShellRailPanel> railPanels;

  /// 宽屏第三栏面板；为空时宽屏也不渲染第三栏（不占位空栏）。
  final List<ShellRailPanel> secondaryRailPanels;

  /// 快捷键清单内容：渲染在右轨的「快捷键」面板里（`KeyHintList`）。
  ///
  /// 底部快捷键条已按 Task 56 诉求③删除，这份清单不再在壳层底部出现第二份。
  /// `null` ⇒ 按当前语言现搭（[shellKeyHintsFor]）。
  final List<ShellKeyHint>? keyHints;

  /// 壳层最底部的全宽独立布局行（今日页放习惯打卡条）。
  ///
  /// 与账页同一列、同在滚动区之外：结构上不可能遮挡正文最后一行。
  /// 底部快捷键条已按 Task 56 诉求③删除：快捷键清单只在右轨的「快捷键」面板
  /// （`KeyHintList`）里出现一份，壳层底部不再有第二份全宽提示行。
  /// 为 `null` 时整行不渲染（不占位、不留空白），例如待办池与日历页。
  final Widget? dock;

  /// 吸顶头（今日页放 `DateBar`）：透传给 [LedgerPaper]，落在滚动区之外。
  ///
  /// 骨架不知道头部内容是什么，只负责「它不属于滚动区」这一条结构事实；
  /// 为 `null` 时纸面结构与未引入本参数之前逐字一致（不加包裹层）。
  final Widget? pinnedHeader;

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final bool narrow = viewportWidth < narrowBreakpoint;
    final bool wide = viewportWidth >= wideBreakpoint;

    // 文案表从 context 取（`L10nScope`；取不到时回落中文态，理由见
    // [shellLocalizationsOf]）。导航项与快捷键清单在这里现搭 ⇒ 壳层不持有
    // 任何硬编码文案。
    final AppLocalizations t = shellLocalizationsOf(context);
    final List<ShellNavItem> resolvedNavItems =
        navItems ?? shellNavItemsFor(t);
    final List<ShellKeyHint> resolvedKeyHints =
        keyHints ?? shellKeyHintsFor(t);

    final List<ShellRailPanel> panels = <ShellRailPanel>[
      ...railPanels,
      if (resolvedKeyHints.isNotEmpty)
        ShellRailPanel(
          title: t.shellShortcutsTitle,
          child: KeyHintList(hints: resolvedKeyHints),
        ),
    ];

    return Material(
      color: context.tokens.paper,
      child: narrow
          ? _buildNarrow(context, resolvedNavItems, panels)
          : _buildWide(context, wide, resolvedNavItems, panels),
    );
  }

  Widget _buildNarrow(
    BuildContext context,
    List<ShellNavItem> navItems,
    List<ShellRailPanel> panels,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NavRail(
          key: const Key('shell-nav'),
          items: navItems,
          currentId: currentNavId,
          onSelected: onNavSelected,
          horizontal: true,
        ),
        Expanded(
          child: LedgerPaper(
            key: const Key('shell-ledger-paper'),
            maxWidth: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            pinnedHeader: pinnedHeader,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                content,
                ToolRail(
                  key: const Key('shell-rail'),
                  panels: panels,
                  stacked: true,
                ),
              ],
            ),
          ),
        ),
        ?dock,
      ],
    );
  }

  Widget _buildWide(
    BuildContext context,
    bool wide,
    List<ShellNavItem> navItems,
    List<ShellRailPanel> panels,
  ) {
    final List<Widget> columns = <Widget>[
      Expanded(
        child: LedgerPaper(
          key: const Key('shell-ledger-paper'),
          maxWidth: wide ? LedgerPaper.wideMaxWidth : LedgerPaper.standardMaxWidth,
          pinnedHeader: pinnedHeader,
          child: content,
        ),
      ),
      ToolRail(key: const Key('shell-rail'), panels: panels, width: railWidth),
      if (wide && secondaryRailPanels.isNotEmpty)
        ToolRail(
          key: const Key('shell-rail2'),
          panels: secondaryRailPanels,
          width: rail2Width,
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NavRail(
          key: const Key('shell-nav'),
          items: navItems,
          currentId: currentNavId,
          onSelected: onNavSelected,
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              Expanded(
                // 交叉轴必须 stretch：否则账页与右轨按内容高度收缩，
                // 横线底与栏边不会铺满视口（Row 默认居中给的是松约束）。
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: columns,
                ),
              ),
              ?dock,
            ],
          ),
        ),
      ],
    );
  }
}