// =============================================================================
// 目标 · 蓝图页片头带 + 10 切面 rail（B11 方向 A「秒数轮盘」骨架）
// =============================================================================
// 设计稿真源：`design-demos/b11-blueprint-roulette.html`（用户已选定 A 版）。
// 本文件只搬**结构**，色值一律取 `theme_tokens.dart` 的 `ThemeTokens`：
//  * 片头带 = `tokens.ink` 墨底 + `tokens.paper` 反白字（浅色档是墨底浅字、
//    深色档自动反过来，因为 `ink`/`paper` 是一对互反色）；
//  * 波形 = 静态折线（CustomPainter，确定性伪随机，seed 固定）——
//    **不复活**设计稿原型的黑底 / 蓝紫渐变 / glow（反 slop 纪律）；
//  * rail 的「当前项」用 ink 反白（墨底 + paper 字），其余用 ink/meta；
//    赭石 `tokens.accent` **只表缺口**，这里一律不用。
//
// 文案来源：`t.shellNavBlueprint`（大标题，页面既有 key `blueprint-title`
// 由本组件的 h1 承载）+ 三条新增 getter（kicker / 副标 / 品牌行）。
// 10 个切面名**复用既有 `goalBrandFacet*` getter**，不新增 10 个 key。
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';

/// 蓝图页片头带。
///
/// 结构（与 A 稿 `header.band` 对齐）：左列 kicker → 巨标题 → 副标；
/// 右侧 mono 元信息（品牌行 + 日期）；底部一条静态折线波形。
class GoalBlueprintBand extends StatelessWidget {
  /// 创建片头带。
  const GoalBlueprintBand({required this.t, required this.today, super.key});

  /// 文案表。
  final AppLocalizations t;

  /// 今天（`yyyy-MM-dd`，来自 `todayProvider`，不与设备时钟二次耦合）。
  final String today;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    // 三段文字层次都从 paper→ink 插值出来，不引入新色值字面量。
    final Color midInk = Color.lerp(tokens.paper, tokens.ink, 0.24)!;
    final Color faintInk = Color.lerp(tokens.paper, tokens.ink, 0.46)!;

