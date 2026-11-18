// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · 习惯排程与自动进计划门禁（Task 38 · W2）
// =============================================================================
// 这些判定都是「错了不报错、只是悄悄多排或少排」的静默错误，只能靠断言钉住：
//   1. 存量语义不变：daily 无 weekly_n ⇒ 每天命中；weekly_n 无 weekdays ⇒ 每天命中；
//   2. daily + weekly_n = N ⇒ 以 start_date 为第 0 天，间隔 N 天命中；
//   3. weekly_n + weekdays ⇒ 每隔 N 周的这些星期命中，周基准是 start_date 那周的周一；
//   4. weekdays ⇒ 只按星期命中，忽略 weekly_n；
//   5. materializeUpcoming 只为间隔型习惯生成条目，字段正确，且重复调用幂等；
//   6. daysBetween / mondayOf / weeksBetween 的边界与非法输入。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:test/test.dart';

const String _device = 'dev-habit-schedule';

/// 固定的日历日：2026-11-09 是周一，2026-11-11 是周三。
const String _monday = '2026-11-09';
const String _wednesday = '2026-11-11';

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

  /// 建一条习惯并读回落库后的行，确保判定用的是真实列值而不是入参。
  Future<HabitData> newHabit({
    String name = '习惯',
    String scheduleType = 'daily',
    int? weeklyN,
    String weekdays = '',
    String startDate = _monday,
  }) async {
    final String id = await repos.habit.create(
      name: name,
      scheduleType: scheduleType,
      weeklyN: weeklyN,
      weekdays: weekdays,
      startDate: startDate,
    );
    final List<HabitData> all = await repos.habit.listActive();
    return all.firstWhere((HabitData h) => h.id == id);
  }

  group('isScheduledFor · 存量语义不变', () {
    test('daily 且 weekly_n 为空 ⇒ 每天都命中', () async {
      final HabitData habit = await newHabit();

      expect(HabitRepository.isScheduledFor(habit, _monday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, _wednesday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-15'), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2027-03-01'), isTrue);
    });

    test('daily 且 weekly_n = 1 ⇒ 仍每天命中', () async {
      final HabitData habit = await newHabit(weeklyN: 1);

      expect(HabitRepository.isScheduledFor(habit, _monday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, _wednesday), isTrue);
    });

    test('weekly_n 且 weekdays 为空 ⇒ 每天都命中（用户自己挑日子）', () async {
      final HabitData habit = await newHabit(
        scheduleType: 'weekly_n',
        weeklyN: 2,
      );

      expect(HabitRepository.isScheduledFor(habit, _monday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, _wednesday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-15'), isTrue);
    });

    test('日期非法 ⇒ false，不抛异常', () async {
      final HabitData habit = await newHabit();

      expect(HabitRepository.isScheduledFor(habit, '2026-13-01'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, ''), isFalse);
    });
  });

  group('isScheduledFor · 每隔 N 天', () {
    test('daily + 3 ⇒ 第 0/3/6 天命中，第 1/2 天不命中', () async {
      final HabitData habit = await newHabit(weeklyN: 3);

      expect(HabitRepository.isScheduledFor(habit, _monday), isTrue); // +0
      expect(HabitRepository.isScheduledFor(habit, '2026-11-10'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-11'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-12'), isTrue); // +3
      expect(HabitRepository.isScheduledFor(habit, '2026-11-15'), isTrue); // +6
      expect(HabitRepository.isScheduledFor(habit, '2026-11-16'), isFalse);
    });

    test('起始日之前的日期不命中', () async {
      final HabitData habit = await newHabit(weeklyN: 3);

      expect(HabitRepository.isScheduledFor(habit, '2026-11-08'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-01'), isFalse);
    });
  });

  group('isScheduledFor · 每隔 N 周', () {
    test('weekly_n + 2 + 周三 ⇒ 隔周周三命中，基准是起始日那周的周一', () async {
      final HabitData habit = await newHabit(
        scheduleType: 'weekly_n',
        weeklyN: 2,
        weekdays: '3',
        startDate: _wednesday,
      );

      expect(HabitRepository.isScheduledFor(habit, _wednesday), isTrue); // 第 0 周
      expect(HabitRepository.isScheduledFor(habit, '2026-11-18'), isFalse); // 第 1 周
      expect(HabitRepository.isScheduledFor(habit, '2026-11-25'), isTrue); // 第 2 周
      expect(HabitRepository.isScheduledFor(habit, '2026-12-09'), isTrue); // 第 4 周
      expect(HabitRepository.isScheduledFor(habit, '2026-12-02'), isFalse); // 第 3 周
      // 同一周的非指定星期一律不命中。
      expect(HabitRepository.isScheduledFor(habit, '2026-11-12'), isFalse);
    });

    test('起始日不是周一时，周基准仍落在起始日那周的周一', () async {
      // 起始日 2026-11-11（周三），周基准 = 2026-11-09（周一）。
      // 若误用「起始日 + 7N 天」，2026-11-27（周五）会被判成第 2 周内的一天，
      // 但它所在周的周一是 2026-11-23，与基准相差 2 周，仍应命中 —— 这里用
      // 2026-11-30（周一，差 3 周）做判别：正确实现不命中。
      final HabitData habit = await newHabit(
        scheduleType: 'weekly_n',
        weeklyN: 2,
        weekdays: '1',
        startDate: _wednesday,
      );

      expect(HabitRepository.isScheduledFor(habit, '2026-11-23'), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-30'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-16'), isFalse);
    });

    test('weekly_n + weekdays 为空 ⇒ 保持存量「每天命中」', () async {
      final HabitData habit = await newHabit(
        scheduleType: 'weekly_n',
        weeklyN: 3,
      );

      expect(HabitRepository.isScheduledFor(habit, _monday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, _wednesday), isTrue);
    });
  });

  group('isScheduledFor · 每周指定几天', () {
    test("weekdays = '1,3,5' ⇒ 只周一/三/五命中", () async {
      final HabitData habit = await newHabit(
        scheduleType: 'weekdays',
        weekdays: '1,3,5',
      );

      expect(HabitRepository.isScheduledFor(habit, _monday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, _wednesday), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-13'), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-10'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-12'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-14'), isFalse);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-15'), isFalse);
      // 跨周仍然只认星期。
      expect(HabitRepository.isScheduledFor(habit, '2026-11-16'), isTrue);
    });

    test('weekdays 型忽略 weekly_n', () async {
      final HabitData habit = await newHabit(
        scheduleType: 'weekdays',
        weeklyN: 2,
        weekdays: '1,3,5',
      );

      expect(HabitRepository.isScheduledFor(habit, '2026-11-16'), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-11'), isTrue);
      expect(HabitRepository.isScheduledFor(habit, '2026-11-10'), isFalse);
    });
  });

  group('isIntervalSchedule', () {
    test('每天 / 每周指定几天 / 存量 weekly_n 都不算间隔型', () async {
      expect(HabitRepository.isIntervalSchedule(await newHabit()), isFalse);
      expect(
        HabitRepository.isIntervalSchedule(
          await newHabit(scheduleType: 'weekdays', weekdays: '1,3,5'),
        ),
        isFalse,
      );
      expect(
        HabitRepository.isIntervalSchedule(
          await newHabit(scheduleType: 'weekly_n', weeklyN: 2),
        ),
        isFalse,
      );
    });

    test('每隔 N 天（N ≥ 2）与每隔 N 周（带星期）算间隔型', () async {
      expect(
        HabitRepository.isIntervalSchedule(await newHabit(weeklyN: 2)),
        isTrue,
      );
      expect(
        HabitRepository.isIntervalSchedule(
          await newHabit(scheduleType: 'weekly_n', weeklyN: 2, weekdays: '3'),
        ),
        isTrue,
      );
    });
  });

  group('materializeUpcoming', () {
    test('每隔 3 天 ⇒ 14 天窗口内生成 5 条，字段全部正确', () async {
      final HabitData habit = await newHabit(name: '晨间拉伸', weeklyN: 3);

      final List<String> created = await repos.habit.materializeUpcoming(
        habitId: habit.id,
        fromDate: _monday,
      );

      expect(created, hasLength(5));
      expect(created.every((String id) => id.isNotEmpty), isTrue);
      // 按日期升序返回。
      expect(
        created.toSet(),
        hasLength(5),
        reason: '每条都应是新写入的 plan_item id',
      );

      final List<PlanItemData> rows = await repos.planItem.listByDate(_monday);
      expect(rows, hasLength(1));
      final PlanItemData row = rows.single;
      expect(row.title, '晨间拉伸');
      expect(row.sourceType, 'habit');
      expect(row.sourceId, habit.id);
      expect(row.isHabitRef, 1);
      expect(row.plannedStart, 540);
      expect(row.plannedEnd, 570);
      expect(row.date, _monday);

      // 14 天窗口 = 2026-11-09 .. 2026-11-22，命中日是 +0/+3/+6/+9/+12。
      expect(await repos.planItem.listByDate('2026-11-12'), hasLength(1));
      expect(await repos.planItem.listByDate('2026-11-15'), hasLength(1));
      expect(await repos.planItem.listByDate('2026-11-18'), hasLength(1));
      expect(await repos.planItem.listByDate('2026-11-21'), hasLength(1));
      expect(await repos.planItem.listByDate('2026-11-22'), isEmpty);
      expect(await repos.planItem.listByDate('2026-11-10'), isEmpty);
    });

    test('重复调用幂等：第二次返回空，条目数不变', () async {
      final HabitData habit = await newHabit(weeklyN: 3);

      final List<String> first = await repos.habit.materializeUpcoming(
        habitId: habit.id,
        fromDate: _monday,
      );
      expect(first, hasLength(5));

      final List<String> second = await repos.habit.materializeUpcoming(
        habitId: habit.id,
        fromDate: _monday,
      );
      expect(second, isEmpty);
      expect(await repos.planItem.listByDate(_monday), hasLength(1));
      expect(await repos.planItem.listByDate('2026-11-12'), hasLength(1));
    });

    test('非间隔型排程不生成任何条目', () async {
      final HabitData habit = await newHabit();

      final List<String> created = await repos.habit.materializeUpcoming(
        habitId: habit.id,
        fromDate: _monday,
      );

      expect(created, isEmpty);
      expect(await repos.planItem.listByDate(_monday), isEmpty);
    });

    test('起始日在窗口之后 ⇒ 一条都不生成', () async {
      final HabitData habit = await newHabit(
        weeklyN: 2,
        startDate: '2027-01-01',
      );

      final List<String> created = await repos.habit.materializeUpcoming(
        habitId: habit.id,
        fromDate: _monday,
      );

      expect(created, isEmpty);
      expect(await repos.planItem.listByDate(_monday), isEmpty);
    });

    test('习惯不存在 ⇒ 抛 StateError', () async {
      expect(
        () => repos.habit.materializeUpcoming(
          habitId: 'not-a-real-habit',
          fromDate: _monday,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('已归档习惯不生成条目', () async {
      final HabitData habit = await newHabit(weeklyN: 2);
      await repos.habit.archive(habit.id);

      final List<String> created = await repos.habit.materializeUpcoming(
        habitId: habit.id,
        fromDate: _monday,
      );

      expect(created, isEmpty);
      expect(await repos.planItem.listByDate(_monday), isEmpty);
    });
  });

  group('日期工具', () {
    test('daysBetween 按日历日计差，非法日期返回 null', () {
      expect(HabitRepository.daysBetween(_monday, _wednesday), 2);
      expect(HabitRepository.daysBetween(_wednesday, _monday), -2);
      expect(HabitRepository.daysBetween(_monday, _monday), 0);
      expect(HabitRepository.daysBetween('2026-11-09', '2027-11-09'), 365);
      expect(HabitRepository.daysBetween('2026-13-01', _monday), isNull);
    });

    test('mondayOf 落在本周周一，周日仍算本周', () {
      expect(HabitRepository.mondayOf(_monday), _monday);
      expect(HabitRepository.mondayOf(_wednesday), _monday);
      expect(HabitRepository.mondayOf('2026-11-15'), _monday); // 周日
      expect(HabitRepository.mondayOf('2026-11-16'), '2026-11-16');
    });

    test('weeksBetween 以所在周周一为基准', () {
      expect(HabitRepository.weeksBetween(_monday, _monday), 0);
      expect(HabitRepository.weeksBetween(_wednesday, '2026-11-15'), 0);
      expect(HabitRepository.weeksBetween(_wednesday, '2026-11-16'), 1);
      expect(HabitRepository.weeksBetween(_wednesday, '2026-11-25'), 2);
    });
  });
}
