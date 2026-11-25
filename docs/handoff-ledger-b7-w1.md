# B7 / W1（地基棒）交付台账 · 左栏去底注 + 人生蓝图独立成页

- 批次：B7（计划真源 `docs/plan-goals-ui-batch7.md`，D-72-a…h）
- 本棒：W1「地基棒」，需求契约 `docs/b71-dispatch-w1-nav.md`（§1 写集 / §7 交付格式）
- 交付对象：控制器（由控制器并入 `handoff.md` / `progress.md`；本文件不改那两份）
- 状态：**DONE_WITH_CONCERNS**（功能与门禁全绿；concerns 全在「写集外文件」与「契约与源码不符」，逐条列明）

---

## 1. 做了什么（需求 1：左栏去底部快捷键常驻显示 + 人生蓝图独立成页）

### 1.1 左栏底部快捷键常驻显示 —— 已删除（D-72-a）

- `apps\desktop\lib\src\widgets\shell\nav_rail.dart`：整段删除 `_NavFoot` / `_NavKeyRun` / `_NavKeyGroup`
  三个私有类与它们引用的 `KeyCap` 用法，并移除 `import 'key_bar.dart';`（后因
  `shellLocalizationsOf` 仍住 `key_bar.dart` 又补回，见 §6 坑 1）。文件 567 → 432 行（净 −129）。
- **只删显示，不删能力**：`Ctrl+1…7` 快捷键本身、窄屏 `KeyBar`、宽屏右轨 `KeyHintList` 一律未动；
  `key_bar.dart` 未改一行。
- 新测试口径从「守它在」反转为「守它不在」：`test\nav_rail_footnote_test.dart` 全量重写为
  F-1…F-5（100%/200% 双档零底注、零溢出、7 项 01–07 无 08、右边缘 ≤214、残留文案 `Ctrl`/`+`/`…`/
  `页面切换` 全 `findsNothing`）。

### 1.2 人生蓝图独立成页（D-72-b：作废 D-62-c 的「目标页第 4 页签」）

| 位置 | 改动 |
|---|---|
| `nav_rail.dart:40-48`（`kShellNavItems`）/ `:56-64`（`shellNavItemsFor`） | 7 项；第 7 项 `ShellNavItem(id: 'blueprint', label: '蓝图' / t.shellNavBlueprint)`，图标沿用 `Icons.map_outlined` |
| `app.dart:171` | 深链 `'/blueprint': (_) => const ShellHost(initialNavId: 'blueprint')` |
| `app.dart:256-257` | 快捷键 `SingleActivator(LogicalKeyboardKey.digit7, control: true) => _NavIntent('blueprint')`（注释同步改成 `Ctrl+1…7`） |
| `app.dart:351` | `_content()` 新增 `'blueprint' => const GoalsBlueprintPage()` |
| `goals_page.dart` | 删蓝图页签项 + `GoalsBlueprintPage` import；`_buildBody()` 只剩 周/月/年 三 case，`default` 兜底回落 `GoalsWeekPage` |
| `goals_blueprint_page.dart:181-197` | `build()` 起手加自带标题 `Text(t.shellNavBlueprint, key: ValueKey('blueprint-title'))` + `AppTokens.gapCard`；页面不再借目标页 AppBar/页签栏 |
| `providers.dart:267-275` / `:408` | `kGoalsTabIds` 只剩 3 项；`kGoalsTabBlueprint` 常量保留作历史值；`parseGoalsTab('blueprint')` 回落 `kGoalsTabWeek` |

---

## 2. W2/W3 要消费的共享地基（本棒只建，不消费）

### 2.1 l10n 8 条 getter（键前缀统一 `goal-`，见 §6 坑 3）

