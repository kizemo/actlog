// =============================================================================
// core_db · 枚举取值 ↔ schema CHECK 约束 交叉校验
// =============================================================================
// 唯一真源是 docs/schema_v1.sql 的 CHECK 约束；core_domain 的枚举取值必须
// 逐字一致，否则「写了 'Q5'」这种错会一路漂到数据库里才炸。
// core_domain 只作为 dev_dependency 被**只读**引用，不修改它的任何文件。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

import 'support/schema_source.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = readSchemaV1Sql();
  });

  void check(String constraint, Set<String> codes) {
    test('$constraint ↔ 枚举取值完全一致', () {
      expect(checkValues(sql, constraint), codes);
    });
  }

  group('枚举 ↔ CHECK', () {
    check(
      'plan_item_quadrant_check',
      Quadrant.values.map((e) => e.code).toSet(),
    );
    check(
      'todo_quadrant_check',
      Quadrant.values.map((e) => e.code).toSet(),
    );
    check(
      'plan_item_priority_abc_check',
      PriorityAbc.values.map((e) => e.code).toSet(),
    );
    check(
      'todo_priority_abc_check',
      PriorityAbc.values.map((e) => e.code).toSet(),
    );
    check(
      'plan_item_status_check',
      PlanStatus.values.map((e) => e.code).toSet(),
    );
    check(
      'todo_status_check',
      TodoStatus.values.map((e) => e.code).toSet(),
    );
    check(
      'plan_item_source_type_check',
      PlanSourceType.values.map((e) => e.code).toSet(),
    );
    check(
      'habit_type_check',
      HabitType.values.map((e) => e.code).toSet(),
    );
    check(
      'habit_schedule_type_check',
      HabitScheduleType.values.map((e) => e.code).toSet(),
    );
    check(
      'habit_checkin_status_check',
      CheckinStatus.values.map((e) => e.code).toSet(),
    );
    check(
      'day_log_mode_check',
      LogMode.values.map((e) => e.code).toSet(),
    );
    check(
      'project_status_check',
      ProjectStatus.values.map((e) => e.code).toSet(),
    );
    check(
      'reminder_target_type_check',
      ReminderTargetType.values.map((e) => e.code).toSet(),
    );
    check(
      'reminder_repeat_rule_check',
      RepeatRule.values.map((e) => e.code).toSet(),
    );
    check(
      'oplog_op_check',
      OplogOp.values.map((e) => e.code).toSet(),
    );
  });

  test('PriorityDisplayMode 只存 settings（无 CHECK），但取值集合固定', () {
    // settings 是键值表，priority_mode 没有独立的 CHECK 约束；
    // 这里只锁定枚举取值本身，防止随手改字面量。
    expect(
      PriorityDisplayMode.values.map((e) => e.code).toSet(),
      <String>{'quadrant', 'abc'},
    );
  });
}
