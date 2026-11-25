// apps/desktop/test/task60_project_domain_edit_test.dart
//
// Task 60 · 「既有项目的所属领域可改」+ 领域真源单一化（界面侧）。
//
// 数据层（纯 `test()`）钉四条：
//   T1：`setProjectDomain` 落库 ⇒ `domain` 变、`rev` 递增 1、`updatedAt` 前进，
//       `listProjects()` 回读同值；
//   T2：传空串 ⇒ 清除领域，统计里落「未分类」桶且**恒排最后**；
//   T3：写入后 `oplog` 里有 `entity_table = 'project'`、`entity_id = 该项目 id`、
//       payload 含 `domain` 字段（同步侧看不到就等于丢改动）；
//   T4：真源单一 —— `projectDomainKeys` 就是那 6 个 key、顺序固定；
//       `projectDomainLabel` 对它们给非空且互不相同的译名，空串 ⇒ 未分类文案，
//       未知 key ⇒ 原样返回 key。
//
// 界面层（`testWidgets`）钉三条：
//   T5：项目卡片内有「所属领域」内联编辑行（`ChipRow` 从 1 排变 2 排），
//       点「事业」⇒ 落库 `domain == 'career'` ⇒ 卡片选中态与分布面板同步刷新；
//   T6：未知 key 的项目 ⇒ 分布面板单独成桶、原样显示 key（不吞成「未分类」），
//       卡片的 7 枚芯片里没有那一枚，但选中集合仍记着原值；
//   T7：**再点一次**已选中的「事业」⇒ 清除领域（界面点选路径；T2 只钉了数据
//       层直接传空串），选中态与分布面板双双回落「未分类」。
//
// 异常分支（60.4c 的另一半，`project_store.dart:503-506` 那道守卫）钉两条：
//   T8：**不存在**的项目 id ⇒ 抛 `MissingEntityException`（kind=project），且不留下项目行、不落 oplog；
//   T9：**已被软删**（`deleted_at != null`）的项目行 ⇒ 同样抛 `MissingEntityException`，
//       墓碑行原样不动（domain / rev / deleted_at 三列都不许被改写）。
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

/// 内存真库 + 真仓储 + 真项目页。
final class _Harness {
  _Harness._(this.container, this.db, this.store);

