// apps/desktop/test/day_timeline_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/day_timeline.dart';

Widget _host(double width, Widget child) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: Scaffold(body: SizedBox(width: width, child: child)),
      ),
    );

const DayTimeline _threeSections = DayTimeline(
  sections: [
    TimelineSection(label: '晨 · 定计划', child: SizedBox(height: 30)),
    TimelineSection(label: '午 · 执行与打卡', child: SizedBox(height: 30)),
    TimelineSection(label: '晚 · 复盘与心态', child: SizedBox(height: 30)),
  ],
);

void main() {
  testWidgets('三段全部渲染、无折叠分支，段间各一个 gapSec（骨架铁律 + 遗留②）', (tester) async {
    await tester.pumpWidget(_host(1400, _threeSections));
    expect(find.text('晨 · 定计划'), findsOneWidget);
    expect(find.text('午 · 执行与打卡'), findsOneWidget);
    expect(find.text('晚 · 复盘与心态'), findsOneWidget);
    // 三段之间各插一个 gapSec=22 的间距：i > 0 才插 ⇒ 恰好 2 个
    expect(
      find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.height == AppTokens.gapSec),
      findsNWidgets(2),
    );
  });

  test('节点形状与赭石纪律：圆点，且只有缺口态允许赭石（TOKENS.md:300/328）', () {
    final closed = tlNodeDecoration(hasGap: false);
    final gap = tlNodeDecoration(hasGap: true);
    expect(closed.shape, BoxShape.circle);
    expect(closed.color, Colors.transparent);
    expect(closed.border!.top.color, AppTokens.hairStrong);
    expect(gap.shape, BoxShape.circle);
    expect(gap.color, AppTokens.accent);
    expect(gap.border!.top.color, AppTokens.accent);
    // 反例：非缺口态的底色与描边都不得是赭石（§7:306-307 禁装饰性赭石色块）
    expect(closed.color, isNot(AppTokens.accent));
    expect(closed.border!.top.color, isNot(AppTokens.accent));
  });

  test('节点双通道：文字与形状同时存在（TOKENS.md:254-255）', () {
    expect(tlNodeLabel(hasGap: false, gapLabel: null), '✓ 已闭合');
    expect(tlNodeLabel(hasGap: true, gapLabel: null), '▸ 有缺口');
    expect(tlNodeLabel(hasGap: true, gapLabel: '缺晚间复盘'), '缺晚间复盘');
    expect(tlNodeTextColor(hasGap: false), AppTokens.meta);
    expect(tlNodeTextColor(hasGap: true), AppTokens.accentInk);
  });

  test('窄断点纯函数：1280 为界（TOKENS.md:238-239）', () {
    expect(tlWidthFor(1280), AppTokens.tlWidth);
    expect(tlGapFor(1280), AppTokens.tlGap);
    expect(tlWidthFor(1279.9), AppTokens.tlWidthNarrow);
    expect(tlGapFor(1279.9), AppTokens.tlGapNarrow);
    expect(tlNarrowBreakpoint, 1280);
  });

  testWidgets('节点 10×10 与 ≥12px 文字共存；窄视口左栏 52+10 贯通（§2.2 硬底线）', (tester) async {
    Widget one(double w) => _host(
          w,
          DayTimeline(
            sections: [
              TimelineSection(
                label: '晨 · 定计划',
                child: const SizedBox(
                  key: ValueKey<String>('probe'),
                  width: 20,
                  height: 30,
                ),
              ),
            ],
          ),
        );
    await tester.pumpWidget(one(1400));
    expect(tester.getSize(find.byKey(const ValueKey<String>('tl-node'))),
        const Size(10, 10));
    expect(
        tester.widget<Text>(find.text('晨 · 定计划')).style?.fontSize, greaterThanOrEqualTo(12));
    expect(tester.getTopLeft(find.byKey(const ValueKey<String>('probe'))).dx,
        AppTokens.tlWidth + AppTokens.tlGap);
    await tester.pumpWidget(one(600));
    expect(tester.getTopLeft(find.byKey(const ValueKey<String>('probe'))).dx,
        AppTokens.tlWidthNarrow + AppTokens.tlGapNarrow);
  });
}