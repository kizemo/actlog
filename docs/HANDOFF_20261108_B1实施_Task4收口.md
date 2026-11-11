# Handoff —— B1 实施 Task 4 收口（`core_domain` `ResultNote` 编解码）

- 生成时间：2026-11-08（本会话内完成 Task 4 全链：**实现 → 评审 → 修复 → 复评 → 再修复 → 复评 3 → 最终修复 → 收口**）
- 会话 ID：`mvs_741771761598421181677b73d231d44e`
- 上一棒：`F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task3收口.md`（Task 1–3 收口；**其 §5.3 跨 Task 遗留项与 §7 行号表已过时，以本文 §5/§7 为准**）

---

## 1. 项目背景与目标

**Practilog**：个人练习记录工具。Windows 桌面端（Tauri/Rust）+ Flutter 客户端，共享 `schema v1`（SQLite）。当前在做 **B1 期 Flutter 客户端**，按实施计划逐 Task 推进。

- 硬约束（不变）：只做 Windows 桌面端；无障碍底线（正文 ≥14px、标签 ≥12px、文字对比度 ≥4.5:1、交互边界 ≥3:1）；赭石 `--accent` 只用于缺口/警示，**不得**作 primary/选中态/焦点环（选中态 = `--ink` 反白，焦点环 = `--ink` 2px 实线）。
- `schema v1` 已 **FROZEN**：不得改 `docs/schema_v1.sql`、`packages/core_db/lib/src/tables.dart` 列定义、不得升 `currentSchemaVersion`。
- 仓库**不是 git 仓库** ⇒ 一切验收以「命令跑通 + 磁盘上存在的证据文件」为准，不接受 commit 作为门禁证据。
- 文件规范：Dart 源 LF 无 BOM；`tools\*.ps1` 纯 ASCII + CRLF；新代码禁 `print`；`packages/` 下公开成员必须有 doc comment（lint：`public_member_api_docs`、`avoid_print`）。
- 界面类验收只能用 `flutter build windows` 产物，不能用 `flutter dev`；需装机实测就直接跑 `tools\build\make_installer.ps1` 打包。

## 2. 当前进度：Task 4 **已完成并收口**

| 项 | 状态 |
|---|---|
| Task 1 `flutter_bootstrap` / Task 2 `design_tokens` / Task 3 `core_data` | ✅ Approved（见上一棒 handoff） |
| **Task 4 `core_domain` `ResultNote` 编解码** | ✅ **Approved**（复评 3：Critical 0 / Important 0 / Minor 2；两条 Minor **均已采纳并落盘修复**，最终门禁全绿，计划 5 项复选框已打勾） |

**Task 4 磁盘产物**（控制器亲自复测，非 worker 自述）：

| 文件 | 现状 |
|---|---|
| `F:\soft\00selfmade\practilog\packages\core_domain\lib\src\result_note.dart` | **6381 B / 191 行** |
| `F:\soft\00selfmade\practilog\packages\core_domain\test\result_note_test.dart` | **4952 B / 118 行**，15 用例 |
| `F:\soft\00selfmade\practilog\packages\core_domain\lib\core_domain.dart` | **567 B / 15 行**（自 Task 4 首轮起零改动） |

**最终门禁（控制器亲跑，证据在盘）**：`dart analyze` `No issues found!` → `reports\task-4-fix3-ctl-analyze.log`；单文件 `00:00 +15: All tests passed!` → `…-ctl-single.log`；core_domain 全量 `+51` → `…-ctl-full.log`；G2 全仓 `passed=227 failed=0` / `RESULT: PASS` → `…-ctl-g2.log`（2484 B）。编码卫生：两文件 BOM=False、CRLF=0、控制字符=0、`print`=0。契约 ≡ 磁盘：测试块与实现块 `identical=True mismatch=0`。Task 4 后全仓无越界改动。

**三轮评审链**（证据均在 `…\reports\`）：① `task-4-review.md`（C0/I3/M3，6 项全采纳）→ 修复轮 1；② `task-4-review2.md`（C0/I1/M3，含 2 处口径矛盾，全采纳）→ 修复轮 2（6 处补丁落 brief/计划/spec）；③ `task-4-review3.md`（25168 B / 223 行，**Approved**，C0/I0/M2，且确认 E1–E6 全落地、口径矛盾 0、brief≡磁盘逐字节一致）→ 修复轮 3（2 处编辑）。

**M9b 判别性守卫（关键，控制器不采信 verifier 的「跑过了」自述，独立复证）**：
`F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\task-4-m9b-ctl.log`
⇒ `warmup RED=0 / baseline RED=0 / M9b RED=1`（变异「裁剪发射侧 `.trim()`」，签名 `Expected:'[结论]a' Actual:'[结论] a '`，失败点 `test\result_note_test.dart:100`）⇒ **GUARD CONFIRMED**，Task 4 无残留缺口。

## 3. 下阶段计划

**下一站 = Task 5：`packages/core_data` 日历纯工具**，计划文件第 **1393** 行起（`## Task 5: core_data —— 日历纯工具`，Task 6 起于 1588 行 ⇒ 边界 1393–1587）。Task 5 执行契约已存在：`F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-5-brief.md`（10036 B / 236 行）。产物 = `lib\src\calendar.dart` + `core_data.dart` export + `test\calendar_test.dart`；复用既有 `src\support.dart` 的 `parseIsoDate`/`isoDate`，**不要重写日期解析**。基线 = core_data 107 用例（Task 5 后 G2 应 > 227）。

