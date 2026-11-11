# 交接文档 — practilog B1 Flutter 实施进行中（Task 1–3 已收口，下一站 Task 4）

> 生成时间：2026-11-08 09:21（GMT+0800）
> 阶段切换说明：上一份 handoff（`HANDOFF_20261107_B版原型收口_转Flutter实施.md`）讲的是「B 版原型已落地、
> 准备转 Flutter」；**从那时起 B1 实施已实际启动并完成 Task 1–3**。本份接棒它，不重复原型阶段细节。

---

## 1. 项目背景（30 秒版）

**practilog（知行日志）** = 一个「每天只记一条结论」的桌面自省工具。
左侧导航 + 今日主屏 + 日期条/日历弹层，只做 **Windows 桌面端**。
视觉方向已定为 **B「墨径·账页流」**：浅色、账页横线、衬线标题、墨色为主、赭石只作警示。
技术栈：Flutter 3.47.9 / Dart 3.13.7 + Riverpod + SQLite（`schema v1` 已冻结）。
三层落地划分：`packages/core_domain` + `packages/core_data` 放纯函数、`apps/desktop/lib/src/theme` 放 token/密度/主题、
`apps/desktop/lib/src/widgets` 放 B1 的共享组件。

**当前正在做的事**：执行 P-1 制定的 **B1 Flutter 实施计划**（17 个 Task），逐 Task 由 subagent 实现 + 评审。

## 2. 硬约束（改代码前必读，全部仍然有效）

1. **只做 Windows 桌面端**。今日主屏 + 左侧导航 + 日期条/日历弹层；浅色。
2. **无障碍硬性下限**：正文 ≥14px、标签 ≥12px、文字对比度 ≥4.5:1、**可交互边界 ≥3:1**。
3. **赭石 `--accent` / `--accentInk` 只允许用于「缺口/警示」语义**；
   不得作为 primary / 选中态 / 焦点环。选中态一律 `--ink` 反白；焦点环 = `--ink` 2px 实线。
4. **`schema v1 FROZEN`**：不改 `docs/schema_v1.sql`、不改 `packages/core_db/lib/src/tables.dart` 列定义、
   不升 `currentSchemaVersion`。新设置项归入 `settings.key`。
5. **非 git 仓库** ⇒ 不把 worktree / commit / review-package 当限制条件，改为「命令跑通 + 磁盘证据文件」；
   每个 Task 不得把 Commit 作为验收条件。
6. **验收以 `flutter build windows` 产物为准**，`flutter dev` 不可用于界面验收；
   需装机实测就直接打包 exe（`tools\build\make_installer.ps1`），不等用户要求。
7. **文件规范**：Dart 源 LF 无 BOM；`tools\*.ps1` 纯 ASCII + CRLF + 无 BOM；`.nsi` UTF-8 带 BOM + LF；
   新代码禁 `print`；`packages/` 公开成员需 doc comment。
8. **执行方式 = Subagent-Driven**：每个 Task 用全新 `worker` 子代理实现，另派 `verifier` 子代理评审。
   修复轮由**原实现者续作**（`task_append`），不另派新 worker。

## 3. 当前进度：Task 1、2、3 已收口；下一站 Task 4

| Task | 内容 | 状态 | 收口门禁（控制器亲跑） |
|---|---|---|---|
| 1 | `AppTokens` + 对比度工具 | ✅ 收口 | analyze clean；`+50`；Spec ✅ Critical 0 / Important 0 |
| 2 | `AppFonts` + `DensityProfile` | ✅ 收口 | `No issues found!`；`+55 All tests passed!` |
| 3 | `AppTheme` 接线 + `SectionCard` 换肤 | ✅ 收口 | `No issues found! (ran in 10.7s)`；`00:08 +63: All tests passed!`；`+8` 单文件 |
| 4 | `core_domain` `ResultNote` 编解码 | ⬜ 下一步 | — |
| 5–17 | 见 §5 与计划全文 | ⬜ 待做 | — |

**测试基线 = 63 个用例**（`apps/desktop` 全量 `flutter test`）。Task 4 起每加一个用例，基线 +N。

### 3.1 已落地产物（控制器已亲自复验）

```
apps/desktop/lib/src/theme/app_tokens.dart        2539B   颜色/间距 token + contrastRatio()
apps/desktop/lib/src/theme/contrast.dart           778B
apps/desktop/lib/src/theme/app_fonts.dart         2470B   栈首首选 + 兜底列表
apps/desktop/lib/src/theme/density_profile.dart   1344B   纯枚举 compact/comfortable/roomy
apps/desktop/lib/src/theme/app_theme.dart         4051B   8 个 TextTheme role + 24 个 ColorScheme 角色
apps/desktop/lib/src/app.dart                     617B
apps/desktop/lib/src/widgets/section_card.dart   2280B
apps/desktop/test/theme_tokens_test.dart          1379B
apps/desktop/test/density_profile_test.dart       2733B
apps/desktop/test/app_theme_test.dart             3995B
```

