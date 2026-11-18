// apps/desktop/test/task39_habit_dup_test.dart
//
// Task 39 · 回归：「添加习惯」一次却出两条（指令 3）。
//
// 缺陷已坐实（W6）：`HabitQuickDialog._submit()` 在 `navigator.pop()` 之后由
// `finally` 无条件复位 `_submitting`，而弹层退出动画（反向过渡）期间两个
// TextField 的 `onSubmitted: (_) => _submit()` 仍然活着 ⇒ 退出窗口内到达的
// 第二次回车会再走一遍 `habit.create`（`create` 每次用新 `uuidV7()`，不撞主键，
// 于是落第二行习惯 + 第二条 oplog）。
//
// 修复：新增一次性终态标志 `_done`，只在成功路径（`pop()` 之前）置位；入口守卫
// 改为 `if (_submitting || _done) return;`；`finally` 只在未完成时才复位
// `_submitting` ⇒ 成功路径保持锁死，失败路径仍可重试。
//
// 本文件钉四条：
//   1. A5：一次回车提交 ⇒ 库里一条习惯，`listScheduledFor(今天)` 一条；
//   2. A6：同一帧连点两次「保存」⇒ 仍只有一条；且退出动画窗口内输入框与
//      保存按钮都保持锁死（`enabled == false` / `onTap == null`）。后半段对
//      W6 的「成功路径不复位 `_submitting`」具判别性 —— 撤掉修复即刻变红。
//      （旧版 A6 只用 `warnIfMissed: false` 假装点中已卸载的按钮，那是对着
//      像素造假绿；坑 57 之后一律改为状态断言。）
//   3. A7：**判别性**用例。绕过指针层，直调 `TextField.onSubmitted`
//      （IME 回车 / 键盘重复走的就是这条回调），撤掉修复必失败。
//   4. A8：真实落库失败（SQLite 触发器 `RAISE(ABORT)` 注入）后不锁死：
//      错误透出、输入仍可编辑，`DROP TRIGGER` 后重试必须落一条。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/habit_quick_dialog.dart';

const String _today = '2026-11-09';
const ValueKey<String> _openKey = ValueKey<String>('test-open-habit-dialog');

final class _Harness {
  _Harness._(this.container, this.db);

  final ProviderContainer container;
  final ActLogDatabase db;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task39-habit-dup-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, db);
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: TextButton(
                  key: _openKey,
                  onPressed: () => showHabitQuickDialog(context),
                  child: const Text('添加习惯'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 保存会连写「习惯 + 若干 plan_item」，给它更长的真实时间。
Future<void> _settleAfterSave(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

Future<List<HabitData>> _habits(WidgetTester tester, ActLogDatabase db) async {
  final List<HabitData>? rows = await tester.runAsync(
    () => db.select(db.habit).get(),
  );
  return rows ?? const <HabitData>[];
}

/// `oplog` 里 `entity_table='habit'` 的写入条数。
///
/// 比 `habit` 表行数更硬：`create` 每次都用新 `uuidV7()`，第二次提交不会撞主键，
/// 而是各自写一条 oplog —— 所以「一条 oplog」= 「只落库一次」。
Future<int> _habitOplogWrites(WidgetTester tester, ActLogDatabase db) async {
  final int? count = await tester.runAsync(() async {
    final List<OplogData> rows = await db.select(db.oplog).get();
    return rows.where((OplogData o) => o.entityTable == 'habit').length;
  });
  return count ?? -1;
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(_openKey));
  await _settle(tester);
}

/// 只填名字 + 回车提交（回车走 `onSubmitted`，与点「保存」同一个 `_submit`）。
Future<void> _typeNameAndSubmitByEnter(
  WidgetTester tester,
  String name,
) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('habit-dialog-name')),
    name,
  );
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.done);
}

