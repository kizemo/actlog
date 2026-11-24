// apps/desktop/lib/src/widgets/loop_progress_ring.dart
import 'package:flutter/material.dart';

import 'package:core_data/core_data.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 闭环环的四个可点段。
enum DayStatsSegment {
  /// 计划 x/y。
  plan,

  /// 回填 m/x。
  backfill,

  /// 复盘。
  review,

  /// 心态。
  mood,
}

/// 闭环四段里的一段（脊线与右栏「闭环提示」共用的一份数据）。
///
/// 比例口径只有 [loopSegmentEntries] 一处（内部走 `_ratio`）：任何界面
/// **不得**自己再算 `done / total`，也**不得**把分母为 0 当成 100%。
class LoopSegmentEntry {
  /// 创建一段。
  const LoopSegmentEntry({
    required this.segment,
    required this.label,
    required this.mark,
    required this.value,
    required this.ratio,
    required this.gap,
  });

  /// 对应段。
  final DayStatsSegment segment;

  /// 段名（脊线口径：`计划` / `回填` / `复盘` / `心态`）。
  final String label;

  /// 状态标记（`○` / `✓` / `▸` / `●`）。
  final String mark;

  /// 数值文案（脊线口径：`6/8` / `4/6` / `✓` / `▸`；分母为 0 是 `—`）。
  final String value;

  /// 0…1 的比例；分母为 0 时为 0（比例条为空）。
  final double ratio;

  /// 该段是否有缺口（决定比例条与文字的配色）。
  final bool gap;
}

/// 原型 `p(a,b)`：分母为 0 时算 0，不算 100%。
double _ratio(int done, int total) {
  if (total <= 0) {
    return 0;
  }
  return (done / total).clamp(0.0, 1.0);
}

/// [DayStats] → 四段（顺序即绘制顺序）。
///
/// 这是全项目唯一的四段比例口径：[LoopProgressRing]（中栏脊线）与
/// [LoopHintBar]（右栏闭环提示）都从这里取，避免出现第二份 `done / total`。
List<LoopSegmentEntry> loopSegmentEntries(
  DayStats stats,
  AppLocalizations l10n,
) {
  final double? rate = stats.backfillRate;
  return <LoopSegmentEntry>[
    LoopSegmentEntry(
      segment: DayStatsSegment.plan,
      label: l10n.domainPlanLabel,
      mark: stats.planPending > 0 ? '○' : '✓',
      value: '${stats.planDone}/${stats.planTotal}',
      ratio: _ratio(stats.planDone, stats.planTotal),
      gap: stats.planPending > 0,
    ),
    LoopSegmentEntry(
      segment: DayStatsSegment.backfill,
      label: l10n.domainBackfillLabel,
      mark: stats.planDone > stats.backfilled ? '▸' : '●',
      value: rate == null ? '—' : '${stats.backfilled}/${stats.planDone}',
      ratio: _ratio(stats.backfilled, stats.planDone),
      gap: stats.planDone > stats.backfilled,
    ),
    LoopSegmentEntry(
      segment: DayStatsSegment.review,
      label: l10n.domainReviewLabel,
      mark: stats.reviewDone ? '✓' : '▸',
      value: stats.reviewDone ? '✓' : '▸',
      ratio: stats.reviewDone ? 1 : 0,
      gap: !stats.reviewDone,
    ),
    LoopSegmentEntry(
      segment: DayStatsSegment.mood,
      label: l10n.domainMoodLabel,
      mark: stats.moodDone ? '✓' : '▸',
      value: stats.moodDone ? '✓' : '▸',
      ratio: stats.moodDone ? 1 : 0,
      gap: !stats.moodDone,
    ),
  ];
}

/// 顶部闭环脊线。
///
/// 原型对应 `.ridge` / `.seg` / `.bar` / `.ticks`：贯穿全宽的一条，
/// 四段各自「状态标记 + 标签 + 数值 + 5px 比例条 + 0/25/50/75/100 刻度」。
///
/// 数字全部来自 [DayStats]（唯一口径），本 widget **不自己算**。
class LoopProgressRing extends StatelessWidget {
  /// 创建闭环脊线。
  const LoopProgressRing({
    super.key,
    required this.stats,
    this.onJump,
    this.l10n = AppLocalizations.zh,
  });

  /// 当日统计。
  final DayStats stats;

  /// 点击某段时的回调（跳到对应段）。
  final void Function(DayStatsSegment segment)? onJump;

