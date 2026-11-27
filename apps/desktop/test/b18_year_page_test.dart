// =============================================================================
// B18 · 年目标页去冗余（W3 写集）：分类名与完成态各只留一处
// =============================================================================
// B17 给年页加了「按类别分区」+「行尾完成单选」，副作用是同一份信息出现两次：
//  * 分类名：分区小标题（`goal-section-title-<displayKey>`）与行内「类别」列并存；
//  * 完成态：行尾完成单选（`goal-row-done-<id>`）与行内「进行中 / 已完成」文本列
//    并存，另有一列「完成」表头。
// B18 的裁决：
//  * **分类名唯一出处 = 分区小标题** ⇒ 行内类别列、表头「类别」列都必须消失；
//  * **完成态唯一出处 = 行尾完成单选** ⇒ 状态文本列、表头「完成」列都必须消失。
// l10n getter（`goalStatusActive` / `goalStatusDone` / `goalMonthColumnCategory`
// / `goalMonthColumnDone`）**保留不删**，只是本页不再渲染。
//
// 全部用例接**真库**（内存 drift），断言落在页面上真实渲染的文本 / 按键上，
// 不打桩、不 mock。
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
  GoalStatus status = GoalStatus.active,
}) {
  final GoalPeriod year = GoalPeriod.year(2026);
  return store.createGoal(
    kind: GoalKind.yearly,
    title: title,
    domain: domain,
    status: status,
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );
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

/// 某个控件最近的一层 `Row` 的格子数（用于「表头与行内逐位对应」）。
int _cellCount(WidgetTester tester, Finder target) => tester
    .widget<Row>(find.ancestor(of: target, matching: find.byType(Row)).first)
    .children
    .length;

/// 完成单选按钮当前的图标（空心圆 = 未完成，勾 = 已完成）。
IconData? _doneIcon(WidgetTester tester, String id) => tester
    .widget<Icon>(
      find.descendant(
        of: find.byKey(ValueKey<String>('goal-row-done-$id')),
        matching: find.byType(Icon),
      ),
    )
    .icon;

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b18-year-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('行内不再重复分类名：同类别两行 ⇒ 分类文本只剩分区小标题一处',
      (WidgetTester tester) async {
    await _seedYearly(store, title: '健身一', domain: 'health');
    await _seedYearly(store, title: '健身二', domain: 'health');
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;

    // 分区小标题是分类名的唯一出处，必须保留。
    expect(
      find.byKey(const ValueKey<String>('goal-section-title-health')),
      findsOneWidget,
      reason: 'B17 F 条的分区小标题必须保留（删了行内列后它是唯一出处）',
    );
    expect(
      find.text(zh.goalCategoryHealth),
      findsOneWidget,
      reason: '两行 + 小标题在 B17 是 3 处同名文本；行内类别列删掉后只剩小标题 1 处',
    );
  });

  testWidgets('行内不再重复完成态：不渲染「进行中 / 已完成」状态文本',
      (WidgetTester tester) async {
    await _seedYearly(store, title: '在办目标', domain: 'health');
    await _seedYearly(
      store,
      title: '办完目标',
      domain: 'health',
      status: GoalStatus.done,
    );
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    // 一 active 一 done：B17 时这两个文本各出现 1 次，B18 之后一律不出现。
    expect(
      find.text(zh.goalStatusActive),
      findsNothing,
      reason: '完成态只由行尾单选表达，不再有状态文本列',
    );
    expect(
      find.text(zh.goalStatusDone),
      findsNothing,
      reason: '完成态只由行尾单选表达，不再有状态文本列',
    );
  });

  testWidgets('表头同步去掉「类别」「完成」两列，且与行内格数逐位对应',
      (WidgetTester tester) async {
    final String id = await _seedYearly(store, title: '一格对数', domain: 'wealth');
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;

    // 保留的四列表头仍在。
    for (final String head in <String>[
      zh.goalMonthColumnIndex,
      zh.goalsColumnGoal,
      zh.goalMonthColumnMethods,
      zh.goalYearColumnPeriod,
    ]) {
      expect(find.text(head), findsOneWidget, reason: '表头「$head」必须保留');
    }
    // 两列冗余表头必须消失（l10n getter 本身保留，只是本页不渲染）。
    expect(
      find.text(zh.goalMonthColumnCategory),
      findsNothing,
      reason: '行内类别列已删 ⇒ 表头不能再留「类别」格',
    );
    expect(
      find.text(zh.goalMonthColumnDone),
      findsNothing,
      reason: '状态文本列已删 ⇒ 表头不能再留「完成」格',
    );

    // 表头格数与行内格数必须逐位对应（两侧各删 2 格）。
    expect(
      _cellCount(tester, find.text(zh.goalMonthColumnIndex)),
      _cellCount(
        tester,
        find.byKey(ValueKey<String>('goal-year-row-$id')),
      ),
      reason: '表头与数据行必须逐位对应，否则列错位',
    );
  });

  testWidgets('完成单选仍在：图标随完成态切换，且切换后仍无状态文本',
      (WidgetTester tester) async {
    final String id = await _seedYearly(store, title: '可勾目标', domain: 'learning');
    await _pumpYear(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    final Finder doneBtn = find.byKey(ValueKey<String>('goal-row-done-$id'));
    expect(doneBtn, findsOneWidget, reason: '行尾完成单选是本页唯一的完成态出口');
    expect(_doneIcon(tester, id), Icons.radio_button_unchecked);

    await tester.tap(doneBtn);
    await tester.pumpAndSettle();
    expect((await store.listGoals()).single.status, GoalStatus.done);
    expect(_doneIcon(tester, id), Icons.check_circle);
    expect(
      find.text(zh.goalStatusDone),
      findsNothing,
      reason: '勾完之后也不能冒出「已完成」文本列',
    );

    await tester.tap(find.byKey(ValueKey<String>('goal-row-done-$id')));
    await tester.pumpAndSettle();
    expect((await store.listGoals()).single.status, GoalStatus.active);
    expect(_doneIcon(tester, id), Icons.radio_button_unchecked);
  });
}