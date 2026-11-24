// apps/desktop/test/task63_w5_l10n_test.dart
//
// Task 63 批次二 · W5（心态 / 习惯 / 优先级）的双语装置。
//
// 守三件事（计划 §47.3）：
//   1. **中文态逐字**：`l10n\parts\habit.dart` 的 44 条无参 getter 取值必须与
//      迁移前的字面量一字不差（空格、全角 `（）`、`·`(U+00B7)、`–`(U+2013)、
//      `—`(U+2014)、句末 `。` 都不能少）—— 这一波是「纯重构、零语义变化」，
//      中文漂移就是回归；
//   2. **英文态逐字**：同一批成员在 en 下是新措辞，逐字钉住，防止后续把
//      zh 值误抄进 en mixin（两段一一对应但值不同，抄错不会编译失败）；
//   3. **阴性对照**：en 的 44 条无参 getter 里一处汉字都没有；zh 的 44 条
//      全都含汉字。否则上面两条可能一直成立却什么都没证明。
//
// 断言一律断**字面量**：全文件没有一处 `find.text(t.xxx)` / `expect(x, t.xxx)`
//   式的同义反复（§47.3 铁律 1）。同一个值在测试里写死，才有判别力。
//
// 带参数的 9 个方法单独成组：参数替换点（`$rated` / `$total` / `$value` /
//   `$joined` / `$amount` / `$unit` / `$error`）以及 zh/en 的分隔符差异
//   （`已评 N/M 维` vs `N/M rated`、`目标 N次` vs `Target N times`）都在这一组钉住。
//
// 组件级接线由本波其余门禁覆盖（W5-11 芯片视觉、W5-12 200% 溢出含 en 态、
//   W5-13 吸底条、W5-14 习惯区/习惯页），本文件只负责字表本身。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// 与 `AppLocalizations.forLanguage` 同源，避免测试里硬编码 mixin 类型。
final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);
final AppLocalizations en = AppLocalizations.forLanguage(AppLanguage.en);

/// 44 条无参 getter 的「名字 → 取值」，供阴性对照整批扫描。
Map<String, String> allGetters(AppLocalizations l) => <String, String>{
      'moodGroupDayTitle': l.moodGroupDayTitle,
      'moodGroupWeekTitle': l.moodGroupWeekTitle,
      'moodSectionSubtitle': l.moodSectionSubtitle,
      'moodClearAll': l.moodClearAll,
      'moodMarkFailed': l.moodMarkFailed,
      'moodNextActionLabel': l.moodNextActionLabel,
      'moodNextActionHint': l.moodNextActionHint,
      'moodNoteLabel': l.moodNoteLabel,
      'moodNoteHint': l.moodNoteHint,
      'moodUnrated': l.moodUnrated,
      'moodClearDimension': l.moodClearDimension,
      'moodDimFulfillmentLabel': l.moodDimFulfillmentLabel,
      'moodDimFulfillmentDesc': l.moodDimFulfillmentDesc,
      'moodDimEfficiencyLabel': l.moodDimEfficiencyLabel,
      'moodDimEfficiencyDesc': l.moodDimEfficiencyDesc,
      'moodDimPositiveMindLabel': l.moodDimPositiveMindLabel,
      'moodDimPositiveMindDesc': l.moodDimPositiveMindDesc,
      'moodDimSelfEfficacyLabel': l.moodDimSelfEfficacyLabel,
      'moodDimSelfEfficacyDesc': l.moodDimSelfEfficacyDesc,
      'moodDimContributionLabel': l.moodDimContributionLabel,
      'moodDimContributionDesc': l.moodDimContributionDesc,
      'moodLegacyDiligent': l.moodLegacyDiligent,
      'moodLegacyFast': l.moodLegacyFast,
      'moodLegacyKeepPromise': l.moodLegacyKeepPromise,
      'moodLegacyFinishTask': l.moodLegacyFinishTask,
      'moodLegacyOptimistic': l.moodLegacyOptimistic,
      'moodLegacyConfident': l.moodLegacyConfident,
      'moodLegacyLoveAndDedication': l.moodLegacyLoveAndDedication,
      'moodLegacyNoExcuses': l.moodLegacyNoExcuses,
      'habitSectionTitle': l.habitSectionTitle,
      'habitSectionSubtitle': l.habitSectionSubtitle,
      'habitSectionEmpty': l.habitSectionEmpty,
      'habitCheckinLoading': l.habitCheckinLoading,
      'habitCheckinError': l.habitCheckinError,
      'habitCheckinHeadTitle': l.habitCheckinHeadTitle,
      'habitCheckinHeadHint': l.habitCheckinHeadHint,
      'habitPageTitle': l.habitPageTitle,
      'habitPageFutureHint': l.habitPageFutureHint,
      'habitPageEmpty': l.habitPageEmpty,
      'priorityPickQuadrant': l.priorityPickQuadrant,
      'priorityPickAbc': l.priorityPickAbc,
      'priorityBubbleCurrent': l.priorityBubbleCurrent,
      'priorityBubbleReadonly': l.priorityBubbleReadonly,
      'priorityBubbleEditable': l.priorityBubbleEditable,
    };

