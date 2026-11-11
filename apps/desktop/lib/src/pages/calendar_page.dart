import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/calendar_month_view.dart';
import '../widgets/date_bar.dart';

/// 日历页：进入任意一天的唯一入口（B 版「墨径 · 账页流」）。
///
/// 今日页只能 `←` / `→` 一天天挪，跨到上个月或下周要按几十次。本页把
/// [CalendarMonthView] 铺进账页，用户点哪一天就切到哪一天：过去日进补录
/// 模式、未来日进预排模式，判定统一交给 [DateBar] 与今日页（spec §13.3）。
///
/// 与今日页一样，本页**不自建壳**：`Scaffold` / `AppBar` 由 `LedgerShell`
/// 承担。因此「点完一天之后回哪儿」不能靠 `Navigator.pop`，需要调用方
/// 通过 [onDayPicked] 指路；路由模式下（深链 / 单测）仍然回退到 `pop`。
class CalendarPage extends ConsumerStatefulWidget {
  /// 创建日历页。
  const CalendarPage({super.key, this.onDayPicked});

  /// 选中一天后的回调（壳内切页用）。
  ///
  /// 传 null 表示调用方自己负责后续跳转；此时若本页在可弹栈的路由里，
  /// 仍旧 `pop` 回上一页，保持旧的「日历 → 今日」行为不变。
  final VoidCallback? onDayPicked;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  /// 当前展示的月份（`yyyy-MM`）。
  ///
  /// 初值取选中日所在月，而不是今天所在月 —— 用户翻到别的月份再进日历，
  /// 打开时应停在正在看的那个月。
  late String _month;

  @override
  void initState() {
    super.initState();
    _month = ref.read(selectedDateProvider).substring(0, 7);
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final summary = ref.watch(calendarMonthProvider(_month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const DateBar(),
        const SizedBox(height: AppTokens.gapCard),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '日历',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontFamilyFallback: AppFonts.displayFallback,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _month,
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 11.5,
                      color: AppTokens.faint,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.gapCard),
            _MonthButton(
              key: const ValueKey<String>('calendar-prev-month'),
              tooltip: '上个月',
              glyph: '‹',
              onPressed: () => _shiftMonth(-1),
            ),
            const SizedBox(width: 6),
            _MonthButton(
              key: const ValueKey<String>('calendar-next-month'),
              tooltip: '下个月',
              glyph: '›',
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.gapCard),
        summary.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SelectableText(
              '$error',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontFamilyFallback: AppFonts.bodyFallback,
                fontSize: 12.5,
                color: AppTokens.accentInk,
              ),
            ),
          ),
          data: (data) => CalendarMonthView(
            month: _month,
            days: data.days,
            today: today,
            onPickDay: _pickDay,
          ),
        ),
      ],
    );
  }

  /// 翻月：交给 `DateTime` 归一化，12 月 +1 自动落到次年 1 月。
  void _shiftMonth(int delta) {
    final first = DateTime.parse('$_month-01');
    final next = isoDate(DateTime(first.year, first.month + delta, 1));
    setState(() => _month = next.substring(0, 7));
  }

  /// 选中一天：写回 [selectedDateProvider]，再交给调用方。
  ///
  /// 顺序不能反：先写 provider，回调里读到的就已经是新日期。
  /// 壳内（[CalendarPage.onDayPicked] 非空）靠回调切回今日页；没有回调时
  /// 才尝试 `pop` —— 本页被单独挂成根路由时 `pop` 会断言失败，而切日本身
  /// 已经生效，没必要连界面一起炸掉（`canPop` 兜这一层）。
  void _pickDay(String date) {
    ref.read(selectedDateProvider.notifier).state = date;
    final callback = widget.onDayPicked;
    if (callback != null) {
      callback();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

/// 翻月按钮（替换 `IconButton` 的默认视觉）。
///
/// `card` 底 + `hair-strong` 边（可交互边界）+ `ink2` 字；hover 只换底与字色。
/// `tooltip` 与 `key` 全部保留：`calendar-prev-month` / `calendar-next-month`
/// 是既有测试的锚点。
class _MonthButton extends StatefulWidget {
  const _MonthButton({
    super.key,
    required this.tooltip,
    required this.glyph,
    required this.onPressed,
  });

  final String tooltip;
  final String glyph;
  final VoidCallback onPressed;

  @override
  State<_MonthButton> createState() => _MonthButtonState();
}

class _MonthButtonState extends State<_MonthButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: _hovered ? AppTokens.sunken : AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: Container(
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: AppTokens.hairStrong, width: 1),
                ),
                child: Text(
                  widget.glyph,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 15,
                    height: 1,
                    color: _hovered ? AppTokens.ink : AppTokens.ink2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}