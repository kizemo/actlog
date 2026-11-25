import 'dart:convert';
import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'app_version.dart';
import 'data/goal_store.dart';
import 'l10n/app_localizations.dart';
import 'theme/density_profile.dart';
import 'widgets/timeline/slot_state.dart';
import 'widgets/timeline/timeline_store.dart';

/// 数据库实例；由 `main()` 用真实文件 override。
///
/// 不给默认实现，是因为「哪一天的数据」必须由启动时解析出的库路径决定，
/// 静默回落到临时库会让用户以为数据丢了。
final databaseProvider = Provider<ActLogDatabase>(
  (ref) => throw UnimplementedError('databaseProvider 必须在 main() 中被覆盖'),
);

/// P1 全部仓储的入口（dayLog / planItem / habit / settings）。
final repositoriesProvider = Provider<ActLogRepositories>(
  (ref) => ActLogRepositories(ref.watch(databaseProvider)),
);

/// 今天（本地时区的日历日，`yyyy-MM-dd`）。
///
/// 单独提出来是为了让测试能 override 成固定日期。
final todayProvider = Provider<String>((ref) => today());

/// 选中日期（本地时区的日历日，`yyyy-MM-dd`）。
///
/// 初值读 [todayProvider]，因此测试里 override `todayProvider` 依然生效；
/// 界面上的任何日期写入都只读这一个 provider（spec §13.3）。
final selectedDateProvider = StateProvider<String>(
  (ref) => ref.watch(todayProvider),
);

/// 当日日志；读取前先 `ensureByDate` 补建（幂等，不写库也不写 oplog）。
final dayLogProvider = StreamProvider<DayLogData?>((ref) async* {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(repositoriesProvider).dayLog;
  await repo.ensureByDate(date);
  yield* repo.watchByDate(date);
});

/// 当日计划条目（含习惯回填行），已按「收口沉底 + 优先级权重 + 创建时间」排好序。
final planItemsProvider = StreamProvider<List<PlanItemData>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(repositoriesProvider).planItem.watchByDate(date);
});

/// 已排期的待办（`todo.id` → 排期事实）。
///
/// 「已填时间」是**派生**事实（§0）：存在未删除的 `plan_item` 且
/// `source_todo_id = todo.id`。待办池用它显示只读徽标 `已排期 09:15`。
final slottedTodosProvider = FutureProvider<Map<String, SlottedTodo>>((ref) {
  return TimelineStore(ref.watch(repositoriesProvider)).slottedTodosAll();
});

/// 优先级展示模式（四象限 / ABC）。
final priorityDisplayModeProvider = FutureProvider<PriorityDisplayMode>(
  (ref) => ref.watch(repositoriesProvider).settings.priorityDisplayMode(),
);

/// 当日闭环统计（闭环环口径唯一实现处）。
final dayStatsProvider = Provider<DayStats>((ref) {
  final items =
      ref.watch(planItemsProvider).whenOrNull(data: (rows) => rows) ??
      const <PlanItemData>[];
  final log = ref.watch(dayLogProvider).whenOrNull(data: (row) => row);

  final hasReview =
      log != null &&
      (log.good.trim().isNotEmpty ||
          log.improve.trim().isNotEmpty ||
          log.learning.trim().isNotEmpty);
  final hasMood =
      log != null &&
      (log.moodFailed == 1 ||
          log.mood1 != null ||
          log.mood2 != null ||
          log.mood3 != null ||
          log.mood4 != null ||
          log.mood5 != null ||
          log.mood6 != null ||
          log.mood7 != null ||
          log.mood8 != null);

  return computeDayStats(
    items: items.map(
      (item) => PlanItemStat(
        status: item.status,
        hasResultNote: item.resultNote.trim().isNotEmpty,
      ),
    ),
    hasReview: hasReview,
    hasMood: hasMood,
  );
});

