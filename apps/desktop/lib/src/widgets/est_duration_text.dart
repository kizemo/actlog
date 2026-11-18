// apps/desktop/lib/src/widgets/est_duration_text.dart
//
// 预估时间的单位口径（Task 39 W2 追加）。
//
// 存储侧不动：`todo.est_minutes` / `plan_item.est_minutes` 都是 INT 分钟列，
// 单位只是**显示与输入**的换算，由分钟数确定性推导，所以不落库、不加列。

import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 预估时间的可选单位，倍数固定（月按 30 天算 = 43200 分钟）。
enum EstUnit {
  /// 分钟（基准）。
  minute('分钟', 1),

  /// 小时 = 60 分钟。
  hour('小时', 60),

  /// 日 = 1440 分钟。
  day('日', 1440),

  /// 周 = 10080 分钟。
  week('周', 10080),

  /// 月（按 30 天）= 43200 分钟。
  month('月', 43200);

  const EstUnit(this.label, this.minutes);

  /// 中文单位名（也是选择器上的文案）。
  final String label;

  /// 一个单位折合多少分钟。
  final int minutes;
}

/// 数量 × 单位 ⇒ 分钟数。结果 ≤ 0（含四舍五入到 0）按「未填」处理，返回 null，
/// 与 `est_minutes >= 0` 的列约束兼容。
int? estMinutesOf(double amount, EstUnit unit) {
  final int raw = (amount * unit.minutes).round();
  return raw > 0 ? raw : null;
}

/// 分钟数 ⇒ 中文时长，按确定性阶梯收紧到最大可用单位。
///
/// 例：120 → `2 小时`、1440 → `1 日`、45 → `45 分钟`。
/// 非正数原样按分钟给（`0 分钟`），避免落进 `0 % 43200 == 0` 的分支。
String formatEstDuration(int minutes) {
  if (minutes <= 0) {
    return '$minutes 分钟';
  }
  if (minutes % EstUnit.month.minutes == 0) {
    return '${minutes ~/ EstUnit.month.minutes} 月';
  }
  if (minutes % EstUnit.week.minutes == 0) {
    return '${minutes ~/ EstUnit.week.minutes} 周';
  }
  if (minutes % EstUnit.day.minutes == 0) {
    return '${minutes ~/ EstUnit.day.minutes} 日';
  }
  if (minutes % EstUnit.hour.minutes == 0) {
    return '${minutes ~/ EstUnit.hour.minutes} 小时';
  }
  return '$minutes 分钟';
}

/// 预估时间的单位选择器：五个固定档，选中 `ink` 反白 / 未选 `card` + `hair-strong`。
///
/// 两个输入点（`quick_todo_dialog` 的手写面板、`todo_pool_page` 的新建表单）都挂
/// 这一个 widget —— 单位口径只能有一份实现，否则迟早漂移。
///
/// [keyPrefix] 区分挂载点（`quick-todo` / `todo-pool`），每个 chip 的 `ValueKey`
/// 形如 `'$keyPrefix-est-unit-${unit.name}'`：测试按前缀断言「两处都真的接了线」，
/// 也能精确点到某一档。
class EstUnitPicker extends StatelessWidget {
  /// 构造选择器。
  const EstUnitPicker({
    required this.keyPrefix,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// 挂载点前缀，决定 chip 的 `ValueKey`（见类注释）。
  final String keyPrefix;

  /// 当前选中的单位。
  final EstUnit selected;

  /// 选中变化回调（只在 [enabled] 为 true 时触发）。
  final ValueChanged<EstUnit> onChanged;

  /// 提交中 / 已保存后禁用，避免写入过程中还能改口径。
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final EstUnit unit in EstUnit.values)
          _EstUnitChip(
            key: ValueKey<String>('$keyPrefix-est-unit-${unit.name}'),
            label: unit.label,
            selected: unit == selected,
            onTap: enabled ? () => onChanged(unit) : null,
          ),
      ],
    );
  }
}

/// 单位芯片：选中态 `ink` 反白，未选中 `card` 底 + `hair-strong` 边。
class _EstUnitChip extends StatelessWidget {
  const _EstUnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bool enabled = onTap != null;
    final Color background;
    final Color foreground;
    if (selected) {
      background = t.ink;
      foreground = t.paper;
    } else if (enabled) {
      background = t.card;
      foreground = t.ink2;
    } else {
      background = t.sunken;
      foreground = t.faint;
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              constraints: const BoxConstraints(minHeight: 28, minWidth: 36),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: selected ? t.ink : t.hairStrong,
                  width: 1,
                ),
              ),
              child: Text(label, style: _chipStyle(foreground)),
            ),
          ),
        ),
      ),
    );
  }

  /// 正文字体样式（与面板内其余 chip 一致）。
  TextStyle _chipStyle(Color color) {
    return TextStyle(
      fontFamily: AppFonts.body,
      fontFamilyFallback: AppFonts.bodyFallback,
      fontSize: 12,
      color: color,
      height: 1.45,
    );
  }
}