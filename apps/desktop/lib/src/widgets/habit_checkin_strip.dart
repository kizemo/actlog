// apps/desktop/lib/src/widgets/habit_checkin_strip.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';

import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 习惯打卡条（原型 `.dock`）。
///
/// 结构：由 `LedgerShell` 的 `dock` 槽位渲染成**壳层独立布局行** —— 位于
/// 正文滚动区之外、快捷键条之上。因为是列里的兄弟行，结构上不可能遮挡正文，
/// 所以这里**不用** `Stack` / `Positioned` / 右下浮动小卡（原型注释
/// `v2-ledger.html:272` 的原话是「独立布局行 ⇒ 结构上不可能遮挡主列表」）。
///
/// 语义：所选日早于或等于今天才渲染；未来日只做预排，整条不渲染
/// （spec §H-1）。这个判定故意留在本文件内 —— 打卡相关的 provider 读取
/// 不搬到壳层或页面里。
///
/// [未覆盖] 原因：原型 `.dock` 还带三块当前没有数据来源的交互 ——
/// 「漏打填理由」单选面板（`v2-ledger.html:290` / `1026`）、周习惯子项
/// 面板（`v2-ledger.html:1024`）、「现在收工」收起态（`1007`）。
/// 它们依赖尚未建模的 `reason` / `weekSubs` / `closed` 状态，本单元既
/// 没有对应 provider 也不在写集内；宁可不渲染，也不做点不动的假交互。
class HabitCheckinStrip extends ConsumerWidget {
  /// 创建打卡条。
  const HabitCheckinStrip({super.key, this.onChecked});

  /// 打卡成功后的回调（便于 Undo 接线）。
  final void Function(String habitName)? onChecked;

  /// 所选日没有待打卡习惯时的占位文案。
  static const String emptyLabel = '今天没有待打卡的习惯';

  /// 习惯清单或打卡流尚未就绪时的提示文案。
  static const String loadingLabel = '正在加载打卡状态…';

  /// 任一异步数据加载失败时的提示文案。
  static const String errorLabel = '打卡状态加载失败，请稍后重试';

  /// 条头第一段（原型 `.dock-h` 第一段文案）。
  static const String headTitle = '习惯打卡 · 吸底不滚动';

  /// 条头第三段（原型 `.dock-h` 第三段文案）。
  static const String headHint = '· 一点即打，跳过需理由';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 两个 provider 都返回 AsyncValue：加载 / 空 / 错误是三种不同状态，
    // 不允许把加载态和错误态都渲染成空态（那是谎报）。
    final habitsAsync = ref.watch(habitsForTodayProvider);
    final checkinsAsync = ref.watch(habitCheckinsProvider);
    final date = ref.watch(selectedDateProvider);

    // 未来日只可预排：打卡在当天才开放（spec §H-1）。
    if (date.compareTo(ref.watch(todayProvider)) > 0) {
      return const SizedBox.shrink();
    }

    if (habitsAsync.hasError || checkinsAsync.hasError) {
      return _dock(context, head: <Widget>[_statusText(context, errorLabel)]);
    }
    if (!habitsAsync.hasValue || !checkinsAsync.hasValue) {
      return _dock(context, head: <Widget>[_statusText(context, loadingLabel)]);
    }

    final habits = habitsAsync.value!;
    if (habits.isEmpty) {
      return _dock(context, head: <Widget>[_statusText(context, emptyLabel)]);
    }

    final doneIds = <String>{
      for (final checkin in checkinsAsync.value!)
        if (checkin.status == CheckinStatus.done.code) checkin.habitId,
    };
    final doneCount = doneIds.length;

