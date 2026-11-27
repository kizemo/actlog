# B16 批次计划（用户 2026-11-27 验收反馈 · 七项界面改动）

> 状态：**执行中**。控制器 = 本会话（`mvs_382f354c18ad42aab11f5e9e380fba1e`）；实现全部由 worker 子会话落盘（AGENTS.md R1）。
> 上游：B15 链 6 环已终态 `blocked`（`docs\relay.json`），本批**不使用**接力链装置（用户未下达「启动接力链」指令），改为控制器 + 3 棒 worker 直派，写集纪律与 R1 一致。

## 0. 背景

- B15 链已把台账 §11.21 遗留项全部走完，门禁全绿（1041 例）。
- 用户 2026-11-27 上午完成 **B14 观感肉眼验收**，给出**通过项 3 条 + 修改意见 8 条**（原文见台账 `docs\handoff-ledger-b9-w4.md` §11.25）。
- 同时用户对三项人工验收点全部拍板：① 同意提交（`AGENTS.md` 的 RELAY-PORT 托管块**不随本批提交**）；② 门禁白名单补录 `apps/desktop/test/b13_polish_test.dart` 并重跑不带排除项的门禁（**已完成**）；③ B15 批次 commit（**只 commit 不 push**，沿用 B13/B14 惯例）。
- B15 的余量加固（英文态 760 窗真页面余量 0.21px → 1.1973px）**只在工作树，未出包、未装机**；用户对第 ⑤ 条「760 宽英文态」的肉眼验收**尚未做**（要新包）。

## 1. 唯一真源与优先级

1. 用户当轮决定
2. 本文件（派工口径）
3. 台账 `docs\handoff-ledger-b9-w4.md` §11.25（用户反馈原文）
4. `AGENTS.md` §2 铁律 R1–R8、§7.1 设计标准、§8 B15 口径条
5. 侦察兵实测映射（`docs\relay\stage-1-inventory.md` 同族格式，本文件 §3 为其落点）

## 2. 工作队列（七项，全部为 A 类：可自动闭合，但必须带判别性测试）

| # | 用户原话（压缩） | 验收要点 |
|---|---|---|
| 1 | 蓝图页点「+」直接进可编辑态，编辑完直接保存；不细分标题/关键词 | 点「+」→ 格内就地编辑（**不弹窗**）→ 保存落库 |
| 2 | 已填目标要有「保存+」按钮，可继续添加新目标 | 每格右侧**常驻**「+」；保存后「+」仍在；可换行继续加第二个目标 |
| 3 | 页签上下 padding 增加，内部文字不要拥挤 | `_tab` 加垂直内边距；高度口径同步；B4-2/B4-4 断言同步 |
| 4 | 填起止日期后顶部多一行年份、日期按钮换行；点击日期直接显示日期选项卡 | 删年刻度条；日期单元格整格可点，**一点即出日期选择**；不再换行 |
| 5 | 几个选项卡中，去除「滚动候选」 | 实为周/月/年三页左列**段头卡**（`t.goalsDraftSection`），去 UI 入口，**数据层不动** |
| 6 | 左侧导航加「学习管理」占位，顺序 01 日志 / 02 待办 / 03 习惯 / 04 蓝图 / 05 目标 / 06 项目 / 07 学习 / 08 日历 | 两份导航清单同改；序号自动生成；「学习」为禁用占位 |
| 7 | 当前目标页面没有录入框；可点击直接编辑、可点「+」添加；右侧未完成*目标可拖入本*目标输入框 | 周页 + 月页「本*目标」卡底部加录入行 + 「+」；`DragTarget` 收到录入行并给落点反馈；点标题可就地编辑 |

**用户已判「通过」不再动的三项**：目标正文就地编辑（光标在末尾 / Esc 失焦退出 / 改完存住）、设置页三档配色（默认墨色与 B14 前逐字节一致）、选中页签与模块底色肉眼可分。⇒ **不得回退**这三条的实现。

### 2.1 控制器裁决（用户未点名处，按项目纪律定案，不外抛）

