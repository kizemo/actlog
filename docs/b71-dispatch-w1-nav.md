# 派工书 · B7-W1「导航瘦身 + 蓝图独立页 + 共享地基」

> 真源：`docs\plan-goals-ui-batch7.md`（需求 1 的裁决 D-72-a / D-72-b / D-72-c，另含本棒承担的共享地基 D-72-d/e/f/g 的**接口名**）。本派工书是唯一实现契约；与口头指示冲突时以本文为准；拿不准写进 `AMBIGUITIES`，不要自行扩面。
> 模型/effort 按 AGENTS.md §2 R8。
> **本棒是「地基棒」：除导航改造外，还要把 W2/W3 会消费的 l10n getter/键与 provider 一并建好，使 W2 与 W3 能真正并行、各自收尾时门禁全绿。**

## 0. 环境与硬约束

- 仓库根 `F:\soft\00selfmade\practilog`。开工第一件事：**完整读 `AGENTS.md`**，再读 `docs\plan-goals-ui-batch7.md` 全文，以及 `docs\plan-goals-ui-batch5.md` §5（D-62-a 至 D-62-l，含 D-62-c 导航口径）。
- **写集纪律**：只许改下表文件。**严禁**改 `packages\**`（core_domain / core_db / core_data 一行都不许动）、`docs\plan-goals-ui-batch*.md`、`AGENTS.md`、`handoff.md`、`release\**`、`tools\**`、`reports\**`、`apps\desktop\lib\src\widgets\shell\key_bar.dart`、`apps\desktop\lib\src\pages\today_page.dart`、`apps\desktop\lib\src\data\project_store.dart`、`apps\desktop\lib\src\pages\goals_*_page.dart`（除本文列出的 2 个例外）。
- **不许新增 package / 依赖 / `flutter pub get` / `flutter clean`**。
- 跑 flutter 前先 `$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`；跑 `flutter test` 前把 `apps\desktop\build\test_cache\build` **改名**（`Move-Item`）；删东西一律改名不许真删。
- `.ps1` 若需临时脚本：纯 ASCII + UTF-8 无 BOM。Dart 源：LF、无 BOM、`print(` 计数必须为 0、公开成员带中文 `///`。
- 本机正在运行装机版 actlog（PID 91364），**不要动 `D:\Program Files\actlog`**，不要跑打包/安装。

## 1. 独占写集（14 项）

| # | 路径 | 本棒用途 |
|---|---|---|
| 1 | `apps\desktop\lib\src\widgets\shell\nav_rail.dart` | 删底注 `_NavFoot` 与挂载；`kShellNavItems` 加第 7 项 `blueprint` |
| 2 | `apps\desktop\lib\src\app.dart` | 新增 `/blueprint` 路由 + `ShellSection.blueprint` + `Ctrl+7`；今日右栏新增第 5 面板槽位（用占位 builder，见 §4.7）；`_content()` 新增蓝图分支并把 goals 分支收敛为三页签 |
| 3 | `apps\desktop\lib\src\pages\goals_page.dart` | 页签只留 周｜月｜年；body 删蓝图分支；默认页签解析回落 |
| 4 | `apps\desktop\lib\src\pages\goals_blueprint_page.dart` | 从「页签内容体」改为独立页壳（标题 + 返回/快捷键说明不做，只留页面标题与主体） |
| 5 | `apps\desktop\lib\src\l10n\parts\shell.dart` | **新增 2 个 getter**（见 §4.5） |
| 6 | `apps\desktop\lib\src\l10n\parts\goals.dart` | **新增 6 个 getter**（W2/W3 共用文案，见 §4.5） |
| 7 | `apps\desktop\lib\src\l10n\l10n_keys.dart` | 为上述 8 个新 getter 登记 kebab 键 + `byGetter` 各一行 |
| 8 | `apps\desktop\lib\src\providers.dart` | **新增 3 个未完成目标 provider**（见 §4.6，纯追加） |
| 9 | `apps\desktop\test\shell\nav_rail_footnote_test.dart` | 断言反转为「底注必须不存在 + 快捷键功能不回归」 |
| 10 | `apps\desktop\test\shell\blueprint_page_test.dart`（新建） | 覆盖 `/blueprint` 与 `Ctrl+7`：独立页可达、标题正确、目标页只剩三页签、`/goals?tab=blueprint` 回落周视图 |
| 11 | `apps\desktop\test\l10n\task61_l10n_shell_test.dart` | 有序清单加 `shellNavBlueprint` |
| 12 | `apps\desktop\test\l10n\l10n_base_test.dart` | 校准键数 / base 行数（本棒加 8 条键） |
| 13 | `apps\desktop\test\l10n\app_l10n_test.dart` | 校准 getter 数（同上） |
| 15 | `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart`（新建） | 今日右栏第 5 面板的**可编译占位**，W3 负责替换内容体（见 §3.5） |
| 16 | `docs\handoff-ledger-b7-w1.md` | 台账片段（见 §7，控制器负责并入 `handoff.md` / `progress.md`） |
| 17 | `apps\desktop\test\pages\goals\task65_goals_week_test.dart` / `task65_goals_month_test.dart` / `task66_goals_blueprint_page_test.dart` | **条件写集**：仅当页签结构变化把它们改红时才许动，且只许修正既有断言口径（不许新增用例、不许放宽判据）。W2/W3 明令**不得**编辑这三个文件，避免并发。 |

