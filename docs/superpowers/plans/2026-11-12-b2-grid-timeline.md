# B2 方格时间轴主屏 实施计划（2026-11-12）

> 本文件是**本轮唯一实现契约**。与 `2026-11-07-b1-flutter-implementation.md` 冲突时，**本文件优先**（B1 计划是历史批次，其「三段永不折叠」「习惯打卡吸底条」口径被本轮用户决定推翻）。
> 与用户当轮指令冲突时，**用户指令优先**。

**Goal:** 把 01 今日页从「三段式账页」改成「纵轴小时 / 横轴分钟的方格时间轴」，计划、回填、习惯三源合并入同一张格子；右轨加待办拖拽源；`Ctrl+3` 切到可用的 03 习惯页。

**Tech Stack:** Flutter 3.47.9（`F:\soft\flutter\flutter\bin\flutter.bat`）· flutter_riverpod ^3.0.0 · drift ^2.35.0 · `packages/core_data` 仓储层（本轮**不改**）

---

## 0. 零 schema 变更（硬约束）

`docs/schema_v1.sql` 已 FROZEN，`todo` 与 `habit_checkin` **都没有时间列**。本计划**不新增表、不新增列、不加 migration**，全部语义靠既有列派生：

| 用户需求 | 落库方式（全部既有列） |
|---|---|
| 格子里的一条内容 | `plan_item` 一行；`planned_start` / `planned_end` = **当日分钟数**（0–1440 的 INTEGER） |
| 「当前之后 = 计划 / 当前或之前 = 回填」 | **不落库**，读取时按 `planned_start` 与「现在」比较**派生**（见 §2） |
| 习惯入格 | `plan_item` 行：`source_type='habit'`、`source_id=habit.id`、`is_habit_ref=1`、`title=habit.name` |
| 习惯打卡 | 同上行的 `status='done'` + 同日 `habit_checkin(status='done', value=1)` **双写**（同事务） |
| 待办入格 | `plan_item` 行：`source_type='todo'`、`source_todo_id=todo.id`、拷贝 `title` |
| 待办池「已填时间」 | **派生**：存在未删除的 `plan_item` 且 `source_todo_id = todo.id` ⇒ 视为已排期 |
| 完成打勾 | `plan_item.status`：`'done'` / `'pending'`；完成时写 `done_at` |
| 回填默认打勾 | 创建回填条目时直接 `status='done'` + `done_at` |

**禁止**：改 `packages/core_db/lib/src/tables.dart`；改 `currentSchemaVersion`；在 `packages/**` 下加任何东西（本轮 `dart test` 基线 **必须仍是 +141**）。

---

## 1. 写入集（worker 可写，别的一律不许碰）

```
apps/desktop/lib/src/app.dart
apps/desktop/lib/src/providers.dart
apps/desktop/lib/src/widgets/date_bar.dart
apps/desktop/lib/src/widgets/timeline/**            ← 新建目录
apps/desktop/lib/src/pages/today_page.dart
apps/desktop/lib/src/pages/habits_page.dart          ← 新建
apps/desktop/lib/src/pages/todo_pool_page.dart
apps/desktop/lib/src/widgets/shell/nav_rail.dart
apps/desktop/lib/src/theme/app_tokens.dart
apps/desktop/test/timeline_*.dart                    ← 新建
apps/desktop/test/nav_rail_test.dart                 ← 仅当已存在时增量改
apps/desktop/test/habits_page_test.dart              ← 新建
apps/desktop/test/todo_pool_*.dart                   ← 新建或增量改
design-demos/TOKENS.md                               ← **只许改 §8**
```

**只读、不许改**：`packages/**`、`apps/desktop/lib/src/theme/app_theme.dart`、`apps/desktop/lib/src/widgets/shell/ledger_shell.dart`、`design-demos/TOKENS.md` §1–§7、`docs/schema_v1.sql`、`apps/desktop/lib/src/widgets/{standup_section,habit_section,habit_checkin_strip}.dart`（**保留文件，只取消引用**）。

---

## 2. 派生状态：唯一的真源函数

新建 `apps/desktop/lib/src/widgets/timeline/slot_state.dart`，只放**纯函数**（便于单测，无 Flutter 依赖除 `material` 的颜色常量）：

