import 'dart:async';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
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
  /// 三段字段的条数。
  ///
  /// 输入框控制器、`_draft` 的下标、渲染循环全都按它对齐，与文案无关，
  /// 所以留在 `static const` 上；文案本身见 [_fields]。
  static const int _fieldCount = 3;

  /// 三段字段（标题 / 占位 / 图标）。
  ///
  /// 文案随语言走，故从 `static const` 改成按 `l10n` 现取 —— 原来那三个中文
  /// 字面量已迁到 `parts\today.dart`。
  List<_ReviewField> _fields(AppLocalizations l10n) => <_ReviewField>[
    _ReviewField(
      l10n.todayReviewFieldLearn,
      l10n.todayReviewFieldLearnHint,
      Icons.lightbulb_outline,
    ),
    _ReviewField(
      l10n.todayReviewFieldGood,
      l10n.todayReviewFieldGoodHint,
      Icons.thumb_up_outlined,
    ),
    _ReviewField(
      l10n.todayReviewFieldImprove,
      l10n.todayReviewFieldImproveHint,
      Icons.build_outlined,
    ),
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
    for (var index = 0; index < _fieldCount; index++) TextEditingController(),
  ];

  Timer? _debounce;
  String? _seededLogId;

  /// 仓储实例的缓存。
  ///
  /// `dispose()` 里不能读 `ref` —— widget 卸载时 Riverpod 会抛
  /// `Using "ref" when a widget is about to or has been unmounted is unsafe`。
  /// 所以在还活着的时候把要用的东西抓进字段，卸载时只用字段。
  DayLogRepository? _repo;

  /// 项目列表（`Future` 只建一次 —— 每次 build 都重建会把 FutureBuilder 打回
  /// waiting 态，按钮跟着闪）。
  Future<List<ProjectRow>>? _projects;

  /// 「记到项目」正在写库。
  bool _busy = false;

  /// 行内弱化提示（成功 / 失败都走这里，不弹 SnackBar）。
  String? _notice;

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

  /// 取第一句并截断到 40 字。
  ///
  /// 增量的 `progress` 是流水里的一行，不该把整段复盘原封搬进去；用户真要把
  /// 原文留全，复制粘贴就行，但默认不该是他「点一下」就产生的结果。
  static String _excerpt(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return '';
    }
    final RegExpMatch? match = RegExp(r'[。！？!?；;\n]').firstMatch(text);
    final String head = (match == null ? text : text.substring(0, match.start))
        .trim();
    return head.length <= 40 ? head : '${head.substring(0, 40)}…';
  }

  /// 把这次复盘追加成一条增量（`project_increment`，只 INSERT）。
  ///
  /// 字段映射（源码只有三列，见 `_fields`）：
  ///  - `progress` = 「做得好」+「学到了什么」，以「；」连接（哪段空就只留另一段）
  ///  - `next_step` = 「待改进」
  ///  - `blockers` = `''` —— 源码里没有「卡在哪」这一栏，不替用户编造
  ///  - `date` = 当日日志的日期；`plan_item_id` 由仓储自动派生
  Future<void> _toProject(
    List<ProjectRow> active,
    DayLogData log,
    AppLocalizations l10n,
  ) async {
    if (_busy) {
      return;
    }
    final List<String> segments = <String>[
      _excerpt(_controllers[1].text),
      _excerpt(_controllers[0].text),
    ].where((String part) => part.isNotEmpty).toList(growable: false);
    final String progress = l10n.todayReviewJoinSegments(segments);
    final String nextStep = _excerpt(_controllers[2].text);
    if (progress.isEmpty && nextStep.isEmpty) {
      setState(() => _notice = l10n.todayReviewEmptyNotice);
      return;
    }

    ProjectRow? target;
    if (active.length == 1) {
      target = active.first;
    } else {
      target = await _pickProject(active, l10n);
    }
    if (target == null || !mounted) {
      return;
    }
    final ProjectRow chosen = target;

    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await ProjectStore(ref.read(repositoriesProvider)).appendIncrement(
        projectId: chosen.id,
        date: log.date,
        progress: progress,
        nextStep: nextStep,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _notice = l10n.todayReviewFiledTo(chosen.name);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _notice = '$error';
      });
    }
  }

  /// 项目多于一个时让用户挑；取消返回 `null`。
  Future<ProjectRow?> _pickProject(
    List<ProjectRow> active,
    AppLocalizations l10n,
  ) async {
    final String? id = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(l10n.todayReviewPickProject),
        children: <Widget>[
          for (final ProjectRow project in active)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(project.id),
              child: Text(project.name),
            ),
        ],
      ),
    );
    if (id == null) {
      return null;
    }
    for (final ProjectRow project in active) {
      if (project.id == id) {
        return project;
      }
    }
    return null;
  }

  /// 「→ 记到项目」：**只有存在 active 项目时才出现**，没有项目就整块不渲染。
  Widget _buildToProject(
    BuildContext context,
    DayLogData log,
    AppLocalizations l10n,
  ) {
    final Future<List<ProjectRow>> future =
        _projects ??= ProjectStore(ref.read(repositoriesProvider))
            .listProjects();
    return FutureBuilder<List<ProjectRow>>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<List<ProjectRow>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final List<ProjectRow> active = (snapshot.data ?? const <ProjectRow>[])
            .where((ProjectRow project) => project.status == 'active')
            .toList(growable: false);
        if (active.isEmpty) {
          return const SizedBox.shrink();
        }
        final String? notice = _notice;
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              TextButton(
                key: const ValueKey<String>('review-increment-to-project'),
                onPressed: _busy ? null : () => _toProject(active, log, l10n),
                child: Text(l10n.todayReviewFileToProject),
              ),
              if (notice != null)
                Text(
                  notice,
                  style: TextStyle(fontSize: 11, color: context.tokens.faint),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final dayLog = ref.watch(dayLogProvider);
    // 还活着的时候把仓储抓进字段，供 dispose() 使用（见 _repo 的注释）。
    _repo ??= ref.read(repositoriesProvider).dayLog;

    return SectionCard(
      icon: Icons.rate_review_outlined,
      title: l10n.domainReviewLabel,
      subtitle: l10n.todayReviewSubtitle,
      child: dayLog.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => Text(
          '$error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (log) {
          if (log == null) {
            return Text(l10n.domainDayLogNotStarted);
          }
          if (_seededLogId != log.id) {
            _seed(log);
          }
          final List<_ReviewField> fields = _fields(l10n);
          return Column(
            children: [
              for (var index = 0; index < fields.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllers[index],
                    minLines: 1,
                    maxLines: 3,
                    onChanged: (_) => _scheduleSave(log.id),
                    decoration: InputDecoration(
                      labelText: fields[index].label,
                      hintText: fields[index].hint,
                      prefixIcon: Icon(fields[index].icon, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              _buildToProject(context, log, l10n),
            ],
          );
        },
      ),
    );
  }
}