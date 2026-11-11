import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';

/// 取出快捷键条的底板容器（靠 keybg 底色定位，避免依赖容器嵌套顺序）。
Finder _barBox() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).color == AppTokens.keybg,
);

/// 取出某枚键帽的外框容器（靠「下边 2px」定位）。
Finder _capBox(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate(
    (Widget widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration! as BoxDecoration).border is Border &&
        ((widget.decoration! as BoxDecoration).border! as Border).bottom.width ==
            2,
  ),
);

Future<void> _pumpKeyBar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: const Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 1200, child: KeyBar()),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('渲染 7 条真实快捷键，键帽与文案都成立', (WidgetTester tester) async {
    await _pumpKeyBar(tester);

    const List<String> keys = <String>[
      'Ctrl+N',
      'Ctrl+D',
      '←→',
      'Space',
      'Enter',
      'Esc',
      'Ctrl+1…3',
    ];
    for (final String key in keys) {
      expect(find.text(key), findsOneWidget, reason: '缺少键帽 $key');
    }
    for (final String label in <String>[
      '＋ 手写一条',
      '打卡第一条未打习惯',
      '切日期',
      '勾选 / 取消勾选',
      '展开回填',
      '关闭弹层',
      '切页',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '缺少说明 $label');
    }

    // 顺序：第一条是 Ctrl+N，最后一条是 Ctrl+1…3（Task 20 / K2）。
    final List<KeyCap> caps = tester.widgetList<KeyCap>(find.byType(KeyCap)).toList();
    expect(caps.length, 7);
    expect(caps.first.label, 'Ctrl+N');
    expect(caps.last.label, 'Ctrl+1…3');
    // Task 20：`Space` / `Enter` 已补上真实绑定，可以留在键条上；
    // 但原型那种「把这一行加进 / 拿出今日计划」的说法不许回来（K3 / A11）。
    expect(find.text('Space'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('排入 / 移出今日'), findsNothing);
    // A11：只宣称到 `Ctrl+1…3` —— 习惯 / 项目 / 设置三项无落点，
    // 键条渲染出 `Ctrl+1…6` 就是假提示。
    expect(find.text('Ctrl+1…6'), findsNothing);
    expect(find.text('Ctrl+1…3'), findsOneWidget);
  });

  testWidgets('快捷键条底板 = keybg + 上边 hair', (WidgetTester tester) async {
    await _pumpKeyBar(tester);

    expect(_barBox(), findsOneWidget);
    final Container bar = tester.widget<Container>(_barBox());
    final BoxDecoration decoration = bar.decoration! as BoxDecoration;
    final Border border = decoration.border! as Border;
    expect(border.top.color, AppTokens.hair);
    expect(border.top.width, 1);
    expect(border.bottom, BorderSide.none);
    // 原型 `.keybar{padding:7px 24px}`。
    expect(bar.padding, const EdgeInsets.symmetric(horizontal: 24, vertical: 7));
  });

  testWidgets('键帽 = mono 11.5 + tabular + 下边 2px + 3 圆角 + card 底', (WidgetTester tester) async {
    await _pumpKeyBar(tester);

    final Text text = tester.widget<Text>(find.text('Ctrl+N'));
    expect(text.style?.fontFamily, AppFonts.mono);
    expect(text.style?.fontSize, KeyCap.fontSize);
    expect(text.style?.fontSize, 11.5);
    expect(text.style?.color, AppTokens.ink);
    expect(
      text.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );

    final Container cap = tester.widget<Container>(_capBox('Ctrl+N'));
    final BoxDecoration decoration = cap.decoration! as BoxDecoration;
    expect(decoration.color, AppTokens.card);
    expect(decoration.borderRadius, BorderRadius.circular(3));
    final Border border = decoration.border! as Border;
    expect(border.bottom.width, 2);
    expect(border.top.width, 1);
    expect(border.top.color, AppTokens.hair);
    expect(cap.padding, const EdgeInsets.symmetric(horizontal: 5, vertical: 1));
  });

  testWidgets('右轨竖排清单复用同一份快捷键，无占位按钮', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 260, child: KeyHintList()),
          ),
        ),
      ),
    );

    for (final String key in <String>['Ctrl+N', 'Ctrl+D', 'Esc']) {
      expect(find.text(key), findsOneWidget);
    }
    expect(find.text('Space'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}