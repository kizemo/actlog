// apps/desktop/test/task72_w3_day_goal_menu_test.dart
//
// Task 72 / B7 需求 4 第二、三条通道 → B8-W3 撤回：今日页「未完成周目标」的
// 写入口全部撤掉（用户裁决「保留只读展示」，见 `docs/b8-scope-decision.md` U1）。
//
// 盯四件事：
//   1. 右键菜单只剩「手填 / 待办 / 习惯」三组 + 取消：第 4 组「未完成周目标」
//      连同 `slot-menu-goals` 整体消失，勾选浮层也不再有入口；
//   2. 待办 / 习惯两组的空池占位仍在（`slot-menu-todo-*` / `slot-menu-habit-*`
//      的正常路径由 `timeline_day_grid_test.dart:253-268` 守，本份只守不回归）；
//   3. 外部把 `goal://<goalId>` 拖进日格 ⇒ 零写入、不弹起止框
//      （今日页不再消费该协议）；
//   4. 「手填」通道原样可走（选组 → 起止 → 标题 → 落库）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/goal_upstream_panel.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_context_menu.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/week_goal_rail_panel.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';
const String _selected = '2026-11-09';

const ValueKey<String> _kGrid = ValueKey<String>('day-grid');
const ValueKey<String> _kMenuManual = ValueKey<String>('slot-menu-manual');
const ValueKey<String> _kMenuGoals = ValueKey<String>('slot-menu-goals');
const ValueKey<String> _kMenuCancel = ValueKey<String>('slot-menu-cancel');
const ValueKey<String> _kRangeConfirm = ValueKey<String>('slot-range-confirm');
const ValueKey<String> _kTitleField = ValueKey<String>('slot-title-field');
const ValueKey<String> _kTitleConfirm = ValueKey<String>('slot-title-confirm');
const ValueKey<String> _kDragSource = ValueKey<String>('w3-drag-source');

final class _Harness {
  _Harness._(this.container, this.repos, this.goals);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final GoalStore goals;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(db, deviceId: 'w3-menu');
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

