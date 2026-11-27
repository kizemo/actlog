// =============================================================================
// 目标 · 周目标页（Task 65 UI 半批 B1）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担。
//
// 数据来源只有一个：`GoalStore.weekView(period)`（读模型）—— 完成度、关联
// 计划项数、「服务于」全部是**派生量**，界面上不写回任何一列。
//
// 本页只有两条写入口（B16 项 7）：
//   ① 「本周目标」卡底部的常驻录入行：回车或点「+」即建一条本周目标；
//   ② 右栏月目标拖进左列：落点高亮后松手即派生一条本周目标（挂 `serves`）。
// 两条都由用户的显式动作触发 —— 界面上永远不会「看一眼就把库改了」。
//
// 「滚动候选」段（原计划 §6.4）已按 B16 项 5 撤掉界面入口；`rollWeeklyDrafts`
// 数据层与 l10n getter 保留，本页不再渲染。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/goal_upstream_panel.dart';
import '../widgets/goal_week_table.dart';
import '../widgets/goals/goal_form_dialog.dart';
import '../widgets/shell/tool_rail.dart';

/// 周目标页：本周目标表 + 上游月目标面板。
class GoalsWeekPage extends ConsumerStatefulWidget {
  /// 创建周目标页。
  const GoalsWeekPage({super.key});

  @override
  ConsumerState<GoalsWeekPage> createState() => _GoalsWeekPageState();
}

class _GoalsWeekPageState extends ConsumerState<GoalsWeekPage> {
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AsyncValue<GoalWeekView> view = ref.watch(goalWeekViewProvider);
    final AsyncValue<List<GoalRow>> openMonthly = ref.watch(
      monthOpenGoalsProvider,
    );
    final List<GoalRow> monthlyGoals =
        openMonthly.asData?.value ?? const <GoalRow>[];

    // 拖拽接收：只认 `goal://` 通道，其它 payload 原样放行（不吞时间轴的裸待办 id）。
    // `candidateData` 非空 = 有可接的 payload 悬停，用它在左列画出落点。
    final Widget dropArea = DragTarget<String>(
      key: const ValueKey<String>('goal-week-drop-target'),
      onWillAcceptWithDetails: (DragTargetDetails<String> details) =>
          goalIdFromDragPayload(details.data) != null,
      onAcceptWithDetails: (DragTargetDetails<String> details) {
        final String? id = goalIdFromDragPayload(details.data);
        if (id == null) {
          return;
        }
        for (final GoalRow row in monthlyGoals) {
          if (row.id == id) {
            _addFromMonthly(row);
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
        view,
        highlight: candidateData.any((String? data) => data != null),
      ),
    );

    final Widget panel = GoalUpstreamPanel(
      kind: GoalKind.monthly,
      title: t.goalsUpstreamMonthTitle,
      hint: t.goalsUpstreamAddHint,
      emptyText: t.goalsUpstreamEmpty,
      goals: monthlyGoals,
      loading: openMonthly.isLoading && !openMonthly.hasValue,
      errorText: openMonthly.hasError ? t.operationFailed : null,
      onPick: _addFromMonthly,
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

  /// 左列：本周目标卡（表格 + 常驻录入行）。
  Widget _buildLeft(
    AppLocalizations t,
    AsyncValue<GoalWeekView> view, {
    required bool highlight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GoalCard(
          title: t.goalsWeekSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              view.when(
                loading: () => const _LoadingBlock(),
                error: (Object error, StackTrace stack) => _ErrorBlock(
                  text: t.operationFailed,
                ),
                data: (GoalWeekView data) => data.items.isEmpty
                    ? _EmptyBlock(
                        key: const ValueKey<String>('goals-week-empty'),
                        text: t.goalsWeekEmpty,
                      )
                    : GoalWeekTable(
                        view: data,
                        t: t,
                        onEdit: _editGoal,
                        onDelete: _deleteGoal,
                        onToggleDone: _toggleDone,
                        editingId: _editingId,
                        titleController: _titleEditing,
                        titleFocus: _titleFocus,
                        onTitleTap: _startTitleEdit,
                        onTitleSubmit: _submitTitleEdit,
                        onTitleCancel: _cancelTitleEdit,
                      ),
              ),
              _inputRow(t, highlight: highlight),
            ],
          ),
        ),
      ],
    );
  }