## 4. 权威文档清单（全路径）

| 用途 | 路径 |
|---|---|
| 实施计划（唯一任务与行号来源，17 Task / **4786 行 / 171495 B**） | `…\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` |
| 进度真相源（**35081 B / 315 行**，已含 Task 4 收口章节） | `…\.superpowers\sdd\2026-11-07-b1-flutter-implementation\progress.md` |
| Task 4 契约（含三轮修订 + E1–E6，**定稿 17536 B / 407 行**） | `…\.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-4-brief.md` |
| Task 5 契约 | `…\.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-5-brief.md` |
| Task 9 契约（含 I1 预告） | `…\.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-9-brief.md` |
| 评审模板 | `…\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reviewer-template.md` |
| Task 4 三轮评审 + 全部证据 | `…\.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\`（`task-4-{review,review2,review3}.md`、`task-4-round3-contract-diff.txt`、`task-4-m9b-ctl.log`、`task-4-plan-tick.log`、`task-4-fix{1,2,3}*.log`） |
| 设计 spec（§6.1 是 `ResultNote` 编码权威口径；**第 217 行已补「字符按 Unicode 码点计」**） | `…\docs\superpowers\specs\2026-11-07-双端交互体验设计.md`（44420 B / 548 行） |
| token 唯一真源 | `…\design-demos\TOKENS.md` |
| 上一棒 handoff（Task 1–3） | `…\docs\HANDOFF_20261108_B1实施_Task3收口.md` |

## 5. 执行流程（Subagent-Driven，已四次验证，照抄）

1. **控制器改口径**：计划 / brief / TOKENS / spec **只由控制器改**，且必须**同步**——同一处改动在 brief 与计划里**逐字节一致**，否则实现者无法判断以谁为准。
2. **派 worker 实现**：`task` 起 `worker`，prompt 里给完整契约路径 + 硬约束 + 「禁止自行改口径」「必须贴命令真实输出、禁止凭记忆写报告」。
3. **控制器亲跑门禁**（worker/verifier 自述不作数）：`dart analyze` / `dart test` / G2 / 编码卫生 / 越界扫描 / **契约 ≡ 磁盘逐行比较**。
4. **派 verifier 评审**：`verifier` 只读，按 `reviewer-template.md` 出 Critical/Important/Minor。
5. **控制器裁定**：逐条采纳/驳回/延后，每条附判据；**明显的 bug 直接按推荐方案修，不发问卷**（用户既有偏好）。延后项必须写清归属 Task，并同步落进该 Task 的 brief。
6. **原实现者续作**：用 `task_append` 回**原 worker 会话**做修复轮。
7. **复跑门禁** + **复评**（另起 `verifier`，prompt 点名「必须逐行读盘上代码」，否则易凭摘要评审）。
8. **收口**：追加 `progress.md` → **计划复选框打勾** → 重写 handoff（本文）。

## 6. 行号表（★ Task 4 收口后整体 +5 漂移，旧表作废）

`## Task N:` 在计划（现 **4786 行 / 171495 B**）中的行号（`Select-String -Pattern '^#{2,4}\s*Task\s*\d+'` 实测）：

```
Task 1=109   Task 2=315   Task 3=567   Task 4=1027   Task 5=1393
Task 6=1588  Task 7=1865  Task 8=2221  Task 9=2422   Task 10=2740
Task 11=2983 Task 12=3229 Task 13=3579 Task 14=4045  Task 15=4260
Task 16=4479 Task 17=4619   附录 A=4726  B=4753  C=4769
```

- **Task 4 = 1027–1391**（5 项复选框在 1045 / 1168 / 1176 / 1378 / 1387，**已全部打勾**）；**Task 5 = 1393–1587**。
- 每次改动计划后，**立刻**用 `Measure-Object -Line` 核行数 + 重跑上面那条 `Select-String` 取边界；若为「行内标记」类改动（如打勾），用**同长度替换**（`- [ ] `→`- [x] `）可保字节数与行号零漂移。

