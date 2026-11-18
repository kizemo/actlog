// =============================================================================
// 四维度优先级标记 · 字形 + 选择器
// =============================================================================
// 为什么不再用四个三角 / 菱形（Task 39 · 指令 6）：
//   旧的 `▲ ▽ ◆ ◇` 只有 NotoSansSC 一族覆盖（cmap 1/9），兜底链一断就是豆腐块；
//   而且四个形状要靠「实心/空心 × 三角/菱形」两个维度去记，用户记不住哪枚是
//   「紧急」。
//
// 现在的分工（Task 40 · 需求 3：**同图标 + 填充 / 空心**）：
//   两条轴各只用**一枚**图标，正负值只靠**填充 / 空心**区分 ——
//     重要性轴 → 星：重要 = `Icons.star`（实心）/ 不重要 = `Icons.star_border`（空心）；
//     紧急度轴 → 铃：紧急 = `Icons.notifications`（实心）/
//                     不紧急 = `Icons.notifications_none`（空心）。
//   四枚都是 `MaterialIcons.ttf` 随包字形（见 `uses-material-design`），
//   不依赖文本字体链；同轴同形回答「这是哪条轴」，填充与否回答「取哪个值」。
//
// 维度 ↔ 标记（与 `Quadrant` 的两个布尔同构，不新增象限枚举）：
//   重要 = star(实心) / accent        不重要 = star_border(空心) / faint
//   紧急 = notifications(实心) / accent
//   不紧急 = notifications_none(空心) / faint
//   ⇒ Q1 = star + notifications          Q2 = star + notifications_none
//     Q3 = star_border + notifications   Q4 = star_border + notifications_none
//
// **身份仍由 `Key` 承担**：同一轴的两态同形（只差填充），所以「象限 → 标记」的
// 表达是 `PriorityMark` 描述对象（key / label / 实心与空心图标 / `filled` / 颜色），
// 唯一取用入口是 `markOf` / `marksOf`。渲染处带**值级** `Key`
// （`priority-mark-important` / `-not-important` / `-urgent` / `-not-urgent`），
// 测试按 key 定位，不用 `find.text` / `find.byIcon` 这种会与另一态撞车的形状计数。
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

/// 重要性轴的两枚图标：**同一枚星**的实心 / 空心两态。
///
/// 实心 = 重要，空心 = 不重要。两态共享同一轮廓，用户只需读「填没填」。
const IconData kMarkImportant = Icons.star;

/// 空心星 = 不重要（`Icons.star` 的描边版，轮廓一致）。
const IconData kMarkNotImportant = Icons.star_border;

/// 紧急度轴的两枚图标：**同一枚铃**的实心 / 空心两态。
///
/// 实心 = 紧急，空心 = 不紧急。
const IconData kMarkUrgent = Icons.notifications;

/// 空心铃 = 不紧急（`Icons.notifications` 的描边版，轮廓一致）。
const IconData kMarkNotUrgent = Icons.notifications_none;

/// 优先级的两根独立维度轴。
enum PriorityAxis { importance, urgency }

/// 一条优先级标记的**可区分描述**（象限 → 标记的唯一身份来源）。
///
/// 为什么需要这个类型：同一轴的两枚标记是**同一枚图标的两种填充**，
/// 光看 IconData 分不开「重要」与「不重要」；把 key / 颜色 / 实心与空心图标 /
/// `filled` 一起装进来，渲染处与测试才有一个可以用来精确定位的对象。
@immutable
class PriorityMark {
  /// 创建一枚标记描述。
  ///
  /// [filled] 默认 `true` ⇒ 只给 [icon] 的老调用点渲染实心，呈现与改造前一致。
  const PriorityMark({
    required this.key,
    required this.label,
    required this.color,
    this.glyph,
    this.icon,
    this.outlineIcon,
    this.filled = true,
    this.emphasis = FontWeight.w400,
  }) : assert(
          glyph != null || icon != null,
          '标记必须至少有一个字形或一个图标',
        );

  /// 渲染处的值级 Key（`priority-mark-important` 等）—— 测试定位用。
  final Key key;

  /// 该维度取值的中文名（「重要」/「不重要」/「紧急」/「不紧急」）。
  final String label;

  /// 该标记在**浅色档**的主色（重要 = `accent`，不重要 = `faint`，两条轴同构）。
  ///
  /// 五枚 spec 都是 `const` 对象，取值必须能在编译期求得，因此这里存的是
  /// `LightPalette` 的字面量而不是 `ThemeTokens` 的运行时颜色。渲染时必须经
  /// [_markColor] 按**角色**换成当前主题的值 —— 深色档直接用它会把浅色赭石
  /// 贴到深色底上。
  final Color color;

