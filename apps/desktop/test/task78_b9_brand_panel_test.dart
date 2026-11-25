// =============================================================================
// Task 78 · B9-W1：蓝图页「个人品牌管理」面板
// =============================================================================
// 钉住派工书（docs\b91-dispatch-w1.md）的口径：
//  T1 面板渲染在人生蓝图矩阵块**上方**，蓝图页既有三块照旧；
//  T2 左侧 10 个切面齐备，默认选中 audience（派工书 §3.4-1）；
//  T3 点切面导航 ⇒ 编辑区跟随该切面（ValueKey 带切面码）；
//  T4 保存落库：`kind='brand'`、`facet='audience'`、`rev=1`、`deleted_at` 为空（R5 证据）；
//  T5 同一面再保存走 `updateGoal`：仍只有一行、`facet` 不被改掉、`rev` 递增到 2；
//  T6 标题留空点保存 ⇒ 一行都不写（派工书 §3.3「空内容不写行」）；
//  T7 库里已有品牌行 ⇒ 切到该面时输入框回填（读到的是库里的值）。
//
// 判据一律回读 SQLite（原生 SQL `customSelect`），不看像素、不做字形断言。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalFacet, GoalKind;
// `QueryRow` 是 `customSelect` 的行类型，drift 从 2.x 起只在 drift.dart 导出。
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 切面顺序（派工书 §3.4-1 逐字，也是导航渲染顺序）。
const List<String> _facetCodes = <String>[
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
];

/// 回读 `goal` 表里所有品牌行（原生列名，按 id 升序 ⇒ 顺序稳定）。
Future<List<QueryRow>> _brandRows(ActLogDatabase db) => db
    .customSelect(
      'SELECT title, kind, note, facet, rev, deleted_at FROM goal '
      "WHERE kind = 'brand' ORDER BY id",
    )
    .get();

/// 挂起人生蓝图页（形状抄 `task73_b8_w1_blueprint_edit_test.dart:156-191`）。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
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
            currentPreferencesProvider.overrideWithValue(AppPreferences.defaults),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(
                key: const ValueKey<String>('bp-brand'),
              ),
            ),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 滚到某个 key 上并点它（页面在长表格里，不 ensureVisible 点不到）。
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
    repos = ActLogRepositories(db, deviceId: 'task78-brand-panel-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('T1 品牌面板渲染在人生蓝图矩阵块上方', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    final Finder panel = find.byKey(
      const ValueKey<String>('goal-brand-panel'),
    );
    expect(panel, findsOneWidget);

    // 位置判据：面板顶边必须在矩阵顶边之上（矩阵块本身仍在页内）。
    final double panelTop = tester.getTopLeft(panel).dy;
    final double matrixTop = tester.getTopLeft(
      find.byType(GoalBlueprintMatrix),
    ).dy;
    expect(panelTop, lessThan(matrixTop));
  });

  testWidgets('T2 十个切面导航齐备，默认选中 audience', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    for (final String code in _facetCodes) {
      expect(
        find.byKey(ValueKey<String>('goal-brand-facet-$code')),
        findsOneWidget,
        reason: '切面导航缺 $code',
      );
    }
    // 默认切面 = audience：编辑区的三个 ValueKey 都带 audience。
    expect(
      find.byKey(const ValueKey<String>('goal-brand-title-audience')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-brand-note-audience')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-brand-save-audience')),
      findsOneWidget,
    );
  });

  testWidgets('T3 点切面导航后编辑区跟随该切面', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    await _tapKey(tester, const ValueKey<String>('goal-brand-facet-word'));

    expect(
      find.byKey(const ValueKey<String>('goal-brand-title-word')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-brand-save-word')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-brand-title-audience')),
      findsNothing,
    );
  });

  testWidgets('T4 保存写入 goal 行：kind=brand / facet=audience / rev=1 / 软删为空',
      (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-brand-title-audience')),
      '刚开业半年、靠一份外卖撑生意的小微餐饮店主',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-brand-note-audience')),
      '先写给他看，他决定别人怎么介绍我',
    );
    await _tapKey(tester, const ValueKey<String>('goal-brand-save-audience'));

    // 保存成功反馈在场。
    expect(
      find.byKey(const ValueKey<String>('goal-brand-saved')),
      findsOneWidget,
    );

    // 判据打到运行时产物：直接读 SQLite 的 goal 行。
    final List<QueryRow> rows = await _brandRows(db);
    expect(rows, hasLength(1));
    final Map<String, Object?> row = rows.first.data;
    expect(row['kind'], 'brand');
    expect(row['facet'], 'audience');
    expect(row['title'], '刚开业半年、靠一份外卖撑生意的小微餐饮店主');
    expect(row['note'], '先写给他看，他决定别人怎么介绍我');
    expect(row['rev'], 1);
    expect(row['deleted_at'], isNull);
  });

  testWidgets('T5 同一面再保存：仍一行、facet 不变、rev 递增到 2',
      (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-brand-title-audience')),
      '第一版受众',
    );
    await _tapKey(tester, const ValueKey<String>('goal-brand-save-audience'));

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-brand-title-audience')),
      '第二版受众',
    );
    await _tapKey(tester, const ValueKey<String>('goal-brand-save-audience'));

    final List<QueryRow> rows = await _brandRows(db);
    expect(rows, hasLength(1), reason: '每切面最多一行');
    final Map<String, Object?> row = rows.first.data;
    expect(row['title'], '第二版受众');
    expect(row['facet'], 'audience', reason: 'updateGoal 不传 facet ⇒ 不被改掉');
    expect(row['rev'], 2, reason: '第二版走 updateGoal，rev 递增');
    expect(row['deleted_at'], isNull);
  });

  testWidgets('T6 标题留空点保存：一行都不写', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    await _tapKey(tester, const ValueKey<String>('goal-brand-save-audience'));

    expect(await _brandRows(db), isEmpty);
    expect(
      find.byKey(const ValueKey<String>('goal-brand-saved')),
      findsNothing,
      reason: '没写库就不该报「已保存」',
    );
  });

  testWidgets('T7 库里已有品牌行时输入框回填', (WidgetTester tester) async {
    await store.createGoal(
      kind: GoalKind.brand,
      facet: GoalFacet.identity,
      title: '回填校验用的身份声明标题',
    );
    await _pumpBlueprint(tester, repos: repos);

    await _tapKey(tester, const ValueKey<String>('goal-brand-facet-identity'));

    expect(find.text('回填校验用的身份声明标题'), findsOneWidget);
  });
}