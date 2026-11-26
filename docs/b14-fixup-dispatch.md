# B14 补做派工书（第二轮 · 控制器裁决后）

> 本书是 `docs\b14-dispatch.md` 的**补充**，不是替代。B14 主体的实现契约仍以 `docs\b14-dispatch.md` 为准。
> 本书只解决 verifier 独立审查（`reports\verifier-b14\verdict.md`，247 行 / 30,165 B / `VERIFIER_VERDICT=FAIL`）列出的、控制器裁定**必须补做**的条目。
> 控制器批注见 `reports\verifier-b14\controller-ruling.txt`（3,341 B）：其中已闭合 verifier 的「未验证项」，并把 D4 归因订正为**不成立**（那些 `docs/relay*` 改动是控制器装 relay-port 装置所致，不是 worker 越界）。

## §0 开工前必须知道的现状（控制器已坐实，不必重查）

- 工作区 HEAD = `dcce549`，B14 主体实现**未提交**，在 `apps\desktop` 下 14 个已跟踪文件 + 2 个新测试文件（`git diff --stat -- apps` = 937+ / 389-）。`packages\**` 零改动。
- 控制器亲跑权威门禁 `reports\task51-gate.ps1 -ExpectDesktopTests 1030`：**PASS**，`DESKTOP_TESTS=1030`（=期望）、四包 analyze 全 `VERBATIM`、`VIOLATIONS=0`、`OUT_OF_SET=0`、`PS1_ASCII_VIOLATIONS=0`、core_data 204 / core_db 96 / core_domain 91。产物 `reports\task51-gate\summary.txt`（2,166 B / `EBC723F90DDE065B`）。
- 另一棒（760 宽缩放实测）**已先行落地**：新增 `apps\desktop\test\b14_tab_scale_test.dart`（19,482 B）。你开工时该文件已在盘上，**不要重写它**，只允许读取与在必要时微调（若你改了它，必须在回报里逐条说明改了什么、为什么）。
- 写集纪律：**只碰 `apps\desktop\**`**。不得碰 `packages\**`、`docs\**`、`AGENTS.md`、`reports\**`（除你自己要写的那一份回报）、`docs\relay*`、`docs\b8*`、`docs\incident-*`。**不得执行任何 git 写操作**（add / commit / checkout / stash / restore）。控制器负责提交。

## §1 必做条目（verifier 缺陷编号 → 动作）

### D1（阻断）· 目标文本常态可点击，直接进入就地编辑

- 现状（verifier 实测）：`apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart` 全文件 **0 处** `GestureDetector` / `MouseRegion`；就地编辑唯一入口是铅笔按钮；`:683` 的 `onTap: () => _toggle(goal.id)` 是展开/收起，不是编辑。
- 要求：**目标内容列的文本本身**可点击 → 直接进入就地编辑态（不点铅笔、不弹窗）。 Pencil 入口保留（不删）。
- 约束：`goal-blueprint-cell-{id}` 的**展开/收起语义必须逐字不变**（约 22 处既有断言依赖它，见 `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart` 与 `b10_blueprint_matrix_done_test.dart`）。因此文本点击必须挂在**文本节点**上，不能覆盖整格。
- 交付：为文本节点加一个稳定 `ValueKey`（建议 `goal-blueprint-goal-text-{id}`），挂点击 → 就地编辑。

### D2（阻断）· 新建目标不弹全量五字段表单

- 现状：`apps\desktop\lib\src\pages\goals_blueprint_page.dart:392-403` 新建仍走 `showGoalFormDialog(..., compact: true)`。
- 要求：新建路径**不得**弹出含标题/备注/关键词/领域/档位五个字段的全量表。走「行尾空可编辑行」或「只写 title 的快速通道」。
- 若你选「行尾空可编辑行」：该行必须是真实可输入控件（`TextField`/`EditableText`），不是静态文本。
- 领域与档位**不得丢**：新建时它们由所在格决定（`goal-blueprint-add-learning-short` 这类入口 key 已带领域+档位），必须仍然落库。verifier D-8-e 裁决原文：「领域（domain）与档位（horizon）**不要隐藏**」。
- 与 D3 联动：新建路径若复用同一个紧凑表单，则紧凑表单的形态由 D3 决定。

