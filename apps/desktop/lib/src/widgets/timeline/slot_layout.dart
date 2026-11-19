// =============================================================================
// 方格时间轴 · 并发车道 + 行高布局（纯函数、无 widget 依赖）
// =============================================================================
// 为什么需要这一层：`slot_state.dart` 的 `DayWindow` 是「一行一小时、行高恒
// 44」的**等行高**模型。它能把「09:15 落在哪一格」算准，却表达不了两件事：
//
//   1. **同一时间段有两条任务** —— 等行高模型里两条条目只能互相盖住；
//   2. **条目的横向起点** —— 单元格坐标（列）与像素的换算在渲染层各写一遍。
//
// 这一层只做三件事，全部是纯函数，不碰 `BuildContext`、不碰 I/O：
//
//   - 把每条条目按「小时行」切成**段**（`SlotSegment`），段是唯一可渲染单位；
//   - 每行内按时间区间做**最少车道贪心装箱**（interval partitioning），
//     得到该行的车道数与该段的车道号；
//   - 由车道数推出**每行的实际行高**，进而给出「分钟 → 像素 / 像素 → 分钟」
//     的可逆换算，供刻度尺、格线、条目、右键落点**共用同一份真源**。
//
// 行高规则：`rowHeight = max(kHourRowHeight, 车道数 × kLaneHeight)`。
// `kLaneHeight = 22` 正是条目外壳的最小高度（见 `day_grid.dart` 的
// `clamp(22.0, ...)`），所以 1 车道、2 车道都是 44 —— **无并发时逐像素不变**，
// 3 车道才长到 66。这让「不改现状一个像素」与「并发要看得全」不再互相打架。
//
// 已知取舍（刻意不做，不是漏做）：车道号是**逐行**算的，跨小时的条目在相邻两行
// 可能换车道。跨行条目本来就只能拆成多段画（行高不同），强求车道号跨行一致
// 会把「最少车道」变成 NP 式的全局装箱，收益只是视觉上的一点点连贯，不值。
// =============================================================================

import 'dart:ui' show Rect;

import 'slot_state.dart';

/// 一条并发车道的高度。
///
/// 取 22 而不是另起一个数：条目外壳的最小高度就是 `22`（`day_grid.dart`
/// 里 `clamp(22.0, ...)` 的下限），2 × 22 = 44 恰是一行的默认高度 ——
/// 「一行正常放得下两条并发任务」这条需求因此是**布局恒等式**，不是巧合。
const double kLaneHeight = 22.0;

/// 条目在**某一行**内的一段投影。
///
/// 一条 09:50–10:20 的条目会产生两段（第 9 行、第 10 行）；一条 09:15–09:45
/// 的条目只有一段。渲染层只认段，不认条目 —— 否则跨行条目的高度无处安放。
class SlotSegment {
  /// 创建一段投影（只由 [layoutSlots] 构造）。
  ///
  /// [lane] 与 [isHead] 由装箱阶段回填：切段时还不知道同行有几条并发，
  /// 先建可变量比「切一遍再重建一遍」少一次整表复制。
  SlotSegment({
    required this.entry,
    required this.row,
    required this.rowStartMinute,
    required this.startMinute,
    required this.endMinute,
    required this.col,
    required this.coveredCols,
    this.lane = 0,
    this.isHead = false,
  });

  /// 来源条目（同一条目的多段共享同一个 `entry.id`）。
  final GridEntry entry;

  /// 行号（`0..window.rows-1`，相对窗口起点，不是绝对小时）。
  final int row;

  /// 本行起点分钟（整点）。
  final int rowStartMinute;

  /// 段起点分钟（已夹到本行内）。
  final int startMinute;

  /// 段终点分钟（已夹到本行内，`> startMinute`）。
  final int endMinute;

  /// 横向起始列（`0..kGridCols-1`）。
  ///
  /// 由「段起点距本行起点多少分钟」换算，因此**起点分钟直接决定左边界** ——
  /// 这是需求「起始时间必须匹配横轴坐标」唯一成立的算法。
  final int col;

  /// 横向覆盖列数（`1..kGridCols-col`）。
  final int coveredCols;

  /// 车道号（`0..车道数-1`），行内从 0 开始自上而下。
  int lane;

  /// 是否是这一条目**第一段**（跨窗口起点被裁掉时也算，因为按可见起点算）。
  ///
  /// 只有 head 段挂条目正文与行级焦点：同一条目挂两个 `Focus` 会抢同一个
  /// `FocusNode`（`_nodeFor(id)` 按 id 缓存），那会让 Tab 序列里出现一个
  /// 焦点跳两次的怪象。
  bool isHead;

