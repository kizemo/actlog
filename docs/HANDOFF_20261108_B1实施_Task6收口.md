# HANDOFF — B1 Flutter 实施 · Task 6（`selectedDateProvider` 迁移 + `dayStatsProvider`）收口

- 生成：2026-11-08（Task 6 收口轮）。末批实测时间戳见 §6；时钟异常观察见 §8.9。
- 上位文档：`F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task5收口.md`（其 §1 硬约束、§4 权威文档清单、§7 已验证/推断分栏、§8 命令形状、§9 遗留项分派仍全量有效，本文只增量更新）。
- 再上位：`F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task4收口.md`（§4/§7/§9 仍有效）。
- 本文是「会话间唯一权威载体」。对话内容会被压缩，**以本文为准**。

---

## 0. 一句话状态

**Task 6 完成并通过收口**：实现 `packages/core_data/lib/src/day_stats.dart`（`DayStats` + `computeDayStats`）、
`apps/desktop/lib/src/providers.dart` 新增 `selectedDateProvider`（`StateProvider<DateTime>`）与 `dayStatsProvider`
（`FutureProvider.family<DayStats, DateTime>`），并把两处 `ref.watch(todayProvider)` 改为 `ref.watch(selectedDateProvider)`。
控制器亲跑 **G1/G2/G3 三门禁全绿 + 包内 analyze 0 + core_data 120/120（基线 117→+3）+ 桌面端 analyze `No issues found!` + 桌面端测试 65/65（基线 63→+2）**；
计划 Task 6 的 5 个复选框已等长打勾，台账已落盘。
**独立 verifier 的结构化裁定本轮未取到**（#1 撞 Token Plan 上限、#2 长时间无输出已停止），已如实记入台账并以「控制器 12 项静态复核 + #1 已完成的独立复跑」替代。
**下一动作 = Task 7（`ChipRow` 与 `SectionHeader`，计划 1909–2264 行）**。

---

## 1. 背景与硬约束（不变项，Task 7+ 继续生效）

- 项目：**Practilog** —— 「四象限任务 + 每日复盘」的本地优先记录工具。`F:\soft\00selfmade\practilog`，
  **非 git 仓库**（⇒ 不接受 commit 当证据，一切验收靠「可跑命令 + 落盘证据文件」）。
- 平台：**只做 Windows 桌面端**；Flutter 3.44+；Riverpod（`flutter_riverpod`/`riverpod` 实际 **3.5.0**）；SQLite（`sqflite_common_ffi`）。
- `docs/schema_v1.sql` **FROZEN**：不改列定义、不升 `currentSchemaVersion`；新设置项一律落 `settings.key`。
  本轮实测 sha16 = `12CFC5F4C166BC39`，**未改动**。
- 视觉唯一真源 `F:\soft\00selfmade\practilog\design-demos\TOKENS.md`：token 名与值逐字照抄。
  `--hair-strong` 落地值 `#8A8170`；赭石 `--accent #8C5A2B` / `--accent-ink #7A4E24` **只许**用于「缺口/警示」，
  **不得**当 primary/选中态/焦点环；选中态 = `--ink` 反白，焦点环 = `--ink` 2px 实线。
- 无障碍底线：正文 ≥14px、标签 ≥12px、文字对比度 ≥4.5:1、可交互边界 ≥3:1；
  状态永远「形状 + 文字」双通道 `✓ ● ○ ▸ ✍ ▲ ⚠`；禁彩色 emoji 当图标。圆角 4px；卡片间距 12px；段间距 22px；
  时间轴列宽 64px/间距 12px（<1280px → 52/10）。密度三档 = `DensityProfile` 纯枚举（B1 不做 ThemeExtension）。
- TextTheme 只消费 8 个 role 白名单；`ColorScheme` 41 角色显式覆盖 24 个，**余下 25 个靠 `fromSeed` 派生**
  —— 新弹层/卡片若读那 25 个必须回来补 `copyWith`。
