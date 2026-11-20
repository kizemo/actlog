// apps/desktop/test/task46_about_licenses_test.dart
//
// Task 46 · W3 —— 关于页两处缺口：
//   G2 第三方软件与许可证：逐条列出 `pubspec.yaml` 里真实存在的依赖与真实
//      许可证名，位置在「其它软件」之后（ValueKey `about-licenses`）。
//   G4 检查结果可复制：结果行右侧一枚复制按钮（ValueKey `about-copy-result`），
//      点击把结果原文真写进剪贴板，按钮文案变「已复制」，重新检查后复位。
//
// 全程不联网：`releaseCheckerProvider` / `systemIntegrationProvider` 注入假实现；
// 剪贴板走 `SystemChannels.platform` 的 mock，不碰真剪贴板。
import 'package:actlog/src/app_version.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/about_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只回固定结果的版本检查器。
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

/// 只记「打开过哪个链接」的系统集成假实现（本文件不发链接，仅需可注入）。
final class _FakeSystem implements SystemIntegration {
  @override
  String executablePath() => r'C:\fake\actlog.exe';

  @override
  Future<bool> setLaunchOnBoot(bool enabled) async => true;

  @override
  Future<String?> readLaunchOnBoot() async => null;

  @override
  Future<bool> createDesktopShortcut() async => true;

  @override
  Future<bool> openUrl(String url) async => true;
}

/// 接住 `Clipboard.setData` / `Clipboard.getData` 的通道桩。
///
/// 断言「真的调了通道」而不是只翻了一个布尔位：`setCalls` 统计写入次数，
/// `text` 是最后一次写入的内容，`Clipboard.getData` 会把同一份内容回读。
final class _ClipboardSpy {
  String? text;
  int setCalls = 0;

  static _ClipboardSpy install() {
    final _ClipboardSpy spy = _ClipboardSpy();
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform,
        (MethodCall call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final Map<Object?, Object?> args =
              call.arguments as Map<Object?, Object?>;
          spy.text = args['text'] as String?;
          spy.setCalls++;
          return null;
        case 'Clipboard.getData':
          final String? value = spy.text;
          return value == null
              ? null
              : <String, dynamic>{'text': value};
        default:
          // SystemChrome / HapticFeedback 之类一律静默吞掉。
          return null;
      }
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    return spy;
  }
}

final class _Harness {
  _Harness._(this.container, this.checker);

  final ProviderContainer container;
  final _FakeChecker checker;

  static _Harness create({
    required ReleaseCheckResult result,
    AppLanguage language = AppLanguage.zh,
  }) {
    final _FakeChecker checker = _FakeChecker(result);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        currentPreferencesProvider.overrideWithValue(
          AppPreferences.defaults.copyWith(language: language),
        ),
        releaseCheckerProvider.overrideWithValue(checker),
        systemIntegrationProvider.overrideWithValue(_FakeSystem()),
      ],
    );
    addTearDown(container.dispose);
    return _Harness._(container, checker);
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

ValueKey<String> _key(String value) => ValueKey<String>(value);

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

/// 点「检查更新」并等结果落进界面。
Future<void> _check(WidgetTester tester) async {
  await tester.tap(find.byKey(_key('about-check-update')));
  await _pump(tester);
}

