# Batch 8（B8）设计真源 —— 目标/蓝图内容的编辑权回归对应页面

> 本文件是 B8 的**唯一设计真源**。冲突优先级：用户当轮决定 > 派工书 > 本计划 > handoff > README（AGENTS.md §6）。
> 派工纪律：一切 `apps\**` / `packages\**` 改动经 `worker` 派工，控制器零改产品代码（AGENTS.md §2 R1）。

## 1. 驱动原则（用户 2026-11-25 逐字原话）

> 「蓝图、目标页面的内容，应该在对应页面编辑，而不是在日志页面填入后，回填到这些页面。」

裁决记录（用户问卷选定，逐字见 `docs\b8-scope-decision.md:19-21`）：

| 项 | 内容 |
|---|---|
| B8① | **07 蓝图页 + 目标页补编辑能力**：直接在这些页新建 / 编辑 / 删除目标，成为目标内容的**唯一编辑面** |
| B8② | **今日页（日志侧）撤掉目标写入入口**：只保留展示与「引用/排期」，不再从这里新建或改写目标内容 |
| 范围 | 用户原话同时点名「蓝图**、目标**页面」⇒ 两类页面**都在范围内**（U1 关闭） |

## 2. 本轮取证坐实的现状事实（源码级，全部可复核）

