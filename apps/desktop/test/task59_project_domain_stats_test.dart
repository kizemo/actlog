// apps/desktop/test/task59_project_domain_stats_test.dart
//
// Task 59 · 项目页「领域分布」面板 + 新建项目的「所属领域」。
//
// 数据层（纯 `test()`）钉六条：
//   D1：空列表 ⇒ 空统计（不是「一个未分类桶」）；
//   D2：分桶计数与 ratio 正确（2×career + 1×learning ⇒ 2/3、1/3）；
//   D3：排序 = 数量降序 → 同数按 key 字典序升序；
//   D4：未分类（空串）**恒排最后**，哪怕它是最大桶；
//   D5：未知 key 单独成桶（照实统计，不猜译名、不丢弃）；
//   D6：写链贯通 —— `createProject(domain:)` 落库，`listProjects()` 原样回读；
//   D7：oplog payload 的字段级 diff 里记着 `domain`（同步侧看不到就等于丢改动）。
//
// 界面层（`testWidgets`）钉七条：
//   W1：有项目 ⇒ 面板出现，本地化标签与「N 个项目」都在；
//   W2（负控）：一个项目都没有 ⇒ 面板**不出现**；
//   W3：表单选完领域再提交 ⇒ 新项目在库里 `domain == 所选 key`；
//   W4：比例条长度严格正比于 ratio（2:1 的桶 ⇒ 2:1 的条）；
//   W5：未知 key ⇒ 面板**原样显示 key**，不吞成「未分类」（59.4d 的界面侧兜底）；
//   W5b：空串 domain ⇒ 面板显示「未分类」，且不借用表单的「未设置」占位；
//   W7：领域芯片 = `projectDomainKeys` × 当前语言本地化标签，集合逐项相等
//       （两处真源 —— 数据层的 key 清单 vs 页面的 `_domainLabel` —— 锁死）。
//
// 口径是**真库 + 真界面**：内存 drift 库 + 真仓储，页面自己走 `_reload()`。
import 'package:actlog/src/data/project_domain_stats.dart';
import 'package:actlog/src/data/project_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/l10n/l10n_scope.dart';
import 'package:actlog/src/pages/projects_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/chip_row.dart';
import 'package:actlog/src/widgets/project_domain_stats_panel.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

const String _today = '2026-11-09';

/// 造一行 `ProjectRow`（只填统计用得上的字段）。
ProjectRow _project(String id, String domain) => ProjectRow(
  id: id,
  name: id,
  goal: '',
  startDate: null,
  endDate: null,
  status: 'active',
  milestones: const <MilestoneRow>[],
  domain: domain,
);

/// 内存真库 + 真仓储 + 真项目页。
final class _Harness {
  _Harness._(this.container, this.repos, this.store);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final ProjectStore store;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task59-domain-stats-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // LIFO ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos, ProjectStore(repos));
  }

  /// 项目页是内容体，Scaffold 由调用方给。
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: L10nScope(
          localizations: AppLocalizations.zh,
          child: const MaterialApp(home: Scaffold(body: ProjectsPage())),
        ),
      ),
    );
  }
}

/// 撑高测试面：新建表单 + 面板 + 甘特图在 800×600 下会被挤。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 按提示文案找输入框（项目页的输入框没有 key）。
Finder _fieldByHint(String hint) => find.byWidgetPredicate(
  (Widget w) => w is TextField && w.decoration?.hintText == hint,
  description: 'TextField(hint: $hint)',
);

