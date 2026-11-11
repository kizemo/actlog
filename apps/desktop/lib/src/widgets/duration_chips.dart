// apps/desktop/lib/src/widgets/duration_chips.dart
import 'package:flutter/material.dart';

import 'chip_row.dart';

/// 预估时长档位芯片。
///
/// 档位抄自 spec §7：`5/10/15/25/45/60/90/120` 分钟。
/// 「自定义…」是唯一的打字兜底入口。
class DurationChips extends StatelessWidget {
  /// 创建时长芯片条。
  const DurationChips({
    super.key,
    required this.selectedMinutes,
    this.onChanged,
  });

  /// 档位列表。
  static const List<int> presets = <int>[5, 10, 15, 25, 45, 60, 90, 120];

  /// 当前选中的分钟数（null = 未选）。
  final int? selectedMinutes;

  /// 选择变化回调；null 表示只读。
  final void Function(int? minutes)? onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMinutes == null
        ? const <String>{}
        : <String>{'$selectedMinutes'};
    return ChipRow(
      options: <ChipOption>[
        for (final minutes in presets)
          ChipOption(key: '$minutes', label: '$minutes 分钟'),
        const ChipOption(key: 'custom', label: '自定义…'),
      ],
      selected: selected,
      onChanged: onChanged == null
          ? null
          : (next) {
              if (next.isEmpty) {
                onChanged!(null);
                return;
              }
              final key = next.first;
              if (key == 'custom') {
                // 自定义入口：本轮只提示需要打字，不弹系统数字键盘。
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('自定义时长：点「+ 手写」里输入分钟数')),
                );
                return;
              }
              onChanged!(int.parse(key));
            },
    );
  }
}