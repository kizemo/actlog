// =============================================================================
// B14 · 条目 2「目标内容就地编辑」判别性用例
// =============================================================================
// 判据（对应 docs\b14-dispatch.md §2）：
//  I2-1 点铅笔 ⇒ 格子内出现输入框（不再弹全量表单），预填旧标题且光标置末；
//  I2-2 回车提交 ⇒ 只把**新标题**交给 `onRenameGoal`，回调拿到的是旧行
//       （页面侧只 `updateGoal(title:)`，note / period_end 不会被重算或清空）；
//  I2-3 Esc 取消 ⇒ 不写库（回调零调用）且退出编辑态；
//  I2-4 拼音组合态回车 ⇒ 只上屏、不提交（IME 守卫）；
//  I2-5 空白 / 未修改 ⇒ 早退不写库；
//  I2-6 失焦 ⇒ 提交（点空白等于确认，不丢用户刚敲的字）；
//  I2-7 未传 `onRenameGoal` ⇒ 铅笔退回旧的全量弹窗（坑 48：既有调用点不变）。
//
// 口径：全部用 `tester` 的可观测事实（键 / 控制器状态 / 回调次数），不看截图。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_domain/core_domain.dart'
    show GoalHorizon, GoalKind, GoalStatus;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 被改名的目标 id（键名与矩阵一致）。
const String _goalId = 'b14-inline-1';

/// 旧标题（4 个字符，便于逐字断言光标落点）。
const String _oldTitle = '原始标题';

/// 一次 `onRenameGoal` 调用的快照。
class _RenameCall {
  const _RenameCall(this.goal, this.title);

  final GoalRow goal;
  final String title;
}

/// 就地编辑输入框。
Finder get _editor =>
    find.byKey(const ValueKey<String>('goal-blueprint-inline-$_goalId'));

/// 铅笔按钮。
Finder get _pencil =>
    find.byKey(const ValueKey<String>('goal-blueprint-edit-$_goalId'));

/// 一条 career × 终极档的矩阵行。
GoalBlueprintRow _careerRow() => GoalBlueprintRow(
  domainKey: 'career',
  cells: <GoalHorizon, List<GoalRow>>{
    GoalHorizon.ultimate: <GoalRow>[
      GoalRow(
        id: _goalId,
        kind: GoalKind.blueprint,
        title: _oldTitle,
        status: GoalStatus.active,
        periodStart: 0,
        periodEnd: 0,
        createdAt: 0,
        updatedAt: 0,
      ),
    ],
  },
);

