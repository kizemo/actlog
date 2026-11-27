// =============================================================================
// Task 66 · 年目标页（UI 半批 B2）
// =============================================================================
// 本文件钉住年页的五条口径：
//  1. 表一给出本年的年度目标（类别 / 序号 / 目标 / 方法和措施 / 起止时间 / 完成）。
//  2. 表二（行 = 年目标 × 列 = 1–12 月）的**有月格来自 serves 真实数据**；
//     空格合法（不报错），点开可就地输入标题进「待确认草稿」。
//  3. 年度复盘给「完成 N 项 / 自评总分 / 自评均值」。
//  4. 80/20 视角**只呈现执行记录条数**：区块内**没有 `%`**、不评分、不排名。
//  5. 滚动候选**只算不写**：未确认前库里 0 增量；确认后落库 `status='draft'`。
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
    show
        GoalKind,
        GoalPeriod,
        GoalRelation,
        GoalStatus,
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

  testWidgets('年页：表二 12 月格来自 serves 真实数据，空格合法',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    // 表一：本年的年度目标。
    expect(
      find.byKey(ValueKey<String>('goal-year-row-${seed.yearlyId}')),
      findsOneWidget,
    );
    // 表二：三月格有真实数据（走 `serves` 链）。
    expect(
      find.byKey(ValueKey<String>('goal-year-cell-${seed.yearlyId}-3')),
      findsOneWidget,
    );
    expect(find.text('三月子目标'), findsOneWidget);
    // 空格合法：别的月份就是「该月未展开」，不报错。
    expect(
      find.byKey(ValueKey<String>('goal-year-cell-empty-${seed.yearlyId}-1')),
      findsOneWidget,
    );
  });

  testWidgets('年页：年度复盘给完成数 / 自评总分 / 自评均值',
      (WidgetTester tester) async {
    await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text('${zh.goalYearReviewDone} 0'), findsOneWidget);
    expect(find.text('${zh.goalYearReviewScoreTotal} 8'), findsOneWidget);
    expect(find.text('${zh.goalYearReviewScoreAverage} 8.0'), findsOneWidget);
    expect(find.text(zh.goalYearReviewSelfNote), findsOneWidget);
  });

  testWidgets('年页：80/20 只呈现执行记录条数，区块内没有百分比',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    final Finder block = find.byKey(
      const ValueKey<String>('goal-year-8020-block'),
    );
    expect(block, findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('goal-year-8020-${seed.yearlyId}')),
      findsOneWidget,
    );
    expect(
      find.text('年度主攻 · 1 ${zh.goalYear8020Tracks}'),
      findsOneWidget,
    );
    // 区块内不出现 `%`（不评分、不排名）。
    final Iterable<Text> texts = tester.widgetList<Text>(
      find.descendant(of: block, matching: find.byType(Text)),
    );
    expect(
      texts.any((Text widget) => (widget.data ?? '').contains('%')),
      isFalse,
      reason: '80/20 区块只呈现条数，不给百分比',
    );
  });

  // B16 项 5：左列底部「滚动候选」段头卡已撤掉 —— 候选列表与它的加号都
  // 不再渲染；「待确认草稿」队列仍挂在「十二月矩阵」卡下，空态照旧可见。
  testWidgets('年页：滚动候选段头卡已撤，候选不渲染且库零增量',
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
    // 待确认草稿队列本体保留在矩阵卡底部（此处为空态）。
    expect(find.text(zh.goalDraftPending), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-year-pending-empty')),
      findsOneWidget,
    );
    // 没有任何自动落库路径。
    expect((await store.listGoals()).length, before);
  });

  testWidgets('年页：表二空格新增月目标，确认后落库并挂上 serves 链',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store, repos);
    await _pumpYear(tester, repos: repos);

    final int before = (await store.listGoals()).length;

    final Finder cell = find.byKey(
      ValueKey<String>('goal-year-cell-empty-${seed.yearlyId}-5'),
    );
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump();

    final Finder input = find.byKey(
      ValueKey<String>('goal-year-cell-input-${seed.yearlyId}-5'),
    );
    await tester.enterText(input, '五月子目标');
    final Finder add = find.byKey(
      ValueKey<String>('goal-year-cell-add-${seed.yearlyId}-5'),
    );
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('goal-year-pending-五月子目标')),
      findsOneWidget,
    );
    // 还没点确认 ⇒ 库里 0 增量。
    expect((await store.listGoals()).length, before);

    final Finder confirm = find.byKey(
      const ValueKey<String>('goal-year-draft-confirm'),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final List<GoalRow> rows = await store.listGoals();
    final GoalRow created = rows.firstWhere(
      (GoalRow goal) => goal.title == '五月子目标',
    );
    expect(created.kind, GoalKind.monthly);
    expect(created.status, GoalStatus.draft);
    expect(created.parentId, seed.yearlyId);
    expect(created.periodStart, GoalPeriod.month(2026, 5).startMillis);
    final List<GoalRow> parents = await store.servedGoals(created.id);
    expect(
      parents.map((GoalRow goal) => goal.id),
      contains(seed.yearlyId),
      reason: '空格新增的月目标要自动挂到年目标下',
    );
  });
}
