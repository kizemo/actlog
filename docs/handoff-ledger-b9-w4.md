# B9-W4 收口台账 · 真机取证 + 门禁 + 出包

> 性质：B9 批次的**最终收口台账**。本文件是控制器（root）写集，worker 不得改。
> 开工时本文件只含「前置核实」与「待填」骨架；W4 实际跑完后逐节回填**盘上回读值**。
> 权威优先级：用户当轮决定 > 派工书 > 计划正文 > 本文件 > README；证据冲突时 实测 > 运行时产物 > 源码 > 文档转述。

---

## 0. 前置核实（控制器盘上实测，2026-11-25 夜）

| 项 | 实测值 | 判读 |
|---|---|---|
| R3 唯一可分发安装包 | `release\actlog-Setup-1.0.0_20261125-222947.exe` / **22,817,510 B** / sha16 **`8D9FE856CD7E882A`** | 与 AGENTS.md §7 记录一致；**本批出包后必须重测 sha16 判是否重编（坑 108：不许比字节数）** |
| `release\` 下 exe 总数 | 57 | 其余 56 个**严禁分发** |
| 当前 Release 构建树 | `apps\desktop\build\windows\x64\runner\Release\actlog.exe` / **484,352 B** / mtime **2026-11-20 22:10:55** | **已过期**：不含 B8 与 B9 W1–W3 任何改动 ⇒ W4 **必须先重编**，不能直接打包 |
| `tools\build\make_installer.ps1` 是否负责构建 | **否**。脚本头注释与日志双处明写：`This script never runs flutter/dart: the release payload must already exist.` / `always packages the existing release tree` | W4 顺序固定为 **① `flutter build windows --release` → ② `make_installer.ps1`**，顺序颠倒会打出旧 payload |
| makensis 日志真落点 | **`.superpowers\makensis_out.txt`**（1,621 B / 22:30:18）+ **`.superpowers\installer_build_report.txt`**（1,559 B / 22:30:18）；脚本 L31 `$reportDir = Join-Path $root '.superpowers'`、L32/L33 拼名。`reports\` 下两者实测 **MISS** | 误记的「改正为 `reports\`」是错的，已回退 ⇒ **AGENTS §5 坑 107 原本的 `.superpowers\` 记法正确** |
| 真机取证种子库 | `reports\task72-seeddb\` 存在（`actlog.db` 417,792 B + `-wal` 1,429,672 B + `-shm` + `actlog_startup.log`） | **摘要里写的 `reports\task78-seeddb` 不存在**。W4 用 `task72-seeddb`（用户活库零写入） |
| 读回脚本 | `reports\task72_readback.py`、`reports\task77-goal-dump.py` 均存在 | `task77-goal-dump.py:4` **硬编码** `DB = ...\reports\task72-seeddb\actlog.db` ⇒ 直接对同一脏库读回即可，勿另造副本 |
| 被测件 | 构建树 `actlog.exe --data-dir=<绝对路径>` | 参数形状沿用 B8；不得指向用户真实 data dir |

---

## 1. W1 / W2 已收口数据（盘上回读，已复核）

| 棒次 | commit | 文件数 | 结果 |
|---|---|---|---|
| W1 个人品牌管理模块 | `0df939d` | 7 文件 +1611/−5 | analyze 逐字 `No issues found!`；全量 `+927` ⇒ N1 = 7；l10n `576 / 576 / 633` |
| W2 矩阵四标签页 + 单元格操作 | `0f123b6` | 8 文件 +984/−639 | analyze 逐字 `No issues found!`；全量 `+936` ⇒ N2 = 9；l10n `575 / 575 / 632` |

- W2 契约落地点：`goal-blueprint-tab-<horizonKey>`、`goal-blueprint-add-<domain>-<horizon>`（右下角）、铅笔 `Icons.edit_outlined`、拆分 `Icons.call_split`、矩阵去段头。
- W2 四删键在 `lib` 内 `git grep` 均 0 命中：`goalBlueprintEmptyCell` / `goalBlueprintMatrixSection` / `goalBlueprintNearSource` / `goalBlueprintSplitTodos`。

---

## 2. W3 四级拆分链路（已交付，控制器盘上复核）

| 项 | 期望 | 实测 |
|---|---|---|
| commit | — | **`58ff59d`**（sha16 **`58ff59d63dd2436c`**），未 push |
| 文件数 / 行数 | 写集 9 文件 | **9 文件 +1057/−160**（7 M + 2 A：新增 `goal_split_dialog.dart` +294、`task79_b9_split_chain_test.dart` +482） |
| analyze | 逐字 `No issues found!` | worker 自跑 `No issues found! (ran in 5.2s)`；控制器独立复跑见 §3 |
| desktop 全量 | `936 + N3`，`N3 ≥ 8` | **`946`**（N3 = **10**），worker 报 `01:29 +946: All tests passed!` |
| l10n | `585 / 585 / 642` | **`585 / 585 / 642`**（`l10n_base_test.dart` L28/L29/L114 盘上三处逐一回读一致） |
| 旧 pending 链路 | `_pending` / `_addSplit` / `_confirmTodos` / 区块 / 2 l10n 键 / 5 ValueKey **全部消失** | 全库 `git grep` 旧键 = **0 命中**（`old_hits=0`） |
| 写集越界 | `packages/**` / `docs/**` / `reports/**` 零改动 | `git show --name-status 58ff59d` = 恰好 9 文件；`git status --porcelain -- apps packages` = 0 行 |
| 卫生 | 无 BOM / CR=0 / `print(` = 0 | 9 文件全清（`bom=False` / `cr=0` / `print=0`） |
| 落库双证 | 行 + 链接（serves / tracks）；年目标 `period_start` 精确等值 | 单测 10 例覆盖映射；**真机运行时双证见 §5（受前台限制，独立判定）** |

W3 页面接线锚点（盘上回读）：`:220` `goal-split-saved` / `:226` `goal-split-failed` / `:278` `onSplitTodos: _openSplit` / `:290` `_openSplit` / `:302` `_writeSplit` 调用点 / `:312` `_writeSplit` 定义。

---

## 3. 门禁（控制器亲跑，不许 worker 代跑）

```powershell
Move-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' `
          'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build_stale_<yyyyMMdd-HHmmss>'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze      # 期望逐字 No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
pwsh -NoProfile -ExecutionPolicy Bypass -File F:\soft\00selfmade\practilog\reports\task51-gate.ps1 -ExpectDesktopTests <实测 N>
```

- 判据只认 `reports\task51-gate\summary.txt` 里的 `GATE_VERDICT`（坑 95）。
- 期望：core_data 204 / core_db 96 / core_domain 91 / desktop = 实测 N；`VIOLATIONS=0`、`OUT_OF_SET=0`。
- 白名单已含 B9 写集 10 条模式（`docs/plan-goals-ui-batch9.md`、`docs/b91|b92|b93-dispatch-*`、`docs/handoff-ledger-b9*`、`task78_*` / `task79_*` 测试与 `reports/task78-*|task79-*|task80-*`）。

### 3.1 门禁实测（控制器亲跑，**最终 PASS**）

**第一轮（`RUN_AT=2026-11-26 00:04:32`）= FAIL，唯一红点 = 3 个非 ASCII `.ps1`**

| 项 | 实测 |
|---|---|
| `GATE_VERDICT` / `GATE_FAILURES` | `FAIL` / `1` |
| `FAIL_ITEM` | `PS1_ASCII_VIOLATIONS=3` |
| 三个违规文件 | `reports\task78-l10n-patch.ps1`（5,477 B）/ `task78-l10n-patch2.ps1`（3,910 B）/ `task78-l10n-patch3.ps1`（3,021 B）（W1/W2 worker 遗留补丁工具） |
| 产品项 | 全绿：`DESKTOP_TESTS=946`（`DESKTOP_EXPECTED=946` / `DESKTOP_DELTA=350`）、`CORE_DATA=204` / `CORE_DB=96` / `CORE_DOMAIN=91`、四包 `ANALYZE=VERBATIM`、`VIOLATIONS=0`、`OUT_OF_SET=0` |

**处置（R4 不删文件）**：按扫描口径（`reports\task57-ps1-ascii-scan.ps1:48` 只收 `-Filter *.ps1`）把三文件 `Move-Item` 改名为 `task78-l10n-patch*.ps1.retired-20261126-000557`（内容保留）。独立复扫 `reports\task79-ps1-recheck.txt`：`SCAN_EXIT=0` / `PS1_SCANNED=515`（回到基线规模）/ `PS1_NON_ASCII_TOTAL=62` / `PS1_NEW_NON_ASCII=0` / `PS1_ASCII_VIOLATIONS=0` / `PS1_MISSING_FROM_BASELINE=0`。
**未**写入 `task57-ps1-ascii-baseline.txt`（基线只收历史存量，塞 baseline 等于掩盖新违规）。

**第二轮（PASS，主证据）**：日志 `reports\task79-gate2.txt`（2,198 B），`RUN_AT=2026-11-26 00:09:11`，`GATE_EXIT=0` / `ELAPSED_S=112`。

| 判据 | 期望 | 实测 |
|---|---|---|
| `GATE_VERDICT` | `PASS` | **`PASS`**（`GATE_FAILURES=0`，无 `FAIL_ITEM`） |
| desktop 全量 | `946` 精确等值 | **`DESKTOP_TESTS=946`**（`DESKTOP_EXPECTED=946` / `DESKTOP_BASELINE=596` / `DESKTOP_DELTA=350`） |
| core 三包 | `204 / 96 / 91` | **`CORE_DATA_TESTS=204`** / **`CORE_DB_TESTS=96`** / **`CORE_DOMAIN_TESTS=91`** |
| analyze ×4 | 逐字 `No issues found!` | `DESKTOP_ANALYZE=VERBATIM` / `CORE_DATA_ANALYZE=VERBATIM` / `CORE_DB_ANALYZE=VERBATIM` / `CORE_DOMAIN_ANALYZE=VERBATIM` |
| R1 写集 | 0 越界 | `VIOLATIONS=0` / `OUT_OF_SET=0`（`STATUS_LINES=14`，`GATE_EXCLUDED=4` = `docs/relay/*` + `docs/relay.json` + `docs/AGENT-RELAY.md` + `docs/RELAY-ADAPTATION.md`，均接力链遗留） |
| PS1 卫生 | `VIOLATIONS=0` | `PS1_SCANNED=515` / `PS1_NON_ASCII_TOTAL=62` / `PS1_NEW_NON_ASCII=0` / **`PS1_ASCII_VIOLATIONS=0`** / `PS1_BASELINE_SHA16=5247D49A400CC3F9` |
| 提交态 | HEAD / ahead | `HEAD=58ff59d` / `AHEAD=16` / `GIT_EXIT=0` |
| summary 指纹 | — | 1,411 B / mtime `00:09:11` / sha16 **`56B31FD32287A808`** |

**另一轮独立复现（同时段、结果一致）**：紧接改名后的重跑 `RUN_AT=2026-11-26 00:08:02` 亦为 `GATE_VERDICT=PASS` / `DESKTOP_TESTS=946` / `PS1_SCANNED=515` / `PS1_ASCII_VIOLATIONS=0`。
**如实登记**：两轮在 00:07:19–00:08:02 有约 43 秒重叠（前一轮收尾时后一轮已起跑），构不成「互不干扰的两次独立测量」；但两轮读数逐项一致，且都晚于改名动作 ⇒ 采信第二轮（有日志文件、`RUN_AT` 更晚）为主证据。

---

## 4. 出包（**只出包，不装机 —— D-9-i 沿用 B8 口径**）已实测完成

### 4.1 重编（构建树过期，必须先编）

| 项 | 实测 |
|---|---|
| 命令 | `flutter build windows --release`（cwd = `apps\desktop`，镜像双变量进程内设置） |
| 日志 | `reports\task79-build.txt`（258 B）：`Building Windows application... 45.4s` + `√ Built build\windows\x64\runner\Release\actlog.exe` |
| 结果 | `BUILD_EXIT=0` / `ELAPSED_S=48` |
| 产物 `data\app.so` | **9,175,944 B** / sha16 **`27D68DEEA7233AAA`** / mtime **2026-11-26 00:11:02** ⇒ 确已重编 |
| 产物 `actlog.exe` | **484,352 B** / sha16 **`89293205FAF8C3DE`** / mtime **2026-11-20 22:10:55**（**未变**） |

**判读（重要，防误判「没编」）**：`actlog.exe` 只是 Flutter 的 C++ runner 外壳，Dart 代码全部编进
`data\app.so`。B9 W1–W3 只改 Dart 源 ⇒ 外壳字节不变、`mtime` 不刷新是**正确行为**。
**判「是否重编」只认 `data\app.so` 的 mtime + sha16**，不要拿 `actlog.exe` 的旧时间戳当过期证据。

### 4.2 出包

| 项 | 实测 |
|---|---|
| 命令 | `pwsh -NoProfile -ExecutionPolicy Bypass -File tools\build\make_installer.ps1 -Version '1.0.0'` |
| 日志 | `reports\task79-installer.txt`：`INSTALLER_EXIT=0` / `RUN_AT=2026-11-26 00:12:03` |
| payload | `release\payload_20261126-001138`：36 文件 / 60,452,938 B（源树 42 文件 / 62,096,564 B，排除 6 个 userdata 库文件 1,643,626 B） |
| makensis | `C:\Program Files (x86)\NSIS\makensis.exe`；`makensis exit = 0`；`pe_mz_magic = MZ` / `nullsoft_signature` 命中 / `Type = Nsis` / `SubType = NSIS-3 Unicode` / `Method = LZMA:23` |
| makensis 日志落点 | `.superpowers\makensis_out.txt` + `.superpowers\installer_build_report.txt`（**本轮再次实测证实**，与 §0 第 17 行一致） |

### 4.3 新包四要素 + 与旧锚点比 sha16（坑 108）

| 包 | 字节数 | sha16 | mtime |
|---|---|---|---|
| **新（B9 唯一可分发）** `actlog-Setup-1.0.0_20261126-001138.exe` | **22,830,357 B** | **`9F7ABEAC7B4C191A`** | **2026-11-26 00:12:03** |
| 旧锚点 `actlog-Setup-1.0.0_20261125-222947.exe` | 22,817,510 B | `8D9FE856CD7E882A` | 2026-11-25 22:30:18 |

- 旧包 sha16 当场复测 = `8D9FE856CD7E882A`，与 §0 第 13 行、AGENTS.md §7 记录**逐字一致** ⇒ 锚点未被污染。
- `REBUILD_DIFFERS_FROM_OLD=True`（sha16 不同）；体积仅 **+12,847 B（+0.056%）**。
  **若按字节数判重编会得出错误结论**（体积几乎不变容易误判「没重编」）⇒ 坑 108 再次生效。
- **R3 锚点已变更**：自本轮起唯一可分发 = 新包；`release\` 下 exe 总数 57 → **58**，其余 **57 个严禁分发**。
- 口径：**只出包、未装机**。本轮**不得**登记为「已装机验收」（D-9-i）。

### 4.4 R6 复选框：本批计划文件无复选框 ⇒ 无操作

`docs\plan-goals-ui-batch9.md` 全文 `^\s*-\s*\[[ xX]\]` 实测 **0 命中** ⇒ R6「控制器独占且等长替换」在本批无适用对象（B8 计划里的「Task 1–3 打勾」情形不复现）。

---

## 5. 真机取证（**未判定**：根因 = 本机锁屏）

### 5.1 判据与实测

| 项 | 期望 | 实测 |
|---|---|---|
| 前置探针（00:10:24，`reports\task80-lockprobe.txt`） | 可交互前台 | `FG=0` / `THREAD_DESKTOP=Default` / `INPUT_OK=False` / `INPUT_ERR=5` / `LOGONUI=1` / `PROC_actlog=1` ⇒ `TREAT_AS_LOCKED=True` |
| 出包后复测（00:12:24，`reports\task80-lockprobe2.txt`） | 同上 | `FG=0` / `INPUT_OK=False` / `INPUT_ERR=5` / `LOGONUI=1` / `PROC_actlog=1` ⇒ `TREAT_AS_LOCKED=True` |

**判读**：`GetForegroundWindow()==0` + `LogonUI` 驻留 + `OpenInputDesktop` 报 error 5 ⇒ 安全桌面接管交互桌面。
Flutter 的 Impeller/DXGI 表面只在窗口为前台时才进表面 ⇒ `PrintWindow` 只能取到 GDI 背景；
`SetForegroundWindow` / `SwitchToThisWindow` / `AttachThreadInput` / 合成鼠标点击全部拿不到前台。
**已排除的误判方向（别再试）**：① 切 `WinSta0`/`Default` —— `OpenWindowStationW`/`OpenDesktopW` 会成功，但
`SetThreadDesktop` 报 `ERROR_BUSY=170`；② `schtasks /Create ... /IT` 交互式任务 —— `FG_AT_START` 仍为 0。

### 5.2 四项待取证（**全部 UNDETERMINED，不写 PASS、不写「已修」也不写「回归」**）

| # | 待证 | 运行时判据 | 状态 |
|---|---|---|---|
| 1 | 蓝图页顶部「个人品牌管理」模块在矩阵**上方** | 帧内品牌卡纵向位置 < 矩阵卡 | **UNDETERMINED（根因=锁屏）** |
| 2 | 4 标签页 终极/远期/中期/短期 + 无「人生蓝图矩阵」标题 + 空单元格**右下角「+」** | 帧内 4 个 tab 与单元格右下角「+」 | **UNDETERMINED（根因=锁屏）** |
| 3 | 已添加内容右侧 **铅笔 + 拆分** 两按钮 | 帧内 `Icons.edit_outlined` / `Icons.call_split` 可辨；`call_split` 是否 tofu 同属未判定 | **UNDETERMINED（根因=锁屏）** |
| 4 | 拆分确认后**直接落库** | `task77-goal-dump.py` 读回新增子目标（`parent_id` + `serves`）或年目标/待办（`tracks`） | **UNDETERMINED（根因=锁屏）** |

- 单测 `apps\desktop\test\task79_b9_split_chain_test.dart`（10 例）只证明**代码路径与映射**，
  **不能替代**运行时双证（R5：结论必须打到运行时产物）。
- W1/W2 的 l10n / ValueKey / 落库读回证据均在**测试进程内**取得，同属「非真机」证据口径。

### 5.3 解锁后复现配方（可直接粘贴执行）

```powershell
# 0) 先判锁屏：期望最后一行 TREAT_AS_LOCKED=False；为 True 就到此为止，别硬跑驱动
pwsh -NoProfile -ExecutionPolicy Bypass -File F:\soft\00selfmade\practilog\reports\task80-lockprobe.ps1

# 1) 取帧 + 交互（驱动自带 PrintWindow(hwnd,hdc,2)）
pwsh -NoProfile -ExecutionPolicy Bypass -File F:\soft\00selfmade\practilog\reports\task77-w4-drive.ps1 `
     -OutDir F:\soft\00selfmade\practilog\reports\task80-frames

# 2) 落库读回（脚本第 4 行硬编码 reports\task72-seeddb\actlog.db）
python F:\soft\00selfmade\practilog\reports\task77-goal-dump.py
```

- 被测件：**重编后**的 `apps\desktop\build\windows\x64\runner\Release\actlog.exe`（验 `data\app.so` mtime = 2026-11-26 00:11:02）。
- 数据：`--data-dir=F:\soft\00selfmade\practilog\reports\task72-seeddb`（种子副本，用户活库零写入）。
- 驱动约束（坑 106）：注入只认 `paste:`；编辑弹窗打开后**不要先点输入框**；屏幕坐标 = 参数 + (20, −56)。
- 探针脚本 `reports\task80-lockprobe.ps1` 为本轮新增（纯 ASCII），**下次门禁 `PS1_SCANNED` 预期 516**（非违规，`PS1_ASCII_VIOLATIONS` 仍应为 0）。

---

## 6. B8 八项遗留挂账承接（不属 B9，本批只承接不解决）

| # | 挂账 | 处置 |
|---|---|---|
| 1 | 今日页右栏「目标/项目」卡只读 vs 整卡移除未裁 | 承接，待用户裁决 |
| 2 | 窄屏 `KeyBar` 缺 `Ctrl+7` 提示 | 承接 |
| 3 | B8 包未装机、装机态待复验 | 承接（B9 同样只出包） |
| 4 | 年页空态归因种子目标缺 `domain`/`horizon` | 承接 |
| 5 | W3 遗留两处：`week-goal-add-hint` 负断言与「符号 0 命中」互斥；外部 `goal://` 拖入被 `DragTarget` 高亮后静默丢弃 | 承接 |
| 6 | 注入通道缺陷属驱动侧，非产品缺陷 | 承接 |
| 7 | 21:59:46「无交互写入」未单独留证，仅登记不采信 | 承接 |
| 8 | `reports\**` 被 `.gitignore` 排除，任何情况下不得 `git add reports/` | 持续有效 |

---

## 7. 收口动作清单

- [x] `progress.md` 追加 ⑳ 条目
- [x] `handoff.md` 追加 §84
- [x] `AGENTS.md` §7 当前状态快照更新（HEAD / 包 sha16 / 测试基线 / l10n 基线）
- [x] 本文件 §2 回填 W3 实测、§4 回填新包四要素、§5 回填帧文件名
- [x] `task_query status=running` 清点；ack 文件保住 `acks` 外层键