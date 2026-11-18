import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        setState(() => _actionError = '规则操作失败：$error');
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
    try {
      confirmed = await showConfirmDialog(
        context,
        title: '删除循环任务',
        message: '「${rule.title}」将从循环任务列表中移除，之后不再自动排入计划；'
            '已经排入计划的条目会保留。',
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
    // 只取错误文本用于展示，**不**用 `whenOrNull` 把整段数据兜成空列表。
    final String? materializeError = materialize.whenOrNull(
      error: (Object error, StackTrace _) => '自动排程失败：$error',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(text: '规则'),
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
    return rules.when(
      loading: () => <Widget>[_hint('读取规则…')],
      error: (Object error, StackTrace _) => <Widget>[
        _RailError(text: '规则读取失败：$error'),
      ],
      data: (List<RecurringTaskData> rows) {
        if (rows.isEmpty) {
          return <Widget>[
            _hint('还没有循环规则'),
            _hint('点右上角 ＋ 添加一条', size: 11),
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
            '共 ${rows.length} 条规则 · 命中日自动排入计划',
            size: 11,
            key: const ValueKey<String>('recurring-rules-count'),
          ),
        ];
      },
    );
  }

  /// 一段灰色说明文字（空态提示、计数行）。
  Widget _hint(String text, {double size = 11.5, Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: _bodyStyle(size: size, color: AppTokens.faint)),
    );
  }
}

/// 段落小标题（`规则`）。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: _bodyStyle(
          size: 10.5,
          color: AppTokens.meta,
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
    final bool active = rule.active == 1;
    // 空掩码在库层被 CHECK 与仓储挡住，这里再兜一次：显示「每日」而不是「未选」。
    final String weekdayText = rule.weekdayMask == WeekdayMask.none
        ? '每日'
        : WeekdayMask.label(rule.weekdayMask);
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
                  style: _monoStyle(size: 11.5, color: AppTokens.ink2),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$weekdayText · ${rule.durationMinutes} 分钟 · '
                  '${active ? '启用中' : '已停用'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(size: 11, color: AppTokens.faint),
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
                    size: 12.5,
                    color: active ? AppTokens.ink : AppTokens.meta,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RuleAction(
                key: ValueKey<String>('recurring-rule-active-${rule.id}'),
                label: active ? '停用' : '启用',
                onTap: busy ? null : onToggleActive,
              ),
              const SizedBox(width: 4),
              _RuleAction(
                key: ValueKey<String>('recurring-rule-delete-${rule.id}'),
                label: '删除',
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
    final bool enabled = onTap != null;
    final Color foreground;
    if (!enabled) {
      foreground = AppTokens.faint;
    } else if (danger) {
      foreground = AppTokens.accentInk;
    } else {
      foreground = AppTokens.ink2;
    }
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppTokens.hairStrong, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: _bodyStyle(size: 11, color: foreground),
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
    return Text(
      text,
      style: _bodyStyle(size: 11.5, color: AppTokens.accentInk),
    );
  }
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({
  double size = 12.5,
  Color color = AppTokens.ink,
  FontWeight? weight,
}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    fontWeight: weight,
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