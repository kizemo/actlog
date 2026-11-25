// =============================================================================
// Task 72 · 批次 B7 · W2：上游目标右栏面板（GoalUpstreamPanel）组件级用例
// =============================================================================
// 锁住四件事：
//  1. 拖拽通道 payload 是 `'goal://' + goalId`；**非本通道一律返回 null**，
//     调用方据此原样放行（不能吞掉时间轴那条裸待办 id 的拖拽）；
//  2. 三态（空 / 加载中 / 出错）各有占位，都不把整页拖崩；
//  3. 点一条 ⇒ `onPick` 收到该条；面板自己**不写库**（派生写入在页面侧）；
//  4. 文案全部由调用方传入 ⇒ 中英两套都能落屏，面板自己不带死字。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_upstream_panel.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 造一条目标行（面板只读 title 与 id）。
GoalRow _row({
  required String id,
  required String title,
  GoalKind kind = GoalKind.yearly,
}) => GoalRow(
  id: id,
  kind: kind,
  title: title,
  status: GoalStatus.active,
  periodStart: 0,
  createdAt: 0,
  updatedAt: 0,
);

/// 挂起一块面板（自带 MaterialApp，面板不需要 l10n 容器：文案是入参）。
Future<void> _pumpPanel(WidgetTester tester, Widget panel) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(body: SingleChildScrollView(child: panel)),
    ),
  );
  await tester.pump();
}

