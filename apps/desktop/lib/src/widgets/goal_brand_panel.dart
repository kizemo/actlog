// =============================================================================
// 目标 · 个人定位面板（B10-D1 棒 A；原「个人品牌管理」B9-W1 **原地改造**）
// =============================================================================
// 位置：蓝图页 `GoalsBlueprintPage` 的**人生蓝图矩阵块上方**。
//
// 口径（派工书 docs\b10-dispatch-d1.md §3）：
//  * 四项问答（顺序即渲染顺序，逐项落库到既有 `facet`）：
//      values    「我的价值观」  → `GoalFacet.identity`
//      strengths 「我的优势」    → `GoalFacet.strength`
//      value     「独特价值」    → `GoalFacet.promise`
//      proof     「信任背书」    → `GoalFacet.evidence`
//  * 落库复用既有 `goal` 表：`kind='brand'` + `facet=<上面那个>`，**零 schema 变更**；
//    每项最多一行 ⇒ 已有行走 `updateGoal`（不传 `facet`），无行走 `createGoal`；
//  * **旧 10 切面里另外 6 个切面**（statement / word / audience / cost / contrast /
//    errc）的历史行**保留不删**，本面板不再显示、也不再改写它们；
//  * 空文本点保存**不写行**（不建空行、不写空 title）；成功显示「已保存」，
//    失败显示错误行；
//  * 价值观 / 优势带标签库（Schwartz 10 项 / VIA 24 项，文案在 l10n 的
//    `List<String>` getter）：输入框悬停 ⇒ `OverlayEntry` 浮层贴在鼠标右下
//    （+12/+16，按屏幕夹取）；鼠标离开输入框 **3 秒**后消失；浮层自身可点，
//    进入取消计时、离开重新计时；点标签**追加**到输入框文本；
//  * 本模块**不使用 Material 图标**（仓库禁新增图标常量）。
//
// 面板自己取数（`listGoals(kind: GoalKind.brand)`），不污染蓝图页的 `_load()`。
// =============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:core_domain/core_domain.dart' show GoalFacet, GoalKind;
import 'package:flutter/gestures.dart'
    show PointerEnterEvent, PointerExitEvent, PointerHoverEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_store.dart' show GoalRow;
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';

/// 四项的 code（也是测试键后缀与渲染顺序）。
const List<String> _positionCodes = <String>[
  'values',
  'strengths',
  'value',
  'proof',
];

/// 标签浮层距鼠标的偏移（右下）。
const Offset _tagsGap = Offset(12, 16);

/// 鼠标离开后浮层停留时长（留出「移过去点」的时间）。
const Duration _tagsLinger = Duration(seconds: 3);

/// 浮层宽度上限。
const double _tagsMaxWidth = 360;

/// 一项问答的渲染数据。
class _PositionItem {
  /// 构造。
  const _PositionItem({
    required this.code,
    required this.facet,
    required this.title,
    required this.hint,
    this.tags = const <String>[],
  });

  /// 测试键后缀（`values` / `strengths` / `value` / `proof`）。
  final String code;

  /// 落库切面。
  final GoalFacet facet;

  /// 项标题。
  final String title;

  /// 要点指引（1–2 行）。
  final String hint;

  /// 标签库（空 = 该项不带标签）。
  final List<String> tags;
}

/// 蓝图页顶部的「个人定位」面板。
class GoalPositionPanel extends ConsumerStatefulWidget {
  /// 创建面板。
  const GoalPositionPanel({super.key});

  @override
  ConsumerState<GoalPositionPanel> createState() => _GoalPositionPanelState();
}

