// apps/desktop/test/task54_done_desaturate_test.dart
//
// Task 54 · 四态底「已完成」的去饱和裁决。
//
// 用户诉求：勾选完成后，格子底色应当**退到背景里**，让没做完的任务先被看见。
// 上一版把「退后」实现成「贴近格底色」（明 `#F6F6F3`），代价是已完成格子与
// 中午段底色 `paper` 只差 1.02:1 —— 打勾后整块融进格底，读起来像空格，
// 「已完成」这个状态本身反而没了（见 `reports/task53-accept-report.md` §3：
// 同一 `status=done` 条目新旧两帧分别取到 `#F6F6F3` 与 `#F3EEE4`）。
//
// 本轮的实现口径：**退后靠去彩度，不靠贴近底色**。
//   · 彩度：明 `13.0%` vs `slotPlan` 的 `31.6%`（41%）；暗 `3.7%` vs `18.0%`（21%）。
//   · 亮度：明 `Y 0.8274` 比 `slotPlan` 的 `0.8574` 暗 0.030；暗 `Y 0.0382` 比
//     `0.0143` 亮 0.024 —— 暗档 `slotPlan` 已贴住亮度地板（`#241F19`），
//     「更暗」在物理上不可达，只能反向取亮。
//   · 结果：明档 done vs 中午段 `paper` 从 1.0155:1 提到 1.0888:1，格子不再消失；
//     done vs 自己的前景 `meta` 仍 5.88:1（暗档 5.93:1），正文远高于 4.5:1。
//
// 判据分三组：A 明档去饱和 + 亮度差 + 不再融进格底；B 暗档同三条；C 映射与
// 四态可分离。数字全部走 `lib/src/theme/contrast.dart` 的 WCAG 实现，不写估计值。
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/contrast.dart';
import 'package:actlog/src/theme/theme_tokens.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:actlog/src/widgets/timeline/slot_layout.dart';
import 'package:actlog/src/widgets/timeline/slot_state.dart';
import 'package:actlog/src/widgets/timeline/timeline_store.dart';

/// 固定「今天」，与被测日期分开，才能确定性地构造回填 / 未来。
const String _today = '2026-11-09';

/// 过去日：整日都算回填 —— 也就是「kind 被 backfill 抢先」的那批条目。
const String _past = '2026-11-08';

/// 内存真库 + 真仓储 + 固定今天 / 选中日（与 `task53_chip_glyph_test.dart`
/// 同一套装置：不 mock，让底色真的走一遍 `provider → gridEntriesOf → 渲染`）。
final class _Harness {
  _Harness._(this.container, this.repos);

  final ProviderContainer container;
  final ActLogRepositories repos;

  static _Harness create({required String selected}) {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'task54-done-desaturate');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => selected),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(container, repos);
  }

  Future<void> mount(WidgetTester tester, String date) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: DayGrid(date: date))),
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

/// 等真库流回来（与 `timeline_day_grid_test.dart` 同一口径）。
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

/// 条目外壳上**真正绘制的**底色（不是重算一遍映射，而是读渲染出来的那层）。
Color _chipFill(WidgetTester tester, String planItemId) {
  final Container box = tester.widget<Container>(
    find.byKey(ValueKey<String>('day-grid-entry-$planItemId')),
  );
  return (box.decoration! as BoxDecoration).color!;
}

/// 条目外壳里的复选框当前值。
bool _checkboxValue(WidgetTester tester, String planItemId) {
  return tester
      .widget<LedgerCheckbox>(
        find.descendant(
          of: find.byKey(ValueKey<String>('day-grid-entry-$planItemId')),
          matching: find.byType(LedgerCheckbox),
        ),
      )
      .value;
}

/// 当前渲染用的那条 [GridEntry]：直接问布局层，避免用「期望值」自证。
GridEntry _liveEntry(WidgetTester tester, String planItemId) {
  final CustomPaint slotPaint = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .firstWhere(
        (CustomPaint p) =>
            p.painter != null &&
            p.painter!.runtimeType.toString() == '_SlotPainter',
      );
  final dynamic painter = slotPaint.painter;
  final SlotLayout layout = painter.layout as SlotLayout;
  return layout.segments
      .firstWhere((SlotSegment s) => s.entry.id == planItemId)
      .entry;
}

/// 一条投影（真值表用）。
GridEntry _entryOf(SlotKind kind, {bool? isDone}) => GridEntry(
  id: 'truth-table',
  title: '真值表',
  startMinute: 10 * 60,
  endMinute: 10 * 60 + 15,
  kind: kind,
  isDone: isDone,
);

