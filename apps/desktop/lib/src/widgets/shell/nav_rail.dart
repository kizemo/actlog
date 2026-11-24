import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
/// 六项都有真实落点（Task 56 起「项目」页落地，不再是禁用项）。
///
/// 口径（Task 61）：这一份**中文常量**保留不动（既有测试直接断言它），
/// 但运行期不再用它渲染 —— 渲染走 [shellNavItemsFor]，按当前语言现搭。
const List<ShellNavItem> kShellNavItems = <ShellNavItem>[
  ShellNavItem(id: 'today', label: '日志'),
  ShellNavItem(id: 'inbox', label: '待办池'),
  ShellNavItem(id: 'habits', label: '习惯'),
  ShellNavItem(id: 'projects', label: '项目'),
  ShellNavItem(id: 'calendar', label: '日历'),
  ShellNavItem(id: 'settings', label: '设置'),
];

/// 运行时构建 6 项主导航（文案走 l10n）。
///
/// `const` 顶层列表不能在编译期常量里调 `t.xxx`，所以运行期的清单在这里现搭；
/// zh 态的取值与 [kShellNavItems] 逐字相同（那一份常量保留下来，供既有测试
/// 直接断言，也留作中文快照）。项的 id / 启用态与常量那份完全一致 ⇒ 导航行为
/// 不因本地化而变。
List<ShellNavItem> shellNavItemsFor(AppLocalizations t) => <ShellNavItem>[
  ShellNavItem(id: 'today', label: t.shellNavToday),
  ShellNavItem(id: 'inbox', label: t.shellNavInbox),
  ShellNavItem(id: 'habits', label: t.shellNavHabits),
  ShellNavItem(id: 'projects', label: t.shellNavProjects),
  ShellNavItem(id: 'calendar', label: t.shellNavCalendar),
  ShellNavItem(id: 'settings', label: t.shellNavSettings),
];

/// 左主导航（等价原型 `nav.nav`）。
///
/// 竖排：[width] 固定宽、右侧 1px `hair` 边、`18/14/12` 内边距，
/// 品牌块 + 6 项（mono 序号 `01`–`06`）+ 底部 `.nav-foot`。
/// 横排（`< 1280`）：撑满宽度、顶栏横排、下边 1px `hair` 边、隐藏 `.nav-foot`。
class NavRail extends StatelessWidget {
  /// 创建主导航。
  const NavRail({
    this.items,
    this.currentId,
    this.onSelected,
    this.horizontal = false,
    super.key,
  });

  /// 竖排栏宽（`--nav-w`）。
  static const double width = 214;

  /// 导航项列表；`null` ⇒ 按当前语言现搭（[shellNavItemsFor]）。
  final List<ShellNavItem>? items;

  /// 当前页 id；命中项渲染 ink 洗底。
  final String? currentId;

  /// 选中回调；禁用项不会触发。
  final ValueChanged<String>? onSelected;

