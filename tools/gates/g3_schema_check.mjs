// =============================================================================
// schema_v1.sql 校验器（不依赖 Dart，用 node:sqlite 实跑）
// 用途：门禁 G3 的「schema 自检」部分 + 约束有牙验证
// 运行：node tools/gates/g3_schema_check.mjs
//
// 纪律：本脚本自身也必须「有牙」——
//   若把 schema 里的 CHECK 约束全部删掉，本脚本必须失败。
//   验证方法见同目录 bad-fixtures/README.md。
// =============================================================================
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..');
const SCHEMA = join(ROOT, 'docs', 'schema_v1.sql');

let failures = 0;
let checks = 0;
function ok(name, cond, extra = '') {
  checks++;
  if (cond) {
    console.log(`  PASS  ${name}`);
  } else {
    failures++;
    console.log(`  FAIL  ${name}${extra ? ' :: ' + extra : ''}`);
  }
}
function section(t) { console.log(`\n== ${t} ==`); }

// 期望的 14 张表（用集合比较，不依赖排序）
const EXPECTED_TABLES = new Set([
  'habit', 'habit_checkin', 'habit_score', 'day_log', 'oplog', 'plan_item',
  'project', 'project_increment', 'project_milestone', 'reminder',
  'settings', 'snapshot_meta', 'sync_state', 'todo',
]);

const schemaSql = readFileSync(SCHEMA, 'utf8');

section('1. DDL 可执行');
const db = new DatabaseSync(':memory:');
let ddlError = null;
try {
  db.exec(schemaSql);
} catch (e) {
  ddlError = e;
}
ok('schema_v1.sql 全量执行无报错', ddlError === null, ddlError ? String(ddlError.message) : '');

if (ddlError) {
  console.log('\nDDL 失败，后续检查跳过。');
  process.exit(1);
}

section('2. 表清单');
const tables = db
  .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
  .all()
  .map((r) => r.name);
ok(`表数量 = 14（实际 ${tables.length}）`, tables.length === 14);
ok('表清单完全一致（集合比较）',
   tables.length === EXPECTED_TABLES.size && tables.every((t) => EXPECTED_TABLES.has(t)),
   `实际: ${tables.join(',')}`);

section('3. 索引');
const idx = db
  .prepare("SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%' ORDER BY name")
  .all()
  .map((r) => r.name);
ok(`索引数量 >= 25（实际 ${idx.length}）`, idx.length >= 25);
// 关键查询路径必须建索引
for (const must of [
  'idx_plan_item_date', 'idx_plan_item_date_status', 'idx_plan_item_source_todo',
  'idx_todo_due_date', 'idx_todo_project', 'idx_habit_checkin_date',
  'idx_reminder_remind_at', 'idx_reminder_enabled',
  'idx_oplog_entity', 'idx_oplog_synced', 'idx_oplog_lamport',
  'idx_project_increment_project_date',
]) {
  ok(`存在索引 ${must}`, idx.includes(must));
}

section('4. integrity_check');
const integ = db.prepare('PRAGMA integrity_check').all().map((r) => r.integrity_check);
ok('PRAGMA integrity_check = ok', integ.length === 1 && integ[0] === 'ok', integ.join(','));

section('5. 外键已开启且生效');
const fkOn = db.prepare('PRAGMA foreign_keys').get();
ok('PRAGMA foreign_keys = 1', fkOn.foreign_keys === 1, `实际 ${fkOn.foreign_keys}`);

section('6. 约束有牙（故意插入坏数据，必须报错）');
const NOW = 1760000000000;
const DEV = 'dev-1';
const uid = (n) => `id-${n}`;

// 基线：一条合法数据必须能插进去
function insertBase() {
  db.exec('DELETE FROM habit; DELETE FROM todo; DELETE FROM plan_item; DELETE FROM day_log;');
  db.prepare(`INSERT INTO habit (id,name,type,schedule_type,start_date,created_at,updated_at,origin_device_id,rev)
              VALUES (?,?,?,?,?,?,?,?,?)`).run(uid('h1'), '喝水', 'count', 'daily', '2026-01-01', NOW, NOW, DEV, 1);
}
insertBase();
ok('基线：合法 habit 可插入', true);

