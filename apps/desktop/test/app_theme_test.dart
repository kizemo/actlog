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
    expect(theme.colorScheme.primary, AppTokens.ink);
    expect(theme.colorScheme.onPrimary, AppTokens.paper);
    expect(theme.colorScheme.surface, AppTokens.paper);
    expect(theme.colorScheme.primary, isNot(AppTokens.accent));
    expect(theme.colorScheme.error, AppTokens.accentInk);
  });

  test('可交互边界用 hairStrong（>=3:1），装饰线才用 hair', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.outline, AppTokens.hairStrong);
    expect(theme.colorScheme.outlineVariant, AppTokens.hair);
    expect(
      contrastRatio(theme.colorScheme.outline, AppTokens.paper),
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
    expect(theme.colorScheme.surfaceContainerHigh, AppTokens.card);
    expect(theme.colorScheme.surfaceContainerHighest, AppTokens.sunken);
    expect(theme.colorScheme.surfaceDim, AppTokens.sunken);
    expect(theme.colorScheme.tertiary, AppTokens.ink2);
    expect(theme.colorScheme.secondaryContainer, AppTokens.inkWash);
    expect(theme.colorScheme.errorContainer, AppTokens.accentWash);
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
}
