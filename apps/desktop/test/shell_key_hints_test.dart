// apps/desktop/test/shell_key_hints_test.dart
//
// Task 20（裁定 K1 / K2 / K3 / K8）守键条清单本身：
// ① **恰好 10 条**，顺序与原型一致（A1；Task 56 起「项目」页落地，
//    `Ctrl+5` 有真实落点 ⇒ 从 7 条变 8 条，`Ctrl+1…3` 同时更正为 `Ctrl+1…4`；
//    Task 65 UI 半批起「目标」页落地，`Ctrl+6` 有真实落点 ⇒ 再变 9 条；
//    Task 72 补齐漏登的「人生蓝图」页，`Ctrl+7` 有真实落点 ⇒ 再变 10 条；
//    B16 左导航扩为 8 项 ⇒「切页」扩为 `Ctrl+1…8`；
//    B17 左导航回到 7 项（「习惯」出列、「学习」改称「学习管理」）⇒
//    「切页」收回 `Ctrl+1…7`，单条落点改为 `Ctrl+3` 蓝图 / `Ctrl+4` 目标 /
//    `Ctrl+5` 项目，条数仍 10）；
// ② `Esc` 的来源写成事实，不再指向本仓里指不到的地方（A2）——
//    上一版注释写的是「某宿主文件的 `DefaultShortcuts` + `ModalRoute` 的
//    `_DismissModalAction`」，本仓既没有 `DefaultShortcuts`，也没有那个私有类，
//    是一条**假引用**；
// ③ 10 条文案里不许出现原型那种「把这一行加进 / 拿出今日计划」的说法，
//    也不许出现 `Ctrl+1…3` / `Ctrl+1…4` / `Ctrl+1…5` / `Ctrl+1…6`（「切页」
//    覆盖 Ctrl+1…7；Ctrl+3 / Ctrl+4 / Ctrl+5 各有单条落点，任何合并写法都是假提示）（A11）。
//
// 判定口径：键条文案 = `kShellKeyHints` 这一份常量（键帽 + 说明），
// 底栏与右轨「快捷键」面板共用它，所以断言这一份就等于断言渲染出来的那 10 条。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';

/// 键条源文件（纯文本断言用；测试的工作目录是包根目录）。
File _sourceFile() => File('lib/src/widgets/shell/key_bar.dart');

/// 10 条的键帽（顺序即渲染顺序）。
const List<List<String>> _expectedKeys = <List<String>>[
  <String>['Ctrl+N'],
  <String>['Ctrl+D'],
  <String>['←→'],
  <String>['Space'],
  <String>['Enter'],
  <String>['Esc'],
  <String>['Ctrl+1…7'],
  <String>['Ctrl+3'],
  <String>['Ctrl+4'],
  <String>['Ctrl+5'],
];

/// 10 条的动作说明（顺序同上）。
const List<String> _expectedLabels = <String>[
  '＋ 手写一条',
  '打卡第一条未打习惯',
  '切日期',
  '勾选 / 取消勾选',
  '展开回填',
  '关闭弹层',
  '切页',
  '切到蓝图',
  '切到目标',
  '切到项目',
];

/// 「切页」只能覆盖 `Ctrl+1…7`：蓝图 / 目标 / 项目各有单条落点（`Ctrl+3` /
/// `Ctrl+4` / `Ctrl+5`），把其中任何一段并回区间都是假提示（A11 反向断言用）。
const List<String> _forbiddenRangeMerges = <String>[
  'Ctrl+1…3',
  'Ctrl+1…4',
  'Ctrl+1…5',
  'Ctrl+1…6',
];

