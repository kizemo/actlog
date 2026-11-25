# 交接台账 · 批次 B7 / Task 72 · W2（月目标页 / 周目标页右栏派生）

- 作业书：`docs/b71-dispatch-w2-panel.md`（末尾 §9「W1 已落地后的强制订正」优先级高于上文）
- 计划正文：`docs/plan-goals-ui-batch7.md`
- 上游地基台账：`docs/handoff-ledger-b7-w1.md`
- 需求归属：需求 2（月页右栏列未完成年目标）、需求 3（周页右栏列未完成月目标）
- 本棒执行人：W2 工人（子会话）
- 完成时间：2026-11-25

---

## STATUS

**DONE** —— 需求 2、需求 3 的右栏派生已落地并通过行为级判据；`flutter analyze` 逐字
`No issues found!`；`flutter test --reporter compact` 逐字 `+903: All tests passed!`（退出码 0）。

未做（明确不在本棒范围 / 未验证）：真拖拽手势的自动化用例（仅覆盖 payload 编解码与点击派生路径）；
`goalsUpstreamAddMenu` 的菜单形态（本棒只消费其余 5 个 getter）。

---

## CHANGED_FILES

写集内逐文件（`git diff --numstat` 实测；新建文件按总行数计 +N/-0）：

| 文件 | 性质 | +/- | 行数 |
|---|---|---|---|
| `apps/desktop/lib/src/widgets/goal_upstream_panel.dart` | 新建 | +222 / -0 | 222 |
| `apps/desktop/lib/src/pages/goals_month_page.dart` | 修改 | +131 / -1 | — |
| `apps/desktop/lib/src/pages/goals_week_page.dart` | 修改 | +128 / -1 | — |
| `apps/desktop/test/task72_w2_goal_upstream_panel_test.dart` | 新建 | +233 / -0 | 233 |
| `apps/desktop/test/task72_w2_goals_month_upstream_test.dart` | 新建 | +157 / -0 | 157 |
| `apps/desktop/test/task72_w2_goals_week_upstream_test.dart` | 新建 | +161 / -0 | 161 |
| `docs/handoff-ledger-b7-w2.md` | 新建（本文件） | — | — |

**合计 +1032 / -2**（不含本台账）。

### 做了什么事

1. **`goal_upstream_panel.dart`（新，D-72-d 三层共用）**
   - 公开约定：`goalDragPayloadPrefix = 'goal://'`、`goalDragPayloadFor(String)`、
     `goalIdFromDragPayload(Object?)`。非本通道（`null`、空串、裸待办 id、非 `String`）
     一律返回 `null` ⇒ 调用方原样放行，不吞 `widgets/timeline/day_grid.dart` 那条拖拽通道。
   - 条目 = `Draggable<String>(data: 'goal://'+id, dragAnchorStrategy: pointerDragAnchorStrategy)`
     包 `InkWell(onTap: () => onPick(goal))`；面板自己**不读库、不写库**。
   - 三态：`loading` → 16px 转圈；`errorText != null` → 错误文案；`goals.isEmpty` → 空态。
   - 定位 key 工厂：`GoalUpstreamPanel.panelKey(kind)` → `goal-upstream-panel-<kind.code>`、
     `GoalUpstreamPanel.itemKey(kind, id)` → `goal-upstream-item-<kind.code>-<id>`。
   - 文案全由调用方传入（页面侧取 `AppLocalizations`），组件**不 import**
     `widgets/shell/key_bar.dart`（规避 §9 第 8 条坑）。

2. **`goals_month_page.dart`（需求 2）**
   - `ref.watch(yearOpenGoalsProvider)`（W1 地基，口径 = `!isDone && archivedAt == null`，本棒只消费不重写）。
   - 原顶层 `Column` 收进 `final Widget left`，外面包 `DragTarget<String>`
     （key `goal-month-drop-target`；`onWillAcceptWithDetails` 用 `goalIdFromDragPayload` 判前缀，
     `onAcceptWithDetails` 按 id 在 `yearlyGoals` 里找行后调 `_addFromYearly`）。
   - `LayoutBuilder`：`maxWidth < _sideBySideMinWidth` ⇒ 上下堆叠；否则
     `Row[Expanded(dropArea), SizedBox(width: ToolRail.panelGap), SizedBox(width: _upstreamWidth, child: panel)]`。
   - 常量从壳层口径推出，不新造断点：`_upstreamWidth = ToolRail.railWidth(290)`，
     `_sideBySideMinWidth = ToolRail.minColumnWidth(210) + ToolRail.panelGap(14) + 290 = 514`。
   - `_addFromYearly(GoalRow)`：走既有写入口 `goalStoreProvider.saveWeeklyDrafts([GoalDraft(kind: monthly,
     periodStart/periodEnd = 本月起止, parentId: yearly.id, sourceGoalId: yearly.id,
     origin: GoalDraftOrigin.fromUpperLayer, domain/note 沿用父)])`，成功后
     `setState(() => _future = _load())`，失败撤闸门 + 写 `_error`（`operationFailed`）。
   - 幂等双层：① `Set<String> _derivedFromYearly` 同步闸门挡连点（写失败才移除）；
     ② `_alreadyServedYearly(_lastData, id)` 遍历 `_MonthData.servedByMonthGoal` 判父 id
     （挡页面重建后 Set 清空的场景，因为 `saveWeeklyDrafts` 自身不幂等，见 `goal_store.dart:1068`）。

