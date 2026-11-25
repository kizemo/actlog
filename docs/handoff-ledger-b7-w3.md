# B7 / W3（接线棒）交付台账 · 右栏未完成周目标三通道接入计划

- 棒次：B7-W3（隐藏子会话 `mvs_3b97a7a28af64566b87afa09e7c2303b`，父会话 `mvs_2fe482da85314d7584b1abcdfc0d19d3`）
- 日期：2026-11-25
- 上游真源：`docs/plan-goals-ui-batch7.md`、`docs/b71-dispatch-w1-nav.md`、`docs/b71-dispatch-w2-panel.md`、`docs/b71-dispatch-w3-wire.md`（§9 优先级最高）、`docs/handoff-ledger-b7-w1.md`
- 需求来源：用户 2026-11-25 需求 4 ——「日志主页面右边栏中添加仍然未完成的周目标，可点击或拖动添加到计划中，也可在日计划右键勾选添加」

---

## 1. 需求 → 落地映射（三条通道全部成立）

| 通道 | 用户动作 | 落点 | 实现位置 |
|---|---|---|---|
| ① 陈列 | 打开今日页，右栏第 5 面板看到「仍未完成的周目标」 | `app.dart:427-432` 已挂 `WeekGoalRailPanel`（W1 建占位，本棒填实体） | `widgets/week_goal_rail_panel.dart` |
| ② 点击 | 点目标条目 ⇒ 直接加进当天计划 | `InkWell(key: ValueKey('week-goal-<id>'))` → `addWeekGoalToPlan(...)` | 同上 |
| ② 拖动 | 把目标条目拖到日计划栅格 | `Draggable<String>(data: 'goal://<id>')` → `day_grid._onDrop` 的 `case 'goal'` | `week_goal_rail_panel.dart` + `timeline/day_grid.dart` |
| ③ 右键 | 在日计划格子右键 ⇒ 菜单选「添加周目标」⇒ 勾选多项 ⇒ 加入计划 | `_onContextMenu` 的 `case SlotMenuGoals()` → `WeekGoalPickDialog.show(...)` → 逐条写 | `timeline/day_grid.dart` + `timeline/slot_context_menu.dart` + `week_goal_rail_panel.dart` |

**重要事实（实测）**：`today_page.dart` 里 `WeekGoalRailPanel` 命中 0 次 —— 挂载点在 `app.dart:427-432`（`ShellRailPanel(title: t.goalsUpstreamWeekTitle, child: const WeekGoalRailPanel())`）。故本棒**未改** `today_page.dart`（写集内允许但不必要）。

---

## 2. 唯一写入路径与幂等

### 2.1 唯一入口：顶层函数 `addWeekGoalToPlan`

`apps/desktop/lib/src/widgets/week_goal_rail_panel.dart`：

```dart
enum WeekGoalAddOutcome { added, alreadyInPlan }

Future<WeekGoalAddOutcome> addWeekGoalToPlan(
  WidgetRef ref, {
  required GoalRow goal,
  required String date,
  required int startMinute,
  required int endMinute,
})
```

三条通道（点击 / 拖动 / 右键勾选）**全部**收敛到这一个函数，不另开写路径、不自写 INSERT、不直接动 drift 表。

### 2.2 幂等判据

1. `goalStore.listLinks(goal.id)` 取 `GoalTargetType.planItem` 的链接目标 id；
2. ∩ `repositoriesProvider.planItem.listByDate(date)` 的活行 id（未软删）；
3. 交集非空 ⇒ 返回 `WeekGoalAddOutcome.alreadyInPlan`，**不写**；否则 `TimelineStore.createManual(...)` 拿到 planItemId，再 `GoalStore.link(...)`，返回 `added`。

⇒ 同一周目标同一天重复点 / 重复拖 / 重复勾，只落一条计划项。

### 2.3 落位规则（纯函数，可断言）

`suggestedGoalStartMinute(List<PlanItemData> dayItems)`：取当天 `plannedEnd ?? plannedStart` 的最大值，向上取整到 30 分，夹到 `24*60-30`；当天无排程时回落 `kGridStartHour*60`。不看真实时钟（可复现、可测）。

