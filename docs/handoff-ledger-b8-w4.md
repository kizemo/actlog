# B8-W4 收口台账 · 真机取证链 + release 安装包 + 分发真源更新

- 提交状态：**本轮由控制器统一 commit**（提交前 HEAD = `d2f5e5e`，门禁读数 `AHEAD=11` / behind 0；按用户指令**只 commit 不 push**）
- 环境：Windows / pwsh 7.7.0 / Flutter（进程内设镜像 `pub.flutter-io.cn` + `storage.flutter-io.cn`）
- 编码：UTF-8 无 BOM，纯 LF（本文件 `CR=0`，自检见 §12）

---

## 1. 背景与目标

**一句话**：B8 前三棒只落了代码，本棒把「目标到底能不能在真机上**建成 / 改掉 / 删掉**」用**帧 + SQLite 读回**双证坐实，然后跑全量门禁、出 `release\` 安装包、把 AGENTS 的分发真源与状态快照推到最新。

**上游文档全路径**（下一棒不必回翻派工书）：

| 文档 | 绝对路径 | 作用 |
|---|---|---|
| 设计真源 | `F:\soft\00selfmade\practilog\docs\plan-goals-ui-batch8.md` | D-8-a~h 裁决 + 四棒划分 + 每棒通用验收判据（§5） |
| 范围裁决 | `F:\soft\00selfmade\practilog\docs\b8-scope-decision.md` | U-8-x / U-8-y **仍未裁** |
| 前三棒台账 | `F:\soft\00selfmade\practilog\docs\handoff-ledger-b8-w1.md` / `-w2.md` / `-w3.md` | 体例样板 + 逐文件改动表 |
| 项目规范 | `F:\soft\00selfmade\practilog\AGENTS.md` | R1–R8 铁律、装置地图、本机坑 |

**四棒定义（计划 §4）**：W1 蓝图页获得目标编辑能力 → W2 目标页（年/月/周）获得行级编辑/删除、与 W1 共用同一表单组件 → W3 日志侧撤目标写入入口 → **W4 真机验收 + 台账 + 安装包**。

**本棒写集**：`reports\`（探针与帧，gitignored）/ `release\`（安装包产物）/ `docs\`（本台账）/ `AGENTS.md`（§2 R3 真源行 + §5 新坑 + §7 快照）。
**零 `apps\**` 改动、零 `packages\**` 改动**（R1：本棒不含实现，只做取证与出货）。

---

## 2. 开工基线（盘上回读）

| 项 | 值 | 取证方式 |
|---|---|---|
| HEAD | `d2f5e5e` | `git log --oneline -3` |
| W1 / W2 / W3 提交 | `fcf1cee` / `dbd95cd` / `d2f5e5e` | 同上 |
| 与 `origin/main` | **ahead 11 / behind 0** | `git rev-list --left-right --count HEAD...@{u}` |
| 工作树脏行 | **11 行**（3 × ` M` + 8 × `??`），**全部属并发 relay 链，本棒一字未碰** | `git status --porcelain -uall` |

---

## 3. 真机取证链（W1 / W2 / W3 三棒功能一次跑完）

### 3.1 装置与数据隔离

| 项 | 值 |
|---|---|
| 被测件 | **构建树** `apps\desktop\build\windows\x64\runner\Release\actlog.exe`（**非装机件**，装机件仍是 B7 载荷，见 §5.3） |
| 启动参数 | `--data-dir=F:\soft\00selfmade\practilog\reports\task72-seeddb` ⇒ 全部读写落在**种子副本** |
| 种子库 | `reports\task72-seeddb\actlog.db` = **417,792 B / sha16 `68180820D9D03ADA` / mtime 2026-11-25 17:22:46**；同目录 `actlog.db-wal` = 1,429,672 B、`actlog.db-shm` = 32,768 B ⇒ **WAL 模式**，写入先落 WAL |
| 驱动脚本 | **本棒新建** `reports\task77-w4-drive.ps1`（**未改** `reports\task72-live-drive.ps1`） |
| 读回脚本 | `reports\task77-goal-dump.py`（本棒新建，`goal` 表 24 列全量 + alive/dead + `todo`/`plan_item`/`goal_link` 计数）+ `reports\task72_readback.py`（用户指定装置，硬编码同一副本） |
| 帧目录 | `reports\task77-frames\`：**38 张 PNG**（合计 5,054,286 B）+ 5 个读回 txt + `drive-log.txt`（27,385 B） |
| 窗口 | PID 258412 / HWND 24577520 / `VIS=True 2520x1468` / `AREA=3699360`；`FOREGROUND_OK=True FG=24577520`（`drive-log.txt` 原文） |
| 坐标口径 | 驱动参数 = **native 图像坐标**，屏幕坐标 = 参数 + (20, −56)；`CLICK_TARGET=1005,341 READBACK=1005,341` 逐条回读一致 |

### 3.2 W1 蓝图页（格内新建 / 卡片编辑 / 删除）

| 步骤 | 帧 | 证据 |
|---|---|---|
| 进入蓝图页 | `w4-02-blueprint.png` | 7 格蓝图矩阵渲染 |
| 新建表单 | `w4-03-form.png`（143,421 B） | 表单含 `title`/`note`/`keywords`/`domain`/`horizon`/`due` 六字段 |
| 键入 `W4GOALA` | `w4-04-typed.png` | 创建表单内 `text:` 通道有效 |
| `utext:` 对照 | `w4-05-utext.png` | 创建表单内 `utext:` **也有效**（与编辑弹窗不同，见 §7.3） |
| 保存 | `w4-06-saved.png`（137,625 B） | 卡片出现在格内 |
| 编辑弹窗 | `w4-07-edit-open.png` → `w4-08-edit-typed.png` → `w4-09-edit-reopen.png` | 弹窗打开；`utext:` 在弹窗内**不插字**（帧字节与打开态一致） |
| 改标题 + 备注 | `w4-12-paste.png` → `w4-13-note-typed.png` | `paste:`（剪贴板 + Ctrl+V）**唯一保真通道** |
| 保存 | `w4-14-edit-saved.png`（139,889 B） | 读回 `readback-W4-EDIT.txt` / `readback-W4-EDIT2.txt` |
| 删除确认 → 删除 | `w4-15-del-confirm.png` → `w4-16-deleted.png`（136,076 B） | 读回 `readback-W4-DELETE.txt` |

**删除语义已坐实 = 软删除**（不是物理删行）：
`deleted_at=1795615816697` 写入、**`status` 仍为 `active`**、`rev` 3→4、alive 7→6 / dead 1；
**`goal_link` = 5、`plan_item` = 24、`todo` = 1 三张表计数不变 ⇒ 删除不级联**。

### 3.3 W2 目标页（行级编辑 / 行级删除）

取证对象 = 种子 weekly draft 目标 `01a2120b-593d-7910-9f3d-8e117cbd4cf3`（原 title `B7SEED Monthly Goal Beta`，是种子里唯一带 `draft` 状态且落在周页可见区的目标）。

| 步骤 | 帧 | 证据 |
|---|---|---|
| 进目标页 | `w4-17-goals-page.png`（118,457 B） | 目标页（年/月/周/蓝图 四页签） |
| 行级编辑弹窗 | `w4-18-row-edit-open.png`（127,408 B） | 行内「编辑 / 删除」两个图标可见 |
| 探针三连（无效路径留证） | `w4-19` / `w4-20` / `w4-21-focus-probe` / `w4-22-paste-probe` / `w4-23-utext-probe` | 帧字节几乎不变 ⇒ 该阶段输入未生效 |
| 改标题（`ctrl:back` ×2 + `paste:`） | `w4-24-base.png` → `w4-25-back1.png` → `w4-26-paste1.png` → `w4-27-row-typed.png` | 弹窗打开后**不点击输入框**，直接键盘输入才有效 |
| 保存 | `w4-28-row-saved.png`（**118,682 B**） | 读回：`rev` 1→2、`updated_at=1795616214124`、title = `W4ROWGOALy Goal Beta`（尾部 `y Goal Beta` 为 **back 次数不足造成的注入误差，非产品缺陷**） |
| 复核 | `w4-29-row-retitled.png` / `w4-30-row-saved2.png` | 帧字节与保存帧一致 |
| 删除确认 → 删除 | `w4-31-del-confirm.png`（121,384 B）→ `w4-32-deleted.png`（**103,158 B**，行消失） | 读回：`deleted_at=1795616862991`、`rev` 2→3、alive 6→5 / dead 2；**`goal_link`=5 / `plan_item`=24 / `todo`=1 不变 ⇒ 不级联** |
| 三页签巡检 | `w4-33-month-page.png`（124,636 B，月页行内有编辑/删除图标） / `w4-34-year-page.png`（118,379 B） / `w4-35-week-back.png`（103,162 B） | 年页显示**空态「本年还没有目标。」** ⇒ 归因见 §7.2 |

### 3.4 W3 今日页（写入面已撤）

| 帧 | 判定 |
|---|---|
| `w4-36-today-page.png`（143,574 B） | 今日页右栏「未完成周目标」是**只读卡**，**无「+ 添加」** |
| `w4-37-today-rightclick.png`（148,119 B） | 日格右键菜单**仅「手填 / 待办 / 习惯」三组，无「目标」组** |

⇒ W3 的写入面撤除在真机上**生效**，与 W1/W2 的编辑面形成闭环（今日页不再能建目标，但目标页/蓝图页能建能改能删）。

### 3.5 终态读回（种子库）

`reports\task77-frames\readback-W4-FINAL.txt`（`task77-goal-dump.py`）+ `readback-W4-FINAL-72.txt`（`task72_readback.py`）：

```
COUNT goal all   = 7      COUNT goal alive = 5      COUNT goal dead = 2
COUNT todo       = 1      COUNT plan_item  = 24     COUNT goal_link  = 5
```

七条 goal 全量（24 列）：

| id | kind | title | status | deleted_at | rev | 备注 |
|---|---|---|---|---|---|---|
| `01a212fe-df54-711f-9690-151798ad6bbc` | blueprint | `W4GOALB` | active | 1795615816697 | 4 | `note=W4NOTE`，本棒新建→编辑→删除（W1） |
| `01a2120b-593d-7910-9f3d-8e117cbd4cf3` | weekly | `W4ROWGOALy Goal Beta` | draft | 1795616862991 | 3 | 本棒行级编辑 + 行级删除（W2） |
| `01a2120b-3c7f-7f34-8b36-04a5f2a996f9` | monthly | `B7SEED Yearly Goal Alpha` | draft | — | 1 | 种子 |
| `b7seed-yearly-1` | yearly | `B7SEED Yearly Goal Alpha` | active | — | 1 | 种子 |
| `b7seed-monthly-1` | monthly | `B7SEED Monthly Goal Beta` | active | — | 1 | 种子 |
| `b7seed-weekly-1` | weekly | `B7SEED Weekly Goal Gamma` | active | — | 1 | 种子 |
| `b7seed-weekly-2` | weekly | `B7SEED Weekly Goal Delta` | active | — | 1 | 种子 |

### 3.6 用户活库零写入核对

| 库 | 实测 | 判定 |
|---|---|---|
| 用户活库 `D:\Program Files\actlog\userdata\actlog.db` | **352,256 B / mtime 2026-11-21 21:37:03 / sha256 `B5F9070FC63068B1E94A040AF5BE0435`** | 与基线**逐字一致** ⇒ **零写入** ✅ |
| 种子副本 `reports\task72-seeddb\actlog.db` | 417,792 B / sha16 `68180820D9D03ADA` | 本棒取证数据只落在这里 |

被测进程已在取证结束后 `Stop-Process`（复检 `ACTLOG_NOT_RUNNING`）。

---

## 4. 门禁复跑（控制器亲跑）

装置：`pwsh -NoProfile -ExecutionPolicy Bypass -File F:\soft\00selfmade\practilog\reports\task51-gate.ps1 -ExpectDesktopTests 920`
摘要：`F:\soft\00selfmade\practilog\reports\task51-gate\summary.txt`

```
GATE_VERDICT=PASS          GATE_FAILURES=0
DESKTOP_TESTS=920          DESKTOP_EXPECTED=920      DESKTOP_BASELINE=596   DESKTOP_DELTA=324
CORE_DATA_TESTS=204        CORE_DB_TESTS=96           CORE_DOMAIN_TESTS=91
DESKTOP_ANALYZE=VERBATIM   CORE_DATA_ANALYZE=VERBATIM CORE_DB_ANALYZE=VERBATIM CORE_DOMAIN_ANALYZE=VERBATIM
VIOLATIONS=0               OUT_OF_SET=0               GATE_EXCLUDED=4
STATUS_LINES=11            HEAD=d2f5e5e               AHEAD=11                GIT_EXIT=0
PS1_SCAN_EXIT=0            PS1_MODE=Check             PS1_SCANNED=515         PS1_NON_ASCII_TOTAL=62
PS1_ASCII_CLEAN=453        PS1_NEW_NON_ASCII=0       PS1_ASCII_FLIPPED=0     PS1_RESOLVED=0
PS1_CHANGED_SAME_FLAG=1    PS1_MISSING_FROM_BASELINE=0  PS1_ASCII_VIOLATIONS=0
PS1_BASELINE_SHA16=5247D49A400CC3F9
RUN_AT=2026-11-25 22:28:25
```

- **精确等值命中 920**（不是「≥920」）。
- **例数归属**：882（Task 64/65/66 收口）→ 907（批次 B7 收口）→ **920**；B8 的 **W1+W2 合计 +13**、**W3 +0**、**W4 +0**（本棒零测试新增）。
  ⚠ `DESKTOP_DELTA=324` 是**累计增量**（相对脚本内历史常量 596），**不是本棒增量**（见 AGENTS §5 坑 57）。
- `PS1_SCANNED=515`（B7 收口时 502 → 本棒 +13 个新 `.ps1`，含本棒新建的 `task77-w4-drive.ps1` / `task77-w4-readback.py` 所在的 `.ps1` 家族），`PS1_ASCII_VIOLATIONS=0` ⇒ 本棒新增脚本**纯 ASCII** 合规。
- `STATUS_LINES=11` = §2 列的 11 行并发 relay 链脏文件；`OUT_OF_SET=0` 说明它们在门禁白名单内，且**本棒未越 R1 写集**。

---

## 5. 出包与分发核验

### 5.1 产物

| 项 | 值 |
|---|---|
| 出包装置 | `pwsh -NoProfile -ExecutionPolicy Bypass -File F:\soft\00selfmade\practilog\tools\build\make_installer.ps1 -Version '1.0.0'` |
| 产物 | **`release\actlog-Setup-1.0.0_20261125-222947.exe`** |
| 字节 | **22,817,510** |
| sha16 | **`8D9FE856CD7E882A`** |
| mtime | 2026-11-25 22:30:18 |
| `release\` 下 exe 总数 | **57 个** ⇒ **仅此 1 个可分发，其余 56 个严禁分发**（R3） |
| payload 目录 | `release\payload_20261125-222947\` = **36 个文件 / 60,403,598 B**（入包前 42 个 / 62,047,224 B，**排除 6 个** `userdata\*.db` 与日志） |

### 5.2 makensis 日志（判出包成功）

`F:\soft\00selfmade\practilog\.superpowers\makensis_out.txt`（**1,621 B / mtime 2026-11-25 22:30:18**）：

```
Output: "F:\soft\00selfmade\practilog\release\actlog-Setup-1.0.0_20261125-222947.exe"
Total size:                 22817510 / 60912494 bytes (37.4%)
```

`Total size` 的 **22817510 与产物字节数逐字一致** ⇒ 出包完成。
⚠ `reports\makensis_out.txt` **不存在**；`makensis exit = 0` 是 `make_installer.ps1` 的 **stdout**，不落该日志文件。

### 5.3 重编判据（只看 `data\app.so` 的 sha16，**不是字节数**）

| 位置 | 字节 | sha16 | mtime |
|---|---|---|---|
| 构建树 `apps\desktop\build\windows\x64\runner\Release\data\app.so` | 9,126,792 | **`3A9E57B8335F1307`** | 2026-11-25 21:46:02 |
| 装机 `D:\Program Files\actlog\data\app.so` | 9,126,792 | **`1A5E09068403A98A`** | 2026-11-25 16:06:36 |

- **两者字节数完全相同、sha16 不同** ⇒ **字节数相同不能当「同一个包」的证据**；本轮正是靠 sha16 才判出「构建树确已重编、装机侧仍是 B7 载荷」。
- 构建树 mtime **21:46:02 > W3 提交 21:44:30** ⇒ 构建树含 **W1/W2/W3** 改动。
- 装机侧 mtime 16:06:36 ⇒ 仍是 2026-11-25 16:13 的 B7 包。

### 5.4 装机取舍（本棒明确**只出包、不装机**）

- 理由一：覆盖安装会动 `D:\Program Files\actlog`（含 `userdata\*.db`），有污染**用户活库零写入**证据的风险。
- 理由二：安装器排除 `userdata\*.db`，覆盖安装与「保留用户数据」之间存在不可控面。
- 理由三：真机验收已经在**构建树 + 种子副本**上做完（§3），装机不增加结论强度，只增加不可逆动作。
- **代价（如实登记）**：**本包未在装机态验证过** ⇒ 装机后需重跑同一取证链复验；本包**不得登记为「已装机验收」**。

---

## 6. AGENTS.md 改动（部分暂存口径，坑 97）

工作树的 `AGENTS.md` 混有**并发 relay 链的未提交改动**（§2 R3 的 Task 72 真源行、§7 的 Task 72 块、§5 的坑 100–105、Relay §A/§B 等），本棒只加自己的三处：

| 位置 | 改动 | 落点 |
|---|---|---|
| §2 R3 · 分发禁令 | **新增一行真源**（本棒包为唯一可分发，其余 56 个严禁分发） | 插在 `### R3 · 分发禁令` 标题之后的第一条 |
| §5 本机工具坑速查 | **新增 3 条坑**（106 注入式真机驱动 / 107 makensis 日志落点 / 108 判重编必须比 sha16） | 接在原有最后一条坑之后（工作树 105 之后、基线 99 之后） |
| §7 当前状态快照 | **改写标题 + 新增 B8 收口条目块** | 标题行整行替换；新块插在标题之后、原有第一条之前 |

