# B9 计划书 · 蓝图页「个人品牌管理」模块 + 人生蓝图矩阵四标签页与四级拆分链路

- 版本：**v1**（2026-11-25 控制器落盘）
- 仓库根：`F:\soft\00selfmade\practilog`（**一切产出落仓库内**，一律绝对路径 + `git -C <repo>`）
- 上游 HEAD：`c11e17d`（B8 W1–W4 全入库；ahead 12 / behind 0；**未 push**）
- 上游真源链：`AGENTS.md`（R1–R8）→ `docs/plan-goals-ui-batch8.md` → `docs/b8-scope-decision.md` → `docs/handoff-ledger-b8-w4.md`
- 本批代号：**B9**（与已收口的 B8 分离）。节奏沿用 B8：**一棒一 commit、只 commit 不 push、控制器零改 `apps/**` 与 `packages/**`**
- 接力链并发状态：`docs/relay.json` = `status: "done"` / `current_stage: 6` / `max_stages: 6` / `next_session_id: null` ⇒ **无并发 relay 链在跑**，可安全开工

---

## 0. 用户当轮指令（逐字，语义不得改写）

> 1. 蓝图页面，在人生蓝图矩阵上面添加一个「个人品牌管理」模块，内容参考文章 `https://www.doubao.com/thread/xlTAj7kOKM5w7yyQ1` 进行规划；
> 2. 人生蓝图矩阵，去除标题「人生蓝图矩阵」，把下面的内容区分为 4 个标签页，分别显示 终极、远期、中期、短期，内容保持和当前一致。在没有填入内容时，不要显示「(空)」，在单元格右下角显示「+」按钮，可以添加单元格内新的内容。已经添加的内容，在右侧显示小铅笔按钮，点击可以对目标进行编辑；显示一个代表拆分的按钮。终极目标，可以拆分为多个 远期目标，远期目标可以拆分为多个中期目标，中期目标又可以拆分为多个短期目标。拆分后，可以自动填入对应的表中。短期目标，则可以拆分为多个年目标或待办任务。确认拆分后，也直接填入对应表格。

---

## 1. 范围裁决（D-9-a ~ D-9-i，控制器已拍板，worker 不得再裁）

> 权威优先级：**用户当轮决定 > 派工书 > 计划正文 > handoff/progress > README**。

| 编号 | 议题 | 裁决 | 理由 |
|---|---|---|---|
| **D-9-a** | 本批与 B8 的关系 | **独立 B9 批次**，四棒：W1 品牌模块 / W2 矩阵四标签页 + 空态「+」+ 铅笔 / W3 四级拆分链路 / W4 真机 + 门禁 + 出包 + 台账 | B8 已全棒收口并入库；B9 改动面更大（新增模块 + 结构性改造 + 新对话框） |
| **D-9-b** | 原第 5 列「近期（1 年）」归属 | **4 标签页 = 终极 / 远期 / 中期 / 短期**；**短期标签页 = 原「短期」列 + 原「近期」列合并**（近期列 = `horizon=near` 的蓝图目标 + 本年度 `kind=yearly` 年目标）⇒ **内容零丢失**，「内容保持和当前一致」字面满足 | 用户只点名 4 档；1 年 ⊂ 3 年属短周期；丢弃任何一类内容都违反「内容保持一致」 |
| **D-9-c** | 近期列里的**年目标**（`kind=yearly`） | 保留渲染（标题 + 做法条数 + 展开），**不给铅笔 / 拆分**（它们是年页内容的镜像，与年页**同一份数据源**；改档位会把 `horizon` 写坏）；**所有蓝图目标（任何档位，含 `near`）都有铅笔 + 拆分** | 与既有代码注释同口径（`goal_blueprint_matrix.dart:273-274`）；年页已有行级编辑/删除（B8-W2 已坐实） |
| **D-9-d** | 铅笔按钮实现 | `IconButton(icon: Icon(Icons.edit_outlined), iconSize: 16)`，点击区 28×28（`MaterialTapTargetSize.shrinkWrap`），**与 `widgets/goals/goal_form_dialog.dart` 的 `GoalRowActions` 逐字同口径** | 仓库已有**铅笔先例**（`goal_form_dialog.dart:373-381`）；AGENTS §5 坑 51 明示「时钟类必须走 Material Icon」，Unicode 字形在随包字体里覆盖不可靠 ⇒ 禁用 `✎` 之类文本字形；测试**只断言 ValueKey / `find.byIcon`，禁字形级断言** |
| **D-9-d'** | 拆分按钮图标 | `Icons.call_split`（Material Icons 里确有「分叉」字形）；tooltip 走 l10n | 与铅笔同一条 28×28 紧凑口径 |
| **D-9-e** | 拆分按钮与既有「拆成 3 条待办」的关系 | **新拆分入口接管旧 key `goal-blueprint-split-<id>`**（由文字按钮变右侧图标按钮）；**旧「待确认待办」区块与 `_pending` 队列整体撤除** | 用户明文「**确认拆分后，也直接填入对应表格**」⇒ 两段式「先进队列再确认」与新口径冲突；新对话框一次确认即落库 |
| **D-9-f** | 个人品牌模块的数据模型 | **零 schema 变更**：复用域层既有 `GoalKind.brand` + `GoalFacet`（10 切面）+ `goal.facet` 自由 TEXT 列（`core_db/lib/src/tables.dart:1253-1272` **无 facet CHECK**）⇒ **`packages/**` 零改动** | Task 62 §5.5 既有设计（`docs/task62/模块规划.md:371-394`）已冻结 10 切面；`packages/**` 在 R1 下属禁区 |
| **D-9-g** | 品牌模块形态 | 域层既有 **10 切面**（不新增枚举）+ 每切面 **要点 / 范例 / 反例**（Task 62 §5.5 明文要求「每个切面给填写范例与反例」）+ 模块级指引（定位公式 / 三层结构 / 三步方法论 / PBE 三维）；**默认落在 `audience`**（他人视角优先） | 零 schema 变更；文章三层结构（内在内核 / 能力价值 / 外在感知）作为**模块级指引**而非新枚举 |
| **D-9-h** | 「去除标题『人生蓝图矩阵』」的实现 | 矩阵卡片**不再渲染段头**；l10n 键 `goalBlueprintMatrixSection` **一并删除**（不留死键）；矩阵卡片改为「无标题壳」 | 用户明文「去除标题」；死键会被 l10n 底座判为不一致风险 |
| **D-9-i** | 出包口径 | 沿用 B8：**只出包、不装机**（覆盖安装会污染用户活库证据且不可逆） | B8 已定；装机态复验留待用户决定 |

