// =============================================================================
// 坏数据样例生成器 + 门禁自检
// =============================================================================
// 用途：证明门禁脚本**真的有牙**。
//
// 做法：
//   1. 造一份「被中和」的 schema（把 CHECK / UNIQUE / FOREIGN KEY 约束体
//      换成恒真或无害形式）
//   2. 跑与 g3_schema_check 相同的核心断言 —— 它必须**失败**
//   3. 如果它仍然通过，说明门禁是假牙，必须修门禁而不是修样例
//
// 运行：node tools/gates/bad-fixtures/self_test.mjs
//
// ⚠️ 踩坑记录（保留下来，避免后人重犯）：
//   坑 1：schema_v1.sql 里部分约束是**跨行**的，例如
//         CONSTRAINT plan_item_quadrant_check
//           CHECK (quadrant IS NULL OR quadrant IN ('Q1','Q2','Q3','Q4')),
//         「按行正则匹配 CONSTRAINT ... CHECK (...)」会漏掉它们 ——
//         表现为「破坏后 schema 仍然拒绝 Q9」，即坏样例根本没破坏约束。
//   坑 2：直接**删除**约束文本会破坏逗号结构，留下 `, )` 之类语法错，
//         而且跨行 + 尾逗号组合起来很难做对。
//   解法：不做文本删除，改做「**中和**」—— 把约束体替换成恒真式
//         `CHECK (1=1)` / `UNIQUE (id)`。替换后的语法天然合法，
//         约束语义却已失效，正好用来验证门禁的判别力。
// =============================================================================
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..', '..');
const SCHEMA = join(ROOT, 'docs', 'schema_v1.sql');

const goodSql = readFileSync(SCHEMA, 'utf8');

let failures = 0;
function assert(name, cond, extra = '') {
  if (cond) {
    console.log(`  PASS  ${name}`);
  } else {
    failures++;
    console.log(`  FAIL  ${name}${extra ? ' :: ' + extra : ''}`);
  }
}

/**
 * 找出所有指定类型约束的文本范围。
 * @param {string} sql 完整 DDL
 * @param {string} kindPattern 紧跟在约束名后的关键字（'CHECK' / 'UNIQUE' / 'FOREIGN KEY'）
 * @returns {{start:number,end:number,name:string}[]}
 */
function findConstraintSpans(sql, kindPattern) {
  const spans = [];
  const re = new RegExp(`CONSTRAINT\\s+(\\w+)\\s+${kindPattern}`, 'gi');
  let m;
  while ((m = re.exec(sql)) !== null) {
    const start = m.index;
    const name = m[1];
    const after = sql.slice(start);
    let end;
    if (/^CONSTRAINT\s+\w+\s+FOREIGN KEY/i.test(m[0])) {
      // FOREIGN KEY (cols) REFERENCES tbl (cols) ON DELETE ACTION
      const p = after.indexOf('(');
      let depth = 0;
      let i = p;
      for (; i < after.length; i++) {
        if (after[i] === '(') depth++;
        else if (after[i] === ')') {
          depth--;
          if (depth === 0) { i++; break; }
        }
      }
      const tail = after.slice(i);
      const od = /ON\s+DELETE\s+(SET\s+NULL|CASCADE|RESTRICT|NO\s+ACTION)/i.exec(tail);
      end = start + (od ? i + od.index + od[0].length : i);
    } else {
      // CHECK (...) / UNIQUE (...) —— 括号配对扫描
      const p = after.indexOf('(');
      let depth = 0;
      let i = p;
      for (; i < after.length; i++) {
        if (after[i] === '(') depth++;
        else if (after[i] === ')') {
          depth--;
          if (depth === 0) { i++; break; }
        }
      }
      end = start + i;
    }
    spans.push({ start, end, name });
  }
  return spans;
}

/**
 * 中和指定类型的约束 —— 把约束体换成恒真/无害形式，语法保持合法。
 * @param {string} sql
 * @param {string} kindPattern
 * @returns {string}
 */
function neutralizeConstraints(sql, kindPattern) {
  const spans = findConstraintSpans(sql, kindPattern);
  let out = sql;
  // 倒序替换，保证前面 span 的下标不受影响
  for (const span of spans.sort((a, b) => b.start - a.start)) {
    const replacement = kindPattern.startsWith('UNIQUE')
      ? `CONSTRAINT ${span.name} UNIQUE (id)`
      : `CONSTRAINT ${span.name} CHECK (1=1)`;
    out = out.slice(0, span.start) + replacement + out.slice(span.end);
  }
  return out;
}

const NOW = 1760000000000;

console.log('== 坏数据自检：门禁必须有牙 ==\n');

// ---------------------------------------------------------------------------
// 坏样例 1：中和全部 CHECK 约束
// ---------------------------------------------------------------------------
console.log('坏样例 1：中和所有 CHECK 约束');
const brokenSql = neutralizeConstraints(goodSql, 'CHECK\\b');

const goodDb = new DatabaseSync(':memory:');
goodDb.exec(goodSql);
const badDb = new DatabaseSync(':memory:');
badDb.exec(brokenSql);

const insertBadQuadrant = (db) => {
  try {
    db.prepare(`INSERT INTO plan_item (id,date,title,quadrant,created_at,updated_at,origin_device_id,rev)
                VALUES (?,?,?,?,?,?,?,?)`).run('p1', '2026-01-01', 'x', 'Q9', NOW, NOW, 'd', 1);
    return false; // 没报错 = 约束没牙
  } catch {
    return true;
  }
};

