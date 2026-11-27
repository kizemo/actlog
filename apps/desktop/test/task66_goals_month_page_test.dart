// =============================================================================
// Task 66 · 月目标页（UI 半批 B2）
// =============================================================================
// 本文件钉住月页的五条口径：
//  1. 上月复盘逐条列出「未完成原因」；**缺失只提示、不阻断**（不弹窗、不拦提交）。
//  2. 「改进措施」是**页内本地编辑**，「转为本月目标草稿」只进**待确认队列**。
//  3. 本月目标要么「服务于年目标」，要么标「临时事项」（**派生标记，不写库**）。
//  4. 滚动候选**只算不写**：未确认前库里 0 增量；确认后落库 `status='draft'`。
//  5. 年度汇总条给出本月目标所 `serves` 的年目标。
//
// 测试接**真库**（内存 drift）：判据是「库里的真实行数与状态」，不是 UI 像素。
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
  const _Seed({
    required this.yearlyId,
    required this.noReasonId,
    required this.servedId,
    required this.adHocId,
  });

  /// 本年的年度目标 id。
  final String yearlyId;

  /// 上月「没写未完成原因」的月目标 id。
  final String noReasonId;

  /// 本月「服务于年目标」的月目标 id。
  final String servedId;

  /// 本月「临时事项」的月目标 id。
  final String adHocId;
}

/// 造基础数据：本年 1 条年目标 + 上月 2 条月目标 + 本月 2 条月目标。
Future<_Seed> _seed(GoalStore store) async {
  final GoalPeriod year = GoalPeriod.year(2026);
  final String yearlyId = await store.createGoal(
    kind: GoalKind.yearly,
    title: '年度主攻',
    domain: 'career',
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );

  final GoalPeriod october = GoalPeriod.month(2026, 10);
  final String noReasonId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '上月没写原因',
    domain: 'career',
    periodStart: october.startMillis,
    periodEnd: october.endMillis,
  );
  await store.createGoal(
    kind: GoalKind.monthly,
    title: '上月有原因',
    domain: 'learning',
    periodStart: october.startMillis,
    periodEnd: october.endMillis,
    reviewNote: '时间不够',
  );

  final GoalPeriod november = GoalPeriod.month(2026, 11);
  final String servedId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '本月服务年目标',
    domain: 'career',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  await store.link(
    goalId: servedId,
    targetType: GoalTargetType.goal,
    targetId: yearlyId,
    relation: GoalRelation.serves,
  );
  final String adHocId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '本月临时事项',
    domain: 'health',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );

  return _Seed(
    yearlyId: yearlyId,
    noReasonId: noReasonId,
    servedId: servedId,
    adHocId: adHocId,
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

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task66-month-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('月页：上月复盘逐条列出未完成原因，缺失只提示不阻断',
      (WidgetTester tester) async {
    await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text(zh.goalMonthReviewSection), findsOneWidget);
    expect(find.text('上月没写原因'), findsOneWidget);
    expect(find.text('上月有原因'), findsOneWidget);
    // 缺原因的给提示文案，但复盘条照样渲染出来（**不阻断**）。
    expect(find.text(zh.goalMonthReviewReasonMissing), findsOneWidget);
    expect(find.text('时间不够'), findsOneWidget);
  });

  testWidgets('月页：本月目标区分「服务于年目标」与「临时事项」（派生标记）',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    expect(
      find.byKey(ValueKey<String>('goal-month-serves-yearly-${seed.servedId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('goal-month-ad-hoc-${seed.adHocId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('goal-month-row-${seed.servedId}')),
      findsOneWidget,
    );
    // 年度汇总条给出了本月目标所 serves 的年目标。
    expect(
      find.byKey(
        ValueKey<String>('goal-month-year-summary-${seed.yearlyId}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-month-year-bar-empty')),
      findsNothing,
    );
  });

  testWidgets('月页：改进措施转草稿只进待确认队列，确认后落库 status=draft',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final int before = (await store.listGoals()).length;

    final Finder improve = find.byKey(
      ValueKey<String>('goal-review-improve-${seed.noReasonId}'),
    );
    await tester.ensureVisible(improve);
    await tester.enterText(improve, '拆成两周节奏');
    final Finder convert = find.byKey(
      ValueKey<String>('goal-review-convert-${seed.noReasonId}'),
    );
    await tester.ensureVisible(convert);
    await tester.tap(convert);
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('goal-month-pending-empty')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-month-pending-上月没写原因')),
      findsOneWidget,
    );
    // 还没点确认 ⇒ 库里 0 增量。
    expect((await store.listGoals()).length, before);

    final Finder confirm = find.byKey(
      const ValueKey<String>('goal-month-draft-confirm'),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final List<GoalRow> rows = await store.listGoals();
    final List<GoalRow> drafts = rows
        .where((GoalRow goal) => goal.status == GoalStatus.draft)
        .toList();
    expect(drafts.length, 1, reason: '确认后只落 1 行草稿');
    expect(drafts.single.title, '上月没写原因');
    expect(drafts.single.kind, GoalKind.monthly);
  });

  // B16 项 5：左列底部「滚动候选」段头卡已撤掉 —— 候选列表与它的加号都
  // 不再渲染；「待确认草稿」队列仍挂在「本月目标」卡下，空态照旧可见。
  testWidgets('月页：滚动候选段头卡已撤，候选不渲染且库零增量',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final int before = (await store.listGoals()).length;
    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text(zh.goalsDraftSection), findsNothing);
    expect(find.text(zh.goalsDraftEmpty), findsNothing);
    expect(
      find.byKey(ValueKey<String>('goal-month-candidate-${seed.servedId}')),
      findsNothing,
      reason: '候选列表已随段头卡一起撤掉',
    );
    expect(
      find.byKey(
        ValueKey<String>('goal-month-candidate-add-${seed.servedId}'),
      ),
      findsNothing,
      reason: '候选的加号入口也一并撤掉',
    );
    // 待确认草稿队列本体保留在「本月目标」卡底部（此处为空态）。
    expect(find.text(zh.goalDraftPending), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-month-pending-empty')),
      findsOneWidget,
    );
    // 没有任何自动落库路径。
    expect((await store.listGoals()).length, before);
  });

  testWidgets('月页英文态：区块标题走英文，界面不残留中文文案',
      (WidgetTester tester) async {
    await _seed(store);
    await _pumpMonth(tester, repos: repos, language: AppLanguage.en);

    final AppLocalizations en = AppLocalizations.en;
    expect(find.text(en.goalMonthReviewSection), findsOneWidget);
    expect(find.text(en.goalMonthGoalsSection), findsOneWidget);
    expect(find.text(AppLocalizations.zh.goalMonthReviewSection), findsNothing);
    expect(find.text(AppLocalizations.zh.goalMonthGoalsSection), findsNothing);
  });
}
