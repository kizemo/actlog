// =============================================================================
// 目标 · 「未完成上游目标」右栏面板（Task 72 / 批次 B7）
// =============================================================================
// 月目标页与周目标页共用同一块右栏（计划 D-72-d）。面板只负责**呈现与手势**：
//   * 列出上游周期里仍然未完成的目标（过滤口径由 provider 决定，本组件不再筛）；
//   * 每条可点击（`onPick`）、可拖拽（`Draggable<String>`）；
//   * 空态 / 加载中 / 出错 三态各自有占位，不把整页拖崩。
//
// 拖拽 payload 是 W2/W3 共用约定：`'goal://' + goalId`。前缀用来和
// `widgets\timeline\day_grid.dart` 既有的裸待办 id 通道区分开 —— 本通道之外的
// payload 一律判为 `null`（调用方据此放行，不吞别人的拖拽）。
//
// 文案由调用方传入（页面侧从 `AppLocalizations` 取）：新组件自己不去 import
// `widgets\shell\key_bar.dart` 里的 `shellLocalizationsOf`（Task 72 §9 第 8 条）。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../data/goal_store.dart';
import '../theme/app_tokens.dart';

/// 目标拖拽通道的 payload 前缀（W2/W3 共用，逐字一致）。
const String goalDragPayloadPrefix = 'goal://';

/// 生成一条目标在拖拽通道里的 payload：`'goal://' + goalId`。
String goalDragPayloadFor(String goalId) => '$goalDragPayloadPrefix$goalId';

/// 从拖拽 payload 里取出目标 id。
///
/// 不是本通道的 payload（含 `null`、空串、裸待办 id）一律返回 `null`，
/// 调用方据此**原样放行**，不吞别的拖拽通道。
String? goalIdFromDragPayload(Object? payload) {
  if (payload is! String || !payload.startsWith(goalDragPayloadPrefix)) {
    return null;
  }
  final String id = payload.substring(goalDragPayloadPrefix.length);
  return id.isEmpty ? null : id;
}

/// 「未完成上游目标」右栏面板。
///
/// 只渲染传进来的 [goals]（已完成 / 已归档的过滤在 provider 侧做完），
/// 本组件不读库、不改库。
class GoalUpstreamPanel extends StatelessWidget {
  /// 创建面板。
  const GoalUpstreamPanel({
    required this.kind,
    required this.title,
    required this.hint,
    required this.emptyText,
    required this.goals,
    required this.onPick,
    this.loading = false,
    this.errorText,
    super.key,
  });

  /// 上游目标的形态（用于定位 key 与语义标注）。
  final GoalKind kind;

  /// 段头标题（如「未完成年目标」）。
  final String title;

  /// 操作提示（如「点击或拖拽添加到当前周期」）。
  final String hint;

  /// 空态文案。
  final String emptyText;

  /// 上游周期里仍然未完成的目标。
  final List<GoalRow> goals;

  /// 点某一条时的回调（派生写入由页面侧负责）。
  final ValueChanged<GoalRow> onPick;

  /// 是否仍在加载（true 时只画占位，不画列表）。
  final bool loading;

  /// 出错文案（null = 无错误）。
  final String? errorText;

  /// 面板外框的定位 key。
  static ValueKey<String> panelKey(GoalKind kind) =>
      ValueKey<String>('goal-upstream-panel-${kind.code}');

  /// 面板内某一条的定位 key。
  static ValueKey<String> itemKey(GoalKind kind, String goalId) =>
      ValueKey<String>('goal-upstream-item-${kind.code}-$goalId');

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      key: panelKey(kind),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.hairSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: tokens.ink),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: tokens.hair),
          const SizedBox(height: 8),
          Text(
            hint,
            key: ValueKey<String>('goal-upstream-hint-${kind.code}'),
            style: _metaStyle(context),
          ),
          const SizedBox(height: 8),
          if (loading)
            const _PanelLoading()
          else if (errorText != null)
            Text(
              errorText!,
              key: ValueKey<String>('goal-upstream-error-${kind.code}'),
              style: _metaStyle(context),
            )
          else if (goals.isEmpty)
            Text(
              emptyText,
              key: ValueKey<String>('goal-upstream-empty-${kind.code}'),
              style: _metaStyle(context),
            )
          else
            for (final GoalRow goal in goals) _item(context, goal),
        ],
      ),
    );
  }

  /// 一条可点击 / 可拖拽的上游目标。
  Widget _item(BuildContext context, GoalRow goal) {
    final TextStyle? bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: context.tokens.ink);
    return Draggable<String>(
      data: goalDragPayloadFor(goal.id),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragFeedback(text: goal.title, style: bodyStyle),
      child: InkWell(
        key: itemKey(kind, goal.id),
        onTap: () => onPick(goal),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(goal.title, style: bodyStyle),
        ),
      ),
    );
  }

  /// 次级文字样式。
  TextStyle? _metaStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(color: context.tokens.meta);
}

/// 加载中占位（右栏不抢页面的错误提示）。
class _PanelLoading extends StatelessWidget {
  /// 创建占位。
  const _PanelLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

/// 拖拽时跟随指针的浮层。
///
/// 用 `MaterialType.transparency` 而不是 `Colors.transparent`：本仓库禁用
/// Material 图标与裸色值，浮层底色走 token。
class _DragFeedback extends StatelessWidget {
  /// 创建浮层。
  const _DragFeedback({required this.text, required this.style});

  /// 浮层文字（目标一句话）。
  final String text;

  /// 文字样式（沿用条目样式）。
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: tokens.hair, width: 1),
        ),
        child: Text(text, style: style),
      ),
    );
  }
}