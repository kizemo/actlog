# Stage 3 报告 · U1–U4 未判定复验 + 27 条新 l10n 键设计稿

> 会话：`mvs_c65a7cd9bcaa47409abe7dc89ffa7ac8`（stage 3 · `read_only_verify_and_design`）
> 仓库根：`F:\soft\00selfmade\practilog` · 计划真源：`docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` §68.4a–i / §68.5 / §68.6 / §68.7（`:9611-9619` / `:9631-9649`）
> 前序交付：`docs\relay\stage-1-inventory.md`、`docs\relay\stage-2-scope.md`

---

## 0 · 一页结论（TL;DR）

| 项 | stage-2 口径 | **stage-3 实测口径** | 差异 |
|---|---|---|---|
| 英文态可见缺口（扫描面 `apps\desktop\lib\**` 内） | 32 条 | **34 条** | +2（`project_store.dart:400` / `:470` 两条 `StateError` 经 `_messageOf` 的 `'$error'` 分支上屏，由 stage-2 的「未知」升 ① 档） |
| 扫描面外可见缺口 | 未登记 | **1 条**（`packages\core_domain\lib\src\entities.dart:111`） | 新增；另登记 **1 条相邻未判定面**（`packages\core_data\lib\src\repositories.dart:49`） |
| 全域缺口 | 32 条 | **35 条** | +3 |
| 需新增 l10n 键 | 25 条 | **27 条** | +2（同上两条 `StateError` 类型化后各需 1 个带 `{id}` 的显示键） |
| `byGetter` 计数 | 390 → 415 | **390 → 417** | 键数口径 |
| `byListGetter` / `byMethod` | 4 / 53 | **4 / 53（不变）** | 27 个新键全部设计为**无参 String getter**，不动 `byMethod` 显式名单 |
| 总键数 | 447 → 472 | **447 → 474** | = 417 + 4 + 53 |

**四个未判定项的终判**：U1 = **2 条上屏 / 4 条不可达**；U2 = **release 构建可达但默认启动不可达，且与 `project_store` 无数据通道** ⇒ 不收紧 U1；U3 = **判定口径已可复跑**（本环实测 命中 1012 / 存活 34 / 排除 978，三段可加总）；U4 = **抛出链被 UI 捕获**（9 个 `catch` 块，7 处走 `_messageOf`）。

**本环不落码**（写集只有本文件 + `docs\relay.json` 的只追加回写），下一环 stage 4 才落地。

---

## 1 · 本环做与不做

### 1.1 做了

1. 回读 `AGENTS.md` 接力章节，确认未被抹掉（见 §5.1）。
2. 并发检测：`git status --porcelain` 计数 + `HEAD` + 目标文件指纹；写集与并发会话**零交集**。
3. U1–U4 逐项复验（派 2 个只读 `explore` 子会话 + 控制器独立内联只读扫描 + 逐行回读）。
4. 产出 **27 条新键的键表设计稿**（键名 / zh / en / 归属 parts 文件 / 落库值映射 / 连带改动清单 / 断言改动）。
5. 产出 **35 条 file:line 级最终核对表**（扫描面内 34 + 扫描面外 1）。
6. 登记与 stage-2 结论的差异、需人工拍板事项、stage 4 范围与前置条件。
7. 只追加回写 `docs\relay.json`（stage 3 条目 → `done`、`current_stage` → 4、追加 stage 4 条目、`sessions` 追加 stage 4 会话、`next_session_id` 回写）。

### 1.2 没做（以及为什么）

| 没做的事 | 原因 |
|---|---|
| 落码（改 `apps\` / `packages\` / `l10n\`） | 本环写集限定为「只读复验 + 设计稿」；且并发 Task 68 会话脏集含 `l10n\l10n_keys.dart` / `parts\*.dart` / `test\l10n_base_test.dart` / `test\l10n_harness.dart`，此刻改同一批文件会被并发会话回写覆盖 |
| 亲跑全量 `flutter test` / 逐包 `analyze` | 会与并发门禁抢 `apps\desktop\build\test_cache\build` 与 `sqlite3.dll` |
| 改 `reports\task51-gate.ps1` 白名单 | 属人工验收点（AGENTS.md §4） |
| 提交 / 推送 / 打包 / 改用户级配置 | 明令禁止 |
| 读取 `maintenance\task-state\LATEST.md` | 属**别项目**交接卡，按项目边界纪律未读 |

---

## 2 · 验收①：U1–U4 逐项复验

> 口径纪律：凡「具体值 / 具体行」结论一律**当场回读文件**取证，不凭形态推断；下文每条结论都带 file:line。

### 2.1 U1 · `project_store.dart` 6 条诊断串是否上屏 → **2 条上屏（① 档），4 条不可达（③ 档）**

`apps\desktop\lib\src\data\project_store.dart` 共 6 条含中文的诊断串，逐条判定：

| # | file:line | 字面量 | 异常类型 | 是否上屏 | 判据（可达性链） |
|---|---|---|---|---|---|
| 1 | `project_store.dart:279` | `项目名称不能为空` | `ArgumentError.value(name,'name',…)` | **否** | UI 先拦截：`projects_page.dart:511-513` 已 `setState(() => _error = '项目名称不能为空')` 并 `return`，**根本不调用 store** ⇒ 该分支是防御性冗余 |
| 2 | `project_store.dart:335` | `任务标题不能为空` | `ArgumentError.value(title,'title',…)` | **否** | 同上：`projects_page.dart:1003-1005` 先拦截并 `return` |
| 3 | `project_store.dart:400` | `任务 $milestoneId 不存在` | `StateError` | **是** | `StateError` 无 `message` 分支 ⇒ 命中 `projects_page.dart:284-292` `_messageOf` 的兜底 `return '$error';`（`:291`）⇒ 原文上屏 |
| 4 | `project_store.dart:470` | `项目 $projectId 不存在` | `StateError` | **是** | 同 #3 |
| 5 | `project_store.dart:518-522` | `只接受 project / increment` | `ArgumentError.value(sourceType,'sourceType',…)` | **否** | 枚举白名单校验，**不是用户输入**；当前无调用方会传错值（stage 4 需复核调用方） |
| 6 | `project_store.dart:916` | `日期必须是 YYYY-MM-DD 格式` | `ArgumentError.value(iso,'iso',…)` | **否** | `_utcOfIso`（`:913-917`）内部前置断言；用户日期在 UI 侧已被 `projects_page.dart:300-311` 的正则 + 日历校验拦下 ⇒ 该分支不可达 |

**结论**：6 条里 **2 条（`:400` / `:470`）真在英文态上屏** ⇒ 计入缺口，且**必须类型化**（见 §3.2），否则 `{id}` 永远插不进本地化文案。

**落库值红线**：`project_store.dart:400` / `:470` 的中文串**不是落库值**（是异常消息，不入库），因此允许改写为类型化异常 + 本地化键，不需要保留字面量。

### 2.2 U2 · `toast_probe.dart:111` 发布构建可达性 → **可达，但默认不可达；与 U1 无关**

| 判据 | 实测 |
|---|---|
| 编译期门禁 | `apps\desktop\lib\src\**\toast_probe.dart` 全文**无** `#if` / `kDebugMode` / `dart_defines` ⇒ **release 构建照样编进去** |
| 运行期开关 | 仅运行期开关控制触发（`toast_probe.dart:46-58` 的探针逻辑，`:111` 是消息文本）⇒ 编译期可达、运行期由开关决定 |
| 默认启动路径 | `main.dart:15` / `:50` / `:68-72` 决定是否启用该探针 ⇒ **默认不启用** |
| 与 U1 的关系 | `toast_probe.dart` 与 `project_store.dart` **无数据通道**（一条是提示探针、一条是领域存储）⇒ 它的可达性**不能**用来给 `project_store` 的 6 条判上屏 |

