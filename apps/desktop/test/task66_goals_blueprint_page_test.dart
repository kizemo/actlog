// =============================================================================
// Task 66 · 人生蓝图页（UI 半批 B2）
// =============================================================================
// 本文件钉住蓝图页的五条口径：
//  1. 蓝图矩阵是 **6 行（领域）× 5 列（档位）**；**空格合法**，整行留空不报错。
//  2. 「近期（1 年）」列 = 本年度的年度目标，**与年页同一份数据源**
//     （`GoalYearView.yearlyGoals`）—— 改了年数据，蓝图列同步。
//  3. **未落位** = 既没有下级目标、也没有任何 `tracks` 执行实体；正例与负例都要断。
//  4. 「拆成 3 条待办」先进待确认队列；确认前库里 0 增量，确认后建 3 条待办
//     并用 `tracks` 挂回原目标。
//  5. 平衡轮是**纯派生只读**：界面上看到的数字不回写目标库。
//
// 测试接**真库**（内存 drift）：判据是「库里的真实行数与状态」，不是 UI 像素。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart'
    show
        GoalHorizon,
        GoalKind,
        GoalPeriod,
        GoalRelation,
        GoalTargetType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 造完基础数据后的 id 集合。
class _Seed {
  /// 构造。
  const _Seed({
    required this.yearlyId,
    required this.ultimateId,
    required this.placedId,
  });

  /// 本年的年度目标 id（近期列的数据源）。
  final String yearlyId;

  /// 「终极」档的蓝图目标 id（**未落位**正例）。
  final String ultimateId;

  /// 「中期」档的蓝图目标 id（**未落位**负例：有周目标挂在它下面）。
  final String placedId;
}

/// 造基础数据：1 条年目标 + 2 条蓝图目标（一条无落位、一条有落位）+ 1 条自评月目标。
Future<_Seed> _seed(GoalStore store) async {
  final GoalPeriod year = GoalPeriod.year(2026);
  final String yearlyId = await store.createGoal(
    kind: GoalKind.yearly,
    title: '年度主攻',
    domain: 'career',
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );

  final String ultimateId = await store.createGoal(
    kind: GoalKind.blueprint,
    title: '终极蓝图',
    domain: 'career',
    horizon: GoalHorizon.ultimate,
  );

  final String placedId = await store.createGoal(
    kind: GoalKind.blueprint,
    title: '有落位的蓝图',
    domain: 'learning',
    horizon: GoalHorizon.mid,
  );
  final GoalPeriod week = GoalPeriod.week(2026, 48);
  final String weeklyId = await store.createGoal(
    kind: GoalKind.weekly,
    title: '每周一次练习',
    domain: 'learning',
    periodStart: week.startMillis,
    periodEnd: week.endMillis,
  );
  await store.link(
    goalId: weeklyId,
    targetType: GoalTargetType.goal,
    targetId: placedId,
    relation: GoalRelation.serves,
  );

  final GoalPeriod november = GoalPeriod.month(2026, 11);
  await store.createGoal(
    kind: GoalKind.monthly,
    title: '本月自评样本',
    domain: 'career',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
    selfScore: 7,
  );

  return _Seed(
    yearlyId: yearlyId,
    ultimateId: ultimateId,
    placedId: placedId,
  );
}

/// 挂起人生蓝图页（自带 MaterialApp + ProviderScope，只补一层 l10n）。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
  AppLanguage language = AppLanguage.zh,
  String instance = 'bp-1',
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
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task66-blueprint-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('蓝图页：矩阵是 6 行领域 × 5 列档位，空格合法不报错',
      (WidgetTester tester) async {
    await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    for (final String domain in <String>[
      'career',
      'wealth',
      'family',
      'learning',
      'social',
      'health',
    ]) {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-row-$domain')),
        findsOneWidget,
        reason: '缺少领域行 $domain',
      );
    }
    for (final String label in <String>[
      zh.goalBlueprintHorizonUltimate,
      zh.goalBlueprintHorizonLong,
      zh.goalBlueprintHorizonMid,
      zh.goalBlueprintHorizonShort,
      zh.goalBlueprintHorizonNear,
    ]) {
      expect(find.text(label), findsOneWidget, reason: '缺少档位列 $label');
    }
    // 空格合法：大量空格子照常渲染，整行留空也不报错。
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-empty-cell')),
      findsWidgets,
    );
    expect(find.text(zh.goalBlueprintBlankRowHint), findsOneWidget);
  });

  testWidgets('蓝图页：近期列与年目标同源，改年数据后蓝图列同步',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    // 本年的年度目标落在「近期（1 年）」列里。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.yearlyId}')),
      findsOneWidget,
    );
    expect(find.text('年度主攻'), findsOneWidget);

    // 改了年目标 ⇒ 换一个 key 重挂页面（重新读模型）后蓝图列同步。
    await store.updateGoal(seed.yearlyId, title: '年度主攻（已改）');
    await _pumpBlueprint(tester, repos: repos, instance: 'bp-2');

    expect(find.text('年度主攻（已改）'), findsOneWidget);
    expect(find.text('年度主攻'), findsNothing);
  });

  testWidgets('蓝图页：未落位有正例（无下级无执行）也有负例（有周目标）',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    // 正例：终极蓝图既没有下级目标，也没有任何 tracks 执行实体。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-unplaced-${seed.ultimateId}')),
      findsOneWidget,
    );
    // 负例：中期蓝图下面挂着周目标 ⇒ 不算未落位。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-unplaced-${seed.placedId}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-child-week-1')),
      findsNothing,
      reason: '周目标是子级，不该出现在「未落位」角标里',
    );
  });

  testWidgets('蓝图页：拆成 3 条待办，确认前 0 增量，确认后建 3 条并挂 tracks',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    expect((await repos.todo.listOpen()).length, 0);

    final Finder split = find.byKey(
      ValueKey<String>('goal-blueprint-split-${seed.ultimateId}'),
    );
    await tester.ensureVisible(split);
    await tester.tap(split);
    await tester.pump();

    for (final String title in <String>['终极蓝图 1/3', '终极蓝图 2/3', '终极蓝图 3/3']) {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-pending-$title')),
        findsOneWidget,
      );
    }
    // 还没点确认 ⇒ 待办池 0 增量。
    expect((await repos.todo.listOpen()).length, 0);

    final Finder confirm = find.byKey(
      const ValueKey<String>('goal-blueprint-todo-confirm'),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect((await repos.todo.listOpen()).length, 3);
    final List<GoalLinkRow> links = await store.listLinks(
      seed.ultimateId,
      relation: GoalRelation.tracks,
    );
    expect(links.length, 3, reason: '3 条待办都要挂回原目标');
  });

  testWidgets('蓝图页：平衡轮是纯派生，渲染后库里 0 增量',
      (WidgetTester tester) async {
    await _seed(store);
    final int goalsBefore = (await store.listGoals()).length;
    final int todosBefore = (await repos.todo.listOpen()).length;

    await _pumpBlueprint(tester, repos: repos);

    expect(
      find.byKey(const ValueKey<String>('goal-balance-wheel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-balance-point-career')),
      findsOneWidget,
    );
    expect((await store.listGoals()).length, goalsBefore);
    expect((await repos.todo.listOpen()).length, todosBefore);
  });
}