| getter | 中文 | English | kebab 键 |
|---|---|---|---|
| `shellNavBlueprint` | 蓝图 | Blueprint | `shell-nav-blueprint` |
| `shellNavBlueprintDesc` | 切到蓝图 | Go to blueprint | `shell-nav-blueprint-desc` |
| `goalsUpstreamYearTitle` | 未完成年目标 | Open yearly goals | `goal-upstream-year-title` |
| `goalsUpstreamMonthTitle` | 未完成月目标 | Open monthly goals | `goal-upstream-month-title` |
| `goalsUpstreamWeekTitle` | 未完成周目标 | Open weekly goals | `goal-upstream-week-title` |
| `goalsUpstreamAddHint` | 点击或拖拽添加到当前周期 | Click or drag to add to this period | `goal-upstream-add-hint` |
| `goalsUpstreamEmpty` | 暂无未完成目标 | No open goals | `goal-upstream-empty` |
| `goalsUpstreamAddMenu` | 添加到计划 | Add to plan | `goal-upstream-add-menu` |

落点：`l10n\parts\shell.dart`（`shellNavBlueprint*`，zh/en 各 2 条）、`l10n\parts\goals.dart`
（`goalsUpstream*`，zh/en 各 6 条）、`l10n\l10n_keys.dart:272/275`、`:1607-1622`（8 个常量）、
`:2067-2068` 起（`byGetter` 8 行）、`test\l10n_harness.dart`（映射 8 条）。

### 2.2 三个「未完成目标」provider（`providers.dart:867-888`）

```dart
List<GoalRow> _openOnly(List<GoalRow> rows)  // !isDone && archivedAt == null
final yearOpenGoalsProvider  = FutureProvider<List<GoalRow>>(...)  // kind: GoalKind.yearly
final monthOpenGoalsProvider = FutureProvider<List<GoalRow>>(...)  // kind: GoalKind.monthly
final weekOpenGoalsProvider  = FutureProvider<List<GoalRow>>(...)  // kind: GoalKind.weekly
```

- 过滤只在 UI 侧做，**未改 `packages\**`、未新增仓储方法**（D-72-c 与派工书 §3.4 的硬约束）。
- 用 `FutureProvider<List<GoalRow>>` 而非派工书写的 `Provider<List<Goal>>`：`listGoals` 是 async，
  且既有 `goalWeeklyDraftsProvider` 同款；`GoalRow` 才是仓储返回类型（见 §5 歧义 4）。

### 2.3 今日右栏第 5 面板可编译占位

- 新文件 `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart`（36 行）：
  `class WeekGoalRailPanel extends StatelessWidget`，只渲染 `t.goalsUpstreamEmpty` +
  `t.goalsUpstreamAddHint`（`:29`/`:31`），**W1 占位：不读数据、不写库、不弹层**，内容体归 W3。
- `app.dart:427-431` `todayRailPanels()` 末尾追加
  `ShellRailPanel(title: t.goalsUpstreamWeekTitle, child: const WeekGoalRailPanel())` ⇒ 右轨 4 块变 5 块。

---