---

## 2. 盘上事实基线（2026-11-25 回读，非摘要抄录）

| 项 | 实测 | 落点 |
|---|---|---|
| 蓝图页 | 575 行；三块 = 矩阵块（`_block(t, t.goalBlueprintMatrixSection, …)`）+ 待确认待办区 + 平衡轮 | `apps/desktop/lib/src/pages/goals_blueprint_page.dart` |
| 矩阵组件 | 308 行；`GoalBlueprintMatrix.horizons` = 5 档排序；`_cell` 空态渲染 `Text(t.goalBlueprintEmptyCell, key 'goal-blueprint-empty-cell')` + 可选「+ 新建目标」TextButton | `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` |
| 矩阵取数 | 6 领域 × 5 档；`horizon == near` 时**额外并入** `view.yearlyGoals`（`goal.domain == domainKey`） | `goals_blueprint_page.dart:175-180` |
| `serves` 方向 | `GoalServesIndex.parentsOfGoal` = 目标 → 它服务的上层；`childrenByParent` = 上层 → 服务它的下级 ⇒ **`childrenOf(parent)` = 下级**；`GoalRelation.serves` 语义 =「本目标服务于上层目标」 | `apps/desktop/lib/src/widgets/goal_year_matrix.dart:27-51` |
| `createGoal` | 签名含 `kind / title / note / keywords / parentId / domain / horizon / facet / periodStart=0 / periodEnd / dueDate / …`；`parent_id` 落库 | `apps/desktop/lib/src/data/goal_store.dart:403-490` |
| `updateGoal` | 传 null = 不动；清空须进 `clear: {GoalField.x}`；`facet` 参与合并 | `goal_store.dart:498-616` |
| 年目标落库 | `_goalsInPeriod` 判据 = **`period_start` 精确等于该周期起点** ⇒ 年目标须传 `GoalPeriod.year(y).startMillis / .endMillis` | `goal_store.dart:1131-1144` |
| 域层切面 | `GoalFacet` 10 值：statement / word / audience / promise / cost / evidence / contrast / strength / errc / identity；`GoalKind.brand` 已存在 | `packages/core_domain/lib/src/goal.dart:26-71, 150-200` |
| DB 约束 | `goal` 表 CHECK：`goal_kind_check`（含 `'brand'`）/ status / horizon(1..5) / … **无 `goal_facet_check`** ⇒ facet 自由 TEXT | `packages/core_db/lib/src/tables.dart:1253-1272` |
| 铅笔先例 | `GoalRowActions` 已用 `IconButton(icon: Icon(Icons.edit_outlined), iconSize: 16)` + 28×28 shrinkWrap | `apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart:373-394` |
| l10n 基线 | **`L10nKeys.byGetter.length == 522` / `l10nAccessors.length == 522` / 总数 `522 + 4 + 53 = 579`** | `apps/desktop/test/l10n_base_test.dart:27-45` |
| 门禁基线 | desktop **920**；core_data 204 / core_db 96 / core_domain 91；`-ExpectDesktopTests` 传什么就精确比什么 | `reports/task51-gate.ps1:401-406` |
| 门禁白名单 | 已含 `pages/goal*` / `data/goal*` / `l10n/parts/goal*` / `widgets/goal*` / `l10n_keys.dart` / `l10n_harness.dart` / `l10n_base_test.dart` / `task66_*` / `task73_*` / `task74_*` | `reports/task51-gate.ps1:252, 276-277, 318-322, 349` |
| 参考文章 | 已抓取全文（标题「个人品牌建设全解」）：三层结构 + PBE 三维 + 五原型 + 四大价值 + 三步方法论 + 定位公式 | 见 §附录 |

