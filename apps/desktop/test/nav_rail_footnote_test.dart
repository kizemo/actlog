// apps/desktop/test/nav_rail_footnote_test.dart
//
// 左栏底部「导航底注」的**删除守护**测试 —— Task 72 · 裁决 D-72-a。
//
// 历史：Task 20 · W2 用 N-1…N-6 守过这条常驻文案（「页面切换 Ctrl + 1 … 6」）。
// Task 72 把它整段删掉（快捷键说明只留在窄屏 `KeyBar` 与宽屏右轨 `KeyHintList`，
// `Ctrl+1…7` 功能不变），所以本文件的口径从「守它在」反转为「守它不在」。
//
// 判据表：
// | 编号 | 断言 |
// |---|---|
// | F-1 | 100% 下左栏里没有任何 `KeyCap`、没有「页面切换」文本、零异常 |
// | F-2 | 200% 下同样零底注、零异常（放大不会把删掉的东西「放出来」） |
// | F-3 | 竖排导航渲染 7 项，序号 `01`–`07` 齐（B17 起末项「日历」的序号是 `07`；B16 的 `08` 必须消失） |
// | F-4 | 200% 下左栏内所有文本右边缘不越过导航栏宽度（`NavRail.width == 214`） |
// | F-5 | 底注三段残留文案（「Ctrl」「…」等键帽文字）在整棵左栏树里都找不到 |
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

/// 左栏里的所有 `Text`（按树序）。
List<Text> _navTexts(WidgetTester tester) {
  final List<Text> texts = <Text>[];
  for (final Element element
      in find
          .descendant(of: find.byType(NavRail), matching: find.byType(Text))
          .evaluate()) {
    final Widget widget = element.widget;
    if (widget is Text) {
      texts.add(widget);
    }
  }
  return texts;
}

void main() {
  testWidgets('F-1 100% 下左栏没有任何快捷键底注', (WidgetTester tester) async {
    await _pumpNavScaled(tester, scale: 1);

    // 键帽（`KeyCap`）是底注的构件；底注删掉后左栏里一枚都不该剩。
    expect(
      find.byType(KeyCap),
      findsNothing,
      reason: 'D-72-a 已删除左栏底注，左栏内不得再出现键帽',
    );
    expect(find.text('页面切换'), findsNothing);
    expect(find.text('Page switch'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F-2 200% 下同样零底注、零溢出', (WidgetTester tester) async {
    await _pumpNavScaled(tester, scale: 2);

    // 先证明 200% 真的生效（否则「没有溢出」可能只是因为没放大）。
    final Element anchor = tester.element(find.text('日志'));
    expect(MediaQuery.textScalerOf(anchor).scale(10), 20);

    expect(find.byType(KeyCap), findsNothing);
    expect(find.text('页面切换'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F-3 竖排导航渲染 7 项，序号 01–07 齐', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 1);

    for (final String label in <String>[
      '日志',
      '待办池',
      '蓝图',
      '目标',
      '项目',
      '学习管理',
      '日历',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '缺少导航项 $label');
    }
    for (int i = 1; i <= 7; i++) {
      expect(
        find.text(i.toString().padLeft(2, '0')),
        findsOneWidget,
        reason: '缺少序号 ${i.toString().padLeft(2, '0')}',
      );
    }
    expect(
      find.text('08'),
      findsNothing,
      reason: 'B17 起左导航为 7 项，序号只到 07（B16 的 08 必须消失）',
    );
  });

  testWidgets('F-4 200% 下左栏文本不横向溢出导航栏宽度', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 2);

    expect(NavRail.width, 214);
    for (final Text text in _navTexts(tester)) {
      final Rect rect = tester.getRect(find.byWidget(text));
      expect(
        rect.right,
        lessThanOrEqualTo(NavRail.width),
        reason: '「${text.data}」右边缘越过了导航栏宽度',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('F-5 底注残留文案（Ctrl / + / …）在左栏里全部找不到', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 1);

    for (final String remnant in <String>['Ctrl', '+', '…', '页面切换']) {
      expect(
        find.text(remnant),
        findsNothing,
        reason: 'D-72-a 删除后左栏不应残留底注片段「$remnant」',
      );
    }
  });
}