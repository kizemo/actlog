// =============================================================================
// Task 64 · 左栏「设置」齿轮化 + 新增「目标」导航项（Ctrl+6）
// =============================================================================
// 本文件锁住 Task 64 的三条口径：
//  1. 左栏项数与末项：第 6 项由「设置」换成「目标」（Task 64），第 7 项「蓝图」（Task 72）；
//  2. 「设置」沉底成**自绘齿轮**（零 Material 图标），点击仍回调 `settings`；
//  3. 快捷键清单新增第 9 条 `Ctrl+6` ⇒ 切到目标。
//
// l10n 纪律：中英双态各断言一次，断言文案取自 [AppLocalizations] 常量，
// 不写死中文字面量，也不写「find.text('目标')」这种同义反复。
// =============================================================================

import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_gear_button.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 包一层最小宿主：只有真实高度，导航栏的 `Spacer` 才有界。
Future<void> _pumpNav(
  WidgetTester tester, {
  ValueChanged<String>? onSelected,
  AppLanguage language = AppLanguage.zh,
  bool horizontal = false,
}) async {
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: horizontal ? 1200 : NavRail.width,
              height: 800,
              child: NavRail(
                onSelected: onSelected,
                horizontal: horizontal,
              ),
            ),
          ),
        ),
        language: language,
      ),
    ),
  );
}

void main() {
  testWidgets('左栏 7 项：第 6 项「目标」、第 7 项「蓝图」，「设置」不再是导航项',
      (WidgetTester tester) async {
    await _pumpNav(tester);

    expect(kShellNavItems.length, 7, reason: '左栏总项数 7（Task 72 起加「蓝图」）');
    expect(kShellNavItems.last.id, 'blueprint');
    // 常量清单是「中文快照」，必须与 l10n 的中文取值逐字一致。
    expect(kShellNavItems.last.label, AppLocalizations.zh.shellNavBlueprint);

    final AppLocalizations zh = AppLocalizations.zh;
    final List<ShellNavItem> items = shellNavItemsFor(zh);
    expect(items.length, 7);
    expect(items.last.id, 'blueprint');
    expect(items.last.label, zh.shellNavBlueprint);

    // 界面上有「目标」这一行，没有「设置」这一行（设置沉底成齿轮了）。
    expect(find.text(zh.shellNavGoals), findsOneWidget);
    expect(find.text(zh.shellNavSettings), findsNothing);
  });

  testWidgets('英文态：导航项是 Goals，「设置」中文串不出现',
      (WidgetTester tester) async {
    await _pumpNav(tester, language: AppLanguage.en);

    final AppLocalizations en = AppLocalizations.en;
    expect(find.text(en.shellNavGoals), findsOneWidget);
    expect(find.text(AppLocalizations.zh.shellNavGoals), findsNothing);
    expect(find.text(AppLocalizations.zh.shellNavSettings), findsNothing);
  });

  testWidgets('「设置」沉底成自绘齿轮：tooltip 是设置文案，点击回调 settings',
      (WidgetTester tester) async {
    final List<String> tapped = <String>[];
    await _pumpNav(tester, onSelected: tapped.add);

    // 齿轮是自绘的（零 Material 图标）：靠类型找，不靠图标。
    expect(find.byType(GoalGearButton), findsOneWidget);
    expect(find.byTooltip(AppLocalizations.zh.shellNavSettings), findsOneWidget);

    await tester.tap(find.byType(GoalGearButton));
    await tester.pump();
    expect(tapped, <String>['settings']);

    // 命中区 ≥ 24×24（图标 16px + 命中盒 28px）。
    expect(
      tester.getSize(find.byType(GoalGearButton)).width,
      greaterThanOrEqualTo(24),
    );
    expect(
      tester.getSize(find.byType(GoalGearButton)).height,
      greaterThanOrEqualTo(24),
    );
  });

  testWidgets('左栏可点元素 = 7 个导航项 + 1 枚齿轮',
      (WidgetTester tester) async {
    await _pumpNav(tester);

    // 导航项 7 个 InkWell + 齿轮 1 个 InkWell。
    expect(find.byType(InkWell), findsNWidgets(8));
  });

  testWidgets('横排模式：齿轮挂在行末（导航项右侧），点击同样回调 settings',
      (WidgetTester tester) async {
    final List<String> tapped = <String>[];
    await _pumpNav(tester, onSelected: tapped.add, horizontal: true);

    expect(find.byType(GoalGearButton), findsOneWidget);
    final double gearRight = tester.getTopRight(find.byType(GoalGearButton)).dx;
    final double lastItemRight = tester.getTopRight(
      find.text(AppLocalizations.zh.shellNavBlueprint),
    ).dx;
    expect(gearRight, greaterThan(lastItemRight));

    // 横排形态也必须能进 `/settings`（竖排形态的同款断言见上一条用例）。
    await tester.tap(find.byType(GoalGearButton));
    await tester.pump();
    expect(tapped, <String>['settings']);
  });

  testWidgets('英文态：齿轮 tooltip 随语言切，不串中文串',
      (WidgetTester tester) async {
    await _pumpNav(tester, language: AppLanguage.en);

    expect(find.byType(GoalGearButton), findsOneWidget);
    expect(
      find.byTooltip(AppLocalizations.en.shellNavSettings),
      findsOneWidget,
      reason: '英文态 tooltip 必须取英文文案',
    );
    expect(
      find.byTooltip(AppLocalizations.zh.shellNavSettings),
      findsNothing,
      reason: '英文态不得残留中文 tooltip',
    );
  });

  testWidgets('快捷键清单新增第 9 条：Ctrl+6 ⇒ 切到目标', (WidgetTester tester) async {
    expect(kShellKeyHints.length, 9);
    expect(kShellKeyHints.last.keys, <String>['Ctrl+6']);
    expect(kShellKeyHints.last.label, AppLocalizations.zh.shellKeyGoGoals);

    final AppLocalizations en = AppLocalizations.en;
    final List<ShellKeyHint> hints = shellKeyHintsFor(en);
    expect(hints.length, 9);
    expect(hints.last.keys, <String>['Ctrl+6']);
    expect(hints.last.label, en.shellKeyGoGoals);
    expect(hints.last.label, isNot(AppLocalizations.zh.shellKeyGoGoals));
  });
}
