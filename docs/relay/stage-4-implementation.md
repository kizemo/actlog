# stage-4 实施报告：27 条新 l10n 键 + 显示映射落码

> 范围：把 `docs\relay\stage-3-report.md` §3.2 / §3.3 的 **27 条新键** 与 §3.4 的**显示映射**真正落码。
> 写集：`apps\desktop\lib\src\l10n\parts\{dialog,projects}.dart`、`apps\desktop\lib\src\l10n\l10n_keys.dart`、
> `apps\desktop\test\l10n_{base_test,harness}.dart`、`apps\desktop\lib\src\widgets\outcome_composer.dart`、
> `apps\desktop\lib\src\widgets\timeline\plan_item_detail_dialog.dart`、`apps\desktop\lib\src\pages\projects_page.dart`、
> `apps\desktop\lib\src\data\project_store.dart` + 本文件。
> 依据：`AGENTS.md`（唯一真源）、`docs\relay\stage-2-scope.md`、`docs\relay\stage-3-report.md`。
> **本轮未运行 `reports\task51-gate.ps1`**（派工书明令禁止跑/改门禁脚本）；§⑥ 是按门禁源码口径做的**独立复算**。

---

## ① 27 键落码清单

全部 **27 个键都是无参 `String` getter** ⇒ `l10n_keys.dart` 的 `byMethod`（53 条）与 `byListGetter`（4 条）**未动**，
`sameValueWhitelist` 仍是 **2 条**（未扩充）。所有行号 = **改完后重新读盘的真实 file:line**。

### A 组 · 20 条（`apps\desktop\lib\src\l10n\parts\dialog.dart`）

| # | getter | kebab 键 | zh 文案 | en 文案 | 抽象声明 | zh 实现 | en 实现 | kebab 常量 |
|---|---|---|---|---|---|---|---|---|
| 1 | `dialogOutcomeOnTime` | `dialog-outcome-on-time` | 按时完成 | Completed on time | `parts\dialog.dart:289` | `parts\dialog.dart:712` | `parts\dialog.dart:1092` | `l10n_keys.dart:1415` |
| 2 | `dialogOutcomeLate` | `dialog-outcome-late` | 延后完成 | Completed late | `parts\dialog.dart:292` | `parts\dialog.dart:716` | `parts\dialog.dart:1095` | `l10n_keys.dart:1418` |
| 3 | `dialogOutcomeEarly` | `dialog-outcome-early` | 提前完成 | Completed early | `parts\dialog.dart:295` | `parts\dialog.dart:720` | `parts\dialog.dart:1098` | `l10n_keys.dart:1421` |
| 4 | `dialogOutcomePartial` | `dialog-outcome-partial` | 部分完成 | Partially completed | `parts\dialog.dart:298` | `parts\dialog.dart:724` | `parts\dialog.dart:1101` | `l10n_keys.dart:1424` |
| 5 | `dialogOutcomeBlocked` | `dialog-outcome-blocked` | 受阻 | Blocked | `parts\dialog.dart:301` | `parts\dialog.dart:728` | `parts\dialog.dart:1104` | `l10n_keys.dart:1427` |
| 6 | `dialogOutcomeDeferredTomorrow` | `dialog-outcome-deferred-tomorrow` | 顺延到明天 | Deferred to tomorrow | `parts\dialog.dart:304` | `parts\dialog.dart:732` | `parts\dialog.dart:1107` | `l10n_keys.dart:1431` |
| 7 | `dialogReasonUnderestimated` | `dialog-reason-underestimated` | 预估不足 | Underestimated | `parts\dialog.dart:307` | `parts\dialog.dart:736` | `parts\dialog.dart:1110` | `l10n_keys.dart:1435` |
| 8 | `dialogReasonInterrupted` | `dialog-reason-interrupted` | 被打断 | Interrupted | `parts\dialog.dart:310` | `parts\dialog.dart:740` | `parts\dialog.dart:1113` | `l10n_keys.dart:1438` |
| 9 | `dialogReasonExternal` | `dialog-reason-external` | 依赖外部 | Depends on external input | `parts\dialog.dart:313` | `parts\dialog.dart:744` | `parts\dialog.dart:1116` | `l10n_keys.dart:1441` |
| 10 | `dialogReasonPriorityChanged` | `dialog-reason-priority-changed` | 优先级变了 | Priority changed | `parts\dialog.dart:316` | `parts\dialog.dart:748` | `parts\dialog.dart:1119` | `l10n_keys.dart:1445` |
| 11 | `dialogReasonPoorState` | `dialog-reason-poor-state` | 状态不好 | Poor condition | `parts\dialog.dart:319` | `parts\dialog.dart:752` | `parts\dialog.dart:1122` | `l10n_keys.dart:1448` |
| 12 | `dialogReasonNoTime` | `dialog-reason-no-time` | 时间不够 | Not enough time | `parts\dialog.dart:322` | `parts\dialog.dart:756` | `parts\dialog.dart:1125` | `l10n_keys.dart:1451` |
| 13 | `dialogReasonUnclear` | `dialog-reason-unclear` | 信息不清 | Information unclear | `parts\dialog.dart:325` | `parts\dialog.dart:760` | `parts\dialog.dart:1128` | `l10n_keys.dart:1454` |
| 14 | `dialogReasonOther` | `dialog-reason-other` | 其他 | Other | `parts\dialog.dart:328` | `parts\dialog.dart:764` | `parts\dialog.dart:1131` | `l10n_keys.dart:1457` |
| 15 | `dialogNextStepContinueTomorrow` | `dialog-next-step-continue-tomorrow` | 明天继续 | Continue tomorrow | `parts\dialog.dart:331` | `parts\dialog.dart:768` | `parts\dialog.dart:1134` | `l10n_keys.dart:1461` |
| 16 | `dialogNextStepToTodo` | `dialog-next-step-to-todo` | 转成待办 | Convert to a to-do | `parts\dialog.dart:334` | `parts\dialog.dart:772` | `parts\dialog.dart:1137` | `l10n_keys.dart:1464` |
| 17 | `dialogNextStepHandOff` | `dialog-next-step-hand-off` | 交出去 | Hand off | `parts\dialog.dart:337` | `parts\dialog.dart:776` | `parts\dialog.dart:1140` | `l10n_keys.dart:1467` |
| 18 | `dialogNextStepNarrowScope` | `dialog-next-step-narrow-scope` | 缩小范围 | Narrow the scope | `parts\dialog.dart:340` | `parts\dialog.dart:780` | `parts\dialog.dart:1143` | `l10n_keys.dart:1471` |
| 19 | `dialogNextStepReviewLater` | `dialog-next-step-review-later` | 定日复盘 | Review on a set date | `parts\dialog.dart:343` | `parts\dialog.dart:784` | `parts\dialog.dart:1146` | `l10n_keys.dart:1475` |
| 20 | `dialogNextStepStopHere` | `dialog-next-step-stop-here` | 就此停止 | Stop here | `parts\dialog.dart:346` | `parts\dialog.dart:788` | `parts\dialog.dart:1149` | `l10n_keys.dart:1478` |

