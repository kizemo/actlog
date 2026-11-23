// =============================================================================
// 项目领域分布 · 纯聚合（Task 59）
// =============================================================================
// 为什么单独一个文件：项目页的「领域分布」面板只需要「一次分桶」，把它写在
// 页面里会让 UI 结构与统计口径缠在一起；这里**零 IO、零 Flutter 依赖**，口径
// 可以被单测直接钉住（空串桶、未知 key 桶、排序）。
//
// 数据来源：`project.domain`（英文小写稳定 key，空串 = 未分类）。该列的
// 取值域**没有** CHECK 约束（自由文本），所以未知 key 属于正常输入。
// =============================================================================

import 'project_store.dart';

// 领域 key 清单的真源已迁到 `project_domain_catalog.dart`（Task 60）：这里只做
// re-export，让既有的 `import 'project_domain_stats.dart'` 调用点一个字都不用改。
export 'project_domain_catalog.dart' show projectDomainKeys;

/// 项目领域分布的一行统计。
class ProjectDomainStat {
  /// 构造。
  const ProjectDomainStat({
    required this.domain,
    required this.count,
    required this.ratio,
  });

  /// 领域 key（英文小写稳定 key）；空串 = 未分类。
  final String domain;

  /// 该领域的项目数。
  final int count;

  /// 该领域项目数占总数的比例（0..1）。
  final double ratio;
}

/// 按领域分桶统计项目（纯函数）。
///
/// 口径（Task 59 裁决，不得按调用方口味改）：
///  - 空串 `''` 收进「未分类」桶，且**恒排最后**；
///  - `ratio = count / 项目总数`；项目总数为 0 ⇒ 返回**空列表**；
///  - 排序 = 项目数降序 → 数量相同时按 domain **字典序升序** →
///    未分类（空串）恒排最后；
///  - 未知 domain key（同步进来的历史数据）**照实成桶**，不猜译名、不丢弃，
///    显示时原样显示 key（由界面层负责）；
///  - 不抛异常、不裁剪、不去重、**不修改入参**。
List<ProjectDomainStat> projectDomainStats(List<ProjectRow> projects) {
  if (projects.isEmpty) {
    return const <ProjectDomainStat>[];
  }

  final Map<String, int> counts = <String, int>{};
  for (final ProjectRow project in projects) {
    counts[project.domain] = (counts[project.domain] ?? 0) + 1;
  }

  final int total = projects.length;
  final List<ProjectDomainStat> stats = counts.entries
      .map(
        (MapEntry<String, int> entry) => ProjectDomainStat(
          domain: entry.key,
          count: entry.value,
          ratio: entry.value / total,
        ),
      )
      .toList();

  stats.sort((ProjectDomainStat a, ProjectDomainStat b) {
    final bool aUnclassified = a.domain.isEmpty;
    final bool bUnclassified = b.domain.isEmpty;
    if (aUnclassified != bUnclassified) {
      return aUnclassified ? 1 : -1;
    }
    final int byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : a.domain.compareTo(b.domain);
  });
  return List<ProjectDomainStat>.unmodifiable(stats);
}
