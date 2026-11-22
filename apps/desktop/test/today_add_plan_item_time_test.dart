// apps/desktop/test/today_add_plan_item_time_test.dart
//
// Task 39 · W1 · 指令 5：「+ 手写一条」支持指定日期 + 开始时刻。
// Task 40 · B2 · 需求 2：日期 / 时刻两枚芯片合并成**一个**按钮，
// 且该按钮与重要 / 紧急芯片**同一行**（本文件钉死这两条）。
//
// 证据口径（`AGENTS.md` R5）：只钉**落库事实**与**组件归属**，不钉像素。
//   1. 合并按钮点开后，改日期真的走全站唯一组件 `DatePickerSheet`
//      （不是自造日历），改时刻走 Material `showTimePicker`；
//   2. 选完日期 + 时刻后，新条目落在**选中的那天**，`planned_start` = 所选时刻,
//      `planned_end` = 所选时刻 + `kSlotMinutes`（15 分钟一档，与方格同源）；
//   3. 不选时刻 ⇒ `planned_start` / `planned_end` **皆 null**（条目进未排期带，
//      而不是被随手塞进某一格）；
//   4. 「同一行」= 两个控件的矩形垂直重叠且顶边齐平（不钉像素值，钉相对位置）。
//
// 为什么时刻只断言 09:00 这一档：`showTimePicker` 的初始值就是 09:00（见
// `today_page.dart:_pickTime` 的 `initial = _startMinute ?? 9 * 60`），
// 测试里点一次「OK」即可拿到确定值，不必去拨表盘坐标 —— 拨盘坐标是像素，
// 本机字体一变就假红。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/date_picker_sheet.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';

/// 手写条的目标日：与"今天"不同的另一天，才证明日期真的被用上。
const String _otherDay = '2026-11-12';

/// 合并后的主定位符（需求 2 的新锚点）。
const ValueKey<String> _kDateTimeButton =
    ValueKey<String>('add-plan-datetime-button');

/// 旧锚点：日期 / 时刻两段文本仍各自带 key（合并按钮**内部**的子元素）。
const ValueKey<String> _kDateChip = ValueKey<String>('add-plan-date-chip');
const ValueKey<String> _kTimeChip = ValueKey<String>('add-plan-time-chip');

/// 「清除时刻」只在按钮点开的菜单里出现 ⇒ 菜单没开时必然不到。
const ValueKey<String> _kTimeClear = ValueKey<String>('add-plan-time-clear');

/// 优先级芯片里的「重要」：需求 2 要求它与日期时间按钮同一行。
const ValueKey<String> _kImportantChip =
    ValueKey<String>('priority-mark-picker-important');

/// 手写条的标题输入框（按 hint 定位：`_AddPlanItemBar` 没有自己的 key）。
final Finder _addBarField = find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextField && widget.decoration?.hintText == '添加计划条目…',
);

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task39-add-bar-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 挂今日页内容体（外包 `LedgerShell`，与真机一致）。
  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nScope(
          const MaterialApp(
            home: LedgerShell(content: TodayPage(), currentNavId: 'today'),
          ),
        ),
      ),
    );
  }

  Future<List<PlanItemData>> rowsOn(WidgetTester tester, String date) async {
    final List<PlanItemData> rows =
        (await tester.runAsync(() => repos.planItem.listByDate(date)))!;
    return rows;
  }
}

/// 撑高测试面：今日页整页竖排多段，默认 800×600 会溢出。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 等一个弹层开/关完动画（弹层不碰 drift，可以只 pump）。
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// 点开合并按钮的日期 / 时刻菜单。
Future<void> _openDateTimeMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(_kDateTimeButton));
  await _pumpDialog(tester);
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 需求 2 的硬判据：日期时间按钮与「重要」芯片**同一行**。
///
/// 判据用相对位置而不是像素值：两者矩形垂直方向真重叠，且顶边齐平
/// （同一行会被 `Row` 的 `CrossAxisAlignment.start` 拉到同一个顶边）。
/// 只要有人把日期时间按钮换回「独立一行」，第二条立刻红。
void _expectSameRowAsPriorityChip(WidgetTester tester) {
  final Rect button = tester.getRect(find.byKey(_kDateTimeButton));
  final Rect chip = tester.getRect(find.byKey(_kImportantChip));
  expect(
    button.bottom,
    greaterThan(chip.top),
    reason: '日期时间按钮与优先级芯片必须在同一行（垂直方向必须重叠）',
  );
  expect(
    chip.bottom,
    greaterThan(button.top),
    reason: '日期时间按钮与优先级芯片必须在同一行（垂直方向必须重叠）',
  );
  expect(
    button.top,
    moreOrLessEquals(chip.top, epsilon: 2),
    reason: '同一行 ⇒ 顶边齐平；差出 2px 以上就是被拆到了两行',
  );
}

