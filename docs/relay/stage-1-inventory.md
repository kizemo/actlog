# Relay Stage 1 · 只读盘点（PractiLog 最近未闭环批次）

- **环次**：stage 1（`current_stage = 1`，`relay.json` 启动值）
- **本环会话**：`mvs_f0f4b5b2d4804d3fabd8f23d1e35544c`
- **模型**：`minimax/MiniMax-M3`（effort `on`；`relay.json` `model_policy.preferred`）
- **时间**：2026-11-24 夜
- **类型**：`read_only_inventory`（`relay.json` `stages[0].type`）
- **本环写集**（`relay.json` `stages[0].scope` 声明）：① 新建 `docs\relay\stage-1-inventory.md`；② 只追加回写 `docs\relay.json` 本环条目。**未修改仓库任何既有文件**（见 §5）。

> **裁决顺序**（`docs\RELAY-ADAPTATION.md` §1）：用户当轮指令 > `AGENTS.md` 硬规则 > `docs\relay.json` 状态机 > `docs\AGENT-RELAY.md` 通用协议 > 会话口头推断。
> 本环实际裁决：用户当轮指令 =「执行 current_stage=1 这一环、不要问问题」；`AGENTS.md`「自动接力（Relay）—— 硬规则」第 3 条为硬判据 ⇒ 先只追加回写 `relay.json` + 回读核对，再起第 2 环。

---

## 1. 最近未闭环批次的判定

### 1.1 结论（两层口径，必须分开读）

**第一层 · 台账事实口径**：计划文件的复选框里，**最近一个未勾闭环的批次 = Task 68 / §68.4a–i（9 条）**，其上游汇总项 = **§47.2 W9**（plan `:8326`）。
次级 backlog（不属本链当前批次）：`51.4e` 真机像素验收、Task 64–67（P0–P3）、规划 §14 的 9 项待核实。

**第二层 · 本链可推进口径（按 `relay.json` 21:40 追加的 `concurrency` / `next_stage_target`）**：
- 并发会话 `mvs_e395774e42a84ff9a218fcb0b7349f98` **正在实施收口 Task 68**（`relay.json` `concurrency.their_task` 实测记载：门禁 desktop 836 / core_data 204 / core_db 71 / core_domain 62 / 四包 analyze 逐字 `No issues found!` / `VIOLATIONS=0`）。
- `relay.json` `next_stage_target` 原文：「**第 2 环及之后不得重做 Task 68**（并发会话正在收口）。目标批次 = Task 68 的下一批：W9 残留 521 条英文态可见中文，拆为 68 条 UI 文案 l10n 化（可自动推进）+ 450 条格言数据（属产品决策，命中人工验收点即 blocked 登记，**不得自行取舍**）。」
- ⇒ **本链的盘点结论指向「W9 残留 521 条」这一下一批次**，不把 Task 68 当作本链的未闭环目标；§68.4a–i 在本环只做**现状核销**（谁在做、做到哪、还差什么），**不代打勾、不重做、不抢写**。

**两层口径不矛盾**：台账复选框仍未勾（事实），但实施归属在并发会话（分工）⇒ 台账口径回答「还有什么没闭环」，可推进口径回答「本链下一环能动什么」。

### 1.1.1 `AGENTS.md` 接力章节回读确认（上游 21:40 追加要求）

开工时回读 `AGENTS.md`，**第 485–494 行「自动接力（Relay）—— 硬规则」6 条确实仍在**（实测原文见 `AGENTS.md:485`–`:494`，文件 494 行，sha16 `9E529458B40F16A9`，mtime `2026-11-24 21:33:28`）。
第 485 行原文：「## 自动接力（Relay）—— 硬规则」；第 489 行「开工第一步读 `docs\relay.json`。`status != "running"` ⇒ 不接力，正常收尾。」；第 491 行 = 本环收尾判据（只追加回写 + 起下一环）。
⇒ **接力章节未被抹掉**，本链可继续（若被抹掉须 `status=blocked` 停链）。

### 1.2 判定依据（全部引用项目自己台账真源，file:line 逐字）

真源计划文件 = `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`（9642 行）。
`AGENTS.md` §6「权威文档导航」明定台账优先级：**实测 > 运行时产物 > 源码 > 文档转述**；本节全部条目属「实测/运行时产物」层。

| # | 未闭合项 | 真源 file:line | 原文摘录 | 层级 |
|---|---|---|---|---|
| 1 | **§68.4a** en 态全量 g1–g4 | plan `:9611` | `- [ ] **68.4a en 态全量 g1–g4**：四门禁全量 PASS（`GATE_VERDICT=PASS` / `GATE_FAILURES=0` / 四包 `ANALYZE=VERBATIM` / `VIOLATIONS=0` / `OUT_OF_SET=0` / `PS1_ASCII_VIOLATIONS=0`），desktop 用例数精确等值。` | 判据原文 |
| 2 | **§68.4b** 全仓静态中文扫描 | plan `:9612` | `- [ ] **68.4b 全仓静态中文扫描**：英文态可见的中文 UI 字面量 = 0（扫描面 = `apps\desktop\lib\**` 全量，不限 5 个 part）；不可见处（协议常量 / 调试异常 / 存储格式正则 / 注释）逐一登记。` | 判据原文 |
| 3 | **§68.4c** 死 key 清理 | plan `:9613` | `- [ ] **68.4c 死 key 清理（编译级证明）**：移除清单内每个键后，`analyze` 仍逐字 `No issues found!` 且全量 `test` 仍全绿；**清单外一律不动**。` | 判据原文 |
| 4 | **§68.4d** 基线定稿 | plan `:9614` | `- [ ] **68.4d 基线定稿**：最终用例数写进 `AGENTS.md` §7 + R2 阶梯（**只增不减**）。` | 判据原文 |
| 5 | **§68.4e** 删 `@Deprecated` | plan `:9615` | `- [ ] **68.4e 删 `@Deprecated`**：如实登记「**实测零注解命中 ⇒ 无待删对象，零改动**」，并附扫描面与命中明细（`app_theme.dart:149` 为注释）。` | 判据原文 |
| 6 | **§68.4f** 域层「工作日」正解 | plan `:9616` | `- [ ] **68.4f 域层「工作日」正解**：英文帧中 `工作日` 归零；域层中文硬编码按 68.2 第 3 条处置并登记。` | 判据原文 |
| 7 | **§68.4g** 独立复验 | plan `:9617` | `- [ ] **68.4g 独立复验**：verifier 会话 **≠ 实现者**、只读，总判 `PASS`（未判定项如实登记）。` | 判据原文 |
| 8 | **§68.4h** 收口提交与推送 | plan `:9618` | `- [ ] **68.4h 收口提交与推送**：commit + push ⇒ `AHEAD=0` / `BEHIND=0`。` | 判据原文 |
| 9 | **§68.4i** 宣称口径 | plan `:9619` | `- [ ] **68.4i 宣称口径**：W9 全部子项闭合 ⇒ 方可宣称「英文界面零中文」；否则只声明已闭合范围。` | 判据原文 |
| 10 | **§47.2 W9**（上游总项） | plan `:8326` | `- [ ] 47.2 W9 全量 en 态 g1–g4 + verify、死 key 清理、基线定稿写 AGENTS §7、删 `@Deprecated`` | 上游汇总项 |

