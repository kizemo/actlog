import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/chip_row.dart';
import '../widgets/date_bar.dart';
import '../widgets/est_duration_text.dart';
import '../widgets/timeline/slot_state.dart';
import '../widgets/timeline/timeline_store.dart';

/// 待办池：把「还没排到某一天」的事捞进当前选中日。
///
/// 这是 B1 遗留 #3 的闭环入口 —— 在此之前的待办池只是一个没有 UI 的数据表，
/// 用户没有任何办法把池子里的条目变成今日计划。
///
/// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担。
///
/// 五列口径（brief §1 修订 G）：标题 / 优先级 / 预估 / 象限 / 到期 + 动作。
/// 「领域」列**不存在** —— `todo` 表与 `Todo` 实体都没有 `domain` 字段，
/// 为了凑六列编一个假列，等于在界面上说谎。
class TodoPoolPage extends ConsumerStatefulWidget {
  /// 创建待办池页。
  const TodoPoolPage({super.key});

  @override
  ConsumerState<TodoPoolPage> createState() => _TodoPoolPageState();
}

class _TodoPoolPageState extends ConsumerState<TodoPoolPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _est = TextEditingController();
  final TextEditingController _due = TextEditingController();

  /// 可选起始时间（`HH:mm`，留空 = 不排期；15 分钟吸附）。
  final TextEditingController _start = TextEditingController();

  /// 新建表单的优先级 / 象限选择（`Set` 是 [ChipRow] 的接口形态）。
  Set<String> _priority = <String>{};
  Set<String> _quadrant = <String>{};

  /// 新建表单的预估单位（数量 × 单位 ⇒ 分钟；默认「分钟」）。
  EstUnit _estUnit = EstUnit.minute;

  /// 新建请求进行中。
  bool _creating = false;

  /// 正在捞取的待办 id（只禁用那一行的按钮，不冻整页）。
  String? _pullingId;

  /// 正在加入主页计划的待办 id（只禁用那一行的按钮，不冻整页）。
  String? _planningId;

  /// 行内错误横幅文案；`null` 表示无错误。
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _est.dispose();
    _due.dispose();
    _start.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final pool = ref.watch(todoPoolProvider);
    final target = ref.watch(todoPullTargetDateProvider);
    // 「已填时间」是派生事实：加载中 / 出错就当没有徽标，绝不编造。
    final slotted =
        ref.watch(slottedTodosProvider).asData?.value ??
            const <String, SlottedTodo>{};
    final countLabel = pool.maybeWhen(
      data: (rows) => l10n.dialogPoolAvailable(rows.length),
      orElse: () => l10n.dialogPoolLoading,
    );
    final error = _error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const DateBar(),
        const SizedBox(height: AppTokens.gapCard),
        _PoolHead(subtitle: l10n.dialogPoolHead(countLabel, target)),
        const SizedBox(height: AppTokens.gapCard),
        _buildCreateForm(),
        if (error != null) ...<Widget>[
          const SizedBox(height: 10),
          _ErrorBanner(
            key: const ValueKey<String>('todo-pool-error'),
            message: error,
          ),
        ],
        const SizedBox(height: AppTokens.gapCard),
        pool.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stack) => _ErrorBanner(message: '$error'),
          data: (rows) => rows.isEmpty
              ? const _EmptyState(key: ValueKey<String>('todo-pool-empty'))
              : _buildTable(rows, slotted),
        ),
      ],
    );
  }

  /// 新建待办表单。
  ///
  /// 外层用 [Wrap] 而不是 `Row`：元信息一行的总宽会随字号缩放（裁定 B 的 200%）
  /// 变化，`Row` 会直接溢出，`Wrap` 只会换行。
  Widget _buildCreateForm() {
    final t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.hairSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('todo-new-title'),
            controller: _title,
            textInputAction: TextInputAction.done,
            style: _bodyStyle(tokens: t, size: 13, color: t.ink),
            onSubmitted: (_) => _submit(),
            decoration: _fieldDecoration(
              tokens: t,
              hint: l10n.dialogPoolTitleHint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 96,
                child: TextField(
                  key: const ValueKey<String>('todo-new-est'),
                  controller: _est,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: _bodyStyle(tokens: t, size: 13, color: t.ink),
                  decoration: _fieldDecoration(
                    tokens: t,
                    hint: l10n.dialogTodoEstHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 单位选择器与手写面板共用同一个 widget ⇒ 口径只有一份实现。
              Expanded(
                child: EstUnitPicker(
                  keyPrefix: 'todo-pool',
                  t: l10n,
                  selected: _estUnit,
                  enabled: !_creating,
                  onChanged: (EstUnit unit) => setState(() => _estUnit = unit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 108,
                child: TextField(
                  key: const ValueKey<String>('todo-new-start'),
                  controller: _start,
                  style: _bodyStyle(tokens: t, size: 13, color: t.ink),
                  decoration: _fieldDecoration(
                    tokens: t,
                    hint: l10n.dialogPoolStartHint,
                  ),
                ),
              ),
              SizedBox(
                width: 148,
                child: TextField(
                  key: const ValueKey<String>('todo-new-due'),
                  controller: _due,
                  style: _bodyStyle(tokens: t, size: 13, color: t.ink),
                  decoration: _fieldDecoration(
                    tokens: t,
                    hint: l10n.dialogPoolDueHint,
                  ),
                ),
              ),
              ChipRow(
                options: const <ChipOption>[
                  ChipOption(key: 'A', label: 'A'),
                  ChipOption(key: 'B', label: 'B'),
                  ChipOption(key: 'C', label: 'C'),
                ],
                selected: _priority,
                onChanged: (next) => setState(() => _priority = next),
              ),
              ChipRow(
                options: const <ChipOption>[
                  ChipOption(key: 'Q1', label: 'Q1'),
                  ChipOption(key: 'Q2', label: 'Q2'),
                  ChipOption(key: 'Q3', label: 'Q3'),
                  ChipOption(key: 'Q4', label: 'Q4'),
                ],
                selected: _quadrant,
                onChanged: (next) => setState(() => _quadrant = next),
              ),
              _PoolButton(
                key: const ValueKey<String>('todo-new-submit'),
                label: l10n.dialogPoolNew,
                primary: true,
                onPressed: _creating ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 待办表格（表头 + 行）。列宽固定，标题列吃掉剩余宽度。
  Widget _buildTable(List<Todo> rows, Map<String, SlottedTodo> slotted) {
    final t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.hairSoft, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.hair)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: _headCell(l10n.commonTitle)),
                _fixed(_wPriority, _headCell(l10n.dialogPoolColPriority)),
                _fixed(_wEst, _headCell(l10n.dialogPoolColEst)),
                _fixed(_wQuadrant, _headCell(l10n.dialogPoolColQuadrant)),
                _fixed(_wDue, _headCell(l10n.dialogPoolColDue)),
                _fixed(_wAction, _headCell(l10n.dialogPoolColAction)),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            _TodoRow(
              key: ValueKey<String>('todo-row-${rows[i].id}'),
              todo: rows[i],
              // 只读徽标，放在标题单元格内 ⇒ 表头仍是严格五列。
              slottedLabel: slotted[rows[i].id] == null
                  ? null
                  : l10n.dialogPoolScheduled(
                      formatMinute(slotted[rows[i].id]!.startMinute),
                    ),
              last: i == rows.length - 1,
              pulling: _pullingId == rows[i].id,
              planning: _planningId == rows[i].id,
              onPull: () => _pull(rows[i]),
              onPlan: () => _planToMain(rows[i]),
            ),
        ],
      ),
    );
  }

  Widget _headCell(String label) {
    final t = context.tokens;
    return Text(label, style: _bodyStyle(tokens: t, size: 11.5, color: t.meta));
  }

  Widget _fixed(double width, Widget child) {
    return SizedBox(width: width, child: Align(alignment: Alignment.centerLeft, child: child));
  }

  /// 新建一条待办。
  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.dialogTodoTitleRequired);
      return;
    }

    // 数量 × 单位 ⇒ 分钟；留空 ⇒ 不写库（NULL）。口径与手写面板同一份实现。
    final estText = _est.text.trim();
    int? estMinutes;
    if (estText.isNotEmpty) {
      final amount = double.tryParse(estText);
      if (amount == null || amount <= 0) {
        setState(() => _error = l10n.dialogTodoEstInvalid);
        return;
      }
      // 四舍五入到 0 视为未填（例如 0.001 分钟），存 NULL。
      estMinutes = estMinutesOf(amount, _estUnit);
    }

    final dueText = _due.text.trim();
    final dueDate = dueText.isEmpty ? null : dueText;

    // 起始时间留空 ⇒ 只建待办（现状不变）；填了 ⇒ 待办 + 当天计划同事务落库。
    final String startText = _start.text.trim();
    int? startMinute;
    if (startText.isNotEmpty) {
      final int? parsed = _parseMinute(startText);
      if (parsed == null) {
        setState(() => _error = l10n.dialogPoolStartInvalid);
        return;
      }
      // 15 分钟吸附：`planned_start` 永远落在格线上。
      startMinute = alignMinuteDown(parsed);
    }
    final String? quadrant = _quadrant.isEmpty ? null : _quadrant.first;
    final String? priorityAbc = _priority.isEmpty ? null : _priority.first;

    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final repos = ref.read(repositoriesProvider);
      final int? start = startMinute;
      if (start == null) {
        await repos.todo.create(
          title: title,
          estMinutes: estMinutes,
          dueDate: dueDate,
          quadrant: quadrant,
          priorityAbc: priorityAbc,
        );
      } else {
        // 排期落在**今天**：待办池的「当天」口径与今日页一致。
        final int rawEnd = start + (estMinutes ?? kSlotMinutes);
        await TimelineStore(repos).createTodoWithSlot(
          date: ref.read(todayProvider),
          title: title,
          startMinute: start,
          endMinute: alignMinuteUp(rawEnd),
          estMinutes: estMinutes,
          dueDate: dueDate,
          quadrant: quadrant,
          priorityAbc: priorityAbc,
        );
      }
      _title.clear();
      _est.clear();
      _due.clear();
      _start.clear();
      _priority = <String>{};
      _quadrant = <String>{};
      _estUnit = EstUnit.minute;
      ref.invalidate(todoPoolProvider);
      ref.invalidate(slottedTodosProvider);
    } on ArgumentError catch (error) {
      // 仓储层对空标题 / 非法日历日抛 ArgumentError；原文直接给用户看。
      setState(() => _error = '${error.message}');
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  /// 把一条待办捞进当前选中日。
  Future<void> _pull(Todo todo) async {
    final date = ref.read(todoPullTargetDateProvider);
    setState(() {
      _pullingId = todo.id;
      _error = null;
    });
    try {
      await ref.read(repositoriesProvider).todo.pullToPlan(todo.id, date);
      // 池子是 FutureProvider ⇒ 必须显式失效；今日计划是 Stream ⇒ 自动 +1。
      ref.invalidate(todoPoolProvider);
    } on StateError catch (error) {
      // 非 open / 已被删 / 不存在：仓储层抛 StateError，`message` 就是原因。
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _pullingId = null);
      }
    }
  }

  /// 把一条待办加入主页计划（Task 56 诉求 2 的终点）。
  ///
  /// 日期口径：待办自己的到期日（`due_date`）；没有到期日就进今天。
  /// 只走 `pullToPlan`（建 `plan_item` + 写 `source_todo_id`）—— **不置 done**，
  /// 待办本体仍留在池子里（待办池只查 `status='open'`）。
  Future<void> _planToMain(Todo todo) async {
    final String date = todo.dueDate ?? ref.read(todayProvider);
    setState(() {
      _planningId = todo.id;
      _error = null;
    });
    try {
      await ref.read(repositoriesProvider).todo.pullToPlan(todo.id, date);
      ref.invalidate(todoPoolProvider);
      ref.invalidate(slottedTodosProvider);
    } on StateError catch (error) {
      // 同一天已经捞过 ⇒ 仓储层抛 StateError，`message` 就是原因。
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _planningId = null);
      }
    }
  }
}

