// 方格时间轴 · 纯函数层单测（不碰数据库、不碰 provider）
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';

void main() {
  group('网格几何常量', () {
    test('纵轴 06:00–24:00 = 18 行，横轴 15 分钟 = 4 列，合计 72 格', () {
      expect(kGridStartHour, 6);
      expect(kGridEndHour, 24);
      expect(kSlotMinutes, 15);
      expect(kGridRows, 18);
      expect(kGridCols, 4);
      expect(kGridSlots, 72);
      expect(kGridRows * kGridCols, kGridSlots);
    });

    test('行高 44 → 网格总高 792', () {
      expect(kHourRowHeight, 44);
      expect(kGridHeight, 792);
      expect(kGridHeight, kGridRows * kHourRowHeight);
    });
  });

  group('分钟 ↔ 行列', () {
    test('minuteOfDay 取「当日第几分钟」', () {
      expect(minuteOfDay(DateTime(2026, 11, 12, 0, 0)), 0);
      expect(minuteOfDay(DateTime(2026, 11, 12, 9, 30)), 570);
      expect(minuteOfDay(DateTime(2026, 11, 12, 23, 59)), 1439);
    });

    test('minuteOfSlot 首格是 06:00，末格是 23:45', () {
      expect(minuteOfSlot(0, 0), 360);
      expect(minuteOfSlot(0, 1), 375);
      expect(minuteOfSlot(1, 0), 420);
      expect(minuteOfSlot(kGridRows - 1, kGridCols - 1), 1425);
    });

    test('rowOfMinute 落在整点边界上', () {
      expect(rowOfMinute(360), 0);
      expect(rowOfMinute(419), 0);
      expect(rowOfMinute(420), 1);
      expect(rowOfMinute(1425), 17);
    });

    test('colOfMinute 落在刻钟边界上', () {
      expect(colOfMinute(360), 0);
      expect(colOfMinute(374), 0);
      expect(colOfMinute(375), 1);
      expect(colOfMinute(405), 3);
    });

    test('rowOfMinute / colOfMinute 互相还原 minuteOfSlot', () {
      for (int row = 0; row < kGridRows; row++) {
        for (int col = 0; col < kGridCols; col++) {
          final int minute = minuteOfSlot(row, col);
          expect(rowOfMinute(minute), row);
          expect(colOfMinute(minute), col);
        }
      }
    });
  });

  group('对齐与格式化', () {
    test('alignMinuteDown 向下取整到刻钟', () {
      expect(alignMinuteDown(360), 360);
      expect(alignMinuteDown(374), 360);
      expect(alignMinuteDown(375), 375);
      expect(alignMinuteDown(1429), 1425);
    });

    test('alignMinuteUp 向上取整到刻钟', () {
      expect(alignMinuteUp(360), 360);
      expect(alignMinuteUp(361), 375);
      expect(alignMinuteUp(375), 375);
    });

    test('对齐是幂等的', () {
      for (int minute = 360; minute <= 1440; minute += 7) {
        final int down = alignMinuteDown(minute);
        final int up = alignMinuteUp(minute);
        expect(alignMinuteDown(down), down);
        expect(alignMinuteUp(up), up);
        expect(down <= minute, isTrue);
        expect(up >= minute, isTrue);
      }
    });

    test('formatMinute 补零成 HH:MM', () {
      expect(formatMinute(360), '06:00');
      expect(formatMinute(375), '06:15');
      expect(formatMinute(1425), '23:45');
    });
  });

  group('夹取进网格范围', () {
    test('早于 06:00 一律夹到网格下界', () {
      expect(clampToGrid(0), 360);
      expect(clampToGrid(-120), 360);
    });

    test('晚于 24:00 一律夹到网格上界，且始终落在格线上', () {
      final int clamped = clampToGrid(5000);
      expect(clamped, lessThanOrEqualTo(kGridEndHour * 60));
      expect(clamped, greaterThanOrEqualTo(kGridStartHour * 60));
      expect(clamped % kSlotMinutes, 0);
    });

    test('范围内原样返回', () {
      expect(clampToGrid(570), 570);
      expect(clampToGrid(1425), 1425);
    });
  });

  // 追加：派生状态真源的两个判据（FAIL-3 点名的 0 命中项）。
  // 网格画哪一态、回填要不要默认打勾，全都走这两个函数 —— 它们没被测到，
  // 「四态优先级」和「回填」就只是注释里的承诺。
  group('回填判定 isBackfill', () {
    test('跨日只看日期：早于今天整日回填，晚于今天全不算', () {
      // 过去日哪怕排在深夜，也算回填。
      expect(
        isBackfill(
          date: '2026-11-08',
          plannedStart: 1439,
          todayIso: '2026-11-09',
          nowMinute: 0,
        ),
        isTrue,
      );
      // 未来日哪怕排在清晨，也不算。
      expect(
        isBackfill(
          date: '2026-11-10',
          plannedStart: 360,
          todayIso: '2026-11-09',
          nowMinute: 1439,
        ),
        isFalse,
      );
      // 字典序 == 时间序：跨月、跨年都不能判反。
      expect(
        isBackfill(
          date: '2026-10-31',
          plannedStart: 900,
          todayIso: '2026-11-01',
          nowMinute: 0,
        ),
        isTrue,
      );
      expect(
        isBackfill(
          date: '2025-12-31',
          plannedStart: 900,
          todayIso: '2026-01-01',
          nowMinute: 0,
        ),
        isTrue,
      );
    });

    test('同日按起点减此刻：早于 / 正好等于算回填，晚于不算', () {
      bool at(int plannedStart, int nowMinute) => isBackfill(
            date: '2026-11-09',
            plannedStart: plannedStart,
            todayIso: '2026-11-09',
            nowMinute: nowMinute,
          );

      expect(at(599, 600), isTrue);
      // 边界：正好落在当前时刻算回填（`<=`，不是 `<`）—— 改成 `<` 这条会红。
      expect(at(600, 600), isTrue);
      expect(at(601, 600), isFalse);
      // 极值不能翻车。
      expect(at(0, 0), isTrue);
      expect(at(1439, 1439), isTrue);
      expect(at(1439, 0), isFalse);
    });
  });

  group('四态派生 slotKindOf', () {
    SlotKind kind(String status, {required bool habit, required bool backfill}) =>
        slotKindOf(status: status, isHabitRef: habit, backfill: backfill);

    test('习惯最优先：同时回填且已完成，仍画习惯态', () {
      // 反例 1：habit 压过 backfill 与 done。
      expect(kind('done', habit: true, backfill: true), SlotKind.habit);
      expect(kind('pending', habit: true, backfill: false), SlotKind.habit);
    });

    test('回填高于已完成：过去时段的 done 条目画回填态，不是对勾态', () {
      // 反例 2：把 `done` 分支提到 `backfill` 之前，这条会红。
      expect(kind('done', habit: false, backfill: true), SlotKind.backfill);
    });

    test('非回填时，已完成才是 done；其余一律 plannedOpen', () {
      expect(kind('done', habit: false, backfill: false), SlotKind.done);
      expect(kind('pending', habit: false, backfill: false),
          SlotKind.plannedOpen);
      // 取消 / 顺延 / 未知取值都不该炸，也不该被当成 done。
      expect(kind('cancelled', habit: false, backfill: false),
          SlotKind.plannedOpen);
      expect(kind('deferred', habit: false, backfill: false),
          SlotKind.plannedOpen);
      expect(kind('', habit: false, backfill: false), SlotKind.plannedOpen);
    });

    test('穷举 2×2×5 组合，结果恒等于 habit→backfill→done→plannedOpen 顺序', () {
      const List<String> statuses = <String>[
        'pending',
        'done',
        'cancelled',
        'deferred',
        'weird-status',
      ];
      for (final bool habit in <bool>[false, true]) {
        for (final bool backfill in <bool>[false, true]) {
          for (final String status in statuses) {
            final SlotKind expected;
            if (habit) {
              expected = SlotKind.habit;
            } else if (backfill) {
              expected = SlotKind.backfill;
            } else if (status == 'done') {
              expected = SlotKind.done;
            } else {
              expected = SlotKind.plannedOpen;
            }
            expect(
              kind(status, habit: habit, backfill: backfill),
              expected,
              reason: 'status=$status habit=$habit backfill=$backfill',
            );
          }
        }
      }
    });
  });

  // ===========================================================================
  // Task 29 · 四态冗余通道（形状 + 文字）
  // ===========================================================================
  // 背景色单通道不够：`--slot-done` 与 `--slot-plan` 近乎同色。这组用例把
  // 「字形 / 状态词 / 前景色」三个映射逐条钉死，并防住两件回退：
  //   1. 有人把回填字形改回 `U+25B8`（随包字体 0/9 覆盖 ⇒ 豆腐块）；
  //   2. 有人给四态配色用上赭石（`--accent` / `--accent-wash`）。
  group('四态冗余通道（字形 / 状态词 / 前景色）', () {
    // 顺序与 `SlotKind` 枚举一致；枚举被调换时这里会跟着露馅。
    const List<SlotKind> allKinds = <SlotKind>[
      SlotKind.habit,
      SlotKind.backfill,
      SlotKind.done,
      SlotKind.plannedOpen,
    ];

    test('四态字形逐条：● 打卡 / ▶ 回填 / ✓ 完成 / ○ 计划', () {
      expect(glyphOfSlotKind(SlotKind.habit), '\u25CF');
      expect(glyphOfSlotKind(SlotKind.backfill), '\u25B6');
      expect(glyphOfSlotKind(SlotKind.done), '\u2713');
      expect(glyphOfSlotKind(SlotKind.plannedOpen), '\u25CB');

      // 码位也钉死：字形长得像但码位不同的情况（如 U+2714 重型勾）要被拦住。
      expect(glyphOfSlotKind(SlotKind.habit).codeUnitAt(0), 0x25CF);
      expect(glyphOfSlotKind(SlotKind.backfill).codeUnitAt(0), 0x25B6);
      expect(glyphOfSlotKind(SlotKind.done).codeUnitAt(0), 0x2713);
      expect(glyphOfSlotKind(SlotKind.plannedOpen).codeUnitAt(0), 0x25CB);
    });

    test('四态状态词逐条：打卡 / 回填 / 完成 / 计划', () {
      expect(stateLabelOfSlotKind(SlotKind.habit), '打卡');
      expect(stateLabelOfSlotKind(SlotKind.backfill), '回填');
      expect(stateLabelOfSlotKind(SlotKind.done), '完成');
      expect(stateLabelOfSlotKind(SlotKind.plannedOpen), '计划');
    });

    test('四个字形与四个状态词两两不同（映射写重复会在这里红）', () {
      final Set<String> glyphs = <String>{
        for (final SlotKind kind in allKinds) glyphOfSlotKind(kind),
      };
      final Set<String> labels = <String>{
        for (final SlotKind kind in allKinds) stateLabelOfSlotKind(kind),
      };
      expect(glyphs, hasLength(allKinds.length));
      expect(labels, hasLength(allKinds.length));
      // 字形单字符，状态词两位中文：形状通道与文字通道彼此不重合。
      for (final String glyph in glyphs) {
        expect(glyph.runes.length, 1);
      }
    });

    test('禁用守卫：任何一态都不许用 U+25B8（随包字体 0/9 覆盖）', () {
      // 不用字面量写禁用字符，避免本文件自己出现它。
      final String banned = String.fromCharCode(0x25B8);
      for (final SlotKind kind in allKinds) {
        final String glyph = glyphOfSlotKind(kind);
        expect(glyph.contains(banned), isFalse, reason: '$kind 用了 U+25B8');
        expect(glyph.codeUnitAt(0), isNot(0x25B8), reason: '$kind 用了 U+25B8');
      }
    });

    test('四态前景色逐条，且不取赭石（accent / accentWash）', () {
      expect(foregroundOfSlotKind(SlotKind.plannedOpen), AppTokens.slotPlanInk);
      expect(foregroundOfSlotKind(SlotKind.done), AppTokens.slotDoneInk);
      expect(foregroundOfSlotKind(SlotKind.backfill), AppTokens.slotBackfillInk);
      expect(foregroundOfSlotKind(SlotKind.habit), AppTokens.slotHabitInk);

      // 三个「在做事」的态共用主墨色；完成态有意退到 `--meta`，
      // 否则它比未完成态更抢眼，语义就反了。
      expect(AppTokens.slotPlanInk, AppTokens.ink);
      expect(AppTokens.slotBackfillInk, AppTokens.ink);
      expect(AppTokens.slotHabitInk, AppTokens.ink);
      expect(AppTokens.slotDoneInk, AppTokens.meta);

      for (final SlotKind kind in allKinds) {
        final Color ink = foregroundOfSlotKind(kind);
        expect(ink, isNot(AppTokens.accent), reason: '$kind 用了赭石');
        expect(ink, isNot(AppTokens.accentWash), reason: '$kind 用了赭石浅洗');
      }
    });

    test('四态前景色与四态格底色不是同一个值（前景/底成对，不许混用）', () {
      const Map<SlotKind, Color> grounds = <SlotKind, Color>{
        SlotKind.plannedOpen: AppTokens.slotPlan,
        SlotKind.done: AppTokens.slotDone,
        SlotKind.backfill: AppTokens.slotBackfill,
        SlotKind.habit: AppTokens.slotHabit,
      };
      for (final SlotKind kind in allKinds) {
        expect(foregroundOfSlotKind(kind), isNot(grounds[kind]),
            reason: '$kind 的前景与格底取了同一个值');
      }
    });
  });
}