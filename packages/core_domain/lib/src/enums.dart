// =============================================================================
// core_domain · 枚举与不变量
// =============================================================================
// 纪律：本包**不得有任何 IO 依赖**（不 import dart:io / drift / flutter）。
//       领域模型必须能在纯 Dart VM 上单测，否则无法独立验证。
// 唯一真源：docs/schema_v1.sql 的 CHECK 约束。两边取值必须逐字一致，
//       否则门禁 G3 的「drift schema ↔ schema_v1.sql 比对」会失败。
// =============================================================================

/// 优先级四象限。
///
/// 铁律（来自 MVP v0.2 第五章）：
///  1. 默认用四象限做日常排程；设置项可切到 ABC 模式；
///  2. 同一时刻只显示一套标签 —— 双标签会让用户每天做两次无意义判断；
///  3. 完整版日志的「A 类要事」列在四象限模式下 = Q1 + Q2。
///
/// **诚实说明**：四象限不是《高绩效人士的五项管理》的体系，原书只有 ABC。
/// 对外宣传不得称「四象限来自五项管理」。
enum Quadrant {
  /// 重要且紧急 —— 立即做。
  q1('Q1', '重要且紧急'),

  /// 重要不紧急 —— 计划做。这是「要事」的核心区间。
  q2('Q2', '重要不紧急'),

  /// 紧急不重要 —— 委托或压缩。
  q3('Q3', '紧急不重要'),

  /// 不重要不紧急 —— 砍掉。
  q4('Q4', '不重要不紧急');

  /// 构造 [Quadrant] 常量。

  const Quadrant(this.code, this.label);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 中文显示名。
  final String label;

  /// 重要的事（无论是否紧急）—— 四象限模式下等价于原书的「A 类要事」。
  bool get isImportant => this == Quadrant.q1 || this == Quadrant.q2;

  /// 紧急的事。
  bool get isUrgent => this == Quadrant.q1 || this == Quadrant.q3;

  /// 从数据库取值解析；无法识别时返回 null（**不抛异常**），
  /// 因为同步对端可能来自更高版本的 schema。
  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static Quadrant? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final q in Quadrant.values) {
      if (q.code == code) {
        return q;
      }
    }
    return null;
  }
}

/// 原书体系的三级优先级（只用于完整版日志的 A/B/C 列）。
enum PriorityAbc {
  /// 最重要。
  a('A', 'A 类要事'),

  /// 重要。
  b('B', 'B 类次要'),

  /// 次重要。
  c('C', 'C 类一般');

  /// 构造 [PriorityAbc] 常量。

  const PriorityAbc(this.code, this.label);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 中文显示名。
  final String label;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static PriorityAbc? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final p in PriorityAbc.values) {
      if (p.code == code) {
        return p;
      }
    }
    return null;
  }
}

/// 计划条目的状态。
enum PlanStatus {
  /// 未开始。
  pending('pending'),

  /// 已完成。
  done('done'),

  /// 已取消。
  cancelled('cancelled'),

  /// 已推迟（顺延到别的日子）。
  deferred('deferred');

  /// 构造 [PlanStatus] 常量。

  const PlanStatus(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static PlanStatus? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final s in PlanStatus.values) {
      if (s.code == code) {
        return s;
      }
    }
    return null;
  }
}

/// 待办的状态。
enum TodoStatus {
  /// 进行中 / 未开始。
  open('open'),

  /// 已完成。
  done('done'),

  /// 已取消。
  cancelled('cancelled'),

  /// 已归档（从池子收起但保留）。
  archived('archived');

  /// 构造 [TodoStatus] 常量。

  const TodoStatus(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static TodoStatus? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final s in TodoStatus.values) {
      if (s.code == code) {
        return s;
      }
    }
    return null;
  }
}

/// 习惯的打卡类型。
enum HabitType {
  /// 普通：完成即达标。
  normal('normal'),

  /// 计数型：带单位与目标值（喝水 8 杯）。
  count('count'),

  /// 避免型：目标为「不发生」（熬夜次数 0 次）。
  avoid('avoid'),

  /// 清单式：一组子项全勾选才算。
  checklist('checklist');

  /// 构造 [HabitType] 常量。

  const HabitType(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static HabitType? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final t in HabitType.values) {
      if (t.code == code) {
        return t;
      }
    }
    return null;
  }
}

/// 习惯的排程方式。
enum HabitScheduleType {
  /// 每日。
  daily('daily'),

  /// 每周 N 次。
  weeklyN('weekly_n'),