### B 组 · 7 条（`apps\desktop\lib\src\l10n\parts\projects.dart`）

| # | getter | kebab 键 | zh 文案 | en 文案 | 抽象声明 | zh 实现 | en 实现 | kebab 常量 |
|---|---|---|---|---|---|---|---|---|
| 21 | `projectsInvalidDateFormat` | `projects-invalid-date-format` | 日期必须是 YYYY-MM-DD 格式 | Date must be in YYYY-MM-DD format | `parts\projects.dart:145` | `parts\projects.dart:292` | `parts\projects.dart:443` | `l10n_keys.dart:662` |
| 22 | `projectsDateNotExist` | `projects-date-not-exist` | 这个日期不存在 | This date does not exist | `parts\projects.dart:148` | `parts\projects.dart:295` | `parts\projects.dart:446` | `l10n_keys.dart:665` |
| 23 | `projectsNameRequired` | `projects-name-required` | 项目名称不能为空 | Project name cannot be empty | `parts\projects.dart:151` | `parts\projects.dart:298` | `parts\projects.dart:449` | `l10n_keys.dart:668` |
| 24 | `projectsTaskTitleRequired` | `projects-task-title-required` | 任务标题不能为空 | Task title cannot be empty | `parts\projects.dart:154` | `parts\projects.dart:301` | `parts\projects.dart:452` | `l10n_keys.dart:672` |
| 25 | `projectsProgressRequired` | `projects-progress-required` | 至少写一句这次推进了什么 | Write at least one line about what you progressed | `parts\projects.dart:157` | `parts\projects.dart:304` | `parts\projects.dart:455` | `l10n_keys.dart:675` |
| 26 | `projectsMilestoneMissing` | `projects-milestone-missing` | 任务 {id} 不存在 | Task {id} does not exist | `parts\projects.dart:160` | `parts\projects.dart:307` | `parts\projects.dart:459` | `l10n_keys.dart:678` |
| 27 | `projectsProjectMissing` | `projects-project-missing` | 项目 {id} 不存在 | Project {id} does not exist | `parts\projects.dart:163` | `parts\projects.dart:310` | `parts\projects.dart:462` | `l10n_keys.dart:681` |

**落点说明**

- A 组放在**既有** `parts\dialog.dart` 的「结果撰写（出处：`widgets\outcome_composer.dart`）」分组，**不新建** `parts\outcome.dart`
  （新建 parts 文件 ⇒ 门禁 `OUT_OF_SET` +1）。
- B 组放在 `parts\projects.dart` 末尾（`projectsDomainHealth` 之后）。
- `l10n_keys.dart`：`byGetter` 同步插入 27 行（dialog 组在 `'dialogNoteDone'` 之后，projects 组在 `'projectsDomainHealth'` 之后）。
- `apps\desktop\lib\src\l10n\app_localizations.dart` **未改**：27 键全为无参 getter，聚合类结构无需变。
- zh 文案**逐字等于现界面文字**；en 文案逐字取自 stage-3 §3.2 / §3.3 提案，且**每条 en ≠ zh**（`l10n_base_test.dart` 的「除白名单外，中英两态必须不同」用例实测通过）。

---