/// 某个月的日历摘要（月历用；一次查区间，禁止按格子 N+1）。
final calendarMonthProvider =
    FutureProvider.family<CalendarMonthSummary, String>((ref, month) async {
  final repos = ref.watch(repositoriesProvider);
  final todayIso = ref.watch(todayProvider);
  final parts = month.split('-');
  final first = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  final last = DateTime(first.year, first.month + 1, 0);
  final start = isoDate(first);
  final end = isoDate(last);

  final items = await repos.planItem.listRange(start, end);
  final checkins = await repos.habit.listCheckinsRange(start, end);
  final logs = await repos.dayLog.listRange(start, end);
  final habits = await repos.habit.listActive();

  final byDate = <String, CalendarDaySummary>{};
  for (var day = first;
      !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1)) {
    final date = isoDate(day);
    byDate[date] = CalendarDaySummary(
      date: date,
      future: date.compareTo(todayIso) > 0,
    );
  }

  for (final item in items) {
    final summary = byDate[item.date];
    if (summary == null || item.status == PlanStatus.cancelled.code) {
      continue;
    }
    byDate[item.date] = CalendarDaySummary(
      date: item.date,
      planDone:
          summary.planDone + (item.status == PlanStatus.done.code ? 1 : 0),
      planTotal: summary.planTotal + 1,
      habitDone: summary.habitDone,
      habitTotal: summary.habitTotal,
      moodAverage: summary.moodAverage,
      moodFailed: summary.moodFailed,
      future: summary.future,
    );
  }

  for (final checkin in checkins) {
    final summary = byDate[checkin.date];
    if (summary == null) {
      continue;
    }
    byDate[checkin.date] = CalendarDaySummary(
      date: checkin.date,
      planDone: summary.planDone,
      planTotal: summary.planTotal,
      habitDone: summary.habitDone +
          (checkin.status == CheckinStatus.done.code ? 1 : 0),
      habitTotal: summary.habitTotal,
      moodAverage: summary.moodAverage,
      moodFailed: summary.moodFailed,
      future: summary.future,
    );
  }

  for (final log in logs) {
    final summary = byDate[log.date];
    if (summary == null) {
      continue;
    }
    final scores = <int?>[
      log.mood1,
      log.mood2,
      log.mood3,
      log.mood4,
      log.mood5,
      log.mood6,
      log.mood7,
      log.mood8,
    ].whereType<int>().toList(growable: false);
    byDate[log.date] = CalendarDaySummary(
      date: log.date,
      planDone: summary.planDone,
      planTotal: summary.planTotal,
      habitDone: summary.habitDone,
      habitTotal: summary.habitTotal,
      moodAverage: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length,
      moodFailed: log.moodFailed == 1,
      future: summary.future,
    );
  }

  for (final habit in habits) {
    for (var day = first;
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final date = isoDate(day);
      final summary = byDate[date];
      if (summary == null ||
          !HabitRepository.isScheduledFor(habit, date) ||
          habit.startDate.compareTo(date) > 0) {
        continue;
      }
      byDate[date] = CalendarDaySummary(
        date: date,
        planDone: summary.planDone,
        planTotal: summary.planTotal,
        habitDone: summary.habitDone,
        habitTotal: summary.habitTotal + 1,
        moodAverage: summary.moodAverage,
        moodFailed: summary.moodFailed,
        future: summary.future,
      );
    }
  }

  return CalendarMonthSummary(
    month: month,
    days: byDate.values.toList(growable: false),
  );
});

// =============================================================================
// Task 39 · W3 —— 偏好 KV / 系统集成 / 版本检查
// =============================================================================
// 为什么不给 `SettingsRepository` 加 getter：「单一写者」—— 本波
// `packages\core_data` 由 W2 独占，且零 schema 变更。这里直接调用既有的
// `get` / `set`，键名集中在下面这组常量里，冲突一目了然。
// =============================================================================

/// 设置键：主题模式（`system` / `light` / `dark`）。
const String settingsKeyThemeMode = 'theme_mode';

