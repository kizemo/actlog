// =============================================================================
// 项目页（Task 56）
// =============================================================================
// 页面纪律：**内容体** —— 不自建 `Scaffold` / `AppBar`（那两样由 `LedgerShell`
// 承担），根是 `mainAxisSize: min` 的 `Column`。
//
// 诉求 1（多项目 / 每项目多任务 / 自绘甘特图）：本页把 `project` 与
// `project_milestone` 两张表读出来，画成甘特图，并给出新建项目 / 新建任务 /
// 改期三个入口。
//
// 诉求 2（排期 ⇒ 待办 ⇒ 主页计划）：排期写库在 `ProjectStore` 里完成（写了
// `target_date` 就同步落一条 `todo`），待办池页负责「加入主页计划」。本页只
// 负责让用户把日期排上。
// =============================================================================

import 'dart:async';

import 'package:core_domain/core_domain.dart' show PlanSourceType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_store.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/gantt_chart.dart';

/// 项目页：多项目 / 每项目多任务 / 自绘甘特图。
class ProjectsPage extends ConsumerStatefulWidget {
  /// 创建项目页。
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  late final ProjectStore _store;

  /// 已读到的项目（含各自的任务）。
  List<ProjectRow> _projects = const <ProjectRow>[];

  /// 首屏还没读完。
  bool _loading = true;

  /// 页级错误横幅文案；`null` = 无错误。
  String? _error;

  /// 项目 id → 该项目的增量流水（新的在前）。
  ///
  /// 增量是附属流水，不塞进 [ProjectRow] —— 那个值类是「项目 + 任务」的
  /// 静态形状，增量会随每次追加变化，混进去会让甘特图那条纯读取路径跟着抖动。
  Map<String, List<IncrementRow>> _increments =
      const <String, List<IncrementRow>>{};

  /// 项目 id → 该项目已排出的计划行（含增量侧排出的行）。
  Map<String, List<ScheduledItem>> _scheduled =
      const <String, List<ScheduledItem>>{};

  @override
  void initState() {
    super.initState();
    _store = ProjectStore(ref.read(repositoriesProvider));
    unawaited(_reload());
  }

