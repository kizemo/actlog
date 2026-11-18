import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 打开「添加习惯」面板（右轨「习惯速览」右上角那枚 `＋`）。
///
/// 面板挂在 `showDialog` 上：`Esc` 与点遮罩关闭都由 `ModalRoute` 默认提供。
Future<void> showHabitQuickDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const HabitQuickDialog(),
  );
}

/// 排程四选一：只决定写进 `habit` 表的 `schedule_type` / `weekly_n` / `weekdays`。
///
/// 刻意**不**扩充 `HabitScheduleType`（`enums.dart` 的枚举与 `habit` 表的
/// CHECK 是双向对齐且已冻结），四选一在这里折叠成三个既有列的取值组合。
enum _ScheduleKind {
  /// 每天：`daily` + `weekly_n` 空。
  daily,

  /// 每隔 N 天：`daily` + `weekly_n = N`（N ≥ 2）。
  everyNDays,

  /// 每隔 N 周：`weekly_n` + `weekly_n = N` + `weekdays` 非空。
  everyNWeeks,

  /// 每周指定几天：`weekdays` + `weekdays` 非空。
  weekdays,
}

/// 「添加习惯」面板：新建一条习惯，并同时定义它的性质。
///
/// 可定义的性质共四项：排程（每天 / 每隔 N 天 / 每隔 N 周 / 每周指定几天）、
/// 每日至少完成几次、起始日期。间隔型排程保存成功后立即把未来 14 天内每个
/// 命中日写进日计划（`plan_item`，`source_type='habit'`）。
class HabitQuickDialog extends ConsumerStatefulWidget {
  /// 创建「添加习惯」面板。
  const HabitQuickDialog({super.key});

  @override
  ConsumerState<HabitQuickDialog> createState() => _HabitQuickDialogState();
}

