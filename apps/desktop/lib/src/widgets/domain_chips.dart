// apps/desktop/lib/src/widgets/domain_chips.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_scope.dart';
import 'chip_row.dart';

/// 领域芯片（6 枚，单选）。
class DomainChips extends StatelessWidget {
  /// 创建领域芯片条。
  const DomainChips({
    super.key,
    required this.selectedDomain,
    this.onChanged,
  });

  /// 领域清单（抄自 spec §5.1）。
  ///
  /// **这是落库值，不是显示文案**：`project.domain` 列存的就是这 6 个中文串，
  /// 不随语言变化。显示名由 [_displayLabel] 按当前语言映射。
  static const List<String> domains = <String>[
    '事业',
    '财富',
    '家庭',
    '学习',
    '人际',
    '健康',
  ];

  /// 当前选中的领域（空串 = 未选）。
  final String selectedDomain;

  /// 选择变化回调；null 表示只读。
  final void Function(String domain)? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = _localizations(context);
    return ChipRow(
      options: <ChipOption>[
        for (final domain in domains)
          ChipOption(key: domain, label: _displayLabel(domain, t)),
      ],
      selected: selectedDomain.isEmpty
          ? const <String>{}
          : <String>{selectedDomain},
      onChanged: onChanged == null
          ? null
          : (next) => onChanged!(next.isEmpty ? '' : next.first),
    );
  }
}

/// 取当前语言的文案表。
///
/// 本组件是 [StatelessWidget]，拿不到 `WidgetRef`；而
/// `test\duration_domain_chips_test.dart` 把 [DomainChips] 挂在**没有**
/// `L10nScope` 的裸 `MaterialApp` 上并断言中文落库值 `'健康'`。因此这里用
/// 「有 scope 按 scope、没 scope 按中文表」的兜底：兜底结果与迁移前逐字一致，
/// 不会把中文态渲染成英文。
///
/// 该测试文件的 `l10nScope(...)` 包装归末轮 R9 补（本批次写集不含它）。
AppLocalizations _localizations(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<L10nScope>()?.localizations ??
    AppLocalizations.zh;

/// 中文落库值 ⇒ 本地化显示名（零新增键，复用 `projectsDomain*`）。
///
/// 翻译只发生在显示层：`ChipOption.key` 仍是中文落库值，回传回调拿到的也仍是它。
String _displayLabel(String domain, AppLocalizations t) {
  switch (domain) {
    case '事业':
      return t.projectsDomainCareer;
    case '财富':
      return t.projectsDomainWealth;
    case '家庭':
      return t.projectsDomainFamily;
    case '学习':
      return t.projectsDomainLearning;
    case '人际':
      return t.projectsDomainSocial;
    case '健康':
      return t.projectsDomainHealth;
    default:
      return domain;
  }
}