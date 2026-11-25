// =============================================================================
// Task 74 · 批次 B8 · W2：目标三页（月 / 周 / 年）行内「编辑 / 删除」用例
// =============================================================================
// 判据（派工书 `docs/b82-dispatch-w2.md` §5）：
//  1. 三页每条既有目标行都带 `goal-<scope>-row-edit-<id>` /
//     `goal-<scope>-row-delete-<id>` 两个键；
//  2. 点编辑 ⇒ 表单按库里值预填 ⇒ 改标题保存后**库里真的变了**；
//  3. 编辑**不改档位**：本来没有 horizon 的月/年/周目标，保存后仍是 null；
//  4. 点删除 ⇒ 取消不写库；确认后行消失、库里读不到（软删）；
//  5. 删空后回落到各页既有空态键。
//
// 与既有用例同策略：真内存 drift + 真 `GoalStore`，不 mock 写入口。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_month_page.dart';
import 'package:actlog/src/pages/goals_week_page.dart';
import 'package:actlog/src/pages/goals_year_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
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

/// 与 [_today] 对应的本周 / 本月 / 本年周期。
final GoalPeriod _week = GoalPeriod.week(2026, 48);
final GoalPeriod _month = GoalPeriod.month(2026, 11);
final GoalPeriod _year = GoalPeriod.year(2026);

/// 打开一张真内存库，返回 `(repos, store)`；库由 tearDown 关。
(ActLogRepositories, GoalStore) _open(String deviceId) {
  final ActLogDatabase db = openInMemoryActLogDatabase();
  addTearDown(db.close);
  final ActLogRepositories repos = ActLogRepositories(db, deviceId: deviceId);
  return (repos, GoalStore(repos));
}

/// 挂起某一页（真 MaterialApp + ProviderScope + l10n，形制抄 task66/task72）。
Future<void> _pump(
  WidgetTester tester,
  Widget page,
  ActLogRepositories repos,
) async {
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
            todayProvider.overrideWithValue(_today),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(body: SingleChildScrollView(child: page)),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 读一个表单 TextField 的当前文本。
String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey<String>(key))).controller!.text;

/// 点行内「编辑」⇒ 断言预填 ⇒ 改名 ⇒ 保存。
Future<void> _renameViaRow(
  WidgetTester tester, {
  required String scope,
  required String id,
  required String expectPrefill,
  required String newTitle,
}) async {
  await tester.tap(find.byKey(ValueKey<String>('goal-$scope-row-edit-$id')));
  await tester.pumpAndSettle();

  expect(
    _fieldText(tester, 'goal-blueprint-form-title'),
    expectPrefill,
    reason: '编辑表单必须按库里既有值预填（否则保存会把没改的字段写坏）',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
    newTitle,
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
  );
  await tester.pumpAndSettle();
}

/// 点行内「删除」⇒ 先取消（必须不写库）⇒ 再确认。
Future<void> _deleteViaRow(
  WidgetTester tester, {
  required String scope,
  required String id,
  required GoalStore store,
}) async {
  // ① 取消：不许有隐式写入。
  await tester.tap(find.byKey(ValueKey<String>('goal-$scope-row-delete-$id')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey<String>('goal-blueprint-delete-cancel')),
  );
  await tester.pumpAndSettle();
  expect(
    await store.findGoal(id),
    isNotNull,
    reason: '在删除确认框点取消 ⇒ 不得写库',
  );

  // ② 确认：软删 ⇒ 读不到。
  await tester.tap(find.byKey(ValueKey<String>('goal-$scope-row-delete-$id')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey<String>('goal-blueprint-delete-confirm')),
  );
  await tester.pumpAndSettle();
  expect(await store.findGoal(id), isNull, reason: '确认删除后库里不应再读到该目标');
}

