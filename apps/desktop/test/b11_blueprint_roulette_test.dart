// =============================================================================
// A 版「秒数轮盘」蓝图页：结构性硬判据
// =============================================================================
// 设计方向 A 的骨架是「片头带 + 切面 rail + 轴刻度」，三件事肉眼一看就知道
// 有没有，但代码里一改就静默坏掉；本文件只钉这类**结构**，业务口径仍归
// `b10_*` / `task66_*` / `task73_*` 守。逐条判据：
//  A-1 片头带：墨底 + kicker + 大标题 + 副标 + 右侧元信息 + 静态波形；
//      无渐变、无阴影、圆角 4（反 slop），大标题 key 仍是 `blueprint-title`。
//  A-2 切面 rail：10 项、四问 4 个圆点、当前项 ink 反白；窄视口整条不渲染
//      （回落到原纵向布局，功能一个不少）。
//  A-3 轴刻度：年刻度由当前档位真实日期派生（不硬编码年份），一条带日期的
//      目标都没有时整条不渲染；日期条实心段按跨度比例映射，已完成降调。
//  A-4 四问 1×4：宽视口同一行、窄视口回落纵向；两种宽度下都没有「标签库」
//      开关与「保存」键（B12 起落库走回车、标签库由点 / 聚焦输入框打开），
//      浮窗暂停 / 恢复语义不变（浮窗细粒度用例在 `b10_position_panel_test`）。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_brand_panel.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:actlog/src/widgets/goals/goal_blueprint_band.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart'
    show GoalHorizon, GoalKind, GoalPeriod, GoalStatus;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 片头带根。
const ValueKey<String> _bandKey = ValueKey<String>('goal-blueprint-band');

/// 切面 rail 根。
const ValueKey<String> _railKey = ValueKey<String>('goal-blueprint-facet-rail');

/// 标签浮层根。
const ValueKey<String> _overlayKey = ValueKey<String>(
  'goal-position-tags-overlay',
);

/// 四问 code（顺序即 1×4 从左到右）。
const List<String> _questionCodes = <String>['values', 'strengths', 'value', 'proof'];

/// 本地午夜毫秒（蓝图目标按本地时区存，与 `_span` 的口径一致）。
int _local(int year, int month, int day) =>
    DateTime(year, month, day).millisecondsSinceEpoch;

/// 固定视口：宽视口让 1×4 / rail / 日期列都拿得到空间。
void _size(WidgetTester tester, {double width = 1400, double height = 1600}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 片头带单独挂起（不依赖任何 provider）。
Widget _bandHost() => MaterialApp(
  theme: AppTheme.light(DensityProfile.comfortable),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 1200,
        child: GoalBlueprintBand(t: AppLocalizations.zh, today: '2026-11-25'),
      ),
    ),
  ),
);

/// rail 单独挂起（宽度取页面里真实的 220）。
Widget _railHost() => MaterialApp(
  theme: AppTheme.light(DensityProfile.comfortable),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 220,
        child: GoalBlueprintFacetRail(t: AppLocalizations.zh),
      ),
    ),
  ),
);

/// 挂蓝图页（验证 rail 的断点显隐）。
Future<void> _pumpBlueprintPage(
  WidgetTester tester, {
  required ActLogRepositories repos,
  required double width,
}) async {
  _size(tester, width: width, height: 2600);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(AppPreferences.defaults),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(period: GoalPeriod.year(2026)),
            ),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 直接挂矩阵本体（不经过页面）。
Widget _matrixHost(List<GoalBlueprintRow> rows, GoalServesIndex serves) =>
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalBlueprintMatrix(
            t: AppLocalizations.zh,
            rows: rows,
            serves: serves,
            tracksCount: const <String, int>{},
            onSplitTodos: (GoalRow _) {},
          ),
        ),
      ),
    );

/// 一条 career × 终极档的矩阵行。
GoalBlueprintRow _careerRow(List<GoalRow> goals) => GoalBlueprintRow(
  domainKey: 'career',
  cells: <GoalHorizon, List<GoalRow>>{GoalHorizon.ultimate: goals},
);

/// 挂面板（`width` 决定 1×4 还是纵向）。
Future<void> _pumpPanel(
  WidgetTester tester, {
  required ActLogRepositories repos,
  required double width,
}) async {
  _size(tester, width: width, height: 1600);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(AppPreferences.defaults),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalPositionPanel()),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 鼠标移到某输入框中心（触发 `onEnter` ⇒ 开浮层），返回手势以复用指针。
Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  return gesture;
}

