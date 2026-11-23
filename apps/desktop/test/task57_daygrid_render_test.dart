// apps/desktop/test/task57_daygrid_render_test.dart
//
// Task 57 · 57.4b 后半：L1 排期写出的 `plan_item` 在**今日页 `DayGrid` 里真的出现**。
//
// 57.4b 原文后半句是「今日页 `DayGrid` 里条目正常出现（key 形如
// `day-grid-entry-${entry.id}`）」。前半（两条入口共用
// `ProjectStore.scheduleToDay`）已由 `task57_project_schedule_test.dart` 的
// 函数级断言钉住；本文件补的是 `docs\B1_验收记录.md:655` 登记为
// 「DayGrid 渲染一致性**未判定**」的那一条 —— 判据此前没有任何断言。
//
// 钉四件事（D1–D4）：
//   D1 存在性：排期写出的行在网格里以 `day-grid-entry-<planItemId>` 出现，恰好一枚；
//   D2 渲染一致性：芯片里读到的标题与库里的 `title` 一致（项目侧 = 项目名）；
//   D3 判别力自证：写入前同一判据 `findsNothing`；另有一条**同库不同日**的排期，
//      它的 key 在当日网格里 `findsNothing` —— 证明 `findsOneWidget` 不是
//      「什么都找得到」（0 命中不等于通过，1 命中也不等于判据有判别力）；
//   D4 两条入口：`source_type='project'` 与 `'increment'` 排出的条目在**同一个**
//      网格里各按自己的 key 出现、标题各自正确（多态指针不污染渲染）。
//
// 不钉什么（D5）：**底色 / 四态**。`DayGrid` 在 `date == todayIso` 时用真实
// `DateTime.now()` 算 `nowMinute`（`day_grid.dart:179`），排在 08:00 的条目
// 「现在过没过 08:00」决定它是 `plannedOpen` 还是 `backfill`，底色因此随时钟漂。
// 条目**是否出现**与时钟无关：`gridEntriesOf` 只要求 `planned_start` /
// `planned_end` 非空（`slot_state.dart:375-382`），四态只影响取色，不影响 key
// 与标题。所以本轮照真实场景跑「今天」（`todayProvider` / `selectedDateProvider`
// / 被测日三者同一天），只钉出现 + 标题 + key。
import 'package:actlog/src/data/project_store.dart';
import 'package:actlog/src/pages/today_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart' show PlanSourceType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 被测日 = 固定的「今天」。
///
/// `planItemsProvider` 跟 `selectedDateProvider` 走，`DayGrid` 的 `date` 又来自
/// `selectedDateProvider`，两者错开网格拿到的会是另一天的行 ⇒ 三者必须同值。
const String _day = '2026-11-09';

/// 负控用的另一天（同库、不同日）。
const String _otherDay = '2026-11-08';

const ValueKey<String> _kGrid = ValueKey<String>('day-grid');

