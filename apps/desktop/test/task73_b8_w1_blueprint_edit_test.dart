// =============================================================================
// Task 73 · B8-W1：蓝图页的目标编辑能力（格内新建 / 卡片编辑 / 卡片删除）
// =============================================================================
// 钉住派工书（docs\b81-dispatch-w1.md §5）的四条口径：
//  T1  格内「+ 新建目标」→ 表单 → `GoalStore.createGoal` 落库；
//      裁决 **D-8-e**：表单的 `domain` + `horizon` 默认**预填所在格子** ⇒
//      用户只填标题，新目标也必须落在**那一格**（不是落到未分类/终极档）。
//  T1b 表单点「取消」⇒ 库里 0 增量（编辑动作不许有隐式写入）。
//  T2  卡片「编辑」→ 改标题、把领域选成「未设置」⇒ SQLite 里 `domain` 回到 NULL。
//      这条守的是 `updateGoal(goalId, domain: null)` 与 `clear: {GoalField.domain}`
//      的语义差别：前者是「不动」，只有后者才置空。
//  T3  卡片「删除」必须**先二次确认**：取消不触库；确认后 `goal.deleted_at` 非空
//      （软删墓碑，行还在 ⇒ 同步端能重放），且卡片从矩阵消失。
//  T4  两个方向各钉一边：
//      T4a 三个回调都不传 ⇒ 矩阵**一个新按钮都不渲染**（坑 48：既有调用点行为逐字不变）；
//      T4b 英文态表单里不残留 CJK（所有文案走 `t.` getter）。
//
// 判据一律**回读 SQLite**（原生 SQL `customSelect`），不看像素。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart'
    show GoalHorizon, GoalKind, GoalPeriod;
// `QueryRow` 是 `customSelect` 的行类型，drift 从 2.x 起只在 drift.dart 导出。
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// `goal` 表一行的原生回读结果（列名是真表列名，不是 Dart 字段名）。
class _RawGoal {
  /// 构造。
  const _RawGoal({
    required this.title,
    required this.kind,
    this.note,
    this.keywords,
    this.domain,
    this.horizon,
    this.facet,
    this.dueDate,
    this.priorityAbc,
    this.quadrant,
    this.deletedAt,
  });

  final String title;
  final String kind;
  final String? note;
  final String? keywords;
  final String? domain;
  final int? horizon;
  final String? facet;
  final int? dueDate;
  final String? priorityAbc;
  final int? quadrant;
  final int? deletedAt;
}

const String _goalColumns =
    'title, kind, note, keywords, domain, horizon, facet, due_date, '
    'priority_abc, quadrant, deleted_at';

/// 按 id 回读一条目标（行不存在返回 null）。
Future<_RawGoal?> _goalById(ActLogDatabase db, String id) async {
  final List<QueryRow> rows = await db
      .customSelect('SELECT $_goalColumns FROM goal WHERE id = \'$id\'')
      .get();
  if (rows.isEmpty) {
    return null;
  }
  return _fromRow(rows.first.data);
}

/// 按标题回读目标（用于断言「恰好新增了一条」）。
Future<List<_RawGoal>> _goalsByTitle(ActLogDatabase db, String title) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT $_goalColumns FROM goal WHERE title = \'$title\'',
      )
      .get();
  return <_RawGoal>[for (final QueryRow r in rows) _fromRow(r.data)];
}

_RawGoal _fromRow(Map<String, Object?> d) => _RawGoal(
  title: d['title']! as String,
  kind: d['kind']! as String,
  note: d['note'] as String?,
  keywords: d['keywords'] as String?,
  domain: d['domain'] as String?,
  horizon: d['horizon'] as int?,
  facet: d['facet'] as String?,
  dueDate: d['due_date'] as int?,
  priorityAbc: d['priority_abc'] as String?,
  quadrant: d['quadrant'] as int?,
  deletedAt: d['deleted_at'] as int?,
);

/// 毫秒 → `YYYY-MM-DD`（本地日）；null 透传。
String? _dayOf(int? millis) {
  if (millis == null) {
    return null;
  }
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(millis);
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// 造数据：1 条年目标（近期列数据源）+ 1 条 career/ultimate 蓝图（编辑删除靶子）。
class _Seed {
  /// 构造。
  const _Seed({required this.bpId, required this.yearlyId});

  /// career × 终极档的蓝图目标 id。
  final String bpId;

  /// 本年年度目标 id。
  final String yearlyId;
}

Future<_Seed> _seed(GoalStore store) async {
  final GoalPeriod year = GoalPeriod.year(2026);
  final String yearlyId = await store.createGoal(
    kind: GoalKind.yearly,
    title: '年度主攻',
    domain: 'career',
    periodStart: year.startMillis,
    periodEnd: year.endMillis,
  );
  final String bpId = await store.createGoal(
    kind: GoalKind.blueprint,
    title: '终极蓝图',
    note: '原备注',
    keywords: '原关键词',
    domain: 'career',
    horizon: GoalHorizon.ultimate,
  );
  return _Seed(bpId: bpId, yearlyId: yearlyId);
}

/// 挂起人生蓝图页（抄 `task66_goals_blueprint_page_test.dart:114-150`）。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
  AppLanguage language = AppLanguage.zh,
  String instance = 'bp-1',
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(
              AppPreferences.defaults,
            ),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(key: ValueKey<String>(instance)),
            ),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 滚到某个 key 上并点它（矩阵在长表格里，不 ensureVisible 点不到）。
