# 批次 B14 派工书 — 蓝图页观感与配色（用户 2026-11-27 口述四条）

> **唯一实现契约**。worker 拿到本书后不得自行扩大范围；本书比计划正文优先。
> 控制器不碰 `apps\**` / `packages\**`（R1），下列改动全部由 worker 落盘。
> 基线：HEAD = `dcce549`（B13 收口），`flutter analyze` 逐字 `No issues found!`，
> `flutter test --reporter compact` = **`+1012`**（新增用例只许加不许减）。

## 0. 用户原话（逐条对应本书条目）

1. 「在目标模块，标签的 终极、长期等等，都添加文字“目标”」
2. 「目标内容，点击铅笔图标，不用弹窗编辑，而直接编辑目标内容，简化掉标题、备注、关键词等等，
   修改表格列宽度比例，自适应内容。尽量保持起止日期在一行中显示」
3. 「再次美化标签，当前在第一个标签被选中时，标签背景色和模块背景色融于一体，看不出标签形状了」
4. 「制作浅绿色主题、浅蓝色主题，在设置中，添加主题选择」

## 1. 控制器已坐实的事实（worker 直接引用，不必重新勘察）

| # | 事实 | 证据（盘上回读） |
|---|---|---|
| F1 | 矩阵档位标签条**真源是 `_tabStrip`**（浏览器标签风格），在 `goal_blueprint_matrix.dart` L331 定义、**L225 唯一调用点** | `reports\task99-b14-facts.txt` L3-37；grep `_tabStrip\(` 只命中 225/331 |
| F2 | **活动标签底色 = `tokens.card`，非活动 = `tokens.sunken`**（L390）。卡片/内容区本身也是 `tokens.card` ⇒ 活动标签与模块内容区**同色**，只靠「无下边框」区分 —— 这就是用户第 3 条「融于一体、看不出标签形状」的根因 | 同上 L60-63 |
| F3 | 标签条容器 `color: tokens.paper`（L338），整条用 `FittedBox(scaleDown)` 兜底防溢出（L340-342）；非活动标签用 `tabInactiveLift` 抬高 | 同上 L8-36 |
| F4 | `goal_brand_panel.dart` 内另有**第二套**档位标签（`_kOnBg` 胶囊 + `_tierShort()`，硬编码中文 `近期/远期/中期/短期`）；`_TierBadgeStrip` 与 `_tierShort` **不在** matrix 文件里 | grep `class _TierBadgeStrip` / `_kOnBg` 命中 goal_brand_panel.dart，matrix 0 命中 |
| F5 | 矩阵里**同时存在**旧的 `_pillTabs`（L248 `ValueKey('goal-blueprint-tabs')`，胶囊风格）与新的 `_tabStrip`（L225 调用），`_pillTabs` 已是死代码 | `reports\task99-b13-layout.txt` |
| F6 | 起止日期单元格 `_dates()`：`Text(_periodText(goal))` + 下方 `_track()` 日期条 + 可选「完成：」行 + 可选编辑按钮，**四段纵向堆叠**；`_periodText` 在 760 列宽下会折行 | facts.txt L73-126 |
| F7 | 铅笔按钮 `goal-blueprint-period-{id}`（L599-600，`_compactButton(Icons.edit_outlined)`）→ `onEditGoalPeriod` → 页面 `_startEdit()`（`goals_blueprint_page.dart` L415）→ `_openEditorFor`（L357）→ **`showDialog` 全量表单**（标题/备注/关键词/领域/期限五字段，宽 2000 上限） | goals_blueprint_page.dart L310-429 |
| F8 | 表单落库走 `_writeGoal(existing, form)`（L463），字段 `title/note/keywords/domain/dueDate`；`_periodEndFor(dueDate, periodStart)`（L473）把期限同步写 `period_end`（B12 第 3 条根因裁决，**不得回退**） | 同上 L165-183 |
| F9 | 主题单一真源链：`AppTheme.light(density)` / `.dark(density)`（`app_theme.dart` L26-29）→ `ThemeTokens.light/.dark` → `ColorScheme.fromSeed(seedColor: tokens.ink)` 后覆盖 ~24 slot（L34-60）。**刻意不设 cardTheme/dialogTheme/chipTheme**（L9-12 注释：Flutter 3.47 类型摇摆），外观一律显式引 `context.tokens.<字段>` | `app_theme.dart` L2-60 |
| F10 | 设置页主题选择是**三枚 `_ChoiceChip`**（system/light/dark），写法：`selected: prefs.themeMode == ThemeMode.light` + `onTap: ref.read(preferencesStoreProvider).setThemeMode(...)`，chip 键 `settings-theme-light` / `settings-theme-dark`（L200-217）；语言区紧随其后（L223-250） | facts2.txt L35-81 |
| F11 | 视觉模型（describe_images）已确认在屏幕上的真实缺陷：中文**孤字折行**（「普世主/义」「坚/持」）、`—` 当占位符、`✓`/`○` 文本字符当图标（today_page L854）、Banner 副标题与档位标签条**信息重复**、字号字重主次倒错 | `reports\task99-vision-out.txt` |
| F12 | 取帧装置 `reports\task99-capture-b14.ps1` 可用：`PostMessage WM_KEYDOWN/UP + VK=0x31..0x37 + FWODOWN` 不抢焦点切页，`PrintWindow(flags=2)` 出帧，`DESKTOP=Default` 前置校验 | 本轮实跑 `CAP_EXIT=0`，帧 `6A40222AF4304615` |
| F13 | 壳级快捷键 `Ctrl+1..7` 在 `app.dart` L243-258，today/inbox/habits/calendar/projects/goals/blueprint | app.dart |

