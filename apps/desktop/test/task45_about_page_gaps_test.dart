// apps/desktop/test/task45_about_page_gaps_test.dart
//
// Task 45 · W4 —— 关于页 G1–G9 差距补齐 + 设置页入口。
//
// 全程不联网、不碰系统：`releaseCheckerProvider` / `systemIntegrationProvider`
// 注入假实现；设置页入口用例使用内存真库（跑完随 `db.close` 消失）。
import 'package:actlog/src/app_version.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/about_page.dart';
import 'package:actlog/src/pages/settings_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只记调用、只回固定结果的版本检查器。
final class _FakeChecker implements ReleaseChecker {
  _FakeChecker(this.result);

  final ReleaseCheckResult result;
  int calls = 0;

  @override
  Future<ReleaseCheckResult> check() async {
    calls++;
    return result;
  }
}

/// 只记「打开过哪个链接」的系统集成假实现。
final class _FakeSystem implements SystemIntegration {
  final List<String> opened = <String>[];

  @override
  String executablePath() => r'C:\fake\actlog.exe';

  @override
  Future<bool> setLaunchOnBoot(bool enabled) async => true;

  @override
  Future<String?> readLaunchOnBoot() async => null;

  @override
  Future<bool> createDesktopShortcut() async => true;

  @override
  Future<bool> openUrl(String url) async {
    opened.add(url);
    return true;
  }
}

final class _Harness {
  _Harness._(this.container, this.checker, this.system);

  final ProviderContainer container;
  final _FakeChecker checker;
  final _FakeSystem system;

  static _Harness create({
    required ReleaseCheckResult result,
    AppLanguage language = AppLanguage.zh,
  }) {
    final checker = _FakeChecker(result);
    final system = _FakeSystem();
    final container = ProviderContainer(
      overrides: <Override>[
        currentPreferencesProvider
            .overrideWithValue(AppPreferences.defaults.copyWith(language: language)),
        releaseCheckerProvider.overrideWithValue(checker),
        systemIntegrationProvider.overrideWithValue(system),
      ],
    );
    addTearDown(container.dispose);
    return _Harness._(container, checker, system);
  }

  Future<void> mount(WidgetTester tester, {Widget? child}) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: child ?? const AboutPage()),
          ),
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

void _useShortSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

/// 真库写入后的等待（不用 `pumpAndSettle`：drift 流订阅永不到「无待处理帧」）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

ValueKey<String> _key(String value) => ValueKey<String>(value);

/// 取某枚按钮（`Container`）当前的边框色。
Color _borderColorOf(WidgetTester tester, String key) {
  final Container container = tester.widget<Container>(find.byKey(_key(key)));
  final BoxDecoration decoration = container.decoration! as BoxDecoration;
  return (decoration.border! as Border).top.color;
}

/// 取包住某枚按钮的 `InkWell`（唯一祖先）。
InkWell _inkOf(WidgetTester tester, String key) {
  return tester.widget<InkWell>(
    find.ancestor(
      of: find.byKey(_key(key)),
      matching: find.byType(InkWell),
    ),
  );
}

