# B19 计划：学习管理页面（学习资料库 · 学习计划 · 日志右轨闭环）

> 批次编号：**B19**（B18 已收口，本批由用户 2026-11-27 当轮指令立项）。
> 控制器：本会话（root）。实现全部由 worker 子会话落盘，控制器**零改** `apps\**` / `packages\**`。
> 状态：**只出计划，本批尚未开工**。计划建立时间 2026-11-27。
>
> **数字纪律**：本文出现的文件行号、表数量、测试计数、门禁期望值均为**计划期回读值**，落地每一棒必须当场回读盘上产物再引用，不得照抄本文（AGENTS.md 证据纪律）。

---

## 1. 背景与盘上现状

「学习管理」当前**只是一个占位页**，背后零数据、零表、零仓储：

| 事实 | 落点 |
|---|---|
| 导航第 6 项「学习管理」已存在 | `apps/desktop/lib/src/widgets/shell/nav_rail.dart`（约 L49–55 / L65–71），key `shell-nav-learning` |
| Ctrl+6 已绑定 | `apps/desktop/lib/src/app.dart`（约 L260–262） |
| 路由指向占位组件 | `apps/desktop/lib/src/app.dart`（约 L368）`'learning' => const _LearningPlaceholder()` |
| 占位渲染与 key | `apps/desktop/lib/src/app.dart`（约 L395–420），`ValueKey('learning-placeholder')` |
| 占位断言测试 | `apps/desktop/test/b16_nav_learning_test.dart`（约 L255–269） |

数据侧现状：

- 表共 18 张，**没有任何学习相关实体**：`packages/core_db/lib/src/tables.dart`（约 L30–84 `TableNames`）。
- schema 版本 **3**：`packages/core_db/lib/src/migrations.dart`（约 L36 `currentSchemaVersion = 3`）。
- `docs/schema_v1.sql` 状态 **FROZEN @ P0-D2**（`docs/schema_v1.sql` 约 L4–9）——**本批不得修改**。
- `day_log.learning` 是**复盘三段自由文本**（`docs/schema_v1.sql` 约 L63/L74；`packages/core_data/lib/src/entities.dart` 约 L166/L189），语义是「今日学到了什么」的日记字段，**与学习计划无关，不得复用/改名**。
- `plan_item` 表（`docs/schema_v1.sql` 约 L122–144）只有单日时段，**无跨天起止、无资料关联、无分节、无进度**，不足以承载学习计划。
- `'learning'` 现有唯一身份是**分类字符串**（`apps/desktop/lib/src/data/goal_category.dart`、`project_domain_catalog.dart`），与学习资料分类不是同一概念。

结论：**必须新建学习域数据模型 + 页面 + 右轨面板，不能靠既有表拼装。**

### 1.1 右轨与拖拽的既有约定（复用，不新造）

| 机制 | 真源 |
|---|---|
| 右轨面板注册 | `apps/desktop/lib/src/app.dart`（约 L327–332 `_railPanels`、L438–473 `todayRailPanels`，已有 5 块） |
| 面板壳 | `apps/desktop/lib/src/widgets/shell/tool_rail.dart`（约 L11–29 `ShellRailPanel`；L36–118 `ToolRail`，宽 290、`panelGap=14`） |
| 面板样例 | `widgets/timeline/todo_rail_panel.dart`、`pages/today_page.dart`（约 L807 `HabitOverviewPanel`）、`widgets/recurring_rail_panel.dart`、`widgets/week_goal_rail_panel.dart` |
| 复选框 | `apps/desktop/lib/src/widgets/ledger_checkbox.dart`（约 L17–45） |
| 拖拽载荷 | 字符串 `"<type>:<id>"`，`DragTarget<String>` + `onAcceptWithDetails`；参考 `pages/goals_week_page.dart`（约 L83–108）、`pages/goals_month_page.dart`（约 L162–166）、`widgets/goal_upstream_panel.dart`（约 L148） |
| 日网格落库 | `widgets/timeline/day_grid.dart`（约 L338–344 `DragTarget`；L1174–1214 `_onDrop` 按 `':'` 切分，只认 `plan` / `todo` / `habit`） |
| store 范式 | `apps/desktop/lib/src/data/goal_store.dart`（约 L382） |
| 仓储范式 | `packages/core_data/lib/src/repositories.dart`（DayLog/Todo/Habit/Settings + 约 L1582–1592 `ActLogRepositories` 聚合）；独立仓储先例 `packages/core_data/lib/src/recurring.dart`（约 L53） |
| 内存库测试范式 | `apps/desktop/test/b16_nav_learning_test.dart`（约 L61–89：`openInMemoryActLogDatabase()` + `ActLogRepositories` + `ProviderContainer(overrides: [...])`；约 L100–107 `_settle`，**禁用 `pumpAndSettle`**） |

