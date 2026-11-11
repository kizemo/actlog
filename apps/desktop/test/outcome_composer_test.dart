// apps/desktop/test/outcome_composer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/outcome_composer.dart';

void main() {
  testWidgets('三段芯片选完即成一句规范文案', (tester) async {
    String? captured;
    bool? markedDone;
    await tester.pumpWidget(
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
    );
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
      const MaterialApp(
        home: Scaffold(body: OutcomeComposer(initial: '随手写的一段话')),
      ),
    );
    expect(find.text('随手写的一段话'), findsOneWidget);
    expect(find.text('重新结构化'), findsOneWidget);
    expect(find.text('按时完成'), findsNothing);
  });

  testWidgets('规范文案能反解回已选芯片', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OutcomeComposer(initial: '[结论]按时完成')),
      ),
    );
    expect(find.text('按时完成'), findsOneWidget);
  });

  testWidgets('初始下一步自由文本要回填进输入框', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OutcomeComposer(initial: '[结论]按时完成 | [下一步]周四上午做完'),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '周四上午做完');
  });
}