W1 可**只读**参考（不许改）：`widgets\shell\key_bar.dart`（`KeyHintList` 必须仍在，它是快捷键说明的替代位置）、`widgets\goal_badge.dart`、`widgets\timeline\day_grid.dart`、`pages\today_page.dart`、`test\shell\*`、`test\shell\shell_nav_rail_test.dart`、`test\shell\nav_shortcut_test.dart`、`test\shell\task64_nav_gear_test.dart`、`test\pages\goals\*`、`test\l10n\l10n_harness.dart`。

## 2. 需求 1 裁决口径（照抄计划 §2，冲突即 AMBIGUITIES）

- **D-72-a**：「去除左边栏底部切换页面快捷键显示」= **只删左栏底部那段常驻文本**。`Ctrl+1…7` 功能**必须保留**（`app.dart` shortcuts map）、窄屏 `KeyBar`（`key_bar.dart`）与宽屏右轨 `KeyHintList`（`app.dart:312-315` → `key_bar.dart:201`）**必须不动**。
- **D-72-b**：蓝图升级为独立页 `blueprint`，排在 `goals` 之后；l10n 文案 zh「蓝图」/ en `Blueprint`；快捷键 `Ctrl+7`；深链 `/blueprint`；`/goals` 页签只剩 周｜月｜年；`kGoalsTabBlueprint` 常量**保留**，但 `parseGoalsTab('blueprint')` 必须回落 `kGoalsTabDefault`（周）。
- 既有口径继承：**B-1 顺序直进**（`app.dart:204` 深链清单口径）、**D-62-l 角标**（蓝图无角标）。

## 3. 逐条必做改动（file:line 是本棒取证所得，若源码已漂以源码为准并在 AMBIGUITIES 说明）

### 3.1 底注删除（写集 1）
- 删 `nav_rail.dart:428-560` 的 `_NavFoot` 类（含 `_FootKeycapRow` / `_FootCombo` / `_FootHint` / `_FootLegend` / `_FootNote`）与 `KeyCap` 的 `_NavFoot` 侧用法；删 `nav_rail.dart:138` 的 `..add(_NavFoot(t: t))`。
- **`KeyCap` 若仍被 `key_bar.dart` 等共用则不许删类本身**，只删 `_NavFoot` 相关私有实现。
- `nav_rail.dart:124-126` 上方注释里「底部常驻快捷键说明」的口径改为「快捷键说明只在窄屏 `KeyBar` 与宽屏右轨 `KeyHintList`」。