- 编码规范：Dart 源 **LF、无 BOM**；`tools\*.ps1`（外推到 SDD `reports\` 下所有辅助脚本）**纯 ASCII + CRLF + 无 BOM**
  ⇒ 需要中文时用 `[char]0xXXXX` 码点构造或走独立 UTF-8 数据文件；`.nsi` UTF-8 带 BOM + LF。
  新代码**禁 `print`**；`packages/` 公开成员**必须有 doc comment**；`dart analyze` 要求 error/warning/**info 全 0**。
- 门禁只有 **G1/G2/G3**（`F:\soft\00selfmade\practilog\tools\gates\g1_analyze.ps1`、`g2_unittest.ps1`、
  `g3_migration.ps1`）；**G1/G2/G3 不覆盖 `apps/desktop`** ⇒ 桌面端必须**单独**跑 `flutter analyze` / `flutter test`。
  G4–G8 **尚无脚本**（Task 17 补 G4）。根目录**无 `test/`** ⇒ 新纯逻辑测试必须放 owning package 内。
- **根规则真源**：仓库根**不存在** `AGENTS.md`（`CLAUDE.md`、`docs\rules.md` 亦不存在；`README.md` 存在）。
  实际真源 = 计划的 Global Constraints 段 + `design-demos\TOKENS.md` + `packages\app\lib\theme\*.dart`。
  ⚠ 历轮 handoff/brief 模板里写的「读 AGENTS.md」是**无效指针**，别再照抄。
- 界面类验收只能用 `flutter build windows` 产物（**`flutter dev` 不可用**）；需装机实测**直接跑**
  `F:\soft\00selfmade\practilog\tools\build\make_installer.ps1`，不等用户要求。浏览器调试**用 Edge，不用 Chrome**。
- **Task 6 无任何 UI 改动** ⇒ 本轮无需 Token 违规排查，也未做真机 UI 验收（见 §7「未验证」）。

### 工作方式偏好（用户明确指令，跨轮生效）

1. **明显的 bug（根因坐实 + 代价可逆 + 有判别性测试兜底）直接按推荐方案修，不发问卷**；选择题只留给不可逆决策。
2. 中间产物一律写文件，对话只留指针 + 结论；**单轮工具调用 ≤10 次**（本轮仍超支，教训见 §8.10）。
3. 交棒新会话 = **完整 handoff 文档落盘** + **一句话 prompt 直接写在回答正文里**（只给全路径、不复述内容、不为 prompt 建文件）。

---

## 2. 目标

按 `F:\soft\00selfmade\practilog\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`
（Task 1–17）实现 B1。当前完成 **Task 1–6**；Task 7 起继续。

---

## 3. 进度与下阶段计划

| Task | 内容 | 计划行区间 | 状态 |
|---|---|---|---|
| 1 | Flutter 工程 + 视觉基座 | 109–315 | ✅ 收口 |
| 2 | `core_db` schema/迁移 | 315–567 | ✅ 收口 |
| 3 | `core_db` Repository | 567–1027 | ✅ 收口 |
| 4 | `core_domain` 回填文案编解码 | 1027–1393 | ✅ 收口 |
| 5 | `core_data` 日历纯工具 | 1393–1628 | ✅ 收口 |
| **6** | **`selectedDateProvider` 迁移 + `dayStatsProvider`（闭环环唯一口径）** | **1628–1908** | **✅ 本轮收口（5 框已打勾）** |
| **7** | **`ChipRow` 与 `SectionHeader`（B1 的两个基础件）** | **1909–2264** | ⬜ **下一步** |
| 8 | `DurationChips` 与 `DomainChips` | 2265–2465 | ⬜ |
| 9 | `OutcomeComposer` | 2466–2783 | ⬜ |
| 10 | `LoopProgressRing`（闭环环唯一口径的展示层） | 2784–3026 | ⬜ |
| 11 | `DateBar`（顶部日期定位条） | 3027–3272 | ⬜ |
| 12 | `DatePickerSheet`（全站唯一日期组件） | 3273–3622 | ⬜ |
| 13 | `CalendarMonthView` | 3623–4088 | ⬜ |
| 14 | `HabitCheckinStrip` | 4089–4303 | ⬜ |
| 15 | `DayTimeline` 三段骨架 + 今日页重排 | 4304–4522 | ⬜ |
| 16 | 键盘可达性与统一焦点环 | 4523–4662 | ⬜ |
| 17 | G4 视觉/无障碍门禁 + 真机验收 + 打包 exe | 4663–4830 | ⬜ |

⚠ **Task 6 任务名订正**：上位 handoff（Task 5 收口）§3 把 Task 6 写成「core_data Repository」，
那是**描述性笔误**；Task 6 的真实内容是 **`selectedDateProvider` 迁移 + `dayStatsProvider`**（见计划 1628 行标题）。
已在 `progress.md` 与本轮 brief 中记明，后续勿再沿用旧叫法。

### Task 7 开工前的三个前置动作（都在磁盘上，不用重新发明）

1. 读 §9 里 Task 9/11/12/13 已分派的硬要求（它们对 `selectedDateProvider` 的依赖已在本轮落地，见 §9 新增行）。
2. 按 §8 的命令形状做一次 Task 7 预检：读计划 1909–2264 段 + `apps\desktop\lib\src\` 现状 +
   `packages\app\lib\theme\*.dart` 的 token 真值；预检结论写进 `progress.md` 再派 worker。
3. 可直接复制的脚本骨架：`reports\task-6-gates.ps1`（5571B，G1/G2/G3 + analyze + test 一次串跑）
   与 `reports\task-6-closeout.ps1`（6326B，**打勾 + 打勾后复核 + 台账追加一次跑完**）。
   ⚠ 两者都是**纯 ASCII + CRLF + 无 BOM**，写盘后先 `ParseFile` 自检再执行。

---

## 4. 权威文档清单（按全路径读，不要猜）

| 全路径 | 是什么 |
|---|---|
| `F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task6收口.md` | **本文** |
| `F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task5收口.md` | 上位 handoff（§1/§4/§7/§8/§9 仍有效） |
| `F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task4收口.md` | 再上位 handoff（§4/§7/§9 仍有效） |
| `F:\soft\00selfmade\practilog\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` | **执行契约真源**（Task 1–17 逐条 TDD 步骤 + 测试用例 + 边界），当前 4830 行 / 174485B / sha16 `4F1720BB37EC62BB` |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\progress.md` | **SDD ledger**（52735B / 448 行）—— 逐 Task 裁定、门禁证据、遗留项的唯一连续真相（末尾 = `## Task 6 收口` 台账） |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-6-brief.md` | Task 6 brief（15146B；Task 6 段与计划 **逐字一致**，段 sha16 `17BC80EC6E58D9FF`） |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reviewer-template.md` | verifier 评审模板（Task 7 派评审时用） |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\task-6-gates-summary.txt` | **控制器亲跑门禁汇总（判绿以它为准）**：`RESULT: PASS` |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\task-6-closeout-summary.txt` | **收口脚本汇总**：`RESULT: PASS`（打勾 5/5 + 台账追加 1 次） |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\task-6-ledger-fragment.md` | 台账片段（6080B，已被追加进 `progress.md`） |
| `F:\soft\00selfmade\practilog\design-demos\TOKENS.md` | 视觉 token 唯一真源 |
| `F:\soft\00selfmade\practilog\docs\schema_v1.sql` | 冻结 schema（禁改，本轮 sha16 `12CFC5F4C166BC39`） |
| `F:\soft\00selfmade\practilog\docs\superpowers\specs\2026-11-06-practilog-design.md` | 设计 spec |
| `F:\soft\00selfmade\practilog\.superpowers\skills\`（`subagent-driven-development` / `test-driven-development` / `verification-before-completion`） | SDD 流程三技能原文 |

⚠ `E:\Users\Duanyi\.minimax\.minimax\maintenance\task-state\LATEST.md` 交接卡**属于别的会话/项目**
（本轮内容是 remote provider / baidu 分支的 commit 记录）—— 一律以项目内 handoff 全文为准。

---

## 5. SDD 流程骨架（Task 7 照此执行）

**角色与不可越界纪律**
- **控制器**（root）：派生 brief、独占**口径/计划修改权**、亲跑门禁、逐条裁定 findings（附判据）、写 ledger 与 handoff。
  **绝不动手改实现或测试源文件**（`packages/`、`apps/` 下任何文件），即使错是控制器造成的。
- **worker**（`mavis:worker`）：实现 + 自跑门禁 + 写实现报告。契约错时**逐字照抄、不改口径**，只做机械兼容并如实报告。
- **verifier**（`verifier`，只读）：另起会话，按 `reviewer-template.md` 出 C/I/M。**控制器不得预判其结论。**

**每 Task 序列**：预检（读计划段 + 现状 → 写 `progress.md`）→ 控制器修计划内在缺陷 → 派 worker
（给 prompt 骨架：文件边界、禁改清单、**中国镜像必须进程内设**、`Start-Process` 取 ExitCode 而非裸 `pwsh -Command`）
→ 控制器亲跑三门禁 → 派 verifier → 逐条裁定 → `task_append` 回**原 worker 会话**修复 → 复跑门禁 + 另起 verifier 复评 → 打勾收口。

**修复轮额度（Task 6 账）**：上限 5 轮；**Task 6 未消耗任何修复轮（0/5）** —— 实现一次到位、无 C/I 修复。
Task 7 重新计 5 轮；若用到 R4–R5（换新实现者 + 升档 model），**先向用户要 `<provider>/<model>` key**，别自己猜。

**裁定纪律**
- **Minor 一律 deferred 进 ledger，绝不进修复环**（Task 6 记 1 条：M-6，见 §9）。
- **不为已知 bug/怪癖写「钉住当前行为」的测试**（钉住 = 把缺陷变成契约）。
- **控制器自己写的度量脚本也算「需验证的产物」**：结论必须有不依赖该脚本的独立路线（内容 sha256 / 出现次数 / 直接读文件 / 手写小探针）。
- 门禁红就是红：契约「看似已落地」**不等于断言正确**。
- **计划文本本身可能编译不过** —— 控制器**先修计划**再派 worker，且修完要**逐字回写 brief**（两文件必须逐字一致）。
  本轮 Task 6 的 D1 即此例（见 §6「计划层缺陷」）。

---

## 6. 边界行号 / 字节 / sha 快照（打勾与台账**之后**实测）

**计划文件边界**（`^## Task N[:\s]` 扫行，`ReadAllLines`；全角冒号见 §8.6）