  /// 文案来源。
  ///
  /// 默认中文：本 widget 目前**没有生产实例**（仅测试直接 pump），
  /// 且既有测试用裸 `MaterialApp` 不带 `L10nScope` / `ProviderScope`，
  /// 故不强制调用方注入。生产接入时须传 `ref.watch(appLocalizationsProvider)`。
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThemeTokens tokens = context.tokens;
    final labelSize = theme.textTheme.labelLarge?.fontSize ?? 11.5;
    final entries = loopSegmentEntries(stats, l10n);

    return Container(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border(bottom: BorderSide(color: tokens.hair)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                l10n.todayLoopRingA11y,
                style: TextStyle(
                  fontSize: labelSize,
                  color: tokens.faint,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                l10n.todayLoopRingScale,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: labelSize,
                  color: tokens.meta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: tokens.hair),
          LayoutBuilder(
            builder: (context, constraints) {
              final perRow = constraints.maxWidth >= 760
                  ? 4
                  : (constraints.maxWidth >= 360 ? 2 : 1);
              final rows = <Widget>[];
              for (var start = 0; start < entries.length; start += perRow) {
                final end = (start + perRow).clamp(0, entries.length);
                final chunk = entries.sublist(start, end);
                if (rows.isNotEmpty) {
                  rows.add(Container(height: 1, color: tokens.hair));
                }
                // 格子可用宽度在此算好并按参数下传：外层 `IntrinsicHeight`
                // 会向子树要「最大固有高度」，而 `LayoutBuilder` 无法回答固有
                // 尺寸（运行时直接断言失败）⇒ 刻度行里不能再放 `LayoutBuilder`。
                final double cellWidth = constraints.maxWidth.isFinite
                    ? (constraints.maxWidth - (chunk.length - 1)) /
                          chunk.length
                    : double.infinity;
                rows.add(
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < chunk.length; i++) ...[
                          if (i > 0)
                            Container(width: 1, color: tokens.hair),
                          Expanded(
                            child: _Segment(
                              entry: chunk[i],
                              labelSize: labelSize,
                              leftPadding: i == 0 ? 0 : 12,
                              // 扣掉 `_Segment` 自己的左右内距（见其 `Padding`）。
                              tickRowWidth:
                                  cellWidth - (i == 0 ? 0 : 12) - 12,
                              onTap: onJump == null
                                  ? null
                                  : () => onJump!(chunk[i].segment),
                            ),
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
            },
          ),
        ],
      ),
    );
  }
}

/// 右栏「闭环提示」里的一行：状态标记 + 标签 + 数值 + 5px 比例条 + 刻度。
///
/// 与 [LoopProgressRing] 共用 [loopSegmentEntries]：比例与缺口判定**不在本类
/// 重算**，本类只决定「用哪段文案、画在哪」。
///
/// 紧凑形态（右栏窄栏，远小于 760px）单列竖排、不叠卡片边（右轨面板容器
/// 已有内距），也不做脊线那种按宽度 4/2/1 列排布的栅格（R-6）。
///
/// 刻度行的可用宽度由 [availableWidth] 传入而不是本类用 `LayoutBuilder`
/// 自己量：右轨在 `< 1280` 的折叠模式下被 `IntrinsicHeight` 包着，
/// `LayoutBuilder` 不支持固有尺寸（运行时断言失败）。
class LoopHintBar extends StatelessWidget {
  /// 创建右栏一行。
  const LoopHintBar({
    super.key,
    required this.entry,
    this.label,
    this.value,
    this.availableWidth = double.infinity,
    this.showTicks = true,
  });

  /// 该段的比例 / 缺口 / 状态标记（来自 [loopSegmentEntries]）。
  final LoopSegmentEntry entry;

  /// 覆写标签（右栏口径如「计划缺口」）；缺省用段名。
  final String? label;

  /// 覆写数值（右栏口径如「2」）；缺省用脊线口径（如 `6/8`）。
  final String? value;

  /// 刻度行可用的逻辑宽度（`Infinity` 表示宽度无界，按自然宽度铺开）。
  final double availableWidth;

