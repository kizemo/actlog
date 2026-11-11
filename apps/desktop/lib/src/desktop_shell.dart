// window_manager / tray_manager 的 0.5.x 兼容 API（`/legacy.dart`）整体标记为
// deprecated，官方定位是「给存量应用用的桥」，未来会移除。
// 这里统一用桥接 API：P1 只需要「标题 / 显隐 / 托盘菜单」这几件事，
// 桥接 API 的语义与 0.5.x 完全一致，迁移到新原生 API 留到 P2 统一做。
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/legacy.dart';

import 'widgets/shell/app_top_bar.dart';

/// 窗口标题（UTF-8 中文）。
///
/// 标题走 Dart 侧 `windowManager.setTitle`，**不**在 C++ 里写中文：
/// Flutter Windows 模板的 `main.cpp` 没有加 `/utf-8`，中文源码会按本地代码页编译。
const String kAppTitle = '知行日志 actlog';

/// 托盘图标资源路径（必须在 pubspec.yaml 的 `assets` 中声明）。
const String kTrayIconAsset = 'assets/icon.png';

/// 启动日志文件名（追加写，写在应用支持目录）。
///
/// 启动链路（标题 → 窗口选项 → 显示 → 托盘 → 拦截关窗）里任何一步失败，
/// 在 GUI 程序里都是**看不见**的（没有控制台、异常也不会弹窗）。
/// 这个日志是唯一的现场证据，也是冒烟脚本断言的对象。
const String kStartupLogName = 'actlog_startup.log';

/// 托盘菜单项：显示窗口。
const String kTrayKeyShow = 'show';

/// 托盘菜单项：隐藏到托盘。
const String kTrayKeyHide = 'hide';

/// 托盘菜单项：退出进程。
const String kTrayKeyQuit = 'quit';

/// 与 runner（C++）通信的通道：让 runner 把 WM_CLOSE 变成「隐藏到托盘」。
const MethodChannel kWindowChannel = MethodChannel('actlog/window');

/// 托盘是否已就绪。
///
/// 托盘没起来时**不能**拦截窗口关闭 —— 否则用户点关闭按钮后既看不到窗口，
/// 也没有托盘可点，进程就成了既关不掉又看不见的僵尸。
bool _trayReady = false;

/// 窗口是否最大化 —— 顶栏「最大化 / 还原」图标的唯一真源。
///
/// 放在模块级而不是 `ShellHost` 里：状态的真身在原生窗口，Dart 侧只是镜像。
/// 初值由 [setupDesktopShell] 用 `isMaximized()` 回填，之后靠窗口监听器
/// （`onWindowMaximize` / `onWindowUnmaximize`）跟进 —— 用户双击系统区域、
/// 拖出边角、Win+↑ 都可能改变它，只认按钮点击会画错。
final ValueNotifier<bool> windowMaximized = ValueNotifier<bool>(false);

/// 启动日志的串行链。
///
/// 日志是并发写的：托盘回调里的写没有 await，和别的写同时打开同一个追加文件
/// 会互相覆盖（两个句柄都 seek 到同一个末尾）。串起来就彻底没有这个竞态。
Future<void> _logChain = Future<void>.value();

