import 'dart:async';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_p1.dart';
import 'section_card.dart';

/// 心态区块（需求 6）：豆包 3+2 结构 —— 每日核心 3 项 + 每周补充 2 项。
///
/// 三条容易被写错、这里刻意写对的规则：
/// 1. **未打分的维度不落键**，而不是写 0 —— 否则每条日志都会被判失守。
/// 2. **8 个 legacy 列全部仍被使用**：5 个主存列由打分控件写，3 个佐证列
///    （`mood_2` / `mood_4` / `mood_8`）只读展示并按 `mood_dimensions.dart`
///    的规则参与统计 ⇒ 老数据零丢失。
/// 3. **失守标记由数据层自动派生**（任一维度为 0 ⇒ `mood_failed` 为真），
///    界面不再提供「今日失守」开关行；`_failedRequested` 只剩「今天没打分」
///    这一个手动入口。
class MoodSection extends ConsumerStatefulWidget {
  /// 创建心态区块。
  const MoodSection({super.key});

  @override
  ConsumerState<MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends ConsumerState<MoodSection> {
  /// 8 个 legacy 维度的原始分数（含佐证列）。
  ///
  /// 保持全 8 维而不是只留 5 维：`saveMood` 会把未出现在 map 里的列写成
  /// NULL，只留 5 维会把佐证列的老数据清空。
  final Map<MoodDimension, int> _scores = <MoodDimension, int>{};
  final TextEditingController _note = TextEditingController();
  final TextEditingController _nextAction = TextEditingController();
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
    _nextAction.dispose();
    super.dispose();
  }

  Future<void> _persist(String logId) async {
    await _persistTo(ref.read(repositoriesProvider).dayLog, logId);
  }

  /// 真正的落库动作，与「怎么拿到仓储」解耦。
  ///
  /// 「明日改进点」只走 `saveMood` 的可选参数（该列现在归心态侧所有），
  /// 复盘侧的 `saveReview` 已明确不碰 `next_action`。
  Future<void> _persistTo(DayLogRepository repo, String logId) async {
    final summary = MoodRules.summarize(
      scores: _scores,
      requestedFailed: _failedRequested,
      note: _note.text.trim(),
    );
    await repo.saveMood(logId, summary, nextAction: _nextAction.text.trim());
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
    _nextAction.text = log.nextAction;
  }

  /// 8 个 legacy 列名 → 当前分数（未评为 null），供统计函数复用。
  Map<String, int?> _columns() {
    return <String, int?>{
      for (final dimension in MoodDimension.all)
        dimension.column: _scores[dimension],
    };
  }

  static String _groupTitle(MoodPeriod period) {
    return period == MoodPeriod.day ? '每日核心' : '每周补充';
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
      subtitle: '每日 3 项 + 每周 2 项，各 0–10 分；留空表示不作评',
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
          // 统计口径是**新 5 维**：主存列缺失时按佐证列均值回退，
          // 与 `mood_dimensions.dart` 的规则保持同一处实现。
          final dimensionScores = scoreMoodDimensions(_columns());
          final rated = ratedMoodDimensionCount(dimensionScores);
          final average = meanMoodScore(dimensionScores);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    '已评 $rated/${moodDimensionDefs.length} 维',
                    key: const ValueKey<String>('mood-rated-count'),
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    '均分 ${average == null ? '—' : average.toStringAsFixed(1)}',
                    key: const ValueKey<String>('mood-average'),
                    style: theme.textTheme.labelSmall,
                  ),
                  if (_scores.isNotEmpty)
                    TextButton(
                      key: const ValueKey<String>('mood-clear-all'),
                      onPressed: () {
                        setState(_scores.clear);
                        _scheduleSave(log.id);
                      },
                      child: const Text('全部清空'),
                    ),
                  TextButton(
                    key: const ValueKey<String>('mood-mark-failed'),
                    onPressed: () {
                      setState(() => _failedRequested = true);
                      _scheduleSave(log.id);
                    },
                    child: const Text('今天没打分'),
                  ),
                ],
              ),
              // 每期（日 / 周）是一个带 key 的整体：标题与它名下的维度行同属
              // 一个子树，外部（含测试）可以按分组判别归属，而不必数行序。
              for (final period in MoodPeriod.values)
                Padding(
                  key: ValueKey<String>('mood-group-${period.name}'),
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _MoodGroupHeader(
                        title: _groupTitle(period),
                        period: period,
                        rated: ratedMoodDimensionCount(
                          dimensionScores,
                          period: period,
                        ),
                        total: moodDimensionDefs
                            .where((definition) => definition.period == period)
                            .length,
                      ),
                      for (final definition in moodDimensionDefs)
                        if (definition.period == period)
                          _MoodDimensionRow(
                            key: ValueKey<String>(
                              'mood-dim-${definition.key}',
                            ),
                            definition: definition,
                            score: _scores[definition.primary],
                            rawScores: _scores,
                            onChanged: (value) {
                              setState(
                                () => _scores[definition.primary] = value,
                              );
                              _scheduleSave(log.id);
                            },
                            onClear: () {
                              setState(() => _scores.remove(definition.primary));
                              _scheduleSave(log.id);
                            },
                          ),
                    ],
                  ),
                ),
              const Divider(height: 20),
              TextField(
                key: const ValueKey<String>('mood-next-action'),
                controller: _nextAction,
                minLines: 1,
                maxLines: 2,
                onChanged: (_) => _scheduleSave(log.id),
                decoration: const InputDecoration(
                  labelText: moodNextActionLabel,
                  hintText: '明天先做的一件具体事',
                  prefixIcon: Icon(Icons.flag_outlined, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>('mood-note'),
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

/// 「每日核心 / 每周补充」分组头。
class _MoodGroupHeader extends StatelessWidget {
  const _MoodGroupHeader({
    required this.title,
    required this.period,
    required this.rated,
    required this.total,
  });

  final String title;
  final MoodPeriod period;
  final int rated;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            '$title · ${period == MoodPeriod.day ? '每日' : '每周'}更新',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$total 项 · 已评 $rated',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个心态维度：一个主存列的 0–10 打分控件 + 文案 + 佐证只读行。
class _MoodDimensionRow extends StatelessWidget {
  const _MoodDimensionRow({
    required this.definition,
    required this.score,
    required this.rawScores,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final MoodDimensionDef definition;
  final int? score;
  final Map<MoodDimension, int> rawScores;
  final ValueChanged<int> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rated = score != null;
    final evidence = <String>[
      for (final dimension in definition.supporting)
        '${dimension.label} ${rawScores[dimension] ?? '未评'}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 92,
                child: Text(
                  definition.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: rated ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: <Widget>[
                    for (int value = moodScoreMin; value <= moodScoreMax; value++)
                      ChoiceChip(
                        key: ValueKey<String>(
                          'mood-dim-${definition.key}-score-$value',
                        ),
                        label: Text('$value'),
                        selected: score == value,
                        onSelected: (_) => onChanged(value),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  rated ? '$score' : '—',
                  key: ValueKey<String>('mood-dim-${definition.key}-value'),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: rated ? FontWeight.w700 : FontWeight.w400,
                    color: rated && score == 0 ? theme.colorScheme.error : null,
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
          ),
          Text(
            definition.description,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (evidence.isNotEmpty)
            Text(
              '佐证：${evidence.join(' · ')}',
              key: ValueKey<String>('mood-supporting-${definition.key}'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}