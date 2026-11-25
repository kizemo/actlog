// =============================================================================
// l10n part：目标页（Task 65 UI 半批 B1）
// =============================================================================
// 一个 part = 一个模块的「接口 + 中英两态实现」。形状照 `parts\shell.dart`：
//  1. `GoalsL10n` 只声明 getter，不带任何实现；
//  2. `GoalsZhL10n` / `GoalsEnL10n` 用 `mixin` 实现接口，`@override` 必须齐全；
//  3. 聚合在 `app_localizations.dart`：zh / en 两个子类各混一个 mixin。
//
// 本 part 只收**目标页自己**的文案：页壳标题与四个页签（周 / 月 / 年 / 蓝图）、
// 周视图的表头与空态、草稿滚动区的标题与动作位。
//
// 不收的文案：
// * 左导航项「目标」与快捷键「切到目标」属于**外壳**，放在 `parts\shell.dart`
//   （齿轮 tooltip 复用既有的 `shellNavSettings`，不新增 getter）；
// * 象限 / ABC 的标签复用 `parts\domain.dart` 里既有的 `quadrantQ1ShortLabel`
//   等 getter，**不建第二套**。
//
// 英文态零中文：每条英文取值都是纯 ASCII（含标点），英文界面下不残留 CJK。
// =============================================================================

/// 目标页文案。
abstract class GoalsL10n {
  // --- 页壳：标题 + 四个页签 ----------------------------------------------

  /// 目标页标题。
  String get goalsTitle;

  /// 页签：周。
  String get goalsTabWeek;

  /// 页签：月。
  String get goalsTabMonth;

  /// 页签：年。
  String get goalsTabYear;

  /// 页签：蓝图。
  ///
  /// Task 72（D-72-b）起蓝图已独立成页，本常量只作历史值保留，
  /// `parseGoalsTab` 收到它必须回落周视图。
  String get goalsTabBlueprint;

  // --- 未完成目标（上游面板，Task 72 B7 起 W2/W3 共用） -----------------------

  /// 上游面板：未完成年目标。
  String get goalsUpstreamYearTitle;

  /// 上游面板：未完成月目标。
  String get goalsUpstreamMonthTitle;

  /// 上游面板：未完成周目标。
  String get goalsUpstreamWeekTitle;

  /// 上游面板：点击或拖拽添加到当前周期的提示。
  String get goalsUpstreamAddHint;

  /// 上游面板：空态。
  String get goalsUpstreamEmpty;

  /// 上游面板：添加到计划的动作位。
  String get goalsUpstreamAddMenu;

  // --- 周视图 -------------------------------------------------------------

  /// 周视图区块标题。
  String get goalsWeekSection;

  /// 周视图空态。
  String get goalsWeekEmpty;

  /// 周视图表头：优先顺序。
  String get goalsColumnOrder;

  /// 周视图表头：目标。
  String get goalsColumnGoal;

  /// 周视图表头：象限。
  String get goalsColumnQuadrant;

  /// 周视图表头：完成期限。
  String get goalsColumnDue;

  /// 周视图表头：完成。
  String get goalsColumnDone;

  /// 周视图表头：服务于。
  String get goalsColumnServes;

  /// 完成度标签。
  String get goalsCompletion;

  /// 关联计划项标签。
  String get goalsPlanItems;

  /// 未落位标记。
  String get goalsUnplaced;

  // --- 草稿滚动区 ---------------------------------------------------------

  /// 草稿滚动区标题。
  String get goalsDraftSection;

  /// 草稿滚动区空态。
  String get goalsDraftEmpty;

  /// 草稿滚动区：确认写入按钮。
  String get goalsDraftConfirm;

  /// 草稿写入成功后的提示。
  String get goalsDraftSaved;

  /// 滚动候选来源：结转。
  String get goalsDraftCarryOver;

  /// 滚动候选来源：由本月目标派生。
  String get goalsDraftFromMonthly;

  // --- 其余三个页签的骨架占位 ----------------------------------------------

  /// 月页骨架占位。
  String get goalsPlaceholderMonth;

  /// 年页骨架占位。
  String get goalsPlaceholderYear;

  /// 蓝图页骨架占位。
  String get goalsPlaceholderBlueprint;

  // --- 目标状态（周 / 月 / 年 / 蓝图共用） ---------------------------------

