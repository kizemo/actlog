// apps/desktop/test/task51_blank_cell_test.dart
//
// Task 51 · 追加诉求（本 worker 派工单原话）：
//   「没有任务的位置，请显示单元格原本的背景色。」
//
// 判据：日程方格区里**没有被任何条目覆盖的分钟**，必须显示单元格原本的底色
// （三段分区底色 / `card`），不得被条目的四态底色（`slotPlan` / `slotBackfill` …）
// 铺满。
//
// 判别性从哪来：修好之前，`_SlotPainter.paint` 的第一遍按「条目与整格相交」
// 把四态底色横向铺满整列、纵向铺满**整行高**（行高 44，而条目芯片只有 18 逻辑高），
// 于是同一条目所处的整列、连芯片下方那 24px 全被染色 —— 采到的像素是 `slotPlan`
// 而不是分区底色。所以下面第 1 条用例在修复前必然是红的，且红色断言会直接把
// 「芯片下方被铺满」这件事指出来。
//
// 为什么用像素采样：用户判据就是「眼睛看到什么颜色」。`_SlotPainter` 是私有类，
// canvas 调用没法在不引入私有依存的前提下逐条断言；`RepaintBoundary.toImage` +
// `rawRgba` 是本项目既有范式（见 `task35_glyph_render_test.dart` 的渲染用例）。
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 固定「今天」，与被测日期同值。
const String _today = '2026-11-09';

/// 第 9 行（09:00–10:00）在默认窗口 `06:00–24:00` 里的下标。
const int _row9 = 3;

/// 第 13 行（13:00–14:00）—— 中午段（12–18）里的空行，用来钉分区底色。
const int _row13 = 7;

/// 行内相对高度 30：芯片占行首 2–20，格线在 44，30 只可能落在「无任务的分钟」。
const double _dyBelowChip = 30;

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task51-blank-cell-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// `RepaintBoundary` 包在最外层：像素坐标 = 全局坐标 − 它自己的原点，
  /// 不必再去猜 `MaterialApp` / `Scaffold` 的内边距。
  Future<void> mount(
    WidgetTester tester,
    String date,
    GlobalKey boundaryKey,
  ) {
    return tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: l10nScope(
            MaterialApp(home: Scaffold(body: DayGrid(date: date))),
          ),
        ),
      ),
    );
  }
}

/// 拉高视口：默认 800×600 装不下 792px 的网格。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（与 `task50_timeline_lines_test.dart` 同口径）。
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
}

/// 走真仓储落若干条「已排期」计划。
Future<void> _seedPlans(
  _Harness harness,
  List<(String, int, int)> seeds,
) async {
  final TimelineStore store = TimelineStore(harness.repos);
  for (final (String title, int start, int end) in seeds) {
    await store.createTodoWithSlot(
      date: _today,
      title: title,
      startMinute: start,
      endMinute: end,
    );
  }
}

/// 取渲染层真正在用的 `_SlotPainter`（私有类只能按 runtimeType 认领；
/// `layout` / `tokens` 字段是公开的，cast 回公开类型即可读）。
Finder _slotPaintFinder() {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is CustomPaint &&
        widget.painter != null &&
        widget.painter!.runtimeType.toString() == '_SlotPainter',
  );
}

/// 从 `rawRgba` 里取一个像素。被测色全部不透明 ⇒ 预乘前后同值。
Color _pixelAt(ByteData raw, int imageWidth, int x, int y) {
  final int offset = (y * imageWidth + x) * 4;
  return Color.fromARGB(
    raw.getUint8(offset + 3),
    raw.getUint8(offset),
    raw.getUint8(offset + 1),
    raw.getUint8(offset + 2),
  );
}

/// 方格区条目四态底色的全集：这四色只属于条目芯片，不该出现在格底。
List<Color> _kindColors(ThemeTokens t) => <Color>[
  t.slotPlan,
  t.slotDone,
  t.slotBackfill,
  t.slotHabit,
];

/// 一次取齐的采样上下文：整幅像素 + 「列中心 / 行内相对 y → 像素」换算。
final class _Snapshot {
  _Snapshot({
    required this.raw,
    required this.image,
    required this.origin,
    required this.gridTopLeft,
    required this.cellWidth,
    required this.layout,
    required this.tokens,
  });

  final ByteData raw;
  final ui.Image image;

  /// `RepaintBoundary` 自身的全局原点，用来把全局坐标折算成图像像素。
  final Offset origin;

