// apps/desktop/test/task53_backfill_inline_test.dart
//
// Task 53 · W3 · 用户当轮需求 4 原文：
//   「4. 左键点击任务，弹出的对话框中，回填部分直接显示可选择的项，
//     不要增加一次跳转。」
//
// 判据（本条测试钉死的就是这句话）：
//   · 打开任务详情窗 ⇒ **不点任何按钮**即可见三组可选项（结论 / 原因 / 下一步），
//     它们此前只藏在 `plan-detail-template` ⇒ `showSlotFillDialog` 的第二层里；
//   · 点某个标签 ⇒ 标签文本落进 `plan-detail-note` 文本框；
//   · 再点已选标签 ⇒ 该项取消，文本回退；
//   · 组内单选（点同组另一个 ⇒ 顶掉前一个）、组间可并存；
//   · 未来日锁定态（回填本就不许写）⇒ 可选项**不出现**；
//   · 小尺寸 surface ⇒ 无 overflow（`tester.takeException()` 为 null）。
//
// 与 `timeline_plan_detail_test.dart` 的差别：那里走真库 + 真网格（`DayGrid`），
// 这里只钉「详情窗回填 section 的交互层级」，所以直接弹 `PlanItemDetailDialog`
// 本体 —— 不引入 drift 流，因此这里**可以**用 `pumpAndSettle`。
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/chip_row.dart';
import 'package:actlog/src/widgets/outcome_composer.dart';
import 'package:actlog/src/widgets/timeline/plan_item_detail_dialog.dart';

/// 固定「今天」；`_item()` 默认就落在这天（过去 / 今天都算可回填）。
const String _today = '2026-11-09';

/// 未来日（预排日）：回填必须锁死，因此也不该出现可选项。
const String _future = '2026-11-12';

const ValueKey<String> _kNote = ValueKey<String>('plan-detail-note');
const ValueKey<String> _kNoteLocked = ValueKey<String>('plan-detail-note-locked');
const ValueKey<String> _kTemplate = ValueKey<String>('plan-detail-template');
const ValueKey<String> _kChipOutcome = ValueKey<String>(
  'plan-detail-chip-outcome',
);
const ValueKey<String> _kChipReason = ValueKey<String>('plan-detail-chip-reason');
const ValueKey<String> _kChipNextStep = ValueKey<String>(
  'plan-detail-chip-next-step',
);

/// 一条最朴素的计划行（不落库，本测试只关心窗内交互）。
PlanItemData _item({
  String date = _today,
  String resultNote = '',
  String title = '开会',
}) {
  return PlanItemData(
    id: 'plan-1',
    date: date,
    title: title,
    detail: '',
    sourceType: 'manual',
    domain: '',
    plannedStart: 9 * 60,
    plannedEnd: 9 * 60 + 15,
    status: PlanStatus.pending.code,
    resultNote: resultNote,
    isHabitRef: 0,
    createdAt: 0,
    updatedAt: 0,
    originDeviceId: 'task53-w3-test',
    rev: 1,
  );
}

