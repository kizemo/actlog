// apps/desktop/test/timeline_day_grid_test.dart
//
// B2 方格时间轴 · 交互层（真库 + 真 provider，不 mock）。
//
// 盯三件事（对应独立复核的三条 FAIL）：
//   1. 需求 5「回填默认打勾」：落进已经过去的时段，计划行直接是 `done`，
//      复选框呈现已勾选；未来日仍 `pending`（FAIL-1）。
//   2. 需求 4「习惯拖入须弹起止弹窗」：取消 ⇒ 一行都不落库；确认 ⇒ 用弹窗里
//      的结束时间，而不是写死的 30 分钟（FAIL-2）。
//   3. 需求 3「右键三级菜单」：手填 / 待办 / 习惯三组都在，已排期待办不再
//      出现在子菜单里。
//
// 为什么回填用「过去日」而不是「今天」：`DayGrid` 在 `date == todayIso` 时用
// 真实 `DateTime.now()` 算 `nowMinute`，拿「今天」构造回填，结论就取决于跑测试
// 的时刻（凌晨跑必绿、白天跑必红）。过去日 / 未来日与时刻无关。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:actlog/src/widgets/timeline/todo_rail_panel.dart';

/// 固定「今天」，与被测日期分开，才能确定性地构造回填 / 未来。
const String _today = '2026-11-09';

/// 过去日：整日都算回填。
const String _past = '2026-11-08';

/// 未来日：全不算回填。
const String _future = '2026-11-10';

const ValueKey<String> _kGrid = ValueKey<String>('day-grid');
const ValueKey<String> _kMenuManual = ValueKey<String>('slot-menu-manual');
const ValueKey<String> _kMenuCancel = ValueKey<String>('slot-menu-cancel');
const ValueKey<String> _kRangeStart = ValueKey<String>('slot-range-start');
const ValueKey<String> _kRangeCancel = ValueKey<String>('slot-range-cancel');
const ValueKey<String> _kRangeConfirm = ValueKey<String>('slot-range-confirm');
const ValueKey<String> _kTitleField = ValueKey<String>('slot-title-field');
const ValueKey<String> _kTitleConfirm = ValueKey<String>('slot-title-confirm');

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  /// [selected] 必须与 `DayGrid` 的 `date` 相同：`planItemsProvider` 跟着选中日
  /// 走，两者错开的话网格拿到的会是另一天的行。
  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'day-grid-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 网格 + 右轨的两个拖拽源。右轨不是装饰：`todoPoolProvider` /
  /// `habitsForTodayProvider` 只有被 watch 过才会是 `asData`，否则右键菜单会把
  /// 它们当空列表。
  ///
  /// 面板顺序与 `app.dart:259 todayRailPanels` 一致（待办列表 → 习惯速览）：
  /// Task 34 把右轨的「拖入时间轴」合并模块拆成两块，习惯拖拽源已从
  /// `TodoRailPanel` 搬到 `HabitOverviewPanel`（key `overview-habit-<id>`、
  /// payload `habit:<id>`）。只挂 `TodoRailPanel` 会让三条习惯用例当场找不到
  /// 拖拽源，`slot-menu-habit-<id>` 也会因为没人 watch 而消失。
  Future<void> mount(WidgetTester tester, String date) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: DayGrid(date: date)),
                SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      TodoRailPanel(),
                      SizedBox(height: 12),
                      HabitOverviewPanel(),
                    ],
                  ),
                ),
              ],
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

/// 等真库流回来。
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

/// 网格里 [minute] 那一格的全局坐标（纵向 +1 躲开格线）。
Offset _gridPointFor(WidgetTester tester, int minute) {
  final Rect grid = tester.getRect(find.byKey(_kGrid));
  final double dy = (minute - kGridStartHour * 60) / 60 * kHourRowHeight;
  return Offset(grid.left + grid.width / 2, grid.top + dy + 1);
}

