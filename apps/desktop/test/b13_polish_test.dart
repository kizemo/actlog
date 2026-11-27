// =============================================================================
// B13 · 界面打磨四条 + 设计口径自检（契约：docs\b13-dispatch.md）
// =============================================================================
// 用例与派工书的对应关系（编号即派工书编号，便于逐条验收）：
//  A5-1 宽视口（1200）四问输入框 top / bottom / height 两两相等；
//  A5-2 第一问灌入 ≥4 行文本后三值仍相等（`maxLines: 3` 落到实处）；
//  A5-3 一列进入「已自动保存」态后四列底边仍相等（状态行槽常驻）；
//  A5-4 窄视口（600 < `_inlineBreakpoint` 720）四框宽度 / 高度两两相等；
//  A5-5 四问 `TextField.minLines == maxLines == 3`。
//  B4-1 档位标签字号 15 + 衬线族取 `AppFonts`（不自写字体名）；
//  B4-2 档位标签水平内边距 10；
//  B4-3 窄视口 760：标签条不溢出（无异常）、四个档位仍都在；
//  B4-4 标签高度：激活 38 / 未激活 31。
//  C3-1 起止日期入口只剩图标：键名在、tooltip 在、旧文字不在；
//  C3-2 点图标仍弹起止日期对话框，且两行日期按 seed 回显；
//  C3-3 在对话框里选结束日 ⇒ 落库（本地午夜毫秒），起始不变。
//
// 判据口径（E 节自检）：**只用** `tester.getRect` / widget 属性 / tooltip，
// 不看截图、不做字形断言 —— 桌面测试不预载字体，字形断言必然是假信号。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_brand_panel.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalHorizon, GoalKind;
// `QueryRow` 是 `customSelect` 的行类型，drift 从 2.x 起只在 drift.dart 导出。
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 四问 code（顺序即渲染顺序，与 `goal_brand_panel.dart` 一致）。
const List<String> _codes = <String>['values', 'strengths', 'value', 'proof'];

/// 四个档位标签的 key 片段（顺序即渲染顺序）。
const List<String> _horizonKeys = <String>['ultimate', 'long', 'mid', 'short'];

/// 某个输入框。
Finder _input(String code) =>
    find.byKey(ValueKey<String>('goal-position-input-$code'));

/// 某个档位标签（`TextButton`）。
Finder _tab(String horizonKey) =>
    find.byKey(ValueKey<String>('goal-blueprint-tab-$horizonKey'));

/// 一组数值两两相等（容许 0.01 的布局取整误差）。
void _expectAllEqual(Iterable<double> values, String reason) {
  final List<double> list = values.toList();
  expect(list.length, _codes.length, reason: '取样数必须与四问一致（$reason）');
  for (int i = 1; i < list.length; i++) {
    expect(
      list[i],
      closeTo(list.first, 0.01),
      reason: '$reason（第 ${i + 1} 项 ${list[i]} ≠ 第 1 项 ${list.first}）',
    );
  }
}

