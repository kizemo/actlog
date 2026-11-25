# B7（Task 72）真机验收记录 — 目标体系 4 条补充 UI 需求

生成：2026-11-25 16:55（本机实测）
会话：`mvs_2fe482da85314d7584b1abcdfc0d19d3`
性质：**权威验收台账条目**，自带完整背景 / 目标 / 进度 / 计划，新会话无需回翻派工书或压缩摘要。

---

## 一、背景（用户原始需求，2026-11-25 14:32 逐字）

> 补充要求：
> 1. 调整页面左边栏，去除左边栏底部切换页面快捷键显示；把人生蓝图单独提取出来，设定为独立页面；
> 2. 月目标设定页面，显示右边栏，右边栏中，显示仍然未完成的年目标，可以点击或拖动添加到月目标；
> 3. 周目标设定页面，显示右边栏，右边栏中，显示仍然未完成的月目标，可以点击或拖动添加到周目标；
> 4. 在日志主页面，右边栏中添加仍然未完成的周目标，可以点击或拖动添加到计划中，也可以在日计划右键勾选添加。

实施分四棒（W1 导航瘦身+蓝图独立页+共享地基 / W2 月·周页右栏 / W3 今日右栏+日计划右键勾选 / W4 修 verifier 发现的 MAJOR-1+MINOR-1+MINOR-4），
另加 verifier 独立复核、post-W4 全量门禁、重出包、三处权威台账回填。
本轮（2026-11-25 下午起）做的是**最后一步：真机覆盖安装 + 逐条界面验收**。

授权来源：用户 2026-11-25 16:42:15 逐字「可以退出，装完截图验收」⇒ 结束旧进程 + 静默覆盖安装 + 真机取帧三项授权成立。

---

## 二、结论（四条需求逐条判定）
> ⚠️ **订正（2026-11-25 18:2x 续轮）**：本节中「交互未取证 / 无落库证据 / 需补做交互验收」的结论**已被 §七 取代** —— 四条写入通道（② 点击、③ 点击、④ 点击、④ 右键勾选、④ 拖拽）已全部取得回读 SQLite 的落库硬证据，B7 交互验收判 **PASS**。勿按本节旧结论重跑取证。


| # | 需求 | 判定 | 实证帧 |
|---|---|---|---|
| ① | 左栏去除底部快捷键显示 + 人生蓝图独立页 | **界面已验证通过** | `01-today.png`、`11-blueprint.png` |
| ② | 月目标页右栏显示未完成年目标 | **界面已验证通过（空态）** | `10-goals-year.png` |
| ③ | 周目标页右栏显示未完成月目标 | **界面已验证通过（空态）** | `13-goals-week.png` |
| ④ | 今日页右栏显示未完成周目标 + 日计划右键勾选 | **右栏界面已验证通过（空态）；右键勾选未取证** | `01-today.png` |

### 逐条证据描述（读帧目视所得，帧均为 2520×1575 物理像素）

**① 左栏（`01-today.png`）**
导航栏自上而下 7 项：`01 日志 / 02 待办池 / 03 习惯 / 04 项目 / 05 日历 / 06 目标 / 07 蓝图`。
导航栏**底部只剩一个齿轮（设置）图标，原「Ctrl+1…7」快捷键显示已消失** —— 需求①前半达成。
「07 蓝图」是独立导航项，点击进入**独立页面**（非抽屉）：`11-blueprint.png` 顶部标题为「蓝图」，
页面含三块卡片 —— 「人生蓝图矩阵」（行：事业/财富/家庭/学习/人际/健康；列：终极/远期/中期/短期/近期(1年)，注「近期列＝本年度年度目标（同一份数据源）」「整行留空合法，不校验、不报错」）、
「待确认待办」（确认写入待办）、「平衡轮（派生，不落库）」（还无自评数据）。需求①后半达成。
补充：右轨「快捷键」卡片**仍在**（Ctrl+N / Ctrl+D / ←→ / Space / Enter / Esc / Ctrl+1..4 / Ctrl+5 / Ctrl+6），
这是裁决 **D-72-a** 明确保留的（只删左栏底部显示，功能与右轨提示不动）。