  /// 重新读库（写入后必须能刷新）。
  Future<void> _reload() async {
    try {
      final List<ProjectRow> rows = await _store.listProjects();
      // 项目数在真实使用里是个位数，逐项目补查两个列表足够；换成一次性
      // 批量查询会把 `listByProject` 的分支逻辑复制一份，得不偿失。
      final Map<String, List<IncrementRow>> increments =
          <String, List<IncrementRow>>{};
      final Map<String, List<ScheduledItem>> scheduled =
          <String, List<ScheduledItem>>{};
      for (final ProjectRow project in rows) {
        increments[project.id] = await _store.listIncrements(project.id);
        scheduled[project.id] = await _store.listByProject(project.id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = rows;
        _increments = increments;
        _scheduled = scheduled;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  /// 新建项目。
  Future<String?> _createProject(
    String name,
    String goal,
    String? startDate,
    String? endDate,
  ) async {
    try {
      await _store.createProject(
        name: name,
        goal: goal,
        startDate: startDate,
        endDate: endDate,
      );
      await _reload();
      return null;
    } catch (error) {
      return _messageOf(error);
    }
  }

  /// 新建任务（带目标日 ⇒ 同步落一条待办）。
  Future<String?> _addTask(
    ProjectRow project,
    String title,
    String? targetDate,
  ) async {
    try {
      await _store.createMilestone(
        projectId: project.id,
        title: title,
        targetDate: targetDate,
      );
      // 排了期就在待办池里落了一条 `todo`（诉求 2 的接线点）。池子是
      // `FutureProvider` ⇒ 写完必须显式失效，否则同会话内「待办池页 / 首页右轨」
      // 一直显示空池，链路的下一环（加入主页计划）根本不会出现在界面上。
      ref.invalidate(todoPoolProvider);
      await _reload();
      return null;
    } catch (error) {
      return _messageOf(error);
    }
  }

  /// 改期（幂等：待办池里不会多出第二条待办）。
  Future<String?> _reschedule(MilestoneRow milestone, String rawDate) async {
    try {
      final String? target = _optionalDay(rawDate);
      await _store.setMilestoneTargetDate(
        milestoneId: milestone.id,
        targetDate: target,
      );
      // 改期会改那条待办的 `due_date`（也可能新建一条）⇒ 池子同样要失效，
      // 否则池里那一行显示的仍是旧日期。
      ref.invalidate(todoPoolProvider);
      await _reload();
      return null;
    } catch (error) {
      return _messageOf(error);
    }
  }

  /// 「＋ 排进今天」：把**项目整体**排一条计划行（`source_type = 'project'`，
  /// `source_id = project.id`）。
  Future<String?> _scheduleProject(ProjectRow project) async {
    try {
      await _store.scheduleToDay(
        date: ref.read(todayProvider),
        sourceType: PlanSourceType.project,
        sourceId: project.id,
        title: project.name,
        detail: project.goal,
      );
      _invalidatePlan();
      await _reload();
      return null;
    } catch (error) {
      return _messageOf(error);
    }
  }

  /// 增量行的「→ 今天」：`source_type = 'increment'`，`source_id = 增量 id`。
  ///
  /// 与 [_scheduleProject] 共用 [ProjectStore.scheduleToDay] —— 两枚按钮只有
  /// 多态指针不同，落库路径必须是一条。
  Future<String?> _scheduleIncrement(
    ProjectRow project,
    IncrementRow increment,
  ) async {
    try {
      await _store.scheduleToDay(
        date: ref.read(todayProvider),
        sourceType: PlanSourceType.increment,
        sourceId: increment.id,
        title: increment.progress.isEmpty ? project.name : increment.progress,
        detail: increment.nextStep,
      );
      _invalidatePlan();
      await _reload();
      return null;
    } catch (error) {
      return _messageOf(error);
    }
  }

  /// 「写第一条增量 / 追加增量」：只 INSERT，写完刷新（`plan_item_id` 由
  /// [ProjectStore.appendIncrement] 自己派生，页面不掺和）。
  Future<String?> _appendIncrement(
    ProjectRow project,
    String progress,
    String blockers,
    String nextStep,
  ) async {
    try {
      await _store.appendIncrement(
        projectId: project.id,
        date: ref.read(todayProvider),
        progress: progress,
        blockers: blockers,
        nextStep: nextStep,
      );
      await _reload();
      return null;
    } catch (error) {
      return _messageOf(error);
    }
  }

  /// 排期写的是 `plan_item`，今日方格由 `planItemsProvider` 这个 `StreamProvider`
  /// 驱动 ⇒ 不失效的话，本会话的今日页看不到刚排进去的那一格。
  void _invalidatePlan() {
    ref.invalidate(planItemsProvider);
  }

  /// 把异常变成一句给用户看的话（`ArgumentError` 自带字段名，更具体）。
  static String _messageOf(Object error) {
    if (error is ArgumentError) {
      return '${error.message}';
    }
    if (error is FormatException) {
      return error.message;
    }
    return '$error';
  }

  /// 取可选日历日；空串 ⇒ `null`（未填）；不是 `YYYY-MM-DD` 或日期不存在 ⇒ 抛。
  static String? _optionalDay(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    final Match? match =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) {
      throw const FormatException('日期必须是 YYYY-MM-DD 格式');
    }
    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    final DateTime parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException('这个日期不存在');
    }
    return text;
  }

  /// 项目 → 甘特图行。
  List<GanttProject> get _ganttProjects => _projects
      .map(
        (ProjectRow project) => GanttProject(
          id: project.id,
          name: project.name,
          startDate: project.startDate,
          endDate: project.endDate,
          milestones: project.milestones
              .map(
                (MilestoneRow milestone) => GanttMilestone(
                  id: milestone.id,
                  title: milestone.title,
                  targetDate: milestone.targetDate,
                ),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final ThemeTokens tokens = context.tokens;
    final String todayIso = ref.watch(todayProvider);
    final String? error = _error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.projectsTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t.projectsSubtitle,
          style: TextStyle(fontSize: 12, color: tokens.meta),
        ),
        const SizedBox(height: AppTokens.gapCard),
        if (error != null) ...<Widget>[
          _ErrorBanner(message: error),
          const SizedBox(height: AppTokens.gapCard),
        ],
        _NewProjectForm(
          newProjectAction: t.projectsNewProjectAction,
          nameHint: t.projectsNameHint,
          goalHint: t.projectsGoalHint,
          startHint: t.projectsStartHint,
          endHint: t.projectsEndHint,
          onSubmit: _createProject,
        ),
        const SizedBox(height: AppTokens.gapCard),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_projects.isEmpty)
          _EmptyHint(text: t.projectsEmpty)
        else ...<Widget>[
          GanttChart(
            projects: _ganttProjects,
            headerLabel: t.projectsTitle,
            emptyLabel: t.projectsEmptyChart,
            unscheduledLabelBuilder: (int count) =>
                t.projectsUnscheduled.replaceAll('{n}', '$count'),
          ),
          const SizedBox(height: AppTokens.gapCard),
          for (final ProjectRow project in _projects) ...<Widget>[
            _ProjectCard(
              localizations: t,
              project: project,
              todayIso: todayIso,
              increments: _increments[project.id] ?? const <IncrementRow>[],
              scheduled: _scheduled[project.id] ?? const <ScheduledItem>[],
              onAddTask: (String title, String? targetDate) =>
                  _addTask(project, title, targetDate),
              onReschedule: (MilestoneRow milestone, String rawDate) =>
                  _reschedule(milestone, rawDate),
              onScheduleToday: () => _scheduleProject(project),
              onScheduleIncrement: (IncrementRow increment) =>
                  _scheduleIncrement(project, increment),
              onAppendIncrement:
                  (String progress, String blockers, String nextStep) =>
                      _appendIncrement(project, progress, blockers, nextStep),
            ),
            const SizedBox(height: AppTokens.gapCard),
          ],
        ],
      ],
    );
  }
}

