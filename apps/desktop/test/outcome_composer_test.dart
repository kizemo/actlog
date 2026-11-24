// apps/desktop/test/outcome_composer_test.dart
//
// Task 63 W7：三段标签（结论/原因/下一步）与按钮文案已迁进 l10n，
// 被测 widget 走 `AppLocalizations.of(context)` ⇒ 每个 pump 都要包 `l10nScope`。
// 断言仍只断**字面量**（§47.3 ①）：不写 `find.text(t.xxx)` 同义反复，
// 否则改错 zh 也照样绿。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/outcome_composer.dart';

import 'l10n_harness.dart';

void main() {
  testWidgets('三段芯片选完即成一句规范文案', (tester) async {
    String? captured;
    bool? markedDone;
    await tester.pumpWidget(
      l10nScope(
        MaterialApp(
          home: Scaffold(
            body: OutcomeComposer(
              initial: '',
              onSubmit: (String encoded, {required bool markDone}) {
                captured = encoded;
                markedDone = markDone;
              },
            ),
          ),
        ),
      ),
    );
    // 三段标题现在由 l10n 出字：zh 态必须还是这三个词。
    expect(find.text('结论'), findsOneWidget);
    expect(find.text('原因'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    await tester.tap(find.text('按时完成'));
    await tester.pump();
    await tester.tap(find.text('预估不足'));
    await tester.pump();
    await tester.tap(find.text('只存进展'));
    await tester.pump();
    expect(captured, '[结论]按时完成 | [原因]预估不足');
    expect(markedDone, isFalse);
  });

  testWidgets('点完成要带 done 意图', (tester) async {
    String? captured;
    bool? markedDone;
    await tester.pumpWidget(
      l10nScope(
        MaterialApp(
          home: Scaffold(
            body: OutcomeComposer(
              initial: '',
              onSubmit: (String encoded, {required bool markDone}) {
                captured = encoded;
                markedDone = markDone;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('按时完成'));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pump();
    expect(captured, '[结论]按时完成');
    expect(markedDone, isTrue);
  });

  testWidgets('反解失败降级为只读纯文本并给出重新结构化入口', (tester) async {
    await tester.pumpWidget(
      l10nScope(
        const MaterialApp(
          home: Scaffold(body: OutcomeComposer(initial: '随手写的一段话')),
        ),
      ),
    );
    expect(find.text('随手写的一段话'), findsOneWidget);
    expect(find.text('重新结构化'), findsOneWidget);
    expect(find.text('按时完成'), findsNothing);
  });

  testWidgets('规范文案能反解回已选芯片', (tester) async {
    await tester.pumpWidget(
      l10nScope(
        const MaterialApp(
          home: Scaffold(body: OutcomeComposer(initial: '[结论]按时完成')),
        ),
      ),
    );
    expect(find.text('按时完成'), findsOneWidget);
  });

  testWidgets('初始下一步自由文本要回填进输入框', (tester) async {
    await tester.pumpWidget(
      l10nScope(
        const MaterialApp(
          home: Scaffold(
            body: OutcomeComposer(initial: '[结论]按时完成 | [下一步]周四上午做完'),
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '周四上午做完');
  });
}