### 3.2 第 7 个导航项（写集 1 + 2）
- `nav_rail.dart:38-50` `kShellNavItems`：`goals` 之后插入 `ShellNavItemData(id:'blueprint', icon: Icons.map_outlined, labelGetter: (t)=>t.shellNavBlueprint)`。**图标沿用现有 `Icons.map_outlined`，不新建蓝图图标。**
- `app.dart:73-83` `ShellSection` 枚举加 `blueprint`；`:87` `shellSectionFromNavId` 加 `case 'blueprint' => ShellSection.blueprint;`。
- `app.dart:168` 同层加 `GoRoute(path:'/blueprint', ...)`（沿用既有 `pushReplacementNamed` 与 redirect 骨架，**不做带参跳转**）。
- `app.dart:204` 深链清单注释加 `/blueprint`。
- `app.dart:252-257` shortcuts map：`LogicalKeyboardKey.key7` → `const _NavIntent('blueprint')`（`digit1..7` 齐全）；`:262-265` desc map 加 `shellNavBlueprintDesc`；`:274` 类 doc 注释 `Ctrl+1…7`。
- `app.dart:345-353` `_content()` switch：新增 `ShellSection.blueprint => const GoalsBlueprintPage()`；`ShellSection.goals` 分支保持只渲染三页签。
- `app.dart:363-370` 注释：从「蓝图是页签，不另设第 7 个导航项」**改写**为「蓝图是第 7 页，`Ctrl+7`」；`:112-113` `homeTabFromNavId` 注释同步。
- `goals_page.dart:94` 删 `GoalsTabItemData(... kGoalsTabBlueprint ...)`；`:105-116` `_buildBody()` 删 `case kGoalsTabBlueprint`，`default` 回落周视图并保留注释说明「blueprint 已独立成页」。
- `goals_page.dart` 的 `parseGoalsTab()`（约 `:33-47`）：收到 `blueprint` 返回默认 `week`，**不得**返回空白页。
- `goals_blueprint_page.dart`：`GoalsBlueprintPage` 增加独立页壳（页面标题 = `t.shellNavBlueprint`），主体沿用现有四段（愿景横幅 / 周期阶梯 / 长期任务 / 回顾位）；`:250-252` 与 `:108-116` 的「蓝图不是 ShellSection / 不做 Ctrl+7 路由」注释改写为新事实。**不得**把 `_GoalsTabBar` 塞进独立页（它现在带 `onChange` 回调，语义已不适用）。
- `goals_blueprint_page.dart` 由 `goals_page.dart` import 的私有入口（若有）改为公开组件调用；`goals_page.dart` 不再 import 该文件。

### 3.3 l10n 新增（写集 5-7，**必须与键表同时改，否则 l10n 计数测试红**）
在 `l10n/parts/shell.dart` 的 `ShellL10n` 接口、`ShellZhL10n`、`ShellEnL10n` 三处同步新增：
1. `shellNavBlueprint` → zh `蓝图` / en `Blueprint`
2. `shellNavBlueprintDesc` → zh `切到蓝图` / en `Go to blueprint`

在 `l10n/parts/goals.dart` 三处同步新增（**这些是 W2/W3 要消费的共用文案，命名必须逐字一致**）：
3. `goalsUpstreamYearTitle` → zh `未完成年目标` / en `Open yearly goals`
4. `goalsUpstreamMonthTitle` → zh `未完成月目标` / en `Open monthly goals`
5. `goalsUpstreamWeekTitle` → zh `未完成周目标` / en `Open weekly goals`
6. `goalsUpstreamAddHint` → zh `点击或拖拽添加到当前周期` / en `Click or drag to add to this period`
7. `goalsUpstreamEmpty` → zh `暂无未完成目标` / en `No open goals`
8. `goalsUpstreamAddMenu` → zh `添加到计划` / en `Add to plan`

- 英文态**零中文**（纯 ASCII）。
- `l10n_keys.dart`：为上述 8 条各加一行 `static const String <camel> = '<kebab>';`（kebab = camel 转横线小写，如 `goals-upstream-year-title`）+ 一行 `byGetter` 映射（`:1851` 起的 Map）。
- 随后把 `l10n_base_test.dart`（约 `:252` 键数、`:289` base 行数）与 `app_l10n_test.dart`（约 `:529` getter 数）里的**旧常量按实际末值校准**（本棒净增 8 条），并在交付里报「旧值 → 新值」。
- `task61_l10n_shell_test.dart` 有序清单插入 `shellNavBlueprint` / `shellNavBlueprintDesc`（按 part 内声明顺序）。

### 3.4 provider 地基（写集 8，**纯追加，本棒不消费**）
在 `apps\desktop\lib\src\providers.dart` 追加三个 `Provider<List<Goal>>`（命名必须逐字一致，W2/W3 按名消费）：
- `yearOpenGoalsProvider` → 调 `goal_store.dart:651` `listGoals(kind: GoalKind.year, status: ...)`，过滤「未完成」
- `monthOpenGoalsProvider` → 同上 `GoalKind.month`
- `weekOpenGoalsProvider` → 同上 `GoalKind.week`

**D-72-c 的「未完成」口径**：`!Goal.isDone`（即 `status != GoalStatus.done`）**且未归档**。
⚠️ `listGoals` 的 `status` 参数只做**等值筛选**、**没有 `notDone`**，所以**严禁改 `packages\core_db`/`core_data` 或新增仓储方法**：按 `kind` 取回后在 UI 侧用 Dart 过滤（可参照 `widgets\goals\goal_year_matrix.dart:6` 的「零改动」纪律）。若 `listGoals` 返回的 `GoalRow` 需转 `Goal` 再取 `isDone`，参照既有页面的写法。
结果**按 createdAt 升序**（沿用 `listGoals` 内 `sort(_compareGoals)`，若排序语义不符写进 AMBIGUITIES，不要自行改排序）。

