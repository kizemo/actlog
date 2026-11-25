// =============================================================================
// B7 / W1 · 人生蓝图页作为**独立页面**的口径（D-72-b）
// =============================================================================
// 蓝图原先挂在目标页第 4 页签，B7 起升级为第 7 个导航项（`blueprint`、
// `Ctrl+7`、深链 `/blueprint`）。「独立成页」有三条可编译、可断言的硬证据：
//  1. 页面**自带标题**，不再借目标页的 `AppBar`/页签栏；
//  2. 标题 key 固定为 `blueprint-title`，文案随语言切换；
//  3. 页面接受 `period` 注入（测试可钉周期，不依赖「今天」）。
// 本文件只钉「独立成页」的可见契约；矩阵/待办/平衡轮的内容口径在
// `task66_goals_blueprint_page_test.dart` 守。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart' show GoalPeriod;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 标题 key（页面自带，不从外部注入）。
const ValueKey<String> _titleKey = ValueKey<String>('blueprint-title');

/// 挂起人生蓝图页：注入固定周期，避免依赖「今天」。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
  AppLanguage language = AppLanguage.zh,
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
              child: GoalsBlueprintPage(period: GoalPeriod.year(2026)),
            ),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b7-blueprint-page-test');
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('蓝图页自带标题：中文显示「蓝图」', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos);

    expect(find.byKey(_titleKey), findsOneWidget, reason: '蓝图页必须有自带标题');
    expect(
      tester.widget<Text>(find.byKey(_titleKey)).data,
      AppLocalizations.zh.shellNavBlueprint,
      reason: '中文标题取 shellNavBlueprint',
    );
    expect(AppLocalizations.zh.shellNavBlueprint, '蓝图');
    expect(tester.takeException(), isNull);
  });

  testWidgets('蓝图页自带标题：英文显示 Blueprint', (WidgetTester tester) async {
    await _pumpBlueprint(tester, repos: repos, language: AppLanguage.en);

    expect(find.byKey(_titleKey), findsOneWidget, reason: '蓝图页必须有自带标题');
    expect(
      tester.widget<Text>(find.byKey(_titleKey)).data,
      AppLocalizations.en.shellNavBlueprint,
      reason: '英文标题取 shellNavBlueprint',
    );
    expect(AppLocalizations.en.shellNavBlueprint, 'Blueprint');
    expect(tester.takeException(), isNull);
  });
}