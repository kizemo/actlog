# 派工书 · B7-W2「未完成年/月目标右栏 + 月页与周页双栏」

> 真源：`docs\plan-goals-ui-batch7.md`（需求 2、需求 3；裁决 D-72-c / D-72-d / D-72-e / D-72-f）。本派工书是唯一实现契约。
> 前置：**W1 已入库**（导航与 l10n/provider 地基）。开工前先 `git status --porcelain` 与 `flutter analyze` 确认地基在位；若 `yearOpenGoalsProvider` / `monthOpenGoalsProvider` / `goalsUpstream*` 文案缺失 ⇒ **立刻 BLOCKED 上报**，不要自己补地基。
> 与 **W3 并发执行**：见 §0.4 并发纪律。

## 0. 环境与硬约束

### 0.1 上下文
- 仓库根 `F:\soft\00selfmade\practilog`。开工第一件事：完整读 `AGENTS.md`，再读 `docs\plan-goals-ui-batch7.md` 全文。
- 需求原文（用户 2026-11-25 逐字）：
  - 需求 2：「月目标设定页面，显示右边栏，右边栏中，显示仍然未完成的年目标，可以点击或拖动添加到月目标」
  - 需求 3：「周目标设定页面，显示右边栏，右边栏中，显示仍然未完成的月目标，可以点击或拖动添加到周目标」

### 0.2 写集纪律
只许改 §1 表内文件。**严禁**改：`packages\**`、`apps\desktop\lib\src\app.dart`、`widgets\shell\**`、`pages\goals_page.dart`、`pages\goals_blueprint_page.dart`、`pages\goals_year_page.dart`、`pages\today_page.dart`、`widgets\timeline\day_grid.dart`、`widgets\week_goal_rail_panel.dart`、`data\project_store.dart`、`providers.dart`、`l10n\**`（含 `l10n_keys.dart`）、`test\l10n\**`、`test\shell\**`、`test\pages\goals\task65_*` / `task66_*`、`AGENTS.md`、`handoff.md`、`progress.md`、`release\**`、`tools\**`、`reports\**`。
不许新增 package / 依赖 / `flutter pub get` / `flutter clean`。

### 0.3 编码与口径
Dart 源 LF、无 BOM、`print(` 计数 0、公开成员中文 `///`；文案一律走 `t.xxx`，**英文态零中文**；临时脚本纯 ASCII + UTF-8 无 BOM；删东西一律 `Move-Item` 改名不许真删。

### 0.4 并发纪律（本棒与 W3 同时在跑同一工作树）
- 跑 flutter 前**必须**把构建目录隔离到本棒专属：
  ```powershell
  $env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
  $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
  $env:FLUTTER_BUILD_DIR='build_w2'
  ```
  这样测试缓存落在 `apps\desktop\build_w2\...`，不与 W3 抢 `build\test_cache\build`（OS Error 183 已证坑）。若该环境变量不生效（仍以 `build/` 为目标），**不要**反复尝试，改为：在交付里写 `BUILD_DIR_ISOLATION=FAILED`，并说明用 `Move-Item` 挪缓存的时间点。
- **W3 的文件在 `git status --porcelain` 里会一起出现，这是正常的**：交付只列你自己写集内的改动，并在 `GIT_STATUS_PORCELAIN` 原样粘贴后注明「含 W3 并发产物，已剔除」。
- `flutter analyze` 若报**你不拥有的文件**的错误（W3 半成品），忽略并复跑一次；只要错误全在你写集内才算你的问题。
- 本棒**不得**为了跑绿去动 W3 的文件；拿不准写进 `AMBIGUITIES`。

## 1. 独占写集（7 项）

| # | 路径 | 本棒用途 |
|---|---|---|
| 1 | `apps\desktop\lib\src\widgets\goal_upstream_panel.dart`（新建） | 三层共用「未完成上游目标」面板组件 `GoalUpstreamPanel`（D-72-d） |
| 2 | `apps\desktop\test\pages\goals\task72_goal_upstream_panel_test.dart`（新建） | 组件单测：未完成过滤、点击回调、拖拽 payload 格式、空态、中英两态 |
| 3 | `apps\desktop\lib\src\pages\goals_month_page.dart` | 双栏化 + 左消费 `yearOpenGoalsProvider` + 添加语义（年→月派生） |
| 4 | `apps\desktop\lib\src\pages\goals_week_page.dart` | 双栏化 + 消费 `monthOpenGoalsProvider` + 添加语义（月→周派生） |
| 5 | `apps\desktop\test\pages\goals\task72_goals_month_upstream_test.dart`（新建） | 月页右栏存在性 + 点击后月目标真的派生出来 + 幂等 |
| 6 | `apps\desktop\test\pages\goals\task72_goals_week_upstream_test.dart`（新建） | 周页同上（月→周） |
| 7 | `docs\handoff-ledger-b7-w2.md` | 台账片段（控制器负责并入） |

