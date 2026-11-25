// =============================================================================
// Task 65 · 目标页 UI 半批（B1）：页签壳 + 周目标页
// =============================================================================
// 本文件锁住 B1 的四条口径：
//  1. 四个页签（周｜月｜年｜蓝图），默认「周」；
//  2. **切页签不 push 路由**（同一页里换内容区，返回键不会在页签间打转）；
//  3. 上次停留的页签被记住（写偏好）；
//  4. 周页数据只来自 `weekView` 的读模型；滚动候选**只算不写**，用户点确认
//     才落库（落库状态 `draft`）。
//
// 测试不接真数据库：读侧 provider 与两个写入口（页签记忆 / 草稿写入）都被
// override 成记录器，于是「点了会发生什么」可以被逐字断言。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_week_table.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' show ActLogDatabase, openInMemoryActLogDatabase;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 记录路由 push 的观察者（用来证明「切页签不 push 路由」）。
class _PushRecorder extends NavigatorObserver {
  /// 被 push 的路由。
  final List<Route<dynamic>> pushes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes.add(route);
    super.didPush(route, previousRoute);
  }
}

/// 一条周目标行。
GoalRow _goal({
  required String id,
  required String title,
  GoalKind kind = GoalKind.weekly,
  Quadrant? quadrant,
}) => GoalRow(
  id: id,
  kind: kind,
  title: title,
  status: GoalStatus.active,
  periodStart: 0,
  createdAt: 0,
  updatedAt: 0,
  quadrant: quadrant,
);

/// 派生统计（完成度 1/2 ⇒ 50%）。
GoalExecutionStats _stats() => const GoalExecutionStats(
  tracksCount: 2,
  tracksInPeriod: 2,
  servesCount: 1,
  planItemTotal: 2,
  planItemDone: 1,
  planItemCancelled: 0,
  userCompleted: false,
  isDiscrepant: false,
  isUnplaced: false,
);

/// 一份非空的周视图。
GoalWeekView _view() => GoalWeekView(
  period: GoalPeriod.week(2026, 48),
  items: <GoalWeekItem>[
    GoalWeekItem(
      goal: _goal(id: 'g1', title: '把周报写完', quadrant: Quadrant.q1),
      stats: _stats(),
      order: 1,
      servedGoal: _goal(
        id: 'm1',
        title: '月度主攻',
        kind: GoalKind.monthly,
      ),
    ),
  ],
);

/// 一条滚动候选（结转）。
GoalDraft _draft() => const GoalDraft(
  kind: GoalKind.weekly,
  title: '延续上周目标',
  periodStart: 0,
  periodEnd: 0,
);

/// 造一组 override：读侧给数据，写侧给记录器。
List<Override> _overrides({
  GoalWeekView? view,
  List<GoalDraft>? drafts,
  List<List<GoalDraft>>? saved,
  List<String>? tabs,
}) => <Override>[
  goalWeekViewProvider.overrideWith((ref) async => view ?? _view()),
  goalWeeklyDraftsProvider.overrideWith(
    (ref) async => drafts ?? const <GoalDraft>[],
  ),
  goalDraftSaverProvider.overrideWithValue((List<GoalDraft> list) async {
    saved?.add(list);
    return list.length;
  }),
  goalsTabSaverProvider.overrideWithValue((String id) async {
    tabs?.add(id);
  }),
];

