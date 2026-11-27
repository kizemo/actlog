// apps/desktop/test/ledger_dock_test.dart
//
// B2（2026-11-12）：打卡条（`HabitCheckinStrip`）不再是壳层的 `.dock` 独立行。
// 用户指令 8 要求 `app.dart` 去掉 `_dock()`（连同 `LedgerShell` 的 `dock:` 实参），
// 打卡入口整体搬到「习惯」页（`lib/src/pages/habits_page.dart`）；B17 起
// 「习惯」退出导航清单，入口改由壳的 `initialNavId: 'habits'` 直达。
//
// 本文件因此从「守住那一行的几何」改为守住三件事：
// ① 壳层底部**不再有**快捷键条那一行（Task 56 诉求③：底部那份删掉、右轨那份保留）：
//    账页下沿直接贴住视口底边，它下面不再有第二个布局行；
// ② 任何页面（今日 / 待办池 / 日历 / 未来日）都不再挂 `HabitCheckinStrip`；
// ③ 打卡能力没丢：习惯页的复选框仍走真库（`upsertCheckin` / `deleteCheckin`），
//    不放内存假态。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/habit_checkin_strip.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';
const String _future = '2026-11-12';

/// 内存真库 + 真仓储 + 固定今天 / 可指定选中日。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({String selected = _today}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'dock-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 挂完整壳宿主（与真机一致；壳层现在没有 `dock` 槽位可填）。
  Future<void> mount(
    WidgetTester tester, {
    String initialNavId = ShellHost.kTodayNavId,
  }) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nScope(
          MaterialApp(home: ShellHost(initialNavId: initialNavId)),
        ),
      ),
    );
  }

  /// 建一个从 2026-11-01 起每天排程的习惯，返回其 id。
  Future<String> addDailyHabit(String name) {
    return repos.habit.create(
      name: name,
      scheduleType: 'daily',
      startDate: '2026-11-01',
    );
  }
}

