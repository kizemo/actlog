import 'dart:io';

import 'package:path/path.dart' as p;

/// 显式指定数据目录用的环境变量名（与 `ACTLOG_SELFTEST` 同族）。
const String kDataDirEnvVar = 'ACTLOG_DATA_DIR';

/// 旧版数据目录环境变量名。
///
/// **保留可读**（不删）：旧名是公开契约，AGENTS.md §3 的验收装置仍在用它把数据
/// 钉在临时目录。读取顺序是「新名优先、旧名兜底」。
const String kLegacyDataDirEnvVar = 'PRACTILOG_DATA_DIR';

/// 从命令行与环境变量里取显式数据目录，没有则返回 `null`。
///
/// 支持 `--data-dir=<path>`、`--data-dir <path>`，以及环境变量
/// [kDataDirEnvVar]（新名优先）与 [kLegacyDataDirEnvVar]（旧名兜底）。
/// 存在的理由是让验收脚本能把数据钉死在临时目录里，
/// 从而**在不碰真机数据的前提下**验证「安装目录优先」这条逻辑；
/// 与 `selftestRequested` 一样做成纯函数，便于单测直接喂参数。
String? dataDirOverrideFromArgs(
  List<String> args, {
  Map<String, String>? environment,
}) {
  const flag = '--data-dir';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('$flag=')) {
      final value = arg.substring(flag.length + 1).trim();
      if (value.isNotEmpty) return value;
    } else if (arg == flag && i + 1 < args.length) {
      final value = args[i + 1].trim();
      if (value.isNotEmpty) return value;
    }
  }
  final env = environment ?? Platform.environment;
  for (final name in <String>[kDataDirEnvVar, kLegacyDataDirEnvVar]) {
    final value = env[name]?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

/// 应用数据目录的**名字**。
///
/// 刻意不叫 `data`：Flutter 的 Windows 产物里 `<exe 所在目录>\data\` 已经被框架
/// 占用（`<exe>\data\flutter_assets\` 是资源目录，托盘图标
/// `assets/icon.png` 就是从这里解析的）。把 SQLite 塞进同一个目录会和框架产物
/// 混在一起，卸载与备份都难以区分，因此另起一个不冲突的名字。
const kUserDataDirName = 'userdata';

/// 主数据库文件名。全应用唯一定义点，其他地方一律引用它，不要再写字符串字面量。
const kDbFileName = 'actlog.db';

/// 旧版数据库文件名 —— **只作为搬迁来源读**，既不删也不改。
///
/// 老用户的库里存的就是这个文件名；改名之后旧文件仍留在原地，
/// 由 [resolveDataDirectory] 在首次运行时复制到新名下（复制而非移动，
/// 保留退回旧版本构建的可能）。
const kLegacyDbFileName = 'practilog.db';

/// 新版 `%APPDATA%\com.actlog\actlog\` 的相对路径分段（**只读**搬迁来源）。
const kCurrentDataDirSegments = <String>['com.actlog', 'actlog'];

/// 旧版 `%APPDATA%\com.practiclog\practilog\` 的相对路径分段（**只读**搬迁来源）。
///
/// 反向兼容只读这一段：新版落位后不应再往用户资料夹写任何业务数据。
const kLegacyDataDirSegments = <String>['com.practiclog', 'practilog'];

/// `%PROGRAMDATA%\actlog` 的相对路径分段。
///
/// 这是安装目录不可写时的**第一兜底**：`C:\ProgramData` 在用户资料夹之外，
/// 因此仍然满足「业务数据不放用户资料文件夹」这条产品要求。
const kProgramDataDirSegments = <String>['actlog'];

/// 旧版 `%PROGRAMDATA%\practilog` 的相对路径分段（**只读**搬迁来源）。
const kLegacyProgramDataDirSegments = <String>['practilog'];

/// `%LOCALAPPDATA%\com.actlog\actlog-fallback` 的相对路径分段。
///
/// 这是最后一档兜底：只有安装目录和 `%PROGRAMDATA%` 都不可写时才会用到。
/// 之所以仍保留它，是因为「数据写不进去 → 应用直接起不来」比「数据位置不理想」
/// 更糟；用了这一档会在启动日志里留下 `layout=legacyFallback`，可被验收脚本抓到。
const kFallbackDataDirSegments = <String>['com.actlog', 'actlog-fallback'];

/// 旧版 `%LOCALAPPDATA%\com.practiclog\practilog-fallback`（**只读**搬迁来源）。
const kLegacyFallbackDataDirSegments = <String>[
  'com.practiclog',
  'practilog-fallback',
];

/// 实际使用的数据目录布局。
enum DataDirLayout {
  /// 数据就在安装目录（exe 同级）的 `userdata` 里 —— 期望的正常形态。
  install,

  /// `%PROGRAMDATA%\actlog` —— 仍在用户资料夹之外，安装目录不可写时的兜底。
  programData,

  /// `%LOCALAPPDATA%` 兜底 —— 说明安装目录与 `%PROGRAMDATA%` 都不可写，
  /// 通常意味着权限配置有问题，需要在真机上排查。
  legacyFallback,

  /// 命令行 / 环境变量显式指定的目录，主要用于自测与验收脚本。
  explicit,
}

/// 数据目录解析结果：落在哪里、为什么、有哪些证据。
///
/// [notes] 会被逐行写进启动日志，是真机判定「数据到底落在哪」的唯一权威证据。
class DataDirResolution {
  /// 构造一次解析结果。
  const DataDirResolution({
    required this.dir,
    required this.layout,
    required this.notes,
  });

  /// 最终采用的数据目录。
  final Directory dir;

  /// 采用的布局档位。
  final DataDirLayout layout;

  /// 人类可读的决策与迁移轨迹。
  final List<String> notes;
}

/// 由 exe 全路径推导安装目录内的数据目录路径（纯字符串，不碰文件系统）。
String userDataDirPathFromExe(String exePath) =>
    p.join(p.dirname(exePath), kUserDataDirName);

/// 由 `%APPDATA%` 推导新版数据目录（纯字符串）。
String currentDataDirPathFromAppData(String appData) =>
    p.joinAll(<String>[appData, ...kCurrentDataDirSegments]);

/// 由 `%APPDATA%` 推导旧版数据目录（纯字符串）。
String legacyDataDirPathFromAppData(String appData) =>
    p.joinAll(<String>[appData, ...kLegacyDataDirSegments]);

/// 由 `%PROGRAMDATA%` 推导第一兜底数据目录（纯字符串）。
String programDataDirPathFromProgramData(String programData) =>
    p.joinAll(<String>[programData, ...kProgramDataDirSegments]);

/// 由 `%PROGRAMDATA%` 推导旧版第一兜底数据目录（纯字符串）。
String legacyProgramDataDirPathFromProgramData(String programData) =>
    p.joinAll(<String>[programData, ...kLegacyProgramDataDirSegments]);

/// 由 `%LOCALAPPDATA%` 推导最后兜底的数据目录（纯字符串）。
String fallbackDataDirPathFromLocalAppData(String localAppData) =>
    p.joinAll(<String>[localAppData, ...kFallbackDataDirSegments]);

/// 由 `%LOCALAPPDATA%` 推导旧版最后兜底的数据目录（纯字符串）。
String legacyFallbackDataDirPathFromLocalAppData(String localAppData) =>
    p.joinAll(<String>[localAppData, ...kLegacyFallbackDataDirSegments]);

/// 需要随主库一起搬迁的 SQLite 附属文件名。
///
/// WAL 模式下未合并的改动在 `-wal` 里，只搬 `.db` 会丢最近写入；`-shm` 是索引缓存，
/// 搬不搬都不影响正确性，一起搬更稳。前提仍是数据库**正常关闭**（本应用的
/// `quitApp` 与自测都会先 `db.close()`）。
List<String> legacyMigrationFileNames(String dbFileName) => <String>[
      dbFileName,
      '$dbFileName-wal',
      '$dbFileName-shm',
    ];

/// 是否需要把旧版数据搬迁到新位置。
///
/// 「只在旧库存在且新位置还没有库时搬」。漏了 `!newDbExists` 这个条件会在每次启动
/// 都用旧快照覆盖新库，直接丢数据；只看新库存在则会把首次启动的空目录误判成
/// 「已经搬好了」。
bool needsLegacyMigration({
  required bool legacyDbExists,
  required bool newDbExists,
}) =>
    legacyDbExists && !newDbExists;

/// 解析（并确保存在）可写的数据目录，顺带完成从旧位置的一次性搬迁。
///
/// 候选优先级（写入位置）：
/// 1. [explicitDir] —— 命令行 `--data-dir` 或环境变量 `ACTLOG_DATA_DIR`
///    （旧名 `PRACTILOG_DATA_DIR` 兜底），供自测与验收脚本把数据钉死在临时目录，
///    避免污染真机数据。
/// 2. 安装目录 `<exe 所在目录>\userdata`。
/// 3. `%PROGRAMDATA%\actlog`。
/// 4. `%LOCALAPPDATA%\com.actlog\actlog-fallback`。
///
/// 每个候选都**实写一个探针文件**验证可写，而不是只看目录能否创建：
/// `Program Files` 下普通用户能建目录不代表能写文件，只看创建结果会让应用一路
/// 走到 SQLite 打开失败才崩，且报错原因和真实根因隔了几层。
/// 全部候选都不可写时抛 [StateError] 并把逐个候选的失败原因留在
/// [DataDirResolution.notes] 同源的文本里 —— 与其静默把数据写到一个不存在的地方，
/// 不如让启动失败并留下原因。
///
/// **旧数据只读搬迁**：老版本可能把库放在 `%APPDATA%\com.practiclog\practilog\`
/// （文件名 `practilog.db`）、`%PROGRAMDATA%\practilog\` 或
/// `%LOCALAPPDATA%\com.practiclog\practilog-fallback\`。这些位置只作**读取来源**，
/// 新版不再往里写；命中且新位置还没有库时把库（含 `-wal`/`-shm`）**复制**到新位置，
/// 旧文件保留，让老用户第一次看到的就是原来那份数据而不是空库。
///
/// [exePath]/[appData]/[programData]/[localAppData] 用于注入，便于单测。
Future<DataDirResolution> resolveDataDirectory({
  String? explicitDir,
  String? exePath,
  String? appData,
  String? programData,
  String? localAppData,
  String dbFileName = kDbFileName,
}) async {
  final env = Platform.environment;
  final resolvedExe = exePath ?? Platform.resolvedExecutable;
  final notes = <String>[];

  final candidates = <(DataDirLayout, String)>[];
  if (explicitDir != null && explicitDir.isNotEmpty) {
    candidates.add((DataDirLayout.explicit, explicitDir));
  }
  candidates.add((DataDirLayout.install, userDataDirPathFromExe(resolvedExe)));
  final pd = programData ?? env['PROGRAMDATA'];
  if (pd != null && pd.isNotEmpty) {
    candidates.add((DataDirLayout.programData, programDataDirPathFromProgramData(pd)));
  }
  final la = localAppData ?? env['LOCALAPPDATA'];
  if (la != null && la.isNotEmpty) {
    candidates.add((DataDirLayout.legacyFallback, fallbackDataDirPathFromLocalAppData(la)));
  }

  Directory? chosen;
  DataDirLayout chosenLayout = DataDirLayout.install;
  for (final entry in candidates) {
    final dir = Directory(entry.$2);
    try {
      await dir.create(recursive: true);
      if (await _isWritable(dir)) {
        chosen = dir;
        chosenLayout = entry.$1;
        notes.add('selected ${entry.$1.name}: ${dir.path}');
        break;
      }
      notes.add('not writable, skipped: ${dir.path}');
    } on Object catch (e) {
      notes.add('create failed, skipped: ${dir.path} <- $e');
    }
  }
  if (chosen == null) {
    throw StateError(
      'no writable data directory; candidates: ${notes.join(' | ')}',
    );
  }

  // 搬迁旧库：从旧版数据目录复制过来。
  // 复制而非移动，是为了保留退回旧版本构建的可能；确认无误后由用户自行清理。
  // 显式目录（--data-dir / ACTLOG_DATA_DIR）**不做搬迁**：那条路径是给验收与
  // 自测用的，把用户真实库复制进去会让「测试产物」和「真实数据」混在一起。
  final ad = appData ?? env['APPDATA'];
  if (chosenLayout != DataDirLayout.explicit && ad != null && ad.isNotEmpty) {
    final newDb = File(p.join(chosen.path, dbFileName));
    final newDbExists = await newDb.exists();

    final sources = <Directory>[
      // 新版 %APPDATA% 位置（可能已被早期 actlog 版本写过）。
      Directory(currentDataDirPathFromAppData(ad)),
      // 旧版 %APPDATA% 位置：老用户的 practilog.db 就在这里。
      Directory(legacyDataDirPathFromAppData(ad)),
    ];
    if (pd != null && pd.isNotEmpty) {
      sources.add(Directory(legacyProgramDataDirPathFromProgramData(pd)));
      sources.add(Directory(programDataDirPathFromProgramData(pd)));
    }
    if (la != null && la.isNotEmpty) {
      sources.add(Directory(legacyFallbackDataDirPathFromLocalAppData(la)));
      sources.add(Directory(fallbackDataDirPathFromLocalAppData(la)));
    }

    var migrated = false;
    for (final srcDir in sources) {
      if (migrated) break;
      if (p.equals(srcDir.path, chosen.path)) continue;
      // 源库可能还是旧文件名（practilog.db），也可能已经改成新名（actlog.db）。
      String? srcName;
      for (final candidate in <String>[kLegacyDbFileName, dbFileName]) {
        if (await File(p.join(srcDir.path, candidate)).exists()) {
          srcName = candidate;
          break;
        }
      }
      if (srcName == null) continue;
      if (!needsLegacyMigration(
        legacyDbExists: true,
        newDbExists: newDbExists,
      )) {
        break;
      }
      for (final name in legacyMigrationFileNames(srcName)) {
        final src = File(p.join(srcDir.path, name));
        if (!await src.exists()) continue;
        final target = name == srcName
            ? dbFileName
            : name.replaceFirst(srcName, dbFileName);
        await src.copy(p.join(chosen.path, target));
        notes.add('migrated $target from ${srcDir.path}');
      }
      notes.add('legacy migration done: ${srcDir.path} -> ${chosen.path}');
      migrated = true;
    }
    if (!migrated) {
      notes.add('legacy migration not needed');
    }
  }

  return DataDirResolution(dir: chosen, layout: chosenLayout, notes: notes);
}

/// 往[dir]里真写一个小文件再删掉，以此判定可写性。
///
/// 目录创建成功但写入被 ACL 拒绝是常见形态，必须实测写入。
Future<bool> _isWritable(Directory dir) async {
  final probe = File(
    p.join(dir.path, '.actlog_write_probe_${DateTime.now().microsecondsSinceEpoch}'),
  );
  try {
    await probe.writeAsString('probe', flush: true);
    await probe.delete();
    return true;
  } on Object {
    try {
      if (await probe.exists()) {
        await probe.delete();
      }
    } on Object {
      // 探针文件删不掉只说明权限奇怪，不影响本次可写性判定结论。
    }
    return false;
  }
}