3. **`goals_week_page.dart`（需求 3）**
   - `ref.watch(monthOpenGoalsProvider)`；同一 `DragTarget`（key `goal-week-drop-target`）与同一
     `LayoutBuilder` 阈值逻辑。
   - `_addFromMonthly(GoalRow)`：走 `ref.read(goalDraftSaverProvider)([GoalDraft(kind: weekly, ...,
     parentId: monthly.id, sourceGoalId: monthly.id, origin: fromUpperLayer)])` +
     `ref.invalidate(goalWeekViewProvider)`（与页内既有 `_confirm` 同口径），失败撤闸门。
   - 周期取 `ref.read(goalCurrentWeekProvider)`（内部 `todayProvider` 本地中午口径）。
   - 幂等双层：`Set<String> _derivedFromMonthly` + `_alreadyServedMonthly(id)`（遍历
     `goalWeekViewProvider` 的 `items[].servedGoal?.id`）。

### 派生语义（D-72-e）落实情况

- 年→月、月→周都是**派生**：库里新增一条子目标行 + 一条 `serves` 关系，**父目标状态不变**
  （用例显式断言派生后父行仍是 `GoalStatus.active` / `isDone == false`）。
- 复用既有写入路径（`saveWeeklyDrafts` / `goalDraftSaverProvider`），**未新增仓储方法**，
  未绕开 provider 直查 store（页面读侧全走 W1 的三个 open provider）。
- 未写 `derives` 双链：`sourceGoalId == parentId` 时 `saveWeeklyDrafts` 内部
  （`goal_store.dart:1094`）的 `sourceGoalId != parentId` 判据只落 `serves` 一条链。

---

## TEST_COUNT

| 口径 | 实测值 |
|---|---|
| 全量 `flutter test --reporter compact` 末行 | `01:10 +903: All tests passed!`（退出码 **0**） |
| 本棒新增用例 | **13** 条（面板 9 + 月页 2 + 周页 2） |
| W1 交接台账记录基线 | `+882` |
| 差值 | `+21` = 本棒 13 + W3 并发新增 8（`task72_w3_*` 两个文件，非本棒产物） |

本棒三个测试文件单独跑：`13: All tests passed!`（退出码 0）。

### 用例清单（全部行为级，落在「库里的行」而非「回调被调用过」）

`test/task72_w2_goal_upstream_panel_test.dart`（9 条）
1. 前缀逐字 `goal://`，`goalDragPayloadFor` 拼接；
2. `goalIdFromDragPayload` 能还原、含连字符 id 不截断；
3. 非本通道（`todo-42` / `''` / `goal://` / `null` / `42`）一律 `null`；
4. 有条目时逐条渲染 + 点一条 `onPick` 收到该 `GoalRow`；
5. 空态只留空提示、不渲染条目；
6. 加载中画转圈、不画空态（避免被误读成「上游没有目标」）；
7. 出错态显示错误文案、列表不渲染；
8. 英文态三处文案都来自 `AppLocalizations.en`；
9. 六个 `goalsUpstream*` getter 中英都非空（本棒只消费，不自补文案）。

`test/task72_w2_goals_month_upstream_test.dart`（2 条）
1. 真内存 drift + 真 `saveWeeklyDrafts`：右栏列出未完成年目标 → 点一次库里多出 1 条本月月目标
   （`kind/monthly`、`periodStart == 本月`、`servedGoals` 含该年目标）→ 父目标仍 `active` →
   再点一次仍只有 1 条；
2. en 态右栏文案来自 `AppLocalizations.en`，上游为空落空态文案。

`test/task72_w2_goals_week_upstream_test.dart`（2 条）
1. 右栏列出未完成月目标 → 点一次 `weekView(GoalPeriod.week(2026,48)).items` 多出 1 条
   `servedGoal?.id == 该月目标` 的周目标（`periodStart == 本周`）→ 父目标仍 `active` →
   再点一次仍只有 1 条；
