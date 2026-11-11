// apps/desktop/test/today_page_selected_date_test.dart
//
// M16-6 的根因回归：今日页标题原本读 `todayProvider`，与所有数据源
// （`dayLogProvider` / `planItemsProvider` / 吸底卡带）不同源，切日之后
// 标题停在今天、内容却换了天。另外守住 spec §H-1 —— 未来日只可预排，
// 打卡 / 回填 / 复盘 / 心态一律不开放。
//
// W3 装配后 `TodayPage` 是**内容体**（无 `Scaffold` / 无 `AppBar`），
// 宿主改由 `LedgerShell` 承担；「进日历」也不再是 AppBar 按钮，而是壳导航。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/habit_checkin_strip.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';
const String _past = '2026-11-05';
const String _future = '2026-11-12';

/// 内存真库 + 真仓储 + 固定今天、可指定选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'today-selected-test');
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

  /// 挂今日页内容体（外包 `LedgerShell`，与真机一致）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LedgerShell(
            content: TodayPage(),
            currentNavId: 'today',
            // 打卡条已从壳层整体移除（打卡入口搬到习惯页）⇒ 这里不再传 `dock`，
            // 与真机壳层一致，下面各例据此断言「条真的不在了」。
          ),
        ),
      ),
    );
  }

  /// 挂完整壳宿主：导航点击才有效，用于替代原 AppBar 的「进日历」路径。
  Future<void> mountHost(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ShellHost()),
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
  // `ReviewSection` 在 `dispose` 里 fire-and-forget 落库（`review_section.dart:64`
  // → `saveReview`）。不等它跑完，tearDown 的 `db.close()` 会先关库，这笔未完成的
  // 写就变成下个用例里的 `Can't re-open a database after closing it`。
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 把 finder 限定在「今日计划」卡片内。
///
/// 今日页已不再挂打卡区块（打卡入口搬到习惯页），但计划行之外仍可能有
/// 别的复选框，所以仍然限定在「今日计划」卡片内找，避免串味。
Finder _inPlanCard(Finder matching) {
  return find.descendant(
    of: find.byKey(const ValueKey<String>('day-grid')),
    matching: matching,
  );
}

void main() {
  testWidgets('标题跟随选中日：过去日显示补录模式，切日即时生效', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _past);
    await harness.mount(tester);
    await _settle(tester);

    // 页头副标带裸 iso 日期（`<日期> · <星期>`），这是标题与数据同源的证据。
    expect(find.textContaining(_past), findsWidgets);
    expect(find.textContaining(_today), findsNothing);
    expect(find.text('补录模式'), findsOneWidget);

    harness.container.read(selectedDateProvider.notifier).state = '2026-11-07';
    await _settle(tester);

    expect(find.textContaining('2026-11-07'), findsWidgets);
    expect(find.textContaining(_past), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('未来日只可预排：勾选禁用、打卡与吸底卡带不出现', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _future);
    await tester.runAsync(() async {
      await TimelineStore(harness.repos).createManual(date: _future, title: '预排一条', startMinute: 9 * 60, endMinute: 10 * 60);
    });
    await harness.mount(tester);
    await _settle(tester);

    expect(_inPlanCard(find.text('预排一条')), findsOneWidget);

    final boxes = tester.widgetList<LedgerCheckbox>(
      _inPlanCard(find.byType(LedgerCheckbox)),
    );
    expect(boxes, hasLength(1));
    expect(boxes.single.onChanged, isNull);

    expect(
      find.byKey(const ValueKey<String>('future-plan-hint')),
      findsOneWidget,
    );
    // 打卡条已从壳层整体移除 ⇒ 判据升级为「widget 根本不在树里」；
    // 「午 · 执行与打卡」整段（含「打卡在当天开放」占位）也已删除 ⇒ 同样判缺席。
    expect(find.byType(HabitCheckinStrip), findsNothing);
    expect(find.text('打卡在当天开放'), findsNothing);
    // 对照：复盘段仍保留、未来日仍打出「当天开放」占位 —— 证明上面两条
    // 缺席判据不是「整页什么都没渲染」导致的恒真。
    expect(find.text('复盘与心态在当天开放'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('过去日仍可回填：计划行可勾、壳层无打卡条', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _past);
    await tester.runAsync(() async {
      await TimelineStore(harness.repos).createManual(date: _past, title: '补录一条', startMinute: 9 * 60, endMinute: 10 * 60);
    });
    await harness.mount(tester);
    await _settle(tester);

    final boxes = tester.widgetList<LedgerCheckbox>(
      _inPlanCard(find.byType(LedgerCheckbox)),
    );
    expect(boxes, hasLength(1));
    expect(boxes.single.onChanged, isNotNull);

    expect(find.byKey(const ValueKey<String>('future-plan-hint')), findsNothing);
    // 打卡条不再常驻今日页壳层 ⇒ 守「缺席」（正向证据见 `ledger_dock_test.dart`
    // 第 3 例：习惯页 `habit-check-<id>` 真库往返）。
    expect(find.byType(HabitCheckinStrip), findsNothing);
    expect(find.text(HabitCheckinStrip.emptyLabel), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('壳导航「日历」进入日历页', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _today);
    await harness.mountHost(tester);
    await _settle(tester);

    await tester.tap(find.text('日历'));
    await _settle(tester);

    expect(find.byType(CalendarPage), findsOneWidget);

    await _flushTimers(tester);
  });
}