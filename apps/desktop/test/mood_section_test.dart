// apps/desktop/test/mood_section_test.dart
//
// Task 40 · B3 · 需求 6：心态改为「豆包 3+2」结构（每日核心 3 项 +
// 每周补充 2 项），「明日改进点」迁入心态侧，「今日失守」UI 删除。
//
// 证据口径（`AGENTS.md` R5）：钉**结构事实**与**落库事实**，不钉像素。
//   1. 5 个主存维度的打分控件各有一枚稳定 key，日 / 周两组可判别；
//   2. 8 个 legacy 列全部仍被读到：主存列回填读数、佐证列只读展示；
//   3. 老数据在只改「明日改进点」时**一列都不丢**（这是迁字段最容易造的回归）；
//   4. 「今日失守」文案不再出现，但 0 分 ⇒ `mood_failed=1` 的自动派生仍在。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/mood_section.dart';

const String _today = '2026-11-09';

/// 5 个主存维度的 key（顺序同 `moodDimensionDefs`）。
const List<String> _dimensionKeys = <String>[
  'fulfillment',
  'efficiency',
  'positiveMind',
  'selfEfficacy',
  'contribution',
];

Finder _byKey(String key) => find.byKey(ValueKey<String>(key));

final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task40-mood-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先 dispose 容器、再 db.close。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: MoodSection())),
        ),
      ),
    );
    await _settle(tester);
  }
}

/// 撑宽测试面：维度行是「标签 + 11 枚 chip + 读数」的横排。
void _useWideSurface(WidgetTester tester) {
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

/// 收尾：卸掉界面放掉 drift 流订阅；`MoodSection.dispose` 里还有一次落库，
/// 不等它跑完，tearDown 的 `db.close()` 会先关库（下一例报 cannot re-open）。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
}

/// 防抖 700ms（`mood_section.dart:_scheduleSave`）+ 一次真异步落库。
Future<void> _flushSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 800));
  await _settle(tester);
}

