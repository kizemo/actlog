// =============================================================================
// 目标 · 人生蓝图矩阵（Task 66 UI 半批 B2 → B9-W2 标签页改造 → B10-B 增强）
// =============================================================================
// 口径（计划 §5.4 + B9 裁决 D-9 + B10 棒 B）：
//  1. 主视图 = **4 个标签页（终极 / 远期 / 中期 / 短期），默认终极**；一次只渲染
//     当前档位那一张表 —— **6 行（domain）× 3 列（领域 | 目标 | 日期）**，
//     不渲染表头行。目标格里显示 `title` 一行 + `keywords` 标签 + 做法条数；
//     点标题展开三层（目标 → 关键词 → 做法）。
//  2. **标签页 = Chrome/Edge 浏览器标签**（B12 第 2 条，用户给的参照物）：
//     标签条底 = 纸（`tokens.paper`）；**活动标签 = 浅洗底（`tokens.inkWash`）**
//     + 顶部 3px 实色指示条 ⇒ 靠「底色差 + 指示条」标出当前档；非活动标签 =
//     下沉色（`tokens.sunken`，偏灰）。B17-A：四档**两态等高**
//     （[GoalBlueprintMatrix.tabHeight]），标签之间留 8px 间距
//     （[GoalBlueprintMatrix.tabGap]）、间距正中 1px hairline 分隔。
//     顶部圆角 8px（[GoalBlueprintMatrix.chromeTabTopRadius]）
//     是本轮**唯一**超出 `AppTokens.radius`（4px）的例外，其余圆角/配色一律走
//     `theme_tokens.dart` 的 `LightPalette`。四档都用 `Tooltip` 悬停显示时长
//     （B10-B2，文案来自 `t.` getter）。
//  3. **短期页 = 原「短期」列 + 原「近期（1 年）」列**：near 蓝图与本年度 yearly 目标
//     都由页面侧并入 `GoalHorizon.short` 那一格（与年页**同一份数据源**
//     `GoalYearView.yearlyGoals`，保证单一真源）。
//  4. **链断裂可视化已下线**（B12 第 3 条）：格内**不再**渲染「条做法 N」与
//     「未落位」（key `goal-blueprint-unplaced-<id>` 一并撤掉）；`serves` 仍用于
//     展开层里列周目标子级，`tracksCount` 仍作为构造参数保留（不再渲染）。
//  5. **空格合法**：矩阵不校验、不强制、不给红字（计划 §5.4 末句）；空格子的唯一
//     入口是右下角「+」（不渲染「（空）」）。
//  6. **编辑入口**：`onAddGoal` / `onEditGoal` / `onDeleteGoal` / `onToggleGoalDone` /
//     `onEditGoalPeriod` 五个回调全部**可选**（默认 null）。不传时本矩阵的渲染与
//     既有调用点逐字一致（AGENTS §5 坑 48：新增参数不得改变既有调用点的行为）。
//     * B10-B3：勾选框（`goal-blueprint-done-<id>`）只在传了 `onToggleGoalDone` 时渲染；
//       归档时刻由 `GoalStore.updateGoal` 按 `status` 派生，本组件不写库。
//     * B10-B4：日期列（`yyyy-MM-dd ~ yyyy-MM-dd`，缺值 `—`，已完成追加完成日）；
//       起止日期是**日期型**字段，但库里的「午夜」有两种语义（蓝图目标 = 本地午夜毫秒
//       ⇒ 按本地时区显示；年/月/周目标 = `GoalPeriod` 的 UTC 午夜毫秒 ⇒ 按 UTC 显示，
//       分流理由见 `_periodText`），
//       而「完成：」取 `archivedAt` 这个**时刻**（⇒ 按本地时区显示，`_momentText`），
//       否则东八区 00:00–08:00 勾完成会显示成前一天；
//       B17 第 B 条：改期的**唯一**入口是日期文本自身（`goal-blueprint-period-tap-<id>`），
//       只在传了 `onEditGoalPeriod` 时渲染，且只管**蓝图目标**（年目标在本页改周期
//       会与年页口径打架）；原先并排的「日期」图标按钮（`goal-blueprint-period-<id>`）
//       已删除 —— 它和日期文本指向同一个对话框，属于重复入口。
//     * B12 第 3 条：**起止缺省时回退显示期限**（`dueDate`，本地午夜毫秒 ⇒ 按本地
//       时区取日）。表单写的是 `due_date`、第三列读的是 `period_*` —— 两侧来源
//       不一致才是「填了日期第三列不显示」的根因；页面侧同步写 `period_end`，
//       矩阵侧再兜底显示 `due_date` ⇒ 新旧数据都能在第三列看到日期。
//
// 本模块使用 3 个 Material 图标，一律 `*_outlined` 系（AGENTS.md 例外清单以外
// 不自造；坑 105）：`Icons.edit_outlined`（改目标）、`Icons.call_split`（拆待办）、
// `Icons.delete_outline`（删除目标；B18 第 2 条把文字按钮改成图标）。
// B13 第 3 条曾把「起止日期」文字入口换成 `Icons.date_range_outlined`；B17 第 B 条
// 判定它与日期文本重复，图标按钮连同其 Tooltip 一并下线（改期仍由日期文本承担）。
// 「+」仍用文字符号（坑 51：桌面测试不预载 MaterialIcons 字体）。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/goal_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_tokens.dart';
import 'goal_year_matrix.dart';

/// 蓝图矩阵的一行（一个领域）。
class GoalBlueprintRow {
  /// 构造。
  const GoalBlueprintRow({required this.domainKey, required this.cells});

  /// 领域 key（Task 59 六 key）。
  final String domainKey;

  /// 档位 → 该格的目标。
  final Map<GoalHorizon, List<GoalRow>> cells;
}

