// apps/desktop/test/todo_pool_schedule_test.dart
//
// B2 §7.5：待办表单加**可选起始时间**。
//
// 三颗钉子：
//   1. 填了起始时间 ⇒ 同一事务里 `todo` 行 + 当天 `plan_item` 行都落库，
//      且计划行带 `source_type='todo'` / `source_todo_id` / `planned_start/end`；
//   2. 起始时间 15 分钟吸附（`09:20` 落到 `09:15`）；
//   3. 留空 ⇒ 只建待办、当天计划 0 行（不排期），也不显示徽标。
//
// 「已填时间」是派生事实（§0）：徽标文案由未删除的 `plan_item` 反算，
// 不新增任何列。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

const ValueKey<String> _kTitle = ValueKey<String>('todo-new-title');
const ValueKey<String> _kEst = ValueKey<String>('todo-new-est');
const ValueKey<String> _kStart = ValueKey<String>('todo-new-start');
const ValueKey<String> _kSubmit = ValueKey<String>('todo-new-submit');
const ValueKey<String> _kError = ValueKey<String>('todo-pool-error');

/// 内存真库 + 真仓储 + 固定今天/选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'todo-schedule-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LedgerShell(content: TodoPoolPage(), currentNavId: 'inbox'),
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

/// 等真库流回来。
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
  testWidgets('填了起始时间 ⇒ 待办 + 当天计划同事务落库，并显示「已排期 09:15」',
      (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.enterText(find.byKey(_kTitle), '排期测试');
    await tester.enterText(find.byKey(_kEst), '30');
    await tester.enterText(find.byKey(_kStart), '09:15');
    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);

    expect(find.byKey(_kError), findsNothing);

    // 待办仍在池子里（已排期 ≠ 已完成），且预估值照旧落库。
    final open = await tester.runAsync(() => harness.repos.todo.listOpen());
    expect(open, hasLength(1));
    final todo = open!.single;
    expect(todo.estMinutes, 30);

    // 计划行：同一天、同标题、source 指向这条待办、起止 = 09:15–09:45。
    final plans = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(plans, hasLength(1));
    final plan = plans!.single;
    expect(plan.title, '排期测试');
    expect(plan.sourceType, 'todo');
    expect(plan.sourceTodoId, todo.id);
    expect(plan.plannedStart, 9 * 60 + 15);
    expect(plan.plannedEnd, 9 * 60 + 45);
    expect(plan.status, 'pending');

    // 只读徽标：文案由计划行反算，不新增列。
    expect(find.text('已排期 09:15'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('起始时间 15 分钟吸附：09:20 落到 09:15，时长留空默认一格',
      (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.enterText(find.byKey(_kTitle), '吸附测试');
    await tester.enterText(find.byKey(_kStart), '09:20');
    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);

    final plans = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(plans, hasLength(1));
    expect(plans!.single.plannedStart, 9 * 60 + 15);
    expect(plans.single.plannedEnd, 9 * 60 + 30);

    await _flushTimers(tester);
  });

  testWidgets('留空 ⇒ 只建待办，当天计划 0 行且不显示排期徽标', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.enterText(find.byKey(_kTitle), '不排期');
    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);

    expect(await tester.runAsync(() => harness.repos.todo.listOpen()),
        hasLength(1));
    expect(
      await tester.runAsync(() => harness.repos.planItem.listByDate(_today)),
      isEmpty,
    );
    expect(find.textContaining('已排期'), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('起始时间格式非法 ⇒ 行内报错且不写库', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.enterText(find.byKey(_kTitle), '格式错');
    await tester.enterText(find.byKey(_kStart), '25:99');
    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);

    expect(find.byKey(_kError), findsOneWidget);
    expect(find.text('起始时间要填 HH:mm，或留空'), findsOneWidget);
    expect(await tester.runAsync(() => harness.repos.todo.listOpen()), isEmpty);
    expect(
      await tester.runAsync(() => harness.repos.planItem.listByDate(_today)),
      isEmpty,
    );

    await _flushTimers(tester);
  });
}