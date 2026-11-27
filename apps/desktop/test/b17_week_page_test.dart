// =============================================================================
// B17 波 C · W6：周目标页接「任务 F」四项
// =============================================================================
// 本文件锁住 B17 任务 F 在**周**页上的四条口径：
//  1. 目标行按类别分区渲染，出分区小标题（`goal-section-*` /
//     `goal-section-title-*`），标题走 `goalCategoryTitle`（不是
//     `projectDomainLabel`），空 / 未知 domain 一律落到「未分类」；
//  2. 行右侧有可点击的完成单选（`goal-row-done-<id>`），点一下切完成态并
//     **落库**（`status` 变 `done`），再点一下回到 `active`；
//  3. 表单的新字段透传：类别（`category` 优先于遗留 `domain`）与起止日期
//     （清空结束日期要能把 `periodEnd` 写回 null）；
//  4. **不回退 B16**：常驻录入行仍可点可加（`goal-week-input*`），上游目标
//     拖入的放置目标仍在（`goal-week-drop-target`）。
//
// 走真库（内存 drift）：同一条目标既要能点、又要能读回库里的 `status` /
// `domain` / `periodEnd`，用记录器替身无法证明「确实落库」。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_week_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' show ActLogDatabase, openInMemoryActLogDatabase;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 固定「今天」⇒ 当前周恒为 `GoalPeriod.week(2026, 48)`。
const String _today = '2026-11-25';

/// 一内存库 + 仓库 + 目标仓（页面与断言共用同一个 `GoalStore`）。
(ActLogRepositories, GoalStore) _open(String deviceId) {
  final ActLogDatabase db = openInMemoryActLogDatabase();
  addTearDown(db.close);
  final ActLogRepositories repos = ActLogRepositories(db, deviceId: deviceId);
  return (repos, GoalStore(repos));
}

/// 挂起周目标页（真库 + 固定今天）。
Future<GoalStore> _pumpWeek(
  WidgetTester tester,
  ActLogRepositories repos,
  GoalStore store,
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
            goalStoreProvider.overrideWithValue(store),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalsWeekPage()),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

/// 当前周（固定 today 下）。
GoalPeriod _week() => GoalPeriod.week(2026, 48);

Finder _key(String key) => find.byKey(ValueKey<String>(key));

