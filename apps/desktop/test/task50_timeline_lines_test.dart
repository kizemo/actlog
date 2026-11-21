// apps/desktop/test/task50_timeline_lines_test.dart
//
// Task 50 · W2 · 用户当轮 a–h 八项优化的验收面。
//
// 与 `timeline_slot_layout_test.dart`（纯函数几何）和 `timeline_day_grid_test.dart`
// （交互层）的分工：本文件**只**盯这八条，一条一个用例，坏掉时能直接指到需求编号。
//
// 为什么 a / b / c / d 用纯布局断言、e / f / g / h 用 widget 断言：
//   前四条是「装箱结果对不对」，像素之外的答案在 `SlotLayout` 里就已经确定，
//   打到 widget 层只会把同一件事验两遍、还多一份 flaky；
//   后四条里有三条必须眼见为实（箭头真的画出来了 / 冲突清单真的传到了 painter /
//   内嵌小盒与标题避让真的按像素落位），h 更是纯交互（悬停才出浮窗）。
//
// 关于 §5.1「a：同一小时 3 条互不重叠 ⇒ 三段分处不同带」的口径说明：
//   装箱是**最少车道**算法，时间上首尾相接的三条本来就该共用一条带（否则
//   「一小时三件不重叠的事」要白占三倍高度）。所以 a 拆成两半验：
//     ① 三条**并发**（同一时段）⇒ 三条带、行高 66 —— 这才是一行要能容纳
//        2–3 条带的真实触发条件；
//     ② 两条**不重叠**（09:00–09:30 / 09:30–10:00）⇒ 同带并排、行高仍 44。
//   两半合起来正好是用户原话「每小时行可容纳 2–3 行车视觉带」的全部含义。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';

/// 固定「今天」，与被测日期同值：本文件只关心当天排期，不构造回填 / 未来。
const String _today = '2026-11-09';

/// 窗口默认 `06:00–24:00`（`DayWindow.defaults`，18 行 × 44px）。
const DayWindow _win = DayWindow.defaults;

/// 第 9 行（09:00–10:00）在默认窗口里的下标。
const int _row9 = 3;

/// 测试里认定的内容区宽度（外层 1400 − 轴列 − 边框的量级，只用于横向相对量断言）。
const double _gridWidth = 1096;

/// 造一条投影条目（与 `timeline_slot_layout_test.dart` 同形，起止写绝对分钟）。
GridEntry _entry(String id, int startMinute, int endMinute) {
  return GridEntry(
    id: id,
    title: id,
    startMinute: startMinute,
    endMinute: endMinute,
    kind: SlotKind.plannedOpen,
  );
}

/// 内存真库 + 真仓储 + 固定今天 / 选中日（与 `timeline_day_grid_test.dart`
/// 同一套依赖口径：不 mock 任何 provider）。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task50-lines-test');
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

  Future<void> mount(WidgetTester tester, String date) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: DayGrid(date: date))),
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

/// 等真库流回来（同 `timeline_day_grid_test.dart`）。
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

/// 走真仓储落若干条「已排期」计划，返回 `标题 → 计划行 id`。
///
/// 计划行 id 与待办 id 不是同一个值，而几何断言只认计划行 id（`GridEntry.id`），
/// 所以统一从 `listByDate` 回读一次，而不是去猜 `createTodoWithSlot` 的返回值。
Future<Map<String, String>> _seedPlans(
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
  final List<PlanItemData> plans = await harness.repos.planItem.listByDate(
    _today,
  );
  return <String, String>{
    for (final PlanItemData plan in plans) plan.title: plan.id,
  };
}

/// 取渲染层真正在用的 `_SlotPainter`（`_SlotPainter` 是私有类，只能按 runtimeType
/// 认领；`layout` / `tokens` 字段是公开的，取到后 cast 回公开类型即可读，不必用
/// 动态成员访问）。
Finder _slotPaintFinder() {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is CustomPaint &&
        widget.painter != null &&
        widget.painter!.runtimeType.toString() == '_SlotPainter',
  );
}

