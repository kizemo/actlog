// =============================================================================
// 轻量本地化：文案表聚合入口
// =============================================================================
// 结构（W0 拆分，纯重构、零语义变化）：
//   app_localizations.dart   ← 你在这里：AppLanguage + 聚合类 + of(context)
//   parts\settings.dart      设置页 35 条（W1）
//   parts\about.dart         关于页 19 条（W1）
//   parts\common.dart        跨页共用 7 条（W1）
//   parts\domain.dart        带参数的插值方法 4 条（W0 起，各波次按需追加到自己那份）
//   parts\today.dart         今日面板（W2，W0 时为空骨架）
//   parts\calendar.dart      日历（W3）
//   parts\timeline.dart      方格时间轴（W4）
//   parts\habit.dart         习惯打卡（W5）
//   parts\dialog.dart        对话框（W6）
//   parts\projects.dart      项目页（Task 56）
//   parts\goals.dart         目标页（Task 65 UI 半批 B1）
//   parts\shell.dart         应用外壳：导航 / 快捷键 / 右轨面板（Task 61）
//
// 为什么拆：一次波次只搬一个模块的文案，八波并行时各自只碰自己那一个 part，
// 不会再在同一个大文件里互相撞写。拆分**不改变**任何一条 getter 的名字、签名与
// 中英取值 —— 页面侧 `t.settingsTitle` 一个字都不用动。
//
// 为什么不用 `flutter_localizations` / `intl`：零新增 pub 依赖，而且既有全应用的
// 中文硬编码属于后续批次 —— 现在只给「语言」设置项一个真实可切换的落点，切了
// English 就真的能看到英文，而不是造一个空开关。
//
// 为什么用抽象类 + mixin + 两个 const 实例，而不是 `Map<String, String>`：
// 漏翻会在**编译期**变成未实现成员的 error；Map 方案漏一个 key 只会在运行期
// 静默回落到中文，那种「看起来能跑」的缺失最难被发现。
// =============================================================================

import 'package:flutter/widgets.dart';

import '../data/project_domain_catalog.dart';
import 'l10n_scope.dart';
import 'parts/about.dart';
import 'parts/calendar.dart';
import 'parts/common.dart';
import 'parts/dialog.dart';
import 'parts/domain.dart';
import 'parts/goals.dart';
import 'parts/habit.dart';
import 'parts/projects.dart';
import 'parts/settings.dart';
import 'parts/shell.dart';
import 'parts/timeline.dart';
import 'parts/today.dart';

/// 界面语言。
///
/// 取值只用于持久化与切换，不参与 `Locale` 解析 —— 本项目没有引入
/// `flutter_localizations`，`MaterialApp.locale` 保持默认。
enum AppLanguage {
  /// 简体中文（默认）。
  zh('zh'),

  /// English。
  en('en');

  const AppLanguage(this.code);

  /// 持久化码值。
  final String code;

  /// 解析持久化码值；无法识别（含 null）一律回落中文。
  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.zh;
}

/// 各模块文案表的聚合接口。
///
/// 本身不实现任何 getter —— 成员全部由 `parts\*.dart` 的接口声明、由 zh/en
/// mixin 实现。这样「少搬一条」在编译期就是 error，不需要靠测试去数条数。
abstract class AppLocalizations
    implements
        SettingsL10n,
        AboutL10n,
        CommonL10n,
        DomainL10n,
        TodayL10n,
        CalendarL10n,
        TimelineL10n,
        HabitL10n,
        DialogL10n,
        ProjectsL10n,
        GoalsL10n,
        ShellL10n {
  /// 子类构造。
  const AppLocalizations();

  /// 简体中文。
  static const AppLocalizations zh = _AppLocalizationsZh();

  /// English。
  static const AppLocalizations en = _AppLocalizationsEn();

  /// 按语言取文案表。
  static AppLocalizations forLanguage(AppLanguage language) =>
      language == AppLanguage.en ? en : zh;

  /// 按 widget 树上的 [L10nScope] 取文案表。
  ///
  /// 与 [forLanguage] 的分工：`forLanguage` 给「已经知道语言」的地方用（provider
  /// 内部、测试里的纯数据校验）；[of] 给「只有 context」的地方用（对话框、深层行
  /// 内组件）。缺失 [L10nScope] 时抛错而不是回落中文，理由见 `l10n_scope.dart`。
  static AppLocalizations of(BuildContext context) => L10nScope.of(context);

  /// 领域 key ⇒ 本地化标签（**唯一标签映射**；Task 60 起页面不再自带 switch）。
  ///
  /// - 空串（未分类/未设置）⇒ `projectsDomainStatsUncategorized`；
  /// - 未知 key（同步进来的历史数据）⇒ **原样返回 key**，不猜译名、不崩；
  /// - 其余按 `projectDomainLabelGetters` 登记的 getter 取当前语言的文案。
  String projectDomainLabel(String key) {
    if (key.isEmpty) {
      return projectsDomainStatsUncategorized;
    }
    switch (projectDomainLabelGetters[key]) {
      case 'projectsDomainCareer':
        return projectsDomainCareer;
      case 'projectsDomainWealth':
        return projectsDomainWealth;
      case 'projectsDomainFamily':
        return projectsDomainFamily;
      case 'projectsDomainLearning':
        return projectsDomainLearning;
      case 'projectsDomainSocial':
        return projectsDomainSocial;
      case 'projectsDomainHealth':
        return projectsDomainHealth;
      default:
        return key;
    }
  }

  AppLanguage get language;
}

/// 简体中文文案表：把 11 个 zh mixin 拼起来。
class _AppLocalizationsZh extends AppLocalizations
    with
        SettingsZhL10n,
        AboutZhL10n,
        CommonZhL10n,
        DomainZhL10n,
        TodayZhL10n,
        CalendarZhL10n,
        TimelineZhL10n,
        HabitZhL10n,
        DialogZhL10n,
        ProjectsZhL10n,
        GoalsZhL10n,
        ShellZhL10n {
  const _AppLocalizationsZh();
  @override AppLanguage get language => AppLanguage.zh;
}

/// English 文案表：把 11 个 en mixin 拼起来。
class _AppLocalizationsEn extends AppLocalizations
    with
        SettingsEnL10n,
        AboutEnL10n,
        CommonEnL10n,
        DomainEnL10n,
        TodayEnL10n,
        CalendarEnL10n,
        TimelineEnL10n,
        HabitEnL10n,
        DialogEnL10n,
        ProjectsEnL10n,
        GoalsEnL10n,
        ShellEnL10n {
  const _AppLocalizationsEn();
  @override AppLanguage get language => AppLanguage.en;
}