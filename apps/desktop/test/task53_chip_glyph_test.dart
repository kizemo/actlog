// apps/desktop/test/task53_chip_glyph_test.dart
//
// Task 53 · 诉求 3 的验收面（用户原话逐字引用）：
//   「任务的前面已经有了点击可以勾选代表完成的选择框，后面的圆圈可以去除。
//     已经勾选完成的任务，也不用显示后面的对号，不要显示删除线。」
//
// 判据分三类，缺一条都会让过度删除 / 删漏悄悄过关：
//   A 删干净 —— plannedOpen 不再有尾部 `○`(U+25CB)、done 不再有尾部 `✓`(U+2713)，
//     done 的标题不再有删除线；
//   B 没删多 —— habit `●`(U+25CF) 与 backfill `▶`(U+25B6) 必须仍在（它们表达
//     「任务类型」，不是完成态）；
//   C 没误伤 —— 前置勾选框（`LedgerCheckbox`，`Text` 通道）的 `○` / `✓` 必须
//     仍在，且各态条目里恰好一个。
//
// 为什么必须分开「尾字形」与「勾选框」两条通道来断言：尾部字形是 `RichText`
// （`fontFamily == AppFonts.body`），勾选框是 `Text`（`fontFamily ==
// AppFonts.mono`，见 `ledger_checkbox.dart:111-120`）。`find.text` 只匹配
// `Text` / `EditableText`，碰不到 `RichText` —— 直接用 `find.text('○')`
// 数「剩几个圆」会把两种通道混成一条读数，删错了也看不出来。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';

/// 固定「今天」，与被测日期分开，才能确定性地构造回填 / 未来。
const String _today = '2026-11-09';

/// 过去日：整日都算回填。
const String _past = '2026-11-08';

/// 未来日：全不算回填 ⇒ 能拿到 `SlotKind.done` / `plannedOpen`。
const String _future = '2026-11-10';

/// 尾部字形的两个保留项（表达任务类型，不是完成态）。
const String _habitGlyph = '\u25CF'; // ●
const String _backfillGlyph = '\u25B6'; // ▶

/// 尾部字形的两个删除项（与前置勾选框的未选 / 选中态重复）。
const String _plannedOpenGlyph = '\u25CB'; // ○
const String _doneGlyph = '\u2713'; // ✓

final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task53-glyph-test');
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

  Future<void> mount(WidgetTester tester, String date) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: DayGrid(date: date))),
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

/// 等真库流回来（与 `timeline_day_grid_test.dart` 同一口径）。
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

Finder _entry(String id) =>
    find.byKey(ValueKey<String>('day-grid-entry-$id'));

/// 条目里「尾部字形」通道的候选：`RichText` + 正文字族 + 单字符。
///
/// 与 `timeline_day_grid_test.dart` 的 `_renderedGlyph` 同一套定位条件，但这里
/// **不要求恰好一个**：本文件要判的正是「还有没有」与「还剩几个」。
List<String> _tailGlyphs(WidgetTester tester, String planItemId) {
  return tester
      .widgetList<RichText>(
        find.descendant(of: _entry(planItemId), matching: find.byType(RichText)),
      )
      .where(
        (RichText rich) =>
            rich.text.style?.fontFamily == AppFonts.body &&
            rich.text.toPlainText().runes.length == 1,
      )
      .map((RichText rich) => rich.text.toPlainText())
      .toList();
}

/// 条目里标题 `Text` 的样式（删除线判据）。
TextStyle _titleStyle(WidgetTester tester, String planItemId, String title) {
  return tester
      .widget<Text>(
        find.descendant(
          of: _entry(planItemId),
          matching: find.text(title),
        ),
      )
      .style!;
}

/// 未来日造一条 `plannedOpen`（不勾选）。
Future<String> _openEntry(_Harness h, String title, int start) async {
  return (await TimelineStore(h.repos).createManual(
    date: _future,
    title: title,
    startMinute: start,
    endMinute: start + 15,
    todayIso: _today,
    nowMinute: 0,
  ));
}

void main() {
  group('Task 53 · 诉求 3：删尾部 ○ / ✓ 与 done 删除线，保留 ● / ▶ 与勾选框', () {
    testWidgets('plannedOpen：尾部无 ○；勾选框的 ○ 仍在且恰好一个', (tester) async {
      _useTallSurface(tester);
      final _Harness h = _Harness.create(selected: _future);
      final String id = await _openEntry(h, '预排：评审', 10 * 60);

      await h.mount(tester, _future);
      await _settle(tester);

      // A：尾部 `○` 必须没了 —— 用 RichText 通道判，不受勾选框干扰。
      expect(
        _tailGlyphs(tester, id),
        isNot(contains(_plannedOpenGlyph)),
        reason: '任务块尾部仍有 ○（与前置勾选框未选态重复）',
      );
      expect(_tailGlyphs(tester, id), isEmpty, reason: 'plannedOpen 不该再有任何尾部字形');

      // C：勾选框自身的 `○` 必须还在（`Text` 通道，mono 字族）。
      expect(
        find.descendant(of: _entry(id), matching: find.text(_plannedOpenGlyph)),
        findsOneWidget,
        reason: '前置勾选框的 ○ 被误删 —— 未完成态就无处表达了',
      );

      // plannedOpen 本来就不划线，反向对照防止「到处都划线」也判绿。
      expect(_titleStyle(tester, id, '预排：评审').decoration, isNull);

      await _flushTimers(tester);
    });

    testWidgets('done：尾部无 ✓、标题无删除线；勾选框的 ✓ 仍在且恰好一个', (tester) async {
      _useTallSurface(tester);
      final _Harness h = _Harness.create(selected: _future);
      final String id = await _openEntry(h, '已完成：写周报', 10 * 60);
      await tester.runAsync(
        () => h.repos.planItem.setStatus(id, PlanStatus.done),
      );

      await h.mount(tester, _future);
      await _settle(tester);

      // A：尾部 `✓` 必须没了。
      expect(
        _tailGlyphs(tester, id),
        isNot(contains(_doneGlyph)),
        reason: '任务块尾部仍有 ✓（与前置勾选框选中态重复）',
      );
      expect(_tailGlyphs(tester, id), isEmpty, reason: 'done 不该再有任何尾部字形');

      // A：标题不再有删除线（三重通道里砍掉的就是这一重）。
      final TextStyle style = _titleStyle(tester, id, '已完成：写周报');
      expect(
        style.decoration,
        isNull,
        reason: '完成态标题仍有删除线（${style.decoration}）',
      );

      // C：勾选框自身的 `✓` 必须还在且恰好一个 —— 完成态改由它 + 前景色表达。
      expect(
        find.descendant(of: _entry(id), matching: find.text(_doneGlyph)),
        findsOneWidget,
        reason: '前置勾选框的 ✓ 被误删 —— 完成态就只剩颜色了',
      );

      await _flushTimers(tester);
    });

    testWidgets('backfill 无尾部 ▶、habit 保留 ●（Task 54 翻面，负向判别）', (tester) async {
      _useTallSurface(tester);

      // ---- 过去日：backfill（手填补记）----
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

      expect(
        _tailGlyphs(tester, backfillId),
        isNot(contains(_backfillGlyph)),
        reason: 'Task 54 已按用户要求删除回填态尾部 ▶（标题后的三角形）',
      );
      expect(
        _tailGlyphs(tester, habitEntryId),
        contains(_habitGlyph),
        reason: 'habit 的 ● 被一并删掉了 —— 它表达任务类型，不是完成态',
      );

      await _flushTimers(tester);
    });
  });
}