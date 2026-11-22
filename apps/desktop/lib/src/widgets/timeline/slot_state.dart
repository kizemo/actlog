// =============================================================================
// 方格时间轴 · 纯状态判定（无副作用、无 I/O）
// =============================================================================
// 「计划 vs 回填」**不落库**：库里只有 `planned_start` / `planned_end` 两个
// 当日分钟数，回填是**读取时按「现在」派生**出来的展示态。因此这一层必须
// 保持纯函数 —— 同一行数据 + 同一时刻，永远得到同一个格子态。
//
// 判定顺序是铁律：`habit → backfill → done → plannedOpen`。
// 回填行默认 `status='done'`（用户是在补记已经发生的事），先判 done 会把
// 回填吞进「计划已完成」，两种语义就再也分不开了。
// =============================================================================

import 'dart:ui' show Color;

import 'package:core_db/core_db.dart' hide Todo, nowMillis;
import 'package:core_domain/core_domain.dart';

import '../../theme/app_tokens.dart';

/// 一格的分钟数。运行时不可切换（5 分钟档只保留这个常量的替换位）。
const int kSlotMinutes = 15;

/// 网格起点小时（含）。纵轴 `06:00–24:00`。
const int kGridStartHour = 6;

/// 网格终点小时（不含）。
const int kGridEndHour = 24;

/// 纵轴行数：每小时一行，`06:00–24:00` 共 18 行。
const int kGridRows = kGridEndHour - kGridStartHour;

/// 横轴列数：一行 60 分钟 ÷ 15 分钟 = 4 列。
const int kGridCols = 60 ~/ kSlotMinutes;

/// 一格总宽度为 4 列 ⇒ 一屏 72 格。
const int kGridSlots = kGridRows * kGridCols;

/// 每小时行高（22 × 2 → 44 是原型实测的舒适档）。
const double kHourRowHeight = 44;

/// 网格总高度（不含表头）。
const double kGridHeight = kGridRows * kHourRowHeight;

/// 每天计划窗口：纵轴可见区间的起止**整点小时**。
///
/// 为什么以整点为界而不是 15 分钟：网格的纵向单位就是「一小时一行」
/// （[kHourRowHeight]）。起点若落在 06:15，整点数字与刻度线就整体错开
/// 15 分钟 —— 用户读到的 `07:00` 实际压在 06:45 那格上，比不参数化更糟。
/// 设置页因此只给整点档（见 `settings_page.dart`）。
///
/// 默认 `6..24` 令 [rows] = 18、[height] = 792，与 [kGridRows] /
/// [kGridHeight] **逐值相同** —— 参数化不允许改变现状一个像素（B8）。
///
/// 本类的常量 [kGridStartHour] 等**保持原义不动**：它们是「默认窗口」的
/// 真源，`_minuteAt` 那些纯函数与 `timeline_slot_state_test.dart` 的断言
/// 都还压在它们身上，改成变量会把一批既有测试变成假绿。
class DayWindow {
  /// 创建窗口（非法入参请走 [DayWindow.fromHours]，那里会夹取）。
  const DayWindow({required this.startHour, required this.endHour})
      : assert(startHour >= 0 && startHour < 24),
        assert(endHour > 0 && endHour <= 24),
        assert(endHour > startHour);

  /// 从任意整点取窗口：越界夹取；`end <= start` 时保底给 1 小时。
  factory DayWindow.fromHours(int startHour, int endHour) {
    final int start = startHour.clamp(0, 23);
    final int end = endHour <= start
        ? (start + 1).clamp(1, 24)
        : endHour.clamp(1, 24);
    return DayWindow(startHour: start, endHour: end);
  }

  /// 默认窗口 `06:00–24:00`（与参数化之前的硬编码完全一致）。
  static const DayWindow defaults = DayWindow(
    startHour: kGridStartHour,
    endHour: kGridEndHour,
  );

  /// 起点小时（含）。
  final int startHour;

  /// 终点小时（不含）。
  final int endHour;

  /// 起点分钟数。
  int get startMinute => startHour * 60;

  /// 终点分钟数（`24:00` ⇒ 1440）。
  int get endMinute => endHour * 60;

  /// 行数（每小时一行）。
  int get rows => endHour - startHour;

  /// 网格总高度。
  double get height => rows * kHourRowHeight;

  /// 窗口内的整点小时数（含起点，不含终点）。
  Iterable<int> get hours sync* {
    for (int hour = startHour; hour < endHour; hour++) {
      yield hour;
    }
  }

  /// 把分钟夹进 `[startMinute, endMinute - kSlotMinutes]`。
  int clampMinute(int minute) =>
      minute.clamp(startMinute, endMinute - kSlotMinutes);

  /// 该分钟是否落在窗口内（左闭右开）。
  bool contains(int minute) => minute >= startMinute && minute < endMinute;

  /// 分钟 → 行号（夹取到 `0..rows-1`）。
  int rowOf(int minute) => ((minute - startMinute) ~/ 60).clamp(0, rows - 1);

  /// 分钟 → 顶部像素偏移。
  double yOf(int minute) => (minute - startMinute) / 60 * kHourRowHeight;

