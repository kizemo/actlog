// apps/desktop/test/task39_settings_page_test.dart
//
// Task 39 · W3 —— 设置页（B1/B3/B4/B5/B6/B7/B8）。
//
// 纪律：只用**写集内**的文件与既有 provider，不 mock 仓储。
// 真实写入一律落在内存库里（`openInMemoryActLogDatabase`），跑完即随
// `db.close` 消失，不碰本机注册表也不碰用户数据目录。
//
// 为什么不真写注册表 / 真建 `.lnk`：那会污染跑测试的那台机器。这里注入
// `_FakeSystem` 只断言「调用序列 + 落库的偏好」，真实落盘验证走
// `reports\task39-w3-autorun-check.ps1`（手工跑一次并还原）。
import 'package:actlog/src/app.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/settings_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 固定「今天」，让 `DayGrid` 不依赖真实时钟。
const String _today = '2026-11-09';

/// 系统集成的假实现：只记调用，不碰系统。
final class _FakeSystem implements SystemIntegration {
  final List<String> calls = <String>[];
  final List<String> opened = <String>[];

  /// 注册表里「开机启动」的读回值（`null` = 没写）。
  String? bootValue;

  bool bootOk = true;
  bool shortcutOk = true;

  @override
  String executablePath() => r'C:\fake\actlog.exe';

  @override
  Future<bool> setLaunchOnBoot(bool enabled) async {
    calls.add('setLaunchOnBoot($enabled)');
    if (bootOk) {
      bootValue = enabled ? r'"C:\fake\actlog.exe"' : null;
    }
    return bootOk;
  }

  @override
  Future<String?> readLaunchOnBoot() async {
    calls.add('readLaunchOnBoot');
    return bootValue;
  }

  @override
  Future<bool> createDesktopShortcut() async {
    calls.add('createDesktopShortcut');
    return shortcutOk;
  }

  @override
  Future<bool> openUrl(String url) async {
    opened.add(url);
    return true;
  }
}

/// 内存真库 + 真仓储 + 固定今天。
final class _Harness {
  _Harness._(this.container, this.repos, this.system);

  final ProviderContainer container;
  final ActLogRepositories repos;
  final _FakeSystem system;

  static _Harness create({List<Override> extra = const <Override>[]}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task39-settings-test');
    final system = _FakeSystem();
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
        systemIntegrationProvider.overrideWithValue(system),
        ...extra,
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos, system);
  }

  Future<void> mount(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nScope(child),
      ),
    );
  }
}

/// 设置页是壳内内容体（没有自己的 `Scaffold`），测试里给它一个滚动视口。
Widget _settingsHost() {
  return const MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: SettingsPage()),
    ),
  );
}