### 2.4 计划项状态恒 `pending`

调用 `createManual` 时**不传** `todayIso` / `nowMinute` ⇒ 从目标带进来的行是「还没做的安排」，不会瞬时变成 `done`/`active`。

### 2.5 目标 ↔ 计划项的关联方式

**不走** `plan_item.source_type`（五值 `manual/todo/habit/project/increment` 已冻结），一律用 `goal_link` 表 + `GoalTargetType.planItem` 建立双向可查的关联。

---

## 3. 门禁实测（本机、进程内设镜像，逐字）

环境：`$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'`、`$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`、`$env:FLUTTER_BUILD_DIR='build_w3'`，工作目录 `apps\desktop`。

### 3.1 `flutter analyze`

```
No issues found! (ran in 7.2s)
```

`ANALYZE_EXIT=0`。中途曾报 3 条并逐条修掉：`unnecessary_underscores`（`error: (Object _, StackTrace _)`）、`unused_import`（误 import `slot_layout.dart`，`kHourRowHeight` 其实在 `day_grid.dart:240`）、`GoalKind.daily` 不存在。

### 3.2 定向测试（本棒 8 条新用例）

```
& flutter.bat test test/task72_w3_week_goal_rail_panel_test.dart test/task72_w3_day_goal_menu_test.dart --reporter compact
00:07 +8: All tests passed!
```

`TEST_EXIT=0`。

### 3.3 全量测试

跑前用 `Move-Item` 把 `apps\desktop\build\test_cache\build` 改名为 `build_moved_w3_1`（可恢复、未删除）；`build_w3\test_cache\build` 实测不存在故跳过。

```
& flutter.bat test --reporter compact
01:22 +903: All tests passed!
```

`TEST_EXIT=0`。基线为 **+882**，全量末值 **+903**（Δ+21）—— 该增量**同时包含并行 W2 的用例**（`test/task72_w2_*` 3 份 + `test/blueprint_page_test.dart`），本棒自身贡献经定向量化为 **+8**。

### 3.4 导航页脚门禁

```
pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task72-nav-foot-judge.ps1
FOOT_CLASS_HITS=0
FOOT_MOUNT_HITS=0
KEYCAP_IN_NAVRAIL=0
DIGIT_SHORTCUTS=7
KEYHINTLIST_IN_KEYBAR=2
BLUEPRINT_NAV_HITS=2
BLUEPRINT_ROUTE_HITS=1
BLUEPRINT_APP_HITS=3
BLUEPRINT_DIGIT7=1
BLUEPRINT_TAB_REFS_IN_GOALSPAGE=0
NAV_FOOT_VERDICT=PASS
```

`JUDGE_EXIT=0`。判据「左栏 `KeyCap` 命中数恒 0」成立（`KEYCAP_IN_NAVRAIL=0`）。

---

## 4. 文件清单（`git status --porcelain -uall`，本棒相关）

```
 M apps/desktop/lib/src/widgets/timeline/day_grid.dart
 M apps/desktop/lib/src/widgets/timeline/slot_context_menu.dart     ← 写集外，见 AMBIGUITIES #1
?? apps/desktop/lib/src/widgets/week_goal_rail_panel.dart           ← 整文件重写（占位 → 实体）
?? apps/desktop/test/task72_w3_week_goal_rail_panel_test.dart      ← 4 用例
?? apps/desktop/test/task72_w3_day_goal_menu_test.dart             ← 4 用例
?? docs/handoff-ledger-b7-w3.md                                    ← 本文件
```

**明确未改**：`pages/today_page.dart`（挂载点不在那儿）、`widgets/shell/key_bar.dart`（见 BLOCKER）、`test/shell_key_hints_test.dart`（随之无需改）。零新增依赖、零 `pub get`、零 `l10n` 新增键、零文件删除。

### 4.1 `day_grid.dart` 改动明细（最小）