**尚未坐实、worker 必须先定位再动手的点**（不许照抄本书措辞当结论）：

- U1 档位标签**实际文案源**：`_tabStrip` 的标签文字取自何处（`_horizonLabel`? `t.goalBlueprintHorizon*`? 硬编码?），
  以及 F4 第二套 `_tierShort()` 到底渲染在哪个界面（个人定位卡内的胶囊）。grep 后写进回报。
- U2 用户说的「终极」对应数据层哪个 `GoalHorizon` 值（`tabs` 顺序 = 终极/远期/中期/短期 还是 近期/远期/中期/短期）。
- U3 英文态对应文案（l10n 是 zh/en 双份，改文案必须两边都改）。

## 2. 条目 1 — 档位标签补「目标」二字

**判据**：四个档位标签在中文态逐字显示 `终极目标 / 远期目标 / 中期目标 / 短期目标`；
英文态显示 `Ultimate / Long-term / Mid-term / Short-term Goal`（单数 Goal，与中文对齐）。

- 若 U1 定位为 l10n 键，改 `l10n\parts\goals.dart` 的 zh/en 两份；若是硬编码，改成走 l10n（不许再新增硬编码中文）。
- **同步改 F4 第二套标签（`goal_brand_panel.dart` `_tierShort()`）**：若它确实渲染在界面上，
  文案必须与矩阵**一字不差**；若 grep 证明它是死代码，改为**复用同一 l10n 源**或直接删除该函数
  （删除属 R4 之外的函数级清理，允许；不许删文件）。
- **宽度红线**：标签条有 `FittedBox(scaleDown)`（F3），加二字后 760 宽会触发缩放 ⇒
  必须实测：改后跑 `b13_polish_test.dart` 与 `b10_position_panel_test.dart`；
  若衬线 12px 标签缩放后 < 11px，则把 `_tabPadding` 从 18 回调到 14，或字号维持 12 但允许标签两字一行。
  **回报里必须给出「760 宽下实际缩放比例」这个数字**（从 widget 尺寸断言取，不许目测）。
- 既有 `ValueKey('goal-blueprint-tab-{key}')` **不许改名**（测试与取帧靠它）。

## 3. 条目 3 — 档位标签选中态（与条目 1 同一改动面，先做这条）

用户判定：选中时与模块背景融为一体，看不出标签形状。F2 已坐实根因是
`backgroundColor: active ? tokens.card`（与内容区同色）。

**目标观感**：既保持「浏览器标签连着内容区」的隐喻，又让选中态**一眼可辨**。
推荐形态（worker 可实现得更细，但必须满足判据）：

