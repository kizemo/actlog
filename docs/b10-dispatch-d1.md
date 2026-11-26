# B10-D1 派工书 · 蓝图页「个人定位」改造 + 目标矩阵增强 + 两处模块下线

- 出单：控制器会话（root）
- 实施：`worker` 子会话（分棒 A → B，**串行**，同一页文件不允许并发写）
- 用户原话口径：见 §0；本文所有行号以 2026-11-26 盘上代码为准
- 规范真源：`AGENTS.md` §2 铁律 R1–R8、§5 坑 110–126、§7 快照

---

## §0 用户诉求（逐条，实施不得漏项）

1. 蓝图页顶部「个人品牌管理」→ **「个人定位」**，回答四问：
   - 我的价值观；我的优势；独特价值（能解决什么问题、什么领域）；信任背书（我凭什么塑造优势）。
2. 四项**都有输入框**；**价值观与优势**另提供**丰富标签选项**（专业文献级），点击标签即填入；
   输入框**悬停**时以**悬浮窗**形式显示在**鼠标右下**；鼠标离开后**约 3 秒**消失（留出移动过去点击的时间）。
   同步改写这部分的填写指引文案。
3. 目标模块排版/样式：**未激活标签与激活标签清晰区分**，以**标签页**形式呈现；
   悬停「短期」「中期」「远期」显示对应**时长**。
4. 已填写目标提供**可勾选**的完成标记；**增加一列显示起止日期**；勾选后**显示完成日期**。
5. 删掉模块底部「整行留空合法，不校验、不报错」这一行。
6. 删掉页面底部「平衡轮」模块。

## §1 已坐实的事实（不要再花时间重查，按此实施）

| 事实 | 证据位置 |
| --- | --- |
| 品牌面板 10 切面，落库 `kind='brand'` + `facet`，空标题不写行 | `apps\desktop\lib\src\widgets\goal_brand_panel.dart` 全文 |
| 页面装配点：品牌面板 L230；矩阵块 L233（`_block`，段头 null）；留空提示 L283–284；平衡轮块 L235–239 | `apps\desktop\lib\src\pages\goals_blueprint_page.dart` |
| 矩阵四标签页 `GoalBlueprintMatrix.tabs = [ultimate,long,mid,short]`，键 `goal-blueprint-tab-<key>`，当前仅用 font-weight 区分选中 | `apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart:99-104,137-166` |
| `GoalHorizon` 语义：ultimate=60 岁后(1)、long=10 年(2)、mid=5 年(3)、short=3 年(4)、near=1 年(5) | `packages\core_domain\lib\src\goal.dart:113-128` |
| `goal` 表有 `period_start`(NOT NULL DEFAULT 0) / `period_end` / `status`('draft','active','done','cancelled') / `archived_at`；**无 `completed_at`** | `reports\task72-live-schema.txt`（`CREATE TABLE "goal"`） |
| 表约束 `goal_archived_at_check CHECK (status='done' OR archived_at IS NULL)` ⇒ `archived_at` 只能表达「完成时刻」 | 同上 |
| `listGoals` 只按 `deleted_at IS NULL` + 可选 kind/status/parentId/period 过滤，**不按 archived_at 过滤** ⇒ 用 archived_at 记完成日期不会把行藏掉 | `apps\desktop\lib\src\data\goal_store.dart:651-678` |
| `Goal.create` 校验：`status != done && archivedAt != null` ⇒ 抛异常 | `packages\core_domain\lib\src\goal.dart:689-691` |
| `updateGoal` 目前 `archivedAt: current.archivedAt`（无法改）⇒ 需在 app 层按 status 派生 | `apps\desktop\lib\src\data\goal_store.dart:568` |
| 蓝图目标的 `period_start` 走 `createGoal` 默认 0、`period_end` 为 null（表单没有日期字段） | 同文件 `:449-457`；`goal_form_dialog.dart` 无 period 字段 |
| schema FROZEN（14 表）；本次**禁止**任何 migration / 新列 / 新表 | `AGENTS.md` §2 R6 |
| 平衡轮组件 `GoalBalanceWheel` 只被蓝图页引用；其派生逻辑另有独立组件用例 | `apps\desktop\lib\src\widgets\goal_balance_wheel.dart`；`test\task66_goals_blueprint_page_test.dart:340` |

