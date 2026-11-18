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

  // `TOKENS.md` §8.4（Task 40 · A2）：用户反馈「淡蓝背景 + 深蓝文字」与米纸
  // 基调冲突。这五个 token 已整体换到暖色相，改成红通道 < 蓝通道即视为蓝色相
  // 回退（旧值 `#2E4057` / `#3D5170` / `#E7EAEF` / `#E8ECF1` / `#DCE4EC` 全部
  // 是蓝通道更高，本用例对它们必红）。
  test('墨色系与格底色相的蓝通道不得高于红通道（去蓝回归闸门）', () {
    const warmed = <String, Color>{
      '--ink': AppTokens.ink,
      '--ink-2': AppTokens.ink2,
      '--ink-wash': AppTokens.inkWash,
      '--slot-plan': AppTokens.slotPlan,
      '--slot-habit': AppTokens.slotHabit,
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