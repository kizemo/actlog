// =============================================================================
// B17 波 B · W2：目标表单扩字段（类别 / 起止日期）+ 行内完成单选 + 类别分区
// =============================================================================
// 守的判据（派工书 `docs/b17-plan.md` §4 W2 行 + 派工书 §5）：
//  1. 表单有「目标类别」「起止日期」两行；选 `wealth` ⇒ `category == 'wealth'`；
//  2. 自定义类别 `旅行` ⇒ `category == 'custom:旅行'`；空白 ⇒ `null`；
//  3. 点起止日期行 ⇒ 真的弹 `showGoalPeriodDialog`（不是另写一套），
//     确认 / 清除的结果都要写回表单状态（显示 + 提交值）；
//  4. **向后兼容**：只传旧参数（既有 4 个调用点的形态）⇒ 正常打开、旧字段
//     语义不变、新字段为 null；`showCategory/showPeriod: false` ⇒ 两行不渲染；
//  5. `GoalRowActions.onToggleDone == null` ⇒ 不渲染且宽度仍 56；非 null ⇒
//     `goal-row-done-<id>` 可点、回调一次、总宽 = 56 + 24；
//  6. `GoalCategorySections` / `GoalSectionList` ⇒ 按传入分区顺序渲染小标题，
//     ValueKey 逐字 `goal-section-<displayKey>` / `goal-section-title-<...>`；
//     泛型版能吃读侧 `GoalRow`（波 C 的真实行模型）。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goals/goal_category.dart';
import 'package:actlog/src/widgets/goals/goal_form_dialog.dart';
import 'package:actlog/src/widgets/goals/goal_section.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 新建态的预填起始（本地午夜，B11 口径）。
final DateTime _start = DateTime(2026, 11, 1);

/// 新建态的预填结束（本地午夜，B11 口径）。
final DateTime _end = DateTime(2026, 11, 30);

/// 宿主：按需传参打开表单，把结果拼成一行文本。
class _Host extends StatefulWidget {
  const _Host({
    this.showCategory = true,
    this.showPeriod = true,
    this.initialPeriodStart,
    this.initialPeriodEnd,
  });

  final bool showCategory;
  final bool showPeriod;
  final DateTime? initialPeriodStart;
  final DateTime? initialPeriodEnd;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  GoalFormResult? _form;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: const ValueKey<String>('host-open'),
            onPressed: () async {
              final GoalFormResult? form = await showGoalFormDialog(
                context,
                t: t,
                showCategory: widget.showCategory,
                showPeriod: widget.showPeriod,
                initialPeriodStart: widget.initialPeriodStart,
                initialPeriodEnd: widget.initialPeriodEnd,
              );
              setState(() => _form = form);
            },
            child: const Text('open'),
          ),
          Text(_formText, key: const ValueKey<String>('host-result')),
        ],
      ),
    );
  }

  /// `title|category|periodStart|periodEnd`（毫秒；null 原样写 null）。
  String get _formText {
    final GoalFormResult? form = _form;
    if (form == null) {
      return 'result:null';
    }
    return 'result:${form.title}|${form.category}|'
        '${form.periodStart?.millisecondsSinceEpoch}|'
        '${form.periodEnd?.millisecondsSinceEpoch}';
  }
}

/// 挂起宿主（真 MaterialApp + l10nScope，与页面用例同一套壳）。
Future<void> _pumpHost(
  WidgetTester tester, {
  bool showCategory = true,
  bool showPeriod = true,
  DateTime? initialPeriodStart,
  DateTime? initialPeriodEnd,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        _Host(
          showCategory: showCategory,
          showPeriod: showPeriod,
          initialPeriodStart: initialPeriodStart,
          initialPeriodEnd: initialPeriodEnd,
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 打开表单并填一个非空标题（否则「保存」置灰）。
Future<void> _openWithTitle(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('host-open')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
    '写周报',
  );
  await tester.pump();
}

/// 收起键盘焦点后点「保存」。
Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('goal-blueprint-form-save')));
  await tester.pumpAndSettle();
}

/// 读宿主导出的结果串（已剥掉 `result:` 前缀，按下标取字段）。
String _resultText(WidgetTester tester) {
  const String prefix = 'result:';
  final String raw = tester
      .widget<Text>(find.byKey(const ValueKey<String>('host-result')))
      .data!;
  return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
}

/// 读起止日期行的显示文本。
String _rangeText(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey<String>('goal-form-date-range-text')))
    .data!;

/// 一条最小 `Goal`（分区件的领域模型路径用）。
Goal _goal(String id, {String? domain}) => Goal(
  id: id,
  kind: GoalKind.yearly,
  title: id,
  createdAt: 0,
  updatedAt: 0,
  originDeviceId: 'b17-w2',
  domain: domain,
);

/// 一条最小 `GoalRow`（读侧行模型；无 `originDeviceId`，波 C 的真实输入）。
GoalRow _row(String id, {String? domain}) => GoalRow(
  id: id,
  kind: GoalKind.monthly,
  title: id,
  status: GoalStatus.active,
  periodStart: 0,
  createdAt: 0,
  updatedAt: 0,
  domain: domain,
);