/// 挂起目标页（自带 MaterialApp + ProviderScope，只补一层 l10n）。
Future<void> _pumpGoals(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.zh,
  List<Override> overrides = const <Override>[],
  NavigatorObserver? observer,
}) async {
  tester.view.physicalSize = const Size(1300, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      navigatorObservers: observer == null
          ? const <NavigatorObserver>[]
          : <NavigatorObserver>[observer],
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(
              AppPreferences.defaults,
            ),
            ...overrides,
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalsPage()),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('目标页四个页签，默认落在「周」', (WidgetTester tester) async {
    await _pumpGoals(tester, overrides: _overrides());

    final AppLocalizations zh = AppLocalizations.zh;
    // 标题用 key 定位：周表列名「目标」与页标题同字，find.text 会撞车。
    final Finder title = find.byKey(const ValueKey<String>('goals-title'));
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).data, zh.goalsTitle);
    for (final String id in kGoalsTabIds) {
      expect(
        find.byKey(ValueKey<String>('goals-tab-$id')),
        findsOneWidget,
        reason: '缺少页签 $id',
      );
    }
    // 默认是「周」⇒ 周区块在，月/年的骨架不在。
    expect(find.text(zh.goalsWeekSection), findsOneWidget);
    expect(find.text(zh.goalsPlaceholderMonth), findsNothing);
    expect(find.text(zh.goalsPlaceholderYear), findsNothing);
    expect(find.text(zh.goalsPlaceholderBlueprint), findsNothing);
  });

  testWidgets('切页签只换内容区，不 push 路由', (WidgetTester tester) async {
    final _PushRecorder recorder = _PushRecorder();
    // B2 起月页是**真实实现**：给它一个空库（内存 drift），月页正文落真实空态。
    final ActLogDatabase db = openInMemoryActLogDatabase();
    addTearDown(db.close);
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task65-goals-test',
    );
    await _pumpGoals(
      tester,
      overrides: <Override>[
        ..._overrides(),
        repositoriesProvider.overrideWithValue(repos),
        todayProvider.overrideWithValue('2026-11-25'),
      ],
      observer: recorder,
    );

    // MaterialApp 挂初始路由时也会被观察者记一笔 ⇒ 先取基线，再看切页签有没有新增。
    final int pushesBefore = recorder.pushes.length;
    await tester.tap(find.byKey(const ValueKey<String>('goals-tab-month')));
    await tester.pumpAndSettle();

    expect(
      recorder.pushes.length,
      pushesBefore,
      reason: '切页签不得产生路由 push',
    );
    expect(
      recorder.pushes.where((Route<dynamic> r) => r.settings.name != '/'),
      isEmpty,
      reason: '只允许 MaterialApp 的初始路由被记录',
    );
    // 月页真实空态：本月无目标 ⇒「本月还没有目标。」（月页正文唯一一处）。
    expect(find.text(AppLocalizations.zh.goalMonthGoalsEmpty), findsOneWidget);
    expect(find.text(AppLocalizations.zh.goalsWeekSection), findsNothing);
  });

  testWidgets('切页签会记住这一页（写偏好）', (WidgetTester tester) async {
    final List<String> tabs = <String>[];
    await _pumpGoals(tester, overrides: _overrides(tabs: tabs));

    await tester.tap(find.byKey(const ValueKey<String>('goals-tab-year')));
    await tester.pump();

    expect(tabs, <String>[kGoalsTabYear]);
  });

  testWidgets('周页表格：表头 + 目标行 + 完成度 + 服务于',
      (WidgetTester tester) async {
    await _pumpGoals(tester, overrides: _overrides());

    final AppLocalizations zh = AppLocalizations.zh;
    // 表头断言限定在周表内：页标题「目标」与列名「目标」同字。
    final Finder table = find.byType(GoalWeekTable);
    expect(table, findsOneWidget);
    for (final String header in <String>[
      zh.goalsColumnOrder,
      zh.goalsColumnGoal,
      zh.goalsColumnQuadrant,
      zh.goalsColumnDue,
      zh.goalsColumnDone,
      zh.goalsColumnServes,
    ]) {
      expect(
        find.descendant(of: table, matching: find.text(header)),
        findsOneWidget,
        reason: '缺少表头 $header',
      );
    }

    expect(find.text('把周报写完'), findsOneWidget);
    expect(find.text('月度主攻'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget, reason: '完成度应显示 50%');
    expect(
      find.text('${zh.goalsCompletion} 50% · ${zh.goalsPlanItems} 1/2'),
      findsOneWidget,
    );
    expect(find.text(zh.quadrantQ1ShortLabel), findsOneWidget);
  });

  testWidgets('滚动候选：只算不写；用户点确认才落库',
      (WidgetTester tester) async {
    final List<List<GoalDraft>> saved = <List<GoalDraft>>[];
    await _pumpGoals(
      tester,
      overrides: _overrides(drafts: <GoalDraft>[_draft()], saved: saved),
    );

    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text(zh.goalsDraftSection), findsOneWidget);
    expect(
      find.text('${_draft().title} · ${zh.goalsDraftCarryOver}'),
      findsOneWidget,
    );
    // 还没点确认 ⇒ 库里 0 增量。
    expect(saved, isEmpty);

    await tester.tap(find.byKey(const ValueKey<String>('goals-draft-confirm')));
    await tester.pump();

    expect(saved.length, 1, reason: '点确认才允许写草稿');
    expect(saved.single.single.title, _draft().title);
    expect(find.text(zh.goalsDraftSaved), findsOneWidget);
  });

  testWidgets('没有候选时显示空态，不给确认按钮', (WidgetTester tester) async {
    await _pumpGoals(tester, overrides: _overrides());

    final AppLocalizations zh = AppLocalizations.zh;
    expect(find.text(zh.goalsDraftEmpty), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('goals-draft-confirm')), findsNothing);
  });

  testWidgets('英文态：页签与周区块走英文，界面不残留中文',
      (WidgetTester tester) async {
    await _pumpGoals(
      tester,
      language: AppLanguage.en,
      overrides: _overrides(),
    );

    final AppLocalizations en = AppLocalizations.en;
    expect(find.text(en.goalsTitle), findsOneWidget);
    expect(find.text(en.goalsTabWeek), findsOneWidget);
    expect(find.text(en.goalsWeekSection), findsOneWidget);
    expect(find.text(AppLocalizations.zh.goalsTitle), findsNothing);
    expect(find.text(AppLocalizations.zh.goalsWeekSection), findsNothing);
  });
}
