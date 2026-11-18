// apps/desktop/test/calendar_month_view_test.dart
import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/calendar_month_view.dart';

/// 取某一格最外层那个 `Container` 的装饰（边框 + 底色都在它身上）。
///
/// 坑 51：desktop 测试不预载字体，一律断言结构与 token 值，不比字形/像素。
Container _cellBox(WidgetTester tester, String date) {
  return tester.widget<Container>(
    find
        .descendant(
          of: find.byKey(ValueKey('day-$date')),
          matching: find.byType(Container),
        )
        .first,
  );
}

Text _cellNumber(WidgetTester tester, String date, String number) {
  return tester.widget<Text>(
    find.descendant(
      of: find.byKey(ValueKey('day-$date')),
      matching: find.text(number),
    ),
  );
}

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

  // 需求 10 · 今天：强调通道必须可判别（2px 墨边 + 「今」角标 + w600）。
  // 2026-11-05 是周四（工作日），用来把「今天」与「周末」两条通道拆开验。
  testWidgets('今天有三条可判别的强调通道，且只有今天有', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: <CalendarDaySummary>[],
            today: '2026-11-05',
          ),
        ),
      ),
    );

    final cell = find.byKey(const ValueKey('day-2026-11-05'));
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(const ValueKey('calendar-cell-today')),
      ),
      findsOneWidget,
      reason: '今天必须带 calendar-cell-today 这个稳定 key',
    );

    final decoration = _cellBox(tester, '2026-11-05').decoration!;
    final border = (decoration as BoxDecoration).border!.top;
    expect(border.color, AppTokens.ink, reason: '今天描边用墨色');
    expect(border.width, 2, reason: '今天描边加粗到 2px');
    expect(decoration.color, isNull, reason: '工作日且无完成度时不应有底色');

    expect(
      find.descendant(of: cell, matching: find.text('今')),
      findsOneWidget,
      reason: '今天要有「今」角标',
    );
    expect(
      _cellNumber(tester, '2026-11-05', '5').style?.fontWeight,
      FontWeight.w600,
      reason: '今天日号加重',
    );

    // 非今天的工作日：无强调 key、1px 弱边、常规字重 —— 强调才「可判别」。
    final other = find.byKey(const ValueKey('day-2026-11-04'));
    expect(
      find.descendant(
        of: other,
        matching: find.byKey(const ValueKey('calendar-cell-today')),
      ),
      findsNothing,
    );
    final otherBorder = (_cellBox(tester, '2026-11-04').decoration! as BoxDecoration)
        .border!
        .top;
    expect(otherBorder.width, 1);
    expect(otherBorder.color, AppTokens.hairStrong);
    expect(_cellNumber(tester, '2026-11-04', '4').style?.fontWeight, isNot(FontWeight.w600));
    expect(find.descendant(of: other, matching: find.text('今')), findsNothing);
  });

  // 需求 10 · 周末：弱化通道必须可判别（sunken 静态底 + meta 字色 + 1px 弱边）。
  // 2026-11-01 是周日；2026-11-02 是周一，作对照。
  testWidgets('周末有三条可判别的弱化通道，且只有周末有', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: <CalendarDaySummary>[],
            today: '2026-11-10',
          ),
        ),
      ),
    );

    final weekend = find.byKey(const ValueKey('day-2026-11-01'));
    expect(
      find.descendant(
        of: weekend,
        matching: find.byKey(const ValueKey('calendar-cell-weekend')),
      ),
      findsOneWidget,
      reason: '周末必须带 calendar-cell-weekend 这个稳定 key',
    );

    final decoration =
        _cellBox(tester, '2026-11-01').decoration! as BoxDecoration;
    expect(decoration.color, AppTokens.sunken, reason: '周末用下沉底弱化');
    expect(decoration.border!.top.width, 1, reason: '周末不加粗（强调只归今天）');
    expect(decoration.border!.top.color, AppTokens.hairStrong);
    expect(
      _cellNumber(tester, '2026-11-01', '1').style?.color,
      AppTokens.meta,
      reason: '周末日号降权到 meta',
    );

    // 对照：周一（11-02，非今天非周末）不弱化 —— 无底色、字色回墨色。
    final weekday = find.byKey(const ValueKey('day-2026-11-02'));
    expect(
      find.descendant(
        of: weekday,
        matching: find.byKey(const ValueKey('calendar-cell-weekend')),
      ),
      findsNothing,
    );
    final weekdayDecoration =
        _cellBox(tester, '2026-11-02').decoration! as BoxDecoration;
    expect(weekdayDecoration.color, isNull);
    expect(
      _cellNumber(tester, '2026-11-02', '2').style?.color,
      AppTokens.ink,
    );
  });

  // 需求 10 · 组合场景：今天恰逢周末（2026-11-07 是周六）⇒ 两个 key 同时存在，
  // 且强调通道压住弱化通道：描边仍 2px 墨色、日号仍是墨色而非 meta。
  testWidgets('今天恰逢周末时两条通道同时成立且强调不被弱化吞掉', (tester) async {
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
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(const ValueKey('calendar-cell-today')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(const ValueKey('calendar-cell-weekend')),
      ),
      findsOneWidget,
      reason: '今天与周末是两条独立通道，key 必须能同时命中',
    );

    final decoration =
        _cellBox(tester, '2026-11-07').decoration! as BoxDecoration;
    expect(decoration.border!.top.width, 2, reason: '强调优先：今天仍 2px');
    expect(decoration.border!.top.color, AppTokens.ink);
    expect(decoration.color, AppTokens.sunken, reason: '弱化底仍然存在');
    expect(
      _cellNumber(tester, '2026-11-07', '7').style?.color,
      AppTokens.ink,
      reason: '今天日号不得被周末弱化降成 meta',
    );
    expect(
      _cellNumber(tester, '2026-11-07', '7').style?.fontWeight,
      FontWeight.w600,
    );
    expect(find.descendant(of: cell, matching: find.text('今')), findsOneWidget);
  });
}