/// HSL 饱和度（0–1）：`slotPlan` 是暖黄（H≈40°），`slotDone` 应几乎无色。
double _saturation(Color color) => HSLColor.fromColor(color).saturation;

/// 相对亮度（WCAG 2.1）—— 与 [contrastRatio] 同源，避免第二套公式。
double _lum(Color color) => relativeLuminance(color);

void _expectAtLeast(double actual, double min, String what) {
  expect(
    actual,
    greaterThanOrEqualTo(min),
    reason: '$what 实测 ${actual.toStringAsFixed(4)} < $min',
  );
}

void main() {
  // 明档：done 必须**比 plan 暗**且几乎无彩度。
  //
  // 方向是判据的一部分，不是随手取的：旧值 `#F6F6F3` 在 plan 的**亮**侧，
  // 与 `paper` 只差 1.0155:1，因此「打勾 = 整块消失」。只断言 |ΔY| ≥ 0.02
  // 会让旧值蒙混过关（旧 |ΔY| = 0.0624），故把方向钉死。
  test('判据 1（明）：已完成比未完成更暗 ≥0.02 且彩度不高于其 55%', () {
    final ThemeTokens t = ThemeTokens.light;
    final double planY = _lum(t.slotPlan);
    final double doneY = _lum(t.slotDone);

    _expectAtLeast(planY - doneY, 0.02, '明档 Y(plan) - Y(done)');
    expect(doneY, lessThan(planY), reason: '明档已完成必须比未完成更暗');

    final double planS = _saturation(t.slotPlan);
    final double doneS = _saturation(t.slotDone);
    expect(planS, greaterThan(0), reason: '_slotPlan 本身必须带彩度，否则比值无意义');
    expect(
      doneS,
      lessThanOrEqualTo(planS * 0.55),
      reason: '明档 _slotDone 饱和度 ${(doneS * 100).toStringAsFixed(2)}% '
          '未降到 _slotPlan（${(planS * 100).toStringAsFixed(2)}%）的 55% 以下',
    );
  });

  // 明档：格子不能融进它下面那层。条目的底有三段（`gridSectionMorning` /
  // `Noon` / `Evening`），这里取覆盖上午 / 晚上两段的 `card` 与中间段的 `paper`
  // 里更难分离的那个方向作闸门（阈值 1.05，旧值 1.0155 必红）。
  test('判据 2（明）：已完成格子与格底色可分离，且与前景仍 ≥4.5', () {
    final ThemeTokens t = ThemeTokens.light;
    _expectAtLeast(
      contrastRatio(t.slotDone, t.gridSectionNoon),
      1.05,
      '明档 done vs 中午段',
    );
    _expectAtLeast(
      contrastRatio(t.slotDone, t.gridSectionMorning),
      1.05,
      '明档 done vs 上午段',
    );
    _expectAtLeast(
      contrastRatio(t.slotDone, t.gridSectionEvening),
      1.05,
      '明档 done vs 晚上段',
    );
    _expectAtLeast(
      contrastRatio(t.slotDone, t.slotDoneInk),
      4.5,
      '明档 doneInk（meta）',
    );
    _expectAtLeast(
      contrastRatio(t.slotDone, t.ink2),
      4.5,
      '明档 done 上的标题（ink2）',
    );
  });

  // 暗档：`slotPlan` 的 `Y` 已到 0.0143（近地板），「更暗 0.02」不可达 ⇒
  // 唯一可达的「拉开明度差」方向是更亮。这条方向断言同样钉死，防止有人
  // 把暗档 done 又拨回 `#1D1A16`（旧 |ΔY| 只有 0.0037，肉眼分不出四态）。
  test('判据 3（暗）：已完成与未完成的亮度差 ≥0.02（暗档取更亮），彩度 ≤ 其 55%', () {
    final ThemeTokens t = ThemeTokens.dark;
    final double planY = _lum(t.slotPlan);
    final double doneY = _lum(t.slotDone);

    _expectAtLeast(doneY - planY, 0.02, '暗档 Y(done) - Y(plan)');
    expect(doneY, greaterThan(planY), reason: '暗档已完成必须比未完成更亮');

    final double planS = _saturation(t.slotPlan);
    final double doneS = _saturation(t.slotDone);
    expect(planS, greaterThan(0), reason: '_slotPlan 本身必须带彩度，否则比值无意义');
    expect(
      doneS,
      lessThanOrEqualTo(planS * 0.55),
      reason: '暗档 _slotDone 饱和度 ${(doneS * 100).toStringAsFixed(2)}% '
          '未降到 _slotPlan（${(planS * 100).toStringAsFixed(2)}%）的 55% 以下',
    );
  });

  test('判据 4（暗）：与前景 ≥4.5，四态两两 ≥1.02，且去蓝闸门仍成立', () {
    final ThemeTokens t = ThemeTokens.dark;
    _expectAtLeast(
      contrastRatio(t.slotDone, t.slotDoneInk),
      4.5,
      '暗档 doneInk（meta）',
    );

    final Map<String, Color> slots = <String, Color>{
      'slotPlan': t.slotPlan,
      'slotDone': t.slotDone,
      'slotBackfill': t.slotBackfill,
      'slotHabit': t.slotHabit,
    };
    final List<String> names = slots.keys.toList();
    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        _expectAtLeast(
          contrastRatio(slots[names[i]]!, slots[names[j]]!),
          1.02,
          '暗档 ${names[i]} vs ${names[j]}',
        );
      }
    }

    // 判据 9（去蓝）对 `slotDone` 同样适用：R ≥ B。
    final int argb = t.slotDone.toARGB32();
    expect(
      (argb >> 16) & 0xFF,
      greaterThanOrEqualTo(argb & 0xFF),
      reason: '暗档 _slotDone 的 R 小于 B，违反「去蓝」纪律',
    );
  });

  test('判据 5：done 两个 SlotKind 映射到自己那一档 token，且两档不同值', () {
    expect(
      colorOfSlotKind(SlotKind.done, ThemeTokens.light),
      ThemeTokens.light.slotDone,
    );
    expect(
      colorOfSlotKind(SlotKind.done, ThemeTokens.dark),
      ThemeTokens.dark.slotDone,
    );
    expect(
      ThemeTokens.light.slotDone,
      isNot(ThemeTokens.dark.slotDone),
      reason: '明暗两档的 _slotDone 不得同值',
    );
    // 四态底必须四值互异，否则「已完成」和别的态会撞成一块。
    expect(
      <int>{
        ThemeTokens.light.slotPlan.toARGB32(),
        ThemeTokens.light.slotDone.toARGB32(),
        ThemeTokens.light.slotBackfill.toARGB32(),
        ThemeTokens.light.slotHabit.toARGB32(),
      }.length,
      4,
      reason: '明档四态底撞色',
    );
    expect(
      <int>{
        ThemeTokens.dark.slotPlan.toARGB32(),
        ThemeTokens.dark.slotDone.toARGB32(),
        ThemeTokens.dark.slotBackfill.toARGB32(),
        ThemeTokens.dark.slotHabit.toARGB32(),
      }.length,
      4,
      reason: '暗档四态底撞色',
    );
  });

  // ===========================================================================
  // Task 54 · 诉求 2：完成态必须**叠加**在 `kind` 之上的底色通道（`fillOfSlot`）
  // ===========================================================================
  // 为什么必须另开一层：`slotKindOf` 的判定顺序是铁律
  // `habit → backfill → done → plannedOpen`，所以「计划起点已到」的条目 —— 用户
  // 最常打勾的那批 —— 打勾前后 `kind` **都是** `backfill`。底色若仍只按 `kind`
  // 取，「打勾后变灰」在真实路径上完全落空（`colorOfSlotKind` 一行不改，
  // 它仍是「kind → 该 kind 的底色」的逐值映射）。

  group('Task 54 · 诉求 2：fillOfSlot 真值表', () {
    // 六格判定矩阵 + 旧调用点的 `isDone: null` 回退语义。
    test('明档：六格逐值 + completed 派生', () {
      final ThemeTokens t = ThemeTokens.light;

      // 回填轴：起点已过 ⇒ kind 恒 backfill，完成态只能来自显式位。
      expect(fillOfSlot(_entryOf(SlotKind.backfill, isDone: true), t),
          t.slotDone, reason: '(backfill, done) 必须退到 slotDone');
      expect(fillOfSlot(_entryOf(SlotKind.backfill, isDone: false), t),
          t.slotBackfill, reason: '(backfill, pending) 仍是 slotBackfill');
      expect(
        fillOfSlot(_entryOf(SlotKind.backfill, isDone: true), t),
        isNot(fillOfSlot(_entryOf(SlotKind.backfill, isDone: false), t)),
        reason: '打勾前后必须不同色 —— 这正是本轮缺口所在',
      );

      // 计划轴。
      expect(fillOfSlot(_entryOf(SlotKind.plannedOpen, isDone: true), t),
          t.slotDone);
      expect(fillOfSlot(_entryOf(SlotKind.plannedOpen, isDone: false), t),
          t.slotPlan);

      // 类型轴：习惯不受完成态影响。
      expect(fillOfSlot(_entryOf(SlotKind.habit, isDone: true), t), t.slotHabit);
      expect(fillOfSlot(_entryOf(SlotKind.habit, isDone: false), t), t.slotHabit);
      expect(
        fillOfSlot(_entryOf(SlotKind.habit, isDone: true), t),
        fillOfSlot(_entryOf(SlotKind.habit, isDone: false), t),
        reason: 'habit 是类型轴，不能被完成态改写',
      );

      // 旧调用点语义：不传 isDone ⇒ 由 kind 推断（kind == done ⇒ 已完成）。
      expect(_entryOf(SlotKind.done).isDone, isNull);
      expect(_entryOf(SlotKind.done).completed, isTrue);
      expect(fillOfSlot(_entryOf(SlotKind.done), t), t.slotDone);
      expect(_entryOf(SlotKind.plannedOpen).completed, isFalse);
    });

    test('暗档：关键四格与明档同构，且明暗两档各自不同值', () {
      final ThemeTokens t = ThemeTokens.dark;

      expect(fillOfSlot(_entryOf(SlotKind.backfill, isDone: true), t),
          t.slotDone);
      expect(fillOfSlot(_entryOf(SlotKind.backfill, isDone: false), t),
          t.slotBackfill);
      expect(fillOfSlot(_entryOf(SlotKind.plannedOpen, isDone: true), t),
          t.slotDone);
      expect(fillOfSlot(_entryOf(SlotKind.plannedOpen, isDone: false), t),
          t.slotPlan);
      expect(fillOfSlot(_entryOf(SlotKind.habit, isDone: true), t), t.slotHabit);

      expect(t.slotDone, isNot(ThemeTokens.light.slotDone));
      expect(t.slotDone, isNot(t.slotBackfill));
      expect(t.slotDone, isNot(t.slotPlan));
    });
  });

  // 判别性用例（最重要）：走**真实渲染路径**打勾前后对拍。
  //
  // 钉的正是 `slotKindOf` 先判 backfill 这个缺口：这条条目的计划起点在过去的
  // 一天里 ⇒ `kind` 恒为 `backfill`；改动之前打勾前后底色**逐字相同**
  // （`colorOfSlotKind(backfill)`），本用例的第二条断言会当场红。
  testWidgets('判别：起点已过的条目，打勾后 chip 底色 slotBackfill → slotDone', (
    tester,
  ) async {
    _useTallSurface(tester);
    final _Harness harness = _Harness.create(selected: _past);
    // 不传 todayIso / nowMinute ⇒ 落库为 `pending`（「起点已到」只体现在粒子上），
    // 这样才有「打勾前」可对拍。
    final String id = (await tester.runAsync(
      () => TimelineStore(harness.repos).createManual(
        date: _past,
        title: '补记：报销',
        startMinute: 10 * 60,
        endMinute: 10 * 60 + 15,
      ),
    ))!;

    await harness.mount(tester, _past);
    await _settle(tester);

    // 前置判据：确实是「起点已过、但没打勾」的那批条目。
    final GridEntry beforeEntry = _liveEntry(tester, id);
    expect(beforeEntry.kind, SlotKind.backfill, reason: '起点已过必须是回填态');
    expect(beforeEntry.isDone, isFalse);
    expect(_checkboxValue(tester, id), isFalse);
    final Color before = _chipFill(tester, id);
    expect(before, ThemeTokens.light.slotBackfill, reason: '打勾前应是回填底色');

    // 打勾：真的点条目里的复选框，走 `_toggleStatus → setStatus → 流回写`。
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey<String>('day-grid-entry-$id')),
        matching: find.byType(LedgerCheckbox),
      ),
    );
    await _settle(tester);

    // 核心判别：kind 没变，完成位变了，底色必须跟着变。
    final GridEntry afterEntry = _liveEntry(tester, id);
    expect(afterEntry.kind, SlotKind.backfill, reason: 'kind 仍是回填（铁律未动）');
    expect(afterEntry.isDone, isTrue);
    expect(_checkboxValue(tester, id), isTrue);
    final Color after = _chipFill(tester, id);
    expect(after, ThemeTokens.light.slotDone, reason: '打勾后必须退到 slotDone');
    expect(
      after,
      isNot(before),
      reason: '打勾前后底色相同 ⇒ 用户诉求（已完成与未完成形成区分）落空',
    );

    await _flushTimers(tester);
  });
}