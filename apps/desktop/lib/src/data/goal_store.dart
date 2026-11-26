// =============================================================================
// 目标体系 · 数据层通道（Task 65 · schema v3）
// =============================================================================
// 为什么不放在 `packages\core_data`：`goal` / `goal_link` 是 v3 才有的两张新表，
// core_data 本轮**不许动**；所以写入通道落在这个文件里，与 `project_store.dart`
// 同一套账本规矩（`uuidV7()` + `nowMillis()` + `resolveDeviceId()` + `rev + 1`
// + `writeWithOplog`），同步侧看到的是正常记录，而不是裸 SQL 写进去的孤儿行。
//
// 三条硬规矩（来自计划 §4.3 与 §12）：
//   1. **派生量一律不入库**：完成度 / 达成率 / 各层汇总 / 「未落位」标记
//      全部现算（[GoalExecutionStats] / [GoalYearSummary]），库里没有对应列。
//   2. **删除一律软删**：写 `deleted_at` 墓碑，不物理删；重新关联必须
//      **复用那一行并清掉墓碑**（`goal_link` 的唯一约束覆盖全表，墓碑仍占槽位）。
//   3. **周期滚动只出草稿**：[rollWeeklyDrafts] 只算不写（库中 0 增量），
//      [saveWeeklyDrafts] 落库时 `status` 仍是 `'draft'`，激活由界面层决定。
//
// 口径说明（都写在这里，避免界面层各自发明一套）：
//   · 周期一律 **UTC**（`period_start` = 周期第一刻，`period_end` = 末刻，含）。
//   · 「本周期」= `period_start` **等于**该周期起点的行（计划 §6.4：
//     `period_start` 是判据来源）。
//   · 完成度 = `tracks` 关联的 `plan_item` 里 `done` 的占比（排除 `cancelled`；
//     无关联记 0）。达成率 = 上层目标下挂子目标里 `done` 的占比。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink, nowMillis;
import 'package:core_domain/core_domain.dart'
    show
        DomainValidationException,
        Goal,
        GoalFacet,
        GoalField,
        GoalHorizon,
        GoalKind,
        GoalLink,
        GoalPeriod,
        GoalPeriodUnit,
        GoalQuadrant,
        GoalRelation,
        GoalStatus,
        GoalTargetType,
        PlanStatus,
        PriorityAbc,
        Quadrant;
import 'package:drift/drift.dart';

/// 目标行找不到时的异常（id 写错，或行已被软删）。
///
/// 刻意**不**写中文消息：它会进日志，也可能被没有 l10n 上下文的地方直接打印；
/// 界面层要上屏的话按 [id] 去查本地化文案（先例：`project_store.dart` 的
/// `MissingEntityException`）。
class GoalMissingException implements Exception {
  /// 构造。
  const GoalMissingException(this.id);

  /// 找不到的那条目标 id。
  final String id;

  @override
  String toString() => 'GoalMissingException(id: $id)';
}

/// 一条目标的行模型（读侧）。
class GoalRow {
  /// 构造。
  const GoalRow({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    required this.periodStart,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.keywords,
    this.parentId,
    this.domain,
    this.horizon,
    this.facet,
    this.periodEnd,
    this.dueDate,
    this.quadrant,
    this.priorityAbc,
    this.selfScore,
    this.reviewNote,
    this.improveNote,
    this.archivedAt,
    this.rev = 1,
  });

  /// 目标 id。
  final String id;

  /// 目标形态。
  final GoalKind kind;

  /// 目标一句话。
  final String title;

  /// 展开说明 / 愿景描述。
  final String? note;

  /// 关键词 / 标签串。
  final String? keywords;

  /// 上级目标 id（null = 顶层）。
  final String? parentId;

  /// 领域 key（Task 59 六 key；null = 未分类）。
  final String? domain;

  /// 蓝图档位。
  final GoalHorizon? horizon;

  /// 品牌画像切面。
  final GoalFacet? facet;

  /// 周期起点（UTC 毫秒）。
  final int periodStart;

  /// 周期终点（UTC 毫秒，含；null = 无固定终点）。
  final int? periodEnd;

  /// 完成期限（UTC 毫秒）。
  final int? dueDate;

  /// 四象限。
  final Quadrant? quadrant;

  /// ABC 优先级。
  final PriorityAbc? priorityAbc;

  /// 状态。
  final GoalStatus status;

  /// 用户自评 0..10（源数据；null = 未评）。
  final int? selfScore;

  /// 未完成原因 / 障碍。
  final String? reviewNote;

  /// 改进措施 / 克服对策。
  final String? improveNote;

  /// 取消线（UTC 毫秒）。
  final int? archivedAt;

  /// 创建时刻（UTC 毫秒）。
  final int createdAt;

  /// 最后更新时刻（UTC 毫秒）。
  final int updatedAt;

  /// 本地修订号。
  final int rev;

  /// 是否已完成（`status == 'done'`）。
  bool get isDone => status == GoalStatus.done;
}

/// 一条目标关联的行模型（读侧）。
class GoalLinkRow {
  /// 构造。
  const GoalLinkRow({
    required this.id,
    required this.goalId,
    required this.targetType,
    required this.targetId,
    required this.relation,
  });

  /// 关联行 id。
  final String id;

  /// 所属目标 id。
  final String goalId;

  /// 关联目标类型。
  final GoalTargetType targetType;

