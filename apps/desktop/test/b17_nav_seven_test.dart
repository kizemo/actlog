// apps/desktop/test/b17_nav_seven_test.dart
//
// B17 判别性测试：左导航由 B16 的 8 项收回 **7 项** ——
//   01 日志 / 02 待办 / 03 蓝图 / 04 目标 / 05 项目 / 06 学习管理 / 07 日历
//
// 本批两件事，各锁一组断言：
//  1. 「习惯」退出导航清单：常量与运行期清单里都没有 `habits`，
//     竖排不再渲染 03「习惯」/ 也不再多出 `08`；
//  2. 「学习」改称「学习管理」：中文值 `学习管理`、英文值 `Learning Management`，
//     且它落在 06，快捷键 `Ctrl+6` 才落到占位。
//
// 与既有文件的分工（不重复锁同一件事）：
//  - `b16_nav_learning_test.dart` 只保留「学习项有真实落点 + 页面映射没变」；
//  - `shell_nav_rail_test.dart` 锁渲染细节（序号几何、选中态、可点性）；
//  - 本文件锁 **7 项整序 + 快捷键逐位重排**（B17 的判别点）。
//
// 判别性：把「习惯」加回清单 / 漏改 l10n / 快捷键表仍从 digit8 起算，
// 本文件都会红 —— 断言直接读实现的常量、运行期清单与真实按键落点。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/pages/goals_page.dart';
import 'package:actlog/src/pages/habits_page.dart';
import 'package:actlog/src/pages/projects_page.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';

/// B17 的七项：id 与中文标签，逐字序（**顺序即编号**）。
const List<String> _ids = <String>[
  'today',
  'inbox',
  'blueprint',
  'goals',
  'projects',
  'learning',
  'calendar',
];
const List<String> _zhLabels = <String>[
  '日志',
  '待办池',
  '蓝图',
  '目标',
  '项目',
  '学习管理',
  '日历',
];

/// 内存真库 + 真仓储 + 固定今天（与 `nav_shortcut_test.dart` 同一形状）。
final class _Harness {
  _Harness._(this.container);

  final ProviderContainer container;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'b17-nav-seven-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container);
  }

  Future<void> mountHost(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nScope(const MaterialApp(home: ShellHost())),
      ),
    );
  }
}

/// 撑高测试面：壳里的页面都比默认 800×600 高。
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

/// 孤立挂一个竖排 `NavRail`（走真实主题 + 指定语言）。
Future<void> _pumpRail(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.zh,
}) async {
  tester.view.physicalSize = const Size(1300, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    l10nScope(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: NavRail.width,
              height: 900,
              child: const NavRail(),
            ),
          ),
        ),
      ),
      language: language,
    ),
  );
}

