// apps/desktop/test/chip_row_visual_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/chip_row.dart';

const List<ChipOption> _options = <ChipOption>[
  ChipOption(key: 'done', label: '按时完成'),
  ChipOption(key: 'later', label: '延后完成'),
  ChipOption(key: 'cancel', label: '取消', deny: true),
];

Material _material(WidgetTester tester, String label) => tester.widget<Material>(
  find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
);

Container _box(WidgetTester tester, String label) => tester.widget<Container>(
  find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
);

TextStyle _style(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

Color _fill(WidgetTester tester, String label) =>
    _material(tester, label).color!;

Border _border(WidgetTester tester, String label) =>
    (_box(tester, label).decoration! as BoxDecoration).border! as Border;

Future<void> _pump(
  WidgetTester tester, {
  Set<String> selected = const <String>{},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChipRow(
          options: _options,
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

    expect(_fill(tester, '按时完成'), AppTokens.paper);
    expect(_border(tester, '按时完成').top.color, AppTokens.hairStrong);
    expect(_border(tester, '按时完成').top.width, 1);
    expect(_style(tester, '按时完成').color, AppTokens.meta);
    expect(_box(tester, '按时完成').constraints!.minHeight, 26);
  });

  testWidgets('选中芯片：ink-wash 洗底 + ink 边 + ink 字 + 500 字重（不反白）', (tester) async {
    await _pump(tester, selected: const <String>{'later'});

    expect(_fill(tester, '延后完成'), AppTokens.inkWash);
    expect(_border(tester, '延后完成').top.color, AppTokens.ink);
    expect(_style(tester, '延后完成').color, AppTokens.ink);
    expect(_style(tester, '延后完成').fontWeight, FontWeight.w500);
    // 反白是 `.btn.pri` / `.chk` / `.cell` 的专利，芯片不许用。
    expect(_fill(tester, '延后完成'), isNot(AppTokens.ink));
    expect(_style(tester, '延后完成').color, isNot(AppTokens.paper));
  });

  testWidgets('拒绝类选中：accent-wash 底 + accent 边 + accent-ink 字', (tester) async {
    await _pump(tester, selected: const <String>{'cancel'});

    expect(_fill(tester, '取消'), AppTokens.accentWash);
    expect(_border(tester, '取消').top.color, AppTokens.accent);
    expect(_style(tester, '取消').color, AppTokens.accentInk);
  });

  testWidgets('hover 只提亮字色，不改底与边', (tester) async {
    await _pump(tester);
    expect(_style(tester, '按时完成').color, AppTokens.meta);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('按时完成')));
    await tester.pumpAndSettle();

    expect(_style(tester, '按时完成').color, AppTokens.ink);
    expect(_fill(tester, '按时完成'), AppTokens.paper);
    expect(_border(tester, '按时完成').top.color, AppTokens.hairStrong);
  });

  testWidgets('圆角一律 4px', (tester) async {
    await _pump(tester, selected: const <String>{'later'});

    for (final label in <String>['按时完成', '延后完成', '取消']) {
      final radius = (_box(tester, label).decoration! as BoxDecoration)
          .borderRadius! as BorderRadius;
      expect(radius.topLeft.x, AppTokens.radius);
    }
  });
}