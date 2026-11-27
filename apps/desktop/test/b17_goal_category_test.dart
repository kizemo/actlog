// =============================================================================
// B17 目标类别口径（W0）
// =============================================================================
// 守的是「类别 key ↔ 文案 ↔ 分区」这三件事：
//  1. 五个预设 key 原样通过，顺序固定为 财务 → 家庭 → 学习 → 人际 → 健康；
//  2. `custom:<文本>` 归一（去前后空白），只有空白的自定义降级为未分类；
//  3. 空值 / 未知 key / 空自定义一律「未分类」—— 页面不该出现空标题；
//  4. 分区顺序：预设 → 自定义（按首次出现）→ 未分类垫底；空组不出、
//     组内相对顺序与传入顺序一致。
//
// 文案只断言关键值与中英不同（防复制粘贴），不逐字锁整句 —— 改措辞不该让
// 这个文件整片变红。
// =============================================================================

import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/widgets/goals/goal_category.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// 造一条最小目标（只为分区用，字段能过构造即可）。
Goal _goal(String id, {String? domain}) => Goal(
  id: id,
  kind: GoalKind.yearly,
  title: id,
  createdAt: 0,
  updatedAt: 0,
  originDeviceId: 'b17-w0',
  domain: domain,
);

/// 分区里目标的 id 序列（读起来比 `groups[2].goals[1]` 清楚）。
List<String> _ids(GoalCategoryGroup group) =>
    group.goals.map((Goal goal) => goal.id).toList();

