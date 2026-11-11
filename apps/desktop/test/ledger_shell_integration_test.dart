// apps/desktop/test/ledger_shell_integration_test.dart
//
// W3 装配的跨页集成：一个 `ShellHost` 就是整个应用外壳。
//
// 钉子两颗：
//   1. 导航只切本组件的 `_nav` 状态，三个真实落点（今日 / 待办池 / 日历）
//      来回切得动，且**不叠壳**（任一刻只有一份 `LedgerShell`）；
//   2. B1 验收记录第 5 节遗留 #4：今日计划里的复选框必须键盘可达。
//      Material `Checkbox` 已换成 `LedgerCheckbox`（自带 `FocusNode` +
//      `ActivateIntent` + 焦点环），按 Tab 能聚焦、按空格能勾。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

/// 内存真库 + 真仓储 + 固定今天/选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'shell-integration-test');
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

  /// 挂完整壳宿主（真机路径：`MaterialApp.home` 就是 [ShellHost]）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ShellHost()),
      ),
    );
  }
}

/// 撑高测试面：整页竖排 + 右轨，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来 + 等状态切换重建。
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

/// 把 finder 限定在「今日计划」卡片内（打卡区块里也有复选框）。
Finder _inPlanCard(Finder matching) {
  return find.descendant(
    of: find.byKey(const ValueKey<String>('day-grid')),
    matching: matching,
  );
}

void main() {
  testWidgets('导航在三个真实落点之间切换，且始终只有一份壳', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.byType(LedgerShell), findsOneWidget);

    await tester.tap(find.text('待办池'));
    await _settle(tester);
    expect(find.byType(TodoPoolPage), findsOneWidget);
    expect(find.byType(TodayPage), findsNothing);
    expect(find.byType(LedgerShell), findsOneWidget, reason: '切页不得叠壳');

    await tester.tap(find.text('日历'));
    await _settle(tester);
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(find.byType(TodoPoolPage), findsNothing);
    expect(find.byType(LedgerShell), findsOneWidget);

    await tester.tap(find.text('今日'));
    await _settle(tester);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.byType(CalendarPage), findsNothing);
    expect(find.byType(LedgerShell), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('#4 复选框键盘可达：聚焦后按空格把计划条目勾成完成', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(() async {
      await TimelineStore(harness.repos).createManual(date: _today, title: '键盘勾选我', startMinute: 9 * 60, endMinute: 10 * 60);
    });
    await harness.mount(tester);
    await _settle(tester);

    // 今日计划里已经没有 Material `Checkbox`（那是键盘不可达的旧实现）。
    expect(_inPlanCard(find.byType(Checkbox)), findsNothing);
    expect(_inPlanCard(find.byType(LedgerCheckbox)), findsOneWidget);

    // 拿框自己的 FocusNode 聚焦 —— 等价于用户 Tab 到这里。
    final nodes = tester
        .widgetList<Focus>(
          _inPlanCard(
            find.descendant(
              of: find.byType(LedgerCheckbox),
              matching: find.byType(Focus),
            ),
          ),
        )
        .map((Focus focus) => focus.focusNode)
        .whereType<FocusNode>()
        .toList(growable: false);
    expect(nodes, isNotEmpty, reason: 'LedgerCheckbox 必须自带可请求焦点的 FocusNode');
    nodes.first.requestFocus();
    await tester.pump();

    // 键盘焦点可见性：框自己的焦点环出现（Task 16 契约，key 不得改名）。
    // 页面上多个控件都挂了 `FocusRing`，所以必须限定在框内部找。
    expect(
      find.descendant(
        of: _inPlanCard(find.byType(LedgerCheckbox)),
        matching: find.byKey(const ValueKey<String>('focus-ring-border')),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);

    final plans = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(plans, hasLength(1));
    expect(plans!.single.status, PlanStatus.done.code);

    await _flushTimers(tester);
  });

  // 裁定 B：B1 验收记录第 5 节遗留 #6「系统字号 200%」。
  //
  // 不碰用户的系统环境，改为读 `ACTLOG_TEXT_SCALE` 并在本进程的
  // `MediaQuery.textScaler` 上施加 —— 这两条钉子分别守「解析口径」与
  // 「真放大后壳里不炸」。
  group('裁定 B · 字号缩放', () {
    test('resolveTextScale 只认正的有限倍数，其余一律回落 1.0', () {
      expect(resolveTextScale('2'), 2.0);
      expect(resolveTextScale('1.75'), 1.75);
      // 没配 / 空串 / 非数字 / 零 / 负数 / 非有限值 ⇒ 都不是合法倍数。
      expect(resolveTextScale(null), 1.0);
      expect(resolveTextScale(''), 1.0);
      expect(resolveTextScale('abc'), 1.0);
      expect(resolveTextScale('0'), 1.0);
      expect(resolveTextScale('-2'), 1.0);
      expect(resolveTextScale('NaN'), 1.0);
      expect(resolveTextScale('Infinity'), 1.0);
    });

    testWidgets('200% 下今日页仍在壳里，且 textScaler 确实放大', (tester) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: const ActLogApp(textScale: 2.0),
        ),
      );
      await _settle(tester);

      expect(find.byType(TodayPage), findsOneWidget);
      expect(find.byType(LedgerShell), findsOneWidget);

      // 真放大才作数：10pt 的字在这里必须量到 20pt。
      final scaler = MediaQuery.textScalerOf(
        tester.element(find.byType(TodayPage)),
      );
      expect(scaler.scale(10), 20);

      // Task 19 收尾：`LoopProgressRing` 的刻度行改成「装不下就整行等比缩小」、
      // `SectionCard` 的头部行改成「标题/说明各让一半、最多折两行」，
      // 200% 下不允许再有任何 `RenderFlex` 溢出。
      //
      // 这里对异常做实断言：抽干异常（`while (takeException() != null) overflows++`）
      // 等于把这条门禁关掉 —— 溢出再多也能「通过」，那不是测试，是消音。
      expect(tester.takeException(), isNull);

      await _flushTimers(tester);
    });
  });
}