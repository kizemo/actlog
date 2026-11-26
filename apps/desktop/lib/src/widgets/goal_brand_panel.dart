// =============================================================================
// 目标 · 个人定位面板（B10-D1 棒 A；B12 第 1 项：说明入浮层 + 去确认键）
// =============================================================================
// 位置：蓝图页 `GoalsBlueprintPage` 的**人生蓝图矩阵块上方**。
//
// 口径（派工书 docs\b10-dispatch-d1.md §3；B12 用户反馈第 1 条在其上改）：
//  * 四项问答（顺序即渲染顺序，逐项落库到既有 `facet`）：
//      values    「我的价值观」  → `GoalFacet.identity`
//      strengths 「我的优势」    → `GoalFacet.strength`
//      value     「独特价值」    → `GoalFacet.promise`
//      proof     「信任背书」    → `GoalFacet.evidence`
//  * 落库复用既有 `goal` 表：`kind='brand'` + `facet=<上面那个>`，**零 schema 变更**；
//    每项最多一行 ⇒ 已有行走 `updateGoal`（不传 `facet`），无行走 `createGoal`；
//  * **旧 10 切面里另外 6 个切面**（statement / word / audience / cost / contrast /
//    errc）的历史行**保留不删**，本面板不再显示、也不再改写它们；
//  * **没有「保存」按钮、也没有「标签库」开关**（B12）：保存改成自动 ——
//      · 点标签库里的标签 ⇒ 并入该项的多值文本并**立即落库**，状态行跟着更新；
//      · 手动输入后**回车** ⇒ 文本按 `、`、`，`、`,`、换行 拆成多个标签，
//        并入多值文本并**自动落库**，落库成功后清空输入框；
//      · 空文本回车 / 空内容**不写行**（不建空行、不写空 title）；成功显示
//        「已保存」，失败显示错误行；
//  * **填写说明不再常驻渲染**（B12）：鼠标悬停在定位分类标题上时，在标题附近
//    弹出**自绘**浮层显示该条说明（离开后延迟消失；浮层不吃指针，不挡输入）。
//  * 标签库入口改成**点击 / 聚焦输入框**（外加原来的悬停）：浮层仍**锚在输入框
//    自身**（下方优先、下方放不下就翻上方，**不跟随鼠标**）；指针进入浮层内部
//    **暂停** 3 秒计时、离开浮层才重新计时；聚焦打开的浮层是**钉住态**（输入时
//    不自动消失）；浮层开着时**点外部**或按 **Esc** 关闭；同一项绝不叠加第二个。
//  * 输入框整体压缩（`isDense` + 收紧 `contentPadding` + 收紧行高），单行起步、
//    最多 4 行，长文本照常换行、不裁切。
//  * 本模块**不使用 Material 图标**（仓库禁新增图标常量）；浮层里**不放
//    Tooltip**（Tooltip 承载可点内容会被既有 `find.byKey` 计数断言打破）。
//
// 面板自己取数（`listGoals(kind: GoalKind.brand)`），不污染蓝图页的 `_load()`。
// =============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:core_domain/core_domain.dart' show GoalFacet, GoalKind;
import 'package:flutter/gestures.dart'
    show
        GestureBinding,
        PointerDownEvent,
        PointerEnterEvent,
        PointerEvent,
        PointerExitEvent,
        PointerHoverEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
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

/// 浮层与输入框之间的间距（浮层贴输入框下沿，**不跟鼠标走**）。
const double _tagsGap = 8;

/// 鼠标离开后浮层停留时长（留出「移过去点」的时间）。
const Duration _tagsLinger = Duration(seconds: 3);

/// 浮层宽度上限。
const double _tagsMaxWidth = 360;

/// 说明浮层宽度上限（比标签浮层窄：说明是短句）。
const double _hintMaxWidth = 280;

/// 浮层锚点与输入框的最小间距（夹在窗口内用）。
const double _tagsEdge = 8;

/// 多值分隔符：顿号、中文逗号、英文逗号、换行。
///
/// 「以符号分隔」是用户当轮的原话；顿号是**写回库里的口径**（拆分只用于判
/// 重与合并，落库一律用顿号连接）。
final RegExp _tagSeparators = RegExp(r'[、，,\n]');

