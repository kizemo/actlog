// apps/desktop/test/plan_row_shortcuts_test.dart
//
// Task 20（裁定 K4 / K5 / K6）守今日计划行的两个键：
//  - `Space` → **切勾选**（`plan_item.status`：`done ⇄ pending`），**不弹任何层**；
//  - `Enter` → 打开「成果 / 进展」回填弹层（复用 `_editResult`）。
//
// 两者的语义必须不同（A3 / A4 / A5）：`Space` 不是「打开回填」的另一个名字。
//
// 另外两条边界：
//  - 焦点在 `LedgerCheckbox` 上时 `Space` **只**切勾选，就近优先、行级不抢（A6）；
//  - 未来日（`future == true`）的行不可聚焦，`Space` / `Enter` 零副作用（A7）。
//
// 真实库往返：断言都读 `plan_item` 表，不用内存假态。
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
const String _future = '2026-11-12';

/// 内存真库 + 真仓储 + 固定今天 / 可指定选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({String selected = _today}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'plan-row-shortcut-test');
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

void main() {
  testWidgets('A3：行上按 Space 切勾选（pending ⇄ done），再按一次回 pending', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '键盘勾我');
    await harness.mount(tester);
    await _settle(tester);

    expect(_inPlanCard(find.text('键盘勾我')), findsOneWidget);

    // 焦点落在**行**上（不是勾选框上）。
    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, row);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);

    PlanItemData row0 = (await harness.repos.planItem.listByDate(_today))
        .firstWhere((PlanItemData item) => item.id == itemId);
    expect(row0.status, PlanStatus.done.code);
    expect(row0.doneAt, isNotNull, reason: '置 done 必须同时写 done_at');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);

    PlanItemData row1 = (await harness.repos.planItem.listByDate(_today))
        .firstWhere((PlanItemData item) => item.id == itemId);
    expect(row1.status, PlanStatus.pending.code);
    expect(row1.doneAt, isNull, reason: '回 pending 必须清 done_at');

    await _flushTimers(tester);
  });

  testWidgets('A4：行上按 Enter 打开「成果 / 进展」回填弹层', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '回填我');
    await harness.mount(tester);
    await _settle(tester);

    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(OutcomeComposer), findsOneWidget);
    expect(find.text('成果 / 进展'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('A5：行上按 Space 不弹回填弹层（Space 与 Enter 语义不同）', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '别弹层');
    await harness.mount(tester);
    await _settle(tester);

    final FocusNode row = _rowNode(tester, itemId);
    row.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(OutcomeComposer), findsNothing);
    expect(find.text('成果 / 进展'), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('A6：勾选框上按 Space 只切勾选，行级动作不跟着来一次', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '就近优先');
    await harness.mount(tester);
    await _settle(tester);

    // 焦点落在**勾选框**上。
    final FocusNode box = _checkboxNode(tester);
    box.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, box);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);

    final PlanItemData item = (await harness.repos.planItem.listByDate(_today))
        .firstWhere((PlanItemData row) => row.id == itemId);
    // 行级 `Space` 与勾选框 `Space` 都是「切一次」：如果两级都响应，
    // 状态会被切两次又回到 pending。所以这里是 done ⇒ 只响应了一次。
    expect(item.status, PlanStatus.done.code);
    expect(find.byType(OutcomeComposer), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('A7：未来日的行不可聚焦，Space / Enter 零副作用', (tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _future);
    final String itemId = await harness.addPlanItem(_future, '预排一条');
    await harness.mount(tester);
    await _settle(tester);

    expect(_inPlanCard(find.text('预排一条')), findsOneWidget);

    // 行级焦点节点存在，但**不可请求焦点**（spec §H-1：未来日只可预排）。
    final Focus focus = tester.widget<Focus>(
      find.byKey(ValueKey<String>('plan-row-focus-$itemId')),
    );
    expect(focus.canRequestFocus, isFalse);
    final FocusNode row = focus.focusNode!;
    row.requestFocus();
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus,
      isNot(row),
      reason: '未来日的行拿不到焦点',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);

    final PlanItemData item = (await harness.repos.planItem.listByDate(_future))
        .firstWhere((PlanItemData row) => row.id == itemId);
    expect(item.status, PlanStatus.pending.code, reason: '未来日零写入');
    expect(item.doneAt, isNull);
    expect(find.byType(OutcomeComposer), findsNothing);

    await _flushTimers(tester);
  });

  // ---------------------------------------------------------------------------
  // A8 / A9（Task 21 补测）：A3–A7 全部用 `requestFocus()` 手工把焦点**放**到行上，
  // 因此从来没有回答「真实键盘遍历能不能走到行」。真机 v3 探针（`reports\task21-key3.ps1`）
  // 30 次 `Tab` + `Space` 全部未命中种入行，必须先分清是
  //   ① Tab 遍历根本到不了行级焦点，还是 ② 到了但 Space 没派发。
  // 这两条用例就是该判别：A8 走真实遍历路径，A9 否掉「先点一下行再 Tab」的补测配方。
  // ---------------------------------------------------------------------------

  testWidgets('A8：Tab 遍历能连续走到计划行的行级焦点，落上后 Space 即切勾选', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String firstId = await harness.addPlanItem(_today, '遍历一号');
    final String secondId = await harness.addPlanItem(_today, '遍历二号');
    await harness.mount(tester);
    await _settle(tester);

    expect(_inPlanCard(find.text('遍历一号')), findsOneWidget);
    final FocusNode first = _rowNode(tester, firstId);
    final FocusNode second = _rowNode(tester, secondId);
    // 冷启动：焦点不在任何计划行上（不在 ⇒ Tab 才有意义）。
    expect(FocusManager.instance.primaryFocus, isNot(first));
    expect(FocusManager.instance.primaryFocus, isNot(second));

    // 逐枚 Tab，直到行级焦点命中。上限 80 用来区分「走不到」与「走得慢」：
    // 今日页可聚焦节点远少于 80，超过就是真走不到，不是次数不够。
    int reachedAt = 0;
    FocusNode? hitNode;
    for (var i = 1; i <= 80; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final FocusNode? now = FocusManager.instance.primaryFocus;
      if (now == first || now == second) {
        reachedAt = i;
        hitNode = now;
        break;
      }
    }
    expect(
      reachedAt,
      greaterThan(0),
      reason: '真实 Tab 遍历必须能走到计划行的行级焦点（v3 真机 30 次未命中即此处不成立）',
    );

    // 走到了就必须能用：Space 切勾选。
    final String hitId = hitNode == first ? firstId : secondId;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester);

    final PlanItemData hit = (await harness.repos.planItem.listByDate(_today))
        .firstWhere((PlanItemData row) => row.id == hitId);
    expect(hit.status, PlanStatus.done.code, reason: '遍历落点上的 Space 必须真的切勾选');
    expect(find.byType(OutcomeComposer), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('A9：指针点击计划行不会把行级焦点放上去（否掉「先点再 Tab」的补测配方）', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final String itemId = await harness.addPlanItem(_today, '点我开层');
    await harness.mount(tester);
    await _settle(tester);

    final FocusNode row = _rowNode(tester, itemId);
    expect(FocusManager.instance.primaryFocus, isNot(row));

    // 真指针点击行（`InkWell.canRequestFocus == false`，子级 `GestureDetector` 也不抢焦点）。
    // 全局 `find.text` 会命中 2 个同名 Text（外层宿主 Roboto/14.0 与行标题 Inter/13.5），
    // 故先限定在「今日计划」卡片内再取第一个，保证点击落在行标题上。
    final Finder rowTitle = _inPlanCard(find.text('点我开层'));
    expect(rowTitle, findsWidgets, reason: '计划卡片内必须能找到行标题作为点击目标');
    await tester.tap(rowTitle.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      FocusManager.instance.primaryFocus,
      isNot(row),
      reason: '点击不建立行级焦点 ⇒ `点击行 → 按 Space` 的配方在真机上必然空转',
    );
    // 点击的真实后果是**打开回填弹层**（不是把焦点给行）。
    expect(find.byType(OutcomeComposer), findsOneWidget);

    await _flushTimers(tester);
  });
}
