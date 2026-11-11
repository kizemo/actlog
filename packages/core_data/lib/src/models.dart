// =============================================================================
// core_data · 视图模型
// =============================================================================
// 这里只放「有业务含义、且值得单测」的聚合结构。原始行数据由 drift 生成类承载，
// 不在这里重新包一层 —— 那只会制造两份需要同步的定义。
// =============================================================================

import 'package:core_domain/core_domain.dart';

/// 站会三段的一条来源。
enum StandupSource {
  /// 昨天已完成（或已达成）的计划条目。
  yesterdayDone('yesterday_done'),

  /// 昨天日志「做得好的」自由文本。
  yesterdayGoodText('yesterday_good_text'),

  /// 今天待办的计划条目。
  todayPlanned('today_planned'),

  /// 昨天没做完、顺延到今天的条目。
  carriedOver('carried_over'),

  /// 习惯打卡自动回填生成的条目。
  habitRef('habit_ref'),

  /// 长线项目增量里记录的阻塞。
  projectBlocker('project_blocker');

  const StandupSource(this.code);

  /// 稳定标识（写入日志 / 测试断言用）。
  final String code;
}

/// 站会三段中的一条。
final class StandupEntry {
  /// 创建条目。
  const StandupEntry({
    required this.id,
    required this.title,
    required this.source,
    this.quadrant,
    this.priorityAbc,
    this.note = '',
    this.carriedOverDays = 0,
  });

  /// 原始实体 id（计划条目 / 项目增量 / 日志日）。
  final String id;

  /// 展示标题。
  final String title;

  /// 来源。
  final StandupSource source;

  /// 四象限（可能为空）。
  final Quadrant? quadrant;

  /// ABC 优先级（可能为空）。
  final PriorityAbc? priorityAbc;

  /// 附注（顺延说明、阻塞描述等）。
  final String note;

  /// 已顺延天数（0 = 不是顺延条目）。
  final int carriedOverDays;

  @override
  String toString() => 'StandupEntry(${source.name}: $title)';
}

/// 站会三段视图 —— P1-2 的交付物。
final class StandupBrief {
  /// 创建站会视图。
  const StandupBrief({
    required this.date,
    required this.yesterdayHighlights,
    required this.todayPriorities,
    required this.blockers,
  });

  /// 站会对齐的日历日（今天）。
  final String date;

  /// 昨日亮点。
  final List<StandupEntry> yesterdayHighlights;

  /// 今日优先。
  final List<StandupEntry> todayPriorities;

  /// 阻塞项。
  final List<StandupEntry> blockers;

  /// 三段都为空 —— UI 用它决定是否显示引导文案。
  bool get isEmpty =>
      yesterdayHighlights.isEmpty &&
      todayPriorities.isEmpty &&
      blockers.isEmpty;
}

/// 心态 8 维的当日总览 —— P1-8 的交付物。
final class MoodSummary {
  /// 创建总览。
  const MoodSummary({
    required this.scores,
    required this.failed,
    required this.note,
  });

  /// 各维度得分（缺省维度不出现在这里，与数据库 NULL 语义一致）。
  final Map<MoodDimension, int> scores;

  /// 今日失守。
  final bool failed;

  /// 情绪备注。
  final String note;

  /// 已打分的维度数。
  int get ratedCount => scores.length;

  /// 8 维平均分；一维都没打时返回 null（**不要返回 0**，那会被误读成「全 0 分」）。
  double? get average {
    if (scores.isEmpty) {
      return null;
    }
    final total = scores.values.reduce((a, b) => a + b);
    return total / scores.length;
  }

  /// 存在 0 分维度。
  bool get hasZero => scores.values.any((v) => v == 0);
}

/// 复盘五段 —— P1-7 的交付物。
///
/// 五段（严格说是六块：学习 / 做得好 / 待改进 / 可控 / 不可控 / 下一步）
/// 必须**各自可独立留白**：任何一段为空都不影响其余段落保存。
final class ReviewDraft {
  /// 创建复盘草稿。
  const ReviewDraft({
    this.learning = '',
    this.good = '',
    this.improve = '',
    this.controllable = '',
    this.uncontrollable = '',
    this.nextAction = '',
  });

  /// 学到了什么。
  final String learning;

  /// 做得好的。
  final String good;

  /// 待改进的。
  final String improve;

  /// 可控的事。
  final String controllable;

  /// 不可控的事。
  final String uncontrollable;

  /// 下一步可控动作。
  final String nextAction;

  /// 六段全空。
  bool get isEmpty =>
      learning.trim().isEmpty &&
      good.trim().isEmpty &&
      improve.trim().isEmpty &&
      controllable.trim().isEmpty &&
      uncontrollable.trim().isEmpty &&
      nextAction.trim().isEmpty;

  /// 复制并覆盖部分段落。
  ReviewDraft copyWith({
    String? learning,
    String? good,
    String? improve,
    String? controllable,
    String? uncontrollable,
    String? nextAction,
  }) {
    return ReviewDraft(
      learning: learning ?? this.learning,
      good: good ?? this.good,
      improve: improve ?? this.improve,
      controllable: controllable ?? this.controllable,
      uncontrollable: uncontrollable ?? this.uncontrollable,
      nextAction: nextAction ?? this.nextAction,
    );
  }
}