**同批次已坐实的结论**（`plan §68.6`，`:9628`–`:9642`，原文引自计划）：
- `:9630` 实测口径：worker B 全仓静态中文扫描，扫描面 = `apps\desktop\lib\**\*.dart` **93 个文件**（词法状态机区分注释 / 字符串 / 插值）⇒ **英文态可见中文 521 条**（严格文案口径 **515 条**）。
- `:9631`–`:9634` 构成 = **450 条**（3 套中文格言数据：`quote_set_character.dart` / `quote_set_mastery.dart` / `quote_set_success.dart` 各 150）+ **68 条**（绕过 l10n 的 UI 文案 / 字形）+ **3 条**（En mixin 泄漏：`parts\dialog.dart:894/960` 全角 `＋`、`parts\settings.dart:257` `简体中文`）。
- `:9635` 判读：**68.4b 判据不成立 ⇒ 不打勾**。
- `:9636` 连带后果：**68.4i 不升级 ⇒ §47.2 W9 不打勾** ⇒ 对外只声明「**§47 W3–W8 覆盖范围零中文**」，**不得**宣称「英文界面零中文」。
- `:9642` 本轮可闭合子项：`68.4a` / `68.4c` / `68.4d` / `68.4e` / `68.4f` / `68.4g` / `68.4h`；**`68.4b` / `68.4i` 与 `§47.2 W9` 保持未勾**。

### 1.3 排除项与次级 backlog（本链不作为当前批次）

| 项 | file:line | 排除理由 |
|---|---|---|
| `51.4e 真机像素验收 4 项` | plan `:8527` | Task 52 收口登记 ① ② ④ = PASS；③-A PASS；③-B「重叠色比 §50 更浅」= 方向成立但精确值未判定；派生「plan↔backfill 底纹带区分」= 未判定 ⇒ 按 R5 保持未勾，**属真机取证类，排在 Task 68 之后** |
| Task 64（P0）/ 65（P1）/ 66（P2）/ 67（P3） | plan `:9437`–`:9440` | §62.3 下阶段闸门项，**排在 §47 剩余项之后**（§47 仅剩 W9 一项） |
| 规划 §14 的 12 项待核实 | plan `:9441` | 2026-11-24 问卷闭合 3 项，**仍开放 9 项**（`shell_nav_rail_test.dart` 断言文本、`key_bar` 与 nav 清单、`_buildBar` 横排末尾结构、`l10n_keys.dart` 登记表结构、`providers_recurring.dart` 语义、`recurring_task` 是否支持 yearly、`project_increment` 三列可否 NULL、sync 引擎第二处表清单、`TableNames` 常量真源与 drift 生成流程） |

### 1.4 台账指针失效登记（如实上报，不擅自改他人字段）

`docs\relay.json` 字段 `plan_doc` = `docs\开发计划.md`，但该文件**不是 Task 级真源**：
- mtime = `2026-11-06 22:57:12`，sha16 `DFA7AD406728F9A3`；
- 全文**无任何 `- [ ]` 复选框**（`grep` 零命中）⇒ 不含任何未闭环项，无法作为「最近未闭环批次」的判定源；
- `AGENTS.md` §6 明定真源为计划文件 `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`。

**处置**：本环**不擅自改写** `plan_doc` 字段（那是他人字段，且改动会引入越界风险），仅在此登记该指针失效；第 2 环的 scope 内已写入真源路径。

---

## 2. 剩余未闭环项逐条清单

状态取值：`未闭合` / `已被并发会话实施但未打勾` / `本环只读判定不成立` / `已被并发会话闭合但台账未更新`。

