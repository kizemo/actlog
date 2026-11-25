// =============================================================================
// Task 79 · B9-W3 四级拆分链路（终极 → 远期 → 中期 → 短期 → 年目标 / 待办）
// =============================================================================
// 本文件钉住派工书 `docs\b93-dispatch-w3.md` 的硬判据：
//  1. 拆分按钮 `goal-blueprint-split-<id>` **打开新对话框**，不再进页内队列；
//  2. 点「确认」**直接写库**（没有「待确认待办」中间态）；
//  3. 终极 → 远期 / 远期 → 中期 / 中期 → 短期：子目标是蓝图目标，
//     `parent_id` 与 `serves` 链接**双写**（R5 双证）；
//  4. 短期 / 近期 → 年目标或待办：年目标的 `period_start` 精确等于本年起点
//     （`GoalPeriod.year(2026).startMillis`）；待办落池 + 父目标 `tracks` 链接；
//  5. 拆分不改父目标 `status`（只允许 `rev` 自增）；
//  6. 目标类型选择器只在短期 / 近期档出现。
//
// 测试接真库（内存 drift）：判据是库里真实的行与链接，不是 UI 像素。
// 断言只走 ValueKey / find.text（坑 51：桌面测试不预载图标字形）。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink, Todo;
import 'package:core_domain/core_domain.dart'
    show GoalHorizon, GoalKind, GoalPeriod, GoalRelation, GoalTargetType, Todo;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 挂起人生蓝图页（与 task66 同装置：今日固定 2026-11-25 ⇒ 本年 = 2026）。