## ② 落库值红线自证

**落库值 = 用户数据，不是 UI 字面量，一个字都不能改。**

1. **21 条结论文案一字未改** —— `apps\desktop\lib\src\widgets\outcome_composer.dart:27-57`（改完后原样）：

```dart
static const List<String> outcomeLabels = <String>[
  '按时完成','延后完成','提前完成','部分完成','受阻','顺延到明天','取消',
];
static const List<String> reasonLabels = <String>[
  '预估不足','被打断','依赖外部','优先级变了','状态不好','时间不够','信息不清','其他',
];
static const List<String> nextStepLabels = <String>[
  '明天继续','转成待办','交出去','缩小范围','定日复盘','就此停止',
];
```

   这三个 `const List<String>` **只读不改**，只作为「显示映射」的输入。

2. **映射函数读落库值，不写落库值** —— 新增 `OutcomeComposer.displayLabel(AppLocalizations t, String stored)`
   （`outcome_composer.dart:68-118`）：`case '按时完成':` … `case '就此停止':` 逐条匹配落库值字面量；
   `default:`（`:112`）**原样返回 `stored`** —— 未知历史值不猜译名（先例：`app_localizations.dart` 的
   `projectDomainLabel`）。zh 文案与落库值同形，所以 zh 态显示与改前完全一致。

3. **写库用的 `key` 仍是落库值** —— `ChipOption.key` = 落库值，`ChipOption.label` = 显示值：
   - `outcome_composer.dart:236 / :251 / :266`：`key: label,`（`label` 是 `const List` 里的落库值）
   - `widgets\timeline\plan_item_detail_dialog.dart:299`：`key: label,`
   ⇒ 选中态 / 回填逻辑（`selected:`、`_setSegment`、`_applyChipTap`）判的仍是**中文落库值**，未改。

4. **`slot_fill.dart` 未改**（写集外，只读）—— `:84-88` 的 `'顺延到明天'` / `'取消'` **判定值**原样保留。

5. **习惯单位 `次` 未改**（`habit_quick_dialog.dart`，写集外）。

6. **`project_store.dart` 的 4 条中文诊断串一字未改**（stage-3 §3.5 第 9 项口径）：
   `:279`（项目名称不能为空）、`:335`（任务标题不能为空）、`:518-522`（只接受 project / increment）、
   `:916`（日期必须是 YYYY-MM-DD 格式）—— 这 4 条在 UI 侧都不可达（stage-3 §2 已坐实可达性链），
   本轮**只改** `:400` / `:470` 两处真上屏的抛点。

---

## ③ 键数断言改动与实测

### 断言改动

| 文件 | 位置 | 改前 | 改后 |
|---|---|---|---|
| `apps\desktop\test\l10n_base_test.dart` | `:27`（用例标题「390 条 getter」） | 390 条 getter | **417 条 getter** |
| `apps\desktop\test\l10n_base_test.dart` | `:28`（`byGetter.length` 断言） | 390 | **417** |
| `apps\desktop\test\l10n_base_test.dart` | `:29`（`l10nAccessors.length` 断言） | 390 | **417** |
| `apps\desktop\test\l10n_base_test.dart` | `:111`（用例标题「（390 + 4 + 53 = 447）」） | 390 + 4 + 53 = 447 | **417 + 4 + 53 = 474** |
| `apps\desktop\test\l10n_base_test.dart` | `:117`（总键数断言） | 447 | **474** |
| `apps\desktop\test\l10n_harness.dart` | `:7` / `:27`（注释） | 390 | **417** |
| `apps\desktop\lib\src\l10n\l10n_keys.dart` | 文件头 / `byGetter` 文档注释 | 390 | **417** |

`l10n_base_test.dart:44-109` 的 **byMethod 53 条显式名单未动**（27 键都是无参 getter），
`byListGetter` 4 条未动，`sameValueWhitelist` 2 条未动。

### 实测（原始输出）

**验证命令**（在 `apps\desktop` 目录、进程内设镜像环境变量）：

```powershell
Set-Location 'F:\soft\00selfmade\practilog\apps\desktop'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test test\l10n_base_test.dart --reporter compact
```

`flutter analyze` 原始输出（最终态）：

```text
Analyzing desktop...
No issues found! (ran in 7.0s)
```

（`ANALYZE_EXIT=0`。）

`flutter test test\l10n_base_test.dart --reporter compact` 原始输出（最终态，节选首尾，逐字）：

