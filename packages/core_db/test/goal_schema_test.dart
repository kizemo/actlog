// =============================================================================
// core_db · 目标两表（schema v3）的结构门禁
// =============================================================================
// 钉住六件事：
//   1. `goal` / `goal_link` 两张表建出来了，列清单**逐列**对上（不多不少）；
//   2. 十二个具名约束都在（CHECK / UNIQUE），且名字与 `tables.dart` 逐字一致；
//   3. 五个偏索引都在，且都带 `WHERE deleted_at IS NULL`（墓碑不进索引）；
//   4. CHECK 真的**会拒写**：非法 kind / 自评越界 / 非法 relation /
//      非法 target_type / 自环 / 重复关联，全部插不进去；
//   5. core_domain 的枚举取值 ↔ 真库 CHECK 里的 IN 列表**完全一致**
//      （枚举改了而 CHECK 没改 ⇒ 真库拒写，这是最隐蔽的一类回归）；
//   6. **派生量不入库**：完成度 / 达成率 / 汇总 / 未落位标记一个列都没有。
//
// 判据全部取自**真库的 sqlite_master / PRAGMA**，不取自源码文本 ——
// 源码写了不等于库里有。
// =============================================================================

import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart'
    show GoalKind, GoalRelation, GoalStatus, GoalTargetType;
import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:test/test.dart';

import 'support/schema_source.dart';

/// `goal` 表的完整列清单（顺序即建表顺序）。
const List<String> goalColumns = <String>[
  'id',
  'kind',
  'title',
  'note',
  'keywords',
  'parent_id',
  'domain',
  'horizon',
  'facet',
  'period_start',
  'period_end',
  'due_date',
  'quadrant',
  'priority_abc',
  'status',
  'self_score',
  'review_note',
  'improve_note',
  'archived_at',
  'created_at',
  'updated_at',
  'deleted_at',
  'origin_device_id',
  'rev',
];

/// `goal_link` 表的完整列清单。
const List<String> goalLinkColumns = <String>[
  'id',
  'goal_id',
  'target_type',
  'target_id',
  'relation',
  'created_at',
  'updated_at',
  'deleted_at',
  'origin_device_id',
  'rev',
];

/// 五个偏索引的名字。
const Set<String> goalIndexNames = <String>{
  'idx_goal_kind_period',
  'idx_goal_parent',
  'idx_goal_domain',
  'idx_goal_link_goal',
  'idx_goal_link_target',
};

/// 十二个具名约束的名字。
const Set<String> goalConstraintNames = <String>{
  'goal_kind_check',
  'goal_status_check',
  'goal_horizon_check',
  'goal_self_score_check',
  'goal_quadrant_check',
  'goal_priority_abc_check',
  'goal_period_end_check',
  'goal_archived_at_check',
  'goal_link_target_type_check',
  'goal_link_relation_check',
  'goal_link_no_self_check',
  'goal_link_target_unique',
};

