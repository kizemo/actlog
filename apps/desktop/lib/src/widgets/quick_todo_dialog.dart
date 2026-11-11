import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'priority_marks.dart';

/// 打开「手写一条」面板（键条第一条 `Ctrl+N` 的真身）。
///
/// 面板挂在 `showDialog` 上：`Esc` 与点遮罩关闭都由 `ModalRoute` 默认提供，
/// 键条 `Esc 关闭弹层` 一说的依据就在这里。
Future<void> showQuickTodoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const QuickTodoDialog(),
  );
}

/// 打开「从待办池捞」面板（今日计划段正文顶部那枚入口）。
Future<void> showPullFromPoolDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const PullFromPoolDialog(),
  );
}

/// 「手写一条」面板：新建待办，可选同时捞入当前选中日。
///
/// 字段：标题 / 预估 / 优先级（四维度字形芯片）/ 是否捞入。优先级只回答
/// 「重不重要、急不急」，象限由两者算出；ABC 仍由计划条目行自己改。
class QuickTodoDialog extends ConsumerStatefulWidget {
  /// 创建「手写一条」面板。
  const QuickTodoDialog({super.key});

  @override
  ConsumerState<QuickTodoDialog> createState() => _QuickTodoDialogState();
}

class _QuickTodoDialogState extends ConsumerState<QuickTodoDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _est = TextEditingController();

  /// 待办的四维度优先级；null = 不分级（落库 `quadrant = null`）。
  Quadrant? _quadrant;

  /// 「同时捞入今天」默认勾选：多数场景是「现在就做」。
  bool _pullIntoToday = true;

  /// 提交中禁用按钮，防止连点写出两条。
  bool _submitting = false;

  /// 面板内错误原文（不写库、不关面板）。
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _est.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = '标题不能为空');
      return;
    }
    final estText = _est.text.trim();
    int? estMinutes;
    if (estText.isNotEmpty) {
      final parsed = int.tryParse(estText);
      if (parsed == null || parsed <= 0) {
        setState(() => _error = '预估分钟要填正整数');
        return;
      }
      estMinutes = parsed;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    // 先取好 navigator：await 之后 `context` 不能再直接用于导航（异步安全规则）。
    final NavigatorState navigator = Navigator.of(context);
    try {
      final repos = ref.read(repositoriesProvider);
      final todoId = await repos.todo.create(
        title: title,
        estMinutes: estMinutes,
        dueDate: null,
        quadrant: _quadrant?.code,
        priorityAbc: null,
      );
      if (_pullIntoToday) {
        await repos.todo.pullToPlan(
          todoId,
          ref.read(todoPullTargetDateProvider),
        );
      }
      // 池子是 `FutureProvider` ⇒ 必须显式失效；计划是 Stream ⇒ 自动 +1。
      ref.invalidate(todoPoolProvider);
      if (!mounted) {
        return;
      }
      navigator.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(todoPullTargetDateProvider);
    return _LedgerDialog(
      title: '手写一条',
      subtitle: '先存进待办池；勾选后同时落进 $target 的计划。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('标题', style: _bodyStyle(size: 11.5, color: AppTokens.faint)),
          const SizedBox(height: 4),
          TextField(
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.next,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('要做什么？'),
          ),
          const SizedBox(height: 10),
          Text(
            '预估分钟（可选）',
            style: _bodyStyle(size: 11.5, color: AppTokens.faint),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _est,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('例如 25'),
          ),
          const SizedBox(height: 10),
          Text(
            '优先级（可选）',
            style: _bodyStyle(size: 11.5, color: AppTokens.faint),
          ),
          const SizedBox(height: 4),
          PriorityMarkPicker(
            value: _quadrant,
            enabled: !_submitting,
            onChanged: (next) => setState(() => _quadrant = next),
          ),
          const SizedBox(height: 6),
          // 200% 缩放下文案会变长，用 `Expanded` 包住让它换行而不是挤出面板。
          Row(
            children: <Widget>[
              Checkbox(
                value: _pullIntoToday,
                visualDensity: VisualDensity.compact,
                onChanged: (checked) {
                  setState(() => _pullIntoToday = checked ?? false);
                },
              ),
              Expanded(
                child: Text(
                  '同时捞入今天',
                  style: _bodyStyle(size: 12.5, color: AppTokens.ink2),
                ),
              ),
            ],
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 4),
            _DialogError(message: _error!),
          ],
          const SizedBox(height: 14),
          // 按钮行用 `Wrap`：200% 下两枚按钮放不下时自然换行，不溢出。
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _DialogButton(
                label: '取消',
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              _DialogButton(
                label: _submitting ? '保存中…' : '保存',
                primary: true,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 「从待办池捞」面板：把池子里的待办捞进当前选中日。
///
/// 三态分开渲染（加载 / 出错 / 空），失败时不关面板 —— 用户能改选另一条。
class PullFromPoolDialog extends ConsumerStatefulWidget {
  /// 创建「从待办池捞」面板。
  const PullFromPoolDialog({super.key});

  @override
  ConsumerState<PullFromPoolDialog> createState() =>
      _PullFromPoolDialogState();
}

class _PullFromPoolDialogState extends ConsumerState<PullFromPoolDialog> {
  /// 正在捞的那条（其余行的按钮一起禁用，避免并发写同一日）。
  String? _pullingId;

  String? _error;

  Future<void> _pull(Todo todo) async {
    if (_pullingId != null) {
      return;
    }
    setState(() {
      _pullingId = todo.id;
      _error = null;
    });
    final NavigatorState navigator = Navigator.of(context);
    try {
      await ref
          .read(repositoriesProvider)
          .todo
          .pullToPlan(todo.id, ref.read(todoPullTargetDateProvider));
      ref.invalidate(todoPoolProvider);
      if (!mounted) {
        return;
      }
      // 成功后关面板：捞完一条基本就该回去看计划了。
      navigator.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _pullingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pool = ref.watch(todoPoolProvider);
    final target = ref.watch(todoPullTargetDateProvider);
    return _LedgerDialog(
      title: '从待办池捞',
      subtitle: '捞进 $target 的计划；待办池本身不会被删。',
      child: pool.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, stack) => _DialogError(message: _errorMessage(error)),
        data: (rows) {
          if (rows.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '待办池是空的',
                style: _bodyStyle(size: 12.5, color: AppTokens.faint),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 列表自身滚动：条数多时不把面板撑出屏幕。
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final Todo todo in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _PoolRow(
                            todo: todo,
                            busy: _pullingId != null,
                            pulling: _pullingId == todo.id,
                            onPull: () => _pull(todo),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 6),
                _DialogError(message: _error!),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                children: <Widget>[
                  _DialogButton(
                    label: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 池子里的一行：标题 + 优先级 + 预估 + 「捞入」。
class _PoolRow extends StatelessWidget {
  const _PoolRow({
    required this.todo,
    required this.busy,
    required this.pulling,
    required this.onPull,
  });

  final Todo todo;

  /// 面板里有任意一条在捞 ⇒ 全部按钮禁用。
  final bool busy;

  /// 本条正在捞。
  final bool pulling;

  final VoidCallback onPull;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (todo.priorityAbc != null) todo.priorityAbc!.code,
      if (todo.estMinutes != null) '${todo.estMinutes} 分钟',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.hairSoft, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  todo.title,
                  style: _bodyStyle(size: 12.5, color: AppTokens.ink),
                ),
                if (meta.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(meta, style: _monoStyle()),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DialogButton(
            label: pulling ? '捞入中…' : '捞入',
            dense: true,
            onPressed: busy ? null : onPull,
          ),
        ],
      ),
    );
  }
}

/// 账页风的面板外壳：`paper` 底 + `hair` 边 + 4px 圆角。
///
/// 宽度固定 480（落在派工书要求的 420–520 之间）；`SizedBox` 的宽度会被父约束
/// 夹紧，所以窄窗口下不会溢出，只是变窄。
class _LedgerDialog extends StatelessWidget {
  const _LedgerDialog({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.paper,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: const BorderSide(color: AppTokens.hair, width: 1),
      ),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.displayFallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppTokens.ink,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: _bodyStyle(size: 11.5, color: AppTokens.faint),
                ),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 面板内错误（`accentWash` 底 + `accent` 边，与待办池页的横幅同 token）。
class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.accentWash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.accent, width: 1),
      ),
      child: Text(
        message,
        style: _bodyStyle(size: 12.5, color: AppTokens.accentInk),
      ),
    );
  }
}

/// 面板按钮：`card` 底 + `hair-strong` 边 + `ink2` 字；
/// `primary` 用 `ink` 反白（B 版允许反白的三处之一）。
class _DialogButton extends StatefulWidget {
  const _DialogButton({
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
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final Color background;
    final Color foreground;
    if (!enabled) {
      background = AppTokens.sunken;
      foreground = AppTokens.faint;
    } else if (widget.primary) {
      background = _hovered ? AppTokens.ink2 : AppTokens.ink;
      foreground = AppTokens.paper;
    } else {
      background = _hovered ? AppTokens.sunken : AppTokens.card;
      foreground = _hovered ? AppTokens.ink : AppTokens.ink2;
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
                      ? AppTokens.ink
                      : AppTokens.hairStrong,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: _bodyStyle(
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

/// 仓储异常的统一提取：`ArgumentError` / `StateError` 取 `message` 原文。
String _errorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }
  if (error is ArgumentError) {
    return '${error.message}';
  }
  return '$error';
}

/// 输入框统一外观：4px 圆角 + `hair-strong` 边 + `card` 底。
InputDecoration _fieldDecoration(String hint) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: _bodyStyle(size: 13, color: AppTokens.faint),
    isDense: true,
    filled: true,
    fillColor: AppTokens.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(AppTokens.hairStrong),
    enabledBorder: border(AppTokens.hairStrong),
    focusedBorder: border(AppTokens.ink, width: 1.5),
  );
}

/// 正文字体样式（`AppFonts.body` + 兜底族）。
TextStyle _bodyStyle({
  double size = 12.5,
  Color color = AppTokens.ink,
}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
  );
}

/// 数字/元信息字体样式（`AppFonts.mono` + `tabular-nums`）。
TextStyle _monoStyle({double size = 11, Color color = AppTokens.faint}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    color: color,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}