void main() {
  testWidgets('5 个维度控件都在，且日 / 周分组可判别', (WidgetTester tester) async {
    _useWideSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);

    for (final String key in _dimensionKeys) {
      expect(
        _byKey('mood-dim-$key'),
        findsOneWidget,
        reason: '维度「$key」必须有一枚可判别的控件 key',
      );
    }
    expect(_byKey('mood-group-day'), findsOneWidget);
    expect(_byKey('mood-group-week'), findsOneWidget);
    expect(find.text('每日核心 · 每日更新'), findsOneWidget);
    expect(find.text('每周补充 · 每周更新'), findsOneWidget);

    // 3 + 2 的分组归属：日组里有前 3 个 key，周组里有后 2 个。
    for (final String key in _dimensionKeys.take(3)) {
      expect(
        find.descendant(
          of: _byKey('mood-group-day'),
          matching: _byKey('mood-dim-$key'),
        ),
        findsOneWidget,
      );
    }
    for (final String key in _dimensionKeys.skip(3)) {
      expect(
        find.descendant(
          of: _byKey('mood-group-week'),
          matching: _byKey('mood-dim-$key'),
        ),
        findsOneWidget,
      );
    }

    expect(find.text('已评 0/5 维'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _flushTimers(tester);
  });

  testWidgets('老数据 8 列全部归组：主存列回填读数，佐证列只读可见', (WidgetTester tester) async {
    _useWideSurface(tester);
    final _Harness harness = _Harness.create();

    await tester.runAsync(() async {
      final DayLogData row = await harness.repos.dayLog.ensureByDate(_today);
      await harness.repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{
            MoodDimension.diligent: 9,
            MoodDimension.fast: 6,
            MoodDimension.keepPromise: 7,
            MoodDimension.finishTask: 8,
            MoodDimension.optimistic: 4,
            MoodDimension.confident: 3,
            MoodDimension.loveAndDedication: 2,
            MoodDimension.noExcuses: 1,
          },
          failed: false,
          note: '',
        ),
      );
    });

    await harness.mount(tester);

    // 主存列 → 读数。
    const Map<String, int> primary = <String, int>{
      'fulfillment': 7,
      'efficiency': 9,
      'positiveMind': 4,
      'selfEfficacy': 3,
      'contribution': 2,
    };
    primary.forEach((String key, int value) {
      expect(
        tester.widget<Text>(_byKey('mood-dim-$key-value')).data,
        '$value',
        reason: '「$key」的主存列必须回填',
      );
    });

    // 佐证列 → 只读展示（归组后不丢）。
    expect(
      tester.widget<Text>(_byKey('mood-supporting-fulfillment')).data,
      '佐证：保证完成任务 8 · 决不找借口 1',
    );
    expect(
      tester.widget<Text>(_byKey('mood-supporting-efficiency')).data,
      '佐证：快 6',
    );

    // 统计按新 5 维：(7 + 9 + 4 + 3 + 2) / 5 = 5.0。
    expect(find.text('已评 5/5 维'), findsOneWidget);
    expect(find.text('均分 5.0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _flushTimers(tester);
  });

  testWidgets('只有佐证列有值时，按佐证均值计入新 5 维统计', (WidgetTester tester) async {
    _useWideSurface(tester);
    final _Harness harness = _Harness.create();

    await tester.runAsync(() async {
      final DayLogData row = await harness.repos.dayLog.ensureByDate(_today);
      await harness.repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{MoodDimension.noExcuses: 8},
          failed: false,
          note: '',
        ),
      );
    });

    await harness.mount(tester);

    // `mood_3` 为空 ⇒ 履约负责由 `mood_8` 回退得出 8.0，计为已评。
    expect(find.text('已评 1/5 维'), findsOneWidget);
    expect(find.text('均分 8.0'), findsOneWidget);
    expect(
      tester.widget<Text>(_byKey('mood-dim-fulfillment-value')).data,
      '—',
      reason: '主存列没打分，读数不伪装成用户填的值',
    );
    expect(
      tester.widget<Text>(_byKey('mood-supporting-fulfillment')).data,
      '佐证：保证完成任务 未评 · 决不找借口 8',
    );

    await _flushTimers(tester);
  });

  testWidgets('「明日改进点」可编辑并落库到 next_action，且 8 列一列不丢', (WidgetTester tester) async {
    _useWideSurface(tester);
    final _Harness harness = _Harness.create();

    await tester.runAsync(() async {
      final DayLogData row = await harness.repos.dayLog.ensureByDate(_today);
      await harness.repos.dayLog.saveMood(
        row.id,
        const MoodSummary(
          scores: <MoodDimension, int>{
            MoodDimension.diligent: 9,
            MoodDimension.fast: 6,
            MoodDimension.keepPromise: 7,
            MoodDimension.finishTask: 8,
            MoodDimension.optimistic: 4,
            MoodDimension.confident: 3,
            MoodDimension.loveAndDedication: 2,
            MoodDimension.noExcuses: 1,
          },
          failed: false,
          note: '旧备注',
        ),
        nextAction: '旧改进点',
      );
    });

    await harness.mount(tester);

    final Finder field = _byKey('mood-next-action');
    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      '旧改进点',
      reason: '已有值必须回填，否则用户一进页面就以为丢了',
    );

    await tester.enterText(field, '先做 A 类');
    await _flushSave(tester);

    final DayLogData? after =
        await tester.runAsync<DayLogData?>(() => harness.repos.dayLog.findByDate(_today));
    expect(after, isNotNull);
    expect(after!.nextAction, '先做 A 类');
    // 迁字段只动 `next_action`：8 个 legacy 列（含 3 个佐证列）原值不动。
    expect(after.mood1, 9);
    expect(after.mood2, 6);
    expect(after.mood3, 7);
    expect(after.mood4, 8);
    expect(after.mood5, 4);
    expect(after.mood6, 3);
    expect(after.mood7, 2);
    expect(after.mood8, 1);
    expect(after.moodNote, '旧备注');

    await _flushTimers(tester);
  });

  testWidgets('「今日失守」UI 已删除，但 0 分仍自动落 mood_failed=1', (WidgetTester tester) async {
    _useWideSurface(tester);
    final _Harness harness = _Harness.create();
    await harness.mount(tester);

    expect(find.textContaining('今日失守'), findsNothing);

    await tester.tap(_byKey('mood-dim-fulfillment-score-0'));
    await _flushSave(tester);

    final DayLogData? after =
        await tester.runAsync<DayLogData?>(() => harness.repos.dayLog.findByDate(_today));
    expect(after, isNotNull);
    expect(after!.mood3, 0, reason: '0 分必须原样落库（不是「未评」）');
    expect(
      after.moodFailed,
      1,
      reason: '0 分 ⇒ 失守自动派生，只删 UI 不删数据层规则',
    );
    expect(find.textContaining('今日失守'), findsNothing);

    await _flushTimers(tester);
  });
}