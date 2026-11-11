import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 相对亮度（WCAG 2.1）。
///
/// 公式 `L = 0.2126R + 0.7152G + 0.0722B`，分量先做 sRGB → 线性化。
double relativeLuminance(Color color) {
  double linear(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}

/// 对比度（WCAG 2.1），返回 ≥1 的比值。
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