  /// 目标状态：草稿。
  String get goalStatusDraft;

  /// 目标状态：进行中。
  String get goalStatusActive;

  /// 目标状态：已完成。
  String get goalStatusDone;

  /// 目标状态：已取消。
  String get goalStatusCancelled;

  /// 自评标签（`self_score`；明确是**用户自评**，不是达成率）。
  String get goalSelfScore;

  /// 待确认草稿区标题（草稿只落在本页，点确认才落库）。
  String get goalDraftPending;

  // --- 月度目标页 ---------------------------------------------------------

  /// 月页顶部年度汇总条标题。
  String get goalMonthYearBar;

  /// 月页「上月复盘」区块标题。
  String get goalMonthReviewSection;

  /// 月页「上月复盘」空态。
  String get goalMonthReviewEmpty;

  /// 月页复盘行：未完成原因标签。
  String get goalMonthReviewReason;

  /// 月页复盘行：未完成原因缺失的**提示**（只提示，不阻断）。
  String get goalMonthReviewReasonMissing;

  /// 月页复盘行：改进措施标签。
  String get goalMonthImprove;

  /// 月页复盘行：改进措施为空时的占位。
  String get goalMonthImproveEmpty;

  /// 月页复盘行：转为本月目标草稿的动作。
  String get goalMonthConvertDraft;

  /// 月页「本月目标」区块标题。
  String get goalMonthGoalsSection;

  /// 月页「本月目标」空态。
  String get goalMonthGoalsEmpty;

  /// 月页表头：类别。
  String get goalMonthColumnCategory;

  /// 月页表头：序号。
  String get goalMonthColumnIndex;

  /// 月页表头：方法和措施。
  String get goalMonthColumnMethods;

  /// 月页表头：完成。
  String get goalMonthColumnDone;

  /// 月页行标记：没有上层目标的「临时事项」。
  String get goalMonthAdHoc;

  /// 月页行标记：服务于某个年目标。
  String get goalMonthServesYearly;

  /// 月页滚动候选空态。
  String get goalMonthDraftEmpty;

  // --- 年度目标页 ---------------------------------------------------------

  /// 年页「年度目标」区块标题。
  String get goalYearGoalsSection;

  /// 年页「年度目标」空态。
  String get goalYearGoalsEmpty;

  /// 年页表一头：起止时间。
  String get goalYearColumnPeriod;

  /// 年页表二标题：月度展开（1–12 月）。
  String get goalYearMonthsSection;

  /// 年页表二列头：月目标。
  String get goalYearMonthColumn;

  /// 年页表二空格：该月未展开。
  String get goalYearCellEmpty;

  /// 年页表二空格输入框的提示文案。
  String get goalYearCellInputHint;

  /// 年页表二空格：加入待确认草稿的动作。
  String get goalYearCellAddDraft;

  /// 年页「年度复盘」区块标题。
  String get goalYearReviewSection;

  /// 年页年度复盘：完成项数标签。
  String get goalYearReviewDone;

  /// 年页年度复盘：自评总分标签。
  String get goalYearReviewScoreTotal;

  /// 年页年度复盘：自评均值标签。
  String get goalYearReviewScoreAverage;

  /// 年页年度复盘：自评口径说明（用户自评，不是达成率）。
  String get goalYearReviewSelfNote;

  /// 年页「80/20 视角」区块标题（只呈现，不评分、不排名）。
  String get goalYear8020Section;

  /// 年页「80/20 视角」空态。
  String get goalYear8020Empty;

  /// 年页「80/20 视角」：执行记录条数单位。
  String get goalYear8020Tracks;

  /// 年页滚动候选空态。
  String get goalYearDraftEmpty;

  // --- 人生蓝图页 ---------------------------------------------------------

  /// 蓝图页矩阵区块标题。
  String get goalBlueprintMatrixSection;

  /// 蓝图页矩阵行头：目标。
  String get goalBlueprintColumnGoal;

  /// 蓝图档位：终极。
  String get goalBlueprintHorizonUltimate;

  /// 蓝图档位：远期。
  String get goalBlueprintHorizonLong;

  /// 蓝图档位：中期。
  String get goalBlueprintHorizonMid;

  /// 蓝图档位：短期。
  String get goalBlueprintHorizonShort;

