// =============================================================================
// B17 波 C · 月目标页（任务 D 下线两个入口 + 任务 F 类别分区 / 完成单选 / 表单透传）
// =============================================================================
// 本文件钉住 B17 月页的六条口径：
//  1. 「年度目标汇总条」的 UI 入口已下线（标题、行 key、空态 key 都不渲染）。
//  2. 「上月复盘」卡的 UI 入口已下线（标题、内容、空态 key 都不渲染）。
//  3. 本月目标区仍在，且月过滤口径没被改动（上月目标不会漏进来）。
//  4. 目标行按**类别分区**渲染：分区容器 `goal-section-<displayKey>`、小标题
//     `goal-section-title-<displayKey>`，标题文案走 `goalCategoryTitle`
//     （未分类 / 自定义都按 B17 裁决）。
//  5. 行尾**完成单选** `goal-row-done-<id>` 点了就落库（`status` 在
//     `active` ↔ `done` 之间切换），再点回来。
//  6. 编辑表单的两个新字段**透传写库**：
//     - 类别写 `domain`，且 `category` 优先（表单同时回 `domain` 与 `category`）；
//     - 起止日期写 `periodStart` / `periodEnd`，表单里「清空」真正清掉 `periodEnd`
//       （`periodStart` 定义月份归属 ⇒ 不清，这是 B17 裁决）。
//
// 测试接**真库**（内存 drift）：判据是「库里的真实字段值」，不是 UI 像素。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_month_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalKind, GoalPeriod, GoalStatus;
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
    required this.wealthId,
    required this.learningId,
    required this.customId,
    required this.unclassifiedId,
  });

  /// 类别 = `wealth`（财务目标）的本月目标。
  final String wealthId;

  /// 类别 = `learning`（学习成长）的本月目标。
  final String learningId;

  /// 类别 = `custom:副业` 的本月目标。
  final String customId;

  /// 已废弃的旧域值（`career`，不是 B17 类别键）⇒ 应归「未分类」。
  final String unclassifiedId;
}

