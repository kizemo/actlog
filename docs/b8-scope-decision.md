# B8 范围裁决（目标/蓝图页编辑权归位）

> 生成：2026-11-25 · 会话 `mvs_2fe482da85314d7584b1abcdfc0d19d3`
> 权威级别：**用户当轮决定**（高于派工书 / 计划正文 / handoff，见 `AGENTS.md` §6）

## 一、用户原话（逐字）

> 蓝图、目标页面的内容，应该在对应页面编辑，而不是在日志页面填入后，回填到这些页面。

问卷裁决结果：`scope_opt1`（两项都做，B8 一棒收口）。

## 二、裁决后的范围

1. **蓝图页补编辑能力**：07 蓝图页目前是只读树（页面文案自述「跨周期目标框架树 · 只读视图 · 数据由目标系统派生」），B8 要在该页内直接提供新增 / 修改 / 归档等编辑入口，不再只能靠别处派生。
2. **今日页撤掉目标写入入口**：移除今日页右栏「点击 / 拖拽添加到计划」与日计划右键菜单的「🚩 添加到计划 → 勾选周目标」链路；目标的创建与编辑回到目标页 / 蓝图页自身。
3. 月页 / 周页的「添加到当前周期」派生链路：B8 需明确保留还是改造（见 §四未决）。

## 三、与 B7 的关系

- B7 已按**现状**收口：四条写入通道（② 点击 / ③ 点击 / ④ 点击 / ④ 右键勾选 / ④ 拖拽）已于 2026-11-25 全部取得 SQLite 落库硬证据，详见 `docs\handoff-b7-live-acceptance.md` §七。
- B8 属于**方向性改造**，不改 B7 已交付的判定；B8 第一步是删除 / 迁移 B7 在 `week_goal_rail_panel.dart`、`slot_context_menu.dart`、`day_grid.dart` 中引入的写入入口，需连带清理对应测试与 l10n key。

## 四、B8 开工前必须裁决的未决问题

| # | 问题 | 现状证据 |
|---|---|---|
| U1 | 今日页右栏是否退化为**纯展示**（只列未完成周目标，不可操作） | `apps\desktop\lib\src\widgets\goals\week_goal_rail_panel.dart:47-83/194-196` |
| U2 | 日计划格子右键菜单里「🚩 添加到计划」条目整体移除后，菜单其余条目（手填 / 待办 / 习惯）是否保留 | `apps\desktop\lib\src\widgets\timeline\slot_context_menu.dart`（条目 119-165，`slot-menu-goals` 158-164）；`day_grid.dart:1173-1196/1282-1310` |
| U3 | 月页 / 周页「添加到当前周期」是否算「在日志页面填入后回填」（用户原则的边界） | `goals_month_page.dart:238-318`、`goals_week_page.dart:116-194`、`goal_store.dart:1046-1090` |
| U4 | 派生目标只写 `serves`、不写 `derives` 的根因 | 推测 `goal_store.dart:1061-1090` 在 `parentId == sourceGoalId` 时去重，**未坐实** |
| U5 | 蓝图页编辑的写集与 `goal` 表列口径 | 真值列见 `reports\task72-live-schema.txt`；`goal` 无 `source_goal_id` / 无 `origin` 列 |
| U6 | MINOR-2：窄屏 `KeyBar` 的 `Ctrl+7` 文字提示是否补做（多次实证只列到 `Ctrl+6`） | 帧 `reports\task72-frames\{41,43,78}-*.png` |
| U7 | provider 未就绪时静默无落库（MINOR-3）+ 新派生目标需重启进程才在右栏出现 | 帧 68/69 vs 53 |

### §四·附 裁决登记（按盘上证据回填，不重复提问）

| # | 裁决 | 依据（盘上可回读） | 落地 |
|---|---|---|---|
| U1 | **已裁决：今日页右栏「未完成周目标」卡保留，退化为只读展示，不整卡移除** | 用户 2026-11-25 逐字「保留只读展示」⇒ `docs\b83-dispatch-w3.md` L5–L7 引用；本文件 §二·2 同步 | B8-W3 已落地：`WeekGoalRailPanel` 只读化，删除 `Draggable` / `onTap` 全部写入通道，保留三态与 `ValueKey('week-goal-${goal.id}')`；卡仍挂在 `apps\desktop\lib\src\app.dart:428-431` |
| U6 | **已裁决：本批补做**（MINOR-2 原判「不在 B8 范围」被推翻） | 键条自身口径「每一条都必须有真实绑定，留一条没有落点的提示就是假承诺」（`key_bar.dart` L24-25）；`Ctrl+7` 早有真实绑定 `apps\desktop\lib\src\app.dart:256-257`（`digit7 + control → _NavIntent('blueprint')`），清单却只列到 `Ctrl+6` ⇒ 属**清单与真实绑定不一致**的明显遗漏，按用户「明显的 bug 直接按推荐方案修」口径直接补，不发问卷 | 清单 9 → 10 条（`Ctrl+7` / 切到蓝图），`kShellKeyHints` 与 `shellKeyHintsFor()` 双份同步，新增 l10n 键 `shellKeyGoBlueprint`（W3 棒「l10n 只减不增」是棒内约束，本批属新棒）；动的是清单本身，故 `kShellKeyHints.length` 相关断言同步改，测试用例条数不增 |

> U2–U5、U7 仍未裁决，保持挂账；U3（月/周页派生链路）与 U7（provider 静默不影响落库）不因本批改动而改变状态。

## 五、纪律提醒（照抄 `AGENTS.md`）

- **R1**：控制器不改 `apps\**` / `packages\**`，改造一律经 `worker` 派工。
- **R2** 门禁：逐包 analyze 逐字 `No issues found!`；desktop 测试精确等值 **907**；`core_data` 204 / `core_db` 96 / `core_domain` 91。删入口会导致测试数变化 ⇒ 907 基线需同步重定并写进台账。
- **R5**：进台账的具体值必须当场盘上回读。
- **R4**：不删文件；测试/l10n key 清理用 `Move-Item` 留档（控制器侧该命令会被本地安全网关拦，见 §5 坑 103，需派工执行）。
