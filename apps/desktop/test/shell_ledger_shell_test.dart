import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';
import 'package:actlog/src/widgets/shell/ledger_paper.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';
import 'package:actlog/src/widgets/shell/tool_rail.dart';

/// 基准视口 1440×900（裁定 F）；测试里逐个用例改尺寸。
Future<void> _pumpShell(
  WidgetTester tester,
  Size size, {
  List<ShellRailPanel> secondary = const <ShellRailPanel>[],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: LedgerShell(
        currentNavId: 'today',
        secondaryRailPanels: secondary,
        content: const Text('账页正文'),
      ),
    ),
  );
}

double _paperMaxWidth(WidgetTester tester) {
  return tester
      .widget<ConstrainedBox>(find.byKey(LedgerPaper.bodyKey))
      .constraints
      .maxWidth;
}

void main() {
  testWidgets('1440×900：导航 214 + 账页 770 + 右轨 290，底部无快捷键条', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester, const Size(1440, 900));

    expect(NavRail.width, 214);
    expect(ToolRail.railWidth, 290);
    expect(LedgerPaper.standardMaxWidth, 770);

    expect(tester.getSize(find.byKey(const Key('shell-nav'))).width, 214);
    expect(tester.getSize(find.byKey(const Key('shell-rail'))).width, 290);
    expect(_paperMaxWidth(tester), 770);
    // 1440 不到第三栏断点，第三栏不存在。
    expect(find.byKey(const Key('shell-rail2')), findsNothing);

    // Task 54 诉求③：纸面背景的浅灰规则横线已按用户要求移除，
    // 所以这里断言**不存在**规则线绘制器（旧实现是
    // `CustomPaint(painter: LedgerRulePainter)`，每 32 逻辑 px 一条）。
    // 用 runtimeType 名字匹配：该类已删除，直接写类型会编译不过。
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is CustomPaint &&
            widget.painter != null &&
            widget.painter!.runtimeType.toString().contains('LedgerRule'),
      ),
      findsNothing,
      reason: '账页纸面不允许再挂背景横线绘制器（Task 54 诉求③）',
    );
    expect(find.byType(Divider), findsNothing);

    // Task 56 诉求③：底部快捷键条已删除（`shell-keybar` 不再装配），
    // 账页直接铺到视口底边 —— 底下不再有第二行布局。
    expect(find.byKey(const Key('shell-keybar')), findsNothing);
    expect(find.byType(KeyBar), findsNothing);
    final Rect paper = tester.getRect(find.byKey(const Key('shell-ledger-paper')));
    expect(paper.bottom, 900);

    // 右轨默认注入真实「快捷键」面板，不是空栏。
    expect(find.text('快捷键'), findsOneWidget);
    expect(find.byType(KeyHintList), findsOneWidget);
    // 键帽只在右轨面板出现一次（底部那份已删）。
    expect(find.text('Ctrl+N'), findsOneWidget);
  });

  testWidgets('1920：账页放宽到 860，出现 286 第三栏', (WidgetTester tester) async {
    await _pumpShell(
      tester,
      const Size(1920, 900),
      secondary: const <ShellRailPanel>[
        ShellRailPanel(title: '闭环提示', child: Text('三条待闭环')),
      ],
    );

    expect(LedgerPaper.wideMaxWidth, 860);
    expect(ToolRail.rail2Width, 286);
    expect(_paperMaxWidth(tester), 860);
    expect(tester.getSize(find.byKey(const Key('shell-rail2'))).width, 286);
    expect(find.text('闭环提示'), findsOneWidget);
  });

  testWidgets('1200：导航折叠成顶栏、右轨落到账页下方、账页取消限宽', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester, const Size(1200, 900));

    final NavRail nav = tester.widget<NavRail>(find.byKey(const Key('shell-nav')));
    final ToolRail rail = tester.widget<ToolRail>(find.byKey(const Key('shell-rail')));
    expect(nav.horizontal, isTrue);
    expect(rail.stacked, isTrue);
    expect(tester.getSize(find.byKey(const Key('shell-nav'))).width, 1200);
    expect(_paperMaxWidth(tester), double.infinity);

    // 右轨在账页下方（同一滚动区），不再占右侧一列。
    final Rect railRect = tester.getRect(find.byKey(const Key('shell-rail')));
    final Rect navRect = tester.getRect(find.byKey(const Key('shell-nav')));
    expect(railRect.top, greaterThan(navRect.bottom));
    // 右轨落在账页的内边距里（原型 `.ledger{padding:16px 16px 22px}`），两侧各让 16px。
    expect(railRect.width, closeTo(1200 - 32, 0.5));
    expect(find.byKey(const Key('shell-rail2')), findsNothing);

    // 窄屏同样不装配底部快捷键条；右轨那份清单保留（落在账页下方的滚动区里）。
    expect(find.byType(KeyBar), findsNothing);
    expect(find.byType(KeyHintList), findsOneWidget);
  });

  testWidgets('断点常量与判定一致：1279 折叠、1280 不折叠、1919 三栏关闭', (
    WidgetTester tester,
  ) async {
    expect(LedgerShell.narrowBreakpoint, 1280);
    expect(LedgerShell.wideBreakpoint, 1920);

    await _pumpShell(tester, const Size(1279, 900));
    expect(
      tester.widget<NavRail>(find.byKey(const Key('shell-nav'))).horizontal,
      isTrue,
    );

    await _pumpShell(tester, const Size(1280, 900));
    expect(
      tester.widget<NavRail>(find.byKey(const Key('shell-nav'))).horizontal,
      isFalse,
    );
    expect(_paperMaxWidth(tester), 770);

    await _pumpShell(
      tester,
      const Size(1919, 900),
      secondary: const <ShellRailPanel>[
        ShellRailPanel(title: '闭环提示', child: Text('三条待闭环')),
      ],
    );
    expect(_paperMaxWidth(tester), 770);
    expect(find.byKey(const Key('shell-rail2')), findsNothing);
  });
}