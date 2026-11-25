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
//
// Task 53 · W3（用户当轮需求 4）：「回填部分直接显示可选择的项，不要增加一次
//   跳转」。此前回填的选项只藏在 `plan-detail-template` ⇒ `showSlotFillDialog`
//   的第二层里，必须多跳一次才看得见「结论 / 原因 / 下一步」。本窗把这三组芯片
//   **内联**进回填 section，点一下就写进回填文本框；模板按钮保留（完整 composer
//   能力不删）。取值语义一字未改：落库仍是 `plan-detail-note` 那段纯文本，
//   `_submit` 的结果类型也没动 —— 芯片只是这段文本的快捷写法。
// =============================================================================

import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';
import '../chip_row.dart';
import '../confirm_dialog.dart';
import '../outcome_composer.dart';
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

  /// 第二层（「成果 / 进展模板」合成器）是否正开着。
  ///
  /// 开着时收起内联可选项：两层同时摆一批同样的标签，用户分不清点的是哪一层。
  bool _composing = false;

  /// 内联可选项三组芯片条的 Key（测试按组定位标签，避免与「取消」按钮撞名）。
  static const ValueKey<String> _kChipOutcome =
      ValueKey<String>('plan-detail-chip-outcome');
  static const ValueKey<String> _kChipReason =
      ValueKey<String>('plan-detail-chip-reason');
  static const ValueKey<String> _kChipNextStep =
      ValueKey<String>('plan-detail-chip-next-step');

  /// 标签之间的分隔（回填文本切片口径）。
  static final RegExp _wordGap = RegExp(r'\s+');

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

  // ---------------------------------------------------------------------------
  // Task 53 · W3：回填 section 的内联可选项（结论 / 原因 / 下一步）。
  //
  // 语义（**唯一的真源仍是回填文本框那段纯文本**）：
  //   · 标签以「空白分隔」的形式写进 `plan-detail-note`，所以「已选」= 该标签
  //     作为**整词**出现在文本里；用户在框里手打同一个词也算选中，不再另存一份
  //     状态 —— 两处状态迟早会漂。
  //   · 组内单选：点同组另一枚时先把该组其余标签从文本里摘掉，再写入新的一枚。
  //   · 再点已选的一枚 = 取消：只摘掉这一枚（连同它前面那个分隔），其余文本原样。
  //   · 组间可并存；写不进去的语义不存在（它就是文本框，`_submit` 照旧读它）。
  // ---------------------------------------------------------------------------

  /// 文本里出现过的词（按空白切）。
  Set<String> _tokens(String text) => text
      .split(_wordGap)
      .where((String s) => s.isNotEmpty)
      .toSet();

  /// 追加一个标签：不动已有文本，只在末尾补一个分隔。
  String _appendLabel(String text, String label) {
    final String head = text.trimRight();
    return head.isEmpty ? label : '$head $label';
  }

  /// 摘掉一个**整词**标签，连同一个相邻分隔，保留其余文本的原有形状。
  String _removeLabel(String text, String label) {
    final String escaped = RegExp.escape(label);
    // ① 前面有分隔（最常见）：一起摘掉。
    final RegExpMatch? lead =
        RegExp(r'\s+' + escaped + r'(?=\s|$)').firstMatch(text);
    if (lead != null) {
      return text.replaceRange(lead.start, lead.end, '');
    }
    // ② 标签在文本开头：摘掉标签 + 紧随的分隔。
    final RegExpMatch? tail = RegExp('^$escaped' r'\s+').firstMatch(text);
    if (tail != null) {
      return text.replaceRange(tail.start, tail.end, '');
    }
    // ③ 整个文本就这一个标签。
    return text.replaceFirst(label, '');
  }

  /// 芯片被点：按「组内单选 + 再点取消」的语义改写回填文本。
  ///
  /// [group] 是该组的全部标签（来自 `outcome_composer.dart` 的常量），
  /// [incoming] 是 `ChipRow` 多选态给出的「点完之后」的集合 —— 比当前少一位
  /// 就说明点的是已选项。
  void _applyChipTap(List<String> group, Set<String> incoming) {
    final Set<String> current = _tokens(_note.text);
    final Set<String> added = incoming.difference(current);
    setState(() {
      String text = _note.text;
      // 先清同组其余标签（单选语义；点已选项时这一步正好就是「取消」）。
      for (final String label in group) {
        if (!added.contains(label) && _tokens(text).contains(label)) {
          text = _removeLabel(text, label);
        }
      }
      if (added.isNotEmpty) {
        text = _appendLabel(text, added.first);
      }
      _note.text = text;
    });
  }

  /// 一组内联芯片（组标题 + `ChipRow`）。
  Widget _chipGroup(String title, Key rowKey, List<String> labels) {
    final ThemeTokens t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Set<String> picked = _tokens(_note.text).intersection(
      labels.toSet(),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: TextStyle(fontSize: 10, color: t.meta)),
        const SizedBox(height: 4),
        ChipRow(
          key: rowKey,
          // `multi: true` 才能「再点已选 = 取消」；单选由 `_applyChipTap` 兜。
          multi: true,
          options: <ChipOption>[
            for (final String label in labels)
              // `key` 是落库值（选中态与回填文本都按它判），`label` 是显示值。
              ChipOption(
                key: label,
                label: OutcomeComposer.displayLabel(l10n, label),
              ),
          ],
          selected: picked,
          onChanged: (Set<String> next) => _applyChipTap(labels, next),
        ),
      ],
    );
  }

  /// 回填 section 的三组可选项（用户需求 4：直接显示，不再多一跳）。
  Widget _inlinePickers() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _chipGroup(
          l10n.domainConclusionLabel,
          _kChipOutcome,
          OutcomeComposer.outcomeLabels,
        ),
        const SizedBox(height: 6),
        _chipGroup(
          l10n.domainReasonLabel,
          _kChipReason,
          OutcomeComposer.reasonLabels,
        ),
        const SizedBox(height: 6),
        _chipGroup(
          l10n.domainNextStepLabel,
          _kChipNextStep,
          OutcomeComposer.nextStepLabels,
        ),
      ],
    );
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
    // 第二层开着时收起内联可选项（同一批标签摆两层，点谁都容易落空）。
    setState(() => _composing = true);
    final SlotFillEdit? edit = await showSlotFillDialog(
      context,
      title: widget.item.title,
      initialNote: _note.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _composing = false;
      if (edit != null) {
        // 合成器返回的是 `[结论]…` 编码串；它就是这个文本框的值，直接覆盖。
        _note.text = edit.note;
      }
    });
  }

  Future<void> _requestDelete() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showConfirmDialog(
      context,
      title: l10n.timelineDeletePlanItemTitle,
      message: l10n.timelineDeletePlanItemMessage(widget.item.title),
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      title: Text(
        l10n.timelineTaskDetailTitle,
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
            Text(l10n.commonTitle, style: TextStyle(fontSize: 10, color: t.meta)),
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
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.timelineContentLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.gapCard),
            // ③ 级别：复用既有四维标记选择器（两轴各自二选一 + 清除）。
            Text(l10n.timelineLevelLabel, style: TextStyle(fontSize: 10, color: t.meta)),
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
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.timelineBackfillContentLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_future)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.timelineFutureDayBackfillBlocked,
                  key: const ValueKey<String>('plan-detail-note-locked'),
                  style: TextStyle(fontSize: 11.5, color: t.meta),
                ),
              ),
            // 用户需求 4：可选项就摆在回填框下面，不要多一跳。
            // 未来日不渲染（回填整体不可用）；模板层开着时收起（同一批标签
            // 摆两层既冗余，也会让 `find.text(...)` 撞车）。
            if (!_future && !_composing) ...<Widget>[
              const SizedBox(height: 6),
              _inlinePickers(),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey<String>('plan-detail-template'),
                onPressed: _future ? null : _openTemplate,
                child: Text(l10n.timelineOutcomeTemplateTitle),
              ),
            ),
            // ⑤ 持续时间：15 分钟粒度步进 + 实时「共 N 分钟」。
            Text(l10n.timelineDurationLabel, style: TextStyle(fontSize: 10, color: t.meta)),
            const SizedBox(height: 2),
            _DetailStepperRow(
              label: l10n.timelineStartLabel,
              fieldKey: const ValueKey<String>('plan-detail-start'),
              value: _start,
              onMinus: () => _bumpStart(-kSlotMinutes),
              onPlus: () => _bumpStart(kSlotMinutes),
            ),
            const SizedBox(height: 4),
            _DetailStepperRow(
              label: l10n.timelineEndLabel,
              fieldKey: const ValueKey<String>('plan-detail-end'),
              value: _end,
              onMinus: () => _bumpEnd(-kSlotMinutes),
              onPlus: () => _bumpEnd(kSlotMinutes),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.timelineTotalMinutes(_end - _start),
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
                child: Text(l10n.commonDelete),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('plan-detail-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey<String>('plan-detail-save'),
          onPressed: _submit,
          child: Text(l10n.commonSave),
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
    final AppLocalizations l10n = AppLocalizations.of(context);
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
          tooltip: l10n.timelineStepDown(label),
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
          tooltip: l10n.timelineStepUp(label),
        ),
      ],
    );
  }
}