void main() {
  testWidgets('① 选日期 + 时刻 ⇒ 落在选中那天，起止时刻按 15 分钟一档落库',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    // 默认态：一个按钮同时显示日期与时刻；时刻未排。
    expect(find.byKey(_kDateTimeButton), findsOneWidget);
    expect(find.text('日期 · $_today'), findsOneWidget);
    expect(find.text('时间 · 未排'), findsOneWidget);
    expect(find.byKey(_kTimeClear), findsNothing, reason: '未选时刻时不该有清除入口');
    _expectSameRowAsPriorityChip(tester);

    await tester.enterText(_addBarField, '手写测试条目');
    await tester.pump();

    // ---- 日期：菜单 → 全站唯一日期组件 ----
    await _openDateTimeMenu(tester);
    expect(find.text('改日期'), findsOneWidget, reason: '合并按钮要把「改日期」做成显式一项');
    expect(find.text('改时刻'), findsOneWidget);
    await tester.tap(find.text('改日期'));
    await _pumpDialog(tester);
    expect(
      find.byType(DatePickerSheet),
      findsOneWidget,
      reason: '日期选择必须走 DatePickerSheet，不得自造日历',
    );
    await tester.tap(find.byKey(const ValueKey<String>('day-$_otherDay')));
    await tester.pump();
    await tester.tap(find.text('确定'));
    await _pumpDialog(tester);
    expect(find.byType(DatePickerSheet), findsNothing, reason: '确定后弹层必须关闭');
    expect(
      find.text('日期 · $_otherDay'),
      findsOneWidget,
      reason: '按钮要回显用户选的那一天',
    );
    // 合成一个按钮后，两个值必须在**同一个**按钮里同时可读。
    expect(find.byKey(_kDateTimeButton), findsOneWidget);
    expect(find.byKey(_kTimeChip), findsOneWidget);
    expect(find.byKey(_kDateChip), findsOneWidget);
    _expectSameRowAsPriorityChip(tester);

    // ---- 时刻：菜单 → Material showTimePicker，初始 09:00，点 OK 即取值 ----
    await _openDateTimeMenu(tester);
    await tester.tap(find.text('改时刻'));
    await _pumpDialog(tester);
    expect(find.text('选择开始时刻'), findsOneWidget, reason: '弹出的必须是时间选择器');
    await tester.tap(find.text('OK'));
    await _pumpDialog(tester);
    expect(find.text('时间 · 09:00'), findsOneWidget);
    expect(find.byKey(_kDateTimeButton), findsOneWidget);

    // ---- 落库 ----
    await tester.tap(find.text('+ 手写一条'));
    await _settle(tester);

    final List<PlanItemData> rows = await harness.rowsOn(tester, _otherDay);
    expect(rows, hasLength(1), reason: '条目必须落在用户选的那一天，而不是今天');
    expect(rows.single.title, '手写测试条目');
    expect(
      rows.single.plannedStart,
      9 * 60,
      reason: 'planned_start 必须等于所选开始时刻（09:00 ⇒ 540）',
    );
    expect(
      rows.single.plannedEnd,
      9 * 60 + kSlotMinutes,
      reason: 'planned_end 恒为 start + kSlotMinutes（15 分钟一档，与方格同源）',
    );

    await _flushTimers(tester);
  });

  testWidgets('② 不选日期、不选时刻 ⇒ 落在所选日，起止时刻皆 null', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.enterText(_addBarField, '只写标题的一条');
    await tester.pump();
    await tester.tap(find.text('+ 手写一条'));
    await _settle(tester);

    final List<PlanItemData> rows = await harness.rowsOn(tester, _today);
    expect(rows, hasLength(1));
    expect(rows.single.title, '只写标题的一条');
    expect(
      rows.single.plannedStart,
      isNull,
      reason: '不选时刻就必须落进未排期带，不许被默认塞进某一格',
    );
    expect(rows.single.plannedEnd, isNull);

    await _flushTimers(tester);
  });

  testWidgets('③ 菜单里的「清除时刻」把时刻退回未排，且不影响已选日期', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    await tester.enterText(_addBarField, '先选后清的条目');
    await tester.pump();

    await _openDateTimeMenu(tester);
    await tester.tap(find.text('改时刻'));
    await _pumpDialog(tester);
    await tester.tap(find.text('OK'));
    await _pumpDialog(tester);
    expect(find.text('时间 · 09:00'), findsOneWidget);

    // 清时刻的入口只在真排了时刻时出现在菜单里（没排时不出现）。
    await _openDateTimeMenu(tester);
    expect(
      find.byKey(_kTimeClear),
      findsOneWidget,
      reason: '排了时刻后，菜单里必须有清除入口',
    );
    await tester.tap(find.byKey(_kTimeClear));
    await _pumpDialog(tester);
    expect(find.text('时间 · 未排'), findsOneWidget);
    expect(find.text('日期 · $_today'), findsOneWidget, reason: '清时刻不该动日期');

    await _openDateTimeMenu(tester);
    expect(
      find.byKey(_kTimeClear),
      findsNothing,
      reason: '时刻已清空 ⇒ 菜单里不该再有可点的空动作',
    );
    await tester.tapAt(const Offset(4, 4)); // 关掉菜单，不选中任何一项
    await _pumpDialog(tester);

    await tester.tap(find.text('+ 手写一条'));
    await _settle(tester);

    final List<PlanItemData> rows = await harness.rowsOn(tester, _today);
    expect(rows, hasLength(1));
    expect(rows.single.plannedStart, isNull);
    expect(rows.single.plannedEnd, isNull);

    await _flushTimers(tester);
  });
}