// =============================================================================
// 方格时间轴 · 写入通道
// =============================================================================
// 为什么这里不直接调 `PlanItemRepository`：
//   `create()` 没有 `planned_start` / `planned_end` 两个形参，而本轮**不许动
//   `packages/**`**。所以排期落库只能走本文件：用 `repos.oplog.writeWithOplog`
//   写 `plan_item`，与仓储层同一套账本规矩（uuidV7 + nowMillis + deviceId +
//   rev +1），同步侧看到的是一条正常记录，而不是裸 SQL 写进去的孤儿行。
//
// 为什么「待办入格」「习惯入格」要自己开事务：
//   这两件事都是**两行同时生效**的语义（计划行 + 待办置 done / 计划行 +
//   打卡行）。仓储层没有提供带排期参数的版本，而跨仓储拼事务只能拿到 `db`
//   之后自己开；`writeWithOplog` 在事务里照样落账本。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Todo, nowMillis;
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'slot_state.dart';

/// 一条待办在网格里的排期事实（待办池徽标 `已排期 09:15` 用）。
class SlottedTodo {
  /// 创建一条事实。
  const SlottedTodo({required this.planItemId, required this.startMinute});

  /// 对应的 `plan_item.id`。
  final String planItemId;

  /// 当日起始分钟。
  final int startMinute;
}

/// 方格时间轴的写入通道：一个数据库句柄 + 一个账本写入器。
class TimelineStore {
  /// 创建通道。
  TimelineStore(this.repos);

  /// 仓储集合（只用它的 `db` 与 `oplog`）。
  final ActLogRepositories repos;

  ActLogDatabase get _db => repos.db;