```dart
/// 一个格子里的内容属于哪一类视觉态。
enum SlotKind { plannedOpen, plannedDone, backfill, habit }

/// 现在 = 当日第几分钟。
int minuteOfDay(DateTime now);

/// 回填判定：过去日全部算回填；今天按 planned_start <= now；未来日全不算。
bool isBackfill({required String date, required String today, required int plannedStart, required int nowMinute});

/// 视觉态。判定顺序 **habit → backfill → done → plannedOpen**，
/// 顺序不可调换：回填条目默认 status='done'，若先判 done 会把回填吞进「完成计划」。
SlotKind slotKindOf({required bool isHabit, required bool isBackfill, required bool isDone});
```

**验收判据（必须有单测）**：
- 今天 09:00 的条目在 `nowMinute=600` 时 = `backfill`，在 `nowMinute=480` 时 = 非回填。
- 过去日期任何 `plannedStart` 都是 `backfill`；未来日期都不是。
- `isHabit=true` 且 `isBackfill=true` 且 `isDone=true` ⇒ `SlotKind.habit`（habit 优先级最高）。
- `isBackfill=true` 且 `isDone=true` ⇒ `SlotKind.backfill`（不是 `plannedDone`）。

---

## 3. 四种视觉态与配色（`TOKENS.md` **只许改 §8**）

在 `design-demos/TOKENS.md` **§8** 追加下表，并在 `apps/desktop/lib/src/theme/app_tokens.dart` 加同名常量。§1–§7 **逐字节不得改**。

| token | 值 | 语义 | 前景 |
|---|---|---|---|
| `--slot-plan` | `#E8ECF1` | 未完成的计划 | `--ink #2E4057` ⇒ 10.1:1 |
| `--slot-done` | `#F1F2F0` | 完成的计划（**有意退居背景**，靠 `✓` + 删除线双通道） | `--meta #5F584B` ⇒ 6.4:1 |
| `--slot-backfill` | `#EDE4D6` | 回填 | `--ink #2E4057` ⇒ 9.3:1 |
| `--slot-habit` | `#DCE4EC` | 打卡 | `--ink #2E4057` ⇒ 10.9:1 |

（对比度数字 worker **必须用仓库里的 `contrast.dart` 实测后填真值**，不许抄本文数字；若实测 < 4.5:1 就地调亮到合格并在 §8 记真值。）

**赭石纪律不破**：`--accent` / `--accent-wash` **不参与**这四态。状态同时用**形状+文字**双通道，字符集沿用既有约定：`○` 未完成计划 · `✓` 完成计划 · `▸` 回填 · `●` 打卡。

格内条目样式：左边缘 2px 竖条（颜色 = 该态文字色）、文字 14px、`--radius 4`、内边距 6×4。

---

## 4. 方格几何

新建 `apps/desktop/lib/src/widgets/timeline/day_grid.dart`。

- **纵轴**：`06:00 – 24:00`（沿用 `StartEndPicker` 既有口径），共 18 个整点行。
- **横轴**：默认 **15 分钟**一格（每小时 4 列，共 72 格）。常量 `const int kSlotMinutes = 15;`，5 分钟档只留常量位（`kSlotMinutes = 5` 时可编译），**不提供运行时切换 UI**（避免假按钮）。
- **行高**：`const double kHourRowHeight = 44;`（18×44=792px，落在标准账页里可纵向滚动）。
- 渲染：`CustomPaint` 画网格线（`--hair` 细线 + 每 3 小时 `--hair-strong`），条目用 `Stack` + `Positioned` 叠加，**不要**给 72 个格子各建一个 `InkWell`。
- 左轴标签列宽 = `AppTokens.tlWidth`（宽）/ `tlWidthNarrow`（窄），复用 `tlWidthFor(width)`；**不要**新造第二套断点。
- 时间轴区必须可纵向滚动，且**不许**用 `Stack` + `Positioned` 把任何条压在上层壳（`LedgerShell` 的 dock/keybar 是列兄弟的既有铁律不得破）。

---

## 5. 交互：右键三级菜单

新建 `apps/desktop/lib/src/widgets/timeline/slot_context_menu.dart`。

`showMenu` 不支持 hover 子菜单 ⇒ 用 `OverlayPortal` + `Positioned` 自绘定位面板（点击外部 / `Esc` 关闭）。

结构（**行序固定**）：
1. 若该格已有内容 ⇒ 最上面插入「编辑：<标题>」行（多行重叠时每行一条，最多显示 3 条 + 「…」）。
2. `手填` —— **hover** 展开子菜单：`空白手填`（新建 `source_type='manual'`）。
3. `待办` —— **hover** 展开子菜单：`todoPoolProvider` 里 `status='open'` 且**未排期**（无未删除 `plan_item.source_todo_id`）的待办，按 `created_at` 倒序，最多 12 条 + 「更多…」；空列表显示只读 `暂无可选待办`（不许假按钮）。
4. `习惯` —— **hover** 展开子菜单：`archived=0` 的习惯（`habitsForTodayProvider` 口径），最多 12 条。