  final ProviderContainer container;
  final ActLogDatabase db;
  final ProjectStore store;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task60-domain-edit-test',
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
    return _Harness._(container, db, ProjectStore(repos));
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

/// 撑高测试面：表单 + 面板 + 甘特图 + 卡片在 800×600 下会被挤。
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

void main() {
  group('数据层 · setProjectDomain', () {
    late ActLogDatabase db;
    late ProjectStore store;

    setUp(() {
      db = openInMemoryActLogDatabase();
      store = ProjectStore(
        ActLogRepositories(db, deviceId: 'task60-domain-edit-test'),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('T1：落库后 rev +1、updatedAt 前进，listProjects() 回读新领域', () async {
      final String id = await store.createProject(name: 'x');
      final ProjectData before = await (db.select(
        db.project,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(before.domain, '', reason: '不传 domain 的新项目落在未分类');

      // `nowMillis()` 是毫秒：跨过一个刻度，`updated_at` 才可能真的前进。
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await store.setProjectDomain(projectId: id, domain: 'career');

      final ProjectData after = await (db.select(
        db.project,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(after.domain, 'career', reason: '改的就是这一列');
      expect(
        after.rev,
        before.rev + 1,
        reason: '每次写业务列都要抬 rev：同步端靠它判新旧，漏抬会被旧记录覆盖回去',
      );
      expect(
        after.updatedAt,
        greaterThan(before.updatedAt),
        reason: 'updatedAt 必须前进，否则增量拉取看不出这次改动',
      );

      final List<ProjectRow> rows = await store.listProjects();
      expect(rows.single.domain, 'career', reason: '回读链路不许把 domain 丢掉');
    });

    test('T2：传空串 ⇒ 清除领域，统计落「未分类」桶且排最后', () async {
      final String id = await store.createProject(name: 'x', domain: 'career');
      await store.createProject(name: 'y', domain: 'family');

      await store.setProjectDomain(projectId: id, domain: '');

      final ProjectData row = await (db.select(
        db.project,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.domain, '', reason: '空串就是「清除」，不是写 NULL 或哨兵值');

      final List<ProjectDomainStat> stats = projectDomainStats(
        await store.listProjects(),
      );
      expect(
        stats.map((ProjectDomainStat s) => s.domain).toList(),
        <String>['family', ''],
        reason: '空串桶即使与其它桶同数量也恒排最后',
      );
      expect(stats.last.count, 1);
    });

    test('T3：写入后 oplog 记到 project / 该项目 id / payload 含 domain', () async {
      final String id = await store.createProject(name: 'x');

      await store.setProjectDomain(projectId: id, domain: 'career');

      final int count =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) AS c FROM oplog "
                    "WHERE entity_table = 'project' AND entity_id = '$id'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(
        count,
        2,
        reason: 'create 一条 + 改领域一条：一次业务写只许留一条痕，多一条就是重复记账',
      );

      // 最后那条必须是 upsert，且 payload（字段级 diff）里带 domain 与新值。
      final String payload =
          (await db
                  .customSelect(
                    'SELECT payload FROM oplog '
                    "WHERE entity_table = 'project' AND entity_id = '$id' "
                    'ORDER BY id DESC LIMIT 1',
                  )
                  .getSingle())
              .read<String>('payload');
      expect(
        payload,
        contains('"domain"'),
        reason: 'payload 里没有 domain ⇒ 同步端重放时收不到这次领域改动',
      );
      expect(
        payload,
        contains('"career"'),
        reason: 'payload 要带新值，不能只留字段名',
      );
    });

    test('T4（真源）：projectDomainKeys 固定 6 个 key，projectDomainLabel 全覆盖', () {
      final AppLocalizations t = AppLocalizations.zh;

      expect(
        projectDomainKeys,
        <String>['career', 'wealth', 'family', 'learning', 'social', 'health'],
        reason: 'key 清单的真源只有一处，顺序也是它定的',
      );

      final List<String> labels = projectDomainKeys
          .map((String key) => t.projectDomainLabel(key))
          .toList();
      expect(
        labels.where((String label) => label.isEmpty),
        isEmpty,
        reason: '六个 key 都必须有译名，缺一个就说明真源与 l10n 脱钩',
      );
      expect(
        labels.toSet().length,
        projectDomainKeys.length,
        reason: '六枚芯片的文案必须互不相同，否则用户点不出区别',
      );

      expect(
        t.projectDomainLabel(''),
        t.projectsDomainStatsUncategorized,
        reason: '空串 ⇒ 未分类文案（与统计面板同一句）',
      );
      expect(
        t.projectDomainLabel('legacy-x'),
        'legacy-x',
        reason: '未知 key 原样返回：它不是未分类，不许被吞成一句通用文案',
      );
    });

    test('T8（60.4c）：不存在的项目 id ⇒ 抛 MissingEntityException，且不落任何写入', () async {
      // 不建这行：守卫的「project == null」半边只有这条能撞到。
      const String missingId = 'task60-missing-project';

      await expectLater(
        store.setProjectDomain(projectId: missingId, domain: 'career'),
        throwsA(
          isA<MissingEntityException>()
              .having(
                (MissingEntityException e) => e.kind,
                'kind',
                MissingEntityException.projectKind,
              )
              .having((MissingEntityException e) => e.id, 'id', missingId),
        ),
        reason: '项目不存在时必须抛错，不许静默当成功（否则调用方以为改成了）',
      );

      final List<ProjectData> rows =
          await (db.select(db.project)
                ..where((t) => t.id.equals(missingId)))
              .get();
      expect(rows, isEmpty, reason: '被拒的写不许凭空造出一行项目');

      final int oplogCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) AS c FROM oplog "
                    "WHERE entity_table = 'project' AND entity_id = '$missingId'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(oplogCount, 0, reason: '守卫在写之前就抛：oplog 里一条痕都不该有');
    });

    test('T9（60.4c）：已软删的项目行 ⇒ 同样抛 MissingEntityException，墓碑行原样不动', () async {
      final String id = await store.createProject(name: '甲', domain: 'career');
      final ProjectData before =
          await (db.select(db.project)..where((t) => t.id.equals(id))).getSingle();

      // 项目表既没有仓储层、也没有 `deleteProject` 之类的 API（全仓搜索零命中），
      // 写入通道只有 `repos.oplog.writeWithOplog`（`project_store.dart:4-8` 的口径）
      // ⇒ 墓碑按同一套账本规矩造：业务行与 delete 记录同事务，payload 记
      // `{"deleted_at": <ms>}`。
      const int tombstoneAt = 1762041600000;
      await store.repos.oplog.writeWithOplog<void>(
        table: TableNames.project,
        id: id,
        isDelete: true,
        deletedAt: tombstoneAt,
        write: () => db.customStatement(
          'UPDATE project SET deleted_at = ?, updated_at = ?, rev = ? '
          'WHERE id = ?',
          <Object?>[tombstoneAt, tombstoneAt, before.rev + 1, id],
        ),
      );

      final ProjectData tomb =
          await (db.select(db.project)..where((t) => t.id.equals(id))).getSingle();
      expect(
        tomb.deletedAt,
        tombstoneAt,
        reason: '前提：造出来的必须是墓碑行 —— 否则 T9 撞的是「不存在」那一半，会假绿',
      );
      expect(
        await store.listProjects(),
        isEmpty,
        reason: '墓碑行不出现在列表里但行还在：这是「已删除」与「不存在」的分界',
      );

      await expectLater(
        store.setProjectDomain(projectId: id, domain: 'family'),
        throwsA(
          isA<MissingEntityException>()
              .having(
                (MissingEntityException e) => e.kind,
                'kind',
                MissingEntityException.projectKind,
              )
              .having((MissingEntityException e) => e.id, 'id', id),
        ),
        reason: '已删项目改领域必须抛错，不许把墓碑行复活',
      );

      final ProjectData after =
          await (db.select(db.project)..where((t) => t.id.equals(id))).getSingle();
      expect(after.domain, 'career', reason: '守卫先抛 ⇒ 领域列不许被改写');
      expect(
        after.rev,
        tomb.rev,
        reason: '被拒的写不许抬 rev：抬了就等于告诉同步端「这一行变了」',
      );
      expect(after.deletedAt, tombstoneAt, reason: '墓碑时刻也不许被顺手清掉');

      final int oplogCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) AS c FROM oplog "
                    "WHERE entity_table = 'project' AND entity_id = '$id'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(
        oplogCount,
        2,
        reason: 'create 一条 + 墓碑一条；被拒的改领域不许落第三条账',
      );
    });
  });

  group('界面层 · 卡片内的领域编辑', () {
    testWidgets('T5：卡片内联「所属领域」行，点「事业」⇒ 落库并刷新选中态', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      await harness.store.createProject(name: '甲');
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;

      // 两排芯片：新建表单（前）+ 唯一一张项目卡片的内联编辑行（后）。
      final Finder chipRows = find.byType(ChipRow);
      expect(
        chipRows,
        findsNWidgets(2),
        reason: '卡片里没有编辑行 ⇒ 只剩表单那一排',
      );
      final Finder cardChipRow = chipRows.last;
      expect(
        find.text(t.projectsDomainFieldLabel),
        findsNWidgets(2),
        reason: '「所属领域」行标签在表单与卡片各出现一次',
      );
      expect(
        tester.widget<ChipRow>(cardChipRow).selected,
        <String>{''},
        reason: '未分类项目选中的是「未设置」那枚（空串）：选中集恒等于 `{project.domain}`',
      );

      await tester.tap(
        find.descendant(
          of: cardChipRow,
          matching: find.text(t.projectsDomainCareer),
        ),
      );
      await _settle(tester);

      final List<ProjectRow> rows =
          await tester.runAsync(() => harness.store.listProjects()) ??
          const <ProjectRow>[];
      expect(rows, hasLength(1));
      expect(
        rows.single.domain,
        'career',
        reason: '点芯片必须一路走到 setProjectDomain 并写库',
      );

      expect(
        tester.widget<ChipRow>(find.byType(ChipRow).last).selected,
        <String>{'career'},
        reason: '写完 `_reload()` ⇒ 卡片的选中态跟着变（断言 widget 属性，不看像素）',
      );
      expect(
        tester.widget<ChipRow>(find.byType(ChipRow).first).selected,
        <String>{''},
        reason: '表单那一排独立：仍停在「未设置」那枚（空串），没有被卡片那边的「事业」污染',
      );

      final Finder panel = find.byType(ProjectDomainStatsPanel);
      expect(
        find.descendant(of: panel, matching: find.text(t.projectsDomainCareer)),
        findsOneWidget,
        reason: '分布面板同源刷新：career 桶出现，未分类桶消失',
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainStatsUncategorized),
        ),
        findsNothing,
      );
    });

    testWidgets('T6：未知 key 的项目 ⇒ 面板单独成桶并原样显示 key', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      // 6 个固定 key 之外的取值（同步进来的历史 key 就长这样）。
      await harness.store.createProject(name: '甲', domain: 'legacy-y');
      await harness.mount(tester);
      await _settle(tester);

      final AppLocalizations t = AppLocalizations.zh;
      final Finder panel = find.byType(ProjectDomainStatsPanel);
      expect(panel, findsOneWidget, reason: '有项目就该有分布面板');

      expect(
        find.descendant(of: panel, matching: find.text('legacy-y')),
        findsOneWidget,
        reason: '未知 key 必须原样当文本显示（不猜译名、不丢信息）',
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainStatsUncategorized),
        ),
        findsNothing,
        reason: '未知 key ≠ 未分类：两者被并桶就意味着信息丢失',
      );

      // 卡片那排只有「未设置 + 6 个固定领域」⇒ 没有任何一枚能表示 legacy-y，
      // 但选中集合必须原样留着它（不许被清成空、也不许当成未分类）。
      final ChipRow cardRow = tester.widget<ChipRow>(
        find.byType(ChipRow).last,
      );
      expect(
        cardRow.options.map((ChipOption o) => o.key),
        isNot(contains('legacy-y')),
        reason: '编辑行只给固定领域，历史 key 不在可选项里',
      );
      expect(
        cardRow.selected,
        <String>{'legacy-y'},
        reason: '选中集合照实反映库里的值：读一眼就知道当前是历史 key',
      );
    });

