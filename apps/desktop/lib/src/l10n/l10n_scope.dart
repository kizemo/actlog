// =============================================================================
// 语言上下文：把「当前语言的文案表」挂到 widget 树上
// =============================================================================
// 为什么另开 `of(context)` 这条路，而不是让页面继续 `ref.watch(appLocalizationsProvider)`：
//  1. 深层 widget（对话框、行内组件）没有 `WidgetRef`，只能靠 context；
//  2. `appLocalizationsProvider` 走 riverpod，测试里必须包 `ProviderScope` 才不炸；
//     走 InheritedWidget 则只要包一层 `L10nScope`，widget 测试的搭建成本低得多。
//
// 为什么 `L10nScope` 不自己读 provider：那会让 `providers.dart` 反过来依赖
// `l10n\`（现在它是单向的：providers → l10n），还会在 provider 容器之外抛错。
// 由 `app.dart` 的根 widget 负责「读 provider 再挂 scope」，依赖方向保持干净。
//
// 缺失时**必须抛错，不能回落中文**：静默回落正是「切了 English 却看到中文」这类
// 最难查的 bug 的产地。错误信息直接给出两步修法。
// =============================================================================

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// 把当前语言的文案表提供给子树。
class L10nScope extends InheritedWidget {
  /// 构造。
  const L10nScope({
    required this.localizations,
    required super.child,
    super.key,
  });

  /// 当前语言的文案表。
  final AppLocalizations localizations;

  /// 取当前语言的文案表；不在 [L10nScope] 之下时抛出带修法的 [FlutterError]。
  static AppLocalizations of(BuildContext context) {
    final L10nScope? scope =
        context.dependOnInheritedWidgetOfExactType<L10nScope>();
    if (scope != null) {
      return scope.localizations;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('找不到 L10nScope，取不到文案表。'),
      ErrorDescription(
        'AppLocalizations.of(context) 只能用在 L10nScope 的子树里，'
        '而当前 context 的上方没有 L10nScope。',
      ),
      ErrorHint(
        '生产代码：在 app.dart 的根 widget 上包一层 '
        'L10nScope(localizations: ref.watch(appLocalizationsProvider), child: ...)。',
      ),
      ErrorHint(
        '测试代码：用 test\\l10n_harness.dart 里的 l10nWrap(child, language: ...) 或 '
        'pumpL10n(tester, child, language: ...) 包一层。',
      ),
    ]);
  }

  @override
  bool updateShouldNotify(L10nScope oldWidget) =>
      oldWidget.localizations != localizations;
}

/// 与语言相关的格式约定（分隔符、列表拼接）。
///
/// 位置登记：本类不属于任何单一模块 part —— 它被时间轴、习惯、日历共用，放进
/// 任何一页的 part 都会让该波次被迫承担别的模块的改动，故与 [L10nScope] 同文件。
class L10nFormat {
  /// 按语言构造。
  const L10nFormat(this.language);

  /// 目标语言。
  final AppLanguage language;

  /// 是否为英文。
  bool get isEn => language == AppLanguage.en;

  /// 列表分隔符：中文用顿号，英文用逗号加空格。
  String get listSeparator => isEn ? ', ' : '、';

  /// 把若干项拼成一句话里的列举。
  String joinList(Iterable<String> items) => items.join(listSeparator);
}