/// 右键：苦主是 `onSecondaryTapDown`，必须真的带次要键按下去。
Future<void> _rightClick(WidgetTester tester, Offset point) async {
  final TestGesture gesture = await tester.startGesture(
    point,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pump();
}

/// 从右轨条目拖到网格上 [minute] 处。
Future<void> _dragRailToGrid(
  WidgetTester tester, {
  required String railKey,
  required int minute,
}) async {
  final Offset from = tester.getCenter(find.byKey(ValueKey<String>(railKey)));
  final Offset to = _gridPointFor(tester, minute);
  final TestGesture gesture = await tester.startGesture(from);
  await tester.pump();
  await gesture.moveTo(Offset.lerp(from, to, 0.4)!);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveTo(Offset.lerp(from, to, 0.8)!);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveTo(to);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.up();
  await tester.pump();
  await _settle(tester);
}

/// 某条目里的复选框当前值（`LedgerCheckbox` 无 key 参数化，只能按条目壳定位）。
bool _checkboxValue(WidgetTester tester, String planItemId) {
  final Finder box = find.descendant(
    of: find.byKey(ValueKey<String>('day-grid-entry-$planItemId')),
    matching: find.byType(LedgerCheckbox),
  );
  return tester.widget<LedgerCheckbox>(box).value;
}

Future<PlanItemData> _onlyPlan(
  WidgetTester tester,
  _Harness harness,
  String date,
) async {
  final List<PlanItemData> plans = (await tester.runAsync(
    () => harness.repos.planItem.listByDate(date),
  ))!;
  expect(plans, hasLength(1));
  return plans.single;
}

/// 走真仓储落一条「已排期」计划（待办 + 计划行一起建），不碰任何界面。
///
/// 删除确认用例要的是一条**点得开任务详情窗**的条目。Task 45 · W6 起未来日
/// 也能开详情窗（编辑 / 删除不再被拦），这里仍用当天 —— 那里删除路径同时
/// 覆盖「当天可完成」的语义，未来日的删除另有专门用例。
Future<void> _seedPlan(
  _Harness harness, {
  required String date,
  required String title,
  required int startMinute,
}) async {
  await TimelineStore(harness.repos).createTodoWithSlot(
    date: date,
    title: title,
    startMinute: startMinute,
    endMinute: startMinute + 15,
  );
}

void main() {
  testWidgets('右键菜单三级齐备，且已排期的待办不再出现在子菜单里', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);

    // 一条已排期（不该再出现）、一条未排期（该出现）。
    // `createTodoWithSlot` 返回的是**待办** id，计划行是它顺手建的那条。
    final String slottedId = await TimelineStore(harness.repos)
        .createTodoWithSlot(
          date: _today,
          title: '已排期',
          startMinute: 9 * 60,
          endMinute: 9 * 60 + 15,
        );
    final String freeId = await harness.repos.todo.create(title: '未排期');
    final String habitId = await harness.repos.habit.create(
      name: '晨间拉伸',
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );

    await harness.mount(tester, _today);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 11 * 60));
    await _settle(tester);

    expect(find.byKey(_kMenuManual), findsOneWidget);
    expect(find.byKey(_kMenuCancel), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('slot-menu-todo-$freeId')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('slot-menu-habit-$habitId')),
      findsOneWidget,
    );
    // 已排期的那条被菜单内部按 `slottedTodoIds` 二次过滤掉。
    expect(
      find.byKey(ValueKey<String>('slot-menu-todo-$slottedId')),
      findsNothing,
    );

    await tester.tap(find.byKey(_kMenuCancel));
    await _settle(tester);
    expect(find.byKey(_kMenuManual), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('过去日手填 ⇒ 默认打勾（回填），done_at 一并落库', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _past);
    await harness.mount(tester, _past);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 10 * 60));
    await _settle(tester);
    await tester.tap(find.byKey(_kMenuManual));
    await _settle(tester);

    expect(find.byKey(_kRangeStart), findsOneWidget);
    await tester.tap(find.byKey(_kRangeConfirm));
    await _settle(tester);

    await tester.enterText(find.byKey(_kTitleField), '补记：写周报');
    await tester.tap(find.byKey(_kTitleConfirm));
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _past);
    expect(plan.plannedStart, 10 * 60);
    expect(plan.status, 'done');
    expect(plan.doneAt, isNotNull);

    // 界面层同一条事实：条目里的复选框是勾上的。
    expect(_checkboxValue(tester, plan.id), isTrue);

    await _flushTimers(tester);
  });

  testWidgets('未来日手填 ⇒ 保持 pending，复选框不勾', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    await harness.mount(tester, _future);
    await _settle(tester);

    await _rightClick(tester, _gridPointFor(tester, 10 * 60));
    await _settle(tester);
    await tester.tap(find.byKey(_kMenuManual));
    await _settle(tester);
    await tester.tap(find.byKey(_kRangeConfirm));
    await _settle(tester);
    await tester.enterText(find.byKey(_kTitleField), '预排：评审');
    await tester.tap(find.byKey(_kTitleConfirm));
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _future);
    expect(plan.status, 'pending');
    expect(plan.doneAt, isNull);
    expect(_checkboxValue(tester, plan.id), isFalse);

    await _flushTimers(tester);
  });

  testWidgets('习惯拖入必须弹起止弹窗；取消 ⇒ 一行都不落库', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    final String habitId = await harness.repos.habit.create(
      name: '晨间拉伸',
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
    await harness.mount(tester, _today);
    await _settle(tester);

    await _dragRailToGrid(
      tester,
      railKey: 'overview-habit-$habitId',
      minute: 10 * 60,
    );

    // 旧实现直接以固定 30 分钟落库，这里一格弹窗都看不到 —— 这条是 FAIL-2 的判据。
    expect(find.byKey(_kRangeStart), findsOneWidget);
    expect(find.byKey(ValueKey<String>('slot-range-end')), findsOneWidget);

    await tester.tap(find.byKey(_kRangeCancel));
    await _settle(tester);

    expect(
      await tester.runAsync(() => harness.repos.planItem.listByDate(_today)),
      isEmpty,
    );
    expect(find.byKey(_kRangeStart), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('习惯拖入确认后用弹窗里的结束时间（不是写死的 30 分钟）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    final String habitId = await harness.repos.habit.create(
      name: '晨间拉伸',
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
    await harness.mount(tester, _today);
    await _settle(tester);

    await _dragRailToGrid(
      tester,
      railKey: 'overview-habit-$habitId',
      minute: 10 * 60,
    );
    expect(find.byKey(_kRangeStart), findsOneWidget);

    // 默认一格（10:00–10:15），再加两格 ⇒ 10:45。
    await tester.tap(find.byTooltip('结束 加一格'));
    await tester.pump();
    await tester.tap(find.byTooltip('结束 加一格'));
    await tester.pump();
    await tester.tap(find.byKey(_kRangeConfirm));
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _today);
    expect(plan.title, '晨间拉伸');
    expect(plan.isHabitRef, 1);
    expect(plan.plannedStart, 10 * 60);
    // 写死 30 分钟的实现会得到 630；这里必须是弹窗给的 645。
    expect(plan.plannedEnd, 10 * 60 + 45);
    expect(plan.status, 'done');

    await _flushTimers(tester);
  });

  testWidgets('待办入格到过去时段同样默认打勾（createFromTodo 复用同一判据）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _past);
    await harness.repos.todo.create(title: '补记的待办');
    final open = (await tester.runAsync(() => harness.repos.todo.listOpen()))!;

    await tester.runAsync(
      () => TimelineStore(harness.repos).createFromTodo(
        date: _past,
        todo: open.single,
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
        todayIso: _today,
        nowMinute: 0,
      ),
    );

    final PlanItemData plan = await _onlyPlan(tester, harness, _past);
    expect(plan.status, 'done');
    expect(plan.doneAt, isNotNull);
  });

  // ===========================================================================
  // Task 29 · 四态冗余通道（形状 + 文字 + 删除线 + 左缘 2px 竖条）
  // ===========================================================================
  // 为什么四态要分四条用例而不是一条：每条都钉死「该态 → 该字形 / 该前景色」，
  // 映射互换（例如 done 与 backfill 张冠李戴）只会让其中一条红，
  // 定位成本最低。数据全部用 `todayIso` / `nowMinute` 显式注入，不读真实时钟。

  testWidgets('plannedOpen 态：○ + 「计划」，无删除线，左缘竖条 2px 主墨色', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    final String id = (await tester.runAsync(
      () => TimelineStore(harness.repos).createManual(
        date: _future,
        title: '预排：评审',
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
        todayIso: _today,
        nowMinute: 0,
      ),
    ))!;

    await harness.mount(tester, _future);
    await _settle(tester);

    _expectDualChannel(
      tester,
      planItemId: id,
      kind: SlotKind.plannedOpen,
      title: '预排：评审',
      glyph: '\u25CB',
    );
    // 反向对照：未完成态**不**划线，防止「到处都划线」也判绿。
    expect(_titleStyle(tester, id, '预排：评审').decoration, isNull);

    await _flushTimers(tester);
  });

  testWidgets('done 态：✓ + 「完成」，标题删除线，左缘竖条用完成态前景色', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _future);
    final String id = (await tester.runAsync(
      () => TimelineStore(harness.repos).createManual(
        date: _future,
        title: '已完成：写周报',
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
        todayIso: _today,
        nowMinute: 0,
      ),
    ))!;
    // 未来日 ⇒ 不算回填，所以置 done 得到的是 `SlotKind.done`（不是 backfill）。
    await tester.runAsync(
      () => harness.repos.planItem.setStatus(id, PlanStatus.done),
    );

    await harness.mount(tester, _future);
    await _settle(tester);

    _expectDualChannel(
      tester,
      planItemId: id,
      kind: SlotKind.done,
      title: '已完成：写周报',
      glyph: '\u2713',
    );
    final TextStyle titleStyle = _titleStyle(tester, id, '已完成：写周报');
    expect(titleStyle.decoration, isNotNull);
    expect(titleStyle.decoration!.contains(TextDecoration.lineThrough), isTrue);
    // 删除线颜色显式指定为该态前景色，不随 `color` 继承出别的色。
    expect(titleStyle.decorationColor, foregroundOfSlotKind(SlotKind.done, ThemeTokens.light));

    await _flushTimers(tester);
  });

  testWidgets('backfill 态：▶ + 「回填」，左缘竖条用回填态前景色', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _past);
    final String id = (await tester.runAsync(
      () => TimelineStore(harness.repos).createManual(
        date: _past,
        title: '补记：排障',
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
        todayIso: _today,
        nowMinute: 0,
      ),
    ))!;

    await harness.mount(tester, _past);
    await _settle(tester);

    _expectDualChannel(
      tester,
      planItemId: id,
      kind: SlotKind.backfill,
      title: '补记：排障',
      glyph: '\u25B6',
    );
    // 回填态不是 done：删除线只在 `SlotKind.done` 上加。
    expect(_titleStyle(tester, id, '补记：排障').decoration, isNull);

    await _flushTimers(tester);
  });

  testWidgets('habit 态：● + 「打卡」，压过回填与完成', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _past);
    final String habitId = await harness.repos.habit.create(
      name: '晨间拉伸',
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
    final HabitData habit = (await tester.runAsync(
      () => harness.repos.habit.listActive(),
    ))!.firstWhere((HabitData h) => h.id == habitId);
    final String id = (await tester.runAsync(
      () => TimelineStore(harness.repos).createFromHabit(
        date: _past,
        habit: habit,
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
      ),
    ))!;

    await harness.mount(tester, _past);
    await _settle(tester);

    // 过去日 + status='done' 本来会是 backfill，`is_habit_ref=1` 把它压成 habit。
    _expectDualChannel(
      tester,
      planItemId: id,
      kind: SlotKind.habit,
      title: '晨间拉伸',
      glyph: '\u25CF',
    );

    await _flushTimers(tester);
  });

  // ===========================================================================
  // Task 29 · 收口：最小受支持视口（960 宽）+ 最小格高（真实 15 分钟格）
  // ===========================================================================
  // 为什么要单开一条：`desktop_shell.dart:111` 的 `minimumSize` 是 960×640，
  // 而上面四态用例都在 1400×3000 上跑（网格宽 1098）。窄档下右轨固定 240、
  // 时间轴列 52 + 列间距 10 之后，网格只剩 658 —— 条目行少掉 440px 横向余量，
  // 而 15 分钟格净高只有 20px、`LedgerCheckbox` 自己就 22px。两个「最小」同时
  // 成立，才是 `RenderFlex overflowed` 最容易被顶出来的工况。
  //
  // 为什么不再把高度也压到 640：格高是常量（`slot_state.dart:42`
  // `kGridHeight = 18 × 44 = 792`），与视口高度无关；外框压到 640 会让页面
  // 外层 `Row`（高度由 792 决定）自己溢出，那是既有的另一笔账，会把本条要盯的
  // 条目行淹掉。窄档判据只看宽度（`day_timeline.dart:7` `tlNarrowBreakpoint`）。
  //
  // 为什么要 mount 两次：`slot_state.dart:128-142` 的 `isBackfill` 对「早于今天」
  // 的日期**无条件** true，所以过去日永远拿不到 `done` / `plannedOpen`；未来日
  // 又拿不到 `backfill`。一次 mount 装不下四态，两次是唯一确定性的走法（同为
  // 过去日的 `habit` 与 `backfill` 共用第二屏）。
  testWidgets('最小视口 + 最小格高：四态同屏、零溢出、字形互异', (tester) async {
    _useNarrowSurface(tester);

    // 15 分钟格交给内容的净高：`day_grid.dart:225-226` 先算
    // `(kSlotMinutes / 60 × kHourRowHeight).clamp(22.0, kGridHeight)` = 22，
    // `:228` 上移 1px、`:231` 再减 2px ⇒ 20。做成可失败断言，免得哪天格高
    // 或钳位下限改了就悄悄退化成「舒适档空转」。
    final double netTileHeight =
        ((kSlotMinutes / 60) * kHourRowHeight).clamp(22.0, kGridHeight) - 2;
    expect(netTileHeight, 20, reason: '最小格高不再是 20px，溢出判据失去意义');

    // ---- 第一屏：未来日 ⇒ plannedOpen + done ----
    final _Harness future = _Harness.create(selected: _future);
    final String openId = (await tester.runAsync(
      () => TimelineStore(future.repos).createManual(
        date: _future,
        title: '预排：评审',
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
        todayIso: _today,
        nowMinute: 0,
      ),
    ))!;
    final String doneId = (await tester.runAsync(
      () => TimelineStore(future.repos).createManual(
        date: _future,
        title: '已完成：写周报',
        startMinute: 10 * 60 + 15,
        endMinute: 10 * 60 + 30,
        todayIso: _today,
        nowMinute: 0,
      ),
    ))!;
    // 未来日 ⇒ 不算回填，置 done 得到的是 `SlotKind.done`。
    await tester.runAsync(
      () => future.repos.planItem.setStatus(doneId, PlanStatus.done),
    );

    await future.mount(tester, _future);
    await _settle(tester);
    _expectNoOverflow(tester, '未来日 plannedOpen + done');

    // 窄档证据：960 − 240（右轨） − 52（时间轴列） − 10（列间距） = 658。
    // 宽度对不上就说明没走窄档，这条用例也就不再是「最小视口」。
    expect(
      tester.getSize(find.byKey(_kGrid)).width,
      closeTo(658, 0.01),
      reason: '没走窄档：960 − 240 − 52 − 10 应为 658',
    );

    for (final String id in <String>[openId, doneId]) {
      _expectMinTile(tester, planItemId: id, netTileHeight: netTileHeight);
    }

    final String openGlyph = _renderedGlyph(tester, openId);
    final String doneGlyph = _renderedGlyph(tester, doneId);
    expect(openGlyph, '\u25CB', reason: 'plannedOpen 字形变了');
    expect(doneGlyph, '\u2713', reason: 'done 字形变了');
    _expectNoChipText(tester, openId);
    _expectNoChipText(tester, doneId);

    // ---- 第二屏：过去日 ⇒ backfill + habit（habit 压过 backfill）----
    final _Harness past = _Harness.create(selected: _past);
    final String backfillId = (await tester.runAsync(
      () => TimelineStore(past.repos).createManual(
        date: _past,
        title: '补记：排障',
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
        todayIso: _today,
        nowMinute: 0,
      ),
    ))!;
    final String habitId = await past.repos.habit.create(
      name: '晨间拉伸',
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
    final HabitData habit = (await tester.runAsync(
      () => past.repos.habit.listActive(),
    ))!.firstWhere((HabitData h) => h.id == habitId);
    final String habitEntryId = (await tester.runAsync(
      () => TimelineStore(past.repos).createFromHabit(
        date: _past,
        habit: habit,
        startMinute: 10 * 60 + 15,
        endMinute: 10 * 60 + 30,
      ),
    ))!;

    await past.mount(tester, _past);
    await _settle(tester);
    _expectNoOverflow(tester, '过去日 backfill + habit');

    // habit 条目还多一个「习惯回填」徽标，是最宽也最挤的一条。
    for (final String id in <String>[backfillId, habitEntryId]) {
      _expectMinTile(tester, planItemId: id, netTileHeight: netTileHeight);
    }

    final String backfillGlyph = _renderedGlyph(tester, backfillId);
    final String habitGlyph = _renderedGlyph(tester, habitEntryId);
    // 回填字形必须是 `▶` U+25B6；`▸` U+25B8 是本任务明令禁用的那个。
    expect(backfillGlyph, '\u25B6', reason: 'backfill 字形变了');
    expect(habitGlyph, '\u25CF', reason: 'habit 字形变了');
    _expectNoChipText(tester, backfillId);
    _expectNoChipText(tester, habitEntryId);

    // 四态字形互异：两屏各两个，合起来必须是 4 个不同字符。
    final Set<String> seen = <String>{
      openGlyph,
      doneGlyph,
      backfillGlyph,
      habitGlyph,
    };
    expect(seen.length, 4, reason: '四态字形不互异：$seen');

    await _flushTimers(tester);
  });

  // --- Task 40 · B1：计划区表格化表头 + 删除确认 ---------------------------

  testWidgets('日期表头行已删（日期只由顶部日期模块表达）；刻度列对齐未受影响', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await harness.mount(tester, _today);
    await _settle(tester);

    // Task 49：日期表头整行删除，`day-grid-header-date` 连同该行一起去掉。
    expect(
      find.byKey(const ValueKey<String>('day-grid-header-date')),
      findsNothing,
      reason: '日期表头行还在：日期只应由顶部日期模块表达',
    );

    // 刻度列仍在，且没被挤歪：窄档（1400 − 240 = 1160 < 1280）仍是 52。
    final Finder ruler = find.byKey(const ValueKey<String>('day-grid-ruler'));
    expect(ruler, findsOneWidget, reason: '刻度列不见了');
    expect(
      tester.getSize(ruler).width,
      closeTo(AppTokens.tlWidthNarrow, 0.01),
      reason: '刻度列被挤歪了',
    );

    // 左缘仍与内容列（x=0）同线：表头删掉后不得反过来把刻度列推歪。
    expect(
      tester.getTopLeft(ruler).dx,
      closeTo(tester.getTopLeft(find.byType(DayGrid)).dx, 0.01),
      reason: '刻度列左缘与 DayGrid（section）左缘不一致',
    );

    await _flushTimers(tester);
  });

  testWidgets('详情窗点「删除」先弹确认；取消 ⇒ 条目仍在、库里没软删', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, date: _today, title: '别删我', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _today);
    final Finder entry = find.byKey(
      ValueKey<String>('day-grid-entry-${plan.id}'),
    );
    expect(entry, findsOneWidget);

    // W2 起删除入口搬进了任务详情窗：点条目 → 弹详情 → 点窗里的「删除」。
    await tester.tap(entry);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('plan-detail-delete')));
    await _settle(tester);

    final Finder cancel = find.byKey(
      const ValueKey<String>('confirm-dialog-cancel'),
    );
    expect(cancel, findsOneWidget, reason: '删除没有确认环节（需求 9）');

    await tester.tap(cancel);
    await _settle(tester);

    expect(cancel, findsNothing);
    expect(entry, findsOneWidget, reason: '取消后条目不该消失');
    expect(tester.takeException(), isNull, reason: '取消删除不该产生异常');
    // 库层同一条事实：仍然只有那一行，没有被软删。
    await _onlyPlan(tester, harness, _today);

    await _flushTimers(tester);
  });

  testWidgets('确认删除 ⇒ 条目消失、库里查不到', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, date: _today, title: '删掉我', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final PlanItemData plan = await _onlyPlan(tester, harness, _today);
    final Finder entry = find.byKey(
      ValueKey<String>('day-grid-entry-${plan.id}'),
    );

    await tester.tap(entry);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('plan-detail-delete')));
    await _settle(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-dialog-confirm')),
    );
    await _settle(tester);

    expect(entry, findsNothing, reason: '确认后条目仍在');
    final List<PlanItemData> left = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    ))!;
    expect(left, isEmpty, reason: '确认后没有软删');

    await _flushTimers(tester);
  });

  // ---------------------------------------------------------------- 需求 1 / 3
  //
  // 下面三条把 `slot_layout.dart` 的纯函数几何接到**真实渲染树**上：
  // 纯函数算对只是必要条件，还得证明 `day_grid.dart` 确实照着那份几何画。
  // 每条都能靠「撤掉修复」变红：并发不拆车道 ⇒ 两条条目同一个 `Rect`
  // （top 差 0、互相盖住）；起点不参与横轴换算 ⇒ 09:45 的左缘仍是 +2。

  testWidgets('同一时段两条任务 ⇒ 两条车道并排，格子高度不变（需求 1）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, date: _today, title: '并发甲', startMinute: 9 * 60);
    await _seedPlan(harness, date: _today, title: '并发乙', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final List<PlanItemData> plans = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    ))!;
    expect(plans, hasLength(2), reason: '两条计划没落库');

    final Finder first = find.byKey(
      ValueKey<String>('day-grid-entry-${plans[0].id}'),
    );
    final Finder second = find.byKey(
      ValueKey<String>('day-grid-entry-${plans[1].id}'),
    );
    expect(first, findsOneWidget, reason: '并发第一条没画出来');
    expect(second, findsOneWidget, reason: '并发第二条没画出来');
    // 标题各自可见（限定在**格子里**那条条目内判：右轨也列着同名待办）⇒
    // 不是「后一条把前一条整片盖掉」。
    for (final PlanItemData plan in plans) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-${plan.id}')),
          matching: find.text(plan.title),
        ),
        findsOneWidget,
        reason: '${plan.title} 的正文没画在自己那条格子里',
      );
    }

    final Rect grid = tester.getRect(find.byKey(_kGrid));
    // 2 × 22 == 44：一行本来就放得下两条，撑高是多余动作。
    expect(
      grid.height,
      closeTo(kGridHeight, 0.01),
      reason: '两条并发把整块格子撑高了（2 车道应仍是 44/行）',
    );

    final Rect ra = tester.getRect(first);
    final Rect rb = tester.getRect(second);
    expect(ra.height, closeTo(kLaneHeight - 2, 0.01), reason: '车道高不是 22−2');
    expect(rb.height, closeTo(kLaneHeight - 2, 0.01), reason: '车道高不是 22−2');
    // 纵向错开一个车道高：这才是「并排」，同 top 就是互相盖住。
    expect(
      (ra.top - rb.top).abs(),
      closeTo(kLaneHeight, 0.01),
      reason: '两条并发落在同一条车道（top 差不是 22）',
    );
    // 同段同列 ⇒ 横向必须完全一致（都与 09:00 左贴）。
    expect(ra.left, closeTo(rb.left, 0.01));
    expect(ra.width, closeTo(rb.width, 0.01));

    // 这两条都在第 9 行（grid 顶部起第 3 行），从行顶 +1 起排。
    // 再 +1 是 `day-grid` 自身 1px 边框：`Positioned.top` 相对 Stack，而
    // `getRect(day-grid)` 量的是含边框的外框。
    const double gridBorder = 1;
    final double row9Top = gridBorder + 3 * kHourRowHeight + 1;
    final double topMin = ra.top < rb.top ? ra.top : rb.top;
    final double topMax = ra.top < rb.top ? rb.top : ra.top;
    expect(
      topMin - grid.top,
      closeTo(row9Top, 0.01),
      reason: '第一条没落在 09:00 行顶',
    );
    expect(
      topMax - grid.top,
      closeTo(row9Top + kLaneHeight, 0.01),
      reason: '第二条没落到第二车道',
    );

    _expectNoOverflow(tester, '同一时段两条并发');
    await _flushTimers(tester);
  });

  testWidgets('同一时段三条任务 ⇒ 该行撑到 66，总高 814（需求 1）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    await _seedPlan(harness, date: _today, title: '并发甲', startMinute: 9 * 60);
    await _seedPlan(harness, date: _today, title: '并发乙', startMinute: 9 * 60);
    await _seedPlan(harness, date: _today, title: '并发丙', startMinute: 9 * 60);
    await harness.mount(tester, _today);
    await _settle(tester);

    final List<PlanItemData> plans = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    ))!;
    expect(plans, hasLength(3), reason: '三条计划没落库');

    final Rect grid = tester.getRect(find.byKey(_kGrid));
    // 3 × 22 == 66 > 44 ⇒ 只有这一行长 22px，总高 792 + 22 = 814。
    expect(
      grid.height,
      closeTo(kGridHeight + 22, 0.01),
      reason: '三条并发没有把该行撑高（或把别的行也撑了）',
    );

    final List<double> tops = <double>[];
    for (final PlanItemData plan in plans) {
      final Rect rect = tester.getRect(
        find.byKey(ValueKey<String>('day-grid-entry-${plan.id}')),
      );
      // 每条都完整占到一个车道高（不再挤成 11px 一条，看不清内容）。
      expect(
        rect.height,
        closeTo(kLaneHeight - 2, 0.01),
        reason: '条目 ${plan.id} 在 3 车道行里高度不对',
      );
      tops.add(rect.top - grid.top);
    }
    tops.sort();
    expect(tops[1] - tops[0], closeTo(kLaneHeight, 0.01));
    expect(tops[2] - tops[1], closeTo(kLaneHeight, 0.01));
    // +1 是 `day-grid` 自身的 1px 边框（`getRect` 量外框，`Positioned` 相对内容区）。
    expect(
      tops[0],
      closeTo(1 + 3 * kHourRowHeight + 1, 0.01),
      reason: '第一条没落在 09:00 行顶',
    );

    _expectNoOverflow(tester, '同一时段三条并发');
    await _flushTimers(tester);
  });

  testWidgets('条目左缘按起始分钟落到对应列，不再满宽左贴（需求 3）', (tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _today);
    // 两条都在 09 点这一行、互不重叠 ⇒ 单车道，横向差异只可能来自起点分钟。
    await _seedPlan(harness, date: _today, title: '准点', startMinute: 9 * 60);
    await _seedPlan(
      harness,
      date: _today,
      title: '四十五',
      startMinute: 9 * 60 + 45,
    );
    await harness.mount(tester, _today);
    await _settle(tester);

    final List<PlanItemData> plans = (await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    ))!;
    expect(plans, hasLength(2));
    final PlanItemData early = plans.firstWhere((PlanItemData p) => p.title == '准点');
    final PlanItemData late = plans.firstWhere(
      (PlanItemData p) => p.title == '四十五',
    );

    final Rect grid = tester.getRect(find.byKey(_kGrid));
    expect(
      grid.height,
      closeTo(kGridHeight, 0.01),
      reason: '两条不重叠的条目被算成并发',
    );
    // 列宽以**内容区**宽度算：`day-grid` 的 1px 边框左右各吃 1px。
    final double cellWidth = (grid.width - 2) / kGridCols;
    expect(cellWidth, greaterThan(0));

    final Rect earlyRect = tester.getRect(
      find.byKey(ValueKey<String>('day-grid-entry-${early.id}')),
    );
    final Rect lateRect = tester.getRect(
      find.byKey(ValueKey<String>('day-grid-entry-${late.id}')),
    );

    // 内容区起点比 `day-grid` 外框内缩 1px（边框）。两条都是 15 分钟 ⇒ 各占一列。
    const double gridBorder = 1;
    // 09:00 ⇒ 第 0 列 + 2px 缝（与并发之前的 `left: 2` 一致）。
    expect(
      earlyRect.left - grid.left,
      closeTo(gridBorder + 2, 0.01),
      reason: '9:00 的条目没贴到左缘',
    );
    // 09:45 ⇒ 第 3 列 + 2px 缝。这就是需求 3 的判据：左缘由起点分钟决定。
    expect(
      lateRect.left - grid.left,
      closeTo(gridBorder + 3 * cellWidth + 2, 0.01),
      reason: '9:45 的条目左缘没落在第 4 格（仍按满宽左贴）',
    );
    // 宽度 = 1 列 − 左右各 2px 缝。**只占一列**这一点本身就是需求 3 的另一半：
    // 修复前两条都吃满整宽（`left: 2, right: 2`），宽度会是 `4 * cellWidth - 4`。
    expect(
      earlyRect.width,
      closeTo(cellWidth - 4, 0.01),
      reason: '整点 15 分钟条目没收到 1 列',
    );
    expect(
      lateRect.width,
      closeTo(cellWidth - 4, 0.01),
      reason: '9:45 的条目宽度没有收到 1 列',
    );
    // 纵向也仍是「按真实分钟落位」的既有行为，顺手钉住。
    expect(
      lateRect.top - grid.top,
      closeTo(
        gridBorder + 3 * kHourRowHeight + 0.75 * kHourRowHeight + 1,
        0.01,
      ),
      reason: '单车道条目的纵向落位被改动',
    );

    _expectNoOverflow(tester, '起始分钟 → 列');
    await _flushTimers(tester);
  });
}