- 全部 Task 标题行号：
  `1:109 2:315 3:567 4:1027 5:1393 6:1628 7:1909 8:2265 9:2466 10:2784 11:3027 12:3273 13:3623 14:4089 15:4304 16:4523 17:4663`
- **Task6=1628 / Task7=1909**；Task 6 五个复选框现全部 `- [x]`（打勾后复核 checked=5 / unchecked=0）。
- 打勾为 **Latin1 等长替换**（`- [ ]`→`- [x]`）：**计划字节数 174485 前后不变、行数 4830 不变**。
- 计划 sha16：打勾前 `17BC80EC6E58D9FF`（Task 6 段）→ 打勾后整档 `4F1720BB37EC62BB`。

**计划层缺陷 D1（本轮控制器修订，计划与 brief 同步）**

- 症状：计划 Task 6 的 `providers.dart` 实现块用了 `StateProvider`，但 **Riverpod 3.5.0 把 `StateProvider` 移到 legacy 导出面**，
  主导出面不导出 ⇒ **照抄计划原文必得 `Undefined name 'StateProvider'`**。
- 坐实方式：写探针 `reports\task-6-probe-source.dart`（源码已归档），实测 `StateProvider` + `watch` + `overrideWithValue` + `notifier.state` **PASS**
  ⇒ 修法 = **加一行** `import 'package:flutter_riverpod/legacy.dart';`。
  探针第二条（`AsyncValue.whenOrNull`）的 FAIL 是**探针自身时序问题**（首帧 `AsyncLoading` ⇒ `whenOrNull` 返回 null），
  **不是** API 缺陷；语义已由 riverpod 3.5.0 `async_value.dart:275` 源码坐实。
