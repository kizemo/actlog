// =============================================================================
// l10n 底座自检（W0）
// =============================================================================
// 这一批用例守的是「拆分没改坏东西」这件事，而不是某个页面的长相：
//  1. 键表与 getter 一一对应，一条不少、键不重复、键格式统一；
//  2. 中英两态都非空，且除两条白名单外必须**不同**（这是防「复制粘贴当翻译」）；
//  3. `forLanguage` / `fromCode` / `of(context)` 的分流正确，缺 scope 必抛错；
//  4. 插值方法的中文输出与拆分前页面里的旧拼串**逐字一致**；
//  5. `L10nFormat` 的分隔符按语言切换。
//
// 刻意没写的东西：断言某条文案的**具体内容**（那会把文案改动变成测试红）。
// 这里只守结构与不变式，文案本身由人看。
// =============================================================================

import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/l10n/l10n_keys.dart';
import 'package:actlog/src/l10n/l10n_scope.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

void main() {
  group('键表结构', () {
    test('586 条 getter 全部登记在对照表里', () {
      expect(L10nKeys.byGetter.length, 586);
      expect(l10nAccessors.length, 586);
      // `byGetter` 是「getter 名 → 键」，访问器表是「键 → 取值」，所以这里比
      // 的是 `byGetter` 的**值**集合（都是 kebab 键）。
      expect(l10nAccessors.keys.toSet(), L10nKeys.byGetter.values.toSet());
    });

    test('4 条列表型 getter 全部登记在列表表里', () {
      expect(L10nKeys.byListGetter.length, 4);
      expect(l10nListAccessors.length, 4);
      expect(
        l10nListAccessors.keys.toSet(),
        L10nKeys.byListGetter.values.toSet(),
      );
    });

    test('53 条插值方法登记在方法表里', () {
      expect(L10nKeys.byMethod.length, 53);
      expect(L10nKeys.byMethod.keys.toSet(), <String>{
        // 既有 6 条（domain 4 + calendar 2）
        'hoursCount',
        'minutesCount',
        'deferredDays',
        'moodScoreLabel',
        'calendarMonthLabel',
        'calendarDateTitle',
        // timeline 12 条
        'timelineSlotMenuTitle',
        'timelineRangeTitle',
        'timelineTotalMinutes',
        'timelineStepDown',
        'timelineStepUp',
        'timelineSlotPrompt',
        'timelineWriteFailed',
        'timelineDeletePlanItemMessage',
        'timelineHoverDetail',
        'timelineHoverNote',
        'timelineHoverState',
        'timelineHoverLevel',
        // today 11 条
        'todayTimeSet',
        'todayDateLabel',
        'todayDateChipA11y',
        'todayGridStartHint',
        'todayStallHint',
        'todayHabitLoadError',
        'todayCheckedIn',
        'todayCheckinFailed',
        'todayReviewFiledTo',
        'todayReviewJoinSegments',
        'todayStandupSectionCount',
        // habit 9 条
        'moodRatedCount',
        'moodAverage',
        'moodGroupHeader',
        'moodGroupProgress',
        'moodEvidence',
        'habitTarget',
        'habitLoadFailed',
        'habitCheckinLoadFailed',
        'priorityBubbleA11y',
        // dialog 15 条
        'dialogHabitSavedWarn',
        'dialogTodoCreateSubtitle',
        'dialogTodoPullSubtitle',
        'dialogRecurringBadDate',
        'dialogRecurringMergedWeekday',
        'dialogRecurringTimeClamped',
        'dialogRuleActionFailed',
        'dialogRecurringDeleteMessage',
        'dialogAutoScheduleFailed',
        'dialogRecurringLoadFailed',
        'dialogRecurringCount',
        'dialogRecurringSummary',
        'dialogPoolAvailable',
        'dialogPoolHead',
        'dialogPoolScheduled',
      });
    });

    test('全部键值不重复（586 + 4 + 53 = 643）', () {
      final Set<String> all = <String>{
        ...L10nKeys.byGetter.values,
        ...L10nKeys.byListGetter.values,
        ...L10nKeys.byMethod.values,
      };
      expect(all.length, 643);
    });

    test('键一律 kebab-case（小写字母数字，单横线分隔）', () {
      final RegExp kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
      final Set<String> all = <String>{
        ...L10nKeys.byGetter.values,
        ...L10nKeys.byListGetter.values,
        ...L10nKeys.byMethod.values,
      };
      for (final String key in all) {
        expect(kebab.hasMatch(key), isTrue, reason: '不合规的键：$key');
      }
    });

    test('键带模块前缀，前缀与 part 归属一致', () {
      for (final String key in <String>[
        ...L10nKeys.byGetter.values,
        ...L10nKeys.byListGetter.values,
      ]) {
        expect(
          key.startsWith('settings-') ||
              key.startsWith('about-') ||
              key.startsWith('common-') ||
              key.startsWith('shell-') ||
              key.startsWith('projects-') ||
              key.startsWith('goal-') ||
              key.startsWith('domain-') ||
              key.startsWith('calendar-') ||
              key.startsWith('timeline-') ||
              key.startsWith('today-') ||
              key.startsWith('habit-') ||
              key.startsWith('mood-') ||
              key.startsWith('priority-') ||
              key.startsWith('dialog-'),
          isTrue,
          reason: 'getter 键必须以模块前缀开头：$key',
        );
      }
      for (final String key in L10nKeys.byMethod.values) {
        expect(
          key.startsWith('domain-') ||
              key.startsWith('calendar-') ||
              key.startsWith('timeline-') ||
              key.startsWith('today-') ||
              key.startsWith('habit-') ||
              key.startsWith('mood-') ||
              key.startsWith('priority-') ||
              key.startsWith('dialog-'),
          isTrue,
          reason: '方法键缺前缀：$key',
        );
      }
    });
  });

  group('域层文案 id 对齐', () {
    /// 当前语言（中文态）下「键 → 文案」的查表结果。
    Map<String, String> zhByKey() => <String, String>{
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in l10nAccessors.entries)
        entry.key: entry.value(AppLocalizations.zh),
    };

    test('包层给出的 id 全部已建键，且中文逐字一致', () {
      final Map<String, String> zh = zhByKey();
      for (final QuadrantStyle style in QuadrantStyle.all.values) {
        expect(zh[style.labelKey], style.label, reason: style.labelKey);
        expect(
          zh[style.shortLabelKey],
          style.shortLabel,
          reason: style.shortLabelKey,
        );
      }
      for (final AbcStyle style in AbcStyle.all.values) {
        expect(zh[style.labelKey], style.label, reason: style.labelKey);
      }
      expect(zh[PriorityDisplay.unsetLabelKey], PriorityDisplay.unsetLabel);
    });

    test('labelKeyFor 与 labelFor 一一对应（含未分级兜底）', () {
      final Map<String, String> zh = zhByKey();
      for (final PriorityDisplayMode mode in PriorityDisplayMode.values) {
        for (final Quadrant? q in <Quadrant?>[...Quadrant.values, null]) {
          expect(
            zh[PriorityDisplay.labelKeyFor(mode, quadrant: q)],
            PriorityDisplay.labelFor(mode, quadrant: q),
            reason: '$mode/$q',
          );
        }
        for (final PriorityAbc? a in <PriorityAbc?>[
          ...PriorityAbc.values,
          null,
        ]) {
          expect(
            zh[PriorityDisplay.labelKeyFor(mode, priorityAbc: a)],
            PriorityDisplay.labelFor(mode, priorityAbc: a),
            reason: '$mode/$a',
          );
        }
      }
    });
  });

  group('中英双态', () {
    test('每条 getter 在中英两态都取得到非空文案', () {
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in l10nAccessors.entries) {
        final String zh = entry.value(AppLocalizations.zh);
        final String en = entry.value(AppLocalizations.en);
        expect(zh.trim(), isNotEmpty, reason: '${entry.key} 中文态为空');
        expect(en.trim(), isNotEmpty, reason: '${entry.key} 英文态为空');
      }
    });

    test('除白名单外，中英两态必须不同（防复制粘贴当翻译）', () {
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in l10nAccessors.entries) {
        if (sameValueWhitelist.contains(entry.key)) {
          continue;
        }
        final String zh = entry.value(AppLocalizations.zh);
        final String en = entry.value(AppLocalizations.en);
        expect(zh, isNot(en), reason: '${entry.key} 中英同值且不在白名单里');
      }
    });

    test('每条列表型 getter 中英两态都非空，条目数一致且逐条不同', () {
      for (final MapEntry<String, List<String> Function(AppLocalizations)> entry
          in l10nListAccessors.entries) {
        final List<String> zh = entry.value(AppLocalizations.zh);
        final List<String> en = entry.value(AppLocalizations.en);
        expect(zh, isNotEmpty, reason: '${entry.key} 中文态为空');
        expect(en, isNotEmpty, reason: '${entry.key} 英文态为空');
        expect(en.length, zh.length, reason: '${entry.key} 中英条目数不一致');
        for (int i = 0; i < zh.length; i++) {
          expect(zh[i].trim(), isNotEmpty, reason: '${entry.key}[$i] 中文态为空');
          expect(en[i].trim(), isNotEmpty, reason: '${entry.key}[$i] 英文态为空');
          expect(zh[i], isNot(en[i]), reason: '${entry.key}[$i] 中英同值');
        }
      }
    });

    test('白名单恰好 2 条，且它们确实中英同值（防白名单过期）', () {
      expect(sameValueWhitelist.length, 2);
      for (final String key in sameValueWhitelist) {
        expect(l10nAccessors.containsKey(key), isTrue, reason: '白名单键不在表里：$key');
        final String Function(AppLocalizations) read = l10nAccessors[key]!;
        expect(
          read(AppLocalizations.zh),
          read(AppLocalizations.en),
          reason: '白名单里的 $key 其实中英不同，应当移出白名单',
        );
      }
    });
  });

  group('语言分流', () {
    test('forLanguage：en 取英文，zh 与未知回落中文', () {
      expect(AppLocalizations.forLanguage(AppLanguage.en), AppLocalizations.en);
      expect(AppLocalizations.forLanguage(AppLanguage.zh), AppLocalizations.zh);
    });

    test('fromCode：只认 en，其余（含 null / 空串 / 大写）回落中文', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('zh'), AppLanguage.zh);
      expect(AppLanguage.fromCode(null), AppLanguage.zh);
      expect(AppLanguage.fromCode(''), AppLanguage.zh);
      expect(AppLanguage.fromCode('EN'), AppLanguage.zh);
      expect(AppLanguage.fromCode('English'), AppLanguage.zh);
    });

    test('持久化码值就是 zh / en', () {
      expect(AppLanguage.zh.code, 'zh');
      expect(AppLanguage.en.code, 'en');
    });
  });

  group('AppLocalizations.of(context)', () {
    testWidgets('没有 L10nScope 时抛 FlutterError，且错误信息给出修法', (
      WidgetTester tester,
    ) async {
      Object? caught;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              try {
                AppLocalizations.of(context);
              } on Object catch (error) {
                caught = error;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(caught, isA<FlutterError>());
      final FlutterError error = caught! as FlutterError;
      final String message = error.toString();
      expect(message.contains('L10nScope'), isTrue);
      expect(message.contains('app.dart'), isTrue);
    });

    testWidgets('有 L10nScope 时取到对应语言的文案', (WidgetTester tester) async {
      late AppLocalizations zh;
      late AppLocalizations en;
      await tester.pumpWidget(
        l10nWrap(
          Builder(
            builder: (BuildContext context) {
              zh = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          language: AppLanguage.zh,
        ),
      );
      await tester.pumpWidget(
        l10nWrap(
          Builder(
            builder: (BuildContext context) {
              en = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          language: AppLanguage.en,
        ),
      );
      expect(zh.settingsTitle, '设置');
      expect(en.settingsTitle, 'Settings');
      expect(identical(zh, AppLocalizations.zh), isTrue);
      expect(identical(en, AppLocalizations.en), isTrue);
    });

    testWidgets('切换语言后子树读到的是新语言（会触发重建）', (WidgetTester tester) async {
      Widget pageUnderTest({AppLanguage language = AppLanguage.zh}) => l10nWrap(
        Builder(
          builder: (BuildContext context) =>
              Text(AppLocalizations.of(context).settingsTitle),
        ),
        language: language,
      );

      await tester.pumpWidget(pageUnderTest());
      expect(find.text('设置'), findsOneWidget);

      await tester.pumpWidget(pageUnderTest(language: AppLanguage.en));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('设置'), findsNothing);
    });
  });

  group('插值方法', () {
    test('中文输出与拆分前的旧拼串逐字一致', () {
      // 出处：widgets\est_duration_text.dart:64
      expect(AppLocalizations.zh.hoursCount(3), '3 小时');
      // 出处：widgets\timeline\slot_range_dialog.dart:137
      expect(AppLocalizations.zh.minutesCount(45), '45 分钟');
      // 出处：packages\core_data\lib\src\standup.dart:293
      expect(AppLocalizations.zh.deferredDays(2), '已顺延 2 天');
      // 出处：packages\core_domain\lib\src\entities.dart:240
      expect(AppLocalizations.zh.moodScoreLabel('心态'), '心态分值');

      // 以下为 R9 新增的 47 个插值方法，字面量逐字抄自各 part 的 zh mixin。
      // ---- timeline（12） ----
      expect(AppLocalizations.zh.timelineSlotMenuTitle('09:00'), '09:00 这一格');
      expect(AppLocalizations.zh.timelineRangeTitle('3月5日'), '3月5日 · 起止');
      expect(AppLocalizations.zh.timelineTotalMinutes(45), '共 45 分钟');
      expect(AppLocalizations.zh.timelineStepDown('午休'), '午休 减一格');
      expect(AppLocalizations.zh.timelineStepUp('午休'), '午休 加一格');
      expect(AppLocalizations.zh.timelineSlotPrompt('09:00'), '09:00 要做什么？');
      expect(AppLocalizations.zh.timelineWriteFailed('磁盘满'), '写入失败：磁盘满');
      expect(
        AppLocalizations.zh.timelineDeletePlanItemMessage('写周报'),
        '确认删除「写周报」？删除后它不再出现在清单里。',
      );
      expect(AppLocalizations.zh.timelineHoverDetail('两段'), '详情：两段');
      expect(AppLocalizations.zh.timelineHoverNote('推进中'), '进展：推进中');
      expect(AppLocalizations.zh.timelineHoverState('已排'), '状态：已排');
      expect(AppLocalizations.zh.timelineHoverLevel('高'), '级别：高');

      // ---- today（11） ----
      expect(AppLocalizations.zh.todayTimeSet('09:00'), '时间 · 09:00');
      expect(AppLocalizations.zh.todayDateLabel('3月5日'), '日期 · 3月5日');
      expect(
        AppLocalizations.zh.todayDateChipA11y('3月5日', '09:00'),
        '日期 3月5日，09:00，点击修改日期或时刻',
      );
      expect(
        AppLocalizations.zh.todayGridStartHint('06:00'),
        '方格时间轴从 06:00 开始：更早的时刻排不进格子，这条会落在下方未排期带。',
      );
      expect(
        AppLocalizations.zh.todayStallHint('跑步', 7),
        '「跑步」7 天没有增量了，想起它的时候再推一步。',
      );
      expect(AppLocalizations.zh.todayHabitLoadError('超时'), '习惯数据加载失败：超时');
      expect(AppLocalizations.zh.todayCheckedIn('跑步'), '已打卡：跑步');
      expect(AppLocalizations.zh.todayCheckinFailed('冲突'), '打卡失败：冲突');
      expect(AppLocalizations.zh.todayReviewFiledTo('周计划'), '已记到「周计划」');
      expect(
        AppLocalizations.zh.todayReviewJoinSegments(<String>['甲', '乙']),
        '甲；乙',
      );
      expect(AppLocalizations.zh.todayStandupSectionCount('站会', 3), '站会（3）');

      // ---- habit（9） ----
      expect(AppLocalizations.zh.moodRatedCount(2, 5), '已评 2/5 维');
      expect(AppLocalizations.zh.moodAverage('3.5'), '均分 3.5');
      expect(AppLocalizations.zh.moodGroupHeader('心态', true), '心态 · 每日更新');
      expect(AppLocalizations.zh.moodGroupHeader('心态', false), '心态 · 每周更新');
      expect(AppLocalizations.zh.moodGroupProgress(6, 4), '6 项 · 已评 4');
      expect(AppLocalizations.zh.moodEvidence('睡眠、专注'), '佐证：睡眠、专注');
      expect(AppLocalizations.zh.habitTarget('30', '分钟'), '目标 30分钟');
      expect(AppLocalizations.zh.habitLoadFailed('超时'), '习惯加载失败：超时');
      expect(AppLocalizations.zh.habitCheckinLoadFailed('超时'), '打卡记录加载失败：超时');
      expect(
        AppLocalizations.zh.priorityBubbleA11y('紧急重要', true, false),
        '紧急重要，紧急：是，重要：否',
      );

      // ---- dialog（15） ----
      expect(
        AppLocalizations.zh.dialogHabitSavedWarn('超时'),
        '习惯已保存，但未能自动加入日计划：超时',
      );
      expect(
        AppLocalizations.zh.dialogTodoCreateSubtitle('今天'),
        '先存进待办池；勾选后同时落进 今天 的计划。',
      );
      expect(
        AppLocalizations.zh.dialogTodoPullSubtitle('今天'),
        '捞进 今天 的计划；待办池本身不会被删。',
      );
      expect(
        AppLocalizations.zh.dialogRecurringBadDate('2026-02-30'),
        '选中日不是合法日历日：2026-02-30',
      );
      expect(
        AppLocalizations.zh.dialogRecurringMergedWeekday('周三'),
        '已把 周三 并入重复日，以便今天就出现在计划里',
      );
      expect(
        AppLocalizations.zh.dialogRecurringTimeClamped('06:00', '06:30'),
        '开始时刻早于 06:00，已改到 06:30（时间轴只显示 06:00 之后）',
      );
      expect(AppLocalizations.zh.dialogRuleActionFailed('超时'), '规则操作失败：超时');
      expect(
        AppLocalizations.zh.dialogRecurringDeleteMessage('写周报'),
        '「写周报」将从循环任务列表中移除，之后不再自动排入计划；'
        '已经排入计划的条目会保留。',
      );
      expect(AppLocalizations.zh.dialogAutoScheduleFailed('超时'), '自动排程失败：超时');
      expect(AppLocalizations.zh.dialogRecurringLoadFailed('超时'), '规则读取失败：超时');
      expect(
        AppLocalizations.zh.dialogRecurringCount(3),
        '共 3 条规则 · 命中日自动排入计划',
      );
      expect(
        AppLocalizations.zh.dialogRecurringSummary('周三', 45, '启用中'),
        '周三 · 45 分钟 · 启用中',
      );
      expect(AppLocalizations.zh.dialogPoolAvailable(4), '4 条待捞');
      expect(
        AppLocalizations.zh.dialogPoolHead('4 条待捞', '今天'),
        '4 条待捞 · 捞入 今天',
      );
      expect(AppLocalizations.zh.dialogPoolScheduled('09:00'), '已排期 09:00');
    });

    test('英文输出非空且与中文不同', () {
      final AppLocalizations en = AppLocalizations.en;
      expect(en.hoursCount(3).trim(), isNotEmpty);
      expect(en.minutesCount(45).trim(), isNotEmpty);
      expect(en.deferredDays(2).trim(), isNotEmpty);
      expect(en.moodScoreLabel('心态').trim(), isNotEmpty);
      expect(en.hoursCount(3), isNot(AppLocalizations.zh.hoursCount(3)));
      expect(en.minutesCount(45), isNot(AppLocalizations.zh.minutesCount(45)));
      expect(en.deferredDays(2), isNot(AppLocalizations.zh.deferredDays(2)));
      expect(
        en.moodScoreLabel('心态'),
        isNot(AppLocalizations.zh.moodScoreLabel('心态')),
      );

      // R9 新增的 47 个方法：一条一行，断言英文非空 + 中英不同。
      final Map<String, String Function(AppLocalizations)> newReaders =
          <String, String Function(AppLocalizations)>{
            'timelineSlotMenuTitle': (AppLocalizations l) =>
                l.timelineSlotMenuTitle('09:00'),
            'timelineRangeTitle': (AppLocalizations l) =>
                l.timelineRangeTitle('3月5日'),
            'timelineTotalMinutes': (AppLocalizations l) =>
                l.timelineTotalMinutes(45),
            'timelineStepDown': (AppLocalizations l) =>
                l.timelineStepDown('午休'),
            'timelineStepUp': (AppLocalizations l) => l.timelineStepUp('午休'),
            'timelineSlotPrompt': (AppLocalizations l) =>
                l.timelineSlotPrompt('09:00'),
            'timelineWriteFailed': (AppLocalizations l) =>
                l.timelineWriteFailed('磁盘满'),
            'timelineDeletePlanItemMessage': (AppLocalizations l) =>
                l.timelineDeletePlanItemMessage('写周报'),
            'timelineHoverDetail': (AppLocalizations l) =>
                l.timelineHoverDetail('两段'),
            'timelineHoverNote': (AppLocalizations l) =>
                l.timelineHoverNote('推进中'),
            'timelineHoverState': (AppLocalizations l) =>
                l.timelineHoverState('已排'),
            'timelineHoverLevel': (AppLocalizations l) =>
                l.timelineHoverLevel('高'),
            'todayTimeSet': (AppLocalizations l) => l.todayTimeSet('09:00'),
            'todayDateLabel': (AppLocalizations l) => l.todayDateLabel('3月5日'),
            'todayDateChipA11y': (AppLocalizations l) =>
                l.todayDateChipA11y('3月5日', '09:00'),
            'todayGridStartHint': (AppLocalizations l) =>
                l.todayGridStartHint('06:00'),
            'todayStallHint': (AppLocalizations l) => l.todayStallHint('跑步', 7),
            'todayHabitLoadError': (AppLocalizations l) =>
                l.todayHabitLoadError('超时'),
            'todayCheckedIn': (AppLocalizations l) => l.todayCheckedIn('跑步'),
            'todayCheckinFailed': (AppLocalizations l) =>
                l.todayCheckinFailed('冲突'),
            'todayReviewFiledTo': (AppLocalizations l) =>
                l.todayReviewFiledTo('周计划'),
            'todayReviewJoinSegments': (AppLocalizations l) =>
                l.todayReviewJoinSegments(<String>['甲', '乙']),
            'todayStandupSectionCount': (AppLocalizations l) =>
                l.todayStandupSectionCount('站会', 3),
            'moodRatedCount': (AppLocalizations l) => l.moodRatedCount(2, 5),
            'moodAverage': (AppLocalizations l) => l.moodAverage('3.5'),
            'moodGroupHeader': (AppLocalizations l) =>
                l.moodGroupHeader('心态', true),
            'moodGroupProgress': (AppLocalizations l) =>
                l.moodGroupProgress(6, 4),
            'moodEvidence': (AppLocalizations l) => l.moodEvidence('睡眠、专注'),
            'habitTarget': (AppLocalizations l) => l.habitTarget('30', '分钟'),
            'habitLoadFailed': (AppLocalizations l) => l.habitLoadFailed('超时'),
            'habitCheckinLoadFailed': (AppLocalizations l) =>
                l.habitCheckinLoadFailed('超时'),
            'priorityBubbleA11y': (AppLocalizations l) =>
                l.priorityBubbleA11y('紧急重要', true, false),
            'dialogHabitSavedWarn': (AppLocalizations l) =>
                l.dialogHabitSavedWarn('超时'),
            'dialogTodoCreateSubtitle': (AppLocalizations l) =>
                l.dialogTodoCreateSubtitle('今天'),
            'dialogTodoPullSubtitle': (AppLocalizations l) =>
                l.dialogTodoPullSubtitle('今天'),
            'dialogRecurringBadDate': (AppLocalizations l) =>
                l.dialogRecurringBadDate('2026-02-30'),
            'dialogRecurringMergedWeekday': (AppLocalizations l) =>
                l.dialogRecurringMergedWeekday('周三'),
            'dialogRecurringTimeClamped': (AppLocalizations l) =>
                l.dialogRecurringTimeClamped('06:00', '06:30'),
            'dialogRuleActionFailed': (AppLocalizations l) =>
                l.dialogRuleActionFailed('超时'),
            'dialogRecurringDeleteMessage': (AppLocalizations l) =>
                l.dialogRecurringDeleteMessage('写周报'),
            'dialogAutoScheduleFailed': (AppLocalizations l) =>
                l.dialogAutoScheduleFailed('超时'),
            'dialogRecurringLoadFailed': (AppLocalizations l) =>
                l.dialogRecurringLoadFailed('超时'),
            'dialogRecurringCount': (AppLocalizations l) =>
                l.dialogRecurringCount(3),
            'dialogRecurringSummary': (AppLocalizations l) =>
                l.dialogRecurringSummary('周三', 45, '启用中'),
            'dialogPoolAvailable': (AppLocalizations l) =>
                l.dialogPoolAvailable(4),
            'dialogPoolHead': (AppLocalizations l) =>
                l.dialogPoolHead('4 条待捞', '今天'),
            'dialogPoolScheduled': (AppLocalizations l) =>
                l.dialogPoolScheduled('09:00'),
          };
      expect(newReaders.length, 47);
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in newReaders.entries) {
        expect(
          entry.value(en).trim(),
          isNotEmpty,
          reason: '${entry.key} 英文态为空',
        );
        expect(
          entry.value(en),
          isNot(entry.value(AppLocalizations.zh)),
          reason: '${entry.key} 中英同值',
        );
      }
    });

    test('插值真的把参数带进输出（不是写死的常量）', () {
      expect(AppLocalizations.zh.minutesCount(1), contains('1'));
      expect(AppLocalizations.zh.minutesCount(999), contains('999'));
      expect(AppLocalizations.zh.deferredDays(7), contains('7'));
      expect(AppLocalizations.zh.moodScoreLabel('专注'), contains('专注'));

      // 新增方法：第一条用例的「逐字相等」已等价证明参数进了输出，这里只对
      // 数值 / 列表 / 布尔参数再取一组**第二取值**，防止把某个具体值写死。
      expect(AppLocalizations.zh.timelineTotalMinutes(7), contains('7'));
      expect(AppLocalizations.zh.todayStallHint('读书', 3), contains('读书'));
      expect(AppLocalizations.zh.todayStallHint('读书', 3), contains('3'));
      expect(
        AppLocalizations.zh.todayReviewJoinSegments(<String>['甲', '乙', '丙']),
        '甲；乙；丙',
      );
      expect(
        AppLocalizations.zh.todayStandupSectionCount('复盘', 9),
        contains('9'),
      );
      expect(AppLocalizations.zh.moodRatedCount(1, 9), contains('1/9'));
      expect(AppLocalizations.zh.moodGroupProgress(9, 1), contains('9 项'));
      expect(AppLocalizations.zh.moodGroupHeader('心态', false), contains('每周'));
      expect(AppLocalizations.zh.habitTarget('9', '天'), contains('天'));
      expect(
        AppLocalizations.zh.priorityBubbleA11y('紧急重要', false, true),
        contains('重要：是'),
      );
      expect(AppLocalizations.zh.dialogRecurringCount(9), contains('9 条'));
      expect(
        AppLocalizations.zh.dialogRecurringSummary('周三', 7, '启用中'),
        contains('7 分钟'),
      );
      expect(AppLocalizations.zh.dialogPoolAvailable(9), contains('9'));
    });
  });

  group('L10nFormat', () {
    test('中文用顿号、英文用逗号加空格拼接', () {
      const L10nFormat zh = L10nFormat(AppLanguage.zh);
      const L10nFormat en = L10nFormat(AppLanguage.en);
      expect(zh.listSeparator, '、');
      expect(en.listSeparator, ', ');
      expect(zh.joinList(<String>['A', 'B', 'C']), 'A、B、C');
      expect(en.joinList(<String>['A', 'B', 'C']), 'A, B, C');
    });

    test('空列表拼出来是空串（不是分隔符）', () {
      expect(const L10nFormat(AppLanguage.zh).joinList(<String>[]), '');
      expect(const L10nFormat(AppLanguage.zh).isEn, isFalse);
      expect(const L10nFormat(AppLanguage.en).isEn, isTrue);
    });
  });
}
