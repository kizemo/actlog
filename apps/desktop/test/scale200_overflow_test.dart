// apps/desktop/test/scale200_overflow_test.dart
//
// 200% 字号（`ACTLOG_TEXT_SCALE=2`）下的溢出回归。
//
// 修复前的两条 `RenderFlex overflowed`：
// ① `loop_progress_ring.dart` 的刻度行（`0 25 50 75 100` 五个 `Text` + `spaceBetween`）；
// ② `section_card.dart` 的段头行（标题 + 说明 + trailing 挤在同一行）。
//
// 判据不是「把 FlutterError 抽干」——抽干只是把异常扔掉，任何真实溢出都会
// 被静默吞掉。这里直接断言 `takeException()` 为 `null`：一旦还有任何溢出，
// 该断言立刻挂。同时守住「200% 是真缩放，不是偷偷缩字号 / 截断内容」：
// 刻度文案必须仍是完整的 `100`，且没有任何 `ellipsis` 截断。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/section_card.dart';

const String _today = '2026-11-09';

/// 1400×3000：够宽（≥1280 走宽屏壳）够高（整页竖排四段不掉出屏幕）。
void _useLargeSurface(WidgetTester tester) {
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

/// 挂 200% 字号的整棵树（缩放只由 `ActLogApp.textScale` 施加）。
Future<void> _mountAt200(WidgetTester tester) async {
  final db = openInMemoryActLogDatabase();
  final repos = ActLogRepositories(db, deviceId: 'scale200-test');
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

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ActLogApp(textScale: 2.0),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('200% 下今日页零溢出，且缩放是真缩放（scale(10) == 20）', (tester) async {
    _useLargeSurface(tester);
    await _mountAt200(tester);

    // 先证明「200% 确实生效」：否则零溢出可能是因为根本没放大。
    final pageElement = tester.element(find.byType(TodayPage));
    expect(MediaQuery.textScalerOf(pageElement).scale(10), 20);

    // B2（2026-11-12）后今日页只剩 2 张段头卡：心情
    // （`mood_section.dart:90`）+ 复盘（`review_section.dart:119`）；
    // 习惯段与站会段已从今日页摘除（文件保留，仅取消引用）。
    expect(find.byType(SectionCard), findsNWidgets(2));

    // 真实断言：任何 `RenderFlex overflowed` 都会被 `takeException` 捕获并挂在这里。
    // 修复前这条会在 `loop_progress_ring.dart` / `section_card.dart` 各报一次。
    expect(tester.takeException(), isNull);

    await _flushTimers(tester);
  });

  testWidgets('200% 下环形刻度仍是完整的 100，不截断、不换行', (tester) async {
    _useLargeSurface(tester);
    await _mountAt200(tester);

    final hundreds = find.text('100');
    expect(hundreds, findsWidgets);

    // `100` 一个都不能被 ellipsis 截成 `1…`，也不能被限制成单行以外的假象。
    for (final element in hundreds.evaluate()) {
      final text = element.widget as Text;
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.overflow, isNot(TextOverflow.clip));
      // 渲染出来必须是正的、且完整高度的盒子（没有塌成 0 宽）。
      final size = tester.getSize(find.byWidget(text));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    }

    expect(tester.takeException(), isNull);

    await _flushTimers(tester);
  });

  testWidgets('200% 下「从待办池捞」入口在段正文内、可换行、零溢出', (tester) async {
    _useLargeSurface(tester);
    await _mountAt200(tester);

    // 入口是 C7 的 D-a：今日计划段必须有一枚可见入口，不能只靠快捷键。
    final entry = find.byKey(const ValueKey<String>('plan-pool-entry'));
    expect(entry, findsOneWidget);
    expect(find.text('＋ 从待办池捞'), findsOneWidget);

    // B2 后入口不再住在「今日计划」卡片里：宿主是今日页正文列，
    // 判据改为「入口矩形完整落在今日页矩形内」，仍能抓住被挤到列外的情况。
    final pageRect = tester.getRect(find.byType(TodayPage));
    final entryRect = tester.getRect(entry);
    expect(entryRect.left, greaterThanOrEqualTo(pageRect.left));
    expect(entryRect.right, lessThanOrEqualTo(pageRect.right));

    // 200% 下入口绝不溢出（`Wrap` 会换行而不是挤出边界）。
    expect(tester.takeException(), isNull);

    await _flushTimers(tester);
  });

  testWidgets('200% 下 1440×900 视口同样零溢出（高度靠滚动兜底，只看横向判据）', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mountAt200(tester);

    final pageElement = tester.element(find.byType(TodayPage));
    expect(MediaQuery.textScalerOf(pageElement).scale(10), 20);
    expect(find.byType(SectionCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await _flushTimers(tester);
  });
}
