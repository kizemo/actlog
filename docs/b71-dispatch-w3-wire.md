# 派工书 · B7-W3「今日右栏未完成周目标 + 日计划右键勾选添加」

> 真源：`docs\plan-goals-ui-batch7.md`（需求 4；裁决 D-72-c / D-72-e / D-72-g）。本派工书是唯一实现契约。
> 前置：**W1 已入库**（`weekOpenGoalsProvider`、`goalsUpstream*` 文案、`widgets\week_goal_rail_panel.dart` 占位、`app.dart` 第 5 面板槽位）。地基缺失 ⇒ 立刻 BLOCKED 上报，不要自己补。
> 与 **W2 并发执行**：见 §0.4 并发纪律。

## 0. 环境与硬约束

### 0.1 上下文
- 仓库根 `F:\soft\00selfmade\practilog`。开工第一件事：完整读 `AGENTS.md`，再读 `docs\plan-goals-ui-batch7.md` 全文。
- 需求原文（用户 2026-11-25 逐字）：「在日志主页面，右边栏中添加仍然未完成的周目标，可以点击或拖动添加到计划中，也可以在日计划右键勾选添加。」⇒ 三条通道都要成立：**点击添加**、**拖拽添加到计划**、**日计划右键勾选添加**。

### 0.2 写集纪律
只许改 §1 表内文件。**严禁**改：`packages\**`、`apps\desktop\lib\src\app.dart`、`widgets\shell\**`、`providers.dart`、`l10n\**`（含 `l10n_keys.dart` 与所有 parts）、`test\l10n\**`、`test\shell\**`、`pages\goals_page.dart`、`pages\goals_*_page.dart`、`widgets\goal_upstream_panel.dart`、`test\pages\goals\**`、`AGENTS.md`、`handoff.md`、`progress.md`、`release\**`、`tools\**`、`reports\**`。
不许新增 package / 依赖 / `flutter pub get` / `flutter clean`。

### 0.3 编码与口径
Dart 源 LF、无 BOM、`print(` 计数 0、公开成员中文 `///`；文案走 `t.xxx`，英文态零中文；临时脚本纯 ASCII + UTF-8 无 BOM；删东西一律 `Move-Item` 改名。

### 0.4 并发纪律（本棒与 W2 同时在跑同一工作树）
```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$env:FLUTTER_BUILD_DIR='build_w3'
```
- 构建目录隔离到 `build_w3`，避免与 W2 抢 `build\test_cache\build`（OS Error 183 已证坑）。若不生效 ⇒ 交付写 `BUILD_DIR_ISOLATION=FAILED`，不要反复试。
- `git status --porcelain` 会同时出现 W2 的文件：**交付只列自己写集**，并在原样粘贴后注明「含 W2 并发产物，已剔除」。
- `flutter analyze` 报**非你写集**的错误（W2 半成品）⇒ 忽略并复跑；只有全在你写集内才算你的问题。
- 为跑绿去改 W2 的文件是**明令禁止**的；冲突写进 `AMBIGUITIES`。

## 1. 独占写集（8 项）

| # | 路径 | 本棒用途 |
|---|---|---|
| 1 | `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart` | 把 W1 的空占位换成真实面板：未完成周目标清单 + 点击添加 + 拖拽发起 |
| 2 | `apps\desktop\lib\src\data\project_store.dart` | 新增「把周目标加入计划」的写入方法，**必须复用 `:578` 既有账本写入路径** |
| 3 | `apps\desktop\lib\src\pages\today_page.dart` | 日计划侧接收 `goal://` 拖拽 payload（不破坏既有通道）；必要时给面板传回调 |
| 4 | `apps\desktop\lib\src\widgets\timeline\day_grid.dart` | 日计划右键菜单新增**勾选式多选未完成周目标**入口（D-72-g） |
| 5 | `apps\desktop\test\widgets\week_goal_rail_panel_test.dart`（新建） | 面板：过滤口径、点击添加、payload 格式、空态、中英两态 |
| 6 | `apps\desktop\test\widgets\task72_day_goal_menu_test.dart`（新建） | 右键勾选 → 计划里真的出现条目；重复勾选幂等；既有右键项不回归 |
| 7 | `apps\desktop\test\timeline\**`（条件写集） | 仅当 `day_grid.dart` 改动把它们改红时才许动，只许修正既有断言口径 |
| 8 | `docs\handoff-ledger-b7-w3.md` | 台账片段（控制器并入） |

