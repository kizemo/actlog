// =============================================================================
// 目标 · 月目标页（Task 66 UI 半批 B2）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与周目标页同口径）。
//
// 三块内容（计划 §5.2）：
//  1. **年度目标汇总条**（派生）：本月目标所 `serves` 的年目标及其子目标完成数。
//  2. **上月复盘**：逐条给出「未完成原因」（缺失只提示、不阻断）与「改进措施」
//     （页内本地编辑，不写库）。
//  3. **本月目标**：每条要么有 `serves` 上层、要么被标「临时事项」（**派生标记**，
//     不写库）。卡底部是**常驻录入行**（B16 项 7：回车或点「+」即建一条本月目标）
//     与**待确认草稿队列**（「改进措施转草稿」先进这里，点「确认写入草稿」才落库，
//     落库状态恒为 `status='draft'`）。
//
// 口径提醒：页面上不会出现「看一眼就把库改了」的情况 —— 落库要么由用户的显式
// 录入触发，要么由「确认写入草稿」触发。
//
// 「滚动候选」段已按 B16 项 5 撤掉界面入口；数据层与 l10n getter 保留，本页不再
// 渲染该段。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/goal_month_review.dart';
import '../widgets/goal_upstream_panel.dart';
import '../widgets/goals/goal_form_dialog.dart';
import '../widgets/shell/tool_rail.dart';

/// 月目标页：年度汇总 + 上月复盘 + 本月目标。
class GoalsMonthPage extends ConsumerStatefulWidget {
  /// 创建月目标页。
  const GoalsMonthPage({this.period, super.key});

  /// 周期（测试注入用；null = 当前月）。
  final GoalPeriod? period;

  @override
  ConsumerState<GoalsMonthPage> createState() => _GoalsMonthPageState();
}

/// 月页读模型（本页私有）。
class _MonthData {
  /// 构造。
  const _MonthData({required this.view, required this.servedByMonthGoal});

  /// 月视图读模型。
  final GoalMonthView view;

  /// 月目标 id → 它 `serves` 的上层目标。
  final Map<String, List<GoalRow>> servedByMonthGoal;
}

class _GoalsMonthPageState extends ConsumerState<GoalsMonthPage> {
  /// 读模型（缓存一次，避免 FutureBuilder 重建循环）。
  Future<_MonthData>? _future;

  /// 待确认草稿队列（**未确认前库里 0 增量**）。
  final List<GoalDraft> _pending = <GoalDraft>[];

  /// 是否正在写草稿。
  bool _saving = false;

  /// 是否已写入成功。
  bool _saved = false;

  /// 录入行输入控制器（常驻，提交后清空）。
  final TextEditingController _input = TextEditingController();

  /// 录入行焦点（提交后保焦点，便于连续录入）。
  final FocusNode _inputFocus = FocusNode();

  /// 是否正在建录入行目标（挡连点）。
  bool _submitting = false;

  /// 就地编辑中的目标 id（null = 无编辑）。
  String? _editingId;

  /// 就地编辑的标题控制器。
  final TextEditingController _titleEditing = TextEditingController();

  /// 就地编辑的焦点。
  final FocusNode _titleFocus = FocusNode();

  /// 写失败提示（null = 无错误）。
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _titleEditing.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// 本页周期。
  GoalPeriod get _period =>
      widget.period ?? _currentMonth(ref.read(todayProvider));

