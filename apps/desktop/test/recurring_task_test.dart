// apps/desktop/test/recurring_task_test.dart
//
// W-循环任务：右轨面板 + 添加对话框的端到端回归。
//
// 验的是真机上会看的四件事：
//   1. 面板一挂上就把选中日该跑的循环任务**自动物化**进计划（不用手动刷新）；
//   2. 面板的「规则」段列出规则**本身** —— 与今天命中与否无关；
//   3. 对话框保存后规则落库、当天立刻出现条目（掩码不含创建日时先提示再确认）；
//   4. 读取失败时错误原文可见（不是空列表）。
//
// 全部用内存真库 + 真仓储：物化幂等与掩码命中只有真 schema 才算数。
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/providers_recurring.dart';
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

  static _Harness create({List<Override> extraOverrides = const <Override>[]}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'recurring-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_date),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _date),
        ...extraOverrides,
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
  testWidgets('面板一挂上就自动物化选中日，并展示规则与时段', (WidgetTester tester) async {
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

    // 需求 8：面板只列规则 —— 标题只有「规则」段那一行，「今日」段整段移除。
    expect(find.text('晨间复盘'), findsOneWidget);
    expect(find.text('周三 · 30 分钟 · 启用中'), findsOneWidget);
    expect(find.text('共 1 条规则 · 命中日自动排入计划'), findsOneWidget);
    // 旧「今日」段的时段区间与实例计数必须一起消失（不是藏起来）。
    expect(find.text('09:30–10:00'), findsNothing);
    expect(find.text('共 1 条 · 已自动排入计划'), findsNothing);
    expect(find.text('今日'), findsNothing);

    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_date),
    );
    expect(items!.map((row) => row.title), contains('晨间复盘'));

    await _flushTimers(tester);
  });

  testWidgets('不命中的星期：规则区仍列出该规则，只是今天不排', (WidgetTester tester) async {
    // 旧断言（改写前）：
    //   expect(find.text('所选日没有循环任务'), findsOneWidget);
    //   expect(find.text('只在周日照看'), findsNothing);
    // 它成立的前提是「面板只列已物化的 occurrence」—— 而 occurrence 要掩码命中
    // 才产生，于是新建规则当天看不见任何东西，正是用户报的
    // 「确认后没有出现在循环任务列表中」。现行契约是规则区**不依赖** occurrence：
    // 无论今天命中与否都必须看得见（派工书 R1）。「今日」段随后按需求 8
    // 整段移除，于是「所选日没有循环任务」也回到 `findsNothing` —— 理由换了，
    // 判据没松：面板只剩规则列表这一种形态。
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

    // 规则区：不命中也要看得见，且四个字段（星期/时刻/时长/启用状态）齐。
    expect(find.text('只在周日照看'), findsOneWidget);
    expect(find.text('周日 · 30 分钟 · 启用中'), findsOneWidget);
    expect(find.text('共 1 条规则 · 命中日自动排入计划'), findsOneWidget);

    // 需求 8：面板不再有「今日」段，连空态一并移除（「看着重复」的来源）。
    expect(find.text('今日'), findsNothing);
    expect(find.text('所选日没有循环任务'), findsNothing);
    expect(find.text('共 0 条 · 已自动排入计划'), findsNothing);

    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_date),
    );
    expect(items, isEmpty);
    final occurrences = await tester.runAsync(
      () => harness.repos.recurring.listOccurrencesByDate(_date),
    );
    expect(occurrences, isEmpty);

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

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-dialog-save')),
    );
    await _settle(tester);

    expect(find.byType(RecurringTaskDialog), findsNothing);

    final rules =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, hasLength(1));
    expect(rules!.single.title, '晚间复盘');
    // 默认选「工作日」∪ {创建日}，2026-11-11 是周三 ⇒ 掩码就是工作日。
    expect(rules.single.weekdayMask, WeekdayMask.workdays);
    expect(rules.single.startMinute, 21 * 60);
    expect(rules.single.durationMinutes, 20);

    final occurrences = await tester.runAsync(
      () => harness.repos.recurring.listOccurrencesByDate(_date),
    );
    expect(occurrences, hasLength(1));
    expect(occurrences!.single.task.title, '晚间复盘');

    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_date),
    );
    expect(items!.map((row) => row.title), contains('晚间复盘'));
    // 单位是**当日分钟数（0–1439）**，不是 epoch 毫秒：时间轴 `gridEntriesOf`
    // 把两端都夹到 1440，写成 epoch 毫秒会被夹成 `clampedEnd <= clampedStart`，
    // 整行被 `continue` 丢弃 ⇒ 物化出来的计划永远不上网格。
    expect(items.single.plannedStart, 21 * 60);
    // 21:00 起、时长 20 分钟 ⇒ 1260 + 20 = 1280（同为当日分钟数）。
    expect(items.single.plannedEnd, 21 * 60 + 20);

    await _flushTimers(tester);
  });

  testWidgets('掩码不含创建日：先提示并入，再点一次才保存', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-title')),
      '读周报',
    );
    // 默认掩码 = 工作日 ∪ {周三}；把周三关掉 ⇒ 最终掩码不含创建日。
    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-dialog-weekday-$_wednesday')),
    );
    await tester.pump();

    final save = find.byKey(const ValueKey<String>('recurring-dialog-save'));
    await tester.tap(save);
    await _settle(tester);

    // 第一次只提示：不写库、不关面板，按钮变「确认保存」。
    expect(find.textContaining('已把 周三 并入重复日'), findsOneWidget);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);
    expect(find.text('确认保存'), findsOneWidget);
    final before =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(before, isEmpty);

    // 第二次才落库。
    await tester.tap(save);
    await _settle(tester);
    expect(find.byType(RecurringTaskDialog), findsNothing);

    final rules =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, hasLength(1));
    expect(WeekdayMask.includes(rules!.single.weekdayMask, _wednesday), isTrue);

    // 掩码已含创建日 ⇒ 当天必有 occurrence（「设了也不进计划」的正面判据）。
    final occurrences = await tester.runAsync(
      () => harness.repos.recurring.listOccurrencesByDate(_date),
    );
    expect(occurrences, hasLength(1));

    await _flushTimers(tester);
  });

  testWidgets('停用后规则仍在列表里，状态变「已停用」，且可再启用', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(
      () => harness.repos.recurring.create(
        id: 'rule-toggle',
        title: '周日复盘',
        weekdayMask: WeekdayMask.sunday,
        startMinute: 600,
      ),
    );
    await harness.mount(tester, const RecurringRailPanel());
    expect(find.text('周日 · 30 分钟 · 启用中'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-rule-active-rule-toggle')),
    );
    await _settle(tester);

    // 停用是写库的，不是纯 UI 状态；规则仍列出（否则「启用」点不回来）。
    expect(find.text('周日 · 30 分钟 · 已停用'), findsOneWidget);
    expect(find.text('周日复盘'), findsOneWidget);
    expect(find.text('启用'), findsOneWidget);
    final stopped =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(stopped, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-rule-active-rule-toggle')),
    );
    await _settle(tester);
    expect(find.text('周日 · 30 分钟 · 启用中'), findsOneWidget);
    expect(find.text('停用'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('规则读取失败：面板显示错误原文，而不是空列表', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(
      extraOverrides: <Override>[
        recurringRulesProvider.overrideWith(
          (ref) => Stream<List<RecurringTaskData>>.error(
            StateError('规则表读取失败（测试注入）'),
          ),
        ),
      ],
    );

    await harness.mount(tester, const RecurringRailPanel());

    expect(find.textContaining('规则表读取失败（测试注入）'), findsOneWidget);
    expect(find.textContaining('规则读取失败：'), findsOneWidget);
    // 关键：不允许把异常吞成「还没有规则」。
    expect(find.text('还没有循环规则'), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('空标题在面板内拦下：不写库、不关面板', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-dialog-save')),
    );
    await _settle(tester);

    expect(find.text('标题不能为空'), findsOneWidget);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);

    final rules =
        await tester.runAsync(() => harness.repos.recurring.listActive());
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

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-dialog-save')),
    );
    await _settle(tester);

    expect(find.text('开始时刻要写成 HH:mm（例如 09:00）'), findsOneWidget);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);

    final rules =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('开始时刻早于 06:00：夹到 06:00 并提示实际落位', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester, const _DialogHost());

    await tester.tap(find.text('打开添加循环任务'));
    await _settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-title')),
      '早起拉伸',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-dialog-time')),
      '05:30',
    );
    await tester.pump();

    final save = find.byKey(const ValueKey<String>('recurring-dialog-save'));
    await tester.tap(save);
    await _settle(tester);

    // 提示里必须能看到实际落位时刻（派工书 R5）。
    expect(find.textContaining('已改到 06:00'), findsOneWidget);
    expect(find.byType(RecurringTaskDialog), findsOneWidget);

    await tester.tap(save);
    await _settle(tester);
    expect(find.byType(RecurringTaskDialog), findsNothing);

    final rules =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, hasLength(1));
    expect(rules!.single.startMinute, 6 * 60);

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

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-dialog-save')),
    );
    await _settle(tester);

    expect(find.text('至少要选一个星期'), findsOneWidget);

    final rules =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(rules, isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('删除规则先弹确认：取消则保留，确认才归档', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(
      () => harness.repos.recurring.create(
        id: 'rule-archive',
        title: '待归档的循环任务',
        weekdayMask: WeekdayMask.workdays,
        startMinute: 600,
      ),
    );
    await harness.mount(tester, const RecurringRailPanel());
    expect(find.text('待归档的循环任务'), findsOneWidget);

    final delete =
        find.byKey(const ValueKey<String>('recurring-rule-delete-rule-archive'));

    // 第一下：只弹确认，不写库（需求 9 —— 归档是软删，也必须有二次确认）。
    await tester.tap(delete);
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('confirm-dialog-confirm')),
      findsOneWidget,
    );
    expect(find.text('待归档的循环任务'), findsOneWidget);
    var alive =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(alive, hasLength(1));

    // 取消 ⇒ 弹窗关掉，规则原样还在。
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-dialog-cancel')),
    );
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('confirm-dialog-confirm')),
      findsNothing,
    );
    expect(find.text('待归档的循环任务'), findsOneWidget);
    alive = await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(alive, hasLength(1));

    // 再来一次并确认 ⇒ 规则真的落成墓碑，列表回到空态。
    await tester.tap(delete);
    await _settle(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-dialog-confirm')),
    );
    await _settle(tester);

    expect(find.text('待归档的循环任务'), findsNothing);
    expect(find.text('还没有循环规则'), findsOneWidget);
    final remaining =
        await tester.runAsync(() => harness.repos.recurring.listActive());
    expect(remaining, isEmpty);

    await _flushTimers(tester);
  });
}