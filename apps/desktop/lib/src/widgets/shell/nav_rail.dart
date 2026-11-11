import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../../theme/density_profile.dart';
import 'key_bar.dart';

/// 一个主导航项。
@immutable
class ShellNavItem {
  /// 创建导航项。
  const ShellNavItem({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  /// 稳定标识（页面路由键，不是显示文案）。
  final String id;

  /// 显示文案。
  final String label;

  /// 是否有真实落点。[false] 时渲染为禁用态（无点击、无焦点）。
  final bool enabled;
}

/// 原型固定的 6 项主导航。
///
/// 「今日 / 待办池 / 习惯 / 日历」四项有真实落点；项目与设置本轮没有页面，
/// 一律禁用而不是做成假按钮（点击无落点等于骗用户）。
const List<ShellNavItem> kShellNavItems = <ShellNavItem>[
  ShellNavItem(id: 'today', label: '今日'),
  ShellNavItem(id: 'inbox', label: '待办池'),
  ShellNavItem(id: 'habits', label: '习惯'),
  // [未覆盖] 原因：计划 Task 19 未实现该页面
  ShellNavItem(id: 'projects', label: '项目', enabled: false),
  ShellNavItem(id: 'calendar', label: '日历'),
  // [未覆盖] 原因：计划 Task 19 未实现该页面
  ShellNavItem(id: 'settings', label: '设置', enabled: false),
];

/// 左主导航（等价原型 `nav.nav`）。
///
/// 竖排：[width] 固定宽、右侧 1px `hair` 边、`18/14/12` 内边距，
/// 品牌块 + 6 项（mono 序号 `01`–`06`）+ 底部 `.nav-foot`。
/// 横排（`< 1280`）：撑满宽度、顶栏横排、下边 1px `hair` 边、隐藏 `.nav-foot`。
class NavRail extends StatelessWidget {
  /// 创建主导航。
  const NavRail({
    this.items = kShellNavItems,
    this.currentId,
    this.onSelected,
    this.horizontal = false,
    super.key,
  });

  /// 竖排栏宽（`--nav-w`）。
  static const double width = 214;

  /// 导航项列表。
  final List<ShellNavItem> items;

  /// 当前页 id；命中项渲染 ink 洗底。
  final String? currentId;

  /// 选中回调；禁用项不会触发。
  final ValueChanged<String>? onSelected;

  /// 是否为顶栏横排模式（`< 1280`）。
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return horizontal ? _buildBar(context) : _buildColumn(context);
  }

  Widget _buildColumn(BuildContext context) {
    final List<Widget> children = <Widget>[
      _Brand(showSubtitle: true, padded: true),
      const SizedBox(height: 8),
    ];
    for (int i = 0; i < items.length; i++) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _NavRow(
            item: items[i],
            index: i,
            selected: items[i].id == currentId,
            onSelected: onSelected,
          ),
        ),
      );
    }
    children
      ..add(const Spacer())
      ..add(const _NavFoot());
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: const BoxDecoration(
        // 原型 `linear-gradient(180deg,#F3F1EA 0%,var(--paper) 46%)`；
        // `#F3F1EA` 不在 AppTokens 里，用最近的下沉色 sunken 作起点，不新增颜色常量。
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppTokens.sunken, AppTokens.paper],
          stops: <double>[0, 0.46],
        ),
        border: Border(right: BorderSide(color: AppTokens.hair)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppTokens.sunken, AppTokens.paper],
          stops: <double>[0, 0.46],
        ),
        border: Border(bottom: BorderSide(color: AppTokens.hair)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: _Brand(showSubtitle: false, padded: false),
            ),
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _NavRow(
                  item: items[i],
                  index: i,
                  selected: items[i].id == currentId,
                  onSelected: onSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 品牌块（`div.brand`）：知行日志 / actlog。
class _Brand extends StatelessWidget {
  const _Brand({required this.showSubtitle, required this.padded});

  final bool showSubtitle;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    return Container(
      padding: padded
          ? const EdgeInsets.only(left: 6, right: 6, bottom: 14)
          : EdgeInsets.zero,
      decoration: padded
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTokens.hair)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            '知行日志',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontFamilyFallback: AppFonts.displayFallback,
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.38,
              color: AppTokens.ink,
            ),
          ),
          if (showSubtitle) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              'actlog',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: labelSize,
                height: 1.3,
                letterSpacing: labelSize * 0.07,
                color: AppTokens.faint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 单个导航项：序号（mono）+ 文案。
///
/// 选中 = `inkWash` 洗底 + `ink` 字 + w500（裁定 A：反白只给 `.btn.pri` / `.chk` / `.cell`）。
/// 禁用项不渲染任何可点击/可聚焦控件。
class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.item,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final ShellNavItem item;
  final int index;
  final bool selected;
  final ValueChanged<String>? onSelected;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    // 序号盒子是**几何量**，必须按实际渲染字号算：`fontSize` 会被
    // `MediaQuery.textScaler` 放大（`ACTLOG_TEXT_SCALE`），而 `SizedBox` 的
    // 宽度不参与缩放。写死 `labelSize * 1.5` 时 200% 下文字宽度约为盒子的 2 倍
    // ⇒ 序号「01」被拆成上下两行。100% 下 `scaler.scale` 是恒等的，
    // 故 `scaledLabelSize == labelSize`，几何零变化。
    final double scaledLabelSize =
        MediaQuery.textScalerOf(context).scale(labelSize);
    final bool enabled = widget.item.enabled;
    final bool selected = widget.selected;

    final Color background = selected
        ? AppTokens.inkWash
        : (_hovered && enabled ? AppTokens.sunken : Colors.transparent);
    final Color labelColor = !enabled
        ? AppTokens.faint
        : (selected || _hovered ? AppTokens.ink : AppTokens.meta);
    final Color indexColor = selected ? AppTokens.ink : AppTokens.faint;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: scaledLabelSize * 1.5,
            child: Text(
              _pad2(widget.index + 1),
              // 兜底：即便将来字号再变，也只横向溢出，不会碎成两行。
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: labelSize,
                height: 1.3,
                color: indexColor,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            widget.item.label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 14.5,
              height: 1.35,
              color: labelColor,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(
        enabled: false,
        selected: false,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: content,
        ),
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: widget.onSelected == null
              ? null
              : () => widget.onSelected!(widget.item.id),
          onHover: (bool value) {
            if (_hovered != value) {
              setState(() => _hovered = value);
            }
          },
          // 底色由上面的 Material 承担，屏蔽 InkWell 自带的涂色避免叠色。
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: content,
        ),
      ),
    );
  }

  static String _pad2(int value) => value < 10 ? '0$value' : '$value';
}

