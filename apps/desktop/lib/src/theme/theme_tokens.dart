import 'package:flutter/material.dart';

/// B 版「墨径 · 账页流」的**解析式**设计 token 包（浅色 + 深色两套）。
///
/// 唯一真源是 `design-demos/TOKENS.md`；改这里之前必须先改那份口径文件。
/// 颜色值一律从该文件抄录，不凭记忆改写。
///
/// 与 [AppTokens] 的分工：**颜色**全部在这里（随 `ThemeData.extensions`
/// 下发到渲染点），**尺寸**留在 `AppTokens`（与亮度无关，`static const`）。
///
/// 为什么做成 `ThemeExtension` 而不是「按 `Theme.of(context).brightness` 推断」：
/// 颜色在装配期就随 `ThemeData` 一起定好，渲染点拿到的就是选定那一套，
/// 不会出现「brightness 翻转了但色板还在插值」的错位，也不引入全局可变状态。
class ThemeTokens extends ThemeExtension<ThemeTokens> {
  const ThemeTokens({
    required this.paper,
    required this.card,
    required this.sunken,
    required this.dock,
    required this.keybg,
    required this.inkWash,
    required this.accentWash,
    required this.ink,
    required this.ink2,
    required this.meta,
    required this.faint,
    required this.hair,
    required this.hairSoft,
    required this.hairStrong,
    required this.accent,
    required this.accentInk,
    required this.slotPlan,
    required this.slotDone,
    required this.slotBackfill,
    required this.slotHabit,
    required this.slotPlanInk,
    required this.slotDoneInk,
    required this.slotBackfillInk,
    required this.slotHabitInk,
    required this.gridSectionMorning,
    required this.gridSectionNoon,
    required this.gridSectionEvening,
    required this.shadowTint,
  });

  // --- 别名承载常量 ---
  // 四态前景（`slotXxxInk`）与三段底色（`gridSectionXxx`）是**别名**，不是独立
  // 色值。这里用常量承载同一份字面量，浅色 / 深色两档各自引用：
  // 改 `ink` 时三个前景别名必然跟着改，杜绝「格底换色、格内文字没换」式的
  // 半截改动（`TOKENS.md` §8.4 的教训）。
  //
  // 浅色档的字面量集中在 [LightPalette]（见文件末尾同名类）：`ThemeTokens.light`
  // 与迁移期别名 `AppTokens.*` 都从那一份取，保证「浅色值只有一个字面量来源」。

  static const Color _darkInk = Color(0xFFECE5DA);
  static const Color _darkMeta = Color(0xFFBFB6A7);
  static const Color _darkCard = Color(0xFF221E1A);
  static const Color _darkPaper = Color(0xFF1A1714);
  static const Color _darkSunken = Color(0xFF141210);

  /// 页面唯一背景（浅色 = 米纸；深色 = 暖墨深褐）。
  final Color paper;

  /// 卡片底（比纸略亮，用于抬起）。
  final Color card;

  /// 下沉区（hover 底、输入区底；深色下比纸更暗）。
  final Color sunken;

  /// 吸底习惯条底。
  final Color dock;

  /// 键帽底。
  final Color keybg;

  /// 「当前/选中」浅洗底（浅色 = 米赭洗底；深色下「洗」= 提亮）。
  final Color inkWash;

  /// 「警示/缺口」浅洗底（赭石系）。
  final Color accentWash;

  /// 主墨色：正文、标题、勾选框、当前页。
  ///
  /// 浅色 = 暖墨黑（对 `paper` 12.69:1）；深色 = 暖米白（对 `paper` 14.27:1）。
  final Color ink;

  /// 强次级（备注、行动项芯片）。浅色对 `paper` 9.19:1。
  final Color ink2;

  /// 次级文字（徽标、优先级、时间刻度）。
  final Color meta;

  /// 弱文字（副标、刻度数字、占位符）。
  final Color faint;

  /// 分隔线（段头下沿、栏边）。**只允许承载纯装饰线。**
  final Color hair;

  /// 卡片边（最弱）。**只允许承载纯装饰线。**
  final Color hairSoft;

  /// 可交互边界（卡片 hover 边、输入框边、日历格边、复选框边）。
  ///
  /// 浅色落地值 `#8A8170`（原型实测值 `#B9AE96` 仅 2.00:1，已废）；
  /// 两档都要求对 7 个底面 ≥ 3:1。
  final Color hairStrong;

  /// 赭石，**仅**作图形填充（缺口节点、缺口比例条、警示边框）。
  final Color accent;

  /// 赭石文字版（缺口状态文字、警示文案）。
  final Color accentInk;

  // --- 方格时间轴四态底（`TOKENS.md` §8「方格时间轴四态」） ---
  // 只做格子填充，不承载文字与边框；判定顺序见
  // `widgets/timeline/slot_state.dart`（habit → backfill → done → plannedOpen）。

