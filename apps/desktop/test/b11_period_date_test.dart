// =============================================================================
// B11 · 蓝图矩阵「起止日期」列的时区修复（判别性用例）
// =============================================================================
// 缺陷（装机真机验收判据 5）：用户在改期对话框里选 2026-11-01 / 2026-11-30，
// 对话框与矩阵都显示成 `2026-10-31 ~ 2026-11-29`（东八区整体提前一天）。
//
// 根因：起止存的是「**本地**某日 00:00 那一刻的毫秒数」（`showDatePicker` 给的是
// 本地 `DateTime`，落库取它的 `millisecondsSinceEpoch`），渲染却按 UTC 解释这串毫秒。
//
// 判据：
//  * 本地午夜毫秒样本 ⇒ 显示必须是用户选的那一天（**修复前红、修复后绿**）。
//  * UTC 窗口毫秒样本（`GoalPeriod` 口径的年 / 月 / 周目标）⇒ 仍按 UTC 显示
//    （防「一律改成本地」把年目标终点显示成第二天）。
//
// 注：判别性依赖运行机的 UTC 偏移为**正**（本机 UTC+8）—— 只有这样「按 UTC 解释
// 本地午夜」才会退一天；期望值本身用本地 `DateTime` 构造，在任意时区都成立。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:actlog/src/widgets/goals/goal_period_dialog.dart';
import 'package:core_domain/core_domain.dart' show GoalHorizon, GoalKind, GoalStatus;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 本地午夜毫秒样本：2026-11-01 00:00（本地）。
final int _localStart = DateTime(2026, 11, 1).millisecondsSinceEpoch;

/// 本地午夜毫秒样本：2026-11-30 00:00（本地）。
final int _localEnd = DateTime(2026, 11, 30).millisecondsSinceEpoch;

/// UTC 午夜毫秒样本：`GoalPeriod.year(2026)` 窗口的起点（2026-01-01T00:00:00Z）。
final int _utcStart = DateTime.utc(2026).millisecondsSinceEpoch;

/// UTC 午夜毫秒样本：`GoalPeriod.year(2026)` 窗口的终点（2026-12-31T23:59:59.999Z）。
final int _utcEnd = DateTime.utc(2027).millisecondsSinceEpoch - 1;

/// 空的关系索引（矩阵只查 `serves`，本用例不涉链）。
const GoalServesIndex _noServes = GoalServesIndex(
  <String, List<GoalRow>>{},
  <String, List<GoalRow>>{},
);

/// 挂矩阵本体（不经过页面）。
Widget _matrixHost(List<GoalBlueprintRow> rows) => MaterialApp(
  theme: AppTheme.light(DensityProfile.comfortable),
  home: Scaffold(
    body: SingleChildScrollView(
      child: GoalBlueprintMatrix(
        t: AppLocalizations.zh,
        rows: rows,
        serves: _noServes,
        tracksCount: const <String, int>{},
        onSplitTodos: (GoalRow _) {},
      ),
    ),
  ),
);

/// 一条 career × 终极档的矩阵行。
GoalBlueprintRow _careerRow(GoalRow goal) => GoalBlueprintRow(
  domainKey: 'career',
  cells: <GoalHorizon, List<GoalRow>>{GoalHorizon.ultimate: <GoalRow>[goal]},
);

/// 造一条目标行（只填矩阵要用的字段）。
GoalRow _goal({
  required String id,
  required GoalKind kind,
  required int periodStart,
  int? periodEnd,
}) => GoalRow(
  id: id,
  kind: kind,
  title: '目标 $id',
  status: GoalStatus.active,
  periodStart: periodStart,
  periodEnd: periodEnd,
  createdAt: 0,
  updatedAt: 0,
);

/// 矩阵日期列那一行的文本。
String _periodText(WidgetTester tester, String id) => tester
    .widget<Text>(find.byKey(ValueKey<String>('goal-blueprint-period-text-$id')))
    .data!;

/// 挂起改期对话框。
Future<void> _openPeriodDialog(
  WidgetTester tester, {
  required int startMs,
  int? endMs,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () => showGoalPeriodDialog(
              context,
              t: AppLocalizations.zh,
              startMs: startMs,
              endMs: endMs,
            ),
            child: const Text('open-period'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open-period'));
  await tester.pumpAndSettle();
}

/// 对话框里某个日期按钮上的文本。
String _dialogDateText(WidgetTester tester, String key) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: find.byType(Text),
      ),
    )
    .data!;

void main() {
  testWidgets('对话框：本地午夜毫秒显示为用户选的那一天（不是前一天）', (
    WidgetTester tester,
  ) async {
    await _openPeriodDialog(
      tester,
      startMs: _localStart,
      endMs: _localEnd,
    );

    expect(
      _dialogDateText(tester, 'goal-period-start'),
      '2026-11-01',
      reason: '起始毫秒 = 本地 2026-11-01 00:00 ⇒ 必须显示 2026-11-01',
    );
    expect(
      _dialogDateText(tester, 'goal-period-end'),
      '2026-11-30',
      reason: '结束毫秒 = 本地 2026-11-30 00:00 ⇒ 必须显示 2026-11-30',
    );
  });

  testWidgets('对话框：日期选择器的初始日期 = 既有起止的那一天', (
    WidgetTester tester,
  ) async {
    await _openPeriodDialog(tester, startMs: _localStart, endMs: _localEnd);

    await tester.tap(find.byKey(const ValueKey<String>('goal-period-start')));
    await tester.pumpAndSettle();

    final DatePickerDialog picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(
      picker.initialDate,
      DateTime(2026, 11, 1),
      reason: '选择器必须落在用户当初选的那一天，不能退到前一天',
    );
  });

  testWidgets('矩阵日期列：蓝图目标的本地午夜毫秒显示为用户选的那一天', (
    WidgetTester tester,
  ) async {
    final GoalRow goal = _goal(
      id: 'b11-local',
      kind: GoalKind.blueprint,
      periodStart: _localStart,
      periodEnd: _localEnd,
    );
    await tester.pumpWidget(_matrixHost(<GoalBlueprintRow>[_careerRow(goal)]));
    await tester.pumpAndSettle();

    expect(
      _periodText(tester, 'b11-local'),
      '2026-11-01 ~ 2026-11-30',
      reason: '蓝图目标的起止是本地午夜毫秒 ⇒ 按本地日显示',
    );
  });

  testWidgets('矩阵日期列：年目标的 UTC 窗口毫秒仍按 UTC 显示（不回退）', (
    WidgetTester tester,
  ) async {
    final GoalRow goal = _goal(
      id: 'b11-utc',
      kind: GoalKind.yearly,
      periodStart: _utcStart,
      periodEnd: _utcEnd,
    );
    await tester.pumpWidget(_matrixHost(<GoalBlueprintRow>[_careerRow(goal)]));
    await tester.pumpAndSettle();

    expect(
      _periodText(tester, 'b11-utc'),
      '2026-01-01 ~ 2026-12-31',
      reason: '年目标起止来自 GoalPeriod（UTC 午夜毫秒）⇒ 终点仍是 12-31',
    );
  });
}
