// apps/desktop/test/today_loop_hint_panel_test.dart
//
// Task 38（W3）：「闭环环 · 四段比例条」并入右栏「闭环提示」。
//
// 七条判据（派工书 §4.2）：
// ① 面板标题逐字 `闭环提示`（按 `todayRailPanels(context)` 生产清单断言）；
// ② 面板内四条 5px 比例条，且不再出现脊线的段头说明；
// ③ 四段比例 = `6/8`、`4/6`、`0`、`0`（按 `FractionallySizedBox.widthFactor` 判，
//    不靠像素猜）；
// ④ 分母为 0 ⇒ 四条比例条为空，且不出现 `100%`；
// ⑤ 中栏不再装配脊线（真机壳里 `LoopProgressRing` 必须缺席）；
// ⑥ 四项文案与数值仍在。
// ⑦ 缺口配色沿用脊线规则（有缺口 `accent`、无缺口 `ink2`）。
// ⑧ 刻度只画一次：整块面板底部一条共用轴（`0`/`25`/`50`/`75`/`100` 各 1 个），
//    四行不再各带一条逐字重复的坐标轴（Task 38 W4）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/loop_progress_ring.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

/// 与 `loop_progress_ring_ridge_test.dart` 同口径：5px 轨道。
final Finder _tracks = find.byWidgetPredicate(
  (widget) => widget is Container && widget.constraints?.maxHeight == 5,
);

/// 撑高测试面：今日页整页竖排，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  // `ReviewSection` 在 `dispose` 里 fire-and-forget 落库；不等它跑完，
  // tearDown 的 `db.close()` 会先关库。
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 内存真库 + 真仓储 + 固定今天。
final class _Harness {
  _Harness._(this.container);

