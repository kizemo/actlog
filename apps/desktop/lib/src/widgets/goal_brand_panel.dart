// =============================================================================
// 目标 · 个人品牌管理面板（B9-W1）
// =============================================================================
// 位置：蓝图页 `GoalsBlueprintPage` 的**人生蓝图矩阵块上方**。
//
// 口径（派工书 docs\b91-dispatch-w1.md）：
//  * 左侧 10 个切面（`GoalFacet`：域层冻结的 10 个，**不新增第 11 个**；五原型
//    归入 `identity` 的文案范围），默认选中 `audience`（§3.4-1）；
//  * 右侧是当前切面的「要点 / 范例 / 反例」+ 标题输入 + 补充说明输入 + 保存；
//  * 落库复用既有 `goal` 表：`kind='brand'`、`facet=<切面>`，**零 schema 变更**；
//    每切面最多一行 ⇒ 已有行走 `updateGoal`（不传 `facet`），无行走 `createGoal`；
//  * 空标题点保存**不写行**（不建空行、不写空 title）；
//  * 本模块**不使用 Material 图标**（仓库禁图标常量），折叠指引块用 `TextButton`。
//
// 面板自己取数（`listGoals(kind: GoalKind.brand)`），不污染蓝图页的 `_load()`。
// =============================================================================

import 'package:core_domain/core_domain.dart' show GoalFacet, GoalKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart' show GoalRow;
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';

/// 切面渲染顺序（派工书 §3.4-1 逐字）。
const List<GoalFacet> _facetOrder = <GoalFacet>[
  GoalFacet.statement,
  GoalFacet.word,
  GoalFacet.audience,
  GoalFacet.promise,
  GoalFacet.cost,
  GoalFacet.evidence,
  GoalFacet.contrast,
  GoalFacet.strength,
  GoalFacet.errc,
  GoalFacet.identity,
];

/// 一个切面的四条文案（标签 / 要点 / 范例 / 反例）。
class _FacetTexts {
  /// 构造。
  const _FacetTexts({
    required this.label,
    required this.hint,
    required this.example,
    required this.counter,
  });

  /// 切面标签。
  final String label;

  /// 要点。
  final String hint;

  /// 范例。
  final String example;

  /// 反例。
  final String counter;
}

/// 蓝图页顶部的「个人品牌管理」面板。
class GoalBrandPanel extends ConsumerStatefulWidget {
  /// 创建面板。
  const GoalBrandPanel({super.key});

  @override
  ConsumerState<GoalBrandPanel> createState() => _GoalBrandPanelState();
}

