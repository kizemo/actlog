# 开源项目 README 功能机制摘要

> 数据来源：`docs/_research_readmes/` 下的 README 原文（只读，未联网）。
>
> **数据说明（抓取问题，主 agent 需注意）**：目录中实际有 29 个 `.md` 文件，但按内容去重后只有 26 份不同 README，其中 3 个文件的内容与其文件名不符：
> - `Pile.md`、`tridiontech__journal.md` 的内容均为 `Achuan-2/siyuan-plugin-task-note-management` 的 README；
> - `almarklein__planify.md` 的内容为 `johannesjo/super-productivity` 的 README。
>
> 因此本文档实际覆盖 **26 个真实项目的 README**，另为 `tridiontech/journal`、`almarklein/planify` 各保留一节并标注「README 未获取」。字段无对应内容一律写「README 未提及」。
>
> 补充说明：`Pile.md` 同样是错配副本（内容为 Achuan-2 插件 README，原始归属不明）；`UdaraJay/Pile` 一节按其自身 README 的真实内容撰写，不受影响。

---

## Achuan-2/siyuan-plugin-task-note-management

- **一句话定位**：思源笔记上的任务管理插件，为践行「防弹笔记法」而开发，把「想法—计划—执行—复盘」串成闭环。
- **平台与形态**：思源笔记插件（非独立应用），宿主覆盖桌面端与移动端；插件本身不独立分发。
- **技术栈与本地存储**：运行在思源笔记（Electron 桌面端 + Android/iOS/HarmonyOS App）之上；日历视图用 fullcalendar、农历用 lunar-typescript、番茄钟数据可视化用 echarts、时间解析用 chrono-node、节假日调休数据来自 china-holiday-calender；数据落在思源工作区，任务以「文档 / 块 / 数据库条目」为载体；README 未提及独立数据库。
- **同步机制**：由思源内核的同步/数据仓库机制承担（插件不自带同步）；插件侧额外提供**内核后台 Webhook 通知**（无需打开页面即可推送）。
- **核心功能清单**：
  - 时间提醒：为文档或块设置时间提醒；根据标题智能自动识别时间；支持重复周期提醒；一个任务可自定义多个提醒时间。
  - 提醒通知：电脑端与移动端系统通知；无需打开页面的内核后台 Webhook 通知；移动端即使思源笔记关闭也能收到通知。
  - 绑定块：任务可绑定文档与块，点标题跳转笔记内容、悬浮预览笔记内容。
  - 数据库条目：右键菜单可选「设置任务」「开始番茄钟」，支持绑定块条目与独立条目，多选可批量设置任务，独立条目自动填入标题与数据库链接。
  - 任务绑定习惯：任务完成可自动进行习惯打卡；任务的番茄钟可统计为某个习惯的番茄钟数据。
  - 项目看板：管理项目内全部任务，区分进行中 / 短期待办 / 长期待办；每个子项目一个分组，可并行管理多个子项目。
  - 日历视图：查看任务日期安排，同屏显示任务、习惯、番茄钟等数据；支持农历与中国节假日补班信息。
  - 四象限看板：区分重要且紧急、重要不紧急、不重要不紧急、不重要但紧急；可过滤只看进行中任务或某项目的任务。
  - 番茄钟：电脑端全局番茄钟可脱离思源以小窗显示；可对任务和任意块番茄专注；番茄数据统计；日历视图显示番茄钟数据。
  - 习惯打卡：罗列想养成的习惯，支持重复提醒，打卡目标可设为次数或番茄时长，支持数据统计。
  - 外部日历订阅：天气日历、节日日历、Outlook 日历；手机日历等其他软件可订阅插件日程。
  - MCP 接入：让 AI 成为任务管家。
- **值得借鉴的具体机制**：
  - **任务即「笔记里的行动节点」**：待办不落成独立清单行，而是绑定到具体文档/块，点标题跳转、悬浮预览，把任务、背景资料、复盘放进同一页。
  - **跨模块数据复用**：任务完成自动触发习惯打卡；番茄钟时长可计入某个习惯，任务系统与习惯系统共用一条数据通路。
  - **提醒三级兜底**：应用内提醒 → 桌面/移动系统通知（应用关闭仍可收）→ 内核后台 Webhook 通知，覆盖「应用没开就收不到」这个经典漏点。
  - **自然语言时间识别 + 重复周期 + 一任务多提醒**：标题里写「明天下午三点」即可解析成提醒。
  - **项目看板三态划分（进行中/短期/长期）**：显式区分任务寿命，避免所有待办堆在同一列表造成管理压力。
  - **习惯打卡目标双单位（次数 / 番茄时长）**：把同一套打卡逻辑接到两种不同的度量上。
  - **日历同屏三类数据（任务/习惯/番茄钟）**：一个时间轴承载多类行为记录。
- **许可证与注意事项**：AGPL-3.0。README 自述：插件 v6.0 起正式收费（会员功能）；开发动因是思源原生没有本地日程提醒、数据库无法展示父子任务架构。

---

## almarklein/planify

- **一句话定位**：README 未获取（目录中 `almarklein__planify.md` 的内容实为 `johannesjo/super-productivity` 的 README）。
- **平台与形态**：README 未提及。
- **技术栈与本地存储**：README 未提及。
- **同步机制**：README 未提及。
- **核心功能清单**：README 未提及。
- **值得借鉴的具体机制**：README 未提及。
- **许可证与注意事项**：README 未提及。

---

## daya0576/beaverhabits

- **一句话定位**：自托管的习惯追踪应用，README 标题即定位「A self-hosted habit tracking app without "Goals"」——刻意不做目标管理。
- **平台与形态**：Web 自托管（Docker 镜像）；另有官方托管 SaaS（beaverhabits.com，含 Demo 与定价页）；社区衍生形态包括 iOS 原生离线客户端、Stream Deck 面板、Apple 快捷指令、Home Assistant 开关。
- **技术栈与本地存储**：后端参考 NiceGUI（README 注明灵感来自 NiceGUI Todo List 示例）；开发用 uv 管理 Python 依赖；存储由环境变量 `HABITS_STORAGE` 二选一：`DATABASE`（单个 SQLite 文件 `habits.db`）或 `USER_DISK`（本地 JSON 文件）；Docker 持久化卷挂载在 `/app/.user/`。
- **同步机制**：自建服务端作为唯一数据源，多端通过 HTTP 访问；README 未提及端到端加密，也未提及离线写入。
- **核心功能清单**：
  - 习惯打卡与习惯索引页；索引页的日期列数可配（`INDEX_HABIT_DATE_COLUMNS`）。
  - REST API（README 链接到 Wiki 的 API How-to Guide）。
  - 部署路径：Docker / Docker Compose / Unraid 社区商店 / Easypanel 官方模板（一键部署 + 持久化卷）。
  - 开关类环境变量：`TRUSTED_LOCAL_EMAIL` 可跳过认证、`ENABLE_IOS_STANDALONE` 支持 iOS 独立客户端。
  - 容器以 nobody 用户启动（README 说明目的是提升安全性并兼容 OpenShift）。
  - 完整功能清单位于项目 Wiki，README 本身未展开。
- **值得借鉴的具体机制**：
  - **用「不做什么」写定位**：首句就是「without Goals」，把排除项当作差异化卖点，避免功能无限膨胀。
  - **存储后端可切换（单个 SQLite 文件 ↔ 本地 JSON 文件）**：同一镜像改环境变量即换存储策略，备份与迁移成本极低。
  - **把「打卡」开放成可编程接口**：CalDAV 桥、Home Assistant 开关、Stream Deck 面板、Apple 快捷指令都不是官方 App，却构成主要使用方式。
  - **容器以 nobody 启动 + 明写 UID 对齐**：把最常见的权限坑直接写进部署文档。
- **许可证与注意事项**：README 未提及许可证。功能清单需查 Wiki；提供官方 SaaS 定价；含赞助入口。

---

## CikeSeven/jotsy

- **一句话定位**：完全本地、无账号无服务器的中文日记应用，主打「日记本 + 模板 + 心情/天气/农历元数据 + 加密备份」的跨端（Android/Windows/Linux）体验。
- **平台与形态**：Android 7+、Windows 10+、Linux（GTK3）；**无 iOS 版本**。
- **技术栈与本地存储**：SQLite（应用私有目录）；无账号、无服务器；README 未提及具体语言与框架。
- **同步机制**：不做实时同步，提供**备份**通道：WebDAV、S3、Google Drive、OneDrive、Dropbox、百度网盘、阿里云盘；ZIP 备份支持 **AES-256 加密**。
- **核心功能清单**：
  - 富文本多媒体日记；10 种心情 emoji + 5 档精力；天气与地点。
  - 农历、法定节假日与调休；纪念日与倒数日。
  - 年度热力图；那年今日；时间胶囊。
  - 8 种日记模板（支持变量占位）；8 种日记本（可多归属、含章节、写作目标、智能日记本）。
  - 回收站 + 撤销；ZIP 备份（AES-256）；多网盘备份。
  - 导出 PDF / Word / Markdown / 网页 / TXT / CSV；导入 18 款应用（含 Evernote / Joplin / Memos）。
- **值得借鉴的具体机制**：
  - **备份加密下沉到备份文件本身（ZIP + AES-256）**：网盘侧只见密文，避免「同步盘泄露明文日记」这一真实事故路径。
  - **把「中国式时间感」做成一等元数据**：农历、节假日调休、纪念日倒数日直接进条目，而不是留给插件。
  - **模板变量占位 + 多归属日记本**：一套内容容纳多场景（写作目标、章节归属），降低模板切换成本。
  - **以「迁移」为核心卖点（18 款应用导入）**：日记类产品的真实流失点在搬家成本，导入矩阵比新功能更能留人。
  - **导出矩阵覆盖办公场景（PDF/Word/Markdown/网页/TXT/CSV）**：一条内容多处可用。
- **许可证与注意事项**：GPL-3.0。Linux 版不支持录音与应用锁，桌面版无视频页内播放；**卸载会丢数据，需定期备份**；联网仅用于天气定位、网盘备份、更新与云笔记导入。

---

## Demizo/Daily_You

