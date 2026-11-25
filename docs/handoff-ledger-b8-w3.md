# B8-W3 收口台账 · 今日页撤掉目标写入入口（右栏只读 + 右键菜单去目标组 + 日格去 goal drop）

- 提交状态：**未提交**（按 R3 由控制器统一 commit；本棒 HEAD = `dbd95cd`，门禁读数 `AHEAD=10`）
- 环境：Windows / pwsh 7.7.0 / Flutter（进程内设镜像 `pub.flutter-io.cn` + `storage.flutter-io.cn`）
- 编码：UTF-8 无 BOM，纯 LF（本文件 `CR=0`，自检见 §11）

---

## 1. 背景与目标

**一句话**：把「今日页」上三条目标写入通道（右栏点击加入当天、右栏拖进日格、日格右键勾选目标）
全部撤掉，右栏退化为**只读展示**；今日页此后只保留「手填 / 待办 / 习惯」三条自有入口。

**用户裁决逐字**：「保留只读展示」（`docs/b8-scope-decision.md` U1）。

**上游文档全路径**（下一棒不必回翻派工书）：

| 文档 | 绝对路径 | 作用 |
|---|---|---|
| 派工书 | `F:\soft\00selfmade\practilog\docs\b83-dispatch-w3.md` | 本棒唯一规格（§2 锚点 / §3 写集 / §4 实现 / §5 TDD / §6 门禁 / §7 台账 / §9 坑） |
| 范围裁决 | `F:\soft\00selfmade\practilog\docs\b8-scope-decision.md` | U1 已裁「只读展示」；U3（月/周页「添加到当前周期」）**仍未裁** |
| 上一棒台账 | `F:\soft\00selfmade\practilog\docs\handoff-ledger-b8-w2.md` | 体例样板 + 920 基线来源 |
| 项目规范 | `F:\soft\00selfmade\practilog\AGENTS.md` | R1–R8 铁律、装置地图、本机坑 |