/// 一条网格条目的联合判据：字形 · 左缘竖条 ·（调用方另判删除线）。
///
/// W2 起条目右侧不再有「未分级 / 状态词 / 删除」文字，判据里也不再有状态词一栏；
/// 「确实一个字都没了」由 `_expectNoChipText` 反向钉住。
///
/// 字形 `Text` 还必须显式带正文字族 + 兜底列表 —— 四个字形都不在 Inter 里，
/// 只靠继承 `DefaultTextStyle` 会在缺字体的机器上渲染成豆腐块。
void _expectDualChannel(
  WidgetTester tester, {
  required String planItemId,
  required SlotKind kind,
  required String title,
  required String glyph,
}) {
  final Finder entry = find.byKey(
    ValueKey<String>('day-grid-entry-$planItemId'),
  );

  // 字形按「同一字符 + 显式正文字族」定位：条目里每个 `Text` 都会 build 出
  // 一个 `RichText`，`LedgerCheckbox` 勾选时自己也画一个 `✓`（13px JetBrains
  // Mono），只按字符找会命中两个。这条同时把硬约束 B（字形必须显式声明正文
  // 字族 + 兜底列表）变成可失败的判据。
  final List<RichText> glyphCandidates = tester
      .widgetList<RichText>(
        find.descendant(of: entry, matching: find.byType(RichText)),
      )
      .where(
        (RichText rich) =>
            rich.text.toPlainText() == glyph &&
            rich.text.style?.fontFamily == AppFonts.body,
      )
      .toList();
  expect(glyphCandidates, hasLength(1), reason: '$kind 缺字形');
  final TextStyle glyphStyle = glyphCandidates.single.text.style!;
  expect(glyphStyle.fontFamily, AppFonts.body);
  expect(glyphStyle.fontFamilyFallback, AppFonts.bodyFallback);
  expect(glyphStyle.color, foregroundOfSlotKind(kind, ThemeTokens.light));
  expect(glyphStyle.fontSize, 11);

  // 标题仍在（既有元素不动）。
  expect(
    find.descendant(of: entry, matching: find.text(title)),
    findsOneWidget,
  );

  // 左缘 2px 竖条：宽度 2，颜色 = 该态前景色；其余三边保持既有细边 `hair`。
  final BoxDecoration decoration =
      tester
              .widget<Container>(
                find.byKey(ValueKey<String>('day-grid-entry-$planItemId')),
              )
              .decoration!
          as BoxDecoration;
  final Border border = decoration.border! as Border;
  expect(border.left.width, 2);
  expect(border.left.color, foregroundOfSlotKind(kind, ThemeTokens.light));
  expect(border.top.color, ThemeTokens.light.hair);
  expect(border.right.color, ThemeTokens.light.hair);
  expect(border.bottom.color, ThemeTokens.light.hair);
}