  /// 是否在本行下方画 `0 / 25 / 50 / 75 / 100` 刻度行（默认画）。
  ///
  /// 右栏「闭环提示」把四行并成一列后，四行各画一条坐标轴会得到 4 条
  /// 完全重复的刻度（20 个刻度标签）⇒ 该面板改为 `showTicks: false`，
  /// 由 [LoopTickAxis] 在整块面板底部**只画一条**。默认 `true` ⇒ 既有
  /// 调用点的行为逐字不变。
  final bool showTicks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThemeTokens tokens = context.tokens;
    final labelSize = theme.textTheme.labelLarge?.fontSize ?? 11.5;
    final accentColor = entry.gap ? tokens.accentInk : tokens.ink2;
    final headColor = entry.gap ? tokens.accentInk : tokens.meta;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                entry.mark,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 12,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              // 窄栏里标签先截断也不挤出横向边界（R-6）；数值永远完整。
              // 标签与数值按 3:2 分摊剩余宽度：实测中文态 200% 时最长的四字标签
              // 「计划缺口 / 回填缺口」宽 101.6px，仍小于 3 份（可用 229 时 ≈116px），
              // 所以中文态的截断临界点没有被改动过。
              Expanded(
                flex: 3,
                child: Text(
                  label ?? entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelSize,
                    color: headColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 数值占剩余宽的 2 份，并交给 `FittedBox(scaleDown)` 等比缩小。
              // 起因（实测）：英文态 200% 下 `Not written` 自然宽 286px，加标记 24px
              // 与两处 6px 间距已达 322px > 可用 229px ⇒ 只要数值按自然宽度排版，
              // 无论标签怎么压缩都会溢出 96px。给数值**有界**区域后由 `FittedBox`
              // 缩到刚好装下：不换行、不截断、不裁切（与下方 `_TickRow` 同一手法）。
              // `Align(centerRight)` 保证数值照旧贴右边缘；中文态数值 ≤52px < 77px，
              // 既不缩放也不位移，像素不变。
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value ?? entry.value,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontFamilyFallback: AppFonts.monoFallback,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 静态填充（不走 500ms 补间）：右栏是读数面板，比例要能一眼读定；
          // 也让测试能直接读 `FractionallySizedBox.widthFactor` 判比例，
          // 不必靠像素猜。
          ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
            child: Container(
              height: 5,
              color: tokens.hairSoft,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: entry.ratio,
                  heightFactor: 1,
                  child: Container(
                    color: entry.gap ? tokens.accent : tokens.ink2,
                  ),
                ),
              ),
            ),
          ),
          if (showTicks) ...<Widget>[
            const SizedBox(height: 3),
            _TickRow(
              availableWidth: availableWidth,
              textStyle: LoopTickAxis.tickStyle(tokens),
            ),
          ],
        ],
      ),
    );
  }
}

/// 整块面板共用的一条 `0 / 25 / 50 / 75 / 100` 坐标轴。
///
/// 「闭环提示」四行各有自己的 5px 比例条，但刻度只画一次：四行各画一条会得到
/// 4 条逐字重复的坐标轴（20 个刻度标签），视觉偏重且没有信息增量。调用方用
/// `LoopHintBar(showTicks: false)` 关掉逐行刻度，再在本面板底部放这一条。
///
/// 刻度口径与 [LoopHintBar] 的逐行刻度**完全相同**（复用同一个 [_TickRow]：
/// 同一套文案、同一套「放不下就整行等比缩小、不换行、不截断」策略），也
/// **不自己用 `LayoutBuilder`** 量宽度（右轨折叠模式外层是 `IntrinsicHeight`，
/// `LayoutBuilder` 不支持固有尺寸 ⇒ 运行时断言失败）—— 可用宽度由
/// [availableWidth] 传入，与 [LoopHintBar] 同一口径。
class LoopTickAxis extends StatelessWidget {
  /// 创建一条共用坐标轴。
  const LoopTickAxis({
    super.key,
    this.availableWidth = double.infinity,
    this.padding = const EdgeInsets.only(top: 1, bottom: 2),
  });

  /// 可用的逻辑宽度（`Infinity` 表示宽度无界，按自然宽度铺开）。
  final double availableWidth;

  /// 轴自身的内距（默认上方 1px 与最后一行比例条分档、下方 2px 收口）。
  final EdgeInsetsGeometry padding;

  /// 刻度文案（顺序即绘制顺序）。
  static const List<String> ticks = _TickRow.ticks;

  /// 刻度字样式（与 [LoopHintBar] 的逐行刻度同一套）。
  ///
  /// 颜色随主题解析 ⇒ 必须是方法而不是 `static const` 字段：深色档的刻度色
  /// 与浅色档不同，常量无法随主题切换。
  static TextStyle tickStyle(ThemeTokens tokens) => TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 9.5,
    color: tokens.faint,
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _TickRow(
        availableWidth: availableWidth,
        textStyle: tickStyle(context.tokens),
      ),
    );
  }
}

