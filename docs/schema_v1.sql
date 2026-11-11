-- =============================================================================
-- PractiLog · schema v1 （规范化契约文件 · NORMATIVE）
-- =============================================================================
-- 地位：这是数据库结构的 **唯一权威定义**（single source of truth）。
--   · core_db 的 drift Dart 表定义必须与本文件逐字段一致；
--   · 迁移脚本 migration_v1.dart 的 onCreate 必须产生与本文件等价的结果；
--   · 门禁 G3 / G6 会用「drift 生成的 sqlite_master」与本文件做比对，
--     任何一方漂移即门禁失败。
-- 状态：FROZEN @ P0-D2。一旦冻结，改动 = schema v2 + 迁移脚本，不允许原地改。
--
-- 表总数：14 张
--   同步表（10）settings, day_log, plan_item, todo, habit, habit_checkin,
--                 project, project_milestone, project_increment, reminder
--   本机表（ 3）habit_score（派生）、sync_state、snapshot_meta
--   账本表（ 1）oplog（同步账本，本地生成，本身也参与同步）
--
-- 统一列约定（所有业务表 except oplog / sync_state / snapshot_meta）：
--   id              TEXT PRIMARY KEY      UUIDv7（按时间单调递增，便于索引局部性）
--   created_at      INTEGER NOT NULL      Unix 毫秒（UTC）
--   updated_at      INTEGER NOT NULL      Unix 毫秒（UTC）
--   deleted_at      INTEGER NULL          Unix 毫秒；非空 = 墓碑（软删除）
--   origin_device_id TEXT NOT NULL        最后一次写入该行的设备 ID
--   rev             INTEGER NOT NULL      本行本地修订号，每次本地变更 +1
--
--   rev 与 lamport 的分工（重要，别混）：
--     rev     = 单机本地单调计数器，用于「本机是否变更过」与本地缓存失效；
--     lamport = 跨设备逻辑时钟，在 oplog 中携带，用于 LWW 合并定序。
--     rev 绝不用于跨设备定序 —— 两台设备上 rev 可以相同但内容不同。
--
-- 墓碑策略：删除只置 deleted_at，不物理删除行。
--   墓碑行必须参与同步，否则对端无法感知「这条已被删」。
--   本机清理策略：保留墓碑 >= 90 天，或在收到对端确认已应用后清理（V1.1）。
--
-- 派生数据铁律：habit_score（及未来的统计缓存、标签倒排）**绝不参与同步**，
--   只存本地、新设备重算。违反此条会产生 siyuan 式的派生索引与源数据不一致。
--
-- 时间约定：日期用 TEXT 'YYYY-MM-DD'（本地日历日，不带时区）；
--           时刻用 INTEGER Unix 毫秒（UTC）。
-- =============================================================================

PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- 1. settings —— 用户配置（键值对，同步）
--    value 统一存 JSON 文本；bool 用 0/1 数字，字符串原样，结构化配置存 JSON。
-- -----------------------------------------------------------------------------
CREATE TABLE settings (
  id               TEXT    PRIMARY KEY,
  key              TEXT    NOT NULL,
  value            TEXT    NOT NULL DEFAULT '',
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT settings_key_unique UNIQUE (key)
);
CREATE INDEX idx_settings_updated_at ON settings (updated_at);

