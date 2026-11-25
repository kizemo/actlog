# 接力协议 × PractiLog 既有纪律 —— 裁决文档

> 本文件只解决一件事：`docs/AGENT-RELAY.md`（通用接力协议）与本项目 `AGENTS.md`（278 KB 真源）
> 冲突时**谁赢**。答案永远是 `AGENTS.md`。
> 绑定时间：2026-11-24 21:20 左右，由 root 会话 `mvs_1711739d1ff3435a824c226a42c5db48` 写入。
> 起链授权：用户在本会话明确指令「绑真实项目起链」+ 选定本项目 + 选定「第 1 环强制只读盘点」。

---

## 1. 裁决顺序（硬）

1. **用户当轮明确指令** >
2. **`AGENTS.md` 全部既有硬规则**（R1 写集表 / R2 门禁判据 / 分发禁令 / 脚本编码判据）>
3. **`docs/relay.json` 状态机** >
4. **`docs/AGENT-RELAY.md` 通用条款** >
5. 会话内口头推断

冲突时：通用协议里任何一条若与 `AGENTS.md` 相抵，**视为不适用**，按 `AGENTS.md` 执行，并在本环交付文档里写明「哪一条被压制、为什么」。不得反向修改 `AGENTS.md` 来迁就接力协议。

## 2. 与本项目既有角色纪律的对接

`AGENTS.md` 规定：**控制器（root 会话）不得修改 `apps\**` 与 `packages\**` 下任何文件；实现只能经 worker 子会话完成**。

接力链上每一环都是用 `session_create` 新建的 root 会话 ⇒ 因此：

