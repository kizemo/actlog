// apps/desktop/test/timeline_plan_detail_test.dart
//
// Task 45 · W2 · 需求 2：左键 / `Enter` 打开的是**任务详情 / 编辑窗**，
// 且 chip 右侧的「未分级 / 删除 / 状态词」已经清掉。
//
// 九条断言（对应派工书 §3）：
//   1. 左键点已填任务 ⇒ 出详情窗（标题「任务详情」），不是「成果 / 进展」层；
//   2. 窗内六块齐备（标题只读 / 内容 / 级别 / 回填内容 / 持续时间 / 删除）；
//   3. 内容可编辑并落库（`plan_item.detail`）；
//   4. 级别可编辑并落库（Q1 ⇄ 未分级）；
//   5. 回填内容可编辑并落库（`plan_item.result_note`）；
//   6. 持续时间可编辑并落库（`planned_start` / `planned_end` + 「共 N 分钟」）；
//   7. 删除先二确认：取消不动库、确认后条目消失；
//   8. chip 上不再有「删除 / 未分级 / 回填」文字；
//   9. `Enter` 开的也是详情窗。
//
// 与 `timeline_day_grid_test.dart` 同一套脚手架口径：真库 + 真 provider，
// **禁用 `pumpAndSettle`**（drift 流订阅会把 `pumpAndSettle` 挂到超时），
// 改为 `_settle` 的「runAsync 让真实 IO 跑 + 定量 pump」。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/priority_marks.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/widgets/timeline/todo_rail_panel.dart';

/// 固定「今天」；被测日期就是它（过去 / 未来与详情窗无关，取当天最直接）。
const String _today = '2026-11-09';

/// 未来日（预排日）：Task 45 · W6 起也**必须**能开详情窗编辑 / 删除。
const String _future = '2026-11-12';

