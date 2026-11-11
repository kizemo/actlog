import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/shell/app_top_bar.dart';

/// 挂一个只含顶栏的最小宿主。
///
/// 关键点：这里**不**碰 `window_manager` —— 顶栏只吃注入的回调（T5），
/// 所以本文件在纯 widget 环境里就能跑，不需要任何插件。
Future<void> _pumpTopBar(
  WidgetTester tester, {
  ValueNotifier<bool>? maximized,
  VoidCallback? onMinimize,
  VoidCallback? onToggleMaximize,
  VoidCallback? onClose,
  VoidCallback? onDragStart,
  double textScale = 1,
}) async {
  final Widget bar = AppTopBar(
    isMaximized: maximized ?? ValueNotifier<bool>(false),
    onMinimize: onMinimize,
    onToggleMaximize: onToggleMaximize,
    onClose: onClose,
    onDragStart: onDragStart,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          // 文本缩放只放大**文字**，不放 `SizedBox` / 图片盒 ⇒ 顶栏几何必须按像素量。
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: bar,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('顶栏高 32、底色是纸色、渲染三钮且**无**英文品牌字', (WidgetTester tester) async {
    await _pumpTopBar(tester);

    // 英文 `actlog` 已从顶栏移除（中文名「知行日志」在左导航品牌块里，
    // 那是 `nav_rail.dart` 的另一棵树，不在本文件断言范围内）。
    expect(find.text('actlog'), findsNothing);
    expect(find.text('actlog').evaluate().length, 0);
    expect(find.byKey(AppTopBar.minimizeButtonKey), findsOneWidget);
    expect(find.byKey(AppTopBar.maximizeButtonKey), findsOneWidget);
    expect(find.byKey(AppTopBar.closeButtonKey), findsOneWidget);

    // 高度写死 32：这是系统窗口控件的尺寸，不跟字号缩放走。
    expect(tester.getSize(find.byType(AppTopBar)).height, kTopBarHeight);
    // 三钮命中区 44×32。
    for (final Key key in <Key>[
      AppTopBar.minimizeButtonKey,
      AppTopBar.maximizeButtonKey,
      AppTopBar.closeButtonKey,
    ]) {
      expect(
        tester.getSize(find.byKey(key)),
        const Size(kTopBarButtonWidth, kTopBarHeight),
      );
    }

    // 底色 --paper：与账页同底无缝融合（顶栏自己不画分隔线、不加阴影）。
    final Material bar = tester.widget<Material>(
      find.descendant(of: find.byType(AppTopBar), matching: find.byType(Material)).first,
    );
    expect(bar.color, AppTokens.paper);
    expect(bar.elevation, 0);
    expect(
      find.descendant(of: find.byType(AppTopBar), matching: find.byType(Divider)),
      findsNothing,
    );
  });

  testWidgets('品牌位渲染 I03 新标记 asset，顶栏不再有旧账页自绘', (WidgetTester tester) async {
    await _pumpTopBar(tester);

    final Finder mark = find.byKey(AppTopBar.brandMarkKey);
    expect(mark, findsOneWidget);

    final Image image = tester.widget<Image>(mark);
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/brand_mark.png');
    // 16 高（像素盒，不随字号缩放）。
    expect(image.height, 16);

    // 旧实现是第 4 个 `CustomPaint`（品牌位自绘）；现在顶栏里只剩三钮的 3 个。
    expect(
      find.descendant(of: find.byType(AppTopBar), matching: find.byType(CustomPaint)),
      findsNWidgets(3),
    );

    // 品牌位在拖拽区之外：不得吞掉拖拽手势。
    expect(
      find.ancestor(of: mark, matching: find.byKey(AppTopBar.dragAreaKey)),
      findsNothing,
    );
  });

  testWidgets('品牌标记顶边距 11–13px、底边距 3–5px（不再垂直居中）', (WidgetTester tester) async {
    await _pumpTopBar(tester);

    final Rect bar = tester.getRect(find.byType(AppTopBar));
    final Rect mark = tester.getRect(find.byKey(AppTopBar.brandMarkKey));

    final double topGap = mark.top - bar.top;
    final double bottomGap = bar.bottom - mark.bottom;

    // 判别性断言：垂直居中时是 8 / 8，本用例必须能把它判红。
    expect(topGap, inInclusiveRange(11, 13), reason: '顶边距实测 $topGap');
    expect(bottomGap, inInclusiveRange(3, 5), reason: '底边距实测 $bottomGap');
    // 上下边距之和 = 顶栏高 − 标记高，说明标记没被压扁、也没超出顶栏。
    expect(topGap + bottomGap, kTopBarHeight - 16);

    // 常量与实测互证：改了 `Padding` 忘改常量（或反过来）都会在这里红。
    expect(kBrandMarkTopGap, inInclusiveRange(11, 13));
    expect(topGap, closeTo(kBrandMarkTopGap, 0.01));

    // 顶栏高仍是 32（系统窗口控件尺寸，不许跟着字号走）。
    expect(bar.height, kTopBarHeight);
    expect(mark.height, 16);
  });

  testWidgets('200% 文本缩放下顶边距不变（间距是像素盒，不随字号走）', (WidgetTester tester) async {
    await _pumpTopBar(tester, textScale: 2);

    final Rect bar = tester.getRect(find.byType(AppTopBar));
    final Rect mark = tester.getRect(find.byKey(AppTopBar.brandMarkKey));

    expect(bar.height, kTopBarHeight);
    expect(mark.height, 16);
    expect(mark.top - bar.top, inInclusiveRange(11, 13));
  });

  testWidgets('brand_mark.png 是合法 PNG（签名 + IHDR 宽高 > 0）', (WidgetTester tester) async {
    // 刻意**不解码**：widget 测试里真去解码 PNG 会挂住等待真实 asset 通道。
    // 这里只读字节校验 PNG 结构（`flutter test` 的工作目录就是 package 根）。
    final File file = File('assets/brand_mark.png');
    expect(file.existsSync(), isTrue);

    final List<int> bytes = file.readAsBytesSync();
    expect(bytes.length, greaterThan(24));
    // PNG 签名 89 50 4E 47 0D 0A 1A 0A。
    expect(bytes.sublist(0, 8), <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    // IHDR 块：长度(4) + 类型(4) + 宽(4) + 高(4) + 位深(1) + 颜色型(1) …
    expect(bytes.sublist(12, 16), <int>[0x49, 0x48, 0x44, 0x52]);
    final int width =
        (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final int height =
        (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    expect(width, greaterThan(0));
    expect(height, greaterThan(0));
    // 颜色类型 6 = RGBA（透明底纯形）。
    expect(bytes[25], 6);
  });

  testWidgets('app_top_bar.dart 里不再有旧账页自绘、也不再有英文品牌字', (WidgetTester tester) async {
    final File source = File('lib/src/widgets/shell/app_top_bar.dart');
    expect(source.existsSync(), isTrue);
    final String text = source.readAsStringSync();
    // 旧自绘类名写成两段拼接：源码里（含本用例）**不得**出现这个词的完整拼写，
    // 否则「旧账页自绘已消失」这条 grep 判据会被本用例自己污染。
    const String oldPainter = 'BrandMark' 'Painter';
    expect(text.contains(oldPainter), isFalse);
    expect(text.contains('brand_mark.png'), isTrue);

    // 品牌字常量与那行 `Text('actlog')` 已删（同样拼接，避免判据被本用例污染）。
    expect(text.contains('_brand' 'Style'), isFalse);
    expect(text.contains("Text('act" "log')"), isFalse);
    // 品牌字连带删掉后 `app_fonts.dart` 不该再被这个文件引用（否则 analyze 报 unused import）。
    expect(text.contains('app_fonts.dart'), isFalse);
  });

  testWidgets('点关闭钮只触发注入的 onClose', (WidgetTester tester) async {
    int minimize = 0;
    int toggle = 0;
    int close = 0;
    await _pumpTopBar(
      tester,
      onMinimize: () => minimize++,
      onToggleMaximize: () => toggle++,
      onClose: () => close++,
    );

    await tester.tap(find.byKey(AppTopBar.closeButtonKey));
    await tester.pump();

    expect(close, 1);
    expect(minimize, 0);
    expect(toggle, 0);
  });

  testWidgets('点最小化钮触发 onMinimize', (WidgetTester tester) async {
    int minimize = 0;
    int close = 0;
    await _pumpTopBar(
      tester,
      onMinimize: () => minimize++,
      onClose: () => close++,
    );

    await tester.tap(find.byKey(AppTopBar.minimizeButtonKey));
    await tester.pump();

    expect(minimize, 1);
    expect(close, 0);
  });

  testWidgets('最大化钮：未最大化画「最大化」、点击触发切换', (WidgetTester tester) async {
    int toggle = 0;
    final ValueNotifier<bool> maximized = ValueNotifier<bool>(false);
    addTearDown(maximized.dispose);
    await _pumpTopBar(
      tester,
      maximized: maximized,
      onToggleMaximize: () => toggle++,
    );

    expect(
      tester.widget<TopBarButton>(find.byKey(AppTopBar.maximizeButtonKey)).glyph,
      TopBarGlyph.maximize,
    );

    await tester.tap(find.byKey(AppTopBar.maximizeButtonKey));
    await tester.pump();

    expect(toggle, 1);
  });

  testWidgets('最大化状态为 true 时图标是还原态，状态变更会跟着换', (WidgetTester tester) async {
    final ValueNotifier<bool> maximized = ValueNotifier<bool>(true);
    addTearDown(maximized.dispose);
    await _pumpTopBar(tester, maximized: maximized);

    TopBarGlyph glyphNow() => tester
        .widget<TopBarButton>(find.byKey(AppTopBar.maximizeButtonKey))
        .glyph;

    expect(glyphNow(), TopBarGlyph.restore);

    // 状态真身在原生窗口，Dart 侧只是镜像 ⇒ 镜像变了顶栏必须立刻跟着换图标。
    maximized.value = false;
    await tester.pump();

    expect(glyphNow(), TopBarGlyph.maximize);
  });

  // 判别性用例（W-2 返工核心）：旧实现在 `onPointerDown` 就调 `startDragging()`，
  // 真机上系统模态移动循环吞掉第二次按下，双击永远到不了框架
  // （`reports/task30-btn3.log`：`DBLCLICK_MAXIMIZE VERDICT=NO_EFFECT`）。
  // 本条断言打在**触发时机**上：轻点/双击都不得启动拖拽。
  testWidgets('空白区快速两次轻点：恰好 1 次最大化切换、0 次拖拽', (WidgetTester tester) async {
    int toggle = 0;
    int drag = 0;
    await _pumpTopBar(
      tester,
      onToggleMaximize: () => toggle++,
      onDragStart: () => drag++,
    );

    final Finder blank = find.byKey(AppTopBar.dragAreaKey);

    await tester.tap(blank);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(blank);
    await tester.pumpAndSettle();

    expect(toggle, 1);
    expect(drag, 0);
  });

  testWidgets('空白区单次轻点（按下 + 极小位移 + 抬起）不触发拖拽', (WidgetTester tester) async {
    int toggle = 0;
    int drag = 0;
    await _pumpTopBar(
      tester,
      onToggleMaximize: () => toggle++,
      onDragStart: () => drag++,
    );

    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.byKey(AppTopBar.dragAreaKey)));
    await tester.pump(const Duration(milliseconds: 16));
    // 2px 远小于 `kTouchSlop`：手抖不该被当成拖动。
    await gesture.moveBy(const Offset(0, 2));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(drag, 0);
    expect(toggle, 0);
  });

  testWidgets('空白区拖动超过手势阈值触发一次拖拽', (WidgetTester tester) async {
    int toggle = 0;
    int drag = 0;
    await _pumpTopBar(
      tester,
      onToggleMaximize: () => toggle++,
      onDragStart: () => drag++,
    );

    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.byKey(AppTopBar.dragAreaKey)));
    await tester.pump(const Duration(milliseconds: 16));
    // 越过 `kPanSlop` 才在 arena 里取胜 ⇒ 恰好触发一次拖拽（不是每次 move 一次）。
    await gesture.moveBy(const Offset(0, kPanSlop + 8));
    await tester.pump();
    expect(drag, 1);

    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(drag, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(toggle, 0);
  });

  testWidgets('三钮轻点各自回调 1 次且不触发拖拽', (WidgetTester tester) async {
    int minimize = 0;
    int toggle = 0;
    int close = 0;
    int drag = 0;
    await _pumpTopBar(
      tester,
      onMinimize: () => minimize++,
      onToggleMaximize: () => toggle++,
      onClose: () => close++,
      onDragStart: () => drag++,
    );

    await tester.tap(find.byKey(AppTopBar.minimizeButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(AppTopBar.maximizeButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(AppTopBar.closeButtonKey));
    await tester.pumpAndSettle();

    expect(minimize, 1);
    expect(toggle, 1);
    expect(close, 1);
    expect(drag, 0);
  });

  testWidgets('hover 底是 --sunken（禁红、禁赭石）', (WidgetTester tester) async {
    // 必须给上回调：没有动作的按钮不画 hover 底（禁用态不该有反馈）。
    await _pumpTopBar(tester, onClose: () {});

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byKey(AppTopBar.closeButtonKey)));
    await tester.pumpAndSettle();

    final ColoredBox surface = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byKey(AppTopBar.closeButtonKey),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(surface.color, AppTokens.sunken);
    expect(surface.color, isNot(AppTokens.accent));
  });
}