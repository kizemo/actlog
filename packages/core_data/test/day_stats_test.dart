import 'package:core_data/core_data.dart';
import 'package:test/test.dart';

void main() {
  test('cancelled 不计入分母，deferred 计入', () {
    final stats = computeDayStats(
      items: const <PlanItemStat>[
        PlanItemStat(status: 'done', hasResultNote: true),
        PlanItemStat(status: 'done', hasResultNote: false),
        PlanItemStat(status: 'pending', hasResultNote: false),
        PlanItemStat(status: 'cancelled', hasResultNote: false),
      ],
      hasReview: false,
      hasMood: false,
    );
    expect(stats.planTotal, 3);
    expect(stats.planDone, 2);
    expect(stats.backfilled, 1);
    expect(stats.planPending, 1);
  });

  test('x=0 时回填率为 null（显示 —，不算 100%）', () {
    final stats = computeDayStats(
      items: const <PlanItemStat>[],
      hasReview: false,
      hasMood: false,
    );
    expect(stats.backfillRate, isNull);
  });

  test('回填率 = backfilled / planDone', () {
    final stats = computeDayStats(
      items: const <PlanItemStat>[
        PlanItemStat(status: 'done', hasResultNote: true),
        PlanItemStat(status: 'done', hasResultNote: true),
        PlanItemStat(status: 'done', hasResultNote: false),
        PlanItemStat(status: 'done', hasResultNote: false),
      ],
      hasReview: true,
      hasMood: true,
    );
    expect(stats.backfillRate, 0.5);
    expect(stats.reviewDone, isTrue);
    expect(stats.moodDone, isTrue);
  });
}
