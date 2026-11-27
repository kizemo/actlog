// =============================================================================
// 目标 · 新建 / 编辑表单 + 删除二次确认（Task 74 / B8-W2 共享组件）
// =============================================================================
// 来历：本文件是 B8-W1 写在蓝图页里的私有表单（原 `_GoalFormResult` /
// `_GoalFormDialog` / `_GoalFormDialogState`）的**逐字搬迁**，仅供蓝图页与
// 目标三页（月 / 周 / 年）复用。抽出来的动因：三页也要「编辑」「删除」，
// 复制第二份表单会出现两套文案与两套校验。
//
// 三条口径保持不变：
//  1. **只产结果，不写库**：`showGoalFormDialog` 返回 `GoalFormResult?`
//     （null = 用户取消 ⇒ 调用方不写任何东西）；`confirmDeleteGoal` 返回
//     `bool`。落库由各页自己调 store。
//  2. **文案全走 `t.` getter**：对话框在 Navigator 的 overlay 里构建，那里
//     **在 `L10nScope` 之上**（L10nScope 包的是 `home`，不是 `MaterialApp`），
//     所以 `t` 必须由调用方在页面 context 上先取好再传进来，本文件不
//     `AppLocalizations.of(context)`。
//  3. **ValueKey 契约不动**：`goal-blueprint-form-*` 与
//     `goal-blueprint-delete-*` 是 W1 已落地的测试契约，名字带 `blueprint`
//     但已由三页共用，**不改名**（改名会撕毁既有用例）。
//
// B12 第 3 条（用户反馈「结束日期点击请弹出日期选择框」）：
//  * 期限字段（`goal-blueprint-form-due`）**改只读**，显示 `YYYY-MM-DD`；
//    点它弹 `showDatePicker`（与 `goal_period_dialog.dart` 同一用法），
//    选中后写入**本地午夜毫秒**（B11 裁决：蓝图目标的期限 = 本地午夜毫秒）。
//  * 字段不再手打 ⇒ 不再需要「格式非法」提示与手打解析。
//  * 保留一个「清除」入口（复用 `t.commonClear`，无新 l10n 键）⇒ 不丢原来
//    「把期限清空」的能力。
//
// ---------------------------------------------------------------------------
// B17-W2（F 条）新增，**全部向后兼容**（新字段 / 新参数一律可选）：
//  1. 「目标类别」一行（`goal-form-category-field`）：五个预设类别 + 自定义
//     类别 + 不设类别。存储口径复用 `Goal.domain` 列（B17 裁决 1/2）：
//     预设 key 原样、自定义写 `custom:<trim 文本>`、不设 / 空自定义 ⇒ null。
//     * 选「自定义类别」时出现输入框（`goal-form-category-custom-input`），
//       文案 hint 用 `t.goalFormCustomCategoryHint`（B17-W0 已落盘）。
//     * 选项本身用 `PopupMenuButton` 而不是 `DropdownButtonFormField`：
//       下拉的选中项会在按钮与菜单里各渲染一份，同 ValueKey 会命中两个
//       widget，波 C 的 `tap(find.byKey(...))` 会直接失败。
//  2. 「起止日期」一行（`goal-form-date-range`）：**点整行**就调
//     `showGoalPeriodDialog`（B10-B4 的共享弹窗），回填后显示
//     `YYYY-MM-DD → YYYY-MM-DD`，两端都没设时显示 `t.goalPeriodUnset`。
//     不要求用户先点小图标 —— 图标只是装饰。
//  3. `showCategory` / `showPeriod` 可关：页面只想保留旧字段时传 false，
//     两行不渲染，其余行为不变（既有 4 个调用点一行不改也编译）。
//
// 注意（写给波 C）：类别与「领域」复用**同一列** `Goal.domain`（B17 裁决 1），
// 而 `projectDomainKeys` 里恰好也有 wealth/family/learning/social/health 五个
// key。表单因此**不替调用方做取舍**：`GoalFormResult` 同时回传 `domain` 与
// `category`，写库时由页面决定写哪一个（建议 category 优先，且两者不要互相
// 覆盖成不同值，否则同一列会被后写的那次覆盖）。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/goal_store.dart';
import '../../data/project_domain_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../goal_blueprint_matrix.dart';
import 'goal_category.dart';
import 'goal_period_dialog.dart';

