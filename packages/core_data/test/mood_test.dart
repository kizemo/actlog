// ignore_for_file: public_member_api_docs

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('评分区间', () {
    test('0 与 10 合法', () {
      expect(() => MoodRules.assertValidScore(0), returnsNormally);
      expect(() => MoodRules.assertValidScore(10), returnsNormally);
    });

    test('越界抛 ArgumentError', () {
      expect(() => MoodRules.assertValidScore(-1), throwsArgumentError);
      expect(() => MoodRules.assertValidScore(11), throwsArgumentError);
    });
  });

  group('今日失守（P1-8）', () {
    test('任一维度为 0 即失守', () {
      expect(MoodRules.hasZero(const {MoodDimension.diligent: 0}), isTrue);
      expect(
        MoodRules.hasZero(
          const {MoodDimension.diligent: 5, MoodDimension.fast: 0},
        ),
        isTrue,
      );
      expect(MoodRules.hasZero(const {MoodDimension.diligent: 5}), isFalse);
      expect(MoodRules.hasZero(const {}), isFalse);
    });

    test('失守标记只能被打开，不能被关掉', () {
      final zero = MoodRules.resolveFailed(
        scores: const {MoodDimension.diligent: 0},
        requested: false,
      );
      expect(zero, isTrue);

      final noZero = MoodRules.resolveFailed(
        scores: const {MoodDimension.diligent: 8},
        requested: false,
      );
      expect(noZero, isFalse);

      // 没有 0 分也可以手动标记失守。
      final manual = MoodRules.resolveFailed(
        scores: const {MoodDimension.diligent: 8},
        requested: true,
      );
      expect(manual, isTrue);
    });

    test('summarize 会归一失守标记', () {
      final summary = MoodRules.summarize(
        scores: const {MoodDimension.diligent: 0, MoodDimension.fast: 6},
        requestedFailed: false,
      );
      expect(summary.failed, isTrue);
      expect(summary.hasZero, isTrue);
    });

    test('summarize 校验越界得分', () {
      expect(
        () => MoodRules.summarize(
          scores: const {MoodDimension.diligent: 11},
          requestedFailed: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('列映射与 NULL 语义', () {
    test('未打分的维度不出现，而不是写 0', () {
      final columns = MoodRules.toColumns({
        MoodDimension.diligent: 7,
        MoodDimension.optimistic: 0,
      });
      expect(columns, <String, int>{'mood_1': 7, 'mood_5': 0});
      expect(columns.containsKey('mood_2'), isFalse);
    });

    test('空映射就是空列集', () {
      expect(MoodRules.toColumns(const {}), isEmpty);
    });

    test('fromColumns 忽略 NULL 与越界值', () {
      final back = MoodRules.fromColumns(<String, int?>{
        'mood_1': 9,
        'mood_2': null,
        'mood_3': 11,
        'mood_4': -2,
        'mood_8': 0,
      });
      expect(back, <MoodDimension, int>{
        MoodDimension.diligent: 9,
        MoodDimension.noExcuses: 0,
      });
    });

    test('toColumns / fromColumns 往返一致', () {
      final source = <MoodDimension, int>{
        MoodDimension.diligent: 3,
        MoodDimension.keepPromise: 10,
        MoodDimension.loveAndDedication: 0,
      };
      expect(MoodRules.fromColumns(MoodRules.toColumns(source)), source);
    });

    test('columnOf 与维度自身的列名一致', () {
      for (final dimension in MoodDimension.all) {
        expect(MoodRules.columnOf(dimension), dimension.column);
      }
      expect(MoodDimension.all.length, 8);
    });
  });

  group('总览统计', () {
    test('一维没打时平均分为 null 而不是 0', () {
      const summary = MoodSummary(scores: {}, failed: false, note: '');
      expect(summary.average, isNull);
      expect(summary.ratedCount, 0);
    });

    test('平均分按已打分维度计算', () {
      const summary = MoodSummary(
        scores: {MoodDimension.diligent: 6, MoodDimension.fast: 10},
        failed: false,
        note: '',
      );
      expect(summary.average, 8);
      expect(summary.ratedCount, 2);
    });
  });
}