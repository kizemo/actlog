import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/contrast.dart';

void main() {
  test('--hair-strong 落地值对 7 个浅底全部 >= 3:1', () {
    final backgrounds = <Color>[
      ThemeTokens.light.paper,
      ThemeTokens.light.card,
      ThemeTokens.light.sunken,
      ThemeTokens.light.dock,
      ThemeTokens.light.keybg,
      ThemeTokens.light.inkWash,
      ThemeTokens.light.accentWash,
    ];
    for (final bg in backgrounds) {
      expect(
        contrastRatio(ThemeTokens.light.hairStrong, bg),
        greaterThanOrEqualTo(3.0),
        reason: 'hairStrong 对 $bg 不达标',
      );
    }
  });

  test('文字色对 paper / card 全部 >= 4.5:1', () {
    final texts = <Color>[
      ThemeTokens.light.ink,
      ThemeTokens.light.ink2,
      ThemeTokens.light.meta,
      ThemeTokens.light.faint,
    ];
    for (final fg in texts) {
      for (final bg in <Color>[ThemeTokens.light.paper, ThemeTokens.light.card]) {
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$fg 对 $bg 不达标',
        );
      }
    }
  });

  test('accent 与 ink 必须是两个不同的色（不得混用）', () {
    expect(ThemeTokens.light.accent, isNot(ThemeTokens.light.ink));
    expect(ThemeTokens.light.accentInk, isNot(ThemeTokens.light.ink));
    expect(ThemeTokens.light.hairStrong, isNot(ThemeTokens.light.hair));
  });

  // `TOKENS.md` §8.4（Task 40 · A2）：用户反馈「淡蓝背景 + 深蓝文字」与米纸
  // 基调冲突。这五个 token 已整体换到暖色相，改成红通道 < 蓝通道即视为蓝色相
  // 回退（旧值 `#2E4057` / `#3D5170` / `#E7EAEF` / `#E8ECF1` / `#DCE4EC` 全部
  // 是蓝通道更高，本用例对它们必红）。
  test('墨色系与格底色相的蓝通道不得高于红通道（去蓝回归闸门）', () {
    final warmed = <String, Color>{
      '--ink': ThemeTokens.light.ink,
      '--ink-2': ThemeTokens.light.ink2,
      '--ink-wash': ThemeTokens.light.inkWash,
      '--slot-plan': ThemeTokens.light.slotPlan,
      '--slot-habit': ThemeTokens.light.slotHabit,
    };
    warmed.forEach((name, color) {
      final int red = (color.r * 255).round();
      final int blue = (color.b * 255).round();
      expect(
        red,
        greaterThanOrEqualTo(blue),
        reason: '$name 的蓝通道 $blue 高于红通道 $red，蓝色相回退了（TOKENS.md §8.4）',
      );
    });
  });
}