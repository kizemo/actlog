// apps/desktop/test/task63_w7_l10n_test.dart
//
// Task 63 · 批次二 W7（结果撰写 + 待办池）的 l10n 守门测试。
//
// §47.3 四条判据逐条落地：
//   ① 只断**字面量**，绝不 `find.text(l10n.xxx)` 同义反复 —— 那样改错 zh 也照样绿；
//   ② zh / en 双态各断各自文案（不是「断一个、另一个靠 it 不跑」）；
//   ③ 用例名保留中文，基线只增不减（本文件只新增，不改既有用例）；
//   ④ en 阴性对照 ≥1 处（en 态不许再看到中文）＋ en 插值格式随 locale 变 ≥1 处。
//
// 另钉一条**产品事实**：三段芯片（21 条「按时完成 / 预估不足 / 明天继续 …」）
// 是落库短语，**不随界面语言变**；规范文案的前缀（`[结论]` / `[原因]` / `[下一步]`）
// 同理属于数据格式。二者都在 en 态下保持中文，这是设计而非漏翻。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/todo_pool_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/outcome_composer.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';

/// 池子页要真库 + 真仓储；固定今天与选中日。
final class _PoolHarness {
  _PoolHarness._(this.container);

  final ProviderContainer container;

  static _PoolHarness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task63-w7-l10n-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // LIFO ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _PoolHarness._(container);
  }

  /// 裸挂池子页本身（不经 LedgerShell，避免导航项里的「待办池」撞页标题）。
  Future<void> mount(WidgetTester tester, {AppLanguage language = AppLanguage.zh}) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nScope(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: TodoPoolPage()),
            ),
          ),
          language: language,
        ),
      ),
    );
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：卸掉界面放掉 drift 流订阅。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Widget _composer(String initial, void Function(String, {required bool markDone}) onSubmit) =>
    Scaffold(body: OutcomeComposer(initial: initial, onSubmit: onSubmit));

