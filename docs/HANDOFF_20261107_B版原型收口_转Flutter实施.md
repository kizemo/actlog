# 交接文档 — practilog B「墨径·账页流」原型已落地，下一阶段转 Flutter 实施

- 生成：2026-11-07 21:58（GMT+0800）
- 交出会话：`mvs_0bebaed106064d89a3f17cc40b2f6da3`
- 上一份交接：`F:\soft\00selfmade\practilog\docs\HANDOFF_20261107_UI转B墨径账页流.md`（本文件取代它的「进度/计划」部分）
- 接棒任务：**B 版 HTML 原型已完整收口（B-0~B-5 全做完），下一步用 `superpowers:writing-plans` 制定 B1 Flutter 实施计划并开工**

---

## 1. 项目背景（30 秒版）

**practilog / 知行日志** —— Windows 桌面端的「知行合一」日志与复盘工具。
方法论底座 = `F:\soft\00selfmade\practilog\高绩效人士的五项管理_全文.md`；需求口径 = `核心需求MVP.md` 系列（全路径见 §4）。
产品核心：每天分 **晨定计划 / 午打卡 / 晚复盘** 三段（三段**永不折叠**），复盘用 **六域**（事业/财富/家庭/学习/人际/健康）
与 **八维**（认真/快/坚守承诺/保证完成任务/乐观/自信/爱与奉献/决不找借口）打分，用**芯片式短语**代替自由打字。
技术栈：Flutter 桌面（`apps\desktop\lib`，15 个 .dart；`apps\` 下**只有 desktop**，Android 工程不存在）。
非 git 仓库，无提交历史可依。

交互 spec 已获用户批准（用户原话「通过。」）；UI 视觉方向用户 **2026-11-07 19:56 改选为 B「墨径·账页流」**。

## 2. 本轮范围（用户四次拍板，仍然有效）

1. 只做 **Windows 桌面端**；
2. 页面范围 = **今日主屏 + 左侧导航 + 日期条/日历弹层**（其余 5 页登记不删，本轮不做）；
3. 品牌取材**抛开现有资产**（`assets\icon.png` 不作基底），按「知行日志/复盘/六域八维」语义重定基调；
4. 交付形态 = **可交互 HTML 原型**（不是静态 mock）；本轮**只做浅色**。

> 本轮已完成 ⇒ **B-0 ~ B-5 全部收口**，B-6（其余 5 页 B 版稿）仍在范围外。

## 3. 进度：已完成 / 已验证 / 推断 / 未验证

### 3.1 已完成且由 agent 亲自验证（可当作可信基线）

| 事项 | 证据（绝对路径 + 实测字节数） |
|---|---|
| **B 版原型已打补丁落地**（时间轴 + 日历弹层 + ARIA 修正） | `F:\soft\00selfmade\practilog\design-demos\v2-ledger.html` **89,281B**，1251+ 行，纯 LF（CRLF 计数 0）。补丁规格 `.superpowers\tmp_patch_B.txt` 19,587B（27 个 `<<<OLD>>>/<<<NEW>>>` 块），运行器 `.superpowers\tmp_apply_patch.js` 1,184B —— **逐块断言 OLD 唯一命中，全通过才写盘** |
| **B-1 页流内纵向时间轴**（三段锚点式） | 落在 `.ledger-pad` 左缘内侧，`.sec-tl` 网格 `var(--tl-w) 64px` + `--tl-gap 12px`；节点 06:00 / 12:00 / 18:00；缺口态实心 `#8C5A2B` + `▸ 有缺口`，闭合态空心 + `✓ 已闭合`；脊线 `::before` 前两段 `bottom:-37.4px`（跨段连续）、末段 `bottom:0px`（止于末节点） |
| **B-2 C 版三类缺陷在 B 上复测** | 结论：**三类在 B 上均不存在，不需要修**。证据 `.superpowers\tmp_probe_B2.json` 4,336B（详见 §3.2） |
| **B-3 三条主路径文案对齐** | 逐字核对脚本 `.superpowers\tmp_b_audit.js` 9,802B → `.superpowers\tmp_b_audit.md` 22,887B。定点核对 15 组全命中：三条主路径 3/3、段头副标 5/5、结论芯片 7/7、原因芯片 8/8、实际时长 5/5、习惯打卡 5/5、复盘六段 6/6、复盘芯片全集 32/32、心态 5/5、八维 8/8、计划 8 条 8/8、闭环口径 3/3、导航 6/6 |
| **B-4 日历弹层（spec §8.2 DatePickerSheet）** | B 确为缺失，已补齐：`#calpop` 容器 + `renderCalPop()` + `calShiftMonth()` + `ACT.calpop/calClose/calPrev/calNext/calToday/calDay` + `calQuick`/`wd-chip` 快捷芯片；Esc / PgUp / PgDn / 方向键全部接上；日期条改 `‹ 昨天 / 明天 ›` 动态标签 + 日期变可点按钮（`.dbtn-date`） |
| **B-5 密度三档 + 三断点** | 三档实测正文 14 / 15 / 16.5px、chip 12 / 12.5 / 13.5px、`--gap-sec` 16 / 22 / 28px；1280 / 1440 / 1920 三档 `hOverflow=0`，1920 出现 `.rail2` |
| **B-0 TOKENS.md 按实测重写** | `F:\soft\00selfmade\practilog\design-demos\TOKENS.md` **14,492B**（替换原 7,137B 作废版）。内容 = `:root` 逐条实测抄录 + WCAG 对比度**自算复算** + B 版赭石使用纪律 + 字号下限三档核查 + Flutter 迁移注意项 |
| **方向记录已更新** | `F:\soft\00selfmade\practilog\design-demos\direction-approved.md` **11,099B**：§1.2 更新字节数、§1.5b 新增「本轮已落地的方向性补充决定」、§3 勾掉两项、§4 批次表全部标状态 |
| **七张实拍**（agent 已逐张打开目视） | `design-demos\v2-ledger-1440.png` 162,037B · `-1280.png` 160,301B · `-1920.png` 185,014B · `-1440-compact.png` 161,166B · `-1440-roomy.png` 161,092B · `-calpop.png` 185,304B · `-timeline.png` 185,167B |

