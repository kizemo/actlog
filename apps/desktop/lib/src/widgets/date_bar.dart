import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_data/core_data.dart';

import '../providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'date_picker_sheet.dart';

/// 打开日期点选卡片；选中后把该日期写回 [selectedDateProvider]。
///
/// 宿主（`app.dart` 的吸顶头）与组件内置默认走**同一条**实现，避免两处各写
/// 一遍「弹层 → 写选中日」。先取容器再 `await`：弹层关闭时调用方的 context
/// 可能已经卸载，那时再取容器会抛。
Future<void> openDatePicker(BuildContext context, String current) async {
  final ProviderContainer container =
      ProviderScope.containerOf(context, listen: false);
  final String? picked = await DatePickerSheet.show(context, initial: current);
  if (picked == null) {
    return;
  }
  container.read(selectedDateProvider.notifier).state = picked;
}

/// 顶部日期定位条（今日页 / 日历页 / 待办池 / 习惯 / 项目共用）。
///
/// 视觉口径（Task 49，单行三件套）：
/// `‹` · 日期（点开日期卡片）· `›` · 只读状态徽标（过去 = 补录模式 / 未来 = 预排）。
/// 顺序固定，**任何档位都不换行**（`Row` + 日期区 `Flexible`/`FittedBox`）。
/// `‹` / `›` 相对**选中日**前后一天；日期文字点开 [DatePickerSheet] 选日，
/// 选中后立刻写回 [selectedDateProvider]。
///
/// **[未覆盖] 原因**：原型还有 `[补录模式]` 与 `模式 ▾ 完整/极简` 两个
/// **可切换**的 ghost 按钮。B1 的 `providers.dart` 里没有 day-mode /
/// supplement 状态（`dayModeFull` / `dayModeMinimal` 只是 `core_data` 常量，
/// 今日页 mode 由调用方传入），而本单元不得改 `providers.dart` / `pages`。
/// 按 `DESIGN.md` §2「禁止假按钮」，这里**不渲染不可切换的按钮**，
/// 只把过去 / 未来日的事实渲染成只读状态徽标（`补录模式` / `预排`）。
class DateBar extends ConsumerWidget {
  /// 创建日期条。
  const DateBar({super.key, this.onPickDate});

  /// 点标题时的回调（打开 [DatePickerSheet]）；null ⇒ 走内置的同一条实现。
  final void Function(String date)? onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final date = ref.watch(selectedDateProvider);
    final today = ref.watch(todayProvider);
    final isPast = date.compareTo(today) < 0;
    final isFuture = date.compareTo(today) > 0;
    final prevDate = shiftIsoDate(date, -1);
    final nextDate = shiftIsoDate(date, 1);

    // 需求 1（Task 49）：单行三件套 `‹` · 日期 · `›`（+ 只读状态徽标）。
    //
    // 外层是 `Row`（不是 `Wrap`）⇒ 结构上不可能换行；宽度不够时只由日期区的
    // `Flexible` + `FittedBox(scaleDown)` 吸收，任何档位都不出 `RenderFlex overflow`。
    // 整组用 `MainAxisAlignment.center` 居中，箭头因此始终贴着日期两侧。
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hair, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // `‹` / `›`：相对**选中日**前后一天。
          _GhostButton(
            key: const ValueKey('date-bar-prev'),
            tooltip: '前一天',
            label: '‹',
            onPressed: () =>
                ref.read(selectedDateProvider.notifier).state = prevDate,
          ),
          const SizedBox(width: 6),
          // 日期标题：点开日期卡片选日（Task 49 需求 2）。
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _TitleButton(
                key: const ValueKey('date-bar-title'),
                title: dateTitle(date),
                onPressed: () {
                  final void Function(String date)? callback = onPickDate;
                  if (callback != null) {
                    callback(date);
                  } else {
                    openDatePicker(context, date);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          _GhostButton(
            key: const ValueKey('date-bar-next'),
            tooltip: '后一天',
            label: '›',
            onPressed: () =>
                ref.read(selectedDateProvider.notifier).state = nextDate,
          ),
          // 只读状态徽标（过去 = 补录模式 / 未来 = 预排），不是可切换按钮。
          if (isPast || isFuture) ...<Widget>[
            const SizedBox(width: 8),
            _StateBadge(text: isPast ? '补录模式' : '预排'),
          ],
        ],
      ),
    );
  }
}

/// 原型 `.dbtn`：ghost 按钮（`--card` 底 + 1px `--hair` 边，hover 换
/// `--hair-strong`）。**不**用 Material `TextButton` / `IconButton`，
/// 避免带入默认的水波纹底色、最小尺寸与内边距。
class _GhostButton extends StatefulWidget {
  const _GhostButton({
    super.key,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 29),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: _hovered ? t.hairStrong : t.hair,
                  width: 1,
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(fontSize: 14, color: t.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 原型 `.dbtn-date`：display 字族日期 + `▾`，hover 给 ink 洗底。
class _TitleButton extends StatefulWidget {
  const _TitleButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  State<_TitleButton> createState() => _TitleButtonState();
}

class _TitleButtonState extends State<_TitleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _hovered ? t.inkWash : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.19,
                    color: t.ink,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '▾',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 11,
                    color: t.faint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 原型 `.badge.warn`：只读状态徽标（过去 = 补录模式，未来 = 预排）。
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: t.hair, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: t.accentInk),
      ),
    );
  }
}
