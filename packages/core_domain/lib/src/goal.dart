// =============================================================================
// core_domain · 目标体系的领域模型（schema v3：goal + goal_link）
// =============================================================================
// 纪律：
//   1. 本包**无 IO 依赖**；时间统一用 Unix 毫秒 int。
//   2. 枚举取值必须与 `packages/core_db` 里 `goal` / `goal_link` 的 CHECK 约束
//      **逐字一致**（由 core_db 的 `test/goal_schema_test.dart` 交叉校验）。
//   3. **不建第二套 domain 枚举**：目标的 `domain` 复用 Task 59 已落地的六个
//      key（career / wealth / family / learning / social / health），清单真源在
//      `apps/desktop/lib/src/data/project_domain_catalog.dart`。本包**刻意不重复
//      声明**那份清单（core_domain 不能依赖 apps 层，抄一份就是第二套真源），
//      因此这里的字段类型是 `String?`，与既有 `project.domain` / `habit.domain`
//      同一口径（见 entities.dart）。
//   4. **派生量一律不入库**：完成度 / 达成率 / 各层汇总 / 「未落位」标记
//      都在仓储层现算（`docs/task62/模块规划.md` §4.3）。本包只提供纯函数与
//      不可变值对象，不持有任何「算出来的进度」。
//   5. 与 core_db 的同名表类（`Goal` / `GoalLink`）的冲突，按既有惯例由引用方
//      `import 'package:core_db/core_db.dart' hide Goal, GoalLink;` 解决
//      （先例：core_data/lib/src/repositories.dart 对 `Todo` 的处理）。
// =============================================================================

import 'entities.dart';
import 'enums.dart';

/// 目标的五种形态（`goal.kind`，与 CHECK `goal_kind_check` 逐字一致）。
enum GoalKind {
  /// 人生蓝图（一格 = 一条目标）。
  blueprint('blueprint'),

  /// 个人品牌画像（一行 = 一个切面）。
  brand('brand'),

  /// 年度目标。
  yearly('yearly'),

  /// 月度目标。
  monthly('monthly'),

  /// 周目标。
  weekly('weekly');

  /// 构造 [GoalKind] 常量。
  const GoalKind(this.code);

  /// 存储到数据库的取值（英文 code；显示走 l10n，不把中文写进库里）。
  final String code;

  /// 本形态的周期单位；蓝图与品牌画像**没有**周期（返回 null）。
  GoalPeriodUnit? get periodUnit => switch (this) {
    GoalKind.yearly => GoalPeriodUnit.year,
    GoalKind.monthly => GoalPeriodUnit.month,
    GoalKind.weekly => GoalPeriodUnit.week,
    GoalKind.blueprint || GoalKind.brand => null,
  };

  /// 是否是**周期型**目标（年 / 月 / 周）。
  bool get isPeriodic => periodUnit != null;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**）。
  static GoalKind? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final k in GoalKind.values) {
      if (k.code == code) {
        return k;
      }
    }
    return null;
  }
}

/// 目标状态（`goal.status`，与 CHECK `goal_status_check` 逐字一致）。
///
/// **没有 `paused`**：项目页的 `paused` 语义不搬过来（计划 §14 风险 R-E），
/// 「暂停一条目标」用 `draft` + 归档表达。
enum GoalStatus {
  /// 草稿（周期滚动生成、尚未确认激活的目标）。
  draft('draft'),

  /// 进行中。
  active('active'),

  /// 已完成。
  done('done'),

  /// 已取消。
  cancelled('cancelled');

  /// 构造 [GoalStatus] 常量。
  const GoalStatus(this.code);

  /// 存储到数据库的取值。
  final String code;

  /// 是否算「已完成」（完成项汇总与达成率的分子）。
  bool get isDone => this == GoalStatus.done;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**）。
  static GoalStatus? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final s in GoalStatus.values) {
      if (s.code == code) {
        return s;
      }
    }
    return null;
  }
}

/// 蓝图档位（`goal.horizon`，1..5；其余 kind 为 NULL）。
enum GoalHorizon {
  /// 终极（60 岁后）。
  ultimate(1),

  /// 远期（10 年）。
  long(2),

  /// 中期（5 年）。
  mid(3),

