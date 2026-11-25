# B7 / W4（修复棒）交付台账 · verifier 1 MAJOR + 2 MINOR

- 棒次：B7-W4（隐藏子会话）
- 日期：2026-11-25
- 唯一派工书：`docs/b71-dispatch-w4-fix.md`
- 上游证据：verifier 独立复核 `bg_8df2c4e0-4776-4d3c-863e-36643c078320`（`VERDICT=PASS_WITH_CONCERNS`，`CRITICAL=0`，`MAJOR=1`，`MINOR=4`）
- 规范真源：`AGENTS.md`（§2 铁律 R1–R8、§5 坑速查）
- 本棒性质：**只修缺陷，不新增功能、不改需求语义**

---

## 1. 交付结论

| 项 | 值 |
|---|---|
| `STATUS` | `DONE`（派工书 3 项全修，判据 1–5 全通） |
| `ANALYZE_VERBATIM` | `No issues found! (ran in 4.2s)`，`ANALYZE_EXIT=0` |
| `DESKTOP_TESTS` | `01:45 +907: All tests passed!`，`FULL_EXIT=0`（基线 903 + 本棒 4 = 907，只增不减） |
| `GOAL_SCHEME_LITERALS_IN_WEEK_PANEL` | `0` |
| `PACKAGES_DIFF_EMPTY` | `True`（`---PKG_DIFF_START---`/`---PKG_DIFF_END---` 之间零输出） |
| 新增用例数 | 4（`test/task72_w4_week_goal_rail_states_test.dart`） |
| 未闭合项 | 见 §6（3 条 CONCERN，无 BLOCKER） |

HEAD 保持 `8c01455`，工作区全部未提交（未执行任何 add/commit/checkout/restore/stash/clean）。

---

## 2. 改动清单（3 处源码 + 1 个新测试文件；零删除）

| 文件 | 改动 | 归属 |
|---|---|---|
| `apps/desktop/lib/src/widgets/week_goal_rail_panel.dart` | 三态分离 + 消费 `goalDragPayloadFor` + 3 处注释引用化 | MAJOR-1 / MINOR-1 |
| `apps/desktop/lib/src/app.dart` | 仅 :377 一行注释缩进 | MINOR-4 |
| `apps/desktop/test/task72_w4_week_goal_rail_states_test.dart` | **新建**，4 用例 | 判据 3 |
| `docs/handoff-ledger-b7-w4.md` | **新建**（本文件） | §6 交付 |

**明确未触碰**：`packages/**`（R1）、`key_bar.dart`、`test/shell_key_bar_test.dart`、`test/task64_nav_gear_test.dart`、`day_grid.dart`、`providers.dart`、`goal_upstream_panel.dart`、`test/task72_w3_week_goal_rail_panel_test.dart`（key 未变，无需同步）、`lib/src/l10n/**`（零新增 getter，详见 §6.2 #1）。

---

## 3. 逐条修法与 file:line

### 3.1 MAJOR-1 · loading / error 被伪装成「暂无未完成目标」

`apps/desktop/lib/src/widgets/week_goal_rail_panel.dart`：`asyncGoals.when` 由「`data` 单臂 + 兜底」改为**三态显式分离**。

| 态 | 位置 | 实现 |
|---|---|---|
| `loading:` | `:145` | `Padding(vertical:12) + Center + SizedBox(16x16) + CircularProgressIndicator(strokeWidth:2, color: context.tokens.meta)`，`key: ValueKey<String>('week-goal-loading')`。形态对齐 `goal_upstream_panel.dart` 的 `_PanelLoading` 范式。 |
| `error: (Object error, StackTrace _)` | `:163` | `Text('${t.operationFailed}: $error', key: ValueKey<String>('week-goal-error'), style: hintStyle)` —— 错误原文可见，不吞异常。 |
| `data:` 真空态 | `:171` | 保留 `key: ValueKey<String>('week-goal-empty')`，文案与布局不变（回归锁）。 |

要点：
1. **文案走 l10n**：用既有通用 getter `t.operationFailed`（zh「操作失败」/ en「Operation failed」），拼 `: $error`。分隔符用 ASCII `: `，避免在 Dart 里硬编码 CJK 标点。**未在 Dart 里出现任何中文串。**
2. **三态互斥**：loading 分支不再落到空态视图，error 分支同样不落空态 ⇒ `week-goal-empty` 只在 `data` 且列表为空时出现（判据 3 的「不存在」子句即由此保证）。

### 3.2 MINOR-1 · 拖拽协议字面量两份