### 3.2 探针关键实测数字（`F:\soft\00selfmade\practilog\.superpowers\tmp_probe_B2.json`，脚本 `tmp_probe_B2.js` 14,670B）

全部用 **Edge headless（`channel:'msedge'`）+ 真实 `page.mouse.click` + `elementFromPoint`** 采集。

| 判据 | 实测 |
|---|---|
| 缺陷① 展开详情遮挡 | `visibleChips=94, tested=35, notHit=[]` ⇒ 展开态芯片**全部鼠标可达** |
| 缺陷② 底部遮挡带 | `ledger top=173 bottom=776 clientH=603 scrollH=2837`；`dockTop=776`、`keyTop=861`；`dockOverlaps=false`、`keyOverlaps=false`；中位滚动 `tested=5 covered=0`；底部滚动 `tested=1 covered=0`；`lastCardReachable=true`（19 张卡）⇒ **吸底条与快捷键条均不遮主列表**（B 用「独立布局行」结构，不是 padding-bottom 补丁） |
| 缺陷③ `data-arg`/`data-v` 混用 | `argCount=65 kindCount=65 vCount=88 argWithoutKind=0 vNotScoreCell=0 vAlsoHasArg=0` ⇒ **`data-v` 只出现在 88 个八维 score `.cell` 上**，与 `data-arg` 零交集 |
| 时间轴 | 3 个 `.tl-mark`；`gridCols="64px 694px"`（1440 视口，正文列由 770px 收窄到 694px）；`pgheadPadLeft=76px`；节点 9px；缺口态 `bg=rgb(140,90,43)`；闭合态 `data-gap="0"` + `bg=rgb(246,244,239)` + `border=rgb(185,174,150)`（空心） |
| ARIA | 单选组 `checkedInGroup=1 / groupSize=7`（唯一选中）；`roleRadio=41`、`roleRadioMissing=0` ⇒ 单选芯片统一 `role="radio"` + `aria-checked`，**不再混用 `aria-pressed`** |
| 日历弹层 | 弹层卡 `[505,220,430,459]` **全在视口内**；30 个 `.cd`、7 个 `.wd-chip`、4 个 `calQuick`；`aria-expanded` true↔false 正确；Esc 关闭 ✓；PgDown `2026-11→2026-12`、PgUp 回到 `2026-11` ✓；方向键 `11-07→11-08` ✓；点选 11-12 ⇒ 日期按钮变 `2026-11-12 周四▾`、弹层关闭 ✓；月格几何 11-01 落在「日」列（周头 `一二三四五六日`，6 个前置空格）✓ |
| 宽度 | 1280：`hOverflow=0`、`rail2=none`、`tlCols="64px 648px"`；1920：`hOverflow=0`、`rail2=block`、`tlCols="64px 784px"` |
| 新增元素对比度 | 9 组全 PASS（`tl-time 6.40` / `tl-state 5.10` / `tl-state(gap) 6.49` / `cd-d 6.40` / `cd-m 5.10` / `cd.sel 9.61` / `wd-chip 6.40` / `wd-chip.on 9.61` / `caret 5.10`） |
| 运行时错误 | `pageerror` = 空、console error = 空 |