```text
00:02 +0: loading F:/soft/00selfmade/practilog/apps/desktop/test/l10n_base_test.dart
00:02 +1: 键表结构 417 条 getter 全部登记在对照表里
00:02 +2: 键表结构 4 条列表型 getter 全部登记在列表表里
00:02 +3: 键表结构 53 条插值方法登记在方法表里
00:02 +4: 键表结构 全部键值不重复（417 + 4 + 53 = 474）
00:02 +5: 键表结构 键一律 kebab-case（小写字母数字，单横线分隔）
00:02 +6: 键表结构 键带模块前缀，前缀与 part 归属一致
00:02 +7: 域层文案 id 对齐 包层给出的 id 全部已建键，且中文逐字一致
00:02 +8: 域层文案 id 对齐 labelKeyFor 与 labelFor 一一对应（含未分级兜底）
00:02 +9: 中英双态 每条 getter 在中英两态都取得到非空文案
00:02 +10: 中英双态 除白名单外，中英两态必须不同（防复制粘贴当翻译）
00:02 +11: 中英双态 每条列表型 getter 中英两态都非空，条目数一致且逐条不同
00:02 +12: 中英双态 白名单恰好 2 条，且它们确实中英同值（防白名单过期）
00:02 +13: 语言分流 forLanguage：en 取英文，zh 与未知回落中文
00:02 +14: 语言分流 fromCode：只认 en，其余（含 null / 空串 / 大写）回落中文
00:02 +15: 语言分流 持久化码值就是 zh / en
00:02 +16: AppLocalizations.of(context) 没有 L10nScope 时抛 FlutterError，且错误信息给出修法
00:02 +17: AppLocalizations.of(context) 有 L10nScope 时取到对应语言的文案
00:02 +18: AppLocalizations.of(context) 切换语言后子树读到的是新语言（会触发重建）
00:02 +19: 插值方法 中文输出与拆分前的旧拼串逐字一致
00:02 +20: 插值方法 英文输出非空且与中文不同
00:02 +21: 插值方法 插值真的把参数带进输出（不是写死的常量）
00:02 +22: L10nFormat 中文用顿号、英文用逗号加空格拼接
00:02 +23: L10nFormat 空列表拼出来是空串（不是分隔符）
00:02 +23: All tests passed!
```

- **真实用例数 = 23**（`+23`），末行 `All tests passed!`，进程退出码 `0`。
- 本轮**只跑了这一个测试文件**（派工书只允许单跑 `test\l10n_base_test.dart`）；**未跑全量 `flutter test`**。
- 期间**未出现** `OS Error 183`，故**未**动 `apps\desktop\build\test_cache\build`。
- 首轮 `flutter analyze` 曾报 **3 个 error**（`outcome_composer.dart:235/247/259` 的 `displayLabel` 漏写类名前缀
  `OutcomeComposer.`），已修为 `OutcomeComposer.displayLabel(l10n, label)` 并按 dart format 折行；**复跑后为逐字 `No issues found!`**。

---

## ④ 显示映射渲染点覆盖清单

映射函数唯一入口：`OutcomeComposer.displayLabel(AppLocalizations t, String stored)`（`outcome_composer.dart:68-118`）。

### 本轮实际改造的渲染点（6 处，全部已落码）

| # | 渲染点 file:line（改完后） | 改前 | 改后 |
|---|---|---|---|
| 1 | `widgets\outcome_composer.dart:237` | `ChipOption(key: label, label: label)` | `ChipOption(key: label, label: OutcomeComposer.displayLabel(l10n, label))`（`key:` 保持落库值） |
| 2 | `widgets\outcome_composer.dart:252` | 同上 | 同上（原因组芯片） |
| 3 | `widgets\outcome_composer.dart:267` | 同上 | 同上（下一步组芯片） |
| 4 | `widgets\timeline\plan_item_detail_dialog.dart:300` | `ChipOption(key: label, label: label)`（直接渲染 `OutcomeComposer.outcomeLabels/reasonLabels/nextStepLabels`） | `ChipOption(key: label, label: OutcomeComposer.displayLabel(l10n, label))` |
| 5 | `pages\projects_page.dart:254` | `detail: increment.nextStep` | `detail: OutcomeComposer.displayLabel(t, increment.nextStep)` |
| 6 | `pages\projects_page.dart:1411`（`_lineText`，`:1403-1414`） | `return increment.nextStep;` | `return OutcomeComposer.displayLabel(t, increment.nextStep);` |

### stage-3 §3.4 其余渲染点的处置（逐条说明「为什么不动」）

| stage-3 列出的渲染点 | 本轮处置 | 理由 |
|---|---|---|
| `widgets\slot_fill.dart:61`（挂载 `OutcomeComposer`） | **不用改** | 只挂载、不含文案（stage-3 §3.1 原则 4） |
| `widgets\slot_fill.dart:84-88`（按 `'顺延到明天'` / `'取消'` 判定） | **不用改** | **落库值判定，红线** |
| `widgets\timeline\plan_item_detail_dialog.dart:240-276`（`_removeLabel` / `_applyChipTap`） | **不用改** | 按落库值判选中/回填，改了就会写坏数据 |
| `l10n\parts\dialog.dart` 20 条新键的**抽象声明与 mixin 实现** | 本身就是**显示层**（不是落库值） | 落库值在 `outcome_composer.dart`；dialog part 只提供「这个落库值显示成什么」 |
| `data\project_store.dart` 的 4 条不可达诊断串（`:279/:335/:518-522/:916`） | **不用改** | UI 侧不可达（stage-3 §2 判据）；改了反而扩大改动面 |
| `pages\projects_page.dart:117-125`（`_reload` 的 catch，用 `'$error'`） | **不用改** | 不是落库值，也不在 stage-3 的缺口清单里 |
| `widgets\habit_quick_dialog.dart:391/:496`、`widgets\shell\tool_rail.dart:304`、`l10n\parts\dialog.dart:894/:960`（`＋`）、`l10n\parts\settings.dart:239`（`简体中文`） | **不用改** | stage-3 §4.1 #29–#34 判为**人工口径**（Q3/Q4），明确「不改 / 不新增键」 |
| `packages\core_domain\lib\src\entities.dart:111`（`$field 必须是 YYYY-MM-DD 格式，实际 "$v"`） | **本轮未处理** | stage-3 §4.2 #35：**扫描面外**（`packages\**`），且该文件不在门禁白名单 ⇒ 人工验收点 **Q5**；且 `packages\**` 本轮禁改 |

