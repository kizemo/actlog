# B15 接力计划（PractiLog · B14 收口后的剩余项闭环）

## 0. 背景与起点

- B14 批次已收口并提交：代码 `5506c60`，台账 `fd6d6d8`（只 commit 不 push）。
- 本链目标：把 `docs\handoff-ledger-b9-w4.md` §11.21 列出的遗留项逐条处置，直到权威门禁全绿并再次收口。
- 本链沿用「控制器 + worker 子会话」结构：控制器零改 `apps/**` 与 `packages/**`，实现全部由 worker 落盘。

## 1. 唯一真源与优先级

1. 用户当轮决定
2. 本文件（派工口径）
3. `docs\handoff-ledger-b9-w4.md` §11.21（B14 收口节原文，含遗留清单原文）
4. `AGENTS.md` §2 铁律 R1–R8、§7.1 设计标准、§8 B14 三条新增口径
5. `docs\RELAY-ADAPTATION.md`（接力裁决）

## 2. 工作队列（stage 1 必须从台账原文摘出，禁止臆造）

- 来源：台账 §11.21 的「已知未覆盖 / 遗留」六条 + 同节其它未闭合项。
- 每条分类：A 可自动闭合（须带判别性测试）｜B 需人拍板（写 blocked 登记，不得擅改口径）｜C 需真机或肉眼（只登记与取证方案，不得假装闭合）。
- stage 1 产出 `docs\relay\stage-1-inventory.md`：逐条给出原文摘录、分类、处置计划、判据。

## 3. 从 B14 实测继承的硬约束（勿重试死路）

- 合成导航取帧（`WM_MOUSEMOVE` / `WM_MOUSEWHEEL` / `SendInput` / UIA）已判死路；界面证据改走带 `ValueKey` 的 widget 测试与布局打印。
- 英文态 760 窗页签余量仅 0.21px（红线 11px）：任何加内边距 / 分隔符 / 文案的改动必须重跑 `apps\desktop\test\b14_tab_scale_test.dart`。
- `flutter test` 必须在 `apps\desktop` 目录内跑（仓库根无 `test/` 目录）。
- 跑全量前先 `Move-Item apps\desktop\build\test_cache\build <改名>`（不删）。
- 权威门禁：`reports\task51-gate.ps1 -ExpectDesktopTests <当轮实测数>`；判绿只看 `reports\task51-gate\summary.txt` 的 `GATE_VERDICT`。
- `reports\**\*.ps1` 纯 ASCII / CRLF / 无 BOM；中文正文只进 `.md` / `.txt` / `.json`。
- 不删文件，一律 `Move-Item` 归档；台账具体值必须盘上回读后再写。

## 4. 接力操作经验（上一链实测的 schema 事实）

- `session_create` 的 schema 只有 `content` / `agent_name` / `title` / `workspace_dir` / `model` / `location`；没有 `effort` / `defer_first_turn` / `parent_session_id`，不要传。
- `workspace_dir` 必须传反斜杠绝对路径，正斜杠会被静默丢弃到私有目录。
- 模型降级：`session_update(model=...)` 后 `session send` 即开新轮，session id 不变，代价一轮失败；不要重建会话。
- 判活看 session messages 末条 timestamp，不看 session get.updatedAt。
- `AGENTS.md` R8 要求显式给 effort，但 schema 无该字段，传了会报错；按 schema 不传并在台账登记该冲突。

## 5. 阶段划分（6 段）

1. 范围盘点（见 §2）
2. 闭合 A 类中最高价值的一条
3. 闭合 A 类其余条目
4. 英文态 760 宽余量加固（若 A 类含此项：余量抬到 ≥1px，红线 11px 不放宽）
5. 权威门禁复跑（`-ExpectDesktopTests` 用当轮实测数，不许估）+ 台账追加
6. `AGENTS.md` 回写 + 收口报告 + 停链（commit 属人工验收点，链上不得自行 commit）

## 6. 停链条件

- 命中人工验收点（git commit / 分发 / 删改用户数据 / 额度与权限 / 口径矛盾）即 `status=blocked` 并登记。
- `current_stage >= max_stages` 即 `status=blocked`。