1. 活动标签底色改为**主墨/强调色的淡染**（浅色态 `tokens.inkWash` 一类，**不得**仍是 `tokens.card`），
   并加**顶部 3px 实色条**（`tokens.accentGreen` 或 `tokens.ink`）；
2. 活动标签文字**升重**（`FontWeight.w600` 或以上）+ 主墨色；非活动维持 `tokens.meta`；
3. 非活动标签保留下沉色 + 抬高，形成明确的高低/明暗双重差；
4. 深色态给对称实现（不得只在浅色态生效）。

**硬判据（必须写成 widget 断言，落 `test\b14_theme_test.dart`）**：

- 活动标签 `backgroundColor` **不等于**其所在卡片/内容区底色（用 `Material`/`Container` 取色断言，
  不是「看起来不同」）；
- 活动标签存在顶部指示条（找到该装饰 widget 或 `BoxDecoration.border` 的 top 边，颜色非透明）；
- 活动标签文字 `fontWeight` **严格大于** 非活动标签；
- 对比度：活动标签文字色 vs 活动标签底色，**WCAG 相对亮度比 ≥ 4.5:1**（测试里用
  `(a,b) => ((math.max(l1,l2)+0.05)/(math.min(l1,l2)+0.05))` 现算，不许写死结论）。

## 4. 条目 2 — 就地编辑目标内容（本书风险最高的一条）

用户判定：点铅笔不该弹窗，应直接编辑目标内容；弹窗里的标题/备注/关键词等字段要简化掉；
列宽按比例自适应内容；起止日期尽量一行显示完。

### 4.1 交互改造

- 目标内容列的文本**常态就是可点击文本**（不再需要先点铅笔）：`GestureDetector` 包裹 +
  `MouseRegion` 手型光标 + hover 淡染底（复用 `goal_brand_panel.dart` 的 `hoverFade` 隐式动画范式）。
- 点击 → **原地切 `TextField`**（同位置、同字号、行高不变，避免跳动），
  初始值 = 当前标题，`autofocus`，光标置末。
- 提交：`Enter` 或焦点移出（失焦）⇒ 落库；`Esc` ⇒ 放弃回滚。IME 保护**必须复用既有守卫**
  （`TextField` 的 IME 组合态判断，见 `b11_ime_guard_test.dart` 的口径），
  组合中不许提交、不许 setState 重建导致焦点丢失。
- 新增目标仍走「+ 新增目标」按钮，但**不得再弹全量表单**：改为在该档位**行尾追加一条空可编辑行**，
  就地输入标题回车即建。若实现代价过大，允许保留对话框但必须**只留「目标内容」一个字段**
  （裁决写进回报，不许默默选难的那条）。
- `_writeGoal` 的写入语义**保持不变**：就地编辑只写 `title`，
  `note/keywords/domain/dueDate/period_end` 传**原值**（不得清空、不得写 null）。
  这条必须有断言：编辑标题后 `note` 与 `period_end` **逐字未变**。

### 4.2 表单简化（弹窗侧同步）

`goal_form_dialog.dart` 的字段区（L167 起）：

- 保留：目标内容（原「标题」，文案改成蓝图页口径）、起止/期限、领域。
- 去掉或折叠：`备注`、`关键词`（以及其它非必要字段）。
- **裁决走「条件渲染」而非「删参数」**：给表单加一个 `compact`（或 `mode`）开关，
  蓝图页传紧凑态、周/月页仍传全量。理由：三页共用同一表单（文件注释已写明），
  周/月页依赖 note/keywords（§11.16 第 2 条刚把「方法和措施」改成读 `goal.note`）。
  **不许**为了让蓝图页简洁而破坏周/月页现有判据。
- 英文态同步。

### 4.3 列宽与日期单行

- 矩阵列宽改成**显式比例**（例：内容 : 领域 : 起止 : 达成 ≈ 自适应权重），
  要求「按内容自适应」而不是均分：列宽由 `Flex` 权重 + 内容测量共同决定，
  窄视口下允许优先压缩「领域」列。