---

## 3. 写集纪律（R1）

- **控制器**只写台账与文档：`docs/**`、`progress.md`、`handoff.md`、`reports/taskN-*`、**以及本批白名单追加（`reports/task51-gate.ps1`）**。
- **控制器不得改** `apps/**` 与 `packages/**` 任何文件；一切实现经 **worker 子会话派工**。
- 越界判据：`VIOLATIONS=0` / `OUT_OF_SET=0` / `PACKAGES_TOUCHED=0`。
- `packages/**` 本批**零改动**（D-9-f）。

### 3.1 门禁白名单追加（控制器动作，已在本批授权范围内）

`reports/task51-gate.ps1` 的 `$patterns` 追加下列行（B9 专属；**由控制器改，worker 不得改**）：

```
# ---- Batch B9 (2026-11-25): blueprint page gets a personal-brand panel; the life
#      blueprint matrix becomes 4 tabs with in-cell add/edit/split affordances. ----
  'docs/plan-goals-ui-batch9.md',
  'docs/b91-dispatch-*',
  'docs/b92-dispatch-*',
  'docs/b93-dispatch-*',
  'docs/handoff-ledger-b9*',
  'apps/desktop/test/task78_*',
  'apps/desktop/test/task79_*',
  'reports/task78-*',
  'reports/task79-*',
  'reports/task80-*'
```

`apps/desktop/lib/src/widgets/goal*` 已覆盖 `goal_brand_panel.dart` 与 `widgets/goals/goal_split_dialog.dart`（`-like` 的 `*` 跨目录分隔符）；`pages/goal*` 覆盖蓝图页；`l10n/parts/goal*` 覆盖 `parts/goals.dart`。

---

## 4. 四棒划分与写集表

> **串行**：四棒写集**互相重叠**（蓝图页 + l10n 四件套），按 R8「写集不重叠才并行」⇒ **必须串行**，禁止并行派工。

### W1 · 个人品牌管理模块（蓝图页矩阵**上方**）

**写集**（worker 独占）：

| 文件 | 动作 |
|---|---|
| `apps/desktop/lib/src/widgets/goal_brand_panel.dart` | **新增** |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 改：在矩阵块**上方**插入品牌面板（只加不动既有三块） |
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 改：**+54 键**（见 §5.1） |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 改：+54 常量 + 54 条 `byGetter` 映射 |
| `apps/desktop/test/l10n_harness.dart` | 改：+54 访问器登记 |
| `apps/desktop/test/l10n_base_test.dart` | 改：**5 处计数 522→576 / 579→633** |
| `apps/desktop/test/task78_b9_brand_panel_test.dart` | **新增**（≥ 6 例） |

**禁改**：`goal_blueprint_matrix.dart`、`packages/**`、`goal_store.dart`、`providers.dart`、`app.dart`。

**实现要点**：

1. 面板自取数据（`ConsumerStatefulWidget` + 自己的 future），**不改蓝图页 `_load()`**；页面只负责插入一个块。
2. 取数：`store.listGoals(kind: GoalKind.brand)` ⇒ 按 `facet` 分桶（**切面 = 一行**，域层口径）。
3. 落库：
   - 该切面已有行 ⇒ `store.updateGoal(id, title: …, note: …)`（`facet` 不动 ⇒ 不进 `clear`）。
   - 该切面无行 ⇒ `store.createGoal(kind: GoalKind.brand, facet: F, title: …, note: …)`。
   - **空内容不写行**（不建空行）。
4. 默认切面 `audience`；左侧 10 切面导航；右侧 = 切面标题 + 要点 + 范例 + 反例 + 标题输入框 + 补充说明输入框 + 保存按钮 + 已保存/失败反馈。
5. 界面结构：一屏一卡，左侧切面导航、右侧编辑区、底部可折叠指引块（定位公式 / 三层结构 / 三步方法论 / PBE 三维）。
6. **零 `Icons.`**（本模块无 Material 图标；指引块用纯文本 + 折叠用 `TextButton`）。
7. 切面导航、输入框、保存按钮的 ValueKey：`goal-brand-facet-<facetCode>` / `goal-brand-title-<facetCode>` / `goal-brand-note-<facetCode>` / `goal-brand-save-<facetCode>`；反馈 `goal-brand-saved` / `goal-brand-error`；面板根 `goal-brand-panel`。

**判据**：

- `flutter analyze` 逐字 `No issues found!`；
- 本棒测试新增例数 **N1**（≥ 6），全量总数 = **920 + N1**；
- l10n 底座五处计数自洽：`byGetter = accessors = 576`、`总数 = 576 + 4 + 53 = 633`；
- 品牌行落库证据：`kind='brand'`、`facet='audience'`、改后 `rev` 递增、`deleted_at` 为空；
- **不改**蓝图页既有三块的任何 ValueKey。

---