**结论**：U2 判「**release 构建可达 / 默认启动不可达 / 与 U1 无关**」⇒ **不据此收紧 U1**。另注：仓内真正的 toast 机制是 `ScaffoldMessenger` 的 SnackBar，而 `project_store` 那 6 条走的是页内 `_ErrorBanner` ⇒ 两者本就是不同通道。

### 2.3 U3 · 「英文态可见」判定口径 → **已可复跑**（规格见下）

本环用**内联只读扫描**（不落脚本文件，写集不允许）实测：

| 指标 | 本环实测 | worker B 报告口径 | 差异说明 |
|---|---|---|---|
| 扫描文件数 | `apps\desktop\lib\**\*.dart` = **93** | 93 | 一致 |
| CJK 字面量命中总数 | **1012** | 1019 | **口径差异 7 条**，来源为 CJK 区间集 / `//` 剥离 / 字符串正则的细微差别，**未逐条定位**；不影响缺口数（缺口按 file:line 逐条回读判定，不靠扫描器计数） |
| 其中 l10n 子树 | **485** | 491 | 同上 |
| 其中非 l10n | **527** | 528 | 同上 |

**可加总台账（判定口径的核心产物）**：

```
1012（命中总数）
 =  34  存活   ← 扫描面内真实英文态可见缺口
      + 449  格言（双语结构，非缺口）
      +  47  非格言排除（落库值 / 死默认 / const 快照）
      + 482  l10n 正常文案（zh 侧正常文案 + en 侧本地化文案）
```

- 34 条存活中，**31 条**来自「非 l10n 且非格言」的 78 条清单，**3 条**来自 l10n 子树的 En mixin 泄漏。
- 78 条清单的拆分：31 存活 + 47 排除 = 78 ✔（排除 47 = `project_store` 4 + `key_bar` 8 + `nav_rail` 6 + `domain_chips` 12 + `est_duration_text` 5 + `gantt_chart` 3 + `slot_fill` 2 + `habit_quick_dialog` 1 + `habits_page` 1 + `habit_section` 1 + `priority_marks` 1 + `review_section` 1 + `providers` 1 + `toast_probe` 1）。

**可复跑扫描器规格**（stage 4 落码为 `reports\task51-cjk-scan.ps1`；纯 ASCII 正文、CRLF、无 BOM，中文区间一律用 `[char]0x…` 或正则 `\uXXXX` 转义）：

```powershell
# scan-cjk-ui.ps1 - ASCII only, CRLF, no BOM
param([string]$Root = 'F:\soft\00selfmade\practilog')
$ErrorActionPreference = 'Stop'
$scanDir = Join-Path $Root 'apps\desktop\lib'
$files = @(Get-ChildItem -Path $scanDir -Recurse -Filter *.dart -File | Sort-Object FullName)
$cjk = [System.Text.RegularExpressions.Regex]::new('[\u4E00-\u9FFF\u3400-\u4DBF\u3000-\u303F\uFF01-\uFF65]')
$reSingle = [System.Text.RegularExpressions.Regex]::new("'((?:[^'\\]|\\.)*)'")
$reDouble = [System.Text.RegularExpressions.Regex]::new('"((?:[^"\\]|\\.)*)"')
$hits = 0
$rows = New-Object System.Collections.Generic.List[string]
foreach ($f in $files) {
  $lines = [IO.File]::ReadAllLines($f.FullName)
  for ($i = 0; $i -lt $lines.Length; $i++) {
    $code = $lines[$i]
    $idx = $code.IndexOf('//')
    if ($idx -ge 0) { $code = $code.Substring(0, $idx) }
    foreach ($m in @($reSingle.Matches($code)) + @($reDouble.Matches($code))) {
      if ($cjk.IsMatch($m.Groups[1].Value)) {
        $hits++
        $rows.Add(('{0}:{1}:{2}' -f $f.FullName.Replace($Root + '\',''), ($i + 1), $m.Groups[1].Value))
      }
    }
  }
}
"SCAN_FILES=$($files.Count)"
"CJK_LITERAL_HITS_TOTAL=$hits"
$rows | ForEach-Object { $_ }
```

> 口径注记（写给 stage 4 使用者）：
> ① 本规格用**朴素 `//` 剥离**，会把字符串里的 `//`（如 URL）误切 ⇒ 与完整词法状态机有偏差（本次 7 条差异即属此类未逐条定位项）；
> ② **扫描器只负责「找候选」，判定「是否英文态可见」必须逐条回读渲染链**（stage-2 的 521→32、stage-3 的 32→34 两次大幅收敛全部来自可达性判读，不是扫描器给的）；
> ③ 落码时若采用完整词法状态机，应在报告里同时给出两种口径的差值，避免把「口径差」误判成「新增缺陷」。

### 2.4 U4 · `project_store` 抛出链是否被 UI 捕获 → **是**

`apps\desktop\lib\src\pages\projects_page.dart` 实测：

- `catch (error)` 块 **9 个**：`:117` / `:147` / `:161` / `:188` / `:206` / `:225` / `:249` / `:272` / `:1015`。
- `_messageOf` 定义在 `:284-292`：

```dart
static String _messageOf(Object error) {
  if (error is ArgumentError) { return '${error.message}'; }   // :285-287
  if (error is FormatException) { return error.message; }        // :288-290
  return '$error';                                               // :291  ← StateError 走这里
}
```

- `_messageOf` 的 **7 个调用点**：`:148` / `:166` / `:189` / `:207` / `:226` / `:250` / `:273`。

⇒ `StateError` 既不是 `ArgumentError` 也不是 `FormatException` ⇒ **必走 `:291` 的 `'$error'` 分支** ⇒ 异常消息原文（含中文）被完整搬进 `_error` ⇒ 上屏。

**未核实项（如实登记）**：本环**未展开完整调用图**，尚未逐点确认「哪个 `catch` 块 ↔ 哪次 `project_store` 调用」的配对（`updateMilestone` / `updateProject` 两条 `StateError` 分别落在哪个 `catch` 块）。stage 4 落码时须逐点核实；**不影响本环结论**（只要该调用发生在任一 `catch` 块内即上屏，而 `project_store` 的所有公开方法都是 `async` 且由 UI `await` 调用）。

**全仓 `StateError` catch 面**：`apps\desktop\lib\**` 内 `StateError` 仅 2 处命中，且**都不在 `project_store`**：`app_paths.dart:192`（文档注释）与 `app_paths.dart:247`（`throw`）⇒ **没有任何 `catch (e) on StateError` 特化捕获** ⇒ 全部落进通用 `catch (error)` ⇒ 上述路径是唯一通路。

---

## 3 · 验收②：27 条新 l10n 键的键表设计稿

### 3.1 总体设计原则（stage 4 落码须遵守）

