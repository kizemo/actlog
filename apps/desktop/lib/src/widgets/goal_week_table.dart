// =============================================================================
// 目标 · 周目标表（Task 65 UI 半批 B1）
// =============================================================================
// 列口径（计划 §5.1）：优先顺序 | 目标 | 象限 | 完成期限 | 完成 | 服务于。
//
// 三条口径纪律：
//  1. **完成度是派生量**，不入库（`GoalExecutionStats.completionRate` 现算）；
//     界面上不写回任何列。
//  2. **同一时刻只显示一套标签**：一条目标同时有象限与 ABC 时，本表显示象限，
//     没有象限才退到 ABC，都没有才显示「未分级」—— 绝不同屏并列两套标签
//     （与 `packages\core_data\lib\src\priority.dart` 的口径一致）。
//  3. 文案全走 l10n：象限 / ABC 标签复用 `parts\domain.dart` 里既有的
//     `quadrantQxShortLabel` / `abcXLabel`，**不建第二套**。
//
// 标题格可**就地编辑**（B16 项 7）：点标题变单行输入框、Esc 取消、回车/失焦
// 提交；模式与 `goal_blueprint_matrix.dart` 的 `_inlineEditor` 一致。编辑状态
// 由页面持有（`editingId` + controller + focusNode），本组件只负责渲染与回调。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_tokens.dart';
import 'goals/goal_form_dialog.dart';

/// 周目标表（表头 + 若干行）。
class GoalWeekTable extends StatelessWidget {
  /// 创建周目标表。
  const GoalWeekTable({
    required this.view,
    required this.t,
    this.onEdit,
    this.onDelete,
    this.editingId,
    this.titleController,
    this.titleFocus,
    this.onTitleTap,
    this.onTitleSubmit,
    this.onTitleCancel,
    super.key,
  });

  /// 周视图读模型。
  final GoalWeekView view;

  /// 文案表。
  final AppLocalizations t;

  /// 点某一行的「编辑」；与 [onDelete] 同时非 null 时才显示操作列。
  final void Function(GoalRow goal)? onEdit;

  /// 点某一行的「删除」。
  final void Function(GoalRow goal)? onDelete;

  /// 正在就地编辑的目标 id（null = 无编辑）。
  final String? editingId;

  /// 就地编辑的标题控制器。
  final TextEditingController? titleController;

  /// 就地编辑的焦点。
  final FocusNode? titleFocus;

  /// 点标题开始就地编辑（null = 标题只读）。
  final void Function(GoalRow goal)? onTitleTap;

  /// 提交就地编辑（目标 + 新标题）。
  final void Function(GoalRow goal, String value)? onTitleSubmit;

  /// 取消就地编辑（Esc）。
  final VoidCallback? onTitleCancel;

  /// 「优先顺序」列宽。
  static const double orderWidth = 44;

  /// 「象限」列宽。
  static const double quadrantWidth = 56;

  /// 「完成期限」列宽。
  static const double dueWidth = 92;

