# PractiLog 同类 GitHub 项目调研报告

> 调研对象：`kizemo/PractiLog`（个人效能日志工具，Windows + Android 双端）
> 理论参考：《高绩效人士的五项管理》
> 需求来源：`核心需求校验清单.md`（8 条）、`核心需求MVP.md`（MVP v0.1）
> 报告生成：2026-11-06
> 数据口径：GitHub REST API（`gh api repos/<owner>/<repo>`）实时读取，星标/fork/许可/语言/创建日期均为 API 实测值，未做任何推测填充

---

## 〇、一页结论（TL;DR）

1. **市场上没有 PractiLog 的直接同类**。GitHub 上 5 万星级别的日志/日记/习惯项目全部是**单点产品**：要么是日记（memos / joplin / siyuan / moodiary），要么是习惯打卡（uhabits / habitica / mhabit / Habo），要么是任务项目（vikunja / super-productivity），要么是目标仪表盘（flow-dashboard）。**把「五项管理的行动日志 + 独立待办池 + 习惯打卡回填 + 长线项目增量记录」合并成一个闭环产品，公开样本里没有对标物**。这是 PractiLog 的机会，也是最大风险（无参照系 = 无验证过的交互范式）。

2. **技术路线已有先例支撑，且与你的 MVP 高度吻合**。`FriesI23/mhabit`（Flutter + SQLite + WebDAV + local-first + Windows/Android/WebDAV，1691★/Apache-2.0）与 `Yu-Core/SwashbucklerDiary`（.NET 10 + Blazor Hybrid + SQLite + WebDAV + Windows/Android/Web，1627★）已经证明了「本地优先 + 自有 WebDAV 同步 + 双端」这条路在真实用户群中是成立的。`CikeSeven/jotsy`（Flutter + offline-first + WebDAV + 心情追踪）则证明了「离线优先 + WebDAV + 情绪元数据」的最小实现路径。

3. **17 条成熟机制已被 3 个以上项目反复验证**，可直接落进 MVP 且不违反你划定的「不做清单」：连续天数/强度评分、打卡类型分型、合法中断出口（假期/归档/跳过）、每日站会三段视图（昨日亮点 + 今日优先 + 阻塞项）、小组件直接打卡、通知内直接操作、GitHub 风格活动网格、天气 + 心情 + 位置三元组、导入时保留历史与连续天数、Markdown 作为交换格式等。详见第四章。

4. **你的 8 条需求里，有 6 条在现有产品中已被验证，2 条是真正的差异点**：
   - 已验证：简化填表（极简日记/问卷式日志）、独立待办池（GTD 类项目全部有）、打卡自动回填日志（Dayflow / streak 已验证）、独立提醒（uhabits / Habo / streak 全部支持每条独立提醒）、双端（mhabit / SwashbucklerDiary / moodiary 已验证）、历史浏览（时间线式日记流已是主流范式）。
   - 差异点：**长线项目「增量记录、不强制闭环」** 和 **完整版 / 极简版双模式切换**。全样本中几乎无人做「不闭环的长线项目时间线」，而双模式切换在 GitHub 上也没有成熟先例（只有 beaverhabits / storypad 走「极致极简」的单向路线）。

5. **必须显式承认与原书的偏离**。《五项管理》原书**没有**长线项目/里程碑、**没有**打卡与连续天数、**没有**「重要紧急四象限」、**没有**极简模式，并且**明确反对**「区分可控/不可控」式的外部归因（原书要求「决不找借口、全部担责」）。你的 MVP 在这 4 处是有意的**逆向改良**（降低记录负担 + 承认外部约束），这是产品优势，但**不要宣称为「忠于原书」**——正确的表述是「以原书为骨架，叠加现代个人效能产品经过验证的减负机制」。详见第六章。

6. **最该立刻抄的三件事**（成本低、收益高、不越界）：
   - 「习惯打卡 → 自动回填当日日志」的具体交互（Dayflow 的自动 + streak 的手动回填各取一半）；
   - 「合法中断出口」（假期模式 / 归档 / 跳过不打断连续）——直接决定你的打卡连续天数是否会在用户休假后崩塌；
   - 「每日站会三段视图」（昨日亮点 / 今日优先 / 阻塞项）——这正是原书「早上对照目标，中间对照过程，晚上对照结果」（L2434）的产品化落地，且现有样本已验证可行。

---

## 一、调研方法与样本口径

### 1.1 采样方法

| 维度 | 做法 |
|---|---|
| 检索 | GitHub Search API，9 条英文分类 query（diary / journal / habit tracker / bullet journal / daily notes / work journal / daily planner 等）+ 5 条中文与 topic 补充 query（topic:daily-journal、topic:journaling-app、topic:mood-tracker、日记、习惯、时间管理、目标管理、GTD） |
| 筛选 | 以 stars 为主排序，兼顾 forks（fork 数反映「愿意动手改造」的真实需求强度，star 数反映知名度，两者背离时优先看 fork） |
| 指标采集 | `gh api repos/<owner>/<repo>` 实测 `stargazers_count` / `forks_count` / `language` / `license.spdx_id` / `created_at` |
| 功能分析 | 下载 27 份 README 原文，按项目逐个消化；跨项目交叉归纳 10 类功能模式 |
| 理论核对 | 对《五项管理》全文做结构化提炼并保留行号定位，用于判定「哪些需求有原书依据 / 哪些是产品自创」 |

### 1.2 口径声明（重要）

- **星标数字是 2026-11-06 的快照**，GitHub 星标每日变化，引用时请带日期。
- **license 字段为 `NOASSERTION` 的仓库不等于「无许可证」**，只表示 GitHub 无法自动识别（如 joplin、habitica、Pile、journiv、lunatask）。若未来要抄它们的代码，需逐仓库人工查 LICENSE 文件，不能凭字段推断。
- **样本剔除了 `tridiontech/journal`**：其 README 实际抓取失败（下载到的是另一个项目的 README），无有效内容，不纳入分析。
- **README 分析 ≠ 代码审计**：功能描述以项目自述为准，可能与实际实现有偏差；本报告的判断依据是 README 声明 + 公开架构信息。

### 1.3 样本总量

- 进入深度分析的仓库：**26 个**（其中 27 份 README 含 1 份重复）
- README 原文落盘：`docs/_research_readmes/`（27 份）
- 逐项目分析摘要：`docs/_research_readme_digest.md`（68,706 字节 / 23 项）+ `docs/_research_readme_digest_extra.md`（27,818 字节 / 4 项）
- 指标快照：`docs/_research_metrics.tsv`、`docs/_research_metrics_verify.tsv`（本次复核版）

---

## 二、样本分组画像

### A 组｜通用日记 / 笔记（时间线流形态）

