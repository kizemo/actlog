// apps/desktop/test/task39_priority_marks_test.dart
//
// Task 40 · 需求 3 的专项回归：优先级标记两条轴各用**一枚图标**，
// 正负值只靠**填充 / 空心**区分 —— 重要性轴 = 实心星 / 空心星，
// 紧急度轴 = 实心铃 / 空心铃；「象限 → 标记」仍是可区分描述对象。
//
// 盯四件事：
//   1. 身份：`PriorityMark` 是唯一身份来源（key / 填充 / 图标 / 颜色），
//      `markOf` / `marksOf` 是唯一取用入口；四象限组合按值级 key 两两不同；
//   2. 重要性轴：同一枚 `Icons.star` 的填充 / 空心两态 —— **同图标**，
//      区分只靠 `filled`（true / false）与 token 色（accent / faint）；
//   3. 紧急度轴：同一枚 `Icons.notifications` 的填充 / 空心两态，同样只差填充；
//      不换图标，也**不用** Unicode 符号（⏱ 一类在本机字体链 0/9 覆盖 ⇒ 豆腐块）；
//   4. 一致：悬停气泡与主通道共用同一份描述对象 ⇒ 同 key、同 `resolvedIcon`，
//      不许在气泡里另写一套图标。
//
// 本文件是**纯控件级**回归，不碰数据库；落库链路仍由
// `priority_marks_test.dart` / `priority_hover_bubble_test.dart` 用真库把守。
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/priority_hover_bubble.dart';
import 'package:actlog/src/widgets/priority_marks.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 四个象限 → (重要性轴, 紧急度轴) 的期望组合（顺序 = 渲染顺序）。
const Map<Quadrant, (PriorityMark, PriorityMark)> _expected =
    <Quadrant, (PriorityMark, PriorityMark)>{
  Quadrant.q1: (kMarkImportantSpec, kMarkUrgentSpec),
  Quadrant.q2: (kMarkImportantSpec, kMarkNotUrgentSpec),
  Quadrant.q3: (kMarkNotImportantSpec, kMarkUrgentSpec),
  Quadrant.q4: (kMarkNotImportantSpec, kMarkNotUrgentSpec),
};

/// 悬停到 [target] 中心，触发 `MouseRegion.onEnter`。
///
/// 刻意**不用** `pumpAndSettle`：加载态可能是无限重复动画（同 hover 主用例）。
Future<void> _hover(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  await tester.pump();
}

