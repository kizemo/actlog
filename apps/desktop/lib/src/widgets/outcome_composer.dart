// apps/desktop/lib/src/widgets/outcome_composer.dart
import 'package:flutter/material.dart';

import 'package:core_domain/core_domain.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import 'chip_row.dart';

/// 三段合成器（结论 → 原因 → 下一步）。
///
/// 写库只写一句规范文案（spec §6.1）；自由文本只允许落在 `[下一步]`。
class OutcomeComposer extends StatefulWidget {
  /// 创建合成器。
  const OutcomeComposer({super.key, required this.initial, this.onSubmit});

  /// 初始 `result_note` 原文。
  final String initial;

  /// 提交回调；传编码后的规范文案与「是否标记完成」的意图。
  ///
  /// 合成器**不自己**弹窗：宿主在回调里 `Navigator.of(context).pop(...)` 回传结果。
  final void Function(String encoded, {required bool markDone})? onSubmit;

  /// 结论短语（spec §7）。
  static const List<String> outcomeLabels = <String>[
    '按时完成',
    '延后完成',
    '提前完成',
    '部分完成',
    '受阻',
    '顺延到明天',
    '取消',
  ];

  /// 原因短语（spec §7）。
  static const List<String> reasonLabels = <String>[
    '预估不足',
    '被打断',
    '依赖外部',
    '优先级变了',
    '状态不好',
    '时间不够',
    '信息不清',
    '其他',
  ];

  /// 下一步短语（spec §7）。
  static const List<String> nextStepLabels = <String>[
    '明天继续',
    '转成待办',
    '交出去',
    '缩小范围',
    '定日复盘',
    '就此停止',
  ];

  /// 落库值 → 当前语言的显示文案（spec §7 那 21 条短语）。
  ///
  /// 落库值**一个字节都不改**：上面三个常量仍是那 21 条中文短语，`_setSegment`
  /// 原样把它们塞进 `ResultNote`。本方法只做**显示层**的映射 —— zh 侧显示值与
  /// 落库值逐字相同（中文界面零视觉变化），en 侧显示英文译文。
  ///
  /// 未知的历史值（用户自己写进 `[下一步]` 的自由文本、同步进来的旧数据）
  /// **原样返回**，不猜译名、不崩 —— 先例见 `l10n\app_localizations.dart` 的
  /// `projectDomainLabel`。
  static String displayLabel(AppLocalizations t, String stored) {
    switch (stored) {
      case '按时完成':
        return t.dialogOutcomeOnTime;
      case '延后完成':
        return t.dialogOutcomeLate;
      case '提前完成':
        return t.dialogOutcomeEarly;
      case '部分完成':
        return t.dialogOutcomePartial;
      case '受阻':
        return t.dialogOutcomeBlocked;
      case '顺延到明天':
        return t.dialogOutcomeDeferredTomorrow;
      case '取消':
        return t.cancel;
      case '预估不足':
        return t.dialogReasonUnderestimated;
      case '被打断':
        return t.dialogReasonInterrupted;
      case '依赖外部':
        return t.dialogReasonExternal;
      case '优先级变了':
        return t.dialogReasonPriorityChanged;
      case '状态不好':
        return t.dialogReasonPoorState;
      case '时间不够':
        return t.dialogReasonNoTime;
      case '信息不清':
        return t.dialogReasonUnclear;
      case '其他':
        return t.dialogReasonOther;
      case '明天继续':
        return t.dialogNextStepContinueTomorrow;
      case '转成待办':
        return t.dialogNextStepToTodo;
      case '交出去':
        return t.dialogNextStepHandOff;
      case '缩小范围':
        return t.dialogNextStepNarrowScope;
      case '定日复盘':
        return t.dialogNextStepReviewLater;
      case '就此停止':
        return t.dialogNextStepStopHere;
      default:
        return stored;
    }
  }

  @override
  State<OutcomeComposer> createState() => _OutcomeComposerState();
}

class _OutcomeComposerState extends State<OutcomeComposer> {
  late ResultNote _note = ResultNote.parse(widget.initial);
  bool _restructured = false;