**② 月目标页（`10-goals-year.png`）**
顶部「目标」+ 周期 tab `周 / 月 / 年`（`月` 处于选中态）。
左列四卡：`年度目标汇总`（本年度还没有目标）/ `上月复盘` / `本月目标` / `滚动候选`。
**右列新卡：`未完成年目标` + 副标题「点击或拖拽添加到当前周期」+ 空态「暂无未完成年目标」** —— 需求②的界面承接达成。

**③ 周目标页（`13-goals-week.png`）**
tab `周` 选中。左列两卡：`本周目标`（本周还没有目标）/ `滚动候选`。
**右列新卡：`未完成月目标` + 「点击或拖拽添加到当前周期」+ 「暂无未完成月目标」** —— 需求③的界面承接达成。

**④ 今日页右栏（`01-today.png`）**
右轨自上而下：`待办列表` / `习惯速览` / `循环任务` / `闭环提示` /
**`未完成周目标` + 「点击或拖拽添加到当前周期」+ 「暂无未完成周目标」** / `快捷键` —— 需求④的右栏承接达成。
「日计划右键勾选添加」这一支**本轮未取到实证**（原因见第三节）。

---

## 三、已验证 / 推断 / 未验证（三分层，务必区分）
> ⚠️ **订正（2026-11-25 18:2x 续轮）**：本节中「交互未取证 / 无落库证据 / 需补做交互验收」的结论**已被 §七 取代** —— 四条写入通道（② 点击、③ 点击、④ 点击、④ 右键勾选、④ 拖拽）已全部取得回读 SQLite 的落库硬证据，B7 交互验收判 **PASS**。勿按本节旧结论重跑取证。


### 已实测（盘上或屏上直接证据）
- **装机指纹与构建产物逐字节一致**（这是「新包真含 W2/W3/W4」的唯一硬判据）：
  `D:\Program Files\actlog\data\app.so` = `9,126,792 B / sha16 1A5E09068403A98A`，
  与 `apps\desktop\build\windows\x64\runner\Release\data\app.so` 完全相同。
  装机前旧值为 `9,061,256 B / 28B069FFE40C6825`（14:11:20），装机后读回 `16:06:36`。
  日志 `reports\task72-live-close-install.txt`。
- 分发包 `release\actlog-Setup-1.0.0_20261125-161235.exe`（`22,815,984 B / sha16 1C73F1DA6C996F09`），
  `makensis` 退出码 0，安装退出码 0。
- 权威门禁（`reports\task51-gate\summary.txt`，`RUN_AT=2026-11-25 16:02:01`）：
  `GATE_VERDICT=PASS / GATE_FAILURES=0`、`DESKTOP_TESTS=907`（精确等值 882+13+8+4）、
  `CORE_DATA=204 / CORE_DB=96 / CORE_DOMAIN=91`、四包 `ANALYZE=VERBATIM`、`VIOLATIONS=0 / OUT_OF_SET=0`、
  `PS1_SCANNED=502 / PS1_ASCII_VIOLATIONS=0`。
- 取帧前置守卫：`LOGONUI=NONE`；`reports\task29-desktop-check.ps1` → `INPUT_DESKTOP=Default / VERDICT=ON_DEFAULT_DESKTOP`。
- 真机窗口：`actlog.exe` PID 92016，`HWND=198170`，`2520×1575`，`FOREGROUND_OK=True`，`PRINTWINDOW=True`。
- 界面呈现四条（见第二节），逐帧哈希互不相同 ⇒ 导航真实生效，不是同一张缓存帧。

### 推断（有旁证但未直接取证）
- 「点击 / 拖拽添加到当前周期」的**交互逻辑**：由单测覆盖（verifier 复核 `testWidgets` 新增 19、真断言 17，A1–A4 全通过），
  且界面提示文案已渲染；但**未在真机上用真实数据走通一次**（本机无任何未完成的上层目标）。
