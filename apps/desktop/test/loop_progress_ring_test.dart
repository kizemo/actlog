// apps/desktop/test/loop_progress_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/loop_progress_ring.dart';
import 'package:core_data/core_data.dart';

void main() {
  testWidgets('四个数字全部可点并回调对应段', (tester) async {
    final jumped = <DayStatsSegment>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoopProgressRing(
            stats: const DayStats(
              planTotal: 8,
              planDone: 6,
              backfilled: 4,
              reviewDone: false,
              moodDone: false,
            ),
            onJump: jumped.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('6/8'), findsOneWidget);
    expect(find.text('4/6'), findsOneWidget);
    await tester.tap(find.text('复盘'));
    expect(jumped, contains(DayStatsSegment.review));
  });

  testWidgets('x=0 时回填显示 — 而不是 100%', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoopProgressRing(
            stats: DayStats(
              planTotal: 0,
              planDone: 0,
              backfilled: 0,
              reviewDone: true,
              moodDone: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });
}