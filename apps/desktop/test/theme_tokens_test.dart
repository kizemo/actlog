import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/contrast.dart';

void main() {
  test('--hair-strong 落地值对 7 个浅底全部 >= 3:1', () {
    const backgrounds = <Color>[
      AppTokens.paper,
      AppTokens.card,
      AppTokens.sunken,
      AppTokens.dock,
      AppTokens.keybg,
      AppTokens.inkWash,
      AppTokens.accentWash,
    ];
    for (final bg in backgrounds) {
      expect(
        contrastRatio(AppTokens.hairStrong, bg),
        greaterThanOrEqualTo(3.0),
        reason: 'hairStrong 对 $bg 不达标',
      );
    }
  });

  test('文字色对 paper / card 全部 >= 4.5:1', () {
    const texts = <Color>[
      AppTokens.ink,
      AppTokens.ink2,
      AppTokens.meta,
      AppTokens.faint,
    ];
    for (final fg in texts) {
      for (final bg in const <Color>[AppTokens.paper, AppTokens.card]) {
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$fg 对 $bg 不达标',
        );
      }
    }
  });

  test('accent 与 ink 必须是两个不同的色（不得混用）', () {
    expect(AppTokens.accent, isNot(AppTokens.ink));
    expect(AppTokens.accentInk, isNot(AppTokens.ink));
    expect(AppTokens.hairStrong, isNot(AppTokens.hair));
  });
}