-- -----------------------------------------------------------------------------
-- 2. day_log —— 每日日志（一天一行，同步）
--    完整版字段：mode='full'；极简版：mode='minimal'。
--    复盘三段 = learning / good / improve；
--    可控-不可控二分 = controllable / uncontrollable，下一步 = next_action。
--    心态 8 维度（0–10 连续分，NULL = 未打分）：
--      mood_1 认真 / mood_2 快 / mood_3 坚守承诺 / mood_4 保证完成任务
--      mood_5 乐观 / mood_6 自信 / mood_7 爱与奉献 / mood_8 决不找借口
--    mood_failed = 今日失守（1 = 失守），承接原书 0/10 二元判定语义。
-- -----------------------------------------------------------------------------
CREATE TABLE day_log (
  id               TEXT    PRIMARY KEY,
  date             TEXT    NOT NULL,
  mode             TEXT    NOT NULL DEFAULT 'full',
  learning         TEXT    NOT NULL DEFAULT '',
  good             TEXT    NOT NULL DEFAULT '',
  improve          TEXT    NOT NULL DEFAULT '',
  controllable     TEXT    NOT NULL DEFAULT '',
  uncontrollable   TEXT    NOT NULL DEFAULT '',
  next_action      TEXT    NOT NULL DEFAULT '',
  mood_note        TEXT    NOT NULL DEFAULT '',
  mood_1           INTEGER,
  mood_2           INTEGER,
  mood_3           INTEGER,
  mood_4           INTEGER,
  mood_5           INTEGER,
  mood_6           INTEGER,
  mood_7           INTEGER,
  mood_8           INTEGER,
  mood_failed      INTEGER NOT NULL DEFAULT 0,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT day_log_date_unique UNIQUE (date),
  CONSTRAINT day_log_mode_check CHECK (mode IN ('full', 'minimal')),
  CONSTRAINT day_log_mood_failed_check CHECK (mood_failed IN (0, 1)),
  CONSTRAINT day_log_mood_1_check CHECK (mood_1 IS NULL OR (mood_1 >= 0 AND mood_1 <= 10)),
  CONSTRAINT day_log_mood_2_check CHECK (mood_2 IS NULL OR (mood_2 >= 0 AND mood_2 <= 10)),
  CONSTRAINT day_log_mood_3_check CHECK (mood_3 IS NULL OR (mood_3 >= 0 AND mood_3 <= 10)),
  CONSTRAINT day_log_mood_4_check CHECK (mood_4 IS NULL OR (mood_4 >= 0 AND mood_4 <= 10)),
  CONSTRAINT day_log_mood_5_check CHECK (mood_5 IS NULL OR (mood_5 >= 0 AND mood_5 <= 10)),
  CONSTRAINT day_log_mood_6_check CHECK (mood_6 IS NULL OR (mood_6 >= 0 AND mood_6 <= 10)),
  CONSTRAINT day_log_mood_7_check CHECK (mood_7 IS NULL OR (mood_7 >= 0 AND mood_7 <= 10)),
  CONSTRAINT day_log_mood_8_check CHECK (mood_8 IS NULL OR (mood_8 >= 0 AND mood_8 <= 10))
);
CREATE INDEX idx_day_log_updated_at ON day_log (updated_at);

