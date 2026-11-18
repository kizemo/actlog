import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../providers_p1.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import '../priority_hover_bubble.dart';

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

    // 三种状态（失败 / 加载 / 空）的原文案一字不改，只是把「优先级分布」块
    // 从列表内容里摘出来、恒挂在末尾 —— 否则空态下整块分布会跟着消失。
    final List<Widget> rows;
    if (todosAsync.hasError || slottedAsync.hasError) {
      rows = <Widget>[const _RailNote(text: '待办加载失败', danger: true)];
    } else if (!todosAsync.hasValue || !slottedAsync.hasValue) {
      rows = <Widget>[const _RailNote(text: '正在加载待办…')];
    } else {
      // 已排期集合按 `todo.id` 计（跨日期），与待办池「已排期」徽标同一事实源。
      final slottedIds = slottedAsync.value!.keys.toSet();
      final todos = todosAsync.value!;
      rows = <Widget>[
        if (todos.isEmpty) const _RailNote(text: '暂无待办'),
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
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...rows,
        // 「优先级分布」只能挂在这里：右轨四块由 `app.dart` 的
        // `todayRailPanels()` 装配，而 `app.dart` 不在本批写集内。
        const PriorityDistributionPanel(),
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
    final ThemeTokens t = context.tokens;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text('○', style: _monoStyle(size: 11.5, color: t.faint)),
          const SizedBox(width: 6),
          if (entry.quadrant != null) ...<Widget>[
            // 悬停即可读两维取值；待办侧暂为只读（见 `_ReadOnlyEntry` 注释）。
            PriorityHoverBubble(
              quadrant: entry.quadrant,
              title: entry.label,
              ownerKey: 'rail-${entry.key}',
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              entry.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(size: 12.5, color: t.ink2),
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
    final ThemeTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text('○', style: _monoStyle(size: 11.5, color: t.faint)),
          const SizedBox(width: 6),
          if (quadrant != null) ...<Widget>[
            // 已排期条目同样只能读：它的数据源是 todo，而 `TodoRepository`
            // 只有 `listOpen` / `create` / `pullToPlan`，没有 `setQuadrant`，
            // 故这里不传 `onChanged`。
            PriorityHoverBubble(
              quadrant: quadrant,
              title: label,
              ownerKey: 'rail-slotted',
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(size: 12.5, color: t.faint),
            ),
          ),
          const SizedBox(width: 6),
          Text('已排期', style: _monoStyle(size: 10.5, color: t.faint)),
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
    final ThemeTokens t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: t.hairStrong),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _bodyStyle(size: 12, color: t.ink),
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
    final ThemeTokens t = context.tokens;
    return Text(
      text,
      style: _bodyStyle(
        size: 12,
        color: danger ? t.accentInk : t.faint,
      ),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
///
/// 颜色必须由调用方从 `context.tokens` 传入：Dart 的默认参数只能是编译期常量，
/// 而主题色是运行期值（浅色 / 深色两套）。
TextStyle _bodyStyle({double size = 12.5, required Color color}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
  );
}

/// 数字/键帽字体样式（`AppFonts.mono` + `tabular-nums`）。
TextStyle _monoStyle({double size = 11.5, required Color color}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

/// 右轨块标题（原型 `.rail h3`：12px / 600 / 字距 .13em / `--faint`）。
/// 为什么是函数而不是 `const TextStyle`：标题色随主题变，运行期颜色进不了
/// 编译期常量。
TextStyle _panelTitleStyle(ThemeTokens tokens) => TextStyle(
  fontFamily: AppFonts.body,
  fontFamilyFallback: AppFonts.bodyFallback,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.5,
  color: tokens.faint,
);

/// 右轨「优先级分布」块：Q1–Q4 计数 **只读**展示。
///
/// 数据源就是今日计划条目的 `quadrant` 码值（`planItemsProvider` 已按所选日
/// 过滤、已排除软删行），与格子里的四维字形同源 —— 不存在第二份计数口径。
///
/// 为什么没有写入口：改分级只有一个合法入口（格子里那条的四维气泡，T1）。
/// 右轨再开一个写点就有两条改分级的路径，其中一条漏掉「未来日豁免」就会和
/// 另一条打架。只读是纪律，不是没做完。
class PriorityDistributionPanel extends ConsumerWidget {
  /// 创建右轨「优先级分布」块。
  const PriorityDistributionPanel({super.key});

  /// 行标列宽（原型 `.qgrid` 第一列 `34px`，这里留到 38px 容纳「不重要」）。
  static const double _labelWidth = 38;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PlanItemData>? items =
        ref.watch(planItemsProvider).asData?.value;
    final Map<Quadrant, int> counts = <Quadrant, int>{
      for (final Quadrant q in Quadrant.values) q: 0,
    };
    int total = 0;
    int ungraded = 0;
    for (final PlanItemData row in items ?? const <PlanItemData>[]) {
      total++;
      final Quadrant? quadrant = Quadrant.fromCode(row.quadrant);
      if (quadrant == null) {
        ungraded++;
      } else {
        counts[quadrant] = counts[quadrant]! + 1;
      }
    }

    final ThemeTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        key: const ValueKey<String>('rail-priority-distribution'),
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: t.hairSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('优先级分布', style: _panelTitleStyle(t)),
            const SizedBox(height: 8),
            // 表头：紧急 / 不紧急（原型 `.qgrid` 第 2、3 列）。
            Row(
              children: <Widget>[
                const SizedBox(width: _labelWidth),
                Expanded(
                  child: Text(
                    '紧急',
                    style: _bodyStyle(size: 10.5, color: t.faint),
                  ),
                ),
                Expanded(
                  child: Text(
                    '不紧急',
                    style: _bodyStyle(size: 10.5, color: t.faint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    '重要',
                    style: _bodyStyle(size: 10.5, color: t.faint),
                  ),
                ),
                Expanded(
                  child: _QuadrantCell(
                    quadrant: Quadrant.q1,
                    count: counts[Quadrant.q1]!,
                  ),
                ),
                Expanded(
                  child: _QuadrantCell(
                    quadrant: Quadrant.q2,
                    count: counts[Quadrant.q2]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    '不重要',
                    style: _bodyStyle(size: 10.5, color: t.faint),
                  ),
                ),
                Expanded(
                  child: _QuadrantCell(
                    quadrant: Quadrant.q3,
                    count: counts[Quadrant.q3]!,
                  ),
                ),
                Expanded(
                  child: _QuadrantCell(
                    quadrant: Quadrant.q4,
                    count: counts[Quadrant.q4]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 原型 `.rail-foot` 的上沿细线。
            Container(height: 1, color: t.hairSoft),
            const SizedBox(height: 7),
            // 用 `Wrap` 而不是 `Row`：右轨宽度随视口收缩，`Wrap` 换行不溢出。
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  '$total 条计划 · 未分级 ',
                  style: _bodyStyle(size: 12, color: t.faint),
                ),
                Text(
                  '$ungraded 条',
                  style: _monoStyle(
                    size: 12,
                    // 赭石只标「缺口」：真有未分级条目才着色，为 0 时与旁文同色。
                    color: ungraded > 0 ? t.accentInk : t.faint,
                  ),
                ),
                Text(
                  '（不计入四象限）',
                  style: _bodyStyle(size: 12, color: t.faint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 四象限计数格（原型 `.qcell`）。计数为 0 时整格不渲染（`.qcell:empty`）。
class _QuadrantCell extends StatelessWidget {
  const _QuadrantCell({required this.quadrant, required this.count});

  final Quadrant quadrant;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final ThemeTokens t = context.tokens;
    return Container(
      key: ValueKey<String>('rail-quadrant-${quadrant.name}'),
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: t.hairSoft),
      ),
      child: Text('$count', style: _monoStyle(size: 12, color: t.ink)),
    );
  }
}
