import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_gear_button.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';

/// 包一层最小宿主：只有真实高度，导航栏的 `Spacer` 才有界。
Future<void> _pumpNav(
  WidgetTester tester, {
  String? currentId,
  ValueChanged<String>? onSelected,
  bool horizontal = false,
}) async {
  // 测试默认视口只有 800 宽，横排模式要 1200 必须先把视口撑开。
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: horizontal ? 1200 : NavRail.width,
            height: 800,
            child: NavRail(
              currentId: currentId,
              onSelected: onSelected,
              horizontal: horizontal,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 按指定文字缩放挂竖排 `NavRail`。
///
/// `ACTLOG_TEXT_SCALE=2` 的等价物就是 `MediaQuery.textScaler` 变成
/// `TextScaler.linear(2)`（见 `lib/src/app.dart`）。注意 MediaQuery 必须放在
/// `MaterialApp` **内部**：`WidgetsApp` 会用 `MediaQuery.fromView` 覆盖顶层那份，
/// 套在外面不会生效。
Future<void> _pumpNavScaled(WidgetTester tester, {required double scale}) async {
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

/// 从主题取 `labelSmall` 的实际字号（不猜、不硬编码）。
double _labelSizeOf(WidgetTester tester, Finder anchor) =>
    Theme.of(tester.element(anchor)).textTheme.labelSmall?.fontSize ??
    DensityProfile.comfortable.labelSize;

void main() {
  testWidgets('竖排导航渲染 7 项与 01–07 序号', (WidgetTester tester) async {
    await _pumpNav(tester);

    expect(NavRail.width, 214);
    for (final String label in <String>['日志', '待办池', '习惯', '项目', '日历', '目标', '蓝图']) {
      expect(find.text(label), findsOneWidget, reason: '缺少导航项 $label');
    }
    for (final String index in <String>['01', '02', '03', '04', '05', '06', '07']) {
      expect(find.text(index), findsOneWidget, reason: '缺少序号 $index');
    }
    expect(find.text('知行日志'), findsOneWidget);
    expect(find.text('actlog'), findsOneWidget);
    // Task 72 / D-72-a：左栏底部常驻的快捷键底注已删除，竖排也不再出现。
    expect(find.text('页面切换'), findsNothing);
  });

  testWidgets('七项都可点：「项目」不再是禁用态（Task 56 起有真实落点）',
      (WidgetTester tester) async {
    final List<String> tapped = <String>[];
    await _pumpNav(tester, onSelected: tapped.add);

    // Task 56 起「项目」也启用 ⇒ 6 个可点项各一个 InkWell；
    // Task 64 起「设置」沉底成齿轮 ⇒ 再加 1 个 InkWell；
    // Task 72 起第 7 项「蓝图」落地 ⇒ 共 8 个可点元素。
    expect(find.byType(InkWell), findsNWidgets(8));

    await tester.tap(find.text('待办池'));
    await tester.pump();
    expect(tapped, <String>['inbox']);

    await tester.tap(find.text('习惯'));
    await tester.pump();
    expect(tapped, <String>['inbox', 'habits']);

    await tester.tap(find.text('日历'));
    await tester.pump();
    expect(tapped, <String>['inbox', 'habits', 'calendar']);

    // 设置页现在有真实落点（Task 39 指令 7）；Task 64 起「设置」不再是导航项，
    // 沉底成自绘齿轮，点击仍回调 `settings`。
    await tester.tap(find.byType(GoalGearButton));
    await tester.pump();
    expect(tapped, <String>['inbox', 'habits', 'calendar', 'settings']);

    // 项目页现在也有真实落点（Task 56）。
    await tester.tap(find.text('项目'));
    await tester.pump();
    expect(
      tapped,
      <String>['inbox', 'habits', 'calendar', 'settings', 'projects'],
      reason: '「项目」已启用，必须触发选中',
    );

    // 可点项（非当前页）走 meta 色，不再是禁用态的 faint。
    final Text projectsLabel = tester.widget<Text>(find.text('项目'));
    expect(projectsLabel.style?.color, ThemeTokens.light.meta);
    final Text habitsLabel = tester.widget<Text>(find.text('习惯'));
    expect(habitsLabel.style?.color, ThemeTokens.light.meta);
  });

  testWidgets('当前页 = ink 洗底 + ink 字 + 500 字重（不是反白）', (WidgetTester tester) async {
    await _pumpNav(tester, currentId: 'today');

    final Finder washed = find.byWidgetPredicate(
      (Widget widget) => widget is Material && widget.color == ThemeTokens.light.inkWash,
    );
    expect(washed, findsOneWidget, reason: '当前页必须且只能用 inkWash 洗底');
    expect(
      find.descendant(of: washed, matching: find.text('日志')),
      findsOneWidget,
    );

    final Text current = tester.widget<Text>(find.text('日志'));
    expect(current.style?.color, ThemeTokens.light.ink);
    expect(current.style?.fontWeight, FontWeight.w500);

    // 非当前页保持 meta 色。
    final Text other = tester.widget<Text>(find.text('日历'));
    expect(other.style?.color, ThemeTokens.light.meta);
  });

  testWidgets('横排模式：撑满宽度、隐藏底注与品牌副标', (WidgetTester tester) async {
    await _pumpNav(tester, horizontal: true);

    expect(tester.getSize(find.byType(NavRail)).width, 1200);
    expect(find.text('页面切换'), findsNothing);
    expect(find.text('actlog'), findsNothing);
    expect(find.text('日志'), findsOneWidget);
  });

  testWidgets('200% 下序号徽标单行不换行，盒子宽度按缩放后字号算', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 2);

    final Finder badge = find.text('01');
    final double labelSize = _labelSizeOf(tester, badge);
    final TextScaler scaler = MediaQuery.textScalerOf(tester.element(badge));

    // 先证明 200% 真的生效：否则「单行」可能只是因为根本没放大。
    expect(scaler.scale(labelSize), labelSize * 2);

    // 结构兜底：即使将来字号再变，也只横向溢出，不会碎成两行。
    final Text text = tester.widget<Text>(badge);
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);

    final Size size = tester.getSize(badge);
    // 修复前这里是 labelSize * 1.5（未缩放）⇒ 200% 下只有 18.75。
    expect(
      size.width,
      moreOrLessEquals(scaler.scale(labelSize) * 1.5, epsilon: 0.01),
    );
    // 单行高度 = 字号 × 1.3；两行会翻倍，1.6 倍容差仍能判出换行。
    expect(
      size.height,
      lessThanOrEqualTo(scaler.scale(labelSize) * 1.3 * 1.6),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('100% 下序号徽标几何零变化：宽度 = 缩放恒等 × labelSize × 1.5', (
    WidgetTester tester,
  ) async {
    await _pumpNavScaled(tester, scale: 1);

    final Finder badge = find.text('01');
    final double labelSize = _labelSizeOf(tester, badge);
    expect(labelSize, DensityProfile.comfortable.labelSize);

    final TextScaler scaler = MediaQuery.textScalerOf(tester.element(badge));
    // 100% 下缩放在数学上是恒等的 ⇒ 新写法的结果与修复前逐位相同。
    expect(scaler.scale(labelSize), labelSize);

    for (final String index in <String>['01', '02', '03', '04', '05', '06', '07']) {
      expect(
        tester.getSize(find.text(index)).width,
        moreOrLessEquals(labelSize * 1.5, epsilon: 0.0001),
        reason: '序号 $index 的盒子宽度变了（1.5 系数或字号被改动）',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
