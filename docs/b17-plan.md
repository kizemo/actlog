# B17 批次计划（用户 2026-11-27 下午第二轮验收反馈 · 七项改动）

> 状态：**执行中**。控制器 = 本会话（`mvs_90fe171f56d74a8c950ad6cab4261ef3`）；实现全部由 worker 子会话落盘（AGENTS.md R1：控制器零改 `apps\**` / `packages\**`）。
> 本批**不使用**接力链装置（用户未下达「启动接力链」指令），改为控制器直派 worker，分三波共 7 棒，写集纪律与 R1 一致。
> 上游：B16 已收口并提交（台账 `docs\handoff-ledger-b9-w4.md` §11.26），全量绿测 `+1061`，新包 `release\actlog-Setup-1.0.0_20261127-131242.exe` 已静默装机（构建树 `app.so` sha16 `F100F1E80E53D9AF`、`PAYLOAD_MATCH=True` / `DB_UNCHANGED=True`）。

## 0. 背景

用户 2026-11-27 下午完成 B16 观感肉眼验收，结论为**通过 4 条 + 修改 6 条**：

- **通过（不得回退）**：① 蓝图格右侧「+」就地建目标、保存后「+」常驻可换行续加；③ 日期格无多余年份行、日期单行不换行、点日期直接弹选择器；④ 三处「滚动候选」段头卡已消失；⑥ 左侧导航 8 项序位本身。
- **修改（本批范围）**：② 页签左右 padding / 页签之间边距 / 激活与非激活等高；③ 残留的多余「日期」按钮要去除；⑤ 年目标行仍无法添加与编辑；月目标页去「上月复盘」「年度目标汇总」；年目标页去「月度展开」「年度复盘」「80/20 视角」；三页目标编辑时可选类别（5 预设 + 自定义）、带起止日期字段（点击录入）、数据行右侧可点击的完成单选按钮、同类别自动分区（分类作小标题）；⑥ 导航去除「习惯」、「学习」改「学习管理」。
- **待肉眼验**：窗口拖到 760 宽 + 切英文，页签文字不换行、不压线。**只有新包才看得到** ⇒ 本批必须出包 + 静默装机。

## 1. 唯一真源与优先级

1. 用户当轮决定（含本节 §0 的原文压缩）
2. 本文件（派工口径）
3. `AGENTS.md` §2 铁律 R1–R8、§7 当前状态快照、§7.1 设计标准
4. 台账 `docs\handoff-ledger-b9-w4.md` §11.26（B16 收口实测值）
5. 盘上源码实况（本文件 §3 的行号均为控制器盘上回读值）

冲突裁决：证据优先级 实测 > 运行时产物 > 源码 > 文档转述。

## 2. 工作队列（七项）

| # | 用户原话（压缩） | 验收要点 |
|---|---|---|
| A | 页签**再**适当增加左右 padding、不同页签之间适当增加边距、**保持激活与非激活页签高度一致** | `_tabPadding` 10→16；新增页签间距 `tabGap = 8`；取消双高度，单一 `tabHeight = 46`（两态同高，取消 7px 落差）；1px hairline 仍居中于间距内 |
| B | 还保留了多余的**「日期」按钮**，需要去除 | 删 `_compactButton(key: goal-blueprint-period-<id>)` 图标按钮；保留 `goal-blueprint-period-tap-<id>` 整格点击 + 外层 `Tooltip` |
| C | **年目标行仍无法添加、编辑** | 年页出现可点的「+」新增入口；行右侧编辑按钮能打开表单并落库；W4 必须先盘上复现并写明根因 |
| D | 月目标选项卡：去「上月复盘」「年度目标汇总」 | 删年度汇总条 + `goalMonthReviewSection` 卡；保留本月目标 |
| E | 年目标选项卡：去「月度展开」「年度复盘」「80/20 视角」 | 只留表一（`goalYearGoalsSection`）；删 `goalYearMonthsSection` / `goalYearReviewSection` / `goalYear8020Section` |
| F | 三页目标编辑时可选**类别**（财务目标/家庭生活/学习成长/人际关系/健康休闲 + 自定义）、带**起止日期**字段（点击录入）、数据行右侧**完成单选按钮**、**同类别自动分区**（分类作小标题） | 表单弹窗增类别选择 + 自定义输入 + 起止日期行；`GoalRowActions` 增可选完成单选；三页列表按类别分区渲染，未分类落「未分类」标题 |
| G | 导航**去除「习惯」**、「学习」改「**学习管理**」 | 7 项：01 日志 / 02 待办 / 03 蓝图 / 04 目标 / 05 项目 / 06 学习管理 / 07 日历；快捷键 `Ctrl+1…7` 重排 |