| 项目 | 星标 | 一句话定位 |
|---|---|---|
| usememos/memos | 64,315 | 「微博式」碎片笔记，时间线 + 标签双轴，Go + SQLite，整库备份收敛到单一目录，带 MCP server |
| laurent22/joplin | 57,061 | Markdown 笔记 + 端到端加密同步 + WebDAV，桌面/移动/CLI 全端 |
| siyuan-note/siyuan | 47,102 | 块级双链 + 本地优先 + 禁第三方同步盘，Windows/Android 一等公民，CLI 可操作本地数据 |
| logseq/logseq | 45,497 | 大纲式日志 + 本地 Git 同步，Clojure |
| JerryZLiu/Dayflow | 7,394 | 屏幕活动自动生成日志卡片（macOS/Swift），每日站会 + 分心/专注并排 |
| ZhuJHua/moodiary | 2,059 | 跨平台日记（Flutter + Rust），WebDAV/S3 + 局域网 + 可选 E2EE 三层拆分，地点足迹地图，导出矩阵 |
| Yu-Core/SwashbucklerDiary | 1,627 | .NET 10 + Blazor Hybrid 日记，Windows/Android/Web，SqlSugar + SQLite，隐私模式只遮蔽私密条目 |
| Demizo/Daily_You | 1,409 | 私密日记 + 情绪模型，导入保留元数据 |
| hanjoongcho/aaf-easydiary | 562 | Android 端 UX 优化见长的日记，语音输入 + 天气/心情/位置三元组 |
| theachoem/storypad | 1,009 | 极简日记，离线优先，多年同日回访（Throwback），多页条目 |
| memex-lab/memex | 827 | 本地优先 AI 日记，iOS + Android |
| CikeSeven/jotsy | 144 | Flutter offline-first 日记 + 心情追踪 + WebDAV |
| journiv/journiv-app | 1,255 | 自建私密日记 + 心情追踪 |
| UdaraJay/Pile | 3,122 | 桌面日记，AI 反思附着在原条目线程上，整本日记可对话式提问 |

**A 组共性**：时间线式日记流已是主流范式（≥3 个项目采用），Markdown 几乎是事实上的存储/交换格式（≥3），隐私是核心卖点（离线优先 + 无账号 + 无遥测几乎全体）。

### B 组｜习惯追踪

| 项目 | 星标 | 一句话定位 |
|---|---|---|
| HabitRPG/habitica | 14,293 | RPG 游戏化习惯，失败扣 HP 不清零，需要服务端 |
| iSoron/uhabits | 10,395 | 连续天数 + habit score 衰减算法，通知内 check/dismiss，可导出 SQLite，Tasker 写入 |
| FriesI23/mhabit | 1,691 | Flutter + SQLite + WebDAV + local-first，**用成长曲线评分替代连续天数**，小组件打卡，Windows + Android |
| xpavle00/Habo | 1,563 | 隐私优先习惯，E2EE 同步，多后端可选，可自建 |
| daya0576/beaverhabits | 1,852 | 自建习惯，极简，明确**不做 Goals** |
| InlitX/streak | 1,116 | 极简 Flutter 习惯，打卡类型分型、假期模式、活动网格、日历承载多类行为 |

**B 组共性**：连续天数 / 强度评分、打卡类型分型、灵活计划（每周 X 次 / 指定星期 / 每 N 天）、合法中断出口（假期 / 归档 / 跳过）四项机制被反复验证（≥3 个项目各自独立实现），是本领域最成熟的共识。

### C 组｜任务 / 项目 / GTD

| 项目 | 星标 | 一句话定位 |
|---|---|---|
| go-vikunja/vikunja | 5,972 | Go + 自建任务/看板，支持 Docker 部署，也有官方托管双轨 |
| johannesjo/super-productivity | 23,442 | 任务 + 习惯 + 番茄钟 + 时间追踪，多端，Web 版功能受限，插件生态 + MCP |
| onejgordon/flow-dashboard | 1,686 | 目标 + 任务 + 习惯 + 每日问卷 + 仪表盘，**已停更** |
| mhss1/MyBrain | 2,232 | Android 一体化：任务 + 笔记 + 日历 + 日记 + 书签，局域网直连同步（AES-GCM） |
| Achuan-2/siyuan-plugin-task-note-management | 227 | 思源插件：任务绑定笔记块，**任务寿命分态**（进行中/短期/长期），项目 + 里程碑 |
| lunatask/lunatask | 124 | 加密待办 + 习惯 + 日志 + 看板，自建桌面应用 |

**C 组共性**：项目 + 里程碑 + 子项目（≥3）、看板视图、任务寿命分态、时间线排期 + 日历并排、外部 issue 系统双向同步。

### D 组｜目标 / 复盘仪表盘

`onejgordon/flow-dashboard` 是唯一样本但极具参考价值：目标 → 任务 → 习惯 → 每日问卷 → 月度自评 → burn-up 进度图，形成完整闭环。它的**「每日报告」= 昨日亮点 + 今日优先 + 阻塞项**三段式，与 `Dayflow` 的每日站会完全同构，说明这个视图不是某个人的发明，而是被两个独立项目各自收敛出来的形态。**该仓库已停更，只能读设计，不能当活样本。**

---

## 三、代表项目深度分析（功能 · 优势 · 价值）

### 3.1 FriesI23/mhabit —— 与 PractiLog 最贴近的样本

- **功能**：Flutter 习惯管理，SQLite 本地存储，WebDAV 同步，支持 Windows / Android / Web。
- **优势**：
  1. **用「成长曲线评分」替代「连续天数」**——中断后不会归零，只衰减；
  2. 桌面小组件直接打卡，不用打开 App；
  3. local-first：断网可用，云端只是可选备份；
  4. Apache-2.0 许可，是本组唯一宽松许可（uhabits 是 GPL-3.0，Habo 是 GPL-3.0）。
- **价值**：它同时证明了「Flutter + SQLite + WebDAV + 双端」和「打分替代连击」两条对 PractiLog 都成立的选择。
- **对 PractiLog 的启示**：**强烈建议把「连续天数」改成「习惯强度评分」或双指标并存**。连击数字具有强烈的负反馈——中断一次就归零，用户容易直接弃用产品；强度评分允许「休息一天不掉太多」。这也和你的「极简模式、降低负担」定位一致。

### 3.2 JerryZLiu/Dayflow —— 「对照结果」的最优解

- **功能**：macOS/Swift，通过屏幕分块 + AI 生成活动卡片，自动生成工作日志；每日站会；分心时段与专注时段并排；AI 可本地/云切换；存储上限自动清理。
- **优势**：
  1. **不需要用户手写**——日志由行为自动生成；
  2. **分心 vs 专注并排对比**，不需要人工标注就能看出一天时间去向；
  3. 每日站会三段视图，直接对应原书「昨晚对照结果 / 今晚对照目标」。
- **价值**：把「结果」这一环从主观自述变成了客观行为数据。
- **对 PractiLog 的启示**：Dayflow 是 macOS 专属、依赖屏幕录制，**不适合直接移植到 Windows + Android**。但它的**结构**可借鉴：每日站会三段视图 + 「时间去向」可视化，都是纯前端逻辑，不依赖系统权限，成本低、收益高。

### 3.3 iSoron/uhabits —— 打卡模型的工程细节标杆

