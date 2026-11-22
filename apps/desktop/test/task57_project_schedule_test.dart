// apps/desktop/test/task57_project_schedule_test.dart
//
// Task 57 · A（L1 排期联动）：项目「＋ 排进今天」与增量「→ 今天」共用**同一条**
// 落库路径，落出来的 `plan_item` 靠 `source_type` / `source_id` 区分来源。
//
// 本文件钉四条：
//   A1：项目侧排期 ⇒ `source_type = 'project'`、`source_id = 项目 id`，
//       **不挂** `source_todo_id`（项目侧不经过待办池）；
//   A2：增量侧排期 ⇒ `source_type = 'increment'`、`source_id = 增量 id`；
//   A3：`listByProject` 同时覆盖两态，且不串到别的项目；
//   A4：在今日方格上删掉排出的计划行，**不连带删增量**（流水不是计划行的附属）。
//
// 判据全是库里的真实行，不是 UI 像素。
import 'package:actlog/src/data/project_store.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart' show PlanSourceType;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late ProjectStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task57-schedule-test');
    store = ProjectStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('A1：项目「排进今天」⇒ source_type=project、source_id=项目 id、无待办指针', () async {
    final String projectId = await store.createProject(name: '甲');

    await store.scheduleToDay(
      date: '2026-11-20',
      sourceType: PlanSourceType.project,
      sourceId: projectId,
      title: '甲',
    );

    final List<PlanItemData> rows = await db.select(db.planItem).get();
    expect(rows.length, 1);
    final PlanItemData row = rows.single;
    expect(row.date, '2026-11-20');
    expect(row.title, '甲');
    expect(row.sourceType, 'project');
    expect(row.sourceId, projectId);
    expect(row.sourceTodoId, isNull, reason: '项目侧排期不经过待办池');
    expect(row.status, 'pending');
    expect(row.isHabitRef, 0);
    // 默认时段：接当日已有计划行之后（空日 ⇒ 08:00 起，时长 30 分钟）。
    expect(row.plannedStart, 8 * 60);
    expect(row.plannedEnd, 8 * 60 + 30);
  });

  test('A2：增量「→ 今天」⇒ source_type=increment、source_id=增量 id', () async {
    final String projectId = await store.createProject(name: '乙');
    final String incrementId = await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      progress: '写完了数据层',
    );

    await store.scheduleToDay(
      date: '2026-11-20',
      sourceType: PlanSourceType.increment,
      sourceId: incrementId,
      title: '写完了数据层',
    );

    final PlanItemData row = (await db.select(db.planItem).get()).single;
    expect(row.sourceType, 'increment');
    expect(row.sourceId, incrementId);
    expect(row.sourceId, isNot(projectId), reason: '增量行指向增量，不是项目');
  });

  test('A3：listByProject 同时覆盖两态，且不串到别的项目', () async {
    final String a = await store.createProject(name: '甲');
    final String b = await store.createProject(name: '乙');
    final String inc = await store.appendIncrement(
      projectId: a,
      date: '2026-11-20',
      progress: '推进',
    );

    await store.scheduleToDay(
      date: '2026-11-20',
      sourceType: PlanSourceType.project,
      sourceId: a,
      title: '甲',
    );
    await store.scheduleToDay(
      date: '2026-11-21',
      sourceType: PlanSourceType.increment,
      sourceId: inc,
      title: '推进',
    );
    await store.scheduleToDay(
      date: '2026-11-20',
      sourceType: PlanSourceType.project,
      sourceId: b,
      title: '乙',
    );

    final List<ScheduledItem> items = await store.listByProject(a);
    expect(
      items.map((ScheduledItem item) => item.sourceId).toSet(),
      <String>{a, inc},
      reason: '甲自己的行 + 甲增量的行，不能混进乙',
    );
    expect(
      items.map((ScheduledItem item) => item.date).toList(),
      <String>['2026-11-20', '2026-11-21'],
      reason: '按日期升序',
    );

    final List<ScheduledItem> other = await store.listByProject(b);
    expect(other.length, 1);
    expect(other.single.sourceId, b);
  });

  test('A4：删掉排出的计划行 ⇒ 增量仍在（流水不随计划行消失）', () async {
    final String projectId = await store.createProject(name: '丙');
    final String planId = await store.scheduleToDay(
      date: '2026-11-20',
      sourceType: PlanSourceType.project,
      sourceId: projectId,
      title: '丙',
    );
    final String incrementId = await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      progress: '推进',
    );

    // 当日已有指向本项目的计划行 ⇒ 增量自动挂上指针。
    final IncrementRow before = (await store.listIncrements(projectId)).single;
    expect(before.planItemId, planId);

    await repos.planItem.softDelete(planId);

    final List<IncrementRow> after = await store.listIncrements(projectId);
    expect(after.length, 1, reason: '增量是流水，不该被连带删掉');
    expect(after.single.id, incrementId);
    expect(
      await store.listByProject(projectId),
      isEmpty,
      reason: '删掉的计划行不再出现在项目排期里',
    );
  });
}