// apps/desktop/test/task39_about_version_test.dart
//
// Task 39 · W3 —— 版本号的「单一真源」防线（B11）。
//
// 关于页显示的是手写常量 `kAppVersion` / `kAppBuildNumber`（理由见
// `lib/src/app_version.dart` 头部）。手写就有漂移风险，所以这里直接把
// `pubspec.yaml` 读进来比对：只改一处，本测试立刻红。
import 'dart:io';

import 'package:actlog/src/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('版本常量与 pubspec.yaml 同源', () {
    test('pubspec 的 version 拆开后与 kAppVersion / kAppBuildNumber 逐字相同', () {
      final File pubspec = File('pubspec.yaml');
      expect(
        pubspec.existsSync(),
        isTrue,
        reason: 'flutter test 的工作目录应当是 apps/desktop',
      );
      final String text = pubspec.readAsStringSync();

      final RegExpMatch? version = RegExp(
        r'^version:\s*([0-9][^\s+]*)',
        multiLine: true,
      ).firstMatch(text);
      expect(version, isNotNull, reason: 'pubspec.yaml 缺少可解析的 version 行');
      expect(version!.group(1), kAppVersion);

      final RegExpMatch? build = RegExp(
        r'^version:\s*[^\s+]+\+(\d+)',
        multiLine: true,
      ).firstMatch(text);
      expect(build, isNotNull, reason: 'pubspec.yaml 的 version 缺少 +构建号');
      expect(build!.group(1), kAppBuildNumber);
    });

    test('kAppVersionFull 就是「版本+构建号」', () {
      expect(kAppVersionFull, '$kAppVersion+$kAppBuildNumber');
    });
  });

  group('compareVersions 口径', () {
    test('远端更新 ⇒ 1', () {
      expect(compareVersions('v0.2.0', '0.1.0'), 1);
      expect(compareVersions('1.0', '0.9.9'), 1);
      expect(compareVersions('V2.0.0', 'v1.9.9'), 1);
    });

    test('同版本 ⇒ 0（构建号不参与比较）', () {
      expect(compareVersions('0.1.0', '0.1.0'), 0);
      expect(compareVersions('v0.1.0', '0.1.0'), 0);
      expect(compareVersions('0.1.0+7', '0.1.0'), 0);
    });

    test('远端更旧 ⇒ -1', () {
      expect(compareVersions('0.1.0', '0.1.1'), -1);
      expect(compareVersions('0.1', '0.2.0'), -1);
    });

    test('缺段补 0、非数字段当 0（不抛异常）', () {
      expect(compareVersions('1.0', '1'), 0);
      expect(compareVersions('abc', '0.0.1'), -1);
      expect(compareVersions('', '0.0.0'), 0);
    });
  });
}
