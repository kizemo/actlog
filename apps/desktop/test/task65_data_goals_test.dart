// apps/desktop/test/task65_data_goals_test.dart
//
// Task 65 · 数据层：目标体系（schema v3 的 `goal` / `goal_link` 两张表）。
//
// 本文件钉九条：
//   T1：目标 CRUD（建 → 读回 → 改 → **显式置空** → 软删墓碑 → 删后再改抛缺失）；
//   T2：`goal_link` 四种 relation（serves / derives / tracks / references）都能写能读能断；
//   T3：重复关联走「复用行 + 清墓碑」（唯一约束覆盖全表，墓碑仍占槽位）；
//   T4：派生量**不入库**（`PRAGMA table_info` 里没有那些列），完成度现算；
//   T5：手勾与实际不一致时给标记，且「完成」按未完成显示；
//   T6：未落位检测（断链 = 正例，满链 = 负例）；
//   T7：滚动只出草稿（未确认时库中 0 增量），落库后 `status='draft'`；
//   T8：周视图按象限 → ABC 排序并给「优先顺序」序号；月视图给上月复盘 + 年度汇总条；
//   T9：新表写操作都落 oplog（证明确实登记进 `syncedTables`）。
//
// 判据全是**库里的真实行**，不是 UI 像素。
import 'package:actlog/src/data/goal_store.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart'
    show
        GoalField,
        GoalKind,
        GoalPeriod,
        GoalRelation,
        GoalStatus,
        GoalTargetType,
        PriorityAbc,
        Quadrant;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task65-goals-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('T1：目标 CRUD —— 建 / 读回 / 改 / 显式置空 / 软删', () async {
    final GoalPeriod week = GoalPeriod.week(2026, 48);
    final String id = await store.createGoal(
      kind: GoalKind.weekly,
      title: '每周读一本书',
      note: '初始备注',
      domain: 'learning',
      periodStart: week.startMillis,
      periodEnd: week.endMillis,
      dueDate: week.endMillis,
      quadrant: Quadrant.q1,
      priorityAbc: PriorityAbc.a,
    );

    final GoalRow? row = await store.findGoal(id);
    expect(row, isNotNull);
    expect(row!.title, '每周读一本书');
    expect(row.kind, GoalKind.weekly);
    expect(row.status, GoalStatus.active);
    expect(row.periodStart, week.startMillis);
    expect(row.periodEnd, week.endMillis);
    expect(row.domain, 'learning');
    expect(row.quadrant, Quadrant.q1);
    expect(row.priorityAbc, PriorityAbc.a);
    expect(row.note, '初始备注');
    expect(row.rev, 1);

    await store.updateGoal(id, title: '每周读两本书', note: '新备注');
    final GoalRow? updated = await store.findGoal(id);
    expect(updated!.title, '每周读两本书');
    expect(updated.note, '新备注');
    expect(updated.rev, 2, reason: '改动要 bump 本地修订号');

    // 显式置空：`clear` 优先于同名实参（普通 copyWith 分不清「不改」与「清空」）。
    await store.updateGoal(
      id,
      note: '这条会被 clear 压掉',
      clear: <GoalField>{GoalField.note},
    );
    expect((await store.findGoal(id))!.note, isNull);

    // 软删：库里留墓碑，接口读不到。
    await store.deleteGoal(id);
    expect(await store.findGoal(id), isNull);
    expect(await store.listGoals(), isEmpty);
    final List<GoalData> rows = await db.select(db.goal).get();
    expect(rows.length, 1, reason: '软删不是物理删');
    expect(rows.first.deletedAt, isNotNull);

    // 删完再改 → 抛缺失异常。
    await expectLater(
      store.updateGoal(id, title: 'x'),
      throwsA(isA<GoalMissingException>()),
    );
  });

  test('T2：`goal_link` 四种 relation 都能写、能读、能断', () async {
    final String goalId = await store.createGoal(
      kind: GoalKind.weekly,
      title: 'T2',
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-1',
      relation: GoalRelation.tracks,
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.goal,
      targetId: 'g-upper',
      relation: GoalRelation.serves,
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.goal,
      targetId: 'g-prev',
      relation: GoalRelation.derives,
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.project,
      targetId: 'pr-1',
      relation: GoalRelation.references,
    );

    expect((await store.listLinks(goalId)).length, 4);
    expect(
      (await store.listLinks(goalId, relation: GoalRelation.tracks)).length,
      1,
    );
    expect(
      (await store.listLinks(goalId, relation: GoalRelation.serves)).single
          .targetId,
      'g-upper',
    );
    expect(
      (await store.listLinks(goalId, relation: GoalRelation.derives)).single
          .targetId,
      'g-prev',
    );
    expect(
      (await store.listLinks(goalId, relation: GoalRelation.references)).single
          .targetId,
      'pr-1',
    );

    await store.unlink(
      goalId: goalId,
      targetType: GoalTargetType.project,
      targetId: 'pr-1',
    );
    expect((await store.listLinks(goalId)).length, 3);

    // 断两次也不报错（幂等）。
    await store.unlink(
      goalId: goalId,
      targetType: GoalTargetType.project,
      targetId: 'pr-1',
    );
    expect((await store.listLinks(goalId)).length, 3);
  });

  test('T3：重复关联复用同一行并清掉墓碑（不新增行）', () async {
    final String goalId = await store.createGoal(
      kind: GoalKind.weekly,
      title: 'T3',
    );
    final String linkId = await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-1',
      relation: GoalRelation.tracks,
    );
    expect((await db.select(db.goalLink).get()).length, 1);

    await store.unlink(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-1',
    );
    final List<GoalLinkData> tombstoned = await db.select(db.goalLink).get();
    expect(tombstoned.length, 1, reason: '唯一约束覆盖全表，墓碑仍占槽位');
    expect(tombstoned.first.deletedAt, isNotNull);

    final String again = await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-1',
      relation: GoalRelation.tracks,
    );
    expect(again, linkId, reason: '必须复用那一行');
    final List<GoalLinkData> rows = await db.select(db.goalLink).get();
    expect(rows.length, 1, reason: '重复关联不新增行');
    expect(rows.first.deletedAt, isNull, reason: '墓碑被清掉');
    expect((await store.listLinks(goalId)).length, 1);
  });

  test('T4：派生量不入库，完成度现算', () async {
    final Set<String> columns = <String>{
      for (final row in await db.customSelect('PRAGMA table_info(goal)').get())
        row.read<String>('name'),
    };
    for (final String banned in <String>[
      'completion',
      'completion_rate',
      'achievement',
      'achievement_rate',
      'progress',
      'summary',
      'is_unplaced',
      'unplaced',
    ]) {
      expect(
        columns.contains(banned),
        isFalse,
        reason: '派生量列「$banned」不许进库',
      );
    }

    final GoalPeriod week = GoalPeriod.week(2026, 48);
    final String goalId = await store.createGoal(
      kind: GoalKind.weekly,
      title: 'T4',
      periodStart: week.startMillis,
    );
    await _insertPlanItem(db, 'pi-done', _utcDate(week.startUtc), 'done');
    await _insertPlanItem(db, 'pi-pending', _utcDate(week.startUtc), 'pending');
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-done',
      relation: GoalRelation.tracks,
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-pending',
      relation: GoalRelation.tracks,
    );

    final GoalExecutionStats stats = await store.statsOf(goalId);
    expect(stats.tracksCount, 2);
    expect(stats.planItemTotal, 2);
    expect(stats.planItemDone, 1);
    expect(stats.completionRate, 0.5);
  });

  test('T5：手勾与实际不一致时给标记，「完成」按未完成显示', () async {
    final GoalPeriod week = GoalPeriod.week(2026, 48);
    final String goalId = await store.createGoal(
      kind: GoalKind.weekly,
      title: 'T5',
      periodStart: week.startMillis,
      status: GoalStatus.done,
    );
    await _insertPlanItem(db, 'pi-pending', _utcDate(week.startUtc), 'pending');
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-pending',
      relation: GoalRelation.tracks,
    );

    final GoalExecutionStats stats = await store.statsOf(goalId);
    expect(stats.userCompleted, isTrue, reason: '手勾了完成');
    expect(stats.isDiscrepant, isTrue, reason: '实际计划项还没完成 ⇒ 不一致');
    expect(stats.displayCompleted, isFalse, reason: '界面按「未完成」显示');

    // 反向：手勾没完成，但计划项全 done。
    final String otherId = await store.createGoal(
      kind: GoalKind.weekly,
      title: 'T5-反向',
      periodStart: week.startMillis,
    );
    await _insertPlanItem(db, 'pi-done', _utcDate(week.startUtc), 'done');
    await store.link(
      goalId: otherId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-done',
      relation: GoalRelation.tracks,
    );
    final GoalExecutionStats other = await store.statsOf(otherId);
    expect(other.userCompleted, isFalse);
    expect(other.isDiscrepant, isTrue);
    expect(other.displayCompleted, isFalse);
  });

  test('T6：未落位检测 —— 断链是正例，满链是负例', () async {
    final String goalId = await store.createGoal(
      kind: GoalKind.monthly,
      title: 'T6',
    );
    final GoalExecutionStats bare = await store.statsOf(goalId);
    expect(bare.isUnplaced, isTrue, reason: '既无 tracks 也无 serves ⇒ 未落位');
    expect(bare.tracksCount, 0);
    expect(bare.servesCount, 0);

    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-1',
      relation: GoalRelation.tracks,
    );
    expect((await store.statsOf(goalId)).isUnplaced, isFalse);

    final String upper = await store.createGoal(
      kind: GoalKind.yearly,
      title: 'T6-上层',
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.goal,
      targetId: upper,
      relation: GoalRelation.serves,
    );
    final GoalExecutionStats full = await store.statsOf(goalId);
    expect(full.servesCount, 1);
    expect(full.isUnplaced, isFalse, reason: '满链不是未落位');
  });

  test('T7：滚动只出草稿 —— 未确认时库中 0 增量，落库后 status=draft', () async {
    final GoalPeriod week = GoalPeriod.week(2026, 48);
    final GoalPeriod lastWeek = week.previous();
    final GoalPeriod month = GoalPeriod.month(2026, 11);

    final String monthlyId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '本月目标',
      periodStart: month.startMillis,
      periodEnd: month.endMillis,
    );
    final String lastWeeklyId = await store.createGoal(
      kind: GoalKind.weekly,
      title: '上周没做完',
      periodStart: lastWeek.startMillis,
      periodEnd: lastWeek.endMillis,
      improveNote: '下周改进',
    );
    await store.link(
      goalId: lastWeeklyId,
      targetType: GoalTargetType.goal,
      targetId: monthlyId,
      relation: GoalRelation.serves,
    );

    final int before = (await db.select(db.goal).get()).length;
    final List<GoalDraft> drafts = await store.rollWeeklyDrafts(week);
    expect(drafts, isNotEmpty);
    expect(
      (await db.select(db.goal).get()).length,
      before,
      reason: '只算不写：库中 0 增量',
    );

    final GoalDraft carry = drafts.firstWhere(
      (GoalDraft d) => d.origin == GoalDraftOrigin.carryOver,
    );
    expect(carry.kind, GoalKind.weekly);
    expect(carry.periodStart, week.startMillis);
    expect(carry.periodEnd, week.endMillis);
    expect(carry.note, '下周改进', reason: '默认备注取 improve_note');
    expect(carry.parentId, monthlyId, reason: '结转候选要服务本月目标');
    expect(carry.sourceGoalId, lastWeeklyId);

    final int written = await store.saveWeeklyDrafts(<GoalDraft>[carry]);
    expect(written, 1);
    final List<GoalRow> weekly = await store.listGoals(
      kind: GoalKind.weekly,
      period: week,
    );
    expect(weekly.length, 1);
    expect(
      weekly.single.status,
      GoalStatus.draft,
      reason: '滚动产物只能是草稿态，激活由界面层决定',
    );

    final List<GoalLinkRow> links = await store.listLinks(weekly.single.id);
    expect(
      links.where((GoalLinkRow l) => l.relation == GoalRelation.serves).length,
      1,
      reason: 'serves(→本月)',
    );
    expect(
      links
          .where((GoalLinkRow l) => l.relation == GoalRelation.derives)
          .single
          .targetId,
      lastWeeklyId,
      reason: 'derives(→上周)',
    );
  });

  test('T8：周视图按象限→ABC 排序并给序号；月视图给上月复盘与年度汇总条',
      () async {
    final GoalPeriod week = GoalPeriod.week(2026, 48);
    final GoalPeriod month = GoalPeriod.month(2026, 11);
    final GoalPeriod lastMonth = month.previous();
    final GoalPeriod year = GoalPeriod.year(2026);

    final String yearlyId = await store.createGoal(
      kind: GoalKind.yearly,
      title: '年度目标',
      periodStart: year.startMillis,
      periodEnd: year.endMillis,
    );
    final String monthlyId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '本月目标（已完成）',
      periodStart: month.startMillis,
      periodEnd: month.endMillis,
      status: GoalStatus.done,
    );
    await store.link(
      goalId: monthlyId,
      targetType: GoalTargetType.goal,
      targetId: yearlyId,
      relation: GoalRelation.serves,
    );
    final String otherMonthlyId = await store.createGoal(
      kind: GoalKind.monthly,
      title: '本月目标（未完成）',
      periodStart: month.startMillis,
      periodEnd: month.endMillis,
    );
    await store.link(
      goalId: otherMonthlyId,
      targetType: GoalTargetType.goal,
      targetId: yearlyId,
      relation: GoalRelation.serves,
    );
    await store.createGoal(
      kind: GoalKind.monthly,
      title: '上月目标',
      periodStart: lastMonth.startMillis,
      periodEnd: lastMonth.endMillis,
    );

    // 先建 Q3 后建 Q1 ⇒ 排序必须按象限，而不是创建时间。
    await store.createGoal(
      kind: GoalKind.weekly,
      title: 'Q3 的事',
      periodStart: week.startMillis,
      quadrant: Quadrant.q3,
      priorityAbc: PriorityAbc.a,
    );
    await store.createGoal(
      kind: GoalKind.weekly,
      title: 'Q1 的事',
      periodStart: week.startMillis,
      quadrant: Quadrant.q1,
      priorityAbc: PriorityAbc.c,
    );

    final GoalWeekView view = await store.weekView(week);
    expect(view.items.length, 2);
    expect(view.items[0].goal.title, 'Q1 的事');
    expect(view.items[0].order, 1);
    expect(view.items[1].order, 2);
    expect(view.items[0].stats.isUnplaced, isTrue);

    final GoalMonthView monthView = await store.monthView(month);
    expect(monthView.monthGoals.length, 2);
    expect(monthView.previousMonthGoals.single.title, '上月目标');
    expect(monthView.yearSummaries.length, 1);
    expect(monthView.yearSummaries.single.goal.id, yearlyId);
    expect(monthView.yearSummaries.single.childTotal, 2);
    expect(monthView.yearSummaries.single.childDone, 1);
    expect(monthView.yearSummaries.single.achievementRate, 0.5);
  });

  test('T9：新表写操作都落 oplog（证明已登记进 syncedTables）', () async {
    final String goalId = await store.createGoal(
      kind: GoalKind.weekly,
      title: 'T9',
    );
    await store.link(
      goalId: goalId,
      targetType: GoalTargetType.planItem,
      targetId: 'pi-1',
      relation: GoalRelation.tracks,
    );
    final List<OplogData> oplogRows = await db.select(db.oplog).get();
    expect(
      oplogRows.any((OplogData r) => r.entityTable == 'goal'),
      isTrue,
      reason: 'goal 的写操作要进 oplog',
    );
    expect(
      oplogRows.any((OplogData r) => r.entityTable == 'goal_link'),
      isTrue,
      reason: 'goal_link 的写操作要进 oplog',
    );
  });
}

/// 造一条 `plan_item`（用原生 SQL 插入，避免依赖 drift 生成的 insert 构造）。
Future<void> _insertPlanItem(
  ActLogDatabase db,
  String id,
  String date,
  String status,
) async {
  await db.customStatement(
    'INSERT INTO plan_item (id, date, title, status, created_at, updated_at, '
    'origin_device_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
    <Object?>[id, date, '计划-$id', status, 1, 1, 'task65-goals-test'],
  );
}

/// UTC 日期串（`YYYY-MM-DD`）。
String _utcDate(DateTime moment) {
  final String y = moment.year.toString().padLeft(4, '0');
  final String m = moment.month.toString().padLeft(2, '0');
  final String d = moment.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