  /// 蓝图档位：近期（1 年）。
  String get goalBlueprintHorizonNear;

  /// 蓝图格为空时的占位（空格合法，不报错）。
  String get goalBlueprintEmptyCell;

  /// 蓝图页说明：整行留空合法。
  String get goalBlueprintBlankRowHint;

  /// 蓝图页说明：近期列的数据来源（与年视图同一份数据）。
  String get goalBlueprintNearSource;

  /// 蓝图格：做法条数单位。
  String get goalBlueprintActionsCount;

  /// 蓝图格展开：周目标标签。
  String get goalBlueprintWeeklyTarget;

  /// 蓝图格：拆成 3 条待办的动作。
  String get goalBlueprintSplitTodos;

  /// 蓝图页：待确认待办区标题。
  String get goalBlueprintPendingTodos;

  /// 蓝图页：确认写入待办的动作。
  String get goalBlueprintConfirmTodos;

  /// 蓝图页平衡轮区块标题（纯派生，不落库）。
  String get goalBlueprintBalanceSection;

  /// 蓝图页平衡轮空态。
  String get goalBlueprintBalanceEmpty;

  /// 蓝图页平衡轮：习惯打卡标签。
  String get goalBlueprintBalanceHabit;

  /// 蓝图格：新建目标入口（B8-W1）。
  String get goalBlueprintAddGoal;

  /// 蓝图卡片：编辑入口。
  String get goalBlueprintEditGoal;

  /// 蓝图卡片：删除入口 + 二次确认框标题。
  String get goalBlueprintDeleteGoal;

  /// 蓝图：目标保存成功提示。
  String get goalBlueprintGoalSaved;

  /// 蓝图：目标删除成功提示。
  String get goalBlueprintGoalDeleted;

  /// 蓝图表单：领域。
  String get goalBlueprintFieldDomain;

  /// 蓝图表单：档位。
  String get goalBlueprintFieldHorizon;

  /// 蓝图表单：备注。
  String get goalBlueprintFieldNote;

  /// 蓝图表单：关键词。
  String get goalBlueprintFieldKeywords;

  /// 蓝图表单：期限（`YYYY-MM-DD`）。
  String get goalBlueprintFieldDue;

  /// 蓝图表单：未设置（领域置空）。
  String get goalBlueprintFieldUnset;

  /// 蓝图表单：期限格式非法提示（`YYYY-MM-DD`）。
  String get goalBlueprintFieldDueInvalid;
}

