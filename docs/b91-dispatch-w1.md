# B9-W1 派工书 · 个人品牌管理模块（蓝图页矩阵**上方**）

> 合同性质：**本文件是本棒唯一实现契约**。与 `docs\plan-goals-ui-batch9.md` 冲突时，以本文件为准；与用户当轮原话冲突时，以用户原话为准。worker 不得再自行裁决范围。

---

## 0. 合同信息

| 项 | 值 |
|---|---|
| 仓库根（一切产出落在此目录内） | `F:\soft\00selfmade\practilog` |
| 棒次 | **B9-W1**（B9 共 4 棒，**串行**，禁止并行派工） |
| 设计真源 | `F:\soft\00selfmade\practilog\docs\plan-goals-ui-batch9.md`（W1 段落：§4「W1 · 个人品牌管理模块」行 93–130；l10n 预算：§5.1 行 234–271；切面内容：文末「附录 · 参考文章《个人品牌建设全解》要点 → 切面内容规划」行 337–370） |
| 项目规范 | `F:\soft\00selfmade\practilog\AGENTS.md`（R1 写集纪律 / R2 门禁 / R5 证据纪律 / §5 本机工具坑，**动手前必须读**） |
| 起点 | HEAD = `c11e17d`（B8 全棒已入库，ahead 12 / behind 0，**未 push**） |
| 基线测试数 | desktop 全量 **920**（本棒结束 = `920 + N1`，`N1 ≥ 6`） |
| 本棒产出 | 提交 1 个 commit（只含本棒写集，**不 push**） |

---

## 1. 背景与本棒目标

B8 已全棒收口。B9 是用户提的两条优化需求里的**第 1 条**：

> 蓝图页面，在人生蓝图矩阵上面添加一个「个人品牌管理」模块，内容参考文章 https://www.doubao.com/thread/xlTAj7kOKM5w7yyQ1 进行规划。

**本棒只做这一件事**（B9 第 2 条「矩阵四标签页 + 空态 + 铅笔 + 拆分」由 W2/W3 做，**本棒严禁提前动**）。

白话目标：蓝图页最上面多一张卡片，卡片里左边 10 个切面导航，右边是当前切面的「要点 / 范例 / 反例」+ 两个输入框（怎么说 / 补充说明）+ 保存按钮；保存后落进 SQLite 的 `goal` 表（`kind='brand'`、`facet=<切面>`）；页面下方既有的人生蓝图矩阵、待确认待办区、平衡轮**一字不改**。

---

## 2. 写集（**你独占**，表外任何文件一律不得改）

| 文件 | 动作 |
|---|---|
| `apps/desktop/lib/src/widgets/goal_brand_panel.dart` | **新增** |
| `apps/desktop/lib/src/pages/goals_blueprint_page.dart` | 改：**只**在矩阵块**上方**插入一个品牌面板块；既有三块与它们的 ValueKey 一律不动 |
| `apps/desktop/lib/src/l10n/parts/goals.dart` | 改：**+54 键**（abstract 声明 + zh + en 三处齐全） |
| `apps/desktop/lib/src/l10n/l10n_keys.dart` | 改：+54 常量 + +54 条 `byGetter` 映射 |
| `apps/desktop/test/l10n_harness.dart` | 改：+54 访问器登记 |
| `apps/desktop/test/l10n_base_test.dart` | 改：**5 处计数 522→576 / 579→633** |
| `apps/desktop/test/task78_b9_brand_panel_test.dart` | **新增**（≥ 6 例） |

**禁改清单（碰到就是越界）**：`goal_blueprint_matrix.dart`、`packages/**`（任何文件）、`data/goal_store.dart`、`providers.dart`、`app.dart`、`widgets/goals/goal_split_dialog.dart`（W3 的文件）、`docs/**` 除本派工书外、`reports/**` 不得 `git add`。

**零 schema 变更、零 `packages/**` 改动**：品牌行复用既有 `goal` 表（`kind='brand'` 已在 CHECK 白名单内，`facet` 是自由 TEXT 列，**不需要**迁移、不需要加 CHECK）。

---

## 3. 实现契约

### 3.1 新文件 `goal_brand_panel.dart`

- 公开一个 widget（建议 `GoalBrandPanel`），`ConsumerStatefulWidget`（**自己取数**，不要让蓝图页 `_load()` 承担）。
- 取数通道：`ref.watch(goalStoreProvider)`（定义在 `apps/desktop/lib/src/providers.dart:540`），`GoalStore` 在 `apps/desktop/lib/src/data/goal_store.dart:382`。
- 面板自带 `Future` 装载 + 保存后刷新（`setState` 重载或 `ref.invalidate`）。
- **零 `Icons.`**（本模块不使用任何 Material 图标；折叠指引块用 `TextButton`）。
- 布局：一张卡片 = 标题行（`goalBrandSection`）+ 左侧切面导航（10 项）+ 右侧编辑区 + 底部可折叠指引块。