  /// 文本字形；走 Material Icon 的标记为 null（当前四枚标记都走图标）。
  final String? glyph;

  /// 该轴图标的**实心**变体；走文本的标记为 null。
  ///
  /// 同一轴的两枚 spec 共用这一枚 —— 与 [outlineIcon] 组成一对，
  /// 由 [filled] 决定渲染哪一个。
  final IconData? icon;

  /// 该轴图标的**空心**变体；没有描边版时留 null（此时 [resolvedIcon] 回落实心）。
  final IconData? outlineIcon;

  /// 取实心（`true`）还是空心（`false`）变体 —— 同轴两态的**唯一**差异。
  final bool filled;

  /// 文本字重（只对 [glyph] 有效，当前无 spec 使用；保留以维持描述对象完整）。
  final FontWeight emphasis;

  /// 实际要画进界面的图标：`filled` 取 [icon]，否则取 [outlineIcon]。
  ///
  /// 没有空心变体时回落到 [icon] ⇒ 只传一个图标的老调用点渲染结果不变。
  IconData? get resolvedIcon => filled ? icon : (outlineIcon ?? icon);

  /// 是否走 Material Icon 通道。
  bool get isIcon => icon != null;
}

/// 「重要」：**实心**星 + accent。
const PriorityMark kMarkImportantSpec = PriorityMark(
  key: ValueKey<String>('priority-mark-important'),
  label: '重要',
  icon: kMarkImportant,
  outlineIcon: kMarkNotImportant,
  filled: true,
  emphasis: FontWeight.w700,
  color: LightPalette.accent,
);

/// 「不重要」：**同一颗星的空心版** + 弱化色。
///
/// `icon` 与 `kMarkImportantSpec` 相同（都是实心 `star` —— 那是该轴的图标本体），
/// 差别只在 [PriorityMark.filled] = false ⇒ 渲染 `star_border`。这不是笔误：
/// 同轴共用一对图标正是「同图标 + 填充/空心」的实现方式。
const PriorityMark kMarkNotImportantSpec = PriorityMark(
  key: ValueKey<String>('priority-mark-not-important'),
  label: '不重要',
  icon: kMarkImportant,
  outlineIcon: kMarkNotImportant,
  filled: false,
  emphasis: FontWeight.w400,
  color: LightPalette.faint,
);

/// 「紧急」：**实心**铃 + accent。
const PriorityMark kMarkUrgentSpec = PriorityMark(
  key: ValueKey<String>('priority-mark-urgent'),
  label: '紧急',
  icon: kMarkUrgent,
  outlineIcon: kMarkNotUrgent,
  filled: true,
  color: LightPalette.accent,
);

/// 「不紧急」：**同一枚铃的空心版** + 弱化色（只有 `filled` 取反）。
const PriorityMark kMarkNotUrgentSpec = PriorityMark(
  key: ValueKey<String>('priority-mark-not-urgent'),
  label: '不紧急',
  icon: kMarkUrgent,
  outlineIcon: kMarkNotUrgent,
  filled: false,
  color: LightPalette.faint,
);

/// 标记在**当前主题**里实际要用的颜色。
///
/// 角色口径只有一条：`filled == true` ⇔ 该维度取「是」（重要 / 紧急）⇔ `accent`；
/// 空心 ⇔ 取「否」⇔ `faint`。两条轴同构，所以不需要按轴分支。
Color _markColor(ThemeTokens tokens, PriorityMark mark) =>
    mark.filled ? tokens.accent : tokens.faint;

/// 取**单个维度**的标记描述 —— 全仓唯一取用入口（选择器 / 气泡都走这里）。
///
/// [positive] 为该维度是否取「是」（重要 / 紧急）。
PriorityMark markOf({required PriorityAxis axis, required bool positive}) {
  switch (axis) {
    case PriorityAxis.importance:
      return positive ? kMarkImportantSpec : kMarkNotImportantSpec;
    case PriorityAxis.urgency:
      return positive ? kMarkUrgentSpec : kMarkNotUrgentSpec;
  }
}

/// 取一个象限的两枚标记：`[重要性轴, 紧急度轴]`（顺序与渲染顺序一致）。
List<PriorityMark> marksOf(Quadrant quadrant) {
  return <PriorityMark>[
    markOf(axis: PriorityAxis.importance, positive: quadrant.isImportant),
    markOf(axis: PriorityAxis.urgency, positive: quadrant.isUrgent),
  ];
}

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

