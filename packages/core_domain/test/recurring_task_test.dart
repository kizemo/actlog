// ignore_for_file: public_member_api_docs
// =============================================================================
// core_domain · 循环任务纯领域工具门禁
// =============================================================================
// 只验两件与 IO 无关、却最容易写错的事：
//   1. `weekday_mask` 的位序（**bit0 = 周一** … bit6 = 周日，0..127）；
//   2. 「一天中的第几分钟」（0..1439）↔ `HH:mm` 文本的互转。
// 位序一旦反了，物化就会在错误的星期生成计划条目 —— 这是静默错误，
// 必须由测试钉住，不能只写在注释里。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('WeekdayMask 位序', () {
    test('bit0 = 周一 … bit6 = 周日（与 DateTime.weekday 对齐）', () {
      expect(WeekdayMask.bitOf(1), 1);
      expect(WeekdayMask.bitOf(2), 2);
      expect(WeekdayMask.bitOf(3), 4);
      expect(WeekdayMask.bitOf(4), 8);
      expect(WeekdayMask.bitOf(5), 16);
      expect(WeekdayMask.bitOf(6), 32);
      expect(WeekdayMask.bitOf(7), 64);
    });

    test('常量：工作日 31 / 周末 96 / 每天 127', () {
      expect(WeekdayMask.workdays, 31);
      expect(WeekdayMask.weekend, 96);
      expect(WeekdayMask.all, 127);
      expect(WeekdayMask.maxValue, 127);
      expect(WeekdayMask.none, 0);
    });

    test('bitOf 对非法星期抛 ArgumentError', () {
      expect(() => WeekdayMask.bitOf(0), throwsArgumentError);
      expect(() => WeekdayMask.bitOf(8), throwsArgumentError);
    });

    test('isValid 只接受 0..127', () {
      expect(WeekdayMask.isValid(0), isTrue);
      expect(WeekdayMask.isValid(127), isTrue);
      expect(WeekdayMask.isValid(-1), isFalse);
      expect(WeekdayMask.isValid(128), isFalse);
    });

    test('includes / weekdaysOf / bitOfDate', () {
      const int mask = WeekdayMask.workdays;
      expect(WeekdayMask.includes(mask, 1), isTrue);
      expect(WeekdayMask.includes(mask, 5), isTrue);
      expect(WeekdayMask.includes(mask, 6), isFalse);
      expect(WeekdayMask.includes(mask, 7), isFalse);
      expect(WeekdayMask.weekdaysOf(mask), <int>[1, 2, 3, 4, 5]);

      // 2026-11-11 是周三（weekday = 3）。
      final DateTime wednesday = DateTime(2026, 11, 11);
      expect(wednesday.weekday, 3);
      expect(WeekdayMask.bitOfDate(wednesday), WeekdayMask.wednesday);
    });

    test('label 摘要', () {
      expect(WeekdayMask.label(WeekdayMask.none), '未选');
      expect(WeekdayMask.label(WeekdayMask.all), '每天');
      expect(WeekdayMask.label(WeekdayMask.workdays), '工作日');
      expect(WeekdayMask.label(WeekdayMask.weekend), '周末');
      expect(
        WeekdayMask.label(WeekdayMask.monday | WeekdayMask.wednesday),
        '周一、周三',
      );
    });
  });

  group('分钟数 ↔ HH:mm', () {
    test('formatMinuteOfDay 补零', () {
      expect(formatMinuteOfDay(0), '00:00');
      expect(formatMinuteOfDay(570), '09:30');
      expect(formatMinuteOfDay(1439), '23:59');
    });

    test('formatMinuteOfDay 越界属于 bug，直接抛', () {
      expect(() => formatMinuteOfDay(-1), throwsArgumentError);
      expect(() => formatMinuteOfDay(1440), throwsArgumentError);
    });

    test('parseMinuteOfDay 接受 H:mm 与 HH:mm', () {
      expect(parseMinuteOfDay('09:30'), 570);
      expect(parseMinuteOfDay('9:30'), 570);
      expect(parseMinuteOfDay(' 00:00 '), 0);
      expect(parseMinuteOfDay('23:59'), 1439);
    });

    test('parseMinuteOfDay 对非法输入返回 null（不抛）', () {
      expect(parseMinuteOfDay(''), isNull);
      expect(parseMinuteOfDay('0900'), isNull);
      expect(parseMinuteOfDay('9:3'), isNull);
      expect(parseMinuteOfDay('24:00'), isNull);
      expect(parseMinuteOfDay('09:60'), isNull);
      expect(parseMinuteOfDay('ab:cd'), isNull);
    });

    test('minutesPerDay = 1440', () {
      expect(minutesPerDay, 1440);
    });
  });
}