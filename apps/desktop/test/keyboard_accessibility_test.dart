import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart' show isTextInputFocused;
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/chip_row.dart';
import 'package:actlog/src/widgets/focus_ring.dart';

void main() {
  testWidgets('焦点环是 ink 2px，不是 accent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FocusRing(child: Text('x'))),
      ),
    );
    final ring = tester.widget<FocusRing>(find.byType(FocusRing));
    expect(ring.focusedBorderWidth, 2);
    expect(AppTokens.accent, isNot(AppTokens.ink));
  });

  testWidgets('聚焦后环 = ink 2px，失焦后透明', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusRing(
            focusNode: node,
            child: Focus(
              focusNode: node,
              child: const SizedBox(width: 40, height: 20),
            ),
          ),
        ),
      ),
    );
    Border ringBorder() {
      final ring = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('focus-ring-border')),
      );
      return (ring.decoration! as BoxDecoration).border! as Border;
    }

    node.requestFocus();
    await tester.pumpAndSettle();
    expect(ringBorder().top.color, AppTokens.ink);
    expect(ringBorder().top.width, 2);

    node.unfocus();
    await tester.pumpAndSettle();
    expect(ringBorder().top.color, Colors.transparent);
  });

  testWidgets('芯片聚焦后 Space / Enter 触发 onChanged', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: const <ChipOption>[
              ChipOption(key: 'a', label: '按时完成'),
            ],
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    // 让芯片拿到焦点：优先用 Tab 遍历，取不到就显式 requestFocus。
    // 芯片的 FocusNode 就是 FocusRing 收到的那个（chip_row 用它包 InkWell）。
    final FocusNode chipNode =
        tester.widget<FocusRing>(find.byType(FocusRing)).focusNode!;
    chipNode.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(captured, {'a'});

    captured = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(captured, {'a'});
  });

  testWidgets('文本输入域内 isTextInputFocused 为真，离开后为假', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              TextField(),
              FilledButton(onPressed: _noop, child: Text('ok')),
            ],
          ),
        ),
      ),
    );
    expect(isTextInputFocused(), isFalse);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(isTextInputFocused(), isTrue);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(isTextInputFocused(), isFalse);
  });

  testWidgets('Tab 逐枚遍历芯片，Space 命中当前焦点芯片，焦点环只亮那一枚', (
    WidgetTester tester,
  ) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: const <ChipOption>[
              ChipOption(key: 'a', label: '按时完成'),
              ChipOption(key: 'b', label: '部分完成'),
              ChipOption(key: 'c', label: '未开始'),
            ],
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final List<FocusNode> nodes = tester
        .widgetList<FocusRing>(find.byType(FocusRing))
        .map((FocusRing ring) => ring.focusNode!)
        .toList();
    expect(nodes.length, 3, reason: '三条选项必须各有自己的焦点节点');

    // 连续 Tab 必须按顺序落到每一枚芯片上，第三枚不能被跳过。
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        same(nodes[i]),
        reason: '第 ${i + 1} 次 Tab 应把焦点放到第 ${i + 1} 枚芯片',
      );
    }

    // 焦点此刻在第三枚：Space 必须命中 'c'，而不是恒定的首枚 'a'。
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(captured, <String>{'c'});

    Border ringBorderAt(int index) {
      final AnimatedContainer ring = tester.widgetList<AnimatedContainer>(
        find.byKey(const ValueKey('focus-ring-border')),
      ).elementAt(index);
      return (ring.decoration! as BoxDecoration).border! as Border;
    }

    // 只有当前焦点那一枚亮 ink 2px，其余两枚必须是透明环（未聚焦态）。
    expect(ringBorderAt(2).top.color, AppTokens.ink);
    expect(ringBorderAt(2).top.width, 2);
    expect(ringBorderAt(0).top.color, Colors.transparent);
    expect(ringBorderAt(1).top.color, Colors.transparent);
  });
}

void _noop() {}