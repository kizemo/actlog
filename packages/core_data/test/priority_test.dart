// ignore_for_file: public_member_api_docs

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('四象限展示元数据（P1-4）', () {
    test('四象限齐全，短名与颜色互不相同', () {
      expect(QuadrantStyle.all.length, 4);
      final shortLabels =
          QuadrantStyle.all.values.map((s) => s.shortLabel).toSet();
      final colors = QuadrantStyle.all.values.map((s) => s.colorHex).toSet();
      expect(shortLabels.length, 4);
      expect(colors.length, 4);
    });

    test('每个象限都有非空行动建议文案', () {
      for (final style in QuadrantStyle.all.values) {
        expect(style.advice.trim(), isNotEmpty);
        expect(style.label.trim(), isNotEmpty);
        expect(RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(style.colorHex), isTrue);
      }
    });

    test('未知象限回落到 Q4 而不是抛异常', () {
      expect(QuadrantStyle.of(null).quadrant, Quadrant.q4);
    });

    test('ABC 元数据齐全且未知值回落到 C', () {
      expect(AbcStyle.all.length, 3);
      expect(AbcStyle.of(null).priority, PriorityAbc.c);
      expect(AbcStyle.of(PriorityAbc.a).label, 'A 类要事');
    });
  });

  group('显示模式（P1-5）', () {
    test('四象限模式表头联动「A 类 = Q1 + Q2」', () {
      expect(
        PriorityDisplay.headerHint(PriorityDisplayMode.quadrant),
        'A 类 = Q1 + Q2',
      );
    });

    test('ABC 模式表头不出现象限符号', () {
      final hint = PriorityDisplay.headerHint(PriorityDisplayMode.abc);
      expect(hint, PriorityDisplay.abcHeaderHint);
      expect(hint.contains('Q1'), isFalse);
    });

    test('只渲染一套标签：四象限模式不返回 ABC 文案', () {
      final label = PriorityDisplay.labelFor(
        PriorityDisplayMode.quadrant,
        quadrant: Quadrant.q2,
        priorityAbc: PriorityAbc.a,
      );
      expect(label, QuadrantStyle.of(Quadrant.q2).label);
      expect(label.contains('A 类'), isFalse);
    });

    test('只渲染一套标签：ABC 模式不返回象限文案', () {
      final label = PriorityDisplay.labelFor(
        PriorityDisplayMode.abc,
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.b,
      );
      expect(label, AbcStyle.of(PriorityAbc.b).label);
      expect(label.contains('紧急'), isFalse);
    });

    test('未分级显示「未分级」', () {
      expect(PriorityDisplay.labelFor(PriorityDisplayMode.quadrant), '未分级');
      expect(PriorityDisplay.labelFor(PriorityDisplayMode.abc), '未分级');
    });

    test('排序权重：Q1 < Q2 < Q3 < Q4 < 未分级', () {
      int w(Quadrant? q) =>
          PriorityDisplay.sortWeight(PriorityDisplayMode.quadrant, quadrant: q);
      expect(w(Quadrant.q1), lessThan(w(Quadrant.q2)));
      expect(w(Quadrant.q2), lessThan(w(Quadrant.q3)));
      expect(w(Quadrant.q3), lessThan(w(Quadrant.q4)));
      expect(w(Quadrant.q4), lessThan(w(null)));
    });

    test('排序权重：A < B < C < 未分级', () {
      int w(PriorityAbc? p) =>
          PriorityDisplay.sortWeight(PriorityDisplayMode.abc, priorityAbc: p);
      expect(w(PriorityAbc.a), lessThan(w(PriorityAbc.b)));
      expect(w(PriorityAbc.b), lessThan(w(PriorityAbc.c)));
      expect(w(PriorityAbc.c), lessThan(w(null)));
    });

    test('两种模式互不读取对方的字段', () {
      // 四象限模式下，即使 ABC 是 A 也不改变权重。
      final quadrantMode = PriorityDisplay.sortWeight(
        PriorityDisplayMode.quadrant,
        quadrant: Quadrant.q4,
        priorityAbc: PriorityAbc.a,
      );
      expect(
        quadrantMode,
        PriorityDisplay.sortWeight(
          PriorityDisplayMode.quadrant,
          quadrant: Quadrant.q4,
        ),
      );

      // ABC 模式下，即使象限是 Q1 也不改变权重。
      final abcMode = PriorityDisplay.sortWeight(
        PriorityDisplayMode.abc,
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.c,
      );
      expect(
        abcMode,
        PriorityDisplay.sortWeight(
          PriorityDisplayMode.abc,
          priorityAbc: PriorityAbc.c,
        ),
      );
    });

    test('四象限模式下 A 类要事 = Q1 + Q2', () {
      expect(PriorityDisplay.isClassAUnderQuadrant(Quadrant.q1), isTrue);
      expect(PriorityDisplay.isClassAUnderQuadrant(Quadrant.q2), isTrue);
      expect(PriorityDisplay.isClassAUnderQuadrant(Quadrant.q3), isFalse);
      expect(PriorityDisplay.isClassAUnderQuadrant(Quadrant.q4), isFalse);
      expect(PriorityDisplay.isClassAUnderQuadrant(null), isFalse);
    });
  });
}