// =============================================================================
// 目标 · 上月复盘块（Task 66 UI 半批 B2）
// =============================================================================
// 口径（计划 §5.2 的复盘条 + §11 的 PDCA 行）：
//  1. 上月每条目标要么 `done`，要么在「未完成原因」留痕；**原因缺失只给提示、
//     不阻断**（不弹窗、不拦提交、不改库）。
//  2. 「改进措施」是**页内本地编辑**：改动先留在本页输入框里，**不写库**；点
//     「转为本月目标草稿」才进本页的待确认草稿队列，再由用户统一确认落库。
//     全程「只算不写」—— 库里不会出现未经确认的行。
//  3. 文案全走 l10n（`parts\goals.dart` 的月页段），英文态零中文。
// =============================================================================

import 'package:flutter/material.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_tokens.dart';

/// 上月复盘块：逐条列出上月目标的「未完成原因」与「改进措施」。
class GoalMonthReview extends StatefulWidget {
  /// 创建复盘块。
  const GoalMonthReview({
    required this.goals,
    required this.t,
    required this.onConvert,
    super.key,
  });

  /// 上月目标（调用方排好序）。
  final List<GoalRow> goals;

  /// 文案表。
  final AppLocalizations t;

  /// 「转为本月目标草稿」回调（改进措施与目标本体一起交出去）。
  final void Function(GoalRow goal, String improveNote) onConvert;

  @override
  State<GoalMonthReview> createState() => _GoalMonthReviewState();
}

class _GoalMonthReviewState extends State<GoalMonthReview> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(GoalRow goal) =>
      _controllers.putIfAbsent(goal.id, TextEditingController.new);

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? titleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.meta);
    final TextStyle? warnStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.accentInk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in widget.goals) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  goal.title,
                  key: ValueKey<String>('goal-review-title-${goal.id}'),
                  style: titleStyle,
                ),
                const SizedBox(height: 2),
                Text(widget.t.goalMonthReviewReason, style: metaStyle),
                Text(
                  goal.reviewNote ?? widget.t.goalMonthReviewReasonMissing,
                  key: ValueKey<String>('goal-review-reason-${goal.id}'),
                  style: goal.reviewNote == null ? warnStyle : metaStyle,
                ),
                const SizedBox(height: 4),
                Text(widget.t.goalMonthImprove, style: metaStyle),
                TextField(
                  key: ValueKey<String>('goal-review-improve-${goal.id}'),
                  controller: _controllerFor(goal),
                  style: titleStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.t.goalMonthImproveEmpty,
                    border: const OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: ValueKey<String>('goal-review-convert-${goal.id}'),
                    onPressed: () => widget.onConvert(
                      goal,
                      _controllerFor(goal).text.trim(),
                    ),
                    child: Text(widget.t.goalMonthConvertDraft),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: tokens.hair),
        ],
      ],
    );
  }
}
