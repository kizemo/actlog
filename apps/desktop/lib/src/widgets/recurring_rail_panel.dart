import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_scope.dart';
// `weekdayNameOf` 是 `DomainL10n` 上的扩展 ⇒ 必须把声明它的库 import 进来。
import '../l10n/parts/domain.dart';
import '../providers.dart';
import '../providers_recurring.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'confirm_dialog.dart';

/// 右轨「循环任务」面板：**只列规则**（需求 8 去掉了原「今日」实例段）。
///
/// 两件事的先后顺序有意义：
/// 1. `watch(recurringMaterializeProvider)` —— **进入即物化**（幂等），
///    保证今天该跑的规则已经落成 `plan_item`，时间轴与计划列表立刻能看到；
/// 2. `watch(recurringRulesProvider)` —— 列出规则**本身**，与今天命中与否无关
///    （这是「确认后不出现在列表里」的修复点：早先面板只读 `recurring_occurrence`，
///    而 occurrence 要掩码命中才产生，于是新建规则当天看不见任何东西）。
///
/// 「今日已自动排入什么」这一段**不再展示**：物化结果本来就落在计划列表与
/// 时间轴上，面板再列一遍只会让「循环任务」看着像重复条目（需求 8）。
/// 规则可以停用/启用与删除（软删，先弹确认）；勾选/回填仍只在计划列表与
/// 时间轴上做。
class RecurringRailPanel extends ConsumerStatefulWidget {
  /// 创建循环任务面板。
  const RecurringRailPanel({super.key});

  @override
  ConsumerState<RecurringRailPanel> createState() => _RecurringRailPanelState();
}

class _RecurringRailPanelState extends ConsumerState<RecurringRailPanel> {
  /// 规则动作（停用/启用/删除）失败的原文；动作成功即清空。
  String? _actionError;

  /// 动作进行中：禁用动作按钮，避免连点写出两次。
  bool _busy = false;

  /// 确认弹窗已经打开：防止连点 `删除` 叠出两个 `AlertDialog`。
  bool _confirming = false;

  /// 执行一个规则动作，并在成功后失效相关 provider。
  ///
  /// 失效是双保险：两个 provider 走 drift 流，本来就会自动重发；但派工书
  /// 明确要求「创建/停用/删除后对应 provider 必须失效」，这里逐条落实。
  Future<void> _runRuleAction(
    Future<void> Function(RecurringTaskRepository repo) action,
  ) async {
    if (_busy) {
      return;
    }
    // `await` 之后不能再取 `context`（`mounted` 之外），故先把文案表读出来。
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action(ref.read(repositoriesProvider).recurring);
      ref.invalidate(recurringRulesProvider);
      ref.invalidate(recurringMaterializeProvider);
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = l10n.dialogRuleActionFailed('$error'));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// 停用 / 启用一条规则。
  ///
  /// 重新启用时顺带补物化「当前选中日」：该星期命中就立刻回到今天的计划里
  /// （`materializeDate` 幂等，重复调用不会多出条目）。停用不撤除已排的条目 ——
  /// 口径见 `RecurringTaskRepository.setActive` 的文档注释。
  Future<void> _toggleActive(RecurringTaskData rule) {
    final bool next = rule.active != 1;
    return _runRuleAction((RecurringTaskRepository repo) async {
      await repo.setActive(rule.id, next);
      if (next) {
        await repo.materializeDate(ref.read(selectedDateProvider));
      }
    });
  }

  /// 删除（软删/归档）一条规则：**先弹确认**（需求 9），确认后才落库。
  ///
  /// 取消 / 点遮罩 / 按 Esc 一律视为取消（`showConfirmDialog` 返回 `false`），
  /// 库里一个字节都不写。归档只给规则打墓碑：已经排入计划的条目保留，
  /// 之后不再物化新实例 —— 文案必须说清这一点，否则用户会以为「删除」
  /// 会把今天已有的时段一起清掉。
  Future<void> _archive(RecurringTaskData rule) async {
    if (_busy || _confirming) {
      return;
    }
    _confirming = true;
    bool confirmed = false;
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      confirmed = await showConfirmDialog(
        context,
        title: l10n.dialogRecurringDeleteTitle,
        message: l10n.dialogRecurringDeleteMessage(rule.title),
      );
    } finally {
      _confirming = false;
    }
    if (!confirmed || !mounted) {
      return;
    }
    await _runRuleAction(
      (RecurringTaskRepository repo) => repo.archive(rule.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<int> materialize = ref.watch(recurringMaterializeProvider);
    final AsyncValue<List<RecurringTaskData>> rules =
        ref.watch(recurringRulesProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    // 只取错误文本用于展示，**不**用 `whenOrNull` 把整段数据兜成空列表。
    final String? materializeError = materialize.whenOrNull(
      error: (Object error, StackTrace _) =>
          l10n.dialogAutoScheduleFailed('$error'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SectionTitle(text: l10n.dialogRecurringSection),
        ..._buildRules(rules),
        if (_actionError != null) ...<Widget>[
          const SizedBox(height: 2),
          _RailError(text: _actionError!),
        ],
        // 物化失败照样要看得见：面板不再列「今日」条目，但「今天该排的没排上」
        // 仍然是用户必须知道的事，所以错误挂在规则区下方。
        if (materializeError != null) ...<Widget>[
          const SizedBox(height: 2),
          _RailError(text: materializeError),
        ],
      ],
    );
  }

  /// 规则段：三态渲染（读取中 / 错误原文 / 列表）。
  List<Widget> _buildRules(AsyncValue<List<RecurringTaskData>> rules) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return rules.when(
      loading: () => <Widget>[_hint(l10n.dialogRecurringLoading)],
      error: (Object error, StackTrace _) => <Widget>[
        _RailError(text: l10n.dialogRecurringLoadFailed('$error')),
      ],
      data: (List<RecurringTaskData> rows) {
        if (rows.isEmpty) {
          return <Widget>[
            _hint(l10n.dialogRecurringNone),
            _hint(l10n.dialogRecurringNoneHint, size: 11),
          ];
        }
        return <Widget>[
          for (final rule in rows)
            _RuleRow(
              key: ValueKey<String>('recurring-rule-${rule.id}'),
              rule: rule,
              busy: _busy,
              onToggleActive: () => _toggleActive(rule),
              onArchive: () => _archive(rule),
            ),
          // 计数只反映**规则数**：旧文案「共 N 条 · 已自动排入计划」说的是
          // 今日实例，随「今日」段移除一并失效（需求 8）。
          _hint(
            l10n.dialogRecurringCount(rows.length),
            size: 11,
            key: const ValueKey<String>('recurring-rules-count'),
          ),
        ];
      },
    );
  }

  /// 一段灰色说明文字（空态提示、计数行）。
  Widget _hint(String text, {double size = 11.5, Key? key}) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: _bodyStyle(tokens, size: size, color: tokens.faint)),
    );
  }
}

