// =============================================================================
// 目标 · 人生蓝图页（Task 66 UI 半批 B2）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与周/月/年页同口径）。
//
// 口径（Task 72 / D-72-b）：蓝图已从「目标页第 4 页签」升级为第 7 个导航项
// （id `blueprint`、`Ctrl+7`、深链 `/blueprint`）；页面自带标题，不再借目标页的。
//
// 两块内容（计划 §5.4；B10-D1 已下线「人生平衡轮」块，组件文件保留不动）：
//  1. **人生蓝图矩阵**：6 行（领域）× 5 列（档位）。空格合法，不校验、不报错。
//     「近期（1 年）」列渲染的是**本年度的年度目标**（`GoalYearView.yearlyGoals`）
//     加上 `horizon='near'` 的蓝图目标 —— 与年页**同一份数据源**，不另建一份。
//     格内显示标题 + 做法条数（`tracks` 关联条数）；**未落位** = 既没有下级目标、
//     也没有任何执行实体。
//  2. **拆分层级（B9-W3，裁决 D-9-e）**：卡片右侧的拆分入口打开对话框，
//     层内选好子目标后**点确认就落库** —— 没有「待确认待办」中间态。
//     终极 → 远期 → 中期 → 短期是蓝图目标（`parent_id` + `serves` 双写）；
//     短期 / 近期则二选一：年度目标（`period_start` = 本年起点 + `serves`）
//     或待办任务（`TodoRepository.create` + 父目标 `tracks`）。
//
// 目标编辑（B8-W1，裁决 D-8-e）：
//  * 格内「+ 新建目标」：表单的 `domain` + `horizon` **预填所在格子** ⇒ 只填标题
//    也落在那一格（不是未分类 / 终极档）。
//  * 卡片「编辑」：预填既有值；领域选「未设置」走 `clear: {GoalField.domain}`
//    —— `updateGoal(domain: null)` 的语义是「不动」，只有 clear 才置空。
//  * 卡片「删除」：**先二次确认**再软删（`deleteGoal` 写 `deleted_at` 墓碑）。
//  * 表单/确认框全部走 `t.` getter，英文态不残留中文。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart';
import '../data/project_domain_catalog.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
// `GoalBalanceData` / `loadGoalBalanceData` 仍被 `_BlueprintData` 引用（B10-D1
// 只下线渲染块，数据字段按派工书 §3.4 保留），所以这个 import 不能摘。
import '../widgets/goal_balance_wheel.dart';
import '../widgets/goal_blueprint_matrix.dart';
import '../widgets/goal_brand_panel.dart';
import '../widgets/goal_year_matrix.dart';
import '../widgets/goals/goal_blueprint_band.dart';
import '../widgets/goals/goal_form_dialog.dart';
import '../widgets/goals/goal_period_dialog.dart';
import '../widgets/goals/goal_split_dialog.dart';

/// 人生蓝图页：个人定位 + 蓝图矩阵 + 待确认待办。
class GoalsBlueprintPage extends ConsumerStatefulWidget {
  /// 创建人生蓝图页。
  const GoalsBlueprintPage({this.period, super.key});

  /// 周期（测试注入用；null = 当前年）。
  final GoalPeriod? period;

  @override
  ConsumerState<GoalsBlueprintPage> createState() => _GoalsBlueprintPageState();
}

/// 蓝图页读模型（本页私有）。
class _BlueprintData {
  /// 构造。
  const _BlueprintData({
    required this.view,
    required this.rows,
    required this.serves,
    required this.tracksCount,
    required this.balance,
  });

  /// 年度读模型（近期列的数据源）。
  final GoalYearView view;

  /// 矩阵行（每个领域一行）。
  final List<GoalBlueprintRow> rows;

  /// `serves` 双向索引（覆盖全量目标）。
  final GoalServesIndex serves;

  /// 目标 id → `tracks` 执行实体条数。
  final Map<String, int> tracksCount;

  /// 平衡轮读模型。
  final GoalBalanceData balance;
}

class _GoalsBlueprintPageState extends ConsumerState<GoalsBlueprintPage> {
  /// 读模型（缓存一次，避免 FutureBuilder 重建循环）。
  Future<_BlueprintData>? _future;

  /// 今天（`yyyy-MM-dd`，片头带元信息用）。
  ///
  /// `initState` 取一次：不在 `build` 里 `ref.read`，也不 watch
  /// （today 变化时页面本来就靠上层重建，不必在这里再挂一条依赖）。
  late String _todayText;