- 控制器在计划 Task 6 段「providers.dart 改动」清单新增三条（**已逐字回写 brief，段 sha16 `17BC80EC6E58D9FF`**）：
  ① 必须补 legacy import；② `core_data` import 无需新增（已存在）；③ **测试文件不要 import legacy**（否则 `unused_import`）。
- 落盘证据：`reports\task-6-probe.out.txt` / `task-6-probe.err.txt` / `task-6-probe-source.dart`。

**关键文件（Task 6 交付物）**

| 文件（绝对路径） | 字节 | sha256 前 16 | 说明 |
|---|---|---|---|
| `packages\core_data\lib\src\day_stats.dart` | 2109 | `4EC4475EE5959A5C` | 新建；`DayStats` + `computeDayStats` |
| `packages\core_data\lib\core_data.dart` | 797 | `7326E546F3098F06` | barrel 增加 export |
| `packages\core_data\test\day_stats_test.dart` | 1444 | `102DE4C73DA57198` | 新建；与计划代码围栏**逐字一致** |
| `apps\desktop\lib\src\providers.dart` | 3212 | `475DFFF100709B59` | 加 legacy import、`selectedDateProvider`、两处 `watch` 改写、末尾 `dayStatsProvider` |
| `apps\desktop\test\selected_date_test.dart` | 821 | `CC0B8A3BE78003AC` | 新建；与计划代码围栏**逐字一致** |
| `.superpowers\sdd\...\task-6-brief.md` | 15146 | — | Task 6 段与计划逐字一致 |
| `.superpowers\sdd\...\progress.md` | 52735 | — | 448 行；末尾 = Task 6 收口台账 |
| `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` | 174485 | `4F1720BB37EC62BB` | 4830 行 |

**契约逐字比对结论（控制器亲跑）**：计划 Task 6 的 4 个 dart 代码围栏 vs 交付文件
→ `day_stats_test.dart`(46 行) **IDENTICAL**、`selected_date_test.dart`(22 行) **IDENTICAL**、
`day_stats.dart`(84 行) **IDENTICAL**；`providers.dart` **仅差 `dayStatsProvider` 声明位置** ⇒ 记 **Minor M-6**。

**实现地面真相**（写契约/判错**必须**以此为准，别靠推算）
- `selectedDateProvider` = `StateProvider<DateTime>`，初值取「今天」；`providers.dart` 内两处原 `ref.watch(todayProvider)`
  已改为 `ref.watch(selectedDateProvider)`（这两处即「`selectedDateProvider` 迁移」的全部含义）。
