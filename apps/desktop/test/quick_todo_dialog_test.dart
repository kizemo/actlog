// apps/desktop/test/quick_todo_dialog_test.dart
//
// C7（Task 19 / W7）回归：键条上承诺的动作必须有真实绑定。
//
// - D-a：今日计划段必须有一枚**可见**的「＋ 从待办池捞」入口
//   （此前 `pullToPlan` 全库只有待办池页一处调用，今日页无法把池子里的待办捞进来）。
// - D-b：`Ctrl+N` 打开手写面板、`Ctrl+D` 打卡第一条未打习惯、`Esc` 关闭弹层。
//
// 全部用内存真库 + 真仓储，键盘走 `HardwareKeyboard` 模拟（不是直接调函数），
// 这样「键条说的和代码做的是否一致」才是被真实验证的对象。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/providers_p1.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/quick_todo_dialog.dart';

const String _today = '2026-11-09';
const String _future = '2026-11-12';

/// 内存真库 + 真仓储 + 固定今天、可指定选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({
    String selected = _today,
    List<Override> extra = const <Override>[],
  }) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'quick-todo-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
        ...extra,
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 挂今日页内容体。
  ///
  /// 故意不套 `LedgerShell`：键条与 dock 会引入同名文案和额外输入框，
  /// 让 `find.byType(EditableText)` / `find.text` 互相串味。
  Future<void> mount(WidgetTester tester) async {
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
}

/// 撑高测试面：今日页整页竖排三段，默认 800×600 会溢出。
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
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  // `ReviewSection` 在 `dispose` 里 fire-and-forget 落库（`review_section.dart:64`
  // → `saveReview`）。不等它跑完，tearDown 的 `db.close()` 会先关库，这笔未完成的
  // 写就变成下个用例里的 `Can't re-open a database after closing it`。
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 把焦点送进 `TodayPage` 子树。
///
/// `Shortcuts` 靠 `Focus` 节点收键：`primaryFocus` 停在根 scope 时事件不会冒泡
/// 下来，直接 `sendKeyEvent` 会「什么都没发生」。聚焦页内一个真实输入框是最贴近
/// 真机的做法（真机上用户总是先点进某个输入框再敲快捷键）。
Future<void> _focusPage(WidgetTester tester) async {
  await tester.showKeyboard(find.byType(EditableText).first);
  await tester.pump();
}

/// B2（2026-11-12）：今日页不再常驻 watch 习惯那两个 provider（习惯区与打卡条
/// 已摘除），裸页测试必须自己把它们推到 `AsyncData`：先 `read` 触发初始化，
/// 再 settle 等真库首帧。最多推 6 轮（有界，绝不死等）。
Future<void> _warmUpHabitData(WidgetTester tester, _Harness harness) async {
  // `read` 只取当前状态、不会订阅流 ⇒ 必须先 `listen` 才会真正建立 drift 订阅
  // （订阅随容器 dispose 一并释放，这里不必手动 close）。
  harness.container.listen(habitsForTodayProvider, (previous, next) {});
  harness.container.listen(habitCheckinsProvider, (previous, next) {});
  for (var round = 0; round < 6; round++) {
    harness.container.read(habitsForTodayProvider);
    harness.container.read(habitCheckinsProvider);
    if (harness.container.read(habitsForTodayProvider)
                is AsyncData<List<HabitData>> &&
        harness.container.read(habitCheckinsProvider)
            is AsyncData<List<HabitCheckinData>>) {
      return;
    }
    await _settle(tester);
  }
}

/// 模拟 `Ctrl+<key>`：按下 Ctrl → 敲键 → 松开 Ctrl。
Future<void> _sendCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
  await _settle(tester);
}

/// 把手写面板里的控件限定在面板内（页面正文也有 `TextField`）。
Finder _inQuickDialog(Finder matching) {
  return find.descendant(
    of: find.byType(QuickTodoDialog),
    matching: matching,
  );
}

/// 面板里第 [index] 个输入框（0 = 标题，1 = 预估分钟）。
Finder _quickField(int index) => _inQuickDialog(find.byType(TextField)).at(index);

