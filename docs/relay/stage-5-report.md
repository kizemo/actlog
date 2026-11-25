# Stage 5 报告 · 修 3 条被 stage 4 打破的既有断言 + 人工口径待决清单收口

- 会话：`mvs_dd5bbcf80ab040c5a017d664411a84eb`（接力链第 5 环；`max_stages=6`，本环为倒数第二环）
- 模型：`custom_provider:provider-aa5659/deepseek-v4.1-flash-1017`
  （M3 报 2056 额度上限后按 `docs/RELAY-ADAPTATION.md` §9.2 降级；降级事件已记在 `docs/relay.json` 的 `sessions[4].note`）
- 起始 `HEAD`：`85b809a`
- 收尾判定：**`status = blocked`** —— 剩余项全部是人工验收点，**本环不建 stage 6**

---

## ① 本环做与不做（写集自证）

### 实际写入的文件（4 个，与派工写集逐条对应）

| # | 文件 | 动作 | 改前 | 改后 |
|---|---|---|---|---|
| 1 | `apps\desktop\test\task60_project_domain_edit_test.dart` | 2 个用例名 + 2 个断言块（worker）+ 3 行文件头注释（根会话） | `2EAF94E096886FC2` / 22,715 B | `48359BDCA6E120F1` / 23,005 B |
| 2 | `apps\desktop\test\task63_w7_l10n_test.dart` | 用例名 + 2 行注释 + 芯片断言改英文 + 新增阴性对照 | `4BE47BC456FB814E` / 12,979 B | `861B96F4F7C56170` / 13,285 B |
| 3 | `docs\relay\stage-5-report.md` | 新建（本文件） | 不存在 | 见 `git status` |
| 4 | `docs\relay.json` | 只追加回写 `stages[4]` 与本环 `sessions` 条目；顶层 `status` / `next_session_id` 收口 | `status=running` | `status=blocked` |

两个测试文件的正文改动由 `worker` 子会话 `bg_713c7ccb-441b-4217-a3b7-f35b1e9f4e16`
（session `mvs_3eed766be6724ee4903985b3ff7c513f`）按派工书写入。
文件头注释的订正由根会话在 worker 交付后补做（同一写集内的同文件，未越界）。

编码/行尾自检（改后，实测）：

| 文件 | BOM | CR | LF | 严格 UTF-8 |
|---|---|---|---|---|
| `task60_project_domain_edit_test.dart` | False | 0 | 578 | ok |
| `task63_w7_l10n_test.dart` | False | 0 | 316 | ok |

⇒ 与改前一致：**UTF-8 无 BOM + 纯 LF**。

### 明确没有碰的（本环禁区，全部保持磁盘原状）

- stage 4 已落码的 **9 个实现文件**（`l10n\parts\dialog.dart`、`l10n\parts\projects.dart`、
  `l10n\l10n_keys.dart`、`test\l10n_base_test.dart`、`test\l10n_harness.dart`、
  `widgets\outcome_composer.dart`、`widgets\timeline\plan_item_detail_dialog.dart`、
  `pages\projects_page.dart`、`data\project_store.dart`）—— 开工时逐条核过 SHA16/字节，
  与 `stages[3].note` 登记值逐字一致，收尾仍是同一组值。
- 人工口径 Q3/Q5/U5 涉及的 4 个文件：`widgets\shell\tool_rail.dart`、`widgets\slot_fill.dart`、
  `packages\core_domain\lib\src\entities.dart`、`packages\core_data\lib\src\repositories.dart`。
- `AGENTS.md`、`handoff.md`、`docs\P1_进度.md`、`docs\B1_验收记录.md`、`docs\开发计划.md`、计划 §68。
- `reports\task51-gate.ps1` —— **既没运行也没修改**（只读分析了它的白名单数组，见 ⑤）。
- 未执行任何 `git add` / `commit` / `push` / `tag` / `stash` / `checkout`。
- 未跑不带文件参数的全量 `flutter test`（避免与并发门禁抢 `build\test_cache\build` 与 `sqlite3.dll`）。

---

## ② 改前失败取证

### 开工时的磁盘真相（不采信任何转述）

| 项 | 实测值 |
|---|---|
| `git rev-parse --short HEAD` | `85b809a` |
| `git status --porcelain -uall` 行数 | **18**（10 `M` + 8 `??`） |
| `docs\relay.json` | 40,401 B / mtime `2026-11-24 22:47:53` |
| 其中 `status` | `running` |
| 其中 `current_stage` / `max_stages` | `5` / `6` |
| 其中 `stages[4].status` / `finished_at` | `pending` / `null` |
| `docs\relay\stage-5-report.md` | **不存在** |

⇒ 本环工作在开工时刻**确未开始**。（上一份压缩摘要开头「已推进到 stage 6、无待办」是误记，不予采信。）

### 改前三段实测（后台 `bg_cbf24d9a`，终态 failed 属预期 —— 失败用例把退出码带出来了）

| 命令 | 改前结果 | 判读 |
|---|---|---|
| `flutter analyze` | `Analyzing desktop...` + `No issues found! (ran in 7.3s)` | ✅ 静态面本来就干净 |
| `test\l10n_base_test.dart` | `+23: All tests passed!` | ✅ 未被 stage 4 打破 |
| `test\task60_project_domain_edit_test.dart` | **`+7 -2`** | ❌ 2 红 |
| `test\task63_w7_l10n_test.dart` | **`+8 -1`** | ❌ 1 红 |

三条红的具体原文：

