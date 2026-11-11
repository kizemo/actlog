import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../providers_p1.dart';
import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// 打开「添加习惯」面板（右轨「习惯速览」右上角那枚 `＋`）。
///
/// 面板挂在 `showDialog` 上：`Esc` 与点遮罩关闭都由 `ModalRoute` 默认提供。
Future<void> showHabitQuickDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const HabitQuickDialog(),
  );
}

/// 「添加习惯」面板：新建一条日常习惯。
///
/// 字段只留 `习惯名`（必填）与 `说明`（可选），保持与「手写一条」同样轻量：
/// 排程固定 `daily`、起始日取今天，保存后立刻出现在「习惯速览」里。
class HabitQuickDialog extends ConsumerStatefulWidget {
  /// 创建「添加习惯」面板。
  const HabitQuickDialog({super.key});

  @override
  ConsumerState<HabitQuickDialog> createState() => _HabitQuickDialogState();
}

class _HabitQuickDialogState extends ConsumerState<HabitQuickDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();

  /// 提交中禁用按钮，防止连点写出两条习惯。
  bool _submitting = false;

  /// 面板内错误原文（不写库、不关面板）。
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '习惯名不能为空');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    // 先取好 navigator 与起始日：await 之后 `context` 不能再直接用于导航
    // （异步安全规则），`ref.read` 也只在 await 之前读一次。
    final NavigatorState navigator = Navigator.of(context);
    final String startDate = ref.read(todayProvider);
    try {
      final repos = ref.read(repositoriesProvider);
      await repos.habit.create(
        name: name,
        description: _description.text.trim(),
        scheduleType: 'daily',
        startDate: startDate,
      );
      // 习惯速览（`FutureProvider`）与勾选状态（`StreamProvider`）都必须显式
      // 失效：新建的习惯没有 checkout 写入，不会触发任何流事件。
      ref.invalidate(habitsForTodayProvider);
      ref.invalidate(habitCheckinsProvider);
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
    return _HabitDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('habit-dialog-name'),
            controller: _name,
            autofocus: true,
            enabled: !_submitting,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('习惯名（必填）'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('habit-dialog-description'),
            controller: _description,
            enabled: !_submitting,
            style: _bodyStyle(size: 13, color: AppTokens.ink),
            decoration: _fieldDecoration('说明（可选）'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            _DialogError(message: _error!),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _DialogButton(
                label: '取消',
                dense: true,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              _DialogButton(
                label: '保存',
                dense: true,
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

/// 账页风的面板外壳：`paper` 底 + `hair` 边 + 4px 圆角 + 480 宽。
///
/// 外观与「手写一条」的 `_LedgerDialog` 一致（那是私有类，这里按同样规格
/// 复刻一份，避免把两个弹窗耦合成一个）。
class _HabitDialog extends StatelessWidget {
  const _HabitDialog({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey<String>('habit-quick-dialog'),
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
                '添加习惯',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.displayFallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppTokens.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '新建一条日常习惯，保存后立刻出现在习惯速览',
                style: _bodyStyle(size: 11.5, color: AppTokens.faint),
              ),
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

/// 面板按钮：`card` 底 + `hair-strong` 边 + `ink2` 字；`primary` 用 `ink` 反白。
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
TextStyle _bodyStyle({double size = 12.5, Color color = AppTokens.ink}) {
  return TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: size,
    color: color,
    height: 1.45,
  );
}