只读参考（**不许改**）：`pages\goals_year_page.dart:449-480`（`_candidates()` 派生语义参照）、`widgets\goal_badge.dart`、`widgets\shell\**`（右栏宽度/折叠口径）、`data\goal_store.dart:651`（`listGoals` 签名）、`packages\core_domain\lib\src\goal.dart:77-97`（`GoalStatus` / `isDone`）、`providers.dart`（W1 新 provider）、`l10n\parts\goals.dart`（W1 新 getter）、`test\pages\goals\task65_goals_month_test.dart` / `task65_goals_week_test.dart`（学习既有 pump 配方与 harness 用法）。

## 2. 设计裁决（照抄计划 §3，冲突即 AMBIGUITIES）

- **D-72-c 未完成口径**：`!goal.isDone` **且未归档**。已在 W1 的 provider 里落地，本棒**只消费 provider**，不许再写一套过滤，更不许改 `packages\**` 或新增仓储方法。若 provider 的口径与需求不符 ⇒ 上报 `AMBIGUITIES`，不要自行绕开 provider 直查 store。
- **D-72-d 组件复用**：月页/周页共用 `widgets\goal_upstream_panel.dart` 的 `GoalUpstreamPanel`（`widgets\` 顶层，不进 `widgets\shell\`）。参数化：来源 `GoalKind`、标题文案、条目列表、`onPick`（点击添加）、拖拽 payload。**今日右栏的周目标面板由 W3 用不同形状实现，本棒不负责它，也不要为了它改组件 API**——若你觉得需要预留 hook，写进 `CONCERNS`。
- **D-72-e 添加语义**：**派生**，不是复制文本，也不是改父目标状态。
  - 年 → 月：参照 `goals_year_page.dart:449-480` 的既有 `_candidates()` / `GoalPeriod.month` 写法，走 `goal_store.dart:651` 同一套写入路径。
  - 月 → 周：同一形状（目标周期为周）。
  - **幂等**：同一条上游目标在同一周期重复添加**不得**产生第二条子目标（沿用既有幂等做法；若既有实现只靠 `parentId` 判重，就照它）。
  - **严禁**自写 `INSERT` / 绕开 store；**严禁**改 `GoalStatus` 或把父目标标记完成。
- **D-72-f 双栏形状**：月页/周页当前顶层是 `Column`（`goals_month_page.dart:221/:311`、`goals_week_page.dart:51/:93`）。改法是**把原顶层整体包进 `Row` 的左 `Expanded`**，右栏用与既有页面一致的宽度口径（先查 `goals_year_page.dart` 有没有右栏先例；有则照它的宽度与折叠行为抄，没有则用项目既有常量）。**窄屏不得写死宽屏独占**：窄屏沿用壳层既有折叠/隐藏行为（`ledger_shell.dart:33-34/:180-184` 是今日页的口径，目标页侧若有自己的自适应先例优先照它，并在交付里说明选了哪个）。
- 页签/导航不属于本棒：`goals_page.dart` 一行不许动。
- **拖拽 payload 约定（W2/W3 共用，逐字一致）**：`Draggable<String>` 的值必须是 `'goal://' + goalId`（前缀用于与 `day_grid.dart:339-341` 既有的裸 todo id 通道区分）。本棒只负责**发起侧**用这个格式 + 月页/周页**自己的接收侧**认这个格式；day_grid 的接收侧属 W3。

## 3. 逐条必做

1. 新建 `GoalUpstreamPanel`：入参建议 `<GoalKind kind, String title, String hint, List<Goal> goals, void Function(Goal) onPick>`（形态可按项目惯例微调，但必须做到：未完成列表渲染、每项可点击、可拖拽、空态显示 `goalsUpstreamEmpty`、标题 + `goalsUpstreamAddHint` 提示、已完成/归档项**不出现**）。
2. 月页：左栏保持原内容原行为**不变**，右侧挂 `GoalUpstreamPanel(kind: year, goals: watch(yearOpenGoalsProvider))`；`onPick` = 年→月派生写入 + 触发既有失效刷新（沿用项目里 `invalidate` 的既有写法）。
3. 周页：同形状，`kind: month` + `monthOpenGoalsProvider`，`onPick` = 月→周派生。
4. 拖拽：面板项 `Draggable<String>(data: 'goal://<id>')`；月页/周页各自的目标区要有对应 `DragTarget<String>` 接收（**只认 `goal://` 前缀**，其它 payload 原样放行不吞）。若某页历史上已有拖拽接收器，必须在 `onWillAcceptWithDetails` 里按前缀分流，不得破坏既有通道。
5. loading/error 态：`goals_week_page.dart` 有 `_LoadingBlock/_EmptyBlock/_ErrorBlock`（`:220/:243/:265`），双栏化后这些态仍要正常渲染（右栏可显示空态，不得整页崩）。
6. 测试必须**行为级**（pump 页面 → 点面板项 → 断言列表里真的出现派生的月/周目标；再点一次断言不重复），不要只断言 widget 存在。
7. `flutter analyze` 逐字 `No issues found!` + `flutter test --reporter compact` 全绿；报「W1 末值 → 本棒末值」。