/// 设置键：界面语言（`zh` / `en`）。
const String settingsKeyLocale = 'locale';

/// 设置键：开机启动（`1` / `0`）。
const String settingsKeyLaunchOnBoot = 'launch_on_boot';

/// 设置键：每天计划起点小时（`0`..`23` 的十进制整数）。
const String settingsKeyDailyStartHour = 'daily_start_hour';

/// 设置键：每天计划终点小时（`1`..`24`）。
const String settingsKeyDailyEndHour = 'daily_end_hour';

/// 设置键：界面密度（`compact` / `comfortable` / `roomy`）。
const String settingsKeyDensity = 'density';

/// 设置键：目标页上次停留的页签（`week` / `month` / `year` / `blueprint`）。
const String settingsKeyGoalsTab = 'goals_tab';

/// 目标页页签 id：周（默认）。
const String kGoalsTabWeek = 'week';

/// 目标页页签 id：月。
const String kGoalsTabMonth = 'month';

/// 目标页页签 id：年。
const String kGoalsTabYear = 'year';

/// 目标页页签 id：蓝图（历史值；Task 72 起不在 [kGoalsTabIds] 内）。
const String kGoalsTabBlueprint = 'blueprint';

/// 目标页的三个页签 id（顺序即展示顺序）。
///
/// 口径（Task 72 / D-72-b）：蓝图已独立成页，`kGoalsTabBlueprint` 不再入列 ⇒
/// `parseGoalsTab` 收到它回落周视图。
const List<String> kGoalsTabIds = <String>[
  kGoalsTabWeek,
  kGoalsTabMonth,
  kGoalsTabYear,
];

/// 「恢复默认」要写回的键（不含 `priority_display_mode`：那项另有既有样板）。
const List<String> kAllPreferenceKeys = <String>[
  settingsKeyThemeMode,
  settingsKeyLocale,
  settingsKeyLaunchOnBoot,
  settingsKeyDailyStartHour,
  settingsKeyDailyEndHour,
  settingsKeyDensity,
  settingsKeyGoalsTab,
];

/// 偏好快照。
///
/// 为什么是「一次读全部键」而不是每个设置一个 provider：设置页一次要显示
/// 六七项，逐项异步读会让页面分批跳变；一次读齐只跳一次。
@immutable
class AppPreferences {
  /// 创建偏好快照。
  const AppPreferences({
    required this.themeMode,
    required this.language,
    required this.launchOnBoot,
    required this.dailyStartHour,
    required this.dailyEndHour,
    required this.density,
    required this.goalsTab,
  });

  /// 默认值 = 参数化之前应用的实际行为。
  ///
  /// 主题默认**浅色**而不是「跟随系统」：改默认值会让既有界面的观感在用户
  /// 什么都没做的情况下变化。跟随系统是可选档，不是新默认。
  static const AppPreferences defaults = AppPreferences(
    themeMode: ThemeMode.light,
    language: AppLanguage.zh,
    launchOnBoot: false,
    dailyStartHour: kGridStartHour,
    dailyEndHour: kGridEndHour,
    density: DensityProfile.comfortable,
    goalsTab: kGoalsTabWeek,
  );

  /// 主题模式。
  final ThemeMode themeMode;

  /// 界面语言。
  final AppLanguage language;

  /// 是否开机启动（注册表实际状态由设置页在进入时读取，不以此为准）。
  final bool launchOnBoot;

  /// 每天计划起点小时。
  final int dailyStartHour;

  /// 每天计划终点小时。
  final int dailyEndHour;

  /// 界面密度。
  final DensityProfile density;

  /// 目标页上次停留的页签（`week` / `month` / `year` / `blueprint`）。
  final String goalsTab;

  /// 每天计划窗口（网格裁剪用）。
  DayWindow get dayWindow => DayWindow.fromHours(dailyStartHour, dailyEndHour);

  /// 文案表。
  AppLocalizations get l10n => AppLocalizations.forLanguage(language);

