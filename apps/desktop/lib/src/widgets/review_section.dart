import 'dart:async';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'section_card.dart';

/// 一条复盘的编辑字段。
class _ReviewField {
  const _ReviewField(this.label, this.hint, this.icon);

  final String label;
  final String hint;
  final IconData icon;
}

/// 复盘区块（P1-7）：学到了什么 / 做得好 / 待改进。
///
/// 三段**各自可独立留白** —— 任何一个输入框空着都不影响其余段落落库，
/// 因为 `saveReview` 写的是整份 `ReviewDraft`，空串就是空串。违反这条的只有
/// 「某段为空就整条不保存」的实现，这里刻意不这么写。
///
/// Task 40 需求 4 删掉了「可控的事 / 不可控的事 / 下一步可控动作」三项输入框：
/// 复盘只回答「学到了什么、哪里做得好、哪里要改」，不再要求用户当场做归因。
class ReviewSection extends ConsumerStatefulWidget {
  /// 创建复盘区块。
  const ReviewSection({super.key});

  @override
  ConsumerState<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<ReviewSection> {
  static const List<_ReviewField> _fields = [
    _ReviewField('学到了什么', '今天最大的一个认知收获', Icons.lightbulb_outline),
    _ReviewField('做得好', '值得保留的做法', Icons.thumb_up_outlined),
    _ReviewField('待改进', '下次换个做法的地方', Icons.build_outlined),
  ];

  /// 已删掉输入框的两列，**原值读进来、原样传回去**。
  ///
  /// 为什么不能直接传空串：`saveReview` 仍然写 `controllable` /
  /// `uncontrollable` 两列（`packages/core_data/lib/src/repositories.dart:164`）。
  /// 界面不再编辑它们，但老库里已经填过的内容必须原封不动 —— 否则用户只是
  /// 在「学到了什么」里改一个字，就会把这两段历史静默清空。删 UI 不等于删数据。
  ///
  /// `next_action` 不在本区块持有：`saveReview` 刻意不写它，该列归心态侧
  /// `saveMood` 的可选参数所有（见 `repositories.dart:187`）。
  String _controllable = '';
  String _uncontrollable = '';

  late final List<TextEditingController> _controllers = [
    for (final _ in _fields) TextEditingController(),
  ];

  Timer? _debounce;
  String? _seededLogId;

  /// 仓储实例的缓存。
  ///
  /// `dispose()` 里不能读 `ref` —— widget 卸载时 Riverpod 会抛
  /// `Using "ref" when a widget is about to or has been unmounted is unsafe`。
  /// 所以在还活着的时候把要用的东西抓进字段，卸载时只用字段。
  DayLogRepository? _repo;

  @override
  void dispose() {
    _debounce?.cancel();
    // 输入框里没落库的内容在退出前再冲一次，避免「打完字关窗全丢」。
    final logId = _seededLogId;
    final repo = _repo;
    if (logId != null && repo != null) {
      unawaited(_persistTo(repo, logId));
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  ReviewDraft get _draft => ReviewDraft(
    learning: _controllers[0].text,
    good: _controllers[1].text,
    improve: _controllers[2].text,
    controllable: _controllable,
    uncontrollable: _uncontrollable,
  );

  Future<void> _persist(String logId) async {
    await _persistTo(ref.read(repositoriesProvider).dayLog, logId);
  }

  /// 真正的落库动作，与「怎么拿到仓储」解耦。
  Future<void> _persistTo(DayLogRepository repo, String logId) async {
    await repo.saveReview(logId, _draft);
  }

  void _scheduleSave(String logId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_persist(logId));
    });
  }

  void _seed(DayLogData log) {
    _seededLogId = log.id;
    // 这两列没有输入框了，但落库时仍要原样带回（见字段注释）。
    _controllable = log.controllable;
    _uncontrollable = log.uncontrollable;
    final values = [
      log.learning,
      log.good,
      log.improve,
    ];
    for (var index = 0; index < _controllers.length; index++) {
      _controllers[index].text = values[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLog = ref.watch(dayLogProvider);
    // 还活着的时候把仓储抓进字段，供 dispose() 使用（见 _repo 的注释）。
    _repo ??= ref.read(repositoriesProvider).dayLog;

    return SectionCard(
      icon: Icons.rate_review_outlined,
      title: '复盘',
      subtitle: '哪几段有想法就写哪几段，留白不影响保存',
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
          if (_seededLogId != log.id) {
            _seed(log);
          }
          return Column(
            children: [
              for (var index = 0; index < _fields.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllers[index],
                    minLines: 1,
                    maxLines: 3,
                    onChanged: (_) => _scheduleSave(log.id),
                    decoration: InputDecoration(
                      labelText: _fields[index].label,
                      hintText: _fields[index].hint,
                      prefixIcon: Icon(_fields[index].icon, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}