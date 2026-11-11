// Windows toast 可见性探针（P1 §16.5 验证用，**不是**产品功能）。
//
// 背景：§16.5 要确认「Windows 通知中心的 toast 是否可见」。但应用里此前
// **没有任何一处**发通知的代码路径 —— `flutter_local_notifications` 只被
// dart_plugin_registrant 自动注册，从未被调用过。没有代码路径，「toast 可见」
// 无从验证。
//
// 所以这里补一条**可控开关**路径，与 `--selftest` 完全同构：
//   * 只有带 `--toast-probe`（或 `ACTLOG_TOAST_PROBE=1`）启动时才发通知；
//   * 正常启动**完全不受影响**（开关判断在 `main()` 最前面，早于建库与建托盘）；
//   * 报告增量落盘，退出码明确（0 = 通知已提交给通知中心）。
//
// 通知正文里埋了唯一标记 `kToastProbeMarker`：验证脚本用它在 Windows 通知
// 数据库里精确定位「这一条就是本探针发的」，而不是靠数量增量瞎猜。

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;

/// 探针开关的环境变量名。
const String kToastProbeEnvVar = 'ACTLOG_TOAST_PROBE';

/// Legacy toast-probe env var name (still honored; the new name wins).
const String kLegacyToastProbeEnvVar = 'PRACTILOG_TOAST_PROBE';

/// 探针报告文件名（写在应用支持目录）。
const String kToastProbeReportName = 'actlog_toast_probe.log';

/// 通知正文里的唯一标记：验证脚本据此在通知数据库里精确定位本探针的通知。
const String kToastProbeMarker = 'P1-TOAST-PROBE-20261107';

/// 通知 id（固定值，便于在通知中心里辨认）。
const int kToastProbeNotificationId = 20261107;

/// AppUserModelId：插件会把它注册进 `HKCU\Software\Classes\AppUserModelId`。
const String kToastProbeAppUserModelId = 'com.actlog.actlog';

/// 通知激活回调用的 GUID（插件会校验格式，必须是合法 GUID）。
const String kToastProbeGuid = '9F1E2D3C-4B5A-6C7D-8E9F-0A1B2C3D4E5F';

/// 是否要跑 toast 探针。
///
/// 与 `selftestRequested` 同构：命令行 `--toast-probe`（或 `--toast-probe=1`），
/// 或环境变量 `ACTLOG_TOAST_PROBE=1`。默认启动**不跑**任何探针逻辑。
bool toastProbeRequested(List<String> args, {Map<String, String>? environment}) {
  for (final arg in args) {
    if (arg == '--toast-probe' || arg.startsWith('--toast-probe=')) return true;
  }
  final env = environment ?? Platform.environment;
  for (final name in <String>[kToastProbeEnvVar, kLegacyToastProbeEnvVar]) {
    final raw = env[name];
    if (raw == null) continue;
    final value = raw.trim().toLowerCase();
    if (value == '1' || value == 'true' || value == 'yes') return true;
  }
  return false;
}

/// 跑一次 toast 探针：发一条通知，写报告文件，返回进程退出码。
///
/// 退出码：
/// * 0 = 通知已成功提交给 Windows 通知中心；
/// * 1 = 抛了异常（报告里有错误详情）；
/// * 2 = 插件初始化没有返回 true（通知根本没发出去）。
Future<int> runToastProbe({required Directory supportDir}) async {
  final reportFile = File(p.join(supportDir.path, kToastProbeReportName));
  final lines = <String>[];

  /// 增量落盘报告（失败时也能留下「跑到哪一步」的现场）。
  Future<void> flush(String result) async {
    final buffer = StringBuffer()
      ..writeln('actlog toast probe ${DateTime.now().toIso8601String()}')
      ..writeln('result = $result')
      ..writeln('marker = $kToastProbeMarker')
      ..writeln('aumid  = $kToastProbeAppUserModelId');
    for (final line in lines) {
      buffer.writeln(line);
    }
    try {
      await reportFile.writeAsString(buffer.toString(), flush: true);
    } catch (_) {
      // 报告写不出去也不能影响结果判定。
    }
  }

  final plugin = FlutterLocalNotificationsPlugin();
  try {
    final iconPath = _resolveIconPath();
    lines.add('iconPath = ${iconPath ?? '(none)'}');

    final initialized = await plugin.initialize(
      InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: 'actlog',
          appUserModelId: kToastProbeAppUserModelId,
          guid: kToastProbeGuid,
          iconPath: iconPath,
        ),
      ),
    );
    lines.add('initialize = $initialized');
    if (initialized != true) {
      await flush('FAIL initialize returned $initialized');
      return 2;
    }

    await plugin.show(
      kToastProbeNotificationId,
      'actlog toast probe',
      '$kToastProbeMarker 通知中心可见性探针',
      const NotificationDetails(
        windows: WindowsNotificationDetails(subtitle: 'P1 section 16.5'),
      ),
      payload: kToastProbeMarker,
    );
    lines.add('show = called');
    await flush('OK');
    return 0;
  } catch (error) {
    lines.add('error = $error');
    await flush('FAIL $error');
    return 1;
  }
}

/// 找应用 exe 同目录下的图标（有就带上，toast 会显示它）。
String? _resolveIconPath() {
  try {
    final dir = p.dirname(Platform.resolvedExecutable);
    for (final name in <String>['app_icon.ico', 'actlog.ico']) {
      final candidate = File(p.join(dir, name));
      if (candidate.existsSync()) return candidate.path;
    }
  } catch (_) {
    // 解析不出来就用默认图标。
  }
  return null;
}