| 项 | 当前状态（本环实测/实测产物） | 归属会话 | 阻塞类型 |
|---|---|---|---|
| 68.4a | **红灯**：并发门禁 `GATE_VERDICT=FAIL` / `GATE_FAILURES=1` / `FAIL_ITEM=OUT_OF_SET=3`（见 §3.3）。其余判据全绿：`VIOLATIONS=0`、四包 `ANALYZE=VERBATIM`、`PS1_ASCII_VIOLATIONS=0`、desktop `TESTS=836` = `DESKTOP_EXPECTED=836` | 并发 Task 68 控制器 | 红灯唯一来自**接力链自身 3 个新 docs 文件不在门禁白名单**（见 §3.4） |
| 68.4b | **判据不成立**（实测 521 条 ⇒ ≠ 0）⇒ 按计划 `:9635` 保持未勾 | Task 68 worker B | 需产品决策（450 格言三选一 + 68 UI 文案 l10n 化） |
| 68.4c | **实施已完成**：`reports\task68-deadkey-cleanup.md` —— 删 7 条死 key；ABC 三键因 `packages\core_data\lib\src\priority.dart` 动态 id 引用回滚；真实口径 byGetter **390** / 总键 **447** / desktop 836 全绿 | Task 68 worker C | 台账未打勾（复选框只控制器能打，`AGENTS.md` R5） |
| 68.4d | **待落**：基线真值 desktop **836**（`task68-gate-run1.log` `DESKTOP_TESTS=836` / `DESKTOP_EXPECTED=836`）；`AGENTS.md` §7 现记 Task 63 轮 834 ⇒ 需由控制器写入 §7 + R2 阶梯（只增不减） | 并发 Task 68 控制器 | 控制器写集（`AGENTS.md` §7 / `handoff.md` / `progress.md` / `docs\B1_验收记录.md`，见 plan `:9607` C-4） |
| 68.4e | **实测零注解命中 ⇒ 无待删对象、零改动**（`app_theme.dart:149` 为注释） | Task 68 | 待如实登记进台账 |
| 68.4f | **实施已完成**：`reports\task68-weekday.md` —— 域层「工作日」正解，11 条 getter，`byGetter` 386 → 397，desktop 834 → 836 | Task 68 worker A | 台账未打勾 |
| 68.4g | **进行中**：verifier 会话 `mvs_33a179b2de0a435e94c52f2d17291c37`（只读，status=started） | 并发 Task 68 | 等其终判 |
| 68.4h | **待做**：commit + push ⇒ `AHEAD=0` / `BEHIND=0`。当前 `HEAD=01b6339` / `AHEAD=0` / `BEHIND=0`（本环实测），但 17 行改动**尚未提交** | 并发 Task 68 控制器 | **命中人工验收点**（git commit / push） |
| 68.4i | **不可升级**（68.4b 未闭合，连坐） | — | 宣称口径 |
| §47.2 W9 | **不可打勾**（连坐 68.4b / 68.4i） | — | 宣称口径 |
| **W9 残留 521 条英文态可见中文**（本链**下一批次目标**，`relay.json` `next_stage_target` 指定） | 521 条 = 68 条 UI 文案 + 450 条格言 + 3 条 En mixin 泄漏（plan `:9630`–`:9634`） | 本链第 2 环起 | 68 条 UI 文案 = **可自动推进**；450 条格言 = **产品决策，只登记不定性**（命中 `human_checkpoints`「验收口径本身含糊」⇒ 触及即 `status=blocked`）；3 条泄漏随 68 条一并 l10n 化 |
| **B 类 4 键** | `hoursCount` / `minutesCount` / `deferredDays` / `moodScoreLabel`（plan `:9640`） | 下一批次 | 需产品 / 测试口径决策「补界面消费」还是「连断言退役」 |
| **4 项未判定**（worker B 盲区） | `project_store.dart` 6 条诊断串是否经 toast 上屏（若上屏则 521 → 527）；`toast_probe.dart:111` 发布构建可达性；「英文态可见」为静态推断、未真机逐条截图 | 下一批次 | 如实登记，不得当作已闭合 |

**归属澄清（上游 21:40 / 21:42 两次追加）**：§68.4a–i **全部由并发会话 `mvs_e395774e42a84ff9a218fcb0b7349f98` 收口**（`relay.json` `concurrency.their_task` 实测：desktop 836 精确等值 / core_data 204 / core_db 71 / core_domain 62 / 四包 analyze 逐字 `No issues found!` / `VIOLATIONS=0`）。
⇒ 本环对 §68.4a–i **只做现状核销，不代打勾、不重做**（重做 = 写集冲突，命中 `human_checkpoints` 第 7 条「本环写集与并发在写的会话冲突」）。

**并发会话清单**（`mavis session list` 实测，本环开工时点）：

| session_id | 角色 | 任务 | 状态 |
|---|---|---|---|
| `mvs_e395774e42a84ff9a218fcb0b7349f98` | 控制器 | 接手 PractiLog Task 63 收口与后续（model `minimax/MiniMax-M3.1-Flash`） | 活跃 |
| `mvs_33a179b2de0a435e94c52f2d17291c37` | verifier | Task68 独立复验（只读） | started |
| `mvs_126817083c97415598f22ed96df6d104` | worker | W9 死 key 清理 + 回归修正 | 活跃 |
| `mvs_ef941b7202c546e1a32d575fb8948ffa` | worker | W9 域层工作日正解 | 活跃 |
| `mvs_825269b6848f4108b8ea82e0af225fda` | worker | W9 死 key 与全仓中文扫描 | 活跃 |

---

## 3. 每项对应的可执行门禁命令与当前原始输出

### 3.1 门禁装置映射（`AGENTS.md` §3 验证装置地图，`:175`–`:213`）

| 判据 | 装置 | 期望 |
|---|---|---|
| 静态分析零 issue | `tools\gates\g1_analyze.ps1` | 逐字 `No issues found!`；自动发现 `packages\` 下含 `pubspec.yaml` 的包 |
| 单测全绿 | `tools\gates\g2_unittest.ps1` | core_domain / core_db / core_data |
| 迁移 + schema 一致性 + 约束有牙 | `tools\gates\g3_migration.ps1` + `tools\gates\g3_schema_check.mjs`（Node `node:sqlite` 实跑） | 14 张表集合一致；CHECK/UNIQUE/FK 插坏数据必须被拒 |
| 视觉 / 无障碍对比度 | `tools\gates\g4_contrast.ps1` | 跑 `theme_tokens_test` + `app_theme_test` |
| **四包全量门禁（本批次主判据）** | `reports\task51-gate.ps1` | `GATE_VERDICT=PASS` / `GATE_FAILURES=0` / 四包 `ANALYZE=VERBATIM` / `VIOLATIONS=0` / `OUT_OF_SET=0` / `PS1_ASCII_VIOLATIONS=0` / desktop 用例数**精确等值** |
| `.ps1` 纯 ASCII | `reports\task57-ps1-ascii-scan.ps1`（基线 `reports\task57-ps1-ascii-baseline.txt`） | `PS1_ASCII_VIOLATIONS=0` |

**全量门禁可执行命令**（脚本自述用法 `reports\task51-gate.ps1:3`–`:7`）：

```powershell
cd F:\soft\00selfmade\practilog
pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests 836
```

**R2 前置（`AGENTS.md` §2）**：跑全量门禁前必须先把 `apps\desktop\build\test_cache\build` **改名挪走**（`Move-Item`，**不删**），否则 OS Error 183 永久挂死。
本轮实测：脚本自身已在 `:16`–`:25` 内建该挪移（`CACHE_MOVED=...` / `CACHE_MOVED=NONE_ALREADY_MOVED`），手工预挪仍属规范动作。
镜像必须**进程内**设置：`$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'`；`$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`（脚本 `:27`–`:28` 已内建）。

### 3.2 本环**亲跑**的原始输出（分析判据，只读，不写工作区）

| 包 | 命令 | 原始输出 | 退出码 |
|---|---|---|---|
| `apps\desktop` | `flutter analyze`（工作目录 `F:\soft\00selfmade\practilog\apps\desktop`） | `No issues found! (ran in 14.7s)` | 0 |
| `packages\core_domain` | `dart analyze` | `No issues found!` | 0 |
| `packages\core_db` | `dart analyze` | `No issues found!` | 0 |
| `packages\core_data` | `dart analyze` | `No issues found!` | 0 |