void main() {
  group('数据层 · projectDomainStats', () {
    test('D1：空列表 ⇒ 空统计', () {
      final List<ProjectDomainStat> stats = projectDomainStats(
        const <ProjectRow>[],
      );
      expect(stats, isEmpty, reason: '没有项目就没有分布，不许凭空造一个空桶');
    });

    test('D2：分桶计数与 ratio 正确', () {
      final List<ProjectDomainStat> stats = projectDomainStats(<ProjectRow>[
        _project('a', 'career'),
        _project('b', 'career'),
        _project('c', 'learning'),
      ]);
      expect(stats.length, 2, reason: '两个领域 ⇒ 两个桶');
      expect(stats.first.domain, 'career');
      expect(stats.first.count, 2);
      expect(
        stats.first.ratio,
        closeTo(2 / 3, 1e-9),
        reason: 'ratio = count / 项目总数',
      );
      expect(stats.last.domain, 'learning');
      expect(stats.last.count, 1);
      expect(stats.last.ratio, closeTo(1 / 3, 1e-9));
    });

    test('D3：数量降序；数量相同时按 key 字典序升序', () {
      final List<ProjectDomainStat> stats = projectDomainStats(<ProjectRow>[
        _project('a', 'learning'),
        _project('b', 'family'),
        _project('c', 'career'),
        _project('d', 'career'),
        _project('e', 'family'),
      ]);
      expect(stats.map((ProjectDomainStat s) => s.domain).toList(), <String>[
        'career',
        'family',
        'learning',
      ], reason: 'career / family 同为 2 ⇒ 字典序 career 在前');
      expect(stats.map((ProjectDomainStat s) => s.count).toList(), <int>[
        2,
        2,
        1,
      ]);
    });

    test('D4：未分类（空串）恒排最后，哪怕它是最大桶', () {
      final List<ProjectDomainStat> stats = projectDomainStats(<ProjectRow>[
        _project('a', ''),
        _project('b', ''),
        _project('c', ''),
        _project('d', 'career'),
      ]);
      expect(stats.map((ProjectDomainStat s) => s.domain).toList(), <String>[
        'career',
        '',
      ], reason: '空串桶数量最多也必须沉底，不能按数量排到第一');
      expect(stats.last.count, 3);
    });

    test('D5：未知 key 照实单独成桶（不猜译名、不丢弃）', () {
      final List<ProjectDomainStat> stats = projectDomainStats(<ProjectRow>[
        _project('a', 'weird-key'),
        _project('b', 'career'),
      ]);
      final ProjectDomainStat weird = stats.firstWhere(
        (ProjectDomainStat s) => s.domain == 'weird-key',
      );
      expect(weird.count, 1, reason: '未知 key 也占一桶，绝不能并进未分类');
      expect(weird.ratio, closeTo(0.5, 1e-9));
      expect(stats.length, 2);
    });
  });

  group('数据层 · 写链', () {
    late ActLogDatabase db;
    late ProjectStore store;

    setUp(() {
      db = openInMemoryActLogDatabase();
      store = ProjectStore(
        ActLogRepositories(db, deviceId: 'task59-domain-write-test'),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('D6：createProject(domain:) 落库，listProjects() 原样回读', () async {
      final String id = await store.createProject(name: 'x', domain: 'career');

      final List<ProjectData> rows = await db.select(db.project).get();
      expect(rows.length, 1);
      expect(rows.single.id, id);
      expect(rows.single.domain, 'career', reason: '写库那行的 domain 必须是所选 key');

      final ProjectRow read = (await store.listProjects()).single;
      expect(read.domain, 'career', reason: '回读链路不许把 domain 丢掉');
    });

    test('D7：createProject(domain:) 的 oplog payload 记到 domain', () async {
      final String id = await store.createProject(name: 'x', domain: 'career');

      // oplog 的 payload 是字段级 diff（`{"domain": ..., ...}`），同步侧只按
      // diff 重放；口径照 `packages/core_data/test/plan_item_detail_test.dart:65-74`。
      final int hits =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) AS c FROM oplog WHERE entity_id = '$id' "
                    "AND op = 'upsert' AND payload LIKE '%\"domain\"%'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(hits, 1, reason: '新建项目没把 domain 记进 oplog ⇒ 同步端永远收不到领域');
    });
  });

  group('界面层 · 领域分布面板', () {
    testWidgets('W1：有项目 ⇒ 面板出现，标签与项目数文案都在', (WidgetTester tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.store.createProject(name: '甲', domain: 'career');
      await harness.store.createProject(name: '乙', domain: 'career');
      await harness.store.createProject(name: '丙', domain: 'learning');
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;
      final Finder panel = find.byType(ProjectDomainStatsPanel);
      expect(panel, findsOneWidget, reason: '有项目就该有分布面板');

      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainStatsTitle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text(t.projectsDomainCareer)),
        findsOneWidget,
        reason: 'career 桶要显示本地化标签（不是原样 key）',
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainLearning),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(
            t.projectsDomainStatsCount.replaceAll('{n}', '2'),
          ),
        ),
        findsOneWidget,
        reason: '2 个 career 项目',
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(
            t.projectsDomainStatsCount.replaceAll('{n}', '1'),
          ),
        ),
        findsOneWidget,
        reason: '1 个 learning 项目',
      );
    });

    testWidgets('W2（负控）：没有任何项目 ⇒ 面板不出现', (WidgetTester tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mount(tester);
      await _settle(tester);

      expect(
        find.byType(ProjectDomainStatsPanel),
        findsNothing,
        reason: '空项目页不画分布面板，也不该画一个「未分类 0 个」的假桶',
      );
    });

    testWidgets('W3：表单选完领域再提交 ⇒ 新项目 domain 是所选 key', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;

      await tester.enterText(_fieldByHint(t.projectsNameHint), '甲');
      await tester.pump();
      // 选项是 7 枚芯片（未设置 + 6 个领域）；此时还没有项目 ⇒ 页面上
      // 「学习」只出现在表单里，不会与面板标签撞车。
      await tester.tap(find.text(t.projectsDomainLearning));
      await tester.pump();
      await tester.tap(find.text(t.projectsNewProjectAction));
      await _settle(tester);

      final List<ProjectRow> rows =
          await tester.runAsync(() => harness.store.listProjects()) ??
          const <ProjectRow>[];
      expect(rows, hasLength(1), reason: '提交后应落一个新项目');
      expect(
        rows.single.domain,
        'learning',
        reason: '表单选的领域必须一路传到 createProject(domain:)',
      );
    });

    testWidgets('W4：比例条长度严格正比于 ratio（2:1 ⇒ 2:1）', (WidgetTester tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.store.createProject(name: '甲', domain: 'career');
      await harness.store.createProject(name: '乙', domain: 'career');
      await harness.store.createProject(name: '丙', domain: 'learning');
      await harness.mount(tester);
      await _settle(tester);

      final Finder careerTrack = find.byKey(
        ProjectDomainStatsPanel.barTrackKey('career'),
      );
      final Finder careerFill = find.byKey(
        ProjectDomainStatsPanel.barFillKey('career'),
      );
      final Finder learningFill = find.byKey(
        ProjectDomainStatsPanel.barFillKey('learning'),
      );
      expect(careerTrack, findsOneWidget);
      expect(careerFill, findsOneWidget);
      expect(learningFill, findsOneWidget);

      final double track = tester.getSize(careerTrack).width;
      final double career = tester.getSize(careerFill).width;
      final double learning = tester.getSize(learningFill).width;

      expect(track, greaterThan(0));
      expect(
        career,
        closeTo(track * 2 / 3, 1.0),
        reason: '2/3 的桶 ⇒ 条长 = 轨道宽 × 2/3',
      );
      expect(
        learning,
        closeTo(track / 3, 1.0),
        reason: '1/3 的桶 ⇒ 条长 = 轨道宽 × 1/3',
      );
      expect(
        career / learning,
        closeTo(2.0, 0.05),
        reason: '条长之比必须等于 ratio 之比',
      );
    });

    testWidgets('W5：未知领域 key 原样显示，不被吞成「未分类」', (WidgetTester tester) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      // 6 个固定 key 之外的取值（同步进来的历史 key 就长这样）。
      await harness.store.createProject(name: '甲', domain: 'legacy-x');
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;
      // 表单里的「所属领域」芯片会撞文案 ⇒ 断言一律限定在面板内。
      final Finder panel = find.byType(ProjectDomainStatsPanel);
      expect(panel, findsOneWidget, reason: '有项目就该有分布面板');

      expect(
        find.descendant(of: panel, matching: find.text('legacy-x')),
        findsOneWidget,
        reason: '未知 key 必须原样当文本显示（不猜译名、不丢信息）',
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainStatsUncategorized),
        ),
        findsNothing,
        reason:
            '未知 key ≠ 未分类：`_domainLabel` 的 `default: return key` '
            '若被改成返回未分类文案，这条会挂',
      );
    });

    testWidgets('W5b：空串 domain ⇒ 面板显示「未分类」，不借用「未设置」', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      // 不传 domain ⇒ 默认空串 = 未分类。
      await harness.store.createProject(name: '甲');
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;
      final Finder panel = find.byType(ProjectDomainStatsPanel);
      expect(panel, findsOneWidget, reason: '有项目就该有分布面板');

      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainStatsUncategorized),
        ),
        findsOneWidget,
        reason: '空串桶就是未分类桶',
      );
      expect(
        find.descendant(of: panel, matching: find.text(t.projectsDomainUnset)),
        findsNothing,
        reason: '「未设置」是表单占位文案，面板里出现说明标签接线串了',
      );
    });

    testWidgets('W7：领域芯片 = projectDomainKeys × 本地化标签，两处真源锁死', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;
      final Finder chipRowFinder = find.byType(ChipRow);
      expect(chipRowFinder, findsOneWidget, reason: '新建项目表单里就只有这一排领域芯片');
      final ChipRow chipRow = tester.widget<ChipRow>(chipRowFinder);

      // 期望值**不从 `_domainLabel` 反推**：这里手写「6 个固定 key ⇒ 本地化
      // 文案」的对照，只依赖 l10n getter。若 `projectDomainKeys` 多一个 key 而
      // `_domainLabel` 少一个映射，那枚芯片会显示原始 key（英文小写串），
      // 下面的集合相等断言必挂。
      final Map<String, String> expected = <String, String>{
        'career': t.projectsDomainCareer,
        'wealth': t.projectsDomainWealth,
        'family': t.projectsDomainFamily,
        'learning': t.projectsDomainLearning,
        'social': t.projectsDomainSocial,
        'health': t.projectsDomainHealth,
      };

      // 空串那枚（「未设置」）不属于 6 个固定领域：单独摘出来断言，不进对照表。
      final Map<String, String> actual = <String, String>{
        for (final ChipOption option in chipRow.options)
          if (option.key.isNotEmpty) option.key: option.label,
      };

      expect(
        chipRow.options.length,
        expected.length + 1,
        reason: '芯片 = 未设置 + 6 个固定领域；多一枚说明 projectDomainKeys 加了 key',
      );
      expect(
        projectDomainKeys.toSet(),
        expected.keys.toSet(),
        reason: 'projectDomainKeys 必须是这 6 个 key（数据层真源）',
      );
      expect(
        actual,
        expected,
        reason:
            'key 集合与显示文案必须逐项相等：`_domainLabel` 漏一个映射，'
            '那枚芯片就显示原始 key 而不是本地化文案（页面真源与数据层脱钩）',
      );

      final ChipOption unset = chipRow.options.firstWhere(
        (ChipOption option) => option.key.isEmpty,
      );
      expect(unset.label, t.projectsDomainUnset, reason: '空串芯片 = 「未设置」');
    });
  });
}
