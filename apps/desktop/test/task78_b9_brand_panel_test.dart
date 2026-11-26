// =============================================================================
// Task 78 · 蓝图页顶部面板（B9-W1 个人品牌管理 → B10-D1 个人定位）
// =============================================================================
// 文件名保留（派工书 §3.5），内容整篇改写为新面板口径：
//  T1 面板渲染在人生蓝图矩阵块**上方**；
//  T2 四项问答齐备（values / strengths / value / proof），各有输入框、**没有保存键**；
//  T3 回车落库：`kind='brand'`、`facet='identity'`、`rev=1`、`deleted_at` 为空；
//  T4 同一项再次回车走 `updateGoal`：仍只有一行、`facet` 不被改掉、`rev` 递增到 2；
//  T5 空文本回车 ⇒ 一行都不写（派工书 §3.1「空文本不写行」）；
//  T6 库里已有该切面的行 ⇒ 输入框回填（读到的是库里的值）；
//  T7 悬停价值观输入框 ⇒ 标签浮层出现、2 秒仍在、4 秒消失；点标签填入输入框。
//
// B12 口径（派工书 §四）：面板上没有「保存」按钮、也没有「标签库」开关，
// 落库只走输入框回车（IME 的 `done`）；标签库由点 / 聚焦输入框打开。
//
// 判据一律回读 SQLite（原生 SQL `customSelect`），不看像素、不做字形断言。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalFacet, GoalKind;
// `QueryRow` 是 `customSelect` 的行类型，drift 从 2.x 起只在 drift.dart 导出。
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 四项的 code（派工书 §3.1 逐字，也是渲染顺序）。
const List<String> _codes = <String>['values', 'strengths', 'value', 'proof'];

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
                key: const ValueKey<String>('bp-position'),
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