### B 组 7 键的上屏点（7 处，全部已落码）

| 键 | 上屏点 file:line（改完后） | 落法 |
|---|---|---|
| `projectsInvalidDateFormat` | `projects_page.dart:326`（`_optionalDay` 内 `throw FormatException(t.projectsInvalidDateFormat)`） | 经 `_messageOf` 的 `FormatException` 分支上屏 |
| `projectsDateNotExist` | `projects_page.dart:333` | 同上 |
| `projectsNameRequired` | `projects_page.dart:537` | 表单内联 `_error` |
| `projectsTaskTitleRequired` | `projects_page.dart:1030` | 表单内联 `_error` |
| `projectsProgressRequired` | `projects_page.dart:1367` | 表单内联 `_error` |
| `projectsMilestoneMissing` | `projects_page.dart:303`（`_messageOf` 的 `MissingEntityException` 分支） | `{id}` 由 `replaceAll('{id}', error.id)` 插值 |
| `projectsProjectMissing` | 同上（`kind == project` 时取） | 同上 |

---

## ⑤ 类型化异常改动 + catch ↔ store 调用逐点核实

### 5.1 改动

`apps\desktop\lib\src\data\project_store.dart:42-60` 新增类型化异常：

```dart
class MissingEntityException implements Exception {
  const MissingEntityException({required this.kind, required this.id});
  final String kind;   // MissingEntityException.milestoneKind / .projectKind
  final String id;
  static const String milestoneKind = 'milestone';
  static const String projectKind = 'project';
  @override
  String toString() => 'MissingEntityException(kind: $kind, id: $id)';
}
```

- **不继承 `StateError`**：异常文案要上屏 ⇒ 必须能本地化 ⇒ 数据层只带「类别 + id」，UI 层查 l10n 表拼句。
- **`toString()` 刻意纯 ASCII**（无中文）：它会进日志、也可能被没有 l10n 上下文的地方直接打印。

两处抛点替换：

| 旧 | 新（改完后 file:line） |
|---|---|
| `project_store.dart:400` `throw StateError('任务 $milestoneId 不存在');` | `project_store.dart:430-433` `throw MissingEntityException(kind: MissingEntityException.milestoneKind, id: milestoneId);` |
| `project_store.dart:470` `throw StateError('项目 $projectId 不存在');` | `project_store.dart:503-506` `throw MissingEntityException(kind: MissingEntityException.projectKind, id: projectId);` |

### 5.2 catch ↔ store 调用逐点核实（磁盘为准）

| # | store 方法（抛点） | 抛出行 | UI 调用点 | catch 行 | `_messageOf` 行 | 落到的 getter |
|---|---|---|---|---|---|---|
| 1 | `ProjectStore.setMilestoneTargetDate` | `project_store.dart:430` | `projects_page.dart:206-211`（`_reschedule`） | `projects_page.dart:214` | `projects_page.dart:298-310` | `projectsMilestoneMissing`（`kind == 'milestone'`） |
| 2 | `ProjectStore.setProjectDomain` | `project_store.dart:503` | `projects_page.dart:164`（`_setProjectDomain`） | `projects_page.dart:171` | 同上 | `projectsProjectMissing`（`kind == 'project'`） |

**核实说明（与派工书措辞的差异，磁盘为准）**

- `project_store.dart` 中**不存在** `updateMilestone` / `updateProject` 方法；真实方法名是
  `setMilestoneTargetDate`（`:388`）与 `setProjectDomain`（`:462`）。
- 全仓 `grep` 确认这两个方法**只有 `projects_page.dart` 调用**（`:206` / `:164`），没有第二个调用方。
- `projects_page.dart` 的 `_messageOf` 定义在 `:298-310`，7 个调用点全部补了 `t`：
  `:152`（`_createProject`）、`:171`（`_setProjectDomain`）、`:195`（`_addTask`）、`:214`（`_reschedule`）、
  `:234`（`_scheduleProject`）、`:260`（`_scheduleIncrement`）、`:284`（`_appendIncrement`）——**与 stage-3 §3.5 第 8 项列的 7 个调用点逐点一致**。
- `t` 在各 async 方法的 **await 之前**捕获（`AppLocalizations.of(context)` 在已卸载 context 上会抛 FlutterError，见 `l10n_scope.dart:34-55`）。

### 5.3 已知会失败的既有断言（写集外，如实登记）

