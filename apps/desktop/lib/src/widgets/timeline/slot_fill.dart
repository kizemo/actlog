// =============================================================================
// 方格时间轴 · 条目回填（成果 / 进展）
// =============================================================================
// 为什么从这里而不是 `today_page.dart` 弹层：
//   「今日计划」整段已删（B2 第二轮裁决），方格条目才是回填的唯一入口。
//   弹层逻辑必须跟着宿主一起搬进 `timeline/`，否则今日页会残留对计划段的
//   引用，B 的完成判据（引用为 0）就不成立。
//
// 为什么不用 Material 默认按钮配色：
//   本目录所有弹层都是账页口径（`AlertDialog` 只做容器，内文自己控色），
//   与 `slot_range_dialog.dart` / `_TitleDialog` 保持一致。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../outcome_composer.dart';

/// 一次回填的结果：勾没勾「完成」+ 编码后的进展串。
class SlotFillEdit {
  /// 创建一次回填结果。
  const SlotFillEdit({required this.done, required this.note});

  /// 用户是否按了「完成」。
  final bool done;

  /// `OutcomeComposer` 编码后的进展串（`[结论]xxx` 形状）。
  final String note;
}

/// 弹「成果 / 进展」层；返回 `null` 表示用户取消。
Future<SlotFillEdit?> showSlotFillDialog(
  BuildContext context, {
  required String title,
  required String initialNote,
}) {
  return showDialog<SlotFillEdit>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('成果 / 进展'),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTokens.meta),
            ),
            const SizedBox(height: 10),
            OutcomeComposer(
              initial: initialNote,
              onSubmit: (String encoded, {required bool markDone}) =>
                  Navigator.of(context).pop(
                SlotFillEdit(done: markDone, note: encoded),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 回填后的条目状态（spec §5.1 口径，与 B1 的 `_statusAfterResult` 等价）。
///
/// - 点「完成」⇒ `done`；
/// - 结论芯片含「顺延到明天」⇒ `deferred`、含「取消」⇒ `cancelled`；
/// - 其余结论 ⇒ 保持原状态。
PlanStatus slotStatusAfterFill(SlotFillEdit edit, String currentStatus) {
  if (edit.done) {
    return PlanStatus.done;
  }
  return switch (ResultNote.parse(edit.note).outcome) {
    '顺延到明天' => PlanStatus.deferred,
    '取消' => PlanStatus.cancelled,
    _ => PlanStatus.fromCode(currentStatus) ?? PlanStatus.pending,
  };
}

/// 「切勾选」意图（网格条目的 `Space`）。
///
/// 只改 `plan_item.status`（`done ⇄ pending`），**不弹任何层** —— 与
/// [OpenSlotResultIntent] 是两件事，语义不许混。
class ToggleSlotStatusIntent extends Intent {
  /// 创建意图。
  const ToggleSlotStatusIntent();
}

/// 「展开回填」意图（网格条目的 `Enter`）。
class OpenSlotResultIntent extends Intent {
  /// 创建意图。
  const OpenSlotResultIntent();
}