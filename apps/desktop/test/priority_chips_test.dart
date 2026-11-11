import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/priority_chips.dart';

/// 旧绿：Task 3 换掉主题层后仍残留在象限色板里，本任务要求它不再上屏。
const Color kOldGreen = Color(0xFF2E8B57);

void main() {
  /// 取某个象限格**自身**的 Material 底色（最近祖先 = 该格自己的 Material）。
  Color cellFill(WidgetTester tester, String shortLabel) {
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text(shortLabel), matching: find.byType(Material))
          .first,
    );
    return material.color!;
  }

  /// 取某个象限格**自身**的描边（最近祖先 Container 的 BoxDecoration.border）。
  Border cellBorder(WidgetTester tester, String shortLabel) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(shortLabel), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.border! as Border;
  }

  /// 取某个象限格**自身**的圆角半径。
  double cellRadius(WidgetTester tester, String shortLabel) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(shortLabel), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  /// 取某个象限格**自身**的短标签文字色。
  Color cellTitleColor(WidgetTester tester, String shortLabel) {
    final text = tester.widget<Text>(find.text(shortLabel));
    return text.style!.color!;
  }

  /// 取某个象限格**自身**的 Semantics 选中标记（`selected` 非 null 的那一个）。
  Semantics cellSemantics(WidgetTester tester, String shortLabel) {
    final list = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text(shortLabel),
            matching: find.byType(Semantics),
          ),
        )
        .where((s) => s.properties.selected != null)
        .toList();
    expect(list.length, 1);
    return list.single;
  }

  testWidgets('四象限：逐格绑定常态/选中态的底色、描边、圆角与选中语义', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final styles = QuadrantStyle.all.values.toList();
    expect(styles.length, 4);

    final pending = QuadrantPickerDialog.show(
      ctx,
      selected: styles.first.quadrant,
      mode: PriorityDisplayMode.quadrant,
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < styles.length; i++) {
      final style = styles[i];
      final isSelected = i == 0;

      // 每格的短标签必须唯一可定位（否则绑定断言会张冠李戴）。
      expect(find.text(style.shortLabel), findsOneWidget);

      expect(
        cellFill(tester, style.shortLabel),
        isSelected ? AppTokens.ink : AppTokens.card,
      );
      expect(
        cellBorder(tester, style.shortLabel).top.color,
        isSelected ? AppTokens.ink : AppTokens.hairStrong,
      );
      expect(
        cellTitleColor(tester, style.shortLabel),
        isSelected ? AppTokens.paper : AppTokens.ink,
      );
      // 圆角一律 4px（禁止大圆角）。
      expect(cellRadius(tester, style.shortLabel), AppTokens.radius);
      // 形状 + 文字双通道：选中态必须进 Semantics。
      final semantics = cellSemantics(tester, style.shortLabel);
      expect(semantics.properties.selected, isSelected);
      expect(semantics.properties.button, isTrue);
    }

    // 全局兜底：旧绿不得上屏。
    final borders = <Color>[];
    final fills = <Color>[];
    for (final c in tester.widgetList<Container>(find.byType(Container))) {
      final d = c.decoration;
      if (d is BoxDecoration) {
        final b = d.border;
        if (b is Border) {
          borders.add(b.top.color);
        }
      }
    }
    for (final m in tester.widgetList<Material>(find.byType(Material))) {
      final col = m.color;
      if (col != null) {
        fills.add(col);
      }
    }
    expect(borders, isNot(contains(kOldGreen)));
    expect(fills, isNot(contains(kOldGreen)));

    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();
    await pending;
  });

  testWidgets('优先级标签：逐枚绑定 card 底 / hair-strong 边 / 4px 圆角 / meta 文字与图标', (tester) async {
    final quadrant = QuadrantStyle.all.values.first.quadrant;
    final label = PriorityDisplay.labelFor(
      PriorityDisplayMode.quadrant,
      quadrant: quadrant,
      priorityAbc: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriorityTagChip(
            mode: PriorityDisplayMode.quadrant,
            quadrant: quadrant,
            priorityAbc: null,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text(label), findsOneWidget);

    final material = tester.widget<Material>(
      find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
    );
    expect(material.color, AppTokens.card);
    expect(material.borderRadius, BorderRadius.circular(AppTokens.radius));

    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect((decoration.borderRadius! as BorderRadius).topLeft.x, AppTokens.radius);
    expect((decoration.border! as Border).top.color, AppTokens.hairStrong);

    final text = tester.widget<Text>(find.text(label));
    expect(text.style!.color, AppTokens.meta);

    final iconColors =
        tester.widgetList<Icon>(find.byType(Icon)).map((i) => i.color).toList();
    expect(iconColors, contains(AppTokens.meta));
    expect(iconColors, isNot(contains(kOldGreen)));
  });
}