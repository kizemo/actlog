// ignore_for_file: public_member_api_docs
// =============================================================================
// core_data · 仓储层集成测试（内存 SQLite，真实 drift 表结构）
// =============================================================================
// 覆盖《开发计划》P1 验收标准中「能机器判定」的部分：
//   P1-1 完整/极简切换即时生效，且极简隐藏字段不丢数据
//   P1-3 计划条目 CRUD 与状态流转
//   P1-5 四象限 / ABC 双模式互斥且切换无损
//   P1-6 回填行可转正；删除回填行不影响习惯记录
//   P1-7 复盘五段各自可独立留白
//   P1-8 任一维度为 0 ⇒ 失守标记自动为真
//
// 这里**故意不 mock drift**：唯一约束、墓碑占槽位、oplog 落库这些行为只有在
// 真实 schema 上才成立，mock 掉的正是要验的东西。
// =============================================================================

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const String _device = 'dev-test';

// 「今天」必须取**真实当天**，不能写死日期字符串。
//
// 原因：`HabitRepository.create` 的 `startDate` 默认值是 `today()`，
// 而 `listScheduledFor` 的排程判定是 `startDate <= 查询日`。
// 如果这里写死一个日期，跨日之后新建的习惯就会因为「起始日在查询日之后」
// 而不进排程 —— 2026-11-07 当天就真实复现过这个失败。
// 取真实当天 ⇒ 两者永远一致。
final String _today = today();

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: _device);
  });

  tearDown(() async {
    await db.close();
  });

  /// 建库并读回当日日志行。
  ///
  /// [date] 必须声明为可空：默认参数值要求编译期常量，而 `_today` 是运行时
  /// 取真实当天的 `final` 变量（写成 `String date = _today` 会报
  /// "Not a constant expression"，整个文件加载失败 ⇒ 40 个用例一个都不跑）。
  Future<DayLogData> newDayLog({
    String? date,
    String mode = dayModeFull,
  }) async {
    final target = date ?? _today;
    await repos.dayLog.ensureByDate(target, mode: mode);
    final row = await repos.dayLog.findByDate(target);
    expect(row, isNotNull, reason: 'ensureByDate 之后必须能读到该日日志');
    return row!;
  }

  /// 取单条标量（COUNT(*) 之类）。
  Future<Object?> scalar(String sql) async {
    final rows = await db.customSelect(sql).get();
    if (rows.isEmpty) {
      return null;
    }
    return rows.first.data.values.first;
  }

  // ===========================================================================
  // P1-1 完整 / 极简模式
  // ===========================================================================
  group('DayLogRepository · P1-1 完整/极简模式', () {
    test('ensureByDate 幂等：两次同 id，库里仍只有一行', () async {
      await repos.dayLog.ensureByDate(_today);
      final first = (await repos.dayLog.findByDate(_today))!;
      await repos.dayLog.ensureByDate(_today);
      final second = (await repos.dayLog.findByDate(_today))!;

      expect(second.id, first.id);
      expect(
        await scalar("SELECT COUNT(*) FROM day_log WHERE date = '$_today'"),
        1,
      );
    });

    test('默认是完整版，也可以按极简版创建', () async {
      expect((await newDayLog()).mode, dayModeFull);
      expect((await newDayLog(date: shiftIsoDate(_today, 1), mode: dayModeMinimal)).mode,
          dayModeMinimal);
    });

    test('已存在时不覆盖已有 mode', () async {
      await repos.dayLog.ensureByDate(_today, mode: dayModeMinimal);
      await repos.dayLog.ensureByDate(_today, mode: dayModeFull);
      expect((await repos.dayLog.findByDate(_today))!.mode, dayModeMinimal);
    });

    test('切到极简后，先前写入的复盘字段原样保留', () async {
      final row = await newDayLog();
      await repos.dayLog.saveReview(row.id, const ReviewDraft(learning: '学到 X'));
      await repos.dayLog.setMode(row.id, dayModeMinimal);

      final after = (await repos.dayLog.findByDate(_today))!;
      expect(after.mode, dayModeMinimal);
      expect(after.learning, '学到 X', reason: '极简只是隐藏字段，不得丢数据');
    });

    test('findByDate 不存在返回 null', () async {
      expect(await repos.dayLog.findByDate('2026-01-01'), isNull);
    });

    test('非法日期抛 ArgumentError', () async {
      await expectLater(
        () => repos.dayLog.findByDate('2026-02-30'),
        throwsArgumentError,
      );
      await expectLater(
        () => repos.dayLog.ensureByDate('2026-13-01'),
        throwsArgumentError,
      );
    });

    test('非法模式抛 ArgumentError', () async {
      await expectLater(
        () => repos.dayLog.ensureByDate(_today, mode: 'tiny'),
        throwsArgumentError,
      );
      final row = await newDayLog(date: shiftIsoDate(_today, 2));
      await expectLater(
        () => repos.dayLog.setMode(row.id, 'tiny'),
        throwsArgumentError,
      );
    });

    test('setMode 只改 mode 一列', () async {
      final row = await newDayLog();
      await repos.dayLog.saveReview(
        row.id,
        const ReviewDraft(good: '守时', nextAction: '先做 A 类'),
      );
      await repos.dayLog.setMode(row.id, dayModeMinimal);
      final after = (await repos.dayLog.findByDate(_today))!;
      expect(after.good, '守时');
      expect(after.nextAction, '先做 A 类');
    });
  });

  // ===========================================================================
  // P1-7 复盘五段
  // ===========================================================================
  group('DayLogRepository · P1-7 复盘五段可独立留白', () {
    test('只写一段也能成功，其余段落保持空串', () async {
      final row = await newDayLog();
      await repos.dayLog.saveReview(
        row.id,
        const ReviewDraft(nextAction: '明天先打三个电话'),
      );

      final after = (await repos.dayLog.findByDate(_today))!;
      expect(after.nextAction, '明天先打三个电话');
      expect(after.learning, '');
      expect(after.good, '');
      expect(after.improve, '');
      expect(after.controllable, '');
      expect(after.uncontrollable, '');
    });

    test('六段一起写，逐段读回一致', () async {
      final row = await newDayLog();
      await repos.dayLog.saveReview(
        row.id,
        const ReviewDraft(
          learning: 'L',
          good: 'G',
          improve: 'I',
          controllable: 'C',
          uncontrollable: 'U',
          nextAction: 'N',
        ),
      );

      final after = (await repos.dayLog.findByDate(_today))!;
      expect(
        <String>[
          after.learning,
          after.good,
          after.improve,
          after.controllable,
          after.uncontrollable,
          after.nextAction,
        ],
        <String>['L', 'G', 'I', 'C', 'U', 'N'],
      );
    });
  });

  // ===========================================================================
  // P1-8 心态 8 维 + 失守标记
  // ===========================================================================
  group('DayLogRepository · P1-8 心态与失守标记', () {
    test('任一维度为 0 ⇒ 即使传 false 也落失守', () async {
      final row = await newDayLog();
      await repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{MoodDimension.diligent: 0},
          failed: false,
          note: '',
        ),
      );

      final mood = await repos.dayLog.moodOf(row.id);
      expect(mood, isNotNull);
      expect(mood!.failed, isTrue);
      expect(
        await scalar('SELECT mood_failed FROM day_log'),
        1,
        reason: 'DB 里必须真的落 1',
      );
    });

    test('没有 0 分时可以手动标失守', () async {
      final row = await newDayLog();
      await repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{MoodDimension.fast: 7},
          failed: true,
          note: '',
        ),
      );
      expect((await repos.dayLog.moodOf(row.id))!.failed, isTrue);
    });

    test('全程非 0 且未勾选 ⇒ 不失守', () async {
      final row = await newDayLog();
      await repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{
            MoodDimension.diligent: 8,
            MoodDimension.optimistic: 9,
          },
          failed: false,
          note: '平稳',
        ),
      );

      final mood = (await repos.dayLog.moodOf(row.id))!;
      expect(mood.failed, isFalse);
      expect(mood.note, '平稳');
      expect(
        await scalar('SELECT mood_failed FROM day_log'),
        0,
      );
    });

    test('往返一致：未打分的维度不出现在 scores 里', () async {
      final row = await newDayLog();
      await repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{
            MoodDimension.keepPromise: 5,
            MoodDimension.noExcuses: 0,
          },
          failed: true,
          note: '有点累',
        ),
      );

      final mood = (await repos.dayLog.moodOf(row.id))!;
      expect(mood.scores, <MoodDimension, int>{
        MoodDimension.keepPromise: 5,
        MoodDimension.noExcuses: 0,
      });
      expect(mood.ratedCount, 2);
      expect(mood.average, 2.5);
      expect(
        await scalar('SELECT mood_1 FROM day_log WHERE mood_1 IS NULL'),
        isNull,
        reason: '未打分维度必须是 NULL 而不是 0',
      );
    });

    test('当天没有打任何分时，scores 为空且不留失守', () async {
      final row = await newDayLog();
      await repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{},
          failed: false,
          note: '',
        ),
      );

      final mood = (await repos.dayLog.moodOf(row.id))!;
      expect(mood.scores, isEmpty);
      expect(mood.average, isNull);
      expect(mood.failed, isFalse);
    });

    test('moodOf 对不存在的 id 返回 null', () async {
      expect(await repos.dayLog.moodOf('no-such-id'), isNull);
    });
  });

  // ===========================================================================
  // P1-3 计划条目 CRUD 与状态流转
  // ===========================================================================
  group('PlanItemRepository · P1-3 条目与状态', () {
    test('create 后能按日期列出', () async {
      final id = await repos.planItem.create(
        date: _today,
        title: '  写周报  ',
      );
      final items = await repos.planItem.listByDate(_today);

      expect(items, hasLength(1));
      expect(items.single.id, id);
      expect(items.single.title, '写周报', reason: '标题落库前必须 trim');
      expect(items.single.status, PlanStatus.pending.code);
      expect(items.single.sourceType, 'manual');
      expect(await repos.planItem.listByDate('2026-01-01'), isEmpty);
    });

    test('标题空白抛 ArgumentError', () async {
      await expectLater(
        () => repos.planItem.create(date: _today, title: '   '),
        throwsArgumentError,
      );
      await expectLater(
        () => repos.planItem.create(date: _today, title: ''),
        throwsArgumentError,
      );
    });

    test('estMinutes 必须在 0..1440', () async {
      await expectLater(
        () => repos.planItem.create(
          date: _today,
          title: 'x',
          estMinutes: 1441,
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => repos.planItem.create(
          date: _today,
          title: 'y',
          estMinutes: -1,
        ),
        throwsArgumentError,
      );
      final id = await repos.planItem.create(
        date: _today,
        title: 'z',
        estMinutes: 0,
      );
      expect(id, isNotEmpty);
    });

    test('状态流转：done 写 doneAt，回到 pending 清 doneAt', () async {
      final id = await repos.planItem.create(date: _today, title: '打电话');

      await repos.planItem.setStatus(id, PlanStatus.done, resultNote: '接通 3 家');
      var item = (await repos.planItem.listByDate(_today)).single;
      expect(item.status, PlanStatus.done.code);
      expect(item.doneAt, isNotNull);
      expect(item.resultNote, '接通 3 家');

      await repos.planItem.setStatus(id, PlanStatus.pending);
      item = (await repos.planItem.listByDate(_today)).single;
      expect(item.status, PlanStatus.pending.code);
      expect(item.doneAt, isNull, reason: '非 done 必须把 doneAt 清成 NULL');
      expect(item.resultNote, '接通 3 家', reason: 'resultNote 不传时保持原值');
    });

    test('deferred / cancelled 也是合法状态', () async {
      final id = await repos.planItem.create(date: _today, title: '排期项');
      await repos.planItem.setStatus(id, PlanStatus.deferred);
      expect(
        (await repos.planItem.listByDate(_today)).single.status,
        PlanStatus.deferred.code,
      );
      await repos.planItem.setStatus(id, PlanStatus.cancelled);
      expect(
        (await repos.planItem.listByDate(_today)).single.status,
        PlanStatus.cancelled.code,
      );
    });

    test('setResultNote 单独回填成果', () async {
      final id = await repos.planItem.create(date: _today, title: '整理库存');
      await repos.planItem.setResultNote(id, '清了 12 个 SKU');
      expect(
        (await repos.planItem.listByDate(_today)).single.resultNote,
        '清了 12 个 SKU',
      );
    });

    test('softDelete 只落墓碑，行仍在库里且 oplog 记 delete', () async {
      final id = await repos.planItem.create(date: _today, title: '要删掉的');
      await repos.planItem.softDelete(id);

      expect(await repos.planItem.listByDate(_today), isEmpty);
      expect(
        await scalar(
          "SELECT COUNT(*) FROM plan_item WHERE id = '$id' AND deleted_at IS NOT NULL",
        ),
        1,
      );
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_id = '$id' AND op = 'delete'",
        ),
        1,
      );
    });

    test('moveToDate 换天', () async {
      final id = await repos.planItem.create(date: _today, title: '顺延项');
      final target = shiftIsoDate(_today, 1);
      await repos.planItem.moveToDate(id, target);

      expect(await repos.planItem.listByDate(_today), isEmpty);
      final moved = (await repos.planItem.listByDate(target)).single;
      expect(moved.id, id);
      expect(moved.date, target);
    });
  });

  // ===========================================================================
  // P1-5 四象限 / ABC 双模式互斥且切换无损
  // ===========================================================================
  group('PlanItemRepository · P1-5 双模式互斥', () {
    test('setQuadrant 不触碰 priorityAbc，反之亦然', () async {
      final id = await repos.planItem.create(
        date: _today,
        title: '两套分级都留着',
        quadrant: Quadrant.q2,
        priorityAbc: PriorityAbc.b,
      );

      await repos.planItem.setQuadrant(id, Quadrant.q1);
      var item = (await repos.planItem.listByDate(_today)).single;
      expect(item.quadrant, Quadrant.q1.code);
      expect(item.priorityAbc, PriorityAbc.b.code, reason: '切象限不得清掉 ABC');

      await repos.planItem.setPriorityAbc(id, PriorityAbc.a);
      item = (await repos.planItem.listByDate(_today)).single;
      expect(item.priorityAbc, PriorityAbc.a.code);
      expect(item.quadrant, Quadrant.q1.code, reason: '切 ABC 不得清掉象限');
    });

    test('可以把分级清空（再次点击已选项 = 取消）', () async {
      final id = await repos.planItem.create(
        date: _today,
        title: '可取消',
        quadrant: Quadrant.q3,
        priorityAbc: PriorityAbc.c,
      );

      await repos.planItem.setQuadrant(id, null);
      await repos.planItem.setPriorityAbc(id, null);
      final item = (await repos.planItem.listByDate(_today)).single;
      expect(item.quadrant, isNull);
      expect(item.priorityAbc, isNull);
    });

    test('两种模式排序各自只看自己那一列', () async {
      const date = '2026-09-01';
      final t1 = await repos.planItem.create(
        date: date,
        id: 'it-01',
        title: 't1',
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.a,
      );
      final t2 = await repos.planItem.create(
        date: date,
        id: 'it-02',
        title: 't2',
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.c,
      );
      final t3 = await repos.planItem.create(
        date: date,
        id: 'it-03',
        title: 't3',
        quadrant: Quadrant.q2,
        priorityAbc: PriorityAbc.a,
      );
      final t4 = await repos.planItem.create(
        date: date,
        id: 'it-04',
        title: 't4',
        quadrant: Quadrant.q3,
        priorityAbc: PriorityAbc.b,
      );
      final t5 = await repos.planItem.create(
        date: date,
        id: 'it-05',
        title: 't5',
        quadrant: Quadrant.q4,
      );
      final t6 = await repos.planItem.create(date: date, id: 'it-06', title: 't6');
      final t7 = await repos.planItem.create(
        date: date,
        id: 'it-07',
        title: 't7',
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.a,
      );
      await repos.planItem.setStatus(t7, PlanStatus.done);

      final items = await repos.planItem.listByDate(date);
      List<String> titles(PriorityDisplayMode mode) =>
          sortPlanItemsForDisplay(items, mode)
              .map((e) => e.title)
              .toList(growable: false);

      expect(
        titles(PriorityDisplayMode.quadrant),
        <String>['t1', 't2', 't3', 't4', 't5', 't6', 't7'],
        reason: 'q1<q2<q3<q4<未分级，done 沉底',
      );
      expect(
        titles(PriorityDisplayMode.abc),
        <String>['t1', 't3', 't4', 't2', 't5', 't6', 't7'],
        reason: 'ABC 模式只看 ABC 列：A(t1,t3) < B(t4) < C(t2) < 未分级(t5,t6)，done 沉底',
      );
      expect(<String>[t1, t2, t3, t4, t5, t6, t7], hasLength(7));
    });
  });

  // ===========================================================================
  // P1-6 成果回填行 / 习惯回填行
  // ===========================================================================
  group('PlanItemRepository · P1-6 习惯回填行', () {
    test('createHabitRef 标记来源为习惯', () async {
      final habitId = await repos.habit.create(name: '喝水');
      final refId = await repos.planItem.createHabitRef(
        date: _today,
        habitId: habitId,
        title: '喝水',
      );

      final item = (await repos.planItem.listByDate(_today)).single;
      expect(item.id, refId);
      expect(item.sourceType, 'habit');
      expect(item.isHabitRef, 1);
      expect(item.sourceId, habitId);
    });

    test('promote 把回填行转成普通条目', () async {
      final habitId = await repos.habit.create(name: '晨读');
      final refId = await repos.planItem.createHabitRef(
        date: _today,
        habitId: habitId,
        title: '晨读',
      );

      await repos.planItem.promote(refId);
      final item = (await repos.planItem.listByDate(_today)).single;
      expect(item.sourceType, 'manual');
      expect(item.isHabitRef, 0);
      expect(item.sourceId, isNull);
      expect(item.title, '晨读', reason: '转正只改来源字段，标题保持不变');
    });

    test('删除回填行不影响习惯打卡记录', () async {
      final habitId = await repos.habit.create(name: '跑步');
      final checkinId = await repos.habit.upsertCheckin(
        habitId: habitId,
        date: _today,
      );
      final refId = await repos.planItem.createHabitRef(
        date: _today,
        habitId: habitId,
        title: '跑步',
      );

      await repos.planItem.softDelete(refId);

      final checkin = await repos.habit.findCheckin(habitId, _today);
      expect(checkin, isNotNull, reason: '删回填行不得级联删打卡');
      expect(checkin!.id, checkinId);
      expect(
        await scalar("SELECT COUNT(*) FROM habit_checkin WHERE deleted_at IS NULL"),
        1,
      );
    });
  });

  // ===========================================================================
  // 习惯：排程 + 撤销后重打卡（墓碑复活）
  // ===========================================================================
  group('HabitRepository · 排程与打卡', () {
    Future<List<String>> scheduledIds(String date) async {
      final habits = await repos.habit.listScheduledFor(date);
      return habits.map((h) => h.id).toList(growable: false);
    }

    test('daily / weekly_n 每天都出现，weekdays 只在指定星期出现', () async {
      final wed = DateTime(2026, 11, 4);
      expect(wed.weekday, DateTime.wednesday, reason: '前提：2026-11-04 是周三');

      final daily = await repos.habit.create(
        name: '每日一件事',
        startDate: '2026-01-01',
      );
      final weekly = await repos.habit.create(
        name: '每周三次',
        scheduleType: 'weekly_n',
        weeklyN: 3,
        startDate: '2026-01-01',
      );
      final wednesday = await repos.habit.create(
        name: '周三复盘',
        scheduleType: 'weekdays',
        weekdays: '3',
        startDate: '2026-01-01',
      );

      expect(await scheduledIds('2026-11-04'), containsAll(<String>[daily, weekly, wednesday]));
      final thursday = await scheduledIds('2026-11-05');
      expect(thursday, containsAll(<String>[daily, weekly]));
      expect(thursday, isNot(contains(wednesday)));
    });

    test('startDate 晚于查询日时不出现在排程里', () async {
      final habitId = await repos.habit.create(
        name: '从下周开始',
        startDate: '2026-11-10',
      );
      expect(await scheduledIds('2026-11-04'), isNot(contains(habitId)));
      expect(await scheduledIds('2026-11-10'), contains(habitId));
    });

    test('名称空白抛 ArgumentError', () async {
      await expectLater(() => repos.habit.create(name: '  '), throwsArgumentError);
    });

    test('撤销打卡后同一天再打卡：复用同一行、同一 id、不撞唯一约束', () async {
      final habitId = await repos.habit.create(name: '背单词');
      final first = await repos.habit.upsertCheckin(
        habitId: habitId,
        date: _today,
      );

      await repos.habit.deleteCheckin(first);
      expect(await repos.habit.findCheckin(habitId, _today), isNull);

      final second = await repos.habit.upsertCheckin(
        habitId: habitId,
        date: _today,
        status: CheckinStatus.done,
        note: '第二次',
      );

      expect(second, first, reason: '必须复活墓碑那一行，id 保持稳定');
      final checkin = await repos.habit.findCheckin(habitId, _today);
      expect(checkin, isNotNull);
      expect(checkin!.id, first);
      expect(checkin.note, '第二次');
      expect(
        await scalar(
          "SELECT COUNT(*) FROM habit_checkin WHERE habit_id = '$habitId'",
        ),
        1,
        reason: '唯一约束不带部分索引，同一天永远只能有一行',
      );
    });

    test('同一天重复打卡是更新而不是新增', () async {
      final habitId = await repos.habit.create(name: '冥想');
      final a = await repos.habit.upsertCheckin(habitId: habitId, date: _today);
      final b = await repos.habit.upsertCheckin(
        habitId: habitId,
        date: _today,
        value: 2,
      );
      expect(b, a);
      expect(
        (await repos.habit.findCheckin(habitId, _today))!.value,
        2.0,
      );
      expect(
        await scalar("SELECT COUNT(*) FROM habit_checkin"),
        1,
      );
    });

    test('已归档的习惯不再出现在排程里', () async {
      final habitId = await repos.habit.create(name: '临时习惯');
      expect(await scheduledIds(_today), contains(habitId));
      await repos.habit.archive(habitId);
      expect(await scheduledIds(_today), isNot(contains(habitId)));
    });
  });

  // ===========================================================================
  // 设置
  // ===========================================================================
  group('SettingsRepository', () {
    test('priorityDisplayMode 默认四象限，可切到 ABC', () async {
      expect(await repos.settings.priorityDisplayMode(), PriorityDisplayMode.quadrant);
      await repos.settings.setPriorityDisplayMode(PriorityDisplayMode.abc);
      expect(await repos.settings.priorityDisplayMode(), PriorityDisplayMode.abc);
      expect(
        await scalar("SELECT COUNT(*) FROM settings WHERE key = 'priority_display_mode'"),
        1,
        reason: 'settings_key_unique 只允许一行',
      );
    });

    test('set 同一个 key 两次不新增行，只更新值', () async {
      await repos.settings.set('default_day_mode', dayModeFull);
      await repos.settings.set('default_day_mode', dayModeMinimal);
      expect(await repos.settings.get('default_day_mode'), dayModeMinimal);
      expect(
        await scalar("SELECT COUNT(*) FROM settings WHERE key = 'default_day_mode'"),
        1,
      );
    });

    test('get 对不存在的 key 返回 null', () async {
      expect(await repos.settings.get('nope'), isNull);
    });
  });

  // ===========================================================================
  // 死活检查：oplog 真的在写
  // ===========================================================================
  group('oplog 接线', () {
    test('创建计划条目会写一条 upsert oplog', () async {
      final id = await repos.planItem.create(date: _today, title: '有账可查');
      expect(
        await scalar(
          "SELECT COUNT(*) FROM oplog WHERE entity_id = '$id' AND op = 'upsert'",
        ),
        1,
      );
      expect(
        await scalar("SELECT COUNT(*) FROM oplog WHERE device_id = '$_device'"),
        greaterThanOrEqualTo(1),
      );
    });
  });
}