/// 四问并成 1×4 单行所需的最小面板宽度；窄于此回落纵向堆叠（键位与浮窗逻辑不变）。
const double _inlineBreakpoint = 720;

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

  /// 浮层锚点矩形（**输入框自身**的矩形，相对 root overlay 原点）。
  ///
  /// 布局期**不能**读 `RenderBox.size`（Flutter 会抛「size accessed beyond the
  /// scope of resize, layout」断言），所以锚点矩形一律在布局期之外算好，
  /// 布局时只读这个纯值。
  Rect? _tagsAnchorRect;

  /// 浮层是否「钉住」（聚焦输入框打开 ⇒ 不自动消失，直到 Esc / 点外部）。
  bool _tagsPinned = false;

  /// Esc 钩子是否已挂上。
  bool _keyboardHooked = false;

  /// 指针路由（点外部关闭）：全局路由；回调对象固定 ⇒ 注册 / 摘除成对。
  late final void Function(PointerEvent) _pointerRoute = _onPointerEvent;

  /// 全局指针路由是否已注册（`removeGlobalRoute` 重复摘除会触发断言）。
  bool _pointerHooked = false;

  /// 浮层根的键（判定「点的是不是浮层内部」）。
  final GlobalKey _tagsBubbleKey = GlobalKey();

  /// 项 code → 输入框锚点键（浮层锚在输入框自身的矩形上）。
  final Map<String, GlobalKey> _anchorKeys = <String, GlobalKey>{};

  /// 项 code → 标题锚点键（说明浮层锚在标题自身的矩形上）。
  final Map<String, GlobalKey> _titleKeys = <String, GlobalKey>{};

  /// 项 code → 输入框的焦点节点（聚焦即开标签库；回车键也靠它兜底）。
  final Map<String, FocusNode> _focusNodes = <String, FocusNode>{};

  /// 正在落库的项 code：同一项重复触发（回车键 + IME「done」可能同时到）
  /// 只让第一个写库，避免同一切面写两行。
  final Set<String> _saving = <String>{};

  /// 说明浮层（悬停标题时出现；同一时刻最多一个）。
  OverlayEntry? _hintOverlay;
  Timer? _hintTimer;
  String? _hintCode;

  /// 说明浮层锚点矩形（**标题自身**的矩形，相对 root overlay 原点）。
  Rect? _hintAnchorRect;

  @override
  void initState() {
    super.initState();
    for (final String code in _positionCodes) {
      _controllers[code] = TextEditingController();
      _focusNodes[code] = FocusNode(debugLabel: 'goal-position-$code');
      _anchorKeys[code] = GlobalKey();
      _titleKeys[code] = GlobalKey();
      _focusNodes[code]!.addListener(() => _onFocusChanged(code));
    }
    _reload();
  }

  @override
  void dispose() {
    // 先摘浮层再取消计时：顺序反了会让 Timer 回调碰已 dispose 的 State。
    _removeTagsOverlay();
    _removeHintOverlay();
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// 读品牌行并按项分桶；重复行按 id 升序取**第一条**（幂等）。
  ///
  /// [fillCode] 为 null ⇒ 回填全部四项（首次装载）；非 null ⇒ 只回填这一项
  /// （保存后刷新），避免把别的项里**还没保存**的输入冲掉。
  ///
  /// [fill] = false ⇒ 只刷库值、**不回填输入框**（回车录入路径：落库后要清空
  /// 输入框，回填会把它又填回来）。
  Future<void> _reload({String? fillCode, bool fill = true}) async {
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
      if (!fill) {
        return;
      }
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
  ///
  /// 写库的值 = 输入框当前文本（多值文本）。
  ///
  /// [clearInput] = true ⇒ 落库成功后**清空输入框**（回车录入路径）。
  Future<void> _save(_PositionItem item, {bool clearInput = false}) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final String code = item.code;
    if (_saving.contains(code)) {
      // 同一项正在落库：重复触发（回车键 + IME「done」可能同时到）直接忽略，
      // 免得同一切面写两行。
      return;
    }
    final String text = _controllers[code]!.text.trim();

    setState(() {
      _savedCode = null;
      _failedCode = null;
      _error = null;
    });

    if (text.isEmpty) {
      // 空内容不写库：不建空行、也不改既有行。
      return;
    }

    _saving.add(code);
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
      await _reload(fillCode: code, fill: !clearInput);
      if (clearInput && mounted) {
        // 回车录入：落库成功后清空输入框（下一批标签从空开始录）。
        _controllers[code]?.clear();
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _failedCode = code;
        _error = t.goalBrandSaveFailed;
      });
    } finally {
      _saving.remove(code);
    }
  }

  /// 把一段文本拆成标签列表（去空白、去空项、去重、保序）。
  List<String> _splitTags(String text) {
    final List<String> tags = <String>[];
    for (final String part in text.split(_tagSeparators)) {
      final String tag = part.trim();
      if (tag.isEmpty) {
        continue;
      }
      if (!tags.contains(tag)) {
        tags.add(tag);
      }
    }
    return tags;
  }

  /// 某项当前的「多值文本」：**库值与输入框工作副本的并集**（去重、保序）。
  ///
  /// 落库一律以这份并集为准 ⇒ 点标签、回车录入都是「往已有内容上并入」，
  /// 不会因为输入框被清空而把先前录好的标签弄丢。
  List<String> _mergedTags(String code) {
    final List<String> merged = <String>[];
    for (final String tag in <String>[
      ..._splitTags(_rows[code]?.title ?? ''),
      ..._splitTags(_controllers[code]?.text ?? ''),
    ]) {
      if (!merged.contains(tag)) {
        merged.add(tag);
      }
    }
    return merged;
  }

  /// 点标签：并入该项的多值文本 ⇒ **立即落库**（B12：不再有「保存」按钮）。
  Future<void> _pickTag(String code, String tag) async {
    final TextEditingController? controller = _controllers[code];
    if (controller == null) {
      return;
    }
    final List<String> merged = _mergedTags(code);
    if (!merged.contains(tag)) {
      merged.add(tag);
    }
    final String text = merged.join('、');
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      // 文本变了，上一次的「已保存」不再成立。
      _savedCode = null;
      _failedCode = null;
      _error = null;
    });
    // 浮层是独立于面板的 `OverlayEntry`：要手动刷新才能把 chip 切成「已选中」。
    _tagsOverlay?.markNeedsBuild();
    final _PositionItem? item = _itemFor(code);
    if (item == null) {
      return;
    }
    await _save(item);
  }

  /// 回车录入：输入框里的文字拆成多个标签 ⇒ 并入多值文本 ⇒ **自动落库**。
  ///
  /// 空文本回车**不写库**。
  Future<void> _submitTags(_PositionItem item) async {
    final String code = item.code;
    final TextEditingController? controller = _controllers[code];
    if (controller == null) {
      return;
    }
    final String raw = controller.text.trim();
    if (raw.isEmpty) {
      // 空文本回车：不写库（也不动已落库的值）。
      return;
    }
    final List<String> merged = _mergedTags(code);
    final String text = merged.join('、');
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    await _save(item, clearInput: true);
  }

  /// 某个标签是否已经在该项的多值文本里（用于「已选中」高亮）。
  bool _hasTag(String code, String tag) => _mergedTags(code).contains(tag);

  /// 开标签库浮层（**锚在输入框自身**，不跟鼠标）。
  ///
  /// 入口有三个：鼠标悬停输入框、点击输入框、输入框获得焦点。
  ///
  /// [pinned] 为 true ⇒ 钉住态（点击 / 聚焦打开），不参与 3 秒自动隐藏计时。
  void _openTags(String code, {bool pinned = false}) {
    final AppLocalizations t = AppLocalizations.of(context);
    final List<String> tags = _tagsFor(t, code);
    if (tags.isEmpty) {
      return;
    }

    // 说明浮层与标签浮层不叠着：开标签浮层时先把说明浮层摘掉。
    _removeHintOverlay();

    final OverlayEntry? existing = _tagsOverlay;
    if (existing != null) {
      if (_tagsCode == code) {
        // 同一 code：只刷新，**绝不叠加第二个 OverlayEntry**。
        _cancelTagsHide();
        if (pinned) {
          // 点击 / 聚焦可以把已开着的浮层升级成钉住态。
          _tagsPinned = true;
        }
        _tagsAnchorRect = _computeAnchorRect(_anchorKeys[code]!);
        existing.markNeedsBuild();
        return;
      }
      _removeTagsOverlay();
    }

    final ThemeTokens tokens = context.tokens;
    // 锚点矩形在布局期之外先量好（布局期读 RenderBox.size 会触发断言）。
    _tagsAnchorRect = _computeAnchorRect(_anchorKeys[code]!);
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext _) => _TagsBubble(
        t: t,
        tokens: tokens,
        anchorRect: _tagsAnchorRect,
        bubbleKey: _tagsBubbleKey,
        code: code,
        tags: tags,
        isSelected: (String tag) => _hasTag(code, tag),
        onPick: (String tag) => _pickTag(code, tag),
        onEnter: _cancelTagsHide,
        onExit: _scheduleTagsHide,
      ),
    );
    _tagsCode = code;
    _tagsPinned = pinned;
    _tagsOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    _attachHooks();
    // 首帧锚点可能还没量准（面板刚出现）：帧后再校一次。
    _scheduleAnchorRefresh();
  }

  /// 算锚点矩形（相对 root overlay 原点）；**只能在布局期之外调用**。
  Rect? _computeAnchorRect(GlobalKey key) {
    final RenderObject? anchor = key.currentContext?.findRenderObject();
    final RenderObject? overlay = Overlay.maybeOf(
      context,
      rootOverlay: true,
    )?.context.findRenderObject();
    if (anchor is! RenderBox || !anchor.hasSize) {
      return null;
    }
    if (overlay is! RenderBox || !overlay.hasSize) {
      return null;
    }
    final Offset anchorOrigin = anchor.localToGlobal(Offset.zero);
    final Offset overlayOrigin = overlay.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      anchorOrigin.dx - overlayOrigin.dx,
      anchorOrigin.dy - overlayOrigin.dy,
      anchor.size.width,
      anchor.size.height,
    );
  }

  /// 帧后重算锚点矩形（滚动 / 文本变长后，输入框位置会变）。
  void _scheduleAnchorRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      _refreshAnchorRect();
    });
  }

  /// 重算锚点矩形；变了才重建浮层（幂等）。
  void _refreshAnchorRect() {
    final String? code = _tagsCode;
    if (code == null || _tagsOverlay == null) {
      return;
    }
    final Rect? rect = _computeAnchorRect(_anchorKeys[code]!);
    if (rect == null || rect == _tagsAnchorRect) {
      return;
    }
    _tagsAnchorRect = rect;
    _tagsOverlay?.markNeedsBuild();
  }

  /// 离开输入框 / 离开浮层：重新起 3 秒计时（钉住态不计时）。
  void _scheduleTagsHide() {
    _cancelTagsHide();
    if (_tagsPinned) {
      return;
    }
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
    _detachHooks();
    _tagsOverlay?.remove();
    _tagsOverlay = null;
    _tagsCode = null;
    _tagsPinned = false;
    _tagsAnchorRect = null;
  }

  /// 输入框焦点变化：**获得焦点即开标签库**（钉住态，输入时不自动消失）。
  ///
  /// B12 删掉了「标签库」开关，点击 / 聚焦输入框就是新的入口。
  void _onFocusChanged(String code) {
    if (!mounted) {
      return;
    }
    final FocusNode? node = _focusNodes[code];
    if (node == null || !node.hasFocus) {
      return;
    }
    final _PositionItem? item = _itemFor(code);
    if (item == null) {
      return;
    }
    _openTags(code, pinned: true);
  }

  /// code → 该项渲染数据（找不到返回 null）。
  _PositionItem? _itemFor(String code) {
    for (final _PositionItem item in _items(AppLocalizations.of(context))) {
      if (item.code == code) {
        return item;
      }
    }
    return null;
  }

  /// 悬停标题 ⇒ 开说明浮层（自绘，锚在标题附近）。
  ///
  /// 说明**不常驻**：只在指针停在标题上时出现；同一时刻最多一个。
  void _openHint(_PositionItem item) {
    _cancelHintHide();
    final Rect? rect = _computeAnchorRect(_titleKeys[item.code]!);
    final OverlayEntry? existing = _hintOverlay;
    if (existing != null && _hintCode == item.code) {
      // 同一项：只刷新锚点，**绝不叠加第二个 OverlayEntry**。
      _hintAnchorRect = rect;
      existing.markNeedsBuild();
      return;
    }
    if (existing != null) {
      _removeHintOverlay();
    }
    _hintAnchorRect = rect;
    final ThemeTokens tokens = context.tokens;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext _) => _HintBubble(
        text: item.hint,
        tokens: tokens,
        anchorRect: _hintAnchorRect,
        onEnter: _cancelHintHide,
        onExit: _scheduleHintHide,
      ),
    );
    _hintCode = item.code;
    _hintOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// 离开标题 / 离开说明浮层：短暂延迟后消失（留出「移到浮层上」的时间）。
  void _scheduleHintHide() {
    _cancelHintHide();
    // 220ms：够指针从标题移到浮层而不闪断，又不至于赖在屏幕上。
    _hintTimer = Timer(const Duration(milliseconds: 220), _removeHintOverlay);
  }

  /// 取消说明浮层的消失计时（指针进入浮层或回到标题）。
  void _cancelHintHide() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  /// 摘掉说明浮层并停表（幂等；`dispose` 里也走这条）。
  void _removeHintOverlay() {
    _cancelHintHide();
    _hintOverlay?.remove();
    _hintOverlay = null;
    _hintCode = null;
    _hintAnchorRect = null;
  }

  /// 挂上「Esc 关闭」与「点外部关闭」两套钩子。
  void _attachHooks() {
    if (!_keyboardHooked) {
      HardwareKeyboard.instance.addHandler(_onKeyEvent);
      _keyboardHooked = true;
    }
    if (!_pointerHooked) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_pointerRoute);
      _pointerHooked = true;
    }
  }

  /// 摘掉两套钩子（幂等：`removeGlobalRoute` 重复摘除会触发断言）。
  void _detachHooks() {
    if (_keyboardHooked) {
      HardwareKeyboard.instance.removeHandler(_onKeyEvent);
      _keyboardHooked = false;
    }
    if (_pointerHooked) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointerRoute);
      _pointerHooked = false;
    }
  }

  /// Esc ⇒ 关闭浮层（不抢焦点，hover 打开时也不打断输入）。
  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    if (_tagsOverlay == null) {
      return false;
    }
    _removeTagsOverlay();
    return true;
  }

  /// 点浮层外部 ⇒ 关闭（点输入框不算外部：点完会由焦点 / onTap 重新打开）。
  void _onPointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }
    if (_tagsOverlay == null) {
      return;
    }
    if (_hitsKey(_tagsBubbleKey, event.position)) {
      return;
    }
    _removeTagsOverlay();
  }

  /// 指针是否落在某个键对应的控件里（全局坐标）。
  bool _hitsKey(GlobalKey key, Offset globalPosition) {
    final BuildContext? ctx = key.currentContext;
    if (ctx == null) {
      return false;
    }
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) {
      return false;
    }
    final Rect rect = ro.localToGlobal(Offset.zero) & ro.size;
    return rect.contains(globalPosition);
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

    // 面板在滚动容器里：滚动时重算浮层锚点，浮层才不会跟输入框脱节。
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          // 锚点会随滚动移动：帧后重算（滚动通知可能在布局期发出，不能直接读 RenderBox）。
          _scheduleAnchorRefresh();
        }
        return false;
      },
      child: Container(
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
            // 宽视口：四问并成 1×4 单行（A 稿骨架），列间用 1px 竖线分隔；
            // 窄视口保留原来的纵向堆叠 —— 键位、浮窗、保存逻辑两条分支完全一致。
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth < _inlineBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: blocks,
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (int i = 0; i < items.length; i++)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: i == 0
                                ? null
                                : Border(
                                    left: BorderSide(
                                      color: tokens.hair,
                                      width: 1,
                                    ),
                                  ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0.0 : 12.0,
                              right: i == items.length - 1 ? 0.0 : 12.0,
                            ),
                            child: _buildItem(items[i], tokens),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 一项：标题（悬停出说明浮层）+ 多行输入框 + 状态行。
  ///
  /// B12：**没有「保存」按钮、也没有「标签库」开关** —— 保存由「点标签」或
  /// 「回车」触发，标签库由「点 / 聚焦输入框」触发；说明文字不再常驻，
  /// 改成悬停标题时弹出的自绘浮层。
  Widget _buildItem(_PositionItem item, ThemeTokens tokens) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String code = item.code;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // 说明浮层的锚点就是标题自身；`SizedBox` 只为拿到它的 `RenderBox`。
          MouseRegion(
            onEnter: (PointerEnterEvent event) => _openHint(item),
            onHover: (PointerHoverEvent event) => _cancelHintHide(),
            onExit: (PointerExitEvent event) => _scheduleHintHide(),
            child: SizedBox(
              key: _titleKeys[code],
              child: Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: tokens.ink),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildInput(item),
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
  ///
  /// B12 入口：**点击 / 聚焦输入框即展开标签库**（钉住态，输入时不消失）；
  /// 回车（`onSubmitted`）把文字拆成标签并入多值文本后立即落库。
  ///
  /// 整体压缩：单行起步（最多 4 行）、`isDense`、收紧内边距与行高 ——
  /// 长文本照常换行并把框撑高，不裁切、不溢出。
  Widget _buildInput(_PositionItem item) {
    final TextField field = TextField(
      key: ValueKey<String>('goal-position-input-${item.code}'),
      controller: _controllers[item.code],
      focusNode: _focusNodes[item.code],
      minLines: 1,
      maxLines: 4,
      onTap: () => _openTags(item.code, pinned: true),
      onSubmitted: (String _) => _submitTags(item),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(height: 1.35),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
    final Widget anchored = SizedBox(key: _anchorKeys[item.code], child: field);
    if (item.tags.isEmpty) {
      return anchored;
    }
    return MouseRegion(
      onEnter: (PointerEnterEvent event) => _openTags(item.code),
      onHover: (PointerHoverEvent event) => _cancelTagsHide(),
      onExit: (PointerExitEvent event) => _scheduleTagsHide(),
      child: anchored,
    );
  }

  /// 次级文字样式。
  TextStyle? _metaStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(color: context.tokens.meta);
}

/// 说明浮层：悬停定位分类标题时出现，锚在标题**上方**。
///
/// 只占自身盒子大小（**不** `SizedBox.expand`）⇒ 命中测试不会扩到整块
/// overlay，指针照常落到下面的输入框上（B12 硬要求：浮层不得遮挡输入）。
class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.text,
    required this.tokens,
    required this.anchorRect,
    required this.onEnter,
    required this.onExit,
  });

  /// 该条的说明文字。
  final String text;

  /// 配色令牌（只走 LightPalette 的 card / ink2 / hair）。
  final ThemeTokens tokens;

  /// 锚点（标题）矩形，相对 root overlay 原点；null = 还没量到。
  final Rect? anchorRect;

  /// 指针进入浮层：取消消失计时（不闪断）。
  final VoidCallback onEnter;

  /// 指针离开浮层：重新起计时。
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.ink2, height: 1.4);
    return CustomSingleChildLayout(
      delegate: _HintLayout(anchorRect: anchorRect),
      child: MouseRegion(
        onEnter: (PointerEnterEvent event) => onEnter(),
        onExit: (PointerExitEvent event) => onExit(),
        child: Container(
          key: const ValueKey<String>('goal-position-hint-overlay'),
          width: _hintMaxWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: tokens.hair, width: 1),
          ),
          child: Text(text, style: style),
        ),
      ),
    );
  }
}