  /// 短期（3 年）。
  short(4),

  /// 近期（1 年）。
  near(5);

  /// 构造 [GoalHorizon] 常量。
  const GoalHorizon(this.value);

  /// 存储到数据库的整数值（`goal.horizon`）。
  final int value;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**）。
  static GoalHorizon? fromValue(int? value) {
    if (value == null) {
      return null;
    }
    for (final h in GoalHorizon.values) {
      if (h.value == value) {
        return h;
      }
    }
    return null;
  }
}

/// 品牌画像切面（`goal.facet`；其余 kind 为 NULL）。
enum GoalFacet {
  /// 定位语句。
  statement('statement'),

  /// 心智一词。
  word('word'),

  /// 对象 / 他人视角。
  audience('audience'),

  /// 承诺结果。
  promise('promise'),

  /// 规避的代价。
  cost('cost'),

  /// 可信证据。
  evidence('evidence'),

  /// 对立面（我不做什么）。
  contrast('contrast'),

  /// 三环交叉。
  strength('strength'),

  /// 剔除 / 减少 / 增加 / 创造。
  errc('errc'),

  /// 身份声明。
  identity('identity');

  /// 构造 [GoalFacet] 常量。
  const GoalFacet(this.code);

  /// 存储到数据库的取值。
  final String code;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**）。
  static GoalFacet? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final f in GoalFacet.values) {
      if (f.code == code) {
        return f;
      }
    }
    return null;
  }
}

/// `goal_link` 的关联目标类型（与 CHECK `goal_link_target_type_check` 逐字一致）。
enum GoalTargetType {
  /// 待办池条目。
  todo('todo'),

  /// 计划条目（时间轴上的一天）。
  planItem('plan_item'),

  /// 项目。
  project('project'),

  /// 项目增量记录。
  increment('increment'),

  /// 习惯。
  habit('habit'),

  /// 另一条目标（目标之间的层级引用）。
  goal('goal');

  /// 构造 [GoalTargetType] 常量。
  const GoalTargetType(this.code);

  /// 存储到数据库的取值。
  final String code;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**）。
  static GoalTargetType? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final t in GoalTargetType.values) {
      if (t.code == code) {
        return t;
      }
    }
    return null;
  }
}

/// `goal_link` 的关系语义（与 CHECK `goal_link_relation_check` 逐字一致）。
enum GoalRelation {
  /// 本目标服务于上层目标（周 → 月 → 年 → 蓝图格）。
  serves('serves'),

  /// 由上层派生出的草稿（滚动生成的下周目标 → 本周目标）。
  derives('derives'),

  /// 完成证据挂在执行层实体上（年目标 → `plan_item`；身份目标 → `habit`）。
  tracks('tracks'),

  /// 弱引用，跨模块看料（品牌画像 → `project`）。
  references('references');

  /// 构造 [GoalRelation] 常量。
  const GoalRelation(this.code);

  /// 存储到数据库的取值。
  final String code;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**）。
  static GoalRelation? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final r in GoalRelation.values) {
      if (r.code == code) {
        return r;
      }
    }
    return null;
  }
}

/// 周期单位。
enum GoalPeriodUnit {
  /// 年（`2026`）。
  year,

  /// 月（`2026-11`）。
  month,

  /// 周（`2026-W48`，ISO-8601 周，周一为一周之首）。
  week,
}

/// 目标周期值对象（年 / 月 / 周）。
///
/// 口径：**UTC**。`period_start` = 周期第一刻 00:00.000 UTC，
/// `period_end` = 周期最后一刻 23:59:59.999 UTC（**含**）。
/// 显示用的本地日期由界面层按本地时区换算；本对象只负责**窗口**，
/// 于是「这一周有哪些目标」在跨时区设备上永远是同一批行。
final class GoalPeriod {
  const GoalPeriod._({
    required this.unit,
    required this.year,
    this.month,
    this.week,
  });

  /// 年周期（`2026`）。
  ///
  /// 非法年份抛 [ArgumentError]。
  factory GoalPeriod.year(int year) {
    _checkYear(year);
    return GoalPeriod._(unit: GoalPeriodUnit.year, year: year);
  }

