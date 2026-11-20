// =============================================================================
// 方格时间轴 · 任务详情 / 编辑窗
// =============================================================================
// 为什么需要它（Task 45 · W2 · 用户当轮需求 2）：
//   条目 chip 右侧的「未分级」「删除」「状态词」已移除，编辑入口改由**左键 /
//   Enter** 打开本窗：标题只读、内容 / 级别 / 回填内容 / 持续时间可编辑、
//   删除独立成按钮。chip 上仍留勾选框（完成与否的主入口）与四态字形。
//
// 为什么保存是**一次性提交**：
//   四块编辑各自落库会产生 4 次 oplog + 4 次流刷新，用户点「取消」时还要
//   回滚一半。本窗只在「保存」时把四块值一次性返回，由调用方
//   （`day_grid.dart` 的 `_openDetail`）比对后统一写库；「取消」一个字节都不写。
//
// 为什么删除要二次确认、且确认后**本窗先关**：
//   与 chip 上原有删除入口的语义一致（需求 9），确认框复用
//   `widgets\confirm_dialog.dart`；确认后本窗自己不关就会挂在一条已软删的
//   行上，所以先 pop 再交回调用方软删。
//
// 为什么起止控件照抄 `slot_range_dialog.dart` 的步进口径：
//   15 分钟粒度 + `formatMinute` + 实时「共 N 分钟」是既有的唯一语义，
//   这里只是换一套 Key 重画一遍，不去改那个文件（双击行仍走它）。
//
// Task 46 · W2 改了两件事（用户当轮口径）：
//   ① 标题从只读改成可编辑（写 `plan_item.title`，列早已存在、无迁移）；
//   ② 未来日（预排日）补上回填守卫：回填框禁用 + 可见锁定提示，保存时再把
//      `resultNote` 强制还原成库里的原值。`day_grid._openDetail` 侧另有
//      `!_future` 守卫 —— 窗与调用方双保险，任一处被放开也不会写脏。
//   标题 / 内容 / 级别 / 持续时间 / 删除对**未来日照常开放**：那是排期本身的
//   编辑，不是「做完了」的事实；打卡 / 回填 / 复盘 / 心态仍只限今天与过去。
// =============================================================================

import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../confirm_dialog.dart';
import '../priority_marks.dart';
import 'slot_fill.dart';
import 'slot_state.dart';

/// 详情窗的提交结果。
///
/// 五个可编辑区块 + 一个删除标记：调用方按字段与旧值比对，只写变化的列。
class PlanItemDetailResult {
  /// 创建一次提交结果。
  const PlanItemDetailResult({
    required this.startMinute,
    required this.endMinute,
    this.title,
    this.detail = '',
    this.resultNote = '',
    this.quadrant,
    this.delete = false,
  });

  /// 标题（`plan_item.title`）；null = 调用方不该写这一列。
  ///
  /// 只有「保存」分支会带上它；「删除」分支保持 null，因此不会顺带改标题。
  final String? title;

  /// 内容（`plan_item.detail`）。
  final String detail;

  /// 回填内容（`plan_item.result_note`）。
  final String resultNote;

  /// 级别（`plan_item.quadrant`）；null = 未分级。
  final Quadrant? quadrant;

  /// 起始分钟（`plan_item.planned_start`）。
  final int startMinute;

  /// 结束分钟（`plan_item.planned_end`）。
  final int endMinute;

  /// 是否为「删除」提交（此时其余字段无意义）。
  final bool delete;
}

/// 弹出任务详情窗；取消返回 null。
///
/// [defaultStart] / [defaultEnd] 是条目在网格上的实际区间，用于
/// `planned_start` / `planned_end` 为空的老数据 —— 不拿 0 当兜底。
/// [todayIso] 是调用方手上的「今天」（本地 `YYYY-MM-DD`）：窗内不自己调
/// `DateTime.now()`，否则测试无法把日期钉死。
Future<PlanItemDetailResult?> showPlanItemDetailDialog(
  BuildContext context, {
  required PlanItemData item,
  required String todayIso,
  required int defaultStart,
  required int defaultEnd,
}) {
  return showDialog<PlanItemDetailResult>(
    context: context,
    builder: (BuildContext ctx) => PlanItemDetailDialog(
      item: item,
      todayIso: todayIso,
      defaultStart: defaultStart,
      defaultEnd: defaultEnd,
    ),
  );
}

