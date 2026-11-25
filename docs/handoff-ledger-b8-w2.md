# B8-W2 收口台账 · 目标页（月/周/年）行级编辑与删除

- 提交状态：**未提交**（按 R3 由控制器统一 commit；本棒 HEAD 仍为 `fcf1cee`，门禁读数 `AHEAD=9`）
- 环境：Windows / pwsh 7.7.0 / Flutter（进程内设镜像 `pub.flutter-io.cn` + `storage.flutter-io.cn`）
- 编码：UTF-8 无 BOM，纯 LF（本文件 CR 计数见文末自检）

## 0. 一句话结论

月 / 周 / 年三页的**既有**目标行已获得「编辑」「删除」能力，写库全部走既有
`GoalStore.updateGoal` / `GoalStore.deleteGoal`（**未新增任何 store 方法**，D-8-d）；
W1 写在蓝图页的私有表单已抽成 `apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart`
并由蓝图页与三页共用，W1 的 10 个 ValueKey 与既有行键逐字未变；**l10n 新增键数 = 0**。
`flutter analyze` 逐字 `No issues found!`；全量 `+920` 全绿；门禁
`GATE_VERDICT=PASS`、`GATE_FAILURES=0`、`OUT_OF_SET=0`、`DESKTOP_TESTS=920 == DESKTOP_EXPECTED=920`。

## 1. 本棒范围与「不做」清单

### 1.1 本棒范围（派工书 §1.1 A–F，全部落地）

| # | 交付物 | 落点 |
|---|---|---|
| A | 共享编辑表单 | `apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart`（新建）；蓝图页改为复用（行为与外观零变化） |
| B | 月页行级编辑/删除 | `goals_month_page.dart` 表头占位 + 每行 `GoalRowActions` |
| C | 年页行级编辑/删除 | `goals_year_page.dart` 同构 |
| D | 周页行级编辑/删除 | `goal_week_table.dart` 加可选回调 + `goals_week_page.dart` 传入（variant-1） |
| E | 测试 | `test/task74_goal_edit_shared_test.dart`（4 例）+ `test/task74_goal_pages_edit_test.dart`（3 例） |
| F | 台账 | 本文件 |

### 1.2 本棒明确「不做」（照抄派工书 §1.2）

- 不新增「新建目标」入口。新建面唯一保留在 07 蓝图页（D-8-e：由所在格子预填 `domain` + `horizon`）。
- 不改 `packages/**`（R1）。不新增 store 方法（D-8-d）。不直连 DAO / 不写裸 SQL。
- 不改 `l10n/parts/goals.dart`，本棒新增 l10n 键数必须为 0。
- 不动 `goal_week_table.dart` 之外的派生统计口径、不动矩阵归属（D-8-f）。
- 不删任何文件（R4）。不动今日页（那是 W3）。
- 不 `git push`、不打 tag、不动 `docs/relay.json`。

自检：上述六条**全部遵守**。`_addFromMonthly` / `_alreadyServedMonthly` / `saveWeeklyDrafts`
的派生语义未改；今日页零改动；`packages/**` 零改动（门禁 `OUT_OF_SET=0` 与 `STATUS_PATHS` 双证）。

## 2. 实际改动文件清单（逐文件盘上回读，非摘要抄录）

`BYTES` = `(Get-Item).Length`；`LINES` = 按 LF 切分计数；`CR` = 文件中 `\r` 出现次数；
`SHA` = `Get-FileHash -Algorithm SHA256`（大写）。

