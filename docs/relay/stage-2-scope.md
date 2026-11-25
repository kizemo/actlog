# 第 2 环交付 · 下一批次范围定稿 + W9 残留 l10n 化可派工清单切分

| 项 | 值 |
|---|---|
| 环次 | stage 2（`type = read_only_scope_finalize`） |
| 会话 | `mvs_72a8f0c1713144d6b060cf2d316a953f`（createdBySessionId = `mvs_f0f4b5b2d4804d3fabd8f23d1e35544c`） |
| 模型 | `minimax/MiniMax-M3`（一档，未降级；本运行时 `session_create` 无 `effort` 字段，见 `docs\RELAY-ADAPTATION.md` §9.5） |
| 起环 | 2026-11-24 21:46:20 +08:00 |
| 判据来源 | `AGENTS.md`（唯一真源：§2 R1–R8、§3 装置地图、§5 坑表、§7 快照、**:484–494 自动接力硬规则**）、`docs\RELAY-ADAPTATION.md` §1–§9、`docs\relay.json`、`docs\relay\stage-1-inventory.md`、台账真源 `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` §68.4–68.6 |
| 裁决顺序 | 用户当轮指令 > `AGENTS.md` 硬规则 > `docs\relay.json` 状态机 > `docs\AGENT-RELAY.md` > 会话口头推断（`RELAY-ADAPTATION.md` §1） |
| 本环写集 | ① 新建本文件 `docs\relay\stage-2-scope.md`（唯一新文件）② 只追加回写 `docs\relay.json` 的本环条目 |

---

## 0 · 一页结论（TL;DR）

1. **W9 残留 521 条不是「521 条英文态可见中文」。** 逐条回读后：68 条 UI 文案里只有 **29 条**真正在英文态上屏；其余 39 条是**落库值 / 死默认参数 / 已被运行期 l10n 取代的测试快照常量**，不是缺口。真实英文态可见合计 **32 条**（29 条 widget + 3 条 `l10n\parts` 的 En mixin 泄漏）。
2. **450 条格言的前提被源码推翻。** `data\quote.dart:7-14` = `Quote({required this.en, required this.zh})`，每条格言本就双语；`widgets\quote_banner.dart:100` 按 `isZh` 分叉显示（AGENTS.md Task 55 真机证据：中文 2 行 / 英文 1 行）⇒ 英文态显示的是英文行，**450 条不属 l10n 化缺口**。
3. **可自动推进的净缺口 = 29 条 widget + 3 条 En mixin = 32 条**，其中 **25 条需要新增 l10n 键**（`byGetter` 390 → 415），4 条要复用既有键，3 条 ＋字形与 1 条 `简体中文` 语言自称属**人工口径**。
4. **落库值不得被 l10n 化**：21 条结论/原因/下一步短语与 1 条习惯单位 `次` 都兼作**落库值**（`ResultNote.parse`、`slot_fill` 按中文串判定）⇒ 只能做「显示层映射」，**不得替换落库字面量**。
5. **本环不落地代码。** 下一环（stage 3）定为**只读复验 + 键表设计稿**；真正落地（stage 4）的前置是并发 Task 68 会话对 `l10n/**` 与 `test\l10n_*` 的写入收口 —— 现在这 6 个文件仍 dirty 且承载并发会话的 390 键断言，此刻动它们会让并发门禁变红。
6. **521 → 44 → 32**：缺口从 stage 1 的 521 收敛到 32，其中 6 条因口径问题挂在人工验收点（3 ＋字形 + 1 语言自称 + B 类 4 键两义 + 450 条是否换数据集）。

---

## 1 · 本环做与不做（写集自证的前置说明）

