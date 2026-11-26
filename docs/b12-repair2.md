# B12 修复派工书 2（收口前最后一轮）

> 本文件是**控制器**写给修复 worker 的派工书。源码改动一律由 worker 落盘，控制器只读。

## 背景

B12 三条用户反馈的实现已全部落盘，`flutter analyze` 逐字绿（`No issues found!`）。
全量 `flutter test` 仍有失败，必须清零才能出包。

## 失败 1：B5「聚焦输入框（不点击）⇒ 标签浮窗展开并钉住」

- 用例：`apps/desktop/test/b12_position_panel_test.dart:242`，失败点 `:253`
  （`Found 0 widgets with key ['goal-position-tags-overlay']`）。
- 对照：同文件 **B6（点输入框）通过** ⇒ `_openTags` 机制、锚点、Overlay 插入都正常。
- 已排除：`_tagsFor(t,'strengths')` 非空（VIA 24 项，`lib/src/l10n/parts/goals.dart:1201`），
  不会在 `_openTags:426` 早退。
- 两个候选，按顺序判：
  1. **假红**：用例只 `await tester.pump()` 一帧。`FocusNode.requestFocus()` 的焦点变化
     由 FocusManager 在 microtask 里应用，浮层 `OverlayEntry` 还需要一帧才建出来。
     ⇒ 先补第二帧 `await tester.pump()` 复跑；绿了就判假红，并在用例注释写明「需要两帧」。
  2. **真缺陷**：`_onFocusChanged`（`goal_brand_panel.dart:551`）没被调到。
     ⇒ 再改 lib 兜底（例如给 `TextField` 加 `onTapAlwaysCalled`、或用 `Focus` 包一层
     监听 `onFocusChange`），并在回报里说明为什么外置 `FocusNode` 监听不可靠。
- 判定顺序不许颠倒：**先证伪测试，再改实现**。

## 失败 2：T4 断言与「并入」语义冲突（**语义已裁决，禁止改实现**）

- 用例：`apps/desktop/test/task78_b9_brand_panel_test.dart:199`
  （`Expected: '第二版'` / `Actual: '第一版、第二版'`）。
- 裁决依据：用户反馈 1 原话「手动输入，回车自动录入保存，**以符号分隔**」⇒ 回车 =
  **往已有内容上并入**（实现 `_mergedTags` :349、`_submitTags` :395-413 一致），不覆盖整值。
- 动作：
  1. 断言改成 `'第一版、第二版'`；
  2. 用例名与注释改成「再次回车 = 并入，不覆盖」，删掉「整值覆盖」的旧说法；
  3. 补一条「同值重复回车不重复追加」的断言（`_mergedTags` 若已去重，这条应直接绿；
     若发现重复追加，属于真缺陷，回报控制器，不许自行改语义）。

## 失败 3：`b10_blueprint_matrix_done_test.dart` 的 B1（旧视觉断言与新标签页冲突）

- 用例：`apps/desktop/test/b10_blueprint_matrix_done_test.dart` —「B1 标签页激活态：
  inkWash 浅洗底 pill + ink/w600；未激活无底色 + meta」。
- 成因：反馈 2 把标签页改成 Chrome/Edge 融合式（活动页与内容区同色、顶部圆角 8px），
  旧断言仍按「pill + inkWash」找。
- 动作：**只改测试**（lib 已定稿、analyze 绿）。先读 `goal_blueprint_matrix.dart` 里标签页的
  当前真实实现（底色 token / 圆角 / 字重 / meta 是否还在），把断言改成**钉新契约**，
  不许降低强度（不许整段删断言、不许改成 `findsWidgets` 了事）：底色照 `theme_tokens.dart`
  的真实 token 断，圆角要断 8px 这一条**唯一例外**，未激活页仍要断「无同款底色」。

## 失败 4：`b12_matrix_tabs_date_test.dart` R2-5（正例控制写太死）

- 现象：`Found 2 widgets with text containing 周目标` ⇒ `findsOneWidget` 失败。
- 判定：**测试假红**（同一文案在卡片与格内各出现一次）。动作：正例控制改成
  `findsWidgets`（或 `findsAtLeastNWidgets(1)`），**不许**删掉这条控制断言。

## 失败 5：`b12_matrix_tabs_date_test.dart` R2-6（`EdgeInsets.horizontal` 语义）

- 现象：`Expected: <8>` / `Actual: <16.0>`。
- 判定：**测试写法错**：`EdgeInsets.symmetric(horizontal: 8, vertical: 11).horizontal` == 16
  （左右相加）。动作：改成断 `cellPadding.left == 8 && cellPadding.right == 8`（或
  `horizontal == 16`）；vertical 那半保持 `> 4` 的强度。

## 复跑口径

每个文件各跑一次单文件；最后控制器跑全量，期望 **`+1000: All tests passed!`**
（986 基线 + 8 个 B12 面板用例 + 6 个矩阵用例）。

## 写集（**只准动这些文件**）

- `apps/desktop/test/b12_position_panel_test.dart`（B5）
- `apps/desktop/test/task78_b9_brand_panel_test.dart`（T4）
- `apps/desktop/test/b10_blueprint_matrix_done_test.dart`（B1）
- `apps/desktop/test/b12_matrix_tabs_date_test.dart`（R2-5 / R2-6）
- `apps/desktop/lib/src/widgets/goal_brand_panel.dart`（仅当 B5 判为真缺陷时）
- 除此之外一个文件都不许动（不许顺手重构无关用例）

## 禁止

- 不改 `goal_blueprint_matrix.dart` / `goals/goal_form_dialog.dart` / `goals_blueprint_page.dart`（已定稿）
- 不跑 `flutter analyze` / `flutter build` / **全量** `flutter test`（并发污染 `.dart_tool` 与
  `build/test_cache`，门禁由控制器亲跑）；只准 `flutter test <单个文件>`
- 不删文件、不做 git 操作、不碰 `docs/` 与 `AGENTS.md`
- 不引入 `print(`，Dart 源保持 LF、无 BOM

## 交付格式

1. 逐条：失败用例名 → 判定（假红/真缺陷）→ 证据（跑的是哪个文件、改前改后差异）→ 改了什么
2. 单文件复跑的最后一行计数（`All tests passed!` 原样贴）
3. 你改过的每个 `.dart` 文件跑 `dart analyze <file>` 的结果（逐字 `No issues found!`）