  /// 月周期（`2026-11`）。
  ///
  /// 非法月份抛 [ArgumentError]。
  factory GoalPeriod.month(int year, int month) {
    _checkYear(year);
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', '月份必须在 1..12');
    }
    return GoalPeriod._(
      unit: GoalPeriodUnit.month,
      year: year,
      month: month,
    );
  }

  /// 周周期（`2026-W48`，ISO-8601 周）。
  ///
  /// 非法周号（含该年不存在的第 53 周）抛 [ArgumentError]。
  factory GoalPeriod.week(int year, int week) {
    _checkYear(year);
    final int weeks = isoWeeksInYear(year);
    if (week < 1 || week > weeks) {
      throw ArgumentError.value(
        week,
        'week',
        'ISO 周号必须在 1..$weeks 之间（$year 年有 $weeks 周）',
      );
    }
    return GoalPeriod._(
      unit: GoalPeriodUnit.week,
      year: year,
      week: week,
    );
  }

  /// 周期单位。
  final GoalPeriodUnit unit;

  /// 所属年（周周期指 **ISO 周年**，不是公历年的自然周序）。
  final int year;

  /// 月（1..12）；仅 [GoalPeriodUnit.month] 非空。
  final int? month;

  /// ISO 周号（1..53）；仅 [GoalPeriodUnit.week] 非空。
  final int? week;

  /// 展示 / 存储用的标签：`2026` / `2026-11` / `2026-W48`。
  String get label => switch (unit) {
    GoalPeriodUnit.year => '$year',
    GoalPeriodUnit.month => '$year-${_two(month!)}',
    GoalPeriodUnit.week => '$year-W${_two(week!)}',
  };

  /// 周期起点（UTC，Unix 毫秒，含）。
  int get startMillis => startUtc.millisecondsSinceEpoch;

  /// 周期终点（UTC，Unix 毫秒，含）。
  int get endMillis => endUtc.millisecondsSinceEpoch;

  /// 周期起点（UTC）。
  DateTime get startUtc => switch (unit) {
    GoalPeriodUnit.year => DateTime.utc(year),
    GoalPeriodUnit.month => DateTime.utc(year, month!),
    GoalPeriodUnit.week => isoWeekStart(year, week!),
  };

  /// 周期终点（UTC，含）。
  DateTime get endUtc {
    final DateTime nextStart = switch (unit) {
      GoalPeriodUnit.year => DateTime.utc(year + 1),
      GoalPeriodUnit.month => DateTime.utc(year, month! + 1),
      GoalPeriodUnit.week => isoWeekStart(year, week!).add(
        const Duration(days: 7),
      ),
    };
    return nextStart.subtract(const Duration(milliseconds: 1));
  }

  /// 该时刻是否落在这个周期窗口内。
  bool contains(int millis) =>
      millis >= startMillis && millis <= endMillis;

  /// 下一个周期。
  GoalPeriod next() => switch (unit) {
    GoalPeriodUnit.year => GoalPeriod.year(year + 1),
    GoalPeriodUnit.month => month == 12
        ? GoalPeriod.month(year + 1, 1)
        : GoalPeriod.month(year, month! + 1),
    GoalPeriodUnit.week => week == isoWeeksInYear(year)
        ? GoalPeriod.week(year + 1, 1)
        : GoalPeriod.week(year, week! + 1),
  };

  /// 上一个周期。
  GoalPeriod previous() => switch (unit) {
    GoalPeriodUnit.year => GoalPeriod.year(year - 1),
    GoalPeriodUnit.month => month == 1
        ? GoalPeriod.month(year - 1, 12)
        : GoalPeriod.month(year, month! - 1),
    GoalPeriodUnit.week => week == 1
        ? GoalPeriod.week(year - 1, isoWeeksInYear(year - 1))
        : GoalPeriod.week(year, week! - 1),
  };

  /// 解析标签；无法识别时返回 null（**不抛异常**，与枚举 `fromCode` 同约定）。
  static GoalPeriod? tryParse(String label) {
    final String t = label.trim();
    final RegExpMatch? weekMatch =
        RegExp(r'^(\d{4})-W(\d{1,2})$').firstMatch(t);
    if (weekMatch != null) {
      final int y = int.parse(weekMatch.group(1)!);
      final int w = int.parse(weekMatch.group(2)!);
      if (w < 1 || w > isoWeeksInYear(y)) {
        return null;
      }
      return GoalPeriod.week(y, w);
    }
    final RegExpMatch? monthMatch =
        RegExp(r'^(\d{4})-(\d{2})$').firstMatch(t);
    if (monthMatch != null) {
      final int y = int.parse(monthMatch.group(1)!);
      final int m = int.parse(monthMatch.group(2)!);
      if (m < 1 || m > 12) {
        return null;
      }
      return GoalPeriod.month(y, m);
    }
    final RegExpMatch? yearMatch = RegExp(r'^(\d{4})$').firstMatch(t);
    if (yearMatch != null) {
      final int y = int.parse(yearMatch.group(1)!);
      if (y < 1) {
        return null;
      }
      return GoalPeriod.year(y);
    }
    return null;
  }

  /// 解析标签；无法识别时抛 [FormatException]。
  static GoalPeriod parse(String label) {
    final GoalPeriod? parsed = tryParse(label);
    if (parsed == null) {
      throw FormatException('不是合法的目标周期标签', label);
    }
    return parsed;
  }

  /// 从某个时刻反推它所属的周期。
  ///
  /// [millis] 是 Unix 毫秒；按 **UTC** 判定归属。
  static GoalPeriod fromStartMillis(int millis, GoalPeriodUnit unit) {
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(
      millis,
      isUtc: true,
    );
    return switch (unit) {
      GoalPeriodUnit.year => GoalPeriod.year(moment.year),
      GoalPeriodUnit.month => GoalPeriod.month(moment.year, moment.month),
      GoalPeriodUnit.week => GoalPeriod.week(
          isoYearOf(moment),
          isoWeekOf(moment),
        ),
    };
  }

  /// ISO-8601：该年第一周的周一（UTC 00:00）。
  ///
  /// ISO 周 1 = 含 1 月 4 日的那一周；周一是一周之首。
  static DateTime isoWeekStart(int year, int week) {
    final DateTime jan4 = DateTime.utc(year, 1, 4);
    final DateTime week1Monday = DateTime.utc(
      year,
      1,
      4,
    ).subtract(Duration(days: jan4.weekday - 1));
    return week1Monday.add(Duration(days: (week - 1) * 7));
  }

  /// ISO-8601：某年共有几个周（52 或 53）。
  static int isoWeeksInYear(int year) {
    final DateTime dec28 = DateTime.utc(year, 12, 28);
    final DateTime week1Monday = DateTime.utc(
      year,
      1,
      4,
    ).subtract(Duration(days: DateTime.utc(year, 1, 4).weekday - 1));
    return dec28.difference(week1Monday).inDays ~/ 7 + 1;
  }

  /// ISO-8601：某时刻所属的 ISO 周年。
  static int isoYearOf(DateTime moment) {
    final DateTime thursday = _isoThursday(moment);
    return thursday.year;
  }

  /// ISO-8601：某时刻所属的 ISO 周号。
  static int isoWeekOf(DateTime moment) {
    final DateTime thursday = _isoThursday(moment);
    final int year = thursday.year;
    final DateTime week1Monday = DateTime.utc(
      year,
      1,
      4,
    ).subtract(Duration(days: DateTime.utc(year, 1, 4).weekday - 1));
    return thursday.difference(week1Monday).inDays ~/ 7 + 1;
  }

  static DateTime _isoThursday(DateTime moment) {
    final DateTime day = DateTime.utc(
      moment.year,
      moment.month,
      moment.day,
    );
    return day.add(Duration(days: 4 - day.weekday));
  }

  static void _checkYear(int year) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year', '年份必须在 1..9999');
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is GoalPeriod &&
      other.unit == unit &&
      other.year == year &&
      other.month == month &&
      other.week == week;

  @override
  int get hashCode => Object.hash(unit, year, month, week);
}

