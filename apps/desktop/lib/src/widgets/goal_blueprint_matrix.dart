// =============================================================================
// 目标 · 人生蓝图矩阵（Task 66 UI 半批 B2）
// =============================================================================
// 口径（计划 §5.4）：
//  1. 主视图 = **6 行（domain）× 5 列（horizon）** 矩阵；格子里显示 `title` 一行
//     + `keywords` 标签 + 做法条数；点标题展开三层（目标 → 关键词 → 做法）。
//  2. **近期（1 年）列渲染该年度的 yearly 目标**，不新建 blueprint 行 —— 与年页
//     **同一份数据源**（`GoalYearView.yearlyGoals`），保证单一真源。
//  3. **链断裂可视化**：沿 `serves` 链向下探；格内目标既没有下级（年/月/周）
//     也没有任何 `tracks` 执行实体时，角标显示「未落位」；可一键「拆成 3 条待办」
//     （走 `TodoRepository.create`）。
//  4. **空格合法**：矩阵不校验、不强制、不给红字（计划 §5.4 末句）。
//  5. **编辑入口（B8-W1）**：`onAddGoal` / `onEditGoal` / `onDeleteGoal` 三个回调
//     全部**可选**（默认 null）。不传时本矩阵的渲染与 Task 66 时期**逐字一致**
//     （AGENTS §5 坑 48：新增参数不得改变既有调用点的行为）。
//
// 本模块**不使用 Material 图标**（`Icons.`），新增 0 处。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_tokens.dart';
import 'goal_year_matrix.dart';

/// 蓝图矩阵的一行（一个领域）。
class GoalBlueprintRow {
  /// 构造。
  const GoalBlueprintRow({
    required this.domainKey,
    required this.cells,
  });

  /// 领域 key（Task 59 六 key）。
  final String domainKey;

  /// 档位 → 该格的目标。
  final Map<GoalHorizon, List<GoalRow>> cells;
}

/// 人生蓝图矩阵（6 行 × 5 列）。
class GoalBlueprintMatrix extends StatefulWidget {
  /// 创建矩阵。
  const GoalBlueprintMatrix({
    required this.t,
    required this.rows,
    required this.serves,
    required this.tracksCount,
    required this.onSplitTodos,
    this.onAddGoal,
    this.onEditGoal,
    this.onDeleteGoal,
    super.key,
  });

  /// 文案表。
  final AppLocalizations t;

  /// 矩阵行（每个领域一行）。
  final List<GoalBlueprintRow> rows;

  /// `serves` 双向索引（用来向下探下级目标）。
  final GoalServesIndex serves;

  /// 目标 id → `tracks` 执行实体条数（做法条数）。
  final Map<String, int> tracksCount;

  /// 「拆成 3 条待办」回调。
  final void Function(GoalRow goal) onSplitTodos;

  /// 空格子里的「+ 新建目标」回调（领域 + 所在档位由格子带入）。
  ///
  /// null = **不渲染**这个入口（坑 48：默认行为与 Task 66 逐字一致）。
  final void Function(String domainKey, GoalHorizon horizon)? onAddGoal;

  /// 目标卡片上的「编辑」回调。
  ///
  /// null = 不渲染（同上）。
  final void Function(GoalRow goal)? onEditGoal;

  /// 目标卡片上的「删除」回调（调用方负责二次确认）。
  ///
  /// null = 不渲染（同上）。
  final void Function(GoalRow goal)? onDeleteGoal;

  /// 档位顺序（终极 → 近期）。
  static List<GoalHorizon> get horizons => GoalHorizon.values.toList()
    ..sort((GoalHorizon a, GoalHorizon b) => a.value.compareTo(b.value));

  @override
  State<GoalBlueprintMatrix> createState() => _GoalBlueprintMatrixState();
}

class _GoalBlueprintMatrixState extends State<GoalBlueprintMatrix> {
  /// 展开三层的目标 id 集合。
  final Set<String> _expanded = <String>{};

