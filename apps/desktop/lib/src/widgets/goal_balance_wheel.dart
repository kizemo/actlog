// =============================================================================
// 目标 · 人生平衡轮（Task 66 UI 半批 B2）
// =============================================================================
// 口径（计划 §5.4 的平衡轮 + §11 的「宣称领域 vs 实际投入」）：
//  1. **纯派生，零落库**：自评均值来自月目标已有的 `self_score`（源数据），
//     习惯打卡频次来自 `habit_checkin`。这个组件**只读不写** —— 界面上看到的
//     任何数字都不回写目标库。
//  2. 六个领域各一根轴；本月与上月各一个多边形（双多边形对照）。
//  3. 自评是**用户自评**（0..10），不是达成率；口径说明复用
//     `goalYearReviewSelfNote` 同一句说明。
//
// 本模块**不使用 Material 图标**（`Icons.`），新增 0 处。
// =============================================================================

import 'dart:math' as math;

import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../data/goal_store.dart';
import '../data/project_domain_catalog.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_tokens.dart';

/// 平衡轮的一个数据点（一个领域）。
class GoalBalancePoint {
  /// 构造。
  const GoalBalancePoint({
    required this.domainKey,
    required this.current,
    required this.previous,
  });

  /// 领域 key（Task 59 六 key）。
  final String domainKey;

  /// 本月自评均值（null = 本月没有自评数据）。
  final double? current;

  /// 上月自评均值（null = 上月没有自评数据）。
  final double? previous;
}

/// 平衡轮读模型（**派生**，不入库）。
class GoalBalanceData {
  /// 构造。
  const GoalBalanceData({
    required this.points,
    required this.habitCheckins,
    required this.habitNames,
  });

  /// 六个领域的数据点。
  final List<GoalBalancePoint> points;

  /// 本月习惯打卡总次数。
  final int habitCheckins;

  /// 本月有打卡的习惯（名称 + 次数）。
  final List<String> habitNames;

  /// 有没有自评数据（没有就显示空态）。
  bool get hasScores =>
      points.any((GoalBalancePoint point) => point.current != null);
}

/// 读平衡轮数据（**只读**，不写库）。
Future<GoalBalanceData> loadGoalBalanceData(
  GoalStore store, {
  required GoalPeriod month,
}) async {
  final List<GoalRow> current = await store.listGoals(
    kind: GoalKind.monthly,
    period: month,
  );
  final List<GoalRow> previous = await store.listGoals(
    kind: GoalKind.monthly,
    period: month.previous(),
  );

  final List<GoalBalancePoint> points = <GoalBalancePoint>[];
  for (final String key in projectDomainKeys) {
    points.add(
      GoalBalancePoint(
        domainKey: key,
        current: _average(_scoresByDomain(current)[key]),
        previous: _average(_scoresByDomain(previous)[key]),
      ),
    );
  }

  final List<HabitData> habits = await store.repos.habit.listActive();
  final List<HabitCheckinData> checkins = await store.repos.habit
      .listCheckinsRange(_calendarDate(month.startUtc), _calendarDate(month.endUtc));
  final Map<String, int> perHabit = <String, int>{};
  for (final HabitCheckinData checkin in checkins) {
    perHabit.update(checkin.habitId, (int value) => value + 1, ifAbsent: () => 1);
  }

  return GoalBalanceData(
    points: points,
    habitCheckins: checkins.length,
    habitNames: <String>[
      for (final HabitData habit in habits)
        if ((perHabit[habit.id] ?? 0) > 0) '${habit.name} ${perHabit[habit.id]}',
    ],
  );
}

/// 领域 → 自评分（只取打了分的）。
Map<String, List<int>> _scoresByDomain(List<GoalRow> goals) {
  final Map<String, List<int>> result = <String, List<int>>{};
  for (final GoalRow goal in goals) {
    final int? score = goal.selfScore;
    final String? domain = goal.domain;
    if (score == null || domain == null || domain.isEmpty) {
      continue;
    }
    result.putIfAbsent(domain, () => <int>[]).add(score);
  }
  return result;
}

/// 均值（无数据返回 null）。
double? _average(List<int>? scores) {
  if (scores == null || scores.isEmpty) {
    return null;
  }
  final int sum = scores.reduce((int a, int b) => a + b);
  return sum / scores.length;
}

/// UTC 时刻 → `yyyy-MM-dd`（习惯打卡用的是日历日字符串）。
String _calendarDate(DateTime moment) {
  final String month = moment.month.toString().padLeft(2, '0');
  final String day = moment.day.toString().padLeft(2, '0');
  return '${moment.year}-$month-$day';
}

