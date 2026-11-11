// =============================================================================
// core_db · 数据库连接
// =============================================================================
// 纪律：
//   · 纯 Dart 包，不依赖 flutter —— 可在纯 Dart VM 上 `dart test`。
//   · 外键必须开着（schema_v1.sql 顶部就写着 PRAGMA foreign_keys = ON）。
//     SQLite 的 foreign_keys 是**连接级**开关，默认关闭，且在事务内设置无效，
//     所以这里在连接建立时（setup 回调）设一次；migrations.dart 的 beforeOpen
//     **不**设 PRAGMA（事务上下文里设了也无效，等于没设）。
//   · 迁移策略见 migrations.dart。
// =============================================================================

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import 'migrations.dart';
import 'tables.dart';

part 'connection.g.dart';

/// ActLog 数据库。
///
/// 16 张表（schema v1 的 14 张 + v2 新增的 2 张循环任务表），
/// schema 版本见 [currentSchemaVersion]。
@DriftDatabase(
  tables: [
    Settings,
    DayLog,
    PlanItem,
    Todo,
    Habit,
    HabitCheckin,
    HabitScore,
    Project,
    ProjectMilestone,
    ProjectIncrement,
    Reminder,
    Oplog,
    SyncState,
    SnapshotMeta,
    RecurringTask,
    RecurringOccurrence,
  ],
)
class ActLogDatabase extends _$ActLogDatabase {
  /// 用给定的执行器打开数据库。
  ///
  /// 参数名沿用 drift 生成代码的 `e`（executor）。
  ActLogDatabase(super.e);

  /// 当前 schema 版本。
  @override
  int get schemaVersion => currentSchemaVersion;

  /// 迁移策略。
  @override
  MigrationStrategy get migration => buildMigrationStrategy();
}

/// 数据库文件名（放在用户数据目录下）。
const String defaultDatabaseFileName = 'actlog.db';

/// 打开磁盘上的数据库。
///
/// [file] 不存在时会被创建；父目录需已存在。
ActLogDatabase openActLogDatabase(
  File file, {
  bool logStatements = false,
}) {
  return ActLogDatabase(
    NativeDatabase(
      file,
      logStatements: logStatements,
      setup: (db) => applyConnectionPragmas(db, wal: true),
    ),
  );
}

/// 打开内存中的数据库（测试用；进程结束即销毁）。
ActLogDatabase openInMemoryActLogDatabase({bool logStatements = false}) {
  return ActLogDatabase(
    NativeDatabase.memory(
      logStatements: logStatements,
      setup: (db) => applyConnectionPragmas(db, wal: false),
    ),
  );
}

/// 连接级 PRAGMA。
///
/// 在连接建立时执行 —— SQLite 的 `foreign_keys` 是连接级开关且在事务内设置无效，
/// 所以必须在这里设。只读库/WAL 不可用时静默跳过，不影响主流程。
void applyConnectionPragmas(Database db, {required bool wal}) {
  db.execute('PRAGMA foreign_keys = ON;');
  db.execute('PRAGMA busy_timeout = 5000;');
  db.execute('PRAGMA synchronous = NORMAL;');
  if (wal) {
    try {
      db.execute('PRAGMA journal_mode = WAL;');
    } on Object {
      // WAL 不可用（例如数据库放在网络盘上）时退回默认日志模式。
    }
  }
}