| 文件 | 字节 | 行 | CR | SHA256（前 16 位） | 新增键 |
|---|---|---|---|---|---|
| `apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart`（新建） | 14,022 | 396 | 0 | `283CE20954F598B0` | 0（保留 W1 的 10 个键） |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 19,153 | 576 | 0 | `B002F58FD7BB4F47` | 0 |
| `apps/desktop/lib/src/pages/goals_month_page.dart` | 26,628 | 778 | 0 | `A4718D6FAED4CA52` | `goal-month-row-edit-${id}` / `goal-month-row-delete-${id}` |
| `apps/desktop/lib/src/pages/goals_year_page.dart` | 22,899 | 697 | 0 | `3289160BB475BFEA` | `goal-year-row-edit-${id}` / `goal-year-row-delete-${id}` |
| `apps/desktop/lib/src/pages/goals_week_page.dart` | 16,633 | 506 | 0 | `A2B8B0BD49BE1DFB` | 0（键在周表内） |
| `apps/desktop/lib/src/widgets/goal_week_table.dart` | 7,887 | 236 | 0 | `2430047348E56EFD` | `goal-week-row-edit-${id}` / `goal-week-row-delete-${id}` |
| `apps/desktop/test/task74_goal_edit_shared_test.dart`（新建） | 10,234 | 305 | 0 | `6F62C5ACAC47AF4C` | — |
| `apps/desktop/test/task74_goal_pages_edit_test.dart`（新建） | 10,031 | 272 | 0 | `D5B3885882A54757` | — |

新增 ValueKey 合计 **6 个**（逐字与派工书 §4.5 一致）；l10n 新增键 **0 个**：
门禁 `STATUS_PATHS` 中不含任何 `l10n/**` 文件，`l10n_base_test.dart` 的 5 处硬编码 523 未动。

## 3. 三页入口实测行号（改后最终行号，`grep` 直读）

### 3.1 共享组件 `widgets/goals/goal_form_dialog.dart`

| 符号 | 行 |
|---|---|
| `class GoalFormResult` | 31 |
| `Future<GoalFormResult?> showGoalFormDialog(...)` | 67 |
| `Future<bool> confirmDeleteGoal(...)` | 86 |
| `class GoalFormDialog` | 109 |
| `class _GoalFormDialogState` | 135 |
| `class GoalRowActions` | 330 |
| `static const double width = 56` | 342 |

### 3.2 蓝图页 `pages/goals_blueprint_page.dart`（抽取后）

| 符号 | 行 |
|---|---|
| `import '../widgets/goals/goal_form_dialog.dart';` | 41 |
| `_openCreateGoal` | 396（`showGoalFormDialog` 调用 401） |
| `_openEditGoal` | 414（调用 417） |
| `_confirmDeleteGoal` | 433（`confirmDeleteGoal` 调用 435） |
| `_writeGoal(GoalRow? existing, GoalFormResult form)` | 460 |

### 3.3 月页 `pages/goals_month_page.dart`

| 符号 | 行 |
|---|---|
| `Future<void> _editGoal(GoalRow goal)` | 339 |
| `Future<void> _deleteGoal(GoalRow goal)` | 353 |
| `Future<void> _updateGoal(GoalRow goal, GoalFormResult form)` | 375 |
| `_keptHorizon` | 413 |
| `_emptyToNull` | 421 |
| 表头操作列占位 `const SizedBox(width: GoalRowActions.width)` | 454 |
| 行尾 `GoalRowActions(` | 514；`editKey` 515、`deleteKey` 516、`onEdit` 517、`onDelete` 518 |

### 3.4 年页 `pages/goals_year_page.dart`

| 符号 | 行 |
|---|---|
| `_editGoal` | 175（`_updateGoal` 调用 185） |
| `_deleteGoal` | 189 |
| `_updateGoal` | 211 |
| 表头操作列占位 | 305 |
| 行尾 `GoalRowActions(` | 366；`editKey` 367、`deleteKey` 368、`onEdit` 369、`onDelete` 370 |

### 3.5 周页 `pages/goals_week_page.dart`

| 符号 | 行 |
|---|---|
| `GoalWeekTable(` | 76；`onEdit: _editGoal` 79、`onDelete: _deleteGoal` 80 |
| `_editGoal` | 205（`_updateGoal` 调用 215） |
| `_deleteGoal` | 219（`ref.invalidate(goalWeekViewProvider)` 231） |
| `_updateGoal` | 241（invalidate 268） |

### 3.6 周表 `widgets/goal_week_table.dart`

