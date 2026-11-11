// apps/desktop/test/ledger_checkbox_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';

/// 勾选框自身的方框（`Stack` 里第一个 `Container`）。
Finder _boxFinder() => find
    .descendant(of: find.byType(LedgerCheckbox), matching: find.byType(Container))
    .first;

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<Container>(_boxFinder()).decoration! as BoxDecoration;

Color _fill(WidgetTester tester) => _decoration(tester).color!;

Border _border(WidgetTester tester) =>
    _decoration(tester).border! as Border;

Color _glyphColor(WidgetTester tester, String glyph) =>
    tester.widget<Text>(find.text(glyph)).style!.color!;

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('未选：22×22 方框 + ○ 字形 + 1.5px hair-strong 边 + paper 底', (tester) async {
    await _pump(tester, LedgerCheckbox(value: false, onChanged: (_) {}));

    expect(tester.getSize(_boxFinder()), const Size(22, 22));
    expect(find.text('○'), findsOneWidget);
    expect(find.text('✓'), findsNothing);
    expect(_border(tester).top.width, 1.5);
    expect(_border(tester).top.color, AppTokens.hairStrong);
    expect(_fill(tester), AppTokens.paper);
    expect(_glyphColor(tester, '○'), AppTokens.ink);
  });

  testWidgets('选中：ink 反白 + ✓ 字形', (tester) async {
    await _pump(tester, LedgerCheckbox(value: true, onChanged: (_) {}));

    expect(find.text('✓'), findsOneWidget);
    expect(_fill(tester), AppTokens.ink);
    expect(_border(tester).top.color, AppTokens.ink);
    expect(_glyphColor(tester, '✓'), AppTokens.paper);
  });

  testWidgets('点击切换回调', (tester) async {
    final toggled = <bool>[];
    await _pump(tester, LedgerCheckbox(value: false, onChanged: toggled.add));

    await tester.tap(find.byType(LedgerCheckbox));
    await tester.pump();
    expect(toggled, <bool>[true]);
  });

  testWidgets('Space 切换（独立焦点节点）', (tester) async {
    final toggled = <bool>[];
    await _pump(
      tester,
      LedgerCheckbox(value: false, autofocus: true, onChanged: toggled.add),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(toggled, <bool>[true]);
  });

  testWidgets('Enter 切换', (tester) async {
    final toggled = <bool>[];
    await _pump(
      tester,
      LedgerCheckbox(value: false, autofocus: true, onChanged: toggled.add),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(toggled, <bool>[true]);
  });

  testWidgets('聚焦后焦点环是 ink 2px（不自造环、不改 ring）', (tester) async {
    await _pump(
      tester,
      LedgerCheckbox(value: false, autofocus: true, onChanged: (_) {}),
    );

    expect(
      find.byKey(const ValueKey('focus-ring-border')),
      findsOneWidget,
    );
    final ring = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('focus-ring-border')),
    );
    final border = (ring.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, AppTokens.ink);
    expect(border.top.width, 2);
  });

  testWidgets('就近优先：框级 ActivateIntent 吃掉按键，不触发外层行级动作', (tester) async {
    final toggled = <bool>[];
    var parentHits = 0;
    await _pump(
      tester,
      Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              parentHits += 1;
              return null;
            },
          ),
        },
        child: LedgerCheckbox(
          value: false,
          autofocus: true,
          onChanged: toggled.add,
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(toggled, <bool>[true]);
    expect(parentHits, 0);
  });

  // Task 25 · W3：把「两个方向」与「Enter 也走就近优先」补到纯 widget 层。
  // 页面级对照（真库往返 + 回填弹层未出现）在 `ledger_checkbox_enter_test.dart`。
  testWidgets('Space 切换：已选 → 未选（done → pending 方向）', (tester) async {
    final toggled = <bool>[];
    await _pump(
      tester,
      LedgerCheckbox(value: true, autofocus: true, onChanged: toggled.add),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(toggled, <bool>[false]);
  });

  testWidgets('Enter 就近优先：框级 ActivateIntent 吃掉 Enter，不触发外层行级动作', (
    tester,
  ) async {
    final toggled = <bool>[];
    var parentHits = 0;
    await _pump(
      tester,
      Actions(
        actions: <Type, Action<Intent>>{
          // 外层这份 `ActivateIntent` 就是「行级 Enter 开回填弹层」的替身：
          // 它一旦被调到，真机上就是弹层出来了。
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              parentHits += 1;
              return null;
            },
          ),
        },
        child: LedgerCheckbox(
          value: true,
          autofocus: true,
          onChanged: toggled.add,
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(toggled, <bool>[false], reason: 'Enter 必须只切一次勾选（已选 → 未选）');
    expect(parentHits, 0, reason: '框上 Enter 不得冒泡到行级动作');
  });

  testWidgets('禁用（onChanged 为 null）：灰字、不可点、不可聚焦', (tester) async {
    await _pump(tester, const LedgerCheckbox(value: false));

    expect(_glyphColor(tester, '○'), AppTokens.faint);
    await tester.tap(find.byType(LedgerCheckbox), warnIfMissed: false);
    await tester.pump();
    // 禁用时 Focus 不接受焦点，焦点环节点保持透明。
    final ring = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('focus-ring-border')),
    );
    final border = (ring.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, Colors.transparent);
  });
}