  /// 是否为顶栏横排模式（`< 1280`）。
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = shellLocalizationsOf(context);
    final List<ShellNavItem> resolvedItems = items ?? shellNavItemsFor(t);
    return horizontal
        ? _buildBar(context, t, resolvedItems)
        : _buildColumn(context, t, resolvedItems);
  }

  Widget _buildColumn(
    BuildContext context,
    AppLocalizations t,
    List<ShellNavItem> items,
  ) {
    final ThemeTokens tokens = context.tokens;
    final List<Widget> children = <Widget>[
      _Brand(t: t, showSubtitle: true, padded: true),
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
      ..add(_NavFoot(t: t));
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        // 原型 `linear-gradient(180deg,#F3F1EA 0%,var(--paper) 46%)`；
        // `#F3F1EA` 不在 token 里，用最近的下沉色 sunken 作起点，不新增颜色常量。
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[tokens.sunken, tokens.paper],
          stops: const <double>[0, 0.46],
        ),
        border: Border(right: BorderSide(color: tokens.hair)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    AppLocalizations t,
    List<ShellNavItem> items,
  ) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[tokens.sunken, tokens.paper],
          stops: const <double>[0, 0.46],
        ),
        border: Border(bottom: BorderSide(color: tokens.hair)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _Brand(t: t, showSubtitle: false, padded: false),
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
///
/// 主标题走 `t.appName`（zh `知行日志` / en `actlog`）；副标题 `actlog` **只在
/// 中文态显示** —— 英文态主标题本身就是 `actlog`，两行同字就是重复（Task 61
/// 已登记的取舍，不为它新增 getter）。
class _Brand extends StatelessWidget {
  const _Brand({
    required this.t,
    required this.showSubtitle,
    required this.padded,
  });

  /// 当前语言的文案表。
  final AppLocalizations t;

  /// 是否显示副标题行（横排模式下不显示）。
  final bool showSubtitle;

  /// 是否带品牌块的边框与内边距。
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    return Container(
      padding: padded
          ? const EdgeInsets.only(left: 6, right: 6, bottom: 14)
          : EdgeInsets.zero,
      decoration: padded
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.hair)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.appName,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontFamilyFallback: AppFonts.displayFallback,
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.38,
              color: tokens.ink,
            ),
          ),
          if (showSubtitle && t.language == AppLanguage.zh) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              'actlog',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: labelSize,
                height: 1.3,
                letterSpacing: labelSize * 0.07,
                color: tokens.faint,
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
    final ThemeTokens tokens = context.tokens;
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
        ? tokens.inkWash
        : (_hovered && enabled ? tokens.sunken : Colors.transparent);
    final Color labelColor = !enabled
        ? tokens.faint
        : (selected || _hovered ? tokens.ink : tokens.meta);
    final Color indexColor = selected ? tokens.ink : tokens.faint;

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
          // 标签用 `Flexible`（**松**配合），不是写死宽度，也不是 `Expanded`：
          // * 中文标签只有 2–3 个汉字（实测 29.5 / 44.25px），远小于净宽 169px
          //   ⇒ 松配合下它仍按自身宽度渲染，**中文态逐像素不变**（同宽同位置）；
          // * 英文标签更长（实测最长 `To-do Pool` 147.5px，净宽 169px ⇒ 硬排
          //   溢出 6.3px）⇒ 松配合把「序号盒 + 间隔」之外的空间整块留给标签
          //   （上限 141.25px），超出就**换行**，既不截断也不丢字形；
          // * 用 `Expanded`（紧配合）会把中文标签的盒子也拉成 141.25px 宽，
          //   中文态的字形位置虽不变、盒子却变了 ⇒ 不用。
          // 横排模式（< 1280）那行在**横向滚动视图**里 ⇒ 主轴无界 ⇒
          // `Flexible` 退化成非弹性子件（标签仍按自身宽度排），行为与改前一致。
          Flexible(
            child: Text(
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

/// 导航底注（`.nav-foot`）：页面切换 Ctrl + 1 … 5。
///
/// 口径（Task 20 · N1 / B2 + Task 56）：只宣称**真实存在**的 `Ctrl+1`–`Ctrl+5`
/// （今日 / 待办池 / 习惯 / 日历 / 项目）。`Ctrl+6` 没有落点 ⇒ 写「… 6」
/// 就是假提示。字符总数仍为 12（`页面切换`4 + `Ctrl`4 + `+`1 + `1`1 + `…`1 + `5`1）。
///
/// 排版分两档：
/// * 常规档：一个 `Wrap`，与原型一致（「页面切换 Ctrl + 1 … 5」排成一行）。
/// * 大字号档（缩放 ≥ 1.5×，如 `ACTLOG_TEXT_SCALE=2`）：三行堆叠 ——
///   「页面切换」/「Ctrl + 1」/「… 5」，第 3 行**必须有内容**。
///
/// 换行点由**结构**保证，不靠像素宽度碰运气：复合单位用
/// `Row(mainAxisSize: max)` 撑满整行，外层 `Wrap` 必然让它独占一行。
/// 宽度断行在不同字体度量下位置并不相同（真机拉丁字形窄、测试环境宽），
/// 靠「量一下会不会正好放得下」只会得到一台机器上成立、另一台上不成立的结果。
class _NavFoot extends StatelessWidget {
  const _NavFoot({required this.t});

  /// 当前语言的文案表。
  final AppLocalizations t;

  /// 大字号档阈值（相对基准字号的缩放倍数）。
  static const double largeTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final double labelSize =
        Theme.of(context).textTheme.labelSmall?.fontSize ??
        DensityProfile.comfortable.labelSize;
    final TextStyle textStyle = TextStyle(
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: labelSize,
      height: 1.3,
      color: tokens.faint,
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
      children: <Widget>[Text('…', style: textStyle), const KeyCap('5')],
    );

    return Container(
      // 大字号档下第 2 行「Ctrl + 1」需要整行宽度；底注内容一律左对齐、
      // 右边缘离导航栏内边还差着一截 ⇒ 右侧不留白，把宽度让给第 2 行。
      padding: EdgeInsets.only(top: 10, left: 8, right: largeText ? 0 : 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.hair)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // 「页面切换」本身是 4 个字，最窄也只断成两字一行，不会留孤字。
          Text(t.shellPageSwitch, style: textStyle),
          if (largeText)
            // 撑满整行 ⇒ 独占一行（第 2 行「Ctrl + 1」）。
            Row(mainAxisSize: MainAxisSize.max, children: <Widget>[keyGroup])
          else
            keyGroup,
          if (largeText)
            // 同理，第 3 行「… 5」独占一行且非空。
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