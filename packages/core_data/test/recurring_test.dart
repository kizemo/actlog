// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · 循环任务仓储门禁（schema v2）
// =============================================================================
// 验的是**幂等**与**掩码命中**两件事 —— 它们都是「错了不会报错、只是悄悄少排
// 或多排一条」的静默错误，只能靠断言钉住：
//   1. 命中掩码的日期物化出 1 条 plan_item（带 planned_start / planned_end）；
//   2. 同一天重复物化返回 0，plan_item 与 recurring_occurrence 都仍然只有 1 条；
//   3. 不命中的星期不物化；
//   4. 停用后不再物化，但已生成的条目**不被撤销**；
//   5. 物化出来的 plan_item 是同步表 ⇒ 必须落 oplog。
// =============================================================================

import 'dart:convert';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const String _device = 'dev-test';

/// 固定的日历日：2026-11-11 是周三。
const String _date = '2026-11-11';
const int _wednesday = 3;

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

  test('create 落库：掩码 / 起始时刻 / 时长 / 备注都保存正确', () async {
    final String id = await repos.recurring.create(
      title: '晨间复盘',
      weekdayMask: WeekdayMask.workdays,
      startMinute: 570,
      durationMinutes: 45,
      note: '先写三行',
    );

    final rows = await repos.recurring.listActive();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.id, id);
    expect(row.title, '晨间复盘');
    expect(row.weekdayMask, WeekdayMask.workdays);
    expect(row.startMinute, 570);
    expect(row.durationMinutes, 45);
    expect(row.note, '先写三行');
    expect(row.active, 1);
    expect(row.deletedAt, isNull);
  });

  test('create 的校验在仓储层也生效（不只靠 UI）', () async {
    await expectLater(
      repos.recurring.create(
        title: '   ',
        weekdayMask: WeekdayMask.workdays,
        startMinute: 0,
      ),
      throwsArgumentError,
    );
    await expectLater(
      repos.recurring.create(
        title: '空掩码',
        weekdayMask: WeekdayMask.none,
        startMinute: 0,
      ),
      throwsArgumentError,
    );
    await expectLater(
      repos.recurring.create(
        title: '越界时刻',
        weekdayMask: WeekdayMask.all,
        startMinute: minutesPerDay,
      ),
      throwsArgumentError,
    );
    await expectLater(
      repos.recurring.create(
        title: '零时长',
        weekdayMask: WeekdayMask.all,
        startMinute: 0,
        durationMinutes: 0,
      ),
      throwsArgumentError,
    );
    expect(await repos.recurring.listActive(), isEmpty);
  });

  test('命中掩码的日期物化成带时段的 plan_item', () async {
    final String taskId = await repos.recurring.create(
      title: '晨间复盘',
      weekdayMask: WeekdayMask.bitOf(_wednesday),
      startMinute: 570,
      durationMinutes: 30,
    );

    final int created = await repos.recurring.materializeDate(_date);
    expect(created, 1);

    final items = await repos.planItem.listByDate(_date);
    expect(items, hasLength(1));
    final item = items.single;
    expect(item.title, '晨间复盘');
    expect(item.sourceId, taskId);
    expect(item.estMinutes, 30);
    expect(item.isHabitRef, 0);

    final DateTime dayStart = DateTime(2026, 11, 11);
    expect(
      item.plannedStart,
      dayStart.add(const Duration(minutes: 570)).millisecondsSinceEpoch,
    );
    expect(
      item.plannedEnd,
      dayStart.add(const Duration(minutes: 600)).millisecondsSinceEpoch,
    );
  });

  test('同一天重复物化是幂等的（返回 0，不产生第二条）', () async {
    await repos.recurring.create(
      title: '晨间复盘',
      weekdayMask: WeekdayMask.bitOf(_wednesday),
      startMinute: 570,
    );

    expect(await repos.recurring.materializeDate(_date), 1);
    expect(await repos.recurring.materializeDate(_date), 0);
    expect(await repos.recurring.materializeDate(_date), 0);

    expect(await repos.planItem.listByDate(_date), hasLength(1));
    expect(await repos.recurring.listOccurrencesByDate(_date), hasLength(1));
  });

  test('不命中的星期不物化', () async {
    await repos.recurring.create(
      title: '只在周日照看',
      weekdayMask: WeekdayMask.sunday,
      startMinute: 600,
    );

    expect(await repos.recurring.materializeDate(_date), 0);
    expect(await repos.planItem.listByDate(_date), isEmpty);
    expect(await repos.recurring.listOccurrencesByDate(_date), isEmpty);
  });

  test('停用后不再物化新的一天，但已生成的条目不被撤销', () async {
    final String taskId = await repos.recurring.create(
      title: '每天读书',
      weekdayMask: WeekdayMask.all,
      startMinute: 1200,
    );
    expect(await repos.recurring.materializeDate(_date), 1);

    await repos.recurring.setActive(taskId, false);
    expect(await repos.recurring.listActive(), isEmpty);

    // 同一天再物化：规则已停用 ⇒ 一条都不新建。
    expect(await repos.recurring.materializeDate(_date), 0);
    // 已经排进计划的条目仍在（停用不回溯撤单）。
    expect(await repos.planItem.listByDate(_date), hasLength(1));
  });

  test('archive 是软删：规则不再启用，墓碑可查', () async {
    final String taskId = await repos.recurring.create(
      title: '将要归档',
      weekdayMask: WeekdayMask.all,
      startMinute: 480,
    );
    await repos.recurring.archive(taskId);

    expect(await repos.recurring.listActive(), isEmpty);
    final row = await (db.select(db.recurringTask)
          ..where((t) => t.id.equals(taskId)))
        .getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.active, 0);
  });

  test('watchOccurrencesByDate 给出时段文本与规则行', () async {
    await repos.recurring.create(
      title: '晨间复盘',
      weekdayMask: WeekdayMask.bitOf(_wednesday),
      startMinute: 570,
      durationMinutes: 30,
    );
    await repos.recurring.materializeDate(_date);

    final views = await repos.recurring.watchOccurrencesByDate(_date).first;
    expect(views, hasLength(1));
    final view = views.single;
    expect(view.task.title, '晨间复盘');
    expect(view.timeLabel, '09:30–10:00');
    expect(view.endMinute, 600);
    expect(view.occurrence.date, _date);
    expect(view.occurrence.planItemId, isNotNull);
  });

  test('时长跨越 23:59 时 endMinute 收口到 23:59', () async {
    await repos.recurring.create(
      title: '深夜收尾',
      weekdayMask: WeekdayMask.bitOf(_wednesday),
      startMinute: 1430,
      durationMinutes: 60,
    );
    await repos.recurring.materializeDate(_date);

    final views = await repos.recurring.listOccurrencesByDate(_date);
    expect(views.single.endMinute, minutesPerDay - 1);
    expect(views.single.timeLabel, '23:50–23:59');
  });

  test('规则、物化凭证、计划条目三者都进 oplog（同步缺口已补齐）', () async {
    final String taskId = await repos.recurring.create(
      title: '晨间复盘',
      weekdayMask: WeekdayMask.bitOf(_wednesday),
      startMinute: 570,
    );
    expect(await repos.recurring.materializeDate(_date), 1);

    final oplog = await db.select(db.oplog).get();
    final taskEntries =
        oplog.where((o) => o.entityTable == 'recurring_task').toList();
    final occurrenceEntries =
        oplog.where((o) => o.entityTable == 'recurring_occurrence').toList();
    final planEntries =
        oplog.where((o) => o.entityTable == 'plan_item').toList();

    // 规则：create 一笔；实例：物化一笔；计划条目：createScheduled 一笔。
    expect(taskEntries, hasLength(1));
    expect(taskEntries.single.entityId, taskId);
    expect(taskEntries.single.op, 'upsert');
    expect(taskEntries.single.deviceId, _device);
    expect(occurrenceEntries, hasLength(1));
    expect(occurrenceEntries.single.op, 'upsert');
    expect(occurrenceEntries.single.deviceId, _device);
    expect(planEntries, hasLength(1));

    // payload 是字段级 diff：凭证必须带上 task_id / date / plan_item_id，
    // 否则对端拉回来是一行空壳凭证，照样会重复物化。
    final occurrencePayload =
        jsonDecode(occurrenceEntries.single.payload!) as Map<String, Object?>;
    expect(occurrencePayload['task_id'], taskId);
    expect(occurrencePayload['date'], _date);
    expect(occurrencePayload['plan_item_id'], planEntries.single.entityId);

    // 同一天再物化：幂等 ⇒ 计划条目不变、账本不新增任何行。
    expect(await repos.recurring.materializeDate(_date), 0);
    expect(await repos.planItem.listByDate(_date), hasLength(1));
    expect(await repos.recurring.listOccurrencesByDate(_date), hasLength(1));
    final after = await db.select(db.oplog).get();
    expect(after, hasLength(oplog.length));
    expect(
      after.where((o) => o.entityTable == 'recurring_occurrence'),
      hasLength(1),
    );
  });
}