/// 人生蓝图矩阵（6 行 × 3 列，4 个档位标签页）。
class GoalBlueprintMatrix extends StatefulWidget {
  /// 创建矩阵。
  const GoalBlueprintMatrix({
    required this.t,
    required this.rows,
    required this.serves,
    required this.tracksCount,
    required this.onSplitTodos,
    this.onAddGoal,
    this.onEditGoal,
    this.onDeleteGoal,
    this.onToggleGoalDone,
    this.onEditGoalPeriod,
    this.onRenameGoal,
    this.onCreateGoalInline,
    super.key,
  });

  /// 文案表。
  final AppLocalizations t;

  /// 矩阵行（每个领域一行）。
  final List<GoalBlueprintRow> rows;

  /// `serves` 双向索引（用来向下探下级目标）。
  final GoalServesIndex serves;

  /// 目标 id → `tracks` 执行实体条数（做法条数）。
  ///
  /// B12 第 3 条起**不再渲染**「条做法 N」；参数保留（既有调用点逐字不动）。
  final Map<String, int> tracksCount;

  /// 拆分回调（B9-W3：打开拆分层级对话框，**确认即落库**；D-9-e 已废止
  /// 旧的「拆成 3 条待办 → 页内待确认队列」两段式链路）。
  final void Function(GoalRow goal) onSplitTodos;

  /// 空格子里的「+ 新建目标」回调（领域 + 所在档位由格子带入）。
  ///
  /// null = **不渲染**这个入口（坑 48：默认行为与 Task 66 逐字一致）。
  final void Function(String domainKey, GoalHorizon horizon)? onAddGoal;

  /// 格内「+」的就地新建回调（B16 第 1/2 条）：`domainKey` + `horizon` 定位格子，
  /// `title` 是用户刚敲下的标题。**不弹表单**，其余字段留默认。
  ///
  /// 传了它 ⇒ 空格与**已填格**的「+」都常驻渲染（保存后仍可继续加下一条）；
  /// null ⇒ 已填格不渲染「+」、空格照旧走 [onAddGoal] 的旧入口（坑 48）。
  final void Function(String domainKey, GoalHorizon horizon, String title)?
      onCreateGoalInline;

  /// 目标卡片上的「编辑」回调。
  ///
  /// null = 不渲染（同上）。
  final void Function(GoalRow goal)? onEditGoal;

  /// 目标卡片上的「删除」回调（调用方负责二次确认）。
  ///
  /// null = 不渲染（同上）。
  final void Function(GoalRow goal)? onDeleteGoal;

  /// 勾选 / 取消「完成」（B10-B3）。
  ///
  /// 调用方只传 `status`，`archived_at` 由 `GoalStore.updateGoal` 内部派生。
  /// null = **不渲染**勾选框（坑 48）。
  final void Function(GoalRow goal, bool done)? onToggleGoalDone;

  /// 改起止日期（B10-B4）：`startMs == 0` ⇒ 清空起始，`endMs == null` ⇒ 无终点。
  ///
  /// null = 不渲染日期列的改期按钮（同上）。
  final void Function(GoalRow goal, int startMs, int? endMs)? onEditGoalPeriod;

  /// 就地改名（B14 第 2 条）：点铅笔 → 格内出现输入框 → 提交只写 `title`。
  ///
  /// `title` 已 trim、且调用前已保证**非空且与旧值不同**。
  /// null ⇒ 铅笔退回 [onEditGoal] 的全量弹窗（坑 48：既有调用点逐字不变）。
  final void Function(GoalRow goal, String title)? onRenameGoal;

  /// 档位顺序（终极 → 近期）。
  ///
  /// 注意：**5 档**，供目标表单的档位下拉用（`goal_form_dialog.dart`）。
  /// 标签页只用 [tabs]（4 档，近期并入短期）。
  static List<GoalHorizon> get horizons =>
      GoalHorizon.values.toList()
        ..sort((GoalHorizon a, GoalHorizon b) => a.value.compareTo(b.value));

  /// 标签页顺序（终极 → 远期 → 中期 → 短期），默认取第一个。
  static const List<GoalHorizon> tabs = <GoalHorizon>[
    GoalHorizon.ultimate,
    GoalHorizon.long,
    GoalHorizon.mid,
    GoalHorizon.short,
  ];

  /// **Chrome/Edge 标签风格参照，唯一超出 `AppTokens.radius`（4px）的例外。**
  ///
  /// 只用于标签的**顶部**两角（浏览器标签的标志性轮廓）；其余圆角与全部配色
  /// 一律走 `theme_tokens.dart` 的 `LightPalette`（`ThemeTokens`）。
  static const double chromeTabTopRadius = 8;

  /// 标签页高度（px）—— **活动态与非活动态同高**（B17 任务 A）。
  ///
  /// 沿革：B13 第 2 条 34 / 28；B16 第 3 条 46 / 39（刻意保留 7px 落差）；
  /// B17 任务 A 用户要求「页签加宽 + 两态等高」⇒ 收敛成**单一**常量 46px，
  /// 两态不再有落差，页签条上下沿齐平（原先「非活动标签下沉」的台阶消失）。
  static const double tabHeight = 46;

  /// 标签之间的水平间距（px，B17 任务 A）。
  ///
  /// 页签条按 [tabGap] 排布；1px hairline 分隔线**居中**于这个间距
  /// （槽宽 [tabGap]，线宽 1px，两侧各留 3.5px）。
  static const double tabGap = 8;

  /// 标签页**垂直**内边距（px，B16 第 3 条）。
  ///
  /// B13 只靠 `minimumSize` 撑高、`padding` 不加 `vertical`；B16 用户要求
  /// 「页签加大垂直内边距（文字不拥挤）」⇒ 上下各 4px 由 `padding` 显式给，
  /// 字号 / 水平内边距 / 指示条宽度一律不动（`b14_tab_scale_test` 的
  /// 760 宽 11px 红线余量只与水平方向有关，不受这 8px 影响）。
  static const double tabVerticalPadding = 4;