- 日计划右键勾选菜单：代码落点 `apps\desktop\lib\src\widgets\day_grid.dart:1173-1196`、`:1282-1310`，
  `slot_context_menu.dart:46`；真机上未取证（同上，无周目标可勾选）。

### 未验证（明确缺口，不得当作已通过）
1. **点击/拖拽添加的真实落库**：需要至少 1 条未完成的年/月/周目标数据。本机 DB 三层全空（帧内可见「本年度/本月/本周还没有目标」）。
2. **日计划右键勾选菜单**：同上，需先有未完成周目标。
3. **窄屏 `KeyBar` 的 `Ctrl+7` 文字提示**（MINOR-2）：按挂账未做，右轨快捷键卡确实只列到 `Ctrl+6 切到目标`。
4. **provider 未就绪时拖拽/右键静默无落库**（MINOR-3）：未做真机故障注入。
5. 三处权威台账（`AGENTS.md` §7 / `docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md\handoff.md` §82 / 同目录 `progress.md` ⑱）
   **尚未写入本条真机验收结果** —— 本轮只落了本文件。回填由下一棒做（见第五节）。

---

## 四、本轮工具坑（务必避免重跑）

1. **`keybd_event` 注入 `Ctrl+数字` 对本应用无效** —— 四帧哈希完全相同（`3F6A973EF4CBC00B`）证明页面根本没切。
   改法：**用鼠标点击左栏导航项**（`click:118,593` = `06 目标`，`click:112,664` = `07 蓝图`），
   帧立刻分化（112,795 / 120,401 / 98,084 / 120,865）。
   推广：真机验收优先走「点击可见控件」，不要依赖合成键盘事件；快捷键路径要验就得先证帧有变化。
2. **判「导航是否生效」的最低成本方法是逐帧 sha16 对比**，不是肉眼看文件大小（PNG 尺寸巧合很常见，但全等几乎必为同帧）。
3. 承前坑（本轮再次踩到/确认）：`Add-Type` 的 `-UsingNamespace` 参数集会报「无法使用指定的命名参数解析参数集」，C# 源里自带 `using System.Text;`；
   `[Drawing.Graphics]::GetHdc($g)` 不存在，必须实例方法 `$hdc=$g.GetHdc()` / `$g.ReleaseHdc($hdc)`；
   `EnumWindows` 委托写外层局部变量不可靠，改用 `$script:` 作用域并打印全部候选 `HND/VIS/WxH`；
   应用刚起时 `MainWindowHandle` 可能为 0，需轮询而非一次判死；
   `CloseMainWindow()` / `WM_CLOSE` 对 Flutter 主窗无效，覆盖安装前需 `Stop-Process -Name actlog -Force`（实测未被安全网关拦）。
4. 坐标口径：`reports\task72-live-drive.ps1` 的动作坐标 = **窗口左上角为原点的物理像素**，与 PNG 1:1；
   读帧时显示图被缩到 1280×800，换算到物理像素要 **×1.97**。

---

## 五、下一步计划（给下一棒）
> ⚠️ **订正（2026-11-25 18:2x 续轮）**：本节中「交互未取证 / 无落库证据 / 需补做交互验收」的结论**已被 §七 取代** —— 四条写入通道（② 点击、③ 点击、④ 点击、④ 右键勾选、④ 拖拽）已全部取得回读 SQLite 的落库硬证据，B7 交互验收判 **PASS**。勿按本节旧结论重跑取证。


1. **造数据后补做交互验收**（需求②③④的「点击/拖拽添加」与「右键勾选」）：
   在 年目标 页新建 1 条未完成年目标 → 切月 tab 看右栏是否列出 → 点击它 → 回读是否进入本月目标；
   月→周、周→今日计划同理；今日页对日计划格子 `rightclick:<x>,<y>` 验勾选式多选。
   注意：这会写真实用户数据，**动手前先征得用户同意**（用户偏好：删除/覆盖用户数据类必须先问）。
   驱动命令形状：
   `& pwsh -NoProfile -ExecutionPolicy Bypass -File reports\task72-live-drive.ps1 -Actions 'click:118,593;wait:2500;click:717,179;wait:3000;frame:NN-name'`
