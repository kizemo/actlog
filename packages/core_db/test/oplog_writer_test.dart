// =============================================================================
// core_db · oplog 写入拦截层（P0-5 门禁）
// =============================================================================
// 验收标准（来自开发计划 P0-5）：**任意仓储写入必产生一条 oplog**。
// 这里用「统一写入口 writeWithOplog」模拟仓储写入，逐条断言。
// =============================================================================

import 'dart:convert';

import 'package:core_db/core_db.dart';
import 'package:test/test.dart';

void main() {
  late ActLogDatabase db;
  late OplogWriter writer;

  setUp(() async {
    db = openInMemoryActLogDatabase();
    writer = OplogWriter(db, deviceId: 'dev-test');
  });

  tearDown(() async {
    await db.close();
  });

  group('白名单', () {
    test('syncedTables = 12 张同步表', () {
      expect(syncedTables.length, 12);
      expect(
        syncedTables,
        containsAll(<String>[
          'settings',
          'day_log',
          'plan_item',
          'todo',
          'habit',
          'habit_checkin',
          'project',
          'project_milestone',
          'project_increment',
          'reminder',
          // v2：规则与物化凭证都必须同步，否则换设备会重新物化出重复条目。
          'recurring_task',
          'recurring_occurrence',
        ]),
      );
    });

    test('派生表 / 本机表不在白名单里', () {
      expect(localOnlyTables, <String>{'habit_score', 'sync_state', 'snapshot_meta'});
      expect(syncedTables.intersection(localOnlyTables), isEmpty);
      expect(allTables.length, 16);
      expect(isSyncedTable('habit_score'), isFalse);
      expect(isSyncedTable('sync_state'), isFalse);
      expect(isSyncedTable('snapshot_meta'), isFalse);
      expect(isSyncedTable('todo'), isTrue);
    });

    test('对非同步表落痕会被当场拒绝', () {
      expect(
        () => writer.recordUpsert('habit_score', 'x', const <String, Object?>{}),
        throwsArgumentError,
      );
      expect(
        () => writer.recordDelete('sync_state', 'x'),
        throwsArgumentError,
      );
      expect(
        () => writer.recordUpsert('oplog', 'x', const <String, Object?>{}),
        throwsArgumentError,
      );
    });
  });

  group('落痕', () {
    test('任意仓储写入必产生一条 oplog', () async {
      await writer.writeWithOplog<void>(
        table: TableNames.todo,
        id: 'todo-1',
        changedFields: <String, Object?>{'title': '写测试', 'status': 'open'},
        write: () => db.into(db.todo).insert(
          TodoCompanion.insert(
            id: 'todo-1',
            title: '写测试',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
      );

      final oplog = await db.select(db.oplog).get();
      expect(oplog.length, 1);
      expect(oplog.single.entityTable, 'todo');
      expect(oplog.single.entityId, 'todo-1');
      expect(oplog.single.op, 'upsert');
      expect(oplog.single.deviceId, 'dev-test');
      expect(oplog.single.lamport, 1);
      expect(oplog.single.synced, 0);
    });

    test('payload 是字段级 diff，不是整行快照', () async {
      await writer.writeWithOplog<void>(
        table: TableNames.todo,
        id: 'todo-2',
        changedFields: <String, Object?>{'status': 'done', 'completed_at': 42},
        write: () => db.into(db.todo).insert(
          TodoCompanion.insert(
            id: 'todo-2',
            title: '不该出现在 payload 里',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
      );

      final payload =
          jsonDecode((await db.select(db.oplog).get()).single.payload!);
      expect(payload, <String, Object?>{'status': 'done', 'completed_at': 42});
      expect(payload.containsKey('title'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
    });

    test('delete 的 payload 记 {"deleted_at": ms}', () async {
      await writer.writeWithOplog<void>(
        table: TableNames.todo,
        id: 'todo-3',
        isDelete: true,
        deletedAt: 1700000000000,
        write: () async {},
      );

      final row = (await db.select(db.oplog).get()).single;
      expect(row.op, 'delete');
      expect(jsonDecode(row.payload!), <String, Object?>{'deleted_at': 1700000000000});
    });

    test('lamport 单调递增', () async {
      for (var i = 0; i < 3; i++) {
        await writer.writeWithOplog<void>(
          table: TableNames.todo,
          id: 'todo-lamport-$i',
          changedFields: <String, Object?>{'title': 't$i'},
          write: () async {},
        );
      }

      final oplog = await db.select(db.oplog).get();
      expect(oplog.map((o) => o.lamport).toList(), <int>[1, 2, 3]);
    });

    test('白名单内每张表都能落痕', () async {
      var index = 0;
      for (final table in syncedTables) {
        await writer.recordUpsert(table, 'id-$index', <String, Object?>{'x': index});
        index++;
      }
      expect(await db.select(db.oplog).get(), hasLength(12));
    });
  });

  group('事务一致性', () {
    test('业务写入抛异常 → 业务数据与 oplog 一起回滚', () async {
      await expectLater(
        writer.writeWithOplog<void>(
          table: TableNames.todo,
          id: 'todo-rollback',
          changedFields: <String, Object?>{'title': '会被回滚'},
          write: () async {
            await db.into(db.todo).insert(
              TodoCompanion.insert(
                id: 'todo-rollback',
                title: '会被回滚',
                createdAt: 1000,
                updatedAt: 1000,
                originDeviceId: 'dev-test',
              ),
            );
            throw StateError('boom');
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(await db.select(db.todo).get(), isEmpty);
      expect(await db.select(db.oplog).get(), isEmpty);
    });

    test('业务写入抛异常 → lamport 计数器也一起回滚', () async {
      await expectLater(
        writer.writeWithOplog<void>(
          table: TableNames.todo,
          id: 'todo-rollback-2',
          write: () async => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );

      // lamport 计数器写在 sync_state，同一事务内回滚 → 仍为初始值。
      final state = await db.select(db.syncState).get();
      final lamportRow = state.where((s) => s.key == lamportStateKey).toList();
      expect(lamportRow, isEmpty);
    });
  });

  group('派生表绝不入 oplog', () {
    test('写 habit_score 不产生 oplog', () async {
      // habit_score 有指向 habit 的外键（ON DELETE CASCADE），先建 habit。
      await db.into(db.habit).insert(
        HabitCompanion.insert(
          id: 'habit-1',
          name: '喝水',
          startDate: '2026-11-06',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );

      await writer.writeLocal<void>(
        write: () => db.into(db.habitScore).insert(
          HabitScoreCompanion.insert(
            id: 'hs-1',
            habitId: 'habit-1',
            date: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
      );

      expect(await db.select(db.habitScore).get(), hasLength(1));
      expect(await db.select(db.oplog).get(), isEmpty);
    });

    test('写 sync_state / snapshot_meta 不产生 oplog', () async {
      await writer.writeLocal<void>(
        write: () => db.into(db.snapshotMeta).insert(
          SnapshotMetaCompanion.insert(
            id: 'snap-1',
            path: 'C:/snapshots/s1.db',
            kind: 'daily',
            sha256: 'abc',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
      );

      // lamport 计数器本身也是 sync_state 写入，同样不落 oplog。
      await writer.recordUpsert('todo', 'todo-4', <String, Object?>{'a': 1});
      await writer.recordUpsert('todo', 'todo-5', <String, Object?>{'a': 2});

      final oplog = await db.select(db.oplog).get();
      expect(oplog.length, 2);
      expect(oplog.every((o) => o.entityTable == 'todo'), isTrue);
    });
  });
}