  /// 关联目标 id。
  final String targetId;

  /// 关系语义。
  final GoalRelation relation;
}

/// 一条目标的派生统计（**不入库**）。
class GoalExecutionStats {
  /// 构造。
  const GoalExecutionStats({
    required this.tracksCount,
    required this.tracksInPeriod,
    required this.servesCount,
    required this.planItemTotal,
    required this.planItemDone,
    required this.planItemCancelled,
    required this.userCompleted,
    required this.isDiscrepant,
    required this.isUnplaced,
  });

  /// `tracks` 关联总数（不限周期）。
  final int tracksCount;

  /// 落在本周期内的执行实体数（`plan_item` 按日期算，其余类型一律算在内）。
  final int tracksInPeriod;

  /// `serves` 上层目标数（对齐链）。
  final int servesCount;

  /// 计入完成度的 `plan_item` 总数（已排除 `cancelled`）。
  final int planItemTotal;

  /// 其中 `done` 的条数。
  final int planItemDone;

  /// 被排除的 `cancelled` 条数。
  final int planItemCancelled;

  /// 用户手勾完成（`status == 'done'`）。
  final bool userCompleted;

  /// 手勾与实际计划项状态**不一致**（界面层给提示，不静默改数据）。
  final bool isDiscrepant;

  /// **未落位**：既没有 `tracks` 执行实体，也没有 `serves` 对齐链。
  final bool isUnplaced;

  /// 完成度 0..1（无关联记 0）。
  double get completionRate =>
      planItemTotal == 0 ? 0 : planItemDone / planItemTotal;

  /// 界面上的「完成」显示位（两者不一致时以「未完成」显示）。
  bool get displayCompleted => userCompleted && !isDiscrepant;
}

/// 周视图里的一行（右块「本周目标」表的一行）。
class GoalWeekItem {
  /// 构造。
  const GoalWeekItem({
    required this.goal,
    required this.stats,
    required this.order,
    this.servedGoal,
  });

  /// 目标本体。
  final GoalRow goal;

  /// 派生统计。
  final GoalExecutionStats stats;

  /// 优先顺序（1 起；按 `quadrant` 再按 `priority_abc` 排出来的显示序号）。
  final int order;

  /// 「服务于」列：它 `serves` 的上层目标（通常���本月目标）。
  final GoalRow? servedGoal;
}

/// 周视图读模型（右块「本周目标」表）。
class GoalWeekView {
  /// 构造。
  const GoalWeekView({required this.period, required this.items});

  /// 本周周期。
  final GoalPeriod period;

  /// 本周目标（已按优先顺序排好）。
  final List<GoalWeekItem> items;
}

/// 年目标派生汇总（顶部年度汇总条；**不入库**）。
class GoalYearSummary {
  /// 构造。
  const GoalYearSummary({
    required this.goal,
    required this.childTotal,
    required this.childDone,
  });

  /// 年目标本体。
  final GoalRow goal;

  /// 下挂子目标总数（`serves` 它的月目标）。
  final int childTotal;

  /// 其中 `done` 的条数。
  final int childDone;

  /// 达成率 0..1（无子目标记 0）。
  double get achievementRate => childTotal == 0 ? 0 : childDone / childTotal;
}

/// 月视图读模型（上块「上月复盘」+ 下块「本月目标」+ 顶部年度汇总条）。
class GoalMonthView {
  /// 构造。
  const GoalMonthView({
    required this.period,
    required this.monthGoals,
    required this.previousMonthGoals,
    required this.yearSummaries,
  });

  /// 本月周期。
  final GoalPeriod period;

  /// 本月目标。
  final List<GoalRow> monthGoals;

  /// 上月目标（复盘用）。
  final List<GoalRow> previousMonthGoals;

  /// 顶部年度汇总条（本月目标所 `serves` 的年目标）。
  final List<GoalYearSummary> yearSummaries;
}

/// 滚动候选的来源。
enum GoalDraftOrigin {
  /// 由上周未完成的周目标**结转**而来（计划 §6.4 第 ① 步）。
  carryOver,

  /// 由本月目标**派生**而来（本月目标本周尚无任何执行实体）。
  fromUpperLayer,
}

/// 一条滚动候选（**草稿**，落库时 `status='draft'`）。
class GoalDraft {
  /// 构造。
  const GoalDraft({
    required this.kind,
    required this.title,
    required this.periodStart,
    required this.periodEnd,
    this.parentId,
    this.domain,
    this.quadrant,
    this.priorityAbc,
    this.note,
    this.sourceGoalId,
    this.origin = GoalDraftOrigin.carryOver,
  });

  /// 目标形态（滚动只产 `weekly`）。
  final GoalKind kind;

  /// 目标一句话。
  final String title;

  /// 周期起点（UTC 毫秒）。
  final int periodStart;

  /// 周期终点（UTC 毫秒，含）。
  final int periodEnd;

  /// 落库后要 `serves` 的上层目标 id。
  final String? parentId;

  /// 领域 key。
  final String? domain;

  /// 四象限。
  final Quadrant? quadrant;

  /// ABC 优先级。
  final PriorityAbc? priorityAbc;

  /// 默认备注（结转时取上周的 `improve_note` / `review_note`）。
  final String? note;

  /// 来源目标 id（落库后要 `derives` 的那条）。
  final String? sourceGoalId;

  /// 候选来源。
  final GoalDraftOrigin origin;
}