/// 目标表单的返回值（未做任何字符串解析：期限已经是毫秒）。
class GoalFormResult {
  /// 构造。
  const GoalFormResult({
    required this.title,
    required this.note,
    required this.keywords,
    required this.domain,
    required this.horizon,
    required this.dueDate,
    this.category,
    this.periodStart,
    this.periodEnd,
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

  /// 类别（`Goal.domain` 口径：五个预设 key / `custom:<文本>` / null = 未设置）。
  ///
  /// 可选：B17 之前构造本结果的调用方（含测试）不用改。
  final String? category;

  /// 起止日期的起始（本地午夜那一刻的 `DateTime`；null = 未设置）。
  ///
  /// 与 [periodEnd] 一起对应 `Goal.periodStart` / `Goal.periodEnd` 的毫秒口径；
  /// 这里回传 `DateTime` 只是为了让调用方不必自己 `fromMillisecondsSinceEpoch`。
  final DateTime? periodStart;

  /// 起止日期的结束（本地午夜那一刻的 `DateTime`；null = 无固定终点）。
  final DateTime? periodEnd;
}

/// 打开「新建 / 编辑目标」表单。
///
/// [existing] 为 null ⇒ 新建（[domainKey] / [horizon] 作为预填值，通常来自
/// 所在格子或当前页语义）；非 null ⇒ 编辑，全部字段按库里既有值预填。
///
/// 返回 null 表示用户取消 —— 调用方**不得**因此写库。
Future<GoalFormResult?> showGoalFormDialog(
  BuildContext context, {
  required AppLocalizations t,
  String domainKey = '',
  GoalHorizon horizon = GoalHorizon.ultimate,
  GoalRow? existing,
  bool compact = false,
  String? initialCategory,
  DateTime? initialPeriodStart,
  DateTime? initialPeriodEnd,
  bool showCategory = true,
  bool showPeriod = true,
}) => showDialog<GoalFormResult>(
  context: context,
  builder: (BuildContext context) => GoalFormDialog(
    t: t,
    domainKey: domainKey,
    horizon: horizon,
    existing: existing,
    compact: compact,
    initialCategory: initialCategory,
    initialPeriodStart: initialPeriodStart,
    initialPeriodEnd: initialPeriodEnd,
    showCategory: showCategory,
    showPeriod: showPeriod,
  ),
);

/// 删除目标的二次确认；返回 true = 用户确认删除。
///
/// 确认框**刻意不回显目标标题**（英文态会漏出用户输入的中文），只放通用文案。
Future<bool> confirmDeleteGoal(BuildContext context, AppLocalizations t) async {
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
  return confirmed == true;
}

/// 新建 / 编辑目标表单（共享：蓝图页与目标月 / 周 / 年页）。
class GoalFormDialog extends StatefulWidget {
  /// 构造。
  const GoalFormDialog({
    required this.t,
    required this.domainKey,
    required this.horizon,
    this.existing,
    this.compact = false,
    this.initialCategory,
    this.initialPeriodStart,
    this.initialPeriodEnd,
    this.showCategory = true,
    this.showPeriod = true,
    super.key,
  });

  /// 文案表（对话框在独立路由里，不能靠 `of(context)` 再取一次）。
  final AppLocalizations t;

  /// 新建时的领域（所在格的 domain）。
  final String domainKey;

  /// 新建时的档位（所在格的 horizon）；编辑时仅在既有 `horizon` 为 null 时兜底。
  final GoalHorizon horizon;

  /// 编辑时的既有目标；null = 新建。
  final GoalRow? existing;

  /// 是否用紧凑版式（蓝图页要更紧凑；目标月 / 周 / 年页默认保持原版式）。
  final bool compact;

  /// 新建时的类别预填（`Goal.domain` 口径；null = 未设置）。
  ///
  /// 编辑态以 [existing] 的 `domain` 为准，本值被忽略。
  final String? initialCategory;

  /// 新建时的起始预填；编辑态以 [existing] 的 `periodStart` 为准。
  final DateTime? initialPeriodStart;

  /// 新建时的结束预填；编辑态以 [existing] 的 `periodEnd` 为准。
  final DateTime? initialPeriodEnd;

  /// 是否渲染「目标类别」一行（默认渲染；B17 之前的行为等价于 false）。
  final bool showCategory;

  /// 是否渲染「起止日期」一行（默认渲染；B17 之前的行为等价于 false）。
  final bool showPeriod;

  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _keywords;
  late final TextEditingController _due;

  /// 自定义类别文本（仅 `_categoryChoice == goalCategoryCustomKey` 时可见）。
  late final TextEditingController _customCategory;

  /// 领域 key（空串 = 未设置）。
  late String _domain;

  /// 档位。
  late GoalHorizon _horizon;

  /// 类别选择：空串 = 不设类别；预设 key；或 [goalCategoryCustomKey]（自定义）。
  late String _categoryChoice;

  /// 起始（**本地午夜毫秒**；`0` = 未设置）。
  late int _periodStartMs;

  /// 结束（**本地午夜毫秒**；null = 无固定终点）。
  int? _periodEndMs;

  /// 期限（**本地午夜毫秒**；null = 未设置）。
  ///
  /// 唯一真源；`_due` 控制器只是它的显示镜像（`YYYY-MM-DD`）。
  int? _dueMs;

  /// 日期选择器的可选区间（与改期对话框 `goal_period_dialog.dart` 同口径）。
  static final DateTime _pickerFirst = DateTime(2000);
  static final DateTime _pickerLast = DateTime(2100);

  @override
  void initState() {
    super.initState();
    final GoalRow? existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _keywords = TextEditingController(text: existing?.keywords ?? '');
    _dueMs = existing?.dueDate;
    _due = TextEditingController(text: _formatDay(_dueMs));
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

    // 类别预填：编辑态看 `existing.domain`；新建态看 `initialCategory`。
    final String? rawCategory = existing != null
        ? existing.domain
        : widget.initialCategory;
    final String? categoryKey = goalCategoryKey(rawCategory);
    if (categoryKey != null &&
        categoryKey.startsWith(goalCategoryCustomPrefix)) {
      _categoryChoice = goalCategoryCustomKey;
      _customCategory = TextEditingController(
        text: categoryKey.substring(goalCategoryCustomPrefix.length),
      );
    } else {
      _categoryChoice = categoryKey ?? '';
      _customCategory = TextEditingController();
    }

    // 起止预填：编辑态看库里的毫秒；新建态看 initialPeriodStart/End。
    if (existing != null) {
      _periodStartMs = existing.periodStart;
      _periodEndMs = existing.periodEnd;
    } else {
      _periodStartMs = widget.initialPeriodStart?.millisecondsSinceEpoch ?? 0;
      _periodEndMs = widget.initialPeriodEnd?.millisecondsSinceEpoch;
    }

    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    _note.dispose();
    _keywords.dispose();
    _customCategory.dispose();
    _due.dispose();
    super.dispose();
  }

  /// 标题空了就把「保存」置灰（只影响按钮可用性，不写库）。
  void _onTitleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = widget.t;
    // 紧凑版：收紧行高（长文本照常换行，不裁切）。
    final TextStyle? fieldStyle = widget.compact
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)
        : null;
    // B14 补做 D3：备注 / 关键词只在**紧凑版**（蓝图页）折进「更多」里，
    // 字段本身不删；周 / 月 / 年页（`compact == false`）仍原样平铺。
    final List<Widget> noteAndKeywords = <Widget>[
      TextField(
        key: const ValueKey<String>('goal-blueprint-form-note'),
        controller: _note,
        style: fieldStyle,
        decoration: _decoration(t.goalBlueprintFieldNote),
      ),
      TextField(
        key: const ValueKey<String>('goal-blueprint-form-keywords'),
        controller: _keywords,
        style: fieldStyle,
        decoration: _decoration(t.goalBlueprintFieldKeywords),
      ),
    ];
    return AlertDialog(
      title: Text(
        widget.existing == null ? t.goalBlueprintAddGoal : t.goalBlueprintEditGoal,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('goal-blueprint-form-title'),
              controller: _title,
              style: fieldStyle,
              // 新建只写标题即可（B14 补做 D2 的快速通道）：打开表单即聚焦。
              autofocus: widget.compact && widget.existing == null,
              decoration: _decoration(t.commonTitle),
            ),
            if (widget.showCategory) ...<Widget>[
              _categoryField(t),
              if (_categoryChoice == goalCategoryCustomKey)
                TextField(
                  key: const ValueKey<String>(
                    'goal-form-category-custom-input',
                  ),
                  controller: _customCategory,
                  style: fieldStyle,
                  decoration: _decoration(
                    null,
                    hintText: t.goalFormCustomCategoryHint,
                  ),
                ),
            ],
            if (widget.compact)
              ExpansionTile(
                key: const ValueKey<String>('goal-blueprint-form-more'),
                title: Text(
                  '${t.goalBlueprintFieldNote} / '
                  '${t.goalBlueprintFieldKeywords}',
                  style: fieldStyle,
                ),
                // 去 M3 自带的上下分隔线与额外缩进，与相邻字段对齐。
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                children: noteAndKeywords,
              )
            else
              ...noteAndKeywords,
            DropdownButtonFormField<String>(
              key: const ValueKey<String>('goal-blueprint-form-domain'),
              initialValue: _domain,
              decoration: _decoration(t.goalBlueprintFieldDomain),
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
              onChanged: (String? value) => setState(() => _domain = value ?? ''),
            ),
            DropdownButtonFormField<GoalHorizon?>(
              key: const ValueKey<String>('goal-blueprint-form-horizon'),
              initialValue: _horizon,
              decoration: _decoration(t.goalBlueprintFieldHorizon),
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
            // 起止日期（B17 F 条）：点整行弹共享的起止日期对话框。
            if (widget.showPeriod) _periodField(t),
            // 期限（B12 第 3 条）：只读字段，点一下弹日期选择器。
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const ValueKey<String>('goal-blueprint-form-due'),
                    controller: _due,
                    readOnly: true,
                    style: fieldStyle,
                    onTap: _pickDue,
                    decoration: _decoration(
                      t.goalBlueprintFieldDue,
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                ),
                if (_dueMs != null)
                  TextButton(
                    key: const ValueKey<String>(
                      'goal-blueprint-form-due-clear',
                    ),
                    onPressed: _clearDue,
                    child: Text(t.commonClear),
                  ),
              ],
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

  /// 「目标类别」一行（B17 F 条）。
  ///
  /// 用 `PopupMenuButton` 承载选项（见文件头注释：下拉会把同 key 渲染两份）。
  Widget _categoryField(AppLocalizations t) {
    return InputDecorator(
      key: const ValueKey<String>('goal-form-category-field'),
      decoration: _decoration(t.goalFormCategoryLabel),
      child: PopupMenuButton<String>(
        tooltip: '',
        initialValue: _categoryChoice.isEmpty
            ? goalCategoryNoneKey
            : _categoryChoice,
        onSelected: (String value) => setState(() {
          _categoryChoice = value == goalCategoryNoneKey ? '' : value;
        }),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          for (final String key in goalCategoryKeys)
            PopupMenuItem<String>(
              key: ValueKey<String>('goal-form-category-$key'),
              value: key,
              child: Text(goalCategoryLabel(t, key)),
            ),
          PopupMenuItem<String>(
            key: const ValueKey<String>(
              'goal-form-category-$goalCategoryCustomKey',
            ),
            value: goalCategoryCustomKey,
            child: Text(goalCategoryLabel(t, goalCategoryCustomKey)),
          ),
          PopupMenuItem<String>(
            key: const ValueKey<String>(
              'goal-form-category-$goalCategoryNoneKey',
            ),
            value: goalCategoryNoneKey,
            child: Text(t.goalBlueprintFieldUnset),
          ),
        ],
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _categoryText(t),
                key: const ValueKey<String>('goal-form-category-text'),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  /// 类别字段的显示文本（未设置时与「不设类别」同一措辞）。
  String _categoryText(AppLocalizations t) {
    if (_categoryChoice.isEmpty) {
      return t.goalBlueprintFieldUnset;
    }
    if (_categoryChoice == goalCategoryCustomKey) {
      final String text = _customCategory.text.trim();
      return text.isEmpty ? goalCategoryLabel(t, goalCategoryCustomKey) : text;
    }
    return goalCategoryLabel(t, _categoryChoice);
  }

  /// 「起止日期」一行（B17 F 条）：整行可点，点开共享的起止日期对话框。
  Widget _periodField(AppLocalizations t) {
    return InkWell(
      key: const ValueKey<String>('goal-form-date-range'),
      onTap: _pickPeriod,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: _decoration(t.goalFormDateRange),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _periodText(t),
                key: const ValueKey<String>('goal-form-date-range-text'),
              ),
            ),
            const Icon(Icons.date_range_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  /// 起止字段的显示文本：两端都空 ⇒ `goalPeriodUnset`，否则 `start → end`。
  String _periodText(AppLocalizations t) {
    if (_periodStartMs <= 0 && _periodEndMs == null) {
      return t.goalPeriodUnset;
    }
    final String start = _periodStartMs > 0 ? _formatDay(_periodStartMs) : '—';
    final String end = _periodEndMs == null ? '—' : _formatDay(_periodEndMs);
    return '$start → $end';
  }

  /// 字段外框。
  ///
  /// 紧凑版（[compact] = true）：`isDense` + 收紧内边距 —— 蓝图页的填写框要
  /// 更紧凑；目标月 / 周 / 年页传 false，保持原版式不动。
  InputDecoration _decoration(String? labelText, {String? hintText}) {
    if (!widget.compact) {
      return InputDecoration(labelText: labelText, hintText: hintText);
    }
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  /// 弹日期选择器；选中的是**本地**某日 00:00（毫秒口径同 B11 裁决）。
  Future<void> _pickDue() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _dueMs == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(_dueMs!);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _clampToPickerRange(initial),
      firstDate: _pickerFirst,
      lastDate: _pickerLast,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      // `showDatePicker` 给的是本地 `DateTime`（00:00）⇒ 取毫秒即本地午夜毫秒。
      _dueMs = picked.millisecondsSinceEpoch;
      _due.text = _formatDay(_dueMs);
    });
  }

  /// 弹共享的起止日期对话框，并把结果写回表单状态（本函数不写库）。
  Future<void> _pickPeriod() async {
    final GoalPeriodResult? result = await showGoalPeriodDialog(
      context,
      t: widget.t,
      startMs: _periodStartMs,
      endMs: _periodEndMs,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _periodStartMs = result.startMs;
      _periodEndMs = result.endMs;
    });
  }

  /// 既有期限可能落在选择器区间之外（别的来源写的）⇒ 先夹进区间再打开。
  DateTime _clampToPickerRange(DateTime value) {
    if (value.isBefore(_pickerFirst)) {
      return _pickerFirst;
    }
    if (value.isAfter(_pickerLast)) {
      return _pickerLast;
    }
    return value;
  }

  /// 清空期限（保留原来「把期限清掉」的能力）。
  void _clearDue() {
    setState(() {
      _dueMs = null;
      _due.text = '';
    });
  }

  /// 类别选择 ⇒ 存储值（`Goal.domain` 口径）。
  ///
  /// 自定义类别 trim 后为空 ⇒ 视同不设类别（null），避免出现空标题的分区。
  String? _categoryResult() {
    if (_categoryChoice == goalCategoryCustomKey) {
      final String text = _customCategory.text.trim();
      return text.isEmpty ? null : '$goalCategoryCustomPrefix$text';
    }
    return _categoryChoice.isEmpty ? null : _categoryChoice;
  }

  /// 把结果交回页面（本函数**不写库**）。
  void _submit() {
    Navigator.of(context).pop(
      GoalFormResult(
        title: _title.text,
        note: _note.text,
        keywords: _keywords.text,
        domain: _domain,
        horizon: _horizon,
        dueDate: _dueMs,
        category: _categoryResult(),
        periodStart: _periodStartMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(_periodStartMs)
            : null,
        periodEnd: _periodEndMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(_periodEndMs!),
      ),
    );
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

/// 目标行尾的「编辑 / 删除」紧凑图标按钮（蓝图页之外的三页共用）。
///
/// 宽度固定 [width]（= 两个 28 的点击区），与表头预留的空列同宽 —— 行与表头
/// 必须用同一个常量，否则列会错位。
///
/// B17 F 条：新增**可选**的完成单选 —— [onToggleDone] 为 null 时该按钮**不
/// 渲染**，宽度仍为 [width]（蓝图矩阵 `shrinkWrap` 布局与既有断言依赖 56）。
/// 传了回调时总宽 = [width] + [doneWidth]（见 [totalWidth]），波 C 的表头预留
/// 列必须跟着用 [totalWidth]，否则列错位。
class GoalRowActions extends StatelessWidget {
  /// 构造。
  const GoalRowActions({
    required this.editKey,
    required this.deleteKey,
    required this.onEdit,
    required this.onDelete,
    required this.t,
    this.goalId,
    this.isDone = false,
    this.onToggleDone,
    super.key,
  });

  /// 编辑 / 删除两个按钮的宽度（各 28）。
  static const double width = 56;

  /// 完成单选的宽度（仅 [onToggleDone] 非 null 时占用）。
  static const double doneWidth = 24;

  /// 编辑按钮的 ValueKey（如 `goal-month-row-edit-<id>`）。
  final String editKey;

  /// 删除按钮的 ValueKey（如 `goal-month-row-delete-<id>`）。
  final String deleteKey;

  /// 点「编辑」。
  final VoidCallback onEdit;

  /// 点「删除」。
  final VoidCallback onDelete;

  /// 文案表（tooltip 用；页面 context 上取的实例）。
  final AppLocalizations t;

  /// 目标 id（只用于拼完成单选的 ValueKey；null / 空 ⇒ 退化为 `goal-row-done`）。
  final String? goalId;

  /// 是否已完成（选中 = 已完成）。
  final bool isDone;

  /// 点完成单选；null ⇒ 不渲染该按钮（蓝图矩阵走这条路径）。
  final VoidCallback? onToggleDone;

  /// 这一行操作列的实际宽度：没有完成单选时仍是 [width]。
  double get totalWidth => onToggleDone == null ? width : width + doneWidth;

  @override
  Widget build(BuildContext context) {
    final String? id = goalId;
    final String doneKey = id == null || id.isEmpty
        ? 'goal-row-done'
        : 'goal-row-done-$id';
    final VoidCallback? toggle = onToggleDone;
    // `IconButton` 默认按 `MaterialTapTargetSize.padded` 把点击区撑到 48×48，
    // 两个按钮就要 96 宽，会把这条 56 宽的操作列挤爆（实测溢出 40px）。
    // 这里显式 shrinkWrap，让点击区回到 `constraints` 给的尺寸。
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: SizedBox(
        width: totalWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              key: ValueKey<String>(editKey),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              tooltip: t.goalBlueprintEditGoal,
            ),
            IconButton(
              key: ValueKey<String>(deleteKey),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              tooltip: t.commonDelete,
            ),
            if (toggle != null)
              IconButton(
                key: ValueKey<String>(doneKey),
                onPressed: toggle,
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                ),
                iconSize: 16,
                color: isDone ? Theme.of(context).colorScheme.primary : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: doneWidth,
                  height: 28,
                ),
                tooltip: t.goalRowDoneTooltip,
              ),
          ],
        ),
      ),
    );
  }
}