  /// 当前月（按本地日历日的中午对应的 UTC 时刻推导，与周页同口径）。
  static GoalPeriod _currentMonth(String today) {
    final DateTime local = DateTime.parse(today);
    final int millis = DateTime.utc(
      local.year,
      local.month,
      local.day,
      12,
    ).millisecondsSinceEpoch;
    return GoalPeriod.fromStartMillis(millis, GoalPeriodUnit.month);
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MonthData> _load() async {
    final GoalStore store = ref.read(goalStoreProvider);
    final GoalMonthView view = await store.monthView(_period);
    final Map<String, List<GoalRow>> served = <String, List<GoalRow>>{};
    for (final GoalRow goal in view.monthGoals) {
      served[goal.id] = await store.servedGoals(goal.id);
    }
    final _MonthData data = _MonthData(view: view, servedByMonthGoal: served);
    // 记下最近一次读到的数据：复盘区的「转为本月目标草稿」回调要靠它找上层年目标。
    _lastData = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AsyncValue<List<GoalRow>> openYearly = ref.watch(
      yearOpenGoalsProvider,
    );
    final List<GoalRow> yearlyGoals =
        openYearly.asData?.value ?? const <GoalRow>[];

    // 拖拽接收：只认 `goal://` 通道，其它 payload（如时间轴的裸待办 id）
    // 返回 false ⇒ 原样放行，不吞别人的拖拽。
    // `candidateData` 非空 = 有可接的 payload 悬停，用它在左列画出落点。
    final Widget dropArea = DragTarget<String>(
      key: const ValueKey<String>('goal-month-drop-target'),
      onWillAcceptWithDetails: (DragTargetDetails<String> details) =>
          goalIdFromDragPayload(details.data) != null,
      onAcceptWithDetails: (DragTargetDetails<String> details) {
        final String? id = goalIdFromDragPayload(details.data);
        if (id == null) {
          return;
        }
        for (final GoalRow row in yearlyGoals) {
          if (row.id == id) {
            _addFromYearly(row);
            return;
          }
        }
      },
      builder: (
        BuildContext context,
        List<String?> candidateData,
        List<dynamic> rejectedData,
      ) => _buildLeft(
        t,
        highlight: candidateData.any((String? data) => data != null),
      ),
    );

    final Widget panel = GoalUpstreamPanel(
      kind: GoalKind.yearly,
      title: t.goalsUpstreamYearTitle,
      hint: t.goalsUpstreamAddHint,
      emptyText: t.goalsUpstreamEmpty,
      goals: yearlyGoals,
      loading: openYearly.isLoading && !openYearly.hasValue,
      errorText: openYearly.hasError ? t.operationFailed : null,
      onPick: _addFromYearly,
    );

    // 宽屏并排、窄屏上下堆叠：阈值由壳层的折列常量推出（不新造断点）。
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < _sideBySideMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              dropArea,
              const SizedBox(height: AppTokens.gapCard),
              panel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: dropArea),
            const SizedBox(width: ToolRail.panelGap),
            SizedBox(width: _upstreamWidth, child: panel),
          ],
        );
      },
    );
  }

  /// 右栏宽度（沿用壳层第一栏口径 `ToolRail.railWidth`）。
  static const double _upstreamWidth = ToolRail.railWidth;

  /// 并排所需最小宽度：左栏至少一个折列宽 + 面板间距 + 右栏。
  static const double _sideBySideMinWidth =
      ToolRail.minColumnWidth + ToolRail.panelGap + _upstreamWidth;

  /// 左列：三块内容（年度汇总条 / 上月复盘 / 本月目标 + 录入行 + 待确认草稿）。
  Widget _buildLeft(AppLocalizations t, {required bool highlight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GoalCard(
          title: t.goalMonthYearBar,
          child: FutureBuilder<_MonthData>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<_MonthData> snapshot) {
              if (!snapshot.hasData) {
                return Text(t.operationFailed, style: _metaStyle(context));
              }
              final List<GoalYearSummary> summaries =
                  snapshot.data!.view.yearSummaries;
              if (summaries.isEmpty) {
                return Text(
                  t.goalYearGoalsEmpty,
                  key: const ValueKey<String>('goal-month-year-bar-empty'),
                  style: _metaStyle(context),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final GoalYearSummary summary in summaries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${summary.goal.title} · '
                        '${summary.childDone}/${summary.childTotal}',
                        key: ValueKey<String>(
                          'goal-month-year-summary-${summary.goal.id}',
                        ),
                        style: _bodyStyle(context),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _GoalCard(
          title: t.goalMonthReviewSection,
          child: FutureBuilder<_MonthData>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<_MonthData> snapshot) {
              if (!snapshot.hasData) {
                return Text(t.operationFailed, style: _metaStyle(context));
              }
              final List<GoalRow> previous =
                  snapshot.data!.view.previousMonthGoals;
              if (previous.isEmpty) {
                return Text(
                  t.goalMonthReviewEmpty,
                  key: const ValueKey<String>('goal-month-review-empty'),
                  style: _metaStyle(context),
                );
              }
              return GoalMonthReview(
                goals: previous,
                t: t,
                onConvert: _convertToDraft,
              );
            },
          ),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _GoalCard(
          title: t.goalMonthGoalsSection,
          child: FutureBuilder<_MonthData>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<_MonthData> snapshot) {
              if (!snapshot.hasData) {
                return Text(t.operationFailed, style: _metaStyle(context));
              }
              final _MonthData data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildMonthGoals(data, t),
                  _inputRow(t, highlight: highlight),
                  _buildPending(t),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppTokens.gapCard),
      ],
    );
  }

  /// 常驻录入行：输入标题 + 「+」，回车或点击即建一条本月目标。
  Widget _inputRow(AppLocalizations t, {required bool highlight}) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      key: const ValueKey<String>('goal-month-input-row'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: highlight ? tokens.inkWash : null,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: highlight ? tokens.ink : tokens.hairSoft,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('goal-month-input'),
                  controller: _input,
                  focusNode: _inputFocus,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (String value) => _submitInput(value),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey<String>('goal-month-input-add'),
                onPressed: _submitting ? null : () => _submitInput(_input.text),
                child: const Text('+'),
              ),
            ],
          ),
          if (highlight)
            Text(
              t.goalsUpstreamAddHint,
              key: const ValueKey<String>('goal-month-drop-hint'),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.ink),
            )
          else if (_error != null)
            Text(
              _error!,
              key: const ValueKey<String>('goal-month-input-error'),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.accentInk),
            ),
        ],
      ),
    );
  }

  /// 录入行提交：建一条本月目标，然后清空输入并保住焦点（便于连续录入）。
  Future<void> _submitInput(String raw) async {
    final String title = raw.trim();
    if (title.isEmpty || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final GoalPeriod period = _period;
      await ref.read(goalStoreProvider).createGoal(
        kind: GoalKind.monthly,
        title: title,
        periodStart: period.startMillis,
        periodEnd: period.endMillis,
      );
      if (!mounted) {
        return;
      }
      _input.clear();
      setState(() => _future = _load());
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _inputFocus.requestFocus();
      }
    }
  }

  /// 本页已派生过的上游目标 id（同步幂等闸门，挡住连点与回读未完成之间的窗口）。
  final Set<String> _derivedFromYearly = <String>{};

  /// 由一条年目标派生一条**本月**月目标（D-72-e：派生，不改父目标状态）。
  Future<void> _addFromYearly(GoalRow yearly) async {
    if (_derivedFromYearly.contains(yearly.id) ||
        _alreadyServedYearly(_lastData, yearly.id)) {
      return;
    }
    _derivedFromYearly.add(yearly.id);
    setState(() => _error = null);
    try {
      final GoalPeriod period = _period;
      await ref.read(goalStoreProvider).saveWeeklyDrafts(<GoalDraft>[
        GoalDraft(
          kind: GoalKind.monthly,
          title: yearly.title,
          periodStart: period.startMillis,
          periodEnd: period.endMillis,
          parentId: yearly.id,
          domain: yearly.domain,
          note: yearly.note,
          sourceGoalId: yearly.id,
          origin: GoalDraftOrigin.fromUpperLayer,
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() => _future = _load());
    } on Object {
      // 写失败 ⇒ 撤掉闸门，允许用户重试。
      _derivedFromYearly.remove(yearly.id);
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 本月是否已有月目标 `serves` 这条年目标（幂等判据：读回来的服务关系）。
  bool _alreadyServedYearly(_MonthData? data, String yearlyId) {
    if (data == null) {
      return false;
    }
    for (final List<GoalRow> parents in data.servedByMonthGoal.values) {
      for (final GoalRow parent in parents) {
        if (parent.id == yearlyId) {
          return true;
        }
      }
    }
    return false;
  }

  /// 点标题开始就地编辑（单行，光标置末）。
  void _startTitleEdit(GoalRow goal) {
    _titleEditing.text = goal.title;
    _titleEditing.selection = TextSelection.collapsed(
      offset: goal.title.length,
    );
    setState(() => _editingId = goal.id);
  }

  /// 取消就地编辑（Esc）：不改库。
  void _cancelTitleEdit() {
    if (_editingId == null) {
      return;
    }
    setState(() => _editingId = null);
  }

  /// 提交就地编辑：空标题或未改动不写库。
  Future<void> _submitTitleEdit(GoalRow goal, String raw) async {
    if (_editingId != goal.id) {
      return;
    }
    final String title = raw.trim();
    setState(() => _editingId = null);
    if (title.isEmpty || title == goal.title) {
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(goalStoreProvider).updateGoal(goal.id, title: title);
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

  /// 本月目标行「编辑」：预填既有值，保存后写库并重读本页。
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

  /// 本月目标行「删除」：先二次确认（确认框本体三页共用），确认后才软删。
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

  /// 表单结果写回库（表单式新建入口不在本页：常驻录入行承担新建）。
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
  /// `ultimate`）⇒ 传 null（`updateGoal` 里 null = 不动），不给月目标隐式赋档。
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

  /// 本月目标表：类别 | 序号 | 目标 | 方法和措施 | 完成。
  Widget _buildMonthGoals(_MonthData data, AppLocalizations t) {
    final List<GoalRow> goals = data.view.monthGoals;
    if (goals.isEmpty) {
      return Text(
        t.goalMonthGoalsEmpty,
        key: const ValueKey<String>('goal-month-goals-empty'),
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
            SizedBox(width: 72, child: Text(t.goalMonthColumnCategory, style: headStyle)),
            SizedBox(width: 32, child: Text(t.goalMonthColumnIndex, style: headStyle)),
            Expanded(flex: 3, child: Text(t.goalsColumnGoal, style: headStyle)),
            Expanded(flex: 2, child: Text(t.goalMonthColumnMethods, style: headStyle)),
            SizedBox(width: 64, child: Text(t.goalMonthColumnDone, style: headStyle)),
            // 操作列表头留空：宽度必须与行尾按钮组同宽（`GoalRowActions.width`），
            // 否则表头与行会错位。
            const SizedBox(width: GoalRowActions.width),
          ],
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < goals.length; i++)
          _monthRow(i, goals[i], data.servedByMonthGoal[goals[i].id], t, bodyStyle, metaStyle),
      ],
    );
  }

  /// 本月目标的一行。
  Widget _monthRow(
    int index,
    GoalRow goal,
    List<GoalRow>? parents,
    AppLocalizations t,
    TextStyle? bodyStyle,
    TextStyle? metaStyle,
  ) {
    final List<GoalRow> served = parents ?? const <GoalRow>[];
    bool hasYearly = false;
    for (final GoalRow parent in served) {
      if (parent.kind == GoalKind.yearly) {
        hasYearly = true;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 72,
                child: Text(t.projectDomainLabel(goal.domain ?? ''), style: metaStyle),
              ),
              SizedBox(width: 32, child: Text('${index + 1}', style: metaStyle)),
              Expanded(flex: 3, child: _titleCell(goal, bodyStyle)),
              Expanded(
                flex: 2,
                child: Text(goal.keywords ?? '—', style: metaStyle),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  goal.isDone ? t.goalStatusDone : t.goalStatusActive,
                  style: metaStyle,
                ),
              ),
              GoalRowActions(
                editKey: 'goal-month-row-edit-${goal.id}',
                deleteKey: 'goal-month-row-delete-${goal.id}',
                onEdit: () => _editGoal(goal),
                onDelete: () => _deleteGoal(goal),
                t: t,
              ),
            ],
          ),
          Text(
            hasYearly ? t.goalMonthServesYearly : t.goalMonthAdHoc,
            key: ValueKey<String>(
              hasYearly
                  ? 'goal-month-serves-yearly-${goal.id}'
                  : 'goal-month-ad-hoc-${goal.id}',
            ),
            style: metaStyle,
          ),
        ],
      ),
    );
  }

  /// 标题格：编辑中 → 单行输入框；否则 → 可点的标题文本（B16 项 7）。
  ///
  /// 用 `GestureDetector` 而不是 `InkWell`（与 `goal_blueprint_matrix.dart` 的
  /// 标题入口同口径）。内层 `goal-month-row-<id>` key 保留，既有断言不受影响。
  Widget _titleCell(GoalRow goal, TextStyle? bodyStyle) {
    if (_editingId == goal.id) {
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _cancelTitleEdit,
        },
        child: TextField(
          key: ValueKey<String>('goal-month-title-edit-${goal.id}'),
          controller: _titleEditing,
          focusNode: _titleFocus,
          autofocus: true,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          onSubmitted: (String value) => _submitTitleEdit(goal, value),
          style: bodyStyle,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            border: InputBorder.none,
          ),
        ),
      );
    }
    return GestureDetector(
      key: ValueKey<String>('goal-month-title-${goal.id}'),
      onTap: () => _startTitleEdit(goal),
      child: Text(
        goal.title,
        key: ValueKey<String>('goal-month-row-${goal.id}'),
        style: bodyStyle,
      ),
    );
  }

  /// 待确认草稿队列 + 确认入口（**只算不写**：点确认才落库）。
  Widget _buildPending(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          t.goalDraftPending,
          key: const ValueKey<String>('goal-month-draft-pending'),
          style: _headStyle(context),
        ),
        if (_pending.isEmpty)
          Text(
            t.goalMonthDraftEmpty,
            key: const ValueKey<String>('goal-month-pending-empty'),
            style: _metaStyle(context),
          )
        else
          for (final GoalDraft draft in _pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                draft.title,
                key: ValueKey<String>('goal-month-pending-${draft.title}'),
                style: _bodyStyle(context),
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey<String>('goal-month-draft-confirm'),
            onPressed: _saving || _pending.isEmpty ? null : _confirmPending,
            child: Text(t.goalsDraftConfirm),
          ),
        ),
        if (_saved)
          Text(
            t.goalsDraftSaved,
            key: const ValueKey<String>('goal-month-draft-saved'),
            style: _metaStyle(context),
          ),
      ],
    );
  }

  /// 某条月目标所服务的年目标 id（没有则 null）。
  String? _yearlyParentId(_MonthData data, GoalRow goal) {
    for (final GoalRow parent
        in data.servedByMonthGoal[goal.id] ?? const <GoalRow>[]) {
      if (parent.kind == GoalKind.yearly) {
        return parent.id;
      }
    }
    return null;
  }

  /// 「改进措施」转本月目标草稿（**页内队列**，不落库）。
  void _convertToDraft(GoalRow goal, String improveNote) {
    final _MonthData? data = _lastData;
    final GoalPeriod period = _period;
    setState(() {
      _pending.add(
        GoalDraft(
          kind: GoalKind.monthly,
          title: goal.title,
          periodStart: period.startMillis,
          periodEnd: period.endMillis,
          parentId: data == null ? null : _yearlyParentId(data, goal),
          domain: goal.domain,
          note: improveNote.isEmpty ? goal.improveNote : improveNote,
          sourceGoalId: goal.id,
          origin: GoalDraftOrigin.fromUpperLayer,
        ),
      );
    });
  }

  /// 上一次读到的数据（供回调取「服务关系」用）。
  _MonthData? _lastData;

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
/// 与周目标页同口径：`SectionCard` 要求传 `IconData`，而本仓库**禁用 Material
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