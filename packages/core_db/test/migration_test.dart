// =============================================================================
// core_db · 迁移框架门禁（G4）
// =============================================================================
// 验证：schema 版本 = 1、user_version 落库、integrity_check 通过、
//       外键开关生效、重开已有库不会重复建表也不会丢数据。
// =============================================================================

import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

import 'support/schema_source.dart';

void main() {
  group('迁移框架', () {
    test('schema 版本常量 = 3', () {
      expect(currentSchemaVersion, 3);
    });

    test('空库建完后 user_version = 1 且完整性检查通过', () async {
      final db = openInMemoryActLogDatabase();
      expect(db.schemaVersion, currentSchemaVersion);

      final userVersion = await db.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data['user_version'], currentSchemaVersion);

      final integrity = await db.customSelect('PRAGMA integrity_check').getSingle();
      expect(integrity.data['integrity_check'], 'ok');

      await db.close();
    });

    test('外键开关在连接级生效', () async {
      final db = openInMemoryActLogDatabase();
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data['foreign_keys'], 1);
      await db.close();
    });

    test('重开已有的文件库：不重复建表、数据还在', () async {
      final dir = Directory.systemTemp.createTempSync('actlog_migration');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}${Platform.pathSeparator}actlog.db');

      final first = openActLogDatabase(file);
      await first.into(first.todo).insert(
        TodoCompanion.insert(
          id: 'todo-keep',
          title: '别丢我',
          createdAt: 1000,
          updatedAt: 1000,
          originDeviceId: 'dev-test',
        ),
      );
      await first.close();

      final second = openActLogDatabase(file);
      final tables = await second
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(18));
      expect(await second.select(second.todo).get(), hasLength(1));

      final userVersion =
          await second.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data['user_version'], currentSchemaVersion);

      await second.close();
    });

    test('v1 库升级到 v3：补齐循环任务与目标四张表，旧数据原样保留', () async {
      final dir = Directory.systemTemp.createTempSync('actlog_migration_v2');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}${Platform.pathSeparator}actlog.db');

      // 造一个**真正的 v1 库**：直接执行 docs/schema_v1.sql，再把 user_version
      // 写成 1。这样打开时走的是 onUpgrade 的 `from < 2` 分支，而不是 onCreate。
      final raw = sqlite.sqlite3.open(file.path);
      for (final statement in splitSqlStatements(readSchemaV1Sql())) {
        raw.execute(statement);
      }
      raw.execute(
        "INSERT INTO todo (id, title, created_at, updated_at, origin_device_id) "
        "VALUES ('todo-v1', '老数据', 1000, 1000, 'dev-test')",
      );
      raw.execute('PRAGMA user_version = 1');
      raw.close();

      final upgraded = openActLogDatabase(file);
      final tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(18));
      expect(await upgraded.select(upgraded.todo).get(), hasLength(1));

      final v2Tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('recurring_task', 'recurring_occurrence')",
          )
          .get();
      expect(v2Tables, hasLength(2));

      final indexes = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_recurring%'",
          )
          .get();
      expect(
        indexes.map((r) => r.data['name']).toSet(),
        <Object?>{
          'idx_recurring_task_active',
          'idx_recurring_task_updated_at',
          'idx_recurring_occurrence_date',
          'idx_recurring_occurrence_updated_at',
        },
      );

      // v3 的两张目标表与五个偏索引也在（v1 → v3 **不能**跳过 v2 那一步）。
      final v3Tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('goal', 'goal_link')",
          )
          .get();
      expect(v3Tables, hasLength(2));

      final goalIndexes = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_goal%'",
          )
          .get();
      expect(
        goalIndexes.map((r) => r.data['name']).toSet(),
        <Object?>{
          'idx_goal_kind_period',
          'idx_goal_parent',
          'idx_goal_domain',
          'idx_goal_link_goal',
          'idx_goal_link_target',
        },
      );

      final userVersion =
          await upgraded.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data['user_version'], 3);

      final integrity =
          await upgraded.customSelect('PRAGMA integrity_check').getSingle();
      expect(integrity.data['integrity_check'], 'ok');

      await upgraded.close();
    });

    test('v2 库升级到 v3：只新增目标两表，循环任务两表原样保留', () async {
      final dir = Directory.systemTemp.createTempSync('actlog_migration_v3');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}${Platform.pathSeparator}actlog.db');

      // v2 那两张表与四个索引的 CREATE 语句，从一个 drift 建出来的库里抄 ——
      // v2 与 v3 里它们逐字相同，所以抄过来不会漂移（不手抄 DDL 文本）。
      final source = openInMemoryActLogDatabase();
      await source.customSelect('SELECT 1').get();
      final v2Sql = await _entitySql(source, <String>[
        'recurring_task',
        'recurring_occurrence',
        'idx_recurring_task_active',
        'idx_recurring_task_updated_at',
        'idx_recurring_occurrence_date',
        'idx_recurring_occurrence_updated_at',
      ]);
      await source.close();

      // 造一个**真正的 v2 库**：v1 的 14 张 + 循环任务 2 张 + 4 个索引，
      // 库里**没有** goal / goal_link，user_version = 2。
      final raw = sqlite.sqlite3.open(file.path);
      for (final statement in splitSqlStatements(readSchemaV1Sql())) {
        raw.execute(statement);
      }
      for (final statement in v2Sql) {
        raw.execute(statement);
      }
      raw.execute('PRAGMA user_version = 2');
      raw.close();

      final upgraded = openActLogDatabase(file);
      final tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(18));

      // 循环任务那两张表**没被重建**（v2 → v3 只补目标表）。
      final v2Tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('recurring_task', 'recurring_occurrence')",
          )
          .get();
      expect(v2Tables, hasLength(2));

      final v3Tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('goal', 'goal_link')",
          )
          .get();
      expect(v3Tables, hasLength(2));

      final goalIndexes = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_goal%'",
          )
          .get();
      expect(
        goalIndexes.map((r) => r.data['name']).toSet(),
        <Object?>{
          'idx_goal_kind_period',
          'idx_goal_parent',
          'idx_goal_domain',
          'idx_goal_link_goal',
          'idx_goal_link_target',
        },
      );

      final userVersion =
          await upgraded.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data['user_version'], 3);

      await upgraded.close();
    });
  });
}

/// 从一个已建好的 drift 库里取出若干实体的 CREATE 语句（表 / 索引）。
Future<List<String>> _entitySql(
  ActLogDatabase db,
  List<String> names,
) async {
  final result = <String>[];
  for (final String name in names) {
    final row = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE name = ? AND sql IS NOT NULL",
          variables: <Variable<Object>>[Variable<String>(name)],
        )
        .getSingle();
    result.add(row.data['sql']! as String);
  }
  return result;
}
