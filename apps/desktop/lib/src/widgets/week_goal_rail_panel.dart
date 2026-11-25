import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart' show GoalRow;
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import 'shell/key_bar.dart';

/// 今日页右轨第 5 块：未完成周目标（**只读展示**，B8-W3）。
///
/// 本面板曾经承担三条写入通道（点击加进当天计划、拖进日格、日格右键勾选）。
/// 用户裁决「保留只读展示」之后三条入口全部撤掉（见
/// `docs/b8-scope-decision.md` U1）：面板只留下三态（加载 / 读库失败 / 空态）
/// 与未完成周目标列表，用来「对照今天该顾哪些周目标」。
///
/// 写入入口撤走后这里不再有 `Draggable`、`InkWell`、`onTap`，也没有任何
/// `plan_item` / `goal_link` 写入路径；要恢复写入必须先改裁决文档，不要在
/// 本文件里私自加回手势。
///
/// 数据只来自 [weekOpenGoalsProvider]（「未完成」口径 `!isDone && archivedAt == null`
/// 在 provider 侧做完），本文件不写第二套过滤、不新增仓储方法、不动 `packages/**`。
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
      children: asyncGoals.when(
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
                for (final GoalRow goal in goals) _tile(context, goal, hintStyle),
              ],
      ),
    );
  }

  /// 一条周目标：只读展示，最多两行，超出省略。
  ///
  /// 键名 `week-goal-<goalId>` 是既有契约（三态测试与本面板的定位都靠它），
  /// 从可点条目迁到只读容器上时保持不变。
  Widget _tile(BuildContext context, GoalRow goal, TextStyle? hintStyle) {
    final TextStyle? itemStyle = hintStyle?.copyWith(
      color: context.tokens.ink,
    );
    return Container(
      key: ValueKey<String>('week-goal-${goal.id}'),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Text(
        goal.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: itemStyle,
      ),
    );
  }
}