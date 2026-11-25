# B9-W2 派工书 · 人生蓝图矩阵四标签页 + 去标题 + 空态「+」+ 右侧铅笔/拆分

> 合同性质：**本文件是本棒唯一实现契约**。与 `docs\plan-goals-ui-batch9.md` 冲突时以本文件为准；与用户当轮原话冲突时以用户原话为准。worker 不得再自行裁决范围。

---

## 0. 合同信息

| 项 | 值 |
|---|---|
| 仓库根 | `F:\soft\00selfmade\practilog` |
| 棒次 | **B9-W2**（B9 共 4 棒，**串行**；本棒在 W1 收口后开工） |
| 设计真源 | `F:\soft\00selfmade\practilog\docs\plan-goals-ui-batch9.md`（W2 段落：§4 行 132–170；l10n 预算：§5.2 行 272–276；契约变更表：§6 行 288–304） |
| 项目规范 | `F:\soft\00selfmade\practilog\AGENTS.md`（**动手前必读**：R1 写集纪律 / R2 门禁 / R5 证据 / §5 坑 51、97、108） |
| 起点 | W1 提交（品牌面板）已入库；HEAD = `c11e17d` + W1 commit |
| 基线测试数 | `<<DESKTOP_BASE_AFTER_W1>>`（控制器在派工时回填；本棒结束 = 该数 + N2，`N2 ≥ 8`） |

---

## 1. 用户当轮原话（本棒逐条落地，**不得改写语义**）

> 人生蓝图矩阵，去除标题“人生蓝图矩阵”，把下面的内容区分为4个标签页，分别显示 终极、远期、中期、短期，内容保持和当前一致。在没有填入内容时，不要显示“(空)”，在单元格右下角显示“+”按钮，可以添加单元格内新的内容。已经添加的内容，在右侧显示小铅笔按钮，点击可以对目标进行编辑；显示一个代表拆分的按钮。

> **W1 基线（控制器回填）**：`<<DESKTOP_BASE_AFTER_W1>>` = W1 收口后的 desktop 全量测试数。

---

## 2. 写集（**你独占**，表外任何文件一律不得改）

