// =============================================================================
// 方格时间轴 · 起止编辑弹窗（Esc 取消 / Enter 确认）
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_tokens.dart';
import 'slot_state.dart';

/// 拖动出来的起止区间。
class SlotRange {
  /// 创建区间。
  const SlotRange({required this.startMinute, required this.endMinute});

  /// 起始分钟。
  final int startMinute;

  /// 结束分钟（严格大于 [startMinute]）。
  final int endMinute;
}

/// 一格 → 一段的起止编辑弹窗。
///
/// 两条硬要求：
/// * `Esc` 取消、`Enter` 确认（键盘用户不该被迫去找按钮）；
/// * 起止永远落在 15 分钟格线上，结束严格大于起始（不产生零长条目）。
class SlotRangeDialog extends StatefulWidget {
  /// 创建弹窗。
  const SlotRangeDialog({
    super.key,
    required this.date,
    required this.initialStart,
    this.initialEnd,
  });

  /// 所属日期（`YYYY-MM-DD`，只用于标题）。
  final String date;

  /// 初始起始分钟。
  final int initialStart;

  /// 初始结束分钟；null 表示默认一格。
  final int? initialEnd;

  /// 弹出并等待结果；取消返回 null。
  static Future<SlotRange?> show(
    BuildContext context, {
    required String date,
    required int initialStart,
    int? initialEnd,
  }) {
    return showDialog<SlotRange>(
      context: context,
      builder: (BuildContext ctx) => SlotRangeDialog(
        date: date,
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );
  }

  @override
  State<SlotRangeDialog> createState() => _SlotRangeDialogState();
}

class _SlotRangeDialogState extends State<SlotRangeDialog> {
  late int _start = alignMinuteDown(widget.initialStart);
  late int _end = alignMinuteUp(
    widget.initialEnd ?? widget.initialStart + kSlotMinutes,
  );

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

  void _confirm() {
    Navigator.of(context).pop(
      SlotRange(startMinute: _start, endMinute: _end),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.enter): _confirm,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _confirm,
      },
      child: AlertDialog(
        backgroundColor: AppTokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        title: Text(
          '${widget.date} · 起止',
          style: const TextStyle(fontSize: 16, color: AppTokens.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _StepperRow(
              label: '开始',
              fieldKey: const ValueKey<String>('slot-range-start'),
              value: _start,
              onMinus: () => _bumpStart(-kSlotMinutes),
              onPlus: () => _bumpStart(kSlotMinutes),
            ),
            const SizedBox(height: AppTokens.gapCard),
            _StepperRow(
              label: '结束',
              fieldKey: const ValueKey<String>('slot-range-end'),
              value: _end,
              onMinus: () => _bumpEnd(-kSlotMinutes),
              onPlus: () => _bumpEnd(kSlotMinutes),
            ),
            const SizedBox(height: AppTokens.gapCard),
            Text(
              '共 ${_end - _start} 分钟',
              style: const TextStyle(fontSize: 12.5, color: AppTokens.meta),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('slot-range-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            key: const ValueKey<String>('slot-range-confirm'),
            onPressed: _confirm,
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTokens.meta),
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
            style: const TextStyle(
              fontSize: 15,
              letterSpacing: 0.4,
              color: AppTokens.ink,
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