  /// rail 出现的最小宽度：窄于此只渲染内容列（rail 是导航示意，缺了不影响操作，
  /// 但绝不能因为塞 rail 让窄窗口溢出）。
  static const double _railBreakpoint = 980;

  /// rail 宽度（对应 A 稿 `.page` 的 `220px 1fr`）。
  static const double _railWidth = 220;

  /// 拆分是否已写入（B9-W3：确认即落库，没有中间队列）。
  bool _splitSaved = false;

  /// 拆分写失败提示（null = 无错误）。
  String? _splitFailed;

  /// 目标是否已保存（B8-W1：与拆分那组标志**分开**，两块互不干扰）。
  bool _goalSaved = false;

  /// 目标是否已删除。
  bool _goalDeleted = false;

  /// 目标写失败提示（null = 无错误）。
  String? _goalFailed;

  /// 本页周期（近期列的年度口径）。
  GoalPeriod get _period =>
      widget.period ?? GoalPeriod.year(_todayYear(ref.read(todayProvider)));

  /// 今天所在的年份。
  static int _todayYear(String today) => DateTime.parse(today).year;

  /// 当前月（平衡轮的「本月」口径）。
  GoalPeriod get _currentMonth {
    final DateTime local = DateTime.parse(ref.read(todayProvider));
    return GoalPeriod.month(local.year, local.month);
  }

  @override
  void initState() {
    super.initState();
    _todayText = ref.read(todayProvider);
    _future = _load();
  }