  /// 档位标签字号（px）。
  ///
  /// B13 第 2 条。**为什么不能走主题槽位**：`labelLarge.fontSize` 由
  /// `DensityProfile` 三档密度决定（12 / 12.5 / 13.5），而档位标签是本页的顶层
  /// 导航，需在三档密度下保持同一视觉权重 ⇒ 显式钉死 15。
  static const double _tabFontSize = 15;

  /// 档位标签水平内边距（px）。
  ///
  /// 沿革：B13 第 2 条 10 → 18（字变大后需要更松的内边距）；B14（stage 4 ·
  /// A1）18 → 10（760 宽英文态 11px 红线余量 ≥ 1.00px 的硬约束）；
  /// **B17 任务 A：10 → 16**（用户要求「页签加宽」）。
  ///
  /// 红线口径不变：`b14_tab_scale_test.dart` 仍按「显示字号 ≥ 12.00px、
  /// 余量 ≥ 1.00px」判 760 宽英文态；英文文案已由 W0 缩为
  /// `Short-term` / `Mid-term` / `Long-term` / `Ultimate`，本常量只调松紧、
  /// **不得**为过判据而回调红线数字。
  ///
  /// 写成命名常量以满足 §2 E4「不新增魔法数」。
  static const double _tabPadding = 16;

  /// 单元格内边距：垂直 11px、水平 8px。
  ///
  /// B12 第 2 条（用户反馈「表格中的内容，适当增加上下边距」）：原先四边各 4px
  /// 太挤；列宽比例（2 / 5 / 3）不变，窄视口不溢出。
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 11,
  );

  /// 活动标签顶部实色条高度（px，B14 第 3 条）。
  ///
  /// 选中态不能再靠「底色 = 内容区底色」表达（那会让标签与表格融为一体、
  /// 看不出选中），改成「淡染底 + 顶部 3px 实色条」。
  static const double tabIndicatorHeight = 3;

  /// 三列宽度比例（领域 : 目标 : 起止），B14 第 2 条显式钉死。
  ///
  /// 起止列 3 → 4：`yyyy-MM-dd ~ yyyy-MM-dd` 是 23 个字符，3 份宽在
  /// 760px 视口下必须缩字才能整行放下；4 份宽给足空间，配合 [cellPadding]
  /// 与日期的 `FittedBox` 兜底 ⇒ 常态不缩字、极窄视口也不折行。
  static const double columnFlexDomain = 2;

  /// 目标列占比（见 [columnFlexDomain]）。
  static const double columnFlexGoal = 5;

  /// 起止列占比（见 [columnFlexDomain]）。
  static const double columnFlexPeriod = 4;

  /// 年刻度条与主表**共用**的列宽；抽成一处，避免两张表比例漂移。
  static const Map<int, TableColumnWidth> columnWidths =
      <int, TableColumnWidth>{
        0: FlexColumnWidth(columnFlexDomain),
        1: FlexColumnWidth(columnFlexGoal),
        2: FlexColumnWidth(columnFlexPeriod),
      };

  @override
  State<GoalBlueprintMatrix> createState() => _GoalBlueprintMatrixState();
}

class _GoalBlueprintMatrixState extends State<GoalBlueprintMatrix> {
  /// 展开三层的目标 id 集合。
  final Set<String> _expanded = <String>{};

  /// 当前选中的档位标签页（默认「终极」）。
  GoalHorizon _selected = GoalBlueprintMatrix.tabs.first;

  void _toggle(String goalId) {
    setState(() {
      if (!_expanded.remove(goalId)) {
        _expanded.add(goalId);
      }
    });
  }

  /// 就地编辑中的目标 id（null = 没有在编辑）。
  ///
  /// B14 第 2 条：**同一时刻只允许一条**在编辑 —— 单份控制器 + 单份焦点节点，
  /// 避免 6 行 × 多目标的格子里堆一屏 `TextEditingController`。
  String? _editingGoalId;

  /// 就地编辑输入框的控制器（State 生命周期内复用一份）。
  final TextEditingController _inline = TextEditingController();

  /// 就地编辑的焦点节点：失焦即提交（点空白/切页签/点别的格子都能收口）。
  final FocusNode _inlineFocus = FocusNode();

  /// 就地新建中的格子（B16 第 1/2 条；null = 没有在新建）。
  ///
  /// `domain` + `horizon` 唯一确定一个格子（同一时刻只允许一格在新建）。
  String? _creatingDomainKey;
  GoalHorizon? _creatingHorizon;

  /// 就地新建输入框的控制器（与改名控制器分开：两条链路的落库语义不同）。
  final TextEditingController _create = TextEditingController();