/// 把说明浮层钉在**标题上方**（上方放不下就夹在窗口内：宁压标题、不压输入框）。
///
/// 锚点矩形在布局期之外算好（见 `_GoalPositionPanelState._computeAnchorRect`），
/// 布局期只读这个纯值 —— 布局期读 `RenderBox.size` 会触发 Flutter 断言。
class _HintLayout extends SingleChildLayoutDelegate {
  const _HintLayout({required this.anchorRect});

  /// 锚点（标题）矩形，相对 overlay 原点；null = 还没量到。
  final Rect? anchorRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final Rect? anchor = anchorRect;
    final double maxWidth = math.max(
      0,
      math.min(_hintMaxWidth, constraints.maxWidth - 16),
    );
    // 高度上限 = 标题上方到窗口上沿的可用高度 ⇒ 浮层永远进不到输入框区域。
    final double above = anchor == null
        ? constraints.maxHeight - 16
        : anchor.top - _tagsGap - _tagsEdge;
    // 上方空间太小（< 24）就别硬压：退回整窗高度，让文本自身折行。
    final double maxHeight = above >= 24
        ? math.min(constraints.maxHeight - 16, above)
        : constraints.maxHeight - 16;
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = math.max(
      _tagsEdge,
      size.width - childSize.width - _tagsEdge,
    );
    final Rect? anchor = anchorRect;
    if (anchor == null) {
      return const Offset(_tagsEdge, _tagsEdge);
    }
    final double y = math.max(
      _tagsEdge,
      anchor.top - _tagsGap - childSize.height,
    );
    final double x = math.max(_tagsEdge, math.min(anchor.left, maxX));
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_HintLayout oldDelegate) =>
      // 锚点随滚动移动 ⇒ 每次都重算（浮层只有一个短句，成本可忽略）。
      true;
}

