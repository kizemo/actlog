// =============================================================================
// 甘特图 · 自绘（Task 56）
// =============================================================================
// 口径（控制器裁决，不得另做设计决策）：
//   · 横条 = 项目区间（`project.start_date`..`project.end_date`）。只知道一端时
//     退化成该已知日的单日条；两端都不知道就**不画条**（不臆造另一端）。
//   · 块 = 任务（`project_milestone.target_date`）的目标日，单日排期。
//   · 目标日为空的任务**不画块**，只在项目行上记「未排期 N 条」。
//   · 可视区间 = 所有项目起止日 + 所有任务目标日里的最小 / 最大日（闭区间）；
//     一个端点都没有 ⇒ 画不出任何东西（空态）。
//
// 为什么不用纯 `CustomPaint`：任务块要能被 widget test 定位（取 `getRect` 比
// x 坐标，判别「块落在目标日」），所以用 `Stack` + `Positioned`，每块带一枚
// `ValueKey`（见 [GanttChart.blockKey]）。
//
// 颜色一律取 `context.tokens`（浅色 / 深色两态都由 `ThemeTokens` 下发），
// 本文件没有一处静态色值。
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 甘特图里的一条任务块（项目下的一条里程碑）。
@immutable
class GanttMilestone {
  /// 构造。
  const GanttMilestone({
    required this.id,
    required this.title,
    required this.targetDate,
  });

  /// `project_milestone.id`（同时用作块的定位 key）。
  final String id;

  /// 任务标题（块里显示的字）。
  final String title;

  /// 目标日（`YYYY-MM-DD`）；`null` = 未排期 ⇒ **不画块**。
  final String? targetDate;
}

/// 甘特图里的一行项目。
@immutable
class GanttProject {
  /// 构造。
  const GanttProject({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.milestones,
  });

  /// `project.id`（同时用作横条的定位 key）。
  final String id;

  /// 项目名称（左侧标签列显示）。
  final String name;

  /// 开始日期（`YYYY-MM-DD`）；`null` = 未定。
  final String? startDate;

  /// 结束日期（`YYYY-MM-DD`）；`null` = 未定。
  final String? endDate;

  /// 该项目的全部任务。
  final List<GanttMilestone> milestones;

  /// 未排期（`target_date` 为空）的任务条数。
  int get unscheduledCount => milestones
      .where((GanttMilestone milestone) => milestone.targetDate == null)
      .length;
}

/// 甘特图（多项目 × 多任务，自绘）。
class GanttChart extends StatelessWidget {
  /// 创建甘特图。
  const GanttChart({
    required this.projects,
    this.dayWidth = 26,
    this.headerLabel = '项目 / 任务',
    this.emptyLabel = '没有可排期的日期',
    this.unscheduledLabelBuilder,
    super.key,
  });

  /// 要画的行（顺序即渲染顺序）。
  final List<GanttProject> projects;

  /// 一天的宽（像素）。
  final double dayWidth;

  /// 左上角表头文案。
  final String headerLabel;

  /// 没有任何可排期日期时的空态文案。
  final String emptyLabel;

  /// 「未排期 N 条」文案（由页面用当前语言的文案表拼好）。
  final String Function(int count)? unscheduledLabelBuilder;

  /// 任务块的定位 key（测试与页面定位用）。
  static Key blockKey(String milestoneId) =>
      ValueKey<String>('gantt-block-$milestoneId');

  /// 项目横条的定位 key。
  static Key barKey(String projectId) =>
      ValueKey<String>('gantt-bar-$projectId');

  /// 未排期计数的定位 key。
  static Key unscheduledKey(String projectId) =>
      ValueKey<String>('gantt-unscheduled-$projectId');

  /// 每行的高度（横条 10 + 间距 4 + 任务块 20）。
  static const double rowHeight = 34;

  /// 横条高度。
  static const double barHeight = 10;

  /// 任务块高度。
  static const double blockHeight = 20;

  /// 甘特图的可视区间（闭区间，两端都是日历日）。
  ///
  /// 取「所有项目的起止日」与「所有任务的目标日」里的最小 / 最大日；一个端点
  /// 都没有时返回 `null`（画不出任何东西）。
  static ({DateTime from, DateTime to})? visibleRange(
    List<GanttProject> projects,
  ) {
    DateTime? min;
    DateTime? max;
    for (final GanttProject project in projects) {
      for (final String? iso in <String?>[
        project.startDate,
        project.endDate,
        for (final GanttMilestone milestone in project.milestones)
          milestone.targetDate,
      ]) {
        final DateTime? day = parseDay(iso);
        if (day == null) {
          continue;
        }
        final DateTime? curMin = min;
        final DateTime? curMax = max;
        if (curMin == null || day.isBefore(curMin)) {
          min = day;
        }
        if (curMax == null || day.isAfter(curMax)) {
          max = day;
        }
      }
    }
    final DateTime? lo = min;
    final DateTime? hi = max;
    if (lo == null || hi == null) {
      return null;
    }
    return (from: lo, to: hi);
  }

