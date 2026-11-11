import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 这个测试唯一的价值是「接线证明」：apps/desktop 用 path 依赖指向
  // packages/ 下带 `resolution: workspace` 的纯 Dart 包时，能否正常解析并
  // 读到其中的规则。真正的业务规则单元测试在 packages/core_data/test 里，
  // 由 G2 门禁覆盖。
  test('app 能通过 path 依赖读到 core_data 的优先级展示规则', () {
    expect(
      PriorityDisplay.headerHint(PriorityDisplayMode.quadrant),
      'A 类 = Q1 + Q2',
    );
    expect(QuadrantStyle.of(Quadrant.q1).shortLabel, '立即做');
    expect(PriorityDisplay.labelFor(PriorityDisplayMode.abc), '未分级');
  });
}