/// 人生平衡轮（双多边形 + 图例）。
class GoalBalanceWheel extends StatelessWidget {
  /// 创建平衡轮。
  const GoalBalanceWheel({required this.data, required this.t, super.key});

  /// 读模型。
  final GoalBalanceData data;

  /// 文案表。
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? bodyStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.meta);

    if (!data.hasScores) {
      return Text(
        t.goalBlueprintBalanceEmpty,
        key: const ValueKey<String>('goal-balance-empty'),
        style: metaStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            key: const ValueKey<String>('goal-balance-wheel'),
            painter: _BalancePainter(
              points: data.points,
              currentFill: tokens.accentWash,
              currentStroke: tokens.accent,
              previousFill: tokens.sunken,
              previousStroke: tokens.faint,
              gridColor: tokens.hairSoft,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final GoalBalancePoint point in data.points)
          Text(
            '${t.projectDomainLabel(point.domainKey)} · '
            '${t.goalSelfScore} ${_scoreText(point.current)}',
            key: ValueKey<String>('goal-balance-point-${point.domainKey}'),
            style: bodyStyle,
          ),
        Text(
          '${t.goalBlueprintBalanceHabit} ${data.habitCheckins}',
          key: const ValueKey<String>('goal-balance-habits'),
          style: metaStyle,
        ),
        for (final String habit in data.habitNames)
          Text(habit, style: metaStyle),
      ],
    );
  }

  /// 自评显示（无数据 = `—`）。
  String _scoreText(double? value) =>
      value == null ? '—' : value.toStringAsFixed(1);
}

/// 平衡轮画笔（六边形网格 + 两个数据多边形）。
class _BalancePainter extends CustomPainter {
  /// 创建画笔。
  const _BalancePainter({
    required this.points,
    required this.currentFill,
    required this.currentStroke,
    required this.previousFill,
    required this.previousStroke,
    required this.gridColor,
  });

  /// 数据点。
  final List<GoalBalancePoint> points;

  /// 本月填充色。
  final Color currentFill;

  /// 本月描边色。
  final Color currentStroke;

  /// 上月填充色。
  final Color previousFill;

  /// 上月描边色。
  final Color previousStroke;

  /// 网格线色。
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final int count = points.length;
    if (count < 3) {
      return;
    }
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.shortestSide / 2 - 14;

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint fill = Paint()..style = PaintingStyle.fill;

    for (final double factor in <double>[0.25, 0.5, 0.75, 1]) {
      canvas.drawPath(
        _ring(centerX, centerY, radius * factor, count),
        stroke..color = gridColor,
      );
    }

    final Path? current = _shape(
      centerX,
      centerY,
      radius,
      count,
      (int index) => points[index].current,
    );
    if (current != null) {
      canvas.drawPath(current, fill..color = currentFill);
      canvas.drawPath(current, stroke..color = currentStroke);
    }

    final Path? previous = _shape(
      centerX,
      centerY,
      radius,
      count,
      (int index) => points[index].previous,
    );
    if (previous != null) {
      canvas.drawPath(previous, fill..color = previousFill);
      canvas.drawPath(previous, stroke..color = previousStroke);
    }
  }

  /// 正多边形环。
  Path _ring(double centerX, double centerY, double radius, int count) {
    final Path path = Path();
    for (int i = 0; i < count; i++) {
      final double angle = -1.5707963267948966 + i * 6.283185307179586 / count;
      final double x = centerX + radius * _cos(angle);
      final double y = centerY + radius * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// 数据多边形（该点无数据就跳过整个多边形）。
  Path? _shape(
    double centerX,
    double centerY,
    double radius,
    int count,
    double? Function(int index) valueAt,
  ) {
    final List<double> values = <double>[
      for (int i = 0; i < count; i++) valueAt(i) ?? 0,
    ];
    if (values.every((double value) => value <= 0)) {
      return null;
    }
    final Path path = Path();
    for (int i = 0; i < count; i++) {
      final double angle = -1.5707963267948966 + i * 6.283185307179586 / count;
      final double scaled = radius * (values[i] / 10).clamp(0.0, 1.0);
      final double x = centerX + scaled * _cos(angle);
      final double y = centerY + scaled * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  double _cos(double angle) => math.cos(angle);

  double _sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(covariant _BalancePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.currentStroke != currentStroke ||
      oldDelegate.previousStroke != previousStroke;
}
