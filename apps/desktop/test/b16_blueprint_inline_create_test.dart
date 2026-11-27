// =============================================================================
// B16 · 蓝图页四项改动的判别性验收（W1 棒新建用例）
// =============================================================================
// 本文件只钉**行为**，不改任何 lib 源码。6 条判别链与用户四条反馈的对应：
//  C1（第 1 条）格内点「+」⇒ 该格**就地**出输入框，不弹 `goal_form_dialog`
//      （`goal-blueprint-form-title` 与 `AlertDialog` 都不得出现）。
//  C2（第 1 条）输入标题按 done ⇒ 落库**恰好 1 条**，字段留默认：
//      `kind=blueprint`、`domain`/`horizon` 取自所在格、`note`/`keywords`/
//      `due_date` 全 NULL、`period_start=0`、`period_end`/`deleted_at` 为 NULL。
//  C3（第 2 条）已经存下目标的格子右侧「+」**常驻**（保存后仍在，不是一次性入口）。
//  C4（第 2 条）再点「+」⇒ 输入第二条 ⇒ 同一格**两条记录**（各成一条，不覆盖）。
//  C5（第 3 条）页签垂直内边距 4px、四页签**两态等高** 46px、水平内边距 16px、
//      相邻间距 8px（B17 任务 A 重定口径），且 `TextButton` 的 `padding` 与
//      实测高度都落到这些数上。
//  C6（第 4 条）年份行已下线 + 日期文案 `maxLines == 1` / `softWrap == false`
//      且无溢出异常；点日期文本**一点即出** `goal-period-dialog`（无二次确认）。
//
// 判据口径：C1–C4 走**真库 + 真页面**（回读 SQLite，不看像素）；C5/C6 读
// widget 属性 / `tester.getSize`（不看截图、不做字形断言 —— 桌面测试不预载
// 字体，字形断言必然是假信号）。
//
// 为什么这些断言能红（改前失败方向）：
//  C1 改前点「+」弹的是 `goal_form_dialog`（`goal-blueprint-form-title` 出现、
//     没有 `goal-blueprint-inline-create-*`）⇒ C1 必红。
//  C3/C4 改前已填格**没有**「+」（`goal-blueprint-add-*` findsNothing）⇒ 必红。
//  C5 改前 `tabActiveHeight == 46`、`tabInactiveHeight == 39`（两态有 7px
//     落差）、无 `tabGap`、`padding` 为 `horizontal: 10` ⇒ 必红。
//  C6 改前跨年目标渲染 `goal-blueprint-year-scale`、日期文本可折行 ⇒ 必红。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Goal, GoalLink;
import 'package:core_domain/core_domain.dart' show GoalHorizon, GoalKind;
// `QueryRow` 是 `customSelect` 的行类型，drift 从 2.x 起只在 drift.dart 导出。
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// `goal` 表一行的原生回读结果（列名是真表列名，不是 Dart 字段名）。
class _RawGoal {
  /// 构造。
  const _RawGoal({
    required this.id,
    required this.title,
    required this.kind,
    required this.periodStart,
    this.note,
    this.keywords,
    this.domain,
    this.horizon,
    this.periodEnd,
    this.dueDate,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String kind;
  final String? note;
  final String? keywords;
  final String? domain;
  final int? horizon;

  /// 起止（`period_start` 非空默认 0；`period_end` 可空）。
  final int periodStart;
  final int? periodEnd;
  final int? dueDate;
  final int? deletedAt;
}

const String _goalColumns =
    'id, title, kind, note, keywords, domain, horizon, due_date, '
    'period_start, period_end, deleted_at';

/// 按标题回读目标（用于断言「恰好新增了一条」）。
Future<List<_RawGoal>> _goalsByTitle(ActLogDatabase db, String title) async {
  final List<QueryRow> rows = await db
      .customSelect('SELECT $_goalColumns FROM goal WHERE title = \'$title\'')
      .get();
  return <_RawGoal>[for (final QueryRow r in rows) _fromRow(r.data)];
}

_RawGoal _fromRow(Map<String, Object?> d) => _RawGoal(
  id: d['id']! as String,
  title: d['title']! as String,
  kind: d['kind']! as String,
  note: d['note'] as String?,
  keywords: d['keywords'] as String?,
  domain: d['domain'] as String?,
  horizon: d['horizon'] as int?,
  periodStart: (d['period_start'] as int?) ?? 0,
  periodEnd: d['period_end'] as int?,
  dueDate: d['due_date'] as int?,
  deletedAt: d['deleted_at'] as int?,
);

/// 挂起人生蓝图页（抄 `b12_matrix_tabs_date_test.dart:124-160`）。
Future<void> _pumpBlueprint(
  WidgetTester tester, {
  required ActLogRepositories repos,
  String instance = 'b16-inline-1',
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(
              AppPreferences.defaults,
            ),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(key: ValueKey<String>(instance)),
            ),
          ),
        ),
        language: AppLanguage.zh,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 直接挂矩阵组件（不经过页面布局；抄 `b12_matrix_tabs_date_test.dart:162-191`）。
Future<void> _pumpMatrix(
  WidgetTester tester, {
  required List<GoalBlueprintRow> rows,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
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
            rows: rows,
            serves: const GoalServesIndex(
              <String, List<GoalRow>>{},
              <String, List<GoalRow>>{},
            ),
            tracksCount: const <String, int>{},
            onSplitTodos: (GoalRow _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 滚到某个 key 上并点它（矩阵在长表格里，不 ensureVisible 点不到）。
Future<void> _tapKey(WidgetTester tester, Key key) async {
  final Finder target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// 切到某个标签页（B9-W2 之后矩阵一次只渲染一个档位）。
Future<void> _switchTab(WidgetTester tester, String horizonKey) async {
  await _tapKey(tester, ValueKey<String>('goal-blueprint-tab-$horizonKey'));
}

/// B16 第 1 条：格内「+」→ 就地输入标题 → done 提交 ⇒ 返回新目标的 id。
Future<String> _createInline(
  WidgetTester tester,
  ActLogDatabase db,
  String domainKey,
  String horizonKey,
  String title,
) async {
  await _tapKey(
    tester,
    ValueKey<String>('goal-blueprint-add-$domainKey-$horizonKey'),
  );
  final Finder editor = find.byKey(
    ValueKey<String>('goal-blueprint-inline-create-$domainKey-$horizonKey'),
  );
  expect(editor, findsOneWidget, reason: 'B16 第 1 条：点「+」就地出输入框');
  expect(
    find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
    findsNothing,
    reason: 'B16 第 1 条：就地新建不弹全量表单',
  );
  await tester.enterText(editor, title);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  final List<_RawGoal> created = await _goalsByTitle(db, title);
  expect(created.length, 1, reason: '就地新建的一条必须落库');
  return created.single.id;
}

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late GoalStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'b16-inline-create-test');
    store = GoalStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('C1 空格点「+」⇒ 就地出输入框，不弹 goal_form_dialog', (
    WidgetTester tester,
  ) async {
    await _pumpBlueprint(tester, repos: repos);
    await _switchTab(tester, 'short');

    await _tapKey(
      tester,
      const ValueKey<String>('goal-blueprint-add-learning-short'),
    );

    expect(
      find.byKey(
        const ValueKey<String>('goal-blueprint-inline-create-learning-short'),
      ),
      findsOneWidget,
      reason: 'B16 第 1 条：点「+」后该格进入就地编辑态',
    );
    // 判别性核心：全量表单三个字段一个都不许出现（改前弹的就是它）。
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      findsNothing,
      reason: 'B16 第 1 条：就地新建不得弹 goal_form_dialog（标题字段不许出现）',
    );
    expect(
      find.byType(AlertDialog),
      findsNothing,
      reason: 'B16 第 1 条：不许用任何对话框二次确认',
    );

    // Esc 退出（顺便钉住「就地态可取消」），避免遗留 TextField 焦点。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('goal-blueprint-inline-create-learning-short'),
      ),
      findsNothing,
      reason: 'Esc 应退出就地新建态',
    );
  });

