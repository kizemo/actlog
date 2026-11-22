/// A single bilingual quote rendered on the Today page.
///
/// Both fields are required and non-empty. [en] must contain no CJK
/// characters and stay under 200 characters; [zh] must contain at least
/// one CJK character and stay under 80 characters. Uniqueness is enforced
/// by the data test, not by this type.
class Quote {
  const Quote({required this.en, required this.zh});

  /// The English sentence.
  final String en;

  /// The Chinese translation of [en].
  final String zh;
}