// =============================================================================
// B16 项 5 / 项 7 · 目标页录入行 + 拖拽落点
// =============================================================================
// 本文件钉住两件事：
//  1. **项 5**：周/月/年三页都不再渲染「滚动候选」段头卡；只是渲染不写库。
//  2. **项 7**：周页 + 月页「本*目标」卡底部的常驻录入行（输入框 + 「+」）——
//     回车或点击即落库、输入清空、焦点保留；上游面板拖来的 `goal://<id>` 落到
//     录入行 ⇒ 悬停有可见落点提示，松手即落库（并挂上 `serves` 链）；点标题可
//     就地改名。
//
// 测试接**真库**（内存 drift）：判据是「库里的真实行」，不是 UI 像素。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_month_page.dart';
import 'package:actlog/src/pages/goals_week_page.dart';
import 'package:actlog/src/pages/goals_year_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_upstream_panel.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 本周（`todayProvider` 固定成 2026-11-25 ⇒ ISO 2026 年第 48 周）。
final GoalPeriod _week = GoalPeriod.week(2026, 48);

/// 本月。
final GoalPeriod _month = GoalPeriod.month(2026, 11);

/// 本年。
final GoalPeriod _year = GoalPeriod.year(2026);

/// 挂一个页面（自带 MaterialApp + ProviderScope，只补一层 l10n）。
Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required ActLogRepositories repos,
  Size size = const Size(1400, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(
              AppPreferences.defaults,
            ),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(body: SingleChildScrollView(child: page)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 把 `goal://<id>` 从上游面板拖到 `target`，返回是否观察到落点提示。
Future<bool> _dragOnto(
  WidgetTester tester, {
  required Finder source,
  required Finder target,
  required Finder hint,
}) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(source),
  );
  await gesture.moveBy(const Offset(20, 0));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  final bool hinted = tester.any(hint);
  await gesture.up();
  await tester.pumpAndSettle();
  return hinted;
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b16-goal-input-drag-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('周页录入行：点「+」落库一条本周目标，输入清空且焦点保留',
      (WidgetTester tester) async {
    final int before = (await store.listGoals()).length;
    await _pump(tester, const GoalsWeekPage(), repos: repos,
        size: const Size(1300, 2400));

    final Finder input = find.byKey(const ValueKey<String>('goal-week-input'));
    final Finder add = find.byKey(
      const ValueKey<String>('goal-week-input-add'),
    );
    expect(
      find.byKey(const ValueKey<String>('goal-week-input-row')),
      findsOneWidget,
      reason: '「本周目标」卡底部要有常驻录入行',
    );
    expect(input, findsOneWidget);
    expect(add, findsOneWidget);
    // 录入行不是拖拽热区独占的：未悬停时没有落点提示。
    expect(
      find.byKey(const ValueKey<String>('goal-week-drop-hint')),
      findsNothing,
    );

    await tester.enterText(input, '  写周报初稿  ');
    await tester.tap(add);
    await tester.pumpAndSettle();

    final List<GoalRow> rows = await store.listGoals();
    expect(rows.length, before + 1, reason: '点「+」应立刻落库');
    final GoalRow created = rows.firstWhere(
      (GoalRow goal) => goal.title == '写周报初稿',
    );
    expect(created.kind, GoalKind.weekly);
    expect(created.status, GoalStatus.active);
    expect(
      created.periodStart,
      _week.startMillis,
      reason: '录入的目标要落在本周口径上',
    );

    final TextField field = tester.widget<TextField>(input);
    expect(field.controller?.text, isEmpty, reason: '提交后输入框清空');
    expect(field.focusNode?.hasFocus, isTrue, reason: '提交后焦点留在录入行');
  });

  testWidgets('周页录入行：回车也落库；纯空白不落库',
      (WidgetTester tester) async {
    final int before = (await store.listGoals()).length;
    await _pump(tester, const GoalsWeekPage(), repos: repos,
        size: const Size(1300, 2400));

    final Finder input = find.byKey(const ValueKey<String>('goal-week-input'));
    await tester.enterText(input, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect((await store.listGoals()).length, before, reason: '纯空白不落库');

    await tester.enterText(input, '周会纪要');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final List<GoalRow> rows = await store.listGoals();
    expect(rows.length, before + 1, reason: '回车即落库');
    expect(
      rows.any((GoalRow goal) => goal.title == '周会纪要'),
      isTrue,
    );
  });

  testWidgets('周页：上游月目标拖到录入行 ⇒ 落点提示 + 松手落库并挂 serves 链',
      (WidgetTester tester) async {
    final String monthlyId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '本月主攻',
      periodStart: _month.startMillis,
      periodEnd: _month.endMillis,
    );
    final int before = (await store.listGoals()).length;
    await _pump(tester, const GoalsWeekPage(), repos: repos,
        size: const Size(1300, 2400));

    final Finder source = find.byKey(
      GoalUpstreamPanel.itemKey(GoalKind.monthly, monthlyId),
    );
    expect(source, findsOneWidget, reason: '右栏应列出本月开着的月目标');
    final Finder hint = find.byKey(
      const ValueKey<String>('goal-week-drop-hint'),
    );

    final bool hinted = await _dragOnto(
      tester,
      source: source,
      target: find.byKey(const ValueKey<String>('goal-week-input-row')),
      hint: hint,
    );
    expect(hinted, isTrue, reason: '悬停在录入行上要给出可见落点提示');
    expect(hint, findsNothing, reason: '落点提示只在悬停期间出现');

    final List<GoalRow> rows = await store.listGoals();
    expect(rows.length, before + 1, reason: '松手即落库');
    final GoalRow derived = rows.firstWhere(
      (GoalRow goal) => goal.kind == GoalKind.weekly && goal.title == '本月主攻',
    );
    expect(derived.status, GoalStatus.draft);
    final List<GoalRow> parents = await store.servedGoals(derived.id);
    expect(
      parents.map((GoalRow goal) => goal.id),
      contains(monthlyId),
      reason: '拖进来的周目标要挂到月目标下（serves 链）',
    );
  });

  testWidgets('月页录入行：点「+」落库一条本月目标并清空输入',
      (WidgetTester tester) async {
    final int before = (await store.listGoals()).length;
    await _pump(tester, const GoalsMonthPage(), repos: repos);

    final Finder input = find.byKey(const ValueKey<String>('goal-month-input'));
    expect(
      find.byKey(const ValueKey<String>('goal-month-input-row')),
      findsOneWidget,
      reason: '「本月目标」卡底部要有常驻录入行',
    );
    await tester.enterText(input, ' 本月补三篇复盘 ');
    await tester.tap(find.byKey(const ValueKey<String>('goal-month-input-add')));
    await tester.pumpAndSettle();

    final List<GoalRow> rows = await store.listGoals();
    expect(rows.length, before + 1, reason: '点「+」应立刻落库');
    final GoalRow created = rows.firstWhere(
      (GoalRow goal) => goal.title == '本月补三篇复盘',
    );
    expect(created.kind, GoalKind.monthly);
    expect(created.status, GoalStatus.active);
    expect(created.periodStart, _month.startMillis);
    expect(
      tester.widget<TextField>(input).controller?.text,
      isEmpty,
      reason: '提交后输入框清空',
    );
  });

  testWidgets('月页：年目标拖到录入行 ⇒ 落点提示 + 松手落库并挂 serves 链',
      (WidgetTester tester) async {
    final String yearlyId = await store.createGoal(
      kind: GoalKind.yearly,
      title: '年度主攻',
      periodStart: _year.startMillis,
      periodEnd: _year.endMillis,
    );
    final int before = (await store.listGoals()).length;
    await _pump(tester, const GoalsMonthPage(), repos: repos);

    final Finder source = find.byKey(
      GoalUpstreamPanel.itemKey(GoalKind.yearly, yearlyId),
    );
    expect(source, findsOneWidget, reason: '右栏应列出本年开着的年目标');
    final Finder hint = find.byKey(
      const ValueKey<String>('goal-month-drop-hint'),
    );

    final bool hinted = await _dragOnto(
      tester,
      source: source,
      target: find.byKey(const ValueKey<String>('goal-month-input-row')),
      hint: hint,
    );
    expect(hinted, isTrue, reason: '悬停在录入行上要给出可见落点提示');
    expect(hint, findsNothing);

    final List<GoalRow> rows = await store.listGoals();
    expect(rows.length, before + 1, reason: '松手即落库');
    final GoalRow derived = rows.firstWhere(
      (GoalRow goal) => goal.kind == GoalKind.monthly && goal.title == '年度主攻',
    );
    expect(derived.status, GoalStatus.draft);
    final List<GoalRow> parents = await store.servedGoals(derived.id);
    expect(
      parents.map((GoalRow goal) => goal.id),
      contains(yearlyId),
      reason: '拖进来的月目标要挂到年目标下（serves 链）',
    );
  });

  testWidgets('周页 / 月页：点标题就地改名，回车提交写回库',
      (WidgetTester tester) async {
    final String weekId = await store.createGoal(
      kind: GoalKind.weekly,
      title: '旧周标题',
      periodStart: _week.startMillis,
      periodEnd: _week.endMillis,
    );
    await _pump(tester, const GoalsWeekPage(), repos: repos,
        size: const Size(1300, 2400));

    final Finder weekTitle = find.byKey(
      ValueKey<String>('goal-week-title-$weekId'),
    );
    expect(weekTitle, findsOneWidget);
    await tester.tap(weekTitle);
    await tester.pump();
    final Finder weekEdit = find.byKey(
      ValueKey<String>('goal-week-title-edit-$weekId'),
    );
    expect(weekEdit, findsOneWidget, reason: '点标题应就地变成输入框');
    await tester.enterText(weekEdit, '新周标题');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      (await store.listGoals())
          .firstWhere((GoalRow goal) => goal.id == weekId)
          .title,
      '新周标题',
    );

    final String monthId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '旧月标题',
      periodStart: _month.startMillis,
      periodEnd: _month.endMillis,
    );
    await _pump(tester, const GoalsMonthPage(), repos: repos);

    final Finder monthTitle = find.byKey(
      ValueKey<String>('goal-month-title-$monthId'),
    );
    expect(monthTitle, findsOneWidget);
    await tester.tap(monthTitle);
    await tester.pump();
    final Finder monthEdit = find.byKey(
      ValueKey<String>('goal-month-title-edit-$monthId'),
    );
    expect(monthEdit, findsOneWidget, reason: '点标题应就地变成输入框');
    await tester.enterText(monthEdit, '新月标题');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      (await store.listGoals())
          .firstWhere((GoalRow goal) => goal.id == monthId)
          .title,
      '新月标题',
    );
  });

  testWidgets('三页都没有「滚动候选」段头卡，且只渲染不写库',
      (WidgetTester tester) async {
    // 三条都会成为旧的「滚动候选」（未完成、非 draft）⇒ 界面必须装作没看见。
    await store.createGoal(
      kind: GoalKind.weekly,
      title: '上周没收尾',
      periodStart: _week.startMillis,
      periodEnd: _week.endMillis,
    );
    final String monthlyId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '本月没收尾',
      periodStart: _month.startMillis,
      periodEnd: _month.endMillis,
    );
    final String yearlyId = await store.createGoal(
      kind: GoalKind.yearly,
      title: '本年没收尾',
      periodStart: _year.startMillis,
      periodEnd: _year.endMillis,
    );
    final int before = (await store.listGoals()).length;
    final AppLocalizations zh = AppLocalizations.zh;

    for (final Widget page in <Widget>[
      const GoalsWeekPage(),
      const GoalsMonthPage(),
      const GoalsYearPage(),
    ]) {
      await _pump(tester, page, repos: repos);
      expect(
        find.text(zh.goalsDraftSection),
        findsNothing,
        reason: 'B16 项 5：滚动候选段头卡整块撤掉',
      );
      expect(find.text(zh.goalsDraftEmpty), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('goals-draft-confirm')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey<String>('goal-month-candidate-$monthlyId')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey<String>('goal-year-candidate-$yearlyId')),
        findsNothing,
      );
    }

    // 只是渲染 ⇒ 库里 0 增量。
    expect((await store.listGoals()).length, before);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}