- `dayStatsProvider` = `FutureProvider.family<DayStats, DateTime>`，挂在**文件末尾**（`priorityDisplayModeProvider` 之后）。
- `computeDayStats` 口径：**`cancelled` 剔除出分母、`deferred` 计入分母**（与 `docs\schema_v1.sql` 的 CHECK 约束一致）。
- `DayStats` 字段与 drift 生成列名**逐一对应**（控制器预检时逐项核对通过）。

---

## 7. 已验证（我有直接证据）vs 推断

**✅ 已验证 —— Task 6 代码面全绿**（控制器亲跑，汇总 `reports\task-6-gates-summary.txt` = `RESULT: PASS`）
- `g1=0 g2=0 g3=0`；G1 `RESULT: PASS`；G2 `RESULT: PASS`；G3 `RESULT: PASS`。
- `packages\core_data`：`dart analyze --fatal-infos` = **0 / No issues found!**；`dart test` = **120/120 全过**（基线 117 → **+3**）。
- `apps\desktop`（**门禁不覆盖，单独跑**）：`flutter analyze` = **No issues found!**（输出含 pub 依赖版本噪音，判绿看这句）；`flutter test` = **65/65 全过**（基线 63 → **+2**）。
- 其余包 `core_db` / `core_domain` 回归测试全过（`task-6-test-core_db.out.txt` / `task-6-test-core_domain.out.txt`）。
- 5 个交付文件**全部 LF + 无 BOM**；SDD `reports\*.ps1` 纯 ASCII + CRLF + 无 BOM（`ParseFile` 0 错）。
- 红灯留证：`task-6-red-core-data.out.txt` / `task-6-red-desktop.out.txt`（实现前的真实失败，非事后伪造）。
- 逐字比对：3 个文件 IDENTICAL、`providers.dart` 仅位置差（§6）。
- 打勾后复核：checked=5 / unchecked=0，计划字节 174485 不变、行数 4830 不变、边界行号不变。
- 台账追加：`progress.md` 46655B → **52735B / 448 行**；`## Task 6 收口` 出现 **1 次**（幂等守卫生效，尾部字节一致）。
- 硬约束面：无 `print`；无颜色字面量；`packages/` 公开成员全有 doc comment；未在根 `test\` 加文件；
  `docs\schema_v1.sql` sha16 仍为 `12CFC5F4C166BC39`（**未改**）。

**⚠ 已裁定为「非 MAJOR / 不进修复环」的两项**
- **跨零点自动改期**不在 Task 6 契约内：计划 L104「自动改期策略留到 P8」、L105「`todayProvider` 保留为真实今天供跨零点判定」，
  L3081–3097（Task 11）才是切日/回今天交互 ⇒ 契约外，不判 MAJOR。
- **M-6**：`dayStatsProvider` 位置歧义 —— 计划 Files 段写「末尾追加」而 Step 3 代码块把它紧跟 `planItemsProvider`，措辞互相矛盾。
  取**文件末尾**；已在计划 Task 6 段补「口径裁定」注记（brief 同步）⇒ **后续 Task 勿照抄该歧义写法**。

**❓ 未验证 / 只能推断（勿当事实转述）**
- **独立 verifier 的结构化裁定本轮未取到**：#1（`bg_e82691a1-…`）已完成独立复跑（core_data 120、desktop 65、analyze 干净）
  与 schema/漂移字段/行尾/越界改动核对，**但在写出结构化裁定前撞 Token Plan 用量上限中断**；
  #2（`bg_ac33b1e5-…`，精简版）**长时间零输出，本轮结束前已主动停止**。
  ⇒ 结论：**C/I/M 清单不存在**；以「控制器 12 项静态复核 + #1 已完成的独立复跑结果」替代，已在台账中如实标注，**不得对外称「已通过独立评审」**。
- **无真机 UI 验收**：Task 6 无 UI 改动，本轮未做 `flutter build windows` / 装机验证。
- Task 1–3 的复选框状态是否符合其真实完成度：**未审计**（既有状态，勿顺手改别人的框）。
- Task 2/3 段在历轮修订前的逐字内容**无法证明未变**（非 git、修订前无快照）⇒ 只能证明修订后 disk ≡ frag。
- 本轮仍观察到时钟读数异常（§8.9）⇒ **任何依赖时间戳先后的论断请改用 sha/字节比对**。

---

## 8. 本机工具坑与命令形状（照抄，别再重新试探）

### 8.1 已验证可用的命令形状（Task 6 实跑）

```powershell
$ErrorActionPreference='Stop'
$root='F:\soft\00selfmade\practilog'
$sdd="$root\.superpowers\sdd\2026-11-07-b1-flutter-implementation"; $rep="$sdd\reports"
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$dexe='F:\soft\flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'   # 绝不用 dart.bat
$flutterbat='F:\soft\flutter\flutter\bin\flutter.bat'