| 原则 | 内容 | 依据 |
|---|---|---|
| **落库值一律不改** | 21 条结论文案、1 条习惯单位 `次`、`顺延到明天` / `取消` 的判定值都**原样保留**；只做「落库值 → 显示值」的**显示层映射** | `outcome_composer.dart:27-57`（`const List<String>` 是落库值）、`:179`/`:191`/`:203-205` 靠 `contains` 回显；`slot_fill.dart:84-88` 按中文 switch 判定 |
| **映射函数放在值的所有者处** | 新增 `OutcomeComposer` 侧映射（`outcome_composer.dart`），由 `plan_item_detail_dialog.dart:312-328` 与 `projects_page.dart:244` / `:1375-1383` 共用 | 值的所有者 = `outcome_composer.dart` |
| **未知值原样返回** | 映射遇到历史数据里的未知短语 ⇒ 原样返回（用户数据，不是 UI 字面量，不在 §68.4b 口径内） | 先例：`app_localizations.dart:105-130` 的 `projectDomainLabel`（`:127-129` `default: return key;`） |
| **不新建 `l10n\parts\outcome.dart`** | 20 条结果撰写键放进既有 `parts\dialog.dart` 的「结果撰写（出处：`widgets\outcome_composer.dart`）」分组 | 新建 parts 文件 ⇒ 门禁 `OUT_OF_SET` +1（`reports\task51-gate.ps1` 的 `$patterns` 只含既有 `parts\*.dart`，见 `:227-246`） |
| **全部无参 String getter** | 27 个新键都不带参数 ⇒ 不进 `byMethod`（`l10n_keys.dart:1914`）⇒ `l10n_base_test.dart:44-109` 的 53 条 byMethod 显式名单**不用改** | 避免改动面扩大 |
| **`{id}` 占位沿用既有先例** | 2 条带 id 的键做成无参 getter，文本内含 `{id}` 占位，调用点 `replaceAll` 注入 | 先例 `parts\projects.dart:177` `projectsUnscheduled => '未排期 {n} 条'`（无参 getter + 文本内占位） |
| **zh 值 = 现存字面量** | zh 侧文案**逐字等于**今天的界面文字 ⇒ 中文界面**零视觉变化** | 「落库值 → 显示值」映射要求 zh 显示值与落库值同形 |
| **中英不同值** | 27 个新键的 en 文案均 ≠ zh 文案（`l10n_base_test.dart:245-253` 会逐条比对） | `sameValueWhitelist`（`l10n_harness.dart:586-589`）只有 2 条，**不得**扩充 |

### 3.2 键表 A · 结果撰写 20 条新键（落 `apps\desktop\lib\src\l10n\parts\dialog.dart`）

> 21 条落库短语中，`取消` **不新增键**，复用 `t.commonCancel`（zh `取消` / en `Cancel`，`parts\common.dart:12` / `:82` / `:145`；键常量 `commonCancel` 见 `l10n_keys.dart:325` / `:1545`）⇒ 21 − 1 = **20 个新键**。
> en 文案为**本环提案**，stage 4 落码时可微调，但须保证「en ≠ zh」且语义准确。

| # | 键名（getter / kebab 键） | zh 文案（= 现字面量） | en 文案（提案） | 落库值（判定用） | 来源 file:line |
|---|---|---|---|---|---|
| A1 | `dialogOutcomeOnTime` / `dialog-outcome-on-time` | 按时完成 | Completed on time | `按时完成` | `outcome_composer.dart:28` |
| A2 | `dialogOutcomeLate` / `dialog-outcome-late` | 延后完成 | Completed late | `延后完成` | `:29` |
| A3 | `dialogOutcomeEarly` / `dialog-outcome-early` | 提前完成 | Completed early | `提前完成` | `:30` |
| A4 | `dialogOutcomePartial` / `dialog-outcome-partial` | 部分完成 | Partially completed | `部分完成` | `:31` |
| A5 | `dialogOutcomeBlocked` / `dialog-outcome-blocked` | 受阻 | Blocked | `受阻` | `:32` |
| A6 | `dialogOutcomeDeferredTomorrow` / `dialog-outcome-deferred-tomorrow` | 顺延到明天 | Deferred to tomorrow | `顺延到明天` | `:33` |
| — | *（复用 `commonCancel`）* | 取消 | Cancel | `取消` | `:34` |
| A7 | `dialogReasonUnderestimated` / `dialog-reason-underestimated` | 预估不足 | Underestimated | `预估不足` | `:39` |
| A8 | `dialogReasonInterrupted` / `dialog-reason-interrupted` | 被打断 | Interrupted | `被打断` | `:40` |
| A9 | `dialogReasonExternal` / `dialog-reason-external` | 依赖外部 | Depends on external input | `依赖外部` | `:41` |
| A10 | `dialogReasonPriorityChanged` / `dialog-reason-priority-changed` | 优先级变了 | Priority changed | `优先级变了` | `:42` |
| A11 | `dialogReasonPoorState` / `dialog-reason-poor-state` | 状态不好 | Poor condition | `状态不好` | `:43` |
| A12 | `dialogReasonNoTime` / `dialog-reason-no-time` | 时间不够 | Not enough time | `时间不够` | `:44` |
| A13 | `dialogReasonUnclear` / `dialog-reason-unclear` | 信息不清 | Information unclear | `信息不清` | `:45` |
| A14 | `dialogReasonOther` / `dialog-reason-other` | 其他 | Other | `其他` | `:46` |
| A15 | `dialogNextStepContinueTomorrow` / `dialog-next-step-continue-tomorrow` | 明天继续 | Continue tomorrow | `明天继续` | `:51` |
| A16 | `dialogNextStepToTodo` / `dialog-next-step-to-todo` | 转成待办 | Convert to a to-do | `转成待办` | `:52` |
| A17 | `dialogNextStepHandOff` / `dialog-next-step-hand-off` | 交出去 | Hand off | `交出去` | `:53` |
| A18 | `dialogNextStepNarrowScope` / `dialog-next-step-narrow-scope` | 缩小范围 | Narrow the scope | `缩小范围` | `:54` |
| A19 | `dialogNextStepReviewLater` / `dialog-next-step-review-later` | 定日复盘 | Review on a set date | `定日复盘` | `:55` |
| A20 | `dialogNextStepStopHere` / `dialog-next-step-stop-here` | 就此停止 | Stop here | `就此停止` | `:56` |

### 3.3 键表 B · 项目页错误 7 条新键（落 `apps\desktop\lib\src\l10n\parts\projects.dart`）

| # | 键名（getter / kebab 键） | zh 文案 | en 文案（提案） | 来源 file:line | 落点说明 |
|---|---|---|---|---|---|
| B1 | `projectsInvalidDateFormat` / `projects-invalid-date-format` | 日期必须是 YYYY-MM-DD 格式 | Date must be in YYYY-MM-DD format | `projects_page.dart:303` | `_optionalDay` 抛 `FormatException` ⇒ 需把 `t` 传进 `_optionalDay` |
| B2 | `projectsDateNotExist` / `projects-date-not-exist` | 这个日期不存在 | This date does not exist | `projects_page.dart:310` | 同上 |
| B3 | `projectsNameRequired` / `projects-name-required` | 项目名称不能为空 | Project name cannot be empty | `projects_page.dart:512` | 表单内联校验 |
| B4 | `projectsTaskTitleRequired` / `projects-task-title-required` | 任务标题不能为空 | Task title cannot be empty | `projects_page.dart:1004` | 表单内联校验 |
| B5 | `projectsProgressRequired` / `projects-progress-required` | 至少写一句这次推进了什么 | Write at least one line about what you progressed | `projects_page.dart:1340` | 表单内联校验 |
| B6 | `projectsMilestoneMissing` / `projects-milestone-missing` | 任务 {id} 不存在 | Task {id} does not exist | `project_store.dart:400` | **需先把 `StateError` 改成类型化异常**（带 `kind` + `id`），否则取不到 id |
| B7 | `projectsProjectMissing` / `projects-project-missing` | 项目 {id} 不存在 | Project {id} does not exist | `project_store.dart:470` | 同上 |

