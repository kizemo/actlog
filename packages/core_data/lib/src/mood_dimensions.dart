// =============================================================================
// core_data · 心态维度映射（需求 6 / Task 40 A1.4）
// =============================================================================
// 零 schema 变更：这里**不新增列**，只把既有 `mood_1..mood_8` 重新归组成
// 「3 个日维度 + 2 个周维度」，8 个 legacy 列全部仍被引用 ⇒ 老数据零丢失。
//
// 主存列 / 佐证列一律从 `core_domain` 的 `MoodDimension` 枚举取 `.column`，
// 不在本文件另造一套列名，避免两处口径漂移。分数合法区间沿用 `MoodRules`
// 的 `moodScoreMin..moodScoreMax`；越界值与 NULL 一律按「未评」处理。
// =============================================================================

import 'package:core_db/core_db.dart' show DayLogData;
import 'package:core_domain/core_domain.dart';

import 'mood.dart';

/// 心态维度的统计周期。
enum MoodPeriod {
  /// 日维度：每天更新（3 项：履约负责 / 高效高质 / 积极思维）。
  day('日'),

  /// 周维度：每周补充（2 项：自我效能 / 利他贡献）。
  week('周');

  const MoodPeriod(this.label);

  /// 中文标签（UI 上标注周期用）。
  final String label;
}

/// 单个维度得分的来源。
enum MoodScoreSource {
  /// 主存列有合法值，直接采用。
  primary,

  /// 主存列缺失，由佐证列的合法值均值回退得出。
  supporting,

  /// 主存列与佐证列都没有合法值 —— 视为未评。
  none,
}

/// 一个心态维度的定义（key / 标签 / 文案 / 周期 / 主存列 / 佐证列）。
final class MoodDimensionDef {
  /// 创建维度定义。
  const MoodDimensionDef({
    required this.key,
    required this.label,
    required this.description,
    required this.period,
    required this.primary,
    this.supporting = const <MoodDimension>[],
  });

  /// 稳定标识（英文，落盘与测试用，不随文案变动）。
  final String key;

  /// 中文标签。
  final String label;

  /// 一行以内的提示文案。
  final String description;

  /// 统计周期（日 / 周）。
  final MoodPeriod period;

  /// 主存列对应的 legacy 维度。
  final MoodDimension primary;

  /// 佐证子项对应的 legacy 维度（可为空）。
  final List<MoodDimension> supporting;

  /// 主存列名（如 `mood_3`）。
  String get primaryColumn => primary.column;

  /// 佐证列名列表（可能为空）。
  List<String> get supportingColumns => <String>[
    for (final MoodDimension dimension in supporting) dimension.column,
  ];

  /// 主存列 + 佐证列（该维度会读到的全部 legacy 列）。
  List<String> get allColumns => <String>[primaryColumn, ...supportingColumns];
}

/// 5 个心态维度定义：3 个日维度在前、2 个周维度在后（即 UI 展示顺序）。
const List<MoodDimensionDef> moodDimensionDefs = <MoodDimensionDef>[
  MoodDimensionDef(
    key: 'fulfillment',
    label: '履约负责',
    description: '说到就做到：先守住已经答应的交付。',
    period: MoodPeriod.day,
    primary: MoodDimension.keepPromise,
    supporting: <MoodDimension>[
      MoodDimension.finishTask,
      MoodDimension.noExcuses,
    ],
  ),
  MoodDimensionDef(
    key: 'efficiency',
    label: '高效高质',
    description: '要事优先：先把可支配的时间给最重要的那件事。',
    period: MoodPeriod.day,
    primary: MoodDimension.diligent,
    supporting: <MoodDimension>[MoodDimension.fast],
  ),
  MoodDimensionDef(
    key: 'positiveMind',
    label: '积极思维',
    description: '积极主动：把注意力放在自己能影响的部分。',
    period: MoodPeriod.day,
    primary: MoodDimension.optimistic,
  ),
  MoodDimensionDef(
    key: 'selfEfficacy',
    label: '自我效能',
    description: '以终为始：这周是否完成了自己认定的关键一步。',
    period: MoodPeriod.week,
    primary: MoodDimension.confident,
  ),
  MoodDimensionDef(
    key: 'contribution',
    label: '利他贡献',
    description: '贡献而非努力：这一周为别人解决了什么具体问题。',
    period: MoodPeriod.week,
    primary: MoodDimension.loveAndDedication,
  ),
];

/// 按 [key] 取维度定义；未知 key 抛 [ArgumentError]。
MoodDimensionDef moodDimensionDefOf(String key) {
  for (final MoodDimensionDef definition in moodDimensionDefs) {
    if (definition.key == key) {
      return definition;
    }
  }
  throw ArgumentError.value(key, 'key', '未知的心态维度 key');
}

