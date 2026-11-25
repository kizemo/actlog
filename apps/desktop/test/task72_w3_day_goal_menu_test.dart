// apps/desktop/test/task72_w3_day_goal_menu_test.dart
//
// Task 72 / B7 需求 4 第二、三条通道：日格右键勾选添加 + 从右栏拖进格子。
//
// 盯四件事：
//   1. 右键菜单新增第 4 组「未完成周目标」，既有「手填 / 待办 / 习惯」三组不回归；
//   2. 勾选浮层未勾选时确认键禁用；勾两条 ⇒ 两条都进当天计划（同一段起止）；
//   3. 重复勾选同两条 ⇒ 计划行数不变（幂等，与点击通道共用同一判据）；
//   4. 拖拽 payload `goal://<goalId>` 能被日格 `DragTarget` 接住并落一条。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';

import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/week_goal_rail_panel.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';
const String _selected = '2026-11-09';

const ValueKey<String> _kGrid = ValueKey<String>('day-grid');
const ValueKey<String> _kMenuManual = ValueKey<String>('slot-menu-manual');
const ValueKey<String> _kMenuGoals = ValueKey<String>('slot-menu-goals');
const ValueKey<String> _kRangeConfirm = ValueKey<String>('slot-range-confirm');
const ValueKey<String> _kPickConfirm = ValueKey<String>('week-goal-pick-confirm');
const ValueKey<String> _kTitleField = ValueKey<String>('slot-title-field');
const ValueKey<String> _kTitleConfirm = ValueKey<String>('slot-title-confirm');

