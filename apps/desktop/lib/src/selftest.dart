// 见 desktop_shell.dart 顶部说明：这里同样使用 window_manager 的 0.5.x 兼容 API。
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/legacy.dart';

import 'desktop_shell.dart';

/// 自检开关用的环境变量名。
const String kSelfTestEnvVar = 'ACTLOG_SELFTEST';

/// Legacy self-test env var name (still honored; the new name wins).
const String kLegacySelfTestEnvVar = 'PRACTILOG_SELFTEST';

/// 自检报告文件名（写在应用支持目录）。
const String kSelfTestReportName = 'actlog_selftest.log';

/// 临时自检库文件名（跑完即删，绝不碰用户的真实库）。
const String kSelfTestScratchDbName = 'actlog_selftest.db';

/// 是否要跑自检。
///
/// D1 原型是「启动即自检」，正式工程改成**可控开关**：
/// 命令行 `--selftest`（或 `--selftest=1`），或环境变量 `ACTLOG_SELFTEST=1`。
/// 默认启动**不跑**任何自检逻辑。
bool selftestRequested(List<String> args, {Map<String, String>? environment}) {
  for (final arg in args) {
    if (arg == '--selftest' || arg.startsWith('--selftest=')) return true;
  }
  final env = environment ?? Platform.environment;
  for (final name in <String>[kSelfTestEnvVar, kLegacySelfTestEnvVar]) {
    final raw = env[name];
    if (raw == null) continue;
    final value = raw.trim().toLowerCase();
    if (value == '1' || value == 'true' || value == 'yes') return true;
  }
  return false;
}

/// 一条自检结论。
final class _Check {
  _Check(this.name, this.ok, this.detail);

  final String name;
  final bool ok;
  final String detail;
}

/// 只用来「听」一次窗口关闭事件的自检探针。
class _CloseProbe extends WindowListener {
  _CloseProbe(this.onClose);

  final void Function() onClose;

  @override
  void onWindowClose() => onClose();
}

/// 今天的日期（YYYY-MM-DD）。
String _today() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

