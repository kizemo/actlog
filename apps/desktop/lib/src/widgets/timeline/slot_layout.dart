// =============================================================================
// 方格时间轴 · 并发车道 + 行高布局（纯函数、无 widget 依赖）
// =============================================================================
// 为什么需要这一层：`slot_state.dart` 的 `DayWindow` 是「一行一小时、行高恒
// 44」的**等行高**模型。它能把「09:15 落在哪一格」算准，却表达不了两件事：
//
//   1. **同一时间段有两条任务** —— 等行高模型里两条条目只能互相盖住；
//   2. **条目的横向起点** —— 单元格坐标（列）与像素的换算在渲染层各写一遍。
//
// 这一层只做四件事，全部是纯函数，不碰 `BuildContext`、不碰 I/O：
//
//   - 把每条条目按「小时行」切成**段**（`SlotSegment`），段是唯一可渲染单位；
//   - 每行内按时间区间做**最少车道贪心装箱**（interval partitioning），
//     得到该行的车道数与该段的车道号；车道数封顶 [kMaxLanesPerRow]；
//   - 车道挤不下时**不再开新带**，而是把后来者叠进「重叠分钟数最少」的那条带，
//     并把每段真实重叠记账成 [LaneConflict]（渲染层据此加深格底 / 画内嵌小盒）；
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
// 跨行的一致性改由 [SlotSegment.continuesAbove] / [SlotSegment.continuesBelow]
// 两个弯折箭头标志表达：读者看到箭头就知道「这条在上一行 / 下一行接着走」。
// =============================================================================

import 'dart:ui' show Rect;

import 'slot_state.dart';

/// 一条并发车道的高度。
///
/// 取 22 而不是另起一个数：条目外壳的最小高度就是 `22`（`day_grid.dart`
/// 里 `clamp(22.0, ...)` 的下限），2 × 22 = 44 恰是一行的默认高度 ——
/// 「一行正常放得下两条并发任务」这条需求因此是**布局恒等式**，不是巧合。
const double kLaneHeight = 22.0;

/// 每行最多允许的并发车道数。
///
/// 3 × 22 = 66 已经把单行撑到默认行高的 1.5 倍；再开第 4 条会让整块方格区在
/// 最小视口里彻底失去「一眼看清一天」的意义。超额时段**不**开新带，改为叠进
/// 重叠分钟数最少的那条带，并把重叠区间记进 [LaneConflict] 交给渲染层加深。
const int kMaxLanesPerRow = 3;

/// 内嵌小盒相对宿主段矩形的上下内缩量。
///
/// 需求「B 完全落在 A 内时，B 画成 A 的内嵌小盒」：上下各缩 2px ⇒ 宿主
/// [kLaneContentHeight] 的净高里 guest 占 14px，边框仍能分辨出「盒中有盒」
/// 而不会糊成一块。
const double kContainedInset = 2.0;

/// 段相对车道上下各留出的缝。
const double kLaneContentInset = 2.0;

/// 段净高：一条段在车道上实际占的高度，**与真实分钟跨度无关**。
///
/// Task 51 · 诉求 2：此前单车道段按真实跨度撑高（1 小时 = 44 − 2 = 42，几乎
/// 占满整行 44），读者会把「任务占位」读成「整格就是这个任务」。现在一律
/// 封顶在这里 —— `22 − 2 × 2 = 18`，比车道矮 4px、上下各露一条缝，「占位」
/// 与「格子」从此视觉可分。
const double kLaneContentHeight = kLaneHeight - 2 * kLaneContentInset;

/// 一次**真实的**时间重叠：同一行、同一条车道里两条段盖住了同一段时间。
///
/// 只在车道已满（[kMaxLanesPerRow]）时才产生 —— 有富余车道时装箱本身就会把
/// 两条并发分到不同带上，不构成冲突。渲染层用它做两件事：
///
///   - 需求 f：`[startMinute, endMinute)` 这段格底加深，提示「这里确实挤了」；
///   - 需求 g：[containment] 为真时 guest 改画成 host 的内嵌小盒。
class LaneConflict {
  /// 创建一条冲突记录（只由 [layoutSlots] 构造）。
  const LaneConflict({
    required this.row,
    required this.lane,
    required this.startMinute,
    required this.endMinute,
    required this.hostId,
    required this.guestId,
    required this.containment,
  });

  /// 行号（相对窗口起点）。
  final int row;

  /// 车道号（`0..kMaxLanesPerRow-1`）。
  final int lane;

  /// 重叠区间起点分钟（两段的交集，不是任一段的原始区间）。
  final int startMinute;

  /// 重叠区间终点分钟（`> startMinute`）。
  final int endMinute;

  /// 先落位的那条（被盖住的宿主）。
  final String hostId;

  /// 后落位的那条（叠上去的客人）。
  final String guestId;

