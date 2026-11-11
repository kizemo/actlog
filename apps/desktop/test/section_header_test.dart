import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/section_header.dart';

void main() {
  /// 找出带 `--accent` 2px 描边的容器（缺项高亮）。
  List<Container> gapContainers(WidgetTester tester) {
    return tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final decoration = c.decoration;
          if (decoration is! BoxDecoration) {
            return false;
          }
          final border = decoration.border;
          if (border is! Border) {
            return false;
          }
          return border.top.color == AppTokens.accent && border.top.width == 2;
        })
        .toList();
  }

  testWidgets('无缺项：标题 + 完成徽章上屏，不渲染赭石描边', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(title: '今日待办', done: 3, total: 5),
        ),
      ),
    );

    expect(find.text('今日待办'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(gapContainers(tester), isEmpty);
  });

  testWidgets('有缺项：整行 2px 赭石描边 + 提示文案走 accent-ink', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: '今日待办',
            done: 3,
            total: 5,
            hasGap: true,
            gapHint: '还差 2 项',
          ),
        ),
      ),
    );

    expect(find.text('还差 2 项'), findsOneWidget);
    final hint = tester.widget<Text>(find.text('还差 2 项'));
    expect(hint.style!.color, AppTokens.accentInk);

    final gaps = gapContainers(tester);
    expect(gaps.length, 1);
    final decoration = gaps.single.decoration! as BoxDecoration;
    expect((decoration.borderRadius! as BorderRadius).topLeft.x, AppTokens.radius);

    // 徽章仍在上屏。
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('有缺项但无提示文案：不渲染 accent-ink 提示文本，描边仍在', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(title: '今日待办', hasGap: true),
        ),
      ),
    );

    expect(gapContainers(tester).length, 1);

    final accentTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.color == AppTokens.accentInk)
        .toList();
    expect(accentTexts, isEmpty);
  });
}