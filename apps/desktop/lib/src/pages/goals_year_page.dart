// =============================================================================
// 目标 · 年目标页（Task 66 UI 半批 B2；B17 W4 重做表一；B18 W3 去冗余）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与周/月页同口径）。
//
// B17 之后本页只剩**一块**内容（派工书 E 条：月度展开 / 年度复盘 / 80/20 三块
// UI 入口下线，数据层与 l10n getter 保留）：
//   * **表一**：本年度的年度目标。列 = 序号 | 目标内容 | 方法和措施 |
//     起止时间 | 操作。行内可编辑 / 删除 / 勾选完成。
//   * 行按**类别分区**渲染，分区小标题取 `goalCategoryTitle`（B17 F 条）；
//     分区与排序全部委托 `widgets/goals/goal_section.dart`（泛型版）
//     + `widgets/goals/goal_category.dart`（唯一真源），页面不自己分桶。
//   * 段头下有「新建目标」入口（B17 C 条）：**空态与非空态都在**，写法与
//     其它目标页一致（同一个表单、同一条落库路径）。
//
// B18 W3 去冗余（**别再改回去**）：
//   * **分类名唯一出处 = 分区小标题**（`goal-section-title-<displayKey>`）⇒
//     行内「类别」列与表头「类别」格一并删除，`goalCategoryTitle` 在本页不再
//     直接引用（该函数本身仍在 `goal_category.dart`，分区件继续用它）。
//   * **完成态唯一出处 = 行尾 `GoalRowActions` 的完成单选**
//     （`goal-row-done-<id>`）⇒ 行内「进行中 / 已完成」文本列与表头「完成」格
//     一并删除；`goalStatusActive` / `goalStatusDone` / `goalMonthColumnCategory`
//     / `goalMonthColumnDone` 这些 l10n getter **保留不删**，只是本页不渲染。
//   * 两侧各删 2 格 ⇒ 表头与数据行仍逐位对应；两行 Row 的 `crossAxisAlignment`
//     改为 `center`（列高不一致时纵向居中对齐）。
//
// 读模型仍走 `loadGoalYearView`（与蓝图页**同一个函数** ⇒ 单一真源）；
// `data\goal_store.dart` **零改动**，不新增 provider / 仓储方法。类别复用
// `Goal.domain` 一列，**没有新列、没有 DB 迁移**（B17 裁决 1）。
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
import '../widgets/goals/goal_section.dart';

/// 年目标页：本年度的年度目标表（按类别分区，可新建 / 编辑 / 删除 / 勾完成）。
class GoalsYearPage extends ConsumerStatefulWidget {
  /// 创建年目标页。
  const GoalsYearPage({this.period, super.key});

  /// 周期（测试注入用；null = 当前年）。
  final GoalPeriod? period;

  @override
  ConsumerState<GoalsYearPage> createState() => _GoalsYearPageState();
}

class _GoalsYearPageState extends ConsumerState<GoalsYearPage> {
  /// 本年度的年度目标（缓存一次，避免 FutureBuilder 重建循环）。
  Future<List<GoalRow>>? _future;

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

