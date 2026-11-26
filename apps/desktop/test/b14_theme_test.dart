// =============================================================================
// B14 · 条目 3（选中态可辨）+ 条目 4（三套配色）判别性用例
// =============================================================================
// 判据（对应 docs\b14-dispatch.md §3 / §4）：
//  T3-1 活动标签底色 = `inkWash`，且**不再**等于内容区底色（`card` / `paper`）
//       —— 修复前活动底色就是 `tokens.card`，与表格融为一体；
//  T3-2 活动标签顶部 3px 实色条存在且为 `tokens.ink`；
//  T3-3 活动标签文字字重**严格大于**非活动标签；
//  T4-1 三套 accent 的纸面（paper）两两不同；
//  T4-2 `ink` 档与历史常量为同一实例（逐字节不变）；
//  T4-3 浅色档 `ink`/`paper` ≥ 7:1、`meta`/`paper` ≥ 4.5:1（WCAG 现算）；
//  T4-6 标签文字 × 活动标签底色（`inkWash`）与标签条底（`paper`）≥ 4.5:1
//       —— 浅色态 / 深色态各一组（D7）；
//  T4-4 `DensityProfile × AppAccent × light/dark` 全组合可构建，
//       且 `scaffoldBackgroundColor` 逐字节等于该档 `paper`；
//  T4-5 偏好 encode/parse 往返、未知值回落 `ink`、默认档 = `ink`。
//
// 口径：对比度现算，不抄设计稿；颜色一律取 `ThemeTokens`，不写字面量。
// =============================================================================

import 'dart:math' as math;

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/theme/theme_tokens.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_domain/core_domain.dart'
    show GoalHorizon, GoalKind, GoalStatus;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 相对亮度（WCAG 2.x 定义；`Color.r/g/b` 已是 0..1 的 sRGB 分量）。
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// 对比度（1..21；与前景/背景顺序无关）。
double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// 一个 `Container` 实际画出的底色（`color` 或 `BoxDecoration.color`）。
Color? _containerColor(Container container) {
  if (container.color != null) {
    return container.color;
  }
  final Decoration? decoration = container.decoration;
  return decoration is BoxDecoration ? decoration.color : null;
}

/// 目标控件**自身或后代**是否有某一层刷成了 [color]。
///
/// 标签底色可能落在 `TextButton.styleFrom(backgroundColor:)` 产生的
/// `Material`，也可能落在 `Container` / `ColoredBox` / `DecoratedBox` 上；
/// 逐种形态都查一遍，避免把实现细节写死进断言。
bool _paints(WidgetTester tester, Finder scope, Color color) {
  final Finder any = find.descendant(
    of: scope,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is ColoredBox ||
          widget is Material ||
          widget is DecoratedBox ||
          widget is Container,
    ),
  );
  final Iterable<Widget> widgets = tester.widgetList<Widget>(any);
  for (final Widget widget in widgets) {
    if (widget is ColoredBox && widget.color == color) {
      return true;
    }
    if (widget is Material && widget.color == color) {
      return true;
    }
    if (widget is DecoratedBox) {
      final Decoration decoration = widget.decoration;
      if (decoration is BoxDecoration && decoration.color == color) {
        return true;
      }
    }
    if (widget is Container && _containerColor(widget) == color) {
      return true;
    }
  }
  // 被查找的节点自己可能就是刷色层。
  final Widget self = tester.widget(scope);
  if (self is ColoredBox && self.color == color) {
    return true;
  }
  if (self is Container && _containerColor(self) == color) {
    return true;
  }
  if (self is DecoratedBox) {
    final Decoration decoration = self.decoration;
    return decoration is BoxDecoration && decoration.color == color;
  }
  return false;
}

/// 某个档位标签（`AppLocalizations.zh` 的四个 key 之一）。
Finder _tab(String horizonKey) =>
    find.byKey(ValueKey<String>('goal-blueprint-tab-$horizonKey'));

/// 某档位标签里第一个 `Text` 的字重（缺失视为 `normal` = 400）。
double _tabWeight(WidgetTester tester, String horizonKey) {
  final Finder label = find.descendant(
    of: _tab(horizonKey),
    matching: find.byType(Text),
  );
  final Text text = tester.widget<Text>(label.first);
  return (text.style?.fontWeight ?? FontWeight.normal).value.toDouble();
}