  Future<_BlueprintData> _load() async {
    final GoalStore store = ref.read(goalStoreProvider);
    // 近期列的数据源与年页**同一个函数**（`loadGoalYearView`）⇒ 单一真源。
    final GoalYearView view = await loadGoalYearView(store, _period);
    final List<GoalRow> all = await store.listGoals();
    // 蓝图页要问「谁服务我」（反向），所以索引覆盖**全量**目标，不只月/周。
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    final List<GoalRow> blueprints = <GoalRow>[
      for (final GoalRow goal in all)
        if (goal.kind == GoalKind.blueprint) goal,
    ];

    final Map<String, int> tracksCount = <String, int>{};
    for (final GoalRow goal in <GoalRow>[...blueprints, ...view.yearlyGoals]) {
      tracksCount[goal.id] = (await store.listLinks(
        goal.id,
        relation: GoalRelation.tracks,
      )).length;
    }

    final List<GoalBlueprintRow> rows = <GoalBlueprintRow>[];
    for (final String domainKey in projectDomainKeys) {
      final Map<GoalHorizon, List<GoalRow>> cells =
          <GoalHorizon, List<GoalRow>>{};
      // B9-W2：矩阵只有 4 个标签页，近期（1 年）并入短期页 ⇒ near 蓝图与
      // 本年度年目标都落进 `GoalHorizon.short` 那一格（D-9-b）。
      for (final GoalHorizon horizon in GoalBlueprintMatrix.tabs) {
        final List<GoalRow> items = <GoalRow>[
          for (final GoalRow goal in blueprints)
            if (goal.domain == domainKey &&
                (goal.horizon == horizon ||
                    (horizon == GoalHorizon.short &&
                        goal.horizon == GoalHorizon.near)))
              goal,
        ];
        if (horizon == GoalHorizon.short) {
          items.addAll(<GoalRow>[
            for (final GoalRow goal in view.yearlyGoals)
              if (goal.domain == domainKey) goal,
          ]);
        }
        cells[horizon] = items;
      }
      rows.add(GoalBlueprintRow(domainKey: domainKey, cells: cells));
    }

    final GoalBalanceData balance = await loadGoalBalanceData(
      store,
      month: _currentMonth,
    );
    return _BlueprintData(
      view: view,
      rows: rows,
      serves: serves,
      tracksCount: tracksCount,
      balance: balance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // B11 方向 A「秒数轮盘」：片头带（kicker + 巨标题 + 副标 + mono 元信息
        // + 静态折线波形）。大标题 key 仍是 `blueprint-title`，文案仍是
        // `t.shellNavBlueprint`（既有契约，见 `blueprint_page_test.dart`）。
        GoalBlueprintBand(t: t, today: _todayText),
        if (_goalSaved)
          Text(
            t.goalBlueprintGoalSaved,
            key: const ValueKey<String>('goal-blueprint-goal-saved'),
            style: _metaStyle(context),
          ),
        if (_goalDeleted)
          Text(
            t.goalBlueprintGoalDeleted,
            key: const ValueKey<String>('goal-blueprint-goal-deleted'),
            style: _metaStyle(context),
          ),
        if (_goalFailed != null)
          Text(
            _goalFailed!,
            key: const ValueKey<String>('goal-blueprint-goal-error'),
            style: _metaStyle(context),
          ),
        if (_splitSaved)
          Text(
            t.goalSplitDialogSaved,
            key: const ValueKey<String>('goal-split-saved'),
            style: _metaStyle(context),
          ),
        if (_splitFailed != null)
          Text(
            _splitFailed!,
            key: const ValueKey<String>('goal-split-failed'),
            style: _metaStyle(context),
          ),
        const SizedBox(height: AppTokens.gapCard),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const GoalPositionPanel(),
                const SizedBox(height: AppTokens.gapCard),
                // B9-W2：矩阵不再有段头（标签页本身已经是分档入口）。
                _block(t, null, (_BlueprintData data) => _buildMatrix(data, t)),
              ],
            );
            if (constraints.maxWidth < _railBreakpoint) {
              return content;
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: _railWidth,
                  child: GoalBlueprintFacetRail(t: t),
                ),
                const SizedBox(width: 30),
                Expanded(child: content),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 一个卡片区块（读模型未到就显示失败提示）。
  ///
  /// [title] 为 null ⇒ 不渲染段头与分隔线（B9-W2 的矩阵块就是这种）。
  Widget _block(
    AppLocalizations t,
    String? title,
    Widget Function(_BlueprintData data) build,
  ) {
    return _GoalCard(
      title: title,
      child: FutureBuilder<_BlueprintData>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<_BlueprintData> snapshot) {
              if (!snapshot.hasData) {
                return Text(t.operationFailed, style: _metaStyle(context));
              }
              return build(snapshot.data!);
            },
      ),
    );
  }

  /// 蓝图矩阵（档位由矩阵自带的标签页切换）。
  Widget _buildMatrix(_BlueprintData data, AppLocalizations t) {
    return GoalBlueprintMatrix(
      t: t,
      rows: data.rows,
      serves: data.serves,
      tracksCount: data.tracksCount,
      onSplitTodos: _openSplit,
      onAddGoal: _openCreateGoal,
      onEditGoal: _openEditGoal,
      onDeleteGoal: _confirmDeleteGoal,
      onToggleGoalDone: _toggleGoalDone,
      onEditGoalPeriod: _editGoalPeriod,
    );
  }

  /// 拆分入口：打开对话框，确认后**直接落库**（D-9-e，没有中间队列）。
  Future<void> _openSplit(GoalRow goal) async {
    // `t` 必须在页面自己的 context 上取：overlay 在 `L10nScope` 之上。
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalSplitResult? result = await showGoalSplitDialog(
      context,
      t: t,
      parentTitle: goal.title,
      parentHorizon: goal.horizon ?? GoalHorizon.ultimate,
    );
    if (result == null || !mounted) {
      return;
    }
    await _writeSplit(goal, result);
  }

  /// 拆分结果落库（派工书 §3.1 映射）。
  ///
  /// * 终极 → 远期 / 远期 → 中期 / 中期 → 短期：蓝图子目标 + `serves` 链接；
  /// * 短期 / 近期 → 年目标：`period_start` 取本年周期 + `serves` 链接；
  /// * 短期 / 近期 → 待办：`TodoRepository.create` + 父目标 `tracks` 链接。
  ///
  /// 全程**不改父目标的 `status`**：派生只增行，状态只由目标自身编辑改。
  Future<void> _writeSplit(GoalRow parent, GoalSplitResult result) async {
    setState(() {
      _splitSaved = false;
      _splitFailed = null;
    });
    try {
      final GoalStore store = ref.read(goalStoreProvider);
      final GoalHorizon parentHorizon =
          parent.horizon ?? GoalHorizon.ultimate;
      final GoalHorizon? childHorizon = goalSplitChildHorizon(parentHorizon);
      final GoalPeriod year = GoalPeriod.year(_period.year);
      for (final String title in result.titles) {
        if (result.target == GoalSplitTarget.todo) {
          final String todoId = await store.repos.todo.create(title: title);
          await store.link(
            goalId: parent.id,
            targetType: GoalTargetType.todo,
            targetId: todoId,
            relation: GoalRelation.tracks,
          );
          continue;
        }
        final bool yearly = result.target == GoalSplitTarget.yearly;
        final String childId = await store.createGoal(
          kind: yearly ? GoalKind.yearly : GoalKind.blueprint,
          title: title,
          parentId: parent.id,
          domain: parent.domain,
          horizon: yearly ? null : childHorizon,
          periodStart: yearly ? year.startMillis : 0,
          periodEnd: yearly ? year.endMillis : null,
        );
        await store.link(
          goalId: childId,
          targetType: GoalTargetType.goal,
          targetId: parent.id,
          relation: GoalRelation.serves,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() => _splitSaved = true);
      _future = _load();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(
        () => _splitFailed =
            AppLocalizations.of(context).goalSplitDialogFailed,
      );
    }
  }

  /// 格内「+ 新建目标」（D-8-e：领域 + 档位由所在格带入）。
  Future<void> _openCreateGoal(String domainKey, GoalHorizon horizon) async {
    // `showDialog` 的 builder 在 Navigator 的 overlay 里构建，那里**在
    // `L10nScope` 之上**（L10nScope 包的是 `home`，不是 `MaterialApp`），
    // 所以必须在页面自己的 context 上先取好 `t` 再传进去。
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalFormResult? result = await showGoalFormDialog(
      context,
      t: t,
      domainKey: domainKey,
      horizon: horizon,
      // 蓝图页的填写框整体要紧凑（目标月 / 周 / 年页保持原样）。
      compact: true,
    );
    if (result == null || !mounted) {
      return;
    }
    await _writeGoal(null, result);
  }

  /// 卡片「编辑」：预填既有值（`existing` 非空 ⇒ 走 `updateGoal`）。
  Future<void> _openEditGoal(GoalRow goal) async {
    // 同上：`t` 必须在页面 context 上取，overlay 里没有 `L10nScope`。
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalFormResult? result = await showGoalFormDialog(
      context,
      t: t,
      domainKey: goal.domain ?? '',
      horizon: goal.horizon ?? GoalHorizon.ultimate,
      existing: goal,
      // 蓝图页的填写框整体要紧凑（目标月 / 周 / 年页保持原样）。
      compact: true,
    );
    if (result == null || !mounted) {
      return;
    }
    await _writeGoal(goal, result);
  }

  /// 卡片「删除」：先二次确认，确认后才软删。
  ///
  /// 确认框本体在 `widgets\goals\goal_form_dialog.dart`（三页共用）。
  Future<void> _confirmDeleteGoal(GoalRow goal) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool confirmed = await confirmDeleteGoal(context, t);
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _goalSaved = false;
      _goalDeleted = false;
      _goalFailed = null;
    });
    try {
      await ref.read(goalStoreProvider).deleteGoal(goal.id);
      if (!mounted) {
        return;
      }
      setState(() => _goalDeleted = true);
      _future = _load();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(
        () => _goalFailed = AppLocalizations.of(context).operationFailed,
      );
    }
  }

  /// 表单结果落库：`existing == null` 走新建，否则走更新。
  Future<void> _writeGoal(GoalRow? existing, GoalFormResult form) async {
    final String title = form.title.trim();
    final String? note = _emptyToNull(form.note);
    final String? keywords = _emptyToNull(form.keywords);
    final String? domain = _emptyToNull(form.domain);
    final int? dueDate = form.dueDate;
    // B12 第 3 条：第三列读的是**起止**（`period_start` / `period_end`），
    // 而表单写的是**期限**（`due_date`）—— 写入与读取来源不一致，就是
    // 「填了日期第三列不显示」的根因。这里把期限**同步**写成 `period_end`
    // （起止缺省时）；矩阵侧另有「只有期限就回退显示期限」的兜底。
    final int? periodEnd = _periodEndFor(dueDate, existing?.periodStart ?? 0);

    setState(() {
      _goalSaved = false;
      _goalDeleted = false;
      _goalFailed = null;
    });
    try {
      final GoalStore store = ref.read(goalStoreProvider);
      if (existing == null) {
        await store.createGoal(
          kind: GoalKind.blueprint,
          title: title,
          note: note,
          keywords: keywords,
          domain: domain,
          horizon: form.horizon,
          dueDate: dueDate,
          periodEnd: periodEnd,
        );
      } else {
        await store.updateGoal(
          existing.id,
          title: title,
          note: note,
          keywords: keywords,
          domain: domain,
          horizon: form.horizon,
          dueDate: dueDate,
          // null = 「不动」⇒ 既有周期不会被表单清掉。
          periodEnd: periodEnd,
          // 表单里清空的字段必须显式进 `clear`：传 null 的语义是「不动」。
          clear: <GoalField>{
            if (domain == null) GoalField.domain,
            if (note == null) GoalField.note,
            if (keywords == null) GoalField.keywords,
            if (dueDate == null) GoalField.dueDate,
          },
        );
      }
      if (!mounted) {
        return;
      }
      setState(() => _goalSaved = true);
      _future = _load();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(
        () => _goalFailed = AppLocalizations.of(context).operationFailed,
      );
    }
  }

  /// 勾选 / 取消「已完成」（B10-B3）。
  ///
  /// 只传 `status`：归档时刻由 `GoalStore.updateGoal` 按 status 派生
  /// （done ⇒ 首次完成时刻，非 done ⇒ null），页面不直接碰 `archivedAt`
  /// —— 领域校验要求二者一致，分两次写必撞。
  Future<void> _toggleGoalDone(GoalRow goal, bool done) async {
    setState(() {
      _goalSaved = false;
      _goalDeleted = false;
      _goalFailed = null;
    });
    try {
      await ref
          .read(goalStoreProvider)
          .updateGoal(
            goal.id,
            status: done ? GoalStatus.done : GoalStatus.active,
          );
      if (!mounted) {
        return;
      }
      setState(() => _goalSaved = true);
      _future = _load();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(
        () => _goalFailed = AppLocalizations.of(context).operationFailed,
      );
    }
  }

  /// 改目标起止日期（B10-B4）。
  ///
  /// 入参就是矩阵日期列带出的这一行既有值（`startMs == 0` = 未设置）。
  /// 结束日清空必须显式进 `clear`（传 null 的语义是「不动」）；起始日清空走
  /// `periodStart: 0`（`GoalField` 没有 periodStart，0 即领域里的「未设置」）。
  Future<void> _editGoalPeriod(GoalRow goal, int startMs, int? endMs) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalPeriodResult? result = await showGoalPeriodDialog(
      context,
      t: t,
      startMs: startMs,
      endMs: endMs,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _goalSaved = false;
      _goalDeleted = false;
      _goalFailed = null;
    });
    try {
      await ref
          .read(goalStoreProvider)
          .updateGoal(
            goal.id,
            periodStart: result.startMs,
            periodEnd: result.endMs,
            clear: result.endMs == null
                ? const <GoalField>{GoalField.periodEnd}
                : const <GoalField>{},
          );
      if (!mounted) {
        return;
      }
      setState(() => _goalSaved = true);
      _future = _load();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(
        () => _goalFailed = AppLocalizations.of(context).operationFailed,
      );
    }
  }

  /// 空白串 → null（表单里的「没填」等于「不设置」）。
  static String? _emptyToNull(String value) {
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

  /// 期限 ⇒ 周期终点（本地午夜毫秒）。
  ///
  /// 返回 null = **不动** `period_end`（`updateGoal` 里 null 的语义是「不动」）：
  ///  * 期限为空 ⇒ 没有可同步的终点；
  ///  * 既有起始日比期限更晚 ⇒ 不能写成更早的终点（领域层会判
  ///    「`period_end` 不能早于 `period_start`」而拒绝写入）⇒ 保持原值。
  static int? _periodEndFor(int? dueDate, int periodStart) {
    if (dueDate == null) {
      return null;
    }
    if (periodStart > 0 && dueDate < periodStart) {
      return null;
    }
    return dueDate;
  }

  /// 次级文字样式。
  TextStyle? _metaStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: context.tokens.meta);
}

/// 目标页的卡片外壳（可选段头 + 内容）。
///
/// 与周/月/年目标页同口径：`SectionCard` 要求传 `IconData`，而本仓库**禁用 Material
/// 图标**（`Icons.`），所以这里自己搭一个视觉等价的壳。
class _GoalCard extends StatelessWidget {
  /// 创建卡片。
  const _GoalCard({required this.title, required this.child});

  /// 段头标题；null = 不渲染段头（B9-W2 的矩阵块）。
  final String? title;

  /// 卡片内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final String? head = title;
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
          if (head != null && head.isNotEmpty) ...<Widget>[
            Text(
              head,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: tokens.ink),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: tokens.hair),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}
