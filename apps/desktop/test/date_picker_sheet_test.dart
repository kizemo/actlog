// apps/desktop/test/date_picker_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/core_data.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/date_picker_sheet.dart';

void main() {
  testWidgets('快捷芯片能选出今天', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '2026-11-03',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  testWidgets('月历渲染 42 格，且能翻月', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DatePickerSheet(initial: '2026-11-07')),
      ),
    );
    expect(find.text('2026-11'), findsOneWidget);
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('month-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 42);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('2026-10'), findsOneWidget);
  });

  testWidgets('无期限芯片返回 null', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '2026-11-07',
                  allowNoDeadline: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('无期限'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(captured, isNull);
  });

  testWidgets('方向键移动选中日并用 Enter 确认', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '2026-11-07',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(captured, '2026-11-08');
  });

  testWidgets('今天描边 + 周末标红', (tester) async {
    final todayIso = today();
    final month = todayIso.substring(0, 7);
    final first = '$month-01';
    final second = '$month-02';
    final initial = first == todayIso ? second : first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DatePickerSheet(initial: initial)),
      ),
    );
    final todayCell = find.byKey(ValueKey('day-$todayIso'));
    expect(todayCell, findsOneWidget);
    final todayBox = tester.widget<Container>(
      find.descendant(of: todayCell, matching: find.byType(Container)).first,
    );
    final todayBorder = (todayBox.decoration! as BoxDecoration).border!;
    expect(todayBorder.top.color, AppTokens.ink);
    expect(todayBorder.top.width, 2);

    final grid = buildMonthGrid(month, today: todayIso, weekStart: 1);
    final weekend = grid.firstWhere((c) => c.isWeekend && c.inMonth);
    final weekendCell = find.byKey(ValueKey('day-${weekend.date}'));
    expect(weekendCell, findsOneWidget);
    final weekendText = tester.widget<Text>(
      find.descendant(of: weekendCell, matching: find.byType(Text)).first,
    );
    expect(weekendText.style!.color, AppTokens.accentInk);
  });

  testWidgets('本周内芯片返回本周最后一天', (tester) async {
    String? captured;
    final todayIso = today();
    final month = todayIso.substring(0, 7);
    final parsed = parseIsoDate(todayIso)!;
    final expected = shiftIsoDate(todayIso, (7 - parsed.weekday) % 7);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '$month-01',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本周内'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(captured, expected);
  });
}