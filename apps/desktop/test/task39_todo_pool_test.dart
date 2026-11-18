// apps/desktop/test/task39_todo_pool_test.dart
//
// Task 39 · W2 回归：「添加待办」后待办列表看不到。
//
// 根因在数据层：`TodoRepository.pullToPlan` 曾顺带把 todo 置 `done`，
// 而待办池只查 `status='open'`，于是「同时捞入今天」的待办一提交就从池子消失。
// 这里走真实面板提交，钉住：
//   1. 默认勾选「同时捞入今天」时，提交后待办**仍**在待办池（`todoPoolProvider` 有它）；
//   2. 今天计划里同时出现该条（plan_item 一条，来源是 todo）。
import 'package:core_data/core_data.dart';
// core_db 也导出同名 Todo（drift 表类）；这里要的是 core_domain 的实体。
import 'package:core_db/core_db.dart' hide Todo;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/providers_p1.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/quick_todo_dialog.dart';

const String _today = '2026-11-09';
const ValueKey<String> _openKey = ValueKey<String>('test-open-todo-dialog');

final class _Harness {
  _Harness._(this.container, this.db);

  final ProviderContainer container;
  final ActLogDatabase db;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task39-todo-pool-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, db);
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: TextButton(
                  key: _openKey,
                  onPressed: () => showQuickTodoDialog(context),
                  child: const Text('手写一条'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// 挂载**待办池页**本身（不走手写面板）：验证池子页自己的新建入口。
  Future<void> mountPool(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: const Scaffold(
            body: SingleChildScrollView(child: TodoPoolPage()),
          ),
        ),
      ),
    );
    await tester.pump();
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

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
  testWidgets('同时捞入今天 ⇒ 提交后待办仍在待办池，且今日计划多一条', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);

    await tester.tap(find.byKey(_openKey));
    await _settle(tester);

    // 标题字段是面板里第一个 TextField；「同时捞入今天」默认已勾选。
    await tester.enterText(find.byType(TextField).first, '给客户回信');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await _settle(tester);

    final List<Todo>? pool = await tester.runAsync(
      () => harness.container.read(todoPoolProvider.future),
    );
    expect(
      (pool ?? const <Todo>[]).map((Todo t) => t.title),
      contains('给客户回信'),
      reason: '待办池必须仍能看到刚添加的这条',
    );

    final List<PlanItemData>? rows = await tester.runAsync(
      () => harness.db.select(harness.db.planItem).get(),
    );
    final List<PlanItemData> items = rows ?? const <PlanItemData>[];
    expect(items, hasLength(1), reason: '默认勾选 ⇒ 今日计划恰好一条');
    expect(items.single.sourceType, PlanSourceType.todo.code);
    expect(items.single.title, '给客户回信');

    await _flushTimers(tester);
  });

  testWidgets('池子页新建入口：选「小时」填 2 ⇒ 落库 120 分钟且仍 open', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mountPool(tester);
    await _settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-new-title')),
      '读一章书',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-new-est')),
      '2',
    );
    await tester.pump();
    // 单位默认「分钟」；点「小时」后口径换成 ×60（数量 2 不再当 2 分钟落库）。
    expect(
      find.byKey(const ValueKey<String>('todo-pool-est-unit-hour')),
      findsOneWidget,
      reason: '池子页必须真的接上共享的单位选择器',
    );
    await tester.tap(find.byKey(const ValueKey<String>('todo-pool-est-unit-hour')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('todo-new-submit')));
    await _settle(tester);

    final List<TodoData>? rows = await tester.runAsync(
      () => harness.db.select(harness.db.todo).get(),
    );
    final List<TodoData> created = (rows ?? const <TodoData>[])
        .where((TodoData row) => row.title == '读一章书')
        .toList();
    expect(created, hasLength(1), reason: '点一次新建只写一条');
    expect(created.single.estMinutes, 120, reason: '2 小时 = 120 分钟');
    expect(created.single.status, 'open', reason: '新建不排期 ⇒ 不该顺手置 done');

    await _flushTimers(tester);
  });

  testWidgets('两个输入点各自接线：chip 前缀互不串台', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mountPool(tester);
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('todo-pool-est-unit-hour')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quick-todo-est-unit-hour')),
      findsNothing,
      reason: '池子页不该混进手写面板的前缀',
    );

    await harness.mount(tester);
    await tester.tap(find.byKey(_openKey));
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('quick-todo-est-unit-hour')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('todo-pool-est-unit-hour')),
      findsNothing,
      reason: '手写面板不该混进池子页的前缀',
    );

    await _flushTimers(tester);
  });
}