// packages/core_domain/test/result_note_test.dart
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  test('规范文案能反解回三段', () {
    final note = ResultNote.parse('[结论]按时完成 | [原因]预估不足 | [下一步]周四上午做完');
    expect(note.parsed, isTrue);
    expect(note.outcome, '按时完成');
    expect(note.reason, '预估不足');
    expect(note.nextStep, '周四上午做完');
  });

  test('编码顺序固定：结论 → 原因 → 下一步', () {
    const note = ResultNote(
      outcome: '按时完成',
      reason: '预估不足',
      nextStep: '周四上午做完',
    );
    expect(note.encoded, '[结论]按时完成 | [原因]预估不足 | [下一步]周四上午做完');
  });

  test('缺段省略、顺序不变', () {
    const note = ResultNote(outcome: '按时完成', nextStep: '继续');
    expect(note.encoded, '[结论]按时完成 | [下一步]继续');
  });

  test('自由文本解析失败时降级为只读纯文本，原文不丢', () {
    final note = ResultNote.parse('随手写的一段话');
    expect(note.parsed, isFalse);
    expect(note.rawText, '随手写的一段话');
    expect(note.encoded, '随手写的一段话');
    final padded = ResultNote.parse('   随手写的一段话   ');
    expect(padded.rawText, '随手写的一段话');
    expect(padded.encoded, '随手写的一段话');
  });

  test('顺序错乱 / 重复标签 / 超长文本都算解析失败', () {
    expect(ResultNote.parse('[下一步]甲 | [结论]乙').parsed, isFalse);
    expect(ResultNote.parse('[结论]甲 | [结论]乙').parsed, isFalse);
    expect(ResultNote.parse('[结论]${'x' * 41}').parsed, isFalse);
  });

  test('空串是空文案', () {
    expect(ResultNote.parse('   ').isEmpty, isTrue);
  });

  test('缺段也能反解回结构（encode → parse 往返一致）', () {
    const cases = <ResultNote>[
      ResultNote(outcome: '按时完成'),
      ResultNote(outcome: '按时完成', nextStep: '继续'),
      ResultNote(reason: '预估不足'),
      ResultNote(reason: '预估不足', nextStep: '继续'),
      ResultNote(nextStep: '继续'),
    ];
    for (final note in cases) {
      final parsed = ResultNote.parse(note.encoded);
      expect(parsed.parsed, isTrue, reason: note.encoded);
      expect(parsed.encoded, note.encoded, reason: note.encoded);
    }
  });

  test('文本含竖线或方括号判为解析失败', () {
    expect(ResultNote.parse('[结论]甲|乙').parsed, isFalse);
    expect(ResultNote.parse('[结论]甲[乙]').parsed, isFalse);
    expect(ResultNote.parse('[结论]甲 | 乙').parsed, isFalse);
  });

  test('text 长度上界：恰好 40 字符通过、41 字符失败', () {
    expect(ResultNote.parse('[结论]${'x' * 40}').parsed, isTrue);
    expect(ResultNote.parse('[结论]${'x' * 41}').parsed, isFalse);
  });

  test('长度按字符计：40 个 emoji 通过（不是 40 个 UTF-16 码元）', () {
    expect(ResultNote.parse('[下一步]${'😀' * 40}').parsed, isTrue);
    expect(ResultNote.parse('[下一步]${'😀' * 41}').parsed, isFalse);
  });

  test('text 含换行仍可反解（spec 只禁竖线与方括号）', () {
    final note = ResultNote.parse('[结论]甲\n乙');
    expect(note.parsed, isTrue);
    expect(note.outcome, '甲\n乙');
  });

  test('中间缺「结论」的两段（原因 + 下一步）也算合法子序列', () {
    const note = ResultNote(reason: '预估不足', nextStep: '继续');
    expect(note.encoded, '[原因]预估不足 | [下一步]继续');
    final parsed = ResultNote.parse(note.encoded);
    expect(parsed.parsed, isTrue);
    expect(parsed.reason, '预估不足');
    expect(parsed.nextStep, '继续');
  });

  test('空文案：编码为空串、isEmpty 为真、wellFormed 为真', () {
    const note = ResultNote();
    expect(note.encoded, '');
    expect(note.isEmpty, isTrue);
    expect(note.wellFormed, isTrue);
    expect(const ResultNote(outcome: '   ').encoded, '');
    expect(const ResultNote(outcome: ' a ').encoded, '[结论]a');
  });

  test('解析失败但有原文时不算空文案', () {
    final note = ResultNote.parse('随手写的一段话');
    expect(note.parsed, isFalse);
    expect(note.isEmpty, isFalse);
  });

  test('非法文本构造出来的文案不 wellFormed（落库前须拦截）', () {
    expect(const ResultNote(outcome: '按时完成').wellFormed, isTrue);
    expect(const ResultNote(outcome: 'a|b').wellFormed, isFalse);
    expect(ResultNote(outcome: 'x' * 41).wellFormed, isFalse);
    expect(ResultNote.parse('[结论]甲|乙').parsed, isFalse);
    expect(ResultNote.parse(const ResultNote(outcome: 'a|b').encoded).parsed, isFalse);
    expect(ResultNote.parse(ResultNote(outcome: 'x' * 41).encoded).parsed, isFalse);
    expect(ResultNote.parse(const ResultNote(outcome: 'a|b').encoded).rawText, '[结论]a|b');
  });
}
