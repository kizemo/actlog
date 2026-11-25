# 无人值守接力协议 · AGENT-RELAY.md

> **用法**：把本文件放进目标仓库 `docs/agent-relay.md`，再把 §7 那 6 行贴进仓库 `AGENTS.md`。
> 此后项目里的 Agent 自己完成「阶段收尾 → 落盘交接 → 开新会话 → 投递接力 Prompt」，
> 你只需要说一次「按 <计划文档> 起接力链」，之后不需要人在场。
>
> 本协议自包含：所有路径都是**仓库相对路径**，不含任何机器绝对路径，可直接搬进任意项目。

---

## 1. 文件契约（链的三条腿）

| 文件 | 角色 | 谁写 |
|---|---|---|
| `docs/relay.json` | **唯一进度真相**（状态机） | 每一环收尾时回写 |
| `docs/plan-*.md` | 目标 + 阶段拆分 + 人工验收点声明 | 起链前由人或首环写 |
| `docs/handoff-*.md` | 每阶段结论与证据，逐字编号续编 | 每一环写自己的那一节 |

铁律：**`relay.json` 不存在或 `status != "running"` ⇒ 不得开新会话。**
链上任何一环都不许把进度写进对话冒充落盘；不许依赖 `~/.minimax/.../task-state/LATEST.md`
（那是 agent 级共享交接卡，任何其它会话的 Stop Hook 都会覆写它，内容可能完全不属于本链）。

### relay.json 骨架

```json
{
  "schema": "mcode-relay/1",
  "updated_at": "<ISO8601>",
  "status": "running",
  "goal": "<一句话目标>",
  "plan_doc": "docs/plan-xxx.md",
  "workspace_dir": "<仓库绝对路径，起链时填一次>",
  "auto_relay": true,
  "max_stages": 12,
  "current_stage": 1,
  "chain_started_at": "<ISO8601>",
  "stop_conditions": [
    "status 变为 blocked 或 done",
    "命中 plan_doc 声明的人工验收点（提交/发布/删数据/付费/不可逆）",
    "同一阶段连续两轮无实质进展",
    "current_stage >= max_stages",
    "存在未终态的后台任务"
  ],
  "stages": [
    { "id": 1, "title": "", "deliverable": "", "acceptance": "", "status": "pending", "session_id": null }
  ],
  "sessions": []
}
```

---

## 2. 每一环的四步义务（顺序不得颠倒）

任一环（含首环）在本轮内必须走完：

1. **读** `docs/relay.json` + `plan_doc`。校验：`status=="running"`、`current_stage <= max_stages`、
   自己负责的阶段号 == `current_stage`。任一不符 → 跳到第 4 步停链分支，**不得**新建会话。
2. **只做** `current_stage` 这一个阶段，做到其 `acceptance` 判据成立**并亲自跑出证据**为止。
   工具调用超过 40 次仍未收敛 → 停下，如实写「未完成」，走第 4 步。
3. **收尾三件事**：
   - 3.1 结论落盘 `docs/handoff-*.md`：含相对仓库根的指针、**已验证 / 推断 / 未验证** 三档、证据路径；
   - 3.2 回写 `docs/relay.json`：**只许追加，不许改写别人的条目** —— 把本阶段条目的 `status` 写成 `done`、
     补 `session_id`、`sessions[]` 追加**自身**会话 ID、`current_stage += 1`、`updated_at` 刷新。
     回写前必须**重读一次**该文件再合并（链上各环并发写同一文件：2026-11-24 实测第 3 环读到的内容比第 2 环
     最终落地的还旧，属跨会话写入竞态，这次没丢数据是运气）。判据：写完必须回读并核对
     `stages` 条数 == 已完成阶段数 且 自己的署名在列。
   - 3.3 调用 `session_create` 开下一环（配方见 §3）。
4. **停链分支**：需要人工验收 / 缺权限 / 连续两轮无进展 / 已达 `max_stages` / 全部完成
   → 把 `status` 写成 `blocked`（并写明缺什么）或 `done`，在回答里说明，**不得**新建会话，等人介入。

**链条能自转的唯一支点 = 每一环都执行了 3.3。任何一环漏写，链当场断。**

---

## 3. `session_create` 调用配方

调用形状（MCode 桌面端 / 本机运行时实测）：

```text
mcp_invoke(
  tool_name = "session_create",
  arguments = {
    "agent_name": "me",
    "title": "relay-<N+1>-<阶段短名>",
    "workspace_dir": "<relay.json.workspace_dir，必须显式传>",
    "content": "<§4 的接力 prompt 正文，把 <N> 换成 <N+1>>"
  }
)
```

