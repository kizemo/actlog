// P1 界面端到端测试：真库（in-memory drift）+ 真 TodayPage。
//
// 覆盖的验收点：
//   P1-3 条目与日志日双向一致
//   P1-6 整行回填可只存进展，也可以顺手标完成（含删除习惯回填行）
//   P1-7 IME 组合输入：拼音未上屏不落库，上屏后回车才落库（Task 40 补）
//
// B2（2026-11-12）删掉两条用例，理由见交付说明：
//   P1-1「极简隐藏字段不丢数据」—— 唯二宿主（`PriorityTagChip` 与条目细节
//        文本）随「今日计划」段一起删除，网格芯片里没有对应物；
//   P1-5「两种模式互斥且切换无损」—— 唯二宿主（`sortPlanItemsForDisplay`
//        与表头提示）同样随段消失，四象限 / ABC 已无界面入口。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const _date = '2026-11-07';

/// 一天的日志 + 仓储，全部指向同一个内存库。
final class _Harness {
  _Harness(this.db, this.repos);

  final ActLogDatabase db;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    return _Harness(db, ActLogRepositories(db, deviceId: 'e2e-device'));
  }

  Widget get app => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      todayProvider.overrideWithValue(_date),
    ],
    // W3 装配后 `TodayPage` 是内容体，宿主壳由 `LedgerShell` 提供。
    child: const MaterialApp(
      home: LedgerShell(content: TodayPage(), currentNavId: 'today'),
    ),
  );

  /// 直接读库，绕过 UI —— 用来证明「界面上看不见 ≠ 数据没了」。
  Future<PlanItemData> onlyItem() async {
    final rows = await repos.planItem.listByDate(_date);
    expect(rows, hasLength(1), reason: '测试依赖恰好一条计划条目');
    return rows.single;
  }
}

/// 把窗口撑大，避免非懒加载区块被挤出视口。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 把上一轮异步（drift 流查询、setState、路由动画）全部推完。
///
/// 刻意**不用** `pumpAndSettle`：加载态里的 `CircularProgressIndicator`
/// 是无限重复动画，`pumpAndSettle` 永远等不到「稳定」，会一路挂到超时。
/// 用 `runAsync` 让真实事件循环跑一轮，再显式 pump 固定帧数。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  // 24 × 30ms = 720ms 假时钟：必须越过 `kDoubleTapTimeout`（300ms）。
  // 网格条目的外壳是 `Draggable` + `GestureDetector(onDoubleTap:)`，单击的
  // `InkWell.onTap` 要等双击识别器认输才轮到它触发；只推 240ms 会让回填层
  // 永远不弹（表现为「找不到『成果 / 进展』」，而不是断言值不对）。
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _boot(WidgetTester tester, _Harness harness) async {
  _useTallSurface(tester);
  await tester.pumpWidget(harness.app);
  await _settle(tester);
}

/// 收尾：把 drift 在 Provider 销毁时留下的 0 长度 timer 跑完。
///
/// `StreamQueryStore.markAsClosed` 会在 StreamProvider 被 dispose 时排一个
/// 零时长 timer；测试框架在「widget 树销毁后还有 pending timer」时会直接判失败
/// （`A Timer is still pending even after the widget tree was disposed.`）。
/// 那是测试环境的收尾噪声，不是产品缺陷 —— 但必须让这帧 timer 走完。
///
/// **必须在用例体内调用，不能放 `addTearDown`**：
/// 框架的 `_verifyInvariants` 在 tearDown 之前就检查 timer，挂进 tearDown 太晚。
Future<void> _flushTimers(WidgetTester tester) async {
  // 先把 widget 树换成空树 ⇒ ProviderScope 被销毁 ⇒ drift 排 timer。
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  // 再把 0 长度 timer 跑完。
  await tester.pump(const Duration(milliseconds: 1));
}

Finder _addField() => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == '添加计划条目…',
);

/// 今日页正文内部的文本。
///
/// B2 之后「今日计划」整段已删，条目有两个落点：**方格网格**
/// （`day-grid`，已排期）与**未排期带**（`unscheduled-strip`，只有标题）。
/// 手写一条走的正是未排期带，所以范围必须放到整个 `TodayPage` ——
/// 只框 `day-grid` 会把未排期条目判成「不存在」。
/// 范围仍不能放宽到 `find.text(...)`：页头的环形刻度也会带出同名的统计文案。
Finder _inPlanBlock(String text) => find.descendant(
  of: find.byType(TodayPage),
  matching: find.text(text),
);