### 3.2 取数

```dart
final List<Goal> rows = await store.listGoals(kind: GoalKind.brand);
```

- 按 `Goal.facet`（`GoalFacet?`，见 `packages/core_domain/lib/src/goal.dart:151`）分桶；**切面 = 一行**。
- `GoalFacet` 共 10 值，code 即：statement / word / audience / promise / cost / evidence / contrast / strength / errc / identity。
- 每个切面**最多一行**（重复行取 id 最大 / 最新的一条；若库里真有重复，按 id 升序取第一条并在测试里断言幂等）。
- `GoalKind.brand` 的 code 是 `'brand'`。

### 3.3 落库（口径已坐实，照抄别猜）

| 场景 | 调用 |
|---|---|
| 该切面**已有**行 | `store.updateGoal(id, title: …, note: …)` —— **不要传 `facet`**（不传 = 不动；传 `null` 也是不动，因为 `null` 的语义是「不改」，`clear` 集合才表示「清空」）。清空补充说明需显式 `clear: {GoalField.note}` |
| 该切面**无**行 | `store.createGoal(kind: GoalKind.brand, facet: F, title: …, note: …)` |
| 空内容 | **不写行**（不建空行、不写空 title 的行）；空输入点保存 = 提示「这一面还空着」，不落库 |

- `createGoal` 签名（`goal_store.dart:403`）：`domain` / `horizon` / `parentId` 均可空 ⇒ 品牌行**不传** domain / horizon。
- `title` 必填且非空；`note` 可空（补充说明留空时传 `null` 即可，**不要**去清别人的值）。

### 3.4 界面结构（逐条实现）

1. **左侧切面导航**：10 项，顺序 = statement / word / audience / promise / cost / evidence / contrast / strength / errc / identity（与 §4 切面表同序）。默认选中 **`audience`**。
2. **右侧编辑区**：
   - 切面标题（切面 label 键）；
   - 要点（hint 键，参考文章要点的中文表述）；
   - 范例（example 键）+ 反例（counterexample 键）；
   - 标题输入框（label = `goalBrandTitleLabel`）；
   - 补充说明输入框（label = `goalBrandNoteLabel`）；
   - 保存按钮（`goalBrandSave`）；
   - 保存反馈：`goalBrandSaved` / `goalBrandSaveFailed`；该切面尚无内容时显示 `goalBrandEmpty`。
3. **底部可折叠指引块**：标题 `goalBrandGuideTitle`，正文 4 条 = 定位公式（`goalBrandGuideFormula`）/ 三层结构（`goalBrandGuideLayers`）/ 三步方法论（`goalBrandGuideMethod`）/ PBE 三维（`goalBrandGuidePbe`）；折叠按钮 `goalBrandGuideToggle`。
   - **五原型（专家/导师/先锋/实干/联结）不单列为切面**，它属于 `identity` 切面的语义范围，在 `identity` 的 hint/范例文案里体现即可（域层切面是冻结的 10 个，**不得新增第 11 个**）。
4. 面板整体插在蓝图页**矩阵块的上方**（矩阵块之前），既有「待确认待办区」「平衡轮」块的位置与内容不变。

### 3.5 ValueKey（**新增键，命名逐字照抄**）

| Key | 位置 |
|---|---|
| `goal-brand-panel` | 面板根 |
| `goal-brand-facet-<facetCode>` | 左侧切面导航项（facetCode ∈ statement/word/audience/promise/cost/evidence/contrast/strength/errc/identity） |
| `goal-brand-title-<facetCode>` | 标题输入框 |
| `goal-brand-note-<facetCode>` | 补充说明输入框 |
| `goal-brand-save-<facetCode>` | 保存按钮 |
| `goal-brand-saved` | 保存成功反馈 |
| `goal-brand-error` | 保存失败反馈 |

其它既有 Key（`goal-blueprint-*`、`goal-blueprint-form-*`）**一律不动**。

---

## 4. l10n 契约（+54 键，**五处同步**）

### 4.1 模块级 14 键（getter / zh / en）

