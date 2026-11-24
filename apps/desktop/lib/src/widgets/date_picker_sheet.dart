// apps/desktop/lib/src/widgets/date_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:core_data/core_data.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_scope.dart';
import '../theme/app_tokens.dart';
import 'chip_row.dart';

/// 全站唯一日期选择组件（spec §8.2）。
///
/// 任何页面**不得**自造日期选择控件。
class DatePickerSheet extends StatefulWidget {
  /// 创建日期选择弹层。
  const DatePickerSheet({
    super.key,
    required this.initial,
    this.weekStart = 1,
    this.allowNoDeadline = false,
  });

  /// 初始选中日期。
  final String initial;

  /// 每周首日（1 = 周一，7 = 周日）。
  final int weekStart;

  /// 是否显示「无期限」（仅 `todo.due_date` 用）。
  final bool allowNoDeadline;

  /// 以弹层方式打开；返回选中的日期，取消返回 null。
  static Future<String?> show(
    BuildContext context, {
    required String initial,
    int weekStart = 1,
    bool allowNoDeadline = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => DatePickerSheet(
        initial: initial,
        weekStart: weekStart,
        allowNoDeadline: allowNoDeadline,
      ),
    );
  }

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  /// 当前选中日期（`YYYY-MM-DD`）。
  String _selected = '';

  /// 当前显示的月份（`YYYY-MM`）。
  String _month = '';

  /// 最近一次点选的快捷芯片 key（空串 = 无）。
  String _activeChip = '';

  /// 是否选了「无期限」。
  bool _noDeadline = false;