class _HabitQuickDialogState extends ConsumerState<HabitQuickDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();

  /// 当前排程选项，默认「每天」—— 与扩展前写库的结果完全一致。
  _ScheduleKind _kind = _ScheduleKind.daily;

  /// 「每隔 N」里的 N：每隔 N 天取 2..7，每隔 N 周取 1..7（表 CHECK 是 1..7）。
  int _interval = 2;

  /// 「每周指定几天」/「每隔 N 周」选中的星期（1=周一 … 7=周日）。
  final Set<int> _weekdays = <int>{};

  /// 是否启用「每日至少完成 N 次」（`type='count'` + `target_count`）。
  bool _countEnabled = false;

  /// 每日至少几次：1..20，写入时转成 `target_count`。
  int _targetCount = 3;

  /// 起始日期（`YYYY-MM-DD`），默认今天。
  late String _startDate;

  /// 提交中禁用按钮，防止连点写出两条习惯。
  bool _submitting = false;

  /// 面板内错误原文（不写库、不关面板）。
  String? _error;

  /// 当前排程是否需要选星期。
  bool get _needsWeekdays =>
      _kind == _ScheduleKind.everyNWeeks || _kind == _ScheduleKind.weekdays;

  @override
  void initState() {
    super.initState();
    // 起始日期默认今天：时钟只在 provider 里读一次，面板内不再碰 `DateTime.now`。
    _startDate = ref.read(todayProvider);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// 切换排程：顺带把 N 与星期的取值夹回合法区间/补一个默认星期。
  void _selectKind(_ScheduleKind kind) {
    setState(() {
      _kind = kind;
      if (kind == _ScheduleKind.everyNDays && _interval < 2) {
        _interval = 2;
      }
      if (_needsWeekdays && _weekdays.isEmpty) {
        // 默认选中起始日期所在星期，避免一切过去就卡在必填校验上。
        final DateTime? start = parseIsoDate(_startDate);
        _weekdays.add(start?.weekday ?? DateTime.monday);
      }
    });
  }

  /// 选起始日期：走 Material 日期选择器，落库仍是 `YYYY-MM-DD`。
  Future<void> _pickStartDate() async {
    final DateTime? initial = parseIsoDate(_startDate);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _startDate = isoDate(picked));
  }

  /// 把四选一折叠成 `habit` 表的三个排程列取值。
  ({String scheduleType, int? weeklyN, String weekdays}) _resolveSchedule() {
    switch (_kind) {
      case _ScheduleKind.daily:
        return (scheduleType: 'daily', weeklyN: null, weekdays: '');
      case _ScheduleKind.everyNDays:
        return (scheduleType: 'daily', weeklyN: _interval, weekdays: '');
      case _ScheduleKind.everyNWeeks:
        return (
          scheduleType: 'weekly_n',
          weeklyN: _interval,
          weekdays: _weekdayCsv(),
        );
      case _ScheduleKind.weekdays:
        return (
          scheduleType: 'weekdays',
          weeklyN: null,
          weekdays: _weekdayCsv(),
        );
    }
  }

  /// `weekdays` 列的写入格式：升序、逗号分隔，例如 '1,3,5'。
  String _weekdayCsv() {
    final List<int> sorted = _weekdays.toList()..sort();
    return sorted.join(',');
  }

  /// 成功关窗后置位的一次性终态标志。
  ///
  /// 弹层退出动画期间 `_ModalScope` 尚未重建，两个 TextField 的
  /// `onSubmitted: (_) => _submit()` 仍然可调；若 `finally` 在此无条件复位
  /// `_submitting`，退窗口内到达的第二次回车会再写一条习惯（指令 3 的
  /// 「加一次出两条」）。只在成功路径置位 ⇒ 失败路径仍可改完再提交。
  bool _done = false;

  Future<void> _submit() async {
    if (_submitting || _done) {
      return;
    }
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '习惯名不能为空');
      return;
    }
    if (_needsWeekdays && _weekdays.isEmpty) {
      setState(() => _error = '请至少选择一个星期');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    // 先取好 navigator / messenger / 时钟值与表单快照：await 之后 `context`
    // 不能再直接用于导航（异步安全规则），`ref.read` 也只在这里读一次。
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    final String todayDate = ref.read(todayProvider);
    final String startDate = _startDate;
    final bool counts = _countEnabled;
    final int target = _targetCount;
    final ({String scheduleType, int? weeklyN, String weekdays}) schedule =
        _resolveSchedule();
    try {
      final repos = ref.read(repositoriesProvider);
      final String habitId = await repos.habit.create(
        name: name,
        description: _description.text.trim(),
        type: counts ? 'count' : 'normal',
        targetCount: counts ? target.toDouble() : null,
        targetUnit: counts ? '次' : '',
        scheduleType: schedule.scheduleType,
        weeklyN: schedule.weeklyN,
        weekdays: schedule.weekdays,
        startDate: startDate,
      );
      // 习惯速览（`FutureProvider`）、勾选状态（`StreamProvider`）与月历
      // （`FutureProvider.family`）都不会被这次写入触发，必须显式失效；
      // 「今日计划」是 `StreamProvider`，plan_item 插入后自己回流。 
      ref.invalidate(habitsForTodayProvider);
      ref.invalidate(habitCheckinsProvider);
      ref.invalidate(calendarMonthProvider);

      String? warning;
      try {
        await repos.habit.materializeUpcoming(
          habitId: habitId,
          fromDate: todayDate,
        );
      } catch (error) {
        // 习惯本身已经落库，不能因为「自动进计划」失败就把它吞掉：
        // 关面板后用 SnackBar 如实告知，让用户能自己去补。
        warning = '习惯已保存，但未能自动加入日计划：${_errorMessage(error)}';
      }
      if (!mounted) {
        return;
      }
      // 落库已成功：pop 之前先锁死入口，退出动画窗口内再来的提交一律忽略。
      _done = true;
      navigator.pop();
      if (warning != null) {
        messenger?.showSnackBar(SnackBar(content: Text(warning)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _errorMessage(error));
    } finally {
      // 只有异常路径才放开门闩（保留重试）；成功路径保持 `_submitting = true`，
      // 与 `_done` 一起挡住退窗口内的重复提交。
      if (!_done && mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HabitDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('habit-dialog-name'),
            controller: _name,
            autofocus: true,
            enabled: !_submitting,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('习惯名（必填）'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('habit-dialog-description'),
            controller: _description,
            enabled: !_submitting,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('说明（可选）'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          _scheduleSection(),
          if (_kind == _ScheduleKind.everyNDays ||
              _kind == _ScheduleKind.everyNWeeks) ...<Widget>[
            const SizedBox(height: 8),
            _intervalRow(),
          ],
          if (_needsWeekdays) ...<Widget>[
            const SizedBox(height: 8),
            _weekdayRow(),
          ],
          const SizedBox(height: 10),
          _startDateRow(),
          const SizedBox(height: 6),
          _targetCountRow(),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            _DialogError(message: _error!),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _DialogButton(
                label: '取消',
                dense: true,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              _DialogButton(
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

  /// 排程四选一（`Wrap` 保证 200% 文字缩放时换行而不是溢出）。
  Widget _scheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionLabel('排程'),
        const SizedBox(height: 5),
        Wrap(
          key: const ValueKey<String>('habit-dialog-schedule'),
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _ChoiceTile(
              key: const ValueKey<String>('habit-dialog-schedule-daily'),
              label: '每天',
              selected: _kind == _ScheduleKind.daily,
              onTap: _submitting ? null : () => _selectKind(_ScheduleKind.daily),
            ),
            _ChoiceTile(
              key: const ValueKey<String>('habit-dialog-schedule-every-days'),
              label: '每隔 N 天',
              selected: _kind == _ScheduleKind.everyNDays,
              onTap:
                  _submitting ? null : () => _selectKind(_ScheduleKind.everyNDays),
            ),
            _ChoiceTile(
              key: const ValueKey<String>('habit-dialog-schedule-every-weeks'),
              label: '每隔 N 周',
              selected: _kind == _ScheduleKind.everyNWeeks,
              onTap: _submitting
                  ? null
                  : () => _selectKind(_ScheduleKind.everyNWeeks),
            ),
            _ChoiceTile(
              key: const ValueKey<String>('habit-dialog-schedule-weekdays'),
              label: '每周指定几天',
              selected: _kind == _ScheduleKind.weekdays,
              onTap:
                  _submitting ? null : () => _selectKind(_ScheduleKind.weekdays),
            ),
          ],
        ),
      ],
    );
  }

  /// 「每隔 N 天 / 每隔 N 周」的步进行。
  Widget _intervalRow() {
    final bool weekly = _kind == _ScheduleKind.everyNWeeks;
    final int min = weekly ? 1 : 2;
    final int max = 7;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        Text('每隔', style: _bodyStyle(size: 11.5, color: AppTokens.faint)),
        _StepButton(
          key: const ValueKey<String>('habit-dialog-interval-minus'),
          label: '−',
          onPressed: _submitting || _interval <= min
              ? null
              : () => setState(() => _interval--),
        ),
        Text(
          '$_interval',
          key: const ValueKey<String>('habit-dialog-interval'),
          style: _bodyStyle(size: 12.5, color: AppTokens.ink),
        ),
        _StepButton(
          key: const ValueKey<String>('habit-dialog-interval-plus'),
          label: '＋',
          onPressed: _submitting || _interval >= max
              ? null
              : () => setState(() => _interval++),
        ),
        Text(
          weekly ? '周' : '天',
          style: _bodyStyle(size: 11.5, color: AppTokens.faint),
        ),
      ],
    );
  }

  /// 星期多选（1=周一 … 7=周日）。
  Widget _weekdayRow() {
    const List<String> labels = <String>['一', '二', '三', '四', '五', '六', '日'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionLabel('星期'),
        const SizedBox(height: 5),
        Wrap(
          key: const ValueKey<String>('habit-dialog-weekdays'),
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (var day = 1; day <= 7; day++)
              _ChoiceTile(
                key: ValueKey<String>('habit-dialog-weekday-$day'),
                label: '周${labels[day - 1]}',
                selected: _weekdays.contains(day),
                onTap: _submitting
                    ? null
                    : () => setState(() {
                          if (!_weekdays.remove(day)) {
                            _weekdays.add(day);
                          }
                        }),
              ),
          ],
        ),
      ],
    );
  }

  /// 起始日期行：显示当前值，点开日期选择器。
  Widget _startDateRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        const _SectionLabel('起始日期'),
        _ChoiceTile(
          key: const ValueKey<String>('habit-dialog-start-date'),
          label: _startDate,
          selected: false,
          onTap: _submitting ? null : _pickStartDate,
        ),
      ],
    );
  }

  /// 「每日至少完成 N 次」：勾上即写 `type='count'` + `target_count` + 单位「次」。
  Widget _targetCountRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Checkbox(
              key: const ValueKey<String>('habit-dialog-target-count-toggle'),
              value: _countEnabled,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: _submitting
                  ? null
                  : (bool? value) =>
                      setState(() => _countEnabled = value ?? false),
            ),
            const _SectionLabel('每日至少完成'),
          ],
        ),
        if (_countEnabled) ...<Widget>[
          _StepButton(
            key: const ValueKey<String>('habit-dialog-target-count-minus'),
            label: '−',
            onPressed: _submitting || _targetCount <= 1
                ? null
                : () => setState(() => _targetCount--),
          ),
          Text(
            '$_targetCount',
            key: const ValueKey<String>('habit-dialog-target-count'),
            style: _bodyStyle(size: 12.5, color: AppTokens.ink),
          ),
          _StepButton(
            key: const ValueKey<String>('habit-dialog-target-count-plus'),
            label: '＋',
            onPressed: _submitting || _targetCount >= 20
                ? null
                : () => setState(() => _targetCount++),
          ),
          Text('次', style: _bodyStyle(size: 11.5, color: AppTokens.faint)),
        ],
      ],
    );
  }
}