void main() {
  group('结果撰写（OutcomeComposer）', () {
    testWidgets('zh 态：三段标题与两个按钮都出中文字面量', (tester) async {
      await pumpL10n(tester, _composer('', (String _, {required bool markDone}) {}));

      expect(find.text('结论'), findsOneWidget);
      expect(find.text('原因'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
      expect(find.text('只存进展'), findsOneWidget);
      // 「完成」是按钮；四个含「完成」的芯片是不同全串，不会撞上。
      expect(find.text('完成'), findsOneWidget);
    });

    testWidgets('zh 态：反解失败时给出「重新结构化」与「取消」', (tester) async {
      await pumpL10n(tester, _composer('随手写的一段话', (String _, {required bool markDone}) {}));

      expect(find.text('随手写的一段话'), findsOneWidget);
      expect(find.text('重新结构化'), findsOneWidget);
      // 芯片行的「取消」此处不渲染 ⇒ 恰好一个。
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('按时完成'), findsNothing);
    });

    testWidgets('en 态：三段标题与按钮出英文，且不再出现中文（阴性对照）', (tester) async {
      await pumpL10n(
        tester,
        _composer('', (String _, {required bool markDone}) {}),
        language: AppLanguage.en,
      );

      expect(find.text('Outcome'), findsOneWidget);
      expect(find.text('Reason'), findsOneWidget);
      expect(find.text('Next step'), findsOneWidget);
      expect(find.text('Save progress only'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // 阴性对照：en 态不许残留这四条中文。
      expect(find.text('结论'), findsNothing);
      expect(find.text('原因'), findsNothing);
      expect(find.text('只存进展'), findsNothing);
      expect(find.text('完成'), findsNothing);
    });

    testWidgets('en 态：反解失败的两个按钮出英文', (tester) async {
      await pumpL10n(
        tester,
        _composer('随手写的一段话', (String _, {required bool markDone}) {}),
        language: AppLanguage.en,
      );

      expect(find.text('Re-structure'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('重新结构化'), findsNothing);
      expect(find.text('取消'), findsNothing);
    });

    testWidgets('en 态：落库值不翻译、只映射显示层（芯片出英文，编码仍是 [结论]）', (tester) async {
      String? captured;
      bool? markedDone;
      await pumpL10n(
        tester,
        _composer('[结论]按时完成', (String encoded, {required bool markDone}) {
          captured = encoded;
          markedDone = markDone;
        }),
        language: AppLanguage.en,
      );

      // 21 条落库短语禁迁：落库值与编码里仍是中文，否则历史数据反解全会断；
      // 但芯片**显示**走 OutcomeComposer.displayLabel 映射成英文（纯显示层映射）。
      expect(find.text('Completed on time'), findsOneWidget);
      expect(
        find.text('按时完成'),
        findsNothing,
        reason: '阴性对照：显示层必须真的翻译过，别在 en 界面漏出落库中文',
      );
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(captured, '[结论]按时完成');
      expect(markedDone, isTrue);
    });
  });

  group('待办池（六列真值）', () {
    test('zh 逐字保留 + en 各自不同 + 插值格式随 locale 变', () {
      final AppLocalizations zh = AppLocalizations.forLanguage(AppLanguage.zh);
      final AppLocalizations en = AppLocalizations.forLanguage(AppLanguage.en);

      // zh 必须逐字等于迁移前的字面量（全角 ＋、全角括号、句末句号）。
      expect(zh.dialogPoolTitle, '待办池');
      expect(zh.dialogPoolNew, '＋ 新建待办');
      expect(zh.dialogPoolTitleHint, '待办标题（必填）');
      expect(zh.dialogPoolStartHint, '起始 09:15');
      expect(zh.dialogPoolDueHint, '到期 yyyy-MM-dd');
      expect(zh.dialogPoolColPriority, '优先级');
      expect(zh.dialogPoolColEst, '预估');
      expect(zh.dialogPoolColQuadrant, '象限');
      expect(zh.dialogPoolColDue, '到期');
      expect(zh.dialogPoolColAction, '动作');
      expect(zh.dialogPoolAddToToday, '加入主页计划');
      expect(zh.dialogPoolStartInvalid, '起始时间要填 HH:mm，或留空');
      expect(zh.dialogPoolEmptyLong, '待办池是空的：先在上面新建一条，再捞到选中日。');

      expect(en.dialogPoolTitle, 'Todo pool');
      expect(en.dialogPoolNew, '＋ New todo');
      expect(en.dialogPoolTitleHint, 'Todo title (required)');
      expect(en.dialogPoolStartInvalid, 'Start time must be HH:mm, or left blank');

      // 插值：同一条键，两种语言的语序 / 连接词不同。
      expect(zh.dialogPoolAvailable(3), '3 条待捞');
      expect(en.dialogPoolAvailable(3), '3 to pull');
      expect(zh.dialogPoolScheduled('09:15'), '已排期 09:15');
      expect(en.dialogPoolScheduled('09:15'), 'Scheduled 09:15');
      expect(zh.dialogPoolHead('3 条待捞', _today), '3 条待捞 · 捞入 $_today');
      expect(en.dialogPoolHead('3 to pull', _today), '3 to pull · pull into $_today');
      expect(zh.dialogPoolAvailable(3), isNot(en.dialogPoolAvailable(3)));
      expect(zh.dialogPoolHead('3 条待捞', _today),
          isNot(en.dialogPoolHead('3 条待捞', _today)));
    });
  });

  group('待办池页（Widget 层）', () {
    testWidgets('zh 态：页标题、六列表头、行内容都是中文字面量', (tester) async {
      _useTallSurface(tester);
      final harness = _PoolHarness.create();
      await tester.runAsync(() async {
        final repos = harness.container.read(repositoriesProvider);
        await repos.todo.create(title: '已存在的待办', quadrant: 'Q1', priorityAbc: 'B');
      });
      await harness.mount(tester);
      await _settle(tester);

      expect(find.text('待办池'), findsOneWidget);
      for (final head in <String>['标题', '优先级', '预估', '象限', '到期', '动作']) {
        expect(find.text(head), findsOneWidget, reason: '表头缺列：$head');
      }
      expect(find.text('已存在的待办'), findsOneWidget);
      expect(find.text('＋ 新建待办'), findsOneWidget);

      await _flushTimers(tester);
    });

    testWidgets('en 态：页标题与六列表头出英文，中文一条不剩（阴性对照）', (tester) async {
      _useTallSurface(tester);
      final harness = _PoolHarness.create();
      await tester.runAsync(() async {
        final repos = harness.container.read(repositoriesProvider);
        await repos.todo.create(title: '已存在的待办', quadrant: 'Q1', priorityAbc: 'B');
      });
      await harness.mount(tester, language: AppLanguage.en);
      await _settle(tester);

      expect(find.text('Todo pool'), findsOneWidget);
      for (final head in <String>['Title', 'Priority', 'Est.', 'Quadrant', 'Due', 'Action']) {
        expect(find.text(head), findsOneWidget, reason: 'en 表头缺列：$head');
      }
      expect(find.text('＋ New todo'), findsOneWidget);

      // 阴性对照：表头与页标题都不许回落中文。
      for (final zhText in <String>['待办池', '优先级', '预估', '象限', '到期', '动作']) {
        expect(find.text(zhText), findsNothing, reason: 'en 态残留中文：$zhText');
      }

      await _flushTimers(tester);
    });

    testWidgets('en 态：三条行内错误与空态长句出英文', (tester) async {
      _useTallSurface(tester);
      final harness = _PoolHarness.create();
      await harness.mount(tester, language: AppLanguage.en);
      await _settle(tester);

      // 空态长句（与手写面板的短版不是同一条）。
      expect(
        find.textContaining('The pool is empty'),
        findsOneWidget,
        reason: 'en 空态长句没接上',
      );

      // ① 标题为空。
      await tester.tap(find.byKey(const ValueKey<String>('todo-new-submit')));
      await _settle(tester);
      expect(find.text('Title is required'), findsOneWidget);

      // ② 预估非法。
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-new-title')),
        '英文界面新建',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-new-est')),
        'abc',
      );
      await tester.tap(find.byKey(const ValueKey<String>('todo-new-submit')));
      await _settle(tester);
      expect(find.text('Estimate must be a positive number, or left blank'),
          findsOneWidget);

      // ③ 起始时间格式非法。
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-new-est')),
        '30',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-new-start')),
        '25:99',
      );
      await tester.tap(find.byKey(const ValueKey<String>('todo-new-submit')));
      await _settle(tester);
      expect(find.text('Start time must be HH:mm, or left blank'), findsOneWidget);

      // 阴性对照：中文错误串一条都不许出现。
      expect(find.text('标题不能为空'), findsNothing);
      expect(find.text('起始时间要填 HH:mm，或留空'), findsNothing);

      await _flushTimers(tester);
    });
  });
}