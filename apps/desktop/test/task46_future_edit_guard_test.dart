// apps/desktop/test/task46_future_edit_guard_test.dart
//
// Task 46 · W2：未来日（预排日）的编辑边界。
//
// 用户当轮口径：
//   **未来日预排条目 → 开放改标题 / 详情 / 删除；
//     打卡 / 回填 / 复盘 / 心态仍只限今天与过去。**
//
// 本文件盯的六条：
//   A. 未来日：标题可改并落库（`plan_item.title`）；
//   B. 未来日：内容可改并落库（`plan_item.detail`）—— 与 A 一起证明
//      「排期本身的编辑」真的放开了，不是只放开一半；
//   C. 未来日：回填框禁用 + 锁定提示可见 + 模板按钮 disabled，保存后
//      `result_note` 一个字节没变（双重守卫：窗内禁用 + 调用方拒绝写入）；
//   D. 未来日：勾选框仍 disabled（「完成」是事实，未来日不该有）；
//   E. 未来日：删除仍可执行（二次确认 → 软删）；
//   F. 今天与过去：回填照常可写 —— 守卫不能误伤正常补录。
//
// 日期一律由 `DateTime.now()` 派生（`isoDate`），**不硬编码绝对日期**：
// 写死 2026-11-xx 会在真实跨日后变成「过去」，断言随之失真。
//
// 脚手架照抄 `timeline_plan_detail_test.dart`：真库 + 真 provider，
// **禁用 `pumpAndSettle`**（drift 流订阅会把 `pumpAndSettle` 挂到超时），
// 改用量化 pump 的 `_settle`。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/widgets/timeline/todo_rail_panel.dart';

/// 「今天」：真实当天。派工书要求按本地日期判定，测试不得硬编码绝对日期。
final String _today = isoDate(DateTime.now());

/// 未来日：三天后（足够远离跨零点边界）。
final String _future = isoDate(DateTime.now().add(const Duration(days: 3)));

/// 过去日：昨天（补录场景，回填必须仍可写）。
final String _past = isoDate(DateTime.now().subtract(const Duration(days: 1)));

const ValueKey<String> _kTitle = ValueKey<String>('plan-detail-title');
const ValueKey<String> _kContent = ValueKey<String>('plan-detail-content');
const ValueKey<String> _kNote = ValueKey<String>('plan-detail-note');
const ValueKey<String> _kNoteLocked = ValueKey<String>(
  'plan-detail-note-locked',
);
const ValueKey<String> _kTemplate = ValueKey<String>('plan-detail-template');
const ValueKey<String> _kDelete = ValueKey<String>('plan-detail-delete');
const ValueKey<String> _kSave = ValueKey<String>('plan-detail-save');
const ValueKey<String> _kConfirmConfirm = ValueKey<String>(
  'confirm-dialog-confirm',
);