**逐包 analyze 是硬要求**（`AGENTS.md` R2 + 记忆沉淀）：根仓库 `flutter analyze` 会因历史备份 `.dart`（`reports\task47-W1c-3-evidence\backup_arm_c\desktop_shell.dart` 等）报 192 issues，**不可用作判据**；必须主包 + 每个 package 分别跑。

### 3.3 并发会话门禁原始输出（`reports\task68-gate-run1.log`，`RUN_AT=2026-11-24 21:35:39`，`HEAD=01b6339`）

逐字关键行：

```
ITEM=desktop.analyze EXIT=0 TESTS=1 FAILS=0 ANALYZE=VERBATIM RESULT=UNKNOWN
ITEM=desktop.test EXIT=0 TESTS=836 FAILS=0 ANALYZE=NO RESULT=PASS
ITEM=core_data.analyze EXIT=0 TESTS=-1 FAILS=0 ANALYZE=VERBATIM RESULT=UNKNOWN
ITEM=core_data.test EXIT=0 TESTS=204 FAILS=0 ANALYZE=NO RESULT=PASS
ITEM=core_db.analyze EXIT=0 TESTS=-1 FAILS=0 ANALYZE=VERBATIM RESULT=UNKNOWN
ITEM=core_db.test EXIT=0 TESTS=71 FAILS=0 ANALYZE=NO RESULT=PASS
ITEM=core_domain.analyze EXIT=0 TESTS=-1 FAILS=0 ANALYZE=VERBATIM RESULT=UNKNOWN
ITEM=core_domain.test EXIT=0 TESTS=62 FAILS=0 ANALYZE=NO RESULT=PASS
GATE_VERDICT=FAIL
GATE_FAILURES=1
FAIL_ITEM=OUT_OF_SET=3
DESKTOP_TESTS=836
DESKTOP_EXPECTED=836
DESKTOP_ANALYZE=VERBATIM / CORE_DATA_ANALYZE=VERBATIM / CORE_DB_ANALYZE=VERBATIM / CORE_DOMAIN_ANALYZE=VERBATIM
VIOLATIONS=0
OUT_OF_SET=3
STATUS_LINES=17
HEAD=01b6339
AHEAD=0
PS1_ASCII_VIOLATIONS=0
RUN_AT=2026-11-24 21:35:39
```

**未闭合项映射**：唯一失败项 = `OUT_OF_SET=3` ⇒ **68.4a 未达成**；其余 68.4a 子判据（`GATE_FAILURES=0` 之外的全绿项）已达成。

### 3.4 `OUT_OF_SET=3` 精确归因（本环只读取证）

