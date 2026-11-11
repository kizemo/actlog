// =============================================================================
// 方格时间轴 · 右键三级菜单 / 起止编辑弹窗
// =============================================================================

import 'package:core_db/core_db.dart' hide Todo, nowMillis;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

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

/// 一格上的右键菜单：`手填` / `待办` / `习惯` 三条路。
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

    return AlertDialog(
      backgroundColor: AppTokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      title: Text(
        '${formatMinute(startMinute)} 这一格',
        style: const TextStyle(fontSize: 16, color: AppTokens.ink),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GroupHeader('手填'),
              _ChoiceTile(
                key: const ValueKey<String>('slot-menu-manual'),
                icon: Icons.edit_outlined,
                label: '手填一条',
                onTap: () =>
                    Navigator.of(context).pop(const SlotMenuManual()),
              ),
              const SizedBox(height: AppTokens.gapCard),
              _GroupHeader('待办'),
              if (available.isEmpty)
                const _EmptyLine('待办池里没有可入格的条目')
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
              _GroupHeader('习惯'),
              if (habits.isEmpty)
                const _EmptyLine('这天没有排程内的习惯')
              else
                for (final HabitData habit in habits)
                  _ChoiceTile(
                    key: ValueKey<String>('slot-menu-habit-${habit.id}'),
                    icon: Icons.repeat,
                    label: habit.name,
                    onTap: () =>
                        Navigator.of(context).pop(SlotMenuHabit(habit)),
                  ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('slot-menu-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          letterSpacing: 0.6,
          color: AppTokens.meta,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppTokens.faint),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 15, color: AppTokens.ink2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: AppTokens.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}