void main() {
  group('B17 导航收紧到 7 项', () {
    test('常量七项逐字序，且没有 habits 这一项', () {
      expect(kShellNavItems.length, 7, reason: 'B17 起导航是 7 项（B16 的 8 项已收回）');
      expect(
        kShellNavItems.map((ShellNavItem i) => i.id).toList(growable: false),
        _ids,
      );
      expect(
        kShellNavItems.map((ShellNavItem i) => i.label).toList(growable: false),
        _zhLabels,
      );
      expect(
        kShellNavItems.map((ShellNavItem i) => i.id),
        isNot(contains('habits')),
        reason: '「习惯」退出导航清单（页面与 `habits` 映射仍保留）',
      );
      // 序号是 index 自动生成的，7 项就必须正好吃到 01–07。
      expect(kShellNavItems.last.label, '日历');
      expect(kShellNavItems.first.label, '日志');
    });

    test('运行期清单 zh/en 同 id 同序；学习管理中文/英文都不是旧值', () {
      final List<ShellNavItem> zh = shellNavItemsFor(AppLocalizations.zh);
      expect(zh.length, 7);
      expect(zh.map((ShellNavItem i) => i.id).toList(growable: false), _ids);
      expect(
        zh.map((ShellNavItem i) => i.label).toList(growable: false),
        _zhLabels,
        reason: 'zh 态必须与常量逐字一致（常量是中文快照）',
      );
      expect(zh[5].id, 'learning');
      expect(zh[5].label, '学习管理');

      final List<ShellNavItem> en = shellNavItemsFor(AppLocalizations.en);
      expect(en.length, 7);
      expect(
        en.map((ShellNavItem i) => i.id).toList(growable: false),
        _ids,
        reason: '语言不影响 id 与顺序',
      );
      expect(en[5].id, 'learning');
      expect(en[5].label, 'Learning Management');
      expect(en[5].label, isNot('学习'));
      expect(en[5].label, isNot(zh[5].label));
      expect(en[6].label, AppLocalizations.en.shellNavCalendar);
      // 「习惯」不在任何一门语言的清单里。
      expect(
        <ShellNavItem>[...zh, ...en].map((ShellNavItem i) => i.id),
        isNot(contains('habits')),
      );
    });

    testWidgets('竖排渲染 01–07：无 03 习惯、无 08，学习管理在 06', (
      WidgetTester tester,
    ) async {
      await _pumpRail(tester);

      for (var i = 1; i <= 7; i++) {
        final String index = i.toString().padLeft(2, '0');
        expect(find.text(index), findsOneWidget, reason: '缺少序号 $index');
      }
      for (final String label in _zhLabels) {
        expect(find.text(label), findsOneWidget, reason: '缺少导航项「$label」');
      }
      // 旧口径的两个痕迹必须消失：03 的习惯、第 8 项。
      expect(find.text('习惯'), findsNothing, reason: '「习惯」已退出导航清单');
      expect(find.text('学习'), findsNothing, reason: '「学习」已改称「学习管理」');
      expect(find.text('08'), findsNothing);

      final double y05 = tester.getCenter(find.text('05')).dy;
      final double y06 = tester.getCenter(find.text('06')).dy;
      final double y07 = tester.getCenter(find.text('07')).dy;
      expect(y05, lessThan(y06), reason: '06「学习管理」必须排在 05「项目」之后');
      expect(y06, lessThan(y07), reason: '06「学习管理」必须排在 07「日历」之前');
      expect(tester.takeException(), isNull);
    });

    testWidgets('英文态竖排 7 项且第 06 项是 Learning Management', (
      WidgetTester tester,
    ) async {
      await _pumpRail(tester, language: AppLanguage.en);

      expect(find.text('Learning Management'), findsOneWidget);
      expect(find.text('学习管理'), findsNothing);
      expect(find.text('习惯'), findsNothing);
      expect(find.text('06'), findsOneWidget);
      expect(find.text('08'), findsNothing);
    });

    test('键条 10 条仍成立，但切页区间收成 Ctrl+1…7', () {
      expect(kShellKeyHints.length, 10, reason: '条数不变，只改键帽与落点');
      expect(kShellKeyHints[6].keys, <String>['Ctrl+1…7']);
      expect(kShellKeyHints[6].label, '切页');
      // 三条单条提示跟着 B17 序位前移一位。
      expect(kShellKeyHints[7].keys, <String>['Ctrl+3']);
      expect(kShellKeyHints[7].label, '切到蓝图');
      expect(kShellKeyHints[8].keys, <String>['Ctrl+4']);
      expect(kShellKeyHints[8].label, '切到目标');
      expect(kShellKeyHints[9].keys, <String>['Ctrl+5']);
      expect(kShellKeyHints[9].label, '切到项目');

      // 旧值不许以任何形式残留。
      final List<String> keys = kShellKeyHints
          .expand((ShellKeyHint h) => h.keys)
          .toList(growable: false);
      expect(keys, isNot(contains('Ctrl+1…8')));
      expect(keys, isNot(contains('Ctrl+6')), reason: '单条提示不再宣称 Ctrl+6');
      expect(keys, isNot(contains('Ctrl+7')), reason: '单条提示不再宣称 Ctrl+7');

      // 运行期英文态同形：只换文案，不换键帽。
      final List<ShellKeyHint> en = shellKeyHintsFor(AppLocalizations.en);
      expect(en.length, 10);
      expect(
        en.map((ShellKeyHint h) => h.keys).toList(growable: false),
        kShellKeyHints.map((ShellKeyHint h) => h.keys).toList(growable: false),
      );
      expect(en[7].label, AppLocalizations.en.shellKeyGoBlueprint);
      expect(en[9].label, AppLocalizations.en.shellKeyGoProjects);
    });
  });

  group('B17 快捷键逐位重排', () {
    testWidgets('Ctrl+3…7 逐位落到 蓝图 / 目标 / 项目 / 学习管理 / 日历', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mountHost(tester);
      await _settle(tester);

      expect(find.byType(TodayPage), findsOneWidget);
      _shellFocusNode(tester).requestFocus();
      await tester.pump();

      // 03 = 蓝图（B16 的 Ctrl+3 是「习惯」）。
      await _sendCtrl(tester, LogicalKeyboardKey.digit3);
      expect(find.byType(GoalsBlueprintPage), findsOneWidget);
      expect(find.byType(HabitsPage), findsNothing, reason: 'Ctrl+3 不再切到习惯页');
      expect(find.byType(TodayPage), findsNothing);

      // 04 = 目标。
      await _sendCtrl(tester, LogicalKeyboardKey.digit4);
      expect(find.byType(GoalsPage), findsOneWidget);
      expect(find.byType(GoalsBlueprintPage), findsNothing);
      expect(find.byType(HabitsPage), findsNothing);

      // 05 = 项目。
      await _sendCtrl(tester, LogicalKeyboardKey.digit5);
      expect(find.byType(ProjectsPage), findsOneWidget);
      expect(find.byType(GoalsPage), findsNothing);
      expect(find.byType(HabitsPage), findsNothing);

      // 06 = 学习管理（占位有稳定 ValueKey）。
      await _sendCtrl(tester, LogicalKeyboardKey.digit6);
      expect(
        find.byKey(const ValueKey<String>('learning-placeholder')),
        findsOneWidget,
      );
      expect(find.byType(ProjectsPage), findsNothing);
      expect(find.byType(HabitsPage), findsNothing);

      // 07 = 日历。
      await _sendCtrl(tester, LogicalKeyboardKey.digit7);
      expect(find.byType(CalendarPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('learning-placeholder')),
        findsNothing,
      );
      expect(find.byType(HabitsPage), findsNothing);
      expect(tester.takeException(), isNull);

      await _flushTimers(tester);
    });

    testWidgets('Ctrl+1 / Ctrl+2 不变；Ctrl+8 没有绑定，停在原页且不抛异常', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mountHost(tester);
      await _settle(tester);

      _shellFocusNode(tester).requestFocus();
      await tester.pump();

      await _sendCtrl(tester, LogicalKeyboardKey.digit2);
      expect(find.byType(TodoPoolPage), findsOneWidget);
      expect(find.byType(TodayPage), findsNothing);

      await _sendCtrl(tester, LogicalKeyboardKey.digit1);
      expect(find.byType(TodayPage), findsOneWidget);
      expect(find.byType(TodoPoolPage), findsNothing);

      // 先离开今日页，避免「本来就在今日页」掩盖 Ctrl+8 的无效性。
      await _sendCtrl(tester, LogicalKeyboardKey.digit7);
      expect(find.byType(CalendarPage), findsOneWidget);

      // B17 起只有 digit1..7：digit8 无绑定 ⇒ 页面不动、不报错、也不落到日历以外。
      await _sendCtrl(tester, LogicalKeyboardKey.digit8);
      expect(find.byType(CalendarPage), findsOneWidget, reason: 'Ctrl+8 不应再切页');
      expect(find.byType(HabitsPage), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Ctrl+8 不许抛异常');

      await _flushTimers(tester);
    });
  });
}