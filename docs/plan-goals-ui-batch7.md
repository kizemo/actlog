# Task 72 · 目标体系 UI 补充四则（批次 7）设计与派工

> 立项依据：用户 2026-11-25 14:32 逐字下达的四条补充要求（见 §1）。
> 本文件是本轮**唯一实现契约**（AGENTS.md §2 R8）：worker 只认本文件 + AGENTS.md。
> 冲突优先级：用户当轮决定 > 本派工书 > handoff/progress 转述。

## 1. 需求原文（用户逐字）

1. 调整页面左边栏，**去除左边栏底部切换页面快捷键显示**；把**人生蓝图单独提取出来，设定为独立页面**；
2. **月目标设定页面显示右边栏**，显示仍然未完成的**年目标**，可**点击或拖动**添加到月目标；
3. **周目标设定页面显示右边栏**，显示仍然未完成的**月目标**，可**点击或拖动**添加到周目标；
4. **日志主页面右边栏**中添加仍然未完成的**周目标**，可点击或拖动添加到**计划**中，也可在**日计划右键勾选**添加。

需求 2/3/4 是 Task 65 遗留挂账「三通道联动 + 今日右栏第 5 面板」的具体化；需求 1 **推翻**既有导航裁决
D-62-c（原裁决：左栏只加 1 项「目标」，周｜月｜年｜蓝图四页签同页切换）。用户当轮决定优先级最高，
旧裁决作废并在台账登记订正。

## 2. 取证事实（本轮实测，file:line 为准）

| 落点 | 证据 |
|---|---|
| 左栏底部快捷键显示 = 「导航底注」 | `apps\desktop\lib\src\widgets\shell\nav_rail.dart:428-560`（`_NavFoot` 类 + `KeyCap`），渲染挂载点 `nav_rail.dart:138` `..add(_NavFoot(t: t))`（宽屏 `_buildColumn` 内） |
| 导航项两处清单 | `nav_rail.dart:38` `kShellNavItems`（`:44` goals）、`nav_rail.dart:53` `shellNavItemsFor()`（`:59` goals，走 l10n） |
| 页面内容映射 / 深链 / 快捷键 | `app.dart:345` `_content()` switch、`app.dart:168` `'/goals'` 深链、`app.dart:240` 段 `shortcuts` map（`Ctrl+1…6` → `_NavIntent`）、`app.dart:252` `_NavIntent('goals')`、`app.dart:363-370` 注释口径 |
| 目标页壳（四页签） | `pages\goals_page.dart`（231 行）：`:88-98` `_GoalsTabBar`、`:94` `kGoalsTabBlueprint: t.goalsTabBlueprint`、`:105-116` `_buildBody()` 四分支 |
| 页签偏好 | `providers.dart:256` `settingsKeyGoalsTab`、`:268/275` `kGoalsTabBlueprint` 与白名单、`:405` `AppPreferences.parseGoalsTab`、`:439` 加载、`:506` 写侧、`:577` `goalsTabSaverProvider` |
| 蓝图页体 | `pages\goals_blueprint_page.dart`（`GoalsBlueprintPage`，顶层 `Column`，`:108/:116` 周期换算，`:129` `store.listGoals()`） |
| 月页 / 周页顶层布局 | `pages\goals_month_page.dart`（548 行，`:221/:311` 顶层 `Column`）、`pages\goals_week_page.dart`（284 行，`:51/:93` 顶层 `Column`）——**当前均无右栏** |
| 今日右栏面板清单 | `app.dart:386-421` `todayRailPanels(context)` 返回 `List<ShellRailPanel>`（现有 4 块：待办清单 / 习惯 / 循环任务 / 闭环提示）；壳侧 `ledger_shell.dart:33-34/69-72/109-122/180-184`、`ToolRail` |
| 拖拽先例（发起侧） | `pages\today_page.dart:840-844` `Draggable<String>` + `pointerDragAnchorStrategy` + `_HabitDragChip` |
| 拖拽先例（接收侧） | `widgets\timeline\day_grid.dart:339-341` `onWillAcceptWithDetails` / `onAcceptWithDetails`（`DragTarget<String>`，日格 = 计划落点） |
| 右键菜单先例 | `pages\today_page.dart:332` `showMenu<_DateTimeActionKind>` |
| 「未完成」口径依据 | `packages\core_domain\lib\src\goal.dart:77-97` `enum GoalStatus{... done}` + `isDone`、`:763` `status`、`:689` 归档不变式（非 done 不得带 `archivedAt`）、`:795` `GoalRow.isDone` |
| 查询能力 | `apps\desktop\lib\src\data\goal_store.dart:651` `listGoals({kind,status,period,parentId})`（status 仅**等值**筛选） |
| 「派生下层目标」既有语义 | `pages\goals_year_page.dart:449-480` `_candidates()` + `GoalPeriod.month(...)`（年→月派生）；`goal_store.dart:320` 上周未完成周目标**结转**、`:981` 候选来源（计划 §6.4）、`:912` 列口径 |
| 计划行写入纪律 | `apps\desktop\lib\src\data\project_store.dart:578` 「计划行的账本路径只能有一份，不另写 INSERT」、`:612` 计划行查询 |
| l10n | `l10n\parts\shell.dart:24-44` 抽象 getter + `:110-128` zh + `:188-206` en（`shellNavGoals` 为末位）；`l10n\parts\goals.dart`（83 getter） |
| 受影响测试 | `nav_rail_footnote_test.dart`、`nav_shortcut_test.dart`、`shell_nav_rail_test.dart`、`task64_nav_gear_test.dart`、`task61_l10n_shell_test.dart`、`ledger_dock_test.dart`、`shell_key_bar_test.dart`、`shell_ledger_shell_test.dart`、`task65_goals_week_test.dart`、`task66_goals_blueprint_page_test.dart`、`timeline_day_grid_test.dart`、`rail_todo_list_test.dart`、`today_loop_hint_panel_test.dart`、`l10n_harness.dart` |
| 既有像素判据（会反转） | `tools\gates\*`、`reports\task72-nav-foot-judge.ps1`（原判底注存在）、`reports\task56-keybar-judge.ps1`（右轨 8 条 + 底部 40px 带 0 命中） |