final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task46-guard-test');
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

  /// 右轨 `TodoRailPanel` 必须一起挂：`todoPoolProvider` 只有被 watch 过才是
  /// `asData`，否则网格里的待办携带分支会拿到空列表（与既有测试同口径）。
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
                SizedBox(width: 240, child: TodoRailPanel()),
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

Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _seed(
  _Harness harness, {
  required String title,
  required String date,
  int startMinute = 9 * 60,
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
  _Harness harness,
  String date,
) async {
  final List<PlanItemData> plans = (await tester.runAsync(
    () => harness.repos.planItem.listByDate(date),
  ))!;
  expect(plans, hasLength(1));
  return plans.single;
}

Finder _entryOf(String planItemId) =>
    find.byKey(ValueKey<String>('day-grid-entry-$planItemId'));

Future<void> _openDetail(WidgetTester tester, String planItemId) async {
  await tester.tap(_entryOf(planItemId));
  await _settle(tester);
  expect(
    find.text('任务详情'),
    findsOneWidget,
    reason: '点条目没有打开详情窗',
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(_kSave));
  await _settle(tester);
}

void main() {
  testWidgets('A. 未来日：标题可改并落库（plan_item.title）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seed(harness, title: '预排原标题', date: _future);
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    await _openDetail(tester, plan.id);

    // 标题是真输入框，初值 = 库里的标题，且没有被禁用。
    final TextField titleField = tester.widget<TextField>(find.byKey(_kTitle));
    expect(titleField.controller?.text, '预排原标题');
    expect(titleField.enabled, isNot(false), reason: '未来日标题不该被禁用');

    await tester.enterText(find.byKey(_kTitle), '预排改后标题');
    await _save(tester);

    final PlanItemData after = await _onlyPlan(tester, harness, _future);
    expect(after.title, '预排改后标题', reason: '未来日改标题没有落库');
    expect(after.detail, isEmpty, reason: '改标题不该顺手写内容');
    expect(after.resultNote, isEmpty, reason: '改标题不该顺手写回填');

    await _flushTimers(tester);
  });

  testWidgets('B. 未来日：内容可改并落库（plan_item.detail）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seed(harness, title: '预排写内容', date: _future);
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    await _openDetail(tester, plan.id);

    await tester.enterText(find.byKey(_kContent), '明天的议程');
    await _save(tester);

    final PlanItemData after = await _onlyPlan(tester, harness, _future);
    expect(after.detail, '明天的议程', reason: '未来日改内容没有落库');
    expect(after.title, '预排写内容', reason: '改内容不该顺手改标题');

    await _flushTimers(tester);
  });

  testWidgets('C. 未来日：回填被拒（框禁用 + 锁定提示 + 保存不写 result_note）',
      (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seed(harness, title: '预排别回填', date: _future);
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    await _openDetail(tester, plan.id);

    // 控件层：回填框禁用、模板按钮 disabled、锁定提示可见。
    expect(
      tester.widget<TextField>(find.byKey(_kNote)).enabled,
      isFalse,
      reason: '未来日回填框必须禁用（打卡 / 回填 / 复盘 / 心态只限今天与过去）',
    );
    expect(
      tester.widget<TextButton>(find.byKey(_kTemplate)).onPressed,
      isNull,
      reason: '未来日不该能打开「成果 / 进展模板」',
    );
    expect(
      find.byKey(_kNoteLocked),
      findsOneWidget,
      reason: '未来日缺可见的锁定提示（用户要知道为什么填不了）',
    );
    expect(find.textContaining('只允许今天与过去'), findsOneWidget);

    // 数据层：即便点了保存，`result_note` 一个字节都不该变。
    await _save(tester);
    final PlanItemData after = await _onlyPlan(tester, harness, _future);
    expect(after.resultNote, isEmpty, reason: '未来日把回填写进了库');
    expect(after.title, '预排别回填', reason: '保存回填分支不该误改标题');

    await _flushTimers(tester);
  });

  testWidgets('D. 未来日：勾选框仍 disabled（「完成」入口没被放开）',
      (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seed(harness, title: '预排别打勾', date: _future);
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    final Finder boxes = find.descendant(
      of: _entryOf(plan.id),
      matching: find.byType(LedgerCheckbox),
    );
    expect(boxes, findsOneWidget);
    expect(
      tester.widget<LedgerCheckbox>(boxes).onChanged,
      isNull,
      reason: '未来日的勾选框必须保持禁用',
    );

    await _flushTimers(tester);
  });

  testWidgets('E. 未来日：删除仍可执行（二次确认 → 软删）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await _seed(harness, title: '预排删我', date: _future);
    await harness.mount(tester, _future);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    await _openDetail(tester, plan.id);

    await tester.tap(find.byKey(_kDelete));
    await _settle(tester);
    final Finder confirm = find.byKey(_kConfirmConfirm);
    expect(confirm, findsOneWidget, reason: '未来日删除也必须先二次确认');

    await tester.tap(confirm);
    await _settle(tester);

    expect(find.text('任务详情'), findsNothing);
    final List<PlanItemData> left = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_future),
    ))!;
    expect(left, isEmpty, reason: '未来日确认后没有软删');

    await _flushTimers(tester);
  });

  for (final String day in <String>[_today, _past]) {
    testWidgets('F. $day：回填照常可写（守卫不误伤今天 / 补录）', (tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: day);
      await _seed(harness, title: '可以回填', date: day);
      await harness.mount(tester, day);
      await _settle(tester);

      final PlanItemData plan = await _onlyPlan(tester, harness, day);
      await _openDetail(tester, plan.id);

      expect(
        tester.widget<TextField>(find.byKey(_kNote)).enabled,
        isTrue,
        reason: '今天与过去的回填框必须是可写的',
      );
      expect(find.byKey(_kNoteLocked), findsNothing);

      await tester.enterText(find.byKey(_kNote), '回填内容可写');
      await _save(tester);

      final PlanItemData after = await _onlyPlan(tester, harness, day);
      expect(after.resultNote, '回填内容可写', reason: '今天 / 过去的回填没有落库');

      await _flushTimers(tester);
    });
  }
}