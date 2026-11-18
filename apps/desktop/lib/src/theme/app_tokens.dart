import 'package:flutter/material.dart';

/// B 版「墨径 · 账页流」的设计 token（浅色档）。
///
/// 唯一真源是 `design-demos/TOKENS.md`；改这里之前必须先改那份口径文件。
/// 颜色值一律从该文件抄录，不凭记忆改写。
class AppTokens {
  const AppTokens._();

  /// 页面唯一背景（米纸）。
  static const Color paper = Color(0xFFF6F4EF);

  /// 卡片底（比纸略亮，用于抬起）。
  static const Color card = Color(0xFFFBFAF6);

  /// 下沉区（hover 底、输入区底）。
  static const Color sunken = Color(0xFFF0EDE5);

  /// 吸底习惯条底。
  static const Color dock = Color(0xFFF7F5F0);

  /// 键帽底。
  static const Color keybg = Color(0xFFF1EFE8);

  /// 「当前/选中」浅洗底（墨色系，`TOKENS.md` §8.4 去蓝后为米赭洗底）。
  static const Color inkWash = Color(0xFFEFE9DE);

  /// 「警示/缺口」浅洗底（赭石系）。
  static const Color accentWash = Color(0xFFF3E8DC);

  /// 主墨色：正文、标题、勾选框、当前页。
  ///
  /// 暖墨黑（`TOKENS.md` §8.4）：原 `#2E4057` 铁胆蓝黑已废 —— 用户反馈
  /// 「深蓝文字」与米纸基调冲突。对 `paper` 12.69:1 / `card` 13.36:1。
  static const Color ink = Color(0xFF322B23);

  /// 强次级（备注、行动项芯片）。
  ///
  /// 暖中墨（`TOKENS.md` §8.4）：原 `#3D5170` 已废。对 `paper` 9.19:1 / `card` 9.68:1。
  static const Color ink2 = Color(0xFF4A4036);

  /// 次级文字（徽标、优先级、时间刻度）。
  static const Color meta = Color(0xFF5F584B);

  /// 弱文字（副标、刻度数字、占位符）。
  static const Color faint = Color(0xFF6E6759);

  /// 分隔线（段头下沿、栏边）。**只允许承载纯装饰线。**
  static const Color hair = Color(0xFFDCD5C6);

  /// 卡片边（最弱）。**只允许承载纯装饰线。**
  static const Color hairSoft = Color(0xFFEAE4D9);

  /// 可交互边界（卡片 hover 边、输入框边、日历格边、复选框边）。
  ///
  /// B1 落地值 `#8A8170`；原型实测值 `#B9AE96` 仅 2.00:1，已废。
  static const Color hairStrong = Color(0xFF8A8170);

  /// 赭石，**仅**作图形填充（缺口节点、缺口比例条、警示边框）。
  static const Color accent = Color(0xFF8C5A2B);

  /// 赭石文字版（缺口状态文字、警示文案）。
  static const Color accentInk = Color(0xFF7A4E24);

  /// 圆角（卡片、按钮、输入框、面板）。禁止大圆角卡。
  static const double radius = 4;

  /// 卡片之间呼吸。
  static const double gapCard = 12;

  /// 段内元素间距（密度三档变量，舒适档值）。
  static const double gapSec = 22;

  /// 时间轴节点列宽。
  static const double tlWidth = 64;

  /// 时间轴列与正文列间距。
  static const double tlGap = 12;

  /// 窄视口（`< tlNarrowBreakpoint`）时间轴节点列宽（`TOKENS.md:238`）。
  static const double tlWidthNarrow = 52;

  /// 窄视口（`< tlNarrowBreakpoint`）时间轴列与正文列间距（`TOKENS.md:239`）。
  static const double tlGapNarrow = 10;

  // --- 方格时间轴四态底（`TOKENS.md` §8「方格时间轴四态」） ---
  // 只做格子填充，不承载文字与边框；判定顺序见
  // `widgets/timeline/slot_state.dart`（habit → backfill → done → plannedOpen）。

