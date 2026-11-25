// apps/desktop/test/task72_w4_week_goal_rail_states_test.dart
//
// Task 72 / B7-W4：修 verifier 复核 MAJOR-1 —— 今日右栏「未完成周目标」面板
// 把 loading / 读库失败 都渲染成 `goalsUpstreamEmpty`（「暂无未完成目标」），
// 与真空态在界面上不可区分，且错误对象被丢弃。
//
// 盯四件事：
//   1. loading 态只出加载占位（`week-goal-loading`），绝不出空态文案；
//   2. error 态出 `week-goal-error`，且**错误原文在页面上可见**，绝不出空态文案；
//   3. 真空态仍是 `week-goal-empty`（回归锁，防止为了修 1/2 把真空态一起改坏）；
//   4. 拖拽 payload 仍逐字 `goal://<goalId>`，且与 `goalDragPayloadFor` 同源
//      （MINOR-1：协议常量单一来源，`week_goal_rail_panel.dart` 内不再手写字面量）。
//
// 与 `task72_w3_week_goal_rail_panel_test.dart` 的分工：那份盯**三条通道的写入
// 语义**（幂等 / 落位 / goal_link），本份只盯**三态呈现**与协议同源。两份都不 mock
// 仓储 —— loading / error 两态用 provider 覆写造出（真实 drift 读失败不可控），
// 真空态与 payload 走真库真 provider。
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
    // 提示行仍在（面板没有整体消失）。
    expect(find.byKey(_kHint), findsOneWidget);

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

    await _flushTimers(tester);
  });

  testWidgets('B7/W4：拖拽 payload 与 goalDragPayloadFor 同源（协议单一来源）', (
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

    final Draggable<String> draggable = tester.widget<Draggable<String>>(
      find.ancestor(
        of: find.byKey(ValueKey<String>('week-goal-$goalId')),
        matching: find.byType(Draggable<String>),
      ),
    );
    // 逐字契约（`day_grid.dart` 的 `_onDrop` 靠前缀分流，值绝不能变）。
    expect(draggable.data, 'goal://$goalId');
    // 且必须与面板共用同一份常量生成，而不是各写一份。
    expect(draggable.data, goalDragPayloadFor(goalId));
    expect(goalIdFromDragPayload(draggable.data), goalId);

    await _flushTimers(tester);
  });
}