    return _dock(
      context,
      head: <Widget>[
        Text(headTitle, style: _headStyle(context)),
        Text(
          '$doneCount/${habits.length}',
          style: _headStyle(context).copyWith(
            fontFamily: AppFonts.mono,
            fontFamilyFallback: AppFonts.monoFallback,
            fontWeight: FontWeight.w500,
            color: AppTokens.ink,
            // 等宽数字自带步进，再叠 1px 字距只会把 `3/12` 拉散。
            letterSpacing: 0,
          ),
        ),
        Text(headHint, style: _headStyle(context)),
      ],
      chips: <Widget>[
        for (final habit in habits)
          _HabitChip(
            habit: habit,
            done: doneIds.contains(habit.id),
            onTap: () async {
              final repo = ref.read(repositoriesProvider).habit;
              if (doneIds.contains(habit.id)) {
                final existing = await repo.findCheckin(habit.id, date);
                if (existing != null) {
                  await repo.deleteCheckin(existing.id);
                }
                return;
              }
              await repo.upsertCheckin(
                habitId: habit.id,
                date: date,
                status: CheckinStatus.done,
              );
              onChecked?.call(habit.name);
            },
          ),
      ],
    );
  }

  /// `.dock` 容器：全宽、只有上边一条 `--hair` 细线，无外边距 / 无圆角。
  ///
  /// 原型 `v2-ledger.html:274`：`border-top:1px solid var(--hair)`、
  /// `background:var(--dock)`、`padding:9px 24px 11px`、`min-height:48px`。
  Widget _dock(
    BuildContext context, {
    required List<Widget> head,
    List<Widget> chips = const <Widget>[],
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(24, 9, 24, 11),
      decoration: const BoxDecoration(
        color: AppTokens.dock,
        border: Border(top: BorderSide(color: AppTokens.hair, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // `.dock-h`：基线对齐、gap 10、可换行（窄屏 / 大字号下掉行，
          // 而不是把三段时间挤成一条）。
          Wrap(
            spacing: 10,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: head,
          ),
          if (chips.isNotEmpty) ...<Widget>[
            // `.dock-row{margin-top:8px; gap:8px}`：窄屏折行，不横向滚动。
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }

  /// `.dock-h` 的文字样式：`--fs-label` + `--faint` + `letter-spacing:.08em`。
  TextStyle _headStyle(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelSmall ?? const TextStyle();
    final fontSize = base.fontSize ?? 12.5;
    return base.copyWith(
      color: AppTokens.faint,
      // `.08em` 换算成像素：Flutter 的 letterSpacing 是绝对像素，不随字号缩放。
      letterSpacing: fontSize * 0.08,
    );
  }

  /// 三态占位文案（加载 / 空 / 失败）走同一套条头样式。
  Widget _statusText(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
        color: AppTokens.meta,
      ),
    );
  }
}

/// `.hchip`：一个习惯一颗芯片，一点即打 / 再点撤销。
///
/// 原型 `v2-ledger.html:278-285`：`padding:5px 10px`、`min-height:30px`、
/// `gap:7px`、`border:1px var(--hair)`、`background:var(--card)`；
/// 已打卡态只换边色与底色（`--ink` / `--ink-wash`），文字仍是 `--ink`。
class _HabitChip extends StatefulWidget {
  const _HabitChip({
    required this.habit,
    required this.done,
    required this.onTap,
  });

  final HabitData habit;
  final bool done;
  final VoidCallback onTap;

  @override
  State<_HabitChip> createState() => _HabitChipState();
}

class _HabitChipState extends State<_HabitChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    // `.hchip` 的 `font-size:14px` 取全应用正文基准（舒适档 15），
    // 不写死像素 —— 否则换密度档后芯片与正文脱节。
    final fontSize = base.fontSize ?? 14;
    // `.hchip .mk{font-family:var(--f-mono); width:1.1em}`：给标记留固定
    // 1.1 字宽的槽，让 ✓ 与 ○ 的芯片左边缘完全对齐。
    final markSlot = fontSize * 1.1;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.done ? AppTokens.inkWash : AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: widget.done
                    ? AppTokens.ink
                    : (_hovered ? AppTokens.hairStrong : AppTokens.hair),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: markSlot,
                  child: Text(
                    widget.done ? '✓' : '○',
                    textAlign: TextAlign.center,
                    style: base.copyWith(
                      fontFamily: AppFonts.mono,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: fontSize,
                      height: 1.2,
                      color: AppTokens.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.habit.name,
                  style: base.copyWith(
                    fontSize: fontSize,
                    height: 1.2,
                    color: AppTokens.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}