  testWidgets('C2 就地新建提交 ⇒ 库里恰好 1 条且字段留默认', (
    WidgetTester tester,
  ) async {
    await _pumpBlueprint(tester, repos: repos);
    final int before = (await store.listGoals()).length;

    await _switchTab(tester, 'short');
    final String id = await _createInline(
      tester,
      db,
      'learning',
      'short',
      'B16 C2 就地新建',
    );

    final List<_RawGoal> created = await _goalsByTitle(db, 'B16 C2 就地新建');
    expect(created.length, 1, reason: '提交后必须恰好一条，不许重复建条');
    final _RawGoal g = created.single;
    expect(g.id, id);
    expect(g.kind, 'blueprint', reason: '蓝图页新建的必须是蓝图目标');
    expect(g.domain, 'learning', reason: 'domain 取自所在格（learning 行）');
    expect(
      g.horizon,
      GoalHorizon.short.value,
      reason: 'horizon 取自所在格（short 页签）',
    );
    expect(g.note, isNull, reason: '就地新建不收集备注 ⇒ 必须留 NULL');
    expect(g.keywords, isNull, reason: '就地新建不收集关键词 ⇒ 必须留 NULL');
    expect(g.dueDate, isNull, reason: '就地新建不收集期限 ⇒ 必须留 NULL');
    expect(g.periodStart, 0, reason: '没设起止 ⇒ period_start 保持 0');
    expect(g.periodEnd, isNull, reason: '没设起止 ⇒ period_end 保持 NULL');
    expect(g.deletedAt, isNull, reason: '新建不得带墓碑');
    expect(
      (await store.listGoals()).length,
      before + 1,
      reason: '只许多出一条（不许连带建别的记录）',
    );
  });