  /// 网格 + 右栏「未完成周目标」面板（今日页的真实布局）。
  ///
  /// [overlay] 用来挂一个**外部**拖拽源：今日页自己已经不再产出
  /// `goal://<id>` payload，要验证「不再消费」只能从外面喂给它。
  Future<void> mount(WidgetTester tester, {Widget? overlay}) {
    return tester.pumpWidget(
      l10nScope(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: DayGrid(date: _selected)),
                      const SizedBox(
                        width: 240,
                        child: WeekGoalRailPanel(),
                      ),
                    ],
                  ),
                  if (overlay != null)
                    Positioned(left: 4, top: 4, child: overlay),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 弹层路由切换：先起一帧，再给转场 250ms。
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Offset _gridPointFor(WidgetTester tester, int minute) {
  final Rect grid = tester.getRect(find.byKey(_kGrid));
  final double dy = (minute - kGridStartHour * 60) / 60 * kHourRowHeight;
  return Offset(grid.left + grid.width / 2, grid.top + dy + 1);
}

Future<void> _rightClick(WidgetTester tester, Offset point) async {
  final TestGesture gesture = await tester.startGesture(
    point,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pump();
}

/// 把 [from] 上的可拖控件拖到 [to]：多步移动，让 `DragTarget` 有机会接住。
Future<void> _dragTo(WidgetTester tester, Offset from, Offset to) async {
  final TestGesture gesture = await tester.startGesture(from);
  await tester.pump();
  await gesture.moveTo(Offset.lerp(from, to, 0.4)!);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveTo(Offset.lerp(from, to, 0.8)!);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveTo(to);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.up();
}

void main() {
  final AppLocalizations zh = AppLocalizations.zh;

  testWidgets('B8/W3：右键菜单不再有「未完成周目标」组，手填组仍在', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.goals.createGoal(kind: GoalKind.weekly, title: '周目标甲');

    await h.mount(tester);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 600));
    await _pumpDialog(tester);

    expect(find.byKey(_kMenuManual), findsOneWidget, reason: '既有「手填」组不许消失');
    expect(find.byKey(_kMenuGoals), findsNothing, reason: '第 4 组目标组已整体撤掉');
    expect(
      find.descendant(
        of: find.byType(SlotContextMenu),
        matching: find.text(zh.goalsUpstreamWeekTitle),
      ),
      findsNothing,
      reason: '菜单里连「未完成周目标」这个组标题都不该再出现',
    );
    // 勾选浮层已随目标组一起删掉，没有任何入口能再弹出它。
    expect(find.byType(AlertDialog), findsOneWidget, reason: '此刻只有右键菜单本身');
    expect(find.byKey(_kRangeConfirm), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：菜单仍是「手填 / 待办 / 习惯」三组，取消能关', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 600));
    await _pumpDialog(tester);

    final Finder menu = find.byType(SlotContextMenu);
    expect(menu, findsOneWidget);
    expect(
      find.descendant(of: menu, matching: find.byKey(_kMenuManual)),
      findsOneWidget,
      reason: '手填组必须原样保留',
    );
    // 空池：两组各出空态占位，说明待办 / 习惯两条分支都还在。
    expect(
      find.descendant(of: menu, matching: find.text(zh.timelineTodoGroup)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: menu, matching: find.text(zh.timelineHabitGroup)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: menu, matching: find.text(zh.timelineTodoPoolEmpty)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: menu, matching: find.text(zh.timelineHabitEmpty)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: menu, matching: find.byKey(_kMenuCancel)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(_kMenuCancel));
    await _pumpDialog(tester);
    expect(find.byType(SlotContextMenu), findsNothing, reason: '取消要能关掉菜单');
    expect(await h.repos.planItem.listByDate(_selected), isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：外部拖入 goal://payload ⇒ 零写入、不弹起止框', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    final String goalId = await h.goals.createGoal(
      kind: GoalKind.weekly,
      title: '拖进来的周目标',
    );

    await h.mount(
      tester,
      overlay: Draggable<String>(
        data: goalDragPayloadFor(goalId),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: const SizedBox(width: 40, height: 16),
        child: const SizedBox(
          key: _kDragSource,
          width: 80,
          height: 20,
        ),
      ),
    );
    await _settle(tester);

    final Draggable<String> source = tester.widget<Draggable<String>>(
      find.ancestor(
        of: find.byKey(_kDragSource),
        matching: find.byType(Draggable<String>),
      ),
    );
    expect(
      source.data,
      goalDragPayloadFor(goalId),
      reason: '前提：外部源喂的确实是旧协议 payload',
    );
    expect(source.data, 'goal://$goalId');

    await _dragTo(
      tester,
      tester.getCenter(find.byKey(_kDragSource)),
      _gridPointFor(tester, 720),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(_kRangeConfirm),
      findsNothing,
      reason: '今日页不再接 goal:// 拖拽，不该弹起止框',
    );
    expect(await h.repos.planItem.listByDate(_selected), isEmpty);
    expect(await h.goals.listLinks(goalId), isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('B8/W3：既有「手填」通道不回归（选组 → 起止 → 标题 → 落库）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 780));
    await _pumpDialog(tester);
    await tester.tap(find.byKey(_kMenuManual));
    await _pumpDialog(tester);
    await tester.tap(find.byKey(_kRangeConfirm));
    await _pumpDialog(tester);
    expect(find.byKey(_kTitleField), findsOneWidget);
    await tester.enterText(find.byKey(_kTitleField), '手写一条');
    await tester.tap(find.byKey(_kTitleConfirm));
    await _settle(tester);

    final List<PlanItemData> rows = await h.repos.planItem.listByDate(_selected);
    expect(rows, hasLength(1));
    expect(rows.single.title, '手写一条');

    await _flushTimers(tester);
  });
}