Future<void> _tapKey(WidgetTester tester, Key key) async {
  final Finder target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task73-blueprint-edit-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('T1 格内新建：只填标题也落在所在格的 domain+horizon（D-8-e）',
      (WidgetTester tester) async {
        await _seed(store);
        await _pumpBlueprint(tester, repos: repos);

        final AppLocalizations zh = AppLocalizations.zh;
        // learning × 短期 这一格本来是空的 ⇒ 入口 key 带领域 + 档位。
        expect(
          find.byKey(const ValueKey<String>('goal-blueprint-add-learning-short')),
          findsOneWidget,
          reason: '空格子里要有「+ 新建目标」入口：${zh.goalBlueprintAddGoal}',
        );
        await _tapKey(
          tester,
          const ValueKey<String>('goal-blueprint-add-learning-short'),
        );

        // 表单必须已经带着所在格的领域 + 档位打开（不靠用户重选）。
        final DropdownButtonFormField<String> domain = tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey<String>('goal-blueprint-form-domain')),
            );
        expect(domain.initialValue, 'learning', reason: '领域没预填所在格 ⇒ D-8-e 破');
        final DropdownButtonFormField<GoalHorizon?> horizon = tester
            .widget<DropdownButtonFormField<GoalHorizon?>>(
              find.byKey(const ValueKey<String>('goal-blueprint-form-horizon')),
            );
        expect(horizon.initialValue, GoalHorizon.short);

        await tester.enterText(
          find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
          '学会游泳',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('goal-blueprint-form-note')),
          '先练憋气',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('goal-blueprint-form-keywords')),
          '游泳,呼吸',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('goal-blueprint-form-due')),
          '2026-12-31',
        );
        await _tapKey(
          tester,
          const ValueKey<String>('goal-blueprint-form-save'),
        );

        final List<_RawGoal> created = await _goalsByTitle(db, '学会游泳');
        expect(created.length, 1, reason: '保存后 SQLite 里应恰好新增一条目标');
        final _RawGoal g = created.single;
        expect(g.kind, 'blueprint', reason: '07 页建的必须是蓝图目标');
        expect(g.domain, 'learning', reason: '领域 = 所在格（回读 SQLite）');
        expect(g.horizon, GoalHorizon.ultimate.value + 3, reason: '短期存 4');
        expect(g.note, '先练憋气');
        expect(g.keywords, '游泳,呼吸');
        expect(_dayOf(g.dueDate), '2026-12-31', reason: '期限要落库成毫秒');
        expect(g.deletedAt, isNull, reason: '新建不是删除');
        expect(
          find.byKey(const ValueKey<String>('goal-blueprint-goal-saved')),
          findsOneWidget,
          reason: '写库成功要给用户可见反馈：${zh.goalBlueprintGoalSaved}',
        );
        // 新目标要立刻出现在原来那一格。
        expect(
          find.byKey(ValueKey<String>('goal-blueprint-cell-${g.title.hashCode}')),
          findsNothing,
          reason: '哨兵断言：cell key 用的是目标 id，不是标题',
        );
      });

  testWidgets('T1b 新建表单点取消 ⇒ 库里 0 增量', (WidgetTester tester) async {
    await _seed(store);
    final int before = (await store.listGoals()).length;
    await _pumpBlueprint(tester, repos: repos);

    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-add-family-long'),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      '不该存在的一条',
    );
    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-form-cancel'),
    );

    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      findsNothing,
      reason: '取消后表单要关掉',
    );
    expect((await store.listGoals()).length, before, reason: '取消 = 一次写都不许发生');
    expect(await _goalsByTitle(db, '不该存在的一条'), isEmpty);
  });

  testWidgets('T2 卡片编辑：预填既有值；领域选「未设置」要真的写回 NULL',
      (WidgetTester tester) async {
        final _Seed seed = await _seed(store);
        await _pumpBlueprint(tester, repos: repos);

        expect(
          find.byKey(ValueKey<String>('goal-blueprint-edit-${seed.bpId}')),
          findsOneWidget,
          reason: '目标卡片上要有「编辑」入口',
        );
        await _tapKey(
          tester,
          ValueKey<String>('goal-blueprint-edit-${seed.bpId}'),
        );

        final TextField titleField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
        );
        expect(
          titleField.controller?.text,
          '终极蓝图',
          reason: '编辑表单必须预填既有标题（这是「编辑」不是「新建」）',
        );
        final TextField noteField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('goal-blueprint-form-note')),
        );
        expect(noteField.controller?.text, '原备注');

        await tester.enterText(
          find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
          '终极蓝图（已改）',
        );
        // 领域下拉改成「未设置」⇒ 走 clear:{GoalField.domain}。
        await _tapKey(
          tester,
          const ValueKey<String>('goal-blueprint-form-domain'),
        );
        final AppLocalizations zh = AppLocalizations.zh;
        await tester.tap(find.text(zh.goalBlueprintFieldUnset).last);
        await tester.pumpAndSettle();
        await _tapKey(
          tester,
          const ValueKey<String>('goal-blueprint-form-save'),
        );

        final _RawGoal? g = await _goalById(db, seed.bpId);
        expect(g, isNotNull);
        expect(g!.title, '终极蓝图（已改）', reason: '改动要落到同一行，不是新建一行');
        expect(
          g.domain,
          isNull,
          reason: '表单里清掉领域必须写 NULL：'
              'updateGoal 传 null 的语义是「不动」，只有 clear:{GoalField.domain} 才置空',
        );
        expect(g.horizon, GoalHorizon.ultimate.value, reason: '没碰档位 ⇒ 原值保留（预填生效）');
        expect(g.note, '原备注', reason: '没改的备注不许被表单抹掉');
        expect(g.keywords, '原关键词');
        expect(
          find.byKey(const ValueKey<String>('goal-blueprint-goal-saved')),
          findsOneWidget,
        );
      });

  testWidgets('T3 删除要二次确认：取消不触库；确认后写墓碑且卡片消失',
      (WidgetTester tester) async {
        final _Seed seed = await _seed(store);
        await _pumpBlueprint(tester, repos: repos);

        await _tapKey(
          tester,
          ValueKey<String>('goal-blueprint-delete-${seed.bpId}'),
        );
        expect(
          find.byKey(const ValueKey<String>('goal-blueprint-delete-confirm')),
          findsOneWidget,
          reason: '删除必须先弹二次确认，不能一点就删',
        );
        await _tapKey(
          tester,
          const ValueKey<String>('goal-blueprint-delete-cancel'),
        );
        expect(
          (await _goalById(db, seed.bpId))!.deletedAt,
          isNull,
          reason: '确认框点取消就不许触库',
        );

        await _tapKey(
          tester,
          ValueKey<String>('goal-blueprint-delete-${seed.bpId}'),
        );
        await _tapKey(
          tester,
          const ValueKey<String>('goal-blueprint-delete-confirm'),
        );

        final _RawGoal? after = await _goalById(db, seed.bpId);
        expect(after, isNotNull, reason: '删除是软删：行要留在表里靠 deleted_at 同步');
        expect(after!.deletedAt, isNotNull, reason: '墓碑时间必须写上');
        expect(
          find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.bpId}')),
          findsNothing,
          reason: '确认后矩阵里不能再看到这条目标',
        );
        expect(
          find.byKey(const ValueKey<String>('goal-blueprint-goal-deleted')),
          findsOneWidget,
        );
      });

  testWidgets('T4a 三个回调都不传 ⇒ 矩阵一个新按钮都不渲染', (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    final List<GoalRow> all = await store.listGoals();
    final GoalRow bp = all.firstWhere((GoalRow g) => g.id == seed.bpId);
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);

    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalBlueprintMatrix(
              t: AppLocalizations.zh,
              rows: <GoalBlueprintRow>[
                GoalBlueprintRow(
                  domainKey: 'career',
                  cells: <GoalHorizon, List<GoalRow>>{
                    GoalHorizon.ultimate: <GoalRow>[bp],
                  },
                ),
              ],
              serves: serves,
              tracksCount: const <String, int>{},
              onSplitTodos: (GoalRow _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 既有内容一字不变地还在。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${seed.bpId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-split-${seed.bpId}')),
      findsOneWidget,
    );
    // 不传回调 ⇒ 新入口一个都不渲染。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-edit-${seed.bpId}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-delete-${seed.bpId}')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-career-ultimate')),
      findsNothing,
      reason: '有目标的格子不该出现「新建」入口，且没传回调时更不该有',
    );
  });

  testWidgets('T4b 英文态：表单与二次确认框里不残留中文', (WidgetTester tester) async {
    final _Seed seed = await _seed(store);
    await _pumpBlueprint(tester, repos: repos, language: AppLanguage.en);

    final RegExp cjk = RegExp(r'[\u3400-\u9fff\uf900-\ufaff]');
    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-add-social-mid'),
    );
    for (final Text w in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Text),
      ),
    )) {
      final String? s = w.data;
      if (s == null) {
        continue;
      }
      expect(cjk.hasMatch(s), isFalse, reason: '英文态表单漏出中文：$s');
    }
    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-form-cancel'),
    );

    await _tapKey(
      tester,
      ValueKey<String>('goal-blueprint-delete-${seed.bpId}'),
    );
    for (final Text w in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Text),
      ),
    )) {
      final String? s = w.data;
      if (s == null) {
        continue;
      }
      expect(cjk.hasMatch(s), isFalse, reason: '英文态确认删除框漏出中文：$s');
    }
    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-delete-cancel'),
    );
  });
}
