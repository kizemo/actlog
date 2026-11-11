// =============================================================================
// core_db · drift 表定义（schema v1）
// =============================================================================
// 纪律：
//   1. 本文件必须与 docs/schema_v1.sql **逐字段**一致 —— 列名、顺序、类型、
//      可空性、默认值、CHECK / UNIQUE / FOREIGN KEY 约束名、索引名。
//      改这里 = 改 schema = 必须走 schema v2 迁移，不得原地改。
//   2. 枚举取值必须与 packages/core_domain 的枚举 code 一致
//      （测试 test/enum_constraint_parity_test.dart 会交叉校验）。
//   3. 布尔语义列一律用 integer()，**不要用 boolean()** ——
//      drift 的 boolean() 生成 "BOOLEAN" 类型，而 schema_v1.sql 用的是 INTEGER。
//   4. 列名由 getter 名按 snake_case 推导；少数与推导结果不同的列
//      （mood_1..mood_8）用 .named(...) 显式指定。
//
// 关于外键的两处写法（重要，不要"简化"）：
//   · references(...)  —— drift DSL 的类型安全外键声明，生成列级
//     REFERENCES "todo" ("id") ON DELETE SET NULL。
//   · customConstraints 里的 CONSTRAINT xxx_fk FOREIGN KEY (...) —— 与
//     schema_v1.sql **同名同体**的具名外键约束。
//   drift 的 DSL 无法给外键约束命名，要同时满足「用 references()」与
//   「外键约束显式命名」，只能两者都写。两处描述的是同一条外键关系
//   （同一列 → 同一目标表/列 → 同一 ON DELETE 动作），SQLite 会按同一条
//   规则强制执行，语义完全一致。schema 一致性测试按「去重后的外键关系集合」
//   比对，见 test/schema_consistency_test.dart。
// =============================================================================

import 'package:drift/drift.dart';

/// 全库表名常量（与 schema_v1.sql 中的表名逐字一致）。
abstract final class TableNames {
  /// 用户配置。
  static const String settings = 'settings';

  /// 每日日志。
  static const String dayLog = 'day_log';

  /// 当日计划条目。
  static const String planItem = 'plan_item';

  /// 待办池。
  static const String todo = 'todo';

  /// 习惯定义。
  static const String habit = 'habit';

  /// 习惯打卡记录。
  static const String habitCheckin = 'habit_checkin';

  /// 习惯强度评分（派生，本机）。
  static const String habitScore = 'habit_score';

  /// 长线项目。
  static const String project = 'project';

  /// 项目里程碑。
  static const String projectMilestone = 'project_milestone';

  /// 项目增量记录。
  static const String projectIncrement = 'project_increment';

  /// 独立提醒。
  static const String reminder = 'reminder';

  /// 同步账本。
  static const String oplog = 'oplog';

  /// 本机同步游标（本机）。
  static const String syncState = 'sync_state';

  /// 本地快照索引（本机）。
  static const String snapshotMeta = 'snapshot_meta';

  /// 循环任务定义（schema v2 新增）。
  static const String recurringTask = 'recurring_task';

  /// 循环任务在某一天的实例（schema v2 新增）。
  static const String recurringOccurrence = 'recurring_occurrence';
}

