// apps/desktop/test/ledger_checkbox_enter_test.dart
//
// Task 25 · W3：补 `docs\B1_验收记录.md` §5 遗留 #11 里「Enter 落在**勾选框**上」
// 这一格 —— 本轮之前只断言过「行级 Enter 开弹层」（A4）与「勾选框 Space 切勾选」（A6），
// 勾选框上的 Enter 在 widget 层**没有任何断言**。
//
// 产品语义（`lib/src/widgets/shell/key_bar.dart:29-30` +
// `lib/src/pages/today_page.dart:1273/:1281`）：
//  - 行级焦点 + `Space` ⇒ 切勾选；
//  - 行级焦点 + `Enter` ⇒ 开「成果 / 进展」回填弹层；
//  - **勾选框级**焦点 + `Space` 或 `Enter` ⇒ 就近切换勾选（`done ⇄ pending`），
//    **不**打开回填弹层。
//
// 所以这里要同时钉住两件事：
//  ① 状态真的翻了（两个方向都翻，且 `done_at` 跟着写 / 清）；
//  ② 弹层真的没出来 —— 并且用 E3 对照组证明「找不到弹层」不是判据本身瞎了。
//
// 断言全部读真库（`plan_item` 表），不用内存假态；每条用例都在 `finally` 里
// 卸界面放 drift 流订阅，避免某条失败后把后续用例连带打死。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/outcome_composer.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

/// 内存真库 + 真仓储 + 固定今天。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'ledger-checkbox-enter-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 挂今日页内容体（外包 `LedgerShell`，与真机一致）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LedgerShell(content: TodayPage(), currentNavId: 'today'),
        ),
      ),
    );
  }

  /// 建一条计划条目，返回它的 id；`done == true` 时顺手置成已完成。
  Future<String> addPlanItem(String title, {bool done = false}) async {
    final String id = await TimelineStore(repos).createManual(date: _today, title: title, startMinute: 9 * 60, endMinute: 10 * 60);
    if (done) {
      await repos.planItem.setStatus(id, PlanStatus.done);
    }
    return id;
  }

  /// 直接读库里的这一行。
  Future<PlanItemData> read(String id) async {
    return (await repos.planItem.listByDate(_today))
        .firstWhere((PlanItemData row) => row.id == id);
  }
}

/// 撑高测试面：今日页整页竖排三段，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
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
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 跑一条用例并在 `finally` 里收尾。
///
/// 断言失败时若跳过收尾，残存的 drift 流订阅会打到下一条用例头上，
/// 把「一条真失败」放大成「整批失败」—— 那会毁掉失败信息的指向性。
Future<void> _run(WidgetTester tester, Future<void> Function() body) async {
  try {
    await body();
  } finally {
    await _flushTimers(tester);
  }
}

/// 把 finder 限定在「今日计划」卡片内（习惯区也有复选框，全局找会串味）。
Finder _inPlanCard(Finder matching) {
  return find.descendant(
    of: find.byKey(const ValueKey<String>('day-grid')),
    matching: matching,
  );
}

/// 计划行的行级焦点节点（`ValueKey('plan-row-focus-<id>')`）。
FocusNode _rowNode(WidgetTester tester, String itemId) {
  final Focus focus = tester.widget<Focus>(
    find.byKey(ValueKey<String>('plan-row-focus-$itemId')),
  );
  return focus.focusNode!;
}

/// 计划行里勾选框自己的焦点节点（`LedgerCheckbox` 自带）。
FocusNode _checkboxNode(WidgetTester tester) {
  final List<FocusNode> nodes = tester
      .widgetList<Focus>(
        _inPlanCard(
          find.descendant(
            of: find.byType(LedgerCheckbox),
            matching: find.byType(Focus),
          ),
        ),
      )
      .map((Focus focus) => focus.focusNode)
      .whereType<FocusNode>()
      .toList(growable: false);
  expect(nodes, isNotEmpty, reason: 'LedgerCheckbox 必须自带可请求焦点的 FocusNode');
  return nodes.first;
}

/// 「成果 / 进展」回填弹层是否在场。
///
/// 三重判据（任一条命中即「弹了」）：标题文案、`OutcomeComposer`、`AlertDialog`。
void _expectNoComposer() {
  expect(find.text('成果 / 进展'), findsNothing, reason: '勾选框上的按键不得弹出回填层');
  expect(find.byType(OutcomeComposer), findsNothing);
  expect(find.byType(AlertDialog), findsNothing);
}