- **第 7 项落在周页 + 月页**（年页无上游右栏，「未完成*目标→本*目标」链路不存在 ⇒ 不做）。
- **第 5 项只删 UI 入口，保留 l10n getter**（`goalsDraftSection` 不删，l10n 计数不变）⇒ 避免与第 6 项抢同一个计数标量。
- **第 6 项独占 l10n 键表三件套**（`l10n_keys.dart` / `l10n_harness.dart` / `l10n_base_test.dart`，计数 612 → 613）；W1 / W3 **不得**碰这三个文件。
- **第 4 项日期选择器**：优先站内唯一组件 `DatePickerSheet`（`date_picker_sheet.dart`，纪律：任何页面不得自造日期选择器）；若其不支持区间，退回既有 `showGoalPeriodDialog`，但**必须做到从日期格一点即出选择界面**，不得再要求用户点那个换行的小图标。
- **第 1/2 项合并实现**：蓝图格内右侧常驻「+」＝「保存+」；点它 → 就地编辑（仅标题）→ 保存 → 「+」仍在右侧 → 可换行继续添加。不新增弹窗按钮，不动 `goal_form_dialog.dart`。

## 3. 侦察兵实测映射（文件 : 行号，行号为盘上实况）

| # | 文件 | 关键行 | 关键符号 / key |
|---|---|---|---|
| 1 | `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart` | 630–657 / 259–337 / 766 | `_cell`、`_editingGoalId`、`_inline`、`_startInline`、`_commitInline`、`_inlineEditor`、`goal-blueprint-add-<domain>-<horizon>` |
| 1 | `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 397–414 / 495–558 | `_openCreateGoal`、`_writeGoal`、`onAddGoal:`(306) |
| 2 | 同上 | 637 附近 | 「+」目前**只在空格渲染**，有内容的格子没有「+」 |
| 3 | `goal_blueprint_matrix.dart` | 507–597 / 166–171 / 181 / 198 / 213 | `_tab`、`_tabFontSize=15`、`_tabPadding=10`、`tabActiveHeight=38`、`tabInactiveHeight=31`、`tabIndicatorHeight=3` |
| 4 | `goal_blueprint_matrix.dart` | 379–396 / 791–871 / 1052–1086 | 年刻度条 `goal-blueprint-year-scale`、`_yearScale`、`_dates`、`goal-blueprint-period-<id>` |
| 4 | `goals_blueprint_page.dart` | 598–638 | `_editGoalPeriod` → `showGoalPeriodDialog` |
| 5 | `goals_week_page.dart` / `goals_month_page.dart` / `goals_year_page.dart` | 85–94 / 198–209 / 145–149 | `_GoalCard(title: t.goalsDraftSection)` |
| 6 | `apps/desktop/lib/src/widgets/shell/nav_rail.dart` | 40–48 / 56–64 / 118–130 / 193–202 | `kShellNavItems`、`shellNavItemsFor`、`ShellNavItem.enabled` |
| 6 | `apps/desktop/lib/src/app.dart` | 167–174 / 244–264 / 349–365 / 367 | 深链路由、`Ctrl+1…7` 快捷键、`_content()`、`_onNavSelected` |
| 7 | `goals_week_page.dart` / `goals_month_page.dart` | 64–96 / 99–131 / 307 / 204 / 241 | `_GoalCard(title: t.goalsWeekSection)`、`DragTarget('goal-week-drop-target')`、`_editGoal`、`_updateGoal` |
| 7 | `apps/desktop/lib/src/widgets/goal_upstream_panel.dart` | 24 / 27 / 33 / 148–160 | `goal://` payload、`Draggable<String>` |

### 3.1 必然变红的既有断言（worker 必须同步改断言，**改断言不删测试**）