- **做**：只读盘点 + 逐条回读取证 + 范围定稿 + 派工清单切分 + 提问单。
- **不做**：不改 `apps\` / `packages\` 任何文件（R1：控制器不得改实现代码）；不改 `AGENTS.md` / `handoff.md` / `docs\P1_进度.md` / `docs\B1_验收记录.md` / `docs\开发计划.md` / 计划 §68（并发会话写集）；不改 `reports\task51-gate.ps1`（改门禁脚本属人工验收点）；不 commit / push / tag；不打包分发；不跑全量 `flutter test`（避免与并发门禁抢 `apps\desktop\build\test_cache\build` 与 `sqlite3.dll`）。
- **跨项目隔离**：本会话被自动注入的 `maintenance\task-state\LATEST.md` 属**别的项目**的交接卡，按项目边界纪律**未读取**，本环所有结论只认本仓库文件。

---

## 2 · 验收①：W9 残留 521 条的分类切分（逐条 file:line）

### 2.1 三档定义

| 档 | 含义 | 可否自动推进 |
|---|---|---|
| **① 可自动推进** | 英文态**真的上屏**的中文文案（渲染路径可达） | 可，但要新增/复用 l10n 键 |
| **② 非缺口** | 落库值 / 死默认 / 已被运行期 l10n 取代的测试快照 / 已有 l10n 显示映射 | 否（改了反而破坏落库语义） |
| **③ 未判定** | 静态不可判，需运行时或真机证据 | 需复验方法，不是结论 |

### 2.2 ① 档：真实英文态可见 —— 29 条 widget + 3 条 En mixin = 32 条

**A. 结论文案 21 条（`apps\desktop\lib\src\widgets\outcome_composer.dart`）** — 英文态上屏，且**兼作落库值**：

| file:line | 当前字面量（原文回读） |
|---|---|
| `:28`–`:34` | 结论 7 条：`按时完成` / `延后完成` / `提前完成` / `部分完成` / `受阻` / `顺延到明天` / `取消` |
| `:39`–`:46` | 原因 8 条：`预估不足` / `被打断` / `依赖外部` / `优先级变了` / `状态不好` / `时间不够` / `信息不清` / `其他` |
| `:51`–`:56` | 下一步 6 条：`明天继续` / `转成待办` / `交出去` / `缩小范围` / `定日复盘` / `就此停止` |

落库耦合证据：`ResultNote.parse(...)` 的 `outcome` 与 `slot_fill` 按 `'顺延到明天'` / `'取消'` 做判定 ⇒ **禁止替换落库字面量**，只能加「落库值 → 显示文案」映射表。

**B. 项目页 5 条（`apps\desktop\lib\src\pages\projects_page.dart`）** — 英文态上屏：

| file:line | 当前字面量 | 上屏路径 |
|---|---|---|
| `:303` | `throw const FormatException('日期必须是 YYYY-MM-DD 格式')` | 被 `:288-290` catch 并返回 `error.message` ⇒ **确实上屏** |
| `:310` | `throw const FormatException('这个日期不存在')` | 同上 |
| `:512` | `_error = '项目名称不能为空'` | 表单错误提示上屏 |
| `:1004` | `_error = '任务标题不能为空'` | 同上 |
| `:1340` | `_error = '至少写一句这次推进了什么'` | 同上 |

**C. 全角 ＋ 字形 3 条**（英文态上屏，但属**字形**不是汉字文案，口径待人拍板）：

| file:line | 说明 |
|---|---|
| `widgets\habit_quick_dialog.dart:391` | 全角 `＋` |
| `widgets\habit_quick_dialog.dart:496` | 全角 `＋` |
| `widgets\shell\tool_rail.dart:304` | 全角 `＋` |

**D. `l10n\parts` En mixin 泄漏 3 条**（英文态上屏，属「英文译文里夹了中文」）：

| file:line | 当前字面量 | 备注 |
|---|---|---|
| `l10n\parts\dialog.dart:894` | `'Use ＋ at the top right to add one'` | 句中夹全角 ＋ |
| `l10n\parts\dialog.dart:960` | `'＋ New todo'` | 同上 |
| `l10n\parts\settings.dart:239` | `languageChinese => '简体中文'` | 语言自称；zh 版在 `:138`（**中英双语界面都显示中文属常见做法**，是否算缺陷待拍板） |

### 2.3 ② 档：39 条 —— 不是缺口（逐条 file:line）

| 组 | 条数 | file:line | 判定依据（直接源码证据） |
|---|---|---|---|
| 领域落库值 | 12 | `widgets\domain_chips.dart:22-27`、`:72`、`:74`、`:76`、`:78`、`:80`、`:82` | `:19-20` 注释明示「**落库值，不是显示文案**」，`project.domain` 列存的就是这 6 个中文串；显示走 `_displayLabel` 的 `switch` → `t.projectsDomainCareer/Wealth/Family/Learning/Social/Health`（`l10n\parts\projects.dart:246-261`）⇒ **显示端已经 l10n 化**，改 `:22-27` 会污染落库数据 |
| 计划状态映射 | 2 | `widgets\timeline\slot_fill.dart:85`、`:86` | 对**已存的中文结论**做 `switch` → `PlanStatus`，属读旧数据，不是显示文案 |
| 时长单位兼容 label | 5 | `widgets\est_duration_text.dart:17`、`:20`、`:23`、`:26`、`:29` | `EstUnit` 枚举的**兼容 label**，`:33-34` 注释「只作兼容读取」；`grep 'EstUnit\.\w+\.label'` = **No matches found**（无显示消费点）；界面单位键 `dialogEstUnitMinute/Hour/Day/Week/Month` 已存在（`l10n\parts\dialog.dart:333/336/339/342/345`） |
| 习惯单位（已 l10n 化） | 2 | `pages\habits_page.dart:230`、`widgets\habit_section.dart:158` | 两处均已用 `t.commonUnitTimes`（`l10n\parts\common.dart:133`，zh 值 `次`） |
| 习惯单位落库值 | 1 | `widgets\habit_quick_dialog.dart:200` | `targetUnit: counts ? '次' : ''` 是**写入记录的字段值** ⇒ 落库值，与 domain_chips 同类；显示端已由 `commonUnitTimes` 覆盖 |
| 键条 const 快照 | 8 | `widgets\shell\key_bar.dart:46-53` | `:44` 注释「**运行期不再用它渲染 —— 渲染走 `shellKeyHintsFor`，按当前语言现搭**」；`shellKeyHintsFor(t)` 已在 `:76-85` 用 `t.shellKeyAddEntry` 等 8 键 ⇒ 这 8 条中文只是**保留给既有测试断言的中文快照常量**，英文态不渲染 |
| 导航 const 快照 | 6 | `widgets\shell\nav_rail.dart:36-41` | 同上：`:34` 注释 + `shellNavItemsFor(t)` 在 `:50-57` 用 `t.shellNavToday/Inbox/Habits/Projects/Calendar/Settings`（`l10n\parts\shell.dart:102/105/108/111/114/117`）⇒ 英文态不渲染 |
| 甘特图构造默认参数 | 3 | `widgets\gantt_chart.dart:84`、`:85`、`:192` | 唯一调用点 `pages\projects_page.dart:407-413` **三个标签全部显式覆盖**：`headerLabel: t.projectsTitle`、`emptyLabel: t.projectsEmptyChart`、`unscheduledLabelBuilder: (count) => t.projectsUnscheduled.replaceAll('{n}', '$count')` ⇒ 默认值在运行期**不可达**（`projectsUnscheduled` 已是 `'{n} 条'` 插值形态，`l10n\parts\projects.dart:177`；`projectsEmptyChart` @ `:186`） |

### 2.4 ③ 档：4 项未判定（复验方法见 §6）

| # | 未判定项 | 复验方法见 |
|---|---|---|
| U1 | `lib\src\data\project_store.dart` 6 条诊断串（`:279`、`:335`、`:400`、`:470`、`:521`、`:916`）是否经 toast 上屏 | §6.1 |
| U2 | `lib\src\toast_probe.dart:111` 在发布构建中是否可达 | §6.2 |
| U3 | 「英文态可见」判定本身（静态推断，未真机逐条截图） | §6.3 |
| U4 | `project_store` 的抛出链是否被 UI 捕获 | §6.4 |

### 2.5 450 条格言：前提订正（不是 ③ 档）

- `apps\desktop\lib\src\data\quote.dart:7-14` = `Quote({required this.en, required this.zh})`；`quote_set_character.dart:5` 等每条条目均含 en + zh。
- `widgets\quote_banner.dart:19-20` 文档 + `:100` `isZh = l10n.language == AppLanguage.zh` ⇒ 中文态显示 2 行、英文态只显示英文行。
- AGENTS.md Task 55 真机证据：中文环境 2 行、英文环境 1 行。
- ⇒ **450 条不属 l10n 化缺口**，从缺口口径里划掉；它剩下的只有「是否要换数据集 / 优化英文译文」这种**可选优化**，不阻塞链。提问单见 §4。

---

## 3 · 验收②：68 条的文件级 l10n 改造清单（与 l10n 键表一一对应）

### 3.1 ① 档 29 条：拟用键与新增量

| 组 | 条数 | 拟用键（**新增**标 ➕） | 现有/落库耦合 |
|---|---|---|---|
| `outcome_composer.dart:28-34` | 7 | `outcomeOnTime` `outcomeDelayed` `outcomeEarly` `outcomePartial` `outcomeBlocked` `outcomeRollTomorrow` ➕ ×6；`取消` → **复用** `t.cancel`（`l10n\parts\common.dart:82`，值待 stage 3 逐字核） | 落库值，改显示不改库 |
| `outcome_composer.dart:39-46` | 8 | `reasonUnderestimated` `reasonInterrupted` `reasonExternalDep` `reasonPriorityChanged` `reasonPoorState` `reasonNotEnoughTime` `reasonUnclearInfo` `reasonOther`（`其他` 是否有既有通用键待 stage 3 核）➕ ×8 | 同上 |
| `outcome_composer.dart:51-56` | 6 | `nextTomorrow` `nextToTodo` `nextDelegate` `nextShrinkScope` `nextScheduleReview` `nextStopHere` ➕ ×6 | 同上 |
| `projects_page.dart:303` | 1 | `projectsErrDateFormat` ➕ | 异常消息上屏 |
| `projects_page.dart:310` | 1 | `projectsErrDateNotExist` ➕ | 同上 |
| `projects_page.dart:512` | 1 | `projectsErrNameEmpty` ➕ | 表单错误 |
| `projects_page.dart:1004` | 1 | `projectsErrTitleEmpty` ➕ | 同上 |
| `projects_page.dart:1340` | 1 | `projectsErrProgressEmpty` ➕ | 同上 |
| `habit_quick_dialog.dart:391` / `:496` / `tool_rail.dart:304` | 3 | 全角 `＋` 字形处理：**不新增 l10n 键**（改字形属「口径」问题，见 §4 Q3） | 人工口径 |

**新增键合计 25** ⇒ `byGetter` **390 → 415**；`byMethod` 53 → 78；总键 447 → 472。
连带断言：`apps\desktop\test\l10n_base_test.dart:27-29` 断言 `byGetter.length == 390` ⇒ **必须同步改 415**，否则门禁红。
连带登记：新 getter 必须同时进 `apps\desktop\lib\src\l10n\l10n_keys.dart` 的 `byGetter`（该文件 `:15-16` 规矩）。

### 3.2 ② 档 39 条：为什么不动（含 domain_chips 重复定义的处理方式）

- **domain_chips 与 l10n 键「重复定义」的处理方式（验收②点名项）**：
  `domain_chips.dart:21-28` 的 6 个中文串与 `l10n\parts\projects.dart:246-261` 的 6 个键**看起来重复**，但它们**不是同一个东西**：
  - `domain_chips.dart` 的 `domains` 列表 = **落库值域**（`project.domain` 列存的就是它，永不随语言变）；
  - `l10n\parts\projects.dart` 的 6 键 = **显示名**（`projectsDomainCareer` 等）；
  - 二者的桥是 `domain_chips.dart:70-84` 的 `_displayLabel(domain, t)`：`switch (domain) { case '事业': return t.projectsDomainCareer; ... }`。
  ⇒ **处理方式：保留两侧，不合并、不改落库值**；若将来要消除「重复」，正确方向是给落库值定义**稳定枚举/常量**（如 `DomainIds.career`）并让 `switch` 改比常量 —— 但那是**改数据契约**，命中 `RELAY-ADAPTATION.md` §4「与真源相矛盾的大规模代码改动（含迁移存储结构）」⇒ **本链不动，登记为可选项**。
- `slot_fill.dart:85/86`、`est_duration_text.dart` 5 条、两个 `次`、`key_bar` 8、`nav_rail` 6、`gantt` 3：均按 §2.3 的依据不动。
  - 唯一**可选**清理：`gantt_chart.dart:84/85/192` 三个死默认值可改为「无默认 + 必填」以免后人误用（属代码风格，不改行为）；本链不做。

### 3.3 结构约束（stage 3/4 落地时必须知道）

1. `const` 顶层列表**不能在编译期常量里调 `t.xxx`** —— 这正是 `key_bar` / `nav_rail` 保留一份中文 const 快照的原因（注释在 `key_bar.dart:73-75`、`nav_rail.dart:46-48`）。新增 l10n 化文案时若落在 const 上下文，必须照 `shellKeyHintsFor(t)` 的模式改成「按 `t` 现搭」的工厂函数。
2. 落库值与显示值**必须分家**：建议形态 `const List<String> outcomeLabels`（落库值，不动）+ `String outcomeLabelFor(String v, AppLocalizations t)`（显示映射），切换时按 `t` 取显示值、落库仍写原中文串。
3. `project_store.dart` 等 **诊断串**若要 l10n 化，属**数据层**依赖 UI 层 l10n（方向反了）⇒ 优先在 UI 层做映射，而不是往数据层塞 `t`。

---

## 4 · 验收③：450 条格言的产品决策提问单（只出单，不作取舍）

> 前提已订正（§2.5）：450 条**不是**英文态可见中文，所以这不再是「缺口」，只是**可选优化**。以下问题**只登记**，链上**不作取舍**（命中人工验收点）。

| # | 提问 | 选项 | 缺省建议（不自动执行） |
|---|---|---|---|
| Q1 | 450 条格言是否要**换数据集 / 扩量**？ | (a) 保持 450 条不动（缺省）(b) 扩到 600 条 (c) 换主题 | (a) |
| Q2 | 450 条的**英文译文质量**是否需要单独一轮审校？ | (a) 不审 (b) 抽检 50 条 (c) 全量审校 | (b) |
| Q3 | 英文态里夹的**全角 `＋`**（`dialog.dart:894`、`:960`、`habit_quick_dialog.dart:391/:496`、`tool_rail.dart:304` 共 5 处）算不算缺陷？ | (a) 算，换半角 `+` (b) 不算，字形风格允许 (c) 只改 En mixin 两处 | (c) |
| Q4 | 语言自称 `'简体中文'`（`settings.dart:239`）在英文界面显示中文，算不算缺陷？ | (a) 算，英文态改 `Chinese` (b) 不算，语言名按母语显示是惯例 | (b) |
| Q5 | 上面 Q3/Q4 若判「算缺陷」，是本批次一起改，还是单开一批？ | (a) 一起 (b) 单开 | (b) |

---

## 5 · 验收④：B 类 4 键的两种口径与本环建议

**对象**：`hoursCount` / `minutesCount` / `deferredDays` / `moodScoreLabel`
**位置**：`apps\desktop\lib\src\l10n\parts\domain.dart:159/162/165/168`（声明）、`:311/317/321/326`（zh 实现）、`:439/442/445/448`（en 实现）；`l10n_keys.dart:1915-1918` 的 `byMethod` 登记。

| 口径 | 含义 | 代价 | 风险 |
|---|---|---|---|
| **A. 补界面消费** | 界面确实需要这 4 个文案，但目前没消费 ⇒ 找到消费点接上 | 找到「谁该显示它」要读历史批次代码 | 接错位置 = 新缺陷 |
| **B. 连断言退役** | 这 4 个键其实没人用 ⇒ 删键 + 删 `byMethod` 登记 + 同步改 `test\l10n_base_test.dart` 键数断言 | 删键会改 `byMethod` 计数（53 → 49） | 若其实有人在用，删了会红 |

**本环建议**：**先做 A 的只读定位（stage 3），再决定**。理由：键在 zh/en 两侧都实现了 ⇒ 不像「半成品」；而 `byMethod` 键数断言与 `byGetter` 键数断言耦合在同一文件 `test\l10n_base_test.dart`（当前 dirty、属并发会话写集）⇒ **此刻任何删键都会让并发门禁红**。
**本环不作定性**（验收口径含糊 ⇒ `human_checkpoints` 第 5 条）。

---

## 6 · 验收⑤：4 项未判定项的复验方法与判据

### 6.1 U1 · `project_store.dart` 6 条诊断串是否上屏

- 复验：`grep -n "throw\|repos\." apps\desktop\lib\src\data\project_store.dart` 取 `:279/:335/:400/:470/:521/:916` 上下文 → 追到 UI 侧 catch（`projects_page.dart:288-290` 已知会把 `FormatException.message` 上屏）。
- 判据：**若**任一条的 message 被某处 `catch (e) { ... e.message / e.toString() ... }` 送进 toast ⇒ 该条升为 ①（需新增键），缺口口径由 32 变为 32+k（k ≤ 6）。
- 若无法静态定位 ⇒ 记「未判定」，**不得**凭形态推断（见 AGENTS.md 取证纪律）。

### 6.2 U2 · `toast_probe.dart:111` 发布构建可达性

- 复验：读 `apps\desktop\lib\src\toast_probe.dart` 全文，确认 `:111` 所在函数被哪些 UI 调用、是否有 `#if DEBUG` 之类条件编译包裹；再查 `pubspec.yaml` 的 `flutter_build` 配置。
- 判据：`:111` 所在代码路径在 release 构建可达 ⇒ 6 条诊断串**有可能**被 toast 上屏 ⇒ U1 判据收紧为「必须逐条确认」；不可达 ⇒ U1 只需静态追 UI 调用点。

