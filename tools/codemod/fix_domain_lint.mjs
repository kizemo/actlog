// 一次性 codemod：修 core_domain 的两类 lint
//   1. `implements SyncEntity` -> `extends SyncEntity`
//      原因：implements 要求子类实现接口的**全部**成员，包括具体 getter isDeleted；
//            extends 才会继承具体实现。
//   2. 枚举构造器与 fromCode 静态方法补文档注释（public_member_api_docs）
//
// 用法：node tools/codemod/fix_domain_lint.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const FILES = [
  'F:/soft/00selfmade/practilog/packages/core_domain/lib/src/entities.dart',
  'F:/soft/00selfmade/practilog/packages/core_domain/lib/src/enums.dart',
];

let totalChanged = 0;

for (const file of FILES) {
  let text = readFileSync(file, 'utf8');
  const before = text;

  // --- 1. implements -> extends ---
  text = text.replace(/implements SyncEntity/g, 'extends SyncEntity');

  // --- 2. 枚举构造器补文档 ---
  text = text.replace(
    /(^|\n)(  const (\w+)\((?:this\.)?[^)]*\);)/g,
    (m, pre, whole, name) => {
      // 前一行已是 /// 注释则跳过
      const idx = text.indexOf(whole, text.indexOf(pre) + pre.length);
      const prevLineStart = text.lastIndexOf('\n', idx - 1);
      const prevLine = text.slice(prevLineStart + 1, idx);
      if (prevLine.trim().startsWith('///')) return m;
      return `${pre}  /// 构造 [${name}] 常量。\n${pre}${whole}`;
    },
  );

  // --- 3. fromCode 静态方法补文档 ---
  text = text.replace(
    /(^|\n)(  static \w+\? fromCode\(String\? code\) \{)/g,
    (m, pre, whole) => {
      const idx = text.indexOf(whole, text.indexOf(pre) + pre.length);
      const prevLineStart = text.lastIndexOf('\n', idx - 1);
      const prevLine = text.slice(prevLineStart + 1, idx);
      if (prevLine.trim().startsWith('///')) return m;
      return `${pre}  /// 从数据库存储值解析。\n${pre}  ///\n${pre}  /// 无法识别时返回 null 而**不抛异常** —— 同步对端可能来自更高版本的\n${pre}  /// schema，抛异常会导致整个同步批次失败。\n${pre}${whole}`;
    },
  );

  if (text !== before) {
    writeFileSync(file, text, 'utf8');
    totalChanged++;
    console.log(`changed: ${file}`);
  } else {
    console.log(`unchanged: ${file}`);
  }
}
console.log(`done, ${totalChanged} file(s) changed`);