void main() {
  group('拖拽通道 payload（W2/W3 共用约定）', () {
    test('前缀逐字是 goal://，拼装函数按约定拼接', () {
      expect(goalDragPayloadPrefix, 'goal://');
      expect(goalDragPayloadFor('g1'), 'goal://g1');
      expect(goalDragPayloadFor('a-b-c'), 'goal://a-b-c');
    });

    test('取 id：能还原，含连字符的 id 不截断', () {
      expect(goalIdFromDragPayload('goal://g1'), 'g1');
      expect(goalIdFromDragPayload(goalDragPayloadFor('a-b-c')), 'a-b-c');
    });

    test('非本通道返回 null（调用方原样放行，不吞别人的拖拽）', () {
      // 时间轴那条通道是裸待办 id，绝不能被我方接收。
      expect(goalIdFromDragPayload('todo-42'), isNull);
      expect(goalIdFromDragPayload(''), isNull);
      // 只有前缀、没有 id ⇒ 等同无效。
      expect(goalIdFromDragPayload('goal://'), isNull);
      expect(goalIdFromDragPayload(null), isNull);
      expect(goalIdFromDragPayload(42), isNull);
    });
  });

  testWidgets('有上游目标时逐条渲染，点一条回调收到该条', (WidgetTester tester) async {
    final AppLocalizations t = AppLocalizations.zh;
    final GoalRow first = _row(id: 'y1', title: '年度主攻');
    final GoalRow second = _row(id: 'y2', title: '年度副线');
    final List<GoalRow> picked = <GoalRow>[];

    await _pumpPanel(
      tester,
      GoalUpstreamPanel(
        kind: GoalKind.yearly,
        title: t.goalsUpstreamYearTitle,
        hint: t.goalsUpstreamAddHint,
        emptyText: t.goalsUpstreamEmpty,
        goals: <GoalRow>[first, second],
        onPick: picked.add,
      ),
    );

    expect(
      find.byKey(GoalUpstreamPanel.panelKey(GoalKind.yearly)),
      findsOneWidget,
    );
    expect(find.text(t.goalsUpstreamYearTitle), findsOneWidget);
    expect(find.text(t.goalsUpstreamAddHint), findsOneWidget);
    expect(
      find.byKey(GoalUpstreamPanel.itemKey(GoalKind.yearly, 'y1')),
      findsOneWidget,
    );
    expect(
      find.byKey(GoalUpstreamPanel.itemKey(GoalKind.yearly, 'y2')),
      findsOneWidget,
    );
    // 有条目时不能再同时显示空态。
    expect(
      find.byKey(const ValueKey<String>('goal-upstream-empty-yearly')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(GoalUpstreamPanel.itemKey(GoalKind.yearly, 'y1')),
    );
    await tester.pump();

    expect(picked.length, 1);
    expect(picked.single.id, 'y1');
    expect(picked.single.title, '年度主攻');
  });

  testWidgets('空态：只留空提示，不渲染条目', (WidgetTester tester) async {
    final AppLocalizations t = AppLocalizations.zh;

    await _pumpPanel(
      tester,
      GoalUpstreamPanel(
        kind: GoalKind.monthly,
        title: t.goalsUpstreamMonthTitle,
        hint: t.goalsUpstreamAddHint,
        emptyText: t.goalsUpstreamEmpty,
        goals: const <GoalRow>[],
        onPick: (GoalRow _) {},
      ),
    );

    final Finder empty = find.byKey(
      const ValueKey<String>('goal-upstream-empty-monthly'),
    );
    expect(empty, findsOneWidget);
    expect(tester.widget<Text>(empty).data, t.goalsUpstreamEmpty);
  });

  testWidgets('加载中：画转圈占位，不画空态（避免被误读成「上游没有目标」）', (
    WidgetTester tester,
  ) async {
    final AppLocalizations t = AppLocalizations.zh;

    await _pumpPanel(
      tester,
      GoalUpstreamPanel(
        kind: GoalKind.weekly,
        title: t.goalsUpstreamWeekTitle,
        hint: t.goalsUpstreamAddHint,
        emptyText: t.goalsUpstreamEmpty,
        goals: const <GoalRow>[],
        onPick: (GoalRow _) {},
        loading: true,
      ),
    );

    // 转圈是无限动画 ⇒ 这里只用 pump（不能用 pumpAndSettle）。
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('goal-upstream-empty-weekly')),
      findsNothing,
    );
  });

  testWidgets('出错：显示错误文案，列表不渲染', (WidgetTester tester) async {
    final AppLocalizations t = AppLocalizations.zh;

    await _pumpPanel(
      tester,
      GoalUpstreamPanel(
        kind: GoalKind.yearly,
        title: t.goalsUpstreamYearTitle,
        hint: t.goalsUpstreamAddHint,
        emptyText: t.goalsUpstreamEmpty,
        goals: <GoalRow>[_row(id: 'y1', title: '年度主攻')],
        onPick: (GoalRow _) {},
        errorText: t.operationFailed,
      ),
    );

    final Finder error = find.byKey(
      const ValueKey<String>('goal-upstream-error-yearly'),
    );
    expect(error, findsOneWidget);
    expect(tester.widget<Text>(error).data, t.operationFailed);
    // 读失败时列表可能是残缺的 ⇒ 宁可只报错，不给出像「就这些」的假象。
    expect(
      find.byKey(GoalUpstreamPanel.itemKey(GoalKind.yearly, 'y1')),
      findsNothing,
    );
  });

  testWidgets('英文态：三处文案都来自 en 文案表', (WidgetTester tester) async {
    final AppLocalizations en = AppLocalizations.en;

    await _pumpPanel(
      tester,
      GoalUpstreamPanel(
        kind: GoalKind.yearly,
        title: en.goalsUpstreamYearTitle,
        hint: en.goalsUpstreamAddHint,
        emptyText: en.goalsUpstreamEmpty,
        goals: const <GoalRow>[],
        onPick: (GoalRow _) {},
      ),
    );

    expect(find.text(en.goalsUpstreamYearTitle), findsOneWidget);
    expect(find.text(en.goalsUpstreamAddHint), findsOneWidget);
    expect(find.text(en.goalsUpstreamEmpty), findsOneWidget);
  });

  test('六个上游文案 getter 中英都非空（本棒只消费，不许自补文案）', () {
    for (final AppLocalizations t in <AppLocalizations>[
      AppLocalizations.zh,
      AppLocalizations.en,
    ]) {
      expect(t.goalsUpstreamYearTitle, isNotEmpty);
      expect(t.goalsUpstreamMonthTitle, isNotEmpty);
      expect(t.goalsUpstreamWeekTitle, isNotEmpty);
      expect(t.goalsUpstreamAddHint, isNotEmpty);
      expect(t.goalsUpstreamEmpty, isNotEmpty);
      expect(t.goalsUpstreamAddMenu, isNotEmpty);
    }
  });
}