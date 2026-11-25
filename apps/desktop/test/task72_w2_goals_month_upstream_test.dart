// =============================================================================
// Task 72 · 批次 B7 · W2：月目标页右栏「未完成年目标」派生用例
// =============================================================================
// 需求 2 的判据（D-72-d / D-72-e）：
//  1. 右栏列出**仍未完成**的年目标（口径由 `yearOpenGoalsProvider` 负责）；
//  2. 点一条 ⇒ 库里真的多出一条**本月**月目标，且它 `serves` 那条年目标；
//  3. **不改父目标状态**（派生不是「完成」也不是「复制文本」）；
//  4. 重复添加**幂等**：再点一次不多出行。
//
// 这里不 override 写入口：走真的 `GoalStore.saveWeeklyDrafts` + 真的内存 drift，
// 于是断言落在「库里的行」而不是「回调被调用过」。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_month_page.dart';
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

/// 被测月份（页面的 `today` 同月，避免「当前月/被看月」两套口径打架）。
final GoalPeriod _month = GoalPeriod.month(2026, 11);

/// 挂起月目标页（真库 + 真写入口，只把仓库与「今天」注入进去）。
Future<void> _pumpMonthPage(
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
            todayProvider.overrideWithValue('2026-11-25'),
          ],
          child: Scaffold(
            body: SingleChildScrollView(child: GoalsMonthPage(period: _month)),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('右栏列出未完成年目标，点一次派生一条本月月目标，再点一次不重复', (
    WidgetTester tester,
  ) async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    addTearDown(db.close);
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task72-w2-month',
    );
    final GoalStore store = GoalStore(repos);

    final String yearlyId = await store.createGoal(
      kind: GoalKind.yearly,
      title: '年度主攻',
      periodStart: GoalPeriod.year(2026).startMillis,
    );

    await _pumpMonthPage(tester, repos);

    // ① 右栏在，且列出了那条年目标。
    expect(
      find.byKey(GoalUpstreamPanel.panelKey(GoalKind.yearly)),
      findsOneWidget,
    );
    final Finder item = find.byKey(
      GoalUpstreamPanel.itemKey(GoalKind.yearly, yearlyId),
    );
    expect(item, findsOneWidget);
    // 标题在右栏与表单里各出现一次以上，这里只要求「至少有」。
    expect(find.text('年度主攻'), findsWidgets);

    // ② 点一次 ⇒ 库里多出一条**本月**月目标。
    await tester.tap(item);
    await tester.pumpAndSettle();

    GoalMonthView view = await store.monthView(_month);
    expect(view.monthGoals.length, 1);
    final GoalRow derived = view.monthGoals.single;
    expect(derived.kind, GoalKind.monthly);
    expect(derived.title, '年度主攻');
    expect(derived.periodStart, _month.startMillis);

    // 派生 = 「服务于」那条年目标（不是复制文本、也不是改父状态）。
    final List<GoalRow> parents = await store.servedGoals(derived.id);
    expect(parents.map((GoalRow g) => g.id), contains(yearlyId));

    // 父目标仍然是未完成（派生不改父状态）。
    final List<GoalRow> yearlyAfter = await store.listGoals(
      kind: GoalKind.yearly,
    );
    final Iterable<GoalRow> parent = yearlyAfter.where(
      (GoalRow g) => g.id == yearlyId,
    );
    expect(parent.single.status, GoalStatus.active);
    expect(parent.single.isDone, isFalse);

    // ③ 再点一次 ⇒ 幂等，不产生第二行。
    await tester.tap(item);
    await tester.pumpAndSettle();

    view = await store.monthView(_month);
    expect(
      view.monthGoals.length,
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
      deviceId: 'task72-w2-month-en',
    );

    await _pumpMonthPage(tester, repos, language: AppLanguage.en);

    final AppLocalizations en = AppLocalizations.en;
    expect(find.text(en.goalsUpstreamYearTitle), findsOneWidget);
    expect(find.text(en.goalsUpstreamAddHint), findsOneWidget);
    // 上游为空 ⇒ 落空态文案。
    expect(find.text(en.goalsUpstreamEmpty), findsOneWidget);
  });
}