/// 内存真库 + 真仓储 + 固定今天 / 选中日。
///
/// provider 层与 `ProjectStore` 直写共用同一个 `db`，断言读的也是同一份落库数据
/// —— 不 mock 数据层：57.4b 说的就是「落库的行没有在界面上出现」这件事。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task57-daygrid-render-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_day),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _day),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  /// 挂整页今日页内容体（`DayGrid` 在 `today_page.dart:142`）。
  ///
  /// 不套 `LedgerShell`：本轮只看正文里的网格。
  Future<void> mountTodayPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nScope(
          MaterialApp(
            theme: AppTheme.light(DensityProfile.comfortable),
            home: const Scaffold(
              body: SingleChildScrollView(child: TodayPage()),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
  }
}

/// 撑高测试面：今日页整页竖排多段，默认 800×600 会溢出。
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

/// 收尾：卸掉界面放掉 drift 流订阅。
///
/// `ReviewSection.dispose` 里 fire-and-forget 落库，不等它跑完，
/// tearDown 的 `db.close()` 会先关库，这笔写就变成下个用例里的
/// `Can't re-open a database after closing it`。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 网格里**任意**条目的 key（`day-grid-entry-...`）。
///
/// 写入前用它断言「一个都没有」：此时还拿不到 plan item 的 id，只能按前缀数。
Finder _gridEntryKeys() => find.byWidgetPredicate((Widget widget) {
  final Key? key = widget.key;
  return key is ValueKey<String> && key.value.startsWith('day-grid-entry-');
});

/// 某条计划行的首段芯片 key（`day_grid.dart:468-470`：首段 `-<id>`，续段 `-seg-<row>`）。
Finder _tile(String planItemId) =>
    find.byKey(ValueKey<String>('day-grid-entry-$planItemId'));

/// 断言 [planItemId] 的芯片在网格里**恰好一枚**，且芯片内读到的标题 == [title]。
///
/// 标题用 `find.text` 取（`Text.data` 持有完整字符串，`maxLines: 1` +
/// `TextOverflow.ellipsis` 只影响画出来的宽度，不改 `data`）；再用
/// `tester.widget<Text>` 读一次实际值，防止「find 命中了别的控件」。
void _expectTileWithTitle(
  WidgetTester tester,
  String planItemId,
  String title,
) {
  final Finder tile = _tile(planItemId);
  expect(tile, findsOneWidget, reason: '条目 $planItemId 没排进格子');
  expect(
    find.descendant(of: find.byKey(_kGrid), matching: tile),
    findsOneWidget,
    reason: '这一枚必须是 DayGrid 里的条目，不是页面别处的同 key 部件',
  );

  final Finder titleText =
      find.descendant(of: tile, matching: find.text(title));
  expect(
    titleText,
    findsOneWidget,
    reason: '芯片里读不到库中的标题「$title」',
  );
  expect(
    tester.widget<Text>(titleText).data,
    title,
    reason: '芯片里的文本必须与库里的 title 逐字相同',
  );
}

void main() {
  group('今日页 DayGrid · L1 排期渲染', () {
    testWidgets('D1 + D3：写入前网格零条目，写入后 day-grid-entry-<id> 恰好一枚', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      final ProjectStore store = ProjectStore(harness.repos);

      final String projectId =
          (await tester.runAsync(() => store.createProject(name: '甲项目')))!;

      await harness.mountTodayPage(tester);

      // 前提：网格挂上来了（否则「findsNothing」毫无意义）。
      expect(find.byKey(_kGrid), findsOneWidget, reason: '方格时间轴没挂上');

      // D3 前半：还没排期 ⇒ 网格里一个条目都没有（先能看见「没有」）。
      expect(
        _gridEntryKeys(),
        findsNothing,
        reason: '尚未排期，网格里不该有任何条目',
      );
      expect(
        await tester.runAsync(
          () => harness.repos.planItem.listByDate(_day),
        ),
        isEmpty,
        reason: '库里也还没这一天的计划行',
      );

      // D1 正样本：走项目侧入口（L1 的唯一落库方法）。
      final String planItemId = (await tester.runAsync(
        () => store.scheduleToDay(
          date: _day,
          sourceType: PlanSourceType.project,
          sourceId: projectId,
          title: '甲项目',
        ),
      ))!;

      await _settle(tester);

      // D3 后半 + D1：同一条判据现在必须命中。
      expect(
        _tile(planItemId),
        findsOneWidget,
        reason: '排期写出的行必须在今日页 DayGrid 里出现',
      );
      expect(
        _gridEntryKeys(),
        findsOneWidget,
        reason: '当天只有这一条排期，网格里就该只有这一枚条目',
      );

      await _flushTimers(tester);
    });

    testWidgets('D2：项目侧排期的芯片标题 = 项目名（与库一致）', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      final ProjectStore store = ProjectStore(harness.repos);

      final String projectId = (await tester.runAsync(
        () => store.createProject(name: '季度复盘项目'),
      ))!;
      final String planItemId = (await tester.runAsync(
        () => store.scheduleToDay(
          date: _day,
          sourceType: PlanSourceType.project,
          sourceId: projectId,
          title: '季度复盘项目',
        ),
      ))!;

      // 先写库、再挂载：让 stream 首次推送就带上这条。
      await harness.mountTodayPage(tester);

      _expectTileWithTitle(tester, planItemId, '季度复盘项目');

      final List<PlanItemData>? rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_day),
      );
      expect(rows, hasLength(1));
      expect(
        rows!.single.title,
        '季度复盘项目',
        reason: '渲染的标题必须与库里的 title 同源（项目侧传的是项目名）',
      );
      expect(rows.single.sourceType, 'project');

      await _flushTimers(tester);
    });

    testWidgets('D4：项目侧与增量侧在同一网格里各自命中、标题各自正确', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      final ProjectStore store = ProjectStore(harness.repos);

      final String projectId = (await tester.runAsync(
        () => store.createProject(name: '乙项目'),
      ))!;
      final String incrementId = (await tester.runAsync(
        () => store.appendIncrement(
          projectId: projectId,
          date: _day,
          progress: '写完了数据层',
        ),
      ))!;

      final String projectPlanId = (await tester.runAsync(
        () => store.scheduleToDay(
          date: _day,
          sourceType: PlanSourceType.project,
          sourceId: projectId,
          title: '乙项目',
        ),
      ))!;
      // 增量侧标题 = 增量摘要（`projects_page.dart:206` 的 title 口径）。
      final String incrementPlanId = (await tester.runAsync(
        () => store.scheduleToDay(
          date: _day,
          sourceType: PlanSourceType.increment,
          sourceId: incrementId,
          title: '写完了数据层',
        ),
      ))!;

      expect(
        projectPlanId,
        isNot(incrementPlanId),
        reason: '两条入口各自落一行，不许共用同一条计划行',
      );

      await harness.mountTodayPage(tester);

      expect(find.byKey(_kGrid), findsOneWidget);
      // 两条都在同一个网格里：不是「后一条把前一条顶掉」。
      _expectTileWithTitle(tester, projectPlanId, '乙项目');
      _expectTileWithTitle(tester, incrementPlanId, '写完了数据层');

      final List<PlanItemData>? rows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_day),
      );
      expect(rows, hasLength(2));
      expect(
        rows!.map((PlanItemData row) => row.sourceType).toSet(),
        <String>{'project', 'increment'},
        reason: '两条入口的落库差异只在 source_type / source_id，渲染面不分叉',
      );

      await _flushTimers(tester);
    });

    testWidgets('D3 负控：同库另一天的排期不出现在这一天的网格里', (
      WidgetTester tester,
    ) async {
      _useTallSurface(tester);
      final harness = _Harness.create();
      final ProjectStore store = ProjectStore(harness.repos);
      final TimelineStore timelineStore = TimelineStore(harness.repos);

      // 正样本：被测日的一条项目侧排期。
      final String projectId = (await tester.runAsync(
        () => store.createProject(name: '丙项目'),
      ))!;
      final String shownId = (await tester.runAsync(
        () => store.scheduleToDay(
          date: _day,
          sourceType: PlanSourceType.project,
          sourceId: projectId,
          title: '丙项目',
        ),
      ))!;

      // 负控：普通待办池排期，落在**另一天**。它是一条真实的 `plan_item`
      // （库里有行、也有合法的 `day-grid-entry-<id>` key 形状），只是不属于
      // 被测日 ⇒ 当日网格里不该有它。若判据是「什么都找得到」，这条会当场红。
      // 坑：`createTodoWithSlot` 返回的是 `todo.id`，不是 `plan_item.id`
      // （plan_item 在内部另建一行），所以网格 key 只能从落库行读回。
      await tester.runAsync(
        () => timelineStore.createTodoWithSlot(
          date: _otherDay,
          title: '无关的另一天待办',
          startMinute: 9 * 60,
          endMinute: 9 * 60 + 30,
        ),
      );

      await harness.mountTodayPage(tester);

      // 负控不是「根本没建出来」：库里确实有这一行。
      final List<PlanItemData>? otherRows = await tester.runAsync(
        () => harness.repos.planItem.listByDate(_otherDay),
      );
      expect(
        otherRows,
        hasLength(1),
        reason: '负控条目必须真的写进了库，否则「找不到」证明不了判别力',
      );
      final String hiddenId = otherRows!.single.id;
      expect(hiddenId, isNotEmpty);
      expect(otherRows.single.date, _otherDay);

      // 两句话缺一不可：正样本在、负控不在。
      expect(
        _tile(shownId),
        findsOneWidget,
        reason: '被测日的排期必须在网格里',
      );
      expect(
        _tile(hiddenId),
        findsNothing,
        reason: '同库另一天的条目不该出现在这一天的网格里',
      );
      expect(
        find.text('无关的另一天待办'),
        findsNothing,
        reason: '它的标题也不该出现在今日页上',
      );

      await _flushTimers(tester);
    });
  });
}