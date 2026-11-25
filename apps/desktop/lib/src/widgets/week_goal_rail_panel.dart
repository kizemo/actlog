import 'package:core_db/core_db.dart' show PlanItemData;
import 'package:core_domain/core_domain.dart' show GoalTargetType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import 'goal_upstream_panel.dart';
import 'shell/key_bar.dart';
import 'timeline/slot_state.dart';
import 'timeline/timeline_store.dart';

/// 一条周目标加入计划的结果。
enum WeekGoalAddOutcome {
  /// 新建了一条计划行，并建立了目标 ↔ 计划项的关联。
  added,

  /// 当天已经有一条关联到同一条周目标的计划行，本次**什么都没写**。
  alreadyInPlan,
}

/// 把一条未完成周目标加入某一天的「计划」——**三条通道共用的唯一写入入口**。
///
/// 通道：右栏面板点击、从面板拖进日格（payload 由 [goalDragPayloadFor] 生成）、
/// 日格右键勾选浮层。
/// 三个入口都走这一个函数，所以「同一条周目标在同一天只出现一条计划行」这条
/// 幂等只需要在这里实现一次：
///
/// 1. 读该目标活着的 `goal_link`，取出 `target_type='plan_item'` 的目标 id；
/// 2. 用 `plan_item.listByDate(date)` 取那一天**未被软删**的计划行 id；
/// 3. 两个集合有交集 ⇒ 判为已存在，直接返回 [WeekGoalAddOutcome.alreadyInPlan]，
///    一行都不写（既不再建计划行，也不重复建关联）。
///
/// 写入本身不新开第二条路径：
/// - 计划行走 [TimelineStore.createManual]（`source_type='manual'`），与
///   `project_store.scheduleToDay` 落在同一份账本写入实现
///   `widgets/timeline/timeline_store.dart` 的 `_insertPlanItem` 上；
/// - 目标与计划项的关联走 [GoalStore.link]（它对同一
///   `(goal_id, target_type, target_id)` 复用在位行、自带幂等）。`plan_item.source_type`
///   的五值 CHECK（`manual/todo/habit/project/increment`）是冻结的，目标 ↔ 计划项
///   的关联**只能**落在 `goal_link`（`packages/core_db/lib/src/tables.dart:1142-1143`）。
///
/// 计划行不注入 `todayIso` / `nowMinute`，因此一律写 `pending`：从目标加进计划的
/// 是「还没做的安排」，不该因为格子落在过去就被判成已完成。
Future<WeekGoalAddOutcome> addWeekGoalToPlan(
  WidgetRef ref, {
  required GoalRow goal,
  required String date,
  required int startMinute,
  required int endMinute,
}) async {
  final GoalStore goalStore = ref.read(goalStoreProvider);
  final List<PlanItemData> dayItems =
      await ref.read(repositoriesProvider).planItem.listByDate(date);
  final Set<String> alivePlanItemIds = <String>{
    for (final PlanItemData item in dayItems) item.id,
  };

  final List<GoalLinkRow> links = await goalStore.listLinks(goal.id);
  for (final GoalLinkRow link in links) {
    if (link.targetType == GoalTargetType.planItem &&
        alivePlanItemIds.contains(link.targetId)) {
      return WeekGoalAddOutcome.alreadyInPlan;
    }
  }

  final TimelineStore store = TimelineStore(ref.read(repositoriesProvider));
  final String planItemId = await store.createManual(
    date: date,
    title: goal.title,
    detail: goal.note ?? '',
    startMinute: startMinute,
    endMinute: endMinute,
  );
  await goalStore.link(
    goalId: goal.id,
    targetType: GoalTargetType.planItem,
    targetId: planItemId,
  );
  return WeekGoalAddOutcome.added;
}

/// 面板里「点一下」的落位：接在当日最后一条计划之后的下一个 30 分钟整点。
///
/// 刻意不读真实时钟：同一天点两次要落到同一个位置，否则「点一次」这个动作的
/// 结果既不可断言、也会让凌晨点和下午点落到完全不同的格子。当日还没有计划时
/// 落到窗口起点（[kGridStartHour] 点）。
int suggestedGoalStartMinute(List<PlanItemData> dayItems) {
  int latest = 0;
  for (final PlanItemData item in dayItems) {
    final int? end = item.plannedEnd ?? item.plannedStart;
    if (end != null && end > latest) {
      latest = end;
    }
  }
  if (latest <= 0) {
    return kGridStartHour * 60;
  }
  final int rounded = ((latest + 29) ~/ 30) * 30;
  const int lastSlot = 24 * 60 - 30;
  return rounded > lastSlot ? lastSlot : rounded;
}