  /// 手填一条计划（`source_type='manual'`）。
  ///
  /// 落进「已经过去的时段」时默认**算已完成**（需求 5「回填默认打勾」）。
  /// 判据不是这里另写一个时间比较，而是复用网格四态派生用的 [isBackfill]：
  /// 同一个函数、同一份 `todayIso` / `nowMinute`，才不可能与格子的底色打架。
  /// `_insertPlanItem` 看到 `done` 会自己补 `done_at`，这里不必另写时间戳。
  ///
  /// [todayIso] / [nowMinute] 由调用方（网格）**成对注入**，与它画格子用的是
  /// 同一份时钟。不传就完全退回旧语义（写 `pending`），绝不在这里偷偷读真实
  /// 时钟：否则任何在固定「今天」下造数据的地方（既有测试、批量导入）都会被
  /// 系统日期判成回填，一建出来就是 `done`。
  Future<String> createManual({
    required String date,
    required String title,
    required int startMinute,
    required int endMinute,
    String detail = '',
    String? todayIso,
    int? nowMinute,
  }) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', '标题不能为空');
    }
    final bool backfill = todayIso != null &&
        nowMinute != null &&
        isBackfill(
          date: date,
          plannedStart: startMinute,
          todayIso: todayIso,
          nowMinute: nowMinute,
        );
    return _insertPlanItem(
      date: date,
      title: trimmed,
      detail: detail,
      startMinute: startMinute,
      endMinute: endMinute,
      // `plan_item.source_type` 的「手填」取值就是字面量 'manual'
      // （`PlanSourceType` 只覆盖 todo / habit 两个引用来源）。
      sourceType: 'manual',
      sourceId: null,
      sourceTodoId: null,
      isHabitRef: 0,
      status: backfill ? PlanStatus.done.code : PlanStatus.pending.code,
    );
  }

  /// 待办入格：新建计划行（快照标题）+ 同事务把待办置 `done`。
  ///
  /// 「回填默认打勾」与 [createManual] 同一条判据（[isBackfill]）：排进已经
  /// 过去的时段，计划行直接写 `done`。注意这里**不**因此多写什么 —— 待办本身
  /// 置 `done` 是本方法既有的语义（「待办入格 = 这件事已做」），与回填无关，
  /// 回填只是让计划行的复选框默认呈现已勾选。
  ///
  /// [todayIso] / [nowMinute] 的约定与 [createManual] 相同：成对注入才判定
  /// 回填，不传就保持旧行为（写 `pending`），不在 store 里读真实时钟。
  Future<String> createFromTodo({
    required String date,
    required Todo todo,
    required int startMinute,
    required int endMinute,
    String? todayIso,
    int? nowMinute,
  }) async {
    final String planItemId = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();
    final bool backfill = todayIso != null &&
        nowMinute != null &&
        isBackfill(
          date: date,
          plannedStart: startMinute,
          todayIso: todayIso,
          nowMinute: nowMinute,
        );

    await _db.transaction(() async {
      await _insertPlanItem(
        id: planItemId,
        date: date,
        title: todo.title,
        detail: todo.detail,
        startMinute: startMinute,
        endMinute: endMinute,
        sourceType: PlanSourceType.todo.code,
        sourceId: todo.id,
        sourceTodoId: todo.id,
        isHabitRef: 0,
        status: backfill ? PlanStatus.done.code : PlanStatus.pending.code,
        estMinutes: todo.estMinutes,
        quadrant: todo.quadrant?.code,
        priorityAbc: todo.priorityAbc?.code,
        deviceId: deviceId,
        ts: ts,
      );
      await _markTodoDone(todo: todo, deviceId: deviceId, ts: ts);
    });
    return planItemId;
  }

  /// 习惯入格：计划行 `status='done'` + 同日 `habit_checkin(status='done')`。
  ///
  /// 两行同一事务；打卡行命中墓碑时**复活同一行**（`habit_checkin_pair_unique`
  /// 是 UNIQUE(habit_id, date)，墓碑仍占位，插新行会撞约束）。
  Future<String> createFromHabit({
    required String date,
    required HabitData habit,
    required int startMinute,
    required int endMinute,
  }) async {
    final String planItemId = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await _db.transaction(() async {
      await _insertPlanItem(
        id: planItemId,
        date: date,
        title: habit.name,
        detail: '',
        startMinute: startMinute,
        endMinute: endMinute,
        sourceType: PlanSourceType.habit.code,
        sourceId: habit.id,
        sourceTodoId: null,
        isHabitRef: 1,
        status: PlanStatus.done.code,
        deviceId: deviceId,
        ts: ts,
      );
      await _upsertDoneCheckin(
        habitId: habit.id,
        date: date,
        deviceId: deviceId,
        ts: ts,
      );
    });
    return planItemId;
  }

  /// 只改起止，**id 不变**（条目拖动改时间用这个，不新建行）。
  Future<void> reschedule({
    required String planItemId,
    required int startMinute,
    required int endMinute,
  }) async {
    final PlanItemData? row = await _rowOf(planItemId);
    if (row == null) {
      throw StateError('plan_item $planItemId 不存在');
    }
    final String deviceId = await repos.oplog.resolveDeviceId();
    final int ts = nowMillis();
    await repos.oplog.writeWithOplog<void>(
      table: 'plan_item',
      id: planItemId,
      changedFields: <String, Object?>{
        'planned_start': startMinute,
        'planned_end': endMinute,
      },
      write: () => (_db.update(_db.planItem)
            ..where((t) => t.id.equals(planItemId)))
          .write(
        PlanItemCompanion(
          plannedStart: Value<int?>(startMinute),
          plannedEnd: Value<int?>(endMinute),
          updatedAt: Value(ts),
          originDeviceId: Value(deviceId),
          rev: Value(row.rev + 1),
        ),
      ),
    );
  }

  /// 某天已经排过期的待办（`todo.id` → 排期事实）。
  ///
  /// 判据与待办池一致：存在**未删除**的 `plan_item` 且 `source_todo_id = todo.id`。
  Future<Map<String, SlottedTodo>> slottedTodosOf(String date) async {
    final List<PlanItemData> rows = await (_db.select(_db.planItem)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull()))
        .get();
    final Map<String, SlottedTodo> result = <String, SlottedTodo>{};
    for (final PlanItemData row in rows) {
      final String? todoId = row.sourceTodoId;
      final int? start = row.plannedStart;
      if (todoId == null || start == null) {
        continue;
      }
      result[todoId] = SlottedTodo(planItemId: row.id, startMinute: start);
    }
    return result;
  }

  /// 全库已排期的待办（**跨日期**；待办池徽标 `已排期 09:15` 用）。
  ///
  /// 与 [slottedTodosOf] 的区别：§0 的「已填时间」判据本身**不带日期**
  /// —— 只要存在一条未删除的 `plan_item` 且 `source_todo_id = todo.id`，
  /// 这条待办就算已排期，不管它排在哪一天。
  ///
  /// 同一待办被排多次时取「日期最早、同日最早」的那条（查询已按此排序 +
  /// `putIfAbsent`），保证同一份数据每次给同一个答案。
  Future<Map<String, SlottedTodo>> slottedTodosAll() async {
    final List<PlanItemData> rows = await (_db.select(_db.planItem)
          ..where((t) => t.sourceTodoId.isNotNull() & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.plannedStart),
          ]))
        .get();
    final Map<String, SlottedTodo> result = <String, SlottedTodo>{};
    for (final PlanItemData row in rows) {
      final String? todoId = row.sourceTodoId;
      final int? start = row.plannedStart;
      if (todoId == null || start == null) {
        continue;
      }
      result.putIfAbsent(
        todoId,
        () => SlottedTodo(planItemId: row.id, startMinute: start),
      );
    }
    return result;
  }

  /// 新建待办并**在同一天同时排进格子**（待办池表单填了起始时间时走这里）。
  ///
  /// 两行同一事务：`todo` 必须先落库，否则 `plan_item.source_todo_id`
  /// 的外键约束会拒收。待办本身保持 `open`（是「已排期」，不是「已完成」），
  /// 与 [createFromTodo]（那边是把已有待办置 `done`）语义不同。
  Future<String> createTodoWithSlot({
    required String date,
    required String title,
    required int startMinute,
    required int endMinute,
    int? estMinutes,
    String? dueDate,
    String? quadrant,
    String? priorityAbc,
  }) async {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', '标题不能为空');
    }
    final String todoId = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await _db.transaction(() async {
      await repos.oplog.writeWithOplog<void>(
        table: 'todo',
        id: todoId,
        changedFields: <String, Object?>{
          'title': trimmed,
          'status': TodoStatus.open.code,
          'est_minutes': estMinutes,
          'due_date': dueDate,
        },
        write: () => _db.into(_db.todo).insert(
          TodoCompanion.insert(
            id: todoId,
            title: trimmed,
            estMinutes: Value<int?>(estMinutes),
            dueDate: Value<String?>(dueDate),
            quadrant: Value<String?>(quadrant),
            priorityAbc: Value<String?>(priorityAbc),
            status: Value(TodoStatus.open.code),
            createdAt: ts,
            updatedAt: ts,
            originDeviceId: deviceId,
          ),
        ),
      );
      await _insertPlanItem(
        date: date,
        title: trimmed,
        detail: '',
        startMinute: startMinute,
        endMinute: endMinute,
        sourceType: PlanSourceType.todo.code,
        sourceId: todoId,
        sourceTodoId: todoId,
        isHabitRef: 0,
        status: PlanStatus.pending.code,
        estMinutes: estMinutes,
        quadrant: quadrant,
        priorityAbc: priorityAbc,
        deviceId: deviceId,
        ts: ts,
      );
    });
    return todoId;
  }

  Future<PlanItemData?> _rowOf(String id) {
    return (_db.select(_db.planItem)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> _insertPlanItem({
    required String date,
    required String title,
    required String detail,
    required int startMinute,
    required int endMinute,
    required String sourceType,
    required String? sourceId,
    required String? sourceTodoId,
    required int isHabitRef,
    required String status,
    int? estMinutes,
    String? quadrant,
    String? priorityAbc,
    String? id,
    String? deviceId,
    int? ts,
  }) async {
    final String newId = id ?? uuidV7();
    final int at = ts ?? nowMillis();
    final String device = deviceId ?? await repos.oplog.resolveDeviceId();
    final bool done = status == PlanStatus.done.code;
    await repos.oplog.writeWithOplog<void>(
      table: 'plan_item',
      id: newId,
      changedFields: <String, Object?>{
        'date': date,
        'title': title,
        'planned_start': startMinute,
        'planned_end': endMinute,
        'source_type': sourceType,
      },
      write: () => _db.into(_db.planItem).insert(
        PlanItemCompanion.insert(
          id: newId,
          date: date,
          title: title,
          detail: Value(detail),
          sourceType: Value(sourceType),
          sourceId: Value<String?>(sourceId),
          sourceTodoId: Value<String?>(sourceTodoId),
          quadrant: Value<String?>(quadrant),
          priorityAbc: Value<String?>(priorityAbc),
          estMinutes: Value<int?>(estMinutes),
          isHabitRef: Value(isHabitRef),
          status: Value(status),
          plannedStart: Value<int?>(startMinute),
          plannedEnd: Value<int?>(endMinute),
          doneAt: Value<int?>(done ? at : null),
          createdAt: at,
          updatedAt: at,
          originDeviceId: device,
        ),
      ),
    );
    return newId;
  }

  Future<void> _markTodoDone({
    required Todo todo,
    required String deviceId,
    required int ts,
  }) async {
    final TodoData? row =
        await (_db.select(_db.todo)..where((t) => t.id.equals(todo.id)))
            .getSingleOrNull();
    if (row == null) {
      throw StateError('todo ${todo.id} 不存在');
    }
    await repos.oplog.writeWithOplog<void>(
      table: 'todo',
      id: todo.id,
      changedFields: <String, Object?>{
        'status': TodoStatus.done.code,
        'completed_at': ts,
      },
      write: () => (_db.update(_db.todo)..where((t) => t.id.equals(todo.id)))
          .write(
        TodoCompanion(
          status: Value(TodoStatus.done.code),
          completedAt: Value<int?>(ts),
          updatedAt: Value(ts),
          originDeviceId: Value(deviceId),
          rev: Value(row.rev + 1),
        ),
      ),
    );
  }

  Future<void> _upsertDoneCheckin({
    required String habitId,
    required String date,
    required String deviceId,
    required int ts,
  }) async {
    final HabitCheckinData? existing =
        await (_db.select(_db.habitCheckin)
              ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
            .getSingleOrNull();

    if (existing == null) {
      final String checkinId = uuidV7();
      await repos.oplog.writeWithOplog<void>(
        table: 'habit_checkin',
        id: checkinId,
        changedFields: <String, Object?>{
          'habit_id': habitId,
          'date': date,
          'status': CheckinStatus.done.code,
        },
        write: () => _db.into(_db.habitCheckin).insert(
          HabitCheckinCompanion.insert(
            id: checkinId,
            habitId: habitId,
            date: date,
            value: const Value<double>(1),
            status: Value(CheckinStatus.done.code),
            note: const Value<String>(''),
            createdAt: ts,
            updatedAt: ts,
            originDeviceId: deviceId,
          ),
        ),
      );
      return;
    }

    await repos.oplog.writeWithOplog<void>(
      table: 'habit_checkin',
      id: existing.id,
      changedFields: <String, Object?>{
        'status': CheckinStatus.done.code,
        'value': 1.0,
      },
      write: () => (_db.update(_db.habitCheckin)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        HabitCheckinCompanion(
          value: const Value<double>(1),
          status: Value(CheckinStatus.done.code),
          deletedAt: const Value<int?>(null),
          updatedAt: Value(ts),
          originDeviceId: Value(deviceId),
          rev: Value(existing.rev + 1),
        ),
      ),
    );
  }
}