import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_tokens.dart';
import 'density_profile.dart';

/// B 版主题构建。
///
/// 刻意**不**设置 `cardTheme` / `dialogTheme` / `chipTheme`：
/// 这几个类的类型在 Flutter 3.47 的小版本间摇摆（`CardTheme` / `CardThemeData`），
/// 一旦写死会在升级时炸编译。卡片 / 芯片 / 弹层的外观一律在各自 widget
/// 里显式引用 [AppTokens] —— 这样 token 口径只有一处。
class AppTheme {
  const AppTheme._();

  /// 浅色档主题。
  static ThemeData light(DensityProfile density) =>
      _build(density, Brightness.light);

  /// 深色档占位：本轮只保证不崩，深色配色待 B4 实测后补。
  static ThemeData dark(DensityProfile density) =>
      _build(density, Brightness.dark);

  static ThemeData _build(DensityProfile density, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.ink,
      brightness: brightness,
    ).copyWith(
      primary: AppTokens.ink,
      onPrimary: AppTokens.paper,
      secondary: AppTokens.ink2,
      onSecondary: AppTokens.paper,
      secondaryContainer: AppTokens.inkWash,
      onSecondaryContainer: AppTokens.ink,
      tertiary: AppTokens.ink2,
      onTertiary: AppTokens.paper,
      error: AppTokens.accentInk,
      onError: AppTokens.paper,
      errorContainer: AppTokens.accentWash,
      onErrorContainer: AppTokens.accentInk,
      surface: AppTokens.paper,
      onSurface: AppTokens.ink,
      onSurfaceVariant: AppTokens.meta,
      surfaceBright: AppTokens.paper,
      surfaceDim: AppTokens.sunken,
      surfaceContainerLowest: AppTokens.paper,
      surfaceContainerLow: AppTokens.card,
      surfaceContainer: AppTokens.card,
      surfaceContainerHigh: AppTokens.card,
      surfaceContainerHighest: AppTokens.sunken,
      outline: AppTokens.hairStrong,
      outlineVariant: AppTokens.hair,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        bodyMedium: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        bodySmall: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelLarge: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.meta,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelMedium: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.meta,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelSmall: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.faint,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        titleLarge: TextStyle(
          fontSize: density.h2Size,
          height: 1.3,
          color: AppTokens.ink,
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.displayFallback,
        ),
        titleSmall: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
      ),
      dividerColor: AppTokens.hair,
      scaffoldBackgroundColor: AppTokens.paper,
    );
  }
}
