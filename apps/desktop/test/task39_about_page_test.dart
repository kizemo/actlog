// apps/desktop/test/task39_about_page_test.dart
//
// Task 39 · W3 —— 关于页（B9/B10）。
//
// 全程不联网：`releaseCheckerProvider` 注入假实现，直接给四个状态里的两个
// 真实可达分支（404 = 仓库零发布 / 网络失败）。真网络行为由
// `GitHubReleaseChecker` 自己吞异常，不在 widget test 里验。
import 'package:actlog/src/app_version.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/about_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:flutter/material.dart';
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
        // 关于页只读偏好里的语言：直接给一份快照，不必起数据库。
        currentPreferencesProvider
            .overrideWithValue(AppPreferences.defaults.copyWith(language: language)),
        releaseCheckerProvider.overrideWithValue(checker),
        systemIntegrationProvider.overrideWithValue(system),
      ],
    );
    addTearDown(container.dispose);
    return _Harness._(container, checker, system);
  }

  Future<void> mount(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AboutPage()),
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

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

ValueKey<String> _key(String value) => ValueKey<String>(value);

void main() {
  final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);

  testWidgets('B9 关于页六个区块与全部入口齐备', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    expect(find.byKey(_key('about-page')), findsOneWidget);

    for (final String key in <String>[
      'about-version',
      'about-check-update',
      'about-online-upgrade',
      'about-online-upgrade-reason',
      'about-repo-url',
      'about-open-repo',
      'about-copy-repo',
      'about-developer',
      'about-open-developer',
      'about-open-alpha',
      'about-open-pageweaver',
    ]) {
      expect(find.byKey(_key(key)), findsOneWidget, reason: '缺少 $key');
    }

    // 版本号来自常量，必须与 `pubspec.yaml` 同源（另见 version 测试）。
    expect(
      tester.widget<Text>(find.byKey(_key('about-version'))).data,
      '${zh.versionLabel}  $kAppVersionFull',
    );
    // 仓库地址是可复制 / 可点开的那一个，不是另写的字符串。
    expect(
      tester.widget<Text>(find.byKey(_key('about-repo-url'))).data,
      kAppRepositoryUrl,
    );
    expect(
      tester.widget<Text>(find.byKey(_key('about-developer'))).data,
      kAppDeveloperName,
    );
    expect(find.text(zh.sectionDeveloper), findsWidgets);
    expect(find.text(zh.sectionOtherSoftware), findsWidgets);
    expect(find.text(zh.sectionRepository), findsWidgets);
  });

  testWidgets('B10 仓库没有发布版本 ⇒ 明说「暂无发布」，不许静默',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    expect(find.byKey(_key('about-check-result')), findsNothing);

    await tester.tap(find.byKey(_key('about-check-update')));
    await _pump(tester);

    expect(h.checker.calls, 1);
    expect(
      tester.widget<Text>(find.byKey(_key('about-check-result'))).data,
      zh.noRelease,
    );
  });

  testWidgets('B10 网络失败 ⇒ 降级成一条人话，页面不崩',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.networkError),
    );
    await h.mount(tester);
    await _pump(tester);

    await tester.tap(find.byKey(_key('about-check-update')));
    await _pump(tester);

    expect(
      tester.widget<Text>(find.byKey(_key('about-check-result'))).data,
      zh.networkError,
    );
    // 页面主体仍在（没有因为异常被换成错误页）。
    expect(find.byKey(_key('about-page')), findsOneWidget);
  });

  testWidgets('B10 有更新 ⇒ 带上远端版本号', (WidgetTester tester) async {
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

    expect(
      tester.widget<Text>(find.byKey(_key('about-check-result'))).data,
      '${zh.newVersionAvailable} 0.2.0',
    );
  });

  testWidgets('在线升级按钮禁用，并给出禁用原因（不造假下载链接）',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    final InkWell ink = tester.widget<InkWell>(
      find.ancestor(
        of: find.byKey(_key('about-online-upgrade')),
        matching: find.byType(InkWell),
      ),
    );
    expect(ink.onTap, isNull);

    expect(
      tester.widget<Text>(find.byKey(_key('about-online-upgrade-reason'))).data,
      zh.onlineUpgradeDisabled,
    );

    // 点了也不该有任何副作用。
    await tester.tap(find.byKey(_key('about-online-upgrade')));
    await _pump(tester);
    expect(h.checker.calls, 0);
    expect(h.system.opened, isEmpty);
  });

  testWidgets('仓库 / 开发者 / 其它软件三个外链都走系统集成', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    await tester.tap(find.byKey(_key('about-open-repo')));
    await _pump(tester);
    await tester.tap(find.byKey(_key('about-open-developer')));
    await _pump(tester);
    await tester.tap(find.byKey(_key('about-open-alpha')));
    await _pump(tester);
    await tester.tap(find.byKey(_key('about-open-pageweaver')));
    await _pump(tester);

    expect(h.system.opened, <String>[
      kAppRepositoryUrl,
      kAppDeveloperUrl,
      kAlphaFileManagerUrl,
      kPageWeaverUrl,
    ]);
  });

  testWidgets('PageWeaver 对应关系未坐实 ⇒ 如实标注', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
    );
    await h.mount(tester);
    await _pump(tester);

    expect(kPageWeaverVerified, isFalse);
    expect(find.byKey(_key('about-pageweaver-unverified')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(_key('about-pageweaver-unverified')))
          .data,
      zh.unverifiedLink,
    );
  });

  testWidgets('B5 英文档下关于页文案整体换掉', (WidgetTester tester) async {
    _useTallSurface(tester);
    final AppLocalizations en = AppLocalizations.forLanguage(AppLanguage.en);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
      language: AppLanguage.en,
    );
    await h.mount(tester);
    await _pump(tester);

    expect(find.text(en.aboutTitle), findsOneWidget);
    expect(find.text(zh.aboutTitle), findsNothing);
    expect(find.text(en.sectionRepository), findsWidgets);
  });
}