  /// 指定星期（'1,3,5'，1=周一）。
  weekdays('weekdays');

  /// 构造 [HabitScheduleType] 常量。

  const HabitScheduleType(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static HabitScheduleType? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final t in HabitScheduleType.values) {
      if (t.code == code) {
        return t;
      }
    }
    return null;
  }
}

/// 打卡状态。
enum CheckinStatus {
  /// 完成。
  done('done'),

  /// 跳过 —— **合法中断出口**：不打断连续天数。
  skip('skip'),

  /// 失败 —— 打断连续天数。
  failed('failed');

  /// 构造 [CheckinStatus] 常量。

  const CheckinStatus(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 跳过不打断连击；失败打断。
  bool get breaksStreak => this == CheckinStatus.failed;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static CheckinStatus? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final s in CheckinStatus.values) {
      if (s.code == code) {
        return s;
      }
    }
    return null;
  }
}

/// 每日日志的显示模式。
enum LogMode {
  /// 完整版（ABC 列、复盘三段、8 维度心态）。
  full('full'),

  /// 极简版。
  minimal('minimal');

  /// 构造 [LogMode] 常量。

  const LogMode(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static LogMode? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final m in LogMode.values) {
      if (m.code == code) {
        return m;
      }
    }
    return null;
  }
}

/// 项目状态。
enum ProjectStatus {
  /// 进行中。
  active('active'),

  /// 暂停。
  paused('paused'),

  /// 已完成。
  done('done'),

  /// 已取消。
  cancelled('cancelled');

  /// 构造 [ProjectStatus] 常量。

  const ProjectStatus(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static ProjectStatus? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final s in ProjectStatus.values) {
      if (s.code == code) {
        return s;
      }
    }
    return null;
  }
}

/// 提醒指向的实体类型。
enum ReminderTargetType {
  /// 指向计划条目。
  planItem('plan_item'),

  /// 指向待办。
  todo('todo'),

  /// 指向习惯。
  habit('habit'),

  /// 指向项目。
  project('project');

  /// 构造 [ReminderTargetType] 常量。

  const ReminderTargetType(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static ReminderTargetType? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final t in ReminderTargetType.values) {
      if (t.code == code) {
        return t;
      }
    }
    return null;
  }
}

/// 提醒的重复规则。
enum RepeatRule {
  /// 不重复。
  none('none'),

  /// 每天。
  daily('daily'),

  /// 每周（repeat_detail 存星期集合）。
  weekly('weekly'),

  /// 每月（repeat_detail 存日期）。
  monthly('monthly'),

  /// 每年。
  yearly('yearly');

  /// 构造 [RepeatRule] 常量。

  const RepeatRule(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static RepeatRule? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final r in RepeatRule.values) {
      if (r.code == code) {
        return r;
      }
    }
    return null;
  }
}

/// oplog 的操作类型。
enum OplogOp {
  /// 新增或更新（payload 为字段级 diff）。
  upsert('upsert'),

  /// 删除（墓碑）。
  delete('delete');

  /// 构造 [OplogOp] 常量。

  const OplogOp(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static OplogOp? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final o in OplogOp.values) {
      if (o.code == code) {
        return o;
      }
    }
    return null;
  }
}

/// 计划条目的来源类型。
enum PlanSourceType {
  /// 手工创建。
  manual('manual'),

  /// 从待办「引用 + 快照」而来。
  todo('todo'),

  /// 由习惯打卡回填生成。
  habit('habit'),

  /// 由项目动作生成。
  project('project'),

  /// 由项目增量回填生成。
  increment('increment');

  /// 构造 [PlanSourceType] 常量。

  const PlanSourceType(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static PlanSourceType? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final t in PlanSourceType.values) {
      if (t.code == code) {
        return t;
      }
    }
    return null;
  }
}

/// 优先级显示模式（设置项）。
///
/// 铁律：这是**显示层**的开关，不改变数据。数据里 quadrant 与 priority_abc
/// 都存着，UI 按这个模式只渲染其中一套。
enum PriorityDisplayMode {
  /// 四象限（默认）。
  quadrant('quadrant'),

  /// ABC（原书体系）。
  abc('abc');

  /// 构造 [PriorityDisplayMode] 常量。

  const PriorityDisplayMode(this.code);

  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。
  final String code;

  /// 从数据库存储值解析。

  ///

  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的

  /// schema，抛异常会导致整个同步批次失败。

  static PriorityDisplayMode? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final m in PriorityDisplayMode.values) {
      if (m.code == code) {
        return m;
      }
    }
    return null;
  }
}