`packages/core_domain` 与 `packages/core_data` **尚未被 B1 改动**（Task 4 起才动）。
`apps/desktop` 其余文件（`today_page.dart` / `mood_section.dart` / `review_section.dart` /
`standup_section.dart` / `priority_chips.dart` / `habit_section.dart`）是**改动前的旧实现**，
Task 7 / 15 才会重做它们。

### 3.2 只是「推断」，接棒者当假设而非事实

- `labelMedium` / `labelSmall` 等 role 在实际渲染中的观感（尤其 `titleSmall` 降到 12.5px 后
  象限短标签的视觉缩水）**未经像素级核对**，留给 Task 7 / Task 17 截图门禁。
- `SectionCard` 标题（19px display）与副标题（12.5px body）的层级差是否与原型一致，**未做像素比对**。
- `surfaceTint` / `shadow` / `scrim` 等 25 个未覆盖的 `ColorScheme` 角色虽在 `lib/` 下零直接消费，
  但 **Material 内部件会间接读取**，实际渲染效果未截图确认。

### 3.3 明确未验证（不要写成「已完成」）

- **字体资产未打包**：Fraunces / Inter / JetBrains Mono / Noto Sans SC 本地无字体文件，
  `TOKENS.md` §8 要求的「桌面端缺字库时必须自带」**不在 B1 的 17 个 Task 范围内**，
  实际渲染走兜底列表（正文命中 Noto Sans SC / 微软雅黑）。
  ⇒ **`TOKENS.md` §8 的「144dpi / 200% 字号」验收不算完整**，已登记于计划附录 C + `TOKENS.md` §8 +
  `app_fonts.dart` 注释三处互相指认。
- 任何**界面观感**结论都还没有真机截图证据（Task 17 才做）。
- B1 的 G4 对比度门禁脚本 `tools\gates\g4_contrast.ps1` **尚未创建**（Task 17 产出）。

## 4. 权威文档清单（全路径，接棒会话必读）

### 4.1 必读（按顺序）

| 路径 | 为什么读 | 大小 |
|---|---|---|
| `F:\soft\00selfmade\practilog\docs\HANDOFF_20261108_B1实施_Task3收口.md` | 本文件 | — |
| `F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\progress.md` | **唯一进度真相源**：Task 1–3 的完整裁定、归属更正、留档事项 | 15588B |
| `F:\soft\00selfmade\practilog\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` | **B1 实施计划全文**（17 个 Task，4644 行）；Task 边界行号见 §7 | 164627B |
| `F:\soft\00selfmade\practilog\design-demos\TOKENS.md` | **token 口径唯一来源**（§2 字号、§2.1 密度、§2.2 下限、§2.3 role 白名单 + 色角色清单、§8 字体要求） | 21166B |
| `F:\soft\00selfmade\practilog\design-demos\CONTENT.md` | 文案口径 | — |
| `F:\soft\00selfmade\practilog\design-demos\direction-approved.md` | 已批准方向（§1 / §1.5b / §4） | — |
| `F:\soft\00selfmade\practilog\docs\superpowers\specs\2026-11-07-双端交互体验设计.md` | 交互设计规范（Task 4 的 `ResultNote` 依据在 §6.1） | — |

### 4.2 工作产物

```
F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation\
  progress.md              15588B   ← 进度真相源
  reviewer-template.md      3480B   ← 评审报告模板（verifier 必须照它写）
  task-1-brief.md … task-17-brief.md   ← 每个 Task 的执行契约（17 份，全部就绪）
  task-3-patch-v2.md        6571B   ← Task 3 补丁 v2（已并入计划与 brief）
  reports\                 60+ 份证据文件（task-N-*.log / -report.md / -package.md / -review.md）
```

### 4.3 只读输入

```
F:\soft\00selfmade\practilog\docs\HANDOFF_20261107_B版原型收口_转Flutter实施.md   （原型阶段，含工具坑清单）
F:\soft\00selfmade\practilog\design-demos\v2-ledger.html                      （已批准原型，勿改）
F:\soft\00selfmade\practilog\docs\schema_v1.sql                                （FROZEN）
```

## 5. 下阶段计划（按序做，每步都要判据）

### 5.1 立即做：Task 4 — `core_domain` `ResultNote` 编解码

