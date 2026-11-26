// =============================================================================
// 目标 · 拆分对话框（B9-W3）
// =============================================================================
// 用户原话（B9 W3）：「终极目标，可以拆分为多个远期目标，远期目标可以拆分为
// 多个中期目标，中期目标又可以拆分为多个短期目标……短期目标，则可以拆分为
// 多个年目标或待办任务。确认拆分后，也直接填入对应表格。」
//
// 本文件**只出结果、不写库**：调用方拿到 [GoalSplitResult] 自己落库，写库失败
// 由页面统一给可见提示。下一层档位由父档位推导（见 [goalSplitChildHorizon]）；
// 只有短期 / 近期两档才让用户二选一「年目标 / 待办任务」。
//
// 断言口径（坑 51）：本文件所有可点元素都带 ValueKey，桌面测试不预载图标字体，
// 不靠字形断言。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 拆分出来的目标类型（三选一）。
enum GoalSplitTarget {
  /// 下一档蓝图目标（终极 → 远期 → 中期 → 短期）。
  blueprint,

  /// 年度目标（短期 / 近期档）。
  yearly,

  /// 待办任务（短期 / 近期档）。
  todo,
}

/// 拆分结果：子目标标题（已去空白，至少 1 条）+ 目标类型。
class GoalSplitResult {
  /// 创建结果。
  const GoalSplitResult({required this.titles, required this.target});

  /// 子目标标题（非空、已 trim）。
  final List<String> titles;

  /// 拆出来的目标类型。
  final GoalSplitTarget target;
}

/// 父档位 → 子蓝图档位；null = 下一层不是蓝图（短期 / 近期 ⇒ 年目标或待办）。
GoalHorizon? goalSplitChildHorizon(GoalHorizon parent) {
  switch (parent) {
    case GoalHorizon.ultimate:
      return GoalHorizon.long;
    case GoalHorizon.long:
      return GoalHorizon.mid;
    case GoalHorizon.mid:
      return GoalHorizon.short;
    case GoalHorizon.short:
    case GoalHorizon.near:
      return null;
  }
}

/// 打开拆分对话框；取消返回 null。
///
/// [t] 必须由调用方在**页面自己的 context** 上取好再传进来：`showDialog` 的
/// builder 在 Navigator 的 overlay 里构建，那里在 `L10nScope` 之上。
Future<GoalSplitResult?> showGoalSplitDialog(
  BuildContext context, {
  required AppLocalizations t,
  required String parentTitle,
  required GoalHorizon parentHorizon,
}) {
  return showDialog<GoalSplitResult>(
    context: context,
    builder: (BuildContext context) => _GoalSplitDialog(
      t: t,
      parentTitle: parentTitle,
      parentHorizon: parentHorizon,
    ),
  );
}

/// 一行输入（`id` 稳定，删行后其它行的 key 不会串位）。
class _SplitRow {
  /// 创建一行，并建好控制器。
  _SplitRow(this.id) : controller = TextEditingController();

  /// 稳定行号（从 0 起，只增不减）。
  final int id;

  /// 标题输入控制器。
  final TextEditingController controller;
}

class _GoalSplitDialog extends StatefulWidget {
  /// 创建对话框。
  const _GoalSplitDialog({
    required this.t,
    required this.parentTitle,
    required this.parentHorizon,
  });

  /// 文案表（由页面传入）。
  final AppLocalizations t;

  /// 被拆目标标题。
  final String parentTitle;

  /// 被拆目标档位。
  final GoalHorizon parentHorizon;

  @override
  State<_GoalSplitDialog> createState() => _GoalSplitDialogState();
}

class _GoalSplitDialogState extends State<_GoalSplitDialog> {
  /// 当前行（默认 3 行空）。
  final List<_SplitRow> _rows = <_SplitRow>[];

  /// 下一个行号。
  int _nextId = 0;

  /// 是否要显示「至少填写一行」提示（点过确认且全空）。
  bool _showEmptyRow = false;

  /// 目标类型（仅短期 / 近期档生效；默认年目标）。
  GoalSplitTarget _target = GoalSplitTarget.yearly;

  /// 短期 / 近期档才给「年目标 / 待办任务」选择器。
  bool get _showsTargetSelector =>
      widget.parentHorizon == GoalHorizon.short ||
      widget.parentHorizon == GoalHorizon.near;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _rows.add(_SplitRow(_nextId));
      _nextId += 1;
    }
  }

  @override
  void dispose() {
    for (final _SplitRow row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  /// 加一行。
  void _addRow() {
    setState(() {
      _rows.add(_SplitRow(_nextId));
      _nextId += 1;
      _showEmptyRow = false;
    });
  }

  /// 删一行（只剩 1 行时不给删）。
  void _removeRow(int id) {
    final int index = _rows.indexWhere((_SplitRow row) => row.id == id);
    if (index < 0 || _rows.length <= 1) {
      return;
    }
    setState(() {
      _rows.removeAt(index).controller.dispose();
      _showEmptyRow = false;
    });
  }

  /// 确认：全空只提示、不关框；否则 pop 结果（**不写库**）。
  void _confirm() {
    final List<String> titles = <String>[
      for (final _SplitRow row in _rows)
        if (row.controller.text.trim().isNotEmpty) row.controller.text.trim(),
    ];
    if (titles.isEmpty) {
      setState(() => _showEmptyRow = true);
      return;
    }
    final GoalSplitTarget target =
        _showsTargetSelector ? _target : GoalSplitTarget.blueprint;
    Navigator.of(context).pop(
      GoalSplitResult(titles: titles, target: target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = widget.t;
    final TextTheme text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(t.goalSplitDialogTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(t.goalSplitDialogHint),
              const SizedBox(height: 6),
              Text(widget.parentTitle, style: text.labelLarge),
              const SizedBox(height: 8),
              for (final _SplitRow row in _rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          key: ValueKey<String>('goal-split-title-${row.id}'),
                          controller: row.controller,
                          style: text.bodyMedium?.copyWith(height: 1.3),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                          ),
                          onChanged: (String _) {
                            if (_showEmptyRow) {
                              setState(() => _showEmptyRow = false);
                            }
                          },
                        ),
                      ),
                      if (_rows.length > 1)
                        IconButton(
                          key: ValueKey<String>('goal-split-remove-${row.id}'),
                          tooltip: t.goalSplitDialogRemoveRow,
                          onPressed: () => _removeRow(row.id),
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 18,
                        ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey<String>('goal-split-add-row'),
                  onPressed: _addRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(t.goalSplitDialogAddRow),
                ),
              ),
              if (_showsTargetSelector) ...<Widget>[
                const SizedBox(height: 4),
                Text(t.goalSplitDialogTargetLabel),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      key: const ValueKey<String>('goal-split-kind-yearly'),
                      label: Text(t.goalSplitTargetYearly),
                      selected: _target == GoalSplitTarget.yearly,
                      onSelected: (bool _) => setState(
                        () => _target = GoalSplitTarget.yearly,
                      ),
                    ),
                    ChoiceChip(
                      key: const ValueKey<String>('goal-split-kind-todo'),
                      label: Text(t.goalSplitTargetTodo),
                      selected: _target == GoalSplitTarget.todo,
                      onSelected: (bool _) => setState(
                        () => _target = GoalSplitTarget.todo,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(t.goalSplitDialogNote, style: text.labelSmall),
              if (_showEmptyRow)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    t.goalSplitDialogEmptyRow,
                    style: text.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('goal-split-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('goal-split-confirm'),
          onPressed: _confirm,
          child: Text(t.goalSplitDialogConfirm),
        ),
      ],
    );
  }
}