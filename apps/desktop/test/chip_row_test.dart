import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/chip_row.dart';

void main() {
  const options = <ChipOption>[
    ChipOption(key: 'a', label: '按时完成'),
    ChipOption(key: 'b', label: '延后完成'),
    ChipOption(key: 'c', label: '取消', deny: true),
  ];

  /// 取某枚芯片**自身**的 Material 底色（最近祖先 = 芯片自己的 Material）。
  Color chipFill(WidgetTester tester, String label) {
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );
    return material.color!;
  }

  /// 取某枚芯片**自身**的描边（最近祖先 Container 的 BoxDecoration.border）。
  Border chipBorder(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.border! as Border;
  }

  /// 取某枚芯片**自身**的圆角半径。
  double chipRadius(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  /// 取某枚芯片**自身**的文字色。
  Color chipTextColor(WidgetTester tester, String label) {
    final text = tester.widget<Text>(find.text(label));
    return text.style!.color!;
  }

  testWidgets('单选：点一枚芯片即回调该 key', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    await tester.tap(find.text('延后完成'));
    expect(captured, <String>{'b'});
  });

  testWidgets('多选：点未选项即新增，再点已选项即取消（可为空）', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            multi: true,
            selected: const <String>{'a'},
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );

    // 新增分支：点未选中的「延后完成」⇒ 已选集合并入 b。
    await tester.tap(find.text('延后完成'));
    expect(captured, <String>{'a', 'b'});

    // 取消分支：再点已选中的「按时完成」⇒ 取消它，剩 b。
    await tester.tap(find.text('按时完成'));
    expect(captured, isEmpty);
  });

  testWidgets('芯片可聚焦且 Space 能触发（精确命中首枚芯片）', (tester) async {
    Set<String>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            onChanged: (next) => captured = next,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(captured, <String>{'a'});
  });

  testWidgets('换色逐枚绑定：常态 paper 底 / hair-strong 边，选中 ink 洗底，拒绝类选中走赭石洗底', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChipRow(
            options: options,
            selected: const <String>{'b', 'c'},
            onChanged: (next) {},
          ),
        ),
      ),
    );

    // 常态芯片「按时完成」：paper 底 + hair-strong 边 + meta 字。
    expect(chipFill(tester, '按时完成'), AppTokens.paper);
    expect(chipBorder(tester, '按时完成').top.color, AppTokens.hairStrong);
    expect(chipTextColor(tester, '按时完成'), AppTokens.meta);

    // 选中态普通芯片「延后完成」：ink-wash 底 + ink 边 + ink 字（洗底，非反白）。
    expect(chipFill(tester, '延后完成'), AppTokens.inkWash);
    expect(chipBorder(tester, '延后完成').top.color, AppTokens.ink);
    expect(chipTextColor(tester, '延后完成'), AppTokens.ink);

    // 拒绝类芯片「取消」选中：accentWash 底 + accent 边 + accentInk 字。
    expect(chipFill(tester, '取消'), AppTokens.accentWash);
    expect(chipBorder(tester, '取消').top.color, AppTokens.accent);
    expect(chipTextColor(tester, '取消'), AppTokens.accentInk);

    // 圆角一律 4px（禁止大圆角）。
    expect(chipRadius(tester, '按时完成'), AppTokens.radius);
    expect(chipRadius(tester, '延后完成'), AppTokens.radius);
    expect(chipRadius(tester, '取消'), AppTokens.radius);
  });
}