// =============================================================================
// B11 · 周目标表「完成期限」列的时区口径（本地午夜毫秒）
// =============================================================================
// 缺陷：`goal_week_table.dart` 的 `_dueLabel` 原本按 **UTC** 解读
// `goal.due_date`，但库里存的是**本地午夜毫秒**（写入方
// `goal_form_dialog.dart` 用 `DateTime.tryParse('yyyy-MM-dd')` 解析，串里没有
// `Z` ⇒ 落库即本地时区的当天零点）⇒ 东八区（+08:00）下「到期日」整整少一天。
//
// 口径证据链（不重新调查）：
//  1. 写：`goal_form_dialog.dart:334` `DateTime.tryParse(text)?.millisecondsSinceEpoch`
//     ⇒ 本地午夜毫秒；同文件 `:342` 回读亦按本地解析。
//  2. 库：`task73_b8_w1_blueprint_edit_test.dart:272` 的 `_dayOf` 助手按**本地**
//     解析并断言 `dueDate` == `2026-12-31` ⇒ 库里的值就是本地午夜语义。
//  3. 读：`goal_week_table.dart` 原本 `isUtc: true` ⇒ 与 1/2 口径不一致，少一天。
//
// 判据打在**渲染结果**上（不是中间值）：把「本地午夜毫秒」样本塞进一张只有
// 一行的周目标表，断言「完成期限」格里出现的是当天日期、且**不出现**前一天。
//
// 判别力前提：本地时区 ≠ UTC（本机 = China Standard Time +08:00）才存在
// 「少一天」；在 UTC 机器上两个口径同值，本用例恒绿（不会误红）。
//
// ⚠️ 只管 `due_date`。`period_start` / `period_end` 是**另一套并存口径**
// （蓝图目标是本地午夜，年/月/周目标是 `GoalPeriod` 的 UTC 午夜），本文件
// 不涉及、也不允许顺手改。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_week_table.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 一条周目标行（`dueDate` = 库里那一列的毫秒值）。
GoalRow _goal({
  required String id,
  required String title,
  GoalKind kind = GoalKind.weekly,
  int? dueDate,
}) => GoalRow(
  id: id,
  kind: kind,
  title: title,
  status: GoalStatus.active,
  periodStart: 0,
  createdAt: 0,
  updatedAt: 0,
  dueDate: dueDate,
);

/// 派生统计（完成度 1/2 ⇒ 50%；`isUnplaced` 假 ⇒ 不出「未落位」提示行）。
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

/// 一份只有一行的周视图（`servedGoal` 恒非空 ⇒ 表里唯一的「—」只能是期限列）。
GoalWeekView _view(GoalRow goal) => GoalWeekView(
  period: GoalPeriod.week(2026, 48),
  items: <GoalWeekItem>[
    GoalWeekItem(
      goal: goal,
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

/// 挂起周目标表（裸 `MaterialApp` + `AppTheme` ⇒ `context.tokens` 拿得到 token）。
Future<void> _pumpWeekTable(WidgetTester tester, GoalWeekView view) async {
  tester.view.physicalSize = const Size(1300, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalWeekTable(view: view, t: AppLocalizations.zh),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('D1 本地午夜毫秒 ⇒ 到期日渲染当天（不是前一天）', (
    WidgetTester tester,
  ) async {
    // 样本 = 本地时区的当天零点（这正是 `goal_form_dialog.dart` 落库的值）。
    final int localMidnight = DateTime(2026, 12, 31).millisecondsSinceEpoch;
    await _pumpWeekTable(
      tester,
      _view(_goal(id: 'g1', title: '把周报写完', dueDate: localMidnight)),
    );

    expect(
      find.text('2026-12-31'),
      findsOneWidget,
      reason: 'due_date 是本地午夜毫秒 ⇒ 期限列必须渲染当天 2026-12-31',
    );
    expect(
      find.text('2026-12-30'),
      findsNothing,
      reason: '按 UTC 解读本地午夜会少一天（修复前渲染的就是 2026-12-30）',
    );
  });

  testWidgets('D2 跨年样本：本地午夜 2026-01-01 ⇒ 渲染 2026-01-01（不是 2025-12-31）', (
    WidgetTester tester,
  ) async {
    final int localMidnight = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    await _pumpWeekTable(
      tester,
      _view(_goal(id: 'g1', title: '把周报写完', dueDate: localMidnight)),
    );

    expect(
      find.text('2026-01-01'),
      findsOneWidget,
      reason: '期限列必须渲染当天 2026-01-01',
    );
    expect(
      find.text('2025-12-31'),
      findsNothing,
      reason: '按 UTC 解读会退到上一年 2025-12-31（少一天）',
    );
  });

  testWidgets('D3 没有期限 ⇒ 期限列显示「—」（回归护栏）', (
    WidgetTester tester,
  ) async {
    await _pumpWeekTable(
      tester,
      _view(_goal(id: 'g1', title: '把周报写完')),
    );

    expect(
      find.text('—'),
      findsOneWidget,
      reason: '无期限时期限列显示占位符「—」',
    );
  });
}
