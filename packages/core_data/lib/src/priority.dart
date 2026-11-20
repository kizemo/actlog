// =============================================================================
// core_data · 优先级显示层规则（P1-4 / P1-5）
// =============================================================================
// 铁律（来自 core_domain/enums.dart 的注释，这里必须字面遵守）：
//   1. 数据里 quadrant 与 priorityAbc **都存着**，显示模式只决定渲染哪一套。
//   2. 同一时刻只显示一套标签 —— 绝不能两个字段一起画到界面上。
//   3. 完整版日志的「A 类要事」，在四象限模式下 = Q1 + Q2。
//   4. 四象限不是《五项管理》体系的组成部分，对外不得这么表述。
//
// 因此本文件里**没有任何「把象限写回 ABC」的函数**。切换显示模式是纯渲染动作，
// 不产生数据库写入 —— 这是「两种模式互斥且切换无损」的实现方式。
// =============================================================================

import 'package:core_domain/core_domain.dart';

/// 四象限的展示元数据（文案 / 提示色 / 行动建议）。
final class QuadrantStyle {
  /// 创建元数据。
  const QuadrantStyle({
    required this.quadrant,
    required this.label,
    required this.shortLabel,
    required this.advice,
    required this.colorHex,
  });

  /// 象限。
  final Quadrant quadrant;

  /// 完整名称（如「重要且紧急」）。
  ///
  /// 这是**兜底文案**，仅供无 `BuildContext` 的场合（日志导出、调试）。
  /// 界面一律取 [labelKey] 去 l10n 里查，不要直接渲染本字段；
  /// 本字段在 W9 波次随 l10n 全量收敛一并删除。
  final String label;

  /// 宫格内的短名（如「立即做」）。
  ///
  /// 同 [label]：兜底文案，界面取 [shortLabelKey]，本字段 W9 删除。
  final String shortLabel;

  /// 行动建议文案。
  final String advice;

  /// 提示色（`#RRGGBB`，UI 层解析；此处不依赖 Flutter）。
  final String colorHex;

  /// 全部四象限的展示元数据表。
  static const Map<Quadrant, QuadrantStyle> all = {
    Quadrant.q1: QuadrantStyle(
      quadrant: Quadrant.q1,
      label: '重要且紧急',
      shortLabel: '立即做',
      advice: '马上处理，别让它变成危机',
      colorHex: '#D9534F',
    ),
    Quadrant.q2: QuadrantStyle(
      quadrant: Quadrant.q2,
      label: '重要不紧急',
      shortLabel: '计划做',
      advice: '安排固定时段，这里决定长期差距',
      colorHex: '#2E8B57',
    ),
    Quadrant.q3: QuadrantStyle(
      quadrant: Quadrant.q3,
      label: '紧急不重要',
      shortLabel: '委托做',
      advice: '能授权就授权，别用忙碌换取心安',
      colorHex: '#E0A030',
    ),
    Quadrant.q4: QuadrantStyle(
      quadrant: Quadrant.q4,
      label: '不重要不紧急',
      shortLabel: '少做',
      advice: '能砍就砍，先问它值不值得占一格',
      colorHex: '#7A7A7A',
    ),
  };

  /// 取某象限的元数据；未知值返回 Q4 的样式（不抛异常）。
  static QuadrantStyle of(Quadrant? quadrant) =>
      all[quadrant ?? Quadrant.q4]!;

  /// [label] 对应的 l10n 键（`domain-quadrant-q1-label` 等）。
  ///
  /// 包层只出 id、不出文案：宿主拿到键自己去查当前语言。
  String get labelKey => 'domain-quadrant-${quadrant.code.toLowerCase()}-label';

  /// [shortLabel] 对应的 l10n 键（`domain-quadrant-q1-short-label` 等）。
  String get shortLabelKey =>
      'domain-quadrant-${quadrant.code.toLowerCase()}-short-label';
}

/// ABC 的展示元数据。
final class AbcStyle {
  /// 创建元数据。
  const AbcStyle({
    required this.priority,
    required this.label,
    required this.description,
  });

  /// 优先级。
  final PriorityAbc priority;

  /// 标签（如「A 类要事」）。
  ///
  /// 兜底文案，界面取 [labelKey] 去 l10n 里查；本字段 W9 波次删除。
  final String label;

  /// 说明。
  final String description;

