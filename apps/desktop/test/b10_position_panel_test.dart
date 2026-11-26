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
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_brand_panel.dart';
import 'package:actlog/src/widgets/goals/goal_form_dialog.dart';
import 'package:actlog/src/widgets/goals/goal_split_dialog.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalHorizon, GoalKind;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
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

  // ---------------------------------------------------------------------------
  // Q 段：标签浮窗（2026-11-26 用户意见「候选标签浮窗不可点选」）
  // ---------------------------------------------------------------------------

  testWidgets('Q1 浮窗锚在输入框下方：换 hover 点位置不变、也不压住输入框', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, repos: repos);
    final Finder input = find.byKey(
      const ValueKey<String>('goal-position-input-values'),
    );
    final TestGesture gesture = await _hoverInput(tester, 'values');
    expect(find.byKey(_overlayKey), findsOneWidget);

    final Rect inputRect = tester.getRect(input);
    final Rect first = tester.getRect(find.byKey(_overlayKey));
    expect(
      first.overlaps(inputRect),
      isFalse,
      reason: '浮窗压住输入框：$first vs $inputRect',
    );
    expect(
      first.top,
      greaterThanOrEqualTo(inputRect.bottom),
      reason: '浮窗应贴在输入框下方',
    );
    expect(
      first.left,
      closeTo(inputRect.left, 0.01),
      reason: '浮窗左缘与输入框对齐',
    );

    // 同一个输入框内换另一个 hover 点 ⇒ 浮窗位置必须一模一样（不跟鼠标走）。
    final Offset center = tester.getCenter(input);
    await gesture.moveTo(center + const Offset(-60, 0));
    await tester.pump();
    await gesture.moveTo(center + const Offset(60, 0));
    await tester.pump();
    expect(
      tester.getRect(find.byKey(_overlayKey)),
      equals(first),
      reason: '浮窗不得跟随鼠标',
    );
  });

  testWidgets('Q2 指针停在浮窗上：3 秒计时暂停；离开浮窗才重新计时', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, repos: repos);
    final TestGesture gesture = await _hoverInput(tester, 'values');

    // 指针移到浮窗上 ⇒ 计时被取消，4 秒后仍在。
    await gesture.moveTo(tester.getCenter(find.byKey(_overlayKey)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_overlayKey), findsOneWidget, reason: '停在浮窗上不该消失');

    // 移出浮窗（也离开输入框）⇒ 重新起 3 秒计时，4 秒后消失。
    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(_overlayKey), findsNothing);
  });

  testWidgets('Q3 点标签：写进输入框、chip 高亮，且立即落库', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, repos: repos);
    await _hoverInput(tester, 'values');

    final String tag = AppLocalizations.zh.goalPositionValueTags.first;
    final Finder chip = find.byKey(
      const ValueKey<String>('goal-position-tag-chip-values-0'),
    );
    expect(_chipFill(tester, chip), isNull, reason: '未选中的标签不该有底色');

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-tag-values-0')),
    );
    // B12：点标签立即落库（不再有「保存」按钮）⇒ 给异步写库留一帧时间。
    await tester.pump(const Duration(milliseconds: 100));

    expect(_inputText(tester, 'values'), tag);
    final BuildContext ctx = tester.element(chip);
    expect(
      _chipFill(tester, chip),
      ctx.tokens.inkWash,
      reason: '已选中的标签要有底色高亮',
    );
    final List<GoalRow> rows = await GoalStore(
      repos,
    ).listGoals(kind: GoalKind.brand);
    expect(
      rows.map((GoalRow row) => row.title),
      contains(tag),
      reason: '点标签必须立即落库',
    );
  });

  testWidgets('Q4 点输入框：打开浮窗，钉住态 4 秒不自动消失', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, repos: repos);
    // B12：标签库没有独立开关，「点 / 聚焦输入框」就是唯一入口。
    expect(
      find.byKey(const ValueKey<String>('goal-position-tags-toggle-values')),
      findsNothing,
      reason: 'B12 已删除标签库开关',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    await tester.pump();
    expect(find.byKey(_overlayKey), findsOneWidget, reason: '点输入框应打开浮窗');

    await tester.pump(const Duration(seconds: 4));
    expect(
      find.byKey(_overlayKey),
      findsOneWidget,
      reason: '点开的浮窗是钉住态，不该自动消失',
    );
  });

  testWidgets('Q5 点浮窗外部：关闭', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    await tester.pump();
    expect(find.byKey(_overlayKey), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(find.byKey(_overlayKey), findsNothing, reason: '点外部应关闭');
  });

  testWidgets('Q6 Esc：关闭浮窗', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-position-input-values')),
    );
    await tester.pump();
    expect(find.byKey(_overlayKey), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byKey(_overlayKey), findsNothing, reason: 'Esc 应关闭浮窗');
  });

  testWidgets('Q7 换一项：旧浮层被摘掉，不叠加第二个', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    // 只用**一支**鼠标指针：flutter_test 里同 device 的第二个 PointerAddedEvent
    // 会触发框架 `mouse_tracker` 断言（Added 只能跟在 Removed 之后）。
    final TestGesture gesture = await _hoverInput(tester, 'values');
    expect(find.byKey(_overlayKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-position-tag-values-0')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byKey(_overlayKey), findsNothing);

    // 同一支指针移到另一项 ⇒ 换开新浮层，旧的不留。
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(const ValueKey<String>('goal-position-input-strengths')),
      ),
    );
    await tester.pump();
    expect(find.byKey(_overlayKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-position-tag-strengths-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-position-tag-values-0')),
      findsNothing,
      reason: '旧浮层必须被摘掉，不能叠着',
    );
  });

  // ---------------------------------------------------------------------------
  // C 段：蓝图页范围内填写框整体压缩（2026-11-26 用户意见）
  // ---------------------------------------------------------------------------

  testWidgets('C1 面板 4 个输入框压到单行高度', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    for (final String code in <String>['values', 'strengths', 'value', 'proof']) {
      final double height = tester
          .getSize(find.byKey(ValueKey<String>('goal-position-input-$code')))
          .height;
      expect(height, lessThan(60), reason: '$code 输入框太高：$height');
    }
  });

  testWidgets('C2 长文本照常换行：框被撑高、文字不溢出', (WidgetTester tester) async {
    await _pumpPanel(tester, repos: repos);
    final Finder input = find.byKey(
      const ValueKey<String>('goal-position-input-values'),
    );
    final double before = tester.getSize(input).height;
    await tester.enterText(input, '第一行\n第二行\n第三行');
    await tester.pump();
    final double after = tester.getSize(input).height;
    expect(after, greaterThan(before), reason: '多行内容应把框撑高');
    final double textHeight = tester
        .getSize(find.descendant(of: input, matching: find.byType(EditableText)))
        .height;
    expect(textHeight, lessThanOrEqualTo(after), reason: '文字不得溢出框外');
  });

  testWidgets('C3 蓝图新建目标弹窗 / 拆分弹窗：输入框都压到更矮', (
    WidgetTester tester,
  ) async {
    await _pumpDialogHost(tester);

    // 原版式（修复前）先量一次：紧凑版必须明显更矮。
    await tester.tap(
      find.byKey(const ValueKey<String>('open-form-dialog-loose')),
    );
    await tester.pumpAndSettle();
    final double looseHeight = tester
        .getSize(find.byKey(const ValueKey<String>('goal-blueprint-form-title')))
        .height;
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-cancel')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('open-form-dialog')));
    await tester.pumpAndSettle();
    final double formHeight = tester
        .getSize(find.byKey(const ValueKey<String>('goal-blueprint-form-title')))
        .height;
    expect(
      formHeight,
      lessThan(48),
      reason: '新建目标弹窗输入框太高：$formHeight',
    );
    expect(
      formHeight,
      lessThan(looseHeight - 8),
      reason: '紧凑版要比原版式矮 8px 以上：$formHeight vs $looseHeight',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-cancel')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('open-split-dialog')));
    await tester.pumpAndSettle();
    final double splitHeight = tester
        .getSize(find.byKey(const ValueKey<String>('goal-split-title-0')))
        .height;
    expect(
      splitHeight,
      lessThan(30),
      reason: '拆分弹窗输入框太高：$splitHeight',
    );
  });
}

/// chip 容器的底色（null = 没底色）。
Color? _chipFill(WidgetTester tester, Finder chip) {
  final Container box = tester.widget<Container>(chip);
  final Decoration? decoration = box.decoration;
  if (decoration is! BoxDecoration) {
    return null;
  }
  return decoration.color;
}

/// 把两个弹窗的宿主挂起来（只验「填写框多高」，不需要真库）。
Future<void> _pumpDialogHost(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Column(
            children: <Widget>[
              TextButton(
                key: const ValueKey<String>('open-form-dialog'),
                onPressed: () => showGoalFormDialog(
                  context,
                  t: AppLocalizations.zh,
                  compact: true,
                ),
                child: const Text('form'),
              ),
              TextButton(
                key: const ValueKey<String>('open-form-dialog-loose'),
                onPressed: () => showGoalFormDialog(
                  context,
                  t: AppLocalizations.zh,
                ),
                child: const Text('form-loose'),
              ),
              TextButton(
                key: const ValueKey<String>('open-split-dialog'),
                onPressed: () => showGoalSplitDialog(
                  context,
                  t: AppLocalizations.zh,
                  parentTitle: '终极目标',
                  parentHorizon: GoalHorizon.ultimate,
                ),
                child: const Text('split'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}