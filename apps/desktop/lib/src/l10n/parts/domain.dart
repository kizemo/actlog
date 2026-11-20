// =============================================================================
// l10n part：领域口径的插值文案（W0 建立，各波次按需追加到自己的 part）
// =============================================================================
// 为什么单独一个 part：这些方法带着 `int` / `String` 参数，形态与纯 getter 不
// 同，而且被多个模块共用（时间轴要「共 N 分钟」，习惯要「连续 N 天」）。
//
// 为什么中文实现要逐字对着旧代码抄：这些方法存在的唯一理由，就是把页面里现成的
// `${...} 分钟` 这类拼串原样搬过来。只要中文输出与旧拼串差一个空格，这一轮
// 「纯重构、零语义变化」就不成立。文件内注释标了各自的旧代码出处。
//
// 英文实现没有旧代码可对齐（旧代码里没有任何英文态），因此英文措辞是 W0 定的
// 新文案，只保证语义对应，不声称「等价于旧代码」。
// =============================================================================

/// 带参数的插值文案。
abstract class DomainL10n {
  /// 时长：`N 小时`。
  String hoursCount(int hours);

  /// 时长：`共 N 分钟` / `N 分钟`。
  String minutesCount(int minutes);

  /// 顺延天数：`已顺延 N 天`。
  String deferredDays(int days);

  /// 心态维度分值标签：`<维度>分值`（用于校验失败信息）。
  String moodScoreLabel(String dimensionLabel);
}

/// 插值文案：简体中文（逐字对齐旧拼串）。
mixin DomainZhL10n implements DomainL10n {
  /// 旧代码：`widgets\est_duration_text.dart:64` —— `'${minutes ~/ 60} 小时'`。
  @override
  String hoursCount(int hours) => '$hours 小时';

  /// 旧代码：`widgets\timeline\slot_range_dialog.dart:137` 与
  /// `widgets\timeline\plan_item_detail_dialog.dart:351` —— `'共 N 分钟'`。
  /// 这里不带 `共` 前缀：需要前缀的调用点自己拼，避免把 `共` 也变成强制。
  @override
  String minutesCount(int minutes) => '$minutes 分钟';

  /// 旧代码：`packages\core_data\lib\src\standup.dart:293` —— `'已顺延 N 天'`。
  @override
  String deferredDays(int days) => '已顺延 $days 天';

  /// 旧代码：`packages\core_domain\lib\src\entities.dart:240` ——
  /// `'${entry.key.label}分值'`。
  @override
  String moodScoreLabel(String dimensionLabel) => '$dimensionLabel分值';
}

/// 插值文案：English。
mixin DomainEnL10n implements DomainL10n {
  @override
  String hoursCount(int hours) => '$hours h';

  @override
  String minutesCount(int minutes) => '$minutes min';

  @override
  String deferredDays(int days) => 'Carried over $days day(s)';

  @override
  String moodScoreLabel(String dimensionLabel) => '$dimensionLabel score';
}