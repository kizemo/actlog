// packages/core_data/test/calendar_summary_test.dart
import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  test('徽标按形状区分：全完成 ✓ / 有未完成 ● / 全空 ○ / 未来预排 ▸', () {
    expect(const CalendarDaySummary(date: '2026-11-07').badge, '○');
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 3,
        planTotal: 3,
      ).badge,
      '✓',
    );
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 2,
        planTotal: 3,
      ).badge,
      '●',
    );
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 0,
        planTotal: 2,
        future: true,
      ).badge,
      '▸',
    );
  });

  test('未来预排徽标优先于完成态', () {
    expect(
      const CalendarDaySummary(
        date: '2026-11-07',
        planDone: 3,
        planTotal: 3,
        future: true,
      ).badge,
      '▸',
    );
  });
}