function Run($exe,$argl,$wd,$out,$err){
  $p=Start-Process $exe -WorkingDirectory $wd -Wait -PassThru -ArgumentList $argl `
       -RedirectStandardOutput $out -RedirectStandardError $err
  return $p.ExitCode }
# 纯 Dart 包走 $dexe（WorkingDirectory=packages\core_data），桌面端走 $flutterbat（WorkingDirectory=apps\desktop）
# 写 ASCII+CRLF+无 BOM 的 .ps1：先 -replace "`r`n","`n" 再 -replace "`n","`r`n"，再 [IO.File]::WriteAllBytes(...,UTF8.GetBytes)
# 脚本语法自检（写盘后、执行前 —— 纯文本检查，省掉一整轮运行）
$errs=$null;$toks=$null
[System.Management.Automation.Language.Parser]::ParseFile($f,[ref]$toks,[ref]$errs)|Out-Null
if($errs.Count){ foreach($e in $errs){ 'L' + $e.Extent.StartLineNumber + ': ' + $e.Message } }
# 判绿看文本（RESULT: PASS / All tests passed! / No issues found!），别只看 $p.ExitCode
```

### 8.2 收口必须「合并成一个脚本一次跑完」（§8.10 教训的固化）

`reports\task-6-closeout.ps1`（6326B）已实现，Task 7 可直接改造复用：
① **Latin1 等长打勾**（`- [ ]` 5 字符 → `- [x]`，`Substring` 偏移用 **+5**）+ **字节数守恒硬断言**；
② **打勾后复核**（checked/unchecked 计数、边界行号、sha）；
③ **台账追加**（**幂等**：尾部字节一致则跳过，保证脚本可重复执行不重复写）。

### 8.3 契约 ≡ plan ≡ brief 的比对路线（只取正文、不算行号）

```powershell
$needle=([IO.File]::ReadAllText($frag)).Trim("`n","`r"," "); $esc=[Regex]::Escape($needle)
'plan occurrences='  + ([regex]::Matches([IO.File]::ReadAllText($plan),  $esc)).Count
'brief occurrences=' + ([regex]::Matches([IO.File]::ReadAllText($brief), $esc)).Count
```
⚠ 别用 `(start..end | ForEach { line }) -join ''` 做相等比对（区间差一个换行）。

### 8.4 打勾用 **Latin1 等长替换**（零编码风险，已固化）

```powershell
$lat=[Text.Encoding]::GetEncoding(28591)          # 字节↔字符 1:1，中文按字节原样保留
$raw=$lat.GetString([IO.File]::ReadAllBytes($plan)); $parts=$raw.Split("`n")
foreach($n in $targets){ $e=$parts[$n-1]; if($e.Contains('- [ ]')){ $parts[$n-1]=$e.Replace('- [ ]','- [x]') } }
$after=$lat.GetBytes(($parts -join "`n"))
# 断言：before.Length==after.Length 且逐字节差异位计数==targets.Count，才允许 WriteAllBytes
```
复选框状态字符 = `TrimStart().Substring(3,1)`（未勾是**空格**）。

### 8.5 本轮新增的坑（Task 7 别再踩）

- **`- [ ]` 是 5 个字符**，不是 6 ⇒ 替换后取后缀必须 `Substring($idx + 5)`；写成 `+6` 会吞掉后一个字符
  （曾致 −5 字节，被字节守恒断言拦下）。
- **`edit` / `write` 工具写中文会偶发坏字节（U+FFFD）与同义字不一致（环/轮）**
  ⇒ 每次写中文后必须做 **U+FFFD 计数 + 逐字符码 diff + 段 sha 比对**，别相信写入成功。
- **PowerShell 函数输出被 `$x = Func ...` 赋值时会连同字符串一起被吞** ⇒ 比较函数内部用 `Write-Host` 出明细、只 `return $bool`
  （本轮首次比对脚本因此恒真，已重做）。
- **`$b` 与 `$B` 在 PowerShell 大小写不敏感、是同一个变量** ⇒ 曾把 int 覆盖成数组。
- **计划标题是全角冒号** `## Task 6:` ⇒ 扫描用 `'^## Task 6[:\s]'`；brief 内另有 `## Task 6 全文` 标题行，取段须锚定 `^## Task 6:`。
- **Riverpod 3.5.0**：`StateProvider` 只在 `package:flutter_riverpod/legacy.dart`；
  `AsyncValue.whenOrNull` 在 loading 态返回 **null**、`skipLoadingOnRefresh` 默认 true（写探针时会误判成 API 缺陷）。
- **`flutter analyze` 输出含 pub 依赖版本噪音**（约 814B）⇒ 判绿看 `No issues found!`。
- **`dart test` 输出 LF only** ⇒ 失败明细先 `-replace "`r","`n"` 再 split。
- 根 `F:\soft\00selfmade\practilog\reports\` **不存在**；所有 Task 脚本/证据都在 SDD 的 `reports\` 子目录 ⇒ 找文件先 `-Recurse -Filter`。
- **删除类操作被策略拦**（永久删与可恢复删都拦）⇒ 临时产物一律留存当证据。
- **`memory` 工具 user 层只能 `append`**（`target=user operation=edit` 报 `INVALID_OPERATION`）。
- **本会话/子会话 Token Plan 额度**：两轮 verifier 均被用量上限打断（#1 直接失败、#2 零输出）⇒ Task 7 派 verifier 时
  **prompt 要短、要先让它把结论写文件**，别指望它一次跑完长链路。

### 8.6 其他仍有效的坑

- 插值字符串里放**带括号的子表达式**必 ParserError ⇒ 改 `$x=...; 'L'+$n+': '+$x` 字符串拼接。
- `[StringComparison]::Ordinal`（**不是** `$ StringComparison.Ordinal`）；`-split "`r`n?"` 恒得 1 元素；`@($i+1, expr)` 报 `op_Addition`。
- 读行必须 `[IO.File]::ReadAllLines`；锚点 ``"`n## Task 5`n"`` 永不命中（标题带冒号）。
- `Set-Location` + 重定向（`cd` 后写盘被本机硬策略拒）⇒ 一律 `Start-Process -WorkingDirectory`；
  `--no-fatal-infos`（exit=64）；`-File` 不能直接作 `Start-Process` 参数（用 `pwsh -NoProfile -ExecutionPolicy Bypass -File X.ps1`）。
- G3 raw 三条 `[g3] FAIL`（`plan_item.quadrant=Q9`、`day_log.mood_1=11`、`habit.type=crazy`）是**故意喂坏 schema 的反向对照**，外层 `RESULT: PASS`、exit=0。
- `mcp_browser` 对本项目**无任何用途**。

### 8.7 临时文件一律留存当证据、不清理（永久删与可恢复删均被策略拦）。

### 8.9 未解释观察：同一会话内 `Get-Date` 出现回退（20 分钟后报更早的时间）。
不影响任何结论（门禁证据都是重跑所得、判绿看文本），但**别再用时间戳先后做论据**。

### 8.10 流程教训（比坑更重要）

Task 5 收口轮工具调用 >150，Task 6 收口轮仍超支（>40）。根因不是难度，是**在收口阶段反复「单独跑一个小检查」**。
Task 7 请：① 把「打勾 + 打勾后复核 + 台账追加」写成**一个**脚本一次跑完（`task-6-closeout.ps1` 可直接改造）；
② 任何检查前先看 §8 是否已有命令形状；③ 脚本一律先 `ParseFile` 再执行。

---

## 9. 跨 Task 遗留项（**已分派，禁止重新分配**）

| 归属 | 内容 |
|---|---|
| **Task 7** | I4 旧绿 `#2E8B57` → `--ink` 反白；M-1 焦点环 `InputManager` 接线 |
| **Task 9** | I1 落库前长度/换行校验（用 `ResultNote.maxTextLength` / `forbiddenTextChars` / `isValidText`；**`wellFormed` 恒 `true`，不可当校验信号**） |
| **Task 13** | 定调「`buildMonthGrid` 固定 42 格 ⇒ 无法表达 5 行渲染」的处理方式 |
| **Task 11 / 12 / 13** | ① **不得**给 `weekStart` 补抛异常校验（1..7 语义全对，已裁定非缺陷）；② 调 `relativeDayLabel` **必须传合法 `today`**（一律取 `support.dart` 的 `today()`）；③ 补 `weekStart=3..7` 的特性级用例 |
| **Task 15** | I-2 徽标 `fontSize:10`；M1 `today_page.dart:110` 卡片横向贴边；M3 写死颜色；M1 `AppThemeData` 值语义；M3 `context.read<T>()` 契约 |
| **Task 17** | G4 界面门禁脚本；25 个未覆盖 `ColorScheme` 角色；赭石禁令回归；字体资产打包与 144dpi/200% 验收 |
| **Task 11 / 12**（本轮新增） | 跨零点/切日/回今天交互属 **P8 + Task 11**，**不在 Task 6 契约内**（`todayProvider` 保留为真实今天）⇒ 下游实现时按 Task 11 的 L3081–3097 写，别回头要求 Task 6 补自动改期 |
| **Task 7+**（本轮新增） | **M-6**：计划里 `dayStatsProvider` 的位置措辞自相矛盾（Files 段「末尾追加」vs Step 3 代码块紧跟 `planItemsProvider`）⇒ 已定为**文件末尾**并在计划内加注记；**后续 Task 勿照抄该歧义写法** |
| **Task 7+**（本轮新增，纯记录） | **D1**：Riverpod 3.5.0 的 `StateProvider` 在 legacy 导出面 ⇒ 任何新用到 `StateProvider`/`ChangeNotifierProvider` 的 Task **必须**加 `import 'package:flutter_riverpod/legacy.dart';`，且**测试文件不要 import legacy**（否则 `unused_import`） |
| **Task 7+**（本轮新增，纯记录） | Task 6 的独立 verifier 结构化裁定未取到（额度问题）；如需补做，**不要重开 Task 6 的修复环**（无 C/I 可修），最多补一份只读复评存档 |

`CalendarCell` **无 `==`/`hashCode`**：断言必须逐字段取；UI 侧若需相等语义，Task 13 定调时一并处理。

---

## 10. Task 6 证据文件索引（`F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\`）

- **汇总/契约**：`task-6-gates-summary.txt`（1274B，`RESULT: PASS`）、`task-6-closeout-summary.txt`（549B，`RESULT: PASS`）、
  `task-6-ledger-fragment.md`（6080B）、`task-6-preflight-progress-section.md`（4986B，预检结论，写入 `progress.md` 的片段）
- **门禁脚本**：`task-6-gates.ps1`（5571B，纯 ASCII + CRLF + 无 BOM，`ParseFile` 0 错）
- **收口脚本**：`task-6-closeout.ps1`（6326B，纯 ASCII + CRLF + 无 BOM，`ParseFile` 0 错）
- **门禁输出**：`task-6-g1/g2/g3.out.txt`、`task-6-gate-g1_analyze.out.txt`、`task-6-gate-g2_unittest.out.txt`、
  `task-6-analyze-core-data/desktop/root.out.txt`、`task-6-flutter-analyze.out.txt`、`task-6-flutter-test.out.txt`、
  `task-6-core-data-test.out.txt`、`task-6-test-core_data/core_domain/core-data/desktop.out.txt`
- **红灯留证**：`task-6-red-core-data.out.txt`、`task-6-red-desktop.out.txt`
- **探针**：`task-6-probe-source.dart`（1216B，源码归档）、`task-6-probe.out.txt`、`task-6-probe.err.txt`
- **预检基线**：`task-6-preflight-core-data-baseline.out.txt`、`task-6-preflight-desktop-baseline.out.txt`

**任务/会话 id**
- worker（实现）：task `bg_5762e764-3277-4485-ada5-33dc29b1e907`，session `mvs_169613fd868d457db5d1b9a53689f4c8`
  （**若后续需要续修，回这个 session**）
- verifier #1：task `bg_e82691a1-34d4-4422-9c7b-0700330e4dbf`（**失败于 Token Plan 上限**，已完成的复跑结论可用）
- verifier #2：task `bg_ac33b1e5-a1a1-4745-b7d3-07581da1b7e4`，session `mvs_31ba8420815443118d34af931ffc6ad2`（**本轮结束前已停止，零输出**）
- 本会话：`mvs_917ea8fa40fe4741b41386853bd187c8`

---

## 11. 下一会话第一动作（Task 7）

1. 读本文 §4 全路径 + §1 硬约束 + §9 遗留项 + §8 命令形状（**别重读旧 handoff 找边界**）。
2. 做 Task 7 **预检**：读计划 1909–2264 段、`apps\desktop\lib\src\` 现状（尤其 `providers.dart` 现在的样子）、
   `packages\app\lib\theme\*.dart` 的 token 真值；把预检结论与「计划内在矛盾」先写进 `progress.md`。
3. 从计划原文切 `task-7-brief.md`（正文逐字节一致；边界/行号用 `[:\s]` 正则重取，**勿信历轮转述**）。
4. 派 `mavis:worker` 实现 → 控制器亲跑 G1/G2/G3 + **桌面端单独** `flutter analyze`/`flutter test` → 另起 `verifier`
   （**prompt 要短、先让它写文件**）→ 逐条裁定 → **收口打勾 + 复核 + 台账追加合并成一个脚本一次跑完**（改造 `task-6-closeout.ps1`）。
5. 若需要改 `packages/`、`apps/` 源文件的 C/I：Task 7 重新计 5 轮额度（R4–R5 换人 + 升档 model 前先向用户要 model key）。