void main() {
  testWidgets('P1-3 底部输入框新增的条目落到当天，并立刻出现在列表里', (tester) async {
    final harness = _Harness.create();
    addTearDown(harness.db.close);

    await _boot(tester, harness);
    expect(find.byKey(const ValueKey<String>('unscheduled-strip')), findsNothing);

    await tester.enterText(_addField(), '写完 P1 今日页');
    await tester.tap(find.text('+ 手写一条'));
    await _settle(tester);

    expect(find.byKey(const ValueKey<String>('unscheduled-strip')), findsOneWidget);
    // 限定在「今日计划」区块里：站会区块也会列出今天的条目。
    expect(_inPlanBlock('写完 P1 今日页'), findsOneWidget);

    // 双向一致：界面上的条目就是当天日志日下的条目。
    final log = await harness.repos.dayLog.findByDate(_date);
    expect(log, isNotNull);
    final item = await harness.onlyItem();
    expect(item.date, log!.date);
    expect(item.title, '写完 P1 今日页');
    await _flushTimers(tester);
  });

  testWidgets('P1-6 整行回填：只存进展不改状态，点完成才转完成', (tester) async {
    final harness = _Harness.create();
    addTearDown(harness.db.close);
    await TimelineStore(harness.repos).createManual(date: _date, title: '整理后台', startMinute: 9 * 60, endMinute: 10 * 60);

    await _boot(tester, harness);

    // Task 45 · W2：左键点行开的是「任务详情」窗，回填搬进窗内的
    // 「成果 / 进展模板」按钮（`plan-detail-template`）。
    await tester.tap(_inPlanBlock('整理后台'));
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('plan-detail-title')),
      findsOneWidget,
      reason: '左键点行必须打开任务详情窗',
    );
    expect(find.text('成果 / 进展'), findsNothing, reason: '详情窗本身不摊开回填层');

    await tester.tap(
      find.byKey(const ValueKey<String>('plan-detail-template')),
    );
    await _settle(tester);
    expect(find.text('成果 / 进展'), findsOneWidget);

    await tester.tap(find.text('按时完成'));
    await _settle(tester);
    await tester.tap(find.text('只存进展'));
    await _settle(tester);

    // 模板只写「回填内容」框，落库还得点「保存」。
    final TextField noteField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('plan-detail-note')),
    );
    expect(
      noteField.controller!.text,
      '[结论]按时完成',
      reason: '模板结果必须落进回填内容框',
    );
    await tester.tap(find.byKey(const ValueKey<String>('plan-detail-save')));
    await _settle(tester);

    var row = await harness.onlyItem();
    expect(row.resultNote, '[结论]按时完成');
    expect(row.status, PlanStatus.pending.code, reason: '只存进展不得把条目判完成');
    expect(find.text('进展：[结论]按时完成'), findsOneWidget);

    // 完成由行首勾选框负责（模板不碰 status）。
    final Finder box = find.descendant(
      of: find.byKey(ValueKey<String>('day-grid-entry-${row.id}')),
      matching: find.byType(LedgerCheckbox),
    );
    expect(box, findsOneWidget, reason: '方格行首必须有勾选框');
    await tester.tap(box);
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('plan-detail-title')),
      findsNothing,
      reason: '点勾选框只切状态、不得打开详情窗',
    );

    row = await harness.onlyItem();
    expect(row.status, PlanStatus.done.code);
    expect(row.resultNote, '[结论]按时完成', reason: '点完成不该抹掉已有进展');
    expect(row.doneAt, isNotNull);
    await _flushTimers(tester);
  });

  testWidgets('P1-6 删除习惯回填行，不影响习惯打卡记录', (tester) async {
    final harness = _Harness.create();
    addTearDown(harness.db.close);

    // 习惯 + 当天打卡 + 打卡生成的回填行（三者都是独立行）。
    final habitId = await harness.repos.habit.create(
      name: '晨跑',
      startDate: _date,
    );
    await harness.repos.habit.upsertCheckin(habitId: habitId, date: _date);
    final String habitRowId = await harness.repos.planItem.createHabitRef(
      date: _date,
      habitId: habitId,
      title: '晨跑',
    );
    // 回填行必须排进方格：B2 之后未排期条目只落在「未排期带」，那里是纯
    // 标题芯片 —— 没有「习惯回填」来源标记、也没有行尾「删除」。
    // 这两处正是本用例的检验点，所以先把回填行排期。
    await TimelineStore(harness.repos).reschedule(
      planItemId: habitRowId,
      startMinute: 9 * 60,
      endMinute: 10 * 60,
    );

    await _boot(tester, harness);

    // 回填行出现在今日计划里，且带「习惯回填」来源标记。
    expect(_inPlanBlock('晨跑'), findsOneWidget);
    expect(_inPlanBlock('习惯回填'), findsOneWidget);

    // Task 45 · W2：行尾「删除」已移进任务详情窗（行尾只剩勾选 / 标记 / 标题 /
    // 时刻 / 字形 / 进展 / 来源徽标）。先钉住行尾确实没有删除入口。
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('day-grid')),
        matching: find.text('删除'),
      ),
      findsNothing,
      reason: '行尾不得再有「删除」，删除只在详情窗里',
    );

    await tester.tap(_inPlanBlock('晨跑'));
    await _settle(tester);
    expect(
      find.byKey(const ValueKey<String>('plan-detail-title')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('plan-detail-delete')));
    await _settle(tester);

    // 需求 9：删除走二次确认 —— 弹窗期间数据一行都不许动。
    expect(find.text('删除计划项'), findsOneWidget, reason: '必须先弹确认框');
    expect(
      _inPlanBlock('晨跑'),
      findsOneWidget,
      reason: '只弹确认框、还没点确认时，回填行必须还在',
    );
    expect(
      await harness.repos.planItem.listByDate(_date),
      hasLength(1),
      reason: '只弹确认框时不得软删任何行',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-dialog-confirm')),
    );
    await _settle(tester);

    // 回填行没了。
    expect(_inPlanBlock('晨跑'), findsNothing);
    expect(
      await harness.repos.planItem.listByDate(_date),
      isEmpty,
      reason: '软删除后计划列表里不该再有这一行',
    );

    // 但打卡记录**必须还在** —— 删回填行只写 plan_item 墓碑，不碰 habit_checkin。
    final checkin = await harness.repos.habit.findCheckin(habitId, _date);
    expect(checkin, isNotNull, reason: '删除回填行不得删掉习惯打卡记录');
    expect(checkin!.status, CheckinStatus.done.code);

    await _flushTimers(tester);
  });

  // P1-7 走真正的 IME 通道（不是 `enterText` 一步到位的赋值）。
  //
  // Task 39 遗留的「端到端 IME 未复验」就是这条：中文输入法下用户先敲拼音，
  // 拼音串在 `composing` 区间里、还没上屏；上屏之后才按回车。这三步在
  // `TextEditingValue` 层面是三次独立的事件，`enterText` 只模拟了最后一次的
  // 结果，掩盖了「组合态被误判为提交」这类缺陷。
  //
  // 钉三件事：① 组合态不落库；② 上屏但不回车也不落库；③ 回车（`done`）
  // 才落库，且落的就是上屏后的正文。
  testWidgets('P1-7 IME 组合输入：拼音未上屏不落库，上屏后回车才落库', (tester) async {
    final harness = _Harness.create();
    addTearDown(harness.db.close);

    await _boot(tester, harness);
    expect(find.byKey(const ValueKey<String>('unscheduled-strip')), findsNothing);

    // 建立真实输入连接（`enterText` 之外唯一能拿到 `testTextInput` 的方式）。
    await tester.showKeyboard(_addField());
    await tester.pump();

    // 1) 拼音串在组合区间里 —— 界面显示的是 `zhengli`，一个字都没上屏。
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'zhengli',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 0, end: 7),
      ),
    );
    await tester.pump();
    expect(
      find.text('zhengli'),
      findsOneWidget,
      reason: '组合态的拼音必须落在输入框里（否则这条用例没测到 IME）',
    );
    expect(
      await harness.repos.planItem.listByDate(_date),
      isEmpty,
      reason: '拼音还在组合区间、没有上屏时不得落库',
    );

    // 2) 上屏（`composing` 清空）—— 输入框里有正文，但用户还没回车。
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '整理阳台',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange.empty,
      ),
    );
    await tester.pump();
    expect(
      await harness.repos.planItem.listByDate(_date),
      isEmpty,
      reason: '上屏本身不是提交动作，不得落库',
    );
    expect(find.byKey(const ValueKey<String>('unscheduled-strip')), findsNothing);

    // 3) 回车（IME 的 `done`）才是提交。
    tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);

    expect(find.byKey(const ValueKey<String>('unscheduled-strip')), findsOneWidget);
    expect(_inPlanBlock('整理阳台'), findsOneWidget);

    final item = await harness.onlyItem();
    expect(item.title, '整理阳台', reason: '落库的必须是上屏后的正文，不是拼音串');
    expect(item.date, _date);
    await _flushTimers(tester);
  });
}