void main() {
  final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);

  testWidgets('G1/G2/G3 新增区块的 key 与内容都真实', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    for (final String key in <String>[
      'about-changelog',
      'about-privacy',
      'about-licenses',
    ]) {
      expect(find.byKey(_key(key)), findsOneWidget, reason: '缺少 $key');
    }

    // G1：最近变更是多条短句，不是一行占位。
    final String changelog =
        tester.widget<Text>(find.byKey(_key('about-changelog'))).data!;
    expect(
      changelog.split('\n').where((String line) => line.trim().isNotEmpty).length,
      greaterThanOrEqualTo(3),
    );

    // G3：内容必须逐字为真 —— 本机 SQLite、只在检查更新时联网、无遥测。
    final String privacy =
        tester.widget<Text>(find.byKey(_key('about-privacy'))).data!;
    expect(privacy, contains('SQLite'));
    expect(privacy, contains('GitHub'));

    // G2：只写仓库里真实存在的资产（四份 OFL + 依赖清单），不凭印象编许可证名。
    final String licenses =
        tester.widget<Text>(find.byKey(_key('about-licenses'))).data!;
    expect(licenses, contains('OFL'));
    expect(licenses, contains('pubspec.yaml'));

    // Task 46 · G2：真依赖 + 真许可证名逐条对齐（BSD-3-Clause 不许写成 MIT）。
    const Map<String, String> deps = <String, String>{
      'cupertino_icons': 'MIT',
      'drift': 'MIT',
      'flutter_riverpod': 'MIT',
      'window_manager': 'MIT',
      'tray_manager': 'MIT',
      'sqlite3': 'MIT',
      'flutter_local_notifications': 'BSD-3-Clause',
      'path': 'BSD-3-Clause',
      'path_provider': 'BSD-3-Clause',
    };
    for (final MapEntry<String, String> dep in deps.entries) {
      expect(licenses, contains('${dep.key}（${dep.value}）'),
          reason: '${dep.key} 应标 ${dep.value}');
    }
    expect(licenses, contains('SIL Open Font License 1.1'));
    expect(licenses, contains('BSD-3-Clause'));
  });

  testWidgets('G1/G3 区块顺序：版本 → 最近变更 → 数据与隐私 → 仓库 → 许可证',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    final double changelog =
        tester.getRect(find.byKey(_key('about-changelog'))).top;
    final double privacy =
        tester.getRect(find.byKey(_key('about-privacy'))).top;
    final double repo = tester.getRect(find.byKey(_key('about-repo-url'))).top;
    final double licenses =
        tester.getRect(find.byKey(_key('about-licenses'))).top;

    expect(changelog, greaterThan(tester.getRect(find.byKey(_key('about-version'))).top));
    expect(privacy, greaterThan(changelog));
    expect(repo, greaterThan(privacy));
    expect(licenses, greaterThan(repo));
    expect(find.text(zh.sectionRepository), findsWidgets);
  });

  testWidgets('G5 有更新时给「打开发布页」，指向仓库 releases',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(
        ReleaseCheckStatus.newer,
        latestTag: 'v0.2.0',
      ),
    );
    await h.mount(tester);
    await _pump(tester);

    // 还没检查之前不该出现（不伪造「有更新」的入口）。
    expect(find.byKey(_key('about-open-releases')), findsNothing);

    await tester.tap(find.byKey(_key('about-check-update')));
    await _pump(tester);

    expect(find.byKey(_key('about-open-releases')), findsOneWidget);
    await tester.tap(find.byKey(_key('about-open-releases')));
    await _pump(tester);

    expect(h.system.opened, <String>['$kAppRepositoryUrl/releases']);
  });

  testWidgets('G5 无发布 / 网络失败 / 已最新 ⇒ 不出现发布页入口',
      (WidgetTester tester) async {
    for (final ReleaseCheckStatus status in <ReleaseCheckStatus>[
      ReleaseCheckStatus.noRelease,
      ReleaseCheckStatus.networkError,
      ReleaseCheckStatus.upToDate,
    ]) {
      final _Harness h = _Harness.create(
        result: ReleaseCheckResult(status),
      );
      _useTallSurface(tester);
      await h.mount(tester);
      await _pump(tester);

      await tester.tap(find.byKey(_key('about-check-update')));
      await _pump(tester);

      expect(
        find.byKey(_key('about-open-releases')),
        findsNothing,
        reason: '$status 下不该出现发布页入口',
      );
    }
  });

  testWidgets('G6 可用按钮在 Tab 序内、禁用按钮被跳过', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    for (final String key in <String>[
      'about-check-update',
      'about-open-repo',
      'about-copy-repo',
      'about-open-developer',
      'about-open-alpha',
      'about-open-pageweaver',
    ]) {
      expect(_inkOf(tester, key).canRequestFocus, isTrue, reason: '$key 键盘不可达');
    }
    // 在线升级恒禁用 ⇒ 不进 Tab 序。
    expect(_inkOf(tester, 'about-online-upgrade').canRequestFocus, isFalse);
  });

  testWidgets('G6 键盘 Enter 能激活按钮', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    final BuildContext ctx = tester.element(find.byKey(_key('about-open-repo')));
    Focus.of(ctx, createDependency: false).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(h.system.opened, <String>[kAppRepositoryUrl]);
  });

  testWidgets('G7 focus 态边框色与默认 / hover 态不同', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    // hover：鼠标停在「复制仓库地址」上（默认态与 hover 态同为 hairStrong）。
    final TestGesture mouse =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(_key('about-copy-repo'))));
    await tester.pumpAndSettle();
    final Color hovered = _borderColorOf(tester, 'about-copy-repo');

    // focus：键盘焦点落在「打开仓库」上。
    final BuildContext ctx = tester.element(find.byKey(_key('about-open-repo')));
    Focus.of(ctx, createDependency: false).requestFocus();
    await tester.pumpAndSettle();
    final Color focused = _borderColorOf(tester, 'about-open-repo');

    expect(focused, isNot(hovered));
    expect(
      _borderColorOf(tester, 'about-online-upgrade'),
      isNot(focused),
      reason: '禁用态不该和 focus 态同色',
    );
  });

  testWidgets('G8 本页导航列出全部七个区块', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    // 导航条目 = 套在 `InkWell` 里的标题文本；区块标题本身是裸 `Text`，
    // 所以每个标题应该恰好命中一枚导航条目。
    for (final String label in <String>[
      '版本',
      '最近变更',
      '数据与隐私',
      '仓库',
      '开发者',
      '其它软件',
      '许可证',
    ]) {
      expect(
        find.widgetWithText(InkWell, label),
        findsOneWidget,
        reason: '本页导航缺少「$label」',
      );
    }
  });

  testWidgets('G8 点导航能把末块滚进视口', (WidgetTester tester) async {
    _useShortSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    expect(tester.getRect(find.byKey(_key('about-licenses'))).top,
        greaterThan(500.0));

    await tester.tap(find.widgetWithText(InkWell, '许可证'));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(_key('about-licenses'))).top,
        lessThan(500.0));
  });

  testWidgets('G9 200% 文字缩放无溢出', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(2),
                size: Size(1400, 3000),
              ),
              child: SingleChildScrollView(child: AboutPage()),
            ),
          ),
        ),
      ),
    );
    await _pump(tester);

    // 先证明缩放真的生效（否则这条用例等于没跑）。
    expect(
      MediaQuery.textScalerOf(tester.element(find.byKey(_key('about-page'))))
          .scale(10),
      20,
    );
    // 溢出的表现是抛 `RenderFlex overflowed`；`takeException` 为 null 才算过。
    expect(tester.takeException(), isNull);
    expect(find.byKey(_key('about-licenses')), findsOneWidget);
  });

  testWidgets('英文档下新增区块文案整体切换', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
      language: AppLanguage.en,
    );
    await h.mount(tester);
    await _pump(tester);

    final String privacy =
        tester.widget<Text>(find.byKey(_key('about-privacy'))).data!;
    expect(privacy, contains('SQLite'));
    expect(privacy, contains('SQLite database'));
    expect(find.text('数据与隐私'), findsNothing);
    expect(find.text('Data & privacy'), findsWidgets);
  });

  testWidgets('设置页有「关于」入口，点击进入关于页', (WidgetTester tester) async {
    _useTallSurface(tester);
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task45-about-entry');
    final system = _FakeSystem();
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue('2026-11-09'),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => '2026-11-09'),
        systemIntegrationProvider.overrideWithValue(system),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // 入口复用壳里注册的 `/about` 深链，不新增路由名字。
          routes: <String, WidgetBuilder>{
            '/about': (_) => const Scaffold(
                  body: SingleChildScrollView(child: AboutPage()),
                ),
          },
          home: const Scaffold(
            body: SingleChildScrollView(child: SettingsPage()),
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.byKey(_key('settings-open-about')), findsOneWidget);
    expect(find.text(zh.aboutTitle), findsWidgets);

    await tester.tap(find.byKey(_key('settings-open-about')));
    await _settle(tester);

    expect(find.byKey(_key('about-page')), findsOneWidget);
    expect(find.byKey(_key('about-version')), findsOneWidget);
  });

  // Task 46 · G4：检查结果可复制 —— 与其它按钮同构（key 在按钮上、可用可聚焦）。
  testWidgets('Task 46 G4 检查结果右侧有一枚复制按钮', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    expect(find.byKey(_key('about-copy-result')), findsNothing);

    await tester.tap(find.byKey(_key('about-check-update')));
    await _pump(tester);

    expect(find.byKey(_key('about-copy-result')), findsOneWidget);
    // 结果行仍是普通 `Text`（Task 39 逐字断言依赖）⇒ 复制靠旁挂按钮实现。
    expect(find.byKey(_key('about-check-result')), findsOneWidget);
    expect(find.text('复制结果'), findsOneWidget);
    expect(_inkOf(tester, 'about-copy-result').canRequestFocus, isTrue);
  });

  // Task 46 · G2/G4：既有 ValueKey 一枚都不许被改名或删掉。
  testWidgets('既有 ValueKey 全部仍在', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(
        ReleaseCheckStatus.newer,
        latestTag: 'v0.2.0',
      ),
    );
    await h.mount(tester);
    await _pump(tester);
    await tester.tap(find.byKey(_key('about-check-update')));
    await _pump(tester);

    // 结果行出现后，18 枚既有 key + 新增的 about-copy-result 应全部在册。
    for (final String key in <String>[
      'about-page',
      'about-version',
      'about-check-update',
      'about-online-upgrade',
      'about-online-upgrade-reason',
      'about-check-result',
      'about-copy-result',
      'about-open-releases',
      'about-changelog',
      'about-privacy',
      'about-repo-url',
      'about-open-repo',
      'about-copy-repo',
      'about-developer',
      'about-open-developer',
      'about-open-alpha',
      'about-pageweaver-unverified',
      'about-open-pageweaver',
      'about-licenses',
    ]) {
      expect(find.byKey(_key(key)), findsOneWidget, reason: '缺少或重名：$key');
    }
  });

  // ------------------------------------------------ Task 63 · W8：en 态补齐
  // 以下两条只**追加** en 态字面量断言 + 中文阴性对照，既有 zh 用例一字未改。
  // en 期望串全部取自 `apps/desktop/lib/src/l10n/parts/about.dart` 的 en mixin。
  testWidgets('en 态本页导航七条整体换成英文，中文条目一条不留',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
      language: AppLanguage.en,
    );
    await h.mount(tester);
    await _pump(tester);

    // 先证页面确实渲染了：否则下面的 `findsNothing` 全是空过。
    expect(find.byKey(_key('about-page')), findsOneWidget);

    // 真值来源：`AboutEnL10n.aboutToc`。
    for (final String label in <String>[
      'Version',
      'Recent changes',
      'Data & privacy',
      'Repository',
      'Developer',
      'Other software',
      'Licenses',
    ]) {
      expect(
        find.widgetWithText(InkWell, label),
        findsOneWidget,
        reason: 'en 态本页导航缺少「$label」',
      );
    }

    // 阴性对照：en 态导航里一枚中文条目都不许留。
    for (final String label in <String>[
      '版本',
      '最近变更',
      '数据与隐私',
      '仓库',
      '开发者',
      '其它软件',
      '许可证',
    ]) {
      expect(
        find.widgetWithText(InkWell, label),
        findsNothing,
        reason: 'en 态导航里不该有中文「$label」',
      );
    }
  });

  testWidgets('en 态版本行、检查结果与复制按钮都用英文真值',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
      language: AppLanguage.en,
    );
    await h.mount(tester);
    await _pump(tester);

    // 版本行 = en 的 `versionLabel`（`Version`）+ 两个空格 + 版本常量，
    // 与 `about_page.dart` 的拼法一致。
    expect(
      tester.widget<Text>(find.byKey(_key('about-version'))).data,
      'Version  $kAppVersionFull',
    );

    await tester.tap(find.byKey(_key('about-check-update')));
    await _pump(tester);

    expect(
      tester.widget<Text>(find.byKey(_key('about-check-result'))).data,
      'No releases available yet',
    );
    // `aboutCopyResult` 的 en 真值；
    expect(find.text('Copy result'), findsOneWidget);
    // 仓库复制按钮走共用词 `copy`（en 为 `Copy URL`）。
    expect(find.text('Copy URL'), findsOneWidget);

    // 阴性对照：这四串 zh 原文在 en 态必须一条都找不到。
    expect(find.text('复制结果'), findsNothing);
    expect(find.text('暂无可用发布版本'), findsNothing);
    expect(find.text('复制地址'), findsNothing);
    expect(find.text('检查新版本'), findsNothing);
  });
}