  /// 常驻录入行：输入标题 + 「+」，回车或点击即落库。
  Widget _inputRow(AppLocalizations t, {required bool highlight}) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      key: const ValueKey<String>('goal-week-input-row'),
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
                  key: const ValueKey<String>('goal-week-input'),
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
                key: const ValueKey<String>('goal-week-input-add'),
                onPressed: _submitting
                    ? null
                    : () => _submitInput(_input.text),
                child: const Text('+'),
              ),
            ],
          ),
          if (highlight)
            Text(
              t.goalsUpstreamAddHint,
              key: const ValueKey<String>('goal-week-drop-hint'),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.ink),
            )
          else if (_error != null)
            Text(
              _error!,
              key: const ValueKey<String>('goal-week-input-error'),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.accentInk),
            ),
        ],
      ),
    );
  }

  /// 录入行提交：建一条本周目标，然后清空输入并保住焦点（便于连续录入）。
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
      final GoalPeriod period = ref.read(goalCurrentWeekProvider);
      await ref.read(goalStoreProvider).createGoal(
        kind: GoalKind.weekly,
        title: title,
        periodStart: period.startMillis,
        periodEnd: period.endMillis,
      );
      if (!mounted) {
        return;
      }
      _input.clear();
      ref.invalidate(goalWeekViewProvider);
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

  /// 本周已派生过的上游目标 id（同步幂等闸门，挡住连点）。
  final Set<String> _derivedFromMonthly = <String>{};

  /// 由一条月目标派生一条**本周**周目标（D-72-e：派生，不改父目标状态）。
  Future<void> _addFromMonthly(GoalRow monthly) async {
    if (_derivedFromMonthly.contains(monthly.id) ||
        _alreadyServedMonthly(monthly.id)) {
      return;
    }
    _derivedFromMonthly.add(monthly.id);
    setState(() => _error = null);
    try {
      final GoalPeriod period = ref.read(goalCurrentWeekProvider);
      await ref.read(goalDraftSaverProvider)(<GoalDraft>[
        GoalDraft(
          kind: GoalKind.weekly,
          title: monthly.title,
          periodStart: period.startMillis,
          periodEnd: period.endMillis,
          parentId: monthly.id,
          domain: monthly.domain,
          note: monthly.note,
          sourceGoalId: monthly.id,
          origin: GoalDraftOrigin.fromUpperLayer,
        ),
      ]);
      // 表里要多出这条派生行。
      ref.invalidate(goalWeekViewProvider);
    } on Object {
      // 写失败 ⇒ 撤掉闸门，允许用户重试。
      _derivedFromMonthly.remove(monthly.id);
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
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
      ref.invalidate(goalWeekViewProvider);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 周目标行「编辑」：预填既有值，保存后写库并重取本周视图。
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

  /// 周目标行「删除」：先二次确认（确认框本体三页共用），确认后才软删。
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
      ref.invalidate(goalWeekViewProvider);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 行尾完成单选：切换 `status` 并重取本周视图。
  ///
  /// 只传 `status`：归档时刻由数据层按状态派生（`updateGoal` 既有语义），页面
  /// 不写任何其它列；`isDone` 为真再点即回到进行中。
  Future<void> _toggleDone(GoalRow goal) async {
    setState(() => _error = null);
    try {
      await ref.read(goalStoreProvider).updateGoal(
        goal.id,
        status: goal.isDone ? GoalStatus.active : GoalStatus.done,
      );
      if (!mounted) {
        return;
      }
      ref.invalidate(goalWeekViewProvider);
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
    // B17 裁决：`category` 与 `domain` 落**同一列**（`Goal.domain`），二者都
    // 非空时只能取一个 ⇒ **category 优先**（类别是面向用户的唯一入口，领域
    // 下拉是旧口径的遗留字段）。
    final String? category = _emptyToNull(form.category ?? '');
    final String? domain = category ?? _emptyToNull(form.domain);
    final int? dueDate = form.dueDate;
    // 起止日期：表单回 `DateTime`，库里是毫秒（周目标本来就带本周周期）。
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
      ref.invalidate(goalWeekViewProvider);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 档位保留口径：原目标本来没有档位、用户也没动档位（表单仍是默认
  /// `ultimate`）⇒ 传 null（`updateGoal` 里 null = 不动），不给周目标隐式赋档。
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

  /// 本周是否已有周目标 `serves` 这条月目标（幂等判据：读回来的服务关系）。
  bool _alreadyServedMonthly(String monthlyId) {
    final GoalWeekView? view = ref.read(goalWeekViewProvider).asData?.value;
    if (view == null) {
      return false;
    }
    for (final GoalWeekItem item in view.items) {
      if (item.servedGoal?.id == monthlyId) {
        return true;
      }
    }
    return false;
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