| 符号 | 行 |
|---|---|
| 构造参数 `this.onEdit,` / `this.onDelete,` | 30 / 31 |
| 字段 `final void Function(GoalRow goal)? onEdit;` / `onDelete` | 42 / 45 |
| 表头占位（两回调非 null 才渲染） | 86–87 |
| `_WeekRow` 透传 `onEdit` / `onDelete` | 93 / 107–121 |
| 行尾 `GoalRowActions(` | 182–187；`editKey` 184、`deleteKey` 185、`onEdit` 186、`onDelete` 187 |

## 4. 周页路径选定：**variant-1**（给 `goal_week_table.dart` 加 `onEdit` / `onDelete` 回调）

理由（按派工书 §4.4 要求写清）：

1. **不复制渲染逻辑**：variant-2 要让周页自建行级操作，等于把周表的行布局（列序、列宽、
   派生统计显示）在页面里再实现一遍，两处容易漂移，而派工书禁止改列序/列宽语义。
2. **零回归可证**：两个回调是**可选**参数，`onEdit` 与 `onDelete` **同时非 null** 才渲染操作列；
   既有直接构造 `GoalWeekTable(view:..., t:...)` 的测试与调用点保持原样编译、原样渲染。
3. **符合白名单**：`apps/desktop/lib/src/widgets/goal*` 在门禁白名单内，`OUT_OF_SET=0` 已证。

派生语义未碰：`_addFromMonthly`（周页上游月目标区）与 `_alreadyServedMonthly` 零改动。

## 5. 证据链（路径 + 末行原文）

命令统一在 `apps/desktop` 下执行，进程内设镜像；证据文件只收 Flutter 的 stdout，
`EXITCODE` 取自当次终端回显（证据文件内**不含** `EXIT` 字样，已用 `grep` 证）。

| 环节 | 路径 | 字节 | 末行原文 | 当次 EXITCODE |
|---|---|---|---|---|
| analyze | `reports/task74-analyze.txt` | 202 | `No issues found! (ran in 5.8s)` | 0 |
| 共享组件单文件绿 | `reports/task74-shared.txt` | 3,101 | `00:03 +4: All tests passed!` | 0 |
| 三页单文件绿 | `reports/task74-pages.txt` | 3,215 | `00:05 +3: All tests passed!` | 0 |
| 红灯（**注入红**，见 §9） | `reports/task74-red.txt` | 5,601 | `00:05 +2 -1: Some tests failed.` | 1 |
| 合并绿（两文件同跑） | `reports/task74-green.txt` | 4,506 | `00:06 +7: All tests passed!` | 0 |
| 全量绿 | `reports/task74-full.txt` | 252,988 | `01:23 +920: All tests passed!` | 0 |

全量新增数 = 920 − 913（派工书基线）= **+7**，与两条新测试文件的 4 + 3 例一致。

## 6. 门禁 `reports/task51-gate/summary.txt` 关键字段抄录