  /// 四态 · 已排未做（`status` 非 done 且不在「现在」之前）。
  final Color slotPlan;

  /// 四态 · 计划已完成（`status='done'` 且非回填）。
  ///
  /// 有意退居背景：若前景仍用 [ink]，完成态会比未完成态更抢眼 —— 语义就反了。
  final Color slotDone;

  /// 四态 · 回填（计划起点已过，或整日已成过去）。
  final Color slotBackfill;

  /// 四态 · 习惯入格（`source_type='habit'` + `is_habit_ref=1`）。
  final Color slotHabit;

  // --- 方格时间轴四态前景（`TOKENS.md` §8.2「四态形状 + 文字双通道」） ---
  // 只承载**条目内的可读信息**：字形、状态词、左缘 2px 竖条、完成态删除线。
  // 「赭石纪律」不破：四态**不得**取 [accent] / [accentWash]。

  /// 四态前景 · 已排未做（= [ink]）。
  final Color slotPlanInk;

  /// 四态前景 · 计划已完成（= [meta]）。
  final Color slotDoneInk;

  /// 四态前景 · 回填（= [ink]）。
  final Color slotBackfillInk;

  /// 四态前景 · 习惯打卡（= [ink]）。
  final Color slotHabitInk;

  // --- 方格时间轴 · 三段底色（`TOKENS.md` §8.3） ---
  // 06:00–12:00 / 12:00–18:00 / 18:00–24:00 各一层极淡底，让人一眼分出
  // 「上午 / 下午 / 晚上」。**只取既有中性阶，不新造 hex、不引入新色相**：
  // 赭石（[accent] / [accentWash]）在方格区仍然禁用。

  /// 三段底色 · 06:00–12:00（= [card]）。
  final Color gridSectionMorning;

  /// 三段底色 · 12:00–18:00（= [paper]）。
  final Color gridSectionNoon;

  /// 三段底色 · 18:00–24:00（= [sunken]）。
  final Color gridSectionEvening;

  /// 硬投影色（气泡 / 浮层的投影**颜色本体**，用方自行加 alpha）。
  ///
  /// 不能拿 [ink] 顶替：深色档 `ink` 是浅米白，投影会变成「发光」。
  /// 浅色 `#322B23` @ 9% 逐字节等于历史硬编码 `0x17322B23`；
  /// 深色 `#0D0A07`（暖近黑）。
  final Color shadowTint;

  /// 浅色档 token（**逐字等于改造前的 `AppTokens.*`**，渲染零变化）。
  static const ThemeTokens light = ThemeTokens(
    paper: LightPalette.paper,
    card: LightPalette.card,
    sunken: LightPalette.sunken,
    dock: LightPalette.dock,
    keybg: LightPalette.keybg,
    inkWash: LightPalette.inkWash,
    accentWash: LightPalette.accentWash,
    ink: LightPalette.ink,
    ink2: LightPalette.ink2,
    meta: LightPalette.meta,
    faint: LightPalette.faint,
    hair: LightPalette.hair,
    hairSoft: LightPalette.hairSoft,
    hairStrong: LightPalette.hairStrong,
    accent: LightPalette.accent,
    accentInk: LightPalette.accentInk,
    slotPlan: LightPalette.slotPlan,
    slotDone: LightPalette.slotDone,
    slotBackfill: LightPalette.slotBackfill,
    slotHabit: LightPalette.slotHabit,
    slotPlanInk: LightPalette.slotPlanInk,
    slotDoneInk: LightPalette.slotDoneInk,
    slotBackfillInk: LightPalette.slotBackfillInk,
    slotHabitInk: LightPalette.slotHabitInk,
    gridSectionMorning: LightPalette.gridSectionMorning,
    gridSectionNoon: LightPalette.gridSectionNoon,
    gridSectionEvening: LightPalette.gridSectionEvening,
    shadowTint: LightPalette.shadowTint,
  );

  /// 深色档 token（暖墨深褐，设计文档 §4 全表）。
  static const ThemeTokens dark = ThemeTokens(
    paper: _darkPaper,
    card: _darkCard,
    sunken: _darkSunken,
    dock: Color(0xFF1F1B17),
    keybg: Color(0xFF1C1915),
    inkWash: Color(0xFF2B2620),
    accentWash: Color(0xFF33241A),
    ink: _darkInk,
    ink2: Color(0xFFDCD4C7),
    meta: _darkMeta,
    faint: Color(0xFFA79E8F),
    hair: Color(0xFF3A342C),
    hairSoft: Color(0xFF2A251F),
    hairStrong: Color(0xFF827869),
    accent: Color(0xFFC08A4E),
    accentInk: Color(0xFFD6A366),
    slotPlan: Color(0xFF241F19),
    slotDone: Color(0xFF1D1A16),
    slotBackfill: Color(0xFF2A2318),
    slotHabit: Color(0xFF322A20),
    slotPlanInk: _darkInk,
    slotDoneInk: _darkMeta,
    slotBackfillInk: _darkInk,
    slotHabitInk: _darkInk,
    gridSectionMorning: _darkCard,
    gridSectionNoon: _darkPaper,
    gridSectionEvening: _darkSunken,
    shadowTint: Color(0xFF0D0A07),
  );

