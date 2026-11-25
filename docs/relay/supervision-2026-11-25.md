# 监督旁注 · 2026-11-25 00:00–00:20 · stage 5 收尾 → stage 6 末环起环

> 本文件是**监督会话旁注**，不是链上环的交付物。链上权威台账仍只认 `docs\relay.json` 与 `docs\relay\stage-N-report.md`。
> 监督会话 `mvs_ea04f090b03346079cda1d888f816a0e`（workspace `C:\Users\Duanyi`），不在 `stages[]` 内，不改 `relay.json` 的 `stages`/`sessions` 条目。

## 1. 本轮结论（先看这段）

| 项 | 值 |
|---|---|
| stage 5 | **done**（会话 `mvs_dd5bbcf80ab040c5a017d664411a84eb`），8 条人工验收点已由用户拍板（23:16），**代码改动 0** |
| 链状态（链上环自收尾时写） | `status=running` / `current_stage=6` / `stages` 5 条全 done / `blocked_on` 空（原文改名 `blocked_on_closed` 保留 8 条） |
| stage 6 | **本轮由监督会话补起**，会话 `mvs_34ce7f807b0a42e186ede8fa6db366e1`，标题 `relay-6-w9-close` |
| stage 6 三要素回读 | `workspaceDir=F:\soft\00selfmade\practilog`（`isDefaultWorkspace=false`）/ `effective_model=custom_provider:provider-aa5659/deepseek-v4.1-flash-1017` / `status.type=started` / `createdBySessionId=mvs_ea04f090…` |
| `HEAD` | `85b809a`（AHEAD=0，本链至今零 git 写操作） |
| 工作区 | `git status --porcelain -uall` = 21 行（含 9 个 stage 4 实现文件 + 2 个测试文件 + `AGENTS.md` + 9 个 relay docs） |

## 2. 本轮做过的三件事

1. **补起末环 stage 6**。链在 stage 5 收尾后处于「已放行但未起环」状态（`current_stage=6` / `next_session_id=null`），符合 `docs\AGENT-RELAY.md:68`（3.3 开下一环）尚未执行。stage 6 范围权威来源 = `relay.json` 的 `stages[4].next_stage`，三项：68.4b/68.4i 复扫（口径按 U5 裁定，维持 35 条，`packages\core_data\lib\src\repositories.dart:47-50` 不计入）、68.4g verifier 终判（要证据不采信转述）、68.4h git commit/push（人工验收点，链不得自做）。
2. **撤掉重复排程**。cron `08886498-b02b-4cc9-ba8b-980688a463af`（`Practilog_定时`，一次性 `runAtMs=1795536912600` ≈ 00:15:12）会在 15 分钟后**再起一个 stage 6 环**，与本轮已起的环构成双写者 → 已 `cron_delete`（返回 `success:true`）。
3. **剔除被污染的接力 prompt**。上述 cron 的 prompt 正文（stage 6 口径部分）本身完整可用，但**尾部混入了两句与本链无关的产品需求**（「推进人生蓝图/年度/月度/周目标页面设计」「限制只打开一个软件实例」）。原样转发会把无关需求塞进 stage 6 环，违反「只做 `current_stage` 一个阶段」的写集纪律 ⇒ 起环时**只保留 stage 6 口径正文**，删去那两句，并在 prompt 首句补一句「本轮任务范围仅限本文件所列 stage 6 内容，不含任何其它产品需求」。

## 3. 模型档位（为什么不是 M3）

- 22:45 stage 5 建环时 M3 报 `status.type=error` / `errorCode=42212`「已达到 Token Plan 用量上限…(2056)」，同轮 worker 以同一 2056 失败 ⇒ M3 额度不可用，非瞬时波动。
- 当前处于夜间窗口 19:01–08:00 ⇒ 按 `relay.json` 的 `model_policy` 取 `fallback_night` = `custom_provider:provider-aa5659/deepseek-v4.1-flash-1017`（该 key 已在 stage 5 实测可用，`model_policy.unverified` 已关闭）。
- 起环即开跑（`turn.mode=activated`），无 defer 窗口 ⇒ 事后回读三要素是唯一校验手段，本轮已做。

## 4. 判活口径（不变）

- 看 `mavis session messages` 末条 timestamp；**不用** `session get.updatedAt`（不推进，会把活会话误判僵死）。
- 链上每环完成回执只回到创建者，不会唤醒监督会话 ⇒ 监督靠 cron 窗口 + `self_reminder` 定期复查。本轮已 `self_reminder cancel`（避免与 cron 重复唤醒），改由 cron 承担监护。

## 5. 待用户拍板（stage 6 会命中）

1. **68.4h `git commit` / `push`** —— 属人工验收点，本链至今零 git 写操作。stage 6 环会在此停 `blocked` 并给出待提交文件清单与建议 commit message ⇒ 需用户明确授权后才能提交/推送。
2. **门禁白名单** —— Q8 已授权落地（`docs/relay/*` + `docs/relay.json` + `docs/AGENT-RELAY.md` + `docs/RELAY-ADAPTATION.md` 四条纯 ASCII 模式已成组登记，`OUT_OF_SET=0`）；门禁脚本本身**不得再改**。
3. **门禁复跑口径** —— 必须带 `-ExpectDesktopTests 836`（`AGENTS.md:57` 把 `$baseline=596` 定性为历史常量，不得改脚本 `:38`）。

## 6. 三档状态

**已验证**
- `relay.json` 磁盘真值：`status=running` / `current_stage=6` / `next_session_id=null` / `stages` 5 条全 `done` / `sessions` 6 条 / 顶层 21 key 完整。
- stage 6 会话三要素回读（见 §1 表）。
- 重复排程已删（`cron delete → success:true`）；`self_reminder` 已取消。
- stage 5 的 8 条裁定与门禁 PASS 证据在 `docs\relay\stage-5-report.md` 第十二章 + `relay.json` 的 `stages[4].human_checkpoint_resolution`（本轮只读转述，未复验门禁本体）。

**推断**
- stage 6 环能在本轮内跑完复扫与 verifier，终点大概率停在 68.4h 授权点（依据：`stages[4].next_stage.must_not` 明确「收口后写 done，或停在 git commit/push 这一人工验收点上写 blocked」）。

**未验证**
- stage 6 的复扫结果（缺口面是否仍为 35 条）、verifier 终判结论、`docs\relay\stage-6-report.md` 的落盘内容、`relay.json` 的 `stages[5]` 条目与 `sessions[7]` 条目 —— 均为**下一环产出**，本轮不预判。
- 沙箱门禁在本轮的 fresh 结果（stage 5 的 PASS 证据 `RUN_AT=2026-11-24 23:11:01` / `summary.txt` 1,890 B / sha16 `9A676DAC79CA6592` 属上一环结果，不当作本轮结论）。
