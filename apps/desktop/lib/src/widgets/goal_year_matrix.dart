// =============================================================================
// 目标 · 年度读模型 + 月度展开矩阵（Task 66 UI 半批 B2）
// =============================================================================
// 三个结构决定：
//  1. **读模型在页面层派生**（计划 §3.3 选方案 b）：`data\goal_store.dart`
//     **零改动**，不新增 provider、不新增仓储方法。年视图 = `listGoals(kind/period)`
//     + `servedGoals` 反向索引。代价是「月目标条数」量级的 N 次往返，数据量级是
//     几十条，页内一次性算完可接受（口径登记在 `reports\task66-ui-b2.md`）。
//  2. **表二按「行 = 年目标 × 列 = 1–12 月」**：每格 = 该月 `serves` 这条年目标的
//     月目标及其 `self_score`（计划 §5.3 图 4）。空格 = 该月未展开，**合法**，
//     不校验、不报错、不给红字。
//  3. **写入一律两段式**：空格点开是页内编辑，填完先进「待确认草稿」，用户点
//     「加入待确认草稿」才进本页草稿队列；真正落库由页面统一调
//     `GoalStore.saveWeeklyDrafts`（落库恒为 `status='draft'`）。
//
// 本模块**不使用 Material 图标**（`Icons.`）：仓库口径是「外壳层零命中，页面/组件层
// 另有 30 处」，本模块新增 0 处。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_tokens.dart';

/// `serves` 关系的双向索引（正向：父表；反向：子表）。
///
/// 为什么要有它：仓储层只提供 `servedGoals(goalId)`（**正向**：我服务谁），
/// 蓝图页要问的是「谁服务我」（**反向**）。建一次索引，两种问法都答得上。
class GoalServesIndex {
  /// 构造。
  const GoalServesIndex(this.parentsOfGoal, this.childrenByParent);

  /// 正向：目标 id → 它 `serves` 的上层目标。
  final Map<String, List<GoalRow>> parentsOfGoal;

  /// 反向：上层目标 id → 服务它的下级目标。
  final Map<String, List<GoalRow>> childrenByParent;

  /// 某目标的**上层**目标。
  List<GoalRow> parentsOf(String goalId) =>
      parentsOfGoal[goalId] ?? const <GoalRow>[];

  /// 某目标的**下级**目标（沿 `serves` 链向下探）。
  List<GoalRow> childrenOf(String parentId) =>
      childrenByParent[parentId] ?? const <GoalRow>[];

  /// 某目标有没有下级。
  bool hasChildren(String parentId) => childrenOf(parentId).isNotEmpty;
}

/// 年度读模型（**派生**，不入库）。
class GoalYearView {
  /// 构造。
  const GoalYearView({
    required this.period,
    required this.yearlyGoals,
    required this.monthlyCells,
    required this.serves,
  });

  /// 本年度周期。
  final GoalPeriod period;

  /// 本年度的年度目标。
  final List<GoalRow> yearlyGoals;

  /// 年目标 id → 月号（1..12）→ 服务它的月目标。
  final Map<String, Map<int, GoalRow>> monthlyCells;

  /// `serves` 双向索引。
  final GoalServesIndex serves;

  /// 某年目标某月的月目标（该月未展开时返回 null）。
  GoalRow? cell(String yearlyId, int month) => monthlyCells[yearlyId]?[month];

  /// 某年目标已展开的月目标（按月号升序）。
  List<GoalRow> monthsOf(String yearlyId) {
    final Map<int, GoalRow>? bucket = monthlyCells[yearlyId];
    if (bucket == null) {
      return const <GoalRow>[];
    }
    final List<int> months = bucket.keys.toList()..sort();
    return <GoalRow>[for (final int month in months) bucket[month]!];
  }
}

/// 建 `serves` 双向索引（每条目标一次 `servedGoals` 查询）。
Future<GoalServesIndex> loadGoalServesIndex(
  GoalStore store,
  List<GoalRow> rows,
) async {
  final Map<String, List<GoalRow>> parents = <String, List<GoalRow>>{};
  final Map<String, List<GoalRow>> children = <String, List<GoalRow>>{};
  for (final GoalRow row in rows) {
    final List<GoalRow> served = await store.servedGoals(row.id);
    parents[row.id] = served;
    for (final GoalRow parent in served) {
      children.putIfAbsent(parent.id, () => <GoalRow>[]).add(row);
    }
  }
  return GoalServesIndex(parents, children);
}

