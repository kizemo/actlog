// =============================================================================
// 项目 · 写入通道（Task 56）
// =============================================================================
// 为什么不直接调仓储层：`packages\core_data` 里没有 `project` /
// `project_milestone` 的仓储，而本轮**不许动 `packages\**`**。所以落库走本文件：
// 用 `repos.oplog.writeWithOplog` 写业务表，与仓储层同一套账本规矩
// （`uuidV7()` + `nowMillis()` + `resolveDeviceId()` + `rev + 1`）—— 同步侧看到的
// 是正常记录，而不是裸 SQL 写进去的孤儿行。
//
// 「排期 ⇒ 待办」口径（Task 56 诉求 2）：
//   里程碑给了 `target_date` ⇒ 待办池里必须有一条 `todo`
//   （`status='open'`、`due_date=target_date`、`project_id=<项目 id>`、
//     `title=里程碑标题`）。
//   `todo` 表**没有**指向里程碑的指针列（列清单已核实），所以幂等判重只能用
//   「同 `project_id` + 同 `due_date` + 同 `title`」三元组：命中就更新既有行，
//   没命中才插入 —— 改期 N 次永远只留一条待办。
//
// 已知代价（写在这里而不是藏起来）：同一项目里**标题相同且目标日相同**的两条
// 任务会共用同一条待办（`todo` 表没有里程碑指针，无法区分）。这不是本文件能
// 在零 schema 变更下绕开的限制。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart'
    hide nowMillis, Project, ProjectMilestone;
import 'package:core_domain/core_domain.dart'
    show PlanSourceType, TodoStatus, Validate;
import 'package:drift/drift.dart';

import '../widgets/timeline/timeline_store.dart';

/// 一条任务（`project_milestone` 的一行）。
class MilestoneRow {
  /// 构造。
  const MilestoneRow({
    required this.id,
    required this.projectId,
    required this.title,
    required this.targetDate,
    required this.note,
    this.achievedAt,
  });

  /// `project_milestone.id`。
  final String id;

  /// 所属项目 id（`project_milestone.project_id`）。
  final String projectId;

  /// 任务标题。
  final String title;

  /// 目标日（`YYYY-MM-DD`）；`null` = 未排期。
  final String? targetDate;

  /// 备注。
  final String note;

  /// 达成时刻（`project_milestone.achieved_at`，Unix 毫秒）；`null` = 未达成。
  ///
  /// 可选字段：既有调用点（`task56_*` 用例）直接构造 [MilestoneRow] 时不传它，
  /// 语义就是「未达成」，与库里 `achieved_at IS NULL` 一致。
  final int? achievedAt;
}

/// 一个项目 + 它的全部任务。
class ProjectRow {
  /// 构造。
  const ProjectRow({
    required this.id,
    required this.name,
    required this.goal,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.milestones,
    this.domain = '',
  });

  /// `project.id`。
  final String id;

  /// 项目名称。
  final String name;

  /// 目标描述。
  final String goal;

  /// 开始日期（`YYYY-MM-DD`）；`null` = 未定。
  final String? startDate;

  /// 结束日期（`YYYY-MM-DD`）；`null` = 未定。
  final String? endDate;

  /// 项目状态（`active` / `paused` / `done` / `cancelled`）。
  final String status;

  /// 该项目的全部任务（按目标日升序，未排期的排在最后）。
  final List<MilestoneRow> milestones;

  /// 所属领域（`project.domain`）：稳定的英文小写 key，例如 `career`。
  ///
  /// **空串 = 未分类**（Task 59 之前的项目、以及新建时没选领域的项目都落在
  /// 这一桶）。显示文案不走本字段，由界面层按 key 本地化。
  final String domain;
}

/// 一条增量（`project_increment` 的一行）。
class IncrementRow {
  /// 构造。
  const IncrementRow({
    required this.id,
    required this.projectId,
    required this.date,
    required this.progress,
    required this.blockers,
    required this.nextStep,
    required this.planItemId,
  });

  /// `project_increment.id`。
  final String id;

