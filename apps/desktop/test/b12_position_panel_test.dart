// =============================================================================
// B12 · 个人定位面板：反馈 1 的六条口径（派工书 §四）
// =============================================================================
// B10 已经钉住标签浮层的细粒度语义（P1–P6），本文件只钉 **B12 新增/删除** 的东西：
//  B1 没有「保存」键、没有「标签库」开关（§四.2，key 一个都不许回流）；
//  B2 悬停分类标题 ⇒ 自绘说明浮层出现，文案就是该条 hint，且不是 `Tooltip`（§四.1）；
//  B3 说明浮层**不遮挡输入框**、也不占布局（输入框矩形悬停前后不变，§四.1）；
//  B4 指针离开标题 ⇒ 短暂延迟后说明浮层消失（§四.1）；
//  B5 聚焦输入框（不点击）⇒ 标签浮窗展开并钉住（§四.3）；
//  B6 点标签 chip ⇒ 立即并入文本**并立刻落库**（§四.4）；
//  B7 回车 ⇒ 按 `、` `，` `,` 换行 拆分、合并落库、清空输入框（§四.5）；
//  B8 空文本回车 ⇒ 一行都不写（§四.5 / §四.6）。
//
// 判据回读 SQLite（原生 `customSelect`），不看像素、不做字形断言。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_brand_panel.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 四问 code（顺序即渲染顺序）。
const List<String> _codes = <String>['values', 'strengths', 'value', 'proof'];

/// 验收键：标签浮窗根。
const ValueKey<String> _tagsKey = ValueKey<String>('goal-position-tags-overlay');

/// 验收键：自绘说明浮层根。
const ValueKey<String> _hintKey = ValueKey<String>('goal-position-hint-overlay');

/// 某个输入框当前的文本。
String _inputText(WidgetTester tester, String code) {
  final TextField field = tester.widget<TextField>(
    find.byKey(ValueKey<String>('goal-position-input-$code')),
  );
  return field.controller!.text;
}

/// 回读 `goal` 表里所有品牌行（原生列名，按 id 升序 ⇒ 顺序稳定）。
Future<List<QueryRow>> _brandRows(ActLogDatabase db) => db
    .customSelect(
      'SELECT title, kind, facet, rev, deleted_at FROM goal '
      "WHERE kind = 'brand' ORDER BY id",
    )
    .get();

/// 把面板单独挂起来（形状抄 `b10_position_panel_test.dart:49-78`）。
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
            // 顶部留白：真实页面里面板在片头带下方，标题上方有足够空间。
            // 说明浮层**只往标题上方长**（§四.1「不得遮挡输入」），需要这段空间。
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 200),
                child: GoalPositionPanel(),
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

/// 用鼠标 hover 到某个点上（返回手势以复用同一个指针）。
Future<TestGesture> _hoverAt(WidgetTester tester, Offset target) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(target);
  await tester.pump();
  return gesture;
}

