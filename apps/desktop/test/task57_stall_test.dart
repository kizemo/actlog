// apps/desktop/test/task57_stall_test.dart
//
// Task 57 · 57.4e（补轮）：右轨停滞提示的「今天不再提」按**日期粒度**抑制。
//
// 计划 §57.4 的 57.4e 已打勾，但 `loop-hint-stall-dismiss` / `_stallDismissed`
// 在 `apps\desktop\test\*.dart` 里曾零命中 ⇒ 本文件补上该勾的测试证据。
//
// 口径是**真库 + 真界面**：内存 drift 库 + 真仓储 + 真壳（右轨由 `LedgerShell`
// 装配 `todayRailPanels`），只点界面上的按钮，不直接摸私有 provider。
//
// 四条断言：
//   E1：点「今天不再提」⇒ 该条停滞提示消失；
//   E2：同一 today 下重挂页面 ⇒ 仍不出现（抑制键 `projectId|today` 生效）；
//   E3：换 today（`2026-11-21`）⇒ **重新出现**（日期粒度；缺此条等于只测了
//       「点一下就没了」，把抑制键退化成 `projectId` 也照样绿）；
//   E4（负控）：同一 today 下不点按钮重挂 ⇒ 仍出现。
//
// 抑制态是 `today_page.dart` 内的私有 `StateProvider<Set<String>>`，只存进程内存、
// 不跨重启（计划 §57.2 裁决① 已登记的边界）；本文件不改产品代码去持久化它。

import 'package:actlog/src/app.dart';
import 'package:actlog/src/data/project_store.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 测试内的「今天」。
///
/// 生产里 `todayProvider` 是 `Provider<String>`（只读），这里用一层可写的
/// `StateProvider` 顶替它，才能在同一容器、**同一份抑制态**下换日。
final StateProvider<String> _fakeToday = StateProvider<String>(
  (ref) => '2026-11-20',
);

Finder _stallRow(String projectId) =>
    find.byKey(ValueKey<String>('loop-hint-stall-$projectId'));

Finder _dismissBtn(String projectId) =>
    find.byKey(ValueKey<String>('loop-hint-stall-dismiss-$projectId'));

/// 撑高测试面：今日页整页竖排，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
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
  // `ReviewSection` 在 `dispose` 里 fire-and-forget 落库；不等它跑完，
  // tearDown 的 `db.close()` 会先关库。
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 点一下「今天不再提」。
Future<void> _tapDismiss(WidgetTester tester, Finder dismiss) async {
  // 提示在右轨里，可能落在滚动区内：能滚就滚到可见，再点。
  if (tester.any(
    find.ancestor(of: dismiss, matching: find.byType(Scrollable)),
  )) {
    await tester.ensureVisible(dismiss);
    await tester.pump();
  }
  await tester.tap(dismiss);
  await tester.pump();
}

/// 内存真库 + 真仓储 + 一条「5 天没增量」的项目。
final class _Harness {
  _Harness._(this.container, this.projectId);

  final ProviderContainer container;
  final String projectId;

  /// 种子同 `task57_stall_overdue_test.dart` C1：11-15 最后一次推进，
  /// 今天 11-20 ⇒ 差 5 天 ≥ 门槛 3，稳定命中 1 条停滞。
  static Future<_Harness> create() async {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task57-stall-test');
    final store = ProjectStore(repos);
    final String projectId = await store.createProject(name: '甲');
    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-15',
      progress: '最后一次推进',
    );
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith((ref) => ref.watch(_fakeToday)),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, projectId);
  }

  /// 挂真机同一套壳（右轨由 `LedgerShell` 装配）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // 面板清单必须显式注入：`LedgerShell.railPanels` 默认空列表，
        // 不传的话右轨只剩「快捷键」，停滞提示根本不渲染。
        child: l10nScope(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) => LedgerShell(
                content: const TodayPage(),
                currentNavId: 'today',
                railPanels: todayRailPanels(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 卸掉界面再挂回去 —— 模拟「今天又打开一次」。
  Future<void> remount(WidgetTester tester) async {
    await _flushTimers(tester);
    await mount(tester);
    await _settle(tester);
  }
}

void main() {
  testWidgets('E1/E2：点「今天不再提」⇒ 消失，同日重挂仍不出现', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = await _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    final Finder row = _stallRow(h.projectId);
    final Finder dismiss = _dismissBtn(h.projectId);
    expect(row, findsOneWidget, reason: '5 天没增量，停滞提示应当出现');
    expect(dismiss, findsOneWidget, reason: '提示上要有「今天不再提」');

    await _tapDismiss(tester, dismiss);
    expect(row, findsNothing, reason: 'E1：点完当帧就该消失');

    await h.remount(tester);
    expect(
      row,
      findsNothing,
      reason: 'E2：同一 today 下重挂仍应被抑制（projectId|today 键生效）',
    );
    await _flushTimers(tester);
  });

  testWidgets('E3：换一天 ⇒ 停滞提示重新出现（按日期粒度抑制）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = await _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    final Finder row = _stallRow(h.projectId);
    expect(row, findsOneWidget, reason: '前提：11-20 应当有停滞提示');

    await _tapDismiss(tester, _dismissBtn(h.projectId));
    expect(row, findsNothing, reason: '前提：先确认抑制确实生效');

    // 同容器、同抑制态，只把「今天」推到 11-21。
    h.container.read(_fakeToday.notifier).state = '2026-11-21';
    await _settle(tester);
    expect(
      row,
      findsOneWidget,
      reason: 'E3：换一天必须重新提醒 —— 抑制只到当天为止，不是永久静音',
    );
    await _flushTimers(tester);
  });

  testWidgets('E4（负控）：同一天没点按钮 ⇒ 重挂后仍提示', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = await _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    final Finder row = _stallRow(h.projectId);
    expect(row, findsOneWidget);

    await h.remount(tester);
    expect(
      row,
      findsOneWidget,
      reason: 'E4：没点过「今天不再提」就不该被抑制',
    );
    await _flushTimers(tester);
  });
}
