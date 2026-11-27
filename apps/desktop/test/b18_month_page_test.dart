// =============================================================================
// B18 波 · 月目标页（行内三处冗余下线）
// =============================================================================
// B17 给月页加了「按类别分区渲染」与「行尾完成单选」，副作用是三处冗余。本批
// 只收紧月页的**展示出口**，数据层与 l10n getter 一律不动：
//  1. 行内**不再有类别列** ⇒ 分类名的唯一出处是分区小标题
//     `goal-section-title-<displayKey>`（`widgets/goals/goal_section.dart` 渲染）。
//  2. 「进行中 / 已完成」状态文本**不再渲染** ⇒ 完成状态只由行尾完成单选
//     `goal-row-done-<id>` 表达（该按钮必须保留）。
//  3. 派生标记行（「服务于年目标」/「临时事项」）**整条下线** ⇒ 两个 ValueKey
//     `goal-month-serves-yearly-<id>` / `goal-month-ad-hoc-<id>` 都不再出现。
//
// 鉴别力：造数时刻意让「同一类别的两条行 + 一条已完成 + 一条 `serves` 年目标」
// 同时存在 —— 只要任一处冗余回归，下面的 `findsNothing` 就会变回
// `findsOneWidget` / `findsNWidgets(3)`。
// 测试接**真库**（内存 drift）：判据是「页面上还有什么」+「库里的真实状态」。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_month_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart'
    show GoalKind, GoalPeriod, GoalRelation, GoalStatus, GoalTargetType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 本批用到的目标 id。
class _Seed {
  /// 构造。
  const _Seed({
    required this.doneLearningId,
    required this.activeLearningId,
    required this.servedHealthId,
    required this.adHocHealthId,
  });

  /// 类别 = `learning` 且**已完成**的本月目标。
  final String doneLearningId;

  /// 类别 = `learning` 且**进行中**的本月目标（与上一条同分区）。
  final String activeLearningId;

  /// 类别 = `health`，且 `serves` 一条年目标的本月目标。
  final String servedHealthId;

  /// 类别 = `health`，且**没有**上层目标的本月目标（旧口径的「临时事项」）。
  final String adHocHealthId;
}

/// 造数据：1 条年目标 + 4 条本月目标（两条同类别、一条已、一条挂 `serves`）。
Future<_Seed> _seed(GoalStore store) async {
  final GoalPeriod year = GoalPeriod.year(2026);
  final String yearlyId = await store.createGoal(
    kind: GoalKind.yearly,
    title: '年度主攻',
    domain: 'career',
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );

  final GoalPeriod november = GoalPeriod.month(2026, 11);
  final String doneLearningId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '读完一本',
    domain: 'learning',
    status: GoalStatus.done,
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  final String activeLearningId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '再读一本',
    domain: 'learning',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  final String servedHealthId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '服务年目标的事',
    domain: 'health',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  await store.link(
    goalId: servedHealthId,
    targetType: GoalTargetType.goal,
    targetId: yearlyId,
    relation: GoalRelation.serves,
  );
  final String adHocHealthId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '临时杂事',
    domain: 'health',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );

  return _Seed(
    doneLearningId: doneLearningId,
    activeLearningId: activeLearningId,
    servedHealthId: servedHealthId,
    adHocHealthId: adHocHealthId,
  );
}