- 起止日期：**`起始 ~ 结束` 必须单行显示完**，不许折行、不许截断成 `11/2… …11/2…`。
  实现方向（选一并给理由）：日期用紧凑格式（`MM-dd`，中间一个 `–`）/
  `textScaler` 不参与该列缩放 / 单行 `softWrap: false` + 允许列变宽 /
  `FittedBox(scaleDown)` 兜底。
- 与 B13 的图标化方案（`goal-blueprint-period-icon` + Tooltip）**如何取舍由 worker 裁决**，
  但裁决必须落在「用户能一眼读Complete起止、且不折行」这一判据上；
  若保留图标 + 单行文字并存，两者不得重复占位。
- **既有 `ValueKey('goal-blueprint-period-text-{id}')` 的测试断言要同步更新**，
  不许直接删测试来让门禁绿。

## 5. 条目 4 — 浅绿色 / 浅蓝色主题 + 设置页主题选择

### 5.1 设计（遵循 F9 的既有链路，不许另起炉灶）

- 新增一个「配色/主题风格」维度（建议命名 `AppAccent`，值 `ink`(默认，现墨绿) / `green`(浅绿) / `blue`(浅蓝)）。
- **真源必须仍只有一处**：在 `ThemeTokens` 上按 accent 派生（例：`ThemeTokens.lightFor(accent)`），
  淡彩主题 = 纸面 `paper` 带极淡对应色相（绿 #F5F8F1 量级 / 蓝 #F2F6FA 量级）、
  主墨 `ink` 转对应深色调、`inkWash`/`accentGreen`/`accentBlue` 等强调 slot 同步换相、
  赭石 `accentInk`（缺口/告警）**三个主题都保持不变**（它承担语义，不能被染色）。
- `AppTheme.light/dark` 接 accent；`MaterialApp` 侧按偏好装配；**深色态同样要给三个 accent 的对称实现**
  （深色下只换强调相，纸面仍深褐/深墨，避免整屏变彩）。
- 持久化：`AppPreferences` 加字段 + `preferencesStoreProvider.setAccent()`，
  读写口径与 `setThemeMode` 完全对称（F10）。存量用户**默认值必须 = `ink`**，
  升级后观感零变化（不得默认换成浅绿/浅蓝）。

### 5.2 设置页 UI

- 在「主题」`_SettingRow` 之后新增一行「配色」，三枚 `_ChoiceChip`，
  chip 键固定 `settings-accent-ink` / `settings-accent-green` / `settings-accent-blue`，
  文案走 l10n（`墨绿（默认）/ 浅绿 / 浅蓝` + 英文），风格与既有主题/语言行**完全一致**（同 spacing=8/runSpacing=8、同 `AppTokens.gapSec` 收尾）。

### 5.3 硬判据（落 `test\b14_theme_test.dart`）

- 三个 accent 的**纸面色互不相同**，且各自 ink↔paper 对比度 **≥ 7:1**（正文级）；
  `tokens.meta` vs `paper` ≥ 4.5:1。
- `ThemeMode.light/dark × accent × density` 全组合调用 `AppTheme.light/dark` **不抛异常**，
  且各组合的 `scaffoldBackgroundColor` 与该 accent 的 `tokens.paper` **逐字节相等**
  （防止「token 改了但 ThemeData 某处漏钉」）。
- 设置页三枚 chip 可点，点击后 `prefs.accent` 变化且**持久化往返一次仍正确**
  （复用既有偏好持久化测试范式）。
- 存量兼容：默认偏好下 `accent == ink`，且该状态下全部 token 与改动前**逐字节相等**
  （用 `ink` 档断言几个关键色值常量钉死）。

## 6. 全局约束（条目之间共用）

- **禁**：`setState(() => setState(...))` 嵌套；`while(true)` 扫描；新增第三方依赖；
  `git add -A`；改 `apps\**` 之外的产品代码前先确认写集归属。
- 每个条目**独立可回滚**：条目 5（主题）与条目 1/3（标签）与条目 2（就地编辑）不要互相牵连。
- **不许回滚 B13 已收口的改动**：四框等高（66.925/63.425/66.925）、标签衬线字族 + 12px、
  分栏线 `hairSoft` 0.5px（§11.16 第 1/3 条裁决）。
  若条目 1 的「加二字」与四框等高或 760 宽度红线冲突，**必须报给控制器**（写进回报），不许自行放宽。
