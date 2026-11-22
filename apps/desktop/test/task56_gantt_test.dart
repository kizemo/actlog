// apps/desktop/test/task56_gantt_test.dart
//
// Task 56 · 甘特图：块必须落在**目标日**那一格，未排期的不画块。
//
// 断言口径是**相对几何**（两个块的 x 坐标之差 = 天数差 × 天宽），不写死绝对
// 像素 —— 绝对坐标会随标签列宽、字号缩放漂移，写死就是一台机器上成立的假绿。
//
// 覆盖：
//   G1：两个任务的块 x 坐标之差 = 它们目标日的天数差 × 天宽（块落在目标日）；
//   G2：项目横条的宽度 = 项目区间天数 × 天宽，起点 = 区间起始日那一格；
//   G3：目标日为空的任务**不画块**，项目行上出现「未排期 N 条」；
//   G4：一个可排期日期都没有 ⇒ 空态（不画假区间）；
//   G5：只知道一端 ⇒ 横条退化成该已知日的单日条（不臆造另一端）；
//   G6：可视区间的推导 —— 任务目标日比项目区间更远时，区间跟着任务走。
import 'package:actlog/src/widgets/gantt_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 天宽（测试里固定一个整数，断言才好算）。
const double _day = 30;

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('G1：任务块落在目标日那一格（x 之差 = 天数差 × 天宽）',
      (WidgetTester tester) async {
    const List<GanttProject> projects = <GanttProject>[
      GanttProject(
        id: 'p1',
        name: '甲',
        startDate: '2026-11-01',
        endDate: '2026-11-10',
        milestones: <GanttMilestone>[
          GanttMilestone(id: 'm1', title: '一', targetDate: '2026-11-03'),
          GanttMilestone(id: 'm2', title: '二', targetDate: '2026-11-08'),
          GanttMilestone(id: 'm3', title: '三', targetDate: null),
        ],
      ),
      GanttProject(
        id: 'p2',
        name: '乙',
        startDate: '2026-11-05',
        endDate: '2026-11-08',
        milestones: <GanttMilestone>[
          GanttMilestone(id: 'm4', title: '四', targetDate: '2026-11-07'),
        ],
      ),
    ];

    await tester.pumpWidget(_wrap(GanttChart(projects: projects, dayWidth: _day)));

    expect(find.byKey(GanttChart.blockKey('m1')), findsOneWidget);
    expect(find.byKey(GanttChart.blockKey('m4')), findsOneWidget);

    final Rect m1 = tester.getRect(find.byKey(GanttChart.blockKey('m1')));
    final Rect m4 = tester.getRect(find.byKey(GanttChart.blockKey('m4')));
    // m1 = 11-03（区间第 3 天，索引 2），m4 = 11-07（索引 6）⇒ 相差 4 天。
    expect(
      m4.left - m1.left,
      moreOrLessEquals(4 * _day, epsilon: 0.01),
      reason: '块必须落在目标日那一格',
    );
    // 同一项目（甲）的两个块在同一行；跨项目（甲 → 乙）正好差一个行高。
    final Rect m2 = tester.getRect(find.byKey(GanttChart.blockKey('m2')));
    expect(
      m2.top,
      moreOrLessEquals(m1.top, epsilon: 0.01),
      reason: '同一项目的块在同一行',
    );
    expect(
      m4.top - m1.top,
      moreOrLessEquals(GanttChart.rowHeight, epsilon: 0.01),
      reason: '第二个项目正好往下一行',
    );
  });

  testWidgets('G2：项目横条 = 项目区间（宽度 = 天数 × 天宽，起点对齐区间首日）',
      (WidgetTester tester) async {
    const List<GanttProject> projects = <GanttProject>[
      GanttProject(
        id: 'p1',
        name: '甲',
        startDate: '2026-11-01',
        endDate: '2026-11-10',
        milestones: <GanttMilestone>[],
      ),
      GanttProject(
        id: 'p2',
        name: '乙',
        startDate: '2026-11-05',
        endDate: '2026-11-08',
        milestones: <GanttMilestone>[],
      ),
    ];

    await tester.pumpWidget(_wrap(GanttChart(projects: projects, dayWidth: _day)));

    final Rect bar1 = tester.getRect(find.byKey(GanttChart.barKey('p1')));
    final Rect bar2 = tester.getRect(find.byKey(GanttChart.barKey('p2')));
    expect(
      bar1.width,
      moreOrLessEquals(10 * _day - 4, epsilon: 0.01),
      reason: '11-01..11-10 共 10 天',
    );
    expect(
      bar2.width,
      moreOrLessEquals(4 * _day - 4, epsilon: 0.01),
      reason: '11-05..11-08 共 4 天',
    );
    expect(
      bar2.left - bar1.left,
      moreOrLessEquals(4 * _day, epsilon: 0.01),
      reason: '乙的起点是区间里的第 5 天',
    );
  });

  testWidgets('G3：目标日为空 ⇒ 不画块，项目行上出现「未排期 N 条」',
      (WidgetTester tester) async {
    const List<GanttProject> projects = <GanttProject>[
      GanttProject(
        id: 'p1',
        name: '甲',
        startDate: '2026-11-01',
        endDate: '2026-11-10',
        milestones: <GanttMilestone>[
          GanttMilestone(id: 'm1', title: '一', targetDate: '2026-11-03'),
          GanttMilestone(id: 'm2', title: '二', targetDate: null),
          GanttMilestone(id: 'm3', title: '三', targetDate: null),
        ],
      ),
    ];

    await tester.pumpWidget(_wrap(GanttChart(projects: projects, dayWidth: _day)));

    expect(find.byKey(GanttChart.blockKey('m2')), findsNothing);
    expect(find.byKey(GanttChart.blockKey('m3')), findsNothing);
    expect(find.byKey(GanttChart.unscheduledKey('p1')), findsOneWidget);
    expect(find.text('未排期 2 条'), findsOneWidget);
  });

  testWidgets('G4：一个可排期日期都没有 ⇒ 空态（不画假区间）',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const GanttChart(
          projects: <GanttProject>[],
          emptyLabel: '没有可排期的日期',
        ),
      ),
    );

    expect(find.text('没有可排期的日期'), findsOneWidget);
    expect(find.byKey(GanttChart.barKey('p1')), findsNothing);
  });

  testWidgets('G5：只知道一端 ⇒ 横条退化成该已知日的单日条',
      (WidgetTester tester) async {
    const List<GanttProject> projects = <GanttProject>[
      GanttProject(
        id: 'p1',
        name: '甲',
        startDate: '2026-11-04',
        endDate: null,
        milestones: <GanttMilestone>[],
      ),
    ];

    await tester.pumpWidget(_wrap(GanttChart(projects: projects, dayWidth: _day)));

    final Rect bar = tester.getRect(find.byKey(GanttChart.barKey('p1')));
    expect(
      bar.width,
      moreOrLessEquals(_day - 4, epsilon: 0.01),
      reason: '只知道开始日 ⇒ 单日条，不许臆造另一端',
    );
  });

  test('G6：可视区间由「项目起止日 + 任务目标日」里最小 / 最大的日推出', () {
    const List<GanttProject> projects = <GanttProject>[
      GanttProject(
        id: 'p1',
        name: '甲',
        startDate: '2026-11-01',
        endDate: '2026-11-02',
        milestones: <GanttMilestone>[
          GanttMilestone(id: 'm1', title: '一', targetDate: '2026-11-09'),
        ],
      ),
    ];

    final ({DateTime from, DateTime to})? range =
        GanttChart.visibleRange(projects);
    expect(range, isNotNull);
    expect(GanttChart.formatDay(range!.from), '2026-11-01');
    expect(GanttChart.formatDay(range.to), '2026-11-09');
  });
}