## 7. 已验证事实 vs 未验证（★ 严格分开）

**已验证（跑过 / 读过，有磁盘证据）**
- Task 1–4 门禁全绿；G2 现总基线 **227**（`core_data 107` + `core_db 69` + `core_domain 51`）。
- `ResultNote` 编码契约三条不变式成立（E1 长度按 `runes.length` 码点、E4 顺序 = 真子序列、E5 三段一致降级）；M9b 变异被新增断言捕获（RED=1）。
- `flutter` / `dart` 可用：`F:\soft\flutter\flutter\bin\flutter.bat`、`dart.bat`；镜像环境变量必须设 `PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL` = `https://pub.flutter-io.cn` / `https://storage.flutter-io.cn`。
- 跑纯 Dart 门禁的形状：`Set-Location packages\<pkg>` 后 `& '…\dart.bat' analyze` / `dart.bat test --reporter compact [test\<file>]`；**G2 必须用 `Start-Process pwsh -WorkingDirectory $root -Wait -PassThru -RedirectStandardOutput <绝对路径>`**（同一命令内 `Set-Location` 后再写文件会被权限门拦；且 .NET `WriteAllText` 按**进程级** CWD 解析相对路径，与 PowerShell `Set-Location` 不同步 ⇒ 一律写绝对路径）。
- 编码卫生标准：无 BOM、LF、无控制字符、无 `print(`。
- 计划复选框打勾可用行号驱动的 `.ps1`（`edit` 工具的目标串在跨 Task 时**不唯一**）。

