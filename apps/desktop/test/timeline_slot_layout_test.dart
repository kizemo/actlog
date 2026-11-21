// =============================================================================
// `slot_layout.dart` 纯函数判据：并发车道、行高撑开、起始分钟 → 列
// =============================================================================
// 这一族用例**不打 widget**，直接对 `layoutSlots` 的返回值下断言。理由：
// 需求 1（同段并发多任务 + 行高放得下 2 条）与需求 3（起点分钟必须决定
// 横向左边界）在像素层是**同一个几何真源**的两半；在纯函数层算清楚，
// widget 层只需要再验「有没有照着这份几何画」。
//
// 每条断言都是「撤掉修复即失败」：
//   - 并发 >1 却仍给单行高 ⇒ `rowHeights[3] == 44` 变红；
//   - 车道不用最少装箱（随便一人一条往下排）⇒ `laneCounts` / 段高变红；
//   - 仍按 `left:2, right:2` 满宽占位 ⇒ `col` / `coveredCols` / `tileRect.left`
//     变红（09:45 会算成 `col 0 × 4`）。
// =============================================================================

import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';

/// 造一条投影条目。
///
/// 起止一律写**绝对分钟**（09:00 ⇒ 540），不写「第几个 15 分钟格」：
/// 需求 3 的错法恰恰是「起点分钟没参与横轴换算」，用绝对分钟写输入
/// 才能让断言与真实数据同构。
GridEntry _entry(
  String id,
  int startMinute,
  int endMinute, {
  SlotKind kind = SlotKind.plannedOpen,
}) {
  return GridEntry(
    id: id,
    title: id,
    startMinute: startMinute,
    endMinute: endMinute,
    kind: kind,
  );
}

/// 第 9 行（09:00–10:00）在默认窗口 `06–24` 里的下标。
const int _row9 = 3;