/// 启动链路日志（没有目录就丢弃）。
Future<void> _logStartup(Directory? dir, String line) {
  if (dir == null) return Future<void>.value();
  _logChain = _logChain.then((_) async {
    try {
      final file = File(p.join(dir.path, kStartupLogName));
      await file.writeAsString(
        '${DateTime.now().toIso8601String()} $line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // 日志写不进去也不能影响启动。
    }
  });
  return _logChain;
}

/// 记录一行启动日志（供入口在数据目录定下来后立刻落证据）。
///
/// 存在的理由：真机需要一条**不依赖 stdout** 的证据，说明数据目录到底落在哪个档位
/// （安装目录 / ProgramData / 兜底）。启动日志就写在数据目录里，是最直接的证据；
/// 没有它就只能靠「目录碰巧存在」来猜。
Future<void> logStartupLine(Directory? dir, String line) => _logStartup(dir, line);

/// 启动窗口与托盘（正常启动路径）。
///
/// 托盘 ↔ 窗口互斥：
/// * 窗口关闭按钮 → 隐藏到托盘，进程继续存活；
/// * 左键点托盘图标 → 窗口在「显示 / 隐藏」之间切换；
/// * 右键点托盘图标 → 菜单（显示窗口 / 隐藏到托盘 / 退出）。
///
/// **每一步都是独立兜底的**：任何一步失败都不能连累后面的步骤。
/// 特别是「托盘」和「关窗隐藏」必须真的执行到 —— 它们不是可选装饰，
/// 而是「关窗隐藏到托盘」这条产品行为的开关。
Future<void> setupDesktopShell({Directory? supportDir}) async {
  await _logStartup(supportDir, 'shell.start');

  try {
    await windowManager.ensureInitialized();
  } catch (error) {
    await _logStartup(supportDir, 'ensureInitialized FAIL $error');
  }

  try {
    await windowManager.setTitle(kAppTitle);
    await _logStartup(supportDir, 'title ok');
  } catch (error) {
    await _logStartup(supportDir, 'title FAIL $error');
  }

  windowManager.addListener(_ShellWindowListener());

  // 顶栏图标的初值：窗口可能一启动就是最大化（上次会话留下的几何）。
  try {
    windowMaximized.value = await windowManager.isMaximized();
    // 回读值必须落盘：镜像初值错了，顶栏图标从第一帧就画反。
    await _logStartup(supportDir, 'isMaximized read-back ${windowMaximized.value}');
  } catch (error) {
    await _logStartup(supportDir, 'isMaximized FAIL $error');
  }

  const options = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(960, 640),
    center: true,
    title: kAppTitle,
  );

  // 窗口选项逐项应用：某一项失败不能影响其余项，更不能影响托盘初始化。
  await _applyWindowOptions(options, supportDir);

  // 原生窗口就绪：把最大化钮的屏幕矩形登记给系统（Win11 悬停飞出 snap layouts）。
  // 放在这里而不是 `main()` 里，是为了「窗口真的起来了」之后再接线。
  enableNativeMaximizeButtonBounds();

  try {
    await windowManager.show();
    await windowManager.focus();
    await _logStartup(supportDir, 'window shown');
  } catch (error) {
    await _logStartup(supportDir, 'show FAIL $error');
  }

  // 托盘必须在窗口起来之后建立：托盘建不起来时不能拦截关窗。
  final trayError = await setupTray(log: (line) => _logStartup(supportDir, line));
  _trayReady = trayError == null;
  if (_trayReady) {
    await _armHideOnClose(supportDir);
  } else {
    await _logStartup(supportDir, 'hide on close skipped (no tray)');
  }
}

/// 让 runner 把 WM_CLOSE 变成「隐藏到托盘」。
///
/// 插件层的 prevent close 只能拦插件自己发起的关闭；Windows 的关闭按钮发的是
/// WM_CLOSE，它会走到 DefWindowProc → 销毁窗口 → 进程退出。所以这一步必须
/// 在 runner 层做（见 `windows/runner/flutter_window.cpp`）。
Future<void> _armHideOnClose(Directory? supportDir) async {
  try {
    await kWindowChannel.invokeMethod<bool>('setHideOnClose');
    await _logStartup(supportDir, 'hide on close armed');
  } catch (error) {
    await _logStartup(supportDir, 'setHideOnClose FAIL $error');
  }
  try {
    // 插件层的 prevent close 仍然保留：它管的是 Dart 侧发起的 close()。
    await windowManager.setPreventClose(true);
    await _logStartup(supportDir, 'preventClose on');
  } catch (error) {
    await _logStartup(supportDir, 'preventClose FAIL $error');
  }
}

/// 逐项应用窗口选项（单项失败只记录，不影响其它项）。
Future<void> _applyWindowOptions(
  WindowOptions options,
  Directory? supportDir,
) async {
  Future<void> step(String name, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      await _logStartup(supportDir, 'option $name FAIL $error');
    }
  }

  await step('size', () => windowManager.setSize(options.size!));
  await step('minimumSize', () => windowManager.setMinimumSize(options.minimumSize!));
  await step('center', () => windowManager.setAlignment(Alignment.center));
  await step('title', () => windowManager.setTitle(options.title!));
  await _applyTitleBarStyle(supportDir);
}

/// 去掉原生标题栏，把顶部那条非客户区让给内容（顶栏自绘）。
///
/// 原生层仍保留 WS_CAPTION / WS_THICKFRAME 与 DWM 边框 ⇒ 贴边缩放、任务栏照旧，
/// 只有那条 32px 的标题带被让出来。
///
/// **为什么要自检**：插件的 `setTitleBarStyle` 在原生目标未就绪时直接 `return`
/// （`_target == null` 分支），既不抛异常也不留痕 ⇒ 真机表现是「双标题条」，
/// 排查只能靠像素。这里用同一套 `_target` 的读接口回探：目标没就绪时
/// `getSize()` 退化成 `Size.zero`（窗口即便还没 show 也是有尺寸的），
/// 据此把「调用被丢弃」写成一行日志，和「生效」区分开。
Future<void> _applyTitleBarStyle(Directory? supportDir) async {
  try {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  } catch (error) {
    await _logStartup(supportDir, 'titleBarStyle FAIL $error');
    return;
  }
  try {
    final Size size = await windowManager.getSize();
    if (size.isEmpty) {
      await _logStartup(
        supportDir,
        'titleBarStyle NOT APPLIED (native target not ready: probe getSize=0x0)',
      );
      return;
    }
    await _logStartup(
      supportDir,
      'titleBarStyle hidden ok (probe size=${size.width.round()}x${size.height.round()})',
    );
  } catch (error) {
    await _logStartup(supportDir, 'titleBarStyle probe FAIL $error');
  }
}