    testWidgets('T7：再点一次已选中的「事业」⇒ 清除领域，选中态与面板回落未分类', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final _Harness harness = _Harness.create();
      // 两个项目：甲是要被清除的那个（career ⇒ 空串），乙一直留在 family。
      // 有乙在，「未分类恒排最后」才是一条能证伪的断言（同数量也不许跑上来）。
      await harness.store.createProject(name: '甲');
      await harness.store.createProject(name: '乙', domain: 'family');

      final AppLocalizations t = AppLocalizations.zh;

      // 卡片顺序 = `listProjects()` 顺序，表单那排芯片是第 0 枚 `ChipRow`
      // ⇒ 目标卡片内联行的下标能先在库里算出来，两次点击都打在**同一张卡片**上。
      final List<ProjectRow> seeded = await harness.store.listProjects();
      final int targetIndex = seeded.indexWhere(
        (ProjectRow p) => p.name == '甲',
      );
      expect(targetIndex, greaterThanOrEqualTo(0), reason: '前提：目标项目在库里');
      final Finder cardRow = find.byType(ChipRow).at(1 + targetIndex);

      await harness.mount(tester);
      await _settle(tester);

      // 两次点击复用同一个 Finder：第 2 次必须还是同一枚「事业」。换成
      // 「未设置」也能清空 domain，那就测不出「再点已选中即清除」这条规则。
      final Finder careerChip = find.descendant(
        of: cardRow,
        matching: find.text(t.projectsDomainCareer),
      );
      expect(careerChip, findsOneWidget, reason: '目标卡片里有一枚「事业」芯片');

      // 第 1 次点：未分类 ⇒ career（这是清除那条分支的前置状态）。
      await tester.tap(careerChip);
      await _settle(tester);

      List<ProjectRow> rows =
          await tester.runAsync(() => harness.store.listProjects()) ??
          const <ProjectRow>[];
      expect(
        rows.firstWhere((ProjectRow p) => p.name == '甲').domain,
        'career',
        reason: '第 1 次点要真写进库，否则第 2 次点的还是未分类态，等于没测',
      );
      expect(tester.widget<ChipRow>(cardRow).selected, <String>{'career'});

      // 第 2 次点同一枚「事业」：`ChipRow` 单选回传的仍是 `{'career'}`（不是
      // 空集），页面据「点中值 == 当前值」把它翻成空串 ⇒ 清除。
      await tester.tap(careerChip);
      await _settle(tester);

      rows =
          await tester.runAsync(() => harness.store.listProjects()) ??
          const <ProjectRow>[];
      expect(
        rows.firstWhere((ProjectRow p) => p.name == '甲').domain,
        '',
        reason: '再点已选中的芯片必须清除领域，否则用户没法把项目退回未分类',
      );
      expect(
        tester.widget<ChipRow>(cardRow).selected,
        <String>{''},
        reason: '清除后卡片选中的是「未设置」那枚（选中集 = `{project.domain}`）',
      );

      // 分布面板同源刷新：career 桶消失、未分类桶回来，且画在 family 桶下面
      // （同数量也恒排最后）。
      final Finder panel = find.byType(ProjectDomainStatsPanel);
      expect(
        find.descendant(
          of: panel,
          matching: find.text(t.projectsDomainStatsUncategorized),
        ),
        findsOneWidget,
        reason: '面板重新显示「未分类」那一行',
      );
      expect(
        find.descendant(of: panel, matching: find.text(t.projectsDomainCareer)),
        findsNothing,
        reason: 'career 桶已消失：面板不是残留的旧快照',
      );
      final Finder familyBar = find.byKey(
        ProjectDomainStatsPanel.barTrackKey('family'),
      );
      final Finder unclassifiedBar = find.byKey(
        ProjectDomainStatsPanel.barTrackKey(''),
      );
      expect(
        tester.getTopLeft(unclassifiedBar).dy,
        greaterThan(tester.getTopLeft(familyBar).dy),
        reason: '未分类桶画在 family 桶下面：两者同为 1 个项目，它仍恒排最后',
      );
    });
  });
}