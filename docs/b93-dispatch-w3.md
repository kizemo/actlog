# B9-W3 派工书 · 四级拆分链路（终极 → 远期 → 中期 → 短期 → 年目标 / 待办）

> 合同性质：**本文件是本棒唯一实现契约**。与 `docs\plan-goals-ui-batch9.md` 冲突时以本文件为准；与用户当轮原话冲突时以用户原话为准。worker 不得再自行裁决范围。

---

## 0. 合同信息

| 项 | 值 |
|---|---|
| 仓库根 | `F:\soft\00selfmade\practilog` |
| 棒次 | **B9-W3**（B9 共 4 棒，**串行**；本棒在 W2 收口后开工） |
| 设计真源 | `F:\soft\00selfmade\practilog\docs\plan-goals-ui-batch9.md`（W3 段落：§4 行 173–217；l10n 预算：§5.3 行 278–284；契约变更表：§6） |
| 项目规范 | `F:\soft\00selfmade\practilog\AGENTS.md`（**动手前必读**：R1 / R2 / R5 / §5 坑 51、97、108） |
| 起点 | W1（品牌面板）、W2（矩阵四标签页）已入库 |
| 基线测试数 | `<<DESKTOP_BASE_AFTER_W2>>`（控制器回填；本棒结束 = 该数 + N3，`N3 ≥ 8`） |

---

## 1. 用户当轮原话（本棒逐条落地）

> 终极目标，可以拆分为多个 远期目标，远期目标可以拆分为多个中期目标，中期目标又可以拆分为多个短期目标。拆分后，可以自动填入对应的表中。短期目标，则可以拆分为多个年目标或待办任务。确认拆分后，也直接填入对应表格。

**控制器裁决（D-9-e）**：用户明文「确认拆分后，也直接填入对应表格」⇒ **旧的两段式（先拆成待办、再在页面上点「确认」写入）整体废止**。点「确认」**直接写库**。

> **W2 基线（控制器回填）**：`<<DESKTOP_BASE_AFTER_W2>>` = W2 收口后的 desktop 全量测试数。

---

## 2. 写集（**你独占**，表外任何文件一律不得改）