/// 列宽（与表头、行共用同一组常量）。
const double _wPriority = 72;
const double _wEst = 72;
const double _wQuadrant = 64;
const double _wDue = 96;
/// 动作列宽：装得下「捞入」+「加入主页计划」两个按钮（Task 56）。
const double _wAction = 132;

/// `H:mm` / `HH:mm` → 当日分钟数（0–1439）。格式非法或越界返回 `null`。
int? _parseMinute(String text) {
  final RegExpMatch? match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  if (minute > 59) {
    return null;
  }
  final int total = hour * 60 + minute;
  return total >= 24 * 60 ? null : total;
}

/// 页头：标题 + 副标（条数 · 捞入日期）。
class _PoolHead extends StatelessWidget {
  const _PoolHead({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.dialogPoolTitle,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontFamilyFallback: AppFonts.displayFallback,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: t.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: _monoStyle(tokens: t, size: 11.5, color: t.faint)),
      ],
    );
  }
}

/// 表格的一行。
class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.todo,
    required this.last,
    required this.pulling,
    required this.planning,
    required this.onPull,
    required this.onPlan,
    required this.slottedLabel,
  });

  final Todo todo;

  /// 已排期只读徽标文案（`已排期 09:15`）；`null` = 未排期。
  final String? slottedLabel;
  final bool last;
  final bool pulling;
  final bool planning;
  final VoidCallback onPull;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: t.hairSoft)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    todo.title,
                    style: _bodyStyle(tokens: t, size: 13, color: t.ink),
                  ),
                ),
                if (slottedLabel != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Text(
                    slottedLabel!,
                    style: _bodyStyle(tokens: t, size: 11, color: t.meta),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: _wPriority,
            child: Text(todo.priorityAbc?.code ?? '—', style: _monoStyle(tokens: t)),
          ),
          SizedBox(
            width: _wEst,
            child: Text(
              // 库里只存分钟数；显示侧统一走确定性阶梯（90 分钟 / 2 小时 / 1 日…）。
              todo.estMinutes == null
                  ? '—'
                  : formatEstDuration(todo.estMinutes!, l10n),
              style: _monoStyle(tokens: t, size: 12, color: t.meta),
            ),
          ),
          SizedBox(
            width: _wQuadrant,
            child: Text(todo.quadrant?.code ?? '—', style: _monoStyle(tokens: t)),
          ),
          SizedBox(
            width: _wDue,
            child: Text(
              todo.dueDate ?? '—',
              style: _monoStyle(tokens: t, size: 11.5, color: t.meta),
            ),
          ),
          SizedBox(
            width: _wAction,
            child: Align(
              alignment: Alignment.centerLeft,
              // 两个动作并排放：大字号档下宁可换行，也不许把按钮挤出格子。
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _PoolButton(
                    key: ValueKey<String>('todo-pull-${todo.id}'),
                    label: l10n.dialogTodoPull,
                    dense: true,
                    onPressed: pulling ? null : onPull,
                  ),
                  _PoolButton(
                    key: ValueKey<String>('todo-plan-${todo.id}'),
                    label: l10n.dialogPoolAddToToday,
                    dense: true,
                    onPressed: planning ? null : onPlan,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空态。
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.hairSoft, width: 1),
      ),
      child: Text(
        l10n.dialogPoolEmptyLong,
        style: _bodyStyle(tokens: t, size: 12.5, color: t.faint),
      ),
    );
  }
}