-- -----------------------------------------------------------------------------
-- 3. plan_item —— 当日计划条目（同步）
--    source_type : manual(手建) / todo(从待办引用) / habit(习惯打卡回填)
--                  / project(项目动作) / increment(项目增量回填)
--    source_id   : 多态指针，指向来源实体 id；source_type='todo' 时等于 source_todo_id
--    source_todo_id : 显式外键到 todo.id —— 「引用 + 快照」模型的锚点，
--                  title 列存的是**当时的标题快照**，todo 改名不影响历史计划行
--    quadrant    : Q1 重要且紧急 / Q2 重要不紧急 / Q3 紧急不重要 / Q4 不重要不紧急
--    priority_abc: A / B / C（原书体系）
--    **两套标签都存，但同一时刻只显示一套**（设置项 priority_mode 决定显示哪个）。
--                  「同一条计划不同时显示两套」是产品铁律，见 MVP v0.2 第五章。
--    is_habit_ref: 1 = 由习惯打卡回填生成（可「转为普通条目」或「删除」）
-- -----------------------------------------------------------------------------
CREATE TABLE plan_item (
  id               TEXT    PRIMARY KEY,
  date             TEXT    NOT NULL,
  title            TEXT    NOT NULL,
  detail           TEXT    NOT NULL DEFAULT '',
  source_type      TEXT    NOT NULL DEFAULT 'manual',
  source_id        TEXT,
  source_todo_id   TEXT,
  quadrant         TEXT,
  priority_abc     TEXT,
  domain           TEXT    NOT NULL DEFAULT '',
  est_minutes      INTEGER,
  planned_start    INTEGER,
  planned_end      INTEGER,
  status           TEXT    NOT NULL DEFAULT 'pending',
  done_at          INTEGER,
  result_note      TEXT    NOT NULL DEFAULT '',
  is_habit_ref     INTEGER NOT NULL DEFAULT 0,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT plan_item_source_type_check
    CHECK (source_type IN ('manual', 'todo', 'habit', 'project', 'increment')),
  CONSTRAINT plan_item_quadrant_check
    CHECK (quadrant IS NULL OR quadrant IN ('Q1', 'Q2', 'Q3', 'Q4')),
  CONSTRAINT plan_item_priority_abc_check
    CHECK (priority_abc IS NULL OR priority_abc IN ('A', 'B', 'C')),
  CONSTRAINT plan_item_status_check
    CHECK (status IN ('pending', 'done', 'cancelled', 'deferred')),
  CONSTRAINT plan_item_is_habit_ref_check CHECK (is_habit_ref IN (0, 1)),
  CONSTRAINT plan_item_est_minutes_check CHECK (est_minutes IS NULL OR est_minutes >= 0),
  CONSTRAINT plan_item_source_todo_fk FOREIGN KEY (source_todo_id)
    REFERENCES todo (id) ON DELETE SET NULL
);
CREATE INDEX idx_plan_item_date ON plan_item (date);
CREATE INDEX idx_plan_item_date_status ON plan_item (date, status);
CREATE INDEX idx_plan_item_source_todo ON plan_item (source_todo_id);
CREATE INDEX idx_plan_item_source ON plan_item (source_type, source_id);
CREATE INDEX idx_plan_item_updated_at ON plan_item (updated_at);

-- -----------------------------------------------------------------------------
-- 4. todo —— 待办池（同步）
--    status: open / done / cancelled / archived
--    「添加到今日计划」= 在 plan_item 建行 + 写 source_todo_id + 拷 title 快照，
--    **不复制状态**。todo.completed_at 只在待办本体完成时写。
-- -----------------------------------------------------------------------------
CREATE TABLE todo (
  id               TEXT    PRIMARY KEY,
  title            TEXT    NOT NULL,
  detail           TEXT    NOT NULL DEFAULT '',
  est_minutes      INTEGER,
  due_date         TEXT,
  project_id       TEXT,
  quadrant         TEXT,
  priority_abc     TEXT,
  status           TEXT    NOT NULL DEFAULT 'open',
  completed_at     INTEGER,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT todo_status_check CHECK (status IN ('open', 'done', 'cancelled', 'archived')),
  CONSTRAINT todo_quadrant_check CHECK (quadrant IS NULL OR quadrant IN ('Q1', 'Q2', 'Q3', 'Q4')),
  CONSTRAINT todo_priority_abc_check CHECK (priority_abc IS NULL OR priority_abc IN ('A', 'B', 'C')),
  CONSTRAINT todo_est_minutes_check CHECK (est_minutes IS NULL OR est_minutes >= 0),
  CONSTRAINT todo_project_fk FOREIGN KEY (project_id)
    REFERENCES project (id) ON DELETE SET NULL
);
CREATE INDEX idx_todo_status ON todo (status);
CREATE INDEX idx_todo_due_date ON todo (due_date);
CREATE INDEX idx_todo_project ON todo (project_id);
CREATE INDEX idx_todo_updated_at ON todo (updated_at);