**关键事实订正**（派工书 §2.1 已推翻，本轮再次盘上确认）：
范围书写的 `apps\desktop\lib\src\widgets\goals\week_goal_rail_panel.dart` **不存在**；
真实路径是 `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart`（无 `goals\` 子目录）。
另：`docs/b8-scope-decision.md` 里写的 907 测试基线**已废**，本棒基线是 **920**。

---

## 2. 逐文件改动表（逐文件盘上回读，非摘要抄录）

`OLD` = `git show HEAD:<path>` 的行数（字节为 UTF-8 重算值，含换行规范化差异，标 `~`）；
`NEW` = `(Get-Item).Length` 与 `ReadAllLines` 计数；`SHA16` = `Get-FileHash -Algorithm SHA256` 前 16 位（本轮改后）。

| 文件 | 行数 OLD → NEW | 字节 OLD → NEW | CR | SHA16（改后） | 关键 diff |
|---|---|---|---|---|---|
| `apps/desktop/lib/src/widgets/week_goal_rail_panel.dart` | 342 → 102（−240） | ~12,939 → 4,067 | 0 | `5D4B8DB1A2B8D5C3` | 整文件重写：删四条写入通道与提示行；`_tile` 由 `Draggable<String>` + `InkWell(onTap:)` 改为纯 `Container(key:)` + `Text(maxLines:2, overflow: ellipsis)`；三态 ValueKey 与 `week-goal-${goal.id}` 逐字保留 |
| `apps/desktop/lib/src/widgets/timeline/slot_context_menu.dart` | 256 → 239（−17） | ~7,821 → 7,036 | 0 | `5398B66B35526EA9` | 删 `SlotMenuGoals` 类与菜单目标组（`_GroupHeader(goalsUpstreamWeekTitle)` + `_ChoiceTile('slot-menu-goals')` + 其前置 `SizedBox`）；类文档「四条路」改「三条路」并补撤除说明 |
| `apps/desktop/lib/src/widgets/timeline/day_grid.dart` | 1,604 → 1,549（−55） | ~66,193 → 64,111 | 0 | `EC51D82CD78E4623` | 删 `case SlotMenuGoals():`（右键菜单构造）与 `case 'goal':`（拖放落点）两整块；删 import `data/goal_store.dart` 与 `week_goal_rail_panel.dart`；`:339` 注释前缀清单收敛为 `plan:` / `todo:` / `habit:` |
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 965 → 958（−7） | ~24,716 → 24,499 | 0 | `3B29EF26CF7B8D0E` | 删 abstract getter（原 `:60-61`）、zh 实现（原 `:380-381`）、en 实现（原 `:686-687`）；`goalsUpstreamAddHint` / `goalsUpstreamEmpty` 保留 |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 2,534 → 2,532（−2） | ~101,704 → 101,534 | 0 | `10D2642DA014F150` | 删常量声明（原 `:1621-1622`）与 `byGetter` 映射条目（原 `:2017`） |
| `apps/desktop/test/l10n_harness.dart` | 808 → 808（0） | ~47,857 → 47,779 | 0 | `32542893334D39E1` | 删访问器登记（原 `:125`）；删除后 `:124` 与 `:126` 相邻，`byGetter` 与访问器表仍一一对应 |
| `apps/desktop/test/l10n_base_test.dart` | 664 → 664（0） | 29,023 → 29,023（0） | 0 | `DA345227EFBCE53E` | 五处计数 `523→522`（`:27` 题名 / `:28` byGetter / `:29` l10nAccessors）与 `580→579`（`:111` 题名 / `:117` all.length）；`byListGetter 4`（`:36`）与 `byMethod 53`（`:45`）**未动**。三个数字等长，故字节数零变化 |
| `apps/desktop/test/task72_w2_goal_upstream_panel_test.dart` | 233 → 232（−1） | ~8,157 → 8,107 | 0 | `A6B9C4A762801C17` | 只删 `expect(t.goalsUpstreamAddMenu, isNotEmpty);`（原 `:230`）+ 题名「六个」→「五个」（`:220`）；该文件测的是**保留组件** `goal_upstream_panel.dart`，其余 8 例与断言一律不动 |
| `apps/desktop/test/task72_w3_day_goal_menu_test.dart` | 319 → 322（+3） | ~11,726 → 11,543 | 0 | `3531387382ED1F5B` | 4 例整文件重写为「移除守卫」；新增 `_kMenuCancel` / `_kDragSource` 常量、`_Harness.mount` 的 `overlay` 参数、`_dragTo` 三步移动辅助；删去不再使用的 `_byTitle` / `_kPickConfirm` / `_openGoalPicker` |
| `apps/desktop/test/task72_w3_week_goal_rail_panel_test.dart` | 239 → 240（+1） | ~8,812 → 8,891 | 0 | `044C6EA19545EBDB` | 4 例重写为「只读守卫」；import 收缩（去掉 `slot_state.dart` / `timeline_store.dart`）；顺带修掉原第 2 例的笔误（造的是「月目标不该出现」却断言 `'日目标不该出现在这里'`） |
| `apps/desktop/test/task72_w4_week_goal_rail_states_test.dart` | 210 → 217（+7） | ~7,919 → 8,263 | 0 | `1E95E63FF345E313` | 三态 3 例保留（loading / error / empty 的键位与文案不变，只在后两例追加「不再有 hint / 不再有 `Draggable`」）；第 4 例改写为「今日页不再产出 `goal://` 拖拽源，协议常量仍单一来源」；文件头 4 条注释同步 |

**净变化**：lib 4 文件 −6 行、test 4 文件 +9 行、l10n 2 文件 −7 行、`l10n_harness.dart` ±0。
**`packages/**` 零改动**（`git diff --stat -- packages` 输出为空）。
**禁改四文件一字未改**：`goal_upstream_panel.dart` / `providers.dart` / `app.dart` / `goal_store.dart`
（`git diff --stat` 对这四个路径输出为空，见 §6.4 自检项）。

新增文件仅本台账；**新增 l10n 键 0 个，删除 l10n 键 1 个**（净 −1）。

---

## 3. 删除清单（逐项）

### 3.1 类型 / 类

| 符号 | 原位置 | 说明 |
|---|---|---|
| `SlotMenuGoals extends SlotMenuChoice` | `slot_context_menu.dart` | 右键菜单「未完成周目标」组的选项载体（sealed 子类），连同文档注释整段删除 |
| `WeekGoalAddOutcome` | `week_goal_rail_panel.dart` | 右栏点击加入的返回结果枚举 |
| `WeekGoalPickDialog` + `_WeekGoalPickDialogState` | `week_goal_rail_panel.dart` | 起止时间选择对话框（点击通道的中间层） |