/// 导航底注（`.nav-foot`）：页面切换 Ctrl + 1 … 4。
///
/// 口径（Task 20 · N1 / B2）：只宣称**真实存在**的 `Ctrl+1`–`Ctrl+4`
/// （今日 / 待办池 / 习惯 / 日历）。导航第 5/6 项是禁用项、没有落点 ⇒ 写「… 6」
/// 就是假提示。字符总数仍为 12（`页面切换`4 + `Ctrl`4 + `+`1 + `1`1 + `…`1 + `4`1）。
///
/// 排版分两档：
/// * 常规档：一个 `Wrap`，与原型一致（「页面切换 Ctrl + 1 … 4」排成一行）。
/// * 大字号档（缩放 ≥ 1.5×，如 `ACTLOG_TEXT_SCALE=2`）：三行堆叠 ——
///   「页面切换」/「Ctrl + 1」/「… 4」，第 3 行**必须有内容**。
///
/// 换行点由**结构**保证，不靠像素宽度碰运气：复合单位用
/// `Row(mainAxisSize: max)` 撑满整行，外层 `Wrap` 必然让它独占一行。
/// 宽度断行在不同字体度量下位置并不相同（真机拉丁字形窄、测试环境宽），
/// 靠「量一下会不会正好放得下」只会得到一台机器上成立、另一台上不成立的结果。
class _NavFoot extends StatelessWidget {
  const _NavFoot();

  /// 大字号档阈值（相对基准字号的缩放倍数）。
  static const double largeTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    final TextStyle textStyle = TextStyle(
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: labelSize,
      height: 1.3,
      color: AppTokens.faint,
    );
    // 字号被放大到 ≥ 1.5 倍 ⇒ 走「三行堆叠」结构。
    final double scaledLabelSize = MediaQuery.textScalerOf(context).scale(labelSize);
    final bool largeText = scaledLabelSize >= labelSize * largeTextScale;

    // 键帽组合按「组」参与换行：组内最小单位是 `_NavKeyRun`，
    // 每个单位自身 ≥ 2 个字符 ⇒ 不管怎么折行都不会出现孤立行。
    final Widget keyGroup = _NavKeyGroup(
      children: <Widget>[
        const KeyCap('Ctrl'),
        _NavKeyRun(
          children: <Widget>[Text('+', style: textStyle), const KeyCap('1')],
        ),
      ],
    );
    final Widget keyRun = _NavKeyRun(
      children: <Widget>[Text('…', style: textStyle), const KeyCap('4')],
    );

    return Container(
      // 大字号档下第 2 行「Ctrl + 1」需要整行宽度；底注内容一律左对齐、
      // 右边缘离导航栏内边还差着一截 ⇒ 右侧不留白，把宽度让给第 2 行。
      padding: EdgeInsets.only(top: 10, left: 8, right: largeText ? 0 : 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTokens.hair)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // 「页面切换」本身是 4 个字，最窄也只断成两字一行，不会留孤字。
          Text('页面切换', style: textStyle),
          if (largeText)
            // 撑满整行 ⇒ 独占一行（第 2 行「Ctrl + 1」）。
            Row(mainAxisSize: MainAxisSize.max, children: <Widget>[keyGroup])
          else
            keyGroup,
          if (largeText)
            // 同理，第 3 行「… 3」独占一行且非空。
            Row(mainAxisSize: MainAxisSize.max, children: <Widget>[keyRun])
          else
            keyRun,
        ],
      ),
    );
  }
}

/// 底注里不可再分的一个换行单位（如「＋ 1」「… 3」）。
///
/// 用 `Row(mainAxisSize: min)` 把两个符号绑成一体：其中任何一个是单字符
/// （`+` / `3`），单独成行就会变成孤字，所以它们必须同进同退。
class _NavKeyRun extends StatelessWidget {
  const _NavKeyRun({required this.children});

  /// 单位内子项，按顺序以 4px 间距横排。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 4),
          children[i],
        ],
      ],
    );
  }
}

/// 底注里的一组键帽组合（「Ctrl + 1」）。
///
/// 组内用 `Wrap` 而不是 `Row`：极端窄宽 / 超宽字体下组合会拆成
/// 「Ctrl」+「＋ 1」两段（各自仍 ≥ 2 个字符），而不是整组横向溢出
/// （`Row` 在 200% 的宽字体下会报 `RenderFlex overflowed`）。
class _NavKeyGroup extends StatelessWidget {
  const _NavKeyGroup({required this.children});

  /// 组内单位，按顺序以 4px 间距横排。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}