2. **把本条验收结果回填三处权威台账**（`AGENTS.md` §7 Task 72 bullet 追加一行「真机界面验收：①②③④ 通过，交互待数据」+
   `handoff.md` 新增 §83 + `progress.md` ㉑ 之类续编），
   姿势沿用 `reports\task72-apply-b7-backfill.ps1`（CJK 放 `.superpowers\b7-backfill\*.md` 片段，`.ps1` 保持纯 ASCII；
   编辑 `AGENTS.md` 前落字节级备份并校验 §6/§7 标题行在位 = 坑 99；数字一律盘上回读 = R5）。
3. 挂账待用户表态（不要自行开工）：MINOR-2 窄屏 `KeyBar` 的 `Ctrl+7` 文字提示；MINOR-3 provider 未就绪静默无落库；
   右栏「未完成目标」不按周期过滤是否符合预期；W4 自报 3 条 CONCERN（错误态复用通用 `t.operationFailed`、无重试按钮、loading 无超时兜底）；
   幂等落在 UI 层 `addWeekGoalToPlan`（`week_goal_rail_panel.dart:47`）而非 store 层。
4. 承自 `docs\relay.json` `still_open_for_human`：是否 push 本地 ahead 6；relay 链未提交载荷是否提交；
   `reports\task51-gate.ps1:302-305` 白名单口径是否回退。

---

## 六、证据路径索引（全路径，可 `Test-Path`）

