import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StateProvider` 在 3.5.0 起只在 legacy.dart 导出（与 `providers.dart` 同口径）。
import 'package:flutter_riverpod/legacy.dart';

import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/date_bar.dart';
import '../widgets/day_timeline.dart';
import '../widgets/timeline/day_grid.dart';
import '../widgets/timeline/unscheduled_strip.dart';
import '../widgets/loop_progress_ring.dart';
import '../widgets/mood_section.dart';
import '../widgets/priority_marks.dart';
import '../widgets/quick_todo_dialog.dart';
import '../widgets/review_section.dart';
import '../widgets/section_card.dart';

/// 今日页：一天工作的唯一入口（B 版「墨径 · 账页流」）。
///
/// 本页**不自建壳**：`Scaffold` / `AppBar` / 导航全部由 `LedgerShell` 承担，
/// 这里只输出「账页正文」这一列。历史提交里本页是 `Scaffold` + `AppBar` 的
/// 独立页，W3 装配后被降级成内容体，理由见 `docs/B1_验收记录.md` 遗留 #1。
///
/// 自上而下：日期条 → 闭环脊线 → 待办池入口 → 方格时间轴 → 两段账页
/// （晨定计划 / 晚复盘心态）。
///
/// 页头（标题「今日」/ 日期副标 / 完整·极简切换）已删除：这三样在
/// `LedgerShell` 的导航与日期条里已经有等价表达，重复一遍只是浪费首屏高度。
///
/// 打卡与站会已迁出本页（B2）：习惯打卡落在 `HabitsPage`，方格时间轴本身
/// 就是排期与待办的主入口。吸底卡带不再是本列的一行。
///
/// 极简模式只做**渲染裁剪**（隐藏象限标签与详情行），不隐藏数据 ——
/// 切回完整模式原样可见，所以「极简隐藏字段不丢数据」在 UI 层也成立。
class TodayPage extends ConsumerWidget {
  /// 创建今日页。
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 与 `dayLogProvider` / `planItemsProvider` 同源：切日必须整页跟着换，
    // 否则标题停在今天、内容却是别的一天（M16-6 的根因）。
    final date = ref.watch(selectedDateProvider);
    final dayLog = ref.watch(dayLogProvider);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // 底部键条（`kShellKeyHints`）承诺的两条动作必须有真实绑定，
        // 否则键条就是假提示 —— 见 `docs/B1_验收记录.md` §5 #3。
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _NewTodoIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, control: true):
            _CheckinFirstIntent(),
        // 「回到今天」原先错绑在 `Ctrl+D` 上，与键条文案「打卡第一条未打习惯」
        // 语义不符；现移到 `Ctrl+T`。键条是精选提示，不列这一条。
        SingleActivator(LogicalKeyboardKey.keyT, control: true):
            _GoTodayIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _ShiftDayIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _ShiftDayIntent(1),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewTodoIntent: _NewTodoAction(
            onInvoke: () => showQuickTodoDialog(context),
          ),
          _CheckinFirstIntent: _CheckinFirstAction(
            onInvoke: () => _checkInFirstHabit(ref),
          ),
          _GoTodayIntent: _GoTodayAction(
            onInvoke: () => ref.read(selectedDateProvider.notifier).state =
                ref.read(todayProvider),
          ),
          _ShiftDayIntent: _ShiftDayAction(
            onInvoke: (delta) {
              final current = ref.read(selectedDateProvider);
              ref.read(selectedDateProvider.notifier).state = shiftIsoDate(
                current,
                delta,
              );
            },
          ),
        },
        child: dayLog.when(
          loading: () => const _LoadingPane(),
          error: (error, stack) => _ErrorPane(error: error),
          data: (log) => log == null
              ? const _NotePane(text: '当日日志尚未建立')
              : _TodayBody(date: date, log: log),
        ),
      ),
    );
  }
}

/// 今日页正文：一列，纵向不设限（外层 `LedgerPaper` 负责滚动）。
class _TodayBody extends ConsumerWidget {
  const _TodayBody({required this.date, required this.log});

  final String date;
  final DayLogData log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minimal = log.mode == dayModeMinimal;
    // 快捷键造成的状态变化要有可见回落（不许静默）：横幅贴在日期条下方。
    final notice = ref.watch(_todayNoticeProvider);
    // 未来日只可预排：打卡 / 回填 / 复盘 / 心态一律不开放（spec §H-1）。
    final future = date.compareTo(ref.watch(todayProvider)) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const DateBar(),
        if (notice != null) ...<Widget>[
          const SizedBox(height: 8),
          _NoticeBanner(
            message: notice,
            onDismiss: () =>
                ref.read(_todayNoticeProvider.notifier).state = null,
          ),
        ],
        const SizedBox(height: AppTokens.gapCard),
        LoopProgressRing(
          stats: ref.watch(dayStatsProvider),
          onJump: (segment) => _jumpTo(segment),
        ),
        const SizedBox(height: AppTokens.gapCard),
        const _PoolEntryBar(),
        const SizedBox(height: AppTokens.gapCard),
        DayGrid(date: date, minimal: minimal),
        const SizedBox(height: AppTokens.gapCard),
        const UnscheduledStrip(),
        const SizedBox(height: AppTokens.gapCard),
        _AddPlanItemBar(date: date),
        if (future) ...<Widget>[
          const SizedBox(height: AppTokens.gapCard),
          const _FuturePlanHint(),
        ],
        const SizedBox(height: AppTokens.gapSec),
        DayTimeline(
          sections: <TimelineSection>[
            TimelineSection(
              label: '晚 · 复盘与心态',
              child: future
                  ? const _FutureLockedSection(
                      icon: Icons.nights_stay,
                      title: '复盘与心态在当天开放',
                      detail: '未来日只做预排：到了那天再写复盘与心态。',
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ReviewSection(),
                        SizedBox(height: AppTokens.gapCard),
                        MoodSection(),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// 跳到闭环脊线的某一段。TODO(Task 17)：用 `Scrollable.ensureVisible` 滚到对应段。
  void _jumpTo(DayStatsSegment segment) {
    // Task 15 建立三段骨架后补齐滚动实现；本任务只提供调用点。
  }
}



/// 账页里的次级按钮（替换 `TextButton` / `IconButton` 的默认视觉）。
///
/// 口径：`card` 底 + `hair-strong` 边（**可交互边界一律 hair-strong**）+
/// `ink2` 字；hover 只把底换 `sunken`、字提亮到 `ink`，不位移不加阴影。
class _GhostAction extends StatefulWidget {
  const _GhostAction({
    required this.label,
    this.onPressed,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// 行内小号形态（高度 22，字号 11.5）。
  final bool dense;

  @override
  State<_GhostAction> createState() => _GhostActionState();
}

class _GhostActionState extends State<_GhostAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered && enabled ? AppTokens.sunken : AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              constraints: BoxConstraints(minHeight: widget.dense ? 22 : 28),
              padding: EdgeInsets.symmetric(
                horizontal: widget.dense ? 6 : 10,
                vertical: widget.dense ? 2 : 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: AppTokens.hairStrong, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: _bodyStyle(
                  size: widget.dense ? 11.5 : 12.5,
                  color: !enabled
                      ? AppTokens.faint
                      : (_hovered ? AppTokens.ink : AppTokens.ink2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 未来日的「只可预排」提示。
///
/// 键名 `future-plan-hint` 是既有验收锚点（`ledger_dock_test.dart:227`）：
/// 未来日必须给出可见提示，而不是把输入框变成黑洞。
class _FuturePlanHint extends StatelessWidget {
  const _FuturePlanHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('future-plan-hint'),
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '未来日只可预排：可以先写计划，到了那天才能打卡与回填。',
          style: _bodyStyle(size: 12, color: AppTokens.meta),
        ),
      ),
    );
  }
}

/// 「从待办池捞」入口。
///
/// 旧计划段整块删除后，这个入口必须留在方格旁边 —— 它是把待办池条目
/// 变成今日排期的第一条路径，入口跟着段一起消失就成了「功能静默丢失」。
/// 键名 `plan-pool-entry` 是既有验收锚点（200% 文字缩放断言读它的矩形）。
class _PoolEntryBar extends StatelessWidget {
  const _PoolEntryBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('plan-pool-entry'),
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _GhostAction(
              label: '＋ 从待办池捞',
              dense: true,
              onPressed: () => showPullFromPoolDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// 新增条目输入行。
class _AddPlanItemBar extends ConsumerStatefulWidget {
  const _AddPlanItemBar({required this.date});

  final String date;

  @override
  ConsumerState<_AddPlanItemBar> createState() => _AddPlanItemBarState();
}

class _AddPlanItemBarState extends ConsumerState<_AddPlanItemBar> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  /// 本条新条目的四维度优先级；null = 不分级（与既往行为一致）。
  ///
  /// 提交成功后清空：优先级是**每条目**的属性，不该被下一条默默继承。
  Quadrant? _quadrant;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(repositoriesProvider).planItem.create(
            date: widget.date,
            title: title,
            quadrant: _quadrant,
          );
      _controller.clear();
      if (mounted) {
        setState(() => _quadrant = null);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: _bodyStyle(size: 13, color: AppTokens.ink),
                decoration: InputDecoration(
                  hintText: '添加计划条目…',
                  hintStyle: _bodyStyle(size: 13, color: AppTokens.faint),
                  isDense: true,
                  filled: true,
                  fillColor: AppTokens.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: _fieldBorder(AppTokens.hairStrong),
                  enabledBorder: _fieldBorder(AppTokens.hairStrong),
                  focusedBorder: _fieldBorder(AppTokens.ink, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _GhostAction(
              label: '+ 手写一条',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 优先级芯片贴在输入行**下方**而不是右侧：右侧放不下四枚芯片，
        // 200% 文字缩放下会先把输入框挤成一条缝。
        Align(
          alignment: Alignment.centerLeft,
          child: PriorityMarkPicker(
            value: _quadrant,
            enabled: !_submitting,
            onChanged: (next) => setState(() => _quadrant = next),
          ),
        ),
      ],
    );
  }
}

/// 输入框圆角边（统一 4px，不用 Material 默认的大圆角胶囊）。
OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTokens.radius),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// 未来日的锁定占位卡。
///
/// spec §H-1 把打卡、回填、复盘、心态限定在「今天与过去」；未来日只留预排。
/// 占位卡保留原区块的标题骨架，用户看得见「这里以后能做什么」，而不是
/// 整段消失后以为界面出错。
class _FutureLockedSection extends StatelessWidget {
  const _FutureLockedSection({
    required this.icon,
    required this.title,
    required this.detail,
  });

  /// 区块图标，沿用被替换区块的图标以保持视觉连续。
  final IconData icon;

  /// 区块标题。
  final String title;

  /// 为什么现在不可用的说明。
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: icon,
      title: title,
      subtitle: '未来日只做预排',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(detail, style: _bodyStyle(size: 12, color: AppTokens.meta)),
      ),
    );
  }
}

/// 加载态：固定高度的小环，避免整页塌成 0 高。
class _LoadingPane extends StatelessWidget {
  const _LoadingPane();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// 空态提示（不居中：账页正文左对齐）。
class _NotePane extends StatelessWidget {
  const _NotePane({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: _bodyStyle(size: 12.5, color: AppTokens.faint)),
    );
  }
}

/// 错误面板：把异常原文显示出来，避免「静默空白」。
///
/// 用赭石文字版（`accentInk`）：这是 B 版允许赭石出现的 5 处之一（警示文案）。
class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SelectableText(
        '$error',
        style: _bodyStyle(size: 12.5, color: AppTokens.accentInk),
      ),
    );
  }
}

/// 右轨「习惯速览」：所选日的排程习惯与勾选状态。
///
/// 数据与 [HabitCheckinStrip] 同源（`habitsForTodayProvider` +
/// `habitCheckinsProvider`），**勾选动作只有卡带一处**：这里仍是只读总览，
/// 避免同一状态出现两个写入点。
///
/// 但每行都包了一层 `Draggable<String>`：右轨合并面板拆掉后，这里是习惯
/// 拖进方格时间轴的**唯一**来源（也仅此一处）。payload 逐字 `habit:<habit.id>`，
/// 且数据源与 `day_grid.dart` 的 `case 'habit'` 读的是同一个
/// `habitsForTodayProvider` —— 两边 id 必然对得上。
class HabitOverviewPanel extends ConsumerWidget {
  /// 创建习惯速览面板。
  const HabitOverviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsForTodayProvider);
    final checkinsAsync = ref.watch(habitCheckinsProvider);

    if (habitsAsync.hasError || checkinsAsync.hasError) {
      return const _RailNote(text: '习惯速览加载失败', danger: true);
    }
    if (!habitsAsync.hasValue || !checkinsAsync.hasValue) {
      return const _RailNote(text: '正在加载习惯…');
    }

    final habits = habitsAsync.value!;
    if (habits.isEmpty) {
      return const _RailNote(text: '所选日没有排程习惯');
    }

    final doneIds = <String>{
      for (final checkin in checkinsAsync.value!)
        if (checkin.status == CheckinStatus.done.code) checkin.habitId,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final habit in habits)
          Draggable<String>(
            key: ValueKey<String>('overview-habit-${habit.id}'),
            data: 'habit:${habit.id}',
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: _HabitDragChip(label: habit.name),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: <Widget>[
                      Text(
                        doneIds.contains(habit.id) ? '✓' : '○',
                        style: _monoStyle(
                          size: 12,
                          color: doneIds.contains(habit.id)
                              ? AppTokens.ink
                              : AppTokens.faint,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: _bodyStyle(
                            size: 12.5,
                            color: doneIds.contains(habit.id)
                                ? AppTokens.ink
                                : AppTokens.meta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 习惯拖拽中的窄条卡片（与「待办列表」的拖拽 feedback 同规格）。
///
/// `feedback` 挂在 overlay 上，必须自带 `Material`，否则文字没有底色。
class _HabitDragChip extends StatelessWidget {
  const _HabitDragChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: AppTokens.hairStrong),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _bodyStyle(size: 12, color: AppTokens.ink),
        ),
      ),
    );
  }
}

/// 右轨「闭环提示」：把闭环脊线的四个缺口摊成文字。
///
/// 四行全部来自 [dayStatsProvider]（唯一口径），缺口状态用 `accentInk`；
/// 这里不自己算比例，也不算「分母为 0 = 100%」。
class LoopHintPanel extends ConsumerWidget {
  /// 创建闭环提示面板。
  const LoopHintPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dayStatsProvider);
    final rate = stats.backfillRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _RailRow(
          label: '计划缺口',
          value: '${stats.planPending}',
          danger: stats.planPending > 0,
        ),
        _RailRow(
          label: '回填缺口',
          value: rate == null
              ? '—'
              : '${stats.planDone - stats.backfilled}',
          danger: stats.planDone > stats.backfilled,
        ),
        _RailRow(
          label: '复盘',
          value: stats.reviewDone ? '已写' : '未写',
          danger: !stats.reviewDone,
        ),
        _RailRow(
          label: '心态',
          value: stats.moodDone ? '已记' : '未记',
          danger: !stats.moodDone,
        ),
      ],
    );
  }
}

/// 右轨一行：左标签 + 右数值（数值 mono + 等宽数字）。
class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: _bodyStyle(size: 12.5, color: AppTokens.meta)),
          ),
          Text(
            value,
            style: _monoStyle(
              size: 12,
              color: danger ? AppTokens.accentInk : AppTokens.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 右轨提示文案。
class _RailNote extends StatelessWidget {
  const _RailNote({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _bodyStyle(
        size: 12.5,
        color: danger ? AppTokens.accentInk : AppTokens.faint,
      ),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({
  double size = 12.5,
  Color color = AppTokens.ink,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
    decoration: decoration,
  );
}

/// 数字/键帽字体样式（`AppFonts.mono` + `tabular-nums`）。
TextStyle _monoStyle({double size = 11.5, Color color = AppTokens.faint}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

/// 「手写一条」意图（`Ctrl+N`，键条第一条）。
class _NewTodoIntent extends Intent {
  const _NewTodoIntent();
}

/// 「打卡第一条未打习惯」意图（`Ctrl+D`，键条第二条）。
class _CheckinFirstIntent extends Intent {
  const _CheckinFirstIntent();
}

/// 「回到今天」意图（`Ctrl+T`）。
///
/// 这条**不在键条上**（键条只收精选动作）；`Ctrl+D` 此前错绑到这里，
/// 与键条文案「打卡第一条未打习惯」语义不符，已按 C7 的 D-b 拆开。
class _GoTodayIntent extends Intent {
  const _GoTodayIntent();
}

/// 打开「手写一条」面板。
class _NewTodoAction extends Action<_NewTodoIntent> {
  _NewTodoAction({required this.onInvoke});

  /// 实际动作。
  final Future<void> Function() onInvoke;

  @override
  Object? invoke(_NewTodoIntent intent) => onInvoke();
}

/// 给选中日第一条未打卡的习惯补一次打卡。
class _CheckinFirstAction extends Action<_CheckinFirstIntent> {
  _CheckinFirstAction({required this.onInvoke});

  /// 实际动作。
  final Future<void> Function() onInvoke;

  @override
  Object? invoke(_CheckinFirstIntent intent) => onInvoke();
}

/// 「换一天」意图（`←` / `→`）。
class _ShiftDayIntent extends Intent {
  const _ShiftDayIntent(this.delta);

  /// 日期偏移天数：`-1` 前一天、`1` 后一天。
  final int delta;
}

/// 把选中日期复位到今天。
class _GoTodayAction extends Action<_GoTodayIntent> {
  _GoTodayAction({required this.onInvoke});

  /// 实际动作。
  final void Function() onInvoke;

  @override
  Object? invoke(_GoTodayIntent intent) {
    onInvoke();
    return null;
  }
}

/// 按方向键换一天。
///
/// 焦点在文本输入域内时 [isEnabled] 返回 false —— `ShortcutManager` 拿到
/// false 后返回 `KeyEventResult.ignored`，事件继续冒泡给 `WidgetsApp` 的
/// `DefaultTextEditingShortcuts`，输入框的光标移动才不会被抢走。
class _ShiftDayAction extends Action<_ShiftDayIntent> {
  _ShiftDayAction({required this.onInvoke});

  /// 实际动作。
  final void Function(int delta) onInvoke;

  @override
  bool isEnabled(_ShiftDayIntent intent) => !isTextInputFocused();

  @override
  Object? invoke(_ShiftDayIntent intent) {
    onInvoke(intent.delta);
    return null;
  }
}

/// 焦点是否在文本输入域内。
///
/// `←/→` 换天只在非输入态生效，否则会抢走输入框的光标移动。
bool isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return false;
  }
  // `EditableText` 把焦点节点挂在内部的 `Focus` 上，所以节点自己的
  // context 指向 `Focus` 而不是 `EditableText`，两种形态都要认。
  return context.widget is EditableText ||
      context.findAncestorStateOfType<EditableTextState>() != null;
}

/// 今日页的一次性提示（快捷键结果、被拒动作）。
///
/// 本列**没有 `Scaffold`**（骨架由 `LedgerShell` 的 `Material` 自建），
/// `SnackBar` 找不到可靠的定位锚点，所以提示走页内横幅。
final StateProvider<String?> _todayNoticeProvider =
    StateProvider<String?>((ref) => null);

/// `Ctrl+D`：给当前选中日第一条还没打勾的习惯补一次打卡。
///
/// 口径与习惯页的打卡卡带一致（`status == done.code` 才算已打卡）。
/// 未来日按 spec §H-1 只做预排 —— 拒绝打卡，但**必须给可见提示**，不许静默。
Future<void> _checkInFirstHabit(WidgetRef ref) async {
  final date = ref.read(selectedDateProvider);
  final today = ref.read(todayProvider);
  if (date.compareTo(today) > 0) {
    ref.read(_todayNoticeProvider.notifier).state = '未来日只做预排：到了那天再打卡。';
    return;
  }
  // B2（2026-11-12）：今日页与壳层都不再常驻 watch 这两个 provider（习惯区与
  // 打卡条已摘除），所以这里必须**等**数据回来，而不是同步读一次快照就判
  // 「没准备好」—— 否则冷启动后第一次 `Ctrl+D` 必然落进岔路，键条就是假提示。
  final List<HabitData> habits;
  final List<HabitCheckinData> checkins;
  try {
    habits = await ref.read(habitsForTodayProvider.future);
    checkins = await ref.read(habitCheckinsProvider.future);
  } catch (error) {
    ref.read(_todayNoticeProvider.notifier).state = '习惯数据加载失败：$error';
    return;
  }
  final doneIds = <String>{
    for (final row in checkins)
      if (row.status == CheckinStatus.done.code) row.habitId,
  };
  HabitData? target;
  for (final habit in habits) {
    if (!doneIds.contains(habit.id)) {
      target = habit;
      break;
    }
  }
  if (target == null) {
    ref.read(_todayNoticeProvider.notifier).state = '今天没有待打卡的习惯';
    return;
  }
  try {
    await ref
        .read(repositoriesProvider)
        .habit
        .upsertCheckin(habitId: target.id, date: date);
    ref.read(_todayNoticeProvider.notifier).state = '已打卡：${target.name}';
  } catch (error) {
    ref.read(_todayNoticeProvider.notifier).state = '打卡失败：$error';
  }
}

/// 页内提示横幅（`accentWash` 底 + `accent` 边，与待办池页横幅同 token）。
class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message, required this.onDismiss});

  /// 提示正文。
  final String message;

  /// 关掉提示（只清状态，不做别的）。
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.accent, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 200% 缩放下文案会变长：用 `Expanded` 换行，不把「知道了」挤出去。
          Expanded(
            child: Text(
              message,
              style: _bodyStyle(size: 12.5, color: AppTokens.accentInk),
            ),
          ),
          const SizedBox(width: 8),
          _GhostAction(label: '知道了', dense: true, onPressed: onDismiss),
        ],
      ),
    );
  }
}
