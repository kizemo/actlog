// =============================================================================
// 项目领域目录（Task 60 · 唯一真源）
// =============================================================================
// 为什么放数据层：领域 key 清单是**领域模型**，不是文案；文案仍在 l10n 里。
// 新增一个领域 = 这张表加一行 + l10n 加一条 getter，**页面不用动**。
// 空串（未分类/未设置）**不在**这张表里 —— 它是「没有领域」，不是一种领域。
// =============================================================================

/// 领域 key ⇒ 本地化 getter 名（**唯一真源**）。
const Map<String, String> projectDomainLabelGetters = <String, String>{
  'career': 'projectsDomainCareer',
  'wealth': 'projectsDomainWealth',
  'family': 'projectsDomainFamily',
  'learning': 'projectsDomainLearning',
  'social': 'projectsDomainSocial',
  'health': 'projectsDomainHealth',
};

/// 领域 key 清单（派生自上表；顺序 = 插入顺序 = 界面芯片顺序）。
List<String> get projectDomainKeys =>
    List<String>.unmodifiable(projectDomainLabelGetters.keys);