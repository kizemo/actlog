// apps/desktop/test/theme_tokens_dark_test.dart
//
// Task 41 深色主题 · 设计文档 §4.2 判据 1-13 的深色版。
//
// 刻意的「不做」：本文件**不引用** `ThemeTokens.dark.*`。28 色全部写 hex
// 字面量 —— 若照抄实现，「值本身」这类判据（9 / 11）会由实现给自己判卷、
// 永远绿。字面量在这里是**规格**，实现是被验对象。
//
// 对比度口径逐字取自 `lib/src/theme/contrast.dart`（WCAG 2.1 相对亮度）。
import 'package:actlog/src/theme/contrast.dart';
import 'package:actlog/src/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 设计文档 §4.1 表右列：深色 28 色。
abstract final class _D {
  static const Color paper = Color(0xFF1A1714);
  static const Color card = Color(0xFF221E1A);
  static const Color sunken = Color(0xFF141210);
  static const Color dock = Color(0xFF1F1B17);
  static const Color keybg = Color(0xFF1C1915);
  static const Color inkWash = Color(0xFF2B2620);
  static const Color accentWash = Color(0xFF33241A);
  static const Color ink = Color(0xFFECE5DA);
  static const Color ink2 = Color(0xFFDCD4C7);
  static const Color meta = Color(0xFFBFB6A7);
  static const Color faint = Color(0xFFA79E8F);
  static const Color hair = Color(0xFF3A342C);
  static const Color hairSoft = Color(0xFF2A251F);
  static const Color hairStrong = Color(0xFF827869);
  static const Color accent = Color(0xFFC08A4E);
  static const Color accentInk = Color(0xFFD6A366);
  static const Color slotPlan = Color(0xFF241F19);
  static const Color slotDone = Color(0xFF383734);
  static const Color slotBackfill = Color(0xFF2A2318);
  static const Color slotHabit = Color(0xFF322A20);
  static const Color slotPlanInk = ink;
  static const Color slotDoneInk = meta;
  static const Color slotBackfillInk = ink;
  static const Color slotHabitInk = ink;
  static const Color gridSectionMorning = card;
  static const Color gridSectionNoon = paper;
  static const Color gridSectionEvening = card;
  static const Color shadowTint = Color(0xFF0D0A07);
}

/// 设计文档 §4.1 表左列：浅色 28 色（判据 12 / 13 的对照侧）。
abstract final class _L {
  static const Color paper = Color(0xFFF6F4EF);
  static const Color card = Color(0xFFFBFAF6);
  static const Color sunken = Color(0xFFF0EDE5);
  static const Color dock = Color(0xFFF7F5F0);
  static const Color keybg = Color(0xFFF1EFE8);
  static const Color inkWash = Color(0xFFEFE9DE);
  static const Color accentWash = Color(0xFFF3E8DC);
  static const Color ink = Color(0xFF322B23);
  static const Color ink2 = Color(0xFF4A4036);
  static const Color meta = Color(0xFF5F584B);
  static const Color faint = Color(0xFF6E6759);
  static const Color hair = Color(0xFFDCD5C6);
  static const Color hairSoft = Color(0xFFEAE4D9);
  static const Color hairStrong = Color(0xFF8A8170);
  static const Color accent = Color(0xFF8C5A2B);
  static const Color accentInk = Color(0xFF7A4E24);
  // Task 51 · 诉求 3：四态底整体变浅（向 card 线性靠拢 t≈0.45），
  // 明次序仍是 done < habit < plan ≈ backfill，四值互不相同。
  // Task 54：done 改为「暗一档 + 去彩度」（#EBEBE5），不再贴 paper 那一端，
  // 因此它从明次序顶端落到最暗；plan / backfill / habit 三值未动。
  static const Color slotPlan = Color(0xFFF2EEE6);
  static const Color slotDone = Color(0xFFEBEBE5);
  static const Color slotBackfill = Color(0xFFF3EEE4);
  static const Color slotHabit = Color(0xFFEDE8DE);
  static const Color slotPlanInk = ink;
  static const Color slotDoneInk = meta;
  static const Color slotBackfillInk = ink;
  static const Color slotHabitInk = ink;
  static const Color gridSectionMorning = card;
  static const Color gridSectionNoon = paper;
  static const Color gridSectionEvening = card;
  static const Color shadowTint = Color(0xFF322B23);
}