/// 跑一遍正式工程自检，写报告文件，返回进程退出码（0 = 全通过）。
///
/// 自检**不动用户的真实库**：真实库只做一次只读查询（证明能打开、能迁移），
/// 写读、软删除隔离、设置往返都在临时库里跑，跑完删掉临时库。
///
/// 报告是**增量落盘**的：每完成一条检查就写一次文件。所以即使最后一条检查
/// （关窗拦截）把进程带崩了，磁盘上的报告仍然能说明「跑到哪一步、卡在哪」。
Future<int> runSelfTest({
  required Directory supportDir,
  required File dbFile,
}) async {
  final checks = <_Check>[];
  final scratch = File(p.join(supportDir.path, kSelfTestScratchDbName));
  final reportFile = File(p.join(supportDir.path, kSelfTestReportName));
  final header = StringBuffer()
    ..writeln('actlog selftest ${DateTime.now().toIso8601String()}')
    ..writeln('db=${dbFile.path}')
    ..writeln('scratch=${scratch.path}');

  /// 增量落盘报告。result 为 null 表示「还在跑」。
  void flush({String? result}) {
    final buffer = StringBuffer()
      ..write(header.toString());
    for (final check in checks) {
      buffer.writeln('${check.ok ? 'OK  ' : 'FAIL'} ${check.name} ${check.detail}');
    }
    if (result == null) {
      buffer.writeln('IN PROGRESS (${checks.length} checks done so far)');
    } else {
      buffer.writeln('RESULT $result');
    }
    try {
      reportFile.writeAsStringSync(buffer.toString(), flush: true);
    } catch (_) {
      // 报告写不进去也要把结论打到 stdout。
    }
  }

  void add(_Check check) {
    checks.add(check);
    flush();
  }

  // 1) 真实库能打开（并完成迁移）。
  try {
    final db = openActLogDatabase(dbFile);
    try {
      final repos = ActLogRepositories(db, deviceId: 'selftest');
      final rows = await repos.planItem.listByDate(_today());
      add(_Check('real_db_open', true, 'rows=${rows.length}'));
    } finally {
      await db.close();
    }
  } catch (error) {
    add(_Check('real_db_open', false, '$error'));
  }

  // 2) 临时库：迁移 + 仓储读写 + 软删除隔离 + 设置往返。
  try {
    _deleteDbFiles(scratch);
    final db = openActLogDatabase(scratch);
    try {
      final repos = ActLogRepositories(db, deviceId: 'selftest');
      final date = _today();

      await repos.dayLog.ensureByDate(date);
      add(_Check('scratch_migration', true, 'day_log ok'));

      final itemId = await repos.planItem.create(date: date, title: 'selftest');
      final items = await repos.planItem.listByDate(date);
      add(
        _Check(
          'plan_item_write_read',
          items.any((item) => item.id == itemId),
          'rows=${items.length}',
        ),
      );

      final habitId = await repos.habit.create(
        name: 'selftest-habit',
        startDate: date,
      );
      await repos.habit.upsertCheckin(habitId: habitId, date: date);
      final checkin = await repos.habit.findCheckin(habitId, date);
      add(
        _Check('habit_checkin_write_read', checkin != null, 'status=${checkin?.status}'),
      );

      await repos.planItem.softDelete(itemId);
      final afterDelete = await repos.planItem.listByDate(date);
      final checkinAfter = await repos.habit.findCheckin(habitId, date);
      add(
        _Check(
          'soft_delete_isolation',
          !afterDelete.any((item) => item.id == itemId) && checkinAfter != null,
          'plan_rows=${afterDelete.length} checkin_kept=${checkinAfter != null}',
        ),
      );

      final previousMode = await repos.settings.priorityDisplayMode();
      await repos.settings.setPriorityDisplayMode(PriorityDisplayMode.abc);
      final currentMode = await repos.settings.priorityDisplayMode();
      await repos.settings.setPriorityDisplayMode(previousMode);
      add(
        _Check(
          'settings_roundtrip',
          currentMode == PriorityDisplayMode.abc,
          'mode=$currentMode restored=$previousMode',
        ),
      );
    } finally {
      await db.close();
    }
  } catch (error) {
    add(_Check('scratch_db', false, '$error'));
  }

  // 3) 窗口标题（UTF-8 中文，走 Dart 侧 setTitle）。
  try {
    await windowManager
        .ensureInitialized()
        .timeout(const Duration(seconds: 10));
    await windowManager.setTitle(kAppTitle).timeout(const Duration(seconds: 10));
    final title = await windowManager
        .getTitle()
        .timeout(const Duration(seconds: 10));
    add(_Check('window_title_utf8', title == kAppTitle, 'title="$title"'));
  } catch (error) {
    add(_Check('window_title_utf8', false, '$error'));
  }

  // 4) 托盘图标与菜单能否真正建立。
  //
  // 这一条是「托盘 ↔ 窗口互斥」的前置条件：托盘建不起来时不能拦截关窗，
  // 否则用户点了关闭按钮就既看不到窗口、也没有托盘可点，进程会变成僵尸。
  try {
    await trayManager.setIcon(kTrayIconAsset).timeout(const Duration(seconds: 10));
    await trayManager.setToolTip(kAppTitle).timeout(const Duration(seconds: 10));
    await trayManager
        .setContextMenu(
          Menu(
            items: [
              MenuItem(
                key: kTrayKeyShow,
                label: '显示窗口',
                onClick: (_) {},
              ),
              MenuItem(
                key: kTrayKeyHide,
                label: '隐藏到托盘',
                onClick: (_) {},
              ),
              MenuItem(
                key: kTrayKeyQuit,
                label: '退出',
                onClick: (_) {},
              ),
            ],
          ),
        )
        .timeout(const Duration(seconds: 10));
    add(_Check('tray_setup', true, 'icon+tooltip+menu ok'));
    try {
      await trayManager.destroy();
    } catch (_) {
      // 自检结束前销毁托盘，失败也无所谓（进程马上退出）。
    }
  } catch (error) {
    add(_Check('tray_setup', false, '$error'));
  }

  // 5) 窗口显隐往返：托盘 ↔ 窗口互斥的两个基础动作（隐藏 / 再显示）。
  try {
    await windowManager.ensureInitialized();
    final before = await windowManager.isVisible();
    await windowManager.hide();
    final hidden = await windowManager.isVisible();
    await windowManager.show();
    final shown = await windowManager.isVisible();
    add(
      _Check(
        'window_visibility',
        !hidden && shown,
        'before=$before hidden=$hidden shown=$shown',
      ),
    );
  } catch (error) {
    add(_Check('window_visibility', false, '$error'));
  }

  // 6) 关窗拦截：setPreventClose(true) 之后 close() 应当被取消，
  // 并且 onWindowClose 应当被回调。
  //
  // 这是**最后**一条检查，因为它有可能把进程带崩（拦截不生效时窗口会被
  // 真正关掉）。报告是增量落盘的，所以崩了也能看出来崩在哪儿。
  try {
    final closed = Completer<bool>();
    windowManager.addListener(_CloseProbe(() {
      if (!closed.isCompleted) closed.complete(true);
    }));
    await windowManager.setPreventClose(true);
    final prevent = await windowManager.isPreventClose();
    await windowManager.close();
    final fired = await closed.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
    add(
      _Check(
        'prevent_close',
        prevent && fired,
        'preventClose=$prevent onWindowClose=$fired',
      ),
    );
    await windowManager.setPreventClose(false);
  } catch (error) {
    add(_Check('prevent_close', false, '$error'));
  }

  _deleteDbFiles(scratch);

  final passed = checks.where((check) => check.ok).length;
  final allOk = passed == checks.length;
  final result = '${allOk ? 'PASS' : 'FAIL'} ($passed/${checks.length})';
  flush(result: result);

  final report = reportFile.existsSync() ? reportFile.readAsStringSync() : '';
  stdout.write(report);
  return allOk ? 0 : 1;
}

/// 删掉 SQLite 的主文件与 WAL 附属文件。
void _deleteDbFiles(File file) {
  for (final path in [file.path, '${file.path}-wal', '${file.path}-shm']) {
    final target = File(path);
    if (target.existsSync()) {
      try {
        target.deleteSync();
      } catch (_) {
        // 文件被占用就留着，下一次自检会覆盖。
      }
    }
  }
}
