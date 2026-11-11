import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'src/app.dart';
import 'src/app_paths.dart';
import 'src/desktop_shell.dart';
import 'src/providers.dart';
import 'src/selftest.dart';
import 'src/toast_probe.dart';

/// 应用入口：解析数据目录 → 打开 SQLite → 注入 Riverpod 作用域。
///
/// 命令行参数与环境变量：
/// * `--selftest`（或 `ACTLOG_SELFTEST=1`）→ 跑一次自检并退出；
/// * `--toast-probe`（或 `ACTLOG_TOAST_PROBE=1`）→ 发一条探针通知并退出；
/// * `--data-dir=<path>`（或 `ACTLOG_DATA_DIR`）→ 把数据目录钉死在该路径，
///   供验收与自测使用；该档位**不触发**旧库搬迁；
/// * `ACTLOG_TEXT_SCALE=<倍数>` → 全局字号缩放（`2` = 200%），非法值回落
///   100%；只影响本进程的 `MediaQuery.textScaler`，**不改用户的系统环境**；
/// * 不带开关 → 正常启动，**不做**任何自检。
///
/// 数据目录**不再**走 `path_provider` 的「用户资料夹」语义：业务数据落在
/// 安装目录内的 `userdata`，详见 [resolveDataDirectory] 的候选优先级说明。
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final resolution = await resolveDataDirectory(
    explicitDir: dataDirOverrideFromArgs(args),
    dbFileName: kDbFileName,
  );
  final dataDir = resolution.dir;
  final dbFile = File(p.join(dataDir.path, kDbFileName));

  if (selftestRequested(args)) {
    exit(
      await runSelfTest(supportDir: dataDir, dbFile: dbFile),
    );
  }

  // Toast 探针（P1 §16.5 验证用）：刻意放在建库与建托盘之前，
  // 保证探针既不碰用户真实库、也不影响正常启动路径。
  if (toastProbeRequested(args)) {
    exit(
      await runToastProbe(supportDir: dataDir),
    );
  }

  // 先把「数据到底落在哪」写进启动日志：这条证据不依赖 stdout，且日志本身就在
  // 数据目录里，是真机判定 layout 的唯一可靠入口。
  await logStartupLine(
    dataDir,
    'data.layout=${resolution.layout.name} dir=${dataDir.path} '
        'notes=${resolution.notes.join('; ')}',
  );

  final db = openActLogDatabase(dbFile);

  // 窗口与托盘（标题、关闭隐藏到托盘、托盘切换窗口）。
  await setupDesktopShell(supportDir: dataDir);

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      // 裁定 B：字号 200% 走环境变量，只在本进程的 MediaQuery 上层施加。
      child: ActLogApp(
        textScale: resolveTextScaleFromEnvironment(Platform.environment),
      ),
    ),
  );
}