选中任一条 ⇒ 打开 §6 的 `SlotRangeDialog`，`planned_start` 预填为右键所在格，`planned_end = start + 15`。

**验收判据**：右键菜单三行文字逐字为 `手填` / `待办` / `习惯`；hover 后子菜单出现；已排期待办在子菜单中出现次数 = 0（先用「有已排期待办」的沙箱证明判据能看见它，再证明排除生效）。

---

## 6. 拖拽 + 起止范围弹窗

新建 `apps/desktop/lib/src/widgets/timeline/slot_range_dialog.dart` 与 `todo_rail_panel.dart`。

- `SlotRangeDialog`：一条**可拖动的起止范围**（`RangeSlider` 或自绘拖动条，15 分钟吸附），显示 `09:15 – 10:00` 文案；`确定` / `取消`；键盘 `Esc` 取消、`Enter` 确定。
- 右轨 `TodoRailPanel`（`ShellRailPanel` 的子节点，不是新面板类型）：`todoPoolProvider` 的 open 待办列表 + 活跃习惯列表；每条是 `Draggable<String>`，payload `todo:<id>` / `habit:<id>`；`feedback` 是窄条卡片。
- 网格是 `DragTarget<String>`：`onAcceptWithDetails` ⇒ 用落点格算 `plannedStart` ⇒ 打开 `SlotRangeDialog` ⇒ 落库。
- **已有条目可拖动改起止**：条目本身 `Draggable<String>`，payload `plan:<id>`；拖到别的格 ⇒ 打开 `SlotRangeDialog` 预填该条目，确定后 `update` 起止。**保持 `id` 不变**，只改 `planned_start/planned_end/updated_at/rev`。

**判据**：拖动结束（`onAcceptWithDetails` 真的被调用）才开弹窗；拖起但落在网格外必须**不留任何脏行**。

---

## 7. 页面改造

### 7.1 `today_page.dart`
- **删除**这三个引用：`StandupSection`、今日计划段、`HabitSection`（文件保留，不删）。
- **新增** `DayGrid` 作为首个主区块。
- `MoodSection` / `ReviewSection` **保留**（用户未要求删，闭环环 `dayStatsProvider` 仍依赖它们）。
- 保留 `DateBar` 在顶部。

### 7.2 `date_bar.dart`（需求 1）
改为**单行**：`‹` · `昨天` · `日期` · `明天` · `›`
- 顺序**固定**：左箭头 → 昨天按钮 → 日期 → 明天按钮 → 右箭头。左右箭头**紧贴日期两侧**。
- 单行：外层 `Row`，日期居中区 `Flexible` + `FittedBox(fit: BoxFit.scaleDown)`，**任何档位不许换行、不许溢出**（大字号档 `PRACTILOG_TEXT_SCALE=2` 下实测无 `RenderFlex overflow`）。
- `‹` / `›` = 前后一天（文案保持只读无歧义：tooltip 写 `前一天` / `后一天`）。
- `昨天` / `明天` 按钮文案**恒为「昨天」「明天」**（不再按 `_navLabel` 变成星期），跳转到 `today-1` / `today+1`。
- 保留 `date-bar-prev` / `date-bar-next` / `date-bar-today` 三个 `ValueKey`（既有测试依赖，**不许改 key**）；新增 `date-bar-yesterday` / `date-bar-tomorrow`。
- 保留「补录模式 / 预排」只读徽标与「今天」按钮（非今天才显示）。

### 7.3 `nav_rail.dart` + `app.dart`（需求 3、8）
- `kShellNavItems` 里 `habits` 的 `enabled` 改 `true`；`today` / `inbox` / `calendar` / `habits` 四项全部可点。
- `app.dart` 快捷键：`Ctrl+1 → today`、`Ctrl+2 → inbox`、**`Ctrl+3 → habits`**、`Ctrl+4 → calendar`（calendar 让位，避免两个键绑同一页）。
- `_content()` 增 `habits` 分支 → `HabitsPage`。
- `_NavFoot` 底注文案 `Ctrl + 1 … 3` 改为 `Ctrl + 1 … 4`（12→12 字符不变，大字号档三行堆叠结构不变）。
- `_dock()`：今日页**不再**挂 `HabitCheckinStrip`（需求 3 去除习惯打卡）⇒ `_dock()` 整体返回 `null` 或移除该分支，`HabitCheckinStrip` 文件保留不删。
- `_railPanels()` 今日页：`HabitOverviewPanel` + `LoopHintPanel` 之后追加 `TodoRailPanel`（需求 4）。