/// 目标页文案：简体中文。
mixin GoalsZhL10n implements GoalsL10n {
  @override
  String get goalsTitle => '目标';

  @override
  String get goalsTabWeek => '周';

  @override
  String get goalsTabMonth => '月';

  @override
  String get goalsTabYear => '年';

  @override
  String get goalsTabBlueprint => '蓝图';

  @override
  String get goalsUpstreamYearTitle => '未完成年目标';

  @override
  String get goalsUpstreamMonthTitle => '未完成月目标';

  @override
  String get goalsUpstreamWeekTitle => '未完成周目标';

  @override
  String get goalsUpstreamAddHint => '点击或拖拽添加到当前周期';

  @override
  String get goalsUpstreamEmpty => '暂无未完成目标';

  @override
  String get goalsUpstreamAddMenu => '添加到计划';

  @override
  String get goalsWeekSection => '本周目标';

  @override
  String get goalsWeekEmpty => '本周还没有目标。';

  @override
  String get goalsColumnOrder => '优先顺序';

  @override
  String get goalsColumnGoal => '目标';

  @override
  String get goalsColumnQuadrant => '象限';

  @override
  String get goalsColumnDue => '完成期限';

  @override
  String get goalsColumnDone => '完成';

  @override
  String get goalsColumnServes => '服务于';

  @override
  String get goalsCompletion => '完成度';

  @override
  String get goalsPlanItems => '关联计划项';

  @override
  String get goalsUnplaced => '未落位';

  @override
  String get goalsDraftSection => '滚动候选';

  @override
  String get goalsDraftEmpty => '本周没有待滚动的候选。';

  @override
  String get goalsDraftConfirm => '确认写入草稿';

  @override
  String get goalsDraftSaved => '草稿已写入';

  @override
  String get goalsDraftCarryOver => '结转';

  @override
  String get goalsDraftFromMonthly => '派生自本月目标';

  @override
  String get goalsPlaceholderMonth => '月视图骨架，下一批实现。';

  @override
  String get goalsPlaceholderYear => '年视图骨架，下一批实现。';

  @override
  String get goalsPlaceholderBlueprint => '蓝图视图骨架，下一批实现。';

  @override
  String get goalStatusDraft => '草稿';

  @override
  String get goalStatusActive => '进行中';

  @override
  String get goalStatusDone => '已完成';

  @override
  String get goalStatusCancelled => '已取消';

  @override
  String get goalSelfScore => '自评';

  @override
  String get goalDraftPending => '待确认草稿';

  @override
  String get goalMonthYearBar => '年度目标汇总';

  @override
  String get goalMonthReviewSection => '上月复盘';

  @override
  String get goalMonthReviewEmpty => '上月没有目标。';

  @override
  String get goalMonthReviewReason => '未完成原因';

  @override
  String get goalMonthReviewReasonMissing => '未完成原因缺失（仅提示，不阻断）';

  @override
  String get goalMonthImprove => '改进措施';

  @override
  String get goalMonthImproveEmpty => '（未填改进措施）';

  @override
  String get goalMonthConvertDraft => '转为本月目标草稿';

  @override
  String get goalMonthGoalsSection => '本月目标';

  @override
  String get goalMonthGoalsEmpty => '本月还没有目标。';

  @override
  String get goalMonthColumnCategory => '类别';

  @override
  String get goalMonthColumnIndex => '序号';

  @override
  String get goalMonthColumnMethods => '方法和措施';

  @override
  String get goalMonthColumnDone => '完成';

  @override
  String get goalMonthAdHoc => '临时事项';

  @override
  String get goalMonthServesYearly => '服务于年目标';

  @override
  String get goalMonthDraftEmpty => '本月没有待滚动的候选。';

  @override
  String get goalYearGoalsSection => '年度目标';

  @override
  String get goalYearGoalsEmpty => '本年度还没有目标。';

  @override
  String get goalYearColumnPeriod => '起止时间';

  @override
  String get goalYearMonthsSection => '月度展开（1–12 月）';

  @override
  String get goalYearMonthColumn => '月目标';

  @override
  String get goalYearCellEmpty => '该月未展开';

  @override
  String get goalYearCellInputHint => '输入月目标标题';

  @override
  String get goalYearCellAddDraft => '加入待确认草稿';

  @override
  String get goalYearReviewSection => '年度复盘';

  @override
  String get goalYearReviewDone => '已完成';

  @override
  String get goalYearReviewScoreTotal => '自评总分';

  @override
  String get goalYearReviewScoreAverage => '自评均值';

  @override
  String get goalYearReviewSelfNote => '自评＝用户自评，不是达成率';

  @override
  String get goalYear8020Section => '80/20 视角（只呈现，不评分、不排名）';

  @override
  String get goalYear8020Empty => '还没有可聚合的执行记录。';

  @override
  String get goalYear8020Tracks => '条执行记录';

  @override
  String get goalYearDraftEmpty => '本年度没有待滚动的候选。';

  @override
  String get goalBlueprintMatrixSection => '人生蓝图矩阵';

  @override
  String get goalBlueprintColumnGoal => '目标';

  @override
  String get goalBlueprintHorizonUltimate => '终极';

  @override
  String get goalBlueprintHorizonLong => '远期';

  @override
  String get goalBlueprintHorizonMid => '中期';

  @override
  String get goalBlueprintHorizonShort => '短期';

  @override
  String get goalBlueprintHorizonNear => '近期（1 年）';

  @override
  String get goalBlueprintEmptyCell => '（空）';

  @override
  String get goalBlueprintBlankRowHint => '整行留空合法，不校验、不报错';

  @override
  String get goalBlueprintNearSource => '近期列＝本年度年度目标（同一份数据源）';

  @override
  String get goalBlueprintActionsCount => '条做法';

  @override
  String get goalBlueprintWeeklyTarget => '周目标';

  @override
  String get goalBlueprintSplitTodos => '拆成 3 条待办';

  @override
  String get goalBlueprintPendingTodos => '待确认待办';

  @override
  String get goalBlueprintConfirmTodos => '确认写入待办';

  @override
  String get goalBlueprintBalanceSection => '平衡轮（派生，不落库）';

  @override
  String get goalBlueprintBalanceEmpty => '还没有自评数据。';

  @override
  String get goalBlueprintBalanceHabit => '习惯打卡';

  @override
  String get goalBlueprintAddGoal => '新建目标';

  @override
  String get goalBlueprintEditGoal => '编辑目标';

  @override
  String get goalBlueprintDeleteGoal => '删除目标';

  @override
  String get goalBlueprintGoalSaved => '目标已保存';

  @override
  String get goalBlueprintGoalDeleted => '目标已删除';

  @override
  String get goalBlueprintFieldDomain => '领域';

  @override
  String get goalBlueprintFieldHorizon => '档位';

  @override
  String get goalBlueprintFieldNote => '备注';

  @override
  String get goalBlueprintFieldKeywords => '关键词';

  @override
  String get goalBlueprintFieldDue => '期限';

  @override
  String get goalBlueprintFieldUnset => '未设置';

  @override
  String get goalBlueprintFieldDueInvalid => '日期格式应为 YYYY-MM-DD';
}