---

## 2. 需求逐条裁决

用户原话拆成 6 条，逐条给落点与裁决：

| 编号 | 用户原话 | 裁决 | 落点 |
|---|---|---|---|
| **L1** | 搭建一个学习数据库，保存语言学习、诗词文学、管理营销等等分类的学习资料 | 在**现有主库**加 **5 张新表**（见 §3），走 schema **v4** 迁移；不建第二库文件 | `packages/core_db/lib/src/{tables,connection,migrations}.dart` |
| **L2** | 每份学习资料，根据学习时长进行分节（15 分钟、30 分钟等） | 新增 `learning_section` 表，一条分节 = 名称 + 时长（分钟）+ 顺序；资料的「总时长/节数」由分节聚合（写时维护 `total_minutes` 缓存） | 同上 + `packages/core_data/lib/src/learning.dart` |
| **L3** | 学习管理页面，列出可以学习的资料；点击资料，添加到学习计划中，添加时选择每周学习几天（进行周几的选择）、每天学习的时长 | 真页面替换占位：分类筛选 + 资料列表 + 资料详情（分节表）+「加入学习计划」弹窗（7 个周几多选 + 每日时长下拉） | `apps/desktop/lib/src/pages/learning_page.dart`、`widgets/learning/learning_plan_dialog.dart`、`app.dart` 路由 |
| **L4** | 添加学习计划后，在日志主页面右侧，出现学习计划模块 | `todayRailPanels` 追加一块 `ShellRailPanel`，**仅当存在 active 计划时出现**（条件注册） | `apps/desktop/lib/src/app.dart` + `widgets/learning/learning_plan_rail_panel.dart` |
| **L5** | 每天完成学习后，可以打钩（打钩后回填到计划中） | 右轨今日条目：`LedgerCheckbox` → `learning_session.status = 'done'` + `completed_at`；进度由 session 状态派生（节数 / 分钟），**不回写 plan 行** | 右轨面板 + `learning_store.dart` + `learning.dart` |
| **L6** | 也可以在没完成时，拖入计划中 | 未完成条目 `Draggable<String>`（载荷 `learn:<sessionId>`），拖到本周另一星期行 ⇒ `rescheduleSession(id, newDay)`（改期，不新建、不删除） | 右轨面板 |

### 2.1 三处需要记录的裁决（含回填点）

**(a) 点击资料 = 选中详情，加入计划走显式按钮。**
用户原话是「点击资料，添加到学习计划中」。直接「点一下就弹加入弹窗」在列表滚动/误触时容易误加计划，所以定为：卡片整块点击 = 选中并在右侧显示详情；卡片右侧与详情页各一个「加入学习计划」按钮，二者打开**同一个**弹窗。
回填点：若用户坚持「点整卡即弹窗」，只需把卡片 `onTap` 从 `_select` 改成 `_openPlanDialog`（约 3 行）。

**(b) 「每天学习的时长」= 从该资料分节时长里选。**
分节时长是资料自带属性（15/30/45…），计划每日时长只能在**该资料已有分节时长去重集合**里选，避免出现「资料只有 30 分钟一节，却要求每天 60 分钟」这种无法满足的计划。
回填点：若要允许任意分钟数（如 25），弹窗下拉改数字输入 + `ensureWeek` 允许拆节，改动集中在 `learning_plan_dialog.dart` 与 `ensureWeek` 的取节算法。

**(c) 「拖入计划」= 在本周内改期。**
判定依据：右轨面板本身就是「计划」，拖入其中最有信息量的语义是「这一天学不了，挪到另一天」。落地为改 `learning_session.day`，原星期行可再拖回。
回填点：若要支持「拖到日志时间轴成为日程项」，需扩 `day_grid._onDrop` 的 `learn:` 分支（本批**不做**，见 §11）。

---

## 3. 数据模型（schema v4）

### 3.1 为什么复用主库