### 7.4 `habits_page.dart`（需求 8）
新建页面：`DateBar` + 活跃习惯列表（名称、`type` 中文标签、今日打卡状态、勾选按钮）+ 打卡/撤销（写 `habit_checkin`）。
- 底部 `keyHints` 用 `kShellKeyHints` 默认值。
- 空态显示只读文案 `还没有习惯`，**不放假按钮**。

### 7.5 `todo_pool_page.dart`（需求 7）
新建待办表单加**可选时间**：`起始时间`（15 分钟吸附，默认空）+ `预计时长`。
- 留空 ⇒ 只建 `todo` 行（现状不变）。
- 填了 ⇒ **同一事务内**建 `todo` 行 + 当天 `plan_item` 行（`source_type='todo'`、`source_todo_id`、拷贝 title、写 `planned_start/planned_end`、`status='pending'`）。
- 已有 todo 的列表行显示只读徽标 `已排期 09:15`（由 §0 的派生规则算出）；`已排期` 的待办在 §5 右键子菜单中**不出现**。

---

## 8. 门禁（worker 自测，控制器复跑）

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
# 跑全量前先把测试缓存改名挪走（不删），否则 OS Error 183
Rename-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' "build_stale_<ts>" -ErrorAction SilentlyContinue
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze     # 期望逐字 No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact   # 基线 +231，本轮只许增不许减
```

- `flutter analyze` 逐字 `No issues found!`（error/warning/info 全 0）。
- desktop 全量测试 **≥ +231 且 0 failed**（新增用例把数字抬高是正常的，回落即回退）。
- BI 口径：`packages/**` 未动 ⇒ core `dart test` 仍是 **+141**（worker 不用跑，控制器复跑）。
- Dart 源 **LF、无 BOM**；`.ps1` 若新增必须纯 ASCII + CRLF + 无 BOM；`print(` 计数 **0**。
- 不许改 `analysis_options.yaml`、不许加 `// ignore:` 绕过。

---

## 9. 硬性禁止（复核会逐条查）

1. 改 `packages/**` 或 `docs/schema_v1.sql`。
2. 改 `design-demos/TOKENS.md` §1–§7 或 `theme/app_theme.dart` / `shell/*.dart`。
3. **删**任何文件（`standup_section.dart` / `habit_section.dart` / `habit_checkin_strip.dart` 必须留盘）。
4. 假按钮：任何 `enabled` 但无实现的入口。
5. 改动既有 `ValueKey`（`date-bar-prev` / `date-bar-next` / `date-bar-today` / `shell-nav` / `shell-keybar` / `shell-ledger-paper` / `shell-rail`）。
6. 用 `PRACTILOG_TEXT_SCALE` 当作显示缩放的证据。
7. 把「搜索 X 得到 0」当成「X 已排除」的证据 —— 必须先证明判据能看见目标。

---

## 10. Task 清单（worker 逐项自检后打 `[x]`）

- [x] **T1** `slot_state.dart` 纯函数 + 4 条单测（§2 判据）
- [x] **T2** `TOKENS.md` §8 四个 token + `app_tokens.dart` 常量 + 实测对比度填真值
- [x] **T3** `day_grid.dart` 方格渲染（18 行 × 4 列，可滚动，无溢出）
- [x] **T4** `slot_context_menu.dart` 三级右键菜单 + 已排期待办排除
- [x] **T5** `slot_range_dialog.dart` 拖动起止 + `Esc`/`Enter`
- [x] **T6** `todo_rail_panel.dart` 右轨待办/习惯列表 + `Draggable`
- [x] **T7** 网格 `DragTarget` + 条目拖动改起止（`id` 不变）
- [x] **T8** `today_page.dart` 接 `DayGrid`、移除三块引用
- [x] **T9** `date_bar.dart` 单行五件套 + 大字号不溢出
- [x] **T10** `nav_rail.dart` 习惯可用 + `app.dart` `Ctrl+3→habits`、`Ctrl+4→calendar`、去 dock
- [x] **T11** `habits_page.dart` 打卡/撤销
- [x] **T12** `todo_pool_page.dart` 可选时间 + 同事务建计划 + `已排期` 徽标
- [x] **T13** `flutter analyze` 逐字 `No issues found!` + 全量测试 ≥ +231 / 0 failed