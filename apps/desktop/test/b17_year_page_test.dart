// =============================================================================
// B17 · 年目标页（W4 写集）：新增 / 编辑 / 完成 / 类别分区
// =============================================================================
// 本文件钉派工书三条：
//  * **C 条（最重要）**：年目标行能新增（空态 + 非空态）与编辑（行内），
//    保存后列表**立刻**反映（走真表单 + 真 `GoalStore`，不打桩）。
//  * **E 条**：表二 / 年度复盘 / 80-20 三块 UI 入口下线 —— 本页只剩表一，
//    反向断言在 `task66_goals_year_page_test.dart` 里。
//  * **F 条**：类别 / 起止日期 / 完成单选 / 按类别分区小标题。
//
// B18 W3 去冗余：行内「类别」列与「进行中 / 已完成」文本列已删 ⇒ 完成态断言
// 从「状态文本」改成「行尾完成单选的图标」；用例**一个都没删**。
//
// 全部用例接**真库**（内存 drift）与**真表单**（`showGoalFormDialog`）：判据是
// 「库里的真实行」+「页面上真实渲染的键」，不打桩、不 mock。
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
    show GoalKind, GoalPeriod, GoalStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 直接落一条年目标（本页周期的窗口内，保证它一定出现在年表里）。
Future<String> _seedYearly(
  GoalStore store, {
  required String title,
  String? domain,
}) {
  final GoalPeriod year = GoalPeriod.year(2026);
  return store.createGoal(
    kind: GoalKind.yearly,
    title: title,
    domain: domain,
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );
}

/// 读某个 TextField 的当前文本（编辑态预填判据）。
String _fieldText(WidgetTester tester, String key) => tester
    .widget<TextField>(find.byKey(ValueKey<String>(key)))
    .controller!
    .text;

/// 在表单里填标题并保存。
///
/// 注意：新增态的保存按钮在标题为空时是**禁用**的，`enterText` 只改 controller
/// 与触发 `onChanged`，必须补一帧 `pump()` 让按钮重建为可用，否则后续 `tap`
/// 落在禁用按钮上（静默无操作，表单不关）。
Future<void> _fillTitleAndSave(WidgetTester tester, String title) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
    title,
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
  );
  await tester.pumpAndSettle();
}

