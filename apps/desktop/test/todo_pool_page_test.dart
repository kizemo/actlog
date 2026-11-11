// apps/desktop/test/todo_pool_page_test.dart
//
// W3 装配的 #3 闭环：B1 验收记录第 5 节遗留「待办捞取入口缺失」。
//
// 钉子有三颗：
//   1. 池子能新建（表单 → `TodoRepository.create` → 表里出现，且字段口径正确）；
//   2. 表里能捞入选中日（`pullToPlan` → 当天 `plan_item` +1，待办转 done 后离开池子）；
//   3. 表头严格五列 —— 修订 G 删掉了「领域」列（`todo` 表没有 `domain`）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

const ValueKey<String> _kTitle = ValueKey<String>('todo-new-title');
const ValueKey<String> _kEst = ValueKey<String>('todo-new-est');
const ValueKey<String> _kSubmit = ValueKey<String>('todo-new-submit');
const ValueKey<String> _kEmpty = ValueKey<String>('todo-pool-empty');
const ValueKey<String> _kError = ValueKey<String>('todo-pool-error');

/// 内存真库 + 真仓储 + 固定今天/选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'todo-pool-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // LIFO ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 待办池是内容体，宿主由 [LedgerShell] 提供。
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

/// 撑高测试面：表单 + 表格在 800×600 下会被挤。
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
  testWidgets('新建待办 → 出现在池子 → 捞入今日 → 当天计划 +1', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    // 空态：池子还没东西。
    expect(find.byKey(_kEmpty), findsOneWidget);

    await tester.enterText(find.byKey(_kTitle), '把周报写完');
    await tester.enterText(find.byKey(_kEst), '30');
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text('Q2'));
    await tester.pump();
    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);

    // 池子出现这一行，空态消失。
    expect(find.byKey(_kEmpty), findsNothing);
    expect(find.text('把周报写完'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.byKey(_kError), findsNothing);

    // 字段口径：优先级 A / 象限 Q2 / 预估 30 分钟都落了库。
    final open = await tester.runAsync(() => harness.repos.todo.listOpen());
    expect(open, hasLength(1));
    final todo = open!.single;
    expect(todo.title, '把周报写完');
    expect(todo.priorityAbc?.code, 'A');
    expect(todo.quadrant?.code, 'Q2');
    expect(todo.estMinutes, 30);

    // 捞入选中日（today），今日计划必须 +1。
    await tester.tap(find.byKey(ValueKey<String>('todo-pull-${todo.id}')));
    await _settle(tester);

    final plans = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(plans, hasLength(1));
    expect(plans!.single.title, '把周报写完');
    expect(plans.single.priorityAbc, 'A');
    expect(plans.single.estMinutes, 30);

    // 捞完待办转 done，离开池子 ⇒ 回到空态。
    expect(find.byKey(_kEmpty), findsOneWidget);
    expect(await tester.runAsync(() => harness.repos.todo.listOpen()), isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('空标题与非法预估都在行内报错，且不写库', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);
    expect(find.byKey(_kError), findsOneWidget);
    expect(find.text('标题不能为空'), findsOneWidget);

    await tester.enterText(find.byKey(_kTitle), '有标题');
    await tester.enterText(find.byKey(_kEst), 'abc');
    await tester.tap(find.byKey(_kSubmit));
    await _settle(tester);
    expect(find.text('预估分钟要填正整数，或留空'), findsOneWidget);

    expect(await tester.runAsync(() => harness.repos.todo.listOpen()), isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('表头严格五列：标题 / 优先级 / 预估 / 象限 / 到期，没有「领域」列', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(() async {
      await harness.repos.todo.create(
        title: '已存在的待办',
        quadrant: 'Q1',
        priorityAbc: 'B',
        dueDate: '2026-11-20',
      );
    });
    await harness.mount(tester);
    await _settle(tester);

    for (final head in <String>['标题', '优先级', '预估', '象限', '到期']) {
      expect(find.text(head), findsOneWidget, reason: '表头缺列：$head');
    }
    expect(find.text('领域'), findsNothing, reason: '修订 G 已删除「领域」列');

    // 缺值一律 `—`，不编造。
    expect(find.text('已存在的待办'), findsOneWidget);
    expect(find.text('B'), findsWidgets);
    expect(find.text('2026-11-20'), findsOneWidget);

    await _flushTimers(tester);
  });
}