- `docs\relay*` / `docs\b8*` / `docs\incident-*` 是并发接力链的在制品，**不得改、不得 add**。
- 新增/改动的 `reports\**\*.ps1` 必须**纯 ASCII**（R2）；中文载荷走 `.txt`/`.md`/`.json`。

## 7. 验收（worker 回报必须逐条给数字，不许写「已完成」）

1. `flutter analyze` 退出码 + 输出末行逐字。
2. `flutter test --reporter compact` 末行（期望 `+1013..1020` 区间内，**不得 < +1012**）。
3. 新增测试文件与用例名清单。
4. 条目 1/3/5 各自的硬判据实测数字（缩放比例、对比度值、色值等）。
5. 条目 2 的「编辑标题后 note/period_end 未变」断言位置与结果。
6. 需要改既有测试口径的地方逐条列出（改了什么、为什么、原断言）。
7. U1/U2/U3 三个未坐实点的 grep 定位结论。
8. 任何与 §6 红线冲突而**未解决**的点，明确标注为「遗留」，不许含糊带过。

回报正文写进 `reports\task100-b14-report.md`，并在最终消息里给出该文件路径与关键数字。

---

## 勘误（2026-11-27 stage 3 回读）

> 本节由接力链 **stage 3 / `b14-dispatch-erratum`** 会话 `mvs_8da97fb4cf0b4e9d8ed398b176c4de3e` 追加；上方 §0–§7 原文**一字未改**（追加前后前缀 sha16 见本节末尾追加块）。
> 裁决依据：`docs\b15-plan.md` §1「唯一真源与优先级」+ `AGENTS.md` §2 R1（控制器不改实现代码）/ R5（证据纪律）。
> **三条勘误全部是「文档瑕疵」**：契约正文与盘上实现不符，**判定以盘上实现为准，产品代码一个字都不许改**。
> 证据一律当场回读盘上文件并标出 `路径:行号`；本节不引用任何摘要转述。

### 勘误 1 · §6「标签衬线字族 + 12px」（§2 另有同源一处）—— 盘上是 **15px**

**(a) 契约原文**

`docs\b14-dispatch.md` §6「全局约束（条目之间共用）」第 165–166 行逐字：

```text
- **不许回滚 B13 已收口的改动**：四框等高（66.925/63.425/66.925）、标签衬线字族 + 12px、
  分栏线 `hairSoft` 0.5px（§11.16 第 1/3 条裁决）。
```

同一处过期数字在 §2「条目 1 — 档位标签补「目标」二字」第 52 行也出现一次（逐字）：

```text
  若衬线 12px 标签缩放后 < 11px，则把 `_tabPadding` 从 18 回调到 14，或字号维持 12 但允许标签两字一行。
```

**(b) 盘上实际**

`apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart:181`：

```dart
  static const double _tabFontSize = 15;
```

- 使用点：同文件 `:549` → `fontSize: GoalBlueprintMatrix._tabFontSize,`
- 「衬线字族」那半句**是对的**：同文件 `:550`–`:551` → `fontFamily: AppFonts.display,` / `fontFamilyFallback: AppFonts.displayFallback,`
- **HEAD 同值，不是回滚**：`git show HEAD:apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` 第 181 行逐字为 `  static const double _tabFontSize = 15;` ⇒ 已提交版本本身就是 15，本仓不存在「12px 被回滚成 15px」这回事。
- 旁证：`docs\handoff-ledger-b9-w4.md:773` 记的 `_tabFontSize=15`（:173）是 **B13 当时的行号**，B14 插行后已漂到 `:181`，旧行号不可再引用。

**(c) 判定**

**文档瑕疵**（契约把 B13 已收口的字号写成 12px）。**产品代码不改**：把 15 改回 12 才是回滚 B14 之前的 B13 收口成果，与该条自己写的「不许回滚 B13 已收口的改动」正面相冲突，且会撞 760 宽红线（stage 4 的余量判据）。契约的**意图成立、只有那个数字写错**。勘误后应表述为：标签衬线字族 `AppFonts.display` + **15px**；`_tabPadding` 维持 `18`（同文件 `:187`）。

