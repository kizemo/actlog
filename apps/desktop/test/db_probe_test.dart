// 探针：确认 flutter test 环境能打开 in-memory drift 库。
// 这决定能否在 UI 层做端到端断言（极简不隐藏数据、双模式切换无损）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flutter test 下能打开内存库并跑通仓储读写', () async {
    final db = openInMemoryActLogDatabase();
    addTearDown(db.close);

    final repos = ActLogRepositories(db, deviceId: 'probe-device');

    final log = await repos.dayLog.ensureByDate('2026-11-07');
    expect(log.date, '2026-11-07');

    await repos.dayLog.saveReview(
      log.id,
      const ReviewDraft(good: '读到能开库', improve: '少绕路'),
    );
    final reread = await repos.dayLog.findByDate('2026-11-07');
    expect(reread, isNotNull);
    expect(reread!.good, '读到能开库');
    expect(reread.improve, '少绕路');

    final itemId = await repos.planItem.create(
      date: '2026-11-07',
      title: '探针条目',
      quadrant: Quadrant.q1,
    );
    await repos.planItem.setPriorityAbc(itemId, PriorityAbc.a);
    final items = await repos.planItem.listByDate('2026-11-07');
    expect(items, hasLength(1));
    expect(items.single.quadrant, 'Q1');
    expect(items.single.priorityAbc, 'A');
  });
}