## §2 硬约束（违反即打回）

- **R4 不删文件**：不得 `Remove-Item`/`git rm` 任何文件；旧实现以「原地改造」或「保留不动」处理。
  本棒**不新建也不删除**源文件（见 §3 的原地改造口径）；测试文件新增允许，删除不允许。
- **零 schema 变更**：不碰 `packages\core_db`、不写 migration、不新增列。
- **不碰 `packages\core_domain`**：`GoalFacet` / `GoalField` / `GoalHorizon` 一律不加成员。
  完成时刻走「`updateGoal` 内部按 status 派生 archived_at」这条纯 app 层路径。
- **l10n 全覆盖**：所有用户可见字符串走 `apps\desktop\lib\src\l10n\`，**中英双语**；
  widget 内不得出现硬编码中文（注释除外）。新增键必须同步 `l10n_keys.dart` 与
  `test\l10n_harness.dart` 的基表（该基表是键计数真源，改完跑 `test\l10n_base_test.dart`）。
- **配色/间距只读 token**：`context.tokens`（`ink` / `meta` / `hair` / `hairSoft` / `card` / `accentInk` …）
  与 `AppTokens` 常量；不得写死颜色。
- **Material 图标**：矩阵模块已允许 `Icons.edit_outlined` / `Icons.call_split` 两个，**不得新增第 3 个**；
  其余新 UI 用文字符号或既有组件。
- **坑 48**：新增可选参数的默认值不得改变既有调用点行为。
- 不 `git add`、不 commit、不 push、不碰 `docs\` 与 `AGENTS.md`。
- 门禁前必须把 `apps\desktop\build\test_cache\build` 用 `Move-Item` 挪走（不得删除）。
- 镜像必须进程内设置：
  `$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'`

---

## §3 棒 A：个人定位面板 + 两处模块下线

### §3.1 面板改造（原地改造，文件路径不变）

文件：`apps\desktop\lib\src\widgets\goal_brand_panel.dart`

- **保留文件路径**（避免删除/改名），把类 `GoalBrandPanel` 改名为 **`GoalPositionPanel`**，
  10 切面实现整体替换为 4 项；文件头注释同步改写（说明「原个人品牌管理 → B10 个人定位」，
  并写明 4 项的 facet 映射与「旧 6 个切面的行保留不删」）。
- 4 项定义（顺序即渲染顺序）：

| code | 标题（zh） | 落库 facet | 是否有标签库 |
| --- | --- | --- | --- |
| `values` | 我的价值观 | `GoalFacet.identity` | 是 |
| `strengths` | 我的优势 | `GoalFacet.strength` | 是 |
| `value` | 独特价值（能解决什么问题、什么领域） | `GoalFacet.promise` | 否 |
| `proof` | 信任背书（我凭什么塑造优势） | `GoalFacet.evidence` | 否 |

- 每项：标题 + 要点指引（1–2 行）+ 多行输入框（`minLines: 2, maxLines: 4`）+ 右侧「保存」。
  保存语义**沿用现有口径**：空文本不写行；有行走 `updateGoal`（不传 facet）；无行走 `createGoal`；
  保存成功显示「已保存」，失败显示错误行。
- 页面装配点：`goals_blueprint_page.dart:230` 的 `const GoalBrandPanel()` 换成 `const GoalPositionPanel()`。
- 段头文案键：新增 `goalPositionSection`（zh「个人定位」/ en "Personal Positioning"），
  不再使用 `goalBrandSection`（旧键保留不删）。
- Widget 键（测试依赖，必须逐字一致）：
  - `goal-position-panel`（根）
  - `goal-position-input-<code>`（输入框）、`goal-position-save-<code>`（保存）
  - `goal-position-saved`（已保存行）、`goal-position-error`（失败行）
  - `goal-position-tags-overlay`（悬浮窗根）、`goal-position-tag-<code>-<index>`（单个标签）

### §3.2 标签库（专业文献级，中英双语）

- 价值观 = **Schwartz 基本价值理论 10 项**（Schwartz, 1992）：
  自我导向 / 刺激 / 享乐 / 成就 / 权力 / 安全 / 遵从 / 传统 / 仁善 / 普世主义。
