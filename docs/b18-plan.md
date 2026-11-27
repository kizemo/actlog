# B18 计划：目标模块四项 UI 修正 + 垂直居中

> 批次编号：**B18**（B17 已闭合，本批由用户当轮指令立项）。
> 控制器：本会话（root）。实现全部由 worker 子会话落盘，控制器**零改** `apps\**` / `packages\**`。
> 计划建立时间：2026-11-27。

---

## 1. 背景

B17 收口时（`docs/handoff-b17-2026-11-27.md`，台账 §11.27/§11.28）落地了「按类别分区渲染 + 行内类别列」「行尾完成单选」「月页派生标记」等一批目标模块改造，desktop 全量 **+1106**、门禁 PASS、出包装机完成、用户肉眼验收通过。

B17 落地后用户当轮提出 4 条修改，本批逐条裁决执行。

**B17 引入、本批要收回的三处冗余**

| 冗余 | B17 引入方式 | 后果 |
|---|---|---|
| 分类名在一行里出现两次 | 同时渲染了「分区小标题」与「行内类别列」 | 选了分类的目标，分区小标题 + 行内列各写一遍同一个分类名 |
| 完成列写「进行中 / 已完成」 | 月/年页各自加了一列状态文本（宽 64 / 56） | 状态信息与行尾完成单选重复，且占了窄列宽 |
| 月页行尾派生标记行 | 每行下面加一行「服务于年目标」/「临时事项」 | 行高参差，与「垂直居中」的诉求相悖 |

## 2. 需求逐条裁决

| 编号 | 用户原话 | 根因（盘上回读） | 裁决 | 落点 |
|---|---|---|---|---|
| R1-1 | 添加的新目标选了分类后显示**两行重复的分类名称**，去除冗余 | `goal_section.dart` L204–224 渲染分区小标题（key `goal-section-title-<displayKey>`），月/年页又各渲染了一列行内类别文本 | **删行内类别列，保留分区小标题**（分类名仍然可见，且只出现一次） | 月页 L676–681；年页 L382–386 |
| R1-2 | 完成列**不要显示「进行中」**，状态只需要单选按钮 | 月页 L688–694 / 年页 L411–417 渲染了状态文字列 | **删状态文字列 + 对应表头格**；状态唯一由 `GoalRowActions` 的完成单选（key `goal-row-done-<id>`）表达 | 月页 L688–694 + 表头 L625；年页 L411–417 + 表头 L360–363 |
| R2 | **每一行数据保持垂直居中**，当前上下有错位 | 行与表头的 `Row` 一律 `CrossAxisAlignment.start`，而行内各列高度不等（标题可多行 / 日期列两行 / 操作列 28px 按钮） | 行 `Row` 与表头 `Row` 改 `CrossAxisAlignment.center` | 周表 L234 / L113；月页 L674 / L619；年页 L380 / L341 |
| R3 | 去除目标模块中的**「临时事项」** | 月页 `_monthRow` 行尾派生标记行（L709–717） | **整条派生标记行下线**（含「服务于年目标」），两个 ValueKey 一并下线 | 月页 L709–717 |
| R4 | 蓝图页面**保持内容垂直居中**，当前上下有错位 | 蓝图目标行 `Row(crossAxisAlignment: start)`，勾选框 / 标题 / 操作三块高度不等；日期列同理 | 目标行、日期列改居中对齐 | `goal_blueprint_matrix.dart` L747–755、L855–856、L955–963 |
| R4-2 | 蓝图「**删除目标**」改**垃圾桶图标按钮**（和目标页面一致） | `_actions` L1054–1059 是 `TextButton` 文字按钮 | 换成与目标页同口径的 28×28 `Icons.delete_outline` 图标按钮，**保留 key** `goal-blueprint-delete-<id>` | `goal_blueprint_matrix.dart` L1054–1059 |

### 2.1 明确**不动**的东西（避免越权）