/// 用户配置（键值对，同步）。
  @TableIndex(name: 'idx_settings_updated_at', columns: {#updatedAt})
class Settings extends Table {
  /// 表名。
  @override
  String get tableName => 'settings';

  /// 主键（UUIDv7 文本）。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 配置键。
  TextColumn get key => text()();

  /// 配置值（JSON 文本；bool 存 0/1）。
  TextColumn get value => text().withDefault(const Constant(''))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT settings_key_unique UNIQUE (key)',
  ];
}

/// 每日日志（一天一行，同步）。
  @TableIndex(name: 'idx_day_log_updated_at', columns: {#updatedAt})
class DayLog extends Table {
  /// 表名。
  @override
  String get tableName => 'day_log';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 日历日 'YYYY-MM-DD'。
  TextColumn get date => text()();

  /// 完整版 / 极简版。
  TextColumn get mode => text().withDefault(const Constant('full'))();

  /// 复盘三段 · 学到了什么。
  TextColumn get learning => text().withDefault(const Constant(''))();

  /// 复盘三段 · 做得好的。
  TextColumn get good => text().withDefault(const Constant(''))();

  /// 复盘三段 · 待改进的。
  TextColumn get improve => text().withDefault(const Constant(''))();

  /// 可控的事。
  TextColumn get controllable => text().withDefault(const Constant(''))();

  /// 不可控的事。
  TextColumn get uncontrollable => text().withDefault(const Constant(''))();

  /// 下一步可控动作。
  TextColumn get nextAction => text().withDefault(const Constant(''))();

  /// 情绪备注。
  TextColumn get moodNote => text().withDefault(const Constant(''))();

  /// 心态 1 认真。
  IntColumn get mood1 => integer().nullable().named('mood_1')();

  /// 心态 2 快。
  IntColumn get mood2 => integer().nullable().named('mood_2')();

  /// 心态 3 坚守承诺。
  IntColumn get mood3 => integer().nullable().named('mood_3')();

  /// 心态 4 保证完成任务。
  IntColumn get mood4 => integer().nullable().named('mood_4')();

  /// 心态 5 乐观。
  IntColumn get mood5 => integer().nullable().named('mood_5')();

  /// 心态 6 自信。
  IntColumn get mood6 => integer().nullable().named('mood_6')();

  /// 心态 7 爱与奉献。
  IntColumn get mood7 => integer().nullable().named('mood_7')();

  /// 心态 8 决不找借口。
  IntColumn get mood8 => integer().nullable().named('mood_8')();

  /// 今日失守（0/1）。
  IntColumn get moodFailed => integer().withDefault(const Constant(0))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT day_log_date_unique UNIQUE (date)',
    "CONSTRAINT day_log_mode_check CHECK (mode IN ('full', 'minimal'))",
    'CONSTRAINT day_log_mood_failed_check CHECK (mood_failed IN (0, 1))',
    'CONSTRAINT day_log_mood_1_check '
        "CHECK (mood_1 IS NULL OR (mood_1 >= 0 AND mood_1 <= 10))",
    'CONSTRAINT day_log_mood_2_check '
        "CHECK (mood_2 IS NULL OR (mood_2 >= 0 AND mood_2 <= 10))",
    'CONSTRAINT day_log_mood_3_check '
        "CHECK (mood_3 IS NULL OR (mood_3 >= 0 AND mood_3 <= 10))",
    'CONSTRAINT day_log_mood_4_check '
        "CHECK (mood_4 IS NULL OR (mood_4 >= 0 AND mood_4 <= 10))",
    'CONSTRAINT day_log_mood_5_check '
        "CHECK (mood_5 IS NULL OR (mood_5 >= 0 AND mood_5 <= 10))",
    'CONSTRAINT day_log_mood_6_check '
        "CHECK (mood_6 IS NULL OR (mood_6 >= 0 AND mood_6 <= 10))",
    'CONSTRAINT day_log_mood_7_check '
        "CHECK (mood_7 IS NULL OR (mood_7 >= 0 AND mood_7 <= 10))",
    'CONSTRAINT day_log_mood_8_check '
        "CHECK (mood_8 IS NULL OR (mood_8 >= 0 AND mood_8 <= 10))",
  ];
}

/// 当日计划条目（同步）。
  @TableIndex(name: 'idx_plan_item_date', columns: {#date})
  @TableIndex(name: 'idx_plan_item_date_status', columns: {#date, #status})
  @TableIndex(name: 'idx_plan_item_source_todo', columns: {#sourceTodoId})
  @TableIndex(name: 'idx_plan_item_source', columns: {#sourceType, #sourceId})
  @TableIndex(name: 'idx_plan_item_updated_at', columns: {#updatedAt})
class PlanItem extends Table {
  /// 表名。
  @override
  String get tableName => 'plan_item';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 所属日历日 'YYYY-MM-DD'。
  TextColumn get date => text()();

  /// 标题（来源为待办时存的是当时的标题快照）。
  TextColumn get title => text()();

  /// 详情。
  TextColumn get detail => text().withDefault(const Constant(''))();

  /// 来源类型。
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();

  /// 多态来源指针。
  TextColumn get sourceId => text().nullable()();

  /// 显式指向 todo.id。
  TextColumn get sourceTodoId =>
      text().nullable().references(Todo, #id, onDelete: KeyAction.setNull)();

  /// 四象限。
  TextColumn get quadrant => text().nullable()();

  /// ABC 优先级。
  TextColumn get priorityAbc => text().nullable()();

  /// 领域标签。
  TextColumn get domain => text().withDefault(const Constant(''))();

  /// 预估分钟数。
  IntColumn get estMinutes => integer().nullable()();

  /// 计划开始时刻。
  IntColumn get plannedStart => integer().nullable()();

  /// 计划结束时刻。
  IntColumn get plannedEnd => integer().nullable()();

  /// 状态。
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// 完成时刻。
  IntColumn get doneAt => integer().nullable()();

  /// 成果 / 进展备注。
  TextColumn get resultNote => text().withDefault(const Constant(''))();

  /// 是否由习惯打卡回填生成。
  IntColumn get isHabitRef => integer().withDefault(const Constant(0))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT plan_item_source_type_check CHECK (source_type IN "
        "('manual', 'todo', 'habit', 'project', 'increment'))",
    "CONSTRAINT plan_item_quadrant_check CHECK (quadrant IS NULL OR quadrant "
        "IN ('Q1', 'Q2', 'Q3', 'Q4'))",
    "CONSTRAINT plan_item_priority_abc_check CHECK (priority_abc IS NULL OR "
        "priority_abc IN ('A', 'B', 'C'))",
    "CONSTRAINT plan_item_status_check CHECK (status IN ('pending', 'done', "
        "'cancelled', 'deferred'))",
    'CONSTRAINT plan_item_is_habit_ref_check CHECK (is_habit_ref IN (0, 1))',
    'CONSTRAINT plan_item_est_minutes_check '
        'CHECK (est_minutes IS NULL OR est_minutes >= 0)',
    'CONSTRAINT plan_item_source_todo_fk FOREIGN KEY (source_todo_id) '
        'REFERENCES todo (id) ON DELETE SET NULL',
  ];
}

/// 待办池（同步）。
  @TableIndex(name: 'idx_todo_status', columns: {#status})
  @TableIndex(name: 'idx_todo_due_date', columns: {#dueDate})
  @TableIndex(name: 'idx_todo_project', columns: {#projectId})
  @TableIndex(name: 'idx_todo_updated_at', columns: {#updatedAt})
class Todo extends Table {
  /// 表名。
  @override
  String get tableName => 'todo';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 标题。
  TextColumn get title => text()();

  /// 详情。
  TextColumn get detail => text().withDefault(const Constant(''))();

  /// 预估分钟数。
  IntColumn get estMinutes => integer().nullable()();

  /// 截止日历日。
  TextColumn get dueDate => text().nullable()();

  /// 所属项目。
  TextColumn get projectId =>
      text().nullable().references(Project, #id, onDelete: KeyAction.setNull)();

  /// 四象限。
  TextColumn get quadrant => text().nullable()();

  /// ABC 优先级。
  TextColumn get priorityAbc => text().nullable()();

  /// 状态。
  TextColumn get status => text().withDefault(const Constant('open'))();

  /// 完成时刻。
  IntColumn get completedAt => integer().nullable()();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT todo_status_check CHECK (status IN ('open', 'done', "
        "'cancelled', 'archived'))",
    "CONSTRAINT todo_quadrant_check CHECK (quadrant IS NULL OR quadrant IN "
        "('Q1', 'Q2', 'Q3', 'Q4'))",
    'CONSTRAINT todo_priority_abc_check CHECK (priority_abc IS NULL OR '
        "priority_abc IN ('A', 'B', 'C'))",
    'CONSTRAINT todo_est_minutes_check '
        'CHECK (est_minutes IS NULL OR est_minutes >= 0)',
    'CONSTRAINT todo_project_fk FOREIGN KEY (project_id) '
        'REFERENCES project (id) ON DELETE SET NULL',
  ];
}

/// 习惯定义（同步）。
  @TableIndex(name: 'idx_habit_archived', columns: {#archived})
  @TableIndex(name: 'idx_habit_updated_at', columns: {#updatedAt})
class Habit extends Table {
  /// 表名。
  @override
  String get tableName => 'habit';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 名称。
  TextColumn get name => text()();

  /// 描述。
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 打卡类型。
  TextColumn get type => text().withDefault(const Constant('normal'))();

  /// 计数型目标值。
  RealColumn get targetCount => real().nullable()();

  /// 计数单位。
  TextColumn get targetUnit => text().withDefault(const Constant(''))();

  /// 排程方式。
  TextColumn get scheduleType => text().withDefault(const Constant('daily'))();

  /// 每周 N 次。
  IntColumn get weeklyN => integer().nullable()();

  /// 指定星期 '1,3,5'。
  TextColumn get weekdays => text().withDefault(const Constant(''))();

  /// 清单式子项 JSON 数组字符串。
  TextColumn get checklistJson => text().withDefault(const Constant('[]'))();

  /// 领域标签。
  TextColumn get domain => text().withDefault(const Constant(''))();

  /// 开始日期。
  TextColumn get startDate => text()();

  /// 是否归档。
  IntColumn get archived => integer().withDefault(const Constant(0))();

  /// 合法中断出口（假期模式）。
  TextColumn get pausedUntil => text().nullable()();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT habit_type_check CHECK (type IN ('normal', 'count', 'avoid', "
        "'checklist'))",
    "CONSTRAINT habit_schedule_type_check CHECK (schedule_type IN ('daily', "
        "'weekly_n', 'weekdays'))",
    'CONSTRAINT habit_archived_check CHECK (archived IN (0, 1))',
    'CONSTRAINT habit_target_count_check '
        'CHECK (target_count IS NULL OR target_count >= 0)',
    'CONSTRAINT habit_weekly_n_check '
        'CHECK (weekly_n IS NULL OR weekly_n BETWEEN 1 AND 7)',
  ];
}

/// 打卡记录（同步）。
  @TableIndex(name: 'idx_habit_checkin_date', columns: {#date})
  @TableIndex(name: 'idx_habit_checkin_updated_at', columns: {#updatedAt})
class HabitCheckin extends Table {
  /// 表名。
  @override
  String get tableName => 'habit_checkin';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 所属习惯。
  TextColumn get habitId =>
      text().references(Habit, #id, onDelete: KeyAction.cascade)();

  /// 打卡日期 'YYYY-MM-DD'。
  TextColumn get date => text()();

  /// 计数型完成量。
  ///
  /// 权威 DDL 为 `value REAL NOT NULL DEFAULT 1`。drift 的 `real()` 列会把
  /// 默认值推断成 double 并写成 `DEFAULT 1.0`，与 schema_v1.sql 的字面量
  /// 不一致；这里改用列级自定义约束输出 `DEFAULT 1`，同时用 [clientDefault]
  /// 保留 drift 侧的客户端默认值（插入时可省略该列）。
  RealColumn get value =>
      real().clientDefault(() => 1.0).customConstraint('NOT NULL DEFAULT 1')();

  /// 打卡状态。
  TextColumn get status => text().withDefault(const Constant('done'))();

  /// 备注。
  TextColumn get note => text().withDefault(const Constant(''))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT habit_checkin_status_check CHECK (status IN ('done', 'skip', "
        "'failed'))",
    'CONSTRAINT habit_checkin_pair_unique UNIQUE (habit_id, date)',
    'CONSTRAINT habit_checkin_habit_fk FOREIGN KEY (habit_id) '
        'REFERENCES habit (id) ON DELETE CASCADE',
  ];
}

/// 习惯强度评分与连续天数（**本地派生，不同步**）。
  @TableIndex(name: 'idx_habit_score_habit_date', columns: {#habitId, #date})
class HabitScore extends Table {
  /// 表名。
  @override
  String get tableName => 'habit_score';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 所属习惯。
  TextColumn get habitId =>
      text().references(Habit, #id, onDelete: KeyAction.cascade)();

  /// 日期 'YYYY-MM-DD'。
  TextColumn get date => text()();

  /// 当日强度评分（0–100）。
  ///
  /// 与 [HabitCheckins.value] 同理：用列级自定义约束输出 schema_v1.sql 的
  /// 字面量 `DEFAULT 0`（drift 的 real() 默认值会被写成 `0.0`）。
  RealColumn get score =>
      real().clientDefault(() => 0.0).customConstraint('NOT NULL DEFAULT 0')();

  /// 当前连续天数。
  IntColumn get streak => integer().withDefault(const Constant(0))();

  /// 历史最长连续天数。
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT habit_score_pair_unique UNIQUE (habit_id, date)',
    'CONSTRAINT habit_score_habit_fk FOREIGN KEY (habit_id) '
        'REFERENCES habit (id) ON DELETE CASCADE',
  ];
}

/// 长线项目（同步）。
  @TableIndex(name: 'idx_project_status', columns: {#status})
  @TableIndex(name: 'idx_project_updated_at', columns: {#updatedAt})
class Project extends Table {
  /// 表名。
  @override
  String get tableName => 'project';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 项目名称。
  TextColumn get name => text()();

  /// 目标。
  TextColumn get goal => text().withDefault(const Constant(''))();

  /// 开始日期。
  TextColumn get startDate => text().nullable()();

  /// 结束日期。
  TextColumn get endDate => text().nullable()();

  /// 领域标签。
  TextColumn get domain => text().withDefault(const Constant(''))();

  /// 项目状态。
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// 是否归档。
  IntColumn get archived => integer().withDefault(const Constant(0))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT project_status_check CHECK (status IN ('active', 'paused', "
        "'done', 'cancelled'))",
    'CONSTRAINT project_archived_check CHECK (archived IN (0, 1))',
  ];
}

/// 里程碑（同步）。
  @TableIndex(name: 'idx_project_milestone_project', columns: {#projectId})
  @TableIndex(name: 'idx_project_milestone_target_date', columns: {#targetDate})
class ProjectMilestone extends Table {
  /// 表名。
  @override
  String get tableName => 'project_milestone';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 所属项目。
  TextColumn get projectId =>
      text().references(Project, #id, onDelete: KeyAction.cascade)();

  /// 标题。
  TextColumn get title => text()();

  /// 目标日期。
  TextColumn get targetDate => text().nullable()();

  /// 达成时刻。
  IntColumn get achievedAt => integer().nullable()();

  /// 备注。
  TextColumn get note => text().withDefault(const Constant(''))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT project_milestone_project_fk FOREIGN KEY (project_id) '
        'REFERENCES project (id) ON DELETE CASCADE',
  ];
}

/// 项目增量记录（同步）。
  @TableIndex(name: 'idx_project_increment_project_date', columns: {#projectId, #date})
  @TableIndex(name: 'idx_project_increment_date', columns: {#date})
class ProjectIncrement extends Table {
  /// 表名。
  @override
  String get tableName => 'project_increment';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 所属项目。
  TextColumn get projectId =>
      text().references(Project, #id, onDelete: KeyAction.cascade)();

  /// 日期 'YYYY-MM-DD'。
  TextColumn get date => text()();

  /// 关联的计划条目。
  TextColumn get planItemId =>
      text().nullable().references(PlanItem, #id, onDelete: KeyAction.setNull)();

  /// 进展。
  TextColumn get progress => text().withDefault(const Constant(''))();

  /// 阻塞项。
  TextColumn get blockers => text().withDefault(const Constant(''))();

  /// 下一步。
  TextColumn get nextStep => text().withDefault(const Constant(''))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT project_increment_project_fk FOREIGN KEY (project_id) '
        'REFERENCES project (id) ON DELETE CASCADE',
    'CONSTRAINT project_increment_plan_item_fk FOREIGN KEY (plan_item_id) '
        'REFERENCES plan_item (id) ON DELETE SET NULL',
  ];
}

/// 独立提醒（同步）。
  @TableIndex(name: 'idx_reminder_target', columns: {#targetType, #targetId})
  @TableIndex(name: 'idx_reminder_remind_at', columns: {#remindAt})
  @TableIndex(name: 'idx_reminder_enabled', columns: {#enabled, #remindAt})
class Reminder extends Table {
  /// 表名。
  @override
  String get tableName => 'reminder';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 目标实体类型。
  TextColumn get targetType => text()();

  /// 目标实体 ID（多态指针，不设 FK）。
  TextColumn get targetId => text()();

  /// 提醒时刻。
  IntColumn get remindAt => integer()();

  /// 重复规则。
  TextColumn get repeatRule => text().withDefault(const Constant('none'))();

  /// 重复附加参数。
  TextColumn get repeatDetail => text().withDefault(const Constant(''))();

  /// 是否启用。
  IntColumn get enabled => integer().withDefault(const Constant(1))();

  /// 上次触发时刻。
  IntColumn get lastFiredAt => integer().nullable()();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT reminder_target_type_check CHECK (target_type IN "
        "('plan_item', 'todo', 'habit', 'project'))",
    "CONSTRAINT reminder_repeat_rule_check CHECK (repeat_rule IN ('none', "
        "'daily', 'weekly', 'monthly', 'yearly'))",
    'CONSTRAINT reminder_enabled_check CHECK (enabled IN (0, 1))',
  ];
}

/// 同步账本（本地生成；本表内容参与同步）。
///
/// id 必须是 INTEGER AUTOINCREMENT —— 增量拉取要的是严格单调序号，
/// UUIDv7 只是「大致有序」，中继端分页会产生空洞与重复。
  @TableIndex(name: 'idx_oplog_entity', columns: {#entityTable, #entityId})
  @TableIndex(name: 'idx_oplog_synced', columns: {#synced, #id})
  @TableIndex(name: 'idx_oplog_lamport', columns: {#lamport})
  @TableIndex(name: 'idx_oplog_device', columns: {#deviceId})
class Oplog extends Table {
  /// 表名。
  @override
  String get tableName => 'oplog';

  /// 自增 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 实体表名。
  TextColumn get entityTable => text()();

  /// 实体 ID。
  TextColumn get entityId => text()();

  /// 操作类型：upsert / delete。
  TextColumn get op => text()();

  /// JSON 字段级 diff；delete 时为 {"deleted_at": ms}。
  TextColumn get payload => text().nullable()();

  /// 跨设备逻辑时钟（LWW 定序）。
  IntColumn get lamport => integer()();

  /// 产生该条变更的设备。
  TextColumn get deviceId => text()();

  /// 记录时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 是否已确认中继已收。
  IntColumn get synced => integer().withDefault(const Constant(0))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT oplog_op_check CHECK (op IN ('upsert', 'delete'))",
  ];
}

/// 本机同步游标（**本机，不同步**）。
///
/// key 取值：cursor / lamport / device_id / channel / relay_code /
/// last_sync_at。
class SyncState extends Table {
  /// 表名。
  @override
  String get tableName => 'sync_state';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 键。
  TextColumn get key => text()();

  /// 值。
  TextColumn get value => text().withDefault(const Constant(''))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT sync_state_key_unique UNIQUE (key)',
  ];
}

/// 本地快照索引（**本机，不同步**）。
  @TableIndex(name: 'idx_snapshot_meta_kind', columns: {#kind})
class SnapshotMeta extends Table {
  /// 表名。
  @override
  String get tableName => 'snapshot_meta';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 快照文件路径。
  TextColumn get path => text()();

  /// 快照类型。
  TextColumn get kind => text()();

  /// 快照内容哈希。
  TextColumn get sha256 => text()();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（与 schema_v1.sql 一致）。
  @override
  List<String> get customConstraints => const [
    "CONSTRAINT snapshot_meta_kind_check CHECK (kind IN ('daily', 'weekly', "
        "'monthly', 'manual', 'export'))",
  ];
}

// =============================================================================
// schema v2 新增：循环任务（recurring task）
// =============================================================================
// 为什么不复用既有表（两条都是硬理由，改之前先读）：
//   1. plan_item 是**某一天的事实**，循环任务是**一条周规则**。混在一张表里，
//      「按规则物化」与「手工排期」两类行在查询上再也分不开；而
//      `plan_item_source_type_check` 在 v1 已冻结为
//      manual/todo/habit/project/increment 五个值，加第六个值必须重建整表，
//      迁移代价远大于新增两张表。
//   2. habit 的排程语义是**打卡**（每天 / 每周 N 次 / 指定星期），没有
//      「固定起始时刻 + 时长」这两个字段，它是时间块，不是打卡。
//
// 物化链路：
//   recurring_task 1─N→ recurring_occurrence (task_id, date)
//   recurring_occurrence.plan_item_id → plan_item.id（生成出来的那一行）
//   「同一任务同一天只有一条实例」由 UNIQUE (task_id, date) 在**库层**兜底，
//   调用方不必先查后写，重复调用只会撞唯一约束、不会多出计划条目。
//
// 同步：两张表**都已**在 `oplog_writer.dart` 的 `syncedTables` 白名单内，
// 落库一律走 `writeWithOplog`（规则 create / setActive / archive 三处，
// occurrence 每次物化插入一笔）。
// 为什么必须在白名单里：`recurring_occurrence` 是物化凭证，不同步 ⇒ 新设备
// 以为一条都没物化过 ⇒ 重新物化 ⇒ `plan_item`（同步表，原有条目会被拉回来）
// 里出现**重复条目**。凭证必须跟规则一起走。
// =============================================================================

/// 循环任务定义（每周几 · 几点 · 多久）。
  @TableIndex(name: 'idx_recurring_task_active', columns: {#active})
  @TableIndex(name: 'idx_recurring_task_updated_at', columns: {#updatedAt})
class RecurringTask extends Table {
  /// 表名。
  @override
  String get tableName => 'recurring_task';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 标题（物化时作为 `plan_item.title` 的初值）。
  TextColumn get title => text()();

  /// 备注。
  TextColumn get note => text().withDefault(const Constant(''))();

  /// 星期掩码：bit0 = 周一 … bit6 = 周日（0..127）。
  IntColumn get weekdayMask => integer()();

  /// 起始时刻（一天中的第几分钟，0..1439）。
  IntColumn get startMinute => integer()();

  /// 时长（分钟）。
  IntColumn get durationMinutes =>
      integer().withDefault(const Constant(30))();

  /// 是否启用（0/1）；停用只影响**后续**物化，已生成的实例保留。
  IntColumn get active => integer().withDefault(const Constant(1))();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（v2 新增，`docs/schema_v1.sql` 里没有这两张表）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT recurring_task_weekday_mask_check '
        'CHECK (weekday_mask BETWEEN 0 AND 127)',
    'CONSTRAINT recurring_task_start_minute_check '
        'CHECK (start_minute BETWEEN 0 AND 1439)',
    'CONSTRAINT recurring_task_duration_check '
        'CHECK (duration_minutes BETWEEN 0 AND 1440)',
    'CONSTRAINT recurring_task_active_check CHECK (active IN (0, 1))',
  ];
}

/// 循环任务在某一天的实例（**物化凭证**：一条 = 已为某天生成过计划条目）。
  @TableIndex(name: 'idx_recurring_occurrence_date', columns: {#date})
  @TableIndex(name: 'idx_recurring_occurrence_updated_at', columns: {#updatedAt})
class RecurringOccurrence extends Table {
  /// 表名。
  @override
  String get tableName => 'recurring_occurrence';

  /// 主键。
  @override
  Set<Column> get primaryKey => {id};

  /// 实体 ID。
  TextColumn get id => text()();

  /// 所属循环任务。
  TextColumn get taskId =>
      text().references(RecurringTask, #id, onDelete: KeyAction.cascade)();

  /// 日历日 `YYYY-MM-DD`。
  TextColumn get date => text()();

  /// 生成出来的计划条目；该行被物理删除时置空（**不**影响幂等性）。
  TextColumn get planItemId =>
      text().nullable().references(PlanItem, #id, onDelete: KeyAction.setNull)();

  /// 创建时刻（Unix 毫秒）。
  IntColumn get createdAt => integer()();

  /// 最后更新时刻（Unix 毫秒）。
  IntColumn get updatedAt => integer()();

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  IntColumn get deletedAt => integer().nullable()();

  /// 最后写入本行的设备 ID。
  TextColumn get originDeviceId => text()();

  /// 本地修订号。
  IntColumn get rev => integer().withDefault(const Constant(1))();

  /// 具名约束（v2 新增）。
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT recurring_occurrence_task_date_unique '
        'UNIQUE (task_id, date)',
    'CONSTRAINT recurring_occurrence_task_fk FOREIGN KEY (task_id) '
        'REFERENCES recurring_task (id) ON DELETE CASCADE',
    'CONSTRAINT recurring_occurrence_plan_item_fk '
        'FOREIGN KEY (plan_item_id) REFERENCES plan_item (id) '
        'ON DELETE SET NULL',
  ];
}