  /// 所属项目 id。
  final String projectId;

  /// 增量日期（`YYYY-MM-DD`）。
  final String date;

  /// 进展。
  final String progress;

  /// 阻塞项。
  final String blockers;

  /// 下一步。
  final String nextStep;

  /// 关联的计划条目 id；`null` = 当天没有指向本项目的计划行。
  final String? planItemId;
}

/// 一条排进某一天的计划行（`plan_item` 里来源指向「项目 / 增量」的行）。
class ScheduledItem {
  /// 构造。
  const ScheduledItem({
    required this.id,
    required this.date,
    required this.title,
    required this.sourceType,
    required this.sourceId,
    required this.status,
    required this.startMinute,
  });

  /// `plan_item.id`。
  final String id;

  /// 所属日历日（`YYYY-MM-DD`）。
  final String date;

  /// 标题快照。
  final String title;

  /// 来源类型（`project` / `increment`）。
  final String sourceType;

  /// 来源 id（`project.id` 或 `project_increment.id`）。
  final String? sourceId;

  /// 状态（`pending` / `done` / `skipped` ...）。
  final String status;

  /// 计划开始时刻（分钟）；`null` = 未定。
  final int? startMinute;
}

/// 一个「停滞」的项目：连续 [thresholdDays] 天没有增量。
class ProjectStall {
  /// 构造。
  const ProjectStall({
    required this.projectId,
    required this.name,
    required this.daysSinceIncrement,
  });

  /// 项目 id。
  final String projectId;

  /// 项目名称。
  final String name;

  /// 距上一次增量（零增量时距项目建立）过去了几天。
  final int daysSinceIncrement;
}

/// 项目的写入通道：一个数据库句柄 + 一个账本写入器。
///
/// 所有写操作都走 `repos.oplog.writeWithOplog`，不裸写 SQL。
class ProjectStore {
  /// 创建通道。
  ProjectStore(this.repos);

  /// 仓储集合（只用它的 `db` 与 `oplog`）。
  final ActLogRepositories repos;

  ActLogDatabase get _db => repos.db;

