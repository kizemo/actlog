// =============================================================================
// B18 · 蓝图矩阵页两条用户当轮要求（W4）
// =============================================================================
// 1. 蓝图页内容**垂直居中**：目标行里的三段（勾选框 / 标题 / 操作区）各自在
//    行内垂直居中（原来是 `CrossAxisAlignment.start` 顶部对齐，视觉上「上紧下松」）；
//    已填格右侧常驻的「+」也要与目标列表块垂直居中。
// 2. 蓝图页「删除目标」从**文字按钮**换成**垃圾桶图标按钮**（与目标页同款），
//    但语义出口一个都不许少：`goal-blueprint-delete-<id>` 键名不变、
//    Tooltip 文案不变、读屏语义标签不变、点击回调不变。
//
// 判据（AGENTS.md §7「纯文本单元格改图标的判据」）：保留原交互入口 + 保留原
// i18n key + 图标必须带 `Tooltip` + `Semantics(label: 原文案)`。
// 几何判据用 `tester.getRect` 的中心线比较，容差 1.0px；用 3 条目标制造
// 足够落差（> 28px）保证鉴别力，避免 0 误差巧合通过。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalHorizon, GoalKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定视口：矩阵在长表格里，默认 800×600 会溢出/点不到。
void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 直接挂矩阵本体（不经过页面，排除页面层的布局干扰）。
Widget _host({
  required List<GoalRow> goals,
  void Function(GoalRow goal)? onDeleteGoal,
  void Function(String domainKey, GoalHorizon horizon, String title)?
      onCreateGoalInline,
}) {
  return MaterialApp(
    theme: AppTheme.light(DensityProfile.comfortable),
    home: Scaffold(
      body: SingleChildScrollView(
        child: GoalBlueprintMatrix(
          t: AppLocalizations.zh,
          rows: <GoalBlueprintRow>[
            GoalBlueprintRow(
              domainKey: 'career',
              cells: <GoalHorizon, List<GoalRow>>{
                GoalHorizon.ultimate: goals,
              },
            ),
          ],
          serves: const GoalServesIndex(
            <String, List<GoalRow>>{},
            <String, List<GoalRow>>{},
          ),
          tracksCount: const <String, int>{},
          onSplitTodos: (GoalRow _) {},
          onEditGoal: (GoalRow _) {},
          onToggleGoalDone: (GoalRow _, bool _) {},
          onDeleteGoal: onDeleteGoal,
          onCreateGoalInline: onCreateGoalInline,
        ),
      ),
    ),
  );
}

/// 造 3 条 career × 终极档蓝图目标（顺序 = 渲染顺序）。
Future<List<GoalRow>> _seedThree(GoalStore store) async {
  final List<String> ids = <String>[];
  for (final String title in <String>['目标一', '目标二', '目标三']) {
    ids.add(
      await store.createGoal(
        kind: GoalKind.blueprint,
        title: title,
        domain: 'career',
        horizon: GoalHorizon.ultimate,
      ),
    );
  }
  final List<GoalRow> all = await store.listGoals();
  return <GoalRow>[
    for (final String id in ids) all.firstWhere((GoalRow g) => g.id == id),
  ];
}