-- -----------------------------------------------------------------------------
-- 5. habit —— 习惯定义（同步）
--    type          : normal(普通) / count(计数型) / avoid(避免型) / checklist(清单式)
--    target_count  : 计数型目标值（如喝水 8 杯）；避免型为 0（目标=不发生）
--    target_unit   : 计数单位（杯 / 公里 / 分钟）
--    schedule_type : daily(每日) / weekly_n(每周 N 次) / weekdays(指定星期)
--    weekly_n      : schedule_type='weekly_n' 时的 N
--    weekdays      : schedule_type='weekdays' 时的星期集合，'1,3,5'（1=周一..7=周日）
--    checklist_json: type='checklist' 时的子项列表（JSON 数组字符串）。
--                    【有意简化】用 JSON 而不建第 15 张表 —— 子项本身不需要独立
--                    查询与排序，且在 oplog 里以整列替换同步即可。
--                    触发重新设计的条件：需要「按子项做统计」或「子项级提醒」。
--    paused_until  : 合法中断出口（假期模式）—— 该日期前不计入连续天数、不提示断签
--    archived      : 归档（保留历史，不计入活跃习惯）
-- -----------------------------------------------------------------------------
CREATE TABLE habit (
  id               TEXT    PRIMARY KEY,
  name             TEXT    NOT NULL,
  description      TEXT    NOT NULL DEFAULT '',
  type             TEXT    NOT NULL DEFAULT 'normal',
  target_count     REAL,
  target_unit      TEXT    NOT NULL DEFAULT '',
  schedule_type    TEXT    NOT NULL DEFAULT 'daily',
  weekly_n         INTEGER,
  weekdays         TEXT    NOT NULL DEFAULT '',
  checklist_json   TEXT    NOT NULL DEFAULT '[]',
  domain           TEXT    NOT NULL DEFAULT '',
  start_date       TEXT    NOT NULL,
  archived         INTEGER NOT NULL DEFAULT 0,
  paused_until     TEXT,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT habit_type_check CHECK (type IN ('normal', 'count', 'avoid', 'checklist')),
  CONSTRAINT habit_schedule_type_check CHECK (schedule_type IN ('daily', 'weekly_n', 'weekdays')),
  CONSTRAINT habit_archived_check CHECK (archived IN (0, 1)),
  CONSTRAINT habit_target_count_check CHECK (target_count IS NULL OR target_count >= 0),
  CONSTRAINT habit_weekly_n_check CHECK (weekly_n IS NULL OR weekly_n BETWEEN 1 AND 7)
);
CREATE INDEX idx_habit_archived ON habit (archived);
CREATE INDEX idx_habit_updated_at ON habit (updated_at);

-- -----------------------------------------------------------------------------
-- 6. habit_checkin —— 打卡记录（同步）
--    status : done(完成) / skip(跳过，不打断连续) / failed(失败)
--    value  : 计数型的完成量（喝水 8 杯 → value=8）；普通/避免型用 1/0
-- -----------------------------------------------------------------------------
CREATE TABLE habit_checkin (
  id               TEXT    PRIMARY KEY,
  habit_id         TEXT    NOT NULL,
  date             TEXT    NOT NULL,
  value            REAL    NOT NULL DEFAULT 1,
  status           TEXT    NOT NULL DEFAULT 'done',
  note             TEXT    NOT NULL DEFAULT '',
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT habit_checkin_status_check CHECK (status IN ('done', 'skip', 'failed')),
  CONSTRAINT habit_checkin_pair_unique UNIQUE (habit_id, date),
  CONSTRAINT habit_checkin_habit_fk FOREIGN KEY (habit_id)
    REFERENCES habit (id) ON DELETE CASCADE
);
CREATE INDEX idx_habit_checkin_date ON habit_checkin (date);
CREATE INDEX idx_habit_checkin_updated_at ON habit_checkin (updated_at);

-- -----------------------------------------------------------------------------
-- 7. habit_score —— 习惯强度评分与连续天数（**本地派生，不同步**）
--    ❌ 不同步。新设备首次同步后本地重算。
--    理由：连续天数与强度是**算法产物**，不是用户直接录入的事实；
--          同步它 = 两端算法版本不一致时产生永久性数据不一致。
--    score          : 当日强度评分（0–100，由衰减算法算出）
--    streak         : 当前连续天数
--    longest_streak : 历史最长连续天数
-- -----------------------------------------------------------------------------
CREATE TABLE habit_score (
  id               TEXT    PRIMARY KEY,
  habit_id         TEXT    NOT NULL,
  date             TEXT    NOT NULL,
  score            REAL    NOT NULL DEFAULT 0,
  streak           INTEGER NOT NULL DEFAULT 0,
  longest_streak   INTEGER NOT NULL DEFAULT 0,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT habit_score_pair_unique UNIQUE (habit_id, date),
  CONSTRAINT habit_score_habit_fk FOREIGN KEY (habit_id)
    REFERENCES habit (id) ON DELETE CASCADE
);
CREATE INDEX idx_habit_score_habit_date ON habit_score (habit_id, date);

