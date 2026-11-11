// apps/desktop/test/habits_page_test.dart
//
// B2 / T11：习惯页把「习惯」导航项变成真实落点。本文件钉两条口径：
// 1. 打卡写入日期 == 所选日期（在日历里选中过去某天补录，不会落到今天）；
// 2. 未来日只读 —— `onChanged` 为 null，且库里不会出现未来日的打卡记录。
//
// 两条都做**判别性**断言：写错日期 / 不禁用都会真的失败，不是「存在即通过」。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/habits_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
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
    final repos = ActLogRepositories(db, deviceId: 'habits-page-test');
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

  /// 建一个自 2026-11-01 起每天排程的习惯，返回其 id。
  Future<String> addDailyHabit(String name) {
    return repos.habit.create(
      name: name,
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
  }

  /// 挂习惯页。`HabitsPage` 是内容体，必须由 [LedgerShell] 提供布局与 `Material`。
  Future<void> mountPage(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LedgerShell(content: HabitsPage(), currentNavId: 'habits'),
        ),
      ),
    );
  }
}

/// 撑高测试面：壳层自带导航与键条，默认 800×600 会溢出。
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

void main() {
  testWidgets('过去日勾选写到所选日期，再点一次撤销', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _past);
    final String habitId = await harness.addDailyHabit('晨读');
    await harness.mountPage(tester);
    await _settle(tester);

    final Finder box = find.byKey(ValueKey<String>('habit-check-$habitId'));
    expect(box, findsOneWidget);
    expect(await harness.repos.habit.findCheckin(habitId, _past), isNull);

    await tester.tap(box);
    await _settle(tester);

    final HabitCheckinData? pastRow = await harness.repos.habit
        .findCheckin(habitId, _past);
    expect(pastRow, isNotNull);
    expect(pastRow!.status, CheckinStatus.done.code);
    // 判别性：写入没有串到「今天」——串了这条必红。
    expect(await harness.repos.habit.findCheckin(habitId, _today), isNull);
    // 界面回显同样跟所选日期走。
    expect(tester.widget<LedgerCheckbox>(box).value, isTrue);

    await tester.tap(box);
    await _settle(tester);

    // 撤销是删除（墓碑），读回来必须是 null。
    expect(await harness.repos.habit.findCheckin(habitId, _past), isNull);
    expect(tester.widget<LedgerCheckbox>(box).value, isFalse);

    await _flushTimers(tester);
  });

  testWidgets('未来日只读：onChanged 为 null 且库中无打卡', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _future);
    final String habitId = await harness.addDailyHabit('晨读');
    await harness.mountPage(tester);
    await _settle(tester);

    final Finder box = find.byKey(ValueKey<String>('habit-check-$habitId'));
    expect(box, findsOneWidget);
    final LedgerCheckbox widget = tester.widget<LedgerCheckbox>(box);
    // 判别性：未来日必须真的禁用（不是「点了没反应」）。
    expect(widget.onChanged, isNull);
    expect(widget.value, isFalse);
    expect(
      find.byKey(const ValueKey<String>('habits-page-future-hint')),
      findsOneWidget,
    );

    await tester.tap(box);
    await _settle(tester);

    expect(await harness.repos.habit.findCheckin(habitId, _future), isNull);
    expect(tester.widget<LedgerCheckbox>(box).value, isFalse);

    await _flushTimers(tester);
  });
}