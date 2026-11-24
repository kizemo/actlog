// apps/desktop/test/habit_quick_dialog_test.dart
//
// Task 38 · W2 回归：「添加习惯」面板新增习惯性质定义，间隔型保存后自动进日计划。
//
// 钉住四件事：
//   1. 存量契约不变：只填名字就保存 ⇒ 仍是「每天」、仍不生成任何 plan_item
//      （`rail_todo_list_test.dart` 依赖这条）；
//   2. 「每隔 N 天」写库口径 = `schedule_type='daily'` + `weekly_n=N` + 起始日期；
//   3. 「每隔 N 周」写库口径 = `schedule_type='weekly_n'` + `weekly_n=N` + `weekdays`；
//   4. 间隔型保存后，未来 14 天内的命中日自动出现计划条目，且字段可直接开工；
//   5. 200% 文字缩放下字段变多不溢出。
//
// 全部用内存真库 + 真仓储 + 真 Riverpod 容器，走真实点击，不直接调内部函数。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/habit_quick_dialog.dart';

import 'l10n_harness.dart';

/// 固定的「今天」：2026-11-09 是周一。
const String _today = '2026-11-09';

/// 打开面板的入口按钮 key（真实用法是右轨「习惯速览」的 `＋`，这里等价复刻）。
const ValueKey<String> _openKey = ValueKey<String>('test-open-habit-dialog');

/// 内存真库 + 真仓储 + 固定今天。
final class _Harness {
  _Harness._(this.container, this.db);

