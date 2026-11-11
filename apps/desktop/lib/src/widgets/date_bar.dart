import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_data/core_data.dart';

import '../providers.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 顶部日期定位条（今日页 / 日历页 / 待办池 / 习惯 / 项目共用）。
///
/// 视觉口径（B2 需求 1，单行五件套）：
/// `‹` · `昨天` · display 字族日期 + `▾` · `明天` · `›` · 状态徽标 · `今天`。
/// 顺序固定，**任何档位都不换行**（`Row` + 日期区 `Flexible`/`FittedBox`）。
/// `‹` / `›` 相对**选中日**前后一天；`昨天` / `明天` 文案恒定、锚点是**今天**。
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

  /// 点标题时的回调（打开 [DatePickerSheet]）；null 表示不可点。
  final void Function(String date)? onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final today = ref.watch(todayProvider);
    final isPast = date.compareTo(today) < 0;
    final isFuture = date.compareTo(today) > 0;
    final prevDate = shiftIsoDate(date, -1);
    final nextDate = shiftIsoDate(date, 1);

    // 需求 1：**单行五件套** `‹` · `昨天` · 日期 · `明天` · `›`。
    //
    // 外层是 `Row`（不是 `Wrap`）⇒ 结构上不可能换行；宽度不够时只由日期区的
    // `Flexible` + `FittedBox(scaleDown)` 吸收，任何档位都不出 `RenderFlex overflow`。
    // 整组用 `MainAxisAlignment.center` 居中，箭头因此始终贴着日期两侧。
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.hair, width: 1)),
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
          // `昨天` / `明天`：文案恒为相对日，锚点是**今天**（不是选中日）。
          _GhostButton(
            key: const ValueKey('date-bar-yesterday'),
            tooltip: '跳到昨天',
            label: '昨天',
            onPressed: () => ref.read(selectedDateProvider.notifier).state =
                shiftIsoDate(today, -1),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _TitleButton(
                title: dateTitle(date),
                onPressed: onPickDate == null ? null : () => onPickDate!(date),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _GhostButton(
            key: const ValueKey('date-bar-tomorrow'),
            tooltip: '跳到明天',
            label: '明天',
            onPressed: () => ref.read(selectedDateProvider.notifier).state =
                shiftIsoDate(today, 1),
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
          if (date != today) ...<Widget>[
            const SizedBox(width: 8),
            _GhostButton(
              key: const ValueKey('date-bar-today'),
              tooltip: '回到今天',
              label: '今天',
              onPressed: () =>
                  ref.read(selectedDateProvider.notifier).state = today,
            ),
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
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: AppTokens.card,
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
                  color: _hovered ? AppTokens.hairStrong : AppTokens.hair,
                  width: 1,
                ),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(fontSize: 14, color: AppTokens.ink),
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
  const _TitleButton({required this.title, required this.onPressed});

  final String title;
  final VoidCallback? onPressed;

  @override
  State<_TitleButton> createState() => _TitleButtonState();
}

class _TitleButtonState extends State<_TitleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: Material(
        color: _hovered && widget.onPressed != null
            ? AppTokens.inkWash
            : Colors.transparent,
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
                    color: AppTokens.ink,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '▾',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 11,
                    color: AppTokens.faint,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppTokens.paper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTokens.hair, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: AppTokens.accentInk),
      ),
    );
  }
}