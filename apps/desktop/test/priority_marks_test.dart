// apps/desktop/test/priority_marks_test.dart
//
// 四维度优先级（重要 / 不重要 × 紧急 / 不紧急）· 代码级回归。
//
// 盯五件事：
//   1. 字形映射：Q1 ▲◆ / Q2 ▲◇ / Q3 ▽◆ / Q4 ▽◇，未分级零尺寸不占空隙；
//   2. 选择器：点任一芯片只改该维度、另一维度保持（未分级时按「否」起步），
//      已分级才出现「清除」，清除回 null；
//   3. 今日页手写条：选「重要 + 紧急」→ 落库 `q1`，提交后选择器清空
//      （不允许下一条静默继承上一条的优先级）；
//   4. 清除后落库 null（与「未分级」是同一个事实，不是 Q4）；
//   5. 方格时间轴：标记渲染在名称**之前**，四个象限各两枚字形互不相同，
//      极简模式（`minimal: true`）仍保留标记。
//
// 全部走内存真库 + 真仓储（除前三个纯控件用例外），不 mock 数据层：
// 「选的重要、落库变成 Q3」这种漂移只有真实读写才能抓住。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/priority_marks.dart';
import 'package:actlog/src/widgets/quick_todo_dialog.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';

const String _today = '2026-11-09';

const ValueKey<String> _kImportance = ValueKey<String>('priority-mark-importance');
const ValueKey<String> _kUrgency = ValueKey<String>('priority-mark-urgency');
const ValueKey<String> _kPickImportant =
    ValueKey<String>('priority-mark-picker-important');
const ValueKey<String> _kPickNotImportant =
    ValueKey<String>('priority-mark-picker-not-important');
const ValueKey<String> _kPickUrgent =
    ValueKey<String>('priority-mark-picker-urgent');
const ValueKey<String> _kPickNotUrgent =
    ValueKey<String>('priority-mark-picker-not-urgent');
const ValueKey<String> _kPickClear = ValueKey<String>('priority-mark-picker-clear');

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
///
/// 用同一个 `db` 起两套读写（provider 层与 `TimelineStore` 直写），
/// 断言读的也是同一份落库数据。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'priority-marks-test');
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

  /// 挂整页今日页内容体。
  ///
  /// 不套 `LedgerShell`：导航栏里也有「今日」，会把「页头已删除」的断言搅浑。
  Future<void> mountTodayPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: const Scaffold(
            body: SingleChildScrollView(child: TodayPage()),
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  /// 只挂方格时间轴（标记渲染的宿主）。
  Future<void> mountGrid(WidgetTester tester, {bool minimal = false}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: DayGrid(date: _today, minimal: minimal)),
        ),
      ),
    );
    await _settle(tester);
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

/// 收尾：卸掉界面放掉 drift 流订阅。
///
/// `ReviewSection.dispose` 里 fire-and-forget 落库，不等它跑完，
/// tearDown 的 `db.close()` 会先关库，这笔写就变成下个用例里的
/// `Can't re-open a database after closing it`。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 手写条输入框（按 hint 精确取，不按序号 —— 页内还有别的 `TextField`）。
final Finder _addBarField = find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextField && widget.decoration?.hintText == '添加计划条目…',
);

/// 把手写面板里的控件限定在面板内（页面正文也有同名芯片与输入框）。
Finder _inDialog(Finder matching) {
  return find.descendant(of: find.byType(QuickTodoDialog), matching: matching);
}

/// 把焦点送进 `TodayPage` 子树（`Shortcuts` 靠 `Focus` 节点收键）。
Future<void> _focusPage(WidgetTester tester) async {
  await tester.showKeyboard(find.byType(EditableText).first);
  await tester.pump();
}

/// 模拟 `Ctrl+<key>`：按下 Ctrl → 敲键 → 松开 Ctrl。
Future<void> _sendCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
  await _settle(tester);
}

/// 单枚标记的字形（未找到会直接抛，比静默 null 好定位）。
String _glyphOf(WidgetTester tester, Finder finder) {
  return tester.widget<Text>(finder).data!;
}

/// 可回写的选择器宿主：把 `onChanged` 的结果同时记进日志与状态。
class _PickerHost extends StatefulWidget {
  const _PickerHost({required this.initial, required this.log});

