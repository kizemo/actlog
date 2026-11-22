// =============================================================================
// 警句库数据守卫（Task 55 · W55-E1）
// =============================================================================
// 守的是「Today 页每天换一句」背后的数据质量，而不是某条文案本身：
//  1. 三个集合各 150 条，聚合后正好 450 条；
//  2. 每条中英都非空，英文不含中文字符、中文至少含一个（防串行 / 漏译）；
//  3. 长度在界内（英文 20–200、中文 ≤ 80），避免长句把卡片撑破；
//  4. 归一化后中英各自唯一（防复制粘贴凑数、大小写或空格造成的假差异）；
//  5. 长句配额（英文 ≥100 字 ≥40 条、≥150 字 ≥20 条），保证句长有层次。
//
// 刻意不写的：断言某条警句的**具体内容** —— 那会让文案编辑变成测试红。
// 这里只守结构与不变式，文案本身由人看。
// =============================================================================

import 'package:actlog/src/data/quote.dart';
import 'package:actlog/src/data/quote_set_character.dart';
import 'package:actlog/src/data/quote_set_mastery.dart';
import 'package:actlog/src/data/quote_set_success.dart';
import 'package:actlog/src/data/quotes.dart';
import 'package:flutter_test/flutter_test.dart';

/// CJK 统一表意文字（U+4E00–U+9FFF）。
final RegExp _cjk = RegExp(r'[\u4e00-\u9fff]');

/// 唯一性判定的归一化：小写 + 连续空白压成单空格 + 去首尾空白。
///
/// 只用于比较，不回写数据：同一句话多打一个空格、首字母大小写不同都算重复。
String _normalize(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('总数', () {
    test('三个集合各 150 条，聚合后正好 450 条', () {
      expect(kQuotesMastery.length, 150, reason: '能力集合条数');
      expect(kQuotesCharacter.length, 150, reason: '境界集合条数');
      expect(kQuotesSuccess.length, 150, reason: '成功集合条数');
      expect(kQuotes.length, 450, reason: '聚合后总数 = 150 × 3');
    });
  });

  group('逐条内容', () {
    test('中英都非空（同一 index 落在同一条上）', () {
      expect(kQuotes, isNotEmpty, reason: '列表为空会让本条断言空转');
      for (int i = 0; i < kQuotes.length; i++) {
        final Quote q = kQuotes[i];
        expect(q.en.trim(), isNotEmpty, reason: '第 $i 条的 en 为空');
        expect(q.zh.trim(), isNotEmpty, reason: '第 $i 条的 zh 为空');
      }
    });

    test('英文不含中文字符，中文至少含一个', () {
      expect(kQuotes, isNotEmpty, reason: '列表为空会让本条断言空转');
      for (int i = 0; i < kQuotes.length; i++) {
        final Quote q = kQuotes[i];
        expect(
          _cjk.hasMatch(q.en),
          isFalse,
          reason: '第 $i 条的 en 混入中文字符：${q.en}',
        );
        expect(
          _cjk.hasMatch(q.zh),
          isTrue,
          reason: '第 $i 条的 zh 没有任何中文字符（漏译？）：${q.zh}',
        );
      }
    });

    test('英文 20–200 字符，中文不超过 80 字符', () {
      expect(kQuotes, isNotEmpty, reason: '列表为空会让本条断言空转');
      for (int i = 0; i < kQuotes.length; i++) {
        final Quote q = kQuotes[i];
        expect(
          q.en.length,
          greaterThanOrEqualTo(20),
          reason: '第 $i 条的 en 过短（${q.en.length} 字符）：${q.en}',
        );
        expect(
          q.en.length,
          lessThanOrEqualTo(200),
          reason: '第 $i 条的 en 过长（${q.en.length} 字符）：${q.en}',
        );
        expect(
          q.zh.length,
          lessThanOrEqualTo(80),
          reason: '第 $i 条的 zh 过长（${q.zh.length} 字符）：${q.zh}',
        );
      }
    });
  });

  group('唯一性', () {
    test('英文归一化后唯一', () {
      final Set<String> uniqueEn = <String>{
        for (final Quote q in kQuotes) _normalize(q.en),
      };
      final Map<String, int> firstSeen = <String, int>{};
      for (int i = 0; i < kQuotes.length; i++) {
        final String key = _normalize(kQuotes[i].en);
        final int? duplicatedAt = firstSeen[key];
        expect(
          duplicatedAt,
          isNull,
          reason: '第 $i 条的 en 与第 $duplicatedAt 条重复：$key',
        );
        firstSeen[key] = i;
      }
      expect(
        uniqueEn.length,
        kQuotes.length,
        reason: 'en 去重后条数（${uniqueEn.length}）应等于总条数',
      );
    });

    test('中文归一化后唯一', () {
      final Set<String> uniqueZh = <String>{
        for (final Quote q in kQuotes) _normalize(q.zh),
      };
      final Map<String, int> firstSeen = <String, int>{};
      for (int i = 0; i < kQuotes.length; i++) {
        final String key = _normalize(kQuotes[i].zh);
        final int? duplicatedAt = firstSeen[key];
        expect(
          duplicatedAt,
          isNull,
          reason: '第 $i 条的 zh 与第 $duplicatedAt 条重复：$key',
        );
        firstSeen[key] = i;
      }
      expect(
        uniqueZh.length,
        kQuotes.length,
        reason: 'zh 去重后条数（${uniqueZh.length}）应等于总条数',
      );
    });
  });

  group('配额', () {
    test('三个 const 列表各自不少于 120 条', () {
      expect(
        kQuotesMastery.length,
        greaterThanOrEqualTo(120),
        reason: 'kQuotesMastery 现有 ${kQuotesMastery.length} 条',
      );
      expect(
        kQuotesCharacter.length,
        greaterThanOrEqualTo(120),
        reason: 'kQuotesCharacter 现有 ${kQuotesCharacter.length} 条',
      );
      expect(
        kQuotesSuccess.length,
        greaterThanOrEqualTo(120),
        reason: 'kQuotesSuccess 现有 ${kQuotesSuccess.length} 条',
      );
    });

    test('英文长句配额：≥100 字符不少于 40 条，≥150 字符不少于 20 条', () {
      final int enAtLeast100 =
          kQuotes.where((Quote q) => q.en.length >= 100).length;
      final int enAtLeast150 =
          kQuotes.where((Quote q) => q.en.length >= 150).length;
      expect(
        enAtLeast100,
        greaterThanOrEqualTo(40),
        reason: 'en ≥100 字符的条数（$enAtLeast100）不足 40',
      );
      expect(
        enAtLeast150,
        greaterThanOrEqualTo(20),
        reason: 'en ≥150 字符的条数（$enAtLeast150）不足 20',
      );
    });
  });
}
