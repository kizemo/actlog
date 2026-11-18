export 'theme_tokens.dart';

/// B 版「墨径 · 账页流」的设计 token。
///
/// 唯一真源是 `design-demos/TOKENS.md`；改这里之前必须先改那份口径文件。
/// 颜色值一律从该文件抄录，不凭记忆改写。
///
/// **分工（Task 41）**：颜色已全部迁到解析式 token 包 `ThemeTokens`
/// （随 `ThemeData.extensions` 按浅色 / 深色下发）；本类只保留**尺寸**，
/// **不再持有任何颜色** —— 想写静态浅色色值会直接编译失败。
/// `export 'theme_tokens.dart';` 让既有的 `import .../theme/app_tokens.dart`
/// 无需新增 import 就能用 `context.tokens`。
class AppTokens {
  const AppTokens._();

  // --- 尺寸 token（与亮度无关，留在本类） ---

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

  // --- 方格时间轴 · 刻度尺（`task36-a-roulette.html` `.ax-hour` / `.ax-half`） ---
  // 只做刻度长度，颜色一律复用 `hair` / `hairStrong`：刻度是装饰线，
  // 不承载信息，也不进语义树。**只增不改**，既有 token 一个不动。

  /// 刻度尺 · 整点刻度长度（原型 `.ax-hour{width:6px}`）。
  static const double axisTickHour = 6;

  /// 刻度尺 · 半点刻度长度（原型 `.ax-half{width:3px}`）。
  static const double axisTickHalf = 3;
}
