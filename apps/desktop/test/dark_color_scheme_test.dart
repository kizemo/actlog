// apps/desktop/test/dark_color_scheme_test.dart
//
// Task 41 深色主题 · 设计文档 §3.3「47 个现役字段全钉」的逐字段硬等。
//
// 期望值一律 hex 字面量：不引 `ThemeTokens.dark.*`，否则实现改错一个字，
// 测试跟着一起错（同源自证）。左列 24 + 右列 23 = 46 色 + `brightness`。
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// —— 深色 token 字面量（设计文档 §4.1 表右列）——
const Color _paper = Color(0xFF1A1714);
const Color _card = Color(0xFF221E1A);
const Color _sunken = Color(0xFF141210);
const Color _inkWash = Color(0xFF2B2620);
const Color _accentWash = Color(0xFF33241A);
const Color _ink = Color(0xFFECE5DA);
const Color _ink2 = Color(0xFFDCD4C7);
const Color _meta = Color(0xFFBFB6A7);
const Color _hair = Color(0xFF3A342C);
const Color _hairStrong = Color(0xFF827869);
const Color _accentInk = Color(0xFFD6A366);
const Color _shadowTint = Color(0xFF0D0A07);

void main() {
  test('深色 ColorScheme：47 个现役字段逐条钉死', () {
    final ColorScheme c = AppTheme.dark(DensityProfile.comfortable).colorScheme;

    // 1 / 47：亮度
    expect(c.brightness, Brightness.dark, reason: 'brightness');

    // —— 左列 24 ——
    expect(c.primary, _ink, reason: 'primary');
    expect(c.onPrimary, _paper, reason: 'onPrimary');
    expect(c.primaryContainer, _inkWash, reason: 'primaryContainer');
    expect(c.onPrimaryContainer, _ink, reason: 'onPrimaryContainer');
    expect(c.primaryFixed, _ink2, reason: 'primaryFixed');
    expect(c.primaryFixedDim, _meta, reason: 'primaryFixedDim');
    expect(c.onPrimaryFixed, _paper, reason: 'onPrimaryFixed');
    expect(c.onPrimaryFixedVariant, _ink2, reason: 'onPrimaryFixedVariant');
    expect(c.secondary, _ink2, reason: 'secondary');
    expect(c.onSecondary, _paper, reason: 'onSecondary');
    expect(c.secondaryContainer, _inkWash, reason: 'secondaryContainer');
    expect(c.onSecondaryContainer, _ink, reason: 'onSecondaryContainer');
    expect(c.secondaryFixed, _ink2, reason: 'secondaryFixed');
    expect(c.secondaryFixedDim, _meta, reason: 'secondaryFixedDim');
    expect(c.onSecondaryFixed, _paper, reason: 'onSecondaryFixed');
    expect(c.onSecondaryFixedVariant, _ink2, reason: 'onSecondaryFixedVariant');
    expect(c.tertiary, _ink2, reason: 'tertiary');
    expect(c.onTertiary, _paper, reason: 'onTertiary');
    expect(c.tertiaryContainer, _inkWash, reason: 'tertiaryContainer');
    expect(c.onTertiaryContainer, _ink, reason: 'onTertiaryContainer');
    expect(c.tertiaryFixed, _ink2, reason: 'tertiaryFixed');
    expect(c.tertiaryFixedDim, _meta, reason: 'tertiaryFixedDim');
    expect(c.onTertiaryFixed, _paper, reason: 'onTertiaryFixed');
    expect(c.onTertiaryFixedVariant, _ink2, reason: 'onTertiaryFixedVariant');

    // —— 右列 23（error 4 + surface 家族 10 + outline 2 + shadow 2 + inverse 4 + surfaceTint 1）——
    expect(c.error, _accentInk, reason: 'error');
    expect(c.onError, _paper, reason: 'onError');
    expect(c.errorContainer, _accentWash, reason: 'errorContainer');
    expect(c.onErrorContainer, _accentInk, reason: 'onErrorContainer');
    expect(c.surface, _paper, reason: 'surface');
    expect(c.onSurface, _ink, reason: 'onSurface');
    expect(c.onSurfaceVariant, _meta, reason: 'onSurfaceVariant');
    expect(c.surfaceDim, _sunken, reason: 'surfaceDim');
    expect(c.surfaceBright, _card, reason: 'surfaceBright');
    expect(c.surfaceContainerLowest, _sunken, reason: 'surfaceContainerLowest');
    expect(c.surfaceContainerLow, _card, reason: 'surfaceContainerLow');
    expect(c.surfaceContainer, _card, reason: 'surfaceContainer');
    expect(c.surfaceContainerHigh, _card, reason: 'surfaceContainerHigh');
    expect(
      c.surfaceContainerHighest,
      _card,
      reason: 'surfaceContainerHighest',
    );
    expect(c.outline, _hairStrong, reason: 'outline');
    expect(c.outlineVariant, _hair, reason: 'outlineVariant');
    expect(c.shadow, _shadowTint, reason: 'shadow');
    expect(c.scrim, _shadowTint, reason: 'scrim');
    expect(c.inverseSurface, _ink, reason: 'inverseSurface');
    expect(c.onInverseSurface, _paper, reason: 'onInverseSurface');
    expect(c.inversePrimary, _paper, reason: 'inversePrimary');
    expect(c.surfaceTint, _ink, reason: 'surfaceTint');
  });

  test('深色 ColorScheme：可交互边界是 hairStrong，装饰线才是 hair（>=3:1）', () {
    final ColorScheme c = AppTheme.dark(DensityProfile.comfortable).colorScheme;
    expect(c.outline, isNot(c.outlineVariant));
    // 深色 hairStrong 对 paper 的实测比值见 reports/task41-dark-palette.txt（判据 3）。
    expect(c.outline, _hairStrong);
    expect(c.outlineVariant, _hair);
  });

  test('深色 ColorScheme：error 走赭石三件套，不引入新色相', () {
    final ColorScheme c = AppTheme.dark(DensityProfile.comfortable).colorScheme;
    expect(c.error, _accentInk);
    expect(c.errorContainer, _accentWash);
    expect(c.onErrorContainer, _accentInk);
    expect(c.error, isNot(c.primary));
  });
}