**部分暂存姿势**（禁用 `git add -p` / `stash` / `restore` / `git commit --only`）：

1. `git cat-file blob HEAD:AGENTS.md` **字节级**导出基线（`reports\agents-base-w4.md`，291,837 B / 纯 LF CR=0 / LF=505）；
2. 在基线副本上施加**同三处**改动 ⇒ `reports\agents-staged-w4.md`；
3. `git hash-object -w --no-filters` ⇒ `git update-index --cacheinfo 100644 <sha> AGENTS.md`；
4. 工作树保留 relay 链的 49 行改动不动（控制器**一字未碰**其内容，只在其前后插入本棒内容）。

⚠ 基线副本**不含** relay 链新增的坑 100–105 与 Task 72 真源行 ⇒ 提交后的 `AGENTS.md` 里 **§5 编号存在断层（94/95 缺号、100–105 缺号）**，与既有提交 `8c01455` 同款处理；这些行由其所属会话自行提交。

---

## 7. 未决与风险

### 7.1 未决（本棒无权裁，需控制器/用户决）

1. **U-8-x 仍未裁**：今日页右栏「目标/项目」卡是**保留只读展示**还是**整卡移除**？本棒真机已确认「只读卡、无 + 添加」落在地上，但**口径未获用户拍板**。
2. **U-8-y 仍未裁**：B7 遗留 MINOR-2（窄屏 `KeyBar` 缺 `Ctrl+7` 文字提示，`apps\desktop\lib\src\widgets\key_bar.dart:87`）是否并入下一批修。
3. **本包装机与否**：见 §5.4 ⇒ **本棒选「只出包不装」**（覆盖安装属不可逆动作 + 有污染活库证据的风险 ⇒ 留给用户决定）。

