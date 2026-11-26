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
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/goal_store.dart';
import '../../data/project_domain_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../goal_blueprint_matrix.dart';

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
}) => showDialog<GoalFormResult>(
  context: context,
  builder: (BuildContext context) => GoalFormDialog(
    t: t,
    domainKey: domainKey,
    horizon: horizon,
    existing: existing,
    compact: compact,
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

  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
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
    // 紧凑版：收紧行高（长文本照常换行，不裁切）。
    final TextStyle? fieldStyle = widget.compact
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)
        : null;
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
              decoration: _decoration(t.commonTitle),
            ),
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
            TextField(
              key: const ValueKey<String>('goal-blueprint-form-due'),
              controller: _due,
              style: fieldStyle,
              decoration: _decoration(
                t.goalBlueprintFieldDue,
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

  /// 字段外框。
  ///
  /// 紧凑版（[compact] = true）：`isDense` + 收紧内边距 —— 蓝图页的填写框要
  /// 更紧凑；目标月 / 周 / 年页传 false，保持原版式不动。
  InputDecoration _decoration(
    String? labelText, {
    String? hintText,
    String? errorText,
  }) {
    if (!widget.compact) {
      return InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
      );
    }
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      GoalFormResult(
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

/// 目标行尾的「编辑 / 删除」紧凑图标按钮（蓝图页之外的三页共用）。
///
/// 宽度固定 [width]（= 两个 28 的点击区），与表头预留的空列同宽 —— 行与表头
/// 必须用同一个常量，否则列会错位。
class GoalRowActions extends StatelessWidget {
  /// 构造。
  const GoalRowActions({
    required this.editKey,
    required this.deleteKey,
    required this.onEdit,
    required this.onDelete,
    required this.t,
    super.key,
  });

  /// 操作列宽度（两个 28 宽的点击区）。
  static const double width = 56;

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

  @override
  Widget build(BuildContext context) {
    // `IconButton` 默认按 `MaterialTapTargetSize.padded` 把点击区撑到 48×48，
    // 两个按钮就要 96 宽，会把这条 56 宽的操作列挤爆（实测溢出 40px）。
    // 这里显式 shrinkWrap，让点击区回到 `constraints` 给的 28×28。
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: SizedBox(
        width: width,
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
          ],
        ),
      ),
    );
  }
}