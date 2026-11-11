// =============================================================================
// core_data · 站会三段生成（P1-2）
// =============================================================================
// 设计要点：**规则是纯函数，查库在 service 层**。
// 这样「三段自动生成逻辑有单测」不需要一个数据库就能验证，
// 而「阻塞项规则可配置」就是 [StandupConfig] 上的字段。
// =============================================================================

import 'package:core_domain/core_domain.dart';

import 'models.dart';

/// 参与站会计算的一条计划条目（脱离 drift 行的纯数据）。
final class StandupPlanRow {
  /// 创建行快照。
  const StandupPlanRow({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    this.quadrant,
    this.priorityAbc,
    this.resultNote = '',
    this.carriedOverDays = 0,
  });

  /// 实体 id。
  final String id;

  /// 标题。
  final String title;

  /// 所属日历日。
  final String date;

  /// 状态。
  final PlanStatus status;

  /// 四象限。
  final Quadrant? quadrant;

  /// ABC 优先级。
  final PriorityAbc? priorityAbc;

  /// 成果 / 进展备注。
  final String resultNote;

  /// 已顺延天数（0 = 首次出现在昨天，不是顺延条目）。
  final int carriedOverDays;

  /// 是否还没收口（pending 或 deferred）。
  bool get isOpen =>
      status == PlanStatus.pending || status == PlanStatus.deferred;
}

/// 站会生成用的输入快照。
final class StandupInput {
  /// 创建输入。
  const StandupInput({
    required this.date,
    this.todayItems = const [],
    this.yesterdayItems = const [],
    this.yesterdayGoodText = '',
    this.projectBlockers = const [],
  });

  /// 站会对齐的日历日（今天）。
  final String date;

  /// 今天的计划条目。
  final List<StandupPlanRow> todayItems;

  /// 昨天的计划条目。
  final List<StandupPlanRow> yesterdayItems;

  /// 昨天日志里「做得好的」自由文本（昨日亮点的兜底来源）。
  final String yesterdayGoodText;

  /// 长线项目增量里记录的阻塞描述。
  final List<String> projectBlockers;
}

/// 站会三段的生成规则 —— **这些字段就是「阻塞项规则可配置」的实现**。
final class StandupConfig {
  /// 创建配置；所有字段都有默认值。
  const StandupConfig({
    this.highlightLimit = 3,
    this.priorityLimit = 3,
    this.blockerLimit = 5,
    this.blockerCarryOverDays = 2,
    this.blockerIncludesUnfinishedUrgent = true,
    this.blockerIncludesProjectBlockers = true,
  });

  /// 昨日亮点最多几条。
  final int highlightLimit;

  /// 今日优先最多几条。
  final int priorityLimit;

  /// 阻塞项最多几条。
  final int blockerLimit;

  /// 顺延达到多少天就升级为阻塞项；设为 0 表示不按顺延判定。
  final int blockerCarryOverDays;

  /// 昨天未完成且紧急（Q1/Q3）的条目是否算阻塞项。
  final bool blockerIncludesUnfinishedUrgent;

  /// 项目增量里的阻塞描述是否算阻塞项。
  final bool blockerIncludesProjectBlockers;
}

/// 站会三段生成器。
abstract final class StandupBuilder {
  /// 按 [config] 从 [input] 生成三段视图。
  static StandupBrief build({
    required StandupInput input,
    StandupConfig config = const StandupConfig(),
  }) {
    final highlights = _highlights(input, config);
    final priorities = _priorities(input, config);
    final blockers = _blockers(input, config);
    return StandupBrief(
      date: input.date,
      yesterdayHighlights: highlights,
      todayPriorities: priorities,
      blockers: blockers,
    );
  }

  static List<StandupEntry> _highlights(
    StandupInput input,
    StandupConfig config,
  ) {
    final done = input.yesterdayItems
        .where((row) => row.status == PlanStatus.done)
        .toList();
    // 有成果备注的排前面：亮点要用「做成了什么」说话，不是「做完了什么」。
    done.sort((a, b) {
      final aNote = a.resultNote.trim().isEmpty ? 1 : 0;
      final bNote = b.resultNote.trim().isEmpty ? 1 : 0;
      if (aNote != bNote) {
        return aNote - bNote;
      }
      return a.title.compareTo(b.title);
    });

    final out = <StandupEntry>[];
    for (final row in done) {
      if (out.length >= config.highlightLimit) {
        break;
      }
      out.add(
        StandupEntry(
          id: row.id,
          title: row.title,
          source: StandupSource.yesterdayDone,
          quadrant: row.quadrant,
          priorityAbc: row.priorityAbc,
          note: row.resultNote,
        ),
      );
    }

    // 一条都没完成时，用昨天日志的「做得好」文本兜底 —— 否则站会第一段永远空白，
    // 用户会以为功能坏了。
    if (out.isEmpty) {
      final text = input.yesterdayGoodText.trim();
      if (text.isNotEmpty) {
        out.add(
          StandupEntry(
            id: input.date,
            title: _firstLine(text),
            source: StandupSource.yesterdayGoodText,
            note: text,
          ),
        );
      }
    }
    return out;
  }

