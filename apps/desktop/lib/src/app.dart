import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'desktop_shell.dart';
import 'pages/calendar_page.dart';
import 'pages/habits_page.dart';
import 'pages/today_page.dart';
import 'pages/todo_pool_page.dart';
import 'theme/app_theme.dart';
import 'theme/density_profile.dart';
import 'widgets/habit_quick_dialog.dart';
import 'widgets/quick_todo_dialog.dart';
import 'widgets/recurring_rail_panel.dart';
import 'widgets/recurring_task_dialog.dart';
import 'widgets/shell/app_top_bar.dart';
import 'widgets/shell/ledger_shell.dart';
import 'widgets/shell/tool_rail.dart';
import 'widgets/timeline/todo_rail_panel.dart';

/// 解析系统字号缩放（裁定 B）。
///
/// 真源是环境变量 `ACTLOG_TEXT_SCALE`：
/// * 未设置 ⇒ `1.0`；
/// * 非数字 / `NaN` / `Infinity` / `<= 0` ⇒ 回落 `1.0`（宁可原尺寸，也不把
///   整个界面缩成看不见或撑爆）；
/// * 合法值原样返回（如 `2` ⇒ 200%）。
///
/// 只影响本进程的 `MediaQuery.textScaler`，**不读写用户的系统环境**。
double resolveTextScale(String? raw) {
  if (raw == null) {
    return 1.0;
  }
  final parsed = double.tryParse(raw.trim());
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    return 1.0;
  }
  return parsed;
}

/// New text-scale env var name.
const String kTextScaleEnvVar = 'ACTLOG_TEXT_SCALE';

/// Legacy text-scale env var name (still honored; the new name wins).
const String kLegacyTextScaleEnvVar = 'PRACTILOG_TEXT_SCALE';

/// Resolve the text scale from the environment: new name first, legacy fallback.
double resolveTextScaleFromEnvironment(Map<String, String> environment) =>
    resolveTextScale(
      environment[kTextScaleEnvVar] ?? environment[kLegacyTextScaleEnvVar],
    );

/// 应用根组件。
class ActLogApp extends StatefulWidget {
  /// 创建应用根组件。
  const ActLogApp({super.key, this.textScale = 1.0});

  /// 全局字号缩放（1.0 = 原型基准 100%）。
  final double textScale;

  @override
  State<ActLogApp> createState() => _ActLogAppState();
}

class _ActLogAppState extends State<ActLogApp> {
  /// 兜底值：非有限 / 非正数一律按 100% 处理，避免把整棵树缩没了。
  double get _scale => widget.textScale.isFinite && widget.textScale > 0
      ? widget.textScale
      : 1.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '知行日志',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(DensityProfile.comfortable),
      darkTheme: AppTheme.dark(DensityProfile.comfortable),
      themeMode: ThemeMode.light,
      // 裁定 B：字号缩放只施加在这一层，页面代码一律不感知。
      builder: (BuildContext context, Widget? child) {
        final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(_scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const ShellHost(),
      routes: <String, WidgetBuilder>{
        '/todo': (_) => const ShellHost(initialNavId: 'inbox'),
        '/calendar': (_) => const ShellHost(initialNavId: 'calendar'),
      },
    );
  }
}

/// 壳宿主：唯一持有 [LedgerShell] 的地方。
///
/// 自绘顶栏 [AppTopBar] 挂在本组件里、`LedgerShell` **之上**（不是塞进壳内部），
/// 窗口动作全部转给 `desktop_shell.dart` 的模块级函数，壳本身完全不感知窗口。
///
/// 四个页面（今日 / 待办池 / 习惯 / 日历）都是**内容体**，不带 `Scaffold`；
/// 导航点击只切本组件的 `_nav` 状态，不做路由 push —— 否则每点一次就叠一层壳。
/// `/todo` 与 `/calendar` 保留为**深链入口**：它们各自创建一个带初始导航项的
/// 宿主，供测试与外部深链使用。
class ShellHost extends StatefulWidget {
  /// 创建壳宿主。
  const ShellHost({super.key, this.initialNavId = kTodayNavId});

  /// 初始导航项 id。
  final String initialNavId;

  /// 今日页导航 id。
  static const String kTodayNavId = 'today';