  testWidgets('C3 已填格右侧「+」常驻（保存后仍在）', (WidgetTester tester) async {
    await store.createGoal(
      kind: GoalKind.blueprint,
      title: 'B16 C3 已有目标',
      domain: 'learning',
      horizon: GoalHorizon.short,
    );

    await _pumpBlueprint(tester, repos: repos);
    await _switchTab(tester, 'short');

    // 正例控制：这确实是「已填」的格子（否则下面测的是空格入口）。
    expect(
      find.text('B16 C3 已有目标'),
      findsOneWidget,
      reason: '正例控制：已填格的标题必须渲染出来',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-learning-short')),
      findsOneWidget,
      reason: 'B16 第 2 条：已填目标不占用「+」入口，它必须常驻在格子里',
    );
  });

  testWidgets('C4 再点「+」⇒ 同格第二条记录（各成一条，不覆盖）', (
    WidgetTester tester,
  ) async {
    final String firstId = await store.createGoal(
      kind: GoalKind.blueprint,
      title: 'B16 C4 第一条',
      domain: 'learning',
      horizon: GoalHorizon.short,
    );

    await _pumpBlueprint(tester, repos: repos);
    await _switchTab(tester, 'short');
    await _createInline(
      tester,
      db,
      'learning',
      'short',
      'B16 C4 第二条',
    );

    final List<_RawGoal> first = await _goalsByTitle(db, 'B16 C4 第一条');
    final List<_RawGoal> second = await _goalsByTitle(db, 'B16 C4 第二条');
    expect(first.length, 1, reason: '第一条不许被覆盖/复制');
    expect(second.length, 1, reason: '第二条必须新增一条记录');
    expect(first.single.id, firstId, reason: '第一条的 id 不许变（不是原地改名）');
    for (final _RawGoal g in <_RawGoal>[first.single, second.single]) {
      expect(g.domain, 'learning');
      expect(g.horizon, GoalHorizon.short.value);
      expect(g.deletedAt, isNull);
    }

    // 保存后「+」仍在 ⇒ 还能继续加第三条（B16 第 2 条）。
    await _switchTab(tester, 'short');
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-add-learning-short')),
      findsOneWidget,
      reason: '两次保存之后「+」仍必须常驻',
    );
    expect(find.text('B16 C4 第一条'), findsOneWidget);
    expect(find.text('B16 C4 第二条'), findsOneWidget);
  });

  testWidgets('C5 页签两态等高 46px、水平内边距 16、间距 8px（B17-A）', (
    WidgetTester tester,
  ) async {
    await _pumpMatrix(
      tester,
      rows: const <GoalBlueprintRow>[
        GoalBlueprintRow(
          domainKey: 'career',
          cells: <GoalHorizon, List<GoalRow>>{},
        ),
      ],
    );

    // 常量口径（B17 任务 A：两态等高 + 加宽 + 8px 间距）。
    expect(GoalBlueprintMatrix.tabHeight, 46);
    expect(GoalBlueprintMatrix.tabGap, 8);
    expect(GoalBlueprintMatrix.tabVerticalPadding, 4);

    const List<String> keys = <String>['ultimate', 'long', 'mid', 'short'];
    for (final String key in keys) {
      final TextButton tab = tester.widget<TextButton>(
        find.byKey(ValueKey<String>('goal-blueprint-tab-$key')),
      );
      expect(
        tab.style!.padding!.resolve(const <WidgetState>{}),
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        reason: 'B17-A：$key 水平 16（加宽）、上下各 4',
      );
      expect(
        tab.style!.minimumSize!.resolve(const <WidgetState>{})!.height,
        46,
        reason: 'B17-A：$key 两态同高 46（不再按 active 分支取值）',
      );
    }

    double heightOf(String key) => tester
        .getSize(find.byKey(ValueKey<String>('goal-blueprint-tab-$key')))
        .height;
    // B17-A：四个页签（含当前激活的 ultimate）实测高均 46。
    for (final String key in keys) {
      expect(heightOf(key), 46, reason: 'B17-A：$key 实测高度 46（两态等高）');
    }
    expect(
      tester.takeException(),
      isNull,
      reason: '加高页签不许撑出 RenderFlex overflow',
    );
  });

  testWidgets('C6 年份行下线 + 日期单行不折行 + 点日期一点即出', (
    WidgetTester tester,
  ) async {
    final String id = await store.createGoal(
      kind: GoalKind.blueprint,
      title: 'B16 C6 跨年目标',
      domain: 'career',
      horizon: GoalHorizon.ultimate,
      periodStart: DateTime(2026, 11, 1).millisecondsSinceEpoch,
      periodEnd: DateTime(2027, 3, 31).millisecondsSinceEpoch,
    );

    await _pumpBlueprint(tester, repos: repos);

    // B16 第 4 条前半：填了起止日期后顶部那一行多余年份必须消失。
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-year-scale')),
      findsNothing,
      reason: 'B16 第 4 条：年份行已下线（跨年目标也不再渲染）',
    );

    // 正例控制：日期列确实渲染了这条目标（否则下面的属性断言挂在空树上）。
    final Finder dateText = find.byKey(
      ValueKey<String>('goal-blueprint-period-text-$id'),
    );
    expect(dateText, findsOneWidget, reason: '正例控制：日期文案必须存在');
    final Text text = tester.widget<Text>(dateText);
    expect(text.maxLines, 1, reason: 'B16 第 4 条：日期文案单行');
    expect(text.softWrap, isFalse, reason: 'B16 第 4 条：日期文案不折行');
    expect(
      tester.takeException(),
      isNull,
      reason: 'B16 第 4 条：日期不换行 ⇒ 不许 overflow',
    );

    // B16 第 4 条后半：点日期文本一点即出选择界面（无二次确认）。
    await _tapKey(tester, ValueKey<String>('goal-blueprint-period-tap-$id'));
    expect(
      find.byKey(const ValueKey<String>('goal-period-dialog')),
      findsOneWidget,
      reason: 'B16 第 4 条：点日期必须**一次点击**就弹出起止日期选择界面',
    );
    expect(
      find.byKey(const ValueKey<String>('goal-period-cancel')),
      findsOneWidget,
      reason: '弹出的必须是起止日期对话框（`DatePickerSheet` 不支持区间）',
    );

    await _tapKey(tester, const ValueKey<String>('goal-period-cancel'));
    expect(
      find.byKey(const ValueKey<String>('goal-period-dialog')),
      findsNothing,
      reason: '取消后对话框必须关闭',
    );
  });
}