## 4. 交付格式

```
STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED
CHANGED_FILES: <自己写集内路径 + 净增/净删行>
TEST_COUNT: desktop <W1末值> → <本棒末值>   （新增用例名逐条）
DRAG_PAYLOAD_FORMAT: goal://<goalId>
ADD_SEMANTICS: <年→月 / 月→周 各自走的函数与幂等依据（file:line）>
LAYOUT_NARROW_BEHAVIOR: <右栏宽度口径来源 + 窄屏行为，file:line>
GIT_STATUS_PORCELAIN: <原样粘贴，标注含 W3 产物>
BUILD_DIR_ISOLATION: OK | FAILED
AMBIGUITIES / CONCERNS: <列表，无则 NONE>
LEDGER片段: docs\handoff-ledger-b7-w2.md（不要改 handoff.md / progress.md）
```

---

## 9. W1 已落地后的**强制订正**（优先级高于上文，冲突处以本节为准）

W1 已交付（台账 `docs\handoff-ledger-b7-w1.md`），地基与本派工书原稿有 6 处不符。逐条覆盖：

1. **l10n 一行都不许再动**。8 条 getter 与全部中英词条 W1 已建完并校准完毕
   （`parts\shell.dart` 2 条、`parts\goals.dart` 6 条、`l10n_keys.dart` 常量 + `byGetter` 映射）。
   本棒**严禁**修改 `apps\desktop\lib\src\l10n\**` 任何文件与 `test\l10n_harness.dart` /
   `test\l10n_base_test.dart`；**若发现缺词，停下来写进 AMBIGUITIES，不要自己补**
   （l10n 有「getter 数 == 键数」的计数不变量，两处并改极易造成假绿）。
   本棒直接消费这些 getter：`goalsUpstreamYearTitle` / `goalsUpstreamMonthTitle` /
   `goalsUpstreamWeekTitle` / `goalsUpstreamAddHint` / `goalsUpstreamEmpty`。
2. **provider 真实签名**（`providers.dart:867-888`，W1 已建）：
   `yearOpenGoalsProvider` / `monthOpenGoalsProvider` / `weekOpenGoalsProvider`
   均为 **`FutureProvider<List<GoalRow>>`**（不是 `Provider<List<Goal>>`）。
   过滤已做完：`_openOnly()` = `!isDone && archivedAt == null`。**本棒只读消费，严禁再改 providers.dart**，
   也严禁碰 `packages\**`。页面里用 `ref.watch(yearOpenGoalsProvider)` + `AsyncValue` 三态
   （loading / error / data），参照同目录既有 `goalWeeklyDraftsProvider` 的消费范式。
   元素类型是 **`GoalRow`**（仓储读模型，自带 `isDone`），不是 `Goal`。
3. **`GoalKind` 枚举名**：`yearly` / `monthly` / `weekly`（不是 `year` / `month` / `week`）。
   派生新目标时按此传参。
4. **月目标派生入口的正确引用**：不是 `_candidates()`，而是
   `apps\desktop\lib\src\pages\goals_year_page.dart:449-480`（该函数是「由年目标派生月目标」的
   既有实现，写集内可 `read`，**不得改它**）。周目标派生参照 `goals_month_page.dart` 的既有派生段。
5. **测试基线不变**：W1 实测 desktop 全量 **`+882: All tests passed!`**（882→882 净 0）、
   `flutter analyze` 逐字 `No issues found!`。本棒新增测试会让数字上升，
   交付时必须报**实际末值**（门禁按末值传参，不硬编 882）。
6. **构建目录隔离（本棒与 W3 并行）**：跑任何 `flutter analyze` / `flutter test` 前先设
   `$env:FLUTTER_BUILD_DIR='build_w2'`（镜像变量同批设：`PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL`），
   并在交付里回填 `BUILD_DIR_ISOLATION: OK`。跑全量前把 `apps\desktop\build_w2\test_cache\build`
   （若存在）`Move-Item` 改名，防 OS Error 183。
7. **写集追加（W1 坐实的必要文件）**：允许 `apps\desktop\test\task72_*` 前缀新建测试；
   若必须改既有测试才能绿，只允许改断言/清单/用例名，**不得改被测行为**，且逐条登记 CONCERNS。
8. **已知的一个真缺陷，别踩**：W1 台账 §6 坑 1 —— `shellLocalizationsOf(context)` 这个 helper
   住在 `widgets\shell\key_bar.dart`。**不要**在任何新建 widget 里漏 import 该文件，否则 `analyze` 报
   `undefined_method`。新建的共享面板类需要取 l10n 时，从页面侧把 `AppLocalizations` 传进构造函数，
   比在新文件里引 helper 更稳。