  @override
  State<ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<ShellHost> {
  late String _nav = widget.initialNavId;

  /// 壳级焦点节点：壳自己持焦点 ⇒ `Ctrl+1…4` 在任何页都收得到键。
  ///
  /// `Shortcuts` 靠焦点节点收键：焦点掉回根 scope 时事件不会冒泡下来，
  /// 快捷键就成了死键。切页时把焦点收回这里，键条上的承诺才始终成立。
  final FocusNode _shellFocus = FocusNode(debugLabel: 'shell-host');

  @override
  void dispose() {
    _shellFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      // 键条最后一条「切页」的真身：只认四个有落点的导航项。
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _NavIntent(ShellHost.kTodayNavId),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _NavIntent('inbox'),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _NavIntent('habits'),
        SingleActivator(LogicalKeyboardKey.digit4, control: true):
            _NavIntent('calendar'),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavIntent: CallbackAction<_NavIntent>(
            onInvoke: (_NavIntent intent) => _go(intent.navId),
          ),
        },
        child: Focus(
          focusNode: _shellFocus,
          autofocus: true,
          skipTraversal: true,
          // 顶栏挂在**壳之上**，不进 `LedgerShell` 内部：壳的骨架纪律
          // （NavRail / LedgerPaper / ToolRail / dock / KeyBar 的层级）不许回退。
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTopBar(
                isMaximized: windowMaximized,
                onMinimize: minimizeMainWindow,
                onToggleMaximize: toggleMaximizeMainWindow,
                onClose: closeMainWindow,
                onDragStart: startWindowDrag,
              ),
              Expanded(
                child: LedgerShell(
                  currentNavId: _nav,
                  onNavSelected: _onNavSelected,
                  railPanels: _railPanels(context),
                  content: _content(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 切页（`Ctrl+1…4`）。
  ///
  /// 已经在目标页 ⇒ **无动作**（不报错、不回跳第一页）。
  void _go(String id) {
    if (id == _nav) {
      return;
    }
    setState(() => _nav = id);
    // 切页会把上一页的焦点节点带走 ⇒ 焦点掉回根 scope，之后的快捷键就收不到。
    // 下一帧把焦点收回壳节点，保证「切完还能继续切」。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _shellFocus.requestFocus();
      }
    });
  }

  /// 右轨面板：只放真实数据。
  ///
  /// 「快捷键」面板由 [LedgerShell] 自动追加，这里**不重复注入**。
  /// 今日页右轨三块，顺序即展示顺序（清单见 [todayRailPanels]）。
  /// 其余页面不挂额外面板：信息密度已经在正文里，右轨放空比塞假数据好。
  List<ShellRailPanel> _railPanels(BuildContext context) {
    if (_nav != ShellHost.kTodayNavId) {
      return const <ShellRailPanel>[];
    }
    return todayRailPanels(context);
  }

  Widget _content() {
    return switch (_nav) {
      'inbox' => const TodoPoolPage(),
      'habits' => const HabitsPage(),
      // 日历页在壳内没有可 pop 的宿主栈，点格子后靠回调回今日。
      'calendar' => CalendarPage(
        onDayPicked: () => setState(() => _nav = ShellHost.kTodayNavId),
      ),
      // 项目 / 设置：[未覆盖] 原因：本轮未实现这两个页面。
      // 这两项在 `kShellNavItems` 里 `enabled: false`，用户点不到，
      // 也不会走到这个分支；此处保留今日页作为唯一合法兜底。
      _ => const TodayPage(),
    };
  }

  void _onNavSelected(String id) {
    if (id == _nav) {
      return;
    }
    // 只有今日 / 待办池 / 习惯 / 日历有真实落点。项目 / 设置两项在
    // `kShellNavItems` 里已 `enabled: false`（无 InkWell、不可 Tab），
    // 因此不会进入本回调 —— 这里不为它们造任何假落点。
    setState(() => _nav = id);
  }
}

/// 「切页」意图（`Ctrl+1…4`，键条最后一条）。
///
/// 只认四个有落点的导航项：今日 / 待办池 / 习惯 / 日历。项目 / 设置两项
/// 在 `kShellNavItems` 里是 `enabled: false`（无落点）⇒ 不实现
/// `Ctrl+5/6`，也不把它们写进键条（留没实现的提示就是假提示）。
class _NavIntent extends Intent {
  const _NavIntent(this.navId);

  /// 目标导航项 id（`today` / `inbox` / `habits` / `calendar`）。
  final String navId;
}

/// 今日页右轨的三块面板（**顺序即展示顺序**）。
///
/// 抽成顶层函数是为了让 widget test 能在不启动窗口壳的前提下按**生产同一份
/// 清单**渲染右轨：`ShellHost` 依赖 `window_manager`，测试进程里起不来。
/// `ShellHost._railPanels()` 只是在这份清单外加了「非今日页即空」的判断。
///
/// 前三块各带一枚 `＋` 动作位（`添加待办` / `添加习惯` / `添加循环任务`）：
/// * 待办 ⇒ 复用既有的 [showQuickTodoDialog]（不另造轮子）；
/// * 习惯 ⇒ [showHabitQuickDialog]；
/// * 循环任务 ⇒ [showRecurringTaskDialog]（保存后立刻幂等物化当前选中日）。
/// 末块「闭环提示」不动，也不带动作位。
List<ShellRailPanel> todayRailPanels(BuildContext context) {
  return <ShellRailPanel>[
    ShellRailPanel(
      title: '待办列表',
      trailing: RailAddButton(
        key: const ValueKey<String>('rail-add-todo'),
        label: '添加待办',
        onPressed: () => showQuickTodoDialog(context),
      ),
      child: const TodoRailPanel(),
    ),
    ShellRailPanel(
      title: '习惯速览',
      trailing: RailAddButton(
        key: const ValueKey<String>('rail-add-habit'),
        label: '添加习惯',
        onPressed: () => showHabitQuickDialog(context),
      ),
      child: const HabitOverviewPanel(),
    ),
    ShellRailPanel(
      title: '循环任务',
      trailing: RailAddButton(
        key: const ValueKey<String>('rail-add-recurring'),
        label: '添加循环任务',
        onPressed: () => showRecurringTaskDialog(context),
      ),
      child: const RecurringRailPanel(),
    ),
    const ShellRailPanel(title: '闭环提示', child: LoopHintPanel()),
  ];
}