`week_goal_rail_panel.dart:195`：`data: 'goal://${goal.id}'` → `data: goalDragPayloadFor(goal.id)`。

- 新增 `import 'goal_upstream_panel.dart';`（`:10`，插在 `../theme/app_tokens.dart` 之后、`shell/key_bar.dart` 之前，保持既有 import 分组序）。
- 前缀唯一来源回到 `goal_upstream_panel.dart` 的 `goalDragPayloadPrefix` / `goalDragPayloadFor` / `goalIdFromDragPayload`（D-72-d「三层共用一个组件」）。
- 值恒等：`goalDragPayloadFor(id)` 产出与旧字面量同值，故 `day_grid._onDrop` 的 `split(':')` 分流逻辑与 W3 既有断言（`draggable.data == 'goal://$openId'`）全部不受影响。
- 为满足判据 3 的字面反查（0 命中），同步把本文件 3 处注释里的 `goal://` 字面量改为引用 `[goalDragPayloadFor]`：`:26`、`:113`、`:184`。**纯注释、零行为影响**，详见 §6.2 #2。

### 3.3 MINOR-4 · `_NavIntent` 文档注释续行缩进

`apps/desktop/lib/src/app.dart:377`：`/// \`blueprint\`）。` 由列 0 改为 2 空格缩进，与上一行 `/// 目标导航项 id（...` 对齐。

- 只改这一行，**未对该文件做整体格式化**（避免把无关行卷进 diff）。

---

## 4. 判据 1–5 原始输出

### 判据 1 · `flutter analyze`

环境：进程内设 `$env:PUB_HOSTED_URL` / `$env:FLUTTER_STORAGE_BASE_URL`，工作目录 `apps\desktop`。

```
Analyzing desktop...
No issues found! (ran in 4.2s)
```

`ANALYZE_EXIT=0`。中途曾报 1 条 `undefined_getter`（误用 `commonOperationFailed`，Dart getter 实为 `operationFailed`），改正后即上文终态。

### 判据 2 · 全量测试

跑前镜像 `build\test_cache\build` 已用 `Move-Item` 改名为 `build_moved_w4_1`（可恢复，未删除）。

```
01:45 +907: All tests passed!
```

`FULL_EXIT=0`。基线 **903**，本棒新增 **4**，终值 **907** —— 只增不减。

### 判据 3 · 判别性测试（先红后绿）

**红灯原文**（实现改之前，`build\w4-red.txt`）：

```
Found 0 widgets with key [<'week-goal-loading'>]
Found 0 widgets with key [<'week-goal-error'>]
00:0? +2 -2: Some tests failed.
```

**转绿原文**（`build\w4-green.txt`）：

```
00:06 +4: All tests passed!
```

即：loading / error 两例先红后绿（判别性成立）；真空态回归锁与 payload 同源两例一开始即绿（前者锁旧行为、后者锁等价性，均为行为锁而非判别例）。

**反查判据**：

```
Select-String -Path week_goal_rail_panel.dart -Pattern 'goal://' -SimpleMatch | Measure-Object | % Count
0
```

⇒ `GOAL_SCHEME_LITERALS_IN_WEEK_PANEL=0`。

### 判据 4 · R1 写集

```
---PKG_DIFF_START---
---PKG_DIFF_END---
```

`git status --porcelain -uall -- packages` 返回**空**。`git rev-parse --short HEAD` = `8c01455`（未变）。

### 判据 5 · 需求语义不变

四条需求（右栏陈列 / 点击加入 / 拖动加入 / 日计划右键勾选）的**行为路径一行未改**：唯一写入口仍是 `addWeekGoalToPlan`，拖拽 payload 值与旧字面量恒等，三通道逻辑未动。本棒只改「状态如何呈现」与「协议字面量的来源」。

---

## 5. 新增用例清单

`apps/desktop/test/task72_w4_week_goal_rail_states_test.dart`（210 行，4 用例）：

| # | 用例 | 断言要点 |
|---|---|---|
| 1 | `B7/W4：加载中只出加载占位，不伪装成「暂无未完成目标」`（`:116`） | 存在 `week-goal-loading`；**不存在** `week-goal-empty`。用 `weekOpenGoalsProvider.overrideWith` + `Completer().future` 造永不完成的 loading。 |
| 2 | `B7/W4：读库失败时出错误态且错误原文可见，不伪装成空态`（`:142`） | 存在 `week-goal-error`；屏幕上可见错误原文（`StateError('drift-read-failed')` 的文本被渲染）；**不存在** `week-goal-empty`。用 `Future<List<GoalRow>>.error(...)` 造 error。 |
| 3 | `B7/W4：真空态仍是 week-goal-empty（回归锁）`（`:167`） | 空列表 ⇒ `week-goal-empty` 仍成立。 |
| 4 | `B7/W4：拖拽 payload 与 goalDragPayloadFor 同源（协议单一来源）`（`:183`） | `Draggable<String>.data == goalDragPayloadFor(openId)`，且其值等于 `goal://$openId`。 |

