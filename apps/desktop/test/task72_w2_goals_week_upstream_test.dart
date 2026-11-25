// =============================================================================
// Task 72 · 批次 B7 · W2：周目标页右栏「未完成月目标」派生用例
// =============================================================================
// 需求 3 的判据（D-72-d / D-72-e）：
//  1. 右栏列出**仍未完成**的月目标（口径由 `monthOpenGoalsProvider` 负责）；
//  2. 点一条 ⇒ 库里真的多出一条**本周**周目标，且它 `serves` 那条月目标；
//  3. **不改父目标状态**；
//  4. 重复添加**幂等**：再点一次不多出行。
//
// 与月页用例同策略：不 override 写入口，走真的 `GoalDraftSaver` →
// `GoalStore.saveWeeklyDrafts` + 真内存 drift，断言落在库里的行。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_week_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_upstream_panel.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart'
    show ActLogDatabase, openInMemoryActLogDatabase;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 固定的「今天」：2026-11-25 属 ISO 2026 年第 48 周、2026 年 11 月。
const String _today = '2026-11-25';

/// 与 [_today] 对应的本周周期。
final GoalPeriod _week = GoalPeriod.week(2026, 48);

/// 与 [_today] 对应的本月周期（用来把月目标的 period_start 摆对）。
final GoalPeriod _month = GoalPeriod.month(2026, 11);

/// 挂起周目标页（真库 + 真写入口）。
Future<void> _pumpWeekPage(
  WidgetTester tester,
  ActLogRepositories repos, {
  AppLanguage language = AppLanguage.zh,
}) async {
  tester.view.physicalSize = const Size(1300, 2400);
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
            repositoriesProvider.overrideWithValue(repos),
            todayProvider.overrideWithValue(_today),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalsWeekPage()),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('右栏列出未完成月目标，点一次派生一条本周周目标，再点一次不重复', (
    WidgetTester tester,
  ) async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    addTearDown(db.close);
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task72-w2-week',
    );
    final GoalStore store = GoalStore(repos);

    final String monthlyId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '月度主攻',
      periodStart: _month.startMillis,
    );

    await _pumpWeekPage(tester, repos);

    // ① 右栏在，且列出了那条月目标。
    expect(
      find.byKey(GoalUpstreamPanel.panelKey(GoalKind.monthly)),
      findsOneWidget,
    );
    final Finder item = find.byKey(
      GoalUpstreamPanel.itemKey(GoalKind.monthly, monthlyId),
    );
    expect(item, findsOneWidget);

    // ② 点一次 ⇒ 库里多出一条**本周**周目标。
    await tester.tap(item);
    await tester.pumpAndSettle();

    GoalWeekView view = await store.weekView(_week);
    final List<GoalWeekItem> derived = <GoalWeekItem>[
      for (final GoalWeekItem row in view.items)
        if (row.goal.kind == GoalKind.weekly &&
            row.servedGoal?.id == monthlyId)
          row,
    ];
    expect(derived.length, 1);
    expect(derived.single.goal.title, '月度主攻');
    expect(derived.single.goal.periodStart, _week.startMillis);

    // 父目标仍然是未完成（派生不改父状态）。
    final List<GoalRow> monthlyAfter = await store.listGoals(
      kind: GoalKind.monthly,
    );
    expect(
      monthlyAfter.where((GoalRow g) => g.id == monthlyId).single.status,
      GoalStatus.active,
    );

    // ③ 再点一次 ⇒ 幂等，不产生第二行。
    await tester.tap(item);
    await tester.pumpAndSettle();

    view = await store.weekView(_week);
    expect(
      view.items.where((GoalWeekItem row) => row.servedGoal?.id == monthlyId)
          .length,
      1,
      reason: '重复点击不得产生重复派生行（D-72-e 幂等）',
    );
  });

  testWidgets('右栏文案走 en 文案表（页面侧接的是 l10n，不是硬编码中文）', (
    WidgetTester tester,
  ) async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    addTearDown(db.close);
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task72-w2-week-en',
    );

    await _pumpWeekPage(tester, repos, language: AppLanguage.en);

    final AppLocalizations en = AppLocalizations.en;
    expect(find.text(en.goalsUpstreamMonthTitle), findsOneWidget);
    expect(find.text(en.goalsUpstreamAddHint), findsOneWidget);
    // 上游为空 ⇒ 落空态文案。
    expect(find.text(en.goalsUpstreamEmpty), findsOneWidget);
  });
}