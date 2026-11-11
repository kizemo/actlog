import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'focus_ring.dart';

/// 账页勾选框（`v2-ledger.html:206-211` 的 `.chk`）。
///
/// 形态：22×22 方框 + `✓` / `○` 字形 + 1.5px `--hair-strong` 边 + 3px 圆角；
/// 选中 = `--ink` 底 + `--ink` 边 + `--paper` 字（`--ink` 反白，允许反白的
/// 三处之一）；未选 = `--paper` 底 + `--ink` 字。
///
/// 交互：**自带独立 [FocusNode]**（可单独 Tab 到、单独亮焦点环），
/// `Space` / `Enter` 经 [ActivateIntent] 切换。当外层行也注册了
/// `ActivateIntent` 时，本控件注册的 `Actions` 距离焦点节点更近，
/// 因此**就近优先**——按键只切换勾选框，不会连带触发行级动作。
class LedgerCheckbox extends StatefulWidget {
  /// 创建勾选框。
  const LedgerCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.semanticLabel,
    this.autofocus = false,
  });

  /// 是否已勾选。
  final bool value;

  /// 切换回调；传 null 表示禁用（不可点、不可聚焦）。
  final ValueChanged<bool>? onChanged;

  /// 外部焦点节点（一般不用传，控件会自建并自行释放）。
  final FocusNode? focusNode;

  /// 无障碍标签（读屏用；视觉上不渲染文字）。
  final String? semanticLabel;

  /// 是否自动获焦。
  final bool autofocus;

  @override
  State<LedgerCheckbox> createState() => _LedgerCheckboxState();
}

class _LedgerCheckboxState extends State<LedgerCheckbox> {
  /// 自建焦点节点；外部传入时以外部为准、不接管其生命周期。
  FocusNode? _ownedNode;

  FocusNode get _node =>
      widget.focusNode ??
      (_ownedNode ??= FocusNode(debugLabel: 'LedgerCheckbox'));

  @override
  void dispose() {
    _ownedNode?.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null;

  void _activate() {
    final handler = widget.onChanged;
    if (handler == null) {
      return;
    }
    handler(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final checked = widget.value;
    final border = checked ? AppTokens.ink : AppTokens.hairStrong;
    final fill = checked ? AppTokens.ink : AppTokens.paper;
    final glyphColor =
        checked ? AppTokens.paper : (_enabled ? AppTokens.ink : AppTokens.faint);

    return Semantics(
      checked: checked,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _activate();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _node,
          autofocus: widget.autofocus,
          canRequestFocus: _enabled,
          child: FocusRing(
            focusNode: _node,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _enabled ? _activate : null,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Text(
                  checked ? '✓' : '○',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 13,
                    height: 1,
                    color: glyphColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}