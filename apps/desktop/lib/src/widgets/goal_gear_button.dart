import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 「设置」齿轮按钮（Task 64）。
///
/// 左导航的第 6 项换成了「目标」，「设置」不再占一行文字，而是**沉底**成一枚
/// 自绘齿轮（竖排在底注之上、横排在行末）。点击行为与原来一致：回调
/// `onSelected('settings')` ⇒ 壳层切到 `/settings`。
///
/// 为什么自绘而不是 `Icons.settings`：
/// * 本仓**外壳层零 Material 图标**（`widgets\shell\` 实测 0 命中）；页面/组件层
///   另有 30 处 Material 图标用法（12 个文件），不属本模块约束范围；
/// * 画法照 `widgets\shell\app_top_bar.dart` 的 `_GlyphPainter`：16px 画布、
///   笔画 1.2、`StrokeCap.butt`、`StrokeJoin.miter`，颜色从 `context.tokens` 取，
///   **不新增任何色值**。
///
/// 无障碍：命中区 ≥ 24×24（图标本身 16px，外面套 28×28 的命中盒），
/// tooltip 用当前语言的「设置 / Settings」。
class GoalGearButton extends StatelessWidget {
  /// 创建齿轮按钮。
  const GoalGearButton({
    required this.tooltip,
    this.onPressed,
    super.key,
  });

  /// 无障碍提示 / tooltip 文案（走 l10n：中文「设置」、英文「Settings」）。
  final String tooltip;

  /// 点击回调；`null` ⇒ 渲染成禁用态（不响应点击）。
  final VoidCallback? onPressed;

  /// 图标画布边长（与顶栏三钮图标同规格）。
  static const double glyphSize = 16;

  /// 命中盒边长（≥ 24，满足最小可点区域）。
  static const double hitSize = 28;

  /// 齿轮中心圆半径（规划 §7.2：r ≈ 3.2）。
  static const double hubRadius = 3.2;

  /// 齿谷半径。
  static const double rootRadius = 4.8;

  /// 齿顶半径。
  static const double tipRadius = 7.2;

  /// 齿数。
  static const int teeth = 6;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final bool enabled = onPressed != null;
    final Color color = enabled ? tokens.meta : tokens.faint;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: InkWell(
                onTap: onPressed,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radius),
                child: SizedBox(
                  width: glyphSize,
                  height: glyphSize,
                  child: CustomPaint(
                    painter: _GearPainter(color: color),
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

/// 齿轮的绘制器：外圈 6 齿 + 中心圆，单色描边。
///
/// 齿形用「谷 → 齿顶 → 齿顶 → 谷」四个顶点拼成折线，`StrokeJoin.miter`
/// 让齿尖保持尖角（`butt` 端点 + `miter` 拐角，与顶栏三钮同一套描边参数）。
class _GearPainter extends CustomPainter {
  const _GearPainter({required this.color});

  /// 描边颜色（由调用方从 `context.tokens` 取）。
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final Offset center = Offset(cx, cy);

    // 齿圈：每颗齿 4 个顶点（谷 / 齿顶 / 齿顶 / 谷）。
    final Path outline = Path();
    final double step = 2 * math.pi / GoalGearButton.teeth;
    for (int i = 0; i < GoalGearButton.teeth; i++) {
      final double base = step * i;
      final List<double> angles = <double>[
        base,
        base + step * 0.16,
        base + step * 0.34,
        base + step * 0.50,
      ];
      final List<double> radii = <double>[
        GoalGearButton.rootRadius,
        GoalGearButton.tipRadius,
        GoalGearButton.tipRadius,
        GoalGearButton.rootRadius,
      ];
      for (int k = 0; k < angles.length; k++) {
        final Offset point = center +
            Offset(
              math.cos(angles[k]) * radii[k],
              math.sin(angles[k]) * radii[k],
            );
        if (i == 0 && k == 0) {
          outline.moveTo(point.dx, point.dy);
        } else {
          outline.lineTo(point.dx, point.dy);
        }
      }
    }
    outline.close();
    canvas.drawPath(outline, stroke);

    // 中心圆（轮毂）。
    canvas.drawCircle(center, GoalGearButton.hubRadius, stroke);
  }

  @override
  bool shouldRepaint(_GearPainter oldDelegate) =>
      oldDelegate.color != color;
}
