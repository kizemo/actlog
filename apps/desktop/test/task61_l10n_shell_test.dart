// apps/desktop/test/task61_l10n_shell_test.dart
//
// Task 61 批次一（worker B）：应用外壳的**中英双态**用例。
//
// 覆盖外壳的全部可见文案：
// * 品牌块（主标题 + 副标题 `actlog`）；
// * 左主导航 7 项（第 3 项「蓝图」，Task 72 · D-72-b）；
// * 导航底注**已删除**（Task 72 · D-72-a）⇒ 相关用例改为阴性断言；
// * 右轨「快捷键 / Shortcuts」面板与 9 条快捷键说明；
// * 右轨 5 个面板（今日页生产清单 `todayRailPanels`）的标题与 `＋` 动作位文案
//   （第 5 块「未完成周目标」是 Batch 7 占位面板，没有 `＋`）。
//
// 断言口径（§47.3 铁律 1 · 本批次派工书 §1 第 9 条）：
// * 一律断**字面量**，不许 `find.text(t.xxx)` —— 那是同义反复，没有鉴别力；
// * en 态必须带**阴性对照**：中文串在整棵树里 `findsNothing`（或不在面板清单里）；
// * 语言切换用 `test\l10n_harness.dart` 的既有 `l10nScope`（挂 `L10nScope`），
//   不另造 pump 框架。
//
// 右轨面板的文案在 `todayRailPanels(context)` 的**返回值**上断言（标题串 +
// `RailAddButton` 的无障碍名），不把它们渲染出来：真面板要真库（`TodoRailPanel`
// / `HabitOverviewPanel` / `RecurringRailPanel` 都读 drift 流），在 widget 测试里
// 起库会把这条用例变成一条与 l10n 无关的集成测试，也拖慢全量门禁。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/app.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';
import 'package:actlog/src/widgets/shell/nav_rail.dart';
import 'package:actlog/src/widgets/shell/tool_rail.dart';

import 'l10n_harness.dart';

/// 左主导航 7 项的中文文案（zh 态逐字）。
const List<String> _zhNavLabels = <String>[
  '日志',
  '待办池',
  '蓝图',
  '目标',
  '项目',
  '学习管理',
  '日历',
];

/// 左主导航 7 项的英文文案（en 态逐字）。
const List<String> _enNavLabels = <String>[
  'Journal',
  'To-do Pool',
  'Blueprint',
  'Goals',
  'Projects',
  'Learning Management',
  'Calendar',
];

/// 9 条快捷键说明的中文文案（zh 态逐字，含全角 `＋` 与斜杠两侧空格）。
const List<String> _zhKeyLabels = <String>[
  '＋ 手写一条',
  '打卡第一条未打习惯',
  '切日期',
  '勾选 / 取消勾选',
  '展开回填',
  '关闭弹层',
  '切页',
  '切到项目',
  '切到目标',
];

/// 9 条快捷键说明的英文文案（en 态逐字）。
const List<String> _enKeyLabels = <String>[
  '+ Add an entry',
  'Check the first unchecked habit',
  'Switch date',
  'Check / uncheck',
  'Expand backfill',
  'Close popup',
  'Switch tab',
  'Go to Projects',
  'Go to Goals',
];

/// 右轨 5 个面板的中文标题（zh 态逐字，顺序即展示顺序）。
const List<String> _zhPanelTitles = <String>[
  '待办列表',
  '习惯速览',
  '循环任务',
  '闭环提示',
  '未完成周目标',
];

/// 右轨 3 枚 `＋` 动作位的中文无障碍名（zh 态逐字）。
const List<String> _zhPanelActions = <String>[
  '添加待办',
  '添加习惯',
  '添加循环任务',
];

/// 右轨 5 个面板的英文标题（en 态逐字，顺序即展示顺序）。
const List<String> _enPanelTitles = <String>[
  'To-do list',
  'Habit overview',
  'Recurring tasks',
  'Loop hint',
  'Open weekly goals',
];

/// 右轨 3 枚 `＋` 动作位的英文无障碍名（en 态逐字）。
const List<String> _enPanelActions = <String>[
  'Add to-do',
  'Add habit',
  'Add recurring task',
];

