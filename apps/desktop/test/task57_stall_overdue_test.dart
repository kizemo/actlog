// apps/desktop/test/task57_stall_overdue_test.dart
//
// Task 57 · B3（停滞提示）+ C（里程碑到期标记）。
//
// 本文件钉四条：
//   C1：连续 ≥3 天没有增量 ⇒ 进停滞列表，天数按**最近一条增量的日期**算；
//   C2：不足 3 天 / 今天刚写过 ⇒ 不提示（不催刚推过一步的项目）；
//   C3：门槛可调（默认 3）；
//   C4：`milestoneOverdue` 三分支 —— 目标日已过且未达成才算逾期，
//       **当天到期不算逾期**，已达成 / 没排期都算不逾期。
import 'package:actlog/src/data/project_store.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late ProjectStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task57-stall-overdue-test');
    store = ProjectStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('C1：连续 ≥3 天无增量 ⇒ 进停滞列表，天数按最近增量日期算', () async {
    final String projectId = await store.createProject(name: '甲');
    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-15',
      progress: '最后一次推进',
    );

    final List<ProjectStall> stalls = await store.stalledProjects(
      todayIso: '2026-11-20',
    );
    expect(stalls.length, 1);
    expect(stalls.single.projectId, projectId);
    expect(stalls.single.name, '甲');
    expect(stalls.single.daysSinceIncrement, 5);
  });

  test('C2：不足 3 天 / 今天刚写过 ⇒ 不提示', () async {
    final String projectId = await store.createProject(name: '乙');

    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-18',
      progress: '两天前',
    );
    expect(
      await store.stalledProjects(todayIso: '2026-11-20'),
      isEmpty,
      reason: '2 天不到门槛',
    );

    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-20',
      progress: '今天推过',
    );
    expect(
      await store.stalledProjects(todayIso: '2026-11-20'),
      isEmpty,
      reason: '今天推过一步，不该被催',
    );
  });

  test('C3：门槛可调（默认 3 天）', () async {
    final String projectId = await store.createProject(name: '丙');
    await store.appendIncrement(
      projectId: projectId,
      date: '2026-11-18',
      progress: '两天前',
    );

    expect(
      await store.stalledProjects(todayIso: '2026-11-20', thresholdDays: 2),
      isNotEmpty,
      reason: '门槛降到 2 天就该提示',
    );
    expect(
      await store.stalledProjects(todayIso: '2026-11-20'),
      isEmpty,
      reason: '默认门槛仍是 3 天',
    );
  });

  test('C4：milestoneOverdue 三分支', () {
    MilestoneRow row(String? target, {int? achieved}) => MilestoneRow(
      id: 'm-1',
      projectId: 'p-1',
      title: '交付一版',
      targetDate: target,
      note: '',
      achievedAt: achieved,
    );

    expect(
      milestoneOverdue(row('2026-11-19'), '2026-11-20'),
      isTrue,
      reason: '目标日已过且未达成',
    );
    expect(
      milestoneOverdue(row('2026-11-20'), '2026-11-20'),
      isFalse,
      reason: '当天到期不算逾期',
    );
    expect(
      milestoneOverdue(row('2026-11-19', achieved: 1763600000000), '2026-11-20'),
      isFalse,
      reason: '已达成就不算逾期',
    );
    expect(
      milestoneOverdue(row(null), '2026-11-20'),
      isFalse,
      reason: '没排期无从逾期',
    );
  });
}