  /// 四态 · 已排未做（`status` 非 done 且不在「现在」之前）。
  ///
  /// `TOKENS.md` §8.4：原 `#E8ECF1` 带蓝已废；对 `ink` 11.11:1。
  static const Color slotPlan = Color(0xFFEBE5D8);

  /// 四态 · 计划已完成（`status='done'` 且非回填）。
  static const Color slotDone = Color(0xFFF1F2F0);

  /// 四态 · 回填（计划起点已过，或整日已成过去）。
  static const Color slotBackfill = Color(0xFFEDE4D6);

  /// 四态 · 习惯入格（`source_type='habit'` + `is_habit_ref=1`）。
  ///
  /// `TOKENS.md` §8.4：原 `#DCE4EC` 带蓝已废；对 `ink` 10.05:1。
  static const Color slotHabit = Color(0xFFE2DACB);

  // --- 方格时间轴四态前景（`TOKENS.md` §8.2「四态形状 + 文字双通道」） ---
  // 只承载**条目内的可读信息**：字形、状态词、左缘 2px 竖条、完成态删除线。
  // 与上面四个格底色成对使用，实测对比度见 `TOKENS.md` §8.2（四组均 ≥ 4.5:1）。
  // 「赭石纪律」不破：四态**不得**取 `--accent` / `--accent-wash`。
  //
  // 为什么完成态要独立一个前景色：`--slot-done` 有意退居背景（几乎等于纸色），
  // 若前景仍用 `--ink`，完成态会比未完成态更抢眼 —— 语义就反了。

  /// 四态前景 · 已排未做（= `--ink`）。
  ///
  /// 直接引用 [ink] 而非抄字面量：`TOKENS.md` §8.4 改 `--ink` 时这三个别名
  /// 必须同步，写成别名可避免「格底去蓝、格内文字仍蓝」的半截改动。
  static const Color slotPlanInk = ink;

  /// 四态前景 · 计划已完成（= `--meta`）。
  static const Color slotDoneInk = Color(0xFF5F584B);

  /// 四态前景 · 回填（= `--ink`）。
  static const Color slotBackfillInk = ink;

  /// 四态前景 · 习惯打卡（= `--ink`）。
  static const Color slotHabitInk = ink;

  // --- 方格时间轴 · 刻度尺（`task36-a-roulette.html` `.ax-hour` / `.ax-half`） ---
  // 只做刻度长度，颜色一律复用 `hair` / `hairStrong`：刻度是装饰线，
  // 不承载信息，也不进语义树。**只增不改**，既有 token 一个不动。

  /// 刻度尺 · 整点刻度长度（原型 `.ax-hour{width:6px}`）。
  static const double axisTickHour = 6;

  /// 刻度尺 · 半点刻度长度（原型 `.ax-half{width:3px}`）。
  static const double axisTickHalf = 3;

  // --- 方格时间轴 · 三段底色（`TOKENS.md` §8.3，Task 39 · W1） ---
  // 06:00–12:00 / 12:00–18:00 / 18:00–24:00 各一层极淡底，让人一眼分出
  // 「上午 / 下午 / 晚上」。**只取既有中性阶，不新造 hex、不引入新色相**：
  // 赭石（`accent` / `accentWash`）在方格区仍然禁用。
  // 三值两两不等、相邻亮度差 2.5–2.7 级 —— 刻意轻微，不做成三块卡片。

  /// 三段底色 · 06:00–12:00（= `--card`，与格区容器同色，靠下两段显形）。
  static const Color gridSectionMorning = card;

  /// 三段底色 · 12:00–18:00（= `--paper`）。
  static const Color gridSectionNoon = paper;

  /// 三段底色 · 18:00–24:00（= `--sunken`）。
  static const Color gridSectionEvening = sunken;
}