  /// 段持续分钟数。
  int get durationMinutes => endMinute - startMinute;

  @override
  String toString() =>
      'SlotSegment(${entry.id} r$row lane$lane '
      '${formatMinute(startMinute)}-${formatMinute(endMinute)} '
      'col$col×$coveredCols head=$isHead)';
}

/// 一天的网格布局：行高表 + 车道数 + 全部段。
///
/// 所有几何查询都从这里出发，保证「刻度尺画在哪」与「条目画在哪」不可能分叉。
class SlotLayout {
  SlotLayout._({
    required this.window,
    required this.rowHeights,
    required this.rowTops,
    required this.laneCounts,
    required this.segments,
  });

  /// 所属窗口。
  final DayWindow window;

  /// 每行实际高度（长度 = `window.rows`）。
  final List<double> rowHeights;

  /// 每行顶部像素偏移（长度 = `window.rows + 1`，最后一项即总高度）。
  final List<double> rowTops;

  /// 每行车道数（长度 = `window.rows`，`0` 表示该行没有条目）。
  final List<int> laneCounts;

  /// 全部段，按「行号升序 → 段起点升序」排列。
  final List<SlotSegment> segments;

  /// 网格总高度。无并发时逐值等于 `window.height`。
  double get totalHeight => rowTops.last;

  /// 分钟 → 行号（夹取到 `0..rows-1`）。
  int rowOfMinute(int minute) =>
      ((minute - window.startMinute) ~/ 60).clamp(0, window.rows - 1);

  /// 分钟 → 顶部像素偏移（按**实际**行高换算，不是固定 44）。
  ///
  /// 唯一的例外在窗口末尾：`window.endMinute` 会落到最后一行的 `frac = 1`，
  /// 因而正好等于 [totalHeight]。
  double yOfMinute(int minute) {
    final int row = rowOfMinute(minute);
    final double rowHeight = rowHeights[row];
    final double frac = (minute - (window.startMinute + row * 60)) / 60;
    return rowTops[row] + frac * rowHeight;
  }

  /// 顶部像素偏移 → 分钟（按实际行高反算，不做 15 分钟对齐）。
  ///
  /// 调用方拿到分钟后仍需自己 `alignMinuteDown`：本层只负责「像素 ↔ 分钟」
  /// 这一步可逆，不替调用方决定吸附粒度。
  int minuteAt(double y) {
    final double clamped = y.clamp(0.0, totalHeight);
    int row = 0;
    while (row < window.rows - 1 && clamped >= rowTops[row + 1]) {
      row++;
    }
    final double rowHeight = rowHeights[row];
    final double frac = rowHeight <= 0
        ? 0.0
        : (clamped - rowTops[row]) / rowHeight;
    return window.startMinute + row * 60 + (frac * 60).round();
  }

  /// 段顶部（相对网格顶部）。
  ///
  /// - 该行有 ≥2 条车道 ⇒ 段占满自己那一条车道（`lane * 22 + 1`，留 1px 缝）；
  /// - 该行只有 1 条车道 ⇒ 段按**真实分钟跨度**落位，与并发之前的视觉一致。
  double segmentTop(SlotSegment segment) {
    final double rowHeight = rowHeights[segment.row];
    if (laneCounts[segment.row] >= 2) {
      return rowTops[segment.row] + segment.lane * kLaneHeight + 1;
    }
    final double frac = (segment.startMinute - segment.rowStartMinute) / 60;
    return rowTops[segment.row] + frac * rowHeight + 1;
  }

  /// 段高度。
  ///
  /// 单车道段取「真实跨度」与 `kLaneHeight` 的**较大者** —— 15 分钟在 44px
  /// 行里只有 11px，低于这个值的条目外壳连一行字都放不下，所以短段保底
  /// 22px（与并发之前的 `clamp(22.0, ...)` 逐像素相同）。
  double segmentHeight(SlotSegment segment) {
    final double rowHeight = rowHeights[segment.row];
    if (laneCounts[segment.row] >= 2) {
      return kLaneHeight - 2;
    }
    final double raw = segment.durationMinutes / 60 * rowHeight;
    final double floor = raw < kLaneHeight ? kLaneHeight : raw;
    return floor - 2;
  }

  /// 段的整块矩形（含横向列覆盖）。
  ///
  /// 左右各留 2px 缝（沿用并发之前的 `left: 2, right: 2`），因此
  /// `width = 覆盖列宽 - 4`。宽度不足时可能为负 —— 由调用方 clip 兜底，
  /// 本层不夹取，免得把几何断言变成「永远是正数」的假绿。
  Rect tileRect(SlotSegment segment, double gridWidth) {
    final double cellWidth = gridWidth / kGridCols;
    return Rect.fromLTWH(
      segment.col * cellWidth + 2,
      segmentTop(segment),
      segment.coveredCols * cellWidth - 4,
      segmentHeight(segment),
    );
  }
}