- **一句话定位**：Android 上的本地优先日记应用，记录想法、追踪心情、保留照片记忆，强调「你的日记应该是你的，而不是产品」。
- **平台与形态**：移动端（Android）独立应用，Google Play / F-Droid / IzzyOnDroid / GitHub Releases 分发；开发环境用 Nix 描述，亦可用 Flutter 直接构建；无桌面端与 Web 版。
- **技术栈与本地存储**：Flutter；数据存本地，具体文件/数据库格式 README 未提及；**数据存放位置可由用户选择，包括外部存储**。
- **同步机制**：README 未提及跨设备同步；仅提到可导入其它 App 的备份文件。
- **核心功能清单**：
  - 每日记录：写下想法、反思或日常例程。
  - 心情追踪：洞察心情随时间的变化。
  - 照片记忆：条目可加图片。
  - 富笔记：Markdown 排版。
  - 温和提醒：**随机**的每日提醒以保持连续性。
  - 数据掌控：可选择数据存放位置，含外部存储。
  - 离线优先：无需联网始终可用。
  - 统计页与画廊页（截图中有 home / gallery / stats / entry view 四页）。
  - 从其它 App 迁移：设置 → Backup & Restore → Import From Another App。
  - 无账号、无广告、无功能锁定、无追踪与数据收集。
- **值得借鉴的具体机制**：
  - **随机时机的每日提醒**：不是固定时间提醒，而是随机提醒，降低打卡的心理负担与「到点被打断」的对抗感。
  - **存储位置作为用户主权**：把「数据放在哪（含外部存储）」做成显式产品能力，而不是写死的沙盒目录。
  - **迁移导入的诚实提示**：明确说明跨 App 导入「不保证一一对应」，因为两边功能不同，先降预期再迁移。
- **许可证与注意事项**：GPL-3.0，另加 GPL 第 7 条的附加条款（`ADDITIONAL_TERMS.md`）。自述「永久免费」，不订阅、不收费；非 F-Droid 商店渠道安装需手动允许未知来源。

---

## FriesI23/mhabit

- **一句话定位**：跨平台微习惯追踪器，用一套独立评分体系（不只连续天数）和成长曲线衡量长期坚持，并支持 WebDAV 跨设备同步。
- **平台与形态**：Android / iOS / macOS / Windows / Linux 全部覆盖（Google Play、App Store、F-Droid、Flathub、Microsoft Store、TestFlight、Homebrew、Scoop、AltStore/SideStore）；移动端 + 桌面端 + Linux 桌面三形态齐全，无 Web 版。
- **技术栈与本地存储**：Flutter / Dart + SQLite + Provider；**完全离线可用，无账号、无遥测**。
- **同步机制**：**WebDAV**（Nextcloud、Koofr、自建服务器）；路线图中「更多同步后端」标记为计划中（即当前只有 WebDAV）。
- **核心功能清单**：
  - 智能评分：不只是连续天数，量化「做」与「不要」两类习惯的一致性，用成长曲线呈现长期进展。
  - WebDAV 跨设备同步。
  - 深度自定义：每个习惯独立配色（内置色板 + 完整取色器）、可折叠习惯分组 + 拖拽排序、Material 3 + 动态取色。
  - 数据：原生 JSON 导入导出、Loop Habit Tracker 迁移导入。
  - 小组件：iOS 桌面小组件支持进度跟踪与打卡（beta）；Android 小组件进行中。
  - 多语言：18+ 语言，含阿拉伯语/希伯来语/波斯语 RTL 支持。
  - 免费、无广告、无内购、不需要账号。
- **值得借鉴的具体机制**：
  - **「评分 + 成长曲线」替代「连续天数」**：把「做型」与「不要型」习惯分成两套评分模型，长期进展用曲线而非数字展示，让偶尔断档不至于归零。
  - **单一 WebDAV 通道做全端同步**：只支持 WebDAV 但适配 Nextcloud / Koofr / 自建，零厂商锁定，用户可用已有 NAS。
  - **可折叠分组 + 拖拽排序**：长列表场景下把「折叠」与「排序」组合，降低维护成本。
  - **小组件内完成打卡与进度查看**：iOS 小组件支持进度跟踪 + 直接打卡。
- **许可证与注意事项**：Apache 2.0。README 未提及已知缺陷；Roadmap 中 Android 小组件仍在进行中，更多同步后端未实现。

---

## go-vikunja/vikunja

- **一句话定位**：自托管的任务管理器，定位语为「The task manager you actually own」，同时提供官方托管版与 Pro 版。
- **平台与形态**：Web 服务端 + 桌面客户端（仓库内含 `desktop/` 目录，单独授权）；Docker 镜像 `vikunja/vikunja`；官方托管实例 vikunja.cloud。
- **技术栈与本地存储**：README 正文未给出具体语言与数据库（仓库组织名暗示 Go，README 未提及）；提供 OpenAPI v2 / Swagger 文档。
- **同步机制**：README 未提及。
- **核心功能清单**：
  - 详细功能清单在官网 features 页与 try.vikunja.io，README 内未展开（README 未提及具体功能点）。
  - 提供托管版（vikunja.cloud）；Vikunja Pro 提供管理后台、审计日志、时间跟踪。
  - 支持 Docker 安装、源码构建、开发环境文档、Magefile、测试文档。
- **值得借鉴的具体机制**：
  - **双轨交付**：同一套核心同时提供「自己部署」与「官方托管」，并把企业向能力（管理面板、审计日志、时间跟踪）划入 Pro 而非核心。
  - **主仓 + 客户端分仓分许可**：`desktop/` 单独用 GPL-3.0-or-later，主仓用 AGPL-3.0-or-later。
  - **直接给一个可玩的试用实例**（try.vikunja.io）降低评估成本。
- **许可证与注意事项**：主仓 AGPL-3.0-or-later，`desktop/` 为 GPL-3.0-or-later；Unsplash 背景图需署名。README 自述：使用 LLM 辅助编码（多数 @tink-bot 的提交如此）；Pro 为付费能力。

---

## HabitRPG/habitica

- **一句话定位**：把人生当作 RPG 玩的开源习惯养成程序——成功就升级，失败就掉 HP，赚金币买武器和护甲。
- **平台与形态**：服务端应用 + Web 客户端；移动端为独立仓库（habitica-android、habitica-ios）。
- **技术栈与本地存储**：README 未提及。
- **同步机制**：README 未提及。
- **核心功能清单**：
  - 等级系统（升级）、HP（失败扣血）、金币、装备（武器与护甲）。
  - 贡献指引：Blacksmith 指南（技术栈与代码组织说明）、本地开发环境搭建指南。
  - API 使用规范（API Usage Guidelines），供第三方工具接入并保证玩家体验。
  - 2026 年 8 月 4 日起暂停接受社区 PR（Blacksmith 层）。
- **值得借鉴的具体机制**：
  - **游戏化三件套反馈回路**：完成 → 经验/等级 + 金币 → 购买装备（装备再影响属性），把「坚持」变成可见的资产积累。
  - **失败有代价但不终止**：失败扣 HP 而非直接清零进度，让中断仍有恢复路径。
  - **对外提供 API 规范页**：明确第三方工具的接入边界，而不是放任生态污染数据模型。
- **许可证与注意事项**：README 只写「代码按仓库 LICENSE 授权」，**未在 README 中指明具体许可**（README 未提及）。另：禁止提交 LLM/AI 生成的代码，AI 辅助提交会被拒；发现 bug 需发邮件给管理员而不是提 issue。

---

## hanjoongcho/aaf-easydiary

- **一句话定位**：主打「最佳用户体验」的 Android 日记应用，覆盖写作、搜索、日历、时间线、图表与备份。
- **平台与形态**：移动端（Android）独立应用，双 flavor：GMS（含 Google 服务、Drive 备份、完整天气图标）与 FOSS（不含 GMS，Drive 备份不可用，天气图标简化）。
- **技术栈与本地存储**：Android（Kotlin 生态，README 未逐项列出库）；数据库/存储格式 README 未提及。
- **同步机制**：**Google Drive** 备份与恢复（含附加的照片等全部内容）——仅 GMS 版可用；FOSS 版因剔除 GMS 而没有该能力。
- **核心功能清单**：
  - 写作编辑：键盘输入或语音识别写日记。
  - 搜索：快速检索，**匹配关键词高亮**。
  - 日历：按日期组织查看条目。
  - 时间线：按时间顺序浏览全部日记条目。
  - 日记明信片：用条目与照片生成可分享的漂亮卡片（适合纪念日、节日祝福）。
  - 锁：PIN 或指纹。
  - 主题：171 套配色主题 + 取色器自定义文字与背景。
  - 字体：支持自定义 TTF 字体，放入字体目录即可用。
  - 图表：用柱状图可视化日记写作习惯。
  - 备份恢复：Google Drive 备份与恢复全部内容（含照片）。
  - Markdown 语法支持；位置信息显示；欢迎页弹窗；优化过的卡片视图；日历起始日可设置；自定义符号（彩蛋）。
- **值得借鉴的具体机制**：
  - **「日记明信片」**：把条目 + 照片合成为可分享卡片，给记录行为加一个社交出口，把私密记录转成可展示的作品。
  - **写作量柱状图**：用图表回答「我最近写得勤不勤」，把记录频率本身变成可反馈的指标。
  - **搜索命中高亮**：长文本检索里高亮关键词，显著降低复核成本。
  - **日历起始日可配置**：周起始日是高频本地化细节，做成设置项而非硬编码。
  - **GMS / FOSS 双 flavor 分发**：同一个功能集按是否依赖闭源服务切成两版，新功能优先 GMS。
- **许可证与注意事项**：Easy Diary License（README 徽章标 GPL-3.0）+ 第三方许可（THIRDPARTY.md）。自述：FOSS 版无 Google Drive 备份、天气图标更简单；新功能优先 GMS 版，FOSS 版本会滞后。

---

## InlitX/streak

