import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';

/// 包一层最小宿主：只有真实高度，导航栏的 `Spacer` 才有界。
Future<void> _pumpNav(
  WidgetTester tester, {
  String? currentId,
  ValueChanged<String>? onSelected,
  bool horizontal = false,
}) async {
  // 测试默认视口只有 800 宽，横排模式要 1200 必须先把视口撑开。
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: horizontal ? 1200 : NavRail.width,
            height: 800,
            child: NavRail(
              currentId: currentId,
              onSelected: onSelected,
              horizontal: horizontal,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 按指定文字缩放挂竖排 `NavRail`。
///
/// `ACTLOG_TEXT_SCALE=2` 的等价物就是 `MediaQuery.textScaler` 变成
/// `TextScaler.linear(2)`（见 `lib/src/app.dart`）。注意 MediaQuery 必须放在
/// `MaterialApp` **内部**：`WidgetsApp` 会用 `MediaQuery.fromView` 覆盖顶层那份，
/// 套在外面不会生效。
Future<void> _pumpNavScaled(WidgetTester tester, {required double scale}) async {
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: NavRail.width,
                height: 800,
                child: const NavRail(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 从主题取 `labelSmall` 的实际字号（不猜、不硬编码）。
double _labelSizeOf(WidgetTester tester, Finder anchor) =>
    Theme.of(tester.element(anchor)).textTheme.labelSmall?.fontSize ??
    DensityProfile.comfortable.labelSize;

/// 统计某个 Element 子树里所有 `Text` 的字符数（不含根节点自身的 widget）。
int _textChars(Element root) {
  int total = 0;
  void visit(Element element) {
    final Widget widget = element.widget;
    if (widget is Text) {
      total += (widget.data ?? '').runes.length;
    }
    element.visitChildren(visit);
  }

  visit(root);
  return total;
}

void main() {
  testWidgets('竖排导航渲染 6 项与 01–06 序号', (WidgetTester tester) async {
    await _pumpNav(tester);

    expect(NavRail.width, 214);
    for (final String label in <String>['今日', '待办池', '习惯', '项目', '日历', '设置']) {
      expect(find.text(label), findsOneWidget, reason: '缺少导航项 $label');
    }
    for (final String index in <String>['01', '02', '03', '04', '05', '06']) {
      expect(find.text(index), findsOneWidget, reason: '缺少序号 $index');
    }
    expect(find.text('知行日志'), findsOneWidget);
    expect(find.text('actlog'), findsOneWidget);
    // 底注只有在竖排时出现（原型 `@media max-width:1279px` 里 `.nav-foot{display:none}`）。
    expect(find.text('页面切换'), findsOneWidget);
  });

  testWidgets('只有今日 / 待办池 / 习惯 / 日历可点，项目与设置是禁用态', (WidgetTester tester) async {
    final List<String> tapped = <String>[];
    await _pumpNav(tester, onSelected: tapped.add);

    // 4 个可点项各自一个 InkWell；禁用项不渲染任何点击控件。
    expect(find.byType(InkWell), findsNWidgets(4));

    await tester.tap(find.text('待办池'));
    await tester.pump();
    expect(tapped, <String>['inbox']);

    await tester.tap(find.text('习惯'));
    await tester.pump();
    expect(tapped, <String>['inbox', 'habits']);

    await tester.tap(find.text('日历'));
    await tester.pump();
    expect(tapped, <String>['inbox', 'habits', 'calendar']);

    for (final String disabled in <String>['项目', '设置']) {
      await tester.tap(find.text(disabled));
      await tester.pump();
    }
    expect(
      tapped,
      <String>['inbox', 'habits', 'calendar'],
      reason: '禁用项不得触发选中',
    );

    // 禁用项用弱文字色，不用 ink；「习惯」已是可点项，非当前页走 meta。
    final Text disabledLabel = tester.widget<Text>(find.text('项目'));
    expect(disabledLabel.style?.color, AppTokens.faint);
    final Text habitsLabel = tester.widget<Text>(find.text('习惯'));
    expect(habitsLabel.style?.color, AppTokens.meta);
  });

  testWidgets('当前页 = ink 洗底 + ink 字 + 500 字重（不是反白）', (WidgetTester tester) async {
    await _pumpNav(tester, currentId: 'today');

    final Finder washed = find.byWidgetPredicate(
      (Widget widget) => widget is Material && widget.color == AppTokens.inkWash,
    );
    expect(washed, findsOneWidget, reason: '当前页必须且只能用 inkWash 洗底');
    expect(
      find.descendant(of: washed, matching: find.text('今日')),
      findsOneWidget,
    );

    final Text current = tester.widget<Text>(find.text('今日'));
    expect(current.style?.color, AppTokens.ink);
    expect(current.style?.fontWeight, FontWeight.w500);

    // 非当前页保持 meta 色。
    final Text other = tester.widget<Text>(find.text('日历'));
    expect(other.style?.color, AppTokens.meta);
  });

  testWidgets('横排模式：撑满宽度、隐藏底注与品牌副标', (WidgetTester tester) async {
    await _pumpNav(tester, horizontal: true);

    expect(tester.getSize(find.byType(NavRail)).width, 1200);
    expect(find.text('页面切换'), findsNothing);
    expect(find.text('actlog'), findsNothing);
    expect(find.text('今日'), findsOneWidget);
  });

  testWidgets('200% 下序号徽标单行不换行，盒子宽度按缩放后字号算', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 2);

    final Finder badge = find.text('01');
    final double labelSize = _labelSizeOf(tester, badge);
    final TextScaler scaler = MediaQuery.textScalerOf(tester.element(badge));

    // 先证明 200% 真的生效：否则「单行」可能只是因为根本没放大。
    expect(scaler.scale(labelSize), labelSize * 2);

    // 结构兜底：即使将来字号再变，也只横向溢出，不会碎成两行。
    final Text text = tester.widget<Text>(badge);
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);

    final Size size = tester.getSize(badge);
    // 修复前这里是 labelSize * 1.5（未缩放）⇒ 200% 下只有 18.75。
    expect(
      size.width,
      moreOrLessEquals(scaler.scale(labelSize) * 1.5, epsilon: 0.01),
    );
    // 单行高度 = 字号 × 1.3；两行会翻倍，1.6 倍容差仍能判出换行。
    expect(
      size.height,
      lessThanOrEqualTo(scaler.scale(labelSize) * 1.3 * 1.6),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('100% 下序号徽标几何零变化：宽度 = 缩放恒等 × labelSize × 1.5', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 1);

    final Finder badge = find.text('01');
    final double labelSize = _labelSizeOf(tester, badge);
    expect(labelSize, DensityProfile.comfortable.labelSize);

    final TextScaler scaler = MediaQuery.textScalerOf(tester.element(badge));
    // 100% 下缩放在数学上是恒等的 ⇒ 新写法的结果与修复前逐位相同。
    expect(scaler.scale(labelSize), labelSize);

    for (final String index in <String>['01', '02', '03', '04', '05', '06']) {
      expect(
        tester.getSize(find.text(index)).width,
        moreOrLessEquals(labelSize * 1.5, epsilon: 0.0001),
        reason: '序号 $index 的盒子宽度变了（1.5 系数或字号被改动）',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% 下底注以整组为换行单位，不出现单字符孤立行', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 2);

    expect(find.text('页面切换'), findsOneWidget);
    expect(find.widgetWithText(KeyCap, 'Ctrl'), findsOneWidget);
    expect(find.widgetWithText(KeyCap, '1'), findsOneWidget);
    // B2（2026-11-12 T10）：习惯页落地后 `Ctrl+1…4` 全有落点；
    // 导航只剩项目 / 设置两项禁用 ⇒ 键帽由 '3' 同步为 '4'。
    expect(find.widgetWithText(KeyCap, '4'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 底注外层是一个 `Wrap`；组内还有嵌套 `Wrap`，所以按「直接子项里有
    // 『页面切换』」定位最外层那个，不靠顺序猜。
    Element? outerWrap;
    for (final Element candidate
        in find
            .descendant(of: find.byType(NavRail), matching: find.byType(Wrap))
            .evaluate()) {
      final List<Element> children = <Element>[];
      candidate.visitChildren(children.add);
      if (children.any(
        (Element child) =>
            child.widget is Text && (child.widget as Text).data == '页面切换',
      )) {
        outerWrap = candidate;
      }
    }
    expect(outerWrap, isNotNull, reason: '底注外层 Wrap 未找到');
    final Element wrapElement = outerWrap!;

    // ① 结构判据：外层 Wrap 的每个直接子项自身都至少 2 个字符。
    //    修复前 Wrap 直接挂了 `Text('+')` / `KeyCap('1')` 这类单字符子项，
    //    一旦被单独甩到一行就是孤立行；现在它们被绑进组 / 单位。
    final List<Element> wrapChildren = <Element>[];
    wrapElement.visitChildren(wrapChildren.add);
    expect(wrapChildren, hasLength(3), reason: '底注应有 3 个换行单位');
    for (final Element child in wrapChildren) {
      expect(
        _textChars(child),
        greaterThanOrEqualTo(2),
        reason: '存在只含 1 个字符的换行单位（孤立行来源）',
      );
    }

    // ② 渲染判据：按纵向位置归组出真实的行，每行的字符总数 ≥ 2。
    final List<Rect> rects = <Rect>[];
    final List<int> counts = <int>[];
    void collect(Element element) {
      final Widget widget = element.widget;
      if (widget is Text) {
        rects.add(tester.getRect(find.byWidget(widget)));
        counts.add((widget.data ?? '').runes.length);
      }
      element.visitChildren(collect);
    }

    collect(wrapElement);
    expect(rects, hasLength(6), reason: '底注应恰好 6 段文案');

    final List<int> order = List<int>.generate(rects.length, (int i) => i)
      ..sort((int a, int b) => rects[a].top.compareTo(rects[b].top));
    final List<int> charsPerRun = <int>[];
    double runBottom = 0;
    for (final int i in order) {
      // 同一行的文本垂直方向必然重叠；换行后顶部会落到上一行底部之下。
      if (charsPerRun.isEmpty || rects[i].top >= runBottom - 0.5) {
        charsPerRun.add(counts[i]);
        runBottom = rects[i].bottom;
      } else {
        charsPerRun[charsPerRun.length - 1] += counts[i];
        if (rects[i].bottom > runBottom) {
          runBottom = rects[i].bottom;
        }
      }
    }
    for (final int chars in charsPerRun) {
      expect(chars, greaterThanOrEqualTo(2), reason: '底注出现只含 $chars 个字符的孤立行');
    }
    // 6 段文案共 4+4+1+1+1+1 = 12 个字符，必须全部计入，避免上面因漏算而恒真。
    expect(charsPerRun.fold<int>(0, (int a, int b) => a + b), 12);
  });
}