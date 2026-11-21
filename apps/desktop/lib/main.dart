import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'src/app.dart';
import 'src/app_paths.dart';
import 'src/desktop_shell.dart';
import 'src/l10n/app_localizations.dart';
import 'src/providers.dart';
import 'src/selftest.dart';
import 'src/toast_probe.dart';

/// 解析「首次 Show 之前」要用的界面语言：读 `settings` 表里的 `locale` 行。
///
/// 为什么必须在 [runApp] 之前解析：[setupDesktopShell] 会在窗口 show 之前推一次
/// 窗口标题与任务栏按钮名，而 Windows shell 会拿第一次读到的名字做缓存。
/// 启动时若一律按 zh 推 `知行日志 actlog`，en 态用户的任务栏就永远挂着中文前缀
/// （Task 47 W1c-3 实测：三臂读数逐字相同 ⇒ 语言压根没进到这条链路）。
///
/// 解析口径与 `currentPreferencesProvider` 完全同源：同一张 `settings` 表、
/// 同一行 `locale`、同一个 [AppLanguage.fromCode]，所以「首推」与「设置页显示」
/// 不会各说各话。读库失败一律回落 zh —— 启动链路不能被偏好读取拖垮。
Future<AppLanguage> resolveStartupLanguage(ActLogDatabase db) async {
  try {
    final String? code =
        await ActLogRepositories(db).settings.get(settingsKeyLocale);
    return AppLanguage.fromCode(code);
  } catch (_) {
    return AppLanguage.zh;
  }
}

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

  // 首次 Show 之前先把持久化语言解析出来：标题 / 任务栏按钮名只在这一步推送一次
  // （见 setupDesktopShell），推错就得等重启才会改。
  final AppLanguage language = await resolveStartupLanguage(db);

  // 窗口与托盘（标题、关闭隐藏到托盘、托盘切换窗口）。
  await setupDesktopShell(supportDir: dataDir, language: language);

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      // 裁定 B：字号 200% 走环境变量，只在本进程的 MediaQuery 上层施加。
      child: ActLogApp(
        textScale: resolveTextScaleFromEnvironment(Platform.environment),
        // 根组件拿同一个语言做初值，避免第一帧后再白推一次 zh→en 往返。
        initialLanguage: language,
      ),
    ),
  );
}
