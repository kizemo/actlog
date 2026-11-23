// apps/desktop/test/task57_excerpt_test.dart
//
// Task 57 · G（判据 57.4g）：项目页的增量行只是**摘要（摘录）**，不是原文。
// 所以它必须 ① 自证是「摘录」，② 给一条回当天 `day_log` 原文的路。
//
// 本文件钉四条判别性用例：
//   G1：增量行上有「摘录」标注，悬停说明指出原文在当天的日志里；
//   G2：点「查看原文」⇒ `selectedDateProvider` 落到**该条增量的日期**
//       （不是今天、不是最新一条的日期）；
//   G3：同一次点击要请壳层跳页（`onOpenDayLog` 恰好一次）—— 光改日期不跳页，
//       用户还停在项目页，等于什么都没发生；
//   G4（负控，合在 G2/G3 里）：没点之前日期仍是今天、跳页回调零次，
//       防止用例在「初始化就写了一次」的假修复上变绿。
//
// 口径是**真库 + 真界面**：内存 drift 库 + 真仓储，页面自己走 `_reload()`。
import 'package:actlog/src/data/project_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/l10n/l10n_scope.dart';
import 'package:actlog/src/pages/projects_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

const String _today = '2026-11-09';
const String _logDate = '2026-11-05';

/// 内存真库 + 真仓储 + 真项目页。
final class _Harness {
  _Harness._(this.container, this.repos, this.store);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final ProjectStore store;

  /// 种一条项目 + 一条 11-05 的增量。
  Future<void> seedIncrement() async {
    projectId = await store.createProject(name: '甲');
    incrementId = await store.appendIncrement(
      projectId: projectId!,
      date: _logDate,
      progress: '把导入跑通',
    );
  }

  String? projectId;
  String? incrementId;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task57-excerpt-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // LIFO ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos, ProjectStore(repos));
  }

  /// 项目页是内容体，Scaffold 由调用方给；`onOpenDayLog` 由壳层注入。
  Future<void> mount(
    WidgetTester tester, {
    VoidCallback? onOpenDayLog,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: L10nScope(
          localizations: AppLocalizations.zh,
          child: MaterialApp(
            home: Scaffold(body: ProjectsPage(onOpenDayLog: onOpenDayLog)),
          ),
        ),
      ),
    );
  }
}

/// 撑高测试面：项目卡 + 甘特图在 800×600 下会被挤。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  testWidgets('G1：增量行标注「摘录」，并指出原文在当天日志里', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.seedIncrement();
    await harness.mount(tester);
    await _settle(tester);

    final AppLocalizations t = AppLocalizations.zh;
    final Finder tag = find.byKey(
      ValueKey<String>('increment-excerpt-tag-${harness.incrementId}'),
    );
    expect(tag, findsOneWidget, reason: '摘要必须自证是摘录，不能冒充原文');
    expect(tester.widget<Text>(tag).data, t.projectsIncrementExcerptTag);

    final Finder tip = find.ancestor(of: tag, matching: find.byType(Tooltip));
    expect(tip, findsOneWidget, reason: '标注要能说明「原文在哪」');
    expect(tester.widget<Tooltip>(tip).message, t.projectsIncrementExcerptHint);

    expect(
      find.text(t.projectsIncrementOpenOriginalAction),
      findsOneWidget,
      reason: '标注旁边就得有回原文的入口，而不是让用户自己去找',
    );
  });

  testWidgets('G2/G3：点「查看原文」⇒ 选中日切到增量那天 + 请壳层跳页', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.seedIncrement();
    var opened = 0;
    await harness.mount(tester, onOpenDayLog: () => opened++);
    await _settle(tester);

    // 负控：没点之前，日期停在今天、跳页一次都没发生。
    expect(harness.container.read(selectedDateProvider), _today);
    expect(opened, 0);

    final Finder open = find.byKey(
      ValueKey<String>('increment-open-original-${harness.incrementId}'),
    );
    expect(open, findsOneWidget, reason: '摘要必须有一条回原文的路');

    await tester.ensureVisible(open);
    await _settle(tester);
    await tester.tap(open);
    await _settle(tester);

    expect(
      harness.container.read(selectedDateProvider),
      _logDate,
      reason: '要落到该条增量的日期，不是今天',
    );
    expect(opened, 1, reason: '只改日期不跳页 = 用户还停在项目页，等于没跳');
  });
}