/// 回车（IME 的 `done`）⇒ `TextField.onSubmitted` ⇒ 落库。
///
/// B12 删掉了「保存」按钮：面板上落库只剩这一条路（派工书 §四）。
Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// 某个输入框当前的文本。
String _inputText(WidgetTester tester, String code) {
  final TextField field = tester.widget<TextField>(
    find.byKey(ValueKey<String>('goal-position-input-$code')),
  );
  return field.controller!.text;
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task78-position-panel-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('T1 个人定位面板渲染在人生蓝图矩阵块上方', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    final Finder panel = find.byKey(
      const ValueKey<String>('goal-position-panel'),
    );
    final Finder matrixTab = find.byKey(
      const ValueKey<String>('goal-blueprint-tab-ultimate'),
    );
    expect(panel, findsOneWidget);
    expect(matrixTab, findsOneWidget, reason: '矩阵仍在页面里');
    expect(
      tester.getBottomLeft(panel).dy,
      lessThanOrEqualTo(tester.getTopLeft(matrixTab).dy),
      reason: '面板必须在矩阵上方',
    );
  });

  testWidgets('T2 四项问答齐备（输入框 + 标题，且没有保存键）', (
    WidgetTester tester,
  ) async {
    await _pumpBlueprint(tester, repos: repos);
    final AppLocalizations zh = AppLocalizations.zh;

    for (final String code in _codes) {
      expect(
        find.byKey(ValueKey<String>('goal-position-input-$code')),
        findsOneWidget,
        reason: '缺输入框 $code',
      );
      expect(
        find.byKey(ValueKey<String>('goal-position-save-$code')),
        findsNothing,
        reason: 'B12 起面板上不许再有保存键 $code',
      );
    }
    expect(find.text(zh.goalPositionSection), findsOneWidget);
    expect(find.text(zh.goalPositionValuesTitle), findsOneWidget);
    expect(find.text(zh.goalPositionStrengthsTitle), findsOneWidget);
    expect(find.text(zh.goalPositionValueTitle), findsOneWidget);
    expect(find.text(zh.goalPositionProofTitle), findsOneWidget);
  });

  testWidgets('T3 回车落库：kind=brand、facet=identity、rev=1', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '自主、成长',
    );
    await _submit(tester);

    final List<QueryRow> rows = await _brandRows(db);
    expect(rows.length, 1);
    expect(rows.single.data['kind'], 'brand');
    expect(rows.single.data['facet'], 'identity');
    expect(rows.single.data['title'], '自主、成长');
    expect(rows.single.data['rev'], 1);
    expect(rows.single.data['deleted_at'], isNull);
    expect(
      find.byKey(const ValueKey<String>('goal-position-saved')),
      findsOneWidget,
    );
  });

  testWidgets('T4 同一项再次回车：并入（不是覆盖）、仍一行、facet 不变、rev 递增到 2', (
    WidgetTester tester,
  ) async {
    await _pumpBlueprint(tester, repos: repos);

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '第一版',
    );
    await _submit(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '第二版',
    );
    await _submit(tester);

    final List<QueryRow> rows = await _brandRows(db);
    expect(rows.length, 1, reason: '同一切面只该有一行');
    expect(rows.single.data['facet'], 'identity');
    // B12 已裁决的产品语义：回车 = **并入**（`_mergedTags` 取「库值 ∪ 输入框」并按
    // `、` 连接），不是「整值覆盖」。旧断言写 '第二版'，与实现语义相反。
    expect(rows.single.data['title'], '第一版、第二版');
    expect(rows.single.data['rev'], 2);

    // 同值再回车：并集去重 ⇒ 不重复追加、也不多出一行。
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '第二版',
    );
    await _submit(tester);
    final List<QueryRow> again = await _brandRows(db);
    expect(again.length, 1, reason: '同一切面仍只有一行');
    expect(
      again.single.data['title'],
      '第一版、第二版',
      reason: '重复标签只保留一份（_mergedTags 去重）',
    );
  });

  testWidgets('T5 空文本回车：一行都不写', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-strengths')),
      '   ',
    );
    await _submit(tester);

    expect(await _brandRows(db), isEmpty);
  });

  testWidgets('T6 库里已有该切面的行 ⇒ 输入框回填', (WidgetTester tester) async {
    await store.createGoal(
      kind: GoalKind.brand,
      facet: GoalFacet.identity,
      title: '库里已有的价值观',
    );

    await _pumpBlueprint(tester, repos: repos);

    expect(_inputText(tester, 'values'), '库里已有的价值观');
    expect(_inputText(tester, 'proof'), isEmpty);
  });

  testWidgets('T7 悬停出现标签浮层：离开后 2 秒仍在、4 秒消失、点标签填入', (
    WidgetTester tester,
  ) async {
    await _pumpBlueprint(tester, repos: repos);
    final Finder overlay = find.byKey(
      const ValueKey<String>('goal-position-tags-overlay'),
    );
    final Finder input = find.byKey(
      const ValueKey<String>('goal-position-input-values'),
    );

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(input));
    await tester.pump();
    expect(overlay, findsOneWidget, reason: '悬停即出现');

    await tester.pump(const Duration(seconds: 4));
    expect(overlay, findsOneWidget, reason: '鼠标还在输入框内 ⇒ 不计时，不消失');

    // 指针离开输入框 ⇒ 才起 3 秒计时（浮层自己也跟着消失）。
    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    expect(overlay, findsOneWidget, reason: '刚离开时还没到 3 秒');

    await tester.pump(const Duration(seconds: 2));
    expect(overlay, findsOneWidget, reason: '2 秒时还没到 3 秒');

    await tester.pump(const Duration(seconds: 4));
    expect(overlay, findsNothing, reason: '超过 3 秒要消失');

    // 指针移回输入框 ⇒ 重新 onEnter，浮层再出现。
    await gesture.moveTo(tester.getCenter(input));
    await tester.pump();
    expect(overlay, findsOneWidget);

    final String firstTag = AppLocalizations.zh.goalPositionValueTags.first;
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-tag-values-0')),
    );
    await tester.pump();
    expect(_inputText(tester, 'values'), firstTag);
  });
}