void main() {
  const DayWindow win = DayWindow.defaults;

  group('无并发 ⇒ 几何与并发前逐像素相同', () {
    test('空列表：行高全 44、车道全 0、总高等窗口高', () {
      final SlotLayout layout = layoutSlots(win, const <GridEntry>[]);

      expect(layout.window, win);
      expect(layout.rowHeights, hasLength(win.rows));
      expect(layout.rowHeights.every((double h) => h == kHourRowHeight), isTrue);
      expect(layout.laneCounts.every((int n) => n == 0), isTrue);
      expect(layout.segments, isEmpty);
      // 792 = 18 行 × 44：这是「不改现状一个像素」的守门数字。
      expect(layout.totalHeight, kGridHeight);
      expect(layout.totalHeight, 792);
    });

    test('单条 09:15 ⇒ 单车道，段顶按真实分钟落位（不吸附到行顶）', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 15, 9 * 60 + 30),
      ]);

      expect(layout.laneCounts[_row9], 1);
      expect(layout.rowHeights[_row9], kHourRowHeight);
      expect(layout.totalHeight, kGridHeight);

      final SlotSegment seg = layout.segments.single;
      expect(seg.row, _row9);
      expect(seg.startMinute, 9 * 60 + 15);
      // 15 分钟 = 0.25 行 = 11px；+1 与并发之前的 `clamp(22.0, ...)` 同源。
      expect(layout.segmentTop(seg), closeTo(3 * 44 + 0.25 * 44 + 1, 1e-9));
      expect(layout.segmentTop(seg), closeTo(144, 1e-9));
      // 短段保底 22 再减 2px 缝 ⇒ 20（既有 `_expectMinTile` 的净高判据）。
      expect(layout.segmentHeight(seg), closeTo(20, 1e-9));
    });

    test('yOfMinute / minuteAt 在等行高窗口里可逆', () {
      final SlotLayout layout = layoutSlots(win, const <GridEntry>[]);

      expect(layout.yOfMinute(9 * 60 + 45), closeTo(165, 1e-9));
      expect(layout.minuteAt(165), 9 * 60 + 45);
      // 0 与总高两个端点必须落在窗口两端（右键在边界上不能算出窗口外的分钟）。
      expect(layout.minuteAt(0), win.startMinute);
      expect(layout.minuteAt(layout.totalHeight), win.endMinute);
    });
  });

  group('需求 1：同一时间段并发多任务', () {
    test('同一时段两条 ⇒ 2 车道，行高仍是 44（一行正好放两条）', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
      ]);

      expect(layout.laneCounts[_row9], 2);
      // 「正常可容纳 2 行任务」在几何上就是 2 × 22 == 44：行高不必变。
      expect(layout.rowHeights[_row9], kHourRowHeight);
      expect(layout.totalHeight, kGridHeight);

      final SlotSegment a = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'a',
      );
      final SlotSegment b = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'b',
      );
      // 两条必须落在**不同**车道，否则还是一层盖一层。
      expect(a.lane, isNot(b.lane));
      expect(<int>{a.lane, b.lane}, <int>{0, 1});
      // 车道高 22、上下各留 1px 缝 ⇒ 段高 20、上下错开 22。
      expect(layout.segmentHeight(a), closeTo(20, 1e-9));
      expect(layout.segmentHeight(b), closeTo(20, 1e-9));
      expect(
        (layout.segmentTop(b) - layout.segmentTop(a)).abs(),
        closeTo(kLaneHeight, 1e-9),
      );
      // 满一小时 ⇒ 两段的横向覆盖完全一致（都是整行 4 列）。
      expect(a.col, 0);
      expect(a.coveredCols, kGridCols);
      expect(b.col, 0);
      expect(b.coveredCols, kGridCols);
    });

    test('同一时段三条 ⇒ 3 车道，该行撑到 66、总高 814', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60 + 10, 9 * 60 + 40),
        _entry('c', 9 * 60 + 20, 9 * 60 + 50),
      ]);

      expect(layout.laneCounts[_row9], 3);
      expect(layout.rowHeights[_row9], 3 * kLaneHeight);
      expect(layout.rowHeights[_row9], 66);
      // 其余 17 行不变 ⇒ 总高只多 22。
      expect(layout.totalHeight, kGridHeight + (66 - kHourRowHeight));
      expect(layout.totalHeight, 814);
      // 行首偏移与总高同源（刻度尺画在 `rowTops` 上，不可能分叉）。
      expect(layout.rowTops[_row9], 3 * 44);
      expect(layout.rowTops[_row9 + 1], 3 * 44 + 66);
    });

    test('最少车道装箱：错开的两条不互相挤到第二车道', () {
      // 09:00–09:30 与 09:30–10:00 首尾相接，不重叠 ⇒ 一条车道就够。
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60 + 30, 10 * 60),
      ]);

      expect(layout.laneCounts[_row9], 1);
      expect(layout.rowHeights[_row9], kHourRowHeight);
      expect(layout.totalHeight, kGridHeight);
      expect(layout.segments.map((SlotSegment s) => s.lane).toSet(), <int>{0});
    });
  });

  group('需求 3：起点分钟决定横向左边界', () {
    test('09:45–10:00 ⇒ 第 3 列起、只占 1 列', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 45, 10 * 60),
      ]);

      final SlotSegment seg = layout.segments.single;
      // (585 − 540) ~/ 15 == 3：起点分钟直接换算成列，不是恒 0。
      expect(seg.col, 3);
      expect(seg.coveredCols, 1);
      // 向上取整到列边界：15 分钟正好 1 列，不会膨胀成 2 列。
      expect(seg.col + seg.coveredCols, kGridCols);
    });

    test('09:00–10:00 ⇒ 第 0 列起、占满 4 列', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
      ]);

      final SlotSegment seg = layout.segments.single;
      expect(seg.col, 0);
      expect(seg.coveredCols, kGridCols);
    });

    test('09:20–09:50 ⇒ 起点落在第 1 格、覆盖 3 列', () {
      // 20 分钟不是 15 的整数倍：起点取 `~/`（落在起点所在的格），终点取
      // `ceil`（覆盖到终点所在的格），保证「看得见的分钟都被格子覆盖」。
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 20, 9 * 60 + 50),
      ]);

      final SlotSegment seg = layout.segments.single;
      expect(seg.col, 1);
      expect(seg.coveredCols, 3);
    });

    test('tileRect 的左缘 = 列宽 × 列号 + 2（不再满宽左贴）', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('early', 9 * 60, 9 * 60 + 15),
        _entry('late', 9 * 60 + 45, 10 * 60),
      ]);

      // 同一行、互不重叠 ⇒ 单车道，但横向各就各位。
      expect(layout.laneCounts[_row9], 1);
      final SlotSegment early = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'early',
      );
      final SlotSegment late = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'late',
      );

      const double gridWidth = 1096; // 任意宽度即可：判据是比值，不是绝对值。
      const double cell = gridWidth / kGridCols;
      expect(cell, 274);

      final Rect earlyRect = layout.tileRect(early, gridWidth);
      final Rect lateRect = layout.tileRect(late, gridWidth);
      expect(earlyRect.left, closeTo(2, 1e-9));
      expect(lateRect.left, closeTo(3 * cell + 2, 1e-9));
      // 宽度 = 覆盖列宽 − 左右各 2px 缝（沿用并发之前的 `left/right: 2`）。
      expect(earlyRect.width, closeTo(cell - 4, 1e-9));
      expect(lateRect.width, closeTo(cell - 4, 1e-9));
      // 短条目不因窄而抬高度：15 分钟仍是净高 20。
      expect(lateRect.height, closeTo(20, 1e-9));
    });
  });

  group('跨行与窗口夹取', () {
    test('09:50–10:20 切成两段，只有第一段是 head', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 50, 10 * 60 + 20),
      ]);

      expect(layout.segments, hasLength(2));
      final SlotSegment first = layout.segments[0];
      final SlotSegment second = layout.segments[1];

      expect(first.row, _row9);
      expect(first.startMinute, 9 * 60 + 50);
      expect(first.endMinute, 10 * 60);
      expect(first.col, 3);
      expect(first.coveredCols, 1);
      expect(first.isHead, isTrue);

      expect(second.row, 10 - 6);
      expect(second.startMinute, 10 * 60);
      expect(second.endMinute, 10 * 60 + 20);
      expect(second.col, 0);
      expect(second.coveredCols, 2);
      // 续段不挂正文/焦点：同一条目挂两个 Focus 会抢同一个 FocusNode。
      expect(second.isHead, isFalse);
    });

    test('窗口外的条目被忽略；与窗口相交的被夹到窗口内', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        // 02:00–03:00 完全在 06–24 之外。
        _entry('before', 2 * 60, 3 * 60),
        // 05:00–06:30 只露出 06:00–06:30。
        _entry('edge', 5 * 60, 6 * 60 + 30),
      ]);

      expect(layout.segments, hasLength(1));
      final SlotSegment seg = layout.segments.single;
      expect(seg.entry.id, 'edge');
      expect(seg.row, 0);
      expect(seg.startMinute, win.startMinute);
      expect(seg.endMinute, 6 * 60 + 30);
      expect(seg.col, 0);
      expect(seg.coveredCols, 2);
      expect(seg.isHead, isTrue);
    });

    test('行内车道号逐行算：跨行条目在相邻行不必同车道', () {
      // 09:30–10:30 跨两行；另有两段各只占一行。两行各自都是 2 条并发，
      // 车道号必须**按行独立**从 0 连续编到 n−1（不出现空车道）。
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('cross', 9 * 60 + 30, 10 * 60 + 30),
        _entry('r9', 9 * 60 + 40, 9 * 60 + 50),
        _entry('r10', 10 * 60, 10 * 60 + 10),
      ]);

      expect(layout.laneCounts[_row9], 2);
      expect(layout.laneCounts[10 - 6], 2);
      // 同一行内车道号必须从 0 连续到 n-1。
      for (final int row in <int>[_row9, 10 - 6]) {
        final Set<int> lanes = layout.segments
            .where((SlotSegment s) => s.row == row)
            .map((SlotSegment s) => s.lane)
            .toSet();
        expect(lanes, <int>{0, 1});
      }
    });

    test('乱序输入得到确定性输出（按行号 → 段起点排序）', () {
      final SlotLayout a = layoutSlots(win, <GridEntry>[
        _entry('b', 10 * 60, 10 * 60 + 15),
        _entry('a', 9 * 60 + 30, 9 * 60 + 45),
        _entry('c', 9 * 60, 9 * 60 + 15),
      ]);
      final SlotLayout b = layoutSlots(win, <GridEntry>[
        _entry('c', 9 * 60, 9 * 60 + 15),
        _entry('a', 9 * 60 + 30, 9 * 60 + 45),
        _entry('b', 10 * 60, 10 * 60 + 15),
      ]);

      List<String> trace(SlotLayout l) => l.segments
          .map((SlotSegment s) => '${s.row}/${s.startMinute}/${s.entry.id}')
          .toList();
      expect(trace(a), trace(b));
      expect(trace(a), <String>[
        '3/540/c',
        '3/570/a',
        '4/600/b',
      ]);
    });
  });

  group('需求 a–d：每小时最多三条带 + 溢出叠带', () {
    test('四条同段并发 ⇒ 不开第 4 条带，行高仍 66、多出一条 LaneConflict', () {
      // 需求 a：一行最多 3 条视觉带；第 4 条不再把行撑高（88），而是叠回
      // 重叠最少的一条带里，由格底加深提示「这里叠了两条」。
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 9 * 60 + 30),
        _entry('b', 9 * 60, 9 * 60 + 30),
        _entry('c', 9 * 60, 9 * 60 + 30),
        _entry('d', 9 * 60, 9 * 60 + 30),
      ]);

      expect(kMaxLanesPerRow, 3);
      expect(layout.laneCounts[_row9], 3);
      // 66 而不是 88：行高封顶在三条带。
      expect(layout.rowHeights[_row9], 3 * kLaneHeight);
      expect(layout.totalHeight, 814);

      final SlotSegment a = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'a',
      );
      final SlotSegment d = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'd',
      );
      expect(d.isOverflow, isTrue);
      // 三条带的重叠分钟数都是 30 ⇒ 平局取编号最小的带，等价于「向上换带」。
      expect(d.lane, 0);
      expect(layout.segmentHeight(d), closeTo(20, 1e-9));

      // 需求 f：冲突有记录，且只记 guest 侧（a 不是 guest）。
      expect(layout.conflicts, hasLength(1));
      final LaneConflict conflict = layout.conflicts.single;
      expect(conflict.guestId, 'd');
      expect(conflict.hostId, 'a');
      expect(conflict.row, _row9);
      expect(conflict.lane, 0);
      expect(conflict.startMinute, 9 * 60);
      expect(conflict.endMinute, 9 * 60 + 30);
      expect(conflict.durationMinutes, 30);
      // 四条完全同段 ⇒ 区间相等也算「完全落在 host 内」（⊆ 的退化情形）⇒
      // containment 为真，guest 画成宿主的内嵌小盒，视觉上才能把两条区分开。
      expect(conflict.containment, isTrue);
      expect(d.conflictWithId, 'a');
      expect(layout.conflictOf(d)?.hostId, 'a');
      expect(layout.conflictOf(a), isNull);
    });

    test('第 4 条被完全包含 ⇒ 画成宿主的内嵌小盒，高度少 4', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
        _entry('inner', 9 * 60 + 30, 9 * 60 + 50),
      ]);

      expect(layout.laneCounts[_row9], 3);
      final SlotSegment a = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'a',
      );
      final SlotSegment inner = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'inner',
      );
      expect(inner.isOverflow, isTrue);
      // 三条带的重叠分钟数都是 20 ⇒ 平局取第 0 条带，也就是 a。
      expect(inner.lane, a.lane);
      expect(layout.conflicts.single.containment, isTrue);
      expect(layout.conflicts.single.hostId, 'a');

      const double gridWidth = 1096;
      final Rect hostRect = layout.hostRectOf(inner, gridWidth)!;
      expect(hostRect, layout.tileRect(a, gridWidth));
      final Rect innerRect = layout.tileRect(inner, gridWidth);
      const double cell = gridWidth / kGridCols;
      // 需求 g：上下各缩 2 ⇒ 高度 = 宿主高度 − 4；横向不缩（否则「盒中有盒」
      // 会变成「盒旁边有个盒」）。
      expect(innerRect.height, closeTo(hostRect.height - 4, 1e-9));
      expect(innerRect.top, closeTo(hostRect.top + 2, 1e-9));
      expect(inner.col, 2);
      expect(innerRect.left, closeTo(2 * cell + 2, 1e-9));
    });

    test('titleLimitOf：无内嵌小盒为 null；有则等于小盒左缘距宿主左缘', () {
      final SlotLayout plain = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
      ]);
      expect(plain.titleLimitOf(plain.segments.single, 1096), isNull);

      final SlotLayout nested = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
        _entry('c', 9 * 60, 10 * 60),
        _entry('inner', 9 * 60 + 30, 9 * 60 + 50),
      ]);
      const double gridWidth = 1096;
      const double cell = gridWidth / kGridCols;
      final SlotSegment a = nested.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'a',
      );
      final SlotSegment inner = nested.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'inner',
      );
      // inner 从第 2 列起 ⇒ 距 a 的左缘正好 2 个列宽，宿主标题据此截窄。
      expect(nested.titleLimitOf(a, gridWidth), closeTo(2 * cell, 1e-9));
      // 自身作为 guest 的段不会给自己设限。
      expect(nested.titleLimitOf(inner, gridWidth), isNull);
    });
  });

  group('需求 e：跨行段两端的接续标记', () {
    test('09:50–10:20 ⇒ 首段 continuesBelow、次段 continuesAbove', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 50, 10 * 60 + 20),
      ]);

      final SlotSegment first = layout.segments[0];
      final SlotSegment second = layout.segments[1];
      expect(first.continuesAbove, isFalse);
      expect(first.continuesBelow, isTrue);
      expect(second.continuesAbove, isTrue);
      expect(second.continuesBelow, isFalse);
    });

    test('被窗口上沿夹住的段：没有上一行同条目 ⇒ continuesAbove 仍为假', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('edge', 5 * 60, 6 * 60 + 30),
      ]);

      final SlotSegment seg = layout.segments.single;
      expect(seg.continuesAbove, isFalse);
      expect(seg.continuesBelow, isFalse);
    });
  });
}