  /// 顶部像素偏移 → 分钟（不做夹取，调用方自行 [clampMinute]）。
  int minuteAt(double y) => startMinute + (y / kHourRowHeight * 60).round();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayWindow &&
          other.startHour == startHour &&
          other.endHour == endHour;

  @override
  int get hashCode => Object.hash(startHour, endHour);

  @override
  String toString() => 'DayWindow($startHour..$endHour)';
}

/// 四态。**枚举顺序即判定优先级**，`slotKindOf` 按这个顺序短路。
enum SlotKind {
  /// 习惯入格。
  habit,

  /// 回填（计划起点已过 / 整日已成过去）。
  backfill,

  /// 计划已完成。
  done,

  /// 已排未做。
  plannedOpen,
}

/// 当日分钟数（0–1439）。`planned_start` / `planned_end` 用的就是这个口径。
int minuteOfDay(DateTime time) => time.hour * 60 + time.minute;

/// 把分钟数夹到网格可见区间 `[kGridStartHour*60, 1440]`。
int clampToGrid(int minute) {
  const int low = kGridStartHour * 60;
  if (minute < low) {
    return low;
  }
  if (minute > 24 * 60) {
    return 24 * 60;
  }
  return minute;
}

/// 时间格 → 分钟数（格首）。越界返回网格边界，绝不抛。
int minuteOfSlot(int row, int col) {
  final int r = row.clamp(0, kGridRows - 1);
  final int c = col.clamp(0, kGridCols - 1);
  return clampToGrid((kGridStartHour + r) * 60 + c * kSlotMinutes);
}

/// 分钟数 → 行（0–17）。用于命中测试与拖拽落点。
int rowOfMinute(int minute) {
  final int clamped = clampToGrid(minute);
  final int row = (clamped - kGridStartHour * 60) ~/ 60;
  return row.clamp(0, kGridRows - 1);
}

/// 分钟数 → 列（0–3）。
int colOfMinute(int minute) {
  final int clamped = clampToGrid(minute);
  final int withinHour = clamped % 60;
  final int col = withinHour ~/ kSlotMinutes;
  return col.clamp(0, kGridCols - 1);
}

/// 对齐到最近的格首（向下取整），保证 `planned_start` 永远落在格线上。
int alignMinuteDown(int minute) {
  final int clamped = clampToGrid(minute);
  return clamped - clamped % kSlotMinutes;
}

/// 对齐到格尾（向上取整），且至少一格宽。
int alignMinuteUp(int minute) {
  final int clamped = clampToGrid(minute);
  final int up = clamped % kSlotMinutes == 0
      ? clamped
      : clamped + (kSlotMinutes - clamped % kSlotMinutes);
  return up > 24 * 60 ? 24 * 60 : up;
}