不新建第二个 `.sqlite` 文件。理由：备份/快照/`sync_state`/`oplog`/单事务跨表一致性全部建立在现有数据库之上（`packages/core_db/lib/src/connection.dart` 约 L28–49 `@DriftDatabase`、L58 `schemaVersion`、L85 `openInMemoryActLogDatabase()`）；第二库会让「一次备份」变成两个文件的一致性问题，且内存库测试范式要重写。

### 3.2 五张表（列清单）

**`learning_category`（分类）**
`id` TEXT PK · `name` TEXT NOT NULL · `sort_order` INT NOT NULL DEFAULT 0 · `archived` INT NOT NULL DEFAULT 0 · `created_at` INT NOT NULL · `updated_at` INT NOT NULL
唯一约束：`name` 唯一（同库内不重名），索引 `(sort_order, name)`。

**`learning_material`（学习资料）**
`id` TEXT PK · `category_id` TEXT NOT NULL · `title` TEXT NOT NULL · `source` TEXT（作者/出处，可空）· `summary` TEXT（可空）· `total_minutes` INT NOT NULL DEFAULT 0（分节聚合缓存）· `archived` INT NOT NULL DEFAULT 0 · `sort_order` INT NOT NULL DEFAULT 0 · `created_at` INT · `updated_at` INT
索引：`(category_id, sort_order)`。

**`learning_section`（分节）**
`id` TEXT PK · `material_id` TEXT NOT NULL · `title` TEXT NOT NULL · `minutes` INT NOT NULL · `sort_order` INT NOT NULL · `created_at` INT · `updated_at` INT
约束：`minutes > 0`；索引 `(material_id, sort_order)`。

**`learning_plan`（学习计划）**
`id` TEXT PK · `material_id` TEXT NOT NULL · `weekday_mask` INT NOT NULL（bit0=周一 … bit6=周日，1..127）· `daily_minutes` INT NOT NULL · `start_day` TEXT NOT NULL（`yyyy-MM-dd`）· `status` TEXT NOT NULL（`active` / `paused` / `done` / `archived`）· `created_at` INT · `updated_at` INT
约束：`weekday_mask BETWEEN 1 AND 127`；索引 `(status, material_id)`。

**`learning_session`（日程 / 打钩记录，是 L5/L6 的唯一落点）**
`id` TEXT PK · `plan_id` TEXT NOT NULL · `day` TEXT NOT NULL（`yyyy-MM-dd`）· `section_id` TEXT NOT NULL · `minutes` INT NOT NULL（**快照**，分节后续被改不影响已生成日程）· `sort_order` INT NOT NULL · `status` TEXT NOT NULL（`planned` / `done` / `skipped`）· `completed_at` INT（可空）· `created_at` INT · `updated_at` INT
唯一约束：`(plan_id, day, section_id)` ⇒ 幂等物化的硬保证。
索引：`(plan_id, day)`、`(day, status)`。

**不建硬外键**：与既有 18 张表的风格一致（引用完整性由仓储层校验），避免 drift 建表顺序与迁移期的外键检查复杂度。**这条是显式裁决，worker 不得自行加 FK。**

### 3.3 迁移策略

1. `packages/core_db/lib/src/tables.dart`：`TableNames` 18 → 23，新增 5 个表名常量与索引名常量（索引必须显式列，见 `migrations.dart` 约 L139–145 `_createEntities` 的注释）。
2. `packages/core_db/lib/src/connection.dart`：`@DriftDatabase` 表清单（约 L28–49）加入 5 张新表；`schemaVersion` 3 → 4（约 L58）。
3. `packages/core_db/lib/src/migrations.dart`：
   - `currentSchemaVersion = 4`；
   - 新增 `schemaV4EntityNames`（5 表 + 索引），**不改** `schemaV2EntityNames` / `schemaV3EntityNames`；
   - `buildMigrationStrategy`（约 L87–129）加一级：`if (from < 4) await _createEntities(<v4 集合>)`。
4. `docs/schema_v1.sql` **保持 FROZEN 原样**；新增 `docs/schema_v4.sql` 记录 v4 全量 DDL（只读档案，由控制器写，worker 只提供 DDL 文本）。
5. 初始分类种子：迁移末尾插入 3 条 —— 语言学习 / 诗词文学 / 管理营销（`INSERT OR IGNORE`，用户可改名可新增；**不写死在 UI 常量里**）。

### 3.4 迁移红→绿判据（W1 必须给出）