/// 建立托盘图标与菜单。返回 null 表示成功，返回异常表示失败。
Future<Object?> setupTray({void Function(String line)? log}) async {
  void write(String line) => log?.call(line);
  try {
    await trayManager.setIcon(kTrayIconAsset);
    await trayManager.setToolTip(kAppTitle);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: kTrayKeyShow,
            label: '显示窗口',
            onClick: (_) {
              write('tray menu show');
              showMainWindow();
            },
          ),
          MenuItem(
            key: kTrayKeyHide,
            label: '隐藏到托盘',
            onClick: (_) {
              write('tray menu hide');
              hideMainWindow();
            },
          ),
          MenuItem(
            key: kTrayKeyQuit,
            label: '退出',
            onClick: (_) {
              write('tray menu quit');
              quitApp();
            },
          ),
        ],
      ),
    );
    trayManager.addListener(_ShellTrayListener(write));
    write('tray ready');
    return null;
  } catch (error) {
    write('tray FAIL $error');
    return error;
  }
}

/// 显示窗口并聚焦。
Future<void> showMainWindow() async {
  await windowManager.show();
  try {
    // runner 侧的显示：原生 show 失败时（窗口已被隐藏且没有任务栏入口），
    // 这一手能保证窗口一定回到桌面上。
    await kWindowChannel.invokeMethod<bool>('showWindow');
  } catch (_) {
    // 通道不可用就只靠插件。
  }
  await windowManager.focus();
}

/// 隐藏窗口（进程继续存活）。
Future<void> hideMainWindow() async {
  await windowManager.hide();
}

/// 按当前可见性切换窗口。
Future<void> toggleMainWindow() async {
  final visible = await windowManager.isVisible();
  if (visible) {
    await hideMainWindow();
  } else {
    await showMainWindow();
  }
}

/// 彻底退出进程：先销毁托盘图标，再关窗口。
Future<void> quitApp() async {
  try {
    await trayManager.destroy();
  } catch (_) {
    // 托盘本来就没起来，忽略。
  }
  try {
    await windowManager.destroy().timeout(const Duration(seconds: 3));
  } catch (_) {
    // 关不掉也要退出，否则用户点了「退出」程序还在。
  }
  exit(0);
}

/// 最小化窗口（顶栏左钮）。
Future<void> minimizeMainWindow() => windowManager.minimize();

/// 最大化 / 还原切换（顶栏中钮与顶栏空白区双击共用）。
///
/// 以 `isMaximized()` 为准而不是镜像状态：镜像可能因外部操作（系统菜单、
/// 拖拽复位）落后一帧，toggle 一旦按错的初值走，用户点一次没反应。
Future<void> toggleMaximizeMainWindow() async {
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
    windowMaximized.value = false;
  } else {
    await windowManager.maximize();
    windowMaximized.value = true;
  }
}

/// 关闭窗口（顶栏右钮）。
///
/// 走 `windowManager.close()` 进**既有**的「隐藏到托盘」链：
/// `setPreventClose(true)` 触发 `_ShellWindowListener.onWindowClose` ⇒ `hide()`。
/// 不直接调 `hide()`，也不绕开 `_trayReady` 兜底。
Future<void> closeMainWindow() => windowManager.close();

/// 按下顶栏空白区 ⇒ 拖动窗口。
Future<void> startWindowDrag() => windowManager.startDragging();

class _ShellWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    if (!_trayReady) {
      // 没有托盘兜底时，让关闭按钮按默认行为退出进程。
      return;
    }
    // 关闭按钮 = 隐藏到托盘；退出请走托盘菜单。
    windowManager.hide();
  }

  @override
  void onWindowMaximize() {
    windowMaximized.value = true;
  }

  @override
  void onWindowUnmaximize() {
    windowMaximized.value = false;
  }
}

/// 托盘事件监听。
///
/// Windows 上原生只发「整体点击」事件（`TrayIconClickedEvent` 等），插件把它
/// 重放成 down + up，所以左键切换挂在 [onTrayIconMouseDown] 上是有效的。
class _ShellTrayListener extends TrayListener {
  _ShellTrayListener(this._log);

  /// 启动日志写入器（与启动链路同一把串行锁）。
  final void Function(String line) _log;

  @override
  void onTrayIconMouseDown() {
    _log('tray click');
    toggleMainWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Windows 上原生默认 contextMenuTrigger = None，菜单不会自动弹出：
    // tray_manager 只在 Linux 分支里把 trigger 设成 rightClicked，
    // cnativeapi 的 tray_icon.h 也写明要显式调 OpenContextMenu()。
    // 所以这里必须由 Dart 侧主动弹菜单。
    _log('tray right click');
    unawaited(trayManager.popUpContextMenu());
  }
}