/// 目标页文案：English。
mixin GoalsEnL10n implements GoalsL10n {
  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsTabWeek => 'Week';

  @override
  String get goalsTabMonth => 'Month';

  @override
  String get goalsTabYear => 'Year';

  @override
  String get goalsTabBlueprint => 'Blueprint';

  @override
  String get goalsUpstreamYearTitle => 'Open yearly goals';

  @override
  String get goalsUpstreamMonthTitle => 'Open monthly goals';

  @override
  String get goalsUpstreamWeekTitle => 'Open weekly goals';

  @override
  String get goalsUpstreamAddHint => 'Click or drag to add to this period';

  @override
  String get goalsUpstreamEmpty => 'No open goals';

  @override
  String get goalsUpstreamAddMenu => 'Add to plan';

  @override
  String get goalsWeekSection => 'Weekly goals';

  @override
  String get goalsWeekEmpty => 'No weekly goals yet.';

  @override
  String get goalsColumnOrder => 'Order';

  @override
  String get goalsColumnGoal => 'Goal';

  @override
  String get goalsColumnQuadrant => 'Quadrant';

  @override
  String get goalsColumnDue => 'Due';

  @override
  String get goalsColumnDone => 'Done';

  @override
  String get goalsColumnServes => 'Serves';

  @override
  String get goalsCompletion => 'Completion';

  @override
  String get goalsPlanItems => 'Plan items';

  @override
  String get goalsUnplaced => 'Unplaced';

  @override
  String get goalsDraftSection => 'Rolling candidates';

  @override
  String get goalsDraftEmpty => 'No candidates to roll in this week.';

  @override
  String get goalsDraftConfirm => 'Save as drafts';

  @override
  String get goalsDraftSaved => 'Drafts saved';

  @override
  String get goalsDraftCarryOver => 'Carry over';

  @override
  String get goalsDraftFromMonthly => 'Derived from a monthly goal';

  @override
  String get goalsPlaceholderMonth => 'Month view placeholder - next batch.';

  @override
  String get goalsPlaceholderYear => 'Year view placeholder - next batch.';

  @override
  String get goalsPlaceholderBlueprint =>
      'Blueprint view placeholder - next batch.';

  @override
  String get goalStatusDraft => 'Draft';

  @override
  String get goalStatusActive => 'Active';

  @override
  String get goalStatusDone => 'Done';

  @override
  String get goalStatusCancelled => 'Cancelled';

  @override
  String get goalSelfScore => 'Self score';

  @override
  String get goalDraftPending => 'Pending drafts';

  @override
  String get goalMonthYearBar => 'Yearly goals summary';

  @override
  String get goalMonthReviewSection => 'Last month review';

  @override
  String get goalMonthReviewEmpty => 'No goals last month.';

  @override
  String get goalMonthReviewReason => 'Reason';

  @override
  String get goalMonthReviewReasonMissing =>
      'Missing reason (hint only, does not block)';

  @override
  String get goalMonthImprove => 'Improvement';

  @override
  String get goalMonthImproveEmpty => '(no improvement note yet)';

  @override
  String get goalMonthConvertDraft => 'Turn into a draft goal for this month';

  @override
  String get goalMonthGoalsSection => "This month's goals";

  @override
  String get goalMonthGoalsEmpty => 'No goals this month yet.';

  @override
  String get goalMonthColumnCategory => 'Category';

  @override
  String get goalMonthColumnIndex => 'No.';

  @override
  String get goalMonthColumnMethods => 'Methods';

  @override
  String get goalMonthColumnDone => 'Done';

  @override
  String get goalMonthAdHoc => 'Ad-hoc item';

  @override
  String get goalMonthServesYearly => 'Serves yearly goal';

  @override
  String get goalMonthDraftEmpty => 'No candidates to roll in this month.';

  @override
  String get goalYearGoalsSection => 'Yearly goals';

  @override
  String get goalYearGoalsEmpty => 'No goals this year yet.';

  @override
  String get goalYearColumnPeriod => 'Period';

  @override
  String get goalYearMonthsSection => 'Monthly breakdown (Jan-Dec)';

  @override
  String get goalYearMonthColumn => 'Monthly goal';

  @override
  String get goalYearCellEmpty => 'Not expanded this month';

  @override
  String get goalYearCellInputHint => 'Monthly goal title';

  @override
  String get goalYearCellAddDraft => 'Add to pending drafts';

  @override
  String get goalYearReviewSection => 'Year in review';

  @override
  String get goalYearReviewDone => 'Completed';

  @override
  String get goalYearReviewScoreTotal => 'Self-score total';

  @override
  String get goalYearReviewScoreAverage => 'Self-score average';

  @override
  String get goalYearReviewSelfNote =>
      'Self-scored by you, not an attainment rate';

  @override
  String get goalYear8020Section =>
      '80/20 view (presentation only, no scoring, no ranking)';

  @override
  String get goalYear8020Empty => 'No execution records to aggregate yet.';

  @override
  String get goalYear8020Tracks => 'execution records';

  @override
  String get goalYearDraftEmpty => 'No candidates to roll in this year.';

  @override
  String get goalBlueprintMatrixSection => 'Life blueprint matrix';

  @override
  String get goalBlueprintColumnGoal => 'Goal';

  @override
  String get goalBlueprintHorizonUltimate => 'Ultimate';

  @override
  String get goalBlueprintHorizonLong => 'Long-term';

  @override
  String get goalBlueprintHorizonMid => 'Mid-term';

  @override
  String get goalBlueprintHorizonShort => 'Short-term';

  @override
  String get goalBlueprintHorizonNear => 'Near-term (1 year)';

  @override
  String get goalBlueprintEmptyCell => '(blank)';

  @override
  String get goalBlueprintBlankRowHint =>
      'A blank row is valid - nothing is enforced';

  @override
  String get goalBlueprintNearSource =>
      "Near-term column = this year's yearly goals (same source)";

  @override
  String get goalBlueprintActionsCount => 'actions';

  @override
  String get goalBlueprintWeeklyTarget => 'Weekly goal';

  @override
  String get goalBlueprintSplitTodos => 'Split into 3 todos';

  @override
  String get goalBlueprintPendingTodos => 'Pending todos';

  @override
  String get goalBlueprintConfirmTodos => 'Create these todos';

  @override
  String get goalBlueprintBalanceSection =>
      'Balance wheel (derived, never stored)';

  @override
  String get goalBlueprintBalanceEmpty => 'No self-scores yet.';

  @override
  String get goalBlueprintBalanceHabit => 'Habit check-ins';

  @override
  String get goalBlueprintAddGoal => 'New goal';

  @override
  String get goalBlueprintEditGoal => 'Edit goal';

  @override
  String get goalBlueprintDeleteGoal => 'Delete goal';

  @override
  String get goalBlueprintGoalSaved => 'Goal saved';

  @override
  String get goalBlueprintGoalDeleted => 'Goal deleted';

  @override
  String get goalBlueprintFieldDomain => 'Domain';

  @override
  String get goalBlueprintFieldHorizon => 'Horizon';

  @override
  String get goalBlueprintFieldNote => 'Note';

  @override
  String get goalBlueprintFieldKeywords => 'Keywords';

  @override
  String get goalBlueprintFieldDue => 'Due date';

  @override
  String get goalBlueprintFieldUnset => 'Not set';

  @override
  String get goalBlueprintFieldDueInvalid => 'Use the YYYY-MM-DD format';
}