### D3（阻断）· 蓝图页表单字段简化 —— 采用**折叠式**，不删除

- 控制器裁决：verifier §2 认定 worker 的「会撕毁 D-8-e」理由**不成立**（T1/T2 是蓝图页自己的判据，不在「周/月页」保护范围内），且 `docs\b14-dispatch.md:178` 明确授权改既有测试口径并留档。
- 采用 verifier 推荐的**最小改法（折叠）**：
  1. `apps\desktop\lib\src\widgets\goals\goal_form_dialog.dart`：`goal-blueprint-form-note`（:228）与 `goal-blueprint-form-keywords`（:234）在 `compact == true` 时**折叠隐藏**（可用 `ExpansionTile` 或「展开更多」按钮），但**不删除字段**（`compact == false` 时行为逐字不变）。
     - 注意：`compact` 当前只控 `isDense`（:210）与内边距（:318-328），开关**空转** —— 这正是要修的点。
  2. `domain`（:240）与 `horizon`（:257）**保持渲染**，不折叠。
  3. `title`（:222）保持渲染。
  4. `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart` 的 **T1**（:214）改为：先点折叠头展开，再键入 note/keywords，**原有 SQLite 回读断言整条保留**（:282-299 那串 `expect` 一条不许删）。
  5. **T2**（:341）：note 预填断言若字段已折叠，同样先展开再断言，**不需要重写**。
  6. 周/月页调用点**一个字都不许改**（它们不传 `compact` ⇒ 走全量分支）。
- 硬约束：**不许删除任何既有测试来换绿灯**（R4）。只能改断言的**操作顺序**（先展开），不许删断言。

### D5（高）· DB 级断言：就地编辑只写 title

- 现状：`apps\desktop\test\b14_inline_edit_test.dart`（271 行 / 7 例）全文**零** `openDatabase` / `sqlite` / `GoalStore` 调用；「只写 title」只是注释里宣称。
- 要求：新增一条**回读 SQLite** 的用例，就地改 title 后断言：
  - `title` 已变（等于新值）；
  - `note`、`keywords`、`domain`、`due_date`、`period_end` **逐字未变**（与改前完全相同）。
- 复用 `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart` 里现成的建库/读库辅助（`_seed` / `_pumpBlueprint` / `_goalsByTitle` 之类，:40-110 区间有 `openDatabase` 与行映射），**不要另造一套**。

### D6（高）· 主题 chip 持久化用例

- 现状：`settings-accent` 在 `test/` 全量 grep **零命中**（只在 `lib\src\l10n\l10n_keys.dart:35-44` 与 `pages\settings_page.dart:225-253` 出现）。
- 要求：新增用例 —— `pump(SettingsPage)` → 点 `settings-accent-green` → **重建 provider 容器 / 重新读取偏好** → 断言持久化值仍为 `AppAccent.green`。
- 只测「key 存在」不算，必须验证**跨容器重建后仍在**。

### D7（高）· 活动标签文字对标签底色的对比度断言

- 现状：`apps\desktop\test\b14_theme_test.dart` 的 3 处 `_contrast` 断言是 ink/paper、meta/paper、ink/card，**没有一处是「标签文字 × 标签底色」**。
- 要求：补断言 `_contrast(标签文字色, 活动标签底色) >= 4.5`，**浅色态与深色态各一例**。
- 活动标签底色现为 `tokens.inkWash`（`goal_blueprint_matrix.dart:524`），标签条容器底色为 `tokens.paper`。两者都要覆盖。
- 判据数值必须**现算**，不许抄报告里的数。

### D9（中）· 光标置末，不是全选

- 现状：`goal_blueprint_matrix.dart:286` 的 `TextSelection` 范围是 `0..title.length`（全选）；`b14_inline_edit_test.dart` 的 I2-1 把「全选」写成了断言，**把偏离固化了**。
- 要求：改为**光标置末**（`TextSelection.collapsed(offset: title.length)`）。
- 同时**改掉 I2-1 那条把全选钉死的断言**（改断言不是删测试；若原用例名依赖「全选」字样，一并改名并在回报里说明）。

### D11（低）· 陈旧注释与实现自相矛盾

- 现状：`goal_blueprint_matrix.dart:446-455` 与 `:493-497` 的注释仍写「活动底 = `tokens.card`」，而实现已于 `:524` 改为 `tokens.inkWash`。
- 要求：把这两处注释改成与实现一致（写 `inkWash`）。

