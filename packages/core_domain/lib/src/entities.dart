// =============================================================================
// core_domain · 实体与不变量
// =============================================================================
// 纪律：本包无 IO 依赖。实体是不可变值对象（final class + final 字段），
//       时间统一用 Unix 毫秒 int，日历日用 'YYYY-MM-DD' 字符串。
//       字段名与 docs/schema_v1.sql 逐字一致（snake_case）。
// =============================================================================

import 'enums.dart';

/// 心态 8 维度 —— 与原书 L826–L843 对应。
///
/// 保留 v0.1 的 0–10 连续分（原书是 0/10 二元制），
/// 「今日失守」用独立的布尔标记承接原书的二元判定语义。
enum MoodDimension {
  /// 认真。
  diligent('mood_1', '认真'),

  /// 快。
  fast('mood_2', '快'),

  /// 坚守承诺。
  keepPromise('mood_3', '坚守承诺'),

  /// 保证完成任务。
  finishTask('mood_4', '保证完成任务'),

  /// 乐观。
  optimistic('mood_5', '乐观'),

  /// 自信。
  confident('mood_6', '自信'),

  /// 爱与奉献。
  loveAndDedication('mood_7', '爱与奉献'),

  /// 决不找借口。
  noExcuses('mood_8', '决不找借口');

  /// 构造 [MoodDimension] 常量。

  const MoodDimension(this.column, this.label);

  /// 数据库列名。
  final String column;

  /// 中文显示名。
  final String label;

  /// 全部 8 个维度，按表列顺序。
  static List<MoodDimension> get all => MoodDimension.values;

  /// 按列名反查。
  static MoodDimension? fromColumn(String column) {
    for (final d in MoodDimension.values) {
      if (d.column == column) {
        return d;
      }
    }
    return null;
  }
}

/// 领域层异常。带**可读中文消息** —— 用户可见的错误不暴露堆栈。
class DomainValidationException implements Exception {
  /// 构造校验异常。
  DomainValidationException(this.message);

  /// 错误消息。
  final String message;

  @override
  String toString() => 'DomainValidationException: $message';
}

/// 通用校验工具。
abstract final class Validate {
  /// 必填文本非空。
  static String nonEmpty(String value, String field) {
    final v = value.trim();
    if (v.isEmpty) {
      throw DomainValidationException('$field 不能为空');
    }
    return v;
  }

  /// 取值必须落在允许集合内。
  static T oneOf<T>(T value, List<T> allowed, String field) {
    if (!allowed.contains(value)) {
      throw DomainValidationException('$field 取值非法：$value');
    }
    return value;
  }

  /// 数值范围校验（含边界）。
  static num range(num? value, num min, num max, String field) {
    if (value == null) {
      throw DomainValidationException('$field 不能为 null');
    }
    if (value < min || value > max) {
      throw DomainValidationException('$field 必须在 $min~$max 之间，实际 $value');
    }
    return value;
  }

  /// 日历日期格式校验：'YYYY-MM-DD'。
  static String calendarDate(String value, String field) {
    final v = value.trim();
    final m = RegExp(r'^\d{4}-\d{2}-\d{2}$').firstMatch(v);
    if (m == null) {
      throw DomainValidationException('$field 必须是 YYYY-MM-DD 格式，实际 "$v"');
    }
    final y = int.parse(v.substring(0, 4));
    final mo = int.parse(v.substring(5, 7));
    final d = int.parse(v.substring(8, 10));
    if (mo < 1 || mo > 12 || d < 1 || d > 31) {
      throw DomainValidationException('$field 日期不存在：$v');
    }
    if (mo == 2) {
      final leap = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
      if (d > (leap ? 29 : 28)) {
        throw DomainValidationException('$field 日期不存在：$v');
      }
    }
    return v;
  }
}

/// 统一列的公共契约。
///
/// 所有业务实体都带 id / created_at / updated_at / deleted_at /
/// origin_device_id / rev 六个统一列（见 schema_v1.sql 头部约定）。
abstract class SyncEntity {
  /// 实体 ID（UUIDv7 文本）。
  String get id;

  /// 创建时刻（Unix 毫秒）。
  int get createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  int get updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  int? get deletedAt;

  /// 最后写入本行的设备 ID。
  String get originDeviceId;

  /// 本地修订号，每次本地变更 +1。**绝不用于跨设备定序**。
  int get rev;

