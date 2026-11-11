import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart' as wm;

import '../../theme/app_tokens.dart';

/// 顶栏高度（Windows 说明按钮区的标准高度）。
///
/// 写死 32，不跟随密度档：这是**系统窗口控件**的尺寸，不是正文排版的一部分，
/// 跟着字号缩放变高会破坏三钮的命中区与 Win11 snap 的手感。
const double kTopBarHeight = 32;

/// 顶栏窗口按钮的命中区宽（44×32，Windows 原生三钮的常规大小）。
const double kTopBarButtonWidth = 44;

/// 品牌标记在顶栏内的顶边距（底边距 = 32 − 16 − 12 = 4）。
///
/// 品牌标记**不再垂直居中**：居中时上下各 8，用户要求把标记整体再抬高一点。
/// 抬高靠 `Padding` 实现，**不动 [kTopBarHeight]** —— 32 是系统窗口控件的尺寸，
/// 改它会破坏三钮的命中区与 Win11 snap 的手感。
const double kBrandMarkTopGap = 12;

/// 是否已给最大化钮接线 Win11 snap layouts。
///
/// 默认 `false`：widget test 与任何没有原生窗口的环境都不该碰插件。
/// 挂载层（`desktop_shell.dart`）在原生窗口就绪后调
/// [enableNativeMaximizeButtonBounds] 打开；用 `ValueNotifier` 而不是普通 `bool`，
/// 是因为顶栏可能先于接线完成渲染，需要一次重建把包装挂上去。
final ValueNotifier<bool> _nativeMaximizeBounds = ValueNotifier<bool>(false);

/// 打开最大化钮的 snap 接线（由挂载层在窗口就绪后调用一次；测试不调用）。
///
/// 语义与单位（插件 `cnativeapi` 的 `window.h` · `SetMaximizeButtonBounds` 注释）：
/// * 矩形按**逻辑像素**（DIP）给，原点 = **内容区左上角**；
/// * Windows 侧自己做逻辑→物理换算（`window_windows.cpp` 里乘窗口 scale），
///   所以这里不需要手动拿 `devicePixelRatio`；
/// * 空矩形 = 清除登记；窗口 resize 边框压住按钮的那圈仍归系统边框；
/// * 登记后按钮**仍收到 pointer**（hover / press / tap 透传给内容），所以自绘三钮
///   的交互不受影响。
void enableNativeMaximizeButtonBounds() {
  _nativeMaximizeBounds.value = true;
}

/// 顶栏上的单色线条图标（全部用 `CustomPaint` 画，不引图片资源）。
enum TopBarGlyph {
  /// 最小化：一横。
  minimize,

  /// 最大化：空心方。
  maximize,

  /// 还原：错位双方。
  restore,

  /// 关闭：X。
  close,
}

/// 应用内自绘顶栏（替代 Windows 原生标题栏）。
///
/// 纪律（`design-demos/TOKENS.md`）：
/// * 底色 `--paper`，与 [LedgerShell] 的账页同底无缝融合：**无分隔线、无阴影**；
/// * 三钮常态 `--meta`，hover 底 `--sunken` + 图标 `--ink`；
/// * **禁红 / 禁赭石**：顶栏不属于「缺口 / 警示」，`--accent` 与红色都不许出现。
///
/// 本组件**不直接调用** `window_manager` 的任何方法：窗口副作用由挂载层
/// （`desktop_shell.dart`）通过回调注入 —— 这样 widget 测试不需要任何插件就能跑（T5）。
/// 唯一的例外是 Win11 snap layouts 的接线：系统要的是钮的屏幕矩形，只能由布局层给，
/// 所以这里用 `MaximizeButtonArea` 包装最大化钮，且**默认关闭**，
/// 由挂载层在原生窗口就绪后调 [enableNativeMaximizeButtonBounds] 打开。
class AppTopBar extends StatelessWidget {
  /// 创建顶栏。
  const AppTopBar({
    super.key,
    required this.isMaximized,
    this.onMinimize,
    this.onToggleMaximize,
    this.onClose,
    this.onDragStart,
  });

