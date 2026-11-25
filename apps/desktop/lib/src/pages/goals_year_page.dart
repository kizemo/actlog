// =============================================================================
// 目标 · 年目标页（Task 66 UI 半批 B2）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与周/月页同口径）。
//
// 五块内容（计划 §5.3）：
//  1. **表一**（类别 | 序号 | 目标内容 | 方法和措施 | 起止时间 | 完成）：本年度的年度
//     目标。类别取 `domain`，方法与措施取 `keywords`，起止时间取 `period_start` /
//     `period_end`，完成取 `status`。**全部是库里的原值**，界面不写回任何一列。
//  2. **表二**（`GoalYearMatrix`）：行 = 年目标 × 列 = 1–12 月。空格 = 该月未展开，
//     **合法**（不校验、不报错、不给红字）；点开可就地输入标题，再「加入待确认草稿」。
//  3. **年度复盘**：完成 N 项 / 自评总分 / 自评均值 + 「自评＝用户自评，不是达成率」
//     的口径说明。
//  4. **80/20 视角**：沿 `serves` 链聚合 `tracks` 执行记录条数，降序**只呈现条数**，
//     **不评分、不排名、不给百分比**（区块内不出现 `%`）。
//  5. **滚动候选**：本年未完成的年目标 → 下年草稿候选（**只算不写**）；用户点
//     「确认写入草稿」才落库，落库状态恒为 `status='draft'`。
//
// 读模型在页面层派生（计划 §3.3 选方案 b）：`data\goal_store.dart` **零改动**，
// 不新增 provider、不新增仓储方法。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/goal_year_matrix.dart';
import '../widgets/goals/goal_form_dialog.dart';

/// 年目标页：年度目标表 + 月度展开矩阵 + 年度复盘 + 80/20 视角 + 滚动候选。
class GoalsYearPage extends ConsumerStatefulWidget {
  /// 创建年目标页。
  const GoalsYearPage({this.period, super.key});

  /// 周期（测试注入用；null = 当前年）。
  final GoalPeriod? period;

  @override
  ConsumerState<GoalsYearPage> createState() => _GoalsYearPageState();
}

/// 年页读模型（本页私有）。
class _YearData {
  /// 构造。
  const _YearData({required this.view, required this.tracks});

  /// 年度读模型。
  final GoalYearView view;

  /// 年目标 id → 沿 `serves` 链聚合的执行记录条数。
  final Map<String, int> tracks;
}

class _GoalsYearPageState extends ConsumerState<GoalsYearPage> {
  /// 读模型（缓存一次，避免 FutureBuilder 重建循环）。
  Future<_YearData>? _future;

  /// 待确认草稿队列（**未确认前库里 0 增量**）。
  final List<GoalDraft> _pending = <GoalDraft>[];

  /// 是否正在写草稿。
  bool _saving = false;

  /// 是否已写入成功。
  bool _saved = false;

  /// 写失败提示（null = 无错误）。
  String? _error;

  /// 本页周期。
  GoalPeriod get _period => widget.period ?? _currentYear(ref.read(todayProvider));