class _GoalPositionPanelState extends ConsumerState<GoalPositionPanel> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  /// 项 code → 该切面已落库的行（每项最多一行）。
  final Map<String, GoalRow> _rows = <String, GoalRow>{};

  /// 已显示「已保存」的项 code（同一时刻最多一个）。
  String? _savedCode;

  /// 已显示错误行的项 code。
  String? _failedCode;

  String? _error;

  /// 标签浮层（同一时刻最多一个）。
  OverlayEntry? _tagsOverlay;
  Timer? _tagsTimer;
  String? _tagsCode;
  Offset _tagsAnchor = Offset.zero;

  @override
  void initState() {
    super.initState();
    for (final String code in _positionCodes) {
      _controllers[code] = TextEditingController();
    }
    _reload();
  }

  @override
  void dispose() {
    // 先摘浮层再取消计时：顺序反了会让 Timer 回调碰已 dispose 的 State。
    _removeTagsOverlay();
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 读品牌行并按项分桶；重复行按 id 升序取**第一条**（幂等）。
  ///
  /// [fillCode] 为 null ⇒ 回填全部四项（首次装载）；非 null ⇒ 只回填这一项
  /// （保存后刷新），避免把别的项里**还没保存**的输入冲掉。
  Future<void> _reload({String? fillCode}) async {
    try {
      final List<GoalRow> rows = await ref
          .read(goalStoreProvider)
          .listGoals(kind: GoalKind.brand);
      if (!mounted) {
        return;
      }
      _rows.clear();
      for (final GoalRow goal in rows) {
        final String? code = _codeForFacet(goal.facet);
        if (code == null) {
          continue;
        }
        final GoalRow? prev = _rows[code];
        if (prev == null || goal.id.compareTo(prev.id) < 0) {
          _rows[code] = goal;
        }
      }
      setState(() {});
      if (fillCode == null) {
        for (final String code in _positionCodes) {
          _fillInput(code);
        }
      } else {
        _fillInput(fillCode);
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppLocalizations.of(context).goalBrandSaveFailed);
    }
  }

  /// 把某一项的库值填进输入框。
  void _fillInput(String code) {
    _controllers[code]?.text = _rows[code]?.title ?? '';
  }

  /// 保存一项：已有行改行、无行建行、空文本不写库。
  Future<void> _save(_PositionItem item) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final String code = item.code;
    final String text = _controllers[code]!.text.trim();

    setState(() {
      _savedCode = null;
      _failedCode = null;
      _error = null;
    });

    if (text.isEmpty) {
      // 空内容不写行：不建空行、也不改既有行。
      return;
    }

    try {
      final GoalRow? existing = _rows[code];
      if (existing == null) {
        await ref.read(goalStoreProvider).createGoal(
              kind: GoalKind.brand,
              facet: item.facet,
              title: text,
            );
      } else {
        // 不传 `facet`（`null` 的语义是「不动」）。
        await ref.read(goalStoreProvider).updateGoal(
              existing.id,
              title: text,
            );
      }
      if (!mounted) {
        return;
      }
      setState(() => _savedCode = code);
      await _reload(fillCode: code);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _failedCode = code;
        _error = t.goalBrandSaveFailed;
      });
    }
  }

  /// 点击标签：追加到对应输入框（同一标签不重复）。
  void _appendTag(String code, String tag) {
    final TextEditingController? controller = _controllers[code];
    if (controller == null) {
      return;
    }
    final String current = controller.text;
    for (final String part in current.split(RegExp(r'[、，,\n]'))) {
      if (part.trim() == tag) {
        return;
      }
    }
    final String next;
    if (current.trim().isEmpty) {
      next = tag;
    } else if (current.endsWith('、') ||
        current.endsWith('，') ||
        current.endsWith(',') ||
        current.endsWith('\n')) {
      next = '$current$tag';
    } else {
      next = '$current、$tag';
    }
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {
      // 文本变了，上一次的「已保存」不再成立。
      _savedCode = null;
      _failedCode = null;
      _error = null;
    });
  }

  /// 鼠标进入带标签库的输入框：开出（或刷新）浮层。
  void _openTags(String code, Offset position) {
    _tagsAnchor = position;
    _cancelTagsHide();

    final OverlayEntry? existing = _tagsOverlay;
    if (existing != null) {
      if (_tagsCode == code) {
        // 重复 enter 只挪位置，绝不叠加第二个 OverlayEntry。
        existing.markNeedsBuild();
        return;
      }
      _removeTagsOverlay();
    }

    final AppLocalizations t = AppLocalizations.of(context);
    final List<String> tags = _tagsFor(t, code);
    if (tags.isEmpty) {
      return;
    }
    final ThemeTokens tokens = context.tokens;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext _) => _TagsBubble(
        t: t,
        tokens: tokens,
        anchor: _tagsAnchor,
        code: code,
        tags: tags,
        onPick: (String tag) => _appendTag(code, tag),
        onEnter: _cancelTagsHide,
        onExit: _scheduleTagsHide,
      ),
    );
    _tagsCode = code;
    _tagsOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// 鼠标在输入框内移动：跟着鼠标走。
  void _moveTags(String code, Offset position) {
    if (_tagsOverlay == null || _tagsCode != code) {
      _openTags(code, position);
      return;
    }
    _tagsAnchor = position;
    _tagsOverlay!.markNeedsBuild();
  }

  /// 离开输入框 / 离开浮层：重新起 3 秒计时。
  void _scheduleTagsHide() {
    _cancelTagsHide();
    _tagsTimer = Timer(_tagsLinger, _removeTagsOverlay);
  }

  /// 取消计时（鼠标回到输入框或浮层上）。
  void _cancelTagsHide() {
    _tagsTimer?.cancel();
    _tagsTimer = null;
  }

  /// 摘掉浮层并停表（幂等）。
  void _removeTagsOverlay() {
    _cancelTagsHide();
    _tagsOverlay?.remove();
    _tagsOverlay = null;
    _tagsCode = null;
  }

  /// 一项的标签库（没有就空表）。
  List<String> _tagsFor(AppLocalizations t, String code) {
    switch (code) {
      case 'values':
        return t.goalPositionValueTags;
      case 'strengths':
        return t.goalPositionStrengthTags;
      default:
        return const <String>[];
    }
  }

  /// code → 落库切面。
  GoalFacet _facetFor(String code) {
    if (code == 'values') {
      return GoalFacet.identity;
    }
    if (code == 'strengths') {
      return GoalFacet.strength;
    }
    if (code == 'value') {
      return GoalFacet.promise;
    }
    return GoalFacet.evidence;
  }

  /// 切面 → code；旧 6 个切面返回 null（行留在库里，本面板不读）。
  String? _codeForFacet(GoalFacet? facet) {
    switch (facet) {
      case GoalFacet.identity:
        return 'values';
      case GoalFacet.strength:
        return 'strengths';
      case GoalFacet.promise:
        return 'value';
      case GoalFacet.evidence:
        return 'proof';
      default:
        return null;
    }
  }

  /// 四项的渲染数据（标题 / 指引 / 标签库都走 l10n）。
  List<_PositionItem> _items(AppLocalizations t) {
    return <_PositionItem>[
      _PositionItem(
        code: 'values',
        facet: _facetFor('values'),
        title: t.goalPositionValuesTitle,
        hint: t.goalPositionValuesHint,
        tags: t.goalPositionValueTags,
      ),
      _PositionItem(
        code: 'strengths',
        facet: _facetFor('strengths'),
        title: t.goalPositionStrengthsTitle,
        hint: t.goalPositionStrengthsHint,
        tags: t.goalPositionStrengthTags,
      ),
      _PositionItem(
        code: 'value',
        facet: _facetFor('value'),
        title: t.goalPositionValueTitle,
        hint: t.goalPositionValueHint,
      ),
      _PositionItem(
        code: 'proof',
        facet: _facetFor('proof'),
        title: t.goalPositionProofTitle,
        hint: t.goalPositionProofHint,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final ThemeTokens tokens = context.tokens;
    final List<_PositionItem> items = _items(t);

    final List<Widget> blocks = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(height: 1, color: tokens.hair),
          ),
        );
      }
      blocks.add(_buildItem(items[i], tokens));
    }

    return Container(
      key: const ValueKey<String>('goal-position-panel'),
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
            t.goalPositionSection,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: tokens.ink),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: tokens.hair),
          ...blocks,
        ],
      ),
    );
  }

  /// 一项：标题 + 要点指引 + 多行输入框 + 右侧「保存」+ 状态行。
  Widget _buildItem(_PositionItem item, ThemeTokens tokens) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String code = item.code;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: tokens.ink),
          ),
          const SizedBox(height: 2),
          Text(item.hint, style: _metaStyle(context)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildInput(item)),
              const SizedBox(width: 8),
              TextButton(
                key: ValueKey<String>('goal-position-save-$code'),
                onPressed: () => _save(item),
                child: Text(t.goalBrandSave),
              ),
            ],
          ),
          if (_savedCode == code)
            Text(
              t.goalBrandSaved,
              key: const ValueKey<String>('goal-position-saved'),
              style: _metaStyle(context),
            ),
          if (_failedCode == code && _error != null)
            Text(
              _error!,
              key: const ValueKey<String>('goal-position-error'),
              style: _metaStyle(context),
            ),
        ],
      ),
    );
  }

  /// 输入框；带标签库的项再套一层 `MouseRegion` 驱动浮层。
  Widget _buildInput(_PositionItem item) {
    final TextField field = TextField(
      key: ValueKey<String>('goal-position-input-${item.code}'),
      controller: _controllers[item.code],
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
    if (item.tags.isEmpty) {
      return field;
    }
    return MouseRegion(
      onEnter: (PointerEnterEvent event) => _openTags(item.code, event.position),
      onHover: (PointerHoverEvent event) => _moveTags(item.code, event.position),
      onExit: (PointerExitEvent event) => _scheduleTagsHide(),
      child: field,
    );
  }

  /// 次级文字样式。
  TextStyle? _metaStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(color: context.tokens.meta);
}

