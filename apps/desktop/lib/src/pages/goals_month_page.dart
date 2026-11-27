// =============================================================================
// 目标 · 月目标页（Task 66 UI 半批 B2）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与周目标页同口径）。
//
// 内容（B17 任务 D 之后只剩一块）：
//  1. **本月目标**：行按**类别分区**渲染（B17 任务 F：分区件与小标题委托
//     `widgets/goals/goal_section.dart`），行尾带**完成单选**（写库走
//     `updateGoal(status: ...)`）。卡底部是**常驻录入行**（B16 项 7：回车或点「+」
//     即建一条本月目标）与**待确认草稿队列**（点「确认写入草稿」才落库，落库状态
//     恒为 `status='draft'`）。
//
// 行内冗余三处已在 B18 下线（展示口径收紧，数据层与 l10n getter 全部保留）：
//  - 行内**类别列**：分类名唯一出处改为分区小标题
//    `goal-section-title-<displayKey>`；
//  - 行内**「进行中 / 已完成」状态列**：完成状态只由行尾完成单选
//    （`goal-row-done-<id>`）表达；
//  - 行下**派生标记行**（「服务于年目标」/「临时事项」）：两个 ValueKey
//    `goal-month-serves-yearly-<id>` / `goal-month-ad-hoc-<id>` 一并下线。
//
// 已下线的 UI 入口（B17 任务 D：**只撤界面，数据层与 l10n getter 全部保留**）：
//  - 「年度目标汇总条」（派生读模型 `GoalMonthView.yearSummaries` 仍在）；
//  - 「上月复盘」卡（`GoalMonthReview` 与 `GoalMonthView.previousMonthGoals` 仍在）。
//  副作用：本页已没有任何路径能往待确认队列里塞草稿 ⇒ 队列恒为空、确认按钮恒禁用；
//  队列本体与 `_confirmPending` 照旧保留（数据层契约不变，后续波次可能再接入口）。
//
// 口径提醒：页面上不会出现「看一眼就把库改了」的情况 —— 落库要么由用户的显式
// 录入触发，要么由「确认写入草稿」或「完成单选」触发。
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
import '../widgets/goal_upstream_panel.dart';
import '../widgets/goals/goal_form_dialog.dart';
import '../widgets/goals/goal_section.dart';
import '../widgets/shell/tool_rail.dart';

