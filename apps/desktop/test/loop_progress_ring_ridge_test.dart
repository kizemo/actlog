// apps/desktop/test/loop_progress_ring_ridge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/core_data.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/loop_progress_ring.dart';

const DayStats _allDone = DayStats(
  planTotal: 8,
  planDone: 8,
  backfilled: 8,
  reviewDone: true,
  moodDone: true,
);

const DayStats _hasGap = DayStats(
  planTotal: 8,
  planDone: 6,
  backfilled: 4,
  reviewDone: false,
  moodDone: false,
);

Finder _byColor(Color color) => find.byWidgetPredicate(
  (widget) => widget is Container && widget.color == color,
);

Future<void> _pump(
  WidgetTester tester,
  DayStats stats, {
  void Function(DayStatsSegment segment)? onJump,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LoopProgressRing(stats: stats, onJump: onJump),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('贯穿全宽一条：paper 底 + 底部 hair 线，不再是卡片', (tester) async {
    await _pump(tester, _allDone);

    final outer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(LoopProgressRing),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = outer.decoration! as BoxDecoration;
    final border = decoration.border! as Border;

    expect(decoration.color, AppTokens.paper);
    expect(border.bottom.color, AppTokens.hair);
    expect(border.bottom.width, 1);
    // 不再有整圈卡片边（top 只能是 BorderSide.none）。
    expect(border.top.width, 0);
    expect(outer.margin, isNull);
  });

  testWidgets('四段标签 + 每段 0/25/50/75/100 刻度 + 段头说明', (tester) async {
    await _pump(tester, _allDone);

    expect(find.text('闭环环 · 四段比例条'), findsOneWidget);
    expect(find.text('刻度 0—100'), findsOneWidget);
    for (final label in <String>['计划', '回填', '复盘', '心态']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final tick in <String>['0', '25', '50', '75', '100']) {
      expect(find.text(tick), findsNWidgets(4));
    }
    // 每段一条 5px 比例条。
    final tracks = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxHeight == 5,
    );
    expect(tracks, findsNWidgets(4));
  });

  testWidgets('无缺口：比例条一律 ink-2，无赭石', (tester) async {
    await _pump(tester, _allDone);

    expect(_byColor(AppTokens.ink2), findsNWidgets(4));
    expect(_byColor(AppTokens.accent), findsNothing);
    expect(find.text('8/8'), findsNWidgets(2));
  });

  testWidgets('有缺口：比例条改赭石，缺口段文字走 accent-ink', (tester) async {
    await _pump(tester, _hasGap);

    expect(_byColor(AppTokens.accent), findsNWidgets(4));
    expect(_byColor(AppTokens.ink2), findsNothing);
    expect(find.text('6/8'), findsOneWidget);
    expect(find.text('4/6'), findsOneWidget);

    // 缺口段的标签与数值都用赭石文字版。
    expect(
      tester.widget<Text>(find.text('复盘')).style!.color,
      AppTokens.accentInk,
    );
    expect(
      tester.widget<Text>(find.text('6/8')).style!.color,
      AppTokens.accentInk,
    );
  });

  testWidgets('数值是 mono + tabular-nums', (tester) async {
    await _pump(tester, _hasGap);

    final style = tester.widget<Text>(find.text('6/8')).style!;
    expect(style.fontFamily, AppFonts.mono);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('点段标签回调对应段', (tester) async {
    final jumped = <DayStatsSegment>[];
    await _pump(tester, _hasGap, onJump: jumped.add);

    await tester.tap(find.text('复盘'));
    await tester.pump();
    await tester.tap(find.text('心态'));
    await tester.pump();

    expect(jumped, <DayStatsSegment>[
      DayStatsSegment.review,
      DayStatsSegment.mood,
    ]);
  });
}