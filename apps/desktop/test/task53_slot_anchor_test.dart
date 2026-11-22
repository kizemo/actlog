// apps/desktop/test/task53_slot_anchor_test.dart
//
// Task 53 · 诉求 1（用户原话，逐字引用）：
//   「任务都请尽量从表格第一行开始排列，长任务则和之前所占的行保持一致；」
//
// 判据（控制器裁决：行内**顶对齐**，「第一行」= 任务所在小时行的行顶）：
//   - 单车道段的段顶 == 该行行顶 + 既有 inset 常量 `kLaneContentInset`
//     —— 与多车道分支里 lane 0 的贴顶位置一致，不再按
//     `(startMinute − 行起点) / 60 × 行高` 下沉；
//   - 行位与车道分配**一字不动**：跨小时条目仍按行切段、仍落在原来那几行，
//     长任务所占的行与改动前一致（这是用户的硬要求「和之前所占的行保持一致」）；
//   - 多车道行的堆叠（车道数、行高、车道内纵向位置）不变。
//
// 判别性从哪来：改之前单车道段顶 = `行顶 + 分钟比例 × 行高 + 1`。
// 09:15 会算成 `132 + 11 + 1 = 144`；09:50 会算成约 `169.67`，加上净高 18 之后
// 越过本行行底 `176` —— 正是用户说的「没从第一行开始」。所以下面第 1、2、3 条
// 用例在修复前必然红；第 4、5、6 条钉住「别的都没动」。
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';

/// 造一条投影条目（绝对分钟，与真实数据同构）。
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

/// 第 10 行（10:00–11:00）在默认窗口 `06–24` 里的下标。
const int _row10 = 4;

