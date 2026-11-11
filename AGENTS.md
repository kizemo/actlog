# actlog · 项目级 Agent 规范（唯一真源）

> **这是本项目唯一的项目级 Agent 指令文件。** 任何 Agent（含子会话）进入本仓库，先读完本文件再动手。
> `CLAUDE.md` 只是指向本文件的兼容入口，内容不重复，避免双真源漂移。
> 本文件只写**长期成立的约束与装置位置**；会变的数字以本文件指明的「真源文档」为准，不在此重复堆积。

---

## 1. 项目是什么（30 秒）

actlog（知行日志）：面向个人的效能工具，以《高绩效人士的五项管理》为信息架构骨架，把「目标—计划—执行—复盘」做成可记录、可追溯、可同步的日常数据。

- Windows 桌面端 **Flutter**，Android 端（P6）共用领域模型与数据库契约。
- **本地 SQLite 是唯一真相源**，服务端只是中继与备份；断网必须完全可用。
- 同步走**记录级 oplog 增量**（upsert/delete + lamport 时钟），oplog 必须在 P0 就埋好。
- **不做账号体系**；同步走局域网直连 / WebDAV。
- 对外不得宣称「四象限」来自原书：本项目统一写「A 类 = Q1 + Q2」。

---

## 2. 铁律（违反即回滚，不接受「下次注意」）

### R1 · 写集纪律：控制器不改实现代码

- **控制器（root session）不得修改 `apps\**` 与 `packages\**` 下任何文件。** 实现只能经 worker 子会话完成。
- 每个 Task 在计划里有一张**写集表**（独占路径）。worker 只能写自己那一行；控制器只能写台账行（计划 / `docs\B1_验收记录.md` / `progress.md` / `handoff.md` / `reports\taskN-*`）。
- 写集之外出现任何改动 = 违规。收口前必须跑越界比对，判据 **`VIOLATIONS=0`**。
- 若某文件确实必须改而计划表没写，**先由控制器在写集表里显式追加一行并留档**（先例：Task 21「收口补」行），不许默默改。
- 独立 verifier 必须**只读**，且**不得是实现者本人会话**。

### R2 · 门禁判据（硬数字，不接受「大概过」）