void main() {
  group('目标两表 · 结构', () {
    late ActLogDatabase db;

    setUpAll(() async {
      db = openInMemoryActLogDatabase();
      await db.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await db.close();
    });

    test('两张表都存在', () async {
      final List<String> tables = await _userTableNames(db);
      expect(tables, contains('goal'));
      expect(tables, contains('goal_link'));
    });

    test('goal 的列逐列对上（派生量不入库）', () async {
      expect(await _columnNames(db, 'goal'), goalColumns);
    });

    test('goal_link 的列逐列对上', () async {
      expect(await _columnNames(db, 'goal_link'), goalLinkColumns);
    });

    test('派生量列一个都没有（完成度 / 达成率 / 汇总 / 未落位）', () async {
      final List<String> columns = await _columnNames(db, 'goal');
      for (final String banned in <String>[
        'completion',
        'completion_rate',
        'achievement_rate',
        'achievement',
        'progress',
        'progress_rate',
        'summary',
        'unplaced',
        'is_unplaced',
        'done_count',
        'total_count',
      ]) {
        expect(columns, isNot(contains(banned)), reason: '派生量列 $banned 不该存在');
      }
    });

    test('十二个具名约束都在', () async {
      final Map<String, String> goalConstraints =
          parseNamedConstraints(await _createSql(db, 'goal'));
      final Map<String, String> linkConstraints =
          parseNamedConstraints(await _createSql(db, 'goal_link'));
      final Set<String> actual = <String>{
        ...goalConstraints.keys,
        ...linkConstraints.keys,
      };
      for (final String name in goalConstraintNames) {
        expect(actual, contains(name));
      }
    });

    test('五个偏索引都在，且都带 WHERE deleted_at IS NULL', () async {
      final Map<String, String> indexes = await _indexSql(db);
      for (final String name in goalIndexNames) {
        expect(indexes.keys, contains(name), reason: '缺索引 $name');
        expect(
          indexes[name]!.toUpperCase(),
          contains('WHERE DELETED_AT IS NULL'),
          reason: '索引 $name 必须是偏索引',
        );
      }
    });

    test('goal_link 的唯一约束覆盖 (goal_id, target_type, target_id)', () async {
      final Map<String, String> constraints =
          parseNamedConstraints(await _createSql(db, 'goal_link'));
      expect(
        constraints.containsKey('goal_link_target_unique'),
        isTrue,
        reason: '缺 goal_link_target_unique 具名唯一约束',
      );
      expect(
        constraints['goal_link_target_unique']!.replaceAll(' ', ''),
        contains('UNIQUE(goal_id,target_type,target_id)'),
      );
    });
  });

  group('目标两表 · CHECK 真的拒写', () {
    late ActLogDatabase db;

    setUpAll(() async {
      db = openInMemoryActLogDatabase();
      await db.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await db.close();
    });

    test('kind 不在允许集合里 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, created_at, updated_at, "
        "origin_device_id) VALUES ('g1', 'nope', 'x', 1, 1, 'dev')",
        'goal_kind_check',
      );
    });

    test('status 不在允许集合里 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, status, created_at, updated_at, "
        "origin_device_id) VALUES ('g2', 'weekly', 'x', 'paused', 1, 1, 'dev')",
        'goal_status_check',
      );
    });

    test('self_score 超出 0..10 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, self_score, created_at, updated_at, "
        "origin_device_id) VALUES ('g3', 'weekly', 'x', 11, 1, 1, 'dev')",
        'goal_self_score_check',
      );
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, self_score, created_at, updated_at, "
        "origin_device_id) VALUES ('g4', 'weekly', 'x', -1, 1, 1, 'dev')",
        'goal_self_score_check',
      );
    });

    test('horizon 超出 1..5 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, horizon, created_at, updated_at, "
        "origin_device_id) VALUES ('g5', 'blueprint', 'x', 9, 1, 1, 'dev')",
        'goal_horizon_check',
      );
    });

    test('quadrant 超出 1..4 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, quadrant, created_at, updated_at, "
        "origin_device_id) VALUES ('g6', 'weekly', 'x', 7, 1, 1, 'dev')",
        'goal_quadrant_check',
      );
    });

    test('priority_abc 不在 A/B/C ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, priority_abc, created_at, "
        "updated_at, origin_device_id) "
        "VALUES ('g7', 'weekly', 'x', 'Z', 1, 1, 'dev')",
        'goal_priority_abc_check',
      );
    });

    test('period_end 早于 period_start ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, period_start, period_end, "
        "created_at, updated_at, origin_device_id) "
        "VALUES ('g8', 'monthly', 'x', 2000, 1999, 1, 1, 'dev')",
        'goal_period_end_check',
      );
    });

    test('非 done 的目标带 archived_at ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal (id, kind, title, status, archived_at, created_at, "
        "updated_at, origin_device_id) "
        "VALUES ('g9', 'weekly', 'x', 'active', 5000, 1, 1, 'dev')",
        'goal_archived_at_check',
      );
    });

    test('target_type 不在允许集合里 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal_link (id, goal_id, target_type, target_id, "
        "created_at, updated_at, origin_device_id) "
        "VALUES ('l1', 'g1', 'note', 'n1', 1, 1, 'dev')",
        'goal_link_target_type_check',
      );
    });

    test('relation 不在允许集合里 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal_link (id, goal_id, target_type, target_id, relation, "
        "created_at, updated_at, origin_device_id) "
        "VALUES ('l2', 'g1', 'plan_item', 'p1', 'owns', 1, 1, 'dev')",
        'goal_link_relation_check',
      );
    });

    test('目标关联自己 ⇒ 拒写', () async {
      await _expectRejected(
        db,
        "INSERT INTO goal_link (id, goal_id, target_type, target_id, "
        "created_at, updated_at, origin_device_id) "
        "VALUES ('l3', 'g-self', 'goal', 'g-self', 1, 1, 'dev')",
        'goal_link_no_self_check',
      );
    });

    test('同一 (goal_id, target_type, target_id) 重复关联 ⇒ 拒写', () async {
      await db.customStatement(
        "INSERT INTO goal_link (id, goal_id, target_type, target_id, "
        "created_at, updated_at, origin_device_id) "
        "VALUES ('l4', 'g-dup', 'plan_item', 'p-dup', 1, 1, 'dev')",
      );
      await _expectRejected(
        db,
        "INSERT INTO goal_link (id, goal_id, target_type, target_id, "
        "created_at, updated_at, origin_device_id) "
        "VALUES ('l5', 'g-dup', 'plan_item', 'p-dup', 1, 1, 'dev')",
        'UNIQUE',
      );
    });
  });

  group('枚举 ↔ 真库 CHECK 的取值域', () {
    late ActLogDatabase db;

    setUpAll(() async {
      db = openInMemoryActLogDatabase();
      await db.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await db.close();
    });

    test('goal_kind_check == GoalKind 的 code 集合', () async {
      expect(
        checkValues(await _createSql(db, 'goal'), 'goal_kind_check'),
        GoalKind.values.map((GoalKind k) => k.code).toSet(),
      );
    });

    test('goal_status_check == GoalStatus 的 code 集合', () async {
      expect(
        checkValues(await _createSql(db, 'goal'), 'goal_status_check'),
        GoalStatus.values.map((GoalStatus s) => s.code).toSet(),
      );
    });

    test('goal_link_relation_check == GoalRelation 的 code 集合', () async {
      expect(
        checkValues(await _createSql(db, 'goal_link'), 'goal_link_relation_check'),
        GoalRelation.values.map((GoalRelation r) => r.code).toSet(),
      );
    });

    test('goal_link_target_type_check == GoalTargetType 的 code 集合', () async {
      expect(
        checkValues(
          await _createSql(db, 'goal_link'),
          'goal_link_target_type_check',
        ),
        GoalTargetType.values.map((GoalTargetType t) => t.code).toSet(),
      );
    });
  });
}