/// 日期条里指定颜色的实心段矩形（找不到返回 null）。
Rect? _barRect(WidgetTester tester, Finder track, Color color) {
  final Iterable<Element> elements = find
      .descendant(of: track, matching: find.byType(DecoratedBox))
      .evaluate();
  for (final Element element in elements) {
    final DecoratedBox box = element.widget as DecoratedBox;
    final Decoration decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.color == color) {
      return tester.getRect(find.byWidget(box));
    }
  }
  return null;
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b11-blueprint-roulette-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('A-1 片头带：五段内容齐全，墨底、无渐变、无阴影', (WidgetTester tester) async {
    _size(tester, width: 1400, height: 900);
    await tester.pumpWidget(_bandHost());
    await tester.pumpAndSettle();

    expect(find.byKey(_bandKey), findsOneWidget);
    final AppLocalizations t = AppLocalizations.zh;
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('goal-blueprint-band-kicker'))).data,
      t.goalBlueprintBandKicker,
    );
    // 页面既有契约：大标题 key 不变、文案仍是导航名。
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('blueprint-title'))).data,
      t.shellNavBlueprint,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('goal-blueprint-band-subtitle'))).data,
      t.goalBlueprintBandSubtitle,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('goal-blueprint-band-brand'))).data,
      t.goalBlueprintBandBrand,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('goal-blueprint-band-today'))).data,
      '2026-11-25',
    );
    final CustomPaint wave = tester.widget<CustomPaint>(
      find.byKey(const ValueKey<String>('goal-blueprint-band-wave')),
    );
    expect(wave.painter, isA<GoalBlueprintWavePainter>());

    // 反 slop：墨底纯色、4px 圆角、没有渐变与阴影。
    final Container band = tester.widget<Container>(find.byKey(_bandKey));
    final BoxDecoration decoration = band.decoration! as BoxDecoration;
    expect(decoration.color, ThemeTokens.light.ink);
    expect(decoration.gradient, isNull);
    expect(decoration.boxShadow, isNull);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppTokens.radius),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-2 rail：10 切面、四问 4 个圆点、当前项 ink 反白', (WidgetTester tester) async {
    _size(tester, width: 1400, height: 1200);
    await tester.pumpWidget(_railHost());
    await tester.pumpAndSettle();

    expect(find.byKey(_railKey), findsOneWidget);
    for (int i = 1; i <= 10; i++) {
      final String serial = i.toString().padLeft(2, '0');
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-facet-$serial')),
        findsOneWidget,
        reason: 'rail 必须有第 $serial 项',
      );
    }
    // 四问（04/06/08/10）打圆点，其余不打。
    for (final int serial in <int>[4, 6, 8, 10]) {
      final String padded = serial.toString().padLeft(2, '0');
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-facet-question-$padded')),
        findsOneWidget,
        reason: '第 $padded 项属四问，必须有圆点',
      );
    }
    for (final int serial in <int>[1, 2, 3, 5, 7, 9]) {
      final String padded = serial.toString().padLeft(2, '0');
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-facet-question-$padded')),
        findsNothing,
        reason: '第 $padded 项不属四问，不该有圆点',
      );
    }
    // 当前项（04）ink 反白；四问项只加粗打点，不做反白。
    final Container active = tester.widget<Container>(
      find.byKey(const ValueKey<String>('goal-blueprint-facet-04')),
    );
    expect((active.decoration! as BoxDecoration).color, ThemeTokens.light.ink);
    final Container question = tester.widget<Container>(
      find.byKey(const ValueKey<String>('goal-blueprint-facet-06')),
    );
    expect(question.decoration, isNull, reason: '四问项只加粗打点，不做反白');
    final Container plain = tester.widget<Container>(
      find.byKey(const ValueKey<String>('goal-blueprint-facet-05')),
    );
    expect(plain.decoration, isNull, reason: '非当前、非四问项必须无色块');
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-2 rail 断点：≥980 渲染、<980 整条不渲染且片头带仍在',
      (WidgetTester tester) async {
    await _pumpBlueprintPage(tester, repos: repos, width: 1400);
    expect(find.byKey(_railKey), findsOneWidget);
    expect(find.byKey(_bandKey), findsOneWidget);

    await _pumpBlueprintPage(tester, repos: repos, width: 900);
    expect(find.byKey(_railKey), findsNothing, reason: '窄视口回落原纵向布局');
    expect(find.byKey(_bandKey), findsOneWidget, reason: '片头带不随 rail 一起消失');
    expect(find.byKey(const ValueKey<String>('blueprint-title')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-3 年刻度已下线：跨年目标也不再渲染年份行（B16 第 4 条）', (
    WidgetTester tester,
  ) async {
    final String first = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '写一本书',
      horizon: GoalHorizon.ultimate,
      periodStart: _local(2026, 1, 1),
      periodEnd: _local(2026, 12, 31),
    );
    final String second = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '再做十年',
      horizon: GoalHorizon.ultimate,
      periodStart: _local(2027, 3, 1),
      periodEnd: _local(2028, 6, 30),
    );
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    _size(tester, width: 1400, height: 1600);
    await tester.pumpWidget(
      _matrixHost(
        <GoalBlueprintRow>[
          _careerRow(
            all
                .where((GoalRow g) => g.id == first || g.id == second)
                .toList(growable: false),
          ),
        ],
        serves,
      ),
    );
    await tester.pumpAndSettle();

    // B16 第 4 条：日期列顶部那行「年份刻度条」整体下线
    // （用户反馈「填入起止日期后顶部多一行年份」）。年份信息由
    // `yyyy-MM-dd ~ yyyy-MM-dd` 全量日期自身承担 —— 跨年目标也一样。
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-year-scale')),
      findsNothing,
      reason: 'B16 第 4 条：年份刻度条已下线，跨年档位也不再渲染',
    );
    for (final int year in <int>[2026, 2027, 2028]) {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-year-tick-$year')),
        findsNothing,
        reason: 'B16 第 4 条：刻度 tick $year 一并下线',
      );
    }
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-year-tick-2029')),
      findsNothing,
      reason: '刻度只按真实跨度派生，不许凑整',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-3 无日期：年刻度整条与日期条都不渲染', (WidgetTester tester) async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '还没定日子',
      horizon: GoalHorizon.ultimate,
    );
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    _size(tester, width: 1400, height: 1600);
    await tester.pumpWidget(
      _matrixHost(
        <GoalBlueprintRow>[
          _careerRow(
            all.where((GoalRow g) => g.id == id).toList(growable: false),
          ),
        ],
        serves,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('goal-blueprint-year-scale')), findsNothing);
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-track-$id')),
      findsNothing,
      reason: '没有日期就不画空轨道',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-3 日期条：实心段按跨度比例映射（左起 / 右起各一条）',
      (WidgetTester tester) async {
    final String first = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '上半年',
      horizon: GoalHorizon.ultimate,
      periodStart: _local(2026, 1, 1),
      periodEnd: _local(2026, 6, 30),
    );
    final String second = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '下半年',
      horizon: GoalHorizon.ultimate,
      periodStart: _local(2026, 7, 1),
      periodEnd: _local(2026, 12, 31),
    );
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    _size(tester, width: 1400, height: 1600);
    await tester.pumpWidget(
      _matrixHost(
        <GoalBlueprintRow>[
          _careerRow(
            all
                .where((GoalRow g) => g.id == first || g.id == second)
                .toList(growable: false),
          ),
        ],
        serves,
      ),
    );
    await tester.pumpAndSettle();

    final Finder trackA = find.byKey(ValueKey<String>('goal-blueprint-track-$first'));
    final Finder trackB = find.byKey(ValueKey<String>('goal-blueprint-track-$second'));
    expect(trackA, findsOneWidget);
    expect(trackB, findsOneWidget);

    final Rect spanRect = tester.getRect(trackA);
    final Rect barA = _barRect(tester, trackA, ThemeTokens.light.ink)!;
    final Rect barB = _barRect(tester, trackB, ThemeTokens.light.ink)!;
    // 2026-01-01 ~ 2026-06-30 占全年 180/364 ≈ 0.494。
    expect(
      barA.width / spanRect.width,
      closeTo(0.494, 0.06),
      reason: '实心段宽度必须按跨度比例，不是固定宽',
    );
    expect(barA.left, closeTo(spanRect.left, 1.0), reason: '起点在年初 ⇒ 左缘贴齐');
    expect(
      (barB.left - spanRect.left) / spanRect.width,
      closeTo(0.497, 0.06),
      reason: '下半年目标从年中段起画',
    );
    expect(barA.width, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-3 已完成：日期条降调成 hairStrong，不着 ink',
      (WidgetTester tester) async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '已收口',
      horizon: GoalHorizon.ultimate,
      periodStart: _local(2026, 1, 1),
      periodEnd: _local(2026, 12, 31),
      status: GoalStatus.done,
    );
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    _size(tester, width: 1400, height: 1600);
    await tester.pumpWidget(
      _matrixHost(
        <GoalBlueprintRow>[
          _careerRow(
            all.where((GoalRow g) => g.id == id).toList(growable: false),
          ),
        ],
        serves,
      ),
    );
    await tester.pumpAndSettle();

    final Finder track = find.byKey(ValueKey<String>('goal-blueprint-track-$id'));
    expect(track, findsOneWidget);
    expect(
      _barRect(tester, track, ThemeTokens.light.hairStrong),
      isNotNull,
      reason: '已完成必须用 hairStrong 降调',
    );
    expect(
      _barRect(tester, track, ThemeTokens.light.ink),
      isNull,
      reason: '已完成不许再用 ink',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-4 四问 1×4：宽视口同一行、从左到右，且无开关/保存键',
      (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos, width: 1400);

    final List<Rect> rects = <Rect>[
      for (final String code in _questionCodes)
        tester.getRect(
          find.byKey(ValueKey<String>('goal-position-input-$code')),
        ),
    ];
    double minTop = rects.first.top;
    double maxTop = rects.first.top;
    for (final Rect rect in rects) {
      minTop = rect.top < minTop ? rect.top : minTop;
      maxTop = rect.top > maxTop ? rect.top : maxTop;
    }
    expect(
      maxTop - minTop,
      lessThan(40),
      reason: '1×4 单行：四框顶边应基本齐平（允许 hint 换行差一行）',
    );
    for (int i = 1; i < rects.length; i++) {
      expect(
        rects[i].left,
        greaterThan(rects[i - 1].right - 40),
        reason: '第 ${i + 1} 列必须在上列右侧（单行四列，不是叠成两行两列）',
      );
      expect(rects[i].width, lessThan(rects.first.width * 1.5));
    }
    // B12 把操作行里的「保存」与「标签库」开关整块删了（派工书 §四）：
    // 四问只剩输入框，键位与输入框一个都不能少、也不许回流。
    for (final String code in _questionCodes) {
      expect(
        find.byKey(ValueKey<String>('goal-position-save-$code')),
        findsNothing,
        reason: '$code 不该再有保存键',
      );
      expect(
        find.byKey(ValueKey<String>('goal-position-input-$code')),
        findsOneWidget,
        reason: '$code 的输入框必须还在',
      );
    }
    for (final String code in <String>['values', 'strengths']) {
      expect(
        find.byKey(ValueKey<String>('goal-position-tags-toggle-$code')),
        findsNothing,
        reason: '$code 不该再有标签库开关',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-4 四问窄视口：回落到纵向堆叠', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos, width: 600);

    final List<Rect> rects = <Rect>[
      for (final String code in _questionCodes)
        tester.getRect(
          find.byKey(ValueKey<String>('goal-position-input-$code')),
        ),
    ];
    double minTop = rects.first.top;
    double maxTop = rects.first.top;
    for (final Rect rect in rects) {
      minTop = rect.top < minTop ? rect.top : minTop;
      maxTop = rect.top > maxTop ? rect.top : maxTop;
    }
    expect(
      maxTop - minTop,
      greaterThan(100),
      reason: '窄视口必须竖排（1×4 会把 1/4 宽度压爆）',
    );
    for (int i = 1; i < rects.length; i++) {
      expect(rects[i].left, closeTo(rects.first.left, 1.0));
      expect(rects[i].top, greaterThan(rects[i - 1].bottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-4 浮窗语义不变：指针在浮层里暂停计时，移出后重新计时',
      (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos, width: 1400);
    final TestGesture gesture = await _hover(
      tester,
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    expect(find.byKey(_overlayKey), findsOneWidget);

    await gesture.moveTo(tester.getCenter(find.byKey(_overlayKey)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(
      find.byKey(_overlayKey),
      findsOneWidget,
      reason: '指针进浮层 ⇒ 3s 计时必须暂停',
    );

    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(
      find.byKey(_overlayKey),
      findsNothing,
      reason: '指针离开 ⇒ 重新计时，3s 到点关闭',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-4 点输入框：打开即钉住（不再受 3s 计时约束）',
      (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos, width: 1400);
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    await tester.pump();
    expect(find.byKey(_overlayKey), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(
      find.byKey(_overlayKey),
      findsOneWidget,
      reason: '点输入框打开 = 钉住，不许被计时关掉',
    );

    // 钉住态由 `Esc` 关（再点一次输入框只会重新打开，不是关闭）。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byKey(_overlayKey), findsNothing, reason: 'Esc 必须能关掉钉住的浮层');
    expect(tester.takeException(), isNull);
  });
}