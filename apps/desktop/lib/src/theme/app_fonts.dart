/// 字体族（TOKENS.md §2）。
///
/// 三族各给「首选族 + 兜底族列表」，顺序与 `TOKENS.md` §2 的 CSS 栈**逐字一致**：
/// - `display`：衬线（Fraunces → Noto Serif SC → 宋体），不得用 Inter/Roboto 当唯一 display 族；
/// - `body`：正文（Inter → Noto Sans SC → 微软雅黑 → Segoe UI）；
/// - `mono`：数字与键帽（JetBrains Mono → SFMono → Cascadia → Consolas → Courier New）。
///
/// Flutter 侧：`fontFamily` = 首选族，`fontFamilyFallback` = 兜底列表；
/// 首选族缺字形时 Flutter 按列表顺序回退。
///
/// **口径**：源码只写「原型规定的族名」，不写「本机装了哪个族」。
/// 反例：本机没装 JetBrains Mono，若为此把 `mono` 改写成已装的 `Consolas`，
/// 换到装了 JetBrains Mono 的机器上原型族就永远不生效 —— 机器事实会过期，代码不该记它。
///
/// **打包状态**：四族**随应用自带**，声明在 `pubspec.yaml` 的 `flutter.fonts`
/// （只声明用到的字重，不整目录声明 `assets/fonts/`）：
/// - `Inter` 400 / 500 / 600；
/// - `Fraunces` 400 / 600 / 700；
/// - `JetBrains Mono` 400 / 500；
/// - `Noto Sans SC` 400 —— 由可变字体（`wght` 100–900）**静态实例化**为 `wght=400`，
///   name 表的 subfamily 与 typo-subfamily 均为 `Regular`（不是可变字体的
///   Thin 默认实例）。
///
/// 四族均为 OFL 1.1，许可证随包分发在 `assets/fonts/licenses/`（四族各一份）。
/// `Noto Sans SC` 是 `bodyFallback` 的首项 ⇒ **中文正文不再依赖系统字体**；
/// `TOKENS.md` §8「桌面端缺字库时必须自带」的要求已满足，`144dpi` / `200%`
/// 字号验收的字库前置条件不再缺失。
class AppFonts {
  const AppFonts._();

  /// 标题族首选：Fraunces（随包自带；缺字时回退到 Noto Serif SC → 宋体）。
  static const String display = 'Fraunces';

  /// 标题族兜底顺序：Noto Serif SC → Songti SC → Georgia → SimSun → serif。
  static const List<String> displayFallback = <String>[
    'Noto Serif SC',
    'Songti SC',
    'Georgia',
    'SimSun',
    'serif',
  ];

  /// 正文字族首选：Inter（随包自带；缺字时回退到 Noto Sans SC → 微软雅黑 → Segoe UI）。
  static const String body = 'Inter';

  /// 正文字族兜底顺序。
  static const List<String> bodyFallback = <String>[
    'Noto Sans SC',
    'PingFang SC',
    'Microsoft YaHei',
    'Segoe UI',
    'system-ui',
    'sans-serif',
  ];

  /// 数字 / 键帽族首选：JetBrains Mono（随包自带）。
  static const String mono = 'JetBrains Mono';

  /// 数字 / 键帽族兜底顺序。
  static const List<String> monoFallback = <String>[
    'SFMono-Regular',
    'Cascadia Mono',
    'Consolas',
    'Courier New',
    'monospace',
  ];
}