  final Offset gridTopLeft;
  final double cellWidth;
  final SlotLayout layout;
  final ThemeTokens tokens;

  /// 格子内容区原点：`day-grid` 的 1px 边框之内（边框把子层整体内缩 1px）。
  Offset get contentOrigin => gridTopLeft + const Offset(1, 1);

  /// 格子内容区里任意一点的像素颜色（[local] 相对内容区原点）。
  Color atPoint(Offset local) {
    final Offset global = contentOrigin + local;
    return _pixelAt(
      raw,
      image.width,
      (global.dx - origin.dx).round(),
      (global.dy - origin.dy).round(),
    );
  }

  /// 第 [col] 列中心、行内相对高度 [dy] 处的颜色。
  Color inRow(int col, int row, double dy) => atPoint(
    Offset((col + 0.5) * cellWidth, layout.rowTops[row] + dy),
  );

  void dispose() => image.dispose();
}

Future<_Snapshot> _snapshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Finder gridFinder,
) async {
  final RenderRepaintBoundary boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late ByteData raw;
  late ui.Image image;
  await tester.runAsync(() async {
    image = await boundary.toImage(pixelRatio: 1);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    expect(bytes, isNotNull, reason: 'toImage → rawRgba 返回 null');
    raw = bytes!;
  });

  final CustomPaint paint = tester.widget<CustomPaint>(_slotPaintFinder());
  final dynamic painter = paint.painter;
  final SlotLayout layout = painter.layout as SlotLayout;
  final ThemeTokens tokens = painter.tokens as ThemeTokens;

  final double outerWidth = tester.getSize(gridFinder).width;
  return _Snapshot(
    raw: raw,
    image: image,
    origin: boundary.globalToLocal(Offset.zero),
    gridTopLeft: tester.getTopLeft(gridFinder),
    cellWidth: (outerWidth - 2) / kGridCols,
    layout: layout,
    tokens: tokens,
  );
}