  final Quadrant? initial;
  final List<Quadrant?> log;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  Quadrant? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: PriorityMarkPicker(
            value: _value,
            onChanged: (Quadrant? next) {
              widget.log.add(next);
              setState(() => _value = next);
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  group('PriorityMarks 字形', () {
    testWidgets('四个象限各渲染两枚、互不相同，且与维度布尔同构', (WidgetTester tester) async {
      const Map<Quadrant, (String, String)> expected = <Quadrant, (String, String)>{
        Quadrant.q1: (kMarkImportant, kMarkUrgent),
        Quadrant.q2: (kMarkImportant, kMarkNotUrgent),
        Quadrant.q3: (kMarkNotImportant, kMarkUrgent),
        Quadrant.q4: (kMarkNotImportant, kMarkNotUrgent),
      };

      for (final MapEntry<Quadrant, (String, String)> entry in expected.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: PriorityMarks(quadrant: entry.key)),
            ),
          ),
        );
        expect(
          _glyphOf(tester, find.byKey(_kImportance)),
          entry.value.$1,
          reason: '${entry.key.code} 的重要性维度字形不对',
        );
        expect(
          _glyphOf(tester, find.byKey(_kUrgency)),
          entry.value.$2,
          reason: '${entry.key.code} 的紧急性维度字形不对',
        );
      }

      // 四组两两不同：任何一种「两枚字形塌成一样」的实现都会被这条兜住。
      expect(expected.values.toSet(), hasLength(4));
    });