- 空库直建（`openInMemoryActLogDatabase()`）后，`PRAGMA table_info` 对 5 张新表逐列等于 §3.2；`PRAGMA index_list` 含上述 3 组索引。
- 造一个 v3 库（写入 day_log / plan_item / goal 各 1 行）→ 升到 v4：既有 18 张表**行数与内容不变**，新 5 表可读写，种子分类为 3 条。
- 重复打开 v4 库不重复建表、不重复插种子。

---

## 4. 数据层（`packages/core_data`）

新建 `packages/core_data/lib/src/learning.dart`（独立仓储，沿用 `recurring.dart` 先例，不把 5 张表塞进 1500+ 行的 `repositories.dart`）。`repositories.dart` 只改 `ActLogRepositories` 聚合（约 L1582–1592）加一个 `final LearningRepository learning;`。

API 草案（命名以落地时的一致风格为准）：

```dart
class LearningRepository {
  // 分类
  Stream<List<LearningCategoryRow>> watchCategories();
  Future<String> upsertCategory({String? id, required String name, int sortOrder = 0});
  Future<void> archiveCategory(String id);

  // 资料
  Stream<List<LearningMaterialRow>> watchMaterials({String? categoryId});
  Future<String> upsertMaterial({String? id, required String categoryId, required String title,
                                 String? source, String? summary, int sortOrder = 0});
  Future<void> archiveMaterial(String id);

  // 分节
  Stream<List<LearningSectionRow>> watchSections(String materialId);
  Future<void> replaceSections(String materialId, List<LearningSectionDraft> drafts); // 事务内 diff，维护 total_minutes

  // 计划
  Stream<List<LearningPlanRow>> watchActivePlans();
  Future<String> createPlan({required String materialId, required int weekdayMask,
                             required int dailyMinutes, required String startDay});
  Future<void> setPlanStatus(String id, LearningPlanStatus status);

  // 日程
  Future<int> ensureWeek(String weekStartDay);            // 幂等物化；返回新建行数
  Stream<List<LearningSessionRow>> watchWeek(String weekStartDay);
  Stream<List<LearningSessionRow>> watchDay(String day);
  Future<void> setSessionStatus(String id, LearningSessionStatus status); // done/planned/skipped + completed_at
  Future<void> rescheduleSession(String id, String newDay);              // L6
  Stream<LearningPlanProgress> watchPlanProgress(String planId);          // 节数/分钟派生
}
```

**`ensureWeek` 取节算法（L2+L3 的接缝，必须按此实现）**
1. 对每个 `status = 'active'` 的计划，取 `[weekStartDay, weekStartDay+6]` 内 `weekday_mask` 命中的日子，且 `day >= plan.start_day`；
2. 每一天按 `sort_order` 取该计划**尚未被任何 session 消费**的分节，**贪心累计到 `>= daily_minutes` 为止**（至少 1 节；剩余不足时取剩余全部）；
3. 生成 `learning_session` 行，`INSERT OR IGNORE`（靠 `(plan_id, day, section_id)` 唯一约束保证幂等）；
4. 全部节被消费 ⇒ 该计划 `status` 置 `done`（写库一次，`updated_at` 同步）。

**约束**：`ensureWeek` 必须整体在一个事务里；日期一律用**本地日 key**，禁止 UTC（见 §11 风险 2）。

---

## 5. 桌面 store

新建 `apps/desktop/lib/src/data/learning_store.dart`（范式对齐 `goal_store.dart` 约 L382）：

- `learningStoreProvider`：`Provider<LearningStore>`；
- 暴露 `AsyncValue<LearningCatalog>`（分类 + 资料 + 选中资料的分节）与 `AsyncValue<LearningPlanBoard>`（本周 7 列 + 今日条目 + 进度）；
- `LearningPlanBoard` 内必须**预先算好**派生量：`weekStartDay`、`List<LearningDayColumn>`（7 条：星期序号 / 节数 / 分钟 / 是否今日 / 是否排课日）、`todaySessions`、`doneCount`、`totalCount`；
- 变更方法（`createPlan` / `setSessionDone` / `reschedule`）一律「写仓储 + 让 stream 自己刷」，**不做本地乐观状态**（避免与 drift 流双真源）；
- 跨日：面板首次挂载与每次日期变化时调一次 `ensureWeek(本周一)`；用与 `todayProvider` 同一套本地日 key 派生，**不新造日期工具**。

---

## 6. 学习管理页（L3）

