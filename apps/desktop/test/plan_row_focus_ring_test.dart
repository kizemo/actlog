// apps/desktop/test/plan_row_focus_ring_test.dart
//
// Task 26（台账 `docs/B1_验收记录.md` §5 #17）：今日页计划行的**行级焦点**
// 必须有可见焦点环。口径：复用 `FocusRing`（`--ink` 2px，TOKENS §5），
// **不改任何键位语义**。
//
// 六条断言：
//  T1 行级焦点 ⇒ 行级环点亮（ink 2px）；
//  T2 失焦 ⇒ 行级环熄灭（transparent）；
//  T3 **就近优先**：焦点落进行内 `LedgerCheckbox` 时，行级环熄灭、
//     只亮 22×22 复选框环；
//  T4 未来日的行不可聚焦 ⇒ 行级环不亮；
//  T5 插环不吃点击（`Stack` + `IgnorePointer`），点行仍开回填弹层；
//  T6 键位语义零回退：行 `Space` 切状态、行 `Enter` 开弹层、
//     勾选框 `Space` 只切勾选（行级不抢）。
//
// T3 是本轮的判别性核心：判据若退化成 `hasFocus`（父子都亮）必须先红。
// 真实库往返：状态断言都读 `plan_item` 表，不用内存假态。
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
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/focus_ring.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/outcome_composer.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';
const String _future = '2026-11-12';

/// 行级环的 key（与复选框环的默认 `focus-ring-border` 区分开）。
const ValueKey<String> _rowRingKey = ValueKey<String>(
  'focus-ring-border-plan-row',
);

/// 复选框环的默认 key。
const ValueKey<String> _defaultRingKey = ValueKey<String>('focus-ring-border');