  /// 是否已被软删除。
  bool get isDeleted => deletedAt != null;
}

/// 每日日志 —— 一天一行。
final class DayLog extends SyncEntity {
  /// 构造每日日志。
  DayLog({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.mode = LogMode.full,
    this.learning = '',
    this.good = '',
    this.improve = '',
    this.controllable = '',
    this.uncontrollable = '',
    this.nextAction = '',
    this.moodNote = '',
    this.moods = const {},
    this.moodFailed = false,
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 日历日 'YYYY-MM-DD'，全局唯一。
  final String date;

  /// 完整版 / 极简版。
  final LogMode mode;

  /// 复盘三段 · 学到了什么。
  final String learning;

  /// 复盘三段 · 做得好的。
  final String good;

  /// 复盘三段 · 待改进的。
  final String improve;

  /// 可控的事。
  final String controllable;

  /// 不可控的事。
  final String uncontrollable;

  /// 下一步可控动作 —— 把用户从复盘拉回行动。
  final String nextAction;

  /// 情绪备注（自由文本，接纳负面情绪）。
  final String moodNote;

  /// 8 维度打分，键为 [MoodDimension]，值 0–10；未打分的维度不出现。
  final Map<MoodDimension, int> moods;

  /// 今日失守 —— 任一维度归零即视为失守（承接原书 0/10 二元语义）。
  final bool moodFailed;

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

  /// 校验不变量并返回规范化后的实例。
  ///
  /// 不变量：
  ///  1. date 必须是合法日历日；
  ///  2. 每个心态分值在 0–10；
  ///  3. **「今日失守」必须与打分一致**：任一维度为 0 ⇒ moodFailed 必须为 true。
  ///     （这是原书 0/10 二元制的语义承接 —— 不能让用户把 0 分记成「没失守」。）
  DayLog validated() {
    Validate.calendarDate(date, 'date');
    for (final entry in moods.entries) {
      Validate.range(entry.value, 0, 10, '${entry.key.label}分值');
    }
    final hasZero = moods.values.any((v) => v == 0);
    if (hasZero && !moodFailed) {
      throw DomainValidationException('存在 0 分维度，「今日失守」必须为 true');
    }
    return copyWith();
  }

  /// 不可变复制。
  DayLog copyWith({
    String? id,
    String? date,
    LogMode? mode,
    String? learning,
    String? good,
    String? improve,
    String? controllable,
    String? uncontrollable,
    String? nextAction,
    String? moodNote,
    Map<MoodDimension, int>? moods,
    bool? moodFailed,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? originDeviceId,
    int? rev,
  }) {
    return DayLog(
      id: id ?? this.id,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      learning: learning ?? this.learning,
      good: good ?? this.good,
      improve: improve ?? this.improve,
      controllable: controllable ?? this.controllable,
      uncontrollable: uncontrollable ?? this.uncontrollable,
      nextAction: nextAction ?? this.nextAction,
      moodNote: moodNote ?? this.moodNote,
      moods: moods ?? this.moods,
      moodFailed: moodFailed ?? this.moodFailed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
    );
  }
}

/// 计划条目 —— 当日计划中的一行。
final class PlanItem extends SyncEntity {
  /// 构造计划条目。
  PlanItem({
    required this.id,
    required this.date,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.detail = '',
    this.sourceType = PlanSourceType.manual,
    this.sourceId,
    this.sourceTodoId,
    this.quadrant,
    this.priorityAbc,
    this.domain = '',
    this.estMinutes,
    this.plannedStart,
    this.plannedEnd,
    this.status = PlanStatus.pending,
    this.doneAt,
    this.resultNote = '',
    this.isHabitRef = false,
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 所属日历日 'YYYY-MM-DD'。
  final String date;

  /// 标题 —— 当来源是待办时，这里存的是**当时的标题快照**。
  final String title;

  /// 详情。
  final String detail;

  /// 来源类型。
  final PlanSourceType sourceType;

  /// 多态来源指针。
  final String? sourceId;

  /// 显式指向 todo.id —— 「引用 + 快照」模型的锚点。
  final String? sourceTodoId;

  /// 四象限（与 [priorityAbc] 互斥显示，但数据可共存）。
  final Quadrant? quadrant;

  /// ABC 优先级。
  final PriorityAbc? priorityAbc;

  /// 领域标签（如「工作」「健康」）。
  final String domain;

  /// 预估分钟数。
  final int? estMinutes;

  /// 计划开始时刻。
  final int? plannedStart;

  /// 计划结束时刻。
  final int? plannedEnd;

  /// 状态。
  final PlanStatus status;

  /// 完成时刻。
  final int? doneAt;

  /// 成果 / 进展备注。
  final String resultNote;

  /// 是否由习惯打卡回填生成（可「转为普通条目」或「删除」）。
  final bool isHabitRef;

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

  /// 校验不变量。
  ///
  /// 不变量：
  ///  1. title 非空；
  ///  2. date 合法；
  ///  3. sourceType='todo' 时必须有 sourceTodoId（否则「引用」模型失效）；
  ///  4. estMinutes >= 0；
  ///  5. status='done' 时应有 doneAt（缺失时由仓储层补齐）。
  PlanItem validated() {
    Validate.nonEmpty(title, 'title');
    Validate.calendarDate(date, 'date');
    if (sourceType == PlanSourceType.todo && sourceTodoId == null) {
      throw DomainValidationException('sourceType=todo 必须携带 sourceTodoId');
    }
    if (estMinutes != null) {
      Validate.range(estMinutes, 0, 24 * 60, 'estMinutes');
    }
    return this;
  }

  /// 不可变复制。
  PlanItem copyWith({
    String? id,
    String? date,
    String? title,
    String? detail,
    PlanSourceType? sourceType,
    String? sourceId,
    String? sourceTodoId,
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
    String? domain,
    int? estMinutes,
    int? plannedStart,
    int? plannedEnd,
    PlanStatus? status,
    int? doneAt,
    String? resultNote,
    bool? isHabitRef,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? originDeviceId,
    int? rev,
  }) {
    return PlanItem(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceTodoId: sourceTodoId ?? this.sourceTodoId,
      quadrant: quadrant ?? this.quadrant,
      priorityAbc: priorityAbc ?? this.priorityAbc,
      domain: domain ?? this.domain,
      estMinutes: estMinutes ?? this.estMinutes,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      status: status ?? this.status,
      doneAt: doneAt ?? this.doneAt,
      resultNote: resultNote ?? this.resultNote,
      isHabitRef: isHabitRef ?? this.isHabitRef,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
    );
  }
}

/// 待办 —— 待办池中的一条。
final class Todo extends SyncEntity {
  /// 构造待办。
  Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.detail = '',
    this.estMinutes,
    this.dueDate,
    this.projectId,
    this.quadrant,
    this.priorityAbc,
    this.status = TodoStatus.open,
    this.completedAt,
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 标题。
  final String title;

  /// 详情。
  final String detail;

  /// 预估分钟数。
  final int? estMinutes;

  /// 截止日历日。
  final String? dueDate;

  /// 所属项目。
  final String? projectId;

  /// 四象限。
  final Quadrant? quadrant;

  /// ABC 优先级。
  final PriorityAbc? priorityAbc;

  /// 状态。
  final TodoStatus status;

  /// 完成时刻。
  final int? completedAt;

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

  /// 校验不变量。
  Todo validated() {
    Validate.nonEmpty(title, 'title');
    if (dueDate != null) {
      Validate.calendarDate(dueDate!, 'dueDate');
    }
    if (estMinutes != null) {
      Validate.range(estMinutes, 0, 24 * 60, 'estMinutes');
    }
    return this;
  }

  /// 不可变复制。
  Todo copyWith({
    String? id,
    String? title,
    String? detail,
    int? estMinutes,
    String? dueDate,
    String? projectId,
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
    TodoStatus? status,
    int? completedAt,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? originDeviceId,
    int? rev,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      estMinutes: estMinutes ?? this.estMinutes,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectId ?? this.projectId,
      quadrant: quadrant ?? this.quadrant,
      priorityAbc: priorityAbc ?? this.priorityAbc,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
    );
  }
}

/// 习惯定义。
final class Habit extends SyncEntity {
  /// 构造习惯。
  Habit({
    required this.id,
    required this.name,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.description = '',
    this.type = HabitType.normal,
    this.targetCount,
    this.targetUnit = '',
    this.scheduleType = HabitScheduleType.daily,
    this.weeklyN,
    this.weekdays = '',
    this.checklistJson = '[]',
    this.domain = '',
    this.archived = false,
    this.pausedUntil,
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 名称。
  final String name;

  /// 描述。
  final String description;

  /// 打卡类型。
  final HabitType type;

  /// 计数型目标值（避免型为 0）。
  final double? targetCount;

  /// 计数单位。
  final String targetUnit;

  /// 排程方式。
  final HabitScheduleType scheduleType;

  /// 每周 N 次（scheduleType='weekly_n' 时有效）。
  final int? weeklyN;

  /// 指定星期 '1,3,5'（1=周一）。
  final String weekdays;

  /// 清单式子项 JSON 数组字符串。
  final String checklistJson;

  /// 领域标签。
  final String domain;

  /// 开始日期。
  final String startDate;

  /// 是否归档。
  final bool archived;

  /// 合法中断出口 —— 该日期前不计入连续天数、不提示断签。
  final String? pausedUntil;

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

  /// 校验不变量。
  ///
  /// 不变量：
  ///  1. name 非空；
  ///  2. type='count' 必须有 targetCount 且 > 0；
  ///  3. scheduleType='weekly_n' 必须有 weeklyN ∈ 1..7；
  ///  4. scheduleType='weekdays' 必须有合法 weekdays；
  ///  5. pausedUntil 必须是合法日历日。
  Habit validated() {
    Validate.nonEmpty(name, 'name');
    Validate.calendarDate(startDate, 'startDate');
    if (type == HabitType.count) {
      if (targetCount == null || targetCount! <= 0) {
        throw DomainValidationException('计数型习惯必须有 targetCount 且大于 0');
      }
    }
    if (scheduleType == HabitScheduleType.weeklyN) {
      if (weeklyN == null || weeklyN! < 1 || weeklyN! > 7) {
        throw DomainValidationException('weekly_n 排程必须有 weeklyN（1~7）');
      }
    }
    if (scheduleType == HabitScheduleType.weekdays) {
      if (parseWeekdays(weekdays).isEmpty) {
        throw DomainValidationException('weekdays 排程必须提供至少一个合法星期');
      }
    }
    if (pausedUntil != null) {
      Validate.calendarDate(pausedUntil!, 'pausedUntil');
    }
    return this;
  }

  /// 不可变复制。
  Habit copyWith({
    String? id,
    String? name,
    String? description,
    HabitType? type,
    double? targetCount,
    String? targetUnit,
    HabitScheduleType? scheduleType,
    int? weeklyN,
    String? weekdays,
    String? checklistJson,
    String? domain,
    String? startDate,
    bool? archived,
    String? pausedUntil,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? originDeviceId,
    int? rev,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      targetUnit: targetUnit ?? this.targetUnit,
      scheduleType: scheduleType ?? this.scheduleType,
      weeklyN: weeklyN ?? this.weeklyN,
      weekdays: weekdays ?? this.weekdays,
      checklistJson: checklistJson ?? this.checklistJson,
      domain: domain ?? this.domain,
      startDate: startDate ?? this.startDate,
      archived: archived ?? this.archived,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
    );
  }

  /// 解析 weekdays 字符串为星期集合（1=周一 .. 7=周日）。
  ///
  /// 非法项静默忽略（不抛异常）—— 同源数据可能来自更高版本 schema。
  static Set<int> parseWeekdays(String raw) {
    if (raw.trim().isEmpty) {
      return const {};
    }
    final out = <int>{};
    for (final part in raw.split(',')) {
      final v = int.tryParse(part.trim());
      if (v != null && v >= 1 && v <= 7) {
        out.add(v);
      }
    }
    return out;
  }
}

/// 打卡记录。
final class HabitCheckin extends SyncEntity {
  /// 构造打卡记录。
  HabitCheckin({
    required this.id,
    required this.habitId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.value = 1,
    this.status = CheckinStatus.done,
    this.note = '',
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 所属习惯。
  final String habitId;

  /// 日历日。
  final String date;

  /// 完成量（计数型用）。
  final double value;

  /// 打卡状态。
  final CheckinStatus status;

  /// 备注。
  final String note;

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

  /// 校验不变量。
  HabitCheckin validated() {
    Validate.calendarDate(date, 'date');
    if (value < 0) {
      throw DomainValidationException('打卡量不能为负');
    }
    return this;
  }
}

/// 提醒 —— 独立表，一实体可挂 N 个。
final class Reminder extends SyncEntity {
  /// 构造提醒。
  Reminder({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.repeatRule = RepeatRule.none,
    this.repeatDetail = '',
    this.enabled = true,
    this.lastFiredAt,
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 目标实体类型。
  final ReminderTargetType targetType;

  /// 目标实体 id。
  final String targetId;

  /// 触发时刻。
  final int remindAt;

  /// 重复规则。
  final RepeatRule repeatRule;

  /// 重复附加参数。
  final String repeatDetail;

  /// 是否启用。
  final bool enabled;

  /// 上次触发时刻。
  final int? lastFiredAt;

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

  /// 校验不变量。
  Reminder validated() {
    if (targetId.trim().isEmpty) {
      throw DomainValidationException('targetId 不能为空');
    }
    return this;
  }
}

/// 项目 —— 长线目标。
final class Project extends SyncEntity {
  /// 构造项目。
  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.goal = '',
    this.startDate,
    this.endDate,
    this.domain = '',
    this.status = ProjectStatus.active,
    this.archived = false,
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 名称。
  final String name;

  /// 目标描述。
  final String goal;

  /// 开始日期。
  final String? startDate;

  /// 结束日期。
  final String? endDate;

  /// 领域标签。
  final String domain;

  /// 状态。
  final ProjectStatus status;

  /// 是否归档。
  final bool archived;

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

  /// 校验不变量。
  Project validated() {
    Validate.nonEmpty(name, 'name');
    if (startDate != null) {
      Validate.calendarDate(startDate!, 'startDate');
    }
    if (endDate != null) {
      Validate.calendarDate(endDate!, 'endDate');
    }
    return this;
  }
}

/// 项目增量记录 —— 只追加，不闭环。
final class ProjectIncrement extends SyncEntity {
  /// 构造增量记录。
  ProjectIncrement({
    required this.id,
    required this.projectId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.planItemId,
    this.progress = '',
    this.blockers = '',
    this.nextStep = '',
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 所属项目。
  final String projectId;

  /// 日历日。
  final String date;

  /// 关联的计划条目。
  final String? planItemId;

  /// 进展。
  final String progress;

  /// 阻碍。
  final String blockers;

  /// 下一步。
  final String nextStep;

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

  /// 校验不变量。
  ProjectIncrement validated() {
    Validate.calendarDate(date, 'date');
    return this;
  }
}

/// 里程碑。
final class ProjectMilestone extends SyncEntity {
  /// 构造里程碑。
  ProjectMilestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.originDeviceId,
    this.targetDate,
    this.achievedAt,
    this.note = '',
    this.deletedAt,
    this.rev = 1,
  });

  @override
  final String id;

  /// 所属项目。
  final String projectId;

  /// 标题。
  final String title;

  /// 目标日期。
  final String? targetDate;

  /// 达成时刻。
  final int? achievedAt;

  /// 备注。
  final String note;

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

  /// 校验不变量。
  ProjectMilestone validated() {
    Validate.nonEmpty(title, 'title');
    if (targetDate != null) {
      Validate.calendarDate(targetDate!, 'targetDate');
    }
    return this;
  }
}

/// oplog 条目 —— 同步账本。
///
/// **这是同步与恢复的唯一依据。** payload 是**字段级 diff**（只含变更字段），
/// 不是整行快照 —— 否则每改一个字就要推整行，oplog 会迅速膨胀。
final class OplogEntry {
  /// 构造 oplog 条目。
  OplogEntry({
    required this.id,
    required this.entityTable,
    required this.entityId,
    required this.op,
    required this.lamport,
    required this.deviceId,
    required this.createdAt,
    this.payload,
    this.synced = false,
  });

  /// 自增 ID（严格单调，作为增量拉取游标）。
  final int id;

  /// 实体表名。
  final String entityTable;

  /// 实体 id。
  final String entityId;

  /// 操作类型。
  final OplogOp op;

  /// 字段级 diff 的 JSON 文本；删除操作时为 null。
  final String? payload;

  /// 跨设备逻辑时钟。
  final int lamport;

  /// 产生该变更的设备。
  final String deviceId;

  /// 产生时刻。
  final int createdAt;

  /// 是否已推送到中继。
  final bool synced;

  /// 删除操作必须是 delete，且 payload 为空或仅含 deleted_at。
  bool get isValid =>
      op == OplogOp.upsert ? payload != null && payload!.isNotEmpty : true;
}