| 断言位置 | 内容 | 为什么红 | 处置 |
|---|---|---|---|
| `b13_polish_test.dart:365–382` | `padding == EdgeInsets.symmetric(horizontal: 10)` | 第 3 项加垂直内边距 | 改成含 vertical 的期望 |
| `b13_polish_test.dart:413–427` | `minimumSize` 38 / 31 | 高度口径随垂直内边距变 | 同步新值 |
| `b11_blueprint_roulette_test.dart:358/361/367` | 断言年刻度条存在 | 第 4 项删年刻度条 | 改为断言**不存在** |
| `b11_blueprint_roulette_test.dart:395` | 无日期时年刻度不存在 | 同上 | 仍成立，保留 |
| `b13_polish_test.dart:433–467 / 469–490` | 日期图标存在 / 点图标弹期间弹窗 | 第 4 项整格可点 | 按新交互改 |
| `b10_blueprint_matrix_done_test.dart:244/252/274/425/495` | `goal-blueprint-period-<id>` / `goal-blueprint-period-text-<id>` | 第 4 项改日期格结构 | 保留 key 再改结构，或同步改断言（优先**保留 key**） |
| `task73_b8_w1_blueprint_edit_test.dart:231/237/268/299` | 点「+」后期望弹窗字段 | 第 1 项改为就地编辑 | 改为就地编辑断言 |
| `task66_goals_blueprint_page_test.dart:220/225/400/443/493`、`b12_matrix_tabs_date_test.dart:314/386` | 弹窗路径 | 同上 | 同上 |
| `task65_goals_week_test.dart:262`、`task66_goals_month_page_test.dart:258`、`task66_goals_year_page_test.dart:203` | 「滚动候选只算不写」 | 第 5 项删段头卡 | 改为断言该卡**不存在**，并保留「不写库」语义 |
| `task64_nav_gear_test.dart:64–73/76/85–87` | 导航 7 项、末项 blueprint | 第 6 项加到 8 项并重排 | 同步新顺序 |

## 4. 写集表（R1 硬约束：worker 只能写自己那一行；控制器只写台账 / 计划 / 门禁脚本 / `AGENTS.md`）

| 行 | worker | 独占写集 | 交付判据 |
|---|---|---|---|
| **W1** | `b16-w1-blueprint` | `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart`、`apps/desktop/lib/src/pages/goals_blueprint_page.dart`、`apps/desktop/test/b13_polish_test.dart`、`b11_blueprint_roulette_test.dart`、`b10_blueprint_matrix_done_test.dart`、`b12_matrix_tabs_date_test.dart`、`task66_goals_blueprint_page_test.dart`、`task73_b8_w1_blueprint_edit_test.dart`、新建 `apps/desktop/test/b16_blueprint_inline_create_test.dart` | 第 1/2/3/4 项落地；新建测试覆盖「点 + → 就地编辑 → 保存 → + 仍在 → 再点 + → 换行新增第二个」；`flutter test` 目标文件全绿；**必须复跑** `b14_tab_scale_test.dart`（余量红线 11px 不放宽） |
| **W2** | `b16-w2-nav` | `apps/desktop/lib/src/widgets/shell/nav_rail.dart`、`apps/desktop/lib/src/app.dart`、`apps/desktop/lib/src/widgets/shell/key_bar.dart`、`apps/desktop/lib/src/l10n/parts/shell.dart`、**独占** `apps/desktop/lib/src/l10n/l10n_keys.dart`、`apps/desktop/test/l10n_harness.dart`、`apps/desktop/test/l10n_base_test.dart`、`apps/desktop/test/task64_nav_gear_test.dart`、新建 `apps/desktop/test/b16_nav_learning_test.dart` | 第 6 项落地；导航顺序逐字为 01 日志 / 02 待办 / 03 习惯 / 04 蓝图 / 05 目标 / 06 项目 / 07 学习 / 08 日历；「学习」为禁用占位；l10n 计数 612 → 613 且 `l10n_base_test` 同步 |
| **W3** | `b16-w3-goals-input` | `apps/desktop/lib/src/pages/goals_week_page.dart`、`goals_month_page.dart`、`goals_year_page.dart`、`apps/desktop/lib/src/widgets/goal_week_table.dart`、`apps/desktop/lib/src/widgets/goal_upstream_panel.dart`、`apps/desktop/test/task65_goals_week_test.dart`、`task66_goals_month_page_test.dart`、`task66_goals_year_page_test.dart`、新建 `apps/desktop/test/b16_goal_input_drag_test.dart` | 第 5/7 项落地；周页 + 月页录入行 + 「+」；`DragTarget` 收到录入行且有落点反馈；拖拽落库有断言；年页删「滚动候选」卡 |
| **W4**（追补·第 4 棒） | `b16-w4-hint-tests` | `apps/desktop/test/nav_rail_footnote_test.dart`、`apps/desktop/test/shell_key_hints_test.dart` | 全量实测 `+1058 -3`：两文件仍写死「7 项 / 无 08」「Ctrl+1…4 + Ctrl+5 项目 / Ctrl+6 目标 / Ctrl+7 蓝图」，被第 6 项重排打红。只许把预期值同步到新序位（01–08、切页 `Ctrl+1…8`、单条 `Ctrl+4` 蓝图 / `Ctrl+5` 目标 / `Ctrl+6` 项目），不许放宽阈值 / 删断言 / skip；两文件 `flutter test` 全绿 |

