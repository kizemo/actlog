# B2 四态「形状+文字」双通道 实施计划（2026-11-12 · Task 29）

> 本文件是**本轮唯一实现契约**。与 `2026-11-12-b2-grid-timeline.md` 冲突时**本文件优先**；与用户当轮指令冲突时**用户指令优先**。
> 上一轮契约：`2026-11-12-b2-grid-timeline.md` §3 要求「状态同时用**形状+文字**双通道」，但实现只落了背景色单通道 ⇒ **本轮是补齐合同缺口，不是新需求**。

**Goal:** 给今日页方格时间轴的四态补上「形状 + 文字」冗余通道，使四态在**色觉障碍 / 灰度打印 / 截图转述**下仍可分辨；同时给完成态加删除线、给格内条目加左缘 2px 竖条（上一轮计划 §3 同段明文要求，同样未落地）。

**用户当轮决定（2026-11-11）**：本轮**只做四态双通道**，不连带 #8 隐式时钟契约、#6 像素级对比度验证、#7 date_bar 窄视口覆盖。

**Tech Stack:** Flutter 3.47.9（`F:\soft\flutter\flutter\bin\flutter.bat`）· 零 schema 变更 · `packages/**` 零改动。

---

## 1. 前置实测（控制器已做完，worker 直接采信，不重测）

### 1.1 字形覆盖（证据：`reports\task29-glyph-matrix.txt`，脚本 `reports\task29-glyph-matrix.py`）

对 9 个随包 ttf 逐文件读 cmap：

| 字形 | 码位 | 覆盖 |
|---|---|---|
| `○` WHITE CIRCLE | U+25CB | 仅 `NotoSansSC-Regular.ttf` |
| `✓` CHECK MARK | U+2713 | 仅 `NotoSansSC-Regular.ttf` |
| `●` BLACK CIRCLE | U+25CF | 仅 `NotoSansSC-Regular.ttf` |
| `▶` BLACK RIGHT-POINTING TRIANGLE | U+25B6 | 仅 `NotoSansSC-Regular.ttf` |
| `▸` BLACK RIGHT-POINTING SMALL TRIANGLE | U+25B8 | **0 / 9 随包字体覆盖** |

**结论 1（硬约束）**：上一轮计划 §3 写的 `▸`（U+25B8）**在任何随包字体里都不存在** ⇒ 运行时必然静默回退到系统字体，跨机器不可控。**本轮改用 `▶`（U+25B6）**，形状语义不变（黑色右指三角），零系统回退。

**结论 2**：四个字形都不在 Inter 里，**只能由 `Noto Sans SC` 兜底渲染** ⇒ 字形 `Text` 必须能拿到 `AppFonts.bodyFallback`（首选 `Noto Sans SC`）。字形 `Text` **必须显式写** `fontFamily: AppFonts.body` + `fontFamilyFallback: AppFonts.bodyFallback`（不许只靠继承，避免将来 `DefaultTextStyle` 变动导致豆腐块）。

**结论 3**：`Inter` 覆盖 `»`（U+00BB）9/9，但它是指引号不是三角，不用。

### 1.2 现状（实测源码）

`apps\desktop\lib\src\widgets\timeline\day_grid.dart`
- `:250-269` `_chipShell`：`BoxDecoration(color: colorOfSlotKind(entry.kind), borderRadius: radius, border: Border.all(hair))` —— **无左缘竖条**。
- `:315-380` `_chipBody`：`Row[LedgerCheckbox, SizedBox(5), Text(startMinute 10px), SizedBox(5), Flexible(Text(title 11px)), note?, habitBadge?, 删除?]` —— **无字形、无状态文字、标题无删除线**。
- `--slot-done #F1F2F0` 与 `--slot-plan #E8ECF1` 近乎同色 ⇒ 完成态目前**没有任何可辨识通道**。

### 1.3 配色 token（`apps\desktop\lib\src\theme\app_tokens.dart` 实测）

`ink #2E4057` / `ink2 #3D5170` / `meta #5F584B` / `faint #6E6759` / `hair #DCD5C6` / `radius 4`；四态底色 `slotPlan/slotDone/slotBackfill/slotHabit` 已存在，**四态前景色尚无**。

---

## 2. 写入集（worker W1 可写，别的一律不许碰）

| 行 | 路径 | 本轮动作 |
|---|---|---|
| W1 | `apps\desktop\lib\src\widgets\timeline\slot_state.dart` | 新增四态 → 字形 / 状态文字 / 前景色的**纯函数映射** |
| W1 | `apps\desktop\lib\src\widgets\timeline\day_grid.dart` | 条目渲染：左缘 2px 竖条 + 字形 + 状态文字 + 完成态标题删除线 |
| W1 | `apps\desktop\lib\src\theme\app_tokens.dart` | 新增四态前景色常量 |
| W1 | `apps\desktop\test\timeline_slot_state_test.dart` | **追加**（不改既有断言）纯函数映射用例 |
| W1 | `apps\desktop\test\timeline_day_grid_test.dart` | **追加**（不改既有断言）widget 用例 |
| W1 | `design-demos\TOKENS.md` | **只许在 §8 追加**；§1–§7 **逐字节不得改** |
| C | `docs\superpowers\plans\*.md` · `.superpowers\sdd\...\task-29-w1-brief.md` · `reports\task29-*` · `docs\B1_验收记录.md` · `AGENTS.md` · `.superpowers\sdd\...\handoff.md` · `...\progress.md` | **控制器独占**（台账行） |

