import 'dart:async';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_p1.dart';
import 'section_card.dart';

/// 心态区块（P1-8）：8 维度 × 0–10 连续分 + 今日失守标记 + 情绪备注。
///
/// 两条容易被写错、这里刻意写对的规则：
/// 1. **未打分的维度不落键**，而不是写 0 —— 否则每条日志都会被判失守。
/// 2. **失守标记只允许被打开、不允许被关掉**：任一维度为 0 时，即使用户把开关
///    拨回去也必须落 true。判定统一走 `MoodRules.resolveFailed`，UI 只负责禁用开关。
class MoodSection extends ConsumerStatefulWidget {
  /// 创建心态区块。
  const MoodSection({super.key});

  @override
  ConsumerState<MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends ConsumerState<MoodSection> {
  final Map<MoodDimension, int> _scores = <MoodDimension, int>{};
  final TextEditingController _note = TextEditingController();
  bool _failedRequested = false;
  String? _seededLogId;
  Timer? _debounce;

  /// 仓储实例的缓存。
  ///
  /// `dispose()` 里不能读 `ref` —— widget 卸载时 Riverpod 会抛
  /// `Using "ref" when a widget is about to or has been unmounted is unsafe`。
  /// 所以在还活着的时候把要用的东西抓进字段，卸载时只用字段。
  DayLogRepository? _repo;

  @override
  void dispose() {
    _debounce?.cancel();
    final logId = _seededLogId;
    final repo = _repo;
    if (logId != null && repo != null) {
      unawaited(_persistTo(repo, logId));
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _persist(String logId) async {
    await _persistTo(ref.read(repositoriesProvider).dayLog, logId);
  }

  /// 真正的落库动作，与「怎么拿到仓储」解耦。
  Future<void> _persistTo(DayLogRepository repo, String logId) async {
    final summary = MoodRules.summarize(
      scores: _scores,
      requestedFailed: _failedRequested,
      note: _note.text.trim(),
    );
    await repo.saveMood(logId, summary);
  }

  void _scheduleSave(String logId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_persist(logId));
    });
  }

  void _seed(DayLogData log, MoodSummary summary) {
    _seededLogId = log.id;
    _scores
      ..clear()
      ..addAll(summary.scores);
    _failedRequested = summary.failed;
    _note.text = summary.note;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLog = ref.watch(dayLogProvider);
    // 还活着的时候把仓储抓进字段，供 dispose() 使用（见 _repo 的注释）。
    _repo ??= ref.read(repositoriesProvider).dayLog;

    return SectionCard(
      icon: Icons.self_improvement,
      title: '心态',
      subtitle: '8 个维度各打 0–10 分；留空表示今天不作评',
      child: dayLog.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => Text(
          '$error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (log) {
          if (log == null) {
            return const Text('当日日志尚未建立');
          }
          final summary = ref.watch(moodProvider(log));
          if (_seededLogId != log.id) {
            _seed(log, summary);
          }
          final hasZero = MoodRules.hasZero(_scores);
          final failed = hasZero || _failedRequested;
          final average = summary.average;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '已评 ${_scores.length}/${MoodDimension.all.length} 维',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: 12),
                  if (_scores.isNotEmpty)
                    Text(
                      '均分 ${average == null ? '—' : average.toStringAsFixed(1)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  const Spacer(),
                  if (_scores.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(_scores.clear);
                        _scheduleSave(log.id);
                      },
                      child: const Text('全部清空'),
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() => _failedRequested = true);
                      _scheduleSave(log.id);
                    },
                    child: const Text('今天没打分'),
                  ),
                ],
              ),
              for (final dimension in MoodDimension.all)
                _MoodSliderRow(
                  dimension: dimension,
                  score: _scores[dimension],
                  onChanged: (value) {
                    setState(() => _scores[dimension] = value);
                    _scheduleSave(log.id);
                  },
                  onClear: () {
                    setState(() => _scores.remove(dimension));
                    _scheduleSave(log.id);
                  },
                ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(
                    failed ? Icons.error_outline : Icons.shield_outlined,
                    size: 18,
                    color: failed ? theme.colorScheme.error : null,
                  ),
                  const SizedBox(width: 6),
                  const Text('今日失守'),
                  const Spacer(),
                  Switch(
                    value: failed,
                    // 存在 0 分维度时开关不可关闭 —— 规则由 core_domain 兜底，
                    // 这里禁用只是为了让用户看见「为什么关不掉」。
                    onChanged: hasZero
                        ? null
                        : (value) {
                            setState(() => _failedRequested = value);
                            _scheduleSave(log.id);
                          },
                  ),
                ],
              ),
              Text(
                hasZero
                    ? '有维度打了 0 分，今日失守自动成立（不可关闭）。'
                    : '没有任何维度为 0，可以手动标记今天是否失守。',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                onChanged: (_) => _scheduleSave(log.id),
                decoration: const InputDecoration(
                  labelText: '情绪备注',
                  hintText: '今天状态如何？为什么？',
                  prefixIcon: Icon(Icons.notes, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoodSliderRow extends StatelessWidget {
  const _MoodSliderRow({
    required this.dimension,
    required this.score,
    required this.onChanged,
    required this.onClear,
  });

  final MoodDimension dimension;
  final int? score;
  final ValueChanged<int> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rated = score != null;
    final value = score ?? 5;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            dimension.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: rated ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (int s = 0; s <= 10; s++)
                ChoiceChip(
                  label: Text('$s'),
                  selected: score == s,
                  onSelected: (_) => onChanged(s),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            rated ? '$value' : '—',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: rated ? FontWeight.w700 : FontWeight.w400,
              color: rated && value == 0 ? theme.colorScheme.error : null,
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: rated
              ? IconButton(
                  tooltip: '清除这一维',
                  icon: const Icon(Icons.close, size: 14),
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                )
              : null,
        ),
      ],
    );
  }
}