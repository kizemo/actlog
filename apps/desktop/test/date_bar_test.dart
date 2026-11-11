import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/date_bar.dart';

void main() {
  testWidgets('显示日期标题；过去显示补录模式、未来显示预排', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('scope-today'),
        overrides: [todayProvider.overrideWithValue('2026-11-07')],
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    expect(find.text('2026-11-07 周六'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('scope-past'),
        overrides: [
          todayProvider.overrideWithValue('2026-11-07'),
          selectedDateProvider.overrideWith((ref) => '2026-11-05'),
        ],
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    expect(find.text('补录模式'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('scope-future'),
        overrides: [
          todayProvider.overrideWithValue('2026-11-07'),
          selectedDateProvider.overrideWith((ref) => '2026-11-09'),
        ],
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    expect(find.text('预排'), findsOneWidget);
  });

  testWidgets('左右箭头切日，今天按钮回到今天', (tester) async {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue('2026-11-07')],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('date-bar-next')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-08');
    await tester.tap(find.byKey(const ValueKey('date-bar-today')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-07');
  });
}