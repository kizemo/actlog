// =============================================================================
// desktop · 共享确认对话框（需求 9：删除 / 危险动作统一二次确认）
// =============================================================================
// 形态照抄 `pages/settings_page.dart` 既有的 `showDialog<bool>` + `AlertDialog`
// 用法：标题 / 正文 / 取消 + 确认两个 `TextButton`。
// 文案走中文常量（与绝大多数 widget 一致），不引入需要 `flutter gen-l10n`
// 的新机制。
// =============================================================================

import 'package:flutter/material.dart';

/// 弹出确认对话框。
///
/// 返回 `true` = 用户点了确认，`false` = 取消（含点遮罩 / Esc 关闭对话框）。
///
/// [destructive] 为 `true`（默认）时确认按钮用 `colorScheme.error` 强调；
/// 为 `false` 时用默认样式，适合「合并 / 归档」这类非破坏性动作。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '删除',
  String cancelLabel = '取消',
  bool destructive = true,
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('confirm-dialog-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          key: const ValueKey<String>('confirm-dialog-confirm'),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}