### 3.2 函数 / 方法

| 符号 | 原位置 | 说明 |
|---|---|---|
| `addWeekGoalToPlan(...)`（顶层） | `week_goal_rail_panel.dart` | 写 `planItem` + `goals.listLinks` 的唯一入口 |
| `suggestedGoalStartMinute(...)`（顶层） | `week_goal_rail_panel.dart` | 点击通道的落点建议时刻 |
| `_WeekGoalRailPanelState._addOne(...)` | `week_goal_rail_panel.dart` | 单条目标的实际写库路径 |
| `case SlotMenuGoals():`（switch 分支） | `day_grid.dart` | 右键菜单的目标组消费点 |
| `case 'goal':`（switch 分支） | `day_grid.dart` | `_onDrop` 里 `goal://<id>` 的落点消费点 |

### 3.3 l10n 键

| 键 | 常量值 | 连带清理（12 处） |
|---|---|---|
| `goalsUpstreamAddMenu` | `'goal-upstream-add-menu'` | `parts/goals.dart` 3（abstract + zh + en）、`l10n_keys.dart` 2（常量 + 映射）、`l10n_harness.dart` 1（访问器）、`l10n_base_test.dart` 5（523/522/522 + 580→579 两处）、`task72_w2_*_test.dart` 1（断言行） |

删后 `l10n_base_test.dart` 自洽：`522 + 4 + 53 = 579`（`:28` / `:29` / `:36` / `:45` / `:117` 五处读数一致）。

### 3.4 ValueKey（随宿主一起消失，未单独改常量）

| Key | 原宿主 | 现状 |
|---|---|---|
| `week-goal-add-hint` | 右栏提示 `Text` | 宿主 `Text` 已删；`lib/` 内 0 命中 |
| `slot-menu-goals` | 菜单目标组 `_ChoiceTile` | 宿主 tile 已删；`lib/` 内 0 命中 |

**保留未动**（本棒契约）：`week-goal-loading` / `week-goal-error` / `week-goal-empty` /
`week-goal-${goal.id}` / `slot-menu-manual` / `slot-menu-todo-${id}` / `slot-menu-habit-${id}` /
`slot-menu-cancel` / `day-grid` / `DragTarget<String>` / `onSecondaryTapDown`。

### 3.5 保留但今日页不再消费的符号（重要，别误删）

- `goalDragPayloadFor` / `goalIdFromDragPayload`：仍在
  `apps/desktop/lib/src/widgets/goal_upstream_panel.dart` 内，月页 / 周页仍用它产出 `goal://<id>`。
  **今日页不再有消费方**（`_onDrop` 已无 `goal:` 前缀分支）。
- `goalsUpstreamAddHint` l10n 键：月页 `goals_month_page.dart:242` 与周页 `goals_week_page.dart:125`
  仍在用，故**只删面板里那一次 `Text`，不删键**。
- `weekOpenGoalsProvider`（`providers.dart:885`）：右栏仍靠它取只读数据，**未删**。

---

## 4. 测试处置逐文件说明

四个文件**未新建、未清空**，全部在既有文件上改写；每文件仍 ≥ 3 例，无空壳。

### 4.1 `task72_w3_week_goal_rail_panel_test.dart`（原 4 例 → 现 4 例）

| # | 题名 | 测什么（断言比原来更强之处） |
|---|---|---|
| 1 | `B8/W3：没有未完成周目标时只有空态，没有添加提示也没有可拖条目` | `_kEmpty` 存在；`goalsUpstreamEmpty` 文案在；**`_kHint` findsNothing + `goalsUpstreamAddHint` 文案 findsNothing + 面板内 `Draggable<String>` findsNothing**（原来只断言空态存在） |
| 2 | `B8/W3：只列未完成**周**目标，且条目不再是拖拽源` | 只列 weekly；月目标不出现；**条目内无 `Draggable` / 无 `InkWell`**。顺带修掉原例笔误（原名造月目标却断言「日目标不该出现在这里」，现断言实际标题字符串） |
| 3 | `B8/W3：点击条目零写入——不建计划行、不建目标关联、不弹确认框` | 用 `tester.tapAt(tester.getCenter(tile))` 点条目（只读文本无手势，避免 hit-test 警告）后：`planItem.listByDate` isEmpty、`goals.listLinks(goalId)` isEmpty、`AlertDialog` findsNothing |
| 4 | `B8/W3：只读结构守卫——面板内无可点 / 可拖控件，条目是两行省略纯文本` | `find.descendant(of: panel, matching: InkWell)` findsNothing、`Draggable<String>` findsNothing、两条目标都列出、`Text.maxLines == 2`、`overflow == TextOverflow.ellipsis` |