void main() {
  group('类别 key 归一', () {
    test('五个预设 key 原样通过', () {
      for (final String key in goalCategoryKeys) {
        expect(goalCategoryKey(key), key);
        expect(goalCategoryDisplayKey(key), key);
      }
    });

    test('预设 key 顺序 = 财务 / 家庭 / 学习 / 人际 / 健康', () {
      expect(goalCategoryKeys, <String>[
        'wealth',
        'family',
        'learning',
        'social',
        'health',
      ]);
    });

    test('custom:<文本> 归一：去前后空白，文本本身保留', () {
      expect(goalCategoryKey('custom:写一本书'), 'custom:写一本书');
      expect(goalCategoryKey('custom: 写一本书 '), 'custom:写一本书');
      expect(goalCategoryDisplayKey(' custom:写一本书 '), 'custom:写一本书');
    });

    test('空值 / 空白 / 空自定义 / 未知 key ⇒ null，展示 key 为 none', () {
      for (final String? raw in <String?>[
        null,
        '',
        '   ',
        'custom:',
        'custom:   ',
        'career',
        'nonsense',
      ]) {
        expect(goalCategoryKey(raw), isNull, reason: '入参 = 「$raw」');
        expect(goalCategoryDisplayKey(raw), goalCategoryNoneKey, reason: '入参 = 「$raw」');
      }
    });
  });

  group('类别标题', () {
    final AppLocalizations zh = AppLocalizations.zh;
    final AppLocalizations en = AppLocalizations.en;

    test('五个预设 key 出各自中文', () {
      expect(goalCategoryTitle(zh, 'wealth'), '财务目标');
      expect(goalCategoryTitle(zh, 'family'), '家庭生活');
      expect(goalCategoryTitle(zh, 'learning'), '学习成长');
      expect(goalCategoryTitle(zh, 'social'), '人际关系');
      expect(goalCategoryTitle(zh, 'health'), '健康休闲');
    });

    test('五个预设 key 出各自英文', () {
      expect(goalCategoryTitle(en, 'wealth'), 'Financial');
      expect(goalCategoryTitle(en, 'family'), 'Family & Life');
      expect(goalCategoryTitle(en, 'learning'), 'Learning & Growth');
      expect(goalCategoryTitle(en, 'social'), 'Relationships');
      expect(goalCategoryTitle(en, 'health'), 'Health & Leisure');
    });

    test('自定义类别直接显示用户文本（不套「自定义」前缀）', () {
      expect(goalCategoryTitle(zh, 'custom:写一本书'), '写一本书');
      expect(goalCategoryTitle(en, 'custom:Read more'), 'Read more');
    });

    test('空 / 未知 / 空自定义 ⇒ 未分类（中英各一次）', () {
      for (final String? raw in <String?>[
        null,
        '',
        '  ',
        'custom:',
        'custom:  ',
        'career',
        'x',
      ]) {
        expect(
          goalCategoryTitle(zh, raw),
          zh.goalCategoryUncategorized,
          reason: '中文态入参 = 「$raw」',
        );
        expect(
          goalCategoryTitle(en, raw),
          en.goalCategoryUncategorized,
          reason: '英文态入参 = 「$raw」',
        );
      }
    });

    test('下拉里的「自定义」项与「未分类」项都取得到且中英不同', () {
      expect(goalCategoryLabel(zh, goalCategoryCustomKey), '自定义类别');
      expect(goalCategoryLabel(en, goalCategoryCustomKey), 'Custom category');
      expect(goalCategoryLabel(zh, goalCategoryNoneKey), '未分类');
      expect(goalCategoryLabel(en, goalCategoryNoneKey), 'Uncategorized');
      expect(
        zh.goalCategoryUncategorized,
        isNot(en.goalCategoryUncategorized),
      );
    });
  });

  group('按类别分区', () {
    final AppLocalizations zh = AppLocalizations.zh;

    test('预设固定序 → 自定义按首次出现 → 未分类垫底；空组不出', () {
      final List<Goal> goals = <Goal>[
        _goal('n1'),
        _goal('h1', domain: 'health'),
        _goal('c-first', domain: 'custom:乙'),
        _goal('w1', domain: 'wealth'),
        _goal('c-second', domain: 'custom:甲'),
        _goal('h2', domain: 'health'),
        _goal('c-first-2', domain: 'custom:乙'),
        _goal('u1', domain: 'career'),
      ];
      final List<GoalCategoryGroup> groups = groupGoalsByCategory(zh, goals);

      expect(groups.map((GoalCategoryGroup g) => g.displayKey).toList(), <String>[
        'wealth',
        'health',
        'custom:乙',
        'custom:甲',
        'none',
      ]);
      expect(groups.map((GoalCategoryGroup g) => g.title).toList(), <String>[
        '财务目标',
        '健康休闲',
        '乙',
        '甲',
        '未分类',
      ]);
      expect(_ids(groups[0]), <String>['w1']);
      // 组内相对顺序 = 传入顺序（h1 在 h2 前）。
      expect(_ids(groups[1]), <String>['h1', 'h2']);
      // 同一自定义类别合并，且按首次出现的组序排。
      expect(_ids(groups[2]), <String>['c-first', 'c-first-2']);
      expect(_ids(groups[3]), <String>['c-second']);
      // 未知 key 与空域都进未分类，顺序不变。
      expect(_ids(groups[4]), <String>['n1', 'u1']);
    });

    test('空输入 ⇒ 空列表（不分出空组）', () {
      expect(groupGoalsByCategory(zh, <Goal>[]), isEmpty);
    });

    test('只有一个类别时只出一组', () {
      final List<GoalCategoryGroup> groups = groupGoalsByCategory(zh, <Goal>[
        _goal('a', domain: 'learning'),
        _goal('b', domain: 'learning'),
      ]);
      expect(groups.length, 1);
      expect(groups.single.displayKey, 'learning');
      expect(groups.single.title, '学习成长');
      expect(_ids(groups.single), <String>['a', 'b']);
    });

    test('分区列表与组内列表都是只读视图', () {
      final List<GoalCategoryGroup> groups = groupGoalsByCategory(zh, <Goal>[
        _goal('a', domain: 'wealth'),
      ]);
      expect(
        () => groups.add(groups.single),
        throwsUnsupportedError,
      );
      expect(
        () => groups.single.goals.add(_goal('b')),
        throwsUnsupportedError,
      );
    });
  });
}