// =============================================================================
// 目标 · 按类别分区 + 分类小标题的共享渲染件（B17-W2）
// =============================================================================
// 用途（B17 F 条）：目标周 / 月 / 年三页（波 C）与蓝图矩阵将来共用同一套
// 「类别分区 + 小标题」渲染，避免四个 worker 各写一套。
//
// 三条口径：
//  1. **只渲染，不分组**：`groups` 直接来自 `goal_category.dart` 的
//     `groupGoalsByCategory(...)`（W0 唯一真源，顺序 = 预设 → 自定义按首次
//     出现 → 未分类垫底）。本文件**不重新排序**、不猜类别。
//  2. **不加载数据、不写库**：行内容全部由调用方的 `rowBuilder` 产出。
//  3. **ValueKey 契约**（波 C 四棒照用，逐字）：
//       * 分区容器 `goal-section-<displayKey>`
//       * 分区小标题 `goal-section-title-<displayKey>`
//       * 空态文本 `goal-section-empty`（仅 `emptyText != null` 时）
//
// 为什么除 `GoalCategorySections` 外还留一个泛型件：W0 的
// `groupGoalsByCategory` 只吃 `List<Goal>`（领域模型，构造需要
// `originDeviceId`），而三页渲染的是读侧模型 `GoalRow`
// （`data/goal_store.dart`，没有 `originDeviceId`）⇒ 波 C 无法把 `GoalRow`
// 喂进去，也无法在**不改** `goal_category.dart`（W0 写集）的前提下解耦。
// 因此这里补 `GoalSectionGroup<T>` / `groupSectionsByCategory<T>` /
// `GoalSectionList<T>`：排序与标题仍全部委托 `goal_category.dart` 的常量与
// 函数（`goalCategoryKeys` / `goalCategoryDisplayKey` / `goalCategoryTitle`），
// 只把「分桶」这一层泛化 —— 三页传 `GoalRow` + `domainOf: (r) => r.domain`
// 即可，不必各自再写第五套分组。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'goal_category.dart';

/// 一个类别分区（泛型版：行模型可以是 `Goal`，也可以是读侧的 `GoalRow`）。
class GoalSectionGroup<T> {
  /// 构造分区。
  const GoalSectionGroup({
    required this.displayKey,
    required this.title,
    required this.items,
  });

  /// 稳定标识（预设 key / `custom:<文本>` / `none`）；用于 `ValueKey`。
  final String displayKey;

  /// 分区小标题（已本地化；自定义类别是用户文本）。
  final String title;

  /// 组内条目，**保持传入顺序**。
  final List<T> items;
}

/// 按类别分桶（泛型版）。
///
/// 顺序与 `goal_category.dart` 的 `groupGoalsByCategory` **完全一致**：
/// 五个预设（空组不出）→ 自定义（按首次出现）→ 未分类垫底；组内保持传入
/// 顺序。差异只有两点：条目类型泛型、类别取自 [domainOf]。
///
/// 排序所依赖的常量与标题函数全部来自 `goal_category.dart`（唯一真源），
/// 本函数只负责分桶。
List<GoalSectionGroup<T>> groupSectionsByCategory<T>(
  AppLocalizations t,
  List<T> items, {
  required String? Function(T item) domainOf,
}) {
  final Map<String, List<T>> buckets = <String, List<T>>{};
  final List<String> customOrder = <String>[];
  for (final T item in items) {
    final String key = goalCategoryDisplayKey(domainOf(item));
    final List<T>? bucket = buckets[key];
    if (bucket == null) {
      buckets[key] = <T>[item];
      if (key.startsWith(goalCategoryCustomPrefix)) {
        customOrder.add(key);
      }
    } else {
      bucket.add(item);
    }
  }
  final List<String> order = <String>[
    ...goalCategoryKeys,
    ...customOrder,
    goalCategoryNoneKey,
  ];
  final List<GoalSectionGroup<T>> groups = <GoalSectionGroup<T>>[];
  for (final String key in order) {
    final List<T>? bucket = buckets[key];
    if (bucket == null) {
      continue;
    }
    groups.add(
      GoalSectionGroup<T>(
        displayKey: key,
        title: goalCategoryTitle(t, domainOf(bucket.first)),
        items: List<T>.unmodifiable(bucket),
      ),
    );
  }
  return List<GoalSectionGroup<T>>.unmodifiable(groups);
}

/// 类别分区的渲染件（领域模型版，派工书契约形态）。
///
/// 三页若拿到的是 `Goal` 就直接用这个；拿到 `GoalRow` 用 [GoalSectionList]
/// 配 [groupSectionsByCategory]。
class GoalCategorySections extends StatelessWidget {
  /// 构造。
  const GoalCategorySections({
    required this.groups,
    required this.rowBuilder,
    this.emptyText,
    this.spacing = 12,
    this.titleStyle,
    super.key,
  });

  /// 分区（**必须**来自 `groupGoalsByCategory(...)`；本件不重新分组）。
  final List<GoalCategoryGroup> groups;

  /// 每一行怎么渲染（分区键 / 标题之外的全部内容由调用方决定）。
  final Widget Function(BuildContext context, Goal goal) rowBuilder;

  /// `groups` 为空时显示的文案；null ⇒ 什么都不渲染。
  final String? emptyText;

  /// 组与组之间的垂直间距。
  final double spacing;

  /// 小标题样式（null ⇒ 主题 `titleSmall` + w600）。
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return GoalSectionList<Goal>(
      groups: <GoalSectionGroup<Goal>>[
        for (final GoalCategoryGroup group in groups)
          GoalSectionGroup<Goal>(
            displayKey: group.displayKey,
            title: group.title,
            items: group.goals,
          ),
      ],
      rowBuilder: rowBuilder,
      emptyText: emptyText,
      spacing: spacing,
      titleStyle: titleStyle,
    );
  }
}

/// 类别分区的渲染件（泛型版：`Goal` / `GoalRow` 都能喂）。
class GoalSectionList<T> extends StatelessWidget {
  /// 构造。
  const GoalSectionList({
    required this.groups,
    required this.rowBuilder,
    this.emptyText,
    this.spacing = 12,
    this.titleStyle,
    super.key,
  });

  /// 分区（顺序由分组函数决定；本件按传入顺序渲染）。
  final List<GoalSectionGroup<T>> groups;

  /// 每一行怎么渲染。
  final Widget Function(BuildContext context, T item) rowBuilder;

  /// `groups` 为空时显示的文案；null ⇒ 什么都不渲染。
  final String? emptyText;

  /// 组与组之间的垂直间距。
  final double spacing;

  /// 小标题样式（null ⇒ 主题 `titleSmall` + w600）。
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      final String? text = emptyText;
      if (text == null) {
        return const SizedBox.shrink();
      }
      return Text(
        text,
        key: const ValueKey<String>('goal-section-empty'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < groups.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          _section(context, groups[i]),
        ],
      ],
    );
  }

  /// 一个分区：小标题 + 逐行。
  Widget _section(BuildContext context, GoalSectionGroup<T> group) {
    final TextStyle? style =
        titleStyle ??
        Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Column(
      key: ValueKey<String>('goal-section-${group.displayKey}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          group.title,
          key: ValueKey<String>('goal-section-title-${group.displayKey}'),
          style: style,
        ),
        const SizedBox(height: 4),
        for (final T item in group.items) rowBuilder(context, item),
      ],
    );
  }
}