    return Container(
      key: const ValueKey<String>('goal-blueprint-band'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.ink,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        t.goalBlueprintBandKicker,
                        key: const ValueKey<String>('goal-blueprint-band-kicker'),
                        style: text.labelSmall?.copyWith(
                          color: faintInk,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 页面既有契约：`blueprint-title` 必须是 `shellNavBlueprint`。
                      Text(
                        t.shellNavBlueprint,
                        key: const ValueKey<String>('blueprint-title'),
                        style: text.headlineMedium?.copyWith(
                          color: tokens.paper,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 660),
                        child: Text(
                          t.goalBlueprintBandSubtitle,
                          key: const ValueKey<String>(
                            'goal-blueprint-band-subtitle',
                          ),
                          style: text.bodyMedium?.copyWith(
                            color: midInk,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      t.goalBlueprintBandBrand,
                      key: const ValueKey<String>('goal-blueprint-band-brand'),
                      style: text.labelSmall?.copyWith(
                        color: tokens.paper,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      today,
                      key: const ValueKey<String>('goal-blueprint-band-today'),
                      style: text.labelSmall?.copyWith(
                        color: faintInk,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 波形条：静态、无渐变、无 glow，只是纸面上的一条折线。
          SizedBox(
            height: 26,
            child: CustomPaint(
              key: const ValueKey<String>('goal-blueprint-band-wave'),
              painter: GoalBlueprintWavePainter(
                line: midInk,
                faint: Color.lerp(tokens.ink, tokens.paper, 0.22)!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 片头带底部的静态折线波形。
///
/// 用固定 seed 的线性同余发生器取点 ⇒ 每次重建波形**逐像素一致**
/// （不用 `Random()`，否则每帧抖动；也不引第三方噪声库）。
class GoalBlueprintWavePainter extends CustomPainter {
  /// 创建画笔。
  const GoalBlueprintWavePainter({
    required this.line,
    required this.faint,
    this.seed = 20261126,
  });

  /// 主折线颜色。
  final Color line;

  /// 刻度线与副折线颜色。
  final Color faint;

  /// 伪随机种子（固定 ⇒ 波形确定）。
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final Paint tick = Paint()
      ..color = faint
      ..strokeWidth = 1;
    // 每 5% 一根 5px 竖刻度（对应设计稿的 tickSvg）。
    for (int i = 0; i <= 20; i++) {
      final double x = size.width * i / 20;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - 5),
        tick,
      );
    }
    _polyline(canvas, size, seed: seed, color: faint, spread: 0.30);
    _polyline(canvas, size, seed: seed + 7, color: line, spread: 0.52);
  }

  /// 画一条折线（[spread] 越大摆幅越大）。
  void _polyline(
    Canvas canvas,
    Size size, {
    required int seed,
    required Color color,
    required double spread,
  }) {
    const int points = 48;
    int state = seed;
    // 局部函数：线性同余，取高 16 位换到 0..1。
    double next() {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      return (state >> 8) / 0x7FFFFF;
    }

    final Path path = Path();
    double level = 0.5;
    for (int i = 0; i <= points; i++) {
      level = (level + (next() - 0.5) * 0.18).clamp(0.08, 0.92).toDouble();
      final double dx = size.width * i / points;
      final double dy = size.height * (0.5 + (level - 0.5) * spread * 2);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(GoalBlueprintWavePainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.faint != faint ||
      oldDelegate.seed != seed;
}

/// 蓝图页左侧「10 切面」rail。
///
/// 10 项名称复用既有的 `goalBrandFacet*` getter（定位语句 … 身份声明）。
/// 其中 04 / 06 / 08 / 10 是个人定位四问对应的切面 ⇒ 加粗 + 4px 圆点；
/// [activeIndex] 那一项用 ink 反白（墨底 + paper 字）表示「当前」。
/// 本 rail 是**只读**导航示意，不承载点击（四问的编辑仍在右侧面板里）。
class GoalBlueprintFacetRail extends StatelessWidget {
  /// 创建 rail。
  const GoalBlueprintFacetRail({
    required this.t,
    this.activeIndex = 4,
    super.key,
  });

  /// 文案表。
  final AppLocalizations t;

  /// 当前项（1 基序号）。默认 4 = 「承诺结果」，即四问第一问对应的切面。
  final int activeIndex;

  /// 个人定位四问对应的切面序号（1 基）。
  static const List<int> questionFacets = <int>[4, 6, 8, 10];

  /// 10 个切面名（顺序与 `goal_brand_panel.dart` 的切面枚举一致）。
  List<String> _names() => <String>[
    t.goalBrandFacetStatement,
    t.goalBrandFacetWord,
    t.goalBrandFacetAudience,
    t.goalBrandFacetPromise,
    t.goalBrandFacetCost,
    t.goalBrandFacetEvidence,
    t.goalBrandFacetContrast,
    t.goalBrandFacetStrength,
    t.goalBrandFacetErrc,
    t.goalBrandFacetIdentity,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> names = _names();

    return Column(
      key: const ValueKey<String>('goal-blueprint-facet-rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.goalBrandFacetNavLabel,
          style: text.labelSmall?.copyWith(
            color: tokens.faint,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < names.length; i++)
          _facet(
            index: i + 1,
            name: names[i],
            tokens: tokens,
            text: text,
          ),
      ],
    );
  }

  /// 一项切面。
  Widget _facet({
    required int index,
    required String name,
    required ThemeTokens tokens,
    required TextTheme text,
  }) {
    final String serial = index.toString().padLeft(2, '0');
    final bool active = index == activeIndex;
    final bool question = questionFacets.contains(index);
    final TextStyle? nameStyle = text.bodySmall?.copyWith(
      color: active
          ? tokens.paper
          : (question ? tokens.ink : tokens.meta),
      fontWeight: question ? FontWeight.w600 : FontWeight.w400,
    );

    return Container(
      key: ValueKey<String>('goal-blueprint-facet-$serial'),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: active
          ? BoxDecoration(
              color: tokens.ink,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            serial,
            style: text.labelSmall?.copyWith(
              color: active ? tokens.paper : tokens.faint,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: nameStyle)),
          if (question)
            Container(
              key: ValueKey<String>('goal-blueprint-facet-question-$serial'),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: active ? tokens.paper : tokens.ink,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}