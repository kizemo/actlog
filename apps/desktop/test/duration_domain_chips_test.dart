// apps/desktop/test/duration_domain_chips_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/domain_chips.dart';
import 'package:actlog/src/widgets/duration_chips.dart';

void main() {
  testWidgets('时长档位来自 spec §7 的 8 档', (tester) async {
    expect(DurationChips.presets, <int>[5, 10, 15, 25, 45, 60, 90, 120]);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DurationChips(selectedMinutes: 25))),
    );
    expect(find.text('25 分钟'), findsOneWidget);
    expect(find.text('120 分钟'), findsOneWidget);
  });

  testWidgets('点档位回调分钟数', (tester) async {
    int? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DurationChips(
            selectedMinutes: null,
            onChanged: (value) => captured = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('45 分钟'));
    expect(captured, 45);
  });

  testWidgets('领域 6 枚且可单选', (tester) async {
    expect(DomainChips.domains.length, 6);
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DomainChips(
            selectedDomain: '',
            onChanged: (value) => captured = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('健康'));
    expect(captured, '健康');
  });
}