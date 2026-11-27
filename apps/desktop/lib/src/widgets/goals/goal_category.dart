// =============================================================================
// 目标类别目录（B17-W0 · 唯一真源）
// =============================================================================
// 为什么放 `widgets/goals`：类别是**目标三页的展示口径**（分区小标题 + 表单
// 下拉），不是领域模型的字段 —— 它复用 `Goal.domain` 这一列，**没有新列、
// 没有 DB 迁移**（B17 裁决 1）。
//
// 口径（B17 裁决 2）：
//  * 五个预设 key：`wealth` / `family` / `learning` / `social` / `health`，
//    顺序即界面分区顺序与下拉顺序；
//  * 自定义存 `custom:<文本>` 前缀，显示时只取 `<文本>`；
//  * **空值 / 未知 key / 空自定义一律归「未分类」** —— 失败安全，页面永远
//    不会出现没有标题的分区；
//  * 不复用 `projectDomainLabel`：那套措辞属于「项目领域」，语义不同。
//
// 文案不写在这里：key ⇒ l10n getter，唯一真源仍是 `l10n/parts/goals.dart`。
// 新增一个预设类别 = 这张表加一行 + l10n 加一条 getter + 下面 switch 加一行
// （switch 无法按名调用 getter，只能与表保持同步）。
// =============================================================================

import 'package:core_domain/core_domain.dart';

import '../../l10n/app_localizations.dart';

/// 预设类别 key ⇒ 本地化 getter 名（**唯一真源**；顺序 = 界面顺序）。
const Map<String, String> goalCategoryLabelGetters = <String, String>{
  'wealth': 'goalCategoryWealth',
  'family': 'goalCategoryFamily',
  'learning': 'goalCategoryLearning',
  'social': 'goalCategorySocial',
  'health': 'goalCategoryHealth',
};

/// 自定义类别的存储前缀（`custom:<文本>`）。
const String goalCategoryCustomPrefix = 'custom:';

/// 下拉里「自定义」这一项的 key（不是存储值，只是选项标识）。
const String goalCategoryCustomKey = 'custom';

/// 未分类分区的展示 key。
const String goalCategoryNoneKey = 'none';

/// 预设类别 key 清单（派生自上表；顺序 = 界面分区顺序）。
List<String> get goalCategoryKeys =>
    List<String>.unmodifiable(goalCategoryLabelGetters.keys);

/// 把 `Goal.domain` 归一成「类别存储 key」；认不出来返回 null。
///
/// 返回值的可能形态只有三种：五个预设 key 之一、`custom:<文本>`、null。
/// `custom:` 后面只有空白视同未分类（避免出现空标题）。
String? goalCategoryKey(String? domain) {
  final String value = (domain ?? '').trim();
  if (value.isEmpty) {
    return null;
  }
  if (goalCategoryLabelGetters.containsKey(value)) {
    return value;
  }
  if (value.startsWith(goalCategoryCustomPrefix)) {
    final String text = value
        .substring(goalCategoryCustomPrefix.length)
        .trim();
    return text.isEmpty ? null : '$goalCategoryCustomPrefix$text';
  }
  return null;
}

/// 分区的稳定标识：预设 key / `custom:<文本>` / [goalCategoryNoneKey]。
String goalCategoryDisplayKey(String? domain) =>
    goalCategoryKey(domain) ?? goalCategoryNoneKey;

/// 类别 key ⇒ 文案。
///
/// 只认五个预设 key、[goalCategoryCustomKey]；其余（含 [goalCategoryNoneKey]
/// 与任何未知 key）一律返回「未分类」。自定义类别的**用户文本**不走这里，
/// 由 [goalCategoryTitle] 直接取。
String goalCategoryLabel(AppLocalizations t, String key) {
  switch (key) {
    case 'wealth':
      return t.goalCategoryWealth;
    case 'family':
      return t.goalCategoryFamily;
    case 'learning':
      return t.goalCategoryLearning;
    case 'social':
      return t.goalCategorySocial;
    case 'health':
      return t.goalCategoryHealth;
    case goalCategoryCustomKey:
      return t.goalCategoryCustom;
    default:
      return t.goalCategoryUncategorized;
  }
}

/// `Goal.domain` ⇒ 分区标题。
///
/// 自定义类别直接显示用户填的文本（不再套「自定义」前缀）；空值 / 未知 key /
/// 空自定义 ⇒ 「未分类」。
String goalCategoryTitle(AppLocalizations t, String? domain) {
  final String? key = goalCategoryKey(domain);
  if (key == null) {
    return t.goalCategoryUncategorized;
  }
  if (key.startsWith(goalCategoryCustomPrefix)) {
    return key.substring(goalCategoryCustomPrefix.length);
  }
  return goalCategoryLabel(t, key);
}

/// 一个类别分区。
class GoalCategoryGroup {
  /// 构造分区。
  const GoalCategoryGroup({
    required this.displayKey,
    required this.title,
    required this.goals,
  });

  /// 稳定标识（预设 key / `custom:<文本>` / `none`）；用于 `ValueKey`。
  final String displayKey;

  /// 分区小标题（已本地化；自定义类别是用户文本）。
  final String title;

  /// 组内目标，**保持传入顺序**。
  final List<Goal> goals;
}

/// 按类别分区。
///
/// 顺序固定：五个预设（空组不出）→ 自定义（按**首次出现**顺序）→ 未分类垫底。
/// 组内相对顺序与传入顺序一致（调用方自己决定排序）。
List<GoalCategoryGroup> groupGoalsByCategory(
  AppLocalizations t,
  List<Goal> goals,
) {
  final Map<String, List<Goal>> buckets = <String, List<Goal>>{};
  final List<String> customOrder = <String>[];
  for (final Goal goal in goals) {
    final String key = goalCategoryDisplayKey(goal.domain);
    final List<Goal>? bucket = buckets[key];
    if (bucket == null) {
      buckets[key] = <Goal>[goal];
      if (key.startsWith(goalCategoryCustomPrefix)) {
        customOrder.add(key);
      }
    } else {
      bucket.add(goal);
    }
  }
  final List<GoalCategoryGroup> groups = <GoalCategoryGroup>[];
  final List<String> order = <String>[
    ...goalCategoryKeys,
    ...customOrder,
    goalCategoryNoneKey,
  ];
  for (final String key in order) {
    final List<Goal>? bucket = buckets[key];
    if (bucket == null) {
      continue;
    }
    groups.add(
      GoalCategoryGroup(
        displayKey: key,
        title: goalCategoryTitle(t, bucket.first.domain),
        goals: List<Goal>.unmodifiable(bucket),
      ),
    );
  }
  return List<GoalCategoryGroup>.unmodifiable(groups);
}