// =============================================================================
// core_db · 坏数据必须真的被数据库拦下来
// =============================================================================
// 门禁要求：每条 CHECK / UNIQUE / FOREIGN KEY 都要用「故意破坏的数据」验证
// 它**会报错**（而不是只写在 schema 里好看）。
// 断言错误信息里带**具名约束名**，确保拦截来自 schema_v1.sql 的那条约束。
// =============================================================================

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';

void main() {
  late ActLogDatabase db;

  setUp(() async {
    db = openInMemoryActLogDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('CHECK 约束拦下坏数据', () {
    final cases = <(String, Future<void> Function(), String)>[
      (
        'plan_item.quadrant = Q9',
        () => db.into(db.planItem).insert(
          PlanItemCompanion.insert(
            id: 'p-quadrant',
            date: '2026-11-06',
            title: '坏象限',
            quadrant: const Value<String?>('Q9'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'plan_item_quadrant_check',
      ),
      (
        'plan_item.priority_abc = D',
        () => db.into(db.planItem).insert(
          PlanItemCompanion.insert(
            id: 'p-abc',
            date: '2026-11-06',
            title: '坏优先级',
            priorityAbc: const Value<String?>('D'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'plan_item_priority_abc_check',
      ),
      (
        'plan_item.status = unknown',
        () => db.into(db.planItem).insert(
          PlanItemCompanion.insert(
            id: 'p-status',
            date: '2026-11-06',
            title: '坏状态',
            status: const Value<String>('unknown'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'plan_item_status_check',
      ),
      (
        'plan_item.source_type = unknown',
        () => db.into(db.planItem).insert(
          PlanItemCompanion.insert(
            id: 'p-source',
            date: '2026-11-06',
            title: '坏来源',
            sourceType: const Value<String>('unknown'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'plan_item_source_type_check',
      ),
      (
        'plan_item.is_habit_ref = 2',
        () => db.into(db.planItem).insert(
          PlanItemCompanion.insert(
            id: 'p-habit-ref',
            date: '2026-11-06',
            title: '坏布尔',
            isHabitRef: const Value<int>(2),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'plan_item_is_habit_ref_check',
      ),
      (
        'plan_item.est_minutes = -1',
        () => db.into(db.planItem).insert(
          PlanItemCompanion.insert(
            id: 'p-est',
            date: '2026-11-06',
            title: '负估时',
            estMinutes: const Value<int?>(-1),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'plan_item_est_minutes_check',
      ),
      (
        'todo.quadrant = Q9',
        () => db.into(db.todo).insert(
          TodoCompanion.insert(
            id: 't-quadrant',
            title: '坏象限',
            quadrant: const Value<String?>('Q9'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'todo_quadrant_check',
      ),
      (
        'todo.status = unknown',
        () => db.into(db.todo).insert(
          TodoCompanion.insert(
            id: 't-status',
            title: '坏状态',
            status: const Value<String>('unknown'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'todo_status_check',
      ),
      (
        'todo.est_minutes = -1',
        () => db.into(db.todo).insert(
          TodoCompanion.insert(
            id: 't-est',
            title: '负估时',
            estMinutes: const Value<int?>(-1),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'todo_est_minutes_check',
      ),
      (
        'day_log.mode = verbose',
        () => db.into(db.dayLog).insert(
          DayLogCompanion.insert(
            id: 'd-mode',
            date: '2026-11-06',
            mode: const Value<String>('verbose'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'day_log_mode_check',
      ),
      (
        'day_log.mood_1 = 11',
        () => db.into(db.dayLog).insert(
          DayLogCompanion.insert(
            id: 'd-mood',
            date: '2026-11-06',
            mood1: const Value<int?>(11),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'day_log_mood_1_check',
      ),
      (
        'day_log.mood_failed = 2',
        () => db.into(db.dayLog).insert(
          DayLogCompanion.insert(
            id: 'd-failed',
            date: '2026-11-06',
            moodFailed: const Value<int>(2),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'day_log_mood_failed_check',
      ),
      (
        'habit.type = weird',
        () => db.into(db.habit).insert(
          HabitCompanion.insert(
            id: 'h-type',
            name: '坏类型',
            type: const Value<String>('weird'),
            startDate: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'habit_type_check',
      ),
      (
        'habit.schedule_type = monthly',
        () => db.into(db.habit).insert(
          HabitCompanion.insert(
            id: 'h-schedule',
            name: '坏排程',
            scheduleType: const Value<String>('monthly'),
            startDate: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'habit_schedule_type_check',
      ),
      (
        'habit.weekly_n = 8',
        () => db.into(db.habit).insert(
          HabitCompanion.insert(
            id: 'h-weekly',
            name: '坏周次',
            weeklyN: const Value<int?>(8),
            startDate: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'habit_weekly_n_check',
      ),
      (
        'habit.target_count = -1',
        () => db.into(db.habit).insert(
          HabitCompanion.insert(
            id: 'h-target',
            name: '负目标',
            targetCount: const Value<double?>(-1),
            startDate: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'habit_target_count_check',
      ),
      (
        'habit_checkin.status = unknown',
        () => db.into(db.habitCheckin).insert(
          HabitCheckinCompanion.insert(
            id: 'hc-status',
            habitId: 'habit-1',
            date: '2026-11-06',
            status: const Value<String>('unknown'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'habit_checkin_status_check',
      ),
      (
        'project.status = unknown',
        () => db.into(db.project).insert(
          ProjectCompanion.insert(
            id: 'pr-status',
            name: '坏状态',
            status: const Value<String>('unknown'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'project_status_check',
      ),
      (
        'project.archived = 2',
        () => db.into(db.project).insert(
          ProjectCompanion.insert(
            id: 'pr-archived',
            name: '坏布尔',
            archived: const Value<int>(2),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'project_archived_check',
      ),
      (
        'reminder.target_type = unknown',
        () => db.into(db.reminder).insert(
          ReminderCompanion.insert(
            id: 'r-target',
            targetType: 'unknown',
            targetId: 'x',
            remindAt: 1000,
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'reminder_target_type_check',
      ),
      (
        'reminder.repeat_rule = hourly',
        () => db.into(db.reminder).insert(
          ReminderCompanion.insert(
            id: 'r-repeat',
            targetType: 'todo',
            targetId: 'x',
            remindAt: 1000,
            repeatRule: const Value<String>('hourly'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'reminder_repeat_rule_check',
      ),
      (
        'reminder.enabled = 2',
        () => db.into(db.reminder).insert(
          ReminderCompanion.insert(
            id: 'r-enabled',
            targetType: 'todo',
            targetId: 'x',
            remindAt: 1000,
            enabled: const Value<int>(2),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'reminder_enabled_check',
      ),
      (
        'oplog.op = unknown',
        () => db.into(db.oplog).insert(
          OplogCompanion.insert(
            entityTable: 'todo',
            entityId: 'x',
            op: 'unknown',
            lamport: 1,
            deviceId: 'dev-test',
            createdAt: 1000,
          ),
        ),
        'oplog_op_check',
      ),
      (
        'snapshot_meta.kind = weird',
        () => db.into(db.snapshotMeta).insert(
          SnapshotMetaCompanion.insert(
            id: 'sm-kind',
            path: 'C:/snapshots/s1.db',
            kind: 'weird',
            sha256: 'abc',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        'snapshot_meta_kind_check',
      ),
    ];

    for (final (label, insert, constraint) in cases) {
      test('$label 被 $constraint 拦下', () async {
        await expectLater(insert, throwsA(_messageContains(constraint)));
      });
    }

    test('坏数据一条都没进库', () async {
      expect(await db.select(db.planItem).get(), isEmpty);
      expect(await db.select(db.todo).get(), isEmpty);
      expect(await db.select(db.dayLog).get(), isEmpty);
      expect(await db.select(db.habit).get(), isEmpty);
      expect(await db.select(db.oplog).get(), isEmpty);
    });
  });

  group('UNIQUE 约束拦下坏数据', () {
    test('settings 同 key 插入两次报错', () async {
      await db.into(db.settings).insert(
        SettingsCompanion.insert(
          id: 's-1',
          key: 'priority_mode',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );

      await expectLater(
        () => db.into(db.settings).insert(
          SettingsCompanion.insert(
            id: 's-2',
            key: 'priority_mode',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        throwsA(_messageContains('UNIQUE constraint failed')),
      );
    });

    test('day_log 同 date 只能一行', () async {
      await db.into(db.dayLog).insert(
        DayLogCompanion.insert(
          id: 'd-1',
          date: '2026-11-06',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );

      await expectLater(
        () => db.into(db.dayLog).insert(
          DayLogCompanion.insert(
            id: 'd-2',
            date: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        throwsA(_messageContains('UNIQUE constraint failed')),
      );
    });
  });

  group('外键真的生效', () {
    test('PRAGMA foreign_keys = 1', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data['foreign_keys'], 1);
    });

    test('引用不存在的 habit → 报错', () async {
      await expectLater(
        () => db.into(db.habitCheckin).insert(
          HabitCheckinCompanion.insert(
            id: 'hc-orphan',
            habitId: 'no-such-habit',
            date: '2026-11-06',
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        throwsA(_messageContains('FOREIGN KEY constraint failed')),
      );
    });

    test('引用不存在的 project → 报错', () async {
      await expectLater(
        () => db.into(db.todo).insert(
          TodoCompanion.insert(
            id: 't-orphan',
            title: '孤儿待办',
            projectId: const Value<String?>('no-such-project'),
            createdAt: 1000,
            updatedAt: 1000,
            originDeviceId: 'dev-test',
          ),
        ),
        throwsA(_messageContains('FOREIGN KEY constraint failed')),
      );
    });

    test('ON DELETE CASCADE：删 habit → 打卡记录一起没了', () async {
      await db.into(db.habit).insert(
        HabitCompanion.insert(
          id: 'habit-cascade',
          name: '喝水',
          startDate: '2026-11-06',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );
      await db.into(db.habitCheckin).insert(
        HabitCheckinCompanion.insert(
          id: 'hc-cascade',
          habitId: 'habit-cascade',
          date: '2026-11-06',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );

      expect(await db.select(db.habitCheckin).get(), hasLength(1));

      await (db.delete(db.habit)..where((t) => t.id.equals('habit-cascade'))).go();

      expect(await db.select(db.habitCheckin).get(), isEmpty);
    });

    test('ON DELETE SET NULL：删 project → todo.project_id 置空', () async {
      await db.into(db.project).insert(
        ProjectCompanion.insert(
          id: 'project-setnull',
          name: '大项目',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );
      await db.into(db.todo).insert(
        TodoCompanion.insert(
          id: 'todo-setnull',
          title: '挂在大项目下',
          projectId: const Value<String?>('project-setnull'),
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );

      await (db.delete(db.project)
            ..where((t) => t.id.equals('project-setnull')))
          .go();

      final todo = (await db.select(db.todo).get()).single;
      expect(todo.projectId, isNull);
    });
  });
}

/// 断言异常信息里含有指定片段（用来验证「是这条具名约束拦下的」）。
Matcher _messageContains(String needle) => predicate<Object>(
      (e) => e.toString().contains(needle),
      '异常信息包含 "$needle"',
    );