/// 新建项目表单。
class _NewProjectForm extends StatefulWidget {
  const _NewProjectForm({
    required this.newProjectAction,
    required this.nameHint,
    required this.goalHint,
    required this.startHint,
    required this.endHint,
    required this.onSubmit,
  });

  final String newProjectAction;
  final String nameHint;
  final String goalHint;
  final String startHint;
  final String endHint;

  /// 提交；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(
    String name,
    String goal,
    String? startDate,
    String? endDate,
  )
  onSubmit;

  @override
  State<_NewProjectForm> createState() => _NewProjectFormState();
}

class _NewProjectFormState extends State<_NewProjectForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _goal = TextEditingController();
  final TextEditingController _start = TextEditingController();
  final TextEditingController _end = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '项目名称不能为空');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String? error = await widget.onSubmit(
        name,
        _goal.text.trim(),
        _start.text.trim().isEmpty ? null : _start.text.trim(),
        _end.text.trim().isEmpty ? null : _end.text.trim(),
      );
      if (!mounted) {
        return;
      }
      if (error == null) {
        _name.clear();
        _goal.clear();
        _start.clear();
        _end.clear();
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.hairSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _name,
                  decoration: _fieldDecoration(tokens: tokens, hint: widget.nameHint),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _goal,
                  decoration: _fieldDecoration(tokens: tokens, hint: widget.goalHint),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _start,
                  decoration: _fieldDecoration(tokens: tokens, hint: widget.startHint),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _end,
                  decoration: _fieldDecoration(tokens: tokens, hint: widget.endHint),
                ),
              ),
              _GhostButton(
                label: widget.newProjectAction,
                primary: true,
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            _ErrorBanner(message: _error!),
          ],
        ],
      ),
    );
  }
}

