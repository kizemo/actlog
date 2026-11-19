// apps/desktop/test/task45_removed_entries_test.dart
//
// Task 45 · W3 · 需求 4：「＋ 从待办池捞」入口必须从今日页消失。
//
// 证据口径（`AGENTS.md` R5）：钉**结构事实**，不钉像素。
//   - 今日页渲染后 `plan-pool-entry` 这个 key 与「从待办池捞」文案都命中 0；
//   - 同一条用例里 `day-grid` 与「手写一条」必须命中 —— 否则「找不到」
//     可能只是整页没渲染出来，断言就变成空过（falsifiability）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

final class _Harness {
  _Harness._(this.container);

  final ProviderContainer container;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task45-removed-entries-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container);
  }

  Future<void> mount(WidgetTester tester) {
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

/// 撑高测试面：整页竖排，默认 800×600 会溢出。
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
  testWidgets('今日页不再有「＋ 从待办池捞」入口，方格与手写条仍在',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    // ① 先证明这一页真的渲染出来了：否则下面的 `findsNothing` 是空过。
    expect(
      find.byKey(const ValueKey<String>('day-grid')),
      findsOneWidget,
      reason: '方格时间轴在，说明 TodayPage 正文确实渲染了',
    );
    // 用 key 而不是「手写一条」文案：底键条里也有两处 `＋ 手写一条` 提示，
    // 按文案断言会命中 3 个（本意是证明手写条这一行在位）。
    expect(
      find.byKey(const ValueKey<String>('add-plan-datetime-button')),
      findsOneWidget,
      reason: '手写条的日期/时刻按钮在，说明正文列走到了它该在的位置',
    );

    // ② 需求 4：入口整块删除 —— key、精确文案、任意含该词的文案都命中 0。
    expect(
      find.byKey(const ValueKey<String>('plan-pool-entry')),
      findsNothing,
      reason: '入口容器的 key 不许留下（留着就是没删干净）',
    );
    expect(find.text('＋ 从待办池捞'), findsNothing);
    expect(
      find.textContaining('从待办池捞'),
      findsNothing,
      reason: '任何形态的「从待办池捞」文案都不许回到今日页',
    );

    await _flushTimers(tester);
  });
}