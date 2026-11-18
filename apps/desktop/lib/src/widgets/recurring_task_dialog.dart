// `core_data` 与 `core_domain` 都导出 `weekdayLabel`：前者收日期字符串，
// 后者收星期序号。本文件用的是**星期序号**那一版，故把前者隐藏掉。
import 'package:core_data/core_data.dart' hide weekdayLabel;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_recurring.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 时间轴纵轴的下界（06:00）。
///
/// 方格时间轴的口径是 06:00–24:00（`docs/superpowers/plans/2026-11-12-b2-grid-timeline.md`），
/// 早于 06:00 的条目即使物化成功也会被网格夹掉、看不见。网格负责在 W2 的
/// `packages/core_data/lib/src/repositories.dart` 里，本文件不得改它，
/// 因此把限制落在对话框侧：输入先夹到边界，并告知用户实际落位时刻。
const int _timelineFirstMinute = 6 * 60;

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
/// 字段：`标题`（必填）、`星期`（多选，默认「工作日 ∪ 创建日所在星期」）、
/// `开始`（`HH:mm`，默认 09:00，不早于 06:00）、`时长`（分钟，默认 30）、
/// `备注`（可选）。
/// 保存后**立刻物化当天**，所以今天的计划里会马上出现这一条。
///
/// 需要纠正用户输入时（掩码不含创建日所在星期、时刻早于 06:00）走
/// **先提示 + 二次确认**：第一次点保存只把纠正结果落到界面并显示提示，按钮
/// 变成「确认保存」，再点一次才写库 —— 不静默改写用户的选择。
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

  /// 星期掩码；bit0 = 周一 … bit6 = 周日。默认值见 [initState]。
  int _mask = WeekdayMask.workdays;

  /// 提交中禁用按钮，防止连点写出两条规则。
  bool _submitting = false;

  /// 面板内错误原文（不写库、不关面板）。
  String? _error;

  /// 需要用户**再点一次**确认的改写提示（null = 无需确认）。
  ///
  /// 只在两种纠正场景出现：掩码不含创建日所在星期、开始时刻早于 06:00。
  String? _notice;

  @override
  void initState() {
    super.initState();
    // 默认掩码 = 工作日 ∪ {创建日所在星期}：让「今天就出现在计划里」是
    // 默认结果，而不是保存完才发现当天什么都没发生。
    final DateTime? createdOn = parseIsoDate(ref.read(selectedDateProvider));
    if (createdOn != null) {
      _mask = WeekdayMask.workdays | WeekdayMask.bitOf(createdOn.weekday);
    }
  }

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
      // 用户改了选择 ⇒ 之前的改写提示作废，下一次提交重新判断。
      _notice = null;
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
    final int? parsedStart = parseMinuteOfDay(_time.text);
    if (parsedStart == null) {
      setState(() => _error = '开始时刻要写成 HH:mm（例如 09:00）');
      return;
    }
    final int? duration = int.tryParse(_duration.text.trim());
    if (duration == null || duration <= 0 || duration > minutesPerDay) {
      setState(() => _error = '时长必须是 1..1440 之间的整数（分钟）');
      return;
    }

    final String date = ref.read(selectedDateProvider);
    final DateTime? createdOn = parseIsoDate(date);
    if (createdOn == null) {
      setState(() => _error = '选中日不是合法日历日：$date');
      return;
    }

    // 纠正 1 —— 掩码不含创建日所在星期：并入。物化闸门是
    // `WeekdayMask.includes(...)`，不命中就静默 `continue`，用户看到的就是
    // 「设了也不进计划」。
    final List<String> notices = <String>[];
    var mask = _mask;
    if (!WeekdayMask.includes(mask, createdOn.weekday)) {
      mask |= WeekdayMask.bitOf(createdOn.weekday);
      notices.add(
        '已把 ${weekdayLabel(createdOn.weekday)} 并入重复日，'
        '以便今天就出现在计划里',
      );
    }
    // 纠正 2 —— 时刻早于 06:00：网格只画 06:00–24:00，夹到下界。
    var startMinute = parsedStart;
    if (startMinute < _timelineFirstMinute) {
      startMinute = _timelineFirstMinute;
      notices.add(
        '开始时刻早于 ${formatMinuteOfDay(_timelineFirstMinute)}，'
        '已改到 ${formatMinuteOfDay(startMinute)}（时间轴只显示 06:00 之后）',
      );
    }

    if (notices.isNotEmpty && _notice == null) {
      // 先提示、不写库：把纠正结果落到界面，等用户再点一次「确认保存」。
      setState(() {
        _mask = mask;
        _time.text = formatMinuteOfDay(startMinute);
        _notice = notices.join('\n');
        _error = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });
    // await 之后 `context` 不能再直接用于导航；`ref.read` 也只在 await 前读一次。
    final NavigatorState navigator = Navigator.of(context);
    try {
      final repos = ref.read(repositoriesProvider);
      await repos.recurring.create(
        title: title,
        weekdayMask: mask,
        startMinute: startMinute,
        durationMinutes: duration,
        note: _note.text.trim(),
      );
      // 立刻物化「当前选中日」：上面已保证掩码含创建日 ⇒ 今天必出条目（幂等）。
      await repos.recurring.materializeDate(date);
      // 规则段的 provider 必须失效，否则新规则不会出现在列表里。
      ref.invalidate(recurringRulesProvider);
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
    final t = context.tokens;
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
            style: _bodyStyle(size: 13, color: t.ink),
            decoration: _fieldDecoration('标题（必填）', t),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text('星期', style: _bodyStyle(size: 12, color: t.meta)),
              const SizedBox(width: 8),
              Text(
                WeekdayMask.label(_mask),
                style: _bodyStyle(size: 11.5, color: t.faint),
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
                  style: _bodyStyle(size: 13, color: t.ink),
                  decoration: _fieldDecoration('开始 HH:mm（06:00 起）', t),
                  // 用户改过时刻 ⇒ 之前的改写提示作废，下一次提交重新判断。
                  onChanged: (_) {
                    if (_notice != null) {
                      setState(() => _notice = null);
                    }
                  },
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
                  style: _bodyStyle(size: 13, color: t.ink),
                  decoration: _fieldDecoration('时长（分钟）', t),
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
            style: _bodyStyle(size: 13, color: t.ink),
            decoration: _fieldDecoration('备注（可选）', t),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            _DialogError(message: _error!),
          ],
          if (_notice != null) ...<Widget>[
            const SizedBox(height: 10),
            _DialogNotice(key: const ValueKey<String>('recurring-dialog-notice'), message: _notice!),
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
                label: _notice == null ? '保存' : '确认保存',
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
    final t = context.tokens;
    final bool enabled = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? t.ink : t.card,
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
                color: selected ? t.ink : t.hairStrong,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: _bodyStyle(
                size: 11.5,
                color: selected
                    ? t.paper
                    : (enabled ? t.ink2 : t.faint),
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
    final t = context.tokens;
    return Dialog(
      key: const ValueKey<String>('recurring-task-dialog'),
      backgroundColor: t.paper,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: t.hair, width: 1),
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
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '按星期与开始时刻，自动排进每一天的计划',
                style: _bodyStyle(size: 11.5, color: t.faint),
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
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.accent, width: 1),
      ),
      child: Text(
        message,
        style: _bodyStyle(size: 12.5, color: t.accentInk),
      ),
    );
  }
}