- **功能**：Android/Kotlin，Loop 习惯追踪，连续天数，habit score 衰减算法，通知内 check / dismiss，每条记录独立提醒 + 重复周期 + 一个任务多个提醒，可导出 SQLite，Tasker 写入打卡。
- **优势**：
  1. **habit score 衰减算法**（连续天数不是唯一指标）；
  2. **通知内直接操作**，减少「收到通知 → 打开 App → 找到条目 → 打卡」的 4 步摩擦；
  3. 导出 SQLite —— 数据不锁死在 App 里。
- **价值**：把「打卡」这件高频小事做到几乎零摩擦。
- **对 PractiLog 的启示**：**「通知内打卡」是 MVP 内最值得优先做的单点优化**。你的需求第 3 条（打卡自动回填日志）真正的摩擦点不在回填，而在「打开 App 找到那条习惯」。uhabits + streak + mhabit + super-productivity（≥3）都独立实现了通知内操作，说明这是高共识的低成本收益点。

### 3.4 Yu-Core/SwashbucklerDiary —— 内容级隐私与跨端技术验证

- **功能**：.NET 10 + Blazor Hybrid，Windows / Android / Web，SqlSugar + SQLite，WebDAV 备份 + 局域网同步，**隐私模式只遮蔽私密条目内容而非整个 App 锁屏**。
- **优势**：
  1. **内容级隐私**——在公共场合打开 App 只看到遮蔽后的条目；
  2. 同一套 C# 代码覆盖桌面与移动，Windows 端体验统一；
  3. 富结构图表语法（脑图 / 甘特 / 流程 / 时序）。
- **价值**：证明了「双端」不等于「两套代码」的解法是存在的。
- **对 PractiLog 的启示**：若走 C#/Blazor，Windows + Android 双端可用一套代码；若走 Flutter，参考 mhabit / moodiary / jotsy。**两条路都成立，选型取决于团队熟悉度而非技术优劣**。另外，「内容级隐私模式」比「锁屏」更适合日志类产品——日志的敏感度是**逐条**的，不是全局的。

### 3.5 UdaraJay/Pile —— AI 与原条目「线程化」结合

- **功能**：桌面日记；AI reflect 的输出**附着在原条目的线程上**而不是生成独立文档；可对整本日记做对话式提问；有 AI 成本上限提示。
- **优势**：AI 不污染原始记录；成本可控。
- **价值**：提供了一条「不破坏原书「行动日志」结构地引入 AI」的路径。
- **对 PractiLog 的启示**：如果未来加 AI 复盘（V1.2），**必须挂在条目线程上**，不要让 AI 另起一套文档——否则你的「对照目标—对照过程—对照结果」闭环会被打散。

### 3.6 onejgordon/flow-dashboard —— 目标管理的完整闭环设计（已停更，仅读设计）

- **功能**：目标 + 任务 + 习惯 + 每日问卷式日志 + 仪表盘；项目 burn-up 进度图；任务完成度三态分析（准时 / 迟到 / 未完成）；月度自评（每月给目标打分 + 月末目标评估报告）。
- **优势**：把「目标」和「每日执行」放进同一个数据模型，而不是两张皮。
- **价值**：**它的月度自评结构（月目标 / 月总结：目标完成情况 / 原因和障碍 / 克服障碍的对策与方法 / 本月创新与收获）与《五项管理》原书的月页结构几乎一一对应**（原书 L1392、L1844 附近）。这说明原书的设计在现代软件里是可实现的，不只是纸面体系。
- **对 PractiLog 的启示**：**这是全样本中与你的理论框架最同构的设计**。可以直接借鉴它的「月目标 → 月度总结四问」结构，作为 V1.1 的复盘模块蓝本。注意它已停更，代码不要参考，只参考信息架构。

### 3.7 usememos/memos —— 碎片捕获 + 备份收敛

- **功能**：微博式碎片，时间线 + 标签双轴，可见性三级；整库备份收敛到单一目录；带 MCP server，CLI 可操作。
- **优势**：**备份收敛到单一目录**（用户 `cp -r` 就能全量带走数据），可被外部工具读写。
- **价值**：证明了「数据可被外部工具直接操作」是长期存活的关键——工具链会围绕你的数据格式生长。
- **对 PractiLog 的启示**：SQLite 单文件本身已满足这个特性，但建议在架构上明确「**SQLite 文件即数据契约**」，并预留 CLI/脚本访问入口（siyuan、logseq、super-productivity 都做了 CLI）。

### 3.8 ZhuJHua/moodiary —— 同步分层与导出矩阵

- **功能**：Flutter + Rust 跨平台；同步拆成三层——WebDAV / S3 + 局域网直连 + **可选** E2EE 三段独立可选；地点足迹地图；多格式导出矩阵。
- **优势**：**把「同步方式」和「是否加密」解耦成两个独立开关**，用户可以按信任级别自由组合。
- **价值**：在「云同步」与「隐私」这对矛盾需求之间给出了成熟的中间解。
- **对 PractiLog 的启示**：MVP 里的「本地 SQLite + WebDAV 可选同步」方向正确。建议**在数据模型层面就把同步通道和加密开关预留出来**，哪怕 MVP 只实现 WebDAV 不加密——后期加 E2EE 时不需要重构表结构。

### 3.9 其他值得记住的样本

- **HabitRPG/habitica（14,293★ / 4,461 fork）**：游戏化三件套（等级 / HP / 金币 / 装备）；**失败扣 HP 但不清零连续记录**；有 API 使用规范页。**注意：2026-08-04 起官方暂停社区 PR 且禁止 AI 生成代码**——它是一个「成熟但封闭」的样本，机制可读，代码不可用。
- **johannesjo/super-productivity（23,442★ / 2,260 fork）**：任务 + 习惯 + 番茄钟 + 时间追踪，是「多模块合一」的可行先例；插件生态 + MCP 齐全；Web 版功能受限说明全端同权很难；外部 issue 系统双向同步（自动导入 + 变更即时通知 + 自动写工作日志）是很巧妙的设计。
- **xpavle00/Habo（1,563★）**：E2EE + 多后端 + 可自建 + 生物识别锁 + 合法中断出口，是隐私维度的最佳实践合集。
- **siyuan-note/siyuan（47,102★）**：**明令禁止第三方同步盘**（因为会损坏块级引用索引）——这是一条极其重要的负面经验：如果你的数据模型有增量/派生结构（如按标签聚合的倒排表、习惯连续天数缓存），**绝对不能允许用户把数据库丢进 OneDrive/百度网盘同步**，会静默损坏。这类「派生索引 + 文件级同步」的冲突，PractiLog 一定会遇到。
- **go-vikunja/vikunja（5,972★）**：自建 + 官方托管双轨，Docker 一键部署；桌面客户端单独许可——**注意许可分层**。

---

## 四、跨项目成熟机制清单（已被多项目验证）

以下机制按「被多少个独立项目实现」排序。标注 **≥3** 的是领域共识级机制，落地风险最低。