/// 造数据：1 条年目标 + 1 条上月目标（用于钉月过滤）+ 4 条本月目标。
Future<_Seed> _seed(GoalStore store) async {
  final GoalPeriod year = GoalPeriod.year(2026);
  await store.createGoal(
    kind: GoalKind.yearly,
    title: '年度主攻',
    domain: 'career',
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );

  final GoalPeriod october = GoalPeriod.month(2026, 10);
  await store.createGoal(
    kind: GoalKind.monthly,
    title: '上月遗留事项',
    domain: 'wealth',
    periodStart: october.startMillis,
    periodEnd: october.endMillis,
  );

  final GoalPeriod november = GoalPeriod.month(2026, 11);
  final String wealthId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '存下应急金',
    domain: 'wealth',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  final String learningId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '读完三本书',
    domain: 'learning',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  final String customId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '开个小店',
    domain: 'custom:副业',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );
  final String unclassifiedId = await store.createGoal(
    kind: GoalKind.monthly,
    title: '杂事一件',
    domain: 'career',
    periodStart: november.startMillis,
    periodEnd: november.endMillis,
  );

  return _Seed(
    wealthId: wealthId,
    learningId: learningId,
    customId: customId,
    unclassifiedId: unclassifiedId,
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
    repos = ActLogRepositories(db, deviceId: 'b17-month-page-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('B17 月页：年度汇总条与上月复盘卡已下线，本月目标区仍在',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;
    // 任务 D：两个入口的标题都不再渲染。
    expect(find.text(zh.goalMonthYearBar), findsNothing);
    expect(find.text(zh.goalMonthReviewSection), findsNothing);
    // 两个入口的内部 key（行 / 空态）也不再出现。
    expect(
      find.byKey(const ValueKey<String>('goal-month-year-bar-empty')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-month-review-empty')),
      findsNothing,
    );
    // 本月目标区保留，行还在。
    expect(find.text(zh.goalMonthGoalsSection), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('goal-month-row-${seed.unclassifiedId}')),
      findsOneWidget,
    );
    // 月过滤口径未变：上月目标不会漏进本月表。
    expect(find.text('上月遗留事项'), findsNothing);
  });

  testWidgets('B17 月页：行按类别分区渲染，小标题与类别列都走 goalCategoryTitle',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final AppLocalizations zh = AppLocalizations.zh;

    // 分区容器 + 小标题：预设类别、自定义类别、未分类垫底三种都出。
    for (final String key in <String>[
      'wealth',
      'learning',
      'custom:副业',
      'none',
    ]) {
      expect(
        find.byKey(ValueKey<String>('goal-section-$key')),
        findsOneWidget,
        reason: '缺少类别分区 $key',
      );
      expect(
        find.byKey(ValueKey<String>('goal-section-title-$key')),
        findsOneWidget,
        reason: '缺少类别小标题 $key',
      );
    }
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-section-title-wealth')),
          )
          .data,
      zh.goalCategoryWealth,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-section-title-learning')),
          )
          .data,
      zh.goalCategoryLearning,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-section-title-custom:副业')),
          )
          .data,
      '副业',
      reason: '自定义类别的标题就是用户文本',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-section-title-none')),
          )
          .data,
      zh.goalCategoryUncategorized,
      reason: '旧域值 career 不是 B17 类别键 ⇒ 归未分类',
    );

    // 类别列同样走 `goalCategoryTitle`（不分区前的 `projectDomainLabel` 已换掉）：
    // 学习成长的类别格里是「学习成长」，不是旧的项目域文案。
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('goal-section-learning')),
        matching: find.text(zh.goalCategoryLearning),
      ),
      findsNWidgets(2),
      reason: '一行 = 小标题 + 类别列各出现一次',
    );

    // 行顺序按分区走：学习成长分区里就是那条学习目标。
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('goal-section-learning')),
        matching: find.byKey(
          ValueKey<String>('goal-month-row-${seed.learningId}'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('B17 月页：行尾完成单选点了就落库，再点回进行中',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final String id = seed.wealthId;
    expect((await _row(store, id)).status, GoalStatus.active);

    final Finder done = find.byKey(ValueKey<String>('goal-row-done-$id'));
    expect(done, findsOneWidget, reason: '月页行尾必须渲染完成单选');

    await tester.tap(done);
    await tester.pumpAndSettle();
    final GoalRow afterDone = await _row(store, id);
    expect(afterDone.status, GoalStatus.done);
    expect(afterDone.isDone, isTrue);

    await tester.tap(find.byKey(ValueKey<String>('goal-row-done-$id')));
    await tester.pumpAndSettle();
    final GoalRow afterUndo = await _row(store, id);
    expect(afterUndo.status, GoalStatus.active);
    expect(afterUndo.isDone, isFalse);
  });

  testWidgets('B17 月页：编辑表单的类别写回 domain（category 优先于旧 domain）',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    await tester.tap(
      find.byKey(ValueKey<String>('goal-month-row-edit-${seed.learningId}')),
    );
    await tester.pumpAndSettle();

    // 类别：学习成长 → 自定义「副业」。
    await tester.tap(find.byKey(const ValueKey<String>('goal-form-category-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('goal-form-category-custom')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-form-category-custom-input')),
      '副业',
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
    );
    await tester.pumpAndSettle();

    final GoalRow row = await _row(store, seed.learningId);
    expect(row.domain, 'custom:副业', reason: '类别写回 domain，且形如 custom:<文本>');
    expect(row.title, '读完三本书', reason: '只改类别，标题不动');
    // 没动的起止日期不得被清掉（表单把既有值原样回传）。
    expect(row.periodEnd, isNotNull);
  });

  testWidgets('B17 月页：编辑表单的起止日期透传，清空时真正清掉 periodEnd',
      (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpMonth(tester, repos: repos);

    final GoalRow before = await _row(store, seed.wealthId);
    expect(before.periodEnd, isNotNull, reason: '前置：本月目标带起止日期');

    await tester.tap(
      find.byKey(ValueKey<String>('goal-month-row-edit-${seed.wealthId}')),
    );
    await tester.pumpAndSettle();

    // 起止日期：点开对话框 → 「清空」（该按钮直接把结果 pop 回表单）。
    await tester.tap(find.byKey(const ValueKey<String>('goal-form-date-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('goal-period-clear')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-form-date-range-text')),
          )
          .data,
      AppLocalizations.zh.goalPeriodUnset,
      reason: '前置：对话框的「清空」已回填到表单',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
    );
    await tester.pumpAndSettle();

    final GoalRow row = await _row(store, seed.wealthId);
    expect(row.periodEnd, isNull, reason: '表单清空 ⇒ periodEnd 走 clear 真被清掉');
    expect(
      row.periodStart,
      before.periodStart,
      reason: 'periodStart 定义月份归属、且领域模型没有对应 GoalField ⇒ 本页不清',
    );
  });
}