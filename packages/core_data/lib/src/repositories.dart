// =============================================================================
// core_data · 仓储层（P1-1 / P1-3 / P1-6 / P1-8 的数据通道）
// =============================================================================
// 三条铁律（与 P0 交接文档「同步铁律」一致，改动前先读）：
//   1. 本地 SQLite 是唯一真相源；仓储层只读写本地库，不做任何网络动作。
//   2. 所有**同步表**的写操作必须经 OplogWriter 落账本，业务写入与 oplog 同事务；
//      派生表（habit_score / sync_state / snapshot_meta）只能走 writeLocal。
//   3. 删除一律软删（写 deleted_at 墓碑），**绝不物理删除**，否则对端无法收敛。
//
// 另一条容易被破坏的约束（P1-6 验收标准）：
//   「删除回填行不影响习惯记录」—— plan_item 的墓碑与 habit_checkin 是两张表，
//   本文件里没有任何一处会因为删 plan_item 而去改 habit_checkin。
// =============================================================================

// `hide Todo`：`core_db` 的表类 `Todo` 与 `core_domain` 的实体 `Todo` 同名。
// 本文件对外返回的是**领域实体**（UI 只认 core_domain 的类型），
// 表类只在 `_db.todo` / `$TodoTable` / `TodoData` / `TodoCompanion` 这些位置出现。
import 'package:core_db/core_db.dart' hide Todo, nowMillis;
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'mood.dart';
import 'models.dart';
import 'priority.dart';
import 'recurring.dart';
import 'support.dart';

/// 日志模式：完整版。
const String dayModeFull = 'full';

/// 日志模式：极简版。
const String dayModeMinimal = 'minimal';

/// 合法的日志模式集合（与 `day_log_mode_check` 约束一致）。
const Set<String> dayModes = <String>{dayModeFull, dayModeMinimal};

/// 设置键：优先级显示模式（`quadrant` / `abc`）。
const String settingsKeyPriorityDisplayMode = 'priority_display_mode';

/// 设置键：完整/极简模式的全局默认值。
const String settingsKeyDefaultDayMode = 'default_day_mode';

void _requireCalendarDate(String date, [String name = 'date']) {
  if (parseIsoDate(date) == null) {
    throw ArgumentError.value(date, name, '必须是合法的 YYYY-MM-DD 日历日');
  }
}

/// 每日日志仓储。
///
/// 一天一行（`day_log_date_unique`），由 [ensureByDate] 幂等创建。
final class DayLogRepository {
  /// 创建仓储。
  DayLogRepository(this._db, this._oplog);

  final ActLogDatabase _db;
  final OplogWriter _oplog;