1. `GoalStore` 位置是 **`apps\desktop\lib\src\data\goal_store.dart`**（不在 `packages\`），公开写通道齐备：
   `createGoal:403` / `updateGoal:498` / `deleteGoal:616` / `link:689` / `unlink:757` /
   `rollWeeklyDrafts:989` / `saveWeeklyDrafts:1068`；只读侧 `findGoal:642` / `listGoals:651` /
   `weekView:915` / `monthView:949` / `servedGoals:888`。
   ⇒ **B8 不需要新增 store 方法就能做完整 CRUD**；`updateGoal` 已有测试用过
   （`apps\desktop\test\task65_data_goals_test.dart:74`）。
2. **07 蓝图页不是纯只读**：`apps\desktop\lib\src\pages\goals_blueprint_page.dart` 共 410 行，
   已有写入先例 `_addSplit(GoalRow goal):310` → `store.repos.todo.create:327`（拆 3 条待办并挂 `tracks`），
   带 `_saved:104` 状态与 `ValueKey('goal-blueprint-todo-saved'):296`。
   ⇒ **编辑弹层/写库/成功反馈的工程范式在本页已存在**，B8① 应复用同一范式，不要另造一套。
3. **蓝图页「暂无蓝图目标框架 / 0 条」定性 = 设计口径，不是缺陷**：
   `goals_blueprint_page.dart:149-172` 的矩阵取数条件是
   `goal.domain == domainKey && goal.horizon == horizon`（`near` 额外并入一桶）。
   B7 真机验收的种子目标（`reports\task72_seed_goals.py`）**没写 `domain` / `horizon`** ⇒ 不入格，
   而同期 `goal` 表有 6 行。
   ⇒ 真正的 UX 洞：**页内没有任何地方能设置 `domain` / `horizon`**，所以「在蓝图页建的目标自己看不见」。
   `createGoal` 参数已支持 `domain / horizon / facet`（`:409-411`），`domain` 取值域见
   `:400-402`（`career/wealth/family/learning/social/health`，留空=未分类，列上无 CHECK 约束）。
   ⚠️ 但 `:12` 注明数据源与年页**同一份**，所以改动**不得改变既有格子的归属口径**。
4. 目标页侧现状：月页 `goals_month_page.dart` 有 `_quickAdd:276` 与派生链
   （`GoalDraft:328` / `GoalDraftOrigin:319`，`origin` 默认 `carryOver:341`；
   注释 `:1064-1065` 写明 `serves → GoalDraft.parentId`、`derives → GoalDraft.sourceGoalId`）；
   周页 `goals_week_page.dart` 有 `_quickAdd:141`；二者都用 `goalDraftSaverProvider`
   （`providers.dart:590`）走 `saveWeeklyDrafts`。
   ⚠️ **年页文件不存在**（无 `goals_year_page.dart`），年视图在 `goals_page.dart` 的页签内（`app.dart:171`）。
5. 日志侧写入点（B8② 的候选，**须由 W1 盘点后再裁决删哪些**）：
   今日页右栏 `GoalOnThisDayPanel`（含 `+ 添加` 新建入口，见 `test\task72_w2_no_today_duplicate_add_test.dart`）、
   日计划右键 `SlotMenuGoals`（`widgets\timeline\slot_context_menu.dart:158-164`、
   `day_grid.dart:1173-1196`）、快捷记录卡（`widgets\timeline\task57c_quick_record.dart`）。

## 3. 裁决（D-8-x）

| ID | 裁决 | 依据 |
|---|---|---|
| **D-8-a** | 目标内容的**唯一编辑面** = 07 蓝图页 + 目标页（年/月/周）。日志侧页面不再新建/改写目标本体 | 用户原则逐字 |
| **D-8-b** | 「引用/排期」**保留**在日志侧：把目标排进计划（`plan_item`）、勾选完成、拖拽落位 —— 写的是 `plan_item`，不是 `goal` | 计划项属日志内容，不属于「目标页面内容」；B7 已取证的五条通道里 ④ 两条写的是 `plan_item` |
| **D-8-c** | 撤入口的方式 = **改为跳转**（跳到目标页/蓝图页对应新建面），不做「点了没反应」也不做静默删除；右栏目标卡保留只读展示 | 保留可达性与可发现性，且完全可逆 |
| **D-8-d** | 蓝图页编辑**复用本页既有写库范式**（`store.createGoal/updateGoal/deleteGoal` + 显式成功/失败反馈 + `ValueKey`），不新增 store 方法，不直连 DAO/SQL | `:310-341` 先例；AGENTS §2 分层纪律 |
| **D-8-e** | 新建/编辑表单**必须能设 `domain` 与 `horizon`**，否则新目标在蓝图矩阵里不可见（事实 3 的洞） | 取数条件 `:157-165` |
| **D-8-f** | 不改变蓝图矩阵的归属口径与「与年页同一份数据源」的既有语义 | `:8-12` 文件头说明 |
| **D-8-g** | 派生语义不动：`serves → parentId` / `derives → sourceGoalId`；派生不得改写父目标状态（承 D-72-e） | `:1064-1065` |
| **D-8-h** | B8 分四棒 W1→W4，**一棒一 commit**，禁止合并提交 | 承 B7 节奏与坑 97 |

**仍挂给用户的问题**（不阻塞 W1）：见 §6。

## 4. 棒次划分

| 棒 | 目标 | 主要落点 |
|---|---|---|
| **B8-W1** | 07 蓝图页获得目标编辑能力：格内新建 / 卡片编辑 / 删除（含确认），表单含 `domain`+`horizon`+`facet`，写库全走 `GoalStore` | `pages\goals_blueprint_page.dart`、`l10n\parts\goals.dart`、新测试 |
| **B8-W2** | 目标页（年/月/周）编辑能力对齐：已有 `_quickAdd` 的补「编辑 / 删除」，缺的补齐；与 W1 共用同一个 goal 编辑表单组件 | `pages\goals_month_page.dart`、`pages\goals_week_page.dart`、`pages\goals_page.dart`（年页签）、`widgets\goals\` |
| **B8-W3** | 日志侧撤目标写入入口（D-8-a/b/c）：先出**盘点清单**（file:line），再逐个改为跳转或移除；同步修被撤入口牵连的测试与 `KeyBar` 提示 | 今日页右栏、`widgets\timeline\slot_context_menu.dart`、`day_grid.dart`、`task57c_quick_record.dart` |
| **B8-W4** | 真机验收 + 台账 + 安装包：先跑既有门禁与真机链，再出 `release\` 包 | `reports\`、`release\`、`docs\` |

**执行顺序不可乱**：W3 依赖 W1/W2 提供替代编辑面 —— 先撤入口后补能力会让产品出现「哪都建不了目标」的空窗。

**B8-W1 写集授权（控制器裁决 2026-11-25，依 R1「必须改而计划表没写的文件，先由控制器显式追加一行并留档」）**：W1 复核坐实「格内 + 新建目标」与「卡片编辑 / 删除」在只改上表 B8-W1 那一行的前提下**物理上不可实现** —— 格子与卡片 100% 由 `widgets\goal_blueprint_matrix.dart` 渲染（`_cell:165-220` 是唯一渲染入口），而 `GoalBlueprintMatrix` 的构造入参只有 `t / rows / serves / tracksCount / onSplitTodos`（`:43-50`），页面侧无任何注入点。现追加 4 个文件进 B8-W1 写集：`apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart`、`apps\desktop\lib\src\l10n\l10n_keys.dart`、`apps\desktop\test\l10n_base_test.dart`、`apps\desktop\test\l10n_harness.dart`（每条新词条必须联动这三者，`l10n_base_test.dart:27-29` 硬断 `L10nKeys.byGetter.length == 511` 且要求访问器表与键表集合全等）。旁证：门禁 `reports\task51-gate.ps1` 的白名单已含 `apps/desktop/lib/src/widgets/goal*`、`l10n_keys.dart`、`l10n_base_test.dart`、`l10n_harness.dart` ⇒ 不会报 `OUT_OF_SET`，缺的只是本表这一行；`task73_*` 测试 pattern 已由控制器追加。`GoalBlueprintMatrix` 全仓唯一构造点 = `pages\goals_blueprint_page.dart:247`（`:152` 只用静态 `horizons`）⇒ 给它加可选回调零外溢，不触碰 W2/W3 写集。

**共享 goal 编辑表单落点（控制器裁决）**：W1 **私有**实现在 `pages\goals_blueprint_page.dart` 内，**不**新建 `widgets\goals\`；W2 抽取为共享组件时再建该目录（W2 写集已含 `widgets\goals\`）。理由：W1 建目录会与 W2 写集重叠、制造并发写冲突；D-8-e「由所在格子预填 `domain`+`horizon`」口径不变。

**W1 台账订正的三处事实（以盘上源码为准，派工书原文作废）**：① 卡片 key 实为 `goal-blueprint-cell-${goal.id}`（`goal_blueprint_matrix.dart:184`），不是 `goal-blueprint-cell-<domain>-<horizon>`；② 空态 key 实为 `goal-blueprint-empty-cell`（`:172-176`），且空格子只渲染一个 `Text`、无按钮位；③ `createGoal` 返回 `Future<String>`（新 id）而非 `Future<Goal>`，`updateGoal` 是位置参数 `goalId` + `Set<GoalField> clear`（`goal_store.dart:403 / :498 / :616`）。

**门禁期望测试数**：`-ExpectDesktopTests` 以 907 + W1 实增用例数为准（W1 交付时报告实数；台账里出现的 911 未经实测，不得直接采信）。

## 5. 验收判据（每棒通用）

1. 逐包 `analyze` 逐字 `No issues found!`；desktop 测试数**精确等值**当前基线 + 本棒新增数（跑 `reports\task51-gate.ps1` 必须显式 `-ExpectDesktopTests`，§5 坑 86）。
2. 每条需求至少一个**判别性测试**（红→绿，红灯原文进台账）。
3. 蓝图页 / 目标页写库后**回读 SQLite** 才算成立；「点了没报错」不算证据。
4. 列名以 `PRAGMA table_info` 为准（R5）。⚠️ `goal` 表**无 `origin` 无 `source_goal_id`**；
   `goal_link` **无 `link_type` 也无 `link_kind`** —— 两个写法都已被实测证伪，新 SQL 前必须先 `PRAGMA`。
5. 台账数字必须盘上回读；只写形态不写值（R5）。
6. W3 的判据额外要求：撤入口后，**原入口的测试要么删除要么改为断言跳转**，禁止留「测试还绿但产品入口已消失」的假绿。

## 6. 留给用户裁决（不阻塞 W1）

- **U-8-x**：今日页右栏「目标/项目」卡是**保留只读展示**（D-8-c 默认）还是**整卡移除**？
- **U-8-y**：B7 遗留 MINOR-2（窄屏 `KeyBar` 缺 `Ctrl+7` 文字提示，`widgets\key_bar.dart:87`）
  是否并入 W3 顺手修（它牵连的正是 W3 要改的快捷键提示区）。
