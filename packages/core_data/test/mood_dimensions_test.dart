// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · 心态维度映射门禁（Task 40 A1.4）
// =============================================================================
// 钉住四件事：
//   1. 5 个维度与派工书规格表逐字一致（key / 标签 / 周期 / 主存列 / 佐证列）；
//   2. 8 个 legacy 列**全部**仍被引用 ⇒ 老数据零丢失；
//   3. 打分规则：主存列优先 → 佐证列均值回退 → 未评；越界值按未评处理；
//   4. 「明日改进点」这一列归心态侧所有：saveMood 可写、saveReview 不再抢写。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const String _date = '2026-11-11';

/// 8 个 legacy 列的原始口径（mood_1..mood_8）。
const List<String> _rawColumns = <String>[
  'mood_1',
  'mood_2',
  'mood_3',
  'mood_4',
  'mood_5',
  'mood_6',
  'mood_7',
  'mood_8',
];

Map<String, MoodDimensionScore> _byKey(List<MoodDimensionScore> scores) {
  return <String, MoodDimensionScore>{
    for (final MoodDimensionScore score in scores)
      score.definition.key: score,
  };
}

MoodSummary _mood() {
  return MoodRules.summarize(
    scores: <MoodDimension, int>{MoodDimension.keepPromise: 8},
    requestedFailed: false,
  );
}