  /// 窗口是否处于最大化：决定右侧中间钮画「最大化」还是「还原」。
  final ValueListenable<bool> isMaximized;

  /// 最小化窗口。
  final VoidCallback? onMinimize;

  /// 最大化 / 还原切换（钮点击与空白区双击共用）。
  final VoidCallback? onToggleMaximize;

  /// 关闭窗口（挂载层接到 `windowManager.close()` ⇒ 隐藏到托盘）。
  final VoidCallback? onClose;

  /// 顶栏空白区被拖动**超过手势阈值** ⇒ 开始拖动窗口。
  ///
  /// 按下瞬间不触发：系统模态移动循环会吞掉后续按键，双击就再也到不了框架。
  final VoidCallback? onDragStart;

  /// 最小化钮（测试用来定位命中区）。
  static const Key minimizeButtonKey = ValueKey<String>('app-top-bar-minimize');

  /// 最大化 / 还原钮。
  static const Key maximizeButtonKey = ValueKey<String>('app-top-bar-maximize');

  /// 关闭钮。
  static const Key closeButtonKey = ValueKey<String>('app-top-bar-close');

  /// 顶栏空白拖拽区。
  static const Key dragAreaKey = ValueKey<String>('app-top-bar-drag');

  /// 品牌标记位（I03 新品牌标记 PNG）。
  static const Key brandMarkKey = ValueKey<String>('app-top-bar-brand-mark');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kTopBarHeight,
      child: Material(
        color: AppTokens.paper,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 16),
            // 品牌标记抬高到顶边距 12。Row 的十字轴是垂直居中，所以 Padding 盒
            // **必须凑满 32**（12 + 16 + 4）标记才会落在 12..28；只写上边距会让
            // 盒高变 28、居中原点回到 2，等于白抬。
            const Padding(
              padding: EdgeInsets.only(top: kBrandMarkTopGap, bottom: 4),
              child: _BrandMark(),
            ),
            // 左标识与拖拽区之间的呼吸位（原来这里还跟着一段英文品牌字，
            // 中文名「知行日志」已在左导航品牌块里，顶栏不再重复）。
            const SizedBox(width: 8),
            // 空白区是拖拽把手：左侧标识与右侧三钮之外的整段都算「标题栏」。
            //
            // 拖拽**必须由位移触发**，不能在 `onPointerDown` 里就 `startDragging()`：
            // 后者发 `WM_NCLBUTTONDOWN(HTCAPTION)`，调用线程进系统模态移动循环，
            // 第二次按下回不到 Flutter ⇒ `onDoubleTap` 永不触发（真机证据
            // `reports/task30-btn3.log`：`DBLCLICK_MAXIMIZE VERDICT=NO_EFFECT`）。
            // pan 默认要超过 `kPanSlop` 才在 gesture arena 里取胜，所以轻点与双击
            // 仍归 `onDoubleTap`，两套手势可以共存。
            Expanded(
              child: GestureDetector(
                key: dragAreaKey,
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (_) => onDragStart?.call(),
                onDoubleTap: () => onToggleMaximize?.call(),
                child: const SizedBox.expand(),
              ),
            ),
            TopBarButton(
              key: minimizeButtonKey,
              glyph: TopBarGlyph.minimize,
              label: '最小化',
              onPressed: onMinimize,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isMaximized,
              builder: (BuildContext context, bool maximized, Widget? _) {
                final TopBarButton button = TopBarButton(
                  key: maximizeButtonKey,
                  glyph: maximized ? TopBarGlyph.restore : TopBarGlyph.maximize,
                  label: maximized ? '还原' : '最大化',
                  onPressed: onToggleMaximize,
                );
                return ValueListenableBuilder<bool>(
                  valueListenable: _nativeMaximizeBounds,
                  builder: (BuildContext context, bool snap, Widget? _) {
                    // 未接线时是普通按钮；接线后包一层 `MaximizeButtonArea`：
                    // 它把钮的屏幕矩形（逻辑像素）在每帧后喂给
                    // `setMaximizeButtonBounds`，并在移动 / resize / 卸载时自动
                    // 跟随与清除 —— 这是 Win11 悬停飞出 snap layouts 的前提。
                    // 自绘钮的 hover / 点击由它在内容层照旧处理。
                    return snap ? wm.MaximizeButtonArea(child: button) : button;
                  },
                );
              },
            ),
            TopBarButton(
              key: closeButtonKey,
              glyph: TopBarGlyph.close,
              label: '关闭',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶栏右侧三钮之一（44×32 命中区，单色线条图标）。
class TopBarButton extends StatefulWidget {
  /// 创建窗口按钮。
  const TopBarButton({
    required super.key,
    required this.glyph,
    required this.label,
    this.onPressed,
  });

  /// 画哪个图标（最大化 / 还原由顶栏按状态选）。
  final TopBarGlyph glyph;

  /// 无障碍名称（图标本身没有文字）。
  final String label;

  /// 点击动作。
  final VoidCallback? onPressed;

  @override
  State<TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<TopBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hovered = _hovered && widget.onPressed != null;
    return Semantics(
      label: widget.label,
      button: true,
      child: ColoredBox(
        color: hovered ? AppTokens.sunken : Colors.transparent,
        child: InkWell(
          // 窗口按钮不进 Tab 序：它不是页面里的操作项（键条上的承诺只管内容区）。
          canRequestFocus: false,
          onTap: widget.onPressed,
          onHover: (bool value) => setState(() => _hovered = value),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: kTopBarButtonWidth,
            height: kTopBarHeight,
            child: Center(
              child: CustomPaint(
                size: const Size.square(16),
                painter: _GlyphPainter(
                  glyph: widget.glyph,
                  color: hovered ? AppTokens.ink : AppTokens.meta,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 品牌标识：I03 新品牌标记（透明底 PNG，深蓝碗形叠合 + 基线）。
///
/// 真源 `design-demos/logo-set-i-bowl-overlap-2026-11-11/I03-bowl36-navy-hard-mark.png`
/// （1024×1024 裁到墨迹 bbox 后缩到 64×32）⇒ 颜色由 PNG 自带，**不硬编码色值**。
///
/// 16 高，宽度按原始比例自适应（≈32×16）；顶边距见 [kBrandMarkTopGap]。
///
/// 旧的「账页」自绘（方框 + 两道账目线）已删除：它与品牌真源不是同一个东西，
/// 且换资源解决不了 —— 这里直接渲染品牌真源本身。
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand_mark.png',
      key: AppTopBar.brandMarkKey,
      height: 16,
      filterQuality: FilterQuality.medium,
      // 纯装饰：中文名「知行日志」在左导航品牌块里，顶栏不必再念一遍。
      excludeFromSemantics: true,
    );
  }
}

/// 三钮图标的绘制器：全部单色线条，笔画 1.2（16px 画布里最接近 Windows 的细线）。
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.glyph, required this.color});

  final TopBarGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    switch (glyph) {
      case TopBarGlyph.minimize:
        // 一横（10px）。
        canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), stroke);
      case TopBarGlyph.maximize:
        // 空心方 11×11。
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: 11, height: 11),
          stroke,
        );
      case TopBarGlyph.restore:
        // 前排方 + 后排方只画露出来的三边（错位双方）。
        canvas.drawRect(
          Rect.fromLTWH(cx - 5.5, cy - 2.5, 8, 8),
          stroke,
        );
        final Path back = Path()
          ..moveTo(cx - 2.5, cy - 2.5)
          ..lineTo(cx - 2.5, cy - 5.5)
          ..lineTo(cx + 5.5, cy - 5.5)
          ..lineTo(cx + 5.5, cy + 2.5)
          ..lineTo(cx + 2.5, cy + 2.5);
        canvas.drawPath(back, stroke);
      case TopBarGlyph.close:
        // X（10×10）。
        canvas.drawLine(
          Offset(cx - 4.5, cy - 4.5),
          Offset(cx + 4.5, cy + 4.5),
          stroke,
        );
        canvas.drawLine(
          Offset(cx + 4.5, cy - 4.5),
          Offset(cx - 4.5, cy + 4.5),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}