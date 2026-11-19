// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · PlanItemRepository.setDetail（Task 45 · W2）
// =============================================================================
// 背景：条目 chip 右侧的「未分级 / 删除 / 状态词」删掉后，任务内容（`detail`）
// 改在左键打开的任务详情窗里编辑。写入口此前缺失（`detail` 只在 `create` /
// 待办转计划时写入），本轮补 `setDetail`。
//
// 盯两件事：
//   1. 写入读回一致，且**只动 `detail` 一列** —— 标题 / 分级 / 回填内容 /
//      起止都保持原值。详情窗「只写变化列」的策略依赖这条：用户的四次编辑
//      一次性提交，改内容不该顺手把级别或时间覆盖掉。
//   2. 软删后的语义**照抄 `setResultNote`**（`_patch` 不过滤墓碑）：对已删行
//      不抛异常、`detail` 仍更新，但 `deleted_at` 保持、`listByDate` 仍查不到。
//      这里不自创「已删即拒绝」的新语义，只把既有行为钉住。
//
// 为什么起止时间用裸 SQL 预置：`PlanItemRepository.create` 没有
// `planned_start` / `planned_end` 形参（起止走桌面层 `TimelineStore`，
// core_data 不依赖它）。本文件只验 `setDetail` 的**列隔离**，预置值用
// `db.customStatement` 最直接，也不引入跨包依赖。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const String _device = 'dev-detail-test';

/// 「今天」取真实当天：`HabitRepository.create` 的 `startDate` 默认值也是它，
/// 写死日期跨日就会因为「起始日在查询日之后」而不进排程（既有坑）。
final String _today = today();

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: _device);
  });

  tearDown(() async {
    await db.close();
  });

  /// 取单条标量（id 与字面量都由测试自己拼，值只有 uuid / 整数，无注入面）。
  Future<Object?> scalar(String sql) async {
    final rows = await db.customSelect(sql).get();
    if (rows.isEmpty) {
      return null;
    }
    return rows.first.data.values.first;
  }

  group('PlanItemRepository · setDetail（Task 45 W2）', () {
    test('写入后读回一致', () async {
      final id = await repos.planItem.create(date: _today, title: '写内容');

      await repos.planItem.setDetail(id, '第一段\n第二段');

      final PlanItemData row = (await repos.planItem.listByDate(_today)).single;
      expect(row.id, id);
      expect(row.detail, '第一段\n第二段');
      // oplog 必须记到这一列上：payload 是字段级 diff（`{"detail": ...}`），
      // 同步侧只按 diff 重放；op 只有 upsert / delete 两种（更新也记 upsert）。
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_id = '$id' "
          "AND op = 'upsert' AND payload LIKE '%\"detail\"%'",
        ),
        1,
        reason: 'setDetail 没走 oplog（同步侧会看不到这次改动）',
      );
    });

    test('只改 detail，其它列一律保持原值', () async {
      final id = await repos.planItem.create(
        date: _today,
        title: '别动我',
        detail: '旧内容',
        quadrant: Quadrant.q1,
      );
      await repos.planItem.setResultNote(id, '旧回填');
      await db.customStatement(
        "UPDATE plan_item SET planned_start = 540, planned_end = 555 "
        "WHERE id = '$id'",
      );

      await repos.planItem.setDetail(id, '新内容');

      final PlanItemData row = (await repos.planItem.listByDate(_today)).single;
      expect(row.detail, '新内容');
      expect(row.title, '别动我', reason: '标题不该被内容写入带偏');
      expect(row.quadrant, Quadrant.q1.code, reason: '级别不该被内容写入带偏');
      expect(row.resultNote, '旧回填', reason: '回填内容不该被内容写入带偏');
      expect(row.plannedStart, 540, reason: '起止不该被内容写入带偏');
      expect(row.plannedEnd, 555, reason: '起止不该被内容写入带偏');
    });

    test('软删后调用照抄 setResultNote：不抛异常、仍写列、墓碑不变', () async {
      final id = await repos.planItem.create(
        date: _today,
        title: '删了也写',
        detail: '删前',
      );
      await repos.planItem.softDelete(id);

      // `_patch` 不过滤 `deleted_at` —— 这里断言的是既有语义，不是新承诺。
      await repos.planItem.setDetail(id, '删后');

      expect(
        await scalar(
          "SELECT detail FROM plan_item WHERE id = '$id' "
          'AND deleted_at IS NOT NULL',
        ),
        '删后',
        reason: '墓碑行仍然可写（与 setResultNote 同语义）',
      );
      expect(
        await repos.planItem.listByDate(_today),
        isEmpty,
        reason: '软删之后条目不该重新出现在列表里',
      );
    });
  });
}