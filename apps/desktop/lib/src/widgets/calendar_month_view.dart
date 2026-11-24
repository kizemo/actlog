import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_scope.dart';
import '../theme/app_tokens.dart';

/// 月历网格（spec §8.1）。
///
/// 每格三层信息：完成度底色 · 打卡热力点 · 心态迷你条 + 形状徽标。
class CalendarMonthView extends StatelessWidget {
  /// 创建月历。
  const CalendarMonthView({
    super.key,
    required this.month,
    required this.days,
    this.today,
    this.onPickDay,
  });

  /// 月份 `YYYY-MM`。
  final String month;

  /// 逐日摘要。
  final List<CalendarDaySummary> days;

  /// 今天（用于描边）。
  final String? today;

  /// 点某天的回调。
  final void Function(String date)? onPickDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLocalizations l10n = _l10nOf(context);
    final byDate = <String, CalendarDaySummary>{
      for (final day in days) day.date: day,
    };
    final grid = buildMonthGrid(month, today: today ?? '');
    final pick = onPickDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.calendarMonthLabel(month), style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
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
          mainAxisExtent: 52,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final cell in grid)
              _DayCell(
                key: ValueKey('day-${cell.date}'),
                cell: cell,
                summary: byDate[cell.date],
                onTap: pick == null ? null : () => pick(cell.date),
              ),
          ],
        ),
      ],
    );
  }
}

/// 取当前语言的文案表。
///
/// 既有测试（`test\calendar_month_view_test.dart`）直接在本控件外面套一个
/// `MaterialApp`、**不套** `L10nScope` ⇒ 硬取会抛 FlutterError 打挂既有测试。
/// 口径与 `widgets\shell\app_top_bar.dart` 一致：取不到 scope 时回落中文态。
AppLocalizations _l10nOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<L10nScope>()?.localizations ??
    AppLocalizations.zh;

/// 日号（不补零）：`2026-11-07` → `7`。
String _dayNumber(String date) {
  final parsed = parseIsoDate(date);
  return parsed == null ? date : parsed.day.toString();
}

/// 单日格：今天与周末各走一条**互不抢**的通道。
///
/// - **今天**走「强调」：2px 墨边 + 「今」角标 + w600 字重；
/// - **周末**走「弱化」：`sunken` 静态底 + `meta` 字色（边仍 1px `hairStrong`）；
/// - 今天恰逢周末时两条同时成立：边框/角标/字重压住底色/字色，
///   今天不会被周末的弱化吞掉。
///
/// 判定直接复用 `packages/core_data` 的 `CalendarCell.isToday` / `isWeekend`，
/// 不在这里重算星期 —— 单一真源在 `buildMonthGrid`。
class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.cell,
    required this.summary,
    required this.onTap,
  });

  final CalendarCell cell;
  final CalendarDaySummary? summary;
  final VoidCallback? onTap;

  /// 今天：三条强调通道同时成立，可用 `calendar-cell-today` 定位。
  bool get _isToday => cell.isToday;

  /// 周末弱化只作用在本月格；补白格已用 `faint` 日号降权，不再叠底色。
  bool get _isWeekend => cell.isWeekend && cell.inMonth;

  /// 完成度洗底。
  ///
  /// 周末先铺静态 `sunken` 底，再按完成度叠 `inkWash`。叠色用
  /// `Color.alphaBlend` 出实色，避免半透明洗底透出纸色把弱化抹平。
  Color? _fill(ThemeTokens t) {
    final day = summary;
    final double ratio = (day == null || day.planTotal == 0)
        ? 0.0
        : day.planDone / day.planTotal;
    if (_isWeekend) {
      if (ratio <= 0) {
        return t.sunken;
      }
      return Color.alphaBlend(
        t.inkWash.withValues(alpha: ratio),
        t.sunken,
      );
    }
    return day == null ? null : t.inkWash.withValues(alpha: ratio);
  }

  /// 日号颜色：今天的墨色不被周末弱化顶掉；补白格恒 `faint`（沿用原口径）。
  Color _dayNumberColor(ThemeTokens t) {
    if (!cell.inMonth) {
      return t.faint;
    }
    if (!_isToday && _isWeekend) {
      return t.meta;
    }
    return t.ink;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final AppLocalizations l10n = _l10nOf(context);
    final day = summary;

    // 英文态的「今天」角标是**单词** `Today`（5 字符），中文态是单字 `今`。
    //
    // 角标贴在格内**右上角**、而日号**居中** ⇒ 两者落在同一条竖直带上：
    // 单字角标（11.5px）与日号（28.2px）只在极窄格子里擦边，单词角标
    // （57.5px）则必然与日号相交（实测 420 / 600 / 800 三档都相交，
    // 见 `reports\task61-f6-today-badge.md`）。
    //
    // 中文态**原样保留**（逐像素不变）；英文态把角标挪到日号**下方**单独一行，
    // 竖直方向彻底错开 —— 与形状徽标同行，格高仍是两行（不引入 RenderFlex 溢出）。
    final bool todayOnOwnLine = _isToday && l10n.language == AppLanguage.en;

    Widget content = Container(
      constraints: const BoxConstraints(minHeight: 38),
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: _isToday ? t.ink : t.hairStrong,
          width: _isToday ? 2 : 1,
        ),
        color: _fill(t),
      ),
      // `StackFit.expand`：让非定位的 Column 拿到紧约束好保持横向居中；
      // 「今」用 Positioned 贴右上角，不占 Column 的行高（52px 格高塞不下三行）。
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Text(
                _dayNumber(cell.date),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _dayNumberColor(t),
                  fontWeight: _isToday ? FontWeight.w600 : null,
                ),
              ),
              if (todayOnOwnLine)
                _todayLabelLine(theme, t, l10n, day?.badge)
              else if (day != null)
                Text(
                  day.badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: t.meta,
                  ),
                ),
            ],
          ),
          if (_isToday && !todayOnOwnLine)
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                l10n.calendarTodayBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );

    // 两条通道各打一个稳定 key；今天恰逢周末时两个 key 同时存在（嵌套而非互斥）。
    if (_isWeekend) {
      content = KeyedSubtree(
        key: const ValueKey('calendar-cell-weekend'),
        child: content,
      );
    }
    if (_isToday) {
      content = KeyedSubtree(
        key: const ValueKey('calendar-cell-today'),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: content,
    );
  }

  /// 英文态的「今天」角标：日号**下方**单独一行（与形状徽标同行）。
  ///
  /// - `softWrap: false` + `overflow: ellipsis`：单词比格宽还长时**不折行** ——
  ///   折行会把这一行撑成两行，格高（46px 可用）随即不够，第三行直接 RenderFlex
  ///   溢出；单行 + 省略号则最多一行、绝不溢出；
  /// - `Flexible` + `TextAlign.center`：单词在剩余宽度里居中，且永远不越出格子。
  Widget _todayLabelLine(
    ThemeData theme,
    ThemeTokens t,
    AppLocalizations l10n,
    String? shapeBadge,
  ) {
    return Row(
      children: [
        if (shapeBadge != null)
          Text(
            shapeBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              color: t.meta,
            ),
          ),
        Flexible(
          child: Text(
            l10n.calendarTodayBadge,
            textAlign: TextAlign.center,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: t.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}