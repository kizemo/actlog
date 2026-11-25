// =============================================================================
// 目标 · 人生蓝图页（Task 66 UI 半批 B2）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与周/月/年页同口径）。
//
// 口径（Task 72 / D-72-b）：蓝图已从「目标页第 4 页签」升级为第 7 个导航项
// （id `blueprint`、`Ctrl+7`、深链 `/blueprint`）；页面自带标题，不再借目标页的。
//
// 三块内容（计划 §5.4）：
//  1. **人生蓝图矩阵**：6 行（领域）× 5 列（档位）。空格合法，不校验、不报错。
//     「近期（1 年）」列渲染的是**本年度的年度目标**（`GoalYearView.yearlyGoals`）
//     加上 `horizon='near'` 的蓝图目标 —— 与年页**同一份数据源**，不另建一份。
//     格内显示标题 + 做法条数（`tracks` 关联条数）；**未落位** = 既没有下级目标、
//     也没有任何执行实体。
//  2. **待确认待办区**：「拆成 3 条待办」先进页内队列，用户点确认才
//     `TodoRepository.create` × 3 并 `tracks` 挂回原目标（**未确认时库里 0 增量**）。
//  3. **人生平衡轮**：纯派生只读 —— 本月/上月自评均值 + 习惯打卡频次，
//     **界面上看到的数字不回写目标库**。
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
import '../widgets/goal_balance_wheel.dart';
import '../widgets/goal_blueprint_matrix.dart';
import '../widgets/goal_year_matrix.dart';

/// 人生蓝图页：蓝图矩阵 + 待确认待办 + 平衡轮。
class GoalsBlueprintPage extends ConsumerStatefulWidget {
  /// 创建人生蓝图页。
  const GoalsBlueprintPage({this.period, super.key});

  /// 周期（测试注入用；null = 当前年）。
  final GoalPeriod? period;

  @override
  ConsumerState<GoalsBlueprintPage> createState() =>
      _GoalsBlueprintPageState();
}

/// 一条待确认的「拆成 3 条待办」。
class _TodoSplit {
  /// 构造。
  const _TodoSplit({required this.goalId, required this.goalTitle});

  /// 被拆的目标 id。
  final String goalId;

  /// 被拆的目标标题。
  final String goalTitle;

  /// 三条待办的标题。
  ///
  /// 序号用 ASCII（`1/3`），这样英文界面也不会漏出中文标点。
  List<String> titles() => <String>[
    for (int i = 1; i <= 3; i++) '$goalTitle $i/3',
  ];
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

  /// 待确认的「拆成 3 条待办」队列（**未确认前库里 0 增量**）。
  final List<_TodoSplit> _pending = <_TodoSplit>[];

  /// 是否正在写待办。
  bool _saving = false;

  /// 是否已写入成功。
  bool _saved = false;

  /// 写失败提示（null = 无错误）。
  String? _error;