void main() {
  testWidgets('类别行：两行齐备；选 wealth 后提交 category == wealth', (
    WidgetTester tester,
  ) async {
    await _pumpHost(tester);
    await _openWithTitle(tester);

    expect(
      find.byKey(const ValueKey<String>('goal-form-category-field')),
      findsOneWidget,
      reason: '类别选择行必须存在（key 契约 goal-form-category-field）',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-form-date-range')),
      findsOneWidget,
      reason: '起止日期行必须存在（key 契约 goal-form-date-range）',
    );
    expect(find.text('目标类别'), findsOneWidget);
    expect(find.text('起止日期'), findsOneWidget);

    // 打开类别菜单：7 个选项（5 预设 + 自定义 + 不设类别）逐字带 key。
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-field')),
    );
    await tester.pumpAndSettle();
    for (final String key in <String>[
      ...goalCategoryKeys,
      goalCategoryCustomKey,
      goalCategoryNoneKey,
    ]) {
      expect(
        find.byKey(ValueKey<String>('goal-form-category-$key')),
        findsOneWidget,
        reason: '类别选项 key 契约 goal-form-category-$key',
      );
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-wealth')),
    );
    await tester.pumpAndSettle();
    await _save(tester);

    expect(_resultText(tester).split('|')[1], 'wealth');
  });

  testWidgets('自定义类别：填「旅行」⇒ custom:旅行；只填空白 ⇒ null', (
    WidgetTester tester,
  ) async {
    await _pumpHost(tester);
    await _openWithTitle(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-custom')),
    );
    await tester.pumpAndSettle();

    // 选「自定义类别」才出现输入框。
    expect(
      find.byKey(const ValueKey<String>('goal-form-category-custom-input')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-form-category-custom-input')),
      '  旅行  ',
    );
    await tester.pump();
    await _save(tester);
    expect(_resultText(tester).split('|')[1], 'custom:旅行');

    // 第二轮：只填空白 ⇒ 视同不设类别。
    await tester.tap(find.byKey(const ValueKey<String>('host-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      '开会',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-category-custom')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-form-category-custom-input')),
      '   ',
    );
    await tester.pump();
    await _save(tester);
    expect(_resultText(tester).split('|')[1], 'null');
  });

  testWidgets('起止日期：点整行弹共享弹窗；确认回填、清除回退为未设置', (
    WidgetTester tester,
  ) async {
    await _pumpHost(
      tester,
      initialPeriodStart: _start,
      initialPeriodEnd: _end,
    );
    await _openWithTitle(tester);

    expect(_rangeText(tester), '2026-11-01 → 2026-11-30');

    // 点整行（不是小图标）⇒ 真弹出 B10-B4 的共享对话框。
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-date-range')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('goal-period-dialog')),
      findsOneWidget,
      reason: '起止日期行必须复用 showGoalPeriodDialog，而不是自己造一套弹窗',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-period-confirm')),
    );
    await tester.pumpAndSettle();
    expect(_rangeText(tester), '2026-11-01 → 2026-11-30');

    // 清除 ⇒ 表单状态真的被写回（显示 + 提交值都要变 null）。
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-form-date-range')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('goal-period-clear')));
    await tester.pumpAndSettle();
    expect(
      _rangeText(tester),
      AppLocalizations.zh.goalPeriodUnset,
      reason: '清除后两端都空 ⇒ 显示「未设置日期」',
    );

    await _save(tester);
    final List<String> parts = _resultText(tester).split('|');
    expect(parts[2], 'null');
    expect(parts[3], 'null');
  });

  testWidgets('向后兼容：只传旧参数仍可用；关掉两行不渲染且不崩', (
    WidgetTester tester,
  ) async {
    // ① 既有 4 个调用点的形态（不传任何 B17 新参数）。
    await _pumpHost(tester);
    await _openWithTitle(tester);
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-form-domain')),
      findsOneWidget,
    );
    await _save(tester);
    final List<String> parts = _resultText(tester).split('|');
    expect(parts[0], '写周报');
    expect(parts[1], 'null', reason: '不选类别 ⇒ null');
    expect(parts[2], 'null', reason: '不设起止 ⇒ null');
    expect(parts[3], 'null');

    // ② 显式关掉：页面只想保留旧字段。
    await _pumpHost(tester, showCategory: false, showPeriod: false);
    await _openWithTitle(tester);
    expect(
      find.byKey(const ValueKey<String>('goal-form-category-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-form-date-range')),
      findsNothing,
    );
    await _save(tester);
    expect(_resultText(tester).split('|')[0], '写周报');
  });

  testWidgets('行内完成单选：null 不渲染且宽度仍 56；非 null 可点且总宽 80', (
    WidgetTester tester,
  ) async {
    int toggles = 0;

    Widget host({required bool withDone}) => MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        Scaffold(
          body: Center(
            child: Builder(
              builder: (BuildContext context) => GoalRowActions(
                editKey: 'row-edit-1',
                deleteKey: 'row-delete-1',
                onEdit: () {},
                onDelete: () {},
                t: AppLocalizations.of(context),
                goalId: 'g1',
                isDone: true,
                onToggleDone: withDone ? () => toggles += 1 : null,
              ),
            ),
          ),
        ),
        language: AppLanguage.zh,
      ),
    );

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // ① 没有回调：单选不渲染、总宽仍是 56（蓝图矩阵走这条路径）。
    await tester.pumpWidget(host(withDone: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('goal-row-done-g1')), findsNothing);
    expect(GoalRowActions.width, 56);
    expect(GoalRowActions.doneWidth, 24);
    expect(
      tester.getSize(find.byType(GoalRowActions)).width,
      56,
      reason: '不渲染单选时宽度必须仍是 56（表头预留列与蓝图矩阵 shrinkWrap 依赖）',
    );

    // ② 有回调：button 存在、点击只回调一次、总宽 = 56 + 24。
    await tester.pumpWidget(host(withDone: true));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('goal-row-done-g1')),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(GoalRowActions)).width, 80);
    await tester.tap(find.byKey(const ValueKey<String>('goal-row-done-g1')));
    await tester.pumpAndSettle();
    expect(toggles, 1);
  });

  testWidgets('类别分区：小标题与容器 key 逐字；顺序 = 预设 → 未分类垫底', (
    WidgetTester tester,
  ) async {
    final AppLocalizations zh = AppLocalizations.zh;
    // 输入乱序：未分类在最前，验证分区件不依赖传入顺序出标题顺序。
    final List<GoalCategoryGroup> groups = groupGoalsByCategory(zh, <Goal>[
      _goal('n1'),
      _goal('h1', domain: 'health'),
      _goal('w1', domain: 'wealth'),
      _goal('w2', domain: 'wealth'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalCategorySections(
              groups: groups,
              rowBuilder: (BuildContext context, Goal goal) =>
                  SizedBox(key: ValueKey<String>('row-${goal.id}'), height: 24),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final String key in <String>['wealth', 'health', goalCategoryNoneKey]) {
      expect(
        find.byKey(ValueKey<String>('goal-section-$key')),
        findsOneWidget,
        reason: '分区容器 key 契约 goal-section-$key',
      );
      expect(
        find.byKey(ValueKey<String>('goal-section-title-$key')),
        findsOneWidget,
        reason: '分区标题 key 契约 goal-section-title-$key',
      );
    }
    expect(find.byKey(const ValueKey<String>('row-w1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('row-w2')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('row-h1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('row-n1')), findsOneWidget);

    // 预设在前、未分类垫底（用 dy 比序，不依赖具体像素）。
    final double wealthY = tester
        .getTopLeft(find.byKey(const ValueKey<String>('goal-section-wealth')))
        .dy;
    final double healthY = tester
        .getTopLeft(find.byKey(const ValueKey<String>('goal-section-health')))
        .dy;
    final double noneY = tester
        .getTopLeft(
          find.byKey(ValueKey<String>('goal-section-$goalCategoryNoneKey')),
        )
        .dy;
    expect(wealthY, lessThan(healthY));
    expect(healthY, lessThan(noneY));

    // 空分区 + emptyText ⇒ 空态 key（附加契约，不影响上面 8 条）。
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Scaffold(
          body: GoalCategorySections(
            groups: const <GoalCategoryGroup>[],
            rowBuilder: (BuildContext context, Goal goal) => const SizedBox(),
            emptyText: zh.goalCategoryUncategorized,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('goal-section-empty')),
      findsOneWidget,
    );
  });

  testWidgets('泛型分区：读侧 GoalRow 也能直接分区渲染（波 C 的真实行模型）', (
    WidgetTester tester,
  ) async {
    final AppLocalizations zh = AppLocalizations.zh;
    final List<GoalRow> rows = <GoalRow>[
      _row('r-none'),
      _row('r-trip', domain: 'custom:旅行'),
      _row('r-wealth', domain: 'wealth'),
    ];
    final List<GoalSectionGroup<GoalRow>> groups =
        groupSectionsByCategory<GoalRow>(
          zh,
          rows,
          domainOf: (GoalRow row) => row.domain,
        );

    expect(
      groups.map((GoalSectionGroup<GoalRow> g) => g.displayKey).toList(),
      <String>['wealth', 'custom:旅行', goalCategoryNoneKey],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalSectionList<GoalRow>(
              groups: groups,
              rowBuilder: (BuildContext context, GoalRow row) =>
                  SizedBox(key: ValueKey<String>('row-${row.id}'), height: 24),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('goal-section-custom:旅行')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-section-title-custom:旅行')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('goal-section-title-custom:旅行')),
          )
          .data,
      '旅行',
      reason: '自定义类别的小标题直接显示用户文本（不套「自定义」前缀）',
    );
    expect(find.byKey(const ValueKey<String>('row-r-wealth')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('row-r-trip')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('row-r-none')), findsOneWidget);
  });
}