/// 内存真库 + 真仓储 + 固定今天 / 可指定选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({String selected = _today}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'plan-row-focus-ring-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
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

  /// 建一条计划条目，返回它的 id。
  Future<String> addPlanItem(String date, String title) {
    return TimelineStore(repos).createManual(
      date: date,
      title: title,
      startMinute: 9 * 60,
      endMinute: 10 * 60,
    );
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

/// 焦点变更后推两帧：焦点落地是微任务，环的重建在下一帧。
Future<void> _pumpFocus(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
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

/// 行级环的 `Finder`：**只在行级 `Focus` 子树里**找，避开复选框环。
Finder _rowRingFinder(String itemId) {
  return find.descendant(
    of: find.byKey(ValueKey<String>('plan-row-focus-$itemId')),
    matching: find.byKey(_rowRingKey),
  );
}

/// 复选框环的 `Finder`：限定在「今日计划」卡片里的勾选框子树内。
Finder _checkboxRingFinder() {
  return find.descendant(
    of: _inPlanCard(find.byType(LedgerCheckbox)),
    matching: find.byKey(_defaultRingKey),
  );
}

/// 读环的边框（`AnimatedContainer.decoration` 的 `Border`）。
Border _ringBorder(WidgetTester tester, Finder finder) {
  final AnimatedContainer ring = tester.widget<AnimatedContainer>(finder);
  return (ring.decoration! as BoxDecoration).border! as Border;
}

Border _rowRingBorder(WidgetTester tester, String itemId) {
  return _ringBorder(tester, _rowRingFinder(itemId));
}

Border _checkboxRingBorder(WidgetTester tester) {
  return _ringBorder(tester, _checkboxRingFinder());
}

void main() {
  testWidgets('T1：行级焦点 ⇒ 行级环点亮 ink 2px', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '行级环要点亮');
    await harness.mount(tester);
    await _settle(tester);

    expect(_inPlanCard(find.text('行级环要点亮')), findsOneWidget);
    // 口径：环宽 2px，且必须走「只认主焦点」那一档（否则 T3 会父子双亮）。
    final FocusRing ring = tester.widget<FocusRing>(
      find.ancestor(
        of: _rowRingFinder(itemId),
        matching: find.byType(FocusRing),
      ),
    );
    expect(ring.focusedBorderWidth, 2);
    expect(ring.requirePrimaryFocus, isTrue);
    // 未聚焦：行级环必须是透明的（先把「判据看得见」立住）。
    expect(_rowRingBorder(tester, itemId).top.color, Colors.transparent);

    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await _pumpFocus(tester);

    expect(FocusManager.instance.primaryFocus, row);
    final Border border = _rowRingBorder(tester, itemId);
    expect(border.top.color, AppTokens.ink);
    expect(border.top.width, 2);

    await _flushTimers(tester);
  });

  testWidgets('T2：失焦 ⇒ 行级环熄灭', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '失焦要熄灭');
    await harness.mount(tester);
    await _settle(tester);

    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await _pumpFocus(tester);
    expect(_rowRingBorder(tester, itemId).top.color, AppTokens.ink);

    row.unfocus();
    await _pumpFocus(tester);

    expect(FocusManager.instance.primaryFocus, isNot(row));
    final Border border = _rowRingBorder(tester, itemId);
    expect(border.top.color, Colors.transparent);
    expect(border.top.width, 2, reason: '未聚焦同宽透明，避免布局跳动');

    await _flushTimers(tester);
  });

  testWidgets('T3：就近优先 —— 焦点在行内勾选框上时只亮复选框环', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '就近优先只有一个环');
    await harness.mount(tester);
    await _settle(tester);

    // 勾选框的焦点节点 = 它自己那个 `FocusRing` 收到的节点。
    final Finder boxRings = _inPlanCard(
      find.descendant(
        of: find.byType(LedgerCheckbox),
        matching: find.byType(FocusRing),
      ),
    );
    expect(boxRings, findsOneWidget);
    final FocusNode box = tester.widget<FocusRing>(boxRings).focusNode!;
    // 勾选框环走默认判据（`hasFocus`），与「只认主焦点」的行级环不是同一档。
    expect(tester.widget<FocusRing>(boxRings).requirePrimaryFocus, isFalse);

    // 前置：行自己拿着焦点时行级环是亮的（否则 T3 的熄灭不算判别）。
    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await _pumpFocus(tester);
    expect(_rowRingBorder(tester, itemId).top.color, AppTokens.ink);

    // 焦点下沉到勾选框（同一行的子节点）。
    box.requestFocus();
    await _pumpFocus(tester);
    expect(FocusManager.instance.primaryFocus, box);

    expect(
      _rowRingBorder(tester, itemId).top.color,
      Colors.transparent,
      reason: '行级环必须让位：`hasFocus` 在子孙拿焦点时仍为 true，父子双亮就是没做 D2',
    );
    final Border boxBorder = _checkboxRingBorder(tester);
    expect(boxBorder.top.color, AppTokens.ink);
    expect(boxBorder.top.width, 2);

    await _flushTimers(tester);
  });

  testWidgets('T4：未来日的行不可聚焦 ⇒ 行级环不亮', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _future);
    final String itemId = await harness.addPlanItem(_future, '未来日环不亮');
    await harness.mount(tester);
    await _settle(tester);

    expect(_inPlanCard(find.text('未来日环不亮')), findsOneWidget);
    final Focus focus = tester.widget<Focus>(
      find.byKey(ValueKey<String>('plan-row-focus-$itemId')),
    );
    expect(focus.canRequestFocus, isFalse, reason: 'spec §H-1：未来日只可预排');
    final FocusNode row = focus.focusNode!;
    row.requestFocus();
    await _pumpFocus(tester);

    expect(FocusManager.instance.primaryFocus, isNot(row));
    expect(_rowRingBorder(tester, itemId).top.color, Colors.transparent);

    await _flushTimers(tester);
  });

  testWidgets('T5：插环不吃点击 —— 点行标题仍打开「成果 / 进展」弹层', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.addPlanItem(_today, '插环不挡点');
    await harness.mount(tester);
    await _settle(tester);

    final Finder rowTitle = _inPlanCard(find.text('插环不挡点'));
    expect(rowTitle, findsWidgets, reason: '计划卡片内必须能找到行标题作为点击目标');
    await tester.tap(rowTitle.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // `Stack` + `Positioned.fill` + `IgnorePointer` 不得吞掉指向子树的点击。
    expect(find.byType(OutcomeComposer), findsOneWidget);
    expect(find.text('成果 / 进展'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('T6：键位语义零回退（行 Space / 行 Enter / 勾选框 Space）', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '键位别回退');
    await harness.mount(tester);
    await _settle(tester);

    Future<PlanItemData> reload() async {
      final List<PlanItemData> rows = await harness.repos.planItem.listByDate(
        _today,
      );
      return rows.firstWhere((PlanItemData row) => row.id == itemId);
    }

    // ① 焦点在行上：`Space` ⇒ pending → done，且不弹层。
    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await _pumpFocus(tester);
    expect(FocusManager.instance.primaryFocus, row);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);
    expect(find.byType(OutcomeComposer), findsNothing, reason: 'Space 不是「开弹层」');
    PlanItemData afterSpace = await reload();
    expect(afterSpace.status, PlanStatus.done.code);
    expect(afterSpace.doneAt, isNotNull);

    // ② 再按一次 ⇒ done → pending。
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);
    afterSpace = await reload();
    expect(afterSpace.status, PlanStatus.pending.code);
    expect(afterSpace.doneAt, isNull);

    // ③ 焦点在勾选框上：`Space` 只切勾选（切两下就会回到 pending ⇒ 判 done）。
    final FocusNode box = tester
        .widget<FocusRing>(
          _inPlanCard(
            find.descendant(
              of: find.byType(LedgerCheckbox),
              matching: find.byType(FocusRing),
            ),
          ),
        )
        .focusNode!;
    box.requestFocus();
    await _pumpFocus(tester);
    expect(FocusManager.instance.primaryFocus, box);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);
    expect(find.byType(OutcomeComposer), findsNothing);
    final PlanItemData afterBoxSpace = await reload();
    expect(
      afterBoxSpace.status,
      PlanStatus.done.code,
      reason: '行级 Space 若也响应，会被切两次又回到 pending',
    );

    // ④ 焦点回到行上：`Enter` ⇒ 打开回填弹层。
    row.requestFocus();
    await _pumpFocus(tester);
    expect(FocusManager.instance.primaryFocus, row);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(OutcomeComposer), findsOneWidget);
    expect(find.text('成果 / 进展'), findsOneWidget);

    await _flushTimers(tester);
  });
}