// =============================================================================
// 目标 · 人生蓝图矩阵（Task 66 UI 半批 B2 → B9-W2 标签页改造 → B10-B 增强）
// =============================================================================
// 口径（计划 §5.4 + B9 裁决 D-9 + B10 棒 B）：
//  1. 主视图 = **4 个标签页（终极 / 远期 / 中期 / 短期），默认终极**；一次只渲染
//     当前档位那一张表 —— **6 行（domain）× 3 列（领域 | 目标 | 日期）**，
//     不渲染表头行。目标格里显示 `title` 一行 + `keywords` 标签 + 做法条数；
//     点标题展开三层（目标 → 关键词 → 做法）。
//  2. **标签页激活态**（B10-B1）：激活 = 圆角 pill + `tokens.inkWash` 浅洗底 +
//     `tokens.ink` + `FontWeight.w600`；未激活 = 无底色 + `tokens.meta`。
//     四档都用 `Tooltip` 悬停显示时长（B10-B2，文案来自 `t.` getter）。
//  3. **短期页 = 原「短期」列 + 原「近期（1 年）」列**：near 蓝图与本年度 yearly 目标
//     都由页面侧并入 `GoalHorizon.short` 那一格（与年页**同一份数据源**
//     `GoalYearView.yearlyGoals`，保证单一真源）。
//  4. **链断裂可视化**：沿 `serves` 链向下探；格内目标既没有下级（年/月/周）
//     也没有任何 `tracks` 执行实体时，角标显示「未落位」；可一键拆分。
//  5. **空格合法**：矩阵不校验、不强制、不给红字（计划 §5.4 末句）；空格子的唯一
//     入口是右下角「+」（不渲染「（空）」）。
//  6. **编辑入口**：`onAddGoal` / `onEditGoal` / `onDeleteGoal` / `onToggleGoalDone` /
//     `onEditGoalPeriod` 五个回调全部**可选**（默认 null）。不传时本矩阵的渲染与
//     既有调用点逐字一致（AGENTS §5 坑 48：新增参数不得改变既有调用点的行为）。
//     * B10-B3：勾选框（`goal-blueprint-done-<id>`）只在传了 `onToggleGoalDone` 时渲染；
//       归档时刻由 `GoalStore.updateGoal` 按 `status` 派生，本组件不写库。
//     * B10-B4：日期列（`yyyy-MM-dd ~ yyyy-MM-dd`，缺值 `—`，已完成追加完成日）；
//       起止日期是**日期型**字段（UTC 午夜毫秒 ⇒ 按 UTC 显示，与方法 `_dateText` 一致），
//       而「完成：」取 `archivedAt` 这个**时刻**（⇒ 按本地时区显示，`_momentText`），
//       否则东八区 00:00–08:00 勾完成会显示成前一天；
//       改期按钮（`goal-blueprint-period-<id>`）只在传了 `onEditGoalPeriod` 时渲染，
//       且只管**蓝图目标**（年目标在本页改周期会与年页口径打架）。
//
// 本模块使用 2 个 Material 图标：`Icons.edit_outlined`（铅笔）与 `Icons.call_split`
// （拆分）；「+」用文字符号（坑 51：桌面测试不预载 MaterialIcons 字体）。
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
  const GoalBlueprintRow({required this.domainKey, required this.cells});

  /// 领域 key（Task 59 六 key）。
  final String domainKey;

  /// 档位 → 该格的目标。
  final Map<GoalHorizon, List<GoalRow>> cells;
}