  /// guest 的时间区间是否**完全落在** host 内。
  ///
  /// 只有完全包含才画内嵌小盒：部分相交时画小盒会让人误以为它是子项。
  final bool containment;

  /// 重叠分钟数。
  int get durationMinutes => endMinute - startMinute;

  @override
  String toString() =>
      'LaneConflict(r$row lane$lane '
      '${formatMinute(startMinute)}-${formatMinute(endMinute)} '
      '$hostId←$guestId contained=$containment)';
}

/// 条目在**某一行**内的一段投影。
///
/// 一条 09:50–10:20 的条目会产生两段（第 9 行、第 10 行）；一条 09:15–09:45
/// 的条目只有一段。渲染层只认段，不认条目 —— 否则跨行条目的高度无处安放。
class SlotSegment {
  /// 创建一段投影（只由 [layoutSlots] 构造）。
  ///
  /// [lane] / [isHead] / [isOverflow] / [continuesAbove] / [continuesBelow]
  /// 由装箱阶段回填：切段时还不知道同行有几条并发、也不知道上下行有没有
  /// 同一条目的下一段，先建可变量比「切一遍再重建一遍」少一次整表复制。
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
    this.isOverflow = false,
    this.conflictWithId,
    this.continuesAbove = false,
    this.continuesBelow = false,
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

  /// 本段是否因车道已满而**叠在**别人的时间段上（需求 f 的触发条件）。
  bool isOverflow;

  /// 被叠的那条宿主的 id（`isOverflow` 为假时是 null）。
  ///
  /// 只记第一条：同一条 guest 可能同时压住两段，但「跟谁挤了」对读者只需要
  /// 一个指认对象，逐个列出来反而没法在 chip 里表达。
  String? conflictWithId;

  /// 上一条**可见**行里还有同一条目的段（需求 e：段左上角画向上弯折箭头）。
  bool continuesAbove;

  /// 下一条行里还有同一条目的段（需求 e：段右下角画向下弯折箭头）。
  bool continuesBelow;

  /// 段持续分钟数。
  int get durationMinutes => endMinute - startMinute;

  @override
  String toString() =>
      'SlotSegment(${entry.id} r$row lane$lane '
      '${formatMinute(startMinute)}-${formatMinute(endMinute)} '
      'col$col×$coveredCols head=$isHead overflow=$isOverflow '
      'up=$continuesAbove down=$continuesBelow)';
}

