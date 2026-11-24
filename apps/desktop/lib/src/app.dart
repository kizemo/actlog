import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_shell.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_scope.dart';
import 'pages/about_page.dart';
import 'pages/calendar_page.dart';
import 'pages/habits_page.dart';
import 'pages/projects_page.dart';
import 'pages/settings_page.dart';
import 'pages/today_page.dart';
import 'pages/todo_pool_page.dart';
import 'providers.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

import 'widgets/date_bar.dart';
import 'widgets/habit_quick_dialog.dart';
import 'widgets/quick_todo_dialog.dart';
import 'widgets/recurring_rail_panel.dart';
import 'widgets/recurring_task_dialog.dart';
import 'widgets/shell/app_top_bar.dart';
import 'widgets/shell/key_bar.dart';
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
  const ActLogApp({
    super.key,
    this.textScale = 1.0,
    this.home,
    this.initialLanguage,
  });

  /// 可选根页面（测试缝）。`null` ⇒ 真壳 [ShellHost]；测试进程里起不来
  /// `window_manager`，因此允许直接注入一个页面断言应用级行为。
  final Widget? home;

  /// 启动时已解析出的界面语言（`main.dart` 在 `runApp()` 之前读库得到）。
  ///
  /// 只用于对齐 [State] 里「已经回写到原生外壳」的镜像值：首次标题 / 任务栏
  /// 名字的推送发生在 `main.dart`，这里不该再白推一次。`null` ⇒ 沿用出厂 zh。
  final AppLanguage? initialLanguage;

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

  /// 已经回写到原生外壳（窗口标题 / 托盘菜单）的语言。
  ///
  /// 初值取 `widget.initialLanguage`：`main.dart` 已在 `runApp()` 之前解析过持久化
  /// 语言，并按它推送过首次标题 / 任务栏名（见 `setupDesktopShell`）。不从初值
  /// 对齐的话，en 态会在第一帧后再补一次 zh→en 的无谓往返。
  late AppLanguage _shellLanguage;

  @override
  void initState() {
    super.initState();
    _shellLanguage = widget.initialLanguage ?? AppLanguage.zh;
  }

  @override
  Widget build(BuildContext context) {
    // 没有 `ProviderScope` 祖先时（部分既有测试直接 pump `ActLogApp`），
    // 不能 `ref.watch`，否则整棵测试树崩在 `ProviderScope` 查找上。
    // 此时按出厂默认偏好渲染：接线照旧成立，只是读不到用户设置。
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } on Object {
      container = null;
    }
    if (container == null) {
      return _buildApp(AppPreferences.defaults);
    }
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) =>
          _buildApp(ref.watch(currentPreferencesProvider)),
    );
  }

  /// 用一份具体偏好构建 `MaterialApp`（根组件唯一的主题 / 路由出口）。
  ///
  /// 不设 `MaterialApp.locale`：本波零新增依赖、没有 `flutter_localizations`，
  /// 把 `locale` 设成 `zh` 会让 Material 内建文案找不到本地化实现。语言切换
  /// 只作用于我们自己的 `AppLocalizations` 文案（设置页 / 关于页）。
  Widget _buildApp(AppPreferences prefs) {
    final AppLocalizations t = AppLocalizations.forLanguage(prefs.language);
    // 语言切换后窗口标题 / 托盘菜单也要跟上（产品决策 D-47-b）。启动时的首次
    // 推送在 `main.dart` 的 `setupDesktopShell`（那里有持久的语言与数据目录），
    // 这里只负责「运行中切语言」；post-frame 才碰原生插件，避免在 build 帧里
    // 改窗口。测试环境没有插件，`applyShellLanguage` 自己吞异常。
    if (_shellLanguage != prefs.language) {
      _shellLanguage = prefs.language;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(applyShellLanguage(prefs.language));
      });
    }
    return L10nScope(
      localizations: t,
      child: MaterialApp(
        title: t.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(prefs.density),
        darkTheme: AppTheme.dark(prefs.density),
        themeMode: prefs.themeMode,
        // 裁定 B：字号缩放只施加在这一层，页面代码一律不感知。
        builder: (BuildContext context, Widget? child) {
          final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(_scale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: widget.home ?? const ShellHost(),
        routes: <String, WidgetBuilder>{
          '/todo': (_) => const ShellHost(initialNavId: 'inbox'),
          '/calendar': (_) => const ShellHost(initialNavId: 'calendar'),
          '/settings': (_) => const ShellHost(initialNavId: 'settings'),
          '/about': (_) => const _AboutRoute(),
        },
      ),
    );
  }
}

/// 关于页的宿主：壳外的独立路由。
///
/// 关于页是**内容体**（不带 `Scaffold`，与四个既有页面同一纪律），深链
/// `/about` 需要一个给得出滚动视口、且带 `Material` 祖先的宿主。
class _AboutRoute extends StatelessWidget {
  const _AboutRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.paper,
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: AboutPage(),
      ),
    );
  }
}