2. en 态右栏文案来自 `AppLocalizations.en`，上游为空落空态文案。

---

## GIT_STATUS_PORCELAIN

`git status --porcelain -uall` 原样（本棒收尾时刻）：

```
 M AGENTS.md
 M apps/desktop/lib/src/app.dart
 M apps/desktop/lib/src/l10n/l10n_keys.dart
 M apps/desktop/lib/src/l10n/parts/goals.dart
 M apps/desktop/lib/src/l10n/parts/shell.dart
 M apps/desktop/lib/src/pages/goals_blueprint_page.dart
 M apps/desktop/lib/src/pages/goals_month_page.dart
 M apps/desktop/lib/src/pages/goals_page.dart
 M apps/desktop/lib/src/pages/goals_week_page.dart
 M apps/desktop/lib/src/providers.dart
 M apps/desktop/lib/src/widgets/shell/nav_rail.dart
 M apps/desktop/lib/src/widgets/timeline/day_grid.dart
 M apps/desktop/lib/src/widgets/timeline/slot_context_menu.dart
 M apps/desktop/test/l10n_base_test.dart
 M apps/desktop/test/l10n_harness.dart
 M apps/desktop/test/nav_rail_footnote_test.dart
 M apps/desktop/test/nav_shortcut_test.dart
 M apps/desktop/test/shell_nav_rail_test.dart
 M apps/desktop/test/task61_l10n_shell_test.dart
 M apps/desktop/test/task64_nav_gear_test.dart
 M docs/relay.json
 M docs/relay/stage-6-report.md
?? apps/desktop/lib/src/widgets/goal_upstream_panel.dart
?? apps/desktop/lib/src/widgets/week_goal_rail_panel.dart
?? apps/desktop/test/blueprint_page_test.dart
?? apps/desktop/test/task72_w2_goal_upstream_panel_test.dart
?? apps/desktop/test/task72_w2_goals_month_upstream_test.dart
?? apps/desktop/test/task72_w2_goals_week_upstream_test.dart
?? apps/desktop/test/task72_w3_day_goal_menu_test.dart
?? apps/desktop/test/task72_w3_week_goal_rail_panel_test.dart
?? docs/b71-dispatch-w1-nav.md
?? docs/b71-dispatch-w2-panel.md
?? docs/b71-dispatch-w3-wire.md
?? docs/handoff-ledger-b7-w1.md
?? docs/plan-goals-ui-batch7.md
?? docs/relay/auto-advance-design.md
?? docs/relay/gate-green-2026-11-25.md
?? docs/relay/relay-lock.ps1
?? docs/relay/start-relay.ps1
```

其中**属于本棒**的只有：

```
 M apps/desktop/lib/src/pages/goals_month_page.dart
 M apps/desktop/lib/src/pages/goals_week_page.dart
?? apps/desktop/lib/src/widgets/goal_upstream_panel.dart
?? apps/desktop/test/task72_w2_goal_upstream_panel_test.dart
?? apps/desktop/test/task72_w2_goals_month_upstream_test.dart
?? apps/desktop/test/task72_w2_goals_week_upstream_test.dart
?? docs/handoff-ledger-b7-w2.md
```

其余为 **W1 地基产物 + W3 并发产物 + 控制器接力装置**，本棒只读取、未改动、未回滚。
特别标注 W3 的独占文件：`widgets/week_goal_rail_panel.dart`、`widgets/timeline/day_grid.dart`、
`widgets/timeline/slot_context_menu.dart`、`test/task72_w3_*`。越界自检：本棒**零**写入上述路径。

---

## 验证输出（逐字）

### `flutter analyze`

```
Analyzing desktop...
No issues found! (ran in 6.3s)
```

退出码 `0`。

> 时序说明（诚实记录）：本棒中途有一次 analyze 输出为
> `3 issues found. (ran in 4.0s)`，三条全部落在 **W3 的并发文件**上
> （`week_goal_rail_panel.dart:138` 的 `unnecessary_underscores`、
> `task72_w3_day_goal_menu_test.dart:21` 的 `unused_import`、
> `task72_w3_week_goal_rail_panel_test.dart:140` 的 `GoalKind.daily` 不存在），
> 随后由 W3 自行修复。本棒写集在任何时刻都贡献 **0** 条 issue。

### `flutter test --reporter compact`

```
01:10 +903: All tests passed!
```

退出码 `0`。日志留在 `reports/task72-w2-test-full.log`（analyze 日志 `reports/task72-w2-analyze.log`）。

### 源码纪律自检（实测）