  /// `[下一步]` 自由文本输入框；初值 = 初始文案里的 `[下一步]` 段。
  late final TextEditingController _nextStepController = TextEditingController(
    text: _note.nextStep,
  );

  @override
  void didUpdateWidget(covariant OutcomeComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial == oldWidget.initial) {
      return;
    }
    _note = ResultNote.parse(widget.initial);
    _restructured = false;
    _nextStepController.text = _note.nextStep;
  }

  @override
  void dispose() {
    _nextStepController.dispose();
    super.dispose();
  }

  void _setSegment(ResultNoteLabel label, String text) {
    setState(() {
      _note = switch (label) {
        ResultNoteLabel.outcome => ResultNote(
          outcome: text,
          reason: _note.reason,
          nextStep: _note.nextStep,
        ),
        ResultNoteLabel.reason => ResultNote(
          outcome: _note.outcome,
          reason: text,
          nextStep: _note.nextStep,
        ),
        ResultNoteLabel.nextStep => ResultNote(
          outcome: _note.outcome,
          reason: _note.reason,
          nextStep: text,
        ),
      };
    });
  }

  /// 选中「下一步」芯片：芯片短语独占 `[下一步]` 槽位，自由文本必须让位。
  void _pickNextStepChip(String label) {
    _nextStepController.clear();
    _setSegment(ResultNoteLabel.nextStep, label);
  }

  /// 自由文本落在 `[下一步]` 槽位；此时芯片短语让位（芯片选中态由文本内容反推）。
  void _typeNextStep(String text) {
    _setSegment(ResultNoteLabel.nextStep, text.trim());
  }

  /// 规范文案是否可落库（spec §6.1 文法）。
  bool get _canSubmit => _note.wellFormed;

  void _submit(bool markDone) {
    final handler = widget.onSubmit;
    if (handler == null || !_canSubmit) {
      return;
    }
    handler(_note.encoded, markDone: markDone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (!_note.parsed && !_restructured) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _note.rawText,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _restructured = true;
                  _note = const ResultNote();
                }),
                child: Text(l10n.dialogNoteRestructure),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.domainConclusionLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ChipRow(
          options: <ChipOption>[
            for (final label in OutcomeComposer.outcomeLabels)
              ChipOption(
                key: label,
                label: OutcomeComposer.displayLabel(l10n, label),
              ),
          ],
          selected: _note.outcome.isEmpty ? const <String>{} : <String>{_note.outcome},
          onChanged: (next) =>
              _setSegment(ResultNoteLabel.outcome, next.isEmpty ? '' : next.first),
        ),
        const SizedBox(height: 10),
        Text(l10n.domainReasonLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ChipRow(
          options: <ChipOption>[
            for (final label in OutcomeComposer.reasonLabels)
              ChipOption(
                key: label,
                label: OutcomeComposer.displayLabel(l10n, label),
              ),
          ],
          selected: _note.reason.isEmpty ? const <String>{} : <String>{_note.reason},
          onChanged: (next) =>
              _setSegment(ResultNoteLabel.reason, next.isEmpty ? '' : next.first),
        ),
        const SizedBox(height: 10),
        Text(l10n.domainNextStepLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ChipRow(
          options: <ChipOption>[
            for (final label in OutcomeComposer.nextStepLabels)
              ChipOption(
                key: label,
                label: OutcomeComposer.displayLabel(l10n, label),
              ),
          ],
          selected: OutcomeComposer.nextStepLabels.contains(_note.nextStep)
              ? <String>{_note.nextStep}
              : const <String>{},
          onChanged: (next) => next.isEmpty
              ? _typeNextStep('')
              : _pickNextStepChip(next.first),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nextStepController,
          maxLength: ResultNote.maxTextLength,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.deny(RegExp(r'[\[\]|]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.dialogNoteNextStepLabel,
            isDense: true,
          ),
          onChanged: _typeNextStep,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _canSubmit ? () => _submit(false) : null,
              child: Text(l10n.dialogNoteSaveProgressOnly),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSubmit ? () => _submit(true) : null,
              child: Text(l10n.dialogNoteDone),
            ),
          ],
        ),
      ],
    );
  }
}