/// 一个项目（含它的任务列表 + 新增任务入口）。
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.localizations,
    required this.project,
    required this.todayIso,
    required this.increments,
    required this.scheduled,
    required this.onAddTask,
    required this.onReschedule,
    required this.onScheduleToday,
    required this.onScheduleIncrement,
    required this.onAppendIncrement,
  });

  final AppLocalizations localizations;
  final ProjectRow project;

  /// 今天（`YYYY-MM-DD`）：头部「已排 MM-DD」与逾期判定的基准日。
  final String todayIso;

  /// 本项目的增量流水（新的在前）。
  final List<IncrementRow> increments;

  /// 本项目已排出的计划行。
  final List<ScheduledItem> scheduled;

  /// 新增任务；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(String title, String? targetDate) onAddTask;

  /// 改期；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(MilestoneRow milestone, String rawDate)
  onReschedule;

  /// 「＋ 排进今天」（项目整体）。
  final Future<String?> Function() onScheduleToday;

  /// 单条增量的「→ 今天」。
  final Future<String?> Function(IncrementRow increment) onScheduleIncrement;

  /// 追加增量；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(
    String progress,
    String blockers,
    String nextStep,
  )
  onAppendIncrement;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final String range = project.startDate == null && project.endDate == null
        ? localizations.projectsNoDateRange
        : '${project.startDate ?? '—'} → ${project.endDate ?? '—'}';

    // 今天是否已经排过（含增量侧排出的行）—— 排过就不必再点一次。
    String? scheduledToday;
    for (final ScheduledItem item in scheduled) {
      if (item.date == todayIso && item.date.length >= 10) {
        scheduledToday = item.date.substring(5);
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.hairSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                range,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 11.5,
                  color: tokens.meta,
                ),
              ),
            ],
          ),
          if (project.goal.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              project.goal,
              style: TextStyle(fontSize: 12, color: tokens.meta),
            ),
          ],
          const SizedBox(height: 6),
          // 「＋ 排进今天」独立成一行用 `Wrap`：标题行里再塞按钮，长项目名 +
          // 长错误文案必炸 RenderFlex。
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _AsyncGhostButton(
                label: localizations.projectsScheduleTodayAction,
                onPressed: onScheduleToday,
              ),
              if (scheduledToday != null)
                Text(
                  localizations.projectsScheduledOn.replaceAll(
                    '{date}',
                    scheduledToday,
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 10.5,
                    color: tokens.faint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (project.milestones.isEmpty)
            Text(
              localizations.projectsNoTask,
              style: TextStyle(fontSize: 11.5, color: tokens.faint),
            )
          else
            for (final MilestoneRow milestone in project.milestones)
              _MilestoneLine(
                milestone: milestone,
                overdue: milestoneOverdue(milestone, todayIso),
                rescheduleAction: localizations.projectsRescheduleAction,
                onReschedule: onReschedule,
              ),
          const SizedBox(height: 8),
          _TaskForm(
            taskTitleHint: localizations.projectsTaskTitleHint,
            targetDateHint: localizations.projectsTargetDateHint,
            addTaskAction: localizations.projectsAddTaskAction,
            onSubmit: onAddTask,
          ),
          const SizedBox(height: 10),
          _IncrementSection(
            localizations: localizations,
            todayIso: todayIso,
            increments: increments,
            scheduled: scheduled,
            onScheduleIncrement: onScheduleIncrement,
            onAppendIncrement: onAppendIncrement,
          ),
        ],
      ),
    );
  }
}

/// 一条任务（标题 + 目标日 + 改期）。
class _MilestoneLine extends StatefulWidget {
  const _MilestoneLine({
    required this.milestone,
    required this.overdue,
    required this.rescheduleAction,
    required this.onReschedule,
  });

  final MilestoneRow milestone;

  /// 目标日已过且未达成（见 [milestoneOverdue]）：给一个不显眼的小字标记，
  /// 不弹窗、不染红、不做动画、不新增色值。
  final bool overdue;

  final String rescheduleAction;

  /// 改期；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(MilestoneRow milestone, String rawDate)
  onReschedule;

  @override
  State<_MilestoneLine> createState() => _MilestoneLineState();
}

class _MilestoneLineState extends State<_MilestoneLine> {
  bool _busy = false;
  String? _error;

  Future<void> _openReschedule() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final TextEditingController controller =
        TextEditingController(text: widget.milestone.targetDate ?? '');
    final String? raw = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(t.projectsRescheduleAction),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.projectsTargetDateHint),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? error = await widget.onReschedule(widget.milestone, raw);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              widget.milestone.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: tokens.ink),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.milestone.targetDate ?? '—',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 11.5,
              color: tokens.meta,
            ),
          ),
          if (widget.overdue) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).projectsMilestoneOverdue,
              key: ValueKey<String>('milestone-overdue-${widget.milestone.id}'),
              style: TextStyle(fontSize: 10.5, color: tokens.faint),
            ),
          ],
          const SizedBox(width: 8),
          if (_error != null) ...<Widget>[
            const SizedBox(width: 8),
            Flexible(child: _ErrorBanner(message: _error!)),
          ],
          _GhostButton(
            label: widget.rescheduleAction,
            busy: _busy,
            onPressed: _openReschedule,
          ),
        ],
      ),
    );
  }
}

