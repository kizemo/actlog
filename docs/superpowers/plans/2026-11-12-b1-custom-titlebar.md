# Task 30 · 自定义顶栏（去 Windows 原生标题栏）— 实施计划

- 日期：2026-11-12
- 派工书（唯一实现契约，R8）：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-30-w1-brief.md`
- 前置：Task 29 四态双通道已全链闭合（analyze 逐字 `No issues found!` / desktop +280 / core_data +141 / 真机 7/7）。
- 用户当轮决定（最高权威）：不要 Windows 风格原生顶部蓝条，顶部与 UI 区自然融合；本轮同时产出 9 个 logo 候选（另行落 `design-demos\`）。#10/#13 继续拖后。

## 1. 目标

去掉原生 Windows 标题栏，用应用内自绘顶栏承载「拖拽 / 最小化 / 最大化-还原 / 关闭」，
顶栏底色与 `LedgerPaper` 同用 `--paper #F6F4EF`，无分隔线，视觉与主 UI 无缝融合。

## 2. 技术路线（本轮实测敲定，勿另起炉灶）

- window_manager 0.6.0 **legacy 桥** `TitleBarStyle.hidden`：
  - 原生层保留 `WS_CAPTION/WS_THICKFRAME` 与 DWM 合成边框 ⇒ 圆角/阴影/贴边缩放/任务栏预览/Win11 snap layouts 全部不受影响；
  - 仅经 `WM_NCCALCSIZE` 把顶部非客户端带让给内容；顶边仍可拖拽改大小（HTTOP）；
  - 证据：`cnativeapi-0.5.10\cxx_impl\src\platform\windows\window_windows.cpp` :2290-2293
    注释明确「hidden + 应用自绘标题件是 Windows 全幅窗的正路」。
- legacy 桥可用性实测：`window_manager-0.6.0\lib\src\legacy\window_manager.dart`
  `setTitleBarStyle` :541-548、`WindowOptions.titleBarStyle` 于 initialize 自动应用 :143-145、
  `startDragging` :693-694；`window_options.dart:34`。
- **零新增依赖、零 runner（`windows\**`）改动、零 C++ 改动。**
- 关闭语义复用既有链：`setPreventClose(true)` + `onWindowClose → windowManager.hide()` 隐藏到托盘；
  `_trayReady` 兜底逻辑不动。窗口管理原生通道在当前 exe 已验证现役（Task 23 + exe_smoke）。

## 3. 里程碑

| 阶段 | 内容 | 责任 | 判据 |
|---|---|---|---|
| M1 | W-1 派工实现（顶栏组件 + titleBarStyle.hidden + 挂载 + 测试） | worker | 派工书 T1–T7 逐条自检 |
| M2 | 门禁复核 | 控制器亲跑 | analyze 逐字 `No issues found!`；desktop ≥ +280；core_data +141 不动 |
| M3 | 打包 | 控制器 | `tools\build\make_installer.ps1` 产出新包，登记唯一可分发 |
| M4 | 真机取证 | 控制器 | 先 `reports\task29-desktop-check.ps1`（Default 桌面）；PrintWindow 抓图坐实：原生蓝条消失、融合顶栏在位；拖拽/最大化/关闭隐藏到托盘冒烟（`tools\verify\exe_smoke.ps1`） |

## 4. 验收判据

1. 运行中的窗口顶部**无原生标题栏带**，自绘顶栏与页面同底色、无硬分隔线；
2. 拖拽顶栏可移动窗口；双击顶栏可最大化/还原；Win11 贴边快照布局仍可用；
3. 最小化 / 最大化(还原) / 关闭三钮可用，关闭 = 隐藏到托盘（与旧行为逐字一致）；
4. 窄屏(<1280) NavRail 折叠、dock/KeyBar 列兄弟结构、Ctrl+1…4 键位零回退；
5. 门禁全绿且只增不减；旧安装包全部作废登记，新包为唯一可分发。

## 5. 风险与对策

- **hidden 让带后 Flutter 内容被 rounded corner 裁切顶边按钮**：真机取证坐实；必要时顶栏左右内缩 1–2px（worker 不预先处理）。
- **既有 widget 测试因高度 +32px 断言失败**：允许 worker 在 `test\**` 内做最小几何修正并在 closeout 登记原因。
- **legacy API 签名与派工书引用行号漂移**：以包源码实读为准（缓存 `C:\Users\Duanyi\AppData\Local\Pub\Cache\hosted\pub.flutter-io.cn\`），不猜参数，差异记 closeout。

## 6. 验收判据勾选（2026-11-11 控制器亲核，最终状态）

> 判据逐条对应 §4。证据一律取**运行时产物**，不接受文档转述。

- [x] **判据 1 · 无原生标题栏带**：探针 `reports\task30-titlebar-check.ps1 -OutDir reports\task30-w2-out`
      ⇒ `NC_TOP=0`（原 45）、`BAND_PAPER_PCT=100`（原 0）、`BAND_INK_PCT=0`、`VERDICT=PASS`；
      截图 `reports\task30-w2-out\task30-window.png`。
- [x] **判据 2 · 拖拽可移动 + 双击可最大化/还原 + 贴边 snap 可用**：
      探针 `reports\task30-btn6.ps1` → `reports\task30-btn6.log`（2026-11-11 12:08:57 一轮）
      ⇒ `SUMMARY pass=7 fail=0`：
      B1_MAXIMIZE PASS / B2_RESTORE PASS / B3_MINIMIZE PASS / B4a_DBLCLICK_MAXIMIZE PASS /
      B4b_DBLCLICK_RESTORE PASS / B5_DRAG PASS（moved_left=180px）/ B6_SNAP_TOP_EDGE PASS（zoomed=True）。
      **双击最大化在 W-1 上是 `NO_EFFECT`（缺陷），W-2 修复后本轮坐实 PASS。**
- [x] **判据 3 · 三钮可用 + 关闭=隐藏到托盘**：B1/B2/B3 PASS；关闭隐藏到托盘为**既有行为，未在本轮改动**（沿用 W-1 结论）。
- [ ] **判据 4 · 窄屏(<1280) NavRail 折叠 + 键位零回退**：**未验证**。顶栏固定 32px 不随宽度自适应，
      窄屏下 NavRail 折叠后顶栏与内容可能叠成两行 32px。⇒ 登记为遗留风险（见 `handoff.md` §25 遗留段），**不勾选**。
- [x] **判据 5 · 门禁全绿 + 唯一可分发**：desktop analyze 逐字 `No issues found!` + 全量 `+290 All tests passed!`；
      core_data analyze 干净 + `+141`；唯一可分发 = `release\PractiLog-Setup-1.0.0_20261111-113143.exe`（sha16 `E41DF9560A978302`）。

### 遗留（登记，不连带）
- 顶栏高 32 **逻辑**px 不随显示缩放自适应；真机 150% 下物理 48px，字形行 y=15..32（钮心 y=T+24）。
- 三钮命中区右锚定：物理 `R-44 / R-110 / R-176`（min/max/close）；最大化态窗口右边 `R=3851`，仍按右锚定取值。
- `windowMaximized` 为模块级单例；顶栏装配层零覆盖；最小窗 960×640 无覆盖。
- 窄屏 <1280 行为未验证（判据 4）。
