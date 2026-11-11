/// core_domain —— 知行日志 ActLog 的领域模型层。
///
/// **硬性约束**：本包不得依赖 dart:io、flutter、drift 或任何 IO 框架。
/// 理由：领域模型是所有层的地基，必须能在纯 Dart VM 上独立单测；
/// 一旦它 import 了 IO，单元测试就会被环境绑死。
///
/// 唯一真源：`docs/schema_v1.sql`。
/// 本包的枚举取值、字段名必须与该文件逐字一致，
/// 门禁 G3 会比对二者。
library;

export 'src/entities.dart';
export 'src/enums.dart';
export 'src/recurring_task.dart';
export 'src/result_note.dart';
