// apps/desktop/test/nav_rail_footnote_test.dart
//
// 导航底注（`.nav-foot`）的回归测试 —— Task 20 · W2 裁定 N1–N6。
//
// 判据表（brief §4）：
// | 编号 | 断言 |
// |---|---|
// | N-1 | 底注文案含 `4`、不含 `6`（只宣称真实存在的 `Ctrl+1…4`） |
// | N-2 | 底注字符总数 == 12 |
// | N-3 | 100% 下零溢出（无 `RenderFlex overflowed` / 无黄黑条） |
// | N-4 | 200% 下排成 3 行，且第 3 行非空 |
// | N-5 | 200% 下每行字符数 ≥ 2（无孤字） |
// | N-6 | 200% 下底注不横向溢出导航栏宽度（`NavRail.width == 214`） |
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';

/// 按指定文字缩放挂竖排 `NavRail`。
///
/// `ACTLOG_TEXT_SCALE=2` 的等价物就是 `MediaQuery.textScaler` 变成
/// `TextScaler.linear(2)`（见 `lib/src/app.dart` 的 `resolveTextScale`）。
/// MediaQuery 必须放在 `MaterialApp` **内部**：`WidgetsApp` 会用
/// `MediaQuery.fromView` 覆盖顶层那份，套在外面不会生效。
Future<void> _pumpNavScaled(
  WidgetTester tester, {
  required double scale,
}) async {
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

/// 找到底注的外层 `Wrap`（直接子项里含 `Text('页面切换')` 的那个）。
///
/// 底注外层恒为 `Wrap`（Task 19 起就是这个结构），内层还有嵌套 `Wrap`，
/// 所以按「直接子项里有『页面切换』」定位，不靠顺序猜。
Element _footWrap(WidgetTester tester) {
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
      return candidate;
    }
  }
  throw StateError('底注外层 Wrap 未找到');
}

/// 底注里的所有 `Text`（按树序：文案顺序 = 渲染顺序）。
List<Text> _footTexts(Element foot) {
  final List<Text> texts = <Text>[];
  void visit(Element element) {
    final Widget widget = element.widget;
    if (widget is Text) {
      texts.add(widget);
    }
    element.visitChildren(visit);
  }

  visit(foot);
  return texts;
}

/// 把底注里的文本按纵向位置聚成「行」。
///
/// 同一行的文本纵向必然重叠；换行后下一行的顶部会落到上一行底部之下。
/// 返回每一行的文本（行内按左边缘排序，即视觉上的阅读顺序）。
List<List<Text>> _rowsOf(WidgetTester tester, Element foot) {
  final List<Text> texts = _footTexts(foot);
  final List<Rect> rects = <Rect>[
    for (final Text text in texts) tester.getRect(find.byWidget(text)),
  ];

  final List<int> order = List<int>.generate(rects.length, (int i) => i)
    ..sort((int a, int b) => rects[a].top.compareTo(rects[b].top));
  final List<List<int>> rowIndexes = <List<int>>[];
  double rowBottom = 0;
  for (final int i in order) {
    if (rowIndexes.isEmpty || rects[i].top >= rowBottom - 0.5) {
      rowIndexes.add(<int>[i]);
      rowBottom = rects[i].bottom;
    } else {
      rowIndexes.last.add(i);
      if (rects[i].bottom > rowBottom) {
        rowBottom = rects[i].bottom;
      }
    }
  }
  return rowIndexes.map((List<int> row) {
    final List<int> sorted = List<int>.of(row)
      ..sort((int a, int b) => rects[a].left.compareTo(rects[b].left));
    return <Text>[for (final int i in sorted) texts[i]];
  }).toList();
}

/// 一行的字符数（rune 计）。
int _charsOf(List<Text> row) => row.fold<int>(
  0,
  (int sum, Text text) => sum + (text.data ?? '').runes.length,
);

void main() {
  testWidgets('N-1 底注只宣称 Ctrl+1…4：含 4 不含 6', (WidgetTester tester) async {
    await _pumpNavScaled(tester, scale: 2);

    // 键帽：Ctrl / 1 / 4 在，6 不在。
    expect(find.widgetWithText(KeyCap, 'Ctrl'), findsOneWidget);
    expect(find.widgetWithText(KeyCap, '1'), findsOneWidget);
    expect(find.widgetWithText(KeyCap, '4'), findsOneWidget);
    expect(
      find.widgetWithText(KeyCap, '6'),
      findsNothing,
      reason: '导航只剩项目 / 设置两项禁用、无落点 ⇒ 底注不得宣称「… 6」',
    );

    // 文案顺序：页面切换 → Ctrl → + → 1 → … → 4。
    final List<Text> texts = _footTexts(_footWrap(tester));
    expect(
      texts.map((Text t) => t.data).toList(),
      <String>['页面切换', 'Ctrl', '+', '1', '…', '4'],
    );
  });

  testWidgets('N-2 底注字符总数 == 12', (WidgetTester tester) async {
    await _pumpNavScaled(tester, scale: 2);

    final List<Text> texts = _footTexts(_footWrap(tester));
    final String caption = texts.map((Text t) => t.data ?? '').join();
    expect(caption, '页面切换Ctrl+1…4');
    expect(caption.runes.length, 12);
  });

  testWidgets('N-3 100% 下底注零溢出（无 RenderFlex overflowed）', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 1);

    // 100% 是恒等缩放 ⇒ 底注仍是「一行 Wrap」结构（原型形态）。
    expect(find.widgetWithText(KeyCap, '4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('N-4 200% 下底注排成 3 行且第 3 行非空', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 2);

    // 先证明 200% 真的生效：否则「3 行」可能只是因为根本没放大。
    final Element anchor = tester.element(find.text('页面切换'));
    final TextScaler scaler = MediaQuery.textScalerOf(anchor);
    expect(scaler.scale(10), 20);

    final List<List<Text>> rows = _rowsOf(tester, _footWrap(tester));
    expect(rows, hasLength(3), reason: '200% 下底注应恰好 3 行，实测 ${rows.length}');
    // 第 3 行非空（不是「预留了行高但没内容」）。
    expect(_charsOf(rows[2]), greaterThan(0));
    // 行内容逐行钉死：第 1 行「页面切换」、第 2 行「Ctrl + 1」、第 3 行「… 4」。
    expect(
      rows.map((List<Text> row) => row.map((Text t) => t.data ?? '').join()).toList(),
      <String>['页面切换', 'Ctrl+1', '…4'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('N-5 200% 下每行字符数 ≥ 2（无孤字）', (WidgetTester tester) async {
    await _pumpNavScaled(tester, scale: 2);

    final List<List<Text>> rows = _rowsOf(tester, _footWrap(tester));
    expect(rows, hasLength(3));
    for (final List<Text> row in rows) {
      final int chars = _charsOf(row);
      expect(chars, greaterThanOrEqualTo(2), reason: '底注出现只含 $chars 个字符的孤立行');
    }
    // 合计必须等于 12，避免上面因漏算而恒真。
    expect(rows.fold<int>(0, (int sum, List<Text> row) => sum + _charsOf(row)), 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('N-6 200% 下底注不横向溢出导航栏宽度', (WidgetTester tester) async {
    await _pumpNavScaled(tester, scale: 2);

    expect(NavRail.width, 214);
    for (final Text text in _footTexts(_footWrap(tester))) {
      final Rect rect = tester.getRect(find.byWidget(text));
      expect(
        rect.right,
        lessThanOrEqualTo(NavRail.width),
        reason: '「${text.data}」右边缘越过了导航栏宽度',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