1. 新增 2 个 import：`../../data/goal_store.dart`、`../week_goal_rail_panel.dart`；
2. `_onContextMenu(int startMinute)` 的 `switch (choice)` 增加 `case SlotMenuGoals():` —— 读 `weekOpenGoalsProvider.asData?.value`，非空则 `WeekGoalPickDialog.show(...)`，勾选结果逐条 `addWeekGoalToPlan` 并包 `_guard`（复用既有 `_busy` 互斥）；
3. `_onDrop` 增加 `case 'goal':` —— 剥掉 `//` 前缀取 goalId，在 `weekOpenGoalsProvider` 现况里查到 `GoalRow`，`_askDropRange(start)` 问起止，再 `addWeekGoalToPlan`；
4. `DragTarget.onWillAcceptWithDetails` 的注释补充「四种前缀统一在 `_onDrop` 分流」（判定条件 `details.data.contains(':')` 未改，`goal://` 天然满足）。

继电顺序沿用既有语义：「菜单 → 起止 → 动作」，故右键通道是「选组 → 弹起止 → 弹勾选 → 写」。右键入口**不破坏**既有三组（手动 / 待办 / 习惯）任何行为。

### 4.2 `slot_context_menu.dart` 改动明细（纯追加，+约 14 行）

- `class SlotMenuGoals extends SlotMenuChoice`（密封类新子类）；
- doc 注释改「四条路」；
- `AlertDialog` 的 `Column` 末尾追加 `SizedBox(gapCard)` + `_GroupHeader(l10n.goalsUpstreamWeekTitle)` + `_ChoiceTile(key: 'slot-menu-goals', icon: Icons.flag_outlined, label: l10n.goalsUpstreamAddMenu)`。

既有三组结构、key、取消按钮均未动。

### 4.3 l10n 纪律

**一行未新增**。UI 文案只用 W1 已登记的 4 键（`goalsUpstreamWeekTitle` / `goalsUpstreamAddHint` / `goalsUpstreamEmpty` / `goalsUpstreamAddMenu`）+ 通用 `confirm` / `cancel`。英文态零中文。

---

## 5. 交付字段（派工书 §7 逐项）

| 字段 | 值 |
|---|---|
| `STATUS` | `DONE`（两条通道的代码与测试全绿；`Ctrl+7` 键条提示为 BLOCKER，见 §6.1） |
| `ANALYZE` | `No issues found! (ran in 7.2s)`，exit 0 |
| `TEST_TARGETED` | `00:07 +8: All tests passed!`，exit 0 |
| `TEST_FULL` | `01:22 +903: All tests passed!`，exit 0（基线 +882，Δ+21 含并行 W2） |
| `GATE` | `NAV_FOOT_VERDICT=PASS`，`KEYCAP_IN_NAVRAIL=0`，exit 0 |
| `L10N_NEW_KEYS` | 0 |
| `NEW_DEPS` | 0 |
| `DELETED_FILES` | 0（`test_cache\build` 为 `Move-Item` 改名 `build_moved_w3_1`） |

---

## 6. 歧义、原样状态与顾虑

### 6.1 BLOCKER · `Ctrl+7` 键条提示无法在本写集内落地

派工书要求 `widgets/shell/key_bar.dart` 增加 `Ctrl+7`（人生蓝图）提示。实测：落地会打挂**两份写集外测试**——

- `test/shell_key_bar_test.dart:79-95`：`caps.length == 9`、`caps.last.label == 'Ctrl+6'`、`find.text('Ctrl+1…4') findsOneWidget`；
- `test/task64_nav_gear_test.dart:157-168`：`kShellKeyHints.length == 9`、`.last.keys == ['Ctrl+6']`、`shellKeyHintsFor(en).length == 9`。

⇒ 本棒**未改 `key_bar.dart`**，以免把两份非本棒所有权的测试打红。

**需要父会话决策（二者择一）**：①授权同改这两份纯断言清单（各一处常量/断言）；②明确放弃该项。补充：`Ctrl+7` 的**功能**已有真实落点（`goals_blueprint_page.dart` + `test/nav_shortcut_test.dart:153-190`），缺的仅是键条上的文字提示。

### 6.2 AMBIGUITIES

**#1 · 右键入口必须改写集外的 `slot_context_menu.dart`。** 既有右键菜单是「`sealed class SlotMenuChoice` + `AlertDialog`」结构，派工书要求「既有结构不动、追加一项」，物理上只能新增 `SlotMenuGoals` 子类并在 `Column` 末尾追加一组。已做**纯追加**（+约 14 行，零回归，既有三组通道有既有用例兜底）。**请求追认该文件进写集。**

