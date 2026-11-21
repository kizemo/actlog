// apps/desktop/test/task49_datebar_test.dart
//
// Task 49「顶部日期模块改版」的回归装置，盯三件事：
//   1. 日期模块只剩三个可交互元素：日期 / 向左 / 向右 —— 「昨天」「明天」
//      「今天」三个按钮**整体删除**（不是条件渲染，key 也必须消失）。
//   2. 点日期标题弹出日期卡片（DatePickerSheet）；选一天后选中日**真的**切过去
//      （写回 selectedDateProvider），不是弹层里选完就散。
//   3. 日期模块下面多出来的那行日期表头已删（day_grid.dart 的 `_headerStrip`
//      / `day-grid-header-date`），方格时间轴的刻度列对齐没被带歪。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/date_bar.dart';
import 'package:actlog/src/widgets/date_picker_sheet.dart';
import 'package:actlog/src/widgets/day_timeline.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';

/// 固定「今天」，让「非今日」的判定确定化。
const String _today = '2026-11-07';

/// 选日用的目标日期（与 [DatePickerSheet] 弹层里的初始月同月）。
const String _picked = '2026-11-12';

/// 只覆盖 `todayProvider` 的轻量容器：日期条本身不碰数据库。
ProviderContainer _lightContainer() {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[todayProvider.overrideWithValue(_today)],
  );
  addTearDown(container.dispose);
  return container;
}

/// 挂一个只含日期条的界面。
Future<void> _mountBar(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: DateBar())),
    ),
  );
}

void main() {
  testWidgets('日期模块只剩「日期 / 向左 / 向右」：没有昨天 / 明天 / 今天', (tester) async {
    final ProviderContainer container = _lightContainer();
    await _mountBar(tester, container);

    expect(find.text('昨天'), findsNothing);
    expect(find.text('明天'), findsNothing);
    expect(find.text('今天'), findsNothing);

    // 三个可交互元素在位。
    expect(find.byKey(const ValueKey('date-bar-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('date-bar-prev')), findsOneWidget);
    expect(find.byKey(const ValueKey('date-bar-next')), findsOneWidget);

    // 被删按钮的 key 必须消失（不许留残骸）。
    expect(find.byKey(const ValueKey('date-bar-yesterday')), findsNothing);
    expect(find.byKey(const ValueKey('date-bar-tomorrow')), findsNothing);
    expect(find.byKey(const ValueKey('date-bar-today')), findsNothing);
  });

  testWidgets('切到非今日日期后仍不出现「今天」按钮', (tester) async {
    final ProviderContainer container = _lightContainer();
    await _mountBar(tester, container);

    await tester.tap(find.byKey(const ValueKey('date-bar-next')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-08');

    expect(find.text('今天'), findsNothing);
    expect(find.byKey(const ValueKey('date-bar-today')), findsNothing);
    // 只读状态徽标是状态读数、不是按钮，必须保留。
    expect(find.text('预排'), findsOneWidget);
  });

  testWidgets('点「‹」「›」各挪一天', (tester) async {
    final ProviderContainer container = _lightContainer();
    await _mountBar(tester, container);

    await tester.tap(find.byKey(const ValueKey('date-bar-next')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-08');

    await tester.tap(find.byKey(const ValueKey('date-bar-prev')));
    await tester.pump();
    expect(container.read(selectedDateProvider), _today);

    await tester.tap(find.byKey(const ValueKey('date-bar-prev')));
    await tester.pump();
    expect(container.read(selectedDateProvider), '2026-11-06');
  });

  testWidgets('点日期标题弹出日期卡片；选一天后真的切过去', (tester) async {
    final ProviderContainer container = _lightContainer();
    await _mountBar(tester, container);

    await tester.tap(find.byKey(const ValueKey('date-bar-title')));
    await tester.pumpAndSettle();
    expect(
      find.byType(DatePickerSheet),
      findsOneWidget,
      reason: '点日期标题没有弹出日期卡片',
    );

    await tester.tap(find.byKey(const ValueKey('day-$_picked')));
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(
      container.read(selectedDateProvider),
      _picked,
      reason: '弹层里选完日期，选中日没切过去',
    );
    expect(find.byType(DatePickerSheet), findsNothing);
  });

  testWidgets('day_grid 不再渲染日期表头行；刻度列对齐未受影响', (tester) async {
    // 撑高测试面：一整天的方格时间轴在默认 800×600 下会溢出。
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 真库 + 真仓储：`planItemsProvider` 得真的把当天条目送到网格。
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task49-datebar-test');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DayGrid(date: _today))),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    for (int i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 日期表头整行删除。
    expect(
      find.byKey(const ValueKey<String>('day-grid-header-date')),
      findsNothing,
      reason: '日期表头行还在：日期只应由顶部日期模块表达',
    );

    // 既有结构 key 仍在，且刻度列没被带歪：宽度仍按视口算，左缘仍与内容列同线。
    final Finder ruler = find.byKey(const ValueKey<String>('day-grid-ruler'));
    expect(ruler, findsOneWidget, reason: '刻度列不见了');
    expect(
      tester.getSize(ruler).width,
      closeTo(tlWidthFor(tester.getSize(find.byType(DayGrid)).width), 0.01),
      reason: '刻度列宽度被带歪了',
    );
    expect(
      tester.getTopLeft(ruler).dx,
      closeTo(tester.getTopLeft(find.byType(DayGrid)).dx, 0.01),
      reason: '刻度列左缘与 DayGrid（section）左缘不一致',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
