// apps/desktop/test/chip_row_visual_test.dart
//
// 芯片条的视觉口径回归（裁定 A / `v2-ledger.html:227-236`）。
//
// Task 63 · W5 改造：定位从「中文 label 文本」改为**结构定位**（第 i 枚
// `InkWell`），并补一条英文期用例。理由有两条：
//   1. `label` 是调用方给的展示串，迁移后由 l10n 提供。拿 `find.text('中文')`
//      当定位器，等于把「视觉判据」和「某条文案」绑死 —— 改文案就误报，
//      而这条测试本来一个字的语义都不关心（§47.3 铁律 1）。
//   2. 结构定位还能顺带证一件事：视觉三态只由 `selected` / `deny` 决定，
//      与文案语种无关 —— 中英两套 label 下取值完全相同。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/chip_row.dart';

/// 中文夹具（迁移前的原始文案，逐字保留）。
const List<String> _labelsZh = <String>['按时完成', '延后完成', '取消'];

/// 英文夹具：只换展示串，`key` / `deny` 与中文夹具一一对应。
const List<String> _labelsEn = <String>['Done on time', 'Done later', 'Cancel'];

List<ChipOption> _options(List<String> labels) => <ChipOption>[
  ChipOption(key: 'done', label: labels[0]),
  ChipOption(key: 'later', label: labels[1]),
  ChipOption(key: 'cancel', label: labels[2], deny: true),
];

/// 第 [index] 枚芯片的 `InkWell`（结构定位，不依赖文案）。
Finder _chipAt(int index) => find
    .descendant(of: find.byType(Wrap), matching: find.byType(InkWell))
    .at(index);

/// 第 [index] 枚芯片的文案 `Text`。
Finder _textAt(int index) =>
    find.descendant(of: _chipAt(index), matching: find.byType(Text)).first;

Material _material(WidgetTester tester, int index) => tester.widget<Material>(
  find.ancestor(of: _textAt(index), matching: find.byType(Material)).first,
);

Container _box(WidgetTester tester, int index) => tester.widget<Container>(
  find.ancestor(of: _textAt(index), matching: find.byType(Container)).first,
);

TextStyle _style(WidgetTester tester, int index) =>
    tester.widget<Text>(_textAt(index)).style!;

Color _fill(WidgetTester tester, int index) => _material(tester, index).color!;

Border _border(WidgetTester tester, int index) =>
    (_box(tester, index).decoration! as BoxDecoration).border! as Border;

Future<void> _pump(
  WidgetTester tester, {
  List<String> labels = _labelsZh,
  Set<String> selected = const <String>{},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChipRow(
          options: _options(labels),
          selected: selected,
          onChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('常态芯片：paper 底 + hair-strong 边 + meta 字 + 26 高', (tester) async {
    await _pump(tester);

    // 先确认夹具确实渲染了 —— 否则下面的结构定位可能指向空树。
    expect(find.text(_labelsZh[0]), findsOneWidget);
    expect(find.text(_labelsZh[1]), findsOneWidget);
    expect(find.text(_labelsZh[2]), findsOneWidget);

    expect(_fill(tester, 0), ThemeTokens.light.paper);
    expect(_border(tester, 0).top.color, ThemeTokens.light.hairStrong);
    expect(_border(tester, 0).top.width, 1);
    expect(_style(tester, 0).color, ThemeTokens.light.meta);
    expect(_box(tester, 0).constraints!.minHeight, 26);
  });

  testWidgets('选中芯片：ink-wash 洗底 + ink 边 + ink 字 + 500 字重（不反白）', (tester) async {
    await _pump(tester, selected: const <String>{'later'});

    expect(_fill(tester, 1), ThemeTokens.light.inkWash);
    expect(_border(tester, 1).top.color, ThemeTokens.light.ink);
    expect(_style(tester, 1).color, ThemeTokens.light.ink);
    expect(_style(tester, 1).fontWeight, FontWeight.w500);
    // 反白是 `.btn.pri` / `.chk` / `.cell` 的专利，芯片不许用。
    expect(_fill(tester, 1), isNot(ThemeTokens.light.ink));
    expect(_style(tester, 1).color, isNot(ThemeTokens.light.paper));
  });

  testWidgets('拒绝类选中：accent-wash 底 + accent 边 + accent-ink 字', (tester) async {
    await _pump(tester, selected: const <String>{'cancel'});

    expect(_fill(tester, 2), ThemeTokens.light.accentWash);
    expect(_border(tester, 2).top.color, ThemeTokens.light.accent);
    expect(_style(tester, 2).color, ThemeTokens.light.accentInk);
  });

  testWidgets('hover 只提亮字色，不改底与边', (tester) async {
    await _pump(tester);
    expect(_style(tester, 0).color, ThemeTokens.light.meta);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(_chipAt(0)));
    await tester.pumpAndSettle();

    expect(_style(tester, 0).color, ThemeTokens.light.ink);
    expect(_fill(tester, 0), ThemeTokens.light.paper);
    expect(_border(tester, 0).top.color, ThemeTokens.light.hairStrong);
  });

  testWidgets('圆角一律 4px', (tester) async {
    await _pump(tester, selected: const <String>{'later'});

    for (var i = 0; i < _labelsZh.length; i++) {
      final radius = (_box(tester, i).decoration! as BoxDecoration)
          .borderRadius! as BorderRadius;
      expect(radius.topLeft.x, AppTokens.radius);
    }
  });

  testWidgets('英文期：视觉三态与文案语种无关', (tester) async {
    await _pump(
      tester,
      labels: _labelsEn,
      selected: const <String>{'later', 'cancel'},
    );

    // 英文夹具确实渲染了（中文一条都不该在）。
    expect(find.text('Done later'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text(_labelsZh[1]), findsNothing);

    // 同一套取值：常态 / 选中 / 拒绝类选中。
    expect(_fill(tester, 0), ThemeTokens.light.paper);
    expect(_style(tester, 0).color, ThemeTokens.light.meta);
    expect(_fill(tester, 1), ThemeTokens.light.inkWash);
    expect(_border(tester, 1).top.color, ThemeTokens.light.ink);
    expect(_style(tester, 1).fontWeight, FontWeight.w500);
    expect(_fill(tester, 2), ThemeTokens.light.accentWash);
    expect(_border(tester, 2).top.color, ThemeTokens.light.accent);
    expect(_style(tester, 2).color, ThemeTokens.light.accentInk);
    expect(_box(tester, 0).constraints!.minHeight, 26);
  });
}