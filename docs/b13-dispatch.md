# B13 派工书 · 个人定位四框等高 / 档位标签衬线化 / 起止日期图标化 / 分栏线软化

> 唯一实现契约（AGENTS.md §2 R8）。worker **不得扩大范围**、不得顺手改本文件未列出的行为。
> 前置：HEAD `b2b6fbf`（B12 三条反馈已收口，包 `actlog-Setup-1.0.0_20261126-221923.exe`）。
> 本轮是**用户对 B12 成果的三条追加优化**，不是缺陷返工——B12 已实现的悬浮说明、自动保存 toast、
> 标签 Chrome 形状、结束日期选择器、`_periodText` 回退**一律保持不动**。

## 0. 环境与写集

- 镜像**必须进程内设置**：`$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'`、`$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`。
- SDK 全路径：`F:\soft\flutter\flutter\bin\flutter.bat`（`dart.bat` 同目录）。禁止 `packages\` 内 `flutter pub get`（坑 121）。
- worker **只准** `flutter test <单个文件>`；**禁止** `flutter analyze` / `flutter build` / 全量 `flutter test`（并发污染 `.dart_tool` 与 `build\test_cache`，坑 24，门禁归控制器）。
- **允许改的文件（写集，越界即返工）**：
  - `apps/desktop/lib/src/widgets/goal_brand_panel.dart`
  - `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart`
  - `apps/desktop/test/b12_position_panel_test.dart`、`apps/desktop/test/b12_matrix_tabs_date_test.dart`、`apps/desktop/test/b11_period_date_test.dart`（仅因本派工样式变化而**同步更新断言口径**，不得删用例）
  - 新建 `apps/desktop/test/b13_polish_test.dart`
- **禁止改**：`packages\` 全仓、`apps\desktop\lib\src\theme\**`（含 `theme_tokens.dart` / `app_fonts.dart` / `app_theme.dart`）、`pubspec.yaml`、任何字体与 `assets\fonts\licenses\**`、`l10n_keys.dart` 之外的 l10n 文案键。
- **不删文件**（R4）。`reports\` 是 gitignore 区，不要往里写业务产物。

## 1. 真源事实（照此实现，不要自造值）

| 事实 | 位置 |
|---|---|
| 衬线（display）族 = Fraunces + `Noto Serif SC` 等回退，常量 `AppFonts.display` / `AppFonts.displayFallback` | `apps\desktop\lib\src\theme\app_fonts.dart:33,36-42` |
| 主题里**只有 title 类**（含 `titleMedium`）走 display 衬线族，`labelLarge` 走 body 无衬线 | `apps\desktop\lib\src\theme\app_theme.dart:227-228` vs `:202-203` |
| `labelLarge.fontSize = density.labelSize`（12 / 12.5 / 13.5 三档密度）、`height: 1.3` | `density_profile.dart:10,21,32` |
| 配色 token 真源：paper/card/sunken/ink/meta/hair/hairSoft/lineStrong … | `apps\desktop\lib\src\theme\theme_tokens.dart:375-414` |
| 档位标签渲染：`style = Theme.textTheme.labelLarge` → `_horizonLabel(horizon)`，padding 水平 10 | `goal_blueprint_matrix.dart:194,349-390` |
| 标签高度常量（**本轮唯一允许改的两个度量**）`tabActiveHeight=34`、`tabInactiveHeight=28`、`tabInactiveLift=6`、`chromeTabTopRadius=8` | `goal_blueprint_matrix.dart:148-159` |
| 「起止日期」文字 = 截止日期列紧凑按钮的 child `Text(t.goalBlueprintPeriodTitle)`（tooltip 同名） | `goal_blueprint_matrix.dart:566-580`；文案常量 `l10n_keys.dart:1851/2313`，值「起止日期」 |
| 同文件既有图标约定 `*_outlined`，文件头第 43 行注释写着「本模块使用 2 个 Material 图标」 | `goal_blueprint_matrix.dart:43,598,605` |
| 个人定位四列：`Row(CrossAxisAlignment.start)` + `Expanded → DecoratedBox(左 1px hair 竖线) → Padding(h:12) → _buildItem` | `goal_brand_panel.dart:831-863` |
| `_buildItem` = 标题 `Text(item.title, style.titleMedium)` → `SizedBox(height:6)` → `_buildInput` → 条件状态行 `goal-position-saved` / `goal-position-error` | `goal_brand_panel.dart:871-913` |
| 输入框 `TextField(minLines:1, maxLines:4, isDense:true, contentPadding:v:8)` ⇒ **高度随内容行数变化** | `goal_brand_panel.dart:921-945` |

**四列上下边界不齐的根因（已坐实，不必再查）**：① 标题行数随文案不同（1 行 / 2 行）⇒ 输入框起始 y 不同；② `minLines:1/maxLines:4` ⇒ 输入框高度随内容变化；③ 状态行只在某一列出现 ⇒ 该列总高更高。

## 2. 四项改动（逐条给判据）

### A. 个人定位四个录入框等高、上下边界对齐

A1 标题占位固定：`_buildItem` 的标题用固定高度槽包住并**底对齐**——
`SizedBox(height: _titleSlotHeight, child: Align(alignment: Alignment.bottomLeft, child: Text(item.title, style: titleMedium, …)))`；
新增 `static const double _titleSlotHeight = 40;`（titleMedium 15px × 1.3 ≈ 19.5，两行 ≈ 39，取 40）。
悬浮说明（hint）的锚点 key `_titleKeys[code]` 仍挂在这个 `SizedBox` 上，**不得改变锚定语义**。

A2 输入框等高：`_buildInput` 的 `TextField` 改 **`minLines: 3, maxLines: 3`**（其余 `isDense`、`contentPadding`、`OutlineInputBorder`、`style` 一律不动）。新增 `static const int _positionInputLines = 3;` 并在此使用，不要写裸数字。
**不得**因为内容超长就调回 `maxLines: 4`——等高是本轮硬要求，超长走内部滚动。

A3 状态行占位固定：`goal-position-saved` / `goal-position-error` 两支各自包
`SizedBox(height: _statusSlotHeight, child: Align(alignment: Alignment.centerLeft, child: …))`，新增 `static const double _statusSlotHeight = 20;`。
出现与否都占同一槽位 ⇒ 四列总高一致、底边对齐。

A4 窄视口堆叠分支（`constraints.maxWidth < _inlineBreakpoint`，`:825`）复用同一个 `_buildItem`，**不需要额外改动**，但必须有一条用例覆盖（见 A5）。

A5 新用例（写进 `apps\desktop\test\b13_polish_test.dart`）：
- 宽视口（≥ `_inlineBreakpoint`）渲染后，取四个 `find.byKey(ValueKey('goal-position-input-<code>'))` 的 `tester.getRect(...)`，断言 `top`、`bottom`、`height` **三者两两逐字相等**（用 `closeTo(0, 0.01)`）；
- 向其中**一列**注入超长文本（≥ 4 行内容）后重测，三值仍相等（证明等高不是巧合）；
- 令其中一列进入「已自动保存」状态后重测，四列 `bottom` 仍相等（证明状态行不撑高）；
- 窄视口（< `_inlineBreakpoint`）四框 `width` 与 `height` 两两相等；
- 断言 `TextField` 的 `minLines == maxLines == 3`（直接读 widget 属性，防回归）。

### B. 四个档位标签：字号↑、主题衬线体、内边距↑

B1 文字样式：`_tab` 的 `Text` 样式改为在既有 `labelLarge` 基础上显式覆写——
`fontSize: 15`、`fontFamily: AppFonts.display`、`fontFamilyFallback: AppFonts.displayFallback`（**从 `theme\app_fonts.dart` import，不得自写字体名 `'Fraunces'` / `'Noto Serif SC'`**）、活动态 `fontWeight: FontWeight.w600` 保持、非活动态 `FontWeight.w500`；颜色仍 `active ? tokens.ink : tokens.meta`。
字号必须写成 `static const double _tabFontSize = 15;`，不要裸数字。

B2 内边距：`padding: EdgeInsets.symmetric(horizontal: 10)` → `EdgeInsets.symmetric(horizontal: 18)`；
`tabActiveHeight` 34 → **38**、`tabInactiveHeight` 28 → **31**（`tabInactiveLift` 保持 6；`chromeTabTopRadius` 保持 8；`_tabStrip` 内若有依赖这两个常量的总高度算术，同步跟着改，**不要**新增第三个硬编码高度）。
垂直方向靠 `minimumSize` 撑高即可，`padding` 不加 `vertical`，避免与 `minimumSize` 打架。

B3 `_tabStrip` 的 `FittedBox(fit: scaleDown)` 兜底**保留不动**（标签变宽后仍需防溢出，B12 用例 811 就是测它）。

B4 用例（更新 `b12_matrix_tabs_test.dart` 相关断言 + 新增）：
- 四个标签 `Text.style.fontSize == 15`、`fontFamily == AppFonts.display`、`fontFamilyFallback` 含 `'Noto Serif SC'`；
- `TextButton.styleFrom` 生效后的 padding 左右各 18（读 `button.style.padding` 解析值或 `EffectiveTweeningStyle`；拿不到就直接断言 `_tab` 构建出的 `TextButton` 的 `style.padding`）；
- 标签条在 760 宽（既有 811 用例口径）**不抛 overflow 异常**；
- 活动标签 `TextButton.minimumSize.height == 38`、非活动 `== 31`。
- 原 811/812/813 用例中写死 34/28 的期望值**改到新值**，注释注明「B13 第 2 条」，**不得删用例**。

### C. 去除截止日期列单元格里的文字「起止日期」

C1 `goal_blueprint_matrix.dart:571-574` 的紧凑按钮 child 由 `FittedBox(scaleDown, Text(t.goalBlueprintPeriodTitle))` 换成
`Icon(Icons.date_range_outlined, size: 16, color: tokens.meta)`（**沿用同文件 `:598/:605` 的 `Icons.*_outlined` 约定**）。
按钮的 `key: 'goal-blueprint-period-<id>'`、`tooltip: t.goalBlueprintPeriodTitle`、`onPressed` 打开起止日期对话框的语义**一律保持不变**——入口不能丢。
若该 `_compactButton` 已有统一 `iconSize/color` 处理，按现有机制接入，不要在图标上重复覆写造成双真源。

C2 同步更新文件头 `:43` 注释「本模块使用 2 个 Material 图标」→ 3 个，并列出 `Icons.edit_outlined / Icons.call_split / Icons.date_range_outlined` 与理由（AGENTS.md 第 570 行的例外同步由**控制器**负责，worker 不要改 AGENTS.md）。

C3 用例：
- 断言截止日期列**任何可见 `Text` 都不含字符串「起止日期」**（遍历 `find.text(t.goalBlueprintPeriodTitle)` 命中数为 0）；
- 断言存在 `find.byIcon(Icons.date_range_outlined)` 且其 `Semantics`/`tooltip` 仍携带「起止日期」；
- **点击该图标 ⇒ 起止日期对话框打开**（复用 B12 用例 807/808 的对话框断言路径），且改期能落库；
- `b11_period_date_test.dart` 若因文字→图标而红，按其原意改断言口径（保留用例条数），**禁止**为过门禁删断言。

### D. 分栏线软化与字体语言统一（美化，改动要小而可解释）

D1 `goal_brand_panel.dart:838-847` 的四列**左侧竖分隔线**：颜色 `tokens.hair` → `tokens.hairSoft`，并在竖线上下各留 8px 端头空隙（用 `Padding(vertical: 8)` 包住 `Container(width: 1, color: hairSoft)` 实现，不再顶满整列高度）。理由：四条满高实线把一行切成四个"格子"，视觉噪音大于分栏收益；软色 + 断开的端头让四列读作一组表单。
D2 若 `goal_blueprint_matrix.dart` 的**行头**（左列 `rowHeaderWidth=130`）与顶部标签条展示同一组档位文案，则行头文字同步用与 B1 一致的衬线覆写（`AppFonts.display` + `displayFallback`，字号仍用该行原字号不放大，颜色维持原 token）；若行头文案与标签不同，**跳过 D2 并在报告里说明**。
D3 严禁引入：渐变、阴影/elevation、光晕、位图资源、新字体文件、新颜色 token、`withValues` 之外未定义的色（坑 105）。

### E. 全仓设计口径自检（**必做**，与 AGENTS.md 第 564-570 行一致，B12 曾漏做）

1. 本次改动涉及的 `withValues(alpha:)` 透明度取值必须在 `theme_tokens.dart` 的 `LightPalette` 字段注释里有对应口径；没有对应口径就改用既有 token，不要自造。
2. 字号/行高/颜色优先走 `Theme.textTheme` / `AppFonts` / `ThemeTokens`；确需覆写（如 B1 的 15px 衬线）必须写成命名常量并在注释里写明「为什么不能走主题槽位」。
3. 图标一律 `Icons.*_outlined` 系（AGENTS.md 第 570 行是例外清单真源）。
4. 间距走既有 `GapTokens` / 文件内 `static const` 度量，**不新增魔法数**。

**报告必须单列一节**：逐项说明 1-4 的符合情况（不符合的写「不符合 + 理由」，不许省略）。

## 3. 交付要求

1. 按 §2 改动；每项落点行号以当前 HEAD `b2b6fbf` 为准。
2. 新用例放 `b13_polish_test.dart`；被样式变更影响的既有断言就地更新并注释来源（「B13 第 N 条」）。
3. 逐文件跑并全绿：`b13_polish_test.dart`、`b12_position_panel_test.dart`、`b12_matrix_tabs_date_test.dart`、`b11_period_date_test.dart`、`b10_blueprint_matrix_done_test.dart`、`b10_position_panel_test.dart`、`task78_b9_brand_panel_test.dart`，报告逐字贴出末行（如 `00:XX +NN: All tests passed!`）。
4. `dart format` 两个 lib 文件与全部测试文件，并跑 `dart format --output=none --set-exit-if-changed` 确认（全路径 `F:\soft\flutter\flutter\bin\dart.bat`）。
5. **不提交**。报告列出 `git status --porcelain -uall` 改动清单，说明每项对应 A/B/C/D/E 哪一条；未涉及的行为变化必须点名说明。