### 4.2 `task72_w3_day_goal_menu_test.dart`（原 4 例 → 现 4 例）

| # | 题名 | 测什么 |
|---|---|---|
| 1 | `B8/W3：右键菜单不再有「未完成周目标」组，手填组仍在` | `_kMenuGoals`（`slot-menu-goals`）findsNothing；菜单内 `goalsUpstreamWeekTitle` findsNothing；`_kRangeConfirm` findsNothing；`AlertDialog` findsOneWidget（手填起止框仍在） |
| 2 | `B8/W3：菜单仍是「手填 / 待办 / 习惯」三组，取消能关` | 用 `find.descendant(of: find.byType(SlotContextMenu), ...)` 精确定位（避开日格其它同名文案），断言 `timelineTodoGroup` / `timelineHabitGroup` / `timelineTodoPoolEmpty` / `timelineHabitEmpty` / `_kMenuCancel`；点取消后 `SlotContextMenu` findsNothing 且库仍空 |
| 3 | `B8/W3：外部拖入 goal://payload ⇒ 零写入、不弹起止框` | `_Harness.mount` 新增可选 `overlay`，用 `Stack` + `Positioned(left:4, top:4)` 挂外部 `Draggable<String>`（键 `w3-drag-source`）；`_dragTo` 三步移动；拖完断言库空、无对话框。拖拽源 payload 用 `find.ancestor(of: find.byKey(_kDragSource), matching: find.byType(Draggable<String>))` 定位，并双断言 `source.data == 'goal://$goalId'` 与 `== goalDragPayloadFor(goalId)` |
| 4 | `B8/W3：既有「手填」通道不回归（选组 → 起止 → 标题 → 落库）` | 端到端走手填路径，确认撤目标组没有误伤三条保留通道 |

`SlotMenuGoals` 类型已删 ⇒ 任何试图构造该菜单项的代码**编译期即红**，此为最强守卫（测试注释已写明）。

### 4.3 `task72_w4_week_goal_rail_states_test.dart`（原 4 例 → 现 4 例）

| # | 题名 | 变化 |
|---|---|---|
| 1 | `B7/W4：加载中只出加载占位，不伪装成「暂无未完成目标」` | 保留；`_kHint` 断言由 findsOneWidget 改 findsNothing |
| 2 | `B7/W4：读库失败时出错误态且错误原文可见，不伪装成空态` | 保留原断言 |
| 3 | `B7/W4：真空态仍是 week-goal-empty（回归锁）` | 保留；追加 `_kHint` findsNothing + `Draggable` findsNothing |
| 4 | `B8/W3：今日页不再产出 goal:// 拖拽源，协议常量仍单一来源`（原「拖拽 payload 与 `goalDragPayloadFor` 同源」） | 断言面板内无 `Draggable`；`goalDragPayloadFor(goalId) == 'goal://<id>'`；`goalIdFromDragPayload` 往返一致 |

文件头 4 条注释同步重写（原描述第 4 条协议的文字已不成立）。

### 4.4 `task72_w2_goal_upstream_panel_test.dart`（原 9 例 → 现 9 例）

只删 `:230` 一行断言 + 题名「六个」→「五个」（`:220`）。该文件测的是**保留组件**
`goal_upstream_panel.dart`（月/周页在用），故其余 8 例与断言一律不动。

### 4.5 例数对账

| 文件 | HEAD 例数 | 现在例数 |
|---|---|---|
| `task72_w3_week_goal_rail_panel_test.dart` | 4（`testWidgets`） | 4（`testWidgets`） |
| `task72_w3_day_goal_menu_test.dart` | 4（`testWidgets`） | 4（`testWidgets`） |
| `task72_w4_week_goal_rail_states_test.dart` | 4（`testWidgets`） | 4（`testWidgets`） |
| `task72_w2_goal_upstream_panel_test.dart` | 9（5 `testWidgets` + 4 `test`） | 9（5 + 4，只删一行断言） |
| **合计** | **21** | **21（净增 0）** |