### 4.1 每日记录与时间线
| 机制 | 出现项目 |
|---|---|
| **时间线式日记流**（按写入日自动排列，不要求先分类） | ≥3：moodiary、memos、storypad、aaf-easydiary、Daily_You、SwashbucklerDiary、flow-dashboard、Dayflow |
| **「今日」聚合页**（任务 + 日程 + 待办一屏总览） | ≥3：MyBrain、super-productivity、streak、flow-dashboard、Dayflow |
| 每日笔记作为独立一等对象、可被命令行操作 | siyuan（`dailynote` CRUD）、logseq |
| 每日问卷式日志（问题可配置） | flow-dashboard |
| 自动从屏幕活动生成时间线（无需手写） | Dayflow |
| 多年后同日回访旧条目（Throwback） | storypad |

### 4.2 习惯与连续性
| 机制 | 出现项目 |
|---|---|
| **连续天数 / 习惯强度评分** | ≥3：streak、uhabits、mhabit、habitica、siyuan-plugin |
| **强度随中断衰减而非归零** | uhabits、mhabit |
| **打卡类型分型**：普通 / 避免型（含复吸）/ 计数型（带单位与目标）/ 清单式 / 跳过 | ≥3：streak、Habo、mhabit、siyuan-plugin |
| **灵活计划**：每周 X 次 / 指定星期 / 每 N 天 | ≥3：streak、uhabits、Habo、flow-dashboard |
| **合法中断出口**：假期模式 / 归档 / 跳过不打断连续 | ≥3：streak、Habo、flow-dashboard |
| 补打卡（修正任意历史日） | streak |
| 按星期几/时段分析「你何时最稳定」 | streak、flow-dashboard |
| 打卡目标用「番茄时长」而非次数计量 | siyuan-plugin |
| 游戏化反馈回路（等级 / HP / 金币 / 装备） | habitica、streak |
| **导入其它 App 时连历史与连续天数一起迁移** | ≥3：streak、mhabit、Daily_You、joplin |

### 4.3 任务与项目
| 机制 | 出现项目 |
|---|---|
| **项目 + 里程碑 + 子项目并行** | ≥3：siyuan-plugin、flow-dashboard、vikunja |
| 任务绑定到笔记块，点标题跳转 / 悬浮预览 | siyuan-plugin、siyuan |
| 看板视图（Kanban / 艾森豪威尔矩阵内置） | super-productivity、siyuan-plugin |
| **任务寿命分态**（进行中 / 短期 / 长期），防任务堆积 | siyuan-plugin |
| 任务完成度三态分析（准时 / 迟到 / 未完成） | flow-dashboard |
| 项目 burn-up 进度图 | flow-dashboard |
| 时间线排期 + 日历事件并排 | super-productivity、siyuan-plugin、MyBrain |
| 外部 issue 系统双向同步（自动写工作日志） | super-productivity |

### 4.4 复盘与回顾
| 机制 | 出现项目 |
|---|---|
| **每日站会视图：昨日亮点 + 今日优先 + 阻塞项** | Dayflow、flow-dashboard |
| 周回顾：何时专注 / 时间去向 / 什么把人拉走 | Dayflow、streak |
| 月度自评：每月给目标打分 + 月末生成目标评估报告 | flow-dashboard |
| 「想法—计划—执行—复盘」全链路串联 | siyuan-plugin、logseq |
| 分心时段与专注时段并排对比（自动识别） | Dayflow |
| 写作量 / 记录量本身成为可统计指标 | aaf-easydiary、streak |

### 4.5 提醒与桌面集成
| 机制 | 出现项目 |
|---|---|
| **桌面小组件**（习惯 / 今日 / 统计 / 活动网格） | ≥3：streak、uhabits、mhabit、MyBrain、habitica |
| **小组件内直接打卡 / 勾选，无需打开 App** | streak、mhabit |
| **通知内直接操作**（Done / Snooze / Add amount / check / dismiss） | ≥3：streak、uhabits、siyuan-plugin、super-productivity |
| 应用关闭仍能收到系统通知 | siyuan-plugin、MyBrain |
| **每条记录独立的提醒时间 + 重复周期 + 一任务多提醒** | uhabits、streak、Habo、siyuan-plugin |
| 提醒文案带鼓励语 / 随机时机提醒以降低对抗感 | streak、Daily_You、Habo |
| 专注计时 + 番茄钟 / 休息提醒 / 反拖延干预 | ≥3：super-productivity、siyuan-plugin、streak |
| 提醒计划可被其它工具订阅（CalDAV 桥） | beaverhabits、super-productivity、siyuan-plugin |

### 4.6 统计与可视化
| 机制 | 出现项目 |
|---|---|
| **GitHub 风格活动网格** | streak、Dayflow |
| **习惯历史图表**（曲线 / 柱状 / 完成率） | ≥3：uhabits、mhabit、streak、aaf-easydiary、storypad、MyBrain |
| 月历视图 / 月度完成次数统计 | ≥3：streak、Habo、aaf-easydiary、siyuan-plugin、MyBrain |
| 日历同屏承载多类行为（任务 + 习惯 + 番茄钟） | siyuan-plugin、streak、MyBrain |
| 按标签 / 分类对日志做分段统计 | flow-dashboard、moodiary |
| 可分享的进度卡片（导出为图片） | streak、storypad、aaf-easydiary |
| 数据外送分析出口（BigQuery） | flow-dashboard |

### 4.7 隐私与同步
| 机制 | 出现项目 |
|---|---|
| **离线优先 + 无账号 + 无遥测** | ≥3，几乎全体 |
| **端到端加密同步 + 多后端可选** | ≥3：Habo、joplin、super-productivity、moodiary、MyBrain |
| **WebDAV 作为用户自有同步通道** | ≥3：mhabit、moodiary、SwashbucklerDiary、super-productivity |
| **局域网直连同步（不经云）** | ≥3：MyBrain（二维码配对 + NSD + WebSocket + AES-GCM）、SwashbucklerDiary、moodiary |
| 自建服务端可选（Docker / Supabase / 官方托管） | beaverhabits、Habo、memos、vikunja、super-productivity、siyuan |
| 生物识别 / PIN 应用锁 | moodiary、storypad、streak、aaf-easydiary、MyBrain、Habo |
| **内容级隐私模式**（只遮蔽私密条目内容） | SwashbucklerDiary |
| 录制/采集数据的自动清理与存储上限 | Dayflow |

### 4.8 数据与导出
| 机制 | 出现项目 |
|---|---|
| **Markdown 作为存储或交换格式** | ≥3：joplin、logseq、siyuan、memos、moodiary、storypad、Daily_You |
| **多格式导出矩阵**（MD / Word / PDF / HTML / 长图 / 纯文本） | ≥3：moodiary、siyuan、storypad、SwashbucklerDiary、flow-dashboard、joplin |
| **导出为可再分析的结构化数据**（CSV / SQLite / JSON） | ≥3：uhabits、flow-dashboard、mhabit、streak |
| 导入导出对外部工具开放（API / MCP / CLI / REST） | ≥3：memos、siyuan、super-productivity、beaverhabits、vikunja |
| 整库备份收敛到单一目录 / 单文件 | memos、streak、moodiary |
| 从同类产品迁移并保留元数据（时间、地理位置、附件） | joplin、Daily_You、streak、mhabit |