  /// 解析 `YYYY-MM-DD`（严格四段数字 + 真实日期）；不是日历日返回 `null`。
  static DateTime? parseDay(String? iso) {
    if (iso == null) {
      return null;
    }
    final Match? match =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso.trim());
    if (match == null) {
      return null;
    }
    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    final DateTime parsed = DateTime.utc(year, month, day);
    // `DateTime.utc` 会把越界值顺延（2 月 30 日 ⇒ 3 月 2 日），这里比回去。
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  /// `DateTime` ⇒ `YYYY-MM-DD`。
  static String formatDay(DateTime day) {
    final String m = day.month.toString().padLeft(2, '0');
    final String d = day.day.toString().padLeft(2, '0');
    return '${day.year}-$m-$d';
  }

  static String _defaultUnscheduledLabel(int count) => '未排期 $count 条';

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final ({DateTime from, DateTime to})? range = visibleRange(projects);
    if (range == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: tokens.hairSoft, width: 1),
        ),
        child: Text(
          emptyLabel,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: tokens.faint),
        ),
      );
    }

    final int totalDays = range.to.difference(range.from).inDays + 1;
    final double cell = dayWidth;
    final double chartWidth = totalDays * cell;
    // 标签列宽随系统字号缩放一起放大（大字号档下不许挤成一条缝）。
    final double labelWidth = MediaQuery.textScalerOf(context).scale(132);
    final String Function(int count) unscheduledLabel =
        unscheduledLabelBuilder ?? _defaultUnscheduledLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(
              width: labelWidth,
              child: Text(
                headerLabel,
                style: TextStyle(fontSize: 11.5, color: tokens.meta),
              ),
            ),
            Expanded(
              child: Text(
                '${formatDay(range.from)} → ${formatDay(range.to)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 11.5,
                  color: tokens.meta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: labelWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final GanttProject project in projects)
                    SizedBox(
                      height: rowHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: tokens.ink),
                          ),
                          if (project.unscheduledCount > 0)
                            Text(
                              unscheduledLabel(project.unscheduledCount),
                              key: unscheduledKey(project.id),
                              style: TextStyle(fontSize: 11, color: tokens.faint),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final GanttProject project in projects)
                      _projectRow(project, range.from, cell, chartWidth, tokens),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 一个项目行：横条（项目区间）+ 任务块（目标日）。
  Widget _projectRow(
    GanttProject project,
    DateTime from,
    double cell,
    double chartWidth,
    ThemeTokens tokens,
  ) {
    final List<Widget> layers = <Widget>[];

    // 项目横条：只知道一端时退化成单日条；两端都不知道就不画。
    final DateTime? start = parseDay(project.startDate);
    final DateTime? end = parseDay(project.endDate);
    final DateTime? barStart = start ?? end;
    final DateTime? barEnd = end ?? start;
    if (barStart != null && barEnd != null) {
      final int fromIndex = barStart.difference(from).inDays;
      final int toIndex = barEnd.difference(from).inDays;
      final int left = fromIndex < 0 ? 0 : fromIndex;
      final int right = toIndex < 0 ? 0 : toIndex;
      final int span = right - left + 1;
      final double raw = span * cell - 4;
      layers.add(
        Positioned(
          left: left * cell,
          top: 0,
          width: raw < 6 ? 6 : raw,
          height: barHeight,
          child: DecoratedBox(
            key: barKey(project.id),
            decoration: BoxDecoration(
              color: tokens.inkWash,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: tokens.hairStrong, width: 1),
            ),
          ),
        ),
      );
    }

    // 任务块：目标日为空 ⇒ 不画块。同一天多块时向右错开一格。
    final Map<int, int> used = <int, int>{};
    final double rawBlock = cell - 4;
    final double blockWidth = rawBlock < 8 ? 8 : rawBlock;
    for (final GanttMilestone milestone in project.milestones) {
      final DateTime? day = parseDay(milestone.targetDate);
      if (day == null) {
        continue;
      }
      final int index = day.difference(from).inDays;
      final int slot = used[index] ?? 0;
      used[index] = slot + 1;
      layers.add(
        Positioned(
          left: index * cell + slot * blockWidth,
          top: barHeight + 4,
          width: blockWidth,
          height: blockHeight,
          child: DecoratedBox(
            key: blockKey(milestone.id),
            decoration: BoxDecoration(
              color: tokens.accentWash,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: tokens.accent, width: 1),
            ),
            child: Center(
              child: Text(
                milestone.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: tokens.accentInk),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: chartWidth,
      height: rowHeight,
      child: Stack(clipBehavior: Clip.none, children: layers),
    );
  }
}