`HEAD:...` 侧例数由 `git show HEAD:<path> | Select-String 'testWidgets\('` 盘上回读。

---

## 5. TDD 时序（真红 → 绿，非注入红）

本轮**拿到的是时序红灯**：先改测试、产品代码当时一行未动，跑出：

```
reports/task75-red.txt   28,220 B   EXITCODE=1   末段 `00:06 +3 -9: Some tests failed.`
reports/task75-red-err.txt   103 B  （仅镜像提示行）
```

3 过 9 败，**失败原因全部是断言**（提示行仍在、`slot-menu-goals` 仍在、`Draggable` 仍在、
点击仍写库、拖拽仍被接住），**不是编译错误** ⇒ 判别性成立。

红阶段暴露并当场修掉的一处测试缺陷：`task72_w3_day_goal_menu_test.dart` 原先用
`tester.widget<Draggable<String>>(find.byType(Draggable<String>))` 断言外部拖拽源 payload，
而产品未改时面板自带 `Draggable` ⇒ `StateError: Bad state: Too many elements`；
已改为 `find.ancestor(of: find.byKey(_kDragSource), matching: find.byType(Draggable<String>))`。

绿阶段（产品 + l10n 同批落盘后，跑本棒相关的 5 个文件）：

```
reports/task75-green.txt   13,181 B   EXITCODE=0   末段 `00:07 +44: All tests passed!`
```

`+44` = 4 + 4 + 4 + 9（w2 全 9 例）+ 23（`l10n_base_test.dart` 全部例数）的实际执行计数
（`l10n_base_test.dart` 整文件参与本轮，故远大于 21）。

---

## 6. 门禁与测试数字

### 6.1 worker 本轮实测（证据文件已在 `reports/`，勿入库）

| 环节 | 证据路径 | 字节 | 末段原文 | 本轮 EXITCODE |
|---|---|---|---|---|
| desktop analyze | `reports/task75-analyze.txt` | 97 | `No issues found! (ran in 11.4s)` | 0 |
| 红（时序红） | `reports/task75-red.txt` | 28,220 | `00:06 +3 -9: Some tests failed.` | 1 |
| 绿（本棒 5 文件） | `reports/task75-green.txt` | 13,181 | `00:07 +44: All tests passed!` | 0 |
| desktop 全量 | `reports/task75-full.txt` | 266,401 | `01:51 +920: All tests passed!` | 0 |
| 门禁本地自检 stdout | `reports/task75-gate.txt` | 2,673 | `RUN_AT=2026-11-25 21:38:49` | 0 |
| 门禁 summary | `reports/task51-gate/summary.txt` | 1,913 | `RUN_AT=2026-11-25 21:38:49` | — |

**全量 `N = 920`，与本棒基线 920 相同 ⇒ 本棒净增 0**（四个测试文件例数 4/4/4/9 前后一致，
见 §4.5）。数字与 `DESKTOP_BASELINE=596` / `DESKTOP_DELTA=324` 自洽（324 为累计增量，非本棒增量）。

### 6.2 门禁全字段（`pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests 920`）

```
GATE_VERDICT=PASS
GATE_FAILURES=0
DESKTOP_TESTS=920
DESKTOP_BASELINE=596
DESKTOP_DELTA=324
DESKTOP_EXPECTED=920
CORE_DATA_TESTS=204
CORE_DB_TESTS=96
CORE_DOMAIN_TESTS=91
DESKTOP_ANALYZE=VERBATIM
CORE_DATA_ANALYZE=VERBATIM
CORE_DB_ANALYZE=VERBATIM
CORE_DOMAIN_ANALYZE=VERBATIM
VIOLATIONS=0
OUT_OF_SET=0
GATE_EXCLUDED=4
STATUS_LINES=22
HEAD=dbd95cd
AHEAD=10
GIT_EXIT=0
PS1_SCAN_EXIT=0
PS1_MODE=Check
PS1_SCANNED=514
PS1_NON_ASCII_TOTAL=62
PS1_ASCII_CLEAN=452
PS1_NEW_NON_ASCII=0
PS1_ASCII_FLIPPED=0
PS1_RESOLVED=0
PS1_CHANGED_SAME_FLAG=1
PS1_MISSING_FROM_BASELINE=0
PS1_ASCII_VIOLATIONS=0
PS1_BASELINE_SHA16=5247D49A400CC3F9
RUN_AT=2026-11-25 21:38:49
```

