import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'focus_ring.dart';

/// 一枚芯片的选项定义。
final class ChipOption {
  /// 创建一个选项。
  const ChipOption({required this.key, required this.label, this.deny = false});

  /// 稳定标识（写库用）。
  final String key;

  /// 显示文案。
  final String label;

  /// 是否为「拒绝类」语义。
  ///
  /// 拒绝类芯片选中时用赭石描边 + 赭石洗底（B 版允许的 5 处赭石位置之一），
  /// 其余选中态一律 **ink 洗底 + ink 边 + ink 字**（`--ink-wash`，非反白）。
  final bool deny;
}

/// 通用芯片条（单选 / 多选）。
///
/// 视觉口径（裁定 A / `v2-ledger.html:227-236`）：
/// 常态 = `--paper` 底 + `--hair-strong` 边 + `--meta` 字（`v2-ledger.html:228`
/// 就是 `--paper`；用 `--card` 会让芯片与所在卡片同色糊在一起）；
/// 选中 = `--ink-wash` 底 + `--ink` 边 + `--ink` 字 + 500 字重；
/// 拒绝类选中 = `--accent-wash` 底 + `--accent` 边 + `--accent-ink` 字。
/// 「ink 反白」只留给 `.btn.pri` / `.chk` / `.cell`，芯片**不反白**。
class ChipRow extends StatelessWidget {
  /// 创建芯片条。
  const ChipRow({
    super.key,
    required this.options,
    this.selected = const <String>{},
    this.multi = false,
    this.onChanged,
  });

  /// 可选项。
  final List<ChipOption> options;

  /// 当前已选项（key 集合）。
  final Set<String> selected;

  /// 是否允许多选。
  final bool multi;

  /// 选中变化回调；传 null 表示只读展示。
  final void Function(Set<String> next)? onChanged;

  void _toggle(ChipOption option) {
    final handler = onChanged;
    if (handler == null) {
      return;
    }
    final next = Set<String>.of(selected);
    if (multi) {
      if (!next.remove(option.key)) {
        next.add(option.key);
      }
    } else {
      next
        ..clear()
        ..add(option.key);
    }
    handler(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final option in options)
          _ChipButton(
            option: option,
            checked: selected.contains(option.key),
            onPressed: onChanged == null ? null : () => _toggle(option),
          ),
      ],
    );
  }
}

class _ChipButton extends StatefulWidget {
  const _ChipButton({
    required this.option,
    required this.checked,
    required this.onPressed,
  });

  final ChipOption option;
  final bool checked;
  final VoidCallback? onPressed;

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
  /// 芯片自己的焦点节点：`InkWell` 用它拿焦点，[FocusRing] 用它画环。
  final FocusNode _focusNode = FocusNode(debugLabel: 'ChipButton');

  bool _hovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final checked = widget.checked;
    final theme = Theme.of(context);
    final labelSize = theme.textTheme.labelLarge?.fontSize ?? 12.5;

    final Color background;
    final Color foreground;
    final Color border;
    final FontWeight? weight;
    if (checked && option.deny) {
      // 拒绝类选中：赭石三件套（`.chip.deny[aria-checked="true"]`）。
      background = AppTokens.accentWash;
      foreground = AppTokens.accentInk;
      border = AppTokens.accent;
      weight = null;
    } else if (checked) {
      // 选中：墨色洗底（**不是**反白）。
      background = AppTokens.inkWash;
      foreground = AppTokens.ink;
      border = AppTokens.ink;
      weight = FontWeight.w500;
    } else {
      // 常态 + hover：hover 只把文字提亮到 ink（边已是 hair-strong，无可再提）。
      background = AppTokens.paper;
      foreground = _hovered ? AppTokens.ink : AppTokens.meta;
      border = AppTokens.hairStrong;
      weight = null;
    }

    return Semantics(
      selected: checked,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FocusRing(
          focusNode: _focusNode,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: InkWell(
              focusNode: _focusNode,
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: Container(
                constraints: const BoxConstraints(minHeight: 26),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: border, width: 1),
                ),
                child: Text(
                  option.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: labelSize,
                    color: foreground,
                    fontWeight: weight,
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