## 3. 设计裁决（控制器定，worker 不得改方向）

**D-72-a 底注只删「显示」，不删「功能」**
`nav_rail.dart` 删除 `_NavFoot` 类（及其 `KeyCap` 辅助类若仅被它使用）与 `:138` 的 `..add(_NavFoot(t: t))`；
`Ctrl+1…7` 快捷键**保留可用**；右轨「快捷键」面板 `KeyHintList`（`key_bar.dart:210`，Task 56 已裁决保留）**不动**。
不删文件（R4）：只删代码段，文件保留。

**D-72-b 蓝图独立成第 7 个导航项**
- 新 nav id = `blueprint`，位置排在 `goals` **之后**（第 7 项）；设置仍沉底成齿轮、不占编号。
- `Ctrl+7` → `_NavIntent('blueprint')`；深链 `/blueprint` → `ShellHost(initialNavId: 'blueprint')`；
  `_content()` 加 `'blueprint' => const GoalsBlueprintPage()`。
- `goals_page.dart` 页签只剩 **周｜月｜年**（删 `:94` 蓝图项与 `:113-114` default 分支的蓝图渲染，
  `_buildBody()` default 回落 `GoalsWeekPage()`）；`GoalsPage` 不再 import `goals_blueprint_page.dart`。
- **兼容旧偏好值**：`providers.dart` 的 `kGoalsTabBlueprint` 常量**保留**（历史值），但
  `parseGoalsTab('blueprint')` 必须回落到默认 `week` —— 老库存过 `blueprint` 的用户进页面不能变空白页。
- l10n 新增 `shellNavBlueprint`（zh `蓝图` / en `Blueprint`），三处（抽象 + zh + en）齐全；英文界面零中文。

**D-72-c 「未完成」口径**
未完成 = `!goal.isDone`（即 `status != GoalStatus.done`）**且** 未归档（`archivedAt == null`）。
实现走 **UI 侧过滤**（`listGoals(kind: ...)` 后 `where`），**不改** `packages\core_db` / `core_data`，
**不新增仓储方法**（沿用 `goal_year_matrix.dart:6` 的「零改动」纪律）。
排序复用 `goal_store` 既有 `_compareGoals` 结果顺序（`listGoals` 已排）。