function expectFail(name, fn) {
  checks++;
  try {
    fn();
    failures++;
    console.log(`  FAIL  ${name} :: 本应报错却成功了（约束没牙）`);
  } catch (e) {
    console.log(`  PASS  ${name} :: ${String(e.message).split('\n')[0].slice(0, 70)}`);
  }
}

// CHECK 约束
expectFail('plan_item.quadrant 非法值 Q9 被拒',
  () => db.prepare(`INSERT INTO plan_item (id,date,title,quadrant,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?,?)`).run(uid('p1'), '2026-01-01', 'x', 'Q9', NOW, NOW, DEV, 1));
expectFail('plan_item.priority_abc 非法值 D 被拒',
  () => db.prepare(`INSERT INTO plan_item (id,date,title,priority_abc,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?,?)`).run(uid('p2'), '2026-01-01', 'x', 'D', NOW, NOW, DEV, 1));
expectFail('day_log.mood_1 = 11 越界被拒',
  () => db.prepare(`INSERT INTO day_log (id,date,mood_1,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('d1'), '2026-01-01', 11, NOW, NOW, DEV, 1));
expectFail('day_log.mood_failed = 2 非法被拒',
  () => db.prepare(`INSERT INTO day_log (id,date,mood_failed,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('d2'), '2026-01-02', 2, NOW, NOW, DEV, 1));
expectFail('habit.type 非法值 crazy 被拒',
  () => db.prepare(`INSERT INTO habit (id,name,type,schedule_type,start_date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?,?,?)`).run(uid('h2'), 'x', 'crazy', 'daily', '2026-01-01', NOW, NOW, DEV, 1));
expectFail('habit_checkin.status 非法值 later 被拒',
  () => db.prepare(`INSERT INTO habit_checkin (id,habit_id,date,status,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?,?)`).run(uid('hc1'), uid('h1'), '2026-01-01', 'later', NOW, NOW, DEV, 1));
expectFail('oplog.op 非法值 merge 被拒',
  () => db.prepare(`INSERT INTO oplog (entity_table,entity_id,op,lamport,device_id,created_at)
                    VALUES (?,?,?,?,?,?)`).run('todo', 'id-t', 'merge', 1, DEV, NOW));
expectFail('reminder.target_type 非法值 plan 被拒',
  () => db.prepare(`INSERT INTO reminder (id,target_type,target_id,remind_at,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?,?)`).run(uid('r1'), 'plan', 'id-x', NOW, NOW, NOW, DEV, 1));
expectFail('project_increment 引用不存在的 project 被拒（FK）',
  () => db.prepare(`INSERT INTO project_increment (id,project_id,date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('pi1'), 'no-such-project', '2026-01-01', NOW, NOW, DEV, 1));
expectFail('habit_checkin 引用不存在的 habit 被拒（FK）',
  () => db.prepare(`INSERT INTO habit_checkin (id,habit_id,date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('hc2'), 'no-such-habit', '2026-01-01', NOW, NOW, DEV, 1));

section('7. UNIQUE 约束有牙');
// ⚠️ 必须先插入**合法基线行**，否则「重复插入」根本不重复，测试会假通过。
// （这是本脚本第一版的真实 bug：前面的非法插入全被 CHECK 拒掉，从没留下合法行。）
function expectSuccess(name, fn) {
  checks++;
  try {
    fn();
    console.log(`  PASS  ${name}`);
  } catch (e) {
    failures++;
    console.log(`  FAIL  ${name} :: 合法数据竟然插不进去 :: ${String(e.message).split('\n')[0].slice(0, 70)}`);
  }
}
expectSuccess('基线：合法 day_log 可插入',
  () => db.prepare(`INSERT INTO day_log (id,date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?)`).run(uid('d0'), '2026-01-01', NOW, NOW, DEV, 1));
expectFail('day_log.date 重复被拒',
  () => db.prepare(`INSERT INTO day_log (id,date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?)`).run(uid('d3'), '2026-01-01', NOW, NOW, DEV, 1));

expectSuccess('基线：合法 habit_checkin 可插入',
  () => db.prepare(`INSERT INTO habit_checkin (id,habit_id,date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('hc0'), uid('h1'), '2026-01-01', NOW, NOW, DEV, 1));
expectFail('habit_checkin (habit_id,date) 重复被拒',
  () => db.prepare(`INSERT INTO habit_checkin (id,habit_id,date,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('hc3'), uid('h1'), '2026-01-01', NOW, NOW, DEV, 1));

expectSuccess('基线：合法 settings 可插入',
  () => db.prepare(`INSERT INTO settings (id,key,value,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('s0'), 'k1', 'v', NOW, NOW, DEV, 1));
expectFail('settings.key 重复被拒',
  () => db.prepare(`INSERT INTO settings (id,key,value,created_at,updated_at,origin_device_id,rev)
                    VALUES (?,?,?,?,?,?,?)`).run(uid('s1'), 'k1', 'v', NOW, NOW, DEV, 1));

section('8. 业务不变量（软性，用代码层保证，此处只验 schema 支持）');
// 引用+快照：plan_item.source_todo_id 指向 todo，且 title 是快照
db.prepare(`INSERT INTO todo (id,title,created_at,updated_at,origin_device_id,rev)
            VALUES (?,?,?,?,?,?)`).run(uid('t1'), '原始标题', NOW, NOW, DEV, 1);
db.prepare(`INSERT INTO plan_item (id,date,title,source_type,source_id,source_todo_id,created_at,updated_at,origin_device_id,rev)
            VALUES (?,?,?,?,?,?,?,?,?,?)`)
  .run(uid('p3'), '2026-01-01', '快照标题', 'todo', uid('t1'), uid('t1'), NOW, NOW, DEV, 1);
db.prepare(`UPDATE todo SET title = ? WHERE id = ?`).run('改了名的待办', uid('t1'));
const snap = db.prepare(`SELECT title FROM plan_item WHERE id = ?`).get(uid('p3'));
ok('plan_item 保留标题快照，不随 todo 改名而变', snap.title === '快照标题', `实际 ${snap.title}`);

section('9. 派生表与本机表不参与同步');
// 同步表 = 业务事实，会被推送；本地表 = 派生或纯本机状态，绝不推送。
const SYNCED_TABLES = new Set([
  'settings', 'day_log', 'plan_item', 'todo', 'habit', 'habit_checkin',
  'project', 'project_milestone', 'project_increment', 'reminder', 'oplog',
]);
const LOCAL_ONLY_TABLES = new Set(['habit_score', 'sync_state', 'snapshot_meta']);
for (const t of EXPECTED_TABLES) {
  const inSynced = SYNCED_TABLES.has(t);
  const inLocal = LOCAL_ONLY_TABLES.has(t);
  ok(`${t} 归类唯一（同步表 XOR 本地表）`, inSynced !== inLocal,
     `synced=${inSynced} local=${inLocal}`);
}
ok('habit_score 属派生本地表', LOCAL_ONLY_TABLES.has('habit_score'));
ok('派生表绝不进同步表集合', !SYNCED_TABLES.has('habit_score'));

section('10. 墓碑删除可用（deleted_at 软删）');
db.prepare(`UPDATE plan_item SET deleted_at = ? WHERE id = ?`).run(NOW, uid('p3'));
const tomb = db.prepare(`SELECT COUNT(*) c FROM plan_item WHERE id = ? AND deleted_at IS NOT NULL`).get(uid('p3'));
ok('deleted_at 置位后行仍存在（软删生效）', tomb.c === 1);

db.close();

console.log(`\n${'='.repeat(60)}`);
console.log(`检查项 ${checks}，通过 ${checks - failures}，失败 ${failures}`);
console.log('='.repeat(60));
process.exit(failures === 0 ? 0 : 1);
