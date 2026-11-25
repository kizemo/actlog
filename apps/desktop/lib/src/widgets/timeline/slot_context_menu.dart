// =============================================================================
// 方格时间轴 · 右键三级菜单 / 起止编辑弹窗
// =============================================================================

import 'package:core_db/core_db.dart' hide Todo, nowMillis;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';
import 'slot_state.dart';

/// 右键菜单选出来的动作。
sealed class SlotMenuChoice {
  const SlotMenuChoice();
}

/// 手填：直接开起止弹窗。
class SlotMenuManual extends SlotMenuChoice {
  /// 创建选择。
  const SlotMenuManual();
}

/// 待办入格。
class SlotMenuTodo extends SlotMenuChoice {
  /// 创建选择。
  const SlotMenuTodo(this.todo);

  /// 被选中的待办。
  final Todo todo;
}

/// 习惯入格。
class SlotMenuHabit extends SlotMenuChoice {
  /// 创建选择。
  const SlotMenuHabit(this.habit);

  /// 被选中的习惯。
  final HabitData habit;
}

/// 未完成周目标入格：先弹勾选浮层（可多选），确认后逐条加入当天计划。
///
/// 本变体不带数据：可选的周目标由调用方在弹浮层时现取
/// （`weekOpenGoalsProvider`），这里只负责表达「用户选了这条路」。
class SlotMenuGoals extends SlotMenuChoice {
  /// 创建选择。
  const SlotMenuGoals();
}

/// 一格上的右键菜单：`手填` / `待办` / `习惯` / `周目标` 四条路。
///
/// 「已排期」的待办不出现在待办分支里 —— 它已经在格子上了，再点一次只会
/// 造出第二条指向同一待办的计划行（待办池的徽标与这里共用同一份派生结果）。
class SlotContextMenu extends StatelessWidget {
  /// 创建菜单。
  const SlotContextMenu({
    super.key,
    required this.startMinute,
    required this.todos,
    required this.habits,
    required this.slottedTodoIds,
  });

  /// 被右击那一格的起始分钟。
  final int startMinute;

  /// 可入格的待办（调用方已过滤「已排期」）。
  final List<Todo> todos;

  /// 可入格的习惯。
  final List<HabitData> habits;

  /// 已排期的待办 id（双保险：调用方过滤 + 这里再过滤一次）。
  final Set<String> slottedTodoIds;

  /// 弹出菜单并等待用户选择；取消返回 null。
  static Future<SlotMenuChoice?> show(
    BuildContext context, {
    required int startMinute,
    required List<Todo> todos,
    required List<HabitData> habits,
    required Set<String> slottedTodoIds,
  }) {
    return showDialog<SlotMenuChoice>(
      context: context,
      builder: (BuildContext ctx) => SlotContextMenu(
        startMinute: startMinute,
        todos: todos,
        habits: habits,
        slottedTodoIds: slottedTodoIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Todo> available = todos
        .where((Todo t) => !slottedTodoIds.contains(t.id))
        .toList(growable: false);
    final ThemeTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      title: Text(
        l10n.timelineSlotMenuTitle(formatMinute(startMinute)),
        style: TextStyle(fontSize: 16, color: t.ink),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GroupHeader(l10n.timelineManualGroup),
              _ChoiceTile(
                key: const ValueKey<String>('slot-menu-manual'),
                icon: Icons.edit_outlined,
                label: l10n.timelineManualEntry,
                onTap: () =>
                    Navigator.of(context).pop(const SlotMenuManual()),
              ),
              const SizedBox(height: AppTokens.gapCard),
              _GroupHeader(l10n.timelineTodoGroup),
              if (available.isEmpty)
                _EmptyLine(l10n.timelineTodoPoolEmpty)
              else
                for (final Todo todo in available)
                  _ChoiceTile(
                    key: ValueKey<String>('slot-menu-todo-${todo.id}'),
                    icon: Icons.check_box_outlined,
                    label: todo.title,
                    onTap: () =>
                        Navigator.of(context).pop(SlotMenuTodo(todo)),
                  ),
              const SizedBox(height: AppTokens.gapCard),
              _GroupHeader(l10n.timelineHabitGroup),
              if (habits.isEmpty)
                _EmptyLine(l10n.timelineHabitEmpty)
              else
                for (final HabitData habit in habits)
                  _ChoiceTile(
                    key: ValueKey<String>('slot-menu-habit-${habit.id}'),
                    icon: Icons.repeat,
                    label: habit.name,
                    onTap: () =>
                        Navigator.of(context).pop(SlotMenuHabit(habit)),
                  ),
              const SizedBox(height: AppTokens.gapCard),
              // Task 72 / B7：把「未完成周目标」接进日计划。可选项由调用方
              // 现取（`weekOpenGoalsProvider`），本菜单只给一个入口。
              _GroupHeader(l10n.goalsUpstreamWeekTitle),
              _ChoiceTile(
                key: const ValueKey<String>('slot-menu-goals'),
                icon: Icons.flag_outlined,
                label: l10n.goalsUpstreamAddMenu,
                onTap: () =>
                    Navigator.of(context).pop(const SlotMenuGoals()),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('slot-menu-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          letterSpacing: 0.6,
          color: t.meta,
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: t.faint),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 15, color: t.ink2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: t.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}