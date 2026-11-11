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
/// 「赭石纪律」：这里**不得**返回 `AppTokens.accent` / `accentWash`。
Color foregroundOfSlotKind(SlotKind kind) {
  switch (kind) {
    case SlotKind.habit:
      return AppTokens.slotHabitInk;
    case SlotKind.backfill:
      return AppTokens.slotBackfillInk;
    case SlotKind.done:
      return AppTokens.slotDoneInk;
    case SlotKind.plannedOpen:
      return AppTokens.slotPlanInk;
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
      ),
    );
  }
  entries.sort((GridEntry a, GridEntry b) =>
      a.startMinute.compareTo(b.startMinute));
  return entries;
}