  /// 复制一份并覆盖若干字段。
  AppPreferences copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? launchOnBoot,
    int? dailyStartHour,
    int? dailyEndHour,
    DensityProfile? density,
    String? goalsTab,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      launchOnBoot: launchOnBoot ?? this.launchOnBoot,
      dailyStartHour: dailyStartHour ?? this.dailyStartHour,
      dailyEndHour: dailyEndHour ?? this.dailyEndHour,
      density: density ?? this.density,
      goalsTab: goalsTab ?? this.goalsTab,
    );
  }

  /// 主题模式的持久化码值。
  static String encodeThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  /// 解析主题模式；无法识别一律回落浅色（与默认一致）。
  static ThemeMode parseThemeMode(String? code) => switch (code) {
        'system' => ThemeMode.system,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.light,
      };

  /// 解析布尔 KV（`1` / `true` 为真）。
  static bool parseBool(String? code) => code == '1' || code == 'true';

  /// 解析密度；无法识别回落舒适档。
  static DensityProfile parseDensity(String? code) {
    for (final DensityProfile profile in DensityProfile.values) {
      if (profile.name == code) {
        return profile;
      }
    }
    return DensityProfile.comfortable;
  }

  /// 解析小时；无法识别回落 [fallback]，并夹进 `[low, high]`。
  static int parseHour(String? code, {required int fallback, required int low, required int high}) {
    final int? parsed = int.tryParse((code ?? '').trim());
    return (parsed ?? fallback).clamp(low, high);
  }

  /// 解析目标页页签 id；无法识别回落「周」。
  ///
  /// 为什么不抛异常：页签 id 是**纯展示状态**，认错了就当用户没选过，
  /// 比把设置页炸掉好。
  static String parseGoalsTab(String? code) =>
      kGoalsTabIds.contains(code) ? code! : kGoalsTabWeek;
}

/// 读取全部偏好（任何异常 ⇒ 默认值，绝不把设置页炸掉）。
final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final SettingsRepository settings = ref.watch(repositoriesProvider).settings;
  final String? theme = await settings.get(settingsKeyThemeMode);
  final String? locale = await settings.get(settingsKeyLocale);
  final String? boot = await settings.get(settingsKeyLaunchOnBoot);
  final String? start = await settings.get(settingsKeyDailyStartHour);
  final String? end = await settings.get(settingsKeyDailyEndHour);
  final String? density = await settings.get(settingsKeyDensity);
  final String? goalsTab = await settings.get(settingsKeyGoalsTab);

  final int startHour = AppPreferences.parseHour(
    start,
    fallback: kGridStartHour,
    low: 0,
    high: 23,
  );
  final int endHour = AppPreferences.parseHour(
    end,
    fallback: kGridEndHour,
    low: 1,
    high: 24,
  );
  return AppPreferences(
    themeMode: AppPreferences.parseThemeMode(theme),
    language: AppLanguage.fromCode(locale),
    launchOnBoot: AppPreferences.parseBool(boot),
    dailyStartHour: startHour,
    dailyEndHour: endHour > startHour ? endHour : (startHour + 1).clamp(1, 24),
    density: AppPreferences.parseDensity(density),
    goalsTab: AppPreferences.parseGoalsTab(goalsTab),
  );
});

/// 同步读取的偏好（未加载完 / 读失败 ⇒ 默认值）。
///
/// 主题与文案必须在**第一帧**就有值，所以这里给一个不会抛的同步视图。
final currentPreferencesProvider = Provider<AppPreferences>(
  (ref) => ref.watch(appPreferencesProvider).asData?.value ??
      AppPreferences.defaults,
);

/// 文案表（设置页 / 关于页）。
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => ref.watch(currentPreferencesProvider).l10n,
);

/// 方格时间轴窗口。
final dayWindowProvider = Provider<DayWindow>(
  (ref) => ref.watch(currentPreferencesProvider).dayWindow,
);

