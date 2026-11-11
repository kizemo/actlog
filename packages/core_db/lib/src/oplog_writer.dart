// =============================================================================
// core_db · oplog 写入拦截层（P0-5）
// =============================================================================
// 这是全项目**最不能推迟**的一块：oplog 是同步与灾难恢复的唯一依据，
// 事后补写历史在技术上不可能（无法还原「当时改了哪些字段」）。
//
// 铁律：
//   1. 所有业务表的写操作（insert / update / delete）必须经过 [writeWithOplog]，
//      它保证「业务写入 + oplog 落痕」在**同一个事务**里：
//      业务写入抛异常 → 整个事务回滚 → oplog 记录也没了（不会出现「改了但没留痕」）。
//   2. oplog 的 payload 是**字段级 diff**（只含变更的字段名和值），不是整行快照。
//   3. lamport 来自本机单调计数器，存放在 sync_state 的 'lamport' 键。
//   4. op 区分 upsert / delete；delete 时 payload 记 `{"deleted_at": <ms>}`。
//   5. 派生表 / 本机表**绝不入 oplog** —— 见 [syncedTables] 白名单。
//      habit_score 是算法产物、sync_state 与 snapshot_meta 是本机状态，
//      同步它们会产生「派生索引与源数据不一致」这类不可修复的分歧。
// =============================================================================

import 'dart:convert';

import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

/// 参与同步的表（白名单）—— 只有这些表会产生 oplog 记录。
///
/// 共 12 张：settings, day_log, plan_item, todo, habit, habit_checkin,
/// project, project_milestone, project_increment, reminder,
/// recurring_task, recurring_occurrence。
///
/// 两张 recurring 表必须同步，理由不是「看着该同步」而是**数据一致性**：
/// · `recurring_task` 是用户定义，跨设备必须一致，否则换台机器规则凭空消失；
/// · `recurring_occurrence` 是物化凭证，不同步 ⇒ 新设备认为「一条都没物化过」
///   ⇒ 再物化一次 ⇒ `plan_item`（同步表，原有条目会被拉回来）里出现**重复条目**。
///   凭证必须跟规则一起走，缺一不可。
const Set<String> syncedTables = <String>{
  TableNames.settings,
  TableNames.dayLog,
  TableNames.planItem,
  TableNames.todo,
  TableNames.habit,
  TableNames.habitCheckin,
  TableNames.project,
  TableNames.projectMilestone,
  TableNames.projectIncrement,
  TableNames.reminder,
  TableNames.recurringTask,
  TableNames.recurringOccurrence,
};

/// 本机表（派生 / 游标 / 快照）—— **绝不入 oplog**。
const Set<String> localOnlyTables = <String>{
  TableNames.habitScore,
  TableNames.syncState,
  TableNames.snapshotMeta,
};

/// 全部 16 张表。
const Set<String> allTables = <String>{
  ...syncedTables,
  ...localOnlyTables,
  TableNames.oplog,
};

/// sync_state 中存放 lamport 计数器的键。
const String lamportStateKey = 'lamport';

/// sync_state 中存放本机设备 ID 的键。
const String deviceIdStateKey = 'device_id';

/// 判断某张表是否参与同步（是否允许落 oplog）。
bool isSyncedTable(String table) => syncedTables.contains(table);

/// oplog 写入器。
///
/// 典型用法（仓储层）：
/// ```dart
/// final writer = OplogWriter(db, deviceId: 'dev-1');
/// await writer.writeWithOplog(
///   table: TableNames.todo,
///   id: todo.id,
///   changedFields: {'status': 'done', 'updated_at': now},
///   write: () => db.into(db.todo).insert(companion),
/// );
/// ```
class OplogWriter {
  /// 绑定到数据库。
  ///
  /// [deviceId] 省略时从 sync_state 的 'device_id' 键读取；没有则生成一个并写回。
  OplogWriter(this.db, {this.deviceId});

  /// 目标数据库。
  final ActLogDatabase db;

  /// 本机设备 ID（可为空，为空时自动解析）。
  final String? deviceId;