/// 宽屏面：1400 ≥ 1280 ⇒ 走竖排导航 + 右轨（`_buildWide`）。
void _useWideSurface(WidgetTester tester) {
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

/// 收尾：卸掉界面放掉 drift 流订阅（框架在 tearDown 之前就查 pending timer）。
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

/// 视口底边（逻辑像素）：键条是壳层列最后一行时，它的下沿必须落在这里。
double _viewportBottom(WidgetTester tester) => 3000;

/// 导航栏里的那一项（今日页正文也出现同名文字，不能全树搜）。
Finder _navItem(String label) => find.descendant(
  of: find.byType(NavRail),
  matching: find.text(label),
);

void main() {
  testWidgets('壳层底部没有快捷键条那一行：账页贴视口底边，打卡条不在', (tester) async {
    _useWideSurface(tester);
    final harness = _Harness.create();
    await harness.addDailyHabit('晨间写作');
    await harness.mount(tester);
    await _settle(tester);

    // ① 打卡条不再是壳层的一行 —— 连条头文案都不出现。
    expect(find.byType(HabitCheckinStrip), findsNothing);
    expect(find.text(HabitCheckinStrip.headTitle), findsNothing);

    // ② Task 56 诉求③：底部快捷键条已删除 —— 壳层列里不再有那一行，
    // 账页下沿直接落到视口底边（下面没有任何布局行）。
    expect(
      find.byType(KeyBar),
      findsNothing,
      reason: '底部快捷键条必须删除（快捷键清单只在右轨出现）',
    );
    expect(
      find.byKey(const Key('shell-keybar')),
      findsNothing,
      reason: '壳层不得再装配底部键条（`shell-keybar`）',
    );
    expect(
      tester.getRect(find.byKey(const Key('shell-ledger-paper'))).bottom,
      moreOrLessEquals(_viewportBottom(tester), epsilon: 0.5),
      reason: '键条删除后账页下沿必须贴住视口底边 ⇒ 它下面没有多出一行',
    );

    // ③ 右轨那份「快捷键」清单必须保留：底部删了，右轨还在。
    expect(find.byType(KeyHintList), findsOneWidget);
    expect(find.text('快捷键'), findsOneWidget);
    expect(find.text('Ctrl+N'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('切到待办池与日历：同样没有打卡条这一行', (tester) async {
    _useWideSurface(tester);
    final harness = _Harness.create();
    await harness.addDailyHabit('晨间写作');
    await harness.mount(tester);
    await _settle(tester);

    expect(find.byType(HabitCheckinStrip), findsNothing);

    await tester.tap(_navItem('待办池'));
    await _settle(tester);

    expect(find.byType(HabitCheckinStrip), findsNothing);
    expect(find.text(HabitCheckinStrip.headTitle), findsNothing);
    expect(
      find.byType(KeyBar),
      findsNothing,
      reason: '待办池页同样不得出现底部快捷键条',
    );
    expect(
      find.byType(KeyHintList),
      findsOneWidget,
      reason: '待办池页右轨仍须保留「快捷键」清单',
    );

    await tester.tap(_navItem('日历'));
    await _settle(tester);

    expect(find.byType(HabitCheckinStrip), findsNothing);
    expect(
      find.byType(KeyBar),
      findsNothing,
      reason: '日历页同样不得出现底部快捷键条',
    );
    expect(
      find.byType(KeyHintList),
      findsOneWidget,
      reason: '日历页右轨仍须保留「快捷键」清单',
    );

    await _flushTimers(tester);
  });

  testWidgets('打卡入口搬到习惯页：勾选仍走真库往返', (tester) async {
    _useWideSurface(tester);
    final harness = _Harness.create();
    final habitId = await harness.addDailyHabit('晨间写作');
    // B17：导航已去掉「习惯」项，打卡入口改由壳的 `initialNavId: 'habits'`
    // 直达（`app.dart` `_content()` 仍保留 `'habits'` 落点）。
    await harness.mount(tester, initialNavId: 'habits');
    await _settle(tester);

    // 习惯页承接了原来打卡条的功能，但壳层不再有那一行。
    expect(find.byType(HabitCheckinStrip), findsNothing);
    final Finder box = find.byKey(ValueKey<String>('habit-check-$habitId'));
    expect(box, findsOneWidget, reason: '习惯页必须给每条习惯一枚可点复选框');

    // 勾上：真库要有 done 记录（不是内存假态）。
    await tester.tap(box);
    await _settle(tester);
    final afterCheck = await harness.repos.habit.findCheckin(habitId, _today);
    expect(afterCheck, isNotNull);
    expect(afterCheck!.status, CheckinStatus.done.code);
    expect(
      tester.widget<LedgerCheckbox>(box).value,
      isTrue,
      reason: '落库后复选框必须读回 done 态',
    );

    // 再点一次撤销：记录要真的被删掉。
    await tester.tap(box);
    await _settle(tester);
    expect(await harness.repos.habit.findCheckin(habitId, _today), isNull);
    expect(
      tester.widget<LedgerCheckbox>(box).value,
      isFalse,
      reason: '撤销后复选框必须读回未打卡态',
    );

    await _flushTimers(tester);
  });

  testWidgets('未来日：打卡条同样不出现，未来提示仍在', (tester) async {
    _useWideSurface(tester);
    final harness = _Harness.create(selected: _future);
    // 习惯本身是在排程内的 —— 不出现的原因只能是「壳层已不挂它」，不是空清单。
    await harness.addDailyHabit('晨间写作');
    await harness.mount(tester);
    await _settle(tester);

    expect(find.byType(HabitCheckinStrip), findsNothing);
    expect(find.text(HabitCheckinStrip.headTitle), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('future-plan-hint')),
      findsOneWidget,
      reason: '未来日仍须给出「只可预排」的可见提示',
    );

    await _flushTimers(tester);
  });
}