### 6.3 U3 · 「英文态可见」判定口径

- 本环已把判定从「文件里有中文字面量」升级为**可达性判读**（显示路径 / 落库值 / `switch` case / 异常捕获 / 死默认 / 运行期已 l10n 化），并据此把 68 → 32。
- 复验方法：沿用 worker B 的词法状态机（`reports\task68-deadkey-scan.md` §3.1–3.3）改造为**可复跑脚本**，扫描面 `apps\desktop\lib\**\*.dart`（93 文件），命中项**必须附可达性判读**才算数。
- 判据：脚本输出「中文字面量命中数」与「经可达性判读后仍上屏数」两个数字，差值即被排除量（当前预期 68 → 32，差 36 = 12+2+5+2+1+8+6+3 中的可解释部分）。
- 注意：脚本必须是**纯 ASCII** `.ps1`（中文用 `[char]0x....` 拼），CRLF，无 BOM（R2）。

### 6.4 U4 · `project_store` 抛出链是否被 UI 捕获

- 复验：对 `:279/:335/:400/:470/:521/:916` 各查一层调用方（`grep` 调用函数名），看 UI 是否 `try/catch`。
- 判据：被捕获 ⇒ 走 §6.1 的 message 路径；未捕获 ⇒ 记「未判定（无 UI 消费点）」，不改缺口口径。

