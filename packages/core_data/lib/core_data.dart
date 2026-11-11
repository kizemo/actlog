/// ActLog 数据访问层。
///
/// 本包是**纯 Dart**包（不依赖 Flutter），因此与 `core_domain` / `core_db`
/// 一起进入 Dart pub workspace，受 G1（静态分析）与 G2（单元测试）两道门禁
/// 保护。
///
/// 分层职责：
/// - `core_domain`：不依赖数据库的实体与校验；
/// - `core_db`：drift 表定义、迁移、账本写入器；
/// - `core_data`（本包）：P1 的业务规则（站会三段、双模式显示、心态失守）
///   与仓储层。UI 只调用本包的公开 API，不直接拼 SQL。
library;

export 'src/models.dart';
export 'src/mood.dart';
export 'src/priority.dart';
export 'src/repositories.dart';
export 'src/recurring.dart';
export 'src/standup.dart';
export 'src/support.dart';
export 'src/calendar.dart';
export 'src/day_stats.dart';
export 'src/calendar_summary.dart';