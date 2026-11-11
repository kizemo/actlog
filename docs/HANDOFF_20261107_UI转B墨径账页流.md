# 交接文档 — practilog UI 设计转 B「墨径·账页流」

- 生成：2026-11-07 19:58（GMT+0800）
- 交出会话：`mvs_119acec20f174625b66e81ff85f21c50`
- 接棒任务：**把视觉方向从 C 换成 B（用户 19:56 改选），在 B 的页流内新增纵向时间轴，并把 C 版已验证的三类缺陷在 B 上复测修掉**
- 状态：**方向变更与后果已落盘，B 版实现尚未开始一行**。当前卡点 = design tokens 需按 B 重取

---

## 1. 项目背景（30 秒版）

**practilog / 知行日志** —— Windows 桌面端的「知行合一」日志与复盘工具。
方法论底座 = `F:\soft\00selfmade\practilog\高绩效人士的五项管理_全文.md`；需求口径 = `核心需求MVP.md` 系列（全路径见 §4）。
产品核心：每天分 **晨定计划 / 午打卡 / 晚复盘** 三段（三段**永不折叠**），复盘用 **六域**（事业/财富/家庭/学习/人际/健康）
与 **八维**（认真/快/坚守承诺/保证完成任务/乐观/自信/爱与奉献/决不找借口）打分，用**芯片式短语**代替自由打字。
技术栈：Flutter 桌面（`apps\desktop\lib`，15 个 .dart；`apps\` 下**只有 desktop**，Android 工程不存在）。
非 git 仓库，无提交历史可依。

交互 spec 已获用户批准（用户原话「通过。」），UI 视觉方向经三版初稿对比后，用户 **19:56 改选为 B**。

## 2. 本轮范围（用户四次拍板，仍然有效）

1. 只做 **Windows 桌面端**；
2. 页面范围 = **今日主屏 + 左侧导航 + 日期条/日历弹层**（其余 5 页登记不删，本轮不做）；
3. 品牌取材**抛开现有资产**（`assets\icon.png` 不作基底），按「知行日志/复盘/六域八维」语义重定基调；
4. 交付形态 = **可交互 HTML 原型**（不是静态 mock）；本轮**只做浅色**。

## 3. 进度：已完成 / 已验证 / 推断 / 未验证

### 3.1 已完成且由 agent 亲自验证（可当作可信基线）

| 事项 | 证据（绝对路径 + 实测字节数） |
|---|---|
| 三版可交互 HTML 初稿 + 三张 1440×900 实拍，一次性呈现供用户选（huashu-design 硬门） | `F:\soft\00selfmade\practilog\design-demos\v1-bigtype.html` 81,881B / `v2-ledger.html` **78,170B** / `v3-grid.html` 102,771B；`v1-bigtype-1440.png` 181,054B / `v2-ledger-1440.png` **159,226B（16:13，改选前旧稿）** / `v3-grid-1440.png` 301,256B |
| 三份共享口径基准 | `design-demos\CONTENT.md` 10,066B（文案，唯一权威）、`DESIGN.md` 7,794B（骨架与硬底线）、`brand-spec.md` 4,493B（三套品牌基调）；辅助 `COMPARE.md` 2,027B、`FIXES.md` 4,153B |
| C 版芯片派发缺陷（`data-arg` vs `data-v` 混用，7 个 act）已修 + 7/7 行为级验证 | `design-demos\FIXES_C_chip_dispatch.md` **6,340B**（19:58 复量值，早前记录的 5,416B 已被后续追加覆盖） |
| C 版深化第 1 批：晚段展开详情覆盖缺陷 + 三条主路径文案对齐 | `design-demos\FIXES_C_deepening_b1.md` **14,344B**，含「附：agent 独立复测」小节；复测脚本 `F:\soft\00selfmade\practilog\.superpowers\tmp_verify_b1.js` 5,474B |
| C 版深化第 1 批 agent 独立复测（不信 worker 自述，另写探针亲测）7/7 通过 | 同上文件；关键亲测数字：真实鼠标点段②行 → `totalDet=14 openCount=1`；展开详情内 **20/20** 颗芯片 `elementFromPoint` 命中自身；14 个闭合 det / 318 颗芯片 / **可达 0 颗** / `checkVisibility()` false 318/318；26 次 Tab **0 次**误入；首个焦点环 `rgb(27,79,216)`；`pageerror` 空；agent 亲自读 PNG 目视确认 |
| **方向变更记录（含改选）**已按硬门落盘 | `design-demos\direction-approved.md` **7,642B**（19:57 重写，§1 记 B 改选原话、§1.4 记口径后果、§1.5 记 C 工作如何转移、§4 记激活批次） |
| 旧 tokens 已标废，防止接力会话误用 | `design-demos\TOKENS.md` **7,137B**，顶部作废横幅（19:57） |

### 3.2 只是「agent 推断」，接棒者需当作假设而非事实

- B 版「墨径·账页流」适合承载纵向时间轴：`.ledger-pad` 是 `max-width:770px` 的居中单栏页流（`v2-ledger.html:148`），
  时间轴沿左缘走、段落节点用赭石 —— 这是**设计推断**，用户只说了「页流中，添加纵向时间轴」，没指定形态。做之前值得先确认要不要对齐 06:00–24:00 半小时刻度。
- C 版三类缺陷「在 B 上大概率也存在」：C/B 是不同的 HTML，无共享代码，**不能假定同源**，必须在 B 上重跑探针才知道。

### 3.3 明确未验证（不要写进结论说已完成）

1. **B 版 design tokens 未取**。`TOKENS.md` 现有内容全是 C 版数值。
2. **B 版从未做过行为级探针**：芯片派发是否有 `data-arg`/`data-v` 混用、展开详情遮挡、底部固定条遮挡带 —— 全部未测。
3. **B 版主路径文案是否对齐 `CONTENT.md §2`** —— 未核。
4. **spec §6.2「日期条点日期弹出日历弹层」**：在 **C 版**已核实为**缺失**（grep 无 `calpop`，只有整页日历 `calday/caljump/calcatch/calmon`）。
   **B 版有没有日历弹层未查**。注意这条曾被当作「整页日历已足够」而搁置，需按 spec 文本判，别自作主张降级。
5. **B 版改选后的实拍截图未截**（现 `v2-ledger-1440.png` 是 16:13 的旧稿）。
6. 密度三档与 `<1280` / `≥1920` 断点观感：原型只在 1440×900 验过；B 有 `.rail2`（`:150` 默认 `display:none`，`:368` 宽屏才出现）—— 断点行为未实测。
7. **词库短语未按用户真实用语校准**（`CONTENT.md` / spec §7、§16-1 的芯片短语目前是按方法论推的起步集）。
8. 从未做 Tauri/Flutter 真机验收 —— 本轮产物是 HTML 原型，界面验收规则（以 `flutter build windows` 产物为准）适用于后续 B1 实现，不适用于本轮。

## 4. 权威文档清单（全路径，接棒会话必读）

**只读输入，禁改**
- `F:\soft\00selfmade\practilog\核心需求MVP.md`
- `F:\soft\00selfmade\practilog\核心需求校验清单.md`
- `F:\soft\00selfmade\practilog\docs\核心需求MVP_v0.2_优化版.md`
- `F:\soft\00selfmade\practilog\高绩效人士的五项管理_全文.md`
- `F:\soft\00selfmade\practilog\docs\schema_v1.sql`（**FROZEN**，已拍板不动 schema）
- `F:\soft\00selfmade\practilog\docs\开发计划.md`

**已获批交互 spec（约 546 行 / 44,387B，本轮一切功能判据来源）**
- `F:\soft\00selfmade\practilog\docs\superpowers\specs\2026-11-07-双端交互体验设计.md`
  - §3 IA（L60）· §4 三段（L82）· §6.2 日期条与**日历弹层** · §7 词库（L242）· §8（L277）· §9（L307）
    · §10（L357）· §13 B1 组件 27 个（L438）· §14（L465）· §16 无障碍（L505）· §17（L517）

**设计基准（可改，但要说明理由）**
- `F:\soft\00selfmade\practilog\design-demos\CONTENT.md` —— 文案唯一权威，原型文案必须逐字照抄
- `F:\soft\00selfmade\practilog\design-demos\DESIGN.md` —— 骨架、硬底线（≥14px 正文 / ≥12px 标签 / ≥4.5:1）、§5 单色状态标记豁免表
- `F:\soft\00selfmade\practilog\design-demos\brand-spec.md` —— 三套品牌基调，**取 B 对应那套**
- `F:\soft\00selfmade\practilog\design-demos\direction-approved.md` —— **现行方向 = B，先读 §1 与 §4**
- `F:\soft\00selfmade\practilog\design-demos\TOKENS.md` —— **已作废**，仅作「tokens 文档该长什么样」的结构模板

**本轮工作对象**
- `F:\soft\00selfmade\practilog\design-demos\v2-ledger.html`（78,170B，B 版，**要改的就是它**）
- `F:\soft\00selfmade\practilog\design-demos\v3-grid.html`（102,771B，C 版存档，**不要再投入**）
- `F:\soft\00selfmade\practilog\design-demos\FIXES_C_deepening_b1.md` —— C 版缺陷的**修法与判据**可转移给 B

**技能根目录**
- `E:\Users\Duanyi\.claude\skills\huashu-design\`（`references\design-styles.md`；做 Android 稿才读 `references\app-prototype.md`）

**上一批工程交接（与 UI 无关，别混）**
- `F:\soft\00selfmade\practilog\docs\HANDOFF_20261107_批次G.md` 28,607B —— 安装器/托盘批次

## 5. 下阶段计划（按序做，每步都要判据）

| 序 | 做什么 | 判据（做完必须能出示什么） |
|---|---|---|
| **B-0** | 按 `v2-ledger.html` 实测重取 design tokens，**重写** `TOKENS.md` | 值全部从 `:root` 抄（`--paper:#F6F4EF --card:#FBFAF6 --sunken:#F0EDE5 --dock:#F7F5F0 --keybg:#F1EFE8 / --ink:#2E4057 --ink-2:#3D5170 --meta:#5F584B --faint:#6E6759 / --hair:#DCD5C6 --hair-soft:#EAE4D9 --hair-strong:#B9AE96 / --accent:#8C5A2B --accent-ink:#7A4E24 --accent-wash:#F3E8DC --ink-wash:#E7EAEF / --f-display:"Fraunces","Noto Serif SC",… / --r:4px --nav-w:214px --rail-w:290px --rail2-w:286px / --fs-body:15px --lh:1.66 --fs-label:12.5px --fs-h2:19px`）；**自己复算对比度**（B 源码注释 `:35-38` 那组数字要验证后才可引用）；写清「强调色使用纪律」的 B 版等价物 |
| **B-1** | **页流内新增纵向时间轴**（用户点名，本轮核心新增需求） | 长在 `.ledger-pad` 内、串起段①/②/③；刻度口径先与用户确认（建议对齐 spec 的 06:00–24:00 半小时格）；1440×900 实拍可见；不得把标签字号压到 12px 以下 |
| **B-2** | 在 B 上复测 C 版三类缺陷并修：① 展开详情遮挡 ② 底部固定条遮挡带 ③ `data-arg`/`data-v` 混用 | 判据照 `FIXES_C_deepening_b1.md` 的「附：agent 独立复测」小节抄：**真实 `page.mouse.click` + `elementFromPoint`**，闭合详情用 `checkVisibility()` / Tab 停靠数，**不要用 rect 判可达**（rect 会被强制布局返回非零盒） |
| **B-3** | 三条主路径文案对齐 `CONTENT.md:26-27` | 复用 B 已有 act，**不新增分支、不新增键位**（C 版就是这么做的，验通） |
| **B-4** | 核对 B 有没有 spec §6.2 的**日历弹层**；缺则补 | 「点日期条上的日期 → 弹层月历 → 选日期进入当天或补录」；若判定整页日历可替代，**要拿 spec 原文向用户确认**，别自己降级 |
| **B-5** | 密度三档（用 B 的 `--fs-body/--lh/--pad-card/--gap-sec` 组，**不是 C 的 `--u`**）+ `<1280` / `≥1920` 断点观感 | 1280 / 1440 / 1920 三档实拍各一张；确认 `.rail2` 显隐与吸底条不遮末行 |
| **B-6** | 其余 5 页 B 版稿（待办池/习惯/项目/日历/设置） | 本轮范围外，登记即可 |
| **B-7** | 转 `superpowers:writing-plans` 制定实施计划（B1 组件先行，纳入 B-0 的 tokens） | tokens 必须先落地，否则计划里的样式表是空的 |

