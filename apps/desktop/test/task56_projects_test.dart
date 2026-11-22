// apps/desktop/test/task56_projects_test.dart
//
// Task 56 · 数据层：项目 / 每项目多任务 /「排期 ⇒ 待办 ⇒ 主页计划」整条链路。
//
// 本文件钉七条：
//   T1：多项目、每项目多任务都读得回来（且任务按目标日升序）；
//   T2：里程碑排了期 ⇒ 待办池里多一条 `open` 待办，`due_date` / `project_id`
//       / `title` 三者都对得上；
//   T3：里程碑**没**排期 ⇒ 不落待办（不凭空造一条没到期日的事）；
//   T4：改期**不重复插**待办（改三次仍只有一条，到期日跟着走）—— 这是
//       「改期幂等」的判别性用例；
//   T5：取消排期只清空到期日，不新建、也不删除那条待办；
//   T6：待办加入主页计划 ⇒ 落一条 `plan_item`（`source_todo_id` 指回待办），
//       且待办本体**不动**（仍在池子里）；
//   T7：所有写操作都落 oplog（同步侧看得到，不是裸 SQL 写进去的孤儿行）。
//
// 判据全是**库里的真实行**，不是 UI 像素。
import 'package:actlog/src/data/project_store.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Todo;
import 'package:core_domain/core_domain.dart'
    show DomainValidationException, Todo, TodoStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late ProjectStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task56-projects-test');
    store = ProjectStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('T1：多项目 / 每项目多任务都读得回来（任务按目标日升序）', () async {
    final String p1 = await store.createProject(
      name: '甲',
      goal: '把甲做完',
      startDate: '2026-11-01',
      endDate: '2026-11-10',
    );
    final String p2 = await store.createProject(
      name: '乙',
      startDate: '2026-11-05',
      endDate: '2026-11-20',
    );
    await store.createMilestone(
      projectId: p1,
      title: '甲-后',
      targetDate: '2026-11-08',
    );
    await store.createMilestone(
      projectId: p1,
      title: '甲-前',
      targetDate: '2026-11-03',
    );
    await store.createMilestone(projectId: p2, title: '乙-未排期');

    final List<ProjectRow> rows = await store.listProjects();
    expect(rows.length, 2, reason: '两个项目都要在');

    final ProjectRow a = rows.firstWhere((ProjectRow r) => r.id == p1);
    final ProjectRow b = rows.firstWhere((ProjectRow r) => r.id == p2);
    expect(a.name, '甲');
    expect(a.goal, '把甲做完');
    expect(a.startDate, '2026-11-01');
    expect(a.endDate, '2026-11-10');
    expect(
      a.milestones.map((MilestoneRow m) => m.title).toList(),
      <String>['甲-前', '甲-后'],
      reason: '任务按目标日升序（未排期的排最后）',
    );

    expect(b.name, '乙');
    expect(b.milestones.length, 1);
    expect(b.milestones.single.title, '乙-未排期');
    expect(b.milestones.single.targetDate, isNull);
  });

  test('T2：排期 ⇒ 待办池里多一条 open 待办（due_date / project_id / title 对得上）',
      () async {
    final String projectId = await store.createProject(
      name: '甲',
      startDate: '2026-11-01',
      endDate: '2026-11-10',
    );
    await store.createMilestone(
      projectId: projectId,
      title: '写文档',
      targetDate: '2026-11-05',
    );

    final List<Todo> todos = await repos.todo.listOpen();
    expect(todos.length, 1, reason: '排了期就该在待办池里看见');
    expect(todos.single.status, TodoStatus.open);
    expect(todos.single.dueDate, '2026-11-05');
    expect(todos.single.projectId, projectId);
    expect(todos.single.title, '写文档');
  });

  test('T3：没排期 ⇒ 不落待办（不凭空造一条没到期日的事）', () async {
    final String projectId = await store.createProject(name: '甲');
    await store.createMilestone(projectId: projectId, title: '写文档');

    final List<Todo> todos = await repos.todo.listOpen();
    expect(todos, isEmpty, reason: '未排期不该进待办池');
  });

  test('T4：改期不重复插待办（改三次仍只有一条，到期日跟着走）', () async {
    final String projectId = await store.createProject(name: '甲');
    final String milestoneId = await store.createMilestone(
      projectId: projectId,
      title: '写文档',
      targetDate: '2026-11-05',
    );

    await store.setMilestoneTargetDate(
      milestoneId: milestoneId,
      targetDate: '2026-11-06',
    );
    await store.setMilestoneTargetDate(
      milestoneId: milestoneId,
      targetDate: '2026-11-07',
    );
    await store.setMilestoneTargetDate(
      milestoneId: milestoneId,
      targetDate: '2026-11-07',
    );

    final List<Todo> todos = await repos.todo.listOpen();
    expect(todos.length, 1, reason: '改期绝不能重复插待办');
    expect(todos.single.dueDate, '2026-11-07');
    expect(todos.single.projectId, projectId);

    final ProjectRow row = (await store.listProjects()).single;
    expect(row.milestones.single.targetDate, '2026-11-07');
  });

  test('T5：取消排期只清空到期日，不新建也不删那条待办', () async {
    final String projectId = await store.createProject(name: '甲');
    final String milestoneId = await store.createMilestone(
      projectId: projectId,
      title: '写文档',
      targetDate: '2026-11-05',
    );

    await store.setMilestoneTargetDate(milestoneId: milestoneId, targetDate: null);

    final List<Todo> todos = await repos.todo.listOpen();
    expect(todos.length, 1, reason: '取消排期不许偷偷删掉那条待办');
    expect(todos.single.dueDate, isNull);
  });

  test('T6：待办加入主页计划 ⇒ 落一条 plan_item，且待办本体不动', () async {
    final String projectId = await store.createProject(name: '甲');
    await store.createMilestone(
      projectId: projectId,
      title: '写文档',
      targetDate: '2026-11-05',
    );
    final Todo todo = (await repos.todo.listOpen()).single;

    final String planItemId = await repos.todo.pullToPlan(todo.id, '2026-11-05');

    final List<PlanItemData> items = await db.select(db.planItem).get();
    expect(items.length, 1);
    expect(items.single.id, planItemId);
    expect(items.single.sourceTodoId, todo.id);
    expect(items.single.sourceType, 'todo');
    expect(items.single.date, '2026-11-05');
    expect(items.single.title, '写文档');
    // 待办本体不动（待办池只查 `status='open'`）⇒ 它仍留在池子里。
    expect((await repos.todo.listOpen()).length, 1);
  });

  test('T7：写库都落 oplog（同步侧看得到，不是裸 SQL 的孤儿行）', () async {
    final String projectId = await store.createProject(name: '甲');
    await store.createMilestone(
      projectId: projectId,
      title: '写文档',
      targetDate: '2026-11-05',
    );

    final List<OplogData> logs = await db.select(db.oplog).get();
    final Set<String> tables = <String>{
      for (final OplogData row in logs) row.entityTable,
    };
    expect(tables, containsAll(<String>['project', 'project_milestone', 'todo']));
    expect(logs.length, 3, reason: '三行业务写入 ⇒ 三条 oplog');
  });

  test('T8：空标题 / 非法日期被拒，且不留下任何写入', () async {
    await expectLater(
      store.createProject(name: '   '),
      throwsArgumentError,
    );
    await expectLater(
      store.createMilestone(
        projectId: 'p',
        title: 'x',
        targetDate: '2026-13-01',
      ),
      throwsA(isA<DomainValidationException>()),
    );
    expect(await store.listProjects(), isEmpty);
  });
}
