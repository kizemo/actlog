import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 统一焦点环：`--ink` 2px 实线（TOKENS §5）。**不得**用赭石。
///
/// 被动装饰件：自己不申请焦点、不进 Tab 遍历、不改变子组件布局。
/// 聚焦态来自 [focusNode]（通常是子组件 `InkWell` / `Focus` 自己的节点）；
/// [focusNode] 为 null 时永不点亮，也不报错。
///
/// 两种判据：
/// - 默认（[requirePrimaryFocus] 为 `false`）⇒ 看 `hasFocus`：节点自己或
///   子孙拿到焦点都亮（芯片、勾选框的既有行为）。
/// - [requirePrimaryFocus] 为 `true` ⇒ **只**看节点自己是不是
///   `FocusManager.primaryFocus`：焦点落进子孙（例如行内的勾选框）时熄灭，
///   保证「就近优先」只有最内层一个环。
class FocusRing extends StatefulWidget {
  /// 创建焦点环。
  const FocusRing({
    super.key,
    required this.child,
    this.focusedBorderWidth = 2,
    this.focusNode,
    this.ringKey = const ValueKey<String>('focus-ring-border'),
    this.requirePrimaryFocus = false,
  });

  /// 内容。
  final Widget child;

  /// 聚焦时的环宽（未聚焦时同宽透明，避免布局跳动）。
  final double focusedBorderWidth;

  /// 聚焦态来源；null 表示永不点亮。
  final FocusNode? focusNode;

  /// 环自身的 key（默认与历史 key 一致；同一容器里挂多个环时用来区分）。
  final Key ringKey;

  /// 是否只在 [focusNode] 自己持有主焦点时点亮（默认沿用 `hasFocus`）。
  final bool requirePrimaryFocus;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  FocusNode? _node;
  bool _focused = false;

  /// 是否已向 `FocusManager` 注册主焦点监听（只有 [FocusRing.requirePrimaryFocus] 才注册）。
  bool _managerBound = false;

  @override
  void initState() {
    super.initState();
    _bind(widget.focusNode);
  }

  @override
  void didUpdateWidget(FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.requirePrimaryFocus != widget.requirePrimaryFocus) {
      _unbind();
      _bind(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  /// 此刻该不该亮。
  ///
  /// `requirePrimaryFocus` 走 `FocusManager.instance.primaryFocus`：父子链上
  /// 每个节点的 `hasFocus` 在子孙拿到焦点时**仍为 true**，拿它判会父子双亮；
  /// 而 `hasPrimaryFocus` 只是计算属性（`_manager?.primaryFocus == this`），
  /// 父节点不保证收到自己的通知 —— 所以变化由 `FocusManager` 的监听器驱动
  /// （见 [_bind]），这里只做无副作用的读取。
  bool _resolveFocused() {
    final FocusNode? node = _node;
    if (node == null) {
      return false;
    }
    if (widget.requirePrimaryFocus) {
      return FocusManager.instance.primaryFocus == node;
    }
    return node.hasFocus;
  }

  void _bind(FocusNode? node) {
    _node = node;
    if (node == null) {
      _focused = false;
      return;
    }
    _focused = _resolveFocused();
    node.addListener(_onFocusChanged);
    if (widget.requirePrimaryFocus) {
      // SDK 口径（`focus_manager.dart`）：主焦点变化时 `FocusManager`
      // 必 `notifyListeners()`，官方建议就是 `addListener` / `removeListener`。
      FocusManager.instance.addListener(_onPrimaryFocusChanged);
      _managerBound = true;
    }
  }

  void _unbind() {
    _node?.removeListener(_onFocusChanged);
    if (_managerBound) {
      FocusManager.instance.removeListener(_onPrimaryFocusChanged);
      _managerBound = false;
    }
    _node = null;
  }

  void _onFocusChanged() => _syncFocus();

  /// 主焦点变了（可能只是换了兄弟节点）⇒ 重新判定本环。
  void _onPrimaryFocusChanged() => _syncFocus();

  void _syncFocus() {
    final bool focused = _resolveFocused();
    if (!mounted || focused == _focused) {
      return;
    }
    setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              key: widget.ringKey,
              duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: _focused ? AppTokens.ink : Colors.transparent,
                  width: widget.focusedBorderWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}