/// 回车（IME 的 `done`）⇒ `TextField.onSubmitted` ⇒ 落库。
Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b12-position-panel-test');
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('B1 没有保存键、也没有标签库开关（四问逐条）', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);

    for (final String code in _codes) {
      expect(
        find.byKey(ValueKey<String>('goal-position-input-$code')),
        findsOneWidget,
        reason: '输入框必须还在：$code',
      );
      expect(
        find.byKey(ValueKey<String>('goal-position-save-$code')),
        findsNothing,
        reason: 'B12 删掉了保存键：$code',
      );
      expect(
        find.byKey(ValueKey<String>('goal-position-tags-toggle-$code')),
        findsNothing,
        reason: 'B12 删掉了标签库开关：$code',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('B2 悬停标题：自绘说明浮层出现，且不是 Tooltip', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final AppLocalizations zh = AppLocalizations.zh;
    final Finder title = find.text(zh.goalPositionValuesTitle);
    expect(title, findsOneWidget, reason: '前情：标题必须可悬停');
    // 说明文字不许常驻（§四.1）：没悬停时面板里找不到它。
    expect(find.text(zh.goalPositionValuesHint), findsNothing);

    final TestGesture gesture = await _hoverAt(tester, tester.getCenter(title));

    expect(find.byKey(_hintKey), findsOneWidget, reason: '悬停标题即出现说明浮层');
    expect(
      find.descendant(
        of: find.byKey(_hintKey),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
      reason: '§四.1：禁止用 Flutter 默认 Tooltip 组件',
    );
    expect(
      find.descendant(
        of: find.byKey(_hintKey),
        matching: find.text(zh.goalPositionValuesHint),
      ),
      findsOneWidget,
      reason: '浮层里要显示该条说明原文',
    );

    await gesture.removePointer();
  });

  testWidgets('B3 说明浮层不遮挡输入框、也不占布局', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final AppLocalizations zh = AppLocalizations.zh;
    final Finder input = find.byKey(
      const ValueKey<String>('goal-position-input-values'),
    );
    final Rect inputBefore = tester.getRect(input);

    final TestGesture gesture = await _hoverAt(
      tester,
      tester.getCenter(find.text(zh.goalPositionValuesTitle)),
    );
    expect(find.byKey(_hintKey), findsOneWidget);

    final Rect hint = tester.getRect(find.byKey(_hintKey));
    expect(
      hint.overlaps(tester.getRect(input)),
      isFalse,
      reason: '§四.1：浮层不得遮挡输入（hint=$hint）',
    );
    // 更强的一条：浮层只往标题上方长，整块都在输入框上沿之上。
    expect(
      hint.bottom,
      lessThanOrEqualTo(tester.getRect(input).top),
      reason: '§四.1：说明浮层必须落在输入框上方（hint=$hint）',
    );
    expect(
      tester.getRect(input),
      inputBefore,
      reason: '浮层是 OverlayEntry ⇒ 不许改变面板布局',
    );

    await gesture.removePointer();
  });

  testWidgets('B4 指针离开标题：短暂延迟后说明浮层消失', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final AppLocalizations zh = AppLocalizations.zh;
    final TestGesture gesture = await _hoverAt(
      tester,
      tester.getCenter(find.text(zh.goalPositionStrengthsTitle)),
    );
    expect(find.byKey(_hintKey), findsOneWidget);

    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    expect(find.byKey(_hintKey), findsOneWidget, reason: '刚离开还没到延迟时间');

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(_hintKey),
      findsNothing,
      reason: '§四.1：离开后短暂延迟即消失（不常驻）',
    );

    await gesture.removePointer();
  });

  testWidgets('B5 聚焦输入框（不点击）⇒ 标签浮窗展开并钉住', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final Finder input = find.byKey(
      const ValueKey<String>('goal-position-input-strengths'),
    );
    expect(find.byKey(_tagsKey), findsNothing, reason: '前情：初始没有浮窗');

    // 只给焦点，不点：这是 B12 新入口（旧版本靠「标签库」开关）。
    tester.widget<TextField>(input).focusNode!.requestFocus();
    // 需要两帧：首帧只把焦点变化应用下去（`requestFocus` 的生效在 microtask 里），
    // 浮层是独立 `OverlayEntry`，要等下一帧 build 才挂上 ⇒ 单帧必然找不到。
    await tester.pump();
    await tester.pump();

    expect(find.byKey(_tagsKey), findsOneWidget, reason: '§四.3：聚焦即展开');
    await tester.pump(const Duration(seconds: 4));
    expect(
      find.byKey(_tagsKey),
      findsOneWidget,
      reason: '聚焦打开 = 钉住，不许被 3s 计时关掉',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('B6 点标签 chip：立即并入文本并落库', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    await tester.pump();
    expect(find.byKey(_tagsKey), findsOneWidget);

    final String tag = AppLocalizations.zh.goalPositionValueTags.first;
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-tag-values-0')),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(_inputText(tester, 'values'), tag);
    final List<QueryRow> rows = await _brandRows(db);
    expect(rows.length, 1, reason: '§四.4：点 chip 必须立即落库，不等任何确认键');
    expect(rows.single.data['title'], tag);
    expect(rows.single.data['kind'], 'brand');
    expect(rows.single.data['facet'], 'identity');
    expect(rows.single.data['deleted_at'], isNull);
  });

  testWidgets('B7 回车：拆分多值、合并落库、清空输入框', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '自主、成长，快乐,健康',
    );
    await _submit(tester);

    expect(
      _inputText(tester, 'values'),
      isEmpty,
      reason: '§四.5：落库成功后清空输入框',
    );
    final List<QueryRow> rows = await _brandRows(db);
    expect(rows.length, 1, reason: '一次回车只写一行');
    expect(
      rows.single.data['title'],
      '自主、成长、快乐、健康',
      reason: '§四.5/§四.6：拆分后按顿号合并写库',
    );
    expect(rows.single.data['facet'], 'identity');

    // 再录一批 ⇒ 并入已有内容（不清库值），仍只有一行。
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
      '专注',
    );
    await _submit(tester);
    final List<QueryRow> again = await _brandRows(db);
    expect(again.length, 1, reason: '同一 facet 仍只有一行');
    expect(again.single.data['title'], '自主、成长、快乐、健康、专注');
  });

  testWidgets('B8 空文本回车：一行都不写', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-position-input-proof')),
      '   ',
    );
    await _submit(tester);

    expect(await _brandRows(db), isEmpty, reason: '§四.6：只有非空才写库');
    expect(_inputText(tester, 'proof').trim(), isEmpty);
  });
}