  /// 取当前主题的 token 包。
  ///
  /// **兜底 [light]**：既有 widget 测试里有裸 `MaterialApp()`（没有挂
  /// `extensions`），拿不到 extension ⇒ 回落浅色，测试不炸。
  static ThemeTokens of(BuildContext context) =>
      Theme.of(context).extension<ThemeTokens>() ?? ThemeTokens.light;

  @override
  ThemeTokens copyWith({
    Color? paper,
    Color? card,
    Color? sunken,
    Color? dock,
    Color? keybg,
    Color? inkWash,
    Color? accentWash,
    Color? ink,
    Color? ink2,
    Color? meta,
    Color? faint,
    Color? hair,
    Color? hairSoft,
    Color? hairStrong,
    Color? accent,
    Color? accentInk,
    Color? slotPlan,
    Color? slotDone,
    Color? slotBackfill,
    Color? slotHabit,
    Color? slotPlanInk,
    Color? slotDoneInk,
    Color? slotBackfillInk,
    Color? slotHabitInk,
    Color? gridSectionMorning,
    Color? gridSectionNoon,
    Color? gridSectionEvening,
    Color? shadowTint,
  }) {
    return ThemeTokens(
      paper: paper ?? this.paper,
      card: card ?? this.card,
      sunken: sunken ?? this.sunken,
      dock: dock ?? this.dock,
      keybg: keybg ?? this.keybg,
      inkWash: inkWash ?? this.inkWash,
      accentWash: accentWash ?? this.accentWash,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      meta: meta ?? this.meta,
      faint: faint ?? this.faint,
      hair: hair ?? this.hair,
      hairSoft: hairSoft ?? this.hairSoft,
      hairStrong: hairStrong ?? this.hairStrong,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      slotPlan: slotPlan ?? this.slotPlan,
      slotDone: slotDone ?? this.slotDone,
      slotBackfill: slotBackfill ?? this.slotBackfill,
      slotHabit: slotHabit ?? this.slotHabit,
      slotPlanInk: slotPlanInk ?? this.slotPlanInk,
      slotDoneInk: slotDoneInk ?? this.slotDoneInk,
      slotBackfillInk: slotBackfillInk ?? this.slotBackfillInk,
      slotHabitInk: slotHabitInk ?? this.slotHabitInk,
      gridSectionMorning: gridSectionMorning ?? this.gridSectionMorning,
      gridSectionNoon: gridSectionNoon ?? this.gridSectionNoon,
      gridSectionEvening: gridSectionEvening ?? this.gridSectionEvening,
      shadowTint: shadowTint ?? this.shadowTint,
    );
  }

  /// 逐字段线性插值（`MaterialApp` 默认 `AnimatedTheme` 会调）。
  @override
  ThemeTokens lerp(covariant ThemeTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return ThemeTokens(
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      card: Color.lerp(card, other.card, t) ?? card,
      sunken: Color.lerp(sunken, other.sunken, t) ?? sunken,
      dock: Color.lerp(dock, other.dock, t) ?? dock,
      keybg: Color.lerp(keybg, other.keybg, t) ?? keybg,
      inkWash: Color.lerp(inkWash, other.inkWash, t) ?? inkWash,
      accentWash: Color.lerp(accentWash, other.accentWash, t) ?? accentWash,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      ink2: Color.lerp(ink2, other.ink2, t) ?? ink2,
      meta: Color.lerp(meta, other.meta, t) ?? meta,
      faint: Color.lerp(faint, other.faint, t) ?? faint,
      hair: Color.lerp(hair, other.hair, t) ?? hair,
      hairSoft: Color.lerp(hairSoft, other.hairSoft, t) ?? hairSoft,
      hairStrong: Color.lerp(hairStrong, other.hairStrong, t) ?? hairStrong,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentInk: Color.lerp(accentInk, other.accentInk, t) ?? accentInk,
      slotPlan: Color.lerp(slotPlan, other.slotPlan, t) ?? slotPlan,
      slotDone: Color.lerp(slotDone, other.slotDone, t) ?? slotDone,
      slotBackfill:
          Color.lerp(slotBackfill, other.slotBackfill, t) ?? slotBackfill,
      slotHabit: Color.lerp(slotHabit, other.slotHabit, t) ?? slotHabit,
      slotPlanInk: Color.lerp(slotPlanInk, other.slotPlanInk, t) ?? slotPlanInk,
      slotDoneInk: Color.lerp(slotDoneInk, other.slotDoneInk, t) ?? slotDoneInk,
      slotBackfillInk:
          Color.lerp(slotBackfillInk, other.slotBackfillInk, t) ??
              slotBackfillInk,
      slotHabitInk:
          Color.lerp(slotHabitInk, other.slotHabitInk, t) ?? slotHabitInk,
      gridSectionMorning:
          Color.lerp(gridSectionMorning, other.gridSectionMorning, t) ??
              gridSectionMorning,
      gridSectionNoon:
          Color.lerp(gridSectionNoon, other.gridSectionNoon, t) ??
              gridSectionNoon,
      gridSectionEvening:
          Color.lerp(gridSectionEvening, other.gridSectionEvening, t) ??
              gridSectionEvening,
      shadowTint: Color.lerp(shadowTint, other.shadowTint, t) ?? shadowTint,
    );
  }
}