  Future<List<GoalRow>> _load() async {
    final GoalStore store = ref.read(goalStoreProvider);
    final GoalYearView view = await loadGoalYearView(store, _period);
    return view.yearlyGoals;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String? error = _error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (error != null) ...<Widget>[
          Text(
            error,
            key: const ValueKey<String>('goal-year-error'),
            style: _metaStyle(context),
          ),
          const SizedBox(height: 6),
        ],
        _GoalCard(
          title: t.goalYearGoalsSection,
          child: FutureBuilder<List<GoalRow>>(
            future: _future,
            builder:
                (BuildContext context, AsyncSnapshot<List<GoalRow>> snapshot) {
                  final List<GoalRow>? goals = snapshot.data;
                  if (goals == null) {
                    return Text(
                      t.operationFailed,
                      style: _metaStyle(context),
                    );
                  }
                  return _buildTableOne(goals, t);
                },
          ),
        ),
      ],
    );
  }

  /// 新建年度目标：表单 → 落库 → 重读本页（空态与非空态同一入口）。
  Future<void> _createGoal() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalFormResult? form = await showGoalFormDialog(
      context,
      t: t,
      // 起止默认落在本页周期内，保证新建的行**一定出现在本页**。
      initialPeriodStart: DateTime.fromMillisecondsSinceEpoch(
        _period.startMillis,
      ),
      initialPeriodEnd: DateTime.fromMillisecondsSinceEpoch(_period.endMillis),
    );
    if (form == null || !mounted) {
      return;
    }
    final String title = form.title.trim();
    if (title.isEmpty) {
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(goalStoreProvider).createGoal(
        kind: GoalKind.yearly,
        title: title,
        note: _emptyToNull(form.note),
        keywords: _emptyToNull(form.keywords),
        domain: _categoryOf(form),
        periodStart:
            form.periodStart?.millisecondsSinceEpoch ?? _period.startMillis,
        periodEnd: form.periodEnd?.millisecondsSinceEpoch ?? _period.endMillis,
        dueDate: form.dueDate,
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

  /// 行内「编辑」：预填既有值，保存后写库并重读本页。
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
    final String title = form.title.trim();
    if (title.isEmpty) {
      return;
    }

    final String? domain = _categoryOf(form);
    final String? note = _emptyToNull(form.note);
    final String? keywords = _emptyToNull(form.keywords);
    final int? periodStart = form.periodStart?.millisecondsSinceEpoch;
    final int? periodEnd = form.periodEnd?.millisecondsSinceEpoch;
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
        // B17 C 条：起止日期必须一起写回，否则「改了日期但列表不变」。
        periodStart: periodStart,
        periodEnd: periodEnd,
        dueDate: dueDate,
        // 表单里清空的字段必须显式进 `clear`：传 null 的语义是「不动」。
        clear: <GoalField>{
          if (domain == null) GoalField.domain,
          if (note == null) GoalField.note,
          if (keywords == null) GoalField.keywords,
          if (periodEnd == null) GoalField.periodEnd,
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

  /// 行内「删除」：先二次确认（确认框本体三页共用），确认后才软删。
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

  /// 行内「完成」单选：写 `status`（B17 C 条）；写完重读，列表立刻反映。
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
      setState(() => _future = _load());
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 表单的类别 → 落库值（**`category` 优先于 `domain`**：两者同列，只能取一个）。
  static String? _categoryOf(GoalFormResult form) =>
      _emptyToNull(form.category ?? '') ?? _emptyToNull(form.domain);

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

  /// 表一：序号 | 目标内容 | 方法和措施 | 起止时间 | 操作。
  ///
  /// 分类名由分区小标题表达、完成态由行尾完成单选表达（B18 W3：行内不再重复
  /// 渲染「类别」列与「进行中 / 已完成」文本列）。
  ///
  /// 新建入口在**空态与非空态都渲染**（B17 C 条：空态不能吞掉入口）。
  Widget _buildTableOne(List<GoalRow> goals, AppLocalizations t) {
    final Widget addButton = Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: const ValueKey<String>('goal-year-add'),
        onPressed: _createGoal,
        child: Text(t.goalBlueprintAddGoal),
      ),
    );

    if (goals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          addButton,
          Text(
            t.goalYearGoalsEmpty,
            key: const ValueKey<String>('goal-year-goals-empty'),
            style: _metaStyle(context),
          ),
        ],
      );
    }

    // 序号 = **分区内**从 1 起（B17 W7）：按 `groups` 的实际渲染顺序
    // （分区顺序 → 分区内条目顺序）编号，换分区即从 1 重新开始。计数源与
    // `GoalSectionList` 的遍历顺序逐条一致（groups → group.items），因此表里
    // 读到的是 1…n 连续序号，不再是跨分区累计的 1、3、2、7。
    // 表头文案不动（`goalMonthColumnIndex`，l10n 不在本棒写集）。
    final List<GoalSectionGroup<GoalRow>> groups =
        groupSectionsByCategory<GoalRow>(
          t,
          goals,
          domainOf: (GoalRow goal) => goal.domain,
        );
    final Map<String, int> order = <String, int>{};
    for (final GoalSectionGroup<GoalRow> group in groups) {
      for (int i = 0; i < group.items.length; i++) {
        order[group.items[i].id] = i + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        addButton,
        const SizedBox(height: 4),
        _headerRow(t),
        const SizedBox(height: 6),
        GoalSectionList<GoalRow>(
          groups: groups,
          rowBuilder: (BuildContext context, GoalRow goal) =>
              _goalRow(order[goal.id] ?? 0, goal, t),
        ),
      ],
    );
  }

  /// 表头一行（列宽必须与 [_goalRow] 逐列一致，否则列错位）。
  Widget _headerRow(AppLocalizations t) {
    final TextStyle? headStyle = _headStyle(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
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
        // 操作列表头留空：宽度必须与行尾按钮组同宽。本页每行都渲染完成单选
        // ⇒ 用 `GoalRowActions.totalWidth`（56 + 24），不能用 `width`。
        const SizedBox(
          width: GoalRowActions.width + GoalRowActions.doneWidth,
        ),
      ],
    );
  }

  /// 表一的一行。
  Widget _goalRow(int index, GoalRow goal, AppLocalizations t) {
    final TextStyle? bodyStyle = _bodyStyle(context);
    final TextStyle? metaStyle = _metaStyle(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: 28, child: Text('$index', style: metaStyle)),
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
          GoalRowActions(
            editKey: 'goal-year-row-edit-${goal.id}',
            deleteKey: 'goal-year-row-delete-${goal.id}',
            onEdit: () => _editGoal(goal),
            onDelete: () => _deleteGoal(goal),
            t: t,
            goalId: goal.id,
            isDone: goal.isDone,
            onToggleDone: () => _toggleDone(goal),
          ),
        ],
      ),
    );
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