- 返回 `ok:true` 且 `turn.mode:"activated"` ⇒ 新会话**已自动开跑**，不需要人在场点发送。
- 若新会话的 `location.workspace_dir` 落到了 `...sessions\<sid>\workspace` 之类的私有临时目录，
  说明 `workspace_dir` 没生效 ⇒ **这一环等于没接上**，必须重投或写 `blocked`。
- 注意 `mavis` 的 `session create` 子命令不存在（报 `SESSION_CREATE_MOVED`），必须走 tool_search + mcp_invoke。

---

## 4. 接力 prompt 正文（第 N 环，N ≥ 1 通用）

```text
你在无人值守接力链的第 <N> 环，只做这一个阶段，不要向人提问。

0. 工作区就是本仓库根。先读 docs/relay.json 与 docs/agent-relay.md（本协议），再读 relay.json.plan_doc。
1. 校验 relay.json：status 必须为 running、current_stage 必须等于 <N>、<N> 不得大于 max_stages。
   任一不符 → 按 §2 第 4 步停链，不得新建会话。
2. 只做 current_stage 阶段，做到 acceptance 判据成立并跑出证据；工具调用 >40 次未收敛就停下写「未完成」。
3. 收尾三件事（顺序不得颠倒）：
   3.1 结论落盘 docs/handoff-*.md（续编现有编号，不新建跨项目指针）；
   3.2 回写 docs/relay.json（done / current_stage+1 / sessions[] 追加自身 ID / updated_at）；
   3.3 调 session_create 开下一环：workspace_dir 沿用 relay.json.workspace_dir，
       title="relay-<N+1>-<阶段短名>"，content 用本段正文、<N> 换成 <N+1>，
       并要求下一环完成后把 relay.json 的 sessions[] 追加其自身会话 ID。
4. 命中停链条件（提交/发布/删数据/付费/不可逆、缺权限、无进展、达 max_stages）：
   写 blocked 或 done 并汇报，不得新建会话。
5. 回执条款：你的结果会被运行时自动回传给创建你的会话并唤醒它。若你本轮开头收到的
   是**下游会话的回执消息**（形如 STAGE-<N+1> RECEIVED），而不是新指令：
   只输出一行 `STAGE-<N> RECEIVED|<下游 session id>` 后立即结束本轮，
   不得调用任何工具、不得重做阶段工作、不得再建会话。
6. 纪律：中间产物写文件、对话只留指针与结论；不得伪造验收证据；
   具体值（口令/令牌/ID/哈希）必须当场回读文件并给出长度 + sha16 前 16 位 + 尾部 4 字符。
```

---

## 5. 成本口径（必须按双份算）

实测：子会话完成后会**自动**把结果 `session send` 回创建者会话，这条回传会让上一环再跑一轮 agent 循环
（这是运行时契约，prompt 禁不掉）。所以

> **每推进一环 ≈ 新会话 1 轮 + 父会话被唤醒 1 轮。**

`max_stages` 和额度预算按 `2 × 阶段数` 估。§4 第 5 步的回执条款就是为了让「被唤醒的那一轮」退化成一行的空转，
避免旧会话把回执当新任务重跑。

---

## 6. 安全边界（不可协商）

- 需要人工验收的动作（提交、推送、发布、部署、删数据、付费、改用户线上配置）**一律停下写 `blocked`**，
  绝不自接力。
- 禁止跨项目目录读别人的交接卡；禁止把密钥/令牌写进任何落盘文件。
- 本轮结束前不得留未终态后台任务，否则会出现无人认领的唤醒。
- 链上任何一环若发现 `relay.json` 与仓库实际状态矛盾，以**仓库实际内容**为准，写 `blocked` 等人。

---

## 7. 贴进 `AGENTS.md` 的那 6 行

```markdown
## 无人值守接力链

- 本项目遵循 `docs/agent-relay.md`。任何会话开始工作前，先看 `docs/relay.json`。
- 若 `docs/relay.json` 存在且 `status == "running"`：本轮必须按 `docs/agent-relay.md` §2 推进
  `current_stage`，并在收尾时按 §3 自行 `session_create` 接力下一环（**必须显式传 workspace_dir**）。
- 若不存在或 `status != "running"`：正常干活，不要擅自起链。
- 起链只能由人的明确指令触发（如「按 docs/plan-xxx.md 起接力链」），不得自我起链。
```

> **为什么要同时写进 AGENTS.md**：`AGENTS.md` 是否被自动注入到新建会话，取决于运行时与项目识别方式，
> 不保证。所以 §4 的接力 prompt 里**显式要求读 `docs/agent-relay.md`**——这样无论注入与否，
> 只要工作区指向仓库，协议就一定拿得到。AGENTS.md 那段的作用是让**人在新会话里随口说一句**
> 也能接上链，以及防止有人误起链。
