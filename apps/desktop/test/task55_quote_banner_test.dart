// =============================================================================
// QuoteBanner 行为守卫（Task 55 · W55-E2）
// =============================================================================
// 守的是四条硬契约：
//  1. 中文态：中文行 + 英文行各一条，两行文本都取自**同一条**条目；
//  2. 英文态：只有英文行，中文行整行不存在（不是渲染成空串）；
//  3. 刷新必换：每次点击都换到**另一条**，不是「随机抽、可能还抽到自己」；
//  4. initialIndex 生效：给定下标的首帧就是那一条（测试与截图复现靠它）。
//
// 画布固定 1200×800 + dpr 1.0：两行各自判溢出，行宽变了
// `MarqueeLine` 会在静态/滚动分支之间翻面，断言就变成环境依赖了。
//
// 全程 `pump(...)`，**不用 `pumpAndSettle()`**：长行是 `repeat()` 滚动，
// 后者的语义是「等到没有待处理帧」，而滚动永远有下一帧 ⇒ 必然超时。
// =============================================================================

import 'package:actlog/src/data/quote.dart';
import 'package:actlog/src/data/quotes.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/widgets/marquee_line.dart';
import 'package:actlog/src/widgets/quote_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 中文行的 key（与 `quote_banner.dart` 里的一致）。
const Key _zhKey = Key('quote.zh');

/// 英文行的 key。
const Key _enKey = Key('quote.en');

/// 刷新钮的 key。
const Key _refreshKey = Key('quote.refresh');

/// 固定测试画布。
void _useFixedSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 读某一行真正拿到的文本；找不到或类型不符就当场失败，不静默兜底。
String _textOf(WidgetTester tester, Key key) =>
    tester.widget<MarqueeLine>(find.byKey(key)).text;

void main() {
  testWidgets('中文态：中英两行都在，文本取自同一条目', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await pumpL10n(tester, const QuoteBanner(initialIndex: 0));

    expect(find.byKey(_zhKey), findsOneWidget, reason: '中文态必须有中文行');
    expect(find.byKey(_enKey), findsOneWidget, reason: '中文态也要有英文行');

    final Quote first = kQuotes.first;
    expect(_textOf(tester, _zhKey), first.zh, reason: '中文行应取条目的 zh');
    expect(_textOf(tester, _enKey), first.en, reason: '英文行应取条目的 en');
    expect(tester.takeException(), isNull, reason: '首帧不应抛异常');
  });

  testWidgets('英文态：只有英文行，中文行不存在', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await pumpL10n(
      tester,
      const QuoteBanner(initialIndex: 0),
      language: AppLanguage.en,
    );

    expect(find.byKey(_enKey), findsOneWidget, reason: '英文态必须有英文行');
    expect(find.byKey(_zhKey), findsNothing, reason: '英文态不该出现中文行');
    expect(_textOf(tester, _enKey), kQuotes.first.en);
  });

  testWidgets('刷新钮每次点击都换到另一条', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await pumpL10n(tester, const QuoteBanner(initialIndex: 0));

    String previous = _textOf(tester, _enKey);
    expect(previous, kQuotes.first.en, reason: '首帧应是 initialIndex 指定的那条');

    // 连点 5 次：每次都必须换。全表 425 条英文无重复，所以比文本即可
    // 证明「换了条目」；若哪天数据出现重复，这里会红并暴露数据问题。
    for (int i = 1; i <= 5; i++) {
      await tester.tap(find.byKey(_refreshKey));
      // 换句是一次同步 setState，走一帧让新文本上屏；滚动动画不能用 pumpAndSettle。
      await tester.pump();

      final String next = _textOf(tester, _enKey);
      expect(
        next,
        isNot(previous),
        reason: '第 $i 次刷新必须换到另一条，实际仍是同一条',
      );
      previous = next;
    }
    expect(tester.takeException(), isNull, reason: '连点期间不应抛异常');
  });

  testWidgets('initialIndex 生效：指定最后一条就显示最后一条', (WidgetTester tester) async {
    _useFixedSurface(tester);
    await pumpL10n(tester, QuoteBanner(initialIndex: kQuotes.length - 1));

    expect(_textOf(tester, _enKey), kQuotes.last.en, reason: '英文行应为最后一条');
    expect(_textOf(tester, _zhKey), kQuotes.last.zh, reason: '中文行应为最后一条');
  });
}