void main() {
  const DayWindow win = DayWindow.defaults;

  group('诉求 1：段从所在行的行顶起排', () {
    test('09:15 单车道 ⇒ 段顶 = 行顶 + kLaneContentInset，不再按分钟下沉', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 15, 9 * 60 + 30),
      ]);

      final SlotSegment seg = layout.segments.single;
      expect(seg.row, _row9);
      expect(layout.laneCounts[_row9], 1);

      // 期望值从源码既有常量推导，不自造偏移：
      // 多车道分支的 lane 0 就是 `rowTops[row] + 0 × kLaneHeight + kLaneContentInset`。
      final double rowTop = layout.rowTops[seg.row];
      expect(rowTop, 3 * kHourRowHeight);
      expect(layout.segmentTop(seg), closeTo(rowTop + kLaneContentInset, 1e-9));
      // 判别式：改之前 15 分钟会下沉成 `132 + 11 + 1 = 144`。
      expect(layout.segmentTop(seg), 134);
      expect(layout.segmentTop(seg), isNot(closeTo(144, 1e-9)));
    });

    test('同一行内不同起点（09:05 / 09:45）段顶相同', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('early', 9 * 60 + 5, 9 * 60 + 10),
        _entry('late', 9 * 60 + 45, 9 * 60 + 50),
      ]);

      // 两条首尾不相接但同属第 9 行、互不重叠 ⇒ 单车道。
      expect(layout.laneCounts[_row9], 1);
      final SlotSegment early = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'early',
      );
      final SlotSegment late = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'late',
      );

      expect(layout.segmentTop(early), layout.segmentTop(late));
      expect(
        layout.segmentTop(late),
        closeTo(layout.rowTops[_row9] + kLaneContentInset, 1e-9),
      );
      // 横向仍由起点分钟决定（只动纵向，不动横轴语义）。
      expect(early.col, 0);
      expect(late.col, 3);
    });

    test('09:50 短条目不再越出本行行底（段顶 + 净高 ≤ 行底）', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 50, 9 * 60 + 59),
      ]);

      final SlotSegment seg = layout.segments.single;
      expect(seg.row, _row9);
      final double rowBottom = layout.rowTops[seg.row] + layout.rowHeights[seg.row];
      expect(rowBottom, 3 * kHourRowHeight + kHourRowHeight);

      // 改之前段顶约 169.67 + 18 = 187.67 > 176：芯片掉到下一行的色带里。
      final double top = layout.segmentTop(seg);
      expect(top + layout.segmentHeight(seg), lessThanOrEqualTo(rowBottom));
      expect(top, closeTo(layout.rowTops[seg.row] + kLaneContentInset, 1e-9));
      // 行高没被顶对齐改动（44 仍是 44）。
      expect(layout.rowHeights[seg.row], kHourRowHeight);
    });
  });

  group('长任务所占的行与改动前一致', () {
    test('09:50–10:20 仍切两段，仍落第 9 / 第 10 行，列覆盖不变', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60 + 50, 10 * 60 + 20),
      ]);

      // 段数、段的行号、段的分钟边界、段的列覆盖：一条都不能变。
      expect(layout.segments, hasLength(2));
      final SlotSegment first = layout.segments[0];
      final SlotSegment second = layout.segments[1];

      expect(first.row, _row9);
      expect(second.row, _row10);
      expect(layout.rowTops[_row9], 3 * kHourRowHeight);
      expect(layout.rowTops[_row10], 4 * kHourRowHeight);
      expect(layout.totalHeight, kGridHeight);

      expect(first.startMinute, 9 * 60 + 50);
      expect(first.endMinute, 10 * 60);
      expect(first.col, 3);
      expect(first.coveredCols, 1);
      expect(second.startMinute, 10 * 60);
      expect(second.endMinute, 10 * 60 + 20);
      expect(second.col, 0);
      expect(second.coveredCols, 2);

      // 两段各自贴自己那一行的行顶（段内纵向偏移不作为判据）。
      expect(
        layout.segmentTop(first),
        closeTo(layout.rowTops[_row9] + kLaneContentInset, 1e-9),
      );
      expect(
        layout.segmentTop(second),
        closeTo(layout.rowTops[_row10] + kLaneContentInset, 1e-9),
      );
    });

    test('跨行条目与同行并发并存时，行高/车道数仍只由车道数决定', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('cross', 9 * 60 + 30, 10 * 60 + 30),
        _entry('r9', 9 * 60 + 40, 9 * 60 + 50),
        _entry('r10', 10 * 60, 10 * 60 + 10),
      ]);

      // 与改动前逐字相同：两行各 2 车道 ⇒ 行高仍 44、总高仍 792。
      expect(layout.laneCounts[_row9], 2);
      expect(layout.laneCounts[_row10], 2);
      expect(layout.rowHeights[_row9], kHourRowHeight);
      expect(layout.rowHeights[_row10], kHourRowHeight);
      expect(layout.totalHeight, kGridHeight);
      expect(layout.segments, hasLength(4));
    });
  });

  group('多车道堆叠不变', () {
    test('2 条并发 ⇒ 2 车道、行高 44，lane0 贴顶、lane1 错开一个车道高', () {
      final SlotLayout layout = layoutSlots(win, <GridEntry>[
        _entry('a', 9 * 60, 10 * 60),
        _entry('b', 9 * 60, 10 * 60),
      ]);

      expect(layout.laneCounts[_row9], 2);
      expect(layout.rowHeights[_row9], kHourRowHeight);

      final SlotSegment a = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'a',
      );
      final SlotSegment b = layout.segments.firstWhere(
        (SlotSegment s) => s.entry.id == 'b',
      );
      expect(<int>{a.lane, b.lane}, <int>{0, 1});
      expect(
        layout.segmentTop(a),
        closeTo(layout.rowTops[_row9] + kLaneContentInset, 1e-9),
      );
      expect(
        layout.segmentTop(b),
        closeTo(layout.rowTops[_row9] + kLaneHeight + kLaneContentInset, 1e-9),
      );
      expect(
        (layout.segmentTop(b) - layout.segmentTop(a)).abs(),
        closeTo(kLaneHeight, 1e-9),
      );
    });

    test('单车道段顶 == 同行多车道 lane 0 段顶（贴顶位置同源）', () {
      final SlotLayout single = layoutSlots(win, <GridEntry>[
        _entry('only', 9 * 60 + 20, 9 * 60 + 40),
      ]);
      final SlotLayout doubled = layoutSlots(win, <GridEntry>[
        _entry('x', 9 * 60 + 20, 9 * 60 + 40),
        _entry('y', 9 * 60 + 20, 9 * 60 + 40),
      ]);

      expect(single.laneCounts[_row9], 1);
      expect(doubled.laneCounts[_row9], 2);
      final SlotSegment lane0 = doubled.segments.firstWhere(
        (SlotSegment s) => s.lane == 0,
      );
      expect(
        single.segmentTop(single.segments.single),
        doubled.segmentTop(lane0),
      );
    });
  });
}