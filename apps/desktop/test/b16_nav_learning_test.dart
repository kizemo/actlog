// apps/desktop/test/b16_nav_learning_test.dart
//
// B16 判别性测试：左导航新增「学习」占位项，并按序位重排为
//   01 日志 / 02 待办 / 03 习惯 / 04 蓝图 / 05 目标 / 06 项目 / 07 学习 / 08 日历
//
// 与既有用例的分工（避免重复锁同一件事）：
//  - `shell_nav_rail_test.dart` 锁渲染细节（序号几何、选中态、可点性）；
//  - `nav_shortcut_test.dart` 锁 Ctrl 落点；
//  - 本文件锁「八项顺序 + 学习有真实落点 + 既有七项页面映射没变」。
//
// 判别性：改回 7 项旧序 / 删掉「学习」/ 把占位换成禁用项，本文件必红 ——
// 三条断言都直接读实现（常量、运行期清单、占位 ValueKey），不是「跑通即过」。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';

/// B16 的八项：id 与中文标签，逐字序（**顺序即编号**）。
const List<String> _ids = <String>[
  'today',
  'inbox',
  'habits',
  'blueprint',
  'goals',
  'projects',
  'learning',
  'calendar',
];
const List<String> _zhLabels = <String>[
  '日志',
  '待办池',
  '习惯',
  '蓝图',
  '目标',
  '项目',
  '学习',
  '日历',
];

/// 内存真库 + 真仓储 + 固定今天（与 `nav_shortcut_test.dart` 同一形状）。
final class _Harness {
  _Harness._(this.container);

  final ProviderContainer container;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'b16-nav-learning-test');
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

/// 只点左导航里的那一项 —— 页面正文里也可能出现同名文字。
Finder _navItem(String label) => find.descendant(
  of: find.byType(NavRail),
  matching: find.text(label),
);

/// 孤立挂一个竖排 `NavRail`（走真实主题 + 指定语言）。
Future<void> _pumpRail(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.zh,
  ValueChanged<String>? onSelected,
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
              child: NavRail(onSelected: onSelected),
            ),
          ),
        ),
      ),
      language: language,
    ),
  );
}

void main() {
  group('B16 左导航「学习」占位项', () {
    test('常量八项逐字序：日志 / 待办池 / 习惯 / 蓝图 / 目标 / 项目 / 学习 / 日历', () {
      expect(kShellNavItems.length, _ids.length, reason: 'B16 起是 8 项，不是旧 7 项');
      expect(
        kShellNavItems.map((ShellNavItem i) => i.id).toList(growable: false),
        _ids,
      );
      expect(
        kShellNavItems.map((ShellNavItem i) => i.label).toList(growable: false),
        _zhLabels,
      );
      // 「学习」是可点击占位（计划 §4 的另一种实现），不是禁用项：
      // 只有可点击，`Ctrl+7` 才有真实落点，键条的 `Ctrl+1…8` 才成立。
      expect(
        kShellNavItems.where((ShellNavItem i) => !i.enabled).toList(),
        isEmpty,
        reason: '八项都必须启用；「学习」也不许退化成禁用占位',
      );
    });

    test('运行期清单与常量同 id 同序；英文态「学习」= Learning', () {
      final List<ShellNavItem> zh = shellNavItemsFor(AppLocalizations.zh);
      expect(zh.length, _ids.length);
      expect(zh.map((ShellNavItem i) => i.id).toList(growable: false), _ids);
      expect(
        zh.map((ShellNavItem i) => i.label).toList(growable: false),
        _zhLabels,
        reason: 'zh 态必须与常量逐字一致（常量是中文快照）',
      );

      final List<ShellNavItem> en = shellNavItemsFor(AppLocalizations.en);
      expect(en.length, _ids.length);
      expect(
        en.map((ShellNavItem i) => i.id).toList(growable: false),
        _ids,
        reason: '语言不影响 id 与顺序',
      );
      expect(en[6].id, 'learning');
      expect(en[6].label, 'Learning');
      expect(en[7].label, AppLocalizations.en.shellNavCalendar);
      // 中文那条占位文案换到英文时真的变了（不是漏翻）。
      expect(en[6].label, isNot(zh[6].label));
    });

    testWidgets('竖排渲染 01–08，「学习」在 06 与 08 之间', (WidgetTester tester) async {
      await _pumpRail(tester);

      for (final String index in <String>[
        '01',
        '02',
        '03',
        '04',
        '05',
        '06',
        '07',
        '08',
      ]) {
        expect(find.text(index), findsOneWidget, reason: '缺少序号 $index');
      }
      expect(find.text('学习'), findsOneWidget);

      // 只判「存在」不够：用 y 坐标证明 07 真的排在 06 与 08 之间。
      final double y06 = tester.getCenter(find.text('06')).dy;
      final double y07 = tester.getCenter(find.text('07')).dy;
      final double y08 = tester.getCenter(find.text('08')).dy;
      expect(y06, lessThan(y07), reason: '07「学习」必须排在 06「项目」之后');
      expect(y07, lessThan(y08), reason: '07「学习」必须排在 08「日历」之前');

      // 旧 7 项没有 09 这种溢出序号。
      expect(find.text('09'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('英文态竖排渲染 Learning（不是中文「学习」）', (WidgetTester tester) async {
      await _pumpRail(tester, language: AppLanguage.en);

      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('学习'), findsNothing);
      expect(find.text('07'), findsOneWidget);
    });

    testWidgets('点「学习」回调 id = learning（可点击占位）', (WidgetTester tester) async {
      final List<String> tapped = <String>[];
      await _pumpRail(tester, onSelected: tapped.add);

      await tester.tap(find.text('学习'));
      await tester.pump();

      expect(tapped, <String>['learning']);
    });
  });

  group('B16 壳宿主落点', () {
    testWidgets('点「学习」→ 占位内容体；点「日志」→ 回今日页', (WidgetTester tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mountHost(tester);
      await _settle(tester);

      expect(find.byType(TodayPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('learning-placeholder')),
        findsNothing,
      );

      await tester.tap(_navItem('学习'));
      await _settle(tester);

      // 占位落点：有稳定 ValueKey，且正文文案取的是同一份 l10n。
      expect(
        find.byKey(const ValueKey<String>('learning-placeholder')),
        findsOneWidget,
      );
      expect(find.byType(TodayPage), findsNothing);
      // 「学习」出现两次 = 导航项 + 占位正文，正好证明占位真的渲染了文案。
      expect(find.text('学习'), findsNWidgets(2));
      expect(tester.takeException(), isNull, reason: '点「学习」不许抛异常');

      await tester.tap(_navItem('日志'));
      await _settle(tester);
      expect(find.byType(TodayPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('learning-placeholder')),
        findsNothing,
      );

      await _flushTimers(tester);
    });

    testWidgets('既有页面映射不变：待办池 / 蓝图 / 日历', (WidgetTester tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mountHost(tester);
      await _settle(tester);

      await tester.tap(_navItem('待办池'));
      await _settle(tester);
      expect(find.byType(TodoPoolPage), findsOneWidget);

      await tester.tap(_navItem('蓝图'));
      await _settle(tester);
      expect(find.byType(GoalsBlueprintPage), findsOneWidget);
      expect(find.byType(TodoPoolPage), findsNothing);

      await tester.tap(_navItem('日历'));
      await _settle(tester);
      expect(find.byType(CalendarPage), findsOneWidget);
      expect(find.byType(GoalsBlueprintPage), findsNothing);
      expect(tester.takeException(), isNull);

      await _flushTimers(tester);
    });
  });
}