/// 某个 key 的 widget 矩形中心 Y。
double _centerY(WidgetTester tester, Key key) =>
    tester.getRect(find.byKey(key)).center.dy;

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b18-blueprint-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('B18-1 目标行三段（勾选框 / 标题 / 操作区）垂直居中', (
    WidgetTester tester,
  ) async {
    _size(tester);
    final List<GoalRow> goals = await _seedThree(store);
    await tester.pumpWidget(_host(goals: goals));
    await tester.pumpAndSettle();

    for (final GoalRow goal in goals) {
      final ValueKey<String> done = ValueKey<String>(
        'goal-blueprint-done-${goal.id}',
      );
      final ValueKey<String> text = ValueKey<String>(
        'goal-blueprint-goal-text-${goal.id}',
      );
      final ValueKey<String> split = ValueKey<String>(
        'goal-blueprint-split-${goal.id}',
      );

      // 操作区是行内最高的一段（28×28 图标按钮）⇒ 它的中心线就是行中心线。
      final double rowY = _centerY(tester, split);
      expect(
        _centerY(tester, done),
        closeTo(rowY, 1.0),
        reason: '勾选框必须与操作区同一条垂直中线上（原 `start` 顶部对齐会差 2px）',
      );
      expect(
        _centerY(tester, text),
        closeTo(rowY, 1.0),
        reason: '标题必须与操作区同一条垂直中线上（原 `start` 顶部对齐会差 3px 以上）',
      );
    }
  });

  testWidgets('B18-2 已填格「+」与目标列表块垂直居中', (WidgetTester tester) async {
    _size(tester);
    final List<GoalRow> goals = await _seedThree(store);
    await tester.pumpWidget(
      _host(
        goals: goals,
        onCreateGoalInline: (String _, GoalHorizon _, String _) {},
      ),
    );
    await tester.pumpAndSettle();

    final Finder addButton = find.byKey(
      const ValueKey<String>('goal-blueprint-add-career-ultimate'),
    );
    expect(addButton, findsOneWidget, reason: '传了 onCreateGoalInline ⇒ 已填格常驻「+」');

    final double firstY = _centerY(
      tester,
      ValueKey<String>('goal-blueprint-done-${goals.first.id}'),
    );
    final double lastY = _centerY(
      tester,
      ValueKey<String>('goal-blueprint-done-${goals.last.id}'),
    );
    final double blockCenter = (firstY + lastY) / 2;
    expect(
      tester.getRect(addButton).center.dy,
      closeTo(blockCenter, 1.0),
      reason:
          '「+」必须与整列目标块居中对齐（原 `start` 会贴在第一行顶上，'
          '3 条目标时落差 ≈ 34px）',
    );
  });

  testWidgets('B18-3 删除入口是垃圾桶图标按钮（不再是文字按钮）', (
    WidgetTester tester,
  ) async {
    _size(tester);
    final List<GoalRow> goals = await _seedThree(store);
    GoalRow? deleted;
    await tester.pumpWidget(
      _host(goals: goals, onDeleteGoal: (GoalRow goal) => deleted = goal),
    );
    await tester.pumpAndSettle();

    final ValueKey<String> key = ValueKey<String>(
      'goal-blueprint-delete-${goals.first.id}',
    );
    expect(find.byKey(key), findsOneWidget, reason: '既有 key 一个字都不许改');

    // 与 task73 N3 同口径：判据落在 `IconButton` 的 `constraints` 上
    // （`getRect` 量到的是收缩后的绘制盒，不是命中盒）。
    final IconButton button = tester.widget<IconButton>(find.byKey(key));
    expect(button.constraints?.maxWidth, 28, reason: '28×28 命中盒');
    expect(button.constraints?.maxHeight, 28, reason: '28×28 命中盒');
    expect(button.iconSize, 16, reason: '图标收紧到 16px，与铅笔/拆分一致');

    expect(
      find.descendant(
        of: find.byKey(key),
        matching: find.byIcon(Icons.delete_outline),
      ),
      findsOneWidget,
      reason: '与目标页同款：`Icons.delete_outline` 垃圾桶图标',
    );
    expect(
      find.text('删除目标'),
      findsNothing,
      reason: '文字按钮必须下线（三个删除按钮都不再渲染这段正文）',
    );
    expect(
      find.descendant(
        of: find.byKey(key),
        matching: find.byTooltip('删除目标'),
      ),
      findsOneWidget,
      reason: '§7：图标按钮必须带 Tooltip，文案沿用 `goalBlueprintDeleteGoal`',
    );

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(
      deleted?.id,
      goals.first.id,
      reason: '点击回调与改造前完全一致（二次确认由页面侧负责）',
    );
  });

  testWidgets('B18-3b 删除按钮语义：每个按钮恰好一个「删除目标」语义节点', (
    WidgetTester tester,
  ) async {
    // 语义句柄必须在用例体内释放：`addTearDown` 跑在框架收尾自检之后，
    // 会被判成 `A SemanticsHandle was active at the end of the test`。
    final SemanticsHandle handle = tester.ensureSemantics();
    _size(tester);
    final List<GoalRow> goals = await _seedThree(store);
    await tester.pumpWidget(_host(goals: goals, onDeleteGoal: (GoalRow _) {}));
    await tester.pumpAndSettle();

    // 3 个按钮 ⇒ **恰好** 3 个节点。这是上限断言：以后谁再给删除按钮套一层
    // 带同文案的 `Semantics`（Tooltip 文案 + 外层 label 各成节点），这里会翻倍。
    expect(
      find.bySemanticsLabel('删除目标'),
      findsNWidgets(goals.length),
      reason: '读屏只该播报一次「删除目标」',
    );

    handle.dispose();
  });
}