`apps/desktop/lib/src/pages/learning_page.dart`（新），`app.dart` 约 L368 路由改为 `'learning' => const LearningPage()`，删除 `_LearningPlaceholder`（约 L395–420）与其 key。

### 6.1 布局（760 宽为硬底线）

```
Column
├─ 顶栏: 标题「学习管理」 + 分类 chips（全部 / 语言学习 / 诗词文学 / 管理营销 / …） + [新建资料]
└─ Expanded → Row
   ├─ 资料列表（flex 3，min 280）
   │    卡片: 标题 / 分类 / 总时长 / 共 N 节 / [已加入计划] / [加入计划]
   └─ 资料详情（flex 4，min 340）
        标题 · 来源 · 总时长
        分节表: 序号 | 节名 | 时长
        按钮: [编辑资料] [加入学习计划]
```

- 空态（无资料）：提示文案 + 「新建学习资料」（key `learning-material-empty`）。
- 列表按分类过滤在数据库侧完成（`watchMaterials(categoryId:)`），不在内存里 filter。
- **不引入新配色**：一律走 `ThemeTokens`（`ink` / `meta` / `hairSoft` / `paper` / `inkWash`），圆角真源 `AppTokens.radius = 4`（AGENTS.md §7.1）。

### 6.2 加入学习计划弹窗（L3）

`widgets/learning/learning_plan_dialog.dart`
- 周几：7 个多选 chip（一 二 三 四 五 六 日），key `learning-plan-weekday-1..7`；
- 每天学习时长：`DropdownButton<int>`，选项 = 该资料分节时长的**去重升序集合**；默认取最小值；
- 开始日期：默认今天，可改（P1，可后置；落地时若不做就固定今天并留注释）；
- 校验：至少选 1 天（否则确认按钮 disabled）；时长必选；
- 确认 ⇒ `createPlan` + `ensureWeek(本周一)` + 关弹窗 + SnackBar「已加入学习计划」；
- 已在计划中的资料：列表卡与详情显示「已加入计划」标记，弹窗确认按钮改为「再建一个计划」（允许同一资料多计划，如工作日 15 分钟 + 周末 45 分钟），**不做唯一性拦截**。

### 6.3 资料维护（L1/L2 的录入口）

`widgets/learning/learning_material_dialog.dart`（新建/编辑合一）
- 字段：名称、分类（下拉，含「新建分类…」）、作者/出处、简介；
- 分节编辑：可增删行，每行「节名 + 分钟」，至少 1 节；保存时 `replaceSections` 事务内 diff；
- 校验：名称非空、分节分钟 > 0、至少 1 节。

---

## 7. 日志页右轨「学习计划」模块（L4/L5/L6）

`widgets/learning/learning_plan_rail_panel.dart`（新）+ `app.dart` `todayRailPanels`（约 L438–473）追加一块。

### 7.1 注册与条件显示

- `ShellRailPanel` id 用 `learning-plan`，标题 `t.learningRailTitle`；
- **仅当 `watchActivePlans()` 非空时出现**：`todayRailPanels` 是同步列表，因此条件判据取 `learningStoreProvider` 已缓存的 `hasActivePlan`（首次为 false 时不注册，store 加载后 `ref.listen` 触发重建）。落地时若发现 `todayRailPanels` 无法响应式重建，回填点是把判据下沉到面板内部返回 `SizedBox.shrink()`——**但那会留一条空壳标题**，所以优先改注册处。
- 面板顺序：排在「未完成周目标」之后（最后一块）。

### 7.2 内容

```
学习计划                    本周 3/7 节
──────────────────────────
今天 · 周三
  ☐ 英语音标 · 第 2 节  15 分钟
  ☐ 英语音标 · 第 3 节  15 分钟
──────────────────────────
本周
  周一  —            (DragTarget)
  周二  2 节 30 分钟
  周三  2 节 30 分钟  ← 今日
  周四  …            (DragTarget)
  …
──────────────────────────
拖到其他星期可改期（meta 提示）
```

- 今日条目：`LedgerCheckbox`（key `learning-session-check-<id>`）+ 资料名 · 节名 + 分钟；
- 本周行：`DragTarget<String>`（key `learning-plan-day-<1..7>`），显示当日节数/分钟；
- 拖拽源：**未完成**条目包 `Draggable<String>`（key `learning-session-chip-<id>`，载荷 `learn:<sessionId>`）；已完成条目不可拖；
- `onAcceptWithDetails`：载荷不以 `learn:` 开头 ⇒ 忽略（不报错、不落库）；是 ⇒ `rescheduleSession(id, 该行 day)`；
- 空态：今日无课 ⇒ 「今天没有学习安排」（key `learning-rail-empty-today`）；
- 超高：整块 `SingleChildScrollView`（右轨宽 290，7 行 + 今日条目在 760 高下必然超）。