/// 可清空的字段集合（供仓储层的更新接口区分「不改」与「改成空」）。
///
/// 为什么需要它：`goal` 有 13 个可空字段，普通的 `copyWith(note: null)`
/// 无法区分「不动备注」与「把备注清空」。这里用**显式集合**表达后者，
/// 避免界面层为了清空一个字段去改别的字段。
enum GoalField {
  /// `goal.note`。
  note,

  /// `goal.keywords`。
  keywords,

  /// `goal.parent_id`。
  parentId,

  /// `goal.domain`。
  domain,

  /// `goal.horizon`。
  horizon,

  /// `goal.facet`。
  facet,

  /// `goal.period_end`。
  periodEnd,

  /// `goal.due_date`。
  dueDate,

  /// `goal.quadrant`.
  quadrant,

  /// `goal.priority_abc`.
  priorityAbc,

  /// `goal.self_score`。
  selfScore,

  /// `goal.review_note`。
  reviewNote,

  /// `goal.improve_note`。
  improveNote,
}

/// `goal.quadrant`（INTEGER 1..4）↔ 领域枚举 [Quadrant] 的换算。
///
/// 为什么需要它：`Quadrant` 的 `code` 是 `'Q1'`…`'Q4'`（**字符串**），
/// 而 `goal.quadrant` 按计划 §4.1 是 **INTEGER 1..4**。两套编码必须在一个
/// 地方对上，否则会出现「写进去的是 'Q1'、CHECK 判它不在 1..4」的静默拒写。
final class GoalQuadrant {
  const GoalQuadrant._();