/// 一天的网格布局：行高表 + 车道数 + 全部段 + 全部冲突。
///
/// 所有几何查询都从这里出发，保证「刻度尺画在哪」与「条目画在哪」不可能分叉。
class SlotLayout {
  SlotLayout._(
    this._hostOf,
    this._conflictOfGuest, {
    required this.window,
    required this.rowHeights,
    required this.rowTops,
    required this.laneCounts,
    required this.segments,
    required this.conflicts,
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

  /// 全部真实时间重叠（按发现顺序）。
  ///
  /// 空列表 = 没有任何两条任务被叠在同一车道上，此时渲染层不需要加深任何格底。
  final List<LaneConflict> conflicts;

  /// guest 段 → 它的宿主段（仅 `containment == true` 的那些）。
  final Map<SlotSegment, SlotSegment> _hostOf;

  /// guest 段 → 它记录的第一条冲突。
  final Map<SlotSegment, LaneConflict> _conflictOfGuest;

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

  /// 段顶部（相对网格顶部）—— **行内顶对齐**。
  ///
  /// Task 53 · 诉求 1「任务都请尽量从表格第一行开始排列」：段的纵向起点不再
  /// 由起始分钟决定，一律贴**自己所在行**的行顶起排，即
  /// `rowTops[row] + kLaneContentInset`（与 lane 0 的位置同源）。
  ///
  /// 为什么时间不进纵轴：时间已经在**横轴**表达（列 = 15 分钟格，见
  /// [layoutSlots] 里的 `offsetStart ~/ kSlotMinutes`），纵轴只负责表达堆叠。
  /// 按分钟下沉的实际副作用是：净高恒 [kLaneContentHeight] = 18 的芯片在 44px
  /// 行里越靠后起点越低 —— 09:50 起排时 `169.67 + 18 = 187.67` 已越过本行
  /// 行底 176，芯片掉进下一行的色带里。
  ///
  /// - 该行有 ≥2 条车道 ⇒ 段占满自己那一条车道（`lane * kLaneHeight +
  ///   kLaneContentInset`，上下各留 [kLaneContentInset] 缝，与段净高
  ///   [kLaneContentHeight] 配对）；
  /// - 该行只有 1 条车道 ⇒ 与 lane 0 完全同一位置（贴行顶）。
  ///
  /// 「长任务占哪些行」不受影响：行位仍只由 `rowTops` / `rowHeights` 决定，
  /// 而它们只由车道数决定 —— 顶对齐只改行内纵向偏移，不改段的行号。
  double segmentTop(SlotSegment segment) {
    if (laneCounts[segment.row] >= 2) {
      return rowTops[segment.row] + segment.lane * kLaneHeight +
          kLaneContentInset;
    }
    // 单车道：贴行顶，与上面 lane 0 的表达式等价。
    return rowTops[segment.row] + kLaneContentInset;
  }

  /// 段高度。
  ///
  /// Task 51 · 诉求 2：**一律** [kLaneContentHeight]（18），不再按真实分钟跨度
  /// 撑高。此前单车道 1 小时段是 `44 − 2 = 42`，几乎等于整行高 44，看起来像
  /// 「整个格子就是这个任务」；封顶之后段永远比车道矮 4px，上下各露一条缝，
  /// 「任务占位」与「格子本身」在视觉上从此可分。
  ///
  /// [segment] 保留在签名里：调用点都按段取矩形，去掉参数会把「这段多高」的
  /// 语境从 API 上抹掉，且下游测试按段断言。
  double segmentHeight(SlotSegment segment) {
    return kLaneContentHeight;
  }

  /// 段的整块矩形（含横向列覆盖）。
  ///
  /// 左右各留 2px 缝（沿用并发之前的 `left: 2, right: 2`），因此
  /// `width = 覆盖列宽 - 4`。宽度不足时可能为负 —— 由调用方 clip 兜底，
  /// 本层不夹取，免得把几何断言变成「永远是正数」的假绿。
  ///
  /// 被完全包含的 guest（[LaneConflict.containment]）在此换算成宿主的**内嵌
  /// 小盒**：上下各缩 [kContainedInset]，横向仍按自己的起始列 —— 内缩只改
  /// 纵向，否则「盒中有盒」会变成「盒旁边有个盒」，看不出包含关系。
  Rect tileRect(SlotSegment segment, double gridWidth) {
    final double cellWidth = gridWidth / kGridCols;
    final double left = segment.col * cellWidth + 2;
    final double width = segment.coveredCols * cellWidth - 4;
    final SlotSegment? host = _hostOf[segment];
    if (host == null) {
      return Rect.fromLTWH(
        left,
        segmentTop(segment),
        width,
        segmentHeight(segment),
      );
    }
    final double hostHeight = segmentHeight(host);
    final double inset = hostHeight > kContainedInset * 3 ? kContainedInset : 0;
    return Rect.fromLTWH(
      left,
      segmentTop(host) + inset,
      width,
      hostHeight - inset * 2,
    );
  }

  /// [segment] 作为 guest 的冲突记录（不是 guest 则为 null）。
  LaneConflict? conflictOf(SlotSegment segment) => _conflictOfGuest[segment];

  /// [segment] 若被完全包含在另一段里，返回那一段的矩形；否则 null。
  ///
  /// `day_grid` 用它算「宿主标题还能剩多少横向空间」（需求 g 的文字避让）。
  Rect? hostRectOf(SlotSegment segment, double gridWidth) {
    final SlotSegment? host = _hostOf[segment];
    return host == null ? null : tileRect(host, gridWidth);
  }

  /// [segment] 作为**宿主**时，标题最多能占多少横向像素（需求 g 的文字避让）。
  ///
  /// 「B 完全落在 A 内」时 B 被画成 A 的内嵌小盒；若 A 的标题一路铺满，
  /// 就会压到 B 的文字上。这里返回「离宿主最近的第一个内嵌小盒的左边界距
  /// 宿主左边界」的距离 —— 调用方据此把 A 的标题截窄，B 的文字因此始终
  /// 可读（两条任务标题都不重叠）。
  ///
  /// 没有任何内嵌小盒落进本段时返回 `null`（表示不设限，走 `Flexible` 原路）。
  /// 返回 `0` 是合法结果（小盒从宿主左边界起画），此时调用方应当**不画标题**
  /// 而不是画一条零宽的省略号。
  double? titleLimitOf(SlotSegment segment, double gridWidth) {
    final double cellWidth = gridWidth / kGridCols;
    final double ownLeft = segment.col * cellWidth + 2;
    double? limit;
    for (final MapEntry<SlotSegment, SlotSegment> pair in _hostOf.entries) {
      if (!identical(pair.value, segment)) {
        continue;
      }
      final double guestLeft = pair.key.col * cellWidth + 2;
      final double gap = guestLeft - ownLeft;
      if (limit == null || gap < limit) {
        limit = gap;
      }
    }
    return limit;
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
  final List<LaneConflict> conflicts = <LaneConflict>[];
  final Map<SlotSegment, SlotSegment> hostOf =
      Map<SlotSegment, SlotSegment>.identity();
  final Map<SlotSegment, LaneConflict> conflictOfGuest =
      Map<SlotSegment, LaneConflict>.identity();

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
    // 车道数封顶 [kMaxLanesPerRow]：满了之后不再开带，改为叠进重叠最少的那条。
    final List<int> laneEnds = <int>[];
    final List<SlotSegment> placedInRow = <SlotSegment>[];
    for (final SlotSegment segment in rowList) {
      int lane = -1;
      for (int i = 0; i < laneEnds.length; i++) {
        if (laneEnds[i] <= segment.startMinute) {
          lane = i;
          break;
        }
      }
      if (lane >= 0) {
        laneEnds[lane] = segment.endMinute;
      } else if (laneEnds.length < kMaxLanesPerRow) {
        lane = laneEnds.length;
        laneEnds.add(segment.endMinute);
      } else {
        // 三条带全占着 ⇒ 不开第 4 条带。挑重叠分钟数最少的那条叠上去；
        // 平局取编号最小的那条，等价于「向上换带」（需求 d）。
        lane = _leastOverlapLane(placedInRow, segment, laneEnds.length);
        segment.isOverflow = true;
        if (laneEnds[lane] < segment.endMinute) {
          laneEnds[lane] = segment.endMinute;
        }
      }
      final bool isHead = seen.add(segment.entry.id);
      segment
        ..lane = lane
        ..isHead = isHead;
      placedInRow.add(segment);
      placed.add(segment);

      if (!segment.isOverflow) {
        continue;
      }
      // 逐条记真实重叠：只记「同一行、同一车道、时间真的相交」的那些。
      for (final SlotSegment host in placedInRow) {
        if (identical(host, segment) || host.lane != lane) {
          continue;
        }
        final int start = host.startMinute > segment.startMinute
            ? host.startMinute
            : segment.startMinute;
        final int end = host.endMinute < segment.endMinute
            ? host.endMinute
            : segment.endMinute;
        if (end <= start) {
          continue;
        }
        final bool containment =
            segment.startMinute >= host.startMinute &&
            segment.endMinute <= host.endMinute;
        final LaneConflict conflict = LaneConflict(
          row: row,
          lane: lane,
          startMinute: start,
          endMinute: end,
          hostId: host.entry.id,
          guestId: segment.entry.id,
          containment: containment,
        );
        conflicts.add(conflict);
        if (!conflictOfGuest.containsKey(segment)) {
          conflictOfGuest[segment] = conflict;
          segment.conflictWithId = host.entry.id;
        }
        // 内嵌小盒只认第一条「完全包含」自己的宿主。
        if (containment && !hostOf.containsKey(segment)) {
          hostOf[segment] = host;
        }
      }
    }
    laneCounts[row] = laneEnds.length;
  }

  // 跨行箭头（需求 e）：同一条目在上一行 / 下一行还有段 ⇒ 该段两端各加弯折箭头。
  // 用「id@row」集合而不是 `isHead` 反推：`isHead` 只说明「是不是第一条可见段」，
  // 拿它当 `continuesAbove` 在窗口起点被裁的条目上虽然碰巧等价，但语义是错的。
  final Set<String> occupancy = <String>{
    for (final SlotSegment segment in placed)
      '${segment.entry.id}@${segment.row}',
  };
  for (final SlotSegment segment in placed) {
    segment
      ..continuesAbove = occupancy.contains('${segment.entry.id}@${segment.row - 1}')
      ..continuesBelow = occupancy.contains('${segment.entry.id}@${segment.row + 1}');
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
    hostOf,
    conflictOfGuest,
    window: window,
    rowHeights: rowHeights,
    rowTops: rowTops,
    laneCounts: laneCounts,
    segments: placed,
    conflicts: conflicts,
  );
}

/// 车道已满时，为 [guest] 挑一条「重叠分钟数最少」的车道。
///
/// 只看 [placedInRow] 里**已经落位**的段：贪心是单趟的，后面那些段还没定带，
/// 拿它们算重叠等于偷看未来，会让结果随排序细节抖动。
/// 平局取编号最小（`<` 而不是 `<=`），于是同等拥挤时优先向上换带。
int _leastOverlapLane(
  List<SlotSegment> placedInRow,
  SlotSegment guest,
  int laneCount,
) {
  int bestLane = 0;
  int bestOverlap = -1;
  for (int lane = 0; lane < laneCount; lane++) {
    int total = 0;
    for (final SlotSegment host in placedInRow) {
      if (host.lane != lane) {
        continue;
      }
      final int start = host.startMinute > guest.startMinute
          ? host.startMinute
          : guest.startMinute;
      final int end = host.endMinute < guest.endMinute
          ? host.endMinute
          : guest.endMinute;
      if (end > start) {
        total += end - start;
      }
    }
    if (bestOverlap < 0 || total < bestOverlap) {
      bestOverlap = total;
      bestLane = lane;
    }
  }
  return bestLane;
}