/// 读年度视图：年目标 + 月度展开网格 + `serves` 索引。
Future<GoalYearView> loadGoalYearView(
  GoalStore store,
  GoalPeriod period,
) async {
  final List<GoalRow> yearly = await store.listGoals(
    kind: GoalKind.yearly,
    period: period,
  );
  final List<GoalRow> monthly = await store.listGoals(
    kind: GoalKind.monthly,
    period: period,
  );
  final List<GoalRow> weekly = await store.listGoals(kind: GoalKind.weekly);
  final GoalServesIndex serves = await loadGoalServesIndex(
    store,
    <GoalRow>[...monthly, ...weekly],
  );
  final Map<String, Map<int, GoalRow>> cells = <String, Map<int, GoalRow>>{
    for (final GoalRow goal in yearly) goal.id: <int, GoalRow>{},
  };
  for (final GoalRow row in monthly) {
    for (final GoalRow parent in serves.parentsOf(row.id)) {
      final Map<int, GoalRow>? bucket = cells[parent.id];
      if (bucket == null) {
        continue;
      }
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(
        row.periodStart,
        isUtc: true,
      );
      bucket[start.month] = row;
    }
  }
  return GoalYearView(
    period: period,
    yearlyGoals: yearly,
    monthlyCells: cells,
    serves: serves,
  );
}

/// 年度目标的月度展开矩阵（表二：行 = 年目标 × 列 = 1–12 月）。
///
/// 空格 = 该月未展开：点开就地输入标题，点「加入待确认草稿」进页内草稿队列
/// （**不落库**；落库由页面在用户确认后统一做）。
class GoalYearMatrix extends StatefulWidget {
  /// 创建矩阵。
  const GoalYearMatrix({
    required this.view,
    required this.t,
    required this.onAddCellDraft,
    super.key,
  });

  /// 年度读模型。
  final GoalYearView view;

  /// 文案表。
  final AppLocalizations t;

  /// 空格新增月目标（进页内待确认草稿队列）。
  final void Function(String yearlyId, int month, String title) onAddCellDraft;

  @override
  State<GoalYearMatrix> createState() => _GoalYearMatrixState();
}

class _GoalYearMatrixState extends State<GoalYearMatrix> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  /// 正在就地编辑的格子（`年目标 id#月号`）。
  String? _editing;

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _cellKey(String yearlyId, int month) => '$yearlyId#$month';

  TextEditingController _controllerFor(String yearlyId, int month) =>
      _controllers.putIfAbsent(
        _cellKey(yearlyId, month),
        TextEditingController.new,
      );

  void _submit(String yearlyId, int month) {
    final TextEditingController controller = _controllerFor(yearlyId, month);
    final String title = controller.text.trim();
    if (title.isEmpty) {
      return;
    }
    widget.onAddCellDraft(yearlyId, month, title);
    controller.clear();
    setState(() => _editing = null);
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

    if (widget.view.yearlyGoals.isEmpty) {
      return Text(widget.t.goalYearGoalsEmpty, style: metaStyle);
    }

    return Table(
      columnWidths: <int, TableColumnWidth>{
        0: const FlexColumnWidth(3),
        for (int month = 1; month <= 12; month++)
          month: const FlexColumnWidth(1),
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
              child: Text(widget.t.goalsColumnGoal, style: headStyle),
            ),
            for (int month = 1; month <= 12; month++)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text('$month', style: headStyle),
              ),
          ],
        ),
        for (final GoalRow yearly in widget.view.yearlyGoals)
          TableRow(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  yearly.title,
                  // 表二的行头标题：**不能**与表一的 `goal-year-row-` 同 key，
                  // 否则同一目标在两表里都带同名 key，定位器会同时命中两个控件。
                  key: ValueKey<String>('goal-year-matrix-row-${yearly.id}'),
                  style: bodyStyle,
                ),
              ),
              for (int month = 1; month <= 12; month++)
                _monthCell(yearly, month, bodyStyle, metaStyle),
            ],
          ),
      ],
    );
  }

  /// 一个月份格：有月目标就显示月目标与自评；没有就是「该月未展开」的空格。
  Widget _monthCell(
    GoalRow yearly,
    int month,
    TextStyle? bodyStyle,
    TextStyle? metaStyle,
  ) {
    final GoalRow? monthGoal = widget.view.cell(yearly.id, month);
    if (monthGoal != null) {
      final String score = monthGoal.selfScore?.toString() ?? '—';
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              monthGoal.title,
              key: ValueKey<String>('goal-year-cell-${yearly.id}-$month'),
              style: bodyStyle,
            ),
            const SizedBox(height: 2),
            Text('${widget.t.goalSelfScore} $score', style: metaStyle),
          ],
        ),
      );
    }

    final String key = _cellKey(yearly.id, month);
    if (_editing != key) {
      return InkWell(
        key: ValueKey<String>('goal-year-cell-empty-${yearly.id}-$month'),
        onTap: () => setState(() => _editing = key),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(widget.t.goalYearCellEmpty, style: metaStyle),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: ValueKey<String>('goal-year-cell-input-${yearly.id}-$month'),
            controller: _controllerFor(yearly.id, month),
            style: bodyStyle,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.t.goalYearCellInputHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: ValueKey<String>('goal-year-cell-add-${yearly.id}-$month'),
            onPressed: () => _submit(yearly.id, month),
            child: Text(widget.t.goalYearCellAddDraft),
          ),
        ],
      ),
    );
  }
}