- **计划位置**：`docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` 第 **1027** 行起。
- **执行契约**：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-4-brief.md`（11450B，已就绪）。
- **产出**：`packages\core_domain\lib\src\result_note.dart` + `packages\core_domain\lib\core_domain.dart`
  加 `export 'src/result_note.dart';` + `packages\core_domain\test\result_note_test.dart`。
- **注意**：`packages/` 的公开成员需 doc comment；`core_domain` 是纯 Dart 包，门禁用 `dart test`
  （**不**是 `flutter test`），工作目录 `packages\core_domain`。

### 5.2 后续 13 个 Task

按计划行号推进：Task 5 `1264` · 6 `1459` · 7 `1736` · 8 `2092` · 9 `2293` · 10 `2598` ·
11 `2841` · 12 `3087` · 13 `3437` · 14 `3903` · 15 `4118` · 16 `4337` · 17 `4477`。

**每个 Task 的固定流程**（Subagent-Driven）：

1. 控制器先读 brief，必要时先修计划 + `TOKENS.md`（**发现计划内在矛盾/缺口时必须先改口径文件再下发**）。
2. 派 `worker` 子代理实现（附「必读路径 + 门禁命令 + 落盘规范 + 回报格式」）。
3. 控制器**亲自复跑门禁**（不采信 worker 自述），亲自核验编码 / 越界改动 / 产物。
4. 派 `verifier` 子代理评审（scope 限定该 Task 的验收项 + 回归检查），报告写入 `reports\task-N-review*.md`。
5. 评审报出 Important 时：控制器裁定 → 写补丁 → `task_append` 给**原实现者**续作 → 再复跑门禁 → 复评。
6. 收口后追加 `progress.md`，更新 TodoWrite。

### 5.3 已分派的跨 Task 遗留项（**不要重新分配**）

| 项 | 内容 | 归属 Task |
|---|---|---|
| I4 | 旧品牌绿 `#2E8B57` 经 `colorFromHex` 当芯片常态边/选中态上屏 | **Task 7**（`priority_chips.dart` 已增补进 Task 7 Files） |
| I-2 | `today_page.dart:404` / `standup_section.dart:190` 徽标写死 `fontSize: 10`，击穿 12px 下限 | **Task 15** |
| M1 | `today_page.dart` 无横向 padding ⇒ `SectionCard` 横向贴边 | **Task 15** |
| M3 | `mood_section.dart:28` `#E07A5F` / `review_section.dart:34` `#6A5ACD` 写死颜色 | **Task 15** |
| M-1 | `titleSmall` 12.5px 象限短标签观感缩水 | Task 7 / Task 17 截图门禁 |
| M-4 | `SectionCard` 标题/副标题层级差缺像素证据 | Task 17 |
| — | 25 个未覆盖 `ColorScheme` 角色 | Task 17 的 G4 门禁要扫 |

## 6. 本轮踩过的坑（别再花一轮试）

### 6.1 PowerShell 写文件（最容易静默毁文档）

- **双引号串里 `` `a `` 是 BEL 转义**：写 `` "`apps/..." `` 会变成 `0x07 + "pps/..."`，**静默毁坏文档**。
  含 backtick 一律用**单引号**串 / 单引号 here-string；写完必查 `[\x00-\x08]` == 0。
