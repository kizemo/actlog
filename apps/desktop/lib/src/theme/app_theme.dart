import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_tokens.dart';
import 'density_profile.dart';

/// B 版主题构建（浅色 / 深色两档）。
///
/// 刻意**不**设置 `cardTheme` / `dialogTheme` / `chipTheme`：
/// 这几个类的类型在 Flutter 3.47 的小版本间摇摆（`CardTheme` / `CardThemeData`），
/// 一旦写死会在升级时炸编译。卡片 / 芯片 / 弹层的外观一律在各自 widget
/// 里显式引用 [ThemeTokens]（`context.tokens.<字段>`）—— 这样 token 口径只有一处。
///
/// 两档的装配策略（Task 41）：
/// - **浅色**：`ColorScheme.fromSeed` 后只覆盖既有 24 个 slot，其余走 seed 派生
///   ⇒ 渲染逐字节等于改造前；
/// - **深色**：47 个 `ColorScheme` 现役字段**全部钉死**（设计文档 §3.3），
///   再显式给定 `ThemeData` 的亮度敏感字段（§3.4）⇒ 不留任何 seed 派生的
///   「半深半浅」缺口。3 个已废弃的 `ColorScheme` 字段
///   （`background` / `onBackground` / `surfaceVariant`）**不设值**，
///   它们由已钉死的 `surface` / `onSurface` / `surfaceContainerHighest` 派生。
class AppTheme {
  const AppTheme._();

  /// 浅色档主题。
  static ThemeData light(DensityProfile density) => _buildLight(density);

  /// 深色档主题（暖墨深褐，设计文档 §4 全表）。
  static ThemeData dark(DensityProfile density) => _buildDark(density);

