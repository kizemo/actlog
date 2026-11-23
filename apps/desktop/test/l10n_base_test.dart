// =============================================================================
// l10n 底座自检（W0）
// =============================================================================
// 这一批用例守的是「拆分没改坏东西」这件事，而不是某个页面的长相：
//  1. 键表与 getter 一一对应，一条不少、键不重复、键格式统一；
//  2. 中英两态都非空，且除两条白名单外必须**不同**（这是防「复制粘贴当翻译」）；
//  3. `forLanguage` / `fromCode` / `of(context)` 的分流正确，缺 scope 必抛错；
//  4. 插值方法的中文输出与拆分前页面里的旧拼串**逐字一致**；
//  5. `L10nFormat` 的分隔符按语言切换。
//
// 刻意没写的东西：断言某条文案的**具体内容**（那会把文案改动变成测试红）。
// 这里只守结构与不变式，文案本身由人看。
// =============================================================================

import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/l10n/l10n_keys.dart';
import 'package:actlog/src/l10n/l10n_scope.dart';
import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

void main() {
  group('键表结构', () {
    test('120 条 getter 全部登记在对照表里', () {
      expect(L10nKeys.byGetter.length, 120);
      expect(l10nAccessors.length, 120);
      // `byGetter` 是「getter 名 → 键」，访问器表是「键 → 取值」，所以这里比
      // 的是 `byGetter` 的**值**集合（都是 kebab 键）。
      expect(l10nAccessors.keys.toSet(), L10nKeys.byGetter.values.toSet());
    });

    test('2 条列表型 getter 全部登记在列表表里', () {
      expect(L10nKeys.byListGetter.length, 2);
      expect(l10nListAccessors.length, 2);
      expect(
        l10nListAccessors.keys.toSet(),
        L10nKeys.byListGetter.values.toSet(),
      );
    });

    test('4 条插值方法登记在方法表里', () {
      expect(L10nKeys.byMethod.length, 4);
      expect(
        L10nKeys.byMethod.keys.toSet(),
        <String>{'hoursCount', 'minutesCount', 'deferredDays', 'moodScoreLabel'},
      );
    });

    test('全部键值不重复（120 + 2 + 4 = 126）', () {
      final Set<String> all = <String>{
        ...L10nKeys.byGetter.values,
        ...L10nKeys.byListGetter.values,
        ...L10nKeys.byMethod.values,
      };
      expect(all.length, 126);
    });

    test('键一律 kebab-case（小写字母数字，单横线分隔）', () {
      final RegExp kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
      final Set<String> all = <String>{
        ...L10nKeys.byGetter.values,
        ...L10nKeys.byListGetter.values,
        ...L10nKeys.byMethod.values,
      };
      for (final String key in all) {
        expect(kebab.hasMatch(key), isTrue, reason: '不合规的键：$key');
      }
    });

    test('键带模块前缀，前缀与 part 归属一致', () {
      for (final String key in <String>[
        ...L10nKeys.byGetter.values,
        ...L10nKeys.byListGetter.values,
      ]) {
        expect(
          key.startsWith('settings-') ||
              key.startsWith('about-') ||
              key.startsWith('common-') ||
              key.startsWith('shell-') ||
              key.startsWith('projects-') ||
              key.startsWith('domain-'),
          isTrue,
          reason: 'getter 键必须以模块前缀开头：$key',
        );
      }
      for (final String key in L10nKeys.byMethod.values) {
        expect(key.startsWith('domain-'), isTrue, reason: '方法键缺前缀：$key');
      }
    });
  });

  group('域层文案 id 对齐', () {
    /// 当前语言（中文态）下「键 → 文案」的查表结果。
    Map<String, String> zhByKey() => <String, String>{
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in l10nAccessors.entries)
        entry.key: entry.value(AppLocalizations.zh),
    };

    test('包层给出的 id 全部已建键，且中文逐字一致', () {
      final Map<String, String> zh = zhByKey();
      for (final QuadrantStyle style in QuadrantStyle.all.values) {
        expect(zh[style.labelKey], style.label, reason: style.labelKey);
        expect(
          zh[style.shortLabelKey],
          style.shortLabel,
          reason: style.shortLabelKey,
        );
      }
      for (final AbcStyle style in AbcStyle.all.values) {
        expect(zh[style.labelKey], style.label, reason: style.labelKey);
      }
      expect(zh[PriorityDisplay.unsetLabelKey], PriorityDisplay.unsetLabel);
    });

    test('labelKeyFor 与 labelFor 一一对应（含未分级兜底）', () {
      final Map<String, String> zh = zhByKey();
      for (final PriorityDisplayMode mode in PriorityDisplayMode.values) {
        for (final Quadrant? q in <Quadrant?>[...Quadrant.values, null]) {
          expect(
            zh[PriorityDisplay.labelKeyFor(mode, quadrant: q)],
            PriorityDisplay.labelFor(mode, quadrant: q),
            reason: '$mode/$q',
          );
        }
        for (final PriorityAbc? a in <PriorityAbc?>[...PriorityAbc.values, null]) {
          expect(
            zh[PriorityDisplay.labelKeyFor(mode, priorityAbc: a)],
            PriorityDisplay.labelFor(mode, priorityAbc: a),
            reason: '$mode/$a',
          );
        }
      }
    });
  });

  group('中英双态', () {
    test('每条 getter 在中英两态都取得到非空文案', () {
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in l10nAccessors.entries) {
        final String zh = entry.value(AppLocalizations.zh);
        final String en = entry.value(AppLocalizations.en);
        expect(zh.trim(), isNotEmpty, reason: '${entry.key} 中文态为空');
        expect(en.trim(), isNotEmpty, reason: '${entry.key} 英文态为空');
      }
    });

    test('除白名单外，中英两态必须不同（防复制粘贴当翻译）', () {
      for (final MapEntry<String, String Function(AppLocalizations)> entry
          in l10nAccessors.entries) {
        if (sameValueWhitelist.contains(entry.key)) {
          continue;
        }
        final String zh = entry.value(AppLocalizations.zh);
        final String en = entry.value(AppLocalizations.en);
        expect(zh, isNot(en), reason: '${entry.key} 中英同值且不在白名单里');
      }
    });

    test('每条列表型 getter 中英两态都非空，条目数一致且逐条不同', () {
      for (final MapEntry<String, List<String> Function(AppLocalizations)> entry
          in l10nListAccessors.entries) {
        final List<String> zh = entry.value(AppLocalizations.zh);
        final List<String> en = entry.value(AppLocalizations.en);
        expect(zh, isNotEmpty, reason: '${entry.key} 中文态为空');
        expect(en, isNotEmpty, reason: '${entry.key} 英文态为空');
        expect(en.length, zh.length, reason: '${entry.key} 中英条目数不一致');
        for (int i = 0; i < zh.length; i++) {
          expect(zh[i].trim(), isNotEmpty, reason: '${entry.key}[$i] 中文态为空');
          expect(en[i].trim(), isNotEmpty, reason: '${entry.key}[$i] 英文态为空');
          expect(zh[i], isNot(en[i]), reason: '${entry.key}[$i] 中英同值');
        }
      }
    });

    test('白名单恰好 2 条，且它们确实中英同值（防白名单过期）', () {
      expect(sameValueWhitelist.length, 2);
      for (final String key in sameValueWhitelist) {
        expect(l10nAccessors.containsKey(key), isTrue, reason: '白名单键不在表里：$key');
        final String Function(AppLocalizations) read = l10nAccessors[key]!;
        expect(
          read(AppLocalizations.zh),
          read(AppLocalizations.en),
          reason: '白名单里的 $key 其实中英不同，应当移出白名单',
        );
      }
    });
  });

  group('语言分流', () {
    test('forLanguage：en 取英文，zh 与未知回落中文', () {
      expect(AppLocalizations.forLanguage(AppLanguage.en), AppLocalizations.en);
      expect(AppLocalizations.forLanguage(AppLanguage.zh), AppLocalizations.zh);
    });

    test('fromCode：只认 en，其余（含 null / 空串 / 大写）回落中文', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('zh'), AppLanguage.zh);
      expect(AppLanguage.fromCode(null), AppLanguage.zh);
      expect(AppLanguage.fromCode(''), AppLanguage.zh);
      expect(AppLanguage.fromCode('EN'), AppLanguage.zh);
      expect(AppLanguage.fromCode('English'), AppLanguage.zh);
    });

    test('持久化码值就是 zh / en', () {
      expect(AppLanguage.zh.code, 'zh');
      expect(AppLanguage.en.code, 'en');
    });
  });

  group('AppLocalizations.of(context)', () {
    testWidgets('没有 L10nScope 时抛 FlutterError，且错误信息给出修法', (
      WidgetTester tester,
    ) async {
      Object? caught;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              try {
                AppLocalizations.of(context);
              } on Object catch (error) {
                caught = error;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(caught, isA<FlutterError>());
      final FlutterError error = caught! as FlutterError;
      final String message = error.toString();
      expect(message.contains('L10nScope'), isTrue);
      expect(message.contains('app.dart'), isTrue);
    });

    testWidgets('有 L10nScope 时取到对应语言的文案', (WidgetTester tester) async {
      late AppLocalizations zh;
      late AppLocalizations en;
      await tester.pumpWidget(
        l10nWrap(
          Builder(
            builder: (BuildContext context) {
              zh = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          language: AppLanguage.zh,
        ),
      );
      await tester.pumpWidget(
        l10nWrap(
          Builder(
            builder: (BuildContext context) {
              en = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          language: AppLanguage.en,
        ),
      );
      expect(zh.settingsTitle, '设置');
      expect(en.settingsTitle, 'Settings');
      expect(identical(zh, AppLocalizations.zh), isTrue);
      expect(identical(en, AppLocalizations.en), isTrue);
    });

    testWidgets('切换语言后子树读到的是新语言（会触发重建）', (
      WidgetTester tester,
    ) async {
      Widget pageUnderTest({AppLanguage language = AppLanguage.zh}) => l10nWrap(
        Builder(
          builder: (BuildContext context) =>
              Text(AppLocalizations.of(context).settingsTitle),
        ),
        language: language,
      );

      await tester.pumpWidget(pageUnderTest());
      expect(find.text('设置'), findsOneWidget);

      await tester.pumpWidget(pageUnderTest(language: AppLanguage.en));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('设置'), findsNothing);
    });
  });

  group('插值方法', () {
    test('中文输出与拆分前的旧拼串逐字一致', () {
      // 出处：widgets\est_duration_text.dart:64
      expect(AppLocalizations.zh.hoursCount(3), '3 小时');
      // 出处：widgets\timeline\slot_range_dialog.dart:137
      expect(AppLocalizations.zh.minutesCount(45), '45 分钟');
      // 出处：packages\core_data\lib\src\standup.dart:293
      expect(AppLocalizations.zh.deferredDays(2), '已顺延 2 天');
      // 出处：packages\core_domain\lib\src\entities.dart:240
      expect(AppLocalizations.zh.moodScoreLabel('心态'), '心态分值');
    });

    test('英文输出非空且与中文不同', () {
      final AppLocalizations en = AppLocalizations.en;
      expect(en.hoursCount(3).trim(), isNotEmpty);
      expect(en.minutesCount(45).trim(), isNotEmpty);
      expect(en.deferredDays(2).trim(), isNotEmpty);
      expect(en.moodScoreLabel('心态').trim(), isNotEmpty);
      expect(en.hoursCount(3), isNot(AppLocalizations.zh.hoursCount(3)));
      expect(en.minutesCount(45), isNot(AppLocalizations.zh.minutesCount(45)));
      expect(en.deferredDays(2), isNot(AppLocalizations.zh.deferredDays(2)));
      expect(
        en.moodScoreLabel('心态'),
        isNot(AppLocalizations.zh.moodScoreLabel('心态')),
      );
    });

    test('插值真的把参数带进输出（不是写死的常量）', () {
      expect(AppLocalizations.zh.minutesCount(1), contains('1'));
      expect(AppLocalizations.zh.minutesCount(999), contains('999'));
      expect(AppLocalizations.zh.deferredDays(7), contains('7'));
      expect(AppLocalizations.zh.moodScoreLabel('专注'), contains('专注'));
    });
  });

  group('L10nFormat', () {
    test('中文用顿号、英文用逗号加空格拼接', () {
      const L10nFormat zh = L10nFormat(AppLanguage.zh);
      const L10nFormat en = L10nFormat(AppLanguage.en);
      expect(zh.listSeparator, '、');
      expect(en.listSeparator, ', ');
      expect(zh.joinList(<String>['A', 'B', 'C']), 'A、B、C');
      expect(en.joinList(<String>['A', 'B', 'C']), 'A, B, C');
    });

    test('空列表拼出来是空串（不是分隔符）', () {
      expect(const L10nFormat(AppLanguage.zh).joinList(<String>[]), '');
      expect(const L10nFormat(AppLanguage.zh).isEn, isFalse);
      expect(const L10nFormat(AppLanguage.en).isEn, isTrue);
    });
  });
}