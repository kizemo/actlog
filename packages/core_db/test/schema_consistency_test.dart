// =============================================================================
// core_db · schema 一致性门禁（G3 / G6 的基础）
// =============================================================================
// 做法：建**两个真实的库**，逐项比对结构。
//   · 库 A：由 core_db 的迁移建出（drift 把 tables.dart 的 TableDef 渲染成 DDL）。
//   · 库 B：直接把 docs/schema_v1.sql 原样执行建出。
// 比对项：表名、列（名/类型/默认值/主键/可空性）、具名约束、外键关系集合、
//         索引（名 + 列）。
//
// 已知的**表示差异**（不是结构差异），比对时显式归一化：
//   1. 主键列的 NOT NULL：drift 对所有非空列都加 NOT NULL，schema_v1.sql 写的是
//      `id TEXT PRIMARY KEY`（SQLite 历史行为：非 INTEGER 主键允许 NULL）。
//      比对时忽略「主键列的 notnull」。
//   2. 外键出现两次：drift 的 references() 生成列级 REFERENCES，具名约束又生成
//      表级 FOREIGN KEY —— 两者是同一条关系，比对时按关系集合去重。
// =============================================================================

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

import 'support/schema_source.dart';

void main() {
  group('drift 生成的 schema ↔ docs/schema_v1.sql', () {
    late ActLogDatabase driftDb;
    late sqlite.Database referenceDb;

    setUpAll(() async {
      driftDb = openInMemoryActLogDatabase();
      // 触发打开与建库。
      await driftDb.customSelect('SELECT 1').get();

      referenceDb = sqlite.sqlite3.openInMemory();
      for (final statement in splitSqlStatements(readSchemaV1Sql())) {
        referenceDb.execute(statement);
      }
    });

    tearDownAll(() async {
      await driftDb.close();
      referenceDb.close();
    });

    test('表集合完全一致（v1 的 14 张 + v2 新增 2 张）', () async {
      final driftTables = await _userTables(driftDb);
      final referenceTables = await _userTables(referenceDb);

      // v1 的 14 张必须逐项对上（顺序即 sqlite_master 的名字序）。
      expect(referenceTables.length, 14);
      expect(
        driftTables.where(referenceTables.contains).toList(),
        referenceTables,
      );
      // 多出来的只允许是 v2 的两张：`docs` 目前没有 schema_v2.sql，
      // 所以这里用「白名单」而不是第二份 DDL 做对照。
      expect(
        driftTables.where((t) => !referenceTables.contains(t)).toList(),
        <String>['recurring_occurrence', 'recurring_task'],
        reason: 'v2 只允许新增循环任务的两张表',
      );
      expect(driftTables.length, 16);
    });

    test('v2 新表的索引都已建出（迁移里手工建的那 4 个）', () async {
      expect(
        (await _indexes(driftDb, 'recurring_task')).keys.toSet(),
        <String>{
          'idx_recurring_task_active',
          'idx_recurring_task_updated_at',
        },
      );
      expect(
        (await _indexes(driftDb, 'recurring_occurrence')).keys.toSet(),
        <String>{
          'idx_recurring_occurrence_date',
          'idx_recurring_occurrence_updated_at',
        },
      );
    });

    test('每张表的列完全一致', () async {
      for (final table in await _userTables(referenceDb)) {
        final expected = await _columns(referenceDb, table);
        final actual = await _columns(driftDb, table);

        expect(
          actual.map(_columnSignature).toList(),
          expected.map(_columnSignature).toList(),
          reason: '表 $table 的列与 schema_v1.sql 不一致',
        );
      }
    });

    test('具名约束（CHECK / UNIQUE / FOREIGN KEY）完全一致', () async {
      var total = 0;
      for (final table in await _userTables(referenceDb)) {
        final expected = await _namedConstraints(referenceDb, table);
        final actual = await _namedConstraints(driftDb, table);

        expect(
          actual,
          expected,
          reason: '表 $table 的具名约束与 schema_v1.sql 不一致',
        );
        total += expected.length;
      }
      expect(total, greaterThanOrEqualTo(40), reason: '具名约束总数不应这么少');
    });

    test('外键关系一致（列 → 目标表/列 → ON DELETE 动作）', () async {
      for (final table in await _userTables(referenceDb)) {
        final expected = await _foreignKeys(referenceDb, table);
        final actual = await _foreignKeys(driftDb, table);

        expect(actual, expected, reason: '表 $table 的外键关系不一致');
      }
    });

    test('索引（名称 + 列）完全一致', () async {
      final expectedNames = <String>{};
      final actualNames = <String>{};

      for (final table in await _userTables(referenceDb)) {
        final expected = await _indexes(referenceDb, table);
        final actual = await _indexes(driftDb, table);

        expect(actual, expected, reason: '表 $table 的索引不一致');
        expectedNames.addAll(expected.keys);
        actualNames.addAll(actual.keys);
      }

      expect(actualNames, expectedNames);
      expect(expectedNames.length, greaterThanOrEqualTo(25));
    });
  });
}