/// 偏好写入口：写一个键 → 让读侧失效重取。
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(ref),
);

/// 偏好写入口。
class PreferencesStore {
  /// 创建写入口。
  PreferencesStore(this._ref);

  final Ref _ref;

  SettingsRepository get _settings => _ref.read(repositoriesProvider).settings;

  /// 写一个键并刷新读侧。
  Future<void> write(String key, String value) async {
    await _settings.set(key, value);
    _ref.invalidate(appPreferencesProvider);
  }

  /// 主题。
  Future<void> setThemeMode(ThemeMode mode) =>
      write(settingsKeyThemeMode, AppPreferences.encodeThemeMode(mode));

  /// 语言。
  Future<void> setLanguage(AppLanguage language) =>
      write(settingsKeyLocale, language.code);

  /// 开机启动偏好（注册表由 [SystemIntegration] 负责）。
  Future<void> setLaunchOnBoot(bool enabled) =>
      write(settingsKeyLaunchOnBoot, enabled ? '1' : '0');

  /// 每天计划起止（非法组合自动纠正成 `start < end`）。
  Future<void> setDailyWindow(int startHour, int endHour) async {
    final DayWindow window = DayWindow.fromHours(startHour, endHour);
    await write(settingsKeyDailyStartHour, '${window.startHour}');
    await write(settingsKeyDailyEndHour, '${window.endHour}');
  }

  /// 界面密度。
  Future<void> setDensity(DensityProfile density) =>
      write(settingsKeyDensity, density.name);

  /// 目标页上次停留的页签。
  Future<void> setGoalsTab(String tabId) =>
      write(settingsKeyGoalsTab, AppPreferences.parseGoalsTab(tabId));

  /// 恢复默认：把全部偏好键写回默认值（没有 delete 方法，只能写回）。
  Future<void> resetToDefaults() async {
    await setThemeMode(AppPreferences.defaults.themeMode);
    await setLanguage(AppPreferences.defaults.language);
    await setLaunchOnBoot(AppPreferences.defaults.launchOnBoot);
    await setDailyWindow(
      AppPreferences.defaults.dailyStartHour,
      AppPreferences.defaults.dailyEndHour,
    );
    await setDensity(AppPreferences.defaults.density);
    await setGoalsTab(AppPreferences.defaults.goalsTab);
    await _settings.setPriorityDisplayMode(PriorityDisplayMode.quadrant);
    _ref.invalidate(appPreferencesProvider);
    _ref.invalidate(priorityDisplayModeProvider);
  }
}

// =============================================================================
// Task 65 · 目标页数据通道（读侧 provider + 两个可测的写入口）
// =============================================================================
// 写侧只暴露两个**函数型** provider（[goalsTabSaverProvider] /
// [goalDraftSaverProvider]）：界面层通过它们写，测试把它们 override 成记录器，
// 于是「页签记忆」与「草稿确认」这两条写路径不需要真数据库就能断言。
//
// 纪律：滚动候选**只算不写**（[goalWeeklyDraftsProvider] 走
// `rollWeeklyDrafts`），落库只发生在用户点了确认之后（走
// [goalDraftSaverProvider] → `saveWeeklyDrafts`，落库状态是 `draft`）。
// =============================================================================

/// 目标仓储（数据层通道）。
final goalStoreProvider = Provider<GoalStore>(
  (ref) => GoalStore(ref.watch(repositoriesProvider)),
);

/// 当前周周期（ISO 周；按**本地日历日**推导）。
///
/// 为什么不能直接拿 `DateTime.now()`：周期口径是 UTC（[GoalPeriod]），而
/// 「本周」是用户视角的本地日历周。直接用当前时刻，在 UTC+8 下会把周一
/// 凌晨算进上一周。这里取本地日历日**中午**对应的 UTC 时刻 —— 任何时区
/// 下它都落在同一个日历日上，于是 ISO 周号与本地日历周一致。
final goalCurrentWeekProvider = Provider<GoalPeriod>((ref) {
  final DateTime local = DateTime.parse(ref.watch(todayProvider));
  final int millis = DateTime.utc(
    local.year,
    local.month,
    local.day,
    12,
  ).millisecondsSinceEpoch;
  return GoalPeriod.fromStartMillis(millis, GoalPeriodUnit.week);
});

