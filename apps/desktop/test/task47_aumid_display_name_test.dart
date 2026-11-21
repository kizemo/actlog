// apps/desktop/test/task47_aumid_display_name_test.dart
//
// Task 47 W1c-3 · 显式 AUMID + 注册表 DisplayName 的 Dart 侧契约。
//
// 真注册表与真 shell 不可能在单测里跑（那要 HKCU 和真实任务栏），所以这一层只钉
// Dart 必须保证的两件事：
//   1. runner 回的 `hr_aumid` / `hr_reg` / `aumid` 三个新字段必须进启动日志 ——
//      真机上这是唯一能区分「身份换了」和「只换了标签」的证据。
//   2. `taskbar.aumid` 行必须早于 `taskbar.display` 行：身份先于标签。
// 失败一律不冒泡，这一层同时钉住「hr_aumid≠0 / hr_reg≠0 也不抛」。
import 'dart:io';

import 'package:actlog/src/desktop_shell.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];
  late Directory tmp;

  /// runner 侧「全部成功」的回复，含三个新字段。
  Map<Object?, Object?> okReply() => <Object?, Object?>{
        'hr_store': 0,
        'hr_cmd': 0,
        'hr_name': 0,
        'hr_commit': 0,
        'hr_read': 0,
        'hr_reg': 0,
        'hr_aumid': 0,
        'aumid': 'com.actlog.actlog',
        'readback_ok': true,
      };

  void mockRunner({Object? reply}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, (MethodCall call) async {
      calls.add(call);
      return reply ?? okReply();
    });
  }

  setUp(() {
    calls.clear();
    tmp = Directory.systemTemp.createTempSync('actlog_w1c3_');
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kWindowChannel, null);
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  String logText() {
    final File file = File(p.join(tmp.path, kStartupLogName));
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  test('hr_aumid / hr_reg / aumid 三个新字段进启动日志', () async {
    mockRunner();

    await applyTaskbarDisplayName(kAppTitle(), supportDir: tmp);

    final String log = logText();
    expect(log, contains('taskbar.aumid ok hr_aumid=0 id=com.actlog.actlog'));
    expect(log, contains('hr_reg=0'));
    expect(log, contains('hr_aumid=0'));
    expect(log, contains('readback_ok=true'));
  });

  test('taskbar.aumid 行早于 taskbar.display 行（身份先于标签）', () async {
    mockRunner();

    await applyTaskbarDisplayName(kAppTitle(), supportDir: tmp);

    final String log = logText();
    final int aumidAt = log.indexOf('taskbar.aumid');
    final int displayAt = log.indexOf('taskbar.display');
    expect(aumidAt, isNonNegative);
    expect(displayAt, isNonNegative);
    expect(aumidAt, lessThan(displayAt));
  });

  test('hr_aumid≠0 落 FAIL 行但仍 completes', () async {
    mockRunner(
      reply: <Object?, Object?>{
        ...okReply(),
        'hr_aumid': -2147467259,
      },
    );

    await expectLater(
      applyTaskbarDisplayName('actlog', supportDir: tmp),
      completes,
    );
    expect(logText(), contains('taskbar.aumid FAIL hr_aumid=-2147467259'));
  });

  test('hr_reg≠0 不抛，且失败值照原样落日志', () async {
    mockRunner(
      reply: <Object?, Object?>{
        ...okReply(),
        'hr_reg': 5,
      },
    );

    await expectLater(
      applyTaskbarDisplayName(kAppTitle(), supportDir: tmp),
      completes,
    );
    expect(calls, hasLength(1));
    expect(logText(), contains('hr_reg=5'));
  });
}