| 文件 | 动作 |
|---|---|
| `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 改：标签页 / 去段头 / 空态「+」 / 右侧铅笔+拆分 |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 改：矩阵块**去掉段头**（其它块不动） |
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 改：**+3 −4**（见 §4） |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 改：+3 常量 + 3 条 `byGetter`；**−4** 常量与映射条目 |
| `apps/desktop/test/l10n_harness.dart` | 改：随键数同步（−4 访问器） |
| `apps/desktop/test/l10n_base_test.dart` | 改：**5 处计数 576→575 / 633→632** |
| `apps/desktop/test/task66_goals_blueprint_page_test.dart` | 改：标签页 / 空态 / 铅笔 / 拆分 断言 |
| `apps/desktop/test/task73_b8_w1_blueprint_edit_test.dart` | 改：**先切标签页再断言** |

**禁改**：`packages/**`（任何文件）、`data/goal_store.dart`、`providers.dart`、`widgets/goal_brand_panel.dart`（W1 的文件）、`widgets/goals/goal_split_dialog.dart`（W3 的文件）、`reports/**`（不得 `git add reports/`）、`reports/task51-gate.ps1`。

> ⚠️ `goals_blueprint_page.dart` 是**共享文件**：W1 已在矩阵块**上方**插入「个人品牌管理」面板块。**不得删除、重排或改写该品牌块**；你只动矩阵块相关代码。

---

## 3. 实现契约

### 3.1 四标签页（终极 / 远期 / 中期 / 短期）

- 4 个标签，顺序 = 终极 → 远期 → 中期 → 短期，对应 `GoalHorizon.ultimate / long / mid / short`。
- 默认选中 **终极**（`ultimate`）。
- 标签按钮 ValueKey：`goal-blueprint-tab-<horizonKey>`，`horizonKey` 取值 `ultimate` / `long` / `mid` / `short`（沿用现有 `_horizonKey` 口径）。
- 标签文案**复用既有** `goalBlueprintHorizonUltimate / Long / Mid / Short`，不新增文案键。
- **只渲染当前选中档位的那一张表**（6 行 × [领域 | 单元格]）；切档位 ⇒ 另一档位的内容**不渲染**（测试要断言 `findsNothing`）。
- 行标签 ValueKey `goal-blueprint-row-<domain>` **逐字保留**（6 个领域行都在，只是格子内容随档位变化）。

### 3.2 短期标签页 = 短期列 + 近期列（D-9-b，控制器裁决）

「内容保持和当前一致」的落地口径：

- 短期 tab 的每一格显示 = **原「短期」列内容 + 原「近期（1 年）」列内容**，两段合并进同一格。
  - 原「短期」列 = `horizon == GoalHorizon.short` 的蓝图目标；
  - 原「近期（1 年）」列 = `horizon == GoalHorizon.near` 的蓝图目标 **+** 本年度 `kind == GoalKind.yearly` 的年目标（蓝图页 `_load()` 现已在 `horizon == near` 时并入 `view.yearlyGoals`）。
- 原「近期（1 年）」**列**本身不再单独出现（列头也没了），其内容并入短期 tab；用新增键 `goalBlueprintShortTabNote` 在短期 tab 上方一行小字明示来源：「短期页含『近期（1 年）』：1 年蓝图目标与本年度年目标。」
- **年目标保留现状渲染，但不给铅笔 / 不给拆分**（D-9-c）：年目标是年页的镜像，改它的 `horizon` 会写坏数据。
- **所有蓝图目标（任何档位，含 near）都有铅笔 + 拆分**。
- 短期 tab 内的「+」按钮 = `goal-blueprint-add-<domain>-short`，新建的是 `horizon=short` 的蓝图目标（**不提供 near 新建入口**，因为已无 near 标签页）。
  - ⇒ 既有 `goal-blueprint-add-<domain>-near` key **随近期列合并而消失**，这是本棒唯一一处未列在 §6 表里的契约变更，**必须在台账登记**（依据 D-9-b）。

### 3.3 去标题（D-9-h）

- 矩阵卡片**不再渲染**「人生蓝图矩阵」段头。
- l10n 键 `goalBlueprintMatrixSection` **一并删除**（不留死键）。
- 既有段头 ValueKey `goal-blueprint-matrix-section` 随之消失，测试断言 `findsNothing`。

### 3.4 空单元格 = 右下角「+」（不再显示「(空)」）

- **不再渲染**「（空）」文本；`goalBlueprintEmptyCell` l10n 键删除；`goal-blueprint-empty-cell` ValueKey 消失。
- 改为单元格**右下角**一个 **28×28** 紧凑「+」按钮：
  - ValueKey **沿用** `goal-blueprint-add-<domain>-<horizonKey>`；
  - 标签从「+ 新建目标」改为「+」（新键 `goalBlueprintAddSymbol`：「+」/ '+'）；
  - 点击行为沿用 B8-W1 既有逻辑：**预填 domain + horizon**，走既有新建目标路径。
- 该「+」与右侧图标按钮**同一 28×28 紧凑口径**（`IconButton` + `constraints` + `padding` 收紧）。

### 3.5 已添加内容右侧按钮（铅笔 + 拆分）

- 铅笔：ValueKey `goal-blueprint-edit-<id>`（**沿用既有 key**，由文字按钮升级为右侧紧凑图标按钮）
  - 图标 `Icons.edit_outlined`，`iconSize: 16`，**28×28**、`shrinkWrap` —— 与既有 `GoalRowActions`（`apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart`）**同口径**。
- 拆分：ValueKey `goal-blueprint-split-<id>`（**沿用既有 key**，由文字按钮「拆成 3 条待办」升级为右侧紧凑图标按钮）
  - 图标 `Icons.call_split`；tooltip 用新键 `goalBlueprintSplit`（「拆分」/ 'Split'）。
- 删除：ValueKey `goal-blueprint-delete-<id>` **保留**（二次确认流程不动）。
- 三个按钮**只对 `kind == GoalKind.blueprint` 的卡片出现**（D-9-c）；年目标卡片不出现铅笔 / 拆分（删除按钮口径沿用既有实现，不在本棒扩大范围）。
- **本棒拆分按钮仍调用既有 `onSplitTodos` 回调**（行为不空转）；W3 才换成新拆分对话框。

### 3.6 ValueKey 契约（唯一允许变更的清单）

| Key | 本棒处置 |
|---|---|
| `goal-blueprint-empty-cell` | **消失**（不再渲染「(空)」） |
| `goal-blueprint-matrix-section` | **消失**（去标题） |
| `goal-blueprint-add-<domain>-near` | **消失**（近期列并入短期 tab，无 near 新建入口） |
| `goal-blueprint-add-<domain>-<horizon>` | **保留 key**，位置改到单元格右下角，标签改「+」 |
| `goal-blueprint-edit-<id>` | **保留 key**，文字按钮 → 右侧铅笔图标 |
| `goal-blueprint-split-<id>` | **保留 key**，文字按钮 → 右侧拆分图标 |
| `goal-blueprint-delete-<id>` | **保留**（二次确认不动） |
| `goal-blueprint-cell-<id>` / `-row-<domain>` / `-unplaced-<id>` / `-child-<id>` | **保留**（切档位后仅当前档可见） |
| `goal-blueprint-form-*` / `goal-blueprint-delete-confirm` / `-cancel` | **保留**（共享表单，不改名） |
| `goal-blueprint-tab-<horizonKey>` | **新增** |
| `goal-brand-*`（W1 全部） | **保留**，不得改动 |

---

## 4. l10n 契约（+3 −4，**五处同步**）

**新增 3**：
- `goalBlueprintAddSymbol` —— 「+」/ '+'
- `goalBlueprintSplit` —— 「拆分」/ 'Split'（图标 tooltip）
- `goalBlueprintShortTabNote` —— 「短期页含『近期（1 年）』：1 年蓝图目标与本年度年目标。」/ 'The short tab also carries near-term (1 year) goals and this year's yearly goals.'

**删除 4**：
- `goalBlueprintMatrixSection`（去标题）
- `goalBlueprintEmptyCell`（不再显示「(空)」）
- `goalBlueprintNearSource`（原「近期列＝…」口径失效）
- `goalBlueprintSplitTodos`（旧「拆成 3 条待办」文字按钮下线）

**五处同步点**：`l10n_keys.dart` 常量 + `l10n_keys.dart` `byGetter` + `l10n/parts/goals.dart`（abstract + zh + en） + `test/l10n_harness.dart` 访问器 + `test/l10n_base_test.dart` **5 处计数 576→**575** / 633→**632**。

**计数自洽**：`byGetter == accessors == 575`；`总数 == 575 + 4 + 53 == 632`。**不得留半成品键**（只加常量不加 getter / 只加 zh 不加 en）。

---

## 5. 既有测试改写要求（**改强，不得改弱或删例**）

`apps/desktop/test/task66_goals_blueprint_page_test.dart`、`apps/desktop/test/task73_b8_w1_blueprint_edit_test.dart`：

- 原来依赖「全档位同屏可见」的断言，改为**先切到对应标签页再断言**；每文件 **≥ 3 例**改写。
- 强断言清单（W2 收口必须全部满足）：
  1. 「（空）」文案与 `goal-blueprint-empty-cell` 在 `apps/desktop/lib` 内 **0 命中**；
  2. 4 个标签按钮存在，**切换后只渲染对应档位**（终极档的目标在切到「远期」后 `findsNothing`）；
  3. 空格子**只有**右下角「+」按钮，**无**「(空)」文本；
  4. 蓝图卡片右侧**同时存在**铅笔键与拆分键（`find.byKey` / `find.byIcon(Icons.edit_outlined)` / `find.byIcon(Icons.call_split)`）；
  5. `goal-blueprint-matrix-section` 段头 `findsNothing`；
  6. 短期 tab 内**同时**出现 short 蓝图目标、near 蓝图目标与本年度年目标。

> 断言只走 ValueKey / `find.byIcon`；**禁字形级断言**（Flutter 桌面测试不预载 MaterialIcons 字体，坑 51）。

---

## 6. 门禁（必跑，全绿才算完成）

```powershell
# ① 跑之前挪走测试缓存（改名不删，否则 OS Error 183 挂死）
Move-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' `
          'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build_stale_<yyyyMMdd-HHmmss>'

# ② 镜像（同进程内）
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'

& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze            # 期望逐字：No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact   # 期望末行：+N: All tests passed!
```

**硬判据**：

| 项 | 期望 |
|---|---|
| analyze | **逐字** `No issues found!` |
| 全量测试 | 精确 = `<<DESKTOP_BASE_AFTER_W1>>` + N2（N2 ≥ 8） |
| l10n 计数 | `byGetter = accessors = 575`；`总数 = 632` |
| 强断言 | §5 的 6 条全部满足 |
| 代码卫生 | 零 `print(`；Dart 源 LF、无 BOM |

> `goal_blueprint_matrix.dart` 文件头原注释声明「本模块不使用 Material 图标（`Icons.`）」—— 本棒引入了 `Icons.edit_outlined` / `Icons.call_split`，**该注释必须同步更新**（否则注释与实现矛盾）。

---

## 7. 证据纪律（R5）

- TDD：先改/写测试 ⇒ **真红**（失败原因是断言）⇒ 改产品 ⇒ 绿。红/绿日志落 `reports\task78-red.txt` / `reports\task78-green.txt`（reports 被 gitignore，**不得 `git add reports/`**）。
- 「搜 X 得 0 命中」**不能**当「X 已消失」的证明：**「(空)」消失**必须同时给出「宿主不再渲染它」的断言证据（空格子只剩「+」按钮）。
- 轮询日志用共享读打开（`[IO.File]::Open($p,'Open','Read','ReadWrite')`），别用独占读。
- 一切路径用绝对路径；不 `Set-Location` 后写相对路径文件；删文件一律 `Move-Item` 改名留档。

---

## 8. 提交纪律

- 只 `git add <逐个文件>`（禁止 `git add .` / `-A`），提交信息 `feat(goals): B9 W2 blueprint matrix tabs and cell affordances`，**不 push**，不 stash / 不用 `git add -p` / 不用 `git restore` / 不用 `git commit --only`。

---

## 9. 交付报告（≤ 30 行）

1. 改了哪些文件（新增/修改 + 行数变化）。
2. `flutter analyze` **逐字**输出行。
3. `flutter test` 末行 + `N`；`N2 = N - <<DESKTOP_BASE_AFTER_W1>>`；改写的既有用例数。
4. l10n 回读三数（byGetter / accessors / 总数）。
5. §5 的 6 条强断言逐条给证据位置（测试名 + 行号）。
6. **ValueKey 契约变更表**的实际落地（含 `goal-blueprint-add-<domain>-near` 消失的登记）。
7. commit sha16 + 提交文件清单。
8. 未完成 / 未验证 / 已知偏差（没有就写「无」）。
9. 留给 W3 的事实：拆分按钮现在挂在哪个回调上（函数名 + 行号）、蓝图页里 `_pending` / `_addSplit` / `_confirmTodos` 的现状行号。
