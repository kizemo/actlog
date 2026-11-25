# B7-W4 派工书：修 verifier 复核发现的 1 MAJOR + 2 MINOR

- 批次：Task 72 / B7 补充四需求
- 控制器会话：`mvs_2fe482da85314d7584b1abcdfc0d19d3`
- 上游证据：verifier 独立复核 `bg_8df2c4e0-4776-4d3c-863e-36643c078320`（`VERDICT=PASS_WITH_CONCERNS`，`CRITICAL=0`，`MAJOR=1`，`MINOR=4`）
- 设计真源：`docs\plan-goals-ui-batch7.md`；棒次台账：`docs\handoff-ledger-b7-w1.md` / `-w2.md` / `-w3.md`
- 规范真源：`AGENTS.md`（§2 铁律 R1–R8、§5 坑速查）

## 0. 开工前置（不可省略）

1. 完整读 `AGENTS.md`，再读 `docs\plan-goals-ui-batch7.md` 与 `docs\handoff-ledger-b7-w3.md`。
2. 读 `apps\desktop\lib\src\widgets\goal_upstream_panel.dart` 全文 —— 它是本棒的**正确范式参照**。
3. 读 `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart` 全文 —— 本棒主战场。
4. 工作区当前全部未提交（HEAD=`8c01455`）。**禁止** `git add` / `git commit` / `git push` / `git checkout` / `git restore` / 任何改写工作区的 git 操作。

## 1. 本棒要修什么（裁决 D-72-i）

### MAJOR-1（必修）周目标右栏把 loading 与 error 伪装成「暂无未完成目标」

- 现状（verifier 逐字定位）：`apps\desktop\lib\src\widgets\week_goal_rail_panel.dart:136-140`
  `asyncGoals.when` 的 `loading:` 分支与 `error: (Object _, StackTrace _)` 分支都返回
  `Text(t.goalsUpstreamEmpty, style: hintStyle)`，与 `data:` 分支真空态（`:141-148`，key `week-goal-empty`）
  在界面上完全不可区分，且错误对象被丢弃。
- 危害：需求 4 的右栏会先闪一帧、或在 drift 读库失败时长期停留在「暂无未完成目标」，
  用户据此误判「今天没有周目标可加」；数据库故障被静默吞成正常空态，事后无从排查。
- 判定依据：同批次 `goal_upstream_panel.dart:122-135` 对同类场景已做对**三态分离**
  （loading → `_PanelLoading`；error → key 含 `goal-upstream-error-` 的错误行；真空 → key 含 `goal-upstream-empty-`）。
  ⇒ 本缺陷是 `week_goal_rail_panel.dart` 单独实现的偏差，不是项目既有约定，不属「照旧」。
- 要求：
  1. `week_goal_rail_panel.dart` 的 loading / error / 真空 三态在**界面上可区分**，且 error 态**保留错误信息可见**（不丢弃对象）。
  2. 三态各自的 SemanticsKey/TestKey 命名与 `goal_upstream_panel.dart` 的既有风格对齐，新增 key 用 `week-goal-loading` / `week-goal-error` / 保留 `week-goal-empty`。
  3. 文案必须走 l10n getter，**禁止**在 Dart 里硬编码中文串。若 l10n 需要新增 getter，允许改 `apps\desktop\lib\l10n\**`（本棒豁免 W2/W3 的 l10n 禁碰令，理由见 §4）。

### MINOR-1（必修）拖拽协议字面量出现两份，违反 D-72-d「三层共用一个组件」

- 现状：`week_goal_rail_panel.dart:169` 手写 `data: 'goal://${goal.id}'`；而 `goal_upstream_panel.dart:24-27`
  已导出 `goalDragPayloadPrefix` 与 `goalDragPayloadFor(...)`，本文件未消费。
- 危害：日后改前缀漏一处 ⇒ `day_grid.dart` 的 `_onDrop` 用 `split(':')` 分流会**静默失效**。
- 要求：`week_goal_rail_panel.dart` 内**不得再出现** `'goal://'` 字面量，改为调用 `goalDragPayloadFor`。
- 不做：不要求把本面板整体重构为复用 `GoalUpstreamPanel`（今日右栏的写入通道、`WeekGoalPickDialog`、
  面板宽度契约与之不同，整体复用属架构改动，超出本棒范围）；只要求**协议常量单一来源**。

