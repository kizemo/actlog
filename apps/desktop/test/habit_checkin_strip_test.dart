// apps/desktop/test/habit_checkin_strip_test.dart
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/providers_p1.dart';
import 'package:actlog/src/widgets/habit_checkin_strip.dart';

const String _today = '2026-11-09';
/// 比今天早一天。用来验证「切日跟随」时**不能**取未来日：
/// 未来日只做预排，本组件整条不渲染（spec §H-1），切过去什么都看不到。
const String _yesterday = '2026-11-08';

/// 卡带夹具：内存真库 + 真仓储 + 可切日的 ProviderContainer。
final class _Harness {
  _Harness._(this.db, this.repos, this.container);

  final ActLogDatabase db;
  final ActLogRepositories repos;
  final ProviderContainer container;

  /// 建夹具；`extra` 用来把 provider 钉成 loading 等特定状态。
  ///
  /// `selectedDateProvider` 是 StateProvider，用 `overrideWith` 定初值，
  /// 用例内再改 state 即可切日（写法同 `date_bar_test.dart` / `selected_date_test.dart`）。
  static _Harness create({List<Override> extra = const <Override>[]}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'strip-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
        ...extra,
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先登记关库、后登记销毁容器，
    // 实际顺序是「先 dispose 容器、再 db.close」。反过来会永久挂起：
    // 容器仍持有 drift 流订阅时 `db.close()` 永远等不到流收尾。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(db, repos, container);
  }

  /// 挂上卡带；`onChecked` 用于断言打卡回调。
  Future<void> mount(WidgetTester tester, {void Function(String)? onChecked}) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: HabitCheckinStrip(onChecked: onChecked)),
        ),
      ),
    );
  }
}

/// 把上一轮异步（drift 流查询、provider 重算、写库）全部推完。
///
/// 刻意**不用** `pumpAndSettle`：加载态可能是无限重复动画，
/// `pumpAndSettle` 永远等不到稳定，会一路挂到超时（同 `p1_e2e_test.dart`）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：drift 在 StreamProvider 被 dispose 时会排一个 0 长度 timer，
/// 框架在 tearDown **之前**就检查 pending timer ⇒ 必须在用例体内跑完这帧。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 建一个从 2026-11-01 起每天排程的习惯，返回其 id。
Future<String> _addDailyHabit(_Harness harness, String name) {
  return harness.repos.habit.create(
    name: name,
    scheduleType: 'daily',
    startDate: '2026-11-01',
  );
}

void main() {
  testWidgets('加载态不得谎报空态：loading / 空态 / 失败是三套互斥文案', (tester) async {
    // 真实 drift 查询可能只靠微任务就完成 ⇒ 「靠首帧时序断言 loading」不可靠，
    // 直接把习惯列表 provider 钉成 AsyncLoading 才是确定性判据。
    final harness = _Harness.create(
      extra: <Override>[
        habitsForTodayProvider.overrideWithValue(
          const AsyncLoading<List<HabitData>>(),
        ),
      ],
    );

    await harness.mount(tester);

    expect(find.text(HabitCheckinStrip.loadingLabel), findsOneWidget);
    expect(find.text(HabitCheckinStrip.emptyLabel), findsNothing);
    expect(find.text(HabitCheckinStrip.errorLabel), findsNothing);
    await _flushTimers(tester);
  });

  testWidgets('逐个渲染当天待打卡习惯：未打卡 ○、已打卡 ✓', (tester) async {
    final harness = _Harness.create();
    await _addDailyHabit(harness, '晨间写作');
    final eveningId = await _addDailyHabit(harness, '晚间复盘');
    await harness.repos.habit.upsertCheckin(
      habitId: eveningId,
      date: _today,
      status: CheckinStatus.done,
    );

    await harness.mount(tester);
    await _settle(tester);

    expect(find.text('晨间写作'), findsOneWidget);
    expect(find.text('晚间复盘'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
    expect(find.text('○'), findsOneWidget);
    await _flushTimers(tester);
  });

  testWidgets('点一下即把所选日写为 done，并通过 onChecked 告知习惯名', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');
    final tapped = <String>[];

    await harness.mount(tester, onChecked: tapped.add);
    await _settle(tester);
    expect(find.text('○'), findsOneWidget);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);

    final checkin = await harness.repos.habit.findCheckin(habitId, _today);
    expect(checkin, isNotNull);
    expect(checkin!.status, CheckinStatus.done.code);
    expect(tapped, <String>['晨间写作']);
    expect(find.text('✓'), findsOneWidget);
    await _flushTimers(tester);
  });

  testWidgets('已打卡再点 = 撤销（软删），且回调不再触发', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');
    final tapped = <String>[];

    await harness.mount(tester, onChecked: tapped.add);
    await _settle(tester);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    await tester.tap(find.text('晨间写作'));
    await _settle(tester);

    expect(await harness.repos.habit.findCheckin(habitId, _today), isNull);
    expect(tapped, <String>['晨间写作']);
    expect(find.text('○'), findsOneWidget);
    // 软删后 live 查询看不到该行（墓碑仍占着 UNIQUE(habit_id,date) 槽位，见下一例）。
    expect(
      await harness.repos.habit.listCheckinsRange(_today, _today),
      isEmpty,
    );
    await _flushTimers(tester);
  });

  testWidgets('撤销后再打卡复用同一 (habit_id,date) 行，不新增第二条', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');
    final tapped = <String>[];

    await harness.mount(tester, onChecked: tapped.add);
    await _settle(tester);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    final afterFirst = await harness.repos.habit.findCheckin(habitId, _today);
    final firstId = afterFirst!.id;

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    await tester.tap(find.text('晨间写作'));
    await _settle(tester);

    final again = await harness.repos.habit.findCheckin(habitId, _today);
    expect(again, isNotNull);
    expect(again!.status, CheckinStatus.done.code);
    // id 不变 ⇒ 复用同一行（撤销再打卡不会破 UNIQUE，也不留双行）。
    expect(again.id, firstId);
    expect(tapped, <String>['晨间写作', '晨间写作']);
    await _flushTimers(tester);
  });

  testWidgets('切换所选日后卡带跟随所选日（钉死 provider 改读 selectedDate）', (tester) async {
    final harness = _Harness.create();
    final habitId = await _addDailyHabit(harness, '晨间写作');

    await harness.mount(tester);
    await _settle(tester);

    await tester.tap(find.text('晨间写作'));
    await _settle(tester);
    expect(find.text('✓'), findsOneWidget);

    harness.container.read(selectedDateProvider.notifier).state = _yesterday;
    await _settle(tester);

    // 所选日换成昨天：习惯仍在排程，但昨天没有打卡记录。
    expect(find.text('晨间写作'), findsOneWidget);
    expect(find.text('✓'), findsNothing);
    expect(find.text('○'), findsOneWidget);
    expect(
      await harness.repos.habit.findCheckin(habitId, _yesterday),
      isNull,
    );
    // 今天的记录不受影响 ⇒ 查询按「所选日」而非「今天」。
    expect(
      await harness.repos.habit.findCheckin(habitId, _today),
      isNotNull,
    );
    await _flushTimers(tester);
  });
}