## 3. 门禁实测（本机、进程内设镜像）

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Push-Location 'F:\soft\00selfmade\practilog\apps\desktop'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
```

| 判据 | 结果 |
|---|---|
| `flutter analyze` | **`No issues found! (ran in 7.4s)`** —— 逐字命中，退出码 0 |
| 定点：`test\blueprint_page_test.dart` + `test\nav_shortcut_test.dart` | `+5: All tests passed!`，退出码 0 |
| `flutter test --reporter compact`（全量） | **`02:01 +882: All tests passed!`**，退出码 0，无 skip |
| 跑前处理 | 已把 `apps\desktop\build\test_cache\build` `Move-Item` 改名 `build_b7w1`（防 OS Error 183） |

日志落盘（`apps\desktop\build\`，gitignored）：`b7w1_targeted2.log`、`b7w1_full.log`、`l10n_base_w1.log`。

## 4. 交付字段（派工书 §7 逐项）

```
STATUS: DONE_WITH_CONCERNS
CHANGED_FILES:
  改 apps\desktop\lib\src\app.dart                                   +23 / -11
  改 apps\desktop\lib\src\widgets\shell\nav_rail.dart                 +14 / -143
  改 apps\desktop\lib\src\pages\goals_page.dart                        +9 /  -7
  改 apps\desktop\lib\src\pages\goals_blueprint_page.dart             +12 /  -0
  改 apps\desktop\lib\src\l10n\parts\shell.dart                       +20 /  -0
  改 apps\desktop\lib\src\l10n\parts\goals.dart                       +59 /  -0
  改 apps\desktop\lib\src\l10n\l10n_keys.dart                         +32 /  -0
  改 apps\desktop\lib\src\providers.dart                              +40 /  -3
  新 apps\desktop\lib\src\widgets\week_goal_rail_panel.dart            36 行
  新 apps\desktop\test\blueprint_page_test.dart                       108 行
  改 apps\desktop\test\nav_rail_footnote_test.dart                    +69 / -134（全量重写）
  改 apps\desktop\test\task61_l10n_shell_test.dart                    +33 /  -25（全量重写）
  改 apps\desktop\test\l10n_base_test.dart                             +5 /   -5
  改 apps\desktop\test\l10n_harness.dart                              +15 /   -1
  改 apps\desktop\test\nav_shortcut_test.dart                         +13 /   -1
  改 apps\desktop\test\shell_nav_rail_test.dart                       +11 / -111
  改 apps\desktop\test\task64_nav_gear_test.dart                      +12 /  -12
  （`packages\**` 0 行改动；`key_bar.dart` / `today_page.dart` / `day_grid.dart` /
    `project_store.dart` / `goal_upstream_panel.dart` / 月页 / 周页 一行未动）

TEST_COUNT: desktop 882 → 882   （净 0：+2 −2）
  新增（2）：test\blueprint_page_test.dart
    「蓝图页自带标题：中文显示「蓝图」」
    「蓝图页自带标题：英文显示 Blueprint」
  删除（2）：
    test\shell_nav_rail_test.dart 「200% 下底注以整组为换行单位，不出现单字符孤立行」（底注已不存在）
    test\nav_rail_footnote_test.dart 由 N-1…N-6 重写为 F-1…F-5（N-1「底注宣称 Ctrl+1…6」等
    守「底注存在」的用例整体作废，合并为 F-1/F-2 双档零底注）
  用例名改写（不增不减）：shell_nav_rail_test「竖排导航渲染 6 项与 01–06 序号」→「7 项与 01–07」、
    「六项都可点」→「七项都可点」；task64_nav_gear_test「6 个导航项 + 1 枚齿轮」→「7 个」；
    nav_shortcut_test A9 →「Ctrl+5 切项目页；Ctrl+6 切目标页；Ctrl+7 切蓝图页」（新增 Ctrl+7 断言，用例数不变）

L10N_CALIBRATION: getters 503→511 / 全部键值 560→568 / harness 映射 503→511
  证据：`L10nKeys.byGetter.length == 511`、`l10nAccessors.length == 511`、
  三表合并去重 `all.length == 568`（511 + 4 列表型 + 53 方法型），均由 `l10n_base_test.dart:27-33`、
  `:111-118` 实测通过。派工书点名的 `app_l10n_test.dart` **不存在** ⇒ 其「getter 数」断言实际住在
  `l10n_base_test.dart`，已同文件校准（见 §5 歧义 2）。

GIT_STATUS_PORCELAIN: 见 §5.2 原样粘贴（含控制器/接力装置产生的非本棒条目，已标注）

NEW_PROVIDER_NAMES: yearOpenGoalsProvider / monthOpenGoalsProvider / weekOpenGoalsProvider
NEW_L10N_NAMES: shellNavBlueprint / shellNavBlueprintDesc / goalsUpstreamYearTitle /
  goalsUpstreamMonthTitle / goalsUpstreamWeekTitle / goalsUpstreamAddHint /
  goalsUpstreamEmpty / goalsUpstreamAddMenu
