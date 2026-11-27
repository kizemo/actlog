// =============================================================================
// Task 66 · 年目标页（UI 半批 B2；B17 W4 之后本页只剩表一）
// =============================================================================
// 本文件钉住年页的两条口径：
//  1. 表一给出本年的年度目标（序号 / 目标 / 方法和措施 / 起止时间 / 操作；
//     B18 W3 之后**不再有**行内「类别」列与「进行中 / 已完成」文本列 ——
//     分类名唯一出处是分区小标题，完成态唯一出处是行尾完成单选）。
//  2. B17 E 条：表二 12 月格 / 年度复盘 / 80-20 视角 / 待确认草稿队列 / 表二空格
//     新增流程的 **UI 入口全部下线**；**数据层（`GoalYearView` /
//     `loadGoalYearView`）与 l10n getter 保留**。
//
// 因此第 2 条在用例里一律是 `findsNothing` 反向断言 —— 用例**没有删**，只是把
// 「必须显示」翻成「必须不显示」；同时补一条库层断言，证明下线的是 UI 而不是数据。
//
// 测试接**真库**（内存 drift）：判据是「库里的真实行数与状态」，不是 UI 像素。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_year_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart'
    show GoalKind, GoalPeriod, GoalRelation, GoalTargetType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 造完基础数据后的 id 集合。
class _Seed {
  /// 构造。
  const _Seed({required this.yearlyId, required this.marchId});

  /// 本年的年度目标 id。
  final String yearlyId;

  /// 三月的月目标 id（`serves` 年度目标）。
  final String marchId;
}

/// 造基础数据：本年 1 条年目标（带自评）+ 3 月 1 条月目标 + 1 条执行记录。
Future<_Seed> _seed(GoalStore store, ActLogRepositories repos) async {
  final GoalPeriod year = GoalPeriod.year(2026);
  final String yearlyId = await store.createGoal(
    kind: GoalKind.yearly,
    title: '年度主攻',
    domain: 'career',
    keywords: '每周一次复盘',
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
    selfScore: 8,
  );

  final GoalPeriod march = GoalPeriod.month(2026, 3);
  final String marchId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '三月子目标',
    domain: 'career',
    periodStart: march.startMillis,
    periodEnd: march.endMillis,
  );
  await store.link(
    goalId: marchId,
    targetType: GoalTargetType.goal,
    targetId: yearlyId,
    relation: GoalRelation.serves,
  );

  final String todoId = await repos.todo.create(title: '执行一件事');
  await store.link(
    goalId: yearlyId,
    targetType: GoalTargetType.todo,
    targetId: todoId,
    relation: GoalRelation.tracks,
  );

  return _Seed(yearlyId: yearlyId, marchId: marchId);
}