/// 挂起年目标页（自带 MaterialApp + ProviderScope，只补一层 l10n）。
Future<void> _pumpYear(
  WidgetTester tester, {
  required ActLogRepositories repos,
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
        language: AppLanguage.zh,
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
    repos = ActLogRepositories(db, deviceId: 'b17-year-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('C：空态点「新建目标」能落一条年目标，列表立刻出现',
      (WidgetTester tester) async {
    await _pumpYear(tester, repos: repos);

    // 空态：入口与空态文案同时在（入口不能被空态吞掉）。
    final Finder add = find.byKey(const ValueKey<String>('goal-year-add'));
    expect(add, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-year-goals-empty')),
      findsOneWidget,
    );

    await tester.tap(add);
    await tester.pumpAndSettle();
    await _fillTitleAndSave(tester, '年度新增');

    final List<GoalRow> rows = await store.listGoals();
    expect(rows, hasLength(1));
    final GoalRow created = rows.single;
    expect(created.kind, GoalKind.yearly);
    expect(created.title, '年度新增');
    // 起止默认落在本页周期内 ⇒ 新行一定属于本年。
    expect(created.periodStart, GoalPeriod.year(2026).startMillis);
    expect(created.periodEnd, GoalPeriod.year(2026).endMillis);

    expect(
      find.byKey(ValueKey<String>('goal-year-row-${created.id}')),
      findsOneWidget,
      reason: '保存后列表必须立刻反映（不能只在库里）',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-year-goals-empty')),
      findsNothing,
    );
  });

  testWidgets('C：非空态也能新增，两条都渲染',
      (WidgetTester tester) async {
    final String first = await _seedYearly(
      store,
      title: '已有目标',
      domain: 'wealth',
    );
    await _pumpYear(tester, repos: repos);
    expect(
      find.byKey(ValueKey<String>('goal-year-row-$first')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('goal-year-add')));
    await tester.pumpAndSettle();
    await _fillTitleAndSave(tester, '第二条');

    final List<GoalRow> rows = await store.listGoals();
    expect(rows, hasLength(2));
    for (final GoalRow row in rows) {
      expect(
        find.byKey(ValueKey<String>('goal-year-row-${row.id}')),
        findsOneWidget,
        reason: '新增后两条目标都要在表一里',
      );
    }
  });

  testWidgets('C+F：行内编辑改标题 + 选类别，库与分区标题一起变',
      (WidgetTester tester) async {
    final String id = await _seedYearly(store, title: '旧标题');
    await _pumpYear(tester, repos: repos);
    // 无类别 ⇒ 未分类分区。
    expect(
      find.byKey(const ValueKey<String>('goal-section-none')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey<String>('goal-year-row-edit-$id')),
    );
    await tester.pumpAndSettle();

    // 编辑 ≠ 重填：既有标题必须预填在表单里。
    expect(_fieldText(tester, 'goal-blueprint-form-title'), '旧标题');

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      '新标题',
    );
    // 类别改用「财富」（`Goal.domain` 一列，B17 裁决 1）。
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-wealth')).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
    );
    await tester.pumpAndSettle();

    final GoalRow saved = (await store.listGoals()).single;
    expect(saved.id, id, reason: '编辑是更新，不是新建');
    expect(saved.title, '新标题');
    expect(saved.domain, 'wealth');

    expect(
      find.byKey(const ValueKey<String>('goal-section-title-wealth')),
      findsOneWidget,
      reason: '改类别后分区小标题必须跟着变',
    );
    expect(find.text('新标题'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-section-none')),
      findsNothing,
    );
  });

  testWidgets('F：完成单选写 status，再点回到未完成',
      (WidgetTester tester) async {
    final String id = await _seedYearly(
      store,
      title: '要勾的目标',
      domain: 'health',
    );
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    final Finder done = find.byKey(ValueKey<String>('goal-row-done-$id'));
    // 完成单选的图标 = 完成态的唯一可读表达（B18 W3：行内状态文本列已删）。
    IconData? doneIcon() => tester
        .widget<Icon>(
          find.descendant(of: done, matching: find.byType(Icon)),
        )
        .icon;

    expect(done, findsOneWidget, reason: '年页行尾必须有完成单选');
    // B18 W3：不再有「进行中 / 已完成」文本列 ⇒ 改成 findsNothing + 图标断言。
    expect(find.text(zh.goalStatusActive), findsNothing);
    expect(doneIcon(), Icons.radio_button_unchecked);

    await tester.tap(done);
    await tester.pumpAndSettle();
    expect((await store.listGoals()).single.status, GoalStatus.done);
    expect(find.text(zh.goalStatusDone), findsNothing);
    expect(doneIcon(), Icons.check_circle);

    await tester.tap(find.byKey(ValueKey<String>('goal-row-done-$id')));
    await tester.pumpAndSettle();
    expect((await store.listGoals()).single.status, GoalStatus.active);
    expect(find.text(zh.goalStatusActive), findsNothing);
    expect(doneIcon(), Icons.radio_button_unchecked);
  });

  testWidgets('F：两个类别 + 未分类 ⇒ 分区按预设顺序且未分类垫底',
      (WidgetTester tester) async {
    final String health = await _seedYearly(
      store,
      title: '健康目标',
      domain: 'health',
    );
    final String wealth = await _seedYearly(
      store,
      title: '财富目标',
      domain: 'wealth',
    );
    final String none = await _seedYearly(store, title: '无类别目标');
    await _pumpYear(tester, repos: repos);

    for (final String key in <String>['health', 'wealth', 'none']) {
      expect(
        find.byKey(ValueKey<String>('goal-section-$key')),
        findsOneWidget,
        reason: '分区 $key 必须渲染',
      );
      expect(
        find.byKey(ValueKey<String>('goal-section-title-$key')),
        findsOneWidget,
      );
    }
    for (final String id in <String>[health, wealth, none]) {
      expect(
        find.byKey(ValueKey<String>('goal-year-row-$id')),
        findsOneWidget,
      );
    }

    double top(String key) => tester
        .getTopLeft(find.byKey(ValueKey<String>('goal-section-$key')))
        .dy;
    expect(
      top('wealth'),
      lessThan(top('health')),
      reason: '预设顺序：wealth 在 health 之前',
    );
    expect(top('health'), lessThan(top('none')), reason: '未分类垫底');
  });

  }