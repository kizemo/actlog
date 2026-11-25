// apps/desktop/test/task72_w3_week_goal_rail_panel_test.dart
//
// Task 72 / B7 需求 4 第一条通道：今日右栏第 5 面板「未完成周目标」。
//
// 盯四件事：
//   1. 空态不造假：没有未完成周目标时只出提示 + 空态，不出任何可拖条目；
//   2. 只列**未完成周**目标：已完成（`status == done`）与非周粒度（`daily`）都不出现；
//   3. 拖拽 payload 逐字 `goal://<goalId>`（日格 `DragTarget` 靠它分流）；
//   4. 点击即加入当天计划，且**同一天重复点只落一条**（幂等）；
//      落位接在当日最后一条计划之后的下一个 30 分钟整点。
//
// 全部走真库 + 真 provider（不 mock）：幂等判据是「该目标的活 `goal_link`
// （`target_type='plan_item'`）∩ 该日未被软删的 `plan_item` id」非空，
// 只有真仓储才能验证它。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/widgets/week_goal_rail_panel.dart';

import 'l10n_harness.dart';

/// 固定「今天」与选中日：点击通道读 `selectedDateProvider` 落计划。
const String _today = '2026-11-09';
const String _selected = '2026-11-09';

const ValueKey<String> _kHint = ValueKey<String>('week-goal-add-hint');
const ValueKey<String> _kEmpty = ValueKey<String>('week-goal-empty');

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos, this.goals);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final GoalStore goals;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(db, deviceId: 'w3-rail');
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

  /// 只挂面板本体（宽 260，与右轨同宽），不挂整壳。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      l10nScope(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 260, child: WeekGoalRailPanel()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（`weekOpenGoalsProvider` 是 `FutureProvider`）。
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
}

void main() {
  final AppLocalizations zh = AppLocalizations.zh;

  testWidgets('B7/W3：没有未完成周目标时只有提示 + 空态，没有可拖条目', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kHint), findsOneWidget);
    expect(find.text(zh.goalsUpstreamAddHint), findsOneWidget);
    expect(find.byKey(_kEmpty), findsOneWidget);
    expect(find.text(zh.goalsUpstreamEmpty), findsOneWidget);
    expect(find.byType(Draggable<String>), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B7/W3：只列未完成**周**目标，已完成与非周粒度都不出现', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String openId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '把周报告写完',
    );
    await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '上周已经收尾的事',
      status: GoalStatus.done,
    );
    await h.goals.createGoal(kind: GoalKind.monthly, title: '月目标不该出现在这里');

    await h.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kEmpty), findsNothing);
    expect(find.text('把周报告写完'), findsOneWidget);
    expect(find.text('上周已经收尾的事'), findsNothing);
    expect(find.text('日目标不该出现在这里'), findsNothing);

    // 第二条通道的前提：拖拽 payload 逐字 `goal://<goalId>`。
    final Draggable<String> draggable = tester.widget<Draggable<String>>(
      find.ancestor(
        of: find.byKey(ValueKey<String>('week-goal-$openId')),
        matching: find.byType(Draggable<String>),
      ),
    );
    expect(draggable.data, 'goal://$openId');

    await _flushTimers(tester);
  });

  testWidgets('B7/W3：点击即加入当天计划，再点一次只落一条（幂等）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '复盘 B7',
      note: '把三条通道都跑一遍',
    );

    await h.mount(tester);
    await _settle(tester);

    final ValueKey<String> tile = ValueKey<String>('week-goal-$goalId');
    await tester.tap(find.byKey(tile));
    await _settle(tester);

    final List<PlanItemData> rows = await h.repos.planItem.listByDate(_selected);
    expect(rows, hasLength(1), reason: '点一次只落一条计划行');
    final PlanItemData row = rows.single;
    expect(row.title, '复盘 B7');
    expect(row.detail, '把三条通道都跑一遍');
    expect(row.sourceType, 'manual');
    // 计划行恒 `pending`：从目标加进来的是「还没做的安排」，不是回填。
    expect(row.status, 'pending');
    expect(row.plannedStart, kGridStartHour * 60);
    expect(row.plannedEnd, kGridStartHour * 60 + 30);

    final List<GoalLinkRow> links = await h.goals.listLinks(goalId);
    final List<GoalLinkRow> planLinks = links
        .where((GoalLinkRow l) => l.targetType == GoalTargetType.planItem)
        .toList(growable: false);
    expect(planLinks, hasLength(1), reason: '目标 ↔ 计划项走 goal_link 一条');
    expect(planLinks.single.targetId, row.id);

    // 第二次点击：同一天已有活着的关联 ⇒ 一行都不写。
    await tester.tap(find.byKey(tile));
    await _settle(tester);
    expect(await h.repos.planItem.listByDate(_selected), hasLength(1));
    expect(await h.goals.listLinks(goalId), hasLength(1));

    await _flushTimers(tester);
  });

  testWidgets('B7/W3：落位接在当日最后一条计划之后的下一个 30 分钟整点', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    // 09:00–10:15 已经有一条安排 ⇒ 新条目应落在 10:30。
    await TimelineStore(h.repos).createManual(
      date: _selected,
      title: '既有安排',
      startMinute: 9 * 60,
      endMinute: 10 * 60 + 15,
    );
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '接着往下排',
    );

    await h.mount(tester);
    await _settle(tester);
    await tester.tap(find.byKey(ValueKey<String>('week-goal-$goalId')));
    await _settle(tester);

    final List<PlanItemData> rows = await h.repos.planItem.listByDate(_selected);
    expect(rows, hasLength(2));
    final PlanItemData added = rows.firstWhere(
      (PlanItemData r) => r.title == '接着往下排',
    );
    expect(added.plannedStart, 10 * 60 + 30);
    expect(added.plannedEnd, 11 * 60);

    await _flushTimers(tester);
  });
}