// =============================================================================
// core_db · 迁移框架门禁（G4）
// =============================================================================
// 验证：schema 版本 = 1、user_version 落库、integrity_check 通过、
//       外键开关生效、重开已有库不会重复建表也不会丢数据。
// =============================================================================

import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

import 'support/schema_source.dart';

void main() {
  group('迁移框架', () {
    test('schema 版本常量 = 2', () {
      expect(currentSchemaVersion, 2);
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
      expect(tables, hasLength(16));
      expect(await second.select(second.todo).get(), hasLength(1));

      final userVersion =
          await second.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data['user_version'], currentSchemaVersion);

      await second.close();
    });

    test('v1 库升级到 v2：只新增两张表，旧数据原样保留', () async {
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
      expect(tables, hasLength(16));
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

      final userVersion =
          await upgraded.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data['user_version'], 2);

      await upgraded.close();
    });
  });
}
