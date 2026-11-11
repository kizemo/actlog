// =============================================================================
// core_data · 循环任务仓储（schema v2）
// =============================================================================
// 职责：
//   1. 维护循环任务规则（`recurring_task`）；
//   2. 把规则**幂等**物化成某一天的计划条目（`recurring_occurrence` + plan_item）。
//
// 幂等性怎么保证（两层，缺一不可）：
//   · 应用层：物化前在同一个事务里查一次 `(task_id, date)` 是否已存在；
//   · 库层：`recurring_occurrence_task_date_unique` 唯一约束兜底。
//   只有库层算数 —— 事务内的「先查后写」在 SQLite 里已经串行化，但唯一约束
//   才是并发/重入下不会多出两行计划条目的**证明**。
//
// 同步：两张表都已纳入 oplog 白名单（`syncedTables`，共 12 张），规则与实例
//   都进账本。物化时 occurrence 走单次 `writeWithOplog`（table=`recurring_occurrence`），
//   `plan_item` 的落痕由 `PlanItemRepository.createScheduled` 自己负责 ——
//   一行一笔，不双写。
// =============================================================================

import 'package:core_db/core_db.dart' hide nowMillis;
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'repositories.dart';
import 'support.dart';

/// 某一天的循环任务实例 + 它的规则行（右轨面板要同时用到两者）。
final class RecurringOccurrenceView {
  /// 创建视图行。
  const RecurringOccurrenceView({
    required this.task,
    required this.occurrence,
  });

  /// 规则行。
  final RecurringTaskData task;

  /// 实例行（物化凭证）。
  final RecurringOccurrenceData occurrence;

  /// 结束时刻（一天中的第几分钟；越界时收口到 23:59）。
  int get endMinute {
    final end = task.startMinute + task.durationMinutes;
    return end > minutesPerDay - 1 ? minutesPerDay - 1 : end;
  }

  /// 展示用时段文本，例如 `09:00–09:30`。
  String get timeLabel =>
      '${formatMinuteOfDay(task.startMinute)}–${formatMinuteOfDay(endMinute)}';
}

/// 循环任务仓储。
final class RecurringTaskRepository {
  /// 创建仓储。
  ///
  /// 需要 [PlanItemRepository] 是因为物化的产物本身是一条 `plan_item`，
  /// 而 `plan_item` 是**同步表**，写入必须经它走 oplog —— 不能绕过去直插。
  RecurringTaskRepository(this._db, this._oplog, this._planItem);

  final ActLogDatabase _db;
  final OplogWriter _oplog;
  final PlanItemRepository _planItem;

  /// 订阅所有启用中的循环任务（按开始时刻排序）。
  Stream<List<RecurringTaskData>> watchActive() {
    return _activeQuery().watch();
  }

  /// 读取所有启用中的循环任务（按开始时刻排序）。
  Future<List<RecurringTaskData>> listActive() {
    return _activeQuery().get();
  }

  SimpleSelectStatement<$RecurringTaskTable, RecurringTaskData> _activeQuery() {
    return _db.select(_db.recurringTask)
      ..where((t) => t.deletedAt.isNull() & t.active.equals(1))
      ..orderBy(<OrderingTerm Function($RecurringTaskTable)>[
        (t) => OrderingTerm(expression: t.startMinute),
        (t) => OrderingTerm(expression: t.id),
      ]);
  }