  /// 领域枚举 → 数据库整数（1..4）。
  static int encode(Quadrant quadrant) => switch (quadrant) {
    Quadrant.q1 => 1,
    Quadrant.q2 => 2,
    Quadrant.q3 => 3,
    Quadrant.q4 => 4,
  };

  /// 数据库整数（1..4）→ 领域枚举；越界或为空时返回 null（**不抛异常**）。
  static Quadrant? decode(int? value) => switch (value) {
    1 => Quadrant.q1,
    2 => Quadrant.q2,
    3 => Quadrant.q3,
    4 => Quadrant.q4,
    _ => null,
  };
}

/// 一条目标（`goal` 表的一行，领域侧不可变视图）。
final class Goal extends SyncEntity {
  /// 构造目标（**不校验**）；请用 [Goal.create] 或仓储层入口。
  Goal({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.note,
    this.keywords,
    this.parentId,
    this.domain,
    this.horizon,
    this.facet,
    this.periodStart = 0,
    this.periodEnd,
    this.dueDate,
    this.quadrant,
    this.priorityAbc,
    this.status = GoalStatus.active,
    this.selfScore,
    this.reviewNote,
    this.improveNote,
    this.archivedAt,
    this.deletedAt,
    this.rev = 1,
  });

  /// 构造并**校验**一条目标。
  ///
  /// 校验口径与 CHECK 约束一致，但错误是**可读中文**（[DomainValidationException]），
  /// 界面层与仓储层各挡一次。
  factory Goal.create({
    required String id,
    required GoalKind kind,
    required String title,
    required int createdAt,
    required int updatedAt,
    required String originDeviceId,
    String? note,
    String? keywords,
    String? parentId,
    String? domain,
    GoalHorizon? horizon,
    GoalFacet? facet,
    int periodStart = 0,
    int? periodEnd,
    int? dueDate,
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
    GoalStatus status = GoalStatus.active,
    int? selfScore,
    String? reviewNote,
    String? improveNote,
    int? archivedAt,
    int? deletedAt,
    int rev = 1,
  }) {
    final String trimmedTitle = Validate.nonEmpty(title, 'title');
    if (selfScore != null && (selfScore < 0 || selfScore > 10)) {
      throw DomainValidationException('self_score 必须在 0..10 之间');
    }
    if (periodEnd != null && periodEnd < periodStart) {
      throw DomainValidationException('period_end 不能早于 period_start');
    }
    if (status != GoalStatus.done && archivedAt != null) {
      throw DomainValidationException('只有完成的目标才能进归档');
    }
    return Goal(
      id: id,
      kind: kind,
      title: trimmedTitle,
      note: note,
      keywords: keywords,
      parentId: parentId,
      domain: domain,
      horizon: horizon,
      facet: facet,
      periodStart: periodStart,
      periodEnd: periodEnd,
      dueDate: dueDate,
      quadrant: quadrant,
      priorityAbc: priorityAbc,
      status: status,
      selfScore: selfScore,
      reviewNote: reviewNote,
      improveNote: improveNote,
      archivedAt: archivedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      originDeviceId: originDeviceId,
      deletedAt: deletedAt,
      rev: rev,
    );
  }

