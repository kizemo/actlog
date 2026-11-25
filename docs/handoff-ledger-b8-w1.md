# B8-W1 收口台账（**未收口 · 阻塞待控制器裁决**）

- 棒次：批次 B8 第一棒 B8-W1 · 派工书 `docs\b81-dispatch-w1.md`
- 会话：`mvs_23aacd3e9ac7402c82d2b596b7b839e3`（worker 子会话）· 日期 2026-11-25
- 进场 HEAD：`4d4af31`（`docs(b8): B8 设计真源 …`），父 `9684268`（Task 72 / B7 收口）
- **本轮状态：取证完成、产品代码零改动、零提交。原因见 §2（写集缺口，非技术障碍）。**

---

## 0. 一句话结论

派工书 §4.1「格内 + 新建目标」与 §4.2「卡片编辑 / 删除入口」在**只改 B8-W1 写集内文件**的前提下
**物理上不可实现**：格子与卡片 100% 由 `apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart`
自己渲染，页面侧无任何注入点（该控件构造入参只有 5 个，`goals_blueprint_matrix.dart:43-50`）。
按 `AGENTS.md:28`（R1）须**先由控制器在写集表追加一行并留档**，故本轮不擅自越界，转为回报 + 交付可直接落地的规格。

---

## 1. 派工书事实复核（逐条盘上回读，**三处与派工书不符，以盘上为准**）

| # | 派工书 §3.6 / §3.4 的断言 | 盘上实测 | 证据 |
|---|---|---|---|
| 1 | 卡片 key = `goal-blueprint-cell-<domain>-<horizon>` | **错**。实际 = `goal-blueprint-cell-${goal.id}`（按目标 id，不按格子坐标） | `widgets\goal_blueprint_matrix.dart:184` |
| 2 | 空格 key = `goal-blueprint-empty` | **错**。实际 = `goal-blueprint-empty-cell`，且空格子**只渲染一个 `Text`，无任何按钮位** | `goal_blueprint_matrix.dart:172-176`；既有测试 `test\task66_goals_blueprint_page_test.dart:198` 亦钉此名 |
| 3 | `createGoal(...) -> Future<Goal>` | **错**。实际 **`Future<String>`（返回新 id）**；`updateGoal` 是 **位置参数 `goalId`** + 命名可选字段 + `Set<GoalField> clear`；`deleteGoal(String goalId)` 对不存在的 id **抛 `GoalMissingException`** | `data\goal_store.dart:403`、`:498`、`:616`；用例 `test\task66_goals_blueprint_page_test.dart:61,69,217,287` |
| 4 | 行首 key / 拆待办 key | 一致：`goal-blueprint-row-<domainKey>`（`:135`）、`goal-blueprint-split-<goalId>`（`:212`）、`goal-blueprint-unplaced-<id>`（`:196`）、`goal-blueprint-child-<id>`（`:205`） | 同上 |
| 5 | desktop 基线 = 907 | **确认**（盘上回读，非转述）：`reports\task51-gate\summary.txt` → `DESKTOP_TESTS=907` / `GATE_VERDICT=PASS` / `VIOLATIONS=0` / `OUT_OF_SET=0`（该 summary 的 `HEAD=8c01455`，即 B7 收口时读数；其后仅 `4d4af31` 一笔 docs 提交） | `reports\task51-gate\summary.txt` |
| 6 | 归属口径不得动（D-8-f） | 确认取数在页面 `pages\goals_blueprint_page.dart:148-166`，`near` 列并入 `view.yearlyGoals`；本轮未触碰 | 源码 |
| 7 | 本页既有「操作后立刻反映」范式 | 确认：`_saving:101` / `_saved:104` / `_error:107`、反馈 `ValueKey('goal-blueprint-todo-saved'):296`、写库 + 重取在 `_confirmTodos:317-354`（`try/on Object` → `_error=t.operationFailed`；成功 → `_saved=true` + `_future=_load()`） | 源码 |

**控件渲染面实况**（决定入口只能落在控件内）：`_cell(...)` @ `goal_blueprint_matrix.dart:165-220` 是
格子内容的**唯一**渲染函数；`GoalBlueprintMatrix` 仅接受 `t / rows / serves / tracksCount / onSplitTodos`。

---

## 2. 阻塞：B8-W1 写集缺 4 个文件（全部**已在门禁白名单内**，只差计划表那一行）

R1 判据链：写集真源 = `docs\plan-goals-ui-batch8.md:69`（§4 表 B8-W1 行）=
`pages\goals_blueprint_page.dart`、`l10n\parts\goals.dart`、新测试。派工书 §2 与之一致。
下列文件是实现的**必要改动面**，但不在该行内：