### 勘误 2 · §4.3「内容 : 领域 : 起止 : 达成」—— 盘上是 **三列**

**(a) 契约原文**

`docs\b14-dispatch.md` §4.3「列宽与日期单行」第 114–116 行逐字：

```text
- 矩阵列宽改成**显式比例**（例：内容 : 领域 : 起止 : 达成 ≈ 自适应权重），
  要求「按内容自适应」而不是均分：列宽由 `Flex` 权重 + 内容测量共同决定，
  窄视口下允许优先压缩「领域」列。
```

口径说明（为免歧义）：**「四列」三个字在契约正文里并未出现**，它以「四段比例示例」的形式出现——上例四项 `内容 : 领域 : 起止 : 达成` 就是四列口径。台账 `docs\handoff-ledger-b9-w4.md:1027` 记的「§4.3『四列』实为 3 列」即指此。本勘误按「四列口径」定性。

**(b) 盘上实际**

`apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart:204`：

```dart
  /// 三列宽度比例（领域 : 目标 : 起止），B14 第 2 条显式钉死。
```

同文件 `:209` / `:212` / `:215`：

```dart
  static const double columnFlexDomain = 2;
  static const double columnFlexGoal = 5;
  static const double columnFlexPeriod = 4;
```

同文件 `:218`–`:223`（**列数的硬证据**）：

```dart
  static const Map<int, TableColumnWidth> columnWidths =
      <int, TableColumnWidth>{
        0: FlexColumnWidth(columnFlexDomain),
        1: FlexColumnWidth(columnFlexGoal),
        2: FlexColumnWidth(columnFlexPeriod),
      };
```

- `columnWidths` **只有 0 / 1 / 2 三项** ⇒ 矩阵是**三列**：领域 / 目标 / 起止；契约示例里的第 4 项「达成」**没有对应列**。
- 表头行（`:369`–`:385`）与数据行（`:386` 起）共用同一套 `columnWidths`（`:370`、`:387`）⇒ 不存在「第四列换另一种承载方式」的空间。

**(c) 判定**

**文档瑕疵**（契约的列比例示例是 B14 落地前的设想稿，与已收口的实现不符）。**产品代码不改**：三列比例 2 : 5 : 4 是 B14 第 2 条「显式钉死」的既成实现，且 `columnWidths` 是年刻度条与主表共用的单一真源；为凑文档加第四列会改动已收口的布局并牵动 760 宽红线。勘误后应表述为：矩阵为**三列 领域 : 目标 : 起止**，比例 **2 : 5 : 4**。

### 勘误 3 · §2 英文示例只给末档加 `Goal` —— 实现**四档全带** `Goal`

**(a) 契约原文**

`docs\b14-dispatch.md` §2「条目 1 — 档位标签补「目标」二字」第 43–44 行逐字：

```text
**判据**：四个档位标签在中文态逐字显示 `终极目标 / 远期目标 / 中期目标 / 短期目标`；
英文态显示 `Ultimate / Long-term / Mid-term / Short-term Goal`（单数 Goal，与中文对齐）。
```

英文示例里 `Goal` **只出现在末档 `Short-term` 之后**，前三档没有。

**(b) 盘上实际**

`apps\desktop\lib\src\l10n\parts\goals.dart` 英文实现（第 1449 / 1452 / 1455 / 1458 行逐字）：

```dart
  String get goalBlueprintHorizonUltimate => 'Ultimate Goal';
  String get goalBlueprintHorizonLong => 'Long-term Goal';
  String get goalBlueprintHorizonMid => 'Mid-term Goal';
  String get goalBlueprintHorizonShort => 'Short-term Goal';
```

接线点 `apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart:586`–`:591`：

```dart
  String _horizonLabel(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => widget.t.goalBlueprintHorizonUltimate,
    GoalHorizon.long => widget.t.goalBlueprintHorizonLong,
    GoalHorizon.mid => widget.t.goalBlueprintHorizonMid,
    GoalHorizon.short => widget.t.goalBlueprintHorizonShort,
    GoalHorizon.near => widget.t.goalBlueprintHorizonNear,
  };
```

