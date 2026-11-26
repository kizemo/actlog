# B12 修复派工书（接两个中途失败的 worker）

- 时间：2026-11-26 21:35 左右
- 背景：B12 两个并行 worker 都因 Token Plan 额度（2056）在实现后段被掐断。
  - **worker A（反馈 1）**：`goal_brand_panel.dart` 重写进行到一半 ⇒ **当前不可编译**。
  - **worker B（反馈 2+3）**：lib 三个文件改动已完整（analyze 无 error）；但 `task73` 引用了一个没定义的 `DatePicker` helper；两个新建用例文件都没创建。

## 一、控制器实测现场（盘上回读，权威）

`flutter analyze`（cwd = `apps\desktop`）→ **14 issues / 9 error**，全部集中在两处：

### A. `apps\desktop\lib\src\widgets\goal_brand_panel.dart`（半成品）

```
warning - '_hintMaxWidth' isn't referenced                                 :76:14
warning - field '_hintOverlay' isn't used                                 :182:17
warning - field '_hintTimer' isn't used                                   :183:10
warning - field '_hintCode' isn't used                                    :184:11
warning - field '_hintAnchorRect' isn't used                              :187:9
error   - '_onFocusChanged' isn't defined                                 :197:44
error   - '_removeHintOverlay' isn't defined                              :206:5
error   - '_itemFor' isn't defined                                        :385:33
warning - '_submitTags' isn't referenced                                  :395:16
error   - '_removeHintOverlay' isn't defined                              :431:5
error   - argument 'String' can't be assigned to 'GlobalKey<State<...>>'   :514:43
error   - Undefined name '_toggleKeys'                                    :867:12
error   - '_toggleTags' isn't defined                                     :870:26
```

⇒ 已声明的 hint 浮层状态字段/常量与几个回调都还是「空壳」：`_onFocusChanged`、`_removeHintOverlay`、`_itemFor`、`_submitTags`（已写未接）、`_toggleTags`、`_toggleKeys`（应删除）。

### B. `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart`

```
error   - Undefined name 'DatePicker'                                      :269:39
```

⇒ 该测试引用了一个从未定义的 helper。

### C. 未创建的文件

- `apps\desktop\test\b12_position_panel_test.dart`（不存在）
- `apps\desktop\test\b12_matrix_tabs_date_test.dart`（不存在）

### D. 未更新的既有测试（当前会运行时失败，非 analyze 报错）

- `apps\desktop\test\b10_position_panel_test.dart`（断言 `goal-position-tags-toggle-<code>` 存在并点击）
- `apps\desktop\test\b11_blueprint_roulette_test.dart`（A-4 断言 `goal-position-save-<code>` / `goal-position-tags-toggle-<code>` 存在）
- `apps\desktop\test\task78_b9_brand_panel_test.dart`（worker A 日志指出它也依赖 `goal-position-save-*`）

## 二、已完成、**不要重做**的部分（worker B 的成果，analyze 干净）

- `apps\desktop\lib\src\widgets\goals\goal_blueprint_matrix.dart`：Chrome/Edge 风格标签页、单元格垂直边距加大、删除「条做法」「未落位」、`_periodText` 缺 period 时回退 `dueDate`。
- `apps\desktop\lib\src\widgets\goals\goal_form_dialog.dart`：due 字段改只读 + `showDatePicker`（本地午夜毫秒）。
- `apps\desktop\lib\src\pages\goals_blueprint_page.dart`：`_writeGoal` 同写 `periodEnd`。
- `apps\desktop\test\task66_goals_blueprint_page_test.dart`、`task74_goal_edit_shared_test.dart`：已按新行为改完。

⇒ 请**先读**这三个 lib 文件与 `task73` 当前内容，只在它们已有实现的基础上补缺口，不要推翻重写。

## 三、本 worker 的独占写集

- `apps\desktop\lib\src\widgets\goal_brand_panel.dart`（补齐）
- `apps\desktop\test\task73_b8_w1_blueprint_edit_test.dart`（修 `DatePicker`）
- `apps\desktop\test\b10_position_panel_test.dart`
- `apps\desktop\test\b11_blueprint_roulette_test.dart`
- `apps\desktop\test\task78_b9_brand_panel_test.dart`
- `apps\desktop\test\b12_position_panel_test.dart`（新建）

**绝对不得改**：`goal_blueprint_matrix.dart`、`goal_form_dialog.dart`、`goals_blueprint_page.dart`、`task66_*`、`task74_*`、`l10n\**`（含 `l10n_keys.dart`）、`theme\**`、`packages\**`、`docs\**`、`AGENTS.md`。

若 `b12_matrix_tabs_date_test.dart` 确认缺失，**不要创建**（矩阵侧已定稿，由控制器另行补齐或授权后再建）；只在报告里确认它不存在。

## 四、反馈 1 的目标行为（权威口径，不得改）

1. hint 说明文字**不常驻**；鼠标悬停在定位分类标题上时，在标题附近弹**自绘**浮层显示该条说明。禁止用 Flutter 默认 `Tooltip` 组件。配色只走 `theme_tokens.dart` 的 `LightPalette`（paper/card/ink/ink2/hair），禁渐变 / BoxShadow / 光晕 / 位图。指针进入浮层或回到标题不闪断；离开后短暂延迟消失。浮层不得遮挡输入。
2. 删除「保存/确认」按钮与「标签库」开关/链接的渲染、回调与 key（`goal-position-save-<code>`、`goal-position-tags-toggle-<code>`）。
3. 点击/聚焦输入框即展开标签库浮窗（保持 B11 契约：锚定输入框下方、放不下翻上方、指针入浮窗暂停 3 s、Esc/点外关闭、同 code 不叠加）。
4. 点击浮窗内标签 chip ⇒ 立即并入当前位置多值文本并落库（走原 `_save` 语义），状态行更新。
5. 回车（`onSubmitted`）⇒ 文本按 `、` `，` `,` 换行 拆分，合并后自动落库并清空输入框；**空文本回车不写库**。
6. 存储格式与既有分隔符一致；只有非空才写库。

## 五、验证要求

- 允许并能证明：`dart analyze` 针对性检查你改的文件（贴原始输出）。
- **不得运行** `flutter test` / `flutter build` / `flutter analyze`（会与控制器门禁争用 `build\test_cache`）；控制器统一亲跑。
- 交付时逐条对应第一节的 9 个 error，说明每个是怎么消掉的；列出你新建/修改的测试与用例名；明确哪些断言你**没有实际执行过**。
- 需要新 l10n key ⇒ 停下报告，不要改 l10n 文件。