/// 面板内「已为你纠正」的提示（`sunken` 底 + `hair` 边 + `ink2` 字）。
///
/// 与 [_DialogError] 分开：这是**说明**，不是失败 —— 纠正结果先显示出来，
/// 用户再点一次「确认保存」才写库。
class _DialogNotice extends StatelessWidget {
  const _DialogNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.sunken,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.hair, width: 1),
      ),
      child: Text(
        message,
        style: _bodyStyle(size: 12, color: t.ink2),
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
    final t = context.tokens;
    final bool enabled = onPressed != null;
    final Color background;
    final Color foreground;
    if (!enabled) {
      background = t.sunken;
      foreground = t.faint;
    } else if (primary) {
      background = t.ink;
      foreground = t.paper;
    } else {
      background = t.card;
      foreground = t.ink2;
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
                    ? t.ink
                    : t.hairStrong,
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
InputDecoration _fieldDecoration(String hint, ThemeTokens tokens) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: _bodyStyle(size: 13, color: tokens.faint),
    isDense: true,
    filled: true,
    fillColor: tokens.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(tokens.hairStrong),
    enabledBorder: border(tokens.hairStrong),
    focusedBorder: border(tokens.ink, width: 1.5),
  );
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({double size = 12.5, required Color color}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
  );
}