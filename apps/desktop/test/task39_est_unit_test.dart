// apps/desktop/test/task39_est_unit_test.dart
//
// Task 39 · W2 追加：预估时间可选「分钟/小时/日/周/月」。
//
// 口径（零 schema 变更）：库里 `todo.est_minutes` 仍然是**整数分钟**，
// 单位只活在输入侧与显示侧；显示侧由分钟数按确定性阶梯推回最大可用单位，
// 所以同一个值在两端是同一串文案，不需要额外列。
//
// 这里钉住三层：
//   1. 阶梯函数的逐值口径（90 / 120 / 1440 / 10080 / 43200 / 45 + 边界）；
//   2. 换算函数 `estMinutesOf`（小时+2 ⇒ 120 等）；
//   3. 端到端：面板里选「小时」填 2 ⇒ 落库 `estMinutes == 120`，数量留空 ⇒ NULL。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/est_duration_text.dart';
import 'package:actlog/src/widgets/quick_todo_dialog.dart';

import 'l10n_harness.dart';

const String _today = '2026-11-09';
const ValueKey<String> _openKey = ValueKey<String>('test-open-todo-dialog');

final class _Harness {
  _Harness._(this.container, this.db);

  final ProviderContainer container;
  final ActLogDatabase db;

  static _Harness create() {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    final ActLogRepositories repos = ActLogRepositories(
      db,
      deviceId: 'task39-est-unit-test',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, db);
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      // Task 63 W6：面板文案改为运行时取 `t`，缺 `L10nScope` 会抛 `FlutterError`。
      l10nScope(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(DensityProfile.comfortable),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => Center(
                  child: TextButton(
                    key: _openKey,
                    onPressed: () => showQuickTodoDialog(context),
                    child: const Text('手写一条'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 等真库流回来（禁用 `pumpAndSettle`：drift 流会挂到超时）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}

/// 面板里只有「标题」和「预估数量」两个输入框，索引 1 就是预估数量。
Finder _estField() => find.byType(TextField).at(1);

Future<List<TodoData>> _todos(WidgetTester tester, ActLogDatabase db) async {
  final List<TodoData>? rows = await tester.runAsync(
    () => db.select(db.todo).get(),
  );
  return rows ?? const <TodoData>[];
}

void main() {
  group('formatEstDuration · 确定性阶梯', () {
    const Map<int, String> samples = <int, String>{
      90: '90 分钟',
      120: '2 小时',
      1440: '1 日',
      10080: '1 周',
      43200: '1 月',
      45: '45 分钟',
    };
    samples.forEach((int minutes, String expected) {
      test('$minutes → $expected', () {
        expect(formatEstDuration(minutes, AppLocalizations.zh), expected);
      });
    });

    test('边界：1 / 59 / 60 / 61', () {
      expect(formatEstDuration(1, AppLocalizations.zh), '1 分钟');
      expect(formatEstDuration(59, AppLocalizations.zh), '59 分钟');
      expect(formatEstDuration(60, AppLocalizations.zh), '1 小时');
      expect(formatEstDuration(61, AppLocalizations.zh), '61 分钟');
    });

    test('非正数原样按分钟给，不落进「0 月」', () {
      expect(formatEstDuration(0, AppLocalizations.zh), '0 分钟');
      expect(formatEstDuration(-5, AppLocalizations.zh), '-5 分钟');
    });
  });

  // Task 63 批次二 W6：单位名改为随语言给；阶梯口径与 zh 完全一致。
  group('formatEstDuration · 英文态单位名', () {
    test('逐档换成英文单位，阶梯规则不变', () {
      expect(formatEstDuration(90, AppLocalizations.en), '90 min');
      expect(formatEstDuration(120, AppLocalizations.en), '2 hr');
      expect(formatEstDuration(1440, AppLocalizations.en), '1 day');
      expect(formatEstDuration(10080, AppLocalizations.en), '1 wk');
      expect(formatEstDuration(43200, AppLocalizations.en), '1 mo');
      expect(formatEstDuration(45, AppLocalizations.en), '45 min');
    });

    test('非正数照样按分钟给', () {
      expect(formatEstDuration(0, AppLocalizations.en), '0 min');
      expect(formatEstDuration(-5, AppLocalizations.en), '-5 min');
    });
  });

  group('estMinutesOf · 数量 × 单位 ⇒ 分钟', () {
    test('小时 + 2 ⇒ 120', () {
      expect(estMinutesOf(2, EstUnit.hour), 120);
    });
    test('日 + 1 ⇒ 1440', () {
      expect(estMinutesOf(1, EstUnit.day), 1440);
    });
    test('周 + 1 ⇒ 10080', () {
      expect(estMinutesOf(1, EstUnit.week), 10080);
    });
    test('月 + 1 ⇒ 43200', () {
      expect(estMinutesOf(1, EstUnit.month), 43200);
    });
    test('小时 + 1.5 ⇒ 90', () {
      expect(estMinutesOf(1.5, EstUnit.hour), 90);
    });
    test('0 / 负数 ⇒ null（视为未填）', () {
      expect(estMinutesOf(0, EstUnit.hour), isNull);
      expect(estMinutesOf(-1, EstUnit.day), isNull);
    });
  });

  testWidgets('选「小时」填 2 ⇒ 落库 120 分钟，待办仍是 open', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);

    await tester.tap(find.byKey(_openKey));
    await _settle(tester);

    await tester.enterText(find.byType(TextField).first, '写周报');
    await tester.pump();
    await tester.enterText(_estField(), '2');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('quick-todo-est-unit-hour')),
    );
    await tester.pump();
    await tester.tap(find.text('保存'));
    await _settle(tester);

    final List<TodoData> rows = await _todos(tester, harness.db);
    expect(rows, hasLength(1));
    expect(rows.single.title, '写周报');
    expect(
      rows.single.estMinutes,
      120,
      reason: '选「小时」填 2 ⇒ 库里存 120 分钟',
    );
    expect(rows.single.status, 'open', reason: '捞入今天不该把待办标记完成');

    await _flushTimers(tester);
  });

  testWidgets('预估数量留空 ⇒ estMinutes 为 NULL', (
    WidgetTester tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);

    await tester.tap(find.byKey(_openKey));
    await _settle(tester);

    await tester.enterText(find.byType(TextField).first, '整理桌面');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await _settle(tester);

    final List<TodoData> rows = await _todos(tester, harness.db);
    expect(rows, hasLength(1));
    expect(rows.single.estMinutes, isNull, reason: '留空 ⇒ 不写估计值');

    await _flushTimers(tester);
  });
}