| 文件 | 断言 | 为什么会失败 | 处置 |
|---|---|---|---|
| `apps\desktop\test\task60_project_domain_edit_test.dart:253-267` | `expect(..., isA<StateError>().having((StateError e) => e.message, ..., allOf(contains('项目'), contains(id))))` | 异常已从 `StateError` 换成 `MissingEntityException` ⇒ `isA<StateError>()` 不再命中 | **需该文件属主更新**（不在本轮写集，未擅自改） |
| `apps\desktop\test\task60_project_domain_edit_test.dart:287-332` | 同上（T9） | 同上 | 同上 |
| `apps\desktop\test\task63_w7_l10n_test.dart:168` | en 态 `expect(find.text('按时完成'), findsOneWidget)`（用例名「en 态：落库短语与前缀不翻译（芯片仍是中文…）」） | 芯片 label 现在走映射 ⇒ en 态显示 `Completed on time`，断言的「芯片仍是中文」不再是事实 | **需该文件属主更新**（不在本轮写集）。同文件 `:168` 附近的数据完整性断言 `expect(captured, '[结论]按时完成')` 仍可通过（**落库值未改**） |

本轮**未运行全量 `flutter test`**，所以上表三条是**代码推演结论（未实测）**，不是实测失败记录。

---

## ⑥ 门禁 OUT_OF_SET 独立复算

