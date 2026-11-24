// apps/desktop/test/task63_w3_l10n_test.dart
//
// Task 63 · 批次二 · W3（时间线）：中文 UI 文案迁入 l10n 后的双态验收。
//
// §47.3 口径：**不断 `find.text(t.xxx)` 这种同义反复**，一律断字面量；
// 中文态断旧中文原文（迁移必须逐字不变），英文态断新英文译文。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/widgets/day_timeline.dart';
import 'package:actlog/src/widgets/timeline/slot_range_dialog.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

void main() {
  group('空格引导 / 手填', () {
    test('zh：引导语与手填弹窗逐字不变', () {
      const AppLocalizations t = AppLocalizations.zh;
      expect(t.timelineEmptyGridHint, '右键任意一格开始排期');
      expect(t.timelinePlanTitleHint, '计划标题');
      expect(t.timelineScheduleAction, '排上');
      expect(t.timelineSlotFillTitle, '成果 / 进展');
    });

    test('en：引导语与手填弹窗为英文译文', () {
      const AppLocalizations t = AppLocalizations.en;
      expect(t.timelineEmptyGridHint, 'Right-click any cell to start scheduling');
      expect(t.timelinePlanTitleHint, 'Plan title');
      expect(t.timelineScheduleAction, 'Schedule');
      expect(t.timelineSlotFillTitle, 'Outcome / progress');
    });
  });

  group('右键三级菜单', () {
    test('zh：分组名与空态逐字不变', () {
      const AppLocalizations t = AppLocalizations.zh;
      expect(t.timelineManualGroup, '手填');
      expect(t.timelineManualEntry, '手填一条');
      expect(t.timelineTodoGroup, '待办');
      expect(t.timelineTodoPoolEmpty, '待办池里没有可入格的条目');
      expect(t.timelineHabitGroup, '习惯');
      expect(t.timelineHabitEmpty, '这天没有排程内的习惯');
      // 起止弹窗的确认按钮是「确认」，**不是** `confirm` 的「确定」。
      expect(t.timelineConfirmAction, '确认');
      expect(t.confirm, '确定');
    });

    test('en：分组名与空态为英文译文', () {
      const AppLocalizations t = AppLocalizations.en;
      expect(t.timelineManualGroup, 'Manual');
      expect(t.timelineManualEntry, 'Write one entry');
      expect(t.timelineTodoGroup, 'To-dos');
      expect(t.timelineTodoPoolEmpty, 'No to-dos available to slot');
      expect(t.timelineHabitGroup, 'Habits');
      expect(t.timelineHabitEmpty, 'No habits scheduled for this day');
      expect(t.timelineConfirmAction, 'Confirm');
    });
  });

  group('带参插值文案', () {
    test('zh：标题 / 时长 / 步进 tooltip 逐字不变', () {
      const AppLocalizations t = AppLocalizations.zh;
      expect(t.timelineSlotMenuTitle('09:15'), '09:15 这一格');
      expect(t.timelineRangeTitle('2026-11-24'), '2026-11-24 · 起止');
      expect(t.timelineTotalMinutes(45), '共 45 分钟');
      expect(t.timelineStepDown('开始'), '开始 减一格');
      expect(t.timelineStepUp('结束'), '结束 加一格');
      expect(t.timelineSlotPrompt('09:15'), '09:15 要做什么？');
    });

    test('en：标题 / 时长 / 步进 tooltip 为英文译文', () {
      const AppLocalizations t = AppLocalizations.en;
      expect(t.timelineSlotMenuTitle('09:15'), 'Slot at 09:15');
      expect(t.timelineRangeTitle('2026-11-24'), '2026-11-24 · Start / end');
      expect(t.timelineTotalMinutes(45), '45 min total');
      expect(t.timelineStepDown('Start'), 'Decrease Start by one step');
      expect(t.timelineStepUp('End'), 'Increase End by one step');
      expect(t.timelineSlotPrompt('09:15'), 'What are you doing at 09:15?');
    });
  });

  group('详情窗 / 写库失败 / 悬停浮窗', () {
    test('zh：详情窗字段名与提示逐字不变', () {
      const AppLocalizations t = AppLocalizations.zh;
      expect(t.timelineTaskDetailTitle, '任务详情');
      expect(t.timelineContentLabel, '内容');
      expect(t.timelineLevelLabel, '级别');
      expect(t.timelineBackfillContentLabel, '回填内容');
      expect(
        t.timelineFutureDayBackfillBlocked,
        '未来日不可回填：打卡 / 回填 / 复盘 / 心态只允许今天与过去。',
      );
      expect(t.timelineOutcomeTemplateTitle, '成果 / 进展模板');
      expect(t.timelineDurationLabel, '持续时间');
      expect(t.timelineStartLabel, '开始');
      expect(t.timelineEndLabel, '结束');
      expect(t.timelineDeletePlanItemTitle, '删除计划项');
      expect(
        t.timelineDeletePlanItemMessage('跑步'),
        '确认删除「跑步」？删除后它不再出现在清单里。',
      );
      // 两处共用同一条写库失败提示。
      expect(t.timelineWriteFailed('boom'), '写入失败：boom');
      expect(t.timelineHoverDetail('d'), '详情：d');
      expect(t.timelineHoverNote('n'), '进展：n');
      expect(t.timelineHoverState('s'), '状态：s');
      expect(t.timelineHoverLevel('l'), '级别：l');
    });

    test('en：详情窗字段名与提示为英文译文', () {
      const AppLocalizations t = AppLocalizations.en;
      expect(t.timelineTaskDetailTitle, 'Task details');
      expect(t.timelineContentLabel, 'Content');
      expect(t.timelineLevelLabel, 'Level');
      expect(t.timelineBackfillContentLabel, 'Backfill content');
      expect(
        t.timelineFutureDayBackfillBlocked,
        'Future days cannot be backfilled: check-in / backfill / review / mood '
        'are limited to today and the past.',
      );
      expect(t.timelineOutcomeTemplateTitle, 'Outcome / progress template');
      expect(t.timelineDurationLabel, 'Duration');
      expect(t.timelineStartLabel, 'Start');
      expect(t.timelineEndLabel, 'End');
      expect(t.timelineDeletePlanItemTitle, 'Delete plan item');
      expect(
        t.timelineDeletePlanItemMessage('Run'),
        'Delete "Run"? It will no longer appear in the list.',
      );
      expect(t.timelineWriteFailed('boom'), 'Write failed: boom');
      expect(t.timelineHoverDetail('d'), 'Details: d');
      expect(t.timelineHoverNote('n'), 'Progress: n');
      expect(t.timelineHoverState('s'), 'Status: s');
      expect(t.timelineHoverLevel('l'), 'Level: l');
    });
  });

  group('四态文字通道 / 右轨待办', () {
    test('zh：四态状态词逐字不变（缺省中文表）', () {
      expect(stateLabelOfSlotKind(SlotKind.habit), '打卡');
      expect(stateLabelOfSlotKind(SlotKind.backfill), '回填');
      expect(stateLabelOfSlotKind(SlotKind.done), '完成');
      expect(stateLabelOfSlotKind(SlotKind.plannedOpen), '计划');
    });

    test('en：四态状态词走英文表（两态复用 domain 键）', () {
      const AppLocalizations en = AppLocalizations.en;
      expect(stateLabelOfSlotKind(SlotKind.habit, localizations: en), 'Checked in');
      expect(stateLabelOfSlotKind(SlotKind.backfill, localizations: en), 'Backfill');
      expect(stateLabelOfSlotKind(SlotKind.done, localizations: en), 'Done');
      expect(stateLabelOfSlotKind(SlotKind.plannedOpen, localizations: en), 'Plan');
    });

    test('zh：右轨待办四态与节点文字逐字不变', () {
      const AppLocalizations t = AppLocalizations.zh;
      expect(t.timelineTodoLoadFailed, '待办加载失败');
      expect(t.timelineTodoLoading, '正在加载待办…');
      expect(t.timelineTodoEmpty, '暂无待办');
      expect(t.timelineTodoSlotted, '已排期');
      expect(t.timelineNodeGap, '▸ 有缺口');
      expect(t.timelineNodeClosed, '✓ 已闭合');
      // 纯函数缺省中文表，与 `test\day_timeline_test.dart` 的既有断言同一事实源。
      expect(tlNodeLabel(hasGap: true, gapLabel: null), '▸ 有缺口');
    });

    test('en：右轨待办四态与节点文字为英文译文', () {
      const AppLocalizations t = AppLocalizations.en;
      expect(t.timelineTodoLoadFailed, 'Failed to load to-dos');
      expect(t.timelineTodoLoading, 'Loading to-dos…');
      expect(t.timelineTodoEmpty, 'No to-dos');
      expect(t.timelineTodoSlotted, 'Scheduled');
      expect(t.timelineNodeGap, '▸ Gap');
      expect(t.timelineNodeClosed, '✓ Closed');
      expect(
        tlNodeLabel(hasGap: false, gapLabel: null, localizations: t),
        '✓ Closed',
      );
    });
  });

  group('控件接线（真界面双态）', () {
    testWidgets('zh：起止弹窗标题 / 时长 / 按钮逐字不变', (WidgetTester tester) async {
      await pumpL10n(
        tester,
        const Scaffold(
          body: SlotRangeDialog(
            date: '2026-11-24',
            initialStart: 540,
            initialEnd: 570,
          ),
        ),
      );
      expect(find.text('2026-11-24 · 起止'), findsOneWidget);
      expect(find.text('开始'), findsOneWidget);
      expect(find.text('结束'), findsOneWidget);
      expect(find.text('共 30 分钟'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确认'), findsOneWidget);
    });

    testWidgets('en：起止弹窗标题 / 时长 / 按钮为英文译文', (WidgetTester tester) async {
      await pumpL10n(
        tester,
        const Scaffold(
          body: SlotRangeDialog(
            date: '2026-11-24',
            initialStart: 540,
            initialEnd: 570,
          ),
        ),
        language: AppLanguage.en,
      );
      expect(find.text('2026-11-24 · Start / end'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('30 min total'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('en：节点文字随文案表切换（缺口态）', (WidgetTester tester) async {
      await pumpL10n(
        tester,
        const Scaffold(
          body: TimelineSection(
            label: 'Morning',
            hasGap: true,
            localizations: AppLocalizations.en,
            child: SizedBox(height: 20),
          ),
        ),
        language: AppLanguage.en,
      );
      expect(find.text('▸ Gap'), findsOneWidget);
      expect(find.text('▸ 有缺口'), findsNothing);
    });
  });
}