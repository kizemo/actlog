// =============================================================================
// desktop · 共享确认对话框（需求 9：删除 / 危险动作统一二次确认）
// =============================================================================
// 形态照抄 `pages/settings_page.dart` 既有的 `showDialog<bool>` + `AlertDialog`
// 用法：标题 / 正文 / 取消 + 确认两个 `TextButton`。
// 标题与正文由调用方按自身语境给（多数已走 `t.*`）；两个按钮的兜底文案走
// `AppLocalizations`（缺省「删除 / 取消」在 en 态不再露出中文）。
// =============================================================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 弹出确认对话框。
///
/// 返回 `true` = 用户点了确认，`false` = 取消（含点遮罩 / Esc 关闭对话框）。
///
/// [destructive] 为 `true`（默认）时确认按钮用 `colorScheme.error` 强调；
/// 为 `false` 时用默认样式，适合「合并 / 归档」这类非破坏性动作。
///
/// [confirmLabel] / [cancelLabel] 留 `null` 时取当前语言的
/// `commonDelete` / `cancel`。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  // 在 `await` 之前取好文案：`showDialog` 之后 `context` 不再保证可读。
  final AppLocalizations l10n = AppLocalizations.of(context);
  final String resolvedConfirm = confirmLabel ?? l10n.commonDelete;
  final String resolvedCancel = cancelLabel ?? l10n.cancel;
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('confirm-dialog-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(resolvedCancel),
        ),
        TextButton(
          key: const ValueKey<String>('confirm-dialog-confirm'),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(resolvedConfirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}