### 7.2 既有口径问题（非本批缺陷，如实登记）

- **年页空态**：种子库里明明有 `b7seed-yearly-1`（`kind=yearly`, `status=active`），年页却显示「本年还没有目标。」。
  归因 = 种子目标**缺 `domain` / `horizon`**（`domain=None horizon=None`），而年页取数条件要求这两个字段非空（计划 D-8-e 已指出这是「事实 3 的洞」，W1 的表单已补 `domain`+`horizon` 字段）。
  ⇒ **是既有口径 + 种子数据形态问题，不是 W2 的行级编辑/删除缺陷**；修法方向 = 补种子数据的 `domain`/`horizon`，或放宽年页取数条件。
- **W3 遗留两处**（挂账，本棒未动）：
  ① `week-goal-add-hint` 的**负断言**与「`lib` 内符号 0 命中」两条判据**字面互斥**（断言必须写出键名）；
  ② 外部 `goal://` 拖入仍会被 `DragTarget` 的通用判据（`details.data.contains(':')`）**高亮接住**，随后无匹配分支 ⇒ **静默丢弃、零写入、不弹框**（用户观感「亮了却没反应」未做真机确认）。

### 7.3 注入通道缺陷（**驱动侧，非产品缺陷，未改产品代码**）

| 现象 | 真因 | 处置 |
|---|---|---|
| `utext`（`KEYEVENTF_UNICODE`）在**创建表单内有效**、在**编辑弹窗内不插字** | 注入通道对 Flutter 文本输入法的兼容性差异 | 真机取证改用 `paste:`（剪贴板 + Ctrl+V）通道 |
| 输入被**转成全大写**（`TypeChar` 对小写也按 Shift） | 驱动脚本按键映射缺陷 | 同上；**不是产品代码问题**，未改 `apps\**` |
| **编辑弹窗打开后先点输入框 ⇒ 后续 `ctrl:back` / `paste` 全部无效**（帧字节完全不变） | 多余点击打断输入焦点 | 弹窗打开后**直接键盘输入**，不点输入框 |
| `keybd_event` 打字（scan=0 与 `MapVirtualKey` 两种）**不产生任何文字** | 本 Flutter 应用不接该通道 | 全程不用 |
| 驱动动作名写 `back` 被判 `UNKNOWN ACTION back` | 动词表要求 `ctrl:back` | 统一写 `ctrl:back` |