| 必须改的文件 | 为什么必须 | 现状证据 | 门禁白名单 |
|---|---|---|---|
| `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 格内新建入口 + 每卡片编辑/删除按钮只能加在这里 | 全仓**唯一构造点** = `pages\goals_blueprint_page.dart:247`（静态 `horizons` 另被 `:152` 引用）⇒ 加可选回调**零外溢** | ✅ 已被 `reports\task51-gate.ps1:320` `'apps/desktop/lib/src/widgets/goal*'` 覆盖 |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 新 getter 必须登记，否则键表缺项 | `test\l10n_base_test.dart:32` 要求 `l10nAccessors.keys == L10nKeys.byGetter.values` **集合全等** | ✅ `task51-gate.ps1:199` / `:252` |
| `apps/desktop/test/l10n_base_test.dart` | **硬编码计数** `511` 必须随新增数上跳 | `l10n_base_test.dart:27-29`（`byGetter.length==511`、`l10nAccessors.length==511`）；测试名逐字「511 条 getter 全部登记在对照表里」 | ✅ `:211` / `:276` |
| `apps/desktop/test/l10n_harness.dart` | `l10nAccessors` 表在此（`l10n_harness.dart:28`），每条新 getter 必须加一行映射 | `l10n_harness.dart:197-198` 为现有蓝图词条样例 | ✅ `:212` / `:277` |

⇒ **改这 4 个文件不会造成 `OUT_OF_SET`**（门禁机械层已放行），纯粹是 R1 的「写集表那一行」需要控制器补登记并留档
（先例：`AGENTS.md:28` 引 Task 21「收口补」行）。

另需控制器补一处（**仅当**本轮新增测试文件按 §5 落盘时）：
`reports\task51-gate.ps1` 的 `$allowed` 里现有 `task64_* / task65_* / task66_* / task69_* / task72_* / goal* / blueprint_page_test.dart`，
**均不匹配 `task73_b8_w1_blueprint_edit_test.dart`** ⇒ 需追加 `'apps/desktop/test/task73_*'`。
（`reports\taskN-*` 按 R1 属控制器台账，worker 不得改。）

### 为什么本轮不「先做完不依赖该决定的部分」

派工书 §4 的三条能力（新建 / 编辑 / 删除）与 l10n 计数装置**全部**落在这 4 个文件上：
只改 `goals.dart` 加词条 ⇒ `l10n_base_test.dart` 必红；只改页面接线到尚不存在的控件回调 ⇒ 编译不过；
写半套页面代码 ⇒ `flutter analyze` 出现未使用私有成员的 info，而 R2 要求**逐字** `No issues found!`。
即「不存在可独立提交且能过门禁的子集」。

---

## 3. 授权后即可落地的实现规格（本轮已设计完，未写盘）

### 3.1 控件：只做**加法**，默认值保持既有渲染逐字不变（`AGENTS.md` §5 坑 48）

```dart
// GoalBlueprintMatrix 构造新增三个可选回调（null ⇒ 完全不渲染新按钮，
// 现有 task66 / blueprint_page 两用例零改动即通过）：
final void Function(String domainKey, GoalHorizon horizon)? onAddGoal;
final void Function(GoalRow goal)? onEditGoal;
final void Function(GoalRow goal)? onDeleteGoal;
```

- `_cell` 需接收 `row.domainKey`（现签名 `:165` 无此参）；
- 空格分支（`:171-177`）：`onAddGoal != null` 时在 `goal-blueprint-empty-cell` 之外**追加**
  `TextButton(key: ValueKey('goal-blueprint-add-${domainKey}-${horizon.value}'))`，文案 `t.goalBlueprintAddGoal`；
- 卡片分支（`:182-217`）：在既有 `goal-blueprint-split-<id>` 同一 `Align` 旁**追加**
  `goal-blueprint-edit-<id>` / `goal-blueprint-delete-<id>`；
- 沿用文件头契约「不使用 Material 图标（`Icons.`）」（`goal_blueprint_matrix.dart:14`）⇒ 纯文字按钮。

### 3.2 页面：`goals_blueprint_page.dart`

- 新增 `enum _GoalFormMode { create, edit }` + `_showGoalForm({mode, domainKey, horizon, goal})`，
  表单字段覆盖派工书 §4.2 全部 9 项：`title / note / keywords / domain / horizon / facet / dueDate / priorityAbc / quadrant`；
  `create` 用 `GoalKind.blueprint`，**domain/horizon 初值 = 所在格子**且表单内可见可改（D-8-e）；
- 写库只用 `store.createGoal`（拿返回的 `String` id）/ `store.updateGoal(id, …, clear: …)`；
  `domain` 清空走 `clear: {GoalField.domain}`（`goal_store.dart:498` 的 `Set<GoalField> clear` 入参）；
- 删除：先 `AlertDialog`（key `goal-blueprint-delete-confirm` / `goal-blueprint-delete-cancel`），
  确认才 `store.deleteGoal(id)`（`GoalMissingException` 走 `_error`），取消**不得触库**；
- 反馈复用本页范式：`_saved` / `_error` + 新 key `goal-blueprint-goal-saved`、`goal-blueprint-goal-deleted`；
  成功后 `_future = _load()` 重取（`:317-354` 同款），**不改** `:148-166` 的取数口径（D-8-f）。
- 表单是否抽成共享组件（计划 §4 说「W1/W2 共用同一个 goal 编辑表单组件」，而 W2 那行拥有 `widgets\goals\`，
  该目录**当前不存在**）⇒ 见 §6 问题 2，未裁决前 W1 先把表单**私有留在页面文件内**，W2 再抽取。

### 3.3 l10n 三处联动登记（缺一不可）

`l10n\parts\goals.dart` 是 abstract `GoalsL10n`（`:22`）+ zh（`:312`）+ en（`:582`）三段 ⇒ 每条新词条要写 **3 处**；
再 `l10n_keys.dart` 加 `byGetter` 条目、`l10n_harness.dart` 加访问器映射、`l10n_base_test.dart:27-29` 的 `511` 改成 `511+N`。
**动手前先 grep `l10n_keys.dart` 是否已有「编辑 / 删除 / 取消 / 保存」类现成词条可复用**，避免重复文案虚增 N。
预估新增 10–14 条 ⇒ `511 → 521..525`，`DESKTOP_TESTS=907 → 907+4`。

---

## 4. 判别性测试（T1–T4，已设计，**未落盘、未跑红**）

落盘路径 `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart`；harness 直接抄
`task66_goals_blueprint_page_test.dart:114-150`（真库 `openInMemoryActLogDatabase` + `l10nScope` +
`todayProvider='2026-11-25'` + `goalStoreProvider.overrideWithValue(GoalStore(repos))`），
**禁** `warnIfMissed: false`（§5 坑 57）。判据全部读库，不看像素：

| 例 | 动作 | 判据（真值来源） | 撤掉修复是否必红 |
|---|---|---|---|
| T1 | 点 `goal-blueprint-add-career-ultimate` → 填标题 → 提交 | `store.listGoals()` 出现 `kind=blueprint, domain='career', horizon=ultimate` 的新行 **且** `goal-blueprint-cell-<newId>` 出现在该格 | 是（无入口则红） |
| T1b | 同上表单点取消 | `listGoals()` 计数与提交前**完全相等**（防「打开即写」） | 是 |
| T2 | 点 `goal-blueprint-edit-<id>` → 改 title + 把 horizon 从 `ultimate` 改 `long` → 提交 | 读回该行 `title` 已改、`horizon` 已移列（`findGoal(id)` 字段判据），且矩阵里旧格不再有该卡片、新格出现 | 是 |
| T3 | 点 `goal-blueprint-delete-<id>` → 确认对话框出现 → 先点**取消**，再点**确认** | 取消后 `findGoal(id) != null` 且 `deleted_at IS NULL`；确认后 `findGoal(id) == null`（`deleteGoal` 写墓碑 `deleted_at`，`goal_store.dart:616`） | 是 |
| T4 | 任一成功写库后**不重挂页面** | 同一次 pump 内 `goal-blueprint-goal-saved` 可见 **且**新卡片已在矩阵中（防「只写库不刷新」） | 是 |

---

## 5. 本轮实际改动面（越界自检）

- 新增：`docs\handoff-ledger-b8-w1.md`（本文件，写集内）。
- **产品代码 / 既有测试 / packages 零改动、零提交、零 `git add`。**
- 未跑红灯：T1–T4 尚未落盘（理由见 §2 末，落盘即全量 `flutter test` 必红，会污染共享工作区里
  另一条接力链正在跑的门禁）。
- 工作区既有脏文件（`AGENTS.md`、`docs\relay.json`、`docs\relay\*`）属**另一条链**，本轮未触碰、未纳入任何提交。

## 6. 请控制器裁决（两问，答完即可直接按 §3 落地）

1. **是否把以下 4 个文件追加进 B8-W1 写集**（并留档一行）：
   `widgets\goal_blueprint_matrix.dart`、`l10n\l10n_keys.dart`、`test\l10n_base_test.dart`、`test\l10n_harness.dart`
   —— 四者已在门禁 `$allowed` 内，追加后无需改 `reports\task51-gate.ps1`（除 `apps/desktop/test/task73_*` 一行）。
   不接受则请给出「入口全部落在页面层」的替代形态定义（此时 D-8-e「由所在格子预填」需重新定义）。
2. **共享目标编辑表单落点**：W1 先私有在 `goals_blueprint_page.dart` 内、由 W2 抽取到 `widgets\goals\`（推荐，
   不动 W2 写集）；还是 W1 直接建 `widgets\goals\goal_edit_form.dart`（则该行须同时追加给 W1，与 W2 有并发风险）。

---

## 7. 第二轮（续棒）：实现落盘 + 单文件转绿

### 7.1 红灯基线（上一轮产物，仍在盘上）

`reports\task73-red.txt` 4,658 B / `task73-red.err.txt` 2,587 B（20:17:47），`EXITCODE=1`。三类编译错误：
`QueryRow` 未定义（测试 `:76/:87/:92`）、`GoalServesIndex` / `loadGoalServesIndex` 未定义（`:427`）、
`goalBlueprintAddGoal` / `goalBlueprintGoalSaved` / `goalBlueprintFieldUnset` 未定义（`:223/:276/:351`）。

**根因裁决**：`QueryRow` 由 `package:drift/drift.dart` 导出；`GoalServesIndex` / `loadGoalServesIndex`
在 `lib\src\widgets\goal_year_matrix.dart` **公开存在** ⇒ 纯属测试文件缺 import，不是缺实现。
故只补两条 import（属写集第 ⑦ 项「仅限 harness 装配 / import」），**未改任何断言**。

### 7.2 落盘面（逐文件盘上回读，全部 LF / CR=0）

| 文件 | 行数 | 字节 | 本轮改动 |
|---|---|---|---|
| `lib\src\widgets\goal_blueprint_matrix.dart` | 307 | 11,569 | 三个可选回调 `onAddGoal`/`onEditGoal`/`onDeleteGoal`（默认 null）；空格追加 `goal-blueprint-add-<domain>-<horizon>`；卡片追加 `goal-blueprint-edit-<id>`/`-delete-<id>`，**门控 `kind == blueprint`** |
| `lib\src\pages\goals_blueprint_page.dart` | 847 | 28,198 | `_openCreateGoal`/`_openEditGoal`/`_confirmDeleteGoal`/`_writeGoal`；`_GoalFormDialog`（页内私有）；三条反馈 key |
| `lib\src\l10n\parts\goals.dart` | 965 | 24,717 | abstract + zh + en 各 12 条（三段同序） |
| `lib\src\l10n\l10n_keys.dart` | 2,533 | 101,704 | 12 个 kebab 常量 + `byGetter` 12 行 |
| `test\l10n_harness.dart` | 807 | 47,857 | `:27` 注释 → 523；`goalBlueprintBalanceHabit` 之后插 12 条访问器 |
| `test\l10n_base_test.dart` | 663 | 29,023 | `:27-29` 三处 `511 → 523` |
| `test\task73_b8_w1_blueprint_edit_test.dart` | 533 | 19,470 | 只加 2 条 import（drift `QueryRow`、`goal_year_matrix.dart`） |

盘上核对：`byGetter=523 / byListGetter=4 / byMethod=53`，12 个新键**全部在表内且无重名**。

### 7.3 单文件转绿

`reports\task73-green.txt` 4,585 B（20:28:25），`EXITCODE=0`，末行 **`00:06 +6: All tests passed!`**
（T1 / T1b / T2 / T3 / T4a / T4b 六条全绿）。

### 7.4 第二次跑红：`l10n_base_test.dart` 还有一处硬编码总数

首轮全量 `+912 -1`（`reports\task73-full.txt` 覆盖前的读数），唯一红项：
`全部键值不重复（511 + 4 + 53 = 568）`（`l10n_base_test.dart:111` + `:117` 的 `expect(all.length, 568)`）。
**同类但独立于 `:27-29` 的第二处计数**，上一轮台账只点名了 `:27-29`，漏了这处 ⇒ 已一并改到
`523 + 4 + 53 = 580`。改后全量 **`01:43 +913: All tests passed!`（`EXITCODE=0`）**。

⇒ 口径修正：`l10n_base_test.dart` 的硬编码计数**共 5 处**（`:27` 测试名、`:28`、`:29`、`:111` 测试名、`:117`），
不是 3 处。后续任何「新增 getter」任务必须 grep `568` 与 `511` 两个数字，别只看 `:27-29`。

### 7.5 新踩的坑（须并入 `AGENTS.md` §5）

**`l10nScope` 包的是 `MaterialApp.home`，而 `showDialog` 的 builder 在 Navigator 的 overlay 里构建 —— 那里在
`L10nScope` 之上**，`AppLocalizations.of(context)` 必抛「找不到 L10nScope」。首跑时 T1 / T1b / T2 / T4b 四条
全部卡在这条上（T3 / T4a 通过）。修法：在页面 State 自己的 context 上先取 `t`，作为参数传入对话框
（`goals_blueprint_page.dart` `_openCreateGoal` / `_openEditGoal` 各加一行 + 注释说明）。

⇒ 推广口径：**任何 `showDialog` 里要文案，都不能在 builder 内 `AppLocalizations.of`**；本仓 `l10nScope`
在 `home` 内部是既有测试夹具的普遍形态，故这条对后续所有对话框都成立。

---

## 8. 门禁判定：`GATE_VERDICT=FAIL`（两红，**均非本棒产品代码所致**）⇒ 按派工书「报 OUT_OF_SET 即停下回报」未提交

### 8.1 盘上读数（`reports\task51-gate\summary.txt`，20:36:35，2,012 B）

```
GATE_VERDICT=FAIL
GATE_FAILURES=2
FAIL_ITEM=OUT_OF_SET=4
FAIL_ITEM=PS1_ASCII_VIOLATIONS=4
DESKTOP_TESTS=913 / DESKTOP_EXPECTED=913       ← 计数判据满足
CORE_DATA_TESTS=204 / CORE_DB_TESTS=96 / CORE_DOMAIN_TESTS=91   ← 三包基线不动
DESKTOP_ANALYZE=VERBATIM  CORE_DATA_ANALYZE=VERBATIM
CORE_DB_ANALYZE=VERBATIM  CORE_DOMAIN_ANALYZE=VERBATIM        ← 四包 analyze 逐字 No issues found!
VIOLATIONS=0                                                   ← 写集外产品代码零改动
HEAD=4d4af31
```

四项**技术判据全绿**：913 测试全过、四包 analyze 逐字、`VIOLATIONS=0`、`OUT_OF_SET` 里无一条 `apps/` 或 `packages/` 路径。

### 8.2 `OUT_OF_SET=4` 明细（用门禁自己的 201 条 `$patterns` 复算，非推断）

| 路径 | 归属 | 门禁缺哪条模式 |
|---|---|---|
| `docs/plan-goals-ui-batch8.md` | 控制器（B8 计划正文） | 只有 `docs/plan-goals-ui-batch7.md` |
| `docs/b81-dispatch-w1-retry.md` | 控制器（本轮补书） | 只有 `docs/b71-dispatch-*` |
| `docs/incident-20261125-phantom-rollback.md` | 控制器（事故记录） | 无 |
| `docs/handoff-ledger-b8-w1.md` | 本棒（写集第 ⑧ 项） | 只有 `docs/handoff-ledger-b7*` |

⇒ **本棒 7 个 `apps/desktop/**` 写集文件全部 `IN_SET`**（已逐条复算）。缺的 4 条模式全在
`reports\task51-gate.ps1` 的 `$patterns`（`:134-353`），该文件按 R1 属控制器台账，worker 不得改。

### 8.3 `PS1_ASCII_VIOLATIONS=4` 明细（全部**非本轮产物**，本轮 `reports\` 只落 `.txt`）

`reports/stage-a-ledger-apply.ps1`、`reports/task72-agents-sec7-backfill.ps1`、
`reports/task72-agents-sec7-backfill2.ps1`、`reports/task72-progress-append-b7closeout.ps1`
（`PS1_MODE=Check`，基线 `reports\task57-ps1-ascii-baseline.txt`）。

### 8.4 处置：**未提交**

派工书 §门禁 明写「仍报 `OUT_OF_SET` 就停下回报」，故本轮到此为止，**零 `git add`、零 commit**。
最小解锁条件（控制器侧，两选一）：
1. 在 `reports\task51-gate.ps1` 的 `$patterns` 追加 `'docs/plan-goals-ui-batch8.md'`、`'docs/b81-*'`、
   `'docs/handoff-ledger-b8*'`、`'docs/incident-*'`（4 行，不改任何判据）；
2. 或把上述 4 个 docs 文件移出本工作区再重跑门禁。

`PS1_ASCII_VIOLATIONS` 需控制器决定：给那 4 个既有 `.ps1` 去非 ASCII，或把它们并入基线（二者都属控制器台账）。