void main() {
  testWidgets('A5 · 一次回车提交 ⇒ 一条习惯，速览只排到一条', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _openDialog(tester);

    await _typeNameAndSubmitByEnter(tester, '读书 20 分钟');
    await _settleAfterSave(tester);

    final List<HabitData> rows = await _habits(tester, harness.db);
    expect(rows, hasLength(1), reason: '一次提交只该落一行习惯');

    // 走「习惯速览」那条真实查询（`habitsForTodayProvider` 底层就是它），
    // 直接钉住显示侧不会把一条习惯排成两条。
    final List<HabitData>? today = await tester.runAsync(
      () => harness.container
          .read(repositoriesProvider)
          .habit
          .listScheduledFor(_today),
    );
    expect(
      (today ?? const <HabitData>[])
          .where((HabitData h) => h.name == '读书 20 分钟'),
      hasLength(1),
      reason: '习惯速览同一习惯只该排一条',
    );

    await _flushTimers(tester);
  });

  // 特征钉（characterization）：两处断言都不依赖「点没点中」。
  //
  //   1. 同一帧连点两次「保存」⇒ 第二击被入口守卫
  //      `if (_submitting || _done) return;` 拦下，库里仍只有一行；
  //   2. 退出动画窗口内输入框 `enabled == false`、保存按钮 `onTap == null`
  //      ⇒ 钉住「成功路径不复位 `_submitting`」。这半段是**判别性**的：
  //      把 `finally` 改回无条件复位，第 2 条立刻红。
  //
  // 不再使用 `warnIfMissed: false`：两击都必须在真的可点状态下命中，
  // 「点不中」不是证据（坑 57）。
  testWidgets('A6 · 同一帧连点两次保存 ⇒ 只落一条，退场窗口入口保持锁死', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _openDialog(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('habit-dialog-name')),
      '晨间拉伸',
    );
    await tester.pump();

    // 两击之间**不 pump**：第二击打到的仍是同一帧里那个还没被重建掉的
    // `onTap`，与「手快双击 / 回车键重复」是同一条真实路径。
    final Finder save = find.text('保存');
    expect(save, findsOneWidget, reason: '弹层打开后保存按钮必须可见');
    await tester.tap(save);
    await tester.tap(save);

    // 让第一次提交真正跑完（`pop()` 已发起、`finally` 已执行），
    // 但只推进一帧：退场动画还没走完，弹层仍 mounted。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      find.byKey(const ValueKey<String>('habit-quick-dialog')),
      findsOneWidget,
      reason: '这一帧里退场动画还没走完，弹层应当仍 mounted',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('habit-dialog-name')),
          )
          .enabled,
      isFalse,
      reason: '成功提交后到真正卸载之前，输入框不得重新可编辑',
    );
    expect(
      tester.widget<InkWell>(find.widgetWithText(InkWell, '保存')).onTap,
      isNull,
      reason: '成功提交后保存按钮必须保持禁用，退场窗口不能再触发一次 `_submit`',
    );

    await _settleAfterSave(tester);

    final List<HabitData> rows = await _habits(tester, harness.db);
    expect(
      rows.where((HabitData h) => h.name == '晨间拉伸'),
      hasLength(1),
      reason: '连点两次保存只该落一行习惯',
    );
    expect(
      await _habitOplogWrites(tester, harness.db),
      1,
      reason: '只该有一条 habit oplog upsert',
    );

    await _flushTimers(tester);
  });

  // A7 是本轮的**判别性**用例（撤掉修复必须失败）。
  //
  // 第二次触发不能沿用 A6 的 `tap`：反向过渡期 `IgnorePointer(ignoring: true)`
  // 会把它静默吞掉（routes.dart:1220-1222）；也不能用
  // `tester.testTextInput.receiveAction`：`pop()` 之后输入连接已断，是静默
  // no-op（W6 两次探针均绿，已排除）。这里直调 `TextField.onSubmitted` ——
  // 生产代码里它就是 `(_) => _submit()`，与 IME 回车 / 键盘重复是同一条回调，
  // 两次触发对称。
  testWidgets('A7 · 退出动画未走完时再提交一次 ⇒ 不得再落一条（判别性）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _openDialog(tester);

    final Finder nameFinder =
        find.byKey(const ValueKey<String>('habit-dialog-name'));
    await tester.enterText(nameFinder, '晨间拉伸');
    await tester.pump();

    // 第一次提交：直调生产代码的同一条回调。
    tester.widget<TextField>(nameFinder).onSubmitted!('晨间拉伸');
    // 让落库与 `finally` 跑完，刻意**不 pump**：`pop()` 与
    // `setState(() => _submitting = false)` 在同一段微任务里先后发生，而反向
    // 过渡的 `IgnorePointer` / `canRequestFocus = false` 要等**下一帧**重建
    // `_ModalScope` 才生效（routes.dart:1220-1222）⇒ 此刻正是缺陷窗口：
    // `_submitting` 已复位、弹层仍 mounted、`onSubmitted` 仍可调。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );

    expect(
      find.byKey(const ValueKey<String>('habit-quick-dialog')).evaluate(),
      hasLength(1),
      reason: '这一帧里弹层仍 mounted ⇒ 缺陷窗口成立',
    );
    expect(
      await _habits(tester, harness.db),
      hasLength(1),
      reason: '第一次提交只该落一条习惯',
    );

    // 第二次提交：同一个生产入口，对称调用。
    tester.widget<TextField>(nameFinder).onSubmitted!('晨间拉伸');
    await _settleAfterSave(tester);

    final List<HabitData> rows = await _habits(tester, harness.db);
    expect(
      rows.where((HabitData h) => h.name == '晨间拉伸'),
      hasLength(1),
      reason: '退出动画窗口内的第二次提交不得再落一条习惯（第 2 次落库）',
    );
    expect(
      await _habitOplogWrites(tester, harness.db),
      1,
      reason: 'habit 只应有一条 oplog upsert（第 2 条 oplog 记录即重复落库）',
    );

    await _flushTimers(tester);
  });

  // A8 钉住修复的**另一半**：`_done` 只在成功路径置位，异常路径必须复位
  // `_submitting`。否则「落库失败」会变成不可重试的死按钮 —— 那是本修复的
  // 主要回归风险（把口子堵死顺手把退路也堵了）。
  //
  // 故障源必须是**真实写入路径**上的失败，不能靠 provider 抛异常伪造：
  // `ActLogRepositories` / `HabitRepository` 都是 `final class` 改不动，而在
  // `repositoriesProvider` 上抛 `StateError` 只是换了处地方造假 —— 那次失败
  // 根本没走到 SQLite。这里直接给 `habit` 表挂 `BEFORE INSERT` 触发器
  // `RAISE(ABORT)`：异常从 drift 的 `insert` 里抛出，与「磁盘写满 / 约束冲突」
  // 是同一条代码路径；`OplogWriter.writeWithOplog` 先执行业务写入、后落 oplog
  // 且全程在同一事务内（`oplog_writer.dart:115-123`），所以回滚后 habit 行与
  // habit oplog 都不会留下。`DROP TRIGGER` 即恢复，不需要 invalidate provider。
  testWidgets('A8 · 真实落库失败后不锁死：错误可见、可再次提交成功（可重试）', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _openDialog(tester);

    const String triggerMessage = '落库失败（真实 SQLite 触发器注入）';
    await tester.runAsync(
      () => harness.db.customStatement(
        'CREATE TRIGGER habit_insert_fail BEFORE INSERT ON habit '
        "BEGIN SELECT RAISE(ABORT, '$triggerMessage'); END;",
      ),
    );

    final Finder nameFinder =
        find.byKey(const ValueKey<String>('habit-dialog-name'));
    await tester.enterText(nameFinder, '晨间拉伸');
    await tester.pump();

    await tester.tap(find.text('保存'));
    await _settleAfterSave(tester);

    // 只匹配触发器消息里那句独有的中文，避开 drift 前缀
    // （`SqliteException(...)`）在不同版本下的措辞差异 —— 仍是引擎原话。
    expect(
      find.textContaining('真实 SQLite 触发器注入'),
      findsOneWidget,
      reason: '引擎给出的失败原因要如实透出给用户',
    );
    expect(
      find.byKey(const ValueKey<String>('habit-quick-dialog')),
      findsOneWidget,
      reason: '失败不得关窗，用户要能接着改',
    );
    expect(
      tester.widget<TextField>(nameFinder).enabled,
      isTrue,
      reason: '失败后必须复位 `_submitting`，否则输入框永久不可编辑、无法重试',
    );
    expect(
      tester.widget<InkWell>(find.widgetWithText(InkWell, '保存')).onTap,
      isNotNull,
      reason: '失败后保存按钮必须重新可点',
    );
    expect(
      await _habits(tester, harness.db),
      isEmpty,
      reason: '失败时不该落任何行（事务回滚）',
    );
    expect(
      await _habitOplogWrites(tester, harness.db),
      0,
      reason: '业务写入抛错后 oplog 必须一起回滚，不能留下「改了但没落库」的痕',
    );

    // 排除故障源 ⇒ 同一个入口重试必须落库（终态标志不得把退路堵死）。
    await tester.runAsync(
      () => harness.db.customStatement('DROP TRIGGER habit_insert_fail'),
    );
    tester.widget<TextField>(nameFinder).onSubmitted!('晨间拉伸');
    await _settleAfterSave(tester);

    expect(
      (await _habits(tester, harness.db)).where(
        (HabitData h) => h.name == '晨间拉伸',
      ),
      hasLength(1),
      reason: '失败重试后应当落一条，且只一条',
    );
    expect(
      await _habitOplogWrites(tester, harness.db),
      1,
      reason: '重试成功后只该有一条 habit oplog',
    );
    expect(
      find.byKey(const ValueKey<String>('habit-quick-dialog')),
      findsNothing,
      reason: '重试成功后弹层要关掉',
    );

    await _flushTimers(tester);
  });
}