- **一句话定位**：极简、无广告、隐私优先的习惯追踪器——一次点击完成打卡，看着连续天数与统计慢慢填满。
- **平台与形态**：Android / Windows / Linux（iOS 进行中、macOS 计划中）；F-Droid、IzzyOnDroid、OpenAPK、GitHub Releases、Obtainium；Flutter 跨平台但平台覆盖不全，无 Web 版。
- **技术栈与本地存储**：Flutter / Dart；本地存储，格式 README 未提及；**永不联网**：Android 上连 INTERNET 权限都不申请，无服务器、无账号、无广告、无分析。
- **同步机制**：**无**。不与任何服务器通信；备份靠导出单文件自存，或每日/每周自动备份到自选目录。
- **核心功能清单**：
  - 追踪：主屏 / 小组件 / 通知一键打卡；三种习惯——普通、**避免型（含复吸记录）**、**计数型（自定义单位与每日目标）**；**清单式习惯**（全部勾选才算完成）；灵活计划（每天、每周或每月 X 次、指定星期、每 N 天）；**补打卡**（点任意一天补或删）；**Day notes**（长按某天写当天发生了什么，可附照片）；**假期模式**（暂停习惯而不破坏任何东西）。
  - 进度：GitHub 风格活动网格（周/月/全年）；月历（周起始可选周一/周六/周日）；每月完成次数；**连续天数演变曲线**；「你何时最稳定」（找出你实际出现的小时）；总计、最佳与当前连续、完成率、每习惯 **strength 评分**；可分享的进度卡片（多种尺寸，导出为图片）。
  - 专注：计时器（自由或绑定习惯及其目标）；番茄轮次 + 短休息，或一次长时段；三种钟面样式（Circle / Flip / Dots）；内置音效（雨、棕噪声、火）或自备音轨（顺序或随机）；背景场景或自有照片；计时中可勾子任务、保持屏幕常亮；每日专注目标 + 每次会话历史。
  - 个性化：Classic / Minimal / Express 三套完整设计；图标包或任意 emoji；自定义主色；亮暗主题 + 五种背景（纯色、渐变、圆点、OLED 真黑、自有照片）；封面照片、分类、拖拽排序、档案名与头像；三种启动器图标；全部完成当天放彩带庆祝。
  - 提醒与小组件：每习惯提醒（指定日期或每 N 天，附一句鼓励语）；通知内直接提供 **Done / Snooze / Add amount** 三个按钮；四个桌面小组件（习惯 / 今日 / 统计 / 活动网格）；每个小组件独立样式（颜色或照片、透明度、边框）；统计小组件可自选展示哪些指标；**小组件内直接打卡并保存**，无需打开 App；点活动网格直接跳进对应习惯。
  - 数据：从 Loop Habit Tracker、HabitKit、Habitica、HabitBull 导入（**含历史与连续天数**），或任意含 habit + date 的 CSV；单文件备份还原；每日/每周自动备份到自选目录；PIN 或指纹应用锁；归档习惯不丢任何历史；7 种语言。
- **值得借鉴的具体机制**：
  - **打卡入口三点触达**：主屏 + 小组件 + 通知按钮（Done / Snooze / Add amount），并在小组件内直接保存打卡，把「打开 App」这一摩擦拿掉。
  - **打卡类型分型**：普通 / 避免型（记复吸）/ 计数型（带单位与目标）/ 清单式（全部勾完才算），而不是只有 yes-no。
  - **「跳过不打断连续」的 skip 类型**（见 xpavle00/Habo）与 **假期模式**：显式提供「合法地中断」的出口。
  - **补打卡（点任意历史日补或删）**：承认现实，允许修正历史而不是逼用户在前一天补记。
  - **Day notes 绑到打卡格子**：长按日历某天写当天发生的事并附照片 —— 把日记直接挂在习惯时间轴上。
  - **强度评分替代纯连续数**：连续天数 + strength 双指标，配合连续演变曲线看趋势。
  - **「你何时最稳定」按时段统计**（不是按天），直接指向最佳提醒时间。
  - **迁移时带走连续天数**：导入其它 App 时连 streak 一起迁移，迁移不惩罚用户。
  - **小组件可配置指标**：统计小组件让用户选「今天最想看哪几个数」。
- **许可证与注意事项**：GNU GPLv3，附第 7(b) 条署名附加条款。README 自述：Linux 版刚落地、仍粗糙，**提醒只在 App 打开时响**；未上 Play 商店，需手动允许浏览器安装 APK。

---

## iSoron/uhabits

- **一句话定位**：Android 上的习惯养成应用，靠详细的图表与统计展示习惯随时间的改善。
- **平台与形态**：移动端（Android）独立应用，Google Play / F-Droid / Releases 页 APK；无 iOS 与桌面端。
- **技术栈与本地存储**：README 未提及具体语言与数据库实现（仅提及可导出 SQLite 数据库文件）。
- **同步机制**：**无**。完全离线工作，不需要网络连接或账号注册，数据不发送给任何人。
- **核心功能清单**：
  - 极简轻量界面，针对老手机优化速度。
  - **Habit score**：用于计算习惯强度的先进公式——每次重复让习惯更强，每漏一天让它变弱，但长连击后漏几天不会像别的 dont-break-the-chain 应用那样彻底摧毁进度。
  - 灵活计划：除每日习惯外，还支持每周三次、隔天等复杂计划。
  - 提醒：每个习惯可设自己的提醒时间与时刻，可直接在通知里打卡或忽略。
  - 小组件：解锁手机即看到习惯，彩色小组件可在主屏直接追踪。
  - 数据掌控：导出为表格（CSV）或数据库文件（SQLite）；高级用户可通过 Tasker 等外部应用添加 checkmark。
  - 无数量限制、无内购、无广告、不打扰的通知。
- **值得借鉴的具体机制**：
  - **习惯强度衰减公式**：完成加分、缺失减分，长连击后偶发漏几天不清零 —— 用「强度」而非「链条是否断裂」表达坚持成本，显式规避断链类应用的挫败设计。
  - **通知内直接 check / dismiss**：提醒通知本身就是操作面板，不要求进入 App。
  - **导出 SQLite 而非只有 CSV**：给高级用户可再分析的结构化出口。
  - **外部应用写入打卡标记**（Tasker 等）：把打卡变成可被自动化工具调用的接口。
  - **明确「无数量限制、全部功能对所有用户开放、无内购」**：把限制条款写进产品定位本身。
- **许可证与注意事项**：GPL v3（Copyright 2016-2025 Álinson Santos Xavier）。README 自述：从 Releases 页下载的 APK 不会自动更新。

---

## JerryZLiu/Dayflow

- **一句话定位**：Mac 上私密、自动的工作日志——理解你在 Mac 上做的事，把它变成清晰的一天时间线。
- **平台与形态**：**仅 macOS**（macOS 14+），需授予「屏幕与系统音频录制」权限；提供 dmg 与 Homebrew cask；Xcode 源码构建。
- **技术栈与本地存储**：Swift / Xcode（具体 UI 框架 README 未提及）；录屏以轻量「屏幕分块」形式存储，时间线与 app 数据库均在本机 `~/Library/Application Support/Dayflow/`。
- **同步机制**：**无**。local-first，无云同步；AI 分析可走本地模型（Ollama / LM Studio）或云（Gemini 自带 key、ChatGPT / Claude 的本地 CLI 工具）——选云端则分析所需活动数据会发给该提供方。
- **核心功能清单**：
  - 自动时间线：截取轻量屏幕分块 → 用所选 AI 提供方分析 → 生成活动卡片；无需计时器、无需手写笔记。
  - 上下文感知摘要：看的是屏幕上实际在做什么，而不是哪个 app 处于前台（Cursor / Chrome / YouTube / Slack 成为有意义的工作上下文）。
  - 每日站会：GitHub 风格活动网格 + 昨日亮点 + 今日优先项 + 阻塞项，站在会前把汇报写好。
  - 周回顾：一周一览——何时专注、时间去向、哪些 app 占主导、什么把人拉走。
  - 与工作日志对话：对当天/本周/本年提问，答案基于时间线。
  - 分心追踪：识别分心时段并与专注工作并排展示，无需手工标注每次休息。
  - 时间线导出为 Markdown（任意日期区间）。
  - 本地优先存储与自动清理：可配存储上限，自动清除旧录制。
- **值得借鉴的具体机制**：
  - **「屏幕分块 + AI 归类成活动卡片」的自动时间线**：用模型把原始活动流抽象为语义卡片，避免用户手工记流水账。
  - **每日站会视图结构**：昨日亮点 + 今日优先 + 阻塞项 + GitHub 式活动网格，把「复盘」压缩成开会前 2 分钟可交付的格式。
  - **分心时段与专注时段并排对比**：不要求用户预先给行为打标，事后自动区分「漂移」与「专注」。
  - **AI 提供方可切换（本地 / 云）**：把隐私与质量/成本的权衡做成用户可见的开关，而不是硬绑定。
  - **录制文件的自动清理策略**：给「持续采集」配上存储上限，避免隐私记录无上限堆积。
- **许可证与注意事项**：MIT。要求 macOS 14+ 与录屏权限；若选择云端模型提供商，分析所需的活动数据会发送给该提供方。

---

## journiv/journiv-app

- **一句话定位**：自托管的私密日记 Web 应用，用「提示词式写作 + 心情追踪 + 媒体上传 + 分析搜索」降低长期记录的门槛。
- **平台与形态**：Web 应用（FastAPI 后端 + React 前端）；旧版 Flutter 客户端保留在 `/legacy/` 路径；Docker 镜像 `swalabtech/journiv-app:latest`，暴露端口 8000。
- **技术栈与本地存储**：FastAPI（Python）+ React；**最小模式（minimal mode）需 Redis/Valkey + Celery worker 才能处理媒体**；具体数据库类型与文件存储布局 README 未提及。
- **同步机制**：自托管单实例，多端通过访问同一服务同步；README 未提及端到端加密，也未提及离线优先写入。
- **核心功能清单**：心情追踪；提示词式日记；媒体上传；数据分析；高级搜索；Docker 部署。
- **值得借鉴的具体机制**：
  - **提示词式日记（用引导问题替代空白页）**：把「今天写什么」的决策成本转成一道可回答的问题，是降低启动摩擦的直接手段。
  - **重任务与核心功能解耦**：媒体处理依赖 Redis/Valkey + Celery 队列，并以「最小模式」明确写出降级边界，部署者可以按需扩容。
  - **在 README 顶部直接标注 beta 与破坏性变更**：自托管项目主动声明稳定性预期，避免用户按正式版预期使用。
  - **旧客户端不删、留在 `/legacy/` 路径**：迁移期同时保留新旧入口。
- **许可证与注意事项**：README 只指向 LICENSE 文件、**未指明具体许可**。项目处于 beta，可能有破坏性变更；需定期备份；README 声明为 AI 辅助开发。

---

## laurent22/joplin

- **一句话定位**：免费开源的笔记与待办应用，能管理大量笔记本中的笔记，可搜索、可复制、可打标签，笔记为 Markdown 格式。
- **平台与形态**：Windows / Linux / macOS / Android / iOS 全部覆盖；另有 Firefox 与 Chrome 的 Web Clipper 扩展。
- **技术栈与本地存储**：README 未提及具体语言与数据库（仅提到数据始终在本地手机/电脑上，offline first）。
- **同步机制**：**端到端加密**同步，可选多种云服务：Nextcloud、Dropbox、OneDrive、Joplin Cloud。
- **核心功能清单**：
  - 笔记：按笔记本组织大量笔记；可搜索、可复制、可打标签、可修改，可直接从 App 或用外部文本编辑器编辑；Markdown 格式。
  - 导入：Evernote 导出可导入，含格式化内容（转换为 Markdown）、资源（图片、附件等）与完整元数据（地理位置、更新时间、创建时间等）；也可导入纯 Markdown 文件。
  - Offline first：数据始终在手机或电脑上，有无网络都可访问。
  - E2EE 同步：可安全同步到多种云服务。
  - 全平台全文搜索。
  - 插件与主题扩展（也可自建）。
  - Web Clipper：从浏览器保存网页与截图。