### MINOR-4（顺手必修，1 行级）`app.dart` `_NavIntent` 文档注释续行缩进错乱

- 现状：W1 新增的注释续行顶在列 0（verifier：`app.dart` `_NavIntent` 文档注释续行缩进错乱）。
- 要求：手工把该行缩进修正即可。**禁止**对本文件跑全文件格式化（会把无关行拉进 diff、放大写集）。

## 2. 明确不做（登记挂账，不得顺手改）

- MINOR-2 `Ctrl+7` 键条文字提示：控制器已裁「本批次不做」（要同改 `key_bar.dart` 与两份纯断言清单），**本棒禁止触碰** `key_bar.dart`、`test\shell_key_bar_test.dart`、`test\task64_nav_gear_test.dart`。
- MINOR-3 拖拽/右键在 provider 未就绪时静默无落库（`day_grid.dart:1282-1310`、`:1173-1196`）：窗口极窄，本棒**不改** `day_grid.dart`。
- MAJOR-1 的同类问题若出现在 `goal_upstream_panel.dart` 自身：verifier 已确认那里做对了，不要「顺手统一」。
- 不得改 `packages\**`（R1 铁律，越界即判红）。
- 不得删任何文件（R4）；不得改 `reports\task51-gate.ps1` 白名单（控制器专权）。

## 3. 写集（只允许这些路径出现改动）

| 路径 | 允许改动内容 |
|---|---|
| `apps\desktop\lib\src\widgets\week_goal_rail_panel.dart` | 三态分离 + 消费 `goalDragPayloadFor` |
| `apps\desktop\lib\l10n\**` | 仅新增错误态所需 getter（若确需） |
| `apps\desktop\lib\app.dart` | 仅 MINOR-4 那一行注释缩进 |
| `apps\desktop\test\task72_w4_*.dart` | **新建**测试（本棒唯一允许的测试落盘位置） |
| `apps\desktop\test\task72_w3_week_goal_rail_panel_test.dart` | 仅当三态 key 变化导致既有断言过期时，做**最小必要同步**，并在台账逐条说明理由 |

> 门禁白名单已覆盖 `apps/desktop/lib/src/widgets/week_goal_rail_panel.dart`、`apps/desktop/test/task72_*`、`docs/b71-dispatch-*`，本棒无需申请新条目。

## 4. 与 W2/W3 禁碰令的关系

W2/W3 派工书 §9 曾禁止碰 `l10n\**` 与 `providers.dart`，那是为**并行棒次**防撞车。本棒**单独串行**跑，
不存在并发写者，故 l10n 解禁；`providers.dart` 仍然**禁止改**（未完成口径已定案 D-72-c）。

## 5. 验收判据（逐条给证据，缺一不算完）

1. `cd apps\desktop` 后跑 `flutter analyze` ⇒ 期望逐字 `No issues found!`（R2，不许用「仅 info」放过）。
2. `flutter test --reporter compact` ⇒ **既有 903 条必须全绿**，本棒新增用例数 N 自报，终值 `903+N`，只增不减。
3. 判别性测试（本棒新增，必须先红灯再转绿）：
   - loading 态：渲染出的树里存在 `week-goal-loading`，且**不存在** `week-goal-empty`；
   - error 态：存在 `week-goal-error`，页面上能看到错误文案，且**不存在** `week-goal-empty`；
   - 真空态：`week-goal-empty` 仍成立（回归锁）；
   - 反查判据：`Select-String -Pattern 'goal://' -Path week_goal_rail_panel.dart` ⇒ **0 命中**。
4. `git status --porcelain -uall -- packages` ⇒ 必须返回**空**（R1）。
5. 本棒不得改四条需求的行为语义（只修状态呈现与协议单一来源）。

## 6. 交付形式

- 台账写入**新文件** `docs\handoff-ledger-b7-w4.md`（这是本棒唯一允许的文档写操作之一），含：
  改动清单 + 每条 MAJOR/MINOR 的修法与 file:line + 判据 1–5 的**原始输出** + 新增用例清单 + CONCERN/AMBIGUITY。
- 最终回答正文给出：`ANALYZE_VERBATIM=` / `DESKTOP_TESTS=` / `GOAL_SCHEME_LITERALS_IN_WEEK_PANEL=` / 新增用例数 / 未闭合项。
- 遇到写集冲突、契约二义性：**停下并在正文申报**，不要自行扩大范围。