### 7.3 打钩回填（L5）

`LedgerCheckbox.onChanged(true)` ⇒ `learningStore.setSessionDone(id)` ⇒ 仓储写 `status='done'` + `completed_at=now` ⇒ drift 流刷新 ⇒
1. 右轨标题进度 `x/y 节` 变化；
2. 学习管理页资料卡「已学 x/y 节」同步变化（同一 `watchPlanProgress` 源）。

**不回写 `learning_plan` 行**——进度是派生量，避免双真源漂移。这是显式裁决。

---

## 8. 交互契约（key / 载荷 / l10n）

### 8.1 keys（新，必须逐字钉死）

| key | 用途 |
|---|---|
| `learning-page-root` | 页面根 |
| `learning-category-all` / `learning-category-chip-<key>` | 分类筛选 |
| `learning-material-empty` | 空态 |
| `learning-material-item-<id>` | 列表项 |
| `learning-material-detail-<id>` | 详情根 |
| `learning-material-new` | 新建资料 |
| `learning-material-edit-<id>` | 编辑资料 |
| `learning-plan-add-<materialId>` | 加入计划（卡片/详情共用一套） |
| `learning-plan-dialog` | 弹窗根 |
| `learning-plan-weekday-<1..7>` | 周几 chip |
| `learning-plan-daily-minutes` | 每日时长下拉 |
| `learning-plan-confirm` / `learning-plan-cancel` | 确认/取消 |
| `learning-session-check-<id>` | 打钩 |
| `learning-session-chip-<id>` | 拖拽源 |
| `learning-plan-day-<1..7>` | 改期落点 |
| `learning-rail-panel` / `learning-rail-progress` / `learning-rail-empty-today` | 右轨 |

**下线**：`learning-placeholder`（占位页整块删除）⇒ `b16_nav_learning_test.dart` 约 L255–269 的断言必须同步改。

### 8.2 拖拽载荷

`learn:<sessionId>`。**不得复用** `plan:` / `todo:` / `habit:`（`day_grid.dart` 约 L1174–1214 按前缀落库，误用会写错表）。

### 8.3 l10n（新 part 文件 `l10n/parts/learning.dart`）

新增 key 草案（zh/en 双语，插值项标注 `{}`）：

```
learning-page-title              学习管理 / Learning
learning-category-all            全部 / All
learning-material-empty          还没有学习资料 / No study materials yet
learning-material-new            新建资料 / New material
learning-material-total-minutes  总时长 {n} 分钟 / {n} min total
learning-material-section-count  共 {n} 节 / {n} sections
learning-material-in-plan        已加入计划 / In a plan
learning-plan-add                加入学习计划 / Add to plan
learning-plan-dialog-title       加入学习计划 / Add to study plan
learning-plan-weekday-label      每周学习日 / Study days
learning-plan-daily-minutes      每天学习时长 / Daily minutes
learning-plan-confirm            确定 / Confirm
learning-plan-cancel             取消 / Cancel
learning-plan-created            已加入学习计划 / Added to study plan
learning-rail-title              学习计划 / Study plan
learning-rail-progress           本周 {done}/{total} 节 / {done}/{total} this week
learning-rail-empty-today        今天没有学习安排 / Nothing scheduled today
learning-rail-defer-hint         拖到其他星期可改期 / Drag to another weekday to reschedule
learning-rail-today              今天 / Today
learning-section-minutes         {n} 分钟 / {n} min
learning-material-form-new       新建学习资料 / New study material
learning-material-form-edit      编辑学习资料 / Edit study material
learning-material-field-title    资料名称 / Title
learning-material-field-source   作者 / 出处 / Author or source
learning-material-field-category 分类 / Category
learning-material-field-summary  简介 / Summary
learning-section-add             添加分节 / Add section
learning-section-field-minutes   分节时长（分钟） / Section length (min)
learning-section-field-title     节名 / Section title
learning-plan-progress-done      已完成 / Done
```

