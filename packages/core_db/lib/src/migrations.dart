// =============================================================================
// core_db · 迁移框架
// =============================================================================
// 权威 DDL：docs/schema_v1.sql（FROZEN @ P0-D2）。
//
// onCreate 做什么：
//   drift 会把 lib/src/tables.dart 的 TableDef 渲染成 CREATE TABLE / CREATE INDEX
//   语句并执行。tables.dart 是 schema_v1.sql 的逐字段转写，所以 onCreate 产生的
//   库结构与 schema_v1.sql **等价**。这份等价性不是靠人眼保证，而是由
//   test/schema_consistency_test.dart 拿两个真实库逐项比对（表/列/约束/索引）。
//
// 回滚策略（SQLite 没有真正的 down migration）：
//   SQLite 不支持 DROP COLUMN / 改约束，drift 的 alterTable 走的是
//   「建临时表 → 拷数据 → 换名」，那是**升级**手段，不是回滚手段。
//   因此本项目**不做 down migration**，回滚策略是「恢复快照」：
//     1. core_backup 在每日/每周/手动时点生成快照（snapshot_meta 记录索引）；
//     2. 需要回滚时，用最新快照文件整库替换当前库文件；
//     3. 回滚后重跑 PRAGMA integrity_check，并把 sync_state.cursor 归零，
//        让同步从快照之后重新拉取。
//   若将来确实需要「迁移脚本」形式的回滚，位置约定在
//   [rollbackScriptPath]，当前为占位（P0 只有一个版本，无历史迁移可回滚）。
//
// 连接级 PRAGMA（foreign_keys 等）**不在** beforeOpen 里设：
//   SQLite 的 foreign_keys 是连接级开关，且在事务内设置无效；
//   真正的设置点在 connection.dart 的 setup 回调（连接建立时执行）。
// =============================================================================

import 'package:drift/drift.dart';

/// 当前 schema 版本。
///
/// schema v1 = 14 张表（权威 DDL：docs/schema_v1.sql，已 FROZEN）。
/// schema v2 = v1 + 2 张循环任务表（recurring_task / recurring_occurrence）。
/// 改动结构 = 版本号 +1 + 迁移分支，不允许原地改既有表的定义。
const int currentSchemaVersion = 2;

/// v2 新增的 schema 实体（两张表 + 各自的索引）。
///
/// 升级分支按名字**精确**挑出这些实体，其余 14 张表与 25 个索引一字不动。
/// 名字与 `tables.dart` 的 `@TableIndex` / `tableName` 逐字对应 ——
/// 改名会静默跳过建索引，因此 `test/migration_test.dart` 断言了 v1 → v2
/// 升级后这两张表的索引确实存在。
const Set<String> schemaV2EntityNames = <String>{
  'recurring_task',
  'recurring_occurrence',
  'idx_recurring_task_active',
  'idx_recurring_task_updated_at',
  'idx_recurring_occurrence_date',
  'idx_recurring_occurrence_updated_at',
};

/// 权威 DDL 文件路径（仓库相对路径）。
const String schemaV1SqlPath = 'docs/schema_v1.sql';

/// 回滚脚本约定位置（占位，当前无历史迁移可回滚）。
const String rollbackScriptPath = 'docs/migrations/rollback_v1.sql';

/// 构造迁移策略。
///
/// [beforeOpenHook] 在库打开后、第一条业务查询前执行（可选，默认不做任何事）。
MigrationStrategy buildMigrationStrategy({
  Future<void> Function()? beforeOpenHook,
}) {
  return MigrationStrategy(
    // 空库 → v1：按 tables.dart 的 TableDef 建全部表与索引。
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    // 老库 → 新版本。
    //
    // v0 = 尚无正式发布版本的历史空库（结构上等同于空库），因此 v0 → v2
    // 直接建全表即可，不需要搬数据。
    // v1 → v2 是**增量**迁移：只补两张循环任务表，既有 14 张表的数据一行不动。
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 1 && to >= 1) {
        await m.createAll();
        return;
      }
      if (from < 2 && to >= 2) {
        // 注意：`Migrator.createTable` **不建索引** —— 只有 `createAll` 才会
        // 遍历 `Index` 实体。所以这里按 entityName 精确挑出 v2 实体（两张表 +
        // 四个索引）逐个 create()，否则升级后的库会缺索引。
        for (final entity in m.database.allSchemaEntities) {
          if (schemaV2EntityNames.contains(entity.entityName)) {
            await m.create(entity);
          }
        }
        return;
      }
      throw StateError('未实现的迁移路径：v$from → v$to');
    },

    // 打开后、第一条业务查询前的钩子。
    beforeOpen: (OpeningDetails details) async {
      await beforeOpenHook?.call();
    },
  );
}