**写集冲突硬规则**

1. 三行**文件零交集**，可并行。
2. `l10n_keys.dart` / `l10n_harness.dart` / `l10n_base_test.dart` **只有 W2 能写**（计数 612 → 613 是单值标量）。W1 / W3 若需新增文案，**一律改用既有 getter**，不许动键表。
3. W1 不得改 `goal_form_dialog.dart`、W3 不得改 `providers.dart` / `goal_store.dart`（数据层不动）。
4. `apps/desktop/test/b14_tab_scale_test.dart`、`b14_theme_test.dart` **只有 W1 能改**（余量与配色判据在 W1 写集内）；W2 / W3 只许**复跑**，不许改。
5. 任何 worker 发现需要改写集外的文件 ⇒ **停下来报控制器**，由控制器在本表追加一行并留档（R1 允许的「显式追补行」）。
6. （B16 追加）W4 是第 4 棒追补：依据 `reports/task113-writeset-amendment-w4.md`，只同步第 6 项连带失效的两处测试预期值；两文件与 W1/W2/W3 零交集，已在三棒全部终态后才派发。

## 5. 控制器后续动作（worker 全部回板之后）

1. 把本批新增 / 新改的文件补进 `reports/task51-gate.ps1` 的 `$patterns`（该脚本在 `reports/`，已被 `.gitignore` 排除，属本机装置物；**每次改都要保持纯 ASCII / CRLF / 无 BOM**，并跑 `reports\task57-ps1-ascii-scan.ps1`）。
2. 跑权威门禁：`pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests <当轮实测数>`（**不许估**，先跑一轮取数再按该数复跑）。
3. 出包（坑 127 两步）：① 在 `apps\desktop` 目录内 `flutter build windows --release`；② `tools\build\make_installer.ps1 -Version '1.0.0'`。重编判据只比构建树 `data\app.so` 的 sha16。
4. 静默装配（仿 `reports\task103-install-b14.ps1`）：**先关掉运行中的实例**，再 `Start-Process <安装包> -ArgumentList '/S'`（**不** `-Wait`），校验装机 `app.so` sha16 与构建树逐字一致 + 活库 `userdata\actlog.db` 零写入。
5. 更新 `AGENTS.md`：§2 R3 分发禁令真源行（新增可分发包）、§7 当前状态快照、§7.1、§8 口径条。
6. 台账追加 §11.26，并把本批改动提交（**只 commit 不 push**；`AGENTS.md` 的 RELAY-PORT 托管块**不随批提交**，沿用「临时剥离 → `git add` → 还原」）。

## 6. 继承的硬约束（勿重试死路）

- 英文态 760 窗页签余量红线 **11px 不放宽**；任何改页签内边距 / 分隔符 / 文案长度的改动**必须复跑** `b14_tab_scale_test.dart`（水平自然宽不变 ⇒ 余量数值不受垂直内边距影响，但结构断言可能变）。
- 合成取帧通道（`WM_MOUSEMOVE` / `WM_MOUSEWHEEL` / `SendInput` / UIA）**已判死路**；界面证据只走带 `ValueKey` 的 widget 测试 + 用户肉眼。
- `flutter test` 必须在 `apps\desktop` 目录内跑；跑全量前先 `Move-Item apps\desktop\build\test_cache\build <改名>`（**不删**）。
- 权威门禁判绿只看 `reports\task51-gate\summary.txt` 的 `GATE_VERDICT`。
- `reports\**\*.ps1` 纯 ASCII / CRLF / 无 BOM；中文正文只进 `.md` / `.txt` / `.json`。
- **不删文件**，一律 `Move-Item` 归档；台账具体值必须盘上回读后再写。
- 长串中文经 shell 传输会静默吞字 ⇒ 中文正文写入一律用 `edit` / `write` 工具，或先落文件再按路径读入。
- 控制器**零改** `apps\**` 与 `packages\**`；实现全部由 worker 落盘。