- **值得借鉴的具体机制**：
  - **「offline first」的产品定义写进简介**：数据永远先落在本机，网络只是可选的同步通道。
  - **E2EE + 多同步后端并存**：同一份 E2EE 数据可落在 Nextcloud / Dropbox / OneDrive / 自建云，用户不被单一厂商绑定。
  - **迁移保真度设计**：从 Evernote 导入时保留地理位置、创建/更新时间等元数据并把富文本转 Markdown，而不只是抓正文。
  - **Web Clipper 输出 Markdown 并保留来源链接**：剪藏结果仍是一等公民的 Markdown 笔记。
  - **插件 + 主题双扩展口子**：功能增强与外观增强分成两条独立扩展路径。
- **许可证与注意事项**：**README 未提及 license**（README 内无 License 段落）。README 未列出已知问题。

---

## logseq/logseq

- **一句话定位**：隐私优先的开源知识管理与协作平台，强调隐私、长久与用户控制。
- **平台与形态**：桌面端（Linux 有自动化安装脚本）、Web 版（app.logseq.com）、移动 App（DB 版新 iOS App 为 alpha，Android 即将）；另提供 Logseq CLI（Node）。
- **技术栈与本地存储**：Clojure / ClojureScript + DataScript（不可变数据库 + Datalog 查询引擎）+ OCaml / Angstrom 的文档解析器 mldoc + isomorphic-git；**文件级 Markdown / Org-mode**（DB 版引入 DB graphs，并提到需定期做 SQLite DB 备份）。
- **同步机制**：DB 版引入新同步方式 **RTC（Real Time Collaboration）**，用于多设备同步 graph 或与他人协作；README 建议开启自动备份或定期 SQLite 备份（DB 版为 beta，移动 App 与 RTC 为 alpha）。
- **核心功能清单**：
  - 内容块：块级引用与双向链接、自定义属性、SQL 查询嵌入、协议（Protocol）支持。
  - 编辑器：块式、Markdown WYSIWYG、大纲列表、块级 zoom-in、百万字级大文档编辑、数学公式/图表/流程图/甘特图/时序图/五线谱、Web 剪藏、PDF 标注链接。
  - 导出：块引用与嵌入、带资源的标准 Markdown、PDF / Word / HTML、复制到微信公众号 / 知乎 / 语雀。
  - 数据库：表格视图（Table view）。
  - 卡片盒间隔重复（Flashcard spaced repetition）。
  - AI 写作与问答（经 OpenAI API）。
  - Tesseract OCR；多标签页与拖拽分屏；模板片段；JavaScript/CSS 片段。
  - Android / iOS / HarmonyOS App；Docker 部署；API；社区市场；插件 API；主题生态。
  - CLI：内置命令行直接操作工作区数据，无需运行服务端；含 `notebook/document/dailynote`（含每日笔记 CRUD）、`block/attr/outline`、`tag/bookmark/template`、`search`（全文/语义/资源内容/SQL）、`ref`（反链与提及）、`export/import/inbox`、`repo/history/sync`（快照、版本、云同步）、`asset/file`、`database`、`serve`、`workspace/system`；输出支持 `-f json` 与 `--dry-run` 预览。
- **值得借鉴的具体机制**：
  - **块级引用 + 双向链接 + 自定义属性 + SQL 查询嵌入**：把日记从纯文本变成可被查询的结构化库。
  - **CLI 里给「每日笔记」一等公民命令**（`dailynote` CRUD）+ `repo/history/sync` 三件套（快照 / 版本 / 同步）分开暴露。
  - **CLI 全命令支持 `--dry-run` 与 JSON 输出**：让脚本化操作可预览、可集成。
  - **DB 版明确的风险提示与备份建议**：beta 阶段主动告知「可能丢数据」，并给出自动备份 / 定期 SQLite 备份两条路径，建议先建测试 graph。
  - **插件 API + 主题市场作为扩展主渠道**：核心保持小而稳，扩展交给社区。
- **许可证与注意事项**：README 未指明具体许可（徽章指向仓库 LICENSE.md，README 未提及具体条款）。自述：DB 版为 beta、新移动 App 与 RTC 为 alpha，**可能丢数据**；更新频率上 `test/db` 分支稳定但更新慢、`master` 分支更新快但 bug 多。

---

## lunatask/lunatask

- **一句话定位**：Lunatask 的发布仓库，一个把待办、习惯、日记、生活追踪与笔记合一的加密应用。
- **平台与形态**：README 未提及（仓库只放 Lunatask 的发布版本，细节指向 lunatask.app）。
- **技术栈与本地存储**：README 未提及；README 定位描述为「all-in-one encrypted to-do list, habit tracker, journaling, life-tracking and notes app」，即整体宣称加密。
- **同步机制**：README 未提及（除「encrypted」字样外无同步说明）。
- **核心功能清单**：待办；习惯追踪；日记；生活追踪（life-tracking）；笔记——五类合一。
- **值得借鉴的具体机制**：
  - **五合一的信息架构**：把待办 / 习惯 / 日记 / 生活追踪 / 笔记收进同一产品与同一套数据模型，直接减少跨 App 切换成本（README 中唯一可借鉴的机制，其余信息不足）。
- **许可证与注意事项**：README 未提及。

---

## memex-lab/memex

- **一句话定位**：iOS / Android 上的 local-first AI 日记，用碎片化捕获 + 多智能体流水线，把随手记录自动升维为时间线卡片、PARA 知识库与长期记忆。
- **平台与形态**：iOS 与 Android（Flutter）；README 未提及桌面端或 Web 版。
- **技术栈与本地存储**：Flutter ≥3.6；Drift / SQLite；Provider + MVVM 架构；智能体运行时 `dart_agent_core`；数据全部留在本地（filesystem + SQLite）。
- **同步机制**：README 未提及同步机制；LLM 提供方由用户自选（Gemini / OpenAI / Claude / DeepSeek / Ollama 等），**Memex AI 仅作代理、不存储内容**。
- **核心功能清单**：
  - 碎片化捕获：文本、照片、语音。
  - 多智能体自动整理：碎片 → 时间线卡片 → PARA 知识库 → 洞察卡片。
  - AI 角色陪伴与长期记忆。
  - 自定义 Agent：事件触发、`SKILL.md` 描述、独立模型、独立工作目录、JS 执行、依赖链、同步/异步、重试。
  - 最终沉淀为 Markdown 文件，可一键导出。
- **值得借鉴的具体机制**：
  - **「捕获 → 自动整理」的多智能体流水线**：把记录行为拆成低摩擦捕获与高价值整理两段，整理结果不是原始流水账，而是时间线卡片、PARA 知识库与洞察卡片。
  - **自定义 Agent 用 `SKILL.md` + 事件触发 + 依赖链描述**：让 Agent 能力可版本化、可编排、可重试，而不只是写死在应用里的一段 Prompt。
  - **AI 产出最终落为 Markdown 文件**：不把整理结果锁死在数据库，随时可迁移、可版本管理、可被其它工具消费。
  - **多提供方可配 + 平台方仅代理不存储**：在享受 AI 便利的同时不交出数据控制权。
- **许可证与注意事项**：GPL-3.0。

---

## mhss1/MyBrain

- **一句话定位**：Android 上一体化生产力应用兼 AI 助手，把任务、笔记、日历、日记与书签装在一个本地应用里。
- **平台与形态**：移动端（Android）为主，Kotlin Multiplatform「当前以 Android 为目标」；通过 Obtainium / GitHub Releases 安装；F-Droid 版本已停止分发。
- **技术栈与本地存储**：Kotlin Multiplatform + Compose Multiplatform (Material 3) + Jetpack Glance（桌面小组件）+ Room DB + Preferences DataStore + Jetpack Paging + Koin + WorkManager + Alarm Manager + Content Provider + 生物识别 + Clean Architecture + MVI；AI 用 Koog 与 Google ML Kit GenAI（端侧 AI）；加密用 AES-GCM，同步负载用 Zstandard，配对用 ZXing 二维码。
- **同步机制**：**同一局域网内的加密本地设备同步**（任务、笔记、日记、书签与 AI 对话）：Android NSD 发现设备 + 二维码配对 + Ktor Server(CIO) 提供本地同步端点 + WebSocket 实时同步 + AES-GCM 加密传输 + Zstandard 压缩；无云账号。
- **核心功能清单**：
  - 本地与隐私：不收集任何数据，注重性能与内存效率。
  - 任务：优先级、子任务、截止日期与提醒。
  - 笔记：支持 Markdown，可用标题、列表、链接。
  - 心情：每日记录心情，用图表查看心情摘要。
  - 书签：从任意其他 App 的分享菜单保存稍后再看。
  - 日历：现代列表视图与月视图，配备漂亮的桌面小组件。
  - Dashboard：任务、日历事件等汇总，一眼看到当天。
  - AI 助手与 Agent：可对话并附加对象，可让 AI 创建与查找条目。
  - 局域网加密同步（见上）。
- **值得借鉴的具体机制**：
  - **局域网 P2P 加密同步**（NSD 发现 + 二维码配对 + WebSocket 实时 + AES-GCM + Zstd）：完全绕开云账号体系实现多端一致，压缩同步负载。
  - **AI 是执行者而非问答框**：可以让 AI 直接创建/查找任务与笔记条目。
  - **分享菜单 → 书签**：把「捕获」入口放在系统分享面板里，而不是要求打开 App。
  - **Dashboard 一屏汇总 + Glance 桌面小组件**：当日任务与日程在锁屏/桌面可见。
  - **停分发时的数据迁移指引**：F-Droid 下架公告里直接写「先导出数据，再从 GitHub Releases 安装并导入」。
- **许可证与注意事项**：GPL-3.0。README 自述：因后续版本将引入原生依赖、可能使用 Google ML Kit 等与 F-Droid 政策不兼容的专有组件，**MyBrain 将在 F-Droid 停止分发**。

---

## onejgordon/flow-dashboard