/// 名称前的优先级标记（0～2 枚）。
///
/// 只做**只读渲染**：点击与修改由 `PriorityMarkPicker` 或既有
/// `QuadrantPickerDialog` 承担，标记本身不抢焦点、不进 Tab 序列。
///
/// 语义合成一句中文（如「重要且紧急」），读屏用户听到的是结论而不是
/// 「实心星 实心铃」这种图形噪声。
class PriorityMarks extends StatelessWidget {
  /// 创建标记组；[quadrant] 为 null 时渲染成零尺寸占位（不占空隙）。
  const PriorityMarks({required this.quadrant, this.size = 10, super.key});

  /// 要渲染的象限；null = 未分级。
  final Quadrant? quadrant;

  /// 标记尺寸（默认 10 —— 与行内其它元信息同级，不抢标题）。
  final double size;

  @override
  Widget build(BuildContext context) {
    final Quadrant? value = quadrant;
    if (value == null) {
      return const SizedBox.shrink();
    }
    final ThemeTokens tokens = context.tokens;
    final QuadrantStyle style = QuadrantStyle.of(value);
    final List<PriorityMark> marks = marksOf(value);
    return Semantics(
      label: style.label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _markWidget(tokens, marks[0]),
          const SizedBox(width: 1),
          _markWidget(tokens, marks[1]),
        ],
      ),
    );
  }

  /// 一枚标记：Material 图标（按 `filled` 落实心/空心）或文本字形，
  /// 各自带**值级** Key；颜色按角色从 [tokens] 解析（见 [_markColor]）。
  Widget _markWidget(ThemeTokens tokens, PriorityMark mark) {
    final String? glyph = mark.glyph;
    final Color color = _markColor(tokens, mark);
    if (glyph != null) {
      return Text(
        glyph,
        key: mark.key,
        style: TextStyle(
          // 文本通道目前没有 spec 使用，保留是为了 `PriorityMark` 仍能描述
          // 纯字形标记；族声明与行内其它元信息保持一致。
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
          fontSize: size,
          height: 1.1,
          fontWeight: mark.emphasis,
          color: color,
        ),
      );
    }
    return Icon(mark.resolvedIcon, key: mark.key, size: size, color: color);
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
    final ThemeTokens tokens = context.tokens;
    final Quadrant? current = value;
    final bool important = current?.isImportant ?? false;
    final bool urgent = current?.isUrgent ?? false;
    final Color accent = current == null
        ? tokens.ink2
        : colorFromHex(
            QuadrantStyle.of(current).colorHex,
            fallback: tokens.meta,
          );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-important'),
          label: '重要',
          mark: kMarkImportantSpec,
          selected: current != null && important,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: true, urgent: urgent)),
        ),
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-not-important'),
          label: '不重要',
          mark: kMarkNotImportantSpec,
          selected: current != null && !important,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: false, urgent: urgent)),
        ),
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-urgent'),
          label: '紧急',
          mark: kMarkUrgentSpec,
          selected: current != null && urgent,
          accent: accent,
          enabled: enabled,
          onTap: () => onChanged(quadrantOf(important: important, urgent: true)),
        ),
        _MarkChip(
          key: const ValueKey<String>('priority-mark-picker-not-urgent'),
          label: '不紧急',
          mark: kMarkNotUrgentSpec,
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

/// 一枚芯片：字形 / 图标 + 中文标签，选中时换底色与边框。
class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.label,
    required this.mark,
    required this.selected,
    required this.accent,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final PriorityMark mark;
  final bool selected;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final Color ink = !enabled
        ? tokens.faint
        : selected
            ? accent
            : tokens.ink2;
    final Color markColor = selected && enabled ? accent : tokens.faint;
    final String? glyph = mark.glyph;
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
            color: selected ? tokens.sunken : tokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: !enabled
                  ? tokens.hair
                  : selected
                      ? accent
                      : tokens.hairStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (glyph != null)
                Text(
                  glyph,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontFamilyFallback: AppFonts.bodyFallback,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: mark.emphasis,
                    color: markColor,
                  ),
                )
              else
                Icon(mark.resolvedIcon, size: 12, color: markColor),
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
    final ThemeTokens tokens = context.tokens;
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
              color: enabled ? tokens.faint : tokens.hair,
            ),
          ),
        ),
      ),
    );
  }
}