/// 标签浮层：标题 + chip 流式换行；自己进入取消计时、离开重新计时。
class _TagsBubble extends StatelessWidget {
  const _TagsBubble({
    required this.t,
    required this.tokens,
    required this.anchorRect,
    required this.bubbleKey,
    required this.code,
    required this.tags,
    required this.isSelected,
    required this.onPick,
    required this.onEnter,
    required this.onExit,
  });

  final AppLocalizations t;
  final ThemeTokens tokens;

  /// 锚点（输入框）矩形，相对 root overlay 原点；null = 还没量到。
  ///
  /// 纯值：布局期直接消费，不碰 `RenderBox`。
  final Rect? anchorRect;

  /// 浮层根的键（判定「点的是不是浮层内部」）。
  final GlobalKey bubbleKey;

  final String code;
  final List<String> tags;

  /// 某个标签是否已被写进输入框（决定「已选中」高亮）。
  final bool Function(String tag) isSelected;

  final void Function(String tag) onPick;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final TextStyle? chipStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: tokens.ink);
    // `SizedBox.expand`：让布局 delegate 拿到整块 overlay 区域 —— 浮层才能贴到
    // 输入框下方的任意位置（父盒若只有浮层那么大，命中测试会落空，标签就点不到）。
    return SizedBox.expand(
      child: CustomSingleChildLayout(
        delegate: _TagsLayout(anchorRect: anchorRect),
        child: MouseRegion(
          key: bubbleKey,
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
      ),
    );
  }

  Widget _chip(int index, String tag, TextStyle? style) {
    final bool selected = isSelected(tag);
    return GestureDetector(
      key: ValueKey<String>('goal-position-tag-$code-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onPick(tag),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          key: ValueKey<String>('goal-position-tag-chip-$code-$index'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? tokens.inkWash : null,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: selected ? tokens.ink : tokens.hairSoft,
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: selected ? style?.copyWith(fontWeight: FontWeight.w600) : style,
          ),
        ),
      ),
    );
  }
}

