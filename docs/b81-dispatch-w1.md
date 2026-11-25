# B8-W1 派工书 —— 07 蓝图页获得目标编辑能力（新建 / 编辑 / 删除）

派工人：控制器（会话 `mvs_2fe482da85314d7584b1abcdfc0d19d3`）｜ 承接人：`worker`
上游真源：`docs\plan-goals-ui-batch8.md`（**必须先完整读完**，本派工书与它冲突时以它为准）

---

## 0. 开工前必读（按顺序，缺一不可）

1. `AGENTS.md` —— 全文。重点 §2 铁律 R1–R8、§3 验证装置地图、§5 本机工具坑、§6 权威导航、§7 状态快照。
2. `docs\plan-goals-ui-batch8.md` —— 本棒设计真源（§2 现状事实 / §3 裁决 / §5 判据）。
3. `docs\b8-scope-decision.md` —— 用户原则逐字与 B8 范围裁决。
4. `docs\handoff-b7-live-acceptance.md` §七 —— 上一轮真机验收结论与取证纪律（尤其 7.3 取证纪律）。
5. `docs\b71-dispatch-w4-fix.md` + `docs\handoff-ledger-b7-w4.md` —— 派工书与台账的**体例参照**。

## 1. 铁律（违反即返工）

- **R1**：控制器不改产品代码，你也是**只在写集内**改；写集外一律只读。
- **R2 门禁硬判据**：逐包 `analyze` 必须逐字 `No issues found!`；desktop 测试**精确等值**，
  跑门禁**必须显式** `-ExpectDesktopTests <基线+本棒新增>`（§5 坑 86，不传就误判）。
- **R4**：不删文件。要挪走用 `Move-Item`（控制器侧被网关拦，worker 侧按实际策略处理；优先「改写」而非「删除」）。
- **R5**：凡进台账的具体值（行数/测试数/sha/包名）**必须当场盘上回读**；列名一律以 `PRAGMA table_info` 为准。
- **R7**：文件不出本项目目录，不执行其它项目的任务。
- **TDD**：每条需求先写**判别性测试**跑出**红灯**，把红灯原文记进台账，再改码转绿。
- **证据纪律**：写库类判据必须回读 SQLite，「没报错」不算证据。
- **镜像必须进程内设置**（§5）：
  `$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`
- 跑全量前先处理 `apps\desktop\build\test_cache\build`（§7：否则 OS Error 183 挂死）。

## 2. 写集（**唯一允许你写入的位置**）

允许**修改**：
- `apps\desktop\lib\src\pages\goals_blueprint_page.dart`
- `apps\desktop\lib\src\l10n\parts\goals.dart`
- `apps\desktop\test\task66_goals_blueprint_page_test.dart`（补断言，不要削弱既有断言）
- `apps\desktop\test\blueprint_page_test.dart`（同上）

