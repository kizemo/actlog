// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · TodoRepository 集成测试（内存 SQLite，真实 drift 表结构）
// =============================================================================
// 覆盖 Task 19 / W4「待办捞取入口」的数据层契约：
//   1. listOpen 只取 open 且未删除的待办，按 created_at 升序；
//   2. pullToPlan 建 plan_item（source_type='todo' + 引用 + 快照）并把 todo 置 done；
//   3. 不存在 / 已删除 / 非 open 的待办按既有约定抛 StateError，且不留下写入；
//   4. 两次写入都经过 OplogWriter（plan_item 一条 upsert + todo 一条 upsert）。
//
// 待办行由测试**直接插入**（fixture），不走 oplog —— 这样 oplog 断言里只会
// 出现 pullToPlan 自己写的记录，计数才有判别力。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';

const String _device = 'dev-test';

final String _today = today();

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
    String? dueDate,
    String? quadrant,
    String? priorityAbc,
    String status = 'open',
    int createdAt = 1000,
    int? deletedAt,
    int rev = 1,
  }) async {
    await db.into(db.todo).insert(
          TodoCompanion.insert(
            id: id,
            title: title,
            detail: Value(detail),
            estMinutes: Value(estMinutes),
            dueDate: Value(dueDate),
            quadrant: Value(quadrant),
            priorityAbc: Value(priorityAbc),
            status: Value(status),
            createdAt: createdAt,
            updatedAt: createdAt,
            deletedAt: Value(deletedAt),
            originDeviceId: _device,
            rev: Value(rev),
          ),
        );
    return id;
  }

  /// 取单条标量（COUNT(*) 之类）。
  Future<Object?> scalar(String sql) async {
    final rows = await db.customSelect(sql).get();
    if (rows.isEmpty) {
      return null;
    }
    return rows.first.data.values.first;
  }

  Future<TodoData> todoRow(String id) {
    return (db.select(db.todo)..where((t) => t.id.equals(id))).getSingle();
  }

  // ===========================================================================
  // listOpen
  // ===========================================================================
  group('TodoRepository.listOpen', () {
    test('只返回 open 且未删除的待办', () async {
      await seedTodo(id: 't-open', title: '写周报', createdAt: 100);
      await seedTodo(
        id: 't-done',
        title: '已完成的',
        status: TodoStatus.done.code,
        createdAt: 200,
      );
      await seedTodo(
        id: 't-cancelled',
        title: '已取消的',
        status: TodoStatus.cancelled.code,
        createdAt: 300,
      );
      await seedTodo(
        id: 't-archived',
        title: '已归档的',
        status: TodoStatus.archived.code,
        createdAt: 400,
      );
      await seedTodo(
        id: 't-deleted',
        title: '已删除的',
        createdAt: 500,
        deletedAt: 900,
      );

      final todos = await repos.todo.listOpen();

      expect(todos.map((t) => t.id), ['t-open']);
      expect(todos.single.title, '写周报');
    });

    test('按 created_at 升序，与插入顺序无关', () async {
      // 故意乱序插入。
      await seedTodo(id: 't-3', title: '第三', createdAt: 3000);
      await seedTodo(id: 't-1', title: '第一', createdAt: 1000);
      await seedTodo(id: 't-2', title: '第二', createdAt: 2000);

      final todos = await repos.todo.listOpen();

      expect(todos.map((t) => t.id), ['t-1', 't-2', 't-3']);
      expect(
        todos.map((t) => t.createdAt),
        orderedEquals(<int>[1000, 2000, 3000]),
      );
    });

    test('空池返回空列表', () async {
      expect(await repos.todo.listOpen(), isEmpty);
    });

    test('返回的是领域实体，字段与库内一致', () async {
      await seedTodo(
        id: 't-full',
        title: '整条快照',
        detail: '细节',
        estMinutes: 45,
        dueDate: '2026-11-10',
        quadrant: Quadrant.q2.code,
        priorityAbc: PriorityAbc.a.code,
        createdAt: 777,
        rev: 3,
      );

      final todo = (await repos.todo.listOpen()).single;

      expect(todo.id, 't-full');
      expect(todo.detail, '细节');
      expect(todo.estMinutes, 45);
      expect(todo.dueDate, '2026-11-10');
      expect(todo.quadrant, Quadrant.q2);
      expect(todo.priorityAbc, PriorityAbc.a);
      expect(todo.status, TodoStatus.open);
      expect(todo.createdAt, 777);
      expect(todo.updatedAt, 777);
      expect(todo.deletedAt, isNull);
      expect(todo.originDeviceId, _device);
      expect(todo.rev, 3);
      // 编译期证明 core_data.dart 导出了 TodoRepository（若未导出这里过不了）。
      final TodoRepository viaPackageRoot = repos.todo;
      expect(viaPackageRoot, same(repos.todo));
    });
  });

  // ===========================================================================
  // pullToPlan · 正常路径
  // ===========================================================================
  group('TodoRepository.pullToPlan 正常路径', () {
    test('建一条 plan_item 并快照 todo 的字段', () async {
      final todoId = await seedTodo(
        id: 't-pull',
        title: '打电话给客户',
        detail: '确认下周排期',
        estMinutes: 30,
        dueDate: '2026-11-12',
        quadrant: Quadrant.q2.code,
        priorityAbc: PriorityAbc.a.code,
      );

      final planItemId = await repos.todo.pullToPlan(todoId, _today);

      final items = await repos.planItem.listByDate(_today);
      expect(items, hasLength(1));
      final item = items.single;

      expect(item.id, planItemId);
      expect(item.date, _today);
      expect(item.sourceType, PlanSourceType.todo.code);
      expect(item.sourceTodoId, todoId);
      expect(item.sourceId, todoId, reason: 'source_id 与 source_todo_id 同指 todo');
      // 快照列。
      expect(item.title, '打电话给客户');
      expect(item.detail, '确认下周排期');
      expect(item.estMinutes, 30);
      expect(item.quadrant, Quadrant.q2.code);
      expect(item.priorityAbc, PriorityAbc.a.code);
      // 其余按 PlanItem 默认。
      expect(item.domain, '');
      expect(item.status, PlanStatus.pending.code);
      expect(item.isHabitRef, 0);
    });

    test('把 todo 置为 done 并写 completed_at，rev 递增', () async {
      final todoId = await seedTodo(id: 't-close', title: '关掉我', rev: 4);

      await repos.todo.pullToPlan(todoId, _today);

      final row = await todoRow(todoId);
      expect(row.status, TodoStatus.done.code);
      expect(row.completedAt, isNotNull);
      expect(row.deletedAt, isNull, reason: '捞进计划不是删除，不得写墓碑');
      expect(row.rev, 5);
      expect(await repos.todo.listOpen(), isEmpty, reason: '捞走后池子里不再出现');
    });

    test('计划日取调用方传入的日期，不取 due_date', () async {
      final todoId = await seedTodo(
        id: 't-due',
        title: '有截止日',
        dueDate: '2026-11-20',
      );

      await repos.todo.pullToPlan(todoId, _today);

      final item = (await repos.planItem.listByDate(_today)).single;
      expect(item.date, _today);
      expect((await todoRow(todoId)).dueDate, '2026-11-20',
          reason: 'due_date 留在待办上，plan_item 没有这一列');
    });

    test('同一条 todo 第二次捞取抛 StateError，不重复建计划行', () async {
      final todoId = await seedTodo(id: 't-twice', title: '只能捞一次');
      await repos.todo.pullToPlan(todoId, _today);

      await expectLater(
        () => repos.todo.pullToPlan(todoId, _today),
        throwsA(isA<StateError>()),
      );

      expect(await repos.planItem.listByDate(_today), hasLength(1));
    });
  });

  // ===========================================================================
  // pullToPlan · 错误约定
  // ===========================================================================
  group('TodoRepository.pullToPlan 错误约定', () {
    test('待办不存在抛 StateError，且不写任何行', () async {
      await expectLater(
        () => repos.todo.pullToPlan('t-missing', _today),
        throwsA(isA<StateError>()),
      );
      expect(await repos.planItem.listByDate(_today), isEmpty);
      expect(await scalar('SELECT COUNT(*) FROM oplog'), 0);
    });

    test('待办已软删抛 StateError，且不改动墓碑行', () async {
      final todoId = await seedTodo(
        id: 't-gone',
        title: '已删除的',
        deletedAt: 5555,
        createdAt: 10,
      );

      await expectLater(
        () => repos.todo.pullToPlan(todoId, _today),
        throwsA(isA<StateError>()),
      );

      final row = await todoRow(todoId);
      expect(row.deletedAt, 5555);
      expect(row.status, TodoStatus.open.code, reason: '失败必须整体不落库');
      expect(await repos.planItem.listByDate(_today), isEmpty);
      expect(await scalar('SELECT COUNT(*) FROM oplog'), 0);
    });

    test('非 open 的待办抛 StateError', () async {
      for (final status in <TodoStatus>[
        TodoStatus.done,
        TodoStatus.cancelled,
        TodoStatus.archived,
      ]) {
        final todoId = await seedTodo(
          id: 't-${status.code}',
          title: '状态 ${status.code}',
          status: status.code,
          createdAt: 100,
        );

        await expectLater(
          () => repos.todo.pullToPlan(todoId, _today),
          throwsA(isA<StateError>()),
          reason: 'status=${status.code} 不该被捞进计划',
        );
        expect((await todoRow(todoId)).status, status.code);
      }
      expect(await repos.planItem.listByDate(_today), isEmpty);
    });

    test('非法日期抛 ArgumentError，todo 保持 open', () async {
      final todoId = await seedTodo(id: 't-date', title: '日期不合法');

      await expectLater(
        () => repos.todo.pullToPlan(todoId, '2026-02-30'),
        throwsArgumentError,
      );

      expect((await todoRow(todoId)).status, TodoStatus.open.code);
      expect(await repos.planItem.listByDate(_today), isEmpty);
      expect(await scalar('SELECT COUNT(*) FROM oplog'), 0);
    });
  });

  // ===========================================================================
  // oplog 接线
  // ===========================================================================
  group('TodoRepository · oplog 接线', () {
    test('一次捞取写两条 upsert：plan_item + todo', () async {
      final todoId = await seedTodo(id: 't-oplog', title: '有账可查');
      final planItemId = await repos.todo.pullToPlan(todoId, _today);

      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_table = 'plan_item' "
          "AND entity_id = '$planItemId' AND op = 'upsert'",
        ),
        1,
      );
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_table = 'todo' "
          "AND entity_id = '$todoId' AND op = 'upsert'",
        ),
        1,
      );
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_table = 'todo' "
          "AND entity_id = '$todoId' AND payload LIKE '%completed_at%'",
        ),
        1,
        reason: 'todo 那条 oplog 的 payload 必须包含 completed_at 字段 diff',
      );
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE device_id = '$_device'",
        ),
        2,
        reason: 'fixture 直接插库不落 oplog，这里恰好只有捞取写的两条',
      );
    });

    test('plan_item 那条 oplog 的 payload 带来源字段', () async {
      final todoId = await seedTodo(id: 't-payload', title: '带来源');
      final planItemId = await repos.todo.pullToPlan(todoId, _today);

      final payload = await scalar(
        "SELECT payload FROM oplog WHERE entity_table = 'plan_item' "
        "AND entity_id = '$planItemId'",
      );
      expect(payload, contains('source_type'));
      expect(payload, contains('todo'));
      expect(payload, contains('source_todo_id'));
      expect(payload, contains(todoId));
    });

    test('失败路径不写 oplog', () async {
      await expectLater(
        () => repos.todo.pullToPlan('t-none', _today),
        throwsA(isA<StateError>()),
      );
      expect(await scalar('SELECT COUNT(*) FROM oplog'), 0);
    });
  });

  // 契约修订 H：待办池必须有数据来源。`create` 是唯一的新建入口，
  // 它必须「落库 + 落 oplog + 立刻能被 listOpen 读到」三件事同时成立。
  group('create', () {
    test('写入 todo 行并返回 id，字段按入参落库（标题去空白）', () async {
      final id = await repos.todo.create(
        title: '  写周报  ',
        detail: '本周进展',
        estMinutes: 30,
        dueDate: _today,
        // 落库值是领域枚举的 `code`（'Q1' / 'A'），库里 CHECK 约束按大写校验。
        quadrant: Quadrant.q1.code,
        priorityAbc: PriorityAbc.a.code,
      );

      expect(id, isNotEmpty);

      final rows = await repos.todo.listOpen();
      expect(rows, hasLength(1));
      final todo = rows.single;
      expect(todo.id, id);
      expect(todo.title, '写周报');
      expect(todo.detail, '本周进展');
      expect(todo.estMinutes, 30);
      expect(todo.dueDate, _today);
      expect(todo.quadrant, Quadrant.q1);
      expect(todo.priorityAbc, PriorityAbc.a);
      expect(todo.status, TodoStatus.open);
    });

    test('省略字段时落 NULL / 默认值，status 默认 open', () async {
      final id = await repos.todo.create(title: '只填标题');

      final rows = await repos.todo.listOpen();
      expect(rows, hasLength(1));
      final todo = rows.single;
      expect(todo.id, id);
      expect(todo.detail, '');
      expect(todo.estMinutes, isNull);
      expect(todo.dueDate, isNull);
      expect(todo.quadrant, isNull);
      expect(todo.priorityAbc, isNull);
      expect(todo.status, TodoStatus.open);
    });

    test('走 oplog：新建恰好留一条 todo upsert 记录', () async {
      final id = await repos.todo.create(title: '留痕');

      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_table = 'todo' "
          "AND entity_id = '$id'",
        ),
        1,
      );
    });

    test('空标题抛 ArgumentError，不落行也不落 oplog', () async {
      await expectLater(
        () => repos.todo.create(title: '   '),
        throwsA(isA<ArgumentError>()),
      );

      expect(await scalar('SELECT COUNT(*) FROM todo'), 0);
      expect(await scalar('SELECT COUNT(*) FROM oplog'), 0);
    });
  });
}