> B6 / B7 的 `{id}` 注入方式沿用 `projectsUnscheduled`（`parts\projects.dart:177`，文本 `未排期 {n} 条`）的先例：getter 无参、占位在文本内、调用点 `replaceAll`。
> **备选方案（不推荐）**：保留 `StateError` 并在 UI 侧用正则从消息里解析 id —— 脆弱（消息文案一改就断），仅作兜底记录。

### 3.4 落库值 → 显示值映射表

| 落库值（中文，`ResultNote` 内实际存储） | 显示值（zh） | 显示值（en） | 映射到 |
|---|---|---|---|
| `按时完成` | 按时完成 | Completed on time | `dialogOutcomeOnTime` |
| `延后完成` | 延后完成 | Completed late | `dialogOutcomeLate` |
| `提前完成` | 提前完成 | Completed early | `dialogOutcomeEarly` |
| `部分完成` | 部分完成 | Partially completed | `dialogOutcomePartial` |
| `受阻` | 受阻 | Blocked | `dialogOutcomeBlocked` |
| `顺延到明天` | 顺延到明天 | Deferred to tomorrow | `dialogOutcomeDeferredTomorrow` |
| `取消` | 取消 | Cancel | `commonCancel`（复用） |
| `预估不足` | 预估不足 | Underestimated | `dialogReasonUnderestimated` |
| `被打断` | 被打断 | Interrupted | `dialogReasonInterrupted` |
| `依赖外部` | 依赖外部 | Depends on external input | `dialogReasonExternal` |
| `优先级变了` | 优先级变了 | Priority changed | `dialogReasonPriorityChanged` |
| `状态不好` | 状态不好 | Poor condition | `dialogReasonPoorState` |
| `时间不够` | 时间不够 | Not enough time | `dialogReasonNoTime` |
| `信息不清` | 信息不清 | Information unclear | `dialogReasonUnclear` |
| `其他` | 其他 | Other | `dialogReasonOther` |
| `明天继续` | 明天继续 | Continue tomorrow | `dialogNextStepContinueTomorrow` |
| `转成待办` | 转成待办 | Convert to a to-do | `dialogNextStepToTodo` |
| `交出去` | 交出去 | Hand off | `dialogNextStepHandOff` |
| `缩小范围` | 缩小范围 | Narrow the scope | `dialogNextStepNarrowScope` |
| `定日复盘` | 定日复盘 | Review on a set date | `dialogNextStepReviewLater` |
| `就此停止` | 就此停止 | Stop here | `dialogNextStepStopHere` |
| **（其它任意值 / 空串）** | 原样返回 | 原样返回 | 无（用户数据，非 UI 字面量） |

**映射函数落点（建议签名）**：

```dart
// apps\desktop\lib\src\widgets\outcome_composer.dart（值的所有者）
static String displayLabel(AppLocalizations t, String stored) {
  switch (stored) {
    case '按时完成': return t.dialogOutcomeOnTime;
    // … 21 条 …
    case '取消': return t.commonCancel;
    default: return stored;   // 未知历史值原样返回（同 app_localizations.dart:127-129 先例）
  }
}
```

**必须一并改的渲染点**（否则英文态仍上屏中文）：

| file:line | 现状 | 需要 |
|---|---|---|
| `outcome_composer.dart:176-177` | `ChipOption(key: label, label: label)` | `key:` 保持落库值；`label:` 改成映射后的显示值 |
| `outcome_composer.dart:188-189` | 同上 | 同上 |
| `outcome_composer.dart:200-201` | 同上 | 同上 |
| `plan_item_detail_dialog.dart:312-328` | 直接渲染 `OutcomeComposer.outcomeLabels / reasonLabels / nextStepLabels` | 改成渲染映射后的显示值（**结论文案在此处确实上屏，已坐实**） |
| `projects_page.dart:244` | `detail: increment.nextStep` | 显示时映射 |
| `projects_page.dart:1375-1383` | `_lineText` 拼装 | 显示时映射 |
| `slot_fill.dart:61` | 挂载 `OutcomeComposer` | **不用改**（只挂载，不含文案） |
| `slot_fill.dart:84-88` | 按 `'顺延到明天'` / `'取消'` 判定 | **不用改**（落库值判定，红线） |

### 3.5 `byGetter` 390 → 417 的连带改动清单（stage 4 逐项照做）

| # | 文件 | 改动 | 依据（file:line） |
|---|---|---|---|
| 1 | `apps\desktop\lib\src\l10n\parts\dialog.dart` | 抽象类新增 **20** 个 getter 声明（放「结果撰写」分组 `:254-260` 之后）+ zh 实现 + en 实现 | 分组注释 `:254-260`；字形约定注释 `:14-17` |
| 2 | `apps\desktop\lib\src\l10n\parts\projects.dart` | 抽象类新增 **7** 个 getter 声明 + zh 实现 + en 实现 | `:8-9`（键前缀约定 `projects-`） |
| 3 | `apps\desktop\lib\src\l10n\l10n_keys.dart` | 新增 **27** 个 kebab 键常量；`byGetter`（`:1490-1900`）加 **27** 条，按 parts 声明顺序插；注释 `:1486` 的「390 条」改 **417** | `:1486-1490` |
| 4 | `apps\desktop\test\l10n_harness.dart` | `l10nAccessors`（`:28-562`）加 **27** 条访问器；注释 `:27` 的「390 条」改 **417** | `:27-29`、`:556-562` |
| 5 | `apps\desktop\test\l10n_base_test.dart` | `:27-29` 断言 `390` → **417**（两处：`byGetter.length` 与 `l10nAccessors.length`）；`:111-117` 断言总键 `447` → **474**；`:44-109` 的 byMethod 名单**不动**（仍 53） | `:27-33`、`:111-118` |
| 6 | `apps\desktop\lib\src\widgets\outcome_composer.dart` | 新增显示映射函数 + 芯片 `label:` 走映射（**不改 21 条落库值**） | `:27-57`、`:174-209` |
| 7 | `apps\desktop\lib\src\widgets\plan_item_detail_dialog.dart` | 三组芯片的显示值走映射 | `:306-331` |
| 8 | `apps\desktop\lib\src\pages\projects_page.dart` | `_messageOf` 签名改为 `(AppLocalizations t, Object error)`，**7 个调用点** `:148` / `:166` / `:189` / `:207` / `:226` / `:250` / `:273` 全部补 `t`；`:303` / `:310` / `:512` / `:1004` / `:1340` 五处字面量换成 getter；`_optionalDay` 需要能拿到 `t` | `:284-292`、`:295-313`、`:511-513`、`:1003-1005`、`:1339-1341` |
| 9 | `apps\desktop\lib\src\data\project_store.dart` | `:400` / `:470` 的 `StateError` 换成**类型化异常**（带 `kind` + `id`）；`:916` / `:279` / `:335` / `:518` 四条不可达诊断串**保持不变**（不属缺口，改了反而扩大改动面） | `:399-401`、`:469-471` |
| 10 | `apps\desktop\lib\src\l10n\app_localizations.dart` | **不改**（27 键全为无参 getter ⇒ `AppLocalizations` 的既有结构不用动） | `:103-132` |