**只读、不许改**：`packages\**`（`dart test` 基线必须仍是 **+141**）、`docs\schema_v1.sql`、`packages\core_db\lib\src\tables.dart`、`apps\desktop\lib\src\theme\app_theme.dart`、`apps\desktop\lib\src\theme\app_fonts.dart`、`apps\desktop\lib\src\widgets\shell\**`、`design-demos\TOKENS.md` §1–§7、既有 `ValueKey`（`day-grid-entry-*` / `plan-row-focus-*` / `focus-ring-border-plan-row` / `rail-todo` / `rail-habit` 等）。

---

## 3. 目标形态（上一轮计划 §3 的逐条落地，措辞以本节为准）

### 3.1 四态映射表

| 态 | 字形（形状通道） | 状态文字（文字通道） | 前景色 | 标题删除线 |
|---|---|---|---|---|
| `plannedOpen` | `○` | 计划 | `--ink #2E4057` | 否 |
| `done` | `✓` | 完成 | `--meta #5F584B` | **是** |
| `backfill` | `▶` | 回填 | `--ink #2E4057` | 否 |
| `habit` | `●` | 打卡 | `--ink #2E4057` | 否 |

「赭石纪律」不破：`--accent` / `--accent-wash` **不得**参与这四态。

### 3.2 条目布局（`Row` 从左到右，顺序固定）

```
[左缘 2px 竖条（前景色）] [字形 11px 前景色] [状态文字 10px 前景色] [LedgerCheckbox] [5] [起始时间 10px faint] [5] [标题 11px ink2，done 态加删除线] [进展?] [习惯徽标?] [删除?]
```

- 状态标记放在**最左**，与竖条一起构成网格左缘的「状态列」，便于纵向扫读；复选框 / 时间 / 标题的**相对顺序保持不变**。
- 既有 `习惯回填` 徽标保留不动。
- 15 分钟格净高 22px：字形 11px、状态文字 10px，**不得**因此触发 `RenderFlex overflowed`。

### 3.3 对比度

四态前景色对各自底色的对比度**必须用仓库里的 `contrast.dart` 实测后填真值**（不许抄本文件数字）。四组均须 ≥ 4.5:1；不足就地调亮并在 `TOKENS.md` §8 记真值。

---

## 4. Task 清单（worker 逐项自检后打 `[x]`）

- [x] **T1** `slot_state.dart` 增四态映射纯函数（字形 / 状态文字 / 前景色），**纯函数、无 Flutter 依赖**
- [x] **T2** `app_tokens.dart` 增四态前景色常量（值按 §3.1）
- [x] **T3** `day_grid.dart` 渲染左缘 2px 竖条 + 字形 + 状态文字 + done 态标题删除线
- [x] **T4** `TOKENS.md` **§8 追加**：四态字形集（含 `▶` 替代 `▸` 的实测理由）/ 状态文字 / 前景色 / 竖条 / 删除线 / 实测对比度；§1–§7 逐字节未改
- [x] **T5** 单测追加（既有断言一字不改），含**判别力自证**
- [x] **T6** `flutter analyze` 逐字 `No issues found!`；desktop 全量 ≥ +269 且 0 failed；`packages\**` 零改动

---

## 5. 门禁（控制器亲跑，worker 只自测）

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Rename-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' "build_stale_<ts>" -ErrorAction SilentlyContinue
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze     # 期望逐字 No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact   # 基线 +269，只许增不许减
```

| 判据 | 期望 |
|---|---|
| `flutter analyze`（desktop） | 逐字 `No issues found!`（error/warning/info 全 0） |
| desktop 全量 `flutter test` | ≥ **+269**、0 failed |
| core_data 全量 `dart test` | **+141**（`packages\**` 零改动也要实跑） |
| 越界比对 | `VIOLATIONS=0` |
| Dart 源 | LF、无 BOM、`print(` 计数 0 |
| `TOKENS.md` §1–§7 | 逐字节未改（sha16 比对） |

---

## 6. 硬性禁止（复核逐条查）

1. 改 `packages\**` 或 `docs\schema_v1.sql`。
2. 改 `TOKENS.md` §1–§7 或 `theme\app_theme.dart` / `theme\app_fonts.dart` / `shell\**`。
3. **删**任何文件。
4. 用 `▸`（U+25B8）—— 实测 0/9 随包覆盖，会渲染成豆腐块或静默走系统字体。
5. 改既有 `ValueKey`；造假按钮；改既有测试的断言（只许追加）。
6. `PRACTILOG_TEXT_SCALE` 顶替显示缩放证据。
7. 「搜索 X 得到 0」当成「X 已排除」—— 必须先证明判据能看见目标。
8. 加 `// ignore:` 或改 `analysis_options.yaml` 绕过门禁。
