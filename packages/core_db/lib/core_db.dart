// =============================================================================
// core_db · 知行日志 ActLog 的数据库层
// =============================================================================
// 纯 Dart 包（不依赖 flutter），因此可以直接 `dart test`。
// 权威 schema：docs/schema_v1.sql（仓库根目录）。
// =============================================================================

/// 知行日志 ActLog 的数据库层（drift + SQLite）。
library;

export 'src/tables.dart';
export 'src/connection.dart';
export 'src/migrations.dart';
export 'src/oplog_writer.dart';
