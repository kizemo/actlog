// =============================================================================
// 目标 · 周目标页（Task 65 UI 半批 B1）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担。
//
// 数据来源只有一个：`GoalStore.weekView(period)`（读模型）—— 完成度、关联
// 计划项数、「服务于」全部是**派生量**，界面上不写回任何一列。
//
// 草稿滚动区（计划 §6.4）的次序是硬约束：
//   ① `rollWeeklyDrafts` **只算不写**（库里 0 增量）；
//   ② 用户点「确认写入草稿」；
//   ③ 才调 `saveWeeklyDrafts` 落库，落库状态是 `status='draft'`（激活由用户
//      后续决定）。
// 也就是说：界面上永远不会「看一眼就把库改了」。
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/goal_week_table.dart';

/// 周目标页：本周目标表 + 滚动候选区。
class GoalsWeekPage extends ConsumerStatefulWidget {
  /// 创建周目标页。
  const GoalsWeekPage({super.key});

  @override
  ConsumerState<GoalsWeekPage> createState() => _GoalsWeekPageState();
}

class _GoalsWeekPageState extends ConsumerState<GoalsWeekPage> {
  /// 是否正在写草稿。
  bool _saving = false;

  /// 是否已写入成功（写入后按钮停用，避免同批候选被写两遍）。
  bool _saved = false;

  /// 写失败提示（null = 无错误）。
  String? _error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AsyncValue<GoalWeekView> view = ref.watch(goalWeekViewProvider);
    final AsyncValue<List<GoalDraft>> drafts = ref.watch(goalWeeklyDraftsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GoalCard(
          title: t.goalsWeekSection,
          child: view.when(
            loading: () => const _LoadingBlock(),
            error: (Object error, StackTrace stack) => _ErrorBlock(
              text: t.operationFailed,
            ),
            data: (GoalWeekView data) => data.items.isEmpty
                ? _EmptyBlock(
                    key: const ValueKey<String>('goals-week-empty'),
                    text: t.goalsWeekEmpty,
                  )
                : GoalWeekTable(view: data, t: t),
          ),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _GoalCard(
          title: t.goalsDraftSection,
          child: drafts.when(
            loading: () => const _LoadingBlock(),
            error: (Object error, StackTrace stack) => _ErrorBlock(
              text: t.operationFailed,
            ),
            data: (List<GoalDraft> data) => _buildDrafts(data, t),
          ),
        ),
      ],
    );
  }

  /// 滚动候选区：候选清单 + 确认按钮。
  Widget _buildDrafts(List<GoalDraft> drafts, AppLocalizations t) {
    if (drafts.isEmpty) {
      return _EmptyBlock(
        key: const ValueKey<String>('goals-draft-empty'),
        text: t.goalsDraftEmpty,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalDraft draft in drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${draft.title} · ${_originLabel(draft, t)}',
              key: ValueKey<String>('goals-draft-${draft.title}'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.tokens.ink),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey<String>('goals-draft-confirm'),
            onPressed: _saving || _saved ? null : () => _confirm(drafts, t),
            child: Text(t.goalsDraftConfirm),
          ),
        ),
        if (_saved)
          Text(
            t.goalsDraftSaved,
            key: const ValueKey<String>('goals-draft-saved'),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.tokens.meta),
          ),
        if (_error != null)
          Text(
            _error!,
            key: const ValueKey<String>('goals-draft-error'),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.tokens.accentInk),
          ),
      ],
    );
  }

  /// 候选来源标签。
  String _originLabel(GoalDraft draft, AppLocalizations t) =>
      switch (draft.origin) {
        GoalDraftOrigin.carryOver => t.goalsDraftCarryOver,
        GoalDraftOrigin.fromUpperLayer => t.goalsDraftFromMonthly,
      };

  /// 用户确认 ⇒ 落库（`status='draft'`）。
  Future<void> _confirm(List<GoalDraft> drafts, AppLocalizations t) async {
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      await ref.read(goalDraftSaverProvider)(drafts);
      // 落库后周视图要重取（表里多出这批草稿行）；候选列表**不**重取 ——
      // 重取会把这批候选原样再算一遍，用户可能误以为还能再写一遍。
      ref.invalidate(goalWeekViewProvider);
      if (!mounted) {
        return;
      }
      setState(() => _saved = true);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = t.operationFailed);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

/// 目标页的卡片外壳（段头 + 内容）。
///
/// 为什么不用 `SectionCard`：那个组件要求传 `IconData`，而本仓库**禁用
/// Material 图标**（`Icons.` 全仓零命中），齿轮与表头一律自绘。这里照它的
/// 视觉口径（4px 圆角 + 1px 弱边 + 段头下沿一条分隔线）自己搭一个。
class _GoalCard extends StatelessWidget {
  /// 创建卡片。
  const _GoalCard({required this.title, required this.child});

  /// 段头标题。
  final String title;

  /// 卡片内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Container(
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
          child,
        ],
      ),
    );
  }
}

/// 加载中占位。
class _LoadingBlock extends StatelessWidget {
  /// 创建占位。
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.tokens.meta,
          ),
        ),
      ),
    );
  }
}

/// 空态占位。
class _EmptyBlock extends StatelessWidget {
  /// 创建空态。
  const _EmptyBlock({required this.text, super.key});

  /// 空态文案。
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.tokens.faint),
      ),
    );
  }
}

/// 出错占位。
class _ErrorBlock extends StatelessWidget {
  /// 创建出错占位。
  const _ErrorBlock({required this.text});

  /// 提示文案。
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.tokens.accentInk),
      ),
    );
  }
}