/// 本周目标视图（右块「本周目标」表的读模型）。
final goalWeekViewProvider = FutureProvider<GoalWeekView>((ref) async {
  final GoalStore store = ref.watch(goalStoreProvider);
  final GoalPeriod period = ref.watch(goalCurrentWeekProvider);
  return store.weekView(period);
});

/// 本周滚动候选（**只算不写**：库里 0 增量）。
final goalWeeklyDraftsProvider = FutureProvider<List<GoalDraft>>((ref) async {
  final GoalStore store = ref.watch(goalStoreProvider);
  final GoalPeriod period = ref.watch(goalCurrentWeekProvider);
  return store.rollWeeklyDrafts(period);
});

/// 记住目标页上次停留的页签（界面层点页签时调用）。
///
/// 写成函数型 provider 是为了可测：测试 override 成记录器即可断言
/// 「点页签 ⇒ 记住页签」，不需要真数据库。
final goalsTabSaverProvider = Provider<Future<void> Function(String tabId)>((
  ref,
) {
  final PreferencesStore store = ref.read(preferencesStoreProvider);
  return store.setGoalsTab;
});

/// 保存滚动草稿（**只有用户点了确认才调用**）。
///
/// 落库状态是 `draft`（激活由用户后续决定），落库前必须先经过
/// [goalWeeklyDraftsProvider] 的「只算」结果。
final goalDraftSaverProvider =
    Provider<Future<int> Function(List<GoalDraft> drafts)>((ref) {
  final GoalStore store = ref.watch(goalStoreProvider);
  return store.saveWeeklyDrafts;
});

// -----------------------------------------------------------------------------
// 系统集成（开机启动 / 桌面快捷方式 / 打开链接）
// -----------------------------------------------------------------------------

/// 系统集成的可注入抽象。
///
/// 为什么必须有这一层：真写注册表 / 真建 `.lnk` 会污染跑测试的那台机器。
/// 单元测试注入假实现只断言「调用序列」，真实落盘验证走
/// `reports\task39-w3-autorun-check.ps1` 手工跑一次并还原。
abstract class SystemIntegration {
  /// 当前可执行文件绝对路径。
  String executablePath();

  /// 写/删注册表 `HKCU\...\Run\ActLog`；返回是否成功。
  Future<bool> setLaunchOnBoot(bool enabled);

  /// 读注册表里 `ActLog` 的当前值；不存在返回 null。
  Future<String?> readLaunchOnBoot();

  /// 在桌面创建 `actlog.lnk`；返回是否成功。
  Future<bool> createDesktopShortcut();

  /// 用系统默认程序打开链接。
  Future<bool> openUrl(String url);
}

/// Windows 实现（零依赖：`reg` / `powershell` / `rundll32`）。
class WindowsSystemIntegration implements SystemIntegration {
  /// 创建实现。
  const WindowsSystemIntegration();

  /// 注册表 Run 键路径。
  static const String runKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  /// 注册表值名。
  static const String runValueName = 'ActLog';

  @override
  String executablePath() => Platform.resolvedExecutable;