  /// 目标是否已保存（B8-W1：与待办那组标志**分开**，两块互不干扰）。
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
      for (final GoalHorizon horizon in GoalBlueprintMatrix.horizons) {
        final List<GoalRow> items = <GoalRow>[
          for (final GoalRow goal in blueprints)
            if (goal.domain == domainKey && goal.horizon == horizon) goal,
        ];
        if (horizon == GoalHorizon.near) {
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
    final ThemeTokens tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.shellNavBlueprint,
          key: const ValueKey<String>('blueprint-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: tokens.ink),
        ),
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
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalBlueprintMatrixSection,
          (_BlueprintData data) => _buildMatrix(data, t),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalBlueprintPendingTodos,
          (_BlueprintData data) => _buildPendingTodos(data, t),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _block(
          t,
          t.goalBlueprintBalanceSection,
          (_BlueprintData data) => GoalBalanceWheel(data: data.balance, t: t),
        ),
      ],
    );
  }

  /// 一个卡片区块（读模型未到就显示失败提示）。
  Widget _block(
    AppLocalizations t,
    String title,
    Widget Function(_BlueprintData data) build,
  ) {
    return _GoalCard(
      title: title,
      child: FutureBuilder<_BlueprintData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_BlueprintData> snapshot) {
          if (!snapshot.hasData) {
            return Text(t.operationFailed, style: _metaStyle(context));
          }
          return build(snapshot.data!);
        },
      ),
    );
  }

  /// 蓝图矩阵 + 近期列来源说明 + 整行留空口径说明。
  Widget _buildMatrix(_BlueprintData data, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(t.goalBlueprintNearSource, style: _metaStyle(context)),
        const SizedBox(height: 6),
        GoalBlueprintMatrix(
          t: t,
          rows: data.rows,
          serves: data.serves,
          tracksCount: data.tracksCount,
          onSplitTodos: _addSplit,
          onAddGoal: _openCreateGoal,
          onEditGoal: _openEditGoal,
          onDeleteGoal: _confirmDeleteGoal,
        ),
        const SizedBox(height: 6),
        Text(t.goalBlueprintBlankRowHint, style: _metaStyle(context)),
      ],
    );
  }

  /// 待确认待办区（**只算不写**）。
  Widget _buildPendingTodos(_BlueprintData data, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_pending.isEmpty)
          Text(
            t.goalBlueprintPendingTodos,
            key: const ValueKey<String>('goal-blueprint-todo-empty'),
            style: _metaStyle(context),
          )
        else
          for (final _TodoSplit split in _pending)
            for (final String title in split.titles())
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  title,
                  key: ValueKey<String>('goal-blueprint-pending-$title'),
                  style: _bodyStyle(context),
                ),
              ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey<String>('goal-blueprint-todo-confirm'),
            onPressed: _saving || _pending.isEmpty
                ? null
                : () => _confirmTodos(),
            child: Text(t.goalBlueprintConfirmTodos),
          ),
        ),
        if (_saved)
          Text(
            t.goalsDraftSaved,
            key: const ValueKey<String>('goal-blueprint-todo-saved'),
            style: _metaStyle(context),
          ),
        if (_error != null)
          Text(
            _error!,
            key: const ValueKey<String>('goal-blueprint-todo-error'),
            style: _metaStyle(context),
          ),
      ],
    );
  }

  /// 「拆成 3 条待办」进页内队列（**不落库**）。
  void _addSplit(GoalRow goal) {
    setState(() {
      _pending.add(_TodoSplit(goalId: goal.id, goalTitle: goal.title));
    });
  }

  /// 用户确认 ⇒ 建 3 条待办 + 用 `tracks` 挂回原目标。
  Future<void> _confirmTodos() async {
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      final GoalStore store = ref.read(goalStoreProvider);
      for (final _TodoSplit split in _pending) {
        for (final String title in split.titles()) {
          final String todoId = await store.repos.todo.create(title: title);
          await store.link(
            goalId: split.goalId,
            targetType: GoalTargetType.todo,
            targetId: todoId,
            relation: GoalRelation.tracks,
          );
        }
      }
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

  /// 格内「+ 新建目标」（D-8-e：领域 + 档位由所在格带入）。
  Future<void> _openCreateGoal(String domainKey, GoalHorizon horizon) async {
    // `showDialog` 的 builder 在 Navigator 的 overlay 里构建，那里**在
    // `L10nScope` 之上**（L10nScope 包的是 `home`，不是 `MaterialApp`），
    // 所以必须在页面自己的 context 上先取好 `t` 再传进去。
    final AppLocalizations t = AppLocalizations.of(context);
    final _GoalFormResult? result = await showDialog<_GoalFormResult>(
      context: context,
      builder: (BuildContext context) => _GoalFormDialog(
        t: t,
        domainKey: domainKey,
        horizon: horizon,
      ),
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
    final _GoalFormResult? result = await showDialog<_GoalFormResult>(
      context: context,
      builder: (BuildContext context) => _GoalFormDialog(
        t: t,
        domainKey: goal.domain ?? '',
        horizon: goal.horizon ?? GoalHorizon.ultimate,
        existing: goal,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    await _writeGoal(goal, result);
  }

  /// 卡片「删除」：先二次确认，确认后才软删。
  ///
  /// 确认框**刻意不回显目标标题**（英文态会漏出用户输入的中文），只放通用文案。
  Future<void> _confirmDeleteGoal(GoalRow goal) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t.goalBlueprintDeleteGoal),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('goal-blueprint-delete-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            key: const ValueKey<String>('goal-blueprint-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
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
      setState(() => _goalFailed = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 表单结果落库：`existing == null` 走新建，否则走更新。
  Future<void> _writeGoal(GoalRow? existing, _GoalFormResult form) async {
    final String title = form.title.trim();
    final String? note = _emptyToNull(form.note);
    final String? keywords = _emptyToNull(form.keywords);
    final String? domain = _emptyToNull(form.domain);
    final int? dueDate = form.dueDate;

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
      setState(() => _goalFailed = AppLocalizations.of(context).operationFailed);
    }
  }

  /// 空白串 → null（表单里的「没填」等于「不设置」）。
  static String? _emptyToNull(String value) {
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

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
/// 与周/月/年目标页同口径：`SectionCard` 要求传 `IconData`，而本仓库**禁用 Material
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

/// 蓝图表单的返回值（未做任何字符串解析：期限已经是毫秒）。
class _GoalFormResult {
  /// 构造。
  const _GoalFormResult({
    required this.title,
    required this.note,
    required this.keywords,
    required this.domain,
    required this.horizon,
    required this.dueDate,
  });

  /// 标题。
  final String title;

  /// 备注（空串 = 未设置）。
  final String note;

  /// 关键词（空串 = 未设置）。
  final String keywords;

  /// 领域 key（空串 = 未设置 ⇒ 走 `clear: {GoalField.domain}`）。
  final String domain;

  /// 档位。
  final GoalHorizon horizon;

  /// 期限毫秒（null = 未设置）。
  final int? dueDate;
}

/// 新建 / 编辑蓝图表单（**本页私有**：不额外抽 `widgets\goals\`）。
class _GoalFormDialog extends StatefulWidget {
  /// 构造。
  const _GoalFormDialog({
    required this.t,
    required this.domainKey,
    required this.horizon,
    this.existing,
  });

  /// 文案表（对话框在独立路由里，不能靠 `of(context)` 再取一次）。
  final AppLocalizations t;

  /// 新建时的领域（所在格的 domain）。
  final String domainKey;

  /// 新建时的档位（所在格的 horizon）。
  final GoalHorizon horizon;

  /// 编辑时的既有目标；null = 新建。
  final GoalRow? existing;

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _keywords;
  late final TextEditingController _due;

  /// 领域 key（空串 = 未设置）。
  late String _domain;

  /// 档位。
  late GoalHorizon _horizon;

  /// 期限格式错误提示（null = 无错）。
  String? _dueError;

  @override
  void initState() {
    super.initState();
    final GoalRow? existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _keywords = TextEditingController(text: existing?.keywords ?? '');
    _due = TextEditingController(text: _formatDay(existing?.dueDate));
    // 编辑时预填既有领域；库里存的 key 不在六 key 里（同步进来的历史值）
    // 就退回「未设置」，避免下拉框的 value 不在 items 里触发断言。
    final String? current = existing?.domain;
    if (existing == null) {
      _domain = widget.domainKey;
    } else if (current != null && projectDomainKeys.contains(current)) {
      _domain = current;
    } else {
      _domain = '';
    }
    _horizon = existing?.horizon ?? widget.horizon;
    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    _note.dispose();
    _keywords.dispose();
    _due.dispose();
    super.dispose();
  }

  /// 标题空了就把「保存」置灰（只影响按钮可用性，不写库）。
  void _onTitleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = widget.t;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? t.goalBlueprintAddGoal
            : t.goalBlueprintEditGoal,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('goal-blueprint-form-title'),
              controller: _title,
              decoration: InputDecoration(labelText: t.commonTitle),
            ),
            TextField(
              key: const ValueKey<String>('goal-blueprint-form-note'),
              controller: _note,
              decoration: InputDecoration(
                labelText: t.goalBlueprintFieldNote,
              ),
            ),
            TextField(
              key: const ValueKey<String>('goal-blueprint-form-keywords'),
              controller: _keywords,
              decoration: InputDecoration(
                labelText: t.goalBlueprintFieldKeywords,
              ),
            ),
            DropdownButtonFormField<String>(
              key: const ValueKey<String>('goal-blueprint-form-domain'),
              initialValue: _domain,
              decoration: InputDecoration(
                labelText: t.goalBlueprintFieldDomain,
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(t.goalBlueprintFieldUnset),
                ),
                for (final String key in projectDomainKeys)
                  DropdownMenuItem<String>(
                    value: key,
                    child: Text(t.projectDomainLabel(key)),
                  ),
              ],
              onChanged: (String? value) =>
                  setState(() => _domain = value ?? ''),
            ),
            DropdownButtonFormField<GoalHorizon?>(
              key: const ValueKey<String>('goal-blueprint-form-horizon'),
              initialValue: _horizon,
              decoration: InputDecoration(
                labelText: t.goalBlueprintFieldHorizon,
              ),
              items: <DropdownMenuItem<GoalHorizon?>>[
                for (final GoalHorizon horizon in GoalBlueprintMatrix.horizons)
                  DropdownMenuItem<GoalHorizon?>(
                    value: horizon,
                    child: Text(_horizonLabel(t, horizon)),
                  ),
              ],
              onChanged: (GoalHorizon? value) =>
                  setState(() => _horizon = value ?? _horizon),
            ),
            TextField(
              key: const ValueKey<String>('goal-blueprint-form-due'),
              controller: _due,
              decoration: InputDecoration(
                labelText: t.goalBlueprintFieldDue,
                hintText: 'YYYY-MM-DD',
                errorText: _dueError,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('goal-blueprint-form-cancel'),
          // 取消 = 什么都不写（裁决：编辑动作不许有隐式写入）。
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        TextButton(
          key: const ValueKey<String>('goal-blueprint-form-save'),
          onPressed: _title.text.trim().isEmpty ? null : _submit,
          child: Text(t.commonSave),
        ),
      ],
    );
  }

  /// 校验期限格式后把结果交回页面（本函数**不写库**）。
  void _submit() {
    final int? dueDate = _parseDay(_due.text);
    if (dueDate == null && _due.text.trim().isNotEmpty) {
      setState(() => _dueError = widget.t.goalBlueprintFieldDueInvalid);
      return;
    }
    Navigator.of(context).pop(
      _GoalFormResult(
        title: _title.text,
        note: _note.text,
        keywords: _keywords.text,
        domain: _domain,
        horizon: _horizon,
        dueDate: dueDate,
      ),
    );
  }

  /// `YYYY-MM-DD` → 毫秒；空串 = null；非法格式 = 由调用方判错。
  static int? _parseDay(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.millisecondsSinceEpoch;
  }

  /// 毫秒 → `YYYY-MM-DD`（本地日）；null = 空串。
  static String _formatDay(int? millis) {
    if (millis == null) {
      return '';
    }
    final DateTime d = DateTime.fromMillisecondsSinceEpoch(millis);
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// 档位显示名（与矩阵表头同一套 getter）。
  static String _horizonLabel(AppLocalizations t, GoalHorizon horizon) =>
      switch (horizon) {
        GoalHorizon.ultimate => t.goalBlueprintHorizonUltimate,
        GoalHorizon.long => t.goalBlueprintHorizonLong,
        GoalHorizon.mid => t.goalBlueprintHorizonMid,
        GoalHorizon.short => t.goalBlueprintHorizonShort,
        GoalHorizon.near => t.goalBlueprintHorizonNear,
      };
}