void main() {
  testWidgets('F-①：行按类别分区，出小标题，未知值并入「未分类」',
      (WidgetTester tester) async {
    final (ActLogRepositories repos, GoalStore store) = _open('b17-w6-sections');
    final int start = _week().startMillis;
    // 三条已知类别 + 一条未知 domain（历史脏值 ⇒ 未分类）。
    await store.createGoal(
      kind: GoalKind.weekly,
      title: '理财复盘',
      domain: 'wealth',
      periodStart: start,
    );
    await store.createGoal(
      kind: GoalKind.weekly,
      title: '夜跑三次',
      domain: 'health',
      periodStart: start,
    );
    await store.createGoal(
      kind: GoalKind.weekly,
      title: '读两章书',
      domain: 'legacy-unknown',
      periodStart: start,
    );
    await _pumpWeek(tester, repos, store);

    final AppLocalizations zh = AppLocalizations.zh;
    // 分区容器与小标题都在。
    for (final String displayKey in <String>['wealth', 'health', 'none']) {
      expect(
        _key('goal-section-$displayKey'),
        findsOneWidget,
        reason: '缺少分区 goal-section-$displayKey',
      );
      expect(
        _key('goal-section-title-$displayKey'),
        findsOneWidget,
        reason: '缺少分区小标题 goal-section-title-$displayKey',
      );
    }
    // 标题文案走 `goalCategoryTitle` 口径（不是 `projectDomainLabel`）。
    expect(
      tester.widget<Text>(_key('goal-section-title-wealth')).data,
      zh.goalCategoryWealth,
    );
    expect(
      tester.widget<Text>(_key('goal-section-title-health')).data,
      zh.goalCategoryHealth,
    );
    expect(
      tester.widget<Text>(_key('goal-section-title-none')).data,
      zh.goalCategoryUncategorized,
    );

    // 行进对应分区：理财行在 wealth 分区内，未知值行进 none 分区。
    expect(
      find.descendant(
        of: _key('goal-section-wealth'),
        matching: find.text('理财复盘'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _key('goal-section-none'),
        matching: find.text('读两章书'),
      ),
      findsOneWidget,
      reason: '未知 domain 必须并入「未分类」',
    );

    // 分区顺序按 `goalCategoryKeys` 的固定次序（wealth 在 health 之前，
    // 未分类收尾）。
    final double wealthY = tester.getTopLeft(_key('goal-section-title-wealth')).dy;
    final double healthY = tester.getTopLeft(_key('goal-section-title-health')).dy;
    final double noneY = tester.getTopLeft(_key('goal-section-title-none')).dy;
    expect(wealthY, lessThan(healthY));
    expect(healthY, lessThan(noneY));
  });

  testWidgets('F-②：行内完成单选点了就落库，再点回到进行中',
      (WidgetTester tester) async {
    final (ActLogRepositories repos, GoalStore store) = _open('b17-w6-toggle');
    final String id = await store.createGoal(
      kind: GoalKind.weekly,
      title: '把周报写完',
      domain: 'wealth',
      periodStart: _week().startMillis,
    );
    await _pumpWeek(tester, repos, store);

    final Finder done = _key('goal-row-done-$id');
    expect(done, findsOneWidget, reason: '行右侧应有完成单选');
    expect(
      (await store.findGoal(id))!.status,
      GoalStatus.active,
      reason: '起始态应是进行中',
    );

    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(
      (await store.findGoal(id))!.status,
      GoalStatus.done,
      reason: '点一下完成单选必须落库为 done',
    );

    // 完成态的行仍在本周视图里（周视图不按状态过滤），再点回到 active。
    expect(_key('goal-row-done-$id'), findsOneWidget);
    await tester.tap(_key('goal-row-done-$id'));
    await tester.pumpAndSettle();
    expect((await store.findGoal(id))!.status, GoalStatus.active);
  });

  testWidgets('F-③：表单类别与起止日期透传（category 优先、periodEnd 可清空）',
      (WidgetTester tester) async {
    final (ActLogRepositories repos, GoalStore store) = _open('b17-w6-form');
    final GoalPeriod week = _week();
    final String id = await store.createGoal(
      kind: GoalKind.weekly,
      title: '写季度复盘',
      // 遗留领域值：表单里改成「健康休闲」后，库里必须变成 health。
      domain: 'learning',
      periodStart: week.startMillis,
      periodEnd: week.endMillis,
    );
    await _pumpWeek(tester, repos, store);

    // 打开行内表单式编辑。
    await tester.tap(_key('goal-week-row-edit-$id'));
    await tester.pumpAndSettle();
    expect(_key('goal-form-category-field'), findsOneWidget);
    expect(_key('goal-form-date-range'), findsOneWidget);

    // 类别：点开菜单选「健康休闲」。
    await tester.tap(_key('goal-form-category-text'));
    await tester.pumpAndSettle();
    await tester.tap(_key('goal-form-category-health'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_key('goal-form-category-text')).data,
        AppLocalizations.zh.goalCategoryHealth);

    // 起止日期：点整行进共享弹窗，清空结束日期。
    await tester.ensureVisible(_key('goal-form-date-range'));
    await tester.tap(_key('goal-form-date-range'));
    await tester.pumpAndSettle();
    expect(_key('goal-period-dialog'), findsOneWidget);
    await tester.tap(_key('goal-period-clear'));
    await tester.pumpAndSettle();
    // 显示口径同步：两端都空 ⇒「未设置日期」。
    expect(
      tester.widget<Text>(_key('goal-form-date-range-text')).data,
      AppLocalizations.zh.goalPeriodUnset,
    );

    await tester.tap(_key('goal-blueprint-form-save'));
    await tester.pumpAndSettle();

    final GoalRow row = (await store.findGoal(id))!;
    expect(
      row.domain,
      'health',
      reason: '类别（category）必须覆盖遗留 domain 落同一列',
    );
    expect(
      row.periodEnd,
      isNull,
      reason: '表单清空结束日期后必须把 periodEnd 写回 null',
    );
    expect(
      row.periodStart,
      week.startMillis,
      reason: '日期透传不得把起始日期写坏',
    );
  });

  testWidgets('B16 不回退：录入行仍可点可加，拖放目标仍在',
      (WidgetTester tester) async {
    final (ActLogRepositories repos, GoalStore store) = _open('b17-w6-input');
    await _pumpWeek(tester, repos, store);

    // 空库 ⇒ 左侧空态，但录入行与放置目标都要在。
    expect(_key('goals-week-empty'), findsOneWidget);
    expect(_key('goal-week-drop-target'), findsOneWidget);
    expect(_key('goal-week-input-row'), findsOneWidget);

    await tester.enterText(_key('goal-week-input'), '把 B17 周页收口');
    await tester.tap(_key('goal-week-input-add'));
    await tester.pumpAndSettle();

    final List<GoalRow> created = await store.listGoals(
      kind: GoalKind.weekly,
    );
    expect(created, hasLength(1), reason: '录入行必须能把目标写进库');
    expect(created.single.title, '把 B17 周页收口');
    expect(created.single.periodStart, _week().startMillis);
    // 录入后行仍在（连续录入），输入框已清空，表格已出现。
    expect(_key('goal-week-input-row'), findsOneWidget);
    expect(_key('goal-week-drop-target'), findsOneWidget);
    expect(find.text('把 B17 周页收口'), findsOneWidget);
  });
}