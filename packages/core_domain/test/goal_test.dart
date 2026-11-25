// ignore_for_file: public_member_api_docs
// =============================================================================
// core_domain · 目标体系领域模型门禁（Task 65 / schema v3）
// =============================================================================
// 钉住五件「写错了不会报错、只会静默算错」的事：
//   1. 五个枚举的**存储 code** 逐字不变（它们是 DB CHECK 约束的取值域，
//      改一个字就等于让真库拒写）；
//   2. `fromCode` 一律**不抛异常**、未知值返回 null（同步对端可能是更高版本）；
//   3. `GoalPeriod` 的三个标签（`2026` / `2026-11` / `2026-W48`）与**窗口边界**，
//      周按 ISO-8601（周一是一周之首）；
//   4. `Goal.create` / `GoalLink.create` 的三条负例（空标题、自评越界、
//      归档口子里塞非完成目标、目标关联自己）；
//   5. 周期口径一律 **UTC**（跨时区设备上「这一周」必须是同一批行）。
// =============================================================================

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('目标枚举 ↔ 存储 code', () {
    test('GoalKind 五个取值逐字对应 DB code', () {
      expect(
        GoalKind.values.map((GoalKind k) => k.code).toList(),
        const <String>['blueprint', 'brand', 'yearly', 'monthly', 'weekly'],
      );
    });

    test('GoalStatus 四个取值逐字对应 DB code（没有 paused）', () {
      expect(
        GoalStatus.values.map((GoalStatus s) => s.code).toList(),
        const <String>['draft', 'active', 'done', 'cancelled'],
      );
    });

    test('GoalRelation 四个取值逐字对应 DB code', () {
      expect(
        GoalRelation.values.map((GoalRelation r) => r.code).toList(),
        const <String>['serves', 'derives', 'tracks', 'references'],
      );
    });

    test('GoalTargetType 六个取值逐字对应 DB code', () {
      expect(
        GoalTargetType.values.map((GoalTargetType t) => t.code).toList(),
        const <String>[
          'todo',
          'plan_item',
          'project',
          'increment',
          'habit',
          'goal',
        ],
      );
    });

    test('GoalHorizon 1..5 与 GoalFacet 十个切面', () {
      expect(
        GoalHorizon.values.map((GoalHorizon h) => h.value).toList(),
        const <int>[1, 2, 3, 4, 5],
      );
      expect(
        GoalFacet.values.map((GoalFacet f) => f.code).toList(),
        const <String>[
          'statement',
          'word',
          'audience',
          'promise',
          'cost',
          'evidence',
          'contrast',
          'strength',
          'errc',
          'identity',
        ],
      );
    });

    test('fromCode / fromValue 往返一致', () {
      for (final GoalKind k in GoalKind.values) {
        expect(GoalKind.fromCode(k.code), k);
      }
      for (final GoalStatus s in GoalStatus.values) {
        expect(GoalStatus.fromCode(s.code), s);
      }
      for (final GoalRelation r in GoalRelation.values) {
        expect(GoalRelation.fromCode(r.code), r);
      }
      for (final GoalTargetType t in GoalTargetType.values) {
        expect(GoalTargetType.fromCode(t.code), t);
      }
      for (final GoalHorizon h in GoalHorizon.values) {
        expect(GoalHorizon.fromValue(h.value), h);
      }
      for (final GoalFacet f in GoalFacet.values) {
        expect(GoalFacet.fromCode(f.code), f);
      }
    });

    test('未知取值返回 null 而不是抛异常', () {
      expect(GoalKind.fromCode('nope'), isNull);
      expect(GoalKind.fromCode(null), isNull);
      expect(GoalStatus.fromCode('paused'), isNull);
      expect(GoalRelation.fromCode('owns'), isNull);
      expect(GoalTargetType.fromCode('note'), isNull);
      expect(GoalHorizon.fromValue(9), isNull);
      expect(GoalHorizon.fromValue(null), isNull);
      expect(GoalFacet.fromCode('vibe'), isNull);
    });

    test('周期型与非周期型：只有 yearly / monthly / weekly 有周期', () {
      expect(GoalKind.yearly.periodUnit, GoalPeriodUnit.year);
      expect(GoalKind.monthly.periodUnit, GoalPeriodUnit.month);
      expect(GoalKind.weekly.periodUnit, GoalPeriodUnit.week);
      expect(GoalKind.blueprint.periodUnit, isNull);
      expect(GoalKind.brand.periodUnit, isNull);

      expect(GoalKind.yearly.isPeriodic, isTrue);
      expect(GoalKind.monthly.isPeriodic, isTrue);
      expect(GoalKind.weekly.isPeriodic, isTrue);
      expect(GoalKind.blueprint.isPeriodic, isFalse);
      expect(GoalKind.brand.isPeriodic, isFalse);
    });

    test('GoalStatus.done 才是「已完成」', () {
      expect(GoalStatus.done.isDone, isTrue);
      expect(GoalStatus.active.isDone, isFalse);
      expect(GoalStatus.draft.isDone, isFalse);
      expect(GoalStatus.cancelled.isDone, isFalse);
    });
  });

  group('GoalPeriod · 标签与窗口', () {
    test('年 / 月 / 周三个标签', () {
      expect(GoalPeriod.year(2026).label, '2026');
      expect(GoalPeriod.month(2026, 11).label, '2026-11');
      expect(GoalPeriod.week(2026, 48).label, '2026-W48');
      expect(GoalPeriod.week(2026, 5).label, '2026-W05');
      expect(GoalPeriod.month(2026, 3).label, '2026-03');
    });

    test('年周期窗口 = 2026 全年（UTC，首刻含、末刻含）', () {
      final GoalPeriod p = GoalPeriod.year(2026);
      expect(p.startUtc, DateTime.utc(2026));
      expect(p.endUtc, DateTime.utc(2026, 12, 31, 23, 59, 59, 999));
      expect(p.endMillis - p.startMillis, 365 * 24 * 3600 * 1000 - 1);
    });

    test('月周期窗口 = 2026-11（UTC）', () {
      final GoalPeriod p = GoalPeriod.month(2026, 11);
      expect(p.startUtc, DateTime.utc(2026, 11));
      expect(p.endUtc, DateTime.utc(2026, 11, 30, 23, 59, 59, 999));
    });

    test('周周期窗口 = 2026-W48 = 11-23(周一) … 11-29(周日)（UTC）', () {
      final GoalPeriod p = GoalPeriod.week(2026, 48);
      expect(p.startUtc, DateTime.utc(2026, 11, 23));
      expect(p.startUtc.weekday, DateTime.monday);
      expect(p.endUtc, DateTime.utc(2026, 11, 29, 23, 59, 59, 999));
      expect(p.endUtc.weekday, DateTime.sunday);
    });

    test('contains 判在窗口内（含两端）', () {
      final GoalPeriod p = GoalPeriod.week(2026, 48);
      expect(p.contains(p.startMillis), isTrue);
      expect(p.contains(p.endMillis), isTrue);
      expect(p.contains(p.startMillis - 1), isFalse);
      expect(p.contains(p.endMillis + 1), isFalse);
      expect(p.contains(DateTime.utc(2026, 11, 25).millisecondsSinceEpoch), isTrue);
    });

    test('2026 年有 53 个 ISO 周（第 53 周合法、第 54 周非法）', () {
      expect(GoalPeriod.isoWeeksInYear(2026), 53);
      expect(GoalPeriod.isoWeeksInYear(2025), 52);
      expect(GoalPeriod.week(2026, 53).label, '2026-W53');
      expect(() => GoalPeriod.week(2026, 54), throwsArgumentError);
      expect(() => GoalPeriod.week(2026, 0), throwsArgumentError);
    });

    test('ISO 周年 ≠ 公历年（元旦那周属于上一年的第 52/53 周）', () {
      // 2027-01-01 是周五；它落在 ISO 2026 的最后一周里。
      final DateTime newYear = DateTime.utc(2027, 1, 1);
      expect(GoalPeriod.isoYearOf(newYear), 2026);
      expect(GoalPeriod.isoWeekOf(newYear), 53);
      expect(GoalPeriod.fromStartMillis(
        newYear.millisecondsSinceEpoch,
        GoalPeriodUnit.week,
      ).label, '2026-W53');
    });

    test('next / previous 跨边界正确', () {
      expect(GoalPeriod.year(2026).next().label, '2027');
      expect(GoalPeriod.year(2026).previous().label, '2025');
      expect(GoalPeriod.month(2026, 12).next().label, '2027-01');
      expect(GoalPeriod.month(2026, 1).previous().label, '2025-12');
      expect(GoalPeriod.week(2026, 53).next().label, '2027-W01');
      expect(GoalPeriod.week(2026, 1).previous().label, '2025-W52');
    });

    test('tryParse 往返 + 无法识别返回 null；parse 抛 FormatException', () {
      expect(GoalPeriod.tryParse('2026'), GoalPeriod.year(2026));
      expect(GoalPeriod.tryParse('2026-11'), GoalPeriod.month(2026, 11));
      expect(GoalPeriod.tryParse('2026-W48'), GoalPeriod.week(2026, 48));
      expect(GoalPeriod.tryParse('  2026-11  '), GoalPeriod.month(2026, 11));

      expect(GoalPeriod.tryParse('2026-13'), isNull);
      expect(GoalPeriod.tryParse('2026-W54'), isNull);
      expect(GoalPeriod.tryParse('nope'), isNull);
      expect(GoalPeriod.tryParse(''), isNull);

      expect(() => GoalPeriod.parse('nope'), throwsFormatException);
      expect(GoalPeriod.parse('2026-W48'), GoalPeriod.week(2026, 48));
    });

    test('fromStartMillis 反推所属周期（UTC 口径）', () {
      final int ms = DateTime.utc(2026, 11, 25, 9, 30).millisecondsSinceEpoch;
      expect(
        GoalPeriod.fromStartMillis(ms, GoalPeriodUnit.year).label,
        '2026',
      );
      expect(
        GoalPeriod.fromStartMillis(ms, GoalPeriodUnit.month).label,
        '2026-11',
      );
      expect(
        GoalPeriod.fromStartMillis(ms, GoalPeriodUnit.week).label,
        '2026-W48',
      );
    });

    test('非法年 / 月抛 ArgumentError', () {
      expect(() => GoalPeriod.year(0), throwsArgumentError);
      expect(() => GoalPeriod.year(10000), throwsArgumentError);
      expect(() => GoalPeriod.month(2026, 0), throwsArgumentError);
      expect(() => GoalPeriod.month(2026, 13), throwsArgumentError);
    });

    test('相等性按 unit + year + month + week 判', () {
      expect(GoalPeriod.week(2026, 48), GoalPeriod.week(2026, 48));
      expect(GoalPeriod.week(2026, 48), isNot(GoalPeriod.week(2026, 49)));
      expect(
        GoalPeriod.week(2026, 48).hashCode,
        GoalPeriod.week(2026, 48).hashCode,
      );
      expect(GoalPeriod.month(2026, 11).toString(), '2026-11');
    });
  });

  group('Goal.create · 校验', () {
    Goal makeGoal({
      String title = '把 2026 跑完',
      int? selfScore,
      int periodStart = 1000,
      int? periodEnd,
      GoalStatus status = GoalStatus.active,
      int? archivedAt,
    }) {
      return Goal.create(
        id: 'goal-1',
        kind: GoalKind.yearly,
        title: title,
        createdAt: 1000,
        updatedAt: 1000,
        originDeviceId: 'dev-test',
        selfScore: selfScore,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: status,
        archivedAt: archivedAt,
      );
    }

    test('正常构造：标题去空白', () {
      final Goal g = makeGoal(title: '  把 2026 跑完  ');
      expect(g.title, '把 2026 跑完');
      expect(g.kind, GoalKind.yearly);
      expect(g.status, GoalStatus.active);
      expect(g.rev, 1);
      expect(g.isDone, isFalse);
      expect(g.isDeleted, isFalse);
    });

    test('标题为空抛 DomainValidationException', () {
      expect(
        () => makeGoal(title: '   '),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('自评越界（11 / -1）抛 DomainValidationException', () {
      expect(
        () => makeGoal(selfScore: 11),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => makeGoal(selfScore: -1),
        throwsA(isA<DomainValidationException>()),
      );
      expect(makeGoal(selfScore: 0).selfScore, 0);
      expect(makeGoal(selfScore: 10).selfScore, 10);
    });

    test('periodEnd 早于 periodStart 抛 DomainValidationException', () {
      expect(
        () => makeGoal(periodStart: 2000, periodEnd: 1999),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        makeGoal(periodStart: 2000, periodEnd: 2000).periodEnd,
        2000,
      );
    });

    test('只有 done 的目标能带归档时刻', () {
      expect(
        () => makeGoal(status: GoalStatus.active, archivedAt: 5000),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        makeGoal(status: GoalStatus.done, archivedAt: 5000).archivedAt,
        5000,
      );
    });
  });

  group('GoalLink.create · 校验', () {
    GoalLink makeLink({
      GoalTargetType targetType = GoalTargetType.planItem,
      String targetId = 'plan-1',
      String goalId = 'goal-1',
    }) {
      return GoalLink.create(
        id: 'link-1',
        goalId: goalId,
        targetType: targetType,
        targetId: targetId,
        createdAt: 1000,
        updatedAt: 1000,
        originDeviceId: 'dev-test',
      );
    }

    test('正常构造：默认 relation = serves', () {
      final GoalLink l = makeLink();
      expect(l.relation, GoalRelation.serves);
      expect(l.targetType, GoalTargetType.planItem);
      expect(l.rev, 1);
      expect(l.isDeleted, isFalse);
    });

    test('目标不能关联自己（禁自环）', () {
      expect(
        () => makeLink(targetType: GoalTargetType.goal, targetId: 'goal-1'),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        makeLink(targetType: GoalTargetType.goal, targetId: 'goal-2').targetId,
        'goal-2',
      );
    });

    test('toString 带上 kind / relation 便于日志排查', () {
      expect(makeLink().toString(), contains('plan_item'));
      expect(makeLink().toString(), contains('serves'));
    });
  });
}