**门禁影响预判**：上述 1–10 涉及的文件 **全部在 `reports\task51-gate.ps1` 白名单内**（`parts\*.dart` `:227-246`、`l10n_keys.dart` `:194`/`:247`、`l10n_base_test.dart` `:206`、`l10n_harness.dart` `:207`、`outcome_composer.dart` `:269`、`plan_item_detail_dialog.dart` `:141`、`projects_page.dart` `:188`、`project_store.dart` `:187`、`app_localizations.dart` `:183`）⇒ **本方案不增加 `OUT_OF_SET`**。

**三个文件故意不碰**（避免 `OUT_OF_SET` +1，且落库值红线）：

| 文件 | 为什么碰不得 | 若必须碰（人工口径） |
|---|---|---|
| `apps\desktop\lib\src\widgets\shell\tool_rail.dart`（`:304` 全角 `＋`） | 不在门禁白名单 | 改 ⇒ 需先加白名单（人工验收点） |
| `apps\desktop\lib\src\widgets\slot_fill.dart`（`:84-88` 判定值） | 不在门禁白名单 + 落库值红线 | 不改 |
| `packages\core_domain\lib\src\entities.dart`（`:111`） | 不在门禁白名单 | 本地化它 ⇒ 需先加白名单（人工验收点，见 §7-Q5） |

---

## 4 · 验收③：35 条 file:line 级最终核对表

> 「存活」= 英文态下真的能在屏幕上看到中文；「人工口径」= 需要人工拍板后才决定算不算缺陷。

### 4.1 扫描面内（`apps\desktop\lib\**`）34 条

| # | file:line | 字面量 | 触达路径（为何上屏） | 判定 | 拟用键 / 处置 |
|---|---|---|---|---|---|
| 1 | `widgets\outcome_composer.dart:28` | `按时完成` | 芯片 label `:177` + 详情页 `plan_item_detail_dialog.dart:312-328` | 存活 ① | `dialogOutcomeOnTime` |
| 2 | `:29` | `延后完成` | 同上 | 存活 ① | `dialogOutcomeLate` |
| 3 | `:30` | `提前完成` | 同上 | 存活 ① | `dialogOutcomeEarly` |
| 4 | `:31` | `部分完成` | 同上 | 存活 ① | `dialogOutcomePartial` |
| 5 | `:32` | `受阻` | 同上 | 存活 ① | `dialogOutcomeBlocked` |
| 6 | `:33` | `顺延到明天` | 同上；`slot_fill.dart:84` 同字面量判定 | 存活 ① | `dialogOutcomeDeferredTomorrow`（落库值不动） |
| 7 | `:34` | `取消` | 同上；`slot_fill.dart:88` 同字面量判定 | 存活 ① | 复用 `t.commonCancel` |
| 8 | `:39` | `预估不足` | 芯片 label `:189` + 详情页 | 存活 ① | `dialogReasonUnderestimated` |
| 9 | `:40` | `被打断` | 同上 | 存活 ① | `dialogReasonInterrupted` |
| 10 | `:41` | `依赖外部` | 同上 | 存活 ① | `dialogReasonExternal` |
| 11 | `:42` | `优先级变了` | 同上 | 存活 ① | `dialogReasonPriorityChanged` |
| 12 | `:43` | `状态不好` | 同上 | 存活 ① | `dialogReasonPoorState` |
| 13 | `:44` | `时间不够` | 同上 | 存活 ① | `dialogReasonNoTime` |
| 14 | `:45` | `信息不清` | 同上 | 存活 ① | `dialogReasonUnclear` |
| 15 | `:46` | `其他` | 同上 | 存活 ① | `dialogReasonOther` |
| 16 | `:51` | `明天继续` | 芯片 label `:201` + 详情页 + `projects_page.dart:244` / `:1375-1383` | 存活 ① | `dialogNextStepContinueTomorrow` |
| 17 | `:52` | `转成待办` | 同上 | 存活 ① | `dialogNextStepToTodo` |
| 18 | `:53` | `交出去` | 同上 | 存活 ① | `dialogNextStepHandOff` |
| 19 | `:54` | `缩小范围` | 同上 | 存活 ① | `dialogNextStepNarrowScope` |
| 20 | `:55` | `定日复盘` | 同上 | 存活 ① | `dialogNextStepReviewLater` |
| 21 | `:56` | `就此停止` | 同上 | 存活 ① | `dialogNextStepStopHere` |
| 22 | `pages\projects_page.dart:303` | `日期必须是 YYYY-MM-DD 格式` | `_optionalDay` → `FormatException` → `_messageOf:289` → `_error` | 存活 ① | `projectsInvalidDateFormat` |
| 23 | `pages\projects_page.dart:310` | `这个日期不存在` | 同上 | 存活 ① | `projectsDateNotExist` |
| 24 | `pages\projects_page.dart:512` | `项目名称不能为空` | 表单内联 `_error` | 存活 ① | `projectsNameRequired` |
| 25 | `pages\projects_page.dart:1004` | `任务标题不能为空` | 表单内联 `_error` | 存活 ① | `projectsTaskTitleRequired` |
| 26 | `pages\projects_page.dart:1340` | `至少写一句这次推进了什么` | 表单内联 `_error` | 存活 ① | `projectsProgressRequired` |
| 27 | `data\project_store.dart:400` | `任务 $milestoneId 不存在` | `StateError` → 通用 `catch` → `_messageOf:291` `'$error'` | 存活 ① | `projectsMilestoneMissing`（+ 类型化异常） |
| 28 | `data\project_store.dart:470` | `项目 $projectId 不存在` | 同上 | 存活 ① | `projectsProjectMissing`（+ 类型化异常） |
| 29 | `widgets\habit_quick_dialog.dart:391` | `＋`（U+FF0B） | 按钮字形，英文态显示全角加号 | **人工口径 Q3** | 不改 / 不新增键 |
| 30 | `widgets\habit_quick_dialog.dart:496` | `＋`（U+FF0B） | 同上 | **人工口径 Q3** | 不改 / 不新增键 |
| 31 | `widgets\shell\tool_rail.dart:304` | `＋`（U+FF0B） | 同上；**该文件不在门禁白名单** | **人工口径 Q3** | 不改 / 不新增键 |
| 32 | `l10n\parts\dialog.dart:894` | `＋`（U+FF0B，En mixin） | En 态渲染 | **人工口径 Q3** | 不改 / 不新增键 |
| 33 | `l10n\parts\dialog.dart:960` | `＋`（U+FF0B，En mixin） | En 态渲染 | **人工口径 Q3** | 不改 / 不新增键 |
| 34 | `l10n\parts\settings.dart:239` | `简体中文`（En mixin） | En 态语言名自述 | **人工口径 Q4**（`sameValueWhitelist` 已豁免） | 不改 |

### 4.2 扫描面外 1 条（`packages\**`，§68.4b 扫描面之外）

| # | file:line | 字面量 | 触达路径 | 判定 | 处置 |
|---|---|---|---|---|---|
| 35 | `packages\core_domain\lib\src\entities.dart:111` | `$field 必须是 YYYY-MM-DD 格式，实际 "$v"` | `DomainValidationException.message`（`:64-70`）⇒ 被 `projects_page._messageOf` 的 `ArgumentError` 分支之外的上屏路径（异常消息本身带中文） | 存活 ①（**扫描面外**） | 需类型化（带 field + value）+ 新键；**该文件不在门禁白名单 ⇒ 人工验收点 Q5** |

