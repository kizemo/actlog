// apps/desktop/test/task63_w4_l10n_test.dart
//
// Task 63 批次二 · W4（今天页与复盘）的双语装置。
//
// 守三件事（计划 §47.3）：
//   1. **中文态逐字**：`l10n\parts\today.dart` 的 55 条成员取值必须与迁移前的
//      字面量一字不差（空格、全角 `（）` / `—` / `；`、中点 `·` 都不能少）——
//      这一波是「纯重构、零语义变化」，中文漂移就是回归；
//   2. **英文态逐字**：同一批成员在 en 下是新措辞，逐字钉住，防止后续把
//      zh 值误抄进 en mixin（两段一一对应但值不同，抄错不会编译失败）；
//   3. **阴性对照**：en 的 44 条无参 getter 里一处中文都没有；zh 的 44 条
//      全都含中文。否则上面两条可能一直成立却什么都没证明。
//
// 断言一律断**字面量**：全文件没有一处 `find.text(t.xxx)` / `expect(x, t.xxx)`
//   式的同义反复（§47.3 铁律 1）。同一个值在测试里写死，才有判别力。
//
// 带参数的方法单独成组：参数替换点（`$time` / `$name` / `$count`）以及
//   zh/en 的分隔符差异（`；` vs `; `、`（）` vs ` ()`）都在这一组钉住。
//
// 闭环环补两个 widget 级用例：它是本波唯一能不依赖 DB / Provider 直接 pump
//   的组件（`LoopProgressRing(l10n: ...)`），用来证明「getter 真的接到了
//   画面上」，而不只是取值正确。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/widgets/loop_progress_ring.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 与 `AppLocalizations.forLanguage` 同源，避免测试里硬编码 mixin 类型。
final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);
final AppLocalizations en = AppLocalizations.forLanguage(AppLanguage.en);

/// 44 条无参 getter 的「名字 → 取值」，供阴性对照整批扫描。
Map<String, String> allGetters(AppLocalizations l) => <String, String>{
      'todayReviewFutureTitle': l.todayReviewFutureTitle,
      'todayReviewFutureDetail': l.todayReviewFutureDetail,
      'todayFuturePlanOnly': l.todayFuturePlanOnly,
      'todayFuturePlanning': l.todayFuturePlanning,
      'todayChangeDate': l.todayChangeDate,
      'todayChangeTime': l.todayChangeTime,
      'todayClearTime': l.todayClearTime,
      'todayTimeUnset': l.todayTimeUnset,
      'todayPickStartTime': l.todayPickStartTime,
      'todayAddPlanHint': l.todayAddPlanHint,
      'todayAddManual': l.todayAddManual,
      'todayHabitLoadFailed': l.todayHabitLoadFailed,
      'todayHabitLoading': l.todayHabitLoading,
      'todayHabitEmpty': l.todayHabitEmpty,
      'todayStatPlanGap': l.todayStatPlanGap,
      'todayStatFillGap': l.todayStatFillGap,
      'todayStatWritten': l.todayStatWritten,
      'todayStatUnwritten': l.todayStatUnwritten,
      'todayStatRecorded': l.todayStatRecorded,
      'todayStatUnrecorded': l.todayStatUnrecorded,
      'todayStallDismiss': l.todayStallDismiss,
      'todayNoticeFutureCheckin': l.todayNoticeFutureCheckin,
      'todayGotIt': l.todayGotIt,
      'todayReviewFieldLearn': l.todayReviewFieldLearn,
      'todayReviewFieldLearnHint': l.todayReviewFieldLearnHint,
      'todayReviewFieldGood': l.todayReviewFieldGood,
      'todayReviewFieldGoodHint': l.todayReviewFieldGoodHint,
      'todayReviewFieldImprove': l.todayReviewFieldImprove,
      'todayReviewFieldImproveHint': l.todayReviewFieldImproveHint,
      'todayReviewSubtitle': l.todayReviewSubtitle,
      'todayReviewEmptyNotice': l.todayReviewEmptyNotice,
      'todayReviewPickProject': l.todayReviewPickProject,
      'todayReviewFileToProject': l.todayReviewFileToProject,
      'todayLoopRingA11y': l.todayLoopRingA11y,
      'todayLoopRingScale': l.todayLoopRingScale,
      'todayStandupTitle': l.todayStandupTitle,
      'todayStandupSubtitle': l.todayStandupSubtitle,
      'todayStandupEmpty': l.todayStandupEmpty,
      'todayStandupYesterday': l.todayStandupYesterday,
      'todayStandupYesterdayEmpty': l.todayStandupYesterdayEmpty,
      'todayStandupToday': l.todayStandupToday,
      'todayStandupTodayEmpty': l.todayStandupTodayEmpty,
      'todayStandupBlockers': l.todayStandupBlockers,
      'todayStandupBlockersEmpty': l.todayStandupBlockersEmpty,
    };