  /// 三条优先级的展示元数据表。
  static const Map<PriorityAbc, AbcStyle> all = {
    PriorityAbc.a: AbcStyle(
      priority: PriorityAbc.a,
      label: 'A 类要事',
      description: '必须今天完成，做不完就是当天失败',
    ),
    PriorityAbc.b: AbcStyle(
      priority: PriorityAbc.b,
      label: 'B 类次要',
      description: '应该做，可在 A 类之后推进',
    ),
    PriorityAbc.c: AbcStyle(
      priority: PriorityAbc.c,
      label: 'C 类一般',
      description: '有空再做，不做也不影响目标',
    ),
  };

  /// 取某优先级的元数据；未知值返回 C 的样式（不抛异常）。
  static AbcStyle of(PriorityAbc? priority) =>
      all[priority ?? PriorityAbc.c]!;

  /// [label] 对应的 l10n 键（`domain-abc-a-label` 等）。
  String get labelKey => 'domain-abc-${priority.code.toLowerCase()}-label';
}

/// 显示模式相关的纯函数集合。
abstract final class PriorityDisplay {
  /// 四象限模式下表头显示的「A 类 = Q1 + Q2」联动提示。
  static const String quadrantHeaderHint = 'A 类 = Q1 + Q2';

  /// ABC 模式下表头显示的提示。
  static const String abcHeaderHint = 'A 类要事优先安排';

  /// 两种模式都没分级时的显示文案（兜底值）。
  ///
  /// 界面一律取 [unsetLabelKey]；本常量仅供无 `BuildContext` 的场合。
  static const String unsetLabel = '未分级';

  /// [unsetLabel] 对应的 l10n 键。
  static const String unsetLabelKey = 'domain-priority-unset-label';

  /// 当前模式对应的表头提示。
  static String headerHint(PriorityDisplayMode mode) =>
      mode == PriorityDisplayMode.quadrant ? quadrantHeaderHint : abcHeaderHint;

  /// 当前模式下要渲染的标签文本。
  ///
  /// **只返回一套**：四象限模式返回象限名，ABC 模式返回优先级名。
  /// 两者都为空时返回 [unsetLabel]。
  ///
  /// 这是兜底文案；界面请用 [labelKeyFor] 拿 id 再查 l10n。
  /// 本方法在 W9 波次随 l10n 全量收敛一并删除。
  static String labelFor(
    PriorityDisplayMode mode, {
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
  }) {
    if (mode == PriorityDisplayMode.quadrant) {
      return quadrant == null ? unsetLabel : QuadrantStyle.of(quadrant).label;
    }
    return priorityAbc == null ? unsetLabel : AbcStyle.of(priorityAbc).label;
  }

  /// [labelFor] 对应的 l10n 键（一一对应，含未分级的兜底键）。
  static String labelKeyFor(
    PriorityDisplayMode mode, {
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
  }) {
    if (mode == PriorityDisplayMode.quadrant) {
      return quadrant == null
          ? unsetLabelKey
          : QuadrantStyle.of(quadrant).labelKey;
    }
    return priorityAbc == null ? unsetLabelKey : AbcStyle.of(priorityAbc).labelKey;
  }

  /// 条目的排序权重（越小越靠前），用于「今日优先」排序。
  ///
  /// 四象限模式按 (重要, 紧急) 排；ABC 模式按 A<B<C 排。
  /// 未分级的条目一律排在最后 —— 它们不该挤掉已分级的要事。
  static int sortWeight(
    PriorityDisplayMode mode, {
    Quadrant? quadrant,
    PriorityAbc? priorityAbc,
  }) {
    if (mode == PriorityDisplayMode.quadrant) {
      if (quadrant == null) {
        return 99;
      }
      switch (quadrant) {
        case Quadrant.q1:
          return 0;
        case Quadrant.q2:
          return 1;
        case Quadrant.q3:
          return 2;
        case Quadrant.q4:
          return 3;
      }
    }
    if (priorityAbc == null) {
      return 99;
    }
    switch (priorityAbc) {
      case PriorityAbc.a:
        return 0;
      case PriorityAbc.b:
        return 1;
      case PriorityAbc.c:
        return 2;
    }
  }

  /// 该条目在四象限模式下是否算「A 类要事」。
  ///
  /// 这是**只读派生**，不写库。用于完整版日志里「A 类要事」小节的筛选。
  static bool isClassAUnderQuadrant(Quadrant? quadrant) =>
      quadrant == Quadrant.q1 || quadrant == Quadrant.q2;
}