- **一句话定位**：习惯追踪 + 个人数据分析应用，把每日问卷式日志、习惯、任务、目标与项目统一到一个面板上（**项目已停止维护**）。
- **平台与形态**：Web 服务端多租户应用（flowdash.co），部署在 Google App Engine；集成 Google Assistant / Google Home 与 Facebook Messenger 作为交互入口。
- **技术栈与本地存储**：Python 2.7 后端（README 明确提示已弃用）+ Node v11.15.0 / gulp 前端；Google Cloud Datastore（用 GQL 查询删除用户数据）；可选把每日面板数据推送到 BigQuery 做额外分析。
- **同步机制**：README 未提及。
- **核心功能清单**：
  - 每日日志 / 问卷：可配置问题；可选位置拾取与地图；从配置好的开放式回答中抽取 @mention 与 #tag（自动建议）；按 tag 对日志做分段分析（高亮有/无该 tag 的日子并显示均值）。
  - 习惯追踪：支持每周目标；承诺（commitments）；可数型习惯可选每日目标。
  - 每日重点任务：追踪每天的 top tasks，并分析任务完成情况——准时 / 迟到 / 未完成。
  - 月度 / 年度 / 长期目标：目标在月末有评估报告；每个目标每月可定义评分。
  - 进行中的项目追踪：记录每次进展增量所花时间；任务与项目关联；定义带标签的里程碑；查看完成进度的 **burn-up 图**。
  - 分析：所有上报数据的汇总图表。
  - 语音 / 对话集成（Google Actions、Messenger）：「我做得怎么样」「我这个月的目标是什么」「把 run 标记完成」「每日报告」。
  - 阅读小组件：当前在读的文章/书籍；同步 Evernote / Kindle 的引用；同步 Pocket 的文章；收藏与笔记；引用与文章全可检索。
  - 闪卡小组件：表格访问（如随机引用、摘录）。
  - 导出全部数据为 CSV。
  - 数据源集成：公开 GitHub 提交、Google Fit、Evernote、Pocket、Goodreads、任意 REST API。
- **值得借鉴的具体机制**：
  - **每日问卷式日记**：问题可配置，位置可拾取，从开放式回答里自动抽 @/# 标签并按标签分段统计 —— 把自由文本变成可聚合的数据。
  - **任务完成度的三态分析**：准时 / 迟到 / 未完成，而不是二元的完成与未完成。
  - **项目 burn-up 图 + 带标签的里程碑 + 进展增量耗时**：把项目进度拆到可度量粒度。
  - **月度自评机制**：每个目标每月打分 + 月末生成目标评估报告，形成周期性复盘闭环。
  - **对话式关键动作入口**：「把 run 标记完成」这类语音/聊天动作直接落到打卡上。
  - **把「在读的书/文章」也纳入每日面板**：阅读追踪与习惯打卡同构，共用同一套面板与评分。
  - **BigQuery 外送面板数据做二次分析**：默认数据自留，同时留出可分析出口。
- **许可证与注意事项**：MIT。README 自述：**项目已停止维护（UNMAINTAINED）**，正在关闭新账号注册，并建议用户导出数据以保未来访问；依赖已弃用的 Python 2.7 与 GAE；自建实例需自行配置各集成密钥；API 文档仍在完善中。

---

## theachoem/storypad

- **一句话定位**：隐私优先的开源日记应用，为看重简洁、极简与数据掌控的用户设计。
- **平台与形态**：移动端（Android / iOS）与桌面端（macOS）Flutter 应用，另有专门的平板 UI（iPad 与安卓平板）；Google Play / App Store；20+ 语言。
- **技术栈与本地存储**：Flutter 3.29.0 + Provider（状态分三级：全局 ProviderScope / 视图 ChangeNotifierProvider / 控件 StatefulWidget）+ MVVM 分层（Model、View、ViewContent、ViewModel）+ **ObjectBox** 本地数据库（强调检索性能与可扩展性）；Java 21（Android）、Ruby 3.3.5（iOS）。
- **同步机制**：**私有 Google Drive 同步** + 离线本地导出；Pro 版提供自动备份。
- **核心功能清单**：
  - 时间线写作：内容自然流动，没有文件夹也没有标签页。
  - 专门平板 UI。
  - 完全可自定义写作：粗体、列表、复选框、颜色，1300+ Google 字体。
  - **Throwback memories**：看到自己多年前这一天写了什么。
  - 照片记忆：每页可加多张照片并自定义布局。
  - 心情追踪：45+ 种情绪，带历史与日历视图。
  - 多页条目：适合写小说、提示词或每日笔记。
  - 标签、星标与搜索。
  - 隐私优先：PIN、FaceID、指纹锁，数据留在设备上。
  - 备份与同步：私有 Google Drive 同步 + 离线本地导出。
  - 主题：20+ 配色主题、深浅色、字体与布局。
  - 导出与分享：文本、Markdown，或含附件（图片、音频等）的完整备份。
  - StoryPad Pro（一次性购买）：自定义背景、自建每日写作模板、放松白噪音、经期日历（并可据此创建相关日记条目）、语音日记、Markdown 导出（兼容 Obsidian、Notion 等）、写作统计（字数与字符数）、置顶笔记（重要条目置顶到时间线顶部）、自动备份。
- **值得借鉴的具体机制**：
  - **「N 年前今日」回顾机制（throwback）**：按同月同日回访旧条目，把沉睡内容重新推回眼前。
  - **情绪细分到 45+ 并配历史与日历视图**：心情不只是打分，而是可回溯的情绪序列。
  - **多页条目**：一条日记可以分页，适配长文与提示词这类结构化内容。
  - **置顶机制**：把纯流水的时间线变成「可操控的流」，重要内容不必靠滚动找回。
  - **每日写作模板（Pro）**：把「今天怎么写」固化成用户可自定义的模板，兼顾效率与个性化。
  - **一次性买断 Pro 而非订阅**：与「永久免费」路线并列的一种商业模式选项。
- **许可证与注意事项**：GPL-3.0，作者明确说明选 GPL 是为保证衍生修改也保持开源。部分能力在 Pro（一次性付费）内。

---

## xpavle00/Habo

- **一句话定位**：Android 与 iOS 上的快速极简习惯追踪器，无需账号、无数据收集，只做干净专注的习惯养成工具。
- **平台与形态**：移动端独立应用（Android + iOS），Google Play / App Store / IzzyOnDroid 分发；Flutter 3.x 跨平台；无桌面端与 Web 版。
- **技术栈与本地存储**：Flutter / Dart；本地存储，格式 README 未提及；**离线优先**，无需网络即可完整使用。
- **同步机制**：**Habo Sync —— 端到端加密、零知识架构**：数据在设备上用主密码加密后才上传，服务器只看到密文（README 称即使想读也读不到）；加密密钥由设备生成；**可自托管**（跑自己的 Supabase 后端，全部同步功能免费提供，不限订阅）；另有自动加密备份（换手机不丢历史）。
- **核心功能清单**：
  - 多种完成类型：yes/no、数值型、**skip（跳过不打断连续天数）**。
  - 备注与评论：每次打卡可附上下文说明。
  - 智能提醒：在恰当时间的温和提醒。
  - 日历视图：在月网格上同时看连续天数与打卡情况。
  - 统计：连续天数、趋势、随时间的完成次数。
  - 个性化：深色 / 浅色 / OLED 主题、Android Material You、自定义按钮颜色、拖拽排序的习惯、**按主题分组的分类**。
  - 隐私与掌控：离线优先、生物识别锁（Face ID / Touch ID / 密码）、导出与备份、**归档（暂停习惯而不丢历史）**、URL scheme 深链（可从 Shortcuts 等应用跳进 Habo）。
  - 开源可审计可 fork（GPL-3.0）。
- **值得借鉴的具体机制**：
  - **skip 类型：合法的「不打断连续」出口**——允许打卡记录里存在「跳过」而不计入中断，与 InlitX/streak 的假期模式属同一类设计。
  - **零知识 E2EE + 可自托管同步**：服务器只见密文，自托管走 Supabase 免费额度且功能不缩水，把「不信任云厂商」落成可执行配置。
  - **归档（暂停而非删除）**：暂停一个习惯时保留其历史连续数据。
  - **URL scheme 深链**：让 Shortcuts 等外部应用直接跳进打卡流程。
  - **备注与评论随打卡记录**：每次打卡可带一句上下文，把行为记录升级为可复盘的事件。
  - **按主题分组的分类 + 拖拽排序**：长列表的组织能力。
- **许可证与注意事项**：GNU General Public License v3.0。自述：Habo 4.0 起才引入跨设备同步与 E2EE；自托管需 Supabase 账号与 Node.js（通过 npx 使用 Supabase CLI）；README 未列出已知缺陷。

---

## tridiontech/journal

- **一句话定位**：README 未获取（目录中 `tridiontech__journal.md` 的内容实为 `Achuan-2/siyuan-plugin-task-note-management` 的 README）。
- **平台与形态**：README 未提及。
- **技术栈与本地存储**：README 未提及。
- **同步机制**：README 未提及。
- **核心功能清单**：README 未提及。
- **值得借鉴的具体机制**：README 未提及。
- **许可证与注意事项**：README 未提及。

---

## UdaraJay/Pile

- **一句话定位**：桌面端的反思型日记应用，卖点是简单、数据留在本地，再用 AI 增强写作体验。
- **平台与形态**：桌面端独立应用，macOS（.zip / .dmg 拖入 Applications）与 Windows（.exe 安装）；基于 Electron + React（electron-react-boilerplate）。
- **技术栈与本地存储**：Electron / React；本地存储，具体文件格式 README 未提及；AI 走 OpenAI GPT API 或本地 Ollama 模型。
- **同步机制**：README 未提及（README 强调「keeping your data local」）。
- **核心功能清单**：
  - 多本日记：首次使用可创建一个「New Pile」。
  - AI Reflections：需 OpenAI API 访问权限或 Ollama 本地 AI；填入 API key 后可用。
  - 对任一已写条目点击「reflect」，生成 AI 洞察与想法，以**线程回复**形式出现在该条目下。
  - 窗口右上角的 reflect 图标：搜索或对整本日记提问。
  - 设置面板中填写 API key。
- **值得借鉴的具体机制**：
  - **「Reflect on entry」**：AI 输出附着在原条目线程里，而不是另开一篇 AI 文档，保留上下文锚点。
  - **全局 reflect 入口对整本日记提问**：把「回忆我写过什么」变成对话式检索。
  - **一本日记 = 一个 Pile**：可建多本，天然分册。
  - **AI 成本防护提示**：README 主动建议在 OpenAI 控制台设置消费上限，避免意外花费。
- **许可证与注意事项**：MIT，但**品牌名与品牌资产不在 MIT 授权范围内**。自述为实验性项目，改动与新功能由作者自行决定是否合并。

---

## usememos/memos