允许**新建**：
- `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart`（本棒判别性测试主战场）
- `apps\desktop\test\golden\` 下如需要的**新**金标（若既有金标因新增控件必然变化，
  变化必须在台账里逐条说明原因，禁止静默重录）

允许**新建台账**（交接必需）：
- `docs\handoff-ledger-b8-w1.md`

**禁止改动**（本棒明确不动，越界即返工）：
- `packages\**`（`GoalStore` 已够用，见 §3 事实 1）
- `apps\desktop\lib\src\data\goal_store.dart`
- `apps\desktop\lib\src\providers.dart`（若确实需要新 provider，先只做**加法**并在台账说明；优先不加）
- 今日页 / 时间轴 / 右键菜单 / 快捷记录（那是 **B8-W3** 的活）
- 月页 / 周页 / 年页（那是 **B8-W2** 的活）
- `AGENTS.md`、`docs\relay*`（属另一条链）

## 3. 现状事实（我已取证，可直接依赖；`file:line` 为当前 HEAD `9684268`）

1. 本页**已有写库先例**，复用它的范式：
   `goals_blueprint_page.dart:310 void _addSplit(GoalRow goal)` → `:327 store.repos.todo.create(title: title)`，
   配 `_saved:104` 状态 + `:293-296` 的 `ValueKey('goal-blueprint-todo-saved')` 成功反馈。
2. 取数口径：`:149-172` 按 `projectDomainKeys × GoalBlueprintMatrix.horizons` 建矩阵，
   入格条件 `:157-165` = `goal.domain == domainKey && goal.horizon == horizon`（`near` 额外并入一桶）。
   **不得改变这个归属口径**（D-8-f，`:12` 注明与年页同一份数据源）。
3. `domain` 取值域注释在 `goal_store.dart:400-402`：`career/wealth/family/learning/social/health`，
   留空 = 未分类，DB 列无 CHECK 约束。
4. 写通道签名（`apps\desktop\lib\src\data\goal_store.dart`）：
   - `Future<String> createGoal({required GoalKind kind, required String title, String? note, String? keywords, String? parentId, String? domain, GoalHorizon? horizon, GoalFacet? facet, int periodStart = 0, int? periodEnd, int? dueDate, Quadrant? quadrant, PriorityAbc? priorityAbc, GoalStatus status = GoalStatus.active, int? selfScore, String? reviewNote, String? improveNote})` @ `:403`
   - `Future<void> updateGoal(...)` @ `:498`（用法参照 `test\task65_data_goals_test.dart:74/81`）
   - `Future<void> deleteGoal(String goalId)` @ `:616`
   - `Future<GoalRow?> findGoal(String goalId)` @ `:642`
5. 已知 UX 洞（本棒要修的主症状）：蓝图页**没有任何地方能设 `domain`/`horizon`**
   ⇒ 在蓝图页新建的目标自己看不见（矩阵不入格）。上一轮真机就撞到这个现象。
6. 空态文案 `goal-blueprint-empty` 见 `blueprint_page_test.dart:91-96`；矩阵格 key 命名规律
   `goal-blueprint-cell-<domain>-<horizon>`（`blueprint_page_test.dart:88`）。

## 4. 本棒要做成什么（范围 = B8① 的蓝图页部分）

在 07 蓝图页内直接完成目标本体的编辑，**不再绕到日志页填**：

1. **格内新建**：每个 `domain × horizon` 格子提供「+ 新建目标」入口；新建时
   `domain` 与 `horizon` **由所在格子自动预填**，且表单里可见、可改（D-8-e）。
2. **卡片编辑**：目标卡上提供编辑入口，可改 `title / note / keywords / domain / horizon / facet /
   dueDate / priorityAbc / quadrant`（至少覆盖这些；其余字段可后置）。
3. **删除**：目标卡提供删除入口，**必须二次确认**（确认弹层，取消=库零变化）。
4. **写库全走 `GoalStore`**（D-8-d）：`createGoal` / `updateGoal` / `deleteGoal`。
   禁止直连 DAO 或写裸 SQL；禁止为了「方便」在 `goal_store.dart` 加新方法。
5. **操作后页面必须立刻反映**：新建/编辑后目标出现在正确的格子；删除后从格子消失。
   若需要刷新 provider 才能生效，用 `ref.invalidate(...)` 之类的现有机制，并在台账说明选了哪种。
6. **成功/失败都要有可见反馈**，沿用本页 `_saved` 的范式；失败不得静默。
7. `l10n` 新词条一律加在 `src\l10n\parts\goals.dart`，**中英都要有**（照该文件既有体例）。

## 5. 判别性测试要求（先红后绿）

至少覆盖，且**每条都要先跑出红灯**：

| 测试 | 判别点 |
|---|---|
| T1 | 蓝图页某格「+ 新建」提交后，回读库中该 goal 的 `domain`/`horizon` **等于所在格子**，且页面立即出现在该格 |
| T2 | 编辑目标改 `title` 后，回读 `goal.title` 已变，且**不新建行**（`COUNT(*)` 不变） |
| T3 | 删除需确认：弹层选「取消」⇒ 库零变化（`COUNT(*)` 不变）；选「确认」⇒ 行消失 |
| T4 | 表单必填校验：`title` 空 ⇒ 不写库（回归防线，参照 `:310` 既有实现有没有这层） |

⚠️ 列名先 `PRAGMA table_info(goal)` 再写 SQL（R5）：已知 `goal` 表**无 `origin`、无 `source_goal_id`**。

## 6. 收尾（必须全部完成才算交棒）

1. 跑门禁并把输出落盘：
   `pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests <907+N>`
   期望 `GATE_VERDICT=PASS`；回读 `reports\task51-gate\summary.txt` 取真值（勿凭记忆）。
2. 写 `docs\handoff-ledger-b8-w1.md`：目标 / 已完成 / **实测数字（盘上回读）** /
   红灯原文 / 文件清单 / 已知遗留 / 下一步建议 / **接力 prompt**。
3. 提交一笔 `feat(goals): B8-W1 ...`（**新文件必须 `git add`**，§5 坑 82；
   不要把 `AGENTS.md` 或 `docs\relay*` 混进本笔，§5 坑 97）。
4. 最终汇报里给出：commit 短哈希、`DESKTOP_TESTS` 实际值、四条判别性测试的绿证、
   以及你**没有做到**的部分（不许粉饰）。

## 7. 已知坑（省下你的试错时间，全部实测过）

- `pubspec.lock` 会显示假 ` M` → 用 `git add --renormalize`（§5 坑 96）。
- `git commit -F -` 不吃 stdin（§5 坑 6）。
- PowerShell 里不要用 `python -c` 内联多行代码（转义会炸），落成 `.py` 文件再跑。
- 写文件用专用写工具；用 `[IO.File]::WriteAllText(path, byte[])` 会把字节写成
  **空格分隔的十进制串**，文件膨胀 3.8–4 倍。要按字节写就用 `WriteAllBytes`。
- `git grep -n ... | ForEach-Object { $_ }` 才能看全输出；`Select-String -Path '<dir>\**\*.dart'` 不递归。
- 驱动/取帧类判据前先查锁屏：`Get-Process LogonUI`（命中就停下来要人解锁）。