void main() {
  group('维度定义', () {
    test('5 个维度与规格表逐字一致', () {
      expect(
        <String>[for (final MoodDimensionDef def in moodDimensionDefs) def.key],
        <String>[
          'fulfillment',
          'efficiency',
          'positiveMind',
          'selfEfficacy',
          'contribution',
        ],
      );
      expect(
        <String>[
          for (final MoodDimensionDef def in moodDimensionDefs) def.label,
        ],
        <String>['履约负责', '高效高质', '积极思维', '自我效能', '利他贡献'],
      );
      expect(
        <String>[
          for (final MoodDimensionDef def in moodDimensionDefs)
            def.period.label,
        ],
        <String>['日', '日', '日', '周', '周'],
      );
      expect(
        <String>[
          for (final MoodDimensionDef def in moodDimensionDefs)
            def.primaryColumn,
        ],
        <String>['mood_3', 'mood_1', 'mood_5', 'mood_6', 'mood_7'],
      );
      expect(
        <List<String>>[
          for (final MoodDimensionDef def in moodDimensionDefs)
            def.supportingColumns,
        ],
        <List<String>>[
          <String>['mood_4', 'mood_8'],
          <String>['mood_2'],
          <String>[],
          <String>[],
          <String>[],
        ],
      );
    });

    test('提示文案都是一行以内、非空', () {
      for (final MoodDimensionDef def in moodDimensionDefs) {
        expect(def.description, isNotEmpty);
        expect(def.description.contains('\n'), isFalse);
        expect(def.allColumns, contains(def.primaryColumn));
      }
    });

    test('8 个 legacy 列全部仍被使用（老数据零丢失）', () {
      expect(legacyMoodColumns, _rawColumns);

      final Set<String> covered = <String>{
        for (final MoodDimensionDef def in moodDimensionDefs) ...def.allColumns,
      };
      expect(covered, _rawColumns.toSet());
      expect(covered, hasLength(8));
    });

    test('moodDimensionDefOf 命中已知 key，未知 key 抛 ArgumentError', () {
      expect(moodDimensionDefOf('fulfillment').label, '履约负责');
      expect(moodDimensionDefOf('contribution').period, MoodPeriod.week);
      expect(
        () => moodDimensionDefOf('nope'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('打分', () {
    test('老数据 8 列全填：主存列优先，source 为 primary', () {
      final List<MoodDimensionScore> scores = scoreMoodDimensions(<String, int?>{
        'mood_1': 7,
        'mood_2': 5,
        'mood_3': 9,
        'mood_4': 6,
        'mood_5': 8,
        'mood_6': 4,
        'mood_7': 10,
        'mood_8': 3,
      });
      final Map<String, MoodDimensionScore> byKey = _byKey(scores);
      expect(byKey['fulfillment']!.score, 9);
      expect(byKey['fulfillment']!.source, MoodScoreSource.primary);
      expect(byKey['efficiency']!.score, 7);
      expect(byKey['positiveMind']!.score, 8);
      expect(byKey['selfEfficacy']!.score, 4);
      expect(byKey['contribution']!.score, 10);
      expect(ratedMoodDimensionCount(scores), 5);
    });

    test('主存列缺失时回退到佐证列均值', () {
      final Map<String, MoodDimensionScore> byKey = _byKey(
        scoreMoodDimensions(<String, int?>{
          'mood_2': 4,
          'mood_3': null,
          'mood_4': 6,
          'mood_8': 8,
        }),
      );
      expect(byKey['fulfillment']!.score, 7);
      expect(byKey['fulfillment']!.source, MoodScoreSource.supporting);
      // 主存列 mood_1 缺失，佐证列 mood_2 单值直接等于自身。
      expect(byKey['efficiency']!.score, 4);
      expect(byKey['efficiency']!.source, MoodScoreSource.supporting);
    });

    test('空行：5 维全部未评', () {
      final List<MoodDimensionScore> scores =
          scoreMoodDimensions(<String, int?>{});
      expect(scores, hasLength(5));
      for (final MoodDimensionScore score in scores) {
        expect(score.rated, isFalse);
        expect(score.score, isNull);
        expect(score.source, MoodScoreSource.none);
      }
      expect(ratedMoodDimensionCount(scores), 0);
      expect(meanMoodScore(scores), isNull);
    });

    test('越界值按未评处理，不污染均分', () {
      final Map<String, MoodDimensionScore> byKey = _byKey(
        scoreMoodDimensions(<String, int?>{
          'mood_5': 11,
          'mood_3': -1,
          'mood_4': 6,
          'mood_8': 8,
        }),
      );
      // 11 > moodScoreMax ⇒ 积极思维未评。
      expect(byKey['positiveMind']!.score, isNull);
      expect(byKey['positiveMind']!.source, MoodScoreSource.none);
      // -1 越界 ⇒ 主存列作废，回退佐证均值 (6 + 8) / 2。
      expect(byKey['fulfillment']!.score, 7);
      expect(byKey['fulfillment']!.source, MoodScoreSource.supporting);
    });

    test('日维度均值 / 周维度均值 / 已评计数', () {
      final List<MoodDimensionScore> scores = scoreMoodDimensions(<String, int?>{
        'mood_1': 6,
        'mood_3': 8,
        'mood_6': 4,
      });
      expect(ratedMoodDimensionCount(scores), 3);
      expect(ratedMoodDimensionCount(scores, period: MoodPeriod.day), 2);
      expect(ratedMoodDimensionCount(scores, period: MoodPeriod.week), 1);
      expect(meanMoodScore(scores), 6);
      expect(meanMoodScore(scores, period: MoodPeriod.day), 7);
      expect(meanMoodScore(scores, period: MoodPeriod.week), 4);
    });
  });

  group('day_log 行适配', () {
    late ActLogDatabase db;
    late ActLogRepositories repos;

    setUp(() {
      db = openInMemoryActLogDatabase();
      repos = ActLogRepositories(db, deviceId: 'dev-test');
    });

    tearDown(() async {
      await db.close();
    });

    test('moodColumnsOfDayLog / scoreMoodDimensionsOfDayLog 与列映射一致', () async {
      final DayLogData row = await repos.dayLog.ensureByDate(_date);
      await repos.dayLog.saveMood(
        row.id,
        MoodRules.summarize(
          scores: <MoodDimension, int>{
            MoodDimension.keepPromise: 8,
            MoodDimension.diligent: 6,
            MoodDimension.confident: 4,
          },
          requestedFailed: false,
        ),
      );

      final DayLogData after = (await repos.dayLog.findByDate(_date))!;
      expect(moodColumnsOfDayLog(after).keys.toSet(), _rawColumns.toSet());

      final List<MoodDimensionScore> scores =
          scoreMoodDimensionsOfDayLog(after);
      final Map<String, MoodDimensionScore> byKey = _byKey(scores);
      expect(byKey['fulfillment']!.score, 8);
      expect(byKey['efficiency']!.score, 6);
      expect(byKey['positiveMind']!.score, isNull);
      expect(byKey['selfEfficacy']!.score, 4);
      expect(byKey['contribution']!.score, isNull);
      expect(ratedMoodDimensionCount(scores), 3);
    });
  });

  group('「明日改进点」列归心态侧所有', () {
    late ActLogDatabase db;
    late ActLogRepositories repos;

    setUp(() {
      db = openInMemoryActLogDatabase();
      repos = ActLogRepositories(db, deviceId: 'dev-test');
    });

    tearDown(() async {
      await db.close();
    });

    test('列名常量是 next_action', () {
      expect(moodNextActionColumn, 'next_action');
      expect(moodNextActionLabel, '明日改进点');
    });

    test('saveMood 传 nextAction 时写入该列', () async {
      final DayLogData row = await repos.dayLog.ensureByDate(_date);
      await repos.dayLog.saveMood(row.id, _mood(), nextAction: '明天先打三个电话');
      final DayLogData after = (await repos.dayLog.findByDate(_date))!;
      expect(after.nextAction, '明天先打三个电话');
      expect(after.mood3, 8);
    });

    test('saveMood 不传 nextAction 时保留原值（不清空）', () async {
      final DayLogData row = await repos.dayLog.ensureByDate(_date);
      await repos.dayLog.saveMood(row.id, _mood(), nextAction: '明天先打三个电话');
      await repos.dayLog.saveMood(row.id, _mood());
      final DayLogData after = (await repos.dayLog.findByDate(_date))!;
      expect(after.nextAction, '明天先打三个电话');
    });

    test('saveReview 不再写 next_action，不会清空心态侧的值', () async {
      final DayLogData row = await repos.dayLog.ensureByDate(_date);
      await repos.dayLog.saveMood(row.id, _mood(), nextAction: '明天先打三个电话');

      await repos.dayLog.saveReview(
        row.id,
        const ReviewDraft(good: '守时', nextAction: '复盘侧旧字段'),
      );

      final DayLogData after = (await repos.dayLog.findByDate(_date))!;
      expect(after.good, '守时');
      expect(
        after.nextAction,
        '明天先打三个电话',
        reason: '复盘侧已删除该字段，继续写会把心态侧数据清空',
      );
    });
  });
}