### 4.3 相邻未判定面（本环登记，未下结论）

| # | file:line | 字面量 | 说明 |
|---|---|---|---|
| U5 | `packages\core_data\lib\src\repositories.dart:47-50` | `必须是合法的 YYYY-MM-DD 日历日` | `ArgumentError.value(date, name, …)` ⇒ 若该函数被 `projects_page` 的 `catch` 覆盖，则与 #35 同类会上屏。**本环未追完调用链** ⇒ 若 stage 4 追到，全域缺口将变成 **36 条** |

### 4.4 已排除项（供 stage 4 / stage 6 复用，不必重查）

| 类别 | 条数 | 代表 file:line | 排除理由 |
|---|---|---|---|
| 格言 | 449（扫描面内） | `data\quote.dart:7-14`（`Quote({required this.en, required this.zh})`）+ `quote_banner.dart:100`（`isZh` 分叉） | 双语结构，中文是数据不是 UI 字面量 |
| `key_bar` | 8 | `key_bar.dart:44` / `:46-53` / `:76-85` | 运行期走 `shellKeyHintsFor`，中文只是 const 测试快照 |
| `nav_rail` | 6 | `nav_rail.dart:34` / `:36-41` / `:50-57` | 运行期走 `shellNavItemsFor` |
| `domain_chips` | 12 | `domain_chips.dart:19-28` / `:70-86` | 落库值 |
| `est_duration_text` | 5 | `est_duration_text.dart:17-29` | 落库值 |
| `gantt_chart` | 3 | `gantt_chart.dart:84` / `:85` / `:192` | 死默认（唯一调用点 `projects_page.dart:407-413` 全部覆盖） |
| `slot_fill` | 2 | `slot_fill.dart:84-88` | 落库值 / 判定值 |
| `habit_quick_dialog:200` | 1 | `habit_quick_dialog.dart:200` | 落库值 `targetUnit: '次'` |
| `habits_page` | 1 | `habits_page.dart:230` | 已有 `t.commonUnitTimes` 通路 |
| `habit_section` | 1 | `habit_section.dart:158` | `stored == '次' ? t.commonUnitTimes : stored` 已有映射 |
| `priority_marks` | 1 | `priority_marks.dart:93-96` | 断言内文案 |
| `review_section` | 1 | `review_section.dart:167` | 正则内文案 |
| `providers` | 1 | `providers.dart:22` | 注释 |
| `toast_probe` | 1 | `toast_probe.dart:111` | 探针消息，默认不启用（见 U2） |
| `project_store`（其余 4 条） | 4 | `:279` / `:335` / `:518-522` / `:916` | 不可达（见 U1） |
| l10n 正常文案 | 482 | `apps\desktop\lib\src\l10n\**` | zh 侧正常文案 + en 侧已本地化文案 |
| `简体中文` | 1 | `l10n\parts\settings.dart:239`（zh `:138`） | `sameValueWhitelist`（`l10n_harness.dart:586-589`）已固化为不变量；改它会让 `l10n_base_test.dart:256-258` 红 |

---

## 5 · 验收④：写集自证与 git status 计数

### 5.1 开工必做项：接力章节回读（AGENTS.md）

- 开工回读 `AGENTS.md` **496 行**（stage-2 时为 494 行 ⇒ 期间被并发会话改动，**非本环**），接力章节在 **`:487-494`**（「## 自动接力（Relay）—— 硬规则」6 条全在）。
- 关键条款逐条确认在场：`:491` 开工先读 `relay.json`；`:492` 只允许写 `stages[current_stage].scope` 声明的写集 + §5 并发检测；`:493` 收尾顺序（**先回写 `relay.json` → 再 `session_create` → 再回写 `next_session_id`**）；`:494` 命中人工验收点 ⇒ `status=blocked` 且不起新会话。
- **章节未被抹掉** ⇒ 本环正常推进，不写 `blocked`。

### 5.2 并发检测

| 时点 | `git status --porcelain` | `HEAD` | 说明 |
|---|---|---|---|
| 开工（21:55） | **18 行** | `01b6339` | 并发 Task 68 会话 dirty 集含 `l10n/**`、`test/l10n_*`、`widgets/recurring_*`、`packages/core_domain/**`、计划文件等 |
| 22:09（收尾前复核） | **5 行** | **`85b809a`** | 并发会话**已提交**（`01b6339` → `85b809a`），porcelain 由 18 降为 5 |

**并发写集 vs 本环写集**：并发会话脏的是 `l10n/**`、`test/l10n_*`、`widgets/recurring_*`、`packages/core_domain/**`、计划文件；本环只写 `docs\relay\stage-3-report.md` 与 `docs\relay.json` ⇒ **零交集** ⇒ 本环可安全写。

### 5.3 写集自证（关键：porcelain 计数**不能**用来证明只读）