跑门禁前**必须**先把 `apps\desktop\build\test_cache\build` **改名挪走**（`Move-Item` → `build_stale_<ts>`），否则 OS Error 183 永久挂死。

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
# apps\desktop（Flutter）
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
# packages\core_data（纯 Dart，不是 flutter）
& 'F:\soft\flutter\flutter\bin\dart.bat' analyze
& 'F:\soft\flutter\flutter\bin\dart.bat' test
```

| 判据 | 通过标准 |
|---|---|
| `flutter analyze`（desktop） | **逐字** `No issues found!`。error / warning / **info** 全 0。**不许**用「数 info 关键词」代替 |
| desktop 全量 `flutter test` | 当前基线 **+215**，零回退（+207 是 Task 21 补测 A8/A9 之前的旧基线） |
| core_data 全量 `dart test` | **+141** |
| 越界比对 | `VIOLATIONS=0`（sha diff + mtime 窗口双判据） |
| `.ps1` 脚本 | **纯 ASCII**（中文一律 `[char]0x....` 码点拼），CRLF，无 BOM |
| Dart 源 | LF，无 BOM，`[\x00-\x08]` 计数 = 0，`print(` 计数 = 0 |

- **门禁重定向必须写在 `.ps1` 内部**：`Set-Location` 之后向新文件重定向会被本地硬安全策略拦。
- 门禁红灯且报错点**不在本任务文件**时，先查**并发写入**（mtime 稳定 ≥30s + sha16 未变）再怀疑自己的代码。

### R3 · 分发禁令

**唯一可分发** = `release\actlog-Setup-1.0.0_20261112-000947.exe`
（15818676 B / sha16 `6CDFAA16D8D23130` / mtime 2026-11-12 00:10:07；包内 `data\app.so` sha16 `4B756691A48DA94A`
与本轮 `flutter build windows --release` 产物**逐字相同** ⇒ 新代码确在包内，证据 `reports\task35-rebuild-installer.txt`）。
Task 35 包内容：**循环任务**（`recurring_task` + `recurring_occurrence` 两表、`currentSchemaVersion` 1→2、
右轨「习惯速览」下方「循环任务＋」模块、添加后自动填入每天计划）+ **四维优先级标记**
（`▲` 重要 / `▽` 不重要 / `◆` 紧急 / `◇` 不紧急，渲在计划**名称前面**）+ **去除「闭环环」模块下的页头标题**
（今日 / 日期 / 星期 + 「完整」「极简」两枚按钮）；门禁 `GATE_VERDICT=PASS`（analyze 逐字 `No issues found!` /
desktop **+328** / core_data +151 / core_db +71 / `VIOLATIONS=0`）。
**真机目视未做** ⇒ 待装本包后验两件：① 四维字形 `▲▽◆◇` 在真机字体下不缺字 ② 循环任务添加后「自动填入每天计划」可见。

⚠️ **打新包前必须先跑 `flutter build windows --release`**：`tools\build\make_installer.ps1` 自带
`NOTE: this script never invokes flutter/dart; it always packages the existing release tree.` —— 它**只打包、不编译**。
2026-11-12 首包 `…_20261112-000727.exe` 正是这么打成旧代码的（包内 `app.so` sha16 仍是 Task 34 的 `D9ACE771340DF3F3`，
包体积与旧包**逐字节相等** 15782107 B，两条独立判据同向）。固化脚本：`reports\task35-rebuild-installer.ps1`。

坏包 `actlog-Setup-1.0.0_20261112-000727.exe`（15782107 B）自 Task 35 起**降为坏包，严禁分发**（未跑 `flutter build` 就打包 ⇒ 包内是 Task 34 旧代码）。

历史包 `actlog-Setup-1.0.0_20261111-225703.exe`（15782107 B / sha16 `1A50EB997120E503`）自 Task 35 起**降为历史包，不得分发**（Task 34 包：安装目录 `practilog`→`actlog` 整目录改名 + 顶栏去 logo 右侧 `actlog` 字 + 右轨拆「待办列表」/「习惯速览」两模块；2026-11-11 本机**静默覆盖装机实测** `INSTALLER EXIT=0`，旧目录 `D:\Program Files\practilog` 已消失、新目录 `D:\Program Files\actlog` 在位，轨迹 `ACTLOG_MIGRATE=RENAME_OK`，`userdata` 原地保留 ⇒ 账本零丢失；真机目检已闭合，证据 `reports\task34-probe\task34-install-out.txt` + `reports\task34-probe\task34-probe2-out.txt` + `reports\task34-probe\app-window-screen2.png`，详见 `handoff.md` §27）。

历史包 `actlog-Setup-1.0.0_20261111-225437.exe`（15781029 B）自 Task 34 起**降为历史包，不得分发**（同轮第一版，迁移轨迹日志常量写不出导致 makensis 报 2 条 6000 警告并整段忽略，已由 `…_225703.exe` 取代）。

历史包 `actlog-Setup-1.0.0_20261111-220332.exe`（15778514 B / sha16 `169D24D160ACA4D5`）自 Task 34 起**降为历史包，不得分发**（Task 33 包；装机目录名当时仍为 `practilog`）。

历史包 `actlog-Setup-1.0.0_20261111-215616.exe`（15778748 B）自 Task 33 起**降为历史包，不得分发**（同轮改名打包的第一版，被 `…_220332.exe` 取代，未装机）。

历史包 `…_20261111-200220.exe`（15751450 B / sha16 `7548437DFF693BF5`）自 Task 33 起**降为历史包，不得分发**（Task 32 品牌图标包，exe 仍为旧名 `practilog.exe`）。

历史包 `…_20261111-113143.exe`（15746526 B / sha16 `E41DF9560A978302`，SHA-256
`E41DF9560A97830230BC2F34A95CFDA03DCA0E9299EF9DED4FF26588AA3354AD`）自 Task 32 起**降为历史包，不得分发**
（Task 30 自定义顶栏包，真机交互 7/7 PASS，收口 `reports\task30-w2-closeout.md`；不含 Task 32 新品牌图标）。

历史包 `…_20261111-105728.exe`（15750941 B）自 Task 30 起**降为历史包，不得分发**（W-1 探针 PASS 但双击最大化 `NO_EFFECT`）。
历史包 `…_20261111-090809.exe`（15742832 B / sha16 `99D1E949E507D0A5`）自 Task 30 起**降为历史包，不得分发**（Task 29 四态双通道包，已被取代）。
历史包 `…_20261111-013828.exe`（15740862 B / sha16 `9FF92CF78678F1D6`）自 Task 29 起**降为历史包，不得分发**（不含四态双通道）。
历史包 `…_214615.exe`（15703955 B / sha16 `CF137421F1637792`）自 Task 28 起**降为历史包，不得分发**。

`release\` 下现共 **21 个 exe，仅上列 1 个可分发，其余 20 个严禁分发**（15 个历史 `PractiLog-Setup-*` + 被取代的 `actlog-Setup-1.0.0_20261111-215616.exe` / `…_220332.exe` / `…_225437.exe` / `…_225703.exe` + 坏包 `…_20261112-000727.exe`）。

以下**严禁分发**（缺许可、缺 Task 20/21/26 内容、或已被取代）：`…_132823.exe`、`…_121337.exe`、`…_095128.exe`、`…_20260918-181730.exe`，以及 `release\` 下其它任何历史 exe。
真源：`docs\B1_验收记录.md` 第 5 节 + `reports\task26-closeout.md` §9。**打包新包后才更新本条**，且必须同步改这两处。

### R4 · 不删文件

- 本机可恢复删除与永久删除**都会被本地策略拦**；要「清掉」一律用 `Move-Item` **改名**（先例：`test_cache\build_stale_*` 有几十个）。
- 字体、许可证、历史安装包 payload **一律不删**；已知计划 §5「不删除任何字体文件」的措辞与 13:04 的实际删除有冲突，已登记 **B2 文档澄清项**，不在实现轮里改。

### R5 · 证据纪律：替代手段不算证据

- **`ACTLOG_TEXT_SCALE`（旧名 `PRACTILOG_TEXT_SCALE` 仍兼容）都是文本缩放，不是 Windows 显示缩放。** 计划 §5 与 `handoff.md` §16.3 双重禁止拿它冒充真实显示缩放证据。
- 结论要打到**运行时产物**上（真机截屏、包内字节、进程行为），不打在「源码看着对」「素材看着对」上。
- 「搜索 X 得到 0 命中」不能当「X 已消失」的证明：先拿改前基线跑同一判据，证明**判据本来能看见 X**。
- 拿不到证据就**如实登记为「未做 + 遗留」**，不许用替代手段充数，也不许把它记成缺陷。

### R6 · 计划复选框由控制器独占写入

- 只有控制器能打勾；必须**等长替换** `- [ ] ` → `- [x] `（含两空格缩进项），改后字节数不变、sha16 当场重测。
- **没通过的不许打勾**。`7041`（T2 真实显示缩放）**至今保持 `- [ ]`** —— 会话内不可达成（只能由用户注销重登后取帧），登记在 `docs\B1_验收记录.md` 第 5 节 **#10 / #13** —— **不冒充通过、也不入缺陷账**。`7042`（T3 键条真机注入）已于 **Task 23 取证达成并打勾**，逐条证据见 §5 **#11** 与 `reports\task23-closeout.md`。

### R7 · 项目边界：文件不出项目目录，任务不越项目

- **本仓库根 = `F:\soft\00selfmade\practilog`。** 所有产出（代码、报告、截图、日志、探针脚本）必须落在本项目目录内：`apps\` / `packages\` / `tools\` / `docs\` / `reports\` / `design-demos\` / `.superpowers\sdd\` / `release\`。
- **不得向项目外写文件**（用户目录、桌面、下载、临时目录、其它仓库）。若某个工具默认写到项目外，改参数把它拉回项目内。
- **不得执行其它项目的任务。** 本机多项目共用 runtime 的 `activeDataDir`，交接卡 `E:\Users\Duanyi\.minimax\.minimax\maintenance\task-state\LATEST.md` **可能是别的项目写的**（历史实例：该卡内容属于 Fluxing / practilog 之外的会话）。读到它先核对**项目名与任务主题是否属于 PractiLog**，不属于就忽略，按本仓库上下文走，不要被它带偏。
- 一律用**绝对路径、不切工作目录**：`git -C <repo>`、全路径调用。`Set-Location` 之后对旧路径写/删会被安全策略拦。
- **建目录 / 写新文件前，先把目标绝对路径与本仓库根逐字符比对**（`F:\soft\00selfmade\practilog`）。本机已发生过两类越界事故：① 把 `00selfmade` 打成 `00selfmake`（**漏一个 `d`**）⇒ 在 `F:\soft\00selfmake\practilog` 下建出一整套假仓库；② 凭空多建 `F:\soft\00selfmade\practilog.superpowers`（**多一个 `.superpowers`**）。**判别口诀：路径里出现 `00selfmake`（缺 `d`）、或仓库根之外出现 `practilog*` 同级目录 ⇒ 立即停下核对，不许「先建了再说」。**
- **建完必须回读确认落在仓库内**：`Test-Path` + 打印父目录，确认父目录确实是仓库根下的子目录。发现越界 ⇒ 用 `Move-Item` / `Directory.Move` **改名挪回**（守 R4 不删），并把这次事故写进本文件 §5 与 handoff。

### R8 · 派工契约（子会话）

- 新起子会话必须显式指定模型 `custom_provider:provider-aa5659/deepseek-v4.1-flash-1017`，且**必须显式给 `effort`**（只接受 `high` / `max`）。
- 派工书（brief）是**唯一实现契约**，比计划正文优先。worker 拿到派工书后不得自行扩大范围。
- 波形：写集互不重叠才并行；重叠则串行，同一文件只允许一个写者。

---

## 3. 验证装置地图（判据 → 装置 → 期望）

| 判据 | 装置 | 期望 / 说明 |
|---|---|---|
| 静态分析零 issue | `tools\gates\g1_analyze.ps1` | 逐字 `No issues found!`；自动发现 `packages\` 下含 `pubspec.yaml` 的包 |
| 单测全绿 | `tools\gates\g2_unittest.ps1` | core_domain / core_db / core_data |
| 迁移 + schema 一致性 + 约束有牙 | `tools\gates\g3_migration.ps1` + `tools\gates\g3_schema_check.mjs`（Node `node:sqlite` 实跑） | 14 张表集合一致；CHECK/UNIQUE/FK 插坏数据必须被拒 |
| 视觉 / 无障碍对比度 | `tools\gates\g4_contrast.ps1` | 跑 `theme_tokens_test` + `app_theme_test` |
| G5–G8（同步幂等 / 双端 schema / 断网可用 / 快照可恢复） | **未实现** | P4–P6 补 |
| G3 自己的「有牙」自测 | `tools\gates\bad-fixtures\`（`self_test.mjs`） | 把 CHECK 中和成 `CHECK (1=1)` 后冒烟**必须失败**，否则门禁判定自己没牙 |
| release exe 冒烟 | `tools\verify\exe_smoke.ps1` | 标题 / 托盘 / 关窗隐藏到托盘 |
| 托盘交互（真鼠标） | `tools\verify\tray_interaction_check.ps1`、`tray_alive_check.ps1`、`tray_visual_probe.ps1`、`uia_find_tray.ps1` | 左键切换 / 右键菜单 / 「显示窗口」拉回；`tray_alive_check` 默认**保留进程**便于肉眼复现 |
| toast | `tools\verify\toast_probe_check.py` | 查 Windows 通知库 |
| 安装结果核对 | `tools\verify\installed_app_check.ps1`、`data_location.ps1` | 装到 `%LOCALAPPDATA%\Programs\actlog` |
| 打包 | `tools\build\make_installer.ps1`（→ `tools\build\make_sfx.ps1`）+ `tools\installer\actlog_setup.iss`、`install_post.ps1` | 产物落 `release\`；包内须核对 `app.so` 指纹 + 4 族字体 + 4 份 OFL + 隐私排除零命中 |
| 字体族名 / 字重核验 | `reports\task21-fontcheck.ps1`、`reports\fonts-name-check.py` | `pubspec` `family:` 必须 == 字体 name 表 **nameID 16**（nameID 1 是旧式名，不可用）；`Noto Sans SC` 必须是 `wght=400` 静态 Regular |
| 字体渲染帧（是否真用上随包字体） | `reports\task21-frame.ps1`、`reports\task21-*.txt` | 界面必须真用 Fraunces / Inter / JetBrains Mono / Noto Sans SC，不许静默回退系统字体 |
| 键条真机按键注入 | `reports\task21-key3.ps1`、`reports\task21-keyinject.ps1` | 注入 → 截屏 → OCR 三件套；`Ctrl+4/5/6` 须验证**零效果** |
| 键条真机按键注入（**当前唯一可用 v6**） | `reports\task23-t3-e2e2.ps1`（日志 `reports\task23-t3-log-v6.txt`，帧 `reports\task23-t3\shots-v6\`） | `Space`/`Enter`/`Ctrl+1..3` 须有**可观测**效果（库状态变化 / 弹层 OCR）；`Ctrl+4/5/6` 须**逐像素零差异**。取帧必须 `PrintWindow(hwnd,hdc,2)`（`PW_RENDERFULLCONTENT`），`CopyFromScreen` 会被本机后台弹窗遮挡；焦点归属优先用**行为判据**，像素焦点环仅作辅助 |
| 像素判据 | `reports\task19-pixel-judge.ps1` | 逐像素比对标定，不靠肉眼「看着像」 |
| OCR 取证 | `reports\task17-ocr.ps1` | 屏上文字识别，作为「按键/点击真的生效了」的可观测结果 |
| 显示缩放取帧 | `reports\task21-frame.ps1 -Tag scale125\|scale100` | 需先坐实 `LogPixels` 改动**对 DPI-aware 应用生效**（记 `GetDpiForWindow` 前后值）；**测完必须恢复 144 并复测**。真实缩放需注销重登 ⇒ 只能由人工执行 |
| 越界比对 | `reports\taskN-forbidden-check.ps1`（每 Task 一份，配 `taskN-forbidden-baseline.txt`） | `VIOLATIONS=0` |
| 包内指纹 | `reports\task21-pkgcheck.ps1` | 逐文件字节数；⭐ 它给的 sha 列口径与 `Get-FileHash SHA256` 前 16 位**不一致**，台账引用时用它的字节数 |
| 覆盖安装真机验收（**当前唯一可用**） | `reports\task25-install\install-run.txt`、`pkg-7z-list.txt`、`exe-smoke-installed.txt` | 唯一可分发包 `/S` 静默装到 `D:\Program Files\practilog`，期望 `INSTALL_EXIT=0`；装后逐条核对 9 ttf + 4 OFL + `AssetManifest.bin` 1310 B + `app.so` sha16 `B3B8CDB737459798`；**`userdata` 四文件大小 + 哈希全部 SAME ⇒ 零丢失零迁移**；已安装件冒烟 `EXE_SMOKE: PASS` |
| 键条 7 条真机帧 + 判据（**当前唯一可用**） | `reports\task25-keybar-frame.ps1`、`reports\task25-keybar-judge.ps1`（→ `reports\task25-keybar-judge.txt`） | 跑**已安装件**并用 `--data-dir` 隔离真实 userdata；主判据 = **7 条中文标签逐条命中**（逐 item LCS ≥ 0.75），拉丁键帽 OCR 比值只作辅助；期望 `LABELS_OK=7/7`、`VERDICT=KEYBAR_7_HINTS_RENDERED` |
| T3 `Space`/`Enter` 端到端（**当前唯一可用 v8**） | `reports\task25-t3-v8.ps1`（由 `reports\task25-patch-v8.ps1` 打补丁产出；日志 `reports\task25-t3-log-v8.txt` / `-v8-cancel.txt`，帧 `reports\task25-t3\shots-v8*\`） | `MODE=CANCEL` ⇒ `EV1B_VERDICT=SPACE_CANCELS_DONE_ROW (done -> pending)`；`MODE=ENTER` ⇒ `EV2_VERDICT=CHECKBOX_TOGGLED_BY_ENTER (pending -> done, no dialog)`；**必须用 Windows PowerShell 5.1 跑**，且**每轮跑前把沙箱 `data` 目录改名挪走**（否则 `database disk image is malformed`） |
| 门禁（控制器亲跑单轮全量） | `reports\task25-gate.ps1`（→ `reports\task25-gate.txt`） | `analyze` 逐字 `No issues found!` + desktop 全量 + core_data 全量；**跑前先把 `apps\desktop\build\test_cache\build` 改名挪走**；期望 `GATE_VERDICT=PASS` |
| 四态字形像素判据（**当前唯一可用 v3**） | `reports\task29-glyph-judge2.py`（→ `reports\task29-glyph-judge2.txt`） | 锚点 = 条目**左缘 2px 竖条**（不是横向色带）；墨迹阈值 = **局部亮度** `thr=min(200, median(lum)-35)`（Rec.601），起点 `bar.x1+2`，同组桥接 ≤2 空列、断组 ≥3；cell 宽 >20px 直接判 FAIL **不静默截断**。期望 `BARS_FOUND=4`、四态 `notdef_box=False` 且 `capped=False`、`GLYPH_VERDICT=PASS`。⭐ v1（横向色带）误锚左侧导航栏、v2（色差容差 70）把 `○` 测成 1×1 —— **两版日志只作留档，不得引用为结论** |
| 抓屏桌面守卫 | `reports\task29-desktop-check.ps1`（→ `reports\task29-desktop-check.txt`） | `GetThreadDesktop` + `GetUserObjectInformationW` 取桌面名，期望 `VERDICT=ON_DEFAULT_DESKTOP`；**影刀(RPA)虚拟桌面内取帧全部失真** ⇒ 任何抓帧/截窗/UIA 取证前先跑它 |
| 四态真机种子 | `reports\task29-seed.py`（**stdout 直接返回，不落独立日志**；沙箱 DB 见 `reports\task29-sandbox2\practilog.db`） | 跑**装机件** + `--data-dir` 沙箱，造 plannedOpen / done / backfill / habit 各一条，期望 `SEED_VERDICT=PASS`；换轮次须先把整个沙箱 `data` 目录改名挪走 |
| 覆盖安装（**当前唯一可用**） | `reports\task29-install-over.ps1`（→ `reports\task29-install\task29-install-over.txt`） | 期望 `OVERALL=PASS` 7/7：7 个交付文件 sha256 逐位一致、用户 DB 未清、旧版残留 exe 已清、HKCU 卸载项 DisplayName 带构建时间戳、目录唯一 exe 即新包 |
| 门禁 CRLF / 写集口径 | `reports\task29-gate.ps1` + `reports\task29-crlf-baseline.txt` | 硬判据收窄为「**写集内 CRLF=0 + 存量文件只登记不改**」（改存量违反 R1）；期望 `PS1_VIOLATIONS=0`、`VIOLATIONS=0` |

---

## 4. 目录与工具索引

```
practilog/
├── AGENTS.md                     # 本文件：项目级唯一规范真源
├── CLAUDE.md                     # 兼容入口 → AGENTS.md
├── apps\desktop\                 # 正式 Windows Flutter 应用（刻意不进 Dart workspace）
│   ├── lib\src\pages\            # 页面（today_page 等）
│   ├── lib\src\widgets\          # 组件（priority_chips / shell\tool_rail 等）
│   ├── lib\src\theme\app_fonts.dart
│   ├── assets\fonts\             # 9 个 ttf + licenses\ 4 份 OFL（当前终态）
│   ├── test\                     # 全量基线 +215
│   └── build\test_cache\         # 跑全量前先把 build\ 改名挪走
├── packages\
│   ├── core_domain\              # 纯 Dart 领域模型（实体 / 枚举 / 不变量），无 IO
│   ├── core_db\                  # drift schema + 迁移 + oplog 写入层
│   └── core_data\                # 业务逻辑层（仓储 / 站会三段 / 心态 8 维 / 优先级视图），基线 +141
├── tools\
│   ├── bootstrap.ps1             # 幂等环境准备（找 SDK / 设镜像 / pub get；根解析失败自动退化逐包）
│   ├── gates\                    # G1–G4 + bad-fixtures（见 §3）
│   ├── build\                    # make_installer.ps1 / make_sfx.ps1 / installer.nsi
│   ├── installer\                # actlog_setup.iss / install_post.ps1
│   ├── verify\                   # 真机证据脚本（见 §3）
│   ├── icons\make_brand_icon.py  # 程序化生成 PNG + 多尺寸 ICO（发布链真源；旧脚本改名 make_app_icon_legacy.py 保留，不删）
│   └── codemod\                  # 一次性 codemod（历史遗留，勿在常规轮次跑）
├── docs\
│   ├── schema_v1.sql             # 数据模型，FROZEN @ P0-D2（14 表）
│   ├── B1_验收记录.md            # B1 验收台账：第 5 节遗留处置（#10/#11）+ §6 总体结论
│   ├── superpowers\plans\2026-11-07-b1-flutter-implementation.md   # 分 Task 计划（Task 21 = 6974 起）
│   ├── superpowers\specs\2026-11-07-双端交互体验设计.md            # 交互 spec（§H-1 :78）
│   └── 开发计划.md / 同步与备份方案.md / D1_技术选型结论.md …
├── .superpowers\sdd\2026-11-07-b1-flutter-implementation\
│   ├── handoff.md                # 跨会话交接（§16 为 Task 21 段，§16.8 最新权威）
│   ├── progress.md               # 逐步进度流水
│   └── task-NN-wN-brief.md       # 派工书 = 唯一实现契约
├── reports\                      # 全部真机证据、探针脚本、门禁日志、worker/verifier 报告
├── design-demos\                 # 视觉原型（TOKENS.md 是视觉口径唯一真源）
│   └── TOKENS.md                 # 只许改 §8；§1–§7 不动
├── release\                      # 安装包 + payload_* 解包目录（分发禁令见 R3）
├── .github\workflows\ci.yml      # CI：G1 / G2 / G3
└── pubspec.yaml                  # Dart pub workspace 根
```

**已知结构事实**

- `apps\desktop` **刻意不进** Dart workspace（用 path 依赖指向三个纯 Dart 包），它的 analyze/test 必须在 `apps\desktop` 内单独用 `flutter` 跑，**不进 G1/G2**。
- ⚠️ **`README.md` 的「已知问题」一节已部分过期，引用前必须实测。** 例：它至今仍写「根工作区因 `packages\core_domain\pubspec.yaml` 缺 `resolution: workspace` 而解析失败」，而 2026-11-10 实测三个包的 `resolution: workspace` **都已在位**。把历史状态当现状是这类文档最常见的坑。
- `reports\` 里 `task15-*` 到 `task21-*` 按批次命名；新批次沿用 `taskN-<主题>.<ext>`，脚本与它产出的 `.txt` 同名前缀，便于追溯。

---

## 5. 本机工具坑速查（踩过的，别再踩）

1. **`Set-Location` 之后**向新路径写文件 / 删旧路径文件会被本地硬安全策略拦 ⇒ 绝对路径、不切目录。
2. **`edit` 工具一次调用只吃一组** `old_string`/`new_string`；JSON 里重复键会**静默丢弃**（返回 `1 block(s)` 不代表 N 处都改了）⇒ 一次一处，改完 `grep` 逐处复核。
3. **`| Out-String` 捕获 flutter 输出**会整段丢失 ⇒ 用 `*>` 或脚本内部重定向。
4. **`Add-Type -MemberDefinition`、here-string 与参数同行、反引号续行** 均有失败形态 ⇒ 只有 `Add-Type -TypeDefinition $cs` 稳。
5. **`keybd_event(vk, 0, …)` 对 Flutter 无效** ⇒ 必须 `MapVirtualKey(vk, 0)` 传真实 scan code。
6. **`git commit -F -` 不吃 stdin** ⇒ 消息写临时文件再 `-F <file>`。
7. **`cmd` 脚本 `if (...)` 块里的裸 `)`** 会提前闭合代码块 ⇒ `.cmd` 里 echo 文本避免括号。
8. **7-Zip 真路径** = `C:\Program Files\7-Zip\7z.exe`（`C:\Tools\7-Zip\7z.exe` 不存在）。
9. **`FindWindow` 跨进程找自绘面板常返回 0**：面板/悬浮窗只随激活态短暂存在，用 `EnumWindows` 高频轮询，别读成「代码没生效」。
10. **合成输入触发 `TrackPopupMenu`**：先 `AttachThreadInput` + `SetForegroundWindow` 让**目标进程**成前台，再 10ms 高频轮询 `#32768`。
11. **DPI 非感知进程里 `GetWindowRect` 返回逻辑坐标** ⇒ 抓屏区域要乘 `GetDpiForWindow/96`；抓全虚拟桌面用 `CreateDC("DISPLAY")`。
12. **GDI 小尺寸 `Ellipse`** 会光栅化成四角星 ⇒ 用小圆点/圆角块用 `RoundRect` + 半径 = 半边长。
13. **改公式后像素零差异** ⇒ 先怀疑「度量 API 报错被吞导致那条分支没走到」，再怀疑公式。
14. **`GetGlyphOutlineW` 的 `MAT2` 不能传零矩阵**（16 字节，16.16 定点，单位矩阵 = `{0x10000,0,0,0x10000}`），否则 `GDI_ERROR` 静默回退。
15. **装完 / 重启后立刻跑桌面自动化探针会假失败**（`WHOLE_PANEL_DIFF=0` = 点击没送达）⇒ 先分「输入没送到」还是「逻辑错」，同一二进制重跑一次再判。
16. **真机取帧只能用 `PrintWindow(hwnd, hdc, 2)`**（`PW_RENDERFULLCONTENT`）：本机有 RPA 后台弹窗，`CopyFromScreen` 抓到的不是目标窗口。
17. **别拿 `Ctrl+1` 当键盘走位恢复键**：切页会**重置焦点** ⇒ 走位原地打转（实测 60 格 diff 严格 3 周期）；**别在导航控件上按 `Space`**（会切页）。
18. **像素判据要先自证「看得见目标」**：22×22 焦点环判据**判不出行级焦点**（行级 `Focus` 根本没有焦点环）⇒ 焦点归属优先用**行为判据**（库状态变化 + 弹层 OCR），像素只作辅助。
19. **同一沙箱连跑两轮探针 ⇒ `database disk image is malformed`**：探针 `Copy-Item -Force` 覆盖 `practilog.db` 时，上一轮 app 留下的 `-wal`/`-shm` **不会被清掉**（种子目录里本来没有 wal）⇒ 新 db 配旧 wal ⇒ sqlite 报错。**修法**：每轮跑前把整个沙箱 `data` 目录**改名挪走**（不删），别只覆盖 db。
20. **勾选框的焦点环在「已勾选」态不可见**：`FocusRing` 是 `Positioned.fill` 的 2px 墨边叠在控件上，勾选后中心是实心墨 ⇒ 「空心 22×22 环」判据必然失效。焦点环**只能在未勾选态定位**；`done→pending` 方向要用「两次 Space + 中间查库证明前态」，不能拿 done 种子直接定位。
21. **同一个 pending 行会被渲染两份**（「今日优先」站会卡片 + 计划列表）⇒ OCR 标题有多个命中 ⇒ 几何判据必须取**最近**的一次命中（≤30 px），不能只留第一份。
22. **PowerShell 5.1 按 ANSI 读 `.ps1`** ⇒ 脚本里写中文字面量会乱码。判据脚本里的中文 needle 一律**码点构造**（`[char]0x624B` 等），保持文件纯 ASCII。
23. **OCR 会误识 CJK 与拉丁**（`选`→`远`、`未`→`耒`、`Ctrl+D`→`Ct`、`Space`→`Sgace`、`Enter`→`EntE0`）⇒ 用**逐 item LCS 比例 ≥ 0.75**，别用精确串匹配；主判据放中文标签，键帽只作辅助。
24. **参数名与列表变量重名会静默串型**：`param([string]$Out)` + `$out = New-Object List` ⇒ `$out.Add()` 报「String does not contain a method named 'Add'」（PowerShell 变量名大小写不敏感）⇒ 改名即可。
25. **`sha16` 要写清是哪套算法的截断**：台账里的 `417BDAAF2ABA60DE` 是 **SHA256** 前 16 位，SHA1 前 16 位是 `D3DF851B50E6AA05`；两者同时出现**不是**「内容不一致」，别误判成两个不同文件。
26. **mtime 变动不证明内容被改**：worker 做 R5 变异自证后把文件还原 ⇒ mtime 变、sha256 不变 ⇒ 判「有没有改」一律用**哈希**，mtime 只作辅助。
27. **别用「搜不到引用」反推「脚本已退役」—— 本轮就栽在这里**：Task 27 与本轮初版结案都断言 `tools\build\installer.nsi` 是死脚本、分发包来自 `tools\installer\practilog_setup.iss`，**实测全错**。判分发包家族要看**产物字节**：`[System.Text.Encoding]::GetEncoding(28591).GetString([System.IO.File]::ReadAllBytes($exe))` 后查 `Nullsoft` / `INSTALLSYSTEM` / `InnoSetupLdr` —— 唯一可分发包 `NULLSOFT=True` / `InnoSetupLdr=False`，再与 `.superpowers\installer_build_report.txt` 的 `out_file` + `compression = SOLID lzma (SetCompressor in installer.nsi)` 互证 ⇒ **`installer.nsi` 是唯一在跑的打包器，`.iss` 才不参与打包**。当初「`makensis` 零命中」是因为把搜索写成**小写字面量**，漏掉 `$Makensis` 变量与 `make_installer.ps1` 的 `param` 默认值 ⇒ **搜小写工具名会漏 PascalCase 变量和参数默认值**。**卸载残留 `HKLM32\SOFTWARE\PractiLog\InstallDir` 的真因不是脚本逻辑**：`installer.nsi:274` 的 `DeleteRegKey HKLM32` **存在且正确**，失败是因为静默卸载（`/S`）跑在**未提权**上下文，HKLM 写入/删除被系统拒绝且**静默失败** ⇒ 这种键**无对象可修**，只能收敛判据（并在探针打印 `LEGACY_FOSSIL_IGNORED=1` 留痕）或改以管理员身份跑卸载器。附带两条硬纪律：**「卸载后程序文件已清除」不能用重装后的实时 `Test-Path` 判**（必假红，须卸载后立刻冻结快照变量再断言）；**`$PROGRAMFILES64` 之外还有 `installer.nsi:143-144` 的 `D:\*.*` 分支** —— 本机有 D 盘 ⇒ 装到 `D:\Program Files\practilog` 是**确定性行为，不是化石**。
28. **症状：`python xxx.py | Out-File log.txt` 报 `PermissionError: [Errno 13] Permission denied`（脚本自己也在写同一个 log）**。真因：PowerShell 的 `Out-File` 先打开并持有该文件句柄，脚本内 `open(LOG,'w')` 撞句柄。**正确做法：不要重定向**，让脚本自写日志；需要吞掉 stdout 用 `*> $null`。判据本身可能已经 PASS —— 别把「写日志失败」读成「判据失败」。
29. **症状：小尺寸汉字的墨迹测量「看起来对但数字不对」**。色差容差（`|ΔRGB| ≤ TOL`）在 144 DPI 下会把 `○`（U+25CB 空心圆）测成 1×1 假读数，因为细环与背景色差不足。**正确做法：墨迹判据用局部亮度阈值**（Rec.601 `lum`，`thr=min(200, median(lum)-35)`），并让**锚点**取自结构性特征（2px 左缘竖条）而非颜色聚类，否则会锚到左侧导航栏。读数不忠实（`ink` 远低于阈值应有值）必须原样上报，不得为过判据改阈值。
30. **症状：`edit` 报 `Could not find the exact text`，而文本是刚从 `read` 里抄的**。真因两种：① 长行在 `read` 显示里被**软换行**，人眼拼接出来的 `\n` 位置与文件不符；② 引用块 `>` 前缀、表格 `\|` 里的行内换行被凭记忆补上。**正确做法：编辑前重读该区间、只取一次读到的原文；同一文件的多次改动分次调用，每调用一组 old/new**（一次调用塞重复键只会生效最后一处）。
31. **症状：手一抖把仓库根拼错，凭空建出「影子仓库」**。2026-11-11 实测：在 `F:\soft\00selfmake\practilog`（**`00selfmake` 少一个 `d`**）下建出了 `reports\task21-stat.ps1` 等产物，又建了 `F:\soft\00selfmade\practilog.superpowers`（**多一段 `.superpowers`**）。两处都在**仓库之外**，且目录名与真仓库高度相似 ⇒ 极易被后续会话当成真根。**根因不是工具 bug，是路径字符串手拼**。**正确做法**：① 建目录 / 写文件前，把目标路径与仓库根做**逐字符比对**，路径中出现 `00selfmake`（缺 `d`）⇒ 立刻停；② 仓库根之外出现 `practilog*` 同级目录 ⇒ 视为越界；③ 建完 `Test-Path` + 打印父目录回读确认；④ 越界产物**改名挪回**（`Move-Item` 改名，不删）并留证。事后清理脚本见 `reports\stray-path-cleanup-20261111.ps1`（日志 `.txt`，`STRAY_CLEANUP_VERDICT=PASS`），留证目录 `reports\_stray-path-artifacts\`；事后复核结论见同一日志 `POST-VERIFY` 段（`STRAY_CLEANUP_POST_VERIFY=PASS` = 原两路径不存在 + 实体文件零丢失 + 仓库完好）。
32. **症状：清理完再枚举父目录，同一条查询在 1 分钟内返回两个不同子集**（本轮实测：`{practilog.__stale_20261111-1725}` 与 `{practilog.superpowers.__stale_20261111-1725}` 轮换出现，而仓库自身 46 个顶层项始终稳定）。真因**未坐实**（疑似该父目录存在并发改名进程 / 目录索引抖动 —— 同级另有 `sigma-batch-rename` 等批量改名项目）。**正确做法**：① 判「某路径存不存在」一律用**直接路径解析**（`Get-Item -LiteralPath` / `Test-Path -LiteralPath` / `[System.IO.Directory]::Exists`），**不要用父目录枚举反推存在性**；② 父目录枚举须**连续 3 次一致**才采信；③ 判「内容有没有丢」用**递归搜索 + 回收站**两路都查；④ 残留目录若为空，如实写「空目录」，不要写成「已归档全部内容」。

---

## 6. 权威文档导航（哪件事以谁为准）

| 想知道 | 看这里 |
|---|---|
| 长期约束 / 装置位置 | 本文件 |
| 数据模型 | `docs\schema_v1.sql`（FROZEN，14 表） |
| 要做什么、做到哪一步 | `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md` 的对应 `## Task NN:` 段 |
| 某个 Task 的实现细节契约 | `.superpowers\sdd\...\task-NN-wN-brief.md`（**比计划正文优先**） |
| 跨会话交接、最近一次结论 | `.superpowers\sdd\...\handoff.md`（§16.8 = Task 21 最新权威） |
| 验收台账、遗留登记 | `docs\B1_验收记录.md` 第 5 节 + §6 |
| 视觉口径 | `design-demos\TOKENS.md` §1–§7（只许改 §8） |
| 交互裁定 | `docs\superpowers\specs\2026-11-07-双端交互体验设计.md`（§H-1 :78 = 未来日只可预排） |
| 真机证据 | `reports\taskN-*.txt` / `*.md` / `*.log` |
| 历史进度流水 | `.superpowers\sdd\...\progress.md` |