void _useTallSurface(WidgetTester tester) {
  // 视口给足：本页是竖排长表，默认 800x600 会让下半截落在视口外，
  // `tap` 就变成「点不到」而不是「点错了」。
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库写入 / 重建回来。
///
/// 不用 `pumpAndSettle`：drift 的流订阅会让它永远等不到「没有待处理帧」。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

ValueKey<String> _key(String value) => ValueKey<String>(value);

void main() {
  final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);
  final AppLocalizations en = AppLocalizations.forLanguage(AppLanguage.en);

  testWidgets('B1/B3 设置页六个区块与全部控件都在', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    expect(find.byKey(_key('settings-page')), findsOneWidget);

    // 外观 / 语言 / 系统集成 / 计划窗口 / 其它 —— 五个区块标题各一份。
    // 其中「外观」与「其它」的区块标题同时是行标题，故只断言至少一份。
    expect(find.text(zh.sectionLanguage), findsWidgets);
    expect(find.text(zh.sectionSystem), findsWidgets);
    expect(find.text(zh.sectionPlanWindow), findsWidgets);
    expect(find.text(zh.sectionOther), findsWidgets);

    for (final String key in <String>[
      'settings-theme-system',
      'settings-theme-light',
      'settings-theme-dark',
      'settings-lang-zh',
      'settings-lang-en',
      'settings-launch-on-boot',
      'settings-shortcut-button',
      'settings-executable-path',
      'settings-plan-start',
      'settings-plan-end',
      'settings-plan-window-hint',
      'settings-density-compact',
      'settings-density-comfortable',
      'settings-density-roomy',
      'settings-priority-quadrant',
      'settings-priority-abc',
      'settings-reset-button',
    ]) {
      expect(find.byKey(_key(key)), findsOneWidget, reason: '缺少控件 $key');
    }

    // 可执行文件路径来自注入的系统集成，不是猜的。
    expect(
      tester.widget<Text>(find.byKey(_key('settings-executable-path'))).data,
      '${zh.executablePath}  ${r'C:\fake\actlog.exe'}',
    );
  });

  testWidgets('B4 主题档落库，并真的把 MaterialApp.themeMode 切过去',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    // 这里必须走 `ActLogApp`：`themeMode` 只在那一层生效，
    // 单独 pump 设置页只能证明「写库」而不能证明「界面真的换了」。
    await h.mount(
      tester,
      const ActLogApp(
        home: Scaffold(body: SingleChildScrollView(child: SettingsPage())),
      ),
    );
    await _settle(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
      reason: '默认档应为浅色（AppPreferences.defaults）',
    );

    await tester.tap(find.byKey(_key('settings-theme-dark')));
    await _settle(tester);

    expect(await h.repos.settings.get(settingsKeyThemeMode), 'dark');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('B5 语言档落库，界面文案整体换成英文', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    expect(find.text(zh.settingsTitle), findsOneWidget);

    await tester.tap(find.byKey(_key('settings-lang-en')));
    await _settle(tester);

    expect(await h.repos.settings.get(settingsKeyLocale), 'en');
    expect(find.text(en.settingsTitle), findsOneWidget);
    expect(find.text(zh.settingsTitle), findsNothing);
  });

  testWidgets('B6 开机启动：先动系统、成功才写偏好', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    // 首帧后读过注册表，开关才可操作。
    expect(h.system.calls, contains('readLaunchOnBoot'));

    await tester.tap(find.byKey(_key('settings-launch-on-boot')));
    await _settle(tester);

    expect(h.system.calls, contains('setLaunchOnBoot(true)'));
    expect(await h.repos.settings.get(settingsKeyLaunchOnBoot), '1');
  });

  testWidgets('B6 开机启动失败：不写偏好，给失败文案', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    h.system.bootOk = false;
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    await tester.tap(find.byKey(_key('settings-launch-on-boot')));
    await _settle(tester);

    expect(h.system.calls, contains('setLaunchOnBoot(true)'));
    expect(await h.repos.settings.get(settingsKeyLaunchOnBoot), isNull);
    expect(
      tester.widget<Text>(find.byKey(_key('settings-status'))).data,
      zh.operationFailed,
    );
  });

  testWidgets('B7 桌面快捷方式：点一下就调系统集成并给成功文案',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    await tester.tap(find.byKey(_key('settings-shortcut-button')));
    await _settle(tester);

    expect(h.system.calls, contains('createDesktopShortcut'));
    expect(
      tester.widget<Text>(find.byKey(_key('settings-status'))).data,
      zh.shortcutCreated,
    );
  });

  testWidgets('B8 计划起止下拉真的落库', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    await tester.tap(find.byKey(_key('settings-plan-end')));
    await _settle(tester);
    await tester.tap(find.byKey(_key('settings-hour-option-18')));
    await _settle(tester);

    expect(await h.repos.settings.get(settingsKeyDailyEndHour), '18');
    // 起止同属一个窗口，写终点时起点按当前值一并落库（默认 6），不是「不写」。
    expect(await h.repos.settings.get(settingsKeyDailyStartHour), '6');
  });

  testWidgets('B8 计划窗口驱动网格高度与刻度行数', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness win = _Harness.create(
      extra: <Override>[
        dayWindowProvider.overrideWith(
          (ref) => const DayWindow(startHour: 9, endHour: 18),
        ),
      ],
    );
    await win.mount(
      tester,
      const MaterialApp(home: Scaffold(body: DayGrid(date: _today))),
    );
    await _settle(tester);

    // 9..18 ⇒ 9 行；高度必须逐像素等于 rows × kHourRowHeight。
    expect(
      tester.getSize(find.byKey(_key('day-grid-ruler'))).height,
      9 * kHourRowHeight,
    );
    expect(find.byKey(_key('day-grid-hour-9')), findsOneWidget);
    expect(find.byKey(_key('day-grid-hour-17')), findsOneWidget);
    expect(find.byKey(_key('day-grid-hour-18')), findsNothing);
    expect(find.byKey(_key('day-grid-hour-8')), findsNothing);
  });

  testWidgets('B8 默认窗口保持参数化之前的逐像素高度（792 = 18 × 44）',
      (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(
      tester,
      const MaterialApp(home: Scaffold(body: DayGrid(date: _today))),
    );
    await _settle(tester);

    expect(
      tester.getSize(find.byKey(_key('day-grid-ruler'))).height,
      kGridHeight,
    );
    expect(kGridHeight, kGridRows * kHourRowHeight);
    expect(find.byKey(_key('day-grid-hour-6')), findsOneWidget);
    expect(find.byKey(_key('day-grid-hour-23')), findsOneWidget);
  });

  testWidgets('恢复默认：确认后偏好回到出厂值', (WidgetTester tester) async {
    _useTallSurface(tester);
    final _Harness h = _Harness.create();
    await h.mount(tester, _settingsHost());
    await _settle(tester);

    await tester.tap(find.byKey(_key('settings-theme-dark')));
    await _settle(tester);
    expect(await h.repos.settings.get(settingsKeyThemeMode), 'dark');

    await tester.tap(find.byKey(_key('settings-reset-button')));
    await _settle(tester);
    await tester.tap(find.byKey(_key('settings-reset-confirm')));
    await _settle(tester);

    expect(await h.repos.settings.get(settingsKeyThemeMode), 'light');
    expect(
      tester.widget<Text>(find.byKey(_key('settings-status'))).data,
      zh.resetDone,
    );
  });
}
