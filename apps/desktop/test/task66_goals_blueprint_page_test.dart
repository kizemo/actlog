// =============================================================================
// Task 66 · 人生蓝图页（UI 半批 B2）→ B9-W2 四标签页改造
// =============================================================================
// 本文件钉住蓝图页的口径：
//  1. 蓝图矩阵按 **4 个标签页（终极 / 远期 / 中期 / 短期）** 展示，默认选中「终极」；
//     切档位后**只渲染当前档位那一张表**。领域行（6 个）不随档位变化。
//  2. 「短期」标签页 = 原「短期」列 + 原「近期（1 年）」列（near 蓝图 + 本年度
//     `kind == yearly` 年目标），与年页**同一份数据源**（`GoalYearView.yearlyGoals`）。
//  3. **未落位** = 既没有下级目标、也没有任何 `tracks` 执行实体；正例与负例都要断。
//  4. 拆分图标打开拆分层级对话框（B9-W3 / D-9-e）：确认前库里 0 增量，
//     确认即落库 —— 终极档拆出的是 3 条远期蓝图目标并挂 `serves`。
//  5. B10-D1：平衡轮块与「整行留空」说明已下线（组件与 l10n 键保留），页面不渲染。
//  6. B9-W2：段头「人生蓝图矩阵」不再渲染；空格子只有右下角「+」、没有「（空）」；
//     蓝图卡片右侧同时有铅笔与拆分图标；年目标不给铅笔 / 拆分（D-9-c）。
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
    show GoalHorizon, GoalKind, GoalPeriod, GoalRelation, GoalTargetType;
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

  /// 本年的年度目标 id（短期标签页的数据源之一）。
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

  return _Seed(yearlyId: yearlyId, ultimateId: ultimateId, placedId: placedId);
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