- 优势 = **VIA 24 项性格优势**（Peterson & Seligman, 2004《Character Strengths and Virtues》）：
  创造力 / 好奇心 / 开放思维 / 好学 / 洞察力 / 勇敢 / 坚持 / 真诚 / 热情 / 爱 / 善良 /
  社交智力 / 团队精神 / 公平 / 领导力 / 宽恕 / 谦逊 / 审慎 / 自我调节 / 欣赏美与卓越 /
  感恩 / 希望 / 幽默 / 灵性。
- 落 l10n：每个库**一个 `List<String>` getter**（`goalPositionValueTags` / `goalPositionStrengthTags`），
  中英各一份，避免 34 个 getter 把基表撑爆。en 用 VIA/Schwartz 官方英文名。
- 点击标签：把标签**追加**到对应输入框文本末尾；若框内已有内容且不以 `、`/`，`/换行结尾，先补 `、`；
  同一标签已存在则不重复追加。点选后浮层保持打开（3 秒规则接管）。

### §3.3 悬停悬浮窗（本棒最高风险项，按此实现）

- 用 `OverlayEntry` + `MouseRegion`，**不得**用 `Tooltip`（不可点击）。
- 触发：仅在两个带标签库的输入框上——`onEnter`/`onHover` 取 `PointerHoverEvent.position`，
  浮层左上角 = 鼠标 `+(12, 16)`，并按 `MediaQuery.sizeOf(context)` 夹取，保证不越出屏幕右下边缘。
- 消失：输入框 `onExit` 起 **`Duration(seconds: 3)`** 的 `Timer`；浮层自身 `MouseRegion`
  `onEnter` 取消计时、`onExit` 重新起 3 秒计时（鼠标移到浮层上不消失）。
- 生命周期：`dispose`、切换项、页面 pop 时必须 `remove()` 并 `cancel()`；
  重复 enter 不得叠加两个 OverlayEntry。
- 浮层内容：标题「点击标签填入」+ 标签 chip 流式换行（`Wrap`），宽度上限约 360，
  背景 `tokens.card`、1px `tokens.hairSoft` 边框、圆角 `AppTokens.radius`。
- 必须可在 widget 测试里驱动：`tester.pump(Duration(seconds: 2))` 仍在、
  `tester.pump(Duration(seconds: 4))` 已消失。

### §3.4 两处下线

- 删「整行留空合法…」渲染：`goals_blueprint_page.dart:283-284` 的 `SizedBox` + `Text` 一并去掉，
  `_buildMatrix` 直接返回 `GoalBlueprintMatrix(...)`。l10n 键 `goalBlueprintBlankRowHint` **保留不动**
  （其他测试/文档可能引用），只改渲染与测试断言。
- 删平衡轮块：`goals_blueprint_page.dart:235-239` 整块去掉（含外层 `SizedBox` 分隔），
  页面类头注释同步（去掉「平衡轮」字样）。`goal_balance_wheel.dart` 文件与组件**保留不动**。
  `_BlueprintData.balance` 若无其他消费者可保留字段与计算（不得为清理而扩大改动面）。

### §3.5 棒 A 的测试

- 改造 `test\task78_b9_brand_panel_test.dart`（**文件名保留**）→ 覆盖新面板：
  四项渲染、输入保存落库、空文本不写行、标签浮层出现/3 秒消失/点选填入。
- 修改 `test\task66_goals_blueprint_page_test.dart`：平衡轮与留空提示相关断言改为**不存在**；
  平衡轮组件自身的派生用例（`:340`）若测的是组件行为则保留。
- 新增 `test\b10_position_panel_test.dart` 承载浮层三秒与追加语义的细粒度用例（可与上条合并，勿重复）。
- 更新 `test\blueprint_page_test.dart` 中因下线/换名失效的断言。

---

## §4 棒 B：目标矩阵增强（棒 A 完成且门禁绿后再开）

文件：`apps\desktop\lib\src\widgets\goal_blueprint_matrix.dart`（主）+ `goal_store.dart`（派生 archived_at）
+ 新组件 `apps\desktop\lib\src\widgets\goals\goal_period_dialog.dart`（起止日期编辑）

1. **标签页视觉区分**：激活 = 实心 pill（`tokens.ink` 底 + `tokens.card` 字，圆角 `AppTokens.radius`）；
   未激活 = 透明底 + `tokens.meta` 字 + 1px `tokens.hairSoft` 边框；hover 未激活时边框转 `tokens.ink`。
   键保持 `goal-blueprint-tab-<key>` 不变（既有测试依赖）。