/// 月目标页：本月目标（按类别分区 + 行尾完成单选）。
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
    // 记下最近一次读到的数据：派生年目标时的幂等判据 `_alreadyServedYearly` 要用。
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

  /// 左列：只有「本月目标」一块（年度汇总条与上月复盘卡的 UI 入口已下线）。
  Widget _buildLeft(AppLocalizations t, {required bool highlight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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

  /// 点完成单选：已完成 → 回到进行中，否则标记完成（写库后重读本页）。
  ///
  /// 复用既有状态机（`GoalStatus.active` / `GoalStatus.done`），不新增字段、
  /// 不动 `GoalRow.isDone` 的派生口径。
  Future<void> _toggleDone(GoalRow goal) async {
    final GoalStatus next = goal.isDone ? GoalStatus.active : GoalStatus.done;
    setState(() => _error = null);
    try {
      await ref.read(goalStoreProvider).updateGoal(goal.id, status: next);
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
    // 类别与 `domain` **同列**（B17 裁决：复用 `Goal.domain`，不新增数据库列）。
    // 表单同时回 `domain` 与 `category`，写库只能取 `category`，否则类别永远
    // 写不进去（旧 `domain` 会把新选的类别盖掉）。
    final String? category = _emptyToNull(form.category ?? '');
    final String? domain = category ?? _emptyToNull(form.domain);
    final int? dueDate = form.dueDate;
    // 起止日期同样透传：表单里「清空」= null ⇒ 走 `clear`。
    final int? periodStart = form.periodStart?.millisecondsSinceEpoch;
    final int? periodEnd = form.periodEnd?.millisecondsSinceEpoch;
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
        periodStart: periodStart,
        periodEnd: periodEnd,
        // 表单里清空的字段必须显式进 `clear`：传 null 的语义是「不动」。
        // `periodStart` 没有对应的 `GoalField`（领域模型只定义了 `periodEnd`），
        // 而且它定义月份归属 ⇒ 本页不清它。
        clear: <GoalField>{
          if (domain == null) GoalField.domain,
          if (note == null) GoalField.note,
          if (keywords == null) GoalField.keywords,
          if (dueDate == null) GoalField.dueDate,
          if (periodEnd == null) GoalField.periodEnd,
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

  /// 本月目标表：序号 | 目标 | 方法和措施 | 操作区（B18：行内无类别列与状态列）。
  ///
  /// 行按**类别分区**渲染（B17 任务 F）：分桶与排序全部委托
  /// `groupSectionsByCategory`（唯一真源在 `goal_category.dart`），本页只提供
  /// `domainOf` 与行内容；空态仍由本页的 `goal-month-goals-empty` 承担。
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
    final List<GoalSectionGroup<GoalRow>> groups =
        groupSectionsByCategory<GoalRow>(
          t,
          goals,
          domainOf: (GoalRow goal) => goal.domain,
        );
    // 序号 = **分区内**从 1 起（B17 W7）：按 `groups` 的实际渲染顺序
    // （分区顺序 → 分区内条目顺序）编 0 基序号，显示处 `+ 1`；换分区即从 1
    // 重新开始，因此不会出现 1、3、2、7 这类跨分区乱序。计数源与
    // `GoalSectionList` 的遍历顺序逐条一致（groups → group.items）。
    final Map<String, int> indexById = <String, int>{};
    for (final GoalSectionGroup<GoalRow> group in groups) {
      for (int i = 0; i < group.items.length; i++) {
        indexById[group.items[i].id] = i;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: 32, child: Text(t.goalMonthColumnIndex, style: headStyle)),
            Expanded(flex: 3, child: Text(t.goalsColumnGoal, style: headStyle)),
            Expanded(flex: 2, child: Text(t.goalMonthColumnMethods, style: headStyle)),
            // 操作列表头留空：宽度必须与行尾按钮组同宽。本页行带了完成单选 ⇒
            // 行尾实际宽度是 `GoalRowActions.totalWidth` = `width + doneWidth`
            // （两个常量都是 static const，这里直接加和，避免实例化只为取宽）。
            const SizedBox(
              width: GoalRowActions.width + GoalRowActions.doneWidth,
            ),
          ],
        ),
        const SizedBox(height: 6),
        GoalSectionList<GoalRow>(
          groups: groups,
          rowBuilder: (BuildContext context, GoalRow goal) => _monthRow(
            indexById[goal.id] ?? 0,
            goal,
            t,
            bodyStyle,
            metaStyle,
          ),
        ),
      ],
    );
  }

  /// 本月目标的一行。
  ///
  /// 单元格与表头**逐位对应**：序号 | 目标 | 方法和措施 | 操作区
  /// （完成单选 + 编辑 + 删除）。B18 起行内**没有**类别列与状态列 ——
  /// 分类名只在分区小标题出现，完成状态只由行尾单选表达；行下也不再挂
  /// 「服务于年目标」/「临时事项」的派生标记行。
  Widget _monthRow(
    int index,
    GoalRow goal,
    AppLocalizations t,
    TextStyle? bodyStyle,
    TextStyle? metaStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: 32, child: Text('${index + 1}', style: metaStyle)),
          Expanded(flex: 3, child: _titleCell(goal, bodyStyle)),
          Expanded(
            flex: 2,
            child: Text(goal.keywords ?? '—', style: metaStyle),
          ),
          GoalRowActions(
            editKey: 'goal-month-row-edit-${goal.id}',
            deleteKey: 'goal-month-row-delete-${goal.id}',
            onEdit: () => _editGoal(goal),
            onDelete: () => _deleteGoal(goal),
            t: t,
            // B17 任务 F：行尾完成单选。`goalId` 只用来拼
            // `goal-row-done-<id>` 这个 ValueKey；宽度由 `totalWidth` 决定。
            goalId: goal.id,
            isDone: goal.isDone,
            onToggleDone: () => _toggleDone(goal),
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