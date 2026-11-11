// =============================================================================
// core_domain 单测 —— 领域模型无 IO 依赖，必须能在纯 Dart VM 上跑。
// 覆盖重点：
//   1. 每个枚举的取值集合（与 schema_v1.sql 的 CHECK 约束逐字对应）；
//   2. fromCode 的正反用例（未知值必须返回 null 而不是抛异常 —— 同步对端
//      可能来自更高版本 schema，抛异常会导致整个同步批次失败）；
//   3. 关键业务不变量（「今日失守」与 0 分的一致性、引用+快照、合法中断）。
// =============================================================================
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('枚举取值与 schema_v1.sql CHECK 约束一致', () {
    test('Quadrant 取值', () {
      expect(Quadrant.values.map((q) => q.code).toList(), [
        'Q1',
        'Q2',
        'Q3',
        'Q4',
      ]);
    });

    test('PriorityAbc 取值', () {
      expect(PriorityAbc.values.map((p) => p.code).toList(), ['A', 'B', 'C']);
    });

    test('PlanStatus 取值', () {
      expect(PlanStatus.values.map((s) => s.code).toList(), [
        'pending',
        'done',
        'cancelled',
        'deferred',
      ]);
    });

    test('TodoStatus 取值', () {
      expect(TodoStatus.values.map((s) => s.code).toList(), [
        'open',
        'done',
        'cancelled',
        'archived',
      ]);
    });

    test('HabitType 取值', () {
      expect(HabitType.values.map((t) => t.code).toList(), [
        'normal',
        'count',
        'avoid',
        'checklist',
      ]);
    });

    test('HabitScheduleType 取值', () {
      expect(HabitScheduleType.values.map((t) => t.code).toList(), [
        'daily',
        'weekly_n',
        'weekdays',
      ]);
    });

    test('CheckinStatus 取值', () {
      expect(CheckinStatus.values.map((s) => s.code).toList(), [
        'done',
        'skip',
        'failed',
      ]);
    });

    test('LogMode 取值', () {
      expect(LogMode.values.map((m) => m.code).toList(), ['full', 'minimal']);
    });

    test('ProjectStatus 取值', () {
      expect(ProjectStatus.values.map((s) => s.code).toList(), [
        'active',
        'paused',
        'done',
        'cancelled',
      ]);
    });

    test('ReminderTargetType 取值', () {
      expect(ReminderTargetType.values.map((t) => t.code).toList(), [
        'plan_item',
        'todo',
        'habit',
        'project',
      ]);
    });

    test('RepeatRule 取值', () {
      expect(RepeatRule.values.map((r) => r.code).toList(), [
        'none',
        'daily',
        'weekly',
        'monthly',
        'yearly',
      ]);
    });

    test('OplogOp 取值', () {
      expect(OplogOp.values.map((o) => o.code).toList(), ['upsert', 'delete']);
    });

    test('PlanSourceType 取值', () {
      expect(PlanSourceType.values.map((t) => t.code).toList(), [
        'manual',
        'todo',
        'habit',
        'project',
        'increment',
      ]);
    });

    test('PriorityDisplayMode 取值', () {
      expect(PriorityDisplayMode.values.map((m) => m.code).toList(), [
        'quadrant',
        'abc',
      ]);
    });

    test('MoodDimension 覆盖 8 个维度且列名连续', () {
      expect(MoodDimension.values.length, 8);
      expect(MoodDimension.values.map((d) => d.column).toList(), [
        'mood_1',
        'mood_2',
        'mood_3',
        'mood_4',
        'mood_5',
        'mood_6',
        'mood_7',
        'mood_8',
      ]);
      expect(MoodDimension.values.map((d) => d.label).toList(), [
        '认真',
        '快',
        '坚守承诺',
        '保证完成任务',
        '乐观',
        '自信',
        '爱与奉献',
        '决不找借口',
      ]);
    });
  });

  group('fromCode 解析', () {
    test('合法值往返一致（所有枚举）', () {
      for (final q in Quadrant.values) {
        expect(Quadrant.fromCode(q.code), q);
      }
      for (final p in PriorityAbc.values) {
        expect(PriorityAbc.fromCode(p.code), p);
      }
      for (final t in HabitType.values) {
        expect(HabitType.fromCode(t.code), t);
      }
      for (final s in CheckinStatus.values) {
        expect(CheckinStatus.fromCode(s.code), s);
      }
      for (final o in OplogOp.values) {
        expect(OplogOp.fromCode(o.code), o);
      }
    });

    test('未知值返回 null 而非抛异常（跨版本兼容）', () {
      expect(Quadrant.fromCode('Q9'), isNull);
      expect(Quadrant.fromCode(null), isNull);
      expect(PriorityAbc.fromCode('D'), isNull);
      expect(HabitType.fromCode('crazy'), isNull);
      expect(OplogOp.fromCode('merge'), isNull);
    });
  });

  group('四象限语义', () {
    test('重要 = Q1+Q2（完整版日志的「A 类要事」列）', () {
      expect(Quadrant.q1.isImportant, isTrue);
      expect(Quadrant.q2.isImportant, isTrue);
      expect(Quadrant.q3.isImportant, isFalse);
      expect(Quadrant.q4.isImportant, isFalse);
    });

    test('紧急 = Q1+Q3', () {
      expect(Quadrant.q1.isUrgent, isTrue);
      expect(Quadrant.q3.isUrgent, isTrue);
      expect(Quadrant.q2.isUrgent, isFalse);
      expect(Quadrant.q4.isUrgent, isFalse);
    });
  });

  group('心态 8 维度与「今日失守」不变量', () {
    DayLog build(Map<MoodDimension, int> moods, {bool failed = false}) {
      return DayLog(
        id: 'dl-1',
        date: '2026-11-06',
        createdAt: 1760000000000,
        updatedAt: 1760000000000,
        originDeviceId: 'dev-1',
        moods: moods,
        moodFailed: failed,
      );
    }

    test('0 分维度必须对应 moodFailed=true（承接原书 0/10 二元语义）', () {
      expect(
        () => build({MoodDimension.diligent: 0}).validated(),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => build({MoodDimension.diligent: 0}, failed: true).validated(),
        returnsNormally,
      );
    });

    test('无 0 分时可以标记失守（允许用户主观判定）', () {
      expect(
        () => build({MoodDimension.diligent: 8}, failed: true).validated(),
        returnsNormally,
      );
    });

    test('分值超出 0–10 被拒', () {
      expect(
        () => build({MoodDimension.fast: 11}).validated(),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => build({MoodDimension.fast: -1}).validated(),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('非法日期被拒', () {
      expect(
        () => DayLog(
          id: 'x',
          date: '2026-02-30',
          createdAt: 0,
          updatedAt: 0,
          originDeviceId: 'd',
        ).validated(),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('计划条目：引用 + 快照不变量', () {
    PlanItem build({
      PlanSourceType type = PlanSourceType.manual,
      String? sourceTodoId,
    }) {
      return PlanItem(
        id: 'pi-1',
        date: '2026-11-06',
        title: '快照标题',
        createdAt: 0,
        updatedAt: 0,
        originDeviceId: 'dev-1',
        sourceType: type,
        sourceTodoId: sourceTodoId,
      );
    }

    test('sourceType=todo 必须携带 sourceTodoId', () {
      expect(
        () => build(type: PlanSourceType.todo).validated(),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => build(type: PlanSourceType.todo, sourceTodoId: 't-1').validated(),
        returnsNormally,
      );
    });

    test('手工条目无需 sourceTodoId', () {
      expect(() => build().validated(), returnsNormally);
    });

    test('标题为空被拒', () {
      expect(
        () => PlanItem(
          id: 'x',
          date: '2026-11-06',
          title: '   ',
          createdAt: 0,
          updatedAt: 0,
          originDeviceId: 'd',
        ).validated(),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('estMinutes 为负被拒', () {
      expect(
        () => PlanItem(
          id: 'x',
          date: '2026-11-06',
          title: 't',
          estMinutes: -1,
          createdAt: 0,
          updatedAt: 0,
          originDeviceId: 'd',
        ).validated(),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('习惯排程不变量', () {
    Habit build({
      HabitType type = HabitType.normal,
      HabitScheduleType schedule = HabitScheduleType.daily,
      double? targetCount,
      int? weeklyN,
      String weekdays = '',
    }) {
      return Habit(
        id: 'h-1',
        name: '喝水',
        startDate: '2026-01-01',
        createdAt: 0,
        updatedAt: 0,
        originDeviceId: 'dev-1',
        type: type,
        scheduleType: schedule,
        targetCount: targetCount,
        weeklyN: weeklyN,
        weekdays: weekdays,
      );
    }

    test('计数型必须带 targetCount', () {
      expect(
        () => build(type: HabitType.count).validated(),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => build(type: HabitType.count, targetCount: 8).validated(),
        returnsNormally,
      );
    });

    test('weekly_n 排程必须带 weeklyN', () {
      expect(
        () => build(schedule: HabitScheduleType.weeklyN).validated(),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () =>
            build(schedule: HabitScheduleType.weeklyN, weeklyN: 3).validated(),
        returnsNormally,
      );
    });

    test('weekdays 排程必须带合法星期', () {
      expect(
        () => build(schedule: HabitScheduleType.weekdays).validated(),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => build(
          schedule: HabitScheduleType.weekdays,
          weekdays: '1,3,5',
        ).validated(),
        returnsNormally,
      );
    });

    test('parseWeekdays 静默忽略非法项', () {
      expect(Habit.parseWeekdays('1,3,5'), {1, 3, 5});
      expect(Habit.parseWeekdays('1,x,9'), {1});
      expect(Habit.parseWeekdays(''), isEmpty);
    });
  });

  group('合法中断出口', () {
    test('skip 不打断连击，failed 打断', () {
      expect(CheckinStatus.skip.breaksStreak, isFalse);
      expect(CheckinStatus.done.breaksStreak, isFalse);
      expect(CheckinStatus.failed.breaksStreak, isTrue);
    });

    test('habit.pausedUntil 非法日期被拒', () {
      expect(
        () => Habit(
          id: 'h',
          name: 'n',
          startDate: '2026-01-01',
          pausedUntil: '2026-13-01',
          createdAt: 0,
          updatedAt: 0,
          originDeviceId: 'd',
        ).validated(),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('oplog 有效性', () {
    test('upsert 必须有 payload', () {
      final e = OplogEntry(
        id: 1,
        entityTable: 'todo',
        entityId: 't-1',
        op: OplogOp.upsert,
        payload: null,
        lamport: 1,
        deviceId: 'dev-1',
        createdAt: 0,
      );
      expect(e.isValid, isFalse);
    });

    test('delete 可以无 payload', () {
      final e = OplogEntry(
        id: 1,
        entityTable: 'todo',
        entityId: 't-1',
        op: OplogOp.delete,
        payload: null,
        lamport: 1,
        deviceId: 'dev-1',
        createdAt: 0,
      );
      expect(e.isValid, isTrue);
    });
  });

  group('墓碑语义', () {
    test('deletedAt 非空即已删除', () {
      final t = Todo(
        id: 't-1',
        title: 'x',
        createdAt: 0,
        updatedAt: 0,
        originDeviceId: 'd',
        deletedAt: 1760000000000,
      );
      expect(t.isDeleted, isTrue);
      expect(
        Todo(
          id: 't-1',
          title: 'x',
          createdAt: 0,
          updatedAt: 0,
          originDeviceId: 'd',
        ).isDeleted,
        isFalse,
      );
    });
  });
}