> **声明：本轮未运行 `reports\task51-gate.ps1`**（派工书明令：禁跑 / 禁改门禁脚本）。
> 以下是**按门禁源码口径做的独立复算**，方法与 `reports\task51-gate.ps1` 完全一致：
> `:103` `git -c core.quotepath=false status --porcelain -uall` → `:119` 取每行第 4 字符起 → `:120` `\`→`/` →
> `:322-324` 用 `$patterns` 逐个 `-like` 匹配 → `:325` 全部未命中者计入 `OUT_OF_SET` → `:346` `OUT_OF_SET>0` 记为门禁 FAIL。

### 6.1 本轮改动的 9 个代码文件 —— 命中的白名单 pattern（逐个列出）

| # | 改动文件 | 命中的 `$patterns` 条目 | 门禁脚本行号 |
|---|---|---|---|
| 1 | `apps/desktop/lib/src/l10n/parts/dialog.dart` | `apps/desktop/lib/src/l10n/parts/dialog.dart` | `:243` |
| 2 | `apps/desktop/lib/src/l10n/parts/projects.dart` | `apps/desktop/lib/src/l10n/parts/projects.dart` | `:193` |
| 3 | `apps/desktop/lib/src/l10n/l10n_keys.dart` | `apps/desktop/lib/src/l10n/l10n_keys.dart` | `:194`、`:247` |
| 4 | `apps/desktop/test/l10n_base_test.dart` | `apps/desktop/test/l10n_base_test.dart` | `:206`、`:271` |
| 5 | `apps/desktop/test/l10n_harness.dart` | `apps/desktop/test/l10n_harness.dart` | `:207`、`:272` |
| 6 | `apps/desktop/lib/src/widgets/outcome_composer.dart` | `apps/desktop/lib/src/widgets/outcome_composer.dart` | `:269` |
| 7 | `apps/desktop/lib/src/widgets/timeline/plan_item_detail_dialog.dart` | `apps/desktop/lib/src/widgets/timeline/plan_item_detail_dialog.dart` | `:141`（另有 `apps/desktop/lib/src/widgets/timeline/*` `:252`） |
| 8 | `apps/desktop/lib/src/pages/projects_page.dart` | `apps/desktop/lib/src/pages/projects_page.dart` | `:188` |
| 9 | `apps/desktop/lib/src/data/project_store.dart` | `apps/desktop/lib/src/data/project_store.dart` | `:187` |

⇒ **9 个代码文件全部命中白名单 ⇒ 代码侧 `OUT_OF_SET` 增量 = 0**（stage-3 §3.5 预判成立）。
`packages\**` 命中数 = 0（`:320` `$pkgHits` 为空）—— 本轮**未碰任何 `packages\**` 文件**。

### 6.2 OUT_OF_SET 清单与计数（复算）

| 路径 | 是否命中白名单 | 说明 |
|---|---|---|
| `docs/AGENT-RELAY.md` | ❌ | `docs/` 下只有 `docs/B1_*.md`（`:212`）、`docs/superpowers/plans/*.md`（`:213`）、`docs/task40/*`（`:215`）、`docs/task62/*`（`:300`）、`docs/task63/*`（`:301`）命中；`docs/AGENT-RELAY.md` 不命中 |
| `docs/RELAY-ADAPTATION.md` | ❌ | 同上 |
| `docs/relay.json` | ❌ | 同上 |
| `docs/relay/stage-1-inventory.md` | ❌ | 同上 |
| `docs/relay/stage-2-scope.md` | ❌ | 同上 |
| `docs/relay/stage-3-report.md` | ❌ | 同上 |
| `docs/relay/supervision-2026-11-24.md` | ❌ | 同上（**非本轮产物**，是本轮期间由别的会话新增） |
| `docs/relay/stage-4-implementation.md` | ❌ | **本轮新增的交付文档**；`docs/relay/*` 整目录都不在白名单里 |

**计数（`-uall` 口径）**

| 口径 | 开工基线 | 收尾 | 差 |
|---|---|---|---|
| `git status --porcelain -uall` 总行数 | 7 | **18** | +11 |
| 其中：代码文件（`apps/**`） | 0 | **9** | +9 |
| 其中：非代码（`AGENTS.md` + `docs/**`） | 7 | **9** | +2 |
| **OUT_OF_SET 计数** | **7** | **8** | **+1** |

- **+1 来自本轮新增的交付文档 `docs\relay\stage-4-implementation.md`**（`docs/relay/*` 不在门禁白名单内 ⇒ 必然 OUT_OF_SET）。
  这**不是**代码越界：9 个代码文件命中白名单，代码侧增量为 0。
- **另外 1 个增量（`docs/relay/supervision-2026-11-24.md`）不是本轮产物** —— 它在本轮执行期间由另一个会话落盘，
  本轮**没有**创建或修改它；为免污染计数，本轮也**没有**去改白名单（禁改门禁脚本）。
- 结论：**门禁 `OUT_OF_SET` 判据在本轮不是「代码越界」，而是「接力台账文档不在白名单」**（stage-3 Q8 同一现象）。

---

## ⑦ git status 计数变化 + 实际改动文件清单 + SHA256 指纹

### 7.1 计数变化

| 口径 | 开工基线 | 收尾 | 差 |
|---|---|---|---|
| `git status --porcelain -uall` | 7 行（1 个 ` M AGENTS.md` + 6 个 `?? docs/...`） | **18 行** | +11 |
| `git status --porcelain`（未跟踪目录折叠口径） | 5 行 | **14 行** | +9 |
| `HEAD` | `85b809a` | `85b809a` | 未变（**未 commit / 未 push / 未 tag**） |

### 7.2 实际改动文件清单（9 个代码文件 + 1 份交付文档）

| # | 文件 | 字节 | SHA256 前 16 位 | 本轮改动 |
|---|---|---|---|---|
| 1 | `apps\desktop\lib\src\l10n\parts\dialog.dart` | 41622 B | `BF8BFB4EF46B39DE` | 20 个 getter 声明 + zh/en 实现 |
| 2 | `apps\desktop\lib\src\l10n\parts\projects.dart` | 12410 B | `32514FAEF5C6161D` | 7 个 getter 声明 + zh/en 实现 |
| 3 | `apps\desktop\lib\src\l10n\l10n_keys.dart` | 83271 B | `DBA879C4EBC86415` | 27 个 kebab 常量 + `byGetter` 27 行 + 注释 390→417 |
| 4 | `apps\desktop\test\l10n_base_test.dart` | 28982 B | `3D3B7B6DC3F3EC4B` | 断言 390→417、447→474 |
| 5 | `apps\desktop\test\l10n_harness.dart` | 38685 B | `BC1419C182560355` | 27 个访问器 + 注释 390→417 |
| 6 | `apps\desktop\lib\src\widgets\outcome_composer.dart` | 10153 B | `3E808CEECF30D9FE` | `displayLabel` + 3 处芯片 label |
| 7 | `apps\desktop\lib\src\widgets\timeline\plan_item_detail_dialog.dart` | 23406 B | `72FA4F974000D518` | 芯片 label 走映射 |
| 8 | `apps\desktop\lib\src\pages\projects_page.dart` | 52453 B | `549D19E2CE0D7E3A` | `_messageOf` / `_optionalDay` / 7 个调用点 / 3 处表单文案 / 2 处显示映射 |
| 9 | `apps\desktop\lib\src\data\project_store.dart` | 33639 B | `9ABE1D8371798BC5` | `MissingEntityException` + 2 处抛点 |
| 10 | `docs\relay\stage-4-implementation.md` | 见 §⑦ 尾注 | 见 §⑦ 尾注 | 本交付文档（新建） |

**尾注**：本文件**无法包含自身的 SHA256**（写入即改哈希）。本文件的字节数与 SHA256 前 16 位在
stage-4 汇报（final_text）中给出。

**编码 / 行尾实测**（9 个代码文件）：全部 **UTF-8 无 BOM**、**LF 行尾**（`crlf=0`）。
派工书写的是「保持 CRLF」，但**磁盘现状本来就是 LF** —— 按「保留既有行尾、不制造整文件 diff」的原则，
本轮**沿用 LF**，未做整文件行尾转换（见 §⑧ D1）。

---

## ⑧ 与 stage-3 结论的差异登记

| # | 差异 | stage-3 / 派工书口径 | 本轮实际 | 依据 |
|---|---|---|---|---|
| **D1** | **行尾** | 派工书要求「保持 CRLF」 | 磁盘 9 个文件实测**全是 LF 无 BOM**（`crlf=0`）⇒ 沿用 LF，未做整文件转换 | 实测（`Get-FileHash` 同批脚本统计 `crlf` / `lf` 计数） |
| **D2** | **「取消」的 getter 名** | 派工书表述为「`t.commonCancel`」 | 实际 getter 名是 **`t.cancel`**（`parts\common.dart:12` 声明 / `:82` zh / `:145` en）；`L10nKeys.commonCancel = 'common-cancel'` 只是**键常量**（`l10n_keys.dart:325`），**没有** `t.commonCancel` getter ⇒ 本轮 `displayLabel` 的 `'取消'` 分支返回 `t.cancel`，**未新增键** | 实测读盘 + 全仓 grep |
| **D3** | **异常类型** | stage-3 §3.2 备选方案：保留 `StateError` + UI 侧正则解析 id（不推荐） | 采用**类型化异常** `MissingEntityException`（`kind` + `id`），**不继承 `StateError`**、`toString()` 纯 ASCII | stage-3 §3.2 B6/B7 落点说明 |
| **D4** | **`t` 的获取时机** | stage-3 只说「`_optionalDay` 需要能拿到 `t`」 | 额外在**每个 async 方法的 await 之前**捕获 `t`（`AppLocalizations.of(context)` 在已卸载 context 上会抛 FlutterError，见 `l10n_scope.dart:34-55`） | 读盘 + `l10n_scope.dart` |
| **D5** | **既有测试会被打破** | stage-3 未点名 | **3 处既有断言会失败**：`task60_project_domain_edit_test.dart:253-267` / `:287-332`（`isA<StateError>()`）、`task63_w7_l10n_test.dart:168`（en 态断言芯片仍是中文）。这 3 个文件**不在本轮写集** ⇒ 未擅自改写，按权威设计实现并如实登记 | 见 §⑤ 5.3 |
| **D6** | **`projects_page.dart:254` 的映射是「近乎 no-op」** | stage-3 §3.4 列「`projects_page.dart:244` 显示时映射」 | 实测：`increment.nextStep` 是**自由文本**（用户在增量表单里写的），只有恰好等于 6 条规范短语之一时才会被翻译 ⇒ 对真实数据基本原样返回。**副作用**：用户在中文界面写了「明天继续」，切到英文后该行会显示 `Continue tomorrow`（语言耦合）。按 stage-3 设计照做，副作用登记在此 | 读盘 `IncrementRow.nextStep` 语义 + `displayLabel` 默认分支 |
| **D7** | **门禁 `OUT_OF_SET` +1** | stage-3 §3.5 预判「本方案不增加 `OUT_OF_SET`」 | 对**代码文件**成立（+0）；但本轮**新增交付文档** `docs\relay\stage-4-implementation.md`，而 `docs/relay/*` 不在白名单 ⇒ `OUT_OF_SET` 由 7 → **8**。另外 `docs/relay/supervision-2026-11-24.md` 是**别的会话**在本轮期间新增的，不属本轮产物 | 见 §⑥ |
| **D8** | **stage-3 §3.5 第 7 项的文件路径写错** | 写作 `apps\desktop\lib\src\widgets\plan_item_detail_dialog.dart` | 实际路径是 `apps\desktop\lib\src\widgets\**timeline**\plan_item_detail_dialog.dart`（在 `timeline/` 子目录下） | 实测读盘；两者都在白名单（`:141` / `:252`），不影响 `OUT_OF_SET` 结论 |
| **D9** | **stage-3 §3.5 第 9 项说「`:916` / `:279` / `:335` / `:518` 四条不可达诊断串保持不变」** | 同 | 一致：4 条**一字未改**；只改 `:400` / `:470` 两处真上屏抛点 | 读盘核对 |
| **D10** | **首轮 analyze 未过** | —— | 首轮 `flutter analyze` 报 3 个 error（`outcome_composer.dart:235/247/259` 漏 `OutcomeComposer.` 类名前缀）⇒ 已修并复跑为逐字 `No issues found!` | 见 §③ |
| **D11** | **`app_localizations.dart` 未改** | stage-3 §3.5 第 10 项「不改」 | 一致：**未改**（27 键全为无参 getter，聚合结构无需变） | 读盘 |
| **D12** | **未建 `l10n\parts\outcome.dart`** | stage-3 §3.1 原则 4 | 一致：20 条 A 组键放进**既有** `parts\dialog.dart` ⇒ 门禁 `OUT_OF_SET` 代码侧 +0 | 读盘 |

---

## 附：本轮**没有**做的事（如实声明）

- **没跑** `reports\task51-gate.ps1`（派工书禁止跑/改门禁脚本）—— §⑥ 是独立复算，不是门禁运行结果。
- **没跑**全量 `flutter test`（派工书只允许单跑 `test\l10n_base_test.dart`）⇒ §⑤ 5.3 的 3 条既有断言失败是**推演结论，未实测**。
- **没改**写集外任何文件：未动 `AGENTS.md`、`handoff.md`、`docs\P1_进度.md`、`docs\B1_验收记录.md`、
  `docs\开发计划.md`、`docs\relay.json`、`docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`、
  `reports\task51-gate.ps1`、`apps\desktop\lib\src\l10n\app_localizations.dart`、
  `widgets\shell\tool_rail.dart`、`widgets\slot_fill.dart`、`packages\**`。
- **没做** git commit / push / tag（`HEAD` 仍是 `85b809a`）。
- **没做**打包 / 分发；**没改**用户级配置。
- **没做**真机界面验收（本轮是代码落码 + 门禁口径复算，不含界面走查）。