## §2 顺带做掉（低风险、同一写集内）

- **格式噪声剥离**（verifier §3 结论：先剥离再提交，不要另立格式批）：
  - `apps\desktop\lib\src\providers.dart`：`git diff` 显示 +183 / −137，但**真正新增只有 55 行、真正消失只有 20 行**（约 77–85% 是新版 `dart format` tall-style 的纯重排）。
  - `apps\desktop\lib\src\theme\app_theme.dart`：+99 / −88，真新增 18 / 真消失 8。
  - `apps\desktop\lib\src\pages\settings_page.dart`：+61 / −28，真新增 25 / 真消失 8。
  - `apps\desktop\lib\src\app.dart`：+23 / −16，其中 `accent` 相关只有 2 行，其余是 Ctrl+1..7 快捷键表重排。
  - `apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart`：+291 / −81，真新增 155 / 真消失 15，**主体是真实功能**（就地编辑 + 选中态），只需剥离纯重排部分。
  - 方法：把这些文件改回 HEAD 的**基线排版风格**（不要用新版 `dart format` 重排整个文件！**只对你自己新增/修改的代码段**手工对齐周围风格）。剥离必须**零信息损失**。
  - **剥离后的自检**：复跑 verifier §3 的「去空白行集合差分」，各文件「真正新增」应降到与真实功能改动同量级；若仍显著偏高，说明有未申报的功能改动，必须回头补判据。
  - 严禁对写集外文件做任何操作（上一棒曾误对整目录跑 `dart format` 后 `git checkout --` 还原 226 个文件，那等于批量覆盖他人写集，**绝对不要重演**）。

## §3 验收（控制器会亲跑，你也要自跑）

1. `flutter analyze` 必须逐字 `No issues found!`。
2. 全量 `flutter test --reporter compact` 必须 **`+1030 + 你新增的用例数`** 全绿，既有 1030 例**一个不少**。
   - 跑全量前先 `Move-Item apps\desktop\build\test_cache\build <改名>`（**不许删**）。
   - 必须在 `apps\desktop` 目录下跑（仓库根有 pubspec 但没有 `test/` 目录）。
3. 环境：镜像需进程内设置 `$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`；flutter 在 `F:\soft\flutter\flutter\bin\flutter.bat`。
4. **不许跑** `reports\task51-gate.ps1`（控制器在跑，会撞 test_cache 锁）。
5. 回报写到 `F:\soft\00selfmade\practilog\reports\task102-b14-fixup-report.md`（UTF-8，中文正文可以），必须含：
   - §0 落盘清单（`git status --porcelain -- apps/desktop` 逐字 + `git diff --stat -- apps/desktop`）；
   - §1 D1/D2/D3/D5/D6/D7/D9/D11 **逐条**的「改了什么 + 文件:行号 + 为什么 + 验证方式」；
   - §2 格式噪声剥离的前后量化对比（每个文件：剥离前 git diff +/- 与真正新增/消失，剥离后再算一遍）；
   - §3 门禁数字：`ANALYZE_EXIT` + 逐字 `No issues found!` 原文、`TEST_EXIT` + 全量末行原文 + 新增用例数；
   - §4 仍未解决的遗留（若有）+ 是否触碰过写集外文件的声明。
6. 回复正文只给：① D1/D2/D3/D5/D6/D7/D9/D11 各一句话结论 ② 噪声剥离量化一行 ③ 门禁末行原文 ④ 报告全路径。

## §4 禁止事项（逐条）

- 不得改 `packages\**`、`docs\**`、`AGENTS.md`。
- 不得改 `docs\relay*`、`docs\b8*`、`docs\incident-*`（并发接力链在制品）。
- 不得改 `reports\task51-gate.ps1`（门禁脚本，改它属人工验收点）。
- 不得执行任何 git 写操作。
- 不得删除任何既有文件或既有测试用例。
- 不得用新版 `dart format` 重排整个文件（会重演 D12 的高危操作）。
- 不得为了让测试通过而放宽断言（例如把 `>= 4.5` 改成 `>= 3`）。断言阈值按本派工书写死。
- 不得把 `goal-blueprint-cell-{id}` 的展开/收起语义改成别的。
