// =============================================================================
// 目标 · 人生蓝图矩阵（Task 66 UI 半批 B2 → B9-W2 标签页改造 → B10-B 增强）
// =============================================================================
// 口径（计划 §5.4 + B9 裁决 D-9 + B10 棒 B）：
//  1. 主视图 = **4 个标签页（终极 / 远期 / 中期 / 短期），默认终极**；一次只渲染
//     当前档位那一张表 —— **6 行（domain）× 3 列（领域 | 目标 | 日期）**，
//     不渲染表头行。目标格里显示 `title` 一行 + `keywords` 标签 + 做法条数；
//     点标题展开三层（目标 → 关键词 → 做法）。
//  2. **标签页 = Chrome/Edge 浏览器标签**（B12 第 2 条，用户给的参照物）：
//     标签条底 = 纸（`tokens.paper`）；**活动标签 = 内容区底色（`tokens.card`）**
//     ⇒ 下边缘与下方表格同色、无下边框，视觉上「打开」进内容区；非活动标签 =
//     下沉色（`tokens.sunken`，偏灰）+ 底边抬高 6px（不与内容区相接）+ 标签之间
//     1px hairline 分隔。顶部圆角 8px（[GoalBlueprintMatrix.chromeTabTopRadius]）
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
//       改期按钮（`goal-blueprint-period-<id>`）只在传了 `onEditGoalPeriod` 时渲染，
//       且只管**蓝图目标**（年目标在本页改周期会与年页口径打架）。
//     * B12 第 3 条：**起止缺省时回退显示期限**（`dueDate`，本地午夜毫秒 ⇒ 按本地
//       时区取日）。表单写的是 `due_date`、第三列读的是 `period_*` —— 两侧来源
//       不一致才是「填了日期第三列不显示」的根因；页面侧同步写 `period_end`，
//       矩阵侧再兜底显示 `due_date` ⇒ 新旧数据都能在第三列看到日期。
//
// 本模块使用 3 个 Material 图标，一律 `*_outlined` 系（AGENTS.md 例外清单以外
// 不自造；坑 105）：`Icons.edit_outlined`（改目标）、`Icons.call_split`（拆待办）、
// `Icons.date_range_outlined`（B13 第 3 条：起止日期入口 —— 原先用文字「起止日期」
// 占满单元格，与相邻图标语言不统一；换图标后 tooltip、键名与对话框语义一字未改）。
// 「+」仍用文字符号（坑 51：桌面测试不预载 MaterialIcons 字体）。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

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

  /// 活动标签高度（px）。
  ///
  /// B13 第 2 条：34 → 38（字号 15 + 衬线体后垂直方向更舒展；靠 `minimumSize`
  /// 撑高，`padding` 不加 `vertical`，避免与 `minimumSize` 打架）。
  static const double tabActiveHeight = 38;

  /// 非活动标签高度（px）。
  ///
  /// B13 第 2 条：28 → 31（与活动态同幅加 3px，保持两者 7px 落差）。
  static const double tabInactiveHeight = 31;

  /// 非活动标签底边相对内容区抬高的高度（px）⇒ 不与内容区相接。
  static const double tabInactiveLift = 6;

  /// 档位标签字号（px）。
  ///
  /// B13 第 2 条。**为什么不能走主题槽位**：`labelLarge.fontSize` 由
  /// `DensityProfile` 三档密度决定（12 / 12.5 / 13.5），而档位标签是本页的顶层
  /// 导航，需在三档密度下保持同一视觉权重 ⇒ 显式钉死 15。
  static const double _tabFontSize = 15;

  /// 档位标签水平内边距（px）。
  ///
  /// B13 第 2 条：10 → 18（字变大后需要更松的内边距，否则字贴着标签轮廓）。
  /// 写成命名常量以满足 §2 E4「不新增魔法数」。
  static const double _tabPadding = 18;

  /// 单元格内边距：垂直 11px、水平 8px。
  ///
  /// B12 第 2 条（用户反馈「表格中的内容，适当增加上下边距」）：原先四边各 4px
  /// 太挤；列宽比例（2 / 5 / 3）不变，窄视口不溢出。
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 11,
  );

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

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final TextStyle? bodyStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: tokens.ink);
    final TextStyle? metaStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: tokens.meta);
    final TextStyle? tabStyle = Theme.of(context).textTheme.labelLarge;
    // 当前档位的日期跨度（年刻度条 + 日期列 track 共用同一份派生值）。
    // **由真实数据派生**，不硬编码「2026–2035」这类业务口径。
    final _DateSpan? span = _span();

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
        // 年刻度条（A 稿 `.scale`）：与下方表格**同一套列宽**，只占日期列；
        // 当前档位没有任何日期时整条不渲染（空格子合法，不摆空刻度）。
        if (span != null)
          Table(
            columnWidths: <int, TableColumnWidth>{
              0: const FlexColumnWidth(2),
              1: const FlexColumnWidth(5),
              2: const FlexColumnWidth(3),
            },
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  const SizedBox.shrink(),
                  const SizedBox.shrink(),
                  Padding(
                    key: const ValueKey<String>('goal-blueprint-year-scale'),
                    // 水平 8px：与下方日期列单元格的内边距对齐（垂直不占位）。
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 3),
                    child: _yearScale(span, tokens, metaStyle),
                  ),
                ],
              ),
            ],
          ),
        Table(
          columnWidths: <int, TableColumnWidth>{
            0: const FlexColumnWidth(2),
            1: const FlexColumnWidth(5),
            2: const FlexColumnWidth(3),
          },
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
                      tokens: tokens,
                      span: span,
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
  /// 结构与「与内容区融合」的做法：
  ///  * 标签条底 = 纸（`tokens.paper`）—— 相当于浏览器的工具条；
  ///  * **活动标签底 = 内容区底色（`tokens.card`）** ⇒ 它下边缘与下方表格（内容区）
  ///    同色、且没有分隔线 ⇒ 视觉上「打开」进内容区（这就是浏览器标签的融合感）；
  ///  * 非活动标签 = 下沉色（`tokens.sunken`，偏灰）+ 底边抬高 6px ⇒ 不与内容区相接；
  ///  * 标签之间的 1px hairline 只画在**两个非活动标签之间**（活动标签两侧留空，
  ///    免得切断它与内容区融合的那条边）。
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
      padding: const EdgeInsets.only(left: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < tabs.length; i++) ...<Widget>[
              if (i > 0 && tabs[i] != _selected && tabs[i - 1] != _selected)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: GoalBlueprintMatrix.tabInactiveLift,
                  ),
                  child: Container(
                    width: 1,
                    height: 14,
                    color: tokens.hairSoft,
                  ),
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
  /// 活动标签 = 内容区底色 + 顶部圆角 8px + 无下边框（与内容区融合）；
  /// 非活动标签 = 下沉色 + 顶部圆角 8px + 底边抬高 6px。
  /// 仍用 `TextButton`（保留按钮语义与键盘可达性），键名与文案一字未改。
  Widget _tab(
    GoalHorizon horizon, {
    required TextStyle? style,
    required ThemeTokens tokens,
  }) {
    final bool active = horizon == _selected;
    return Tooltip(
      message: _horizonSpan(horizon),
      child: Padding(
        // 非活动标签整体抬高 ⇒ 底边不与内容区相接（浏览器观感）。
        padding: EdgeInsets.only(
          bottom: active ? 0 : GoalBlueprintMatrix.tabInactiveLift,
        ),
        child: TextButton(
          key: ValueKey<String>('goal-blueprint-tab-${_horizonKey(horizon)}'),
          onPressed: () => setState(() => _selected = horizon),
          style: TextButton.styleFrom(
            // 活动 = 内容区底色（融合）；非活动 = 下沉色（偏灰）。
            backgroundColor: active ? tokens.card : tokens.sunken,
            foregroundColor: active ? tokens.ink : tokens.meta,
            // B13 第 2 条：水平内边距 10 → 18（`_tabPadding`）。
            padding: const EdgeInsets.symmetric(
              horizontal: GoalBlueprintMatrix._tabPadding,
            ),
            minimumSize: Size(
              0,
              active
                  ? GoalBlueprintMatrix.tabActiveHeight
                  : GoalBlueprintMatrix.tabInactiveHeight,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              // 只圆顶部两角（浏览器标签轮廓）；底部是直角 ⇒ 能与内容区对齐。
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(GoalBlueprintMatrix.chromeTabTopRadius),
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
    if (goals.isEmpty) {
      if (widget.onAddGoal == null) {
        // 没传回调 ⇒ 与 Task 66 时期一致：空态什么都不渲染（坑 48）。
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.bottomRight,
        child: _compactButton(
          key: ValueKey<String>(
            'goal-blueprint-add-$domainKey-${_horizonKey(horizon)}',
          ),
          onPressed: () => widget.onAddGoal!(domainKey, horizon),
          tooltip: widget.t.goalBlueprintAddGoal,
          // 英文态「Add」比 28×28 按钮宽，`FittedBox` 兜底缩放（不换行、不溢出）。
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.t.goalBlueprintAddSymbol),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final GoalRow goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      InkWell(
                        key: ValueKey<String>('goal-blueprint-cell-${goal.id}'),
                        onTap: () => _toggle(goal.id),
                        child: Text(goal.title, style: bodyStyle),
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
      ],
    );
  }

  /// 日期列（B10-B4）：每行目标一条 `起始 ~ 结束`，已完成追加完成日。
  Widget _dates({
    required List<GoalRow> goals,
    required TextStyle? bodyStyle,
    required TextStyle? metaStyle,
    required ThemeTokens tokens,
    required _DateSpan? span,
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
                Text(
                  _periodText(goal),
                  key: ValueKey<String>(
                    'goal-blueprint-period-text-${goal.id}',
                  ),
                  // 等宽数字（`tabularFigures`）：日期列纵向对齐，不抖动。
                  style: bodyStyle?.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                // 日期条（A 稿 `.track`）：整条宽 = 当前档位的跨度，实心段 = 本条；
                // 已完成用 hairStrong 降调，赭石留给「未落位」那类缺口信号。
                if (span != null && goal.periodStart > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _track(goal, span, tokens),
                  ),
                if (goal.isDone)
                  Text(
                    '${widget.t.goalBlueprintDonePrefix}'
                    '${_momentText(goal.archivedAt)}',
                    key: ValueKey<String>('goal-blueprint-done-on-${goal.id}'),
                    style: metaStyle,
                  ),
                // 年目标的周期归年页管，本页只改蓝图目标（与 _actions 同门槛）。
                if (widget.onEditGoalPeriod != null &&
                    goal.kind == GoalKind.blueprint)
                  _compactButton(
                    key: ValueKey<String>('goal-blueprint-period-${goal.id}'),
                    onPressed: () => widget.onEditGoalPeriod!(
                      goal,
                      goal.periodStart,
                      goal.periodEnd,
                    ),
                    tooltip: widget.t.goalBlueprintPeriodTitle,
                    // B13 第 3 条：文字「起止日期」→ 日历图标。入口语义不变：
                    // 键名、tooltip（仍为「起止日期」，语义树不丢）与点击打开的
                    // 对话框一律照旧。尺寸/颜色走 `_compactButton` 既有机制
                    // （`iconSize` + `IconButton` 前景色），不在图标上重复覆写。
                    child: const Icon(Icons.date_range_outlined),
                    iconSize: 16,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 目标卡片右侧的操作区（铅笔 + 拆分 + 既有删除按钮）。
  Widget _actions(GoalRow goal) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.onEditGoal != null)
          _compactButton(
            key: ValueKey<String>('goal-blueprint-edit-${goal.id}'),
            onPressed: () => widget.onEditGoal!(goal),
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
          TextButton(
            key: ValueKey<String>('goal-blueprint-delete-${goal.id}'),
            onPressed: () => widget.onDeleteGoal!(goal),
            child: Text(widget.t.goalBlueprintDeleteGoal),
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

  /// 当前档位的日期跨度；**一条带日期的目标都没有 ⇒ null**（不摆空刻度、不画空轨道）。
  ///
  /// 毫秒值跨 `kind` 可直接比较（都是 epoch 毫秒）；只有「取年」这一步要按
  /// [_periodText] 的口径分流 —— 蓝图目标是本地午夜毫秒、年/月/周目标是 UTC 午夜，
  /// 所以起止两端各自记住给自己那个边界的目标属于哪种口径，避免东八区跨年错位。
  _DateSpan? _span() {
    int? minStart;
    bool minLocal = true;
    int? maxEnd;
    bool maxLocal = true;
    for (final GoalBlueprintRow row in widget.rows) {
      for (final GoalRow goal in row.cells[_selected] ?? const <GoalRow>[]) {
        if (goal.periodStart <= 0) {
          continue;
        }
        final bool local = goal.kind == GoalKind.blueprint;
        final int? declaredEnd = goal.periodEnd;
        final int end = (declaredEnd != null && declaredEnd > 0)
            ? declaredEnd
            : goal.periodStart;
        if (minStart == null || goal.periodStart < minStart) {
          minStart = goal.periodStart;
          minLocal = local;
        }
        if (maxEnd == null || end > maxEnd) {
          maxEnd = end;
          maxLocal = local;
        }
      }
    }
    if (minStart == null) {
      return null;
    }
    // 只有一天的目标（起 == 止）也给一条满格日条：跨度缩成 24h，
    // 否则「这天要做什么」会看起来像没排日期。
    final int start = minStart;
    final int end = (maxEnd == null || maxEnd <= start)
        ? start + Duration.millisecondsPerDay
        : maxEnd;
    return _DateSpan(
      startMillis: start,
      endMillis: end,
      startYear: _yearOf(start, localMidnight: minLocal),
      endYear: _yearOf(end, localMidnight: maxLocal),
    );
  }

  /// 毫秒 → 年份（口径分流同 [_dateText]）。
  int _yearOf(int millis, {required bool localMidnight}) {
    final DateTime moment = localMidnight
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return moment.year;
  }

  /// 年刻度条（A 稿 `.scale`）：跨年内按年份等分，每年一根 1px 刻度 + 年份标签。
  /// 窄列靠 `FittedBox` 缩字，不换行、不溢出、不截断业务值。
  Widget _yearScale(_DateSpan span, ThemeTokens tokens, TextStyle? metaStyle) {
    final int years = span.endYear >= span.startYear
        ? span.endYear - span.startYear + 1
        : 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < years; i++)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(width: 1, height: 4, color: tokens.hairStrong),
                const SizedBox(width: 3),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${span.startYear + i}',
                      key: ValueKey<String>(
                        'goal-blueprint-year-tick-${span.startYear + i}',
                      ),
                      style: metaStyle,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 日期条（A 稿 `.track`）：整条宽 = 当前档位跨度，实心段 = 本条目标。
  /// 已完成用 `hairStrong` 降调 —— 赭石只留给「未落位」这类缺口信号。
  Widget _track(GoalRow goal, _DateSpan span, ThemeTokens tokens) {
    final int total = span.endMillis - span.startMillis;
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    final int? declaredEnd = goal.periodEnd;
    final int rawEnd = (declaredEnd != null && declaredEnd > 0)
        ? declaredEnd
        : goal.periodStart;
    final int from = goal.periodStart.clamp(span.startMillis, span.endMillis);
    final int to = rawEnd.clamp(from, span.endMillis);
    final double startFraction = (from - span.startMillis) / total;
    final double endFraction = (to - span.startMillis) / total;
    final Color bar = goal.isDone ? tokens.hairStrong : tokens.ink;
    return SizedBox(
      key: ValueKey<String>('goal-blueprint-track-${goal.id}'),
      height: 3,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          if (!width.isFinite || width <= 2) {
            return const SizedBox.shrink();
          }
          // 至少 2px 宽：跨度极短的目标也要看得见，且不给 `clamp` 反区间。
          final double left = (startFraction * width).clamp(0.0, width - 2);
          final double barWidth = ((endFraction - startFraction) * width).clamp(
            2.0,
            width - left,
          );
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.hairSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: barWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 该目标下的周目标（做法层的下一层）。
  List<GoalRow> _weeklyChildren(GoalRow goal) => widget.serves
      .childrenOf(goal.id)
      .where((GoalRow child) => child.kind == GoalKind.weekly)
      .toList(growable: false);
}

/// 当前档位的日期跨度：毫秒起止 + 起止两年（年刻度条按年份等分用）。
///
/// 两年分开存而不是从毫秒现算，是因为起止两端可能属于不同 `kind`
/// （本地午夜 / UTC 午夜两种存储口径），见 `_span`。
class _DateSpan {
  const _DateSpan({
    required this.startMillis,
    required this.endMillis,
    required this.startYear,
    required this.endYear,
  });

  final int startMillis;
  final int endMillis;
  final int startYear;
  final int endYear;
}
