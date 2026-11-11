// apps/desktop/test/nav_shortcut_test.dart
//
// Task 20（裁定 K7 / K8）+ B2（2026-11-12 T10）守 `Ctrl+1…4` 切页：
//  - `Ctrl+1` 今日 / `Ctrl+2` 待办池 / `Ctrl+3` 习惯 / `Ctrl+4` 日历（A8）；
//  - `Ctrl+5/6` **零效果**（不切页、不报错）——项目 / 设置两项在
//    `kShellNavItems` 里是 `enabled: false`（无落点），宣称到 6 就是假提示（A9）；
//  - 在待办池页按 `Ctrl+1` 回到今日页（A10）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/pages/habits_page.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

/// 内存真库 + 真仓储 + 固定今天。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'nav-shortcut-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 挂完整壳宿主（导航与快捷键都在壳里）。
  Future<void> mountHost(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ShellHost()),
      ),
    );
  }
}

/// 撑高测试面：三个页面都比默认视口高。
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

/// 壳自己的焦点节点（`Shortcuts` 靠焦点节点收键）。
FocusNode _shellFocusNode(WidgetTester tester) {
  final List<Focus> ancestors = tester
      .widgetList<Focus>(
        find.ancestor(
          of: find.byType(LedgerShell),
          matching: find.byType(Focus),
        ),
      )
      .toList(growable: false);
  final Focus shell = ancestors.firstWhere(
    (Focus focus) => focus.canRequestFocus,
    orElse: () => throw StateError('壳宿主必须自带一个可请求焦点的节点'),
  );
  return shell.focusNode!;
}

/// 模拟 `Ctrl+<key>`：按下 Ctrl → 敲键 → 松开 Ctrl。
Future<void> _sendCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
  await _settle(tester);
}

void main() {
  testWidgets('A8：Ctrl+1 / Ctrl+2 / Ctrl+3 / Ctrl+4 分别切今日 / 待办池 / 习惯 / 日历', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mountHost(tester);
    await _settle(tester);

    expect(find.byType(TodayPage), findsOneWidget);

    _shellFocusNode(tester).requestFocus();
    await tester.pump();

    await _sendCtrl(tester, LogicalKeyboardKey.digit2);
    expect(find.byType(TodoPoolPage), findsOneWidget);
    expect(find.byType(TodayPage), findsNothing);

    await _sendCtrl(tester, LogicalKeyboardKey.digit3);
    expect(find.byType(HabitsPage), findsOneWidget);
    expect(find.byType(TodoPoolPage), findsNothing);

    await _sendCtrl(tester, LogicalKeyboardKey.digit4);
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(find.byType(HabitsPage), findsNothing);

    await _sendCtrl(tester, LogicalKeyboardKey.digit1);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.byType(CalendarPage), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('A9：Ctrl+5 / Ctrl+6 零效果（不切页、不报错）', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mountHost(tester);
    await _settle(tester);

    _shellFocusNode(tester).requestFocus();
    await tester.pump();

    for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
    ]) {
      await _sendCtrl(tester, key);
      expect(find.byType(TodayPage), findsOneWidget, reason: '$key 不许切页');
      expect(find.byType(TodoPoolPage), findsNothing);
      expect(find.byType(HabitsPage), findsNothing);
      expect(find.byType(CalendarPage), findsNothing);
      expect(tester.takeException(), isNull, reason: '$key 不许抛异常');
    }

    await _flushTimers(tester);
  });

  testWidgets('A10：在待办池页按 Ctrl+1 回到今日页', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mountHost(tester);
    await _settle(tester);

    _shellFocusNode(tester).requestFocus();
    await tester.pump();

    await _sendCtrl(tester, LogicalKeyboardKey.digit2);
    expect(find.byType(TodoPoolPage), findsOneWidget);

    // 切页后不再手工聚焦：壳自己把焦点收回壳节点，快捷键必须仍然可用。
    await _sendCtrl(tester, LogicalKeyboardKey.digit1);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.byType(TodoPoolPage), findsNothing);

    await _flushTimers(tester);
  });
}