/// 把浮层钉在**输入框自身**下方（下方放不下就翻到上方），并夹在窗口内。
///
/// 锚点矩形在**布局期之外**算好（见 `_GoalPositionPanelState._computeAnchorRect`），
/// 布局期只读这个纯值 —— 布局期读 `RenderBox.size` 会触发 Flutter 断言
/// （「size accessed beyond the scope of resize, layout」）。
class _TagsLayout extends SingleChildLayoutDelegate {
  const _TagsLayout({required this.anchorRect});

  /// 锚点（输入框）矩形，相对 overlay 原点；null = 还没量到。
  final Rect? anchorRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final double maxWidth = math.max(
      0,
      math.min(_tagsMaxWidth, constraints.maxWidth - 16),
    );
    final double maxHeight = math.max(0, constraints.maxHeight - 16);
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = math.max(_tagsEdge, size.width - childSize.width - _tagsEdge);
    final double maxY = math.max(_tagsEdge, size.height - childSize.height - _tagsEdge);
    final Rect? anchor = anchorRect;
    if (anchor == null) {
      return const Offset(_tagsEdge, _tagsEdge);
    }
    // 下方优先；下方放不下就翻到上方；两边都放不下才夹回窗口内。
    final double below = anchor.bottom + _tagsGap;
    final double above = anchor.top - _tagsGap - childSize.height;
    final double y;
    if (below + childSize.height <= size.height - _tagsEdge) {
      y = below;
    } else if (above >= _tagsEdge) {
      y = above;
    } else {
      y = math.max(_tagsEdge, math.min(below, maxY));
    }
    final double x = math.max(_tagsEdge, math.min(anchor.left, maxX));
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TagsLayout oldDelegate) =>
      // 锚点会随滚动移动 ⇒ 每次都重算位置（浮层小，重排成本可忽略）。
      true;
}
