// =============================================================================
// B12 · 用户反馈第 2、3 条：蓝图矩阵的标签 / 上下边距 / 期限（6 条运行时用例）
// =============================================================================
// 反馈原文：
//   2. 目标模块美化不理想，标签请参考 chrome 或 edge 浏览器的标签，表格中的
//      内容，适当增加上下边距；
//   3. 目标输入的结束日期，点击请弹出日期选择框，可以点击选择；当前填写日期后，
//      无法出现在第三列，请检查修复bug；目标框中，不要显示"条做法"、"未落位"。
//
// 本文件只钉**行为**，不改任何 lib 源码。6 条用例与反馈的对应关系：
//  R2-1（第 3 条）只有 `due_date`、没有起止（`period_*`）的历史目标 ⇒ 第三列
//       回退显示该期限（旧数据可见性）。
//  R2-2（第 3 条）页面新建带期限的目标 ⇒ `period_end` 与 `due_date` 同写，
//       且第三列立刻显示所选日期（端到端：表单 → store → 矩阵）。
//  R2-3（第 3 条）期限字段只读 + 点击弹 `DatePickerDialog` ⇒ 选中日落库为
//       **本地**午夜毫秒，字段回显 `YYYY-MM-DD`。
//  R2-4（第 2 条）4 个标签页仍可切换，且一次只渲染当前档位那一格。
//  R2-5（第 2 条）格内不再出现「条做法」「未落位」，key
//       `goal-blueprint-unplaced-<id>` 一并撤掉（展开前后都要断）。
//  R2-6（第 2 条）单元格上下内边距已比改造前的 4px 加大。
//
// 断言口径：一律用 `DateTime(y, m, d).millisecondsSinceEpoch`（**本地**午夜），
// 不用 UTC —— 蓝图目标的期限就是本地午夜毫秒（B11 裁决）。
//
// 判定方式：R2-1 / R2-2 / R2-3 走**真库 + 真页面**（判据回读 SQLite，不看像素）；
// R2-4 / R2-5 / R2-6 直接挂矩阵组件（不依赖页面布局，判据更确定）。
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
    show GoalHorizon, GoalKind, GoalPeriod, GoalRelation, GoalTargetType;
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
    required this.id,
    required this.title,
    required this.kind,
    required this.periodStart,
    this.keywords,
    this.domain,
    this.horizon,
    this.periodEnd,
    this.dueDate,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String kind;
  final String? keywords;
  final String? domain;
  final int? horizon;

  /// 起止（`period_start` 非空默认 0；`period_end` 可空）。
  final int periodStart;
  final int? periodEnd;
  final int? dueDate;
  final int? deletedAt;
}

const String _goalColumns =
    'id, title, kind, keywords, domain, horizon, due_date, period_start, '
    'period_end, deleted_at';

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
      .customSelect('SELECT $_goalColumns FROM goal WHERE title = \'$title\'')
      .get();
  return <_RawGoal>[for (final QueryRow r in rows) _fromRow(r.data)];
}

_RawGoal _fromRow(Map<String, Object?> d) => _RawGoal(
  id: d['id']! as String,
  title: d['title']! as String,
  kind: d['kind']! as String,
  keywords: d['keywords'] as String?,
  domain: d['domain'] as String?,
  horizon: d['horizon'] as int?,
  periodStart: (d['period_start'] as int?) ?? 0,
  periodEnd: d['period_end'] as int?,
  dueDate: d['due_date'] as int?,
  deletedAt: d['deleted_at'] as int?,
);

/// `DateTime` → `yyyy-MM-dd`（与表单 / 日期列的显示口径一致）。
String _dayLabel(DateTime d) {
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// 挂起人生蓝图页（抄 `task66_goals_blueprint_page_test.dart:111-146`）。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
  AppLanguage language = AppLanguage.zh,
  String instance = 'b12-matrix-1',
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

/// 直接挂矩阵组件（不经过页面布局；抄 `task73..._test.dart:447-474`）。
Future<void> _pumpMatrix(
  WidgetTester tester, {
  required List<GoalBlueprintRow> rows,
  required GoalServesIndex serves,
  Map<String, int> tracksCount = const <String, int>{},
}) async {
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
            rows: rows,
            serves: serves,
            tracksCount: tracksCount,
            onSplitTodos: (GoalRow _) {},
          ),
        ),
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