const ValueKey<String> _kContent = ValueKey<String>('plan-detail-content');
const ValueKey<String> _kNote = ValueKey<String>('plan-detail-note');
const ValueKey<String> _kDelete = ValueKey<String>('plan-detail-delete');
const ValueKey<String> _kSave = ValueKey<String>('plan-detail-save');
const ValueKey<String> _kDuration = ValueKey<String>('plan-detail-duration');
const ValueKey<String> _kStart = ValueKey<String>('plan-detail-start');
const ValueKey<String> _kEnd = ValueKey<String>('plan-detail-end');
const ValueKey<String> _kTitle = ValueKey<String>('plan-detail-title');
const ValueKey<String> _kPickerImportant = ValueKey<String>(
  'priority-mark-picker-important',
);
const ValueKey<String> _kPickerUrgent = ValueKey<String>(
  'priority-mark-picker-urgent',
);
const ValueKey<String> _kPickerClear = ValueKey<String>(
  'priority-mark-picker-clear',
);
const ValueKey<String> _kConfirmCancel = ValueKey<String>(
  'confirm-dialog-cancel',
);
const ValueKey<String> _kConfirmConfirm = ValueKey<String>(
  'confirm-dialog-confirm',
);

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'plan-detail-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 右轨的 `TodoRailPanel` 不是装饰：`todoPoolProvider` 只有被 watch 过才是
  /// `asData`，否则网格里的待办携带分支会拿到空列表（与 W1 同一口径）。
  Future<void> mount(WidgetTester tester, String date) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: DayGrid(date: date)),
                SizedBox(
                  width: 240,
                  child: TodoRailPanel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（**不能**用 `pumpAndSettle`：drift 流会让它挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 走真仓储落一条「已排期」计划（待办 + 计划行一起建），不碰任何界面。
Future<void> _seedPlan(
  _Harness harness, {
  required String title,
  required int startMinute,
  String date = _today,
}) async {
  await TimelineStore(harness.repos).createTodoWithSlot(
    date: date,
    title: title,
    startMinute: startMinute,
    endMinute: startMinute + 15,
  );
}

Future<PlanItemData> _onlyPlan(
  WidgetTester tester,
  _Harness harness, [
  String date = _today,
]) async {
  final List<PlanItemData> plans = (await tester.runAsync(
    () => harness.repos.planItem.listByDate(date),
  ))!;
  expect(plans, hasLength(1));
  return plans.single;
}

Finder _entryOf(String planItemId) =>
    find.byKey(ValueKey<String>('day-grid-entry-$planItemId'));

/// 点条目 → 等详情窗动画走完。
Future<void> _openDetail(WidgetTester tester, String planItemId) async {
  await tester.tap(_entryOf(planItemId));
  await _settle(tester);
  expect(
    find.text('任务详情'),
    findsOneWidget,
    reason: '左键点已填任务没有打开详情窗',
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(_kSave));
  await _settle(tester);
}

void main() {
  testWidgets('1. 左键点已填任务 ⇒ 出详情窗（不是「成果 / 进展」层）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '开会', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    await _openDetail(tester, plan.id);

    // 旧行为必须真的退场：不再是 `OutcomeComposer` 那层。
    expect(find.text('成果 / 进展'), findsNothing);
    expect(find.byKey(_kContent), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('2. 窗内六块齐备：标题 / 内容 / 级别 / 回填 / 持续 / 删除', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '六块都在', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    await _openDetail(tester, plan.id);

    // ① 标题只读：是一个 `Text`，没有 `TextField`。
    final Finder title = find.byKey(_kTitle);
    expect(title, findsOneWidget, reason: '缺标题');
    expect(tester.widget<Text>(title).data, '六块都在');
    expect(
      find.descendant(of: title, matching: find.byType(TextField)),
      findsNothing,
      reason: '标题按规格只读',
    );
    // ② 内容
    expect(find.byKey(_kContent), findsOneWidget, reason: '缺内容框');
    // ③ 级别
    expect(
      find.byType(PriorityMarkPicker),
      findsOneWidget,
      reason: '缺级别选择器',
    );
    // ④ 回填内容
    expect(find.byKey(_kNote), findsOneWidget, reason: '缺回填内容框');
    // ⑤ 持续时间：开始 / 结束 / 分钟数
    expect(find.byKey(_kStart), findsOneWidget, reason: '缺开始时间');
    expect(find.byKey(_kEnd), findsOneWidget, reason: '缺结束时间');
    expect(tester.widget<Text>(find.byKey(_kDuration)).data, '共 15 分钟');
    // ⑥ 删除
    expect(find.byKey(_kDelete), findsOneWidget, reason: '缺删除按钮');

    await _flushTimers(tester);
  });

  testWidgets('3. 内容可编辑并落库（plan_item.detail）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '写内容', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    expect(plan.detail, isEmpty, reason: '预置条件：内容本来是空的');

    await _openDetail(tester, plan.id);
    await tester.enterText(find.byKey(_kContent), '三条结论');
    await _save(tester);

    final PlanItemData row = await _onlyPlan(tester, harness);
    expect(row.detail, '三条结论');
    expect(
      row.title,
      '写内容',
      reason: '写内容不得顺带改标题（只写变化列）',
    );

    await _flushTimers(tester);
  });

  testWidgets('4. 级别可编辑并落库：选 Q1，再清回未分级', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '定级别', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    expect(plan.quadrant, isNull, reason: '预置条件：本来未分级');

    // 先点「重要」再点「紧急」⇒ 无论空值默认轴取什么，两次点击后必是 Q1。
    await _openDetail(tester, plan.id);
    await tester.tap(find.byKey(_kPickerImportant));
    await tester.pump();
    await tester.tap(find.byKey(_kPickerUrgent));
    await tester.pump();
    await _save(tester);

    expect((await _onlyPlan(tester, harness)).quadrant, Quadrant.q1.code);

    // 再开一次：清除 ⇒ null。
    final PlanItemData q1 = await _onlyPlan(tester, harness);
    await _openDetail(tester, q1.id);
    final Finder clear = find.byKey(_kPickerClear);
    expect(clear, findsOneWidget, reason: '有级别时必须有「清除」项');
    await tester.tap(clear);
    await tester.pump();
    await _save(tester);

    expect((await _onlyPlan(tester, harness)).quadrant, isNull);

    await _flushTimers(tester);
  });

  testWidgets('5. 回填内容可编辑并落库（result_note），且不改 status', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '写回填', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    await _openDetail(tester, plan.id);
    await tester.enterText(find.byKey(_kNote), '完成 3 项');
    await _save(tester);

    final PlanItemData row = await _onlyPlan(tester, harness);
    expect(row.resultNote, '完成 3 项');
    expect(
      row.status,
      plan.status,
      reason: '回填内容只写 result_note，「完成」交给勾选框',
    );

    await _flushTimers(tester);
  });

  testWidgets('6. 持续时间可编辑并落库（planned_start / planned_end）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '改时长', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    expect(plan.plannedStart, 9 * 60);
    expect(plan.plannedEnd, 9 * 60 + 15);

    await _openDetail(tester, plan.id);
    expect(tester.widget<Text>(find.byKey(_kDuration)).data, '共 15 分钟');
    // 结束 +1 格 ⇒ 09:30，共 30 分钟。
    await tester.tap(find.byTooltip('结束 加一格'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(_kEnd)).data,
      '09:30',
      reason: '结束时间没按 15 分钟粒度走',
    );
    expect(tester.widget<Text>(find.byKey(_kDuration)).data, '共 30 分钟');
    // 开始 +1 格 ⇒ 09:15，共 15 分钟。
    await tester.tap(find.byTooltip('开始 加一格'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(_kStart)).data, '09:15');
    expect(tester.widget<Text>(find.byKey(_kDuration)).data, '共 15 分钟');
    // 再推结束到 09:45，最终区间 09:15–09:45。
    await tester.tap(find.byTooltip('结束 加一格'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(_kDuration)).data, '共 30 分钟');
    await _save(tester);

    final PlanItemData row = await _onlyPlan(tester, harness);
    expect(row.plannedStart, 9 * 60 + 15);
    expect(row.plannedEnd, 9 * 60 + 45);
    expect(row.id, plan.id, reason: '改时长不该新建行');

    await _flushTimers(tester);
  });

  testWidgets('7. 删除先二次确认：取消不动库、确认后条目消失', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '删我', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    await _openDetail(tester, plan.id);

    // ---- 取消分支 ----
    await tester.tap(find.byKey(_kDelete));
    await _settle(tester);
    final Finder cancel = find.byKey(_kConfirmCancel);
    expect(cancel, findsOneWidget, reason: '删除没有确认环节');
    await tester.tap(cancel);
    await _settle(tester);
    expect(cancel, findsNothing);
    expect(find.text('任务详情'), findsOneWidget, reason: '取消删除不该关掉详情窗');
    await _onlyPlan(tester, harness);

    // ---- 确认分支 ----
    await tester.tap(find.byKey(_kDelete));
    await _settle(tester);
    await tester.tap(find.byKey(_kConfirmConfirm));
    await _settle(tester);

    expect(find.text('任务详情'), findsNothing, reason: '确认后详情窗还挂着');
    expect(_entryOf(plan.id), findsNothing, reason: '确认后条目仍在');
    final List<PlanItemData> left = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    ))!;
    expect(left, isEmpty, reason: '确认后没有软删');

    await _flushTimers(tester);
  });

  testWidgets('8. chip 上不再有「删除 / 未分级 / 回填」文字', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '干净行', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    final Finder entry = _entryOf(plan.id);
    expect(entry, findsOneWidget);

    for (final String word in <String>['删除', '未分级', '回填']) {
      expect(
        find.descendant(of: entry, matching: find.text(word)),
        findsNothing,
        reason: 'chip 上还留着「$word」（需求 2 要求清掉）',
      );
    }
    // 状态词「计划」也不该再出现在条目里（四态字形仍保留，另一条用例钉住）。
    expect(
      find.descendant(of: entry, matching: find.text('计划')),
      findsNothing,
      reason: '状态词「计划」应随状态词一并移除',
    );

    await _flushTimers(tester);
  });

  testWidgets('9. Enter 打开的是详情窗', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, title: '键盘开窗', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness);
    final FocusNode row = tester
        .widget<Focus>(find.byKey(ValueKey<String>('plan-row-focus-${plan.id}')))
        .focusNode!;
    row.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('任务详情'), findsOneWidget);
    expect(find.text('成果 / 进展'), findsNothing);
    expect(find.byKey(_kContent), findsOneWidget);

    await _flushTimers(tester);
  });

  // ---------------------------------------------------------------------------
  // Task 45 · W6：未来日（预排日）的两个入口必须与当天一致。
  //
  // 缺陷背景：W2 把「删除 / 回填 / 分级」从 chip 搬进本详情窗后，`day_grid.dart`
  // 里 `canRequestFocus: !_future` / `onTap: _future ? null : ...` /
  // `_openDetail` 开头的 `if (_future) return;` 三处旧拦截没跟着撤 ⇒ 明天 / 后天
  // 预排的条目既改不了级别 / 内容 / 时长，也删不掉。
  // 收窄后的口径：**只拦「完成 / 打勾」**，编辑与删除对未来日开放。
  // ---------------------------------------------------------------------------

  testWidgets('10. 未来日左键点条目 ⇒ 出详情窗，但「完成」入口仍禁用', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seedPlan(
      harness,
      title: '明天：评审',
      startMinute: 9 * 60,
      date: _future,
    );
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);

    // 前置判据：「完成」的唯一主入口是 chip 左侧勾选框 —— 未来日必须锁死。
    final Finder boxes = find.descendant(
      of: _entryOf(plan.id),
      matching: find.byType(LedgerCheckbox),
    );
    expect(boxes, findsOneWidget);
    expect(
      tester.widget<LedgerCheckbox>(boxes).onChanged,
      isNull,
      reason: '未来日的勾选框必须保持禁用（本修复不放开「完成」）',
    );

    // 左键点条目：旧实现 `onTap` 为 null，这一步什么也不会发生。
    await tester.tap(_entryOf(plan.id));
    await _settle(tester);

    expect(find.text('任务详情'), findsOneWidget, reason: '未来日点条目没开详情窗');
    final Finder title = find.byKey(_kTitle);
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).data, '明天：评审');
    expect(find.byKey(_kContent), findsOneWidget);
    expect(find.byKey(_kDelete), findsOneWidget);

    // 窗内没有任何「完成」类控件 —— 未来日不可能借详情窗伪造「做完了」。
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('完成'),
      ),
      findsNothing,
      reason: '详情窗里不该有「完成」入口（未来日尤其不该有）',
    );

    // 库层同一条事实：只是开了窗，一个字节都没写。
    final PlanItemData after = await _onlyPlan(tester, harness, _future);
    expect(after.status, PlanStatus.pending.code);
    expect(after.doneAt, isNull);

    await _flushTimers(tester);
  });

  testWidgets('11. 未来日点删除 ⇒ 二次确认 ⇒ 条目从网格消失', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seedPlan(
      harness,
      title: '后天：删我',
      startMinute: 9 * 60,
      date: _future,
    );
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    final Finder entry = _entryOf(plan.id);
    expect(entry, findsOneWidget);

    await tester.tap(entry);
    await _settle(tester);
    expect(find.text('任务详情'), findsOneWidget);

    await tester.tap(find.byKey(_kDelete));
    await _settle(tester);
    final Finder confirm = find.byKey(_kConfirmConfirm);
    expect(confirm, findsOneWidget, reason: '未来日删除也必须先二次确认');

    await tester.tap(confirm);
    await _settle(tester);

    expect(find.text('任务详情'), findsNothing, reason: '确认后详情窗还挂着');
    expect(entry, findsNothing, reason: '未来日确认删除后条目仍在网格上');
    final List<PlanItemData> left = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_future),
    ))!;
    expect(left, isEmpty, reason: '未来日确认后没有软删');

    await _flushTimers(tester);
  });
}