  @override
  final String id;

  /// 目标形态。
  final GoalKind kind;

  /// 目标一句话（必须本人撰写）。
  final String title;

  /// 展开说明 / 愿景描述。
  final String? note;

  /// 关键词（蓝图「手段」层；其余 kind 复用为标签串）。
  final String? keywords;

  /// 上级目标 id；null = 顶层。
  final String? parentId;

  /// 领域 key（Task 59 六 key；null = 未分类）。
  final String? domain;

  /// 蓝图档位；其余 kind 为 null。
  final GoalHorizon? horizon;

  /// 品牌画像切面；其余 kind 为 null。
  final GoalFacet? facet;

  /// 周期起点（Unix 毫秒，UTC）。
  final int periodStart;

  /// 周期终点（Unix 毫秒，UTC，含）；null = 无固定终点。
  final int? periodEnd;

  /// 周内完成期限（Unix 毫秒）。
  final int? dueDate;

  /// 四象限（复用 `Quadrant`）。
  final Quadrant? quadrant;

  /// ABC 优先级（复用 `PriorityAbc`）。
  final PriorityAbc? priorityAbc;

  /// 状态。
  final GoalStatus status;

  /// 用户自评 0..10；null = 未评。
  ///
  /// **这是源数据不是派生数据**，所以入库（计划 §4.3 的唯一例外）。
  final int? selfScore;

  /// 未完成原因 / 障碍。
  final String? reviewNote;

  /// 改进措施 / 克服对策。
  final String? improveNote;

  /// 取消线（Unix 毫秒）；只有 `done` 的目标可带。
  final int? archivedAt;

  @override
  final int createdAt;

  @override
  final int updatedAt;

  @override
  final int? deletedAt;

  @override
  final String originDeviceId;

  @override
  final int rev;

  /// 是否已完成。
  bool get isDone => status.isDone;

  @override
  String toString() => 'Goal(id: $id, kind: ${kind.code}, title: $title)';
}

/// 一条目标关联（`goal_link` 表的一行）。
///
/// **不建外键**（仿 `reminder` 的多态指针范式）：删除执行层实体时不级联，
/// 读时统一 `deleted_at IS NULL` 过滤；孤儿链接在界面上显式标「已失效引用」。
final class GoalLink extends SyncEntity {
  /// 构造关联（**不校验**）。
  GoalLink({
    required this.id,
    required this.goalId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.relation = GoalRelation.serves,
    this.deletedAt,
    this.rev = 1,
  });

  /// 构造并**校验**一条关联。
  ///
  /// 唯一的业务不变量是**禁自环**：`target_type='goal'` 时不能指向自己。
  factory GoalLink.create({
    required String id,
    required String goalId,
    required GoalTargetType targetType,
    required String targetId,
    required int createdAt,
    required int updatedAt,
    required String originDeviceId,
    GoalRelation relation = GoalRelation.serves,
    int? deletedAt,
    int rev = 1,
  }) {
    if (targetType == GoalTargetType.goal && targetId == goalId) {
      throw DomainValidationException('目标不能关联自己');
    }
    return GoalLink(
      id: id,
      goalId: goalId,
      targetType: targetType,
      targetId: targetId,
      relation: relation,
      createdAt: createdAt,
      updatedAt: updatedAt,
      originDeviceId: originDeviceId,
      deletedAt: deletedAt,
      rev: rev,
    );
  }

  @override
  final String id;

  /// 所属目标 id。
  final String goalId;

  /// 关联目标类型。
  final GoalTargetType targetType;

  /// 关联目标 id。
  final String targetId;

  /// 关系语义。
  final GoalRelation relation;

  @override
  final int createdAt;

  @override
  final int updatedAt;

  @override
  final int? deletedAt;

  @override
  final String originDeviceId;

  @override
  final int rev;

  @override
  String toString() =>
      'GoalLink(goal: $goalId, ${targetType.code}: $targetId, '
      '${relation.code})';
}