判定逻辑（`reports\task51-gate.ps1:300`–`:309`）：对 `git status --porcelain` 的每条路径归一化（`\` → `/`）后，逐条比对 `$patterns`（`:112`–`:293`）；`packages/` 前缀另需命中 `$pkgAllowed`（`:295`–`:298`）；**任一 pattern 未命中即计入 `outOfSet`** ⇒ `OUT_OF_SET>0` 即门禁红。

同日志 `STATUS_PATHS:` 段共 17 行，其中**末尾 3 行**为：

```
docs/AGENT-RELAY.md
docs/RELAY-ADAPTATION.md
docs/relay.json
```

⇒ **`OUT_OF_SET=3` 精确等于接力链自身新建的 3 个 docs 文件**，与 Task 68 的 14 条改动无关。

白名单中与 `docs` 有关的 pattern 仅 5 条（`reports\task51-gate.ps1`）：

| 行 | pattern | 覆盖 |
|---|---|---|
| `:195` | `docs/B1_*.md` | `docs\B1_验收记录.md` |
| `:196` | `docs/superpowers/plans/*.md` | 真源计划文件 |
| `:198` | `docs/task40/*` | 任务目录 |
| `:283` | `docs/task62/*` | 任务目录 |
| `:284` | `docs/task63/*` | 任务目录 |

**⇒ `docs\relay\*.md` 不被任何 pattern 覆盖。**

**可预期的下一轮红灯**：本环新建 `docs\relay\stage-1-inventory.md` ⇒ `STATUS_LINES` 17 → **18**、`OUT_OF_SET` 3 → **4**（若并发控制器未先追加白名单）。
**归属与处置**：
- 追加白名单 = `reports\task51-gate.ps1` 的 `$patterns`，属 **C-2 控制器写集**（plan `:9605`）⇒ **本链不自行修改**（改了既与并发控制器抢同一文件，又使 `OUT_OF_SET` 再 +1）；
- 计划 `:9626` 明写「worker 若发现还需改动白名单外的路径 ⇒ **不得自改门禁脚本**，须回报控制器按实测路径追加」；
- **需上游/并发控制器追加**：`docs/relay.json`、`docs/AGENT-RELAY.md`、`docs/RELAY-ADAPTATION.md`、`docs/relay/*.md`（4 条）。
- **与并发控制器口径对齐**（`relay.json` `concurrency.gate_whitelist_note` 原文）：「`docs\relay.json` 每跳都会变，`OUT_OF_SET` **不是噪声而是长期固定项**；已在 §7 快照侧单列为「接力链写集，不属本批次范围」。**改门禁脚本属人工验收点，链不得自行改**。」
  ⇒ 本环据此**不把 `OUT_OF_SET` 记为 Task 68 的功能缺陷**，只记为「接力链写集的已知固定项 + 需控制器加白名单」；本链**不自行改门禁脚本**（与上游约束 B 的禁写清单一致）。

### 3.5 逐项门禁命令与当前原始输出汇总表

| 未闭合项 | 可执行命令 | 当前原始输出 | 判读 |
|---|---|---|---|
| 68.4a | `pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task51-gate.ps1 -ExpectDesktopTests 836` | `GATE_VERDICT=FAIL` / `GATE_FAILURES=1` / `FAIL_ITEM=OUT_OF_SET=3` | 红；唯一失败项=白名单问题 |
| 68.4b | worker B 全仓中文扫描（`reports\task68-deadkey-scan.md` + plan `:9630`） | `521` 条（严格文案口径 `515`） | 判据不成立 ⇒ 不打勾 |
| 68.4c | `flutter analyze` + `flutter test`（逐包） | desktop `TESTS=836 FAILS=0`；worker C 报告 byGetter `390` / 总键 `447` | 实施完成，待台账打勾 |
| 68.4d | `git status` / 门禁 `DESKTOP_TESTS` | `DESKTOP_TESTS=836`（`AGENTS.md` §7 现记 834） | 待控制器写 §7 + R2 阶梯 |
| 68.4e | `@Deprecated` 全仓扫描 | 零注解命中（`app_theme.dart:149` 为注释） | 零改动，只需登记 |
| 68.4f | 英文帧「工作日」判读 | worker A：11 条 getter，`byGetter` 386 → 397 | 实施完成，待台账打勾 |
| 68.4g | verifier 只读复验 | 会话 `mvs_33a179b2de0a435e94c52f2d17291c37` status=started | 等终判 |
| 68.4h | `git rev-list --count HEAD..origin/main` / `origin/main..HEAD` | `AHEAD=0` / `BEHIND=0`（但 17 行改动未提交） | 待控制器 commit + push（**人工验收点**） |
| 68.4i | 宣称口径核对 | 68.4b 未闭合 | 不升级 |
| §47.2 W9 | 上述 a–i 的汇总 | 68.4b / 68.4i 连坐 | 保持未勾 |

---

## 4. 第 2 环建议写集与风险

### 4.1 建议的第 2 环定义（`read_only_reverify_scope`）

**标题**：下一批次范围定稿 + W9 残留 521 条 l10n 化可派工清单切分（W9 残留面 = 本链目标批次；Task 68 §68.4a–i 只核销、不重做）

**与 `relay.json` `next_stage_target` 的一致性**：本环 §1.1 两层口径即按该字段展开 —— 第 2 环**不得**重做 Task 68，目标批次 = W9 残留 521 条 = **68 条 UI 文案 l10n 化（可自动推进）** + **450 条格言数据（属产品决策，只登记不定性，触及即 blocked 登记）**。

**为什么不能由第 2 环直接实施 Task 68**：
1. **写集冲突**：Task 68 的实现环写集 = `apps\**` / `packages\**` / `reports\task51-gate.ps1` / `AGENTS.md` §7 / `handoff.md` / `progress.md` / `docs\B1_验收记录.md` / 计划 §68（plan `:9605`–`:9607` C-2/C-4），**全部由并发会话 `mvs_e395774e42a84ff9a218fcb0b7349f98` 及其 4 个子会话独占** ⇒ 命中 `relay.json` `human_checkpoints`「本环写集与并发在写的会话冲突」⇒ 必须 `status=blocked` 停链，**不得抢写**。
2. **口径含糊**：68.4b 的 450 条格言需要产品决策「翻译 / 换 en 数据集 / 英文态隐藏」三选一（plan `:9639`），属 `human_checkpoints`「验收口径本身含糊或互相矛盾」。

⇒ 第 2 环定位为**零 `apps\` / `packages\` 写入的复验 + 范围定稿环**，把可派工范围切清楚后，再由后续环承接实现。

### 4.2 建议写集（stage 2 scope 建议值）

**允许写**：
- 新建 `docs\relay\stage-2-*.md`（复验报告 + 下一批次范围定稿）；
- 只追加回写 `docs\relay.json` 的 stage 2 条目。

**禁止写（全部属并发会话写集或人工验收点）**：
`apps\**`、`packages\**`、`reports\task51-gate.ps1`、`reports\task68-*`、`AGENTS.md`（含 §7）、`docs\B1_验收记录.md`、`docs\P1_进度.md`、`docs\P1_交接文档.md`、`docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`（§68 复选框只控制器能打，R5）、`.superpowers\sdd\...\handoff.md` / `progress.md`、任何 git commit / push / tag、任何发布分发。

### 4.3 风险登记

| # | 风险 | 证据 | 缓解 |
|---|---|---|---|
| R1 | **门禁红灯根因在接力链自身**：每新增一个 `docs\relay\*.md`，`OUT_OF_SET` +1 | `task51-gate-run1.log:26` `OUT_OF_SET=3`；白名单 docs pattern 仅 5 条（`:195/:196/:198/:283/:284`） | 本环如实登记并上报；由并发控制器追加白名单（4 条），本链不自改 |
| R2 | **并发抢写**：`apps\**` / `packages\**` / 门禁脚本 / 台账行 | 并发 5 个会话活跃（§2 表） | 第 2 环限定零 `apps\packages` 写入 |
| R3 | **宣称口径越界**：误宣称「英文界面零中文」 | plan `:9636` + `AGENTS.md` §7 末句 | 第 2 环只允许「§47 W3–W8 覆盖范围零中文」口径 |
| R4 | **全量 test 与并发门禁抢资源**：`test_cache\build`（OS Error 183）、`sqlite3.dll` 占用 | `AGENTS.md` §5 坑表；`docs\P1_进度.md` 记并发测试占用 sqlite3.dll 会直接失败 | 第 2 环**只跑 analyze（逐包）**，不跑全量 test；或先与并发协调 |
| R5 | **台账 `plan_doc` 指针失效**（`docs\开发计划.md` 非真源） | §1.4 | 第 2 环 scope 内写真源路径；不改他人字段 |
| R6 | **`relay.json` 被并发会话改写导致回写覆盖** | 写前 sha16 `73F9EDA03A6E2BAF` / mtime `2026-11-24 21:33:28` | 回写前**重读**并只追加；回写后回读核对条数与署名 |
| R7 | **68.4g verifier 终判未出**，第 2 环无法自行核销 | `mvs_33a179b2de0a435e94c52f2d17291c37` status=started | 第 2 环只登记「等终判」，不得代打勾 |
| R8 | **本机坑**：锁屏 ⇒ 真机取帧全失真 | 记忆沉淀（本机 `LogonUI` 驻留时 `GetForegroundWindow()==0`） | 第 2 环**不做真机取帧**；如需，先查 `Get-Process LogonUI` |

### 4.4 第 2 环应交付的「下一批次可派工范围」（依据 plan `:9637`–`:9641`）

1. **UI 文案 68 条 l10n 化** —— 高危面清单（plan `:9633`）：`widgets\shell\nav_rail.dart:36-41`（6 条导航项）、`widgets\shell\key_bar.dart:46-53`（8 条快捷键提示）、`widgets\outcome_composer.dart:28-56`（21 条）、`widgets\domain_chips.dart:22-27` + `:72-82`（12 条，**且与 l10n 的 domain 键重复定义**）、`widgets\est_duration_text.dart:17-29`（5 条单位）、`pages\projects_page.dart`（5 条表单校验）、`widgets\habit_quick_dialog.dart:200` + `pages\habits_page.dart:230` + `widgets\habit_section.dart:158`（3 条「次」单位）、`widgets\gantt_chart.dart:84/85/192`（3 条）、`widgets\timeline\slot_fill.dart:85-86`（2 条）。判定：**纯 l10n 改造，工作量可控**。
2. **格言数据 450 条** —— 需产品决策「翻译 / 换 en 数据集 / 英文态隐藏」三选一（`quote_set_character.dart` / `quote_set_mastery.dart` / `quote_set_success.dart` 各 150 条）。**本环只登记、不擅自取舍**（上游 21:42 明确：「属产品决策，只登记不定性，命中人工验收点即写 `status=blocked`」）。
3. **B 类 4 键** —— `hoursCount` / `minutesCount` / `deferredDays` / `moodScoreLabel`，需产品 / 测试口径决策「补界面消费」还是「连断言退役」。
4. **未判定项**（worker B 盲区，须如实登记）：`lib\src\data\project_store.dart` 6 条诊断串是否经 toast 上屏（若上屏则 521 → 527）；`lib\src\widgets\toast_probe.dart:111` 在发布构建的可达性；「英文态可见」为**静态推断**，**未真机英文态逐条截图**。

---

### 4.5 与上游口径的差异登记（按上游 21:42 指令：以台账 file:line 证据为准，不自行取舍）

| # | 上游口径 | 台账 / 实测证据 | 差异结论 | 本环处置 |
|---|---|---|---|---|
| D1 | 「Task 68 门禁**已实测全绿**」 | `reports\task68-gate-run1.log`：`GATE_VERDICT=FAIL` / `GATE_FAILURES=1` / `FAIL_ITEM=OUT_OF_SET=3`；但 `DESKTOP_TESTS=836` = `DESKTOP_EXPECTED=836`、`VIOLATIONS=0`、四包 `ANALYZE=VERBATIM`、`PS1_ASCII_VIOLATIONS=0` | **不冲突**：上游指「功能 / 用例数 / 越界 / analyze 层面全绿」，红灯唯一项 `OUT_OF_SET` 来自**接力链自身的 3 个 docs 文件不在门禁白名单**（§3.4），且已被并发控制器登记为「长期固定项，不是噪声」 | 本环如实记录红灯项及其归因，**不记为 Task 68 功能缺陷**，**不改门禁脚本** |
| D2 | 「Task 68 已闭环中，重做属写集冲突」 | plan `:9611`–`:9619`（§68.4a–i）**复选框仍全未勾**；`:9636` 明写「`68.4b` 未闭合 ⇒ `68.4i` 不升级 ⇒ `§47.2 W9` 不打勾」；`:9642` 明写「`68.4b` / `68.4i` 与 `§47.2 W9` 保持未勾」 | **实施完成度 ≠ 台账复选框已勾**（复选框只控制器能打，`AGENTS.md` R5）。上游「闭环中」= 实施侧；台账侧 = 复选框侧 | 本环登记「复选框仍未勾 + 归属并发控制器」，**不代勾**（§2 归属澄清） |
| D3 | 未提及 | `relay.json` `plan_doc` = `docs\开发计划.md`，但该文件**无任何未勾复选框**（非 Task 级真源，`AGENTS.md` §6 明定真源为 `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`）；且 `docs\开发计划.md` 在 `concurrency.forbidden_this_round` 禁写清单内 | **指针失效**，且该文件不可改 | 本环只登记（§1.4），**不改字段、不改文件**；第 2 环 scope 内写真源路径 |
| D4 | 未提及 | `relay.json` `concurrency.forbidden_this_round` = `AGENTS.md` / `handoff.md` / `docs\P1_进度.md` / `docs\B1_验收记录.md` / `docs\开发计划.md` | 本环写集与之**无交集**（本环只写 `docs\relay\stage-1-inventory.md` + `docs\relay.json`） | 本环零越界；§5 已注明「台账正被并发更新」 |

---

## 5. 本环 git status 计数变化说明（证明只读）

### 5.1 写前基线（本环开工时，实测）

`git status --porcelain` = **17 行**；`HEAD=01b6339`；`AHEAD=0`；`BEHIND=0`。
17 行逐条（路径 | 字节 | mtime | sha16 前 16 位）：

| 路径 | 字节 | mtime | sha16 |
|---|---|---|---|
| `AGENTS.md` | 279490 | 2026-11-24 21:33:28 | `9E529458B40F16A9` |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 78463 | 2026-11-24 21:18:21 | `760A8E990F4ED618` |
| `apps/desktop/lib/src/l10n/parts/common.dart` | 4694 | 2026-11-24 21:11:22 | `31DF49E483ECE52D` |
| `apps/desktop/lib/src/l10n/parts/domain.dart` | 14288 | 2026-11-24 21:17:35 | `AE8095A54C113188` |
| `apps/desktop/lib/src/l10n/parts/projects.dart` | 10158 | 2026-11-24 21:11:45 | `19BCB8A951B2DB31` |
| `apps/desktop/lib/src/l10n/parts/settings.dart` | 7730 | 2026-11-24 21:11:32 | `D4FA71A3205E617A` |
| `apps/desktop/lib/src/widgets/recurring_rail_panel.dart` | 15078 | 2026-11-24 21:10:51 | `83D3C376996B6468` |
| `apps/desktop/lib/src/widgets/recurring_task_dialog.dart` | 21129 | 2026-11-24 20:54:23 | `D24FB0C10135AD12` |
| `apps/desktop/test/l10n_base_test.dart` | 28982 | 2026-11-24 21:17:39 | `4193D08894BCB9E1` |
| `apps/desktop/test/l10n_harness.dart` | 36066 | 2026-11-24 21:17:38 | `D679E85EBD744FB0` |
| `apps/desktop/test/recurring_task_test.dart` | 22853 | 2026-11-24 20:51:30 | `5A4A0B69B677F2A4` |
| `docs/superpowers/plans/2026-11-07-b1-flutter-implementation.md` | 679445 | 2026-11-24 21:09:41 | `205BAD2B76088912` |
| `packages/core_domain/lib/src/recurring_task.dart` | 5183 | 2026-11-24 20:50:47 | `270A2BC9C4982EF1` |
| `packages/core_domain/test/recurring_task_test.dart` | 4504 | 2026-11-24 20:50:49 | `C41BF5D3C7100013` |
| `docs/AGENT-RELAY.md` | 8564 | 2026-11-24 20:53:16 | `32E909343AFEB9B0` |
| `docs/RELAY-ADAPTATION.md` | 10233 | 2026-11-24 21:31:17 | `5B68216D40BC84C0` |
| `docs/relay.json` | 4232 | 2026-11-24 21:33:28 | `73F9EDA03A6E2BAF` |

### 5.2 写后计数（收尾时实测，本节以下为收尾回写时复测值）

- `git status --porcelain` = **18 行**（17 → 18，**净 +1**）；
- 净增的唯一一行 = `?? docs/relay/`（git 把未跟踪目录折叠为一行；内含本环新建的 `stage-1-inventory.md`，38,408 B）；
- `docs/relay.json` 仍为 `??`（未跟踪）1 行 ⇒ 计数不增，但**内容被本环按硬规则第 3 条只追加回写**（4232 B → **9111 B / sha16 `935666E934984A84` / mtime 21:43:56**）。

### 5.3 计数变化结论

| 项 | 写前 | 写后 | 判定 |
|---|---|---|---|
| `git status --porcelain` 行数 | 17 | 18 | 净 +1 = 本环新建的 1 个文件 |
| 新增行内容 | — | `?? docs/relay/stage-1-inventory.md` | **唯一**新增路径，且属本环声明写集 |
| 既有 17 行的内容改动 | — | **2 条变化，其中 1 条非本环所为**（见下表） | 本环**只改** `docs\relay.json`（声明写集内） |
| `HEAD` / `AHEAD` / `BEHIND` | `01b6339` / 0 / 0 | `01b6339` / 0 / 0 | 本环**未 commit**（commit 属人工验收点） |

**逐条指纹比对结论（写前 17 条 → 写后实测）**：

| 路径 | 写前 字节 / sha16 / mtime | 写后 字节 / sha16 / mtime | 变化来源 |
|---|---|---|---|
| 其余 15 条（`AGENTS.md`、8 个 `apps\desktop\**`、计划文件、2 个 `packages\core_domain\**`、`docs\AGENT-RELAY.md`） | 见 §5.1 | **逐字一致** | 无变化 |
| `docs\RELAY-ADAPTATION.md` | 10233 / `5B68216D40BC84C0` / 21:31:17 | **11364 / `4C592024964D6E8E` / 21:42:45** | **并发**：root 会话扩充 §5.5「开工副本必然过期」条款；**非本环所写**（不在本环写集内，也不在 `concurrency.forbidden_this_round` 内） |
| `docs\relay.json` | 4232 / `73F9EDA03A6E2BAF` / 21:33:28 | **9111 / `935666E934984A84` / 21:43:56** | **本环**按 `AGENTS.md` 硬规则第 3 条只追加回写（声明写集内） |

**本环未修改任何「声明写集以外」的既有文件**；唯一的自发改动 = `docs\relay.json`，且回写前已按 `RELAY-ADAPTATION.md` §5.5 重新读盘、在最新字节上定点替换，**未用开工时的内存副本整文件覆写**。
**并发注记（上游 21:42 约束 B 的落地）**：并发 Task 68 会话同期在写 `apps\**` / `packages\**` / 计划文件 / `AGENTS.md` / `handoff.md` / `docs\P1_进度.md` / `docs\B1_验收记录.md` / `docs\开发计划.md`（后者五个即 `relay.json` `concurrency.forbidden_this_round` 禁写清单）。
⇒ 本环对这些文件**只读**；**若其 mtime / 指纹在盘点期间变化，属正常并发更新，不得判为异常、更不得去改它们**。
⇒ 本环实测到的唯一「盘点期间被他人改动」的文件 = `docs\relay.json`（上游 root 会话 21:42 追加顶层字段）：**4232 B / sha16 `73F9EDA03A6E2BAF` / mtime 21:33:28 → 6185 B / sha16 `BE946104D4EF3B28` / mtime 21:42:05**。
　本环因此**在回写前重新读盘**，在最新内容上做定点替换，**未使用开工时的内存副本整文件覆写**（避免抹掉 `concurrency` / `next_stage_target`），并在回写后校验这两个顶层字段仍在（见 §8 第 9 条）。

---

## 6. 已验证 / 推断 / 未验证（三档登记）

### 6.1 已验证（本环亲测，原始输出在 §3）

| 结论 | 证据 |
|---|---|
| 四包 analyze 逐字 `No issues found!`，退出码 0 | 本环亲跑（§3.2） |
| 并发门禁唯一失败项 = `OUT_OF_SET=3`，其余全绿 | `reports\task68-gate-run1.log`（§3.3） |
| `OUT_OF_SET=3` 精确对应 3 个接力链自建 docs 文件 | 门禁脚本 `:300`–`:309` + 日志 `STATUS_PATHS:` 段（§3.4） |
| `docs\relay\*.md` 不在任何白名单 pattern 内 | 门禁脚本 docs pattern 仅 `:195/:196/:198/:283/:284` 五条（§3.4） |
| 最近未闭环批次 = §68.4a–i + §47.2 W9 | 计划 `:8326` / `:9611`–`:9619` / `:9628`–`:9642` 逐字（§1.2） |
| `docs\开发计划.md` 无任何未勾复选框、非 Task 级真源 | grep 零命中 + mtime `2026-11-06 22:57:12`（§1.4） |
| 本环写前工作树 = 17 行，`HEAD=01b6339`，`AHEAD=0` / `BEHIND=0` | 本环亲跑（§5.1） |
| 5 个并发会话 id / 角色 / 状态 | `mavis session list` 实测（§2） |

### 6.2 推断（有证据支撑但非本环亲测）

| 结论 | 依据 | 风险 |
|---|---|---|
| 本环写入后 `OUT_OF_SET` 将由 3 变 4、`STATUS_LINES` 由 17 变 18 | 白名单判定逻辑 + §5.1 基线 | 并发控制器若先追加白名单则不发生；属**可预期**而非实测 |
| 68.4c / 68.4f 的实施已完成，只差台账打勾 | worker 报告 `reports\task68-deadkey-cleanup.md` / `task68-weekday.md` | 复选框只控制器能打（R5），本环不代打 |
| 68.4d 的基线真值为 desktop 836 | `task68-gate-run1.log` `DESKTOP_TESTS=836` / `DESKTOP_EXPECTED=836` | `AGENTS.md` §7 现记 834（Task 63 轮），需控制器更新 |

### 6.3 未验证 / 未判定（如实登记，不得当作已修或已绿）

| 项 | 原因 |
|---|---|
| **全量 `flutter test` 本环未亲跑** | 836 / 204 / 71 / 62 四个计数取自并发会话门禁原始输出，非本环实测；本环只亲跑 analyze |
| **真机 / 打包验收未做** | 无写集（`tools\build\make_installer.ps1` 产物与 `release\` 分发属人工验收点）；本机锁屏风险 |
| **68.4b 的 6 条诊断串是否上屏** | `lib\src\data\project_store.dart` 6 条是否经 toast 上屏（若上屏则 521 → 527）—— worker B 盲区 |
| **`toast_probe.dart:111` 在发布构建的可达性** | worker B 盲区，未实测 |
| **「英文态可见」为静态推断，未真机英文态逐条截图** | plan `:9641` 明写；真机取帧受锁屏与影刀虚拟桌面双重风险约束 |
| **68.4g verifier 终判** | 会话 `mvs_33a179b2de0a435e94c52f2d17291c37` status=started，终判未出 |
| **68.4h commit + push** | 命中人工验收点（git commit / push），本链不执行 |

---

## 7. 被压制的通用协议条款登记（`docs\RELAY-ADAPTATION.md` §1 裁决）

`docs\AGENT-RELAY.md`（通用协议）中与 `AGENTS.md` / `RELAY-ADAPTATION.md` 抵触、本环**不适用**的条款：

| 通用协议条款 | 抵触对象 | 本环处置 |
|---|---|---|
| `AGENT-RELAY.md` §4 通用 prompt 模板（含第 5 步「回执条款」要求向发起方回执） | `AGENTS.md`「自动接力（Relay）—— 硬规则」第 3 条（本环只追加回写 `relay.json` + 起下一环，不含通用回执格式）；`RELAY-ADAPTATION.md` §2 / §3 / §5 / §9 | **不适用**：本环不套用通用 prompt 模板与回执格式，改为按项目硬规则执行 |
| `AGENT-RELAY.md` §2「结论落盘 `docs/handoff-*.md`」 | `RELAY-ADAPTATION.md` §2（收紧为「本环交付文档 + `relay.json` 追加」） | **收紧适用**：本环结论落盘 `docs\relay\stage-1-inventory.md`，**不新建** `docs\handoff-*.md`（避免与并发会话的 `handoff.md` 抢写集） |
| `AGENT-RELAY.md` 关于「自动选择模型 / 自动降级」的一般表述 | `RELAY-ADAPTATION.md` §9 模型策略（优先 `minimax/MiniMax-M3` + effort `on`，百炼侧一律不传 effort，同一跳最多降级一次并回写实际 model） | **以 §9 为准**（见 §8 第 3 条） |

---

## 8. 证据路径索引

1. 台账真源计划：`docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`（`:8326` / `:8527` / `:9437`–`:9441` / `:9605`–`:9642`）
2. 家规：`AGENTS.md`（`:175`–`:213` §3 装置地图；`:400`+ §7 快照；`:485`–`:494` 接力硬规则）
3. 接力状态机：`docs\relay.json`；项目裁决：`docs\RELAY-ADAPTATION.md`；通用协议：`docs\AGENT-RELAY.md`
4. 并发门禁原始输出：`reports\task68-gate-run1.log`（`RUN_AT=2026-11-24 21:35:39`）
5. 门禁脚本：`reports\task51-gate.ps1`（`:3`–`:10` 用法；`:16`–`:28` 缓存挪移 + 镜像；`:112`–`:298` 白名单；`:300`–`:329` `OUT_OF_SET` 判定；`:311`–`:316` 期望计数）
6. 并发 worker 报告：`reports\task68-weekday.md`（worker A 域层工作日）、`reports\task68-deadkey-cleanup.md`（worker C 死 key 清理）、`reports\task68-deadkey-scan.md`（worker B 死 key + 中文扫描）
7. 本环交付文档：`docs\relay\stage-1-inventory.md`（本文件）
8. **`docs\relay.json` 回写校验记录（2026-11-24 21:43:56 回写后实测回读）**：`JSON_PARSE=OK` / `status=running` / `current_stage=2` / `max_stages=6` / `stages_count=2`（stage1=`done` + `session_id=mvs_f0f4b5b2d4804d3fabd8f23d1e35544c` + `model=minimax/MiniMax-M3` + `tool_calls=53` + `finished_at=2026-11-24T21:43:42+08:00`；stage2=`pending` + `handoff=docs\relay\stage-2-scope.md`）/ `sessions_count=2`（未删改既有条目）。
   **relay.json 顶层字段保留 OK** —— 顶层 20 个 key 全部在位：`concurrency`（`forbidden_this_round` 5 条、`by_session=mvs_e395774e42a84ff9a218fcb0b7349f98`）/ `next_stage_target` / `model_policy`（`preferred=minimax/MiniMax-M3`）/ `human_checkpoints` 7 条 / `stop_conditions` 5 条 / `ledger_docs` 4 条 / `goal` / `plan_doc` / `protocol` 等均未被抹掉；回写后 `relay.json` = **9111 B / sha16 `935666E934984A84`**。
9. 台账真源指针失效登记：`docs\relay.json` 的 `plan_doc` = `docs\开发计划.md`（非 Task 级真源，且在 `concurrency.forbidden_this_round` 内）—— 见 §1.4 与 §4.5 D3。
10. 写集命名口径说明：`RELAY-ADAPTATION.md` §3 表格写的盘点环路径是 `docs\relay-stage-<N>-inventory.md`，而 `relay.json` 的 `stages[0].scope` / `handoff` 明确写 `docs\relay\stage-1-inventory.md`。按裁决顺序（`relay.json` 状态机第 3 位 > 通用协议第 4 位），针对具体 stage 的具体 scope 从 `relay.json` 读，本环按 `docs\relay\stage-1-inventory.md` 执行，第 2 环沿用同族路径 `docs\relay\stage-2-scope.md`。
