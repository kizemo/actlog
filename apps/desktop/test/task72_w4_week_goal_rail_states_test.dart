// apps/desktop/test/task72_w4_week_goal_rail_states_test.dart
//
// Task 72 / B7-W4 修 verifier 复核 MAJOR-1 的回归锁 → B8-W3 保留三态、撤掉写入口。
//
// 盯四件事：
//   1. loading 态只出加载占位（`week-goal-loading`），绝不出空态文案；
//   2. error 态出 `week-goal-error`，且**错误原文在页面上可见**，绝不出空态文案；
//   3. 真空态仍是 `week-goal-empty`（回归锁，防止为了修 1/2 把真空态一起改坏）；
//      三态里「点击或拖拽添加」的提示与一切拖拽源都已撤（B8-W3）。
//   4. 今日页不再产出 `goal://` 拖拽源，但协议常量仍单一来源
//      （`goal_upstream_panel.dart` 的 `goalDragPayloadFor` /
//      `goalIdFromDragPayload` 未删：月页 / 周页的「添加到当前周期」链路仍在用）。
//
// 与 `task72_w3_week_goal_rail_panel_test.dart` 的分工：那份盯**只读语义**
// （零写入 / 结构守卫），本份只盯**三态呈现**与协议常量的去向。两份都不 mock
// 仓储 —— loading / error 两态用 provider 覆写造出（真实 drift 读失败不可控），
// 真空态与协议常量走真库真 provider。
import 'dart:async';

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
import 'package:actlog/src/widgets/goal_upstream_panel.dart';
import 'package:actlog/src/widgets/week_goal_rail_panel.dart';

import 'l10n_harness.dart';

/// 固定「今天」与选中日（与 W3 同一组常量）。
const String _today = '2026-11-09';
const String _selected = '2026-11-09';

const ValueKey<String> _kHint = ValueKey<String>('week-goal-add-hint');
const ValueKey<String> _kEmpty = ValueKey<String>('week-goal-empty');
const ValueKey<String> _kLoading = ValueKey<String>('week-goal-loading');
const ValueKey<String> _kError = ValueKey<String>('week-goal-error');

/// 内存真库 + 真仓储 + 固定今天 / 选中日，可叠加 provider 覆写。
final class _Harness {
  _Harness._(this.container, this.repos, this.goals);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final GoalStore goals;

  static _Harness create({List<Override> extra = const <Override>[]}) {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(db, deviceId: 'w4-states');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _selected),
        ...extra,
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

  testWidgets('B7/W4：加载中只出加载占位，不伪装成「暂无未完成目标」', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    // 永不完成的 future ⇒ AsyncValue 恒为 loading。
    final Completer<List<GoalRow>> pending = Completer<List<GoalRow>>();
    final _Harness h = _Harness.create(
      extra: <Override>[
        weekOpenGoalsProvider.overrideWith((ref) => pending.future),
      ],
    );
    await h.mount(tester);
    await tester.pump();

    expect(find.byKey(_kLoading), findsOneWidget);
    expect(find.byKey(_kEmpty), findsNothing);
    expect(find.byKey(_kError), findsNothing);
    // MAJOR-1 的判别点：空态文案一个都不许出现。
    expect(find.text(zh.goalsUpstreamEmpty), findsNothing);
    expect(find.byType(Draggable<String>), findsNothing);
    // B8/W3 的判别点：写入口撤了，加载态也不许再挂那条添加提示。
    expect(find.byKey(_kHint), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B7/W4：读库失败时出错误态且错误原文可见，不伪装成空态', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      extra: <Override>[
        weekOpenGoalsProvider.overrideWith(
          (ref) => Future<List<GoalRow>>.error(StateError('drift-read-failed')),
        ),
      ],
    );
    await h.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kError), findsOneWidget);
    expect(find.byKey(_kEmpty), findsNothing);
    expect(find.byKey(_kLoading), findsNothing);
    expect(find.text(zh.goalsUpstreamEmpty), findsNothing);
    // 错误对象没有被丢弃：原文在页面上可读。
    expect(find.textContaining('drift-read-failed'), findsOneWidget);
    expect(find.byType(Draggable<String>), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B7/W4：真空态仍是 week-goal-empty（回归锁）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kEmpty), findsOneWidget);
    expect(find.text(zh.goalsUpstreamEmpty), findsOneWidget);
    expect(find.byKey(_kLoading), findsNothing);
    expect(find.byKey(_kError), findsNothing);
    expect(find.byKey(_kHint), findsNothing);
    expect(find.byType(Draggable<String>), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：今日页不再产出 goal:// 拖拽源，协议常量仍单一来源', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '协议同源',
    );

    await h.mount(tester);
    await _settle(tester);

    // 条目仍列出来 —— 撤的是写入口，不是展示。
    expect(find.byKey(ValueKey<String>('week-goal-$goalId')), findsOneWidget);
    // 但今日页再没有 `goal://` 的产出方（旧 W4 断言的是 payload 内容）。
    expect(
      find.descendant(
        of: find.byType(WeekGoalRailPanel),
        matching: find.byType(Draggable<String>),
      ),
      findsNothing,
    );
    expect(find.byType(Draggable<String>), findsNothing);

    // 协议本身没被删，且仍只在 `goal_upstream_panel.dart` 一处生成 ——
    // 月页 / 周页的「添加到当前周期」链路（U3 未裁）继续用它。
    expect(goalDragPayloadFor(goalId), 'goal://$goalId');
    expect(goalIdFromDragPayload(goalDragPayloadFor(goalId)), goalId);

    await _flushTimers(tester);
  });
}