  /// 列出全部未删除项目（按创建时间升序），每个项目带上它的任务。
  Future<List<ProjectRow>> listProjects() async {
    final List<ProjectData> projects =
        await (_db.select(_db.project)..where((t) => t.deletedAt.isNull())).get();
    if (projects.isEmpty) {
      return const <ProjectRow>[];
    }
    final List<ProjectMilestoneData> milestones =
        await (_db.select(_db.projectMilestone)
              ..where((t) => t.deletedAt.isNull()))
            .get();

    final Map<String, List<MilestoneRow>> grouped = <String, List<MilestoneRow>>{};
    for (final ProjectMilestoneData row in milestones) {
      grouped.putIfAbsent(row.projectId, () => <MilestoneRow>[]).add(
            MilestoneRow(
              id: row.id,
              projectId: row.projectId,
              title: row.title,
              targetDate: row.targetDate,
              note: row.note,
              achievedAt: row.achievedAt,
            ),
          );
    }
    for (final List<MilestoneRow> list in grouped.values) {
      list.sort(_compareMilestones);
    }

    final List<ProjectData> sorted = List<ProjectData>.of(projects)
      ..sort((ProjectData a, ProjectData b) {
        final int byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

    return sorted
        .map(
          (ProjectData row) => ProjectRow(
            id: row.id,
            name: row.name,
            goal: row.goal,
            startDate: row.startDate,
            endDate: row.endDate,
            status: row.status,
            milestones:
                grouped[row.id] ?? const <MilestoneRow>[],
            domain: row.domain,
          ),
        )
        .toList(growable: false);
  }

  /// 新建项目，返回新的 `project.id`。
  ///
  /// [startDate] / [endDate] 留 `null` 表示「未定」（列存 NULL，不写空串占位）；
  /// 给了就必须是真实日历日（`Validate.calendarDate`），否则抛
  /// `DomainValidationException` 且**不留下任何写入**。
  ///
  /// [domain] 是稳定的英文小写领域 key（`career` / `wealth` / `family` /
  /// `learning` / `social` / `health`）；留空串 = 未分类。列上**没有** CHECK
  /// 约束（自由文本），所以这里不校验取值域 —— 同步进来的历史 key 照样能存。
  Future<String> createProject({
    required String name,
    String goal = '',
    String? startDate,
    String? endDate,
    String domain = '',
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', '项目名称不能为空');
    }
    if (startDate != null) {
      Validate.calendarDate(startDate, 'startDate');
    }
    if (endDate != null) {
      Validate.calendarDate(endDate, 'endDate');
    }

    final String id = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await repos.oplog.writeWithOplog<void>(
      table: 'project',
      id: id,
      changedFields: <String, Object?>{
        'name': trimmed,
        'goal': goal,
        'start_date': startDate,
        'end_date': endDate,
        'domain': domain,
        'status': 'active',
      },
      write: () => _db.into(_db.project).insert(
            ProjectCompanion.insert(
              id: id,
              name: trimmed,
              goal: Value<String>(goal),
              startDate: Value<String?>(startDate),
              endDate: Value<String?>(endDate),
              domain: Value<String>(domain),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );
    return id;
  }

  /// 新建任务（项目下的一条里程碑），返回新的 `project_milestone.id`。
  ///
  /// 给了 [targetDate] 就**同时**在待办池里落一条待办（诉求 2 的接线点）：
  /// `status='open'`、`due_date=target_date`、`project_id=<项目 id>`、
  /// `title=<任务标题>`。
  ///
  /// [targetDate] 留 `null` = 未排期 ⇒ 不落待办（甘特图上也不画块）。
  Future<String> createMilestone({
    required String projectId,
    required String title,
    String? targetDate,
    String note = '',
  }) async {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', '任务标题不能为空');
    }
    if (targetDate != null) {
      Validate.calendarDate(targetDate, 'targetDate');
    }

    final String id = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await repos.oplog.writeWithOplog<void>(
      table: 'project_milestone',
      id: id,
      changedFields: <String, Object?>{
        'project_id': projectId,
        'title': trimmed,
        'target_date': targetDate,
      },
      write: () => _db.into(_db.projectMilestone).insert(
            ProjectMilestoneCompanion.insert(
              id: id,
              projectId: projectId,
              title: trimmed,
              targetDate: Value<String?>(targetDate),
              note: Value<String>(note),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );

    if (targetDate != null) {
      await _syncTodo(
        projectId: projectId,
        title: trimmed,
        dueDate: targetDate,
        deviceId: deviceId,
        ts: ts,
      );
    }
    return id;
  }

  /// 改一条任务的目标日（幂等：改期 N 次，待办池里永远只有一条待办）。
  ///
  /// [targetDate] 传 `null` = 取消排期 ⇒ 只把既有待办的 `due_date` 清空，
  /// **不新建、也不删除**那条待办（事情还在，只是没有截止日了）。
  ///
  /// 幂等判重规则（`todo` 表没有指向里程碑的指针列，只能用三元组）：
  /// 「同 `project_id` + 同 `title` + 同**旧**目标日」命中既有待办 ⇒ 更新它的
  /// `due_date`；没命中而 [targetDate] 非空 ⇒ 新建一条。命中的是既有行，所以
  /// 待办条数不会因为改期而增长。
  Future<void> setMilestoneTargetDate({
    required String milestoneId,
    required String? targetDate,
  }) async {
    if (targetDate != null) {
      Validate.calendarDate(targetDate, 'targetDate');
    }
    final ProjectMilestoneData? milestone =
        await (_db.select(_db.projectMilestone)
              ..where((t) => t.id.equals(milestoneId)))
            .getSingleOrNull();
    if (milestone == null || milestone.deletedAt != null) {
      throw StateError('任务 $milestoneId 不存在');
    }

    final String? oldDate = milestone.targetDate;
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await repos.oplog.writeWithOplog<void>(
      table: 'project_milestone',
      id: milestoneId,
      changedFields: <String, Object?>{'target_date': targetDate},
      write: () =>
          (_db.update(_db.projectMilestone)..where((t) => t.id.equals(milestoneId)))
              .write(
        ProjectMilestoneCompanion(
          targetDate: Value<String?>(targetDate),
          updatedAt: Value<int>(ts),
          originDeviceId: Value<String>(deviceId),
          rev: Value<int>(milestone.rev + 1),
        ),
      ),
    );

    // 找「这条任务原来那条待办」：同项目 + 同标题 + 同旧目标日。
    final TodoData? linked = await _findTodo(
      projectId: milestone.projectId,
      title: milestone.title,
      dueDate: oldDate,
    );
    if (linked != null) {
      await _updateTodo(
        row: linked,
        dueDate: targetDate,
        title: milestone.title,
        deviceId: deviceId,
        ts: ts,
      );
      return;
    }
    if (targetDate == null) {
      // 取消排期且没有对应待办 ⇒ 无事可做（不凭空造一条）。
      return;
    }
    await _insertTodo(
      projectId: milestone.projectId,
      title: milestone.title,
      dueDate: targetDate,
      deviceId: deviceId,
      ts: ts,
    );
  }

  // ---------------------------------------------------------------------------
  // P1 批次：排期联动 / 增量追加 / 停滞判定（Task 57）
  // ---------------------------------------------------------------------------

  /// 把「项目 / 增量」的一件事排进 [date]（两枚「→ 今天」按钮的**唯一**入口）。
  ///
  /// [sourceType] 只接受 `project` / `increment`（`plan_item.source_type` 的
  /// CHECK 里项目侧就这两态），[sourceId] 分别指向 `project.id` /
  /// `project_increment.id`。落库一律走 [TimelineStore.createFromProject] ——
  /// 计划行的账本路径只能有一份，本文件不另写 INSERT（否则两边静默分叉）。
  ///
  /// [startMinute] / [endMinute] 不给时按当天已有计划行的最大结束时刻顺延
  /// （见 [_nextStartMinute]），默认时长 30 分钟。
  Future<String> scheduleToDay({
    required String date,
    required PlanSourceType sourceType,
    required String sourceId,
    required String title,
    String detail = '',
    int? startMinute,
    int? endMinute,
  }) async {
    Validate.calendarDate(date, 'date');
    if (sourceType != PlanSourceType.project &&
        sourceType != PlanSourceType.increment) {
      throw ArgumentError.value(
        sourceType,
        'sourceType',
        '只接受 project / increment',
      );
    }
    final int start = startMinute ?? await _nextStartMinute(date);
    return TimelineStore(repos).createFromProject(
      date: date,
      title: title,
      sourceType: sourceType.code,
      sourceId: sourceId,
      startMinute: start,
      endMinute: endMinute ?? (start + 30),
      detail: detail,
    );
  }

  /// 某个项目排出的全部计划行（`source_type` 为 `project` 或 `increment`）。
  ///
  /// `plan_item` **没有** `project_id` 列，所以只能经多态指针过滤：项目自己的
  /// 行是 `source_id = projectId`，增量的行是 `source_id IN (本项目增量 id)`。
  /// 增量集合为空时走单分支 —— `IN ()` 在 SQLite 里是语法错。
  ///
  /// 返回按日期升序、同日按开始时刻升序（未定时刻的排最后）。
  Future<List<ScheduledItem>> listByProject(String projectId) async {
    final List<String> incrementIds = await _incrementIds(projectId);
    final List<PlanItemData> rows = await (_db.select(_db.planItem)
          ..where((t) {
            final Expression<bool> byProject =
                t.sourceType.equals(PlanSourceType.project.code) &
                    t.sourceId.equals(projectId);
            if (incrementIds.isEmpty) {
              return t.deletedAt.isNull() & byProject;
            }
            return t.deletedAt.isNull() &
                (byProject |
                    (t.sourceType.equals(PlanSourceType.increment.code) &
                        t.sourceId.isIn(incrementIds)));
          }))
        .get();
    final List<ScheduledItem> items = rows
        .map(
          (PlanItemData row) => ScheduledItem(
            id: row.id,
            date: row.date,
            title: row.title,
            sourceType: row.sourceType,
            sourceId: row.sourceId,
            status: row.status,
            startMinute: row.plannedStart,
          ),
        )
        .toList();
    items.sort((ScheduledItem a, ScheduledItem b) {
      final int byDate = a.date.compareTo(b.date);
      if (byDate != 0) {
        return byDate;
      }
      final int byStart =
          (a.startMinute ?? 24 * 60).compareTo(b.startMinute ?? 24 * 60);
      return byStart != 0 ? byStart : a.id.compareTo(b.id);
    });
    return List<ScheduledItem>.unmodifiable(items);
  }

  /// 某个项目的全部增量（日期倒序，同日按创建时刻倒序）。
  Future<List<IncrementRow>> listIncrements(String projectId) async {
    final List<ProjectIncrementData> rows =
        await (_db.select(_db.projectIncrement)
              ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull()))
            .get();
    final List<ProjectIncrementData> sorted =
        List<ProjectIncrementData>.of(rows)
          ..sort((ProjectIncrementData a, ProjectIncrementData b) {
            final int byDate = b.date.compareTo(a.date);
            if (byDate != 0) {
              return byDate;
            }
            final int byTime = b.createdAt.compareTo(a.createdAt);
            return byTime != 0 ? byTime : b.id.compareTo(a.id);
          });
    return sorted
        .map(
          (ProjectIncrementData row) => IncrementRow(
            id: row.id,
            projectId: row.projectId,
            date: row.date,
            progress: row.progress,
            blockers: row.blockers,
            nextStep: row.nextStep,
            planItemId: row.planItemId,
          ),
        )
        .toList(growable: false);
  }

  /// 追加一条增量（**只 INSERT**，永不更新既有行），返回新的
  /// `project_increment.id`。
  ///
  /// 增量的语义是流水，写错了只能再追加一条更正 —— 所以这里没有 update /
  /// delete 的对偶方法。前端无增量时把提交按钮写成「写第一条增量」，两种文案
  /// 走同一条 INSERT。
  ///
  /// [planItemId] 自动派生：当天有指向本项目的计划行就挂上，没有就 `NULL`。
  /// `project_increment.plan_item_id` 的 FK 是 `ON DELETE SET NULL`，所以在
  /// 今日方格上删掉那条计划**不会**连带删增量，只会把指针置空。
  Future<String> appendIncrement({
    required String projectId,
    required String date,
    String progress = '',
    String blockers = '',
    String nextStep = '',
  }) async {
    Validate.calendarDate(date, 'date');
    final String id = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();
    final String? planItemId = await _planItemOn(projectId, date);

    await repos.oplog.writeWithOplog<void>(
      table: 'project_increment',
      id: id,
      changedFields: <String, Object?>{
        'project_id': projectId,
        'date': date,
        'plan_item_id': planItemId,
        'progress': progress,
        'blockers': blockers,
        'next_step': nextStep,
      },
      write: () => _db.into(_db.projectIncrement).insert(
            ProjectIncrementCompanion.insert(
              id: id,
              projectId: projectId,
              date: date,
              planItemId: Value<String?>(planItemId),
              progress: Value<String>(progress),
              blockers: Value<String>(blockers),
              nextStep: Value<String>(nextStep),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );
    return id;
  }

  /// 连续 [thresholdDays] 天没有增量的 active 项目（温和停滞提示的数据源）。
  ///
  /// 起算点 = `max(最近一条增量的日期, 项目建立日)`：
  ///  - 有增量 ⇒ 从最近那条算；同一天写 10 条也只算 0 天。
  ///  - 零增量 ⇒ 从项目建立日算（派工书只写「距最近增量」，零增量时无定义，
  ///    不拿 `epoch` 当起点 —— 那样每个新项目一出生就被判停滞）。
  ///
  /// 只取 `status = 'active'` 且未删除的项目；`paused` / `done` / `cancelled`
  /// 不该被催。
  Future<List<ProjectStall>> stalledProjects({
    required String todayIso,
    int thresholdDays = 3,
  }) async {
    Validate.calendarDate(todayIso, 'todayIso');
    final List<ProjectData> projects = await (_db.select(_db.project)
          ..where((t) => t.deletedAt.isNull() & t.status.equals('active')))
        .get();
    if (projects.isEmpty) {
      return const <ProjectStall>[];
    }
    final List<ProjectIncrementData> increments =
        await (_db.select(_db.projectIncrement)
              ..where((t) => t.deletedAt.isNull()))
            .get();
    final Map<String, String> latestByProject = <String, String>{};
    for (final ProjectIncrementData row in increments) {
      final String? current = latestByProject[row.projectId];
      if (current == null || row.date.compareTo(current) > 0) {
        latestByProject[row.projectId] = row.date;
      }
    }
    final List<ProjectStall> stalls = <ProjectStall>[];
    for (final ProjectData project in projects) {
      final String? latest = latestByProject[project.id];
      final String floor = latest ?? _isoOfMillis(project.createdAt);
      final int days = _daysBetween(floor, todayIso);
      if (days >= thresholdDays) {
        stalls.add(
          ProjectStall(
            projectId: project.id,
            name: project.name,
            daysSinceIncrement: days,
          ),
        );
      }
    }
    stalls.sort((ProjectStall a, ProjectStall b) {
      final int byDays = b.daysSinceIncrement.compareTo(a.daysSinceIncrement);
      return byDays != 0 ? byDays : a.projectId.compareTo(b.projectId);
    });
    return List<ProjectStall>.unmodifiable(stalls);
  }

  /// 本项目的全部未删增量 id（只给 [listByProject] 拼 `IN (...)` 用）。
  Future<List<String>> _incrementIds(String projectId) async {
    final List<ProjectIncrementData> rows =
        await (_db.select(_db.projectIncrement)
              ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull()))
            .get();
    return rows.map((ProjectIncrementData row) => row.id).toList(growable: false);
  }

  /// 当天指向本项目的**第一条**计划行（[appendIncrement] 派生 `plan_item_id`）。
  Future<String?> _planItemOn(String projectId, String date) async {
    final List<ScheduledItem> items = await listByProject(projectId);
    for (final ScheduledItem item in items) {
      if (item.date == date) {
        return item.id;
      }
    }
    return null;
  }

  /// 当天新排一件事的默认开始时刻：接在既有计划行最后一件事之后。
  ///
  /// 规则：取当日未删计划行的最大 `planned_end`，向上吸附到 5 分钟；早于
  /// 08:00 一律从 08:00 起；超过 22:00 的封顶线则回落 08:00（不把事排到深夜）。
  /// 为什么不是固定 09:00：同一天排多个项目会全部叠在同一格上。
  Future<int> _nextStartMinute(String date) async {
    final List<PlanItemData> rows = await (_db.select(_db.planItem)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull()))
        .get();
    int latest = 0;
    for (final PlanItemData row in rows) {
      final int? end = row.plannedEnd;
      if (end != null && end > latest) {
        latest = end;
      }
    }
    const int floorMinutes = 8 * 60;
    const int ceilMinutes = 22 * 60;
    if (latest < floorMinutes) {
      return floorMinutes;
    }
    final int snapped = ((latest + 4) ~/ 5) * 5;
    return snapped > ceilMinutes ? floorMinutes : snapped;
  }

  /// 任务排序：目标日升序；未排期（`null`）的排最后；同日期按 id 破平局。
  static int _compareMilestones(MilestoneRow a, MilestoneRow b) {
    final String? da = a.targetDate;
    final String? db = b.targetDate;
    if (da == null && db == null) {
      return a.id.compareTo(b.id);
    }
    if (da == null) {
      return 1;
    }
    if (db == null) {
      return -1;
    }
    final int byDate = da.compareTo(db);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  /// 让一条任务在待办池里对应**唯一一条**待办（幂等）。
  Future<void> _syncTodo({
    required String projectId,
    required String title,
    required String dueDate,
    required String deviceId,
    required int ts,
  }) async {
    final TodoData? existing =
        await _findTodo(projectId: projectId, title: title, dueDate: dueDate);
    if (existing != null) {
      await _updateTodo(
        row: existing,
        dueDate: dueDate,
        title: title,
        deviceId: deviceId,
        ts: ts,
      );
      return;
    }
    await _insertTodo(
      projectId: projectId,
      title: title,
      dueDate: dueDate,
      deviceId: deviceId,
      ts: ts,
    );
  }

  /// 幂等判重的查询：`project_id` + `title` + `due_date` 三者全同、未删除、
  /// 状态 `open`。同键多条时取最早创建的那条（保证每次给同一个答案）。
  Future<TodoData?> _findTodo({
    required String projectId,
    required String title,
    required String? dueDate,
  }) async {
    final List<TodoData> rows = await (_db.select(_db.todo)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.status.equals(TodoStatus.open.code) &
                t.projectId.equals(projectId) &
                t.title.equals(title) &
                (dueDate == null ? t.dueDate.isNull() : t.dueDate.equals(dueDate)),
          ))
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final List<TodoData> sorted = List<TodoData>.of(rows)
      ..sort((TodoData a, TodoData b) {
        final int byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return sorted.first;
  }

  Future<void> _insertTodo({
    required String projectId,
    required String title,
    required String dueDate,
    required String deviceId,
    required int ts,
  }) async {
    final String id = uuidV7();
    await repos.oplog.writeWithOplog<void>(
      table: 'todo',
      id: id,
      changedFields: <String, Object?>{
        'title': title,
        'status': TodoStatus.open.code,
        'due_date': dueDate,
        'project_id': projectId,
      },
      write: () => _db.into(_db.todo).insert(
            TodoCompanion.insert(
              id: id,
              title: title,
              dueDate: Value<String>(dueDate),
              projectId: Value<String>(projectId),
              status: Value<String>(TodoStatus.open.code),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );
  }

  Future<void> _updateTodo({
    required TodoData row,
    required String? dueDate,
    required String title,
    required String deviceId,
    required int ts,
  }) async {
    await repos.oplog.writeWithOplog<void>(
      table: 'todo',
      id: row.id,
      changedFields: <String, Object?>{
        'title': title,
        'due_date': dueDate,
      },
      write: () => (_db.update(_db.todo)..where((t) => t.id.equals(row.id))).write(
            TodoCompanion(
              title: Value<String>(title),
              dueDate: Value<String?>(dueDate),
              updatedAt: Value<int>(ts),
              originDeviceId: Value<String>(deviceId),
              rev: Value<int>(row.rev + 1),
            ),
          ),
    );
  }
}

/// 一条任务是否**逾期**：目标日已过、且尚未达成。
///
/// 三条同时成立才算逾期（任务 C 的全部规则）：
///  * `target_date != null` —— 没排期就谈不上逾期；
///  * `achieved_at == null` —— 已达成的不再催；
///  * `target_date < today` —— **当天到期不算逾期**（今天还有一整天可用）。
bool milestoneOverdue(MilestoneRow milestone, String todayIso) {
  final String? target = milestone.targetDate;
  if (target == null || milestone.achievedAt != null) {
    return false;
  }
  return target.compareTo(todayIso) < 0;
}

/// 把 `YYYY-MM-DD` 换成 UTC 零点（只算整日差，不掺时区 / DST）。
DateTime _utcOfIso(String iso) {
  final List<String> parts = iso.split('-');
  if (parts.length != 3) {
    throw ArgumentError.value(iso, 'iso', '日期必须是 YYYY-MM-DD 格式');
  }
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// `toIso - fromIso` 的整日数。
int _daysBetween(String fromIso, String toIso) =>
    _utcOfIso(toIso).difference(_utcOfIso(fromIso)).inDays;

/// Unix 毫秒 → 本地日历日 `YYYY-MM-DD`（与 `today()` 的本地口径一致）。
String _isoOfMillis(int millis) {
  final DateTime local = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-${two(local.day)}';
}