final class _Harness {
  _Harness._(this.container, this.repos, this.goals);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final GoalStore goals;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(db, deviceId: 'w3-menu');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _selected),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos, GoalStore(repos));
  }

  /// 网格 + 右栏「未完成周目标」面板（拖拽源必须真的挂在树上）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      l10nScope(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: DayGrid(date: _selected)),
                  const SizedBox(
                    width: 240,
                    child: WeekGoalRailPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 弹层路由切换：先起一帧，再给转场 250ms。
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Offset _gridPointFor(WidgetTester tester, int minute) {
  final Rect grid = tester.getRect(find.byKey(_kGrid));
  final double dy = (minute - kGridStartHour * 60) / 60 * kHourRowHeight;
  return Offset(grid.left + grid.width / 2, grid.top + dy + 1);
}

Future<void> _rightClick(WidgetTester tester, Offset point) async {
  final TestGesture gesture = await tester.startGesture(
    point,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pump();
}

/// 右键 → 选「未完成周目标」→ 确认起止 ⇒ 勾选浮层已弹出。
Future<void> _openGoalPicker(WidgetTester tester, {int minute = 600}) async {
  await _rightClick(tester, _gridPointFor(tester, minute));
  await _pumpDialog(tester);
  expect(find.byKey(_kMenuGoals), findsOneWidget, reason: '右键菜单缺「未完成周目标」组');
  await tester.tap(find.byKey(_kMenuGoals));
  await _pumpDialog(tester);
  expect(find.byKey(_kRangeConfirm), findsOneWidget, reason: '选组后应先定起止');
  await tester.tap(find.byKey(_kRangeConfirm));
  await _pumpDialog(tester);
  expect(find.byKey(_kPickConfirm), findsOneWidget, reason: '定完起止应弹勾选浮层');
}

Map<String, PlanItemData> _byTitle(List<PlanItemData> rows) => <String, PlanItemData>{
  for (final PlanItemData row in rows) row.title: row,
};

void main() {
  testWidgets('B7/W3：右键菜单有第 4 组周目标，既有手填组仍在；勾两条落两条', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String idA = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '周目标甲',
    );
    final String idB = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '周目标乙',
    );

    await h.mount(tester);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 600));
    await _pumpDialog(tester);
    expect(find.byKey(_kMenuManual), findsOneWidget, reason: '既有「手填」组不许消失');
    expect(find.byKey(_kMenuGoals), findsOneWidget);

    await tester.tap(find.byKey(_kMenuGoals));
    await _pumpDialog(tester);
    await tester.tap(find.byKey(_kRangeConfirm));
    await _pumpDialog(tester);

    // 未勾选时确认键禁用：空选不许默默关窗。
    expect(find.byKey(_kPickConfirm), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(_kPickConfirm)).onPressed,
      isNull,
      reason: '一条都没勾时确认键必须禁用',
    );

    await tester.tap(find.byKey(ValueKey<String>('week-goal-pick-$idA')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey<String>('week-goal-pick-$idB')));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byKey(_kPickConfirm)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(_kPickConfirm));
    await _settle(tester);

    final List<PlanItemData> rows = await h.repos.planItem.listByDate(_selected);
    expect(rows, hasLength(2), reason: '勾两条就该落两条计划行');
    final Map<String, PlanItemData> byTitle = _byTitle(rows);
    expect(byTitle.keys.toSet(), <String>{'周目标甲', '周目标乙'});
    // 两条共用同一次起止选择。
    expect(byTitle['周目标甲']!.plannedStart, byTitle['周目标乙']!.plannedStart);
    expect(byTitle['周目标甲']!.plannedEnd, byTitle['周目标乙']!.plannedEnd);
    expect(byTitle['周目标甲']!.status, 'pending');

    for (final String id in <String>[idA, idB]) {
      final List<GoalLinkRow> links = await h.goals.listLinks(id);
      expect(
        links.where((GoalLinkRow l) => l.targetType == GoalTargetType.planItem),
        hasLength(1),
        reason: '每条周目标都应留下一条 plan_item 关联',
      );
    }

    await _flushTimers(tester);
  });

  testWidgets('B7/W3：重复勾选同两条 ⇒ 计划行数不变（幂等）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String idA = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '周目标甲',
    );

    await h.mount(tester);
    await _settle(tester);

    await _openGoalPicker(tester);
    await tester.tap(find.byKey(ValueKey<String>('week-goal-pick-$idA')));
    await tester.pump();
    await tester.tap(find.byKey(_kPickConfirm));
    await _settle(tester);
    expect(await h.repos.planItem.listByDate(_selected), hasLength(1));

    // 同一天再来一次：已经有一条活着的关联 ⇒ 一行都不写。
    await _openGoalPicker(tester);
    await tester.tap(find.byKey(ValueKey<String>('week-goal-pick-$idA')));
    await tester.pump();
    await tester.tap(find.byKey(_kPickConfirm));
    await _settle(tester);

    expect(await h.repos.planItem.listByDate(_selected), hasLength(1));
    expect(await h.goals.listLinks(idA), hasLength(1));

    await _flushTimers(tester);
  });

  testWidgets('B7/W3：从右栏把周目标拖进格子 ⇒ 定起止后落一条', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '拖进来的周目标',
    );

    await h.mount(tester);
    await _settle(tester);

    final Offset from = tester.getCenter(
      find.byKey(ValueKey<String>('week-goal-$goalId')),
    );
    final Offset to = _gridPointFor(tester, 720);
    final TestGesture gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(Offset.lerp(from, to, 0.4)!);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(Offset.lerp(from, to, 0.8)!);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await _pumpDialog(tester);

    expect(find.byKey(_kRangeConfirm), findsOneWidget, reason: '拖入也要先定起止');
    await tester.tap(find.byKey(_kRangeConfirm));
    await _settle(tester);

    final List<PlanItemData> rows = await h.repos.planItem.listByDate(_selected);
    expect(rows, hasLength(1));
    expect(rows.single.title, '拖进来的周目标');
    final List<GoalLinkRow> links = await h.goals.listLinks(goalId);
    expect(
      links.where((GoalLinkRow l) => l.targetType == GoalTargetType.planItem),
      hasLength(1),
    );

    await _flushTimers(tester);
  });

  testWidgets('B7/W3：既有「手填」通道不回归（选组 → 起止 → 标题 → 落库）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 780));
    await _pumpDialog(tester);
    await tester.tap(find.byKey(_kMenuManual));
    await _pumpDialog(tester);
    await tester.tap(find.byKey(_kRangeConfirm));
    await _pumpDialog(tester);
    expect(find.byKey(_kTitleField), findsOneWidget);
    await tester.enterText(find.byKey(_kTitleField), '手写一条');
    await tester.tap(find.byKey(_kTitleConfirm));
    await _settle(tester);

    final List<PlanItemData> rows = await h.repos.planItem.listByDate(_selected);
    expect(rows, hasLength(1));
    expect(rows.single.title, '手写一条');

    await _flushTimers(tester);
  });
}