/// 任务详情 / 编辑窗本体。
class PlanItemDetailDialog extends StatefulWidget {
  /// 创建详情窗。
  const PlanItemDetailDialog({
    super.key,
    required this.item,
    required this.todayIso,
    required this.defaultStart,
    required this.defaultEnd,
  });

  /// 当前条目（构建时传入的行快照）。
  final PlanItemData item;

  /// 调用方的「今天」（本地 `YYYY-MM-DD`）。
  final String todayIso;

  /// 网格上的实际起始分钟（`planned_start` 为空时兜底）。
  final int defaultStart;

  /// 网格上的实际结束分钟（`planned_end` 为空时兜底）。
  final int defaultEnd;

  @override
  State<PlanItemDetailDialog> createState() => _PlanItemDetailDialogState();
}

class _PlanItemDetailDialogState extends State<PlanItemDetailDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.item.title);
  late final TextEditingController _content =
      TextEditingController(text: widget.item.detail);
  late final TextEditingController _note =
      TextEditingController(text: widget.item.resultNote);

  /// 本条目所在日期是否晚于今天（本地日期字符串比较，与 `day_grid` 同口径）。
  ///
  /// 未来日只锁**回填**（打卡 / 回填 / 复盘 / 心态）；标题 / 内容 / 级别 /
  /// 持续时间 / 删除照常可改 —— 那是排期本身的编辑。
  late final bool _future = widget.item.date.compareTo(widget.todayIso) > 0;

  /// 级别当前值：`null` = 未分级（与 `plan_item.quadrant` 的 null 同构）。
  late Quadrant? _quadrant = Quadrant.fromCode(widget.item.quadrant);

  late int _start = _alignedStart();
  late int _end = _alignedEnd(_start);

  int _alignedStart() =>
      alignMinuteDown(widget.item.plannedStart ?? widget.defaultStart);

  int _alignedEnd(int start) {
    final int end = alignMinuteUp(widget.item.plannedEnd ?? widget.defaultEnd);
    // 零长条目没有意义：结束不足一格时强制补一格（与 `SlotRangeDialog` 同口径）。
    return end <= start ? start + kSlotMinutes : end;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _note.dispose();
    super.dispose();
  }

  void _bumpStart(int delta) {
    setState(() {
      _start = clampToGrid(_start + delta);
      if (_end <= _start) {
        _end = alignMinuteUp(_start + kSlotMinutes);
      }
    });
  }

  void _bumpEnd(int delta) {
    setState(() {
      _end = clampToGrid(_end + delta);
      if (_end <= _start) {
        _end = _start + kSlotMinutes;
      }
    });
  }

  /// 「成果 / 进展模板」：打开**既有**回填合成器，把结果串写进回填内容框。
  ///
  /// 只取 `note`、**不碰 status** —— 「完成」仍由 chip 的勾选框负责，
  /// 这里落库的是 `result_note` 一列。
  Future<void> _openTemplate() async {
    // 未来日模板按钮本就是 disabled，这里再拦一道：窗内任何路径都不该往
    // `result_note` 里写字。
    if (_future) {
      return;
    }
    final SlotFillEdit? edit = await showSlotFillDialog(
      context,
      title: widget.item.title,
      initialNote: _note.text,
    );
    if (!mounted || edit == null) {
      return;
    }
    _note.text = edit.note;
  }

  Future<void> _requestDelete() async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: '删除计划项',
      message: '确认删除「${widget.item.title}」？删除后它不再出现在清单里。',
    );
    if (!mounted || !confirmed) {
      return;
    }
    Navigator.of(context).pop(
      PlanItemDetailResult(
        startMinute: _start,
        endMinute: _end,
        delete: true,
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      PlanItemDetailResult(
        title: _title.text,
        detail: _content.text,
        // 未来日不落回填：即使控件被别处放开，这里也把值还原成库里的原值。
        resultNote: _future ? widget.item.resultNote : _note.text,
        quadrant: _quadrant,
        startMinute: _start,
        endMinute: _end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = context.tokens;
    return AlertDialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      title: Text(
        '任务详情',
        style: TextStyle(fontSize: 16, color: t.ink),
      ),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ① 标题：可编辑（Task 46 · W2 放开；写 `plan_item.title`）。
            //    未来日同样可改 —— 预排时本来就要能修订标题。
            Text('标题', style: TextStyle(fontSize: 10, color: t.meta)),
            const SizedBox(height: 2),
            TextField(
              key: const ValueKey<String>('plan-detail-title'),
              controller: _title,
              style: TextStyle(fontSize: 16, color: t.ink),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.gapCard),
            // ② 内容：写 `plan_item.detail`。
            TextField(
              key: const ValueKey<String>('plan-detail-content'),
              controller: _content,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(fontSize: 13, color: t.ink2),
              decoration: const InputDecoration(
                isDense: true,
                labelText: '内容',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.gapCard),
            // ③ 级别：复用既有四维标记选择器（两轴各自二选一 + 清除）。
            Text('级别', style: TextStyle(fontSize: 10, color: t.meta)),
            const SizedBox(height: 4),
            PriorityMarkPicker(
              value: _quadrant,
              onChanged: (Quadrant? next) {
                setState(() {
                  _quadrant = next;
                });
              },
            ),
            const SizedBox(height: AppTokens.gapCard),
            // ④ 回填内容：写 `plan_item.result_note`，不改 status。
            //    未来日禁用 —— 回填是「做完了」的产物，只允许今天与过去。
            TextField(
              key: const ValueKey<String>('plan-detail-note'),
              controller: _note,
              enabled: !_future,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(fontSize: 13, color: t.ink2),
              decoration: const InputDecoration(
                isDense: true,
                labelText: '回填内容',
                border: OutlineInputBorder(),
              ),
            ),
            if (_future)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '未来日不可回填：打卡 / 回填 / 复盘 / 心态只允许今天与过去。',
                  key: const ValueKey<String>('plan-detail-note-locked'),
                  style: TextStyle(fontSize: 11.5, color: t.meta),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey<String>('plan-detail-template'),
                onPressed: _future ? null : _openTemplate,
                child: const Text('成果 / 进展模板'),
              ),
            ),
            // ⑤ 持续时间：15 分钟粒度步进 + 实时「共 N 分钟」。
            Text('持续时间', style: TextStyle(fontSize: 10, color: t.meta)),
            const SizedBox(height: 2),
            _DetailStepperRow(
              label: '开始',
              fieldKey: const ValueKey<String>('plan-detail-start'),
              value: _start,
              onMinus: () => _bumpStart(-kSlotMinutes),
              onPlus: () => _bumpStart(kSlotMinutes),
            ),
            const SizedBox(height: 4),
            _DetailStepperRow(
              label: '结束',
              fieldKey: const ValueKey<String>('plan-detail-end'),
              value: _end,
              onMinus: () => _bumpEnd(-kSlotMinutes),
              onPlus: () => _bumpEnd(kSlotMinutes),
            ),
            const SizedBox(height: 4),
            Text(
              '共 ${_end - _start} 分钟',
              key: const ValueKey<String>('plan-detail-duration'),
              style: TextStyle(fontSize: 12.5, color: t.meta),
            ),
            const SizedBox(height: AppTokens.gapCard),
            // ⑥ 删除：独立入口，二次确认后由调用方软删。
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey<String>('plan-detail-delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: _requestDelete,
                child: const Text('删除'),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('plan-detail-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          key: const ValueKey<String>('plan-detail-save'),
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 起止步进行（与 `slot_range_dialog.dart` 的 `_StepperRow` 同口径，
/// 只是 Key 前缀不同 —— 那个文件不归本波次改）。
class _DetailStepperRow extends StatelessWidget {
  const _DetailStepperRow({
    required this.label,
    required this.fieldKey,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final Key fieldKey;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: t.meta),
          ),
        ),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove, size: 16),
          tooltip: '$label 减一格',
        ),
        SizedBox(
          width: 64,
          child: Text(
            formatMinute(value),
            key: fieldKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              letterSpacing: 0.4,
              color: t.ink,
            ),
          ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add, size: 16),
          tooltip: '$label 加一格',
        ),
      ],
    );
  }
}