/// 逐色对齐的两档全表（判据 9 / 11 需要「名字 + 值」）。
const Map<String, Color> _darkAll = <String, Color>{
  'paper': _D.paper,
  'card': _D.card,
  'sunken': _D.sunken,
  'dock': _D.dock,
  'keybg': _D.keybg,
  'inkWash': _D.inkWash,
  'accentWash': _D.accentWash,
  'ink': _D.ink,
  'ink2': _D.ink2,
  'meta': _D.meta,
  'faint': _D.faint,
  'hair': _D.hair,
  'hairSoft': _D.hairSoft,
  'hairStrong': _D.hairStrong,
  'accent': _D.accent,
  'accentInk': _D.accentInk,
  'slotPlan': _D.slotPlan,
  'slotDone': _D.slotDone,
  'slotBackfill': _D.slotBackfill,
  'slotHabit': _D.slotHabit,
  'slotPlanInk': _D.slotPlanInk,
  'slotDoneInk': _D.slotDoneInk,
  'slotBackfillInk': _D.slotBackfillInk,
  'slotHabitInk': _D.slotHabitInk,
  'gridSectionMorning': _D.gridSectionMorning,
  'gridSectionNoon': _D.gridSectionNoon,
  'gridSectionEvening': _D.gridSectionEvening,
  'shadowTint': _D.shadowTint,
};

const Map<String, Color> _lightAll = <String, Color>{
  'paper': _L.paper,
  'card': _L.card,
  'sunken': _L.sunken,
  'dock': _L.dock,
  'keybg': _L.keybg,
  'inkWash': _L.inkWash,
  'accentWash': _L.accentWash,
  'ink': _L.ink,
  'ink2': _L.ink2,
  'meta': _L.meta,
  'faint': _L.faint,
  'hair': _L.hair,
  'hairSoft': _L.hairSoft,
  'hairStrong': _L.hairStrong,
  'accent': _L.accent,
  'accentInk': _L.accentInk,
  'slotPlan': _L.slotPlan,
  'slotDone': _L.slotDone,
  'slotBackfill': _L.slotBackfill,
  'slotHabit': _L.slotHabit,
  'slotPlanInk': _L.slotPlanInk,
  'slotDoneInk': _L.slotDoneInk,
  'slotBackfillInk': _L.slotBackfillInk,
  'slotHabitInk': _L.slotHabitInk,
  'gridSectionMorning': _L.gridSectionMorning,
  'gridSectionNoon': _L.gridSectionNoon,
  'gridSectionEvening': _L.gridSectionEvening,
  'shadowTint': _L.shadowTint,
};

/// 文字 4 色（两档各一组）。
const List<(String, Color, Color)> _textColors = <(String, Color, Color)>[
  ('ink', _D.ink, _L.ink),
  ('ink2', _D.ink2, _L.ink2),
  ('meta', _D.meta, _L.meta),
  ('faint', _D.faint, _L.faint),
];

/// 正文可能压到的两个面。
const List<(String, Color, Color)> _textGrounds = <(String, Color, Color)>[
  ('paper', _D.paper, _L.paper),
  ('card', _D.card, _L.card),
];

/// 四态格底 + 各自前景。
const List<(String, Color, Color)> _slotPairs = <(String, Color, Color)>[
  ('slotPlan', _D.slotPlan, _D.slotPlanInk),
  ('slotDone', _D.slotDone, _D.slotDoneInk),
  ('slotBackfill', _D.slotBackfill, _D.slotBackfillInk),
  ('slotHabit', _D.slotHabit, _D.slotHabitInk),
];