- **task60 T8**（`:253`）：`which is not an instance of 'StateError'`
- **task60 T9**（`:322`）：`which is not an instance of 'StateError'`
  （用例名 `T9（60.4c）：已软删的项目行 ⇒ 同样抛 StateError，墓碑行原样不动`）
- **task63**：`This was caught by the test expectation on the following line:
  file:///F:/soft/00selfmade/practilog/apps/desktop/test/task63_w7_l10n_test.dart line 168`，
  用例 `结果撰写（OutcomeComposer）` / `en 态：落库短语与前缀不翻译（芯片仍是中文，编码仍是 [结论]）`

### 根因（两条，各自坐实）

**(a) 异常类型被 stage 4 换代，测试还在断言旧类型。**
`apps\desktop\lib\src\data\project_store.dart:42-60` 定义了
`MissingEntityException({required String kind, required String id})`，带
`milestoneKind = 'milestone'` / `projectKind = 'project'` 两个常量；
`setProjectDomain`（`:495`）的两条守卫都在 `:503-506` 抛
`MissingEntityException(kind: projectKind, id: projectId)`。
测试仍断言 `isA<StateError>()` ⇒ 类型不匹配，必然红。

**(b) stage 4 给芯片加了「纯显示层映射」，测试还按「芯片必须是中文」断言。**
`apps\desktop\lib\src\widgets\outcome_composer.dart:68-115` 的
`static String displayLabel(AppLocalizations t, String stored)` 对 21 条落库短语逐条映射，
`:70-71` 是 `case '按时完成': return t.dialogOutcomeOnTime;`；en 侧
`apps\desktop\lib\src\l10n\parts\dialog.dart:1092` 的 `dialogOutcomeOnTime` 值是
`'Completed on time'`。芯片 `label:` 取 `displayLabel(...)`（`:237/:252/:267`，`key:` 仍是落库原值）
⇒ en 态下 `find.text('按时完成') findsOneWidget` 必然失败。
落库值本身**没变**（`:27-57` 的三个 `const List<String>` 只读不改）。

---

## ③ 人工口径待决清单（Q1–Q8 / U5 / D6，供人拍板）

> 本环**一条都没有自行决定**。下表只登记「问题 / 证据 / 可选项与判据」。

| # | 问题 | 证据（file:line） | 可选项与判据 |
|---|---|---|---|
| **Q1** | 450 条格言数据集是否要更换 | `apps\desktop\lib\src\data\quote.dart:7-14`（`Quote({en, zh})` 双字段）、`widgets\quote_banner.dart:100`（按 `isZh` 分叉） | stage 2 已推翻「450 条属 l10n 缺口」这一前提：它是**双语双字段**，不是待译缺口。若仍要换，需给新数据集来源与替换判据；若不换，登记关闭 |
| **Q2** | 这 450 条的英文译文是否需要人工审 | 同上 | 审 = 需人工产出或外部译文源；不审 = 现状即定稿。两者都无代码门槛，纯内容决策 |
| **Q3** | 全角 `＋` 3 处是否改为 l10n 键 | `l10n\parts\dialog.dart:894`、`:960`、`widgets\shell\tool_rail.dart:304`；`widgets\slot_fill.dart` | 改 ⇒ 必须同步改 `apps\desktop\test\task63_w7_l10n_test.dart:189`（`expect(zh.dialogPoolNew, '＋ 新建待办')` 逐字锁死全角 ＋），且 `tool_rail.dart`/`slot_fill.dart` 需加门禁白名单。不改 ⇒ 全角 ＋ 作为 zh 视觉规范保留 |
| **Q4** | `settings.dart:239` 的「简体中文」自称在 en 态是否保留中文 | `l10n\parts\settings.dart:239` | 保留 ⇒ 语言名按母语自称（业界常见，en 界面里显示「简体中文」）。改 ⇒ 会与语言选择器的可辨识性冲突（en 用户看不到中文名反而认不出） |
| **Q5** | `DomainValidationException` 的消息是否 l10n 化 | `packages\core_domain\lib\src\entities.dart:111`（`'$field 必须是 YYYY-MM-DD 格式，实际 "$v"'`） | 这条消息**会上屏**，且在 l10n 扫描面之外、属 `packages\**`。l10n 化 ⇒ 违反「core 包不依赖 UI l10n」的层次，需改设计（抛 code 由 UI 映射）；不化 ⇒ 承认 en 态会出现中文异常文案 |
| **Q6** | `StateError` 是否改用备选方案（UI 侧正则解析 id） | `data\project_store.dart:42-60` 与 `pages\projects_page.dart:298-310` 的 `_messageOf`（已有 `MissingEntityException` 分支） | stage 4 已选**类型化异常**并落码、本环已把测试对齐到该选择。备选方案（正则解析 `StateError.message`）强度更低且脆。**默认建议：确认类型化异常定案**，Q6 关闭 |
| **Q7** | `dialog.dart:254-259` 的「21 条永不在本文件出现」注释是否已正确改写 | `l10n\parts\dialog.dart:254-259` | stage 4 已同步改成「显示层键」口径。请确认该注释与 `outcome_composer.dart:68-115` 的新事实一致 ⇒ 一致即关闭 |
| **Q8** | `docs/relay/*`、`docs/AGENT-RELAY.md`、`docs/RELAY-ADAPTATION.md`、`reports/stage4-closeout.js` 是否登记为门禁白名单长期固定项 | 见 ⑤ 的复算结果 | **这是唯一能让门禁转绿的开关**。改白名单本身是人工验收点。判据：这些是中继框架自身的状态台账，不是产品代码，且会随每一环增长 ⇒ 建议成组登记 `docs/relay/*` + 三份中继文档，而不是逐环追加单个文件名 |
| **U5** | 是否把 `packages\core_data\lib\src\repositories.dart:47-50` 纳入缺口面（全域缺口 35 → 36） | 同左 | 纳入 ⇒ 缺口账要从 35 改成 36 并进计划；不纳入 ⇒ 需写明排除理由（例如该消息不进 UI） |
| **D6** | 自由文本语言耦合副作用是否接受为设计取舍 | `pages\projects_page.dart:254` 对 `increment.nextStep` 的映射近 no-op（仅当用户文本恰等于 6 条规范短语之一才翻译） | 接受 ⇒ 登记为已知取舍、不修；不接受 ⇒ 需改数据结构（存 code 而非自然语言），属架构级改动 |