**D-72-d 三层共用一个组件，不做三份拷贝**
新建 `apps\desktop\lib\src\widgets\goal_upstream_panel.dart`：
- `GoalUpstreamPanel({required GoalKind sourceKind, required GoalPickCallback onPick, ...})`
  内部按 `sourceKind` 拉取未完成上层目标并渲染可点击 + 可拖拽条目；
- 点击 = 调 `onPick(goal)`；拖拽 = `Draggable<String>`（payload 用 goal id，带 `sourceKind` 前缀以区分来源，
  与 `day_grid.dart` 现有 `DragTarget<String>` payload 命名空间**不得冲突** —— 现有通道拖的是 todo id）；
- 空态/加载态/错误态复用 `goals_week_page.dart:220-284` 的 `_LoadingBlock`/`_EmptyBlock`/`_ErrorBlock` 同形态
  （或提为共用私有组件，但不得改动那三个类所在的公开 API）；
- 文案全走 l10n，新增键放 `parts\goals.dart`。

**D-72-e 「添加」语义（三条通道各自复用它已有的既有写入路径）**
| 通道 | 语义 | 必须复用 |
|---|---|---|
| 年→月（需求 2） | 在当前目标月**派生一条月目标**，`parentId`/serves 指向该年目标 | `goals_year_page.dart:449-480` 的派生语义与 `goal_store` 既有创建/关联方法（`link()` `:651+`） |
| 月→周（需求 3） | 在当前周**派生一条周目标**，指向上层月目标 | 同上；结转语义参见 `goal_store.dart:320` |
| 周→计划（需求 4） | 把周目标**排进选中日**，形成/合并 `plan_item` 行并 link 该周目标 | `project_store.dart:578` 的唯一账本路径；**严禁自写 INSERT** |
幂等要求：同一上层目标重复添加**不得产生重复行**（复用 `link()` 的幂等口径）。
添加成功后对应视图**必须可见新增项**（沿用各页既有的重载/失效刷新方式，不引新 provider 框架）。

**D-72-f 双栏改造方式**
月页 / 周页：把顶层 `Column` 包进 `Row`——左内容 `Expanded`、右栏定宽（取 `today_page` / `ToolRail` 既有右栏宽度
口径，不得新造魔法数；窄屏阈值沿用壳层既有断点，窄屏下右栏按壳层既有折叠行为处理，不得把布局写死成仅宽屏可用）。
今日页：新面板追加到 `app.dart:386-421` `todayRailPanels()` 清单**末尾**（第 5 块，「闭环提示」之后还是之前由
worker 依现有视觉层级决定并说明理由，默认放末尾）。

**D-72-g 日计划右键勾选（需求 4 后半）**
在日计划区（`widgets\timeline\day_grid.dart` 的格子/计划行）右键菜单新增「从周目标添加」子集：
用 `showMenu` 列出未完成周目标（勾选式多选），确认后走 D-72-e 的周→计划同一写入路径。
右键菜单先例见 `today_page.dart:332`；不得破坏 `day_grid.dart:339-341` 既有拖放通道。