  /// 统一的写入口：业务写入与 oplog 落痕在同一个事务内。
  ///
  /// [write] 里的业务写入若抛异常，整个事务回滚 —— oplog 记录随之消失。
  /// 这正是「写了业务数据但没留痕」被禁止的保证。
  ///
  /// [changedFields] 是**字段级 diff**（只含变更字段），upsert 时写进 payload。
  /// [isDelete] 为 true 时写 delete 记录，payload 为 `{"deleted_at": <ms>}`。
  Future<T> writeWithOplog<T>({
    required String table,
    required String id,
    required Future<T> Function() write,
    Map<String, Object?> changedFields = const <String, Object?>{},
    bool isDelete = false,
    int? deletedAt,
  }) {
    _assertSyncedTable(table);
    return db.transaction(() async {
      final result = await write();
      if (isDelete) {
        await recordDelete(table, id, deletedAt: deletedAt);
      } else {
        await recordUpsert(table, id, changedFields);
      }
      return result;
    });
  }

  /// 本机表（派生 / 游标 / 快照）的写入口 —— **不产生 oplog**。
  Future<T> writeLocal<T>({required Future<T> Function() write}) {
    return db.transaction(write);
  }

  /// 记录一次 upsert（payload = 字段级 diff 的 JSON）。
  ///
  /// 必须在事务内调用（用 [writeWithOplog] 即可）。
  Future<int> recordUpsert(
    String table,
    String id,
    Map<String, Object?> changedFields,
  ) {
    _assertSyncedTable(table);
    return _append(table: table, id: id, op: 'upsert', fields: changedFields);
  }

  /// 记录一次删除（payload 为 `{"deleted_at": <ms>}`）。
  ///
  /// 必须在事务内调用（用 [writeWithOplog] 即可）。
  Future<int> recordDelete(String table, String id, {int? deletedAt}) {
    _assertSyncedTable(table);
    return _append(
      table: table,
      id: id,
      op: 'delete',
      fields: <String, Object?>{'deleted_at': deletedAt ?? nowMillis()},
    );
  }

  /// 追加一条 oplog 记录，返回自增 id。
  Future<int> _append({
    required String table,
    required String id,
    required String op,
    required Map<String, Object?> fields,
  }) async {
    final device = await resolveDeviceId();
    final lamport = await nextLamport();
    final now = nowMillis();

    return db.into(db.oplog).insert(
      OplogCompanion.insert(
        entityTable: table,
        entityId: id,
        op: op,
        payload: Value<String>(jsonEncode(fields)),
        lamport: lamport,
        deviceId: device,
        createdAt: now,
      ),
    );
  }

  /// 取下一个 lamport 值（本机单调递增）。
  ///
  /// 计数器存在 sync_state 的 'lamport' 键里，读-改-写必须整体在同一个事务内，
  /// 否则并发写会拿到相同的 lamport。
  Future<int> nextLamport() async {
    final row = await (db.select(db.syncState)
          ..where((t) => t.key.equals(lamportStateKey)))
        .getSingleOrNull();

    final next = (int.tryParse(row?.value ?? '') ?? 0) + 1;
    final now = nowMillis();
    final device = deviceId ?? await resolveDeviceId();

    if (row == null) {
      await db.into(db.syncState).insert(
        SyncStateCompanion.insert(
          id: lamportStateKey,
          key: lamportStateKey,
          value: Value<String>('$next'),
          createdAt: now,
          updatedAt: now,
          originDeviceId: device,
        ),
      );
    } else {
      await (db.update(db.syncState)..where((t) => t.id.equals(row.id))).write(
        SyncStateCompanion(
          value: Value<String>('$next'),
          updatedAt: Value<int>(now),
          rev: Value<int>(row.rev + 1),
        ),
      );
    }
    return next;
  }

  /// 解析本机设备 ID；没有则生成一个写进 sync_state。
  Future<String> resolveDeviceId() async {
    final injected = deviceId;
    if (injected != null && injected.isNotEmpty) {
      return injected;
    }

    final row = await (db.select(db.syncState)
          ..where((t) => t.key.equals(deviceIdStateKey)))
        .getSingleOrNull();
    if (row != null && row.value.isNotEmpty) {
      return row.value;
    }

    final generated = 'dev-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final now = nowMillis();
    await db.into(db.syncState).insert(
      SyncStateCompanion.insert(
        id: deviceIdStateKey,
        key: deviceIdStateKey,
        value: Value<String>(generated),
        createdAt: now,
        updatedAt: now,
        originDeviceId: generated,
      ),
    );
    return generated;
  }

  void _assertSyncedTable(String table) {
    if (!syncedTables.contains(table)) {
      throw ArgumentError(
        '表 "$table" 不参与同步，不得写入 oplog。'
        '可同步的表：${syncedTables.join(', ')}',
      );
    }
  }
}

/// 当前时刻（Unix 毫秒）。
int nowMillis() => DateTime.now().millisecondsSinceEpoch;
