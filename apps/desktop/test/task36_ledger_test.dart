// apps/desktop/test/task36_ledger_test.dart
//
// Task 36 / T2 视觉批次（方向 A「今日账页」）的结构断言（真库 + 真 provider）。
//
// 只钉「结构」，不钉像素：刻度尺存在且 06/12/18 三档整点齐备（起点用 8×1 短线，
// 不再写「晨/午/晚」文字）、行按 `planned_start` 升序、
// 未分级行不画标记但留一处 meta、右轨「优先级分布」标题存在且只读。
//
// 为什么刻意让**插入顺序与时间顺序相反**（先写 20:00、再写 09:00）：
// 若行序只是插入序的巧合，本文件的升序断言会假绿。反着写才有判别力。
//
// 为什么用 `getTopLeft(...).dy` 表达「按 `planned_start` 升序」：网格右侧的
// 条目层是 `Positioned(top: 由 startMinute 换算)`，纵坐标就是「真实时刻」的
// 唯一可见投影；widget 树里的兄弟顺序不是可断言的事实（`Stack` 顺序不影响
// 布局），拿它断言反而测不到东西。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/priority_hover_bubble.dart';
import 'package:actlog/src/widgets/priority_marks.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/todo_rail_panel.dart';
import 'package:actlog/src/widgets/timeline/unscheduled_strip.dart';

const String _today = '2026-11-09';

/// 已排期 + 已分级（Q1）：20:00–21:00，**先**写入。
const String _lateTitle = '晚段一件（已分级 Q1）';

/// 已排期 + 未分级：09:00–10:00，**后**写入 ⇒ 行序不可能是插入序。
const String _earlyTitle = '早段一件（未分级）';

/// 未排期 + 未分级：走 `UnscheduledStrip`。
const String _looseTitle = '未排期一件（未分级）';

const ValueKey<String> _kRuler = ValueKey<String>('day-grid-ruler');
const ValueKey<String> _kStrip = ValueKey<String>('unscheduled-strip');
const ValueKey<String> _kDistribution =
    ValueKey<String>('rail-priority-distribution');

