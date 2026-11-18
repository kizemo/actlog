// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · 循环任务「重复」回归门禁（Task 40 A1.2）
// =============================================================================
// 与 `recurring_test.dart` 分开：那个文件是原有的幂等 / 掩码门禁（12 个用例，
// 本轮一个字都不动）。这里只钉住本轮新增的两条行为：
//   1. occurrence 已是墓碑 ⇒ 同一天不会再物化出重复项，且**不会抛唯一约束**；
//   2. 删除由循环生成的 plan_item ⇒ 对应 occurrence 一并软删，右栏不再列它，
//      而且后续物化不会把它「复活」。
// 判据来源：`recurring_occurrence` 上的 `UNIQUE (task_id, date)` 是整表唯一约束
// （packages/core_db/lib/src/tables.dart:1117-1119），墓碑行仍占槽位。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Value;
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

  Future<String> createWednesdayTask({
    String title = '晨间复盘',
    int startMinute = 570,
  }) {
    return repos.recurring.create(
      title: title,
      weekdayMask: WeekdayMask.bitOf(_wednesday),
      startMinute: startMinute,
      durationMinutes: 30,
    );
  }

  test('occurrence 已是墓碑：再次物化返回 0，不撞唯一约束也不产生重复项', () async {
    await createWednesdayTask();
    expect(await repos.recurring.materializeDate(_date), 1);
    expect(await repos.planItem.listByDate(_date), hasLength(1));

    // 绕过仓储层直接给 occurrence 写墓碑：模拟「墓碑行仍占着 (task_id, date)
    // 唯一槽位」。若 _materializeOne 按 deletedAt.isNull() 过滤后重建，
    // 这一步之后的物化会抛 UNIQUE 约束 —— 正是本用例要拦住的回归。
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final RecurringOccurrenceData occurrence =
        await db.select(db.recurringOccurrence).getSingle();
    await (db.update(db.recurringOccurrence)
          ..where((t) => t.id.equals(occurrence.id)))
        .write(
      RecurringOccurrenceCompanion(
        deletedAt: Value(ts),
        updatedAt: Value(ts),
        rev: Value(occurrence.rev + 1),
      ),
    );

    expect(await repos.recurring.materializeDate(_date), 0);
    expect(await repos.planItem.listByDate(_date), hasLength(1));
    expect(
      await db.select(db.recurringOccurrence).get(),
      hasLength(1),
      reason: '墓碑行的槽位不能被第二条实例复用',
    );
  });

  test('删除循环生成的 plan_item：occurrence 一并软删，右栏不再返回它', () async {
    await createWednesdayTask();
    expect(await repos.recurring.materializeDate(_date), 1);
    final PlanItemData item = (await repos.planItem.listByDate(_date)).single;
    expect(await repos.recurring.listOccurrencesByDate(_date), hasLength(1));

    await repos.planItem.softDelete(item.id);

    expect(
      await repos.recurring.listOccurrencesByDate(_date),
      isEmpty,
      reason: 'occurrence 未联动软删时，右栏会继续列出网格里已删掉的条目',
    );
    final RecurringOccurrenceData occurrence =
        await db.select(db.recurringOccurrence).getSingle();
    expect(occurrence.deletedAt, isNotNull);

    // 不复活：墓碑仍占槽位 ⇒ 再物化返回 0，网格里也不会重新长出这一行。
    expect(await repos.recurring.materializeDate(_date), 0);
    expect(await repos.planItem.listByDate(_date), isEmpty);
  });

  test('联动软删只影响指向被删条目的那一行 occurrence', () async {
    await createWednesdayTask(title: '晨间复盘', startMinute: 570);
    await createWednesdayTask(title: '午后散步', startMinute: 840);
    expect(await repos.recurring.materializeDate(_date), 2);
    expect(await repos.recurring.listOccurrencesByDate(_date), hasLength(2));

    final PlanItemData first = (await repos.planItem.listByDate(_date)).first;
    await repos.planItem.softDelete(first.id);

    final List<RecurringOccurrenceView> left =
        await repos.recurring.listOccurrencesByDate(_date);
    expect(left, hasLength(1));
    expect(left.single.task.title, '午后散步');
  });
}