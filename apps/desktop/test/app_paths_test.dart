// app_paths 的单测：覆盖纯函数、迁移判定真值表、候选优先级与失败路径。
//
// 刻意只用文件系统事实（临时目录 + 「同名文件占位」制造不可创建候选），
// 不依赖 path_provider 插件，也不依赖真机 ACL —— 这两点都是本项目 test 面的约束。
// 临时目录用 createTempSync + tearDown 手工清理，不用 addTemporaryDirectory
// （它不在 flutter_test 的导出面里）。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:actlog/src/app_paths.dart';

/// 造一个带唯一后缀的临时目录，交给 tearDown 统一删。
Directory _tempDir(String tag) =>
    Directory.systemTemp.createTempSync('actlog_$tag');

void main() {
  final scratch = <Directory>[];

  Directory makeTemp(String tag) {
    final d = _tempDir(tag);
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

  group('纯路径函数', () {
    test('安装目录数据路径 = exe 同级 userdata，且绝不叫 data', () {
      final got = userDataDirPathFromExe(p.join('C:', 'pf', 'actlog', 'actlog.exe'));
      expect(got, p.join('C:', 'pf', 'actlog', 'userdata'));
      // 框架占用 <exe>\data\flutter_assets\，撞名会让托盘图标解析失败。
      expect(p.basename(got), isNot('data'));
      expect(p.basename(got), kUserDataDirName);
    });

    test('旧版路径由 %APPDATA% 推导', () {
      expect(
        legacyDataDirPathFromAppData(p.join('C:', 'Users', 'u', 'AppData', 'Roaming')),
        p.join('C:', 'Users', 'u', 'AppData', 'Roaming', 'com.practiclog', 'practilog'),
      );
    });

    test('ProgramData 兜底路径在用户资料夹之外', () {
      final got = programDataDirPathFromProgramData(p.join('C:', 'ProgramData'));
      expect(got, p.join('C:', 'ProgramData', 'actlog'));
      expect(got.contains('AppData'), isFalse);
    });

    test('LOCALAPPDATA 兜底路径带 actlog-fallback 段', () {
      expect(
        fallbackDataDirPathFromLocalAppData(p.join('C:', 'Users', 'u', 'AppData', 'Local')),
        p.join('C:', 'Users', 'u', 'AppData', 'Local', 'com.actlog', 'actlog-fallback'),
      );
    });

    test('搬迁文件清单含 WAL 与 SHM', () {
      // 只搬 .db 会丢掉 WAL 里尚未合并的写入。
      expect(legacyMigrationFileNames('actlog.db'), <String>[
        'actlog.db',
        'actlog.db-wal',
        'actlog.db-shm',
      ]);
    });
  });

  group('needsLegacyMigration 真值表', () {
    test('旧有新无 → 搬', () {
      expect(needsLegacyMigration(legacyDbExists: true, newDbExists: false), isTrue);
    });
    test('两边都有 → 不搬（搬了会用旧快照覆盖新库）', () {
      expect(needsLegacyMigration(legacyDbExists: true, newDbExists: true), isFalse);
    });
    test('旧无新有 → 不搬', () {
      expect(needsLegacyMigration(legacyDbExists: false, newDbExists: true), isFalse);
    });
    test('两边都无 → 不搬（首次安装）', () {
      expect(needsLegacyMigration(legacyDbExists: false, newDbExists: false), isFalse);
    });
  });

  group('dataDirOverrideFromArgs', () {
    test('等号形式', () {
      expect(dataDirOverrideFromArgs(<String>['--data-dir=D:\\x']), 'D:\\x');
    });
    test('空格分隔形式', () {
      expect(dataDirOverrideFromArgs(<String>['--data-dir', 'D:\\x']), 'D:\\x');
    });
    test('值被 trim', () {
      expect(dataDirOverrideFromArgs(<String>['--data-dir=  D:\\x ']), 'D:\\x');
    });
    test('只有 flag 没有值 → null', () {
      expect(dataDirOverrideFromArgs(<String>['--data-dir']), isNull);
      expect(dataDirOverrideFromArgs(<String>['--data-dir=']), isNull);
    });
    test('环境变量兜底', () {
      expect(
        dataDirOverrideFromArgs(<String>[], environment: <String, String>{kDataDirEnvVar: 'E:\\d'}),
        'E:\\d',
      );
    });
    test('空环境变量不算覆盖', () {
      expect(
        dataDirOverrideFromArgs(<String>[], environment: <String, String>{kDataDirEnvVar: '   '}),
        isNull,
      );
    });
    test('其他参数不干扰', () {
      expect(dataDirOverrideFromArgs(<String>['--selftest', '--toast-probe=1']), isNull);
    });
  });

  group('resolveDataDirectory', () {
    test('安装目录可写时优先选它（layout=install）', () async {
      final exeHome = makeTemp('exe');
      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: '',
        programData: '',
        localAppData: '',
      );
      expect(res.layout, DataDirLayout.install);
      expect(res.dir.path, p.join(exeHome.path, kUserDataDirName));
      expect(res.dir.existsSync(), isTrue);
      expect(res.notes.first, startsWith('selected install'));
    });

    test('安装目录不可用时降级到 ProgramData，且仍在用户资料夹外', () async {
      final exeHome = makeTemp('exe2');
      // 用一个同名**文件**占住 userdata 这个位置：目录创建必然失败。
      File(p.join(exeHome.path, kUserDataDirName)).writeAsStringSync('occupied');
      final pdHome = makeTemp('pd');
      final laHome = makeTemp('la');
      // 注入一个「有旧库的 %APPDATA% 根」，这样降级后「没落回用户资料夹」才是可断言的事实。
      final ahHome = makeTemp('ah2');
      final legacyDir = Directory(legacyDataDirPathFromAppData(ahHome.path))
        ..createSync(recursive: true);
      File(p.join(legacyDir.path, kDbFileName)).writeAsStringSync('OLDDB');
      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: ahHome.path,
        programData: pdHome.path,
        localAppData: laHome.path,
      );
      expect(res.layout, DataDirLayout.programData);
      expect(res.dir.path, p.join(pdHome.path, 'actlog'));
      // 占位是**文件**时，create() 直接抛 PathExistsException，所以走的是
      // "create failed, skipped"；ACL 拒写才走 "not writable, skipped"。
      // 两条都是「这个候选用不了」，断言只锁住「记录了这个候选被跳过」。
      expect(
        res.notes.where(
          (n) => n.contains('skipped') && n.contains(p.join(exeHome.path, kUserDataDirName)),
        ),
        isNotEmpty,
      );
      // 「仍在用户资料夹外」必须用**注入的根**做前缀判定，不能对路径粗判 'AppData'
      // 字样：临时根本身就躺在 %LOCALAPPDATA%\Temp 里，字符串判定恒真、毫无意义。
      expect(res.dir.path.startsWith(pdHome.path), isTrue);
      expect(res.dir.path.startsWith(ahHome.path), isFalse);
      expect(res.dir.path.startsWith(laHome.path), isFalse);
      // 降级同样完成搬迁，且旧库只复制不删除（保留退回旧版本的能力）。
      expect(File(p.join(res.dir.path, kDbFileName)).readAsStringSync(), 'OLDDB');
      expect(File(p.join(legacyDir.path, kDbFileName)).existsSync(), isTrue);
    });

    test('ProgramData 也不可用时才落到 legacyFallback', () async {
      final exeHome = makeTemp('exe3');
      File(p.join(exeHome.path, kUserDataDirName)).writeAsStringSync('occupied');
      final pdHome = makeTemp('pd3');
      File(p.join(pdHome.path, 'actlog')).writeAsStringSync('occupied');
      final laHome = makeTemp('la3');
      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: '',
        programData: pdHome.path,
        localAppData: laHome.path,
      );
      expect(res.layout, DataDirLayout.legacyFallback);
      expect(res.dir.existsSync(), isTrue);
    });

    test('全部候选不可用 → StateError，且原因留在消息里', () async {
      final exeHome = makeTemp('exe4');
      File(p.join(exeHome.path, kUserDataDirName)).writeAsStringSync('occupied');
      final pdHome = makeTemp('pd4');
      File(p.join(pdHome.path, 'actlog')).writeAsStringSync('occupied');
      final laHome = makeTemp('la4');
      // 让兜底路径的中间段变成文件，创建必然失败。
      File(p.join(laHome.path, 'com.actlog')).writeAsStringSync('occupied');
      expect(
        () => resolveDataDirectory(
          exePath: p.join(exeHome.path, 'actlog.exe'),
          appData: '',
          programData: pdHome.path,
          localAppData: laHome.path,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('显式 --data-dir 生效且不搬迁旧库', () async {
      final explicitHome = makeTemp('exp');
      final explicit = p.join(explicitHome.path, 'given');
      final legacyHome = makeTemp('legacy_exp');
      final legacyDir = Directory(legacyDataDirPathFromAppData(legacyHome.path))
        ..createSync(recursive: true);
      File(p.join(legacyDir.path, kDbFileName)).writeAsStringSync('REAL');

      final res = await resolveDataDirectory(
        explicitDir: explicit,
        exePath: p.join(makeTemp('exe5').path, 'actlog.exe'),
        appData: legacyHome.path,
        programData: '',
        localAppData: '',
      );
      expect(res.layout, DataDirLayout.explicit);
      expect(res.dir.path, explicit);
      // 验收目录里绝不能混进用户真实数据。
      expect(File(p.join(explicit, kDbFileName)).existsSync(), isFalse);
      expect(res.notes.any((n) => n.startsWith('migrated')), isFalse);
      expect(File(p.join(legacyDir.path, kDbFileName)).readAsStringSync(), 'REAL');
    });

    test('首次启动把旧库（含 WAL）复制进安装目录，旧文件保留', () async {
      final exeHome = makeTemp('exe6');
      final legacyHome = makeTemp('legacy6');
      final legacyDir = Directory(legacyDataDirPathFromAppData(legacyHome.path))
        ..createSync(recursive: true);
      File(p.join(legacyDir.path, kDbFileName)).writeAsStringSync('DB');
      File(p.join(legacyDir.path, '$kDbFileName-wal')).writeAsStringSync('WAL');

      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: legacyHome.path,
        programData: '',
        localAppData: '',
      );
      expect(res.layout, DataDirLayout.install);
      expect(File(p.join(res.dir.path, kDbFileName)).readAsStringSync(), 'DB');
      // WAL 里是尚未合并的写入，漏搬等于丢最近的数据。
      expect(File(p.join(res.dir.path, '$kDbFileName-wal')).readAsStringSync(), 'WAL');
      // 复制而非移动：保留退回旧版本构建的能力。
      expect(File(p.join(legacyDir.path, kDbFileName)).existsSync(), isTrue);
      expect(res.notes.any((n) => n.startsWith('migrated actlog.db')), isTrue);
      expect(res.notes.any((n) => n == 'legacy migration not needed'), isFalse);
    });

    test('新位置已有库时不再搬迁（否则会用旧快照覆盖新数据）', () async {
      final exeHome = makeTemp('exe7');
      final dataDir = Directory(userDataDirPathFromExe(p.join(exeHome.path, 'actlog.exe')))
        ..createSync(recursive: true);
      File(p.join(dataDir.path, kDbFileName)).writeAsStringSync('NEW');
      final legacyHome = makeTemp('legacy7');
      final legacyDir = Directory(legacyDataDirPathFromAppData(legacyHome.path))
        ..createSync(recursive: true);
      File(p.join(legacyDir.path, kDbFileName)).writeAsStringSync('OLD');

      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: legacyHome.path,
        programData: '',
        localAppData: '',
      );
      expect(File(p.join(res.dir.path, kDbFileName)).readAsStringSync(), 'NEW');
      expect(res.notes, contains('legacy migration not needed'));
    });

    test('解析后目录里没有残留写探针文件', () async {
      final exeHome = makeTemp('exe8');
      final res = await resolveDataDirectory(
        exePath: p.join(exeHome.path, 'actlog.exe'),
        appData: '',
        programData: '',
        localAppData: '',
      );
      expect(
        res.dir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('.actlog_write_probe')),
        isEmpty,
      );
    });
  });
}