  final ProviderContainer container;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'loop-hint-panel-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container);
  }

  /// 挂真机同一套壳（右轨由 `LedgerShell` 装配）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // 面板清单必须显式注入：`LedgerShell.railPanels` 默认空列表，
        // 不传的话右轨只剩「快捷键」，本用例会假红。
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => LedgerShell(
              content: const TodayPage(),
              currentNavId: 'today',
              railPanels: todayRailPanels(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// 只挂右栏面板：注入 `dayStatsProvider`，不碰数据库。
///
/// 宽度 206 = 右轨栏宽 − 两侧内距 − 面板内距（真实窄栏量级），用来顺带
/// 守住「紧凑形态在窄栏里不横向溢出」。
Future<void> _mountPanel(WidgetTester tester, DayStats stats) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[dayStatsProvider.overrideWithValue(stats)],
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 206, child: const LoopHintPanel()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 取第 [index] 行比例条内的填充宽度因子（未填充时为 0）。
double _widthFactorOf(WidgetTester tester, int index) {
  final Finder fill = find.descendant(
    of: find.byKey(LoopHintPanel.rowKeys[index]),
    matching: find.byType(FractionallySizedBox),
  );
  expect(fill, findsOneWidget, reason: '第 $index 行必须恰有一条比例条填充');
  final FractionallySizedBox box = tester.widget<FractionallySizedBox>(fill);
  expect(box.widthFactor, isNotNull);
  return box.widthFactor!;
}

/// 面板里用 [color] 填充的比例条数量。
Finder _barsFilledWith(Color color) {
  return find.descendant(
    of: find.byType(LoopHintPanel),
    matching: find.byWidgetPredicate(
      (widget) => widget is Container && widget.color == color,
    ),
  );
}

/// 一个可当 `BuildContext` 用的探针（只为调生产清单函数）。
Future<BuildContext> _pumpProbe(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('右栏面板标题逐字是「闭环提示」，末块挂 LoopHintPanel', (tester) async {
    final BuildContext context = await _pumpProbe(tester);
    final panels = todayRailPanels(context);

    final loopPanel = panels.where((panel) => panel.title == '闭环提示');
    expect(loopPanel, hasLength(1), reason: '右栏只能有一个「闭环提示」面板');
    expect(loopPanel.single.child, isA<LoopHintPanel>());
    // 标题不改字面量：不重命名成脊线那套说法。
    expect(
      panels.map((panel) => panel.title).where((t) => t.contains('闭环环')),
      isEmpty,
    );
  });

  testWidgets('面板渲染四条 5px 比例条，且不再出现脊线的段头说明', (tester) async {
    await _mountPanel(
      tester,
      const DayStats(
        planTotal: 8,
        planDone: 6,
        backfilled: 4,
        reviewDone: false,
        moodDone: false,
      ),
    );

    final Finder panel = find.byType(LoopHintPanel);
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: _tracks),
      findsNWidgets(4),
      reason: '一段一条，不得缺、不得多',
    );
    for (final ValueKey<String> key in LoopHintPanel.rowKeys) {
      expect(find.byKey(key), findsOneWidget);
    }

    // R-3：右栏不得再出现脊线的第二层标题。
    expect(find.text('闭环环 · 四段比例条'), findsNothing);
    expect(find.text('刻度 0—100'), findsNothing);

    // 刻度只画一次：整块面板底部一条共用轴（`scale200_overflow_test` 依赖
    // `100` 这个文案，仍然存在、仍不被截断）。
    for (final String tick in LoopTickAxis.ticks) {
      expect(
        find.descendant(of: panel, matching: find.text(tick)),
        findsOneWidget,
        reason: '刻度 `$tick` 在整块面板里只能出现一次',
      );
    }
    expect(find.byKey(LoopHintPanel.axisKey), findsOneWidget);
    expect(find.byType(LoopTickAxis), findsOneWidget);
    // 每行的刻度确实关了：行内找不到任何刻度文案（4 条重复坐标轴已消失）。
    for (final ValueKey<String> key in LoopHintPanel.rowKeys) {
      for (final String tick in LoopTickAxis.ticks) {
        expect(
          find.descendant(of: find.byKey(key), matching: find.text(tick)),
          findsNothing,
          reason: '$key 行不得再各带一条坐标轴',
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('四段比例 = 6/8、4/6、0、0（按宽度因子判，不靠像素）', (tester) async {
    await _mountPanel(
      tester,
      const DayStats(
        planTotal: 8,
        planDone: 6,
        backfilled: 4,
        reviewDone: false,
        moodDone: false,
      ),
    );

    expect(_widthFactorOf(tester, 0), closeTo(6 / 8, 1e-9));
    expect(_widthFactorOf(tester, 1), closeTo(4 / 6, 1e-9));
    expect(_widthFactorOf(tester, 2), 0);
    expect(_widthFactorOf(tester, 3), 0);
  });

  testWidgets('分母为 0 ⇒ 四条比例条为空，且不出现 100%', (tester) async {
    await _mountPanel(
      tester,
      const DayStats(
        planTotal: 0,
        planDone: 0,
        backfilled: 0,
        reviewDone: false,
        moodDone: false,
      ),
    );

    for (var i = 0; i < 4; i++) {
      expect(
        _widthFactorOf(tester, i),
        0,
        reason: '分母为 0 算 0（不是 100%）——第 $i 行',
      );
    }
    expect(find.text('100%'), findsNothing);
    // 回填分母为 0 ⇒ 沿用脊线的 `—` 口径，而不是 0。
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('四项文案与数值仍在（计划缺口 / 回填缺口 / 复盘 / 心态）', (tester) async {
    await _mountPanel(
      tester,
      const DayStats(
        planTotal: 8,
        planDone: 6,
        backfilled: 4,
        reviewDone: false,
        moodDone: false,
      ),
    );

    expect(find.text('计划缺口'), findsOneWidget);
    expect(find.text('回填缺口'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);
    expect(find.text('心态'), findsOneWidget);
    // 数值沿用合并前口径：planPending=2 与「6-4=2」各一处。
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('未写'), findsOneWidget);
    expect(find.text('未记'), findsOneWidget);
  });

  testWidgets('中栏不再装配脊线：真机壳里 LoopProgressRing 缺席、右轨闭环提示在位', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    expect(find.byType(LoopProgressRing), findsNothing);
    expect(find.text('闭环提示'), findsOneWidget);

    final Finder panel = find.byType(LoopHintPanel);
    expect(panel, findsOneWidget);
    expect(find.descendant(of: panel, matching: _tracks), findsNWidgets(4));
    // 真机壳里同样只有一条刻度轴（真库里 `0` 还可能是行内的缺口数值，
    // 所以判据只钉住 `100`，且限定在面板内）。
    expect(
      find.descendant(of: panel, matching: find.text('100')),
      findsOneWidget,
    );

    await _flushTimers(tester);
  });

  testWidgets('缺口配色：全缺口 ⇒ 四条条用 accent、无 ink2', (tester) async {
    await _mountPanel(
      tester,
      const DayStats(
        planTotal: 8,
        planDone: 6,
        backfilled: 4,
        reviewDone: false,
        moodDone: false,
      ),
    );

    expect(_barsFilledWith(AppTokens.accent), findsNWidgets(4));
    expect(_barsFilledWith(AppTokens.ink2), findsNothing);
  });

  testWidgets('缺口配色：全完成 ⇒ 四条条用 ink2、无 accent', (tester) async {
    await _mountPanel(
      tester,
      const DayStats(
        planTotal: 8,
        planDone: 8,
        backfilled: 8,
        reviewDone: true,
        moodDone: true,
      ),
    );

    expect(_barsFilledWith(AppTokens.ink2), findsNWidgets(4));
    expect(_barsFilledWith(AppTokens.accent), findsNothing);
    expect(find.text('已写'), findsOneWidget);
    expect(find.text('已记'), findsOneWidget);
  });
}