- **周页「完成」列不动**：周表 L269–275 渲染的是**完成度百分比**（`stats.completionRate`），与「进行中」状态文本语义不同，不属于本次删除范围。
- **l10n getter 一律保留不删**：`goalStatusActive` / `goalStatusDone` / `goalMonthColumnCategory` / `goalMonthColumnDone` / `goalMonthAdHoc` / `goalBlueprintDeleteGoal` 全部保留原样，避免动 `l10n_base_test.dart` / `l10n_harness.dart` 的 613 / 613 / 672 计数。本批**不碰** `apps\desktop\lib\src\l10n\**`。
- **分区小标题保留**：仍走 `goal_category.dart` 的 `goalCategoryTitle`（B17 F 条口径），**不复用** `projectDomainLabel`。
- **`Column(crossAxisAlignment: stretch)` 不动**：月页 L615 / L670、周表 L109 / L145、蓝图的横向 stretch 是**横向**对齐语义，改成 center 会破坏分区小标题左对齐。本批只改**行内纵向**对齐。

### 2.2 R3 的裁决说明（「临时事项」整行下线）

用户原话是「去除目标模块中的『临时事项』」。本批按**整条派生标记行下线**执行，理由：

1. 保留「服务于年目标」而只删「临时事项」，会让一半行两行、一半行一行，行高参差，正好是 R2 要消除的错位；
2. 标记行是**派生**信息（由父子关系推导，不写库），分区小标题 + 行内容已足够定位该目标。

验收时若确认「服务于年目标」要保留，回填点只有月页 `_monthRow` 一处三元表达式，改动量约 5 行。

### 2.3 R4-2 的 §7.1 口径

按 `AGENTS.md` §7.1「纯文本单元格改图标」：

- 保留原交互入口与原 i18n key；
- 图标必须带 `Tooltip` + `Semantics(label: 原文案)`，原文案取 `t.goalBlueprintDeleteGoal`（zh「删除目标」/ en「Delete goal」）；
- 单色、语义明确、不抢正文视觉；圆角真源 `AppTokens.radius = 4`（唯一例外 `chromeTabTopRadius = 8`），禁胶囊化、禁彩色 emoji 当图标。

目标页同款口径在 `widgets\goals\goal_form_dialog.dart` L778–786（`Icons.delete_outline`，iconSize 16，`BoxConstraints.tightFor(width: 28, height: 28)`，`materialTapTargetSize: shrinkWrap`）。蓝图矩阵已有 `_compactButton`（L1064–1088）正是该口径，直接复用。

## 3. 关键不变量（worker 不得破坏）

1. **key 契约全部不变**：
   - `goal-row-done-<id>`（完成单选）
   - `goal-month-row-edit-<id>` / `goal-month-row-delete-<id>`
   - `goal-year-row-edit-<id>` / `goal-year-row-delete-<id>`
   - `goal-week-row-edit-<id>` / `goal-week-row-delete-<id>`
   - `goal-blueprint-done-<id>` / `goal-blueprint-cell-<id>` / `goal-blueprint-goal-text-<id>`
   - `goal-blueprint-edit-<id>` / `goal-blueprint-split-<id>` / **`goal-blueprint-delete-<id>`**
   - 确认/取消：`goal-blueprint-delete-confirm` / `goal-blueprint-delete-cancel`
   - 分区小标题：`goal-section-title-<displayKey>`
2. **表头列数与行列数逐位对应**：月页删 2 格（类别 72 + 状态 64），年页删 2 格（类别 64 + 状态 56）；操作列表头宽度恒为 `GoalRowActions.width + GoalRowActions.doneWidth`（56 + 24 = 80）。
3. **分区小标题仍在**：删掉行内类别列后，分类名唯一出处是分区小标题，**不得**把分区小标题一起删掉。
4. **不动 `packages\**`**（schema FROZEN）、不动 `apps\desktop\lib\src\l10n\**`、不动路由与数据层。
5. **改动后 `flutter analyze` 必须逐字 `No issues found!`**：删除代码后残留的未使用局部变量 / 未使用 import 一律清干净（例：月页 `_monthRow` 的 `hasYearly` / `served` 与 `goalCategoryTitle` import）。