/// 挂矩阵本体（形状抄 `b11_period_date_test.dart:49-62`）。
Widget _host({
  required void Function(GoalRow goal, String title) onRenameGoal,
  void Function(GoalRow goal)? onEditGoal,
}) => MaterialApp(
  theme: AppTheme.light(DensityProfile.comfortable),
  home: Scaffold(
    body: SingleChildScrollView(
      child: GoalBlueprintMatrix(
        t: AppLocalizations.zh,
        rows: <GoalBlueprintRow>[_careerRow()],
        serves: const GoalServesIndex(
          <String, List<GoalRow>>{},
          <String, List<GoalRow>>{},
        ),
        tracksCount: const <String, int>{},
        onSplitTodos: (GoalRow _) {},
        onEditGoal: onEditGoal,
        onRenameGoal: onRenameGoal,
      ),
    ),
  ),
);

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 挂起并进入就地编辑，返回回调收集桶。
Future<List<_RenameCall>> _enterInline(
  WidgetTester tester, {
  List<_RenameCall>? sink,
  List<GoalRow>? edits,
}) async {
  final List<_RenameCall> calls = sink ?? <_RenameCall>[];
  // 铅笔的**渲染**门槛是 `onEditGoal != null`（Task 66 坑 48 的既有口径），
  // 页面侧两个回调都传；测试也照此挂载，才能验证「有 onRenameGoal 就不弹窗」。
  final List<GoalRow> popups = edits ?? <GoalRow>[];
  _size(tester);
  await tester.pumpWidget(
    _host(
      onRenameGoal: (GoalRow goal, String title) =>
          calls.add(_RenameCall(goal, title)),
      onEditGoal: popups.add,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(_pencil);
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  testWidgets('I2-1 点铅笔进入就地编辑：预填旧标题且光标置末', (WidgetTester tester) async {
    final List<GoalRow> edits = <GoalRow>[];
    final List<_RenameCall> calls = await _enterInline(tester, edits: edits);

    expect(_editor, findsOneWidget, reason: '格内应出现就地编辑框');
    expect(edits, isEmpty, reason: '有 onRenameGoal 时不得再弹全量表单');

    final TextField field = tester.widget<TextField>(_editor);
    final TextEditingController controller = field.controller!;
    expect(controller.text, _oldTitle);
    expect(
      controller.selection,
      TextSelection.collapsed(offset: _oldTitle.length),
      reason: '预填后光标置末（D9：不抢全选，免得一敲键就删掉整条标题）',
    );
    expect(calls, isEmpty);
  });

  testWidgets('I2-2 回车只提交新标题，且回调拿到的是旧行（未被改写）', (
    WidgetTester tester,
  ) async {
    final List<GoalRow> edits = <GoalRow>[];
    final List<_RenameCall> calls = await _enterInline(tester, edits: edits);

    await tester.enterText(_editor, '修订标题');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(calls.length, 1);
    expect(calls.single.title, '修订标题');
    expect(calls.single.goal.id, _goalId);
    // 回调拿到的是**改之前**那一行：页面侧据此只写 title。
    expect(calls.single.goal.title, _oldTitle);
    expect(edits, isEmpty, reason: '就地提交不得回落到全量弹窗链路');
    expect(_editor, findsNothing, reason: '提交后应退出编辑态');
    // 原文字仍在（页面没有真的写库，矩阵只是把新值交给回调）。
    expect(find.text(_oldTitle), findsOneWidget);
  });

  testWidgets('I2-3 Esc 取消：零写入且退出编辑态', (WidgetTester tester) async {
    final List<_RenameCall> calls = await _enterInline(tester);

    await tester.enterText(_editor, '不要保存');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(calls, isEmpty, reason: 'Esc 是放弃，不是提交');
    expect(_editor, findsNothing);
    expect(find.text(_oldTitle), findsOneWidget);
  });

  testWidgets('I2-4 拼音组合态不提交，上屏完成才提交', (WidgetTester tester) async {
    final List<_RenameCall> calls = await _enterInline(tester);

    // 组合态（拼音还在候选窗里）只上屏：不得提交、不得退出编辑态。
    // 注：这条路不能用 receiveAction(done) 模拟——EditableText 在调用 onSubmitted
    // 之前就 clearComposing() 了，组合态只能用 updateEditingValue 直接喂。
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'xiu',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ),
    );
    await tester.pump();

    expect(calls, isEmpty, reason: '组合态只上屏，不得提交');
    expect(_editor, findsOneWidget, reason: '组合态期间应继续编辑');

    // 上屏完成（无组合态）后回车才算提交。
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '修订',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(calls.length, 1);
    expect(calls.single.title, '修订');
  });

  testWidgets('I2-5 空白与未修改都早退，不写库', (WidgetTester tester) async {
    final List<_RenameCall> calls = await _enterInline(tester);

    await tester.enterText(_editor, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '空白标题不得写库');
    expect(_editor, findsNothing);

    await tester.tap(_pencil);
    await tester.pumpAndSettle();
    await tester.enterText(_editor, _oldTitle);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(calls, isEmpty, reason: '未修改不得写库');
  });

  testWidgets('I2-6 失焦即提交（点空白不丢刚敲的字）', (WidgetTester tester) async {
    final List<_RenameCall> calls = await _enterInline(tester);

    await tester.enterText(_editor, '失焦提交');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(calls.length, 1);
    expect(calls.single.title, '失焦提交');
    expect(_editor, findsNothing);
  });

  testWidgets('I2-7 未传 onRenameGoal ⇒ 铅笔退回全量弹窗（坑 48）', (
    WidgetTester tester,
  ) async {
    final List<GoalRow> edits = <GoalRow>[];
    _size(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalBlueprintMatrix(
              t: AppLocalizations.zh,
              rows: <GoalBlueprintRow>[_careerRow()],
              serves: const GoalServesIndex(
                <String, List<GoalRow>>{},
                <String, List<GoalRow>>{},
              ),
              tracksCount: const <String, int>{},
              onSplitTodos: (GoalRow _) {},
              onEditGoal: edits.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_pencil);
    await tester.pumpAndSettle();

    expect(edits.length, 1, reason: '旧链路：点铅笔打开全量表单');
    expect(_editor, findsNothing, reason: '旧链路不得出现就地编辑框');
  });
}