  final ProviderContainer container;
  final ActLogDatabase db;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'habit-quick-dialog-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, db);
  }

  /// 挂一个只有入口按钮的极简页面：面板是 `showDialog` 挂上去的，与真机同路径。
  Future<void> mount(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      // Task 63 FIX-4：`AppLocalizations.of` 走严格 `L10nScope.of`，补祖先。
      l10nScope(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(DensityProfile.comfortable),
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => Center(
                  child: TextButton(
                    key: _openKey,
                    onPressed: () => showHabitQuickDialog(context),
                    child: const Text('添加习惯'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }
}

/// 撑高测试面：面板字段变多后默认 800×600 容易先被外层挤爆。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 保存会连写「习惯 + 若干 plan_item」，给它更长的真实时间。
Future<void> _settleAfterSave(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
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

Future<List<HabitData>> _habits(WidgetTester tester, ActLogDatabase db) async {
  final List<HabitData>? rows = await tester.runAsync(
    () => db.select(db.habit).get(),
  );
  return rows ?? const <HabitData>[];
}

Future<List<PlanItemData>> _planItems(
  WidgetTester tester,
  ActLogDatabase db,
) async {
  final List<PlanItemData>? rows = await tester.runAsync(
    () => db.select(db.planItem).get(),
  );
  return rows ?? const <PlanItemData>[];
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(_openKey));
  await _settle(tester);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('保存'));
  await _settleAfterSave(tester);
}

ValueKey<String> _key(String suffix) =>
    ValueKey<String>('habit-dialog-$suffix');

void main() {
  testWidgets('只填名字保存 ⇒ 仍是每天，且不生成任何计划条目', (WidgetTester tester) async {
    final _Harness harness = _Harness.create();
    _useTallSurface(tester);
    await harness.mount(tester);
    await _openDialog(tester);

    await tester.enterText(find.byKey(_key('name')), '晨间拉伸');
    await _save(tester);

    final List<HabitData> habits = await _habits(tester, harness.db);
    expect(habits, hasLength(1));
    final HabitData habit = habits.single;
    expect(habit.name, '晨间拉伸');
    expect(habit.type, 'normal');
    expect(habit.targetCount, isNull);
    expect(habit.scheduleType, 'daily');
    expect(habit.weeklyN, isNull);
    expect(habit.weekdays, isEmpty);
    expect(habit.startDate, _today);
    expect(
      await _planItems(tester, harness.db),
      isEmpty,
      reason: '非间隔型习惯不该自动进日计划',
    );

    await _flushTimers(tester);
  });

  testWidgets('每隔 N 天：写库为 daily + weekly_n，并自动生成 14 天内的计划条目', (
    WidgetTester tester,
  ) async {
    final _Harness harness = _Harness.create();
    _useTallSurface(tester);
    await harness.mount(tester);
    await _openDialog(tester);

    await tester.enterText(find.byKey(_key('name')), '隔天跑步');
    await tester.tap(find.byKey(_key('schedule-every-days')));
    await tester.pump();

    // 默认 N=2，点一次「＋」变 3。
    expect(
      tester.widget<Text>(find.byKey(_key('interval'))).data,
      '2',
      reason: '每隔 N 天的默认间隔应为 2',
    );
    await tester.tap(find.byKey(_key('interval-plus')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(_key('interval'))).data, '3');

    await _save(tester);

    final List<HabitData> habits = await _habits(tester, harness.db);
    expect(habits, hasLength(1));
    final HabitData habit = habits.single;
    expect(habit.scheduleType, 'daily');
    expect(habit.weeklyN, 3);
    expect(habit.weekdays, isEmpty);
    expect(habit.startDate, _today);

    final List<PlanItemData> items = await _planItems(tester, harness.db);
    expect(
      items.map((PlanItemData i) => i.date).toSet(),
      <String>{
        '2026-11-09',
        '2026-11-12',
        '2026-11-15',
        '2026-11-18',
        '2026-11-21',
      },
      reason: '14 天窗口（11-09..11-22）内每隔 3 天共 5 天命中',
    );
    for (final PlanItemData item in items) {
      expect(item.title, '隔天跑步');
      expect(item.sourceType, 'habit');
      expect(item.sourceId, habit.id);
      expect(item.isHabitRef, 1);
      expect(item.plannedStart, 540);
      expect(item.plannedEnd, 570);
    }

    await _flushTimers(tester);
  });

  testWidgets('每隔 N 周：写库为 weekly_n + weekdays，只生成第 0 周的计划条目', (
    WidgetTester tester,
  ) async {
    final _Harness harness = _Harness.create();
    _useTallSurface(tester);
    await harness.mount(tester);
    await _openDialog(tester);

    await tester.enterText(find.byKey(_key('name')), '双周复盘');
    await tester.tap(find.byKey(_key('schedule-every-weeks')));
    await tester.pump();

    // 切到「每隔 N 周」后自动补上起始日所在星期（2026-11-09 是周一）。
    expect(find.byKey(_key('weekdays')), findsOneWidget);
    expect(find.byKey(_key('weekday-1')), findsOneWidget);

    await _save(tester);

    final List<HabitData> habits = await _habits(tester, harness.db);
    expect(habits, hasLength(1));
    final HabitData habit = habits.single;
    expect(habit.scheduleType, 'weekly_n');
    expect(habit.weeklyN, 2);
    expect(habit.weekdays, '1');
    expect(habit.startDate, _today);

    final List<PlanItemData> items = await _planItems(tester, harness.db);
    expect(
      items.map((PlanItemData i) => i.date).toList(),
      <String>['2026-11-09'],
      reason: '窗口内只有第 0 周（11-09）命中，第 1 周（11-16）不命中',
    );
    expect(items.single.sourceId, habit.id);
    expect(items.single.plannedStart, 540);

    await _flushTimers(tester);
  });

  testWidgets('勾选「每日至少完成」⇒ type=count + target_count + 单位「次」', (
    WidgetTester tester,
  ) async {
    final _Harness harness = _Harness.create();
    _useTallSurface(tester);
    await harness.mount(tester);
    await _openDialog(tester);

    await tester.enterText(find.byKey(_key('name')), '喝水');
    await tester.tap(find.byKey(_key('target-count-toggle')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(_key('target-count'))).data, '3');
    await tester.tap(find.byKey(_key('target-count-plus')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(_key('target-count'))).data, '4');

    await _save(tester);

    final HabitData habit = (await _habits(tester, harness.db)).single;
    expect(habit.type, 'count');
    expect(habit.targetCount, 4);
    expect(habit.targetUnit, '次');
    // 每天 + 次数型不是间隔型，不自动进计划。
    expect(await _planItems(tester, harness.db), isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('200% 文字缩放下展开全部字段不溢出', (WidgetTester tester) async {
    final _Harness harness = _Harness.create();
    _useTallSurface(tester);
    await harness.mount(tester, textScale: 2);
    await _openDialog(tester);

    expect(tester.takeException(), isNull, reason: '打开面板即不应溢出');

    await tester.tap(find.byKey(_key('schedule-every-weeks')));
    await tester.pump();
    expect(find.byKey(_key('interval')), findsOneWidget);
    expect(find.byKey(_key('weekdays')), findsOneWidget);

    await tester.tap(find.byKey(_key('target-count-toggle')));
    await tester.pump();
    expect(find.byKey(_key('target-count')), findsOneWidget);

    expect(tester.takeException(), isNull, reason: '字段全展开也不应溢出');

    // 取消关面板，避免留下未完成的弹层。
    await tester.tap(find.text('取消'));
    await _settle(tester);
    await _flushTimers(tester);
  });
}