/// 人生蓝图矩阵（6 行 × 3 列，4 个档位标签页）。
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
    this.onToggleGoalDone,
    this.onEditGoalPeriod,
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

  /// 拆分回调（B9-W3：打开拆分层级对话框，**确认即落库**；D-9-e 已废止
  /// 旧的「拆成 3 条待办 → 页内待确认队列」两段式链路）。
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

  /// 勾选 / 取消「完成」（B10-B3）。
  ///
  /// 调用方只传 `status`，`archived_at` 由 `GoalStore.updateGoal` 内部派生。
  /// null = **不渲染**勾选框（坑 48）。
  final void Function(GoalRow goal, bool done)? onToggleGoalDone;

  /// 改起止日期（B10-B4）：`startMs == 0` ⇒ 清空起始，`endMs == null` ⇒ 无终点。
  ///
  /// null = 不渲染日期列的改期按钮（同上）。
  final void Function(GoalRow goal, int startMs, int? endMs)? onEditGoalPeriod;

  /// 档位顺序（终极 → 近期）。
  ///
  /// 注意：**5 档**，供目标表单的档位下拉用（`goal_form_dialog.dart`）。
  /// 标签页只用 [tabs]（4 档，近期并入短期）。
  static List<GoalHorizon> get horizons =>
      GoalHorizon.values.toList()
        ..sort((GoalHorizon a, GoalHorizon b) => a.value.compareTo(b.value));

  /// 标签页顺序（终极 → 远期 → 中期 → 短期），默认取第一个。
  static const List<GoalHorizon> tabs = <GoalHorizon>[
    GoalHorizon.ultimate,
    GoalHorizon.long,
    GoalHorizon.mid,
    GoalHorizon.short,
  ];

  @override
  State<GoalBlueprintMatrix> createState() => _GoalBlueprintMatrixState();
}

class _GoalBlueprintMatrixState extends State<GoalBlueprintMatrix> {
  /// 展开三层的目标 id 集合。
  final Set<String> _expanded = <String>{};