  /// 当前年（按本地日历日推导）。
  static GoalPeriod _currentYear(String today) {
    final DateTime local = DateTime.parse(today);
    return GoalPeriod.year(local.year);
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_YearData> _load() async {
    final GoalStore store = ref.read(goalStoreProvider);
    final GoalYearView view = await loadGoalYearView(store, _period);
    final Map<String, int> tracks = <String, int>{};
    for (final GoalRow yearly in view.yearlyGoals) {
      int total = (await store.listLinks(
        yearly.id,
        relation: GoalRelation.tracks,
      )).length;
      for (final GoalRow child in view.serves.childrenOf(yearly.id)) {
        total += (await store.listLinks(
          child.id,
          relation: GoalRelation.tracks,
        )).length;
      }
      tracks[yearly.id] = total;
    }
    return _YearData(view: view, tracks: tracks);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _block(
          t,
          t.goalYearGoalsSection,
          (_YearData data) => _buildTableOne(data, t),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalYearMonthsSection,
          (_YearData data) => GoalYearMatrix(
            view: data.view,
            t: t,
            onAddCellDraft: _addCellDraft,
          ),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalYearReviewSection,
          (_YearData data) => _buildReview(data, t),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalYear8020Section,
          (_YearData data) => _build8020(data, t),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalsDraftSection,
          (_YearData data) => _buildDrafts(data, t),
        ),
      ],
    );
  }

  /// 一个卡片区块（读模型未到就显示失败提示）。
  Widget _block(
    AppLocalizations t,
    String title,
    Widget Function(_YearData data) build,
  ) {
    return _GoalCard(
      title: title,
      child: FutureBuilder<_YearData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_YearData> snapshot) {
          if (!snapshot.hasData) {
            return Text(t.operationFailed, style: _metaStyle(context));
          }
          return build(snapshot.data!);
        },
      ),
    );
  }

  /// 年度目标行「编辑」：预填既有值，保存后写库并重读本页。
  Future<void> _editGoal(GoalRow goal) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalFormResult? form = await showGoalFormDialog(
      context,
      t: t,
      existing: goal,
    );
    if (form == null || !mounted) {
      return;
    }
    await _updateGoal(goal, form);
  }

  /// 年度目标行「删除」：先二次确认（确认框本体三页共用），确认后才软删。
  Future<void> _deleteGoal(GoalRow goal) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool confirmed = await confirmDeleteGoal(context, t);
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(goalStoreProvider).deleteGoal(goal.id);
      if (!mounted) {
        return;
      }
      setState(() => _future = _load());
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 表单结果写回库（本页不新建目标：新建入口不在本棒范围）。
  Future<void> _updateGoal(GoalRow goal, GoalFormResult form) async {
    final String title = form.title.trim();
    final String? note = _emptyToNull(form.note);
    final String? keywords = _emptyToNull(form.keywords);
    final String? domain = _emptyToNull(form.domain);
    final int? dueDate = form.dueDate;
    setState(() => _error = null);
    try {
      await ref.read(goalStoreProvider).updateGoal(
        goal.id,
        title: title,
        note: note,
        keywords: keywords,
        domain: domain,
        horizon: _keptHorizon(goal, form.horizon),
        dueDate: dueDate,
        // 表单里清空的字段必须显式进 `clear`：传 null 的语义是「不动」。
        clear: <GoalField>{
          if (domain == null) GoalField.domain,
          if (note == null) GoalField.note,
          if (keywords == null) GoalField.keywords,
          if (dueDate == null) GoalField.dueDate,
        },
      );
      if (!mounted) {
        return;
      }
      setState(() => _future = _load());
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 档位保留口径：原目标本来没有档位、用户也没动档位（表单仍是默认
  /// `ultimate`）⇒ 传 null（`updateGoal` 里 null = 不动），不给年目标隐式赋档。
  static GoalHorizon? _keptHorizon(GoalRow goal, GoalHorizon picked) {
    if (goal.horizon == null && picked == GoalHorizon.ultimate) {
      return null;
    }
    return picked;
  }

  /// 空白串 → null（表单里的「没填」等于「不设置」）。
  static String? _emptyToNull(String value) {
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

  /// 表一：类别 | 序号 | 目标内容 | 方法和措施 | 起止时间 | 完成。
  Widget _buildTableOne(_YearData data, AppLocalizations t) {
    final List<GoalRow> goals = data.view.yearlyGoals;
    if (goals.isEmpty) {
      return Text(
        t.goalYearGoalsEmpty,
        key: const ValueKey<String>('goal-year-goals-empty'),
        style: _metaStyle(context),
      );
    }
    final TextStyle? headStyle = _headStyle(context);
    final TextStyle? bodyStyle = _bodyStyle(context);
    final TextStyle? metaStyle = _metaStyle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 64,
              child: Text(t.goalMonthColumnCategory, style: headStyle),
            ),
            SizedBox(
              width: 28,
              child: Text(t.goalMonthColumnIndex, style: headStyle),
            ),
            Expanded(flex: 3, child: Text(t.goalsColumnGoal, style: headStyle)),
            Expanded(
              flex: 2,
              child: Text(t.goalMonthColumnMethods, style: headStyle),
            ),
            SizedBox(
              width: 96,
              child: Text(t.goalYearColumnPeriod, style: headStyle),
            ),
            SizedBox(
              width: 56,
              child: Text(t.goalMonthColumnDone, style: headStyle),
            ),
            // 操作列表头留空：宽度必须与行尾按钮组同宽（`GoalRowActions.width`）。
            const SizedBox(width: GoalRowActions.width),
          ],
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < goals.length; i++)
          _goalRow(i, goals[i], t, bodyStyle, metaStyle),
      ],
    );
  }

  /// 表一的一行。
  Widget _goalRow(
    int index,
    GoalRow goal,
    AppLocalizations t,
    TextStyle? bodyStyle,
    TextStyle? metaStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              t.projectDomainLabel(goal.domain ?? ''),
              style: metaStyle,
            ),
          ),
          SizedBox(width: 28, child: Text('${index + 1}', style: metaStyle)),
          Expanded(
            flex: 3,
            child: Text(
              goal.title,
              key: ValueKey<String>('goal-year-row-${goal.id}'),
              style: bodyStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(goal.keywords ?? '—', style: metaStyle),
          ),
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_dateText(goal.periodStart), style: metaStyle),
                Text(_dateText(goal.periodEnd), style: metaStyle),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              goal.isDone ? t.goalStatusDone : t.goalStatusActive,
              style: metaStyle,
            ),
          ),
          GoalRowActions(
            editKey: 'goal-year-row-edit-${goal.id}',
            deleteKey: 'goal-year-row-delete-${goal.id}',
            onEdit: () => _editGoal(goal),
            onDelete: () => _deleteGoal(goal),
            t: t,
          ),
        ],
      ),
    );
  }

  /// 年度复盘：完成 N 项 / 自评总分 / 自评均值 + 口径说明。
  Widget _buildReview(_YearData data, AppLocalizations t) {
    final List<GoalRow> goals = data.view.yearlyGoals;
    final int done = goals.where((GoalRow goal) => goal.isDone).length;
    final List<int> scores = <int>[
      for (final GoalRow goal in goals)
        if (goal.selfScore != null) goal.selfScore!,
    ];
    final int total = scores.fold(0, (int sum, int value) => sum + value);
    final String average = scores.isEmpty
        ? '—'
        : (total / scores.length).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${t.goalYearReviewDone} $done',
          key: const ValueKey<String>('goal-year-review-done'),
          style: _bodyStyle(context),
        ),
        Text(
          '${t.goalYearReviewScoreTotal} $total',
          key: const ValueKey<String>('goal-year-review-total'),
          style: _bodyStyle(context),
        ),
        Text(
          '${t.goalYearReviewScoreAverage} $average',
          key: const ValueKey<String>('goal-year-review-average'),
          style: _bodyStyle(context),
        ),
        Text(t.goalYearReviewSelfNote, style: _metaStyle(context)),
      ],
    );
  }

  /// 80/20 视角：只呈现执行记录条数（**不评分、不排名、无百分比**）。
  Widget _build8020(_YearData data, AppLocalizations t) {
    final List<GoalRow> ordered = <GoalRow>[...data.view.yearlyGoals]
      ..sort(
        (GoalRow a, GoalRow b) => (data.tracks[b.id] ?? 0).compareTo(
          data.tracks[a.id] ?? 0,
        ),
      );
    final List<GoalRow> shown = <GoalRow>[
      for (final GoalRow goal in ordered)
        if ((data.tracks[goal.id] ?? 0) > 0) goal,
    ];
    if (shown.isEmpty) {
      return Column(
        key: const ValueKey<String>('goal-year-8020-block'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.goalYear8020Empty,
            key: const ValueKey<String>('goal-year-8020-empty'),
            style: _metaStyle(context),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey<String>('goal-year-8020-block'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${goal.title} · ${data.tracks[goal.id]} ${t.goalYear8020Tracks}',
              key: ValueKey<String>('goal-year-8020-${goal.id}'),
              style: _bodyStyle(context),
            ),
          ),
      ],
    );
  }

  /// 滚动候选 + 待确认草稿区（**只算不写**）。
  Widget _buildDrafts(_YearData data, AppLocalizations t) {
    final List<GoalDraft> candidates = _candidates(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (candidates.isEmpty)
          Text(
            t.goalYearDraftEmpty,
            key: const ValueKey<String>('goal-year-draft-empty'),
            style: _metaStyle(context),
          )
        else
          for (final GoalDraft candidate in candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      candidate.title,
                      key: ValueKey<String>(
                        'goal-year-candidate-${candidate.sourceGoalId}',
                      ),
                      style: _bodyStyle(context),
                    ),
                  ),
                  TextButton(
                    key: ValueKey<String>(
                      'goal-year-candidate-add-${candidate.sourceGoalId}',
                    ),
                    onPressed: () => _addPending(candidate),
                    child: Text(t.goalYearCellAddDraft),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        Text(
          t.goalDraftPending,
          key: const ValueKey<String>('goal-year-draft-pending'),
          style: _headStyle(context),
        ),
        if (_pending.isEmpty)
          Text(
            t.goalYearDraftEmpty,
            key: const ValueKey<String>('goal-year-pending-empty'),
            style: _metaStyle(context),
          )
        else
          for (final GoalDraft draft in _pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                draft.title,
                key: ValueKey<String>('goal-year-pending-${draft.title}'),
                style: _bodyStyle(context),
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey<String>('goal-year-draft-confirm'),
            onPressed: _saving || _pending.isEmpty
                ? null
                : () => _confirmPending(),
            child: Text(t.goalsDraftConfirm),
          ),
        ),
        if (_saved)
          Text(
            t.goalsDraftSaved,
            key: const ValueKey<String>('goal-year-draft-saved'),
            style: _metaStyle(context),
          ),
        if (_error != null)
          Text(
            _error!,
            key: const ValueKey<String>('goal-year-draft-error'),
            style: _metaStyle(context),
          ),
      ],
    );
  }

  /// 滚动候选：本年未完成的年目标 → 下年草稿（**只算不写**）。
  List<GoalDraft> _candidates(_YearData data) {
    final GoalPeriod next = _period.next();
    final List<GoalDraft> drafts = <GoalDraft>[];
    for (final GoalRow goal in data.view.yearlyGoals) {
      if (goal.isDone) {
        continue;
      }
      drafts.add(
        GoalDraft(
          kind: GoalKind.yearly,
          title: goal.title,
          periodStart: next.startMillis,
          periodEnd: next.endMillis,
          domain: goal.domain,
          note: goal.improveNote ?? goal.reviewNote,
          sourceGoalId: goal.id,
          origin: GoalDraftOrigin.carryOver,
        ),
      );
    }
    return drafts;
  }

  /// 表二空格新增月目标 → 进页内待确认草稿队列（**不落库**）。
  void _addCellDraft(String yearlyId, int month, String title) {
    final GoalPeriod monthPeriod = GoalPeriod.month(_period.year, month);
    setState(() {
      _pending.add(
        GoalDraft(
          kind: GoalKind.monthly,
          title: title,
          periodStart: monthPeriod.startMillis,
          periodEnd: monthPeriod.endMillis,
          parentId: yearlyId,
          origin: GoalDraftOrigin.fromUpperLayer,
        ),
      );
    });
  }

  /// 把滚动候选加入待确认队列。
  void _addPending(GoalDraft draft) {
    setState(() => _pending.add(draft));
  }

  /// 用户确认 ⇒ 落库（`status='draft'`）。
  Future<void> _confirmPending() async {
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      await ref.read(goalStoreProvider).saveWeeklyDrafts(
        List<GoalDraft>.from(_pending),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pending.clear();
        _saved = true;
      });
      _future = _load();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// UTC 毫秒 → `yyyy-MM-dd`（null = 无固定终点 → 占位符 `—`，与同页其它缺值口径一致）。
  String _dateText(int? millis) {
    if (millis == null) {
      return '—';
    }
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(
      millis,
      isUtc: true,
    );
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }

  /// 段头样式。
  TextStyle? _headStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(color: context.tokens.faint);

  /// 正文样式。
  TextStyle? _bodyStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: context.tokens.ink);

  /// 次级文字样式。
  TextStyle? _metaStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(color: context.tokens.meta);
}

/// 目标页的卡片外壳（段头 + 内容）。
///
/// 与周/月目标页同口径：`SectionCard` 要求传 `IconData`，而本仓库**禁用 Material
/// 图标**（`Icons.`），所以这里自己搭一个视觉等价的壳。
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