/// 切到某个标签页（B9-W2 之后矩阵一次只渲染一个档位）。
Future<void> _switchTab(WidgetTester tester, String horizonKey) async {
  final Finder tab = find.byKey(
    ValueKey<String>('goal-blueprint-tab-$horizonKey'),
  );
  await tester.ensureVisible(tab);
  await tester.tap(tab);
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

  testWidgets('蓝图页：4 个标签页 + 6 行领域；只渲染当前档位，空格合法不报错', (
    WidgetTester tester,
  ) async {
    await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    // 4 个标签页（终极 → 远期 → 中期 → 短期），默认选中「终极」。
    for (final MapEntry<String, String> tab in <String, String>{
      'ultimate': zh.goalBlueprintHorizonUltimate,
      'long': zh.goalBlueprintHorizonLong,
      'mid': zh.goalBlueprintHorizonMid,
      'short': zh.goalBlueprintHorizonShort,
    }.entries) {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-tab-${tab.key}')),
        findsOneWidget,
        reason: '缺少标签页 ${tab.value}',
      );
      expect(
        find.text(tab.value),
        findsOneWidget,
        reason: '标签页文案 ${tab.value}',
      );
    }
    // 6 个领域行都在（行头不随档位变化）。
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
    // 空格合法：终极档里 career 有目标、wealth 是空 ⇒ 空格的入口是「+」而不是「（空）」。
    expect(find.text('（空）'), findsNothing, reason: '空态不再显示「（空）」');
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-empty-cell')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-wealth-ultimate')),
      findsOneWidget,
    );
    // 未选中的档位整张表都不渲染。
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-wealth-long')),
      findsNothing,
      reason: '一次只渲染当前标签页',
    );
    // B10-D1：「整行留空」的说明已下线（键保留，页面不再渲染）。
    expect(find.text(zh.goalBlueprintBlankRowHint), findsNothing);
  });

  testWidgets('蓝图页：短期标签页里的年目标与年页同源，改年数据后同步', (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    // 年目标属于「近期（1 年）」，已并入短期页 ⇒ 默认的终极档里看不到。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.yearlyId}')),
      findsNothing,
      reason: '终极档不该渲染短期页的内容',
    );

    await _switchTab(tester, 'short');
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.yearlyId}')),
      findsOneWidget,
      reason: '本年度年目标要落在短期标签页里',
    );
    expect(find.text('年度主攻'), findsOneWidget);

    // 改了年目标 ⇒ 换一个 key 重挂页面（重新读模型）后短期页同步。
    await store.updateGoal(seed.yearlyId, title: '年度主攻（已改）');
    await _pumpBlueprint(tester, repos: repos, instance: 'bp-2');
    await _switchTab(tester, 'short');

    expect(find.text('年度主攻（已改）'), findsOneWidget);
    expect(find.text('年度主攻'), findsNothing);
  });

  testWidgets('蓝图页：未落位有正例（无下级无执行）也有负例（有周目标）', (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    // 正例：终极蓝图既没有下级目标，也没有任何 tracks 执行实体（默认档位里）。
    expect(
      find.byKey(
        ValueKey<String>('goal-blueprint-unplaced-${seed.ultimateId}'),
      ),
      findsOneWidget,
    );

    // 负例：中期蓝图下面挂着周目标 ⇒ 不算未落位。先切到「中期」，确认卡片确实
    // 渲染了（否则下面的 findsNothing 是空断言）。
    await _switchTab(tester, 'mid');
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.placedId}')),
      findsOneWidget,
      reason: '切到中期后该卡片必须渲染',
    );
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

  testWidgets('蓝图页：拆分图标打开对话框，确认前 0 增量，确认后建 3 条并挂 serves', (
    WidgetTester tester,
  ) async {
    final _Seed seed = await _seed(store);
    final int goalsBefore = (await store.listGoals()).length;
    await _pumpBlueprint(tester, repos: repos);

    final Finder split = find.byKey(
      ValueKey<String>('goal-blueprint-split-${seed.ultimateId}'),
    );
    await tester.ensureVisible(split);
    await tester.tap(split);
    await tester.pumpAndSettle();

    // 打开的是拆分层级对话框：默认 3 行空输入（不再有页内待确认队列）。
    for (int i = 0; i < 3; i++) {
      await tester.enterText(
        find.byKey(ValueKey<String>('goal-split-title-$i')),
        '远期 $i',
      );
    }
    await tester.pump();
    // 还没点确认 ⇒ 库里 0 增量。
    expect((await store.listGoals()).length, goalsBefore);

    final Finder confirm = find.byKey(
      const ValueKey<String>('goal-split-confirm'),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final List<GoalRow> all = await store.listGoals();
    expect(all.length, goalsBefore + 3, reason: '确认即落库，三条子目标');
    final List<GoalRow> children = <GoalRow>[
      for (final GoalRow goal in all)
        if (goal.parentId == seed.ultimateId) goal,
    ];
    expect(children.length, 3);
    for (final GoalRow child in children) {
      expect(child.horizon, GoalHorizon.long, reason: '终极的下一层是远期');
      final List<GoalLinkRow> serves = await store.listLinks(
        child.id,
        relation: GoalRelation.serves,
      );
      expect(serves.length, 1);
      expect(serves.single.targetId, seed.ultimateId);
    }
  });

  testWidgets('B10-D1：平衡轮块已下线，页面渲染后库里 0 增量', (WidgetTester tester) async {
    await _seed(store);
    final int goalsBefore = (await store.listGoals()).length;
    final int todosBefore = (await repos.todo.listOpen()).length;

    await _pumpBlueprint(tester, repos: repos);

    expect(
      find.byKey(const ValueKey<String>('goal-balance-wheel')),
      findsNothing,
      reason: 'B10-D1 下线平衡轮块',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-balance-point-career')),
      findsNothing,
    );
    expect((await store.listGoals()).length, goalsBefore);
    expect((await repos.todo.listOpen()).length, todosBefore);
  });

  testWidgets('B9-W2：矩阵段头「人生蓝图矩阵」不再渲染', (WidgetTester tester) async {
    await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-matrix-section')),
      findsNothing,
    );
    expect(find.text('人生蓝图矩阵'), findsNothing);
    expect(find.text('Life blueprint matrix'), findsNothing);
    // 去标题只针对矩阵块：顶部「个人定位」面板的段头在场。
    expect(find.text(AppLocalizations.zh.goalPositionSection), findsOneWidget);
  });

  testWidgets('B9-W2：空格子只有右下角「+」，不再渲染「（空）」', (WidgetTester tester) async {
    await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    expect(find.text('（空）'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-empty-cell')),
      findsNothing,
    );

    final Finder add = find.byKey(
      const ValueKey<String>('goal-blueprint-add-wealth-ultimate'),
    );
    expect(add, findsOneWidget, reason: '空格子要有一个「+」入口');
    expect(find.text('+'), findsWidgets, reason: '空态用「+」符号代替「（空）」');

    // 与右侧图标按钮同一 28×28 紧凑口径。
    final IconButton button = tester.widget<IconButton>(add);
    expect(button.constraints?.maxWidth, 28);
    expect(button.constraints?.maxHeight, 28);
  });

  testWidgets('B9-W2：蓝图卡片右侧同时有铅笔与拆分图标', (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    expect(
      find.byKey(ValueKey<String>('goal-blueprint-edit-${seed.ultimateId}')),
      findsOneWidget,
      reason: '已添加内容右侧要有铅笔',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-split-${seed.ultimateId}')),
      findsOneWidget,
      reason: '已添加内容右侧要有拆分图标',
    );
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    expect(find.byIcon(Icons.call_split), findsWidgets);
  });

  testWidgets('B9-W2：切标签页只渲染对应档位（终极目标在远期档 findsNothing）', (
    WidgetTester tester,
  ) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    final Finder ultimateCell = find.byKey(
      ValueKey<String>('goal-blueprint-cell-${seed.ultimateId}'),
    );
    expect(ultimateCell, findsOneWidget);

    await _switchTab(tester, 'long');
    expect(ultimateCell, findsNothing, reason: '切到远期后终极档整张表都不渲染');
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-career-long')),
      findsOneWidget,
      reason: '远期档的空格子照常有「+」',
    );

    await _switchTab(tester, 'ultimate');
    expect(ultimateCell, findsOneWidget, reason: '切回终极档内容要回来');
  });

  testWidgets('B9-W2：短期标签页同时含 short 蓝图、near 蓝图与本年度年目标', (
    WidgetTester tester,
  ) async {
    final _Seed seed = await _seed(store);
    final String shortId = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '短期蓝图',
      domain: 'health',
      horizon: GoalHorizon.short,
    );
    final String nearId = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '一年蓝图',
      domain: 'health',
      horizon: GoalHorizon.near,
    );
    await _pumpBlueprint(tester, repos: repos);

    await _switchTab(tester, 'short');
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-$shortId')),
      findsOneWidget,
      reason: '短期蓝图在短期页',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-$nearId')),
      findsOneWidget,
      reason: 'D-9-b：near 蓝图并入短期页',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.yearlyId}')),
      findsOneWidget,
      reason: '本年度年目标并入短期页',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-short-tab-note')),
      findsOneWidget,
      reason: '短期页要有来源说明',
    );
    // 近期列已经不单独存在 ⇒ 没有 near 新建入口。
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-health-near')),
      findsNothing,
    );
  });

  testWidgets('B9-W2：短期页里的年目标不给铅笔与拆分（D-9-c）', (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos);

    await _switchTab(tester, 'short');
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.yearlyId}')),
      findsOneWidget,
      reason: '年目标确实渲染了，下面的 findsNothing 才不是空断言',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-edit-${seed.yearlyId}')),
      findsNothing,
      reason: '年目标是年页镜像，不许在 07 页改档位',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-split-${seed.yearlyId}')),
      findsNothing,
    );
  });
}
