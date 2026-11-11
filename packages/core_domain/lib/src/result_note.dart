// packages/core_domain/lib/src/result_note.dart
/// 回填文案的三种标签。
///
/// 顺序固定为「结论 → 原因 → 下一步」，缺段省略、顺序不变（spec §6.1）。
enum ResultNoteLabel {
  /// 结论。
  outcome('结论'),

  /// 原因。
  reason('原因'),

  /// 下一步。
  nextStep('下一步');

  /// 创建标签枚举值。
  const ResultNoteLabel(this.label);

  /// 写库时使用的标签文本。
  ///
  /// 仅作编码前缀（如 `[结论]`），**不可**当作统计维度使用 ——
  /// spec §6.1 的「结论分布」统计的是段内文本，不是段名。
  final String label;
}

/// 规范回填文案（spec §6.1）。
///
/// 文法：`result_note := segment (" | " segment)*`，`segment := "[" label "]" text`，
/// `text` 长度 1..40（按 Unicode 码点计）且禁止包含 `|` `[` `]`。
///
/// 解析失败（自由文本 / 顺序错乱 / 标签重复 / 超长 / 非法字符）时**整体降级**为
/// [rawText]：调用方据此渲染只读纯文本 + 「重新结构化」按钮，
/// 绝不丢数据、绝不猜。
///
/// **本类不校验构造入参**：构造器接受任意字符串；若段内文本违反上述文法
/// （超过 [maxTextLength] 或含禁止字符），[encoded] 产出的串将**无法**被
/// [ResultNote.parse] 还原成结构化文案 —— 落库前调用方必须自行校验 [wellFormed]。
final class ResultNote {
  /// 构造一段规范文案。
  const ResultNote({
    this.outcome = '',
    this.reason = '',
    this.nextStep = '',
  }) : rawText = '',
       parsed = true;

  const ResultNote._raw(this.rawText)
    : outcome = '',
      reason = '',
      nextStep = '',
      parsed = false;

  /// 单段文本的最大字符数（spec §6.1：text 长度 1..40）。
  static const int maxTextLength = 40;

  /// 单段文本禁止包含的字符（spec §6.1）。
  static const List<String> forbiddenTextChars = <String>['|', '[', ']'];

  static final RegExp _segment = RegExp(
    r'^\[(结论|原因|下一步)\](.+)$',
    dotAll: true,
  );

  /// 判断单段文本是否满足 spec §6.1 的 text 约束。
  ///
  /// 规则：去掉首尾空白后非空、长度不超过 [maxTextLength]（按 Unicode 码点计）、
  /// 不含 [forbiddenTextChars] 中的任何字符。
  static bool isValidText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.runes.length > maxTextLength) {
      return false;
    }
    for (final char in forbiddenTextChars) {
      if (trimmed.contains(char)) {
        return false;
      }
    }
    return true;
  }

  /// 结论段文本。
  final String outcome;

  /// 原因段文本。
  final String reason;

  /// 下一步段文本。
  final String nextStep;

  /// 解析失败时的原始文本（已去掉首尾空白）；解析成功时为空串。
  final String rawText;

  /// 是否解析成规范结构。
  final bool parsed;

  /// 三段文本是否都满足 spec §6.1 的 text 约束。
  ///
  /// 为 `false` 时 [encoded] 产出的串**不能**被 [ResultNote.parse] 还原，
  /// 落库会导致下次打开时降级为自由文本（芯片态不可恢复）。
  /// 缺省的段（文本为空）不算违规。
  ///
  /// 解析失败（[parsed] 为 `false`）时三段文本为空、本值恒为 `true`；
  /// 此时 [encoded] 原样返回 [rawText]，其本身不可被还原为结构 —— 这是
  /// spec §6.1「反解失败 ⇒ 纯文本只读」的预期形态，不是校验通过信号。
  bool get wellFormed =>
      (outcome.trim().isEmpty || isValidText(outcome)) &&
      (reason.trim().isEmpty || isValidText(reason)) &&
      (nextStep.trim().isEmpty || isValidText(nextStep));

  /// 解析一段原文。
  factory ResultNote.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const ResultNote();
    }

    final segments = <ResultNoteLabel, String>{};

    for (final part in trimmed.split(' | ')) {
      final match = _segment.firstMatch(part);
      if (match == null) {
        return ResultNote._raw(trimmed);
      }
      final label = switch (match.group(1)) {
        '结论' => ResultNoteLabel.outcome,
        '原因' => ResultNoteLabel.reason,
        '下一步' => ResultNoteLabel.nextStep,
        _ => null,
      };
      if (label == null) {
        return ResultNote._raw(trimmed);
      }
      final text = match.group(2)!.trim();
      if (!isValidText(text)) {
        return ResultNote._raw(trimmed);
      }
      if (segments.containsKey(label)) {
        return ResultNote._raw(trimmed);
      }
      segments[label] = text;
    }

    // 顺序必须是「结论 → 原因 → 下一步」的子序列：缺段可省，但相对顺序不得错乱。
    const expected = ResultNoteLabel.values;
    var lastIndex = -1;
    for (final label in segments.keys) {
      final index = expected.indexOf(label);
      if (index <= lastIndex) {
        return ResultNote._raw(trimmed);
      }
      lastIndex = index;
    }

    return ResultNote(
      outcome: segments[ResultNoteLabel.outcome] ?? '',
      reason: segments[ResultNoteLabel.reason] ?? '',
      nextStep: segments[ResultNoteLabel.nextStep] ?? '',
    );
  }

  /// 编码成写库文本。
  ///
  /// 解析失败时原样返回 [rawText]（去掉首尾空白后的原文，不丢内容、不擅自改写）。
  ///
  /// 解析成功时按「结论 → 原因 → 下一步」拼装、缺段省略（纯空白段按缺段处理）。
  /// 若 [wellFormed] 为 `false`，产出的串无法被 [ResultNote.parse] 还原 ——
  /// 调用方落库前必须自行校验。
  String get encoded {
    if (!parsed) {
      return rawText;
    }
    final parts = <String>[];
    if (outcome.trim().isNotEmpty) {
      parts.add('[${ResultNoteLabel.outcome.label}]${outcome.trim()}');
    }
    if (reason.trim().isNotEmpty) {
      parts.add('[${ResultNoteLabel.reason.label}]${reason.trim()}');
    }
    if (nextStep.trim().isNotEmpty) {
      parts.add('[${ResultNoteLabel.nextStep.label}]${nextStep.trim()}');
    }
    return parts.join(' | ');
  }

  /// 是否为空文案。
  bool get isEmpty =>
      parsed
          ? outcome.trim().isEmpty &&
                reason.trim().isEmpty &&
                nextStep.trim().isEmpty
          : rawText.trim().isEmpty;
}