PLACEHOLDER_WEEK_GOAL_RAIL_PANEL: 类名 `WeekGoalRailPanel`，文件
  `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart`（36 行，StatelessWidget）；
  挂在 `app.dart:427-431` 今日右轨第 5 块，标题取 `t.goalsUpstreamWeekTitle`；
  内容体仅两行提示文案（`goalsUpstreamEmpty` + `goalsUpstreamAddHint`），不读 provider、不写库、不弹层；
  W3 只需替换该文件内 `build()` 的 children，类名/文件路径/挂载点均不用动。
AMBIGUITIES: 见 §5.1（8 条）
CONCERNS: 见 §5.3（4 条）
```

## 5. 歧义、原样状态与顾虑

### 5.1 AMBIGUITIES（派工书与源码不符 / 契约含糊，均按最保守解释做完）

1. **§3.2 引用的 `ShellSection` 枚举 / `shellSectionFromNavId` / `homeTabFromNavId` 在 `app.dart` 不存在**。
   实际是 `String _nav` + `_content()` 的 `switch`。已按源码实现（`app.dart:351`），零新抽象。
2. **§4.2 要读的 `docs\plan-goals-ui-batch5.md` 不存在**；D-62 裁决真源在
   `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md:9415-9426`（只读，未改）。
3. **§3.4 写 `GoalKind.year` / `GoalKind.month` / `GoalKind.week`**，源码实为
   `GoalKind.yearly` / `monthly` / `weekly`（`providers.dart:875/881/887`）。
4. **§3.4 要求 `Provider<List<Goal>>`**，但 `listGoals` 是 async 且返回 `GoalRow` ⇒ 改用
   `FutureProvider<List<GoalRow>>`（与既有 `goalWeeklyDraftsProvider` 同口径），未改仓储。
5. **§3.5 要求面板 `id: 'week-goals'`**，但 `ShellRailPanel` 无 `id` 字段 ⇒ 省略 id，靠 `title` 标识。
6. **l10n 键名与派工书写法不同**：派工书示例是 `goals-upstream-year-title`，实测必须改成
   `goal-upstream-year-title`。原因：`l10n_base_test.dart` 的键前缀断言只认 `goal-`（对齐既有
   `goal-tab-week` / `goal-title`），写成 `goals-` 直接红。getter 名保持派工书逐字不变。
7. **「未完成」不含已归档**：派工书 §3.4 只写 `!Goal.isDone` 且「未归档」，未给 `archivedAt` 取值口径
   ⇒ 取 `archivedAt == null`（`providers.dart:867-871`）。
8. **深链清单与 §3.1 行号漂移**：派工书给的 `nav_rail.dart:428-560`、`app.dart:204/386-421` 等行号与
   当前源码不符（本棒已改动前置状态），一律以源码为准并在上文给出**改后**行号。

### 5.2 GIT_STATUS_PORCELAIN（原样；`M`/`??` 前 17 条属本棒，其余属控制器/接力装置）

```
 M AGENTS.md                                        <- 非本棒（控制器）
 M apps/desktop/lib/src/app.dart
 M apps/desktop/lib/src/l10n/l10n_keys.dart
 M apps/desktop/lib/src/l10n/parts/goals.dart
 M apps/desktop/lib/src/l10n/parts/shell.dart
 M apps/desktop/lib/src/pages/goals_blueprint_page.dart
 M apps/desktop/lib/src/pages/goals_page.dart
 M apps/desktop/lib/src/providers.dart
 M apps/desktop/lib/src/widgets/shell/nav_rail.dart
 M apps/desktop/test/l10n_base_test.dart
 M apps/desktop/test/l10n_harness.dart
 M apps/desktop/test/nav_rail_footnote_test.dart
 M apps/desktop/test/nav_shortcut_test.dart
 M apps/desktop/test/shell_nav_rail_test.dart
 M apps/desktop/test/task61_l10n_shell_test.dart
 M apps/desktop/test/task64_nav_gear_test.dart
 ?? apps/desktop/lib/src/widgets/week_goal_rail_panel.dart
 ?? apps/desktop/test/blueprint_page_test.dart
 ?? docs/b71-dispatch-w1-nav.md                     <- 非本棒（控制器）
 ?? docs/b71-dispatch-w2-panel.md                   <- 非本棒（控制器）
 ?? docs/b71-dispatch-w3-wire.md                    <- 非本棒（控制器）
 ?? docs/plan-goals-ui-batch7.md                    <- 非本棒（控制器）
 M docs/relay.json                                  <- 非本棒（接力装置）
 M docs/relay/stage-6-report.md                     <- 非本棒（接力装置）
 ?? docs/relay/auto-advance-design.md               <- 非本棒（接力装置）
 ?? docs/relay/gate-green-2026-11-25.md             <- 非本棒（接力装置）
 ?? docs/relay/relay-lock.ps1                       <- 非本棒（接力装置）
 ?? docs/relay/start-relay.ps1                      <- 非本棒（接力装置）