/// 新增任务表单（标题 + 目标日期）。
class _TaskForm extends StatefulWidget {
  const _TaskForm({
    required this.taskTitleHint,
    required this.targetDateHint,
    required this.addTaskAction,
    required this.onSubmit,
  });

  final String taskTitleHint;
  final String targetDateHint;
  final String addTaskAction;

  /// 提交；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(String title, String? targetDate) onSubmit;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _date = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = '任务标题不能为空');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final String raw = _date.text.trim();
      error = await widget.onSubmit(title, raw.isEmpty ? null : raw);
    } catch (error_) {
      error = '$error_';
    }
    if (!mounted) {
      return;
    }
    if (error == null) {
      _title.clear();
      _date.clear();
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: TextField(
                controller: _title,
                decoration:
                    _fieldDecoration(tokens: tokens, hint: widget.taskTitleHint),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _date,
                decoration:
                    _fieldDecoration(tokens: tokens, hint: widget.targetDateHint),
              ),
            ),
            _GhostButton(
              label: widget.addTaskAction,
              busy: _busy,
              onPressed: _submit,
            ),
          ],
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 6),
          _ErrorBanner(message: _error!),
        ],
      ],
    );
  }
}

/// 小按钮（账页的幽灵按钮 / 主按钮两态）。
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final bool enabled = !busy;
    final Color background = !enabled
        ? tokens.sunken
        : primary
            ? tokens.ink
            : tokens.card;
    final Color foreground = !enabled
        ? tokens.faint
        : primary
            ? tokens.paper
            : tokens.ink2;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 24),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: primary && enabled ? tokens.ink : tokens.hairStrong,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontFamilyFallback: AppFonts.bodyFallback,
              fontSize: 12.5,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// 页级错误横幅。
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.accent, width: 1),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12, color: tokens.accentInk),
      ),
    );
  }
}

/// 空态提示。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: tokens.faint),
      ),
    );
  }
}

/// 输入框统一外观：圆角 + `hair-strong` 边 + `card` 底。
InputDecoration _fieldDecoration({
  required ThemeTokens tokens,
  required String hint,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        borderSide: BorderSide(color: color, width: 1),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 12, color: tokens.faint),
    isDense: true,
    filled: true,
    fillColor: tokens.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(tokens.hairStrong),
    enabledBorder: border(tokens.hairStrong),
    focusedBorder: border(tokens.ink),
  );
}

/// 自带「忙 / 错」两态的小按钮：点下去自己进 busy，失败就地摆一行错误。
///
/// 为什么不做成 `FutureBuilder`：按钮的忙碌态是**点击驱动**的，跟 widget 生命周期
/// 无关；失败文案也得留在原地直到下一次点击，不该被重建冲掉。
class _AsyncGhostButton extends StatefulWidget {
  const _AsyncGhostButton({required this.label, required this.onPressed});

  final String label;

  /// 执行；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function() onPressed;

  @override
  State<_AsyncGhostButton> createState() => _AsyncGhostButtonState();
}

class _AsyncGhostButtonState extends State<_AsyncGhostButton> {
  bool _busy = false;
  String? _error;

  Future<void> _run() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? error = await widget.onPressed();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GhostButton(label: widget.label, busy: _busy, onPressed: _run),
        if (error != null) ...<Widget>[
          const SizedBox(height: 4),
          _ErrorBanner(message: error),
        ],
      ],
    );
  }
}

/// 增量区：已有流水（只读）+ 追加表单。
///
/// 增量**不可编辑** —— 写错了只能再追加一条更正。所以这里刻意没有任何编辑 /
/// 删除入口，底部那句 `projectsIncrementAppendOnly` 就是把这条纪律写给用户看。
class _IncrementSection extends StatefulWidget {
  const _IncrementSection({
    required this.localizations,
    required this.todayIso,
    required this.increments,
    required this.scheduled,
    required this.onScheduleIncrement,
    required this.onAppendIncrement,
  });

