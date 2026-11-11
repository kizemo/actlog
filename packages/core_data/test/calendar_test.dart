import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  test('buildMonthGrid returns whole weeks', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07');
    expect(grid.length % 7, 0);
    expect(weekdayLabel(grid.first.date), '周一');
    expect(grid.first.date.compareTo('2026-11-01') <= 0, true);
    expect(grid.where((c) => c.inMonth).length, 30);
    expect(grid.firstWhere((c) => c.date == '2026-11-01').inMonth, true);
    expect(grid[grid.length - 1].date, '2026-12-06');
  });

  test('weekend flags follow Saturday/Sunday', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07');
    expect(grid.firstWhere((c) => c.date == '2026-11-07').isWeekend, true);
    expect(grid.firstWhere((c) => c.date == '2026-11-01').isWeekend, true);
    expect(grid.firstWhere((c) => c.date == '2026-11-05').isWeekend, false);
  });

  test('relative labels match today', () {
    expect(relativeDayLabel('2026-11-07', today: '2026-11-07'), '今天');
    expect(relativeDayLabel('2026-11-06', today: '2026-11-07'), '昨天');
    expect(relativeDayLabel(shiftIsoDate('2026-11-07', 1), today: '2026-11-07'), '明天');
  });

  test('malformed month inputs degrade to an empty grid', () {
    expect(buildMonthGrid('garbage', today: '2026-11-07'), isEmpty);
    expect(buildMonthGrid('2026-13', today: '2026-11-07'), isEmpty);
    expect(buildMonthGrid('2026-11-07', today: '2026-11-07'), isEmpty);
  });

  test('weekStart shifts the window and the whole-week rule still holds', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07', weekStart: 2);
    expect(grid.first.date, '2026-10-27');
    expect(weekdayLabel(grid.first.date), '周二');
    expect(grid.length % 7, 0);
    expect(grid.where((c) => c.inMonth).length, 30);
  });

  test('Friday is a weekday and isToday marks exactly one cell', () {
    final grid = buildMonthGrid('2026-11', today: '2026-11-07');
    expect(grid.firstWhere((c) => c.date == '2026-11-06').isWeekend, false);
    expect(grid.firstWhere((c) => c.date == '2026-11-06').isToday, false);
    expect(grid.where((c) => c.isToday).length, 1);
  });

  test('relativeDayLabel covers day-before-yesterday and weekday fallback', () {
    expect(relativeDayLabel('2026-11-05', today: '2026-11-07'), '前天');
    expect(relativeDayLabel('2026-11-20', today: '2026-11-07'), '周五');
  });

  test('invalid inputs degrade instead of throwing', () {
    expect(weekdayLabel('garbage'), '');
    expect(dateTitle('garbage'), 'garbage');
    expect(relativeDayLabel('garbage', today: '2026-11-07'), '');
  });

  test('leap February keeps whole weeks and 29 in-month cells', () {
    final grid = buildMonthGrid('2028-02', today: '2026-11-07');
    expect(grid.length % 7, 0);
    expect(grid.where((c) => c.inMonth).length, 29);
  });

  test('December grid crosses into January 2027 correctly', () {
    final grid = buildMonthGrid('2026-12', today: '2026-11-07');
    expect(grid.length % 7, 0);
    expect(grid.where((c) => c.inMonth).length, 31);
    expect(grid.first.date, '2026-11-30');
    expect(grid.last.date, '2027-01-10');
    expect(grid.last.inMonth, false);
  });
}