- 链上任一环节要改代码，**必须在本环内派 `worker` 子会话**去做，本环自己不动 `apps\` / `packages\`。
- 本环可直接写的只有 `AGENTS.md` 授权给控制器的台账位：计划文档、`docs\B1_验收记录.md`、`progress.md`、handoff 类文档，**且必须按写集表只写自己那一行**。
- 验收结论必须来自**独立 `verifier` 子会话或门禁脚本的原始输出**，不接受实现者自我声明，也不接受「大概过」。
- 派子会话 **不要传 `effort`**：本项目运行时实测 MiniMax M3 只支持 `on`/`off`，传 `high` 会直接失败。

## 3. 每环的写集（本项目收紧版）

通用协议 §2 只要求「追加台账 + 写交接文档」。本项目再收紧一档：

| 环节类型 | 允许写 | 禁止写 |
|---|---|---|
| 盘点环（当前 stage 1） | **仅** `docs\relay.json` 中 `stages` 追加自身条目；新建 `docs\relay-stage-<N>-inventory.md` | 其余全部，含任何既有台账与代码 |
| 实现环（stage ≥2） | `AGENTS.md` 写集表里本 Task 独占那一行；`docs\relay.json` 追加；新建本环交付文档 | 别人的写集行；`apps\**`/`packages\**` 直改（须走 worker） |
| 验收环 | 门禁读数文件（`reports\` 下新建，不覆写既有）；台账对应行 | 任何源码 |

**追加纪律沿用通用协议 §2 的 3.2**：回写 `docs\relay.json` 前必须重读、只做追加、不许改写别人的条目，写完回读核对 `stages` 条数与自身署名。

## 4. 人工验收点 = 一律 `blocked` 停链

链上任何一环，只要下一步动作落进下列清单，**不许自动执行**：把 `docs\relay.json` 写成 `status=blocked`、在 `stages` 里留下「卡在什么、需要人拍板什么、判据在哪」，然后停止建下一环会话。

- `git commit` / `git push` / 打 tag
- 打包、发布、分发（`AGENTS.md` 分发禁令优先：以最新真源行为准）
- 删除或覆盖既有数据、既有文档正文、数据库文件
- 修改用户级 `hooks.json`、运行时配置、额度相关配置
- 付费、需要账号或凭据的动作
- 与 `AGENTS.md` 真源行相矛盾的大规模代码改动（含重命名公开 API、迁移存储结构）

## 5. 并发冲突检测（每环开工前必做）

本项目此刻**存在另一个正在写仓库的会话**（Task 63 收口，root 会话 `mvs_e395774e42a84ff9a218fcb0b7349f98`）。因此每环第一步：

1. `git -C <repo> status --porcelain` 计数 + 记下时间戳；
2. 对本环要读/要写的每个文件取 `LastWriteTime` 与 sha16（`Get-FileHash -Algorithm SHA1` 前 16 位）；
3. 若目标文件 mtime 距开工 **< 30 秒**，视为「有别人在写」⇒ 本环**不得写该文件**；写集表冲突时按 §4 写 `blocked` 停链，不抢锁、不重试；
4. 收尾时再取一次 `git status` 计数。计数无规律跳变（既不是本环写集造成的增减）⇒ 交付文档里必须写明并降低结论置信度。
5. **状态文件的「开工副本必然过期」问题**（2026-11-24 21:40 实测踩坑）。环在开工时读到的 `docs/relay.json`
   只是一个时间点的快照；root 会话或并发的第三方会话**可能在环运行中途往同一个文件加字段**（本轮 root 就在
   stage 1 运行期间追加了 `concurrency` 与 `next_stage_target`）。因此：
   - 收尾回写前**必须重新读盘**，在最新字节上做定点替换/只追加，**严禁用开工时的内存副本整文件覆写** ——
     那会静默抹掉别人的协调信息，且 JSON 仍然合法，门禁查不出来；
   - 回写后除核对条数与署名外，还要确认「非本环负责」的顶层字段仍然存在（至少 `concurrency`、
     `next_stage_target`、`model_policy`、`human_checkpoints`、`stop_conditions`），缺失即判失败；
   - 同理适用于 `AGENTS.md`：本文件 484–494 行的接力章节是链的开关。链上任一环若发现该章节消失，
     **不得自行补写**（改 `AGENTS.md` 属台账写集 + 人工验收点），直接写 `status=blocked` + note 停链等人。

对齐 `AGENTS.md` 既有条款「门禁红灯且报错点不在本任务文件时，先查并发写入再怀疑自己的代码」。

## 6. 状态与判据口径

- `docs\relay.json` 的 `goal` 是**元目标**（把台账里最近一个未闭环批次推到门禁全绿），不是新发明的需求。具体做什么，只认项目自己的台账真源：`docs\B1_验收记录.md`、`docs\开发计划.md`、`AGENTS.md` 里最新的真源行。
- acceptance 判据**必须是可执行命令的原始输出**（门禁脚本、`dart analyze` 逐字 `No issues found!`、测试计数精确等值），不接受形容词。多包仓库的 analyze 判据要**逐包**跑。
- 取证到的「具体值」（口令、ID、哈希、路径）必须当场回读文件取该行并给校验位，禁止按形态推断。
- 路径指针落盘后必须逐字校验可解析（`Test-Path` 命中）；少后缀 / 少目录 = 真缺陷，直接修，不回头问人。

## 7. 链长与成本

`max_stages = 6`。本项目单轮实际成本明显高于探针工作区（一次唤醒可达上百次工具调用），所以：

- 每环工具调用控制在预算内，中间产物一律落文件，对话只留指针 + 结论；
- 第 6 环结束仍未闭环 ⇒ 写 `status=blocked`、`note` 说明剩余项，停链等人，不许自行加长 `max_stages`；
- 环内不得留未终态后台任务（等完 / `task_stop` / 写 `.bgtask_ack.json` 三选一）。

## 8. 链是怎么起的（防止自我起链）

- 起链动作由**人类明确指令**触发，已完成：root 会话 `mvs_1711739d1ff3435a824c226a42c5db48` 于 2026-11-24 21:2x 用 `session_create` 起 stage 1。
- 链上任何一环**不得**在目标未闭环时提前宣布 `done`；也不得在本环之外再起第二条链（`auto_relay` 只允许「自己 → 下一环」一条边）。
- 每一环的接力 prompt 正文只给**全路径指针**，不复述文档内容（用户交付偏好）。

## 9. 模型策略（用户 2026-11-24 21:17 补充要求）

### 9.1 选模顺序（每一环起下一环时，按**当时时刻**计算）

| 优先级 | 模型 key | effort | 生效时段（北京时间） |
|---|---|---|---|
| 1 | `minimax/MiniMax-M3` | **`"on"`**（M3 无 high 档，见 9.3） | 全天，只要 MiniMax 计划可用 |
| 2 | `custom_provider:provider-aa5659/auto` | **不传** | **08:00–19:00**，M3 不可用时 |
| 2' | `custom_provider:provider-aa5659/deepseek-v4.1-flash-1017` | **不传** | **19:01–次日 08:00**，M3 不可用时 |

`docs\relay.json` 的 `model_policy` 字段固化本表，起环前必读。

### 9.2 「额度用完」的可编程判据 —— 只能事后判，不能预检

MCode **没有**读取剩余额度的运行时接口（2026-11-24 查过 local-runtime 暴露的 24 个工具，无额度读取项），
所以「额度用完自动切换」只能按**失败信号**触发。以下任一命中即判定「M3 这一环不可用」：

1. `session_create(model=minimax/MiniMax-M3)` 直接返回错误；
2. 新会话首轮即失败，`mavis "session get"` / `session messages` 中出现额度 / 配额 / quota /
   insufficient / rate limit / 无可用模型 一类字样；
3. 新会话零工具调用即结束（被创建成模型不可用的空转态）。

命中后**按顺序**执行，且**同一跳最多降级一次**：

```
a) 【2026-11-24 21:5x 订正，见 9.5】本运行时 **没有 defer 姿势可用**：`session_create` 建环即开跑。
   唯一可行起环姿势 = 建环时显式传 `model` + `workspace_dir` → 立刻 `mavis "session get"` 回读
   `effective_model` / `workspace_dir` / `status.type`，三者对得上才算起环成功。