### 3.3 只是「agent 推断」，接棒者需当作假设而非事实

- **B-2 的「三类缺陷都不存在」结论只对当前这份 HTML 成立**。B 与 C 无共享代码；B 是因为用了「独立布局行」结构（`.app` 四行 grid：脊线/账页/吸底条/快捷键条）才天然不遮挡，**换结构复现就会出问题**。迁移到 Flutter 时**必须重测**，不能引用本轮结论。
- **B 版的「视觉克制」是 agent 判断，不是用户签字**。用户本轮只拍板了「改选 B + 加时间轴」，未逐项评过赭石纪律、密度三档、弹层形态。
- **周末标红改为非色彩区分**（字重 + 表头标记）是对 spec §8.2 的**有意偏离**，用户尚未确认。

### 3.4 明确未验证（不要写进结论说已完成）

1. **从未做过 Flutter 真机验收** —— 本轮产物是 HTML 原型，界面验收规则（以 `flutter build windows` 产物为准）适用于 B1 实现期，不适用于本轮。
2. **`--hair-strong` 对比度只有 2.00–2.10:1**，达不到 WCAG 1.4.11 非文字 3:1（影响：卡片 hover 边、输入框边、日历格边、复选框边）。本轮**故意没改**（会动视觉语言），但 **B1 落地前必须解决** —— 详见 `TOKENS.md` §1.6。
3. **字号下限有 3 处已知例外**：`.ticks` 10.5px（闭环刻度数字）、`.dtcaret` 11px（光标符号）、`.keybar kbd` 11.5px（键帽）。三档实测（`.superpowers\tmp_b_fontsize.md` 8,832B）确认其余标签类全部 ≥12px、正文 ≥14px。**这三处在 Flutter 里不得承载语义文字。**
4. **B-6（其余 5 页 B 版稿）未做** —— 待办池/习惯/项目/日历/设置 仍是原样。
5. **词库短语未按用户真实用语校准** —— `CONTENT.md` / spec §7、§16-1 的芯片短语目前是按方法论推的起步集。
6. **`superpowers:writing-plans` 的 B1 实施计划尚未制定** —— 这是下一阶段的第一件事。

## 4. 权威文档清单（全路径，接棒会话必读）

**只读输入，禁改**
- `F:\soft\00selfmade\practilog\核心需求MVP.md`
- `F:\soft\00selfmade\practilog\核心需求校验清单.md`
- `F:\soft\00selfmade\practilog\docs\核心需求MVP_v0.2_优化版.md`
- `F:\soft\00selfmade\practilog\高绩效人士的五项管理_全文.md`
- `F:\soft\00selfmade\practilog\docs\schema_v1.sql`（**FROZEN**，已拍板不动 schema）
- `F:\soft\00selfmade\practilog\docs\开发计划.md`

**已获批交互 spec（44,387B，本轮一切功能判据来源）**
- `F:\soft\00selfmade\practilog\docs\superpowers\specs\2026-11-07-双端交互体验设计.md`
  - §3 IA · §4 三段 · **§8.2 日期条与日历弹层（注意：旧 handoff 写成 §6.2 是错的）** · §7 词库 · §10 无障碍 · §13 B1 组件 27 个 · §16 密度档位