/// 8 个 legacy 心态列名（与 `MoodDimension.all` 一一对应，顺序同为 `mood_1..8`）。
final List<String> legacyMoodColumns = <String>[
  for (final MoodDimension dimension in MoodDimension.all) dimension.column,
];

/// 「明日改进点」落库列名（该列现在归心态侧所有）。
const String moodNextActionColumn = 'next_action';

/// 「明日改进点」的中文标签。
const String moodNextActionLabel = '明日改进点';

/// 从 `day_log` 的一行取出 8 个 legacy 心态值，键为列名。
Map<String, int?> moodColumnsOfDayLog(DayLogData row) {
  return <String, int?>{
    MoodDimension.diligent.column: row.mood1,
    MoodDimension.fast.column: row.mood2,
    MoodDimension.keepPromise.column: row.mood3,
    MoodDimension.finishTask.column: row.mood4,
    MoodDimension.optimistic.column: row.mood5,
    MoodDimension.confident.column: row.mood6,
    MoodDimension.loveAndDedication.column: row.mood7,
    MoodDimension.noExcuses.column: row.mood8,
  };
}

/// 单个维度的得分结果。
final class MoodDimensionScore {
  /// 创建得分结果。
  const MoodDimensionScore({
    required this.definition,
    required this.score,
    required this.source,
  });

  /// 对应的维度定义。
  final MoodDimensionDef definition;

  /// 0–10 的得分；未评为 `null`。
  final double? score;

  /// 得分来源。
  final MoodScoreSource source;

  /// 是否已评（[score] 非空）。
  bool get rated => score != null;
}

/// 按列名 → 分数映射算出 5 个维度的得分（顺序同 [moodDimensionDefs]）。
///
/// 规则：主存列有合法值 ⇒ 用它（[MoodScoreSource.primary]）；
/// 否则取佐证列合法值的均值（[MoodScoreSource.supporting]）；
/// 都没有 ⇒ `score == null`、未评（[MoodScoreSource.none]）。
List<MoodDimensionScore> scoreMoodDimensions(Map<String, int?> columns) {
  return <MoodDimensionScore>[
    for (final MoodDimensionDef definition in moodDimensionDefs)
      _scoreOneDimension(definition, columns),
  ];
}

/// 直接从 `day_log` 的一行算出 5 个维度的得分。
List<MoodDimensionScore> scoreMoodDimensionsOfDayLog(DayLogData row) {
  return scoreMoodDimensions(moodColumnsOfDayLog(row));
}

/// 已评维度的均分；未评维度不参与分母。
///
/// [period] 为 `null` 时统计全部 5 个维度，否则只统计该周期的维度。
/// 没有任何已评维度时返回 `null`。
double? meanMoodScore(
  Iterable<MoodDimensionScore> scores, {
  MoodPeriod? period,
}) {
  double sum = 0;
  int count = 0;
  for (final MoodDimensionScore score in scores) {
    if (!_matchesPeriod(score, period)) {
      continue;
    }
    sum += score.score ?? 0;
    count += 1;
  }
  if (count == 0) {
    return null;
  }
  return sum / count;
}

/// 已评维度计数（[period] 为 `null` 时统计全部 5 个维度）。
int ratedMoodDimensionCount(
  Iterable<MoodDimensionScore> scores, {
  MoodPeriod? period,
}) {
  int count = 0;
  for (final MoodDimensionScore score in scores) {
    if (_matchesPeriod(score, period)) {
      count += 1;
    }
  }
  return count;
}

MoodDimensionScore _scoreOneDimension(
  MoodDimensionDef definition,
  Map<String, int?> columns,
) {
  final int? primary = _validScore(columns[definition.primaryColumn]);
  if (primary != null) {
    return MoodDimensionScore(
      definition: definition,
      score: primary.toDouble(),
      source: MoodScoreSource.primary,
    );
  }
  final List<int> supporting = <int>[];
  for (final String column in definition.supportingColumns) {
    final int? value = _validScore(columns[column]);
    if (value != null) {
      supporting.add(value);
    }
  }
  if (supporting.isEmpty) {
    return MoodDimensionScore(
      definition: definition,
      score: null,
      source: MoodScoreSource.none,
    );
  }
  int sum = 0;
  for (final int value in supporting) {
    sum += value;
  }
  return MoodDimensionScore(
    definition: definition,
    score: sum / supporting.length,
    source: MoodScoreSource.supporting,
  );
}

/// 越界值与 `null` 一律视为「没有值」。
int? _validScore(int? value) {
  if (value == null) {
    return null;
  }
  if (value < moodScoreMin || value > moodScoreMax) {
    return null;
  }
  return value;
}

bool _matchesPeriod(MoodDimensionScore score, MoodPeriod? period) {
  if (!score.rated) {
    return false;
  }
  if (period != null && score.definition.period != period) {
    return false;
  }
  return true;
}