- **一句话定位**：开源自托管的日常随记应用，把零散想法汇聚成一条个人时间线，数据归你自己。
- **平台与形态**：Web 服务端（Docker / Docker Compose / Kubernetes / 单二进制），默认端口 5230；桌面端与移动端 README 未提及；另提供 Web Clipper 浏览器扩展与 Telegram 机器人。
- **技术栈与本地存储**：README 未提及具体语言与数据库；数据全部集中在 `~/.memos` 一个目录，备份这一个文件夹即可。
- **同步机制**：README 未提及跨设备同步（数据在自托管服务器上）。
- **核心功能清单**：
  - 日常写作：一句话即可成一条 memo，也可以慢慢写长内容，用 Markdown 组织结构。
  - 个人时间线：每条 memo 保留写下它的那一天，把想法汇总成可回看的时间线；标签跨天连接相关想法，便于重拾某个话题或找回记忆。
  - 自己的数据：记录存在你自己的服务器上。
  - 分享由你控制：哪些私有、哪些分享给家人朋友、哪些公开发布到 web。
  - 共享空间：可以与他人共写，但每个人保留自己的 memos。
  - Web Clipper（Chrome / Firefox）：把页面、选区与图片存为 Markdown，并带源链接。
  - Memogram：Telegram 机器人，把消息与图片存进 Memos。
  - API 与 MCP server：接入自建脚本与 AI 工具。
  - 版本策略：发布号 YY.MM.N、rc.K；Docker 标签 stable / 月份标签（如 26.10）/ canary。
- **值得借鉴的具体机制**：
  - **时间线 + 标签双轴**：默认按时间自然排列（不需要用户组织），标签负责跨天主题串联 —— 低维护成本的检索结构。
  - **可见性三级**：私有 / 分享给特定人 / 公开到 web，逐条可控。
  - **共享空间里的「各人保留自己的 memos」隔离规则**：多人共处一个空间但内容不互相污染。
  - **MCP server 暴露给 AI 工具**：让 AI 直接读写自己的时间线。
  - **剪藏即 Markdown + 保留源链接**：剪藏结果与手写笔记格式统一。
  - **备份承诺收敛到一个目录**：明确「所有数据都在这一个文件夹」，备份心智成本最低。
- **许可证与注意事项**：MIT。README 自述：来自 v0.31.0 之前的版本需先运行一次 v0.31.0 再升级（`store/migration`）。

---

## Yu-Core/SwashbucklerDiary

- **一句话定位**：开源、跨平台的本地日记应用，「不是所有日记都叫流水账」。
- **平台与形态**：Windows（10 1809+ / 11）、Android（8.0+）、macOS（12+）、Web、Linux 跨平台；**iOS 已划掉**（虚拟机可跑、物理机未经测试）；Microsoft 应用商店 + GitHub Releases + 123 云盘 / 中国移动云盘 / 百度手机助手 / 豌豆荚 / 酷安 / 应用宝 / 华为应用市场等国内渠道；GitHub Pages 提供在线预览。
- **技术栈与本地存储**：.NET 10 + **Blazor Hybrid / Blazor Server / Blazor WebAssembly** + .NET MAUI + Masa Blazor + Gir.Core + **Vditor**（Markdown 编辑器）+ SqlSugar（ORM）+ Serilog（Serilog.Sinks.SQLite）+ Microsoft.Data.Sqlite；数据全部本地存储，无需联网。
- **同步机制**：**WebDAV 备份** + **同一局域网下的同步传输**（不走云端账号）；无自建服务端要求。
- **核心功能清单**：
  - 极简风格 UI；多尺寸响应式布局。
  - Markdown 即时渲染。
  - 隐私模式（守护私密日记）。
  - 支持图片、音频、视频。
  - 支持数学公式、脑图、图表、流程图、甘特图、时序图、五线谱。
  - 标签分类展示；深色模式；多语言（12 种，含简繁中文）。
  - 天气、心情、位置记录。
  - 导出多种格式文件；支持文字与图片分享。
  - WebDAV 备份；局域网内同步传输。
- **值得借鉴的具体机制**：
  - **Markdown 即时渲染 + 一体化图表语法**：脑图 / 甘特图 / 流程图 / 时序图 / 五线谱与正文同源，记录时就能把结构画出来，而不是事后补图。
  - **「所有数据存储本地，无需联网」作为显式产品承诺**，并在功能列表里前置。
  - **隐私模式**：把「遮住私密条目」做成独立模式，而不是只靠应用锁。
  - **局域网同步传输**：多端一致性用局域网直连完成，不依赖第三方云。
  - **天气 + 心情 + 位置三元组随条目记录**：每条日记自带环境与状态上下文。
- **许可证与注意事项**：README 未见 License 段落（**README 未提及**）。自述：iOS 不支持（物理机未测试）；Windows 要求 10 1809/1909 以上版本（开发环境部分写 1909）。

---

## ZhuJHua/moodiary

- **一句话定位**：以 Flutter 实现的日记本，围绕图文影音记录、天气与地点、心情，并提供 WebDAV/S3 备份同步与 AI 助手。
- **平台与形态**：移动端 + 桌面端（Flutter 3.47.8 跨平台，提供 Releases 安装包；README 未逐一列出各平台名称），另有独立文档站与论坛。
- **技术栈与本地存储**：Flutter；本地存储，具体数据库/文件格式 README 未提及；**离线开箱即用**（README：The app works offline out of the box）。
- **同步机制**：**WebDAV 与 S3 / MinIO 同步** + **局域网传输** + **可选端到端加密**（backup and sync 三件套）。
- **核心功能清单**：
  - 富文本：可插入图片、音频与视频。
  - 搜索与分类：全文搜索 + 按分类筛选。
  - 主题与字体：浅色/深色模式、多种配色、可导入字体（含可变字体）。
  - 应用锁：密码 + 生物识别解锁。
  - 导出、导入与分享：导出 Markdown、Word、PDF 或长图；导入 Markdown zip 或本地备份。
  - 备份与同步：WebDAV、S3 / MinIO 同步、局域网传输、可选 E2EE。
  - 天气与地点：选择或抓取天气，保存地点并可在条目中引用，在地图上查看足迹。
  - AI 助手：接入 OpenAI 或 Anthropic 兼容服务，支持对话与日记工具。
- **值得借鉴的具体机制**：
  - **「地点足迹」地图**：日记与地理位置绑定并可视化，形成一条可回看的轨迹。
  - **分类过滤 + 全文搜索的组合检索**：分类先缩小范围，全文再定位。
  - **导出格式矩阵（Markdown / Word / PDF / 长图）+ Markdown zip 导入**：导出面向不同用途，导入能带附件。
  - **同步后端三选（WebDAV / S3 / MinIO）+ 局域网传输 + 可选 E2EE**：把「同步」拆成存储层、通道层与加密层三层分别可配。
  - **可变字体（variable font）导入**：跟随系统排版趋势，支持中文长文排版。
- **许可证与注意事项**：README 内未出现 License 段落（**README 未提及**，仅顶部有 license 徽章）。README 未列出已知缺陷。

---

## johannesjo/super-productivity

- **一句话定位**：专注个人工作的待办清单、时间追踪器与每日计划器，隐私优先、离线优先、开源。
- **平台与形态**：Linux / macOS / Windows / Android / iOS + 浏览器 Web App（**Web 版存在功能限制**，README 指向 Web App vs Desktop 对比页）；Flathub、Snap、Microsoft Store、Google Play、F-Droid、Obtainium、App Store；支持 Docker 运行。
- **技术栈与本地存储**：README 未直接给出框架与数据库（提供插件 API、REST API、同步服务器 REST API、自定义主题与 Docker 运行）。
- **同步机制**：**SuperSync**（自研同步服务，端到端加密，密码只由用户持有，**可自己托管**）+ **Dropbox** + **WebDAV**；另有基本 **CalDAV** 集成。
- **核心功能清单**：
  - 组织与聚焦：用子任务、项目、标签规划任务并按需着色。
  - 计划：**planner** 提前规划，**schedule** 时间线铺开一天，与日历事件并排显示。
  - 看板视图：内置 **Kanban** 与 **艾森豪威尔矩阵**，也可自建看板。
  - **Timeboxing** 与时间追踪；生成工时表，可导出到公司的工时系统。
  - 健康与专注：**休息提醒（break reminder）**；**反拖延功能（anti-procrastination）**；**Focus mode** 提供 Pomodoro、Flowtime 与倒计时三种会话；收集个人指标以判断哪种工作流程需要调整。
  - 外部集成：Jira、Trello、GitHub、GitLab、Gitea、OpenProject、Linear、ClickUp、Redmine、Nextcloud Deck、Azure DevOps —— 自动导入分配给你的任务、在本地规划细节、自动创建工作日志，**外部变更即时通知**。
  - 上下文附件：给任务和项目附加信息，创建笔记、附加文件，或创建含链接、文件甚至命令的**项目级书签**。
  - 隐私：不收集任何数据，无需账号注册，**数据存放位置由用户决定**。
  - 扩展：插件 API 与自定义主题。
  - 文档策略：官方 Wiki（仓库内 `docs/wiki` 在 CI 里 lint 后自动同步到 GitHub Wiki）之外还提供 DeepWiki 自动生成版本，并列出了自动文档的缺点。
- **值得借鉴的具体机制**：
  - **反拖延与休息提醒作为独立功能**：不只提供任务列表，还提供「该停下」「该开始」两种干预动作。
  - **三种专注会话模式并存**（Pomodoro / Flowtime / 倒计时）覆盖不同注意力形态。
  - **planner + schedule 与日历事件并排**：把「今日要做什么」和「什么时候有空」放在同一时间轴。
  - **艾森豪威尔矩阵与 Kanban 作为内置视图**：把优先级方法论做成一等视图，而不是让用户自己搭。
  - **外部 issue 变更即时通知**：把「事项被别人改动」变成事件推送，形成闭环回访。
  - **工时表导出到公司系统**：个人工具主动对接组织流程。
  - **项目级书签可存命令**：把可复用的上下文/命令沉淀在项目里。
  - **自研 E2EE 同步服务且可自托管**，同时保留 Dropbox / WebDAV 备选。
  - **文档在仓库内维护并由 CI 自动同步到 Wiki**：保证文档与代码同版本。
- **许可证与注意事项**：MIT。README 提示 Web 版有功能限制；列出 DeepWiki 自动文档的四点弊端（只讲代码不讲意图、必然滞后、只讲代码不讲概念、成本）。

---

## siyuan-note/siyuan

