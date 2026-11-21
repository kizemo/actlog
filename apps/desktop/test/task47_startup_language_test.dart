// apps/desktop/test/task47_startup_language_test.dart
//
// Task 47 W1d · 首次 Show 之前推送的任务栏显示名该用哪种语言。
//
// W1c-3 的真机读数是「三臂逐字相同」——zh 臂和 en 臂的任务栏都挂着
// `知行日志 actlog`，说明语言压根没进到「show 之前那一次推送」。这一层钉三件事：
//   1. 语言只从 `settings.locale` 一行解析，且与 `currentPreferencesProvider`
//      同源（同一个 `AppLanguage.fromCode`），不另立口径。
//   2. 读不到 / 值不认识 ⇒ zh，绝不抛。
//   3. `setupDesktopShell(language: ...)` 真的把语言带到了 runner 那一步：
//      en ⇒ `actlog`，zh ⇒ `知行日志 actlog`。这是「首推语言」的回归点。
//
// 真窗口 / 真 COM 不可能在单测里跑，所以这里只钉 Dart 侧契约；真机由启动日志
// 的 `taskbar.display ... name=` 行序断言（见 task47_aumid_display_name_test.dart）。
import 'package:actlog/main.dart';
import 'package:actlog/src/desktop_shell.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];

  setUp(calls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, null);
  });

  /// 装 mock runner：记下调用，并按「读回成功」应答。
  void mockRunner() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, (MethodCall call) async {
      calls.add(call);
      return <Object?, Object?>{
        'hr_store': 0,
        'hr_cmd': 0,
        'hr_name': 0,
        'hr_commit': 0,
        'hr_read': 0,
        'hr_aumid': 0,
        'aumid': 'com.actlog.actlog',
        'readback_ok': true,
      };
    });
  }

  /// 只挑「写任务栏显示名」的调用（同一条通道还跑 setHideOnClose 等）。
  List<String> pushedNames() => calls
      .where((MethodCall c) => c.method == 'setTaskbarDisplayName')
      .map((MethodCall c) => '${c.arguments}')
      .toList();

  test('库里没有 locale 行 ⇒ zh（出厂默认）', () async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    expect(await resolveStartupLanguage(db), AppLanguage.zh);
  });

  test('locale=en ⇒ en（与设置页同一个 fromCode 口径）', () async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    await ActLogRepositories(db).settings.set(settingsKeyLocale, 'en');

    expect(await resolveStartupLanguage(db), AppLanguage.en);
    // 同源校验：解析结果必须等于设置页读到的那个值。
    expect(
      AppLanguage.fromCode(
        await ActLogRepositories(db).settings.get(settingsKeyLocale),
      ),
      AppLanguage.en,
    );
  });

  test('locale 是认识不了的值 ⇒ zh（不抛、不把启动链路拖垮）', () async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    await ActLogRepositories(db).settings.set(settingsKeyLocale, 'not-a-locale');

    expect(await resolveStartupLanguage(db), AppLanguage.zh);
  });

  test('en 态首次推送的名字是 actlog，不再是中文前缀', () async {
    mockRunner();

    await setupDesktopShell(language: AppLanguage.en, supportDir: null);

    expect(pushedNames(), <String>['actlog']);
  });

  test('zh 态首次推送仍是 知行日志 actlog（零回归）', () async {
    mockRunner();

    await setupDesktopShell(supportDir: null);

    expect(pushedNames(), <String>['知行日志 actlog']);
  });
}