void main() {
  group('标记身份', () {
    testWidgets('四象限标记组合两两不同，且每枚都被自己的 key 定位到', (tester) async {
      for (final MapEntry<Quadrant, (PriorityMark, PriorityMark)> entry
          in _expected.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: PriorityMarks(quadrant: entry.key)),
            ),
          ),
        );
        final Finder scope = find.byType(PriorityMarks);
        expect(
          find.descendant(of: scope, matching: find.byKey(entry.value.$1.key)),
          findsOneWidget,
          reason: '${entry.key.code} 的重要性轴标记缺失',
        );
        expect(
          find.descendant(of: scope, matching: find.byKey(entry.value.$2.key)),
          findsOneWidget,
          reason: '${entry.key.code} 的紧急度轴标记缺失',
        );
      }

      // 四象限的「(重要性 key, 紧急度 key)」两两不同 —— 同形 `!` 之下，
      // 只有 key 还能证明 Q1 与 Q3 不是同一个东西。
      expect(
        _expected.values
            .map(((PriorityMark, PriorityMark) pair) => '${pair.$1.key}/${pair.$2.key}')
            .toSet(),
        hasLength(4),
        reason: '四象限标记组合必须两两不同',
      );
      // 每条轴恰好两种取值，不允许第三态混进来。
      expect(
        _expected.values
            .map(((PriorityMark, PriorityMark) pair) => pair.$1.key)
            .toSet(),
        hasLength(2),
      );
      expect(
        _expected.values
            .map(((PriorityMark, PriorityMark) pair) => pair.$2.key)
            .toSet(),
        hasLength(2),
      );
    });

    test('重要性轴：同一枚星，靠填充 / 空心 + token 色区分', () {
      // 需求是「同一枚图标，用填充/空心区分」，不是两枚不同形状。
      expect(kMarkImportant, Icons.star);
      expect(kMarkNotImportant, Icons.star_border);
      // 两枚 spec **共用同一对图标**，唯一差异是 `filled`。
      expect(kMarkImportantSpec.icon, kMarkNotImportantSpec.icon);
      expect(kMarkImportantSpec.outlineIcon, kMarkNotImportantSpec.outlineIcon);
      expect(kMarkImportantSpec.filled, isTrue);
      expect(kMarkNotImportantSpec.filled, isFalse);
      // 因此渲染值才是两枚不同字形（实心 / 描边）。
      expect(kMarkImportantSpec.resolvedIcon, kMarkImportant);
      expect(kMarkNotImportantSpec.resolvedIcon, kMarkNotImportant);

      // 区分剩两条通道：填充与颜色。两条都必须成立，缺一条就不可辨。
      expect(kMarkImportantSpec.color, AppTokens.accent);
      expect(kMarkNotImportantSpec.color, AppTokens.faint);
      expect(kMarkImportantSpec.key, isNot(kMarkNotImportantSpec.key));
      // `emphasis` 是文本通道的遗留字段，取值保持原样（当前不参与渲染）。
      expect(kMarkImportantSpec.emphasis, FontWeight.w700);
      expect(kMarkNotImportantSpec.emphasis, FontWeight.w400);
      // 重要性轴走图标通道；不再有文本字形 ⇒ 不会出现豆腐块风险。
      expect(kMarkImportantSpec.isIcon, isTrue);
      expect(kMarkNotImportantSpec.isIcon, isTrue);
      expect(kMarkImportantSpec.glyph, isNull);
      expect(kMarkNotImportantSpec.glyph, isNull);
    });

    testWidgets('紧急度轴：同一枚铃的填充 / 空心两态，不是 Unicode 符号', (
      WidgetTester tester,
    ) async {
      expect(kMarkUrgent, Icons.notifications);
      expect(kMarkNotUrgent, Icons.notifications_none);
      // 同一轴共用一对图标，只有 `filled` 不同。
      expect(kMarkUrgentSpec.icon, kMarkNotUrgentSpec.icon);
      expect(kMarkUrgentSpec.outlineIcon, kMarkNotUrgentSpec.outlineIcon);
      expect(kMarkUrgentSpec.filled, isTrue);
      expect(kMarkNotUrgentSpec.filled, isFalse);
      expect(kMarkUrgentSpec.resolvedIcon, kMarkUrgent);
      expect(kMarkNotUrgentSpec.resolvedIcon, kMarkNotUrgent);
      // 填充与描边是两枚不同字形 ⇒ 填充态可辨。
      expect(kMarkUrgent, isNot(kMarkNotUrgent));
      expect(kMarkUrgentSpec.isIcon, isTrue);
      expect(kMarkNotUrgentSpec.isIcon, isTrue);
      expect(kMarkUrgentSpec.glyph, isNull);
      expect(kMarkNotUrgentSpec.glyph, isNull);
      expect(kMarkUrgentSpec.key, isNot(kMarkNotUrgentSpec.key));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: PriorityMarks(quadrant: Quadrant.q2)),
          ),
        ),
      );
      final Icon icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(PriorityMarks),
          matching: find.byKey(kMarkNotUrgentSpec.key),
        ),
      );
      expect(icon.icon, Icons.notifications_none);
      expect(icon.color, AppTokens.faint);
      // Q2 = 重要性轴（星）+ 紧急度轴（空心铃）⇒ 整棵树恰好两枚 `Icon`，
      // 且一个 `Text` 都没有 ⇒ 没有任何 Unicode 时钟/铃字符混进来。
      expect(find.byType(Icon), findsNWidgets(2));
      expect(find.byType(Text), findsNothing);
      expect(find.text('!'), findsNothing);
      expect(find.text('⏱'), findsNothing);
      expect(find.text('⏰'), findsNothing);
    });
  });

  group('象限 ↔ 标记同构', () {
    test('marksOf 与象限的两个布尔同构，markOf 是唯一入口', () {
      for (final Quadrant quadrant in Quadrant.values) {
        final List<PriorityMark> marks = marksOf(quadrant);
        expect(marks, hasLength(2));
        expect(
          marks[0],
          markOf(axis: PriorityAxis.importance, positive: quadrant.isImportant),
        );
        expect(
          marks[1],
          markOf(axis: PriorityAxis.urgency, positive: quadrant.isUrgent),
        );
        // 顺序固定：先重要性（星），后紧急度（铃）。
        expect(marks.first.isIcon, isTrue, reason: '第一枚必须是重要性轴（星）');
        expect(marks.last.isIcon, isTrue, reason: '第二枚必须是紧急度轴（铃）');
      }

      // 布尔 → 象限同样只有一个映射点，四象限全覆盖。
      expect(quadrantOf(important: true, urgent: true), Quadrant.q1);
      expect(quadrantOf(important: true, urgent: false), Quadrant.q2);
      expect(quadrantOf(important: false, urgent: true), Quadrant.q3);
      expect(quadrantOf(important: false, urgent: false), Quadrant.q4);
    });
  });

  group('气泡与主通道', () {
    testWidgets('悬停气泡里的标记与主通道同 key、同 Icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, top: 120),
                child: PriorityHoverBubble(
                  quadrant: Quadrant.q1,
                  title: '写复盘',
                  onChanged: (Quadrant? _) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 基线：只有主通道两枚（实心星 + 实心铃），气泡还没建。
      expect(find.byKey(kMarkImportantSpec.key), findsOneWidget);
      expect(find.byKey(kMarkNotImportantSpec.key), findsNothing);
      expect(find.byIcon(kMarkUrgent), findsOneWidget);
      expect(find.byIcon(kMarkNotUrgent), findsNothing);

      await _hover(tester, find.byType(PriorityMarks));
      expect(
        find.byKey(const ValueKey<String>('priority-hover-bubble')),
        findsOneWidget,
      );

      // 气泡两行各两枚芯片 ⇒ 两条轴的两种取值都在场，且与主通道**同一个 key**。
      expect(find.byKey(kMarkImportantSpec.key), findsNWidgets(2)); // 主通道 + 芯片
      expect(find.byKey(kMarkNotImportantSpec.key), findsOneWidget); // 未选中芯片
      expect(find.byIcon(kMarkUrgent), findsNWidgets(2)); // 主通道 + 芯片
      expect(find.byIcon(kMarkNotUrgent), findsOneWidget); // 未选中芯片
      // 同轴同形、只差填充：主通道那枚与气泡里同 key 的那枚必须是**同一字形**，
      // 否则「气泡只是另一套画法」了。这里直接读两处的 `Icon.icon` 比对。
      final List<Icon> importantIcons = tester
          .widgetList<Icon>(find.byIcon(kMarkImportant))
          .toList();
      expect(importantIcons, hasLength(2));
      expect(
        importantIcons.every((Icon i) => i.icon == kMarkImportantSpec.resolvedIcon),
        isTrue,
        reason: '主通道与气泡的重要性标记必须同字形（实心星）',
      );
      // 两条轴的正负态各自只差填充：`filled` 为唯一差异，字形成对存在。
      expect(kMarkImportantSpec.filled, isNot(kMarkNotImportantSpec.filled));
      expect(kMarkUrgentSpec.filled, isNot(kMarkNotUrgentSpec.filled));
    });
  });
}
