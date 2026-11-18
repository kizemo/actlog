import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/contrast.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/section_card.dart';

void main() {
  test('primary 是 ink、surface 是 paper，accent 不得当 primary', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.primary, ThemeTokens.light.ink);
    expect(theme.colorScheme.onPrimary, ThemeTokens.light.paper);
    expect(theme.colorScheme.surface, ThemeTokens.light.paper);
    expect(theme.colorScheme.primary, isNot(ThemeTokens.light.accent));
    expect(theme.colorScheme.error, ThemeTokens.light.accentInk);
  });

  test('可交互边界用 hairStrong（>=3:1），装饰线才用 hair', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.outline, ThemeTokens.light.hairStrong);
    expect(theme.colorScheme.outlineVariant, ThemeTokens.light.hair);
    expect(
      contrastRatio(theme.colorScheme.outline, ThemeTokens.light.paper),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('字号来自密度档，且正文 >= 14', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.textTheme.bodyMedium?.fontSize, 15);
    expect(theme.textTheme.labelLarge?.fontSize, 12.5);
    expect(theme.textTheme.titleLarge?.fontSize, 19);
    final compact = AppTheme.light(DensityProfile.compact);
    expect(compact.textTheme.bodyMedium?.fontSize, 14);
  });

  test('bodySmall 也随密度档，且三档都 >= 14', () {
    for (final d in DensityProfile.values) {
      final t = AppTheme.light(d);
      expect(t.textTheme.bodySmall?.fontSize, d.bodySize);
      expect(t.textTheme.bodySmall?.fontSize, greaterThanOrEqualTo(14.0));
    }
  });

  test('段标题走 titleLarge（display 族 + h2 号），titleSmall 落 label 号', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.textTheme.titleLarge?.fontSize, 19);
    expect(theme.textTheme.titleLarge?.fontFamily, AppFonts.display);
    expect(theme.textTheme.titleLarge?.fontFamilyFallback, AppFonts.displayFallback);
    expect(theme.textTheme.titleSmall?.fontSize, 12.5);
    expect(theme.textTheme.titleSmall?.fontFamily, AppFonts.body);
  });

  test('弹层与徽标底色在 token 口径内，不走 seed 派生', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.surfaceContainerHigh, ThemeTokens.light.card);
    expect(theme.colorScheme.surfaceContainerHighest, ThemeTokens.light.sunken);
    expect(theme.colorScheme.surfaceDim, ThemeTokens.light.sunken);
    expect(theme.colorScheme.tertiary, ThemeTokens.light.ink2);
    expect(theme.colorScheme.secondaryContainer, ThemeTokens.light.inkWash);
    expect(theme.colorScheme.errorContainer, ThemeTokens.light.accentWash);
  });

  testWidgets('SectionCard 标题真的吃到 titleLarge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: const Scaffold(
          body: SectionCard(
            icon: Icons.circle,
            title: '段标题',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('段标题'));
    expect(text.style?.fontSize, 19);
    expect(text.style?.fontFamily, AppFonts.display);
  });

  test('labelMedium 也被接管（白名单 8 个 role），三档都 >= 12', () {
    for (final d in DensityProfile.values) {
      final t = AppTheme.light(d);
      expect(t.textTheme.labelMedium?.fontSize, d.labelSize);
      expect(t.textTheme.labelMedium?.fontSize, greaterThanOrEqualTo(12.0));
      expect(t.textTheme.labelMedium?.fontFamily, AppFonts.body);
      expect(t.textTheme.labelMedium?.fontFamilyFallback, AppFonts.bodyFallback);
    }
  });

  // —— Task 41 深色断言组（上面 8 例只测浅色，逐字不动）——

  test('深色档：brightness = dark、surface = paper、extensions 带深色包', () {
    final theme = AppTheme.dark(DensityProfile.comfortable);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, ThemeTokens.dark.paper);
    expect(theme.colorScheme.primary, ThemeTokens.dark.ink);
    expect(
      theme.extensions.values.whereType<ThemeTokens>().single,
      ThemeTokens.dark,
    );
    expect(theme.colorScheme.surface, isNot(ThemeTokens.light.paper));
  });

  test('深色档：白名单角色与 dividerColor 全取深色 token（9 项）', () {
    final theme = AppTheme.dark(DensityProfile.comfortable);
    final t = theme.textTheme;
    expect(t.bodyLarge?.color, ThemeTokens.dark.ink);
    expect(t.bodyMedium?.color, ThemeTokens.dark.ink);
    expect(t.bodySmall?.color, ThemeTokens.dark.ink);
    expect(t.titleLarge?.color, ThemeTokens.dark.ink);
    expect(t.titleSmall?.color, ThemeTokens.dark.ink);
    expect(t.labelLarge?.color, ThemeTokens.dark.meta);
    expect(t.labelMedium?.color, ThemeTokens.dark.meta);
    expect(t.labelSmall?.color, ThemeTokens.dark.faint);
    expect(theme.dividerColor, ThemeTokens.dark.hair);
  });

  test('深色档：底色 / 线 / 状态层全部落在墨色阶，无残留浅色', () {
    final theme = AppTheme.dark(DensityProfile.comfortable);
    expect(theme.scaffoldBackgroundColor, ThemeTokens.dark.paper);
    expect(theme.canvasColor, ThemeTokens.dark.paper);
    expect(theme.cardColor, ThemeTokens.dark.card);
    expect(theme.secondaryHeaderColor, ThemeTokens.dark.card);
    expect(theme.primaryColor, ThemeTokens.dark.ink);
    expect(theme.primaryColorDark, ThemeTokens.dark.ink2);
    expect(theme.primaryColorLight, ThemeTokens.dark.ink);
    expect(theme.focusColor, ThemeTokens.dark.ink.withValues(alpha: 0.12));
    expect(theme.hoverColor, ThemeTokens.dark.ink.withValues(alpha: 0.08));
    expect(theme.disabledColor, ThemeTokens.dark.faint);
    expect(theme.hintColor, ThemeTokens.dark.faint);
    expect(theme.unselectedWidgetColor, ThemeTokens.dark.meta);
    expect(theme.shadowColor, ThemeTokens.dark.shadowTint);
    expect(theme.applyElevationOverlayColor, isTrue);
  });

  testWidgets('暗色 MaterialApp 下 extension<ThemeTokens>() 非空且是深色包', (
    tester,
  ) async {
    ThemeTokens? seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(DensityProfile.comfortable),
        home: Builder(
          builder: (BuildContext context) {
            seen = Theme.of(context).extension<ThemeTokens>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen, isNotNull);
    expect(seen, ThemeTokens.dark);
  });
}