- `docs\relay\` 是**未跟踪目录** ⇒ porcelain 只输出 1 行 `?? docs/relay/` ⇒ 本环在目录内新建文件**不改变计数**。
- ⇒ 只读自证改用**文件清单 + 指纹**（下表）。

| 文件 | 动作 | 写前 | 写后 |
|---|---|---|---|
| `docs\relay\stage-3-report.md` | **新建**（本文件） | 不存在（`Test-Path` = False） | 见 §10 |
| `docs\relay.json` | **只追加回写**（stage 3 条目 → done、`current_stage` → 4、追加 stage 4 条目、`sessions` 追加 stage 4 会话、最后回写 `next_session_id`） | 21727 B / 22:00:41 / sha16 `A3CE91176C92FA05` | 见 §10 |

**本环未改动（写后指纹复核，关键文件）**：

| 文件 | 大小 | mtime | sha16（SHA256 前 16 位） |
|---|---|---|---|
| `AGENTS.md` | 284030 B | 22:03:49 | `ED60373B5EE00598` |
| `apps\desktop\lib\src\l10n\l10n_keys.dart` | 78463 B | 21:18:21 | `1EDAEBC8D2A5E16A` |
| `apps\desktop\lib\src\l10n\app_localizations.dart` | 6272 B | 09:16:32 | `DCD8C65E164F632D` |
| `apps\desktop\lib\src\l10n\parts\dialog.dart` | 34374 B | 17:42:26 | `49CDE3DC80808C39` |
| `apps\desktop\lib\src\l10n\parts\projects.dart` | 10158 B | 21:11:45 | `D0B9AE5550E440FD` |
| `apps\desktop\test\l10n_base_test.dart` | 28982 B | 21:17:39 | `BC6E686C0E375E13` |
| `apps\desktop\test\l10n_harness.dart` | 36066 B | 21:17:38 | `AA12CF8994843FEB` |
| `apps\desktop\lib\src\widgets\outcome_composer.dart` | 7738 B | 17:42:51 | `F35E971C9471E02B` |
| `apps\desktop\lib\src\pages\projects_page.dart` | 50520 B | 00:23:31 | `9FA9AA16360F9AB0` |
| `apps\desktop\lib\src\data\project_store.dart` | 32198 B | 00:14:45 | `A90A158F8C1ECD24` |
| `packages\core_domain\lib\src\entities.dart` | 26354 B | — | `ED85A2F77239D0F1` |
| `docs\relay\stage-2-scope.md` | 30362 B | 21:58:35 | `ADF4515E55946D48` |

> **指纹算法口径**：本环一律用 **SHA256 前 16 位**；stage-2 的指纹是 **SHA1 数值** ⇒ **两套数字不可直接对比**（误比对会误判「文件被改」）。stage 4 请统一到 SHA256 前 16 位。

### 5.4 §5.5 偏离登记（收尾前重新读盘）

- 收尾前重新读盘 `docs\relay.json`：21727 B / 22:00:41 / sha16 `A3CE91176C92FA05`（stage-2 收尾写盘后的字节）⇒ **期间无第三方写入**（stage-2 记录的「root 会话中途加字段」在本环窗口内未再发生）。
- 回写方式：**在最新字节上定点替换**，只动 ① `stages[2]`（stage 3 条目）② `stages` 追加 stage 4 条目 ③ `current_stage` ④ `sessions` 追加 stage 4 会话 ⑤ `next_session_id`。
- **不得改**：`stages[0]` / `stages[1]`、`top-level` 的 `concurrency` / `next_stage_target` / `model_policy` / `human_checkpoints` / `stop_conditions` / `goal` / `plan_doc` / `plan_doc_note` / `ledger_docs` / `protocol` / `adaptation_note` / `workspace_dir` / `status` / `auto_relay` / `max_stages` / `started_at` / `started_by`。
- 回写后回读核对：顶层 key 数量零丢失、`stages` 条数 3 → 4、`sessions` 条数 4 → 5、`current_stage` = 4。

---

## 6 · 验收⑤：与 stage-2 结论的差异登记

| # | stage-2 结论 | 本环复核结论 | 差异原因（直接证据） |
|---|---|---|---|
| D1 | 缺口 32 条（29 widget + 3 En mixin） | **34 条**（扫描面内）+ **1 条**（扫描面外）= **35 条** | `project_store.dart:400` / `:470` 两条 `StateError` 经 `_messageOf:291` 的 `'$error'` 分支上屏（stage-2 记为「未判定」）；`core_domain\entities.dart:111` 的 `DomainValidationException` 消息亦上屏 |
| D2 | 21 条结论文案属「落库值」，故**不改** | **不改字面量，但必须改显示**：落库值照旧，英文态显示走本地化 getter | `outcome_composer.dart:176-177` / `:188-189` / `:200-201` 把落库值直接当芯片 `label:` 渲染；`plan_item_detail_dialog.dart:312-328` 同上 ⇒ 落库 ≠ 显示，必须做映射层 |
| D3 | 新增 25 条键；`byGetter` 390 → 415 | **27 条**；`byGetter` 390 → **417**；总键 447 → **474** | 多出的 2 条 = 两条 `StateError` 的类型化消息（B6 / B7） |
| D4 | `byMethod` 53 → 78（stage-2 初稿口径） | **53 → 53（不变）** | 27 个新键全部设计为**无参 String getter**（含 2 条 `{id}` 占位 + `replaceAll`，先例 `parts\projects.dart:177`）⇒ `l10n_base_test.dart:44-109` 的 byMethod 显式名单不动 |
| D5 | `简体中文`（`settings.dart:239`）算 3 条 En mixin 缺口之一 | **不算缺口**（人工口径 Q4） | `l10n_harness.dart:586-589` 的 `sameValueWhitelist` 已把语言名母语显示固化为不变量；改它会让 `l10n_base_test.dart:256-258` 红 |
| D6 | 全角 `＋` 5 处算缺口 | 仍算缺口，但**归人工口径 Q3、不新增键**（3 处 widget + 2 处 En mixin） | `l10n\parts\dialog.dart:17` 仓内约定：「全角 `＋`（U+FF0B）是按钮字形，不是文案」 |
| D7 | 68.4b 判据 = 扫描面 `apps\desktop\lib\**` 全量 | 维持，但**新增「扫描面外 1 条 + 相邻未判定 1 条」** | §68.4b 的扫描面是 `apps\desktop\lib\**`；`packages\core_domain` / `packages\core_data` 在扫描面外，但错误消息确实能上屏 |
| D8 | 未登记 U5 | **新增相邻未判定面 U5**（`packages\core_data\lib\src\repositories.dart:47-50`） | 该 `ArgumentError` 若被 UI `catch` 覆盖即上屏，本环未追完调用链 |

---

## 7 · 人工验收点 / 需拍板事项（本环只登记，**不自行取舍**）

| 编号 | 事项 | 现状 | 影响 | 建议拍板人 |
|---|---|---|---|---|
| Q1 | 450 条格言是否换数据集 | `data\quote.dart:7-14` 双语结构 + `quote_banner.dart:100` `isZh` 分叉 ⇒ **不属 l10n 缺口** | 只影响产品内容，不影响代码 | 产品 |
| Q2 | 格言英文译文是否要审校 | 现译未审校 | 只影响文案质量 | 产品 |
| Q3 | 全角 `＋`（U+FF0B）算不算缺陷 | 仓内约定「是按钮字形，不是文案」（`l10n\parts\dialog.dart:17`） | 若算缺陷 ⇒ 需改 `habit_quick_dialog.dart:391/:496`、`tool_rail.dart:304`、`parts\dialog.dart:894/:960`；其中 `tool_rail.dart` **不在门禁白名单** ⇒ 需先加白名单 | 人工验收点（AGENTS.md §4） |
| Q4 | `简体中文` 语言名自述 | 已被 `sameValueWhitelist` 豁免 | 改了会让 `l10n_base_test.dart:256-258` 红 | 产品 |
| Q5 | 扫描面外那条（`core_domain\entities.dart:111`）要不要本地化 | 若本地化 ⇒ 需改 `packages\core_domain\lib\src\entities.dart` ⇒ **门禁 `OUT_OF_SET` +1**，须先加白名单 | 全域缺口 35 或 34 | 人工验收点 |
| Q6 | `project_store` 两条 `StateError` 的改法 | 推荐：**类型化异常**（带 `kind` + `id`），备选：UI 侧正则解析消息（脆弱） | 影响 B6 / B7 两键能否注入 id | 控制器 + 人工确认 |
| Q7 | `parts\dialog.dart:254-259` 的注释冲突 | 该注释断言 21 条落库值「**永不在本文件出现**」；而 stage 4 要在**同文件**新增这 21 条的**显示**文案键（zh 值 = 同字面量） | 注释与实现自相矛盾 ⇒ **stage 4 必须同步改这段注释**（属设计取舍，不是 bug） | 控制器（改注释措辞） |
| Q8 | 门禁红灯 `OUT_OF_SET` 的归属 | `reports\task51-gate.ps1` 的 `$patterns` 未含 `docs\relay\**` ⇒ 接力链自建文档一直算 OUT_OF_SET | 不属本链自改范围 | 人工验收点 |

> **命中 `human_checkpoints` ⇒ `status=blocked` + `note` 且不起新会话**（AGENTS.md `:494`）。本环判定：Q1–Q8 **均不需要阻断本链推进** —— Q3 / Q4 / Q5 / Q6 已分别落入 stage 5（人工口径批次）与 stage 4 的**可选**加固项，不影响 stage 4 落地 27 键。故本环 `status = done`，正常起 stage 4。

---

## 8 · 验收⑥：stage 4 的范围与前置条件

### 8.1 stage 4 做什么

| 项 | 内容 |
|---|---|
| 标题 | 落地 27 条新键 + 35 处显示映射（**实现经 worker 子会话；控制器不碰 `apps\`**） |
| 类型 | `implement_l10n_keys` |
| 写集 | `apps\desktop\lib\src\l10n\parts\{dialog,projects}.dart`、`apps\desktop\lib\src\l10n\l10n_keys.dart`、`apps\desktop\test\l10n_{base_test,harness}.dart`、`apps\desktop\lib\src\widgets\{outcome_composer,plan_item_detail_dialog}.dart`、`apps\desktop\lib\src\pages\projects_page.dart`、`apps\desktop\lib\src\data\project_store.dart` + 本环文档与 `docs\relay.json` 的台账行 |
| 必做 | ① 按 §3.5 清单逐项落码 ② 落库值红线校验（21 条结论文案 + `次` + `顺延到明天` / `取消` 判定值一字不改） ③ 断言改为 417 / 474 ④ byMethod 名单不动 ⑤ 门禁 `OUT_OF_SET` 不增加 ⑥ 交付 `docs\relay\stage-4-implementation.md` |
| 验收 | 门禁重跑 `OUT_OF_SET` 不增、desktop 逐包 analyze 逐字 `No issues found!`、l10n 基线测试按当轮真实用例数通过、§68.4b 复扫英文态可见中文 = 0（本轮 27 键落地后仍剩的只有 Q3 / Q4 / Q5 口径项） |

### 8.2 前置条件（stage 4 开工必查）

| # | 条件 | 检查方式 |
|---|---|---|
| P1 | 并发 Task 68 会话已收口，`l10n\**` 与 `test\l10n_*` **不再 dirty** | `git status --porcelain` + `HEAD` 复核；脏了就等或改期 |
| P2 | `l10n_keys.dart` 的 `byGetter` 仍为 **390** 条、测试仍断言 **390 / 447** | 读 `l10n_keys.dart:1486-1490`、`l10n_base_test.dart:27-33` / `:111-118`；**若已被并发会话改过，以磁盘为准重算增量** |
| P3 | `AGENTS.md` 接力章节仍在（`:487-494`） | 开工第一步回读；被抹掉 ⇒ `status=blocked` |
| P4 | `docs\relay.json` 收尾前**重新读盘**（§5.5） | 读盘 + sha16 比对 |
| P5 | 门禁 `-ExpectDesktopTests` 按**当轮真实用例数**填 | 跑完看真实数再填 |
| P6 | Q3 / Q4 / Q5 / Q6 若要一起做，先确认白名单改动属人工验收点 | 与人工确认 |

### 8.3 本环**不**给 stage 4 的东西

- 不给「已实现」结论（本环零落码）。
- 不给「门禁已绿」结论（本环未亲跑门禁 / 测试 / analyze；§68.7 记的 gate run3 是 **21:57:47 / HEAD `01b6339`** 的并发会话输出，**不是本环实测**）。
- 不替 Q1–Q8 作取舍。

---

## 9 · 未做 / 未验证（不得当作已完成）

- **未亲跑全量 `flutter test`**（desktop 836 / core_data 204 / core_db 71 / core_domain 62）—— 该数字取自 `reports\task68-gate-run1.log`（RUN_AT 21:35:39 / HEAD `01b6339`）的并发门禁输出，**不是本环实测**；本环为避免与并发门禁抢 `apps\desktop\build\test_cache\build` 与 `sqlite3.dll` 未跑。
- **未跑逐包 analyze** —— 同上，非本环实测。
- **未做真机 / 打包 / 分发** —— 68.4h 属人工验收点。
- **68.4g verifier 终判未出** —— 本环不代打勾。
- **§68.4b / §68.4i 仍未勾** —— 复扫是 stage 6 的活；本环只交付了可复跑口径与实测数字。
- **U4 的「哪个 `catch` 块 ↔ 哪次 store 调用」未逐点配对** —— 见 §2.4「未核实项」；结论（会走 `'$error'` 分支）不受影响。
- **U5（`packages\core_data\lib\src\repositories.dart:47-50`）调用链未追完** —— 全域缺口可能是 35 或 36。
- **扫描器口径 7 条差异未逐条定位** —— 影响面仅「口径一致性」，不影响缺口数（缺口按 file:line 逐条回读判定）。
- **`l10n_keys.dart` / `l10n_base_test.dart` 的 390 / 447 读数取自本环磁盘实测** —— 但并发会话在 21:18 后仍可能改这两个文件 ⇒ stage 4 开工必须按 P2 重读。

---

## 10 · 指针与产物

| 指针 | 用途 |
|---|---|
| `F:\soft\00selfmade\practilog\docs\relay\stage-3-report.md` | **本环交付**（本文件） |
| `F:\soft\00selfmade\practilog\docs\relay\stage-2-scope.md` | 第 2 环：范围定稿 + 68 条切分（`§6` = U1–U4 复验方法，`§7` = stage 4/5/6 切分） |
| `F:\soft\00selfmade\practilog\docs\relay\stage-1-inventory.md` | 第 1 环：批次盘点 |
| `F:\soft\00selfmade\practilog\docs\relay.json` | 状态机（stage 3 条目 → done、`current_stage` → 4、追加 stage 4 条目、`sessions` 追加 stage 4 会话、`next_session_id`） |
| `F:\soft\00selfmade\practilog\docs\RELAY-ADAPTATION.md` | 裁决文档（§1 顺序 / §4 人工验收点 / §5 并发检测 / §9 模型策略） |
| `F:\soft\00selfmade\practilog\AGENTS.md` `:487-494` | 接力硬规则（每环开工必回读） |
| `F:\soft\00selfmade\practilog\apps\desktop\lib\src\widgets\outcome_composer.dart` `:27-57` / `:174-209` | 21 条落库值 + 芯片渲染点 |
| `F:\soft\00selfmade\practilog\apps\desktop\lib\src\pages\projects_page.dart` `:284-292` / `:295-313` | `_messageOf` 与 `_optionalDay` |
| `F:\soft\00selfmade\practilog\apps\desktop\lib\src\data\project_store.dart` `:399-401` / `:469-471` | 两条上屏 `StateError` |
| `F:\soft\00selfmade\practilog\apps\desktop\test\l10n_base_test.dart` `:27-33` / `:44-109` / `:111-118` | 键数断言 + byMethod 名单 |
| `F:\soft\00selfmade\practilog\apps\desktop\test\l10n_harness.dart` `:27-29` / `:586-589` | 访问器表 + 同值白名单 |
| `F:\soft\00selfmade\practilog\apps\desktop\lib\src\l10n\l10n_keys.dart` `:1486-1490` / `:1906-1911` / `:1914` | `byGetter` / `byListGetter` / `byMethod` 三表 |
| `F:\soft\00selfmade\practilog\packages\core_domain\lib\src\entities.dart` `:64-70` / `:111` | 扫描面外的领域异常 |
| `F:\soft\00selfmade\practilog\reports\task51-gate.ps1` `:141/:183/:187/:188/:194/:206/:207/:227-246/:263/:269` | 门禁白名单实测行号 |
| `F:\soft\00selfmade\practilog\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` `:9611-9619` / `:9631-9649` | 台账真源 §68.4a–i / §68.6 / §68.7 |
| `F:\soft\00selfmade\practilog\reports\task68-gate-run1.log` | 并发门禁原始输出（**引用，非本环实测**） |
| `F:\soft\00selfmade\practilog\reports\task68-deadlock-scan.md` | worker B 扫描报告（口径差异 7 条的来源之一） |