void main() {
  group('Task 51 · 没有任务的位置显示单元格原本的背景色', () {
    testWidgets('空白分钟（同行有任务、芯片下方 / 同行空列）落回分区底色', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: _today);
      // 09:00–09:45 覆盖第 9 行的前 3 列（每列 15 分钟），第 4 列（09:45–10:00）
      // 整列没有任何任务 —— 这正是用户说的「没有任务的位置」。
      await _seedPlans(harness, <(String, int, int)>[('甲', 9 * 60, 9 * 60 + 45)]);

      final GlobalKey boundaryKey = GlobalKey();
      await harness.mount(tester, _today, boundaryKey);
      await _settle(tester);

      final Finder grid = find.byKey(const ValueKey<String>('day-grid'));
      expect(grid, findsOneWidget);
      final _Snapshot snap = await _snapshot(tester, boundaryKey, grid);
      expect(snap.layout.segments, hasLength(1), reason: '只有一条条目');

      // ① 判别性断言：条目**占着**的那一列、在芯片下方（行内 y=30，无任务的分钟）
      //    必须是分区底色。修复前这里是四态底色（`slotPlan` / `slotBackfill` …），
      //    即「条目底色把整行 44px 铺满」。
      final Color belowChip = snap.inRow(1, _row9, _dyBelowChip);
      expect(
        _kindColors(snap.tokens),
        isNot(contains(belowChip)),
        reason: '条目四态底色把整行铺满了（芯片下方 24px 仍是条目色）',
      );
      expect(belowChip, snap.tokens.gridSectionMorning);

      // ② 同一行里完全没任务的第 4 列：同样是分区底色。
      final Color blankColumn = snap.inRow(3, _row9, _dyBelowChip);
      expect(_kindColors(snap.tokens), isNot(contains(blankColumn)));
      expect(blankColumn, snap.tokens.gridSectionMorning);

      // ③ 整行没任务的第 13 行（中午段）：分区底色是 `paper` 那一档。
      final Color noonRow = snap.inRow(2, _row13, _dyBelowChip);
      expect(_kindColors(snap.tokens), isNot(contains(noonRow)));
      expect(noonRow, snap.tokens.gridSectionNoon);

      snap.dispose();
      await _flushTimers(tester);
    });

    testWidgets('三段分区底色仍在（06–12 / 12–18 / 18–24 各一条，颜色按 token 顺序）', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: _today);
      final GlobalKey boundaryKey = GlobalKey();
      await harness.mount(tester, _today, boundaryKey);
      await _settle(tester);

      final Finder tint = find.byKey(
        const ValueKey<String>('day-grid-section-tint'),
      );
      expect(tint, findsOneWidget);
      final Column column = tester.widget<Column>(tint);
      expect(column.children, hasLength(3), reason: '默认窗口 06–24 恰好三段');

      final List<Color> colors = <Color>[
        for (final Widget child in column.children)
          ((child as SizedBox).child! as ColoredBox).color,
      ];
      final _Snapshot snap = await _snapshot(
        tester,
        boundaryKey,
        find.byKey(const ValueKey<String>('day-grid')),
      );
      expect(colors, <Color>[
        snap.tokens.gridSectionMorning,
        snap.tokens.gridSectionNoon,
        snap.tokens.gridSectionEvening,
      ]);

      // 高任务行的并发把某一行撑高时，色带高度仍应与格线对齐 ⇒ 三段之和 = 总高。
      final double total = column.children
          .map((Widget child) => (child as SizedBox).height ?? 0)
          .fold<double>(0, (double sum, double h) => sum + h);
      expect(total, snap.layout.totalHeight);

      snap.dispose();
      await _flushTimers(tester);
    });

    // 控制器的补充质询：`_chipShell` 里有 `OverflowBox(minWidth: 260)`，窄条目
    // 的**正文**被强行撑到 260 逻辑 px。若四态底色挂在被撑宽的那一层上，底色就
    // 会横向溢出到同行右侧的空白格。本条用例把「底色挂在哪一层」变成可判定的：
    // 底色层（`day-grid-entry-<id>` 这个 `Container`）的实测尺寸必须**等于**
    // `layout.tileRect`，且 tileRect 右侧、260 保底宽度之内的像素仍是分区底色。
    testWidgets('窄条目的状态底色只铺 tileRect，不跟着 260px 正文保底横向溢出', (
      WidgetTester tester,
    ) async {
      // 800 宽 ⇒ 每列约 199 逻辑 px，15 分钟条目只有约 195px，确实窄于 260。
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _Harness harness = _Harness.create(selected: _today);
      await _seedPlans(harness, <(String, int, int)>[('窄', 9 * 60, 9 * 60 + 15)]);

      final GlobalKey boundaryKey = GlobalKey();
      await harness.mount(tester, _today, boundaryKey);
      await _settle(tester);

      final Finder grid = find.byKey(const ValueKey<String>('day-grid'));
      expect(grid, findsOneWidget);
      final _Snapshot snap = await _snapshot(tester, boundaryKey, grid);
      final SlotSegment seg = snap.layout.segments.single;
      final Rect rect = snap.layout.tileRect(seg, tester.getSize(grid).width - 2);

      // 前提：本条用例确实落在「正文被撑宽」的窄档，否则测不到溢出路径。
      expect(
        rect.width,
        lessThan(kChipContentMinWidth),
        reason: '视口太宽，条目内宽已 ≥ 260，测不到 OverflowBox 溢出路径',
      );

      // ① 底色层就是外壳 `Container`（`_chipShell` 的 `decoration.color` 层），
      //    它拿的是 `Positioned` 给的紧约束 ⇒ 尺寸与 `tileRect` 逐像素相同。
      final Size painted = tester.getSize(
        find.byKey(ValueKey<String>('day-grid-entry-${seg.entry.id}')),
      );
      expect(painted.width, rect.width);
      expect(painted.height, rect.height);

      // ② tileRect 右缘之外、但仍落在 260 保底宽度之内的像素：若底色跟着正文
      //    溢出，这里必然是四态色；只铺 tileRect 时它是分区底色。
      const double dyMidChip = 11;
      final double leakX = rect.right + 12;
      expect(
        leakX,
        lessThan(kChipContentMinWidth),
        reason: '采样点必须落在「溢出区」里才有判别力',
      );
      final Color leaked = snap.atPoint(
        Offset(leakX, snap.layout.rowTops[_row9] + dyMidChip),
      );
      expect(
        _kindColors(snap.tokens),
        isNot(contains(leaked)),
        reason: '条目底色横向溢出到 tileRect 之外（跟了 260px 的正文保底宽度）',
      );
      expect(leaked, snap.tokens.gridSectionMorning);

      snap.dispose();
      await _flushTimers(tester);
    });
  });
}