/// 单段：状态标记 + 标签 + 数值 + 5px 比例条 + 刻度。
class _Segment extends StatefulWidget {
  const _Segment({
    required this.entry,
    required this.labelSize,
    required this.leftPadding,
    required this.tickRowWidth,
    required this.onTap,
  });

  final LoopSegmentEntry entry;
  final double labelSize;
  final double leftPadding;

  /// 刻度行可用的逻辑宽度（由外层 `LayoutBuilder` 预算，本层不再自己量）。
  final double tickRowWidth;

  final VoidCallback? onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final entry = widget.entry;
    final accentColor = entry.gap ? tokens.accentInk : tokens.ink;
    final headColor = entry.gap ? tokens.accentInk : tokens.meta;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? tokens.sunken : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Padding(
            padding: EdgeInsets.fromLTRB(widget.leftPadding, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      entry.mark,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontFamilyFallback: AppFonts.monoFallback,
                        fontSize: 13,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 标签是唯一会变长的子项（走 l10n，英文如 `Backfill` 实测
                    // 116.8px），必须可收缩：省略号截断，而不是把整行撑爆
                    // （en 态实测溢出 8.6px）。剩余宽度几乎全部（1000/1001）交给
                    // 标签，只留 1 份给下面的 `Spacer` —— 两者都是紧约束，合计仍等于
                    // 剩余宽，所以数值照旧贴右边缘，中文态的截断临界点（≈整条剩余宽）
                    // 与改动前「放不下才溢出」的临界点一致，像素不变。
                    Expanded(
                      flex: 1000,
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.labelSize,
                          color: headColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontFamilyFallback: AppFonts.monoFallback,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.5),
                  child: Container(
                    height: 5,
                    color: tokens.hairSoft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: entry.ratio),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value,
                            heightFactor: 1,
                            child: Container(
                              color: entry.gap ? tokens.accent : tokens.ink2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                _TickRow(
                  availableWidth: widget.tickRowWidth,
                  textStyle: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 10.5,
                    color: tokens.faint,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 比例条下方的 `0 / 25 / 50 / 75 / 100` 刻度行。
///
/// 100% 时按 `spaceBetween` 铺满整行（视觉与原型 `.ticks` 一致）。字号放大后
/// 五个刻度的自然宽度一旦超过可用宽度，就**整行统一等比缩小**到刚好装下：
/// 不换行（刻度掉到第二行会让刻度和 5px 比例条脱节）、不截断（`100` 变成
/// `1…` 就不是刻度了）、也不给单个刻度各自缩放（那会让 0 和 100 大小不一）。
///
/// 自然宽度用 [TextPainter] 按当前 `MediaQuery.textScaler` 实测，而不是拿
/// 字号乘字数估：估算遇到等宽字体 fallback 与 `letterSpacing` 会偏，偏了
/// 就还会溢出。
///
/// 可用宽度作为参数传入（[availableWidth]），本组件**不自己用
/// `LayoutBuilder`**：外层 `IntrinsicHeight` 会向子树要最大固有高度，而
/// `LayoutBuilder` 不支持固有尺寸，放在这条链上会让整页布局断言失败。
class _TickRow extends StatelessWidget {
  const _TickRow({required this.availableWidth, required this.textStyle});

  /// 本行可用的逻辑宽度（`Infinity` 表示宽度无界，按自然宽度铺开）。
  final double availableWidth;

  /// 刻度文案（顺序即绘制顺序）。
  static const List<String> ticks = <String>['0', '25', '50', '75', '100'];

  /// 刻度字样式（字号、等宽族、字距与原型一致）。
  final TextStyle textStyle;

  /// 按当前缩放实测五个刻度的自然宽度之和。
  double _naturalWidth(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    var total = 0.0;
    for (final tick in ticks) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: tick, style: textStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      total += painter.width;
      painter.dispose();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final double natural = _naturalWidth(context);
    final List<Widget> labels = <Widget>[
      for (final tick in ticks) Text(tick, style: textStyle),
    ];

    // 放得下 ⇒ 原样 `spaceBetween` 铺满整行（100% 时不缩放，视觉不变）。
    if (!availableWidth.isFinite ||
        availableWidth <= 0 ||
        natural <= availableWidth) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels,
      );
    }

    // 放不下 ⇒ 整行等比缩小到刚好装下：外层 `SizedBox` 给紧约束，
    // `FittedBox` 才有确定的可用宽度；内层 `SizedBox` 用实测自然宽，
    // +1 吸收浮点舍入，避免「刚好装下」被判成溢出。
    return SizedBox(
      width: availableWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: natural + 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels,
          ),
        ),
      ),
    );
  }
}