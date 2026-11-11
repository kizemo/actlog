// apps/desktop/test/habit_section_selected_date_test.dart
//
// M18-2 的回归：习惯打卡区的写入日期原本读 `todayProvider`，用户在日历里选中
// 过去某天补录时，勾选会被写到今天。本文件钉死「写入日期 == 所选日期」，
// 并守住 spec §H-1 —— 未来日由 `TodayPage` 整体替换为占位卡，不产生打卡写入。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/habit_section.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';
const String _past = '2026-11-05';
const String _future = '2026-11-12';

/// 内存真库 + 真仓储 + 固定今天、可指定选中日的夹具。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'habit-section-date-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 建一个自 [_past] 起每天排程的习惯，返回其 id。
  Future<String> addDailyHabit(String name) {
    return repos.habit.create(
      name: name,
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
  }

  /// 单独挂习惯打卡区（用于直接验证两个写入分支）。
  Future<void> mountSection(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: HabitSection())),
      ),
    );
  }

  /// 挂整页今日页（用于验证未来日由宿主页整体锁定）。
  ///
  /// `TodayPage` 是内容体，必须由 [LedgerShell] 提供 `Material` 祖先与布局。
  Future<void> mountToday(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LedgerShell(content: TodayPage(), currentNavId: 'today'),
        ),
      ),
    );
  }
}

/// 撑高测试面：今日页整页竖排三段，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来；刻意不用 `pumpAndSettle`（加载动画可能永不静止）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅，避免 tearDown 撞 pending timer。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 只取习惯区块里的同名文本：吸底卡带也渲染习惯名，全局找会重复。
Finder _rowText(String name) {
  return find.descendant(
    of: find.byType(HabitSection),
    matching: find.text(name),
  );
}

void main() {
  testWidgets('过去日：点整行打卡写入所选过去日，绝不落到今天', (tester) async {
    final harness = _Harness.create(selected: _past);
    final habitId = await harness.addDailyHabit('晨间写作');
    await harness.mountSection(tester);
    await _settle(tester);

    expect(_rowText('晨间写作'), findsOneWidget);

    await tester.tap(_rowText('晨间写作'));
    await _settle(tester);

    final checkin = await harness.repos.habit.findCheckin(habitId, _past);
    expect(checkin, isNotNull, reason: '打卡必须落在所选过去日');
    expect(checkin!.status, CheckinStatus.done.code);
    expect(
      await harness.repos.habit.findCheckin(habitId, _today),
      isNull,
      reason: '不得写到今天 —— 这正是 M18-2 的原始缺陷',
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await _flushTimers(tester);
  });

  testWidgets('过去日：复选框分支同样写所选日，再点一次删的也是所选日那条', (tester) async {
    final harness = _Harness.create(selected: _past);
    final habitId = await harness.addDailyHabit('晨间写作');
    await harness.mountSection(tester);
    await _settle(tester);

    await tester.tap(find.byType(Checkbox));
    await _settle(tester);

    expect(await harness.repos.habit.findCheckin(habitId, _past), isNotNull);
    expect(await harness.repos.habit.findCheckin(habitId, _today), isNull);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await _settle(tester);

    expect(
      await harness.repos.habit.findCheckin(habitId, _past),
      isNull,
      reason: '取消打卡要删所选日那条',
    );
    expect(await harness.repos.habit.findCheckin(habitId, _today), isNull);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await _flushTimers(tester);
  });

  testWidgets('切日：今天打卡后切到过去日，勾选状态不串，写入各归各日', (tester) async {
    final harness = _Harness.create(selected: _today);
    final habitId = await harness.addDailyHabit('晨间写作');
    await harness.mountSection(tester);
    await _settle(tester);

    await tester.tap(_rowText('晨间写作'));
    await _settle(tester);
    expect(await harness.repos.habit.findCheckin(habitId, _today), isNotNull);

    harness.container.read(selectedDateProvider.notifier).state = _past;
    await _settle(tester);

    // 过去日没有打卡记录 ⇒ 复选框回到未勾选（状态来自所选日的打卡流）。
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(_rowText('晨间写作'));
    await _settle(tester);

    expect(await harness.repos.habit.findCheckin(habitId, _past), isNotNull);
    expect(
      await harness.repos.habit.findCheckin(habitId, _today),
      isNotNull,
      reason: '补录过去日不得覆盖或删除今天的记录',
    );
    final both = await harness.repos.habit.listCheckinsRange(_past, _today);
    expect(both, hasLength(2));

    await _flushTimers(tester);
  });

  testWidgets('未来日：今日页整体替换为占位卡，不渲染打卡行、不产生任何写入', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _future);
    final habitId = await harness.addDailyHabit('晨间写作');
    await harness.mountToday(tester);
    await _settle(tester);

    expect(find.byType(HabitSection), findsNothing);
    // B2（2026-11-12）：「午 · 执行与打卡」整段（含「打卡在当天开放」占位）
    // 已从今日页删除 ⇒ 未来日的可见占位只剩复盘段那张卡。
    expect(find.text('打卡在当天开放'), findsNothing);
    expect(find.text('复盘与心态在当天开放'), findsOneWidget);
    // 习惯名在两处都不出现（区块与吸底卡带都被未来日锁掉）。
    expect(find.text('晨间写作'), findsNothing);
    expect(
      await harness.repos.habit.findCheckin(habitId, _future),
      isNull,
      reason: '未来日只可预排，禁止产生打卡记录',
    );
    expect(
      await harness.repos.habit.listCheckinsRange(_future, _future),
      isEmpty,
    );

    await _flushTimers(tester);
  });

  testWidgets('页内切到未来日：习惯区已不在今日页，未来日仍零写入且今天的记录不受影响', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _today);
    final habitId = await harness.addDailyHabit('晨间写作');
    // B2（2026-11-12）：打卡入口已搬离今日页 ⇒ 无法再在页内点行造前置数据，
    // 改用仓储直造「今天已打过卡」。「点行写入所选日」那条 UI 路径由上面的
    // `mountSection` 用例覆盖，本用例只剩「切日不串写、不动历史」两个 db 判据。
    await harness.repos.habit.upsertCheckin(habitId: habitId, date: _today);
    await harness.mountToday(tester);
    await _settle(tester);

    expect(find.byType(HabitSection), findsNothing);

    harness.container.read(selectedDateProvider.notifier).state = _future;
    await _settle(tester);

    expect(find.byType(HabitSection), findsNothing);
    expect(find.text('打卡在当天开放'), findsNothing);
    expect(
      await harness.repos.habit.findCheckin(habitId, _future),
      isNull,
      reason: '未来日禁止打卡写入（spec §H-1）',
    );
    expect(
      await harness.repos.habit.findCheckin(habitId, _today),
      isNotNull,
      reason: '切到未来日不得动到今天的记录',
    );

    await _flushTimers(tester);
  });
}