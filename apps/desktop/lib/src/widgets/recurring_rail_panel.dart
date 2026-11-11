import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers_recurring.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 右轨「循环任务」：选中日里按星期重复的任务，以及它们的时段。
///
/// 两件事都在这一个 `build` 里发生，顺序有意义：
/// 1. `watch(recurringMaterializeProvider)` —— **进入即物化**（幂等），
///    保证今天该跑的任务已经落成 `plan_item`，时间轴与计划列表立刻能看到；
/// 2. `watch(recurringOccurrencesProvider)` —— 读物化凭证并展示。
///
/// 面板只读：它不改计划条目的状态（勾选/回填都在计划列表与时间轴上做）。
class RecurringRailPanel extends ConsumerWidget {
  /// 创建循环任务面板。
  const RecurringRailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? materializeError = ref
        .watch(recurringMaterializeProvider)
        .whenOrNull(
          error: (Object error, StackTrace _) => '自动排程失败：$error',
        );
    final List<RecurringOccurrenceView> rows =
        ref.watch(recurringOccurrencesProvider).whenOrNull(
              data: (List<RecurringOccurrenceView> data) => data,
            ) ??
        const <RecurringOccurrenceView>[];

    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '所选日没有循环任务',
            style: _bodyStyle(size: 12.5, color: AppTokens.faint),
          ),
          const SizedBox(height: 4),
          Text(
            '点右上角 ＋ 添加一条，或换到它排的那一天',
            style: _bodyStyle(size: 11.5, color: AppTokens.faint),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final view in rows) _OccurrenceRow(view: view),
        if (materializeError != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            materializeError,
            style: _bodyStyle(size: 11.5, color: AppTokens.accentInk),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          '共 ${rows.length} 条 · 已自动排入计划',
          style: _bodyStyle(size: 11, color: AppTokens.faint),
        ),
      ],
    );
  }
}

/// 一行循环任务：时段（mono）+ 标题 + 星期摘要。
class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({required this.view});

  final RecurringOccurrenceView view;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              view.timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _monoStyle(size: 11.5, color: AppTokens.ink2),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              view.task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(size: 12.5, color: AppTokens.ink),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            WeekdayMask.label(view.task.weekdayMask),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _bodyStyle(size: 11, color: AppTokens.faint),
          ),
        ],
      ),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({double size = 12.5, Color color = AppTokens.ink}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
  );
}

/// 等宽字体样式（时段、数字用）。
TextStyle _monoStyle({double size = 12, Color color = AppTokens.ink}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color,
    height: 1.45,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}