  /// 「完成」列宽。
  static const double doneWidth = 64;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? headerStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.faint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: orderWidth, child: Text(t.goalsColumnOrder, style: headerStyle)),
            Expanded(
              flex: 3,
              child: Text(t.goalsColumnGoal, style: headerStyle),
            ),
            SizedBox(
              width: quadrantWidth,
              child: Text(t.goalsColumnQuadrant, style: headerStyle),
            ),
            SizedBox(width: dueWidth, child: Text(t.goalsColumnDue, style: headerStyle)),
            SizedBox(width: doneWidth, child: Text(t.goalsColumnDone, style: headerStyle)),
            Expanded(flex: 2, child: Text(t.goalsColumnServes, style: headerStyle)),
            // 操作列表头留空：宽度必须与行尾按钮组同宽（`GoalRowActions.width`）。
            if (onEdit != null && onDelete != null)
              const SizedBox(width: GoalRowActions.width),
          ],
        ),
        const SizedBox(height: 6),
        for (final GoalWeekItem item in view.items) ...<Widget>[
          Divider(height: 1, thickness: 1, color: tokens.hair),
          _WeekRow(
            item: item,
            t: t,
            onEdit: onEdit,
            onDelete: onDelete,
            editingId: editingId,
            titleController: titleController,
            titleFocus: titleFocus,
            onTitleTap: onTitleTap,
            onTitleSubmit: onTitleSubmit,
            onTitleCancel: onTitleCancel,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

/// 周目标表的一行。
class _WeekRow extends StatelessWidget {
  /// 创建一行。
  const _WeekRow({
    required this.item,
    required this.t,
    this.onEdit,
    this.onDelete,
    this.editingId,
    this.titleController,
    this.titleFocus,
    this.onTitleTap,
    this.onTitleSubmit,
    this.onTitleCancel,
  });

  /// 行数据。
  final GoalWeekItem item;

  /// 文案表。
  final AppLocalizations t;

  /// 点本行的「编辑」（null = 不显示操作列）。
  final void Function(GoalRow goal)? onEdit;

  /// 点本行的「删除」。
  final void Function(GoalRow goal)? onDelete;

  /// 正在就地编辑的目标 id（null = 无编辑）。
  final String? editingId;

  /// 就地编辑的标题控制器。
  final TextEditingController? titleController;

  /// 就地编辑的焦点。
  final FocusNode? titleFocus;

  /// 点标题开始就地编辑。
  final void Function(GoalRow goal)? onTitleTap;

  /// 提交就地编辑。
  final void Function(GoalRow goal, String value)? onTitleSubmit;

  /// 取消就地编辑。
  final VoidCallback? onTitleCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.meta);
    final GoalRow goal = item.goal;
    final GoalExecutionStats stats = item.stats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: GoalWeekTable.orderWidth,
          child: Text('${item.order}', style: metaStyle),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _titleCell(goal, bodyStyle),
              const SizedBox(height: 2),
              Text(_subLine(stats), style: metaStyle),
              if (stats.isUnplaced) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  t.goalsUnplaced,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.accentInk),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          width: GoalWeekTable.quadrantWidth,
          child: Text(_priorityLabel(goal), style: metaStyle),
        ),
        SizedBox(
          width: GoalWeekTable.dueWidth,
          child: Text(_dueLabel(goal), style: metaStyle),
        ),
        SizedBox(
          width: GoalWeekTable.doneWidth,
          child: Text(
            '${(stats.completionRate * 100).round()}%',
            style: metaStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(item.servedGoal?.title ?? '—', style: metaStyle),
        ),
        if (onEdit != null && onDelete != null)
          GoalRowActions(
            editKey: 'goal-week-row-edit-${goal.id}',
            deleteKey: 'goal-week-row-delete-${goal.id}',
            onEdit: () => onEdit!(goal),
            onDelete: () => onDelete!(goal),
            t: t,
          ),
      ],
    );
  }

  /// 标题格：编辑中 → 单行输入框；否则 → 可点的标题文本。
  ///
  /// 用 `GestureDetector` 而不是 `InkWell`：本组件没有 Material 祖先
  /// （与 `goal_blueprint_matrix.dart` 的标题入口同口径）。
  Widget _titleCell(GoalRow goal, TextStyle? bodyStyle) {
    final TextEditingController? controller = titleController;
    final FocusNode? focus = titleFocus;
    if (editingId == goal.id && controller != null && focus != null) {
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              onTitleCancel?.call(),
        },
        child: TextField(
          key: ValueKey<String>('goal-week-title-edit-${goal.id}'),
          controller: controller,
          focusNode: focus,
          autofocus: true,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          onSubmitted: (String value) => onTitleSubmit?.call(goal, value),
          style: bodyStyle,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            border: InputBorder.none,
          ),
        ),
      );
    }
    final Widget text = Text(goal.title, style: bodyStyle);
    final void Function(GoalRow goal)? onTap = onTitleTap;
    if (onTap == null) {
      return text;
    }
    return GestureDetector(
      key: ValueKey<String>('goal-week-title-${goal.id}'),
      onTap: () => onTap(goal),
      child: text,
    );
  }

  /// 目标格下面的次级行：完成度 + 关联计划项。
  String _subLine(GoalExecutionStats stats) =>
      '${t.goalsCompletion} ${(stats.completionRate * 100).round()}% · '
      '${t.goalsPlanItems} ${stats.planItemDone}/${stats.planItemTotal}';

  /// 象限 / ABC 标签（同一时刻只显示一套）。
  String _priorityLabel(GoalRow goal) {
    final Quadrant? quadrant = goal.quadrant;
    if (quadrant != null) {
      return switch (quadrant) {
        Quadrant.q1 => t.quadrantQ1ShortLabel,
        Quadrant.q2 => t.quadrantQ2ShortLabel,
        Quadrant.q3 => t.quadrantQ3ShortLabel,
        Quadrant.q4 => t.quadrantQ4ShortLabel,
      };
    }
    final PriorityAbc? abc = goal.priorityAbc;
    if (abc != null) {
      return switch (abc) {
        PriorityAbc.a => t.abcALabel,
        PriorityAbc.b => t.abcBLabel,
        PriorityAbc.c => t.abcCLabel,
      };
    }
    return t.priorityUnsetLabel;
  }

  /// 完成期限（`due_date` 毫秒 → `yyyy-MM-dd`；空 = 无期限）。
  ///
  /// 口径：`goal.due_date` 存的是**本地午夜毫秒**（写入方
  /// `goal_form_dialog.dart` 用 `DateTime.tryParse('yyyy-MM-dd')` 解析，串里没有
  /// `Z` ⇒ 落库就是本地时区的当天零点；`task73_b8_w1_blueprint_edit_test.dart`
  /// 的 `_dayOf` 助手亦按本地解析并断言 `2026-12-31`）⇒ 这里必须按**本地时区**
  /// 解读。若按 UTC 解读（`isUtc: true`），东八区会整整少一天（显示成前一天）。
  ///
  /// 注意：`period_start` / `period_end` 是**另一套并存口径**（蓝图目标是本地
  /// 午夜，年/月/周目标是 `GoalPeriod` 的 UTC 午夜），本函数只管 `due_date`。
  String _dueLabel(GoalRow goal) {
    final int? due = goal.dueDate;
    if (due == null) {
      return '—';
    }
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(due);
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }
}