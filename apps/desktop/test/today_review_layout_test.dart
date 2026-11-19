// apps/desktop/test/today_review_layout_test.dart
//
// Task 40 · B2 · 需求 4：复盘 + 心态整段不再走带左栏的 `TimelineSection`
// 包装，且 `review_section.dart` 删掉「可控的事 / 不可控的事 / 下一步可控动作」
// 三项字段。
//
// 证据口径（`AGENTS.md` R5）：钉**结构事实**与**落库事实**，不钉像素。
//   1. 今日页上「晚 · 复盘与心态」「✓ 已闭合」这两处只属于时间轴骨架的文案
//      **一处都不出现**（`find.text` 全页搜，不是限定某个子树）；
//   2. 复盘卡、心态卡与方格时间轴**左基线相同**（左栏包装被摘掉的
//      可测后果；只要有人把 `TimelineSection` 包回去，第一条断言立刻红）；
//      锚点原先是「从待办池捞」入口，Task 45 需求 4 删掉它后改锚
//      加计划条上的日期时间按钮（与复盘 / 心态卡同列左边界）；
//   3. 复盘只剩三段输入框，删掉的三段**连控件都不在**；
//   4. 删控件 ≠ 删数据：老库里的 `controllable` / `uncontrollable` 在改
//      「学到了什么」时**必须原值保留**（`saveReview` 仍写这两列，
//      传空串就是一次静默数据丢失）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/day_timeline.dart';
import 'package:actlog/src/widgets/section_card.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const String _today = '2026-11-09';

/// 复盘里保留的三段（顺序与 `review_section.dart:_fields` 一致）。
const List<String> _keptLabels = <String>['学到了什么', '做得好', '待改进'];

/// 已删除的三段。它们不许以任何形式回到界面上。
const List<String> _removedLabels = <String>['可控的事', '不可控的事', '下一步可控动作'];

/// 按 `InputDecoration.labelText` 定位复盘输入框（不依赖 label 的渲染方式）。
Finder _field(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is TextField && widget.decoration?.labelText == label,
    );

/// 内容左锚点：加计划条上的日期时间按钮与复盘卡、心态卡同属正文列，
/// 共用一条左基线。
///
/// 原先锚在「＋ 从待办池捞」入口上；Task 45 需求 4 删掉入口后改锚
/// `add-plan-datetime-button` —— 实测其左边界与复盘 / 心态卡逐像素相同
/// （`day-grid` 的 key 容器从方格区起算，比正文列右移，不能当同列锚点）。
final Finder _contentLeftAnchor =
    find.byKey(const ValueKey<String>('add-plan-datetime-button'));

final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task40-review-layout-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LedgerShell(content: TodayPage(), currentNavId: 'today'),
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

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅（`ReviewSection.dispose` 里还有一次落库）。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
}

void main() {
  testWidgets('复盘不再挂在时间轴段里：没有段头文案、没有节点文案、与其它模块同左基线',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);
    await _settle(tester);

    // ① 时间轴骨架的两处文案全页不得出现。
    expect(
      find.text('晚 · 复盘与心态'),
      findsNothing,
      reason: '复盘段头已随 TimelineSection 包装一起删除',
    );
    expect(
      find.text('✓ 已闭合'),
      findsNothing,
      reason: '「已闭合 / 有缺口」是时间轴节点的语言，复盘不是一天里的某一格',
    );
    expect(
      find.byType(TimelineSection),
      findsNothing,
      reason: '今日页不再用带左栏的 TimelineSection 包装任何区块',
    );

    // ② 复盘卡与心态卡仍是普通区块：两张 SectionCard，且左基线一致。
    final Finder reviewCard = find.ancestor(
      of: _field('学到了什么'),
      matching: find.byType(SectionCard),
    );
    final Finder moodCard = find.ancestor(
      of: find.text('心态'),
      matching: find.byType(SectionCard),
    );
    expect(find.byType(SectionCard), findsNWidgets(2));
    expect(reviewCard, findsOneWidget);
    expect(moodCard, findsOneWidget);

    final double anchorLeft = tester.getTopLeft(_contentLeftAnchor).dx;
    final Rect reviewRect = tester.getRect(reviewCard);
    final Rect moodRect = tester.getRect(moodCard);
    expect(
      reviewRect.left,
      moreOrLessEquals(anchorLeft, epsilon: 0.5),
      reason: '复盘内容必须与其它模块同一条左基线，不许有额外左缩进',
    );
    expect(
      moodRect.left,
      moreOrLessEquals(anchorLeft, epsilon: 0.5),
      reason: '心态内容必须与其它模块同一条左基线，不许有额外左缩进',
    );
    expect(reviewRect.width, moreOrLessEquals(moodRect.width, epsilon: 0.5));

    // ③ 三段保留、三段删除（删的是控件，不只是文案）。
    for (final String label in _keptLabels) {
      expect(_field(label), findsOneWidget, reason: '「$label」必须保留');
    }
    for (final String label in _removedLabels) {
      expect(_field(label), findsNothing, reason: '「$label」字段已删除');
    }

    await _flushTimers(tester);
  });

  testWidgets('删掉的三段不留数据残骸：改「学到了什么」不清空可控 / 不可控',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();

    // 预置一条「老版本界面写的」日志：可控 / 不可控都有内容。
    late DayLogData seeded;
    await tester.runAsync(() async {
      seeded = await harness.repos.dayLog.ensureByDate(_today);
      await harness.repos.dayLog.saveReview(
        seeded.id,
        const ReviewDraft(
          learning: '旧收获',
          good: '旧做法',
          improve: '旧改法',
          controllable: '自己能决定的部分',
          uncontrollable: '天气与别人的脾气',
        ),
      );
    });

    await harness.mount(tester);
    await _settle(tester);

    // 老内容回填进保留的三段。
    expect(
      tester.widget<TextField>(_field('学到了什么')).controller!.text,
      '旧收获',
    );

    await tester.enterText(_field('学到了什么'), '新收获');
    // 防抖 700ms（`review_section.dart:_scheduleSave`）+ 一次真异步落库。
    await tester.pump(const Duration(milliseconds: 800));
    await _settle(tester);

    // `runAsync` 的泛型是 `T` 而返回 `T?`：直接承接会被推断成
    // 「闭包必须返回非空」，所以先落到 `late` 变量里再断言，别跟类型推断较劲。
    late DayLogData? readBack;
    await tester.runAsync(() async {
      readBack = await harness.repos.dayLog.findByDate(_today);
    });
    final DayLogData after = readBack!;
    expect(after.learning, '新收获', reason: '改的那一段必须真的落库');
    expect(
      after.controllable,
      '自己能决定的部分',
      reason: '界面不再编辑这一列，但存量数据必须原值保留（删 UI 不等于删数据）',
    );
    expect(
      after.uncontrollable,
      '天气与别人的脾气',
      reason: '界面不再编辑这一列，但存量数据必须原值保留（删 UI 不等于删数据）',
    );

    await _flushTimers(tester);
  });
}