/// 挂起个人定位面板（形状抄 `b12_position_panel_test.dart:60-96`）。
///
/// [size] 是**逻辑**尺寸（`devicePixelRatio = 1`）：1200 = 宽视口（四列并排），
/// 600 = 窄视口（< `_inlineBreakpoint` 720 ⇒ 纵向堆叠）。
Future<void> _pumpPanel(
  WidgetTester tester, {
  required ActLogRepositories repos,
  Size size = const Size(1200, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(
              AppPreferences.defaults,
            ),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: const Scaffold(
            // 顶部留白：说明浮层只往标题上方长，需要这段空间（B12 §四.1）。
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 200),
                child: GoalPositionPanel(),
              ),
            ),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 直接挂矩阵组件（抄 `b12_matrix_tabs_date_test.dart:163-191`）。
///
/// 只放一个空领域行：本组用例只关心**标签条**的样式与窄视口表现，不需要真实目标。
Future<void> _pumpMatrix(
  WidgetTester tester, {
  Size size = const Size(1400, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalBlueprintMatrix(
            t: AppLocalizations.zh,
            rows: const <GoalBlueprintRow>[
              GoalBlueprintRow(
                domainKey: 'career',
                cells: <GoalHorizon, List<GoalRow>>{},
              ),
            ],
            serves: const GoalServesIndex(
              <String, List<GoalRow>>{},
              <String, List<GoalRow>>{},
            ),
            tracksCount: const <String, int>{},
            onSplitTodos: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// `onSplitTodos` 的哑实现（本文件不触发拆分）。
void _noop(GoalRow _) {}

/// 挂起人生蓝图页（真页面 + 真库；抄 `b12_matrix_tabs_date_test.dart:125-160`）。
Future<void> _pumpPage(
  WidgetTester tester, {
  required ActLogRepositories repos,
  String instance = 'b13-polish',
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(
              AppPreferences.defaults,
            ),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(key: ValueKey<String>(instance)),
            ),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 滚到某个 key 上并点它（页面在长表格里，不 ensureVisible 点不到）。
Future<void> _tapKey(WidgetTester tester, Key key) async {
  final Finder target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// 回车（IME 的 `done`）⇒ `TextField.onSubmitted` ⇒ 自动落库。
Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// 回读一条目标的起止（原生列名；毫秒口径 = 本地午夜）。
Future<Map<String, int?>> _periodRow(ActLogDatabase db, String id) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT period_start, period_end FROM goal WHERE id = \'$id\'',
      )
      .get();
  expect(rows.length, 1, reason: '目标必须还在库里：$id');
  return <String, int?>{
    'period_start': rows.single.data['period_start'] as int?,
    'period_end': rows.single.data['period_end'] as int?,
  };
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b13-polish-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  // ===========================================================================
  // A5 · 个人定位四框等高
  // ===========================================================================

  testWidgets('A5-1 宽视口：四问输入框 top/bottom/height 两两相等', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, repos: repos);

    final List<Rect> rects = <Rect>[
      for (final String code in _codes) tester.getRect(_input(code)),
    ];

    _expectAllEqual(
      rects.map((Rect r) => r.top),
      'A1/A2：标题槽定高 + 状态行槽常驻 ⇒ 四个输入框起始 y 必须一致',
    );
    _expectAllEqual(rects.map((Rect r) => r.bottom), 'A1：四个输入框底边必须一致（四列等高）');
    _expectAllEqual(
      rects.map((Rect r) => r.height),
      'A1：四个输入框高度必须一致（minLines = maxLines = 3）',
    );
  });

  testWidgets('A5-2 第一问灌入 4 行文本：三值仍相等（不撑高）', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final List<Rect> before = <Rect>[
      for (final String code in _codes) tester.getRect(_input(code)),
    ];

    await tester.enterText(_input('values'), '甲\n乙\n丙\n丁');
    await tester.pumpAndSettle();

    final List<Rect> after = <Rect>[
      for (final String code in _codes) tester.getRect(_input(code)),
    ];
    _expectAllEqual(
      after.map((Rect r) => r.top),
      'A2：多行文本不许把该列输入框顶下去（maxLines 固定为 3）',
    );
    _expectAllEqual(after.map((Rect r) => r.height), 'A2：多行文本不许撑高输入框');
    expect(
      after.first.height,
      closeTo(before.first.height, 0.01),
      reason: 'A2：塞 4 行文本前后，输入框高度必须不变',
    );
  });

  testWidgets('A5-3 一列进入「已自动保存」态：四列底边仍相等', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);

    await tester.enterText(_input('values'), '自主、成长');
    await _submit(tester);
    // 前情：第一列确实进了「已自动保存」态（否则这条用例测不到状态行占位）。
    expect(
      find.byKey(const ValueKey<String>('goal-position-saved')),
      findsOneWidget,
      reason: 'A3：回车落库后要有「已自动保存」提示',
    );

    final List<Rect> rects = <Rect>[
      for (final String code in _codes) tester.getRect(_input(code)),
    ];
    _expectAllEqual(
      rects.map((Rect r) => r.bottom),
      'A3：状态行是常驻槽位 ⇒ 有提示的一列也不许把输入框顶高/压低',
    );
    _expectAllEqual(rects.map((Rect r) => r.height), 'A3：状态行槽常驻 ⇒ 四列输入框高度仍一致');
  });

  testWidgets('A5-4 窄视口 600（< 720 断点）：四框宽度 / 高度两两相等', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, repos: repos, size: const Size(600, 1600));

    final List<Rect> rects = <Rect>[
      for (final String code in _codes) tester.getRect(_input(code)),
    ];

    // 先证明真的走了窄视口那条分支（否则这条用例在宽视口下会假绿）。
    expect(
      rects[1].top,
      greaterThan(rects[0].bottom),
      reason: 'A4：600 < _inlineBreakpoint 720 ⇒ 必须是纵向堆叠，不是四列并排',
    );

    _expectAllEqual(rects.map((Rect r) => r.width), 'A4：窄视口四框宽度必须一致（都占满列宽）');
    _expectAllEqual(rects.map((Rect r) => r.height), 'A4：窄视口四框高度必须一致（同一套槽位尺寸）');
  });

  testWidgets('A5-5 四问 minLines = maxLines = 3', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);

    for (final String code in _codes) {
      final TextField field = tester.widget<TextField>(_input(code));
      expect(field.minLines, 3, reason: 'A2：$code 的 minLines 必须是 3');
      expect(field.maxLines, 3, reason: 'A2：$code 的 maxLines 必须是 3');
    }
  });

  // ===========================================================================
  // B4 · 档位标签衬线化（字号 ↑ / 内边距 ↑ / 高度 ↑）
  // ===========================================================================

  testWidgets('B4-1 标签字号 15 + 衬线族取自 AppFonts', (WidgetTester tester) async {
    await _pumpMatrix(tester);

    Text labelOf(String horizonKey) => tester.widget<Text>(
      find.descendant(of: _tab(horizonKey), matching: find.byType(Text)),
    );

    for (final String horizonKey in _horizonKeys) {
      final TextStyle? style = labelOf(horizonKey).style;
      expect(style?.fontSize, 15, reason: 'B1：$horizonKey 标签字号必须是 15');
      expect(
        style?.fontFamily,
        AppFonts.display,
        reason: 'B1：$horizonKey 标签字体必须取 AppFonts.display（不许自写字体名）',
      );
      expect(
        style?.fontFamilyFallback,
        contains('Noto Serif SC'),
        reason: 'B1：$horizonKey 标签衬线回退里必须有 Noto Serif SC（中文字形）',
      );
    }
  });

  testWidgets('B4-2 标签内边距：水平 10（硬下限）/ 上下 4', (WidgetTester tester) async {
    await _pumpMatrix(tester);

    for (final String horizonKey in _horizonKeys) {
      final TextButton tab = tester.widget<TextButton>(_tab(horizonKey));
      // B14（stage 4 · A1）：水平内边距 18 → 10。18 时英文态 760 宽真页面的
      // 自然宽 976.5px 缩到可用宽 742 ⇒ 显示字号 11.3978px，相对 11px 红线的
      // 余量只有 0.3978px（< 1.00px 判据）；四个标签的左右内边距合计 144px 是
      // 自然宽里**唯一可压**的部分（字形宽 830.5px 由字号 15 与固定文案决定）
      // ⇒ 收到 10。**10 是硬下限**：再降到 9，中文 320 宽那组不再触发
      // scaleDown ⇒ `b14_tab_scale_test.dart` 的 T4 量具自检失效。
      // 11px 红线不变（余量判据见 `b14_tab_scale_test.dart` 的 `_requiredMarginPx`）。
      expect(
        tab.style!.padding!.resolve(const <WidgetState>{}),
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        reason: 'B16 第 3 条：$horizonKey 水平内边距仍是 10（硬下限不动）'
            '+ 上下各 4px（标签文字不拥挤）',
      );
    }
  });

  testWidgets('B4-3 窄视口 760：标签条不溢出，四个档位都在', (WidgetTester tester) async {
    await _pumpMatrix(tester, size: const Size(760, 1600));

    expect(
      tester.takeException(),
      isNull,
      reason: 'B3：`FittedBox(scaleDown)` 兜底 ⇒ 窄视口不许 RenderFlex overflow',
    );
    for (final String horizonKey in _horizonKeys) {
      expect(
        _tab(horizonKey),
        findsOneWidget,
        reason: 'B3：窄视口下 $horizonKey 标签仍要渲染出来',
      );
    }
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey<String>('goal-blueprint-tab-strip')),
          )
          .width,
      lessThanOrEqualTo(760),
      reason: 'B3：标签条宽度不许超出视口',
    );
  });

  testWidgets('B4-4 标签高度：激活 46 / 未激活 39（仍差 7px）', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(tester);

    double heightOf(String horizonKey) => tester
        .widget<TextButton>(_tab(horizonKey))
        .style!
        .minimumSize!
        .resolve(const <WidgetState>{})!
        .height;

    // B16 第 3 条：页签加大**垂直**内边距（文字不拥挤）。
    // 激活 38 → 46、未激活 31 → 39：两条都 +8（上下各 4），落差 7px 不变。
    // 水平宽度与字号完全不动 ⇒ `b14_tab_scale_test.dart` 的缩放余量判据不受影响。
    expect(heightOf('ultimate'), 46, reason: 'B16 第 3 条：激活标签高度 46（原 38）');
    for (final String horizonKey in <String>['long', 'mid', 'short']) {
      expect(
        heightOf(horizonKey),
        39,
        reason: 'B16 第 3 条：未激活标签高度 39（原 31）',
      );
    }
  });

  // ===========================================================================
  // C3 · 起止日期入口：文字 → 图标（语义与行为不变）
  // ===========================================================================

  testWidgets('C3-1 入口只剩图标：键名在、tooltip 在、旧文字不在', (WidgetTester tester) async {
    final AppLocalizations zh = AppLocalizations.zh;
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '起止图标目标',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      periodStart: DateTime(2026, 12, 1).millisecondsSinceEpoch,
      periodEnd: DateTime(2026, 12, 20).millisecondsSinceEpoch,
    );

    await _pumpPage(tester, repos: repos);

    expect(
      find.byKey(ValueKey<String>('goal-blueprint-period-$id')),
      findsOneWidget,
      reason: 'C3：改期按钮的键名一字未改（调用点/测试都没换 key）',
    );
    expect(
      find.text(zh.goalBlueprintPeriodTitle),
      findsNothing,
      reason: 'C3：入口不再用「起止日期」四个字占满单元格',
    );
    expect(
      find.byTooltip(zh.goalBlueprintPeriodTitle),
      findsOneWidget,
      reason: 'C3：tooltip 仍是「起止日期」⇒ 语义没有丢，只是视觉换成图标',
    );
    expect(
      find.byIcon(Icons.date_range_outlined),
      findsOneWidget,
      reason: 'C3：图标必须是 Icons.date_range_outlined（与相邻 *_outlined 系一致）',
    );
    expect(tester.takeException(), isNull, reason: 'C3：换图标不许引入布局异常');
  });

  testWidgets('C3-2 点图标仍弹起止日期对话框，两行日期按库里值回显', (WidgetTester tester) async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '起止对话框目标',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      periodStart: DateTime(2026, 12, 1).millisecondsSinceEpoch,
      periodEnd: DateTime(2026, 12, 20).millisecondsSinceEpoch,
    );

    await _pumpPage(tester, repos: repos);
    await _tapKey(tester, ValueKey<String>('goal-blueprint-period-$id'));

    expect(
      find.byKey(const ValueKey<String>('goal-period-dialog')),
      findsOneWidget,
      reason: 'C3：图标入口打开的仍是同一个起止日期对话框',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('goal-period-start')),
        matching: find.text('2026-12-01'),
      ),
      findsOneWidget,
      reason: 'C3：起始行按库里的 period_start 回显（本地午夜口径）',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('goal-period-end')),
        matching: find.text('2026-12-20'),
      ),
      findsOneWidget,
      reason: 'C3：结束行按库里的 period_end 回显',
    );
  });

  testWidgets('C3-3 对话框里选结束日：落库为本地午夜毫秒，起始不变', (WidgetTester tester) async {
    final int startMs = DateTime(2026, 12, 1).millisecondsSinceEpoch;
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '改结束日目标',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      periodStart: startMs,
      periodEnd: DateTime(2026, 12, 20).millisecondsSinceEpoch,
    );

    await _pumpPage(tester, repos: repos);
    await _tapKey(tester, ValueKey<String>('goal-blueprint-period-$id'));
    expect(
      find.byKey(const ValueKey<String>('goal-period-dialog')),
      findsOneWidget,
      reason: '前情：对话框已打开',
    );

    // 结束行按钮在对话框内容里（无 Scrollable 祖先）⇒ 直接 tap，
    // 用 `ensureVisible` 会因找不到 Scrollable 抛出。
    await tester.tap(find.byKey(const ValueKey<String>('goal-period-end')));
    await tester.pumpAndSettle();
    expect(
      find.byType(DatePickerDialog),
      findsOneWidget,
      reason: 'C3：点结束行必须弹日期选择器（不是手打文本框）',
    );
    expect(
      find.byType(CalendarDatePicker),
      findsOneWidget,
      reason: 'C3：弹出的是可点选的日历体',
    );

    // 初始日期 = 库里的 2026-12-20 ⇒ 日历停在 2026 年 12 月，点 10 号。
    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarDatePicker),
            matching: find.text('10'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    // 回到起止对话框：结束行要立刻回显新选的日期。
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('goal-period-end')),
        matching: find.text('2026-12-10'),
      ),
      findsOneWidget,
      reason: 'C3：选完日期对话框内要立刻回显',
    );

    await tester.tap(find.byKey(const ValueKey<String>('goal-period-confirm')));
    await tester.pumpAndSettle();

    final Map<String, int?> row = await _periodRow(db, id);
    expect(
      row['period_end'],
      DateTime(2026, 12, 10).millisecondsSinceEpoch,
      reason: 'C3：结束日要落库为**本地**午夜毫秒（东八区不许提前一天）',
    );
    expect(
      row['period_start'],
      startMs,
      reason: 'C3：只改结束日 ⇒ period_start 必须原封不动',
    );
  });
}
