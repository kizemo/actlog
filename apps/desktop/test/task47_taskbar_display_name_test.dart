// apps/desktop/test/task47_taskbar_display_name_test.dart
//
// Task 47 W1c-2b · 任务栏按钮名的「应用可控前缀」。
//
// 真窗口 / 真 COM 不可能在单测里跑（那要 shell 和属性 store），所以这一层只钉
// Dart 侧的契约，真正的写入由真机启动日志断言：
//   1. 方法名就是 `setTaskbarDisplayName`，且只发一次 —— runner 那边是 if/else
//      分支，名字写错就是 NotImplemented，静默无效果。
//   2. 参数就是本地化标题本身（zh `知行日志 actlog` / en `actlog`）。这里从
//      `kAppTitle` 取期望值而不是写死字面量，锚的是「同一个真源」。
//   3. 通道抛异常不冒泡 —— 任务栏名字写不进去不能拖垮启动链路或语言切换。
//
// 全程 `supportDir` 传 null：`_logStartup` 在没有目录时直接丢弃，测试不碰磁盘。
import 'package:actlog/src/desktop_shell.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];

  /// 装一个 mock handler：记下调用，并回一个「runner 说成功」的结果。
  void mockRunner({Object? reply}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, (MethodCall call) async {
      calls.add(call);
      return reply ??
          <Object?, Object?>{
            'hr_store': 0,
            'hr_cmd': 0,
            'hr_name': 0,
            'hr_commit': 0,
            'hr_read': 0,
            'readback_ok': true,
          };
    });
  }

  setUp(calls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, null);
  });

  test('zh 态把本地化标题送进 setTaskbarDisplayName', () async {
    mockRunner();

    await applyTaskbarDisplayName(kAppTitle());

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setTaskbarDisplayName');
    expect(calls.single.arguments, '知行日志 actlog');
    expect(kAppTitle(), '知行日志 actlog');
  });

  test('en 态送的是 en 标题（与 zh 不同，否则测试抓不到语言串线）', () async {
    mockRunner();

    await applyTaskbarDisplayName(kAppTitle(AppLanguage.en));

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setTaskbarDisplayName');
    expect(calls.single.arguments, 'actlog');
    expect(
      kAppTitle(AppLanguage.en),
      isNot(kAppTitle(AppLanguage.zh)),
    );
  });

  test('通道抛异常不冒泡（启动链路不能被任务栏名字拖垮）', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, (MethodCall call) async {
      calls.add(call);
      throw PlatformException(code: 'no-runner', message: 'channel closed');
    });

    await expectLater(applyTaskbarDisplayName('actlog'), completes);
    expect(calls.single.method, 'setTaskbarDisplayName');
  });

  test('runner 回 readback_ok=false 也不抛（失败只落日志）', () async {
    mockRunner(
      reply: <Object?, Object?>{
        'hr_store': 0,
        'hr_cmd': 0,
        'hr_name': -2147467259,
        'hr_commit': 0,
        'hr_read': 0,
        'readback_ok': false,
      },
    );

    await expectLater(
      applyTaskbarDisplayName(kAppTitle(), supportDir: null),
      completes,
    );
    expect(calls, hasLength(1));
  });
}
