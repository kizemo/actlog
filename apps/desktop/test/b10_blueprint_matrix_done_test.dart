// =============================================================================
// B10 · 棒 B：蓝图矩阵增强（标签页激活态 / 时长提示 / 完成勾选 / 日期列）
// =============================================================================
// 钉住派工书 §4 的四条口径：
//  B-1 标签页激活态**不只靠字重**：激活 = `tokens.inkWash` 浅洗底 pill +
//      `tokens.ink` + `FontWeight.w600`；未激活 = 无底色 + `tokens.meta`。
//  B-2 四档标签页都用 `Tooltip` 挂时长（60 岁以后 / 约 10 年 / 约 5 年 / 约 3 年）。
//  B-3 每行目标一个 `Checkbox`（`goal-blueprint-done-<id>`），勾选只写
//      `updateGoal(status:)`；`archived_at` 由 `GoalStore` **内部派生**
//      （done ⇒ 首次完成时刻，非 done ⇒ NULL），页面不直接碰这一列。
//      不传 `onToggleGoalDone` ⇒ 勾选框一个都不渲染（坑 48）。
//  B-4 表格 3 列，日期列 `yyyy-MM-dd ~ yyyy-MM-dd`（无起始整体 `—`），
//      已完成追加 `完成：yyyy-MM-dd`；改期按钮只在传了 `onEditGoalPeriod` 时渲染。
//
// 判据：库里真实行的 `status` / `archived_at` + 矩阵渲染出的键与文本。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/theme/theme_tokens.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalHorizon, GoalKind, GoalStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 2026-01-01T00:00:00Z（UTC 毫秒；日期列按 UTC 格式化）。
final int _start2026 = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;

/// 2026-12-31T00:00:00Z。
final int _end2026 = DateTime.utc(2026, 12, 31).millisecondsSinceEpoch;

/// 固定视口：矩阵在长表格里，默认 800×600 会溢出/点不到。
void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 直接挂矩阵本体（不经过页面，验证渲染门槛与样式）。
Widget _host(
  List<GoalBlueprintRow> rows,
  GoalServesIndex serves, {
  void Function(GoalRow goal, bool done)? onToggleGoalDone,
  void Function(GoalRow goal, int startMs, int? endMs)? onEditGoalPeriod,
}) {
  return MaterialApp(
    theme: AppTheme.light(DensityProfile.comfortable),
    home: Scaffold(
      body: SingleChildScrollView(
        child: GoalBlueprintMatrix(
          t: AppLocalizations.zh,
          rows: rows,
          serves: serves,
          tracksCount: const <String, int>{},
          onSplitTodos: (GoalRow _) {},
          onToggleGoalDone: onToggleGoalDone,
          onEditGoalPeriod: onEditGoalPeriod,
        ),
      ),
    ),
  );
}

/// 一条 career × 终极档的矩阵行。
GoalBlueprintRow _careerRow(List<GoalRow> goals) => GoalBlueprintRow(
  domainKey: 'career',
  cells: <GoalHorizon, List<GoalRow>>{GoalHorizon.ultimate: goals},
);

/// 按 id 取库里那一行（真表回读，不看 UI）。
Future<GoalRow> _row(GoalStore store, String id) async {
  final List<GoalRow> all = await store.listGoals();
  return all.firstWhere((GoalRow g) => g.id == id);
}

