// apps/desktop/test/shell_key_hints_test.dart
//
// Task 20（裁定 K1 / K2 / K3 / K8）守键条清单本身：
// ① **恰好 7 条**，顺序与原型一致（A1）；
// ② `Esc` 的来源写成事实，不再指向本仓里指不到的地方（A2）——
//    上一版注释写的是「`app.dart` 的 `DefaultShortcuts` + `ModalRoute` 的
//    `_DismissModalAction`」，本仓既没有 `DefaultShortcuts`，也没有那个私有类，
//    是一条**假引用**；
// ③ 7 条文案里不许出现原型那种「把这一行加进 / 拿出今日计划」的说法，
//    也不许出现 `Ctrl+1…6`（三项导航无落点 ⇒ 宣称到 6 就是假提示）（A11）。
//
// 判定口径：键条文案 = `kShellKeyHints` 这一份常量（键帽 + 说明），
// 底栏与右轨「快捷键」面板共用它，所以断言这一份就等于断言渲染出来的那 7 条。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/shell/key_bar.dart';

/// 键条源文件（纯文本断言用；测试的工作目录是包根目录）。
File _sourceFile() => File('lib/src/widgets/shell/key_bar.dart');

/// 7 条的键帽（顺序即渲染顺序）。
const List<List<String>> _expectedKeys = <List<String>>[
  <String>['Ctrl+N'],
  <String>['Ctrl+D'],
  <String>['←→'],
  <String>['Space'],
  <String>['Enter'],
  <String>['Esc'],
  <String>['Ctrl+1…3'],
];

/// 7 条的动作说明（顺序同上）。
const List<String> _expectedLabels = <String>[
  '＋ 手写一条',
  '打卡第一条未打习惯',
  '切日期',
  '勾选 / 取消勾选',
  '展开回填',
  '关闭弹层',
  '切页',
];

void main() {
  test('A1：键条恰好 7 条，键帽与说明逐条相等、顺序固定', () {
    expect(kShellKeyHints, hasLength(7));
    expect(
      kShellKeyHints.map((ShellKeyHint hint) => hint.keys).toList(),
      _expectedKeys,
      reason: '键帽顺序必须是 Ctrl+N / Ctrl+D / ←→ / Space / Enter / Esc / Ctrl+1…3',
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
    expect(kShellKeyHints.last.keys, <String>['Ctrl+1…3']);
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

  test('A11：7 条文案里没有「加进 / 拿出今日计划」式说法，也没有 Ctrl+1…6', () {
    for (final ShellKeyHint hint in kShellKeyHints) {
      for (final String key in hint.keys) {
        expect(key.contains('排入'), isFalse, reason: '键帽 $key 不许用原型那套说法');
        expect(key.contains('移出'), isFalse, reason: '键帽 $key 不许用原型那套说法');
        expect(
          key.contains('Ctrl+1…6'),
          isFalse,
          reason: '习惯 / 项目 / 设置三项无落点，只能宣称到 3',
        );
      }
      expect(hint.label.contains('排入'), isFalse);
      expect(hint.label.contains('移出'), isFalse);
      expect(hint.label.contains('Ctrl+1…6'), isFalse);
    }
    // 源文件里也不许留这种说法（注释同样会误导人）。
    final String src = _sourceFile().readAsStringSync();
    expect(src.contains('排入'), isFalse);
    expect(src.contains('移出'), isFalse);
    expect(src.contains('Ctrl+1…6'), isFalse);
  });
}