盘上回读：`1,729 B`，`RUN_AT=2026-11-25 21:12:36`，命令
`pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests 920`。

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
STATUS_LINES=18
HEAD=fcf1cee
AHEAD=9
PS1_ASCII_VIOLATIONS=0
PS1_NEW_NON_ASCII=0
PS1_CHANGED_SAME_FLAG=1
```

判据逐条对账：`GATE_VERDICT=PASS` ✓；`GATE_FAILURES=0` ✓；`OUT_OF_SET=0` ✓；
`PS1_ASCII_VIOLATIONS=0` ✓；`DESKTOP_TESTS == DESKTOP_EXPECTED == 920` ✓；
`CORE_DATA/DB/DOMAIN = 204/96/91` ✓；四包 `ANALYZE=VERBATIM` ✓。

## 7. 与计划正文冲突的事实清单

W1 台账已记三条（`_quickAdd` 三页命中 0 / 年页文件其实存在 / 三页写库其实是 `saveWeeklyDrafts`），
本棒 §2.1 三条与之同源，本轮**再次盘上验证仍成立**：

1. 「月/年页已有 `_quickAdd`」—— 假。三页 `_quickAdd` 命中数 0/0/0；本棒没有「补全 `_quickAdd`」，
   而是新写 `_editGoal` / `_deleteGoal` / `_updateGoal` 三个方法。
2. 「年页文件不存在，需新建」—— 假。`pages/goals_year_page.dart` 存在且本棒直接改它。
3. 「三页已能写目标」—— 假。三页写库原本只有 `saveWeeklyDrafts`（写 `GoalDraft` 派生草稿）；
   本棒才引入真实目标的 `updateGoal` / `deleteGoal` 调用。

另有一处**计划正文未提、本棒实测得出**的硬约束（已并入 §9）：
`GoalRowActions` 的两个 `IconButton` 若不 shrinkWrap 点击区，按 Material 默认 48×48 会把
56 宽的行情撑爆（实测 `RenderFlex overflowed by 40 pixels`），故 `GoalRowActions.build`
外套 `Theme(... materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)`。

## 8. 遗留问题与不确定项

### 已验（盘上/实跑可复查）

- 三页行级编辑可用：改标题后 `store.findGoal(id)!.title` 变，且 `horizon` 仍为 `null`
  （`_keptHorizon` 生效，`updateGoal` 的 null = 不动）。
- 三页行级删除可用：先取消不写库，再确认后 `findGoal(id) == null`、行键消失、回落到各页空态键
  （`goal-month-goals-empty` / `goal-year-goals-empty` / `goals-week-empty`）。
- 共享组件 8 个表单键齐备、空标题保存置灰、取消返回 `null`、编辑预填
  （title/note/keywords/due=`2026-12-31`/domain=`career`/horizon=`mid`）、删除框 false/true 两分支、
  `GoalRowActions.width == 56` 且两回调互相独立。
- W1 的 10 个键名原样保留，W1 测试 `task73_*` 全绿（含在全量 920 内）。
- 全量 920 绿、门禁 PASS、`OUT_OF_SET=0`、四包 analyze VERBATIM。
- CR=0（8 个改动文件 + 本台账均纯 LF）。

### 推断（合理但未单独取证的判断）

- 「+7 = 920 − 913」中 913 取自派工书基线，本轮**未**重跑未改动状态的全量来复核 913；
  但两条新文件 4 + 3 例与全量增量一致，且门禁 `DESKTOP_DELTA=324` 与 `596` 基线自洽。
- 三页操作列的视觉对齐（56 宽、图标 16、按钮 28×28）只经测试与 overflow 报错消失验证，
  **未做像素级/截图验收**；本棒不涉及打包，也无真机界面证据。
- `GoalWeekTable` 新增可选参数对旧调用点零影响，由「旧测试全绿 + 编译通过」推定；
  未逐一枚举所有旧调用点。

### 未验（本棒范围外或无法在本环境验证）

- 未跑 `tauri build`（派工书 §8 明确不做）。
- 未做真实用户数据目录下的手工点测（测试全部用 `openInMemoryActLogDatabase`，不碰活库）。
- 未验证多窗口 / 并发编辑同一目标时的冲突表现（超出 D-8 本棒范围）。

## 9. TDD 时序偏差（必须如实登记）

本轮**实现先于测试落盘**，因此拿不到「先写测试跑红」的**时序红灯**。补偿做法：
在测试已绿后，把月页 `onEdit: () => _editGoal(goal),` **临时改成** `onEdit: () {},`，
重跑 `test/task74_goal_pages_edit_test.dart` ⇒ 月页用例 `[E]`，结果
`00:05 +2 -1: Some tests failed.`、`EXITCODE=1`，存 `reports/task74-red.txt`；
随后逐字节复原该行，复原后 SHA256 = `A4718D6FAED4CA526D9CA1F45191E9BBD399FF3D97F8486C5B181740CAB8DCBC`
（与本次改动面盘点一致），再跑合并绿 `+7` 通过。

⇒ `reports/task74-red.txt` 是**注入红**，不是时序红；判别性成立（删/断实现必红），
但**不满足**派工书 §5 第 1 条的字面时序要求。此偏差由控制器裁决是否需要补跑。

## 10. 本文件自检

- 编码：UTF-8 无 BOM；换行：纯 LF。
- 所有字节数 / 行数 / 行号 / 测试数 / 门禁字段均为本轮盘上回读值（`Get-Item`、`Get-FileHash`、
  `grep`、`read summary.txt`），未从上下文摘要抄录。