int _r(Color c) => (c.toARGB32() >> 16) & 0xFF;

int _b(Color c) => c.toARGB32() & 0xFF;

void _atLeast(double actual, double min, String what) {
  expect(
    actual,
    greaterThanOrEqualTo(min),
    reason: '$what 实测 ${actual.toStringAsFixed(2)} < $min',
  );
}

void main() {
  test('判据 1：文字 4 色 × {paper, card} 对比度 >= 4.5', () {
    for (final (textName, darkText, _) in _textColors) {
      for (final (bgName, darkBg, _) in _textGrounds) {
        _atLeast(
          contrastRatio(darkText, darkBg),
          4.5,
          '$textName on $bgName',
        );
      }
    }
  });

  test('判据 2：faint / meta × {sunken, dock, keybg, inkWash, accentWash} >= 4.5',
      () {
    const List<(String, Color)> grounds = <(String, Color)>[
      ('sunken', _D.sunken),
      ('dock', _D.dock),
      ('keybg', _D.keybg),
      ('inkWash', _D.inkWash),
      ('accentWash', _D.accentWash),
    ];
    const List<(String, Color)> texts = <(String, Color)>[
      ('faint', _D.faint),
      ('meta', _D.meta),
    ];
    for (final (textName, text) in texts) {
      for (final (bgName, bg) in grounds) {
        _atLeast(contrastRatio(text, bg), 4.5, '$textName on $bgName');
      }
    }
  });

  test('判据 3：hairStrong × 7 个底面 >= 3.0（可交互边界不以装饰线代偿）', () {
    const List<(String, Color)> grounds = <(String, Color)>[
      ('paper', _D.paper),
      ('card', _D.card),
      ('sunken', _D.sunken),
      ('dock', _D.dock),
      ('keybg', _D.keybg),
      ('inkWash', _D.inkWash),
      ('accentWash', _D.accentWash),
    ];
    for (final (bgName, bg) in grounds) {
      _atLeast(contrastRatio(_D.hairStrong, bg), 3.0, 'hairStrong on $bgName');
    }
  });

  test('判据 4：accentInk × {paper, card, accentWash} >= 4.5', () {
    _atLeast(contrastRatio(_D.accentInk, _D.paper), 4.5, 'accentInk on paper');
    _atLeast(contrastRatio(_D.accentInk, _D.card), 4.5, 'accentInk on card');
    _atLeast(
      contrastRatio(_D.accentInk, _D.accentWash),
      4.5,
      'accentInk on accentWash',
    );
  });

  test('判据 5：accent 填充 × {paper, card} >= 3.0', () {
    _atLeast(contrastRatio(_D.accent, _D.paper), 3.0, 'accent on paper');
    _atLeast(contrastRatio(_D.accent, _D.card), 3.0, 'accent on card');
  });

  test('判据 6：四态格底 vs 各自前景 >= 4.5', () {
    for (final (name, bg, fg) in _slotPairs) {
      _atLeast(contrastRatio(bg, fg), 4.5, '$name vs ${name}Ink');
    }
  });

  test('判据 7：四态两两可分离 >= 1.02', () {
    for (var i = 0; i < _slotPairs.length; i++) {
      for (var j = i + 1; j < _slotPairs.length; j++) {
        final a = _slotPairs[i];
        final b = _slotPairs[j];
        _atLeast(
          contrastRatio(a.$2, b.$2),
          1.02,
          '${a.$1} vs ${b.$1}',
        );
      }
    }
  });

  test('判据 8：四态互不相同（ARGB 唯一）', () {
    final Set<int> seen = <int>{};
    for (final (name, bg, _) in _slotPairs) {
      expect(seen.add(bg.toARGB32()), isTrue, reason: '$name 与前面某态撞色');
    }
  });

  test('判据 9：去蓝闸门 —— 28 色全部 R >= B', () {
    expect(_darkAll.length, 28);
    for (final MapEntry<String, Color> e in _darkAll.entries) {
      expect(
        _r(e.value),
        greaterThanOrEqualTo(_b(e.value)),
        reason: '${e.key} R=${_r(e.value)} B=${_b(e.value)}',
      );
    }
  });

  test('判据 10：角色分离（accent≠ink / accentInk≠ink / hairStrong≠hair / accent≠accentWash）',
      () {
    expect(_D.accent, isNot(_D.ink));
    expect(_D.accentInk, isNot(_D.ink));
    expect(_D.hairStrong, isNot(_D.hair));
    expect(_D.accent, isNot(_D.accentWash));
  });

  test('判据 11：深色 ≠ 浅色（28 色逐一，无复用）', () {
    expect(_darkAll.keys, _lightAll.keys);
    for (final MapEntry<String, Color> e in _darkAll.entries) {
      expect(
        e.value,
        isNot(_lightAll[e.key]),
        reason: '${e.key} 深色与浅色同值',
      );
    }
  });

  test('判据 12：逐对 —— 深色对比度不显著差于浅色（容差 0.5）', () {
    for (final (textName, darkText, lightText) in _textColors) {
      for (final (bgName, darkBg, lightBg) in _textGrounds) {
        final dark = contrastRatio(darkText, darkBg);
        final light = contrastRatio(lightText, lightBg);
        expect(
          dark,
          greaterThanOrEqualTo(light - 0.5),
          reason: '$textName on $bgName：深 ${dark.toStringAsFixed(2)} '
              'vs 浅 ${light.toStringAsFixed(2)}',
        );
      }
    }
  });

  test('判据 13：每个文字色最差场景 深色 >= 浅色', () {
    for (final (textName, darkText, lightText) in _textColors) {
      final darkMin = _textGrounds
          .map(((String, Color, Color) g) => contrastRatio(darkText, g.$2))
          .reduce((double a, double b) => a < b ? a : b);
      final lightMin = _textGrounds
          .map(((String, Color, Color) g) => contrastRatio(lightText, g.$3))
          .reduce((double a, double b) => a < b ? a : b);
      expect(
        darkMin,
        greaterThanOrEqualTo(lightMin),
        reason: '$textName：深最差 ${darkMin.toStringAsFixed(2)} '
            'vs 浅最差 ${lightMin.toStringAsFixed(2)}',
      );
    }
  });

  // Task 51 · 诉求 3：上午段（06:00–12:00）与晚上段（18:00–24:00）逐字同值。
  //
  // 这条判据是**关系**而不是**取值**：断言两个 token 相等，不会替实现给自己的
  // 色值判卷（值仍由 `_D` / `_L` 两组字面量与 `theme_tokens_test.dart` 钉住），
  // 所以本文件破例引入 `ThemeTokens` 不违反「不引用 ThemeTokens.dark.*」的初衷。
  test('判据 14（Task 51）：上午段与晚上段底色逐字同值，中间段仍可区分', () {
    // 规格侧：字面量表自己先成立，否则实现再「对齐」也是对齐到错的规格。
    expect(_L.gridSectionMorning, _L.gridSectionEvening);
    expect(_D.gridSectionMorning, _D.gridSectionEvening);
    // 中间段必须仍是另一个值 —— 否则三段会塌成一段，格子失去「上下午」提示。
    expect(_L.gridSectionNoon, isNot(_L.gridSectionMorning));
    expect(_D.gridSectionNoon, isNot(_D.gridSectionMorning));

    // 实现侧：真实 token 逐档同值。
    expect(
      ThemeTokens.light.gridSectionMorning,
      ThemeTokens.light.gridSectionEvening,
    );
    expect(
      ThemeTokens.dark.gridSectionMorning,
      ThemeTokens.dark.gridSectionEvening,
    );
    expect(
      ThemeTokens.light.gridSectionNoon,
      isNot(ThemeTokens.light.gridSectionMorning),
    );
    expect(
      ThemeTokens.dark.gridSectionNoon,
      isNot(ThemeTokens.dark.gridSectionMorning),
    );
  });
}