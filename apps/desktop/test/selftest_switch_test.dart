// 「启动即自检」开关的单元测试。
//
// 关键断言：**默认启动不跑自检**，只有显式开关才跑。
// 这条是 D1 原型的教训（原型是无条件自检），必须锁死。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/selftest.dart';

void main() {
  group('selftestRequested', () {
    test('不带任何参数时不跑自检', () {
      expect(
        selftestRequested(const <String>[]),
        isFalse,
        reason: '正式工程不得像 D1 原型那样无条件自检',
      );
    });

    test('--selftest 打开自检', () {
      expect(selftestRequested(const <String>['--selftest']), isTrue);
    });

    test('--selftest=1 也打开自检', () {
      expect(selftestRequested(const <String>['--selftest=1']), isTrue);
    });

    test('其它参数不误触发自检', () {
      expect(selftestRequested(const <String>['--verbose']), isFalse);
      expect(selftestRequested(const <String>['selftest']), isFalse);
    });

    test('环境变量 ACTLOG_SELFTEST=1 也打开自检', () {
      final env = Platform.environment[kSelfTestEnvVar];
      if (env == null) {
        // 当前进程没有这个环境变量：断言默认值不触发即可。
        expect(selftestRequested(const <String>[]), isFalse);
      } else {
        // 环境变量存在时，行为由它的取值决定。
        final expected = const <String>{'1', 'true', 'yes'}.contains(
          env.trim().toLowerCase(),
        );
        expect(selftestRequested(const <String>[]), expected);
      }
    });
  });
}