### 2.1 控制器裁决（用户未点名处，按项目纪律定案，不外抛）

1. **F 的类别复用既有 `Goal.domain`，不新增列、无 DB 迁移**。盘上 `packages\core_domain\lib\src\goal.dart` 的 `Goal` 已有 `domain`(String?)、`periodStart`(非空,默认 0)、`periodEnd`(int?)、`status`(`GoalStatus`，含 `isDone`)；`apps\desktop\lib\src\data\goal_store.dart` 的 `updateGoal(...)` 签名已含 `GoalStatus? status`（L502 附近）。⇒ 类别、起止、完成三项**全部落在既有列**。
2. **类别映射表（唯一口径）**：财务目标→`wealth`、家庭生活→`family`、学习成长→`learning`、人际关系→`social`、健康休闲→`health`；自定义存 `custom:<文本>` 前缀；空值 / 未知 key / 空自定义 → 显示「未分类」。**不得**复用 `projectDomainLabel`（措辞是项目域的，语义不同），页面层用新 helper 出中文/英文标签。
3. **D / E 只下线 UI 入口，保留 l10n getter 与数据层**；既有断言一律改为 `findsNothing`，**不删用例**（保留用例计数、留下「已下线」证据）。
4. **A 的宽度预算必须先腾出，再谈加宽**：760 窗英文态真页面可用宽度仅 15.0px（实测量化见 §3.4），纯加 padding 最多 +1px/边 ⇒ **必须先缩短 4 条英文页签文案**（由 W0 独占 l10n 落盘），把 en 的 `natural` 从 912.5 降到 ≤ 600，之后 W3 才能把 `_tabPadding` 加到 16 并加 8px 间距。
5. **英文页签新文案（仅 en，zh 一字不改）**：`Short-term` / `Mid-term` / `Long-term` / `Ultimate`。不用单词 `Short`/`Mid`/`Long`（丢语义），也不用 `→ Goal` 后缀（多 30px 无收益）。span 类文案（弹窗标题、tooltip）**不动**。
6. **F 的完成单选做成可选回调**：`GoalRowActions` 新增 `onToggleDone`（可空）。**为 null 时不渲染单选、且 `width` 必须仍为 56** —— 因为 `goal_blueprint_matrix.dart:1088` 也用它，且 B16 其 `width = 56` + `shrinkWrap` 是蓝图矩阵布局的前提。蓝图矩阵**不在本批 F 的范围**（用户说的是「三个选项卡」= 周/月/年）。
7. **新增 l10n 数量以盘上实测为准**：先查重再新增，撞值优先改 en 措辞、zh 保持用户原词。W0 回板必须报「新增 getter 名 → 语义」表 + 新的三处计数值。
8. **G 只改导航清单与快捷键表**：`habits` 页面/路由**保留**（不删文件、不删路由），只从 `kShellNavItems` / `shellNavItemsFor` / 快捷键表中移除；`shellNavLearning` 的**值**改「学习管理」/「Learning Management」，可用/占位状态**保持不变**（用户未要求）。
9. **C 的根因由 W4 盘上核实后再修**，不得凭猜测改；回板必须写明「根因：文件:行 → 为何无法添加/编辑」。
10. **所有新 API 必须向后兼容**：W2 新增的 `GoalFormResult` 字段一律可选带默认值、`showGoalFormDialog` 新参数一律可选 ⇒ W2 回板时 `flutter analyze` 必须逐字 `No issues found!`，否则第三波无法开工。

## 3. 侦察实测映射（文件 : 行号，行号为控制器盘上回读值）

### 3.1 页签与日期格（A / B）

