// =============================================================================
// Task 74 · 批次 B8 · W2：共享目标表单 / 删除确认 / 行尾操作列 用例
// =============================================================================
// 判据（派工书 `docs/b82-dispatch-w2.md`）：
//  1. 共享组件 `goal_form_dialog.dart` 的 8 个 ValueKey 与 W1 契约逐字一致；
//  2. 新建态空标题 ⇒ 「保存」置灰（不写库，也不允许提交空标题）；
//  3. 取消 ⇒ 返回 null（调用方不得写库）；
//  4. 编辑态按库里既有值预填，保存回传的是毫秒而不是字符串；
//  5. 删除确认框：取消 = false，确认 = true；
//  6. 行尾操作列两个键由调用方给定、回调各自独立。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goals/goal_form_dialog.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// W1 已落地的 8 个表单键（本棒抽成共享组件后必须逐字保留）。
const List<String> _formKeys = <String>[
  'goal-blueprint-form-title',
  'goal-blueprint-form-note',
  'goal-blueprint-form-keywords',
  'goal-blueprint-form-domain',
  'goal-blueprint-form-horizon',
  'goal-blueprint-form-due',
  'goal-blueprint-form-cancel',
  'goal-blueprint-form-save',
];

/// 编辑用例的既有目标：六个字段全给值，用来验预填。
final GoalRow _existing = GoalRow(
  id: 'goal-existing-1',
  kind: GoalKind.monthly,
  title: '旧标题',
  status: GoalStatus.active,
  periodStart: 1761955200000,
  createdAt: 1761955200000,
  updatedAt: 1761955200000,
  note: '旧备注',
  keywords: 'a,b',
  domain: 'career',
  horizon: GoalHorizon.mid,
  dueDate: DateTime(2026, 12, 31).millisecondsSinceEpoch,
);

/// 把共享组件挂起来的宿主：两个按钮各自打开一个对话框，把结果写到 Text 上。
class _Host extends StatefulWidget {
  const _Host({this.existing});

  final GoalRow? existing;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  GoalFormResult? _form;
  bool? _deleted;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: const ValueKey<String>('host-open'),
            onPressed: () async {
              final GoalFormResult? form = await showGoalFormDialog(
                context,
                t: t,
                existing: widget.existing,
              );
              setState(() => _form = form);
            },
            child: const Text('open'),
          ),
          TextButton(
            key: const ValueKey<String>('host-confirm'),
            onPressed: () async {
              final bool confirmed = await confirmDeleteGoal(context, t);
              setState(() => _deleted = confirmed);
            },
            child: const Text('confirm'),
          ),
          Text(_formText, key: const ValueKey<String>('host-result')),
          Text(
            'deleted:${_deleted ?? 'none'}',
            key: const ValueKey<String>('host-deleted'),
          ),
        ],
      ),
    );
  }

  String get _formText {
    final GoalFormResult? form = _form;
    if (form == null) {
      return 'result:null';
    }
    return 'result:${form.title}|${form.note}|${form.keywords}|'
        '${form.domain}|${form.horizon.name}|${form.dueDate}';
  }
}

/// 挂起宿主（真 MaterialApp + l10nScope，与页面用例同一套壳）。
Future<void> _pumpHost(WidgetTester tester, {GoalRow? existing}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(_Host(existing: existing), language: AppLanguage.zh),
    ),
  );
  await tester.pumpAndSettle();
}

/// 读一个 TextField 的当前文本（表单预填的判据）。
String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey<String>(key))).controller!.text;

/// 读宿主导出的结果串。
String _resultText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey<String>('host-result'))).data!;

void main() {
  testWidgets('新建态：8 个键齐备，空标题时保存置灰，取消不产出结果', (
    WidgetTester tester,
  ) async {
    await _pumpHost(tester);

    await tester.tap(find.byKey(const ValueKey<String>('host-open')));
    await tester.pumpAndSettle();

    for (final String key in _formKeys) {
      expect(
        find.byKey(ValueKey<String>(key)),
        findsOneWidget,
        reason: 'W1 契约键 $key 必须仍然存在（共享化不得撕毁既有用例）',
      );
    }

    // 空标题 ⇒ 保存不可点。
    final TextButton save = tester.widget<TextButton>(
      find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
    );
    expect(save.onPressed, isNull, reason: '标题为空时不允许提交表单');

    await tester.enterText(
      find.byKey(const ValueKey<String>('goal-blueprint-form-title')),
      '写周报',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
          )
          .onPressed,
      isNotNull,
      reason: '标题非空后保存必须恢复可点',
    );

    // 取消 ⇒ null（调用方据此不写库）。
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-cancel')),
    );
    await tester.pumpAndSettle();
    expect(_resultText(tester), 'result:null');
  });

  testWidgets('编辑态：既有值全部预填，保存回传毫秒与档位', (WidgetTester tester) async {
    await _pumpHost(tester, existing: _existing);

    await tester.tap(find.byKey(const ValueKey<String>('host-open')));
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'goal-blueprint-form-title'), '旧标题');
    expect(_fieldText(tester, 'goal-blueprint-form-note'), '旧备注');
    expect(_fieldText(tester, 'goal-blueprint-form-keywords'), 'a,b');
    expect(
      _fieldText(tester, 'goal-blueprint-form-due'),
      '2026-12-31',
      reason: '期限毫秒必须以 YYYY-MM-DD 预填，否则用户改别的字段就会把期限写坏',
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey<String>('goal-blueprint-form-domain')),
          )
          .initialValue,
      'career',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-form-save')),
    );
    await tester.pumpAndSettle();

    final List<String> parts = _resultText(tester)
        .substring('result:'.length)
        .split('|');
    expect(parts[0], '旧标题');
    expect(parts[1], '旧备注');
    expect(parts[2], 'a,b');
    expect(parts[3], 'career');
    expect(parts[4], 'mid');
    expect(parts[5], '${DateTime(2026, 12, 31).millisecondsSinceEpoch}');
  });

  testWidgets('删除确认框：取消返回 false，确认返回 true', (WidgetTester tester) async {
    await _pumpHost(tester);

    // ① 取消。
    await tester.tap(find.byKey(const ValueKey<String>('host-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-delete-cancel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('goal-blueprint-delete-confirm')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-delete-cancel')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey<String>('host-deleted')))
          .data,
      'deleted:false',
    );

    // ② 确认。
    await tester.tap(find.byKey(const ValueKey<String>('host-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('goal-blueprint-delete-confirm')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey<String>('host-deleted')))
          .data,
      'deleted:true',
    );
  });

  testWidgets('行尾操作列：两个键由调用方给定，回调各自独立', (WidgetTester tester) async {
    int edits = 0;
    int deletes = 0;

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(DensityProfile.comfortable),
        home: l10nScope(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: GoalRowActions(
                  editKey: 'row-edit-1',
                  deleteKey: 'row-delete-1',
                  onEdit: () => edits += 1,
                  onDelete: () => deletes += 1,
                  t: AppLocalizations.of(context),
                ),
              ),
            ),
          ),
          language: AppLanguage.zh,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(GoalRowActions.width, 56, reason: '表头预留列与行尾按钮组必须同宽');

    await tester.tap(find.byKey(const ValueKey<String>('row-edit-1')));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(deletes, 0);

    await tester.tap(find.byKey(const ValueKey<String>('row-delete-1')));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(edits, 1);
  });
}