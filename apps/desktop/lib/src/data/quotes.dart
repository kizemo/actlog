import 'quote.dart';
import 'quote_set_character.dart';
import 'quote_set_mastery.dart';
import 'quote_set_success.dart';

/// 全量警句库：能力（mastery）→ 境界（character）→ 成功（success）。
const List<Quote> kQuotes = <Quote>[
  ...kQuotesMastery,
  ...kQuotesCharacter,
  ...kQuotesSuccess,
];