b) 会话已建但模型不可用 → mavis "session update" 改 model 为 9.1 第 2 / 2' 档，**自下一轮生效**；
   由于不存在 defer 窗口，首轮多半已随失败信号一起烧掉 ⇒ 该环按 c 重建，不要指望 update 能救回本轮。
c) session_create 直接失败 → 放弃 M3，用第 2 / 2' 档重建本环。
d) 任一降级都要：在 stages[current_stage] 回写**实际生效**的 model，并在 relay.json 追加一条降级事件
   （含触发信号原文，不得只写「已切换」）。

**代价（因无 defer 窗口而必然存在）**：降级只能事后判，所以每一次降级都要付出「一轮失败或空转」。
⇒ 判据 3（零工具调用空转）**不能只看 `status=started`**，必须 `session messages` 回读该轮是否真有工具调用。
```

仍失败 → 写 `status=blocked` 停链回报，**禁止**静默换模型硬撑、禁止改 `max_stages`。

### 9.3 effort 档位硬规则（本机实测，违反即 failed）

| 模型 | effort | 依据 |
|---|---|---|
| `minimax/MiniMax-M3` | 只接受 **`on` / `off`**；传 `high` → `failed: Invalid model thinking.effort` | 2026-11-21 后台任务 `bg_8a8b40e8` |
| 百炼 `auto` | 传 `high` 不报错、可正常完成 | 2026-11-24 `bg_a3852d31` `bg_8457886a` `bg_b53d61a9` `bg_27982133` 四次实测 |
| 百炼**显式**模型 | **传 effort 直接 failed** | 2026-11-24 08:03 cron 会话 `mvs_c51f3111f5a94e4b84f5b3fba207afd8`，同日子会话亦 `INCONCLUSIVE` |

⇒ 用户要的「推理程度高」在 M3 上**最大可行表达是 `effort:"on"`**；百炼侧**一律不传 effort**。

### 9.4 已实测 vs 待验证（不得混淆）

- **已实测（2026-11-24 本轮，`mavis "session list"` 回读原值）**：`minimax/MiniMax-M3`、
  `custom_provider:provider-aa5659/auto` 都是运行时正在使用的 key；
  `deepseek-v4.1-flash-1017` 是 `auto` 路由**实际落到过**的模型名（`bg_b53d61a9`、`bg_27982133` 完成时的 model 字段）。
- **推断、未实测**：加前缀的完整 key `custom_provider:provider-aa5659/deepseek-v4.1-flash-1017`
  未被直接观测过（前缀格式由 `.../auto` 推得）。**首次启用只能在起环时直接传该完整 key 并用
  `session get` 回读验证**（9.2(a) 已订正：本运行时无 defer 窗口）；
  若创建即报错，则 key 写法有误，就地订正本节并留证。
- **未验证**：会话**跑到一半**额度耗尽时运行时是否会自行换模型 —— 已知**不会**（会话 model 固定，
  只能 `session_update` 自下一轮生效）。⇒ 「额度用完切百炼」**只在接力跳上成立**；
  单环内部烧穿额度仍会失败，此时该环要按 9.2 的 b/c 由**下一环的发起方**补救。
- 跨 19:00 边界长时间运行的会话，模型**不会**随时间自动切换；策略只在起环那一刻生效。

### 9.5 `session_create` 的真实 schema（2026-11-24 `tool_search` 回读，权威）

`input_schema` 只接受这些字段（`required: ["content"]`）：`content` / `agent_name` / `title` /
`workspace_dir` / `location{mode|branch|base|worktree_dir}` / `model`。**没有 `effort`，没有
`defer_first_turn`，没有 `parent_session_id`。**

- **无 `effort`** ⇒ 用户要的「推理程度高」在**接力跳上不可表达**（`session update` 也只有
  title / archived / model）。这属**已知运行时限制**，不是待修缺陷，不得为此改用其他起链路径绕过。
  M3 档位由运行时决定；stage 1 在**未传 effort** 的情况下正常完成 78 次工具调用并交付盘点文档
  ⇒「不传 effort 可用」已实证，接力链照此运行。
- **无 `defer_first_turn`** ⇒ `content` 即首轮消息、随建随跑，**不存在「先建后发」的预检窗口**；
  9.2(a) 原稿所述 defer 姿势作废，起环后必须立刻 `session get` 回读三要素。
- **无 `parent_session_id`** ⇒ 起链溯源只能靠运行时自动记录的 `createdBySessionId`，
  加上 `relay.json.sessions[].trigger` 的人工登记，两者缺一不可。

本节由 stage 1 会话（`mvs_f0f4b5b2d4804d3fabd8f23d1e35544c`）21:46 起环时实测发现、
父会话（`mvs_1711739d1ff3435a824c226a42c5db48`）21:5x 用 `tool_search` 独立回读 schema 坐实后落地。