### W2 · 矩阵四标签页 + 去标题 + 空态「+」+ 右侧铅笔/拆分

**写集**（worker 独占）：

| 文件 | 动作 |
|---|---|
| `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 改：标签页、空态、右侧按钮 |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 改：矩阵块去段头 |
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 改：**+3 −4**（见 §5.2） |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` / `apps/desktop/test/l10n_harness.dart` / `apps/desktop/test/l10n_base_test.dart` | 改：随键数同步（五处计数 576→**575** / 633→**632**） |
| `apps/desktop/test/task66_goals_blueprint_page_test.dart` | 改：标签页 / 空态 / 铅笔 / 拆分断言 |
| `apps/desktop/test/task73_b8_w1_blueprint_edit_test.dart` | 改：**先切标签页再断言**（见 §6 契约变更表） |

**禁改**：`packages/**`、`goal_store.dart`、`providers.dart`、`goal_brand_panel.dart`、`widgets/goals/goal_split_dialog.dart`。

**实现要点**：

1. **标签页**：4 个，顺序 = 终极 / 远期 / 中期 / 短期（`GoalHorizon.ultimate / long / mid / short`），默认选中**终极**。
   - 标签按钮 key：`goal-blueprint-tab-<horizonKey>`（`horizonKey` 沿用现有 `_horizonKey`：ultimate / long / mid / short）；文案复用既有 `goalBlueprintHorizonUltimate / Long / Mid / Short`。
   - **只渲染选中档位**的那张表（6 行 × [领域 | 单元格]）；行标签 key `goal-blueprint-row-<domain>` 逐字保留。
2. **短期标签页内容 = 短期列 + 近期列**（D-9-b）：`horizon == short` 的蓝图目标 **+** `horizon == near` 的蓝图目标 **+** 本年度 `kind=yearly` 年目标（近期的年目标沿用现状渲染，**无铅笔/无拆分**，D-9-c）。
3. **去标题**（D-9-h）：矩阵卡片**不渲染**「人生蓝图矩阵」段头；`goalBlueprintMatrixSection` 键删除。
4. **空单元格**：**不再渲染**「（空）」文本（`goalBlueprintEmptyCell` 键删除，`goal-blueprint-empty-cell` key 随之消失）；改为单元格**右下角**一个 28×28 的「+」按钮（key 沿用 `goal-blueprint-add-<domain>-<horizonKey>`），点击 = 新建该格目标（预填 domain + horizon，行为沿用 B8-W1）。
5. **已添加内容右侧按钮**：铅笔 `goal-blueprint-edit-<id>` + 拆分 `goal-blueprint-split-<id>`（**沿用既有 key**，由文字按钮升级为右侧紧凑图标按钮）；删除入口 `goal-blueprint-delete-<id>` **保留**（既有契约，仍走二次确认）。
   - **拆分按钮在本棒仍调用既有 `onSplitTodos` 回调**（行为不空转）；W3 才换成新对话框。
6. 铅笔/拆分**只对 `kind == blueprint` 的卡片出现**（D-9-c）。
7. 单元格右下的「+」与右侧图标按钮同一 28×28 紧凑口径；**断言只走 ValueKey / `find.byIcon`，禁字形级断言**（AGENTS §5 坑 51）。

**判据**：

- analyze 逐字 `No issues found!`；本棒新增例数 **N2**（≥ 8），全量 = 920 + N1 + N2；
- l10n 五处计数自洽：`byGetter = accessors = 575`、`总数 = 575 + 4 + 53 = 632`；
- **强断言（改写后要更强，不得改弱）**：
  - 「（空）」文案与 `goal-blueprint-empty-cell` 在 `apps/desktop/lib` 内 **0 命中**；
  - 4 个标签按钮存在且**切换后只渲染对应档位**（终极档的目标在切到「远期」后 `findsNothing`）；
  - 空格子**只有**右下角「+」按钮，无「（空）」文本；
  - 卡片右侧同时存在铅笔键与拆分键；
  - `goal-blueprint-matrix-section` 段头文本 `findsNothing`。

---

### W3 · 四级拆分链路（终极 → 远期 → 中期 → 短期 → 年目标/待办）

**写集**（worker 独占）：

