// =============================================================================
// 方格时间轴 · 未排期带
// =============================================================================
// 为什么需要这条带：
//   「今日计划」整段删掉之后，`_AddPlanItemBar`（＋ 手写一条）写进去的条目
//   只有标题、没有 `planned_start` / `planned_end`，而 `gridEntriesOf` 会
//   跳过一切没有起止的条目 —— 不补这条带，手写的条目在界面上就是**无底洞**：
//   库里有、屏幕上没有。所以未排期条目在这里以标题芯片列出，
//   拖进格子即由 `DayGrid._onDrop` 的 `plan:<id>` 分支写成排期。
// =============================================================================

import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../theme/app_tokens.dart';
import '../priority_marks.dart';

/// 「未排期」带：只列还没有起止时间的条目，可拖进格子排期。
class UnscheduledStrip extends ConsumerWidget {
  /// 创建未排期带。
  const UnscheduledStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PlanItemData> rows =
        ref.watch(planItemsProvider).asData?.value ?? const <PlanItemData>[];
    final List<PlanItemData> pending = <PlanItemData>[
      for (final PlanItemData row in rows)
        if (row.plannedStart == null && row.plannedEnd == null) row,
    ];
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      key: const ValueKey<String>('unscheduled-strip'),
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final PlanItemData row in pending)
            Draggable<String>(
              data: 'plan:${row.id}',
              feedback: Material(
                color: Colors.transparent,
                child: _chip(row),
              ),
              child: _chip(row),
            ),
        ],
      ),
    );
  }

  Widget _chip(PlanItemData row) {
    // 与 `day_grid.dart` 的格子芯片同一条规矩：行里存码值，渲染层自己解析；
    // 无法识别（未来 schema）当作未分级 —— 不画标记、不占位、不抛异常。
    final Quadrant? quadrant = Quadrant.fromCode(row.quadrant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.slotPlan,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (quadrant != null) ...<Widget>[
            PriorityMarks(quadrant: quadrant),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              row.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTokens.ink2),
            ),
          ),
        ],
      ),
    );
  }
}