Future<void> _pumpPage(
  WidgetTester tester, {
  required ActLogRepositories repos,
  String instance = 'split-1',
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
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
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(key: ValueKey<String>(instance)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 造一条蓝图目标。
Future<String> _seedBlueprint(
  GoalStore store,
  String title,
  GoalHorizon horizon, {
  String domain = 'career',
}) {
  return store.createGoal(
    kind: GoalKind.blueprint,
    title: title,
    domain: domain,
    horizon: horizon,
  );
}

/// 切档位标签页。
Future<void> _switchTab(WidgetTester tester, String horizonKey) async {
  final Finder tab = find.byKey(
    ValueKey<String>('goal-blueprint-tab-$horizonKey'),
  );
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

/// 点卡片右侧的拆分图标（必须**打开对话框**，不再进页内队列）。
Future<void> _openSplit(WidgetTester tester, String goalId) async {
  final Finder split = find.byKey(
    ValueKey<String>('goal-blueprint-split-$goalId'),
  );
  await tester.ensureVisible(split);
  await tester.tap(split);
  await tester.pumpAndSettle();
}

/// 逐行填标题（行号键从 0 起）。
Future<void> _fillTitles(WidgetTester tester, List<String> titles) async {
  for (int i = 0; i < titles.length; i++) {
    await tester.enterText(
      find.byKey(ValueKey<String>('goal-split-title-$i')),
      titles[i],
    );
  }
  await tester.pump();
}

/// 点对话框「确认」。
Future<void> _tapConfirm(WidgetTester tester) async {
  final Finder confirm = find.byKey(
    const ValueKey<String>('goal-split-confirm'),
  );
  await tester.ensureVisible(confirm);
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

/// 父目标的直接下级（行侧证据）。
Future<List<GoalRow>> _childrenOf(GoalStore store, String parentId) async {
  final List<GoalRow> all = await store.listGoals();
  return <GoalRow>[
    for (final GoalRow goal in all)
      if (goal.parentId == parentId) goal,
  ];
}

/// 子目标的 `serves` 链接（链接侧证据）。
Future<void> _expectServes(
  GoalStore store,
  String childId,
  String parentId,
) async {
  final List<GoalLinkRow> links = await store.listLinks(
    childId,
    relation: GoalRelation.serves,
  );
  expect(links.length, 1, reason: '$childId 必须有一条 serves 链接');
  expect(links.single.targetType, GoalTargetType.goal);
  expect(links.single.targetId, parentId);
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task79-split-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('终极拆 3 条远期：行 + serves 双证，远期标签页可见', (
    WidgetTester tester,
  ) async {
    final String parent = await _seedBlueprint(
      store,
      '终极蓝图',
      GoalHorizon.ultimate,
    );
    await _pumpPage(tester, repos: repos);
    await _openSplit(tester, parent);

    // 默认 3 行空输入；终极档不显示「年目标 / 待办」选择器。
    expect(
      find.byKey(const ValueKey<String>('goal-split-title-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-split-title-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-yearly')),
      findsNothing,
      reason: '终极档的下一层由档位推导，不给选择器',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-todo')),
      findsNothing,
    );

    await _fillTitles(tester, <String>['远期一', '远期二', '远期三']);
    await _tapConfirm(tester);

    final List<GoalRow> children = await _childrenOf(store, parent);
    expect(children.length, 3);
    expect(
      <String>{for (final GoalRow child in children) child.title},
      <String>{'远期一', '远期二', '远期三'},
    );
    for (final GoalRow child in children) {
      expect(child.kind, GoalKind.blueprint);
      expect(child.horizon, GoalHorizon.long);
      expect(child.domain, 'career', reason: '子目标继承父目标领域');
      await _expectServes(store, child.id, parent);
    }

    // 落位可见：切到「远期」标签页能看到三条新目标。
    await _switchTab(tester, 'long');
    for (final GoalRow child in children) {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-cell-${child.id}')),
        findsOneWidget,
        reason: '拆出的远期目标要出现在远期标签页',
      );
    }
  });

  testWidgets('远期拆 2 条中期：行 + serves 双证', (WidgetTester tester) async {
    final String parent = await _seedBlueprint(store, '远期蓝图', GoalHorizon.long);
    await _pumpPage(tester, repos: repos);
    await _switchTab(tester, 'long');
    await _openSplit(tester, parent);

    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-todo')),
      findsNothing,
    );
    await _fillTitles(tester, <String>['中期一', '中期二']);
    await _tapConfirm(tester);

    final List<GoalRow> children = await _childrenOf(store, parent);
    expect(children.length, 2);
    for (final GoalRow child in children) {
      expect(child.kind, GoalKind.blueprint);
      expect(child.horizon, GoalHorizon.mid);
      await _expectServes(store, child.id, parent);
    }
  });

  testWidgets('中期拆 2 条短期：行 + serves 双证', (WidgetTester tester) async {
    final String parent = await _seedBlueprint(store, '中期蓝图', GoalHorizon.mid);
    await _pumpPage(tester, repos: repos);
    await _switchTab(tester, 'mid');
    await _openSplit(tester, parent);

    await _fillTitles(tester, <String>['短期一', '短期二']);
    await _tapConfirm(tester);

    final List<GoalRow> children = await _childrenOf(store, parent);
    expect(children.length, 2);
    for (final GoalRow child in children) {
      expect(child.horizon, GoalHorizon.short);
      expect(child.domain, 'career');
      await _expectServes(store, child.id, parent);
    }
  });

  testWidgets('短期拆 2 条年目标：period_start 精确等于本年起点', (
    WidgetTester tester,
  ) async {
    final String parent = await _seedBlueprint(
      store,
      '短期蓝图',
      GoalHorizon.short,
    );
    final GoalPeriod year = GoalPeriod.year(2026);
    await _pumpPage(tester, repos: repos);
    await _switchTab(tester, 'short');
    await _openSplit(tester, parent);

    // 短期档才给「年目标 / 待办」选择器，默认年目标。
    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-yearly')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-todo')),
      findsOneWidget,
    );

    await _fillTitles(tester, <String>['今年主攻一', '今年主攻二']);
    await _tapConfirm(tester);

    final List<GoalRow> children = await _childrenOf(store, parent);
    expect(children.length, 2);
    for (final GoalRow child in children) {
      expect(child.kind, GoalKind.yearly);
      // 年页的判据是 `period_start == 周期起点`，必须是精确等值。
      expect(child.periodStart, year.startMillis);
      expect(child.periodEnd, year.endMillis);
      expect(child.domain, 'career');
      await _expectServes(store, child.id, parent);
    }

    // 年目标与年页同源 ⇒ 短期标签页立刻能看到。
    for (final GoalRow child in children) {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-cell-${child.id}')),
        findsOneWidget,
        reason: '拆出的年目标要落在短期标签页',
      );
    }
  });

  testWidgets('短期拆 2 条待办：落待办池 + 父目标 tracks 链接', (
    WidgetTester tester,
  ) async {
    final String parent = await _seedBlueprint(
      store,
      '短期蓝图',
      GoalHorizon.short,
    );
    await _pumpPage(tester, repos: repos);
    await _switchTab(tester, 'short');
    await _openSplit(tester, parent);

    final Finder todoKind = find.byKey(
      const ValueKey<String>('goal-split-kind-todo'),
    );
    await tester.ensureVisible(todoKind);
    await tester.tap(todoKind);
    await tester.pump();

    await _fillTitles(tester, <String>['本周落地一', '本周落地二']);
    await _tapConfirm(tester);

    final List<Todo> open = await repos.todo.listOpen();
    expect(open.length, 2);
    expect(
      <String>{for (final Todo todo in open) todo.title},
      <String>{'本周落地一', '本周落地二'},
    );

    // 行侧：父目标没多出子目标；链接侧：父目标 2 条 tracks。
    expect((await _childrenOf(store, parent)).length, 0);
    final List<GoalLinkRow> tracks = await store.listLinks(
      parent,
      relation: GoalRelation.tracks,
    );
    expect(tracks.length, 2, reason: '2 条待办都要挂回原目标');
    for (final GoalLinkRow link in tracks) {
      expect(link.targetType, GoalTargetType.todo);
    }
    expect(
      <String>{for (final GoalLinkRow link in tracks) link.targetId},
      <String>{for (final Todo todo in open) todo.id},
    );
  });

  testWidgets('拆分不改父目标状态：status 不变，rev 只允许自增', (
    WidgetTester tester,
  ) async {
    final String parent = await _seedBlueprint(
      store,
      '短期蓝图',
      GoalHorizon.short,
    );
    final GoalRow before = (await store.listGoals()).firstWhere(
      (GoalRow goal) => goal.id == parent,
    );
    await _pumpPage(tester, repos: repos);
    await _switchTab(tester, 'short');
    await _openSplit(tester, parent);

    await _fillTitles(tester, <String>['今年主攻']);
    await _tapConfirm(tester);

    expect((await _childrenOf(store, parent)).length, 1);
    final GoalRow after = (await store.listGoals()).firstWhere(
      (GoalRow goal) => goal.id == parent,
    );
    expect(after.status, before.status, reason: '派生不改父目标状态');
    expect(after.rev, greaterThanOrEqualTo(before.rev));
  });

  testWidgets('全行留空不许确认：给提示且库里 0 增量', (WidgetTester tester) async {
    final String parent = await _seedBlueprint(
      store,
      '终极蓝图',
      GoalHorizon.ultimate,
    );
    await _pumpPage(tester, repos: repos);
    await _openSplit(tester, parent);

    await _tapConfirm(tester);

    // 对话框还在（没 pop），并显示空行提示。
    expect(
      find.byKey(const ValueKey<String>('goal-split-confirm')),
      findsOneWidget,
    );
    // 文案与 `goalSplitDialogEmptyRow`（zh）逐字一致；这里用字面量断言，
    // 让本测试在键尚未新增时就以**断言失败**（而不是编译失败）变红。
    expect(find.text('至少填写一行子目标'), findsOneWidget);
    expect((await _childrenOf(store, parent)).length, 0);
  });

  testWidgets('可增行 / 删行：add-row 出第 4 行，remove-0 让第 1 行消失', (
    WidgetTester tester,
  ) async {
    final String parent = await _seedBlueprint(
      store,
      '终极蓝图',
      GoalHorizon.ultimate,
    );
    await _pumpPage(tester, repos: repos);
    await _openSplit(tester, parent);

    final Finder addRow = find.byKey(
      const ValueKey<String>('goal-split-add-row'),
    );
    await tester.ensureVisible(addRow);
    await tester.tap(addRow);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('goal-split-title-3')),
      findsOneWidget,
    );

    final Finder removeFirst = find.byKey(
      const ValueKey<String>('goal-split-remove-0'),
    );
    await tester.ensureVisible(removeFirst);
    await tester.tap(removeFirst);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('goal-split-title-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-split-title-3')),
      findsOneWidget,
    );
  });

  testWidgets('取消 ⇒ 对话框关闭且库里 0 增量', (WidgetTester tester) async {
    final String parent = await _seedBlueprint(
      store,
      '终极蓝图',
      GoalHorizon.ultimate,
    );
    await _pumpPage(tester, repos: repos);
    await _openSplit(tester, parent);
    await _fillTitles(tester, <String>['不会落库']);

    final Finder cancel = find.byKey(
      const ValueKey<String>('goal-split-cancel'),
    );
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('goal-split-confirm')),
      findsNothing,
    );
    expect((await _childrenOf(store, parent)).length, 0);
    expect((await repos.todo.listOpen()).length, 0);
  });

  testWidgets('近期档与短期同口径：同样给「年目标 / 待办」选择器', (
    WidgetTester tester,
  ) async {
    final String parent = await _seedBlueprint(store, '一年蓝图', GoalHorizon.near);
    await _pumpPage(tester, repos: repos);
    await _switchTab(tester, 'short');
    await _openSplit(tester, parent);

    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-yearly')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-split-kind-todo')),
      findsOneWidget,
    );
  });
}