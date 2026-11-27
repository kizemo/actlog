// =============================================================================
// B17 · 任务 A：页签加宽 + 两态等高（契约：reports\b17-writeset-amendment-w3b.md）
// =============================================================================
// 本轮把页签从「活动 46 / 非活动 39 + 底边抬高 6px」收敛成**四档两态等高 46**，
// 同时水平内边距 10 → 16、相邻页签之间留 8px 间距（1px hairline 居中于间距）。
//
// 用例与验收判据的对应：
//  A1 常量口径：单一 `tabHeight == 46`、`tabGap == 8`、垂直内边距 4、
//      指示条 3px、顶部圆角 8px（既有口径不许回退）。
//  A2 两态等高：四个页签的 `minimumSize` 高、实测高、**顶边与底边**全部 46 且齐平
//      ⇒ 原先「非活动页下沉 6px」的台阶必须消失。
//  A3 加宽与间距：`padding == symmetric(horizontal: 16, vertical: 4)`；
//      相邻页签 rect 的水平间隔 = 8px；hairline 宽 1px 且**居中**于该间距。
//  A4 切档后仍等高（不是靠 `active` 分支凑出来的高度）；hairline 只画在两个
//      非活动页签之间（活动页两侧留空）。
//
// 判据口径：只用 `tester.getRect` / widget 属性，不看截图、不做字形断言
// （桌面测试不预载字体，字形断言必然是假信号；沿用 b13/b14 的口径）。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_domain/core_domain.dart' show GoalHorizon;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 四个档位标签的 key 片段（顺序即渲染顺序）。
const List<String> _horizonKeys = <String>['ultimate', 'long', 'mid', 'short'];

/// 某个档位标签（`TextButton`）。
Finder _tab(String horizonKey) =>
    find.byKey(ValueKey<String>('goal-blueprint-tab-$horizonKey'));

/// 页签之间的 1px hairline（`width: 1` / `height: 14` 的裸 `Container`）。
///
/// `Container` 把 `width` / `height` 折算进 `constraints`（没有同名 getter），
/// 故按 `BoxConstraints.tightFor` 的值相等来识别。
final Finder _hairLines = find.byWidgetPredicate(
  (Widget w) =>
      w is Container &&
      w.constraints == const BoxConstraints.tightFor(width: 1, height: 14),
);