// -----------------------------------------------------------------------------
// 读真库的小工具
// -----------------------------------------------------------------------------

/// 列出全部用户表（排除 sqlite_ 内建表）。
Future<List<String>> _userTableNames(ActLogDatabase db) async {
  final List<QueryRow> rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  return rows.map((QueryRow r) => r.data['name']! as String).toList();
}

/// 列出某张表的列名（按建表顺序）。
Future<List<String>> _columnNames(ActLogDatabase db, String table) async {
  final List<QueryRow> rows =
      await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((QueryRow r) => r.data['name']! as String).toList();
}

/// 取某张表的 CREATE TABLE 原文。
Future<String> _createSql(ActLogDatabase db, String table) async {
  final QueryRow row = await db
      .customSelect(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: <Variable<Object>>[Variable<String>(table)],
      )
      .getSingle();
  return row.data['sql']! as String;
}

/// 取全部索引的名字 → 建索引 SQL。
Future<Map<String, String>> _indexSql(ActLogDatabase db) async {
  final List<QueryRow> rows = await db
      .customSelect(
        "SELECT name, sql FROM sqlite_master WHERE type = 'index' "
        "AND sql IS NOT NULL",
      )
      .get();
  return <String, String>{
    for (final QueryRow r in rows)
      r.data['name']! as String: r.data['sql']! as String,
  };
}

/// 断言一条 INSERT 会被约束拒绝，且拒绝理由里含 [expectSubstring]。
Future<void> _expectRejected(
  ActLogDatabase db,
  String sql,
  String expectSubstring,
) async {
  await expectLater(
    db.customStatement(sql),
    throwsA(
      predicate<Object>(
        (Object e) => e.toString().contains(expectSubstring),
        '应被约束拒绝（理由含 "$expectSubstring"），但实际未抛异常',
      ),
    ),
  );
}