/// 挂起月目标页（自带 MaterialApp + ProviderScope，只补一层 l10n）。
Future<void> _pumpMonth(
  WidgetTester tester, {
  required ActLogRepositories repos,
  AppLanguage language = AppLanguage.zh,
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
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalsMonthPage()),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 从库里按 id 取一行。
Future<GoalRow> _row(GoalStore store, String id) async {
  final List<GoalRow> rows = await store.listGoals();
  return rows.firstWhere((GoalRow goal) => goal.id == id);
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b18-month-page-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('B18 月页：行内不再渲染类别列，分类名唯一出处是分区小标题',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    // `learning` 分区里有**两条**行：旧口径下分类名出现 1（小标题）+ 2（类别列）
    // = 3 次；现在只剩分区小标题那一次。
    expect(
      find.text(zh.goalCategoryLearning),
      findsOneWidget,
      reason: '行内类别列已删 ⇒ 分类名只在分区小标题出现一次',
    );
    expect(
      find.text(zh.goalCategoryHealth),
      findsOneWidget,
      reason: 'health 分区的两条行同样不再各带一份分类名',
    );
    // 唯一那一处确实是分区小标题，且分区本体仍在（本批只撤行内类别列）。
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-section-title-learning')),
          )
          .data,
      zh.goalCategoryLearning,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-section-learning')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-section-health')),
      findsOneWidget,
    );
    // 行本体没被动：标题还在。
    expect(
      find.byKey(ValueKey<String>('goal-month-row-${seed.activeLearningId}')),
      findsOneWidget,
    );
  });

  testWidgets('B18 月页：不再渲染「进行中 / 已完成」状态文本',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    // 前置：库里确实同时有「已完成」与「进行中」的行 ⇒ 上面的 findsNothing 有鉴别力。
    expect((await _row(store, seed.doneLearningId)).isDone, isTrue);
    expect((await _row(store, seed.activeLearningId)).isDone, isFalse);

    expect(
      find.text(zh.goalStatusActive),
      findsNothing,
      reason: '完成列已删 ⇒ 「进行中」不再作为文本出现',
    );
    expect(
      find.text(zh.goalStatusDone),
      findsNothing,
      reason: '完成列已删 ⇒ 「已完成」不再作为文本出现',
    );
  });

  testWidgets('B18 月页：派生标记行下线，服务于年目标 / 临时事项 两个 key 都不渲染',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    expect(
      find.byKey(
        ValueKey<String>('goal-month-serves-yearly-${seed.servedHealthId}'),
      ),
      findsNothing,
      reason: '派生标记行整条下线（即使该行真有 serves 年目标的关系）',
    );
    expect(
      find.byKey(ValueKey<String>('goal-month-ad-hoc-${seed.adHocHealthId}')),
      findsNothing,
      reason: '派生标记行整条下线（没有上层目标的行走同一条出口）',
    );
    // 文案本身也不再出现（key 与文本双保险）。
    expect(find.text(zh.goalMonthServesYearly), findsNothing);
    expect(find.text(zh.goalMonthAdHoc), findsNothing);
    // 行本体照旧渲染 ⇒ 删的是标记行，不是整个行。
    expect(
      find.byKey(ValueKey<String>('goal-month-row-${seed.servedHealthId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('goal-month-row-${seed.adHocHealthId}')),
      findsOneWidget,
    );
  });

  testWidgets('B18 月页：表头删掉类别列与完成列，其余表头保留',
      (WidgetTester tester) async {
    await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text(zh.goalMonthColumnCategory), findsNothing);
    expect(find.text(zh.goalMonthColumnDone), findsNothing);
    // 余下的表头格仍在（两侧各删两格 ⇒ 逐位对应不被破坏）。
    expect(find.text(zh.goalMonthColumnIndex), findsOneWidget);
    expect(find.text(zh.goalMonthColumnMethods), findsOneWidget);
  });

  testWidgets('B18 月页：行尾完成单选仍在，且点了照样落库',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final String id = seed.activeLearningId;
    final Finder done = find.byKey(ValueKey<String>('goal-row-done-$id'));
    expect(done, findsOneWidget, reason: '完成状态唯一出口 = 行尾单选，必须保留');
    // 已完成的行同样带着单选（口径是「当前是否完成」，不是「能否点」）。
    expect(
      find.byKey(ValueKey<String>('goal-row-done-${seed.doneLearningId}')),
      findsOneWidget,
    );

    await tester.tap(done);
    await tester.pumpAndSettle();
    expect((await _row(store, id)).isDone, isTrue);
  });
}