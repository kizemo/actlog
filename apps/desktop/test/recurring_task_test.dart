// apps/desktop/test/recurring_task_test.dart
//
// W-循环任务：右轨面板 + 添加对话框的端到端回归。
//
// 验的是三件真机上会看的事：
//   1. 面板一挂上就把选中日该跑的循环任务**自动物化**进计划（不用手动刷新）；
//   2. 对话框保存后规则落库、当天立刻出现条目；
//   3. 必填校验在面板内拦下，不写库、不关面板。
//
// 全部用内存真库 + 真仓储：物化幂等与掩码命中只有真 schema 才算数。
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/recurring_rail_panel.dart';
import 'package:actlog/src/widgets/recurring_task_dialog.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-11-11 是**周三**（物化命中与否全靠这一点）。
const String _date = '2026-11-11';
const int _wednesday = 3;

/// 内存真库 + 真仓储 + 固定「今天」与选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'recurring-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_date),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _date),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await _settle(tester);
  }
}

/// 撑高测试面：面板 + 对话框（480 宽）在默认 800×600 下会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（不用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅，再等一拍落库。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pump();
}

/// 对话框宿主：真按钮触发 `showRecurringTaskDialog`（不直接调函数，
/// 这样「面板能被打开」本身就是被验证的对象）。
class _DialogHost extends StatelessWidget {
  const _DialogHost();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => showRecurringTaskDialog(context),
        child: const Text('打开添加循环任务'),
      ),
    );
  }
}

void main() {
  testWidgets('面板一挂上就自动物化选中日，并展示时段与标题', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(
      () => harness.repos.recurring.create(
        title: '晨间复盘',
        weekdayMask: WeekdayMask.bitOf(_wednesday),
        startMinute: 570,
        durationMinutes: 30,
      ),
    );

    await harness.mount(tester, const RecurringRailPanel());

    expect(find.text('晨间复盘'), findsOneWidget);
    expect(find.text('09:30–10:00'), findsOneWidget);
    expect(find.text('共 1 条 · 已自动排入计划'), findsOneWidget);

    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_date),
    );
    expect(items!.map((row) => row.title), contains('晨间复盘'));

    await _flushTimers(tester);
  });

  testWidgets('不命中的星期：面板空态，且不建计划条目', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(
      () => harness.repos.recurring.create(
        title: '只在周日照看',
        weekdayMask: WeekdayMask.sunday,
        startMinute: 600,
      ),
    );

    await harness.mount(tester, const RecurringRailPanel());

    expect(find.text('所选日没有循环任务'), findsOneWidget);
    expect(find.text('只在周日照看'), findsNothing);

    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_date),
    );
    expect(items, isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('对话框保存：规则落库，并立刻物化当天', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-title')),
      '晚间复盘',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-time')),
      '21:00',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-duration')),
      '20',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('recurring-dialog-save')));
    await _settle(tester);

    expect(find.byType(RecurringTaskDialog), findsNothing);

    final rules = await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, hasLength(1));
    expect(rules!.single.title, '晚间复盘');
    // 默认选「工作日」，2026-11-11 是周三 ⇒ 命中。
    expect(rules.single.weekdayMask, WeekdayMask.workdays);
    expect(rules.single.startMinute, 21 * 60);
    expect(rules.single.durationMinutes, 20);

    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_date),
    );
    expect(items!.map((row) => row.title), contains('晚间复盘'));
    expect(
      items.single.plannedStart,
      DateTime(2026, 11, 11).add(const Duration(hours: 21)).millisecondsSinceEpoch,
    );

    await _flushTimers(tester);
  });

  testWidgets('空标题在面板内拦下：不写库、不关面板', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey<String>('recurring-dialog-save')));
    await _settle(tester);

    expect(find.text('标题不能为空'), findsOneWidget);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);

    final rules = await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('时刻写错时给出可读中文，而不是 SQLite 原文', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-title')),
      '时段写错的循环任务',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-time')),
      '25:99',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('recurring-dialog-save')));
    await _settle(tester);

    expect(find.text('开始时刻要写成 HH:mm（例如 09:00）'), findsOneWidget);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);

    final rules = await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('取消星期全选后提交被拦下', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-title')),
      '没有星期',
    );
    // 默认工作日（周一到周五）逐个关掉 ⇒ 掩码归零。
    for (var weekday = 1; weekday <= 5; weekday++) {
      await tester.tap(
        find.byKey(ValueKey<String>('recurring-dialog-weekday-$weekday')),
      );
      await tester.pump();
    }

    await tester.tap(find.byKey(const ValueKey<String>('recurring-dialog-save')));
    await _settle(tester);

    expect(find.text('至少要选一个星期'), findsOneWidget);

    final rules = await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, isEmpty);

    await _flushTimers(tester);
  });
}