- part 形状照 `l10n/parts/shell.dart`（约 L4–17）；聚合登记 `l10n/app_localizations.dart`（约 L52 / L124）。
- **硬计数必须按实测重算**：`apps/desktop/test/l10n_base_test.dart` 约 L27–29（getter 数两侧相等，当前 625/625）、约 L44–46（插值条数，当前 53）、约 L108–114（总数，当前 684）、约 L117–125（kebab 正则）、约 L129–154（前缀归属）。**本计划的 625/53/684 是抄录值，落地时必须回读该文件当前值再改**，且新增 `learning-` 前缀要登记进归属表。

---

## 9. 测试与门禁

### 9.1 新增测试

| 文件 | 覆盖 |
|---|---|
| `packages/core_db/test/learning_v4_migration_test.dart` | §3.4 三条红→绿 |
| `packages/core_data/test/learning_repository_test.dart` | 分类/资料/分节 CRUD；`createPlan` 校验；`ensureWeek` 幂等（调两次行数不变）与贪心取节；`rescheduleSession`；`watchPlanProgress` |
| `apps/desktop/test/b19_learning_page_test.dart` | 列表渲染/分类筛选/空态/详情/弹窗校验（0 天时确认 disabled） |
| `apps/desktop/test/b19_learning_rail_test.dart` | 无计划时右轨不出现；有计划时出现；打钩后进度变化；拖拽改期；`learn:` 之外载荷被忽略 |
| `apps/desktop/test/b19_learning_flow_test.dart` | 端到端：建资料 → 加入计划 → 右轨出现今日条目 → 打钩 → 进度 1/1 |

### 9.2 必须同步的既有装置

| 文件 | 改什么 |
|---|---|
| `apps/desktop/test/b16_nav_learning_test.dart`（约 L255–269） | 占位断言 → 真页面根 key |
| `apps/desktop/test/l10n_base_test.dart` | 三处计数 + 前缀归属（按实测） |
| `reports/task51-gate.ps1`（约 L462–480 `$pkgAllowed`） | 加 `packages/core_data/lib/src/learning.dart`；core_db 新文件若不在白名单一并加 |
| `reports/task51-gate.ps1`（约 L493–498 `$expect`） | 三包命中数按实测改（抄录值 core_data 204 / core_db 96 / core_domain 91 **不可照抄**） |
| `docs/schema_v4.sql`（新建） | v4 全量 DDL 档案 |

### 9.3 门禁判据（每棒 + 收口）

```powershell
# 跑全量前必须先把测试缓存挪走（改名，不删）
$tc='F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build'
if (Test-Path $tc) { Rename-Item -LiteralPath $tc -NewName ('build_moved_' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }

$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
Set-Location 'F:\soft\00selfmade\practilog\apps\desktop'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze      # 逐字 No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact
pwsh -NoProfile -ExecutionPolicy Bypass -File 'F:\soft\00selfmade\practilog\reports\task51-gate.ps1' -ExpectDesktopTests <当轮实测数>
```

- desktop 全量基线：**1121**（B18 收口值）。B19 新增用例 ⇒ 收口数必然变大，`-ExpectDesktopTests` 必须传当轮实测数（脚本内建 `$baseline=596` 不是增量）。
- worker **只跑自己写集内测试文件**（多棒并发跑全量会争 `build\native_assets\windows\sqlite3.dll`）；权威全量由控制器独占跑。
- 全项目**禁用 `pumpAndSettle`**（drift 流会挂），用 `l10n_harness` + 既有 `_settle` 范式。
- 出包（如需装机验收）严格两步：① 在 `apps\desktop` 内 `flutter build windows --release`；② `tools\build\make_installer.ps1 -Version '1.0.0'`。重编判据只比 `data\app.so` 的 sha16（`actlog.exe` 恒不变）。

---

## 10. 写集与波次

| 波 | 主题 | 可写文件（**且仅**这些） | 前置 |
|---|---|---|---|
| **W1** | schema v4：5 表 + 迁移 + 索引 | `packages/core_db/lib/src/tables.dart`、`connection.dart`、`migrations.dart`、`packages/core_db/test/learning_v4_migration_test.dart`（新建）、`packages/core_db/CHANGELOG`（若项目有此约定） | — |
| **W3** | l10n：新 part + 键 + 计数 | `apps/desktop/lib/src/l10n/l10n_keys.dart`、`l10n/parts/learning.dart`（新建）、`l10n/app_localizations.dart`、zh/en 资源文件、`apps/desktop/test/l10n_base_test.dart` | — |
| **W2** | 数据层：学习仓储 + 聚合注册 | `packages/core_data/lib/src/learning.dart`（新建）、`packages/core_data/lib/src/repositories.dart`（**仅** `ActLogRepositories` 聚合处）、`packages/core_data/test/learning_repository_test.dart`（新建） | W1 |
| **W4** | 桌面：store + 页面 + 弹窗 + 右轨 + 路由 | `apps/desktop/lib/src/data/learning_store.dart`（新建）、`pages/learning_page.dart`（新建）、`widgets/learning/*`（新建）、`app.dart`、`apps/desktop/test/b19_*.dart`（新建）、`apps/desktop/test/b16_nav_learning_test.dart` | W1+W2+W3 |

