// apps/desktop/test/rail_todo_list_test.dart
//
// Task 34 / Part B 回归：右轨拆成三块后的面板顺序、内容边界与两枚 `＋` 动作位。
//
// ① 面板顺序 = 待办列表 / 习惯速览 / 闭环提示，且合并模块「拖入时间轴」已删除；
// ② 「待办列表」只列待办（同一份右轨里不出现习惯名）；
// ③ 两枚 `＋` 存在（`Semantics` label 可读），点击分别打开两个弹窗；
// ④ 「添加习惯」空名不提交；填名保存后库里真有这条习惯。
//
// 渲染的是 `todayRailPanels()` 这份**生产清单**（`ShellHost` 依赖 `window_manager`，
// 测试进程里起不来），所以面板顺序与动作位都取自真实实现，不是测试里另拼一份。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/quick_todo_dialog.dart';
import 'package:actlog/src/widgets/shell/tool_rail.dart';
import 'package:actlog/src/widgets/timeline/todo_rail_panel.dart';

const String _today = '2026-11-09';
const String _todoTitle = '右轨待办甲';
const String _habitName = '右轨习惯乙';

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'rail-todo-list-test');
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

  /// 一条未排期待办 + 一条自 2026-11-01 起每天排程的习惯。
  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      await repos.todo.create(title: _todoTitle);
      await repos.habit.create(
        name: _habitName,
        scheduleType: 'daily',
        startDate: '2026-11-01',
      );
    });
  }

  /// 挂右轨（不套 `LedgerShell`：键条与 dock 会引入同名文案）。
  Future<void> mountRail(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: ToolRail(panels: todayRailPanels(context)),
              ),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
  }
}

/// 撑高测试面：右轨竖排三块，默认 800×600 会溢出。
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
  testWidgets('① 面板顺序 = 待办列表 / 习惯速览 / 闭环提示，且没有「拖入时间轴」',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mountRail(tester);

    expect(find.text('拖入时间轴'), findsNothing, reason: '合并模块必须已删除');

    final double yTodo = tester.getTopLeft(find.text('待办列表')).dy;
    final double yHabit = tester.getTopLeft(find.text('习惯速览')).dy;
    final double yLoop = tester.getTopLeft(find.text('闭环提示')).dy;
    expect(yTodo < yHabit && yHabit < yLoop, isTrue,
        reason: '面板顺序必须是 待办列表 → 习惯速览 → 闭环提示');

    await _flushTimers(tester);
  });

  testWidgets('② 待办列表只列待办，不出现习惯名', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mountRail(tester);

    expect(
      find.descendant(
        of: find.byType(TodoRailPanel),
        matching: find.text(_todoTitle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TodoRailPanel),
        matching: find.text(_habitName),
      ),
      findsNothing,
      reason: '习惯不再混进待办列表面板',
    );
    // 习惯仍然出现在「习惯速览」里（拖拽源搬家了，但没丢）。
    expect(find.text(_habitName), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('③ 两枚 ＋ 存在，点击分别打开添加待办 / 添加习惯弹窗',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mountRail(tester);

    // 语义句柄必须在用例体内释放：`addTearDown` 跑在框架的收尾自检之后，
    // 会被判成「A SemanticsHandle was active at the end of the test」。
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('添加待办'), findsOneWidget);
    expect(find.bySemanticsLabel('添加习惯'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('rail-add-todo')));
    await _settle(tester);
    expect(find.byType(QuickTodoDialog), findsOneWidget,
        reason: '待办 ＋ 复用既有的手写面板');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(find.byType(QuickTodoDialog), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('rail-add-habit')));
    await _settle(tester);
    expect(find.byKey(const ValueKey<String>('habit-quick-dialog')), findsOneWidget);

    handle.dispose();
    await _flushTimers(tester);
  });

  testWidgets('④ 添加习惯：空名不提交，填名保存后库里有该习惯',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.seed(tester);
    await harness.mountRail(tester);

    await tester.tap(find.byKey(const ValueKey<String>('rail-add-habit')));
    await _settle(tester);
    expect(find.byKey(const ValueKey<String>('habit-quick-dialog')), findsOneWidget);

    // 空名 ⇒ 面板内报错、不关面板、库里不新增。
    await tester.tap(find.text('保存'));
    await _settle(tester);
    expect(find.text('习惯名不能为空'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('habit-quick-dialog')), findsOneWidget);
    final List<HabitData>? before = await tester.runAsync(
      () => harness.repos.habit.listActive(),
    );
    expect(before!.length, 1);

    await tester.enterText(
      find.byKey(const ValueKey<String>('habit-dialog-name')),
      '右轨新习惯',
    );
    await tester.tap(find.text('保存'));
    await _settle(tester);

    expect(find.byKey(const ValueKey<String>('habit-quick-dialog')), findsNothing);
    final List<HabitData>? after = await tester.runAsync(
      () => harness.repos.habit.listActive(),
    );
    expect(after!.length, 2);
    expect(
      after.any((HabitData habit) => habit.name == '右轨新习惯'),
      isTrue,
    );

    await _flushTimers(tester);
  });
}