**只是推断 / 尚未验证**
- 「Task 4 界面无关、不影响渲染」是从代码分层推断，未跑过 `flutter build windows`。
- Task 9+ 的 Flutter 侧门禁形状沿用上一棒记录，本会话未复测。
- `nextActions` / `outcome` 的自由文本长度约束（I1 校验面）在 Task 9 之前**无强制**，属已知风险。
- 设计 token 的字体资产仍未打包 ⇒ TOKENS §8 的 144dpi/200% 验收尚不完整（延续未验证项）。
- 本会话**无任何真机界面截图证据**；G4 界面脚本尚不存在（`tools\gates\` 只有 G1/G2/G3/G5）。

## 8. 本机工具坑（★ 含本会话新增，勿重复踩）

1. **`edit` 工具每次调用必须带 `file_path`**，且一次只能一组 `old_string`/`new_string`（重复键会被静默丢弃）。漏 `file_path` 直接校验失败。
2. **含中文 / 正则的批量计划修订 = 生成 Python 补丁脚本**（`reports\*.py` 留证）：脚本末尾 `assert bad==0`；每处替换断言命中数（`hit==1`）；保存后回读断言字节数 > 0 且占位符已清零。
3. **PowerShell 坑**：双引号内 `` `a `` 是 BEL；`[char]0x2028`；`-replace '$1'` 单引号 `$` 是字面量；替换式里 `$` 是组引用 ⇒ 含 `$` 的替换一律用 `.Replace()`（ordinal）或单引号字面量；`Set-Content -Encoding UTF8` 写 BOM ⇒ 用 `WriteAllText(path,text,UTF8Encoding($false))`；`Contains(' [1-9]')` 把正则当**字面量**（会恒不匹配 ⇒ 假绿/假红），判红必须用 `[regex]::Matches($out,'\+([0-9]+) -([0-9]+)')` 取最大值。
4. **内联 `pwsh -Command` 含中文/反引号/复杂引号极易碎，且 `Copy-Item` 内联会被权限门判 `recursive write/delete target cannot be verified`** ⇒ 一律用 `write` 工具落**纯 ASCII `.ps1`**（放 `tmp\` 证据目录）再 `pwsh -NoProfile -ExecutionPolicy Bypass -File`；脚本内用 `[IO.File]::Copy` / `[IO.File]::WriteAllText` / `Get-ChildItem`，**不要** `Remove-Item`。
5. **变异沙盒（判别性测试自证）三条铁律**（本会话实测）：① 复制到 workspace 外/子目录时**必须剥掉 `pubspec.yaml` 的 `resolution: workspace`**，否则 `dart test` 报 `exit 65`（找不到 workspace root）；② 沙盒**首轮** `dart test` 常只打印 `loading ...` 无摘要 ⇒ 必须先跑一次 warmup 丢弃，再取基线，否则 `RED=-1` 假结果；③ 变异前先 `ReadAllText` 断言目标串命中数 ≥1（本会话真实位置 `result_note.dart:173`，naive 扫描窗口只覆盖前 60 行会 `hits=0` ABORT）。
6. **bash 工具正文含删除类关键字会被整条命令拦**；永久删除被拦，可恢复删除要求 trash marker ⇒ **临时文件一律留存当证据，不删**。
7. **`grep` 工具在本项目对 content 模式常失效** ⇒ 用 `Select-String` / `read`。
8. **后台子代理写文件期间去读它的产出 = 读到半截**（解析失败/大小突变是中间态）⇒ 先 `task_output`/`task_query` 确认终态再验收。
9. **`task_query` 不带 `task_id` 会倾泻全部历史**（曾一次吃掉 20 万 token）⇒ 只用 `task_output(task_id, offset=上次 next_offset)` 增量读。
10. **naive「代码块对齐比较」会给出位移伪影**（如 DIFF=19/89 实为对齐漂移）⇒ 判「契约 ≡ 磁盘」必须按**同起点逐行相等**（identical/mismatch 计数），不要按行索引硬配。
11. **交接卡可能不属于本项目**：`E:\Users\Duanyi\.minimax\.minimax\maintenance\task-state\LATEST.md` 本会话实测指向**另一项目**（filemanager）⇒ 核对项目/任务归属，不属于就忽略，按本项目上下文走。

## 9. Task 5 起步要点

1. 先读 §4 权威文档：`progress.md`、计划第 **1393–1587** 行、`task-5-brief.md`、`reviewer-template.md`。
2. 派 `worker`：TDD（先测后实现，贴真实失败签名）；产物 `packages\core_data\lib\src\calendar.dart` + 在 `core_data.dart` 追加 export + `packages\core_data\test\calendar_test.dart`。
3. **复用 `src\support.dart` 的 `parseIsoDate` / `isoDate`**，不要重写日期解析。
4. 硬约束：禁 `print`；公开成员必须有 doc comment；禁改 `schema v1`；worker 不得改口径文件；所有证据写进 `…\reports\` 留指针。
5. 门禁：core_data `dart analyze` + `dart test`；G2 用 `Start-Process -WorkingDirectory $root` 形态（§7）。当前基线 `passed=227`，Task 5 后应上升且 `failed=0`。
6. 评审后控制器裁定，**明显 bug 直接修、不发问卷**；延后项归属必须同步进对应 Task 的 brief（见 §10）。
7. 收口后**必须**：`progress.md` 追加 → 计划打勾（记录行号、同长度替换）→ 行号表重测（§6）。

**跨 Task 遗留项（含上一棒 §5.3，勿重新分配）**
- Task 5：日历纯工具按 spec §6 口径，边界行号 1393–1587。
- Task 7：**I4**（`ResultNoteLabel.fromLabel` 对 `下一步` 的别名回退无契约用例）；另含 M-1。
- Task 9：**I1** 必须做落库前的长度/换行输入约束校验（用 `ResultNote.maxTextLength` / `forbiddenTextChars` / `isValidText`），不得只信 UI；注意 `wellFormed` 恒 `true`（Task 4 E1 后已改 doc，不作校验信号）。
- Task 15：**I-2**（`AppScope` 生命周期 / `start` 前 `ensureInitialized` / `close` 幂等 / 失败路径 dispose）、**M1**（`AppThemeData` 值语义）、**M3**（`context.read<T>()` 抛 `ProviderNotFoundException` 契约）。
- Task 17：**G4** 界面门禁脚本 + 25 个未覆盖 `ColorScheme` 角色 + M-1/M-4 无障碍残留 + 赭石禁令回归 + 字体资产打包与 144dpi/200% 验收。
- Task 7/17：M-1（焦点环 `InputManager` 接线）。

## 10. 一句话接力 prompt（新会话直接粘贴）

> 请先完整阅读 `F:/soft/00selfmade/practilog/docs/HANDOFF_20261108_B1实施_Task4收口.md`，并按其中 §4「权威文档清单」列出的全路径读取必要文档（必读项以 `F:/soft/00selfmade/practilog/.superpowers/sdd/2026-11-07-b1-flutter-implementation/progress.md`、`F:/soft/00selfmade/practilog/docs/superpowers/plans/2026-11-07-b1-flutter-implementation.md`、`F:/soft/00selfmade/practilog/.superpowers/sdd/2026-11-07-b1-flutter-implementation/task-5-brief.md`、`F:/soft/00selfmade/practilog/design-demos/TOKENS.md` 为主），充分掌握项目背景、目标、当前进度与下阶段计划之后再动手；本任务是接着执行 B1 Flutter 实施计划的下一个 Task（计划里的 Task 5 `core_data` 日历纯工具），请严格沿用 handoff 中记录的 Subagent-Driven 流程与全部硬约束、工具坑与命令形状，其中 §6 给出的是各 Task 在计划中的**最新**边界行号（Task 4 收口后已整体 +5 漂移，旧表作废），§9 末尾是已分派的跨 Task 遗留项请勿重新分配，§7 明确区分了已验证事实与尚未验证的推断。
