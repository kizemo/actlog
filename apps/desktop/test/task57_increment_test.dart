// apps/desktop/test/task57_increment_test.dart
//
// Task 57 · B（L3 推进联动）：增量是**流水**，只追加、永不改写。
//
// 本文件钉三条：
//   B1：连写两次就是两行，旧行的 `progress` / `updated_at` 一个字都不动
//       —— 这是「不可编辑」的判别性用例（任何 update 式实现都会挂在这条）；
//   B2：当日有指向本项目的计划行 ⇒ 新行自动挂 `plan_item_id`，没有就 `NULL`；
//   B3：三列都可以留空（只写「卡在哪」也算一条增量），列表按日期倒序。
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
    repos = ActLogRepositories(db, deviceId: 'task57-increment-test');
    store = ProjectStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('B1：只能追加 —— 写两次是两行，既有行原样不动', () async {
    final String projectId = await store.createProject(name: '甲');

    final String first = await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      progress: '第一版',
    );
    final ProjectIncrementData before =
        (await db.select(db.projectIncrement).get()).single;

    final String second = await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      progress: '更正第一版',
    );

    expect(second, isNot(first));
    final List<ProjectIncrementData> rows =
        await db.select(db.projectIncrement).get();
    expect(rows.length, 2, reason: '两次追加就是两行');

    final ProjectIncrementData firstRow =
        rows.firstWhere((ProjectIncrementData row) => row.id == first);
    expect(firstRow.progress, '第一版', reason: '旧行不能被后来的追加改掉');
    expect(firstRow.updatedAt, before.updatedAt, reason: '旧行的时间戳也不能动');
  });

  test('B2：当日有指向本项目的计划行就挂 plan_item_id，否则 NULL', () async {
    final String projectId = await store.createProject(name: '乙');
    final String planId = await store.scheduleToDay(
      date: '2026-11-20',
      sourceType: PlanSourceType.project,
      sourceId: projectId,
      title: '乙',
    );

    final String linked = await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      progress: '有排期',
    );
    final String unlinked = await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-19',
      progress: '没排期',
    );

    final List<IncrementRow> rows = await store.listIncrements(projectId);
    expect(
      rows.firstWhere((IncrementRow row) => row.id == linked).planItemId,
      planId,
    );
    expect(
      rows.firstWhere((IncrementRow row) => row.id == unlinked).planItemId,
      isNull,
      reason: '那天没有指向本项目的计划行 ⇒ 指针为空，不硬编一个',
    );
  });

  test('B3：三列都可留空；列表按日期倒序（同日新的在前）', () async {
    final String projectId = await store.createProject(name: '丙');

    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-18',
      progress: '前两天',
    );
    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      blockers: '卡在等审批',
    );
    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      nextStep: '明天先做导入',
    );

    final List<IncrementRow> rows = await store.listIncrements(projectId);
    expect(rows.length, 3);
    expect(rows.first.date, '2026-11-20');
    expect(rows.last.date, '2026-11-18');
    expect(rows.first.progress, isEmpty, reason: '只写了下一步也算一条增量');
    expect(rows.first.nextStep, '明天先做导入');
    expect(rows[1].blockers, '卡在等审批');
  });
}