---

## 7 · 下一环（stage 3）范围与后续切分

### 7.1 stage 3 = 只读复验 + 键表设计稿（**不落码**）

| 项 | 内容 |
|---|---|
| 标题 | W9 残留 32 条未判定项复验 + 25 条新键的键表设计稿 |
| 类型 | `read_only_verify_and_design` |
| 写集 | ① 新建 `docs\relay\stage-3-report.md` ② 只追加回写 `docs\relay.json` 本环条目。**不动** `apps\` / `packages\` / `l10n\**` / 并发会话 5 个台账文件 / `reports\task51-gate.ps1` |
| 必做 | ① §6 的 4 项未判定逐项复验（带 file:line 与判据）② 25 条新键的**键表设计稿**（键名 + zh 文案 + en 文案 + 所属 parts 文件 + 落库值映射表 + `byGetter` 390→415 的连带改动清单）③ 32 条的 file:line 级最终核对表 |
| 验收 | `docs\relay\stage-3-report.md` 存在且含上述三块；本环 `git status` 增量**只**等于本环新建文件 |
| 为何不直接落码 | 并发 Task 68 会话**未提交**的 dirty 集含 `l10n\l10n_keys.dart`、`l10n\parts\{common,domain,projects,settings}.dart`、`test\l10n_base_test.dart`、`test\l10n_harness.dart`；这些文件承载并发会话的 **390 键断言**（`test\l10n_base_test.dart:27-29`）⇒ 此刻新增 25 键会让并发门禁红，且并发会话后续再写同一文件会覆盖我们的改动 |

### 7.2 stage 4 / 5 / 6 切分

| 环 | 内容 | 前置 |
|---|---|---|
| stage 4 | **落地 25 条新键 + 29 条显示映射**（实现经 worker 子会话；控制器只写台账行 + 交付文档 + `docs\relay.json`） | 并发 Task 68 会话收口（`l10n\**` 与 `test\l10n_*` 不再 dirty）；门禁 `-ExpectDesktopTests` 按当轮真实用例数 |
| stage 5 | **人工口径批次**：B 类 4 键（§5）、＋字形（Q3）、`简体中文` 语言自称（Q4）、450 条是否换数据集（Q1/Q2） | 命中 `human_checkpoints` ⇒ `status=blocked` 停链等人 |
| stage 6 | **W9 收口**：68.4b / 68.4i 复扫 + 68.4g verifier 终判 + 68.4h（`git commit` / `push` 属人工验收点） | 68.4h 人工 |

### 7.3 stage 4 的门禁影响预判（实测白名单）

`reports\task51-gate.ps1` 的 `$patterns` 已含：`l10n\l10n_keys.dart`(:190/:243)、`l10n\parts\*.dart`(:227-243)、`test\l10n_base_test.dart`(:202/:267)、`test\l10n_harness.dart`(:203/:268)、`widgets\outcome_composer.dart`(:265)、`pages\projects_page.dart`(:184)、`widgets\habit_quick_dialog.dart`(:259)、`widgets\domain_chips.dart`(:253)、`widgets\est_duration_text.dart`(:263) ⇒ **改这些文件不增加 `OUT_OF_SET`**。
**但**：若为 21 条结论文案**新建** `l10n\parts\outcome.dart`，该文件不在白名单 ⇒ `OUT_OF_SET` +1 ⇒ **建议把 21 条键放进既有 parts 文件**（`dialog.dart` 或 `today.dart`），避免新增白名单项（改门禁脚本属人工验收点，本链不自改）。

---

## 8 · 验收⑥：本环 git status 计数变化说明与写集自证

- **开工检测（21:46:46）**：`git status --porcelain` = **18 行**；`HEAD = 01b6339`；`AHEAD=0 / BEHIND=0`。
- **收尾检测（本环结束前）**：`git status --porcelain` = **18 行**；`HEAD = 01b6339`（未变，未做任何 commit）。
- **计数不变的原因（须如实登记）**：`docs/relay/` 是**未跟踪目录**，porcelain 只输出 1 行 `?? docs/relay/` ⇒ 本环在目录内新增 `stage-2-scope.md` **不改变计数**。⇒ **「只读自证」不能靠计数**，改用文件清单 + 指纹（下表）。
- **本环改动清单（完整）**：

| 文件 | 动作 | 写前指纹 | 写后指纹 |
|---|---|---|---|
| `docs\relay\stage-2-scope.md` | **新建**（本文件） | 不存在 | 见 `docs\relay\` 目录清单 |
| `docs\relay.json` | **只追加回写** stage 2 条目 + `current_stage` 2→3 + 追加 stage 3 条目 + `next_session_id` | 12620 B / 21:50:56 / sha16 `25E98602B8E22062` | 见 `docs\relay.json` 收尾回读 |

- **未动的 12 个关键文件指纹（与并发会话写集无关的「我没碰」证据）**：
  `AGENTS.md` 279490 B / 21:33:28 / `9E529458B40F16A9`（接力章节 :484-494 原样；**收尾复测已变为 279514 B / `7B053EF28EECA08B` / 仍 494 行**，且收尾复读 :484-494 逐行确认「自动接力（Relay）—— 硬规则」6 条原样仍在 —— 这 +24 B 由并发 Task 68 会话按其声明写集改动 `R2 基线 + §7 快照` 造成，**非本环所为**，本环只写了 `docs\relay\stage-2-scope.md` 与 `docs\relay.json`）、
  `l10n\l10n_keys.dart` 78463 B / 21:18:21 / `760A8E990F4ED618`、
  `l10n\parts\common.dart` 4694 B / 21:11:22 / `31DF49E483ECE52D`、
  `l10n\parts\domain.dart` 14288 B / 21:17:35 / `AE8095A54C113188`、
  `l10n\parts\shell.dart` 6287 B / 09:24:42 / `EB0CE70B169E0FE5`、
  `l10n\parts\dialog.dart` 34374 B / 17:42:26 / `17CCA97604087714`、
  `l10n\parts\settings.dart` 7730 B / 21:11:32 / `D4FA71A3205E617A`、
  `widgets\outcome_composer.dart` 7738 B / 17:42:51 / `7805362693D14DC7`、
  `pages\projects_page.dart` 50520 B / 00:23:31 / `49ECB20E1A3C2BED`、
  `widgets\habit_quick_dialog.dart` 28097 B / 17:27:25 / `4D444A73A324D1AB`、
  `widgets\shell\tool_rail.dart` 10130 B / 11-18 20:59:22 / `FB201491D7C04E2E`、
  `test\l10n_base_test.dart` 28982 B / 21:17:39 / `4193D08894BCB9E1`。
- **并发检测结论**：并发 Task 68 会话 `mvs_e395774e42a84ff9a218fcb0f98`（原 id `mvs_e395774e42a84ff9a218fcb0b7349f98`）的 dirty 集与本环写集**零交集**（它脏的是 `l10n/**`、`test\l10n_*`、`widgets\recurring_*`、`packages\core_domain\**`、计划文件；本环只写 `docs\relay\**` 与 `docs\relay.json`）⇒ 本环可安全写。
- **⚠ 偏离登记（§5.5 的「开工副本必然过期」）**：`docs\relay.json` 在本环读盘时是 **9975 B / 21:46:42 / `BCD14D6BB9CAA619`**；本环收尾前复测变成 **12620 B / 21:50:56 / `25E98602B8E22062`**（**+2645 B**）⇒ 期间**有人写过 relay.json**。处置：**不回用开工副本**，收尾前**重新读盘**并在最新字节上做定点替换；回写后再核对 `concurrency` / `next_stage_target` / `model_policy` / `human_checkpoints` / `stop_conditions` 五个顶层字段仍在（§5.5 要求）。**写者已查明**：root 会话 `mvs_1711739d1ff3435a824c226a42c5db48`（把 `plan_doc` 订正为 `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`、新增 `plan_doc_note`、给 stage 1 条目追加「root 复核」段）—— 属 §5.5 明说的「根会话在环运行中途往同一个文件加字段」情形，**非第三方会话** ⇒ 本环按 §5.5 在最新字节上定点替换，回写后回读核对顶层 key 零丢失。

---

## 9 · 验收⑦：与 stage-1 结论的差异登记

| # | stage-1 结论 | 本环复核结论 | 差异原因（直接证据） |
|---|---|---|---|
| D1 | W9 残留 521 条 = 68 条 UI 文案 + 450 条格言 + 3 条 En mixin | **32 条真实缺口**（29 widget + 3 En mixin）+ 450 条非缺口 + 39 条非缺口 | 逐条加了**可达性判读**：落库值 / 死默认 / 运行期已 l10n 化 |
| D2 | 450 条格言「英文态可见」 | **前提被推翻**（`Quote{en,zh}` 双语 + `quote_banner.dart:100` isZh 分叉） | 直接源码证据 |
| D3 | key_bar 8 + nav_rail 6 属英文态可见 | **运行期不渲染**（`shellKeyHintsFor` / `shellNavItemsFor` 已在用），中文只是 const 测试快照 | `key_bar.dart:44/73-85`、`nav_rail.dart:34/46-57` |
| D4 | gantt 2 条可用既有键覆盖 | gantt 3 条**全是死默认值**（唯一调用点全部覆盖）⇒ 缺口归零 | `projects_page.dart:407-413` |
| D5 | stage 3 = 17 条零新增键替换 | **作废**（那 17 条里 14 条是 const 快照、2 条是死默认）⇒ 改为 stage 3 只读复验 + 键表设计 | D3 + D4 |
| D6 | l10n 键 397 条 | **390 条**（`test\l10n_base_test.dart:27-29` 断言 + `l10n_keys.dart:1486` 注释）；总键 447 = 390 + 4 + 53 | 并发会话改过 parts，worker B 的读数已过期 |
| D7 | B 类 4 键在 `parts\domain.dart:121/124/127/130` | 现为 `:159/162/165/168`（声明）+ `:311/317/321/326`（zh）+ `:439/442/445/448`（en） | 并发会话改文件导致行号位移 |
| D8 | `parts\settings.dart:257` 是 `简体中文` | 现 `:257` = `@override`，`简体中文` 在 zh `:138` / En mixin `:239` | 同上 |
| D9 | 缺口 44 条 | **32 条**（25 条需新增键 + 4 条复用 + 3 条字形，另 3 条 En mixin 归人工口径） | D1–D4 累加 |

---

## 10 · 未做 / 未验证（不得当作已完成）

- **未亲跑全量 `flutter test`**：desktop 836 / core_data 204 / core_db 71 / core_domain 62 取自并发门禁原始输出 `reports\task68-gate-run1.log`（RUN_AT 21:35:39 / HEAD 01b6339），**不是本环实测**；本环为避免与并发门禁抢 `apps\desktop\build\test_cache\build` 与 `sqlite3.dll` 未跑。
- **未跑逐包 analyze**：四包 `ANALYZE=VERBATIM` 亦取自同一份并发门禁输出。
- **未做真机 / 打包 / 分发**：68.4h（commit+push）属人工验收点。
- **68.4g verifier 终判未出**：本环不代打勾。
- **门禁红灯项未变**：`GATE_VERDICT=FAIL` / `GATE_FAILURES=1` / `FAIL_ITEM=OUT_OF_SET=3` = 接力链自建的 3 个 docs 文件（`docs/AGENT-RELAY.md`、`docs/RELAY-ADAPTATION.md`、`docs/relay.json` + `docs/relay/`）不在 `reports\task51-gate.ps1` 白名单；本环新建 `docs\relay\stage-2-scope.md` 后**仍为 3**（同属未跟踪目录 `docs/relay/`）。改门禁脚本 = 人工验收点，本链不自改。
- **`docs\relay.json` 的 `plan_doc` 指针**：本环开工时仍指向失效的 `docs\开发计划.md`（该文件无任何未勾复选框）；**root 会话已于 21:5x 订正为 `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` 并加 `plan_doc_note`** ⇒ 本环按最新磁盘值取台账真源，无需本环再改（该字段属他人字段且在禁写清单内）。
- **B 类 4 键未定性**、**＋字形与 `简体中文` 口径未拍板**、**450 条是否换数据集未拍板**：见 §4、§5。

---

## 11 · 指针与产物

| 指针 | 用途 |
|---|---|
| `F:\soft\00selfmade\practilog\docs\relay\stage-2-scope.md` | 本环交付（本文件） |
| `F:\soft\00selfmade\practilog\docs\relay\stage-1-inventory.md` | 第 1 环盘点 |
| `F:\soft\00selfmade\practilog\docs\relay.json` | 状态机（stage 2 条目 + `current_stage` → 3 + stage 3 条目 + `next_session_id`） |
| `F:\soft\00selfmade\practilog\docs\RELAY-ADAPTATION.md` | 裁决文档（§1 顺序 / §4 人工验收点 / §5 并发检测 / §9 模型策略） |
| `F:\soft\00selfmade\practilog\AGENTS.md` `:484-494` | 接力硬规则（每环开工必回读） |
| `F:\soft\00selfmade\practilog\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` `:9611-9619` / `:9630-9642` | 台账真源 §68.4a–i / §68.6 W9 残留面 |
| `F:\soft\00selfmade\practilog\reports\task68-gate-run1.log` | 并发门禁原始输出（本环引用，非本环实测） |