**注**：以上是 **worker 本地自检**读数（`-ExpectDesktopTests 920`，显式给期望数）。
按派工书 §6.2，**最终门禁数字以控制器复跑为准**；控制器复跑后如与上表不同，以控制器为准。

### 6.3 §4.4 契约读数（`apps/desktop` 内 `lib` + `test` 递归 grep）

| 项 | 期望 | 实测 |
|---|---|---|
| `goalsUpstreamAddMenu` 全仓 | 0 | **0** |
| `goalsUpstreamAddHint` | ≥ 4 | **19** |
| `l10n_base_test.dart` 五处计数 | 522 / 522 / 522 / 579 / 579 | **522 / 522 / 522 / 579 / 579** ✓ |

---

## 7. 未决与风险

### 7.1 未决（本棒无权裁，需控制器/用户决）

1. **U3 仍未裁**：月页 / 周页「添加到当前周期」链路本棒**一行未动**（页面仍在用
   `goalDragPayloadFor` 产出 `goal://`，`task72_w2` 仍测它）。今日页既已不消费，
   这条协议成了「只在月/周页成立」的半边契约。
2. **§4.5 与 §5.3 的字面冲突（已发生，请在控制器侧裁决）**：§4.5 要求
   `week-goal-add-hint` / `slot-menu-goals` 在 **`lib` 与 `test` 都 0 命中**，
   但 §5.3 又要求测试里断言这两个键 `findsNothing` —— 断言必须写出键名。
   本棒处置：**`lib/` 内 8 个待消失符号全部 0 命中**；`test/` 内留 4 处**负断言常量/注释**
   （`task72_w3_week_goal_rail_panel_test.dart:36` 与 `task72_w4_week_goal_rail_states_test.dart:39`
   的 `_kHint`；`task72_w3_day_goal_menu_test.dart:38` 的 `_kMenuGoals` 与 `:8` 的注释）。
   若控制器坚持字面 0 命中，可把常量改成派生写法（例如 `'week-goal-' + 'add-hint'`），
   但那只会让断言更难读、守卫强度不增，故本棒选择保留更强断言。
3. **`SlotMenuGoals` 编译期守卫**：类型已删，任何复活企图都会编译失败；已写进测试注释。

### 7.2 风险 / 未验

- **未做真机打包验收**：本棒只跑测试与 analyze，未 `flutter build` / 未截图。
  右栏条目从 `InkWell` 变 `Container` 后**失去 hover 手势光标反馈**，只由测试证明
  「无 `InkWell`」，未做像素级 / 手工点测。
- **`goal://` 外部拖入的视觉表现未验**：`onWillAcceptWithDetails`（`day_grid.dart:343-344`）
  仍是通用判据 `details.data.contains(':')`，故外部 `goal://` 仍会被 `DragTarget` **接住**
  （可能高亮），随后 `_onDrop` 无匹配分支 ⇒ **静默丢弃、零写入、不弹框**。
  这是测试第 3 例刻意证明的行为，但「高亮却落地无反应」的用户观感未做真机确认。
- **未跑活库**：测试全部走内存库，活库零写入。
- **`reports/task51-gate.ps1` 未改**（禁区），门禁判据以脚本现状为准。
- 本棒 `Desktop` 全量一次通过，未出现 flaky 重跑；但 `test_cache\build` 在跑前已
  改名挪走到 `build_stale_20261125213400`（未删），符合 `AGENTS.md` §5 坑（OS Error 183）。

---

## 8. 收工自检清单（派工书 §6.4，逐条打勾）

