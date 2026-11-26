// =============================================================================
// B10-D1 棒 A · 个人定位面板：标签浮层细粒度用例
// =============================================================================
// 派工书 §3.2 / §3.3 里靠肉眼看不出的语义，集中钉在这里：
//  P1 空框点标签 ⇒ 框内就是该标签（不带多余分隔符）；
//  P2 已有内容点标签 ⇒ 先补「、」再追加；
//  P3 同一标签点两次 ⇒ 不重复追加；
//  P4 鼠标移进浮层 ⇒ 3 秒计时被取消（4 秒后仍在）；移出 ⇒ 重新计时（4 秒后消失）；
//  P5 反复 hover ⇒ 始终只有一个 OverlayEntry（不叠加）。
//
// 面板自己取数（`listGoals`），所以这里照旧接**真库**（内存 drift）。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_brand_panel.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 验收键：浮层根。
const ValueKey<String> _overlayKey = ValueKey<String>(
  'goal-position-tags-overlay',
);

/// 某个输入框当前的文本。
String _inputText(WidgetTester tester, String code) {
  final TextField field = tester.widget<TextField>(
    find.byKey(ValueKey<String>('goal-position-input-$code')),
  );
  return field.controller!.text;
}

/// 把面板单独挂起来（不带蓝图页，聚焦浮层行为）。
Future<void> _pumpPanel(
  WidgetTester tester, {
  required ActLogRepositories repos,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
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
          child: const Scaffold(
            body: SingleChildScrollView(child: GoalPositionPanel()),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 用鼠标 hover 某个输入框（触发 `onEnter` ⇒ 开浮层），返回手势以复用指针。
Future<TestGesture> _hoverInput(WidgetTester tester, String code) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(
    tester.getCenter(find.byKey(ValueKey<String>('goal-position-input-$code'))),
  );
  await tester.pump();
  return gesture;
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b10-position-panel-test');
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('P1 空框点标签：框内就是该标签', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await _hoverInput(tester, 'values');
    expect(find.byKey(_overlayKey), findsOneWidget);

    final List<String> tags = AppLocalizations.zh.goalPositionValueTags;
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-tag-values-4')),
    );
    await tester.pump();

    expect(_inputText(tester, 'values'), tags[4]);
  });

  testWidgets('P2 已有内容点标签：先补「、」再追加', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '已经写下的内容',
    );
    await _hoverInput(tester, 'values');

    final String tag = AppLocalizations.zh.goalPositionValueTags.first;
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-tag-values-0')),
    );
    await tester.pump();

    expect(_inputText(tester, 'values'), '已经写下的内容、$tag');
  });

  testWidgets('P3 同一标签点两次：不重复追加', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await _hoverInput(tester, 'strengths');

    final Finder chip = find.byKey(
      const ValueKey<String>('goal-position-tag-strengths-0'),
    );
    final String tag = AppLocalizations.zh.goalPositionStrengthTags.first;
    await tester.tap(chip);
    await tester.pump();
    expect(_inputText(tester, 'strengths'), tag);

    await tester.tap(chip);
    await tester.pump();
    expect(_inputText(tester, 'strengths'), tag, reason: '同标签不重复');
  });

  testWidgets('P4 移进浮层取消计时，移出重新计时', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final TestGesture gesture = await _hoverInput(tester, 'values');
    expect(find.byKey(_overlayKey), findsOneWidget);

    // 指针移到浮层上 ⇒ 计时取消，4 秒后仍在。
    await gesture.moveTo(tester.getCenter(find.byKey(_overlayKey)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_overlayKey), findsOneWidget, reason: '停在浮层上不该消失');

    // 移出浮层（也离开输入框）⇒ 重新起 3 秒计时，4 秒后消失。
    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_overlayKey), findsNothing);
  });

  testWidgets('P5 反复 hover：只存在一个浮层', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final TestGesture gesture = await _hoverInput(tester, 'values');
    expect(find.byKey(_overlayKey), findsOneWidget);

    final Offset center = tester.getCenter(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    await gesture.moveTo(center + const Offset(6, 6));
    await tester.pump();
    await gesture.moveTo(center + const Offset(-6, -6));
    await tester.pump();

    expect(find.byKey(_overlayKey), findsOneWidget, reason: '不得叠加第二个浮层');
  });
}