| 项 | 结果 |
|---|---|
| 6 个写集文件 CRLF 计数 | 全 `0`（纯 LF） |
| 6 个写集文件 BOM | 全 `False` |
| 顶层 `print(` 计数 | 全 `0` |
| 新增公开成员中文 `///` | 已加（`goalDragPayloadPrefix` / `goalDragPayloadFor` / `goalIdFromDragPayload` / `GoalUpstreamPanel` 及其全部字段 / `panelKey` / `itemKey`） |

---

## BUILD_DIR_ISOLATION

- 全程 `$env:FLUTTER_BUILD_DIR` 进程内设置，**未污染**默认 `build/`。
- 前段用 `build_w2`；收尾全量与终次 analyze 用**全新目录** `build_w2_full`。
- 原计划「全量前把 `build_w2\test_cache\build` 改名挪走」**未执行**：`Move-Item` 被本地安全
  策略拒绝（`recursive write/delete target cannot be verified inside the workspace`）。
  改用全新构建目录达到同样隔离效果，**没有删除任何目录或文件**。
- `build_w2` / `build_w2_full` 均在 `apps/desktop/` 下、被 git 忽略，未出现在
  `git status --porcelain -uall` 里。

---

## AMBIGUITIES

1. **测试文件目录**：派工书 §1 原稿写 `test\pages\goals\task72_*`，本会话作业书写
   `test\task72_w2_*`，§9 第 7 条允许 `test\task72_*`。采用 `test\task72_w2_*`，
   目的是与 W3 的 `test\task72_w3_*` 不撞名。
2. **窄屏折叠的层级**：D-72-f 要求「沿用壳层既有折叠行为、不新造断点机制」。壳层的折列
   常量在页面内拿不到布局上下文，因此折成**页面级宽度守卫**：阈值
   `ToolRail.minColumnWidth + ToolRail.panelGap + ToolRail.railWidth = 514`，由既有常量推出、
   不写魔数；`< 514` 时右栏落到正文下方（同一列内上下堆叠），不隐藏面板。
   若控制器要求真正复用壳层的折叠开关（而不是宽度推算），这里是**主动登记的口径差异**。
3. **右栏宽度取 `ToolRail.railWidth`（290）的代价**：月页/周页正文已被 `LedgerPaper`
   限宽（770 / 860），右栏吃掉 290 后左表仅剩约 480 / 556。`Expanded` 不溢出、`Text` 自动
   换行，功能成立但密度明显变紧。若嫌窄，改 `rail2Width(286)` 或另立窄栏常量即可，属一行改动。
4. **出错态优先于列表**：`errorText != null` 时**不渲染条目**（即使调用方传了 `goals`）。
   这是刻意选择——读失败时列表可能残缺，宁可只报错，不给「就这些」的假象。
5. **派生后的刷新口径不统一**：月页 `setState(() => _future = _load())`、周页
   `ref.invalidate(goalWeekViewProvider)`。两者都沿用各自页内既有实现的写法，本棒未强行统一。
6. **`goalsUpstreamAddMenu` 未消费**：派工书列了 6 个只读 getter，本棒落 5 个
   （Year/Month/Week Title、AddHint、Empty）。该 getter 对应「长按/右键菜单」形态，
   派工书的 D-72-d 未细化菜单交互，故本棒不做、登记在此。

---

## CONCERNS

1. **W3 并发让本棒的验证数字有时序性**。本棒跑测期间 W3 正在改
   `day_grid.dart` / `slot_context_menu.dart` / `week_goal_rail_panel.dart` / `task72_w3_*`，
   中途 analyze 曾因 W3 的文件报 3 条 issue（非本棒），随后被 W3 修好。
   最终的 `No issues found!` 与 `+903 All tests passed!` 是**全仓快照**的结果，
   不能把 +21 全部归因于本棒；本棒的真实增量是 **13 条**。
2. **真拖拽手势未被自动化覆盖**。用例只锁了 payload 编解码（`goal://+id` 往返、非本通道返回
   `null`）与点击派生路径；`Draggable → DragTarget` 的实拖需要手写
   `tester.startGesture` + `moveTo` + `up` 长链，本棒时间预算内未做。
   **拖拽分支目前是「代码在、判据缺」**，建议控制器在合并前补一条实拖用例或明确接受该缺口。
3. **幂等只在同一页面实例内被强证明**。同步 `Set` 闸门在页面重建后会清空，此时依赖
   回读 `serves` 关系兜底（月页 `servedByMonthGoal`、周页 `items[].servedGoal`）。
   这条兜底路径**没有独立用例**（用例里连点发生在同一实例内，走的是 Set 闸门）。
   风险等级低（`saveWeeklyDrafts` 的 `sourceGoalId != parentId` 判据天然不写重复 `derives`），
   但「切页签再回来重复点击」这一场景属未验证项。