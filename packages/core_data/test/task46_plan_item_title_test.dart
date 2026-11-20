// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · PlanItemRepository.setTitle（Task 46 · W2）
// =============================================================================
// 背景：未来日（预排日）的条目必须能改标题。`plan_item.title` 列早已存在
// （`packages\core_db\lib\src\tables.dart`），本波次**不加 schema、不做迁移**，
// 只补一个写入口。四条事实钉住它：
//   1. 写入读回一致，且 oplog payload 里确实带着新标题（同步侧按字段级 diff
//      重放；没记录就等于这次改动永远不会离开本机）；
//   2. **只改 title 一列** —— 内容 / 级别 / 回填 / 起止 / 状态都保持原值。
//      详情窗「只写变化列」的策略依赖这条：用户改标题不该顺手覆盖掉别的列；
//   3. 空串原样写入：口径与 `setDetail` / `setResultNote` 完全一致，**不自创
//      校验规则**（标题能否为空是界面决策，不是仓储决策）；
//   4. 软删后照抄 `setDetail` 的既有语义：不抛异常、仍写列、墓碑不变
//      （`_patch` 不过滤 `deleted_at`）。
//
// 日期取真实当天 `today()`：`create` 的默认 date 就是它，写死绝对日期会跨日
// 漂移（既有坑）。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const String _device = 'dev-title-test';

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

  /// 取单条标量（id 与字面量都由测试自己拼，无注入面）。
  Future<Object?> scalar(String sql) async {
    final rows = await db.customSelect(sql).get();
    if (rows.isEmpty) {
      return null;
    }
    return rows.first.data.values.first;
  }

  group('PlanItemRepository · setTitle（Task 46 W2）', () {
    test('写入后读回一致，oplog payload 带 title 字段与新值', () async {
      final id = await repos.planItem.create(date: _today, title: '旧标题');

      await repos.planItem.setTitle(id, '新标题');

      final PlanItemData row = (await repos.planItem.listByDate(_today)).single;
      expect(row.id, id);
      expect(row.title, '新标题');
      // 按「字段名 + 新值」双条件匹配：`create` 自己的 payload 也可能带
      // `title` 字段名（旧值），只匹配字段名会与建行那条混淆。
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_id = '$id' "
          "AND op = 'upsert' AND payload LIKE '%\"title\"%' "
          "AND payload LIKE '%新标题%'",
        ),
        1,
        reason: 'setTitle 没把 title 写进 oplog（同步侧会看不到这次改动）',
      );
    });

    test('只改 title，其它列一律保持原值', () async {
      final id = await repos.planItem.create(
        date: _today,
        title: '别动我',
        detail: '内容还在',
        quadrant: Quadrant.q1,
      );
      await repos.planItem.setResultNote(id, '回填还在');
      // `create` 没有 planned_start / planned_end 形参（起止走桌面层），
      // 裸 SQL 预置最直接，也不引入跨包依赖。
      await db.customStatement(
        "UPDATE plan_item SET planned_start = 540, planned_end = 555 "
        "WHERE id = '$id'",
      );

      await repos.planItem.setTitle(id, '改个名');

      final PlanItemData row = (await repos.planItem.listByDate(_today)).single;
      expect(row.title, '改个名');
      expect(row.detail, '内容还在', reason: '内容不该被标题写入带偏');
      expect(row.quadrant, Quadrant.q1.code, reason: '级别不该被标题写入带偏');
      expect(row.resultNote, '回填还在', reason: '回填内容不该被标题写入带偏');
      expect(row.plannedStart, 540, reason: '起止不该被标题写入带偏');
      expect(row.plannedEnd, 555, reason: '起止不该被标题写入带偏');
      expect(
        row.status,
        PlanStatus.pending.code,
        reason: '状态不该被标题写入带偏（改标题不是「完成」）',
      );
    });

    test('空串原样写入（与 setDetail / setResultNote 同口径）', () async {
      final id = await repos.planItem.create(date: _today, title: '有标题');

      await repos.planItem.setTitle(id, '');

      expect(
        await scalar("SELECT title FROM plan_item WHERE id = '$id'"),
        '',
        reason: '仓储层不拒绝空串：是否允许空标题由界面决定',
      );
    });

    test('软删后调用照抄 setDetail：不抛异常、仍写列、墓碑不变', () async {
      final id = await repos.planItem.create(date: _today, title: '删了也改');
      await repos.planItem.softDelete(id);

      // `_patch` 不过滤 `deleted_at` —— 这里断言的是既有语义，不是新承诺。
      await repos.planItem.setTitle(id, '删后标题');

      expect(
        await scalar(
          "SELECT title FROM plan_item WHERE id = '$id' "
          'AND deleted_at IS NOT NULL',
        ),
        '删后标题',
        reason: '墓碑行仍然可写（与 setDetail / setResultNote 同语义）',
      );
      expect(
        await repos.planItem.listByDate(_today),
        isEmpty,
        reason: '软删之后条目不该重新出现在列表里',
      );
    });
  });
}