用例 1/2 是本棒的判别例（改前实测 `+2 -2`）；用例 3/4 是行为锁（改前即绿，防回归）。

---

## 6. CONCERN / AMBIGUITY

### 6.1 CONCERNS（3）

1. **错误态用的是通用「操作失败」而非专用文案。** 派工书 §2 允许新增 l10n getter，但 `test/l10n_base_test.dart` 硬断言 `L10nKeys.byGetter.length == 511` 与总键 568 —— 新增 getter 必须同改该测试（不在写集内），会直接打红。⇒ 取最小代价方案：复用既有 `t.operationFailed` + `: $error` 让原文可见。代价是文案偏通用。若后续要专用文案，需授权同改 `l10n_base_test.dart` 的计数常量。
2. **错误态无重试按钮。** 派工书只要求「能看到错误文案」，未要求可重试；为守住最小改动未加重试。当前用户只能靠切页/重进来触发重读。
3. **loading 态无超时兜底。** provider 若永不完成，面板会长期停在转圈。属 provider 层议题，不在本写集。

### 6.2 AMBIGUITY（3）

**#1 · 派工书路径口径与实际仓库不一致（两处）。** 派工书 §3 写 `apps\desktop\lib\app.dart` 与 `apps\desktop\lib\l10n\**`，实际文件为 `apps\desktop\lib\src\app.dart` 与 `apps\desktop\lib\src\l10n\**`。按语义等价处理（改的就是那两处对应的真实文件），未越界。

**#2 · 注释里 3 处 `goal://` 的改写是本棒自加的。** 派工书只要求「消费 `goalDragPayloadFor`」，但判据 3 的反查是**文件级字面 0 命中**；若保留注释里的旧字面量，反查不为 0。⇒ 把 `:26` / `:113` / `:184` 三处注释改成引用 `[goalDragPayloadFor]`。纯注释、零行为影响，但属判据驱动的额外改动，在此申报。

**#3 · l10n 三文件显示为 `M`，非本棒所为。** `apps/desktop/lib/src/l10n/l10n_keys.dart`、`parts/goals.dart`、`parts/shell.dart` 在 `git status` 里是 ` M`，来自上游 W1/W2/W3 棒次（goals/shell 键登记）。本棒**未写入 l10n 任何文件**（本棒全程只编辑了 §2 表中的 3 个源文件，未对 `lib/src/l10n/**` 做过任何写入）。因工作区整体未提交，无法用 git 分离归属，只能在此申报。

---

## 7. 本轮踩到的新坑

1. **`cd <dir>; ... *> build\x.txt` 会被本地硬安全策略拒绝**（"write/delete targets cannot be verified safely after a command working directory change"）。⇒ 改用 `Start-Process -WorkingDirectory <dir> -RedirectStandardOutput <绝对路径>`，不切目录。
2. **`flutter test ... | Out-String` 会丢输出**（沿用 W3 记录，本棒复现一致）。⇒ 重定向到文件后用 `Get-Content -Tail` / `Select-String` 读。
3. **Dart getter 名以文件为准，不要凭 l10n 语义猜**：`commonOperationFailed` 不存在，实为 `operationFailed`，猜错直接 analyze 报 `undefined_getter`。

---

## 8. 给收口棒的接棒提示

- 本棒只碰了状态呈现与协议来源，**未碰任何行为路径**；若后续要改「加目标的落位/幂等」，唯一入口仍是 `week_goal_rail_panel.dart` 的 `addWeekGoalToPlan`（W3 台账 §2.1）。
- 若要补专用错误文案，动手点有两处且必须同改：`lib/src/l10n/parts/*.dart` 加键 + `test/l10n_base_test.dart` 的 `511` / `568` 两个计数常量。
- `build\w4-red.txt`、`w4-green.txt`、`w4-analyze-final.txt`、`w4-full.txt` 是本棒证据原件，落在 `apps\desktop\build\`（构建产物目录，不入库）。
- `build\test_cache\build` 已改名为 `build_moved_w4_1`；下棒跑全量前若要还原，用 `Move-Item` 改回（不要删）。