- **一句话定位**：隐私优先的个人知识管理系统，支持块级精细引用与 Markdown 所见即所得。
- **平台与形态**：桌面端（Microsoft Store / 安装包）、Web/自托管（Docker、Kubernetes、Unraid、TrueNAS）、移动端 Android / iOS / HarmonyOS App；内置 CLI。
- **技术栈与本地存储**：Go 内核 + Electron 桌面端（生态表：lute 编辑器引擎、chrome 剪藏扩展、bazaar 社区市场、dejavu 数据仓库、petal 插件 API、android/ios/harmony 客户端、riff 间隔重复）；数据存工作区目录：`assets`（附件）、`emojis`、`snippets`、`storage`（查询条件/布局/卡片）、`templates`、`widgets`、`plugins`、`public`，笔记本目录存放 `.sy` 文档（JSON），**加密笔记本存为密文**；工作区另含 SQLite 索引。
- **同步机制**：**不支持第三方同步盘**（README 明确：否则数据可能损坏）；支持连接第三方云存储（会员权限）；有「数据仓库（data repo）」机制保护快照与同步数据，多设备初始化一致时密钥相同，可在设置中复制密钥字符串；数据仓库密钥与加密笔记本主密码、密钥备份相互独立，密钥丢失后重置也无法恢复主密码。
- **核心功能清单**：
  - 内容块：块级引用与双向链接、自定义属性、SQL 查询嵌入、协议 `siyuan://`。
  - 编辑器：块式、Markdown 所见即所得、列表大纲、块级 zoom-in、百万字大文档编辑、数学公式/图表/流程图/甘特图/时序图/五线谱、Web 剪藏、PDF 标注链接。
  - 导出：块引用与嵌入、带资源的标准 Markdown、PDF / Word / HTML、复制到微信公众号 / 知乎 / 语雀。
  - 数据库：表格视图。
  - 卡片盒间隔重复；经 OpenAI API 的 AI 写作与问答；Tesseract OCR；多标签页与拖拽分屏；模板片段；JavaScript/CSS 片段；Docker 部署；API；社区市场；插件 API（petal）。
  - 内置 CLI：无需运行服务端即可直接操作工作区数据；含 `notebook/document/dailynote`（每日笔记 CRUD）、`block/attr/outline`、`tag/bookmark/template`、`search`（全文 / 语义 / 资源内容 / SQL）、`ref`（反链与提及）、`export/import/inbox`、`repo/history/sync`、`asset/file`、`database`、`serve`、`workspace/system`；支持 `-f json` 输出与 `--dry-run` 预览；不支持操作加密笔记本。
  - 付费：多数功能免费且可商用，部分功能（如连接第三方云存储同步）仅会员可用；Docker 支持 OIDC 取代锁屏密码作为访问认证。
- **值得借鉴的具体机制**：
  - **块级引用 + 自定义属性 + SQL 嵌入**：让日记条目可以被查询成表，而不只是文本。
  - **CLI 把每日笔记（`dailynote`）与快照/版本/同步（`repo`/`history`/`sync`）做成独立命令**：给自动化留出完整接口。
  - **明确禁止第三方同步盘并说明后果**（会损坏数据），只提供受控的云存储接入 —— 用「不支持」来保护数据完整性。
  - **数据仓库密钥与加密笔记本主密码解耦**，且在文档中写清「重置密钥 ≠ 找回主密码」的恢复流程。
  - **加密笔记本以密文形式落盘**，权限与存储层分离。
  - **OIDC 取代锁屏密码作为 Docker 访问认证**，并对 claim 规则做可配置化描述。
  - **工作区必须放在安装目录之外**（更新会清空安装目录）这类运维坑写进 FAQ。
- **许可证与注意事项**：AGPLv3。Docker 部署限制：**不支持桌面端与移动端客户端连接，只能浏览器使用**；不支持导出 PDF / HTML / Word；不支持导入 Markdown 文件。Kubernetes 部署限制：同一工作区只能有一个写入实例，升级有停机；备份必须整工作区（含 SQLite 索引），仅复制索引文件不足以恢复。FAQ 提示：升级前需保留工作区在安装目录之外。

---

## 跨项目功能模式汇总

> 每条注明出现在哪几个项目（用 owner/repo 简称）。标注「≥3 个」的是被多个项目重复采用、已被验证的机制。

### 1. 每日记录与时间线

- **时间线式日记流：内容按「写下的那一天」自动排列，不要求用户先分类**（≥3）：ZhuJHua/moodiary、usememos/memos、theachoem/storypad、hanjoongcho/aaf-easydiary、Demizo/Daily_You、Yu-Core/SwashbucklerDiary、onejgordon/flow-dashboard、JerryZLiu/Dayflow、journiv/journiv-app、memex-lab/memex
- **每日笔记作为独立一等对象并可命令行操作**：siyuan-note/siyuan（`dailynote` CRUD）、logseq/logseq
- **「今日」聚合页：任务 + 日程 + 待办一屏总览**（≥3）：mhss1/MyBrain、johannesjo/super-productivity、InlitX/streak、onejgordon/flow-dashboard、JerryZLiu/Dayflow
- **多年后同日回访旧条目（Throwback）**：theachoem/storypad
- **多页条目**：theachoem/storypad
- **每日问卷式日志（问题可配置）**：onejgordon/flow-dashboard
- **自动从屏幕活动生成时间线（无需手写）**：JerryZLiu/Dayflow
- **提示词式日记：用引导问题替代空白页，降低开始写作的成本**：journiv/journiv-app
- **碎片化捕获（文本/照片/语音）由多智能体自动整理成时间线卡片**：memex-lab/memex
- **「五合一」信息架构：待办 / 习惯 / 日记 / 生活追踪 / 笔记共用同一产品与数据模型**：lunatask/lunatask

### 2. 习惯与连续性

- **连续天数 / 习惯强度评分（不止一条链条）**（≥3）：InlitX/streak、iSoron/uhabits、FriesI23/mhabit、HabitRPG/habitica、Achuan-2/siyuan-plugin-task-note-management
- **强度随中断衰减而非归零**：iSoron/uhabits、FriesI23/mhabit
- **打卡类型分型：普通 / 避免型（含复吸）/ 计数型（带单位与目标）/ 清单式 / 跳过**（≥3）：InlitX/streak、xpavle00/Habo、FriesI23/mhabit、Achuan-2/siyuan-plugin-task-note-management
- **灵活计划：每周 X 次、指定星期、每 N 天**：InlitX/streak、iSoron/uhabits、xpavle00/Habo、onejgordon/flow-dashboard
- **合法中断出口：假期模式 / 归档 / 跳过不打断连续**（≥3）：InlitX/streak、xpavle00/Habo、onejgordon/flow-dashboard
- **补打卡（修正任意历史日）**：InlitX/streak
- **按星期几/时段分析「你何时最稳定」**：InlitX/streak、onejgordon/flow-dashboard
- **打卡目标可用「番茄时长」而非次数计量**：Achuan-2/siyuan-plugin-task-note-management
- **游戏化反馈回路（等级 / HP / 金币 / 装备）**：HabitRPG/habitica、InlitX/streak（完成彩带、岛屿等 gamification 页签）
- **导入其它 App 时连历史与连续天数一起迁移**（≥3）：InlitX/streak、FriesI23/mhabit、Demizo/Daily_You、laurent22/joplin
- **用「不做什么」写定位：主动排除一类用户需求（产品名即 "without Goals"）**：daya0576/beaverhabits
- **开放 API 让外部自动化直接写入打卡状态**：daya0576/beaverhabits
- **习惯与待办、日记、追踪合并在同一产品内，减少跨 App 切换**：lunatask/lunatask

### 3. 任务与项目

- **任务绑定到具体笔记块/文档，点标题跳转、悬浮预览**：Achuan-2/siyuan-plugin-task-note-management、siyuan-note/siyuan
- **项目 + 里程碑 + 子项目并行**：Achuan-2/siyuan-plugin-task-note-management、onejgordon/flow-dashboard、go-vikunja/vikunja
- **看板视图：Kanban / 艾森豪威尔矩阵内置**：johannesjo/super-productivity、Achuan-2/siyuan-plugin-task-note-management
- **任务寿命分态：进行中 / 短期 / 长期**，防任务堆积：Achuan-2/siyuan-plugin-task-note-management
- **任务完成度三态分析（准时 / 迟到 / 未完成）**：onejgordon/flow-dashboard
- **项目 burn-up 进度图**：onejgordon/flow-dashboard
- **时间线排期（planner + schedule）与日历事件并排**：johannesjo/super-productivity、Achuan-2/siyuan-plugin-task-note-management、mhss1/MyBrain
- **把「在读的书/文章」也纳入任务/习惯体系**：onejgordon/flow-dashboard
- **外部 issue 系统双向同步（自动导入 + 变更即时通知 + 自动写工作日志）**：johannesjo/super-productivity
- **待办与习惯、笔记、生活追踪合流到同一数据模型**：lunatask/lunatask

### 4. 复盘与回顾

- **每日站会视图：昨日亮点 + 今日优先 + 阻塞项**：JerryZLiu/Dayflow、onejgordon/flow-dashboard（每日报告）
- **周回顾：何时专注、时间去向、什么把人拉走**：JerryZLiu/Dayflow、InlitX/streak（专注历史）
- **月度自评：每月给目标打分 + 月末生成目标评估报告**：onejgordon/flow-dashboard
- **「想法—计划—执行—复盘」全链路串联**：Achuan-2/siyuan-plugin-task-note-management、logseq/logseq
- **分心时段与专注时段并排对比（自动识别，不需人工标注）**：JerryZLiu/Dayflow
- **写作量/记录量本身成为可统计指标**：hanjoongcho/aaf-easydiary、InlitX/streak
- **N 年前今日的回访机制**：theachoem/storypad
- **年度热力图 + 「那年今日」回访**：CikeSeven/jotsy
- **基于历史日记的分析面板与高级搜索**：journiv/journiv-app
- **自动生成洞察卡片 + 长期记忆 + AI 角色陪伴**：memex-lab/memex

### 5. 提醒与桌面集成

- **桌面小组件（习惯 / 今日 / 统计 / 活动网格）**（≥3）：InlitX/streak、iSoron/uhabits、FriesI23/mhabit、mhss1/MyBrain、HabitRPG/habitica
- **小组件内直接打卡 / 勾选，无需打开 App**：InlitX/streak、FriesI23/mhabit
- **通知内直接操作（Done / Snooze / Add amount / check / dismiss）**（≥3）：InlitX/streak、iSoron/uhabits、Achuan-2/siyuan-plugin-task-note-management、johannesjo/super-productivity
- **应用关闭仍能收到系统通知（移动端后台/内核级通知）**：Achuan-2/siyuan-plugin-task-note-management、mhss1/MyBrain
- **每条记录独立的提醒时间 + 重复周期 + 一个任务多个提醒**：iSoron/uhabits、InlitX/streak、xpavle00/Habo、Achuan-2/siyuan-plugin-task-note-management
- **提醒文案带鼓励语 / 随机时机提醒以降低对抗感**：InlitX/streak、Demizo/Daily_You、xpavle00/Habo
- **专注计时 + 番茄钟 / 休息提醒 / 反拖延干预**（≥3）：johannesjo/super-productivity、Achuan-2/siyuan-plugin-task-note-management、InlitX/streak
- **提醒计划可被其它工具订阅（CalDAV 桥）**：daya0576/beaverhabits、johannesjo/super-productivity、Achuan-2/siyuan-plugin-task-note-management
- **把「打卡」做成可编程接口（CalDAV 桥 / Home Assistant 开关 / Stream Deck 面板 / Apple 快捷指令）**：daya0576/beaverhabits

