# B12 派工记录（三条用户反馈的实现切分）

- 记录时间：2026-11-26（本轮）
- 上一笔提交：`39b9b14`（`docs(ledger): 记录 B11 装机复验与 §11.16`）
- 触发：用户对新装机版本提出三条反馈（原文见下）

## 一、用户反馈原文

1. 个人定位部分，填写说明请放入悬浮框，在鼠标悬停在定位分类标题上时显示；去除输入的确认按键，标签库链接。点击选择标签，自动保存；手动输入，回车自动录入保存，以符号分隔；
2. 目标模块美化不理想，标签请参考 chrome 或 edge 浏览器的标签，表格中的内容，适当增加上下边距；
3. 目标输入的结束日期，点击请弹出日期选择框，可以点击选择；当前填写日期后，无法出现在第三列，请检查修复 bug；目标框中，不要显示“条做法”、“未落位”。

## 二、根因（控制器已勘察，源码为准）

| 反馈 | 现状 | 根因 |
|---|---|---|
| 1 | `_buildItem` 渲染 标题 + hint 正文行 + 输入框 + `▾ 标签库` 开关 + `保存` 按钮 + 状态行 | `_appendTag` 只追加不落库；`_save` 是唯一落库入口；hint 常驻渲染 |
| 2 | `_tab()` = `TextButton` + `Tooltip` + `inkWash` pill；单元格 `Padding(EdgeInsets.all(4))` | 标签页形态与浏览器标签不符；垂直内边距过小 |
| 3 | 表单 due 是纯文本 `TextField`（key `goal-blueprint-form-due`）；`_writeGoal` 只写 `dueDate`；矩阵第三列 `_periodText` 只读 `periodStart/periodEnd` | **写入来源与读取来源不一致** ⇒ 填了日期第三列不出现 |

## 三、写集切分（并行，互不重叠）

- **Worker A（反馈 1）**：`apps\desktop\lib\src\widgets\goal_brand_panel.dart`
  + 测试 `test\b12_position_panel_test.dart`（新建）、`test\b10_position_panel_test.dart`、`test\b11_blueprint_roulette_test.dart`（仅被删控件相关断言）
- **Worker B（反馈 2+3）**：`apps\desktop\lib\src\widgets\goals\goal_blueprint_matrix.dart`、
  `apps\desktop\lib\src\widgets\goals\goal_form_dialog.dart`、`apps\desktop\lib\src\pages\goals_blueprint_page.dart`
  + 测试 `test\b12_matrix_tabs_date_test.dart`（新建）、`test\task66_goals_blueprint_page_test.dart`、
  `test\task73_b8_w1_blueprint_edit_test.dart`、`test\task74_goal_edit_shared_test.dart`

两侧均**不得**改 l10n 任何文件（含 `l10n_keys.dart`）与 `l10n_base_test.dart`；需要新文案 ⇒ 停下回报。

## 四、裁决与假设（控制器口径）

1. 反馈 2 = **参照式微调**（用户已给 Chrome/Edge 参照物），不重走 huashu 三初稿门；顶部圆角允许 8px 单点例外并注释，其余一律走 `theme_tokens.dart` 的 `LightPalette`；禁渐变/阴影/光晕/位图。
2. 反馈 1 去掉「标签库链接」后，标签库入口 = **点击/聚焦输入框即展开**（否则用户无从点标签）。
3. 反馈 3 第三列修复双管齐下：`_writeGoal` 同写 `periodEnd` + 矩阵第三列在缺 period 时**回退显示 `dueDate`**（新旧数据都可见）。
4. `dueDate` 时区口径沿用 B11 裁决：蓝图目标 = 本地午夜毫秒，不得改回 UTC。
5. 「条做法 N」「未落位」= 删除格内该两处渲染（含 key `goal-blueprint-unplaced-<id>`），并同步改 `task66` 既有断言。
6. worker 一律**不跑** `flutter test/build/analyze`（与另一 worker 并发会污染 `.dart_tool` 与 `build\test_cache`），门禁由控制器统一亲跑。

## 五、收口链（控制器执行）

worker 实现 → 控制器亲跑 `flutter analyze`（逐字 `No issues found!`）+ 全量 `flutter test`（基线 986，只增不减）
→ release 构建（`flutter build windows --release`）→ `tools\build\make_installer.ps1 -Version '1.0.0'`（坑 127 两步）
→ 更新 R3 唯一可分发指针 → 静默装配（先确认用户实例已退出、活库 sha16 仍 `B5F9070FC63068B1`）
→ 装机件取证（`PrintWindow(hwnd,hdc,2)` + 像素判据）→ 台账追加节 → 提交（排除并发接力链会话的 `AGENTS.md`/`docs\relay*`/`docs\b8*.md`）

## 六、当前门禁基线（控制器读数，须盘上回读为准）

- `flutter analyze`：`No issues found! (ran in 6.3s)`
- `flutter test --reporter compact`：`03:09 +986: All tests passed!`
- l10n 基线：608 / 667（本轮不变）
- R3 唯一可分发：`release\actlog-Setup-1.0.0_20261126-174718.exe`，22,846,044 B / sha16 `317436F79DAF631F`（出新包后须更新）