- [x] `flutter analyze` 逐字 `No issues found!`（`reports/task75-analyze.txt`，EXIT=0）
- [x] 全量测试末行 `+920`（≥ 920）且 `All tests passed!`（`reports/task75-full.txt`，EXIT=0）
- [x] core 三包 204 / 96 / 91 未变（门禁三字段）
- [x] §4.5「必须消失」7 项在 `apps/desktop/lib` 内 grep 命中 **0**
      （`week-goal-add-hint` / `slot-menu-goals` / `SlotMenuGoals` / `addWeekGoalToPlan` /
      `WeekGoalAddOutcome` / `suggestedGoalStartMinute` / `WeekGoalPickDialog`；
      另 `goalsUpstreamAddMenu` 全仓 0）——**test 侧 4 处负断言见 §7.1 第 2 条**
- [x] §4.5「必须存在」键位逐个存活：`week-goal-loading` 3 / `week-goal-error` 3 /
      `week-goal-empty` 5 / `week-goal-${goal.id}` 1 / `slot-menu-manual` 3 /
      `slot-menu-todo-` 4 / `slot-menu-habit-` 4 / `slot-menu-cancel` 3 /
      `day-grid` 107 / `DragTarget<String>` 4 / `onSecondaryTapDown` 2
- [x] 四个测试文件每个 ≥ 3 例（4 / 4 / 4 / 9），无空壳
- [x] `goalsUpstreamAddMenu` 全仓 0 命中；`l10n_base_test.dart` 五处计数 522 / 522 / 522 / 579 / 579
- [x] `goal_upstream_panel.dart` / `providers.dart` / `app.dart` / `goal_store.dart` 一字未改
      （`git diff --stat --` 这四个路径 + `packages` 输出为空）
- [x] 本台账已落盘，`CR=0`
- [x] 没有 `git add` / `git commit` / `git push` / `stash` / `restore`（全程只用 `git show` /
      `git status` / `git rev-parse` / `git diff` 四个只读命令）

---

## 9. 回滚点

- **本棒 commit 之前的 HEAD = `dbd95cd`**（控制器 commit 后回滚应回到此点）。
- 回滚会连带撤销：右栏只读化、菜单去目标组、日格去两消费点、`goalsUpstreamAddMenu` 删键、
  四个测试文件改写。
- 回滚**不影响**月页 / 周页链路与 `goal_upstream_panel.dart`（本棒未动）。

---

## 10. 写集对账（`git status --porcelain -uall`）

本棒改动 11 个已跟踪文件 + 新建 1 个台账：

```
 M apps/desktop/lib/src/l10n/l10n_keys.dart
 M apps/desktop/lib/src/l10n/parts/goals.dart
 M apps/desktop/lib/src/widgets/timeline/day_grid.dart
 M apps/desktop/lib/src/widgets/timeline/slot_context_menu.dart
 M apps/desktop/lib/src/widgets/week_goal_rail_panel.dart
 M apps/desktop/test/l10n_base_test.dart
 M apps/desktop/test/l10n_harness.dart
 M apps/desktop/test/task72_w2_goal_upstream_panel_test.dart
 M apps/desktop/test/task72_w3_day_goal_menu_test.dart
 M apps/desktop/test/task72_w3_week_goal_rail_panel_test.dart
 M apps/desktop/test/task72_w4_week_goal_rail_states_test.dart
?? docs/handoff-ledger-b8-w3.md
```

**盘上另有一批非本棒改动**（本棒开工前即存在，**本棒一字未碰**，在此登记以免误判为越界）：

```
 M AGENTS.md
 M docs/relay.json
 M docs/relay/stage-6-report.md
?? docs/b81-dispatch-w1-retry.md
?? docs/b82-dispatch-w2.md
?? docs/b83-dispatch-w3.md
?? docs/incident-20261125-phantom-rollback.md
?? docs/relay/auto-advance-design.md
?? docs/relay/gate-green-2026-11-25.md
?? docs/relay/relay-lock.ps1
?? docs/relay/start-relay.ps1
```

`reports/**` 未出现在 `git status` 中（`.gitignore:46` 生效），**未 `git add reports/`**。

---

## 11. 本文件自检

- 编码：UTF-8 无 BOM；换行：纯 LF，`CR=0`。
- 所有字节数 / 行数 / 行号 / 测试数 / 门禁字段均为本轮**盘上回读值**
  （`Get-Item`、`Get-FileHash`、`[IO.File]::ReadAllLines`、`Select-String`、
  `git show HEAD:<path>`、`read summary.txt`），未从上下文摘要抄录。
- 门禁数字标注了「worker 本地自检」，控制器复跑值若不同以控制器为准（§6.2 注）。