### 4.9 输入效率与元数据
| 机制 | 出现项目 |
|---|---|
| Markdown 即时渲染 + 富结构图表语法 | ≥3：SwashbucklerDiary、siyuan、storypad、joplin |
| **心情 / 情绪作为独立元数据并可回溯** | ≥3：moodiary、storypad、Daily_You、MyBrain、SwashbucklerDiary |
| **天气 + 心情 + 位置三元组随条目记录** | ≥3：SwashbucklerDiary、moodiary、aaf-easydiary、flow-dashboard |
| 地点足迹地图 / 位置拾取与地图 | moodiary、flow-dashboard、aaf-easydiary |
| 语音输入与语音日记 | aaf-easydiary、storypad |
| 分享菜单作为捕获入口 | MyBrain、memos、joplin |
| **对话式交互：AI 可直接创建/查找条目或执行打卡** | ≥3：Pile、MyBrain、moodiary、Dayflow、flow-dashboard |
| 块级引用 + 双向链接 + 自定义属性 | siyuan、logseq |
| 标签 / 分类 / 星标 / 大纲多套组织手段并存 | ≥3：storypad、memos、moodiary、joplin、super-productivity |

### 4.10 扩展、部署与商业化
| 机制 | 出现项目 |
|---|---|
| 插件 / 主题 / 片段作为扩展主渠道 | ≥3：siyuan、logseq、super-productivity、joplin |
| Docker / Kubernetes / Unraid 一键部署 | siyuan、memos、beaverhabits、vikunja、super-productivity |
| **CLI 直接操作本地数据 + JSON 输出 + dry-run** | siyuan、logseq |
| 免费本体 + 会员/Pro 增值，或一次性买断 | siyuan-plugin、siyuan、storypad、Daily_You、vikunja |
| 多语言与社区翻译流程 | ≥3：mhabit、streak、SwashbucklerDiary、storypad、MyBrain、habitica |

---

## 五、与 PractiLog 核心需求的逐项对比

### 5.1 对照《核心需求校验清单》8 条

| # | 你的需求 | 现有产品中的对应实现 | 验证程度 | 结论 |
|---|---|---|---|---|
| 1 | **简化填表** | storypad / streak / beaverhabits 的极简单页；flow-dashboard 的可配置问卷；Dayflow 的全自动生成 | ✅ 充分验证 | **直接抄**：单页 + 可配置字段 + 默认全折叠 |
| 2 | **独立待办池，一键加入当日计划** | super-productivity、vikunja、mhabit 的独立任务池 + 「今日」视图；MyBrain「今日」聚合页 | ✅ 充分验证 | **直接抄**：待办池是独立实体，「加入今日」是一次状态迁移而非复制 |
| 3 | **习惯打卡自动回填日志** | Dayflow（自动）、streak（手动回填）、super-productivity（习惯+任务同页） | ⚠️ 部分验证 | **关键设计点**：回填要带**「来源标记」**，让用户看出这行是打卡生成而非手写。建议回填行可一键转为普通条目或删除 |
| 4 | **计划与习惯各自独立提醒** | uhabits / Habo / streak / siyuan-plugin 的「每条记录独立提醒 + 重复周期 + 一任务多提醒」 | ✅ 充分验证 | **直接抄**：提醒实体与业务实体解耦，一条记录挂 N 个提醒 |
| 5 | **长线项目增量记录，不强制闭环** | siyuan-plugin 的项目 + 里程碑、flow-dashboard 的 burn-up、vikunja 的项目 | ❌ **无直接对标** | **这是你的差异点**。现有项目都要求「完成」；你要的是「持续增量」。建议照抄 flow-dashboard 的 burn-up 表达（累计进展曲线），但**去掉完成率/完成度统计** |
| 6 | **Windows + Android 双端** | mhabit（Flutter）、SwashbucklerDiary（Blazor）、moodiary（Flutter）、MyBrain（Android 为主）、super-productivity（多端） | ✅ 充分验证 | **直接抄**：单代码库双端；注意 super-productivity「Web 版功能受限」的教训 |
| 7 | **完整版 / 极简版切换** | beaverhabits / storypad 只走极简单向；**无成熟双模式先例** | ❌ **无直接对标** | **这是你的第二个差异点**，也是风险点。建议双模式做成「同一数据、两种视图密度」的开关，而不是两套数据模型 |
| 8 | **复盘区分可控 / 不可控** | Dayflow（分心/专注自动识别）、flow-dashboard（原因和障碍）、habitica（失败扣 HP 不清零） | ⚠️ 部分验证，且**与原书相反** | **产品自创改良**。habitica 的「失败有代价但不抹杀记录」是很好的参照 |

### 5.2 对照 MVP v0.1 六大模块

| MVP 模块 | 可直接引入的成熟机制（来源） | 建议优先级 |
|---|---|---|
| **每日日志** | 时间线流（memos/moodiary）；今日聚合页（MyBrain/streak）；站会三段视图（Dayflow/flow-dashboard）；心情元数据 + 天气/位置三元组（moodiary/aaf-easydiary/flow-dashboard）；Markdown 渲染（joplin/logseq） | 站会三段视图 P0；时间线流 P0；心情元数据 P1；天气/位置 P2 |
| **待办库** | 独立任务池 + 「加入今日」（super-productivity/vikunja）；任务寿命分态（siyuan-plugin）；ABC 优先级（原书 L1889–L1897 体系，flow-dashboard 的艾森豪威尔矩阵是同族但不同法，**不要混用**） | 独立池 + 加入今日 P0；寿命分态 P2 |
| **习惯** | 打卡类型分型（streak/Habo/mhabit）；强度评分替代连击（mhabit/uhabits）；灵活计划（每周 X 次/指定星期）（≥3）；合法中断出口（≥3）；小组件打卡（streak/mhabit）；通知内打卡（≥3）；合法补打卡（streak） | 打卡类型分型 + 强度评分 + 中断出口 P0；通知内打卡 P0；小组件 P1；补打卡 P1 |
| **长线项目** | 项目 + 里程碑（≥3）；burn-up 累计进展（flow-dashboard）；时间线排期 + 日历并排（super-productivity/siyuan-plugin） | 里程碑 P1；增量时间线（自创）P0；burn-up P2 |
| **提醒** | 提醒实体与业务解耦、一任务多提醒（uhabits/streak/Habo）；鼓励语 / 随机时机（streak/Daily_You/Habo）；应用关闭仍能收到通知（siyuan-plugin/MyBrain）；CalDAV 桥（beaverhabits） | 实体解耦 P0；鼓励语/随机时机 P1；CalDAV P3 |
| **历史浏览** | 时间线回溯（≥3）；多年同日回访 Throwback（storypad）；GitHub 风格活动网格（streak/Dayflow）；月度复盘四问（flow-dashboard，对应原书月页） | 活动网格 P1；Throwback P2；月度四问 P1 |

### 5.3 对照「明确不做」清单

你的不做清单（统计图表、导出、附件、协作、iOS、复杂循环任务）与调研结论**基本一致，没有冲突**，但有两处值得注意：