class _GoalBrandPanelState extends ConsumerState<GoalBrandPanel> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();

  /// 切面 → 该切面的品牌行（每切面最多一行）。
  final Map<GoalFacet, GoalRow> _rows = <GoalFacet, GoalRow>{};

  GoalFacet _facet = GoalFacet.audience;
  bool _saved = false;
  bool _guideOpen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  /// 读品牌行并按切面分桶；重复行按 id 升序取**第一条**（幂等）。
  Future<void> _reload() async {
    try {
      final List<GoalRow> rows = await ref
          .read(goalStoreProvider)
          .listGoals(kind: GoalKind.brand);
      if (!mounted) {
        return;
      }
      _rows.clear();
      for (final GoalRow goal in rows) {
        final GoalFacet? facet = goal.facet;
        if (facet == null) {
          continue;
        }
        final GoalRow? prev = _rows[facet];
        if (prev == null || goal.id.compareTo(prev.id) < 0) {
          _rows[facet] = goal;
        }
      }
      setState(() {});
      _fillInputs();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).goalBrandSaveFailed);
    }
  }

  /// 把当前切面的库值填进输入框。
  void _fillInputs() {
    final GoalRow? row = _rows[_facet];
    _title.text = row?.title ?? '';
    _note.text = row?.note ?? '';
  }

  /// 切面导航。
  void _selectFacet(GoalFacet facet) {
    if (facet == _facet) {
      return;
    }
    setState(() {
      _facet = facet;
      _saved = false;
      _error = null;
    });
    _fillInputs();
  }

  /// 保存当前切面：已有行改行、无行建行、空标题不写库。
  Future<void> _save() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final GoalFacet facet = _facet;
    final String title = _title.text.trim();
    final String note = _note.text.trim();

    setState(() {
      _saved = false;
      _error = null;
    });

    if (title.isEmpty) {
      // 空内容不写行：库里「这一面还空着」的提示本身就是反馈。
      return;
    }

    try {
      final GoalRow? existing = _rows[facet];
      if (existing == null) {
        await ref.read(goalStoreProvider).createGoal(
              kind: GoalKind.brand,
              facet: facet,
              title: title,
              note: note.isEmpty ? null : note,
            );
      } else {
        // 不传 `facet`（`null` 的语义是「不动」），补充说明留空也不清别人的值。
        await ref.read(goalStoreProvider).updateGoal(
              existing.id,
              title: title,
              note: note.isEmpty ? null : note,
            );
      }
      if (!mounted) {
        return;
      }
      setState(() => _saved = true);
      await _reload();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = t.goalBrandSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final ThemeTokens tokens = context.tokens;
    final _FacetTexts texts = _facetTexts(t, _facet);

    return Container(
      key: const ValueKey<String>('goal-brand-panel'),
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
            t.goalBrandSection,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: tokens.ink),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: tokens.hair),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 160, child: _buildFacetNav(t)),
              const SizedBox(width: 12),
              Expanded(child: _buildEditor(context, t, texts)),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: tokens.hair),
          _buildGuide(context, t),
        ],
      ),
    );
  }

  /// 左侧：10 个切面导航。
  Widget _buildFacetNav(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(t.goalBrandFacetNavLabel, style: _metaStyle(context)),
        const SizedBox(height: 4),
        for (final GoalFacet facet in _facetOrder)
          TextButton(
            key: ValueKey<String>('goal-brand-facet-${facet.code}'),
            onPressed: () => _selectFacet(facet),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            child: Text(
              _facetTexts(t, facet).label,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: facet == _facet ? context.tokens.ink : context.tokens.meta,
                fontWeight: facet == _facet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  /// 右侧：当前切面的要点 / 范例 / 反例 + 两个输入框 + 保存。
  Widget _buildEditor(
    BuildContext context,
    AppLocalizations t,
    _FacetTexts texts,
  ) {
    final String code = _facet.code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          texts.label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: context.tokens.ink),
        ),
        const SizedBox(height: 4),
        Text(texts.hint, style: _bodyStyle(context)),
        const SizedBox(height: 4),
        Text(texts.example, style: _metaStyle(context)),
        Text(texts.counter, style: _metaStyle(context)),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey<String>('goal-brand-title-$code'),
          controller: _title,
          decoration: InputDecoration(
            labelText: t.goalBrandTitleLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey<String>('goal-brand-note-$code'),
          controller: _note,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            labelText: t.goalBrandNoteLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            TextButton(
              key: ValueKey<String>('goal-brand-save-$code'),
              onPressed: _save,
              child: Text(t.goalBrandSave),
            ),
            const SizedBox(width: 8),
            if (_saved)
              Text(
                t.goalBrandSaved,
                key: const ValueKey<String>('goal-brand-saved'),
                style: _metaStyle(context),
              ),
            if (_error != null)
              Text(
                _error!,
                key: const ValueKey<String>('goal-brand-error'),
                style: _metaStyle(context),
              ),
          ],
        ),
        if (_rows[_facet] == null)
          Text(t.goalBrandEmpty, style: _metaStyle(context)),
      ],
    );
  }

  /// 底部：可折叠的指引块（定位公式 / 三层结构 / 三步方法论 / PBE）。
  Widget _buildGuide(BuildContext context, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextButton(
          onPressed: () => setState(() => _guideOpen = !_guideOpen),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          child: Text(t.goalBrandGuideToggle),
        ),
        if (_guideOpen) ...<Widget>[
          Text(
            t.goalBrandGuideTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: context.tokens.ink),
          ),
          const SizedBox(height: 4),
          Text(t.goalBrandGuideFormula, style: _bodyStyle(context)),
          Text(t.goalBrandGuideLayers, style: _bodyStyle(context)),
          Text(t.goalBrandGuideMethod, style: _bodyStyle(context)),
          Text(t.goalBrandGuidePbe, style: _bodyStyle(context)),
        ],
      ],
    );
  }

  /// 一个切面的四条文案。
  _FacetTexts _facetTexts(AppLocalizations t, GoalFacet facet) {
    switch (facet) {
      case GoalFacet.statement:
        return _FacetTexts(
          label: t.goalBrandFacetStatement,
          hint: t.goalBrandFacetStatementHint,
          example: t.goalBrandFacetStatementExample,
          counter: t.goalBrandFacetStatementCounterExample,
        );
      case GoalFacet.word:
        return _FacetTexts(
          label: t.goalBrandFacetWord,
          hint: t.goalBrandFacetWordHint,
          example: t.goalBrandFacetWordExample,
          counter: t.goalBrandFacetWordCounterExample,
        );
      case GoalFacet.audience:
        return _FacetTexts(
          label: t.goalBrandFacetAudience,
          hint: t.goalBrandFacetAudienceHint,
          example: t.goalBrandFacetAudienceExample,
          counter: t.goalBrandFacetAudienceCounterExample,
        );
      case GoalFacet.promise:
        return _FacetTexts(
          label: t.goalBrandFacetPromise,
          hint: t.goalBrandFacetPromiseHint,
          example: t.goalBrandFacetPromiseExample,
          counter: t.goalBrandFacetPromiseCounterExample,
        );
      case GoalFacet.cost:
        return _FacetTexts(
          label: t.goalBrandFacetCost,
          hint: t.goalBrandFacetCostHint,
          example: t.goalBrandFacetCostExample,
          counter: t.goalBrandFacetCostCounterExample,
        );
      case GoalFacet.evidence:
        return _FacetTexts(
          label: t.goalBrandFacetEvidence,
          hint: t.goalBrandFacetEvidenceHint,
          example: t.goalBrandFacetEvidenceExample,
          counter: t.goalBrandFacetEvidenceCounterExample,
        );
      case GoalFacet.contrast:
        return _FacetTexts(
          label: t.goalBrandFacetContrast,
          hint: t.goalBrandFacetContrastHint,
          example: t.goalBrandFacetContrastExample,
          counter: t.goalBrandFacetContrastCounterExample,
        );
      case GoalFacet.strength:
        return _FacetTexts(
          label: t.goalBrandFacetStrength,
          hint: t.goalBrandFacetStrengthHint,
          example: t.goalBrandFacetStrengthExample,
          counter: t.goalBrandFacetStrengthCounterExample,
        );
      case GoalFacet.errc:
        return _FacetTexts(
          label: t.goalBrandFacetErrc,
          hint: t.goalBrandFacetErrcHint,
          example: t.goalBrandFacetErrcExample,
          counter: t.goalBrandFacetErrcCounterExample,
        );
      case GoalFacet.identity:
        return _FacetTexts(
          label: t.goalBrandFacetIdentity,
          hint: t.goalBrandFacetIdentityHint,
          example: t.goalBrandFacetIdentityExample,
          counter: t.goalBrandFacetIdentityCounterExample,
        );
    }
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