**D-72-h 判据装置同步订正（防假红）**
- `reports\task72-nav-foot-judge.ps1`：原「底注必须存在」⇒ 反转为「左栏底部**必须 0 命中**」。
- `reports\task56-keybar-judge.ps1`：右轨 8 条判据不变，底部带判据方向一致（本就要求 0 命中）。
- 这两个脚本属 `reports\`，**控制器自己改**（R1 只禁 `apps\`/`packages\`），改后逐字 ASCII 自检。

## 4. 写集划分与并行度（R1）

| worker | 任务 | 独占写集 | 依赖 |
|---|---|---|---|
| **W1** | 需求 1（底注删除 + 蓝图独立页 + 页签三分化 + l10n shell + 受影响测试） | `widgets\shell\nav_rail.dart`、`app.dart`（**仅** nav/路由/shortcuts/`_content`/`_railPanels` 以外的导航段）、`pages\goals_page.dart`、`providers.dart`（`parseGoalsTab` 回落）、`l10n\parts\shell.dart`、`l10n_keys.dart`、测试 `nav_rail_footnote_test.dart`/`nav_shortcut_test.dart`/`shell_nav_rail_test.dart`/`task64_nav_gear_test.dart`/`task61_l10n_shell_test.dart`/`shell_ledger_shell_test.dart`/`task66_goals_blueprint_page_test.dart` | 无 |
| **W2** | 共用基建：`goal_upstream_panel.dart` 组件 + 未完成过滤 + 组件单测 + l10n goals 键 | **新建** `widgets\goal_upstream_panel.dart`、**新建** `test\task72_goal_upstream_panel_test.dart`、`l10n\parts\goals.dart`、`l10n_keys.dart`（**仅追加新键**） | 无 |
| **W3** | 三处接线：月页双栏、周页双栏、今日右栏第 5 面板、日计划右键勾选 | `pages\goals_month_page.dart`、`pages\goals_week_page.dart`、`app.dart` 的 `todayRailPanels()` 段、`widgets\timeline\day_grid.dart`、相关测试 | **W1 + W2 完成** |

⚠️ 冲突纪律：`l10n_keys.dart` 与 `app.dart` 被多个 worker 触碰 ⇒ **W1 与 W2 并行时，
`app.dart` 只允许 W1 写；`l10n_keys.dart` 键数计数断言（`l10n_base_test.dart`）由最后一棒 W3 统一校准**。
若 W1/W2 都必须改 `l10n_keys.dart`，W2 只做**追加**、W1 不动该文件（shell 新键也交给 W2 追加，
W1 只声明并使用 getter）——见派工书正文。

## 5. 门禁与基线影响（R2）

- `flutter analyze` 必须**逐字** `No issues found!`（三个包各自跑）。
- desktop 测试基线当前 **+882**、core_data **+204**：本轮删底注测试、新增组件测试 ⇒ 数字必然变化。
  收口以**实际末值**为准，跑门禁时传真实 `-ExpectDesktopTests <n>` 并回填台账与 AGENTS.md。
- 跑门禁前先 `Move-Item` 改名挪走 `apps\desktop\build\test_cache\build`（R2 / 坑 OS Error 183）。
- `.ps1` 纯 ASCII；Dart 源 LF、无 BOM、`print(` 计数 0。

## 6. 验收判据（判据 → 装置 → 期望）

| # | 判据 | 装置 | 期望 |
|---|---|---|---|
| 1 | 逐包 analyze 零问题 | 三遍 `flutter analyze` | 逐字 `No issues found!` |
| 2 | 全量测试 | `reports\task51-gate.ps1 -ExpectDesktopTests <n>` | `GATE_VERDICT=PASS` |
| 3 | 左栏底注已消失 | 新建 `task72-nav-foot-judge.ps1` + 真机取帧 | 底注 0 命中 / 帧内可见导航项无 `Ctrl` 键帽行 |
| 4 | 蓝图独立页可用 | `task71-tabs-capture-v3.ps1` 改版（导航到蓝图项） | 真机帧显示蓝图矩阵且非页签 |
| 5 | 月/周页右栏显示未完成上层目标 + 点击生效 | 新增 widget test + 真机取帧 | 面板存在、点击后下层派生目标出现 |
| 6 | 今日右栏第 5 面板 + 拖入计划 + 右键勾选 | 新增 widget test + 真机取帧 | 三种添加路径各至少 1 条断言，幂等 1 条 |
| 7 | 真机确认 | 两阶段出货 + 覆盖装机 + 取帧 | `app.so` 逐字节一致 + `VERDICT=FRAME_OK` |

## 7. 派工书索引

- `docs\b71-dispatch-w1-nav.md` — W1 导航与蓝图独立页
- `docs\b71-dispatch-w2-panel.md` — W2 共用未完成目标面板组件
- `docs\b71-dispatch-w3-wire.md` — W3 三处接线与日计划右键（W1/W2 后派发）
