// Task 33 · T1 改名后的**旧名兼容**回归测试。
//
// 覆盖派工书 §4 的两条硬判据：
//   ③ 旧 `%APPDATA%\com.practiclog\practilog\practilog.db` 存在时，新版首次运行
//      后数据**可见**（不是空库）；
//   ④ 新 `ACTLOG_TEXT_SCALE` 生效、旧 `PRACTILOG_TEXT_SCALE` **仍生效**。
//
// 另附环境变量兜底（DATA_DIR / SELFTEST / TOAST_PROBE）与旧路径分段常量，
// 防止后续改动把旧名兜底悄悄删掉。

import 'dart:io';

import 'package:actlog/src/app.dart';
import 'package:actlog/src/app_paths.dart';
import 'package:actlog/src/selftest.dart';
import 'package:actlog/src/toast_probe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final scratch = <Directory>[];

  Directory makeTemp(String tag) {
    final d = Directory.systemTemp.createTempSync('actlog_legacy_$tag');
    scratch.add(d);
    return d;
  }

  tearDown(() {
    for (final d in scratch) {
      try {
        if (d.existsSync()) d.deleteSync(recursive: true);
      } on Object {
        // 清理失败不影响后续用例；系统临时目录会自己回收。
      }
    }
    scratch.clear();
  });

  group('旧名常量（刻意保留）', () {
    test('旧 DB 文件名、旧目录段、旧环境变量名都在', () {
      expect(kLegacyDbFileName, 'practilog.db');
      expect(kDbFileName, 'actlog.db');
      expect(kLegacyDataDirSegments, <String>['com.practiclog', 'practilog']);
      expect(kCurrentDataDirSegments, <String>['com.actlog', 'actlog']);
      expect(kLegacyProgramDataDirSegments, <String>['practilog']);
      expect(kLegacyFallbackDataDirSegments, <String>[
        'com.practiclog',
        'practilog-fallback',
      ]);
      expect(kLegacyDataDirEnvVar, 'PRACTILOG_DATA_DIR');
      expect(kDataDirEnvVar, 'ACTLOG_DATA_DIR');
    });

    test('旧路径仍能按 %APPDATA% 推导出来', () {
      final ad = p.join('C:', 'Users', 'u', 'AppData', 'Roaming');
      expect(
        legacyDataDirPathFromAppData(ad),
        p.join('C:', 'Users', 'u', 'AppData', 'Roaming', 'com.practiclog', 'practilog'),
      );
      expect(
        currentDataDirPathFromAppData(ad),
        p.join('C:', 'Users', 'u', 'AppData', 'Roaming', 'com.actlog', 'actlog'),
      );
    });
  });

  group('判据③ 旧库可见', () {
    test('旧 %APPDATA%\\com.practiclog\\practilog\\practilog.db 首次运行被搬进安装目录',
        () async {
      final exeHome = makeTemp('exe');
      final appDataHome = makeTemp('appdata');
      final legacyDir = Directory(
        legacyDataDirPathFromAppData(appDataHome.path),
      )..createSync(recursive: true);
      // 旧库本体 + WAL 附属文件都在旧位置。
      File(p.join(legacyDir.path, kLegacyDbFileName)).writeAsStringSync('OLDDB');
      File(p.join(legacyDir.path, '$kLegacyDbFileName-wal')).writeAsStringSync('WAL');

      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: appDataHome.path,
        programData: '',
        localAppData: '',
      );

      expect(res.layout, DataDirLayout.install);
      // 数据可见：不是空库，而是旧库那份内容。
      expect(File(p.join(res.dir.path, kDbFileName)).readAsStringSync(), 'OLDDB');
      // WAL 里的未合并写入也要跟着搬，否则丢最近数据。
      expect(
        File(p.join(res.dir.path, '$kDbFileName-wal')).readAsStringSync(),
        'WAL',
      );
      // 旧文件保留（复制而非移动），保留退回旧版本构建的能力。
      expect(
        File(p.join(legacyDir.path, kLegacyDbFileName)).existsSync(),
        isTrue,
      );
      expect(res.notes.any((n) => n.startsWith('migrated actlog.db')), isTrue);
    });

    test('旧库里若已改成新名 actlog.db，同样搬得动', () async {
      final exeHome = makeTemp('exe2');
      final appDataHome = makeTemp('appdata2');
      final legacyDir = Directory(
        legacyDataDirPathFromAppData(appDataHome.path),
      )..createSync(recursive: true);
      File(p.join(legacyDir.path, kDbFileName)).writeAsStringSync('OLDDB2');

      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: appDataHome.path,
        programData: '',
        localAppData: '',
      );
      expect(File(p.join(res.dir.path, kDbFileName)).readAsStringSync(), 'OLDDB2');
    });

    test('新位置已有库时不搬（不许用旧快照覆盖新数据）', () async {
      final exeHome = makeTemp('exe3');
      final dataDir = Directory(
        userDataDirPathFromExe(p.join(exeHome.path, 'actlog.exe')),
      )..createSync(recursive: true);
      File(p.join(dataDir.path, kDbFileName)).writeAsStringSync('NEW');
      final appDataHome = makeTemp('appdata3');
      final legacyDir = Directory(
        legacyDataDirPathFromAppData(appDataHome.path),
      )..createSync(recursive: true);
      File(p.join(legacyDir.path, kLegacyDbFileName)).writeAsStringSync('OLD');

      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: appDataHome.path,
        programData: '',
        localAppData: '',
      );
      expect(File(p.join(res.dir.path, kDbFileName)).readAsStringSync(), 'NEW');
      expect(res.notes, contains('legacy migration not needed'));
    });
  });

  group('判据④ 环境变量新名优先、旧名兜底', () {
    test('新 ACTLOG_TEXT_SCALE 生效', () {
      expect(
        resolveTextScaleFromEnvironment(<String, String>{'ACTLOG_TEXT_SCALE': '2'}),
        2.0,
      );
    });

    test('旧 PRACTILOG_TEXT_SCALE 仍生效（回归）', () {
      expect(
        resolveTextScaleFromEnvironment(<String, String>{'PRACTILOG_TEXT_SCALE': '2'}),
        2.0,
      );
    });

    test('两个都设时新名优先', () {
      expect(
        resolveTextScaleFromEnvironment(<String, String>{
          'ACTLOG_TEXT_SCALE': '1.5',
          'PRACTILOG_TEXT_SCALE': '2',
        }),
        1.5,
      );
    });

    test('都没设时是 1.0', () {
      expect(resolveTextScaleFromEnvironment(<String, String>{}), 1.0);
    });

    test('旧 PRACTILOG_DATA_DIR 仍能钉住数据目录', () {
      expect(
        dataDirOverrideFromArgs(
          <String>[],
          environment: <String, String>{'PRACTILOG_DATA_DIR': 'E:\\old'},
        ),
        'E:\\old',
      );
    });

    test('新旧 DATA_DIR 同时存在时新名优先', () {
      expect(
        dataDirOverrideFromArgs(
          <String>[],
          environment: <String, String>{
            'ACTLOG_DATA_DIR': 'E:\\new',
            'PRACTILOG_DATA_DIR': 'E:\\old',
          },
        ),
        'E:\\new',
      );
    });

    test('旧 PRACTILOG_SELFTEST 仍能开自检', () {
      expect(
        selftestRequested(
          <String>[],
          environment: <String, String>{'PRACTILOG_SELFTEST': '1'},
        ),
        isTrue,
      );
      expect(
        selftestRequested(
          <String>[],
          environment: <String, String>{'ACTLOG_SELFTEST': '1'},
        ),
        isTrue,
      );
    });

    test('旧 PRACTILOG_TOAST_PROBE 仍能开 toast 探针', () {
      expect(
        toastProbeRequested(
          <String>[],
          environment: <String, String>{'PRACTILOG_TOAST_PROBE': '1'},
        ),
        isTrue,
      );
      expect(
        toastProbeRequested(
          <String>[],
          environment: <String, String>{'ACTLOG_TOAST_PROBE': 'true'},
        ),
        isTrue,
      );
    });
  });
}