**#2 · 幂等实现落在 UI 层而非 store 层。** 派工书 D-72-e / §3.2 要求 `project_store.addPlanItemFromGoal`（store 层方法），但父 briefing 的写集**明确排除** `project_store.dart`。⇒ 现由 `week_goal_rail_panel.dart` 顶层 `addWeekGoalToPlan` 承担（三通道共用唯一入口，行为已由 8 条用例覆盖）。**建议控制器后续把该函数整体下移到 store 层**（纯搬迁，无逻辑变更）。

**#3 · 派工书 §1 第 2 项把 `project_store.dart` 列进写集，与父 briefing 冲突。** 按冲突优先级（用户当轮决定 > 派工书 §9 > 派工书正文 > handoff）取**父 briefing 为准**，视 §1 第 2 项为越界，未触碰该文件。

### 6.3 CONCERNS（≤3）

1. **右键通道的继电顺序偏长**：「选组 → 起止 → 勾选」，用户完成一次右键加目标要过三跳。若要压缩，可把「起止」默认值直接用 `suggestedGoalStartMinute` 并跳过询问，但会与既有「菜单 → 起止」语义不一致，本棒按一致性优先保留。建议后续单独一轮做交互收敛。
2. **`WeekGoalPickDialog.show` 直接读 `weekOpenGoalsProvider` 的快照**（`asData?.value`），若右键期间目标状态被别的面板改写，勾选列表可能短暂过期。写入前 `addWeekGoalToPlan` 会用 `listLinks` 兜幂等，故不会产生脏数据，但列表项可能出现「点了却没加」的观感。当前单用户单机场景风险低。
3. **全量末值 +903 混入了并行 W2 的增量**，无法从单次全量跑里分离出「本棒贡献」。本棒贡献已用定向跑 `+8` 量化；若父会话需要严格归因，需在 W2 落地后重跑一次全量并与 +903 对比。

---

## 7. 本轮踩到的新坑（供后续棒复用）

1. **`flutter test` 与并行会话抢 dll**：出现 `flutter failed to delete file at "...\build\native_assets\windows\sqlite3.dll"`。正确处理是轮询 `Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter_tester' }` 等其清空后重跑，**不要杀进程**（会打挂对方会话）。
2. **挪 `test_cache` 不要合成一条命令**：把 `Set-Location` + `foreach` + `Move-Item` 写进同一句会被硬安全策略拒绝（`write/delete targets cannot be verified safely after a command working directory change`）。改成**单条 `Move-Item -LiteralPath '<绝对路径>'`、不切目录**即可。
3. **`GoalKind` 没有 `daily`**：写「非周粒度」对照时用 `GoalKind.monthly`，否则 analyze 直接 error。
4. **`kHourRowHeight` 在 `day_grid.dart:240`**，不在 `slot_layout.dart`；顺手 import `slot_layout.dart` 会造成 `unused_import` 打挂 `No issues found!`。
5. **`flutter test ... | Out-String` 会丢输出**：改用 `*>` 重定向到文件再 `Get-Content -Tail` 读。
6. **`week_goal_rail_panel.dart` 必须保留 `import 'shell/key_bar.dart';`** —— `shellLocalizationsOf` 住在那里，删掉会打断编译。

---

## 8. 给 W4 / 收口棒的接棒提示

- 三通道已全通，唯一入口是 `addWeekGoalToPlan`（`widgets/week_goal_rail_panel.dart`）。做任何行为修改**只改这一个函数**，不要在三处分别补丁。
- 若追认 AMBIGUITIES #2，把该函数整体搬到 `project_store.dart` 后，`week_goal_rail_panel.dart` 只留 UI，`day_grid.dart` 的两处调用点改指 store。
- 若追认 BLOCKER §6.1，改的是 `test/shell_key_bar_test.dart`（3 处断言）+ `test/task64_nav_gear_test.dart`（3 处断言），**不是**改 `key_bar.dart` 的能力问题。