// =============================================================================
// 目标页 · 页壳（Task 65 UI 半批 B1）
// =============================================================================
// 页面是**内容体**：`Scaffold` / `AppBar` 由 `LedgerShell` 承担（与其它页面
// 同口径，见 `pages\todo_pool_page.dart`）。
//
// 三个结构决定：
//  1. 页签切换**不 push 路由**：四个页签是同一页里的四个视图，共享标题栏与
//     滚动位置。push 路由会让返回键在四个页签之间来回跳 —— 那是壳的毛病，
//     不是页签的毛病。测试断言「切页签不产生路由 push」。
//  2. 上次停留的页签存在偏好里（`settingsKeyGoalsTab`），下次进页面直接回到
//     那一页；默认「周」。
//  3. 用户手动点过页签之后，偏好回读**不再覆盖**界面（否则「点月 → 偏好异步
//     落库 → 偏好回读 → 界面被改回去」会闪一下）。
//
// 文案全走 l10n（`parts\goals.dart` + `parts\shell.dart`），英文界面零中文。
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../theme/app_tokens.dart';
import 'goals_month_page.dart';
import 'goals_week_page.dart';
import 'goals_year_page.dart';

/// 目标页：周｜月｜年 三个页签的壳。
///
/// 口径（Task 72 / D-72-b）：蓝图不再是一个页签，它已独立成第 7 个导航项。
class GoalsPage extends ConsumerStatefulWidget {
  /// 创建目标页。
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  /// 当前页签 id（`week` / `month` / `year`）。
  late String _tabId;

  /// 用户是否手动点过页签（点过之后偏好回读不再覆盖界面）。
  bool _userPicked = false;

  @override
  void initState() {
    super.initState();
    _tabId = AppPreferences.parseGoalsTab(
      ref.read(currentPreferencesProvider).goalsTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final ThemeTokens tokens = context.tokens;

    // 偏好加载完成前 `currentPreferencesProvider` 给默认档（周）；加载完成后
    // 若用户没点过页签就跟随偏好走。
    ref.listen<AppPreferences>(currentPreferencesProvider, (
      AppPreferences? _,
      AppPreferences next,
    ) {
      if (_userPicked || !mounted) {
        return;
      }
      final String parsed = AppPreferences.parseGoalsTab(next.goalsTab);
      if (parsed != _tabId) {
        setState(() => _tabId = parsed);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.goalsTitle,
          key: const ValueKey<String>('goals-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: tokens.ink),
        ),
        const SizedBox(height: AppTokens.gapCard),
        _GoalsTabBar(
          currentId: _tabId,
          labels: <String, String>{
            kGoalsTabWeek: t.goalsTabWeek,
            kGoalsTabMonth: t.goalsTabMonth,
            kGoalsTabYear: t.goalsTabYear,
          },
          onSelected: _selectTab,
        ),
        const SizedBox(height: AppTokens.gapCard),
        _buildBody(),
      ],
    );
  }

  /// 当前页签的内容区。
  ///
  /// 蓝图已独立成页（Task 72 / D-72-b），所以 `default` 回落周视图：历史偏好里
  /// 残留的 `blueprint` 已被 `parseGoalsTab` 挡掉，这里再兜一层，取到不认的值
  /// 也不会白屏。
  Widget _buildBody() {
    switch (_tabId) {
      case kGoalsTabMonth:
        return const GoalsMonthPage();
      case kGoalsTabYear:
        return const GoalsYearPage();
      default:
        return const GoalsWeekPage();
    }
  }

  /// 切页签：只换内容区，**不 push 路由**；顺手记住这一页。
  void _selectTab(String id) {
    if (id == _tabId) {
      return;
    }
    setState(() {
      _tabId = id;
      _userPicked = true;
    });
    unawaited(_rememberTab(id));
  }

  /// 把页签写进偏好。
  ///
  /// 写失败**不阻断界面**：偏好只决定「下次进页面回到哪一页」，忘了记也不影响
  /// 本次使用（下次回落到默认「周」）。
  Future<void> _rememberTab(String id) async {
    try {
      await ref.read(goalsTabSaverProvider)(id);
    } on Object {
      // 忽略：记忆失败只影响下一次进入时的落点。
    }
  }
}

/// 页签条（周｜月｜年｜蓝图）。
class _GoalsTabBar extends StatelessWidget {
  /// 创建页签条。
  const _GoalsTabBar({
    required this.currentId,
    required this.labels,
    required this.onSelected,
  });

  /// 当前页签 id。
  final String currentId;

  /// 页签 id → 显示文案。
  final Map<String, String> labels;

  /// 选中回调。
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens tokens = context.tokens;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final MapEntry<String, String> entry in labels.entries)
          _GoalsTab(
            key: ValueKey<String>('goals-tab-${entry.key}'),
            label: entry.value,
            selected: entry.key == currentId,
            onTap: () => onSelected(entry.key),
            tokens: tokens,
          ),
      ],
    );
  }
}

/// 单个页签。
class _GoalsTab extends StatelessWidget {
  /// 创建页签。
  const _GoalsTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tokens,
    super.key,
  });

  /// 显示文案。
  final String label;

  /// 是否当前页签。
  final bool selected;

  /// 点击回调。
  final VoidCallback onTap;

  /// 主题色板。
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.inkWash : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: selected ? tokens.hairStrong : tokens.hairSoft,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? tokens.ink : tokens.meta,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// B2 起三个占位分支已换成真实页面体（月 / 年 / 蓝图），
// 骨架占位壳 `_GoalsPlaceholder` 随之删除（保留会触发 `unused_element`）。