ValueKey<String> _entryKey(String id) => ValueKey<String>('day-grid-entry-$id');

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  /// 两条已排期行的 id（写完才有，供按 key 定位）。
  String lateId = '';
  String earlyId = '';

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task36-ledger-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 插入顺序 = 20:00 → 09:00 → 未排期，与时间顺序相反。
  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      lateId = await repos.planItem.createScheduled(
        date: _today,
        title: _lateTitle,
        plannedStart: 20 * 60,
        plannedEnd: 21 * 60,
      );
      await repos.planItem.setQuadrant(lateId, Quadrant.q1);
      earlyId = await repos.planItem.createScheduled(
        date: _today,
        title: _earlyTitle,
        plannedStart: 9 * 60,
        plannedEnd: 10 * 60,
      );
      await repos.planItem.create(date: _today, title: _looseTitle);
    });
  }

  /// 网格 + 未排期带 + 右轨待办面板（「优先级分布」挂在后者内部）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const DayGrid(date: _today),
                      const UnscheduledStrip(),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[TodoRailPanel()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 撑高测试面：网格 792 + 未排期带 + 右轨，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

void main() {
  testWidgets('① 全天刻度尺在，06:00 / 12:00 / 18:00 三档整点齐备、三处起点用 8×1 短线',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kRuler), findsOneWidget, reason: '刻度尺必须存在');

    final Finder ruler = find.byKey(_kRuler);
    for (final String hour in <String>['06:00', '12:00', '18:00']) {
      expect(
        find.descendant(of: ruler, matching: find.text(hour)),
        findsOneWidget,
        reason: '$hour 整点数字必须在刻度尺里',
      );
    }
    // ---- Task 39 · W1（指令 4）改写了这一段 ----
    // 改前基线（本文件 2026-11-18 之前，原 :181-187）：
    //   for (final String anchor in <String>['晨', '午', '晚']) {
    //     expect(
    //       find.descendant(of: ruler, matching: find.text(anchor)),
    //       findsOneWidget,
    //       reason: '锚标 $anchor 必须与对应整点同行',
    //     );
    //   }
    // 现在同一条链路的要求反过来：三行「晨 / 午 / 晚」文字**必须不在**，
    // 三段起点改由 8×1 短横线标记（文字名称在段头「晚 · 复盘与心态」里已有）。
    // 只改断言、不删用例 —— 这个用例守的仍是「刻度尺三档齐备」。
    for (final String anchor in <String>['晨', '午', '晚']) {
      expect(
        find.descendant(of: ruler, matching: find.text(anchor)),
        findsNothing,
        reason: '「$anchor」文字标记已移除（Task 39 指令 4），不是被藏起来',
      );
    }
    for (final int hour in <int>[6, 12, 18]) {
      final Finder mark =
          find.byKey(ValueKey<String>('day-grid-segment-mark-$hour'));
      expect(
        mark,
        findsOneWidget,
        reason: '起段短线必须在刻度尺里（文字去掉了，标记不能跟着没）',
      );
      expect(
        tester.getSize(mark),
        const Size(8, 1),
        reason: '起段标记是 8px×1px 短横线',
      );
      final double dyMark = tester.getCenter(mark).dy;
      final double dyHour = tester
          .getCenter(find.byKey(ValueKey<String>('day-grid-hour-$hour')))
          .dy;
      expect(
        (dyMark - dyHour).abs(),
        lessThanOrEqualTo(2),
        reason: '$hour 点：短线中心与整点数字中心必须在同一条水平中轴（|Δy| ≤ 2px）',
      );
    }

    await _flushTimers(tester);
  });

  testWidgets('② 行按 planned_start 升序，未分级行不画标记但留一处 meta',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mount(tester);
    await _settle(tester);

    final Finder late = find.byKey(_entryKey(harness.lateId));
    final Finder early = find.byKey(_entryKey(harness.earlyId));
    expect(late, findsOneWidget);
    expect(early, findsOneWidget);

    // 插入序是 20:00 → 09:00；屏幕顺序必须是 09:00 在上。
    expect(
      tester.getTopLeft(early).dy,
      lessThan(tester.getTopLeft(late).dy),
      reason: '行按 planned_start 升序，不是按插入顺序',
    );

    // 已分级行：气泡（四维标记的 T1 形态）在位，且不出现「未分级」。
    expect(
      find.descendant(of: late, matching: find.byType(PriorityHoverBubble)),
      findsOneWidget,
      reason: '已分级行必须有四维标记',
    );
    expect(
      find.descendant(of: late, matching: find.text('未分级')),
      findsNothing,
    );

    // 未分级行：两个标记组件都不渲染（不是渲染成空占位），只留一处 meta。
    // 这两条 `findsNothing` 之所以有意义，是因为同一用例里已分级行断言了
    // `findsOneWidget` —— 组件本身没被移除。
    expect(
      find.descendant(of: early, matching: find.byType(PriorityHoverBubble)),
      findsNothing,
      reason: '未分级不画标记',
    );
    expect(
      find.descendant(of: early, matching: find.byType(PriorityMarks)),
      findsNothing,
      reason: '未分级也不回落到旧标记组件',
    );
    expect(
      find.descendant(of: early, matching: find.text('未分级')),
      findsOneWidget,
      reason: '未分级必须留一处 meta，否则与「分级没渲染出来」不可分',
    );

    await _flushTimers(tester);
  });

  testWidgets('③ 右轨「优先级分布」：标题在、Q1 计数来自计划条目、整块只读',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mount(tester);
    await _settle(tester);

    final Finder block = find.byKey(_kDistribution);
    expect(block, findsOneWidget, reason: '右轨必须有「优先级分布」块');
    expect(
      find.descendant(of: block, matching: find.text('优先级分布')),
      findsOneWidget,
    );

    // Q1 有一条（20:00 那条已分级），其余三格计数为 0 ⇒ 不渲染。
    expect(
      find.byKey(const ValueKey<String>('rail-quadrant-q1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('rail-quadrant-q2')),
      findsNothing,
      reason: '计数为 0 的格不渲染（对齐原型 .qcell:empty）',
    );

    // 只读：块里不许出现任何可改分级的写入口。
    expect(
      find.descendant(of: block, matching: find.byType(PriorityHoverBubble)),
      findsNothing,
      reason: '改分级只有气泡一个入口，右轨块不开第二处',
    );

    // 尾注：3 条计划、2 条未分级（1 条排期行 + 1 条未排期行）。
    expect(
      find.descendant(of: block, matching: find.text('3 条计划 · 未分级 ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: block, matching: find.text('2 条')),
      findsOneWidget,
    );

    await _flushTimers(tester);
  });

  testWidgets('④ 未排期带：未分级条目不画标记，只补一处 meta',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mount(tester);
    await _settle(tester);

    final Finder strip = find.byKey(_kStrip);
    expect(strip, findsOneWidget, reason: '有未排期条目就必须出现未排期带');
    expect(
      find.descendant(of: strip, matching: find.text(_looseTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: strip, matching: find.byType(PriorityHoverBubble)),
      findsNothing,
      reason: '未分级芯片不画标记',
    );
    expect(
      find.descendant(of: strip, matching: find.byType(PriorityMarks)),
      findsNothing,
      reason: '未分级芯片也不回落到旧标记组件',
    );
    expect(
      find.descendant(of: strip, matching: find.text('未分级')),
      findsOneWidget,
      reason: '与格子行同一规矩：零标记，但留一处 meta',
    );

    await _flushTimers(tester);
  });
}