### 6. 统计与可视化

- **GitHub 风格活动网格**：InlitX/streak、JerryZLiu/Dayflow
- **习惯历史图表（曲线 / 柱状 / 完成率）**（≥3）：iSoron/uhabits、FriesI23/mhabit、InlitX/streak、hanjoongcho/aaf-easydiary、theachoem/storypad、mhss1/MyBrain
- **月历视图 / 月度完成次数统计**：InlitX/streak、xpavle00/Habo、hanjoongcho/aaf-easydiary、Achuan-2/siyuan-plugin-task-note-management、mhss1/MyBrain
- **日历同屏承载多类行为（任务 + 习惯 + 番茄钟）**：Achuan-2/siyuan-plugin-task-note-management、InlitX/streak、mhss1/MyBrain
- **按标签/分类对日志做分段统计**：onejgordon/flow-dashboard、ZhuJHua/moodiary
- **可分享的进度卡片（导出为图片）**：InlitX/streak、theachoem/storypad、hanjoongcho/aaf-easydiary（日记明信片）
- **写作字数/字符数统计**：theachoem/storypad
- **数据外送分析出口（BigQuery）**：onejgordon/flow-dashboard
- **年度活动热力图**：CikeSeven/jotsy
- **心情 emoji + 5 档精力 + 天气/地点作为条目级元数据可视化**：CikeSeven/jotsy
- **AI 分析面板与高级搜索**：journiv/journiv-app
- **PARA 知识库 + 洞察卡片两种结构化视图**：memex-lab/memex

### 7. 隐私与同步

- **离线优先 + 无账号 + 无遥测**（≥3，几乎全体）：InlitX/streak、iSoron/uhabits、ZhuJHua/moodiary、Yu-Core/SwashbucklerDiary、mhss1/MyBrain、theachoem/storypad、FriesI23/mhabit、Demizo/Daily_You、johannesjo/super-productivity、laurent22/joplin、xpavle00/Habo、CikeSeven/jotsy、memex-lab/memex
- **端到端加密同步 + 多后端可选**（≥3）：xpavle00/Habo、laurent22/joplin、johannesjo/super-productivity、ZhuJHua/moodiary、mhss1/MyBrain
- **WebDAV 作为自建/用户自有同步通道**（≥3）：FriesI23/mhabit、ZhuJHua/moodiary、Yu-Core/SwashbucklerDiary、johannesjo/super-productivity、CikeSeven/jotsy
- **局域网直连同步/传输（不经云）**（≥3）：mhss1/MyBrain（二维码配对 + NSD + WebSocket + AES-GCM）、Yu-Core/SwashbucklerDiary、ZhuJHua/moodiary
- **自建服务端可选（Docker / Supabase / 官方托管）**：daya0576/beaverhabits、xpavle00/Habo、usememos/memos、go-vikunja/vikunja、johannesjo/super-productivity、siyuan-note/siyuan、journiv/journiv-app
- **生物识别 / PIN 应用锁**：ZhuJHua/moodiary、theachoem/storypad、InlitX/streak、hanjoongcho/aaf-easydiary、mhss1/MyBrain、xpavle00/Habo
- **内容级隐私模式（仅遮蔽私密条目，不只是锁屏）**：Yu-Core/SwashbucklerDiary
- **数据存放位置由用户决定 / 可选外部存储**：ZhuJHua/moodiary、Demizo/Daily_You、johannesjo/super-productivity、laurent22/joplin
- **明令禁止第三方同步盘以防损坏**：siyuan-note/siyuan
- **录制/采集数据的自动清理与存储上限**：JerryZLiu/Dayflow
- **数据全部留在本机（filesystem + SQLite），LLM 提供方可自选、平台方仅代理不存储**：memex-lab/memex
- **无账号、无服务器，备份链路完全由用户自选**：CikeSeven/jotsy
- **备份文件自身加密（ZIP + AES-256），避免网盘侧泄露明文**：CikeSeven/jotsy
- **多网盘备份通道（WebDAV / S3 / Google Drive / OneDrive / Dropbox / 百度网盘 / 阿里云盘）**：CikeSeven/jotsy

### 8. 数据与导出

- **Markdown 作为存储或交换格式**（≥3）：laurent22/joplin、logseq/logseq、siyuan-note/siyuan、usememos/memos、ZhuJHua/moodiary、theachoem/storypad、Demizo/Daily_You、memex-lab/memex、CikeSeven/jotsy
- **多格式导出矩阵（Markdown / Word / PDF / HTML / 长图 / 纯文本）**（≥3）：ZhuJHua/moodiary、siyuan-note/siyuan、theachoem/storypad、Yu-Core/SwashbucklerDiary、onejgordon/flow-dashboard、laurent22/joplin、CikeSeven/jotsy
- **导出为可再分析的结构化数据（CSV / SQLite / JSON / BigQuery）**（≥3）：iSoron/uhabits、onejgordon/flow-dashboard、FriesI23/mhabit、InlitX/streak、CikeSeven/jotsy
- **导入导出对外部工具开放（API / MCP / CLI / REST）**（≥3）：usememos/memos、siyuan-note/siyuan、johannesjo/super-productivity、daya0576/beaverhabits、go-vikunja/vikunja、memex-lab/memex
- **整库备份收敛到单一目录/单文件**：usememos/memos、InlitX/streak、ZhuJHua/moodiary、CikeSeven/jotsy（ZIP 单文件）
- **从同类产品迁移并保留元数据（时间、地理位置、附件）**：laurent22/joplin、Demizo/Daily_You、InlitX/streak、FriesI23/mhabit、CikeSeven/jotsy
- **网页剪藏转 Markdown 并保留源链接**：usememos/memos、laurent22/joplin、siyuan-note/siyuan
- **AI 整理结果最终沉淀为 Markdown 文件，一键导出，不锁在数据库里**：memex-lab/memex
- **从 18 款同类应用导入（含 Evernote / Joplin / Memos）**：CikeSeven/jotsy

### 9. 输入效率与元数据

- **Markdown 即时渲染 + 富结构图表语法（脑图/甘特/流程/时序/五线谱）**（≥3）：Yu-Core/SwashbucklerDiary、siyuan-note/siyuan、theachoem/storypad、laurent22/joplin
- **心情 / 情绪作为独立元数据并可回溯**（≥3）：ZhuJHua/moodiary、theachoem/storypad、Demizo/Daily_You、mhss1/MyBrain、Yu-Core/SwashbucklerDiary、CikeSeven/jotsy、journiv/journiv-app
- **天气 + 心情 + 位置三元组随条目记录**（≥3）：Yu-Core/SwashbucklerDiary、ZhuJHua/moodiary、hanjoongcho/aaf-easydiary、onejgordon/flow-dashboard、CikeSeven/jotsy
- **地点足迹地图 / 位置拾取与地图**：ZhuJHua/moodiary、onejgordon/flow-dashboard、hanjoongcho/aaf-easydiary
- **语音输入与语音日记**：hanjoongcho/aaf-easydiary、theachoem/storypad、memex-lab/memex
- **分享菜单作为捕获入口（书签 / 剪藏）**：mhss1/MyBrain、usememos/memos、laurent22/joplin
- **对话式交互：AI 可直接创建/查找条目或执行打卡**（≥3）：UdaraJay/Pile、mhss1/MyBrain、ZhuJHua/moodiary、JerryZLiu/Dayflow、onejgordon/flow-dashboard
- **块级引用 + 双向链接 + 自定义属性 + SQL 嵌入**：siyuan-note/siyuan、logseq/logseq
- **标签 / 分类 / 星标 / 大纲多套组织手段并存**（≥3）：theachoem/storypad、usememos/memos、ZhuJHua/moodiary、laurent22/joplin、johannesjo/super-productivity
- **碎片化捕获（文本 / 照片 / 语音）降低单次记录门槛**：memex-lab/memex
- **提示词驱动的写作（引导问题替代空白页）**：journiv/journiv-app
- **农历、法定节假日、调休随条目记录**：CikeSeven/jotsy
- **日记模板变量占位 + 日记本多归属 / 章节 / 写作目标**：CikeSeven/jotsy

### 10. 扩展、部署与商业化

- **插件 / 主题 / 片段作为扩展主渠道**（≥3）：siyuan-note/siyuan、logseq/logseq、johannesjo/super-productivity、laurent22/joplin
- **Docker / Kubernetes / Unraid 一键部署路径**：siyuan-note/siyuan、usememos/memos、daya0576/beaverhabits、go-vikunja/vikunja、johannesjo/super-productivity、journiv/journiv-app
- **CLI 直接操作本地数据（无需服务端）+ JSON 输出 + dry-run**：siyuan-note/siyuan、logseq/logseq
- **免费本体 + 会员/Pro 增值，或一次性买断**：Achuan-2/siyuan-plugin-task-note-management、siyuan-note/siyuan、theachoem/storypad、Demizo/Daily_You、go-vikunja/vikunja
- **开源但拒绝 LLM 生成代码 / 暂停社区 PR**：HabitRPG/habitica
- **多语言与社区翻译流程（Weblate / Crowdin / 贡献者平台）**（≥3）：FriesI23/mhabit、InlitX/streak、Yu-Core/SwashbucklerDiary、theachoem/storypad、mhss1/MyBrain、habitica
- **Docker / Unraid / Easypanel 社区模板一键部署**：daya0576/beaverhabits
- **容器以 nobody 用户启动以兼容 OpenShift，并写明宿主 UID 对齐要求**：daya0576/beaverhabits
- **「最小模式」降级边界（核心功能不依赖 Redis/Valkey + Celery worker，媒体处理才需要）**：journiv/journiv-app
- **自定义 Agent 作为扩展机制（SKILL.md + 事件触发 + 独立模型 + 工作目录 + JS 执行 + 依赖链 + 重试）**：memex-lab/memex
- **官方 SaaS 与自托管并行、社区衍生客户端（iOS 原生 / Stream Deck / Home Assistant）**：daya0576/beaverhabits
