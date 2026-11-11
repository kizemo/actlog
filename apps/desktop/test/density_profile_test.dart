import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';

void main() {
  test('三档字号满足硬底线：正文 >= 14、标签 >= 12', () {
    for (final d in DensityProfile.values) {
      expect(d.bodySize, greaterThanOrEqualTo(14), reason: '$d 正文过小');
      expect(d.labelSize, greaterThanOrEqualTo(12), reason: '$d 标签过小');
    }
  });

  test('三档数值抄自 TOKENS.md §2.1', () {
    expect(DensityProfile.compact.bodySize, 14);
    expect(DensityProfile.compact.lineHeight, 1.5);
    expect(DensityProfile.compact.labelSize, 12);
    expect(DensityProfile.compact.h2Size, 17);
    expect(DensityProfile.compact.padH, 11);
    expect(DensityProfile.compact.padV, 9);
    expect(DensityProfile.compact.gapSec, 16);
    expect(DensityProfile.comfortable.bodySize, 15);
    expect(DensityProfile.comfortable.lineHeight, 1.66);
    expect(DensityProfile.comfortable.labelSize, 12.5);
    expect(DensityProfile.comfortable.h2Size, 19);
    expect(DensityProfile.comfortable.padH, 14);
    expect(DensityProfile.comfortable.padV, 12);
    expect(DensityProfile.comfortable.gapSec, 22);
    expect(DensityProfile.roomy.bodySize, 16.5);
    expect(DensityProfile.roomy.lineHeight, 1.84);
    expect(DensityProfile.roomy.labelSize, 13.5);
    expect(DensityProfile.roomy.h2Size, 21);
    expect(DensityProfile.roomy.padH, 18);
    expect(DensityProfile.roomy.padV, 16);
    expect(DensityProfile.roomy.gapSec, 28);
  });

  test('comfortable 档段间距与 AppTokens.gapSec 同源', () {
    expect(DensityProfile.comfortable.gapSec, AppTokens.gapSec);
  });

  test('字体族首选 + 兜底顺序抄自 TOKENS.md §2', () {
    expect(AppFonts.display, 'Fraunces');
    expect(
      AppFonts.displayFallback,
      <String>['Noto Serif SC', 'Songti SC', 'Georgia', 'SimSun', 'serif'],
    );
    expect(AppFonts.body, 'Inter');
    expect(
      AppFonts.bodyFallback,
      <String>[
        'Noto Sans SC',
        'PingFang SC',
        'Microsoft YaHei',
        'Segoe UI',
        'system-ui',
        'sans-serif',
      ],
    );
    expect(AppFonts.mono, 'JetBrains Mono');
    expect(
      AppFonts.monoFallback,
      <String>[
        'SFMono-Regular',
        'Cascadia Mono',
        'Consolas',
        'Courier New',
        'monospace',
      ],
    );
  });

  test('兜底列表不得包含首选族本身', () {
    expect(AppFonts.displayFallback, isNot(contains(AppFonts.display)));
    expect(AppFonts.bodyFallback, isNot(contains(AppFonts.body)));
    expect(AppFonts.monoFallback, isNot(contains(AppFonts.mono)));
  });
}
