import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StateProvider` 在 3.5.0 起只在 legacy.dart 导出（与 `providers.dart` 同口径）。
import 'package:flutter_riverpod/legacy.dart';

import '../data/project_store.dart';
import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/date_picker_sheet.dart';
import '../widgets/timeline/day_grid.dart';
import '../widgets/timeline/slot_state.dart';
import '../widgets/timeline/timeline_store.dart';
import '../widgets/timeline/unscheduled_strip.dart';
import '../widgets/loop_progress_ring.dart';
import '../widgets/mood_section.dart';
import '../widgets/priority_marks.dart';
import '../widgets/quick_todo_dialog.dart';
import '../widgets/quote_banner.dart';
import '../widgets/review_section.dart';
import '../widgets/section_card.dart';

/// 今日页：一天工作的唯一入口（B 版「墨径 · 账页流」）。
///
/// 本页**不自建壳**：`Scaffold` / `AppBar` / 导航全部由 `LedgerShell` 承担，
/// 这里只输出「账页正文」这一列。历史提交里本页是 `Scaffold` + `AppBar` 的
/// 独立页，W3 装配后被降级成内容体，理由见 `docs/B1_验收记录.md` 遗留 #1。
///
/// 自上而下：日期条 → 方格时间轴 → 未排期带 → 手写一条 → 两段账页
/// （晨定计划 / 晚复盘心态）。闭环四段比例条已并入右栏「闭环提示」
/// （W3 / Task 38），中栏不再有脊线。
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
    // 快捷键造成的状态变化要有可见回落（不许静默）：警句横幅贴在日期条下方，其后是提示横幅。
    final notice = ref.watch(_todayNoticeProvider);
    // 未来日只可预排：打卡 / 回填 / 复盘 / 心态一律不开放（spec §H-1）。
    final future = date.compareTo(ref.watch(todayProvider)) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // 日期条**不在这里**：它是壳的吸顶头（`LedgerShell.pinnedHeader`），
        // 坐在滚动区之外。原先放在本列第一行 = 坐在滚动区里，往下一翻方格
        // 时间轴就跟着滚走，用户失去「现在看的是哪一天」这个锚点。
        const SizedBox(height: AppTokens.gapCard),
        const QuoteBanner(),
        if (notice != null) ...<Widget>[
          const SizedBox(height: 8),
          _NoticeBanner(
            message: notice,
            onDismiss: () =>
                ref.read(_todayNoticeProvider.notifier).state = null,
          ),
        ],
        // 「＋ 从待办池捞」入口已删（Task 45 需求 4）：计划列表上部不再挂这个
        // 入口，也不做替代。两只 `gapCard` 收成一只 —— 否则中间会留下一条
        // 32px 的空带，读起来像「这里本来就缺一块」。
        const SizedBox(height: AppTokens.gapCard),
        DayGrid(date: date, minimal: minimal),
        const SizedBox(height: AppTokens.gapCard),
        const UnscheduledStrip(),
        // 未排期带与「手写一条」是两个语义区：上面是「库里已有、但没排时刻」
        // 的事实，下面是「新写一条」的写入面。原先只隔 12px，读起来像同一团。
        // 这里只补**视觉**分区（段间距 + 1px 装饰线），
        // **不删任何行、不做任何过滤**：用户库里真实的未排期条目
        // （例如「执行日志开发」）照样一条不少地留在上面。
        const SizedBox(height: AppTokens.gapSec),
        const _HandwrittenDivider(),
        const SizedBox(height: 12),
        _AddPlanItemBar(date: date),
        if (future) ...<Widget>[
          const SizedBox(height: AppTokens.gapCard),
          const _FuturePlanHint(),
        ],
        const SizedBox(height: AppTokens.gapSec),
        // 复盘 + 心态不再走 `DayTimeline` / `TimelineSection` 的左栏包装
        // （Task 40 需求 4）：左栏那套「节点 + ✓ 已闭合」是**时间轴段**的心智，
        // 而复盘不是一天的某一格，它是一天结束时的另一块正文。包在段里就多出
        // 一条 52+10px 的悬挂缩进，与上方方格、待办池、手写条全都不对齐。
        // 这里直接铺成普通区块：与其它模块同一条左基线，且页面上不再出现
        // 「晚 · 复盘与心态」「已闭合」这两处只属于时间轴骨架的文案。
        if (future)
          const _FutureLockedSection(
            icon: Icons.nights_stay,
            title: '复盘与心态在当天开放',
            detail: '未来日只做预排：到了那天再写复盘与心态。',
          )
        else
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ReviewSection(),
              SizedBox(height: AppTokens.gapCard),
              MoodSection(),
            ],
          ),
      ],
    );
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
    final t = context.tokens;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered && enabled ? t.sunken : t.card,
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
                border: Border.all(color: t.hairStrong, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: _bodyStyle(
                  size: widget.dense ? 11.5 : 12.5,
                  color: !enabled ? t.faint : (_hovered ? t.ink : t.ink2),
                  tokens: t,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 合并按钮里可选的三件事：改日期 / 改时刻 / 清除时刻。
///
/// 用枚举而不是字符串：`showMenu` 的返回值是值对象，写错一个字母不会变成
/// 「菜单点了没反应」，而是编译期就红。
enum _DateTimeActionKind {
  /// 走全站唯一日期组件 [DatePickerSheet]。
  pickDate,

  /// 走 Material `showTimePicker`。
  pickTime,

  /// 把开始时刻退回未排（`planned_start` 落 null）。
  clearTime,
}

/// 「日期 · X   时间 · Y」二合一按钮（Task 40 需求 2）。
///
/// 三条硬约束：
/// 1. **一个按钮**：整块只有一个 `InkWell`，不存在「点左边改日期、点右边改时刻」
///    这种要靠用户自己摸的隐式分区；
/// 2. **两条链路原样复用**：菜单选「改日期」直接调 [onPickDate]（内部是
///    `DatePickerSheet`），选「改时刻」直接调 [onPickTime]（内部是
///    `showTimePicker`）——本按钮不新增任何取值组件；
/// 3. **旧锚点不消失**：日期 / 时刻两段文本各自保留原 key
///    （`add-plan-date-chip` / `add-plan-time-chip`），「清除时刻」菜单项保留
///    `add-plan-time-clear`。合成一个按钮不该顺手让既有断言失明。
///
/// 为什么改成弹出菜单而不是连弹两个对话框：连弹会强制用户每次都过两道弹层，
/// 只想改时刻也得先确认一遍日期。菜单把「改哪一半」交还用户，默认不打扰。
class _DateTimeAction extends StatefulWidget {
  const _DateTimeAction({
    super.key,
    required this.date,
    required this.startMinute,
    required this.enabled,
    required this.onPickDate,
    required this.onPickTime,
    required this.onClearTime,
  });

  /// 本条会落到的日期（用户改过就是改后的那天，没改就是页面所选日）。
  final String date;

  /// 开始时刻（当日分钟数）；null = 未排，落库时 `planned_start` 为 null。
  final int? startMinute;

  /// 为 false 时整体只读（提交中）。
  final bool enabled;

  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;

  @override
  State<_DateTimeAction> createState() => _DateTimeActionState();
}

class _DateTimeActionState extends State<_DateTimeAction> {
  bool _hovered = false;

  Future<void> _openMenu() async {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Rect rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
    final _DateTimeActionKind? picked = await showMenu<_DateTimeActionKind>(
      context: context,
      // 菜单贴着按钮左上角展开：位置来自按钮自己的矩形，不写死坐标。
      position: RelativeRect.fromRect(
        rect,
        Offset.zero & MediaQuery.sizeOf(context),
      ),
      items: <PopupMenuEntry<_DateTimeActionKind>>[
        const PopupMenuItem<_DateTimeActionKind>(
          value: _DateTimeActionKind.pickDate,
          child: Text('改日期'),
        ),
        const PopupMenuItem<_DateTimeActionKind>(
          value: _DateTimeActionKind.pickTime,
          child: Text('改时刻'),
        ),
        // 「清除时刻」只在真的排了时刻时出现：没排的时刻没有可清的东西，
        // 常驻一项空动作等于给用户一个点了没反应的按钮。
        if (widget.startMinute != null)
          const PopupMenuItem<_DateTimeActionKind>(
            value: _DateTimeActionKind.clearTime,
            child: Text(
              '清除时刻',
              key: ValueKey<String>('add-plan-time-clear'),
            ),
          ),
      ],
    );
    if (!mounted || picked == null) {
      return;
    }
    switch (picked) {
      case _DateTimeActionKind.pickDate:
        widget.onPickDate();
      case _DateTimeActionKind.pickTime:
        widget.onPickTime();
      case _DateTimeActionKind.clearTime:
        widget.onClearTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String timeLabel = widget.startMinute == null
        ? '时间 · 未排'
        : '时间 · ${formatMinute(widget.startMinute!)}';
    final t = context.tokens;
    final Color ink = !widget.enabled
        ? t.faint
        : (_hovered ? t.ink : t.ink2);
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: '日期 ${widget.date}，$timeLabel，点击修改日期或时刻',
        child: MouseRegion(
          cursor:
              widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: _hovered && widget.enabled ? t.sunken : t.card,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: InkWell(
              onTap: widget.enabled ? _openMenu : null,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: Container(
                constraints: const BoxConstraints(minHeight: 22),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: t.hairStrong, width: 1),
                ),
                // `Wrap` 而不是 `Row`：日期 + 时刻两段在 200% 字号下比按钮的
                // 可用宽度还长，`Row` 会直接 `RenderFlex overflowed`，
                // 而折成两行只是变高，不丢字、不报错。
                child: Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '日期 · ${widget.date}',
                      key: const ValueKey<String>('add-plan-date-chip'),
                      style: _bodyStyle(size: 11.5, color: ink, tokens: t),
                    ),
                    Text(
                      timeLabel,
                      key: const ValueKey<String>('add-plan-time-chip'),
                      style: _bodyStyle(size: 11.5, color: ink, tokens: t),
                    ),
                  ],
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
    final t = context.tokens;
    return Padding(
      key: const ValueKey<String>('future-plan-hint'),
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '未来日只可预排：可以先写计划，到了那天才能打卡与回填。',
          style: _bodyStyle(size: 12, color: t.meta, tokens: t),
        ),
      ),
    );
  }
}

/// 「未排期带」与「手写一条」之间的分区线。
///
/// 两块内容语义不同 —— 上面是库里已有、只是没落时刻的事实，下面是新写的入口。
/// 这里只做**视觉**分离：一条 1px `hair` 装饰线。
/// `hair` 只承载纯装饰线（`TOKENS.md` §1.6），不承载任何可交互边界。
class _HandwrittenDivider extends StatelessWidget {
  const _HandwrittenDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('handwritten-divider'),
      height: 1,
      color: context.tokens.hair,
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

  /// 本条新条目的日期；`null` = 跟随当前所选日。
  ///
  /// 允许改日期是为了「今天顺手记下明天的事」这种真实用法：条目落到哪天是
  /// 用户选的，不是页面替它决定的。提交后清空回 `null`（不继承）。
  String? _date;

  /// 本条新条目的开始时刻（当日分钟数，0..1439）；`null` = 不落时刻。
  ///
  /// `null` 的语义很重要：条目会落进下方「未排期带」，而不是被随手塞进某一格。
  /// 结束时刻不由用户填，恒为 `_startMinute + kSlotMinutes`（方格 15 分钟一档）。
  int? _startMinute;

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
      final String id = await ref.read(repositoriesProvider).planItem.create(
            date: _date ?? widget.date,
            title: title,
            quadrant: _quadrant,
          );
      // 时刻分两步落库，原因必须写清：
      // `PlanItemRepository.create()` **没有** `plannedStart` / `plannedEnd`
      // 形参（只有 `createHabitRef` 与 `createScheduled` 才有），而
      // `createScheduled` 把 `quadrant` 硬编码成 null —— 用它会静默丢掉刚选的
      // 优先级。本轮又禁止改 `packages/**`，所以走既有公开写入口
      // `TimelineStore.reschedule()`：与拖拽排期**同一条**路径、同一套账本规矩，
      // 同步侧看到的仍是一条正常记录，不是裸 SQL 写进去的孤儿行。
      final int? start = _startMinute;
      if (start != null) {
        final int raw = start + kSlotMinutes;
        // 夹到 1440：保证 `end > start`，不会撞上仓储层的
        // `plannedEnd < plannedStart` 校验。
        final int end = raw <= 1440 ? raw : 1440;
        await TimelineStore(ref.read(repositoriesProvider)).reschedule(
          planItemId: id,
          startMinute: start,
          endMinute: end,
        );
      }
      _controller.clear();
      if (mounted) {
        setState(() {
          _quadrant = null;
          _date = null;
          _startMinute = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// 选日期：走全站唯一日期组件 [DatePickerSheet]，不自造日历。
  Future<void> _pickDate() async {
    final String? picked = await DatePickerSheet.show(
      context,
      initial: _date ?? widget.date,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _date = picked);
  }

  /// 选开始时刻：Material `showTimePicker`，换算成当日分钟数（0..1439）。
  ///
  /// 不自己画时间选择器 —— 这是一个纯取值动作，系统组件已经把键盘、无障碍、
  /// 24/12 小时制都处理好了。这里只负责把 `TimeOfDay` 换成与时间轴同源的分钟数。
  Future<void> _pickTime() async {
    final int initial = _startMinute ?? 9 * 60;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: '选择开始时刻',
      builder: (BuildContext context, Widget? child) => MediaQuery(
        // 固定 24 小时制：分钟口径与刻度尺（06:00–24:00）同源，不出现 AM/PM。
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    final int minutes = picked.hour * 60 + picked.minute;
    if (minutes < kGridStartHour * 60) {
      // 方格时间轴从 06:00 起。更早的时刻排不进任何一格 —— 静默接受等于
      // 「写进去了但界面上看不见」。这里明说一句，并且**不**写时间，
      // 条目照旧落进未排期带（数据不丢，用户可再排）。
      ref.read(_todayNoticeProvider.notifier).state =
          '方格时间轴从 ${formatMinute(kGridStartHour * 60)} 开始：'
          '更早的时刻排不进格子，这条会落在下方未排期带。';
      return;
    }
    setState(() => _startMinute = minutes);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
                style: _bodyStyle(size: 13, color: t.ink, tokens: t),
                decoration: InputDecoration(
                  hintText: '添加计划条目…',
                  hintStyle: _bodyStyle(size: 13, color: t.faint, tokens: t),
                  isDense: true,
                  filled: true,
                  fillColor: t.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: _fieldBorder(t.hairStrong),
                  enabledBorder: _fieldBorder(t.hairStrong),
                  focusedBorder: _fieldBorder(t.ink, width: 1.5),
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
        // 日期 + 时刻是**一个**按钮，且与重要/紧急芯片**同一行**（Task 40 需求 2）。
        //
        // 原先拆成两枚并排芯片，用户要在两枚之间认「哪一枚改的是日期」，窄屏和
        // 200% 字号下还会先把这一行挤成两条。合并后一行读下来是三个判断：
        // 这条写在哪天几点（左侧一个按钮）、有多重要多紧急（右侧四枚芯片）。
        //
        // 两个 `Flexible` 而不是固定宽度：`PriorityMarkPicker` 内部是 `Wrap`，
        // 空间不够时自己折行，不会把 Row 挤爆（200% 缩放用例守着这条）。
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              child: _DateTimeAction(
                key: const ValueKey<String>('add-plan-datetime-button'),
                date: _date ?? widget.date,
                startMinute: _startMinute,
                enabled: !_submitting,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
                onClearTime: () => setState(() => _startMinute = null),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: PriorityMarkPicker(
                value: _quadrant,
                enabled: !_submitting,
                onChanged: (next) => setState(() => _quadrant = next),
              ),
            ),
          ],
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
    final t = context.tokens;
    return SectionCard(
      icon: icon,
      title: title,
      subtitle: '未来日只做预排',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          detail,
          style: _bodyStyle(size: 12, color: t.meta, tokens: t),
        ),
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
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: _bodyStyle(size: 12.5, color: t.faint, tokens: t),
      ),
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
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SelectableText(
        '$error',
        style: _bodyStyle(size: 12.5, color: t.accentInk, tokens: t),
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
    final t = context.tokens;

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
                              ? t.ink
                              : t.faint,
                          tokens: t,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: _bodyStyle(
                            size: 12.5,
                            color: doneIds.contains(habit.id)
                                ? t.ink
                                : t.meta,
                            tokens: t,
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
    final t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: t.hairStrong),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _bodyStyle(size: 12, color: t.ink, tokens: t),
        ),
      ),
    );
  }
}

/// 右轨「闭环提示」：四个缺口各配一条比例条。
///
/// 四行全部来自 [dayStatsProvider]（唯一口径）。比例 / 缺口判定 / 状态标记
/// 一律取自 `loopSegmentEntries`（与中栏脊线**同一份**算法），本面板只把
/// 标签与数值换成右栏口径 —— 不自己算 `done / total`，也不把分母为 0
/// 当成 100%。
///
/// 刻度（`0 / 25 / 50 / 75 / 100`）只在面板底部画一次（[LoopTickAxis]）：
/// 四行各带一条会得到 4 条逐字重复的坐标轴。
class LoopHintPanel extends ConsumerWidget {
  /// 创建闭环提示面板。
  const LoopHintPanel({super.key});

  /// 四行各自的定位键（顺序即展示顺序）。
  static const List<ValueKey<String>> rowKeys = <ValueKey<String>>[
    ValueKey<String>('loop-hint-plan'),
    ValueKey<String>('loop-hint-backfill'),
    ValueKey<String>('loop-hint-review'),
    ValueKey<String>('loop-hint-mood'),
  ];

  /// 四行共用的那条刻度轴的定位键。
  static const ValueKey<String> axisKey = ValueKey<String>('loop-hint-tick-axis');

  /// 右栏标签（沿用合并前文案，不改措辞）。
  static const List<String> _labels = <String>[
    '计划缺口',
    '回填缺口',
    '复盘',
    '心态',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DayStats stats = ref.watch(dayStatsProvider);
    final entries = loopSegmentEntries(stats);
    final rate = stats.backfillRate;
    final values = <String>[
      '${stats.planPending}',
      rate == null ? '—' : '${stats.planDone - stats.backfilled}',
      stats.reviewDone ? '已写' : '未写',
      stats.moodDone ? '已记' : '未记',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // 四行只留「状态标记 + 标签 + 数值 + 比例条」：刻度收到底部那一条共用轴。
        // 每行各带一条 `0/25/50/75/100` 会得到 4 条逐字重复的坐标轴（20 个刻度
        // 标签），属视觉冗余。
        for (var i = 0; i < entries.length; i++)
          LoopHintBar(
            key: rowKeys[i],
            entry: entries[i],
            label: _labels[i],
            value: values[i],
            showTicks: false,
          ),
        // 整块面板共用的一条刻度轴：只渲染一次，仍覆盖 0—100 全量程。
        const LoopTickAxis(key: axisKey),
        // 停滞提示接在刻度轴下方：同属右轨「闭环提示」，但它是**项目侧**的
        // 温和提醒，没有项目在停滞时整块不渲染（见 `_StallHints`）。
        const _StallHints(),
      ],
    );
  }
}

/// 停滞项目（连续 ≥3 天没有增量的 active 项目）。
///
/// 口径在 [ProjectStore.stalledProjects] 里，这里只做取数与失效。
final FutureProvider<List<ProjectStall>> _stalledProjectsProvider =
    FutureProvider.autoDispose<List<ProjectStall>>((ref) {
      final String todayIso = ref.watch(todayProvider);
      final repos = ref.watch(repositoriesProvider);
      return ProjectStore(repos).stalledProjects(todayIso: todayIso);
    });

/// 今日已关闭的停滞提示，键 = `projectId|today`。
///
/// **只存进程内存**：`StateProvider` 的初值就是空集，不写库、不落盘 ⇒ 重启后
/// 会重新提示。这是刻意的 —— 抑制只该管「今天别烦我」，不该变成永久静音。
final StateProvider<Set<String>> _stallDismissedProvider =
    StateProvider<Set<String>>((ref) => const <String>{});

/// 右轨停滞提示（`LoopHintPanel` 尾部那一小段）。
///
/// 措辞走「想起它的时候再推一步」——温和提示，不是催办；关闭按**日期粒度**
/// 抑制（`projectId|today`），第二天自动重新出现。
class _StallHints extends ConsumerWidget {
  const _StallHints();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ProjectStall> rows =
        ref.watch(_stalledProjectsProvider).asData?.value ??
        const <ProjectStall>[];
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final String todayIso = ref.watch(todayProvider);
    final Set<String> dismissed = ref.watch(_stallDismissedProvider);
    final List<ProjectStall> visible = rows
        .where(
          (ProjectStall stall) =>
              !dismissed.contains('${stall.projectId}|$todayIso'),
        )
        .toList(growable: false);
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 10),
        for (final ProjectStall stall in visible)
          Padding(
            key: ValueKey<String>('loop-hint-stall-${stall.projectId}'),
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '「${stall.name}」${stall.daysSinceIncrement} 天没有增量了，'
                  '想起它的时候再推一步。',
                  style: _bodyStyle(
                    size: 11.5,
                    color: tokens.meta,
                    tokens: tokens,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: ValueKey<String>(
                      'loop-hint-stall-dismiss-${stall.projectId}',
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      ref.read(_stallDismissedProvider.notifier).state =
                          <String>{...dismissed, '${stall.projectId}|$todayIso'};
                    },
                    child: Text(
                      '今天不再提',
                      style: _bodyStyle(
                        size: 11,
                        color: tokens.faint,
                        tokens: tokens,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
    final t = context.tokens;
    return Text(
      text,
      style: _bodyStyle(
        size: 12.5,
        color: danger ? t.accentInk : t.faint,
        tokens: t,
      ),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
///
/// [tokens] 必填：正文默认色 `ink` 从「静态常量」改为「按当前主题解析」。
/// 不给默认值 —— 留一个可以回落到浅色的口子，深色档就会重新长出浅色字。
TextStyle _bodyStyle({
  double size = 12.5,
  Color? color,
  TextDecoration? decoration,
  required ThemeTokens tokens,
}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color ?? tokens.ink,
    height: 1.45,
    decoration: decoration,
  );
}

/// 数字/键帽字体样式（`AppFonts.mono` + `tabular-nums`）。
///
/// [tokens] 必填，理由同 [_bodyStyle]。
TextStyle _monoStyle({
  double size = 11.5,
  Color? color,
  required ThemeTokens tokens,
}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color ?? tokens.faint,
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
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.accent, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 200% 缩放下文案会变长：用 `Expanded` 换行，不把「知道了」挤出去。
          Expanded(
            child: Text(
              message,
              style: _bodyStyle(size: 12.5, color: t.accentInk, tokens: t),
            ),
          ),
          const SizedBox(width: 8),
          _GhostAction(label: '知道了', dense: true, onPressed: onDismiss),
        ],
      ),
    );
  }
}