/// 账页风的面板外壳：`paper` 底 + `hair` 边 + 4px 圆角 + 480 宽。
///
/// 外观与「手写一条」的 `_LedgerDialog` 一致（那是私有类，这里按同样规格
/// 复刻一份，避免把两个弹窗耦合成一个）。
///
/// 正文放在 `Flexible` + `SingleChildScrollView` 里：字段变多后，200% 文字
/// 缩放只会让内容滚动，不会撑破面板（与 `AlertDialog` 同一套布局策略）。
class _HabitDialog extends StatelessWidget {
  const _HabitDialog({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey<String>('habit-quick-dialog'),
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
                '添加习惯',
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
                '定义排程与目标，间隔型习惯保存后自动进入未来 14 天日计划',
                style: _bodyStyle(size: 11.5, color: AppTokens.faint),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 面板内的小节标题（`faint` 小字）。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _bodyStyle(size: 11, color: AppTokens.faint));
  }
}

/// 可选中的方片（排程选项 / 星期 / 日期都复用它）。
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color background = selected ? AppTokens.ink : AppTokens.card;
    final Color foreground = selected
        ? AppTokens.paper
        : (enabled ? AppTokens.ink2 : AppTokens.faint);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Material(
          color: background,
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
                style: _bodyStyle(size: 11.5, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 步进按钮（`−` / `＋`）：禁用态用 `sunken` 底 + `faint` 字。
class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Material(
          color: enabled ? AppTokens.card : AppTokens.sunken,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: AppTokens.hairStrong, width: 1),
              ),
              child: Text(
                label,
                style: _bodyStyle(
                  size: 12.5,
                  color: enabled ? AppTokens.ink : AppTokens.faint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 面板内错误（`accentWash` 底 + `accent` 边，与待办池页的横幅同 token）。
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
class _DialogButton extends StatefulWidget {
  const _DialogButton({
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
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final Color background;
    final Color foreground;
    if (!enabled) {
      background = AppTokens.sunken;
      foreground = AppTokens.faint;
    } else if (widget.primary) {
      background = _hovered ? AppTokens.ink2 : AppTokens.ink;
      foreground = AppTokens.paper;
    } else {
      background = _hovered ? AppTokens.sunken : AppTokens.card;
      foreground = _hovered ? AppTokens.ink : AppTokens.ink2;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              constraints: BoxConstraints(minHeight: widget.dense ? 22 : 28),
              padding: EdgeInsets.symmetric(
                horizontal: widget.dense ? 6 : 10,
                vertical: widget.dense ? 2 : 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: widget.primary && enabled
                      ? AppTokens.ink
                      : AppTokens.hairStrong,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: _bodyStyle(
                  size: widget.dense ? 11.5 : 12.5,
                  color: foreground,
                ),
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