/// 段落小标题（`规则`）。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: _bodyStyle(
          tokens,
          size: 10.5,
          color: tokens.meta,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 一条规则：时段 + 星期 / 时长 / 启用状态 + 标题 + 两个动作。
class _RuleRow extends StatelessWidget {
  const _RuleRow({
    super.key,
    required this.rule,
    required this.busy,
    required this.onToggleActive,
    required this.onArchive,
  });

  final RecurringTaskData rule;
  final bool busy;
  final VoidCallback onToggleActive;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool active = rule.active == 1;
    // Task 68 W9：星期文案全部走 l10n（域层 `WeekdayMask.label` 已移除）。
    // 空掩码在库层被 CHECK 与仓储挡住，这里再兜一次：显示「每日」而不是「未选」。
    final String weekdayText = switch (rule.weekdayMask) {
      WeekdayMask.none => l10n.dialogRecurringDaily,
      WeekdayMask.all => l10n.every,
      WeekdayMask.workdays => l10n.workdays,
      WeekdayMask.weekend => l10n.weekend,
      final int mask => L10nFormat(l10n.language).joinList(
        WeekdayMask.weekdaysOf(mask).map(l10n.weekdayNameOf),
      ),
    };
    // 脏数据防御：`formatMinuteOfDay` 对越界值抛异常，别让一行坏数据把整块
    // 面板渲染搞挂（与 `materializeDate` 的脏数据防御同口径）。
    final String timeText =
        rule.startMinute >= 0 && rule.startMinute < minutesPerDay
            ? formatMinuteOfDay(rule.startMinute)
            : '--:--';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 84,
                child: Text(
                  timeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _monoStyle(tokens, size: 11.5, color: tokens.ink2),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.dialogRecurringSummary(
                    weekdayText,
                    rule.durationMinutes,
                    active ? l10n.dialogRuleActiveOn : l10n.dialogRuleActiveOff,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(tokens, size: 11, color: tokens.faint),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  rule.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(
                    tokens,
                    size: 12.5,
                    color: active ? tokens.ink : tokens.meta,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RuleAction(
                key: ValueKey<String>('recurring-rule-active-${rule.id}'),
                label: active ? l10n.dialogRuleDisable : l10n.dialogRuleEnable,
                onTap: busy ? null : onToggleActive,
              ),
              const SizedBox(width: 4),
              _RuleAction(
                key: ValueKey<String>('recurring-rule-delete-${rule.id}'),
                label: l10n.commonDelete,
                danger: true,
                onTap: busy ? null : onArchive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 规则行上的迷你动作按钮（`card` 底 + `hair-strong` 边）。
class _RuleAction extends StatelessWidget {
  const _RuleAction({
    super.key,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    final bool enabled = onTap != null;
    final Color foreground;
    if (!enabled) {
      foreground = tokens.faint;
    } else if (danger) {
      foreground = tokens.accentInk;
    } else {
      foreground = tokens.ink2;
    }
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: tokens.hairStrong, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: _bodyStyle(tokens, size: 11, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// 错误原文（`accentInk`，与 `today_page` 的 `_RailNote(danger: true)` 同色）。
class _RailError extends StatelessWidget {
  const _RailError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Text(
      text,
      style: _bodyStyle(tokens, size: 11.5, color: tokens.accentInk),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
///
/// [tokens] 必填：默认色是 `ink`，必须由调用方按当前主题解析后传入
/// （纯函数拿不到 `BuildContext`，写死浅色常量会在深色档留下浅色字）。
TextStyle _bodyStyle(
  ThemeTokens tokens, {
  double size = 12.5,
  Color? color,
  FontWeight? weight,
}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    fontWeight: weight,
    color: color ?? tokens.ink,
    height: 1.45,
  );
}

/// 等宽字体样式（时段、数字用）。
TextStyle _monoStyle(ThemeTokens tokens, {double size = 12, Color? color}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color ?? tokens.ink,
    height: 1.45,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}