**冲突时的优先级**：用户当轮决定 > 派工书 > 计划正文 > handoff / progress > README。
**证据冲突时**：实测 > 运行时产物 > 源码阅读 > 文档转述。

---

## 7. 当前状态快照（2026-11-12 凌晨，Task 35 收口后）

- **Task 35（2026-11-12 凌晨）已完成「开源入库 + 循环任务 + 四维优先级标记 + 去页头标题」四项用户指令**。**开源入库**：仓库 `https://github.com/kizemo/actlog`（public / `main`），`main` = `f460fc4`（`ls-remote` 一致、`## main...origin/main` 不领先不落后），`TREE_FILES=299`；流程用 `init -b main` → `remote add origin` → `fetch` → `reset --soft origin/main` 把首提交挂在远端 `d03ce96 Initial commit` 之上（**未 force-push**），垃圾文件用 `git rm -r --cached -f` 清索引、磁盘文件按 R4 保留（302→299）；`.gitignore` 80 行（补 `__pycache__/` `*.pyc` `*.pyo` `*.obj`）；在版图书全文 `高绩效人士的五项管理_全文.md` **不入公开仓库**（本地保留），README「诚实说明」写明。`README.md` 全文重写 21488 B / 340 行（13 个二级标题、11 个链接逐一 `Test-Path=True`、不嵌图），单测数字校正为 151。**循环任务**：新表 `recurring_task`（`weekday_mask` 周一=bit0…周日=bit6、`start_minute` 0–1439、`duration_minutes`、`active`、`deleted_at`）+ `recurring_occurrence`（`UNIQUE(task_id, date)` 幂等），`currentSchemaVersion` 1→2，物化时机 = 应用启动 + 选中日期变化；右轨「习惯速览」下方新增「循环任务＋」模块。**四维优先级标记**：4 枚芯片分两组【重要/不重要】【紧急/不紧急】，映射既有 `Quadrant` Q1–Q4，标记 `▲`/`▽`/`◆`/`◇` 渲在计划**名称前面**，`quadrant == null` 不渲染不留位，**零 schema 变更**。**去页头**：删 `_PageHead` + `_ModeSwitch`（今日 / 日期 / 星期 + 完整 / 极简），保留 `log.mode` / `dayModeMinimal` 数据语义与 `DayGrid(minimal:)`。**门禁九步全绿**：`analyze` 逐字 `No issues found!` / desktop **+328** / core_data **+151** / core_db **+71**（本轮**首次**纳入门禁）/ 三包 `dart analyze` 逐字干净 / G3 `0 FAIL` / `FLUTTER_LOCK_SEEN=0` / 越界 `VIOLATIONS=0`（`reports\task35-forbidden-check.txt`）。**越界判据必须每轮新写**：`task34-forbidden-check.ps1` 的基线绑 Task 34 brief mtime、白名单绑 Task 34 写集 ⇒ 对本轮必然假红 23 条；本轮新建 `task35-forbidden-check.ps1`，基线固定 `2026-11-11T23:30:00`。**包**：`release\actlog-Setup-1.0.0_20261112-000947.exe`（15818676 B / sha16 `6CDFAA16D8D23130`）唯一可分发，包内 `app.so` sha16 `4B756691A48DA94A` 与构建产物逐字相同。**踩过的真坑**：`make_installer.ps1` **只打包不编译**，首包 `…_000727.exe` 打成 Task 34 旧代码（`app.so` 仍是 `D9ACE771340DF3F3`、体积与旧包逐字节相等）⇒ 已降为坏包；见 R3。**遗留**：① 真机目视未做（四维字形真机不缺字、循环任务自动填充）② `docs\` 不改 ⇒ 无 `schema_v2.sql` 第二份 DDL 对照，`schema_consistency_test` 改用「v1 十四张逐项比对 + 白名单放行两新表 + 索引集合校验」③ 计划历史未勾项 `7041` 仍挂账 ④ `progress.md` 仓库根不存在 ⑤ 旧库分叉与问卷 `ask_bc0b98b4aaab7c72b85afe28` 仍未拍板/未回收。详见 `handoff.md` §28。

- **Task 34（2026-11-11 深夜）已完成「安装目录改名 `actlog` + 顶栏去英文 + 右轨两模块拆分」**。**目录**：`installer.nsi` 加 1d 迁移段 —— 旧目录存在且新目录不存在 ⇒ `ClearErrors` + `Rename`（**同盘整目录改名、逐字节不变、零删除、`userdata` 原地保留**）；目标已存在 ⇒ robocopy 只复制程序文件、旧目录保留不删；失败 ⇒ 回退旧目录就地安装并弹框。真机 `INSTALLER EXIT=0`、`OLD_DIR_EXISTS_AFTER=False` / `NEW_DIR_EXISTS_AFTER=True`、轨迹 `ACTLOG_MIGRATE=RENAME_OK D:\Program Files\practilog -> D:\Program Files\actlog`、`USERDATA_HASH_SAME=1`。**界面**：顶栏删掉 logo 右侧 `actlog` 字并新增 `kBrandMarkTopGap=12` 顶部留白（`kTopBarHeight=32` 未动）；右轨自上而下改为「待办列表＋」「习惯速览＋」「闭环提示」「快捷键」，两模块右上角各一枚加号弹窗（习惯侧新建 `habit_quick_dialog.dart`），旧「拖入时间轴」混合模块删除、习惯拖拽源搬到 `HabitOverviewPanel`（key `overview-habit-<id>`）。**门禁**：`analyze` 逐字 `No issues found!` / desktop **+312** / core_data +141 / 越界 `VIOLATIONS=0`（`reports\task34-gate.txt`）。**包与装机**：`release\actlog-Setup-1.0.0_20261111-225703.exe` 已于 Task 35 降为历史包（见 R3）；真机目检须先断言 `FG_MATCH` 再取帧。**账本零丢失**：整目录 `Rename` + 装机器 BEFORE/AFTER 对拍 + 停进程后 `sqlite3` 逐库 dump（`reports\task34-ledger-audit.txt`）；三库唯一有内容的记录 = 计划项「中国」（11-07 / `done`）逐字一致、所有 `day_log` 内容列长度皆 0 ⇒ 无用户文本丢失；**「改名未改库字节」只能由 BEFORE/AFTER 对拍 + 同盘 `Rename` 支撑，禁用 mtime**（SQLite 打开/checkpoint 会改 mtime 与哈希）。**遗留**：旧库另有 2 条空壳 `day_log` + `rev` 差异 + `oplog 17 vs 8`，**成因未坐实、不下结论**；合并需写 live 库、不可逆 ⇒ 待用户拍板。详见 `reports\task34-closeout.md` 与 `handoff.md` §27。

- **Task 33（2026-11-11 晚）已完成「全面改名 `actlog` + 图标闭合 + GitHub 仓库改名」**。**GitHub**：`kizemo/PractiLog` → **`kizemo/actlog`**（public / main，旧 URL 自动重定向）。**改名**：81 文件机械改名（`package:practilog/`→`package:actlog/`、`PractiLog`→`ActLog`、`PRACTILOG`→`ACTLOG`、`practilog`→`actlog`），含 exe 名 / 注册表键 / Dart 包名类名 / 环境变量 / 文档；`installer.nsi` 全量重写（`.onInit` 就地升级段复用旧目录）；**旧数据目录 / `practilog.db` / 旧 `PRACTILOG_*` 环境变量新旧并存**（新为主 + 旧兜底 + 首启搬迁），中文「知行日志」保留；13 条 legacy 兼容测试锁死契约。**图标**：任务栏旧样 = **Windows 图标缓存 + 旧进程持旧映像（非代码 bug）**，重启 explorer 后成对帧差异带 `x=1359..1466` `green 180 → 0`、navy `4479 → 7410` ⇒ **Task 32 遗留「像素目检未判定」闭合**；app 左上角旧样 = `_BrandMarkPainter` **自绘方框**（真 bug）⇒ 改 `Image.asset('assets/brand_mark.png')`，真机目检 = I03 三瓣「a」标记 + `actlog` 字样。**门禁**：`analyze` 逐字 `No issues found!` / desktop **+306** / core_data +141 / 越界 `VIOLATIONS=0`。**包与装机**：`release\actlog-Setup-1.0.0_20261111-220332.exe`（15778514 B / sha16 `169D24D160ACA4D5`）唯一可分发；`INSTALLER EXIT=0`，旧 `practilog.exe` 已删、`userdata` 四文件哈希保留（**账本零丢失**）。**遗留**：本机安装目录名仍为 `D:\Program Files\practilog`（为保账本复用旧目录；全新机器用 `actlog` 目录）。详见 `handoff.md` §26。

- **Logo 设计稿已推进到 Set I（2026-11-11，本轮）**：`design-demos\logo-set-i-bowl-overlap-2026-11-11\`（用户当轮要求在 Set H 的 **H01** 基础上「把最左边的圆圈向右移动、与竖线产生叠加、圆圈用深蓝色描边、压住竖线一部分」，**只动碗的位置/颜色/层序，其余部件逐字不动**，出 3 则）自含构建器 `build_bowl_overlap_i.py`，几何审计**越界合计 = 0**、碗→三角净距 38/26/34 均正（未顶到播放三角）、三角内孔 33×36 与 H01 同；产物 9 SVG + 9 PNG + 3 ICO（7 档）+ `geometry-audit.txt` / `overlap-measurement.txt` / `preview.png` / `zoom-crossing.png` **已读图目检**。三则 = `I01-bowl12-ink-halo` / `I02-bowl24-navy-halo` / `I03-bowl36-navy-hard`，最低可用尺寸 **64 / 48 / 48**。**本轮两条关键结论**：① 目检坐实 **`halo 让位` 与 `压住` 互斥** ⇒ 带 halo 的 I01/I02 读不出「压住」，**只有 I03（无 halo 硬压）真正盖住竖干**，推荐随之由 I02 改为「压住为硬要求 ⇒ I03」；② 修掉 `bite_depth()` 解析式**多减一个 HALF** 的真 bug（原把「咬进 12px」报成「够不着 12px」），并**如实披露分色判据自身的饱和假象**（同族深蓝 ⇒ 碗为墨色的 I01 也量到 navy 23/7/2px，小档位绝对计数不可信，须配目检）。待拍板 5 项（含深蓝 `#0E2A4A` 是否破两色契约、交付稿改用纸底片）详见 handoff **§25.9** 与该目录 README。
- **（承前）Logo Set H（2026-11-11）**：`design-demos\logo-set-h-alog-playtriangle-2026-11-11\`（基于用户手稿 `log_design.png` 的小步优化：**al 连字 + 轮廓播放三角 + g + 通到底账行**，6 则）自含构建器 `build_alog_h.py`（`CANDIDATES` 唯一真源，README 由实参生成），几何审计**越界合计 = 0**；产物 12 SVG + 12 PNG + 6 ICO（7 档 256…16）+ `preview.png` / `sizes-proof.png` / `compare-ref-vs-h01.png` / `draft-colorway.png` / `ico-frames-proof.png` / `zoom-small-sizes.png` **六张证据图已读图目检**（结论见该目录 README「目检结论」节）。**描边 56 → 48 是本轮唯一结构性改动**（56 时轮廓三角内孔只剩 12×13 px、ICO 256px 档仅 2×2 px ⇒ 本轮唯一结构性新增完全失效；48 ⇒ 实算 33×36 / 像素实测 32×34 px，ICO 256px 档 8×7 px）；**最低可用尺寸改用 ICO 逐档像素实测校核**（H01–H04/H06 = 64px，原宣称 48px 不成立；H05 = 32px）。待拍板 6 项（承 Set G 的 5 项 + **新增第 6 项：底片是否改用暖灰褐 #867668**，本轮交付件仍用墨片 + 纸描边，暖褐只出对照图）；**应用侧改名上机仍未派工**（R1 禁改 `apps\**`），当轮唯一可分发包是 `release\PractiLog-Setup-1.0.0_20261111-113143.exe`（**Task 33 起已由 `actlog-Setup-1.0.0_20261111-220332.exe` 取代，见 R3**）。详见 handoff §25.8。
- **Logo 设计稿已推进到 Set G（2026-11-11，本轮）**：`design-demos\logo-set-g-alog-ligature-arrow-2026-11-11\`（用户三条改动：去 a 顶横 / a-l 连字并留实算分界 / o 变右向三角）6 则，自含构建器 `build_alog_g.py`（`CANDIDATES` 唯一真源，README 由实参生成），几何审计**越界合计 = 0**，产物 12 SVG + 12 PNG + 6 ICO（7 档 256…16）+ `preview.png` / `sizes-proof.png` / `compare-f04-vs-g01.png` 三张证据图**已读图目检**（结论见该目录 README 的「目检结论」节）。待拍板 5 项不变（点 1–3 进精修 / ICO 墨片 vs 纯形蒙版 / 底片圆角 6.25% vs 10–15% / 深浅双底两套 ICO / 中文名「知行日志」去留）；**应用侧改名上机仍未派工**（R1 禁改 `apps\**`），当轮唯一可分发包是 `release\PractiLog-Setup-1.0.0_20261111-113143.exe`（**Task 33 起已由 `actlog-Setup-1.0.0_20261111-220332.exe` 取代，见 R3**）。详见 handoff §25.7。
- **Task 29（2026-11-12 上午）已交付方格时间轴四态「形状 + 文字」双通道**。写集 6 文件（`slot_state.dart` 三个纯函数 `glyphOfSlotKind` / `stateLabelOfSlotKind` / `foregroundOfSlotKind`、`app_tokens.dart` 四态前景色、`day_grid.dart` 2px 左缘竖条 + 字形 + 状态词 + done 标题删除线、两份测试、`design-demos\TOKENS.md` §8.2），**零 schema 变更、`packages\**` 零改动、零新依赖**。字形口径：`○`U+25CB / `✓`U+2713 / `●`U+25CF / 回填 `▶`U+25B6（`▸`U+25B8 因 9 个随包 ttf **零覆盖**而禁用），字形必须用 `RichText` 而非 `Text.rich`（后者会污染 `ledger_checkbox_enter_test.dart` 的 `find.text('✓')` 计数）。门禁：`flutter analyze` 逐字 `No issues found!` / desktop 全量 **+280** / core_data **+141** / 越界 `VIOLATIONS=0`；**独立 verifier VERDICT=PASS**。**已重打包**：包内 `app.so` `19590D97EE2A0430`，真机覆盖安装 `OVERALL=PASS` 7/7，四态像素判据 v3 `GLYPH_VERDICT=PASS / FAIL_COUNT=0`（锚点 = 2px 左缘竖条、墨迹 = 局部亮度阈值；v1/v2 判据已废弃，只留档，**不得引用为结论**）。详见 `reports\task29-closeout.md`。
- **Task 28（2026-11-12 凌晨）已交付 APP 八项界面改造 + 遗留 #18 结案**。产品代码大量改动（新建 `apps\desktop\lib\src\widgets\timeline\` 八个文件 + `pages\habits_page.dart`；改 `app.dart` / `providers.dart` / `date_bar.dart` / `today_page.dart` / `todo_pool_page.dart` / `nav_rail.dart` / `theme\app_tokens.dart`，重指 13 个既有测试文件）⇒ **已重打包**。唯一实现契约 = `docs\superpowers\plans\2026-11-12-b2-grid-timeline.md`（T1–T13 已全打勾，声明与 B1 计划冲突时本文件优先）。**门禁三条全绿**（`flutter analyze` 逐字 `No issues found!` / desktop 全量 **+269** / core_data **+141** / 越界 `VIOLATIONS=0`）。**独立 verifier 首轮判 A 项 FAIL**（八项落实 3 处缺陷：回填未默认打勾、习惯拖入不弹窗、声明 6 个测试实为 4 个），worker 返工后三项闭合。**真机覆盖安装验收 `OVERALL=PASS` 7/7**（`INSTALL_EXIT=0`；37 → 37 文件；`app.so` `0882787DA90430DB` → **`90EAF4A50B7FECFE`** 与包内校验逐字一致 ⇒ 新代码确已上机；`userdata` 四文件大小 + 哈希全 SAME；`ADDED=0 / REMOVED=0`）。详见 `reports\task28-closeout.md`。
- **Task 27（2026-11-10 深夜）已用唯一可分发包做完「覆盖安装 + 卸载 + 重装」全链路真机验收**。**零产品/测试代码改动**（`apps\` 与 `packages\` 零写入、越界 `VIOLATIONS=0`）⇒ **未跑门禁、未重打包**，门禁数字沿用 Task 26 实测、唯一可分发不变。覆盖安装 `INSTALL_EXIT=0`（37 → 37 文件、`45370676` B 前后同、**唯一变化 = `data\app.so`**、`ADDED=0 / REMOVED=0`）、`userdata` 四文件大小 + 哈希全 SAME；装机件烟测 `EXE_SMOKE: PASS`、键条 `LABELS_OK=7/7`；静默卸载后目录只剩 `userdata` 四文件且哈希逐一相同、重装后 37 文件与 `app.so` sha16 `0882787DA90430DB` 全部恢复、复跑烟测 PASS。**12 项判定 11 PASS / 1 FAIL**，唯一 FAIL = 卸载后残留 `HKLM32\SOFTWARE\PractiLog\InstallDir`（登记第 5 节 **#18**，判据 vs 设计二义，未修）。详见 `reports\task27-closeout.md`。
- 真机验收口径（本轮确立，以后照抄）：**「卸载后程序文件已清除」不能用重装后的实时 `Test-Path` 判**（重装会把文件放回来 ⇒ 必然假红），必须卸载后立刻冻结快照变量；**越界基线取「本轮顶层产物的最早 mtime」**，不能拍时钟点、也不能对整目录递归取 `Min mtime`（备份目录保留原始 mtime 会把基线拉到一周前）。

- **Task 26（2026-11-10 晚）已闭合台账第 5 节 #17：计划行行级焦点补上可见焦点环**。复用既有 `FocusRing`（`--ink` 2px，**零新增视觉口径**、`design-demos\TOKENS.md` 逐字节未改）；「就近优先」用 `FocusManager.instance.primaryFocus == node`（父子不双亮）；**键位语义零回退**。写集 3 文件（`focus_ring.dart` / `today_page.dart` / 新建 `plan_row_focus_ring_test.dart`）。详见 `reports\task26-closeout.md`。
- 门禁实测（**Task 26 收口轮，控制器亲跑** `reports\task26-gate.ps1` → `reports\task26-gate.txt`）：`flutter analyze` 逐字 `No issues found!`；desktop 全量 **+231**（+225 基线 + 新增 6 条断言，零回退）；core_data **+141**；越界 `VIOLATIONS=0`。**独立 verifier VERDICT: PASS**（11 PASS / 0 FAIL / 3 UNVERIFIED，0 blocker / 0 major）。
- （**Task 29 时点的**唯一可分发安装包；**现已由 Task 30 的 `…_20261111-113143.exe` 取代，见 R3**）唯一可分发安装包：**`release\PractiLog-Setup-1.0.0_20261111-090809.exe`**（15742832 B / sha16 `99D1E949E507D0A5` / mtime 2026-11-11 09:08:42；R3）。**Task 29 四态双通道 ⇒ 已重打包**；包内 `app.so` sha16 `19590D97EE2A0430`（≠ Task 28 的 `90EAF4A50B7FECFE`）且 9 个字形码位探针均有命中（`reports\task29-pkgcheck-console.txt` PKG_VERDICT=PASS）⇒ 新代码确在包内；**已用它完成真机覆盖安装验收 OVERALL=PASS 7/7**（`reports\task29-install\task29-install-over.txt`，装机 `app.so` `90EAF4A50B7FECFE` → `19590D97EE2A0430`）。**Task 28 包 `…_20261111-013828.exe`（15740862 B / sha16 `9FF92CF78678F1D6`）自 Task 29 起降为历史包**（不含四态双通道）。`release\` 下另有 **11 个历史 exe 严禁分发**（含 `…_214615.exe` 与作废的 `…_011717.exe`）—— **该计数为 Task 29 时点；2026-11-11 实测现为 14 个 exe / 13 个禁止分发**。
- 计划文件 Task 26 段 S1–S8 已按 R6 等长打勾（`337107` B / `7158` 行不变，sha16 `B0240D06E45B338F` → `44207C6AA70414BE`）；**全文件残留未勾仅 `7041`（T2 真实 125%/100% 显示缩放取帧）** —— 登记 `docs\B1_验收记录.md` 第 5 节 **#10 / #13**；唯一补法是用户**注销重登**后跑 `reports\task21-frame.ps1 -Tag scale125|scale100`。
- **Task 25（2026-11-10 晚）已闭环 `handoff.md` §19.4 的第 2 / 3 项**：② 覆盖安装 `D:\Program Files\practilog` 并真机验收 **PASS**（`INSTALL_EXIT=0`；装后 37 文件、`AssetManifest.bin` **1310 B**、`app.so` sha16 `B3B8CDB737459798`；**老库四文件大小 + 哈希全部 SAME ⇒ 零丢失零迁移**；已安装件冒烟 `EXE_SMOKE: PASS`；键条 7 条 `VERDICT=KEYBAR_7_HINTS_RENDERED`）；③ `Space` 取消勾选 `done→pending` 与 `Enter` 落勾选框（`pending→done`、**不开**回填弹层）**真机取证 PASS** + widget 层净增 6 条断言。详见 `reports\task25-closeout.md`。
- 字体终态：9 个 ttf（Fraunces ×3 / Inter ×3 / JetBrainsMono ×2 / `NotoSansSC-Regular.ttf` 10596412 B）+ `licenses\` 4 份 OFL。**装机件已验证带上随包字体**（装前 `AssetManifest.bin` 267 B 无字体 → 装后 1310 B；运行时标题为无衬线黑体）—— 但**字形级唯一归因未做**，台账不得吹大成归因到某个具体 ttf。
- 仍欠遗留：第 5 节 **#10 / #13**（T2 真实显示缩放）、**#12**（M21-1 未来日预排条目不可编辑，需先改 spec §H-1）。**#18 已于 Task 28 按选项 ① 结案**（承认「记住上次安装目录」属设计内行为：`HKLM*\SOFTWARE\PractiLog` 已移出验收判定集，`DIRCOMPAT_32` 只作信息打印；选项 ②「修 `DeleteRegKey` 并重打包」被否决 —— 实测 `installer.nsi:274` 的删除行本就正确，真因是卸载器未提权时系统静默拒绝，无对象可修，为清一个兼容指针而给卸载路径加 HKLM 提权删除会打掉「卸载器可静默运行」。详见 `reports\task28-reg18-decision.md`）。**Task 29 另登记 7 条遗留**（9 处 CRLF 存量只登记不修、未做 hover/press 交互态与窄视口取证、未做多字体族与真实 125%/100% 显示缩放取帧、全量 widget 目视抽查未做、无 git 基线），详见 `reports\task29-closeout.md`。
- 待办两项决策（用户拍板前不动手）：**T2 真实显示缩放处置**、**M21-1 未来日预排条目可编辑性**（#14 / #15 / #16 已按 Task 22 裁定登记为 B2 候选或只登记；**#18 已结案、移出待办**）。Task 29 的 7 条遗留里，**#6 像素级对比度 / #7 date_bar 窄视口 / #8 隐式时钟契约** 已由用户当轮拍板「本轮不连带做」⇒ 只登记、不是缺陷。

---

## 8. 维护本文件

- 只写**长期成立**的东西。任何会随 Task 变化的具体数字，指到真源文档，别抄进来。
- 新增装置（探针/门禁）就进 §3 表格；新增坑就进 §5，并按「症状 → 真因 → 正确做法」一行写完。
- 本文件的改动由控制器做，属台账写集，**不进 worker 写集**。