## 4. 写集表（四棒互不重叠，可并行）

| 棒 | 主题 | 可写文件（**且仅**这些） |
|---|---|---|
| **W1** | 周表行垂直居中 | `apps/desktop/lib/src/widgets/goal_week_table.dart`；`apps/desktop/test/b17_week_page_test.dart`；`apps/desktop/test/b18_week_row_center_test.dart`（新建） |
| **W2** | 月页去重 + 去状态列 + 去临时事项 + 居中 | `apps/desktop/lib/src/pages/goals_month_page.dart`；`apps/desktop/test/b17_month_page_test.dart`；`apps/desktop/test/task66_goals_month_page_test.dart`；`apps/desktop/test/b18_month_page_test.dart`（新建） |
| **W3** | 年页去重 + 去状态列 + 居中 | `apps/desktop/lib/src/pages/goals_year_page.dart`；`apps/desktop/test/b17_year_page_test.dart`；`apps/desktop/test/task66_goals_year_page_test.dart`；`apps/desktop/test/b18_year_page_test.dart`（新建） |
| **W4** | 蓝图居中 + 删除改垃圾桶图标 | `apps/desktop/lib/src/widgets/goal_blueprint_matrix.dart`；`apps/desktop/test/task73_b8_w1_blueprint_edit_test.dart`；`apps/desktop/test/b18_blueprint_test.dart`（新建） |

**写集纪律（R1）**：worker 只允许改上表列出的文件。**发现必须写写集外文件时，立刻停下报控制器**，由控制器在 `reports\b18-writeset-amendment-w<N>.md` 追加行并留档后再继续，不得自行扩大范围。

**并发纪律**：多棒并发跑 `flutter test` 会争 `apps\desktop\build\native_assets\windows\sqlite3.dll` ⇒ worker 只跑**自己写集内**的测试文件；**权威全量必须由控制器独占跑**。

## 5. 必红断言（既有测试改法：**改断言，不删用例**）

| 文件 | 位置 | 现状 | 改法 |
|---|---|---|---|
| `test/b17_year_page_test.dart` | L250 / L255–256 / L261 | 断言 `find.text(zh.goalStatusActive)` `findsOneWidget` 等 | 改为断言完成单选（key `goal-row-done-<id>`）的图标/状态；对状态文本断言 `findsNothing` |
| `test/task66_goals_month_page_test.dart` | L191–201（用例名含「区分『服务于年目标』与『临时事项』」） | 断言 `goal-month-serves-yearly-<id>` 与 `goal-month-ad-hoc-<id>` 两个 key 存在 | 两个 key 都改 `findsNothing`；用例名同步改为「月页：不再渲染派生标记行」 |
| `test/b17_month_page_test.dart` | L286 用例名含「进行中」 | 用例名字面 | 改用例名，断言内容按实际实现核对 |
| `test/task66_goals_year_page_test.dart` | 含类别列/状态列断言处 | — | 改断言或删对应断言（**用例本身保留**） |
| `test/task73_b8_w1_blueprint_edit_test.dart` | L384 / L403 / L487 / L542 | 依赖 key `goal-blueprint-delete-<id>` | key 不变 ⇒ 基础断言不必改；若断言的是「删除目标」**文字**，改为断言垃圾桶图标按钮存在 + Tooltip/Semantics 文案 |
| `test/task74_goal_edit_shared_test.dart` | L271–293 确认/取消 key、L63/75/103/292/308 宽度断言 | `GoalRowActions` 宽度 | 本批不动 `GoalRowActions` ⇒ 通常无需改；若有偏差才动 |

**新测试建议**（每个 worker 在自己的 `b18_*` 文件里落判别性断言）：