| 文件 | 动作 |
|---|---|
| `apps/desktop/lib/src/widgets/goals/goal_split_dialog.dart` | **新增** |
| `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 改：拆分按钮改走新对话框回调 |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 改：接线 + 落库；**移除旧「待确认待办」区块与 `_pending` 队列** |
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 改：**+12 −2**（见 §4） |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 改：+12 常量 + 12 条 `byGetter`；−2 常量与映射条目 |
| `apps/desktop/test/l10n_harness.dart` | 改：随键数同步（+12 −2 访问器） |
| `apps/desktop/test/l10n_base_test.dart` | 改：**5 处计数 575→585 / 632→642** |
| `apps/desktop/test/task79_b9_split_chain_test.dart` | **新增**（≥ 8 例） |
| `apps/desktop/test/task66_goals_blueprint_page_test.dart` | 改：旧 pending 用例改写为新链路用例（**改强，不得删例**） |

**禁改**：`packages/**`、`data/goal_store.dart`、`providers.dart`、`widgets/goal_brand_panel.dart`（W1）、`reports/**`（不得 `git add reports/`）、`reports/task51-gate.ps1`。

> ⚠️ `goals_blueprint_page.dart` 与 `goal_blueprint_matrix.dart` 是**共享文件**：W1 插了品牌面板，W2 改了标签页 / 空态 / 右侧按钮。**只动拆分相关代码**，其余保留。

---

## 3. 实现契约

### 3.1 落库映射（**用户原话逐条落库，口径已坐实**）

| 被拆目标档位 | 子目标落位 | 落库调用 |
|---|---|---|
| 终极 `GoalHorizon.ultimate` | 远期 `long` | `createGoal(kind: GoalKind.blueprint, horizon: long, parentId: 父.id, domain: 父.domain)` + `link(childId, goal, 父.id, serves)` |
| 远期 `long` | 中期 `mid` | 同上（`horizon: mid`） |
| 中期 `mid` | 短期 `short` | 同上（`horizon: short`） |
| 短期 `short` | **年目标** | `createGoal(kind: GoalKind.yearly, periodStart: 年起点, periodEnd: 年终点, parentId: 父.id, domain: 父.domain)` + `link(childId, goal, 父.id, serves)` |
| 短期 `short` | **待办任务** | `store.repos.todo.create(title: …)` + `link(父.id, todo, todoId, tracks)`（**父目标 tracks 待办**） |
| 近期 `near` | 同「短期」两选 | 1 年 ⊂ 短期（W2 已把近期并入短期 tab） |

**关键口径（不要猜）**：

- `serves` 方向：`GoalServesIndex`（`apps/desktop/lib/src/widgets/goal_year_matrix.dart:27-51`）中 `parentsOfGoal` = 目标→它服务的上层，`childrenByParent` = 上层→下级 ⇒ **`childrenOf(parent)` 取下级**；`GoalRelation.serves` = 「本目标服务于上层目标」⇒ 子目标落库 = `link(goalId: 子, targetType: goal, targetId: 父, relation: serves)` + `parent_id = 父.id`。
- `createGoal` 的 `parentId` 参数会写 `goal.parent_id` ⇒ **子目标行与 serves 链接必须双写**（判据要求行 + 链接双证）。
- **年目标的周期**：`periodStart` 必须**精确等于**周期起点（`GoalStore._goalsInPeriod` 的判据是 `period_start == 周期起点`，`goal_store.dart:1131-1144`）。用 `GoalPeriod.year(y).startMillis` / `.endMillis`，`y` = 蓝图页本年（`_period.year`，与年页同一份数据源）。
- **拆分不改变父目标状态**（沿用 B8 口径：派生不改父目标状态；父行只允许 `rev` 自增）。
- 链接 API 以 `GoalStore` / `ActLogRepositories` 里既有的 link 入口为准（**先读源码确认方法名与参数顺序**，不要臆造）。

### 3.2 拆分对话框（新文件 `widgets/goals/goal_split_dialog.dart`）

- 形态建议 `showGoalSplitDialog({required String parentTitle, required GoalHorizon parentHorizon})` → 返回结果对象（子目标标题列表 + 目标类型）。**不写库**，只出结果。
- 内容：
  1. **N 行子目标标题输入框**，默认 3 行空；可增行 / 删行；
  2. **至少 1 行非空**才允许点「确认」（否则给 `goalSplitDialogEmptyRow` 提示）；
  3. **目标类型选择**：**仅当父目标档位为 `short` / `near`** 时显示「年目标 / 待办任务」二选一；其余档位由父档位**推导**（终极→远期、远期→中期、中期→短期）且**不显示选择器**；
  4. 确认 / 取消按钮。
- ValueKey（**新增，逐字照抄**）：
  - `goal-split-title-<n>`（n = 行号，从 0 或 1 开始自洽即可，同一文件内一致）
  - `goal-split-add-row`
  - `goal-split-remove-<n>`
  - `goal-split-kind-yearly`
  - `goal-split-kind-todo`
  - `goal-split-confirm`
  - `goal-split-cancel`
- 断言只走 ValueKey / `find.byIcon`，**禁字形级断言**（坑 51）。

### 3.3 接线与落库（蓝图页）

- W2 已把矩阵上的拆分按钮（ValueKey `goal-blueprint-split-<id>`）做成右侧紧凑图标按钮，仍挂在**旧回调**上；本棒把它改挂到**新对话框**回调。
- 点「确认」⇒ **直接写库**（不再有「待确认待办」中间态）⇒ 写完蓝图页 `_future = _load()` 刷新 ⇒
  - 子蓝图目标出现在**下一档标签页**（终极拆出的远期出现在「远期」tab）；
  - 年目标出现在**年目标页**；
  - 待办出现在**待办池**（并可在年/月/周页排期）。
- 写库失败 ⇒ 给用户可见失败提示（`goalSplitDialogFailed`），**不得静默**。

### 3.4 旧「待确认待办」链路整体撤除（D-9-e）

**必须删除**（不是隐藏，是删代码 + 删键）：

- 蓝图页的「待确认待办」区块 UI；
- `_pending` 队列；
- `_addSplit` / `_confirmTodos` 两个方法；
- l10n 键 `goalBlueprintPendingTodos` / `goalBlueprintConfirmTodos`；
- 随之消失的 ValueKey：`goal-blueprint-pending-<title>` / `goal-blueprint-todo-confirm` / `goal-blueprint-todo-empty` / `goal-blueprint-todo-saved` / `goal-blueprint-todo-error`。

> 删除类操作在 Git 侧用**改动**（删代码段）实现即可；本条指的是**产品链路下线**，不是「不删仓库文件」（R4 只针对仓库文件清理，代码行随功能下线是正常改动）。

### 3.5 ValueKey 契约（本棒）

| Key | 处置 |
|---|---|
| `goal-blueprint-pending-<title>` | **消失** |
| `goal-blueprint-todo-confirm` / `-empty` / `-saved` / `-error` | **消失** |
| `goal-blueprint-split-<id>` | **保留 key**，行为改为打开新拆分对话框 |
| `goal-blueprint-edit-<id>` / `-delete-<id>` / `-add-<domain>-<horizon>` / `-cell-<id>` / `-row-<domain>` / `-tab-<horizonKey>` | **保留**（W2 契约） |
| `goal-split-title-<n>` / `-add-row` / `-remove-<n>` / `-kind-yearly` / `-kind-todo` / `-confirm` / `-cancel` | **新增** |
| `goal-brand-*`（W1） | **保留**，不得改动 |

---

## 4. l10n 契约（+12 −2，**五处同步**）

**新增 12**：`goalSplitDialogTitle` / `goalSplitDialogHint` / `goalSplitDialogTargetLabel` / `goalSplitDialogAddRow` / `goalSplitDialogRemoveRow` / `goalSplitDialogConfirm` / `goalSplitDialogEmptyRow` / `goalSplitDialogSaved` / `goalSplitDialogFailed` / `goalSplitTargetYearly` / `goalSplitTargetTodo` / `goalSplitDialogNote`

**删除 2**：`goalBlueprintPendingTodos` / `goalBlueprintConfirmTodos`

**五处同步点**：`l10n_keys.dart` 常量 + `l10n_keys.dart` `byGetter` + `l10n/parts/goals.dart`（abstract + zh + en） + `test/l10n_harness.dart` 访问器 + `test/l10n_base_test.dart` **5 处计数 575→**585** / 632→**642**。

**计数自洽**：`byGetter == accessors == 585`；`总数 == 585 + 4 + 53 == 642`。**不得留半成品键**。

---

## 5. 门禁（必跑，全绿才算完成）

```powershell
Move-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' `
          'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build_stale_<yyyyMMdd-HHmmss>'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze            # 期望逐字：No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact   # 期望末行：+N: All tests passed!
```

**硬判据**：

| 项 | 期望 |
|---|---|
| analyze | **逐字** `No issues found!` |
| 全量测试 | 精确 = `<<DESKTOP_BASE_AFTER_W2>>` + N3（N3 ≥ 8） |
| l10n 计数 | `byGetter = accessors = 585`；`总数 = 642` |
| 落库双证（测试内） | 见 §6 |
| 代码卫生 | 零 `print(`；Dart 源 LF、无 BOM |

---

## 6. 证据纪律（R5）—— **落库双证**

测试内必须同时断言「行」与「链接」，缺一不算：

1. **终极拆 3 条远期** ⇒ 库内 3 条 `kind=blueprint` / `horizon=2`（long）/ `parent_id=父.id` / `domain=父.domain`，且 3 条链接为 `goal_id=子, target_type='goal', target_id=父, relation='serves'`；
2. **短期拆 2 条年目标** ⇒ 2 条 `kind=yearly` / `period_start == 年起点`（精确等值）；
3. **短期拆 2 条待办** ⇒ 2 条 todo + 父目标 2 条 `tracks` 链接；
4. **父目标状态不被改写**：父行 `status` 与拆分前一致（只允许 `rev` 自增）。

TDD：先写测试 ⇒ **真红**（失败原因是断言）⇒ 改产品 ⇒ 绿。红/绿日志落 `reports\task79-red.txt` / `reports\task79-green.txt`（reports 被 gitignore，**不得 `git add reports/`**）。

轮询日志用共享读打开（`[IO.File]::Open($p,'Open','Read','ReadWrite')`）；一切路径用绝对路径；不 `Set-Location` 后写相对路径文件。

---

## 7. 提交纪律

- 只 `git add <逐个文件>`（禁止 `git add .` / `-A`），提交信息 `feat(goals): B9 W3 four-level split chain`,**不 push**，不 stash / 不用 `git add -p` / 不用 `git restore` / 不用 `git commit --only`。

---

## 8. 交付报告（≤ 30 行）

1. 改了哪些文件（新增/修改 + 行数变化）。
2. `flutter analyze` **逐字**输出行。
3. `flutter test` 末行 + `N`；`N3 = N - <<DESKTOP_BASE_AFTER_W2>>`。
4. l10n 回读三数（byGetter / accessors / 总数）。
5. §6 四条落库双证逐条给测试名 + 行号 + 实际读数。
6. 旧 pending 链路撤除清单（方法 / 区块 / 2 个 l10n 键 / 5 个 ValueKey 逐项确认已消失）。
7. commit sha16 + 提交文件清单。
8. 未完成 / 未验证 / 已知偏差（没有就写「无」）。
9. 留给 W4 的事实：拆分对话框打开路径（函数 + 行号）、年目标年份来源、todo 落库路径。
