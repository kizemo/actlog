// ignore_for_file: public_member_api_docs

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const String _today = '2026-11-07';
const String _yesterday = '2026-11-06';

StandupPlanRow row({
  String id = 'p1',
  String title = '条目',
  String date = _yesterday,
  PlanStatus status = PlanStatus.pending,
  Quadrant? quadrant,
  PriorityAbc? priorityAbc,
  String resultNote = '',
  int carriedOverDays = 0,
}) {
  return StandupPlanRow(
    id: id,
    title: title,
    date: date,
    status: status,
    quadrant: quadrant,
    priorityAbc: priorityAbc,
    resultNote: resultNote,
    carriedOverDays: carriedOverDays,
  );
}

StandupBrief build({
  List<StandupPlanRow> todayItems = const [],
  List<StandupPlanRow> yesterdayItems = const [],
  String yesterdayGoodText = '',
  List<String> projectBlockers = const [],
  StandupConfig config = const StandupConfig(),
}) {
  return StandupBuilder.build(
    input: StandupInput(
      date: _today,
      todayItems: todayItems,
      yesterdayItems: yesterdayItems,
      yesterdayGoodText: yesterdayGoodText,
      projectBlockers: projectBlockers,
    ),
    config: config,
  );
}

void main() {
  group('StandupPlanRow', () {
    test('pending 与 deferred 算未收口，其余不算', () {
      expect(row(status: PlanStatus.pending).isOpen, isTrue);
      expect(row(status: PlanStatus.deferred).isOpen, isTrue);
      expect(row(status: PlanStatus.done).isOpen, isFalse);
      expect(row(status: PlanStatus.cancelled).isOpen, isFalse);
    });
  });

  group('昨日亮点', () {
    test('只取昨天已完成的条目', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '完成的', status: PlanStatus.done),
          row(id: 'b', title: '未完成的', status: PlanStatus.pending),
          row(id: 'c', title: '取消的', status: PlanStatus.cancelled),
        ],
      );
      expect(brief.yesterdayHighlights.map((e) => e.title), <String>['完成的']);
      expect(
        brief.yesterdayHighlights.single.source,
        StandupSource.yesterdayDone,
      );
    });

    test('有成果备注的排在没备注的前面', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '没备注', status: PlanStatus.done),
          row(
            id: 'b',
            title: '有备注',
            status: PlanStatus.done,
            resultNote: '签下 3 单',
          ),
        ],
      );
      expect(brief.yesterdayHighlights.map((e) => e.title), <String>[
        '有备注',
        '没备注',
      ]);
      expect(brief.yesterdayHighlights.first.note, '签下 3 单');
    });

    test('一条都没完成时用昨天「做得好」文本兜底', () {
      final brief = build(
        yesterdayGoodText: '和客户谈成了续约\n细节略',
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '没做完', status: PlanStatus.pending),
        ],
      );
      final entry = brief.yesterdayHighlights.single;
      expect(entry.source, StandupSource.yesterdayGoodText);
      expect(entry.title, '和客户谈成了续约');
      expect(entry.note, '和客户谈成了续约\n细节略');
    });

    test('兜底文本超长时截断到 40 字符并加省略号', () {
      final long = 'A' * 50;
      final brief = build(yesterdayGoodText: long);
      final title = brief.yesterdayHighlights.single.title;
      expect(title.length, 41);
      expect(title, '${'A' * 40}…');
    });

    test('兜底文本为空白时不算亮点', () {
      final brief = build(yesterdayGoodText: '   \n  ');
      expect(brief.yesterdayHighlights, isEmpty);
    });

    test('highlightLimit 限制条数', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          for (var i = 0; i < 5; i++)
            row(id: 'p$i', title: '完成$i', status: PlanStatus.done),
        ],
        config: const StandupConfig(highlightLimit: 2),
      );
      expect(brief.yesterdayHighlights.length, 2);
    });

    test('已完成的条目不会同时出现在今日优先里', () {
      final brief = build(
        todayItems: <StandupPlanRow>[
          row(date: _today, status: PlanStatus.done),
        ],
      );
      expect(brief.todayPriorities, isEmpty);
    });
  });

  group('今日优先', () {
    test('只取今天未收口的条目', () {
      final brief = build(
        todayItems: <StandupPlanRow>[
          row(id: 'a', title: '待办', date: _today),
          row(id: 'b', title: '顺延', date: _today, status: PlanStatus.deferred),
          row(id: 'c', title: '做完', date: _today, status: PlanStatus.done),
          row(
            id: 'd',
            title: '取消',
            date: _today,
            status: PlanStatus.cancelled,
          ),
        ],
      );
      expect(brief.todayPriorities.map((e) => e.title), <String>['待办', '顺延']);
      expect(
        brief.todayPriorities.map((e) => e.source).toSet(),
        <StandupSource>{StandupSource.todayPlanned},
      );
    });

    test('按 象限 → ABC → id 排序', () {
      final brief = build(
        todayItems: <StandupPlanRow>[
          row(id: 'n1', date: _today),
          row(id: 'q4', date: _today, quadrant: Quadrant.q4),
          row(id: 'q3c', date: _today, quadrant: Quadrant.q3, priorityAbc: PriorityAbc.c),
          row(id: 'q1c', date: _today, quadrant: Quadrant.q1, priorityAbc: PriorityAbc.c),
          row(id: 'q1a', date: _today, quadrant: Quadrant.q1, priorityAbc: PriorityAbc.a),
          row(id: 'q2', date: _today, quadrant: Quadrant.q2),
        ],
        config: const StandupConfig(priorityLimit: 10),
      );
      expect(brief.todayPriorities.map((e) => e.id), <String>[
        'q1a',
        'q1c',
        'q2',
        'q3c',
        'q4',
        'n1',
      ]);
    });

    test('象限相同时先按 ABC 再按 id', () {
      final brief = build(
        todayItems: <StandupPlanRow>[
          row(id: 'z', date: _today, quadrant: Quadrant.q2, priorityAbc: PriorityAbc.a),
          row(id: 'y', date: _today, quadrant: Quadrant.q2, priorityAbc: PriorityAbc.c),
          row(id: 'x', date: _today, quadrant: Quadrant.q2),
        ],
      );
      expect(brief.todayPriorities.map((e) => e.id), <String>['z', 'y', 'x']);
    });

    test('顺延天数原样带到条目上', () {
      final brief = build(
        todayItems: <StandupPlanRow>[
          row(id: 'a', date: _today, carriedOverDays: 3),
        ],
      );
      expect(brief.todayPriorities.single.carriedOverDays, 3);
    });

    test('priorityLimit 限制条数', () {
      final brief = build(
        todayItems: <StandupPlanRow>[
          for (var i = 0; i < 6; i++) row(id: 'p$i', date: _today),
        ],
        config: const StandupConfig(priorityLimit: 2),
      );
      expect(brief.todayPriorities.length, 2);
    });

    test('空的今日条目不会抛异常', () {
      expect(build().todayPriorities, isEmpty);
    });
  });

  group('阻塞项', () {
    test('项目阻塞默认计入，并去掉空行与首尾空白', () {
      final brief = build(
        projectBlockers: <String>['  等法务确认合同  ', '   ', '\n'],
      );
      final entry = brief.blockers.single;
      expect(entry.source, StandupSource.projectBlocker);
      expect(entry.title, '等法务确认合同');
      expect(entry.note, '等法务确认合同');
    });

    test('昨天未收口且紧急（Q1 / Q3）计入', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '紧急未做', quadrant: Quadrant.q1),
          row(id: 'b', title: '委托未做', quadrant: Quadrant.q3),
        ],
      );
      expect(brief.blockers.map((e) => e.title), <String>['紧急未做', '委托未做']);
      expect(
        brief.blockers.map((e) => e.source).toSet(),
        <StandupSource>{StandupSource.carriedOver},
      );
      expect(brief.blockers.first.note, '昨天未收口');
    });

    test('Q2 / Q4 未收口且未达顺延天数时不计入', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', quadrant: Quadrant.q2),
          row(id: 'b', quadrant: Quadrant.q4),
          row(id: 'c'),
        ],
      );
      expect(brief.blockers, isEmpty);
    });

    test('顺延达到 blockerCarryOverDays（默认 2 天）即计入', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '顺延两天', carriedOverDays: 2),
          row(id: 'b', title: '顺延一天', carriedOverDays: 1),
        ],
      );
      expect(brief.blockers.map((e) => e.title), <String>['顺延两天']);
      expect(brief.blockers.single.note, '已顺延 2 天');
    });

    test('blockerCarryOverDays = 0 时完全不按顺延判定', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '顺延九天', carriedOverDays: 9),
        ],
        config: const StandupConfig(blockerCarryOverDays: 0),
      );
      expect(brief.blockers, isEmpty);
    });

    test('blockerIncludesUnfinishedUrgent = false 时紧急条目不再自动计入', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '紧急未做', quadrant: Quadrant.q1),
        ],
        config: const StandupConfig(blockerIncludesUnfinishedUrgent: false),
      );
      expect(brief.blockers, isEmpty);
    });

    test('紧急条目在关闭紧急规则后仍可按顺延天数计入', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '紧急且顺延', quadrant: Quadrant.q1, carriedOverDays: 3),
        ],
        config: const StandupConfig(blockerIncludesUnfinishedUrgent: false),
      );
      expect(brief.blockers.single.title, '紧急且顺延');
    });

    test('blockerIncludesProjectBlockers = false 时项目阻塞被排除', () {
      final brief = build(
        projectBlockers: <String>['等外部依赖'],
        config: const StandupConfig(blockerIncludesProjectBlockers: false),
      );
      expect(brief.blockers, isEmpty);
    });

    test('顺延条目按顺延天数降序排列', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '两天', carriedOverDays: 2),
          row(id: 'b', title: '五天', carriedOverDays: 5),
          row(id: 'c', title: '三天', carriedOverDays: 3),
        ],
      );
      expect(brief.blockers.map((e) => e.title), <String>['五天', '三天', '两天']);
    });

    test('顺延天数相同时按象限排序', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: 'Q4', quadrant: Quadrant.q4, carriedOverDays: 2),
          row(id: 'b', title: 'Q1', quadrant: Quadrant.q1, carriedOverDays: 2),
        ],
      );
      expect(brief.blockers.map((e) => e.title), <String>['Q1', 'Q4']);
    });

    test('已完成的昨天条目不会进阻塞项', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', status: PlanStatus.done, quadrant: Quadrant.q1),
        ],
      );
      expect(brief.blockers, isEmpty);
    });

    test('blockerLimit 限制条数，且项目阻塞先占名额', () {
      final brief = build(
        projectBlockers: <String>['项目阻塞甲', '项目阻塞乙'],
        yesterdayItems: <StandupPlanRow>[
          row(id: 'a', title: '紧急未做', quadrant: Quadrant.q1),
        ],
        config: const StandupConfig(blockerLimit: 2),
      );
      expect(brief.blockers.map((e) => e.title), <String>['项目阻塞甲', '项目阻塞乙']);
    });

    test('项目阻塞 id 稳定可判定', () {
      final brief = build(projectBlockers: <String>['甲', '乙']);
      expect(brief.blockers.map((e) => e.id), <String>[
        'project-blocker-0',
        'project-blocker-1',
      ]);
    });

    test('项目阻塞描述超长时只保留首行 40 字符，note 保留全文', () {
      final long = '${'B' * 50}\n第二行';
      final brief = build(projectBlockers: <String>[long]);
      final entry = brief.blockers.single;
      expect(entry.title, '${'B' * 40}…');
      expect(entry.note, long);
    });
  });

  group('StandupBrief', () {
    test('三段全空时 isEmpty 为真', () {
      final brief = build();
      expect(brief.isEmpty, isTrue);
      expect(brief.date, _today);
    });

    test('任意一段非空时 isEmpty 为假', () {
      expect(build(projectBlockers: <String>['阻塞']).isEmpty, isFalse);
      expect(
        build(yesterdayItems: <StandupPlanRow>[
          row(status: PlanStatus.done),
        ]).isEmpty,
        isFalse,
      );
      expect(
        build(todayItems: <StandupPlanRow>[row(date: _today)]).isEmpty,
        isFalse,
      );
    });

    test('三段互不干扰：同一份输入可同时产出三段', () {
      final brief = build(
        yesterdayItems: <StandupPlanRow>[
          row(id: 'done', title: '昨天做完', status: PlanStatus.done),
          row(id: 'late', title: '昨天没做完', quadrant: Quadrant.q1),
        ],
        todayItems: <StandupPlanRow>[
          row(id: 'now', title: '今天要做', date: _today),
        ],
        projectBlockers: <String>['等外部依赖'],
      );
      expect(brief.yesterdayHighlights.single.title, '昨天做完');
      expect(brief.todayPriorities.single.title, '今天要做');
      expect(brief.blockers.map((e) => e.title), <String>['等外部依赖', '昨天没做完']);
    });
  });
}