/// 挂起人生蓝图页（抄 `task73_b8_w1_blueprint_edit_test.dart:154-189`）。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
}) async {
  _size(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(AppPreferences.defaults),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalsBlueprintPage()),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 滚到 key 上再点（长表格里不 ensureVisible 点不到）。
Future<void> _tapKey(WidgetTester tester, Key key) async {
  final Finder target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// `yyyy-MM-dd`（直接取该 `DateTime` 自己的年月日，不做任何时区换算）。
String _ymd(DateTime moment) =>
    '${moment.year}-'
    '${moment.month.toString().padLeft(2, '0')}-'
    '${moment.day.toString().padLeft(2, '0')}';

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b10-b-blueprint-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('B3 归档时刻由 status 派生：done ⇒ 落值且重复勾不改写，取消 ⇒ 清回 NULL', () async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '写一本书',
      horizon: GoalHorizon.ultimate,
      periodStart: _start2026,
      periodEnd: _end2026,
    );

    GoalRow row = await _row(store, id);
    expect(row.status, GoalStatus.active);
    expect(row.archivedAt, isNull, reason: '新建即 active，不许带归档时刻');

    await store.updateGoal(id, status: GoalStatus.done);
    row = await _row(store, id);
    expect(row.status, GoalStatus.done);
    expect(row.archivedAt, isNotNull, reason: 'done ⇒ archived_at 必须落值');
    final int firstDone = row.archivedAt!;

    // 重复勾（已是 done 再写 done）不许把「首次完成时刻」刷成 now。
    await store.updateGoal(id, status: GoalStatus.done);
    row = await _row(store, id);
    expect(row.archivedAt, firstDone, reason: '完成时刻只认第一次');

    await store.updateGoal(id, status: GoalStatus.active);
    row = await _row(store, id);
    expect(row.status, GoalStatus.active);
    expect(row.archivedAt, isNull, reason: '取消完成 ⇒ 归档时刻必须清回 NULL');
  });

  testWidgets('B3 页面勾选：勾上写 done + archived_at，取消写回 active 且清空', (
    WidgetTester tester,
  ) async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '跑完半马',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
    );
    await _pumpBlueprint(tester, repos: repos);

    final ValueKey<String> box = ValueKey<String>('goal-blueprint-done-$id');
    expect(find.byKey(box), findsOneWidget, reason: '页面必须传 onToggleGoalDone');

    await _tapKey(tester, box);
    GoalRow row = await _row(store, id);
    expect(row.status, GoalStatus.done, reason: '勾选 = updateGoal(status: done)');
    expect(row.archivedAt, isNotNull);

    await _tapKey(tester, box);
    row = await _row(store, id);
    expect(row.status, GoalStatus.active, reason: '取消 = 写回 active');
    expect(row.archivedAt, isNull);
  });

  testWidgets('B4 日期列：起止日期 / 缺起始的「—」/ 已完成追加完成日', (
    WidgetTester tester,
  ) async {
    final String dated = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '有起止的目标',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      periodStart: _start2026,
      periodEnd: _end2026,
    );
    final String undated = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '没起止的目标',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
    );
    await store.updateGoal(dated, status: GoalStatus.done);

    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    final Map<String, GoalRow> byId = <String, GoalRow>{
      for (final GoalRow goal in all) goal.id: goal,
    };

    int? tappedStart;
    int? tappedEnd;
    _size(tester);
    await tester.pumpWidget(
      _host(
        <GoalBlueprintRow>[_careerRow(<GoalRow>[byId[dated]!, byId[undated]!])],
        serves,
        onToggleGoalDone: (GoalRow _, bool _) {},
        onEditGoalPeriod: (GoalRow _, int startMs, int? endMs) {
          tappedStart = startMs;
          tappedEnd = endMs;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(ValueKey<String>('goal-blueprint-period-text-$dated')),
          )
          .data,
      '2026-01-01 ~ 2026-12-31',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(ValueKey<String>('goal-blueprint-period-text-$undated')),
          )
          .data,
      '—',
      reason: 'periodStart == 0 ⇒ 整体「—」，不拼半截日期',
    );

    final String doneOn = tester
        .widget<Text>(
          find.byKey(ValueKey<String>('goal-blueprint-done-on-$dated')),
        )
        .data!;
    expect(doneOn, matches(RegExp(r'^完成：\d{4}-\d{2}-\d{2}$')));
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-done-on-$undated')),
      findsNothing,
      reason: '未完成的目标不追加完成日',
    );

    // 改期按钮带出的是这一行目标的既有起止。
    await _tapKey(
      tester,
      ValueKey<String>('goal-blueprint-period-$dated'),
    );
    expect(tappedStart, _start2026);
    expect(tappedEnd, _end2026);
  });

  testWidgets('B1 标签页激活态：inkWash 浅洗底 pill + ink/w600；未激活无底色 + meta', (
    WidgetTester tester,
  ) async {
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    _size(tester);
    await tester.pumpWidget(_host(<GoalBlueprintRow>[], serves));
    await tester.pumpAndSettle();

    final ThemeTokens tokens = tester
        .element(find.byType(GoalBlueprintMatrix))
        .tokens;

    TextButton tabOf(String key) => tester.widget<TextButton>(
      find.byKey(ValueKey<String>('goal-blueprint-tab-$key')),
    );
    Text labelOf(String key) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>('goal-blueprint-tab-$key')),
        matching: find.byType(Text),
      ),
    );

    // 默认选中「终极」。
    expect(
      tabOf('ultimate').style?.backgroundColor?.resolve(const <WidgetState>{}),
      tokens.inkWash,
      reason: '激活页签必须有浅洗底（B-1：不只靠字重）',
    );
    expect(labelOf('ultimate').style?.color, tokens.ink);
    expect(labelOf('ultimate').style?.fontWeight, FontWeight.w600);
    expect(
      tabOf('short').style?.backgroundColor?.resolve(const <WidgetState>{}),
      isNull,
      reason: '未激活页签不铺底色',
    );
    expect(labelOf('short').style?.color, tokens.meta);

    // 切到「中期」后，激活态跟着走（不是写死在第一个）。
    await _tapKey(tester, const ValueKey<String>('goal-blueprint-tab-mid'));
    expect(
      tabOf('mid').style?.backgroundColor?.resolve(const <WidgetState>{}),
      tokens.inkWash,
    );
    expect(
      tabOf('ultimate').style?.backgroundColor?.resolve(const <WidgetState>{}),
      isNull,
    );
    expect(labelOf('mid').style?.fontWeight, FontWeight.w600);
    expect(labelOf('ultimate').style?.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('B2 四档标签页悬停时长：四条 tooltip 都在', (WidgetTester tester) async {
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    _size(tester);
    await tester.pumpWidget(_host(<GoalBlueprintRow>[], serves));
    await tester.pumpAndSettle();

    final AppLocalizations zh = AppLocalizations.zh;
    for (final String span in <String>[
      zh.goalBlueprintHorizonUltimateSpan,
      zh.goalBlueprintHorizonLongSpan,
      zh.goalBlueprintHorizonMidSpan,
      zh.goalBlueprintHorizonShortSpan,
    ]) {
      expect(find.byTooltip(span), findsOneWidget, reason: '缺时长提示：$span');
    }
    expect(zh.goalBlueprintHorizonUltimateSpan, '60 岁以后');
    expect(zh.goalBlueprintHorizonLongSpan, '约 10 年内');
    expect(zh.goalBlueprintHorizonMidSpan, '约 5 年内');
    expect(zh.goalBlueprintHorizonShortSpan, '约 3 年内');
  });

  testWidgets('B3/B4 不传两个新回调 ⇒ 勾选框与改期按钮一个都不渲染（坑 48）', (
    WidgetTester tester,
  ) async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: '不传回调也要能看',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      periodStart: _start2026,
    );
    final List<GoalRow> all = await store.listGoals();
    final GoalServesIndex serves = await loadGoalServesIndex(store, all);
    final GoalRow row = all.firstWhere((GoalRow g) => g.id == id);

    _size(tester);
    await tester.pumpWidget(_host(<GoalBlueprintRow>[_careerRow(<GoalRow>[row])], serves));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey<String>('goal-blueprint-cell-$id')),
      findsOneWidget,
      reason: '既有内容一字不变',
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-done-$id')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-period-$id')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey<String>('goal-blueprint-period-text-$id')),
      findsOneWidget,
      reason: '日期是只读列，不依赖回调',
    );
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('B4 完成日按本地时区：「完成：」用时刻口径，起止日期仍走 UTC', (
    WidgetTester tester,
  ) async {
    // `archivedAt` 存的是 `updateGoal` 里 `DateTime.now()` 的**时刻**，不是 UTC 午夜的
    // 「日期」⇒ 必须按本地年月日显示（按 UTC 会在东八区 00:00–08:00 少一天）。
    // 断言值全部在运行时算出来，不硬编码任何日期串，因此在任意时区都成立。
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // 判别行：扫一小段候选时刻，挑一个「本地日 ≠ UTC 日」的（纯运行时算，不写死日期）。
    // 零偏移时区（UTC）扫不到 ⇒ 跳过判别行，now 那一条仍然成立。
    int? edgeMs;
    for (int hour = 0; hour < 48 && edgeMs == null; hour++) {
      final int probe =
          DateTime.utc(2026, 6, 15).millisecondsSinceEpoch + hour * 3600000;
      final DateTime probeLocal = DateTime.fromMillisecondsSinceEpoch(probe);
      if (_ymd(probeLocal) != _ymd(probeLocal.toUtc())) {
        edgeMs = probe;
      }
    }

    GoalRow doneRow(String id, int archivedAt) => GoalRow(
      id: id,
      kind: GoalKind.blueprint,
      title: '刚完成的目标',
      status: GoalStatus.done,
      periodStart: _start2026,
      periodEnd: _end2026,
      archivedAt: archivedAt,
      createdAt: archivedAt,
      updatedAt: archivedAt,
    );

    final GoalRow doneNow = doneRow('b10-done-now', nowMs);
    final GoalRow? doneEdge = edgeMs == null
        ? null
        : doneRow('b10-done-edge', edgeMs);

    final GoalServesIndex serves = await loadGoalServesIndex(
      store,
      const <GoalRow>[],
    );
    _size(tester);
    await tester.pumpWidget(
      _host(
        <GoalBlueprintRow>[
          _careerRow(<GoalRow>[doneNow, ?doneEdge]),
        ],
        serves,
        onToggleGoalDone: (GoalRow _, bool _) {},
      ),
    );
    await tester.pumpAndSettle();

    String textOf(String key) =>
        tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;
    final String prefix = AppLocalizations.zh.goalBlueprintDonePrefix;

    // 日期型字段不动：起止仍然按 UTC 午夜毫秒显示。
    expect(
      textOf('goal-blueprint-period-text-b10-done-now'),
      '2026-01-01 ~ 2026-12-31',
    );

    // 时刻型字段：显示「now 那一刻」的本地年月日（与本条 now 同一时刻，跨零点也不闪）。
    expect(
      textOf('goal-blueprint-done-on-b10-done-now'),
      '$prefix${_ymd(DateTime.fromMillisecondsSinceEpoch(nowMs))}',
      reason: 'archivedAt 必须按本地时区显示完成日',
    );

    if (doneEdge != null) {
      final DateTime edgeLocal = DateTime.fromMillisecondsSinceEpoch(edgeMs!);
      final String edgeLocalDay = _ymd(edgeLocal);
      final String edgeUtcDay = _ymd(edgeLocal.toUtc());
      expect(
        edgeLocalDay,
        isNot(edgeUtcDay),
        reason: '候选点必须真的跨本地/UTC 日界，否则这条判别无效',
      );
      expect(
        textOf('goal-blueprint-done-on-b10-done-edge'),
        '$prefix$edgeLocalDay',
        reason: '若误用 isUtc: true，这里会显示 $edgeUtcDay',
      );
    }
  });
}