  static List<StandupEntry> _priorities(
    StandupInput input,
    StandupConfig config,
  ) {
    final open = input.todayItems.where((row) => row.isOpen).toList();
    if (open.isEmpty) {
      return const [];
    }

    // 主排序：四象限（重要 → 紧急 → 其余）优先，其次 ABC。
    // 这是「今日优先」而不是「今日全部」：C 类与 Q4 本来就该往后排。
    open.sort((a, b) {
      final qa = _quadrantWeight(a.quadrant);
      final qb = _quadrantWeight(b.quadrant);
      if (qa != qb) {
        return qa - qb;
      }
      final aa = _abcWeight(a.priorityAbc);
      final ab = _abcWeight(b.priorityAbc);
      if (aa != ab) {
        return aa - ab;
      }
      return a.id.compareTo(b.id);
    });

    final out = <StandupEntry>[];
    for (final row in open) {
      if (out.length >= config.priorityLimit) {
        break;
      }
      out.add(
        StandupEntry(
          id: row.id,
          title: row.title,
          source: StandupSource.todayPlanned,
          quadrant: row.quadrant,
          priorityAbc: row.priorityAbc,
          note: row.resultNote,
          carriedOverDays: row.carriedOverDays,
        ),
      );
    }
    return out;
  }

  static List<StandupEntry> _blockers(
    StandupInput input,
    StandupConfig config,
  ) {
    final out = <StandupEntry>[];

    if (config.blockerIncludesProjectBlockers) {
      for (final text in input.projectBlockers) {
        if (out.length >= config.blockerLimit) {
          break;
        }
        final trimmed = text.trim();
        if (trimmed.isEmpty) {
          continue;
        }
        out.add(
          StandupEntry(
            id: 'project-blocker-${out.length}',
            title: _firstLine(trimmed),
            source: StandupSource.projectBlocker,
            note: trimmed,
          ),
        );
      }
    }

    // 昨天未收口的条目：按「顺延天数 → 紧急度」挑，最该被说出来的是
    // 连续几天没动、又自称紧急的那条。
    final openYesterday = input.yesterdayItems
        .where((row) => row.isOpen)
        .where((row) {
          if (config.blockerIncludesUnfinishedUrgent &&
              (row.quadrant?.isUrgent ?? false)) {
            return true;
          }
          if (config.blockerCarryOverDays > 0 &&
              row.carriedOverDays >= config.blockerCarryOverDays) {
            return true;
          }
          return false;
        })
        .toList();

    openYesterday.sort((a, b) {
      final ca = a.carriedOverDays;
      final cb = b.carriedOverDays;
      if (ca != cb) {
        return cb - ca;
      }
      return _quadrantWeight(a.quadrant) - _quadrantWeight(b.quadrant);
    });

    for (final row in openYesterday) {
      if (out.length >= config.blockerLimit) {
        break;
      }
      out.add(
        StandupEntry(
          id: row.id,
          title: row.title,
          source: StandupSource.carriedOver,
          quadrant: row.quadrant,
          priorityAbc: row.priorityAbc,
          note: row.carriedOverDays > 0
              ? '已顺延 ${row.carriedOverDays} 天'
              : (row.resultNote.trim().isEmpty ? '昨天未收口' : row.resultNote),
          carriedOverDays: row.carriedOverDays,
        ),
      );
    }
    return out;
  }

  static int _quadrantWeight(Quadrant? q) {
    if (q == null) {
      return 9;
    }
    if (q == Quadrant.q1) {
      return 0;
    }
    if (q == Quadrant.q2) {
      return 1;
    }
    if (q == Quadrant.q3) {
      return 2;
    }
    return 3;
  }

  static int _abcWeight(PriorityAbc? p) {
    if (p == null) {
      return 9;
    }
    if (p == PriorityAbc.a) {
      return 0;
    }
    if (p == PriorityAbc.b) {
      return 1;
    }
    return 2;
  }

  /// 取首行，并把过长文本截断 —— 站会一行只能说一件事。
  static String _firstLine(String text) {
    final line = text.split('\n').first.trim();
    if (line.length <= 40) {
      return line;
    }
    return '${line.substring(0, 40)}…';
  }
}