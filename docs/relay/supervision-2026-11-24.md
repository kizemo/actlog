# 接力链监督记录 · 2026-11-24（监督会话，非链上环）

> 本文件由**用户开的监督会话** `mvs_ea04f090b03346079cda1d888f816a0e` 写入（workspace `C:\Users\Duanyi`，非链上环、不是 `stages[]` 里的一环）。
> 用途：记录链的推进状态、判活口径、以及**监督者不得越界**的边界，避免下一位监督会话从零重做。
> 链的唯一进度真相仍是 `F:\soft\00selfmade\practilog\docs\relay.json`；本文件只做指针与旁注。

---

## 1. 监督会话的职责边界（硬）

| 监督会话**可以** | 监督会话**不可以** |
|---|---|
| 读 `docs\relay.json` / `docs\relay\stage-*.md` / `AGENTS.md` 接力章节 | 改 `docs\relay.json` 的 `stages` 条目（那是链上环的写集） |
| 用 `mavis session list` + `session messages` 末条 timestamp 判活 | 用 `session get.updatedAt` 判活（不可信，见 §3） |
| 链断时按 `docs\AGENT-RELAY.md` §4 补起下一环 | 与正在实跑的环**并行**做同一阶段（两个写者 = 写集冲突） |
| 写本文件（`docs\relay\supervision-*.md`）这类旁注 | 碰 `reports\task51-gate.ps1` 白名单（人工验收点） |
| 挂 `self_reminder` 定期复查 | 读 `maintenance\task-state\LATEST.md`（跨项目共享卡，会被别的会话覆写） |

## 2. 22:20 时点的链状态（已验证）

| 项 | 值 | 取证方式 |
|---|---|---|
| `status` / `current_stage` / `max_stages` | `running` / `4` / `6` | `Get-Content docs\relay.json \| ConvertFrom-Json` |
| stage 4 会话 | `mvs_6e8375ea012f4f64a23fdcd02dde6139`（`stages[3].session_id` 已回填，状态 `in_progress`） | `relay.json` + `mavis session list` |
| stage 4 起链时刻 / 模型 | `2026-11-24T22:17:23+08:00` / `minimax/MiniMax-M3`（未降级） | `relay.json` + `session get` |
| stage 4 工作区 | `F:\soft\00selfmade\practilog`（`isDefaultWorkspace=false` ⇒ 生效） | `session get` |
| stage 4 判活 | 最后一次工具调用 `2026-11-24 22:19:36`（并发检测 bash），本轮**在跑** | `session messages` 末条 timestamp |
| 仓库 HEAD / 脏文件 | `85b809a` / 5 行（`M AGENTS.md` + `?? docs/AGENT-RELAY.md` + `?? docs/RELAY-ADAPTATION.md` + `?? docs/relay.json` + `?? docs/relay/`） | `git -C … status --porcelain` |
| l10n 写集是否被并发会话占住 | **否** —— `l10n_keys.dart`(21:18:21) / `parts\dialog.dart`(17:42:26) / `parts\projects.dart`(21:11:45) / `test\l10n_base_test.dart`(21:17:39) 全部早于 stage 4 开工，**不 dirty** | stage 4 自己的并发检测输出（22:19:36） |
| `AGENTS.md` 接力章节 | 仍在（`:487`，文件 496 行；并发会话 Task 68 收口后由 494 → 496 行） | `Select-String '自动接力（Relay）'` |

**判读**：并发 Task 68 控制器会话 `mvs_e395774e42a84ff9a218fcb0b7349f98` 已 `idle` 且 HEAD 已前进到 `85b809a` ⇒ 旧写集已让出，stage 4 无双写者风险。

## 3. 判活口径（踩坑固化）

- `mavis session get` 的 `updatedAt` **不可作判活依据**（会停在起环后数秒不动，把活会话误判成僵死、把空转会话误判成健康）。
- 正确口径：`mavis session messages` 取**末条消息 timestamp**；连续递增 = 在跑。
- 链上每一环的完成回执**只回到它的创建者（上一环）**，**不会唤醒更上层的监督会话** ⇒ 监督会话必须自己挂 `self_reminder` 定期复查。

## 4. `session_create` 起环姿势（本轮实测）

- `workspace_dir` 必须写**反斜杠绝对路径**：`F:\soft\00selfmade\practilog`。
  stage 3 传 `F:/soft/00selfmade/practilog`（正斜杠）→ 运行时未采纳，落到 `…\.minimax\sessions\<sid>\workspace`，那一环整轮读不到仓库；stage 4 传反斜杠 → 生效。
- `input_schema` 只有 `content` / `agent_name` / `title` / `workspace_dir` / `location` / `model`：**无 `effort`、无 `defer_first_turn`、无 `parent_session_id`**（与 `docs\RELAY-ADAPTATION.md` §9.5 一致）。建环即开跑，无预检窗口 ⇒ 起环后**立刻** `session get` 回读 `workspaceDir` / `isDefaultWorkspace` / `effective_model` 三要素。

## 5. 监督者要盯的三个风险（未验证 = 待观察）

1. **stage 4 写集里 `apps\desktop\lib\src\widgets\plan_item_detail_dialog.dart` 在该路径下不存在**（stage 4 自己的指纹扫描报 `MISSING`；stage 3 报告引用的 `plan_item_detail_dialog.dart:312-328` 在别的目录）。若 stage 4 在错路径新建文件 ⇒ 门禁 `OUT_OF_SET` 会 +1（白名单改动 = 人工验收点，链不得自改）。
2. **stage 4 收尾必须重读盘再回写 `relay.json`**（`RELAY-ADAPTATION.md` §5.5），并回读核对顶层 21 个 key 零丢失、`stages` 条数、`sessions[]` 署名。
3. **stage 5 / stage 6 必然撞人工验收点**：Q1–Q2 格言产品决策、Q3 全角 `＋`、Q4 简体中文自称、Q5 扫描面外 `core_domain`、Q6 StateError 备选方案、Q7 `parts\dialog.dart:254-259` 注释冲突（这条与 stage 4 落码直接相关，须在 stage 4 报告写明改法）、以及 68.4h 的 commit + push。⇒ 链的终点大概率是 `status=blocked` 等人裁决，**不是** `done`。

## 6. 链内已有交付（指针，供快速定位）

- `F:\soft\00selfmade\practilog\docs\relay\stage-1-inventory.md` —— 只读盘点：最近未闭环批次判定 + 门禁缺口
- `F:\soft\00selfmade\practilog\docs\relay\stage-2-scope.md` —— 下一批次范围定稿 + 521 条切分（口径被 stage 3 订正）
- `F:\soft\00selfmade\practilog\docs\relay\stage-3-report.md` —— U1–U4 复验 + 27 条新键设计稿（stage 4 的唯一施工依据）
- `F:\soft\00selfmade\practilog\docs\relay\stage-4-implementation.md` —— stage 4 交付（**尚未生成**）

## 7. 已验证 / 推断 / 未验证

**已验证**（本会话亲跑、原始输出在手）：§2 表格全部字段；§3 的 `updatedAt` 不可信；§4 的正斜杠 workspace_dir 不生效。

**推断**（有证据但未实证到终局）：stage 4 会完成 27 键落地并自行起 stage 5；stage 6 收口时 `OUT_OF_SET` 仍为 4~5（接力链 4 个 docs 路径 + 可能的错位新建）。

**未验证**：stage 4 的落码结果与门禁读数（**stage 4 未结束，本会话未亲跑门禁 / analyze / test**）；stage 5 / stage 6 是否如预期撞人工验收点；450 条格言与 B 类 4 键的产品口径结论。
