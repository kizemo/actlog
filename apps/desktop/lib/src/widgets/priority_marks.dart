// =============================================================================
// 四维度优先级标记 · 字形 + 选择器
// =============================================================================
// 为什么用四种字形而不是四种颜色：
//   颜色是单一通道 —— 红/绿/橙/灰在弱视、灰度打印、极端配色下会塌成一团。
//   这里每个维度一个**形状**（实心/空心 × 三角/菱形），颜色只是第二重冗余。
//
// 维度 ↔ 字形（与 `Quadrant` 的两个布尔同构，不新增枚举）：
//   重要 = ▲   不重要 = ▽   紧急 = ◆   不紧急 = ◇
//   ⇒ Q1 重要且紧急 = ▲◆ / Q2 重要不紧急 = ▲◇
//     Q3 不重要紧急 = ▽◆ / Q4 都不 = ▽◇
//
// 未分级（`quadrant == null`）不画标记，也不留占位空隙 —— 空白本身是信息：
// 用户看一眼就知道这条还没想过分级，与「想了但结论是 Q4」明确区分。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'priority_chips.dart' show colorFromHex;

/// 「重要」维度字形（实心三角）。
const String kMarkImportant = '▲';

/// 「不重要」维度字形（空心三角）。
const String kMarkNotImportant = '▽';

/// 「紧急」维度字形（实心菱形）。
const String kMarkUrgent = '◆';

/// 「不紧急」维度字形（空心菱形）。
const String kMarkNotUrgent = '◇';

/// 由两个布尔拼出象限：`true/true` = Q1，`true/false` = Q2，
/// `false/true` = Q3，`false/false` = Q4。
///
/// 这是四维度与既有 `Quadrant` 之间**唯一**的映射点：选择器、标记、落库
/// 三条路径都走这里，避免「芯片上选的重要，落库变成 Q3」这类漂移。
Quadrant quadrantOf({required bool important, required bool urgent}) {
  if (important) {
    return urgent ? Quadrant.q1 : Quadrant.q2;
  }
  return urgent ? Quadrant.q3 : Quadrant.q4;
}

/// 名称前的优先级标记（0～2 枚字形）。
///
/// 只做**只读渲染**：点击与修改由 `PriorityMarkPicker` 或既有
/// `QuadrantPickerDialog` 承担，标记本身不抢焦点、不进 Tab 序列。
///
/// 语义合成一句中文（如「重要且紧急」），读屏用户听到的是结论而不是
/// 「黑色向上三角 黑色菱形」这种字形噪声。
class PriorityMarks extends StatelessWidget {
  /// 创建标记组；[quadrant] 为 null 时渲染成零尺寸占位（不占空隙）。
  const PriorityMarks({required this.quadrant, this.size = 10, super.key});

  /// 要渲染的象限；null = 未分级。
  final Quadrant? quadrant;

  /// 字形字号（默认 10 —— 与行内其它元信息同级，不抢标题）。
  final double size;

  @override
  Widget build(BuildContext context) {
    final Quadrant? value = quadrant;
    if (value == null) {
      return const SizedBox.shrink();
    }
    final QuadrantStyle style = QuadrantStyle.of(value);
    final TextStyle glyphStyle = TextStyle(
      // 四个字形都不在 Inter 里，必须显式声明族 —— 继承 `DefaultTextStyle`
      // 会渲染成豆腐块（与 `day_grid.dart` 的字形通道同一处理）。
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: size,
      height: 1.1,
      color: colorFromHex(style.colorHex),
    );
    return Semantics(
      label: style.label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value.isImportant ? kMarkImportant : kMarkNotImportant,
            style: glyphStyle,
            key: const ValueKey<String>('priority-mark-importance'),
          ),
          const SizedBox(width: 1),
          Text(
            value.isUrgent ? kMarkUrgent : kMarkNotUrgent,
            style: glyphStyle,
            key: const ValueKey<String>('priority-mark-urgency'),
          ),
        ],
      ),
    );
  }
}

/// 四枚可点芯片的优先级选择器：两组各二选一，恒得到确定象限。
///
/// 为什么要两块而不是一个 2×2 宫格：宫格要求用户先理解「象限」这个词；
/// 两块二选一只要回答两个各自独立的判断（重不重要 / 急不急），
/// 象限是**算出来的结果**，不是用户要背的术语。
///
/// 交互约定：
/// - 点任一芯片 ⇒ 该维度取该值，**另一维度保持不变**（未分级时按「否」起步）；
/// - 未分级（`value == null`）时四枚芯片都不高亮，与「已选 Q4」明确区分；
/// - 已分级时多出一枚「清除」，把它打回未分级（落库为 null）。
class PriorityMarkPicker extends StatelessWidget {
  /// 创建选择器。
  const PriorityMarkPicker({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// 当前象限；null = 未分级。
  final Quadrant? value;

  /// 选择变化回调；`null` 表示清除分级。
  final ValueChanged<Quadrant?> onChanged;

  /// 为 false 时整体只读（提交中）。
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Quadrant? current = value;
    final bool important = current?.isImportant ?? false;
    final bool urgent = current?.isUrgent ?? false;
    final Color accent =
        current == null ? AppTokens.ink2 : colorFromHex(QuadrantStyle.of(current).colorHex);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-important'),
          label: '重要',
          glyph: kMarkImportant,
          selected: current != null && important,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: true, urgent: urgent)),
        ),
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-not-important'),
          label: '不重要',
          glyph: kMarkNotImportant,
          selected: current != null && !important,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: false, urgent: urgent)),
        ),
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-urgent'),
          label: '紧急',
          glyph: kMarkUrgent,
          selected: current != null && urgent,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: important, urgent: true)),
        ),
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-not-urgent'),
          label: '不紧急',
          glyph: kMarkNotUrgent,
          selected: current != null && !urgent,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: important, urgent: false)),
        ),
        if (current != null)
          _ClearChip(enabled: enabled, onTap: () => onChanged(null)),
      ],
    );
  }
}

/// 一枚芯片：字形 + 中文标签，选中时换底色与边框。
class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.accent,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final String glyph;
  final bool selected;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = !enabled
        ? AppTokens.faint
        : selected
            ? accent
            : AppTokens.ink2;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: selected ? AppTokens.sunken : AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: !enabled
                  ? AppTokens.hair
                  : selected
                      ? accent
                      : AppTokens.hairStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                glyph,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontFamilyFallback: AppFonts.bodyFallback,
                  fontSize: 10,
                  height: 1.1,
                  color: selected && enabled ? accent : AppTokens.faint,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontFamilyFallback: AppFonts.bodyFallback,
                  fontSize: 11,
                  height: 1.2,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「清除」芯片：把已分级打回未分级。
class _ClearChip extends StatelessWidget {
  const _ClearChip({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '清除优先级',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey<String>('priority-mark-picker-clear'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            '清除',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 11,
              height: 1.2,
              color: enabled ? AppTokens.faint : AppTokens.hair,
            ),
          ),
        ),
      ),
    );
  }
}