2. **悬停显示时长**：每个标签页套 `Tooltip`（hover 触发），文案
   「终极 · 60 岁后」「远期 · 10 年」「中期 · 5 年」「短期 · 3 年」，l10n 四条键
   （`goalBlueprintHorizonUltimateSpan` 等），中英双语。
3. **新增第三列「起止日期」**：表变 3 列（领域 flex 2 / 目标 flex 4 / 起止日期 flex 2）。
   列头不渲染（与现状一致，矩阵不画表头行）；每行内容：
   - `periodStart == 0` ⇒ `—`；否则 `yyyy-MM-dd ~ yyyy-MM-dd`（`periodEnd == null` 时右端 `—`）。
   - 该文本是**可点击按钮**（键 `goal-blueprint-period-<goalId>`），点开 `GoalPeriodDialog`：
     起始日期 / 截止日期两个 `showDatePicker`（初始值 = 今天）+「清除」+「取消」+「确定」。
     确定 ⇒ `updateGoal(id, periodStart:…, periodEnd:…)`；
     清除 ⇒ `updateGoal(id, periodStart: 0, clear: {GoalField.periodEnd})`
     （`period_start` 非空，清空语义 = 归 0；`GoalField` 里若无 `periodStart` 成员就只传 0，**不要**改 core_domain）。
   - 只对 `kind == GoalKind.blueprint` 渲染可点编辑；`yearly` 行只读展示。
4. **完成勾选**：每行最左加 `Checkbox`（键 `goal-blueprint-done-<goalId>`），
   仅 `kind == GoalKind.blueprint` 渲染（与铅笔/拆分/删除同门槛）。
   - 勾选 ⇒ `updateGoal(id, status: GoalStatus.done)`；取消 ⇒ `updateGoal(id, status: GoalStatus.active)`。
   - **完成日期落库**：在 `goal_store.updateGoal` 内部按 status 派生，不改 API、不改 core_domain：
     `status == done && current.archivedAt == null` ⇒ 合并行的 `archivedAt = ts`；
     `status != done` ⇒ `archivedAt = null`（必须与 status 同步写入，否则触发域校验
     `只有完成的目标才能进归档`）。
   - 完成后同列追加「完成 yyyy-MM-dd」（取 `archivedAt`，null 时兜底 `updatedAt`），
     文案键 `goalBlueprintDoneOn(date)`（插值方法，中英各一）。
   - 已完成行标题降对比（`tokens.meta`）+ 删除线，勾选框保持可取消。
5. **刷新**：勾选/改日期后页面 `_future = _load()` 重取（走既有 `onToggleDone` / `onSetPeriod`
   回调，回调可选、默认 null ⇒ 不渲染，坑 48）。矩阵新增参数：
   `onToggleDone`、`onSetPeriod`（`void Function(GoalRow goal, int start, int? end)` 之类）。
6. 测试：新增 `test\b10_blueprint_matrix_done_test.dart` 覆盖
   ① 勾选写 status=done 且 archived_at 落值、② 取消清回 null、③ 起止日期列格式与「—」、
   ④ 时长 tooltip 文案、⑤ 激活/未激活标签页样式差异（按色值断言）。
   同步修 `test\blueprint_page_test.dart` 因列数变化失效的断言。

---

## §5 门禁与交付

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Move-Item 'apps\desktop\build\test_cache\build' "apps\desktop\build\test_cache\build.bak-<时间戳>" -ErrorAction SilentlyContinue
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze                       # 逐字 No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact       # desktop 基线 946，改造后给出精确数
& 'F:\soft\flutter\flutter\bin\flutter.bat' test test\l10n_base_test.dart --reporter compact
```

- 三个 `packages\core_*` 测试基线不得变化（本次不改 packages）：`core_data` 204 / `core_db` 96 / `core_domain` 91。
- 越界检查 `VIOLATIONS=0`（`tools\gates` 既有脚本）。
- 回报格式：改动文件清单（含行号区间）+ 每条需求的落点 + 三个门禁的**原始末行输出** +
  desktop 测试精确总数 + 未做/未验证项。**不要**自报「已通过」而不贴原始输出。
- 任何一条门禁红，先修到绿再回报；修不动就停下并说明卡点，不要绕。