  final AppLocalizations localizations;
  final String todayIso;
  final List<IncrementRow> increments;
  final List<ScheduledItem> scheduled;

  /// 单条增量排进今天；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(IncrementRow increment) onScheduleIncrement;

  /// 追加增量；返回 `null` = 成功，非空 = 错误文案。
  final Future<String?> Function(
    String progress,
    String blockers,
    String nextStep,
  )
  onAppendIncrement;

  @override
  State<_IncrementSection> createState() => _IncrementSectionState();
}

class _IncrementSectionState extends State<_IncrementSection> {
  final TextEditingController _progress = TextEditingController();
  final TextEditingController _blockers = TextEditingController();
  final TextEditingController _nextStep = TextEditingController();

  bool _busy = false;

  /// 正在排期的那条增量的 id（列表里逐行独立的忙碌态）。
  String? _busyIncrementId;

  String? _error;

  @override
  void dispose() {
    _progress.dispose();
    _blockers.dispose();
    _nextStep.dispose();
    super.dispose();
  }

  Future<void> _schedule(IncrementRow increment) async {
    if (_busyIncrementId != null) {
      return;
    }
    setState(() {
      _busyIncrementId = increment.id;
      _error = null;
    });
    final String? error = await widget.onScheduleIncrement(increment);
    if (!mounted) {
      return;
    }
    setState(() {
      _busyIncrementId = null;
      _error = error;
    });
  }

  Future<void> _append() async {
    if (_busy) {
      return;
    }
    final String progress = _progress.text.trim();
    if (progress.isEmpty) {
      setState(() => _error = '至少写一句这次推进了什么');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? error = await widget.onAppendIncrement(
      progress,
      _blockers.text.trim(),
      _nextStep.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (error == null) {
      _progress.clear();
      _blockers.clear();
      _nextStep.clear();
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  /// 这条增量今天已经有排出的计划行了。
  bool _scheduledToday(IncrementRow increment) => widget.scheduled.any(
    (ScheduledItem item) =>
        item.sourceType == PlanSourceType.increment.code &&
        item.sourceId == increment.id &&
        item.date == widget.todayIso,
  );

  /// 列表行正文：优先「推进了什么」，退到「下一步」，都没有就给破折号。
  static String _lineText(IncrementRow increment) {
    if (increment.progress.isNotEmpty) {
      return increment.progress;
    }
    if (increment.nextStep.isNotEmpty) {
      return increment.nextStep;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final AppLocalizations t = widget.localizations;
    final String? error = _error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.projectsIncrementTitle,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: tokens.meta,
          ),
        ),
        if (widget.increments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          for (final IncrementRow increment in widget.increments)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Text(
                    increment.date,
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 10.5,
                      color: tokens.faint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _lineText(increment),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.ink2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_scheduledToday(increment)) ...<Widget>[
                    Text(
                      t.projectsScheduledOn.replaceAll(
                        '{date}',
                        increment.date.substring(5),
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontFamilyFallback: AppFonts.monoFallback,
                        fontSize: 10.5,
                        color: tokens.faint,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _GhostButton(
                    label: t.projectsIncrementToTodayAction,
                    busy: _busyIncrementId == increment.id,
                    onPressed: () => _schedule(increment),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: TextField(
                controller: _progress,
                decoration: _fieldDecoration(
                  tokens: tokens,
                  hint: t.projectsIncrementProgressHint,
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _blockers,
                decoration: _fieldDecoration(
                  tokens: tokens,
                  hint: t.projectsIncrementBlockersHint,
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _nextStep,
                decoration: _fieldDecoration(
                  tokens: tokens,
                  hint: t.projectsIncrementNextStepHint,
                ),
              ),
            ),
            _GhostButton(
              // 空列表时是「写第一条增量」，有流水时是「追加增量」——同一条
              // INSERT，只是把「第一条」这个心理起步门槛说出来。
              label: widget.increments.isEmpty
                  ? t.projectsIncrementEmptyAction
                  : t.projectsIncrementAddAction,
              busy: _busy,
              onPressed: _append,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          t.projectsIncrementAppendOnly,
          style: TextStyle(fontSize: 10.5, color: tokens.faint),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: 6),
          _ErrorBanner(message: error),
        ],
      ],
    );
  }
}
