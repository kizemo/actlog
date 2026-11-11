// =============================================================================
// core_db · 测试辅助：读取并解析权威 DDL（docs/schema_v1.sql）
// =============================================================================
// 只读工具，不含任何断言逻辑。
// =============================================================================

import 'dart:io';

/// 权威 DDL 的仓库相对路径。
const String schemaV1RelativePath = 'docs/schema_v1.sql';

/// 读取 docs/schema_v1.sql 全文。
///
/// 测试的工作目录是包目录（packages/core_db），因此按 ../ 逐级向上找。
String readSchemaV1Sql() {
  final candidates = <String>[
    schemaV1RelativePath,
    '../$schemaV1RelativePath',
    '../../$schemaV1RelativePath',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  throw StateError('找不到 $schemaV1RelativePath，试过：${candidates.join(', ')}');
}

/// 把 SQL 文件切成可执行语句（去掉 `--` 行注释）。
List<String> splitSqlStatements(String sql) {
  final withoutComments = sql
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('--'))
      .join('\n');
  return withoutComments
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// 从 CREATE TABLE 语句里抽出具名约束：名字 → 约束体（空白归一化）。
Map<String, String> parseNamedConstraints(String createSql) {
  final result = <String, String>{};
  final pattern = RegExp(r'CONSTRAINT\s+([A-Za-z_][A-Za-z0-9_]*)');
  for (final match in pattern.allMatches(createSql)) {
    final name = match.group(1)!;
    var index = match.end;
    while (index < createSql.length && createSql[index].trim().isEmpty) {
      index++;
    }
    final start = index;
    var depth = 0;
    var inString = false;
    while (index < createSql.length) {
      final char = createSql[index];
      if (char == "'") {
        inString = !inString;
      } else if (!inString) {
        if (char == '(') {
          depth++;
        } else if (char == ')') {
          if (depth == 0) {
            break;
          }
          depth--;
        }
      }
      index++;
    }
    result[name] = normalizeSql(createSql.substring(start, index));
  }
  return result;
}

/// 取某个具名 CHECK 约束里 `IN (...)` 的全部取值。
///
/// 找不到约束或约束里没有 IN 列表时抛 [StateError]（测试里等于红灯）。
Set<String> checkValues(String sql, String constraintName) {
  final start = sql.indexOf('CONSTRAINT $constraintName');
  if (start < 0) {
    throw StateError('schema_v1.sql 里找不到约束 $constraintName');
  }
  final segment = sql.substring(start);
  final nextConstraint = segment.indexOf('CONSTRAINT ', 1);
  final scope = nextConstraint < 0 ? segment : segment.substring(0, nextConstraint);

  final inMatch = RegExp(r'IN\s*\(([^)]*)\)').firstMatch(scope);
  if (inMatch == null) {
    throw StateError('约束 $constraintName 里没有 IN (...) 取值列表');
  }
  return RegExp(r"'([^']*)'")
      .allMatches(inMatch.group(1)!)
      .map((m) => m.group(1)!)
      .toSet();
}

/// 空白归一化：连续空白折叠成一个空格，并去掉「逗号前空格」。
String normalizeSql(String sql) {
  return sql
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s+,'), ',')
      .trim();
}
