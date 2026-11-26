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

  /// 蓝图页矩阵行头：目标（B9-W2 之后表体不再渲染表头行，键保留）。
  String get goalBlueprintColumnGoal;

  /// 蓝图档位：终极。
  String get goalBlueprintHorizonUltimate;

  /// 蓝图档位：远期。
  String get goalBlueprintHorizonLong;

  /// 蓝图档位：中期。
  String get goalBlueprintHorizonMid;

  /// 蓝图档位：短期。
  String get goalBlueprintHorizonShort;

  /// 蓝图档位：近期（1 年）（表单下拉仍有这一档，矩阵已并入短期页）。
  String get goalBlueprintHorizonNear;

  /// 蓝图档位时长（B10-B2）：终极 —— 标签页悬停提示。
  String get goalBlueprintHorizonUltimateSpan;

  /// 蓝图档位时长（B10-B2）：远期。
  String get goalBlueprintHorizonLongSpan;

  /// 蓝图档位时长（B10-B2）：中期。
  String get goalBlueprintHorizonMidSpan;

  /// 蓝图档位时长（B10-B2）：短期。
  String get goalBlueprintHorizonShortSpan;

  /// 日期列「完成」前缀（后面直接拼 `yyyy-MM-dd`）。
  String get goalBlueprintDonePrefix;

  /// 起止日期对话框标题。
  String get goalBlueprintPeriodTitle;

  /// 起止日期对话框：起始。
  String get goalBlueprintPeriodStart;

  /// 起止日期对话框：结束。
  String get goalBlueprintPeriodEnd;

  /// 蓝图页说明：整行留空合法。
  String get goalBlueprintBlankRowHint;

  /// 蓝图格：做法条数单位。
  String get goalBlueprintActionsCount;

  /// 蓝图格展开：周目标标签。
  String get goalBlueprintWeeklyTarget;

  /// 拆分层级对话框：标题（B9-W3）。
  String get goalSplitDialogTitle;

  /// 拆分层级对话框：填写说明。
  String get goalSplitDialogHint;

  /// 拆分层级对话框：目标类型选择器标签。
  String get goalSplitDialogTargetLabel;

  /// 拆分层级对话框：加一行。
  String get goalSplitDialogAddRow;

  /// 拆分层级对话框：删除这一行。
  String get goalSplitDialogRemoveRow;

  /// 拆分层级对话框：确认拆分（确认即落库）。
  String get goalSplitDialogConfirm;

  /// 拆分层级对话框：一行都没填时的提示。
  String get goalSplitDialogEmptyRow;

  /// 拆分层级对话框：写入成功的提示。
  String get goalSplitDialogSaved;

  /// 拆分层级对话框：写入失败的提示。
  String get goalSplitDialogFailed;

  /// 拆分层级对话框：目标类型「年目标」。
  String get goalSplitTargetYearly;

  /// 拆分层级对话框：目标类型「待办任务」。
  String get goalSplitTargetTodo;

  /// 拆分层级对话框：确认即落库的说明。
  String get goalSplitDialogNote;

  /// 蓝图页平衡轮区块标题（纯派生，不落库）。
  String get goalBlueprintBalanceSection;

  /// 蓝图页平衡轮空态。
  String get goalBlueprintBalanceEmpty;

  /// 蓝图页平衡轮：习惯打卡标签。
  String get goalBlueprintBalanceHabit;

  /// 蓝图格：新建目标入口（B8-W1）；也是空格「+」按钮的 tooltip。
  String get goalBlueprintAddGoal;

  /// 蓝图空格子上的「+」符号（B9-W2）。
  String get goalBlueprintAddSymbol;

  /// 蓝图卡片上的「拆分」入口（B9-W2）。
  String get goalBlueprintSplit;

  /// 短期标签页的来源说明（B9-W2）。
  String get goalBlueprintShortTabNote;

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

  // ---------------------------------------------------------------------------
  // 个人品牌管理面板（B9-W1，54 条）
  // ---------------------------------------------------------------------------

  /// 品牌面板：模块标题。
  String get goalBrandSection;

  /// 品牌面板：保存按钮。
  String get goalBrandSave;

  /// 品牌面板：保存成功反馈。
  String get goalBrandSaved;

  /// 品牌面板：保存失败反馈。
  String get goalBrandSaveFailed;

  /// 品牌面板：该切面尚无内容。
  String get goalBrandEmpty;

  /// 品牌面板：标题输入框标签。
  String get goalBrandTitleLabel;

  /// 品牌面板：补充说明输入框标签。
  String get goalBrandNoteLabel;

  /// 品牌面板：左侧切面导航的小标题。
  String get goalBrandFacetNavLabel;

  /// 品牌面板：指引块标题。
  String get goalBrandGuideTitle;

  /// 品牌面板：指引 · 定位公式。
  String get goalBrandGuideFormula;

  /// 品牌面板：指引 · 三层结构。
  String get goalBrandGuideLayers;

  /// 品牌面板：指引 · 三步方法论。
  String get goalBrandGuideMethod;

  /// 品牌面板：指引 · PBE 三维诊断。
  String get goalBrandGuidePbe;

  /// 品牌面板：指引块展开 / 收起。
  String get goalBrandGuideToggle;

  /// 切面 statement：标签。
  String get goalBrandFacetStatement;

  /// 切面 statement：要点。
  String get goalBrandFacetStatementHint;

  /// 切面 statement：范例。
  String get goalBrandFacetStatementExample;

  /// 切面 statement：反例。
  String get goalBrandFacetStatementCounterExample;

  /// 切面 word：标签。
  String get goalBrandFacetWord;

  /// 切面 word：要点。
  String get goalBrandFacetWordHint;

  /// 切面 word：范例。
  String get goalBrandFacetWordExample;

  /// 切面 word：反例。
  String get goalBrandFacetWordCounterExample;

  /// 切面 audience：标签。
  String get goalBrandFacetAudience;

  /// 切面 audience：要点。
  String get goalBrandFacetAudienceHint;

  /// 切面 audience：范例。
  String get goalBrandFacetAudienceExample;

  /// 切面 audience：反例。
  String get goalBrandFacetAudienceCounterExample;

  /// 切面 promise：标签。
  String get goalBrandFacetPromise;

  /// 切面 promise：要点。
  String get goalBrandFacetPromiseHint;

  /// 切面 promise：范例。
  String get goalBrandFacetPromiseExample;

  /// 切面 promise：反例。
  String get goalBrandFacetPromiseCounterExample;

  /// 切面 cost：标签。
  String get goalBrandFacetCost;

  /// 切面 cost：要点。
  String get goalBrandFacetCostHint;

  /// 切面 cost：范例。
  String get goalBrandFacetCostExample;

  /// 切面 cost：反例。
  String get goalBrandFacetCostCounterExample;

  /// 切面 evidence：标签。
  String get goalBrandFacetEvidence;

  /// 切面 evidence：要点。
  String get goalBrandFacetEvidenceHint;

  /// 切面 evidence：范例。
  String get goalBrandFacetEvidenceExample;

  /// 切面 evidence：反例。
  String get goalBrandFacetEvidenceCounterExample;

  /// 切面 contrast：标签。
  String get goalBrandFacetContrast;

  /// 切面 contrast：要点。
  String get goalBrandFacetContrastHint;

  /// 切面 contrast：范例。
  String get goalBrandFacetContrastExample;

  /// 切面 contrast：反例。
  String get goalBrandFacetContrastCounterExample;

  /// 切面 strength：标签。
  String get goalBrandFacetStrength;

  /// 切面 strength：要点。
  String get goalBrandFacetStrengthHint;

  /// 切面 strength：范例。
  String get goalBrandFacetStrengthExample;

  /// 切面 strength：反例。
  String get goalBrandFacetStrengthCounterExample;

  /// 切面 errc：标签。
  String get goalBrandFacetErrc;

  /// 切面 errc：要点。
  String get goalBrandFacetErrcHint;

  /// 切面 errc：范例。
  String get goalBrandFacetErrcExample;

  /// 切面 errc：反例。
  String get goalBrandFacetErrcCounterExample;

  /// 切面 identity：标签。
  String get goalBrandFacetIdentity;

  /// 切面 identity：要点。
  String get goalBrandFacetIdentityHint;

  /// 切面 identity：范例。
  String get goalBrandFacetIdentityExample;

  /// 切面 identity：反例。
  String get goalBrandFacetIdentityCounterExample;

  // ---------------------------------------------------------------------------
  // B10-D1 个人定位（4 项问答 + 标签库）
  // ---------------------------------------------------------------------------

  /// 「个人定位」段标题。
  String get goalPositionSection;

  /// 价值观：标题。
  String get goalPositionValuesTitle;

  /// 价值观：要点指引。
  String get goalPositionValuesHint;

  /// 优势：标题。
  String get goalPositionStrengthsTitle;

  /// 优势：要点指引。
  String get goalPositionStrengthsHint;

  /// 独特价值：标题。
  String get goalPositionValueTitle;

  /// 独特价值：要点指引。
  String get goalPositionValueHint;

  /// 信任背书：标题。
  String get goalPositionProofTitle;

  /// 信任背书：要点指引。
  String get goalPositionProofHint;

  /// 标签浮层标题。
  String get goalPositionTagsTitle;

  /// 价值观标签库（Schwartz 基本价值理论 10 项）。
  List<String> get goalPositionValueTags;

  /// 优势标签库（VIA 24 项性格优势）。
  List<String> get goalPositionStrengthTags;
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
  String get goalBlueprintHorizonUltimateSpan => '60 岁以后';

  @override
  String get goalBlueprintHorizonLongSpan => '约 10 年内';

  @override
  String get goalBlueprintHorizonMidSpan => '约 5 年内';

  @override
  String get goalBlueprintHorizonShortSpan => '约 3 年内';

  @override
  String get goalBlueprintDonePrefix => '完成：';

  @override
  String get goalBlueprintPeriodTitle => '起止日期';

  @override
  String get goalBlueprintPeriodStart => '起始';

  @override
  String get goalBlueprintPeriodEnd => '结束';

  @override
  String get goalBlueprintBlankRowHint => '整行留空合法，不校验、不报错';

  @override
  String get goalBlueprintActionsCount => '条做法';

  @override
  String get goalBlueprintWeeklyTarget => '周目标';

  @override
  String get goalSplitDialogTitle => '拆分目标';

  @override
  String get goalSplitDialogHint => '每行一条；留空的行会被忽略。';

  @override
  String get goalSplitDialogTargetLabel => '拆成';

  @override
  String get goalSplitDialogAddRow => '加一行';

  @override
  String get goalSplitDialogRemoveRow => '删除这一行';

  @override
  String get goalSplitDialogConfirm => '确认拆分';

  @override
  String get goalSplitDialogEmptyRow => '至少填写一行子目标';

  @override
  String get goalSplitDialogSaved => '已拆分并写入对应表格';

  @override
  String get goalSplitDialogFailed => '拆分写入失败，请重试';

  @override
  String get goalSplitTargetYearly => '年目标';

  @override
  String get goalSplitTargetTodo => '待办任务';

  @override
  String get goalSplitDialogNote => '确认后直接写入对应表格，不再经过待确认队列。';

  @override
  String get goalBlueprintBalanceSection => '平衡轮（派生，不落库）';

  @override
  String get goalBlueprintBalanceEmpty => '还没有自评数据。';

  @override
  String get goalBlueprintBalanceHabit => '习惯打卡';

  @override
  String get goalBlueprintAddGoal => '新建目标';

  @override
  String get goalBlueprintAddSymbol => '+';

  @override
  String get goalBlueprintSplit => '拆分';

  @override
  String get goalBlueprintShortTabNote => '短期页含「近期（1 年）」：1 年蓝图目标与本年度年目标。';

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

  // ---------------------------------------------------------------------------
  // 个人品牌管理（B9 W1）
  // ---------------------------------------------------------------------------

  @override
  String get goalBrandSection => '个人品牌管理';

  @override
  String get goalBrandSave => '保存';

  @override
  String get goalBrandSaved => '已保存';

  @override
  String get goalBrandSaveFailed => '保存失败';

  @override
  String get goalBrandEmpty => '这一面还空着，写下第一句就算开始。';

  @override
  String get goalBrandTitleLabel => '这一面怎么说';

  @override
  String get goalBrandNoteLabel => '补充说明';

  @override
  String get goalBrandFacetNavLabel => '切面';

  @override
  String get goalBrandGuideTitle => '个人品牌建设全解';

  @override
  String get goalBrandGuideFormula =>
      '我帮助【目标人群】，在【具体场景】下，解决【什么问题】，通过【我的独特方法】，达到【什么结果】。';

  @override
  String get goalBrandGuideLayers => '三层结构：内在内核 → 能力价值 → 外在感知';

  @override
  String get goalBrandGuideMethod => '三步方法论：定位 → 呈现 → 传播';

  @override
  String get goalBrandGuidePbe => 'PBE 三维诊断：吸引力 × 差异化 × 认知度';

  @override
  String get goalBrandGuideToggle => '展开 / 收起指引';

  @override
  String get goalBrandFacetStatement => '定位语句';

  @override
  String get goalBrandFacetStatementHint =>
      '一句话说清「我是谁 / 为谁 / 解决什么 / 凭什么 / 带来什么结果」；窄而深，胜过面面俱到';

  @override
  String get goalBrandFacetStatementExample =>
      '我帮小微餐饮老板用一套 7 天菜单改造流程，把外卖差评率压到 3% 以内';

  @override
  String get goalBrandFacetStatementCounterExample => '我是一个热爱学习、追求成长的优秀青年';

  @override
  String get goalBrandFacetWord => '心智一词';

  @override
  String get goalBrandFacetWordHint => '一个别人提起你就会想到的词；它替你的方法命名，不是形容性格';

  @override
  String get goalBrandFacetWordExample => '「菜单医生」——一听就知道解决的是菜单问题';

  @override
  String get goalBrandFacetWordCounterExample => '努力 / 靠谱 / 优秀';

  @override
  String get goalBrandFacetAudience => '对象（他人视角）';

  @override
  String get goalBrandFacetAudienceHint => '先写给谁看；默认最重要的一面，它决定别人怎么介绍你';

  @override
  String get goalBrandFacetAudienceExample => '刚开业半年、靠一份外卖撑生意的小微餐饮店主';

  @override
  String get goalBrandFacetAudienceCounterExample => '所有人；或只写「同行」';

  @override
  String get goalBrandFacetPromise => '承诺结果';

  @override
  String get goalBrandFacetPromiseHint => '承诺一个可验证的结果，不是一个动作；对方能拿它对账';

  @override
  String get goalBrandFacetPromiseExample => '90 天内把单店月毛利从 3 万提到 4.5 万';

  @override
  String get goalBrandFacetPromiseCounterExample => '帮你做好菜单、持续赋能';

  @override
  String get goalBrandFacetCost => '规避的代价';

  @override
  String get goalBrandFacetCostHint => '写清你不愿承担什么代价；这是筛选同行的开关';

  @override
  String get goalBrandFacetCostExample => '不接没有真实门店、只想白嫖方案的单子';

  @override
  String get goalBrandFacetCostCounterExample => '什么都接、什么钱都赚';

  @override
  String get goalBrandFacetEvidence => '可信证据';

  @override
  String get goalBrandFacetEvidenceHint => '列出可核验的事实：做过多少家、什么结果、谁在背书';

  @override
  String get goalBrandFacetEvidenceExample =>
      '已陪跑 23 家门店，其中 11 家差评率下降 50% 以上；3 位老板可写推荐语';

  @override
  String get goalBrandFacetEvidenceCounterExample => '我很有经验、业内口碑不错';

  @override
  String get goalBrandFacetContrast => '对立面';

  @override
  String get goalBrandFacetContrastHint => '你的对照组是谁；写清「我不做什么」，别人才知道何时找你';

  @override
  String get goalBrandFacetContrastExample => '不做纯设计外包，不接只改海报不出方案的活';

  @override
  String get goalBrandFacetContrastCounterExample => '空着；或只写「和别人不一样」';

  @override
  String get goalBrandFacetStrength => '三环交叉';

  @override
  String get goalBrandFacetStrengthHint => '专业能力 × 独特优势 × 价值主张的交集；交集之外别人也能做到';

  @override
  String get goalBrandFacetStrengthExample =>
      '餐饮后厨 8 年经验（专业）× 懂平台流量规则（优势）× 能让店真的赚钱（主张）';

  @override
  String get goalBrandFacetStrengthCounterExample => '我热爱美食、擅长沟通';

  @override
  String get goalBrandFacetErrc => '剔除 / 减少 / 增加 / 创造';

  @override
  String get goalBrandFacetErrcHint => '对现状做四种手术；这是你的方法论本体';

  @override
  String get goalBrandFacetErrcExample =>
      '剔除无效套餐；减少出品工序；增加复购触达；创造「7 天改造陪跑」这一交付形态';

  @override
  String get goalBrandFacetErrcCounterExample => '全面升级、优化体验';

  @override
  String get goalBrandFacetIdentity => '身份声明';

  @override
  String get goalBrandFacetIdentityHint => '你要成为什么样的人；内在内核，决定十年后还在不在同一件事上';

  @override
  String get goalBrandFacetIdentityExample => '我是那个让小餐饮老板敢把菜单交给我的人';

  @override
  String get goalBrandFacetIdentityCounterExample => '我是一个不断学习的人';

  // B10-D1 个人定位
  @override
  String get goalPositionSection => '个人定位';

  @override
  String get goalPositionValuesTitle => '我的价值观';

  @override
  String get goalPositionValuesHint =>
      '写下你真正在意的 2–4 条价值取向，它们决定你长期愿意为什么付出代价；可从标签库点选后改写';

  @override
  String get goalPositionStrengthsTitle => '我的优势';

  @override
  String get goalPositionStrengthsHint =>
      '挑 3–5 项最像你的性格优势，各补一句具体表现（什么时候、做过什么）；可从标签库点选后改写';

  @override
  String get goalPositionValueTitle => '独特价值';

  @override
  String get goalPositionValueHint => '你能解决什么问题、在什么领域解决；写给谁，替代了谁的什么方案';

  @override
  String get goalPositionProofTitle => '信任背书';

  @override
  String get goalPositionProofHint => '我凭什么塑造这个优势：可核验的案例、数据、资质或口碑，一条一句';

  @override
  String get goalPositionTagsTitle => '点击标签填入';

  @override
  List<String> get goalPositionValueTags => const <String>[
    '自我导向',
    '刺激',
    '享乐',
    '成就',
    '权力',
    '安全',
    '遵从',
    '传统',
    '仁善',
    '普世主义',
  ];

  @override
  List<String> get goalPositionStrengthTags => const <String>[
    '创造力',
    '好奇心',
    '开放思维',
    '好学',
    '洞察力',
    '勇敢',
    '坚持',
    '真诚',
    '热情',
    '爱',
    '善良',
    '社交智力',
    '团队精神',
    '公平',
    '领导力',
    '宽恕',
    '谦逊',
    '审慎',
    '自我调节',
    '欣赏美与卓越',
    '感恩',
    '希望',
    '幽默',
    '灵性',
  ];
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
  String get goalBlueprintHorizonUltimateSpan => 'After 60';

  @override
  String get goalBlueprintHorizonLongSpan => 'Within ~10 years';

  @override
  String get goalBlueprintHorizonMidSpan => 'Within ~5 years';

  @override
  String get goalBlueprintHorizonShortSpan => 'Within ~3 years';

  @override
  String get goalBlueprintDonePrefix => 'Done: ';

  @override
  String get goalBlueprintPeriodTitle => 'Date range';

  @override
  String get goalBlueprintPeriodStart => 'Start';

  @override
  String get goalBlueprintPeriodEnd => 'End';

  @override
  String get goalBlueprintBlankRowHint =>
      'A blank row is valid - nothing is enforced';

  @override
  String get goalBlueprintActionsCount => 'actions';

  @override
  String get goalBlueprintWeeklyTarget => 'Weekly goal';

  @override
  String get goalSplitDialogTitle => 'Split goal';

  @override
  String get goalSplitDialogHint => 'One per line; blank rows are ignored.';

  @override
  String get goalSplitDialogTargetLabel => 'Split into';

  @override
  String get goalSplitDialogAddRow => 'Add row';

  @override
  String get goalSplitDialogRemoveRow => 'Remove this row';

  @override
  String get goalSplitDialogConfirm => 'Confirm split';

  @override
  String get goalSplitDialogEmptyRow => 'Fill in at least one row';

  @override
  String get goalSplitDialogSaved => 'Split and saved to the matching table';

  @override
  String get goalSplitDialogFailed => 'Split failed, please retry';

  @override
  String get goalSplitTargetYearly => 'Yearly goals';

  @override
  String get goalSplitTargetTodo => 'Todo tasks';

  @override
  String get goalSplitDialogNote =>
      'Confirming writes straight to the matching table — no pending queue.';

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
  String get goalBlueprintAddSymbol => 'Add';

  @override
  String get goalBlueprintSplit => 'Split';

  @override
  String get goalBlueprintShortTabNote =>
      "This tab also carries near-term (1 year) goals and this year's yearly goals.";

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

  // ---------------------------------------------------------------------------
  // Personal brand (B9 W1)
  // ---------------------------------------------------------------------------

  @override
  String get goalBrandSection => 'Personal brand';

  @override
  String get goalBrandSave => 'Save';

  @override
  String get goalBrandSaved => 'Saved';

  @override
  String get goalBrandSaveFailed => 'Save failed';

  @override
  String get goalBrandEmpty =>
      'This facet is still empty — one sentence is enough to start.';

  @override
  String get goalBrandTitleLabel => 'How you say it';

  @override
  String get goalBrandNoteLabel => 'Notes';

  @override
  String get goalBrandFacetNavLabel => 'Facets';

  @override
  String get goalBrandGuideTitle => 'Personal brand, end to end';

  @override
  String get goalBrandGuideFormula =>
      'I help 【audience】, in 【situation】, solve 【problem】, through 【my method】, to reach 【result】.';

  @override
  String get goalBrandGuideLayers =>
      'Three layers: inner core → value → visible image';

  @override
  String get goalBrandGuideMethod => 'Three steps: position → present → spread';

  @override
  String get goalBrandGuidePbe =>
      'PBE diagnosis: attraction × differentiation × awareness';

  @override
  String get goalBrandGuideToggle => 'Show / hide the guide';

  @override
  String get goalBrandFacetStatement => 'Positioning statement';

  @override
  String get goalBrandFacetStatementHint =>
      'Say who you are, for whom, what you solve, on what grounds, to what result — narrow and deep beats broad.';

  @override
  String get goalBrandFacetStatementExample =>
      'I help small restaurant owners cut delivery review complaints below 3% with a 7-day menu overhaul.';

  @override
  String get goalBrandFacetStatementCounterExample =>
      'I am a passionate, growth-oriented young person.';

  @override
  String get goalBrandFacetWord => 'One word';

  @override
  String get goalBrandFacetWordHint =>
      'A word people think of when they hear your name; it names your method, not your personality.';

  @override
  String get goalBrandFacetWordExample =>
      '"Menu Doctor" — you instantly know it is about menus.';

  @override
  String get goalBrandFacetWordCounterExample =>
      'Hardworking / reliable / excellent.';

  @override
  String get goalBrandFacetAudience => 'Audience (how others see you)';

  @override
  String get goalBrandFacetAudienceHint =>
      'Write for someone specific first; the most important facet, it decides how others introduce you.';

  @override
  String get goalBrandFacetAudienceExample =>
      'Small restaurant owners who opened six months ago and live on a single delivery brand.';

  @override
  String get goalBrandFacetAudienceCounterExample =>
      'Everyone; or just "peers".';

  @override
  String get goalBrandFacetPromise => 'Promise';

  @override
  String get goalBrandFacetPromiseHint =>
      'Promise a verifiable result, not an activity; they can hold you to it.';

  @override
  String get goalBrandFacetPromiseExample =>
      'Lift a single store from 30k to 45k monthly gross profit within 90 days.';

  @override
  String get goalBrandFacetPromiseCounterExample =>
      'Help you fix your menu, keep empowering you.';

  @override
  String get goalBrandFacetCost => 'Cost you avoid';

  @override
  String get goalBrandFacetCostHint =>
      'State the cost you refuse to bear; this is what filters the people you work with.';

  @override
  String get goalBrandFacetCostExample =>
      'I do not take clients without a real storefront who only want free plans.';

  @override
  String get goalBrandFacetCostCounterExample =>
      'Take everything, earn from anything.';

  @override
  String get goalBrandFacetEvidence => 'Proof';

  @override
  String get goalBrandFacetEvidenceHint =>
      'List verifiable facts: how many stores, what result, who vouches for you.';

  @override
  String get goalBrandFacetEvidenceExample =>
      'Coached 23 stores, 11 cut review complaints by over 50%; 3 owners will write a testimonial.';

  @override
  String get goalBrandFacetEvidenceCounterExample =>
      'I am very experienced with a good reputation.';

  @override
  String get goalBrandFacetContrast => 'Opposite';

  @override
  String get goalBrandFacetContrastHint =>
      'Name your comparison group; by saying what you do not do, people learn when to call you.';

  @override
  String get goalBrandFacetContrastExample =>
      'No pure design outsourcing, no poster-only jobs without a plan.';

  @override
  String get goalBrandFacetContrastCounterExample =>
      'Leave it blank; or write "different from others".';

  @override
  String get goalBrandFacetStrength => 'Three-circle overlap';

  @override
  String get goalBrandFacetStrengthHint =>
      'The overlap of skill × edge × value proposition; outside the overlap anyone can do it.';

  @override
  String get goalBrandFacetStrengthExample =>
      '8 years in restaurant kitchens (skill) × platform traffic rules (edge) × stores that actually make money (proposition).';

  @override
  String get goalBrandFacetStrengthCounterExample =>
      'I love food and communicate well.';

  @override
  String get goalBrandFacetErrc => 'Eliminate / reduce / raise / create';

  @override
  String get goalBrandFacetErrcHint =>
      'Four surgeries on the status quo; this is your method itself.';

  @override
  String get goalBrandFacetErrcExample =>
      'Eliminate dead combos; reduce kitchen steps; raise repeat-visit touchpoints; create the "7-day overhaul coaching" delivery form.';

  @override
  String get goalBrandFacetErrcCounterExample =>
      'Comprehensive upgrade, better experience.';

  @override
  String get goalBrandFacetIdentity => 'Identity';

  @override
  String get goalBrandFacetIdentityHint =>
      'What kind of person you are becoming; the inner core that decides whether you are still here in ten years.';

  @override
  String get goalBrandFacetIdentityExample =>
      'I am the one small restaurant owners trust with their menu.';

  @override
  String get goalBrandFacetIdentityCounterExample =>
      'I am someone who keeps learning.';

  // B10-D1 Personal Positioning
  @override
  String get goalPositionSection => 'Personal Positioning';

  @override
  String get goalPositionValuesTitle => 'My values';

  @override
  String get goalPositionValuesHint =>
      'Write down the 2-4 values you actually care about; they decide what you are willing to pay for over time. Click a tag to start, then rewrite it in your own words.';

  @override
  String get goalPositionStrengthsTitle => 'My strengths';

  @override
  String get goalPositionStrengthsHint =>
      'Pick the 3-5 character strengths that fit you best and add one concrete example each (when, and what you did). Click a tag to start, then rewrite it.';

  @override
  String get goalPositionValueTitle => 'Unique value';

  @override
  String get goalPositionValueHint =>
      'What problem you solve, and in which field; who you serve and whose approach you replace.';

  @override
  String get goalPositionProofTitle => 'Proof of trust';

  @override
  String get goalPositionProofHint =>
      'Why you can build this strength: verifiable cases, numbers, credentials or reputation, one per line.';

  @override
  String get goalPositionTagsTitle => 'Click a tag to fill in';

  @override
  List<String> get goalPositionValueTags => const <String>[
    'Self-direction',
    'Stimulation',
    'Hedonism',
    'Achievement',
    'Power',
    'Security',
    'Conformity',
    'Tradition',
    'Benevolence',
    'Universalism',
  ];

  @override
  List<String> get goalPositionStrengthTags => const <String>[
    'Creativity',
    'Curiosity',
    'Open-mindedness',
    'Love of learning',
    'Perspective',
    'Bravery',
    'Perseverance',
    'Honesty',
    'Zest',
    'Love',
    'Kindness',
    'Social intelligence',
    'Teamwork',
    'Fairness',
    'Leadership',
    'Forgiveness',
    'Humility',
    'Prudence',
    'Self-regulation',
    'Appreciation of beauty and excellence',
    'Gratitude',
    'Hope',
    'Humor',
    'Spirituality',
  ];
}