- 帧目录：`F:\soft\00selfmade\practilog\reports\task72-frames\`
  `01-today.png`（今日页，143,315 B）/ `06-goals.png` `07-blueprint.png` `01b-today.png`（三张与 01 同哈希 = 键盘注入失效留证，勿删）
  `10-goals-year.png`（月目标页，112,795 B）/ `11-blueprint.png`（蓝图独立页，120,401 B）
  `12-goals-again.png`（回目标页，112,795 B）/ `13-goals-week.png`（周目标页，98,084 B）/ `14-goals-year-tab.png`（年 tab，120,865 B）
  驱动日志 `reports\task72-frames\drive-log.txt`
- 真机装置：`F:\soft\00selfmade\practilog\reports\task72-live-drive.ps1`（驱动+取帧）、`reports\task72-live-close-install.ps1`（退出+覆盖安装+指纹）、`reports\task72-live-probe.ps1`（窗口枚举探针）、`reports\task29-desktop-check.ps1`（桌面守卫）
- 门禁/出包：`reports\task51-gate\summary.txt`、`reports\task72-make-installer-b7-w4.txt`、`release\actlog-Setup-1.0.0_20261125-161235.exe`
- 设计真源与派工：`docs\plan-goals-ui-batch7.md`、`docs\b71-dispatch-w1-nav.md`、`docs\b71-dispatch-w2-panel.md`、`docs\b71-dispatch-w3-wire.md`、`docs\b71-dispatch-w4-fix.md`
- 四棒台账：`docs\handoff-ledger-b7-w1.md`、`-w2.md`、`-w3.md`、`-w4.md`
- 代码落点（控制器只读，R1）：`apps\desktop\lib\src\app.dart`（`:244-257` 快捷键映射、`:171` `/blueprint` 深链、`:351` `GoalsBlueprintPage`）、
  `apps\desktop\lib\src\widgets\shell\nav_rail.dart`、`...\shell\key_bar.dart`、`...\goals\goal_upstream_panel.dart`、`...\goals\week_goal_rail_panel.dart`、`...\day_grid.dart`、`...\slot_context_menu.dart`
- 回填装置与备份：`reports\task72-apply-b7-backfill.ps1`、`.superpowers\b7-backfill\*.md`、`reports\b7-backup\*.20261125-163838.bak`


---

## 七、交互验收补做（2026-11-25 18:2x 续，用户指令「建测试数据，补做交互验收」）

**结论：四条写入通道全部取证到落库硬证据，B7 交互验收判 PASS。** 之前「只有界面呈现、无落库证据」的判定被本节取代。

### 7.1 测试数据构造（零污染用户真实库）

| 项 | 实测 |
|---|---|
| 快照装置 | `reports\task72_snapshot.py`（`VACUUM INTO`，幂等，可重复执行取最新态） |
| 快照副本 | `reports\task72-seeddb\actlog.db` |
| 造数装置 | `reports\task72_seed_goals.py` → `SEED_GOALS_INSERTED=4` |
| 种子数据 | 年 `b7seed-yearly-1` Alpha / 月 `b7seed-monthly-1` / 周 `b7seed-weekly-1` Gamma / 周 `b7seed-weekly-2` Delta |
| 种子实例 | `Start-Process 'D:\Program Files\actlog\actlog.exe' -ArgumentList "--data-dir=<seed>"`（与 `ACTLOG_DATA_DIR` 双保险，`main.dart:36-64` / `app_paths.dart:182-215`） |
| **用户活库** | 全程零写入，收工回读仍为 `352,256 B / mtime 11/21/2026 21:37:03`，未变 |

### 7.2 四条通道落库证据（一律以回读 SQLite 为准，截图只作界面证据）

基线（seed 之后、任何交互之前）：`goal 4 / goal_link 0 / plan_item 21 / todo 1`。

| # | 通道 | 操作链（native 像素，窗口原点系） | 界面证据 | **落库证据** |
|---|---|---|---|---|
| ④ | 今日页右栏**点击**添加 | 右栏 Gamma 卡 (1990,1220) | 帧 26/27 字节数变化 | `goal_link 0→1`；新 plan_item `01a21205-1a4f-7a92-987f-066b222535c8`（Gamma，600/630） |
| ② | 月页「添加到当前周期」 | 06 目标→月 tab→右栏年目标卡 (1555,392)→确认 (1411,948) | 帧 61→62 **219,156→197,478** | `goal 4→5`；新目标 `01a2120b-3c7f-7f34-8b36-04a5f2a996f9`「B7SEED Monthly Goal Alpha」(kind=monthly, parent=b7seed-yearly-1)；新 link `serves` |
| ③ | 周页「添加到当前周期」 | 06 目标→周 tab (554,177)→右栏月目标卡→确认 | 帧 66→67 **197,238→218,141** | `goal 5→6`；新目标 `01a2120b-593d-7910-9f3d-8e117cbd4cf3`「B7SEED Weekly Goal Beta」(kind=weekly, parent=b7seed-monthly-1)；新 link `serves` |
| ④ | 日计划**右键勾选** | 今日页 (114,243)→空白格右键 (1060,1379)→**🚩 添加到计划 (1109,971)**→勾选框 (998,765)→**确定 (1540,932)** | 帧 76=161,233（已勾选）→77=154,870（关窗） | `goal_link 3→4 / plan_item 23→24`；新 plan_item `01a21234-2806-780b-b608-41a974cc2a16`（Delta，1200/1215）；新 link `01a21234-2808-7f64-9a81-db46c0c2b3fa` |
| ④ | 今日页右栏**拖拽**添加 | `drag:2150,1325/1060,1200` → 确认 (1411,948) | 帧 79=154,870 → 84 **160,570**（起止弹窗）→ 85 157,268 | `goal_link 4→5 / plan_item 23→24`；新 plan_item `01a21238-a02c-79bc-8e53-77b1018d4c7d`（Beta，**planned_start 1065 / planned_end 1080 = 17:45–18:00，由落点决定**）；新 link `01a2120b-593d…, plan_item, 01a21238-a02c…, serves` |

末态：`goal 6 / goal_link 5 / plan_item 24 / todo 1`。三条派生 plan_item 的 `source_type='manual' / status='pending' / date='2026-11-25' / domain=''`。

**源码同源证据**（`reports\task72-code-snip.txt`，708 行）：右栏卡是普通 `Draggable<String>`（`week_goal_rail_panel.dart:194` + `:196 pointerDragAnchorStrategy`，**无需长按**）；落点侧 `day_grid.dart:341-346 onWillAcceptWithDetails/_onDrop` → `:1200 _onDrop(payload, globalOffset)` → `:1282 case 'goal'` 分支只调 `_askDropRange` + `addWeekGoalToPlan`，**不经勾选弹窗**。三条 UI 通道共用同一写入入口与幂等判据 `alreadyInPlan`。

### 7.3 取证纪律教训（本节推翻两条错误结论）

1. **「拖拽零落库」与「右键勾选零落库」都不是产品缺陷，都是取证姿势错误** —— 拖拽起点 `y=1465` 落在「快捷键」卡上（`Ctrl+N` 文字所在），不是 Beta 卡；右键链里前几轮的 `确定` 坐标 `1440,1005` / `1460,1092` 落在遮罩空白。**教训：任何「无反应」结论之前，必须先标定元素坐标，别信目测。**
2. **坐标标定装置是必需的**：`reports\task72-frame-annot.ps1`（3,188 B，纯 ASCII，`PS1_ASCII_VIOLATIONS=0`）—— 区域 1:1 纵向堆叠 + 30px 网格 + native 坐标标签（`GX/GY` 为区域左上角 native 像素，格标签 = `GX+gx / GY+gy`）。**教训：全帧肉眼读数在 2520×1575 缩略图里不可靠（目测 1465 实际 1325，偏 140px）。**
3. `goal_link` 的「种类」列**既不叫 `link_type` 也不叫 `link_kind`**（`no such column` 实测）—— 列名一律先 `PRAGMA table_info` 回读。
4. 帧 SHA1 打印坑：`"...Substring(0,16)"` 写在双引号内插串里被当字面量输出（本轮帧哈希不可用）；**字节数**足以判「画面是否真变化」，本轮靠它抓到多次零反应轮。
5. `python -c` 内联在 PowerShell 下转义不可用，一律落成 `.py` 文件再跑。
6. 驱动脚本无法发送裸 Escape（`key:<vk>` 恒为 Ctrl 组合），关弹窗只能点「取消」或遮罩空白（后者 = barrier 关闭，零写入，别误判成落库）。

### 7.4 新发现 / 待办（写进下一棒）

- **MINOR-2 仍未取证**：窄屏下 `KeyBar` 的 `Ctrl+7` 文字提示是否补做 —— 帧 41 / 43 / 78 多次实证「快捷键」卡只列到 `Ctrl+6`。
- **provider 刷新**：③ 新派生的周目标 draft 需**重启进程**才在 今日右栏出现（帧 68/69 不显示，重启后帧 53 显示 Gamma/Delta/Beta 三卡）。待定性：设计缓存策略 vs 缺陷。
- 同轮附带发现（待定性）：07 蓝图页显示「暂无蓝图目标框架 / 0 条」，而同期 `goal` 表有 6 行 —— 三条 seed 行未写 `domain / horizon / facet`；是设计口径还是缺陷，未坐实。
- **用户新原则（本轮裁决）**：「蓝图、目标页面的内容，应该在对应页面编辑，而不是在日志页面填入后回填到这些页面。」⇒ **B8 范围**：① 蓝图页补可编辑能力（不再只读树）② 今日页撤掉目标写入入口（右栏点击/拖拽 + 日计划右键勾选）。B7 按现状收口，改造另起一棒。
- 派生目标只写 `serves`、不写 `derives` 的原因未坐实（推测 `goal_store.dart:1061-1090` 在 `parentId == sourceGoalId` 时去重）。

### 7.5 本节装置索引

`reports\task72_snapshot.py` · `task72_seed_goals.py` · `task72_readback.py` · `task72_drag_detail.py` · `task72_live_schema.py` · `task72-live-drive.ps1` · `task72-frame-annot.ps1` · `task29-desktop-check.ps1`
证据：`reports\task72-seeddb\` · `reports\task72-live-schema.txt` · `reports\task72-code-snip.txt` · `reports\task72-frames\{53,61,62,66,67,73,76,77,79,82,83,84,85}-*.png`
