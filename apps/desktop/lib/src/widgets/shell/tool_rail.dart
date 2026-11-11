import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../../theme/density_profile.dart';

/// 右工具轨的一块面板：标题 + 任意真实数据内容。
///
/// 骨架不认识业务，面板一律由调用方注入（裁定 G：不得 import `pages/*`）。
@immutable
class ShellRailPanel {
  /// 创建面板声明。
  const ShellRailPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  /// 面板小标题（原型 `.rail h3`）。
  final String title;

  /// 面板内容，必须是真实数据控件，不得是占位按钮。
  final Widget child;

  /// 面板头右上角的动作位（今日页两枚 `＋` 用）。
  ///
  /// 为 `null` 时标题行只有一个小标题 `Text`，与加动作位之前的布局逐字等价。
  final Widget? trailing;
}

/// 右工具轨（等价原型 `aside.rail` / `aside.rail2`）。
///
/// 竖排（标准 / 宽屏）：固定宽度，左侧 1px `hair` 边，`18/16/26` 内边距。
/// 横排（`< 1280`）：宽度撑满，上边 1px `hair` 边，面板按 `minmax(210px, 1fr)`
/// 自动折列（等价原型 `.rail-in{grid-template-columns:repeat(auto-fit,minmax(210px,1fr))}`）。
class ToolRail extends StatelessWidget {
  /// 创建工具轨。
  const ToolRail({
    this.panels = const <ShellRailPanel>[],
    this.stacked = false,
    this.width = railWidth,
    super.key,
  });

  /// 第一栏宽度（`--rail-w`）。
  static const double railWidth = 290;

  /// 宽屏第三栏宽度（`--rail2-w`）。
  static const double rail2Width = 286;

  /// 面板间距（`.rail-in{gap:14px}`）。
  static const double panelGap = 14;

  /// 折列最小列宽（`minmax(210px,1fr)`）。
  static const double minColumnWidth = 210;

  /// 注入的面板列表。
  final List<ShellRailPanel> panels;

  /// 是否为账页下方的横排模式（`< 1280`）。
  final bool stacked;

  /// 竖排时的栏宽。
  final double width;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppTokens.sunken, AppTokens.paper],
            stops: <double>[0, 0.34],
          ),
          border: Border(top: BorderSide(color: AppTokens.hair)),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return _PanelGrid(
              panels: panels,
              available: constraints.maxWidth,
            );
          },
        ),
      );
    }

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppTokens.sunken, AppTokens.paper],
          stops: <double>[0, 0.34],
        ),
        border: Border(left: BorderSide(color: AppTokens.hair)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < panels.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: panelGap),
              _RailPanelChrome(panel: panels[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// 自动折列的面板网格（等价 `repeat(auto-fit, minmax(210px, 1fr))`）。
class _PanelGrid extends StatelessWidget {
  const _PanelGrid({required this.panels, required this.available});

  final List<ShellRailPanel> panels;
  final double available;

  @override
  Widget build(BuildContext context) {
    final int columns = _columnCount(available);
    final List<Widget> rows = <Widget>[];
    for (int start = 0; start < panels.length; start += columns) {
      final List<ShellRailPanel> slice = panels.sublist(
        start,
        (start + columns).clamp(0, panels.length),
      );
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: ToolRail.panelGap));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < columns; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: ToolRail.panelGap),
                Expanded(
                  child: i < slice.length
                      ? _RailPanelChrome(panel: slice[i])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  int _columnCount(double width) {
    if (!width.isFinite || width <= ToolRail.minColumnWidth) {
      return 1;
    }
    final int count =
        ((width + ToolRail.panelGap) /
                (ToolRail.minColumnWidth + ToolRail.panelGap))
            .floor();
    return count < 1 ? 1 : count;
  }
}

/// 面板外观：1px `hair-soft` 边 + 4px 圆角 + `card` 底 + `12px 13px` 内边距。
///
/// hover 时边框升到 `hair`（原型 `.panel:hover`）。面板本身不可点击。
class _RailPanelChrome extends StatefulWidget {
  const _RailPanelChrome({required this.panel});

  final ShellRailPanel panel;

  @override
  State<_RailPanelChrome> createState() => _RailPanelChromeState();
}

class _RailPanelChromeState extends State<_RailPanelChrome> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    final Widget titleText = Text(
      widget.panel.title,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
        fontSize: labelSize,
        height: 1.3,
        letterSpacing: labelSize * 0.1,
        fontWeight: FontWeight.w600,
        color: AppTokens.faint,
      ),
    );
    final Widget? trailing = widget.panel.trailing;
    // `trailing == null` ⇒ 面板头仍然只有 `titleText` 一个 `Text`，
    // 与加动作位之前完全一致（不引入 `Row` / `Spacer`，避免多出半像素）。
    final Widget header;
    if (trailing == null) {
      header = titleText;
    } else {
      header = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: titleText),
          const SizedBox(width: 6),
          trailing,
        ],
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: _hovered ? AppTokens.hair : AppTokens.hairSoft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            header,
            const SizedBox(height: 9),
            widget.panel.child,
          ],
        ),
      ),
    );
  }
}

/// 面板头右上角的加号动作位（`＋`）。
///
/// 视觉纪律：只用 `--ink` 字色与 `--sunken` hover 底，**不用赭石、不用彩色、
/// 不用 emoji 字形**；命中区 22×22（派工书要求 ≥ 20×20）。
/// `InkWell` 自带焦点节点 ⇒ 可以 `Tab` 聚焦、`Enter` / `Space` 触发。
///
/// [label] 是无障碍名（`添加待办` / `添加习惯`），也是测试定位依据之一。
class RailAddButton extends StatefulWidget {
  /// 创建加号动作位。
  const RailAddButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// 无障碍名与 tooltip 语义（`添加待办` / `添加习惯`）。
  final String label;

  /// 点击动作。
  final VoidCallback onPressed;

  @override
  State<RailAddButton> createState() => _RailAddButtonState();
}

class _RailAddButtonState extends State<RailAddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // `container: true` ⇒ 自成语义节点，不与子级合并；`excludeSemantics: true`
    // ⇒ 读屏只报无障碍名，不把装饰用的 `＋` 一起念出来；`onTap` 挂在本节点上，
    // 保证排除子级语义后读屏仍能触发。指针与 `Tab` 焦点仍由内部 `InkWell` 负责。
    return Semantics(
      button: true,
      label: widget.label,
      container: true,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered ? AppTokens.sunken : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: Text(
                  '＋',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontFamilyFallback: AppFonts.bodyFallback,
                    fontSize: 13,
                    height: 1,
                    color: AppTokens.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}