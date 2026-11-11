import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 把 `QuadrantStyle.colorHex` 解析成 [Color]。
///
/// 兼容 `#RRGGBB` / `RRGGBB` / `AARRGGBB` 三种写法；解析失败回落主题色而不是抛异常
/// —— 一个配色笔误不该让整个页面白屏。
Color colorFromHex(String hex, {Color fallback = const Color(0xFF757575)}) {
  var value = hex.trim();
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null || value.length != 8) {
    return fallback;
  }
  return Color(parsed);
}

/// 选择器返回值。
///
/// 用包装类而不是裸 `Quadrant?`，是为了区分「主动清空」和「关掉对话框什么都没选」：
/// 前者返回 `QuadrantPick(null)`，后者返回 `null`。
class QuadrantPick {
  /// 创建一个选择结果；[value] 为 null 表示清空已选象限。
  const QuadrantPick(this.value);

  /// 选中的象限；null = 清空。
  final Quadrant? value;
}

/// 四象限选择器（P1-4）。
///
/// 2×2 宫格 + 颜色 + 行动建议文案；再次点击已选项可取消；每个格子的
/// `InkWell` 都可获得焦点，Tab 移动 + Enter/空格确认，满足「键盘可达」。
class QuadrantPickerDialog extends StatelessWidget {
  /// 创建选择器。
  const QuadrantPickerDialog({
    required this.selected,
    required this.mode,
    super.key,
  });

  /// 当前已选象限。
  final Quadrant? selected;

  /// 当前优先级展示模式（决定标题文案）。
  final PriorityDisplayMode mode;

  /// 弹出选择器。返回 null 表示用户取消；返回 `QuadrantPick(null)` 表示清空。
  static Future<QuadrantPick?> show(
    BuildContext context, {
    required Quadrant? selected,
    required PriorityDisplayMode mode,
  }) {
    return showDialog<QuadrantPick>(
      context: context,
      builder: (context) =>
          QuadrantPickerDialog(selected: selected, mode: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('选择四象限'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PriorityDisplay.quadrantHeaderHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final style in QuadrantStyle.all.values)
                  _QuadrantCell(
                    style: style,
                    selected: style.quadrant == selected,
                    onPick: () => Navigator.of(context).pop(
                      // 再次点击已选项 = 取消该条目的象限标记。
                      QuadrantPick(style.quadrant == selected ? null : style.quadrant),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(const QuadrantPick(null)),
          child: const Text('清除'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _QuadrantCell extends StatelessWidget {
  const _QuadrantCell({
    required this.style,
    required this.selected,
    required this.onPick,
  });

  final QuadrantStyle style;
  final bool selected;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? AppTokens.paper : AppTokens.ink;
    final secondary = selected ? AppTokens.paper : AppTokens.meta;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppTokens.ink : AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: selected ? AppTokens.ink : AppTokens.hairStrong,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: selected ? AppTokens.paper : AppTokens.faint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      style.shortLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      style.quadrant.code,
                      style: theme.textTheme.labelSmall?.copyWith(color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  style.label,
                  style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                ),
                const SizedBox(height: 2),
                Text(
                  style.advice,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ABC 选择器（P1-5）。
///
/// 与四象限选择器**互斥**：它只写 `priority_abc` 一列，绝不反推象限。
class AbcPickerDialog extends StatelessWidget {
  /// 创建选择器。
  const AbcPickerDialog({required this.selected, super.key});

  /// 当前已选 ABC。
  final PriorityAbc? selected;

  /// 弹出选择器。返回 null 表示取消；返回 `AbcPick(null)` 表示清空。
  static Future<AbcPick?> show(
    BuildContext context, {
    required PriorityAbc? selected,
  }) {
    return showDialog<AbcPick>(
      context: context,
      builder: (context) => AbcPickerDialog(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('选择 ABC 优先级'),
      children: [
        for (final style in AbcStyle.all.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(
              context,
            ).pop(AbcPick(style.priority == selected ? null : style.priority)),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    style.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(style.description)),
                if (style.priority == selected) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
        SimpleDialogOption(
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(const AbcPick(null)),
          child: const Text('清除'),
        ),
      ],
    );
  }
}

/// ABC 选择结果。
class AbcPick {
  /// 创建一个选择结果；[value] 为 null 表示清空。
  const AbcPick(this.value);

  /// 选中的 ABC；null = 清空。
  final PriorityAbc? value;
}

/// 计划条目上的优先级标签（可点击，P1-4 / P1-5）。
class PriorityTagChip extends StatelessWidget {
  /// 创建标签。
  const PriorityTagChip({
    required this.mode,
    required this.quadrant,
    required this.priorityAbc,
    required this.onTap,
    super.key,
  });

  /// 当前展示模式。
  final PriorityDisplayMode mode;

  /// 条目的象限。
  final Quadrant? quadrant;

  /// 条目的 ABC。
  final PriorityAbc? priorityAbc;

  /// 点击回调。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = PriorityDisplay.labelFor(
      mode,
      quadrant: quadrant,
      priorityAbc: priorityAbc,
    );

    return Material(
      color: AppTokens.card,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: AppTokens.hairStrong, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_outlined, size: 12, color: AppTokens.meta),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTokens.meta,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}