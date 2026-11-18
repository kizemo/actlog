// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · Task 39 W2「待办捞进计划后从待办池消失」回归
// =============================================================================
// 权威口径在 docs/schema_v1.sql 的 todo 表注释：
//   「「添加到今日计划」= 在 plan_item 建行 + 写 source_todo_id + 拷 title 快照，
//     **不复制状态**。todo.completed_at 只在待办本体完成时写。」
//
// 因此这里钉住四件事：
//   1. pullToPlan 之后 todo 仍 `open`、`completed_at` 仍 NULL、`rev` 不动；
//   2. 同一次调用只新增一条 plan_item（来源 + 快照字段齐全，计划起止成对）；
//   3. `listOpen()`（待办池的唯一数据源）仍能读到这条 todo；
//   4. 「只能捞一次」不靠状态位兜底：同一天重复捞取抛 StateError 且不建第二行。
// =============================================================================

import 'package:core_data/core_data.dart';
// `core_db` 也导出同名 `Todo`（drift 表类）；这里要的是 `core_domain` 的实体。
import 'package:core_db/core_db.dart' hide Todo;
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';

const String _device = 'dev-task39-w2';
const String _today = '2026-11-09';

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: _device);
  });

  tearDown(() async {
    await db.close();
  });

  /// 直接插一条待办（fixture，不落 oplog）。
  Future<String> seedTodo({
    required String id,
    required String title,
    String detail = '',
    int? estMinutes,
    String? quadrant,
    String? priorityAbc,
    int createdAt = 1000,
    int rev = 3,
  }) async {
    await db.into(db.todo).insert(
          TodoCompanion.insert(
            id: id,
            title: title,
            detail: Value(detail),
            estMinutes: Value(estMinutes),
            quadrant: Value(quadrant),
            priorityAbc: Value(priorityAbc),
            status: const Value('open'),
            createdAt: createdAt,
            updatedAt: createdAt,
            originDeviceId: _device,
            rev: Value(rev),
          ),
        );
    return id;
  }

  Future<TodoData> todoRow(String id) {
    return (db.select(db.todo)..where((t) => t.id.equals(id))).getSingle();
  }

  test('A1 · 捞进计划后 todo 仍是 open，completed_at 为 NULL，rev 不变', () async {
    final String todoId = await seedTodo(id: 't-keep', title: '写周报');

    await repos.todo.pullToPlan(todoId, _today);

    final TodoData row = await todoRow(todoId);
    expect(row.status, TodoStatus.open.code, reason: '计划项不是待办完成');
    expect(row.completedAt, isNull, reason: 'completed_at 只在待办本体完成时写');
    expect(row.rev, 3, reason: '没写 todo 行 ⇒ rev 不该递增');
    expect(row.deletedAt, isNull);
  });

  test('A2 · 只新增一条 plan_item，来源与快照字段齐全', () async {
    final String todoId = await seedTodo(
      id: 't-snap',
      title: '整理会议纪要',
      detail: '把三段录音并成一页',
      estMinutes: 45,
      quadrant: 'Q2',
      priorityAbc: 'A',
    );

    final String planItemId = await repos.todo.pullToPlan(todoId, _today);

    final List<PlanItemData> items = await repos.planItem.listByDate(_today);
    expect(items, hasLength(1), reason: '一次捞取只建一条计划行');
    final PlanItemData item = items.single;
    expect(item.id, planItemId);
    expect(item.title, '整理会议纪要');
    expect(item.detail, '把三段录音并成一页');
    expect(item.sourceType, PlanSourceType.todo.code);
    expect(item.sourceTodoId, todoId);
    expect(item.estMinutes, 45);
    expect(item.quadrant, 'Q2');
    expect(item.priorityAbc, 'A');
    expect(item.isHabitRef, 0);
    expect(
      item.plannedStart == null,
      item.plannedEnd == null,
      reason: '计划起止必须成对（这里两个都为 NULL ⇒ 都未排时刻）',
    );
  });

  test('A3 · listOpen() 仍能读到这条 todo（待办池不丢条目）', () async {
    final String todoId = await seedTodo(id: 't-pool', title: '给客户回信');

    await repos.todo.pullToPlan(todoId, _today);

    final List<Todo> open = await repos.todo.listOpen();
    expect(open.map((Todo t) => t.id), contains(todoId));
    expect(open, hasLength(1));
  });

  test('A4 · 同一天重复捞取抛 StateError，不建第二行', () async {
    final String todoId = await seedTodo(id: 't-twice', title: '只能捞一次');
    await repos.todo.pullToPlan(todoId, _today);

    await expectLater(
      () => repos.todo.pullToPlan(todoId, _today),
      throwsA(isA<StateError>()),
    );

    expect(await repos.planItem.listByDate(_today), hasLength(1));
    expect((await todoRow(todoId)).status, TodoStatus.open.code);
  });
}