只读参考（**不许改**）：`pages\today_page.dart:840-844`（`Draggable<String>` + `pointerDragAnchorStrategy` 发起侧先例）、`:332`（`showMenu<_DateTimeActionKind>` 先例）、`widgets\timeline\day_grid.dart:339-341`（`DragTarget<String>` `onWillAcceptWithDetails/onAcceptWithDetails`）、`widgets\ledger_dock.dart`（`LedgerRailPanel` 形状）、`app.dart:386-421`（`todayRailPanels()` 第 5 面板槽位，W1 已建）、`data\project_store.dart:578`（计划行唯一账本路径）、`:612`（计划行查询）、`packages\core_domain\lib\src\goal.dart:77-97`（`isDone`）。

## 2. 设计裁决（冲突即 AMBIGUITIES）

- **D-72-c 未完成口径**：一律走 W1 的 `weekOpenGoalsProvider`（`!isDone` 且未归档）。**严禁**本棒再写一套过滤，严禁改 `packages\**` / 新增仓储查询。
- **D-72-e 写入语义**：周目标 → 计划 = **只走 `project_store.dart:578` 既有那条账本写入路径**，**严禁自写 INSERT / 严禁新开第二条写路径 / 严禁直接动 drift 表**。计划项与目标的关联沿用既有字段与既有幂等做法：同一条周目标在同一天重复添加**必须不产生第二条计划行**（点击与右键两条入口共享同一方法，天然幂等；若既有实现不幂等，本棒**不得**擅自改它的幂等语义，写进 `AMBIGUITIES` 让控制器裁决）。
- **D-72-g 三条通道**：
  1. **点击**面板条目 ⇒ 调同一添加方法，随后按项目既有写法 `invalidate` 相关 provider，让日计划立刻可见。
  2. **拖拽**：条目 `Draggable<String>(data: 'goal://' + goalId)`（与 W2 逐字一致的 payload 约定）；`day_grid.dart:339-341` 既有接收器必须按前缀分流：`goal://` 前缀走本棒新通道，**裸 id（todo 通道）行为一律不变**。
  3. **右键勾选**：在日计划既有右键菜单里加一项「未完成周目标」，点击后弹 `showMenu` / 勾选浮层（照 `today_page.dart:332` 的 `showMenu` 先例的形状），列出未完成周目标供**多选勾选**，确认后批量调同一添加方法。菜单项文案用 W1 已登记的 `goalsUpstreamWeekTitle` 与 `goalsUpstreamAddMenu`，**不得新增 l10n getter/键**。
- 面板必须挂进 W1 已建的 `id: 'week-goals'` 槽位（`app.dart` 里），本棒**只改面板实现体**，不改 `app.dart`。若槽位签名需要微调才能拿到 provider/回调 ⇒ 写 `AMBIGUITIES`，不要自己动 `app.dart`。
- 不得破坏 `today_page.dart:840-844` / `_HabitDragChip:890` 既有的习惯拖拽与 `day_grid.dart` 既有拖放（验收要求「既有拖拽通道不回归」）。
- 不得改 `KeyHintList` / `KeyBar` / 左栏导航（W1 已完成）。

## 3. 逐条必做

1. `WeekGoalRailPanel` 真身：标题 = `t.goalsUpstreamWeekTitle`，提示 = `t.goalsUpstreamAddHint`，空态 = `t.goalsUpstreamEmpty`；条目 = 未完成周目标（provider 直读），每项 `InkWell`/按钮点击即添加，每项可拖拽。
2. `project_store.dart` 新增一个方法（命名按项目惯例，例如 `addPlanItemFromGoal`）：入参（目标 id / 目标对象 + 日期），内部复用 `:578` 那条写路径；返回新增或已存在的判据，供上层 `invalidate`。**不要在 UI 里堆业务写入逻辑。**
3. `day_grid.dart` 右键：既有菜单结构不动，追加一项进入勾选浮层；勾选确认后**批量**调用同一 store 方法；`await` 后刷新。窄屏/无目标时该项应禁用或不出现（选择一种并说明）。
4. 测试要**行为级**：pump 今日页 → 点面板条目 → 断言日计划/计划查询里出现对应条目；再点一次断言不重复；右键勾选两条 → 断言两条都进计划；拖拽用 `WidgetTester.dragFrom` 或直接调 `onAcceptWithDetails` 断言同一路径。
5. `flutter analyze` 逐字 `No issues found!` + `flutter test --reporter compact` 全绿；报「W1 末值 → 本棒末值」并列出新增用例名。

## 4. 交付格式