/// 切到某个标签页（B9-W2 之后矩阵一次只渲染一个档位）。
Future<void> _switchTab(WidgetTester tester, String horizonKey) async {
  await _tapKey(tester, ValueKey<String>('goal-blueprint-tab-$horizonKey'));
}

/// 点期限字段 ⇒ 断言弹出日期选择器 ⇒ 在本月选 [day] 日 ⇒ 确定。
///
/// 返回用户实际选中的那一天（**本地**午夜 `DateTime`）。
Future<DateTime> _pickDueDay(WidgetTester tester, int day) async {
  final DateTime now = DateTime.now();
  final DateTime picked = DateTime(now.year, now.month, day);

  await _tapKey(tester, const ValueKey<String>('goal-blueprint-form-due'));
  expect(
    find.byType(DatePickerDialog),
    findsOneWidget,
    reason: '点期限字段必须弹日期选择器（手打日期的文本框已下线）',
  );
  expect(
    find.byType(CalendarDatePicker),
    findsOneWidget,
    reason: '弹出的是可点击选择的日历体，不是空对话框',
  );

  await tester.tap(
    find
        .descendant(
          // `DatePicker` 是 Flutter 私有的 `_DatePicker`，测试里只能用公开的
          // 日历体 `CalendarDatePicker`（`DatePickerDialog` 的 body）。
          of: find.byType(CalendarDatePicker),
          matching: find.text('$day'),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'OK'));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b12-matrix-date-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('R2-1 只有 dueDate、没有起止的历史目标：第三列回退显示该期限', (
    WidgetTester tester,
  ) async {
    // 历史数据（B12 之前建的）只有 `due_date`，`period_*` 从来没人写。
    final int due = DateTime(2026, 12, 10).millisecondsSinceEpoch;
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '只有期限的旧蓝图',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      dueDate: due,
    );

    // 前提先钉死：这条目标确实没有起止 ⇒ 走的是「回退显示期限」那条分支。
    final _RawGoal? before = await _goalById(db, id);
    expect(before, isNotNull);
    expect(before!.dueDate, due, reason: '期限要按本地午夜毫秒落库');
    expect(
      before.periodStart,
      0,
      reason: '没写过起止 ⇒ period_start 必须还是 0（否则这条用例测不到回退分支）',
    );
    expect(before.periodEnd, isNull, reason: '没写过起止 ⇒ period_end 必须还是 NULL');

    await _pumpBlueprint(tester, repos: repos);

    final Finder dateText = find.byKey(
      ValueKey<String>('goal-blueprint-period-text-$id'),
    );
    expect(dateText, findsOneWidget, reason: '第三列必须给这条目标渲染日期文案');
    expect(
      tester.widget<Text>(dateText).data,
      '2026-12-10',
      reason: 'B12 第 3 条：起止缺省时第三列要回退显示 due_date，而不是「—」',
    );
    expect(
      tester.widget<Text>(dateText).data,
      isNot('—'),
      reason: '旧数据填过期限 ⇒ 第三列不许再是空白占位',
    );
  });

  testWidgets('R2-2 页面新建带期限的目标：period_end 与 due_date 同写，第三列立刻显示该日期', (
    WidgetTester tester,
  ) async {
    // 先放一条蓝图，保证页面上有正常内容（默认停在「终极」档）。
    await store.createGoal(
      kind: GoalKind.blueprint,
      title: '矩阵占位蓝图',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
    );
    await _pumpBlueprint(tester, repos: repos);

    // family × 中期 这一格是空的 ⇒ 从格子里的「+」进表单。
    await _switchTab(tester, 'mid');
    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-add-family-mid'),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      '带期限的新目标',
    );

    final DateTime picked = await _pickDueDay(tester, 15);

    // 选完日期，字段要立刻回显（用户看得见自己选了什么）。
    final TextField dueField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('goal-blueprint-form-due')),
    );
    expect(
      dueField.controller?.text,
      _dayLabel(picked),
      reason: '选完日期字段要回显 yyyy-MM-dd',
    );

    await _tapKey(tester, const ValueKey<String>('goal-blueprint-form-save'));
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-goal-saved')),
      findsOneWidget,
      reason: '写库成功要给用户可见反馈',
    );

    final List<_RawGoal> created = await _goalsByTitle(db, '带期限的新目标');
    expect(created.length, 1, reason: '保存后 SQLite 里应恰好新增一条目标');
    final _RawGoal g = created.single;
    expect(g.domain, 'family', reason: '领域 = 所在格（回读 SQLite）');
    expect(g.horizon, GoalHorizon.mid.value, reason: '档位 = 所在格（回读 SQLite）');
    expect(
      g.dueDate,
      picked.millisecondsSinceEpoch,
      reason: '期限要落库成**本地午夜毫秒**（B11 口径）',
    );
    expect(
      g.periodEnd,
      g.dueDate,
      reason:
          'B12 第 3 条的根因修复：表单写 due_date、第三列读 period_* 两侧来源不一致，'
          '页面侧必须同写 period_end',
    );
    expect(g.periodStart, 0, reason: '新建不设起始 ⇒ period_start 仍是 0');
    expect(g.deletedAt, isNull, reason: '新建不是删除');

    // 端到端第二半：这条新目标必须**当场**出现在第三列（不用重启 / 不用手动刷新）。
    await _switchTab(tester, 'mid');
    final Finder dateText = find.byKey(
      ValueKey<String>('goal-blueprint-period-text-${g.id}'),
    );
    expect(dateText, findsOneWidget, reason: '新建目标的日期格必须渲染出来');
    final String? shown = tester.widget<Text>(dateText).data;
    expect(
      shown,
      _dayLabel(picked),
      reason:
          '第三列显示的日期必须**就是**用户刚选的那一天：'
          '起止缺省 ⇒ 只显示期限本身，不该带范围/后缀（实际：$shown）',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-${g.id}')),
      findsOneWidget,
      reason: '新目标卡片也要出现在 family × 中期这一格里',
    );
  });

  testWidgets('R2-3 期限字段点开日期选择器：选中日按本地午夜毫秒落库', (
    WidgetTester tester,
  ) async {
    await _pumpBlueprint(tester, repos: repos);
    await _switchTab(tester, 'mid');
    await _tapKey(tester, const ValueKey<String>('goal-blueprint-add-social-mid'));

    final TextField emptyField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('goal-blueprint-form-due')),
    );
    expect(
      emptyField.readOnly,
      isTrue,
      reason: '期限字段必须只读（手打日期已下线，只能点选）',
    );
    expect(emptyField.controller?.text, isEmpty, reason: '新表单的期限初始为空');
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-form-due-clear')),
      findsNothing,
      reason: '还没选日期 ⇒ 不该有「清除」入口',
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      '点选期限的目标',
    );
    final DateTime picked = await _pickDueDay(tester, 15);

    // 选完之后：字段回显 + 出现「清除」入口（证明内部真的记住了所选日期）。
    final TextField filledField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('goal-blueprint-form-due')),
    );
    expect(filledField.controller?.text, _dayLabel(picked));
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-form-due-clear')),
      findsOneWidget,
      reason: '选过日期后必须有清除入口（否则用户没法把期限清空）',
    );

    await _tapKey(tester, const ValueKey<String>('goal-blueprint-form-save'));

    final List<_RawGoal> created = await _goalsByTitle(db, '点选期限的目标');
    expect(created.length, 1, reason: '保存后 SQLite 里应恰好新增一条目标');
    final _RawGoal g = created.single;
    expect(
      g.dueDate,
      DateTime(picked.year, picked.month, picked.day).millisecondsSinceEpoch,
      reason:
          '点选的日期要落库成**本地 00:00:00** 的毫秒数'
          '（不是 UTC 午夜 ⇒ 否则东八区会整体提前一天）',
    );
    // 同一条再用「日」复核一遍：毫秒口径写错（UTC  vs 本地）这里会先炸。
    expect(
      _dayLabel(DateTime.fromMillisecondsSinceEpoch(g.dueDate!)),
      _dayLabel(picked),
      reason: '回读出来的日期必须还是用户点的那一天',
    );
  });

  testWidgets('R2-4 四个标签页仍可切换：一次只渲染当前档位那一格', (
    WidgetTester tester,
  ) async {
    const Map<String, GoalHorizon> tabHorizons = <String, GoalHorizon>{
      'ultimate': GoalHorizon.ultimate,
      'long': GoalHorizon.long,
      'mid': GoalHorizon.mid,
      'short': GoalHorizon.short,
    };

    // 四档各放一条，标题互为哨兵：切到哪一页只该看到自己那一条。
    final Map<GoalHorizon, String> idOf = <GoalHorizon, String>{};
    for (final MapEntry<String, GoalHorizon> e in tabHorizons.entries) {
      idOf[e.value] = await store.createGoal(
        kind: GoalKind.blueprint,
        title: '四档样本-${e.key}',
        domain: 'career',
        horizon: e.value,
      );
    }
    final List<GoalRow> all = await store.listGoals();
    GoalRow byId(String id) => all.firstWhere((GoalRow g) => g.id == id);

    await _pumpMatrix(
      tester,
      rows: <GoalBlueprintRow>[
        GoalBlueprintRow(
          domainKey: 'career',
          cells: <GoalHorizon, List<GoalRow>>{
            for (final GoalHorizon h in tabHorizons.values)
              h: <GoalRow>[byId(idOf[h]!)],
          },
        ),
      ],
      serves: await loadGoalServesIndex(store, all),
    );

    for (final MapEntry<String, GoalHorizon> current in tabHorizons.entries) {
      await _switchTab(tester, current.key);
      expect(
        find.byKey(
          ValueKey<String>('goal-blueprint-cell-${idOf[current.value]!}'),
        ),
        findsOneWidget,
        reason: '点「${current.key}」标签后必须渲染该档位的目标（标签页没坏）',
      );
      for (final MapEntry<String, GoalHorizon> other in tabHorizons.entries) {
        if (other.key == current.key) {
          continue;
        }
        expect(
          find.byKey(ValueKey<String>('goal-blueprint-cell-${idOf[other.value]!}')),
          findsNothing,
          reason:
              'B9-W2 口径：一次只渲染一个档位 ⇒ 在「${current.key}」页'
              '不该看到「${other.key}」的目标',
        );
      }
    }
  });

  testWidgets('R2-5 格内不再出现「条做法」「未落位」，unplaced key 已撤掉', (
    WidgetTester tester,
  ) async {
    final AppLocalizations zh = AppLocalizations.zh;

    // 两条靶子：
    //  * lonely：无下级、无执行 ⇒ 旧实现在它身上会渲染「未落位」；
    //  * parent：有周目标挂在下面 + tracksCount 非空 ⇒ 旧实现会渲染「N 条做法」。
    final String lonelyId = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '没有下级的蓝图',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
    );
    final String parentId = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '有周目标的蓝图',
      keywords: '关键词样本',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
    );
    final GoalPeriod week = GoalPeriod.week(2026, 48);
    final String weeklyId = await store.createGoal(
      kind: GoalKind.weekly,
      title: '每周一次练习',
      domain: 'career',
      periodStart: week.startMillis,
      periodEnd: week.endMillis,
    );
    await store.link(
      goalId: weeklyId,
      targetType: GoalTargetType.goal,
      targetId: parentId,
      relation: GoalRelation.serves,
    );

    final List<GoalRow> all = await store.listGoals();
    GoalRow byId(String id) => all.firstWhere((GoalRow g) => g.id == id);

    await _pumpMatrix(
      tester,
      rows: <GoalBlueprintRow>[
        GoalBlueprintRow(
          domainKey: 'career',
          cells: <GoalHorizon, List<GoalRow>>{
            GoalHorizon.ultimate: <GoalRow>[byId(lonelyId), byId(parentId)],
          },
        ),
      ],
      serves: await loadGoalServesIndex(store, all),
      // 故意给非空：旧实现会把它渲染成「3 条做法」。
      tracksCount: <String, int>{parentId: 3},
    );

    // 正例控制：卡片确实渲染出来了（否则下面的「不出现」全是空断言）。
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-$lonelyId')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-$parentId')),
      findsOneWidget,
    );

    void expectNoChainText() {
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-unplaced-$lonelyId')),
        findsNothing,
        reason: 'B12 第 3 条：unplaced 标记的 key 已从实现里撤掉',
      );
      expect(
        find.byKey(ValueKey<String>('goal-blueprint-unplaced-$parentId')),
        findsNothing,
        reason: 'B12 第 3 条：有下级的也不该有 unplaced key',
      );
      expect(
        find.textContaining(zh.goalBlueprintActionsCount),
        findsNothing,
        reason: 'B12 第 3 条：目标框里不要显示「${zh.goalBlueprintActionsCount}」',
      );
      expect(
        find.textContaining(zh.goalsUnplaced),
        findsNothing,
        reason: 'B12 第 3 条：目标框里不要显示「${zh.goalsUnplaced}」',
      );
    }

    expectNoChainText();

    // 展开 parent：周目标子级必须冒出来 —— 证明 serves 索引真的有下级数据，
    // 即「不渲染未落位」不是因为没有数据可渲染。
    await _tapKey(tester, ValueKey<String>('goal-blueprint-cell-$parentId'));
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-child-$weeklyId')),
      findsOneWidget,
      reason: '展开后要看到周目标子级（正例控制：确实存在下级关系）',
    );
    // 按 key 定位到子级本身再断文案（不要用全树 `textContaining('周目标')`：
    // 本用例自己造的目标标题「有周目标的蓝图」也含这三个字，恒有 2 个匹配）。
    final Text weeklyChild = tester.widget<Text>(
      find.byKey(ValueKey<String>('goal-blueprint-child-$weeklyId')),
    );
    expect(
      weeklyChild.data,
      '${zh.goalBlueprintWeeklyTarget} 每周一次练习',
      reason: '子级文案走 t.goalBlueprintWeeklyTarget（label + 空格 + 子目标标题）',
    );

    // 展开 lonely 也不该冒出任何链路标记。
    await _tapKey(tester, ValueKey<String>('goal-blueprint-cell-$lonelyId'));
    expectNoChainText();
  });

  testWidgets('R2-6 单元格上下内边距已加大（改造前四边各 4px）', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(
      tester,
      rows: const <GoalBlueprintRow>[
        GoalBlueprintRow(domainKey: 'career', cells: <GoalHorizon, List<GoalRow>>{}),
      ],
      serves: const GoalServesIndex(
        <String, List<GoalRow>>{},
        <String, List<GoalRow>>{},
      ),
    );

    // 三列共用一个常量；逐列都断，避免「只改了其中一列」的回归。
    for (final String column in <String>['domain', 'goal', 'date']) {
      final Finder finder = find.byKey(
        ValueKey<String>('goal-blueprint-pad-$column-career'),
      );
      expect(finder, findsOneWidget, reason: '$column 列的单元格要带内边距容器');
      final EdgeInsets pad = tester
          .widget<Padding>(finder)
          .padding as EdgeInsets;
      expect(
        pad.top,
        greaterThan(4),
        reason: 'B12 第 2 条：改造前四边各 4px，上下要更大（实际 top=${pad.top}）',
      );
      expect(
        pad.bottom,
        greaterThan(4),
        reason: 'B12 第 2 条：改造前四边各 4px，上下要更大（实际 bottom=${pad.bottom}）',
      );
      expect(pad.top, pad.bottom, reason: '上下边距要对称（symmetric）');
      expect(
        pad,
        GoalBlueprintMatrix.cellPadding,
        reason: '三列必须共用 GoalBlueprintMatrix.cellPadding（单一真源）',
      );
    }

    // 常量本身的守卫：有人把 cellPadding 改回 4 ⇒ 这条必须先炸。
    expect(
      GoalBlueprintMatrix.cellPadding.vertical,
      greaterThan(4),
      reason: 'cellPadding 的垂直值必须大于改造前的 4px',
    );
    // 注意口径：`EdgeInsets.horizontal` 是**左右之和**（8 + 8 = 16），
    // 不是「每边 8」。要「每边 8」必须断 left / right 各自的值。
    expect(
      GoalBlueprintMatrix.cellPadding.left,
      8,
      reason: 'B12 只加大上下边距；水平每边保持 8px（列宽比例不变）',
    );
    expect(
      GoalBlueprintMatrix.cellPadding.right,
      8,
      reason: '水平方向左右对称，每边 8px',
    );
    expect(
      GoalBlueprintMatrix.cellPadding.horizontal,
      16,
      reason: '左右相加 = 16（钉住「每边 8」的口径，防把 horizontal 误当单边）',
    );
  });
}