**设计基准（可改，但要说明理由）**
- `F:\soft\00selfmade\practilog\design-demos\CONTENT.md` 10,066B —— 文案唯一权威
- `F:\soft\00selfmade\practilog\design-demos\DESIGN.md` 7,794B —— 骨架与硬底线
- `F:\soft\00selfmade\practilog\design-demos\brand-spec.md` 4,493B —— 三套品牌基调，取 B 那套
- `F:\soft\00selfmade\practilog\design-demos\direction-approved.md` **11,099B** —— **现行方向 = B，先读 §1、§1.5b、§4**
- `F:\soft\00selfmade\practilog\design-demos\TOKENS.md` **14,492B** —— **B 版现行 token 口径（已作废横幅已删除）**

**本轮产物**
- `F:\soft\00selfmade\practilog\design-demos\v2-ledger.html` **89,281B** —— B 版原型，**现行唯一实现稿**
- `F:\soft\00selfmade\practilog\design-demos\v2-ledger-{1440,1280,1920,1440-compact,1440-roomy,calpop,timeline}.png` —— 七张实拍

**仅作参照，禁当口径来源**
- `F:\soft\00selfmade\practilog\design-demos\v3-grid.html` —— C 版存档，**不要再投入**
- `F:\soft\00selfmade\practilog\design-demos\v1-bigtype.html` —— A 版存档
- `F:\soft\00selfmade\practilog\design-demos\FIXES_C_deepening_b1.md` —— C 版缺陷的**修法与判据**（B 复测时确实用到）

**上一批工程交接（与 UI 无关，别混）**
- `F:\soft\00selfmade\practilog\docs\HANDOFF_20261107_批次G.md` —— 安装器/托盘批次

## 5. 下阶段计划（按序做，每步都要判据）

| 序 | 做什么 | 判据（做完必须能出示什么） |
|---|---|---|
| **P-1** | **转 `superpowers:writing-plans` 制定 B1 实施计划**（前置条件已满足：tokens 落地） | 计划文件落盘 `F:\soft\00selfmade\practilog\docs\`，逐条映射 spec §13 的 27 个 B1 组件；每条写明对应 `TOKENS.md` 的哪个 token、判据是什么 |
| **P-2** | **先解决 `--hair-strong` 对比度 2.0:1 的问题** | 给出调深后的值并复算 ≥3:1（`TOKENS.md` §1.6），或改用 `--ink` 系描边；**这一步在写任何 Flutter 组件前做**，否则所有边框都会带着不合规值扩散 |
| **P-3** | 建 Flutter 主题层：颜色/字号/密度三档/字体资源 | `ColorScheme` 显式给值（primary=ink #2E4057，赭石是 error/警示色不是 primary）；字体打包 Fraunces/Inter/JetBrains Mono/Noto Sans SC；`DensityProfile` 主题扩展只换一组变量（对应 `TOKENS.md` §2.1） |
| **P-4** | 实现今日主屏骨架：双栏（账页 + 工具轨）+ **纵向时间轴** + 吸底条 | 用 `flutter build windows` 产物截图验收（**不是 `flutter dev`**）；时间轴节点/脊线形态与本轮 HTML 一致（06:00/12:00/18:00，缺口态实心赭石 + `▸ 有缺口`） |
| **P-5** | 移植**日历弹层**（spec §8.2 DatePickerSheet） | 居中弹层 + 快捷芯片 + 月历；Esc/PgUp/PgDn/方向键；周末**不靠红色**（沿用本轮的非色彩区分做法） |
| **P-6** | 把本轮的**行为级探针**方法移植成 Flutter 侧验收脚本 | 判据沿用 `FIXES_C_deepening_b1.md`：**真实鼠标点击 + `elementFromPoint` 等价**（Flutter 用 `flutter test` 的 hit test / `WidgetTester`），**不要用 rect 判可达**；本轮 HTML 探针的判据可以作为测试用例清单（但**必须在 Flutter 侧重跑**，见 §3.3） |
| **P-7** | B-6：其余 5 页的 B 版稿 | 待办池/习惯/项目/日历/设置；**登记即可，用户未催** |

## 6. 项目硬约束（改代码前必读）

- 非 git 仓库。数据目录必须 `<exe>\userdata`。
- Dart 源文件 **LF**；`tools\*.ps1` 尽量纯 ASCII/LF/无 BOM；`.nsi` 必须 UTF-8 **带 BOM** + LF；新代码**禁 `print`**。
- 界面验收以 `flutter build windows` 产物为准；**`flutter dev` 不可用于界面验收**。
- `docs\schema_v1.sql` FROZEN，已拍板不动 schema。
- 标题「知行日志」、`practilog`、bundle `com.practiclog`。
- huashu-design 硬门：**方向若再变更，必须先更新 `direction-approved.md` 记用户原话，再动实现**；产出目录 `design-demos\`，禁用 `_temp\`；正文 ≥14px、标签 ≥12px、对比度 ≥4.5:1。
- 审美禁区：彩色 emoji 当图标、紫渐变、圆角卡+左彩色 border、SVG 画人、Inter/Roboto 作唯一 display、GitHub-dark 偷懒解。
  （B 的 display 是 **Fraunces 衬线**，不踩 Inter 禁区；`DESIGN.md §5` 明文豁免单色状态标记 `✓ ● ○ ▸ ✍`。）

## 7. 工具坑（本轮踩过，别再花一轮试）

**可用命令形状**
```powershell
# B 版截图（--channel msedge 必须，无它 exit=1；用户偏好 Edge 不用 Chrome）
npx --yes playwright screenshot 'file:///F:/soft/00selfmade/practilog/design-demos/v2-ledger.html' 'F:\soft\00selfmade\practilog\design-demos\v2-ledger-1440.png' --channel msedge --viewport-size=1440,900 --wait-for-timeout=4000

