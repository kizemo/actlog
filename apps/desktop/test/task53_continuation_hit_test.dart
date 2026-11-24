// apps/desktop/test/task53_continuation_hit_test.dart
//
// Task 53 · 诉求 2 的验收面（用户原话逐字引用）：
//   「长任务在后续的行中，没有文字，但悬停也要悬浮显示任务信息，左键点击可以
//     对任务进行编辑；」
//
// 控制器裁决：续段**保留无文字**（`showBody: false` 语义不动），只补两件事 ——
// ① 悬停出任务信息浮窗，锚点必须是**续段自身**的矩形；② 左键打开任务详情窗。
// 续段不新增拖拽，也不新增双击（`_editRange` 仍只挂首段）。
//
// 三条用例各盯一件事：
//   A 续段确实「没有文字」（前置条件，否则后面两条的「无文字也要能操作」不成立）；
//   B 浮窗锚在**续段**上 —— 判据是「卡片顶边 ≥ 续段下缘 + 8px」；若锚到首段，
//     卡片会落进续段所在的行里，这条立刻红；
//   C 左键续段打开详情窗，且窗里是**这一条**任务（标题字段逐字比对）。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';

import 'l10n_harness.dart';

/// 固定「今天」，被测日取其**次日**（未来日 ⇒ 不算回填，四态稳定）。
const String _today = '2026-11-09';
const String _future = '2026-11-10';

/// 跨小时的标题：09:50–10:20 横跨 10:00 整点，布局层切成两段。
const String _title = '跨小时长任务';

const ValueKey<String> _kHoverCard = ValueKey<String>('slot-hover-card');
const ValueKey<String> _kDetailTitle = ValueKey<String>('plan-detail-title');
const ValueKey<String> _kDetailCancel = ValueKey<String>('plan-detail-cancel');

/// 卡片与当条 chip 的最小净空（与 `slot_hover_card.dart` 的 `_kChipClearance`
/// 同值；硬约束「卡片顶边 ≥ chip 下缘 + 8px」）。
const double _chipClearance = 8;

final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task53-hit-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _future),
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
        child: l10nScope(
          MaterialApp(home: Scaffold(body: DayGrid(date: _future))),
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

/// 走完「卡片出现 → 量高度 → 用实测高度重排一次」这三帧。
Future<void> _settleCard(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

/// 跨小时条目的两段（首段 + 续段）。段信息从 `_SlotPainter` 的布局里读，
/// 不靠猜行号 —— 续段的 key 里带 `row`，猜错就整条用例空转。
List<SlotSegment> _segmentsOf(WidgetTester tester) {
  final CustomPaint paint = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .firstWhere(
        (CustomPaint p) =>
            p.painter != null &&
            p.painter!.runtimeType.toString() == '_SlotPainter',
      );
  final dynamic painter = paint.painter;
  final SlotLayout layout = painter.layout as SlotLayout;
  return layout.segments
      .where((SlotSegment s) => s.entry.title == _title)
      .toList();
}

/// 续段那条 `Container` 的 key（与 `day_grid.dart` 的拼法逐字一致）。
ValueKey<String> _continuationKey(SlotSegment seg) =>
    ValueKey<String>('day-grid-entry-${seg.entry.id}-seg-${seg.row}');

/// 一条跨小时条目：09:50–10:20。
Future<_Harness> _pumpCrossHour(WidgetTester tester) async {
  _useTallSurface(tester);
  final _Harness h = _Harness.create();
  await tester.runAsync(
    () => TimelineStore(h.repos).createManual(
      date: _future,
      title: _title,
      startMinute: 9 * 60 + 50,
      endMinute: 10 * 60 + 20,
      todayIso: _today,
      nowMinute: 0,
    ),
  );
  await h.mount(tester);
  await _settle(tester);
  return h;
}

void main() {
  group('Task 53 · 诉求 2：续段无文字，但悬停有浮窗、左键可编辑', () {
    testWidgets('A：跨小时条目切成两段，续段里一个文字都没有', (tester) async {
      await _pumpCrossHour(tester);

      final List<SlotSegment> segs = _segmentsOf(tester);
      expect(segs, hasLength(2), reason: '09:50–10:20 没有被切成两段');
      final SlotSegment head = segs.first;
      final SlotSegment tail = segs.last;
      expect(head.isHead, isTrue);
      expect(tail.isHead, isFalse, reason: '第二段应当是续段');

      // 首段有正文（标题在），续段一个 `Text` 都没有 —— 这就是用户说的
      // 「后续的行中没有文字」。
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-${head.entry.id}')),
          matching: find.text(_title),
        ),
        findsOneWidget,
        reason: '首段没有标题 —— 前置条件不成立，后面的判据失去意义',
      );
      expect(
        find.descendant(
          of: find.byKey(_continuationKey(tail)),
          matching: find.byType(Text),
        ),
        findsNothing,
        reason: '续段里出现了文字（`showBody` 语义被改动）',
      );

      await _flushTimers(tester);
    });

    testWidgets('B：悬停续段出信息浮窗，且浮窗锚在续段自身矩形上', (tester) async {
      await _pumpCrossHour(tester);

      final SlotSegment tail = _segmentsOf(tester).last;
      final Finder cont = find.byKey(_continuationKey(tail));
      final Rect contRect = tester.getRect(cont);
      expect(contRect.height, greaterThan(0), reason: '续段矩形是空的，测不到');
      // 关闭态：卡片零渲染。
      expect(find.byKey(_kHoverCard), findsNothing);

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: const Offset(4, 4));
      addTearDown(pointer.removePointer);

      await pointer.moveTo(contRect.center);
      await _settleCard(tester);

      expect(
        find.byKey(_kHoverCard),
        findsOneWidget,
        reason: '悬停续段没有出现任务信息浮窗',
      );
      final Rect cardRect = tester.getRect(find.byKey(_kHoverCard));
      // 判别性判据：锚在续段 ⇒ 卡片整体落在续段之下 8px 起；锚在首段 ⇒ 卡片会
      // 落进续段所在那一行里，这条必红。
      expect(
        cardRect.top,
        greaterThanOrEqualTo(contRect.bottom + _chipClearance - 0.01),
        reason: '卡片顶边没有退到续段下缘 8px 之外 ⇒ 锚点不是续段自身',
      );
      expect(
        cardRect.overlaps(contRect),
        isFalse,
        reason: '卡片压住了续段本体（会吃掉续段的左键）',
      );

      // 收尾：挪走指针、跨过 200ms 宽限期。
      await pointer.moveTo(const Offset(4, 4));
      await tester.pump(const Duration(milliseconds: 400));
      await _flushTimers(tester);
    });

    testWidgets('C：左键点续段打开任务详情窗，且窗里是这一条任务', (tester) async {
      await _pumpCrossHour(tester);

      final SlotSegment tail = _segmentsOf(tester).last;
      await tester.tap(find.byKey(_continuationKey(tail)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(_kDetailTitle),
        findsOneWidget,
        reason: '左键点续段没有打开任务详情窗',
      );
      final TextField field = tester.widget<TextField>(
        find.byKey(_kDetailTitle),
      );
      expect(
        field.controller?.text,
        _title,
        reason: '打开的详情窗不是这一条任务（标题字段对不上）',
      );

      // 取消收尾：不落库，也不留 pending 路由。
      await tester.tap(find.byKey(_kDetailCancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_kDetailTitle), findsNothing);

      await _flushTimers(tester);
    });
  });
}