  static ThemeData _buildLight(DensityProfile density) {
    final ThemeTokens tokens = ThemeTokens.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.ink,
      brightness: Brightness.light,
    ).copyWith(
      primary: tokens.ink,
      onPrimary: tokens.paper,
      secondary: tokens.ink2,
      onSecondary: tokens.paper,
      secondaryContainer: tokens.inkWash,
      onSecondaryContainer: tokens.ink,
      tertiary: tokens.ink2,
      onTertiary: tokens.paper,
      error: tokens.accentInk,
      onError: tokens.paper,
      errorContainer: tokens.accentWash,
      onErrorContainer: tokens.accentInk,
      surface: tokens.paper,
      onSurface: tokens.ink,
      onSurfaceVariant: tokens.meta,
      surfaceBright: tokens.paper,
      surfaceDim: tokens.sunken,
      surfaceContainerLowest: tokens.paper,
      surfaceContainerLow: tokens.card,
      surfaceContainer: tokens.card,
      surfaceContainerHigh: tokens.card,
      surfaceContainerHighest: tokens.sunken,
      outline: tokens.hairStrong,
      outlineVariant: tokens.hair,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, density, tokens),
      dividerColor: tokens.hair,
      scaffoldBackgroundColor: tokens.paper,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  static ThemeData _buildDark(DensityProfile density) {
    final ThemeTokens tokens = ThemeTokens.dark;

    // 47 个现役字段逐条落地（设计文档 §3.3 左 24 + 右 23 = 47）。
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.ink,
      brightness: Brightness.dark,
    ).copyWith(
      brightness: Brightness.dark,
      primary: tokens.ink,
      onPrimary: tokens.paper,
      primaryContainer: tokens.inkWash,
      onPrimaryContainer: tokens.ink,
      primaryFixed: tokens.ink2,
      primaryFixedDim: tokens.meta,
      onPrimaryFixed: tokens.paper,
      onPrimaryFixedVariant: tokens.ink2,
      secondary: tokens.ink2,
      onSecondary: tokens.paper,
      secondaryContainer: tokens.inkWash,
      onSecondaryContainer: tokens.ink,
      secondaryFixed: tokens.ink2,
      secondaryFixedDim: tokens.meta,
      onSecondaryFixed: tokens.paper,
      onSecondaryFixedVariant: tokens.ink2,
      tertiary: tokens.ink2,
      onTertiary: tokens.paper,
      tertiaryContainer: tokens.inkWash,
      onTertiaryContainer: tokens.ink,
      tertiaryFixed: tokens.ink2,
      tertiaryFixedDim: tokens.meta,
      onTertiaryFixed: tokens.paper,
      onTertiaryFixedVariant: tokens.ink2,
      error: tokens.accentInk,
      onError: tokens.paper,
      errorContainer: tokens.accentWash,
      onErrorContainer: tokens.accentInk,
      surface: tokens.paper,
      onSurface: tokens.ink,
      onSurfaceVariant: tokens.meta,
      surfaceDim: tokens.sunken,
      surfaceBright: tokens.card,
      surfaceContainerLowest: tokens.sunken,
      surfaceContainerLow: tokens.card,
      surfaceContainer: tokens.card,
      surfaceContainerHigh: tokens.card,
      surfaceContainerHighest: tokens.card,
      outline: tokens.hairStrong,
      outlineVariant: tokens.hair,
      shadow: tokens.shadowTint,
      scrim: tokens.shadowTint,
      inverseSurface: tokens.ink,
      onInverseSurface: tokens.paper,
      inversePrimary: tokens.paper,
      surfaceTint: tokens.ink,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, density, tokens),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: tokens.ink,
        displayColor: tokens.ink,
      ),
      iconTheme: base.iconTheme.copyWith(color: tokens.meta),
      primaryIconTheme: IconThemeData(color: tokens.ink),
      applyElevationOverlayColor: true,
      // --- 底色 ---
      canvasColor: tokens.paper,
      cardColor: tokens.card,
      scaffoldBackgroundColor: tokens.paper,
      secondaryHeaderColor: tokens.card,
      // --- 线 ---
      dividerColor: tokens.hair,
      // NOTE(Task41-W0): 派工书 §5.3 / 设计文档 §3.4 要求显式钉 `dialogBackgroundColor`
      // 与 `indicatorColor`，但本机 SDK（3.47.9）对这两个 **`copyWith` 参数**标了
      // `@Deprecated`（`theme_data.dart:1592` v3.27 / `:1597` v3.28），设值即触发
      // `deprecated_member_use`（info 级）⇒ 破「逐字 `No issues found!`」硬门禁（已实测：
      // 2 issues found）。二者语义均已由**已钉死**字段派生，不会半深半浅：
      // · 弹层底 = `colorScheme.surfaceContainerHigh` = `card`（已钉）；
      // · Tab 指示器 = `colorScheme.primary` = `ink`（已钉）。
      // 替代方案（`DialogThemeData` / `TabBarThemeData`）又撞 §5.4「不设 dialogTheme」禁令，
      // 故不设值 —— 此为与派工书的有据偏离。
      // --- 主色三阶（M2 遗留字段：一律落在墨色阶上，不引入新色相）---
      primaryColor: tokens.ink,
      primaryColorDark: tokens.ink2,
      primaryColorLight: tokens.ink,
      // --- 状态层：M3 语义 = `onSurface` @ 低 alpha，故用 `ink` 派生 ---
      focusColor: tokens.ink.withValues(alpha: 0.12),
      hoverColor: tokens.ink.withValues(alpha: 0.08),
      highlightColor: tokens.ink.withValues(alpha: 0.10),
      splashColor: tokens.ink.withValues(alpha: 0.12),
      // --- 前景 / 边界 ---
      disabledColor: tokens.faint,
      hintColor: tokens.faint,
      unselectedWidgetColor: tokens.meta,
      shadowColor: tokens.shadowTint,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  /// 9 个 TextTheme 角色（白名单，两档共用同一装配逻辑）。
  static TextTheme _textTheme(
    TextTheme base,
    DensityProfile density,
    ThemeTokens tokens,
  ) {
    return base.copyWith(
      bodyLarge: TextStyle(
        fontSize: density.bodySize,
        height: density.lineHeight,
        color: tokens.ink,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
      bodyMedium: TextStyle(
        fontSize: density.bodySize,
        height: density.lineHeight,
        color: tokens.ink,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
      bodySmall: TextStyle(
        fontSize: density.bodySize,
        height: density.lineHeight,
        color: tokens.ink,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
      labelLarge: TextStyle(
        fontSize: density.labelSize,
        height: 1.3,
        color: tokens.meta,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
      labelMedium: TextStyle(
        fontSize: density.labelSize,
        height: 1.3,
        color: tokens.meta,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
      labelSmall: TextStyle(
        fontSize: density.labelSize,
        height: 1.3,
        color: tokens.faint,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
      titleLarge: TextStyle(
        fontSize: density.h2Size,
        height: 1.3,
        color: tokens.ink,
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.displayFallback,
      ),
      titleSmall: TextStyle(
        fontSize: density.labelSize,
        height: 1.3,
        color: tokens.ink,
        fontFamily: AppFonts.body,
        fontFamilyFallback: AppFonts.bodyFallback,
      ),
    );
  }
}