void main() {
  testWidgets('月页：行内编辑写回库（不动档位）、删除取消不写库、确认后回空态', (
    WidgetTester tester,
  ) async {
    final (ActLogRepositories repos, GoalStore store) = _open('task74-month');
    final String id = await store.createGoal(
      kind: GoalKind.monthly,
      title: '月度主攻',
      periodStart: _month.startMillis,
      periodEnd: _month.endMillis,
    );

    await _pump(tester, GoalsMonthPage(period: _month), repos);

    expect(find.byKey(ValueKey<String>('goal-month-row-$id')), findsOneWidget);

    await _renameViaRow(
      tester,
      scope: 'month',
      id: id,
      expectPrefill: '月度主攻',
      newTitle: '月度新标题',
    );

    final GoalRow? edited = await store.findGoal(id);
    expect(edited!.title, '月度新标题');
    expect(
      edited.horizon,
      isNull,
      reason: '月目标本来没有档位，编辑保存不得隐式赋 ultimate（_keptHorizon）',
    );
    expect(find.byKey(ValueKey<String>('goal-month-row-$id')), findsOneWidget);
    expect(find.text('月度新标题'), findsWidgets);

    await _deleteViaRow(tester, scope: 'month', id: id, store: store);

    expect(find.byKey(ValueKey<String>('goal-month-row-$id')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('goal-month-goals-empty')),
      findsOneWidget,
      reason: '删空后必须回落到本页既有空态（不新造空态键）',
    );
  });

  testWidgets('年页：行内编辑写回库（不动档位）、删除取消不写库、确认后回空态', (
    WidgetTester tester,
  ) async {
    final (ActLogRepositories repos, GoalStore store) = _open('task74-year');
    final String id = await store.createGoal(
      kind: GoalKind.yearly,
      title: '年度主线',
      periodStart: _year.startMillis,
      periodEnd: _year.endMillis,
    );

    await _pump(tester, GoalsYearPage(period: _year), repos);

    expect(find.byKey(ValueKey<String>('goal-year-row-$id')), findsOneWidget);

    await _renameViaRow(
      tester,
      scope: 'year',
      id: id,
      expectPrefill: '年度主线',
      newTitle: '年度新主线',
    );

    final GoalRow? edited = await store.findGoal(id);
    expect(edited!.title, '年度新主线');
    expect(edited.horizon, isNull, reason: '年目标本来没有档位 ⇒ 保存后仍为 null');
    expect(find.byKey(ValueKey<String>('goal-year-row-$id')), findsOneWidget);
    expect(find.text('年度新主线'), findsWidgets);

    await _deleteViaRow(tester, scope: 'year', id: id, store: store);

    expect(find.byKey(ValueKey<String>('goal-year-row-$id')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('goal-year-goals-empty')),
      findsOneWidget,
      reason: '删空后必须回落到本页既有空态（不新造空态键）',
    );
  });

  testWidgets('周页：行内编辑写回库（不动档位）、删除取消不写库、确认后回空态', (
    WidgetTester tester,
  ) async {
    final (ActLogRepositories repos, GoalStore store) = _open('task74-week');
    final String id = await store.createGoal(
      kind: GoalKind.weekly,
      title: '本周主攻',
      periodStart: _week.startMillis,
      periodEnd: _week.endMillis,
    );

    await _pump(tester, const GoalsWeekPage(), repos);

    // 周表历来没有 `goal-week-row-<id>` 这个键（契约里周页只新增操作列的
    // `goal-week-row-edit/delete-<id>`），所以这里以操作列键为准。
    expect(
      find.byKey(ValueKey<String>('goal-week-row-edit-$id')),
      findsOneWidget,
      reason: '周页表体必须为既有周目标行渲染行内编辑入口',
    );

    await _renameViaRow(
      tester,
      scope: 'week',
      id: id,
      expectPrefill: '本周主攻',
      newTitle: '本周新主攻',
    );

    final GoalRow? edited = await store.findGoal(id);
    expect(edited!.title, '本周新主攻');
    expect(edited.horizon, isNull, reason: '周目标本来没有档位 ⇒ 保存后仍为 null');
    expect(find.text('本周新主攻'), findsWidgets);

    await _deleteViaRow(tester, scope: 'week', id: id, store: store);

    expect(find.byKey(ValueKey<String>('goal-week-row-edit-$id')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('goals-week-empty')),
      findsOneWidget,
      reason: '删空后必须回落到本页既有空态（不新造空态键）',
    );
  });
}