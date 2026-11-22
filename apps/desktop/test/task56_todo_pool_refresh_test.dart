// apps/desktop/test/task56_todo_pool_refresh_test.dart
//
// Task 56 · 诉求 2 · 同会话刷新：项目页排期 ⇒ 待办池必须当场重查。
//
// 根因（已坐实）：`todoPoolProvider` 是 `FutureProvider`，内容 = `status='open'`
// 且未删除，**与日期无关** ⇒ 它不会自动重查，写库后必须显式 `ref.invalidate`。
// 项目页此前只做页面级 `_reload()`（重读 project / milestone），没失效池子，于是
// 同会话内「待办池页 / 首页右轨」一直显示「0 条待捞」，诉求 2 的下一环
// （「加入主页计划」按钮）根本不存在。
//
// 本文件钉两条**判别性**用例（缺修复必红、修复后必绿）：
//   R1：项目页新增一条排了期的任务 ⇒ 池子重查 ⇒ 池里有它；
//   R2：项目页改期 ⇒ 池子里那条待办的 `due_date` 跟着更新（不是旧日期）。
//
// 口径是**provider 的真值**：先读一次把「空池」缓存下来，再走真界面写库，
// 最后读同一个 provider —— 没失效就读到旧缓存（这正是修复前的行为）。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/l10n/l10n_scope.dart';
import 'package:actlog/src/pages/projects_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/providers_p1.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Todo;
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

const String _today = '2026-11-09';
const String _targetDate = '2026-11-05';
const String _newDate = '2026-11-06';

/// 内存真库 + 真仓储 + 可切日的 ProviderContainer。
final class _Harness {
  _Harness._(this.container, this.db, this.repos);

  final ProviderContainer container;
  final ActLogDatabase db;
  final ActLogRepositories repos;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task56-todo-pool-refresh-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // LIFO ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, db, repos);
  }

  /// 项目页是内容体（自带 Scaffold 的宿主由调用方给）。
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: L10nScope(
          localizations: AppLocalizations.zh,
          child: const MaterialApp(
            home: Scaffold(body: ProjectsPage()),
          ),
        ),
      ),
    );
  }
}

/// 撑高测试面：甘特图 + 项目卡在 800×600 下会被挤。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 按提示文案找输入框（项目页的输入框没有 key）。
Finder _fieldByHint(String hint) => find.byWidgetPredicate(
      (Widget w) => w is TextField && w.decoration?.hintText == hint,
      description: 'TextField(hint: $hint)',
    );

/// 读待办池 provider 的真值（不是界面像素）。
Future<List<Todo>> _readPool(WidgetTester tester, _Harness harness) async {
  final List<Todo>? pool = await tester.runAsync(
    () => harness.container.read(todoPoolProvider.future),
  );
  return pool ?? const <Todo>[];
}

void main() {
  testWidgets('R1：项目页排一条任务 ⇒ 待办池当场重查（池里有这条）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    // 先把「空池」缓存下来 —— 这一步就是修复前漏掉的那一环的前提。
    expect(await _readPool(tester, harness), isEmpty, reason: '开局池子为空');

    final AppLocalizations t = AppLocalizations.zh;

    // 新建项目。
    await tester.enterText(_fieldByHint(t.projectsNameHint), '甲');
    await tester.pump();
    await tester.tap(find.text(t.projectsNewProjectAction));
    await _settle(tester);

    // 新增一条**排了期**的任务 ⇒ 库里会落一条 `open` 待办。
    await tester.enterText(_fieldByHint(t.projectsTaskTitleHint), '写文档');
    await tester.enterText(_fieldByHint(t.projectsTargetDateHint), _targetDate);
    await tester.pump();
    await tester.tap(find.text(t.projectsAddTaskAction));
    await _settle(tester);

    // 库里确实有这条（写库成功）。
    final List<Todo> stored =
        await tester.runAsync(() => harness.repos.todo.listOpen()) ??
            const <Todo>[];
    expect(stored, hasLength(1), reason: '排了期就该在库里落一条待办');
    expect(stored.single.title, '写文档');
    expect(stored.single.dueDate, _targetDate);

    // 池子必须**重新查询** ⇒ 拿到新值，而不是开局的空缓存。
    final List<Todo> pool = await _readPool(tester, harness);
    expect(
      pool.map((Todo todo) => todo.title),
      contains('写文档'),
      reason: '池子是 FutureProvider ⇒ 写库后必须 invalidate，否则读到的还是空缓存',
    );
    expect(pool.single.dueDate, _targetDate);

    await _flushTimers(tester);
  });

  testWidgets('R2：项目页改期 ⇒ 池子里那条待办的到期日跟着更新', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    expect(await _readPool(tester, harness), isEmpty);

    final AppLocalizations t = AppLocalizations.zh;

    await tester.enterText(_fieldByHint(t.projectsNameHint), '甲');
    await tester.pump();
    await tester.tap(find.text(t.projectsNewProjectAction));
    await _settle(tester);

    await tester.enterText(_fieldByHint(t.projectsTaskTitleHint), '写文档');
    await tester.enterText(_fieldByHint(t.projectsTargetDateHint), _targetDate);
    await tester.pump();
    await tester.tap(find.text(t.projectsAddTaskAction));
    await _settle(tester);

    // 池子已经看到这条（第一次失效生效了）。
    expect(await _readPool(tester, harness), hasLength(1));

    // 改期：对话框里填新日期。
    await tester.tap(find.text(t.projectsRescheduleAction));
    await tester.pump();
    final Finder dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      _newDate,
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: dialog, matching: find.text(t.confirm)),
    );
    await _settle(tester);

    // 库里到期日已更新。
    final List<Todo> stored =
        await tester.runAsync(() => harness.repos.todo.listOpen()) ??
            const <Todo>[];
    expect(stored, hasLength(1), reason: '改期幂等：仍只有一条');
    expect(stored.single.dueDate, _newDate);

    // 池子里那一条也必须显示新日期（否则用户看到的还是旧日期）。
    final List<Todo> pool = await _readPool(tester, harness);
    expect(pool, hasLength(1));
    expect(
      pool.single.dueDate,
      _newDate,
      reason: '改期改了待办的 due_date ⇒ 池子必须 invalidate 重查',
    );

    await _flushTimers(tester);
  });
}