### 7.4 中途观察（**未单独留证文件，仅登记不采信为结论**）

21:59:46 前后一次操作后，读到 `goal` 的 `rev` 1→2 且 `due_date` 被补成 **2050-06-12**、提案面板呈内存态、**未点确认**、`todo` 仍为 1。
该现象**未在 `drive-log.txt` 或任何读回 txt 中单独留证**，因此**不作为结论**，仅登记待下一棒在装机态复现时优先核查（怀疑与 `due` 字段默认值/提案面板未确认即写库有关）。

### 7.5 其它风险

- **未跑活库写入**：本棒全部读写都在种子副本；用户活库零写入已用 sha256 逐字核对（§3.6）。
- **帧取自构建树、非装机件**：结论对**装机态**的适用性需 §5.4 复验补齐。
- **`reports\** 被 `.gitignore` 排除** ⇒ 帧 / 探针 / 日志**不入库**，只在工作区留档（与既有约定一致）。

---

## 8. 收工自检清单

- [x] 门禁四包 `analyze` 逐字 `No issues found!`（`ANALYZE=VERBATIM` ×4）
- [x] desktop 全量 **精确 920**（`DESKTOP_EXPECTED=920`）/ core_data 204 / core_db 96 / core_domain 91
- [x] `GATE_VERDICT=PASS` / `GATE_FAILURES=0` / `VIOLATIONS=0` / `OUT_OF_SET=0` / `PS1_ASCII_VIOLATIONS=0`
- [x] 真机链三棒功能全部有**帧 + SQLite 读回**双证（38 帧 + 5 读回 txt）
- [x] 蓝图页删除语义**软删除**坐实（`deleted_at` 有值 / `status` 仍 active / 三表不级联）
- [x] 目标页行级编辑 + 行级删除坐实（`rev` 1→2→3 / `updated_at` / `deleted_at` 落库）
- [x] 今日页右栏只读 + 右键菜单**无目标组**坐实
- [x] 用户活库**零写入**（sha256 逐字比对一致）
- [x] 出包产物字节 / sha16 / mtime 落盘回读；`release\` 共 57 个 exe，**仅 1 个可分发**
- [x] 重编判据用 **sha16**（构建树 `3A9E57B8335F1307` vs 装机 `1A5E09068403A98A`）
- [x] 本棒**未装机**，且已在 §5.4 与 §7.1 明确登记
- [x] `AGENTS.md` 部分暂存，**未带入**并发 relay 链的改动
- [x] 本台账已落盘，`CR=0`
- [x] 全程**未 push**（`git rev-list --left-right --count HEAD...@{u}` = ahead / 0 behind）
- [x] 全程只用 `git show` / `git cat-file` / `git status` / `git diff` / `git hash-object` / `git update-index` / `git add`（单文件）/ `git commit`；**未**用 `add -p` / `stash` / `restore` / `commit --only`

---

## 9. 回滚点

- **本棒 commit 之前的 HEAD = `d2f5e5e`**（回滚应回到此点）。
- 回滚会连带撤销：W4 台账 `docs\handoff-ledger-b8-w4.md` + `AGENTS.md` 的 §2 R3 新真源行 / §5 坑 106–108 / §7 新快照块。
- 回滚**不影响** W1/W2/W3 的产品代码（`fcf1cee` / `dbd95cd` / `d2f5e5e` 仍在）与**已出的安装包**（`release\` 下的 exe 不随 git 回滚消失；如需作废该包，须另行标记并重出包）。

---

## 10. 写集对账（`git status --porcelain -uall`）

**本棒入库内容**：

```
A  docs/handoff-ledger-b8-w4.md          （新增台账）
M  AGENTS.md                            （部分暂存：仅本棒三处）
```

**工作树残留（本棒一字未碰，属并发 relay 链）**：

```
 M AGENTS.md                            （relay 链的 49 行：§2 Task 72 真源行 / §7 Task 72 块 / §5 坑 100–105 / Relay §A§B）
 M docs/relay.json
 M docs/relay/stage-6-report.md