  @override
  Future<bool> setLaunchOnBoot(bool enabled) async {
    final List<String> args = enabled
        ? <String>[
            'ADD',
            runKey,
            '/v',
            runValueName,
            '/t',
            'REG_SZ',
            '/d',
            '"${Platform.resolvedExecutable}"',
            '/f',
          ]
        : <String>['DELETE', runKey, '/v', runValueName, '/f'];
    try {
      final ProcessResult result = await Process.run('reg', args);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> readLaunchOnBoot() async {
    try {
      final ProcessResult result = await Process.run(
        'reg',
        <String>['QUERY', runKey, '/v', runValueName],
      );
      if (result.exitCode != 0) {
        return null;
      }
      final String out = '${result.stdout}';
      final RegExpMatch? match =
          RegExp('$runValueName\\s+REG_SZ\\s+(.+)').firstMatch(out);
      return match?.group(1)?.trim();
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> createDesktopShortcut() async {
    final String exe = Platform.resolvedExecutable.replaceAll("'", "''");
    // 纯 ASCII 脚本体：`-EncodedCommand` 用 UTF-16LE base64，绕开引号与
    // 中文路径的双重转义地狱。
    final String script = <String>[
      r"$ErrorActionPreference = 'Stop'",
      "\$exe = '$exe'",
      r"$desktop = [Environment]::GetFolderPath('Desktop')",
      r"if ([string]::IsNullOrWhiteSpace($desktop)) { throw 'desktop not found' }",
      r"$lnk = Join-Path $desktop 'actlog.lnk'",
      r'$shell = New-Object -ComObject WScript.Shell',
      r'$shortcut = $shell.CreateShortcut($lnk)',
      r'$shortcut.TargetPath = $exe',
      r'$shortcut.WorkingDirectory = Split-Path $exe',
      r'$shortcut.Save()',
    ].join("\r\n");
    try {
      final ProcessResult result = await Process.run('powershell', <String>[
        '-NoProfile',
        '-NonInteractive',
        '-EncodedCommand',
        _utf16LeBase64(script),
      ]);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openUrl(String url) async {
    try {
      // `rundll32 url.dll,FileProtocolHandler` 不起控制台，比 `cmd /c start`
      // 少一次黑窗闪烁（brief §3 允许两种，实测选后者）。
      final ProcessResult result =
          await Process.run('rundll32', <String>['url.dll,FileProtocolHandler', url]);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }

  /// UTF-16LE（无 BOM）base64 —— PowerShell `-EncodedCommand` 的入参格式。
  static String _utf16LeBase64(String value) {
    final List<int> bytes = <int>[];
    for (final int unit in value.codeUnits) {
      bytes.add(unit & 0xFF);
      bytes.add((unit >> 8) & 0xFF);
    }
    return base64.encode(bytes);
  }
}

/// 系统集成入口（测试注入假实现）。
final systemIntegrationProvider = Provider<SystemIntegration>(
  (ref) => const WindowsSystemIntegration(),
);

// -----------------------------------------------------------------------------
// 版本检查（零依赖：dart:io HttpClient）
// -----------------------------------------------------------------------------

/// GitHub 最新发布 API。
final Uri kLatestReleaseUrl = Uri.parse(
  'https://api.github.com/repos/kizemo/actlog/releases/latest',
);

/// 检查结果状态。
enum ReleaseCheckStatus {
  /// 已是最新（或与最新同版本）。
  upToDate,

  /// 有更新。
  newer,

  /// 仓库暂无发布版本（HTTP 404）。
  noRelease,

  /// 网络失败 / 超时 / 响应不可解析。
  networkError,
}

/// 检查结果。
@immutable
class ReleaseCheckResult {
  /// 创建结果。
  const ReleaseCheckResult(this.status, {this.latestTag});

  /// 状态。
  final ReleaseCheckStatus status;

  /// 远端 `tag_name`（可能为 null）。
  final String? latestTag;

  /// 远端版本号字符串（去 `v` 前缀）。
  String? get latestVersion {
    final String? tag = latestTag;
    if (tag == null) {
      return null;
    }
    return tag.trim().replaceFirst(RegExp('^[vV]'), '');
  }
}

/// 版本检查抽象（测试可注入）。
abstract class ReleaseChecker {
  /// 执行检查；实现必须**自行**吞掉所有网络异常。
  Future<ReleaseCheckResult> check();
}

/// 走 GitHub Releases API 的实现。
class GitHubReleaseChecker implements ReleaseChecker {
  /// 创建实现。
  GitHubReleaseChecker({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 10),
    this.currentVersion = kAppVersion,
  }) : endpoint = endpoint ?? kLatestReleaseUrl;

  /// 目标地址（测试注入本地 HttpServer）。
  final Uri endpoint;

  /// 单步超时。
  final Duration timeout;

  /// 当前版本。
  final String currentVersion;

  @override
  Future<ReleaseCheckResult> check() async {
    final HttpClient client = HttpClient()..connectionTimeout = timeout;
    try {
      final HttpClientRequest request =
          await client.getUrl(endpoint).timeout(timeout);
      request.headers
        ..set(HttpHeaders.userAgentHeader, 'actlog/$currentVersion')
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final HttpClientResponse response =
          await request.close().timeout(timeout);
      if (response.statusCode == HttpStatus.notFound) {
        return const ReleaseCheckResult(ReleaseCheckStatus.noRelease);
      }
      if (response.statusCode != HttpStatus.ok) {
        return const ReleaseCheckResult(ReleaseCheckStatus.networkError);
      }
      final String body =
          await response.transform(utf8.decoder).join().timeout(timeout);
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return const ReleaseCheckResult(ReleaseCheckStatus.noRelease);
      }
      final Object? tag = decoded['tag_name'];
      if (tag is! String || tag.trim().isEmpty) {
        return const ReleaseCheckResult(ReleaseCheckStatus.noRelease);
      }
      return ReleaseCheckResult(
        compareVersions(tag, currentVersion) > 0
            ? ReleaseCheckStatus.newer
            : ReleaseCheckStatus.upToDate,
        latestTag: tag,
      );
    } on Object {
      // 超时、DNS 失败、TLS 失败、JSON 截断 —— 一律降级，不冒泡到 UI。
      return const ReleaseCheckResult(ReleaseCheckStatus.networkError);
    } finally {
      client.close(force: true);
    }
  }
}

/// 版本检查入口。
final releaseCheckerProvider = Provider<ReleaseChecker>(
  (ref) => GitHubReleaseChecker(),
);

// -----------------------------------------------------------------------------
// 未完成目标（Task 72 B7 地基：W2/W3 共用，本棒不消费）
// -----------------------------------------------------------------------------
//
// D-72-c 的「未完成」口径 = 非 done **且**未归档。`GoalStore.listGoals` 的
// `status` 只做等值筛选、没有 `notDone`，且严禁为它新增仓储方法 ⇒ 按 kind 取回
// 后在 Dart 侧过滤（与 `widgets\goal_year_matrix.dart:6` 的零改动纪律一致）。
//
// 形状沿用本文件既有的异步清单 provider（见 `goalWeeklyDraftsProvider`）：
// `FutureProvider<List<GoalRow>>`，W2/W3 按名 `ref.watch(...)` 消费。

/// 只留「未完成且未归档」的目标（D-72-c 口径）。
List<GoalRow> _openOnly(List<GoalRow> rows) => <GoalRow>[
  for (final GoalRow goal in rows)
    if (!goal.isDone && goal.archivedAt == null) goal,
];

/// 未完成年目标（`kind == yearly`）。
final yearOpenGoalsProvider = FutureProvider<List<GoalRow>>((ref) async {
  final GoalStore store = ref.read(goalStoreProvider);
  return _openOnly(await store.listGoals(kind: GoalKind.yearly));
});

/// 未完成月目标（`kind == monthly`）。
final monthOpenGoalsProvider = FutureProvider<List<GoalRow>>((ref) async {
  final GoalStore store = ref.read(goalStoreProvider);
  return _openOnly(await store.listGoals(kind: GoalKind.monthly));
});

/// 未完成周目标（`kind == weekly`）。
final weekOpenGoalsProvider = FutureProvider<List<GoalRow>>((ref) async {
  final GoalStore store = ref.read(goalStoreProvider);
  return _openOnly(await store.listGoals(kind: GoalKind.weekly));
});