/// 挂起年目标页（自带 MaterialApp + ProviderScope，只补一层 l10n）。
Future<void> _pumpYear(
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
            body: SingleChildScrollView(child: GoalsYearPage()),
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
    repos = ActLogRepositories(db, deviceId: 'task66-year-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('年页：表一给出本年年度目标，表二 12 月格已下线',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;

    // 表一：本年的年度目标仍在（行键 = 契约）。
    expect(
      find.byKey(ValueKey<String>('goal-year-row-${seed.yearlyId}')),
      findsOneWidget,
    );
    // 行按类别分区：`career` 不是目标类别 ⇒ 归「未分类」（B17 裁决 2）。
    expect(
      find.byKey(const ValueKey<String>('goal-section-none')),
      findsOneWidget,
    );
    // B18 W3：分类名的**唯一**出处是分区小标题 ⇒ 两处（小标题 + 行内类别列）
    // 之说不再成立，这里从 `findsAtLeastNWidgets(1)` 收紧成 `findsOneWidget`。
    expect(
      find.text(zh.goalCategoryUncategorized),
      findsOneWidget,
      reason: '行内类别列已删 ⇒ 未分类文本只剩分区小标题一处',
    );

    // B17 E 条：表二（行 = 年目标 × 列 = 1–12 月）整块下线 ⇒ 月格与空格都不渲染。
    expect(
      find.byKey(ValueKey<String>('goal-year-cell-${seed.yearlyId}-3')),
      findsNothing,
      reason: '表二的月格已随区块下线',
    );
    expect(
      find.byKey(ValueKey<String>('goal-year-cell-empty-${seed.yearlyId}-1')),
      findsNothing,
      reason: '表二的空格也一并下线',
    );
    expect(
      find.text('三月子目标'),
      findsNothing,
      reason: '月目标只出现在表二的月格里，表二下线后不应渲染',
    );

    // 下线的是 UI，不是数据：serves 链上的月目标仍真实存在。
    final GoalRow march = (await store.listGoals()).firstWhere(
      (GoalRow goal) => goal.id == seed.marchId,
    );
    expect(march.kind, GoalKind.monthly);
    expect(await store.servedGoals(march.id), isNotEmpty);
  });

  testWidgets('年页：年度复盘块已下线（自评仍在库里）',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    // 旧断言逐条翻成 `findsNothing`：完成数 / 自评总分 / 自评均值 / 脚注 / 段头。
    expect(find.text('${zh.goalYearReviewDone} 0'), findsNothing);
    expect(find.text('${zh.goalYearReviewScoreTotal} 8'), findsNothing);
    expect(find.text('${zh.goalYearReviewScoreAverage} 8.0'), findsNothing);
    expect(find.text(zh.goalYearReviewSelfNote), findsNothing);
    expect(find.text(zh.goalYearReviewSection), findsNothing);

    // 数据层保留：自评 8 分仍在目标行上，只是不再有复盘 UI 去汇总它。
    final GoalRow yearly = (await store.listGoals()).firstWhere(
      (GoalRow goal) => goal.id == seed.yearlyId,
    );
    expect(yearly.selfScore, 8);
  });

  testWidgets('年页：80/20 视角块已下线（不呈现条数、没有百分比）',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    expect(
      find.byKey(const ValueKey<String>('goal-year-8020-block')),
      findsNothing,
      reason: '80/20 区块已随 E 条下线',
    );
    expect(
      find.byKey(ValueKey<String>('goal-year-8020-${seed.yearlyId}')),
      findsNothing,
    );
    expect(
      find.text('年度主攻 · 1 ${zh.goalYear8020Tracks}'),
      findsNothing,
      reason: '执行记录条数不再呈现',
    );
    // 全页不出现 `%`（不评分、不排名）。
    final Iterable<Text> texts = tester.widgetList<Text>(find.byType(Text));
    expect(
      texts.any((Text widget) => (widget.data ?? '').contains('%')),
      isFalse,
      reason: '年页不呈现百分比',
    );
  });

  // B16 项 5 撤掉了「滚动候选」段头卡；B17 E 条又把挂在表二卡下的
  // 「待确认草稿」队列一起下线 ⇒ 整条候选 / 草稿链路在本页都不再渲染。
  testWidgets('年页：滚动候选与待确认草稿队列均已下线，库零增量',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final int before = (await store.listGoals()).length;
    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text(zh.goalsDraftSection), findsNothing);
    expect(
      find.byKey(ValueKey<String>('goal-year-candidate-${seed.yearlyId}')),
      findsNothing,
      reason: '候选列表已随段头卡一起撤掉',
    );
    expect(
      find.byKey(ValueKey<String>('goal-year-candidate-add-${seed.yearlyId}')),
      findsNothing,
      reason: '候选的加号入口也一并撤掉',
    );
    // 待确认草稿队列本体随表二卡下线（旧断言是 findsOneWidget，此处反向）。
    expect(find.text(zh.goalDraftPending), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('goal-year-pending-empty')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-year-draft-confirm')),
      findsNothing,
    );
    // 没有任何自动落库路径。
    expect((await store.listGoals()).length, before);
  });

  testWidgets('年页：表二空格新增流程已下线（cell 键一律不渲染，库零增量）',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final int before = (await store.listGoals()).length;
    // 旧的「点空格 → 输入 → 加入待确认草稿 → 确认落库」四步入口全部不渲染。
    for (final String key in <String>[
      'goal-year-cell-empty-${seed.yearlyId}-5',
      'goal-year-cell-input-${seed.yearlyId}-5',
      'goal-year-cell-add-${seed.yearlyId}-5',
      'goal-year-draft-confirm',
    ]) {
      expect(
        find.byKey(ValueKey<String>(key)),
        findsNothing,
        reason: '表二空格新增入口 $key 已下线',
      );
    }
    // 表一非空 ⇒ 空态文案不渲染。
    expect(
      find.byKey(const ValueKey<String>('goal-year-goals-empty')),
      findsNothing,
    );
    // 本页不再有任何写库路径 ⇒ 行数不变，五月也不会凭空多出月目标。
    expect((await store.listGoals()).length, before);
    expect(
      (await store.listGoals()).where(
        (GoalRow goal) =>
            goal.periodStart == GoalPeriod.month(2026, 5).startMillis,
      ),
      isEmpty,
    );
  });
}