  /// 当前选中的档位标签页（默认「终极」）。
  GoalHorizon _selected = GoalBlueprintMatrix.tabs.first;

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
    final TextStyle? bodyStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: tokens.meta);
    final TextStyle? warnStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: tokens.accentInk);
    final TextStyle? tabStyle = Theme.of(context).textTheme.labelLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final GoalHorizon horizon in GoalBlueprintMatrix.tabs)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _tab(horizon, style: tabStyle, tokens: tokens),
              ),
          ],
        ),
        if (_selected == GoalHorizon.short)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.t.goalBlueprintShortTabNote,
              key: const ValueKey<String>('goal-blueprint-short-tab-note'),
              style: metaStyle,
            ),
          ),
        Table(
          columnWidths: <int, TableColumnWidth>{
            0: const FlexColumnWidth(2),
            1: const FlexColumnWidth(5),
            2: const FlexColumnWidth(3),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: tokens.hairSoft, width: 1),
            verticalInside: BorderSide(color: tokens.hairSoft, width: 1),
          ),
          children: <TableRow>[
            for (final GoalBlueprintRow row in widget.rows)
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      widget.t.projectDomainLabel(row.domainKey),
                      key: ValueKey<String>(
                        'goal-blueprint-row-${row.domainKey}',
                      ),
                      style: bodyStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: _cell(
                      goals: row.cells[_selected] ?? const <GoalRow>[],
                      domainKey: row.domainKey,
                      horizon: _selected,
                      bodyStyle: bodyStyle,
                      metaStyle: metaStyle,
                      warnStyle: warnStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: _dates(
                      goals: row.cells[_selected] ?? const <GoalRow>[],
                      bodyStyle: bodyStyle,
                      metaStyle: metaStyle,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// 一个档位标签页（B10-B1 激活态 + B10-B2 时长提示）。
  Widget _tab(
    GoalHorizon horizon, {
    required TextStyle? style,
    required ThemeTokens tokens,
  }) {
    final bool active = horizon == _selected;
    return Tooltip(
      message: _horizonSpan(horizon),
      child: TextButton(
        key: ValueKey<String>('goal-blueprint-tab-${_horizonKey(horizon)}'),
        onPressed: () => setState(() => _selected = horizon),
        style: TextButton.styleFrom(
          // 激活 = 浅洗底 pill；未激活 = 透明（不是靠字重「猜」哪个选中）。
          backgroundColor: active ? tokens.inkWash : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
        ),
        child: Text(
          _horizonLabel(horizon),
          style: active
              ? style?.copyWith(color: tokens.ink, fontWeight: FontWeight.w600)
              : style?.copyWith(color: tokens.meta),
        ),
      ),
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

  /// 档位时长（标签页悬停提示；near 不进标签页，兜底用短期那条）。
  String _horizonSpan(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => widget.t.goalBlueprintHorizonUltimateSpan,
    GoalHorizon.long => widget.t.goalBlueprintHorizonLongSpan,
    GoalHorizon.mid => widget.t.goalBlueprintHorizonMidSpan,
    GoalHorizon.short => widget.t.goalBlueprintHorizonShortSpan,
    GoalHorizon.near => widget.t.goalBlueprintHorizonShortSpan,
  };

  /// 档位 → key 片段（与枚举名一致：`career-ultimate` / `learning-short`）。
  String _horizonKey(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => 'ultimate',
    GoalHorizon.long => 'long',
    GoalHorizon.mid => 'mid',
    GoalHorizon.short => 'short',
    GoalHorizon.near => 'near',
  };

  /// 一个格子：列出该格的目标（空格子只留「+」入口，**合法**）。
  Widget _cell({
    required List<GoalRow> goals,
    required String domainKey,
    required GoalHorizon horizon,
    required TextStyle? bodyStyle,
    required TextStyle? metaStyle,
    required TextStyle? warnStyle,
  }) {
    if (goals.isEmpty) {
      if (widget.onAddGoal == null) {
        // 没传回调 ⇒ 与 Task 66 时期一致：空态什么都不渲染（坑 48）。
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.bottomRight,
        child: _compactButton(
          key: ValueKey<String>(
            'goal-blueprint-add-$domainKey-${_horizonKey(horizon)}',
          ),
          onPressed: () => widget.onAddGoal!(domainKey, horizon),
          tooltip: widget.t.goalBlueprintAddGoal,
          // 英文态「Add」比 28×28 按钮宽，`FittedBox` 兜底缩放（不换行、不溢出）。
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.t.goalBlueprintAddSymbol),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // B10-B3：勾选框只管写 `status`，归档时刻由 store 派生。
                if (widget.onToggleGoalDone != null)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      key: ValueKey<String>('goal-blueprint-done-${goal.id}'),
                      value: goal.isDone,
                      onChanged: (bool? value) =>
                          widget.onToggleGoalDone!(goal, value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      InkWell(
                        key: ValueKey<String>('goal-blueprint-cell-${goal.id}'),
                        onTap: () => _toggle(goal.id),
                        child: Text(goal.title, style: bodyStyle),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.t.goalBlueprintActionsCount} '
                        '${widget.tracksCount[goal.id] ?? 0}',
                        style: metaStyle,
                      ),
                      if (_isUnplaced(goal))
                        Text(
                          widget.t.goalsUnplaced,
                          key: ValueKey<String>(
                            'goal-blueprint-unplaced-${goal.id}',
                          ),
                          style: warnStyle,
                        ),
                      if (_expanded.contains(goal.id)) ...<Widget>[
                        if (goal.keywords != null &&
                            goal.keywords!.trim().isNotEmpty)
                          Text(goal.keywords!, style: metaStyle),
                        for (final GoalRow child in _weeklyChildren(goal))
                          Text(
                            '${widget.t.goalBlueprintWeeklyTarget} ${child.title}',
                            key: ValueKey<String>(
                              'goal-blueprint-child-${child.id}',
                            ),
                            style: metaStyle,
                          ),
                      ],
                    ],
                  ),
                ),
                // 铅笔/拆分/删除只管**蓝图目标**：短期页里混进来的年目标属于年页，
                // 在 07 页改它的档位会把 `horizon` 写成一个不该有的值。
                if (goal.kind == GoalKind.blueprint) _actions(goal),
              ],
            ),
          ),
      ],
    );
  }

  /// 日期列（B10-B4）：每行目标一条 `起始 ~ 结束`，已完成追加完成日。
  Widget _dates({
    required List<GoalRow> goals,
    required TextStyle? bodyStyle,
    required TextStyle? metaStyle,
  }) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _periodText(goal),
                  key: ValueKey<String>('goal-blueprint-period-text-${goal.id}'),
                  style: bodyStyle,
                ),
                if (goal.isDone)
                  Text(
                    '${widget.t.goalBlueprintDonePrefix}'
                    '${_momentText(goal.archivedAt)}',
                    key: ValueKey<String>(
                      'goal-blueprint-done-on-${goal.id}',
                    ),
                    style: metaStyle,
                  ),
                // 年目标的周期归年页管，本页只改蓝图目标（与 _actions 同门槛）。
                if (widget.onEditGoalPeriod != null &&
                    goal.kind == GoalKind.blueprint)
                  _compactButton(
                    key: ValueKey<String>('goal-blueprint-period-${goal.id}'),
                    onPressed: () => widget.onEditGoalPeriod!(
                      goal,
                      goal.periodStart,
                      goal.periodEnd,
                    ),
                    tooltip: widget.t.goalBlueprintPeriodTitle,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(widget.t.goalBlueprintPeriodTitle),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 目标卡片右侧的操作区（铅笔 + 拆分 + 既有删除按钮）。
  Widget _actions(GoalRow goal) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.onEditGoal != null)
          _compactButton(
            key: ValueKey<String>('goal-blueprint-edit-${goal.id}'),
            onPressed: () => widget.onEditGoal!(goal),
            tooltip: widget.t.goalBlueprintEditGoal,
            child: const Icon(Icons.edit_outlined),
            iconSize: 16,
          ),
        _compactButton(
          key: ValueKey<String>('goal-blueprint-split-${goal.id}'),
          onPressed: () => widget.onSplitTodos(goal),
          tooltip: widget.t.goalBlueprintSplit,
          child: const Icon(Icons.call_split),
          iconSize: 16,
        ),
        if (widget.onDeleteGoal != null)
          TextButton(
            key: ValueKey<String>('goal-blueprint-delete-${goal.id}'),
            onPressed: () => widget.onDeleteGoal!(goal),
            child: Text(widget.t.goalBlueprintDeleteGoal),
          ),
      ],
    );
  }

  /// 28×28 紧凑图标按钮（与 `GoalRowActions` 同口径）。
  Widget _compactButton({
    required Key key,
    required VoidCallback onPressed,
    required String tooltip,
    required Widget child,
    double? iconSize,
  }) {
    // `IconButton` 默认按 `MaterialTapTargetSize.padded` 把点击区撑到 48×48，
    // 这里显式 shrinkWrap，让点击区回到 `constraints` 给的 28×28。
    return Theme(
      data: Theme.of(context)
          .copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: IconButton(
        key: key,
        onPressed: onPressed,
        icon: child,
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        tooltip: tooltip,
      ),
    );
  }

  /// 起止日期文案：无起始 ⇒ 整体 `—`；无结束 ⇒ 右端 `—`。
  String _periodText(GoalRow goal) {
    if (goal.periodStart <= 0) {
      return '—';
    }
    return '${_dateText(goal.periodStart)} ~ ${_dateText(goal.periodEnd)}';
  }

  /// **日期型字段**专用：UTC 毫秒 → `yyyy-MM-dd`（null / 非正数 → `—`，与年页同口径）。
  ///
  /// 只给 `periodStart` / `periodEnd` 用 —— 这两个是全项目统一约定存
  /// UTC 午夜毫秒的「日期」，必须按 UTC 取年月日。
  String _dateText(int? millis) {
    if (millis == null || millis <= 0) {
      return '—';
    }
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(
      millis,
      isUtc: true,
    );
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }

  /// **时刻型字段**专用：毫秒 → `yyyy-MM-dd`（null / 非正数 → `—`），按**本地时区**取年月日。
  ///
  /// 只给 `archivedAt` 用 —— 它存的是 `GoalStore.updateGoal` 里 `DateTime.now()` 的
  /// 时刻，不是 UTC 午夜的「日期」。若按 UTC 显示，东八区 00:00–08:00 之间勾完成
  /// 会少一天，用户看到的完成日期就是错的。
  String _momentText(int? millis) {
    if (millis == null || millis <= 0) {
      return '—';
    }
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(millis);
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }

  /// 未落位：既没有下级目标，也没有任何 `tracks` 执行实体。
  bool _isUnplaced(GoalRow goal) =>
      !widget.serves.hasChildren(goal.id) &&
      (widget.tracksCount[goal.id] ?? 0) == 0;

  /// 该目标下的周目标（做法层的下一层）。
  List<GoalRow> _weeklyChildren(GoalRow goal) => widget.serves
      .childrenOf(goal.id)
      .where((GoalRow child) => child.kind == GoalKind.weekly)
      .toList(growable: false);
}