// -----------------------------------------------------------------------------
// 库访问抽象（drift 库与 sqlite3 库都要能查）
// -----------------------------------------------------------------------------

Future<List<Map<String, Object?>>> _query(
  Object db,
  String sql, [
  List<Object?> params = const <Object?>[],
]) async {
  if (db is ActLogDatabase) {
    final rows = await db.customSelect(
      sql,
      variables: [for (final p in params) Variable<String>(p! as String)],
    ).get();
    return rows.map((r) => r.data).toList();
  }
  final raw = (db as sqlite.Database).select(sql, params);
  return raw.map((r) => Map<String, Object?>.from(r)).toList();
}

Future<List<String>> _userTables(Object db) async {
  final rows = await _query(
    db,
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  return rows.map((r) => r['name']! as String).toList();
}

/// 列签名：名 / 类型 / 默认值 / 主键 / 可空性。
///
/// 主键列的 notnull 被忽略（见文件头说明 1）。
String _columnSignature(Map<String, Object?> column) {
  final name = column['name'];
  final type = column['type'];
  final dflt = column['dflt_value'];
  final pk = (column['pk'] as int?) ?? 0;
  final notNull = (column['notnull'] as int?) ?? 0;
  final notNullPart = pk == 1 ? '' : ' notnull=$notNull';
  return '$name | $type | default=$dflt | pk=$pk$notNullPart';
}

Future<List<Map<String, Object?>>> _columns(Object db, String table) async {
  final rows = await _query(db, 'PRAGMA table_info("$table")');
  return rows.toList()
    ..sort((a, b) => (a['cid']! as int).compareTo(b['cid']! as int));
}

/// 具名约束：名字 → 归一化后的约束体。
Future<Map<String, String>> _namedConstraints(Object db, String table) async {
  final rows = await _query(
    db,
    "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
    <Object?>[table],
  );
  if (rows.isEmpty) {
    return <String, String>{};
  }
  final sql = rows.first['sql'] as String? ?? '';
  return parseNamedConstraints(sql);
}

/// 外键关系集合：(来源列 → 目标表.列, on_delete, on_update)。
Future<Set<String>> _foreignKeys(Object db, String table) async {
  final rows = await _query(db, 'PRAGMA foreign_key_list("$table")');
  return rows
      .map(
        (r) =>
            '${r['from']} -> ${r['table']}.${r['to']} '
            'on_delete=${r['on_delete']} on_update=${r['on_update']}',
      )
      .toSet();
}

/// 索引：名字 → 列名列表（只取显式创建的索引，忽略 sqlite_autoindex_*）。
Future<Map<String, List<String>>> _indexes(Object db, String table) async {
  final list = await _query(db, 'PRAGMA index_list("$table")');
  final result = <String, List<String>>{};
  for (final row in list) {
    final name = row['name']! as String;
    if (name.startsWith('sqlite_autoindex')) {
      continue;
    }
    final info = await _query(db, 'PRAGMA index_info("$name")');
    final columns = info.map((r) => r['name']).whereType<String>().toList();
    result[name] = columns;
  }
  return result;
}