## 6. 项目硬约束（改代码前必读）

- 非 git 仓库。数据目录必须 `<exe>\userdata`。
- Dart 源文件 **LF**；`tools\*.ps1` 尽量纯 ASCII/LF/无 BOM；`.nsi` 必须 UTF-8 **带 BOM** + LF；新代码**禁 `print`**。
- 界面验收以 `flutter build windows` 产物为准；**`flutter dev` 不可用于界面验收**。
- `docs\schema_v1.sql` FROZEN，已拍板不动 schema。
- 标题「知行日志」、`practilog`、bundle `com.practiclog`。
- huashu-design 硬门：**方向若再变更，必须先更新 `direction-approved.md` 记用户原话，再动实现**；产出目录 `design-demos\`，禁用 `_temp\`；正文 ≥14px、标签 ≥12px、对比度 ≥4.5:1。
- 审美禁区：彩色 emoji 当图标、紫渐变、圆角卡+左彩色 border、SVG 画人、Inter/Roboto 作唯一 display、GitHub-dark 偷懒解。
  （注：B 的 display 是 **Fraunces 衬线**，不踩 Inter 禁区；`DESIGN.md §5` 明文豁免单色状态标记 `✓ ● ○ ▸ ✍`。）

## 7. 工具坑（本轮踩过，别再花一轮试）

**可用命令形状**
```powershell
# B 版截图（--channel msedge 必须，无它 exit=1；用户偏好 Edge 不用 Chrome）
npx --yes playwright screenshot 'file:///F:/soft/00selfmade/practilog/design-demos/v2-ledger.html' 'F:\soft\00selfmade\practilog\design-demos\v2-ledger-1440.png' --channel msedge --viewport-size=1440,900 --wait-for-timeout=4000