/// 直接挂矩阵组件（形状抄 `b13_polish_test.dart:119-153`）。
///
/// 只放一个空领域行：本文件只关心**标签条**的尺寸与间距，不需要真实目标。
Future<void> _pumpMatrix(
  WidgetTester tester, {
  Size size = const Size(1400, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalBlueprintMatrix(
            t: AppLocalizations.zh,
            rows: const <GoalBlueprintRow>[
              GoalBlueprintRow(
                domainKey: 'career',
                cells: <GoalHorizon, List<GoalRow>>{},
              ),
            ],
            serves: const GoalServesIndex(
              <String, List<GoalRow>>{},
              <String, List<GoalRow>>{},
            ),
            tracksCount: const <String, int>{},
            onSplitTodos: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// `onSplitTodos` 的哑实现（本文件不触发拆分）。
void _noop(GoalRow _) {}

/// `minimumSize` 结算后的高度（不依赖实际渲染，直接读 style）。
double _minHeightOf(WidgetTester tester, String horizonKey) => tester
    .widget<TextButton>(_tab(horizonKey))
    .style!
    .minimumSize!
    .resolve(const <WidgetState>{})!
    .height;

void main() {
  testWidgets('A1 常量口径：单一 tabHeight 46、tabGap 8、垂直 4、既有口径不回退', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(tester);

    expect(GoalBlueprintMatrix.tabHeight, 46, reason: 'B17-A：两态共用的唯一高度');
    expect(GoalBlueprintMatrix.tabGap, 8, reason: 'B17-A：相邻页签间距 8px');
    expect(GoalBlueprintMatrix.tabVerticalPadding, 4, reason: 'B16 第 3 条不回退');
    expect(GoalBlueprintMatrix.tabIndicatorHeight, 3, reason: 'B14 第 3 条不回退');
    expect(GoalBlueprintMatrix.chromeTabTopRadius, 8, reason: 'B12 第 2 条不回退');
  });

  testWidgets('A2 两态等高：四个页签高度 46 且顶边 / 底边齐平', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(tester);

    for (final String key in _horizonKeys) {
      expect(
        _minHeightOf(tester, key),
        46,
        reason: 'B17-A：$key 的 minimumSize 高必须是 46（不再按 active 分支）',
      );
      expect(
        tester.getRect(_tab(key)).height,
        46,
        reason: 'B17-A：$key 实测高必须是 46',
      );
    }

    // 「两态等高」的可视判据：四页签顶边同高、底边同高（没有下沉台阶）。
    final Rect first = tester.getRect(_tab(_horizonKeys.first));
    for (final String key in _horizonKeys.skip(1)) {
      final Rect rect = tester.getRect(_tab(key));
      expect(
        rect.top,
        closeTo(first.top, 0.01),
        reason: 'B17-A：$key 顶边 ${rect.top} 必须与 ${_horizonKeys.first} '
            '顶边 ${first.top} 齐平（底边抬高已删除）',
      );
      expect(
        rect.bottom,
        closeTo(first.bottom, 0.01),
        reason: 'B17-A：$key 底边 ${rect.bottom} 必须与 ${_horizonKeys.first} '
            '底边 ${first.bottom} 齐平',
      );
    }

    // 标签条自身高度 = 单一页签高，不含原先为「抬高」预留的 6px。
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey<String>('goal-blueprint-tab-strip')),
          )
          .height,
      46,
      reason: 'B17-A：标签条高度就是 tabHeight 46（不再多出 6px 抬高带）',
    );
  });

  testWidgets('A3 加宽与间距：内边距水平 16 + 上下 4，相邻间隔 8，hairline 居中', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(tester);

    for (final String key in _horizonKeys) {
      expect(
        tester
            .widget<TextButton>(_tab(key))
            .style!
            .padding!
            .resolve(const <WidgetState>{}),
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        reason: 'B17-A：$key 水平 16（加宽）+ 上下各 4',
      );
    }

    // 相邻页签的 rect 间隔 = tabGap（1400 宽 ⇒ 不触发 scaleDown，比例 1.0）。
    for (int i = 1; i < _horizonKeys.length; i++) {
      final Rect prev = tester.getRect(_tab(_horizonKeys[i - 1]));
      final Rect cur = tester.getRect(_tab(_horizonKeys[i]));
      expect(
        cur.left - prev.right,
        closeTo(8, 0.01),
        reason: 'B17-A：${_horizonKeys[i - 1]} 与 ${_horizonKeys[i]} 之间'
            '必须留 8px（实测 ${cur.left - prev.right}）',
      );
    }

    // 默认选中 ultimate ⇒ 非活动相邻对 = (long, mid) / (mid, short) ⇒ 2 条 hairline。
    expect(
      _hairLines,
      findsNWidgets(2),
      reason: 'B17-A：活动页两侧留空 ⇒ 只有两个非活动相邻对之间画线',
    );
    final Rect longRect = tester.getRect(_tab('long'));
    final Rect midRect = tester.getRect(_tab('mid'));
    final double gapMid = (longRect.right + midRect.left) / 2;
    final List<Rect> lines = <Rect>[
      for (int i = 0; i < _hairLines.evaluate().length; i++)
        tester.getRect(_hairLines.at(i)),
    ];
    expect(
      lines.any((Rect r) => (r.center.dx - gapMid).abs() <= 0.01 && r.width == 1),
      isTrue,
      reason: 'B17-A：long / mid 之间的 hairline 必须 1px 宽且居中于 8px 间距'
          '（间距中线 $gapMid，实测 ${lines.map((Rect r) => r.center.dx).toList()}）',
    );
  });

  testWidgets('A4 切档后仍等高，hairline 只跟非活动相邻对走', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(tester);

    await tester.tap(_tab('mid'));
    await tester.pumpAndSettle();

    for (final String key in _horizonKeys) {
      expect(
        tester.getRect(_tab(key)).height,
        46,
        reason: 'B17-A：切到 mid 后 $key 仍为 46（高度与选中状态无关）',
      );
    }
    final Rect first = tester.getRect(_tab(_horizonKeys.first));
    for (final String key in _horizonKeys.skip(1)) {
      expect(
        tester.getRect(_tab(key)).top,
        closeTo(first.top, 0.01),
        reason: 'B17-A：切档后 $key 顶边仍齐平',
      );
    }

    // 选中 mid ⇒ 只有 (ultimate, long) 这一对两侧都非活动 ⇒ 1 条 hairline。
    expect(
      _hairLines,
      findsOneWidget,
      reason: 'B17-A：活动页（mid）两侧留空 ⇒ hairline 只剩 (ultimate, long) 那条',
    );
  });
}
