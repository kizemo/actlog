// apps/desktop/test/task61_l10n_calendar_test.dart
//
// Task 61 批次一 · 日历与日期（计划 §47 W2）的双语装置。
//
// 守三件事：
//   1. **中文态**：日历页 / 月视图 / 日期条 / 日期弹层的文案**逐字**命中
//      （zh 取值必须与改动前的字面量一字不差）；
//   2. **英文态**：同一批位置显示英文，且**格式**（年 / 月 / 星期）随 locale 变
//      —— 只换标签不算数，`2026-11` → `Nov 2026`、`2026-11-07 周六` →
//      `2026-11-07 Sat` 才算格式跟着 locale 走；
//   3. **阴性对照**：英文态下中文日历文案**一处都找不到**（否则上面两条可能
//      一直成立却什么都没证明）。
//
// 断言一律断**字面量**：全文件没有一处 `find.text(t.xxx)`（那是同义反复，
//   见计划 §47.3 铁律 1）。tooltip 不是 `Text` 控件，find.text 找不到它，
//   所以翻月提示走 `Tooltip.message` 属性断言。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/calendar_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/calendar_month_view.dart';
import 'package:actlog/src/widgets/date_picker_sheet.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 固定的「今天」。
const String _today = '2026-11-09';

/// 固定的选中日（周六，过去 ⇒ 日期条显示补录徽标）。
const String _selected = '2026-11-07';

/// 内存真库 + 真仓储 + 可切日的 ProviderContainer。
final class _Harness {
  _Harness._(this.container);

  final ProviderContainer container;

  static _Harness create({String selected = _selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task61-l10n-calendar');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先登记关库、后登记销毁容器，
    // 实际顺序是「先 dispose 容器、再 db.close」。反过来会永久挂起。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container);
  }
}

/// 等真库查询回来 + 等首帧跑完。
///
/// 不能用 `pumpAndSettle`：日历页 loading 态是无限转圈的
/// `CircularProgressIndicator`，settle 会一直等下去。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (int i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅，否则容器销毁会挂住。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 以指定语言挂出日历页（页面自带 MaterialApp / ProviderScope ⇒ 只补 L10nScope）。
Future<void> _pumpPage(
  WidgetTester tester,
  _Harness harness,
  AppLanguage language,
) async {
  await tester.pumpWidget(
    l10nScope(
      UncontrolledProviderScope(
        container: harness.container,
        child: const MaterialApp(home: Scaffold(body: CalendarPage())),
      ),
      language: language,
    ),
  );
  await _settle(tester);
}

/// 取某个 key 下 Tooltip 的提示文案（tooltip 不是 Text 控件，find.text 找不到）。
String _tooltipOf(WidgetTester tester, String key) {
  final Tooltip tooltip = tester.widget<Tooltip>(
    find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: find.byType(Tooltip),
    ),
  );
  return tooltip.message ?? '';
}

/// 月视图夹具：固定月份与「今天」，不依赖数据库。
Widget _monthView() {
  return const Scaffold(
    body: CalendarMonthView(
      month: '2026-11',
      days: <CalendarDaySummary>[],
      today: '2026-11-07',
    ),
  );
}

