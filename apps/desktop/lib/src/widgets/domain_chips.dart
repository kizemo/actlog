// apps/desktop/lib/src/widgets/domain_chips.dart
import 'package:flutter/material.dart';

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
    return ChipRow(
      options: <ChipOption>[
        for (final domain in domains) ChipOption(key: domain, label: domain),
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