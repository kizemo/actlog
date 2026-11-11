// apps/desktop/test/calendar_page_test.dart
//
// 日历页是「进历史日 / 未来日」的唯一入口（M16-6 的另一半缺陷：月历组件
// 建好了却没有宿主页）。这里守住三件事：格子能切日并回退、翻月跨月正确、
// 未来日不被拦住（未来日只可预排 ≠ 不可进入）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/calendar_month_view.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

/// 内存真库 + 真仓储 + 可切日的 ProviderContainer。
final class _Harness {
  _Harness._(this.container);

  final ProviderContainer container;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'calendar-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先登记关库、后登记销毁容器，
    // 实际顺序是「先 dispose 容器、再 db.close」。反过来会永久挂起。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container);
  }

  /// 挂宿主页，日历经 `Navigator.push` 进入。
  ///
  /// 直接把 [CalendarPage] 当 `home` 会让「点格子后 pop」打在根路由上断言
  /// 失败，而真实路径永远是从今日页推入 —— 夹具必须复刻这条路径。
  /// W3 装配后 [CalendarPage] 是内容体，能提供 `Material` 祖先与布局尺寸的
  /// 只有 [LedgerShell]，所以路由里塞的是「壳 + 日历内容体」。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LedgerShell(
                        content: CalendarPage(),
                        currentNavId: 'calendar',
                      ),
                    ),
                  ),
                  child: const Text('打开日历'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 等真库查询回来 + 等路由转场跑完。
///
/// 不能用 `pumpAndSettle`：日历页 loading 态是无限转圈的
/// `CircularProgressIndicator`，settle 会一直等下去。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 等退场转场跑完（`pop` 之后才断言「日历页已消失」）。
///
/// 退场动画是真实的 `AnimationController`，光靠固定帧数容易卡在
/// `reverse` 中途；这里交给 `pumpAndSettle` 跑到底，并留 10 秒上限避免
/// 万一有无限动画时静默挂死。
Future<void> _settlePop(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 60),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

/// 收尾：卸掉界面放掉 drift 流订阅，否则容器销毁会挂住。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 打开日历并等它查完当月摘要。
Future<void> _openCalendar(WidgetTester tester, _Harness harness) async {
  await harness.mount(tester);
  await tester.tap(find.text('打开日历'));
  await _settle(tester);
}

void main() {
  testWidgets('点格子切到那一天，并退回上一页', (tester) async {
    final harness = _Harness.create();
    await _openCalendar(tester, harness);

    expect(find.byType(CalendarPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('day-2026-11-05')));
    await _settlePop(tester);

    expect(harness.container.read(selectedDateProvider), '2026-11-05');
    expect(find.byType(CalendarPage), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('翻月跨月且能翻回来', (tester) async {
    final harness = _Harness.create();
    await _openCalendar(tester, harness);

    // W3 装配后页头多了一处 mono 月份副标题，页内因此有两处同文案
    // ⇒ 断言要锚到真正权威的月历视图标题（`CalendarMonthView` 里那个），
    // 这样也顺带证明「翻月后格子所在月真的换了」。
    Finder month(String text) => find.descendant(
      of: find.byType(CalendarMonthView),
      matching: find.text(text),
    );

    expect(month('2026-11'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('calendar-next-month')));
    await _settle(tester);
    expect(month('2026-12'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('calendar-prev-month')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('calendar-prev-month')));
    await _settle(tester);
    expect(month('2026-10'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('未来日也可进入：预排路径不被月历拦住', (tester) async {
    final harness = _Harness.create();
    await _openCalendar(tester, harness);

    await tester.tap(find.byKey(const ValueKey<String>('day-2026-11-20')));
    await _settlePop(tester);

    expect(harness.container.read(selectedDateProvider), '2026-11-20');
    expect(find.byType(CalendarPage), findsNothing);

    await _flushTimers(tester);
  });
}