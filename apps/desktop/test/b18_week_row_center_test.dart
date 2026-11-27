// =============================================================================
// B18 · W1：周目标表行内垂直居中
// =============================================================================
// 用户口径（B18 反馈 R2）：**每一行数据保持垂直居中**。改前表头行与数据行
// 都是 `CrossAxisAlignment.start` ⇒ 行内各格**上缘**对齐，而各格高度不等
// （顺序号是 labelSmall 单行 ≈ 16.25、行尾完成单选是 28 高、标题格是「标题 +
// 次级行」两行 ≈ 43）⇒ 视觉上标题多行时下方各列整体偏上，看着错位。
//
// 本文件锁两条判据：
//  1. **数据行**：同一行里两个可定位的直接子格（顺序号文本 `goal-week-order-<id>`
//     ↔ 行尾完成单选 `goal-row-done-<id>`）的 `center.dy` 之差 ≤ 1px。
//     这两格高度故意差很多（16.25 vs 28），上缘对齐时中心线必然差 ≈ 5.9px，
//     居中后差 0 ⇒ 判据有鉴别力（改前必红、改后必绿）。
//  2. **表头行**：表头各格都是同一 `headerStyle` 的单行文本，**几何上分不出**
//     start / center（高度相同 ⇒ 中心线一致）⇒ 对齐口径只能按结构断言，
//     故给表头 `Row` 加了定位键 `goal-week-header-row` 直接读它的
//     `crossAxisAlignment`。
//
// 走真库（内存 drift）+ 真页面：判据是布局几何，必须在真实列宽 / flex 下量。
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

/// 一内存库 + 仓库 + 目标仓。
(ActLogRepositories, GoalStore) _open(String deviceId) {
  final ActLogDatabase db = openInMemoryActLogDatabase();
  addTearDown(db.close);
  final ActLogRepositories repos = ActLogRepositories(db, deviceId: deviceId);
  return (repos, GoalStore(repos));
}

/// 挂起周目标页（真库 + 固定今天 + 舒适档）。
Future<void> _pumpWeek(
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
}

/// 当前周（固定 today 下）。
GoalPeriod _week() => GoalPeriod.week(2026, 48);

Finder _key(String key) => find.byKey(ValueKey<String>(key));

void main() {
  testWidgets('数据行：顺序号与行尾完成单选的垂直中心线一致（≤ 1px）',
      (WidgetTester tester) async {
    final (ActLogRepositories repos, GoalStore store) = _open('b18-w1-center');
    // 长标题：贴用户报的症状（标题多行 ⇒ 标题格比其它格高得多）。
    final String id = await store.createGoal(
      kind: GoalKind.weekly,
      title: '把本周的理财复盘、夜跑三次、读书两章和季度总结全部整理成一份可执行的周清单',
      domain: 'wealth',
      periodStart: _week().startMillis,
    );
    await _pumpWeek(tester, repos, store);

    final Finder order = _key('goal-week-order-$id');
    final Finder done = _key('goal-row-done-$id');
    expect(order, findsOneWidget, reason: '顺序号文本应可按 goal-week-order-<id> 定位');
    expect(done, findsOneWidget, reason: '行尾完成单选应可按 goal-row-done-<id> 定位');

    final Rect orderRect = tester.getRect(order);
    final Rect doneRect = tester.getRect(done);

    // 诊断（红跑时打印实际几何，便于核对判据是否真被触发）。
    // ignore: avoid_print
    print(
      'B18-W1 geometry: order=$orderRect done=$doneRect '
      'orderCenter.dy=${orderRect.center.dy} doneCenter.dy=${doneRect.center.dy}',
    );

    final double gap = (orderRect.center.dy - doneRect.center.dy).abs();
    expect(
      gap,
      lessThanOrEqualTo(1.0),
      reason: '同一行内各格必须垂直居中：中心线之差应 ≤ 1px，实测 $gap px',
    );
  });

  testWidgets('表头行：对齐口径是垂直居中（crossAxisAlignment = center）',
      (WidgetTester tester) async {
    final (ActLogRepositories repos, GoalStore store) = _open('b18-w1-header');
    await store.createGoal(
      kind: GoalKind.weekly,
      title: '写周报',
      periodStart: _week().startMillis,
    );
    await _pumpWeek(tester, repos, store);

    final Finder header = _key('goal-week-header-row');
    expect(header, findsOneWidget, reason: '表头行应可按 goal-week-header-row 定位');
    expect(
      tester.widget<Row>(header).crossAxisAlignment,
      CrossAxisAlignment.center,
      reason: '表头各格高度相同时几何无差，只能按结构锁居中口径',
    );
  });
}