/// 竖排导航的宿主：固定宽高（导航栏的 `Spacer` 需要有界高度）。
Widget _navHost() => const Scaffold(
  body: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: NavRail.width, height: 800, child: NavRail()),
  ),
);

/// 按指定语言 pump 竖排导航（语言切换用既有 `l10nScope`）。
Future<void> _pumpNav(
  WidgetTester tester, {
  required AppLanguage language,
}) async {
  await tester.pumpWidget(
    l10nScope(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: _navHost(),
      ),
      language: language,
    ),
  );
}

/// pump 竖排导航但**不挂** `L10nScope`。
///
/// 既有测试（`shell_nav_rail_test.dart` 等）就是这样直接构造 `NavRail` 的，
/// 所以壳层取不到 scope 时必须回落中文态，不能抛错 —— 这条用例守着这个契约。
Future<void> _pumpNavWithoutScope(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: _navHost(),
    ),
  );
}

/// 撑到宽屏（≥ 1280）⇒ 导航竖排、右轨在右侧。
void _useWideSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 宽屏账页壳（正文用 ASCII，避免把无关中文混进阴性对照）。
Widget _ledgerHost() => const LedgerShell(
  currentNavId: 'today',
  content: Text('ledger body'),
);

/// 按指定语言 pump 宽屏账页壳。
Future<void> _pumpLedger(
  WidgetTester tester, {
  required AppLanguage language,
}) async {
  _useWideSurface(tester);
  await tester.pumpWidget(
    l10nScope(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: _ledgerHost(),
      ),
      language: language,
    ),
  );
}

/// 取一份带 `L10nScope` 的 context（只为调 `todayRailPanels` 这类生产清单函数）。
Future<BuildContext> _pumpProbe(
  WidgetTester tester,
  AppLanguage language,
) async {
  late BuildContext captured;
  await tester.pumpWidget(
    l10nScope(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
      language: language,
    ),
  );
  return captured;
}

/// 面板标题清单（顺序即展示顺序）。
List<String> _panelTitles(List<ShellRailPanel> panels) =>
    panels.map((ShellRailPanel panel) => panel.title).toList();

/// `＋` 动作位的无障碍名清单（顺序即展示顺序）。
List<String> _panelActionLabels(List<ShellRailPanel> panels) => <String>[
  for (final ShellRailPanel panel in panels)
    if (panel.trailing is RailAddButton)
      (panel.trailing! as RailAddButton).label,
];