- **W1 ∥ W3 可并行**；W1 完 → W2；W2+W3 完 → W4。
- **写集纪律（R1）**：worker 只改上表列出的文件。发现必须写写集外文件 ⇒ 立刻停下报控制器，由控制器在 `reports/b19-writeset-amendment-w<N>.md` 追加并留档后再继续。
- **冲突点**：`app.dart` 只归 W4（路由 + 右轨注册 + provider 接线一次性完成），**不得**让 W4 与另一棒并行改它。
- 控制器（root）**零改** `apps\**` / `packages\**`；只写 `docs\`、`reports\`、`AGENTS.md`、计划与门禁脚本。

---

## 11. 风险、回填点与本次不做

1. **760 宽英文态（用户已挂待办）**：本批所有新页面/面板必须过「760 宽 + en」用例——`tester.binding.setSurfaceSize(Size(760, 720))` + `tester.takeException()` 为空。**用户明确本轮不验证现有英文态**，但新页面不得新增同类债务。
2. **跨日/跨周边界**：日 key 一律本地时区派生，复用既有 helper；必须有一条「周日 23:59 → 周一 00:01」用例。禁 UTC。
3. **幂等**：重复进入日志页 / 同周反复切页不得重复生成 session（唯一约束 + `INSERT OR IGNORE`）。
4. **分节被改/被删**：已生成 session 保留 `minutes` 快照；资料归档不级联删计划与历史 session（历史是学习记录，不可丢）。
5. **右轨高度**：内容必须可滚动，且不得把既有 5 块挤成不可用（面板在 760×720 下需实测）。
6. **`learn:` 载荷串味**：`day_grid._onDrop`（约 L1174–1214）现有分支不得改动；必须有一条用例证明 `learn:` 落到日网格时被忽略而不是误写 `plan_item`。
7. **schema 冻结**：`docs/schema_v1.sql` 不改；`schemaV2/V3EntityNames` 不改。
8. **门禁数字**：`$expect` 三包计数必须实测回填，禁止照抄本计划。
9. **本次不做**：① 学习资料导入（文件/网页）；② 学习统计图表/连续打卡；③ 拖到日志时间轴成为日程项；④ 学习提醒（reminder 联动）；⑤ 多设备同步语义扩展（沿用现有 oplog/sync_state，不新增协议）。

---

## 12. 验收清单（用户肉眼）

1. 学习管理页可新建分类、新建资料（含 ≥1 个分节，分节时长如 15/30/45）。
2. 页面按分类筛选列出资料；点卡片看到详情与分节表。
3. 点「加入学习计划」→ 选周几（多选）+ 每天时长 → 确定，提示「已加入学习计划」。
4. 切到日志主页 → 右侧出现「学习计划」模块，含今日待学与本周 7 天。
5. 打钩今日条目 → 右轨进度 +1，学习管理页该资料「已学 x/y 节」同步 +1。
6. 未完成条目拖到周四 → 今日块消失、周四行 +1；再拖回 → 复原。
7. 无任何 active 计划时，日志页右侧**没有**「学习计划」模块。
8. 760 宽 + en 不溢出（本轮只要求新页面过关，既有英文态仍挂待办）。

---

## 13. 交付节奏（建议）

- **本轮（B19-0）**：本计划落盘 + B18 横线修复 + B18 改动提交推送。**不实现学习功能**。
- **下一轮（B19-1）**：W1 ∥ W3 起棒 → W2 → W4；每棒附红→绿证据。
- **B19-2**：控制器独占跑 analyze / 全量 / gate；出包（`flutter build windows --release` → `make_installer.ps1`）交用户装机肉眼验收。
- **B19-3**：台账收口（§11.x 追加），更新 AGENTS.md §7 状态与 R3 分发真源（新包产出后）。