/// 由窗口与条目算出整份布局。
///
/// [entries] 允许重叠、允许超出窗口、允许乱序；本函数负责夹取、切段、
/// 装箱、排序。空列表必须得到「行高全 44、车道全 0、`totalHeight` 等于
/// `window.height`」—— 这是「无并发不改变现状」的守门条件。
SlotLayout layoutSlots(DayWindow window, List<GridEntry> entries) {
  final List<List<SlotSegment>> rowSegments = List<List<SlotSegment>>.generate(
    window.rows,
    (int _) => <SlotSegment>[],
  );

  for (final GridEntry entry in entries) {
    final int visibleStart = entry.startMinute < window.startMinute
        ? window.startMinute
        : entry.startMinute;
    final int visibleEnd = entry.endMinute > window.endMinute
        ? window.endMinute
        : entry.endMinute;
    if (visibleEnd <= visibleStart) {
      continue;
    }
    final int firstRow = (visibleStart - window.startMinute) ~/ 60;
    final int lastRow = (visibleEnd - 1 - window.startMinute) ~/ 60;
    for (int row = firstRow; row <= lastRow && row < window.rows; row++) {
      if (row < 0) {
        continue;
      }
      final int rowStart = window.startMinute + row * 60;
      final int segStart =
          visibleStart > rowStart ? visibleStart : rowStart;
      final int rowEnd = rowStart + 60;
      final int segEnd = visibleEnd < rowEnd ? visibleEnd : rowEnd;
      if (segEnd <= segStart) {
        continue;
      }
      final int offsetStart = segStart - rowStart;
      final int col = (offsetStart ~/ kSlotMinutes).clamp(0, kGridCols - 1);
      // 向上取整到列边界：09:50–10:00 只占一列（第 4 列），不是半列 + 空列。
      final int colEnd =
          ((segEnd - rowStart + kSlotMinutes - 1) ~/ kSlotMinutes)
              .clamp(col + 1, kGridCols);
      rowSegments[row].add(
        SlotSegment(
          entry: entry,
          row: row,
          rowStartMinute: rowStart,
          startMinute: segStart,
          endMinute: segEnd,
          col: col,
          coveredCols: colEnd - col,
        ),
      );
    }
  }

  final List<int> laneCounts = List<int>.filled(window.rows, 0);
  final List<SlotSegment> placed = <SlotSegment>[];
  final Set<String> seen = <String>{};

  for (int row = 0; row < window.rows; row++) {
    final List<SlotSegment> rowList = rowSegments[row];
    if (rowList.isEmpty) {
      continue;
    }
    // 起点早的先进车道；同起点时短段优先（短段更容易塞进已有缝隙），
    // 最后用 id 兜底，保证同一批输入的输出顺序稳定（测试可复现）。
    rowList.sort((SlotSegment a, SlotSegment b) {
      final int byStart = a.startMinute.compareTo(b.startMinute);
      if (byStart != 0) {
        return byStart;
      }
      final int byEnd = a.endMinute.compareTo(b.endMinute);
      return byEnd != 0 ? byEnd : a.entry.id.compareTo(b.entry.id);
    });

    // 最少车道贪心：按起点升序，塞进「已空出的最早一条车道」，否则开新车道。
    // 对区间图（interval graph）这个贪心即最优，车道数 = 最大并发数。
    final List<int> laneEnds = <int>[];
    for (final SlotSegment segment in rowList) {
      int lane = -1;
      for (int i = 0; i < laneEnds.length; i++) {
        if (laneEnds[i] <= segment.startMinute) {
          lane = i;
          break;
        }
      }
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(segment.endMinute);
      } else {
        laneEnds[lane] = segment.endMinute;
      }
      final bool isHead = seen.add(segment.entry.id);
      segment
        ..lane = lane
        ..isHead = isHead;
      placed.add(segment);
    }
    laneCounts[row] = laneEnds.length;
  }

  final List<double> rowHeights = List<double>.generate(window.rows, (int row) {
    final int lanes = laneCounts[row];
    final double needed = lanes * kLaneHeight;
    return needed > kHourRowHeight ? needed : kHourRowHeight;
  });

  final List<double> rowTops = List<double>.filled(window.rows + 1, 0);
  for (int row = 0; row < window.rows; row++) {
    rowTops[row + 1] = rowTops[row] + rowHeights[row];
  }

  return SlotLayout._(
    window: window,
    rowHeights: rowHeights,
    rowTops: rowTops,
    laneCounts: laneCounts,
    segments: placed,
  );
}