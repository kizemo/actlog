// ignore_for_file: public_member_api_docs

import 'dart:math';

import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  group('uuidV7', () {
    test('36 字符、版本位 7、变体位 10xx', () {
      final id = uuidV7(random: Random(7));
      expect(id.length, 36);
      expect(id[8], '-');
      expect(id[13], '-');
      expect(id[18], '-');
      expect(id[23], '-');
      expect(id[14], '7');
      expect('89ab'.contains(id[19]), isTrue);
    });

    test('同一个随机源下也不会重复', () {
      final rng = Random(11);
      final ids = <String>{for (var i = 0; i < 500; i++) uuidV7(random: rng)};
      expect(ids.length, 500);
    });

    test('时间戳靠前的 ID 字典序更小', () {
      final rng = Random(13);
      final early = uuidV7(now: DateTime.utc(2026, 1, 1), random: rng);
      final late = uuidV7(now: DateTime.utc(2026, 1, 2), random: rng);
      expect(early.compareTo(late), lessThan(0));
    });
  });

  group('parseIsoDate', () {
    test('接受合法日历日', () {
      final parsed = parseIsoDate('2026-11-06');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 11);
      expect(parsed.day, 6);
    });

    test('拒绝被 DateTime 静默进位的日期', () {
      expect(parseIsoDate('2026-02-30'), isNull);
      expect(parseIsoDate('2026-13-01'), isNull);
      expect(parseIsoDate('2026-00-10'), isNull);
    });

    test('拒绝格式错误与空串', () {
      expect(parseIsoDate(''), isNull);
      expect(parseIsoDate('2026/11/06'), isNull);
      expect(parseIsoDate('2026-11'), isNull);
      expect(parseIsoDate('abcd-ef-gh'), isNull);
    });
  });

  group('日历日运算', () {
    test('isoDate 补零到两位', () {
      expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(today(DateTime(2026, 11, 6)), '2026-11-06');
    });

    test('跨月与闰年边界', () {
      expect(shiftIsoDate('2026-01-31', 1), '2026-02-01');
      expect(shiftIsoDate('2028-02-28', 1), '2028-02-29');
      expect(shiftIsoDate('2026-03-01', -1), '2026-02-28');
      expect(shiftIsoDate('2026-12-31', 1), '2027-01-01');
    });

    test('previousIsoDate 就是减一天', () {
      expect(previousIsoDate('2026-11-06'), '2026-11-05');
    });

    test('非法输入原样返回，解析层不崩溃', () {
      expect(shiftIsoDate('not-a-date', 3), 'not-a-date');
      expect(previousIsoDate(''), '');
    });
  });
}