/// 标签浮层：标题 + chip 流式换行；自己进入取消计时、离开重新计时。
class _TagsBubble extends StatelessWidget {
  const _TagsBubble({
    required this.t,
    required this.tokens,
    required this.anchor,
    required this.code,
    required this.tags,
    required this.onPick,
    required this.onEnter,
    required this.onExit,
  });

  final AppLocalizations t;
  final ThemeTokens tokens;
  final Offset anchor;
  final String code;
  final List<String> tags;
  final void Function(String tag) onPick;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final TextStyle? chipStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.ink);
    return CustomSingleChildLayout(
      delegate: _TagsLayout(anchor),
      child: MouseRegion(
        onEnter: (PointerEnterEvent event) => onEnter(),
        onExit: (PointerExitEvent event) => onExit(),
        child: Container(
          key: const ValueKey<String>('goal-position-tags-overlay'),
          width: _tagsMaxWidth,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: tokens.hairSoft, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.goalPositionTagsTitle, style: chipStyle),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (int i = 0; i < tags.length; i++)
                    _chip(i, tags[i], chipStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(int index, String tag, TextStyle? style) {
    return GestureDetector(
      key: ValueKey<String>('goal-position-tag-$code-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onPick(tag),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: tokens.hairSoft, width: 1),
          ),
          child: Text(tag, style: style),
        ),
      ),
    );
  }
}

/// 把浮层钉在鼠标右下，并夹在屏幕内（含右下边缘）。
class _TagsLayout extends SingleChildLayoutDelegate {
  const _TagsLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final double maxWidth = math.max(0, math.min(_tagsMaxWidth, constraints.maxWidth - 16));
    final double maxHeight = math.max(0, constraints.maxHeight - 16);
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = math.max(8, size.width - childSize.width - 8);
    final double maxY = math.max(8, size.height - childSize.height - 8);
    final double x = math.max(8, math.min(anchor.dx + _tagsGap.dx, maxX));
    final double y = math.max(8, math.min(anchor.dy + _tagsGap.dy, maxY));
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TagsLayout oldDelegate) => oldDelegate.anchor != anchor;
}