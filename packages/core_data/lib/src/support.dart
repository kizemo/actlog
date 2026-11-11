// =============================================================================
// core_data · 基础设施：ID 生成、时钟、日历日工具
// =============================================================================

import 'dart:math';
import 'dart:typed_data';

/// 生成 UUIDv7（RFC 9562）的 36 字符文本形式。
///
/// 为什么必须是 v7 而不是 v4：前 48 位是 Unix 毫秒时间戳，
/// 因此**按主键字典序排序 = 按创建时间排序**。这正好满足 SQLite 文本主键
/// 需要的索引局部性 —— 新插入的行总落在 B-tree 尾部，避免随机主键导致的
/// 页分裂；同时同步端可以直接用 id 做「创建时间」的粗略排序。
///
/// [now] 与 [random] 只供测试注入，生产调用一律留空。
String uuidV7({DateTime? now, Random? random}) {
  final rng = random ?? Random.secure();
  final millis = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final bytes = Uint8List(16);

  // 前 6 字节 = 48 位毫秒时间戳（大端）。
  bytes[0] = (millis ~/ 0x10000000000) & 0xFF;
  bytes[1] = (millis ~/ 0x100000000) & 0xFF;
  bytes[2] = (millis ~/ 0x1000000) & 0xFF;
  bytes[3] = (millis ~/ 0x10000) & 0xFF;
  bytes[4] = (millis ~/ 0x100) & 0xFF;
  bytes[5] = millis & 0xFF;

  // 后 10 字节 = 随机。
  for (var i = 6; i < 16; i++) {
    bytes[i] = rng.nextInt(256);
  }

  // 版本号 7。
  bytes[6] = (bytes[6] & 0x0F) | 0x70;
  // 变体 10xx（RFC 9562 要求）。
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  final hex = StringBuffer();
  for (var i = 0; i < 16; i++) {
    hex.write(bytes[i].toRadixString(16).padLeft(2, '0'));
  }
  final s = hex.toString();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
      '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

/// 当前时刻（Unix 毫秒）。
///
/// 全项目只有这一处允许直接调用 [DateTime.now]；其余代码一律接收注入的时钟值，
/// 这样测试可以断言「同一时刻写入的两行 updatedAt 相等」这类性质。
int nowMillis() => DateTime.now().millisecondsSinceEpoch;

/// 把 [DateTime] 转成日历日字符串 `YYYY-MM-DD`（本地时区）。
String isoDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// 今天的日历日字符串。
String today([DateTime? now]) => isoDate(now ?? DateTime.now());

/// 把日历日字符串解析为本地时区当天零点。
///
/// 非法输入返回 null（不抛异常）—— 与枚举 `fromCode` 的约定一致：
/// 同源数据可能来自更高版本 schema，解析层不该成为崩溃点。
DateTime? parseIsoDate(String raw) {
  final parts = raw.split('-');
  if (parts.length != 3) {
    return null;
  }
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) {
    return null;
  }
  if (m < 1 || m > 12 || d < 1 || d > 31) {
    return null;
  }
  final parsed = DateTime(y, m, d);
  // 拒绝 2026-02-30 这类被 DateTime 静默进位的日期。
  if (parsed.year != y || parsed.month != m || parsed.day != d) {
    return null;
  }
  return parsed;
}

/// 在日历日上加减天数，返回新的日历日字符串。
///
/// 非法输入原样返回 —— 同样是「解析层不崩溃」的约定。
String shiftIsoDate(String date, int days) {
  final parsed = parseIsoDate(date);
  if (parsed == null) {
    return date;
  }
  return isoDate(DateTime(parsed.year, parsed.month, parsed.day + days));
}

/// 昨天（相对 [date]）。
String previousIsoDate(String date) => shiftIsoDate(date, -1);