assert('完整 schema 拒绝 Q9', insertBadQuadrant(goodDb));
assert('中和后 schema 放行 Q9（证明该坏样例确实能破坏约束）', !insertBadQuadrant(badDb));

const insertBadMood = (db) => {
  try {
    db.prepare(`INSERT INTO day_log (id,date,mood_1,created_at,updated_at,origin_device_id,rev)
                VALUES (?,?,?,?,?,?,?)`).run('d9', '2026-01-02', 99, NOW, NOW, 'd', 1);
    return false;
  } catch {
    return true;
  }
};
assert('完整 schema 拒绝 mood=99', insertBadMood(goodDb));
assert('中和后 schema 放行 mood=99', !insertBadMood(badDb));

// ---------------------------------------------------------------------------
// 坏样例 2：中和 UNIQUE 约束
// ---------------------------------------------------------------------------
console.log('\n坏样例 2：中和 UNIQUE 约束');
const brokenUniqueSql = neutralizeConstraints(goodSql, 'UNIQUE\\b');
const badDb2 = new DatabaseSync(':memory:');
badDb2.exec(brokenUniqueSql);

const insertDup = (db) => {
  db.prepare(`INSERT INTO day_log (id,date,created_at,updated_at,origin_device_id,rev)
              VALUES (?,?,?,?,?,?)`).run('d1', '2026-01-01', NOW, NOW, 'd', 1);
  try {
    db.prepare(`INSERT INTO day_log (id,date,created_at,updated_at,origin_device_id,rev)
                VALUES (?,?,?,?,?,?)`).run('d2', '2026-01-01', NOW, NOW, 'd', 1);
    return false;
  } catch {
    return true;
  }
};

const goodDb2 = new DatabaseSync(':memory:');
goodDb2.exec(goodSql);
assert('完整 schema 拒绝重复 date', insertDup(goodDb2));
assert('中和后 schema 放行重复 date', !insertDup(badDb2));

// ---------------------------------------------------------------------------
// 坏样例 3：中和外键约束
// ---------------------------------------------------------------------------
console.log('\n坏样例 3：中和外键约束');
const brokenFkSql = neutralizeConstraints(goodSql, 'FOREIGN KEY');
const badDb3 = new DatabaseSync(':memory:');
badDb3.exec(brokenFkSql);

const insertOrphan = (db) => {
  try {
    db.prepare(`INSERT INTO habit_checkin (id,habit_id,date,created_at,updated_at,origin_device_id,rev)
                VALUES (?,?,?,?,?,?,?)`).run('hc1', 'no-such-habit', '2026-01-01', NOW, NOW, 'd', 1);
    return false;
  } catch {
    return true;
  }
};

const goodDb3 = new DatabaseSync(':memory:');
goodDb3.exec(goodSql);
goodDb3.exec('PRAGMA foreign_keys = ON');
badDb3.exec('PRAGMA foreign_keys = ON');
assert('完整 schema 拒绝孤儿打卡', insertOrphan(goodDb3));
assert('中和后 schema 放行孤儿打卡', !insertOrphan(badDb3));

// ---------------------------------------------------------------------------
// 坏样例 4：漏一张表
// ---------------------------------------------------------------------------
console.log('\n坏样例 4：漏掉 oplog 表');
// 精确匹配 oplog 表体：从 "CREATE TABLE oplog (" 到该表自己的 ");" 结束。
// ⚠️ 不能用贪婪的 [\s\S]* —— 会把后面所有表一起吞掉。
// ⚠️ 同时必须删掉 oplog 的索引：CREATE INDEX ... ON oplog(...) 引用了
//    不存在的表，建库时会报 "no such table: main.oplog"，
//    那样就变成「建库就炸」，而不是「表数量少了一张」—— 测的就不是想测的东西了。
const missingTableSql = goodSql
  .replace(/CREATE TABLE oplog \(.*?\n\);/s, '')
  .replace(/CREATE INDEX idx_oplog_\w+ ON oplog[^;]*;/g, '');
const badDb4 = new DatabaseSync(':memory:');
badDb4.exec(missingTableSql);
const tables4 = badDb4
  .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
  .all();
assert('破坏后表数量 = 13（少于 14，门禁应捕获）', tables4.length === 13, `实际 ${tables4.length}`);

// ---------------------------------------------------------------------------
// 坏样例 5：漏掉关键索引
// ---------------------------------------------------------------------------
console.log('\n坏样例 5：删掉 idx_plan_item_date 索引');
const missingIdxSql = goodSql.replace(/CREATE INDEX idx_plan_item_date ON plan_item \(date\);/, '');
const badDb5 = new DatabaseSync(':memory:');
badDb5.exec(missingIdxSql);
const idx5 = badDb5.prepare("SELECT name FROM sqlite_master WHERE type='index'").all().map((r) => r.name);
assert('破坏后 idx_plan_item_date 缺失', !idx5.includes('idx_plan_item_date'));

goodDb.close(); badDb.close(); goodDb2.close(); badDb2.close();
goodDb3.close(); badDb3.close(); badDb4.close(); badDb5.close();

console.log(`\n${'='.repeat(60)}`);
if (failures === 0) {
  console.log('坏数据自检通过：门禁确实有牙（坏样例都能破坏对应约束）');
  console.log('='.repeat(60));
  process.exit(0);
} else {
  console.log(`坏数据自检失败：${failures} 项不符 —— 门禁可能是假牙`);
  console.log('='.repeat(60));
  process.exit(1);
}