---

## ④ 修复后实测（根会话独立重跑，非转述 worker 结论）

| # | 命令 | 结果 | 退出码 | 判据 |
|---|---|---|---|---|
| 1 | `flutter analyze` | `Analyzing desktop...` + **`No issues found! (ran in 7.5s)`** | 0 | 逐字命中 ✅ |
| 2 | `flutter test test\task60_project_domain_edit_test.dart --reporter compact` | **`+9: All tests passed!`** | 0 | 由 `+7 -2` → `+9`；through 数与改前总数（7+2 条用例）一致，未删用例 ✅ |
| 3 | `flutter test test\task63_w7_l10n_test.dart --reporter compact` | **`+9: All tests passed!`** | 0 | 由 `+8 -1` → `+9` ✅ |
| 4 | `flutter test test\l10n_base_test.dart --reporter compact` | **`+23: All tests passed!`** | 0 | 与改前基线 `+23` 逐字一致（未改坏） ✅ |

均带文件参数串行运行，未触发 `OS Error 183`。

### 改后的 3 条断言（逐字）

`apps\desktop\test\task60_project_domain_edit_test.dart`

- `:253` 用例名 → `T8（60.4c）：不存在的项目 id ⇒ 抛 MissingEntityException，且不落任何写入`
- `:259-267` → `isA<MissingEntityException>().having((MissingEntityException e) => e.kind, 'kind', MissingEntityException.projectKind).having((MissingEntityException e) => e.id, 'id', missingId)`
- `:289` 用例名 → `T9（60.4c）：已软删的项目行 ⇒ 同样抛 MissingEntityException，墓碑行原样不动`
- `:326-334` → 同形状，`id` 换成 T9 的局部变量 `id`

强度未降：原断言用 `allOf(contains('项目'), contains(missingId))` 表达「错误必须指向哪个实体」，
改后用 `kind == projectKind` + `id == missingId` 表达同一意图，且**比字符串包含更强**（不再依赖文案措辞）。
「不落写入」的四条断言（`:271-286` 的 `rows isEmpty` / `oplogCount == 0`，
`:338-346` 的 `after.domain` / `rev` 未抬 / `deletedAt` 未清）逐行原样未动。

`apps\desktop\test\task63_w7_l10n_test.dart`

- `:155` 用例名 → `en 态：落库值不翻译、只映射显示层（芯片出英文，编码仍是 [结论]）`
- `:169` → `expect(find.text('Completed on time'), findsOneWidget);`
- `:170-174` → 新增阴性对照 `expect(find.text('按时完成'), findsNothing, reason: '阴性对照：显示层必须真的翻译过，别在 en 界面漏出落库中文')`
- `:177-178` → **原样保留** `expect(captured, '[结论]按时完成')` 与 `expect(markedDone, isTrue)`
  ⇒ 「落库值零改动」的证明仍在，本环没有拿掉这条护栏来换绿。

---

## ⑤ 门禁 OUT_OF_SET 的结构性冲突（复算，未运行 `task51-gate.ps1`）

`reports\task51-gate.ps1` 禁止运行也禁止修改，故按其**代码本身的算法**复算：