/// 壳宿主：唯一持有 [LedgerShell] 的地方。
///
/// 自绘顶栏 [AppTopBar] 挂在本组件里、`LedgerShell` **之上**（不是塞进壳内部），
/// 窗口动作全部转给 `desktop_shell.dart` 的模块级函数，壳本身完全不感知窗口。
///
/// 五个页面（今日 / 待办池 / 习惯 / 日历 / 设置）都是**内容体**，不带
/// `Scaffold`；导航点击只切本组件的 `_nav` 状态，不做路由 push —— 否则每点
/// 一次就叠一层壳。
/// `/todo`、`/calendar`、`/settings`、`/about` 保留为**深链入口**：前三个各自
/// 创建一个带初始导航项的宿主，`/about` 走壳外的 `_AboutRoute`（关于页没有
/// 导航项，只在设置页与深链里可达）。
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
      // 键条最后两条「切页」的真身：只认有落点的导航项。
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _NavIntent(ShellHost.kTodayNavId),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _NavIntent('inbox'),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _NavIntent('habits'),
        SingleActivator(LogicalKeyboardKey.digit4, control: true):
            _NavIntent('calendar'),
        SingleActivator(LogicalKeyboardKey.digit5, control: true):
            _NavIntent('projects'),
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
                  pinnedHeader: _pinnedHeader(context),
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

  /// 吸顶头：只有今日页有日期条，其余页返回 `null`（不占位、不留空白）。
  ///
  /// 日期条原先长在 `TodayPage` 正文**里面**，等于坐在滚动区里 —— 往下翻方格
  /// 时间轴时它会跟着滚走，用户就失去了「现在看的是哪一天」这个锚点。
  /// 挂在壳的纸面头部后，它成为滚动区之外的列兄弟，结构性不可能滚走。
  ///
  /// Task 49：日期文字点开日期卡片选日，这里由宿主显式接线（弹层用壳层的
  /// context）；其余页面的 [DateBar] 走组件内置的同一条实现。
  Widget? _pinnedHeader(BuildContext context) {
    if (_nav != ShellHost.kTodayNavId) {
      return null;
    }
    return DateBar(onPickDate: (date) => openDatePicker(context, date));
  }

  Widget _content() {
    return switch (_nav) {
      'inbox' => const TodoPoolPage(),
      'habits' => const HabitsPage(),
      // 日历页在壳内没有可 pop 的宿主栈，点格子后靠回调回今日。
      'calendar' => CalendarPage(
        onDayPicked: () => setState(() => _nav = ShellHost.kTodayNavId),
      ),
      'settings' => const SettingsPage(),
      // 项目页内容体没有自己的宿主栈，点增量「查看原文」后由壳层回今日页。
      'projects' => ProjectsPage(
        onOpenDayLog: () => setState(() => _nav = ShellHost.kTodayNavId),
      ),
      _ => const TodayPage(),
    };
  }

  void _onNavSelected(String id) {
    if (id == _nav) {
      return;
    }
    // 今日 / 待办池 / 习惯 / 项目 / 日历 / 设置六项都有真实落点。
    setState(() => _nav = id);
  }
}

/// 「切页」意图（`Ctrl+1…5`，键条最后两条）。
///
/// 只认有落点的导航项：今日 / 待办池 / 习惯 / 日历 / 项目。设置页虽有落点，
/// 但键条与快捷键只承诺这五条 ⇒ 不实现 `Ctrl+6`（留没实现的提示就是假提示）。
class _NavIntent extends Intent {
  const _NavIntent(this.navId);

  /// 目标导航项 id（`today` / `inbox` / `habits` / `calendar` / `projects`）。
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
///
/// 口径（Task 61）：面板标题与动作位文案走 l10n（英文界面下这块右轨零中文）。
/// 文案表从 context 取（`L10nScope`）；取不到时回落中文态，理由与理由见
/// [shellLocalizationsOf]（既有测试直接构造这份清单、不套 `L10nScope`）。
List<ShellRailPanel> todayRailPanels(BuildContext context) {
  final AppLocalizations t = shellLocalizationsOf(context);
  return <ShellRailPanel>[
    ShellRailPanel(
      title: t.shellPanelTodoList,
      trailing: RailAddButton(
        key: const ValueKey<String>('rail-add-todo'),
        label: t.shellPanelAddTodo,
        onPressed: () => showQuickTodoDialog(context),
      ),
      child: const TodoRailPanel(),
    ),
    ShellRailPanel(
      title: t.shellPanelHabitOverview,
      trailing: RailAddButton(
        key: const ValueKey<String>('rail-add-habit'),
        label: t.shellPanelAddHabit,
        onPressed: () => showHabitQuickDialog(context),
      ),
      child: const HabitOverviewPanel(),
    ),
    ShellRailPanel(
      title: t.shellPanelRecurringTasks,
      trailing: RailAddButton(
        key: const ValueKey<String>('rail-add-recurring'),
        label: t.shellPanelAddRecurringTask,
        onPressed: () => showRecurringTaskDialog(context),
      ),
      child: const RecurringRailPanel(),
    ),
    ShellRailPanel(title: t.shellPanelLoopHint, child: const LoopHintPanel()),
  ];
}
