// apps/desktop/test/timeline_contrast_test.dart
//
// B2 方格时间轴 §3：四种视觉态格底的对比度**实测**闸门。
//
// 真源是仓库里的 `lib/src/theme/contrast.dart`（WCAG 2.1 相对亮度 + 比值），
// 不是设计稿估计值。这里把 `design-demos/TOKENS.md` §8.1 表里的数字连同
// 「≥ 4.5:1」的硬判据一起钉死：任何一方改色、或有人把实测值改回估计值，都会红。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/contrast.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';

/// 单个视觉态的验收样本：格底 token + 契约规定的前景色 + 实测对比度。
final class _SlotCase {
  const _SlotCase({
    required this.name,
    required this.background,
    required this.foreground,
    required this.measured,
  });

  final String name;
  final Color background;
  final Color foreground;

  /// `design-demos/TOKENS.md` §8.1 里登记的实测值。
  final double measured;
}

const List<_SlotCase> _cases = <_SlotCase>[
  _SlotCase(
    name: '--slot-plan',
    background: AppTokens.slotPlan,
    foreground: AppTokens.ink,
    measured: 8.91,
  ),
  _SlotCase(
    name: '--slot-done',
    background: AppTokens.slotDone,
    foreground: AppTokens.meta,
    measured: 6.27,
  ),
  _SlotCase(
    name: '--slot-backfill',
    background: AppTokens.slotBackfill,
    foreground: AppTokens.ink,
    measured: 8.39,
  ),
  _SlotCase(
    name: '--slot-habit',
    background: AppTokens.slotHabit,
    foreground: AppTokens.ink,
    measured: 8.23,
  ),
];

void main() {
  // WCAG 2.1 对正文要求 4.5:1；四态格底承载 14px 正文，必须全部达标。
  const double kMinRatio = 4.5;

  test('四态格底对比度全部 ≥ 4.5:1 且等于 TOKENS.md §8.1 实测值', () {
    for (final _SlotCase c in _cases) {
      final double ratio = contrastRatio(c.background, c.foreground);
      expect(
        ratio,
        greaterThanOrEqualTo(kMinRatio),
        reason: '${c.name} 与前景色对比度 $ratio 未达 $kMinRatio:1',
      );
      // TOKENS.md 登记的是两位小数 ⇒ 容差 0.005 只允许四舍五入差，
      // 任何真实改色都会把比值推动得远大于此。
      expect(
        ratio,
        moreOrLessEquals(c.measured, epsilon: 0.005),
        reason: '${c.name} 实测值已偏离 TOKENS.md §8.1 登记的 ${c.measured}',
      );
    }
  });

  test('四态格底互不相同：没有两个态共用同一个底色', () {
    final Set<int> seen = <int>{};
    for (final _SlotCase c in _cases) {
      expect(
        seen.add(c.background.toARGB32()),
        isTrue,
        reason: '${c.name} 与前面的态撞色，四态不可区分',
      );
    }
  });

  test('颜色映射：四个 SlotKind 各自映射到自己的 token，赭石不参与', () {
    expect(colorOfSlotKind(SlotKind.plannedOpen), AppTokens.slotPlan);
    expect(colorOfSlotKind(SlotKind.done), AppTokens.slotDone);
    expect(colorOfSlotKind(SlotKind.backfill), AppTokens.slotBackfill);
    expect(colorOfSlotKind(SlotKind.habit), AppTokens.slotHabit);

    for (final SlotKind kind in SlotKind.values) {
      final Color color = colorOfSlotKind(kind);
      expect(
        color,
        isNot(AppTokens.accent),
        reason: '$kind 不得用赭石（--accent 只属「缺口 / 警示」语义）',
      );
      expect(color, isNot(AppTokens.accentWash), reason: '$kind 不得用赭石洗底');
    }
  });
}