- 白名单：`:129`–`:310` 的 `$patterns = @(...)`，正则提取得 **167 条**模式
- 归一化：`:119` 取 `git status --porcelain -uall` 每行的第 4 字符起，`:120` 把 `\` 换成 `/`
- 匹配：`:322` 对每条模式 `-like`，未命中即计 `OUT_OF_SET`（`:325`），`>0` 记 FAIL（`:346`）

### 复算结果（含本环两个测试文件）

```
TOTAL_STATUS_LINES=20   IN_SET=12   OUT_OF_SET=8
```

`OUT_OF_SET` 的 8 条，**全部是中继框架自己的 docs 台账**：

```
docs/AGENT-RELAY.md
docs/RELAY-ADAPTATION.md
docs/relay.json
docs/relay/stage-1-inventory.md
docs/relay/stage-2-scope.md
docs/relay/stage-3-report.md
docs/relay/stage-4-implementation.md
docs/relay/supervision-2026-11-24.md
```

### 三条必须记下的更正

1. **本环改的两个测试文件本来就在白名单里**，由
   `apps/desktop/test/task60_*.dart` 与 `apps/desktop/test/task63_*.dart` 两条通配覆盖
   ⇒ **本环的代码改动一条都没有增加 `OUT_OF_SET`**。
   （开工时的怀疑「改测试文件会撑破白名单」是错的；按文件名全文 grep 会漏掉通配模式，必须按 `-like` 语义匹配。）
2. 这 8 条 `OUT_OF_SET` 从 **stage 1** 起就存在，与 stage 5 无关 —— 每一环都会新增
   `docs/relay/stage-N-*.md`，而 docs 白名单只有 `docs/B1_*.md`、`docs/superpowers/plans/*.md`、
   `docs/task40/*`、`docs/task62/*`、`docs/task63/*` 五条。
3. 本文件落盘后再复算会变成 **`OUT_OF_SET=9`**（新增 `docs/relay/stage-5-report.md`）。
   即：**只要中继框架继续用自己的 docs 目录记状态，门禁就不可能全绿**。

### 结论

「门禁全绿」在本环**不可达**，原因不在代码，而在 ④ 那 8–9 条 docs 台账不在白名单。
改白名单属人工验收点 ⇒ 归入 Q8，本环**不动**。

---

## ⑥ `git status` 计数变化与改动指纹

| 时点 | 行数 | 构成 |
|---|---|---|
| 开工 | **18** | 10 `M` + 8 `??` |
| 收尾（本文件落盘前） | **20** | 12 `M` + 8 `??` |
| 收尾（本文件落盘后） | **21** | 12 `M` + 9 `??` |

增量 2 全部是**已跟踪文件**（两个测试文件由 `M` 前的干净态变成 `M`），
没有新增 `??`，也没有删除任何文件。

12 个 `M` 的去向：

- stage 1–4 的既有改动（本环未碰）：`AGENTS.md` + `lib\` 下 7 个 + `test\l10n_base_test.dart` + `test\l10n_harness.dart`
- **本环新增的 2 个**：`test\task60_project_domain_edit_test.dart`、`test\task63_w7_l10n_test.dart`

---

## ⑦ 收尾判定：`blocked`，以及需要谁拍什么板

依据 `docs\RELAY-ADAPTATION.md`：

- §4「人工验收点 = 一律 blocked 停链：把 `docs\relay.json` 写成 `status=blocked`，
  在 `stages` 里留下『卡在什么、需要人拍板什么、判据在哪』，然后停止建下一环会话」
- §7「第 6 环结束仍未闭环 ⇒ blocked」

本环的**可自主执行动作已全部做完**（3 条断言全绿、analyze 逐字干净、基线未破）。
剩余项 100% 是 ③ 表里的内容决策与白名单授权 —— 没有一条能在不询问用户的前提下继续动手。
因此：`status = blocked`，`next_session_id = null`，**不起 stage 6**（起了也只能空转，白烧额度）。

### 需要人拍板的三组事

1. **Q8（唯一的门禁开关）**：是否把 `docs/relay/*` + `docs/AGENT-RELAY.md` + `docs/RELAY-ADAPTATION.md`
   （可能还有 `reports/stage4-closeout.js`）成组登记进门禁白名单。不授权 ⇒ 门禁将长期红在 `OUT_OF_SET=9`。
2. **Q6/Q7（定案确认）**：类型化异常 `MissingEntityException` 是否作为最终方案；
   `dialog.dart:254-259` 的注释改写是否通过。
3. **内容决策**：Q1/Q2（450 条格言）、Q3（全角 ＋）、Q4（语言自称）、Q5（core 异常消息）、
   U5（缺口 35 → 36）、D6（自由文本语言耦合）。

### 判据在哪

- 代码判据：④ 的表格（可原样重跑；命令形状见下）
- 门禁判据：⑤ 的复算（167 条模式 + 3 步归一化，可复现）
- 本环未验证项：`reports\task51-gate.ps1` 的真实执行结果（禁止运行，只能用复算逼近）

```powershell
Set-Location 'F:\soft\00selfmade\practilog\apps\desktop'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test test\task60_project_domain_edit_test.dart --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' test test\task63_w7_l10n_test.dart --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' test test\l10n_base_test.dart --reporter compact
```

---

## ⑧ 与 stage 4 结论的差异登记 + 本轮没有做的事

### 差异

| 项 | 差异 |
|---|---|
| 交接转述 vs 磁盘 | 上一份压缩摘要称「已推进到 stage 6、无待办」；磁盘实为 `current_stage=5` / `stages[4]=pending` / `stage-5-report.md` 不存在 ⇒ 本环从零开工，未重做已完成的事 |
| 「改测试文件会撑破白名单」 | **错**。两条通配模式已覆盖，`OUT_OF_SET` 与代码改动无关（见 ⑤ 更正 1） |
| stage 4 的失败面 | 确认就是 3 条（task60 两条 + task63 一条），无第四处；`l10n_base_test.dart` 的 `+23` 未被打破 |
| stage 4 遗留的注释失真 | worker 主动披露：`task60…dart:23-25` 文件头仍写「T9 ⇒ 抛 `StateError`」且引用旧行号 `project_store.dart:469-471`（实际抛点 `:503-506`）。**根会话已订正**，非新增写集 |

### 本轮没有做的事（如实登记）

- 没有运行 `reports\task51-gate.ps1`（禁令），因此**「门禁真实全绿」始终是未验证状态**，只有复算。
- 没有跑全量 `flutter test`（禁令 + `build\test_cache\build` 争用），**只验证了 3 个文件共 `+9/+9/+23`**，
  其余用例未在本环重跑。
- 没有修 Q1–Q5 / U5 / D6 的任何一条（全是人工决策）。
- 没有动 `tool_rail.dart` / `slot_fill.dart` / `entities.dart` / `repositories.dart`（写集外，且需白名单）。
- 没有执行任何 git 写操作（`add` / `commit` / `push` / `tag`），全部改动留在工作区。
- 没有起 stage 6（`blocked` 停链）。

---

## 九、Q8 授权后的落地与新增待决（2026-11-24T23:01:24+08:00 回写）

**用户授权**：原话「授权，成组登记」。

**改动**：`reports\task51-gate.ps1` 的 `$patterns` 内、`'docs/task63/*',` 之后新增 **4 条纯 ASCII 模式**：
`'docs/relay/*'`、`'docs/relay.json'`、`'docs/AGENT-RELAY.md'`、`'docs/RELAY-ADAPTATION.md'`。
判定段 `:317-326` 逐字未动 —— 本次只登记范围，不改判据。

**为什么必须 4 条**：`-like 'docs/relay/*'` 匹配不到同级的 `docs/relay.json`；「成组登记」指的是
「按目录通配一次登记」，不是「一条模式覆盖全部」。

**实测校验（写入后回读）**：

| 项 | 值 |
|---|---|
| 字节 | 18,797 |
| BOM | False |
| 非 ASCII 字节 | 0 |
| 行尾 | CR=420 / LF=420（纯 CRLF，无混行） |
| 白名单模式数 | 167 → **171** |

**复算结果（按脚本自身算法，非运行本体）**：`IN_SET=21 / OUT_OF_SET=0`，`OOS:` 空列表。
此前 9 条全部是中继 docs 台账；本环两个测试文件的改动本来就落在 `task60_*` / `task63_*` 通配内，
故代码侧零新增。

> 口径声明：这是**复算**，不是门禁本体输出。脚本还包含 4 个包的 analyze + 全量 test 与计数硬判，
> 本环按 stage scope 禁令未运行本体。

**新增待决 Q9（已登记进 `docs\relay.json` 的 `stages[4].blocked_on`）**：
`reports\task51-gate.ps1:38` 的 `$baseline = 596`，而 stage 1 记载的并发门禁原始输出
`desktop.test = 836`（`core_data 204` / `core_db 71` / `core_domain 62` 与脚本 `:330-332` 一致）
⇒ 直接跑本体在 `desktop.test:COUNT` 判 FAIL（**已实测，见 §十**）。解法二选一：
① `-ExpectDesktopTests` 显式传入当轮真实用例数（不改脚本）；② 改 `:38` 硬判基线（= 改门禁判据，
人工验收点）。**Q8 解决后 `OUT_OF_SET` 已归零，但这条未解决前「门禁全绿」仍不可声明。**

**台账回写**：`docs\relay.json` 45,408 → **46,733 B**；`status=blocked` 不变、`current_stage=5` 不变、
`next_session_id=null` 不变；`blocked_on` = Q3,Q4,Q5,U5,Q1,Q2,Q6,Q7,**Q9**（Q8 已摘除，落地记录见
`stages[4].q8_resolution`）；顶层 21 key 与 `concurrency` / `next_stage_target` / `model_policy` /
`human_checkpoints` / `stop_conditions` 全部存活；BOM=False / CR=0。

---

## 十、门禁本体实跑（用户授权「直接跑，读真实计数」）

**授权原话**：2026-11-24「直接跑，读真实计数」。该指令覆盖 stage scope 里「禁止运行门禁本体」的禁令。
运行口径 = **不带 `-ExpectDesktopTests`、不改 `:38` 的 `$baseline`**，接受 `desktop.test:COUNT` 判红，
目的只有一个：取真实用例数。

**命令**：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File 'F:\soft\00selfmade\practilog\reports\task51-gate.ps1'
```

**时间线**：23:03:26 起（脚本自身先搬 stale cache），23:05:43 写出 summary，约 2 分 17 秒。
被搬走目录 = `apps\desktop\build\test_cache\build_moved_20261124-230326`
（回读 `TODAY_MOVED_EXISTS=True`，是移动不是删除）。

**本体输出（非复算）**：

| 项 | 值 |
|---|---|
| `GATE_VERDICT` | **FAIL** |
| `GATE_FAILURES` | **1** |
| `FAIL_ITEM` | `desktop.test:COUNT=836 EXPECT=596` |
| `DESKTOP_TESTS` / `DESKTOP_BASELINE` / `DESKTOP_DELTA` | **836** / 596 / **+240** |
| `core_data.test` | 204（与脚本期望一致） |
| `core_db.test` | 71（与脚本期望一致） |
| `core_domain.test` | 62（与脚本期望一致） |
| 四个 `*_ANALYZE` | 全部 `VERBATIM`（逐字 `No issues found!`） |
| `OUT_OF_SET` | **0** |
| `VIOLATIONS` | **0** |
| `GATE_EXCLUDED` | 0 |
| `PS1_ASCII_VIOLATIONS` | **0**（`PS1_SCANNED=493` / `NEW_NON_ASCII=0` / `FLIPPED=0`） |
| `STATUS_LINES` | 21（与改前相同） |
| `HEAD` / `AHEAD` | `85b809a` / 0 |

**四条结论**：

1. **唯一失败项就是 Q9 那条基线**：`GATE_FAILURES=1`，除它之外全部 PASS。Q8 的白名单在**本体**里同样生效
   （`OUT_OF_SET=0`），§九 的复算结论被本体证实。
2. **本环 3 条断言修复在真实全量下站得住**：`desktop.test` `EXIT=0` / `FAILS=0` / `TESTS=836`，
   四个包 analyze 全部逐字 `No issues found!`；`VIOLATIONS=0` 说明本环只动了白名单、没碰判定逻辑。
3. **真实用例数 = 836，不是 596**。`+240` 是基线设定以来的累计新增，不是本环引入 ——
   本环只改断言、不增用例，两个测试文件仍各为 `+9`。
4. 「门禁全绿」**仍不可声明**，卡点已收敛为一条：`:38` 的 `$baseline` 是否更新为 836。

**证据路径**：

- `reports\task51-gate\summary.txt` —— 1,935 B / sha16 `F169BFBEEE73C39B` / 23:05:43
- `reports\task51-gate\run-console.txt` —— 2,694 B（含 `CACHE_MOVED` 与全量回显）
- `apps\desktop\build\test_cache\build_moved_20261124-230326` —— stale cache 留证，未删

> 口径：本节是**门禁本体输出**，与 §九 的「按脚本自身算法复算」不同；两者并存，凡冲突以本节为准。

---

## 十一、Q9 定案与门禁转绿（按 `AGENTS.md:57` 带参重跑）

### 十一·1 判定依据（仓库硬规则，不是我的推断）

`AGENTS.md:57` 逐字：

> **门禁对 desktop 用例数是精确等值比较**：`reports\task51-gate.ps1` 的 `-ExpectDesktopTests` 传什么就比什么 ⇒ 任何一轮新增/删除用例后，复跑门禁**必须带当轮的新用例数**（沿用旧数直接判红）；脚本内建 `$baseline=596` 是历史常量，其输出的 `DESKTOP_DELTA` **不是**本轮增量，台账只写「本轮真实新增 N 例」。

⇒ 据此定案：`:38` 的 `$baseline = 596` 是**历史常量**，不是「待更新的过期判据」。§十 留的两条解法里只有一条合规：

- **采用**：复跑时传 `-ExpectDesktopTests <当轮真实用例数>`（本环 = 836）
- **否决**：把 `:38` 改成 836 —— 与 `AGENTS.md:57` 直接冲突；且 `:375` 的 `$delta` 取的是 `$baseline`，改完 `DESKTOP_DELTA` 会恒为 0，反而掩掉「本轮真实新增」

**脚本未改**：`reports\task51-gate.ps1` 仍是 18,797 B / 171 条模式（本环只加过 Q8 授权的 4 条白名单模式，未动任何判定逻辑）。

### 十一·2 第二轮实跑（带参，正式判据轮）

```powershell
& pwsh -NoProfile -ExecutionPolicy Bypass -File 'F:\soft\00selfmade\practilog\reports\task51-gate.ps1' -ExpectDesktopTests 836
```

stale cache 仍由脚本自搬 → `build_moved_20261124-230852`（`Move-Item`，非删除）；`RUN_AT=2026-11-24 23:11:01`；`EXITCODE=0`。

### 十一·3 本体输出（全绿）

| 项 | 实测 |
|---|---|
| `GATE_VERDICT` | **PASS** |
| `GATE_FAILURES` | **0**（输出里没有 `FAIL_ITEM` 行） |
| desktop | `TESTS=836` / `FAILS=0` / `EXPECTED=836` |
| core_data / core_db / core_domain | `204` / `71` / `62`（与 `:334-336` 期望全等） |
| 四包 analyze | 全部 `VERBATIM`（逐字 `No issues found!`） |
| `VIOLATIONS` / `OUT_OF_SET` / `GATE_EXCLUDED` | `0` / `0` / `0` |
| `STATUS_LINES` | 21 |
| `HEAD` / `AHEAD` | `85b809a` / `0` |
| `PS1_ASCII_VIOLATIONS` | `0`（`PS1_SCANNED=493` / `PS1_NEW_NON_ASCII=0` / `PS1_FLIPPED=0`） |

第 6 行顺带自证 Q8：新增的 4 条白名单模式是**纯 ASCII**，没有破坏脚本自身的 ASCII-only 约束。

### 十一·4 与 §十 的关系（口径区分，不是修订）

§十 那一轮是**故意不带参**跑本体（用户当轮指令「直接跑，读真实计数」），所以 `EXPECT=596` 判红是**预期内的判别性结果**，它证明两件事：① 当轮真实计数 = 836；② 门禁确实做精确等值比较（不是区间或 ≥）。§十一 才是**带当轮用例数**的正式判据轮，结论 PASS。

**两轮证据都保留、不覆盖**：

- `reports\task51-gate\summary.run1-fail596.txt` —— 1,935 B / sha16 `F169BFBEEE73C39B`（FAIL 轮原件，从 `summary.txt` 复制留存）
- `reports\task51-gate\summary.txt` —— PASS 轮（`RUN_AT=23:11:01`）
- `reports\task51-gate\run-console-expect836.txt` —— PASS 轮控制台全量回显（含 `CACHE_MOVED`）

### 十一·5 台账口径（按 `AGENTS.md:57` 最后一句）

- 本环（stage 5）**真实新增用例 = 0**：只修 3 条既有断言，`task60_project_domain_edit_test.dart` 与 `task63_w7_l10n_test.dart` 仍各 `+9`。⇒ 台账写「本轮真实新增 0 例」。
- **不写** `DESKTOP_DELTA=240`：那是相对 596 历史常量的差，跨了 Task 51 之后多个任务，**不是**任一轮的增量。
- 836 的构成不做逐任务追溯（596 → Task 51 的 606 → … → 836），因为台账只要求当轮真实新增，追溯既无需求也易错。

### 十一·6 收口判定

- **门禁：PASS（全绿）** —— 这是本批第一次拿到 `GATE_VERDICT=PASS`。
- **stage 5：done** —— 3 条被 stage 4 打破的断言已修（`+9` / `+9` / `+23` 全绿）+ Q8 白名单已授权落地 + Q9 已定案闭环。
- **链：`status=blocked`** —— 卡点已**不再是技术项**，而是 **8 条人工验收点未拍板**：`Q3` / `Q4` / `Q5` / `U5` / `Q1` / `Q2` / `Q6` / `Q7`（`Q8` 已授权落地、`Q9` 已闭环）。`current_stage` 保持 5、`next_session_id` 置 null，等人工答复再起 stage 6。

### 十一·7 本环未做的事

1. 未改 `reports\task51-gate.ps1:38`，未改任何判定逻辑（见 §十一·1）。
2. 未替用户回答 Q3/Q4/Q5/U5/Q1/Q2/Q6/Q7（全部属人工验收点）。
3. 未 `git commit`/`add`/`stash`/`checkout`，未打包、未分发 —— `HEAD=85b809a` / `AHEAD=0` 可用作旁证。
4. 未起 stage 6（`blocked` 停链）。

### 十一·8 证据指纹（供下一环独立校验，勿只看转述）

| 证据 | 字节 | sha16 | 说明 |
|---|---|---|---|
| `reports\task51-gate\summary.txt` | 1,890 | `9A676DAC79CA6592` | **PASS 轮**（带 `-ExpectDesktopTests 836`，`RUN_AT=2026-11-24 23:11:01`，`EXITCODE=0`） |
| `reports\task51-gate\summary.run1-fail596.txt` | 1,935 | `F169BFBEEE73C39B` | 第一轮**不带参 FAIL** 摘要，重跑前已备份，未被覆盖 |
| `reports\task51-gate\run-console-expect836.txt` | — | — | PASS 轮完整控制台 |
| `reports\task51-gate.ps1` | 18,797 | — | CRLF 420/420，非 ASCII 0，含 Q8 新增 4 条白名单模式 |
| `apps\desktop\test\task60_project_domain_edit_test.dart` | 23,005 | `48359BDCA6E120F1` | 修后，`+9` 全绿 |
| `apps\desktop\test\task63_w7_l10n_test.dart` | 13,285 | `861B96F4F7C56170` | 修后，`+9` 全绿 |
| `docs\relay.json` | 48,855 | — | 顶层 21 key，`stages[4].status=done`，`blocked_on` 8 条 |

**判据**：下一环若要复核「stage 5 的门禁确实 PASS」，只需比对 `summary.txt` 的字节数与 sha16 两项，不必重跑 2 分 10 秒的门禁本体。

---

## 十二、人工验收点拍板落定（用户裁定 · 2026-11-24T23:16）

### 十二·1 裁定原文与效力

用户在本报告第十一章落盘后给出唯一一句裁定：

> 「8 条人工验收点，全部接受你的建议。把这个补充进handoff 文档中，然后再次撰写 Prompt。」

三件事同时成立：

1. **8 条全部采纳 ⇒ 零代码改动**：§十一·6 列出的 `Q3` / `Q4` / `Q5` / `U5` / `Q1` / `Q2` / `Q6` / `Q7` 全部按上一环给出的「维持现状」建议执行，不新增任何源码改动、不新增任何 l10n 键、不改任何断言。
2. **授权补写本 handoff**：本章即该授权产物。用户当轮指令**覆盖**阶段范围书里「不得修改 handoff 文档」的禁令 —— 裁决顺序见 `docs\RELAY-ADAPTATION.md` §1（**用户当轮指令 > `AGENTS.md` 硬规则 > `relay.json` > `AGENT-RELAY.md` > 口头推断**）。
3. **要求重写接力 Prompt**：针对下一阶段（stage 6）重写，随本轮回答正文交付，不另建文件。

### 十二·2 逐条落定（8 条 → 全部「维持现状」）

| # | 条目 | 裁定 | 落地后果 |
|---|---|---|---|
| Q3 | 全角 `＋` 是否拆成 l10n 键 | **不改**：保留全角字符字面量，不新增 l10n 键 | 缺口面计数不变 |
| Q4 | `settings.dart:239`「简体中文」是否按当前 locale 映射 | **保留中文原文**，不做 locale 映射 | 与 `settings.dart` 现有语言列表口径一致 |
| Q5 | `entities.dart:111` 异常消息是否 l10n 化 | **不 l10n 化**：领域层异常消息保持单语，用户可见文案由 UI 侧兜底 | 领域层不引入 Flutter / l10n 依赖 |
| U5 | `repositories.dart:47-50` 是否纳入缺口面 | **不纳入**：缺口总数**维持 35 条** | 与 stage 2 / stage 3 的 35 条基线对齐 |
| Q1 | 450 条格言是否更换 | **不更换** | `quote.dart` 用 `{en, zh}` 双字段，双语由数据自带 |
| Q2 | 450 条格言是否逐条审译 | **不审译** | stage 2 的「格言属 l10n 缺口」前提已被推翻，不再列为待办 |
| Q6 | `StateError → MissingEntityException` 是否回退 | **不回退**：确认定案 | 本环 3 条断言即按此类型化异常修好（`+9` / `+9` / `+23` 全绿） |
| Q7 | `dialog.dart:254-259` 注释口径 | **确认现注释准确**，不改 | 无代码改动 |

**合计代码改动 = 0**。`git status --porcelain -uall` 仍 21 行、`HEAD=85b809a`、`AHEAD=0` —— 与本章写入前完全一致。

### 十二·3 状态位移（本章唯一改动的是台账与文档）

| 维度 | 拍板前 | 拍板后 |
|---|---|---|
| 门禁 | `PASS`（全绿） | `PASS`（未重跑，见 §十二·5 「未验证项」） |
| stage 5 | `done` | `done`（不变） |
| 链 `status` | `blocked` | **`running`** |
| `current_stage` | 5 | **6** |
| `blocked_on` | 8 条（`Q3`/`Q4`/`Q5`/`U5`/`Q1`/`Q2`/`Q6`/`Q7`） | **0 条**（全部落定） |
| `next_session_id` | `null` | `null`（由 stage 6 环建会话后自填） |

### 十二·4 下一阶段移交（stage 6 = W9 收口）

范围定义在 `docs\relay\stage-2-scope.md:227`，四项：

1. **68.4b / 68.4i 复扫** —— 缺口面复扫，口径以 U5 裁定为准（维持 35 条，`repositories.dart:47-50` 不计入）。
2. **68.4g verifier 终判** —— 独立验收判定，要证据不要转述。
3. **68.4h `git commit` / `push`** —— **属人工验收点**：本链至今**零 git 写操作**，`commit` / `push` 必须由用户明确授权（`AGENTS.md` §2 R 系列禁令），stage 6 环不得自行执行。
4. 收尾照 `docs\AGENT-RELAY.md:61-68` 三件事；`max_stages=6` ⇒ stage 6 是**末环**：收口后 `status` 写 `done`，或停在 `git commit` / `push` 这一人工验收点上写 `blocked` 并说明缺什么，**两种情形都不得再 `session_create`**。

### 十二·5 证据与可复核点

| 证据 | 值 | 说明 |
|---|---|---|
| `reports\task51-gate\summary.txt` | 1,890 B / sha16 `9A676DAC79CA6592` | PASS 轮原件，本章**未重跑** |
| `reports\task51-gate\summary.run1-fail596.txt` | 1,935 B / sha16 `F169BFBEEE73C39B` | 第一轮 FAIL 留存件 |
| `reports\task51-gate.ps1` | 18,797 B / CRLF 420-420 / 非 ASCII 0 | 判定逻辑与 `:38` 均未动 |
| `apps\desktop\test\task60_project_domain_edit_test.dart` | 23,005 B / sha16 `48359BDCA6E120F1` | `+9` |
| `apps\desktop\test\task63_w7_l10n_test.dart` | 13,285 B / sha16 `861B96F4F7C56170` | `+9` |
| `docs\relay.json` | 52,585 B / sha16 `22F911DA2EDF760B` / `status=running` / `current_stage=6` / `blocked_on` 空 / `blocked_on_closed` 8 条 | `ConvertFrom-Json` 解析通过；`stages` 5 条仍 == 已完成阶段数（5），符合 `docs\AGENT-RELAY.md:67` |

**回写执行记录（本章落盘后执行）**：按 §十二·3 的目标位移完成了 `docs\relay.json` 回写 —— `blocked_on` 置空（原文改名 `blocked_on_closed` 保留 8 条，另加 `blocked_on_closed_note` 说明 Q3 旧 `suggested` 已被最终裁定覆盖）、插入 `human_checkpoint_resolution` 与 `next_stage` 两块、`status: blocked→running`、`current_stage: 5→6`；原件备份在 `reports\tmp\relay.json.bak-presplice`。回写后 `ConvertFrom-Json` 解析通过：顶层 21 key 全存活、四组新键各出现 1 次（无重复插入）、`sessions` 仍 6 条且本环 `mvs_dd5bbcf80ab040c5a017d664411a84eb` 以 `stage=5` 在册。另追加 `model_policy.stage5_measured_correction`（已报错的环不必重建 / fallback key 已实测可用）。注意：顶层 `next_stage_target`（`:39`）是 stage 2 写入的历史目标，**不覆盖**，stage 6 的权威范围只认 `stages[4].next_stage`。

**未验证项（如实声明）**：本章落盘后**没有**重跑门禁本体。理由是零代码改动；`reports\` 被 git 忽略、不进 `git status`，`docs\relay/*` 已在 Q8 白名单内属合法改动面 ⇒ 重跑只会重复得到 `PASS`，不产生新信息。若下一环要本批的新鲜门禁证据，按 §十一·1 的命令带 `-ExpectDesktopTests 836` 重跑即可（约 2 分 10 秒，stale cache 由脚本自搬）。

**放行但未派工（如实声明）**：`docs\relay.json` 已就绪（`status=running` / `current_stage=6` / `blocked_on` 空），但本环**没有**调用 `session_create`。理由：stage 6 是末环，且 68.4h 的 `git commit` / `push` 必须用户明确授权，故留一次确认由用户决定何时开跑。用户确认后按 `docs\AGENT-RELAY.md:80-90` 的配方建会话：`agent_name="me"` / `title="relay-6-w9-close"` / `workspace_dir="F:\soft\00selfmade\practilog"` / `content` = stage 5 回答里给出的接力 prompt，**不传 `effort`**；建完立刻 `session get` 回读 `effective_model` / `workspace_dir` 两要素再登记。

**判据**：下一环读本章即可确认「8 条人工验收点已全部拍板、零代码改动、链已放行到 stage 6」，无需回读对话上下文。