?? docs/b81-dispatch-w1-retry.md
?? docs/b82-dispatch-w2.md
?? docs/b83-dispatch-w3.md
?? docs/incident-20261125-phantom-rollback.md
?? docs/relay/auto-advance-design.md
?? docs/relay/gate-green-2026-11-25.md
?? docs/relay/relay-lock.ps1
?? docs/relay/start-relay.ps1
```

`reports\**` 未出现在 `git status`（`.gitignore` 生效），**未 `git add reports/`**。

---

## 11. 本轮新增的通用坑（已同步进 `AGENTS.md` §5，编号 106–108）

1. **106 · 注入式真机驱动只认三条通道**：`keybd_event` 打字（scan=0 与 `MapVirtualKey` 两种）**不产生任何文字**；`utext`（`KEYEVENTF_UNICODE`）在**创建表单有效、在编辑弹窗内不插字**；唯一保真通道是 `paste:`（`Clipboard.SetText` + `Ctrl+V`）。
   **编辑弹窗打开后不要先点击输入框** —— 多余点击会打断输入焦点，后续 `ctrl:back` / `paste` 全部无效（帧字节完全不变）。
   驱动参数是 **native 图像坐标**，屏幕坐标 = 参数 + (20, −56)（用 `drive-log.txt` 的 `CLICK_TARGET=… READBACK=…` 核对）。
   驱动动作名必须写 `ctrl:back`，写 `back` 被判 `UNKNOWN ACTION`。
2. **107 · makensis 日志的真实落点是 `.superpowers\makensis_out.txt`，且它不含退出码**：`reports\makensis_out.txt` **不存在**；判出包成功要看日志末段 `Total size: <产物字节数> / <原始字节数>` 与产物**逐字一致**；`makensis exit = 0` 是 `make_installer.ps1` 的 **stdout**，不落该文件。
3. **108 · 判「本包确含新代码」必须比 sha16，不能比字节数**：本轮构建树与装机 `data\app.so` 字节数**完全相同**（9,126,792 B）却 sha16 不同；字节数相同**既可能是同一个包、也可能是不同版本**。`actlog.exe` 更不能当判据（mtime 不随 Dart 改动变化）。

---

## 12. 本文件自检与证据路径清单

- 编码：UTF-8 无 BOM；换行：**纯 LF，`CR=0`**。
- 所有字节数 / 行数 / 时间戳 / sha16 / 测试数 / 门禁字段 / 例数归属均为本轮**盘上回读值**
  （`Get-Item`、`Get-FileHash`、`[IO.File]::ReadAllLines` / `ReadAllText`、
  `git show` / `git cat-file` / `git status --porcelain -uall` / `git rev-list`、
  读 `reports\task51-gate\summary.txt`），未从会话摘要抄录。

**证据路径清单**：

| 证据 | 路径 |
|---|---|
| 门禁摘要 | `F:\soft\00selfmade\practilog\reports\task51-gate\summary.txt` |
| 门禁脚本 | `F:\soft\00selfmade\practilog\reports\task51-gate.ps1` |
| 真机驱动脚本（本棒新建） | `F:\soft\00selfmade\practilog\reports\task77-w4-drive.ps1` |
| 真机读回脚本（本棒新建） | `F:\soft\00selfmade\practilog\reports\task77-w4-readback.py` / `reports\task77-goal-dump.py` |
| 帧 + 驱动日志 + 读回 | `F:\soft\00selfmade\practilog\reports\task77-frames\`（38 PNG + `drive-log.txt` + 5 个 `readback-W4-*.txt`） |
| 种子库副本 | `F:\soft\00selfmade\practilog\reports\task72-seeddb\`（`actlog.db` / `-wal` / `-shm` / `actlog_startup.log`） |
| 出包日志 | `F:\soft\00selfmade\practilog\.superpowers\makensis_out.txt` |
| 安装包产物 | `F:\soft\00selfmade\practilog\release\actlog-Setup-1.0.0_20261125-222947.exe` |
| payload 目录 | `F:\soft\00selfmade\practilog\release\payload_20261125-222947\` |
| AGENTS 基线快照（字节级导出） | `F:\soft\00selfmade\practilog\reports\agents-base-w4.md`（291,837 B / 纯 LF） |
| AGENTS 部分暂存暂存件 | `F:\soft\00selfmade\practilog\reports\agents-staged-w4.md` |
| AGENTS 编辑前备份 | `F:\soft\00selfmade\practilog\reports\agents-bak-20261125-223020.md` |