void main() {
  testWidgets('zh 态（无 L10nScope，回落中文）：左导航 7 项 + 品牌逐字命中，且无底注', (
    WidgetTester tester,
  ) async {
    await _pumpNavWithoutScope(tester);

    for (final String label in _zhNavLabels) {
      expect(find.text(label), findsOneWidget, reason: '缺少导航项 $label');
    }
    expect(find.text('知行日志'), findsOneWidget);
    expect(find.text('actlog'), findsOneWidget);
    // D-72-a：左栏底部不再有快捷键常驻文本。
    expect(find.text('页面切换'), findsNothing);
  });

  testWidgets('zh 态（L10nScope）：左导航 7 项中文文案逐字命中，且无底注', (
    WidgetTester tester,
  ) async {
    await _pumpNav(tester, language: AppLanguage.zh);

    for (final String label in _zhNavLabels) {
      expect(find.text(label), findsOneWidget, reason: '缺少导航项 $label');
    }
    expect(find.text('页面切换'), findsNothing);
  });

  testWidgets('zh 态：品牌主标题「知行日志」+ 副标题「actlog」都在', (
    WidgetTester tester,
  ) async {
    await _pumpNav(tester, language: AppLanguage.zh);

    expect(find.text('知行日志'), findsOneWidget, reason: '中文态主标题必须是「知行日志」');
    expect(find.text('actlog'), findsOneWidget, reason: '中文态副标题「actlog」必须在场');
  });

  testWidgets('en 态：左导航 7 项英文文案逐字命中', (WidgetTester tester) async {
    await _pumpNav(tester, language: AppLanguage.en);

    for (final String label in _enNavLabels) {
      expect(find.text(label), findsOneWidget, reason: '缺少英文导航项 $label');
    }
  });

  testWidgets('en 态：品牌主标题显示 actlog，副标题不再重复一行', (
    WidgetTester tester,
  ) async {
    await _pumpNav(tester, language: AppLanguage.en);

    // 英文态主标题就是 `actlog`；副标题行此时必须隐藏（否则同字两行）。
    expect(find.text('actlog'), findsOneWidget, reason: '英文态主标题是 actlog');
    expect(find.text('知行日志'), findsNothing, reason: '英文态不得出现中文品牌名');
  });

  testWidgets('en 态：导航底注已删除（Page switch 与 页面切换 都找不到）', (
    WidgetTester tester,
  ) async {
    await _pumpNav(tester, language: AppLanguage.en);

    expect(find.text('Page switch'), findsNothing, reason: 'D-72-a 已删除底注');
    expect(find.text('页面切换'), findsNothing);
  });

  testWidgets('en 态阴性对照：左导航里的中文串全都找不到', (
    WidgetTester tester,
  ) async {
    await _pumpNav(tester, language: AppLanguage.en);

    for (final String label in _zhNavLabels) {
      expect(find.text(label), findsNothing, reason: '英文态不得出现中文导航项 $label');
    }
    expect(find.text('知行日志'), findsNothing);
    expect(find.text('页面切换'), findsNothing);
  });

  testWidgets('zh 态：右轨「快捷键」面板 + 9 条说明逐字命中', (
    WidgetTester tester,
  ) async {
    await _pumpLedger(tester, language: AppLanguage.zh);

    expect(find.text('快捷键'), findsOneWidget, reason: '右轨面板标题逐字是「快捷键」');
    for (final String label in _zhKeyLabels) {
      expect(find.text(label), findsOneWidget, reason: '缺少快捷键说明 $label');
    }
  });

  testWidgets('en 态：右轨「Shortcuts」面板 + 9 条英文说明逐字命中', (
    WidgetTester tester,
  ) async {
    await _pumpLedger(tester, language: AppLanguage.en);

    expect(find.text('Shortcuts'), findsOneWidget, reason: '右轨面板标题逐字是「Shortcuts」');
    for (final String label in _enKeyLabels) {
      expect(find.text(label), findsOneWidget, reason: '缺少英文快捷键说明 $label');
    }
  });

  testWidgets('en 态阴性对照：整棵壳树里没有一条中文文案', (
    WidgetTester tester,
  ) async {
    await _pumpLedger(tester, language: AppLanguage.en);

    expect(find.text('快捷键'), findsNothing);
    expect(find.text('页面切换'), findsNothing);
    expect(find.text('知行日志'), findsNothing);
    for (final String label in _zhNavLabels) {
      expect(find.text(label), findsNothing, reason: '英文态不得出现中文导航项 $label');
    }
    for (final String label in _zhKeyLabels) {
      expect(find.text(label), findsNothing, reason: '英文态不得出现中文快捷键说明 $label');
    }
  });

  testWidgets('zh 态：右轨 5 个面板的标题与动作位文案逐字命中', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await _pumpProbe(tester, AppLanguage.zh);
    final List<ShellRailPanel> panels = todayRailPanels(context);

    expect(_panelTitles(panels), _zhPanelTitles);
    expect(_panelActionLabels(panels), _zhPanelActions);
  });

  testWidgets('en 态：右轨 5 个面板的标题与动作位英文文案逐字命中', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await _pumpProbe(tester, AppLanguage.en);
    final List<ShellRailPanel> panels = todayRailPanels(context);

    expect(_panelTitles(panels), _enPanelTitles);
    expect(_panelActionLabels(panels), _enPanelActions);
  });

  testWidgets('en 态阴性对照：右轨 5 个面板里没有一条中文文案', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await _pumpProbe(tester, AppLanguage.en);
    final List<ShellRailPanel> panels = todayRailPanels(context);

    for (final String title in _zhPanelTitles) {
      expect(
        _panelTitles(panels),
        isNot(contains(title)),
        reason: '英文态不得出现中文面板标题 $title',
      );
    }
    for (final String label in _zhPanelActions) {
      expect(
        _panelActionLabels(panels),
        isNot(contains(label)),
        reason: '英文态不得出现中文动作位文案 $label',
      );
    }
  });
}