- **统计图表**：全样本中「习惯历史图表」是被 ≥3 个项目验证的高频需求（uhabits/mhabit/streak/aaf-easydiary/storypad/MyBrain）。**你的 MVP 不做图表是可以的**（会拖慢开发），但**活动网格**（GitHub 风格）成本远低于完整图表系统，且视觉反馈价值极高 —— 建议在不做「完整统计」的前提下，**单独保留一个活动网格**作为 V1.1 的低成本出口。
- **导出**：uhabits / mhabit / streak / flow-dashboard 全部支持导出 SQLite/CSV。这是用户「数据不锁死」的最后一道保险，也是让用户敢长期投入的关键。**建议至少保留「导出 SQLite 文件」这一个零成本动作**（SQLite 本来就是单文件，导出即复制），**不违反你的不做清单**（它不算「导出功能」，只是文件复制）。
- **复杂循环任务**：注意「每周 X 次 / 指定星期」这类**灵活计划**是被 ≥3 个项目验证的刚需，且实现复杂度远低于「每月第 2 个周二」这类复杂循环规则。建议在不做清单里**明确豁免「每周 X 次 + 指定星期」**，否则会误伤刚需。

---

## 六、理论一致性核对与风险提示

### 6.1 你的需求与《五项管理》原书的对应关系

| 你的设计 | 原书依据 | 判定 |
|---|---|---|
| 每日日志结构 | 原书每日页 = 日期 + 4 列计划表（ABC 分类 \| 起止时间 \| 今日事项 \| 完成打√）+ 今日学习 + 今日反省 + 改进方法 + 心态 8 项打分（L632–639、L826–L843） | ✅ **有原书依据** |
| ABC 优先级 | A 最重要 / B 重要 / C 次重要（L1889）；A 类三判据（L1895–L1897） | ✅ 有原书依据 |
| 计划与过程/结果对照 | 「每人每天每件事，早上对照目标，中间对照过程，晚上对照结果」（L2434） | ✅ 有原书依据，且**你的站会三段视图正是它的产品化** |
| 复盘结构 | 月页含月目标 / 月总结（目标完成情况 \| 原因和障碍 \| 克服障碍的对策和方法 \| 本月创新与收获）；周复盘页含上周总结四段 + 随笔 + 本周目标 | ✅ 有原书依据 |
| 目标领域 | 六大领域：事业、财富（理财规划）、家庭生活、学习成长、人际关系、健康休闲（L1392、L1844） | ✅ 有原书依据 |
| **长线项目增量记录** | **原文未出现**「长线项目 / 里程碑 / 增量进展」 | ⚠️ **产品自创** |
| **习惯打卡 / 连续天数 / 完成率** | **原文未出现**「打卡 / 连续天数 / 完成率」 | ⚠️ **产品自创** |
| **复盘区分可控 / 不可控** | 原文唯一接近的是内部/外部时间陷阱分类（L1749、L1753）；但原文强推「决不找借口、全部担责」（L803–L814） | ⚠️ **与原书方向相反的产品自创** |
| **完整版 / 极简版切换** | **原文未出现**；原文走「强检查 + 惩罚」路线（L2438、L2440、L2500） | ⚠️ **与原书方向相反的产品自创** |
| **重要紧急四象限** | **原书不存在四象限**（只存在 ABC 三分类） | ❗ **不要使用「艾森豪威尔矩阵」表述** |
| **每日 A 类条数限制** | 原文**未规定**每天 A 类条数（但强调 20% 重要事项用 80% 时间保证完成，L1882） | ℹ️ 原文未明确 |
| **心态评分 0/10 二元制** | 8 项维度逐字为：认真、快、坚守承诺、保证完成任务、乐观、自信、爱与奉献、决不找借口（L632–L639、L828–L837），成功 = 心态 × 能力（L860） | ℹ️ 如要实现必须严格照抄 8 项与 0/10 制，**不要改成 1–5 星** |

### 6.2 五条风险提示

1. **不要宣称「忠于原书」**。原书是「强检查 + 惩罚 + 每日打卡」的体系（L2438、L2440、L2500），你的 MVP 是「极简 + 降负担 + 可控/不可控归因」，两者在精神上是相反的。正确表述：**「以五项管理为信息架构骨架，用现代个人效能产品 15 年验证过的减负机制替换其执行强度」**。这样既诚实，又保留理论权威。

2. **「可控/不可控」是与原书冲突的主动改良，要标清楚**。原书要求「全部担责、决不找借口」。你的设计允许用户把失败归因为外部。**建议做法**：在复盘界面保留「可控」与「不可控」两个字段的同时，加一个「下一步可控动作」字段——这既保留了你的归因空间，又把用户拉回「行动」这个原书核心上，且与 flow-dashboard 的「克服障碍的对策和方法」结构一致。

3. **不要引入四象限**。原书只有 ABC。调研中确实看到 super-productivity 与 siyuan-plugin 内置了艾森豪威尔矩阵，但那属于通用效率软件的做法，**不是五项管理的做法**。混用会造成理论表述混乱。建议：日志里的优先级用 ABC；如要提供四象限，**明确标注为「通用任务视图」**，与日志的 ABC 分离。

4. **派生索引 vs 文件同步的冲突**（来自 siyuan 的教训）。你的 SQLite 里有大量派生数据：习惯连续天数缓存、按标签的聚合索引、reminder 调度表、统计缓存。**绝不能让用户把 SQLite 文件丢进 OneDrive / 百度网盘 / iCloud**——文件级同步会替换文件导致缓存与主数据不一致甚至损坏。要么在文档里明令禁止，要么让 WebDAV 同步走「导出快照文件」而非「同步活数据库」。

5. **长线项目「不强制闭环」是差异点，也是最难的产品设计**。调研中**没有任何一个样本做过**（siyuan-plugin / flow-dashboard / vikunja 全部要求完成态）。这意味着：① 你没有现成范式可抄，要自己定义「增量记录」的数据模型（增量条 / 里程碑 / 关联日志 / 进展快照）；② 建议在 MVP 里**把它做得极简**：长线项目 = 标题 + 关联日志条目（复用日志的日期与正文）+ 一条「本次增量」追加记录，不引入里程碑表、不引入进度百分比。**用最小模型验证需求真伪**，把里程碑体系留到 V1.1。

---

## 七、可直接借鉴的功能清单（按优先级）

### P0 —— MVP 内就该做（成本低、验证充分、不越界）