### 3.5 今日右栏第 5 面板**槽位**地基（写集 2）
`app.dart:386-421` `todayRailPanels()` 末尾追加一块面板，`id: 'week-goals'`、`title: t.goalsUpstreamWeekTitle`、`order 与同类静态块一致`。**本棒只建槽位，内容体留待 W3**：
- 若直接引用 W3 尚未存在的组件类会导致编译不过 ⇒ 本棒用**最小可编译占位**：新建 `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart`（**列入写集 15**），类名 `WeekGoalRailPanel`（`const` + `Key? key`），本棒实现为**空态安全的最小骨架**（渲染 `goalsUpstreamWeekTitle` 与 `goalsUpstreamAddHint`，不接数据、不写库）。W3 会替换其内容。
- 该类必须建在 `widgets\`（与 `widgets\shell\` 同层）：`test\shell\ledger_dock_test.dart:138-143` 对 `widgets\shell\` 下文件有「无重复 import」检查。
- `LedgerRailPanel` 若无对应 `LedgerDockSlot` 枚举值可用，则**复用 `LedgerDockSection.weekTodo`**（`ledger_dock.dart:61`），并在交付里说明。

## 4. 禁止事项

1. 不许动 `packages\**`、不许改任何 SQL / drift 表 / 仓储方法。
2. 不许动右轨 `KeyHintList`、窄屏 `KeyBar`、`Ctrl+…` 快捷键功能。
3. 不许在 `goals_page.dart` 保留蓝图页签，也不许给蓝图再造角标。
4. 不许新增 l10n getter 而不在 `l10n_keys.dart` 登记（计数测试必红）。
5. 不许把 `weekOpenGoalsProvider` 等 provider 写成 `StateProvider`/`NotifierProvider` 之外的新形状 —— 沿用 `providers.dart` 既有 `Provider` 风格。
6. 不许写 `today_page.dart` / `project_store.dart` / `day_grid.dart`（那是 W3 的写集）。
7. 不许为「让测试好看」放宽既有断言；断言反转仅限 `nav_rail_footnote_test.dart`（D-72-a 的用户裁决所致）。

## 5. 验收判据（逐条自证）

1. `flutter analyze` **逐字** `No issues found!`。
2. `flutter test --reporter compact` **全绿**；报「基线 882 → 本棒末值 +Δ」明细。
3. `nav_rail_footnote_test.dart` 新口径成立：左栏底部**无** `Ctrl+1…7` 常驻文本（`find.text` 零命中或 widget 类型不存在），同时 `Ctrl+7` 断言成立。
4. `blueprint_page_test.dart`：`/blueprint` 与 `Ctrl+7` 都命中；`/goals?tab=blueprint` 回落周视图；`/goals` 页签数量 == 3。
5. l10n 三个测试（`task61` / `l10n_base` / `app_l10n`）全绿，并报旧值→新值。
6. 未动 W2/W3 写集文件：`git status --porcelain` 的改动必须全在 §1 写集内（把该输出原样放进交付）。

## 6. 自检命令（跑完再交）

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Move-Item 'apps\desktop\build\test_cache\build' 'apps\desktop\build\test_cache\build_w1'   # 若存在
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
git -C . status --porcelain
```

## 7. 交付格式（缺项视为未完成；台账不直接写 `handoff.md`/`progress.md`，交控制器并入）

```
STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED
CHANGED_FILES: <逐条路径 + 净增/净删行数>
TEST_COUNT: desktop 882 → <实际末值>   （列出新增/删除的用例名）
L10N_CALIBRATION: keys <旧>→<新> / base <旧>→<新> / getters <旧>→<新>
GIT_STATUS_PORCELAIN: <原样粘贴>
NEW_PROVIDER_NAMES: yearOpenGoalsProvider / monthOpenGoalsProvider / weekOpenGoalsProvider
NEW_L10N_NAMES: <8 条逐字列出>
PLACEHOLDER_WEEK_GOAL_RAIL_PANEL: <实际类名/文件/未接数据说明>
AMBIGUITIES: <列表，无则 NONE>
CONCERNS: <列表，无则 NONE>
LEDGER片段: 写入 docs\handoff-ledger-b7-w1.md（中文、含事实与数字，不要改动 handoff.md / progress.md）
```
