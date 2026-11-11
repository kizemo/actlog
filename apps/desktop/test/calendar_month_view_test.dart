// apps/desktop/test/calendar_month_view_test.dart
import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/calendar_month_view.dart';

void main() {
  testWidgets('月历渲染 42 格并按形状显示徽标', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: <CalendarDaySummary>[
              CalendarDaySummary(
                date: '2026-11-07',
                planDone: 2,
                planTotal: 3,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('2026-11'), findsOneWidget);
    expect(find.text('●'), findsOneWidget);
    // 补白格也会渲染日号（12-07），所以必须按 key 定位，否则 '7' 会命中 2 个。
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-11-07')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
    // 日号不补零：'07' 不应出现。
    expect(find.text('07'), findsNothing);
  });

  testWidgets('网格恒为 42 格', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: <CalendarDaySummary>[],
          ),
        ),
      ),
    );
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('month-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 42);
  });

  testWidgets('点某天回调该天日期', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: const <CalendarDaySummary>[],
            onPickDay: (date) => picked = date,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('day-2026-11-07')));
    await tester.pump();
    expect(picked, '2026-11-07');
  });

  testWidgets('今天描边用墨色 2px', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: <CalendarDaySummary>[],
            today: '2026-11-07',
          ),
        ),
      ),
    );
    final cell = find.byKey(const ValueKey('day-2026-11-07'));
    expect(cell, findsOneWidget);
    final box = tester.widget<Container>(
      find.descendant(of: cell, matching: find.byType(Container)).first,
    );
    final border = (box.decoration! as BoxDecoration).border!;
    expect(border.top.color, AppTokens.ink);
    expect(border.top.width, 2);
  });
}