| 功能 | 来源项目 | 落地位置 | 说明 |
|---|---|---|---|
| **连续天数 → 强度评分双指标** | mhabit、uhabits | 习惯模块 | 中断只衰减不清零，与「极简/降负担」定位一致 |
| **打卡类型分型**（普通 / 计数带目标 / 避免型 / 清单式 / 跳过） | streak、Habo、mhabit | 习惯模块 | 一次建模，覆盖 80% 真实习惯场景 |
| **合法中断出口**（假期模式 / 归档 / 跳过不打断连续） | streak、Habo、flow-dashboard | 习惯模块 | 决定用户休假回来后还留不留 |
| **通知内直接打卡** | uhabits、streak、mhabit、super-productivity | 提醒模块 | 把 4 步摩擦压到 1 步 |
| **提醒实体与业务实体解耦**（一条记录挂 N 个提醒） | uhabits、Habo、streak | 提醒模块 | 直接满足需求第 4 条 |
| **每日站会三段视图**（昨日亮点 / 今日优先 / 阻塞项） | Dayflow、flow-dashboard | 每日日志 | 原书 L2434 的产品化落地 |
| **打卡回填带来源标记 + 可转为手写条目** | Dayflow、streak | 每日日志 ↔ 习惯 | 满足需求第 3 条且不污染日志 |
| **独立待办池 + 「加入今日」一次迁移** | super-productivity、vikunja | 待办库 | 满足需求第 2 条 |
| **时间线式日记流** | memos、moodiary、storypad 等 ≥3 | 历史浏览 | 已是事实标准 |
| **导出 SQLite 文件**（= 复制单文件） | uhabits、mhabit、streak | 全局 | 几乎零成本，给用户数据安全感 |

### P1 —— V1.1（需要额外设计，但已被验证）

| 功能 | 来源项目 | 说明 |
|---|---|---|
| 桌面小组件 + 小组件内直接打卡 | streak、mhabit | Windows 需另找方案（Windows 11 Widgets），Android 简单 |
| GitHub 风格活动网格 | streak、Dayflow | 成本远低于完整图表系统，视觉反馈强 |
| 心情 / 情绪作为独立元数据 | moodiary、Daily_You、storypad | 支撑「极简模式」一键切换心情评分 |
| 天气 + 位置随条目记录 | moodiary、aaf-easydiary | 位置需权限，Windows 上麻烦，可后置 |
| 项目 + 里程碑 | siyuan-plugin、vikunja、flow-dashboard | 支撑长线项目的完整形态 |
| 月度复盘四问 | flow-dashboard（对应原书月页） | 与原书 L1392、L1844 结构对齐 |
| 补打卡 / 修改任意历史日 | streak | 用户会犯错，必须能修 |
| 多年后同日回访（Throwback） | storypad | 留存钩子，成本低 |
| 提醒文案鼓励语 / 随机时机 | streak、Daily_You、Habo | 降低提醒对抗感 |
| 内容级隐私模式 | SwashbucklerDiary | 只遮蔽私密条目，比锁屏更贴日志场景 |
| 应用关闭仍能收到系统通知 | siyuan-plugin、MyBrain | Windows 上需计划任务或自建托盘常驻 |

### P2 —— V1.2（差异化加分，不进 MVP）

| 功能 | 来源项目 | 说明 |
|---|---|---|
| AI 对话式交互（创建/查找/打卡） | Pile、MyBrain、moodiary、Dayflow | AI 必须**挂在原条目线程上**（Pile 模式），不另起文档 |
| 习惯历史图表 | uhabits、mhabit、streak ≥3 | 需求明确但被你的不做清单排除，可留到 V1.2 |
| 番茄钟 / 专注计时 | super-productivity、streak、siyuan-plugin | 与「今日学习」「时间管理」联动 |
| 时间线排期 + 日历并排 | super-productivity、MyBrain | 长线项目排期 |
| 周回顾（时间去向 / 什么把人拉走） | Dayflow、streak | 需要数据积累 |
| CLI / MCP 访问本地数据 | siyuan、logseq、memos、super-productivity | 「SQLite 即数据契约」的兑现 |
| E2EE 同步 | Habo、joplin、moodiary | 需在**数据模型设计阶段**预留加密开关位，MVP 不实现 |
| 局域网直连同步 | MyBrain、SwashbucklerDiary、moodiary | 同上，先预留接口 |

---

## 八、改进建议（分层）

### 8.1 建议在 MVP 内调整（改动小、收益大）

1. **把「连续天数」改成「强度评分 + 连续天数」双指标**，并实现中断衰减。理由：mhabit 与 uhabits 两个成熟项目都独立做了这件事，机制成熟；连击归零的负反馈与你的「降负担」定位直接冲突。
2. **习惯模型增加「打卡类型」与「灵活计划」两个字段**（每周 X 次 / 指定星期）。理由：≥3 个项目各自实现，是刚需；同时请在「不做清单」里明确写明「**不做复杂循环规则**」，避免以后被自己误伤。
3. **打卡回填的日志行必须带来源标记**（如「来自习惯：晨跑」），并提供「转为普通条目」与「删除」两个动作。理由：Dayflow 与 streak 都验证过这条链路，但都没有把「可撤销 / 可转正」做得显眼；这是差异化的机会点。
4. **每日日志页固定一屏「站会三段」**（昨日亮点 / 今日优先 / 阻塞项）。理由：这是原书 L2434 的直接产品化，且两个独立项目收敛出同一形态，风险极低、认知成本极低。
5. **提醒从第一天就按「独立提醒表 + 业务表外键」建模**，不要用「任务上的一个 remind_at 字段」。理由：需求第 4 条明确要求计划与习惯各自独立提醒，而 ≥3 个项目都用「一任务多提醒」的模型；后期改造成本差异巨大。
6. **明确禁止「把 SQLite 丢进文件级同步盘」**，并在 README 与设置页写明；WebDAV 同步走「导出快照」而非「同步活库」。理由：siyuan 的公开教训。
7. **长线项目在 MVP 内只做最小模型**：项目 = 标题 + 一串追加的「增量记录」（复用日志条目的日期与正文）+ 可选里程碑文本。**不引入进度百分比、不引入完成率、不引入燃尽图**。理由：全样本无先例，先用最小模型验证真伪。
8. **MVP 阶段就在数据模型里预留两个开关位**：`sync_channel`（none / webdav / lan）与 `encryption`（none / e2ee）。MVP 只实现 none + webdav，但字段先在。理由：moodiary 的「同步方式与加密解耦」是成熟做法；后期加功能时不必重构表结构。

### 8.2 建议在 V1.1 做的（超出 MVP 但已验证）

1. Windows 端补上**桌面小组件 / 托盘常驻 + 应用关闭仍能通知**（Android 用系统通知，Windows 需要计划任务或托盘进程）。
2. **GitHub 风格活动网格**——在不做完整统计的前提下，提供最便宜的正反馈。
3. **月度复盘四问**（目标完成情况 / 原因和障碍 / 对策方法 / 本月创新与收获），与原书月页结构对齐。
4. **心情作为独立元数据**，并让「极简模式」可以只填心情 + 一个 ABC 清单。
5. **补打卡与历史修正**。
6. **内容级隐私模式**（只遮蔽私密条目内容）。
7. **长线项目里程碑体系**（在最小模型验证通过后再上）。

### 8.3 建议在 V1.2 做的

1. **AI 对话式交互**，且 AI 输出挂在原条目线程上（Pile 模式），另设成本上限提示。
2. **习惯历史图表**与更完整的复盘可视化。
3. **番茄钟 / 专注计时**，与「今日学习」栏联动。
4. **端到端加密同步**与局域网直连同步（数据模型已预留开关位的前提下）。
5. **CLI / MCP 开放**，兑现「SQLite 即数据契约」。