  /// 就地新建的焦点节点：失焦即提交（点空白/点其它「+」都能收口）。
  final FocusNode _createFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _inlineFocus.addListener(_onInlineFocusChanged);
    _createFocus.addListener(_onCreateFocusChanged);
  }

  @override
  void dispose() {
    _inlineFocus.removeListener(_onInlineFocusChanged);
    _inlineFocus.dispose();
    _createFocus.removeListener(_onCreateFocusChanged);
    _createFocus.dispose();
    _inline.dispose();
    _create.dispose();
    super.dispose();
  }

  /// 失焦 ⇒ 提交（不丢用户刚敲的字；语义等同点空白确认）。
  void _onInlineFocusChanged() {
    if (_inlineFocus.hasFocus) {
      return;
    }
    _commitInline();
  }

  /// 进入就地编辑：预填旧标题，**光标置末**（不抢全选，避免误删整条标题）。
  void _startInline(GoalRow goal) {
    if (widget.onRenameGoal == null) {
      // 没传改名回调 ⇒ 保持旧行为：打开全量表单弹窗（坑 48）。
      widget.onEditGoal?.call(goal);
      return;
    }
    _inline.text = goal.title;
    _inline.selection = TextSelection.collapsed(offset: goal.title.length);
    setState(() => _editingGoalId = goal.id);
  }

  /// 提交就地编辑：只把**标题**交给调用方，其余字段一律不碰。
  ///
  /// 为什么不经页面侧的表单落库：`_writeGoal` 会重算 `period_end` 并按
  /// `clear` 集合清空 note/keywords —— 改个错别字不该有这种副作用。
  void _commitInline() {
    if (!mounted) {
      return;
    }
    final String? id = _editingGoalId;
    if (id == null) {
      return;
    }
    final GoalRow? goal = _goalById(id);
    final String next = _inline.text.trim();
    setState(() => _editingGoalId = null);
    if (goal == null || next.isEmpty || next == goal.title) {
      return;
    }
    widget.onRenameGoal?.call(goal, next);
  }

  /// 放弃就地编辑（Esc）：不写库、不改数据。
  void _cancelInline() {
    if (_editingGoalId == null || !mounted) {
      return;
    }
    setState(() => _editingGoalId = null);
  }

  /// 回车提交；**IME 组合态（拼音还在候选窗里）回车是上屏，不是提交**。
  void _onInlineSubmitted(String _) {
    final TextEditingValue value = _inline.value;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return;
    }
    _commitInline();
  }

  /// 当前档位里按 id 找目标（就地编辑提交时取旧标题做比较）。
  GoalRow? _goalById(String id) {
    for (final GoalBlueprintRow row in widget.rows) {
      for (final GoalRow goal in row.cells[_selected] ?? const <GoalRow>[]) {
        if (goal.id == id) {
          return goal;
        }
      }
    }
    return null;
  }

  /// 进入就地新建（B16 第 1/2 条）：格内直接出输入框，**不弹表单**。
  ///
  /// `onCreateGoalInline` 为 null ⇒ 保持旧行为：把点击交给 `onAddGoal`
  /// 打开弹窗（坑 48：既有调用点逐字不变）。
  void _startCreate(String domainKey, GoalHorizon horizon) {
    if (widget.onCreateGoalInline == null) {
      widget.onAddGoal?.call(domainKey, horizon);
      return;
    }
    _create.clear();
    setState(() {
      // 同屏只留一个输入框：改名链路先收口（提交由失焦监听负责）。
      _editingGoalId = null;
      _creatingDomainKey = domainKey;
      _creatingHorizon = horizon;
    });
  }

  /// 提交就地新建：只交「领域 + 档位 + 标题」，其余字段由页面/store 取默认。
  ///
  /// 空标题 = 用户放弃 ⇒ 不落库（空格子合法，矩阵不校验、不给红字）。
  void _commitCreate() {
    if (!mounted) {
      return;
    }
    final String? domainKey = _creatingDomainKey;
    final GoalHorizon? horizon = _creatingHorizon;
    if (domainKey == null || horizon == null) {
      return;
    }
    final String title = _create.text.trim();
    setState(() {
      _creatingDomainKey = null;
      _creatingHorizon = null;
    });
    if (title.isEmpty) {
      return;
    }
    widget.onCreateGoalInline?.call(domainKey, horizon, title);
  }

  /// 放弃就地新建（Esc）：不写库、不改数据。
  void _cancelCreate() {
    if (_creatingDomainKey == null || !mounted) {
      return;
    }
    setState(() {
      _creatingDomainKey = null;
      _creatingHorizon = null;
    });
  }

  /// 失焦 ⇒ 提交（与改名链路同语义：不丢用户刚敲的字）。
  void _onCreateFocusChanged() {
    if (_createFocus.hasFocus) {
      return;
    }
    _commitCreate();
  }

  /// 回车提交；**IME 组合态（拼音还在候选窗里）回车是上屏，不是提交**。
  void _onCreateSubmitted(String _) {
    final TextEditingValue value = _create.value;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return;
    }
    _commitCreate();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? bodyStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: tokens.meta);
    final TextStyle? tabStyle = Theme.of(context).textTheme.labelLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _tabStrip(tokens: tokens, tabStyle: tabStyle),
        if (_selected == GoalHorizon.short)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.t.goalBlueprintShortTabNote,
              key: const ValueKey<String>('goal-blueprint-short-tab-note'),
              style: metaStyle,
            ),
          ),
        // B16 第 4 条：日期列顶部那行**年份刻度条已下线**（用户反馈「填入起止
        // 日期后顶部多一行年份」）。日期改为「点一下即出选择界面」，年份信息
        // 由 `yyyy-MM-dd` 全量日期自带的年份承担，不再单摆一行刻度。
        Table(
          columnWidths: GoalBlueprintMatrix.columnWidths,
          border: TableBorder(
            horizontalInside: BorderSide(color: tokens.hairSoft, width: 1),
            verticalInside: BorderSide(color: tokens.hairSoft, width: 1),
          ),
          children: <TableRow>[
            for (final GoalBlueprintRow row in widget.rows)
              TableRow(
                children: <Widget>[
                  Padding(
                    key: ValueKey<String>(
                      'goal-blueprint-pad-domain-${row.domainKey}',
                    ),
                    padding: GoalBlueprintMatrix.cellPadding,
                    child: Text(
                      widget.t.projectDomainLabel(row.domainKey),
                      key: ValueKey<String>(
                        'goal-blueprint-row-${row.domainKey}',
                      ),
                      style: bodyStyle,
                    ),
                  ),
                  Padding(
                    key: ValueKey<String>(
                      'goal-blueprint-pad-goal-${row.domainKey}',
                    ),
                    padding: GoalBlueprintMatrix.cellPadding,
                    child: _cell(
                      goals: row.cells[_selected] ?? const <GoalRow>[],
                      domainKey: row.domainKey,
                      horizon: _selected,
                      bodyStyle: bodyStyle,
                      metaStyle: metaStyle,
                    ),
                  ),
                  Padding(
                    key: ValueKey<String>(
                      'goal-blueprint-pad-date-${row.domainKey}',
                    ),
                    padding: GoalBlueprintMatrix.cellPadding,
                    child: _dates(
                      goals: row.cells[_selected] ?? const <GoalRow>[],
                      bodyStyle: bodyStyle,
                      metaStyle: metaStyle,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// 标签条（Chrome/Edge 浏览器标签风格，B12 第 2 条）。
  ///
  /// 结构与「当前档」的标法：
  ///  * 标签条底 = 纸（`tokens.paper`）—— 相当于浏览器的工具条；
  ///  * **活动标签底 = 浅洗底（`tokens.inkWash`）** + 顶部 3px 实色指示条
  ///    ⇒ 靠「底色差 + 指示条」标出当前档（不再与内容区同色融合）；
  ///  * 非活动标签 = 下沉色（`tokens.sunken`，偏灰）；B17-A 起两态**等高**；
  ///  * 标签之间留 [GoalBlueprintMatrix.tabGap] 间距，1px hairline **居中**于
  ///    该间距；线只画在**两个非活动标签之间**（活动标签两侧留空）。
  ///
  /// 整条标签条用 `FittedBox(scaleDown)` 兜底 ⇒ 窄视口（1920 / 2520）不溢出。
  Widget _tabStrip({
    required ThemeTokens tokens,
    required TextStyle? tabStyle,
  }) {
    final List<GoalHorizon> tabs = GoalBlueprintMatrix.tabs;
    return Container(
      key: const ValueKey<String>('goal-blueprint-tab-strip'),
      color: tokens.paper,
      // B14（stage 4 · A1）：left 4 → 0，把这 4px 让给 `FittedBox`
      // ⇒ 760 宽真页面的可用宽 +4（标签条自身不再内缩）。
      padding: const EdgeInsets.only(left: 0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < tabs.length; i++) ...<Widget>[
              if (i > 0)
                Container(
                  width: GoalBlueprintMatrix.tabGap,
                  height: 14,
                  alignment: Alignment.center,
                  child: tabs[i] != _selected && tabs[i - 1] != _selected
                      ? Container(
                          width: 1,
                          height: 14,
                          color: tokens.hairSoft,
                        )
                      : const SizedBox.shrink(),
                ),
              _tab(tabs[i], style: tabStyle, tokens: tokens),
            ],
          ],
        ),
      ),
    );
  }

  /// 一个档位标签页（Chrome/Edge 浏览器标签风格）。
  ///
  /// 活动标签 = 浅洗底（`tokens.inkWash`）+ 顶部圆角 8px + 顶部 3px 指示条；
  /// 非活动标签 = 下沉色（`tokens.sunken`）+ 顶部圆角 8px；B17-A 起两态**同高**
  /// （[GoalBlueprintMatrix.tabHeight]），不再有「底边抬高」的落差。
  /// 仍用 `TextButton`（保留按钮语义与键盘可达性），键名与文案一字未改。
  Widget _tab(
    GoalHorizon horizon, {
    required TextStyle? style,
    required ThemeTokens tokens,
  }) {
    final bool active = horizon == _selected;
    return Tooltip(
      message: _horizonSpan(horizon),
      // 选中态 = 淡染底 + **顶部 3px 实色条**（B14 第 3 条）。
        // 指示条单独铺在标签顶边：底色与内容区同色时它提供唯一的方向线索；
        // 用 `IgnorePointer` 包住，免得抢走标签顶部 3px 的点击。
        child: Stack(
          children: <Widget>[
            TextButton(
              key: ValueKey<String>(
                'goal-blueprint-tab-${_horizonKey(horizon)}',
              ),
          onPressed: () => setState(() => _selected = horizon),
          style: TextButton.styleFrom(
                // 活动 = 「当前」浅洗底（**不再**用内容区底色，否则融为一体）；
                // 非活动 = 下沉色（偏灰）。
                backgroundColor: active ? tokens.inkWash : tokens.sunken,
            foregroundColor: active ? tokens.ink : tokens.meta,
            // B13 第 2 条曾把水平内边距加到 18；B14（stage 4 · A1）收到 10
            // （`_tabPadding`）—— 760 宽英文真页面的 11px 红线余量靠这条。
            // B16 第 3 条：加垂直 4px（文字上下不再贴轮廓）。
            // B17-A：水平 10 → 16（「页签加宽」），垂直 4 不动。
            padding: const EdgeInsets.symmetric(
              horizontal: GoalBlueprintMatrix._tabPadding,
              vertical: GoalBlueprintMatrix.tabVerticalPadding,
            ),
            // B17-A：两态等高 ⇒ 单一 tabHeight，不再按 active 分支取值。
            minimumSize: const Size(0, GoalBlueprintMatrix.tabHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              // 只圆顶部两角（浏览器标签轮廓）；底部是直角 ⇒ 能与内容区对齐。
              borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      GoalBlueprintMatrix.chromeTabTopRadius,
                    ),
              ),
            ),
          ),
          child: Text(
            _horizonLabel(horizon),
            // B13 第 2 条：在既有 `labelLarge` 基础上显式覆写字号 + 衬线族。
            // 字体名一律从 `AppFonts` 取，**不得**自写 `'Fraunces'` /
            // `'Noto Serif SC'`（theme 是唯一真源）。
            style: (style ?? const TextStyle()).copyWith(
              fontSize: GoalBlueprintMatrix._tabFontSize,
              fontFamily: AppFonts.display,
              fontFamilyFallback: AppFonts.displayFallback,
              color: active ? tokens.ink : tokens.meta,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
            ),
            if (active)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    key: ValueKey<String>(
                      'goal-blueprint-tab-indicator-${_horizonKey(horizon)}',
                    ),
                    height: GoalBlueprintMatrix.tabIndicatorHeight,
                    decoration: BoxDecoration(
                      color: tokens.ink,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(
                          GoalBlueprintMatrix.chromeTabTopRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  /// 档位显示名。
  String _horizonLabel(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => widget.t.goalBlueprintHorizonUltimate,
    GoalHorizon.long => widget.t.goalBlueprintHorizonLong,
    GoalHorizon.mid => widget.t.goalBlueprintHorizonMid,
    GoalHorizon.short => widget.t.goalBlueprintHorizonShort,
    GoalHorizon.near => widget.t.goalBlueprintHorizonNear,
  };

  /// 档位时长（标签页悬停提示；near 不进标签页，兜底用短期那条）。
  String _horizonSpan(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => widget.t.goalBlueprintHorizonUltimateSpan,
    GoalHorizon.long => widget.t.goalBlueprintHorizonLongSpan,
    GoalHorizon.mid => widget.t.goalBlueprintHorizonMidSpan,
    GoalHorizon.short => widget.t.goalBlueprintHorizonShortSpan,
    GoalHorizon.near => widget.t.goalBlueprintHorizonShortSpan,
  };

  /// 档位 → key 片段（与枚举名一致：`career-ultimate` / `learning-short`）。
  String _horizonKey(GoalHorizon horizon) => switch (horizon) {
    GoalHorizon.ultimate => 'ultimate',
    GoalHorizon.long => 'long',
    GoalHorizon.mid => 'mid',
    GoalHorizon.short => 'short',
    GoalHorizon.near => 'near',
  };

  /// 一个格子：列出该格的目标（空格子只留「+」入口，**合法**）。
  ///
  /// B12 第 3 条：格内**不再**渲染「条做法 N」与「未落位」（含 key
  /// `goal-blueprint-unplaced-<id>`）—— 目标框只留标题 + 展开层。
  Widget _cell({
    required List<GoalRow> goals,
    required String domainKey,
    required GoalHorizon horizon,
    required TextStyle? bodyStyle,
    required TextStyle? metaStyle,
  }) {
    final bool canAdd = widget.onCreateGoalInline != null ||
        widget.onAddGoal != null;
    final bool creating =
        _creatingDomainKey == domainKey && _creatingHorizon == horizon;
    if (goals.isEmpty) {
      if (!canAdd) {
        // 没传回调 ⇒ 与 Task 66 时期一致：空态什么都不渲染（坑 48）。
        return const SizedBox.shrink();
      }
      if (!creating) {
        return Align(
          alignment: Alignment.bottomRight,
          child: _addButton(domainKey, horizon),
        );
      }
      // B16 第 1 条：点「+」就在格内出输入框（不弹 `goal_form_dialog`）。
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _createEditor(domainKey, horizon, bodyStyle),
          Align(
            alignment: Alignment.centerRight,
            child: _addButton(domainKey, horizon),
          ),
        ],
      );
    }
    final Widget goalsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              // B18 第 1 条：行内三段（勾选框 / 标题 / 操作区）垂直居中。
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // B10-B3：勾选框只管写 `status`，归档时刻由 store 派生。
                if (widget.onToggleGoalDone != null)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      key: ValueKey<String>('goal-blueprint-done-${goal.id}'),
                      value: goal.isDone,
                      onChanged: (bool? value) =>
                          widget.onToggleGoalDone!(goal, value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_editingGoalId == goal.id)
                        _inlineEditor(goal, bodyStyle)
                      else ...<Widget>[
                        // D1：格子按键（整格）仍是**展开/收起**，语义逐字不变；
                        // 文本节点自己再挂一个手势，只盖住文字自身尺寸 ⇒
                        // 点文字进就地编辑、点格子空白处照旧展开。
                        SizedBox(
                          width: double.infinity,
                          child: InkWell(
                            key: ValueKey<String>(
                              'goal-blueprint-cell-${goal.id}',
                            ),
                            onTap: () => _toggle(goal.id),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                key: ValueKey<String>(
                                  'goal-blueprint-goal-text-${goal.id}',
                                ),
                                onTap: () => _startInline(goal),
                                child: Text(goal.title, style: bodyStyle),
                              ),
                            ),
                          ),
                        ),
                        if (_expanded.contains(goal.id)) ...<Widget>[
                          if (goal.keywords != null &&
                              goal.keywords!.trim().isNotEmpty)
                            Text(goal.keywords!, style: metaStyle),
                          for (final GoalRow child in _weeklyChildren(goal))
                            Text(
                              '${widget.t.goalBlueprintWeeklyTarget} ${child.title}',
                              key: ValueKey<String>(
                                'goal-blueprint-child-${child.id}',
                              ),
                              style: metaStyle,
                            ),
                          // B14 第 2 条：铅笔改成**就地改名**后，全量编辑
                          // （备注 / 关键词 / 领域 / 档位 / 期限）的唯一入口
                          // 必须另开 —— 否则 B8 D-8-e 的「领域可清空」链路
                          // 在 UI 上失去可达性（T2 就是钉这条的）。
                          if (goal.kind == GoalKind.blueprint &&
                              widget.onEditGoal != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                key: ValueKey<String>(
                                  'goal-blueprint-edit-full-${goal.id}',
                                ),
                                onPressed: () => widget.onEditGoal!(goal),
                                icon: const Icon(Icons.tune, size: 15),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
                // 铅笔/拆分/删除只管**蓝图目标**：短期页里混进来的年目标属于年页，
                // 在 07 页改它的档位会把 `horizon` 写成一个不该有的值。
                if (goal.kind == GoalKind.blueprint) _actions(goal),
              ],
            ),
          ),
        // B16 第 1 条：新建输入框挂在目标列表末尾；保存后「+」仍在 ⇒ 可继续加。
        if (creating) _createEditor(domainKey, horizon, bodyStyle),
      ],
    );
    if (widget.onCreateGoalInline == null) {
      // 坑 48：没传就地新建回调的既有调用点，已填格结构逐字不变（仍无「+」）。
      return goalsColumn;
    }
    // B16 第 2 条：已填格右侧**常驻**「+」—— 已存下的目标不占用这个入口。
    return Row(
      // B18 第 1 条：「+」与整列目标块垂直居中（原 start 贴第一行顶上）。
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: goalsColumn),
        _addButton(domainKey, horizon),
      ],
    );
  }

  /// 就地编辑框（B14 第 2 条）：单行、自动聚焦、Esc 取消、失焦 / 回车提交。
  ///
  /// 入口有两个（B14 补做 D1）：格内标题文本（`goal-blueprint-goal-text-<id>`，
  /// 点文字直接进）与铅笔。`goal-blueprint-cell-<id>` 的点击仍归**展开三层**
  /// （B9/B12 收口）；文字手势只覆盖文字自身尺寸，点格子空白处照旧展开。
  Widget _inlineEditor(GoalRow goal, TextStyle? bodyStyle) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _cancelInline,
      },
      child: TextField(
        key: ValueKey<String>('goal-blueprint-inline-${goal.id}'),
        controller: _inline,
        focusNode: _inlineFocus,
        autofocus: true,
        maxLines: 1,
        style: bodyStyle,
        textInputAction: TextInputAction.done,
        onSubmitted: _onInlineSubmitted,
        decoration: const InputDecoration(
          isDense: true,
          // 与相邻单元格的文字左缘对齐（不额外撑高行）。
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// 格内「+」（B16 第 1/2 条）：空格右下角与已填格右侧共用**同一个**入口/key。
  Widget _addButton(String domainKey, GoalHorizon horizon) {
    return _compactButton(
      key: ValueKey<String>(
        'goal-blueprint-add-$domainKey-${_horizonKey(horizon)}',
      ),
      onPressed: () => _startCreate(domainKey, horizon),
      tooltip: widget.t.goalBlueprintAddGoal,
      // 英文态「Add」比 28×28 按钮宽，`FittedBox` 兜底缩放（不换行、不溢出）。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(widget.t.goalBlueprintAddSymbol),
      ),
    );
  }

  /// 就地新建框（B16 第 1 条）：单行、自动聚焦、Esc 取消、失焦 / 回车提交。
  ///
  /// 与 [_inlineEditor] 同语义但**控制器 / 焦点独立**：改名提交走
  /// `onRenameGoal`（只写标题），新建提交走 `onCreateGoalInline`（新建一条记录），
  /// 混用一份控制器会让两条断言链互相踩。
  Widget _createEditor(
    String domainKey,
    GoalHorizon horizon,
    TextStyle? bodyStyle,
  ) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _cancelCreate,
      },
      child: TextField(
        key: ValueKey<String>(
          'goal-blueprint-inline-create-$domainKey-${_horizonKey(horizon)}',
        ),
        controller: _create,
        focusNode: _createFocus,
        autofocus: true,
        maxLines: 1,
        style: bodyStyle,
        textInputAction: TextInputAction.done,
        onSubmitted: _onCreateSubmitted,
        decoration: const InputDecoration(
          isDense: true,
          // 与相邻单元格的文字左缘对齐（不额外撑高行）。
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// 日期列（B10-B4）：每行目标一条 `起始 ~ 结束`，已完成追加完成日。
  Widget _dates({
    required List<GoalRow> goals,
    required TextStyle? bodyStyle,
    required TextStyle? metaStyle,
  }) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // B14 第 2 条：起止日期**单行不折行**。
                // 23 个字符在 760px 视口的起止列里仍可能超宽 ⇒ `FittedBox`
                // 等比缩字（保留 `yyyy-MM-dd ~ yyyy-MM-dd` 全量信息，不截年份、
                // 不省略号），常态宽度下 scaleDown 不生效、字号原样。
                //
                // B16 第 4 条：**点日期一点即出**选择界面 —— 日期文本自身就是
                // 入口；没有改期回调 / 非蓝图目标时保持纯文本。B17 第 B 条：
                // 原先并排的图标按钮已下线 ⇒ 这里是改期**唯一**的入口
                // （年目标的周期归年页管，与本门槛无关）。
                if (widget.onEditGoalPeriod != null &&
                    goal.kind == GoalKind.blueprint)
                  InkWell(
                    key: ValueKey<String>(
                      'goal-blueprint-period-tap-${goal.id}',
                    ),
                    onTap: () => widget.onEditGoalPeriod!(
                      goal,
                      goal.periodStart,
                      goal.periodEnd,
                    ),
                    child: _periodLine(goal, bodyStyle),
                  )
                else
                  _periodLine(goal, bodyStyle),
                // B19：日期条（起止日期下方那条整列宽的横线）整条下线 ——
                // 日期列只保留起止日期文本，不再画任何轨道。
                if (goal.isDone)
                  Text(
                    '${widget.t.goalBlueprintDonePrefix}'
                    '${_momentText(goal.archivedAt)}',
                    key: ValueKey<String>('goal-blueprint-done-on-${goal.id}'),
                    style: metaStyle,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 起止日期这一行（B14 第 2 条 + B16 第 4 条）：**单行、不换行、不溢出**。
  ///
  /// 23 个字符（`yyyy-MM-dd ~ yyyy-MM-dd`）在窄视口等比缩字，不截年份、
  /// 不省略号；`maxLines: 1` + `softWrap: false` 保证永不折行。
  Widget _periodLine(GoalRow goal, TextStyle? bodyStyle) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        _periodText(goal),
        key: ValueKey<String>('goal-blueprint-period-text-${goal.id}'),
        maxLines: 1,
        softWrap: false,
        // 等宽数字（`tabularFigures`）：日期列纵向对齐，不抖动。
        style: bodyStyle?.copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// 目标卡片右侧的操作区（铅笔 + 拆分 + 删除，三个都是图标按钮）。
  Widget _actions(GoalRow goal) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.onEditGoal != null)
          _compactButton(
            key: ValueKey<String>('goal-blueprint-edit-${goal.id}'),
            // B14 第 2 条：点铅笔 ⇒ **格内就地编辑**（不再弹全量表单弹窗）。
            // `onRenameGoal` 为 null 的既有调用点仍走旧弹窗（坑 48）。
            onPressed: () => _startInline(goal),
            tooltip: widget.t.goalBlueprintEditGoal,
            child: const Icon(Icons.edit_outlined),
            iconSize: 16,
          ),
        _compactButton(
          key: ValueKey<String>('goal-blueprint-split-${goal.id}'),
          onPressed: () => widget.onSplitTodos(goal),
          tooltip: widget.t.goalBlueprintSplit,
          child: const Icon(Icons.call_split),
          iconSize: 16,
        ),
        if (widget.onDeleteGoal != null)
          // B18 第 2 条：文字按钮 ⇒ 垃圾桶图标（与 `GoalRowActions` 同款）。
          // 语义出口逐字保留：key / Tooltip / 读屏文案 / 回调全不变；外层
          // `Semantics` 按 AGENTS.md §7 补 `label`（实测 zh 下每个按钮恰好一个
          // 「删除目标」语义节点，由 `test\b18_blueprint_test.dart` B18-3b 钉住）。
          Semantics(
            label: widget.t.goalBlueprintDeleteGoal,
            button: true,
            onTap: () => widget.onDeleteGoal!(goal),
            child: _compactButton(
              key: ValueKey<String>('goal-blueprint-delete-${goal.id}'),
              onPressed: () => widget.onDeleteGoal!(goal),
              tooltip: widget.t.goalBlueprintDeleteGoal,
              child: const Icon(Icons.delete_outline),
              iconSize: 16,
            ),
          ),
      ],
    );
  }

  /// 28×28 紧凑图标按钮（与 `GoalRowActions` 同口径）。
  Widget _compactButton({
    required Key key,
    required VoidCallback onPressed,
    required String tooltip,
    required Widget child,
    double? iconSize,
  }) {
    // `IconButton` 默认按 `MaterialTapTargetSize.padded` 把点击区撑到 48×48，
    // 这里显式 shrinkWrap，让点击区回到 `constraints` 给的 28×28。
    return Theme(
      data: Theme.of(context)
          .copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: IconButton(
        key: key,
        onPressed: onPressed,
        icon: child,
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        tooltip: tooltip,
      ),
    );
  }

  /// 起止日期文案：无起始 ⇒ 整体 `—`；无结束 ⇒ 右端 `—`。
  ///
  /// **B12 第 3 条的回退**：起止都缺省时**回退显示期限**（`dueDate`）。
  /// 表单写的是 `due_date`、本列读的是 `period_*` —— 两侧来源不一致才是
  /// 「填了日期第三列不显示」的根因；页面侧已同步写 `period_end`，这里再兜底
  /// 显示 `due_date` ⇒ 新建目标与历史目标（只有 `due_date`）都能看到日期。
  ///
  /// 口径按「这条起止是谁写的」分流 —— 库里 `period_start` / `period_end` 有**两种**
  /// 存储语义并存：
  ///  * 蓝图目标（`kind == blueprint`）：起止只由 B10 改期对话框写入
  ///    （`goals_blueprint_page.dart` 只给蓝图目标渲染改期按钮），写进去的是
  ///    「**本地**某日 00:00 那一刻的毫秒数」⇒ 必须按**本地时区**取年月日；
  ///    按 UTC 解释会让东八区整体提前一天（装机实测：选 11-01 / 11-30 显示成
  ///    10-31 / 11-29）。
  ///  * 年 / 月 / 周目标：起止由 `GoalPeriod.startMillis` / `endMillis` 写入 =
  ///    **UTC 午夜毫秒**（起点 00:00.000Z、终点 23:59:59.999Z）⇒ 按 UTC 取年月日；
  ///    按本地解释会把终点（周期最后一刻）显示成第二天（如 2026-12-31 → 2027-01-01）。
  ///
  /// 期限 `dueDate` 一律按**本地** midnight 口径显示（蓝图目标的期限就是本地午夜
  /// 毫秒，B11 裁决，不得改回 UTC）。
  String _periodText(GoalRow goal) {
    if (goal.periodStart <= 0) {
      final int? due = goal.dueDate;
      if (due != null && due > 0) {
        return _dateText(due, localMidnight: true);
      }
      return '—';
    }
    final bool localMidnight = goal.kind == GoalKind.blueprint;
    return '${_dateText(goal.periodStart, localMidnight: localMidnight)} ~ '
        '${_dateText(goal.periodEnd, localMidnight: localMidnight)}';
  }

  /// **日期型字段**专用：毫秒 → `yyyy-MM-dd`（null / 非正数 → `—`）。
  ///
  /// [localMidnight] = true ⇒ 值是「本地午夜毫秒」，按**本地时区**取年月日；
  /// false ⇒ 值是「UTC 午夜毫秒」，按 UTC 取年月日（分流理由见 [_periodText]）。
  String _dateText(int? millis, {required bool localMidnight}) {
    if (millis == null || millis <= 0) {
      return '—';
    }
    final DateTime moment = localMidnight
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }

  /// **时刻型字段**专用：毫秒 → `yyyy-MM-dd`（null / 非正数 → `—`），按**本地时区**取年月日。
  ///
  /// 只给 `archivedAt` 用 —— 它存的是 `GoalStore.updateGoal` 里 `DateTime.now()` 的
  /// 时刻，不是 UTC 午夜的「日期」。若按 UTC 显示，东八区 00:00–08:00 之间勾完成
  /// 会少一天，用户看到的完成日期就是错的。
  String _momentText(int? millis) {
    if (millis == null || millis <= 0) {
      return '—';
    }
    final DateTime moment = DateTime.fromMillisecondsSinceEpoch(millis);
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }

  /// 该目标下的周目标（做法层的下一层）。
  List<GoalRow> _weeklyChildren(GoalRow goal) => widget.serves
      .childrenOf(goal.id)
      .where((GoalRow child) => child.kind == GoalKind.weekly)
      .toList(growable: false);
}