/// 语法糖：`context.tokens.paper`。
extension ThemeTokensContext on BuildContext {
  ThemeTokens get tokens => ThemeTokens.of(this);
}

/// 浅色色板的**唯一字面量来源**。
///
/// 为什么需要单独一张常量表：`ThemeTokens.light` 是 `const` **实例**，
/// 而 Dart 不允许在 const 表达式里访问 const 对象的实例字段
/// （`ThemeTokens.light.paper` ⇒ `const_eval_property_access`）。迁移期
/// `app_tokens.dart` 里 27 个 `static const Color` 别名又必须是编译期常量
/// （18 处 `const TextStyle(... color: AppTokens.x)` 依赖它），所以字面量
/// 必须以 **静态 const** 的形式存在一处，两边共同引用。
///
/// 约束：本类只描述浅色档；深色档字面量仍在 [ThemeTokens] 内私有承载。
/// 迁移收尾（删除别名）后本类可保留为浅色单一真源。
abstract final class LightPalette {
  /// 页面唯一背景。
  static const Color paper = Color(0xFFF6F4EF);

  /// 卡片底。
  static const Color card = Color(0xFFFBFAF6);

  /// 下沉区。
  static const Color sunken = Color(0xFFF0EDE5);

  /// 吸底习惯条底。
  static const Color dock = Color(0xFFF7F5F0);

  /// 键帽底。
  static const Color keybg = Color(0xFFF1EFE8);

  /// 「当前/选中」浅洗底。
  static const Color inkWash = Color(0xFFEFE9DE);

  /// 「警示/缺口」浅洗底。
  static const Color accentWash = Color(0xFFF3E8DC);

  /// 主墨色。
  static const Color ink = Color(0xFF322B23);

  /// 强次级。
  static const Color ink2 = Color(0xFF4A4036);

  /// 次级文字。
  static const Color meta = Color(0xFF5F584B);

  /// 弱文字。
  static const Color faint = Color(0xFF6E6759);

  /// 分隔线。
  static const Color hair = Color(0xFFDCD5C6);

  /// 卡片边（最弱）。
  static const Color hairSoft = Color(0xFFEAE4D9);

  /// 可交互边界。
  static const Color hairStrong = Color(0xFF8A8170);

  /// 赭石（仅作图形填充）。
  static const Color accent = Color(0xFF8C5A2B);

  /// 赭石文字版。
  static const Color accentInk = Color(0xFF7A4E24);

  /// 四态底 · 已排未做。
  static const Color slotPlan = Color(0xFFEBE5D8);

  /// 四态底 · 计划已完成。
  static const Color slotDone = Color(0xFFF1F2F0);

  /// 四态底 · 回填。
  static const Color slotBackfill = Color(0xFFEDE4D6);

  /// 四态底 · 习惯入格。
  static const Color slotHabit = Color(0xFFE2DACB);

  /// 四态前景 · 已排未做（= [ink]）。
  static const Color slotPlanInk = ink;

  /// 四态前景 · 计划已完成（= [meta]）。
  static const Color slotDoneInk = meta;

  /// 四态前景 · 回填（= [ink]）。
  static const Color slotBackfillInk = ink;

  /// 四态前景 · 习惯打卡（= [ink]）。
  static const Color slotHabitInk = ink;

  /// 三段底色 · 06:00–12:00（= [card]）。
  static const Color gridSectionMorning = card;

  /// 三段底色 · 12:00–18:00（= [paper]）。
  static const Color gridSectionNoon = paper;

  /// 三段底色 · 18:00–24:00（= [sunken]）。
  static const Color gridSectionEvening = sunken;

  /// 硬投影色。
  static const Color shadowTint = Color(0xFF322B23);
}