  /// 读取指定日期的日志；不存在或已墓碑时返回 null。
  Future<DayLogData?> findByDate(String date) {
    _requireCalendarDate(date);
    return (_db.select(_db.dayLog)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// 列出日期区间内的每日日志（含两端，按日期升序）。
  Future<List<DayLogData>> listRange(String startDate, String endDate) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return (_db.select(_db.dayLog)
          ..where(
            (t) =>
                t.date.isBetweenValues(startDate, endDate) &
                t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($DayLogTable)>[
            (t) => OrderingTerm(expression: t.date),
          ]))
        .get();
  }

  /// 订阅指定日期的日志变化。
  Stream<DayLogData?> watchByDate(String date) {
    _requireCalendarDate(date);
    return (_db.select(_db.dayLog)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  /// 取回指定日期的日志，不存在则创建（幂等）。
  ///
  /// 创建时 [mode] 只能是 [dayModeFull] 或 [dayModeMinimal]；
  /// 已存在则**不覆盖**它的 mode —— 切换模式请用 [setMode]。
  Future<DayLogData> ensureByDate(
    String date, {
    String mode = dayModeFull,
  }) async {
    _requireCalendarDate(date);
    if (!dayModes.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', '必须是 full 或 minimal');
    }
    final existing = await findByDate(date);
    if (existing != null) {
      return existing;
    }

    final id = uuidV7();
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();
    await _oplog.writeWithOplog<void>(
      table: 'day_log',
      id: id,
      changedFields: <String, Object?>{'date': date, 'mode': mode},
      write: () => _db.into(_db.dayLog).insert(
        DayLogCompanion.insert(
          id: id,
          date: date,
          mode: Value(mode),
          createdAt: ts,
          updatedAt: ts,
          originDeviceId: deviceId,
        ),
      ),
    );

    final created = await findByDate(date);
    if (created == null) {
      throw StateError('day_log $date 创建后仍读不到，检查是否有并发墓碑');
    }
    return created;
  }

  /// 切换完整/极简模式。
  ///
  /// 只改 `mode` 一列 —— 极简模式隐藏的字段**原样留在库里**，
  /// 这是「极简隐藏字段不丢数据」的实现方式。
  Future<void> setMode(String id, String mode) {
    if (!dayModes.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', '必须是 full 或 minimal');
    }
    return _patch(
      id,
      changedFields: <String, Object?>{'mode': mode},
      build: (deviceId, ts, rev) => DayLogCompanion(
        mode: Value(mode),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 写入复盘五段 + 学习收获。
  Future<void> saveReview(String id, ReviewDraft draft) {
    return _patch(
      id,
      changedFields: <String, Object?>{
        'learning': draft.learning,
        'good': draft.good,
        'improve': draft.improve,
        'controllable': draft.controllable,
        'uncontrollable': draft.uncontrollable,
        'next_action': draft.nextAction,
      },
      build: (deviceId, ts, rev) => DayLogCompanion(
        learning: Value(draft.learning),
        good: Value(draft.good),
        improve: Value(draft.improve),
        controllable: Value(draft.controllable),
        uncontrollable: Value(draft.uncontrollable),
        nextAction: Value(draft.nextAction),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 写入心态 8 维 + 失守标记 + 情绪备注。
  ///
  /// 失守标记经 [MoodRules.resolveFailed] 归一：任一维度为 0 时**强制为真**，
  /// 即使 [MoodSummary.failed] 传 false 也落 true。
  Future<void> saveMood(String id, MoodSummary summary) {
    final columns = MoodRules.toColumns(summary.scores);
    final failed = MoodRules.resolveFailed(
      scores: summary.scores,
      requested: summary.failed,
    );
    final changed = <String, Object?>{
      ...columns,
      'mood_failed': failed ? 1 : 0,
      'mood_note': summary.note,
    };

    return _patch(
      id,
      changedFields: changed,
      build: (deviceId, ts, rev) => DayLogCompanion(
        mood1: Value(columns[MoodDimension.diligent.column]),
        mood2: Value(columns[MoodDimension.fast.column]),
        mood3: Value(columns[MoodDimension.keepPromise.column]),
        mood4: Value(columns[MoodDimension.finishTask.column]),
        mood5: Value(columns[MoodDimension.optimistic.column]),
        mood6: Value(columns[MoodDimension.confident.column]),
        mood7: Value(columns[MoodDimension.loveAndDedication.column]),
        mood8: Value(columns[MoodDimension.noExcuses.column]),
        moodFailed: Value(failed ? 1 : 0),
        moodNote: Value(summary.note),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 读取 [id] 当前的心态总览。
  Future<MoodSummary?> moodOf(String id) async {
    final row = await _rowOf(id);
    if (row == null) {
      return null;
    }
    return MoodSummary(
      scores: MoodRules.fromColumns(<String, int?>{
        MoodDimension.diligent.column: row.mood1,
        MoodDimension.fast.column: row.mood2,
        MoodDimension.keepPromise.column: row.mood3,
        MoodDimension.finishTask.column: row.mood4,
        MoodDimension.optimistic.column: row.mood5,
        MoodDimension.confident.column: row.mood6,
        MoodDimension.loveAndDedication.column: row.mood7,
        MoodDimension.noExcuses.column: row.mood8,
      }),
      failed: row.moodFailed == 1,
      note: row.moodNote,
    );
  }

  Future<DayLogData?> _rowOf(String id) {
    return (_db.select(_db.dayLog)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _patch(
    String id, {
    required Map<String, Object?> changedFields,
    required DayLogCompanion Function(String deviceId, int ts, int rev) build,
  }) async {
    final deviceId = await _oplog.resolveDeviceId();
    final ts = nowMillis();
    await _oplog.writeWithOplog<void>(
      table: 'day_log',
      id: id,
      changedFields: changedFields,
      write: () async {
        final row = await _rowOf(id);
        if (row == null) {
          throw StateError('day_log $id 不存在，先调用 ensureByDate');
        }
        await (_db.update(_db.dayLog)..where((t) => t.id.equals(id)))
            .write(build(deviceId, ts, row.rev + 1));
      },
    );
  }
}

/// 计划条目仓储。
final class PlanItemRepository {
  /// 创建仓储。
  PlanItemRepository(this._db, this._oplog);

  final ActLogDatabase _db;
  final OplogWriter _oplog;

  /// 列出某天未删除的计划条目（按创建顺序）。
  Future<List<PlanItemData>> listByDate(String date) {
    _requireCalendarDate(date);
    return _query(date).get();
  }

  /// 列出日期区间内的计划条目（含两端，按日期 + 创建时间排序）。
  ///
  /// 走 `idx_plan_item_date_status`，供月历**一次**取 42 天，禁止按格子 N+1。
  Future<List<PlanItemData>> listRange(String startDate, String endDate) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return (_db.select(_db.planItem)
          ..where(
            (t) =>
                t.date.isBetweenValues(startDate, endDate) &
                t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($PlanItemTable)>[
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }

  /// 订阅某天的计划条目。
  Stream<List<PlanItemData>> watchByDate(String date) {
    _requireCalendarDate(date);
    return _query(date).watch();
  }

  SimpleSelectStatement<$PlanItemTable, PlanItemData> _query(String date) {
    return _db.select(_db.planItem)
      ..where((t) => t.date.equals(date) & t.deletedAt.isNull())
      ..orderBy(<OrderingTerm Function($PlanItemTable)>[
        (t) => OrderingTerm(expression: t.createdAt),
        (t) => OrderingTerm(expression: t.id),
      ]);
  }

  /// 新建普通计划条目。
  Future<String> create({
    required String date,
    required String title,
    String detail = '',
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
    String domain = '',
    int? estMinutes,
    String sourceType = 'manual',
    String? sourceId,
    String? sourceTodoId,
    String? id,
  }) async {
    _requireCalendarDate(date);
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', '标题不能为空');
    }
    if (estMinutes != null && (estMinutes < 0 || estMinutes > 1440)) {
      throw ArgumentError.value(estMinutes, 'estMinutes', '预估分钟数必须在 0..1440');
    }
    return _insert(
      id: id ?? uuidV7(),
      date: date,
      title: title.trim(),
      detail: detail,
      quadrant: quadrant?.code,
      priorityAbc: priorityAbc?.code,
      domain: domain,
      estMinutes: estMinutes,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceTodoId: sourceTodoId,
      isHabitRef: 0,
    );
  }

  /// 由习惯打卡生成的回填行（`source_type='habit'` + `is_habit_ref=1`）。
  ///
  /// 回填行是**独立的 plan_item 行**，与 habit_checkin 没有外键关系 ——
  /// 因此删除它不会影响任何习惯记录。
  Future<String> createHabitRef({
    required String date,
    required String habitId,
    required String title,
  }) {
    return _insert(
      id: uuidV7(),
      date: date,
      title: title,
      detail: '',
      quadrant: null,
      priorityAbc: null,
      domain: '',
      estMinutes: null,
      sourceType: 'habit',
      sourceId: habitId,
      sourceTodoId: null,
      isHabitRef: 1,
    );
  }

  /// 由循环任务物化出的**带时段**计划条目。
  ///
  /// 与 [create] 的唯一差别是同时写入 `planned_start` / `planned_end`
  /// （毫秒时间戳，供时间轴定位）。`source_type` 仍取既有值域里的 `manual`
  /// —— 该列的 CHECK 在 v1 已冻结，加第六个取值须重建整表；权威的
  /// 「这条是哪条循环规则生成的」关系记在 `recurring_occurrence.plan_item_id`。
  Future<String> createScheduled({
    required String date,
    required String title,
    String detail = '',
    required int plannedStart,
    required int plannedEnd,
    int? estMinutes,
    String? sourceId,
    String sourceType = 'manual',
    String? id,
  }) {
    _requireCalendarDate(date);
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', '标题不能为空');
    }
    if (plannedEnd < plannedStart) {
      throw ArgumentError.value(plannedEnd, 'plannedEnd', '结束时刻不能早于开始时刻');
    }
    return _insert(
      id: id ?? uuidV7(),
      date: date,
      title: title.trim(),
      detail: detail,
      quadrant: null,
      priorityAbc: null,
      domain: '',
      estMinutes: estMinutes,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceTodoId: null,
      isHabitRef: 0,
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
    );
  }

  Future<String> _insert({
    required String id,
    required String date,
    required String title,
    required String detail,
    required String? quadrant,
    required String? priorityAbc,
    required String domain,
    required int? estMinutes,
    required String sourceType,
    required String? sourceId,
    required String? sourceTodoId,
    required int isHabitRef,
    int? plannedStart,
    int? plannedEnd,
  }) async {
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();
    await _oplog.writeWithOplog<void>(
      table: 'plan_item',
      id: id,
      changedFields: <String, Object?>{'date': date, 'title': title},
      write: () => _db.into(_db.planItem).insert(
        PlanItemCompanion.insert(
          id: id,
          date: date,
          title: title,
          detail: Value(detail),
          sourceType: Value(sourceType),
          sourceId: Value(sourceId),
          sourceTodoId: Value(sourceTodoId),
          quadrant: Value(quadrant),
          priorityAbc: Value(priorityAbc),
          domain: Value(domain),
          estMinutes: Value(estMinutes),
          isHabitRef: Value(isHabitRef),
          plannedStart: Value(plannedStart),
          plannedEnd: Value(plannedEnd),
          createdAt: ts,
          updatedAt: ts,
          originDeviceId: deviceId,
        ),
      ),
    );
    return id;
  }

  /// 设置四象限（传 null 表示取消分级）。
  Future<void> setQuadrant(String id, Quadrant? quadrant) {
    return _patch(
      id,
      changedFields: <String, Object?>{'quadrant': quadrant?.code},
      build: (deviceId, ts, rev) => PlanItemCompanion(
        quadrant: Value(quadrant?.code),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 设置 ABC 优先级（传 null 表示取消分级）。
  ///
  /// 只改 `priority_abc` 一列，**不碰 quadrant** —— 两种分级各自独立存储，
  /// 这是「两种模式互斥且切换无损」的前提。
  Future<void> setPriorityAbc(String id, PriorityAbc? priorityAbc) {
    return _patch(
      id,
      changedFields: <String, Object?>{'priority_abc': priorityAbc?.code},
      build: (deviceId, ts, rev) => PlanItemCompanion(
        priorityAbc: Value(priorityAbc?.code),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 流转状态；置为 `done` 时同时写 `done_at`。
  Future<void> setStatus(String id, PlanStatus status, {String? resultNote}) {
    final ts = nowMillis();
    final done = status == PlanStatus.done;
    return _patch(
      id,
      changedFields: <String, Object?>{
        'status': status.code,
        'result_note': ?resultNote,
      },
      build: (deviceId, at, rev) => PlanItemCompanion(
        status: Value(status.code),
        doneAt: Value(done ? at : null),
        resultNote: resultNote == null ? const Value.absent() : Value(resultNote),
        updatedAt: Value(at),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
      nowOverride: ts,
    );
  }

  /// 回填成果 / 进展（P1-6）。
  Future<void> setResultNote(String id, String note) {
    return _patch(
      id,
      changedFields: <String, Object?>{'result_note': note},
      build: (deviceId, ts, rev) => PlanItemCompanion(
        resultNote: Value(note),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 把习惯回填行「转正」为普通手动条目。
  ///
  /// 转正只改来源字段，条目本身（标题、状态、成果）保持不变。
  Future<void> promote(String id) {
    return _patch(
      id,
      changedFields: <String, Object?>{
        'source_type': 'manual',
        'source_id': null,
        'is_habit_ref': 0,
      },
      build: (deviceId, ts, rev) => PlanItemCompanion(
        sourceType: const Value('manual'),
        sourceId: const Value<String?>(null),
        isHabitRef: const Value(0),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 顺延到另一天（保留原条目，只改 date）。
  Future<void> moveToDate(String id, String date) {
    _requireCalendarDate(date);
    return _patch(
      id,
      changedFields: <String, Object?>{'date': date},
      build: (deviceId, ts, rev) => PlanItemCompanion(
        date: Value(date),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 软删除（写墓碑）。**不会触碰 habit_checkin。**
  Future<void> softDelete(String id) async {
    final deviceId = await _oplog.resolveDeviceId();
    final ts = nowMillis();
    await _oplog.writeWithOplog<void>(
      table: 'plan_item',
      id: id,
      isDelete: true,
      deletedAt: ts,
      write: () async {
        final row = await _rowOf(id);
        if (row == null) {
          return;
        }
        await (_db.update(_db.planItem)..where((t) => t.id.equals(id))).write(
          PlanItemCompanion(
            deletedAt: Value(ts),
            updatedAt: Value(ts),
            originDeviceId: Value(deviceId),
            rev: Value(row.rev + 1),
          ),
        );
      },
    );
  }

  Future<PlanItemData?> _rowOf(String id) {
    return (_db.select(_db.planItem)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _patch(
    String id, {
    required Map<String, Object?> changedFields,
    required PlanItemCompanion Function(String deviceId, int ts, int rev) build,
    int? nowOverride,
  }) async {
    final deviceId = await _oplog.resolveDeviceId();
    final ts = nowOverride ?? nowMillis();
    await _oplog.writeWithOplog<void>(
      table: 'plan_item',
      id: id,
      changedFields: changedFields,
      write: () async {
        final row = await _rowOf(id);
        if (row == null) {
          throw StateError('plan_item $id 不存在');
        }
        await (_db.update(_db.planItem)..where((t) => t.id.equals(id)))
            .write(build(deviceId, ts, row.rev + 1));
      },
    );
  }
}

/// 待办池仓储。
///
/// 「从待办池捞进计划」是**引用 + 快照**模型：新建的 `plan_item` 行用
/// `source_type='todo'` + `source_todo_id` 指向待办，同时把待办的
/// `title` / `detail` / `est_minutes` / `quadrant` / `priority_abc`
/// **快照**过去 —— 之后改待办或删除待办都不会回头改写这一天的历史计划。
///
/// 捞取是**原子操作**：建计划行与把待办置为 `done` 在同一个事务里，
/// 任一步失败都不会留下「计划里多了一条、待办却还挂在池子里」的半截状态。
final class TodoRepository {
  /// 创建仓储。
  TodoRepository(this._db, this._oplog);

  final ActLogDatabase _db;
  final OplogWriter _oplog;

  /// 列出待办池里**未完成**的待办（`deleted_at IS NULL` 且 `status='open'`）。
  ///
  /// 按 `created_at` 升序（再按 id 破平局，保证顺序稳定）—— 池子里的老条目
  /// 排在上面，符合「先清旧的」的使用习惯。
  Future<List<Todo>> listOpen() async {
    final rows = await (_db.select(_db.todo)
          ..where(
            (t) => t.status.equals(TodoStatus.open.code) & t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($TodoTable)>[
            (t) => OrderingTerm(expression: t.createdAt),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
    return rows.map(_toEntity).toList(growable: false);
  }

  /// 在待办池里新建一条待办，返回新的 `todo.id`。
  ///
  /// 字段口径照抄 `todo` 表 schema：只有 [title] 必填，其余参数留 `null`
  /// 表示「未填」（列存 NULL，与数据库语义一致，不写空串占位）。
  ///
  /// 写入走 `OplogWriter`（`uuidV7()` + `nowMillis()` + 本机 `deviceId`），
  /// 与 [pullToPlan] 同一套规矩 —— 裸 `db.execute` 会让同步侧看不到这条记录。
  ///
  /// 标题去空白后为空时抛 [ArgumentError]，**不留下任何写入**。
  ///
  /// [status] 留 `null` 表示「按默认 `open`」—— 默认值必须在函数体内取，
  /// 因为 `TodoStatus.open.code` 不是编译期常量，不能写进形参默认值。
  Future<String> create({
    required String title,
    String detail = '',
    int? estMinutes,
    String? dueDate,
    String? projectId,
    String? quadrant,
    String? priorityAbc,
    String? status,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', '待办标题不能为空');
    }
    if (dueDate != null) {
      _requireCalendarDate(dueDate, 'dueDate');
    }
    final resolvedStatus = status ?? TodoStatus.open.code;

    final id = uuidV7();
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();

    await _oplog.writeWithOplog<void>(
      table: 'todo',
      id: id,
      changedFields: <String, Object?>{
        'title': trimmed,
        'status': resolvedStatus,
      },
      write: () => _db
          .into(_db.todo)
          .insert(
            TodoCompanion.insert(
              id: id,
              title: trimmed,
              detail: Value(detail),
              estMinutes: Value(estMinutes),
              dueDate: Value(dueDate),
              projectId: Value(projectId),
              quadrant: Value(quadrant),
              priorityAbc: Value(priorityAbc),
              status: Value(resolvedStatus),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );

    return id;
  }

  /// 把待办 [todoId] 捞进 [date] 当天的计划，返回**新建的 `plan_item` id**。
  ///
  /// 写入的列：
  /// - 引用：`source_type='todo'`、`source_todo_id=<todo.id>`、
  ///   `source_id=<todo.id>`（`source_id` 就是 `source_todo_id`，不另起一套指针）；
  /// - 快照：`title` / `detail` / `est_minutes` / `quadrant` / `priority_abc`；
  /// - 其余按 `PlanItem` 默认：`domain=''`、`status='pending'`、`is_habit_ref=0`。
  ///
  /// 随后把该待办置为 `done` 并写 `completed_at`（同一个事务）。
  ///
  /// 错误约定与 `PlanItemRepository` 一致（`StateError`）：待办不存在、已软删、
  /// 或状态不是 `open` 时抛出，且**不留下任何写入**。
  Future<String> pullToPlan(String todoId, String date) async {
    _requireCalendarDate(date);
    final row = await _rowOf(todoId);
    if (row == null) {
      throw StateError('todo $todoId 不存在');
    }
    if (row.deletedAt != null) {
      throw StateError('todo $todoId 已删除，不能再捞进计划');
    }
    if (row.status != TodoStatus.open.code) {
      throw StateError('todo $todoId 状态是 ${row.status}，只有 open 才能捞进计划');
    }

    final planItemId = uuidV7();
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();

    await _db.transaction(() async {
      await _oplog.writeWithOplog<void>(
        table: 'plan_item',
        id: planItemId,
        changedFields: <String, Object?>{
          'date': date,
          'title': row.title,
          'source_type': PlanSourceType.todo.code,
          'source_todo_id': row.id,
        },
        write: () => _db.into(_db.planItem).insert(
          PlanItemCompanion.insert(
            id: planItemId,
            date: date,
            title: row.title,
            detail: Value(row.detail),
            sourceType: Value(PlanSourceType.todo.code),
            sourceId: Value<String?>(row.id),
            sourceTodoId: Value<String?>(row.id),
            quadrant: Value(row.quadrant),
            priorityAbc: Value(row.priorityAbc),
            domain: const Value(''),
            estMinutes: Value(row.estMinutes),
            isHabitRef: const Value(0),
            createdAt: ts,
            updatedAt: ts,
            originDeviceId: deviceId,
          ),
        ),
      );

      await _oplog.writeWithOplog<void>(
        table: 'todo',
        id: row.id,
        changedFields: <String, Object?>{
          'status': TodoStatus.done.code,
          'completed_at': ts,
        },
        write: () =>
            (_db.update(_db.todo)..where((t) => t.id.equals(row.id))).write(
          TodoCompanion(
            status: Value(TodoStatus.done.code),
            completedAt: Value(ts),
            updatedAt: Value(ts),
            originDeviceId: Value(deviceId),
            rev: Value(row.rev + 1),
          ),
        ),
      );
    });

    return planItemId;
  }

  /// 读一行待办（**包含墓碑**，用于区分「不存在」与「已删除」）。
  Future<TodoData?> _rowOf(String id) {
    return (_db.select(_db.todo)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// drift 数据行 → 领域实体。
  ///
  /// 无法识别的枚举值按「解析层不崩溃」的约定回落（`quadrant` / `priorityAbc`
  /// 回落 null，`status` 回落 open），与 `enums.dart` 的 `fromCode` 一致。
  Todo _toEntity(TodoData row) {
    return Todo(
      id: row.id,
      title: row.title,
      detail: row.detail,
      estMinutes: row.estMinutes,
      dueDate: row.dueDate,
      projectId: row.projectId,
      quadrant: Quadrant.fromCode(row.quadrant),
      priorityAbc: PriorityAbc.fromCode(row.priorityAbc),
      status: TodoStatus.fromCode(row.status) ?? TodoStatus.open,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      originDeviceId: row.originDeviceId,
      rev: row.rev,
    );
  }
}

/// 习惯与打卡仓储。
final class HabitRepository {
  /// 创建仓储。
  HabitRepository(this._db, this._oplog);

  final ActLogDatabase _db;
  final OplogWriter _oplog;

  /// 列出未归档的习惯。
  Future<List<HabitData>> listActive() {
    return (_db.select(_db.habit)
          ..where((t) => t.archived.equals(0) & t.deletedAt.isNull())
          ..orderBy(<OrderingTerm Function($HabitTable)>[
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }

  /// 列出某天应当出现的习惯（按排程过滤）。
  Future<List<HabitData>> listScheduledFor(String date) async {
    _requireCalendarDate(date);
    final all = await listActive();
    return all
        .where((h) => isScheduledFor(h, date) && h.startDate.compareTo(date) <= 0)
        .toList(growable: false);
  }

  /// 列出日期区间内的习惯打卡记录（含两端，按日期 + 创建时间升序）。
  Future<List<HabitCheckinData>> listCheckinsRange(
    String startDate,
    String endDate,
  ) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return (_db.select(_db.habitCheckin)
          ..where(
            (t) =>
                t.date.isBetweenValues(startDate, endDate) &
                t.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($HabitCheckinTable)>[
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }

  /// 判断习惯是否在 [date] 有排程。
  ///
  /// - `daily`：每天；
  /// - `weekdays`：`weekdays` 列存 '1,3,5'（1=周一 … 7=周日）；
  /// - `weekly_n`：每周 N 次，没有固定日，因此每天都会出现，由用户自己挑日子。
  static bool isScheduledFor(HabitData habit, String date) {
    switch (habit.scheduleType) {
      case 'weekdays':
        final parsed = parseIsoDate(date);
        if (parsed == null) {
          return false;
        }
        return habit.weekdays
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .any((n) => n == parsed.weekday);
      case 'weekly_n':
        return true;
      case 'daily':
      default:
        return true;
    }
  }

  /// 订阅某天的全部打卡记录。
  Stream<List<HabitCheckinData>> watchCheckinsByDate(String date) {
    _requireCalendarDate(date);
    return (_db.select(_db.habitCheckin)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull())
          ..orderBy(<OrderingTerm Function($HabitCheckinTable)>[
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  /// 读取某习惯某天的打卡记录。
  Future<HabitCheckinData?> findCheckin(String habitId, String date) {
    _requireCalendarDate(date);
    return (_db.select(_db.habitCheckin)
          ..where(
            (t) =>
                t.habitId.equals(habitId) &
                t.date.equals(date) &
                t.deletedAt.isNull(),
          ))
        .getSingleOrNull();
  }

  /// 读取某习惯某天的打卡行，**包含墓碑**。
  ///
  /// 与 [findCheckin] 的唯一区别是不看 `deleted_at`。`habit_checkin_pair_unique`
  /// 是 UNIQUE (habit_id, date) 且不带部分索引条件 —— 墓碑仍然占着这个槽位，
  /// 所以「撤销后再打卡」必须复用同一行，不能新插一行。
  Future<HabitCheckinData?> _checkinRow(String habitId, String date) {
    return (_db.select(_db.habitCheckin)
          ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
        .getSingleOrNull();
  }

  /// 新建习惯。
  Future<String> create({
    required String name,
    String description = '',
    String type = 'normal',
    double? targetCount,
    String targetUnit = '',
    String scheduleType = 'daily',
    int? weeklyN,
    String weekdays = '',
    String domain = '',
    String? startDate,
    String? id,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '习惯名不能为空');
    }
    final start = startDate ?? today();
    _requireCalendarDate(start, 'startDate');
    final habitId = id ?? uuidV7();
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();
    await _oplog.writeWithOplog<void>(
      table: 'habit',
      id: habitId,
      changedFields: <String, Object?>{'name': name.trim(), 'start_date': start},
      write: () => _db.into(_db.habit).insert(
        HabitCompanion.insert(
          id: habitId,
          name: name.trim(),
          description: Value(description),
          type: Value(type),
          targetCount: Value(targetCount),
          targetUnit: Value(targetUnit),
          scheduleType: Value(scheduleType),
          weeklyN: Value(weeklyN),
          weekdays: Value(weekdays),
          domain: Value(domain),
          startDate: start,
          createdAt: ts,
          updatedAt: ts,
          originDeviceId: deviceId,
        ),
      ),
    );
    return habitId;
  }

  /// 归档（不删除历史打卡）。
  Future<void> archive(String id) {
    return _patchHabit(
      id,
      changedFields: <String, Object?>{'archived': 1},
      build: (deviceId, ts, rev) => HabitCompanion(
        archived: const Value(1),
        updatedAt: Value(ts),
        originDeviceId: Value(deviceId),
        rev: Value(rev),
      ),
    );
  }

  /// 记录一次打卡（同一习惯同一天只有一行，重复调用即更新）。
  ///
  /// [status] 为 `failed` 时打断连击；`skip` 不打断（见 `CheckinStatus`）。
  Future<String> upsertCheckin({
    required String habitId,
    required String date,
    CheckinStatus status = CheckinStatus.done,
    double value = 1,
    String note = '',
  }) async {
    _requireCalendarDate(date);
    // 注意：这里查的是**含墓碑**的行，不是 findCheckin。
    // schema 里 habit_checkin_pair_unique 是 UNIQUE (habit_id, date)，
    // 不带 `WHERE deleted_at IS NULL` 的部分索引 —— 撤销打卡后墓碑仍占着这个槽位，
    // 若按 findCheckin（过滤墓碑）判定「不存在」再插入，会撞唯一约束。
    // 正确做法与 SettingsRepository.set 一致：命中墓碑就更新它、清掉 deleted_at，
    // 让同一行复活，行 id 也保持稳定（对端同步时是 update 而不是 delete+insert）。
    final existing = await _checkinRow(habitId, date);
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();

    if (existing == null) {
      final checkinId = uuidV7();
      await _oplog.writeWithOplog<void>(
        table: 'habit_checkin',
        id: checkinId,
        changedFields: <String, Object?>{
          'habit_id': habitId,
          'date': date,
          'status': status.code,
          'value': value,
        },
        write: () => _db.into(_db.habitCheckin).insert(
          HabitCheckinCompanion.insert(
            id: checkinId,
            habitId: habitId,
            date: date,
            value: Value(value),
            status: Value(status.code),
            note: Value(note),
            createdAt: ts,
            updatedAt: ts,
            originDeviceId: deviceId,
          ),
        ),
      );
      return checkinId;
    }

    await _oplog.writeWithOplog<void>(
      table: 'habit_checkin',
      id: existing.id,
      changedFields: <String, Object?>{
        'status': status.code,
        'value': value,
        'note': note,
      },
      write: () => (_db.update(_db.habitCheckin)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        HabitCheckinCompanion(
          value: Value(value),
          status: Value(status.code),
          note: Value(note),
          deletedAt: const Value<int?>(null),
          updatedAt: Value(ts),
          originDeviceId: Value(deviceId),
          rev: Value(existing.rev + 1),
        ),
      ),
    );
    return existing.id;
  }

  /// 撤销某天的打卡（软删墓碑，保留审计痕迹）。
  Future<void> deleteCheckin(String checkinId) async {
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();
    await _oplog.writeWithOplog<void>(
      table: 'habit_checkin',
      id: checkinId,
      isDelete: true,
      deletedAt: ts,
      write: () async {
        final row = await (_db.select(_db.habitCheckin)
              ..where((t) => t.id.equals(checkinId)))
            .getSingleOrNull();
        if (row == null) {
          return;
        }
        await (_db.update(_db.habitCheckin)
              ..where((t) => t.id.equals(checkinId)))
            .write(
          HabitCheckinCompanion(
            deletedAt: Value(ts),
            updatedAt: Value(ts),
            originDeviceId: Value(deviceId),
            rev: Value(row.rev + 1),
          ),
        );
      },
    );
  }

  Future<void> _patchHabit(
    String id, {
    required Map<String, Object?> changedFields,
    required HabitCompanion Function(String deviceId, int ts, int rev) build,
  }) async {
    final deviceId = await _oplog.resolveDeviceId();
    final ts = nowMillis();
    await _oplog.writeWithOplog<void>(
      table: 'habit',
      id: id,
      changedFields: changedFields,
      write: () async {
        final row = await (_db.select(_db.habit)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (row == null) {
          throw StateError('habit $id 不存在');
        }
        await (_db.update(_db.habit)..where((t) => t.id.equals(id)))
            .write(build(deviceId, ts, row.rev + 1));
      },
    );
  }
}

/// 键值设置仓储（`settings` 表是同步表，因此写操作同样落账本）。
final class SettingsRepository {
  /// 创建仓储。
  SettingsRepository(this._db, this._oplog);

  final ActLogDatabase _db;
  final OplogWriter _oplog;

  /// 读一个配置值；不存在返回 null。
  Future<String?> get(String key) async {
    final row = await _rowOf(key);
    if (row == null || row.deletedAt != null) {
      return null;
    }
    return row.value;
  }

  /// 写一个配置值（不存在则插入，存在则更新）。
  Future<void> set(String key, String value) async {
    final existing = await _rowOf(key);
    final ts = nowMillis();
    final deviceId = await _oplog.resolveDeviceId();

    if (existing == null) {
      final id = uuidV7();
      await _oplog.writeWithOplog<void>(
        table: 'settings',
        id: id,
        changedFields: <String, Object?>{'key': key, 'value': value},
        write: () => _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            id: id,
            key: key,
            value: Value(value),
            createdAt: ts,
            updatedAt: ts,
            originDeviceId: deviceId,
          ),
        ),
      );
      return;
    }

    await _oplog.writeWithOplog<void>(
      table: 'settings',
      id: existing.id,
      changedFields: <String, Object?>{'key': key, 'value': value},
      write: () => (_db.update(_db.settings)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        SettingsCompanion(
          value: Value(value),
          deletedAt: const Value<int?>(null),
          updatedAt: Value(ts),
          originDeviceId: Value(deviceId),
          rev: Value(existing.rev + 1),
        ),
      ),
    );
  }

  /// 读取优先级显示模式；未设置时回落到四象限。
  Future<PriorityDisplayMode> priorityDisplayMode() async {
    final raw = await get(settingsKeyPriorityDisplayMode);
    return PriorityDisplayMode.fromCode(raw ?? '') ?? PriorityDisplayMode.quadrant;
  }

  /// 保存优先级显示模式。
  Future<void> setPriorityDisplayMode(PriorityDisplayMode mode) =>
      set(settingsKeyPriorityDisplayMode, mode.code);

  /// 读一行设置。
  ///
  /// 这里刻意不写出 drift 生成的数据类名（`Settings` 会被 drift 单数化），
  /// 改用记录类型只取需要的字段 —— 表名一变，这里的编译错误就在本地。
  Future<({String id, String value, int rev, int? deletedAt})?> _rowOf(
    String key,
  ) async {
    final row = await (_db.select(_db.settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (
      id: row.id,
      value: row.value,
      rev: row.rev,
      deletedAt: row.deletedAt,
    );
  }
}

/// 按当前显示模式排序计划条目。
///
/// 已收口（`done` / `cancelled`）的条目一律沉底 —— 它们不该挤掉今天还要做的事。
/// 同一权重下按创建时刻、再按 ID 排，保证顺序稳定。
List<PlanItemData> sortPlanItemsForDisplay(
  List<PlanItemData> items,
  PriorityDisplayMode mode,
) {
  bool closed(PlanItemData item) =>
      item.status == PlanStatus.done.code ||
      item.status == PlanStatus.cancelled.code;

  int weight(PlanItemData item) => PriorityDisplay.sortWeight(
        mode,
        quadrant: Quadrant.fromCode(item.quadrant ?? ''),
        priorityAbc: PriorityAbc.fromCode(item.priorityAbc ?? ''),
      );

  final sorted = List<PlanItemData>.of(items);
  sorted.sort((a, b) {
    final aClosed = closed(a);
    final bClosed = closed(b);
    if (aClosed != bClosed) {
      return aClosed ? 1 : -1;
    }
    final byWeight = weight(a).compareTo(weight(b));
    if (byWeight != 0) {
      return byWeight;
    }
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) {
      return byCreated;
    }
    return a.id.compareTo(b.id);
  });
  return sorted;
}

/// 一个数据库句柄上的全部仓储。
final class ActLogRepositories {
  /// 创建仓储集合。
  ActLogRepositories(this.db, {String? deviceId, this.clock})
      : oplog = OplogWriter(db, deviceId: deviceId) {
    dayLog = DayLogRepository(db, oplog);
    planItem = PlanItemRepository(db, oplog);
    todo = TodoRepository(db, oplog);
    habit = HabitRepository(db, oplog);
    settings = SettingsRepository(db, oplog);
    recurring = RecurringTaskRepository(db, oplog, planItem);
  }

  /// 数据库句柄。
  final ActLogDatabase db;

  /// 账本写入器。
  final OplogWriter oplog;

  /// 可注入的时钟（测试用）。
  final DateTime Function()? clock;

  /// 每日日志仓储。
  late final DayLogRepository dayLog;

  /// 计划条目仓储。
  late final PlanItemRepository planItem;

  /// 待办池仓储。
  late final TodoRepository todo;

  /// 习惯仓储。
  late final HabitRepository habit;

  /// 设置仓储。
  late final SettingsRepository settings;

  /// 循环任务仓储（schema v2）。
  late final RecurringTaskRepository recurring;
}