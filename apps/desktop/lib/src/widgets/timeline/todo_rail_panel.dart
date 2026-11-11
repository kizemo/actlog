import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../providers_p1.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../priority_marks.dart';

/// 右轨「待办列表」面板：待办池的**拖拽源**（只列待办，不再混排习惯）。
///
/// 结构上是既有 `ShellRailPanel` 的子节点（不是新面板类型），由
/// `app.dart` 的 `todayRailPanels()` 注入到今日页右轨第一块。
///
/// payload 契约与 `day_grid.dart` 的 `DragTarget<String>` 严格对齐：
/// 未排期待办 ⇒ `todo:<todo.id>`。
///
/// 已排期判定按 §0 的派生口径：只要存在未删除的 `plan_item` 且
/// `source_todo_id = todo.id`（跨日期，不只看所选日），该待办就算已排期。
/// 已排期条目渲染为**只读**（不包 `Draggable`）并弱化字色 —— 否则用户会把
/// 同一条待办排进两天。
class TodoRailPanel extends ConsumerWidget {
  /// 创建右轨待办列表面板。
  const TodoRailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoPoolProvider);
    final slottedAsync = ref.watch(slottedTodosProvider);

    if (todosAsync.hasError || slottedAsync.hasError) {
      return const _RailNote(text: '待办加载失败', danger: true);
    }
    if (!todosAsync.hasValue || !slottedAsync.hasValue) {
      return const _RailNote(text: '正在加载待办…');
    }

    // 已排期集合按 `todo.id` 计（跨日期），与待办池「已排期」徽标同一事实源。
    final slottedIds = slottedAsync.value!.keys.toSet();
    final todos = todosAsync.value!;
    if (todos.isEmpty) {
      return const _RailNote(text: '暂无待办');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final todo in todos)
          if (slottedIds.contains(todo.id))
            _ReadOnlyEntry(label: todo.title, quadrant: todo.quadrant)
          else
            _DraggableEntry(
              entry: _RailEntry(
                key: 'rail-todo-${todo.id}',
                payload: 'todo:${todo.id}',
                label: todo.title,
                quadrant: todo.quadrant,
              ),
            ),
      ],
    );
  }
}

/// 一条可拖动条目的显示数据。
@immutable
class _RailEntry {
  const _RailEntry({
    required this.key,
    required this.payload,
    required this.label,
    this.quadrant,
  });

  /// 测试与去重用的稳定 key。
  final String key;

  /// 拖拽 payload（`todo:<id>`）。
  final String payload;

  /// 显示文案。
  final String label;

  /// 四维度优先级；null = 未分级（名称前不画标记）。
  final Quadrant? quadrant;
}

/// 单条 `Draggable<String>`（前导 `○` + 标题）。
///
/// `feedback` 必须是自带 `Material` 的窄条：拖起后它挂在 overlay 上，
/// 没有 `Material` 祖先会让文字退化成无底色的裸文本。
class _DraggableEntry extends StatelessWidget {
  const _DraggableEntry({required this.entry});

  final _RailEntry entry;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text('○', style: _monoStyle(size: 11.5, color: AppTokens.faint)),
          const SizedBox(width: 6),
          if (entry.quadrant != null) ...<Widget>[
            PriorityMarks(quadrant: entry.quadrant),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              entry.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(size: 12.5, color: AppTokens.ink2),
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      key: ValueKey<String>(entry.key),
      data: entry.payload,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragChip(label: entry.label),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Material(
          color: Colors.transparent,
          child: row,
        ),
      ),
    );
  }
}

/// 已排期条目：**只读**（不包 `Draggable`），弱化字色 + `已排期` 提示。
///
/// 形状与可拖条目一致，只是没有拖拽柄光标、没有 `Draggable` —— 它不可能是
/// 方格时间轴的落点来源。
class _ReadOnlyEntry extends StatelessWidget {
  const _ReadOnlyEntry({required this.label, this.quadrant});

  final String label;

  /// 四维度优先级；null = 未分级。
  final Quadrant? quadrant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text('○', style: _monoStyle(size: 11.5, color: AppTokens.faint)),
          const SizedBox(width: 6),
          if (quadrant != null) ...<Widget>[
            PriorityMarks(quadrant: quadrant),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(size: 12.5, color: AppTokens.faint),
            ),
          ),
          const SizedBox(width: 6),
          Text('已排期', style: _monoStyle(size: 10.5, color: AppTokens.faint)),
        ],
      ),
    );
  }
}

/// 拖拽中的窄条卡片。
class _DragChip extends StatelessWidget {
  const _DragChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: AppTokens.hairStrong),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _bodyStyle(size: 12, color: AppTokens.ink),
        ),
      ),
    );
  }
}

/// 右轨只读提示（空态 / 加载 / 失败），不带任何按钮。
class _RailNote extends StatelessWidget {
  const _RailNote({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _bodyStyle(
        size: 12,
        color: danger ? AppTokens.accentInk : AppTokens.faint,
      ),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({double size = 12.5, Color color = AppTokens.ink}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
  );
}

/// 数字/键帽字体样式（`AppFonts.mono` + `tabular-nums`）。
TextStyle _monoStyle({double size = 11.5, Color color = AppTokens.faint}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}