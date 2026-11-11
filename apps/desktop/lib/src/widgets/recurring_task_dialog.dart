import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_recurring.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 打开「添加循环任务」面板（右轨「循环任务」右上角那枚 `＋`）。
///
/// 与 `showHabitQuickDialog` 同一套壳：`Esc` / 点遮罩关闭由 `ModalRoute` 提供。
Future<void> showRecurringTaskDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const RecurringTaskDialog(),
  );
}

/// 「添加循环任务」面板：一条按星期重复、带起始时刻的规则。
///
/// 字段：`标题`（必填）、`星期`（多选，默认工作日）、`开始`（`HH:mm`，默认
/// 09:00）、`时长`（分钟，默认 30）、`备注`（可选）。
/// 保存后**立刻物化当天**，所以今天的计划里会马上出现这一条。
class RecurringTaskDialog extends ConsumerStatefulWidget {
  /// 创建「添加循环任务」面板。
  const RecurringTaskDialog({super.key});

  @override
  ConsumerState<RecurringTaskDialog> createState() =>
      _RecurringTaskDialogState();
}

class _RecurringTaskDialogState extends ConsumerState<RecurringTaskDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _time = TextEditingController(text: '09:00');
  final TextEditingController _duration = TextEditingController(text: '30');
  final TextEditingController _note = TextEditingController();

  /// 星期掩码；bit0 = 周一 … bit6 = 周日。默认工作日（`0x1F`）。
  int _mask = WeekdayMask.workdays;

  /// 提交中禁用按钮，防止连点写出两条规则。
  bool _submitting = false;

  /// 面板内错误原文（不写库、不关面板）。
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _duration.dispose();
    _note.dispose();
    super.dispose();
  }

  void _toggleWeekday(int isoWeekday) {
    if (_submitting) {
      return;
    }
    setState(() {
      _mask ^= WeekdayMask.bitOf(isoWeekday);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = '标题不能为空');
      return;
    }
    if (_mask == WeekdayMask.none) {
      setState(() => _error = '至少要选一个星期');
      return;
    }
    final int? startMinute = parseMinuteOfDay(_time.text);
    if (startMinute == null) {
      setState(() => _error = '开始时刻要写成 HH:mm（例如 09:00）');
      return;
    }
    final int? duration = int.tryParse(_duration.text.trim());
    if (duration == null || duration <= 0 || duration > minutesPerDay) {
      setState(() => _error = '时长必须是 1..1440 之间的整数（分钟）');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    // await 之后 `context` 不能再直接用于导航；`ref.read` 也只在 await 前读一次。
    final NavigatorState navigator = Navigator.of(context);
    final String date = ref.read(selectedDateProvider);
    try {
      final repos = ref.read(repositoriesProvider);
      await repos.recurring.create(
        title: title,
        weekdayMask: _mask,
        startMinute: startMinute,
        durationMinutes: duration,
        note: _note.text.trim(),
      );
      // 立刻物化「当前选中日」：规则命中今天就马上出现在计划里（幂等）。
      await repos.recurring.materializeDate(date);
      ref.invalidate(recurringMaterializeProvider);
      if (!mounted) {
        return;
      }
      navigator.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RecurringDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('recurring-dialog-title'),
            controller: _title,
            autofocus: true,
            enabled: !_submitting,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('标题（必填）'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text('星期', style: _bodyStyle(size: 12, color: AppTokens.meta)),
              const SizedBox(width: 8),
              Text(
                WeekdayMask.label(_mask),
                style: _bodyStyle(size: 11.5, color: AppTokens.faint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (var weekday = 1; weekday <= 7; weekday++)
                _WeekdayChip(
                  key: ValueKey<String>('recurring-dialog-weekday-$weekday'),
                  label: weekdayLabel(weekday),
                  selected: WeekdayMask.includes(_mask, weekday),
                  onTap: _submitting ? null : () => _toggleWeekday(weekday),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('recurring-dialog-time'),
                  controller: _time,
                  enabled: !_submitting,
                  style: _bodyStyle(size: 13, color: AppTokens.ink),
                  decoration: _fieldDecoration('开始 HH:mm'),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('recurring-dialog-duration'),
                  controller: _duration,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  style: _bodyStyle(size: 13, color: AppTokens.ink),
                  decoration: _fieldDecoration('时长（分钟）'),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('recurring-dialog-note'),
            controller: _note,
            enabled: !_submitting,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('备注（可选）'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            _DialogError(message: _error!),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _DialogButton(
                key: const ValueKey<String>('recurring-dialog-cancel'),
                label: '取消',
                dense: true,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              _DialogButton(
                key: const ValueKey<String>('recurring-dialog-save'),
                label: '保存',
                dense: true,
                primary: true,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 星期多选小片：选中用 `ink` 反白，未选用 `card` + `hair-strong` 边。
class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? AppTokens.ink : AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: selected ? AppTokens.ink : AppTokens.hairStrong,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: _bodyStyle(
                size: 11.5,
                color: selected
                    ? AppTokens.paper
                    : (enabled ? AppTokens.ink2 : AppTokens.faint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 账页风面板外壳：`paper` 底 + `hair` 边 + 4px 圆角 + 480 宽。
class _RecurringDialog extends StatelessWidget {
  const _RecurringDialog({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey<String>('recurring-task-dialog'),
      backgroundColor: AppTokens.paper,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: const BorderSide(color: AppTokens.hair, width: 1),
      ),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '添加循环任务',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.displayFallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppTokens.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '按星期与开始时刻，自动排进每一天的计划',
                style: _bodyStyle(size: 11.5, color: AppTokens.faint),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 面板内错误（`accentWash` 底 + `accent` 边，与右轨同 token）。
class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.accent, width: 1),
      ),
      child: Text(
        message,
        style: _bodyStyle(size: 12.5, color: AppTokens.accentInk),
      ),
    );
  }
}

/// 面板按钮：`card` 底 + `hair-strong` 边 + `ink2` 字；`primary` 用 `ink` 反白。
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color background;
    final Color foreground;
    if (!enabled) {
      background = AppTokens.sunken;
      foreground = AppTokens.faint;
    } else if (primary) {
      background = AppTokens.ink;
      foreground = AppTokens.paper;
    } else {
      background = AppTokens.card;
      foreground = AppTokens.ink2;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            constraints: BoxConstraints(minHeight: dense ? 22 : 28),
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 6 : 10,
              vertical: dense ? 2 : 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: primary && enabled
                    ? AppTokens.ink
                    : AppTokens.hairStrong,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: _bodyStyle(
                size: dense ? 11.5 : 12.5,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 仓储异常的统一提取：`ArgumentError` / `StateError` 取 `message` 原文。
String _errorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }
  if (error is ArgumentError) {
    return '${error.message}';
  }
  return '$error';
}

/// 输入框统一外观：4px 圆角 + `hair-strong` 边 + `card` 底。
InputDecoration _fieldDecoration(String hint) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: _bodyStyle(size: 13, color: AppTokens.faint),
    isDense: true,
    filled: true,
    fillColor: AppTokens.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(AppTokens.hairStrong),
    enabledBorder: border(AppTokens.hairStrong),
    focusedBorder: border(AppTokens.ink, width: 1.5),
  );
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