| getter | zh | en |
|---|---|---|
| `goalBrandSection` | 个人品牌管理 | Personal brand |
| `goalBrandSave` | 保存 | Save |
| `goalBrandSaved` | 已保存 | Saved |
| `goalBrandSaveFailed` | 保存失败 | Save failed |
| `goalBrandEmpty` | 这一面还空着，写下第一句就算开始。 | This facet is still empty — one sentence is enough to start. |
| `goalBrandTitleLabel` | 这一面怎么说 | How you say it |
| `goalBrandNoteLabel` | 补充说明 | Notes |
| `goalBrandFacetNavLabel` | 切面 | Facets |
| `goalBrandGuideTitle` | 个人品牌建设全解 | Personal brand, end to end |
| `goalBrandGuideFormula` | 我帮助【目标人群】，在【具体场景】下，解决【什么问题】，通过【我的独特方法】，达到【什么结果】。 | I help 【audience】, in 【situation】, solve 【problem】, through 【my method】, to reach 【result】. |
| `goalBrandGuideLayers` | 三层结构：内在内核 → 能力价值 → 外在感知 | Three layers: inner core → value → visible image |
| `goalBrandGuideMethod` | 三步方法论：定位 → 呈现 → 传播 | Three steps: position → present → spread |
| `goalBrandGuidePbe` | PBE 三维诊断：吸引力 × 差异化 × 认知度 | PBE diagnosis: attraction × differentiation × awareness |
| `goalBrandGuideToggle` | 展开 / 收起指引 | Show / hide the guide |

### 4.2 切面 40 键（10 切面 × 4）

每个切面 4 个 getter：`<Base>`（标签）/ `<Base>Hint`（要点）/ `<Base>Example`（范例）/ `<Base>CounterExample`（反例），`<Base>` 取值：

`goalBrandFacetStatement` / `goalBrandFacetWord` / `goalBrandFacetAudience` / `goalBrandFacetPromise` / `goalBrandFacetCost` / `goalBrandFacetEvidence` / `goalBrandFacetContrast` / `goalBrandFacetStrength` / `goalBrandFacetErrc` / `goalBrandFacetIdentity`

### 4.3 切面文案来源（zh 语义规范 —— 你据此写正式 zh + en 文案）

| 切面 | 要点（hint） | 范例（example） | 反例（counterexample） |
|---|---|---|---|
| statement 定位语句 | 一句话说清「我是谁 / 为谁 / 解决什么 / 凭什么 / 带来什么结果」；窄而深，胜过面面俱到 | 我帮小微餐饮老板用一套 7 天菜单改造流程，把外卖差评率压到 3% 以内 | 我是一个热爱学习、追求成长的优秀青年 |
| word 心智一词 | 一个别人提起你就会想到的词；它替你的**方法**命名，不是形容性格 | 「菜单医生」——一听就知道解决的是菜单问题 | 努力 / 靠谱 / 优秀 |
| audience 对象（他人视角） | 先写给谁看；**默认最重要的一面**，它决定别人怎么介绍你 | 刚开业半年、靠一份外卖撑生意的小微餐饮店主 | 所有人；或只写「同行」 |
| promise 承诺结果 | 承诺一个**可验证的结果**，不是一个动作；对方能拿它对账 | 90 天内把单店月毛利从 3 万提到 4.5 万 | 帮你做好菜单、持续赋能 |
| cost 规避的代价 | 写清你不愿承担什么代价；这是筛选同行的开关 | 不接没有真实门店、只想白嫖方案的单子 | 什么都接、什么钱都赚 |
| evidence 可信证据 | 列出可核验的事实：做过多少家、什么结果、谁在背书 | 已陪跑 23 家门店，其中 11 家差评率下降 50% 以上；3 位老板可写推荐语 | 我很有经验、业内口碑不错 |
| contrast 对立面 | 你的对照组是谁；写清「我不做什么」，别人才知道何时找你 | 不做纯设计外包，不接只改海报不出方案的活 | 空着；或只写「和别人不一样」 |
| strength 三环交叉 | 专业能力 × 独特优势 × 价值主张的**交集**；交集之外别人也能做到 | 餐饮后厨 8 年经验（专业）× 懂平台流量规则（优势）× 能让店真的赚钱（主张） | 我热爱美食、擅长沟通 |
| errc 剔除/减少/增加/创造 | 对现状做四种手术；这是你的**方法论本体** | 剔除无效套餐；减少出品工序；增加复购触达；创造「7 天改造陪跑」这一交付形态 | 全面升级、优化体验 |
| identity 身份声明 | 你要成为什么样的人；**内在内核**，决定十年后还在不在同一件事上 | 我是那个让小餐饮老板敢把菜单交给我的人 | 我是一个不断学习的人 |

> 素材来源文章《个人品牌建设全解》：内在内核（个性 + 品质）→ 能力价值（专业能力 / 独特优势 / 价值主张，差异化是前提）→ 外在感知（形象 / 数字形象 / 观点输出 / 表达方式 / 渠道 / 他人评价 / 圈层）；PBE = 吸引力 × 差异化 × 认知度；方法论三步 = 定位（窄而深）→ 呈现（一致性、3–5 个内容支柱）→ 传播（选平台、价值先行、持续积累、互动连接）；五原型 = 专家 / 导师 / 先锋 / 实干 / 联结（归入 identity，不单列）。