# 行为级探针：npx -p playwright 不会给 node 暴露 require，必须显式挂 NODE_PATH
$env:NODE_PATH = 'C:\Users\Duanyi\AppData\Local\npm-cache\_npx\e41f203b7505f1fb\node_modules'
node F:\soft\00selfmade\practilog\.superpowers\tmp_probe_B2.js > F:\soft\00selfmade\practilog\.superpowers\tmp_probe_B2.json 2>&1
# 脚本内：const {chromium}=require('playwright'); chromium.launch({channel:'msedge',headless:true})
#        newPage({viewport:{width:1440,height:900}})

# 通用审计脚本（本轮写的 token/对比度/文案核对器，可复用）
node F:\soft\00selfmade\practilog\.superpowers\tmp_b_audit.js      # → tmp_b_audit.md
node F:\soft\00selfmade\practilog\.superpowers\tmp_b_fontsize.js   # → tmp_b_fontsize.md

# 批量改 HTML 的安全做法：补丁规格 + 唯一命中断言运行器（27 块全通过才写盘）
node F:\soft\00selfmade\practilog\.superpowers\tmp_apply_patch.js

# Flutter 门禁（B1 实现期用；手工跑必须设中国镜像，否则挂在 pub.dev）
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'; $env:FLUTTER_STORAGE_BASE_URL='https://storage-io.cn'
& 'F:\soft\flutter\flutter\bin\flutter.bat' analyze
& 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact --timeout 120s
```

**失败写法（禁止重试）**
1. `bash` 里先 `Set-Location` 再写文件会被本地硬安全策略拦 ⇒ **一律用绝对路径、不 cd**。
2. `Get-ChildItem -Filter 'HANDOFF*','Directory'` —— `-Filter` 不收数组。
3. 用 rect 判「闭合元素不可达」—— 改用 `checkVisibility({checkVisibilityCSS:true})` / `elementFromPoint` / Tab 停靠数。
4. 用 DOM 级 `el.click()` 判遮挡缺陷 —— 必须 `page.mouse.click` + `elementFromPoint`。
5. `pg.evaluate(fn, arg)` 忘传第二参 ⇒ `a is not iterable`。
6. 判遮挡带时用 `innerHeight` 或「卡片必须完全在账页可视区内」当过滤 ⇒ 会漏判/假 0；正确判据是「卡片底部在账页可视区内的点 + `elementFromPoint` 命中卡片」，且 `.ledger` 有 `scroll-behavior:smooth`，设 `scrollTop` 前须 `style.scrollBehavior='auto'`。
7. `edit` 按记忆写 `old_string` ⇒ 必先 `read` 回原文；参数名是 `file_path` 不是 `path`。
8. 权限坑：`rm` 必须单独成一条 targets-only 命令；`design-demos\` 一律用绝对路径。
9. `read` 大文件必须带 `offset`/`limit`；字符数 ≠ 字节数。
10. PNG 只有约 14KB = 脚本异常导致的半空白页。
11. `LogonUI` 在跑 = 会话锁屏，UI 自动化会静默失败。
12. 探针 JSON 直接 dump 会被 88 个 `data-v` 元素撑爆 ⇒ 用摘要/字段提取后再读。
13. **用正则抽 CSS 时必须先剥注释**，否则 `:root` 前的说明注释会被并进选择器，导致「顶层 `:root` 找不到 / 对比度表空」；本轮为此白跑两轮脚本。
14. **用 `aria-checked` 判单选组**（B 已改用 `aria-checked`）—— 用 `textContent.trim()` 匹配单选芯片会被 `○→●` 前缀变化骗出假阴性。
15. 交接卡可能串台：`E:\Users\Duanyi\.minimax\.minimax\maintenance\task-state\LATEST.md` 是**同机多项目共用**的（本轮它给出的是 filemanager 的内容）—— 读到先核对项目归属。

## 8. 不在本任务里、但别丢的用户本人事项

1. **词库校准**：`CONTENT.md` / spec §7、§16-1 的芯片短语需用户以真实用语校准（目前是按方法论推的起步集）。
2. **批次 G 装机真机复核三项**（只能用户本人做）：双击安装包的中文 MUI2 向导观感；二次「更新安装」是否回填已装路径（验收前先关掉运行中的 exe）；非管理员账户下 `<exe>\userdata` 可写性。
3. **约 126 MB 残留分选删除**需用户批准：清单在 `F:\soft\00selfmade\practilog\docs\HANDOFF_20261107_批次G.md` §10。**至今尚未删过任何文件。**
4. **周末标红改非色彩区分**是本轮的有意偏离（spec §8.2 写的是标红），**用户尚未确认** —— 若用户想要红色，需回改 spec 与 `direction-approved.md`。
5. B-6（其余 5 页）用户未催，优先级低。

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

---

## B1 已实施（2026-11-09）

B1 的 Flutter 实施与真机验收已完成归档，状态以这两份文件为准：

- 验收结论与遗留问题：`F:\soft\00selfmade\practilog\docs\B1_验收记录.md`
- 实施计划与 8 个 Step 的完成记录：`F:\soft\00selfmade\practilog\docs\superpowers\plans\2026-11-07-b1-flutter-implementation.md`（Task 17 窗口 6567–6690）

要点：G1–G4 门禁全绿（G2 `passed=242 failed=0`、G3 `checks=16 failed=0`），Release 构建与 NSIS 安装包均产出；六场景实测为「通过 2 / 部分通过 2 / 受限 1 / 不通过 1」。键盘无法切换 Checkbox（`today_page.dart:317` 行级 `InkWell` 吞掉 Space）与 M16-6（无日历宿主页，无法补录）是既有代码缺陷，已在验收记录第 5 节登记；安装包夹带开发机 `userdata\` 目录同批登记。

**Task 17 收口（2026-11-09）**：Task 17 的 8 个 Step 已全部完成，并由独立只读 verifier 复核 **PASS**（`FAIL_COUNT=0`，会话 `mvs_b95a9616487e47b7af389cb064ef3138`）；计划中 8 个 Step 复选框已 8/8 勾选（`290310 B / 6753 行 / F5770231CAA46A38`，`- [ ]`=15、`- [x]`=75）。六场景里的「不通过 1（键盘切换 Checkbox）」与「受限 1（M16-6 无日历宿主页）」都不是本轮门禁或打包的回归，而是既有代码缺陷，修法建议见验收记录第 5 节。