/// 今日页右轨第 5 块：未完成周目标（Task 72 / B7）。
///
/// 数据只来自 [weekOpenGoalsProvider]（W1 已建，「未完成」口径
/// `!isDone && archivedAt == null` 在 provider 侧做完），本文件不写第二套过滤、
/// 不新增仓储方法、不动 `packages/**`。
///
/// 每一条既是点击目标（点了就加进当天的计划），也是拖拽源：payload 走
/// [goalDragPayloadFor]（前缀单一来源在 `goal_upstream_panel.dart`），与日格
/// `DragTarget<String>` 的前缀分流约定一致。
class WeekGoalRailPanel extends ConsumerWidget {
  /// 创建「未完成周目标」面板。
  const WeekGoalRailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = shellLocalizationsOf(context);
    final TextStyle? hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.tokens.faint,
      height: 1.4,
    );
    final AsyncValue<List<GoalRow>> asyncGoals = ref.watch(
      weekOpenGoalsProvider,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.goalsUpstreamAddHint,
          key: const ValueKey<String>('week-goal-add-hint'),
          style: hintStyle,
        ),
        const SizedBox(height: 6),
        ...asyncGoals.when(
          // 三态必须互相可区分（范式照 `goal_upstream_panel.dart:122-135`）：
          // 把 loading / 读库失败 也画成「暂无未完成目标」，会让人误判「今天
          // 没有周目标可加」，且把数据库故障静默吞成正常空态。
          loading: () => <Widget>[
            Padding(
              key: const ValueKey<String>('week-goal-loading'),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.tokens.meta,
                  ),
                ),
              ),
            ),
          ],
          // 错误对象不丢弃：原文跟着通用「操作失败」一起露出，事后可排查。
          error: (Object error, StackTrace _) => <Widget>[
            Text(
              '${t.operationFailed}: $error',
              key: const ValueKey<String>('week-goal-error'),
              style: hintStyle,
            ),
          ],
          data: (List<GoalRow> goals) => goals.isEmpty
              ? <Widget>[
                  Text(
                    t.goalsUpstreamEmpty,
                    key: const ValueKey<String>('week-goal-empty'),
                    style: hintStyle,
                  ),
                ]
              : <Widget>[
                  for (final GoalRow goal in goals)
                    _tile(context, ref, goal, hintStyle),
                ],
        ),
      ],
    );
  }

  /// 一条周目标：可点（加进当天计划）+ 可拖（payload 见 [goalDragPayloadFor]）。
  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    GoalRow goal,
    TextStyle? hintStyle,
  ) {
    final TextStyle? itemStyle = hintStyle?.copyWith(
      color: context.tokens.ink,
    );
    return Draggable<String>(
      data: goalDragPayloadFor(goal.id),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.tokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: context.tokens.hairStrong),
          ),
          child: Text(goal.title, style: itemStyle),
        ),
      ),
      child: InkWell(
        key: ValueKey<String>('week-goal-${goal.id}'),
        onTap: () => _addOne(ref, goal),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          child: Text(
            goal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: itemStyle,
          ),
        ),
      ),
    );
  }

  /// 点击通道：按当日已排内容算落位，再走唯一写入入口。
  Future<void> _addOne(WidgetRef ref, GoalRow goal) async {
    final String date = ref.read(selectedDateProvider);
    final List<PlanItemData> dayItems =
        await ref.read(repositoriesProvider).planItem.listByDate(date);
    final int start = suggestedGoalStartMinute(dayItems);
    await addWeekGoalToPlan(
      ref,
      goal: goal,
      date: date,
      startMinute: start,
      endMinute: start + 30,
    );
  }
}

/// 「未完成周目标」勾选浮层（日格右键通道）。
///
/// 多选后一次性确认，确认结果交回调用方逐条走 [addWeekGoalToPlan]，因此与
/// 点击 / 拖拽两条通道共享同一份幂等判据。文案只用 W1 已登记的
/// `goalsUpstreamWeekTitle` / `goalsUpstreamEmpty` 与通用 `confirm` / `cancel`，
/// 不新增任何 l10n 键。
class WeekGoalPickDialog extends StatefulWidget {
  /// 创建勾选浮层。
  const WeekGoalPickDialog({super.key, required this.goals});

  /// 可勾选的未完成周目标。
  final List<GoalRow> goals;

  /// 弹出浮层并等待确认；取消返回 null。
  static Future<List<GoalRow>?> show(
    BuildContext context, {
    required List<GoalRow> goals,
  }) {
    return showDialog<List<GoalRow>>(
      context: context,
      builder: (BuildContext ctx) => WeekGoalPickDialog(goals: goals),
    );
  }

  @override
  State<WeekGoalPickDialog> createState() => _WeekGoalPickDialogState();
}

class _WeekGoalPickDialogState extends State<WeekGoalPickDialog> {
  final Set<String> _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = shellLocalizationsOf(context);
    final ThemeTokens tokens = context.tokens;
    return AlertDialog(
      backgroundColor: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      title: Text(
        t.goalsUpstreamWeekTitle,
        style: TextStyle(fontSize: 16, color: tokens.ink),
      ),
      content: SizedBox(
        width: 360,
        child: widget.goals.isEmpty
            ? Text(
                t.goalsUpstreamEmpty,
                style: TextStyle(fontSize: 13, color: tokens.faint),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final GoalRow goal in widget.goals)
                      CheckboxListTile(
                        key: ValueKey<String>('week-goal-pick-${goal.id}'),
                        value: _picked.contains(goal.id),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked ?? false) {
                              _picked.add(goal.id);
                            } else {
                              _picked.remove(goal.id);
                            }
                          });
                        },
                        title: Text(
                          goal.title,
                          style: TextStyle(fontSize: 13, color: tokens.ink),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('week-goal-pick-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('week-goal-pick-confirm'),
          onPressed: _picked.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                    widget.goals
                        .where((GoalRow g) => _picked.contains(g.id))
                        .toList(growable: false),
                  ),
          child: Text(t.confirm),
        ),
      ],
    );
  }
}