# 行为级探针：npx -p playwright 不会给 node 暴露 require，必须显式挂 NODE_PATH
$env:NODE_PATH = 'C:\Users\Duanyi\AppData\Local\npm-cache\_npx\e41f203b7505f1fb\node_modules'
node F:\soft\00selfmade\practilog\.superpowers\tmp_verify_b1.js
# 脚本内：const {chromium}=require('playwright'); chromium.launch({channel:'msedge',headless:true})
#        newPage({viewport:{width:1440,height:900}})

# 取某文件的 :root 块
$s=[IO.File]::ReadAllText('F:\soft\00selfmade\practilog\design-demos\v2-ledger.html',[Text.Encoding]::UTF8); $i=$s.IndexOf(':root'); $s.Substring($i,$s.IndexOf('}',$i)-$i+1)

# Flutter 门禁（B1 实现期用；手工跑必须设中国镜像，否则挂在 pub.dev）
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact --timeout 120s
```

**失败写法（禁止重试）**
1. `Get-ChildItem -Filter 'HANDOFF*','Directory'` —— `-Filter` 不收数组，直接 `-Filter 'HANDOFF*'`。
2. 用 rect 判「闭合元素不可达」—— Chrome 查询 `content-visibility:hidden` 子树的 rect 会**强制布局**返回非零盒。改用 `checkVisibility({checkVisibilityCSS:true})` / `elementFromPoint` / Tab 停靠数。
3. 用 DOM 级 `el.click()` 判遮挡缺陷 —— **假 PASS**（绕过命中测试）。必须 `page.mouse.click` + `elementFromPoint`。
4. `pg.evaluate(fn, arg)` 忘传第二参 —— 页面里 `a is not iterable`。
5. 用 `aria-checked` 判多选组（B/C 的多选用 `aria-pressed`）—— 恒 null、误判 NO_CHANGE。
6. 探针点了默认已选中项 / 展开错行 —— 两轮假阴性。
7. `edit` 按记忆写 `old_string` —— 「Could not find the exact text」，必须先 `read` 回原文。
8. **`edit` 工具参数名是 `file_path`，不是 `path`**（本轮又踩一次，浪费一轮）。
9. 权限坑：`rm` 必须单独成一条 targets-only 命令，与其它语句同调用会被 recoverable-delete 整条拦下；
   `Set-Location` 后写相对路径被拦 ⇒ `design-demos\` 一律用绝对路径。
10. PowerShell 统计：`[s.match(/re/g)]||[]` 多包一层数组 ⇒ 恒长 1；`Select-String -Context` 输出不可当原文抄。
11. `read` 大文件必须带 `offset`/`limit`；字符数 ≠ 字节数；`node --check` 需先把 `<script>` 抽到 .js。
12. PNG 只有约 14KB = 脚本异常导致的半空白页（一个 `ReferenceError` 让整页停渲），不是布局问题。
13. `LogonUI` 在跑 = 会话锁屏，UI 自动化会静默失败，先判锁屏再怀疑代码。
14. **后台 worker 写文件期间读它的产物 = 读到半截**（本轮实测：同一文件先后读到 27,438B 解析失败、5,133B、16,215B）。先 `task_query` 确认终态再验收。
15. 交接卡可能串台：`E:\Users\Duanyi\.minimax\.minimax\maintenance\task-state\LATEST.md` 是**同机多项目共用**的，
    本轮它一度给出另一条会话（filemanager）的内容 —— 读到先核对项目归属。

## 8. 不在本任务里、但别丢的用户本人事项

1. **词库校准**：`CONTENT.md` / spec §7、§16-1 的芯片短语需用户以真实用语校准（目前是按方法论推的起步集）。
2. **批次 G 装机真机复核三项**（只能用户本人做）：双击安装包的中文 MUI2 向导观感；二次「更新安装」是否回填已装路径（验收前先关掉运行中的 exe）；非管理员账户下 `<exe>\userdata` 可写性。
3. **约 126 MB 残留分选删除**需用户批准：清单在 `docs\HANDOFF_20261107_批次G.md` §10（A 可删 / B 必留证据 / C 严禁删 / D 假阳性）。
   实测 `F:\soft\00selfmade\practilog\.superpowers\` 下确有 `practilog_payload_*.7z` 三份（9.4MB/10.3MB/10.3MB）与 `tmp_*.json` 大文件（`tmp_before3.json` 189,914B、`tmp_after.json` 190,881B）。**尚未删过任何文件。**
4. 批次 G 刻意暂缓的一次性改文档（需用户点头）：`docs\P1_进度.md:362,414,436,453`、`docs\P1_交接文档.md:591,683,693,715,716`、`README.md:26-35,164-180`、`docs\D1_技术选型结论.md:100,210`、废弃 `tools\build\make_sfx.ps1:6,54` 与 `tools\installer\install_post.ps1:45`；spec §15 登记 `docs\开发计划.md` P4 的 Kotlin+Compose/Room+SQLDelight 表述作废。

## 9. 用户长期偏好（跨项目，接棒会话照做）

- **明显 bug 直接按推荐方案修，不发问卷**（根因坐实 + 代价可逆 ⇒ 直接动手做完汇报）。
  必须先问的三类：① 删除/覆盖用户数据 ② 付费或对外发布 ③ 大量时间或显著改架构方向。
- **需要装机实测就直接打包 exe**，不等用户要求。
- **浏览器调试用 Edge，不要 Chrome**。
- **交棒时必须产「完整 handoff 文档 + 一句话 prompt」**：handoff 落盘进项目（背景/目标/进度/下阶段 + 已验证·推断·未验证 + 证据路径 + 工具坑）；
  prompt 只给**全路径**引导新会话去读必要文档、自己掌握背景目标进度计划，**不复述 handoff 内容**，更不许拿转述代替文档。
- **worker 说修好不算**：agent 亲自读截图 + 自己另写探针亲测才算；探针自身必须有判别性；
  「派发正确（DOM click）」≠「鼠标可达（真实 mouse.click + elementFromPoint）」。
- 中间产物写文件，对话只留指针 + 结论；单轮工具调用 ≤10 次，超 20 次停止试探、一次取齐。
