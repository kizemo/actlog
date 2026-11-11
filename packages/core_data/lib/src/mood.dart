// =============================================================================
// core_data · 心态 8 维与「今日失守」（P1-8）
// =============================================================================
// 核心不变量（core_domain 的 DayLog.validated 也强制，这里是 UI 侧的同一道闸）：
//   **任一维度为 0 ⇒ moodFailed 必须为 true。**
// 反过来不成立：用户可以在没有 0 分维度时手动打「失守」标记（比如整天没做事
// 但心情都还行）。所以 moodFailed 不是纯派生值，它有一个「不可撤销为假」的约束。
// =============================================================================

import 'package:core_domain/core_domain.dart';

import 'models.dart';

/// 心态得分下限。
const int moodScoreMin = 0;

/// 心态得分上限。
const int moodScoreMax = 10;

/// 心态 8 维工具集。
abstract final class MoodRules {
  /// 校验单个维度得分；非法值抛 [ArgumentError]。
  static void assertValidScore(int score) {
    if (score < moodScoreMin || score > moodScoreMax) {
      throw ArgumentError.value(
        score,
        'score',
        '心态得分必须在 $moodScoreMin..$moodScoreMax',
      );
    }
  }

  /// 任一维度为 0。
  static bool hasZero(Map<MoodDimension, int> scores) =>
      scores.values.any((v) => v == 0);

  /// 计算出最终应该落库的失守标记。
  ///
  /// [requested] 是用户手动勾选的值。规则：**只允许被打开，不允许被关掉** ——
  /// 存在 0 分维度时，即使 UI 传来 false 也必须落 true。
  /// 这是为了防止「用户先打 0 分、再取消勾选」造出违反 schema 不变量的一行。
  static bool resolveFailed({
    required Map<MoodDimension, int> scores,
    required bool requested,
  }) {
    if (hasZero(scores)) {
      return true;
    }
    return requested;
  }

  /// 组装总览。
  static MoodSummary summarize({
    required Map<MoodDimension, int> scores,
    required bool requestedFailed,
    String note = '',
  }) {
    for (final score in scores.values) {
      assertValidScore(score);
    }
    return MoodSummary(
      scores: Map<MoodDimension, int>.unmodifiable(scores),
      failed: resolveFailed(scores: scores, requested: requestedFailed),
      note: note,
    );
  }

  /// 把得分映射到数据库列名（`mood_1`..`mood_8`）。
  static String columnOf(MoodDimension dimension) => dimension.column;

  /// 把 `{MoodDimension: score}` 摊平为 `{列名: 值}`，供 drift companion 使用。
  ///
  /// **未打分的维度不出现在结果里** —— 数据库列可空，未打分必须是 NULL 而不是 0。
  /// 把未打分写成 0 会让每一条日志都被判成失守。
  static Map<String, int> toColumns(Map<MoodDimension, int> scores) {
    final out = <String, int>{};
    for (final entry in scores.entries) {
      assertValidScore(entry.value);
      out[entry.key.column] = entry.value;
    }
    return out;
  }

  /// 从数据库列值还原得分；NULL 与越界值一律忽略（不抛异常）。
  static Map<MoodDimension, int> fromColumns(Map<String, int?> columns) {
    final out = <MoodDimension, int>{};
    for (final dimension in MoodDimension.all) {
      final value = columns[dimension.column];
      if (value == null) {
        continue;
      }
      if (value < moodScoreMin || value > moodScoreMax) {
        continue;
      }
      out[dimension] = value;
    }
    return out;
  }
}