void main() {
  testWidgets('zh 态：日历页标题、翻月提示、月份与日期标题逐字命中', (tester) async {
    final _Harness harness = _Harness.create();
    await _pumpPage(tester, harness, AppLanguage.zh);

    expect(find.text('日历'), findsOneWidget);
    expect(_tooltipOf(tester, 'calendar-prev-month'), '上个月');
    expect(_tooltipOf(tester, 'calendar-next-month'), '下个月');
    expect(find.text('2026-11'), findsWidgets);
    expect(find.text('2026-11-07 周六'), findsOneWidget);
    expect(find.text('补录模式'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('en 态：同一批位置显示英文文案', (tester) async {
    final _Harness harness = _Harness.create();
    await _pumpPage(tester, harness, AppLanguage.en);

    expect(find.text('Calendar'), findsOneWidget);
    expect(_tooltipOf(tester, 'calendar-prev-month'), 'Previous month');
    expect(_tooltipOf(tester, 'calendar-next-month'), 'Next month');
    expect(find.text('Nov 2026'), findsWidgets);
    expect(find.text('2026-11-07 Sat'), findsOneWidget);
    expect(find.text('Backfill'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('日期格式随 locale 变：zh 用年月串，en 用月份名', (tester) async {
    final _Harness harness = _Harness.create();

    await _pumpPage(tester, harness, AppLanguage.zh);
    expect(find.text('2026-11'), findsWidgets, reason: '中文态的月份标题是 yyyy-MM');
    expect(find.text('2026-11-07 周六'), findsOneWidget);

    await _pumpPage(tester, harness, AppLanguage.en);
    expect(find.text('Nov 2026'), findsWidgets, reason: '英文态的月份标题带月份名');
    expect(
      find.text('2026-11'),
      findsNothing,
      reason: '英文态不该再出现 yyyy-MM 的月份标题',
    );
    expect(find.text('2026-11-07 Sat'), findsOneWidget);
    expect(
      find.text('2026-11-07 周六'),
      findsNothing,
      reason: '星期名必须随 locale 变，不能只换标签',
    );

    await _flushTimers(tester);
  });

  testWidgets('zh 态：月视图星期表头与「今天」角标逐字命中', (tester) async {
    await pumpL10n(tester, _monthView());

    expect(find.text('一'), findsOneWidget);
    expect(find.text('二'), findsOneWidget);
    expect(find.text('三'), findsOneWidget);
    expect(find.text('四'), findsOneWidget);
    expect(find.text('五'), findsOneWidget);
    expect(find.text('六'), findsOneWidget);
    expect(find.text('日'), findsOneWidget);
    expect(find.text('今'), findsOneWidget);
    expect(find.text('2026-11'), findsOneWidget);
  });

  testWidgets('en 态：月视图星期表头为英文缩写，「今天」角标为 Today', (tester) async {
    await pumpL10n(tester, _monthView(), language: AppLanguage.en);

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nov 2026'), findsOneWidget);
    // 阴性对照：中文星期表头在英文态一处都找不到。
    expect(find.text('三'), findsNothing);
    expect(find.text('四'), findsNothing);
    expect(find.text('五'), findsNothing);
    expect(find.text('六'), findsNothing);
  });

  testWidgets('阴性对照：en 态下中文日历文案一处都找不到', (tester) async {
    final _Harness harness = _Harness.create();
    await _pumpPage(tester, harness, AppLanguage.en);

    expect(find.text('日历'), findsNothing, reason: '页面标题不该残留中文');
    expect(find.text('今'), findsNothing, reason: '今天角标不该残留中文');
    expect(find.text('一'), findsNothing, reason: '星期表头不该残留中文');
    expect(find.text('补录模式'), findsNothing, reason: '状态徽标不该残留中文');
    expect(
      find.text('2026-11-07 周六'),
      findsNothing,
      reason: '日期标题不该残留中文星期名',
    );

    await _flushTimers(tester);
  });

  testWidgets('zh 态：月视图星期表头与「今天」角标之外，英文态也不漏中文',
      (tester) async {
    await pumpL10n(tester, _monthView(), language: AppLanguage.en);

    expect(find.text('今'), findsNothing);
    expect(find.text('二'), findsNothing);
    expect(find.text('日'), findsNothing);
    expect(find.text('2026-11'), findsNothing);
  });

  testWidgets('日期条状态徽标随 locale 变：未来日「预排」/ Scheduled', (tester) async {
    final _Harness harness = _Harness.create(selected: '2026-11-11');

    await _pumpPage(tester, harness, AppLanguage.zh);
    expect(find.text('预排'), findsOneWidget);
    expect(find.text('补录模式'), findsNothing);

    await _pumpPage(tester, harness, AppLanguage.en);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('预排'), findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('日期选择弹层：快捷芯片与按钮中英双态逐字命中', (tester) async {
    const Widget sheet = Scaffold(body: DatePickerSheet(initial: '2026-11-07'));

    await pumpL10n(tester, sheet);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('昨天'), findsOneWidget);
    expect(find.text('前天'), findsOneWidget);
    expect(find.text('明天'), findsOneWidget);
    expect(find.text('本周内'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    expect(find.text('一'), findsOneWidget);
    expect(find.text('2026-11'), findsOneWidget);

    await pumpL10n(tester, sheet, language: AppLanguage.en);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Day before yesterday'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Nov 2026'), findsOneWidget);
    // 阴性对照：中文芯片、按钮与表头在英文态一处都找不到。
    expect(find.text('今天'), findsNothing);
    expect(find.text('昨天'), findsNothing);
    expect(find.text('前天'), findsNothing);
    expect(find.text('明天'), findsNothing);
    expect(find.text('本周内'), findsNothing);
    expect(find.text('取消'), findsNothing);
    expect(find.text('确定'), findsNothing);
    expect(find.text('一'), findsNothing);
    expect(find.text('2026-11'), findsNothing);
  });
}