/// 目标体系的数据层通道。
///
/// 所有写操作都走 `repos.oplog.writeWithOplog`（业务写入与 oplog 同事务），
/// 删除一律软删写墓碑。
class GoalStore {
  /// 构造。
  GoalStore(this.repos);

  /// 仓储集合（只用它的 `db` 与 `oplog`）。
  final ActLogRepositories repos;

  ActLogDatabase get _db => repos.db;

  // ---------------------------------------------------------------------------
  // 目标 CRUD
  // ---------------------------------------------------------------------------

  /// 新建一条目标，返回新的 `goal.id`。
  ///
  /// 校验口径与 `goal` 表的 CHECK 约束一致，但错误是**可读中文**
  /// （[DomainValidationException]），且**抛异常时一行都不写**。
  ///
  /// [domain] 是稳定的英文小写领域 key（`career` / `wealth` / `family` /
  /// `learning` / `social` / `health`）；留空 = 未分类。列上**没有** CHECK
  /// 约束（自由文本），所以这里不校验取值域 —— 同步进来的历史 key 照样能存。
  Future<String> createGoal({
    required GoalKind kind,
    required String title,
    String? note,
    String? keywords,
    String? parentId,
    String? domain,
    GoalHorizon? horizon,
    GoalFacet? facet,
    int periodStart = 0,
    int? periodEnd,
    int? dueDate,
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
    GoalStatus status = GoalStatus.active,
    int? selfScore,
    String? reviewNote,
    String? improveNote,
  }) async {
    final String id = uuidV7();
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    final Goal goal = Goal.create(
      id: id,
      kind: kind,
      title: title,
      createdAt: ts,
      updatedAt: ts,
      originDeviceId: deviceId,
      note: note,
      keywords: keywords,
      parentId: parentId,
      domain: domain,
      horizon: horizon,
      facet: facet,
      periodStart: periodStart,
      periodEnd: periodEnd,
      dueDate: dueDate,
      quadrant: quadrant,
      priorityAbc: priorityAbc,
      status: status,
      selfScore: selfScore,
      reviewNote: reviewNote,
      improveNote: improveNote,
    );

    await repos.oplog.writeWithOplog<void>(
      table: 'goal',
      id: id,
      changedFields: <String, Object?>{
        'kind': goal.kind.code,
        'title': goal.title,
        'period_start': goal.periodStart,
        'status': goal.status.code,
      },
      write: () => _db.into(_db.goal).insert(
            GoalCompanion.insert(
              id: id,
              kind: goal.kind.code,
              title: goal.title,
              note: Value<String?>(goal.note),
              keywords: Value<String?>(goal.keywords),
              parentId: Value<String?>(goal.parentId),
              domain: Value<String?>(goal.domain),
              horizon: Value<int?>(goal.horizon?.value),
              facet: Value<String?>(goal.facet?.code),
              periodStart: Value<int>(goal.periodStart),
              periodEnd: Value<int?>(goal.periodEnd),
              dueDate: Value<int?>(goal.dueDate),
              quadrant: Value<int?>(
                goal.quadrant == null ? null : GoalQuadrant.encode(goal.quadrant!),
              ),
              priorityAbc: Value<String?>(goal.priorityAbc?.code),
              status: Value<String>(goal.status.code),
              selfScore: Value<int?>(goal.selfScore),
              reviewNote: Value<String?>(goal.reviewNote),
              improveNote: Value<String?>(goal.improveNote),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );
    return id;
  }

  /// 改一条目标。
  ///
  /// 语义：**传了值 = 改成这个值；字段在 [clear] 里 = 显式置空；两样都没做 = 不动。**
  /// 普通 `copyWith(note: null)` 分不清「不改」与「清空」，所以用 [clear] 集合。
  ///
  /// [clear] 里出现的字段优先于同名实参（显式置空胜出）。
  ///
  /// 目标不存在或已被软删时抛 [GoalMissingException]。
  Future<void> updateGoal(
    String goalId, {
    String? title,
    GoalKind? kind,
    GoalStatus? status,
    int? selfScore,
    int? periodStart,
    int? periodEnd,
    int? dueDate,
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
    GoalHorizon? horizon,
    GoalFacet? facet,
    String? parentId,
    String? domain,
    String? note,
    String? keywords,
    String? reviewNote,
    String? improveNote,
    Set<GoalField> clear = const <GoalField>{},
  }) async {
    final GoalData? current = await _findGoalRow(goalId);
    if (current == null) {
      throw GoalMissingException(goalId);
    }

    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    // B10-B3：归档时刻由 `status` 派生，调用点只传 `status`（不改 API、不加 schema）。
    final GoalStatus nextStatus = status ?? _statusOf(current);

    // 合并 → 用领域工厂统一校验（标题非空 / 自评 0..10 / 周期顺序 / 归档口径）。
    final Goal merged = Goal.create(
      id: current.id,
      kind: kind ?? _kindOf(current),
      title: title ?? current.title,
      createdAt: current.createdAt,
      updatedAt: ts,
      originDeviceId: deviceId,
      note: clear.contains(GoalField.note) ? null : (note ?? current.note),
      keywords:
          clear.contains(GoalField.keywords) ? null : (keywords ?? current.keywords),
      parentId:
          clear.contains(GoalField.parentId) ? null : (parentId ?? current.parentId),
      domain: clear.contains(GoalField.domain) ? null : (domain ?? current.domain),
      horizon: clear.contains(GoalField.horizon)
          ? null
          : (horizon ?? GoalHorizon.fromValue(current.horizon)),
      facet: clear.contains(GoalField.facet)
          ? null
          : (facet ?? GoalFacet.fromCode(current.facet)),
      periodStart: periodStart ?? current.periodStart,
      periodEnd: clear.contains(GoalField.periodEnd)
          ? null
          : (periodEnd ?? current.periodEnd),
      dueDate: clear.contains(GoalField.dueDate) ? null : (dueDate ?? current.dueDate),
      quadrant: clear.contains(GoalField.quadrant)
          ? null
          : (quadrant ?? GoalQuadrant.decode(current.quadrant)),
      priorityAbc: clear.contains(GoalField.priorityAbc)
          ? null
          : (priorityAbc ?? PriorityAbc.fromCode(current.priorityAbc)),
      status: nextStatus,
      selfScore: clear.contains(GoalField.selfScore)
          ? null
          : (selfScore ?? current.selfScore),
      reviewNote: clear.contains(GoalField.reviewNote)
          ? null
          : (reviewNote ?? current.reviewNote),
      improveNote: clear.contains(GoalField.improveNote)
          ? null
          : (improveNote ?? current.improveNote),
      // done ⇒ 保留已有归档时刻，没有就记此刻；非 done ⇒ 必须清空
      // （`Goal.create` 校验：非 done 带 archivedAt 会直接抛「只有完成的目标才能进归档」）。
      archivedAt: nextStatus == GoalStatus.done
          ? (current.archivedAt ?? ts)
          : null,
      rev: current.rev + 1,
    );

    final Map<String, Object?> changed = _diff(current, merged);
    if (changed.isEmpty) {
      return;
    }

    await repos.oplog.writeWithOplog<void>(
      table: 'goal',
      id: goalId,
      changedFields: changed,
      write: () =>
          (_db.update(_db.goal)..where((t) => t.id.equals(goalId))).write(
        GoalCompanion(
          kind: Value<String>(merged.kind.code),
          title: Value<String>(merged.title),
          note: Value<String?>(merged.note),
          keywords: Value<String?>(merged.keywords),
          parentId: Value<String?>(merged.parentId),
          domain: Value<String?>(merged.domain),
          horizon: Value<int?>(merged.horizon?.value),
          facet: Value<String?>(merged.facet?.code),
          periodStart: Value<int>(merged.periodStart),
          periodEnd: Value<int?>(merged.periodEnd),
          dueDate: Value<int?>(merged.dueDate),
          quadrant: Value<int?>(
            merged.quadrant == null
                ? null
                : GoalQuadrant.encode(merged.quadrant!),
          ),
          priorityAbc: Value<String?>(merged.priorityAbc?.code),
          status: Value<String>(merged.status.code),
          selfScore: Value<int?>(merged.selfScore),
          reviewNote: Value<String?>(merged.reviewNote),
          improveNote: Value<String?>(merged.improveNote),
          // 归档时刻必须与 `status` 同一次写入（否则领域校验与库内状态会脱节）。
          archivedAt: Value<int?>(merged.archivedAt),
          updatedAt: Value<int>(ts),
          originDeviceId: Value<String>(deviceId),
          rev: Value<int>(current.rev + 1),
        ),
      ),
    );
  }

  /// 软删一条目标（写 `deleted_at` 墓碑，**不物理删**）。
  ///
  /// 目标不存在或已被软删时抛 [GoalMissingException]。
  Future<void> deleteGoal(String goalId) async {
    final GoalData? current = await _findGoalRow(goalId);
    if (current == null) {
      throw GoalMissingException(goalId);
    }
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await repos.oplog.writeWithOplog<void>(
      table: 'goal',
      id: goalId,
      isDelete: true,
      deletedAt: ts,
      write: () =>
          (_db.update(_db.goal)..where((t) => t.id.equals(goalId))).write(
        GoalCompanion(
          deletedAt: Value<int>(ts),
          updatedAt: Value<int>(ts),
          originDeviceId: Value<String>(deviceId),
          rev: Value<int>(current.rev + 1),
        ),
      ),
    );
  }

  /// 读一条目标（不含墓碑）；不存在返回 null。
  Future<GoalRow?> findGoal(String goalId) async {
    final GoalData? row = await _findGoalRow(goalId);
    return row == null ? null : _toRow(row);
  }

  /// 列出目标（不含墓碑）。
  ///
  /// [period] 按 `period_start` 落在该周期窗口内筛选；[kind] / [status] /
  /// [parentId] 是可选的等值筛选。
  Future<List<GoalRow>> listGoals({
    GoalKind? kind,
    GoalStatus? status,
    GoalPeriod? period,
    String? parentId,
  }) async {
    final query = _db.select(_db.goal)
      ..where((t) => t.deletedAt.isNull());
    if (kind != null) {
      query.where((t) => t.kind.equals(kind.code));
    }
    if (status != null) {
      query.where((t) => t.status.equals(status.code));
    }
    if (parentId != null) {
      query.where((t) => t.parentId.equals(parentId));
    }
    if (period != null) {
      query.where(
        (t) =>
            t.periodStart.isBetweenValues(period.startMillis, period.endMillis),
      );
    }
    final List<GoalData> rows = await query.get();
    final List<GoalRow> result = rows.map(_toRow).toList();
    result.sort(_compareGoals);
    return result;
  }

  // ---------------------------------------------------------------------------
  // 目标关联（goal_link）
  // ---------------------------------------------------------------------------

  /// 关联一条执行实体 / 上层目标，返回 `goal_link.id`。
  ///
  /// **幂等**：同一 `(goal_id, target_type, target_id)` 已经有行（含墓碑）时，
  /// **复用那一行并清掉墓碑**，而不是再插一行 —— `goal_link` 的唯一约束覆盖
  /// 全表，墓碑行仍然占着那个槽位。
  Future<String> link({
    required String goalId,
    required GoalTargetType targetType,
    required String targetId,
    GoalRelation relation = GoalRelation.serves,
  }) async {
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    final GoalLink draft = GoalLink.create(
      id: uuidV7(),
      goalId: goalId,
      targetType: targetType,
      targetId: targetId,
      relation: relation,
      createdAt: ts,
      updatedAt: ts,
      originDeviceId: deviceId,
    );

    final GoalLinkData? existing = await _findLinkRow(goalId, targetType, targetId);
    if (existing != null) {
      await repos.oplog.writeWithOplog<void>(
        table: 'goal_link',
        id: existing.id,
        changedFields: <String, Object?>{'relation': relation.code},
        write: () =>
            (_db.update(_db.goalLink)..where((t) => t.id.equals(existing.id))).write(
          GoalLinkCompanion(
            relation: Value<String>(relation.code),
            deletedAt: const Value<int?>(null),
            updatedAt: Value<int>(ts),
            originDeviceId: Value<String>(deviceId),
            rev: Value<int>(existing.rev + 1),
          ),
        ),
      );
      return existing.id;
    }

    await repos.oplog.writeWithOplog<void>(
      table: 'goal_link',
      id: draft.id,
      changedFields: <String, Object?>{
        'goal_id': goalId,
        'target_type': targetType.code,
        'target_id': targetId,
        'relation': relation.code,
      },
      write: () => _db.into(_db.goalLink).insert(
            GoalLinkCompanion.insert(
              id: draft.id,
              goalId: goalId,
              targetType: targetType.code,
              targetId: targetId,
              relation: Value<String>(relation.code),
              createdAt: ts,
              updatedAt: ts,
              originDeviceId: deviceId,
            ),
          ),
    );
    return draft.id;
  }

  /// 断开一条关联（软删：写 `deleted_at` 墓碑）。
  ///
  /// 已经断开时**什么都不做**（幂等），不抛异常。
  Future<void> unlink({
    required String goalId,
    required GoalTargetType targetType,
    required String targetId,
  }) async {
    final GoalLinkData? existing = await _findLinkRow(goalId, targetType, targetId);
    if (existing == null || existing.deletedAt != null) {
      return;
    }
    final int ts = nowMillis();
    final String deviceId = await repos.oplog.resolveDeviceId();

    await repos.oplog.writeWithOplog<void>(
      table: 'goal_link',
      id: existing.id,
      isDelete: true,
      deletedAt: ts,
      write: () =>
          (_db.update(_db.goalLink)..where((t) => t.id.equals(existing.id))).write(
        GoalLinkCompanion(
          deletedAt: Value<int>(ts),
          updatedAt: Value<int>(ts),
          originDeviceId: Value<String>(deviceId),
          rev: Value<int>(existing.rev + 1),
        ),
      ),
    );
  }

  /// 列出一条目标的**活着的**关联（不含墓碑）。
  ///
  /// [relation] 给了就只取该语义的那一类。
  Future<List<GoalLinkRow>> listLinks(
    String goalId, {
    GoalRelation? relation,
  }) async {
    final query = _db.select(_db.goalLink)
      ..where((t) => t.goalId.equals(goalId) & t.deletedAt.isNull());
    if (relation != null) {
      query.where((t) => t.relation.equals(relation.code));
    }
    final List<GoalLinkData> rows = await query.get();
    return rows
        .map(
          (GoalLinkData row) => GoalLinkRow(
            id: row.id,
            goalId: row.goalId,
            targetType: GoalTargetType.fromCode(row.targetType) ??
                GoalTargetType.planItem,
            targetId: row.targetId,
            relation: GoalRelation.fromCode(row.relation) ?? GoalRelation.serves,
          ),
        )
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // 派生量（不入库）
  // ---------------------------------------------------------------------------

  /// 算一条目标的派生统计。
  ///
  /// [period] 给了就把执行实体限制在该周期内（`plan_item` 按 `date` 判定）；
  /// 不给就是全量口径。
  Future<GoalExecutionStats> statsOf(
    String goalId, {
    GoalPeriod? period,
  }) async {
    final List<GoalLinkRow> links = await listLinks(goalId);
    final List<GoalLinkRow> tracks = links
        .where((GoalLinkRow l) => l.relation == GoalRelation.tracks)
        .toList(growable: false);
    final int servesCount = links
        .where(
          (GoalLinkRow l) =>
              l.relation == GoalRelation.serves &&
              l.targetType == GoalTargetType.goal,
        )
        .length;

    final Set<String> planItemIds = tracks
        .where((GoalLinkRow l) => l.targetType == GoalTargetType.planItem)
        .map((GoalLinkRow l) => l.targetId)
        .toSet();

    var total = 0;
    var done = 0;
    var cancelled = 0;
    var tracksInPeriod = tracks.length - planItemIds.length;
    if (planItemIds.isNotEmpty) {
      final List<PlanItemData> items = await (_db.select(_db.planItem)
            ..where((t) => t.id.isIn(planItemIds) & t.deletedAt.isNull()))
          .get();
      for (final PlanItemData item in items) {
        final bool inPeriod = period == null || _dateInPeriod(item.date, period);
        if (inPeriod) {
          tracksInPeriod++;
        }
        if (!inPeriod) {
          continue;
        }
        final PlanStatus? status = PlanStatus.fromCode(item.status);
        if (status == PlanStatus.cancelled) {
          cancelled++;
          continue;
        }
        total++;
        if (status == PlanStatus.done) {
          done++;
        }
      }
    }

    final GoalRow? goal = await findGoal(goalId);
    final bool userCompleted = goal?.isDone ?? false;
    final bool trackedCompleted = total > 0 && done == total;

    return GoalExecutionStats(
      tracksCount: tracks.length,
      tracksInPeriod: tracksInPeriod,
      servesCount: servesCount,
      planItemTotal: total,
      planItemDone: done,
      planItemCancelled: cancelled,
      userCompleted: userCompleted,
      isDiscrepant: total > 0 && userCompleted != trackedCompleted,
      isUnplaced: tracks.isEmpty && servesCount == 0,
    );
  }

  /// 一条目标 `serves` 的上层目标（`target_type='goal'` 的 `serves` 关联）。
  Future<List<GoalRow>> servedGoals(String goalId) async {
    final List<GoalLinkRow> links = await listLinks(
      goalId,
      relation: GoalRelation.serves,
    );
    final List<GoalRow> result = <GoalRow>[];
    for (final GoalLinkRow link in links) {
      if (link.targetType != GoalTargetType.goal) {
        continue;
      }
      final GoalRow? row = await findGoal(link.targetId);
      if (row != null) {
        result.add(row);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // 读模型
  // ---------------------------------------------------------------------------

  /// 周视图（右块「本周目标」表）。
  ///
  /// 列口径（计划 §5.1）：优先顺序 | 目标 | 象限 | 完成期限 | 完成 | 服务于。
  /// 排序：先 `quadrant`（null 排最后）再 `priority_abc`（null 排最后），
  /// 「优先顺序」就是这个排序出来的显示序号。
  Future<GoalWeekView> weekView(GoalPeriod period) async {
    final List<GoalRow> goals = await _goalsInPeriod(GoalKind.weekly, period);
    final List<GoalWeekItem> items = <GoalWeekItem>[];
    for (final GoalRow goal in goals) {
      final GoalExecutionStats stats = await statsOf(goal.id, period: period);
      final List<GoalRow> parents = await servedGoals(goal.id);
      items.add(
        GoalWeekItem(
          goal: goal,
          stats: stats,
          order: 0, // 排序后重编（见下面的 order: i + 1）。
          servedGoal: parents.isEmpty ? null : parents.first,
        ),
      );
    }
    items.sort(_compareWeekItems);
    return GoalWeekView(
      period: period,
      items: <GoalWeekItem>[
        for (int i = 0; i < items.length; i++)
          GoalWeekItem(
            goal: items[i].goal,
            stats: items[i].stats,
            order: i + 1,
            servedGoal: items[i].servedGoal,
          ),
      ],
    );
  }

  /// 月视图（上块「上月复盘」+ 下块「本月目标」+ 顶部年度汇总条）。
  ///
  /// 年度汇总条 = 本月目标所 `serves` 的年目标，其进度是**派生**的
  /// （下挂月目标里 `done` 的占比），库里没有这一列。
  Future<GoalMonthView> monthView(GoalPeriod period) async {
    final List<GoalRow> monthGoals = await _goalsInPeriod(GoalKind.monthly, period);
    final List<GoalRow> previousGoals =
        await _goalsInPeriod(GoalKind.monthly, period.previous());

    final List<GoalYearSummary> summaries = <GoalYearSummary>[];
    final Set<String> seen = <String>{};
    for (final GoalRow month in monthGoals) {
      for (final GoalRow parent in await servedGoals(month.id)) {
        if (parent.kind != GoalKind.yearly || !seen.add(parent.id)) {
          continue;
        }
        summaries.add(await _yearSummary(parent));
      }
    }

    return GoalMonthView(
      period: period,
      monthGoals: monthGoals,
      previousMonthGoals: previousGoals,
      yearSummaries: summaries,
    );
  }

  // ---------------------------------------------------------------------------
  // 周期滚动（只出草稿）
  // ---------------------------------------------------------------------------

  /// 算出某一周的滚动候选（**只算不写**：库里 0 增量）。
  ///
  /// [targetWeek] = **要生成的那一周**（候选落在这一周）；来源是它的上一周。
  ///
  /// 候选来源（计划 §6.4）：
  ///   ① 上一周 `weekly` 目标里未完成（`status != 'done'`）的 → **结转**候选，
  ///      默认备注取上周的 `improve_note` / `review_note`（§6.4 第 ② 步）；
  ///   ③ 目标周所在月的 `monthly` 目标里「目标周尚无任何执行实体」的 → **派生**候选。
  ///
  /// 结转候选还会带上 `serves` 的上层目标（上一周那条所服务的月目标；没有就取
  /// 目标月里唯一的那条月目标），落库时与 `derives`（→ 上一周）成对出现，
  /// 对齐 §6.4 第 ④ 步「写 weekly 行 + serves(→本月) + derives(→上周)」。
  Future<List<GoalDraft>> rollWeeklyDrafts(GoalPeriod targetWeek) async {
    final List<GoalDraft> drafts = <GoalDraft>[];

    final List<GoalRow> lastWeek =
        await _goalsInPeriod(GoalKind.weekly, targetWeek.previous());
    final GoalPeriod targetMonth = GoalPeriod.fromStartMillis(
      targetWeek.startMillis,
      GoalPeriodUnit.month,
    );
    final List<GoalRow> monthly =
        await _goalsInPeriod(GoalKind.monthly, targetMonth);

    for (final GoalRow goal in lastWeek) {
      if (goal.isDone) {
        continue;
      }
      drafts.add(
        GoalDraft(
          kind: GoalKind.weekly,
          title: goal.title,
          periodStart: targetWeek.startMillis,
          periodEnd: targetWeek.endMillis,
          parentId: await _servedMonthlyGoalId(goal.id, monthly),
          domain: goal.domain,
          quadrant: goal.quadrant,
          priorityAbc: goal.priorityAbc,
          note: goal.improveNote ?? goal.reviewNote,
          sourceGoalId: goal.id,
          origin: GoalDraftOrigin.carryOver,
        ),
      );
    }

    for (final GoalRow goal in monthly) {
      if (goal.isDone) {
        continue;
      }
      final GoalExecutionStats stats =
          await statsOf(goal.id, period: targetWeek);
      if (stats.tracksInPeriod > 0) {
        continue;
      }
      drafts.add(
        GoalDraft(
          kind: GoalKind.weekly,
          title: goal.title,
          periodStart: targetWeek.startMillis,
          periodEnd: targetWeek.endMillis,
          parentId: goal.id,
          domain: goal.domain,
          sourceGoalId: goal.id,
          origin: GoalDraftOrigin.fromUpperLayer,
        ),
      );
    }

    return drafts;
  }

  /// 结转候选的 `serves` 目标：源周目标所服务的月目标；没有则取目标月里唯一的一条。
  Future<String?> _servedMonthlyGoalId(
    String goalId,
    List<GoalRow> monthly,
  ) async {
    for (final GoalRow parent in await servedGoals(goalId)) {
      if (parent.kind == GoalKind.monthly) {
        return parent.id;
      }
    }
    return monthly.length == 1 ? monthly.single.id : null;
  }

  /// 把滚动候选落库（**草稿态**：`status='draft'`）。
  ///
  /// 每条候选落一行 `weekly` 目标，并补两条链：
  ///   · `serves` → [GoalDraft.parentId]（它服务的上层目标）；
  ///   · `derives` → [GoalDraft.sourceGoalId]（它由哪条目标派生）。
  ///
  /// 返回新写入的目标行数（不含关联行）。
  Future<int> saveWeeklyDrafts(List<GoalDraft> drafts) async {
    int written = 0;
    for (final GoalDraft draft in drafts) {
      final String id = await createGoal(
        kind: draft.kind,
        title: draft.title,
        note: draft.note,
        parentId: draft.parentId,
        domain: draft.domain,
        periodStart: draft.periodStart,
        periodEnd: draft.periodEnd,
        quadrant: draft.quadrant,
        priorityAbc: draft.priorityAbc,
        status: GoalStatus.draft,
      );
      written++;
      final String? parentId = draft.parentId;
      if (parentId != null) {
        await link(
          goalId: id,
          targetType: GoalTargetType.goal,
          targetId: parentId,
          relation: GoalRelation.serves,
        );
      }
      final String? sourceGoalId = draft.sourceGoalId;
      if (sourceGoalId != null && sourceGoalId != parentId) {
        await link(
          goalId: id,
          targetType: GoalTargetType.goal,
          targetId: sourceGoalId,
          relation: GoalRelation.derives,
        );
      }
    }
    return written;
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  Future<GoalData?> _findGoalRow(String goalId) async {
    return (_db.select(_db.goal)
          ..where((t) => t.id.equals(goalId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<GoalLinkData?> _findLinkRow(
    String goalId,
    GoalTargetType targetType,
    String targetId,
  ) async {
    return (_db.select(_db.goalLink)
          ..where(
            (t) =>
                t.goalId.equals(goalId) &
                t.targetType.equals(targetType.code) &
                t.targetId.equals(targetId),
          ))
        .getSingleOrNull();
  }

  /// 某个周期内的目标（判据：`period_start` **等于**该周期起点）。
  Future<List<GoalRow>> _goalsInPeriod(
    GoalKind kind,
    GoalPeriod period,
  ) async {
    final List<GoalData> rows = await (_db.select(_db.goal)
          ..where(
            (t) =>
                t.kind.equals(kind.code) &
                t.periodStart.equals(period.startMillis) &
                t.deletedAt.isNull(),
          ))
        .get();
    final List<GoalRow> result = rows.map(_toRow).toList();
    result.sort(_compareGoals);
    return result;
  }

  Future<GoalYearSummary> _yearSummary(GoalRow yearGoal) async {
    // `serves` 的方向是「子 → 父」（子目标那条链指向年目标），
    // 所以年目标的子目标 = **指向**它的 `serves` 链。
    final List<GoalLinkData> links = await (_db.select(_db.goalLink)
          ..where(
            (t) =>
                t.targetType.equals(GoalTargetType.goal.code) &
                t.targetId.equals(yearGoal.id) &
                t.relation.equals(GoalRelation.serves.code) &
                t.deletedAt.isNull(),
          ))
        .get();
    int total = 0;
    int done = 0;
    for (final GoalLinkData link in links) {
      final GoalRow? child = await findGoal(link.goalId);
      if (child == null) {
        continue;
      }
      total++;
      if (child.isDone) {
        done++;
      }
    }
    return GoalYearSummary(
      goal: yearGoal,
      childTotal: total,
      childDone: done,
    );
  }

  GoalRow _toRow(GoalData row) {
    return GoalRow(
      id: row.id,
      kind: _kindOf(row),
      title: row.title,
      note: row.note,
      keywords: row.keywords,
      parentId: row.parentId,
      domain: row.domain,
      horizon: GoalHorizon.fromValue(row.horizon),
      facet: GoalFacet.fromCode(row.facet),
      periodStart: row.periodStart,
      periodEnd: row.periodEnd,
      dueDate: row.dueDate,
      quadrant: GoalQuadrant.decode(row.quadrant),
      priorityAbc: PriorityAbc.fromCode(row.priorityAbc),
      status: _statusOf(row),
      selfScore: row.selfScore,
      reviewNote: row.reviewNote,
      improveNote: row.improveNote,
      archivedAt: row.archivedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      rev: row.rev,
    );
  }

  GoalKind _kindOf(GoalData row) {
    final GoalKind? kind = GoalKind.fromCode(row.kind);
    if (kind == null) {
      throw StateError('goal.kind 取值非法：${row.kind}');
    }
    return kind;
  }

  GoalStatus _statusOf(GoalData row) {
    return GoalStatus.fromCode(row.status) ?? GoalStatus.active;
  }

  /// 字段级 diff（只含真正变了的列），写进 oplog 的 payload。
  Map<String, Object?> _diff(GoalData current, Goal merged) {
    final Map<String, Object?> changed = <String, Object?>{};
    void put(String column, Object? before, Object? after) {
      if (before != after) {
        changed[column] = after;
      }
    }

    put('kind', current.kind, merged.kind.code);
    put('title', current.title, merged.title);
    put('note', current.note, merged.note);
    put('keywords', current.keywords, merged.keywords);
    put('parent_id', current.parentId, merged.parentId);
    put('domain', current.domain, merged.domain);
    put('horizon', current.horizon, merged.horizon?.value);
    put('facet', current.facet, merged.facet?.code);
    put('period_start', current.periodStart, merged.periodStart);
    put('period_end', current.periodEnd, merged.periodEnd);
    put('due_date', current.dueDate, merged.dueDate);
    put('quadrant', current.quadrant, merged.quadrant == null ? null : GoalQuadrant.encode(merged.quadrant!));
    put('priority_abc', current.priorityAbc, merged.priorityAbc?.code);
    put('status', current.status, merged.status.code);
    put('self_score', current.selfScore, merged.selfScore);
    put('review_note', current.reviewNote, merged.reviewNote);
    put('improve_note', current.improveNote, merged.improveNote);
    put('archived_at', current.archivedAt, merged.archivedAt);
    return changed;
  }

  /// 目标排序（周期内按象限 → ABC → 标题；其它场景按创建时间）。
  static int _compareGoals(GoalRow a, GoalRow b) {
    final int byTime = a.createdAt.compareTo(b.createdAt);
    if (byTime != 0) {
      return byTime;
    }
    return a.id.compareTo(b.id);
  }

  /// 周视图排序：象限（null 最后）→ ABC（null 最后）→ 标题。
  static int _compareWeekItems(GoalWeekItem a, GoalWeekItem b) {
    final int byQuadrant =
        _quadrantRank(a.goal.quadrant).compareTo(_quadrantRank(b.goal.quadrant));
    if (byQuadrant != 0) {
      return byQuadrant;
    }
    final int byAbc = _abcRank(a.goal.priorityAbc)
        .compareTo(_abcRank(b.goal.priorityAbc));
    if (byAbc != 0) {
      return byAbc;
    }
    final int byTitle = a.goal.title.compareTo(b.goal.title);
    return byTitle != 0 ? byTitle : a.goal.id.compareTo(b.goal.id);
  }

  static int _quadrantRank(Quadrant? quadrant) {
    switch (quadrant) {
      case Quadrant.q1:
        return 1;
      case Quadrant.q2:
        return 2;
      case Quadrant.q3:
        return 3;
      case Quadrant.q4:
        return 4;
      case null:
        return 5;
    }
  }

  static int _abcRank(PriorityAbc? abc) {
    switch (abc) {
      case PriorityAbc.a:
        return 1;
      case PriorityAbc.b:
        return 2;
      case PriorityAbc.c:
        return 3;
      case null:
        return 4;
    }
  }

  /// `'YYYY-MM-DD'` 是否落在周期窗口内（**UTC** 口径）。
  static bool _dateInPeriod(String date, GoalPeriod period) {
    final String start = _utcDate(period.startUtc);
    final String end = _utcDate(period.endUtc);
    return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
  }

  static String _utcDate(DateTime moment) {
    final String y = moment.year.toString().padLeft(4, '0');
    final String m = moment.month.toString().padLeft(2, '0');
    final String d = moment.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