-- -----------------------------------------------------------------------------
-- 8. project —— 长线项目（同步）
--    status: active / paused / done / cancelled
-- -----------------------------------------------------------------------------
CREATE TABLE project (
  id               TEXT    PRIMARY KEY,
  name             TEXT    NOT NULL,
  goal             TEXT    NOT NULL DEFAULT '',
  start_date       TEXT,
  end_date         TEXT,
  domain           TEXT    NOT NULL DEFAULT '',
  status           TEXT    NOT NULL DEFAULT 'active',
  archived         INTEGER NOT NULL DEFAULT 0,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT project_status_check CHECK (status IN ('active', 'paused', 'done', 'cancelled')),
  CONSTRAINT project_archived_check CHECK (archived IN (0, 1))
);
CREATE INDEX idx_project_status ON project (status);
CREATE INDEX idx_project_updated_at ON project (updated_at);

-- -----------------------------------------------------------------------------
-- 9. project_milestone —— 里程碑（同步）
-- -----------------------------------------------------------------------------
CREATE TABLE project_milestone (
  id               TEXT    PRIMARY KEY,
  project_id       TEXT    NOT NULL,
  title            TEXT    NOT NULL,
  target_date      TEXT,
  achieved_at      INTEGER,
  note             TEXT    NOT NULL DEFAULT '',
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT project_milestone_project_fk FOREIGN KEY (project_id)
    REFERENCES project (id) ON DELETE CASCADE
);
CREATE INDEX idx_project_milestone_project ON project_milestone (project_id);
CREATE INDEX idx_project_milestone_target_date ON project_milestone (target_date);

-- -----------------------------------------------------------------------------
-- 10. project_increment —— 项目增量记录（同步，「不闭环」日志）
--     每次推进只追加一条，不修改历史；连续 3 天无增量触发温和停滞提示。
-- -----------------------------------------------------------------------------
CREATE TABLE project_increment (
  id               TEXT    PRIMARY KEY,
  project_id       TEXT    NOT NULL,
  date             TEXT    NOT NULL,
  plan_item_id     TEXT,
  progress         TEXT    NOT NULL DEFAULT '',
  blockers         TEXT    NOT NULL DEFAULT '',
  next_step        TEXT    NOT NULL DEFAULT '',
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT project_increment_project_fk FOREIGN KEY (project_id)
    REFERENCES project (id) ON DELETE CASCADE,
  CONSTRAINT project_increment_plan_item_fk FOREIGN KEY (plan_item_id)
    REFERENCES plan_item (id) ON DELETE SET NULL
);
CREATE INDEX idx_project_increment_project_date ON project_increment (project_id, date);
CREATE INDEX idx_project_increment_date ON project_increment (date);

-- -----------------------------------------------------------------------------
-- 11. reminder —— 独立提醒表（同步）
--     一条业务实体可挂 N 个提醒（target_type + target_id 为多态指针，不设 FK）。
--     target_type: plan_item / todo / habit / project
--     repeat_rule : none / daily / weekly / monthly / yearly
--     repeat_detail: 附加参数（如 '1,3,5' 表示周一三五；'15' 表示每月 15 日）
--     last_fired_at: 上次触发时刻，用于补触发判定
-- -----------------------------------------------------------------------------
CREATE TABLE reminder (
  id               TEXT    PRIMARY KEY,
  target_type      TEXT    NOT NULL,
  target_id        TEXT    NOT NULL,
  remind_at        INTEGER NOT NULL,
  repeat_rule      TEXT    NOT NULL DEFAULT 'none',
  repeat_detail    TEXT    NOT NULL DEFAULT '',
  enabled         INTEGER NOT NULL DEFAULT 1,
  last_fired_at    INTEGER,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT reminder_target_type_check
    CHECK (target_type IN ('plan_item', 'todo', 'habit', 'project')),
  CONSTRAINT reminder_repeat_rule_check
    CHECK (repeat_rule IN ('none', 'daily', 'weekly', 'monthly', 'yearly')),
  CONSTRAINT reminder_enabled_check CHECK (enabled IN (0, 1))
);
CREATE INDEX idx_reminder_target ON reminder (target_type, target_id);
CREATE INDEX idx_reminder_remind_at ON reminder (remind_at);
CREATE INDEX idx_reminder_enabled ON reminder (enabled, remind_at);