/// 把焦点放到勾选框上，并自证真的落上去了（否则按键会打到别处，断言失去意义）。
Future<FocusNode> _focusCheckbox(WidgetTester tester) async {
  final FocusNode box = _checkboxNode(tester);
  box.requestFocus();
  await tester.pump();
  expect(FocusManager.instance.primaryFocus, box, reason: '焦点必须真的在勾选框上');
  return box;
}

void main() {
  testWidgets('E1：Enter 落在勾选框 ⇒ pending → done，且不弹回填弹层', (tester) async {
    _useTallSurface(tester);
    await _run(tester, () async {
      final harness = _Harness.create();
      final String itemId = await harness.addPlanItem('框上回车勾我');
      await harness.mount(tester);
      await _settle(tester);

      expect(_inPlanCard(find.text('框上回车勾我')), findsOneWidget);
      final PlanItemData before = await harness.read(itemId);
      expect(before.status, PlanStatus.pending.code);
      expect(before.doneAt, isNull);

      final FocusNode box = await _focusCheckbox(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      final PlanItemData after = await harness.read(itemId);
      expect(after.status, PlanStatus.done.code, reason: '勾选框上的 Enter 必须切勾选');
      expect(after.doneAt, isNotNull, reason: '置 done 必须同时写 done_at');

      // 视觉侧也翻了：卡片内出现 ✓、○ 消失。
      expect(_inPlanCard(find.text('✓')), findsOneWidget);
      expect(_inPlanCard(find.text('○')), findsNothing);

      // 关键否定断言：没有打开「成果 / 进展」。
      _expectNoComposer();
      // 弹层若被 push，焦点会被 ModalRoute 的 scope 拿走；这里顺带钉死焦点没被劫持。
      expect(box.hasFocus, isTrue, reason: '没弹层 ⇒ 焦点应当仍在勾选框上');
    });
  });

  testWidgets('E2：Enter 落在勾选框 ⇒ done → pending（取消勾选），且不弹回填弹层', (
    tester,
  ) async {
    _useTallSurface(tester);
    await _run(tester, () async {
      final harness = _Harness.create();
      final String itemId = await harness.addPlanItem('框上回车取消我', done: true);
      await harness.mount(tester);
      await _settle(tester);

      final PlanItemData before = await harness.read(itemId);
      expect(before.status, PlanStatus.done.code, reason: '前置：这一行必须已经是 done');
      expect(before.doneAt, isNotNull);
      expect(_inPlanCard(find.text('✓')), findsOneWidget);

      await _focusCheckbox(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      final PlanItemData after = await harness.read(itemId);
      expect(after.status, PlanStatus.pending.code, reason: 'done 行上 Enter 必须取消勾选');
      expect(after.doneAt, isNull, reason: '回 pending 必须清 done_at');
      expect(_inPlanCard(find.text('○')), findsOneWidget);
      expect(_inPlanCard(find.text('✓')), findsNothing);

      _expectNoComposer();
    });
  });

  testWidgets('E3：对照组 —— 行级焦点上 Enter 确实弹出「成果 / 进展」（证明否定断言不是瞎的）', (
    tester,
  ) async {
    _useTallSurface(tester);
    await _run(tester, () async {
      final harness = _Harness.create();
      final String itemId = await harness.addPlanItem('行上回车开层');
      await harness.mount(tester);
      await _settle(tester);

      final FocusNode row = _rowNode(tester, itemId);
      row.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, row);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 同一套判据在这里必须看得见弹层 —— 否则 E1 / E2 的 `findsNothing` 毫无判别力。
      expect(find.text('成果 / 进展'), findsOneWidget);
      expect(find.byType(OutcomeComposer), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      // 顺带确认行级 Enter 不切勾选：弹层与状态切换是两件事。
      final PlanItemData after = await harness.read(itemId);
      expect(after.status, PlanStatus.pending.code, reason: '行级 Enter 只开层、不切勾选');
    });
  });

  testWidgets('E4：Space 落在勾选框 ⇒ done → pending（§5 #11⑤ 补强，对照 A6 的反向）', (
    tester,
  ) async {
    _useTallSurface(tester);
    await _run(tester, () async {
      final harness = _Harness.create();
      final String itemId = await harness.addPlanItem('框上空格取消我', done: true);
      await harness.mount(tester);
      await _settle(tester);

      await _focusCheckbox(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester);

      final PlanItemData after = await harness.read(itemId);
      expect(after.status, PlanStatus.pending.code, reason: '勾选框上的 Space 必须切勾选');
      expect(after.doneAt, isNull, reason: '回 pending 必须清 done_at');
      _expectNoComposer();
    });
  });
}