/// 条目里标题 `Text` 的样式（删除线判据）。
TextStyle _titleStyle(WidgetTester tester, String planItemId, String title) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-$planItemId')),
          matching: find.text(title),
        ),
      )
      .style!;
}

/// 最小受支持视口的**宽度**（`desktop_shell.dart:111`
/// `minimumSize: Size(960, 640)`）。
///
/// 高度仍取 3000：格高是常量（`slot_state.dart:42` `kGridHeight = 792`），与
/// 视口高度无关；压到 640 只会让页面外层 `Row` 自己溢出（既有行为），把本条要
/// 盯的条目行溢出淹掉。窄档判据只看宽度（`day_timeline.dart:7`）。
void _useNarrowSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(960, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// `RenderFlex overflowed` 必须让这条用例变红。
///
/// 判据与全仓既有做法一致（`scale200_overflow_test.dart:100`）：对
/// `takeException()` 做实断言。**不能**先「抽干异常再计数」——抽干本身就是把
/// 异常扔掉，任何真实溢出都会变成绿。失败信息里带上完整异常文本，省得再猜是
/// 哪个 widget 撑爆的。
void _expectNoOverflow(WidgetTester tester, String where) {
  final Object? error = tester.takeException();
  expect(
    error,
    isNull,
    reason: '$where 出现渲染异常（含 RenderFlex overflowed）：$error',
  );
}

/// 条目真的落在「最小格高」路径上，且内容自然高度确实超过壳内高。
///
/// 两条都是可失败断言：前者钉住 20px 净高（`day_grid.dart:225-231`），后者钉住
/// 「最坏工况成立」——壳内高只有 20 − 上下各 1px 边框 = 18，而内容（复选框
/// 22px）自然高度更高，`day_grid.dart:274-280` 的 `ClipRect` + `OverflowBox`
/// 守卫一旦被拿掉，就会当场 `RenderFlex overflowed`。
void _expectMinTile(
  WidgetTester tester, {
  required String planItemId,
  required double netTileHeight,
}) {
  final Finder entry = find.byKey(
    ValueKey<String>('day-grid-entry-$planItemId'),
  );
  expect(
    tester.getSize(entry).height,
    netTileHeight,
    reason: '条目 $planItemId 没走在最小格高路径上',
  );
  expect(
    tester
        .getSize(find.descendant(of: entry, matching: find.byType(Row)).first)
        .height,
    greaterThan(netTileHeight - 2),
    reason: '条目 $planItemId 的内容没超出壳内高，测不到最坏工况',
  );
}

/// 条目里那一个字形 `RichText` 实际渲染出的字符。
///
/// 定位沿用 W1 已证成的双条件（`fontFamily == AppFonts.body` + 单字符），但
/// **不预设期望值**：先读回真值、再交由调用方与期望比对，映射写错（例如 done
/// 与 backfill 张冠李戴）才会被咬住。单字符条件顺带把状态词、时间、标题，以及
/// `LedgerCheckbox` 自绘的 `✓`（JetBrains Mono）排除在外。
String _renderedGlyph(WidgetTester tester, String planItemId) {
  final List<RichText> hits = tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-$planItemId')),
          matching: find.byType(RichText),
        ),
      )
      .where(
        (RichText rich) =>
            rich.text.style?.fontFamily == AppFonts.body &&
            rich.text.toPlainText().runes.length == 1,
      )
      .toList();
  expect(hits, hasLength(1), reason: '条目 $planItemId 里的字形不唯一');
  return hits.single.text.toPlainText();
}

/// 条目里的「未分级 / 状态词 / 删除」文字必须**一个都不剩**。
///
/// W2 把 chip 右侧那三样文字整段删掉，判据随之翻面：以前是「状态词必须在该条目
/// 里」，现在是「一条都不许有」。谁把那段加回来（或只删一半），这条立刻红。
void _expectNoChipText(WidgetTester tester, String planItemId) {
  final Finder entry = find.byKey(
    ValueKey<String>('day-grid-entry-$planItemId'),
  );
  for (final String text in <String>[
    '未分级',
    '计划',
    '完成',
    '回填',
    '打卡',
    '删除',
  ]) {
    expect(
      find.descendant(of: entry, matching: find.text(text)),
      findsNothing,
      reason: '条目 $planItemId 仍渲染着「$text」',
    );
  }
}