  /// 月历网格的焦点节点（键盘可达的落点）。
  final FocusNode _gridFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _month = widget.initial.substring(0, 7);
  }

  void _shiftMonth(int delta) {
    setState(() {
      final parts = _month.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]) + delta;
      final shifted = DateTime(year, month, 1);
      _month = '${shifted.year.toString().padLeft(4, '0')}-'
          '${shifted.month.toString().padLeft(2, '0')}';
      _activeChip = '';
    });
  }

  /// 当月最后一天（`YYYY-MM-DD`）。
  String _monthLastDay() {
    final parts = _month.split('-');
    final last = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0);
    return '$_month-${last.day.toString().padLeft(2, '0')}';
  }

  /// 本周最后一天（按 `weekStart` 口径；`weekStart = 1` 时即本周日）。
  String _weekEnd(String todayIso) {
    final parsed = parseIsoDate(todayIso);
    if (parsed == null) {
      return todayIso;
    }
    final offset = (widget.weekStart - 1 + 7 - parsed.weekday) % 7;
    return shiftIsoDate(todayIso, offset);
  }

  /// 选中某个日期（并复位快捷芯片 / 无期限态）。
  void _selectDate(String date) {
    setState(() {
      _selected = date;
      _activeChip = '';
      _noDeadline = false;
    });
  }

  /// 方向键在**当月网格内**移动选中日（边界钳制，不跨月）。
  void _moveSelection(int delta) {
    final moved = shiftIsoDate(_selected, delta);
    final first = '$_month-01';
    final last = _monthLastDay();
    if (moved.compareTo(first) < 0) {
      _selectDate(first);
      return;
    }
    if (moved.compareTo(last) > 0) {
      _selectDate(last);
      return;
    }
    _selectDate(moved);
  }

  /// 确认并关闭弹层；「无期限」时返回 null。
  void _commit() {
    Navigator.of(context).pop(_noDeadline ? null : _selected);
  }

  /// 网格键盘事件：方向键移动选中日，`Enter` 确认。
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commit();
      return KeyEventResult.handled;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => 0,
    };
    if (delta == 0) {
      return KeyEventResult.ignored;
    }
    _moveSelection(delta);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _gridFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLocalizations l10n = _l10nOf(context);
    final todayIso = today();
    final grid =
        buildMonthGrid(_month, today: todayIso, weekStart: widget.weekStart);

    return AlertDialog(
      // Task 61 补轮：英文态的芯片更长（实测芯片条 302×98，中文态 279.1×30）
      // ⇒ 内容列自然高 432.6px，超过弹层给内容的 368px 上限 ⇒ 纵向溢出 65px。
      // 口径：**内容自带滚动视图**（标题与动作按钮条留在原地），
      // 不砍英文文案、不砍芯片、不砍月历网格。
      // 中文态内容自然高 364.6px < 368px ⇒ 视口高度 = 内容自然高 ⇒ 不滚动
      // ⇒ 中文态布局与改前逐像素一致。
      //
      // 为什么不用框架自带的 `AlertDialog(scrollable: true)`：它把标题与内容
      // 一起塞进 `SingleChildScrollView`，弹层外层的 `IntrinsicWidth` 会向下
      // 问视口的固有尺寸 ⇒ 本 SDK 触发
      // `RenderShrinkWrappingViewport does not support returning intrinsic
      // dimensions.`。这里的滚动视图被**定宽的 `SizedBox`** 包住 ⇒ 固有宽度
      // 计算在 `SizedBox` 处短路（`RenderConstrainedBox` 遇 tight width 直接
      // 返回 `minWidth`、不再问子节点）⇒ 不会问视口 ⇒ 不触发该断言。
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.calendarPickerPrevMonth,
            onPressed: () => _shiftMonth(-1),
          ),
          Expanded(
            child: Text(
              l10n.calendarMonthLabel(_month),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.calendarPickerNextMonth,
            onPressed: () => _shiftMonth(1),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChipRow(
                options: <ChipOption>[
                  ChipOption(key: 'today', label: l10n.calendarToday),
                  ChipOption(key: 'yesterday', label: l10n.calendarYesterday),
                  ChipOption(
                    key: 'before',
                    label: l10n.calendarDayBeforeYesterday,
                  ),
                  ChipOption(key: 'tomorrow', label: l10n.calendarTomorrow),
                  ChipOption(key: 'week', label: l10n.calendarThisWeek),
                  if (widget.allowNoDeadline)
                    ChipOption(key: 'none', label: l10n.calendarNoDeadline),
                ],
                selected: <String>{if (_activeChip.isNotEmpty) _activeChip},
                onChanged: (next) {
                  if (next.isEmpty) {
                    return;
                  }
                  final key = next.first;
                  setState(() {
                    _activeChip = key;
                    _noDeadline = key == 'none';
                    _selected = switch (key) {
                      'today' => todayIso,
                      'yesterday' => shiftIsoDate(todayIso, -1),
                      'before' => shiftIsoDate(todayIso, -2),
                      'tomorrow' => shiftIsoDate(todayIso, 1),
                      'week' => _weekEnd(todayIso),
                      _ => _selected,
                    };
                  });
                },
              ),
              const SizedBox(height: 10),
              Shortcuts(
                shortcuts: <ShortcutActivator, Intent>{
                  const SingleActivator(LogicalKeyboardKey.pageUp):
                      const _MonthIntent(-1),
                  const SingleActivator(LogicalKeyboardKey.pageDown):
                      const _MonthIntent(1),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _MonthIntent: _MonthAction(onInvoke: _shiftMonth),
                  },
                  child: Focus(
                    focusNode: _gridFocus,
                    autofocus: true,
                    onKeyEvent: _handleKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            for (final label in l10n.calendarWeekdaysShort)
                              Expanded(
                                child: Center(
                                  child: Text(label, style: theme.textTheme.labelSmall),
                                ),
                              ),
                          ],
                        ),
                        GridView.count(
                          key: const ValueKey('month-grid'),
                          crossAxisCount: 7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final cell in grid)
                              _DayCell(
                                key: ValueKey('day-${cell.date}'),
                                cell: cell,
                                selected: cell.date == _selected,
                                onTap: () => _selectDate(cell.date),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _commit,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

/// 取当前语言的文案表。
///
/// 既有测试（`test\date_picker_sheet_test.dart`）直接在本控件外面套一个
/// `MaterialApp`、**不套** `L10nScope` ⇒ 硬取会抛 FlutterError 打挂既有测试。
/// 口径与 `widgets\shell\app_top_bar.dart` 一致：取不到 scope 时回落中文态。
AppLocalizations _l10nOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<L10nScope>()?.localizations ??
    AppLocalizations.zh;

class _MonthIntent extends Intent {
  const _MonthIntent(this.delta);

  final int delta;
}

class _MonthAction extends Action<_MonthIntent> {
  _MonthAction({required this.onInvoke});

  final void Function(int delta) onInvoke;

  @override
  Object? invoke(_MonthIntent intent) {
    onInvoke(intent.delta);
    return null;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final CalendarCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: selected
                ? t.ink
                : cell.isToday
                ? t.ink
                : cell.inMonth
                ? t.hairStrong
                : t.hair,
            width: selected || cell.isToday ? 2 : 1,
          ),
          color: selected ? t.inkWash : null,
        ),
        child: Text(
          cell.date.substring(8),
          style: theme.textTheme.labelLarge?.copyWith(
            color: cell.inMonth
                ? (cell.isWeekend ? t.accentInk : t.ink)
                : t.faint,
          ),
        ),
      ),
    );
  }
}