void main() {
  test('A1：键条恰好 10 条，键帽与说明逐条相等、顺序固定', () {
    expect(kShellKeyHints, hasLength(10));
    expect(
      kShellKeyHints.map((ShellKeyHint hint) => hint.keys).toList(),
      _expectedKeys,
      reason: '键帽顺序必须是 Ctrl+N / Ctrl+D / ←→ / Space / Enter / Esc / '
          'Ctrl+1…7 / Ctrl+3 / Ctrl+4 / Ctrl+5',
    );
    expect(
      kShellKeyHints.map((ShellKeyHint hint) => hint.label).toList(),
      _expectedLabels,
      reason: '说明文案必须逐条相等，不许出现半实现的说法',
    );
  });

  test('A1：既有 4 条一条都不许少（键条不许删承诺）', () {
    final List<String> keys = <String>[
      for (final ShellKeyHint hint in kShellKeyHints) ...hint.keys,
    ];
    for (final String key in <String>['Ctrl+N', 'Ctrl+D', '←→', 'Esc']) {
      expect(keys, contains(key), reason: '既有键帽 $key 不许消失');
    }
    expect(kShellKeyHints.first.keys, <String>['Ctrl+N']);
  });

  test('A1：切页那条覆盖 Ctrl+1…7（日志 / 待办池 / 蓝图 / 目标 / 项目 / 学习管理 / 日历），蓝图是 Ctrl+3、目标是 Ctrl+4、项目是 Ctrl+5',
      () {
    expect(kShellKeyHints[6].keys, <String>['Ctrl+1…7']);
    expect(kShellKeyHints[6].label, '切页');
    expect(kShellKeyHints[7].keys, <String>['Ctrl+3']);
    expect(kShellKeyHints[7].label, '切到蓝图');
    expect(kShellKeyHints[8].keys, <String>['Ctrl+4']);
    expect(kShellKeyHints[8].label, '切到目标');
    expect(kShellKeyHints.last.keys, <String>['Ctrl+5']);
    expect(kShellKeyHints.last.label, '切到项目');
  });

  test('A2：Esc 的来源写成事实，不指本仓里指不到的地方', () {
    final String src = _sourceFile().readAsStringSync();
    expect(
      src.contains('DefaultShortcuts'),
      isFalse,
      reason: '本仓没有 `DefaultShortcuts`，写它就是假引用',
    );
    expect(
      src.contains('ModalRoute._DismissModalAction'),
      isFalse,
      reason: '框架没有这个私有类名，写它就是假引用',
    );
    expect(
      src.contains('app.dart'),
      isFalse,
      reason: 'Esc 的来源是框架的 `WidgetsApp` 默认快捷键，不是本仓某个文件',
    );
    // 事实写法必须在场：`WidgetsApp` 默认快捷键 `escape → DismissIntent`，
    // 弹层由 `ModalRoute` 处理 `DismissIntent` 关闭。
    expect(src.contains('WidgetsApp'), isTrue);
    expect(src.contains('DismissIntent'), isTrue);
    expect(src.contains('ModalRoute'), isTrue);
  });

  test('A11：10 条文案里没有「加进 / 拿出今日计划」式说法，也没有 Ctrl+1…3 / Ctrl+1…4 / Ctrl+1…5 / Ctrl+1…6',
      () {
    for (final ShellKeyHint hint in kShellKeyHints) {
      for (final String key in hint.keys) {
        expect(key.contains('排入'), isFalse, reason: '键帽 $key 不许用原型那套说法');
        expect(key.contains('移出'), isFalse, reason: '键帽 $key 不许用原型那套说法');
        for (final String merged in _forbiddenRangeMerges) {
          expect(
            key.contains(merged),
            isFalse,
            reason: '「切页」那条覆盖 Ctrl+1…7；蓝图 / 目标 / 项目各有单条落点'
                '（Ctrl+3 / Ctrl+4 / Ctrl+5），键帽 $key 不能合并成「$merged」',
          );
        }
      }
      expect(hint.label.contains('排入'), isFalse);
      expect(hint.label.contains('移出'), isFalse);
      for (final String merged in _forbiddenRangeMerges) {
        expect(
          hint.label.contains(merged),
          isFalse,
          reason: '「${hint.label}」这条不许写成合并区间「$merged」',
        );
      }
    }
    // 源文件里也不许留这种说法（注释同样会误导人）。
    final String src = _sourceFile().readAsStringSync();
    expect(src.contains('排入'), isFalse);
    expect(src.contains('移出'), isFalse);
    for (final String merged in _forbiddenRangeMerges) {
      expect(
        src.contains(merged),
        isFalse,
        reason: '源文件里不许出现合并写法「$merged」',
      );
    }
  });
}