-- -----------------------------------------------------------------------------
-- 12. oplog —— 同步账本（本地生成；本表内容参与同步）
--     **这是 P0 最不可压缩的表**：oplog 是同步与灾难恢复的唯一依据，
--     事后补写历史在技术上不可能（无法还原「当时改了哪些字段」）。
--     id        : INTEGER AUTOINCREMENT —— 必须单调递增，作为增量拉取游标。
--                 注意：此处刻意 **不用** UUIDv7 —— 增量同步要的是严格单调的序号，
--                 UUIDv7 只是「大致有序」，在中继端分页时会产生空洞与重复。
--     entity_table : 实体表名
--     entity_id    : 实体 id
--     op           : upsert / delete
--     payload      : JSON —— upsert 时是**字段级 diff**（只含变更字段），
--                    delete 时为 null 或 {"deleted_at":...}
--     lamport      : 跨设备逻辑时钟，LWW 定序用
--     device_id    : 产生该条变更的设备
--     created_at   : Unix 毫秒
--     synced       : 0 = 待推送，1 = 已确认中继已收（V1.1 启用）
-- -----------------------------------------------------------------------------
CREATE TABLE oplog (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_table  TEXT    NOT NULL,
  entity_id     TEXT    NOT NULL,
  op            TEXT    NOT NULL,
  payload       TEXT,
  lamport       INTEGER NOT NULL,
  device_id     TEXT    NOT NULL,
  created_at    INTEGER NOT NULL,
  synced        INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT oplog_op_check CHECK (op IN ('upsert', 'delete'))
);
CREATE INDEX idx_oplog_entity ON oplog (entity_table, entity_id);
CREATE INDEX idx_oplog_synced ON oplog (synced, id);
CREATE INDEX idx_oplog_lamport ON oplog (lamport);
CREATE INDEX idx_oplog_device ON oplog (device_id);

-- -----------------------------------------------------------------------------
-- 13. sync_state —— 本机同步游标（**本机，不同步**）
--     key: cursor(已拉取的最大 oplog id) / lamport(本机 lamport 计数)
--          / device_id(本机设备 ID) / channel / relay_code / last_sync_at
-- -----------------------------------------------------------------------------
CREATE TABLE sync_state (
  id               TEXT    PRIMARY KEY,
  key              TEXT    NOT NULL,
  value            TEXT    NOT NULL DEFAULT '',
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT sync_state_key_unique UNIQUE (key)
);

-- -----------------------------------------------------------------------------
-- 14. snapshot_meta —— 本地快照索引（**本机，不同步**）
--     kind: daily / weekly / monthly / manual / export
--     path : 快照文件路径
--     sha256: 快照内容哈希，用于校验与恢复
-- -----------------------------------------------------------------------------
CREATE TABLE snapshot_meta (
  id               TEXT    PRIMARY KEY,
  path             TEXT    NOT NULL,
  kind             TEXT    NOT NULL,
  sha256           TEXT    NOT NULL,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER,
  origin_device_id TEXT    NOT NULL,
  rev              INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT snapshot_meta_kind_check
    CHECK (kind IN ('daily', 'weekly', 'monthly', 'manual', 'export'))
);
CREATE INDEX idx_snapshot_meta_kind ON snapshot_meta (kind);