/// 汉字区间（用于阴性对照）。只判汉字，不判全角标点：en 里出现 `·` 是允许的
/// （`Habit check-in · pinned, no scroll`），出现汉字则说明串了 zh 值。
final RegExp cjk = RegExp(r'[\u4e00-\u9fff]');

void main() {
  group('中文态逐字（迁移前后必须一字不差）', () {
    test('心态分组与副标题', () {
      expect(zh.moodGroupDayTitle, '每日核心');
      expect(zh.moodGroupWeekTitle, '每周补充');
      // 注意是 `0–10`（U+2013 en dash），不是连字符、不是 em dash。
      expect(zh.moodSectionSubtitle, '每日 3 项 + 每周 2 项，各 0–10 分；留空表示不作评');
    });

    test('心态操作与状态八条', () {
      expect(zh.moodClearAll, '全部清空');
      expect(zh.moodMarkFailed, '今天没打分');
      expect(zh.moodNextActionLabel, '明日改进点');
      expect(zh.moodNextActionHint, '明天先做的一件具体事');
      expect(zh.moodNoteLabel, '情绪备注');
      expect(zh.moodNoteHint, '今天状态如何？为什么？');
      expect(zh.moodUnrated, '未评');
      expect(zh.moodClearDimension, '清除这一维');
    });

    test('心态 5 个维度的名称', () {
      expect(zh.moodDimFulfillmentLabel, '履约负责');
      expect(zh.moodDimEfficiencyLabel, '高效高质');
      expect(zh.moodDimPositiveMindLabel, '积极思维');
      expect(zh.moodDimSelfEfficacyLabel, '自我效能');
      expect(zh.moodDimContributionLabel, '利他贡献');
    });

    test('心态 5 个维度的说明（句末带句号）', () {
      expect(zh.moodDimFulfillmentDesc, '说到就做到：先守住已经答应的交付。');
      expect(zh.moodDimEfficiencyDesc, '要事优先：先把可支配的时间给最重要的那件事。');
      expect(zh.moodDimPositiveMindDesc, '积极主动：把注意力放在自己能影响的部分。');
      expect(zh.moodDimSelfEfficacyDesc, '以终为始：这周是否完成了自己认定的关键一步。');
      expect(zh.moodDimContributionDesc, '贡献而非努力：这一周为别人解决了什么具体问题。');
    });

    test('心态 legacy 8 列（历史数据展示）', () {
      expect(zh.moodLegacyDiligent, '认真');
      expect(zh.moodLegacyFast, '快');
      expect(zh.moodLegacyKeepPromise, '坚守承诺');
      expect(zh.moodLegacyFinishTask, '保证完成任务');
      expect(zh.moodLegacyOptimistic, '乐观');
      expect(zh.moodLegacyConfident, '自信');
      expect(zh.moodLegacyLoveAndDedication, '爱与奉献');
      expect(zh.moodLegacyNoExcuses, '决不找借口');
    });

    test('习惯区块与吸底条', () {
      expect(zh.habitSectionTitle, '习惯打卡');
      expect(zh.habitSectionSubtitle, '打勾会同步生成今日计划里的回填行');
      // 与 `domainNoHabitsDueToday` 不是同一条：这条句末有 `。`。
      expect(zh.habitSectionEmpty, '今天没有排程内的习惯。');
      expect(zh.habitCheckinLoading, '正在加载打卡状态…');
      expect(zh.habitCheckinError, '打卡状态加载失败，请稍后重试');
      expect(zh.habitCheckinHeadTitle, '习惯打卡 · 吸底不滚动');
      expect(zh.habitCheckinHeadHint, '· 一点即打，跳过需理由');
    });

    test('习惯页三条', () {
      expect(zh.habitPageTitle, '习惯');
      expect(zh.habitPageFutureHint, '未来日只做预排：习惯打卡在当天开放。');
      expect(zh.habitPageEmpty, '还没有习惯');
    });

    test('优先级五条', () {
      expect(zh.priorityPickQuadrant, '选择四象限');
      expect(zh.priorityPickAbc, '选择 ABC 优先级');
      expect(zh.priorityBubbleCurrent, '当前');
      expect(zh.priorityBubbleReadonly, '点标记开关 · 分级写入未开放');
      expect(zh.priorityBubbleEditable, '点标记开关 · 点维度改分级');
    });
  });

  group('英文态逐字（新文案，防 zh 值误抄）', () {
    test('心态分组与副标题', () {
      expect(en.moodGroupDayTitle, 'Daily core');
      expect(en.moodGroupWeekTitle, 'Weekly add-on');
      expect(
        en.moodSectionSubtitle,
        '3 daily + 2 weekly items, 0–10 each; leave blank to skip',
      );
    });

    test('心态操作与状态八条', () {
      expect(en.moodClearAll, 'Clear all');
      expect(en.moodMarkFailed, 'Not scored today');
      // en 用弯引号 `’`（U+2019），不是直引号。
      expect(en.moodNextActionLabel, 'Tomorrow’s improvement point');
      expect(en.moodNextActionHint, 'One concrete thing to do first tomorrow');
      expect(en.moodNoteLabel, 'Mood note');
      expect(en.moodNoteHint, 'How was today? Why?');
      expect(en.moodUnrated, 'Unrated');
      expect(en.moodClearDimension, 'Clear this dimension');
    });

    test('心态 5 个维度的名称与说明', () {
      expect(en.moodDimFulfillmentLabel, 'Keeps promises');
      expect(
        en.moodDimFulfillmentDesc,
        'Do what you said: protect the commitments you already made.',
      );
      expect(en.moodDimEfficiencyLabel, 'Effective and high quality');
      expect(
        en.moodDimEfficiencyDesc,
        'First things first: spend your available time on what matters most.',
      );
      expect(en.moodDimPositiveMindLabel, 'Positive mindset');
      expect(
        en.moodDimPositiveMindDesc,
        'Be proactive: focus on the part you can influence.',
      );
      expect(en.moodDimSelfEfficacyLabel, 'Self-efficacy');
      expect(
        en.moodDimSelfEfficacyDesc,
        'Begin with the end in mind: did you complete the key step you set this week?',
      );
      expect(en.moodDimContributionLabel, 'Contribution');
      expect(
        en.moodDimContributionDesc,
        'Contribution over effort: what concrete problem did you solve for others this week?',
      );
    });

    test('心态 legacy 8 列', () {
      expect(en.moodLegacyDiligent, 'Diligent');
      expect(en.moodLegacyFast, 'Fast');
      expect(en.moodLegacyKeepPromise, 'Keep promises');
      expect(en.moodLegacyFinishTask, 'Finish the task');
      expect(en.moodLegacyOptimistic, 'Optimistic');
      expect(en.moodLegacyConfident, 'Confident');
      expect(en.moodLegacyLoveAndDedication, 'Love and dedication');
      expect(en.moodLegacyNoExcuses, 'No excuses');
    });

    test('习惯区块与吸底条', () {
      expect(en.habitSectionTitle, 'Habit check-in');
      expect(
        en.habitSectionSubtitle,
        'Checking a habit also adds a backfill row to today’s plan',
      );
      expect(en.habitSectionEmpty, 'No habits are scheduled today.');
      expect(en.habitCheckinLoading, 'Loading check-in status…');
      expect(
        en.habitCheckinError,
        'Failed to load check-in status, try again later',
      );
      expect(en.habitCheckinHeadTitle, 'Habit check-in · pinned, no scroll');
      expect(
        en.habitCheckinHeadHint,
        '· one tap to log, a reason is required to skip',
      );
    });

    test('习惯页三条', () {
      expect(en.habitPageTitle, 'Habits');
      expect(
        en.habitPageFutureHint,
        'Future days are for scheduling only: check-in opens on the day itself.',
      );
      expect(en.habitPageEmpty, 'No habits yet');
    });

    test('优先级五条', () {
      expect(en.priorityPickQuadrant, 'Choose a quadrant');
      expect(en.priorityPickAbc, 'Choose an ABC priority');
      expect(en.priorityBubbleCurrent, 'Current');
      expect(
        en.priorityBubbleReadonly,
        'Tap a mark to toggle · grading is read-only',
      );
      expect(
        en.priorityBubbleEditable,
        'Tap a mark to toggle · tap a dimension to regrade',
      );
    });
  });

  group('带参数的 9 个方法', () {
    test('中文态：参数落位与分隔符逐字', () {
      expect(zh.moodRatedCount(2, 5), '已评 2/5 维');
      expect(zh.moodAverage('7.5'), '均分 7.5');
      // 均分可以为 `—`（U+2014）：没打分时不伪造 0。
      expect(zh.moodAverage('—'), '均分 —');
      expect(zh.moodGroupHeader('每日核心', true), '每日核心 · 每日更新');
      expect(zh.moodGroupHeader('每周补充', false), '每周补充 · 每周更新');
      expect(zh.moodGroupProgress(3, 1), '3 项 · 已评 1');
      expect(zh.moodEvidence('认真、快'), '佐证：认真、快');
      // 落库单位 `次` 由 `_displayUnit` 映射成显示文案。
      expect(zh.habitTarget('30', zh.commonUnitTimes), '目标 30次');
      expect(zh.habitLoadFailed('timeout'), '习惯加载失败：timeout');
      expect(zh.habitCheckinLoadFailed('timeout'), '打卡记录加载失败：timeout');
      expect(
        zh.priorityBubbleA11y('紧急且重要', true, true),
        '紧急且重要，紧急：是，重要：是',
      );
      expect(
        zh.priorityBubbleA11y('不紧急不重要', false, false),
        '不紧急不重要，紧急：否，重要：否',
      );
    });

    test('英文态：参数落位与分隔符逐字', () {
      expect(en.moodRatedCount(2, 5), '2/5 rated');
      expect(en.moodAverage('7.5'), 'Avg 7.5');
      expect(en.moodGroupHeader('Daily core', true), 'Daily core · updated daily');
      expect(
        en.moodGroupHeader('Weekly add-on', false),
        'Weekly add-on · updated weekly',
      );
      expect(en.moodGroupProgress(3, 1), '3 items · 1 rated');
      expect(en.moodEvidence('diligent, fast'), 'Evidence: diligent, fast');
      // en 的 `次` 显示为 `times`，且数字与单位之间**有空格**（zh 紧贴）。
      expect(en.habitTarget('30', en.commonUnitTimes), 'Target 30 times');
      expect(en.habitLoadFailed('timeout'), 'Failed to load habits: timeout');
      expect(
        en.habitCheckinLoadFailed('timeout'),
        'Failed to load check-in records: timeout',
      );
      expect(
        en.priorityBubbleA11y('Urgent and important', true, true),
        'Urgent and important, urgent: yes, important: yes',
      );
      expect(
        en.priorityBubbleA11y('Not urgent and not important', false, false),
        'Not urgent and not important, urgent: no, important: no',
      );
    });
  });

  group('阴性对照', () {
    test('en 的 44 条无参 getter 里一处汉字都没有', () {
      final values = allGetters(en);
      expect(values, hasLength(44));
      final leaked = <String>[
        for (final entry in values.entries)
          if (cjk.hasMatch(entry.value)) '${entry.key}=${entry.value}',
      ];
      expect(leaked, isEmpty, reason: 'en 里出现汉字 ⇒ 抄了 zh 值');
    });

    test('zh 的 44 条无参 getter 全都含汉字', () {
      final values = allGetters(zh);
      expect(values, hasLength(44));
      final missed = <String>[
        for (final entry in values.entries)
          if (!cjk.hasMatch(entry.value)) entry.key,
      ];
      expect(missed, isEmpty, reason: 'zh 里没有汉字 ⇒ 抄了 en 值');
    });

    test('同一键 zh/en 逐字不同（同值白名单不扩到本波）', () {
      final zhValues = allGetters(zh);
      final enValues = allGetters(en);
      expect(enValues.keys, zhValues.keys);
      final same = <String>[
        for (final key in zhValues.keys)
          if (zhValues[key] == enValues[key]) key,
      ];
      expect(
        same,
        isEmpty,
        reason: '同值键只允许 settings-language-zh / -en 两条（本波零同值）',
      );
    });
  });
}