| 文件 | 动作 |
|---|---|
| `apps/desktop/lib/src/widgets/goals/goal_split_dialog.dart` | **新增** |
| `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 改：拆分按钮改走新回调 |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 改：接线 + 落库；**移除旧「待确认待办」区块与 `_pending` 队列** |
| `apps/desktop/lib/src/l10n/parts/goals.dart` 等四件套 | 改：**+12 −2**（见 §5.3） |
| `apps/desktop/test/task79_b9_split_chain_test.dart` | **新增**（≥ 8 例） |
| `apps/desktop/test/task66_goals_blueprint_page_test.dart` | 改：旧 pending 用例改写为新链路用例 |

**禁改**：`packages/**`、`goal_store.dart`、`providers.dart`、`goal_brand_panel.dart`。

**实现要点**：

1. **档位映射（用户原话逐条落库）**：

   | 被拆目标档位 | 子目标落位 | 落库口径 |
   |---|---|---|
   | 终极 `ultimate` | 远期 `long` | `createGoal(kind: blueprint, horizon: long, parentId: 父.id, domain: 父.domain)` + `link(child, goal, 父, serves)` |
   | 远期 `long` | 中期 `mid` | 同上（`horizon: mid`） |
   | 中期 `mid` | 短期 `short` | 同上（`horizon: short`） |
   | 短期 `short` | **年目标** | `createGoal(kind: yearly, periodStart: 年起点, periodEnd: 年终点, parentId: 父.id, domain: 父.domain)` + `link(child, goal, 父, serves)` |
   | 短期 `short` | **待办任务** | `store.repos.todo.create(title: …)` + `link(父, todo, todoId, tracks)`（**父目标 tracks 待办**，沿用既有口径） |
   | 近期 `near` | 同「短期」两选 | 1 年 ⊂ 短期（D-9-b 合并口径） |

2. **对话框**：N 行子目标标题（默认 3 行空，可增删；至少 1 行非空才可确认）+ 目标类型选择（仅短期/近期档显示「年目标 / 待办任务」二选一，其余档位由父档位推导且**不可选**）+ 确认/取消。
   - key：`goal-split-title-<n>` / `goal-split-add-row` / `goal-split-remove-<n>` / `goal-split-kind-yearly` / `goal-split-kind-todo` / `goal-split-confirm` / `goal-split-cancel`。
3. **确认即落库**（D-9-e）：点确认**直接写库**，不经过第二段「待确认」；写完 `_future = _load()` 刷新 ⇒ 子目标出现在**下一档标签页**、年目标出现在**年目标页**、待办出现在**待办池**。
4. **旧「待确认待办」区块、`_pending` 队列、`_addSplit` / `_confirmTodos`、`goalBlueprintPendingTodos` / `goalBlueprintConfirmTodos` 两个 l10n 键全部撤除**；`goal-blueprint-pending-*` / `goal-blueprint-todo-confirm` / `goal-blueprint-todo-empty` / `goal-blueprint-todo-saved` / `goal-blueprint-todo-error` 五个 ValueKey 随之消失。
5. **年目标的年份** = 蓝图页本年（`_period.year`，与年页同一份数据源）。
6. **拆分不改变父目标状态**（沿用 B8 口径：派生不改父目标状态）。

**判据**：

- analyze 逐字 `No issues found!`；本棒新增例数 **N3**（≥ 8），全量 = 920 + N1 + N2 + N3；
- l10n 五处计数自洽：`byGetter = accessors = 585`、`总数 = 585 + 4 + 53 = 642`；
- **落库双证**（测试 + 真机）：
  - 终极拆 3 条远期 ⇒ 库内 3 条 `kind=blueprint` / `horizon=2` / `parent_id=父.id` / `domain=父.domain`，且 3 条 `goal_link` 为 `goal_id=子, target_type='goal', target_id=父, relation='serves'`；
  - 短期拆 2 条年目标 ⇒ 2 条 `kind=yearly` / `period_start == 年起点`；
  - 短期拆 2 条待办 ⇒ 2 条 todo + 父目标 2 条 `tracks` 链接；
  - 父目标 `status` / `rev` 语义不被拆分改写（除 `rev` 自增）。

---

### W4 · 真机取证 + 门禁 + 出包 + 台账

- **控制器亲跑门禁**：`Move-Item` 挪走 `apps\desktop\build\test_cache\build`（→ `build_stale_<ts>`，**不删**）⇒ `pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests <实测 N>`（N = 920 + N1 + N2 + N3）。
- **门禁硬判据**：`GATE_VERDICT=PASS` / `GATE_FAILURES=0` / `DESKTOP_TESTS=N` 精确命中 / `CORE_DATA_TESTS=204` / `CORE_DB_TESTS=96` / `CORE_DOMAIN_TESTS=91` / 四包 `ANALYZE=VERBATIM` / `VIOLATIONS=0` / `OUT_OF_SET=0` / `PS1_ASCII_VIOLATIONS=0`。
- **真机取证**：构建树 `apps\desktop\build\windows\x64\runner\Release\actlog.exe` + `--data-dir=reports\task78-seeddb`（种子副本）⇒ **用户活库零写入**；帧落 `reports\task80-frames\`；证据 = **帧 + SQLite 读回**双证。
- **出包**：`tools\build\make_installer.ps1 -Version '1.0.0'` ⇒ 只出包**不装机**；**判重编必须比 sha16，不能比字节数**（坑 108）。
- **台账**：`docs/handoff-ledger-b9-w4.md`（体例照 `docs/handoff-ledger-b8-w4.md`）；`progress.md` ⑳；`handoff.md` §84；AGENTS.md §7 快照更新。

---

## 5. l10n 键预算（五处同步，**数字必须自洽**）

> l10n 底座判据：`byGetter.length == l10nAccessors.length == N`，总数 `N + 4 + 53`。改键数必须**五处**同步：`l10n_keys.dart` 常量 + `l10n_keys.dart` `byGetter` 映射 + `parts/goals.dart`（abstract + zh + en）+ `l10n_harness.dart` 访问器 + `l10n_base_test.dart` 五处计数。

### 5.1 W1：+54 键 ⇒ 522 → **576**；总数 579 → **633**

**模块级 14 键**：

| getter | zh | en |
|---|---|---|
| `goalBrandSection` | 个人品牌管理 | Personal brand |
| `goalBrandSave` | 保存 | Save |
| `goalBrandSaved` | 已保存 | Saved |
| `goalBrandSaveFailed` | 保存失败 | Save failed |
| `goalBrandEmpty` | 这一面还空着，写下第一句就算开始。 | This facet is still empty — one sentence is enough to start. |
| `goalBrandTitleLabel` | 这一面怎么说 | How you say it |
| `goalBrandNoteLabel` | 补充说明 | Notes |
| `goalBrandFacetNavLabel` | 切面 | Facets |
| `goalBrandGuideTitle` | 个人品牌建设全解 | Personal brand, end to end |
| `goalBrandGuideFormula` | 我帮助【目标人群】，在【具体场景】下，解决【什么问题】，通过【我的独特方法】，达到【什么结果】。 | I help 【audience】, in 【situation】, solve 【problem】, through 【my method】, to reach 【result】. |
| `goalBrandGuideLayers` | 三层结构：内在内核 → 能力价值 → 外在感知 | Three layers: inner core → value → visible image |
| `goalBrandGuideMethod` | 三步方法论：定位 → 呈现 → 传播 | Three steps: position → present → spread |
| `goalBrandGuidePbe` | PBE 三维诊断：吸引力 × 差异化 × 认知度 | PBE diagnosis: attraction × differentiation × awareness |
| `goalBrandGuideToggle` | 展开 / 收起指引 | Show / hide the guide |

**切面 40 键**（10 切面 × label / hint / example / counterexample）：

| 切面 | getter 后缀 |
|---|---|
| 定位语句 | `goalBrandFacetStatement` / `…Hint` / `…Example` / `…CounterExample` |
| 心智一词 | `goalBrandFacetWord` / … |
| 对象 / 他人视角 | `goalBrandFacetAudience` / … |
| 承诺结果 | `goalBrandFacetPromise` / … |
| 规避的代价 | `goalBrandFacetCost` / … |
| 可信证据 | `goalBrandFacetEvidence` / … |
| 对立面 | `goalBrandFacetContrast` / … |
| 三环交叉 | `goalBrandFacetStrength` / … |
| 剔除 / 减少 / 增加 / 创造 | `goalBrandFacetErrc` / … |
| 身份声明 | `goalBrandFacetIdentity` / … |

（每切面的中文要点 / 范例 / 反例见 **§附录**，worker 据此写 zh + en。）

### 5.2 W2：+3 −4 键 ⇒ 576 → **575**；总数 633 → **632**

**新增 3**：`goalBlueprintAddSymbol`（「+」/ '+'）/ `goalBlueprintSplit`（「拆分」/ 'Split'，图标 tooltip）/ `goalBlueprintShortTabNote`（「短期页含『近期（1 年）』：1 年蓝图目标与本年度年目标。」/ 'The short tab also carries near-term (1 year) goals and this year's yearly goals.'）

**删除 4**：`goalBlueprintMatrixSection`（D-9-h 去标题）/ `goalBlueprintEmptyCell`（不再显示「（空）」）/ `goalBlueprintNearSource`（原「近期列＝…」口径失效）/ `goalBlueprintSplitTodos`（旧「拆成 3 条待办」文字按钮下线）

### 5.3 W3：+12 −2 键 ⇒ 575 → **585**；总数 632 → **642**

**新增 12**：`goalSplitDialogTitle` / `goalSplitDialogHint` / `goalSplitDialogTargetLabel` / `goalSplitDialogAddRow` / `goalSplitDialogRemoveRow` / `goalSplitDialogConfirm` / `goalSplitDialogEmptyRow` / `goalSplitDialogSaved` / `goalSplitDialogFailed` / `goalSplitTargetYearly` / `goalSplitTargetTodo` / `goalSplitDialogNote`

**删除 2**：`goalBlueprintPendingTodos` / `goalBlueprintConfirmTodos`

> **兜底条款**：若实现确需增减键，**以实现为准**，但必须在台账写明最终 N，并让 `l10n_base_test.dart` 五处期望值自洽（`byGetter = accessors = N`，`总数 = N + 4 + 53`）。**不得留半成品键**（只加常量不加 getter / 只加 zh 不加 en）。

---

## 6. 既有 ValueKey 契约变更表（**唯一**允许变更的清单）

| Key | 处置 | 棒次 | 依据 |
|---|---|---|---|
| `goal-blueprint-empty-cell` | **消失**（不再渲染「（空）」） | W2 | 用户明文 |
| `goal-blueprint-pending-<title>` | **消失**（旧 pending 区块撤除） | W3 | D-9-e |
| `goal-blueprint-todo-confirm` | **消失** | W3 | D-9-e |
| `goal-blueprint-todo-empty` / `-saved` / `-error` | **消失** | W3 | D-9-e |
| `goal-blueprint-split-<id>` | **保留 key**，由文字按钮 → 右侧图标按钮；行为 W2 仍旧、W3 改新对话框 | W2/W3 | D-9-e |
| `goal-blueprint-edit-<id>` | **保留 key**，文字按钮 → 右侧铅笔图标 | W2 | D-9-d |
| `goal-blueprint-delete-<id>` | **保留**（二次确认不动） | — | 既有契约 |
| `goal-blueprint-add-<domain>-<horizon>` | **保留 key**，位置移到单元格右下角，标签由「+ 新建目标」改为「+」 | W2 | 用户明文 |
| `goal-blueprint-cell-<id>` / `-row-<domain>` / `-unplaced-<id>` / `-child-<id>` | **保留**（标签页切换后只在该档位可见） | W2 | — |
| `goal-blueprint-tab-<horizonKey>` | **新增** | W2 | — |
| `goal-brand-panel` / `-facet-<code>` / `-title-<code>` / `-note-<code>` / `-save-<code>` / `-saved` / `-error` | **新增** | W1 | — |
| `goal-split-title-<n>` / `-add-row` / `-remove-<n>` / `-kind-yearly` / `-kind-todo` / `-confirm` / `-cancel` | **新增** | W3 | — |
| `goal-blueprint-form-*` / `goal-blueprint-delete-confirm` / `-cancel` | **保留**（共享表单，不改名） | — | 既有契约 |

---

## 7. 每棒必跑的门禁与证据（缺一不可）

1. **门禁前**：`Move-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build_stale_<ts>'`（**改名不删**，否则 OS Error 183 挂死）。
2. **镜像必须进程内设置**：`$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`。
3. `flutter analyze`（desktop）**逐字** `No issues found!`；`flutter test --reporter compact` 末行 `+N: All tests passed!`。
4. core 三包 **204 / 96 / 91** 未变。
5. **TDD 时序**：先写测试 ⇒ 跑出**真红**（失败原因是**断言**不是编译错误）⇒ 再改产品 ⇒ 跑绿。红/绿日志分别落 `reports/taskNN-red.txt` / `-green.txt`。
6. **证据纪律（R5）**：结论必须打到**运行时产物**上（真机帧 / SQLite 读回 / 包内字节），「源码看着对」不算证据；「搜 X 得 0 命中」**不能**当「X 已消失」的证明（须同时给出宿主消失的证据）。
7. **零 `print(`**；Dart 源 **LF、无 BOM**；新增 `.ps1` 纯 ASCII、无 BOM、CRLF。
8. `reports/**` 被 `.gitignore` 排除 ⇒ **任何情况下不得 `git add reports/`**；帧与探针不入库。

---

## 8. 风险与挂账

| # | 风险 / 挂账 | 处置 |
|---|---|---|
| R-9-1 | 「近期（1 年）」列并入短期标签页后，**短期档格子内容变多** | D-9-b 已裁；`goalBlueprintShortTabNote` 明示来源 |
| R-9-2 | 年目标留在蓝图矩阵但无铅笔/拆分，用户可能觉得「少了个按钮」 | D-9-c 已裁；年目标改档位会写坏 `horizon`，改到年页更安全 |
| R-9-3 | `Icons.call_split` 在随包字体里是否存在 ⇒ 需真机帧确认（不 tofu） | W4 真机帧必拍「拆分」按钮；如 tofu ⇒ 改用 `Icons.call_split` 的替代（`Icons.alt_route`）并在台账留证 |
| R-9-4 | l10n 键数与 5 处同步点易错 | 每棒在台账写「改后 byGetter / accessors / 总数」三数自洽读数 |
| R-9-5 | 标签页切换导致既有测试大面积失配 | §6 变更表逐条列出；**改断言要改强**（不得改弱或删用例）；每文件 ≥ 3 例 |
| R-9-6 | 拆分落库涉及 `parent_id` + `serves` 链接双写 | W3 判据要求「行 + 链接」双证；`GoalServesIndex.childrenOf` 方向已在 §2 坐实 |
| R-9-7 | 品牌模块 10 切面 + 62 文案工作量集中 | 拆为 W1 单独一棒；指引文案放模块级（4 键）而非每切面 4 键以外再膨胀 |
| R-9-8 | B8 八项挂账（U-8-x / U-8-y / B8 包未装机 / 年页空态归因 / W3 两处遗留 / 注入通道缺陷 / 21:59:46 未单独留证） | **不属本批**，在 `docs/handoff-ledger-b9-w4.md` §挂账承接，**不重复施工** |
| R-9-9 | 本批**只出包不装机**（D-9-i） | 装机态复验留待用户决定；台账**不得**登记为「已装机验收」 |

---

## 附录 · 参考文章《个人品牌建设全解》要点 → 切面内容规划

> 来源：`https://www.doubao.com/thread/xlTAj7kOKM5w7yyQ1`（2026-11-25 已抓取全文）。**该文是内容素材，不是结构真源** —— 结构真源 = Task 62 §5.5 的 10 切面（D-9-g）。

**文章骨架（用于模块级指引文案）**

1. **内在内核**：个性（大五人格）＋ 品质（核心价值观 / 职业品格 / 真实性）
2. **能力价值**：专业能力 / 独特优势 / 价值主张（**差异化是前提**）
3. **外在感知**：外在形象 / 数字形象 / 观点输出 / 表达方式 / 传播渠道 / 他人评价 / 社交圈层
4. **PBE 三维模型**：品牌吸引力 × 品牌差异化 × 品牌认知度
   - 有吸引力、无差异化 ⇒ **易被替代**
   - 只有差异化、无认知度 ⇒ **酒香巷子深**
   - 只有认知度、无吸引力 ⇒ **名声反作用**
5. **个性五原型**：专家型 / 导师型 / 先锋型 / 实干型 / 联结型
6. **四大价值**：职业杠杆 / 商业加速 / 成长导航 / 社会关系筛选
7. **方法论三步**：定位（我是谁 / 为谁 / 解决什么 / 凭什么；**窄而深**）→ 呈现（一致性、3–5 个内容支柱）→ 传播（选对平台、价值先行、持续积累、互动连接）
8. **定位公式**：我帮助【目标人群】，在【具体场景】下，解决【什么问题】，通过【我的独特方法 / 优势】，达到【什么结果】

**10 切面内容规划（zh 语义规范；worker 据此写 zh + en 正式文案）**

| 切面 | 要点（hint） | 范例（example） | 反例（counterexample） |
|---|---|---|---|
| 定位语句 statement | 一句话说清「我是谁 / 为谁 / 解决什么 / 凭什么 / 带来什么结果」；窄而深，胜过面面俱到 | 我帮小微餐饮老板用一套 7 天菜单改造流程，把外卖差评率压到 3% 以内 | 我是一个热爱学习、追求成长的优秀青年 |
| 心智一词 word | 一个别人提起你就会想到的词；它替你的**方法**命名，不是形容性格 | 「菜单医生」——一听就知道解决的是菜单问题 | 努力 / 靠谱 / 优秀 |
| 对象（他人视角）audience | 先写给谁看；**默认最重要的一面**，它决定别人怎么介绍你 | 刚开业半年、靠一份外卖撑生意的小微餐饮店主 | 所有人；或只写「同行」 |
| 承诺结果 promise | 承诺一个**可验证的结果**，不是一个动作；对方能拿它对账 | 90 天内把单店月毛利从 3 万提到 4.5 万 | 帮你做好菜单、持续赋能 |
| 规避的代价 cost | 写清你不愿承担什么代价；这是筛选同行的开关 | 不接没有真实门店、只想白嫖方案的单子 | 什么都接、什么钱都赚 |
| 可信证据 evidence | 列出可核验的事实：做过多少家、什么结果、谁在背书 | 已陪跑 23 家门店，其中 11 家差评率下降 50% 以上；3 位老板可写推荐语 | 我很有经验、业内口碑不错 |
| 对立面 contrast | 你的对照组是谁；写清「我不做什么」，别人才知道何时找你 | 不做纯设计外包，不接只改海报不出方案的活 | 空着；或只写「和别人不一样」 |
| 三环交叉 strength | 专业能力 × 独特优势 × 价值主张的**交集**；交集之外别人也能做到 | 餐饮后厨 8 年经验（专业）× 懂平台流量规则（优势）× 能让店真的赚钱（主张） | 我热爱美食、擅长沟通 |
| 剔除/减少/增加/创造 errc | 对现状做四种手术；这是你的**方法论本体** | 剔除无效套餐；减少出品工序；增加复购触达；创造「7 天改造陪跑」这一交付形态 | 全面升级、优化体验 |
| 身份声明 identity | 你要成为什么样的人；**内在内核**，决定十年后还在不在同一件事上 | 我是那个让小餐饮老板敢把菜单交给我的人 | 我是一个不断学习的人 |

> 五原型（专家/导师/先锋/实干/联结）**不单列为切面** —— 10 切面是域层冻结值（D-9-g），五原型归入 `identity` 的指引文案与模块级指引。

---

## 9. 指针

| 文档 | 绝对路径 |
|---|---|
| 项目规范 | `F:\soft\00selfmade\practilog\AGENTS.md` |
| 本计划 | `F:\soft\00selfmade\practilog\docs\plan-goals-ui-batch9.md` |
| W1 派工书 | `F:\soft\00selfmade\practilog\docs\b91-dispatch-w1.md` |
| B8 计划（上批真源） | `F:\soft\00selfmade\practilog\docs\plan-goals-ui-batch8.md` |
| B8 W4 台账（体例样板） | `F:\soft\00selfmade\practilog\docs\handoff-ledger-b8-w4.md` |
| Task 62 §5.5 品牌画像设计 | `F:\soft\00selfmade\practilog\docs\task62\模块规划.md`（行 371–394） |
| 门禁脚本 | `F:\soft\00selfmade\practilog\reports\task51-gate.ps1` |