  /// 新建一条循环任务规则。
  ///
  /// 校验全部在这里做（而不是只信 UI）：这些值直接进 CHECK 约束，界面与
  /// 仓储各挡一次，才能保证错误是「一句可读的中文」而不是 SQLite 原文。
  Future<String> create({
    required String title,
    required int weekdayMask,
    required int startMinute,
    int durationMinutes = 30,
    String note = '',
    String? id,
  }) async {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', '标题不能为空');
    }
    if (!WeekdayMask.isValid(weekdayMask)) {
      throw ArgumentError.value(weekdayMask, 'weekdayMask', '星期掩码必须在 0..127');
    }
    if (weekdayMask == WeekdayMask.none) {
      throw ArgumentError.value(weekdayMask, 'weekdayMask', '至少要选一个星期');
    }
    if (startMinute < 0 || startMinute >= minutesPerDay) {
      throw ArgumentError.value(
        startMinute,
        'startMinute',
        '起始时刻必须在 0..1439（一天中的第几分钟）',
      );
    }
    if (durationMinutes <= 0 || durationMinutes > minutesPerDay) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        '时长必须在 1..1440 分钟',
      );
    }

    final int ts = nowMillis();
    final String deviceId = await _oplog.resolveDeviceId();
    final String rowId = id ?? uuidV7();
    await _oplog.writeWithOplog<void>(
      table: TableNames.recurringTask,
      id: rowId,
      changedFields: <String, Object?>{
        'title': trimmed,
        'weekday_mask': weekdayMask,
        'start_minute': startMinute,
        'duration_minutes': durationMinutes,
      },
      write: () => _db.into(_db.recurringTask).insert(
        RecurringTaskCompanion.insert(
          id: rowId,
          title: trimmed,
          weekdayMask: weekdayMask,
          startMinute: startMinute,
          durationMinutes: Value(durationMinutes),
          note: Value(note.trim()),
          createdAt: ts,
          updatedAt: ts,
          originDeviceId: deviceId,
        ),
      ),
    );
    return rowId;
  }

  /// 启用 / 停用一条规则。
  ///
  /// 停用只影响**后续**物化：已经生成的实例行与计划条目都保留，
  /// 否则「今天已经排进去的时段」会因为点了停用而从今日计划里消失。
  Future<void> setActive(String id, bool active) {
    return _oplog.writeWithOplog<void>(
      table: TableNames.recurringTask,
      id: id,
      changedFields: <String, Object?>{'active': active ? 1 : 0},
      write: () async {
        final int ts = nowMillis();
        await (_db.update(_db.recurringTask)..where((t) => t.id.equals(id)))
            .write(
              RecurringTaskCompanion(
                active: Value(active ? 1 : 0),
                updatedAt: Value(ts),
              ),
            );
      },
    );
  }

  /// 软删一条规则（写 `deleted_at` 墓碑，绝不物理删除）。
  ///
  /// oplog 按项目统一约定记 `op=delete` + `{"deleted_at": ts}`
  /// （与 `PlanItemRepository.softDelete` 一致）：对端要收敛的是「这行没了」。
  Future<void> archive(String id) async {
    final int ts = nowMillis();
    await _oplog.writeWithOplog<void>(
      table: TableNames.recurringTask,
      id: id,
      isDelete: true,
      deletedAt: ts,
      write: () async {
        await (_db.update(_db.recurringTask)..where((t) => t.id.equals(id)))
            .write(
              RecurringTaskCompanion(
                active: const Value(0),
                deletedAt: Value(ts),
                updatedAt: Value(ts),
              ),
            );
      },
    );
  }

  /// 把某一天该跑的任务物化成计划条目，返回**本次新建**的条数。
  ///
  /// 重复调用安全：已物化过的 `(task_id, date)` 直接跳过，返回 0。
  /// 它**只增不删** —— 停用规则不会撤掉已经生成的条目（见 [setActive]）。
  Future<int> materializeDate(String date) {
    final DateTime? parsed = parseIsoDate(date);
    if (parsed == null) {
      throw ArgumentError.value(date, 'date', '必须是合法的 YYYY-MM-DD 日历日');
    }

    // 外层只给「整天一个事务」的边界，**不**记账：账本由内部逐笔写
    // （plan_item 由 createScheduled 记，occurrence 由 _materializeOne 记）。
    return _oplog.writeLocal<int>(
      write: () async {
        final List<RecurringTaskData> tasks = await listActive();
        var created = 0;
        for (final task in tasks) {
          if (!WeekdayMask.includes(task.weekdayMask, parsed.weekday)) {
            continue;
          }
          // 脏数据防御：CHECK 已挡住越界值，这里再挡一次，避免
          // formatMinuteOfDay / DateTime.add 在运行期抛异常把整天物化搞挂。
          if (task.startMinute < 0 || task.startMinute >= minutesPerDay) {
            continue;
          }
          final bool materialized = await _materializeOne(task, date, parsed);
          if (materialized) {
            created += 1;
          }
        }
        return created;
      },
    );
  }

  /// 物化单条任务；已存在返回 false。
  ///
  /// 顺序刻意是「先查 → 建 plan_item → 写实例行」，三步在同一个事务里：
  /// 任何一步抛异常都会整体回滚，不会留下「实例行在、计划条目不在」的孤儿，
  /// 也不会出现「计划条目在、实例行不在」导致下次重复物化的情况。
  Future<bool> _materializeOne(
    RecurringTaskData task,
    String date,
    DateTime parsed,
  ) async {
    final RecurringOccurrenceData? existing = await (_db.select(
      _db.recurringOccurrence,
    )..where((t) => t.taskId.equals(task.id) & t.date.equals(date)))
        .getSingleOrNull();
    if (existing != null) {
      return false;
    }

    final DateTime dayStart = DateTime(parsed.year, parsed.month, parsed.day);
    final DateTime start = dayStart.add(Duration(minutes: task.startMinute));
    final DateTime end = start.add(Duration(minutes: task.durationMinutes));

    final String planItemId = await _planItem.createScheduled(
      date: date,
      title: task.title,
      detail: task.note,
      plannedStart: start.millisecondsSinceEpoch,
      plannedEnd: end.millisecondsSinceEpoch,
      estMinutes: task.durationMinutes,
      sourceId: task.id,
    );

    final int ts = nowMillis();
    final String deviceId = await _oplog.resolveDeviceId();
    // 单次插入落一笔 oplog。外层 `materializeDate` 的 writeLocal 只提供
    // 「整天一个事务」的边界，本身不记账，因此不会重复落痕。
    final String occurrenceId = uuidV7();
    await _oplog.writeWithOplog<void>(
      table: TableNames.recurringOccurrence,
      id: occurrenceId,
      changedFields: <String, Object?>{
        'task_id': task.id,
        'date': date,
        'plan_item_id': planItemId,
      },
      write: () => _db.into(_db.recurringOccurrence).insert(
        RecurringOccurrenceCompanion.insert(
          id: occurrenceId,
          taskId: task.id,
          date: date,
          planItemId: Value(planItemId),
          createdAt: ts,
          updatedAt: ts,
          originDeviceId: deviceId,
        ),
      ),
    );
    return true;
  }

  /// 订阅某一天的循环任务实例（连同规则行）。
  Stream<List<RecurringOccurrenceView>> watchOccurrencesByDate(String date) {
    return _occurrenceQuery(date).watch().map(_toViews);
  }

  /// 读取某一天的循环任务实例（连同规则行）。
  Future<List<RecurringOccurrenceView>> listOccurrencesByDate(String date) async {
    final List<TypedResult> rows = await _occurrenceQuery(date).get();
    return _toViews(rows);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _occurrenceQuery(String date) {
    if (parseIsoDate(date) == null) {
      throw ArgumentError.value(date, 'date', '必须是合法的 YYYY-MM-DD 日历日');
    }
    return _db.select(_db.recurringOccurrence).join(<Join>[
      innerJoin(
        _db.recurringTask,
        _db.recurringTask.id.equalsExp(_db.recurringOccurrence.taskId),
      ),
    ])
      ..where(
        _db.recurringOccurrence.date.equals(date) &
            _db.recurringOccurrence.deletedAt.isNull() &
            _db.recurringTask.deletedAt.isNull(),
      )
      ..orderBy(<OrderingTerm>[
        OrderingTerm(expression: _db.recurringTask.startMinute),
        OrderingTerm(expression: _db.recurringOccurrence.id),
      ]);
  }

  List<RecurringOccurrenceView> _toViews(List<TypedResult> rows) {
    return <RecurringOccurrenceView>[
      for (final row in rows)
        RecurringOccurrenceView(
          task: row.readTable(_db.recurringTask),
          occurrence: row.readTable(_db.recurringOccurrence),
        ),
    ];
  }
}