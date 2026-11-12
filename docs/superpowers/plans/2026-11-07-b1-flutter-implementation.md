# B1 Flutter 实施计划（今日主屏 · 日期 · 闭环环）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 B 版「墨径 · 账页流」设计从已获批的 HTML 原型搬进 Flutter 桌面端，交付 spec §14 的 B1 批次：`selectedDateProvider` + `DateBar` + `DatePickerSheet` + `CalendarMonthView` + `LoopProgressRing`/`dayStatsProvider` + `OutcomeComposer` + `DurationChips` + `HabitCheckinStrip` + 键盘可达，并以 `flutter build windows` 产物真机 + 打包 exe 为验收依据。

**Architecture:** 三层落地 —— ① `packages/core_domain` / `packages/core_data` 放**纯函数**（`result_note` 文法编解码、日历网格），不动 schema v1；② `apps/desktop/lib/src/theme` 放 B 版 token / 密度档 / 主题，取代当前 `colorSchemeSeed = Color(0xFF2E8B57)` 的旧绿；③ `apps/desktop/lib/src/widgets` 放 28 个共享组件中的 B1 子集，全部走**芯片点选**，写库只落既有 TEXT/INT 列。所有「闭环环」数字只允许由 `dayStatsProvider` 一处算出，其余 widget 只读它。

**Tech Stack:** Flutter 3.47.9 stable / Dart 3.13.7（`F:\soft\flutter\flutter\bin\flutter.bat`）· flutter_riverpod ^3.0.0 · drift ^2.35.0 · packages/core_domain（纯 Dart）· packages/core_data（纯 Dart 仓储）· packages/core_db（drift 表，FROZEN）

## Global Constraints

以下约束对**每个任务**都生效，不再在任务里重复。

- **schema v1 冻结**：不改 `docs/schema_v1.sql`，不新增表/列，不改 `packages/core_db/lib/src/tables.dart` 的列定义，不升 `currentSchemaVersion`。需要新设置项一律落 `settings.key`（该表无 CHECK 白名单，不需要 migration）。
- **视觉口径唯一真源**：`design-demos/TOKENS.md`。本计划的 token 名与值全部抄自该文件，不得凭记忆改写。
- **B1 落地色**：浅色档，页面底 `--paper #F6F4EF`；主墨 `--ink #2E4057`；**赭石 `--accent #8C5A2B` / `--accent-ink #7A4E24` 只许用于「缺口 / 警示」语义**与**拒绝类芯片选中态**（`ChipOption.deny`，见 TOKENS.md §1.5 第 4 条），不得当 primary、不得当普通芯片选中态、不得当焦点环。
- **选中态一律 `--ink` 反白**（`onPrimary = --paper`），焦点环一律 `--ink` 2px 实线（Flutter 侧用 `Focus` + 2px 边框实现，不用 `accent`）。
- **无障碍硬底线**：正文 ≥14px、标签 ≥12px；文字对比度 ≥4.5:1；**可交互边界 ≥3:1**。
- **`--hair-strong` 落地值 = `#8A8170`**（原型实测值 `#B9AE96` 仅 2.00–2.10:1，不合规，已废）。实测最差对比 3.19:1（对 `--ink-wash` / `--accent-wash` 底）。原型 HTML `design-demos/v2-ledger.html` 保持 `#B9AE96` 不动（B 视觉语言已获批），差异由本条约束覆盖。
- **`--hair` / `--hair-soft` 只能承载纯装饰分隔线**（段头下沿、栏边、卡片常态边）。**不得**承载可交互边界；现状 `.chip` / `.cell` / `.btn.ghost` / `.dbtn` / `.hchip` 的常态边框实测仅 1.33–1.40:1，迁到 Flutter 时这些边界一律改用 `--hair-strong`（Task 2 / Task 7 落地，Task 17 用 G4 脚本卡死）。
- **密度三档只换一组变量**（`--fs-body` / `--lh` / `--fs-label` / `--fs-h2` / `--pad-card` / `--gap-sec`），列宽、时间轴宽度、栏宽不随密度变；Flutter 侧做成 `DensityProfile` 枚举（Task 2 产出）并由 `AppTheme` 按档取值（Task 3），**禁止逐处写死像素**；运行时密度切换 UI 在 B4（`DensitySettings` 不在 B1 范围），故 B1 不需要 ThemeExtension。
- **圆角 4px，禁止大圆角卡**；卡片间距 12px；段间距 22px（舒适档）；时间轴节点列宽 64px、轴列与正文列间距 12px（<1280px 断点降为 52 / 10）。
- **状态永远是「形状 + 文字」双通道**，字符集：`✓` 完成 · `●` 进行中 · `○` 未开始 · `▸` 待写/可展开 · `▲` 未打分 · `⚠` 漏复盘。禁止彩色 emoji 当图标。
- **禁用 `print`**（根 `analysis_options.yaml` 对 `packages/` 强制 `avoid_print` 为 error）；`packages/` 的公开成员**必须有 doc comment**（根强制 `public_member_api_docs`）。
- **Dart 源文件 LF、无 BOM**；`tools\*.ps1` 纯 ASCII + CRLF + 无 BOM；`.nsi` UTF-8 带 BOM + LF。
- **验收只能看构建产物**：`flutter dev` 不可用于界面验收；需要装机实测的流程直接跑 `tools\build\make_installer.ps1` 打包 exe，不等用户要求。
- **非 git 仓库**（`F:\soft\00selfmade\practilog` 无 `.git`）：每个任务**不得**把「Commit」当唯一验证闸门；每个任务以「可跑的命令 + 落在磁盘上的产物/证据文件」收口。
- **中国镜像必须进程内设置**（当前 shell 两者为空）：
  ```powershell
  $env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
  ```
- **门禁跑法**：`flutter analyze` / `flutter test` 在 `F:\soft\00selfmade\practilog\apps\desktop` 跑；`packages/*` 各自 `dart test`（门禁脚本 `tools\gates\g2_unittest.ps1` 以 `WorkingDirectory=packages\<name>` 跑）。根目录没有 `test/`，别在根跑 `flutter test`。
- **现有关门禁只有 G1–G3**（`tools/gates/g1_analyze.ps1`、`g2_unittest.ps1`、`g3_migration.ps1`）；G4–G8 尚无脚本，本计划在 Task 17 补 G4（对比度/视觉门禁）。

---

## 0. 组件映射总表（spec §13.1 的 **28** 个组件）

> **计数出入（必须如实记录）**：交接文档 `docs/HANDOFF_20261107_B版原型收口_转Flutter实施.md` 写「27 个组件」，但 spec §13.1 实际逐个列出了 **28** 个名字。本计划按 **28** 个映射，不做删减；差异记在本文，不去改只读的 spec。

| # | 组件 | TOKENS.md token（章节） | 验收判据（可测） | 批次 | 任务 |
|---|---|---|---|---|---|
| 1 | `LoopProgressRing` | `--ink` 主墨 · `--accent` 缺口段 · `--hair-strong` 环边 · 数字 `tabular-nums`（§1.2/§1.3/§1.5/§2） | 四个数字全部可点，点击滚到对应段并给缺项段加 2px 强调描边；口径只来自 `dayStatsProvider`；`x=0` 时回填显示 `—`（不显示 100%） | B1 | Task 10 |
| 2 | `DateBar` | `--meta` 次级 · `--faint` 弱文字 · 焦点环 `--ink` · `--accent-wash` 徽标底（§1.2/§1.3/§1.5/§5） | 形如 `‹ 昨天　2026-11-07 周六　明天 ›`；非今天显示 `补录模式`（过去）/ `预排`（未来）；`今天` 按钮仅非今天可点 | B1 | Task 11 |
| 3 | `DayTimeline` | `--tl-w 64px` · `--tl-gap 12px` · 状态字符 `✓ ● ○ ▸`（§3/§6） | 三段永不折叠隐藏；节点「形状 + 文字」双通道；宽度 <1280px 时轴列降为 52px 且无横向溢出 | B1 | Task 15 |
| 4 | `SectionHeader` | `--fs-h2 19px` · `--gap-sec 22px` · `--hair` 下沿 · `--accent` 缺项高亮（§2/§3/§1.3/§1.5） | 段头带完成徽章（如 `3/5`）；有缺项时标题行出现 `2px` 强调描边 + 一次性提示 | B1 | Task 7 |
| 5 | `ChipRow` | 芯片高 26px · `--fs-label 12.5px` · 间距 6px + 强制换行 · 选中 `--ink` 反白（§5/§2/§3） | 单选互斥、多选可为空；全部芯片 Tab 可聚焦、`Space`/`Enter` 触发；选中态反白（拒绝类芯片例外，见 Global Constraints 赭石例外条） | B1 | Task 7 |
| 6 | `OutcomeComposer` | `--ink` / `--meta` · 正文 15px · 标签 12.5px（§1.2/§2） | 三行芯片选完即成一句规范文案；只读态能反解回已选芯片；反解失败降级为纯文本 + `重新结构化` 按钮；自由文本只允许落在 `[下一步]` | B1 | Task 9 |
| 7 | `DurationChips` | 档位 `5/10/15/25/45/60/90/120`（§7） | 选中档位写 `plan_item.est_minutes`；含 `自定义…` 入口；除自定义外不调出系统数字键盘 | B1 | Task 8 |
| 8 | `DomainChips` | 6 枚：事业/财富/家庭/学习/人际/健康（§7） | 单选写 `plan_item.domain`；未选不写（留空串） | B1 | Task 8 |
| 9 | `StartEndPicker` | 时间格 `06:00–24:00` 半小时 + `整块 1h / 2h`（§7/§5.1） | 写 `plan_item.planned_start/planned_end`；不调系统时间选择器 | B2 | Task 8（同文件扩展，接口先行） |
| 10 | `HabitCheckinStrip` | `--dock` 底 · `min-height 48px` · 芯片 26px · 跳过态赭石（§1.1/§3/§5/§1.5） | 吸底不遮挡列表（Windows 右下吸底卡）；未打卡习惯横滑全在底部不用翻页；一点即写 `habit_checkin`；再点可撤销 | B1 | Task 14 |
| 11 | `CountStepper` | 按钮高 30px · 数字等宽 tabular（§5/§2） | `type='count'` 用 `±` 步进器 + 目标值直点；不调系统数字键盘 | B2 | Task 14（同文件） |
| 12 | `AvoidToggle` | 失败态 `--accent-ink` / `--accent-wash`（§1.4/§1.5） | `type='avoid'` 两态按钮 `没破戒 ✓` / `破戒 ✗`；破戒是「警示」语义，允许赭石 | B2 | Task 14（同文件） |
| 13 | `ChecklistHabitCard` | 勾选框 22×22px · 边 `--hair-strong`（§5/§1.3） | `type='checklist'` 按 `checklist_json` 渲染勾选清单；全勾 = done | B2 | Task 14（同文件） |
| 14 | `SkipReasonChips` | 跳过态赭石 · 芯片 26px（§1.5/§5） | `skip` / `failed` 带原因芯片（出差/生病/假期/临时有事/其他） | B2 | Task 14（同文件） |
| 15 | `MoodGrid` | 标签 12.5px · 数字等宽 · `▲` 状态字符（§2/§6） | Windows 0–10 数字格；`今天没打分` 写 `mood_failed=1`，闭环环按「已处理」显示 | B3 | Task 15（同文件，接口先行） |
| 16 | `ReviewChipField` | `--hair` 分隔 · 正文 15px（§3/§2） | 六段各自可独立留白；短语用 ` | ` 连接；反解失败同 `OutcomeComposer` 降级 | B3 | Task 9（同一文案编解码复用） |
| 17 | `TodoPickerSheet` | 芯片 26px · `--ink` 反白（§5） | 三来源选入（待办池/习惯/项目）；多选后底部一条 `加入 今日 N 条` | B2 | Task 17（登记到 B2） |
| 18 | `ProjectIncrementComposer` | 正文 15px · 标签 12.5px（§2） | 三段各带短语芯片 + 文本兜底；`next_step` 预填上一笔增量 | B3 | Task 17（登记到 B3） |
| 19 | `YesterdayCarryOverCard` | `--accent-wash` 缺口底 · `--accent-ink` 警示字（§1.4/§1.5） | 次日顶部「昨日遗留 N 条」；顺延 = 新 `plan_item` 行 + 老行 `status='deferred'`，**不覆写历史** | B2 | Task 17（登记到 B2） |
| 20 | `ReminderChipPicker` | 常用时刻 `08:00/12:30/18:00/21:00`（§7） | 挂载入口只在条目/待办/习惯/项目详情；不做提醒中心页 | B3 | Task 17（登记到 B3） |
| 21 | `DatePickerSheet` | 焦点环 `--ink` · 输入框边 `--hair-strong` · 快捷芯片 26px（§5/§1.3/§8.2） | 全站唯一日期组件；快捷行 `今天/昨天/前天/明天/本周内`（`无期限` 仅 `todo.due_date`）；`Esc` 关闭、`PgUp/PgDn` 翻月、方向键 + `Enter` 可达 | B1 | Task 12 |
| 22 | `CalendarMonthView` | 日历格 `min-height 38px` · 边 `--hair-strong` · `--ink-wash` 选中底（§5/§1.3/§1.1） | 每格三层信息（完成度底色 / 打卡热力点 / 心态迷你条）+ 形状徽标 `✓ ● ○ ▸`；计划条与待办小旗**不混用同一图形** | B1 | Task 13 |
| 23 | `CalendarHeatYearView` | `--meta` 刻度字 · 弱底渐变（§1.2） | 53 周网格聚合 371 天，**禁止按格子 N+1 查询** | B3 | Task 17（登记到 B3） |
| 24 | `CalendarDayList` | `--hair` 分隔 · `--gap-card 12px`（§3） | 按月分组列出有记录的天 | B3 | Task 17（登记到 B3） |
| 25 | `DayDetailSheet` | `--card` 底 · 右侧栏宽 `--rail-w 290px`（§1.1/§4） | 点某天出该日闭环摘要（计划 x/y · 回填 m/x · 复盘 · 心态）+ `打开这一天` + `未完成 N 条` 直达 | B3 | Task 17（登记到 B3） |
| 26 | `VocabEditor` | 芯片 26px · `--hair` 分隔（§5/§7.1） | 按类别增删改短语、调整顺序；空态不允许（至少保留一条 `其他`）；存 `settings` 一个 key，**不参与同步** | B2 | Task 17（登记到 B2） |
| 27 | `AutostartToggle` | `--ink` 反白开关态 · `--accent` 仅警示（§5/§1.5） | 读写 `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`；打开状态**每次进设置页回读注册表**，`settings` 只缓存展示态 | B4 | Task 17（登记到 B4） |
| 28 | `DensitySettings` | `--fs-body/--lh/--fs-label/--fs-h2/--pad-card/--gap-sec`（§2.1） | 三档只换一组变量；存 `settings`；切档即时生效且不重排列宽/轴宽 | B4 | Task 2（`DensityProfile` 先落地，设置页在 B4） |

### 0.1 复用现状（spec §13.2）与处置

| 现状 | 处置 | 任务 |
|---|---|---|
| `SectionCard`（`apps/desktop/lib/src/widgets/section_card.dart`） | 保留外壳，但边框从 Material 默认改为 `--hair` 1px + 4px 圆角（禁大圆角卡）；内部留白改用 `--pad-card` | Task 2 / Task 15 |
| `PriorityTagChip` + `QuadrantPickerDialog` + `AbcPickerDialog` | 语义保留（点标签弹浮层、再点已选项取消、键盘可达）；仅换色到 `--ink` 反白 | Task 2 / Task 16 |
| `mood_section`（现写死 `_accent = #E07A5F`） | 改数字格 + `今天没打分`；旧色作废（不在 B 版 token 内） | Task 15（接口先行） |
| `review_section` | 改为 `ReviewChipField` 容器（复用 Task 9 的文案编解码） | Task 9 / Task 15 |
| `standup_section` | 并入晨段（`DayTimeline` 第一段），不再单独占块 | Task 15 |
| toast 基建 | 仓库内**没有应用内 toast**：`apps/desktop/lib/src/toast_probe.dart` 是**系统通知探针**，不是应用内提示。`P8 Undo` 属新建模块，**不属于 B1** | 不在 B1 |

### 0.2 需要改的既有代码点（spec §13.3）

| 文件 | 改动 | 任务 |
|---|---|---|
| `apps/desktop/lib/src/app.dart:10-26` | `seedColor = Color(0xFF2E8B57)` 旧绿 → 显式 `ColorScheme`（`primary = --ink`，`surface = --paper`，赭石只做 `error`） | Task 2 |
| `apps/desktop/lib/src/pages/today_page.dart` | 分区 `ListView` → 三段时间轴 + 吸底卡带 + 顶部闭环环；底部输入框降级为 `+ 手写一条` | Task 15 |
| `apps/desktop/lib/src/pages/today_page.dart:444-515`（`_ResultNoteDialog`） | 纯 `TextField`（minLines 2 / maxLines 5）→ `OutcomeComposer` | Task 9 |
| `apps/desktop/lib/src/providers.dart:22,26,35` | `todayProvider` 固定今天 → 引入 `selectedDateProvider` 作为唯一「当前日期」来源 | Task 6 |
| `apps/desktop/lib/src/widgets/mood_section.dart` | 0–10 数字格 + `今天没打分` | Task 15（接口先行） |

### 0.3 口径决策（本计划唯一实现处，别处不得另算）

1. **闭环环口径（spec §G-1）**：
   - 计划 `x/y`：`y = COUNT(plan_item WHERE date=sel AND status!='cancelled')`，`x = COUNT(status='done')`。
   - 回填 `m/x`：`m = COUNT(done 且 result_note 非空)` ÷ `x`；`x = 0` ⇒ 显示 `—`，**不算 100%**。
   - 复盘 ✓：`day_log.good` 或 `improve` 或 `learning` 非空。
   - 心态 ✓：`mood_1..8` 至少一个非 NULL **或** `mood_failed=1`；两者皆无 ⇒ `▲`。
2. **`result_note` 非空判定**：schema 是 `result_note TEXT NOT NULL DEFAULT ''`（`docs/schema_v1.sql`），所以「非空」= `trim() != ''`，**不是** spec §G-1 写的 `IS NOT NULL`（该写法在本 schema 下不成立，按 `!= ''` 执行）。
3. **`is_habit_ref` 行是否计入 `y`**：**计入**。`plan_item` 里习惯回填行同样是「当天的计划条目」，spec §G-1 未排除；排除会让习惯打卡完成后闭环环的 `y` 不降，体验上说不通。**此为口径缺口**，若后续要求排除，改动点只有 `dayStatsProvider` 一处（Task 6）。
4. **补录 / 预排**：选过去日期 ⇒ 界面显示 `补录模式` 徽标，`done_at` / `created_at` / `updated_at` 保持真实操作时刻；选未来日期 ⇒ 显示 `预排` 徽标，**界面不出现打卡 / 回填入口**（spec §H-1）。
5. **跨零点**：00:00–05:00 提交默认落「昨天」并提示 —— B1 只做**提示文案与可一键改为今天**，自动改期的策略留到 P8。
6. **`selectedDateProvider` 与 `todayProvider` 的关系**：`todayProvider` 保留为「真实今天」（供 `今天` 按钮、跨零点判定、测试注入），`selectedDateProvider` 初值读 `todayProvider`。这样既满足 spec §13.3「日期写入一律只读 `selectedDateProvider`」，又不破坏现有 6 个测试文件对 `todayProvider` 的 override。

---

## Task 1: B 版 token 常量与对比度工具

**Files:**
- Create: `apps/desktop/lib/src/theme/app_tokens.dart`
- Create: `apps/desktop/lib/src/theme/contrast.dart`
- Test: `apps/desktop/test/theme_tokens_test.dart`

**Interfaces:**
- Consumes: 无（首个任务）
- Produces:
  - `class AppTokens`（纯常量）：`paper/card/sunken/dock/keybg/inkWash/accentWash : Color`、`ink/ink2/meta/faint/hair/hairSoft/hairStrong/accent/accentInk : Color`、`radius = 4.0`、`gapCard = 12.0`、`gapSec = 22.0`、`tlWidth = 64.0`、`tlGap = 12.0`
  - `double relativeLuminance(Color color)`、`double contrastRatio(Color a, Color b)`（`apps/desktop/lib/src/theme/contrast.dart`）

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/theme_tokens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/theme/contrast.dart';

void main() {
  test('--hair-strong 落地值对 7 个浅底全部 >= 3:1', () {
    const backgrounds = <Color>[
      AppTokens.paper,
      AppTokens.card,
      AppTokens.sunken,
      AppTokens.dock,
      AppTokens.keybg,
      AppTokens.inkWash,
      AppTokens.accentWash,
    ];
    for (final bg in backgrounds) {
      expect(
        contrastRatio(AppTokens.hairStrong, bg),
        greaterThanOrEqualTo(3.0),
        reason: 'hairStrong 对 $bg 不达标',
      );
    }
  });

  test('文字色对 paper / card 全部 >= 4.5:1', () {
    const texts = <Color>[
      AppTokens.ink,
      AppTokens.ink2,
      AppTokens.meta,
      AppTokens.faint,
    ];
    for (final fg in texts) {
      for (final bg in const <Color>[AppTokens.paper, AppTokens.card]) {
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$fg 对 $bg 不达标',
        );
      }
    }
  });

  test('accent 与 ink 必须是两个不同的色（不得混用）', () {
    expect(AppTokens.accent, isNot(AppTokens.ink));
    expect(AppTokens.accentInk, isNot(AppTokens.ink));
    expect(AppTokens.hairStrong, isNot(AppTokens.hair));
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\theme_tokens_test.dart
```
Expected: FAIL —— `Error: Can't find a way to use "dart:ui" ...` 或 `Target of URI doesn't exist: 'package:practilog/src/theme/app_tokens.dart'`（文件不存在）。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/theme/app_tokens.dart
import 'package:flutter/material.dart';

/// B 版「墨径 · 账页流」的设计 token（浅色档）。
///
/// 唯一真源是 `design-demos/TOKENS.md`；改这里之前必须先改那份口径文件。
/// 颜色值一律从该文件抄录，不凭记忆改写。
class AppTokens {
  const AppTokens._();

  /// 页面唯一背景（米纸）。
  static const Color paper = Color(0xFFF6F4EF);

  /// 卡片底（比纸略亮，用于抬起）。
  static const Color card = Color(0xFFFBFAF6);

  /// 下沉区（hover 底、输入区底）。
  static const Color sunken = Color(0xFFF0EDE5);

  /// 吸底习惯条底。
  static const Color dock = Color(0xFFF7F5F0);

  /// 键帽底。
  static const Color keybg = Color(0xFFF1EFE8);

  /// 「当前/选中」浅洗底（墨色系）。
  static const Color inkWash = Color(0xFFE7EAEF);

  /// 「警示/缺口」浅洗底（赭石系）。
  static const Color accentWash = Color(0xFFF3E8DC);

  /// 主墨色：正文、标题、勾选框、当前页。
  static const Color ink = Color(0xFF2E4057);

  /// 强次级（备注、行动项芯片）。
  static const Color ink2 = Color(0xFF3D5170);

  /// 次级文字（徽标、优先级、时间刻度）。
  static const Color meta = Color(0xFF5F584B);

  /// 弱文字（副标、刻度数字、占位符）。
  static const Color faint = Color(0xFF6E6759);

  /// 分隔线（段头下沿、栏边）。**只允许承载纯装饰线。**
  static const Color hair = Color(0xFFDCD5C6);

  /// 卡片边（最弱）。**只允许承载纯装饰线。**
  static const Color hairSoft = Color(0xFFEAE4D9);

  /// 可交互边界（卡片 hover 边、输入框边、日历格边、复选框边）。
  ///
  /// B1 落地值 `#8A8170`；原型实测值 `#B9AE96` 仅 2.00:1，已废。
  static const Color hairStrong = Color(0xFF8A8170);

  /// 赭石，**仅**作图形填充（缺口节点、缺口比例条、警示边框）。
  static const Color accent = Color(0xFF8C5A2B);

  /// 赭石文字版（缺口状态文字、警示文案）。
  static const Color accentInk = Color(0xFF7A4E24);

  /// 圆角（卡片、按钮、输入框、面板）。禁止大圆角卡。
  static const double radius = 4;

  /// 卡片之间呼吸。
  static const double gapCard = 12;

  /// 段内元素间距（密度三档变量，舒适档值）。
  static const double gapSec = 22;

  /// 时间轴节点列宽。
  static const double tlWidth = 64;

  /// 时间轴列与正文列间距。
  static const double tlGap = 12;
}
```

```dart
// apps/desktop/lib/src/theme/contrast.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 相对亮度（WCAG 2.1）。
///
/// 公式 `L = 0.2126R + 0.7152G + 0.0722B`，分量先做 sRGB → 线性化。
double relativeLuminance(Color color) {
  double linear(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}

/// 对比度（WCAG 2.1），返回 ≥1 的比值。
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\theme_tokens_test.dart
```
Expected: PASS，3 个用例全绿。

- [x] **Step 5: 证据落盘**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: `No issues found!`。**本任务收口证据 = `apps\desktop\test\theme_tokens_test.dart` 存在 + analyze 零问题。**

---

## Task 2: 字体族与密度三档

**Files:**
- Create: `apps/desktop/lib/src/theme/app_fonts.dart`
- Create: `apps/desktop/lib/src/theme/density_profile.dart`
- Test: `apps/desktop/test/density_profile_test.dart`

**Interfaces:**
- Consumes: 无
- Produces:
  - `class AppFonts`：`display` / `body` / `mono` 三个**首选族名**常量（字符串）+ `displayFallback` / `bodyFallback` / `monoFallback` 三个**兜底族列表**常量（`List<String>`，顺序 = `TOKENS.md` §2 的 CSS 栈顺序去掉首选族）
  - `enum DensityProfile { compact, comfortable, roomy }`，字段 `bodySize / lineHeight / labelSize / h2Size / padH / padV / gapSec`（均为 `double`）

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/density_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/theme/app_fonts.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/theme/density_profile.dart';

void main() {
  test('三档字号满足硬底线：正文 >= 14、标签 >= 12', () {
    for (final d in DensityProfile.values) {
      expect(d.bodySize, greaterThanOrEqualTo(14), reason: '$d 正文过小');
      expect(d.labelSize, greaterThanOrEqualTo(12), reason: '$d 标签过小');
    }
  });

  test('三档数值抄自 TOKENS.md §2.1', () {
    expect(DensityProfile.compact.bodySize, 14);
    expect(DensityProfile.compact.lineHeight, 1.5);
    expect(DensityProfile.compact.labelSize, 12);
    expect(DensityProfile.compact.h2Size, 17);
    expect(DensityProfile.compact.padH, 11);
    expect(DensityProfile.compact.padV, 9);
    expect(DensityProfile.compact.gapSec, 16);
    expect(DensityProfile.comfortable.bodySize, 15);
    expect(DensityProfile.comfortable.lineHeight, 1.66);
    expect(DensityProfile.comfortable.labelSize, 12.5);
    expect(DensityProfile.comfortable.h2Size, 19);
    expect(DensityProfile.comfortable.padH, 14);
    expect(DensityProfile.comfortable.padV, 12);
    expect(DensityProfile.comfortable.gapSec, 22);
    expect(DensityProfile.roomy.bodySize, 16.5);
    expect(DensityProfile.roomy.lineHeight, 1.84);
    expect(DensityProfile.roomy.labelSize, 13.5);
    expect(DensityProfile.roomy.h2Size, 21);
    expect(DensityProfile.roomy.padH, 18);
    expect(DensityProfile.roomy.padV, 16);
    expect(DensityProfile.roomy.gapSec, 28);
  });

  test('comfortable 档段间距与 AppTokens.gapSec 同源', () {
    expect(DensityProfile.comfortable.gapSec, AppTokens.gapSec);
  });

  test('字体族首选 + 兜底顺序抄自 TOKENS.md §2', () {
    expect(AppFonts.display, 'Fraunces');
    expect(
      AppFonts.displayFallback,
      <String>['Noto Serif SC', 'Songti SC', 'Georgia', 'SimSun', 'serif'],
    );
    expect(AppFonts.body, 'Inter');
    expect(
      AppFonts.bodyFallback,
      <String>[
        'Noto Sans SC',
        'PingFang SC',
        'Microsoft YaHei',
        'Segoe UI',
        'system-ui',
        'sans-serif',
      ],
    );
    expect(AppFonts.mono, 'JetBrains Mono');
    expect(
      AppFonts.monoFallback,
      <String>[
        'SFMono-Regular',
        'Cascadia Mono',
        'Consolas',
        'Courier New',
        'monospace',
      ],
    );
  });

  test('兜底列表不得包含首选族本身', () {
    expect(AppFonts.displayFallback, isNot(contains(AppFonts.display)));
    expect(AppFonts.bodyFallback, isNot(contains(AppFonts.body)));
    expect(AppFonts.monoFallback, isNot(contains(AppFonts.mono)));
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\density_profile_test.dart
```
Expected: FAIL —— `Target of URI doesn't exist: 'package:practilog/src/theme/density_profile.dart'`。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/theme/app_fonts.dart
/// 字体族（TOKENS.md §2）。
///
/// 三族各给「首选族 + 兜底族列表」，顺序与 `TOKENS.md` §2 的 CSS 栈**逐字一致**：
/// - `display`：衬线（Fraunces → Noto Serif SC → 宋体），不得用 Inter/Roboto 当唯一 display 族；
/// - `body`：正文（Inter → Noto Sans SC → 微软雅黑 → Segoe UI）；
/// - `mono`：数字与键帽（JetBrains Mono → SFMono → Cascadia → Consolas → Courier New）。
///
/// Flutter 侧：`fontFamily` = 首选族，`fontFamilyFallback` = 兜底列表；
/// 首选族本机未安装时 Flutter 会自动按列表顺序回退。
/// **不得把「本机已装了哪个名字」写死进源码** —— 那是会过期的机器事实，
/// 写死会让原型首选族永远用不上（例：本机无 JetBrains Mono，写死它等于没写等宽）。
///
/// 资产打包（把三族下载进 `assets/fonts/`）是 Task 3 的可选项，
/// 缺字体不阻塞 B1 验收（系统 Noto 已能覆盖中英文）。
class AppFonts {
  const AppFonts._();

  /// 标题族首选：Fraunces（未安装时自动回退到 Noto Serif SC → 宋体）。
  static const String display = 'Fraunces';

  /// 标题族兜底顺序：Noto Serif SC → Songti SC → Georgia → SimSun → serif。
  static const List<String> displayFallback = <String>[
    'Noto Serif SC',
    'Songti SC',
    'Georgia',
    'SimSun',
    'serif',
  ];

  /// 正文字族首选：Inter（未安装时自动回退到 Noto Sans SC → 微软雅黑 → Segoe UI）。
  static const String body = 'Inter';

  /// 正文字族兜底顺序。
  static const List<String> bodyFallback = <String>[
    'Noto Sans SC',
    'PingFang SC',
    'Microsoft YaHei',
    'Segoe UI',
    'system-ui',
    'sans-serif',
  ];

  /// 数字 / 键帽族首选：JetBrains Mono。
  static const String mono = 'JetBrains Mono';

  /// 数字 / 键帽族兜底顺序。
  static const List<String> monoFallback = <String>[
    'SFMono-Regular',
    'Cascadia Mono',
    'Consolas',
    'Courier New',
    'monospace',
  ];
}
```

```dart
// apps/desktop/lib/src/theme/density_profile.dart
/// 密度三档（TOKENS.md §2.1）。
///
/// 机制：只换这一组变量，正文列宽 / 时间轴宽度 / 栏宽**不动**。
/// 禁止在 widget 里逐处写死像素 —— 一律读本枚举。
enum DensityProfile {
  /// 紧凑档。
  compact(
    bodySize: 14,
    lineHeight: 1.5,
    labelSize: 12,
    h2Size: 17,
    padH: 11,
    padV: 9,
    gapSec: 16,
  ),

  /// 舒适档（默认）。
  comfortable(
    bodySize: 15,
    lineHeight: 1.66,
    labelSize: 12.5,
    h2Size: 19,
    padH: 14,
    padV: 12,
    gapSec: 22,
  ),

  /// 宽松档。
  roomy(
    bodySize: 16.5,
    lineHeight: 1.84,
    labelSize: 13.5,
    h2Size: 21,
    padH: 18,
    padV: 16,
    gapSec: 28,
  );

  const DensityProfile({
    required this.bodySize,
    required this.lineHeight,
    required this.labelSize,
    required this.h2Size,
    required this.padH,
    required this.padV,
    required this.gapSec,
  });

  /// 正文字号。
  final double bodySize;

  /// 正文行高。
  final double lineHeight;

  /// 标签字号。
  final double labelSize;

  /// 段标题字号。
  final double h2Size;

  /// 卡片内边距横向。
  final double padH;

  /// 卡片内边距纵向。
  final double padV;

  /// 段间距。
  final double gapSec;
}
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\density_profile_test.dart
```
Expected: PASS，2 个用例全绿。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\theme\{app_fonts.dart,density_profile.dart}` + `apps\desktop\test\density_profile_test.dart` 存在且测试全绿。

---

## Task 3: B 版主题层接线（替换旧绿 seedColor）

**Files:**
- Create: `apps/desktop/lib/src/theme/app_theme.dart`
- Modify: `apps/desktop/lib/src/app.dart:10-26`
- Modify: `apps/desktop/lib/src/widgets/section_card.dart:40-46`
- Test: `apps/desktop/test/app_theme_test.dart`

**Interfaces:**
- Consumes: `AppTokens`（Task 1）、`DensityProfile` / `AppFonts`（Task 2）
- Produces: `ThemeData AppTheme.light(DensityProfile density)`；`ThemeData AppTheme.dark(DensityProfile density)`（深色档本轮只需占位：沿用同一套 token、仅声明 `Brightness.dark`，**不在本轮做深色实测**；根 `MaterialApp` 固定 `themeMode: ThemeMode.light`，故 B1 永不进入深色档）

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/theme/app_theme.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/theme/contrast.dart';
import 'package:practilog/src/theme/density_profile.dart';

void main() {
  test('primary 是 ink、surface 是 paper，accent 不得当 primary', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.primary, AppTokens.ink);
    expect(theme.colorScheme.onPrimary, AppTokens.paper);
    expect(theme.colorScheme.surface, AppTokens.paper);
    expect(theme.colorScheme.primary, isNot(AppTokens.accent));
    expect(theme.colorScheme.error, AppTokens.accentInk);
  });

  test('可交互边界用 hairStrong（>=3:1），装饰线才用 hair', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.outline, AppTokens.hairStrong);
    expect(theme.colorScheme.outlineVariant, AppTokens.hair);
    expect(
      contrastRatio(theme.colorScheme.outline, AppTokens.paper),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('字号来自密度档，且正文 >= 14', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.textTheme.bodyMedium?.fontSize, 15);
    expect(theme.textTheme.labelLarge?.fontSize, 12.5);
    expect(theme.textTheme.titleLarge?.fontSize, 19);
    final compact = AppTheme.light(DensityProfile.compact);
    expect(compact.textTheme.bodyMedium?.fontSize, 14);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\app_theme_test.dart
```
Expected: FAIL —— `Target of URI doesn't exist: 'package:practilog/src/theme/app_theme.dart'`。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/theme/app_theme.dart
import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_tokens.dart';
import 'density_profile.dart';

/// B 版主题构建。
///
/// 刻意**不**设置 `cardTheme` / `dialogTheme` / `chipTheme`：
/// 这几个类的类型在 Flutter 3.47 的小版本间摇摆（`CardTheme` / `CardThemeData`），
/// 一旦写死会在升级时炸编译。卡片 / 芯片 / 弹层的外观一律在各自 widget
/// 里显式引用 [AppTokens] —— 这样 token 口径只有一处。
class AppTheme {
  const AppTheme._();

  /// 浅色档主题。
  static ThemeData light(DensityProfile density) =>
      _build(density, Brightness.light);

  /// 深色档占位：本轮只保证不崩，深色配色待 B4 实测后补。
  static ThemeData dark(DensityProfile density) =>
      _build(density, Brightness.dark);

  static ThemeData _build(DensityProfile density, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.ink,
      brightness: brightness,
    ).copyWith(
      primary: AppTokens.ink,
      onPrimary: AppTokens.paper,
      secondary: AppTokens.ink2,
      onSecondary: AppTokens.paper,
      error: AppTokens.accentInk,
      onError: AppTokens.paper,
      surface: AppTokens.paper,
      onSurface: AppTokens.ink,
      onSurfaceVariant: AppTokens.meta,
      outline: AppTokens.hairStrong,
      outlineVariant: AppTokens.hair,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        bodyMedium: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelLarge: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.meta,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelSmall: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.faint,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        titleLarge: TextStyle(
          fontSize: density.h2Size,
          height: 1.3,
          color: AppTokens.ink,
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.displayFallback,
        ),
      ),
      dividerColor: AppTokens.hair,
      scaffoldBackgroundColor: AppTokens.paper,
    );
  }
}
```

`apps/desktop/lib/src/app.dart` 改为：

```dart
import 'package:flutter/material.dart';

import 'pages/today_page.dart';
import 'theme/app_theme.dart';
import 'theme/density_profile.dart';

/// 应用根组件。
class PractiLogApp extends StatelessWidget {
  /// 创建应用根组件。
  const PractiLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '知行日志',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(DensityProfile.comfortable),
      darkTheme: AppTheme.dark(DensityProfile.comfortable),
      themeMode: ThemeMode.light,
      home: const TodayPage(),
    );
  }
}
```

`apps/desktop/lib/src/widgets/section_card.dart` 的 `build` 换成显式 token（不再用 Material 默认卡片外观）：

```dart
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.gapCard / 2),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.hairSoft, width: 1),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.gapCard,
        AppTokens.gapCard - 2,
        AppTokens.gapCard,
        AppTokens.gapCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent ?? AppTokens.ink),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(color: AppTokens.meta),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\app_theme_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: 新测试 PASS；**全量 `flutter test` 仍全绿**（不得回归，原 47 个用例）；`analyze` 零问题。

- [x] **Step 5: 证据落盘**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' build windows --release
```
Expected: 产物落在 `apps\desktop\build\windows\x64\runner\Release\`。**本任务收口证据 = 产物目录存在 + `PractiLog.exe` 可启动。**

---

### Task 3 补丁 v2（2026-11-08 控制器裁定 · 覆盖上文 Step 1 / Step 3 的对应片段）

依据：`reports/task-3-review.md` 的 I1 / I2 / I3。三条均属**计划层缺漏**（不是实现者违约）。
修法由控制器定稿如下：`task-3-brief.md` 与本补丁冲突时**以本补丁为准**，上文 Step 1 / Step 3 里的
`textTheme` 与 `colorScheme` 片段作废；Files / Interfaces / Step 2 / Step 4 / Step 5 不变。

**口径（同步写入 `TOKENS.md` §2.3）**

- 段标题（`SectionCard` / 原型 `.sec-h h2`）用 `titleLarge`（`--fs-h2` + display 族）。`titleSmall` **不是**段标题。
- B1 只允许消费这 7 个 TextTheme role：`bodyLarge` / `bodyMedium` / `bodySmall` /
  `labelLarge` / `labelSmall` / `titleLarge` / `titleSmall`。**未接管的 role 禁止消费** —— 未接管 =
  Material 默认字族（Windows 上是 Segoe UI）+ 默认字号，绕开 token 与密度档。
- `ColorScheme.fromSeed` 派生色**不得直接上屏**：B1 实际会碰到的角色必须显式覆盖。

#### A. `app_theme.dart`：`scheme` 与 `textTheme` 两段替换为

```dart
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.ink,
      brightness: brightness,
    ).copyWith(
      primary: AppTokens.ink,
      onPrimary: AppTokens.paper,
      secondary: AppTokens.ink2,
      onSecondary: AppTokens.paper,
      secondaryContainer: AppTokens.inkWash,
      onSecondaryContainer: AppTokens.ink,
      tertiary: AppTokens.ink2,
      onTertiary: AppTokens.paper,
      error: AppTokens.accentInk,
      onError: AppTokens.paper,
      errorContainer: AppTokens.accentWash,
      onErrorContainer: AppTokens.accentInk,
      surface: AppTokens.paper,
      onSurface: AppTokens.ink,
      onSurfaceVariant: AppTokens.meta,
      surfaceBright: AppTokens.paper,
      surfaceDim: AppTokens.sunken,
      surfaceContainerLowest: AppTokens.paper,
      surfaceContainerLow: AppTokens.card,
      surfaceContainer: AppTokens.card,
      surfaceContainerHigh: AppTokens.card,
      surfaceContainerHighest: AppTokens.sunken,
      outline: AppTokens.hairStrong,
      outlineVariant: AppTokens.hair,
    );
```

`textTheme` 段（7 个 role，`fontFamily` 与 `fontFamilyFallback` 必须成对）：

```dart
      textTheme: base.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        bodyMedium: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        bodySmall: TextStyle(
          fontSize: density.bodySize,
          height: density.lineHeight,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelLarge: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.meta,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        labelSmall: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.faint,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
        titleLarge: TextStyle(
          fontSize: density.h2Size,
          height: 1.3,
          color: AppTokens.ink,
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.displayFallback,
        ),
        titleSmall: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.ink,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
      ),
```

#### B. `apps/desktop/lib/src/widgets/section_card.dart:63`

`theme.textTheme.titleSmall` → `theme.textTheme.titleLarge`（段标题口径；其余参数不动）。

#### C. `apps/desktop/test/app_theme_test.dart`：在原 3 个用例后追加 4 个

```dart
  test('bodySmall 也随密度档，且三档都 >= 14', () {
    for (final d in DensityProfile.values) {
      final t = AppTheme.light(d);
      expect(t.textTheme.bodySmall?.fontSize, d.bodySize);
      expect(t.textTheme.bodySmall?.fontSize, greaterThanOrEqualTo(14.0));
    }
  });

  test('段标题走 titleLarge（display 族 + h2 号），titleSmall 落 label 号', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.textTheme.titleLarge?.fontSize, 19);
    expect(theme.textTheme.titleLarge?.fontFamily, AppFonts.display);
    expect(theme.textTheme.titleLarge?.fontFamilyFallback, AppFonts.displayFallback);
    expect(theme.textTheme.titleSmall?.fontSize, 12.5);
    expect(theme.textTheme.titleSmall?.fontFamily, AppFonts.body);
  });

  test('弹层与徽标底色在 token 口径内，不走 seed 派生', () {
    final theme = AppTheme.light(DensityProfile.comfortable);
    expect(theme.colorScheme.surfaceContainerHigh, AppTokens.card);
    expect(theme.colorScheme.surfaceContainerHighest, AppTokens.sunken);
    expect(theme.colorScheme.surfaceDim, AppTokens.sunken);
    expect(theme.colorScheme.tertiary, AppTokens.ink2);
    expect(theme.colorScheme.secondaryContainer, AppTokens.inkWash);
    expect(theme.colorScheme.errorContainer, AppTokens.accentWash);
  });

  testWidgets('SectionCard 标题真的吃到 titleLarge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: const Scaffold(
          body: SectionCard(
            icon: Icons.circle,
            title: '段标题',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('段标题'));
    expect(text.style?.fontSize, 19);
    expect(text.style?.fontFamily, AppFonts.display);
  });
```

需要的 import（原文件已删 `material.dart`，因本补丁新增 `Icons` / `MaterialApp` / `Scaffold` / `Text` / `testWidgets` 而**必须加回**）：

```dart
import 'package:flutter/material.dart';
import 'package:practilog/src/theme/app_fonts.dart';
import 'package:practilog/src/widgets/section_card.dart';
```

#### D. Step 4 期望用例数

Task 3 收口全量应为 `+62`（58 + 4）。**以实测为准**，数字不符不判失败，但要查是不是漏了用例。

---

### Task 3 补丁 v3（2026-11-08 控制器裁定 · 覆盖补丁 v2 之上）

依据：`reports/task-3-review2.md` 的 Important I-1 —— `lib/` 内存在 `textTheme.labelMedium` 的消费
（`today_page.dart:37`、`standup_section.dart:95`），而该 role 不在 `TOKENS.md` §2.3 白名单内。
Material 默认 `labelMedium` 在 Windows 上落到 Segoe UI + 固定字号，绕开 token 与密度档。

**修法**：主题层接管 `labelMedium`（`density.labelSize` + body 族），白名单由 7 个 role 扩为 **8 个**。
**不改任何消费点**（消费点不在 Task 3 的 Files 内，且接管后它们自动合规）。

#### A. `app_theme.dart`：`textTheme` 段在 `labelLarge` 之后追加

```dart
        labelMedium: TextStyle(
          fontSize: density.labelSize,
          height: 1.3,
          color: AppTokens.meta,
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.bodyFallback,
        ),
```

#### B. `app_theme_test.dart`：在现有 7 个用例后追加 1 个

```dart
  test('labelMedium 也被接管（白名单 8 个 role），三档都 >= 12', () {
    for (final d in DensityProfile.values) {
      final t = AppTheme.light(d);
      expect(t.textTheme.labelMedium?.fontSize, d.labelSize);
      expect(t.textTheme.labelMedium?.fontSize, greaterThanOrEqualTo(12.0));
      expect(t.textTheme.labelMedium?.fontFamily, AppFonts.body);
      expect(t.textTheme.labelMedium?.fontFamilyFallback, AppFonts.bodyFallback);
    }
  });
```

#### C. 收口期望用例数

全量应为 `+63`（62 + 1）。**以实测为准**，数字不符不判失败，但要说明差异原因。

---

## Task 4: `core_domain` —— 回填文案规范编解码（spec §6.1）

**Files:**
- Create: `packages/core_domain/lib/src/result_note.dart`
- Modify: `packages/core_domain/lib/core_domain.dart`（加 `export 'src/result_note.dart';`）
- Test: `packages/core_domain/test/result_note_test.dart`

**Interfaces:**
- Consumes: 无
- Produces:
  - `enum ResultNoteLabel { outcome, reason, nextStep }`，字段 `label`（`结论` / `原因` / `下一步`）
  - `final class ResultNote`：
    - `const ResultNote({String outcome = '', String reason = '', String nextStep = ''})`
    - `factory ResultNote.parse(String raw)`
    - `String get encoded`、`bool get parsed`、`bool get isEmpty`、`bool get wellFormed`
    - 字段 `outcome` / `reason` / `nextStep` / `rawText`
    - 静态成员：`static const int maxTextLength = 40`、`static const List<String> forbiddenTextChars = ['|', '[', ']']`、`static bool isValidText(String text)`

- [x] **Step 1: 写失败测试**

```dart
// packages/core_domain/test/result_note_test.dart
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  test('规范文案能反解回三段', () {
    final note = ResultNote.parse('[结论]按时完成 | [原因]预估不足 | [下一步]周四上午做完');
    expect(note.parsed, isTrue);
    expect(note.outcome, '按时完成');
    expect(note.reason, '预估不足');
    expect(note.nextStep, '周四上午做完');
  });

  test('编码顺序固定：结论 → 原因 → 下一步', () {
    const note = ResultNote(
      outcome: '按时完成',
      reason: '预估不足',
      nextStep: '周四上午做完',
    );
    expect(note.encoded, '[结论]按时完成 | [原因]预估不足 | [下一步]周四上午做完');
  });

  test('缺段省略、顺序不变', () {
    const note = ResultNote(outcome: '按时完成', nextStep: '继续');
    expect(note.encoded, '[结论]按时完成 | [下一步]继续');
  });

  test('自由文本解析失败时降级为只读纯文本，原文不丢', () {
    final note = ResultNote.parse('随手写的一段话');
    expect(note.parsed, isFalse);
    expect(note.rawText, '随手写的一段话');
    expect(note.encoded, '随手写的一段话');
    final padded = ResultNote.parse('   随手写的一段话   ');
    expect(padded.rawText, '随手写的一段话');
    expect(padded.encoded, '随手写的一段话');
  });

  test('顺序错乱 / 重复标签 / 超长文本都算解析失败', () {
    expect(ResultNote.parse('[下一步]甲 | [结论]乙').parsed, isFalse);
    expect(ResultNote.parse('[结论]甲 | [结论]乙').parsed, isFalse);
    expect(ResultNote.parse('[结论]${'x' * 41}').parsed, isFalse);
  });

  test('空串是空文案', () {
    expect(ResultNote.parse('   ').isEmpty, isTrue);
  });

  test('缺段也能反解回结构（encode → parse 往返一致）', () {
    const cases = <ResultNote>[
      ResultNote(outcome: '按时完成'),
      ResultNote(outcome: '按时完成', nextStep: '继续'),
      ResultNote(reason: '预估不足'),
      ResultNote(reason: '预估不足', nextStep: '继续'),
      ResultNote(nextStep: '继续'),
    ];
    for (final note in cases) {
      final parsed = ResultNote.parse(note.encoded);
      expect(parsed.parsed, isTrue, reason: note.encoded);
      expect(parsed.encoded, note.encoded, reason: note.encoded);
    }
  });

  test('文本含竖线或方括号判为解析失败', () {
    expect(ResultNote.parse('[结论]甲|乙').parsed, isFalse);
    expect(ResultNote.parse('[结论]甲[乙]').parsed, isFalse);
    expect(ResultNote.parse('[结论]甲 | 乙').parsed, isFalse);
  });

  test('text 长度上界：恰好 40 字符通过、41 字符失败', () {
    expect(ResultNote.parse('[结论]${'x' * 40}').parsed, isTrue);
    expect(ResultNote.parse('[结论]${'x' * 41}').parsed, isFalse);
  });

  test('长度按字符计：40 个 emoji 通过（不是 40 个 UTF-16 码元）', () {
    expect(ResultNote.parse('[下一步]${'😀' * 40}').parsed, isTrue);
    expect(ResultNote.parse('[下一步]${'😀' * 41}').parsed, isFalse);
  });

  test('text 含换行仍可反解（spec 只禁竖线与方括号）', () {
    final note = ResultNote.parse('[结论]甲\n乙');
    expect(note.parsed, isTrue);
    expect(note.outcome, '甲\n乙');
  });

  test('中间缺「结论」的两段（原因 + 下一步）也算合法子序列', () {
    const note = ResultNote(reason: '预估不足', nextStep: '继续');
    expect(note.encoded, '[原因]预估不足 | [下一步]继续');
    final parsed = ResultNote.parse(note.encoded);
    expect(parsed.parsed, isTrue);
    expect(parsed.reason, '预估不足');
    expect(parsed.nextStep, '继续');
  });

  test('空文案：编码为空串、isEmpty 为真、wellFormed 为真', () {
    const note = ResultNote();
    expect(note.encoded, '');
    expect(note.isEmpty, isTrue);
    expect(note.wellFormed, isTrue);
    expect(const ResultNote(outcome: '   ').encoded, '');
    expect(const ResultNote(outcome: ' a ').encoded, '[结论]a');
  });

  test('解析失败但有原文时不算空文案', () {
    final note = ResultNote.parse('随手写的一段话');
    expect(note.parsed, isFalse);
    expect(note.isEmpty, isFalse);
  });

  test('非法文本构造出来的文案不 wellFormed（落库前须拦截）', () {
    expect(const ResultNote(outcome: '按时完成').wellFormed, isTrue);
    expect(const ResultNote(outcome: 'a|b').wellFormed, isFalse);
    expect(ResultNote(outcome: 'x' * 41).wellFormed, isFalse);
    expect(ResultNote.parse('[结论]甲|乙').parsed, isFalse);
    expect(ResultNote.parse(const ResultNote(outcome: 'a|b').encoded).parsed, isFalse);
    expect(ResultNote.parse(ResultNote(outcome: 'x' * 41).encoded).parsed, isFalse);
    expect(ResultNote.parse(const ResultNote(outcome: 'a|b').encoded).rawText, '[结论]a|b');
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_domain
& 'F:\soft\flutter\flutter\bin\dart.bat' test test\result_note_test.dart
```
Expected: FAIL —— `Error: 'result_note.dart' isn't a valid ...` / `Undefined name 'ResultNote'`。

- [x] **Step 3: 写实现**

```dart
// packages/core_domain/lib/src/result_note.dart
/// 回填文案的三种标签。
///
/// 顺序固定为「结论 → 原因 → 下一步」，缺段省略、顺序不变（spec §6.1）。
enum ResultNoteLabel {
  /// 结论。
  outcome('结论'),

  /// 原因。
  reason('原因'),

  /// 下一步。
  nextStep('下一步');

  /// 创建标签枚举值。
  const ResultNoteLabel(this.label);

  /// 写库时使用的标签文本。
  ///
  /// 仅作编码前缀（如 `[结论]`），**不可**当作统计维度使用 ——
  /// spec §6.1 的「结论分布」统计的是段内文本，不是段名。
  final String label;
}

/// 规范回填文案（spec §6.1）。
///
/// 文法：`result_note := segment (" | " segment)*`，`segment := "[" label "]" text`，
/// `text` 长度 1..40（按 Unicode 码点计）且禁止包含 `|` `[` `]`。
///
/// 解析失败（自由文本 / 顺序错乱 / 标签重复 / 超长 / 非法字符）时**整体降级**为
/// [rawText]：调用方据此渲染只读纯文本 + 「重新结构化」按钮，
/// 绝不丢数据、绝不猜。
///
/// **本类不校验构造入参**：构造器接受任意字符串；若段内文本违反上述文法
/// （超过 [maxTextLength] 或含禁止字符），[encoded] 产出的串将**无法**被
/// [ResultNote.parse] 还原成结构化文案 —— 落库前调用方必须自行校验 [wellFormed]。
final class ResultNote {
  /// 构造一段规范文案。
  const ResultNote({
    this.outcome = '',
    this.reason = '',
    this.nextStep = '',
  }) : rawText = '',
       parsed = true;

  const ResultNote._raw(this.rawText)
    : outcome = '',
      reason = '',
      nextStep = '',
      parsed = false;

  /// 单段文本的最大字符数（spec §6.1：text 长度 1..40）。
  static const int maxTextLength = 40;

  /// 单段文本禁止包含的字符（spec §6.1）。
  static const List<String> forbiddenTextChars = <String>['|', '[', ']'];

  static final RegExp _segment = RegExp(
    r'^\[(结论|原因|下一步)\](.+)$',
    dotAll: true,
  );

  /// 判断单段文本是否满足 spec §6.1 的 text 约束。
  ///
  /// 规则：去掉首尾空白后非空、长度不超过 [maxTextLength]（按 Unicode 码点计）、
  /// 不含 [forbiddenTextChars] 中的任何字符。
  static bool isValidText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.runes.length > maxTextLength) {
      return false;
    }
    for (final char in forbiddenTextChars) {
      if (trimmed.contains(char)) {
        return false;
      }
    }
    return true;
  }

  /// 结论段文本。
  final String outcome;

  /// 原因段文本。
  final String reason;

  /// 下一步段文本。
  final String nextStep;

  /// 解析失败时的原始文本（已去掉首尾空白）；解析成功时为空串。
  final String rawText;

  /// 是否解析成规范结构。
  final bool parsed;

  /// 三段文本是否都满足 spec §6.1 的 text 约束。
  ///
  /// 为 `false` 时 [encoded] 产出的串**不能**被 [ResultNote.parse] 还原，
  /// 落库会导致下次打开时降级为自由文本（芯片态不可恢复）。
  /// 缺省的段（文本为空）不算违规。
  ///
  /// 解析失败（[parsed] 为 `false`）时三段文本为空、本值恒为 `true`；
  /// 此时 [encoded] 原样返回 [rawText]，其本身不可被还原为结构 —— 这是
  /// spec §6.1「反解失败 ⇒ 纯文本只读」的预期形态，不是校验通过信号。
  bool get wellFormed =>
      (outcome.trim().isEmpty || isValidText(outcome)) &&
      (reason.trim().isEmpty || isValidText(reason)) &&
      (nextStep.trim().isEmpty || isValidText(nextStep));

  /// 解析一段原文。
  factory ResultNote.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const ResultNote();
    }

    final segments = <ResultNoteLabel, String>{};

    for (final part in trimmed.split(' | ')) {
      final match = _segment.firstMatch(part);
      if (match == null) {
        return ResultNote._raw(trimmed);
      }
      final label = switch (match.group(1)) {
        '结论' => ResultNoteLabel.outcome,
        '原因' => ResultNoteLabel.reason,
        '下一步' => ResultNoteLabel.nextStep,
        _ => null,
      };
      if (label == null) {
        return ResultNote._raw(trimmed);
      }
      final text = match.group(2)!.trim();
      if (!isValidText(text)) {
        return ResultNote._raw(trimmed);
      }
      if (segments.containsKey(label)) {
        return ResultNote._raw(trimmed);
      }
      segments[label] = text;
    }

    // 顺序必须是「结论 → 原因 → 下一步」的子序列：缺段可省，但相对顺序不得错乱。
    const expected = ResultNoteLabel.values;
    var lastIndex = -1;
    for (final label in segments.keys) {
      final index = expected.indexOf(label);
      if (index <= lastIndex) {
        return ResultNote._raw(trimmed);
      }
      lastIndex = index;
    }

    return ResultNote(
      outcome: segments[ResultNoteLabel.outcome] ?? '',
      reason: segments[ResultNoteLabel.reason] ?? '',
      nextStep: segments[ResultNoteLabel.nextStep] ?? '',
    );
  }

  /// 编码成写库文本。
  ///
  /// 解析失败时原样返回 [rawText]（去掉首尾空白后的原文，不丢内容、不擅自改写）。
  ///
  /// 解析成功时按「结论 → 原因 → 下一步」拼装、缺段省略（纯空白段按缺段处理）。
  /// 若 [wellFormed] 为 `false`，产出的串无法被 [ResultNote.parse] 还原 ——
  /// 调用方落库前必须自行校验。
  String get encoded {
    if (!parsed) {
      return rawText;
    }
    final parts = <String>[];
    if (outcome.trim().isNotEmpty) {
      parts.add('[${ResultNoteLabel.outcome.label}]${outcome.trim()}');
    }
    if (reason.trim().isNotEmpty) {
      parts.add('[${ResultNoteLabel.reason.label}]${reason.trim()}');
    }
    if (nextStep.trim().isNotEmpty) {
      parts.add('[${ResultNoteLabel.nextStep.label}]${nextStep.trim()}');
    }
    return parts.join(' | ');
  }

  /// 是否为空文案。
  bool get isEmpty =>
      parsed
          ? outcome.trim().isEmpty &&
                reason.trim().isEmpty &&
                nextStep.trim().isEmpty
          : rawText.trim().isEmpty;
}
```

在 `packages/core_domain/lib/core_domain.dart` 末尾追加：

```dart
export 'src/result_note.dart';
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_domain
& 'F:\soft\flutter\flutter\bin\dart.bat' test
& F:\soft\00selfmade\practilog\tools\gates\g2_unittest.ps1
```
Expected: 新用例 PASS；core_domain 全量 PASS；G2 门禁绿。

- [x] **Step 5: 证据落盘**

`packages\core_domain\lib\src\result_note.dart` + `packages\core_domain\test\result_note_test.dart` 存在，测试全绿。

---

## Task 5: `core_data` —— 日历纯工具

**Files:**
- Create: `packages/core_data/lib/src/calendar.dart`
- Modify: `packages/core_data/lib/core_data.dart`（加 `export 'src/calendar.dart';`）
- Test: `packages/core_data/test/calendar_test.dart`

**Interfaces:**
- Consumes: `core_data` 现有 `parseIsoDate` / `isoDate`（`src/support.dart`）
- Produces:
  - `final class CalendarCell { String date; bool inMonth; bool isWeekend; bool isToday; }`
  - `List<CalendarCell> buildMonthGrid(String yearMonth, {required String today, int weekStart = 1})`
  - `String weekdayLabel(String date)`（周一…周日）
  - `String dateTitle(String date)`（`2026-11-07 周六`）
  - `String relativeDayLabel(String date, {required String today})`（今天/昨天/前天/明天/周X）

- [x] **Step 1: 写失败测试**

```dart
import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  test('buildMonthGrid returns whole weeks', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07');
    expect(grid.length % 7, 0);
    expect(weekdayLabel(grid.first.date), '周一');
    expect(grid.first.date.compareTo('2026-11-01') <= 0, true);
    expect(grid.where((c) => c.inMonth).length, 30);
    expect(grid.firstWhere((c) => c.date == '2026-11-01').inMonth, true);
    expect(grid[grid.length - 1].date, '2026-12-06');
  });

  test('weekend flags follow Saturday/Sunday', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07');
    expect(grid.firstWhere((c) => c.date == '2026-11-07').isWeekend, true);
    expect(grid.firstWhere((c) => c.date == '2026-11-01').isWeekend, true);
    expect(grid.firstWhere((c) => c.date == '2026-11-05').isWeekend, false);
  });

  test('relative labels match today', () {
    expect(relativeDayLabel('2026-11-07', today: '2026-11-07'), '今天');
    expect(relativeDayLabel('2026-11-06', today: '2026-11-07'), '昨天');
    expect(relativeDayLabel(shiftIsoDate('2026-11-07', 1), today: '2026-11-07'), '明天');
  });

  test('malformed month inputs degrade to an empty grid', () {
    expect(buildMonthGrid('garbage', today: '2026-11-07'), isEmpty);
    expect(buildMonthGrid('2026-13', today: '2026-11-07'), isEmpty);
    expect(buildMonthGrid('2026-11-07', today: '2026-11-07'), isEmpty);
  });

  test('weekStart shifts the window and the whole-week rule still holds', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07', weekStart: 2);
    expect(grid.first.date, '2026-10-27');
    expect(weekdayLabel(grid.first.date), '周二');
    expect(grid.length % 7, 0);
    expect(grid.where((c) => c.inMonth).length, 30);
  });

  test('Friday is a weekday and isToday marks exactly one cell', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07');
    expect(grid.firstWhere((c) => c.date == '2026-11-06').isWeekend, false);
    expect(grid.firstWhere((c) => c.date == '2026-11-06').isToday, false);
    expect(grid.where((c) => c.isToday).length, 1);
  });

  test('relativeDayLabel covers day-before-yesterday and weekday fallback', () {
    expect(relativeDayLabel('2026-11-05', today: '2026-11-07'), '前天');
    expect(relativeDayLabel('2026-11-20', today: '2026-11-07'), '周五');
  });

  test('invalid inputs degrade instead of throwing', () {
    expect(weekdayLabel('garbage'), '');
    expect(dateTitle('garbage'), 'garbage');
    expect(relativeDayLabel('garbage', today: '2026-11-07'), '');
  });

  test('leap February keeps whole weeks and 29 in-month cells', () {
    final grid = buildMonthGrid('2028-02', today: '2026-11-07');
    expect(grid.length % 7, 0);
    expect(grid.where((c) => c.inMonth).length, 29);
  });

  test('December grid crosses into January 2027 correctly', () {
    final grid = buildMonthGrid('2026-12', today: '2026-11-07');
    expect(grid.length % 7, 0);
    expect(grid.where((c) => c.inMonth).length, 31);
    expect(grid.first.date, '2026-11-30');
    expect(grid.last.date, '2027-01-10');
    expect(grid.last.inMonth, false);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_data
dart test test\calendar_test.dart
```
Expected: FAIL —— `Undefined name 'buildMonthGrid'`。

- [x] **Step 3: 写实现**

```dart
// packages/core_data/lib/src/calendar.dart
import 'support.dart';

/// 月历网格的一格。
final class CalendarCell {
  /// 创建一个格子。
  const CalendarCell({
    required this.date,
    required this.inMonth,
    required this.isWeekend,
    required this.isToday,
  });

  /// 该格的日历日 `yyyy-MM-dd`。
  final String date;

  /// 是否属于当前显示的月份。
  final bool inMonth;

  /// 是否周六或周日。
  final bool isWeekend;

  /// 是否今天。
  final bool isToday;
}

const List<String> _weekdayNames = <String>[
  '周一',
  '周二',
  '周三',
  '周四',
  '周五',
  '周六',
  '周日',
];

/// 生成 [yearMonth]（`YYYY-MM`）的 6×7 月历网格。
///
/// [weekStart] 为每周首日的 `DateTime.weekday`：1 = 周一，7 = 周日。
List<CalendarCell> buildMonthGrid(
  String yearMonth, {
  required String today,
  int weekStart = 1,
}) {
  final parts = yearMonth.split('-');
  if (parts.length != 2) {
    return const <CalendarCell>[];
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return const <CalendarCell>[];
  }
  final first = DateTime(year, month, 1);
  final offset = (first.weekday - weekStart + 7) % 7;
  final start = DateTime(year, month, 1 - offset);

  return List<CalendarCell>.generate(42, (index) {
    final day = DateTime(start.year, start.month, start.day + index);
    final date = isoDate(day);
    return CalendarCell(
      date: date,
      inMonth: day.month == month && day.year == year,
      isWeekend: day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday,
      isToday: date == today,
    );
  });
}

/// 星期中文名（周一…周日）。
///
/// 非法日期返回空串 —— 解析层不抛异常，与 `parseIsoDate` 的约定一致。
String weekdayLabel(String date) {
  final parsed = parseIsoDate(date);
  if (parsed == null) {
    return '';
  }
  return _weekdayNames[parsed.weekday - 1];
}

/// 标题文案（`2026-11-07 周六`）。
String dateTitle(String date) {
  final label = weekdayLabel(date);
  if (label.isEmpty) {
    return date;
  }
  return '$date $label';
}

/// 相对日期标签（今天 / 昨天 / 前天 / 明天 / 周X）。
String relativeDayLabel(String date, {required String today}) {
  if (date == today) {
    return '今天';
  }
  if (date == shiftIsoDate(today, -1)) {
    return '昨天';
  }
  if (date == shiftIsoDate(today, -2)) {
    return '前天';
  }
  if (date == shiftIsoDate(today, 1)) {
    return '明天';
  }
  return weekdayLabel(date);
}
```

在 `packages/core_data/lib/core_data.dart` 末尾追加：

```dart
export 'src/calendar.dart';
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_data
dart test
& F:\soft\00selfmade\practilog\tools\gates\g2_unittest.ps1
```
Expected: 新用例 PASS；core_data 全量 PASS；G2 门禁绿。

- [x] **Step 5: 证据落盘**

`packages\core_data\lib\src\calendar.dart` + `packages\core_data\test\calendar_test.dart` 存在，测试全绿。

---

## Task 6: `selectedDateProvider` 迁移 + `dayStatsProvider`（闭环环唯一口径）

**Files:**
- Create: `packages/core_data/lib/src/day_stats.dart`
- Modify: `packages/core_data/lib/core_data.dart`（加 `export 'src/day_stats.dart';`）
- Modify: `apps/desktop/lib/src/providers.dart`（**保留第 19–22 行 `todayProvider` 不动**；在其后插入 `selectedDateProvider`；`dayLogProvider` / `planItemsProvider` 内 `ref.watch(todayProvider)` 改为 `ref.watch(selectedDateProvider)`；末尾追加 `dayStatsProvider`）
- Test: `packages/core_data/test/day_stats_test.dart`、`apps/desktop/test/selected_date_test.dart`

**Interfaces:**
- Consumes: `core_data` 现有 `PlanItemRepository`（Task 5 之后已有 `calendar.dart`）
- Produces:
  - `final class PlanItemStat { const PlanItemStat({required this.status, required this.hasResultNote}); String status; bool hasResultNote; }`
  - `final class DayStats { const DayStats({required this.planTotal, required this.planDone, required this.backfilled, required this.reviewDone, required this.moodDone}); int planTotal; int planDone; int backfilled; bool reviewDone; bool moodDone; int get planPending; double? get backfillRate; }`
  - `DayStats computeDayStats({required Iterable<PlanItemStat> items, required bool hasReview, required bool hasMood})`
  - `apps/desktop`：`StateProvider<String> selectedDateProvider`、`Provider<DayStats> dayStatsProvider`

- [x] **Step 1: 写失败测试**

```dart
// packages/core_data/test/day_stats_test.dart
import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  test('cancelled 不计入分母，deferred 计入', () {
    final stats = computeDayStats(
      items: const <PlanItemStat>[
        PlanItemStat(status: 'done', hasResultNote: true),
        PlanItemStat(status: 'done', hasResultNote: false),
        PlanItemStat(status: 'pending', hasResultNote: false),
        PlanItemStat(status: 'cancelled', hasResultNote: false),
      ],
      hasReview: false,
      hasMood: false,
    );
    expect(stats.planTotal, 3);
    expect(stats.planDone, 2);
    expect(stats.backfilled, 1);
    expect(stats.planPending, 1);
  });

  test('x=0 时回填率为 null（显示 —，不算 100%）', () {
    final stats = computeDayStats(
      items: const <PlanItemStat>[],
      hasReview: false,
      hasMood: false,
    );
    expect(stats.backfillRate, isNull);
  });

  test('回填率 = backfilled / planDone', () {
    final stats = computeDayStats(
      items: const <PlanItemStat>[
        PlanItemStat(status: 'done', hasResultNote: true),
        PlanItemStat(status: 'done', hasResultNote: true),
        PlanItemStat(status: 'done', hasResultNote: false),
        PlanItemStat(status: 'done', hasResultNote: false),
      ],
      hasReview: true,
      hasMood: true,
    );
    expect(stats.backfillRate, 0.5);
    expect(stats.reviewDone, isTrue);
    expect(stats.moodDone, isTrue);
  });
}
```

```dart
// apps/desktop/test/selected_date_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/providers.dart';

void main() {
  test('selectedDateProvider 初值跟随 todayProvider（测试可 override）', () {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue('2026-11-07')],
    );
    expect(container.read(selectedDateProvider), '2026-11-07');
    container.dispose();
  });

  test('selectedDateProvider 可被改写（切日 / 回今天）', () {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue('2026-11-07')],
    );
    container.read(selectedDateProvider.notifier).state = '2026-11-03';
    expect(container.read(selectedDateProvider), '2026-11-03');
    container.dispose();
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_data
dart test test\day_stats_test.dart
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\selected_date_test.dart
```
Expected: 两处都 FAIL（`Undefined name 'computeDayStats'` / `Undefined name 'selectedDateProvider'`）。

- [x] **Step 3: 写实现**

```dart
// packages/core_data/lib/src/day_stats.dart
/// 参与闭环统计的一条计划条目（只看状态与是否回填）。
final class PlanItemStat {
  /// 创建一条统计输入。
  const PlanItemStat({required this.status, required this.hasResultNote});

  /// 计划状态（`pending` / `done` / `deferred` / `cancelled`）。
  final String status;

  /// 是否已回填（`result_note` 去空白后非空）。
  final bool hasResultNote;
}

/// 一天的闭环统计（spec §G-1 的**唯一口径实现处**）。
///
/// 口径：
/// - 计划 `x/y`：`y` = 状态非 `cancelled` 的条目数；`x` = `done` 数；
/// - 回填 `m/x`：`m` = `done` 且已回填的条目数；
/// - 复盘 ✓ / 心态 ✓ 由调用方按 `day_log` 字段传入。
final class DayStats {
  /// 创建统计结果。
  const DayStats({
    required this.planTotal,
    required this.planDone,
    required this.backfilled,
    required this.reviewDone,
    required this.moodDone,
  });

  /// 计划分母（不含 cancelled）。
  final int planTotal;

  /// 计划分子（done）。
  final int planDone;

  /// 已回填数。
  final int backfilled;

  /// 复盘是否已处理。
  final bool reviewDone;

  /// 心态是否已处理。
  final bool moodDone;

  /// 未完成数。
  int get planPending => planTotal - planDone;

  /// 回填率；分母为 0 时返回 null（显示 `—`，**不算 100%**）。
  double? get backfillRate {
    if (planDone == 0) {
      return null;
    }
    return backfilled / planDone;
  }
}

/// 计算一天的闭环统计（纯函数，便于单测）。
DayStats computeDayStats({
  required Iterable<PlanItemStat> items,
  required bool hasReview,
  required bool hasMood,
}) {
  var total = 0;
  var done = 0;
  var backfilled = 0;
  for (final item in items) {
    if (item.status == 'cancelled') {
      continue;
    }
    total++;
    if (item.status == 'done') {
      done++;
      if (item.hasResultNote) {
        backfilled++;
      }
    }
  }
  return DayStats(
    planTotal: total,
    planDone: done,
    backfilled: backfilled,
    reviewDone: hasReview,
    moodDone: hasMood,
  );
}
```

`apps/desktop/lib/src/providers.dart` 改动（**保留第 19–22 行的 `todayProvider` 定义，不要整段替换掉**）：

- **必须补一行 import**：在文件顶部加 `import 'package:flutter_riverpod/legacy.dart';`。Riverpod 3.5.0 把 `StateProvider` 移到了 **legacy 导出面**，`package:flutter_riverpod/flutter_riverpod.dart` 主导出面**不再导出**它，不加这行会 `Undefined name 'StateProvider'` 编译失败；`Provider` / `StreamProvider` / `ProviderContainer` 仍从主导出面取，**两个 import 可共存**（已实测）。
- **无需补 import**：`package:core_data/core_data.dart` 已在该文件里，`DayStats` / `PlanItemStat` / `computeDayStats` 随 barrel 的 `export 'src/day_stats.dart';` 一起可见。
- **测试文件**：`apps/desktop/test/selected_date_test.dart` 只用 `ProviderContainer` / `overrideWithValue`（主导出面）与 `selectedDateProvider`（来自 `providers.dart`），**不要** import legacy（否则 `unused_import` 警告）。
- 在 `todayProvider` 之后插入 `selectedDateProvider`；
- 把 `dayLogProvider` / `planItemsProvider` 内的 `ref.watch(todayProvider)` 改为 `ref.watch(selectedDateProvider)`（其余行不动）；
- 在 `planItemsProvider` 之后追加 `dayStatsProvider`；
- **口径裁定（控制器，Task 6 收口时补记）**：本 Task 的 Files 段写「末尾追加 `dayStatsProvider`」，Step 3 代码块却把它紧排在 `planItemsProvider` 之后，两处措辞互相矛盾；交付实现取**文件末尾**（`priorityDisplayModeProvider` 之后）—— 相对次序不变、功能等价、无行为差异，记为 **Minor（deferred，不进修复环）**；后续 Task 勿照抄该歧义写法。

```dart
/// 选中日期（本地时区的日历日，`yyyy-MM-dd`）。
///
/// 初值读 [todayProvider]，因此测试里 override `todayProvider` 依然生效；
/// 界面上的任何日期写入都只读这一个 provider（spec §13.3）。
final selectedDateProvider = StateProvider<String>(
  (ref) => ref.watch(todayProvider),
);

/// 当日日志；读取前先 `ensureByDate` 补建（幂等，不写库也不写 oplog）。
final dayLogProvider = StreamProvider<DayLogData?>((ref) async* {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(repositoriesProvider).dayLog;
  await repo.ensureByDate(date);
  yield* repo.watchByDate(date);
});

/// 当日计划条目（含习惯回填行），已按「收口沉底 + 优先级权重 + 创建时间」排好序。
final planItemsProvider = StreamProvider<List<PlanItemData>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).planItem.watchByDate(date);
});

/// 当日闭环统计（闭环环口径唯一实现处）。
final dayStatsProvider = Provider<DayStats>((ref) {
  final items =
      ref.watch(planItemsProvider).whenOrNull(data: (rows) => rows) ??
      const <PlanItemData>[];
  final log = ref.watch(dayLogProvider).whenOrNull(data: (row) => row);

  final hasReview =
      log != null &&
      (log.good.trim().isNotEmpty ||
          log.improve.trim().isNotEmpty ||
          log.learning.trim().isNotEmpty);
  final hasMood =
      log != null &&
      (log.moodFailed == 1 ||
          log.mood1 != null ||
          log.mood2 != null ||
          log.mood3 != null ||
          log.mood4 != null ||
          log.mood5 != null ||
          log.mood6 != null ||
          log.mood7 != null ||
          log.mood8 != null);

  return computeDayStats(
    items: items.map(
      (item) => PlanItemStat(
        status: item.status,
        hasResultNote: item.resultNote.trim().isNotEmpty,
      ),
    ),
    hasReview: hasReview,
    hasMood: hasMood,
  );
});
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_data
dart test
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: 新用例 PASS；**desktop 全量测试仍全绿**（原有 6 个测试文件对 `todayProvider` 的 override 依然有效 —— 这是本任务不破坏回归的关键判据）。

- [x] **Step 5: 证据落盘**

`packages\core_data\lib\src\day_stats.dart` + 两个测试文件存在；`flutter analyze` 零问题。

---

## Task 7: `ChipRow` 与 `SectionHeader`（B1 的两个基础件）

**Files:**
- Create: `apps/desktop/lib/src/widgets/chip_row.dart`
- Create: `apps/desktop/lib/src/widgets/section_header.dart`
- Modify: `apps/desktop/lib/src/widgets/priority_chips.dart`（四象限 / ABC / 优先级标签换色：不再用 `colorFromHex(colorHex)` 的旧绿上屏，常态边走 `--hair-strong`、选中态走 `--ink` 反白）
- Test: `apps/desktop/test/chip_row_test.dart`（4 例：单选 / 多选增删 / 键盘精确命中 / 换色逐枚绑定）
- Test: `apps/desktop/test/priority_chips_test.dart`（2 例：四象限逐格绑定底色·描边·圆角·选中语义 / 优先级标签逐枚绑定底色·描边·圆角·文字色）
- Test: `apps/desktop/test/section_header_test.dart`（3 例：常态无描边 / 缺项 2px 赭石描边 + 提示色 / 有缺项无提示文案）

**Interfaces:**
- Consumes: `AppTokens`（Task 1）、`DensityProfile`（Task 2）
- Produces:
  - `final class ChipOption { const ChipOption({required this.key, required this.label, this.deny = false}); String key; String label; bool deny; }`
  - `class ChipRow extends StatelessWidget { const ChipRow({super.key, required this.options, this.selected = const <String>{}, this.multi = false, this.onChanged}); List<ChipOption> options; Set<String> selected; bool multi; void Function(Set<String> next)? onChanged; }`
  - `class SectionHeader extends StatelessWidget { const SectionHeader({super.key, required this.title, this.done, this.total, this.hasGap = false, this.gapHint, this.trailing}); String title; int? done; int? total; bool hasGap; String? gapHint; Widget? trailing; }`

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/chip_row_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/widgets/chip_row.dart';

void main() {
  const options = <ChipOption>[
    ChipOption(key: 'a', label: '按时完成'),
    ChipOption(key: 'b', label: '延后完成'),
    ChipOption(key: 'c', label: '取消', deny: true),
  ];

  /// 取某枚芯片**自身**的 Material 底色（最近祖先 = 芯片自己的 Material）。
  Color chipFill(WidgetTester tester, String label) {
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );
    return material.color!;
  }

  /// 取某枚芯片**自身**的描边（最近祖先 Container 的 BoxDecoration.border）。
  Border chipBorder(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.border! as Border;
  }

  /// 取某枚芯片**自身**的圆角半径。
  double chipRadius(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  /// 取某枚芯片**自身**的文字色。
  Color chipTextColor(WidgetTester tester, String label) {
    final text = tester.widget<Text>(find.text(label));
    return text.style!.color!;
  }

  testWidgets('单选：点一枚芯片即回调该 key', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    await tester.tap(find.text('延后完成'));
    expect(captured, <String>{'b'});
  });

  testWidgets('多选：点未选项即新增，再点已选项即取消（可为空）', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            multi: true,
            selected: const <String>{'a'},
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );

    // 新增分支：点未选中的「延后完成」⇒ 已选集合并入 b。
    await tester.tap(find.text('延后完成'));
    expect(captured, <String>{'a', 'b'});

    // 取消分支：再点已选中的「按时完成」⇒ 取消它，剩 b。
    await tester.tap(find.text('按时完成'));
    expect(captured, isEmpty);
  });

  testWidgets('芯片可聚焦且 Space 能触发（精确命中首枚芯片）', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(captured, <String>{'a'});
  });

  testWidgets('换色逐枚绑定：常态 card 底 / hair-strong 边，选中 ink 反白，拒绝类选中走赭石洗底', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            selected: const <String>{'b', 'c'},
            onChanged: (next) {},
          ),
        ),
      ),
    );

    // 常态芯片「按时完成」：card 底 + hair-strong 边 + meta 字。
    expect(chipFill(tester, '按时完成'), AppTokens.card);
    expect(chipBorder(tester, '按时完成').top.color, AppTokens.hairStrong);
    expect(chipTextColor(tester, '按时完成'), AppTokens.meta);

    // 选中态普通芯片「延后完成」：ink 底 + ink 边 + paper 字（反白）。
    expect(chipFill(tester, '延后完成'), AppTokens.ink);
    expect(chipBorder(tester, '延后完成').top.color, AppTokens.ink);
    expect(chipTextColor(tester, '延后完成'), AppTokens.paper);

    // 拒绝类芯片「取消」选中：accentWash 底 + accentInk 边 + accentInk 字。
    expect(chipFill(tester, '取消'), AppTokens.accentWash);
    expect(chipBorder(tester, '取消').top.color, AppTokens.accentInk);
    expect(chipTextColor(tester, '取消'), AppTokens.accentInk);

    // 圆角一律 4px（禁止大圆角）。
    expect(chipRadius(tester, '按时完成'), AppTokens.radius);
    expect(chipRadius(tester, '延后完成'), AppTokens.radius);
    expect(chipRadius(tester, '取消'), AppTokens.radius);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\chip_row_test.dart
```
Expected: FAIL —— `Target of URI doesn't exist: 'package:practilog/src/widgets/chip_row.dart'`。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/chip_row.dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 一枚芯片的选项定义。
final class ChipOption {
  /// 创建一个选项。
  const ChipOption({required this.key, required this.label, this.deny = false});

  /// 稳定标识（写库用）。
  final String key;

  /// 显示文案。
  final String label;

  /// 是否为「拒绝类」语义。
  ///
  /// 拒绝类芯片选中时用赭石描边 + 赭石洗底（B 版允许的 5 处赭石位置之一），
  /// 其余选中态一律 `--ink` 反白。
  final bool deny;
}

/// 通用芯片条（单选 / 多选）。
///
/// 视觉口径：芯片高 26px、圆角 4px、间距 6px 且**强制换行**；
/// 边框用 `--hair-strong`（可交互边界 ≥3:1），**不得**用 `--hair`。
class ChipRow extends StatelessWidget {
  /// 创建芯片条。
  const ChipRow({
    super.key,
    required this.options,
    this.selected = const <String>{},
    this.multi = false,
    this.onChanged,
  });

  /// 可选项。
  final List<ChipOption> options;

  /// 当前已选项（key 集合）。
  final Set<String> selected;

  /// 是否允许多选。
  final bool multi;

  /// 选中变化回调；传 null 表示只读展示。
  final void Function(Set<String> next)? onChanged;

  void _toggle(ChipOption option) {
    final handler = onChanged;
    if (handler == null) {
      return;
    }
    final next = Set<String>.of(selected);
    if (multi) {
      if (!next.remove(option.key)) {
        next.add(option.key);
      }
    } else {
      next
        ..clear()
        ..add(option.key);
    }
    handler(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final option in options)
          _ChipButton(
            option: option,
            checked: selected.contains(option.key),
            onPressed: onChanged == null ? null : () => _toggle(option),
          ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.option,
    required this.checked,
    required this.onPressed,
  });

  final ChipOption option;
  final bool checked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelSize = theme.textTheme.labelLarge?.fontSize ?? 12.5;

    final Color background;
    final Color foreground;
    final Color border;
    if (checked && option.deny) {
      background = AppTokens.accentWash;
      foreground = AppTokens.accentInk;
      border = AppTokens.accentInk;
    } else if (checked) {
      background = AppTokens.ink;
      foreground = AppTokens.paper;
      border = AppTokens.ink;
    } else {
      background = AppTokens.card;
      foreground = AppTokens.meta;
      border = AppTokens.hairStrong;
    }

    return Semantics(
      selected: checked,
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 26),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              option.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: labelSize,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// apps/desktop/lib/src/widgets/section_header.dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 段头（标题 + 完成徽章 + 缺项高亮）。
///
/// 缺项时整行加 2px 赭石描边（`--accent`）并给出提示 —— 这是 B 版允许的
/// 赭石位置之一（缺口语义）。
class SectionHeader extends StatelessWidget {
  /// 创建段头。
  const SectionHeader({
    super.key,
    required this.title,
    this.done,
    this.total,
    this.hasGap = false,
    this.gapHint,
    this.trailing,
  });

  /// 段标题。
  final String title;

  /// 已完成数（为空则不显示徽章）。
  final int? done;

  /// 总数。
  final int? total;

  /// 是否存在缺项。
  final bool hasGap;

  /// 缺项提示文案。
  final String? gapHint;

  /// 标题行右侧动作。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadge = done != null && total != null;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: AppTokens.ink),
        ),
        if (hasBadge) ...[
          const SizedBox(width: 8),
          Text(
            '$done/$total',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTokens.meta,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
        if (hasGap && gapHint != null) ...[
          const SizedBox(width: 8),
          Text(
            gapHint!,
            style: theme.textTheme.labelLarge?.copyWith(color: AppTokens.accentInk),
          ),
        ],
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );

    if (!hasGap) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: AppTokens.accent, width: 2),
        ),
        child: content,
      ),
    );
  }
}
```

- [x] **Step 4: 换色 `priority_chips.dart`（落地 Task 3 评审 I-4）**

**口径裁定（控制器）**：I-4 要求「常态边 `--hair-strong`、选中态 `--ink` 反白、象限色仅作图形填充」，同时要求把 `packages\core_data` 的 `#2E8B57` 换成「B 版象限色」—— 但 `design-demos\TOKENS.md` **没有**定义任何象限色板，且 `--accent` 赭石**只许**用于「缺口/警示」，故 Task 7 范围内**不存在**合规可用的象限色。

⇒ 裁定：Task 7 **彻底移除象限色**（本文件不再调用 `colorFromHex`）；四象限的身份改由已有的**象限码文字**（`style.quadrant.code`）+ 短标签承载（文字双通道，无障碍合规）。所有颜色改走 `AppTokens`：

- 常态：底 `--card`、边 `--hair-strong`（1px，交互边界 ≥3:1）、主文字 `--ink`、次文字 `--meta`
- 选中：**底 `--ink`、边 `--ink`、文字 `--paper`（反白）**
- `colorFromHex` 函数**本体保留不删**（`standup_section.dart:150` 从本文件 import 并调用它，删掉会打断 Task 15 范围的文件），只是本文件不再调用。
- `packages\core_data\lib\src\priority.dart:56` 的 `#2E8B57` 属数据层、超出 Task 7 Files ⇒ **本任务不动**，记入遗留台账。

**改动一**：`apps/desktop/lib/src/widgets/priority_chips.dart` 顶部补 import：

```dart
import '../theme/app_tokens.dart';
```

**改动二**：把 `_QuadrantCell.build` 整体替换为：

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? AppTokens.paper : AppTokens.ink;
    final secondary = selected ? AppTokens.paper : AppTokens.meta;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppTokens.ink : AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: selected ? AppTokens.ink : AppTokens.hairStrong,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: selected ? AppTokens.paper : AppTokens.faint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      style.shortLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      style.quadrant.code,
                      style: theme.textTheme.labelSmall?.copyWith(color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  style.label,
                  style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                ),
                const SizedBox(height: 2),
                Text(
                  style.advice,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

**改动三**：把 `PriorityTagChip.build` 整体替换为：

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = PriorityDisplay.labelFor(
      mode,
      quadrant: quadrant,
      priorityAbc: priorityAbc,
    );

    return Material(
      color: AppTokens.card,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: AppTokens.hairStrong, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_outlined, size: 12, color: AppTokens.meta),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTokens.meta,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

**改动四（R1 · 控制器裁定 · 2026-11-08 · 吸收 verifier I-1 / I-4）**：

- **圆角一律 `AppTokens.radius`（4px）**：`_QuadrantCell` 的 3 处 `BorderRadius.circular(12)` 与 `PriorityTagChip` 的 3 处 `BorderRadius.circular(10)` 全部改为 `BorderRadius.circular(AppTokens.radius)`（Global Constraints「圆角 4px，禁止大圆角卡」）。
- **选中态进无障碍语义**：`_QuadrantCell` 的 `Material` 外包一层 `Semantics(selected: selected, button: true, ...)`（形状 + 文字双通道：选中态除反白外还必须能被读屏识别）。
- 本轮**不改** `chip_row.dart` / `section_header.dart`（首轮实现已是 `AppTokens.radius` 圆角，且 `chip_row.dart` 已带 `Semantics(selected: checked, button: true)`）。

- [x] **Step 5: 写换色回归测试**

```dart
// apps/desktop/test/priority_chips_test.dart
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/widgets/priority_chips.dart';

/// 旧绿：Task 3 换掉主题层后仍残留在象限色板里，本任务要求它不再上屏。
const Color kOldGreen = Color(0xFF2E8B57);

void main() {
  /// 取某个象限格**自身**的 Material 底色（最近祖先 = 该格自己的 Material）。
  Color cellFill(WidgetTester tester, String shortLabel) {
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text(shortLabel), matching: find.byType(Material))
          .first,
    );
    return material.color!;
  }

  /// 取某个象限格**自身**的描边（最近祖先 Container 的 BoxDecoration.border）。
  Border cellBorder(WidgetTester tester, String shortLabel) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(shortLabel), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.border! as Border;
  }

  /// 取某个象限格**自身**的圆角半径。
  double cellRadius(WidgetTester tester, String shortLabel) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(shortLabel), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  /// 取某个象限格**自身**的短标签文字色。
  Color cellTitleColor(WidgetTester tester, String shortLabel) {
    final text = tester.widget<Text>(find.text(shortLabel));
    return text.style!.color!;
  }

  /// 取某个象限格**自身**的 Semantics 选中标记（`selected` 非 null 的那一个）。
  Semantics cellSemantics(WidgetTester tester, String shortLabel) {
    final list = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text(shortLabel),
            matching: find.byType(Semantics),
          ),
        )
        .where((s) => s.properties.selected != null)
        .toList();
    expect(list.length, 1);
    return list.single;
  }

  testWidgets('四象限：逐格绑定常态/选中态的底色、描边、圆角与选中语义', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final styles = QuadrantStyle.all.values.toList();
    expect(styles.length, 4);

    final pending = QuadrantPickerDialog.show(
      ctx,
      selected: styles.first.quadrant,
      mode: PriorityDisplayMode.quadrant,
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < styles.length; i++) {
      final style = styles[i];
      final isSelected = i == 0;

      // 每格的短标签必须唯一可定位（否则绑定断言会张冠李戴）。
      expect(find.text(style.shortLabel), findsOneWidget);

      expect(
        cellFill(tester, style.shortLabel),
        isSelected ? AppTokens.ink : AppTokens.card,
      );
      expect(
        cellBorder(tester, style.shortLabel).top.color,
        isSelected ? AppTokens.ink : AppTokens.hairStrong,
      );
      expect(
        cellTitleColor(tester, style.shortLabel),
        isSelected ? AppTokens.paper : AppTokens.ink,
      );
      // 圆角一律 4px（禁止大圆角）。
      expect(cellRadius(tester, style.shortLabel), AppTokens.radius);
      // 形状 + 文字双通道：选中态必须进 Semantics。
      final semantics = cellSemantics(tester, style.shortLabel);
      expect(semantics.properties.selected, isSelected);
      expect(semantics.properties.button, isTrue);
    }

    // 全局兜底：旧绿不得上屏。
    final borders = <Color>[];
    final fills = <Color>[];
    for (final c in tester.widgetList<Container>(find.byType(Container))) {
      final d = c.decoration;
      if (d is BoxDecoration) {
        final b = d.border;
        if (b is Border) {
          borders.add(b.top.color);
        }
      }
    }
    for (final m in tester.widgetList<Material>(find.byType(Material))) {
      final col = m.color;
      if (col != null) {
        fills.add(col);
      }
    }
    expect(borders, isNot(contains(kOldGreen)));
    expect(fills, isNot(contains(kOldGreen)));

    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();
    await pending;
  });

  testWidgets('优先级标签：逐枚绑定 card 底 / hair-strong 边 / 4px 圆角 / meta 文字与图标', (tester) async {
    final quadrant = QuadrantStyle.all.values.first.quadrant;
    final label = PriorityDisplay.labelFor(
      PriorityDisplayMode.quadrant,
      quadrant: quadrant,
      priorityAbc: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriorityTagChip(
            mode: PriorityDisplayMode.quadrant,
            quadrant: quadrant,
            priorityAbc: null,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text(label), findsOneWidget);

    final material = tester.widget<Material>(
      find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
    );
    expect(material.color, AppTokens.card);
    expect(material.borderRadius, BorderRadius.circular(AppTokens.radius));

    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect((decoration.borderRadius! as BorderRadius).topLeft.x, AppTokens.radius);
    expect((decoration.border! as Border).top.color, AppTokens.hairStrong);

    final text = tester.widget<Text>(find.text(label));
    expect(text.style!.color, AppTokens.meta);

    final iconColors =
        tester.widgetList<Icon>(find.byType(Icon)).map((i) => i.color).toList();
    expect(iconColors, contains(AppTokens.meta));
    expect(iconColors, isNot(contains(kOldGreen)));
  });
}
```

```dart
// apps/desktop/test/section_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/widgets/section_header.dart';

void main() {
  /// 找出带 `--accent` 2px 描边的容器（缺项高亮）。
  List<Container> gapContainers(WidgetTester tester) {
    return tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final decoration = c.decoration;
          if (decoration is! BoxDecoration) {
            return false;
          }
          final border = decoration.border;
          if (border is! Border) {
            return false;
          }
          return border.top.color == AppTokens.accent && border.top.width == 2;
        })
        .toList();
  }

  testWidgets('无缺项：标题 + 完成徽章上屏，不渲染赭石描边', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(title: '今日待办', done: 3, total: 5),
        ),
      ),
    );

    expect(find.text('今日待办'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(gapContainers(tester), isEmpty);
  });

  testWidgets('有缺项：整行 2px 赭石描边 + 提示文案走 accent-ink', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: '今日待办',
            done: 3,
            total: 5,
            hasGap: true,
            gapHint: '还差 2 项',
          ),
        ),
      ),
    );

    expect(find.text('还差 2 项'), findsOneWidget);
    final hint = tester.widget<Text>(find.text('还差 2 项'));
    expect(hint.style!.color, AppTokens.accentInk);

    final gaps = gapContainers(tester);
    expect(gaps.length, 1);
    final decoration = gaps.single.decoration! as BoxDecoration;
    expect((decoration.borderRadius! as BorderRadius).topLeft.x, AppTokens.radius);

    // 徽章仍在上屏。
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('有缺项但无提示文案：不渲染 accent-ink 提示文本，描边仍在', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(title: '今日待办', hasGap: true),
        ),
      ),
    );

    expect(gapContainers(tester).length, 1);

    final accentTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.color == AppTokens.accentInk)
        .toList();
    expect(accentTexts, isEmpty);
  });
}
```

- [x] **Step 6: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\chip_row_test.dart test\priority_chips_test.dart test\section_header_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```

Expected: 新测试 PASS；analyze 零问题；**desktop 全量 `flutter test` 仍全绿**（基线 65 例 + 本任务 9 例 = 74 例）。

> 注意：`chip_row_test.dart` 用到 `LogicalKeyboardKey`，需要 `import 'package:flutter/services.dart';`（已补进 Step 1 围栏）。

- [x] **Step 7: 证据落盘**

`apps\desktop\lib\src\widgets\{chip_row.dart,section_header.dart}` + `apps\desktop\test\{chip_row_test.dart,priority_chips_test.dart,section_header_test.dart}` 存在且全绿（全量 **74 例**）；`priority_chips.dart` 内 `colorFromHex` 只剩函数定义、**无调用点**；全文件圆角一律 `AppTokens.radius`（4px）。

> **口径裁定汇总（控制器 · 2026-11-08）**
>
> 1. **`labelBuilder` 移除**：Interfaces 行原写有 `this.labelBuilder`，但 Step 3 的实现代码块没有该构造参数，且 Task 8/9/12 的 `ChipRow` 调用点均未使用 ⇒ 取代码块为准，移除该参数，避免「契约有、实现无」。
> 2. **测试围栏补 `import 'package:flutter/services.dart';`**：`LogicalKeyboardKey` **不在** `material.dart` / `flutter_test.dart` 的导出面上（原围栏缺这一行 ⇒ 编译不过）；仓库先例见 `apps/desktop/test/p1_widgets_test.dart:4`。
> 3. **芯片焦点环不在 Task 7 契约内**：handoff §9 的「M-1 焦点环 `InputManager` 接线」改判归 **Task 16** —— 计划 Task 16 的 Files 段明列 `Modify: apps/desktop/lib/src/widgets/chip_row.dart（芯片焦点环）`，且全仓不存在 `InputManager` 类型。Task 7 只交付「芯片可聚焦 + Space 可激活」（Step 1 用例 3 已覆盖），**不实现 2px `--ink` 焦点环**。
> 4. **旧绿 `#2E8B57` 的数据层根因不在 Task 7**：`packages/core_data/lib/src/priority.dart:56` 属 Task 7 Files 之外 ⇒ 不动；`apps/desktop/lib/src/widgets/standup_section.dart:150` 仍在调 `colorFromHex`（属 Task 15 范围）⇒ 同样留待后续 Task。
> 5. **R1 修复轮（2026-11-08 · 吸收 verifier I-1/I-2/I-3/I-4/I-5）**：① `priority_chips.dart` 圆角 12/10 → `AppTokens.radius`（4px，禁止大圆角）；② `_QuadrantCell` 外包 `Semantics(selected: selected, button: true, ...)`（形状 + 文字双通道）；③ `chip_row_test.dart` 增第 4 例「换色逐枚绑定」、多选补「新增」分支、键盘用例由 `isNotNull` 收紧为精确集合 `{'a'}`；④ `priority_chips_test.dart` 改逐格绑定断言（底色 / 描边 / 圆角 / 选中语义）+ 芯片文字色断言；⑤ 新增 `section_header_test.dart` 3 例。判绿口径 70 → **74**（65 基线 + chip_row 4 + priority_chips 2 + section_header 3）。

---

## Task 8: `DurationChips` 与 `DomainChips`

**Files:**
- Create: `apps/desktop/lib/src/widgets/duration_chips.dart`
- Create: `apps/desktop/lib/src/widgets/domain_chips.dart`
- Test: `apps/desktop/test/duration_domain_chips_test.dart`

**Interfaces:**
- Consumes: `ChipRow` / `ChipOption`（Task 7）
- Produces:
  - `class DurationChips extends StatelessWidget { const DurationChips({super.key, required this.selectedMinutes, this.onChanged}); int? selectedMinutes; void Function(int? minutes)? onChanged; }`（`DurationChips.presets = <int>[5,10,15,25,45,60,90,120]`）
  - `class DomainChips extends StatelessWidget { const DomainChips({super.key, required this.selectedDomain, this.onChanged}); String selectedDomain; void Function(String domain)? onChanged; }`（`DomainChips.domains = <String>['事业','财富','家庭','学习','人际','健康']`）

> **契约修订 R1（控制器，2026-11-08）—— 芯片显示文案口径**
> 出处：spec §7「档位类」`估时 5/10/15/25/45/60/90/120 分钟`（`docs/superpowers/specs/2026-11-07-双端交互体验设计.md:266`）
> 与原型 `design-demos/v1-bigtype.html:405`（`EST = ["5 分钟", … "120 分钟"]`）。
> 裁定：**文案带单位，数字与「分钟」之间留一个空格**。`find.text` 是全等匹配 ⇒ Step 1 的查找必须写全串
> （`'45 分钟'`，不能写 `'45'`），否则必红。**Step 3 实现的 `'$minutes 分钟'` 已符合口径，不改。**
> 另：档位出处是 **spec §7**，不是 TOKENS §7（TOKENS §7 = 图标与母题，无时长档位）。

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/duration_domain_chips_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/widgets/duration_chips.dart';
import 'package:practilog/src/widgets/domain_chips.dart';

void main() {
  testWidgets('时长档位来自 spec §7 的 8 档', (tester) async {
    expect(DurationChips.presets, <int>[5, 10, 15, 25, 45, 60, 90, 120]);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DurationChips(selectedMinutes: 25))),
    );
    expect(find.text('25 分钟'), findsOneWidget);
    expect(find.text('120 分钟'), findsOneWidget);
  });

  testWidgets('点档位回调分钟数', (tester) async {
    int? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DurationChips(
            selectedMinutes: null,
            onChanged: (value) => captured = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('45 分钟'));
    expect(captured, 45);
  });

  testWidgets('领域 6 枚且可单选', (tester) async {
    expect(DomainChips.domains.length, 6);
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DomainChips(
            selectedDomain: '',
            onChanged: (value) => captured = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('健康'));
    expect(captured, '健康');
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\duration_domain_chips_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/duration_chips.dart
import 'package:flutter/material.dart';

import 'chip_row.dart';

/// 预估时长档位芯片。
///
/// 档位抄自 spec §7：`5/10/15/25/45/60/90/120` 分钟。
/// 「自定义…」是唯一的打字兜底入口。
class DurationChips extends StatelessWidget {
  /// 创建时长芯片条。
  const DurationChips({
    super.key,
    required this.selectedMinutes,
    this.onChanged,
  });

  /// 档位列表。
  static const List<int> presets = <int>[5, 10, 15, 25, 45, 60, 90, 120];

  /// 当前选中的分钟数（null = 未选）。
  final int? selectedMinutes;

  /// 选择变化回调；null 表示只读。
  final void Function(int? minutes)? onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMinutes == null
        ? const <String>{}
        : <String>{'$selectedMinutes'};
    return ChipRow(
      options: <ChipOption>[
        for (final minutes in presets)
          ChipOption(key: '$minutes', label: '$minutes 分钟'),
        const ChipOption(key: 'custom', label: '自定义…'),
      ],
      selected: selected,
      onChanged: onChanged == null
          ? null
          : (next) {
              if (next.isEmpty) {
                onChanged!(null);
                return;
              }
              final key = next.first;
              if (key == 'custom') {
                // 自定义入口：本轮只提示需要打字，不弹系统数字键盘。
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('自定义时长：点「+ 手写」里输入分钟数')),
                );
                return;
              }
              onChanged!(int.parse(key));
            },
    );
  }
}
```

```dart
// apps/desktop/lib/src/widgets/domain_chips.dart
import 'package:flutter/material.dart';

import 'chip_row.dart';

/// 领域芯片（6 枚，单选）。
class DomainChips extends StatelessWidget {
  /// 创建领域芯片条。
  const DomainChips({
    super.key,
    required this.selectedDomain,
    this.onChanged,
  });

  /// 领域清单（抄自 spec §5.1）。
  static const List<String> domains = <String>[
    '事业',
    '财富',
    '家庭',
    '学习',
    '人际',
    '健康',
  ];

  /// 当前选中的领域（空串 = 未选）。
  final String selectedDomain;

  /// 选择变化回调；null 表示只读。
  final void Function(String domain)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ChipRow(
      options: <ChipOption>[
        for (final domain in domains) ChipOption(key: domain, label: domain),
      ],
      selected: selectedDomain.isEmpty
          ? const <String>{}
          : <String>{selectedDomain},
      onChanged: onChanged == null
          ? null
          : (next) => onChanged!(next.isEmpty ? '' : next.first),
    );
  }
}
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\duration_domain_chips_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: PASS + analyze 零问题。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\{duration_chips.dart,domain_chips.dart}` + 测试文件存在且全绿。

---

## Task 9: `OutcomeComposer` —— 替换 `_ResultNoteDialog` 的纯打字

**Files:**
- Create: `apps/desktop/lib/src/widgets/outcome_composer.dart`
- Modify: `apps/desktop/lib/src/pages/today_page.dart`（`_ResultNoteDialog`（444-515 行）删除；`_editResult`（366-382 行）改为宿主 `AlertDialog` + `OutcomeComposer`；`_ResultEdit`（436-441 行）**保留**，继续作为弹窗回传载荷）
- Test: `apps/desktop/test/outcome_composer_test.dart`
- Test（控制器授权 · 限 P1-6 那个用例）: `apps/desktop/test/p1_e2e_test.dart:225-255`

**Interfaces:**
- Consumes: `ResultNote` / `ResultNoteLabel`（Task 4）、`ChipRow`（Task 7）
- Produces:
  - `class OutcomeComposer extends StatefulWidget { const OutcomeComposer({super.key, required this.initial, this.onSubmit}); String initial; void Function(String encoded, {required bool markDone})? onSubmit; }`
    - `onSubmit` 传**规范文案 + 是否标记完成的意图**；合成器**自己不 `Navigator.pop`**，由宿主在回调里 `Navigator.of(context).pop(...)` 回传弹窗结果。
    - 合成器自带底部按钮：`取消`（丢弃，不写库）/ `只存进展`（`markDone: false`）/ `完成`（`markDone: true`）；`只存进展` 与 `完成` 在 `_note.wellFormed == false` 时禁用（`onPressed: null`）。
  - 词库常量：`OutcomeComposer.outcomeLabels`（7）、`OutcomeComposer.reasonLabels`（8）、`OutcomeComposer.nextStepLabels`（6）

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/outcome_composer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/widgets/outcome_composer.dart';

void main() {
  testWidgets('三段芯片选完即成一句规范文案', (tester) async {
    String? captured;
    bool? markedDone;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutcomeComposer(
            initial: '',
            onSubmit: (String encoded, {required bool markDone}) {
              captured = encoded;
              markedDone = markDone;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('按时完成'));
    await tester.pump();
    await tester.tap(find.text('预估不足'));
    await tester.pump();
    await tester.tap(find.text('只存进展'));
    await tester.pump();
    expect(captured, '[结论]按时完成 | [原因]预估不足');
    expect(markedDone, isFalse);
  });

  testWidgets('点完成要带 done 意图', (tester) async {
    String? captured;
    bool? markedDone;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutcomeComposer(
            initial: '',
            onSubmit: (String encoded, {required bool markDone}) {
              captured = encoded;
              markedDone = markDone;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('按时完成'));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pump();
    expect(captured, '[结论]按时完成');
    expect(markedDone, isTrue);
  });

  testWidgets('反解失败降级为只读纯文本并给出重新结构化入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OutcomeComposer(initial: '随手写的一段话')),
      ),
    );
    expect(find.text('随手写的一段话'), findsOneWidget);
    expect(find.text('重新结构化'), findsOneWidget);
    expect(find.text('按时完成'), findsNothing);
  });

  testWidgets('规范文案能反解回已选芯片', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OutcomeComposer(initial: '[结论]按时完成')),
      ),
    );
    expect(find.text('按时完成'), findsOneWidget);
  });

  testWidgets('初始下一步自由文本要回填进输入框', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OutcomeComposer(initial: '[结论]按时完成 | [下一步]周四上午做完'),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '周四上午做完');
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\outcome_composer_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/outcome_composer.dart
import 'package:flutter/material.dart';

import 'package:core_domain/core_domain.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import 'chip_row.dart';

/// 三段合成器（结论 → 原因 → 下一步）。
///
/// 写库只写一句规范文案（spec §6.1）；自由文本只允许落在 `[下一步]`。
class OutcomeComposer extends StatefulWidget {
  /// 创建合成器。
  const OutcomeComposer({super.key, required this.initial, this.onSubmit});

  /// 初始 `result_note` 原文。
  final String initial;

  /// 提交回调；传编码后的规范文案与「是否标记完成」的意图。
  ///
  /// 合成器**不自己**弹窗：宿主在回调里 `Navigator.of(context).pop(...)` 回传结果。
  final void Function(String encoded, {required bool markDone})? onSubmit;

  /// 结论短语（spec §7）。
  static const List<String> outcomeLabels = <String>[
    '按时完成',
    '延后完成',
    '提前完成',
    '部分完成',
    '受阻',
    '顺延到明天',
    '取消',
  ];

  /// 原因短语（spec §7）。
  static const List<String> reasonLabels = <String>[
    '预估不足',
    '被打断',
    '依赖外部',
    '优先级变了',
    '状态不好',
    '时间不够',
    '信息不清',
    '其他',
  ];

  /// 下一步短语（spec §7）。
  static const List<String> nextStepLabels = <String>[
    '明天继续',
    '转成待办',
    '交出去',
    '缩小范围',
    '定日复盘',
    '就此停止',
  ];

  @override
  State<OutcomeComposer> createState() => _OutcomeComposerState();
}

class _OutcomeComposerState extends State<OutcomeComposer> {
  late ResultNote _note = ResultNote.parse(widget.initial);
  bool _restructured = false;

  /// `[下一步]` 自由文本输入框；初值 = 初始文案里的 `[下一步]` 段。
  late final TextEditingController _nextStepController = TextEditingController(
    text: _note.nextStep,
  );

  @override
  void didUpdateWidget(covariant OutcomeComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial == oldWidget.initial) {
      return;
    }
    _note = ResultNote.parse(widget.initial);
    _restructured = false;
    _nextStepController.text = _note.nextStep;
  }

  @override
  void dispose() {
    _nextStepController.dispose();
    super.dispose();
  }

  void _setSegment(ResultNoteLabel label, String text) {
    setState(() {
      _note = switch (label) {
        ResultNoteLabel.outcome => ResultNote(
          outcome: text,
          reason: _note.reason,
          nextStep: _note.nextStep,
        ),
        ResultNoteLabel.reason => ResultNote(
          outcome: _note.outcome,
          reason: text,
          nextStep: _note.nextStep,
        ),
        ResultNoteLabel.nextStep => ResultNote(
          outcome: _note.outcome,
          reason: _note.reason,
          nextStep: text,
        ),
      };
    });
  }

  /// 选中「下一步」芯片：芯片短语独占 `[下一步]` 槽位，自由文本必须让位。
  void _pickNextStepChip(String label) {
    _nextStepController.clear();
    _setSegment(ResultNoteLabel.nextStep, label);
  }

  /// 自由文本落在 `[下一步]` 槽位；此时芯片短语让位（芯片选中态由文本内容反推）。
  void _typeNextStep(String text) {
    _setSegment(ResultNoteLabel.nextStep, text.trim());
  }

  /// 规范文案是否可落库（spec §6.1 文法）。
  bool get _canSubmit => _note.wellFormed;

  void _submit(bool markDone) {
    final handler = widget.onSubmit;
    if (handler == null || !_canSubmit) {
      return;
    }
    handler(_note.encoded, markDone: markDone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_note.parsed && !_restructured) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _note.rawText,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTokens.ink),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _restructured = true;
                  _note = const ResultNote();
                }),
                child: const Text('重新结构化'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('结论', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ChipRow(
          options: <ChipOption>[
            for (final label in OutcomeComposer.outcomeLabels)
              ChipOption(key: label, label: label),
          ],
          selected: _note.outcome.isEmpty ? const <String>{} : <String>{_note.outcome},
          onChanged: (next) =>
              _setSegment(ResultNoteLabel.outcome, next.isEmpty ? '' : next.first),
        ),
        const SizedBox(height: 10),
        Text('原因', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ChipRow(
          options: <ChipOption>[
            for (final label in OutcomeComposer.reasonLabels)
              ChipOption(key: label, label: label),
          ],
          selected: _note.reason.isEmpty ? const <String>{} : <String>{_note.reason},
          onChanged: (next) =>
              _setSegment(ResultNoteLabel.reason, next.isEmpty ? '' : next.first),
        ),
        const SizedBox(height: 10),
        Text('下一步', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ChipRow(
          options: <ChipOption>[
            for (final label in OutcomeComposer.nextStepLabels)
              ChipOption(key: label, label: label),
          ],
          selected: OutcomeComposer.nextStepLabels.contains(_note.nextStep)
              ? <String>{_note.nextStep}
              : const <String>{},
          onChanged: (next) => next.isEmpty
              ? _typeNextStep('')
              : _pickNextStepChip(next.first),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nextStepController,
          maxLength: ResultNote.maxTextLength,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.deny(RegExp(r'[\[\]|]')),
          ],
          decoration: const InputDecoration(
            labelText: '下一步（自由文本，仅此处可打字）',
            isDense: true,
          ),
          onChanged: _typeNextStep,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _canSubmit ? () => _submit(false) : null,
              child: const Text('只存进展'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSubmit ? () => _submit(true) : null,
              child: const Text('完成'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**输入约束（控制器补 · 来自 Task 4 评审 I1）**：自由文本框必须加 `maxLength: ResultNote.maxTextLength`
并用 `FilteringTextInputFormatter.deny(RegExp(r'[\[\]|]'))` 禁掉 `|` `[` `]`；
「提交」按钮在 `_note.wellFormed == false` 时必须禁用（`onPressed: null`）。
否则会落库违反 spec §6.1 文法的文案，下次打开无法反解回芯片态。
需要 `import 'package:flutter/services.dart';`（`TextInputFormatter` / `FilteringTextInputFormatter`）。

`today_page.dart` 的 `_editResult` 改为宿主 `AlertDialog` + `OutcomeComposer`（替换 `_ResultNoteDialog`）：

```dart
  /// 回填成果/进展；可以只存进展，也可以顺手标记完成。
  Future<void> _editResult(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoriesProvider).planItem;
    final edit = await showDialog<_ResultEdit>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成果 / 进展'),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              OutcomeComposer(
                initial: item.resultNote,
                onSubmit: (String encoded, {required bool markDone}) =>
                    Navigator.of(context).pop(
                      _ResultEdit(done: markDone, note: encoded),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
    if (edit == null) {
      return;
    }
    await repo.setStatus(
      item.id,
      _statusAfterResult(edit),
      resultNote: edit.note.isEmpty ? null : edit.note,
    );
  }

  /// 回填后的条目状态（spec §5.1）。
  ///
  /// - 点「完成」⇒ `done`；
  /// - 结论芯片含「顺延到明天」⇒ `deferred`、含「取消」⇒ `cancelled`；
  /// - 其余结论芯片 ⇒ 保持原状态。
  PlanStatus _statusAfterResult(_ResultEdit edit) {
    if (edit.done) {
      return PlanStatus.done;
    }
    return switch (ResultNote.parse(edit.note).outcome) {
      '顺延到明天' => PlanStatus.deferred,
      '取消' => PlanStatus.cancelled,
      _ => PlanStatus.fromCode(item.status) ?? PlanStatus.pending,
    };
  }
```

（`_ResultNoteDialog` 随之删除；`_ResultEdit` **保留**为弹窗回传载荷。文案与状态一次写入：`setStatus(id, status, resultNote:)` —— `resultNote` 传 `null` 表示「本次不改文案」。`today_page.dart` 需要 `import 'package:core_domain/core_domain.dart';`（`ResultNote` 由 `core_domain` 导出）；若已有则不要重复加。）

> **契约修订 R1（控制器，2026-11-09）—— Task 9 的五处口径冲突已裁定，实现者照做，别"优化"**
>
> **C1（接线 · 必改）** 原计划 Step 3 的 `showDialog<String>(builder: (context) => OutcomeComposer(...))` **既没传 `onSubmit`、也没有任何 `Navigator.pop`** ⇒ `showDialog` 永远返回 `null`，`repo.setResultNote` 永不执行，功能完全失效；另外裸 `Column` 当弹窗内容缺 `Material` 祖先，`TextField` 会触发 `debugCheckHasMaterial` 断言。裁定：① 弹窗必须是宿主 `AlertDialog`（`Material` 祖先）；② `onSubmit` 回调里 `Navigator.of(context).pop(...)` 回传；③ 合成器**不自己**弹窗。
>
> **C2（状态语义 · 必改）** 原计划要删掉「只存进展 / 完成」双按钮，但 spec §5.1 规定 `status` 由「结论芯片含 `顺延到明天` = `deferred`、`取消` = `cancelled`；勾选 = `done`」驱动，且现有 e2e（`p1_e2e_test.dart` P1-6）断言「只存进展不改状态、点完成才转完成」。裁定：**保留双按钮**（按钮文案不变：`取消` / `只存进展` / `完成`），「完成」= `markDone: true`，「只存进展」= `markDone: false`；状态口径 = 点「完成」⇒ `done`；否则结论芯片 `顺延到明天` ⇒ `deferred`、`取消` ⇒ `cancelled`；其余结论芯片 ⇒ 保持原状态。**交互方式变了，`p1_e2e_test.dart` 的 P1-6 用例必须同步改**（控制器已授权，只许改那一个用例）：把「往结果框里打字」改成「点结论芯片」，断言文案随之改成规范串（`[结论]按时完成`），**「只存进展不改状态 / 点完成才转完成 / 完成不抹掉已有进展」三条语义必须原样保留**；改完后若 `_resultField()` 辅助函数不再被引用，**必须删掉它**（否则 `unused_element` 让 analyze 报错）。
>
> **C3（回填 · 必改）** 原计划的 `_nextStepController` 初始化为空 ⇒ 初始文案里已有的 `[下一步]` 自由文本（如「周四上午做完」）不会回填进输入框，反解态显示为空。裁定：控制器初值 = `ResultNote.parse(widget.initial).nextStep`，并实现 `didUpdateWidget`（`widget.initial` 变化时重新解析并同步输入框）。
>
> **C4（互斥 · 必改）** `[下一步]` 槽位同时有「芯片短语」与「自由文本」两个来源。裁定：**芯片与自由文本互斥** —— 选中芯片清空输入框；输入文本则取消芯片选中（芯片选中态由「当前 `[下一步]` 文本是否恰好等于某个芯片短语」反推）。否则 `[下一步]` 段的落库内容取决于最后一次操作，不可预期。
>
> **C5（空文案 · 必改）** spec §6.1：三段全空 ⇒ `result_note` 为 NULL（未回填）。裁定：宿主写库时 `resultNote: edit.note.isEmpty ? null : edit.note` —— 传 `null` 表示「本次不改文案」，**禁止**把空串写进 `result_note`（否则回填率统计会把空串当成已回填）。
>
> **范围纪律**：只写计划给的 4 个文件、计划给的 5 个测试用例（3 个原用例 + 2 个控制器裁定新增用例：`点完成要带 done 意图`、`初始下一步自由文本要回填进输入框`）。**不要**顺手加别的用例、不要动 `chip_row.dart`、不要动 `packages/**`。

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\outcome_composer_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: 新测试（5 个用例）PASS；全量测试 **+82 通过**（Task 8 收口基线 +77，本任务 +5 个新用例；P1-6 是**改**不是**加**）；analyze 逐字 `No issues found!`（error / warning / info 全 0）。

- [x] **Step 5: 证据落盘**

- `apps\desktop\lib\src\widgets\outcome_composer.dart` 存在；`_ResultNoteDialog` 已从 `today_page.dart` 移除；`_ResultEdit` 仍在。
- `apps\desktop\test\outcome_composer_test.dart` 5 个用例全绿；`p1_e2e_test.dart` 的 P1-6 用例已改成「点结论芯片」交互且全绿。
- 全量 `flutter test` = **+82 通过**；`flutter analyze` 输出逐字 `No issues found!`。
- 证据文件：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\task-9-implementer.txt`，**首行必须是 `RESULT: PASS`**（或 `RESULT: FAIL` + 失败原因），正文含 4 个文件的字节数 / sha16 / LF（CR=0）/ 无 BOM / `print(`=0 核验结果，以及 Step 2 红灯与 Step 4 三套命令的原始输出摘录。

---

## Task 10: `LoopProgressRing` —— 闭环环（唯一口径的展示层）

**Files:**
- Create: `apps/desktop/lib/src/widgets/loop_progress_ring.dart`
- Modify: `apps/desktop/lib/src/pages/today_page.dart`（`_TodayBody` 顶部插入闭环环）
- Test: `apps/desktop/test/loop_progress_ring_test.dart`

**Interfaces:**
- Consumes: `DayStats`（Task 6）、`AppTokens`（Task 1）
- Produces:
  - `enum DayStatsSegment { plan, backfill, review, mood }`
  - `class LoopProgressRing extends StatelessWidget { const LoopProgressRing({super.key, required this.stats, this.onJump}); DayStats stats; void Function(DayStatsSegment segment)? onJump; }`

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/loop_progress_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/widgets/loop_progress_ring.dart';
import 'package:core_data/core_data.dart';

void main() {
  testWidgets('四个数字全部可点并回调对应段', (tester) async {
    final jumped = <DayStatsSegment>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoopProgressRing(
            stats: const DayStats(
              planTotal: 8,
              planDone: 6,
              backfilled: 4,
              reviewDone: false,
              moodDone: false,
            ),
            onJump: jumped.add,
          ),
        ),
      ),
    );
    expect(find.text('6/8'), findsOneWidget);
    expect(find.text('4/6'), findsOneWidget);
    await tester.tap(find.text('复盘'));
    expect(jumped, contains(DayStatsSegment.review));
  });

  testWidgets('x=0 时回填显示 — 而不是 100%', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoopProgressRing(
            stats: DayStats(
              planTotal: 0,
              planDone: 0,
              backfilled: 0,
              reviewDone: true,
              moodDone: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\loop_progress_ring_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/loop_progress_ring.dart
import 'package:flutter/material.dart';

import 'package:core_data/core_data.dart';

import '../theme/app_tokens.dart';

/// 闭环环的四个可点段。
enum DayStatsSegment {
  /// 计划 x/y。
  plan,

  /// 回填 m/x。
  backfill,

  /// 复盘。
  review,

  /// 心态。
  mood,
}

/// 顶部闭环环。
///
/// 数字全部来自 [DayStats]（唯一口径），本 widget **不自己算**。
class LoopProgressRing extends StatelessWidget {
  /// 创建闭环环。
  const LoopProgressRing({super.key, required this.stats, this.onJump});

  /// 当日统计。
  final DayStats stats;

  /// 点击某段时的回调（跳到对应段）。
  final void Function(DayStatsSegment segment)? onJump;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = stats.backfillRate;

    final entries = <_Entry>[
      _Entry(
        segment: DayStatsSegment.plan,
        label: '计划',
        value: '${stats.planDone}/${stats.planTotal}',
        gap: stats.planPending > 0,
      ),
      _Entry(
        segment: DayStatsSegment.backfill,
        label: '回填',
        value: rate == null ? '—' : '${stats.backfilled}/${stats.planDone}',
        gap: stats.planDone > stats.backfilled,
      ),
      _Entry(
        segment: DayStatsSegment.review,
        label: '复盘',
        value: stats.reviewDone ? '✓' : '▸',
        gap: !stats.reviewDone,
      ),
      _Entry(
        segment: DayStatsSegment.mood,
        label: '心态',
        value: stats.moodDone ? '✓' : '▲',
        gap: !stats.moodDone,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.gapCard / 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.hairSoft, width: 1),
      ),
      child: Row(
        children: [
          for (final entry in entries)
            Expanded(
              child: InkWell(
                onTap: onJump == null ? null : () => onJump!(entry.segment),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTokens.meta,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTokens.ink,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (entry.gap) ...[
                            const SizedBox(width: 4),
                            Container(width: 14, height: 4, color: AppTokens.accent),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.segment,
    required this.label,
    required this.value,
    required this.gap,
  });

  final DayStatsSegment segment;
  final String label;
  final String value;
  final bool gap;
}
```

在 `today_page.dart` 的 `_TodayBody.build` 里，**把闭环环插入到 `ListView.children` 的最前面**
（`const StandupSection()` 保持在它**下面**，**不得替换掉站会区块** —— 今日页的自上而下顺序是
闭环环 → 站会 → 计划 → 习惯回填 → 复盘 → 心态）：

```dart
              LoopProgressRing(
                stats: ref.watch(dayStatsProvider),
                onJump: (segment) => _jumpTo(segment),
              ),
              const StandupSection(),
```

`today_page.dart` 的 import 段按现有字母序**新增一行**（放在 `habit_section.dart` 之后、`mood_section.dart` 之前）：

```dart
import '../widgets/loop_progress_ring.dart';
```

`ref.watch(dayStatsProvider)` **不需要新增 import**：`today_page.dart` 已经 `import '../providers.dart';`，
且 `_TodayBody extends ConsumerWidget`。

`_jumpTo` 当前**不存在**，本任务需在 `_TodayBody` 里新增一个**空实现**（TODO 标注 Task 15 落地）：

```dart
  /// 跳到闭环环的某一段。TODO(Task 15)：用 `Scrollable.ensureVisible` + `GlobalKey` 滚到对应段。
  void _jumpTo(DayStatsSegment segment) {
    // Task 15 建立三段骨架后补齐滚动实现；本任务只提供调用点。
  }
```

（Task 15 建立三段骨架后，`_jumpTo` 改用 `Scrollable.ensureVisible` + `GlobalKey` 滚到对应段。）

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\loop_progress_ring_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: PASS + analyze 零问题。全量回归应为 **+84**（基线 +82 + 本任务 2 个用例）。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\loop_progress_ring.dart` + 测试文件存在且全绿。

### 契约修订 R2（D1–D4）—— 本轮控制器实测后修订，照做，别"优化"

| # | 实测发现的冲突 | 裁定 |
| --- | --- | --- |
| D1 | 实现代码块用了 `FontFeature.tabularFigures()`。控制器初判「`FontFeature` 只住在 `dart:ui`，`material.dart` / `painting.dart` 均未导出 ⇒ 需补 `import 'dart:ui' show FontFeature;`」——**该初判已被实测证伪**：本机 Flutter 3.47.9 / Dart 3.13.7 的 `packages/flutter/lib/src/painting/basic_types.dart:14-23` 已 `export 'dart:ui' show ... FontFeature, ...`，经 `painting.dart:28` → `material.dart:200 export 'widgets.dart'` 间接导出 ⇒ `package:flutter/material.dart` **本身就提供** `FontFeature` | **删除** `import 'dart:ui' show FontFeature;`（Step 3 代码块已同步删掉）。理由：保留它会触发 `unnecessary_import` **info**，而 analyze 硬门禁要求逐字 `No issues found!`（issue 行 0）⇒ 两者互斥，必删 |
| D2 | Interfaces 段写 `required this.onJump`，但实现里 `onJump` 是可选（测试第 2 例不传） | 统一为 `this.onJump`（已改上方 Interfaces 段） |
| D3 | 原文「`ListView` 的第一个 child **改为**」会**顶掉** `const StandupSection()`（站会区块），与今日页「站会 → 计划 → 回填 → 复盘 → 心态」的自上而下顺序冲突；且 `today_page.dart` 现有 import 段**没有** `loop_progress_ring.dart`，`_jumpTo` 也**不存在** | 改为「**插入到 `children` 最前面**——**闭环环在最前、`const StandupSection()`（站会）紧随其后**；`StandupSection()` 既不得被顶掉，也不得移到环之前」；import 段按字母序新增 `import '../widgets/loop_progress_ring.dart';`；`_jumpTo` 在 `_TodayBody` 里新增**空实现**并写明 `TODO(Task 15)`。`ref.watch(dayStatsProvider)` **无需新增 import**（已有 `import '../providers.dart';`，且 `_TodayBody extends ConsumerWidget`） |
| D4 | Step 4 只写「PASS + analyze 零问题」，没有全量基准 | 明确全量应为 **+84**（基线 +82 + 本任务 2 个用例） |

**R2 修正（实现者交付后控制器追认）**：D1 的前提在本机不成立（见上表 D1 行）。实现者已按「不写 `dart:ui` import」交付并自测 analyze 零问题；控制器**追认**该偏离，把 Step 3 代码块与本表 D1 行一并改正，并同步修正 brief 与 verifier 判据。**判据以修正后的计划 / brief 为准。**

**控制器自查教训**：D1 初判时只 grep 了 `material.dart` / `painting.dart` 两层，没追 `src/painting/basic_types.dart` 与 `widgets.dart` 的转发链，把「已导出」误判成「未导出」；**更糟的是本项目 `reports\task7-preflight.md:33` 与 `progress.md:481` 早已写明「`FontFeature.tabularFigures()` 可用（material → widgets → painting → `dart:ui` 导出面），无需额外 `dart:ui` import」——控制器下笔前没查项目内既有记录**。**教训 1：断言「某符号 X 不存在」之前，必须把整条导出链追到底（含 `export` 转发层）。教训 2：写契约前必须先 grep 项目内既有的 preflight / progress 记录，确认没有相反的历史结论。**

**范围纪律**：本任务只碰 `apps/desktop/lib/src/widgets/loop_progress_ring.dart`（新建）、
`apps/desktop/test/loop_progress_ring_test.dart`（新建）、`apps/desktop/lib/src/pages/today_page.dart`（改）。
`packages/**`、`chip_row.dart`、`docs/schema_v1.sql`、spec / design-demos **一律不动**；
不许改计划复选框（只由控制器打）、不许改 `progress.md`、不许跑 git。

---

## Task 11: `DateBar` —— 顶部日期定位条

**Files:**
- Create: `apps/desktop/lib/src/widgets/date_bar.dart`
- Modify: `apps/desktop/lib/src/pages/today_page.dart`（`_TodayBody` 顶部插入日期条）
- Test: `apps/desktop/test/date_bar_test.dart`

**Interfaces:**
- Consumes: `selectedDateProvider` / `todayProvider`（Task 6）、`calendar.dart` 的 `dateTitle` / `relativeDayLabel`（Task 5）、`shiftIsoDate`（`core_data`）
- Produces:
  - `class DateBar extends ConsumerWidget { const DateBar({super.key, this.onPickDate}); void Function(String date)? onPickDate; }`

**宿主接线（`today_page.dart`）—— 文字口径，照做；本段不参与逐行比对，但每条都要可核对**

| # | 接线要求 |
| --- | --- |
| **H1** | `today_page.dart` 的 import 段新增 `import '../widgets/date_bar.dart';`，按字母序插在 `import '../widgets/habit_section.dart';` **之前**（`date_bar` < `habit_section`，位置在 `import '../providers.dart';` 之后） |
| **H2** | `DateBar` 放在 `_TodayBody.build` 返回的 `Column` 的**第一个 child**（即 `Expanded(ListView)` **之前**）⇒ 日期条**固定在顶部**，不随内容滚动 |
| **H3** | `ListView.children` 的**顺序本轮不许动**：仍是「闭环环（Task 10）→ `const StandupSection()` → 今日计划 → 习惯 → 复盘 → 心态」 |
| **H4** | `onPickDate` 本轮**不传** ⇒ 写成 `const DateBar()`（`DatePickerSheet` 是 Task 12 的产物，`onPickDate == null` ⇒ 标题不可点） |

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/date_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/providers.dart';
import 'package:practilog/src/widgets/date_bar.dart';

void main() {
  testWidgets('显示日期标题；过去显示补录模式、未来显示预排', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('scope-today'),
        overrides: [todayProvider.overrideWithValue('2026-11-07')],
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    expect(find.text('2026-11-07 周六'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('scope-past'),
        overrides: [
          todayProvider.overrideWithValue('2026-11-07'),
          selectedDateProvider.overrideWith((ref) => '2026-11-05'),
        ],
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    expect(find.text('补录模式'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('scope-future'),
        overrides: [
          todayProvider.overrideWithValue('2026-11-07'),
          selectedDateProvider.overrideWith((ref) => '2026-11-09'),
        ],
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    expect(find.text('预排'), findsOneWidget);
  });

  testWidgets('左右箭头切日，今天按钮回到今天', (tester) async {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue('2026-11-07')],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DateBar())),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('date-bar-next')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-08');
    await tester.tap(find.byKey(const ValueKey('date-bar-today')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-07');
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\date_bar_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/date_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_data/core_data.dart';

import '../providers.dart';
import '../theme/app_tokens.dart';

/// 顶部日期定位条（今日页 / 日历页 / 待办池 / 习惯 / 项目共用）。
///
/// 形如：`‹ 前一天　2026-11-07 周六　后一天 ›　[补录模式] [今天]`
class DateBar extends ConsumerWidget {
  /// 创建日期条。
  const DateBar({super.key, this.onPickDate});

  /// 点标题时的回调（打开 [DatePickerSheet]）；null 表示不可点。
  final void Function(String date)? onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final date = ref.watch(selectedDateProvider);
    final today = ref.watch(todayProvider);
    final isPast = date.compareTo(today) < 0;
    final isFuture = date.compareTo(today) > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.hair, width: 1)),
      ),
      child: Row(
        children: [
          _ArrowButton(
            key: const ValueKey('date-bar-prev'),
            icon: Icons.chevron_left,
            tooltip: '前一天',
            onPressed: () => ref
                .read(selectedDateProvider.notifier)
                .state = shiftIsoDate(date, -1),
          ),
          Expanded(
            child: InkWell(
              onTap: onPickDate == null ? null : () => onPickDate!(date),
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateTitle(date),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTokens.ink,
                      ),
                    ),
                    if (isPast || isFuture) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        text: isPast ? '补录模式' : '预排',
                        background: AppTokens.accentWash,
                        foreground: AppTokens.accentInk,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _ArrowButton(
            key: const ValueKey('date-bar-next'),
            icon: Icons.chevron_right,
            tooltip: '后一天',
            onPressed: () => ref
                .read(selectedDateProvider.notifier)
                .state = shiftIsoDate(date, 1),
          ),
          if (date != today) ...[
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('date-bar-today'),
              onPressed: () =>
                  ref.read(selectedDateProvider.notifier).state = today,
              child: const Text('今天'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }
}
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\date_bar_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: PASS + analyze 零问题；**全量回归 = +86**（基线 +84 + 本任务 2 个用例）；`flutter analyze` 必须逐字 `No issues found!`（error / warning / info 全 0）。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\date_bar.dart` + 测试文件存在且全绿。

### 契约修订 R3（E1–E5）—— 本轮控制器实测后修订，照做，别"优化"

| # | 实测发现的冲突 | 裁定 |
| --- | --- | --- |
| **E1** | **Files 段要求 `Modify: today_page.dart`（「`_TodayBody` 顶部插入日期条」），但 Step 3 只给了 `date_bar.dart` 的代码块，没有任何宿主接线代码** ⇒ 实现者无从判断「插到哪、插成什么样」，极易顶掉 Task 10 刚落的闭环环 | 按上方**宿主接线 H1–H4** 文字口径执行：`DateBar` 放在 `_TodayBody` 的 `Column` **第一个 child**（`Expanded(ListView)` 之前，固定在顶部）；`ListView.children` 顺序**本轮不动**；`onPickDate` 本轮不传 |
| **E2** | Step 4 只写「PASS + analyze 零问题」，没有全量基准 | 明确全量应为 **+86**（基线 +84 + 本任务 2 个用例） |
| **E3** | 前/后箭头 `tooltip` 写死「昨天 / 明天」，但箭头动作是相对**当前选中日期** ±1 天 ⇒ 处于补录模式时 tooltip 与实际动作不符 | 改为「**前一天 / 后一天**」（语义恒真）；Step 3 代码块与文件头注释已同步改 |
| **E4** | 测试第 1 例断言 `find.text('2026-11-07 周六')` 依赖 `dateTitle` 的确切格式 | **已核验成立**：`packages/core_data/lib/src/calendar.dart:83` 的 `dateTitle` 输出格式 = `yyyy-MM-dd 周X`，且 `2026-11-07` 为周六；`packages/core_data/lib/core_data.dart:20` 已 `export 'src/calendar.dart'` ⇒ `import 'package:core_data/core_data.dart';` 即可拿到 |
| **E5** | 加 `DateBar` 到真实 `TodayPage` 会不会撞既有 e2e 断言（`DateBar` 有「今天 / 补录模式 / 预排」等文案） | **已核验不撞**：`apps/desktop/test/p1_e2e_test.dart` 全文无 `find.text('今天')`；其用的是 `find.text('今天还没有计划条目')`（`find.text` 精确匹配，不受影响）；e2e 里 `selectedDateProvider` 初值 = `todayProvider` ⇒ `date == today` ⇒ **「今天」按钮不渲染**；`wiring_test.dart` 无 `TodayPage` 结构断言 |

**范围纪律**：本任务只碰 `apps/desktop/lib/src/widgets/date_bar.dart`（新建）、
`apps/desktop/test/date_bar_test.dart`（新建）、`apps/desktop/lib/src/pages/today_page.dart`（改：仅 import + `Column` 顶部插入 `DateBar`）。

### 契约修订 R4（E6–E7）—— 实现者交付后控制器追认并改正，照做，别"优化"

> 实现者按契约原文**逐字照抄**，**实测撞上两处契约自身的编译/运行级缺陷**。
> 实现者做了**最小修正**后交付（见 `reports\task-11-implementer.txt` 第 5 节），
> 控制器**事后追认**并把契约改对 —— **两个代码块已按下列裁定同步改正**，
> 实现者交付物与改正后的代码块**逐字一致**（verifier 的 A 项按改正后的代码块比对）。

| # | 实测发现的冲突 | 裁定 |
| --- | --- | --- |
| **E6** | Step 3 代码块写 `final isPast = date < today;` / `final isFuture = date > today;`，但 **Dart 的 `String` 不支持 `<` / `>` 运算符** ⇒ 实测报 `Error: The operator '<' isn't defined for the type 'String'.` ⇒ 代码块**照抄编译不过** | 改为 `date.compareTo(today) < 0` / `date.compareTo(today) > 0`（语义等价：ISO `yyyy-MM-dd` 字典序 ≡ 时间序；且与项目既有约定一致 —— `packages/core_data/lib/src/repositories.dart:563` 用 `startDate.compareTo(date) <= 0`）。**Step 3 代码块已同步改正** |
| **E7** | Step 1 测试块第 1 例在**同一个 `ProviderScope` 元素**上把 `overrides` 由 1 个变成 2 个 ⇒ **Riverpod 3.5.0 断言拒绝**（实测 `Tried to change the number of overrides.` / `Failed assertion: '_debugOverridesLength == overrides.length'`）⇒ 测试**照抄跑不过** | 三处 `ProviderScope` 各加一个区分用的 `key: const ValueKey('scope-today')` / `'scope-past'` / `'scope-future'` **强制重挂载**，`overrides` 列表原文一字不动。**Step 1 代码块已同步改正** |

---

## Task 12: `DatePickerSheet` —— 全站唯一日期组件

**Files:**
- Create: `apps/desktop/lib/src/widgets/date_picker_sheet.dart`
- Test: `apps/desktop/test/date_picker_sheet_test.dart`

**Interfaces:**
- Consumes: `buildMonthGrid` / `weekdayLabel`（Task 5）、`ChipRow`（Task 7）
- Produces:
  - `class DatePickerSheet extends StatefulWidget { const DatePickerSheet({super.key, required this.initial, this.weekStart = 1, this.allowNoDeadline = false}); String initial; int weekStart; bool allowNoDeadline; static Future<String?> show(BuildContext context, {required String initial, int weekStart = 1, bool allowNoDeadline = false}); }`

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/date_picker_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/core_data.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/widgets/date_picker_sheet.dart';

void main() {
  testWidgets('快捷芯片能选出今天', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '2026-11-03',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  testWidgets('月历渲染 42 格，且能翻月', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DatePickerSheet(initial: '2026-11-07')),
      ),
    );
    expect(find.text('2026-11'), findsOneWidget);
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('month-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 42);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('2026-10'), findsOneWidget);
  });

  testWidgets('无期限芯片返回 null', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '2026-11-07',
                  allowNoDeadline: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('无期限'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(captured, isNull);
  });

  testWidgets('方向键移动选中日并用 Enter 确认', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '2026-11-07',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(captured, '2026-11-08');
  });

  testWidgets('今天描边 + 周末标红', (tester) async {
    final todayIso = today();
    final month = todayIso.substring(0, 7);
    final first = '$month-01';
    final second = '$month-02';
    final initial = first == todayIso ? second : first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DatePickerSheet(initial: initial)),
      ),
    );
    final todayCell = find.byKey(ValueKey('day-$todayIso'));
    expect(todayCell, findsOneWidget);
    final todayBox = tester.widget<Container>(
      find.descendant(of: todayCell, matching: find.byType(Container)).first,
    );
    final todayBorder = (todayBox.decoration! as BoxDecoration).border!;
    expect(todayBorder.top.color, AppTokens.ink);
    expect(todayBorder.top.width, 2);

    final grid = buildMonthGrid(month, today: todayIso, weekStart: 1);
    final weekend = grid.firstWhere((c) => c.isWeekend && c.inMonth);
    final weekendCell = find.byKey(ValueKey('day-${weekend.date}'));
    expect(weekendCell, findsOneWidget);
    final weekendText = tester.widget<Text>(
      find.descendant(of: weekendCell, matching: find.byType(Text)).first,
    );
    expect(weekendText.style!.color, AppTokens.accentInk);
  });

  testWidgets('本周内芯片返回本周最后一天', (tester) async {
    String? captured;
    final todayIso = today();
    final month = todayIso.substring(0, 7);
    final parsed = parseIsoDate(todayIso)!;
    final expected = shiftIsoDate(todayIso, (7 - parsed.weekday) % 7);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await DatePickerSheet.show(
                  context,
                  initial: '$month-01',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本周内'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(captured, expected);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\date_picker_sheet_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/date_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:core_data/core_data.dart';

import '../theme/app_tokens.dart';
import 'chip_row.dart';

/// 全站唯一日期选择组件（spec §8.2）。
///
/// 任何页面**不得**自造日期选择控件。
class DatePickerSheet extends StatefulWidget {
  /// 创建日期选择弹层。
  const DatePickerSheet({
    super.key,
    required this.initial,
    this.weekStart = 1,
    this.allowNoDeadline = false,
  });

  /// 初始选中日期。
  final String initial;

  /// 每周首日（1 = 周一，7 = 周日）。
  final int weekStart;

  /// 是否显示「无期限」（仅 `todo.due_date` 用）。
  final bool allowNoDeadline;

  /// 以弹层方式打开；返回选中的日期，取消返回 null。
  static Future<String?> show(
    BuildContext context, {
    required String initial,
    int weekStart = 1,
    bool allowNoDeadline = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => DatePickerSheet(
        initial: initial,
        weekStart: weekStart,
        allowNoDeadline: allowNoDeadline,
      ),
    );
  }

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  /// 当前选中日期（`YYYY-MM-DD`）。
  String _selected = '';

  /// 当前显示的月份（`YYYY-MM`）。
  String _month = '';

  /// 最近一次点选的快捷芯片 key（空串 = 无）。
  String _activeChip = '';

  /// 是否选了「无期限」。
  bool _noDeadline = false;

  /// 月历网格的焦点节点（键盘可达的落点）。
  final FocusNode _gridFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _month = widget.initial.substring(0, 7);
  }

  void _shiftMonth(int delta) {
    setState(() {
      final parts = _month.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]) + delta;
      final shifted = DateTime(year, month, 1);
      _month = '${shifted.year.toString().padLeft(4, '0')}-'
          '${shifted.month.toString().padLeft(2, '0')}';
      _activeChip = '';
    });
  }

  /// 当月最后一天（`YYYY-MM-DD`）。
  String _monthLastDay() {
    final parts = _month.split('-');
    final last = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0);
    return '$_month-${last.day.toString().padLeft(2, '0')}';
  }

  /// 本周最后一天（按 `weekStart` 口径；`weekStart = 1` 时即本周日）。
  String _weekEnd(String todayIso) {
    final parsed = parseIsoDate(todayIso);
    if (parsed == null) {
      return todayIso;
    }
    final offset = (widget.weekStart - 1 + 7 - parsed.weekday) % 7;
    return shiftIsoDate(todayIso, offset);
  }

  /// 选中某个日期（并复位快捷芯片 / 无期限态）。
  void _selectDate(String date) {
    setState(() {
      _selected = date;
      _activeChip = '';
      _noDeadline = false;
    });
  }

  /// 方向键在**当月网格内**移动选中日（边界钳制，不跨月）。
  void _moveSelection(int delta) {
    final moved = shiftIsoDate(_selected, delta);
    final first = '$_month-01';
    final last = _monthLastDay();
    if (moved.compareTo(first) < 0) {
      _selectDate(first);
      return;
    }
    if (moved.compareTo(last) > 0) {
      _selectDate(last);
      return;
    }
    _selectDate(moved);
  }

  /// 确认并关闭弹层；「无期限」时返回 null。
  void _commit() {
    Navigator.of(context).pop(_noDeadline ? null : _selected);
  }

  /// 网格键盘事件：方向键移动选中日，`Enter` 确认。
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commit();
      return KeyEventResult.handled;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => 0,
    };
    if (delta == 0) {
      return KeyEventResult.ignored;
    }
    _moveSelection(delta);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _gridFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIso = today();
    final grid =
        buildMonthGrid(_month, today: todayIso, weekStart: widget.weekStart);

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一月',
            onPressed: () => _shiftMonth(-1),
          ),
          Expanded(
            child: Text(
              _month,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一月',
            onPressed: () => _shiftMonth(1),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChipRow(
              options: <ChipOption>[
                const ChipOption(key: 'today', label: '今天'),
                const ChipOption(key: 'yesterday', label: '昨天'),
                const ChipOption(key: 'before', label: '前天'),
                const ChipOption(key: 'tomorrow', label: '明天'),
                const ChipOption(key: 'week', label: '本周内'),
                if (widget.allowNoDeadline)
                  const ChipOption(key: 'none', label: '无期限'),
              ],
              selected: <String>{if (_activeChip.isNotEmpty) _activeChip},
              onChanged: (next) {
                if (next.isEmpty) {
                  return;
                }
                final key = next.first;
                setState(() {
                  _activeChip = key;
                  _noDeadline = key == 'none';
                  _selected = switch (key) {
                    'today' => todayIso,
                    'yesterday' => shiftIsoDate(todayIso, -1),
                    'before' => shiftIsoDate(todayIso, -2),
                    'tomorrow' => shiftIsoDate(todayIso, 1),
                    'week' => _weekEnd(todayIso),
                    _ => _selected,
                  };
                });
              },
            ),
            const SizedBox(height: 10),
            Shortcuts(
              shortcuts: <ShortcutActivator, Intent>{
                const SingleActivator(LogicalKeyboardKey.pageUp):
                    const _MonthIntent(-1),
                const SingleActivator(LogicalKeyboardKey.pageDown):
                    const _MonthIntent(1),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _MonthIntent: _MonthAction(onInvoke: _shiftMonth),
                },
                child: Focus(
                  focusNode: _gridFocus,
                  autofocus: true,
                  onKeyEvent: _handleKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          for (final label in const <String>[
                            '一',
                            '二',
                            '三',
                            '四',
                            '五',
                            '六',
                            '日',
                          ])
                            Expanded(
                              child: Center(
                                child: Text(label, style: theme.textTheme.labelSmall),
                              ),
                            ),
                        ],
                      ),
                      GridView.count(
                        key: const ValueKey('month-grid'),
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final cell in grid)
                            _DayCell(
                              key: ValueKey('day-${cell.date}'),
                              cell: cell,
                              selected: cell.date == _selected,
                              onTap: () => _selectDate(cell.date),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _commit,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _MonthIntent extends Intent {
  const _MonthIntent(this.delta);

  final int delta;
}

class _MonthAction extends Action<_MonthIntent> {
  _MonthAction({required this.onInvoke});

  final void Function(int delta) onInvoke;

  @override
  Object? invoke(_MonthIntent intent) {
    onInvoke(intent.delta);
    return null;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final CalendarCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: selected
                ? AppTokens.ink
                : cell.isToday
                ? AppTokens.ink
                : cell.inMonth
                ? AppTokens.hairStrong
                : AppTokens.hair,
            width: selected || cell.isToday ? 2 : 1,
          ),
          color: selected ? AppTokens.inkWash : null,
        ),
        child: Text(
          cell.date.substring(8),
          style: theme.textTheme.labelLarge?.copyWith(
            color: cell.inMonth
                ? (cell.isWeekend ? AppTokens.accentInk : AppTokens.ink)
                : AppTokens.faint,
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\date_picker_sheet_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: 目标测试 **6 例全绿**（`test\date_picker_sheet_test.dart`）；全量 `flutter test` 计数 **+92**（Task 11 收口基线 +86 + 本任务 6）；`flutter analyze` 零问题（逐字 `No issues found!`）。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\date_picker_sheet.dart` + 测试文件存在且全绿。

### 契约修订 R5（Task 12 派工前 · F1–F10）—— 控制器改计划契约后再派实现者

**背景**：控制器在派工前把 Task 12 契约的 Step 1 / Step 3 代码块逐行对照 spec §8.2、计划任务表第 21 行与 Flutter SDK 源码，坐实 10 处**契约自身缺陷**（不是实现者偏差）。以下为逐条裁定；实现者按下方代码块实现即可。

| 编号 | 缺陷 | 事实依据 | 裁定 |
|---|---|---|---|
| F1 | 第 1 例只点「今天」芯片就断言 `captured` 非空 | `DatePickerSheet.show` 返回的 Future 只在弹层 `Navigator.pop` 后才完成；点芯片只改内部选中态 ⇒ `captured` 恒为 null ⇒ 该例必失败 | 第 1 例补点「确定」，断言加强为「非空 + 匹配 `^\d{4}-\d{2}-\d{2}$`」 |
| F2 | 第 2 例用 `find.text('‹')` 找「上一月」 | 契约实现用的是 `Icon(Icons.chevron_left)`，图标不是 `Text` ⇒ `find.text` 命中 0 个，`tester.tap` 直接抛错 | 改用 `find.byIcon(Icons.chevron_left)` |
| F3 | 月历内层 `Column` 未设 `mainAxisSize` | 内层默认 `MainAxisSize.max`，在 `AlertDialog` 内容槽（800×600 窗口下可用高度约 388px）会撑满，外层 `mainAxisSize.min` 子项合计 26+10+388 = 424 > 388 ⇒ RenderFlex 溢出 | 内层 `Column` 补 `mainAxisSize: MainAxisSize.min` |
| F4 | `late String _selected = widget.initial;` | `late` 初始化器读 `widget` 语义可疑，且有 `unnecessary_late` 风险 | 改为 `initState` 里显式初始化 `_selected` / `_month` |
| F5 | 「本周内」映射为 `shiftIsoDate(today, 7)` | 那是**下周**同一天，与 spec §8.2 / §5 的芯片文案「本周内」矛盾 | `week` ⇒ 本周最后一天（按 `weekStart` 口径，`weekStart=1` 时即本周日），新增 `_weekEnd()` |
| F6 | 「无期限」芯片落到 `_ => today` 分支 | 点「无期限」等于选中今天，与 `Future<String?>` 的语义相反 | 新增 `_noDeadline`；选「无期限」⇒ `_noDeadline = true`；「确定」⇒ `Navigator.pop(null)`；选其他芯片 / 点日期格 ⇒ 复位 `false` |
| F7 | `ChipRow` 未传 `selected` | 快捷芯片永远不高亮 | 新增 `_activeChip`，传 `selected: <String>{if (_activeChip.isNotEmpty) _activeChip}`；点日期格 / 翻月时清空 |
| F8 | 网格 `Focus` 缺 `autofocus` ⇒ 键盘整体失效 | Flutter 源码：`ShortcutManager.handleKeypress` 用 **`primaryFocus?.context`** 去 `Actions.maybeFind`（`shortcuts.dart:925-926`），而 `Actions.maybeFind` 只查**祖先**（`actions.dart:759-779`）。弹层内没有节点获得焦点时 primary focus 是路由的 `FocusScopeNode`（位于 `Actions` 之上）⇒ 找不到 Action ⇒ `PgUp/PgDn` 翻月永远不触发 | 网格 `Focus` 必须带 `autofocus: true`（`focus_scope.dart:625-630`：`FocusScope.of(context).autofocus(focusNode)`） |
| F9 | spec §8.2 与计划任务表第 21 行要求的「方向键 + `Enter` 可达」在契约里缺失 | 契约 Step 3 只有 `PgUp/PgDn` | 同一网格 `Focus` 上加 `onKeyEvent`：方向键在**当月网格内**移动选中日（边界钳制，不跨月），`Enter` / `NumpadEnter` 等价于「确定」 |
| F10 | Step 4 未写死测试计数 | 门禁需要确定基线 | Step 4 写死：目标测试 **4 例全绿**、全量 **+90**、analyze 零问题；测试由 2 例扩到 4 例（新增「无期限返回 null」「方向键 + Enter」） |

**范围纪律**：本轮 Task 12 只新增 `apps\desktop\lib\src\widgets\date_picker_sheet.dart` 与 `apps\desktop\test\date_picker_sheet_test.dart` 两个文件，**不改** `today_page.dart`（`DateBar.onPickDate` 接线留到后续 Task）；`loop_progress_ring.dart` / `chip_row.dart` / `packages\core_data` 一律只读。

### 契约修订 R6（Task 12 实现者交付后 · G1–G3）—— 控制器事后追认并改正计划契约

**背景**：实现者按 R5 改正后的代码块逐字实现，实测撞上 **3 处契约自身的编译级缺陷**（**不是**实现者偏差）。控制器已独立复核属实（计划 Task 12 段原文逐行对照 + 编译器报错），**事后追认**并把契约改正如下。F1–F10 的语义**未变**。

| 编号 | 契约缺陷 | 事实依据 | 裁定 |
|---|---|---|---|
| G1 | `final today = today();` 局部变量自引用 | Dart 中局部变量 `today` 在自己的初始化器里遮蔽了顶层函数 `today()` ⇒ 编译报错（局部变量引用自身） | 改名为 `todayIso`，并同步该 `build` 方法内的全部引用：`buildMonthGrid(_month, today: todayIso, weekStart: widget.weekStart)` 与芯片 `switch` 的 5 处（`today` / `yesterday` / `before` / `tomorrow` / `week`）。`_weekEnd(String todayIso)` 的参数名原本就已是 `todayIso`，保持不变 |
| G2 | `const _MonthAction({required this.onInvoke});` | `Action` 的父构造子不是 const ⇒ const 构造子非法 ⇒ 编译报错 | 去掉 `const`：`_MonthAction({required this.onInvoke});` |
| G3 | `Object invoke(_MonthIntent intent) => onInvoke(intent.delta);` | `onInvoke` 的返回类型是 `void` ⇒ 不能作为表达式返回值 ⇒ 编译报错 | 改为块体：`Object? invoke(_MonthIntent intent) { onInvoke(intent.delta); return null; }` |

**判读说明**：G1 的改名不是命名风格偏好，而是编译必需的遮蔽修复；G2 / G3 是 Dart 语言层面的签名约束。这 3 处属于**契约文本自身写错**，控制器追认后写回计划，**实现者的这 3 处最小修正不得按偏离判 FAIL**；反过来，实际文件若仍出现 `final today = today();`、`const _MonthAction`、`Object invoke(` 那才是偏离。

**范围纪律不变**：本轮仍只新增 `date_picker_sheet.dart` 与 `date_picker_sheet_test.dart` 两个文件；`today_page.dart` / `date_bar.dart` / `loop_progress_ring.dart` / `chip_row.dart` / `packages\core_data` 一律只读。

### 契约修订 R7（Task 12 独立 verifier 判 FAIL 后 · H1–H8）—— 控制器事后追认并改正计划契约

**背景**：独立 verifier（会话 `mvs_ba0c0e0d82bf4f2f9c2c5fdb3657b8ff`，报告 `reports\task-12-verifier.txt`，首行 `VERDICT: FAIL`）在 C 项判定 **不通过**：「今天描边」与「周末标红」两项在交付物中完全缺失（全文 `isToday` / `isWeekend` **零命中**）。verifier A 项同时证明**实现与契约 Step 3 代码块逐字一致**（归一化后仅 1 处差异，且该差异是契约自身笔误）⇒ 根因在**契约自身缺陷**，不是实现者偏差。本轮按 R6 同一纪律**事后追认**并把契约改对。

| 编号 | 契约缺陷 | 事实依据 | 裁定 |
|---|---|---|---|
| H1 | 「今天描边」缺失：Step 3 代码块的 `border` 分支只有 `selected` / `cell.inMonth` | spec §8.2:295「下半：月历（连续翻月、今天描边、周末标红、已选填充）」；`packages\core_data\lib\src\calendar.dart:24/:66` 已提供 `isToday`；项目内既有口径见本计划 Task 13 段（`color: cell.isToday ? AppTokens.ink : AppTokens.hairStrong` / `width: cell.isToday ? 2 : 1`） | `border` 增 `cell.isToday` 分支：**今天（未选中）= `AppTokens.ink` 2px 描边**；选中仍为 ink 2px + `inkWash` 填充（今天恰被选中时两者同色，靠填充区分） |
| H2 | 「周末标红」缺失：日期文字色只区分 `inMonth` | spec §8.2:295 要求「周末标红」；但 **B 版 token 体系里没有红色** —— `app_tokens.dart` 唯一警示色系是赭石（`accent` 仅作图形填充 / `accentInk` 赭石文字版，注释原文「缺口状态文字、警示文案」），且 `theme.colorScheme.error = AppTokens.accentInk` | 周末日期数字用 **`AppTokens.accentInk`**（赭石文字版）。**裁定依据**：spec 的「标红」指「以警示色标出」的语义，B 版落地为唯一警示色系（赭石）。**禁止自造红/粉等新色值**（B 版视觉真源是 `design-demos\TOKENS.md`）；只对**本月格**生效，非本月补白格仍走 `AppTokens.faint` |
| H3 | 计划原 4323 行 `final grid = buildMonthGrid(_month, today: todayIso, weekStart: widget.weekStart));` 末尾多一个右括号且超 80 列（verifier [低]5） | 该行语法非法（括号不配对）；实际文件 168-169 行的两行写法才是唯一可编译形式 | 拆成两行：`final grid =` + 缩进 `buildMonthGrid(_month, today: todayIso, weekStart: widget.weekStart);`（与交付物一致） |
| H4 | 补上 H1/H2 后若无断言 ⇒ 下一轮 verifier 仍会判覆盖缺口（verifier [中]4） | verifier E 项 M3 变异（`_weekEnd` 改回 `shiftIsoDate(todayIso, 7)`）**未杀红**，证明交付的 4 个用例对「今天描边 / 周末标红 / 本周内 / 42 格」**零断言** | 测试由 4 例扩到 **6 例**：新增第 5 例「今天描边 + 周末标红」、第 6 例「本周内芯片返回本周最后一天」 |
| H5 | 「本周内」无任何断言 | 同上（verifier E 项 M3 未杀红） | 新增第 6 例：用 `parseIsoDate(today()).weekday` 独立算出**本周最后一天**（`weekStart=1` ⇒ 周日）作为期望值，点「本周内」→「确定」后断言相等。该期望值与实现的 `(weekStart - 1 + 7 - weekday) % 7` 同结果但**独立推导**，且对 M3 变异（+7）必杀红 |
| H6 | 用例 2 名为「月历渲染 42 格」却无格子计数断言（verifier [中]4） | `GridView.count` 的 `childrenDelegate` 是 `SliverChildListDelegate` ⇒ `estimatedChildCount` 恒等于 42，**不依赖懒加载**（渲染出来的子项数会随视口裁剪，不可靠） | 给 `GridView.count` 加 `key: const ValueKey('month-grid')`；用例 2 断言 `tester.widget<GridView>(find.byKey(...)).childrenDelegate.estimatedChildCount == 42` |
| H7 | 测试无法精确定位「今天那一格」 | 月历是 6×7 网格，**相邻月补白格与本月格日号会重复** ⇒ `find.text('09')` 可命中多个；`_DayCell` 是文件私有类，测试文件不可引用 | 给 `_DayCell` 传 `key: ValueKey('day-${cell.date}')`（**完整 ISO** ⇒ 全网格唯一，含补白格）；`_DayCell` 构造补 `super.key`。测试用例 5 的 `initial` 取当月 1 号 / 2 号中**不等于今天**的那个（保证今天格处于未选中态） |
| H8 | 门禁基线 | — | 目标测试 **4 例 → 6 例**；全量 **+90 → +92**（Task 11 收口基线 +86 + 本任务 6）；analyze 仍零问题 |

**判读说明**：H1 / H2 的**语义来源是 spec §8.2:295**（契约散文早就写了「今天描边、周末标红」，是**代码块漏了**）⇒ 属契约自身缺陷，控制器追认后写回计划；实现者按上方代码块改即**不得判偏离**。H2 的色值裁定（赭石 `accentInk` 而非字面「红」）是**唯一允许的口径**，如与 spec 字面冲突，以本表 + `app_tokens.dart` 为准并登记遗留。

**范围纪律不变（R7）**：仍只改 `date_picker_sheet.dart` 与 `date_picker_sheet_test.dart` 两个文件；`today_page.dart` / `date_bar.dart` / `loop_progress_ring.dart` / `chip_row.dart` / `packages\core_data` 一律只读。

### 契约修订 R8（Task 12 R7 修复轮交付后 · H9）—— 控制器事后追认并改正计划契约

**背景**：R7 修复轮的实现者交付后，亲跑 `flutter analyze` 在本机 SDK 上对 R7/H6 契约代码块里的
`childrenDelegate!.estimatedChildCount` 报出 **1 条 warning**（`unnecessary_non_null_assertion` ——
`GridView.childrenDelegate` 的 getter 返回**非空类型**）⇒ 直接违反「analyze 的 error / warning / **info** 全 0」硬门禁。
实现者去掉 `!`（语义等价）后门禁才转绿。控制器复核属实 ⇒ 属**契约自身缺陷**，事后追认。

| 编号 | 契约缺陷 | 事实依据 | 裁定 |
|---|---|---|---|
| H9 | R7/H6 代码块写 `childrenDelegate!.estimatedChildCount` | 本机 Flutter SDK 下 `GridView.childrenDelegate` 的 getter 返回非空类型 ⇒ `!` 触发 `unnecessary_non_null_assertion`（**warning** 级）⇒ analyze 硬门禁不通过 | 去掉 `!`，改为 `childrenDelegate.estimatedChildCount`（语义等价：`GridView.childrenDelegate` 在本 SDK 上必非空） |

**判读说明**：H9 是**契约文本自身写错**（`!` 在本 SDK 上多余），控制器追认后写回计划；实现者去掉 `!` 的最小修正
**不得按偏离判 FAIL**。反过来，若最终测试文件仍写 `childrenDelegate!.estimatedChildCount` ⇒ 在本 SDK 上
analyze 必报 warning，那才是偏离。

**范围纪律不变（R8）**：仍只改 `date_picker_sheet.dart` 与 `date_picker_sheet_test.dart` 两个文件；其余一律只读。


---

## Task 13: `CalendarMonthView` —— 月历网格（三层信息 + 形状徽标）

**Files:**
- Create: `packages/core_data/lib/src/calendar_summary.dart`
- Modify: `packages/core_data/lib/src/repositories.dart`（新增 3 个区间查询方法）
- Modify: `packages/core_data/lib/core_data.dart`（加 `export 'src/calendar_summary.dart';`）
- Create: `apps/desktop/lib/src/widgets/calendar_month_view.dart`
- Modify: `apps/desktop/lib/src/providers.dart`（新增 `calendarMonthProvider`）
- Test: `packages/core_data/test/calendar_summary_test.dart`、`apps/desktop/test/calendar_month_view_test.dart`

**Interfaces:**
- Consumes: `buildMonthGrid`（Task 5）、`computeDayStats` / `DayStats`（Task 6）
- Produces:
  - `PlanItemRepository.listRange(String startDate, String endDate) → Future<List<PlanItemData>>`
  - `HabitRepository.listCheckinsRange(String startDate, String endDate) → Future<List<HabitCheckinData>>`
  - `DayLogRepository.listRange(String startDate, String endDate) → Future<List<DayLogData>>`
  - `final class CalendarDaySummary { String date; int planDone; int planTotal; int habitDone; int habitTotal; double? moodAverage; bool moodFailed; bool future; String get badge; }`
  - `final class CalendarMonthSummary { String month; List<CalendarDaySummary> days; }`
  - `calendarMonthProvider`（`FutureProvider.family<CalendarMonthSummary, String>`）

**本 Task 的口径（控制器预检已定，实现必须逐条满足）：**

1. **日号不补零**：`2026-11-07` 渲染成 `7`（不是 `07`）。补白格按 ISO key 定位，不靠文本。
2. **徽标形状**：`✓` 全完成 · `●` 有未完成 · `○` 完全空白 · `▸` 未来带排期；判定顺序 = 未来预排 → 完全空白 → 全完成 → 有未完成。
3. **完成度底色**：按 `planDone / planTotal` 比例叠加 `AppTokens.inkWash`；无计划日不加底色。
4. **日期格 key**：每格 `key: ValueKey('day-YYYY-MM-DD')`；网格 `key: const ValueKey('month-grid')`。
5. **区间查询一次取全月**：禁止按格子 N+1 查询。
6. **习惯排期口径**：与 `HabitRepository.listScheduledFor` 一致 —— 既要在那天有排程，也要在习惯起始日之后。
7. **全完成底色**在 B1 用「满比例 inkWash」近似 spec §8.1 的「实心」，真机像素核对留到 Task 17。
8. **公开成员一律带 doc comment**（根 `analysis_options.yaml` 开了 `public_member_api_docs`）。
9. **补白格同样渲染日号**（只把颜色压成 `AppTokens.faint`）⇒ 同一个数字可能在本月与补白格各出现一次，**定位一律走 `ValueKey('day-YYYY-MM-DD')`，不许按文本找日号**。
10. **格高固定 52px**（`GridView.count(mainAxisExtent: 52)`）⇒ 6 行 = 312px，避免在 flutter_test 默认 800×600 窗口里溢出。

- [x] **Step 1: 写失败测试**

```dart
// packages/core_data/test/calendar_summary_test.dart
import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  test('徽标按形状区分：全完成 ✓ / 有未完成 ● / 全空 ○ / 未来预排 ▸', () {
    expect(const CalendarDaySummary(date: '2026-11-07').badge, '○');
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 3,
        planTotal: 3,
      ).badge,
      '✓',
    );
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 2,
        planTotal: 3,
      ).badge,
      '●',
    );
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 0,
        planTotal: 2,
        future: true,
      ).badge,
      '▸',
    );
  });

  test('未来预排徽标优先于完成态', () {
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 3,
        planTotal: 3,
        future: true,
      ).badge,
      '▸',
    );
  });
}
```

```dart
// apps/desktop/test/calendar_month_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/core_data.dart';
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/widgets/calendar_month_view.dart';

void main() {
  testWidgets('月历渲染 42 格并按形状显示徽标', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: <CalendarDaySummary>[
              CalendarDaySummary(
                date: '2026-11-07',
                planDone: 2,
                planTotal: 3,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('2026-11'), findsOneWidget);
    expect(find.text('●'), findsOneWidget);
    // 补白格也会渲染日号（12-07），所以必须按 key 定位，否则 '7' 会命中 2 个。
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-11-07')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
    // 日号不补零：'07' 不应出现。
    expect(find.text('07'), findsNothing);
  });

  testWidgets('网格恒为 42 格', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: const <CalendarDaySummary>[],
          ),
        ),
      ),
    );
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('month-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 42);
  });

  testWidgets('点某天回调该天日期', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: const <CalendarDaySummary>[],
            onPickDay: (date) => picked = date,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('day-2026-11-07')));
    await tester.pump();
    expect(picked, '2026-11-07');
  });

  testWidgets('今天描边用墨色 2px', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarMonthView(
            month: '2026-11',
            days: const <CalendarDaySummary>[],
            today: '2026-11-07',
          ),
        ),
      ),
    );
    final cell = find.byKey(const ValueKey('day-2026-11-07'));
    expect(cell, findsOneWidget);
    final box = tester.widget<Container>(
      find.descendant(of: cell, matching: find.byType(Container)).first,
    );
    final border = (box.decoration! as BoxDecoration).border!;
    expect(border.top.color, AppTokens.ink);
    expect(border.top.width, 2);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_data
& 'F:\soft\flutter\flutter\bin\dart.bat' test test\calendar_summary_test.dart
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\calendar_month_view_test.dart
```
Expected: 两处 FAIL（`Undefined name 'CalendarDaySummary'` / URI 不存在）。

- [x] **Step 3: 写实现**

`packages/core_data/lib/src/calendar_summary.dart`：

```dart
/// 一天在月历格里的摘要（spec §8.1 的三层信息）。
final class CalendarDaySummary {
  /// 创建一天摘要。
  const CalendarDaySummary({
    required this.date,
    this.planDone = 0,
    this.planTotal = 0,
    this.habitDone = 0,
    this.habitTotal = 0,
    this.moodAverage,
    this.moodFailed = false,
    this.future = false,
  });

  /// 日历日。
  final String date;

  /// 当天完成数。
  final int planDone;

  /// 当天计划总数（不含 cancelled）。
  final int planTotal;

  /// 当天打卡完成数。
  final int habitDone;

  /// 当天应打卡总数。
  final int habitTotal;

  /// 当天心态八维均值（全 NULL 时为 null）。
  final double? moodAverage;

  /// 当天是否「今天没打分」。
  final bool moodFailed;

  /// 是否未来日期（未来只可预排）。
  final bool future;

  /// 形状徽标（不只靠颜色）。
  ///
  /// `✓` 全完成 · `●` 有未完成 · `○` 完全空白 · `▸` 未来带排期。
  String get badge {
    if (future && planTotal > 0) {
      return '▸';
    }
    if (planTotal == 0 && habitTotal == 0 && moodAverage == null &&
        !moodFailed) {
      return '○';
    }
    if (planTotal > 0 && planDone == planTotal) {
      return '✓';
    }
    return '●';
  }
}

/// 一个月历月的摘要。
final class CalendarMonthSummary {
  /// 创建月度摘要。
  const CalendarMonthSummary({required this.month, required this.days});

  /// 月份 `YYYY-MM`。
  final String month;

  /// 逐日摘要。
  final List<CalendarDaySummary> days;
}
```

`packages/core_data/lib/src/repositories.dart` 追加三个方法（**只加查询，不动 schema**）：

```dart
  /// 列出日期区间内的计划条目（含两端，按日期 + 创建时间排序）。
  ///
  /// 走 `idx_plan_item_date_status`，供月历**一次**取 42 天，禁止按格子 N+1。
  Future<List<PlanItemData>> listRange(String startDate, String endDate) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return (_db.select(_db.planItem)
          ..where(
            (t) =>
                t.date.isBetweenValues(startDate, endDate) &
                t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($PlanItemTable)>[
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }
```

```dart
  /// 列出日期区间内的每日日志（含两端，按日期升序）。
  Future<List<DayLogData>> listRange(String startDate, String endDate) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return (_db.select(_db.dayLog)
          ..where(
            (t) =>
                t.date.isBetweenValues(startDate, endDate) &
                t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($DayLogTable)>[
            (t) => OrderingTerm(expression: t.date),
          ]))
        .get();
  }
```

```dart
  /// 列出日期区间内的习惯打卡记录（含两端，按日期 + 创建时间升序）。
  Future<List<HabitCheckinData>> listCheckinsRange(
    String startDate,
    String endDate,
  ) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return (_db.select(_db.habitCheckin)
          ..where(
            (t) =>
                t.date.isBetweenValues(startDate, endDate) &
                t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($HabitCheckinTable)>[
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }
```

`packages/core_data/lib/core_data.dart` 追加 `export 'src/calendar_summary.dart';`。

`apps/desktop/lib/src/widgets/calendar_month_view.dart`：

```dart
import 'package:flutter/material.dart';

import 'package:core_data/core_data.dart';

import '../theme/app_tokens.dart';

/// 月历网格（spec §8.1）。
///
/// 每格三层信息：完成度底色 · 打卡热力点 · 心态迷你条 + 形状徽标。
class CalendarMonthView extends StatelessWidget {
  /// 创建月历。
  const CalendarMonthView({
    super.key,
    required this.month,
    required this.days,
    this.today,
    this.onPickDay,
  });

  /// 月份 `YYYY-MM`。
  final String month;

  /// 逐日摘要。
  final List<CalendarDaySummary> days;

  /// 今天（用于描边）。
  final String? today;

  /// 点某天的回调。
  final void Function(String date)? onPickDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byDate = <String, CalendarDaySummary>{
      for (final day in days) day.date: day,
    };
    final grid = buildMonthGrid(month, today: today ?? '');
    final pick = onPickDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(month, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in const <String>['一', '二', '三', '四', '五', '六', '日'])
              Expanded(
                child: Center(
                  child: Text(label, style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
        GridView.count(
          key: const ValueKey('month-grid'),
          crossAxisCount: 7,
          mainAxisExtent: 52,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final cell in grid)
              _DayCell(
                key: ValueKey('day-${cell.date}'),
                cell: cell,
                summary: byDate[cell.date],
                onTap: pick == null ? null : () => pick(cell.date),
              ),
          ],
        ),
      ],
    );
  }
}

/// 日号（不补零）：`2026-11-07` → `7`。
String _dayNumber(String date) {
  final parsed = parseIsoDate(date);
  return parsed == null ? date : parsed.day.toString();
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.cell,
    required this.summary,
    required this.onTap,
  });

  final CalendarCell cell;
  final CalendarDaySummary? summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = summary;
    final ratio = (day == null || day.planTotal == 0)
        ? 0.0
        : day.planDone / day.planTotal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: cell.isToday ? AppTokens.ink : AppTokens.hairStrong,
            width: cell.isToday ? 2 : 1,
          ),
          color: day == null ? null : AppTokens.inkWash.withValues(alpha: ratio),
        ),
        child: Column(
          children: [
            Text(
              _dayNumber(cell.date),
              style: theme.textTheme.labelLarge?.copyWith(
                color: cell.inMonth ? AppTokens.ink : AppTokens.faint,
              ),
            ),
            if (day != null)
              Text(
                day.badge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTokens.meta,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

`apps/desktop/lib/src/providers.dart` 追加：

```dart
/// 某个月的日历摘要（月历用；一次查区间，禁止按格子 N+1）。
final calendarMonthProvider =
    FutureProvider.family<CalendarMonthSummary, String>((ref, month) async {
  final repos = ref.watch(repositoriesProvider);
  final todayIso = ref.watch(todayProvider);
  final parts = month.split('-');
  final first = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  final last = DateTime(first.year, first.month + 1, 0);
  final start = isoDate(first);
  final end = isoDate(last);

  final items = await repos.planItem.listRange(start, end);
  final checkins = await repos.habit.listCheckinsRange(start, end);
  final logs = await repos.dayLog.listRange(start, end);
  final habits = await repos.habit.listActive();

  final byDate = <String, CalendarDaySummary>{};
  for (var day = first; !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1)) {
    final date = isoDate(day);
    byDate[date] = CalendarDaySummary(
      date: date,
      future: date.compareTo(todayIso) > 0,
    );
  }

  for (final item in items) {
    final summary = byDate[item.date];
    if (summary == null || item.status == PlanStatus.cancelled.code) {
      continue;
    }
    byDate[item.date] = CalendarDaySummary(
      date: item.date,
      planDone:
          summary.planDone +
          (item.status == PlanStatus.done.code ? 1 : 0),
      planTotal: summary.planTotal + 1,
      habitDone: summary.habitDone,
      habitTotal: summary.habitTotal,
      moodAverage: summary.moodAverage,
      moodFailed: summary.moodFailed,
      future: summary.future,
    );
  }

  for (final checkin in checkins) {
    final summary = byDate[checkin.date];
    if (summary == null) {
      continue;
    }
    byDate[checkin.date] = CalendarDaySummary(
      date: checkin.date,
      planDone: summary.planDone,
      planTotal: summary.planTotal,
      habitDone:
          summary.habitDone +
          (checkin.status == CheckinStatus.done.code ? 1 : 0),
      habitTotal: summary.habitTotal,
      moodAverage: summary.moodAverage,
      moodFailed: summary.moodFailed,
      future: summary.future,
    );
  }

  for (final log in logs) {
    final summary = byDate[log.date];
    if (summary == null) {
      continue;
    }
    final scores = <int?>[
      log.mood1,
      log.mood2,
      log.mood3,
      log.mood4,
      log.mood5,
      log.mood6,
      log.mood7,
      log.mood8,
    ].whereType<int>().toList(growable: false);
    byDate[log.date] = CalendarDaySummary(
      date: log.date,
      planDone: summary.planDone,
      planTotal: summary.planTotal,
      habitDone: summary.habitDone,
      habitTotal: summary.habitTotal,
      moodAverage: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length,
      moodFailed: log.moodFailed == 1,
      future: summary.future,
    );
  }

  for (final habit in habits) {
    for (var day = first; !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final date = isoDate(day);
      final summary = byDate[date];
      if (summary == null ||
          !HabitRepository.isScheduledFor(habit, date) ||
          habit.startDate.compareTo(date) > 0) {
        continue;
      }
      byDate[date] = CalendarDaySummary(
        date: date,
        planDone: summary.planDone,
        planTotal: summary.planTotal,
        habitDone: summary.habitDone,
        habitTotal: summary.habitTotal + 1,
        moodAverage: summary.moodAverage,
        moodFailed: summary.moodFailed,
        future: summary.future,
      );
    }
  }

  return CalendarMonthSummary(
    month: month,
    days: byDate.values.toList(growable: false),
  );
});
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\packages\core_data
& 'F:\soft\flutter\flutter\bin\dart.bat' test
& 'F:\soft\flutter\flutter\bin\dart.bat' analyze
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: 新用例 PASS；全量绿；analyze 逐字 `No issues found!`（error/warning/info 全 0）。

门禁口径：

- `packages\core_data`：目标测试 `test\calendar_summary_test.dart` **2 例**；全量用例数 = 实施前基线 **+2**。
- `apps\desktop`：目标测试 `test\calendar_month_view_test.dart` **4 例**；全量用例数 = 实施前基线 **+92** 加本次新增用例数。
- 文件规范：LF、无 BOM、无 `print(`、无 `[\x00-\x08]` 控制字符。

- [x] **Step 5: 证据落盘**

`packages\core_data\lib\src\calendar_summary.dart` + `apps\desktop\lib\src\widgets\calendar_month_view.dart` + 两个测试文件存在且全绿。

---

## Task 14: `HabitCheckinStrip` —— 吸底打卡卡带

**Files:**
- Create: `apps/desktop/lib/src/widgets/habit_checkin_strip.dart`
- Modify: `apps/desktop/lib/src/providers_p1.dart`（`habitsForTodayProvider` / `habitCheckinsProvider` 改读 `selectedDateProvider`）
- Test: `apps/desktop/test/habit_checkin_strip_test.dart`

**Interfaces:**
- Consumes: `habitsForTodayProvider` / `habitCheckinsProvider`（`providers_p1.dart`）、`HabitRepository.upsertCheckin` / `deleteCheckin`
- Produces:
  - `class HabitCheckinStrip extends ConsumerWidget { const HabitCheckinStrip({super.key, this.onChecked}); void Function(String habitName)? onChecked; }`
  - 三个占位态文案常量（供测试直接引用，测试里**不复制字面量**）：
    `static const String emptyLabel` / `loadingLabel` / `errorLabel`

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/habit_checkin_strip_test.dart
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（Riverpod 3.5.0 起 flutter_riverpod.dart 不再带它），
// 夹具签名 `List<Override> extra` 需要这条 import，缺它直接编译不过。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/providers.dart';
import 'package:practilog/src/providers_p1.dart';
import 'package:practilog/src/widgets/habit_checkin_strip.dart';

const String _today = '2026-11-09';
const String _tomorrow = '2026-11-10';

/// 卡带夹具：内存真库 + 真仓储 + 可切日的 ProviderContainer。
final class _Harness {
  _Harness._(this.db, this.repos, this.container);

  final PractiLogDatabase db;
  final PractiLogRepositories repos;
  final ProviderContainer container;

  /// 建夹具；`extra` 用来把 provider 钉成 loading 等特定状态。
  ///
  /// `selectedDateProvider` 是 StateProvider，用 `overrideWith` 定初值，
  /// 用例内再改 state 即可切日（写法同 `date_bar_test.dart` / `selected_date_test.dart`）。
  static _Harness create({List<Override> extra = const <Override>[]}) {
    final db = openInMemoryPractiLogDatabase();
    final repos = PractiLogRepositories(db, deviceId: 'strip-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
        ...extra,
      ],
    );
    // addTearDown 按 LIFO 执行：必须**先登记 db.close、后登记 container.dispose**，
    // 实际才轮到「先销毁容器（切断 drift 流订阅）→ 再关库」。
    // 反序会永久挂起：容器仍持有 habitCheckinsProvider 的 drift 流订阅时，
    // await db.close() 永远等不到流收尾，且 --timeout 对 tearDown 阶段无效。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(db, repos, container);
  }

  /// 挂上卡带；`onChecked` 用于断言打卡回调。
  Future<void> mount(WidgetTester tester, {void Function(String)? onChecked}) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: HabitCheckinStrip(onChecked: onChecked)),
        ),
      ),
    );
  }
}

/// 把上一轮异步（drift 流查询、provider 重算、写库）全部推完。
///
/// 刻意**不用** `pumpAndSettle`：加载态可能是无限重复动画，
/// `pumpAndSettle` 永远等不到稳定，会一路挂到超时（同 `p1_e2e_test.dart`）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：drift 在 StreamProvider 被 dispose 时会排一个 0 长度 timer，
/// 框架在 tearDown **之前**就检查 pending timer ⇒ 必须在用例体内跑完这帧。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 建一个从 2026-11-01 起每天排程的习惯，返回其 id。
Future<String> _addDailyHabit(_Harness harness, String name) {
  return harness.repos.habit.create(
    name: name,
    scheduleType: 'daily',
    startDate: '2026-11-01',
  );
}

void main() {
  testWidgets('加载态不得谎报空态：loading / 空态 / 失败是三套互斥文案', (tester) async {
    // 真实 drift 查询可能只靠微任务就完成 ⇒ 「靠首帧时序断言 loading」不可靠，
    // 直接把习惯列表 provider 钉成 AsyncLoading 才是确定性判据。
    final harness = _Harness.create(
      extra: <Override>[
        habitsForTodayProvider.overrideWithValue(
          const AsyncLoading<List<HabitData>>(),
        ),
      ],
    );

    await harness.mount(tester);

    expect(find.text(HabitCheckinStrip.loadingLabel), findsOneWidget);
    expect(find.text(HabitCheckinStrip.emptyLabel), findsNothing);
    expect(find.text(HabitCheckinStrip.errorLabel), findsNothing);
    await _flushTimers(tester);
  });

  testWidgets('逐个渲染当天待打卡习惯：未打卡 ○、已打卡 ✓', (tester) async {
    final harness = _Harness.create();
    await _addDailyHabit(harness, '晨间写作');
    final eveningId = await _addDailyHabit(harness, '晚间复盘');
    await harness.repos.habit.upsertCheckin(
      habitId: eveningId,
      date: _today,
      status: CheckinStatus.done,
    );

    await harness.mount(tester);
    await _settle(tester);

    expect(find.text('晨间写作'), findsOneWidget);
    expect(find.text('晚间复盘'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
    expect(find.text('○'), findsOneWidget);
    await _flushTimers(tester);
  });

  testWidgets('点一下即把所选日写为 done，并通过 onChecked 告知习惯名', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');
    final tapped = <String>[];

    await harness.mount(tester, onChecked: tapped.add);
    await _settle(tester);
    expect(find.text('○'), findsOneWidget);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);

    final checkin = await harness.repos.habit.findCheckin(habitId, _today);
    expect(checkin, isNotNull);
    expect(checkin!.status, CheckinStatus.done.code);
    expect(tapped, <String>['晨间写作']);
    expect(find.text('✓'), findsOneWidget);
    await _flushTimers(tester);
  });

  testWidgets('已打卡再点 = 撤销（软删），且回调不再触发', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');
    final tapped = <String>[];

    await harness.mount(tester, onChecked: tapped.add);
    await _settle(tester);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    await tester.tap(find.text('晨间写作'));
    await _settle(tester);

    expect(await harness.repos.habit.findCheckin(habitId, _today), isNull);
    expect(tapped, <String>['晨间写作']);
    expect(find.text('○'), findsOneWidget);
    // 软删后 live 查询看不到该行（墓碑仍占着 UNIQUE(habit_id,date) 槽位，见下一例）。
    expect(
      await harness.repos.habit.listCheckinsRange(_today, _today),
      isEmpty,
    );
    await _flushTimers(tester);
  });

  testWidgets('撤销后再打卡复用同一 (habit_id,date) 行，不新增第二条', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');
    final tapped = <String>[];

    await harness.mount(tester, onChecked: tapped.add);
    await _settle(tester);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    final afterFirst = await harness.repos.habit.findCheckin(habitId, _today);
    final firstId = afterFirst!.id;

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    await tester.tap(find.text('晨间写作'));
    await _settle(tester);

    final again = await harness.repos.habit.findCheckin(habitId, _today);
    expect(again, isNotNull);
    expect(again!.status, CheckinStatus.done.code);
    // id 不变 ⇒ 复用同一行（撤销再打卡不会破 UNIQUE，也不留双行）。
    expect(again.id, firstId);
    expect(tapped, <String>['晨间写作', '晨间写作']);
    await _flushTimers(tester);
  });

  testWidgets('切换所选日后卡带跟随所选日（钉死 provider 改读 selectedDate）', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');

    await harness.mount(tester);
    await _settle(tester);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    expect(find.text('✓'), findsOneWidget);

    harness.container.read(selectedDateProvider.notifier).state = _tomorrow;
    await _settle(tester);

    // 所选日换成明天：习惯仍在排程，但明天没有打卡记录。
    expect(find.text('晨间写作'), findsOneWidget);
    expect(find.text('✓'), findsNothing);
    expect(find.text('○'), findsOneWidget);
    expect(
      await harness.repos.habit.findCheckin(habitId, _tomorrow),
      isNull,
    );
    // 今天的记录不受影响 ⇒ 查询按「所选日」而非「今天」。
    expect(
      await harness.repos.habit.findCheckin(habitId, _today),
      isNotNull,
    );
    await _flushTimers(tester);
  });
}
```

> 打卡落库 / 撤销 / 切日在 widget 层用**内存真库** E2E 覆盖（上面 6 例）；
> 真机手感（吸底位置、不遮挡列表）仍放 Task 17 场景 1 验收。
>
> 实现须把三套状态文案作为 `static const String` 暴露在 `HabitCheckinStrip` 上
> （`emptyLabel` / `loadingLabel` / `errorLabel`），测试直接引用常量而不是复制字符串
> —— 文案改动只该红在真正该红的地方。

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\habit_checkin_strip_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

```dart
// apps/desktop/lib/src/widgets/habit_checkin_strip.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// HabitData / HabitCheckinData 是 drift 生成类，只在 core_db 提供；
// 写成 core_data 会触 unused_import（error 级）+ 类型找不到。
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';

import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_tokens.dart';

/// 习惯打卡吸底卡带。
///
/// 位置固定在视口底部（Windows 为右下吸底卡），**不遮挡列表**。
/// 这是全产品最高频动作，不允许需要向下翻才找到。
class HabitCheckinStrip extends ConsumerWidget {
  /// 创建吸底卡带。
  const HabitCheckinStrip({super.key, this.onChecked});

  /// 打卡成功后的回调（便于 Undo 接线）。
  final void Function(String habitName)? onChecked;

  /// 所选日没有待打卡习惯时的占位文案。
  static const String emptyLabel = '今天没有待打卡的习惯';

  /// 习惯清单或打卡流尚未就绪时的提示文案。
  static const String loadingLabel = '正在加载打卡状态…';

  /// 任一异步数据加载失败时的提示文案。
  static const String errorLabel = '打卡状态加载失败，请稍后重试';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 两个 provider 都返回 AsyncValue：加载 / 空 / 错误是三种不同状态，
    // 不允许把加载态和错误态都渲染成空态（那是谎报）。
    final habitsAsync = ref.watch(habitsForTodayProvider);
    final checkinsAsync = ref.watch(habitCheckinsProvider);
    final date = ref.watch(selectedDateProvider);

    if (habitsAsync.hasError || checkinsAsync.hasError) {
      return _dockCard(context, label: errorLabel);
    }
    if (!habitsAsync.hasValue || !checkinsAsync.hasValue) {
      return _dockCard(context, label: loadingLabel);
    }

    final habits = habitsAsync.value!;
    if (habits.isEmpty) {
      return _dockCard(context, label: emptyLabel);
    }

    final doneIds = <String>{
      for (final checkin in checkinsAsync.value!)
        if (checkin.status == CheckinStatus.done.code) checkin.habitId,
    };

    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      constraints: const BoxConstraints(minHeight: 48, maxWidth: 420),
      decoration: BoxDecoration(
        color: AppTokens.dock,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.hair, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final habit in habits)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _HabitButton(
                  habit: habit,
                  done: doneIds.contains(habit.id),
                  onTap: () async {
                    final repo = ref.read(repositoriesProvider).habit;
                    if (doneIds.contains(habit.id)) {
                      final existing = await repo.findCheckin(habit.id, date);
                      if (existing != null) {
                        await repo.deleteCheckin(existing.id);
                      }
                      return;
                    }
                    await repo.upsertCheckin(
                      habitId: habit.id,
                      date: date,
                      status: CheckinStatus.done,
                    );
                    onChecked?.call(habit.name);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 卡带占位外壳：加载 / 空 / 错误三态共用的吸底小卡。
Widget _dockCard(BuildContext context, {required String label}) {
  final theme = Theme.of(context);
  return Container(
    width: 260,
    margin: const EdgeInsets.only(right: 16, bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTokens.dock,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      border: Border.all(color: AppTokens.hair, width: 1),
    ),
    child: Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(color: AppTokens.meta),
    ),
  );
}

class _HabitButton extends StatelessWidget {
  const _HabitButton({
    required this.habit,
    required this.done,
    required this.onTap,
  });

  final HabitData habit;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: done ? AppTokens.ink : AppTokens.card,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: done ? AppTokens.ink : AppTokens.hairStrong,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                done ? '✓' : '○',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: done ? AppTokens.paper : AppTokens.meta,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                habit.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: done ? AppTokens.paper : AppTokens.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`providers_p1.dart` 同步改动（**只改这两个 provider 的体内引用，两个 provider 的名字都不改**）：

- `habitsForTodayProvider`：体内 `ref.watch(todayProvider)` 改成
  `ref.watch(selectedDateProvider)`。
- `habitCheckinsProvider`：体内 `ref.watch(todayProvider)` 改成
  `ref.watch(selectedDateProvider)`。
- 这两个 provider 各自的 doc comment 里「今天」的口径同步改写成「所选日」，
  不允许注释与行为不一致。
- 同文件的 `yesterdayProvider` 仍读 `todayProvider`，**本任务不许动**
  （它是「昨日复盘」的锚点，与所选日无关）。

> 这两个 provider **并非零消费方**：`apps\desktop\lib\src\widgets\habit_section.dart:22-23`
> 已在 `ref.watch` 它们，所以本任务的改读会把 `HabitSection` 的日期口径一并从「今天」
> 切到「所选日」。这是**可接受的连带**而非回归：`selectedDateProvider` 的初值就是
> `ref.watch(todayProvider)`（`providers.dart:29-30`，其 doc 注释明确「测试里 override
> `todayProvider` 依然生效」），用户不主动切日时两者恒等，故既有 `date_bar_test` /
> `selected_date_test` / `p1_e2e_test` 等只 override `todayProvider` 的用例口径不变、照旧全绿。
> 上面第 6 例专门钉住改读本身 —— 若 provider 忘改，切日后卡带仍显示今天的 `✓`，当场变红。

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\habit_checkin_strip_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: PASS —— 目标文件 **6 例全绿**；desktop 全量由 **96 例增至 102 例**（新增 6 例、零回退）；
`flutter analyze` 逐字输出 `No issues found!`（error / warning / info 全为 0）。
core_data 本任务不涉及，但控制器复跑一次以证明跨包零回退（基线 **122**）。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\habit_checkin_strip.dart` 与
`apps\desktop\test\habit_checkin_strip_test.dart` 存在且全绿；门禁三件套日志、
`pass=+102` 与 `No issues found!` 的逐字摘录落盘到
`.superpowers\sdd\2026-11-07-b1-flutter-implementation\reports\`。

---

## Task 15: `DayTimeline` 三段骨架 + 今日页重排

**Files:**
- Create: `apps/desktop/lib/src/widgets/day_timeline.dart`
- Modify: `apps/desktop/lib/src/pages/today_page.dart`
- Modify: `apps/desktop/lib/src/widgets/mood_section.dart`
- Modify: `apps/desktop/lib/src/widgets/review_section.dart`
- Modify: `apps/desktop/lib/src/widgets/standup_section.dart`（仅遗留① 的一处 12px）
- Modify: `apps/desktop/lib/src/theme/app_tokens.dart`（新增 `<1280px` 窄断点两值，见 R9 J4）
- Modify: `apps/desktop/test/p1_e2e_test.dart`（仅 R9 J8 的两处连带改动）
- Test: `apps/desktop/test/day_timeline_test.dart`
- 禁改: `apps/desktop/lib/src/widgets/section_card.dart`、`.../habit_checkin_strip.dart`、`.../date_bar.dart`、`.../section_header.dart`、`.../habit_section.dart`（文件保留、只是不再出现在今日页）、`.../loop_progress_ring.dart`、`.../plan_section.dart`、`.../outcome_composer.dart`、`.../priority_chips.dart`、`apps/desktop/lib/src/providers.dart`、`apps/desktop/lib/main.dart`、`packages/**`
- 基线: `reports/task15-forbidden-baseline.txt`——`B1BASE2` 前缀 45 条 forbidden（由 `reports/task14-forbidden-baseline-v2.txt` 的 51 条逐条沿用，其中 `app_tokens.dart` 与 `p1_e2e_test.dart` 因 J4/J8 转入本轮写集，`lib/main.dart` 与 `test/habit_checkin_strip_test.dart` 为本轮新增禁改行）；6 条 `WRITESET` 为本轮 6 个 Modify 文件的基线指纹（`path bytes sha16`）；2 条 `ABSENT` = 两个 Create 文件当前不存在

> **Task 3 评审遗留项（本任务一并闭合，见 `task-15-brief.md` 附加项）**：
> Task 3 遗留处理：① 两处 `fontSize: 10` 改 12px——实测在 `apps/desktop/lib/src/pages/today_page.dart:457`（`_MiniBadge`）与 `apps/desktop/lib/src/widgets/standup_section.dart:190`；计划原文写的 `standup_section.dart:404` 属行号漂移（该文件仅 226 行，`:404` 不存在），`fontSize: 10` 在 `apps\desktop\lib` 下实测**仅这两处**（R9 J11）。
> ② 今日页外层内边距 `EdgeInsets` 与三段间距 `gapSec`（`TOKENS.md:260/262`）——**本轮裁定见 R9 J10**：`ListView(padding: EdgeInsets.fromLTRB(26, 6, 26, 96))` + 段间 `AppTokens.gapSec`；
> ③ 「今日页」与「计划页」合并的判据（`_MiniBadge` / 午段归属）——**本轮裁定见 R9 J13**：`_AddPlanItemBar` 保持紧随 `_PlanBlock`（= 晨段末尾），**不**移到晨段顶部、也不改成收件箱子段（那属 B4）；`_MiniBadge` 保留，只按 J11 把字号 10 → 12。

**Interfaces:**
- Consumes: `SectionHeader`（Task 7）、`LoopProgressRing`（Task 10）、`DateBar`（Task 11）、`HabitCheckinStrip`（Task 14）、`DurationChips` / `DomainChips`（Task 8）
- Produces: `DayTimeline({required List<Widget> children, super.key})` 与 `TimelineSection({required String label, required Widget child, bool hasGap = false, String? gapLabel, Key? key})`；三个赭石纪律纯函数 `BoxDecoration tlNodeDecoration({required bool hasGap})` / `String tlNodeLabel({required bool hasGap, String? gapLabel})` / `Color tlNodeTextColor({required bool hasGap})`；断点纯函数 `tlNarrowBreakpoint` / `tlWidthFor(double width)` / `tlGapFor(double width)`。

- [x] **Step 1: 写失败测试**

在 `apps/desktop/test/day_timeline_test.dart` 写 **5 个**渲染与纯函数判据（骨架铁律 + 赭石纪律 + 双通道 + 断点边界；R9 J12 说明为何由 1 例扩为 5 例）：

```dart
// apps/desktop/test/day_timeline_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog_desktop/src/theme/app_tokens.dart';
import 'package:practilog_desktop/src/widgets/day_timeline.dart';

Widget _host(double width, Widget child) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: Scaffold(body: SizedBox(width: width, child: child)),
      ),
    );

const DayTimeline _threeSections = DayTimeline(
  sections: [
    TimelineSection(label: '晨 · 定计划', child: SizedBox(height: 30)),
    TimelineSection(label: '午 · 执行与打卡', child: SizedBox(height: 30)),
    TimelineSection(label: '晚 · 复盘与心态', child: SizedBox(height: 30)),
  ],
);

void main() {
  testWidgets('三段全部渲染、无折叠分支，段间各一个 gapSec（骨架铁律 + 遗留②）', (tester) async {
    await tester.pumpWidget(_host(1400, _threeSections));
    expect(find.text('晨 · 定计划'), findsOneWidget);
    expect(find.text('午 · 执行与打卡'), findsOneWidget);
    expect(find.text('晚 · 复盘与心态'), findsOneWidget);
    // 三段之间各插一个 gapSec=22 的间距：i > 0 才插 ⇒ 恰好 2 个
    expect(
      find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.height == AppTokens.gapSec),
      findsNWidgets(2),
    );
  });

  test('节点形状与赭石纪律：圆点，且只有缺口态允许赭石（TOKENS.md:300/328）', () {
    final closed = tlNodeDecoration(hasGap: false);
    final gap = tlNodeDecoration(hasGap: true);
    expect(closed.shape, BoxShape.circle);
    expect(closed.color, Colors.transparent);
    expect(closed.border!.top.color, AppTokens.hairStrong);
    expect(gap.shape, BoxShape.circle);
    expect(gap.color, AppTokens.accent);
    expect(gap.border!.top.color, AppTokens.accent);
    // 反例：非缺口态的底色与描边都不得是赭石（§7:306-307 禁装饰性赭石色块）
    expect(closed.color, isNot(AppTokens.accent));
    expect(closed.border!.top.color, isNot(AppTokens.accent));
  });

  test('节点双通道：文字与形状同时存在（TOKENS.md:254-255）', () {
    expect(tlNodeLabel(hasGap: false, gapLabel: null), '✓ 已闭合');
    expect(tlNodeLabel(hasGap: true, gapLabel: null), '▸ 有缺口');
    expect(tlNodeLabel(hasGap: true, gapLabel: '缺晚间复盘'), '缺晚间复盘');
    expect(tlNodeTextColor(hasGap: false), AppTokens.meta);
    expect(tlNodeTextColor(hasGap: true), AppTokens.accentInk);
  });

  test('窄断点纯函数：1280 为界（TOKENS.md:238-239）', () {
    expect(tlWidthFor(1280), AppTokens.tlWidth);
    expect(tlGapFor(1280), AppTokens.tlGap);
    expect(tlWidthFor(1279.9), AppTokens.tlWidthNarrow);
    expect(tlGapFor(1279.9), AppTokens.tlGapNarrow);
    expect(tlNarrowBreakpoint, 1280);
  });

  testWidgets('节点 10×10 与 ≥12px 文字共存；窄视口左栏 52+10 贯通（§2.2 硬底线）', (tester) async {
    Widget one(double w) => _host(
          w,
          DayTimeline(
            sections: [
              TimelineSection(
                label: '晨 · 定计划',
                child: const SizedBox(
                  key: ValueKey<String>('probe'),
                  width: 20,
                  height: 30,
                ),
              ),
            ],
          ),
        );
    await tester.pumpWidget(one(1400));
    expect(tester.getSize(find.byKey(const ValueKey<String>('tl-node'))),
        const Size(10, 10));
    expect(
        tester.widget<Text>(find.text('晨 · 定计划')).style?.fontSize, greaterThanOrEqualTo(12));
    expect(tester.getTopLeft(find.byKey(const ValueKey<String>('probe'))).dx,
        AppTokens.tlWidth + AppTokens.tlGap);
    await tester.pumpWidget(one(600));
    expect(tester.getTopLeft(find.byKey(const ValueKey<String>('probe'))).dx,
        AppTokens.tlWidthNarrow + AppTokens.tlGapNarrow);
  });
}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\day_timeline_test.dart
```
Expected: FAIL —— URI 不存在。

- [x] **Step 3: 写实现**

先在 `apps/desktop/lib/src/theme/app_tokens.dart` 补两个窄断点值。`tlWidth = 64`（`:70`）与 `tlGap = 12`（`:73`）**已存在，不要重复添加、不要改值**；只在其后（`gapTl` 之后、`shadowFloat` 之前）追加两行（R9 J4，取值来自 `design-demos/TOKENS.md:238-239`，本轮**不改口径文件**）：

```dart
  /// 时间轴左栏宽度的窄断点值（`<1280px`，`design-demos/TOKENS.md:238`）。
  static const double tlWidthNarrow = 52;

  /// 时间轴左栏间距的窄断点值（`<1280px`，`design-demos/TOKENS.md:239`）。
  static const double tlGapNarrow = 10;
```

然后新建 `apps/desktop/lib/src/widgets/day_timeline.dart`：
```dart
// apps/desktop/lib/src/widgets/day_timeline.dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// `TOKENS.md:238-239` 的 `<1280px` 断点边界。
const double tlNarrowBreakpoint = 1280;

/// 时间轴左栏宽度：窄视口 52px，宽视口 64px。
double tlWidthFor(double width) =>
    width < tlNarrowBreakpoint ? AppTokens.tlWidthNarrow : AppTokens.tlWidth;

/// 时间轴左栏与内容的间距：窄视口 10px，宽视口 12px。
double tlGapFor(double width) =>
    width < tlNarrowBreakpoint ? AppTokens.tlGapNarrow : AppTokens.tlGap;

/// 时段节点形状与赭石纪律（`TOKENS.md:300`、`§6:328`、`§7:306-307`）：
/// 两态都是**圆点**，**只有「有缺口」态用赭石**，非缺口态一律透明底 + 描边。
BoxDecoration tlNodeDecoration({required bool hasGap}) => BoxDecoration(
      shape: BoxShape.circle,
      color: hasGap ? AppTokens.accent : Colors.transparent,
      border: Border.all(
        color: hasGap ? AppTokens.accent : AppTokens.hairStrong,
        width: 1.5,
      ),
    );

/// 节点下方文字通道（`TOKENS.md:254-255`，12px 允许换行）。
String tlNodeLabel({required bool hasGap, String? gapLabel}) =>
    gapLabel ?? (hasGap ? '▸ 有缺口' : '✓ 已闭合');

/// 节点文字颜色：缺口态用赭石**文字**（`accentInk` 保证对比度），其余用次级色。
Color tlNodeTextColor({required bool hasGap}) =>
    hasGap ? AppTokens.accentInk : AppTokens.meta;

/// 一天时间轴上的一个时段（晨/午/晚）：左栏 = 节点 + 段名，右栏 = 内容。
class TimelineSection extends StatelessWidget {
  /// 创建时段。
  const TimelineSection({
    required this.label,
    required this.child,
    this.hasGap = false,
    this.gapLabel,
    super.key,
  });

  /// 段名（≥12px，允许换行，**不用** `SectionHeader`，见 R9 J3）。
  final String label;

  /// 该时段是否存在缺口。
  final bool hasGap;

  /// 缺口说明（可空）：有缺口时优先显示它，否则显示默认缺口文字。
  final String? gapLabel;

  /// 时段内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Row(
      key: ValueKey<String>('tl-section-$label'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: tlWidthFor(width),
          child: Column(
            children: [
              Container(
                key: const ValueKey<String>('tl-node'),
                width: 10,
                height: 10,
                decoration: tlNodeDecoration(hasGap: hasGap),
              ),
              const SizedBox(height: 4),
              Text(
                tlNodeLabel(hasGap: hasGap, gapLabel: gapLabel),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: tlNodeTextColor(hasGap: hasGap),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(width: tlGapFor(width)),
        Expanded(child: child),
      ],
    );
  }
}

/// 今日页三段骨架：三段**同时渲染、永不折叠**（骨架铁律）。
class DayTimeline extends StatelessWidget {
  /// 创建三段骨架，段间用 `AppTokens.gapSec`（R9 J10）。
  const DayTimeline({required this.sections, super.key});

  /// 时段列表。
  final List<TimelineSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.gapSec),
          sections[i],
        ],
      ],
    );
  }
}
```

`today_page.dart` 的 `_TodayBody.build` 改为：**只替换 `:109-134` 的 `return Column(...)` 整段表达式**（R9 J9）。`:100-108` 的 `minimal` / `displayMode` 局部变量、`:137-140` 的 `// TODO` + `_jumpTo` 空实现**原样保留**（TODO 注释改指 `Task 17`，见 M15-3）。

三处**不能照契约旧稿抄**（旧稿不可编译 / 会抛 RenderFlex，R9 J15 / J16 / J10）：

- `DateBar` 用**无参 const 构造** `const DateBar()`：`date_bar.dart:14` 只有 `onPickDate`，日期由组件内部自 watch（`:22` `selectedDateProvider`、`:23` `todayProvider`）。旧稿的 `DateBar(date: date, onJump: _jumpTo)` **编译不过**。
- 主内容必须包进 `Positioned.fill(...)`：`Stack` 的非定位子拿到 loose 高度约束，`Column > Expanded` 会抛 `RenderFlex children have non-zero flex but incoming height constraints are unbounded`。
- `ListView` 的 padding 写成 `EdgeInsets.only(top: 6, bottom: 96)`（现状 `:114` 是 `bottom: 12`，改 96 是给吸底的 `HabitCheckinStrip` 让位；**左右不加内边距**，页面级内距属 Task 18）。
- 午/晚两段的 `TimelineSection(...)` 参数全是 const ⇒ 写 `const TimelineSection(...)`（`prefer_const_constructors` 会报 lint）；但 `SizedBox(width: tlWidthFor(width))` **不能加 const**（函数调用进不了 const 表达式，是编译错误）。

```dart
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              const DateBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 96),
                  children: [
                    LoopProgressRing(
                      stats: ref.watch(dayStatsProvider),
                      onJump: (segment) => _jumpTo(segment),
                    ),
                    DayTimeline(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const StandupSection(),
                            _PlanBlock(
                              date: date,
                              minimal: minimal,
                              displayMode: displayMode,
                            ),
                            _AddPlanItemBar(date: date),
                          ],
                        ),
                        const HabitSection(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ReviewSection(),
                            const MoodSection(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: HabitCheckinStrip(),
        ),
      ],
    );
```

**连带清单**（缺一条 analyze 当场变红，R9 J14）：

- import：**保留** `today_page.dart:9`（`habit_section.dart`，午段仍渲染 `HabitSection`）、`:12`（`outcome_composer.dart`）、`:13`（`priority_chips.dart`）、`:15`（`section_card.dart`）；**新增** `import '../widgets/day_timeline.dart';` 与 `import '../widgets/habit_checkin_strip.dart';`（实测 `HabitCheckinStrip` 此前全仓未挂载，只被 `test\habit_checkin_strip_test.dart:12/:55` 引用 ⇒ Task 15 是唯一挂载点，位置由 `spec:114` 定为吸底）。
- `_AddPlanItemBar`（`today_page.dart:497`）**位置不变**（晨段末尾，紧随 `_PlanBlock`）；只把 `:558` 的 `child: const Text('添加')` 改成 `child: const Text('+ 手写一条')`，`:549` 的 `hintText: '添加计划条目…'` **不动**（R9 J13；`test/p1_e2e_test.dart:119` 的 `find.text('添加')` 同步改文案，见 Step 4 / R9 J8）。
- 字号（R9 J11）：`today_page.dart:457`（`_MiniBadge` 的 `copyWith(color: color, fontSize: 10)`）与 `standup_section.dart:190` 的 `fontSize: 10` 改为 `12`。`labelSmall` 默认 11px，必须显式 `copyWith(fontSize: 12)` 才达到 `TOKENS.md:291-292` 的「chip 12px」。

`mood_section.dart` 的打分行：把 `:237-246` 的 `Expanded(child: Slider(...))` 换成 0–10 数字格（R9 J5）。`_MoodSliderRow` 的字段名实测是 `score`（`:217`）/ `onChanged`（`:218`）——契约旧稿的 `_setScore(dimension, v)` 与 `summary.scores[...]` **都不存在**；类名与 `:141-153` 的调用点都**不动**：

```dart
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (int s = 0; s <= 10; s++)
                ChoiceChip(
                  label: Text('$s'),
                  selected: score == s,
                  onSelected: (_) => onChanged(s),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
```

`:224` 的 `rated` 与 `:225` 的 `value` 仍被后面的数字回显（`:247-255`）使用 ⇒ **不要删**（删了 `:250/:254` 就断；留着也不会触发 `unused_local_variable`）。

「今天没打分」（R9 J6）：**复用**现有「今日失守」Switch 的通路（`mood_section.dart:169-174`），与 `:133-138` 的「全部清空」同排插入，走 `setState` + `_scheduleSave(log.id)`。**不得**直写 `repo.saveMood(log.id, scores: {}, failed: true, note: '')`（旧稿会抹掉备注，签名也不符）：

```dart
                  TextButton(
                    onPressed: () {
                      setState(() => _failedRequested = true);
                      _scheduleSave(log.id);
                    },
                    child: const Text('今天没打分'),
                  ),
```

去写死强调色（R9 J7，赭石纪律）：删 `mood_section.dart:28` 的 `_accent` 常量声明与 `:96` 的 `accent: _accent,` 调用行，`:160` 改成 `color: failed ? theme.colorScheme.error : null,`；同样删 `review_section.dart:34` 的 `_accent` 与 `:125` 的 `accent: _accent,`。**不新增** `moodAccent` / `reviewAccent` token（避免第二个赭石色源）。

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\day_timeline_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: PASS —— 目标 5 例全绿；desktop 全量 **`+107`**（基线 `+102` + 本轮新增 5 例）；`flutter analyze` 逐字 `No issues found!`。`packages/core_data` 不碰不重跑（台账沿用 `+122`）。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\day_timeline.dart` 存在；`today_page.dart` 已改为三段骨架；`mood_section.dart` 不再含 `#E07A5F`。


### 契约修订 R9（Task 15 开工前控制器预检：契约块与真实源码 / 测试 / 口径逐行比对，含 6 处本轮连带改动）—— 控制器 2026-11-09 实测，实现者照此执行

**背景**：控制器按 R7/R8 的手法，在派工前把 Task 15 契约的 Step 1/2/3 代码块与 `today_page.dart`（568 行）、`mood_section.dart`（267 行）、`review_section.dart`（177 行）、`standup_section.dart`（226 行）、`app_tokens.dart`（74 行）、`section_card.dart`（85 行）、`habit_checkin_strip.dart`（169 行）、`p1_e2e_test.dart`（336 行）、`providers.dart`、`analysis_options.yaml` 与 `design-demos/TOKENS.md` 逐行比对，并把本轮 6 个 Modify 文件的基线指纹冻结进 `reports/task15-forbidden-baseline.txt`（`B1BASE2` 45 条 + 6 条 `WRITESET` + 2 条 `ABSENT`，派生自 `reports/task14-forbidden-baseline-v2.txt` 的 51 条）。**结论：契约的骨架方向正确（三段不折叠 / 节点 10×10 / 双通道 / `<1280px` 断点 / 「0 分 ≠ 没打分」），但 14 处不可编译、必红或违口径，已按裁定改写进上面的 Step 1/2/3 代码块与散文；另有 6 项契约未覆盖的真实缺陷裁定为本轮连带改动，6 项登记遗留。**

| 编号 | 契约缺陷 | 事实依据（实测） | 裁定 |
|---|---|---|---|
| J1 | Step 3 节点写死 `Container(width: 10, height: 10, color: AppTokens.accent)`——**方形色块**，且两态同色 | `TOKENS.md:300`「节点只区分有/无缺口两种形状，赭石永不作为底色」、`:328`「非缺口时段节点不用赭石填充」、`§7:306` 禁「实心赭石圆点」、`§7:307` 禁「赭石作大面积底色 / 色块装饰」 | 抽纯函数 `BoxDecoration tlNodeDecoration({required bool hasGap})`：两态 `shape: circle`；缺口态 `color: accent` + 描边 accent，非缺口态 `color: transparent` + 描边 `hairStrong`（宽 1.5）⇒ 赭石纪律可静态单测 |
| J2 | 两态无区分、节点下无文字通道 | `TOKENS.md:254-255` 允许「节点下 12px 文字通道，允许换行」 | `TimelineSection` 新增 `hasGap` / `gapLabel`；节点文字抽 `tlNodeLabel`（`✓ 已闭合` / `▸ 有缺口`，可被 `gapLabel` 覆盖）与 `tlNodeTextColor`（仅缺口态 `accentInk` 文字）⇒ 双通道成立，且**只有缺口态出现赭石** |
| J3 | 左栏 `IntrinsicHeight` + `header: Widget`（契约要传 `SectionHeader`） | `today_page.dart:1-16` 的 import 块**没有** `../widgets/section_header.dart` ⇒ 原文 `header: const SectionHeader(...)` **编译不过**；`SectionHeader` 实测含 `overflow: TextOverflow.ellipsis`，与 `TOKENS.md:297`「标签不允许 ellipsis 截断」**直接冲突**；`IntrinsicHeight` 双次布局 + `CrossAxisAlignment.stretch` 在窄栏易溢出 | 取消 `header: Widget`，改 `label` / `hasGap` / `gapLabel` 三字段；段名用 `Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, w600, AppTokens.ink)` 的居中 `Text`（≥12px 硬底线不越，允许换行）；去掉 `IntrinsicHeight`，`Row(crossAxisAlignment: start)` + `Expanded(child: child)`；`section_header.dart` 列入禁改集（其 ellipsis 冲突登记 M15-5） |
| J4 | Step 2 只补宽值 `64/12` ⇒ 契约 Step 1 用例 4「窄视口左栏 = 52+10」**无法实现** | `TOKENS.md:238-239` 已写明 `64px（<1280px → 52px）`、`12px（→ 10px）`；`app_tokens.dart:69-73` 实测只有 `tlWidth = 64`、`tlGap = 12`；`apps\desktop\lib` 下窄断点**零实现先例**；`theme_tokens_test.dart` 仅 3 例、不枚举 token 数量 ⇒ 新增 token 不碰它 | 新增 `AppTokens.tlWidthNarrow = 52` / `tlGapNarrow = 10`（值已在口径文件 ⇒ **不改 `TOKENS.md`、无口径变更**）+ 纯函数 `tlWidthFor` / `tlGapFor` / `const double tlNarrowBreakpoint = 1280`；`TimelineSection` 用 `MediaQuery.of(context).size.width`（**不用** `MediaQuery.sizeOf`，规避 SDK 版本差异）；边界判据进单测（1280 → 64/12，1279.9 → 52/10） |
| J5 | Step 3 的 mood 片段引用不存在的方法与表达式：`_setScore(dimension, v)`、`summary.scores[...]` | `mood_section.dart` 实测：状态 `final Map<MoodDimension, int> _scores = {}`（`:30`）；写值只有 `_MoodSliderRow` 的 `onChanged` / `onClear` 调用点（`:141-153`）；保存 `void _scheduleSave(int logId)`（`:179`）；`_MoodSliderRow` 定义 `:208`，`onChanged` **已是 `ValueChanged<int>`**、`Slider` 在 `:238-245` | **调用点一行不动**（签名与 `int` 语义本就正确），只把 `_MoodSliderRow.build` 内的 `Slider` 整段换成 `Wrap` + `ChoiceChip` 0–10 数字格（`onSelected: (_) => onChanged(s)`）⇒ 一次性提交、防抖不被拖动压垮、「未打分不落键」语义原样保留。契约代码块给精确 old→new 片段（R9 初稿曾把病灶归到调用点签名与「改名残留」，两处均已按实测更正） |
| J6 | 「今天没打分」契约写 `repo.saveMood(log.id, scores: {}, failed: true, note: '')`，绕过页面状态 | `mood_section.dart:165-175` 已有完整「今日失守」`Switch` 通路（`_failedRequested` + `_scheduleSave`）；`_note`（`:31`）由文本框维护 ⇒ 契约写法会把备注写成 `''`；`saveMood` 的位置参数签名（`repositories.dart:251`）也与契约写法不符 | 复用既有 Switch 通路（`setState(() => _failedRequested = true); _scheduleSave(log.id);`），**不新增写库路径**；文案仍用 `今天没打分`（spec:126/:186 明确 `mood_failed=1` 是合法状态） |
| J7 | 铁律 6 那条注引用**编造符号**；两处写死 hex 契约未处理 | `review_section.dart:29` 是 `static const int _minChars = 3;`（非 `noteMinChars`）、`:61` 是 `void _addChip(String raw)`（非 `_appendTag`）、`:45/:63` 阈值已为 3；`mood_section.dart:28` `Color(0xFFE07A5F)` 与 `review_section.dart:34` `Color(0xFF6A5ACD)` 在 `apps\desktop\lib` 其余位置**零命中** | 改正该注为实测符号；删除两常量与其调用行 `accent: _accent,`（`mood:96` / `review:125`），`mood:160` 改 `failed ? theme.colorScheme.error : null` ⇒ 回落 `SectionCard` 默认 `AppTokens.ink`（`section_card.dart:59`）。**不新增** `moodAccent`/`reviewAccent`（`TOKENS.md` 零命中 ⇒ 口径变更）；绿/红语义缺口登记 M15-4 |
| J8 | Step 4 只写 analyze + 冒烟，**未识别今日页重排会打断既有 e2e** | `p1_e2e_test.dart:119` `await tester.tap(find.text('添加'));` ⇒ 文案改 `+ 手写一条` 后必红；`:293-306` 整块以 `find.text('习惯打卡')` 为祖先找 `SectionCard` 内的 `Checkbox` 并断言 `value isTrue`，而 `HabitSection` 按契约从今日页移除、`HabitCheckinStrip` 全文**既无 `Checkbox` 也无 `习惯打卡` 文案** ⇒ 必红 | 两处 e2e 连带改动写进 Step 3：`:119` 文案改 `+ 手写一条`；`:293-306` 整块删除，打卡验收点由 `:289-291` 的**直读数据库断言**承担（`findCheckin(habitId, _date)` isNotNull + `status == CheckinStatus.done.code`）。**不**新增 `selectedDateProvider.overrideWithValue(_date)`：P1-6 的录入链路本就依赖「`todayProvider` 与默认 `selectedDateProvider` 同为今天」这一前提，override 与本轮改动无关（同 Task 14 的 R8 裁定） |
| J9 | Step 3 只说「重写 `_TodayBody.build`」，未界定可替换区间 | `today_page.dart:96-141` 实测：`date`/`mode` 在 `:96-97`、`minimal` 在 `:101`、`displayMode` 在 `:104-107`（**都在 return 之外**），`:137-140` 是 `// TODO` + `_jumpTo` 空实现 | 契约改为**只替换 `:109-134` 的 `return Column(...)` 整段表达式**，`:100-108` 与 `:137-140` 原样保留（TODO 改指 Task 17）；新表达式见下方代码块 |
| J10 | 遗留② 的页面内边距与段间距契约未给值 | `today_page.dart:114` 现为 `EdgeInsets.only(top: 6, bottom: 12)`（**左右 0**，即病灶）；`TOKENS.md:260` `--page-pad: 26px`、`:251` `--gap-top: 6px`、`:262` `--gap-sec: 22px`；`date_bar.dart:49` / `plan_page.dart:136` 均用 26 | `ListView` padding 改 `EdgeInsets.fromLTRB(26, 6, 26, 96)`（bottom 96 为吸底卡带让位，spec:114）；`DayTimeline` 段间插 `const SizedBox(height: AppTokens.gapSec)`，`i > 0` 才插 ⇒ 三段共 2 个，用例 1 以 `findsNWidgets(2)` 断言 |
| J11 | 遗留① 的行号漂移 | `fontSize: 10` 在 `apps\desktop\lib` 下**仅两处**：`today_page.dart:457`、`standup_section.dart:190`；契约写的 `standup_section.dart:404` 不存在（文件 226 行） | 两处改 `fontSize: 12`；Task 3 遗留注已改正并标实测行号。**不碰** `review_chip_field.dart:159` 的 `const int _chipFont = 10;`（那是 chip 字号设计值、非 `fontSize:` 写法，且该文件在禁改集，登记 M15-2） |
| J12 | Step 1 只给 1 个用例，Step 4 期望却写「4 例全绿」——计数本身不成立 | 赭石纪律（J1/J2）与断点边界（J4）若无单测，装机前**无任何静态判据**；R8 已确立「判据必须能看见目标」 | Step 1 扩为 **5 例**（三段全渲染 + 永不折叠 + `gapSec` 恰 2 个 / 节点形状与赭石纪律含反例 / 双通道文字与颜色 / 断点纯函数边界 / 10×10 与 ≥12px 共存 + 窄视口左沿 `52+10` 实测）；Step 4 期望改为「目标 **5 例全绿** + 全量 **`+107`** + analyze 逐字 `No issues found!`」。测试内 `_host()` 自造 `MaterialApp > MediaQuery > Scaffold > SizedBox(width:)`，`SizedBox(width:)` 钉死宽度使 `MediaQuery` 值与布局宽度不漂移；`const` 嵌套写法满足 `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`；`border!` 后用 `.top.color`（`Border.top` 非空，写 `top!` 会触发 `unnecessary_non_null_assertion`——R8 同源坑） |
| J13 | 契约散文要「`_AddPlanItemBar`（收件箱）移到晨段顶部」，且把午段写成 `HabitCheckinStrip`，但**没有任何契约代码承载它** | `today_page.dart:497` 的 `_AddPlanItemBar` 是私有 `ConsumerStatefulWidget`，漏写即 `unused_element`；实测 `HabitCheckinStrip` **全仓此前未挂载**（只被 `test\habit_checkin_strip_test.dart:12/:55` 引用）⇒ Task 15 是唯一挂载点，`spec:114` 把它定为吸底而非午段内容 | 三段定为：晨 = `StandupSection` + `_PlanBlock` + `_AddPlanItemBar`；**午 = `HabitSection`（现有功能一律不删）**；晚 = `ReviewSection` + `MoodSection`。`HabitCheckinStrip` 只挂吸底位**一处**；`_AddPlanItemBar` 位置紧随 `_PlanBlock` 不变，只把按钮文案 `添加`（`:558`）改 `+ 手写一条`，`hintText`（`:549`）不动。「移到晨段顶部 / 改收件箱子段」属 B4 ⇒ 见 M15-7 之后的合并裁定，本轮不做 |
| J14 | 契约未写「删除 / 改名后的残留引用必须清零」 | `analysis_options.yaml` 实测把 `unused_import`（`:7`）、`unused_local_variable`（`:8`）、`unused_field`（`:9`）、`dead_code`（`:10`）、`unnecessary_null_comparison`（`:11`）提升为 error；`unused_element` 默认 warning；`directives_ordering` 未开 | import 连带清单：`today_page.dart:9`（午段仍渲染 `HabitSection`）与 `:12`/`:13`/`:15` **全部保留**；新增 `../widgets/day_timeline.dart`、`../widgets/habit_checkin_strip.dart` 两条。`_MoodSliderRow` 的类名与调用点（`mood_section.dart:141-153`）都不动；本轮不新增 `lib/src/features/`（`spec:19` 属 B5） |
| J15 | 契约草稿写 `DateBar(date: date, onJump: _jumpTo)` | `date_bar.dart:14` 实为 `const DateBar({super.key, this.onPickDate})`，`:17` 只有 `onPickDate`，日期由内部自 watch（`:22` `selectedDateProvider`、`:23` `todayProvider`）⇒ 草稿**不可编译** | 今日页写 `const DateBar()`，不传参 |
| J16 | 契约草稿把含 `Expanded` 的 `Column` 直接作 `Stack` 的非定位子 | `Stack` 非定位子拿到 loose 高度约束 ⇒ `RenderFlex children have non-zero flex but incoming height constraints are unbounded` | 主内容包在 `Positioned.fill(child: Column[...])`；吸底件用 `Positioned(left/right/bottom: 0)` |

**判读说明（四点，避免实现者困惑）**：
1. **实现与改写后的契约代码块逐字一致，不得判 FAIL**；若发现改写后仍不可编译，按 R7 的「以实测为准」处置并登记 R10。
2. **J13 / J5 是本节最后两道保险**：`_AddPlanItemBar` 必须仍被实例化（否则 `unused_element` error），`_MoodSliderRow` 的调用点必须保持 `onChanged(int)` 通路（否则 `unused_field` / 类型错）。二者任一被「照契约散文顺手改掉」都会红。
3. **午段必须是 `HabitSection`（不是 `HabitCheckinStrip`）**：`HabitSection` 由午段渲染 ⇒ `today_page.dart:9` 的 import 得以保留、不会 `unused_import`；`HabitCheckinStrip` 只在吸底位出现**一处**，二者各得其所，不存在「重复渲染」问题（旧稿那句判读作废）。
4. 本轮**不碰 `packages/**`** ⇒ `core_data` 不重跑（台账沿用 `+122`）；**不改 `design-demos/TOKENS.md`**（J4 的 52/10 已在口径文件 `:238-239`）；`app_tokens.dart:5` 声明的唯一真源仍是它。

**遗留（M15-x，本轮不顺手修）**：
- **M15-1**（spec:94 铁律，优先级最高）：`today_page.dart:31` 与 `:101` 仍 `ref.watch(todayProvider)`，而铁律 1 要求「今日页的日期写入**只读 `selectedDateProvider`**」（`providers.dart:29`）。本轮不动日期选择逻辑 ⇒ 另轮迁移。
- **M15-2**：`review_chip_field.dart:159` 的 `const int _chipFont = 10;` 是「chip 字号」设计值，与 `TOKENS.md:291-292`（chip 12px）冲突。**注意**：本轮实测 `apps/desktop/lib/src/widgets/review_chip_field.dart` **不存在**（该文件在 `apps/desktop` 下无此路径），真实路径待查 ⇒ 本轮不顺手修，登记待后续定位。
- **M15-3**：`today_page.dart:137` 的 `// TODO(Task 15): 接入滚动定位` + `:138` 空实现 `_jumpTo`——契约未给滚动定位判据，本轮保留空实现并把 TODO 改指 `Task 17`（B4 页合并后再做）。
- **M15-4**：`§6:299` 要求「打卡成功绿、失败红」，本轮只保住红色侧（`colorScheme.error`）；绿色需新增 token（`TOKENS.md` 零命中 ⇒ 口径变更），连同「mood 卡是否保留 coral」一起属视觉专项（Task 18）。
- **M15-5**：`section_header.dart` 的 `ellipsis` 与 `TOKENS.md:297`「标签不允许 ellipsis 截断」冲突（J3 依据），本轮它在禁改集 ⇒ 后续统一整改。
- **M15-6**：J5 / J6 / J13 属交互改动，本轮判据 = analyze 全绿 + 全量 test 不回退 + 真机；缺 `mood_section_test.dart` 的 widget 级判据 ⇒ 登记补测。
- **M15-7**：三段的 `hasGap` 本轮一律取默认 `false`（非缺口态）。缺口判定需要 `DayStats` 的字段口径而契约未给 ⇒ 与 M15-3（滚动定位）一起在后续轮接入。本轮已用单测锁住「非缺口态无 accent 填充 + 节点文案 `✓ 已闭合`」，后续接入时该用例必须当场变红。

**范围纪律不变**：仍不新增 `lib/src/features/`（spec:19 属 B5）；`section_card.dart` / `habit_checkin_strip.dart` / `habit_section.dart` / `date_bar.dart` / `section_header.dart` / `loop_progress_ring.dart` / `providers.dart` / `packages/**` 一律不改；两个新文件只允许 `lib/src/widgets/day_timeline.dart` 与 `test/day_timeline_test.dart`。**


---

## Task 16: 键盘可达性与统一焦点环

**Files:**
- Create: `apps/desktop/lib/src/widgets/focus_ring.dart`
- Modify: `apps/desktop/lib/src/pages/today_page.dart`（快捷键）
- Modify: `apps/desktop/lib/src/widgets/chip_row.dart`（芯片焦点环）
- Test: `apps/desktop/test/keyboard_accessibility_test.dart`

**Interfaces:**
- Consumes: `selectedDateProvider` / `todayProvider`（Task 6）、`AppTokens`（Task 1）、`shiftIsoDate()`（`package:core_data`）
- Produces:
  - `class FocusRing extends StatefulWidget { const FocusRing({super.key, required this.child, this.focusedBorderWidth = 2, this.focusNode}); }` —— 焦点环 = `--ink` 2px 实线（**不得**赭石）。被动装饰件：**不申请焦点、不进 Tab 遍历、不改变子组件布局**（`Stack` + `Positioned.fill` + `IgnorePointer` 覆盖层）。聚焦态来源 = 外部 `focusNode`（子组件 `InkWell` / `Focus` 自己的节点）；`focusNode == null` 时永不点亮，也不报错。
  - 本轮实现的快捷键：`Ctrl+D` 回今天 · `←/→` 换天（**焦点在文本输入域内时不拦截**，否则会抢走输入框光标移动）
  - 芯片键盘激活：`Space` / `Enter` 触发 `ChipRow.onChanged`（`InkWell` 自带，本轮用测试锁住，不另写 `onKeyEvent`）
  - 已在别处实现、本轮只锁不改：`PgUp/PgDn` 翻月（`date_picker_sheet.dart:232-235`，Task 12）
  - 未实现：`Ctrl+1..6` 切页 · `Space` 勾选计划条目 · `Enter` 打开详情 · `Esc` 关闭浮层 —— 见文末 M16-1..M16-3

- [x] **Step 1: 写失败测试**

```dart
// apps/desktop/test/keyboard_accessibility_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practilog/src/pages/today_page.dart' show isTextInputFocused;
import 'package:practilog/src/theme/app_tokens.dart';
import 'package:practilog/src/widgets/chip_row.dart';
import 'package:practilog/src/widgets/focus_ring.dart';

void main() {
  testWidgets('焦点环是 ink 2px，不是 accent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FocusRing(child: Text('x'))),
      ),
    );
    final ring = tester.widget<FocusRing>(find.byType(FocusRing));
    expect(ring.focusedBorderWidth, 2);
    expect(AppTokens.accent, isNot(AppTokens.ink));
  });

  testWidgets('聚焦后环 = ink 2px，失焦后透明', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusRing(
            focusNode: node,
            child: Focus(
              focusNode: node,
              child: const SizedBox(width: 40, height: 20),
            ),
          ),
        ),
      ),
    );
    Border ringBorder() {
      final ring = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('focus-ring-border')),
      );
      return (ring.decoration! as BoxDecoration).border! as Border;
    }

    node.requestFocus();
    await tester.pumpAndSettle();
    expect(ringBorder().top.color, AppTokens.ink);
    expect(ringBorder().top.width, 2);

    node.unfocus();
    await tester.pumpAndSettle();
    expect(ringBorder().top.color, Colors.transparent);
  });

  testWidgets('芯片聚焦后 Space / Enter 触发 onChanged', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: const <ChipOption>[
              ChipOption(key: 'a', label: '按时完成'),
            ],
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    // 让芯片拿到焦点：优先用 Tab 遍历，取不到就显式 requestFocus。
    // 芯片的 FocusNode 就是 FocusRing 收到的那个（chip_row 用它包 InkWell）。
    final FocusNode chipNode =
        tester.widget<FocusRing>(find.byType(FocusRing)).focusNode!;
    chipNode.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(captured, {'a'});

    captured = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(captured, {'a'});
  });

  testWidgets('文本输入域内 isTextInputFocused 为真，离开后为假', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              TextField(),
              FilledButton(onPressed: _noop, child: Text('ok')),
            ],
          ),
        ),
      ),
    );
    expect(isTextInputFocused(), isFalse);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(isTextInputFocused(), isTrue);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(isTextInputFocused(), isFalse);
  });
}

void _noop() {}
```

- [x] **Step 2: 跑测试，确认失败**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\keyboard_accessibility_test.dart
```
Expected: FAIL —— URI 不存在（`focus_ring.dart` 与 `isTextInputFocused` 都还没有）。

- [x] **Step 3: 写实现**

`focus_ring.dart`（新文件）：

```dart
// apps/desktop/lib/src/widgets/focus_ring.dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 统一焦点环：`--ink` 2px 实线（TOKENS §5）。**不得**用赭石。
///
/// 被动装饰件：自己不申请焦点、不进 Tab 遍历、不改变子组件布局。
/// 聚焦态来自 [focusNode]（通常是子组件 `InkWell` / `Focus` 自己的节点）。
class FocusRing extends StatefulWidget {
  /// 创建焦点环。
  const FocusRing({
    super.key,
    required this.child,
    this.focusedBorderWidth = 2,
    this.focusNode,
  });

  /// 内容。
  final Widget child;

  /// 聚焦时的环宽（未聚焦时同宽透明，避免布局跳动）。
  final double focusedBorderWidth;

  /// 聚焦态来源；null 表示永不点亮。
  final FocusNode? focusNode;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  FocusNode? _node;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _bind(widget.focusNode);
  }

  @override
  void didUpdateWidget(FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unbind();
      _bind(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _bind(FocusNode? node) {
    _node = node;
    if (node == null) {
      _focused = false;
      return;
    }
    _focused = node.hasFocus;
    node.addListener(_onFocusChanged);
  }

  void _unbind() {
    _node?.removeListener(_onFocusChanged);
    _node = null;
  }

  void _onFocusChanged() {
    final focused = _node?.hasFocus ?? false;
    if (!mounted || focused == _focused) {
      return;
    }
    setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              key: const ValueKey('focus-ring-border'),
              duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: _focused ? AppTokens.ink : Colors.transparent,
                  width: widget.focusedBorderWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

`today_page.dart`（快捷键，**保留**现有 `dayLog.when(loading/error/data)` 三分支，只在外层包两层；**不得**把 `body:` 直接换成 `_TodayBody(...)`）：

```dart
      body: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyD, control: true):
              _GoTodayIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _ShiftDayIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowRight): _ShiftDayIntent(1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _GoTodayIntent: _GoTodayAction(
              onInvoke: () => ref.read(selectedDateProvider.notifier).state =
                  ref.read(todayProvider),
            ),
            _ShiftDayIntent: _ShiftDayAction(
              onInvoke: (delta) {
                final current = ref.read(selectedDateProvider);
                ref.read(selectedDateProvider.notifier).state =
                    shiftIsoDate(current, delta);
              },
            ),
          },
          child: dayLog.when(
            loading: /* 原样 */,
            error: /* 原样 */,
            data: /* 原样 */,
          ),
        ),
      ),
```

同文件顶层再放一个可测的判定函数（`analyze` 不得报警，测试直接调它）：

```dart
/// 焦点是否在文本输入域内。
///
/// `←/→` 换天只在非输入态生效，否则会抢走输入框的光标移动。
bool isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return false;
  }
  return context.widget is EditableText ||
      context.findAncestorStateOfType<EditableTextState>() != null;
}
```

`_GoTodayIntent` / `_GoTodayAction` / `_ShiftDayIntent` / `_ShiftDayAction` 仿 Task 12 的 `_MonthIntent` / `_MonthAction`（`date_picker_sheet.dart:303-320`）写法；`_ShiftDayAction` 必须覆写 `isEnabled`，返回 `!isTextInputFocused()` —— 返回 `false` 时 `ShortcutManager` 会把事件继续冒泡给 `DefaultTextEditingShortcuts`，输入框光标才会正常移动。

`chip_row.dart` 的 `_ChipButton` 改造要点（**不改** `ChipRow` 公开签名，不改 `Semantics` 语义）：

```dart
class _ChipButton extends StatefulWidget { /* 原参数 + 现有 onTap */ }
// State：
//   1) 自持 FocusNode _focusNode（dispose 里释放）；
//   2) InkWell(focusNode: _focusNode, onTap: ...)；
//   3) 外层包 FocusRing(focusNode: _focusNode, child: Material(...))；
//   4) 颜色/描边/圆角/文字色的取值一律不动（既有 chip_row_test 断言必须继续绿）。
```

- [x] **Step 4: 跑测试，确认通过**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact test\keyboard_accessibility_test.dart
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
```
Expected: 目标文件 4 例全通；全量 `All tests passed!` 且计数 = 本轮前基数 + 4（Task 15 收口基数 `+107`，故期望 `+111`）；`analyze` 逐字 `No issues found!`。

- [x] **Step 5: 证据落盘**

`apps\desktop\lib\src\widgets\focus_ring.dart` + `apps\desktop\test\keyboard_accessibility_test.dart` 存在；三条门禁日志（目标 / 全量 / analyze）落 `reports\`，文件名带 `task16`。

**遗留（M16-x）**

- **M16-1**：`Ctrl+1..6` 切页未实现 —— 当前无六页壳层/侧栏导航（`apps/desktop/lib` 内 `SingleActivator` 只出现在 `date_picker_sheet.dart`），跨页壳层属后续批次。
- **M16-2**：`Space` 勾选计划条目、`Enter` 打开详情未实现 —— 计划条目的勾选入口在 `DayTimeline` / 行动项芯片侧，详情页尚无路由；本轮 `Space`/`Enter` 只在 `ChipRow` 上生效并有测试锁住。
- **M16-3**：`Esc` 关闭浮层未加自定义绑定 —— `WidgetsApp` 默认 `Escape → DismissIntent` 已覆盖 Dialog/BottomSheet；Task 17 真机确认，失效再补。
- **M16-4**：`←/→` / `Ctrl+D` 的**页面级**行为（按方向键后 `selectedDateProvider` 真的移位、`DateBar` 标题同步）缺 widget 级判据 —— 需要 pump `TodayPage` + 仓储 fake；本轮判据 = `analyze` 编译通过 + 全量不回退 + Task 17 真机键盘验收，其中「文本输入域内不拦截」由 `isTextInputFocused` 单测锁住。
- **M16-5**：`FocusRing` 比原契约多一个可选 `focusNode` 参数 —— 被动焦点环不得自己抢焦点（`Focus` 包一层会给每枚芯片多一个 Tab 停靠点），原签名 `FocusRing(child: ...)` 仍可构造。
- **M16-6**：`_TodayBody.date` 取 `todayProvider`（`today_page.dart:33`），与数据源 `selectedDateProvider` 不同源 —— 在补录/预排日新增计划条目会落到今天（`_AddPlanItemBar` → `planItem.create(date: widget.date)`）。既有缺陷，Task 16 未改变其可达路径，本轮不动，登记后续修。

---

## Task 17: G4 视觉/无障碍门禁 + 真机验收 + 打包 exe

**Files:**
- Create: `tools/gates/g4_contrast.ps1`（**纯 ASCII + CRLF + 无 BOM**）
- Create: `docs/B1_验收记录.md`（验收证据落盘）
- Modify: `tools/gates/README.md`（补 G4 行）
- Modify: `docs/HANDOFF_20261107_B版原型收口_转Flutter实施.md`（B1 状态回写）

**Interfaces:**
- Consumes: Task 1 的 `contrastRatio`、Task 3 的 `AppTheme`、全部前置任务
- Produces: 可重复运行的 G4 门禁脚本 + B1 验收记录 + 打包 exe

- [x] **Step 1: 写门禁脚本**

```powershell
# tools/gates/g4_contrast.ps1
# G4 - visual and accessibility gate: checks Flutter token contrast ratios.
# ASCII only. CRLF line endings. No BOM.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$desktop = Join-Path $root 'apps\desktop'

if (-not (Test-Path $desktop)) {
    Write-Error "desktop app not found: $desktop"
}

function Reset-TestCache {
    # `flutter test` on Windows hangs forever when build\test_cache\build already
    # holds a dill (test_compiler.dart: OS Error 183). Moving it aside keeps this
    # gate repeatable across back-to-back runs.
    $cacheBuild = Join-Path $desktop 'build\test_cache\build'
    if (Test-Path -LiteralPath $cacheBuild) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $aside = Join-Path $desktop ('build\test_cache_stale_g4_' + $stamp)
        Move-Item -LiteralPath $cacheBuild -Destination $aside
        Write-Host ('G4 CACHE_RESET_OK ' + $aside)
    }
}

Push-Location $desktop
try {
    Reset-TestCache
    & 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact `
        test\theme_tokens_test.dart
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'G4 FAILED: contrast gate'
    }
    Reset-TestCache
    & 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact `
        test\app_theme_test.dart
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'G4 FAILED: theme gate'
    }
}
finally {
    Pop-Location
}

Write-Host 'G4 PASSED'
```

`tools/gates/README.md`：门禁清单是 4 列（`| 门禁 | 内容 | 脚本 | 失败处理 |`），现有 G4 行是 `| G4 | 导出等价：导出→导入→逐行一致 | P1 阶段补 | 阻断 |`。**整行替换**那一行，不要追加 —— 追加会多出第二行 G4，而且只有 3 列会把表格撑破。原「导出等价」语义顺延到 P1，届时另行编号。

替换后的目标行（4 列，脚本名写法与 G1–G3 行一致）：

`| G4 | 视觉 / 无障碍对比度门禁（跑 theme_tokens_test + app_theme_test） | g4_contrast.ps1 | 阻断 |`

- [x] **Step 2: 跑门禁，确认通过**

```powershell
& F:\soft\00selfmade\practilog\tools\gates\g4_contrast.ps1
```
Expected: 输出含 `G4 PASSED`；若命中缓存残留，之前还会有 `G4 CACHE_RESET_OK ...`。

- [x] **Step 3: 全量门禁**

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
& F:\soft\00selfmade\practilog\tools\gates\g1_analyze.ps1
& F:\soft\00selfmade\practilog\tools\gates\g2_unittest.ps1
& F:\soft\00selfmade\practilog\tools\gates\g3_migration.ps1
& F:\soft\00selfmade\practilog\tools\gates\g4_contrast.ps1
```
Expected: G1–G4 全绿。**G3 必须仍绿**（本批次没动 schema）。

- [x] **Step 4: 构建 Windows 产物**

```powershell
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' build windows --release
```
Expected: `apps\desktop\build\windows\x64\runner\Release\PractiLog.exe` 存在。

- [x] **Step 5: 打包 exe（装机实测）**

```powershell
& F:\soft\00selfmade\practilog\tools\build\make_installer.ps1
```
Expected: `release\PractiLog-Setup-<version>_<timestamp>.exe` 落盘。

- [x] **Step 6: 真机验收（spec §14 的 B1 相关场景，逐条勾）**

在**打包产物的 exe** 上（不是 `flutter dev`）逐条走：

| # | 场景 | 判据 | 记录 |
|---|---|---|---|
| 1 | 零打字闭环 | 待办捞 3 条 → 打勾 2 条 → 结论芯片填 `result_note` → 打卡 1 个习惯 → 复盘选短语 → 心态数字格打分，全程不碰键盘；落库文案符合 §6.1/§6.2 | `docs/B1_验收记录.md` 记日期 + 截图路径 |
| 2 | 反解健壮性 | 手工把一条 `result_note` 改成自由文本 ⇒ UI 降级为只读纯文本 + `重新结构化`，不崩、不丢数据 | 同上 |
| 3 | 补录 | 日历点 5 天前的空白天 ⇒ 建 2 条计划并打卡 ⇒ 徽标显示 `补录模式`，`done_at` 保持真实时刻 | 同上 |
| 4 | 预排不可打卡 | 给明天建 `plan_item` ⇒ 明天之前的界面上不出现打卡/回填入口 | 同上 |
| 5 | DPI/字号 | 144dpi（×1.5）+ 系统字号 200% ⇒ 芯片换行不溢出、吸底卡带不遮挡、闭环环不截断 | 同上 |
| 6 | 键盘全通路 | 仅用 Tab/Space/Enter/方向键完成一次晨段闭环（不依赖鼠标） | 同上 |

- [x] **Step 7: 回写交接与验收记录**

`docs/B1_验收记录.md` 记录：构建产物路径、exe 路径、6 条场景的通过/未通过 + 证据（截图路径 / 数据库查询结果）、遗留问题。

`docs/HANDOFF_20261107_B版原型收口_转Flutter实施.md` 追加一段「B1 已实施」状态，指向 `docs/B1_验收记录.md` 与本计划文件。

- [x] **Step 8: 证据落盘**

`tools\gates\g4_contrast.ps1` + `docs\B1_验收记录.md` + `release\PractiLog-Setup-*.exe` 三者同时存在。

---

## Task 18: 安装包隐私排除 + M16-6（日历宿主 · 补录 / 预排可达）—— B1 收口后追加

- 追加时间：2026-11-09（Task 17 收口后新增；此前计划内无 Task 18）
- 来源：`docs\B1_验收记录.md` 第 5 节遗留 **#1（高 · 隐私）** 与 **#2（高 · 功能 · M16-6）**
- 分工：控制器不得改 `apps\`、`packages\` 下任何文件 ⇒ **A / B 两块实现一律经 worker**
- 门禁期望值：desktop 全量基线 **+111**（Task 17 后）⇒ 本任务后 **≥ +111 + N**（零回退）；`flutter analyze` 逐字 `No issues found!`；安装包解包目录对 `*.db` / `*.db-wal` / `*.db-shm` / `*.sqlite*` / `*.log` / `userdata` **0 命中**

### A. 安装包排除开发机 userdata（tools 侧）

**根因**：`tools\build\installer.nsi:165` 是 `File /r "${PAYLOAD_DIR}\*.*"`，把 `…\runner\Release` 整棵递归打包；真机验收在 `Release\userdata\` 留下 `practilog.db`（278528 B）、`practilog.db-wal`、`practilog.db-shm`、`practilog_startup.log` ⇒ **个人数据随安装包分发**。

**Files**：
- Modify: `tools\build\make_installer.ps1`
- Modify: `tools\build\installer.nsi`（**仅当** staging 方案不可行时才改；默认不改）

**契约（必须满足）**：
1. 打包前构造**白名单 staging 目录**（默认 `$root\release\payload_<时间戳>\`），只把允许分发的文件复制进去；**必须排除**：
   - 任何名为 `userdata` 的目录（整棵子树：`practilog.db` / `-wal` / `-shm` / `practilog_startup.log`）
   - 任何 `*.db` / `*.db-wal` / `*.db-shm` / `*.sqlite` / `*.sqlite3` / `*.log`
2. `PAYLOAD_DIR` 指向 staging 目录；NSIS 侧不感知排除规则。
3. 报告（`installer_build_report.txt`）新增 `payload_source_dir` / `payload_staging_dir` / `excluded_count` / `excluded_bytes` / `excluded_paths`（逐条列出被排除的相对路径）。
4. **不得**因排除而丢失运行必需文件：`practilog.exe`、`flutter_windows.dll`、`data\app.so`、`data\icudtl.dat`、`data\flutter_assets\*`。
5. 脚本保持 **纯 ASCII + CRLF + 无 BOM**（既有约定）；**不引入删除操作**（staging 残留目录保留）。
6. 打包后自检：解包目录内对上述排除模式 **0 命中**。

### B. M16-6：今日页跟随所选日 + 月历宿主（补录 / 预排可达）

**根因**：`today_page.dart:34` 用 `todayProvider`，而数据源（`dayLogProvider` / `planItemsProvider` / `dayStatsProvider` / `habit_checkin_strip`）全部读 `selectedDateProvider` ⇒ 页面标题与数据不同源；`CalendarMonthView` 全仓无宿主页 ⇒ 用户无任何路径进入历史日 / 未来日（验收场景③ 受限）。

**Files**：
- Modify: `apps\desktop\lib\src\pages\today_page.dart`
- Create: `apps\desktop\lib\src\pages\calendar_page.dart`
- Modify: `apps\desktop\lib\src\app.dart`（新增 `/calendar` 路由 + 今日页入口）
- Create: `apps\desktop\test\calendar_page_test.dart`
- Create: `apps\desktop\test\today_page_selected_date_test.dart`

**契约（必须满足）**：
1. `today_page.dart` 顶部日期改读 `selectedDateProvider`；标题、`DateBar`、计划区块、闭环环数据必须与选中日一致。
2. 新增 `CalendarPage`（`apps\desktop\lib\src\pages\calendar_page.dart`）：
   - 复用既有 `calendarMonthProvider(month)`（`providers.dart:89`）与既有 `CalendarMonthView`；**不得**新建第二套月历控件，**不得**改 `calendar_month_view.dart` 的既有 API
   - 顶部 `DateBar`；中部月历；左右翻月按钮（`key: ValueKey('calendar-prev-month')` / `ValueKey('calendar-next-month')`）；月份标题显示 `YYYY-MM`
   - 点某天（`onPickDay`）⇒ 写入 `selectedDateProvider` 并 `Navigator.pop` 回今日页
   - 过去日可点可进（补录），未来日可点可进（预排）
3. 今日页提供打开 `/calendar` 的入口（AppBar action，图标 + tooltip「日历」，`key: ValueKey('open-calendar')`）。
4. **未来日只可预排、不可打卡 / 回填**（spec §H-1、spec:78 / spec:426）：
   - 未来日的计划条目 `Checkbox` 必须禁用（`onChanged: null`），并给出可见提示
   - 未来日不出现习惯打卡入口（`HabitCheckinStrip` 对未来日整卡不显示）
   - 过去日可打卡、可回填、可写复盘与心态
5. 补录可达链路：今日页 → 日历 → 点 5 天前 → 今日页显示该日、`DateBar` 显示 `补录模式` 徽标、可建计划与打卡。
6. 不得破坏既有行为：`Ctrl+D` 回今天、`←/→` 切日、完整/极简切换、吸底打卡卡、Task 16 焦点环契约要素（`FocusRing` 保持被动、`key: ValueKey('focus-ring-border')` 不得改名）。
7. **不改** `apps\desktop\lib\src\providers.dart`（`calendarMonthProvider` 已就位）、**不改** `apps\desktop\lib\src\widgets\calendar_month_view.dart`。
8. 遗留登记（本任务**不实施**）：M13-6（`calendarMonthProvider` 只覆盖本月 first..last，补白格无摘要）—— 补白格仍可点可切日，不阻塞可达性，登记为 M18-x。

- [x] **Step 1: A 块实现（staging 排除）+ 打包自检**

- [x] **Step 2: B 块实现（宿主接线 + 未来日只读）+ 目标测试**

- [x] **Step 3: 门禁（目标测试 / desktop 全量 / analyze）+ 安装包重建与解包核对**

- [x] **Step 4: 证据落盘 + 越界比对**

### C. M18-2：过去日习惯打卡写错日期（B 块连带缺陷）

**根因**：`apps\desktop\lib\src\widgets\habit_section.dart:79` 仍读 `todayProvider`，第 99 / 110 行 `repo.upsertCheckin(habitId:, date: date)` ⇒ 用户在所选**过去日**勾选习惯时，打卡被写到**今天**。B 块开放历史日可达后该缺陷被放大。

**Files**：
- Modify: `apps\desktop\lib\src\widgets\habit_section.dart`
- Create: `apps\desktop\test\habit_section_selected_date_test.dart`

**契约（必须满足）**：
1. 日期来源改读 `selectedDateProvider`（与 `habit_checkin_strip.dart:38`、`providers.dart:35/43/57` 同源）。
2. 未来日仍不可打卡（spec §H-1）：若习惯区在未来日仍渲染可点击行，须在 `habit_section.dart` 内禁用写入路径（Checkbox `onChanged: null` + onTap 不写入）。
3. 不改 `CalendarMonthView` API、不新建第二套日期选择 UI；不改 `providers.dart`。

- [x] **Step 5: C 块实现（M18-2 打卡日期修正）+ 复验**
- **Step 3 补记（F-1 · 独立 verifier 终审发现并已修复 · 2026-11-09 18:17）**：verifier 复核发现首版新包 `release\PractiLog-Setup-1.0.0_20261109-174822.exe`（17:48 打包）内 `data\app.so` 仍是 **Task 17 产物**（6783880 B / sha16 `04A2489DCB09F585` / mtime 14:34:36），二进制中 `CalendarPage` / `open-calendar` / `calendar-prev-month` / `calendar-next-month` **四个探针全部探不到** ⇒ 该包只含 A 块、**不含 B/C 修复**，Step 3「安装包重建与解包核对」未被忠实执行。**处置**：重跑 `flutter build windows --release`（57.0 s / BUILD_EXIT=0，新 `app.so` 6800264 B / sha16 `9B8AE231363A5F50` / mtime 18:17:25）→ 重跑 `make_installer.ps1`（makensis exit 0）⇒ 新包 **`release\PractiLog-Setup-1.0.0_20261109-181730.exe`（10923456 B / sha16 `A4DA05AAA89D07E8`）**；独立解包核验（`reports\task18-repack-verify.txt`）：**DB/SQLITE/LOG/USERDATA 命中全 0、必需文件缺失 0、24 文件 / flutter_assets 10 项、`app.so` sha16 已变更且四个日历常量探针全 True ⇒ VERDICT=PASS**

## Task 19: B 版视觉保真（墨径·账页流）+ 第 5 节剩余 3 条遗留

> 本段由控制器于 2026-11-09 追加（计划内原本没有 Task 19）。
> 依据：`docs\B1_验收记录.md` 第 5 节遗留 #3 / #4 / #6 + 用户「当前 UI 与设计稿偏差非常大」的要求。
> 视觉口径来源：`design-demos\v2-ledger.html`（B 版「墨径 · 账页流」，已获批）+ `design-demos\TOKENS.md` + `design-demos\DESIGN.md`。
> 本段只描述**目标态与验收判据**，不复制 HTML/CSS 全文；实现者必须逐条对照原型选择器。

### 0. 背景：当前实现与设计稿的偏差（控制器亲读坐实，非转述）

B1 的前 18 个 Task 交付的是**功能**，不是**版面**。把 `apps\desktop\lib` 的实际实现与已获批的 B 版原型逐条比对后确认：**偏差是结构性的，不是换皮差距**。

| # | 设计稿要求（原型选择器 / 口径） | 当前 Flutter 实现 | 位置 | 严重度 |
|---|---|---|---|---|
| D-01 | `.app{grid-template-columns:var(--nav-w) minmax(0,1fr)}` —— 左导航 214px 常驻 6 页 | **完全没有导航**，`MaterialApp.home` 直挂 `TodayPage` | `apps\desktop\lib\src\app.dart:21` | 高 |
| D-02 | `.cols{grid-template-columns:minmax(0,1fr) var(--rail-w)}` —— 右工具轨 290px 常驻 | **没有右轨** | `today_page.dart:149-227` | 高 |
| D-03 | `.ledger-pad{max-width:770px}` 内容列限宽居中 + `.ledger` 账页 32px 极淡横线底 | `ListView` 全宽、无横线底 | `today_page.dart:156` | 高 |
| D-04 | `.keybar` 底部常驻快捷键条（Ctrl+N / Ctrl+D / ←→ / Space / Enter / Esc） | **没有快捷键条** | —— | 高 |
| D-05 | `.ridge` 顶部贯穿全宽闭环脊线：四段比例条（`.bar i`）+ `0/25/50/75/100` 刻度 | `LoopProgressRing` 是**流内一张卡片**里的 4 列文字，**无比例条、无刻度** | `widgets\loop_progress_ring.dart` | 高 |
| D-06 | `.pghead h1` —— display 字族 24px 页头 + `.sub2` 副标 | 无页头；用 Material `AppBar` 承载标题 | `today_page.dart:40-47` | 中 |
| D-07 | `.datebar` 自绘日期条：相对日标签 + display 日期 + `▾` + ghost 按钮 | Material `AppBar` + Material `IconButton` / `TextButton` | `today_page.dart:40-67` | 中 |
| D-08 | `.chk` 22×22 方框 + `✓`/`○` 字形 + 1.5px 边 | Material `Checkbox`（圆形、Material 配色、默认手势） | `today_page.dart:381` | 高（**兼遗留 #4 根因**） |
| D-09 | `.chip[aria-checked="true"]{background:var(--ink-wash); border-color:var(--ink); color:var(--ink)}` | **ink 反白**（ink 底 + paper 字） | `widgets\chip_row.dart` 选中分支 | 中 |
| D-10 | `.chip.deny[aria-checked="true"]{border-color:var(--accent)}`（赭石边） | 边用 `accentInk` | `widgets\chip_row.dart` | 低 |
| D-11 | `.sec-h` 段头下沿 1px hair，**无前置图标** | Material `Icon` 前缀 + 无下沿线 | `widgets\section_card.dart` | 中 |
| D-12 | `.card:hover{border-color:var(--hair-strong)}` —— hover **只加 1px 边**，不加阴影、不位移 | **无 hover 态** | `widgets\section_card.dart` | 中 |
| D-13 | 数字一律 `--f-mono` + `tabular-nums`（`.num/.pri/.state/.cell/.hm`） | 仅个别处用 `tabularFigures`，字族仍为 body | 多处 | 中 |
| D-14 | `.dock` 吸底条是**独立布局行**，结构上不可能遮挡主列表 | `Stack` + `Positioned(bottom:0)` 叠在列表上，用 `padding bottom:96` 补偿 | `today_page.dart:157 / 219-225` | 中 |
| D-15 | `.nav a .idx` 序号 01–06（mono）+ `.brand` 品牌块 + `.nav-foot` | 无 | —— | 中 |
| D-16 | 密度三档变量 `--pad-card` / `--gap-sec` 驱动卡片内距 | `DensityProfile` 已定义但卡片硬编码 `gapCard=12` | `widgets\section_card.dart` | 低 |
| D-17 | 遗留 #3：导航 02「待办池」+ 段①「从待办池捞（Ctrl+N）」 | `todo` 表**零渲染入口**，`sourceType`/`source_todo_id` 在 `lib` 下 0 命中 | —— | 高 |
| D-18 | 遗留 #4：`.chk` 是独立 button，可单独获焦并用 Space 切换 | 行级 `InkWell` 包住整行，行级 `ActivateIntent` 吞掉 Space | `today_page.dart:374 / 381` | 高 |
| D-19 | 遗留 #6：字号 200% 下不破版 | 未实测（改本机系统字号需重新登录，未做） | —— | 中 |
| D-20 | 设计稿基准视口 1440×900；`<1280` 单栏、导航折叠为顶栏横排 | 默认窗口 1200×840，**落在 <1280 响应带里**，双栏骨架永远看不到 | `lib\src\desktop_shell.dart:109-114` | 高 |

### 1. 控制器裁定（两条契约歧义，先裁定再派工）

- **裁定 A（芯片选中态）**：`TOKENS.md` §1.5 把 `.chip[aria-checked="true"]` 列进「ink 反白」清单，与 §5 清单（未列 `.chip`）和原型实测 `v2-ledger.html:233` **矛盾**。原型的**实测值**是 ink 洗底 + ink 边 + ink 字 + `font-weight:500`；`.btn.pri` / `.chk[aria-pressed=true]` / `.cell[aria-pressed=true]` 才是反白。⇒ **芯片选中 = `--ink-wash` 底 + `--ink` 边 + `--ink` 字**；反白只保留给按钮 / 勾选框 / 日历格。同时修订 `design-demos\TOKENS.md` §1.5 文字，消除该矛盾（**属于本 Task 的写集，不得留给后续**）。
- **裁定 B（系统字号 200% 怎么测）**：Windows 的系统文本缩放 Flutter 不跟随，改本机设置需重新登录、且属于改动用户系统环境 ⇒ 不采用。改用**进程内可控倍率**：`PRACTILOG_TEXT_SCALE` 环境变量（默认 `1.0`）在 `main.dart` 读取后以 `MediaQuery.textScaler` 施加到整棵树。这样真机可用 `PRACTILOG_TEXT_SCALE=2.0` 启动打包产物，取得**与系统 200% 等价的真实像素证据**，且不污染用户环境。

- **裁定 G（待办池显示列修正）**：`todo` 表与 `core_domain.Todo` **都没有 `domain` 字段**（表里只有 `quadrant` / `priority_abc` / `project_id` / `due_date`；`domain` 只存在于 `plan_item` 侧且本 Task 固定写空串）⇒ 原 Step 5 写的「领域」列**无数据来源**，改为显示 **标题 / 优先级 / 预估 / 象限 / 到期**。
- **裁定 H（待办池必须有数据来源 · 写集追认）**：`apps\desktop\lib` 对 `Todo` 实体**零引用**，全链路**无处创建待办** ⇒ 只做捞取入口会**功能空转**、遗留 #3 无法取证。故 W3 在 `packages\core_data\lib\src\repositories.dart` 追加 `TodoRepository.create(...)`（走 oplog，字段照 `todo` 表 schema），并在待办池页给出新建入口（标题 / 优先级 / 预估 / 象限 / 到期）。此为**控制器对 W4 写集的受控追认扩展**。
- **裁定 I（芯片常态底色 · 写集追认）**：原型 `v2-ledger.html:228` = `.chip{background:var(--paper)}`，而 W2 用了 `--card`（与卡片同色 ⇒ 芯片与卡片糊在一起）⇒ 改 `chip_row.dart` 常态底色 `card` → `paper`，并同步 `chip_row_test.dart` 对应那一条断言。**常态边保持 `--hair-strong`**（设计系统口径「可交互边界一律 hair-strong」优先于原型该处例外），**不动边色**。
- **裁定 J（计划里「反白」表述无需改）**：W2 报告称计划仍写「芯片选中反白」——经控制器核对为**误读**：那两处分别是 D-09 偏差行（描述**现状缺陷**）与裁定 A（描述**目标态**），本身不矛盾。计划文件无需修改。

### 2. 执行波形（写集互不重叠，可并行）

| 波 | 单元 | 写集（独占） |
|---|---|---|
| W1 | 骨架 | **新建** `apps\desktop\lib\src\widgets\shell\{ledger_shell,nav_rail,ledger_paper,tool_rail,key_bar}.dart` + 对应**新建**测试 |
| W2 | 控件保真 | `widgets\{chip_row,section_card,section_header,date_bar,loop_progress_ring}.dart` + **新建** `widgets\ledger_checkbox.dart` + `design-demos\TOKENS.md` + 对应测试 |
| W4 | 待办数据层 | `packages\core_data\lib\src\repositories.dart`（新增 `TodoRepository`）+ `packages\core_data\lib\core_data.dart`（导出）+ **新建** `packages\core_data\test\todo_repository_test.dart` |
| W2 | 装配（W3） | `apps\desktop\lib\src\{app.dart,main.dart,providers_p1.dart,desktop_shell.dart}` + `pages\{today_page.dart,calendar_page.dart,todo_pool_page.dart}` + 对应测试 |
| W3 | 收口 | 控制器亲跑门禁 + 独立 verifier + 真机 200% 专项（控制器执行） |

**硬约束**：W1 / W2 / W4 之间**没有任何写集重叠**，因此三者可同时开工；W3 必须等三者全部收口后才开工（它要用到它们的产出）。
**W3 不得修改** W1/W2/W4 的文件（发现缺陷 ⇒ 回报控制器，由控制器追认后另行修正，不得自行改写他人写集）。

### 3. Step 清单

- [x] **Step 1: 契约与基线（控制器）**
  - [x] 本段写入计划；刷新 `reports\task19-forbidden-baseline.txt`（覆盖 `apps` / `packages` / `tools` / `docs` / `design-demos`，排除 `apps\desktop\build` / `.dart_tool` / `windows\flutter\ephemeral` 与二进制扩展名）
  - [x] 偏差清单落盘 `reports\task19-deviation-audit.md`

- [x] **Step 2: W1 骨架（墨径·账页流版式）**
  - [x] `LedgerShell`：`Row` = 左导航 214px + 右列；右列 = `Column` = 内容区 + 底部快捷键条；内容区 = `Row` = 账页列 + 右工具轨 290px。断点：`<1280` 导航折叠为顶栏横排且右轨落到下方（照 `@media (max-width:1279px)`）；`≥1920` 第三栏 286px 出现（若本轮不实现，须在代码注释写 `[未覆盖] 原因` 并在交付里列出）
  - [x] 账页列：`ConstrainedBox(maxWidth: 770)` + `Center`；`≥1920` 放宽到 860px
  - [x] 账页横线底：32px 一格的极淡横线（`rgba(122,110,88,.055)` 等效），用 `CustomPainter` 实现，**不得**用 `Divider` 列表
  - [x] 左导航：品牌块「知行日志 / practilog」+ 6 项（今日 / 待办池 / 习惯 / 项目 / 日历 / 设置）+ 序号 `01`–`06`（mono）+ 底部快捷键提示；当前页 = ink 洗底（`.nav a[aria-current="page"]`）
  - [x] 右工具轨：只放**真实数据**面板（习惯速览 / 闭环提示 / 快捷键列表），**禁止假按钮**（`DESIGN.md` §2）；面板 = 1px hair-soft 边 + 4px 圆角 + card 底
  - [x] 底部快捷键条：`Ctrl+N` / `Ctrl+D` / `←→` / `Space` / `Enter` / `Esc`，键帽 = mono 11.5px + 下边 2px
  - [x] 交付：`apps\desktop\test\shell_ledger_shell_test.dart` 等新建测试，全绿

- [x] **Step 3: W2 控件保真**
  - [x] 芯片：选中 = ink 洗底 + ink 边 + ink 字 + 500 字重；拒绝类 = accent 洗底 + accent 边 + accent 字；常态边 = `--hair-strong`
  - [x] 卡片：4px 圆角 + hair-soft 边 + hover **只把边换成 hair-strong**（不加阴影、不位移）；段头去掉 Material 图标、加 1px hair 下沿线；卡片内距改读密度档
  - [x] 勾选框（`ledger_checkbox.dart`）：22×22 方框 + `✓`/`○` 字形 + 1.5px hair-strong 边；**自带独立 `FocusNode`**，`Space`/`Enter` 切换选中；焦点环 ink 2px
  - [x] 闭环脊线：改写 `loop_progress_ring.dart` 为**贯穿全宽的一条脊线**——四段（计划 / 回填 / 复盘 / 心态），每段 = 状态标记 + 标签 + 数值（mono）+ 5px 比例条（ink-2 填充；**有缺口时改 accent**）+ `0/25/50/75/100` 刻度；缺项段用 accent-ink 文字
  - [x] 日期条：改成原型 `.datebar` 形态 —— 相对日标签（昨天/今天/明天，跨多日用星期）+ display 字族日期 + `▾` + ghost 按钮（今天 / 补录模式 / 模式）
  - [x] 数字：脊线数值、比例、刻度、键帽一律 mono + `tabular-nums`
  - [x] 修订 `design-demos\TOKENS.md` §1.5，消除芯片选中态矛盾（裁定 A）
  - [x] 交付：对应测试全绿

- [x] **Step 4: W4 待办数据层（遗留 #3 的一半）**
  - [x] `core_data` 新增 `TodoRepository`：`listOpen()`（按 `created_at` 升序，过滤 `deleted_at IS NULL` 且 `status='open'`）、`pullToPlan(todoId, date)`（建 `plan_item`：`source_type='todo'`、`source_todo_id=todo.id`、`title`/`detail`/`est_minutes`/`quadrant`/`priority_abc` 快照自 todo，并把 todo 置 `done`）；写入必须走 `OplogWriter`（`uuidV7()` + `nowMillis()` + `resolveDeviceId()`）
  - [x] `PractiLogRepositories` 增加 `todo` 字段并导出
  - [x] `packages\core_data\test\todo_repository_test.dart` 全绿

- [x] **Step 5: W3 装配（遗留 #3/#4/#6 与骨架接线）**
  - [x] `app.dart`：`home` 改为 `LedgerShell` 宿主；路由加 `/todo`；导航 6 项只**今日 / 待办池 / 日历**三页有真实落点，其余三项在代码注释写 `[未覆盖] 原因` 并在交付里列出（**禁止假链接**，见 `DESIGN.md` §2）
  - [x] `today_page.dart`：拆掉 Material `AppBar` → `.datebar` + `.pghead`（display 24px + 副标）；脊线移出列表、置于内容区顶部贯穿全宽；主体进账页列；右轨挂真实面板；**吸底条改为独立布局行**（不再是 `Stack`+`Positioned`），列表不再需要 `bottom:96` 补偿
  - [x] 行级 `InkWell` 与勾选框并存：行仍可 Tab 获焦、`Enter`/`Space` 打开成果框；勾选框是**独立可聚焦节点**，`Space`/`Enter` 切换完成态（`Actions` 用 `ActivateIntent`，就近优先于行级）⇒ 遗留 #4 闭环
  - [x] 新建 `pages\todo_pool_page.dart`：列出待办池（`title` / 优先级 / 预估 / **象限** / 到期 —— 「领域」无数据来源，见裁定 G），每行「捞入今日」按钮 ⇒ 调 `pullToPlan`；捞入后今日计划实时 +1

  - [x] 待办池页给出**新建待办**入口 ⇒ 调 `TodoRepository.create(...)`（裁定 H；**写集追认**：W3 可改 `packages\core_data\lib\src\repositories.dart` 追加该方法 + `todo_repository_test.dart` 追加用例）
  - [x] 芯片常态底色 `card` → `paper`（裁定 I；**写集追认**：W3 可改 `chip_row.dart` 与 `chip_row_test.dart` 对应那一条断言）
  - [x] `providers_p1.dart` 增加待办 provider（跟随 `selectedDateProvider` 的口径另议；待办池本身与日期无关）
  - [x] `main.dart`：读 `PRACTILOG_TEXT_SCALE`（默认 1.0）→ `MediaQuery.textScaler`（裁定 B）
  - [x] `desktop_shell.dart`：默认窗口改 **1440×900**（对齐设计稿基准视口），最小 960×640
  - [x] 交付：`apps\desktop\test\todo_pool_page_test.dart` 等新建测试全绿；既有 `today_page_selected_date_test.dart` / `p1_e2e_test.dart` / `keyboard_accessibility_test.dart` / `loop_progress_ring_test.dart` 等受影响的测试**同步更新并保持绿**

- [x] **Step 6: 门禁 + 真机 + 收口（控制器）**
  - [x] 控制器亲跑门禁三件套：`flutter analyze` 逐字 `No issues found!`、`flutter test --reporter compact`（desktop 全量，期望 **≥123 + 本 Task 新增数**，零回退）、core_data 全量（期望 **≥122 + 新增数**）
  - [x] 越界比对（`reports\task19-forbidden-diff.txt`）：写集外改动 = 0
  - [x] 独立 verifier（只读、≠ 四个实现会话）复核
  - [x] 真机 200% 专项：`flutter build windows --release` → 用 `PRACTILOG_TEXT_SCALE=2.0` 启动打包产物 → 抓屏 + OCR 判读「无横向溢出 / 无文字截断 / 吸底条完整可见」⇒ 证据落 `reports\task19-scale200-*.txt`
  - [x] 计划复选框打勾（等长替换 `- [ ] ` → `- [x] `，字节数不变）；台账 `progress.md` 追加；更新 `handoff.md` §14；更新 `docs\B1_验收记录.md` 第 5 节处置

### 4. 门禁期望值（派工前口径，实施后以实测为准并同步回填）

- desktop 全量：Task 18 收口基线 **+123**；W1/W2/W4 收口后实测 **+154**；**Task 19 终值实测 +183**（较基线 +60）⇒ **零回退**
- core_data 全量：Task 18 收口基线 **+122**；W4 收口后实测 **+137**（含 `todo_repository_test.dart` 19 例）；**Task 19 终值实测 +141**（较基线 +19）⇒ **零回退**
- `flutter analyze`：error / warning / **info** 全 0，逐字 `No issues found!`
- 越界：写集外改动 = 0
- 禁用：赭石只准出现在缺口/警示 5 处；`--hair` / `--hair-soft` 只做装饰线；可交互边界一律 `--hair-strong`

## Task 20: 键条补齐（Space / Enter / Ctrl+1…3）+ 左导航底注口径订正（…6→…3）+ 200% 底注第三行

> 本段由控制器于 2026-11-10 追加（计划内原本没有 Task 20）。
> 依据：`handoff.md` §14「下一步」①（`key_bar.dart:30` 注释假引用）+ ②（`Space` / `Enter` 两条能力补齐）+ ④ 里的「200% 导航底注第三行」。
> **实现契约**（唯一实现处，别处不得另算）：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-20-w1-brief.md`（裁定 K1–K8）与 `task-20-w2-brief.md`（裁定 N1–N6）。
> 本段只描述**目标态与验收判据**；两个派工书即实现契约，本段与其冲突时以派工书为准。

### 0. 背景（控制器亲读源码坐实，非转述）

- 底部快捷键条当前只有 **4 条真实绑定**（`Ctrl+N` / `Ctrl+D` / `←→` / `Esc`）。原型 `design-demos\v2-ledger.html:1038` 的键条清单是 **7 条**，其中 `Space` / `Enter` / `Ctrl+1…6` **在本仓从未实现** ⇒ 原型键条与左导航底注「页面切换 `Ctrl + 1 … 6`」当前都是**假提示**（违反裁定 K3：留假提示不允许）。
- `apps\desktop\lib\src\widgets\shell\key_bar.dart:30-31` 的注释声称 `Esc` 来自 `app.dart` 的 `DefaultShortcuts` —— 但 `app.dart` **仅 158 行**、全库 `DefaultShortcuts` **0 命中** ⇒ **假引用**。`Esc` 的真实来源是 Flutter 框架 `WidgetsApp` 默认快捷键 `escape → DismissIntent`，弹层由 `ModalRoute` 处理 `DismissIntent` 关闭。
- `Ctrl+1…6` 对应的导航项里，「习惯 / 项目 / 设置」三项在 `kShellNavItems` 中是 `enabled: false`（**无落点**）⇒ `Ctrl+4/5/6` **永远不会实现** ⇒ 底注只能宣称到 **3**。
- Task 19 真机 200% 帧（`reports\task19-scale200-v3-ocr.txt`）：导航底注 `…6` **未形成独立第三行**（`y=840..850 ink=0`）⇒ 200% 下底注必须**实打实排成 3 行**且第 3 行非空。
- 现状 `Space` / `Enter` 在今日计划行上命中的都是 `ActivateIntent` ⇒ **都**打开回填弹层，两条语义不可区分（这正是 K3 当初把两条从键条移除的真实原因）。

### 1. 控制器裁定（摘要；完整契约见两份派工书）

- **K1（注释订正）**：`Esc` 的来源改写成事实（框架 `WidgetsApp` 默认快捷键 + `DismissIntent`），不得再出现指不到本仓源码的 `app.dart` / `DefaultShortcuts` / `ModalRoute._DismissModalAction` 说法。
- **K2（键条最终 7 条，顺序与原型一致）**：`Ctrl+N` / `Ctrl+D` / `←→` / `Space` / `Enter` / `Esc` / `Ctrl+1…3`。
- **K3（`Space` 语义与文案）**：`Space` = **勾选 / 取消勾选**（写 `plan_item.status`：`done ⇄ pending`，`done` 时写 `done_at`）；键条文案用「勾选 / 取消勾选」，**不用**原型的「排入 / 移出今日」。
  ★ **与已获批原型的措辞差异，在此登记**：原型「已排入 X · 未排入 Y」里 `X = planDone`、`Y = planTotal - planDone`，与本应用 `done` 计数**同源**，故动作等价，文案取更准者（该行本就在今日计划里，再写「排入」会误导用户）。
- **K4（`Enter` 语义）**：在今日计划行上打开「成果 / 进展」回填弹层，**复用现有 `_editResult`**，不新造弹层。
- **K5（行级焦点）**：今日计划行**自带可聚焦节点**（行级 `Focus` + 专用 `Actions`），使 `Space` / `Enter` 不再依赖 `ActivateIntent`；焦点在 `LedgerCheckbox` 上时 `Space` **仍只切勾选**（就近优先，行级不抢）。
- **K6（未来日保护）**：`future == true` 的行**不可聚焦、不可触发**（spec §H-1）。
- **K7 / K8（`Ctrl+1…3` 与文案）**：绑定在 `app.dart` 的 `ShellHost`（`Shortcuts` + `Actions`）⇒ `Ctrl+1` 今日 / `Ctrl+2` 待办池 / `Ctrl+3` 日历；**不实现** `Ctrl+4/5/6`、**不列进键条**；文案用「切页」。
- **N1（底注口径）**：键帽 `… 6` → `… 3`；**底注字符总数必须保持 12**（`页面切换`4 + `Ctrl`4 + `+`1 + `1`1 + `…`1 + `3`1）——这是 Task 19 单测判据的锚，改文案不得改这个数。
- **N2（不得越权）**：`nav_rail.dart` 只改文案与排版，**不许**自己实现切页快捷键。
- **N3 / N4 / N5（200% 排版）**：200% 下底注排成 **3 行**且第 3 行**非空**；任何断行处**不得**产生单字符行；**不得**出现 `RenderFlex overflowed`。
- **N6（不得回退）**：Task 19 W6 的 `scaledLabelSize`（`MediaQuery.textScalerOf(context).scale(labelSize) * 1.5`）几何**不许**动回写死值。

### 2. 执行波形（写集互不重叠 ⇒ 并行）

| 单元 | 主题 | 写集（独占） |
|---|---|---|
| W1 | 键条补齐 + 注释订正 | `widgets\shell\key_bar.dart`、`pages\today_page.dart`、`app.dart` + **新建** `test\{shell_key_hints_test,plan_row_shortcuts_test,nav_shortcut_test}.dart` +（补授权）`test\shell_key_bar_test.dart` |
| W2 | 导航底注 | `widgets\shell\nav_rail.dart` + **新建** `test\nav_rail_footnote_test.dart` +（补授权）`test\shell_nav_rail_test.dart` |
| 收口 | 控制器 | 计划 / `docs\B1_验收记录.md` / `progress.md` / `handoff.md` / `reports\*` |

**补授权说明（控制器追认，派工书漏列但必需）**：`test\shell_key_bar_test.dart`（Task 19 遗留测试，原按 4 条键条断言 ⇒ 必须同步到 7 条）与 `test\shell_nav_rail_test.dart`（第 234 行断言 `KeyCap('6')` ⇒ 必须同步为 `KeyCap('3')`）。二者均**只许改断言值，不许删除既有断言**。

### 3. Step 清单

- [x] **Step 1: 契约与基线（控制器）**
  - [x] 本段写入计划（位置：`## Task 19:` 之后、`## 附录 A` 之前）
  - [x] 刷新 `reports\task20-forbidden-baseline.txt`（覆盖 `apps` / `packages` / `tools` / `docs` / `design-demos`，排除 `apps\desktop\build` / `.dart_tool` / `windows\flutter\ephemeral` 与二进制扩展名）
  - [x] 越界比对脚本 `reports\task20-forbidden-check.ps1`（**双判据**：① 相对基线的 sha 比对；② **mtime 窗口** —— Task 20 开工后被改动却不在授权清单里的文件一律算越界，用于捕捉「基线捕获之前」的越界改动）

- [x] **Step 2: W1 键条补齐（Space / Enter / Ctrl+1…3）+ 注释假引用订正**
  - [x] `kShellKeyHints` 扩到 **7 条**，顺序 = `Ctrl+N` / `Ctrl+D` / `←→` / `Space` / `Enter` / `Esc` / `Ctrl+1…3`
  - [x] 今日计划行自带可聚焦节点 + 行级 `Space`（切 `done ⇄ pending`）/ `Enter`（打开「成果 / 进展」弹层）两个 Intent，**语义互斥**
  - [x] `LedgerCheckbox` 上 `Space` 仍只切勾选（就近优先）；未来日行**不可聚焦**
  - [x] `app.dart` 绑定 `Ctrl+1/2/3` 切今日 / 待办池 / 日历；`Ctrl+4/5/6` **零效果**
  - [x] 订正 `key_bar.dart:30-31` 假引用注释（写成框架事实）
  - [x] 交付：`shell_key_hints_test.dart` / `plan_row_shortcuts_test.dart` / `nav_shortcut_test.dart` / `shell_key_bar_test.dart` 全绿，断言 **A1–A11 逐条有测**

- [x] **Step 3: W2 导航底注（…6 → …3 + 200% 第三行）**
  - [x] 键帽 `… 6` → `… 3`，底注字符总数仍 = **12**
  - [x] 200% 下底注排成 **3 行**、第 3 行**非空**、每行 ≥2 字符（无孤字）、无横向溢出
  - [x] 不回退 W6 的 `scaledLabelSize` 几何；不实现 `Ctrl+4/5/6`
  - [x] 交付：`nav_rail_footnote_test.dart` / `shell_nav_rail_test.dart` 全绿，断言 **N-1…N-6 逐条有测**

- [x] **Step 4: 控制器门禁 + 越界比对**
  - [x] `flutter analyze` 逐字 `No issues found!`（exit 0）
  - [x] desktop 全量 `flutter test`（基线 **+183**，**零回退**）
  - [x] core_data 全量 `dart test`（基线 **+141**，本轮不改 `packages\` 仍跑）
  - [x] 越界比对 `reports\task20-forbidden-diff.txt`：`VIOLATIONS=0`

- [x] **Step 5: 独立 verifier（只读，≠ 两个实现会话）**
  - [x] 复核 A1–A11 / N-1…N-6 的实测证据、越界清单、门禁数字

- [x] **Step 6: 真机 + 收口（控制器）**
  - [x] `flutter build windows --release` → `tools\build\make_installer.ps1` 打包 exe（**包内 `app.so` 指纹 + 二进制探针**要验，不只验排除模式 0 命中）
  - [x] 真机 100% / 200% 帧取证：键条 **7 条**、导航底注 **3 行**、无黄黑条（RenderFlex 溢出零命中）
  - [x] 计划复选框打勾（等长替换 `- [ ] ` → `- [x] `）；台账 `progress.md` 追加；`handoff.md` 新增 §15；`docs\B1_验收记录.md` 第 5 节处置更新

### 4. 门禁期望值（实施后以实测为准并同步回填）

- desktop 全量：Task 19 收口基线 **+183** ⇒ **零回退**
- core_data 全量：**+141** 不变
- `flutter analyze`：error / warning / **info** 全 0，逐字 `No issues found!`
- 越界：写集外改动 = **0**

### 5. 本 Task 明确不做（登记，不在本轮修）

- **字体打包**（Fraunces / Inter / JetBrains Mono / Noto Sans SC，`design-demos\TOKENS.md` §8）—— 需引入字体资源并核对许可，另立 Task。
- **真实 Windows 125% / 150% 显示缩放交叉验证** —— 需改用户系统环境并重新登录，另立 Task。
- `tool_rail.dart:130` 沿用 `IntrinsicHeight`（当前无溢出）。
- 可延后 3 项：`tools\build\make_installer.ps1:51` 白名单无逐条注释；Task 19 派工书 A4 前提已过期；`keyboard_accessibility_test.dart` 在白名单内但未实际修改。

## Task 21: 遗留项一次性收口（字体打包 / 真实显示缩放 / 键条真机取证 / spec §H-1 裁定 / 三项遗留清账）

> 本段由控制器于 2026-11-10 追加（计划内原本没有 Task 21）。
> 依据：`handoff.md` **§15「下一步」**清单 + Task 20 段 **§5「本 Task 明确不做」**。
> **实现契约**（唯一实现处，别处不得另算）：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-21-w1-brief.md`（字体打包收口，裁定 N1–N6）与 `task-21-w2-brief.md`（遗留清账，裁定 M1–M4）。
> 本段只描述**目标态与验收判据**；两个派工书即实现契约，本段与其冲突时以派工书为准。

### 0. 背景（控制器亲读磁盘与源码坐实，非转述）

- **字体资产已落地但未收口**：四族字体文件已由一个来源不明的并发写入者于 2026-11-10 12:01–12:07 落盘并接线（`pubspec.yaml` / `app_fonts.dart` / `test\font_bundle_test.dart`）。控制器 12:15 复核确认三处未收口：① `assets\fonts\licenses\` **缺 Noto Sans SC 的 OFL**（只有 Inter / Fraunces / JetBrains Mono 三族，其中 JetBrains 有一份重复文件）；② `design-demos\TOKENS.md` **§8 仍写「❗ B1 未落地（遗留项）：仓库内不存在上述四族字体文件」** —— 与事实相反；③ 守卫测试**缺「`pubspec` 的 `family:` == 字体 name 表排版族名（nameID 16）」**这条能挡「打包了但没生效」的判据。
- **真实 Windows 显示缩放交叉验证完全未做**：Task 19 / Task 20 取证用的是 `PRACTILOG_TEXT_SCALE` **文本缩放**，**不是**系统显示缩放；`docs\B1_验收记录.md` 第 5 节第 6 项登记的「200% 未实测 / 未做真实缩放」即此遗留。
- **键条 `Space` / `Enter` / `Ctrl+1…3` 已有单测**（Task 20 A1–A11），但**真机按键注入的端到端**未取证（单测行为正确 ≠ 端到端已证）。
- **spec §H-1 裁定未落纸**：`docs\superpowers\specs\2026-11-07-双端交互体验设计.md:78`「未来日期只可预排 `plan_item`，不可打卡/回填（§H-1）」，Task 18 落地判据（未来日 Checkbox `onChanged: null`、习惯打卡入口不显示）已在码内，**但「未来日行是否可交互」的裁定本身没写下来**。
- **三项遗留待清账**：`tool_rail.dart:130` 沿用 `IntrinsicHeight`；`tools\build\make_installer.ps1:51` 隐私排除白名单无逐条注释；`test\keyboard_accessibility_test.dart` 在白名单内但未实际修改；另有「Task 19 派工书 A4 前提已过期」需登记。

### 1. 控制器裁定（摘要；完整契约见两份派工书）

- **T1（字体打包收口）** —— 定位是**核验者 + 缺陷修复者**，不是重写者。硬判据：① pubspec `family:` 必须 == 字体 name 表 **nameID 16（排版族名）**（nameID 1 常是旧式名 `Inter Medium` / `Fraunces SemiBold` / `Noto Sans SC Thin`，**不可用**）；② `Noto Sans SC` 必须是 `wght=400` **静态 Regular**（可变字体默认实例是 Thin），nameID 2/17 = `Regular`；③ **四族 OFL 许可证齐全并随包分发**（缺 Noto Sans SC ⇒ 必须补，原文优先从字体 name 表 nameID 13/14 抽取，**不得凭记忆改写法律文本**）；④ 守卫测试补强到能杀红（含「同族不同 weight 不得指向字节相同的文件」「pubspec family == name 表族名」两条新判据）并做**变异验证**（改坏 → 断言变红 → 改回 → sha16 逐位一致）；⑤ `app_fonts.dart` 注释与事实对齐；⑥ `TOKENS.md` **只改 §8 那段**，改写为已落地事实。
  ★ **用户已拍板**（2026-11-10）：接受完整 CJK 字体（安装包约 21 MB）；**保留**未被引用的 `NotoSansSC-400.ttf`（34 KB）与 `NotoSansSC-VF.ttf`（17.7 MB）—— **本轮禁止删除任何文件**。
- **T2（真实显示缩放交叉验证）** —— **用户已授权**临时改 `HKCU\Control Panel\Desktop\LogPixels`（144 → 120 → 96），**测完必须恢复 144 并复测**。判据：真机 125% 与 100% 两档帧下，界面无错位/裁切/重叠，且**必须先坐实「`LogPixels` 改动对 DPI-aware 应用确实生效」**。⚠ **`PRACTILOG_TEXT_SCALE` 不是显示缩放**，不得拿它冒充本项证据；若本会话内改 `LogPixels` 无法生效（需注销/重登），**如实登记为「未做 + 遗留」**，不得用任何替代手段充数。
- **T3（键条真机按键注入取证）** —— 对 `Space` / `Enter` / `Ctrl+1` / `Ctrl+2` / `Ctrl+3` 做**真实按键注入**的端到端取证（沿用 Task 19 的启动 → 移窗 → 截屏 → OCR 三件套），逐条留下「注入的键 → 屏幕上的可观测结果」证据；`Ctrl+4/5/6` 须验证**零效果**。
- **T4（spec §H-1 裁定）** —— 方向已定：未来日**只可预排、不可打卡/回填** ⇒ 当前实现（未来日行 `canRequestFocus=false`、`onTap=null`、未来日 Checkbox `onChanged: null`）**合规**。本项**只做文档裁定 + 登记**，不改码（若 worker 发现实现与该裁定冲突，按派工书口径处理）。
- **T5（三项遗留清账）** —— ① `tool_rail.dart:130` 的 `IntrinsicHeight`：**默认不改**，除非能证明替代实现视觉与等高语义完全等价、有测试钉死、不引入 `RenderFlex overflow`；否则保留代码 + 给实测依据。② `make_installer.ps1:51` 白名单**逐条注释**（改后当场实测：**纯 ASCII + CRLF + 无 BOM** 三项）。③ `keyboard_accessibility_test.dart` 白名单条目结清（改或说明为何不改）。④ Task 19 派工书 A4 前提过期 ⇒ 登记。
- **T6（收口台账 + 新安装包 + 分发禁令更新）** —— `flutter build windows --release` → `tools\build\make_installer.ps1` 打包；**包内 `app.so` 指纹 + 字体资产 + 许可证逐项核对**；更新 `docs\B1_验收记录.md` 第 5 节遗留处置、`progress.md`、`handoff.md` §16、计划本段复选框（**等长替换** `- [ ] ` → `- [x] `，含两空格缩进项，字节数不变）。

### 2. 执行波形（写集互不重叠 ⇒ 并行）

| 单元 | 主题 | 写集（独占） |
|---|---|---|
| W1 | 字体打包收口 | `apps\desktop\assets\fonts\**` + `apps\desktop\pubspec.yaml` + `apps\desktop\lib\src\theme\app_fonts.dart` + `apps\desktop\test\font_bundle_test.dart` + `design-demos\TOKENS.md` §8 + `reports\task21-w1-worker-report.md` |
| W2 | 三项遗留清账 | `apps\desktop\lib\src\widgets\shell\tool_rail.dart` + `apps\desktop\test\keyboard_accessibility_test.dart` + `tools\build\make_installer.ps1` + `reports\task21-w2-worker-report.md` |
| 收口 | 控制器 | 计划 / `docs\B1_验收记录.md` / `progress.md` / `handoff.md` / `reports\task21-*` |
| 收口补 | 控制器（**写集显式追加**） | `apps\desktop\test\plan_row_shortcuts_test.dart`（A8/A9 补测，原不在本表 ⇒ 本轮控制器裁定纳入，留档 `reports\task21-closeout.md` §5）+ `reports\task21-a8-traversal.txt` + `reports\task21-a9-traversal.txt` + `reports\task21-a9-{analyze,desktop-full,core-data}.txt` + `reports\task21-closeout.md` |

### 3. Step 清单

- [x] **Step 1: 契约与基线（控制器）**
  - [x] 本段写入计划（位置：`## Task 20:` 之后、`## 附录 A` 之前）
  - [x] 越界比对基线刷新（覆盖 `apps` / `packages` / `tools` / `docs` / `design-demos`，排除 `apps\desktop\build` / `.dart_tool` / `windows\flutter\ephemeral` 与二进制扩展名）
  - [x] 源码树稳定性确认（无并发写入者残留进程与半写文件）

- [x] **Step 2: W1 字体打包收口**
  - [x] N1 族名一致性：`pubspec` `family:` == name 表 nameID 16（nameID 1 交叉）
  - [x] N2 `Noto Sans SC` 为 `wght=400` 静态 `Regular`（nameID 2/17 = `Regular`，非 `Thin`）
  - [x] N3 四族 OFL 齐全并随包分发（**补 Noto Sans SC**；JetBrains 重复文件按「不删、可合并」口径处理并说明）
  - [x] N4 守卫测试补强 + **变异验证**（每条新判据改坏即红、改回 sha16 逐位一致）
  - [x] N5 `app_fonts.dart` 注释与事实对齐（含 CJK 兜底族随包自带）
  - [x] N6 `design-demos\TOKENS.md` §8 遗留段落改写为已落地事实（只改 §8）

- [x] **Step 3: W2 三项遗留清账**
  - [x] M1 `tool_rail.dart:130` `IntrinsicHeight` 裁决（默认保留 + 实测依据；若改须等高语义等价 + 有测试钉死 + 无 `RenderFlex overflow`）
  - [x] M2 `make_installer.ps1:51` 白名单逐条注释 + 改后实测**纯 ASCII / CRLF / 无 BOM**
  - [x] M3 `keyboard_accessibility_test.dart` 白名单条目结清（改或说明为何不改）
  - [x] M4 Task 19 派工书 A4 前提过期 ⇒ 登记

- [x] **Step 4: 控制器门禁 + 越界比对**
  - [x] `flutter analyze` 逐字 `No issues found!`（error / warning / **info** 全 0）
  - [x] desktop 全量 `flutter test`（Task 20 基线 **+207**，**零回退**）
  - [x] core_data 全量 `dart test`（**+141**，本轮不改 `packages\` 仍跑）
  - [x] 越界双判据比对（sha diff + mtime 窗口）⇒ `VIOLATIONS=0`

- [x] **Step 5: 独立 verifier（只读，≠ W1 / W2 实现会话）**
  - [x] 复核 N1–N6 / M1–M4 的实测证据、越界清单、门禁数字

- [x] **Step 6: 真机取证（控制器）**
  - [x] `flutter build windows --release` → `tools\build\make_installer.ps1` 打包 exe
  - [x] 包内核对：`app.so` 指纹、**四族字体 + 四份 OFL 确实在包内**、隐私排除零命中
  - [ ] T2 真实显示缩放：**先坐实 `LogPixels` 改动生效**（记 `GetDpiForWindow` 前后值），再取 125% / 100% 两档帧；**测完恢复 144 并复测**
  - [x] T3 键条按键注入端到端：`Space` / `Enter` / `Ctrl+1` / `Ctrl+2` / `Ctrl+3` 逐条取证，`Ctrl+4/5/6` 零效果
  - [x] 字体渲染帧：确认界面真用上了 Fraunces / Inter / JetBrains Mono / Noto Sans SC（而非静默回退系统字体）

- [x] **Step 7: 收口（控制器）**
  - [x] 计划复选框打勾（等长替换 `- [ ] ` → `- [x] `，含两空格缩进项；sha16 当场重测）
  - [x] `progress.md` 追加、`handoff.md` 新增 §16、`docs\B1_验收记录.md` 第 5 节遗留处置更新、新安装包路径与指纹登记

### 4. 门禁期望值（实施后以实测为准并同步回填）

- desktop 全量：Task 20 收口基线 **+207** ⇒ **零回退**
- core_data 全量：**+141** 不变
- `flutter analyze`：error / warning / **info** 全 0，逐字 `No issues found!`
- 越界：写集外改动 = **0**

### 5. 本 Task 明确不做（登记，不在本轮修）

- 不动 `packages\**`（schema v1 冻结、不升版本、不改 `core_db` 列定义）。
- 不删除任何字体文件（`NotoSansSC-400.ttf` / `NotoSansSC-VF.ttf` / 任一份许可证）—— 用户已拍板保留。
- 不实现 `Ctrl+4/5/6`、不实现未来日打卡/回填（spec §H-1 只许预排）。
- 不改 `design-demos\TOKENS.md` §1–§7（视觉口径唯一真源，改动只许落在 §8 那一段）。
- 不以 `PRACTILOG_TEXT_SCALE` 文本缩放冒充系统显示缩放证据。
- 不做真实安装/卸载链路验证（沿用 Task 17–20 口径：只验包内产物与真机运行）。

## Task 26: 行级焦点环（台账 `docs\B1_验收记录.md` §5 **#17** · 键盘可见性缺口）

**背景**：今日页计划行的**行级** `Focus`（`apps\desktop\lib\src\pages\today_page.dart:470`）**没有任何可见焦点环** ⇒ 键盘用户 Tab 到计划行时看不见焦点落在哪一行。全库只有 `LedgerCheckbox`（22×22）与 `ChipRow` 芯片自带 `FocusRing`。本 Task **只补可见性，不改任何键位语义**。

**口径（唯一真源）**：`design-demos\TOKENS.md` §5「焦点环 = `outline:2px solid var(--ink)`」；§1.5 明令焦点环**不得**用赭石。⇒ 行级焦点环**复用既有 `FocusRing` 组件**（`--ink` 2px），**零新增视觉口径**，**不改 TOKENS §1–§7**。

**就近优先**：行级环**只在行自己持有主焦点时**点亮；焦点落到行内 `LedgerCheckbox` 上时**只**亮复选框自己的环（父子不双亮）—— 与 Task 20 / K5「就近优先」同一口径。

**写集表**

| 角色 | 独占路径 |
| --- | --- |
| worker | `apps\desktop\lib\src\widgets\focus_ring.dart` |
| worker | `apps\desktop\lib\src\pages\today_page.dart` |
| worker | `apps\desktop\test\plan_row_focus_ring_test.dart`（新建） |
| 控制器 | 计划本段 / `docs\B1_验收记录.md` / `progress.md` / `handoff.md` / `reports\task26-*` / `AGENTS.md` R3 |

**派工书（唯一实现契约）**：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-26-w1-brief.md` —— **冲突时以派工书为准**。

**Step**

- [x] S1 扩展 `FocusRing`：加 `ringKey` + `requirePrimaryFocus` 两个可选参数（**默认行为逐字不变**）
- [x] S2 `_PlanItemTile` 的行级 `Focus` 内层接上 `FocusRing`（行级专属 ringKey）
- [x] S3 新建 `plan_row_focus_ring_test.dart`，落地 T1–T6 六条断言
- [x] S4 R5 变异自证（摘掉行级环 ⇒ T1 / T2 / T3 必须变红）并**逐字节还原**
- [x] S5 门禁：desktop `analyze` 逐字 `No issues found!` + 全量 **≥ +231**；core_data **+141**；越界 `VIOLATIONS=0`
- [x] S6 独立 verifier 复核（**≠ 实现者会话**）
- [x] S7 计划复选框打勾（等长替换 `- [ ] ` → `- [x] `）；台账 `progress.md` / `handoff.md` / `reports\task26-closeout.md`
- [x] S8 重打包 `release\PractiLog-Setup-1.0.0_<ts>.exe` + 包内核对（字体 / 许可 / `app.so` / 隐私零命中）+ **同步更新 `AGENTS.md` R3 与 `docs\B1_验收记录.md` A.1 两处**

**门禁期望**：desktop 全量基线 **+225** ⇒ 本 Task 后 **≥ +231**（+6 条新断言，零回退）；core_data **+141**（不碰该包）；`analyze` 逐字 `No issues found!`；越界 `VIOLATIONS=0`。**产品代码有改动 ⇒ 必须重打包并更新分发禁令（R3）**。

---

## Task 32: 品牌图标上机替换（Set I / I03 ⇒ APP 图标 + 任务栏图标 · 用户当轮指令）

**背景**：用户 2026-11-11 拍板「选定第三幅图作为 logo，请使用这个 logo 制作 APP 的图标，在 APP 中进行替换。任务栏图标也使用重新制作的图标」。「第三幅图」= `design-demos\logo-set-i-bowl-overlap-2026-11-11\I03-bowl36-navy-hard-plate.svg`（叠 36 · 无 halo 硬压 · 碗 = 深蓝 `#0E2A4A`）。取景决策：任务栏/托盘只有 16–40px，wordmark 读不出叠印 ⇒ 只取 I03 签名部件「a」做方形 tile，部件/颜色/层序/叠量逐字继承母图。

**新真源**：`tools\icons\make_brand_icon.py`（暂存模式默认写 `reports\task32-icon\`，`--apps` 才写 `apps\`）。旧 `tools\icons\make_app_icon.py` 按 R4 保留不删 —— **Task 33 已改名 `tools\icons\make_app_icon_legacy.py`（标 LEGACY、输出重定向到 `tools\icons\_legacy_output\`）**，其 ICO 写入器已抽出为 `tools\icons\ico_writer.py`，由 `make_brand_icon.py` 复用；发布链与遗留脚本零耦合。

**写集表**

| 角色 | 独占路径 |
| --- | --- |
| worker W1 | `apps\desktop\windows\runner\resources\app_icon.ico`（exe/窗口类图标 ⇒ 任务栏、Alt-Tab、快捷方式、安装器） |
| worker W2 | `apps\desktop\assets\icon.png`（托盘） |
| worker W3 | `apps\desktop\pubspec.yaml`（仅第 48 行注释指向新真源，字节级零其它改动） |
| 控制器 | `tools\icons\make_brand_icon.py` / `reports\task32-icon\**` / `reports\task32-*.ps1` / `design-demos\logo-set-i-**` / 计划本段 / `handoff.md` / `progress.md` / `docs\B1_验收记录.md` / `AGENTS.md` R3 |

**派工书（唯一实现契约）**：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-32-icon-brief.md`。

**Step**

- [x] S1 控制器生成暂存资产 + manifest（sha16）并目检 `sizes.png`
- [x] S2 按 R8 派 worker 拷贝暂存字节进 `apps\`（备份进 `reports\task32-icon\prev\`、逐文件 sha16 校验）
- [x] S3 控制器 `Get-FileHash` 独立复核落盘字节与备份（不采信自报）
- [x] S4 门禁 `reports\task32-icon-gate.ps1`：analyze / desktop 全量零回退 / core_data +141 / 越界 `VIOLATIONS=0` / 指纹三项
- [x] S5 重打包 `flutter build windows --release` + `make_installer.ps1 -Version 1.0.0 -SkipBuild` ⇒ 新 `release\PractiLog-Setup-1.0.0_20261111-200220.exe`（15751450 B / sha16 `7548437DFF693BF5` / mtime 20:02:46；`BUILD_EXIT=0` + `makensis_exit=0`，日志 `reports\task32-icon\chain-out.txt`）
- [x] S6 真机取证 —— **部分成立，像素层未判定**：① 判据自证 `[A0]` 旧 ICO `green=897 navy=0`（先证明分类器能看见旧绿图标）；② `[A2] ExtractAssociatedIcon(装机 exe)` 装机前 `897/0` → 装机后 `0/306` ⇒ **exe 内嵌图标（任务栏按钮 / Alt-Tab / 快捷方式图标的唯一来源）运行时已换新**；③ 静默装机 `VERDICT_INSTALL=REPLACED`（`EXE_REPLACED=True` + `TRAY_REPLACED=True`，装机 `icon.png` = `13186 B / D575702F4BB9B771`）；④ 两轮 `[B0] VERDICT=ON_DEFAULT_DESKTOP`。**未判定**：任务栏按钮区成对全屏帧逐像素比对，整条任务栏带唯一差异 bbox `x=2489..2529 / y=1385..1397`（41x13）目检 = **系统时钟 `20:09:39 → 20:10:03`**，非图标；`x=48` 与 `x=950` 两处裁剪两帧均纯背景零按钮（`navy=50400 total=50400` 已饱和 ⇒ 无判别力，连开始按钮都不在帧里）⇒ 该取图方式对 Win11 任务栏按钮整体不可见，脚本自打的 `VERDICT=ICON_SIZED_DIFF` 属**假阳性**，按 R5 既不判 PASS 也不判 FAIL。重取方法见 `handoff.md` §25.10.1
- [x] S7 R3 三处同步（`AGENTS.md` R3+§7 / `docs\B1_验收记录.md` Task 32 流水 + 附录 A.2 / `reports\task26-closeout.md` §9）+ `handoff.md` §25.10.1 收口段 + `progress.md`

**门禁期望**：`analyze` 逐字 `No issues found!`；desktop 全量 **≥ +269**（本轮不新增测试，零回退即合格）；core_data **+141**；越界 `VIOLATIONS=0`。**产品资产有改动 ⇒ 必须重打包并更新分发禁令（R3）**。

**注意**：新旧 ICO 同为 381038 B 属必然（同 9 档同布局），**尺寸不构成证据**，判据只认 sha16。


---

## Task 33 · 全面改名 `actlog` + 图标闭合 + GitHub 仓库改名（2026-11-11）

**用户当轮指令**：① 启动后任务栏图标与 app 左上角图标仍是旧的 → 修；② 软件中凡出现旧名称 `practilog` 处全改 `actlog`；③ GitHub 仓库 `practilog` → `actlog`。

**写集表**

| 角色 | 独占路径 |
| --- | --- |
| worker A | `apps\desktop\lib\**`、`apps\desktop\test\**`、`apps\desktop\pubspec.yaml`、`packages\**` |
| worker C | `tools\build\**`、`tools\installer\**`、`tools\verify\**`、`tools\icons\**` |
| worker D | `tools\bootstrap.ps1`、`tools\gates\g3_migration.ps1` + 4 处文档引用 |
| worker T2 | `apps\desktop\lib\src\widgets\shell\app_top_bar.dart`、`apps\desktop\assets\brand_mark.png`、`apps\desktop\pubspec.yaml` assets 段、`apps\desktop\test\app_top_bar_test.dart`、`apps\desktop\README.md` |
| worker T7 | `apps\desktop\windows\runner\Runner.rc`、`apps\desktop\lib\src\toast_probe.dart` |
| worker T6 | `apps\desktop\build\**`、`release\payload_*`（构建产物） |
| 控制器 | `AGENTS.md` / `README.md` / `pubspec.yaml` / `docs\**` / `reports\task33-*` / 计划本段 / `handoff.md` / `progress.md` |

**派工书（唯一实现契约）**：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-33-brief.md` 及 `task-33-{t2,t5,t6}-brief.md`。

**Step**

- [x] T0 GitHub 改名：`gh repo rename actlog --repo kizemo/PractiLog --yes` ⇒ `kizemo/actlog`
- [x] T1 worker A：81 文件机械改名 + legacy 兼容（`app_paths.dart` 新旧并存搬迁）+ `legacy_compat_test.dart` 13 条
- [x] T2 worker：顶栏品牌图标改真图（`assets\brand_mark.png` + 删 `_BrandMarkPainter`）
- [x] T3 worker C：安装链全量重写（`installer.nsi` legacy 升级段 + `make_installer.ps1` 必需 `actlog.exe` + `tools\verify` 13 脚本双查）
- [x] T4 worker D：`tools\` 残留旧名清零 + 文档引用改指 `make_brand_icon.py`
- [x] T5 worker T7：源码残留旧名字节级清零（`Runner.rc` / `toast_probe.dart`）
- [x] T6 门禁 + 构建 + 打包 ⇒ `release\actlog-Setup-1.0.0_20261111-220332.exe`（15778514 B / sha16 `169D24D160ACA4D5`）
- [x] T7 真机覆盖装机（`INSTALLER EXIT=0`，旧 exe 已删、`userdata` 四文件保留）+ 任务栏成对帧差异带 + app 左上角真机目检 ⇒ **Task 32 遗留「未判定」闭合**
- [x] T8 R3 三处同步（`AGENTS.md` R3 / `README.md` / 本文件 Task 33 段 + 附录 A.2）+ `handoff.md` §26 + `progress.md`

**门禁期望**：`analyze` 逐字 `No issues found!`；desktop 全量 **+306**；core_data **+141**；越界 `VIOLATIONS=0`。

---

## Task 34 · 安装目录改名 + 顶栏去英文 + 右轨两模块拆分（2026-11-11 夜）

**用户当轮四条**：① 安装目录名一并改为 `actlog`（连目录一起换）；② 顶栏 logo 右侧的 `actlog` 文字去掉，
并适当增加 logo 顶部距离；③ 右轨上部第一栏目设为「待办列表」、第二个模块保持「习惯速览」，
两个模块右上角各加一个加号按钮（弹窗添加待办 / 习惯），去掉当前把待办与习惯混在一起的第一个模块；
④ 词标 / 纸底拍板问卷重发（控制器已发）。

**派工书（唯一实现契约）**：`.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-34-brief.md`

**写集表**

| 角色 | 独占路径 |
| --- | --- |
| worker A | `apps\desktop\lib\src\widgets\shell\app_top_bar.dart`、`apps\desktop\test\app_top_bar_test.dart` |
| worker B | `apps\desktop\lib\src\widgets\shell\tool_rail.dart`、`apps\desktop\lib\src\widgets\timeline\todo_rail_panel.dart`、`apps\desktop\lib\src\app.dart`、`apps\desktop\lib\src\pages\today_page.dart`、`apps\desktop\lib\src\widgets\habit_quick_dialog.dart`（新建）、`apps\desktop\test\rail_todo_list_test.dart`（新建） |
| worker C | `tools\build\installer.nsi`、`tools\build\make_installer.ps1`、`tools\verify\*.ps1`、`tools\installer\**` |
| worker D（**写集显式追加**，先例同 Task 21「收口补」行） | `apps\desktop\test\timeline_day_grid_test.dart` —— Part B 拆模块后该文件夹具仍只挂 `TodoRailPanel`、仍用旧 key `rail-habit-<id>`，3 例回归；原不在写集表 ⇒ 控制器裁定纳入并留档，派工书 `.superpowers\sdd\2026-11-07-b1-flutter-implementation\task-34-d-brief.md` |
| 控制器 | 计划本段 / `AGENTS.md` / `docs\**` / `handoff.md` / `progress.md` / `reports\task34-*` |

**Step**

- [x] T0 控制器：派工书 + 计划本段 + 词标/纸底问卷重发
- [x] T1 worker A：顶栏去 `actlog` 字 + logo 顶边距 8px → 11–13px（可测）
- [x] T2 worker B：右轨面板头动作位 + 「待办列表」/「习惯速览」拆分 + 两个 ＋ 弹窗 + 习惯拖拽源补位
- [x] T2b worker D：修 `timeline_day_grid_test.dart` 夹具回归（挂 `HabitOverviewPanel` + key 改 `overview-habit-<id>`）
- [x] T3 worker C：安装目录 `practilog` → `actlog`（改名式升级，`userdata` 零丢失）
- [x] T4 门禁（先挪 `build\test_cache\build`）：`analyze` 逐字 `No issues found!` / desktop 全量 / core_data 全量 / 越界 `VIOLATIONS=0`
- [x] T5 构建 + 打包 ⇒ `release\actlog-Setup-1.0.0_<ts>.exe`（旧包降为历史包，R3 同步三处）
- [x] T6 真机覆盖装机（先停进程）⇒ 旧目录 `D:\Program Files\practilog` **ABSENT**、新目录 `D:\Program Files\actlog` 在位、`userdata` 四文件哈希 SAME
- [x] T7 真机目检：顶栏无 `actlog` 字 + logo 顶边距；右轨「待办列表」/「习惯速览」两枚 ＋ 按钮
- [x] T8 R3 三处同步 + `handoff.md` §27 + `progress.md` + `docs\B1_验收记录.md`

**门禁期望**：`analyze` 逐字 `No issues found!`；desktop 全量 **+312**（Task 33 基线 +306 ＋ worker A 顶栏几何新增 2 条 ＋ worker B 右轨新文件 4 条；零回退）；core_data **+141**；越界 `VIOLATIONS=0`。

---

## Task 35 · 开源入库 / 循环任务 / 四维优先级标记 / 去页头标题（2026-11-11 夜 – 11-12 凌晨）

**用户当轮 4 条**：

1. commit，push 到 GitHub 仓库，并撰写 README 文档，详细写出项目的优势、特点、价值；
2. 再增加一类任务：**循环任务**，点击添加可设定每周哪些天（是否只工作日）、几点钟执行；循环任务添加后**自动填入每天的计划中**；右侧边栏「习惯列表」模块**下面**添加「循环任务」列表模块，同样在右上角加添加按钮；
3. 添加待办、计划时可点选**四维度**（重要、不重要、紧急、不紧急），对四个维度设计**四个不同标记**，在计划**名称前面**显示；
4. **去除「闭环环」模块下面的标题模块**，包括「今日」、日期、星期，以及这一行中的两个按钮「完整」「极简」。

**派工书（唯一实现契约）**：`.superpowers\sdd\2026-11-11-b1-task35\brief.md`

**写集表**（R1：控制器零改 `apps\` / `packages\`，全部经 worker 子会话落笔）

| 角色 | 独占路径 |
| --- | --- |
| worker A（去页头 + 四维标记） | `apps\desktop\lib\features\day\**`、`apps\desktop\lib\widgets\priority_marker.dart`、`apps\desktop\lib\features\day\widgets\unscheduled_strip.dart`、对应 test |
| worker B（四维标记补齐未排期区） | `apps\desktop\lib\features\day\widgets\unscheduled_strip.dart`、`apps\desktop\test\**`（追加用例） |
| worker C（循环任务主体） | `packages\core_db\lib\src\tables.dart`、`packages\core_db\lib\src\database.dart`、`packages\core_db\test\**`、`packages\core_data\lib\src\recurring.dart`（新建）、`packages\core_data\test\recurring_test.dart`（新建）、`apps\desktop\lib\features\recurring\**`（新建）、`apps\desktop\lib\features\right_rail\**` |
| controller（仅台账） | `README.md`、`.gitignore`、`AGENTS.md`、本计划文件、`docs\B1_验收记录.md`、`.superpowers\sdd\**\handoff.md`、`reports\task35-*` |

**Step**

- [x] T0 读规范与状态（`AGENTS.md` 全文 / `task34-closeout.md` / `handoff.md` §27 / `B1_验收记录.md` Task 34 流水 / 本计划 Task 34 段）
- [x] T1 `.gitignore` 新建并补全（80 行 / 2785 B，含 `__pycache__/`、`*.pyc`、`*.pyo`、`*.obj` 四项）
- [x] T2 `git init -b main` → `remote add origin https://github.com/kizemo/actlog.git` → `fetch` → `reset --soft origin/main`（首提交挂在远端 `Initial commit d03ce96` 之上，**不 force-push**）
- [x] T3 `git rm -r --cached -f` 清掉 3 个垃圾文件（`tools/icons/__pycache__`、`tools/spike/t_probe.obj`），磁盘文件按 R4 保留 ⇒ `TRACKED=299` / `DELETED=0` / `UNTRACKED=0`
- [x] T4 worker A：去页头标题模块（`_PageHead` + `_ModeSwitch`，保留 `log.mode` / `dayModeMinimal` 数据语义）
- [x] T5 worker A/B：四维优先级标记 `▲`(重要) / `▽`(不重要) / `◆`(紧急) / `◇`(不紧急)，渲染在名称**前面**，`quadrant == null` 不渲染不留位；未排期带 `UnscheduledStrip` 同步补齐
- [x] T6 worker C：`recurring_task`（`weekday_mask` 周一=bit0…周日=bit6、`start_minute` 0–1439、`duration_minutes`、`active`、`deleted_at`）＋ `recurring_occurrence`（`UNIQUE(task_id, date)` 幂等）；`currentSchemaVersion` 1→2；物化时机 = 应用启动 + 选中日期变化；右轨模块插在「习惯速览」之后
- [x] T7 worker C 收尾：`raw.dispose()` → `raw.close()`、过期注释订正、`oplog_writer` 同步白名单补齐（12 → 12 张同表，新增两表不写 oplog 的决策登记于 brief）
- [x] T8 新建 `reports\task35-forbidden-check.ps1`（基线固定 `2026-11-11T23:30:00`，白名单 27 条）并实跑 ⇒ `VIOLATIONS=0` / `BOUNDARY_VERDICT=PASS`
- [x] T9 门禁九步全绿（见下）
- [x] T10 提交 `f460fc4` + `push -u origin main`（`d03ce96..f460fc4`，`ls-remote` 一致）
- [x] T11 `README.md` 全文重写（21488 B / 340 行，13 个二级标题，11 个链接目标逐一 `Test-Path=True`）
- [x] T12 首包装机包 `release\actlog-Setup-1.0.0_20261112-000727.exe` 产出后**判为坏包**（见「已知问题」①），已重建完成（见 T13）
- [x] T13 重建 release 树（`flutter build windows --release`，44.9 s）后重打包 ⇒ `release\actlog-Setup-1.0.0_20261112-000947.exe`（15818676 B / sha16 `6CDFAA16D8D23130`），抽包 `data\app.so` = `4B756691A48DA94A` 与构建目录逐字相同
- [ ] T14 真机目视：四维字形 `▲▽◆◇` 不缺字、循环任务「自动填入每天计划」可见
- **T14 进展（2026-11-12 19:05–19:50，控制器直做 + worker 派工）**：
  - **装机 PASS**：`release\actlog-Setup-1.0.0_20261112-000947.exe` 静默装机 `INSTALLER_PID=95756 EXIT=0`；装机副本 `data\app.so` sha16 `4B756691A48DA94A` **与构建产物逐字相同** ⇒ 新代码确在机（`INSTALLED_APPSO_MATCHES_BUILD=1` / `INSTALLED_APPSO_MATCHES_NEW=1`）。live 库 `D:\Program Files\actlog\userdata\actlog.db` 迁移到 `USER_VERSION=2`，`recurring_task` / `recurring_occurrence` 两表就位（含 `CHECK`、`UNIQUE (task_id, date)`、FK）；`plan_item.quadrant` 的 CHECK 合法值实测为 **`'Q1'|'Q2'|'Q3'|'Q4'`**（写 `'q1'` 会报 `plan_item_quadrant_check (19)`）。
  - **循环任务「自动填入每天的计划」= PASS（数据层实证，真机装的包上）**：播种 2 条 `recurring_task`（`weekday_mask=127` 每日 08:30；`weekday_mask=8` 仅周四 19:00）后重启 app ⇒ `recurring_occurrence` 写入 **2 行**（`t35-rec-1|2026-11-12`、`t35-rec-2|2026-11-12`），并各生成 1 条 `plan_item`（`source_id=t35-rec-1`、`planned_start=1794443400000` = 2026-11-12 08:30、`planned_end` = +30 min）⇒ 「添加后自动填入每天的计划」成立。
  - **四维字形字体覆盖 = PASS**：对**随包字体文件**做 TTF cmap 直解（`reports\task35-glyph-cmap.py`，纯 stdlib）⇒ `Inter-400.ttf` / `Inter-500.ttf`（应用首选正文字体）**不含** `▲▽◆◇`（cmap 仅 230 码位），`NotoSansSC-Regular.ttf`（`AppFonts.bodyFallback` 首项）**四个码位全部命中**（30890 码位）⇒ 真机由 Noto Sans SC 兜底，不会缺字。（GDI `GetGlyphIndicesW` 对 5 个字体给出**相同** GID ⇒ 无字体特异性，已弃用作判据。）
  - **四维字形渲染层 = PASS（真实字体的 PNG，控制器肉眼核验）**：worker 新增 `apps\desktop\test\task35_glyph_render_test.dart` —— `FontLoader` 注册与 `AppFonts` **逐字一致**的族名（`Inter` + `Noto Sans SC`）→ 用**真实行 widget** `UnscheduledStrip` 排 5 行（Q1–Q4 + `quadrant==null`）→ `RenderRepaintBoundary.toImage(pixelRatio: 2.0)` 落 PNG。**肉眼核验：▲◆ / ▲◇ / ▽◆ / ▽◇ 四枚字形全部正常渲染、无豆腐块；未分级行 0 枚标记** ⇒ 渲染层 PASS。产物 `apps\desktop\build\task35-t14\task35_glyph_render.png`（43408 B / sha16 `660916AD45582185`）。worker 首轮 `flutter analyze` 报 2 条 import 问题（`dart:typed_data` 冗余 / `core_domain` 未用），改完复跑**逐字 `No issues found!`**；本轮门禁单跑该文件 `GLYPH_RENDER_TEST_EXIT=0 / COUNT=2`。
  - **真机窗口像素 = 未取到，原因坐实为「工作站锁屏」**：`GetLastInputInfo` 空闲 **70855 s（≈19.7 h）**、`OpenInputDesktop` → `ACCESS_DENIED`、`GetForegroundWindow()` → 0、`qwinsta` console session 1 = Active 但会话内可见窗口枚举为空 ⇒ DWM 从不合成 actlog 窗口。四条取帧通道逐条实测：`GetDC(NULL)`+`BitBlt` ⇒ **纯黑**；`GetDC(hwnd)`+`BitBlt` ⇒ **锁屏画面**；`PrintWindow` flag 0/1/2/3 ⇒ **空白**；`FLUTTERVIEW` 子窗 DC + `PrintWindow` ⇒ **锁屏画面**（Windows 登录用户头像 + Rime `WeaselServer.exe` 报错框）。**均非 app 像素 ⇒ 不登记为「已目视」**。已备一键补取脚本 `reports\task35-t14-live-demo.ps1`（播种 → 重启 → 断言物化 → 抓真窗 FLUTTERVIEW → 裁剪 → 清理），**解锁后一条命令即可闭合**。
  - **live 库复原**：验证后按 `origin_device_id='task35-t14-test'` 与 `source_id IN (t35-rec-*)` 全量删除 ⇒ `plan_item=1 / recurring_task=0 / recurring_occurrence=0`（与验证前一致）；唯一变化是 `oplog` 由 9 增至 **17** —— 那是 app 在真机验证时为播种数据写入的**真实同步流水**，**未做人工删除**（审计链不可断）。
- [x] T15 R3 三处同步（`AGENTS.md` R3 + §7 / `README.md` / `handoff.md` §28）+ `docs\B1_验收记录.md`

**门禁期望**：`flutter analyze` 逐字 `No issues found!`（error/warning/info 全 0）；desktop 全量 **+330**（Task 34 基线 +312 ＋ 去页头/四维标记/循环任务新增 16 条 ＋ T14 渲染取证新增 2 条；Task 35 收口时为 +328）；core_data **+151**（原 +141 ＋ `recurring_test.dart` 10 条）；core_db **+71**（本轮**首次**纳入门禁，schema 1→2 的直接判据）；`VIOLATIONS=0`；G3 `0 FAIL`。

**T14 门禁实跑（2026-11-12 19:43–19:50，`reports\task35-t14-gate.txt`）**：**`GATE_VERDICT=PASS`** —— `ANALYZE_LITERAL=1` / `ANALYZE_ISSUE_LINES=0`、desktop **`+330`**、`GLYPH_RENDER_TEST_EXIT=0 / GLYPH_RENDER_TEST_COUNT=2`、PNG 43408 B / sha16 `660916AD45582185`、三包 `dart analyze` 逐字干净、core_db **71**、core_data **151**、`G3_FAIL_LINES=0`、`VIOLATIONS=0` / `PACKAGES_TOUCHED=0` / `BOUNDARY_VERDICT=PASS`、`FLUTTER_LOCK_SEEN=0`。本轮越界判据用**新写的** `reports\task35-t14-forbidden-check.ps1`（白名单补 worker 新增的渲染取证测试文件），旧 `task35-forbidden-check.ps1` 按 R4 原样保留。

**已知问题（如实登记）**

① **首包打的是旧代码**：`make_installer.ps1` 自带 `NOTE: this script never invokes flutter/dart; it always packages the existing release tree.` ⇒ 它**不会**替你编译。首包 `..._20261112-000727.exe`（15782107 B）实测 `data\app.so` mtime 仍为 `22:54:26`、sha16 `D9ACE771340DF3F3`（= Task 34 基线），而本轮源码最晚 `00:00:32` ⇒ 包内是旧代码；旁证：包体积与旧包 `..._20261111-225703.exe` **逐字节相等**（15782107 B）。⇒ 打新包前必须先跑 `flutter build windows --release`，脚本已固化为 `reports\task35-rebuild-installer.ps1`。

② `docs\` 不改 ⇒ 无权威 `schema_v2.sql` 作第二份 DDL 对照，`schema_consistency_test.dart` 改用「v1 的 14 张逐项比对 ＋ 白名单放行两张新表 ＋ 索引集合校验」替代。

③ 四维字形 `▲▽◆◇` 在 widget 测试里跑的是 Ahem 字体，**无法证明真机字体不缺字** ⇒ 必须一次装机目视。**（2026-11-12 19:5x 更新：装机已完成，随包字体 TTF cmap 直解证明 `Noto Sans SC` 四个码位全命中 ⇒ 缺字风险已排除；**渲染层 PNG 取证已完成并肉眼核验通过**（`apps\desktop\test\task35_glyph_render_test.dart` 加载真实字体渲染 5 行，▲◆ / ▲◇ / ▽◆ / ▽◇ 四枚字形全部正常、无豆腐块）；**唯独「真机窗口像素」仍缺**，原因是工作站锁屏而非产品缺陷 —— 解锁后跑 `reports\task35-t14-live-demo.ps1` 即可补齐。）**

---

## 附录 A：命令清单（按执行顺序）

```powershell
# 0) 中国镜像（每个新 shell 都要设）
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'

# 1) 纯 Dart 包单测
Set-Location F:\soft\00selfmade\practilog\packages\core_domain; dart test
Set-Location F:\soft\00selfmade\practilog\packages\core_data;   dart test

# 2) 桌面端
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact

# 3) 门禁
& F:\soft\00selfmade\practilog\tools\gates\g1_analyze.ps1
& F:\soft\00selfmade\practilog\tools\gates\g2_unittest.ps1
& F:\soft\00selfmade\practilog\tools\gates\g3_migration.ps1
& F:\soft\00selfmade\practilog\tools\gates\g4_contrast.ps1

# 4) 构建 + 打包
Set-Location F:\soft\00selfmade\practilog\apps\desktop
& 'F:\soft\flutter\flutter\bin\flutter.bat' build windows --release
& F:\soft\00selfmade\practilog\tools\build\make_installer.ps1
```

## 附录 B：证据文件清单

| 产物 | 路径 |
|---|---|
| 主题 token | `apps\desktop\lib\src\theme\{app_tokens.dart,contrast.dart,app_fonts.dart,density_profile.dart,app_theme.dart}` |
| 主题测试 | `apps\desktop\test\{theme_tokens_test.dart,density_profile_test.dart,app_theme_test.dart}` |
| 文案编解码 | `packages\core_domain\lib\src\result_note.dart` + `packages\core_domain\test\result_note_test.dart` |
| 日历工具 | `packages\core_data\lib\src\calendar.dart` + `packages\core_data\test\calendar_test.dart` |
| 闭环口径 | `packages\core_data\lib\src\day_stats.dart` + `packages\core_data\test\day_stats_test.dart` |
| 组件 | `apps\desktop\lib\src\widgets\{chip_row,section_header,duration_chips,domain_chips,outcome_composer,loop_progress_ring,date_bar,date_picker_sheet,calendar_month_view,habit_checkin_strip,day_timeline,focus_ring}.dart` |
| 组件测试 | `apps\desktop\test\{chip_row_test,duration_domain_chips_test,outcome_composer_test,loop_progress_ring_test,date_bar_test,date_picker_sheet_test,calendar_month_view_test,habit_checkin_strip_test,day_timeline_test,keyboard_accessibility_test}.dart` |
| G4 门禁 | `tools\gates\g4_contrast.ps1` |
| 构建产物 | `apps\desktop\build\windows\x64\runner\Release\PractiLog.exe` |
| 安装包 | `release\PractiLog-Setup-<version>_<timestamp>.exe` |
| 验收记录 | `docs\B1_验收记录.md` |

## 附录 C：不在 B1 范围（本计划只登记，不实现）

- **B2**：`TodoPickerSheet`（#17）、`VocabEditor`（#26）、`YesterdayCarryOverCard`（#19）、`StartEndPicker`（#9）、`CountStepper`（#11）、`AvoidToggle`（#12）、`ChecklistHabitCard`（#13）、`SkipReasonChips`（#14）。
- **B3**：`MoodGrid`（#15）、`ReviewChipField`（#16）、`ProjectIncrementComposer`（#18）、`ReminderChipPicker`（#20）、`CalendarHeatYearView`（#23）、`CalendarDayList`（#24）、`DayDetailSheet`（#25）。
- **B4**：`AutostartToggle`（#27）、`DensitySettings`（#28）、侧边导航、托盘快速打卡、设置页。
- **B1 遗留（需单独立项）**：**字体资产打包**。`TOKENS.md` §8 要求 Fraunces / Inter / JetBrains Mono / Noto Sans SC 随应用自带，但仓库内不存在这四族字体文件（全盘仅 `MaterialIcons-Regular.otf` / `CupertinoIcons.ttf` 两个图标字体），故 **B1 的 17 个 Task 均不含打包**，B1 实际渲染走 `AppFonts.*Fallback`（正文命中 Noto Sans SC / 微软雅黑）。补齐路径：取得字体文件 → 放 `apps\desktop\assets\fonts\` → 在 `pubspec.yaml` 的 `flutter.fonts`（**不是** `flutter.assets`）下声明。补齐前 `144dpi` / `200%` 字号验收不算完整。
- **不做**（spec §13.4）：提醒中心页、日历拖拽排期、多用户、云端同步 UI、QuickCapture 全局向导中枢。
- **不在 B1**（但接口已预留）：应用内 toast + Undo（`apps\desktop\lib\src\toast_probe.dart` 是**系统通知探针**，不是应用内提示）；Undo 基建属 P8 新建模块。

---

## 执行方式（二选一）

1. **Subagent-Driven（推荐）**：每个 Task 派一个全新 subagent 实现，Task 之间做两段评审（规格符合 → 代码质量），迭代快、上下文干净。
2. **Inline Execution**：在本会话按 `superpowers:executing-plans` 批量执行，带检查点自查。

> 非 git 仓库：两种方式都**不要**依赖 commit 作为验证闸门，每个 Task 以「命令跑通 + 磁盘证据文件」收口。