- 单引号串里 `` `n `` **不转义**；多行字面量用单引号 here-string + `-replace "`r`n","`n"` 归一。
- `Set-Content -Encoding UTF8` **会写 BOM** ⇒ 一律
  `[System.IO.File]::WriteAllText($p,$s,(New-Object System.Text.UTF8Encoding($false)))`。
- `$line.Replace([char]96,'<BT>')` 报 `String must be exactly one character long`
  ⇒ 用 `.Replace([string][char]96,'<BT>')`。
- 正则里写 `\btest\(` 时，**双引号串内的 `\"` 会被 PowerShell 误解析** ⇒ 用单引号串。
- 含 backtick 的字面量替换：单引号串 + **断言命中数 == 1** 再替换。

### 6.2 评审与子代理

- `grep` 工具 `output_mode:'content'` 本会话经常失效（只回文件列表）⇒ 用 `read` 或 `Select-String`。
- `git diff --no-index` + `Copy-Item -Force` 到新建快照目录**被本机硬安全策略拦**
  ⇒ 改「读全文 + 拼接写单 .md」。
- 连续 3 次轮询同一后台任务会触发系统提醒 ⇒ 等自动完成通知。
- **后台子代理写文件期间读它的产出会读到半截内容** ⇒ 先确认终态（`task_query` / `task_output`）再验收。
- verifier 子代理可能没有 `write` 工具，会用 PowerShell 写报告文件（正常）。
- 本机 Dart SDK 编译错误文案已中文化（`Error when reading ... 系统找不到指定的文件`），
  brief 里写的英文原文对不上属正常。
- **子代理 Token Plan 额度可能触顶**（`bg_5beb40c6` 曾因 `2056` 失败）；若新子代理报 `2056`
  ⇒ 控制器自己做并记录偏差。
- 子代理的「口径文件未更新」类判断**可能是误报**（它读的是补丁前的内容）⇒ 控制器必须自己核验。

### 6.3 验收纪律

- **worker 说修好不算**；控制器必须亲自跑命令 + 看字节。
- `practilog.exe` 的 mtime **不会随 Dart 代码变化**（Dart 代码在 `data\app.so`）⇒ 看 `app.so` 的 mtime。
- 修改**绘制/排版/几何公式**后像素零差异 ⇒ 先怀疑「度量 API 报错被吞」，再怀疑公式。
- 验收判据必须打在**运行时产物**上，不能打在素材文件上。

## 7. 计划文件的 Task 边界行号（实测，插过补丁后已更新）

```
Task 1  109     Task 7  1736    Task 13 3437
Task 2  315     Task 8  2092    Task 14 3903
Task 3  567     Task 9  2293    Task 15 4118
Task 4  1027    Task 10 2598    Task 16 4337
Task 5  1264    Task 11 2841    Task 17 4477
Task 6  1459    Task 12 3087    附录 A 4584 / B 4611 / C 4627
```

补丁 v2 在 815 行、补丁 v3 在 986 行（都在 Task 3 末尾、Task 4 之前）。

## 8. 可直接复用的命令形状

```powershell
# Flutter 门禁（工作目录 apps\desktop；每个新 shell 先设中国镜像）
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\<name>_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' build windows --release

# 纯 Dart 包单测（各自目录，用 dart 不是 flutter）
Set-Location F:\soft\00selfmade\practilog\packages\core_domain; dart test
Set-Location F:\soft\00selfmade\practilog\packages\core_data; dart test

# 门禁跑通并同时落盘 UTF-8 无 BOM 日志（末行判读）
$ws='F:\soft\00selfmade\practilog\.superpowers\sdd\2026-11-07-b1-flutter-implementation'
$a=(& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze 2>&1 | Out-String)
[System.IO.File]::WriteAllText("$ws\reports\task-N-analyze.log",$a,(New-Object System.Text.UTF8Encoding($false)))
Write-Output (($a.Trim() -split "`n")[-1])

# 编码 + 残留文件核验
$b=[System.IO.File]::ReadAllBytes($f); $s=[System.Text.Encoding]::UTF8.GetString($b)
$bom=($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
([regex]::Matches($s,"`r`n")).Count; ([regex]::Matches($s,'[\x00-\x08]')).Count; ([regex]::Matches($s,'\bprint\(')).Count
Get-ChildItem -Recurse -File -Path "$root\lib","$root\test" | Where-Object { $_.Extension -ne '.dart' }

# 追加到 progress.md 且强制 LF
$add = $add -replace "`r`n","`n"
$s=[System.IO.File]::ReadAllText($p)
[System.IO.File]::WriteAllText($p, $s.TrimEnd([char]10) + "`n" + $add.Trim([char]10) + "`n", (New-Object System.Text.UTF8Encoding($false)))
```

## 9. 用户长期偏好（跨项目，接棒会话照做）

- **明显 bug 直接按推荐方案修，不要发放问卷让用户选**；但「删除/覆盖用户数据、需付费或对外发布、
  会大量消耗时间或显著改变架构方向」这三类必须先问。
- **需要装机实测就直接打包 exe**，不要等用户要求（`npm run tauri:build` 类命令很慢，判断出要验就早启动、丢后台跑）。
- **浏览器调试用 Edge，不用 Chrome**。
- **worker 说修好不算，须 agent 亲自验证**。
- **中间产物写文件，对话里只留指针 + 结论**；单轮工具调用控制在 10 次以内。
- **计划文件发现内在矛盾或缺口时，先由控制器修订计划 + 口径文件，再下发。**
- 每轮任务结束后写 handoff 文档 + 一句话 prompt（见 `docs\prompt-2026-11-08-relay-b1-task4.md`）。

## 10. 不在本任务里、但别丢的用户本人事项

- 字体资产打包（Fraunces / Inter / JetBrains Mono / Noto Sans SC）—— 需单独立项取字体文件，
  放 `apps\desktop\assets\fonts\`，在 `pubspec.yaml` 的 **`flutter.fonts`**（不是 `flutter.assets`）下声明。
- B4 范围的运行时密度切换 UI（`DensitySettings`）、深色档配色、多端（移动端）。