/// `HH:mm`（分钟数 → 显示）。
String formatMinute(int minute) {
  final int clamped = clampToGrid(minute);
  final int hour = clamped ~/ 60;
  final int rest = clamped % 60;
  final String hh = hour.toString().padLeft(2, '0');
  final String mm = rest.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// 计划起点是否已经「成为过去」，即该格是否算回填。
///
/// - [date] 早于 [todayIso] ⇒ 整日回填（true）；
/// - [date] 晚于 [todayIso] ⇒ 全不算（false）；
/// - 同一天 ⇒ `plannedStart <= nowMinute` 就算。
///
/// ISO `YYYY-MM-DD` 的字典序等于时间序，所以直接 `compareTo`。
bool isBackfill({
  required String date,
  required int plannedStart,
  required String todayIso,
  required int nowMinute,
}) {
  final int cmp = date.compareTo(todayIso);
  if (cmp < 0) {
    return true;
  }
  if (cmp > 0) {
    return false;
  }
  return plannedStart <= nowMinute;
}

/// 一格该用哪一态。**顺序不可换**，见文件头注释。
SlotKind slotKindOf({
  required String status,
  required bool isHabitRef,
  required bool backfill,
}) {
  if (isHabitRef) {
    return SlotKind.habit;
  }
  if (backfill) {
    return SlotKind.backfill;
  }
  if (status == PlanStatus.done.code) {
    return SlotKind.done;
  }
  return SlotKind.plannedOpen;
}

/// 四态字形（形状通道）。
///
/// 四个字形都已在本机字体矩阵里实测有覆盖（见 `reports/task29-glyph-matrix.txt`），
/// 但它们**都不在 Inter 里**，所以渲染时必须在 `TextStyle` 上显式给
/// `fontFamily: AppFonts.body` + `fontFamilyFallback: AppFonts.bodyFallback`，
/// 不能靠继承。
///
/// 回填用 `U+25B6`（黑右三角）而**不是** `U+25B8`（白右小三角）：
/// 后者在同一次实测里覆盖 0/9，换了机器就是豆腐块。
String glyphOfSlotKind(SlotKind kind) {
  switch (kind) {
    case SlotKind.habit:
      return '\u25CF';
    case SlotKind.backfill:
      return '\u25B6';
    case SlotKind.done:
      return '\u2713';
    case SlotKind.plannedOpen:
      return '\u25CB';
  }
}

/// 四态中文状态词（文字通道）。
///
/// 与 [glyphOfSlotKind] 成对出现：只靠形状会要求用户先学会图例，
/// 只靠颜色则对色觉障碍不友好，两条通道同时给才叫冗余可辨识。
String stateLabelOfSlotKind(SlotKind kind) {
  switch (kind) {
    case SlotKind.habit:
      return '打卡';
    case SlotKind.backfill:
      return '回填';
    case SlotKind.done:
      return '完成';
    case SlotKind.plannedOpen:
      return '计划';
  }
}

/// 四态的条目前景色（字形、状态词、左缘竖条、完成态删除线共用）。
///
/// 与格底 `colorOfSlotKind` 成对；四组对比度见 `TOKENS.md` §8.2。
/// 「赭石纪律」：这里**不得**返回 `tokens.accent` / `tokens.accentWash`。
///
/// 为什么颜色由调用方传入而不是在这里读全局：本层是**纯函数**（见文件头），
/// 一旦引入 `BuildContext` 就被绑死在 widget 树上。`ThemeTokens` 是值对象，
/// 传参不破坏纯性，深浅两档也由调用方（`day_grid.dart` 的 `build`）决定。
Color foregroundOfSlotKind(SlotKind kind, ThemeTokens tokens) {
  switch (kind) {
    case SlotKind.habit:
      return tokens.slotHabitInk;
    case SlotKind.backfill:
      return tokens.slotBackfillInk;
    case SlotKind.done:
      return tokens.slotDoneInk;
    case SlotKind.plannedOpen:
      return tokens.slotPlanInk;
  }
}

/// 一条已排期的计划条目在网格里的投影。
///
/// 只有 `planned_start` 与 `planned_end` **都**有值的条目才入格；
/// 其余条目（历史 P1 数据、未排期的待办快照）留在别处展示，不硬塞进格子。
class GridEntry {
  /// 创建一条投影。
  const GridEntry({
    required this.id,
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.kind,
    this.isDone,
  });

  /// `plan_item.id`（拖动与改起止都按这个 id 定位，**不新建行**）。
  final String id;

  /// 格子里显示的一行文字。
  final String title;

  /// 当日起始分钟。
  final int startMinute;

  /// 当日结束分钟（> [startMinute]）。
  final int endMinute;

  /// 四态。
  final SlotKind kind;

  /// 显式完成位：`plan_item.status == 'done'` 的原样投影。
  ///
  /// 为什么必须**显式传**，不能从 [kind] 反推：[kind] 的判定顺序是
  /// `habit → backfill → done → plannedOpen`（见 [slotKindOf]，铁律写在文件头）。
  /// 任何「计划起点已到」的条目 —— 也就是用户最常打勾的那批 —— [kind] 恒为
  /// [SlotKind.backfill]，即便 `status` 已经是 `done`。完成态从 [kind] 上**看不出来**，
  /// 所以「打勾后底色退到 `slotDone`」只能靠这个独立位。
  ///
  /// `null` 表示按旧语义由 [kind] 推断（`kind == SlotKind.done` ⇒ 已完成），
  /// 因此不传它的既有调用点行为逐字不变；生产路径（[gridEntriesOf]）必须传。
  final bool? isDone;

  /// 该条目是否已完成 —— 底色按它取 `slotDone`（见 `day_grid.dart` 的 `fillOfSlot`）。
  bool get completed => isDone ?? kind == SlotKind.done;

  /// 持续分钟数。
  int get durationMinutes => endMinute - startMinute;
}

/// 把某天的 `plan_item` 投影成网格条目。
///
/// 读取时就地派生四态，不写库；`todayIso` / `nowMinute` 由调用方注入，
/// 便于测试钉死「现在」。
List<GridEntry> gridEntriesOf(
  List<PlanItemData> items, {
  required String date,
  required String todayIso,
  required int nowMinute,
}) {
  final List<GridEntry> entries = <GridEntry>[];
  for (final PlanItemData item in items) {
    final int? start = item.plannedStart;
    final int? end = item.plannedEnd;
    if (start == null || end == null || end <= start) {
      continue;
    }
    final int clampedStart = clampToGrid(start);
    final int clampedEnd = clampToGrid(end);
    if (clampedEnd <= clampedStart) {
      continue;
    }
    entries.add(
      GridEntry(
        id: item.id,
        title: item.title,
        startMinute: clampedStart,
        endMinute: clampedEnd,
        kind: slotKindOf(
          status: item.status,
          isHabitRef: item.isHabitRef == 1,
          backfill: isBackfill(
            date: date,
            plannedStart: clampedStart,
            todayIso: todayIso,
            nowMinute: nowMinute,
          ),
        ),
        // 完成态单独走一条通道：`kind` 里它已经被 `backfill` 抢先吞掉了
        // （见 [GridEntry.isDone]）。
        isDone: item.status == PlanStatus.done.code,
      ),
    );
  }
  entries.sort((GridEntry a, GridEntry b) =>
      a.startMinute.compareTo(b.startMinute));
  return entries;
}