| 文件 | 关键行 | 关键符号 / key |
|---|---|---|
| `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 169–232 | `tabActiveHeight=46`、`tabInactiveHeight=39`、`tabVerticalPadding=4`、`tabInactiveLift=6`、`_tabPadding=10`、`tabIndicatorHeight=3`、`chromeTabTopRadius=8` |
| 同上 | 551 | `_tabStrip`：`FittedBox(scaleDown)`、`padding: EdgeInsets.only(left: 0)`、页签之间插 1px hairline |
| 同上 | 594 | `_tab` |
| 同上 | 954–1033 | 日期格双入口：①`InkWell(key: goal-blueprint-period-tap-<id>)` ②`_compactButton(key: goal-blueprint-period-<id>, Icon(Icons.date_range_outlined), tooltip: t.goalBlueprintPeriodTitle)` ⇒ **B 删 ②** |
| 同上 | 1057 / 1089 | `_actions` / `_compactButton` |
| 同上 | 1088 | `GoalRowActions(...)` —— F 的 `onToggleDone` 必须可空且不传 |

### 3.2 三页区块（D / E / C / F）

| 文件 | 关键行 | 关键符号 / key |
|---|---|---|
| `apps/desktop/lib/src/pages/goals_month_page.dart` | 221 | `_buildLeft`：年度汇总条（`goal-month-year-bar-empty`，L228–264）→ `_GoalCard(title: t.goalMonthReviewSection)`（`goal-month-review-empty`，L265–290）→ `_GoalCard(title: t.goalMonthGoalsSection)`（L291+）⇒ **D 删前两块** |
| 同上 | 321–375 / 606 / 631–686 | 录入行 / `_buildMonthGoals` / `GoalRowActions` 三处 |
| `apps/desktop/lib/src/pages/goals_year_page.dart` | 116–151 | 四区块：`goalYearGoalsSection`（表一）/ `goalYearMonthsSection` / `goalYearReviewSection` / `goalYear8020Section` ⇒ **E 删后三块** |
| 同上 | 178 / 264 / 269 / 305–367 / 380 / 417 | `showGoalFormDialog` / `_buildTableOne` / `goal-year-goals-empty` / `GoalRowActions` / `_buildReview` / `_build8020` |
| `apps/desktop/lib/src/pages/goals_week_page.dart` | 389 / 494 | `showGoalFormDialog` / `_GoalCard` |
| `apps/desktop/lib/src/widgets/goal_week_table.dart` | 114 / 116 / 247 | `GoalRowActions` 三处（周页行渲染在共享表里） |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 439 / 619 | `showGoalFormDialog` / `showGoalPeriodDialog`（**不改**） |

### 3.3 表单与行控件（F）

| 文件 | 关键行 | 关键符号 |
|---|---|---|
| `apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart` | 75 / 436 | `showGoalFormDialog` / `GoalRowActions`（`width = 56`） |
| 同上 | — | `GoalFormResult` = title / note / keywords / domain / horizon / dueDate（**无 period**，需扩） |
| `apps/desktop/lib/src/widgets/goal_period_dialog.dart` | 39 | `showGoalPeriodDialog`（起止一体，F 的起止日期行直接复用） |
| `apps/desktop/lib/src/data/goal_store.dart` | 158 / 502 / 1224 | `isDone` / `updateGoal(... GoalStatus? status)` / `_statusOf` |
| `packages/core_domain/lib/src/goal.dart` | — | `Goal` / `GoalField` / `GoalStatus` / `domain` / `periodStart` / `periodEnd` |

### 3.4 760 英文态实测量化（B16 已测，红线不改）

| 组 | natural | scale | display(px) | margin |
|---|---|---|---|---|
| `zh-760` | 323.6 | 1.000000 | 15.00 | 4.0000 |
| `en-760` | 912.5 | 0.832877 | 12.49 | 1.4932 |
| `page-760-en`（真页面） | 912.5 | 0.813151 | 12.20 | **1.1973** |

- 单页签自然宽：short=226.5 / mid=196.3 / long=211.4 / ultimate=196.3；`natural − 文本宽 = 82` ≈ 4×2×10 内边距 + 2 条 1px 分隔。
- 760 窗可用宽度预算仅 **15.0px**（`natural` 上限 = 742 ÷ 0.80 = 927.5）⇒ 纯加 padding 不可行，必须先缩文案。
- 红线**不放宽**：`_redLineFontPx = 11.0`、`_requiredMarginPx = 1.00`（显示字号 ≥ 12.00px）。

### 3.5 l10n 与导航（F / G）

| 文件 | 关键行 | 关键符号 |
|---|---|---|
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 22 / 615 / 1230 / 830–854 / 1449–1473 | `GoalsL10n` / `GoalsZhL10n` / `GoalsEnL10n` / zh 页签文案 / en 页签文案；555 个 `String get` |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | — | kebab-case 键表，新增 getter 必须登记 `byGetter` |
| `apps/desktop/test/l10n_harness.dart` / `l10n_base_test.dart` | L28 / L29 / L108 | `l10nAccessors`；计数 `613` / `613` / `'全部键值不重复（613 + 6 + 53 = 672）'`（**盘上回读确认后再改**） |
| `apps/desktop/lib/src/widgets/shell/nav_rail.dart` | 45–53 / 62–71 | `kShellNavItems`（today/inbox/**habits**/blueprint/goals/projects/**learning**/calendar）/ `shellNavItemsFor(t)` |
| `apps/desktop/lib/src/app.dart` | 263 / 368 / 402 | `'learning'` 深链 / `_LearningPlaceholder` 路由 / 类定义 |
| `apps/desktop/lib/src/widgets/shell/key_bar.dart` | — | `Ctrl+1…8` 快捷键 |
| `apps/desktop/lib/src/l10n/parts/shell.dart` | — | `shellNavHabits` / `shellNavLearning`（只改后者**值**） |

## 4. 写集表（R1 硬约束：worker 只能写自己那一行；控制器只写计划 / 门禁脚本 / `AGENTS.md` / 台账）

### 波 A（并行 2 棒）

| 行 | worker | 独占写集 | 交付判据 |
|---|---|---|---|
| **W0** | `b17-w0-l10n-category` | `apps/desktop/lib/src/l10n/parts/goals.dart`、`apps/desktop/lib/src/l10n/l10n_keys.dart`、`apps/desktop/test/l10n_harness.dart`、`apps/desktop/test/l10n_base_test.dart`、新建 `apps/desktop/lib/src/widgets/goals/goal_category.dart`、新建 `apps/desktop/test/b17_goal_category_test.dart` | ① 4 条 en 页签值缩短为 `Short-term` / `Mid-term` / `Long-term` / `Ultimate`（zh 一字不改）；② 新增类别 / 表单字段 / 行控件所需 l10n（先查重再新增，撞值优先改 en），三处计数同步、`l10n_base_test.dart` 全绿；③ `goal_category.dart` 提供类别目录 + `Goal → 类别 key` + `类别 key → 标签` + 按类别分组；④ `b17_goal_category_test.dart` 断言 `wealth/family/learning/social/health/custom:<文本>/空→未分类/未知 key→未分类`；⑤ `flutter analyze` 逐字 `No issues found!` |
| **W1** | `b17-w1-nav` | `apps/desktop/lib/src/widgets/shell/nav_rail.dart`、`apps/desktop/lib/src/app.dart`、`apps/desktop/lib/src/widgets/shell/key_bar.dart`、`apps/desktop/lib/src/l10n/parts/shell.dart`、`apps/desktop/test/task64_nav_gear_test.dart`、`apps/desktop/test/nav_rail_footnote_test.dart`、`apps/desktop/test/shell_key_hints_test.dart`、`apps/desktop/test/b16_nav_learning_test.dart`、新建 `apps/desktop/test/b17_nav_seven_test.dart` | ① 导航逐字 7 项：01 日志 / 02 待办 / 03 蓝图 / 04 目标 / 05 项目 / 06 学习管理 / 07 日历；② `shellNavLearning` 值为「学习管理」（en `Learning Management`），可用/占位状态不变；③ `Ctrl+1…7` 重排且与序位一致；④ `habits` 路由与页面**保留**，只从清单与快捷键表移除；⑤ 5 个测试文件全绿；⑥ `flutter analyze` 逐字 `No issues found!` |

### 波 B（串行 1 棒，依赖 W0）

| 行 | worker | 独占写集 | 交付判据 |
|---|---|---|---|
| **W2** | `b17-w2-goal-form` | `apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart`、`apps/desktop/lib/src/widgets/goal_period_dialog.dart`、新建 `apps/desktop/lib/src/widgets/goals/goal_section.dart`、`apps/desktop/test/task74_goal_edit_shared_test.dart`、`apps/desktop/test/b10_position_panel_test.dart`、`apps/desktop/test/b11_period_date_test.dart`、新建 `apps/desktop/test/b17_goal_form_test.dart` | ① 表单增「目标类别」选择（5 预设 + 自定义 + 不设类别）+ 自定义输入 + 「起止日期」行（点击即开 `showGoalPeriodDialog` 回填，显示已选区间或「未设置日期」）；② `GoalFormResult` 扩 `category` / `periodStart` / `periodEnd`，**全部可选带默认值**；`showGoalFormDialog` 新参数全部可选 ⇒ 三页不改也编译；③ `GoalRowActions` 增可空 `onToggleDone` + 单选视觉（选中=已完成）；**为 null 时不渲染且 `width` 仍为 56**；④ 新建 `goal_section.dart` 提供「按类别分区 + 分类小标题」的共享渲染件（三页共用，避免各写一套）；⑤ 4 个测试文件全绿；⑥ `flutter analyze` **逐字** `No issues found!` |

### 波 C（并行 4 棒，依赖 W0 + W2）

| 行 | worker | 独占写集 | 交付判据 |
|---|---|---|---|
| **W3** | `b17-w3-tabs` | `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart`、`apps/desktop/test/b14_tab_scale_test.dart`、`apps/desktop/test/b13_polish_test.dart`、`apps/desktop/test/b12_matrix_tabs_date_test.dart`、`apps/desktop/test/b10_blueprint_matrix_done_test.dart`、新建 `apps/desktop/test/b17_tab_layout_test.dart` | ① A：`_tabPadding` 10→16、新增 `tabGap = 8`、单一 `tabHeight`（两态同高）、hairline 居中于间距；② B：删 `goal-blueprint-period-<id>` 图标按钮，`goal-blueprint-period-tap-<id>` 与外层 `Tooltip` 保留；③ `b14_tab_scale_test.dart` 复跑：**红线不放宽**，`page-760-en` 实测 display ≥ 12.00px 且 margin ≥ 1.00，并把实测数字写进回报；④ 新建测试断言「两态高度相等 / 页签左右 padding=16 / 相邻页签间距=8」；⑤ 5 个测试文件全绿；⑥ `flutter analyze` 逐字 `No issues found!` |
| **W4** | `b17-w4-year` | `apps/desktop/lib/src/pages/goals_year_page.dart`、`apps/desktop/test/task66_goals_year_page_test.dart`、新建 `apps/desktop/test/b17_year_page_test.dart` | ① C：年页可**新增**（有可点「+」入口）与**编辑**（行右侧编辑按钮开表单并落库），根因写明「文件:行 → 为何失效」；② E：删「月度展开」「年度复盘」「80/20 视角」三块，只留表一，既有断言改 `findsNothing`；③ F：行接类别分区 + 完成单选（默认按类别分区，未分类落标题）；④ 测试全绿；⑤ `flutter analyze` 逐字 `No issues found!` |
| **W5** | `b17-w5-month` | `apps/desktop/lib/src/pages/goals_month_page.dart`、`apps/desktop/test/task66_goals_month_page_test.dart`、新建 `apps/desktop/test/b17_month_page_test.dart` | ① D：删年度汇总条 + 「上月复盘」卡，保留本月目标；既有断言改 `findsNothing`；② F：行接类别分区 + 完成单选 + 表单新字段透传；③ 测试全绿；④ `flutter analyze` 逐字 `No issues found!` |
| **W6** | `b17-w6-week` | `apps/desktop/lib/src/pages/goals_week_page.dart`、`apps/desktop/lib/src/widgets/goal_week_table.dart`、`apps/desktop/test/task65_goals_week_test.dart`、新建 `apps/desktop/test/b17_week_page_test.dart` | ① F：周页行接类别分区 + 完成单选 + 表单新字段透传；② **不得**回退 B16 的录入行 / `DragTarget('goal-week-drop-target')` / 上游目标拖入语义；③ 测试全绿；④ `flutter analyze` 逐字 `No issues found!` |

### 写集冲突硬规则

1. **波 A 两行文件零交集**（W0 只碰 `l10n/parts/goals.dart` + 键表 + 两个 l10n 测试 + 新建 `widgets/goals/goal_category.dart`；W1 只碰导航五件 + 五个导航测试）。`l10n/parts/shell.dart` **只有 W1** 能写；`l10n_keys.dart` / `l10n_harness.dart` / `l10n_base_test.dart` **只有 W0** 能写。
2. **波 B 必须在 W0 回板后派发**（`goal_category.dart` 的 API 与新增 getter 名以 W0 落盘为准，W2 只读引用，不得改 W0 的写集）。
3. **波 C 必须在 W2 回板后派发**（表单 API 与分区渲染件以 W2 落盘为准）。
4. `goal_form_dialog.dart` / `goal_period_dialog.dart` / `goal_section.dart` **只有 W2** 能写；波 C 四棒**只许读、不许写**。
5. `apps/desktop/test/b14_tab_scale_test.dart` **只有 W3** 能改（红线判据在其写集内）；其余棒只许**复跑**，不许改。
6. `goal_week_table.dart` **只有 W6** 能写；`goal_blueprint_matrix.dart` **只有 W3** 能写。
7. 任何 worker 发现要写自己写集外的文件 ⇒ **停下来报控制器**，由控制器在本表追加一行并留档（先例 `reports\task112-writeset-amendment.md`、`reports\task113-writeset-amendment-w4.md`）。
8. worker **不得**跑全量 `flutter test`、`flutter build`、门禁、`tools\build\make_installer.ps1`、`release\` 下任何写操作；这些只由控制器做。

## 5. 必然变红的既有断言（worker 必须同步改断言，**改断言不删测试**）

| 断言位置 | 内容 | 为什么红 | 处置 |
|---|---|---|---|
| `l10n_base_test.dart` L28/L29/L108 | 计数 `613` / `613` / `672` | W0 新增 getter | 按盘上实测新值同步三处 |
| `b13_polish_test.dart:365–382` | 页签 `padding == symmetric(horizontal: 10)` | A 改 padding 16 | 同步新值 |
| `b13_polish_test.dart:413–427` | `minimumSize` 46 / 39 双高度 | A 取消双高度 | 两态同值断言 |
| `b13_polish_test.dart:433–490` | 日期图标存在 / 点图标弹期间 | B 删图标按钮 | 改为断言图标**不存在** + 点日期格弹选择器 |
| `b12_matrix_tabs_date_test.dart:314/386` | 页签/日期格结构 | A / B | 同步结构 |
| `b10_blueprint_matrix_done_test.dart:244/252/274/425/495` | `goal-blueprint-period-<id>` / `-text-<id>` | B 删图标按钮（**保留 `-text-` 与 `-tap-`**） | 图标 key 改 `findsNothing`，其余保留 |
| `task64_nav_gear_test.dart:64–87` | 导航 8 项 / 末项 calendar / 含 habits | G 改 7 项 | 同步新序位 |
| `nav_rail_footnote_test.dart`、`shell_key_hints_test.dart` | 「8 项」「Ctrl+1…8」「Ctrl+3 习惯」 | G 改 7 项 | 同步新序位（`Ctrl+3` 蓝图 / `Ctrl+4` 目标 / `Ctrl+5` 项目 / `Ctrl+6` 学习管理） |
| `b16_nav_learning_test.dart` | 8 项 / 学习为禁用占位 | G | 改 7 项 + 学习管理文案 |
| `task65_goals_week_test.dart`、`task66_goals_month_page_test.dart`、`task66_goals_year_page_test.dart` | 行渲染 / 区块存在 | D / E / F | 区块断言改 `findsNothing`；行断言补类别小标题与单选 |
| `task74_goal_edit_shared_test.dart:63/75/103/292/308` | `showGoalFormDialog` 字段 / `GoalRowActions` 宽度 | F | 同步新字段与宽度口径（无 done 回调时仍 56） |
| `b10_position_panel_test.dart:478/488`、`b11_period_date_test.dart:104` | 表单 / 期间弹窗 | F | 同步新结构 |

## 6. 控制器后续动作（worker 全部回板之后）

1. 把本批新增 / 新改的文件补进 `reports\task51-gate.ps1` 的 `$patterns`（该脚本在 `reports/`，已被 `.gitignore` 排除，属本机装置物；**每次改都要保持纯 ASCII / CRLF / 无 BOM**，并跑 `reports\task57-ps1-ascii-scan.ps1`）。**已在本批开工时补录**（见 §6.1）。
2. 跑权威门禁：`pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests <当轮实测数>`（**不许估**，先跑一轮取数再按该数复跑）。前置：先把 `apps\desktop\build\test_cache\build` 用 `Move-Item` 改名挪走（不删）。
3. 出包（坑 127 两步）：① 在 `apps\desktop` 目录内 `flutter build windows --release`；② `tools\build\make_installer.ps1 -Version '1.0.0'`。重编判据只比构建树 `data\app.so` 的 sha16（`actlog.exe` 恒为 484,352 B / `89293205FAF8C3DE`，不作判据）。
4. 静默装配（仿 `reports\task103-install-b14.ps1`）：先 `WM_CLOSE`（必要时 FORCE_KILL）关实例，再 `Start-Process <安装包> -ArgumentList '/S'`（**不** `-Wait`），校验装机 `app.so` sha16 与构建树逐字一致 + 活库 `userdata\actlog.db` 零写入（只认安装脚本成对日志 `DB_BEFORE`=`DB_AFTER`）。
5. 更新 `AGENTS.md`：§2 R3 分发禁令真源行（新增可分发包）、§7 当前状态快照、§7.1、§8 口径条。
6. 台账 `docs\handoff-ledger-b9-w4.md` 追加 §11.27，并把本批改动提交（**只 commit 不 push**；`AGENTS.md` 的 `<!-- BEGIN RELAY-PORT -->` … `<!-- END RELAY-PORT -->` 托管块**不随批提交**，沿用「临时剥离 → `git add` → 还原」）。

### 6.1 门禁白名单补录（控制器，本批开工时完成）

`reports\task51-gate.ps1` 的 `$patterns` 追加 B17 块：`docs/b17-plan.md`、`apps/desktop/lib/src/widgets/goals/goal_category.dart`、`apps/desktop/lib/src/widgets/goals/goal_section.dart`、`apps/desktop/lib/src/widgets/goals/goal_form_dialog.dart`、`apps/desktop/lib/src/widgets/goal_period_dialog.dart`、`apps/desktop/lib/src/widgets/goal_week_table.dart`、`apps/desktop/test/b17_*.dart`、`apps/desktop/test/b10_position_panel_test.dart`、`apps/desktop/test/b11_period_date_test.dart`、`apps/desktop/test/b13_polish_test.dart`、`apps/desktop/test/b12_matrix_tabs_date_test.dart`、`apps/desktop/test/b10_blueprint_matrix_done_test.dart`、`apps/desktop/test/b14_tab_scale_test.dart`、`apps/desktop/test/task74_goal_edit_shared_test.dart`、`apps/desktop/test/nav_rail_footnote_test.dart`、`apps/desktop/test/b16_nav_learning_test.dart`。

## 7. 继承的硬约束（勿重试死路）

- `flutter test` / `flutter build windows --release` 必须在 `apps\desktop` 目录内跑（仓库根报 `Target file "lib\main.dart" not found`）。
- 跑全量前先 `Move-Item apps\desktop\build\test_cache\build <改名>`（**不删**），否则 OS Error 183 挂死。
- 多棒并发跑测试会争 `apps\desktop\build\native_assets\windows\sqlite3.dll` ⇒ worker 只跑自己写集内的测试文件，权威全量**必须控制器独占跑**。
- 环境变量必须进程内设置：`$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`。
- 四包 analyze 必须逐字 `No issues found!`（VERBATIM）。
- 合成取帧通道（`PrintWindow` 外的 `WM_MOUSEMOVE` / `SendInput` / UIA）**已判死路**；界面证据只走带 `ValueKey` 的 widget 测试 + 用户肉眼。
- `reports\**\*.ps1` 纯 ASCII / CRLF / 无 BOM；中文正文只进 `.md` / `.txt` / `.json`。
- **不删文件**，一律 `Move-Item` 归档；台账具体值必须盘上回读后再写。
- 长中文串经 shell 传输会静默吞字 ⇒ 中文正文一律用 `write` / `edit` 工具落盘。
- 控制器**零改** `apps\**` 与 `packages\**`；实现全部由 worker 落盘。