/// 行内错误横幅（不用 `SnackBar` —— 内容体没有 `Scaffold`，定位不可靠）。
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.accent, width: 1),
      ),
      child: Text(message, style: _bodyStyle(tokens: t, size: 12.5, color: t.accentInk)),
    );
  }
}

/// 账页按钮（`_GhostAction` / 主按钮两态）。
///
/// 主按钮用 `--ink` 反白：`.btn.pri` 是 B 版允许反白的三处之一。
class _PoolButton extends StatefulWidget {
  const _PoolButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool dense;

  @override
  State<_PoolButton> createState() => _PoolButtonState();
}

class _PoolButtonState extends State<_PoolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = widget.onPressed != null;
    final Color background;
    final Color foreground;
    if (!enabled) {
      background = t.sunken;
      foreground = t.faint;
    } else if (widget.primary) {
      background = _hovered ? t.ink2 : t.ink;
      foreground = t.paper;
    } else {
      background = _hovered ? t.sunken : t.card;
      foreground = _hovered ? t.ink : t.ink2;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: background,
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
                border: Border.all(
                  color: widget.primary && enabled
                      ? t.ink
                      : t.hairStrong,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: _bodyStyle(
                  tokens: t,
                  size: widget.dense ? 11.5 : 12.5,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 输入框统一外观：4px 圆角 + `hair-strong` 边（可交互边界）+ `card` 底。
InputDecoration _fieldDecoration({
  required ThemeTokens tokens,
  required String hint,
}) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: _bodyStyle(tokens: tokens, size: 12.5, color: tokens.faint),
    isDense: true,
    filled: true,
    fillColor: tokens.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(tokens.hairStrong),
    enabledBorder: border(tokens.hairStrong),
    focusedBorder: border(tokens.ink, width: 1.5),
  );
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({
  required ThemeTokens tokens,
  double size = 12.5,
  Color? color,
}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color ?? tokens.ink,
    height: 1.45,
  );
}

/// 数字字体样式（`AppFonts.mono` + `tabular-nums`）。
TextStyle _monoStyle({
  required ThemeTokens tokens,
  double size = 11.5,
  Color? color,
}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color ?? tokens.meta,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}