```

源码纪律自检（9 个 lib 文件逐字节实测）：**全部 LF、无 BOM、顶层 `print(` 计数 0**；
新增公开成员均带中文 `///`。

### 5.3 CONCERNS

1. **写集缺 5 个必须改的测试文件**（派工书 §1 未列，但不改就红）：
   `test\l10n_harness.dart`、`test\shell_nav_rail_test.dart`、`test\task64_nav_gear_test.dart`、
   `test\nav_shortcut_test.dart`、`test\nav_rail_footnote_test.dart`（派工书写 `test\shell\`，实际在
   `test\` 根目录）。处理口径：**只改断言/清单/用例名，不动被测行为**；`nav_shortcut_test.dart`
   属新增 `Ctrl+7` 落地证据，必要。
2. **蓝图「角标」口径未实现**（D-62-l「蓝图无角标」）：`ShellNavItem` 本就没有角标字段，无需代码，
   仅登记为「已核对、零改动」。
3. **`KeyBar` 不显示 `Ctrl+7`**：`key_bar.dart:78-88` 的 `shellKeyHintsFor` 只有 `Ctrl+1…4`/`Ctrl+5`/
   `Ctrl+6`。它属 W2/W3 写集（本棒只读），若 W2 要补 `Ctrl+7` 提示需自行改并校准
   `shell_key_hints_test.dart`。
4. **真机装机版 `actlog`（PID 91364）全程未动**：未打包、未安装、未触碰 `D:\Program Files\actlog`；
   本棒只交源码 + 门禁数字，**无装机截图证据**，需要界面证据请控制器安排打包验收。

## 6. 本轮踩到的新坑（供后续棒复用）

1. **删 `import 'key_bar.dart';` 会连带打断 `shellLocalizationsOf`**：该 helper 住在 `key_bar.dart`，
   壳层三个文件共用。删完 `analyze` 报 `undefined_method`（`nav_rail.dart:100`、
   `week_goal_rail_panel.dart:20`）⇒ 只要还用这个取法，import 就删不得（本棒已补回，
   `week_goal_rail_panel.dart` 新增 `import 'shell/key_bar.dart';`）。
2. **PowerShell 函数里改 `$script:t` 不回写外层变量**：批量替换必须顶层顺序 `.Replace()`，
   或落成 `.ps1` 执行，或用 `edit`/`write`。本轮补丁脚本 `apps\desktop\build\_w1_patch_nav_tests.ps1`。
3. **正则数 `byGetter` 条目会少算 12 条**（跨行条目 `'key':` 换行再写值）⇒ 本轮就出现
   「正则报 499 / 实际 511」。计数一律以 `flutter test` 的 `Expected/Actual` 为准。
4. `flutter test | Out-String` 会整段丢输出 ⇒ 用 `*>` 重定向到日志后 `Select-String` 抓关键行。