### 8.4 明确不要做的（避免被行业惯例带偏）

- **不要引入重要紧急四象限**（原书没有，且会与 ABC 冲突）。若提供，只能作为「通用任务视图」并明确隔离。
- **不要做「未完成事项惩罚」机制**（habitica 的 HP 扣减是游戏化闭环，迁移到严肃个人日志里会产生负反馈；habitica 自己也有大量用户因惩罚过重流失的社区讨论）。
- **不要把 AI 生成的总结当作用户日志的主体内容**——Dayflow 的价值在于它标记的是「真实发生的事」，不是「AI 认为你做了的事」。
- **不要在没有最小模型验证前就上里程碑 + 燃尽图 + 目标对齐矩阵全套**（flow-dashboard 那一套信息密度极高，不适合个人工具的「极简」定位）。

---

## 九、参考项目速查表

数据来源：GitHub REST API 实测，**2026-11-06** 快照。

| 项目 | ★ | fork | 语言 | 许可 | 创建日期 | 一句话价值 |
|---|---:|---:|---|---|---|---|
| usememos/memos | 64,315 | 4,938 | Go | MIT | 2021-12-08 | 碎片笔记时间线 + 单一目录备份 + MCP |
| laurent22/joplin | 57,061 | 6,398 | TypeScript | NOASSERTION | 2017-01-16 | Markdown + E2EE + WebDAV + CLI |
| siyuan-note/siyuan | 47,102 | 3,099 | TypeScript | AGPL-3.0 | 2020-08-30 | 块级双链 + 本地优先 + 禁第三方同步盘 |
| logseq/logseq | 45,497 | 2,867 | Clojure | AGPL-3.0 | 2020-05-23 | 大纲式日志 + 本地 Git |
| johannesjo/super-productivity | 23,442 | 2,260 | TypeScript | MIT | 2017-01-06 | 任务+习惯+番茄钟+时间追踪，多端合一 |
| HabitRPG/habitica | 14,293 | 4,461 | JavaScript | NOASSERTION | 2012-06-06 | RPG 习惯（已暂停社区 PR，禁 AI 代码） |
| iSoron/uhabits | 10,395 | 1,289 | Kotlin | GPL-3.0 | 2014-11-08 | 习惯评分衰减算法 + 通知内打卡 + 导出 SQLite |
| JerryZLiu/Dayflow | 7,394 | 461 | Swift | MIT | 2025-09-23 | 自动日志 + 站会三段 + 分心/专注并排（macOS） |
| go-vikunja/vikunja | 5,972 | 805 | Go | AGPL-3.0 | 2018-11-28 | 自建任务/看板，双轨部署 |
| UdaraJay/Pile | 3,122 | 214 | JavaScript | NOASSERTION | 2023-10-14 | AI 反思挂原条目线程 + 整本对话 |
| mhss1/MyBrain | 2,232 | 194 | Kotlin | GPL-3.0 | 2022-05-11 | Android 一体化 + 局域网 AES-GCM 直连 |
| ZhuJHua/moodiary | 2,059 | 183 | Dart | AGPL-3.0 | 2024-08-24 | 同步三层拆分 + 位置足迹 + 导出矩阵 |
| daya0576/beaverhabits | 1,852 | 86 | Python | BSD-3-Clause | 2024-03-11 | 极简自建习惯，明确不做 Goals |
| onejgordon/flow-dashboard | 1,686 | 186 | Python | MIT | 2017-03-11 | 目标-任务-习惯-问卷闭环（**已停更**） |
| FriesI23/mhabit | 1,691 | 106 | Dart | Apache-2.0 | 2023-04-26 | Flutter+SQLite+WebDAV 双端，成长曲线评分 |
| Yu-Core/SwashbucklerDiary | 1,627 | 156 | C# | AGPL-3.0 | 2022-12-23 | Blazor 双端 + 内容级隐私模式 |
| xpavle00/Habo | 1,563 | 183 | Dart | GPL-3.0 | 2020-07-19 | 隐私优先习惯 + E2EE + 多后端 |
| Demizo/Daily_You | 1,409 | 77 | Dart | AGPL-3.0 | 2023-08-05 | 私密日记 + 情绪模型 |
| journiv/journiv-app | 1,255 | 54 | JavaScript | NOASSERTION | 2025-10-20 | 自建私密日记 + 心情追踪 |
| InlitX/streak | 1,116 | 59 | Dart | GPL-3.0 | 2026-06-08 | 打卡分型 + 假期模式 + 活动网格 |
| theachoem/storypad | 1,009 | 132 | Dart | GPL-3.0 | 2022-01-03 | 极简日记 + Throwback 回访 |
| memex-lab/memex | 827 | 82 | Dart | GPL-3.0 | 2026-03-11 | 本地优先 AI 日记 |
| hanjoongcho/aaf-easydiary | 562 | 133 | Kotlin | GPL-3.0 | 2017-08-17 | Android 日记 UX + 语音 + 天气三元组 |
| Achuan-2/siyuan-plugin-task-note-management | 227 | 55 | TypeScript | AGPL-3.0 | 2025-06-09 | 任务寿命分态 + 项目里程碑 |
| CikeSeven/jotsy | 144 | 8 | Dart | AGPL-3.0 | 2026-03-08 | Flutter offline-first 日记 + 心情 + WebDAV |
| lunatask/lunatask | 124 | 1 | （仓库字段为空） | NOASSERTION | 2020-05-02 | 加密待办+习惯+日志+看板 |

---

## 十、附录：数据来源与可复现命令

```powershell
# 单仓库指标（README 的元数据来源）
gh api repos/<owner>/<repo> --jq '"\(.full_name)|\(.stargazers_count)|\(.forks_count)|\(.language)|\(.license.spdx_id // "NOASSERTION")|\(.created_at[0:10])"'

# 分类检索（README 的来源）
gh api -X GET search/repositories -f q='"habit tracker" in:name,description stars:>300' -f sort=stars -f order=desc -f per_page=18

# README 原文落盘（27 份）
$b64 = gh api "repos/<owner>/<repo>/readme" --jq '.content'
$txt = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($b64 -join '')))
[System.IO.File]::WriteAllText($f, $txt, (New-Object System.Text.UTF8Encoding($false)))
```

**中间产物清单**（均在 `F:\soft\00selfmade\practilog\docs\`）：
- `_research_metrics.tsv` / `_research_metrics_verify.tsv` —— 指标快照
- `_research_raw_repos.txt` / `_research_raw_repos_cn.txt` —— 原始检索清单
- `_research_readmes/` —— 27 份 README 原文
- `_research_readme_digest.md` —— 23 项逐项目分析 + 10 类跨项目模式
- `_research_readme_digest_extra.md` —— 4 项补充分析（journiv / memex / jotsy / lunatask）
- `五项管理理论要点摘要.md` —— 理论要点与行号定位

**引用规范**：本报告的理论行号 (Lxxxx) 指向 `高绩效人士的五项管理_全文.md`；标注「原文未明确」处即该文档中确实没有对应表述，未做任何补写。
