// apps/desktop/lib/src/widgets/loop_progress_ring.dart
import 'package:flutter/material.dart';

import 'package:core_data/core_data.dart';

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

/// 顶部闭环脊线。
///
/// 原型对应 `.ridge` / `.seg` / `.bar` / `.ticks`：贯穿全宽的一条，
/// 四段各自「状态标记 + 标签 + 数值 + 5px 比例条 + 0/25/50/75/100 刻度」。
///
/// 数字全部来自 [DayStats]（唯一口径），本 widget **不自己算**。
class LoopProgressRing extends StatelessWidget {
  /// 创建闭环脊线。
  const LoopProgressRing({super.key, required this.stats, this.onJump});

  /// 当日统计。
  final DayStats stats;

  /// 点击某段时的回调（跳到对应段）。
  final void Function(DayStatsSegment segment)? onJump;

  /// 原型 `p(a,b)`：分母为 0 时算 0，不算 100%。
  static double _ratio(int done, int total) {
    if (total <= 0) {
      return 0;
    }
    return (done / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelSize = theme.textTheme.labelLarge?.fontSize ?? 11.5;
    final rate = stats.backfillRate;

    final entries = <_Entry>[
      _Entry(
        segment: DayStatsSegment.plan,
        label: '计划',
        mark: stats.planPending > 0 ? '○' : '✓',
        value: '${stats.planDone}/${stats.planTotal}',
        ratio: _ratio(stats.planDone, stats.planTotal),
        gap: stats.planPending > 0,
      ),
      _Entry(
        segment: DayStatsSegment.backfill,
        label: '回填',
        mark: stats.planDone > stats.backfilled ? '▸' : '●',
        value: rate == null ? '—' : '${stats.backfilled}/${stats.planDone}',
        ratio: _ratio(stats.backfilled, stats.planDone),
        gap: stats.planDone > stats.backfilled,
      ),
      _Entry(
        segment: DayStatsSegment.review,
        label: '复盘',
        mark: stats.reviewDone ? '✓' : '▸',
        value: stats.reviewDone ? '✓' : '▸',
        ratio: stats.reviewDone ? 1 : 0,
        gap: !stats.reviewDone,
      ),
      _Entry(
        segment: DayStatsSegment.mood,
        label: '心态',
        mark: stats.moodDone ? '✓' : '▸',
        value: stats.moodDone ? '✓' : '▸',
        ratio: stats.moodDone ? 1 : 0,
        gap: !stats.moodDone,
      ),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      decoration: const BoxDecoration(
        color: AppTokens.paper,
        border: Border(bottom: BorderSide(color: AppTokens.hair)),
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
                '闭环环 · 四段比例条',
                style: TextStyle(
                  fontSize: labelSize,
                  color: AppTokens.faint,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '刻度 0—100',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: labelSize,
                  color: AppTokens.meta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: AppTokens.hair),
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
                  rows.add(Container(height: 1, color: AppTokens.hair));
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
                            Container(width: 1, color: AppTokens.hair),
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

/// 单段：状态标记 + 标签 + 数值 + 5px 比例条 + 刻度。
class _Segment extends StatefulWidget {
  const _Segment({
    required this.entry,
    required this.labelSize,
    required this.leftPadding,
    required this.tickRowWidth,
    required this.onTap,
  });

  final _Entry entry;
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
    final entry = widget.entry;
    final accentColor = entry.gap ? AppTokens.accentInk : AppTokens.ink;
    final headColor = entry.gap ? AppTokens.accentInk : AppTokens.meta;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? AppTokens.sunken : Colors.transparent,
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
                    Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: widget.labelSize,
                        color: headColor,
                        letterSpacing: 0.6,
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
                    color: AppTokens.hairSoft,
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
                              color: entry.gap
                                  ? AppTokens.accent
                                  : AppTokens.ink2,
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
                    color: AppTokens.faint,
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

class _Entry {
  const _Entry({
    required this.segment,
    required this.label,
    required this.mark,
    required this.value,
    required this.ratio,
    required this.gap,
  });

  final DayStatsSegment segment;
  final String label;
  final String mark;
  final String value;
  final double ratio;
  final bool gap;
}