### 4.4 五处同步点（**一个都不能漏**）

1. `l10n_keys.dart`：常量声明
2. `l10n_keys.dart`：`byGetter` 映射条目
3. `l10n/parts/goals.dart`：abstract 声明 + **zh** 实现 + **en** 实现
4. `test/l10n_harness.dart`：访问器登记
5. `test/l10n_base_test.dart`：**5 处计数** 522→**576** / 579→**633**

**计数自洽判据**：`byGetter.length == accessors.length == 576`；`总数 == 576 + 4 + 53 == 633`。
**不得留半成品键**：只加常量不加 getter / 只加 zh 不加 en，一律视为缺陷。

---

## 5. 门禁（**必跑，缺一不可**）

### 5.1 跑之前（两个必做动作）

```powershell
# ① 挪走测试缓存（否则 OS Error 183 挂死）——改名不删
Move-Item 'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build' `
          'F:\soft\00selfmade\practilog\apps\desktop\build\test_cache\build_stale_<yyyyMMdd-HHmmss>'

# ② 镜像（必须在同一进程内设置）
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
```

### 5.2 命令

```powershell
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze                     # 期望逐字：No issues found!
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact     # 期望末行：+N: All tests passed!
```

### 5.3 硬判据（全绿才算完成）

| 项 | 期望 |
|---|---|
| `flutter analyze` | **逐字** `No issues found!` |
| desktop 全量测试 | 精确 = `920 + N1`，`N1 ≥ 6` |
| 本棒新测试 | `apps/desktop/test/task78_b9_brand_panel_test.dart`，≥ 6 例 |
| l10n 计数 | `byGetter = accessors = 576`；`总数 = 633` |
| 品牌行落库 | `kind='brand'`、`facet='audience'`（默认切面）、`rev` 递增、软删列为空 |
| 既有契约 | 蓝图页既有三块 ValueKey **零改动** |
| 代码卫生 | 零 `print(`；Dart 源 **LF、无 BOM**；无新增 `Icons.` |

> 门禁白名单已由控制器追加（`reports/task51-gate.ps1` 的 `$patterns` 含 B9 段），你**不得**改 `reports/task51-gate.ps1`。

---

## 6. TDD 与证据纪律（R5）

1. **先写测试** ⇒ 跑出**真红**（失败原因是**断言**，不是编译错误）⇒ 再改产品 ⇒ 跑绿。
2. 红/绿日志分别落盘：
   - `F:\soft\00selfmade\practilog\reports\task78-red.txt`
   - `F:\soft\00selfmade\practilog\reports\task78-green.txt`
   （`reports/**` 被 `.gitignore` 排除 ⇒ **任何情况下不得 `git add reports/`**）
3. **证据必须打到运行时产物上**：至少一个用例走「UI 触发保存 → 直接读 SQLite `goal` 行」读回断言 `kind='brand'` / `facet='audience'` / `rev` 递增 / 软删列为空。「源码看着对」不算证据。
4. 「搜 X 得 0 命中」**不能**当「X 已消失」的证明；本棒不涉及删除类断言，但断言写法不得依赖这种证据。
5. 判活/轮询日志文件时用共享读打开（`[IO.File]::Open($p,'Open','Read','ReadWrite')`），不要用独占读，否则会撞「being used by another process」。

---

## 7. 提交纪律

- 只提交本棒写集文件（**逐个路径 `git add <file>`，禁止 `git add .` / `git add -A`**）。
- 提交信息建议：`feat(goals): B9 W1 personal brand panel on blueprint page`
- **不 push**；不 `git stash`、不 `git add -p`、不 `git restore`、不 `git commit --only`。
- 删除类操作一律 `Move-Item` 改名留档，**不得**真删。
- 一切路径用绝对路径；不要 `Set-Location` 后写相对路径文件。

---

## 8. 交付报告（收工时按此格式回报，控制在 30 行内）

1. 改了哪些文件（逐个：新增/修改 + 行数变化）。
2. `flutter analyze` 的**逐字**输出行。
3. `flutter test` 末行（`+N: All tests passed!`）与 `N`；`N1 = N - 920`；本棒新测试例数。
4. l10n 回读三数：`byGetter = ?` / `accessors = ?` / `总数 = ?`（必须 = 576 / 576 / 633）。
5. 品牌行落库读回证据（`kind` / `facet` / `rev` / 软删列的实际读数）。
6. commit sha16 + 提交文件清单。
7. **未完成 / 未验证 / 已知偏差**（没有就写「无」；有就逐条写清楚，别粉饰）。
8. 留给 W2 的接口事实：品牌面板在蓝图页中的**插入位置代码锚点**（行号 + 前后 3 行上下文），W2 要在矩阵块上方/下方继续动同一文件。