/// 弹真详情窗（走 `showDialog`，与生产路径同一套布局）。
Future<void> _openDetail(
  WidgetTester tester, {
  required String todayIso,
  required PlanItemData item,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showPlanItemDetailDialog(
                context,
                item: item,
                todayIso: todayIso,
                defaultStart: 9 * 60,
                defaultEnd: 9 * 60 + 15,
              ),
              child: const Text('打开详情'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开详情'));
  await tester.pumpAndSettle();
  expect(find.text('任务详情'), findsOneWidget, reason: '详情窗没弹出来');
}

/// 回填文本框的当前内容（**唯一**的判据载体：标签写进去的就是这段纯文本）。
String _noteText(WidgetTester tester) {
  return tester.widget<TextField>(find.byKey(_kNote)).controller!.text;
}

/// 点某个标签（限定在某一组芯片条内，避免与对话框「取消」按钮等同名文本撞车）。
Future<void> _tapChip(
  WidgetTester tester,
  ValueKey<String> group,
  String label,
) async {
  final Finder chip = find.descendant(
    of: find.byKey(group),
    matching: find.text(label),
  );
  expect(chip, findsOneWidget, reason: '组 $group 里找不到标签「$label」');
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// 全屏尺寸：详情窗内容本来就长（六块），给足高度再看竖向节流。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // ---------------------------------------------------------------------------
  // 1. 核心诉求：打开窗就能看见可选项，**零次跳转**。
  // ---------------------------------------------------------------------------
  testWidgets('1. 打开详情窗 ⇒ 不点任何按钮即见三组可选标签', (tester) async {
    _useTallSurface(tester);
    await _openDetail(tester, todayIso: _today, item: _item());

    // 三组芯片条本体在（不依赖任何点击）。
    expect(
      find.byKey(_kChipOutcome),
      findsOneWidget,
      reason: '回填 section 缺「结论」可选项（用户要求直接显示，不再多一跳）',
    );
    expect(find.byKey(_kChipReason), findsOneWidget, reason: '缺「原因」可选项');
    expect(
      find.byKey(_kChipNextStep),
      findsOneWidget,
      reason: '缺「下一步」可选项',
    );

    // 每组至少抽一枚标签，确认真的是 `outcome_composer.dart` 那份常量，
    // 而不是另起一套文案。
    expect(
      find.descendant(
        of: find.byKey(_kChipOutcome),
        matching: find.text(OutcomeComposer.outcomeLabels.first),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_kChipReason),
        matching: find.text(OutcomeComposer.reasonLabels.first),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_kChipNextStep),
        matching: find.text(OutcomeComposer.nextStepLabels.first),
      ),
      findsOneWidget,
    );

    // 整组的每一枚都在（组内选项不许被裁掉）。
    for (final String label in OutcomeComposer.outcomeLabels) {
      expect(
        find.descendant(
          of: find.byKey(_kChipOutcome),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: '结论组缺「$label」',
      );
    }
    for (final String label in OutcomeComposer.reasonLabels) {
      expect(
        find.descendant(
          of: find.byKey(_kChipReason),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: '原因组缺「$label」',
      );
    }
    for (final String label in OutcomeComposer.nextStepLabels) {
      expect(
        find.descendant(
          of: find.byKey(_kChipNextStep),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: '下一步组缺「$label」',
      );
    }

    // 完整 composer 的入口保留（本改动只加不删）。
    expect(
      find.byKey(_kTemplate),
      findsOneWidget,
      reason: '「成果 / 进展模板」按钮不许被删',
    );
    // 第二层没被打开：`OutcomeComposer` 不该出现在窗里。
    expect(find.byType(OutcomeComposer), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // 2. 点标签 ⇒ 写进回填文本框（判据载体是那段纯文本，不是别的状态）。
  // ---------------------------------------------------------------------------
  testWidgets('2. 点结论标签 ⇒ plan-detail-note 文本随之写入该标签', (tester) async {
    _useTallSurface(tester);
    await _openDetail(tester, todayIso: _today, item: _item());
    expect(_noteText(tester), isEmpty, reason: '预置条件：回填本来是空的');

    await _tapChip(tester, _kChipOutcome, '按时完成');

    expect(
      _noteText(tester),
      contains('按时完成'),
      reason: '点了结论标签，回填文本框里却没有它',
    );

    // 组内单选：点同组另一枚 ⇒ 顶掉前一枚，不会两只都留着。
    await _tapChip(tester, _kChipOutcome, '延后完成');
    expect(_noteText(tester), contains('延后完成'));
    expect(
      _noteText(tester),
      isNot(contains('按时完成')),
      reason: '结论组必须单选（点新的要顶掉旧的）',
    );

    // 组间可并存：再点原因 / 下一步，三段都在。
    await _tapChip(tester, _kChipReason, '预估不足');
    await _tapChip(tester, _kChipNextStep, '明天继续');
    final String text = _noteText(tester);
    expect(text, contains('延后完成'), reason: '加原因不该抹掉结论');
    expect(text, contains('预估不足'), reason: '原因没写进回填文本框');
    expect(text, contains('明天继续'), reason: '下一步没写进回填文本框');
  });

  // ---------------------------------------------------------------------------
  // 3. 再点已选标签 = 取消（文本回退，不留残渣）。
  // ---------------------------------------------------------------------------
  testWidgets('3. 再点已选标签 ⇒ 该项取消，文本相应回退', (tester) async {
    _useTallSurface(tester);
    await _openDetail(tester, todayIso: _today, item: _item());

    await _tapChip(tester, _kChipOutcome, '受阻');
    expect(_noteText(tester), contains('受阻'));

    await _tapChip(tester, _kChipOutcome, '受阻');
    expect(
      _noteText(tester),
      isNot(contains('受阻')),
      reason: '再点已选标签应回到「未选」，文本里不许残留',
    );
    expect(_noteText(tester), isEmpty, reason: '只选了一枚，取消后应回到空文本');

    // 多段时取消其中一段：其余段落原样保留。
    await _tapChip(tester, _kChipOutcome, '部分完成');
    await _tapChip(tester, _kChipReason, '时间不够');
    expect(_noteText(tester), contains('部分完成'));
    await _tapChip(tester, _kChipReason, '时间不够');
    final String text = _noteText(tester);
    expect(text, contains('部分完成'), reason: '取消原因不该连带抹掉结论');
    expect(text, isNot(contains('时间不够')));
  });

  // ---------------------------------------------------------------------------
  // 4. 芯片选中态与文本一致（否则「再点取消」的操作者会看不出来）。
  // ---------------------------------------------------------------------------
  testWidgets('4. 选中态：写进文本的标签在条上呈选中，取消后回到未选', (tester) async {
    _useTallSurface(tester);
    await _openDetail(tester, todayIso: _today, item: _item());

    final Finder outcomeRow = find.byKey(_kChipOutcome);
    Set<String> selected() => tester.widget<ChipRow>(outcomeRow).selected;

    expect(selected(), isEmpty, reason: '初始不该有任何选中项');

    await _tapChip(tester, _kChipOutcome, '提前完成');
    expect(selected(), <String>{'提前完成'});

    await _tapChip(tester, _kChipOutcome, '提前完成');
    expect(selected(), isEmpty);
  });

  // ---------------------------------------------------------------------------
  // 5. 未来日锁定态：回填本就不许写 ⇒ 可选项一枚都不许出现。
  // ---------------------------------------------------------------------------
  testWidgets('5. 未来日锁定态 ⇒ 不出现任何可选项', (tester) async {
    _useTallSurface(tester);
    await _openDetail(
      tester,
      todayIso: _today,
      item: _item(date: _future),
    );

    expect(
      tester.widget<TextField>(find.byKey(_kNote)).enabled,
      isFalse,
      reason: '未来日回填框必须禁用',
    );
    expect(find.byKey(_kNoteLocked), findsOneWidget, reason: '未来日缺锁定提示');

    expect(
      find.byKey(_kChipOutcome),
      findsNothing,
      reason: '未来日不许出现「结论」可选项（回填整体锁死）',
    );
    expect(find.byKey(_kChipReason), findsNothing, reason: '未来日不许出现「原因」');
    expect(
      find.byKey(_kChipNextStep),
      findsNothing,
      reason: '未来日不许出现「下一步」',
    );
    // 更强的一条：连标签文本本身都不该在窗里（防止换一套自绘 chip 绕过）。
    expect(find.text('按时完成'), findsNothing);
    expect(find.text('预估不足'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // 6. 溢出防护：小尺寸 surface 下不许报 overflow。
  // ---------------------------------------------------------------------------
  testWidgets('6. 小尺寸 surface ⇒ 无 overflow 异常，且三组仍可达', (tester) async {
    tester.view.physicalSize = const Size(430, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openDetail(tester, todayIso: _today, item: _item());
    // 布局类异常（overflow / unbounded）会在这一帧之后被测试框架抓住。
    expect(
      tester.takeException(),
      isNull,
      reason: '小尺寸 surface 下详情窗报了布局异常（overlap / overflow）',
    );

    // 三组仍在树里（正文可滚动即可，不要求同时可见）。
    expect(find.byKey(_kChipOutcome), findsOneWidget);
    expect(find.byKey(_kChipReason), findsOneWidget);
    expect(find.byKey(_kChipNextStep), findsOneWidget);

    // 点得到（如有滚动则会先滚过去）：验证小尺寸下不是「看得见摸不着」。
    await tester.ensureVisible(find.byKey(_kChipOutcome));
    await tester.pumpAndSettle();
    await _tapChip(tester, _kChipOutcome, '按时完成');
    expect(_noteText(tester), contains('按时完成'));
    expect(tester.takeException(), isNull, reason: '点击后出现布局异常');
  });
}