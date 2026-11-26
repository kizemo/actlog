// =============================================================================
// 目标 · 起止日期对话框（B10-B4）
// =============================================================================
// 蓝图矩阵「日期」列的编辑入口：两个 `showDatePicker`（结束可空）+ 清除/取消/确定。
//
// 口径：
//  1. 起始为空 ⇒ 回调返回 `startMs == 0`。`Goal.periodStart` 是**非空** int，
//     「无起始」只能写成 0；且 `GoalField` 里**没有** `periodStart`，所以清空起始
//     的合法做法就是传 0（领域层 `periodEnd != null && periodEnd < periodStart` 才抛，
//     0 配 null 合法）。
//  2. 结束为空 ⇒ `endMs == null`；调用方负责补 `clear: {GoalField.periodEnd}`。
//  3. 结束早于起始 ⇒ 确认时按起始对齐（不弹错、不写非法周期）。
//  4. 文案一律走 `t.` getter；日期按 `yyyy-MM-dd` 显示，缺值占位符 `—`（与年页同口径）。
//  5. **存储口径（B11 核实）**：起止毫秒 = 「**本地**某日 00:00 那一刻的毫秒数」
//     （`showDatePicker` 给的是本地 `DateTime`，落库取它的 `millisecondsSinceEpoch`），
//     因此解析与显示一律按**本地时区**；按 UTC 解释会让东八区整体提前一天。
//
// 键（测试用）：`goal-period-dialog` / `goal-period-start` / `goal-period-end` /
// `goal-period-clear` / `goal-period-cancel` / `goal-period-confirm`。
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 起止日期的编辑结果。
class GoalPeriodResult {
  /// 构造。
  const GoalPeriodResult({required this.startMs, required this.endMs});

  /// 起始（**本地午夜毫秒**；`0` = 清空起始）。
  final int startMs;

  /// 结束（**本地午夜毫秒**；null = 无固定终点）。
  final int? endMs;
}

/// 打开起止日期对话框；取消返回 null（调用方据此**不写库**）。
Future<GoalPeriodResult?> showGoalPeriodDialog(
  BuildContext context, {
  required AppLocalizations t,
  required int startMs,
  int? endMs,
}) {
  return showDialog<GoalPeriodResult>(
    context: context,
    builder: (BuildContext context) =>
        _GoalPeriodDialog(t: t, startMs: startMs, endMs: endMs),
  );
}

class _GoalPeriodDialog extends StatefulWidget {
  const _GoalPeriodDialog({
    required this.t,
    required this.startMs,
    required this.endMs,
  });

  final AppLocalizations t;
  final int startMs;
  final int? endMs;

  @override
  State<_GoalPeriodDialog> createState() => _GoalPeriodDialogState();
}

class _GoalPeriodDialogState extends State<_GoalPeriodDialog> {
  int _startMs = 0;
  int? _endMs;

  @override
  void initState() {
    super.initState();
    _startMs = widget.startMs;
    _endMs = widget.endMs;
  }

  /// 有没有起始（0 = 无）。
  bool get _hasStart => _startMs > 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey<String>('goal-period-dialog'),
      title: Text(widget.t.goalBlueprintPeriodTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _row(
            rowKey: 'goal-period-start',
            label: widget.t.goalBlueprintPeriodStart,
            text: _dateText(_hasStart ? _startMs : null),
            onPressed: _pickStart,
          ),
          const SizedBox(height: 8),
          _row(
            rowKey: 'goal-period-end',
            label: widget.t.goalBlueprintPeriodEnd,
            text: _dateText(_endMs),
            onPressed: _pickEnd,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('goal-period-clear'),
          onPressed: () => Navigator.of(context).pop(
            const GoalPeriodResult(startMs: 0, endMs: null),
          ),
          child: Text(widget.t.commonClear),
        ),
        TextButton(
          key: const ValueKey<String>('goal-period-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.t.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('goal-period-confirm'),
          onPressed: _confirm,
          child: Text(widget.t.confirm),
        ),
      ],
    );
  }

  /// 一行「标签 + 日期按钮」。
  Widget _row({
    required String rowKey,
    required String label,
    required String text,
    required Future<void> Function() onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(width: 40, child: Text(label)),
        const SizedBox(width: 8),
        OutlinedButton(
          key: ValueKey<String>(rowKey),
          onPressed: onPressed,
          child: Text(text),
        ),
      ],
    );
  }

  Future<void> _pickStart() async {
    final DateTime? picked = await _pick(_hasStart ? _startMs : null);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _startMs = picked.millisecondsSinceEpoch);
  }

  Future<void> _pickEnd() async {
    final DateTime? picked = await _pick(_endMs);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _endMs = picked.millisecondsSinceEpoch);
  }

  Future<DateTime?> _pick(int? millis) {
    // 起止是「本地某日 00:00 那一刻的毫秒数」⇒ 按**本地时区**还原成那一天再喂给
    // 日期选择器。（原先的 `isUtc: true` + `toLocal()` 绕了一圈回到同一个本地时刻，
    // 结果相同但读起来像「按 UTC 解释」，容易再写错；这里直接用本地口径。）
    final DateTime initial = millis == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(millis);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  void _confirm() {
    final int start = _hasStart ? _startMs : 0;
    int? end = _endMs;
    // 结束早于起始 ⇒ 按起始对齐（否则 `Goal.create` 会抛「period_end 不能早于 period_start」）。
    if (start > 0 && end != null && end < start) {
      end = start;
    }
    Navigator.of(context).pop(GoalPeriodResult(startMs: start, endMs: end));
  }

  /// 本地午夜毫秒 → `yyyy-MM-dd`（null = 缺值 → `—`）。
  ///
  /// 口径：起止存的是「**本地**某日 00:00 那一刻的毫秒数」（`showDatePicker` 给的
  /// 就是本地 `DateTime`，落库取它的 `millisecondsSinceEpoch`）⇒ 解析与显示都按
  /// **本地时区**；按 UTC 解释会让东八区整体提前一天（装机实测：选 11-01 显示成 10-31）。
  String _dateText(int? millis) {
    if (millis == null || millis <= 0) {
      return '—';
    }
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(millis);
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }
}