/// 汉字区间（用于阴性对照）。只判汉字，不判全角标点：en 里出现 `·` 是允许的
/// （`Time · Unset`），出现汉字则说明串了 zh 值。
final RegExp cjk = RegExp(r'[\u4e00-\u9fff]');

void main() {
  group('中文态逐字（迁移前后必须一字不差）', () {
    test('未来日与锁定卡的四条文案', () {
      expect(zh.todayReviewFutureTitle, '复盘与心态在当天开放');
      expect(zh.todayReviewFutureDetail, '未来日只做预排：到了那天再写复盘与心态。');
      expect(zh.todayFuturePlanOnly, '未来日只可预排：可以先写计划，到了那天才能打卡与回填。');
      expect(zh.todayFuturePlanning, '未来日只做预排');
    });

    test('手写条的日期与时刻按钮', () {
      expect(zh.todayChangeDate, '改日期');
      expect(zh.todayChangeTime, '改时刻');
      expect(zh.todayClearTime, '清除时刻');
      expect(zh.todayTimeUnset, '时间 · 未排');
      expect(zh.todayPickStartTime, '选择开始时刻');
      expect(zh.todayAddPlanHint, '添加计划条目…');
      expect(zh.todayAddManual, '+ 手写一条');
    });

    test('右轨习惯速览与闭环提示的标签状态词', () {
      expect(zh.todayHabitLoadFailed, '习惯速览加载失败');
      expect(zh.todayHabitLoading, '正在加载习惯…');
      expect(zh.todayHabitEmpty, '所选日没有排程习惯');
      expect(zh.todayStatPlanGap, '计划缺口');
      expect(zh.todayStatFillGap, '回填缺口');
      expect(zh.todayStatWritten, '已写');
      expect(zh.todayStatUnwritten, '未写');
      expect(zh.todayStatRecorded, '已记');
      expect(zh.todayStatUnrecorded, '未记');
      expect(zh.todayStallDismiss, '今天不再提');
    });

    test('页内横幅与闭环环刻度', () {
      expect(zh.todayNoticeFutureCheckin, '未来日只做预排：到了那天再打卡。');
      expect(zh.todayGotIt, '知道了');
      expect(zh.todayLoopRingA11y, '闭环环 · 四段比例条');
      // em dash（U+2014），不是半角连字符。
      expect(zh.todayLoopRingScale, '刻度 0—100');
    });

    test('复盘三段与记到项目', () {
      expect(zh.todayReviewFieldLearn, '学到了什么');
      expect(zh.todayReviewFieldLearnHint, '今天最大的一个认知收获');
      expect(zh.todayReviewFieldGood, '做得好');
      expect(zh.todayReviewFieldGoodHint, '值得保留的做法');
      expect(zh.todayReviewFieldImprove, '待改进');
      expect(zh.todayReviewFieldImproveHint, '下次换个做法的地方');
      expect(zh.todayReviewSubtitle, '哪几段有想法就写哪几段，留白不影响保存');
      expect(zh.todayReviewEmptyNotice, '三段都还空着，先写一句再记');
      expect(zh.todayReviewPickProject, '记到哪个项目');
      expect(zh.todayReviewFileToProject, '→ 记到项目');
    });

    test('站会三段', () {
      expect(zh.todayStandupTitle, '站会');
      expect(zh.todayStandupSubtitle, '昨天做成了什么 · 今天最重要的事 · 卡在哪');
      expect(zh.todayStandupEmpty, '三段都还没有内容 —— 先给今天加几条计划，或者去补昨天的记录。');
      expect(zh.todayStandupYesterday, '昨日亮点');
      expect(zh.todayStandupYesterdayEmpty, '昨天没有已完成的条目');
      expect(zh.todayStandupToday, '今日优先');
      expect(zh.todayStandupTodayEmpty, '今天还没有待办条目');
      expect(zh.todayStandupBlockers, '阻塞项');
      expect(zh.todayStandupBlockersEmpty, '没有检测到阻塞 — 保持住');
    });

    test('带参方法的参数替换点与中文分隔符', () {
      expect(zh.todayTimeSet('09:30'), '时间 · 09:30');
      expect(zh.todayDateLabel('2026-11-24'), '日期 · 2026-11-24');
      expect(
        zh.todayDateChipA11y('2026-11-24', '时间 · 未排'),
        '日期 2026-11-24，时间 · 未排，点击修改日期或时刻',
      );
      expect(
        zh.todayGridStartHint('06:00'),
        '方格时间轴从 06:00 开始：更早的时刻排不进格子，这条会落在下方未排期带。',
      );
      expect(
        zh.todayStallHint('复利记账', 4),
        '「复利记账」4 天没有增量了，想起它的时候再推一步。',
      );
      expect(zh.todayHabitLoadError('disk'), '习惯数据加载失败：disk');
      expect(zh.todayCheckedIn('晨读'), '已打卡：晨读');
      expect(zh.todayCheckinFailed('disk'), '打卡失败：disk');
      expect(zh.todayReviewFiledTo('健账'), '已记到「健账」');
      expect(
        zh.todayReviewJoinSegments(<String>['学到了什么', '做得好']),
        '学到了什么；做得好',
      );
      // 全角括号（U+FF08 / U+FF09）。
      expect(zh.todayStandupSectionCount('阻塞项', 3), '阻塞项（3）');
    });
  });

  group('英文态逐字（这一波新定措辞）', () {
    test('未来日、手写条与右轨速览', () {
      expect(en.todayReviewFutureTitle, 'Review and mood open on the day');
      expect(
        en.todayReviewFutureDetail,
        'Future days are for planning only: write the review and mood once the day arrives.',
      );
      expect(
        en.todayFuturePlanOnly,
        'Future days are plan-only: you can write plans now, but check-in and backfill open on the day.',
      );
      expect(en.todayFuturePlanning, 'Future days are plan-only');
      expect(en.todayChangeDate, 'Change date');
      expect(en.todayChangeTime, 'Change time');
      expect(en.todayClearTime, 'Clear time');
      expect(en.todayTimeUnset, 'Time · Unset');
      expect(en.todayPickStartTime, 'Pick a start time');
      expect(en.todayAddPlanHint, 'Add a plan item…');
      expect(en.todayAddManual, '+ Write one');
      expect(en.todayHabitLoadFailed, 'Failed to load the habit overview');
      expect(en.todayHabitLoading, 'Loading habits…');
      expect(en.todayHabitEmpty, 'No habits scheduled for this day');
    });

    test('闭环提示标签、页内横幅与闭环环刻度', () {
      expect(en.todayStatPlanGap, 'Plan gap');
      expect(en.todayStatFillGap, 'Backfill gap');
      expect(en.todayStatWritten, 'Written');
      expect(en.todayStatUnwritten, 'Not written');
      expect(en.todayStatRecorded, 'Logged');
      expect(en.todayStatUnrecorded, 'Not logged');
      expect(en.todayStallDismiss, "Don't mention it today");
      expect(en.todayNoticeFutureCheckin, 'Future days are plan-only: check in once the day arrives.');
      expect(en.todayGotIt, 'Got it');
      expect(en.todayLoopRingA11y, 'Loop ring · four-segment bars');
      // 半角连字符，与 zh 的 em dash 不同——这是刻意的差异，不是笔误。
      expect(en.todayLoopRingScale, 'Scale 0-100');
    });

    test('复盘三段与记到项目', () {
      expect(en.todayReviewFieldLearn, 'What I learned');
      expect(en.todayReviewFieldLearnHint, 'The biggest insight from today');
      expect(en.todayReviewFieldGood, 'What went well');
      expect(en.todayReviewFieldGoodHint, 'Practices worth keeping');
      expect(en.todayReviewFieldImprove, 'What to improve');
      expect(en.todayReviewFieldImproveHint, 'Where to try a different approach next time');
      expect(
        en.todayReviewSubtitle,
        'Write whichever sections you have thoughts on; blanks do not affect saving',
      );
      expect(en.todayReviewEmptyNotice, 'All three sections are empty — write a line before filing');
      expect(en.todayReviewPickProject, 'Which project to file to');
      expect(en.todayReviewFileToProject, '→ File to project');
    });

    test('站会三段', () {
      expect(en.todayStandupTitle, 'Standup');
      expect(
        en.todayStandupSubtitle,
        "What got done yesterday · Today's most important thing · Where you are stuck",
      );
      expect(
        en.todayStandupEmpty,
        "All three sections are empty — add a few plans for today, or fill in yesterday's record.",
      );
      expect(en.todayStandupYesterday, "Yesterday's highlights");
      expect(en.todayStandupYesterdayEmpty, 'Nothing was completed yesterday');
      expect(en.todayStandupToday, "Today's priorities");
      expect(en.todayStandupTodayEmpty, 'No to-dos for today yet');
      expect(en.todayStandupBlockers, 'Blockers');
      expect(en.todayStandupBlockersEmpty, 'No blockers detected — keep it up');
    });

    test('带参方法的参数替换点与英文分隔符', () {
      expect(en.todayTimeSet('09:30'), 'Time · 09:30');
      expect(en.todayDateLabel('2026-11-24'), 'Date · 2026-11-24');
      expect(
        en.todayDateChipA11y('2026-11-24', 'Time · Unset'),
        'Date 2026-11-24, Time · Unset. Tap to change the date or time.',
      );
      expect(
        en.todayGridStartHint('06:00'),
        'The grid starts at 06:00: earlier times do not fit a cell, so this item lands in the unscheduled strip below.',
      );
      expect(
        en.todayStallHint('Ledger', 4),
        '"Ledger" has had no progress for 4 days; push it one step when it comes to mind.',
      );
      expect(en.todayHabitLoadError('disk'), 'Failed to load habit data: disk');
      expect(en.todayCheckedIn('Reading'), 'Checked in: Reading');
      expect(en.todayCheckinFailed('disk'), 'Check-in failed: disk');
      expect(en.todayReviewFiledTo('Ledger'), 'Filed to "Ledger"');
      expect(
        en.todayReviewJoinSegments(<String>['What I learned', 'What went well']),
        'What I learned; What went well',
      );
      // 半角括号 + 空格。
      expect(en.todayStandupSectionCount('Blockers', 3), 'Blockers (3)');
    });
  });

  group('分隔符与拼接的判别性用例', () {
    test('复盘拼接：zh 用全角分号不带空格，en 用半角分号加一个空格', () {
      expect(zh.todayReviewJoinSegments(<String>['a', 'b']), 'a；b');
      expect(en.todayReviewJoinSegments(<String>['a', 'b']), 'a; b');
      // 分号字符不同 ⇒ 两者不可能相等，串了 zh 值就会被抓住。
      expect(
        zh.todayReviewJoinSegments(<String>['a', 'b']),
        isNot(en.todayReviewJoinSegments(<String>['a', 'b'])),
      );
    });

    test('单段与空列表不引入多余分隔符', () {
      expect(zh.todayReviewJoinSegments(<String>['只有一段']), '只有一段');
      expect(en.todayReviewJoinSegments(<String>['only one']), 'only one');
      expect(zh.todayReviewJoinSegments(<String>[]), '');
      expect(en.todayReviewJoinSegments(<String>[]), '');
    });

    test('段头计数：括号全角/半角 + 数字替换', () {
      expect(zh.todayStandupSectionCount('昨日亮点', 0), '昨日亮点（0）');
      expect(en.todayStandupSectionCount('Blockers', 12), 'Blockers (12)');
    });
  });

  group('阴性对照（防止「两条都成立却什么都没证明」）', () {
    test('英文态 44 条 getter 里一处中文都没有', () {
      final Map<String, String> values = allGetters(en);
      expect(values, hasLength(44));
      final List<String> offenders = <String>[
        for (final MapEntry<String, String> e in values.entries)
          if (cjk.hasMatch(e.value)) '${e.key} => ${e.value}',
      ];
      expect(offenders, isEmpty);
    });

    test('中文态 44 条 getter 全都含中文', () {
      final Map<String, String> values = allGetters(zh);
      expect(values, hasLength(44));
      final List<String> missing = <String>[
        for (final MapEntry<String, String> e in values.entries)
          if (!cjk.hasMatch(e.value)) '${e.key} => ${e.value}',
      ];
      expect(missing, isEmpty);
    });

    test('zh 与 en 的 44 条 getter 逐条不同（不存在静默回落）', () {
      final Map<String, String> zhValues = allGetters(zh);
      final Map<String, String> enValues = allGetters(en);
      expect(zhValues.keys, enValues.keys);
      final List<String> same = <String>[
        for (final String key in zhValues.keys)
          if (zhValues[key] == enValues[key]) key,
      ];
      expect(same, isEmpty);
    });
  });

  group('接线证据（闭环环真的把 getter 画到了画面上）', () {
    Future<void> pumpRing(WidgetTester tester, {AppLocalizations? l10n}) async {
      final AppLocalizations resolved = l10n ?? AppLocalizations.zh;
      await tester.pumpWidget(
        l10nScope(
          MaterialApp(
            home: Scaffold(
              body: LoopProgressRing(
                stats: const DayStats(
                  planTotal: 8,
                  planDone: 6,
                  backfilled: 4,
                  reviewDone: false,
                  moodDone: false,
                ),
                l10n: resolved,
              ),
            ),
          ),
          language: resolved.language,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('zh 态：脊线画的是中文字面量', (WidgetTester tester) async {
      await pumpRing(tester);
      expect(find.text('闭环环 · 四段比例条'), findsOneWidget);
      expect(find.text('刻度 0—100'), findsOneWidget);
      // 四段段名复用 parts\domain.dart，没有另建同形键。
      expect(find.text('计划'), findsOneWidget);
      expect(find.text('回填'), findsOneWidget);
      expect(find.text('复盘'), findsOneWidget);
      expect(find.text('心态'), findsOneWidget);
      expect(find.text('Loop ring · four-segment bars'), findsNothing);
    });

    testWidgets('en 态：脊线画的是英文字面量且中文一处不见', (WidgetTester tester) async {
      await pumpRing(tester, l10n: AppLocalizations.en);
      expect(find.text('Loop ring · four-segment bars'), findsOneWidget);
      expect(find.text('Scale 0-100'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Backfill'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);
      expect(find.text('闭环环 · 四段比例条'), findsNothing);
      expect(find.text('复盘'), findsNothing);
      expect(find.text('刻度 0—100'), findsNothing);
    });
  });
}