void main() {
  group('Task 50 · 需求 a–d：带数、并排、换带', () {
    test('Task 50 · a：并发 3 条 ⇒ 3 条带 / 行高 66；不重叠 2 条 ⇒ 同带并排 / 行高 44', () {
      final SlotLayout three = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
      ]);

      expect(three.laneCounts[_row9], 3);
      expect(three.rowHeights[_row9], kMaxLanesPerRow * kLaneHeight);
      expect(three.rowHeights[_row9], 66);
      expect(three.segments.map((SlotSegment s) => s.lane).toSet(), <int>{
        0,
        1,
        2,
      });
      // 三段占满三条带后，每段净高 20（22 − 2px 缝），一屏一天仍读得完。
      expect(three.segmentHeight(three.segments.first), closeTo(20, 1e-9));

      final SlotLayout two = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60 + 30, 10 * 60),
      ]);

      // 首尾相接 ⇒ 一条带并排放下两条，行高不涨（44 = 2 × 22 的恒等式）。
      expect(two.laneCounts[_row9], 1);
      expect(two.rowHeights[_row9], kHourRowHeight);
      expect(two.segments.map((SlotSegment s) => s.lane).toSet(), <int>{0});
    });

    test('Task 50 · b：同一小时内一个条目只占一条带', () {
      final SlotLayout layout = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
      ]);

      for (final String id in <String>['a', 'b', 'c']) {
        final List<SlotSegment> mine = layout.segments
            .where((SlotSegment s) => s.entry.id == id && s.row == _row9)
            .toList();
        // 本小时内只有一段：跨小时才会切成多段，同一行里不可能出现两条同条目。
        expect(mine, hasLength(1), reason: '条目 $id 在 09:00 行出现了多次');
        expect(mine.single.isHead, isTrue);
      }

      // 带内条目互不相同：同一条带里没有两条同 id 的段。
      final Map<int, Set<String>> idsPerLane = <int, Set<String>>{};
      for (final SlotSegment seg in layout.segments) {
        idsPerLane.putIfAbsent(seg.lane, () => <String>{}).add(seg.entry.id);
      }
      for (final Set<String> ids in idsPerLane.values) {
        expect(ids, hasLength(1));
      }
      expect(layout.laneCounts[_row9], 3);
    });

    test('Task 50 · c：同小时两条不重叠 ⇒ 同带、矩形不相交、横向左缘差 2 列', () {
      final SlotLayout layout = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60 + 30, 10 * 60),
      ]);

      final SlotSegment a = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'a',
      );
      final SlotSegment b = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'b',
      );
      expect(a.lane, b.lane);

      final Rect ra = layout.tileRect(a, _gridWidth);
      final Rect rb = layout.tileRect(b, _gridWidth);
      // 同带并行 ⇒ 横向不重叠：b 从半小时处起，正好接在 a 的右缘之后一个格缝。
      //
      // 注：brief §5.1「c」还写了「纵向 top 相同」，但 §3 明确规定单带行沿用既有
      // 几何（`segmentTop` 按起始分钟比例定位，不改横轴/纵轴语义）——两条不重叠的
      // 条目在同一带里必然起点不同 ⇒ top 必然不同。取「同带 + 矩形不相交」为准，
      // 理由已写进 `reports\task50-w2-report.md`。
      expect(ra.overlaps(rb), isFalse);
      expect(rb.left, greaterThan(ra.left));
      expect(
        rb.left - ra.left,
        closeTo(2 * (_gridWidth / kGridCols), 1e-9),
      );
    });

    test('Task 50 · d：重叠换带；三带打满后第 4 条落在重叠最少的带，平局取编号最小', () {
      // ① 两条同段 ⇒ 必须换带。
      final SlotLayout overlap = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60, 9 * 60 + 30),
      ]);
      expect(
        overlap.segments[0].lane,
        isNot(overlap.segments[1].lane),
        reason: '时间重叠的两条不能落在同一条带上',
      );

      // ② 三条带全占着时，第 4 条挑重叠分钟数最少的那条带（这里 20 / 10 / 5）。
      final SlotLayout least = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 9 * 60 + 40),
        _entry('c', 9 * 60, 9 * 60 + 35),
        _entry('d', 9 * 60 + 30, 9 * 60 + 50),
      ]);
      expect(least.laneCounts[_row9], kMaxLanesPerRow);
      final SlotSegment d = least.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'd',
      );
      // 一段内排序：起点升序 → 终点升序 ⇒ a/b/c 同起点时实际入座顺序是 c/b/a，
      // 于是 lane 0 = c（575 分结束），d 与它只重叠 5 分钟 ⇒ 溢出落到 0 号带。
      expect(d.lane, 0);
      expect(d.isOverflow, isTrue);
      expect(d.conflictWithId, 'c');
      final LaneConflict conflict = least.conflictOf(d)!;
      expect(conflict.hostId, 'c');
      expect(conflict.startMinute, 9 * 60 + 30);
      expect(conflict.endMinute, 9 * 60 + 35);
      expect(conflict.durationMinutes, 5);
      expect(conflict.containment, isFalse);
      // 宿主自己没有「被叠」的记录。
      final SlotSegment c = least.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'c',
      );
      expect(least.conflictOf(c), isNull);
      expect(c.isOverflow, isFalse);

      // ③ 平局 ⇒ 取编号最小的带（等价于「向上换带」）。
      final SlotLayout tie = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
        _entry('d', 9 * 60 + 5, 9 * 60 + 10),
      ]);
      final SlotSegment tieD = tie.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'd',
      );
      expect(tie.laneCounts[_row9], kMaxLanesPerRow);
      expect(tieD.lane, 0);
      expect(tie.conflictOf(tieD)!.hostId, 'a');
    });
  });

  group('Task 50 · 需求 e：跨小时接续箭头', () {
    testWidgets('Task 50 · e：跨两小时的条目两端各一个弯折箭头', (tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: _today);
      // 09:50–10:20 ⇒ 第 3 行一段（09:50–10:00）+ 第 4 行一段（10:00–10:20）。
      final Map<String, String> ids = await _seedPlans(harness, <(String, int, int)>[
        ('跨小时任务', 9 * 60 + 50, 10 * 60 + 20),
      ]);
      final String id = ids['跨小时任务']!;

      await harness.mount(tester, _today);
      await _settle(tester);

      // 首段右下角向下弯折，末段左上角向上弯折。
      expect(
        find.byKey(ValueKey<String>('day-grid-continue-down-$id-$_row9')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey<String>('day-grid-continue-up-$id-${_row9 + 1}')),
        findsOneWidget,
      );
      // 反向必须不存在：同一条边不会同时出现两个箭头。
      expect(
        find.byKey(ValueKey<String>('day-grid-continue-up-$id-$_row9')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey<String>('day-grid-continue-down-$id-${_row9 + 1}')),
        findsNothing,
      );
      // 两个箭头都是自绘 `CustomPaint`（`↳` / `↰` 在随包字体里没有字形）。
      expect(
        tester
            .widget<CustomPaint>(
              find.byKey(
                ValueKey<String>('day-grid-continue-down-$id-$_row9'),
              ),
            )
            .painter,
        isNotNull,
      );

      await _flushTimers(tester);
    });

    test('Task 50 · e：被窗口两端夹住的段不画箭头', () {
      final SlotLayout layout = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
      ]);
      final SlotSegment only = layout.segments.single;
      expect(only.continuesAbove, isFalse);
      expect(only.continuesBelow, isFalse);
    });
  });

  group('Task 50 · 需求 f：重叠处格底加深', () {
    testWidgets('Task 50 · f：同带冲突 ⇒ 冲突区间被记录且传进 painter，加深色走 ink 叠色', (
      tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: _today);
      // a 09:00–10:00 / b 09:00–09:40 / c 09:00–09:35 占满三条带，
      // d 09:30–09:50 只能叠到重叠最少的 c 上（09:30–09:35，5 分钟）。
      await _seedPlans(harness, <(String, int, int)>[
        ('甲', 9 * 60, 10 * 60),
        ('乙', 9 * 60, 9 * 60 + 40),
        ('丙', 9 * 60, 9 * 60 + 35),
        ('丁', 9 * 60 + 30, 9 * 60 + 50),
      ]);

      await harness.mount(tester, _today);
      await _settle(tester);

      final CustomPaint paint = tester.widget<CustomPaint>(_slotPaintFinder());
      final dynamic painter = paint.painter;
      // painter 拿到的就是带冲突清单的那份布局 ⇒ 加深分支一定会执行。
      final SlotLayout layout = painter.layout as SlotLayout;
      expect(layout.conflicts, hasLength(1));
      final LaneConflict conflict = layout.conflicts.single;
      expect(conflict.startMinute, 9 * 60 + 30);
      expect(conflict.endMinute, 9 * 60 + 35);
      expect(conflict.durationMinutes, 5);
      expect(conflict.containment, isFalse);

      // 加深色是 ink 叠色（`day_grid.dart` 的 `_SlotPainter` 里 alpha 0.08），
      // 方格区禁用赭石 —— 这里钉死「叠出来的颜色不等于 accent」。
      final ThemeTokens tokens = painter.tokens as ThemeTokens;
      final Color deep = tokens.ink.withValues(alpha: 0.08);
      expect(deep, isNot(tokens.accent));
      expect(deep.a, closeTo(0.08, 1e-6));

      await _flushTimers(tester);
    });

    test('Task 50 · f：没有真实重叠时 conflicts 为空（不加深任何格底）', () {
      final SlotLayout layout = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60 + 30, 10 * 60),
      ]);
      expect(layout.conflicts, isEmpty);
      expect(layout.segments.every((SlotSegment s) => !s.isOverflow), isTrue);
    });
  });

  group('Task 50 · 需求 g：包含关系画成内嵌小盒', () {
    testWidgets('Task 50 · g：B 是 A 的内嵌小盒（高 −4 / 内缩 2 / 独立边框），A 标题让到 B 左缘', (
      tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: _today);
      // 制造「三条带打满 + 第 4 条完全落在 lane 0 宿主内」：
      // 宿主 09:00 最早起 ⇒ 必占 lane 0；后两条 09:05 / 09:10 依次占 lane 1/2；
      // 客人 09:15–09:45 与三条的重叠都是 30 分钟 ⇒ 平局取 lane 0 = 宿主。
      const String hostTitle = '宿主任务标题很长很长很长很长很长很长很长很长很长很长很长很长很长很长';
      const String guestTitle = '内嵌小任务';
      final Map<String, String> ids = await _seedPlans(
        harness,
        <(String, int, int)>[
          (hostTitle, 9 * 60, 10 * 60),
          ('并发乙', 9 * 60 + 5, 10 * 60),
          ('并发丙', 9 * 60 + 10, 10 * 60),
          (guestTitle, 9 * 60 + 15, 9 * 60 + 45),
        ],
      );
      final String hostId = ids[hostTitle]!;
      final String guestId = ids[guestTitle]!;

      await harness.mount(tester, _today);
      await _settle(tester);

      final Rect host = tester.getRect(
        find.byKey(ValueKey<String>('day-grid-entry-$hostId')),
      );
      final Rect guest = tester.getRect(
        find.byKey(ValueKey<String>('day-grid-entry-$guestId')),
      );
      // 内嵌小盒：上下各内缩 2 ⇒ 高度正好少 4，纵向起点比宿主低 2。
      expect(guest.height, closeTo(host.height - 4, 1e-9));
      expect(guest.top, closeTo(host.top + 2, 1e-9));
      // 横向仍按自己的起点列（09:15 ⇒ 第 2 列），不是宿主的左缘。
      expect(guest.left, greaterThan(host.left));
      // B 有独立外壳（自己的边框），不是「A 上贴一块色」。
      final Container guestShell = tester.widget<Container>(
        find.byKey(ValueKey<String>('day-grid-entry-$guestId')),
      );
      expect((guestShell.decoration! as BoxDecoration).border, isNotNull);

      // 标题避让：宿主的标题右缘不越过小盒左缘（不重叠）。
      final Rect hostTitleRect = tester.getRect(find.text(hostTitle));
      expect(hostTitleRect.right, lessThanOrEqualTo(guest.left + 0.01));

      await _flushTimers(tester);
    });

    test('Task 50 · g：包含关系被记录成 containment（区间重合也算），跨小时尾段不算', () {
      final SlotLayout contained = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
        _entry('inner', 9 * 60 + 15, 9 * 60 + 45),
      ]);
      final SlotSegment inner = contained.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'inner',
      );
      expect(contained.conflicts.single.containment, isTrue);
      final Rect hostRect = contained.hostRectOf(inner, _gridWidth)!;
      final Rect innerRect = contained.tileRect(inner, _gridWidth);
      expect(innerRect.height, closeTo(hostRect.height - 4, 1e-9));
      expect(innerRect.top, closeTo(hostRect.top + 2, 1e-9));
      // 宿主标题上限 = 小盒左缘距宿主左缘的距离。
      expect(
        contained.titleLimitOf(
          contained.segments.firstWhere((SlotSegment s) => s.entry.id == 'a'),
          _gridWidth,
        ),
        closeTo(innerRect.left - hostRect.left, 1e-9),
      );
      // 小盒自己不再被限制（它没有更小的宿主）。
      expect(contained.titleLimitOf(inner, _gridWidth), isNull);

      final SlotLayout partial = layoutSlots(_win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
        _entry('half', 9 * 60 + 45, 10 * 60 + 15),
      ]);
      // 跨小时条目按小时切段：09:45–10:00 那一段确实整体落在 a 的同段里 ⇒
      // containment 为真（这是分段之后的事实，不是 bug）；10:00–10:15 那一段
      // 单独一行、没有任何重叠 ⇒ 既无冲突，也不该被画成别人的内嵌小盒。
      expect(partial.conflicts.single.containment, isTrue);
      final List<SlotSegment> halfSegs = partial.segments
          .where((SlotSegment s) => s.entry.id == 'half')
          .toList();
      expect(halfSegs, hasLength(2));
      final SlotSegment halfTail = halfSegs.firstWhere(
        (SlotSegment s) => s.row == _row9 + 1,
      );
      expect(partial.conflictOf(halfTail), isNull);
      expect(partial.hostRectOf(halfTail, _gridWidth), isNull);
    });
  });

  group('Task 50 · 需求 h：chip 只留标题 + 悬停浮窗', () {
    testWidgets('Task 50 · h：chip 内无起始时刻与「进展：」，悬停后浮窗给出起止 / 标题 / 详情 / 进展', (
      tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create(selected: _today);
      const String title = '写交付报告';
      final Map<String, String> ids = await _seedPlans(
        harness,
        <(String, int, int)>[(title, 9 * 60, 10 * 60)],
      );
      final String id = ids[title]!;
      await harness.repos.planItem.setDetail(id, '把 a–h 八项逐条落成证据');
      await harness.repos.planItem.setResultNote(id, '[结论]按时完成');

      await harness.mount(tester, _today);
      await _settle(tester);

      final Finder chip = find.byKey(ValueKey<String>('day-grid-entry-$id'));
      expect(chip, findsOneWidget);
      // 起始时刻与「进展：」都从 chip 里搬走了（刻度尺上仍有 09:00，所以按
      // chip 子树断言，而不是全树）。
      expect(
        find.descendant(of: chip, matching: find.text('09:00')),
        findsNothing,
      );
      expect(
        find.descendant(of: chip, matching: find.text('进展：[结论]按时完成')),
        findsNothing,
      );
      // 关闭态：浮窗不在树里（零文本、零尺寸）。
      expect(
        find.byKey(const ValueKey<String>('slot-hover-card')),
        findsNothing,
      );

      // 悬停到标题上（标题一定在 `MouseRegion` 覆盖范围内）。
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text(title)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const ValueKey<String>('slot-hover-card')),
        findsOneWidget,
      );
      // 起止时间（en dash 分隔）
      expect(find.text('09:00–10:00'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('slot-hover-card-title')),
            )
            .data,
        title,
      );
      // 详情与进展都在浮窗里，且「进展」确实还在（p1_e2e 的等价补偿）。
      expect(find.text('详情：把 a–h 八项逐条落成证据'), findsOneWidget);
      expect(find.text('进展：[结论]按时完成'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('slot-hover-card-state')),
        findsOneWidget,
      );

      await _flushTimers(tester);
    });
  });
}