/// 一条 career × 终极档的矩阵行（只为让标签条渲染出来）。
GoalBlueprintRow _careerRow() => GoalBlueprintRow(
  domainKey: 'career',
  cells: <GoalHorizon, List<GoalRow>>{
    GoalHorizon.ultimate: <GoalRow>[
      GoalRow(
        id: 'b14-theme-1',
        kind: GoalKind.blueprint,
        title: '配色样本',
        status: GoalStatus.active,
        periodStart: 0,
        periodEnd: 0,
        createdAt: 0,
        updatedAt: 0,
      ),
    ],
  },
);

/// 挂矩阵本体（不经过页面，形状抄 `b10_blueprint_matrix_done_test.dart:52-74`）。
Widget _host() => MaterialApp(
  theme: AppTheme.light(DensityProfile.comfortable),
  home: Scaffold(
    body: SingleChildScrollView(
      child: GoalBlueprintMatrix(
        t: AppLocalizations.zh,
        rows: <GoalBlueprintRow>[_careerRow()],
        serves: const GoalServesIndex(
          <String, List<GoalRow>>{},
          <String, List<GoalRow>>{},
        ),
        tracksCount: const <String, int>{},
        onSplitTodos: (GoalRow _) {},
      ),
    ),
  ),
);

void main() {
  group('B14-1 四个档位标签都带「目标」', () {
    test('中文四档以「目标」结尾，英文四档以 "Goal" 结尾', () {
      final AppLocalizations zh = AppLocalizations.zh;
      final AppLocalizations en = AppLocalizations.en;
      final List<String> zhLabels = <String>[
        zh.goalBlueprintHorizonUltimate,
        zh.goalBlueprintHorizonLong,
        zh.goalBlueprintHorizonMid,
        zh.goalBlueprintHorizonShort,
      ];
      for (final String label in zhLabels) {
        expect(label.endsWith('目标'), isTrue, reason: '中文档位缺「目标」：$label');
      }
      final List<String> enLabels = <String>[
        en.goalBlueprintHorizonUltimate,
        en.goalBlueprintHorizonLong,
        en.goalBlueprintHorizonMid,
        en.goalBlueprintHorizonShort,
      ];
      for (final String label in enLabels) {
        expect(label.endsWith('Goal'), isTrue, reason: '英文档位缺 Goal：$label');
      }
      expect(zhLabels.toSet().length, 4, reason: '四个档位文案必须互不相同');
    });

    test('配色三枚设置文案中英都齐', () {
      expect(AppLocalizations.zh.settingsAccentGreen, '浅绿');
      expect(AppLocalizations.zh.settingsAccentBlue, '浅蓝');
      expect(AppLocalizations.en.settingsAccentGreen, 'Green');
      expect(AppLocalizations.en.settingsAccentBlue, 'Blue');
    });
  });

  group('B14-3 活动标签选中态可辨', () {
    testWidgets('活动底色是 inkWash，不再与内容区同色', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      const ThemeTokens tokens = ThemeTokens.light;
      // T3-1：活动标签刷 `inkWash`。
      expect(_paints(tester, _tab('ultimate'), tokens.inkWash), isTrue);
      // 修复前的 bug：活动底色 = 内容区底色（`card` / `paper`）⇒ 融为一体。
      expect(_paints(tester, _tab('ultimate'), tokens.card), isFalse);
      expect(_paints(tester, _tab('ultimate'), tokens.paper), isFalse);
      // 非活动标签仍走 `sunken`，与活动态有别。
      expect(_paints(tester, _tab('long'), tokens.sunken), isTrue);
      expect(_paints(tester, _tab('long'), tokens.inkWash), isFalse);
    });

    testWidgets('活动标签有 3px 顶部实色条', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      const ThemeTokens tokens = ThemeTokens.light;
      final Finder indicator = find.byKey(
        const ValueKey<String>('goal-blueprint-tab-indicator-ultimate'),
      );
      expect(indicator, findsOneWidget);
      expect(tester.getSize(indicator).height, 3);
      expect(_paints(tester, indicator, tokens.ink), isTrue);
      // 非活动标签没有实色条。
      expect(
        find.byKey(
          const ValueKey<String>('goal-blueprint-tab-indicator-long'),
        ),
        findsNothing,
      );
    });

    testWidgets('活动文字字重严格大于非活动', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(
        _tabWeight(tester, 'ultimate'),
        greaterThan(_tabWeight(tester, 'long')),
      );
    });
  });

  group('B14-4 三套配色', () {
    test('T4-1 三档纸面两两不同（浅色 + 深色）', () {
      for (final bool dark in <bool>[false, true]) {
        final Set<int> papers = <int>{
          for (final AppAccent accent in AppAccent.values)
            (dark ? ThemeTokens.darkFor(accent) : ThemeTokens.lightFor(accent))
                .paper
                .toARGB32(),
        };
        expect(papers.length, AppAccent.values.length, reason: 'dark=$dark');
      }
    });

    test('T4-2 ink 档与历史常量为同一实例（默认档逐字节不变）', () {
      expect(identical(ThemeTokens.lightFor(AppAccent.ink), ThemeTokens.light), isTrue);
      expect(identical(ThemeTokens.darkFor(AppAccent.ink), ThemeTokens.dark), isTrue);
    });

    test('T4-3 浅色档正文与次要文字对比度达 WCAG AA', () {
      for (final AppAccent accent in AppAccent.values) {
        final ThemeTokens tokens = ThemeTokens.lightFor(accent);
        expect(
          _contrast(tokens.ink, tokens.paper),
          greaterThanOrEqualTo(7.0),
          reason: '${accent.name}: ink/paper',
        );
        expect(
          _contrast(tokens.meta, tokens.paper),
          greaterThanOrEqualTo(4.5),
          reason: '${accent.name}: meta/paper',
        );
        expect(
          _contrast(tokens.ink, tokens.card),
          greaterThanOrEqualTo(7.0),
          reason: '${accent.name}: ink/card',
        );
      }
    });

    test('T4-3b 绿/蓝档的槽位与网格别名跟随本档主色（不同步即「格底换色字仍旧墨」）', () {
      for (final AppAccent accent in <AppAccent>[
        AppAccent.green,
        AppAccent.blue,
      ]) {
        final ThemeTokens tokens = ThemeTokens.lightFor(accent);
        expect(tokens.slotPlanInk, tokens.ink, reason: '${accent.name} slotPlanInk');
        expect(tokens.gridSectionMorning, tokens.card, reason: '${accent.name} gridMorning');
      }
    });

    test('T4-6 标签文字 × 活动标签底色 inkWash / 标签条底 paper 对比度 ≥ 4.5（浅深各一）', () {
      // D7：活动标签文字色 = `tokens.ink`、活动标签底 = `tokens.inkWash`
      // （`goal_blueprint_matrix.dart` 的 `_tab`）；标签条容器底 = `tokens.paper`。
      // 判据全部现算，不抄报告里的数。
      for (final bool dark in <bool>[false, true]) {
        for (final AppAccent accent in AppAccent.values) {
          final ThemeTokens tokens = dark
              ? ThemeTokens.darkFor(accent)
              : ThemeTokens.lightFor(accent);
          final String where = '${accent.name} dark=$dark';
          expect(
            _contrast(tokens.ink, tokens.inkWash),
            greaterThanOrEqualTo(4.5),
            reason: '$where: 活动标签文字 ink × 活动底 inkWash',
          );
          expect(
            _contrast(tokens.ink, tokens.paper),
            greaterThanOrEqualTo(4.5),
            reason: '$where: 标签文字 ink × 标签条底 paper',
          );
        }
      }
    });

    test('T4-4 密度 × 配色 × 明暗全组合可构建且背景 = 本档 paper', () {
      for (final AppAccent accent in AppAccent.values) {
        for (final DensityProfile density in DensityProfile.values) {
          final ThemeData light = AppTheme.light(density, accent: accent);
          final ThemeTokens lightTokens = light.extension<ThemeTokens>()!;
          expect(lightTokens.paper, ThemeTokens.lightFor(accent).paper);
          expect(light.scaffoldBackgroundColor, lightTokens.paper);

          final ThemeData dark = AppTheme.dark(density, accent: accent);
          final ThemeTokens darkTokens = dark.extension<ThemeTokens>()!;
          expect(darkTokens.paper, ThemeTokens.darkFor(accent).paper);
          expect(dark.scaffoldBackgroundColor, darkTokens.paper);
        }
      }
    });

    test('T4-5 偏好 encode/parse 往返、未知值回落 ink、默认 ink', () {
      expect(AppPreferences.defaults.accent, AppAccent.ink);
      expect(settingsKeyAccent, 'accent');
      for (final AppAccent accent in AppAccent.values) {
        final String encoded = AppPreferences.encodeAccent(accent);
        expect(AppPreferences.parseAccent(encoded), accent);
      }
      expect(AppPreferences.parseAccent('nope'), AppAccent.ink);
      expect(AppPreferences.parseAccent(''), AppAccent.ink);
    });
  });
}