void main() {
  final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);

  // ---------------------------------------------------------------- G2 许可证
  testWidgets('G2 许可证区块逐条列出真实依赖 + 真实许可证名', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h =
        _Harness.create(result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease));
    await h.mount(tester);
    await _pump(tester);

    expect(find.byKey(_key('about-licenses')), findsOneWidget,
        reason: '缺少 about-licenses');
    // Task 39 / 45 的逐字断言依赖它是普通 `Text`；换成别的 widget 会破既有契约。
    expect(tester.widget<Text>(find.byKey(_key('about-licenses'))), isNotNull);
    final String text =
        tester.widget<Text>(find.byKey(_key('about-licenses'))).data!;

    // 真值来源：apps/desktop/pubspec.yaml。逐条断言「依赖名（许可证名）」成对出现，
    // 任一条缺失或换错许可证名都会红。
    const Map<String, String> expected = <String, String>{
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
    for (final MapEntry<String, String> dep in expected.entries) {
      expect(text, contains('${dep.key}（${dep.value}）'),
          reason: '${dep.key} 应标 ${dep.value}');
    }

    // 反例：把 BSD-3-Clause 写成 MIT 是本波最可能的错法，必须能被这条抓住。
    expect(text, isNot(contains('flutter_local_notifications（MIT）')));
    expect(text, isNot(contains('path_provider（MIT）')));
    expect(text, contains('BSD-3-Clause'));

    // 字体资产按「字体族 + OFL-1.1」分组表述，不许写死数量（W1 会新增字体族）。
    expect(text, contains('SIL Open Font License 1.1'));
    expect(text, contains('OFL-*.txt'));
    expect(RegExp(r'\d+\s*(个|种|款|套|份)\s*字体').hasMatch(text), isFalse,
        reason: '字体数量不许写死：新增字体族会让写死的数字变成假话');

    // 本仓库自研包不属于第三方，须写明（否则读者会以为 core_* 也是第三方）。
    expect(text, contains('core_domain'));
    expect(text, contains('pubspec.yaml'));
  });

  testWidgets('G2 许可证区块位置在「其它软件」之后', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h =
        _Harness.create(result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease));
    await h.mount(tester);
    await _pump(tester);

    final double other =
        tester.getRect(find.byKey(_key('about-open-pageweaver'))).top;
    final double licenses =
        tester.getRect(find.byKey(_key('about-licenses'))).top;
    expect(licenses, greaterThan(other), reason: '许可证必须在其它软件之后');
  });

  testWidgets('G2 英文档同样逐条对齐', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
      language: AppLanguage.en,
    );
    await h.mount(tester);
    await _pump(tester);

    final String text =
        tester.widget<Text>(find.byKey(_key('about-licenses'))).data!;
    expect(text, contains('drift (MIT)'));
    expect(text, contains('flutter_local_notifications (BSD-3-Clause)'));
    expect(text, contains('path_provider (BSD-3-Clause)'));
    expect(find.text('许可证'), findsNothing);
  });

  // ------------------------------------------------------------- G4 可复制结果
  testWidgets('G4 检查后出现复制按钮，点击把结果原文写进剪贴板',
      (WidgetTester tester) async {
    final _ClipboardSpy spy = _ClipboardSpy.install();
    _useTallSurface(tester);
    final _Harness h =
        _Harness.create(result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease));
    await h.mount(tester);
    await _pump(tester);

    // 没有结果行时不该有复制按钮（不做无对象的空按钮）。
    expect(find.byKey(_key('about-copy-result')), findsNothing);

    await _check(tester);
    expect(find.byKey(_key('about-copy-result')), findsOneWidget);

    final String shown =
        tester.widget<Text>(find.byKey(_key('about-check-result'))).data!;
    expect(shown, zh.noRelease, reason: '结果行文案不该被 G4 改动');

    await tester.tap(find.byKey(_key('about-copy-result')));
    await tester.pump();
    await tester.pump();

    expect(spy.setCalls, 1, reason: '必须真的调 Clipboard.setData');
    expect(spy.text, shown, reason: '复制的内容必须是结果原文');

    // 走一遍读通道，确认写进去的东西真能取回来（不是只记在 spy 里）。
    final ClipboardData? round =
        await Clipboard.getData(Clipboard.kTextPlain);
    expect(round?.text, shown);

    // 按下后有可见反馈：文案换成「已复制」（与「复制仓库地址」同构）。
    expect(
      find.descendant(
        of: find.byKey(_key('about-copy-result')),
        matching: find.text(zh.copied),
      ),
      findsOneWidget,
    );
  });

  testWidgets('G4 重新检查后按钮文案复位', (WidgetTester tester) async {
    _ClipboardSpy.install();
    _useTallSurface(tester);
    final _Harness h =
        _Harness.create(result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease));
    await h.mount(tester);
    await _pump(tester);

    await _check(tester);
    await tester.tap(find.byKey(_key('about-copy-result')));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(_key('about-copy-result')),
        matching: find.text(zh.copied),
      ),
      findsOneWidget,
    );

    await _check(tester);
    expect(
      find.descendant(
        of: find.byKey(_key('about-copy-result')),
        matching: find.text('复制结果'),
      ),
      findsOneWidget,
      reason: '重新检查后「已复制」必须复位',
    );
  });

  testWidgets('G4 有更新时复制的是含版本号的那一行', (WidgetTester tester) async {
    final _ClipboardSpy spy = _ClipboardSpy.install();
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(
        ReleaseCheckStatus.newer,
        latestTag: 'v0.2.0',
      ),
    );
    await h.mount(tester);
    await _pump(tester);

    await _check(tester);
    final String shown =
        tester.widget<Text>(find.byKey(_key('about-check-result'))).data!;
    expect(shown, contains('0.2.0'));

    await tester.tap(find.byKey(_key('about-copy-result')));
    await tester.pump();
    await tester.pump();

    expect(spy.text, shown);
  });

  testWidgets('G4 复制按钮可键盘聚焦（与其它按钮同构）', (WidgetTester tester) async {
    _ClipboardSpy.install();
    _useTallSurface(tester);
    final _Harness h =
        _Harness.create(result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease));
    await h.mount(tester);
    await _pump(tester);

    await _check(tester);
    final InkWell ink = tester.widget<InkWell>(
      find.ancestor(
        of: find.byKey(_key('about-copy-result')),
        matching: find.byType(InkWell),
      ),
    );
    expect(ink.canRequestFocus, isTrue);
  });

  // ------------------------------------------- 版本口径（Task 46 · W3 追加）
  // 关于页的版本串必须与 `app_version.dart` 的常量同源。原先变更日志里硬编码
  // `0.1.0+1`，本波统一到 `1.0.0` 后它成了假话 —— 这两条把口径钉住。
  testWidgets('版本行与变更日志都取 kAppVersionFull，不再硬编码旧版本',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h =
        _Harness.create(result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease));
    await h.mount(tester);
    await _pump(tester);

    final String versionLine =
        tester.widget<Text>(find.byKey(_key('about-version'))).data!;
    expect(versionLine, '${zh.versionLabel}  $kAppVersionFull',
        reason: '版本行必须由 kAppVersionFull 拼出');

    final String changelog =
        tester.widget<Text>(find.byKey(_key('about-changelog'))).data!;
    expect(changelog, contains(kAppVersionFull),
        reason: '变更日志首行必须显示真实版本');
    expect(changelog, isNot(contains('0.1.0')),
        reason: '硬编码的旧版本串必须彻底消失');
  });

  testWidgets('英文档变更日志同样取 kAppVersionFull', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create(
      result: const ReleaseCheckResult(ReleaseCheckStatus.noRelease),
      language: AppLanguage.en,
    );
    await h.mount(tester);
    await _pump(tester);

    final String changelog =
        tester.widget<Text>(find.byKey(_key('about-changelog'))).data!;
    expect(changelog, contains(kAppVersionFull),
        reason: '英文档也要同源');
    expect(changelog, isNot(contains('0.1.0')));
  });
}