    testWidgets('未分级：不渲染任何字形、也不占空隙', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: PriorityMarks(quadrant: null))),
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(PriorityMarks)), Size.zero);
    });
  });

  group('PriorityMarkPicker 交互', () {
    testWidgets('点任一芯片只改该维度，另一维度保持（未分级时按「否」起步）', (WidgetTester tester) async {
      final List<Quadrant?> log = <Quadrant?>[];
      await tester.pumpWidget(_PickerHost(initial: null, log: log));

      // 未分级时四枚芯片都不高亮，也没有「清除」。
      expect(find.byKey(_kPickClear), findsNothing);

      // 只点「重要」：紧急维度按「否」起步 ⇒ Q2，不是 Q1。
      await tester.tap(find.byKey(_kPickImportant));
      await tester.pumpAndSettle();
      expect(log.last, Quadrant.q2, reason: '未分级时点「重要」必须得到 Q2');

      // 再点「紧急」：重要性维度保持 ⇒ Q1。
      await tester.tap(find.byKey(_kPickUrgent));
      await tester.pumpAndSettle();
      expect(log.last, Quadrant.q1, reason: '另一维度必须保持，不许被重置');

      // Q1 下点「不重要」：紧急性保持 ⇒ Q3。
      await tester.tap(find.byKey(_kPickNotImportant));
      await tester.pumpAndSettle();
      expect(log.last, Quadrant.q3);

      // 点「不紧急」：⇒ Q4。
      await tester.tap(find.byKey(_kPickNotUrgent));
      await tester.pumpAndSettle();
      expect(log.last, Quadrant.q4);
    });

    testWidgets('已分级才出现「清除」，点它回 null', (WidgetTester tester) async {
      final List<Quadrant?> log = <Quadrant?>[];
      await tester.pumpWidget(_PickerHost(initial: Quadrant.q1, log: log));

      expect(find.byKey(_kPickClear), findsOneWidget);

      await tester.tap(find.byKey(_kPickClear));
      await tester.pumpAndSettle();

      expect(log.last, isNull);
      expect(find.byKey(_kPickClear), findsNothing, reason: '清除后回到未分级，清除键应收起');
    });
  });

  group('今日页手写条', () {
    testWidgets('选「重要 + 紧急」落库 q1，提交后选择器清空；页头已删除', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      await harness.mountTodayPage(tester);

      // 任务甲：页头（标题「今日」/ 副标 / 完整·极简芯片）已删除。
      expect(find.text('今日'), findsNothing, reason: '页头标题「今日」不该再出现');
      expect(find.text('完整'), findsNothing, reason: '完整/极简芯片已删除');
      expect(find.text('极简'), findsNothing, reason: '完整/极简芯片已删除');
      // 删完之后正文仍在（不是整块被误删）。
      expect(find.text('＋ 从待办池捞'), findsOneWidget);

      await tester.tap(find.byKey(_kPickImportant));
      await tester.pump();
      await tester.tap(find.byKey(_kPickUrgent));
      await tester.pump();
      expect(find.byKey(_kPickClear), findsOneWidget);

      await tester.enterText(_addBarField, '把季度复盘写完');
      await tester.pump();
      await tester.tap(find.text('+ 手写一条'));
      await _settle(tester);

      final rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_today),
      );
      expect(rows, hasLength(1));
      expect(rows!.single.title, '把季度复盘写完');
      expect(
        rows.single.quadrant,
        Quadrant.q1.code,
        reason: '重要 + 紧急 必须落库 q1',
      );
      // 提交成功后清空：下一条不许静默继承上一条的优先级。
      expect(
        find.byKey(_kPickClear),
        findsNothing,
        reason: '提交后选择器必须回到未分级',
      );

      // 落库后再读一遍（同一真库、另一次查询）：优先级是真存进去了，
      // 不是只活在这一次渲染里。
      final again = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_today),
      );
      expect(again!.single.quadrant, Quadrant.q1.code);

      await _flushTimers(tester);
    });

    testWidgets('选中后点「清除」→ 落库为 null（不是 q4）', (WidgetTester tester) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      await harness.mountTodayPage(tester);

      await tester.tap(find.byKey(_kPickImportant));
      await tester.pump();
      await tester.tap(find.byKey(_kPickClear));
      await tester.pump();

      await tester.enterText(_addBarField, '还不知道急不急的事');
      await tester.pump();
      await tester.tap(find.text('+ 手写一条'));
      await _settle(tester);

      final rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_today),
      );
      expect(rows, hasLength(1));
      expect(
        rows!.single.quadrant,
        isNull,
        reason: '清除后是「未分级」，不许悄悄变成 q4',
      );

      await _flushTimers(tester);
    });
  });

  group('方格时间轴', () {
    testWidgets('四个象限各两枚字形，且标记排在名称之前', (WidgetTester tester) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      final TimelineStore store = TimelineStore(harness.repos);

      const Map<String, (Quadrant, String, String)> cases =
          <String, (Quadrant, String, String)>{
        '条目甲': (Quadrant.q1, kMarkImportant, kMarkUrgent),
        '条目乙': (Quadrant.q2, kMarkImportant, kMarkNotUrgent),
        '条目丙': (Quadrant.q3, kMarkNotImportant, kMarkUrgent),
        '条目丁': (Quadrant.q4, kMarkNotImportant, kMarkNotUrgent),
      };

      await tester.runAsync(() async {
        var start = 9 * 60;
        for (final MapEntry<String, (Quadrant, String, String)> entry
            in cases.entries) {
          await store.createTodoWithSlot(
            date: _today,
            title: entry.key,
            startMinute: start,
            endMinute: start + 50,
            quadrant: entry.value.$1.code,
          );
          start += 60;
        }
      });

      await harness.mountGrid(tester);

      final rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_today),
      );
      expect(rows, hasLength(4));

      for (final MapEntry<String, (Quadrant, String, String)> entry
          in cases.entries) {
        final String id =
            rows!.firstWhere((PlanItemData row) => row.title == entry.key).id;
        final Finder tile = find.byKey(ValueKey<String>('day-grid-entry-$id'));
        expect(tile, findsOneWidget, reason: '${entry.key} 没排进格子');

        final Finder importance =
            find.descendant(of: tile, matching: find.byKey(_kImportance));
        final Finder urgency =
            find.descendant(of: tile, matching: find.byKey(_kUrgency));
        expect(_glyphOf(tester, importance), entry.value.$2,
            reason: '${entry.key} 的重要性字形不对');
        expect(_glyphOf(tester, urgency), entry.value.$3,
            reason: '${entry.key} 的紧急性字形不对');

        if (entry.key == '条目甲') {
          final Finder name = find.descendant(
            of: tile,
            matching: find.text(entry.key),
          );
          expect(
            tester.getTopLeft(importance).dx,
            lessThan(tester.getTopLeft(name).dx),
            reason: '标记必须在名称之前',
          );
        }
      }

      await _flushTimers(tester);
    });

    testWidgets('未分级条目不画标记、也不留空隙；极简模式仍保留标记', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      final TimelineStore store = TimelineStore(harness.repos);

      await tester.runAsync(() async {
        await store.createTodoWithSlot(
          date: _today,
          title: '分级了的',
          startMinute: 9 * 60,
          endMinute: 10 * 60,
          quadrant: Quadrant.q2.code,
        );
        await store.createTodoWithSlot(
          date: _today,
          title: '没分级的',
          startMinute: 11 * 60,
          endMinute: 12 * 60,
        );
      });

      await harness.mountGrid(tester);
      final rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_today),
      );
      final String gradedId = rows!
          .firstWhere((PlanItemData row) => row.title == '分级了的')
          .id;
      final String plainId = rows
          .firstWhere((PlanItemData row) => row.title == '没分级的')
          .id;

      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-$gradedId')),
          matching: find.byKey(_kImportance),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-$plainId')),
          matching: find.byKey(_kImportance),
        ),
        findsNothing,
        reason: '未分级（null）不画标记',
      );

      // 极简模式：只裁「进展：…」这类详情行，优先级标记必须留着 ——
      // 10px 字形正是极简要保的低密度信息。
      await harness.mountGrid(tester, minimal: true);
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-$gradedId')),
          matching: find.byKey(_kImportance),
        ),
        findsOneWidget,
        reason: '极简模式仍要显示优先级标记',
      );
      expect(find.text('分级了的'), findsOneWidget);

      await _flushTimers(tester);
    });
  });

  group('未排期带', () {
    testWidgets('未排期条目同样在名称前显示四维标记，未分级不占位', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();

      // 没有 `planned_start` / `planned_end` ⇒ 只落在未排期带，不进格子。
      await tester.runAsync(() async {
        await harness.repos.planItem.create(
          date: _today,
          title: '没排期的急事',
          quadrant: Quadrant.q1,
        );
        await harness.repos.planItem.create(date: _today, title: '没排期的闲事');
      });

      await harness.mountTodayPage(tester);

      final Finder strip = find.byKey(
        const ValueKey<String>('unscheduled-strip'),
      );
      expect(strip, findsOneWidget, reason: '未排期带应该出现');

      // 整条带上只有一枚标记组：未分级那条根本不该插进去（不是插了再零尺寸）。
      expect(
        find.descendant(of: strip, matching: find.byType(PriorityMarks)),
        findsOneWidget,
      );

      final Finder gradedRow = find.ancestor(
        of: find.text('没排期的急事'),
        matching: find.byType(Row),
      );
      expect(gradedRow, findsOneWidget);
      final Finder importance = find.descendant(
        of: gradedRow,
        matching: find.byKey(_kImportance),
      );
      expect(_glyphOf(tester, importance), kMarkImportant);
      expect(
        _glyphOf(
          tester,
          find.descendant(of: gradedRow, matching: find.byKey(_kUrgency)),
        ),
        kMarkUrgent,
      );
      // 与 `day_grid.dart` 一致：标记在名称之前，不是之后。
      expect(
        tester.getTopLeft(importance).dx,
        lessThan(tester.getTopLeft(find.text('没排期的急事')).dx),
        reason: '标记必须在名称之前',
      );

      final Finder plainRow = find.ancestor(
        of: find.text('没排期的闲事'),
        matching: find.byType(Row),
      );
      expect(plainRow, findsOneWidget);
      expect(
        find.descendant(of: plainRow, matching: find.byType(PriorityMarks)),
        findsNothing,
        reason: '未分级（null）不画标记、也不占位',
      );

      await _flushTimers(tester);
    });
  });

  group('手写面板', () {
    testWidgets('面板里选「重要 + 紧急」→ 待办与今日计划都带 q1', (WidgetTester tester) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      await harness.mountTodayPage(tester);
      await _focusPage(tester);

      await _sendCtrl(tester, LogicalKeyboardKey.keyN);
      expect(find.byType(QuickTodoDialog), findsOneWidget);

      await tester.tap(_inDialog(find.byKey(_kPickImportant)));
      await tester.pump();
      await tester.tap(_inDialog(find.byKey(_kPickUrgent)));
      await tester.pump();

      await tester.enterText(_inDialog(find.byType(TextField)).at(0), '面板里分级的');
      await tester.pump();
      await tester.tap(_inDialog(find.text('保存')));
      await _settle(tester);

      expect(find.byType(QuickTodoDialog), findsNothing);

      // 「同时捞入今天」默认勾选 ⇒ 待办被置 done、离开待办池。
      final open = await tester.runAsync(() => harness.repos.todo.listOpen());
      expect(open, isEmpty, reason: '捞入后待办不该还留在池子里');

      // 计划行是待办的**快照**（`pullToPlan` 把待办的象限一并抄过来），
      // 所以这一条 q1 同时证明了「面板的选择进了待办」与「快照没把象限丢掉」。
      final rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_today),
      );
      expect(rows, hasLength(1));
      expect(
        rows!.single.quadrant,
        Quadrant.q1.code,
        reason: '面板选的重要 + 紧急 必须一路带到今日计划',
      );

      await _flushTimers(tester);
    });
  });
}