标签页档位（同文件 `:149`–`:154`）**四个**：终极 → 远期 → 中期 → 短期；`near` 不进标签页（`:594` 注释自述「near 不进标签页，兜底用短期那条」）。

中文侧 `apps\desktop\lib\src\l10n\parts\goals.dart:830` / `:833` / `:836` / `:839` 逐字为 `终极目标` / `远期目标` / `中期目标` / `短期目标`，**与契约中文侧逐字一致** ⇒ 差异只出在英文侧的 `Goal` 出现位置。

**(c) 判定**

**文档瑕疵**（契约英文示例是示意写法，把 `Goal` 只挂在末档）。**产品代码不改**：改实现去凑契约示例，等于把四档英文标签削成「只有末档带 Goal」，与用户原话「都添加文字『目标』」及契约自身「英文态同步」的要求相悖；中文侧逐字正确，产品无缺陷。勘误后应表述为：英文态四档分别为 `Ultimate Goal / Long-term Goal / Mid-term Goal / Short-term Goal`。

### 本节写集与证据

| 项 | 值（盘上回读） |
|---|---|
| 本环允许写集 | `docs\b14-dispatch.md`（**追加**本节）；`apps\**` / `packages\**` / `AGENTS.md` / `reports\**` / `docs\relay\stage-2-blocked.md` **零改动** |
| 本文件追加前 | **15,645 B** / **182 行** / sha16 `07CF80640BC05B25` / mtime 2026-11-27 00:07:14 / 纯 LF（CRLF 计数 = 0） |
| `apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart` | 50,052 B / sha16 `0F99C0C569AA3981` / mtime 2026-11-27 01:14:44（追加前后逐字相同 ⇒ 本环零改动） |
| `apps\desktop\test\b14_theme_test.dart` | 19,173 B / sha16 `88C2CD3A6B5FABD8`（stage 2 产物，本环零改动） |
| `apps\desktop\test\b14_tab_scale_test.dart` | 21,045 B / sha16 `28E2160B3B9F6D4C`（本环零改动） |
| git 写操作 | **一次都没做**（commit / push / tag / stash / checkout 全属人工验收点） |
| 测试 | **没跑**：本环零代码改动，跑 `flutter test` 证明不了文档勘误成立，只会引入无关噪声 |

本节追加后的完整落盘回读（最终字节数 / 行数 / sha16 / 前 15,645 B 前缀 sha16）由控制器在本节末尾以**追加块**给出，不改本块已写内容。

### 落盘回读（stage 3 控制器，追加于本节末）

> 本块**只追加**、不改上文任何字节。上文表格记的是「追加前」指纹，本块给的是**实测值**。

| 项 | 实测值（2026-11-27 盘上回读） |
|---|---|
| 追加前文件 | 15,645 B / 182 行 / sha16 `07CF80640BC05B25` / mtime 2026-11-27 00:07:14 |
| 追加勘误节后（本块写入前） | **24,131 B / 331 行 / sha16 `865B43C2A762017B`** |
| 前 15,645 B **前缀** sha16 | **`07CF80640BC05B25`** —— 与追加前整文件 sha16 **逐字相同** ⇒ 原有字节**零改动**，追加只发生在文件尾 |
| 行尾格式 | CRLF 计数 = 0 / 纯 LF / 无 BOM（与追加前一致） |
| git 越界比对 | 本环新增改动**仅** ` M docs/b14-dispatch.md`；`apps\**` / `packages\**` 仍只有 stage 2 留下的 ` M apps/desktop/test/b14_theme_test.dart`（19,173 B / sha16 `88C2CD3A6B5FABD8`，本环未动） |
| 产品文件 | `apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart` 50,052 B / sha16 `0F99C0C569AA3981` / mtime 2026-11-27 01:14:44 —— **追加前后逐字相同**，本环零改动 |

本块写入后的**最终**字节数 / 行数 / sha16 见 `docs\relay.json` 的 `stages[2]` 条目与 stage 3 收口回报（文件本体不再自我引用，避免自指）。