- W1：周表行内各列的**垂直中心线一致**（取 `tester.getRect` 比较中点，容差 ≤ 1px）。
- W2：月页**行内不再出现类别文本**（`findsNothing`）、**不再出现「进行中/已完成」文本**、**两个派生标记 key 都 `findsNothing`**、完成单选仍存在。
- W3：年页同上两项 + 垂直中心线一致。
- W4：蓝图目标行 Checkbox / 标题 / 操作区**垂直中心线一致**；`goal-blueprint-delete-<id>` 是**图标按钮**（`find.byIcon(Icons.delete_outline)`）且带 Tooltip「删除目标」。

## 6. 控制器后续动作（worker 全部回板之后）

1. **门禁白名单补录**（§6.1，本批开工时已完成）。
2. **跑权威门禁**：`pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests <当轮实测数>`（**不许估**，先跑一轮取数再按该数复跑）。前置：先把 `apps\desktop\build\test_cache\build` 用 `Move-Item` 改名挪走（**不删**），否则 OS Error 183 挂死。
3. **出包（坑 127 两步）**：① 在 `apps\desktop` 目录内 `flutter build windows --release`；② `tools\build\make_installer.ps1 -Version '1.0.0'`。重编判据只比构建树 `data\app.so` 的 sha16（`actlog.exe` 恒为 484,352 B / `89293205FAF8C3DE`，不作判据）。
4. **静默装配**（仿 `reports\task103-install-b14.ps1`）：先 `WM_CLOSE`（必要时 FORCE_KILL）关实例，再 `Start-Process <安装包> -ArgumentList '/S'`（**不** `-Wait`），校验装机 `app.so` sha16 与构建树逐字一致 + 活库 `userdata\actlog.db` 零写入。
5. **更新台账** `docs\handoff-ledger-b9-w4.md` 追加 §11.29（锚点用「末条非空行 + 断言其后即文件末尾」，**不用**「全文件唯一」——§11.26 与 §11.27 收尾句完全相同，唯一性断言必 exit 3）。
6. **更新 `AGENTS.md`**：§2 R3 分发真源行、§7 状态快照、§7.1。
7. **写 handoff 单页** `docs\handoff-b18-2026-11-27.md`。
8. **git 写操作**：本批**未获 push 授权**，commit / push 属人工验收点，链上不自作。若提交 `AGENTS.md`，须先剥离 `<!-- BEGIN RELAY-PORT -->` … `<!-- END RELAY-PORT -->` 托管块、提交后还原并校验 SHA 相等。

### 6.1 门禁白名单补录（控制器，本批开工时完成）

`reports\task51-gate.ps1` 的 `$patterns` 追加 B18 块：`apps/desktop/test/b18_*.dart`、`docs/b18-plan.md`、`docs/handoff-b18-*.md`。
该脚本属本机装置物（`reports/` 被 gitignore），**每次改都要保持纯 ASCII / CRLF / 无 BOM**，改完跑 `reports\task57-ps1-ascii-scan.ps1`（期望 `PS1_ASCII_VIOLATIONS=0`）。

## 7. 继承的硬约束（勿重试死路）

- `flutter test` / `flutter build windows --release` 必须在 `apps\desktop` 目录内跑（仓库根报 `Target file "lib\main.dart" not found`）。
- 跑全量前先 `Move-Item apps\desktop\build\test_cache\build <改名>`（**不删**），否则 OS Error 183 挂死。
- 环境变量必须**进程内**设置：`$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`。
- 四包 analyze 必须逐字 `No issues found!`（error / warning / info 全 0）。
- 合成取帧通道（`WM_MOUSEMOVE` / `SendInput` / UIA）**已判死路**；界面证据只走带 `ValueKey` 的 widget 测试 + 用户肉眼。
- `reports\**\*.ps1` 纯 ASCII / CRLF / 无 BOM；中文正文只进 `.md` / `.txt` / `.json`。
- **不删文件**，一律 `Move-Item` 归档；台账具体值必须盘上回读后再写。
- 长中文串经 shell 传输会静默吞字 ⇒ 中文正文一律用 `write` / `edit` 工具落盘。
- 控制器**零改** `apps\**` 与 `packages\**`；实现全部由 worker 落盘。
