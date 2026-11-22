// =============================================================================
// MarqueeLine 行为守卫（Task 55 · W55-E2）
// =============================================================================
// 守的是「一行文字怎么处理溢出」的四条硬契约：
//  1. 装得下 ⇒ 静态单副本：只有 staticTextKey 一个 Text，两个 animated key 为 0；
//  2. 装不下 ⇒ 滚动双副本：两个 animated key 各 1 个，static key 为 0；
//  3. disableAnimations（系统「减少动态效果」）⇒ 退回静态单副本；
//  4. 滚动期间位移逐帧向左推进（从右向左），且不抛异常。
//
// 为什么画布要固定：判宽用的是 `TextPainter` 实测宽度 vs 布局约束宽度，
// 画布尺寸变了容器宽度就可能跟着变，短句/长句的判定会翻面。这里写死
// 1200×800 + dpr 1.0，判宽只取决于测试自己给的 `SizedBox.width`。
//
// 全程 `pump(...)`，**不用 `pumpAndSettle()`**：滚动是 `repeat()`，
// 后者的语义是「等到没有待处理帧」，而滚动永远有下一帧 ⇒ 必然超时。
// =============================================================================

import 'package:actlog/src/data/quote.dart';
import 'package:actlog/src/data/quotes.dart';
import 'package:actlog/src/widgets/marquee_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定测试画布。
void _useFixedSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 全库最长的一条英文：从数据里算，避免写死字面量后与库漂移。
String _longestEnglishQuote() {
  String longest = '';
  for (final Quote quote in kQuotes) {
    if (quote.en.length > longest.length) {
      longest = quote.en;
    }
  }
  return longest;
}

/// 长句样本（约 190 字符）：宽 800 都装不下，200 更不可能。
final String _longText = _longestEnglishQuote();

/// 短句样本：28 个字符，宽 800 的容器一定装得下。
const String _shortText = 'Stay hungry. Stay foolish.';

/// 把被测行放进指定宽度的容器里；`maxWidth` 只由这一层 `SizedBox` 决定。
Widget _host(double width, String text) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: MarqueeLine(text: text)),
      ),
    ),
  );
}

void main() {
  testWidgets('短句装得下：静态单副本，不滚动', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await tester.pumpWidget(_host(800, _shortText));

    expect(
      find.byKey(MarqueeLine.staticTextKey),
      findsOneWidget,
      reason: '短句应只渲染一个居中静态 Text',
    );
    expect(find.byKey(MarqueeLine.animatedTextKeyA), findsNothing);
    expect(find.byKey(MarqueeLine.animatedTextKeyB), findsNothing);
  });

  testWidgets('长句装不下：滚动双副本，静态副本退场', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await tester.pumpWidget(_host(200, _longText));
    // 首帧只搭树；帧末才把「该滚」交给控制器，再走一帧让分支稳定。
    await tester.pump();

    expect(
      find.byKey(MarqueeLine.animatedTextKeyA),
      findsOneWidget,
      reason: '长句在窄容器里必须有第一份滚动副本',
    );
    expect(
      find.byKey(MarqueeLine.animatedTextKeyB),
      findsOneWidget,
      reason: '长句在窄容器里必须有第二份滚动副本（无缝回卷）',
    );
    expect(
      find.byKey(MarqueeLine.staticTextKey),
      findsNothing,
      reason: '滚动分支不应同时渲染静态单副本',
    );
  });

  testWidgets('disableAnimations：长句也退回静态单副本', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              // 只翻 disableAnimations 一位，size / textScaler / direction 全部沿用外层，
              // 否则「退回静态」可能只是被空 MediaQuery 意外触发的。
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: MarqueeLine(text: _longText),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(MarqueeLine.staticTextKey),
      findsOneWidget,
      reason: '系统「减少动态效果」下长句也走静态分支',
    );
    expect(find.byKey(MarqueeLine.animatedTextKeyA), findsNothing);
    expect(find.byKey(MarqueeLine.animatedTextKeyB), findsNothing);
  });

  testWidgets('滚动位移随时间向左推进（从右向左）', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await tester.pumpWidget(_host(200, _longText));

    // 首帧只搭树；控制器在帧末起步，因此再走一帧让 ticker 拿到起点
    // （repeat 的第一个 tick elapsed 恒为 0，先消耗掉它再记初值）。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final Finder copyA = find.byKey(MarqueeLine.animatedTextKeyA);
    expect(copyA, findsOneWidget, reason: '长句在窄容器里必须走滚动分支');

    final double x0 = tester.getTopLeft(copyA).dx;
    await tester.pump(const Duration(milliseconds: 500));
    final double x1 = tester.getTopLeft(copyA).dx;

    expect(tester.takeException(), isNull, reason: '滚动期间不应抛异常');
    expect(x1, lessThan(x0), reason: '位移应向左推进：x0=$x0，x1=$x1');
  });
}
