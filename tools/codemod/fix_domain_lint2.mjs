// 一次性 codemod（第二轮）：修 core_domain 剩余 lint
//   1. 单行 if 语句 -> 大括号 + 换行（always_put_control_body_on_new_line）
//      例：if (q.code == code) return q;
//        -> if (q.code == code) {\n  return q;\n}
//   2. 枚举里缺文档的 `final String code;` / `final String label;` 补注释
//
// 用法：node tools/codemod/fix_domain_lint2.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const FILES = [
  'F:/soft/00selfmade/practilog/packages/core_domain/lib/src/entities.dart',
  'F:/soft/00selfmade/practilog/packages/core_domain/lib/src/enums.dart',
];

const CODE_DOC = '  /// 存储到数据库的取值，与 schema 的 CHECK 约束一致。\n';
const LABEL_DOC = '  /// 中文显示名。\n';

for (const file of FILES) {
  let text = readFileSync(file, 'utf8');
  const before = text;

  // --- 1. 单行 if -> 大括号 ---
  // ⚠️ 上一版只匹配 `if (cond) return ...;`，漏掉了 throw 和方法调用形式
  //    （如 `if (x) throw DomainValidationException(...)`、`if (v) out.add(v);`）。
  //    这里放宽成「语句体内不含分号」的通用单行语句。
  text = text.replace(
    /^(\s*)if \((.+?)\) ([^;{}]+;)$/gm,
    (m, indent, cond, stmt) => `${indent}if (${cond}) {\n${indent}  ${stmt}\n${indent}}`,
  );

  // --- 2. 补 code/label 文档 ---
  const lines = text.split('\n');
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const prev = i > 0 ? lines[i - 1].trim() : '';
    if (/^  final String code;$/.test(line) && !prev.startsWith('///')) {
      out.push(CODE_DOC.trimEnd());
    } else if (/^  final String label;$/.test(line) && !prev.startsWith('///')) {
      out.push(LABEL_DOC.trimEnd());
    }
    out.push(line);
  }
  text = out.join('\n');

  if (text !== before) {
    writeFileSync(file, text, 'utf8');
    console.log(`changed: ${file}`);
  } else {
    console.log(`unchanged: ${file}`);
  }
}
console.log('done');
