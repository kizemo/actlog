// apps/desktop/test/task72_w3_week_goal_rail_panel_test.dart
//
// Task 72 / B7 需求 4 第一条通道 → B8-W3 撤回写入：今日右栏第 5 面板
// 「未完成周目标」已退化为**只读展示**（用户裁决「保留只读展示」，
// 见 `docs/b8-scope-decision.md` U1）。点击 / 拖拽两条写入口全部撤掉。
//
// 盯四件事：
//   1. 空态不造假：没有未完成周目标时只出空态文案，且旧的
//      「点击或拖拽添加到当前周期」提示已随写入口一起撤掉；
//   2. 只列**未完成周**目标：已完成（`status == done`）与非周粒度（`monthly`）都不出现，
//      且条目不再是拖拽源；
//   3. 点击条目**零写入**：不建计划行、不建 `goal_link`、不弹任何确认框；
//   4. 只读结构守卫：面板里既没有 `Draggable`（拖拽源）也没有 `InkWell`（点击），
//      条目仍是「最多两行 + 省略号」的纯文本。
//
// 全部走真库 + 真 provider（不 mock）：第 3 条要证明「读库之后什么都没写」，
// 只有真仓储才能给出这个证据。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/week_goal_rail_panel.dart';

import 'l10n_harness.dart';

/// 固定「今天」与选中日：只读面板不该再读它们写库，但壳依赖仍在。
const String _today = '2026-11-09';
const String _selected = '2026-11-09';

const ValueKey<String> _kHint = ValueKey<String>('week-goal-add-hint');
const ValueKey<String> _kEmpty = ValueKey<String>('week-goal-empty');

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos, this.goals);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final GoalStore goals;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(db, deviceId: 'w3-rail');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _selected),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos, GoalStore(repos));
  }

  /// 只挂面板本体（宽 260，与右轨同宽），不挂整壳。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      l10nScope(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 260, child: WeekGoalRailPanel()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（`weekOpenGoalsProvider` 是 `FutureProvider`）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  final AppLocalizations zh = AppLocalizations.zh;

  testWidgets('B8/W3：没有未完成周目标时只有空态，没有添加提示也没有可拖条目', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kEmpty), findsOneWidget);
    expect(find.text(zh.goalsUpstreamEmpty), findsOneWidget);
    // 写入口撤掉后，这条提示（「点击或拖拽添加到当前周期」）不许再留在今日页。
    expect(find.byKey(_kHint), findsNothing);
    expect(find.text(zh.goalsUpstreamAddHint), findsNothing);
    expect(find.byType(Draggable<String>), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：只列未完成**周**目标，且条目不再是拖拽源', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String openId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '把周报告写完',
    );
    await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '上周已经收尾的事',
      status: GoalStatus.done,
    );
    await h.goals.createGoal(kind: GoalKind.monthly, title: '月目标不该出现在这里');

    await h.mount(tester);
    await _settle(tester);

    expect(find.byKey(_kEmpty), findsNothing);
    expect(find.byKey(ValueKey<String>('week-goal-$openId')), findsOneWidget);
    expect(find.text('把周报告写完'), findsOneWidget);
    expect(find.text('上周已经收尾的事'), findsNothing);
    expect(find.text('月目标不该出现在这里'), findsNothing);
    // B8/W3：条目只剩展示，`goal://<id>` 这个 payload 不再由今日页产出。
    expect(find.byType(Draggable<String>), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：点击条目零写入——不建计划行、不建目标关联、不弹确认框', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '复盘 B7',
      note: '把三条通道都跑一遍',
    );

    await h.mount(tester);
    await _settle(tester);

    final Finder tile = find.byKey(ValueKey<String>('week-goal-$goalId'));
    expect(tile, findsOneWidget);
    // 用 `tapAt` 而不是 `tap`：要的就是「真指针按在条目位置上」也不该发生任何事，
    // 而不是断言某个手势回调存在。
    await tester.tapAt(tester.getCenter(tile));
    await _settle(tester);

    expect(
      await h.repos.planItem.listByDate(_selected),
      isEmpty,
      reason: '只读面板点一下不许落计划行',
    );
    expect(
      await h.goals.listLinks(goalId),
      isEmpty,
      reason: '也不许写 goal_link（点一次一条都没有）',
    );
    expect(find.byType(AlertDialog), findsNothing, reason: '点击不再弹任何浮层');
    expect(
      find.byType(Draggable<String>),
      findsNothing,
      reason: '点击也不该顺手把条目变成拖拽源',
    );

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：只读结构守卫——面板内无可点 / 可拖控件，条目是两行省略纯文本', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '只读展示这条',
    );
    await h.goals.createGoal(kind: GoalKind.weekly, title: '第二条也要列出来');

    await h.mount(tester);
    await _settle(tester);

    final Finder panel = find.byType(WeekGoalRailPanel);
    expect(
      find.descendant(of: panel, matching: find.byType(InkWell)),
      findsNothing,
      reason: '点击写入口已撤：面板里不许再有 InkWell',
    );
    expect(
      find.descendant(of: panel, matching: find.byType(Draggable<String>)),
      findsNothing,
      reason: '拖拽写入口已撤：面板里不许再有 Draggable',
    );
    // 两条都要列出来（不是只剩一条），说明只读列表本身还完整。
    expect(find.byKey(ValueKey<String>('week-goal-$goalId')), findsOneWidget);
    expect(find.text('第二条也要列出来'), findsOneWidget);

    final Text title = tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>('week-goal-$goalId')),
        matching: find.byType(Text),
      ),
    );
    expect(title.data, '只读展示这条');
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);

    await _flushTimers(tester);
  });
}