void main() {
  testWidgets('Ctrl+N 打开手写面板，保存后待办与今日计划同时落地', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _focusPage(tester);

    await _sendCtrl(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(QuickTodoDialog), findsOneWidget, reason: 'Ctrl+N 必须打开手写面板');

    await tester.enterText(_quickField(0), '把周报写完');
    await tester.enterText(_quickField(1), '25');
    await tester.pump();

    await tester.tap(_inQuickDialog(find.text('保存')));
    await _settle(tester);

    // 面板关掉、计划里出现这条 —— 「手写一条」是真的落到计划上，不只是建了个待办。
    // 只断言「看得见」不断言唯一：同一标题在页面里可能被不止一处渲染，
    // 落库是否真的发生由下面两条仓储断言兜住。
    expect(find.byType(QuickTodoDialog), findsNothing);
    expect(find.text('把周报写完'), findsAtLeastNWidgets(1));

    final open = await tester.runAsync(() => harness.repos.todo.listOpen());
    expect(open, isEmpty, reason: '勾了「同时捞入今天」就不该还留在待办池');
    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(items!.map((row) => row.title), contains('把周报写完'));

    await _flushTimers(tester);
  });

  testWidgets('手写面板空标题不写库、也不关面板', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _focusPage(tester);

    await _sendCtrl(tester, LogicalKeyboardKey.keyN);
    await tester.tap(_inQuickDialog(find.text('保存')));
    await _settle(tester);

    expect(find.text('标题不能为空'), findsOneWidget);
    expect(find.byType(QuickTodoDialog), findsOneWidget);

    final open = await tester.runAsync(() => harness.repos.todo.listOpen());
    expect(open, isEmpty);

    await _flushTimers(tester);
  });

  testWidgets('取消勾选「同时捞入今天」只建待办，不动计划', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _focusPage(tester);

    await _sendCtrl(tester, LogicalKeyboardKey.keyN);
    await tester.tap(_inQuickDialog(find.byType(Checkbox)));
    await tester.pump();
    await tester.enterText(_quickField(0), '先攒着以后做');
    await tester.pump();
    await tester.tap(_inQuickDialog(find.text('保存')));
    await _settle(tester);

    final open = await tester.runAsync(() => harness.repos.todo.listOpen());
    expect(open!.map((row) => row.title), contains('先攒着以后做'));
    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(items, isEmpty, reason: '没勾「同时捞入今天」就不该进计划');

    await _flushTimers(tester);
  });

  testWidgets('今日计划段顶部有「从待办池捞」入口，点开可捞入', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await tester.runAsync(() async {
      await harness.repos.todo.create(title: '池子里的A');
    });
    await harness.mount(tester);

    // D-a：入口必须**可见**在段正文里（不是只存在于待办池页）。
    expect(find.text('＋ 从待办池捞'), findsOneWidget);

    await tester.tap(find.text('＋ 从待办池捞'));
    await _settle(tester);
    expect(find.byType(PullFromPoolDialog), findsOneWidget);
    expect(find.text('池子里的A'), findsOneWidget);

    await tester.tap(find.text('捞入'));
    await _settle(tester);

    expect(find.byType(PullFromPoolDialog), findsNothing);
    final items = await tester.runAsync(
      () => harness.repos.planItem.listByDate(_today),
    );
    expect(items!.map((row) => row.title), contains('池子里的A'));

    await _flushTimers(tester);
  });

  testWidgets('待办池为空时面板说明空态', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);

    await tester.tap(find.text('＋ 从待办池捞'));
    await _settle(tester);

    expect(find.byType(PullFromPoolDialog), findsOneWidget);
    expect(find.text('待办池是空的'), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);

    await _flushTimers(tester);
  });

  testWidgets('待办池读不出来时面板显示错误原文', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(
      extra: <Override>[
        todoPoolProvider.overrideWith(
          (ref) async => throw StateError('池子坏了'),
        ),
      ],
    );
    await harness.mount(tester);

    await tester.tap(find.text('＋ 从待办池捞'));
    await _settle(tester);

    expect(find.byType(PullFromPoolDialog), findsOneWidget);
    expect(find.text('池子坏了'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('Esc 关闭手写面板（键条 Esc 一说的真实依据）', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);
    await _focusPage(tester);

    await _sendCtrl(tester, LogicalKeyboardKey.keyN);
    expect(find.byType(QuickTodoDialog), findsOneWidget);

    // 弹层内容已 autofocus（`_settle` 里 pump 过），Esc 由 `ModalRoute` 的
    // `DismissIntent` 处理。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);

    expect(find.byType(QuickTodoDialog), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('Ctrl+D 在没有习惯时给出可见提示，不静默', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    await harness.mount(tester);

    // 前置条件：习惯数据必须已就绪，否则 Ctrl+D 只会走进「还没准备好」这条岔路。
    // B2（2026-11-12）：今日页不再常驻 watch 这两个 provider ⇒ 首次 `read`
    // 只负责触发初始化（返回 loading），所以必须再 settle 一轮才拿得到首帧。
    await _warmUpHabitData(tester, harness);
    expect(
      harness.container.read(habitsForTodayProvider),
      isA<AsyncData<List<HabitData>>>(),
    );
    expect(
      harness.container.read(habitCheckinsProvider),
      isA<AsyncData<List<HabitCheckinData>>>(),
    );

    await _focusPage(tester);
    await _sendCtrl(tester, LogicalKeyboardKey.keyD);

    expect(find.text('今天没有待打卡的习惯'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('Ctrl+D 在未来日拒绝打卡并给出可见提示', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create(selected: _future);
    await harness.mount(tester);

    await _focusPage(tester);
    await _sendCtrl(tester, LogicalKeyboardKey.keyD);

    expect(find.text('未来日只做预排：到了那天再打卡。'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('Ctrl+D 给第一条未打卡习惯落库', (WidgetTester tester) async {
    _useTallSurface(tester);
    final harness = _Harness.create();
    final habitId = await tester.runAsync(
      () => harness.repos.habit.create(name: '晨间跑步', startDate: _today),
    );
    await harness.mount(tester);
    // 先把习惯数据推到就绪：`Ctrl+D` 内部要 `await ...future`，冷启动在
    // 测试的 fake-async 里不会自己推进。
    await _warmUpHabitData(tester, harness);
    await _focusPage(tester);

    await _sendCtrl(tester, LogicalKeyboardKey.keyD);
    // B2（2026-11-12）：页面不再常驻 watch，`Ctrl+D` 内部要等 provider 首帧，
    // 多给一轮真实时间再断言。
    await _settle(tester);

    // 先排除岔路：若落进加载失败分支，这条会先炸，比「找不到提示」更好定位。
    expect(find.textContaining('习惯数据加载失败'), findsNothing);
    expect(find.text('已打卡：晨间跑步'), findsOneWidget);
    final checkins = await tester.runAsync(
      () => harness.repos.habit.watchCheckinsByDate(_today).first,
    );
    expect(checkins!.map((row) => row.habitId), contains(habitId));

    await _flushTimers(tester);
  });
}