  void _toggle(String goalId) {
    setState(() {
      if (!_expanded.remove(goalId)) {
        _expanded.add(goalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? headStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.faint);
    final TextStyle? bodyStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.meta);
    final TextStyle? warnStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.accentInk);

    final List<GoalHorizon> horizons = GoalBlueprintMatrix.horizons;

    return Table(
      columnWidths: <int, TableColumnWidth>{
        0: const FlexColumnWidth(2),
        for (int i = 0; i < horizons.length; i++) i + 1: const FlexColumnWidth(1),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: tokens.hairSoft, width: 1),
        verticalInside: BorderSide(color: tokens.hairSoft, width: 1),
      ),
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(widget.t.goalBlueprintColumnGoal, style: headStyle),
            ),
            for (final GoalHorizon horizon in horizons)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(_horizonLabel(horizon), style: headStyle),
              ),
          ],
        ),
        for (final GoalBlueprintRow row in widget.rows)
          TableRow(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  widget.t.projectDomainLabel(row.domainKey),
                  key: ValueKey<String>('goal-blueprint-row-${row.domainKey}'),
                  style: bodyStyle,
                ),
              ),
              for (final GoalHorizon horizon in horizons)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _cell(
                    goals: row.cells[horizon] ?? const <GoalRow>[],
                    domainKey: row.domainKey,
                    horizon: horizon,
                    bodyStyle: bodyStyle,
                    metaStyle: metaStyle,
                    warnStyle: warnStyle,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// 档位显示名。
  String _horizonLabel(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => widget.t.goalBlueprintHorizonUltimate,
    GoalHorizon.long => widget.t.goalBlueprintHorizonLong,
    GoalHorizon.mid => widget.t.goalBlueprintHorizonMid,
    GoalHorizon.short => widget.t.goalBlueprintHorizonShort,
    GoalHorizon.near => widget.t.goalBlueprintHorizonNear,
  };

  /// 档位 → key 片段（与枚举名一致：`career-ultimate` / `learning-short`）。
  String _horizonKey(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => 'ultimate',
    GoalHorizon.long => 'long',
    GoalHorizon.mid => 'mid',
    GoalHorizon.short => 'short',
    GoalHorizon.near => 'near',
  };

  /// 一个格子：列出该格的目标（空格子只留占位，**合法**）。
  Widget _cell({
    required List<GoalRow> goals,
    required String domainKey,
    required GoalHorizon horizon,
    required TextStyle? bodyStyle,
    required TextStyle? metaStyle,
    required TextStyle? warnStyle,
  }) {
    if (goals.isEmpty) {
      final Text empty = Text(
        widget.t.goalBlueprintEmptyCell,
        key: const ValueKey<String>('goal-blueprint-empty-cell'),
        style: metaStyle,
      );
      if (widget.onAddGoal == null) {
        // 没传回调 ⇒ 与 Task 66 时期**逐字一致**（坑 48）。
        return empty;
      }
      // 占位文字照旧渲染（空格合法），只在它下面补一个「+ 新建目标」入口。
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          empty,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: ValueKey<String>(
                'goal-blueprint-add-$domainKey-${_horizonKey(horizon)}',
              ),
              onPressed: () => widget.onAddGoal!(domainKey, horizon),
              child: Text(widget.t.goalBlueprintAddGoal),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in goals) ...<Widget>[
          InkWell(
            key: ValueKey<String>('goal-blueprint-cell-${goal.id}'),
            onTap: () => _toggle(goal.id),
            child: Text(goal.title, style: bodyStyle),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.t.goalBlueprintActionsCount} ${widget.tracksCount[goal.id] ?? 0}',
            style: metaStyle,
          ),
          if (_isUnplaced(goal))
            Text(
              widget.t.goalsUnplaced,
              key: ValueKey<String>('goal-blueprint-unplaced-${goal.id}'),
              style: warnStyle,
            ),
          if (_expanded.contains(goal.id)) ...<Widget>[
            if (goal.keywords != null && goal.keywords!.trim().isNotEmpty)
              Text(goal.keywords!, style: metaStyle),
            for (final GoalRow child in _weeklyChildren(goal))
              Text(
                '${widget.t.goalBlueprintWeeklyTarget} ${child.title}',
                key: ValueKey<String>('goal-blueprint-child-${child.id}'),
                style: metaStyle,
              ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: ValueKey<String>('goal-blueprint-split-${goal.id}'),
              onPressed: () => widget.onSplitTodos(goal),
              child: Text(widget.t.goalBlueprintSplitTodos),
            ),
          ),
          // 编辑/删除只管**蓝图目标**：近期列里混进来的年目标属于年页，
          // 在 07 页改它的档位会把 `horizon` 写成一个不该有的值。
          if (goal.kind == GoalKind.blueprint &&
              (widget.onEditGoal != null || widget.onDeleteGoal != null))
            Wrap(
              spacing: 4,
              children: <Widget>[
                if (widget.onEditGoal != null)
                  TextButton(
                    key: ValueKey<String>('goal-blueprint-edit-${goal.id}'),
                    onPressed: () => widget.onEditGoal!(goal),
                    child: Text(widget.t.goalBlueprintEditGoal),
                  ),
                if (widget.onDeleteGoal != null)
                  TextButton(
                    key: ValueKey<String>('goal-blueprint-delete-${goal.id}'),
                    onPressed: () => widget.onDeleteGoal!(goal),
                    child: Text(widget.t.goalBlueprintDeleteGoal),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  /// 未落位：既没有下级目标，也没有任何 `tracks` 执行实体。
  bool _isUnplaced(GoalRow goal) =>
      !widget.serves.hasChildren(goal.id) && (widget.tracksCount[goal.id] ?? 0) == 0;

  /// 该目标下的周目标（做法层的下一层）。
  List<GoalRow> _weeklyChildren(GoalRow goal) => widget.serves
      .childrenOf(goal.id)
      .where((GoalRow child) => child.kind == GoalKind.weekly)
      .toList(growable: false);
}