```
STATUS: DONE | DONE | DONE_WITH_CONCERNS | BLOCKED
CHANGED_FILES: <自己写集内路径 + 净增/净删行>
TEST_COUNT: desktop <W1末值> → <本棒末值>   （新增用例名逐条）
STORE_METHOD: <方法签名 + 复用的既有写路径 file:line>
IDEMPOTENCY_EVIDENCE: <同目标重复添加的实测结果与依据>
DRAG_PAYLOAD_FORMAT: goal://<goalId>
CONTEXT_MENU_SHAPE: <入口位置、勾选控件、禁用策略>
GIT_STATUS_PORCELAIN: <原样粘贴，标注含 W2 产物>
BUILD_DIR_ISOLATION: OK | FAILED
AMBIGUITIES / CONCERNS: <列表，无则 NONE>
LEDGER片段: docs\handoff-ledger-b7-w3.md（不要改 handoff.md / progress.md）
```

---

## 9. W1 已落地后的**强制订正**（优先级高于上文，冲突处以本节为准）

W1 已交付（台账 `docs\handoff-ledger-b7-w1.md`），地基与本派工书原稿有 7 处不符。逐条覆盖：

1. **l10n 一行都不许再动**。8 条 getter（含本棒要用的 `goalsUpstreamAddMenu`，中文「添加到计划」/
   英文 `Add to plan`）与全部中英词条、`l10n_keys.dart` 常量与 `byGetter` 映射、
   `test\l10n_harness.dart` 映射，W1 已建完并过计数不变量。本棒**严禁**修改
   `apps\desktop\lib\src\l10n\**`、`test\l10n_harness.dart`、`test\l10n_base_test.dart`；
   缺词就写进 AMBIGUITIES，**不要自己补**。
2. **provider 真实签名**（`providers.dart:867-888`，W1 已建）：`weekOpenGoalsProvider` 是
   **`FutureProvider<List<GoalRow>>`**（不是 `Provider<List<Goal>>`），过滤已在 provider 侧做完
   （`!isDone && archivedAt == null`）。本棒 `ref.watch` 后按 `AsyncValue` 三态渲染，元素类型 `GoalRow`。
   **严禁修改 `providers.dart` 与 `packages\**`。**
3. **今日右栏第 5 面板已存在，本棒是「填内容」不是「新建挂载」**：W1 已建占位类
   `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart`（36 行，`class WeekGoalRailPanel`），
   并已挂在 `app.dart:427-431` 的 `todayRailPanels()` 末尾（右轨已 4 块 → 5 块）。
   ⇒ **本棒只替换该文件 `build()` 内的 children**（改为读 `weekOpenGoalsProvider` + 可点 + 可拖），
   **类名、文件路径、挂载点一律不动**；`app.dart` 本棒**不再需要**改右栏挂载。
   若你判断槽位签名不够用，写进 AMBIGUITIES，**不要自己动 `app.dart`**（写集外）。
4. **`GoalKind` 枚举名**是 `yearly` / `monthly` / `weekly`。
5. **补一项 W1 明确移交的收尾**（原派工书没写，现补进本棒写集）：
   `apps\desktop\lib\src\widgets\shell\key_bar.dart:78` 的 `shellKeyHintsFor()` 快捷键清单
   **缺 `Ctrl+7`（蓝图）** —— W1 加了 `Ctrl+7` 导航能力但没同步这份提示清单。
   本棒须在该清单末尾补一条 `Ctrl+7` → 蓝图（`Ctrl+1…6` 措辞同步改 `Ctrl+1…7`），
   并同步校准 `test\shell_key_hints_test.dart`（只改断言清单，不改被测行为）。
   注意：左栏底部的快捷键常驻显示已被需求 1 删除（判据装置 `reports\task72-nav-foot-judge.ps1`
   要求左栏内 `KeyCap` 命中数 **恒为 0**），**这条提示只能加在 `shellKeyHintsFor()` 里**
   （窄屏 `KeyBar` 与宽屏右轨 `KeyHintList` 共用该清单），绝不能在 `nav_rail.dart` 里加任何常驻显示。
6. **测试基线不变**：W1 实测 desktop 全量 **`+882`** 全绿、`flutter analyze` 逐字 `No issues found!`。
   本棒新增测试会使数字上升，交付时报**实际末值**。
7. **构建目录隔离（本棒与 W2 并行）**：跑任何 `flutter` 命令前先设
   `$env:FLUTTER_BUILD_DIR='build_w3'`，交付回填 `BUILD_DIR_ISOLATION: OK`；
   跑全量前把 `apps\desktop\build_w3\test_cache\build`（若存在）`Move-Item` 改名。
8. **已知的一个真缺陷，别踩**：W1 台账 §6 坑 1 —— `shellLocalizationsOf(context)` 住在
   `widgets\shell\key_bar.dart`，新文件引它必须 import；`week_goal_rail_panel.dart` 已有该 import，
   改的时候**不要删掉**。
