// apps/desktop/test/dark_theme_widget_test.dart
//
// Task 41 深色主题 · 真机级取色路径：暗色 `MaterialApp` 下渲染关键 widget，
// 断言它们真正吃到的颜色等于深色 token（**不是**浅色回落）。
//
// 为什么这几类 widget：
//   · `context.tokens` 探针 —— 先证明 `extensions` 接线成立，否则后面全是浅色；
//   · `SectionCard` / `SectionHeader` / `ChipRow` / `LedgerCheckbox` —— 账页四件套；
//   · `DayGrid` —— `CustomPainter` 拿不到 `BuildContext`，token 靠构造器显式传入，
//     是最容易漏接的一条路径（painter 类私有，用 `dynamic` 读公有字段 `tokens`）。
//
// 期望值一律 hex 字面量：不引 `ThemeTokens.dark.*`。
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/chip_row.dart';
import 'package:actlog/src/widgets/ledger_checkbox.dart';
import 'package:actlog/src/widgets/section_card.dart';
import 'package:actlog/src/widgets/section_header.dart';
import 'package:actlog/src/widgets/timeline/day_grid.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

// —— 深色 token 字面量 ——
const Color _paper = Color(0xFF1A1714);
const Color _card = Color(0xFF221E1A);
const Color _inkWash = Color(0xFF2B2620);
const Color _accentWash = Color(0xFF33241A);
const Color _ink = Color(0xFFECE5DA);
const Color _meta = Color(0xFFBFB6A7);
const Color _hair = Color(0xFF3A342C);
const Color _hairSoft = Color(0xFF2A251F);
const Color _hairStrong = Color(0xFF827869);
const Color _accent = Color(0xFFC08A4E);
const Color _accentInk = Color(0xFFD6A366);

/// 固定「今天」，让 `DayGrid` 的 `nowMinute` 不参与取色判断。
const String _today = '2026-11-09';

Widget _darkApp(Widget child) => MaterialApp(
      theme: AppTheme.dark(DensityProfile.comfortable),
      home: Scaffold(body: child),
    );

/// 收集某棵子树里所有带 border 的 `BoxDecoration`（`Container` 才有）。
List<BoxDecoration> _decorationsOf(WidgetTester tester, Finder root) => tester
    .widgetList<Container>(
      find.descendant(of: root, matching: find.byType(Container)),
    )
    .map((Container c) => c.decoration)
    .whereType<BoxDecoration>()
    .where((BoxDecoration d) => d.border != null)
    .toList();

BorderSide _topSide(BoxDecoration d) => (d.border! as Border).top;

/// 栅格加载是「真库 + 真 provider」，给异步留时间（同 `timeline_day_grid_test`）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// `CustomPainter` 类私有，但字段名 `tokens` 是公有的 ⇒ dynamic 可取；
/// 没有该字段的 painter 会抛 [NoSuchMethodError]，视作「不参与取色」。
Object? _tokensOf(Object painter) {
  try {
    final dynamic d = painter;
    return d.tokens as Object?;
  } on NoSuchMethodError {
    return null;
  }
}

void main() {
  testWidgets('暗色主题下 context.tokens 取到深色包', (tester) async {
    ThemeTokens? seen;
    await tester.pumpWidget(
      _darkApp(
        Builder(
          builder: (BuildContext context) {
            seen = context.tokens;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen, isNotNull);
    expect(seen!.paper, _paper);
    expect(seen!.card, _card);
    expect(seen!.ink, _ink);
    expect(seen!.hairStrong, _hairStrong);
    expect(seen!.accent, _accent);
  });

  testWidgets('SectionCard 底色 = card、常态边 = hairSoft', (tester) async {
    await tester.pumpWidget(
      _darkApp(
        const SectionCard(
          icon: Icons.circle,
          title: '段标题',
          child: SizedBox.shrink(),
        ),
      ),
    );
    final AnimatedContainer box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(SectionCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final BoxDecoration deco = box.decoration! as BoxDecoration;
    expect(deco.color, _card);
    expect(_topSide(deco).color, _hairSoft);
    expect(_topSide(deco).width, 1.0);
  });

  testWidgets('SectionHeader 标题 = ink、计数 = meta、底边 = hair', (tester) async {
    await tester.pumpWidget(
      _darkApp(const SectionHeader(title: '段标题', done: 2, total: 5)),
    );
    expect(tester.widget<Text>(find.text('段标题')).style?.color, _ink);
    expect(tester.widget<Text>(find.text('2/5')).style?.color, _meta);

    final List<BoxDecoration> decos =
        _decorationsOf(tester, find.byType(SectionHeader));
    expect(
      decos.any((BoxDecoration d) => (d.border! as Border).bottom.color == _hair),
      isTrue,
      reason: '段标题下边线应取 hair',
    );
  });

  testWidgets('SectionHeader 空档时外框 = accent 2px', (tester) async {
    await tester.pumpWidget(
      _darkApp(
        const SectionHeader(
          title: '段标题',
          hasGap: true,
          gapHint: '有 2h 空档',
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('有 2h 空档')).style?.color, _accentInk);

    final List<BoxDecoration> decos =
        _decorationsOf(tester, find.byType(SectionHeader));
    expect(
      decos.any((BoxDecoration d) => _topSide(d).color == _accent &&
          _topSide(d).width == 2.0),
      isTrue,
      reason: '空档外框应取 accent 2px',
    );
  });

  testWidgets('ChipRow 未选：paper 底 + hairStrong 边 + meta 字', (tester) async {
    await tester.pumpWidget(
      _darkApp(
        const ChipRow(
          options: <ChipOption>[ChipOption(key: 'a', label: '计划')],
          selected: <String>{},
        ),
      ),
    );
    final Material m = tester.widget<Material>(
      find.descendant(of: find.byType(ChipRow), matching: find.byType(Material)),
    );
    expect(m.color, _paper);

    // `FocusRing` 也会挂一层带 border 的装饰 ⇒ 按「芯片边宽 1px」挑出来。
    final BoxDecoration deco = _decorationsOf(
      tester,
      find.byType(ChipRow),
    ).firstWhere((BoxDecoration d) => _topSide(d).width == 1.0);
    expect(_topSide(deco).color, _hairStrong);
    expect(tester.widget<Text>(find.text('计划')).style?.color, _meta);
  });

  testWidgets('ChipRow 普通选中：inkWash 底 + ink 边 + ink 字（不反白）', (tester) async {
    await tester.pumpWidget(
      _darkApp(
        const ChipRow(
          options: <ChipOption>[ChipOption(key: 'a', label: '计划')],
          selected: <String>{'a'},
        ),
      ),
    );
    final Material m = tester.widget<Material>(
      find.descendant(of: find.byType(ChipRow), matching: find.byType(Material)),
    );
    expect(m.color, _inkWash);

    final BoxDecoration deco = _decorationsOf(
      tester,
      find.byType(ChipRow),
    ).firstWhere((BoxDecoration d) => _topSide(d).width == 1.0);
    expect(_topSide(deco).color, _ink);
    expect(tester.widget<Text>(find.text('计划')).style?.color, _ink);
  });

  testWidgets('ChipRow 拒绝类选中：accentWash 底 + accent 边 + accentInk 字', (tester) async {
    await tester.pumpWidget(
      _darkApp(
        const ChipRow(
          options: <ChipOption>[
            ChipOption(key: 'a', label: '会议', deny: true),
          ],
          selected: <String>{'a'},
        ),
      ),
    );
    final Material m = tester.widget<Material>(
      find.descendant(of: find.byType(ChipRow), matching: find.byType(Material)),
    );
    expect(m.color, _accentWash);

    final BoxDecoration deco = _decorationsOf(
      tester,
      find.byType(ChipRow),
    ).firstWhere((BoxDecoration d) => _topSide(d).width == 1.0);
    expect(_topSide(deco).color, _accent);
    expect(tester.widget<Text>(find.text('会议')).style?.color, _accentInk);
  });

  testWidgets('LedgerCheckbox 选中：ink 底 + ink 边 + paper 字', (tester) async {
    await tester.pumpWidget(
      _darkApp(LedgerCheckbox(value: true, onChanged: (bool _) {})),
    );
    final BoxDecoration deco = _decorationsOf(
      tester,
      find.byType(LedgerCheckbox),
    ).firstWhere((BoxDecoration d) => _topSide(d).width == 1.5);
    expect(deco.color, _ink);
    expect(_topSide(deco).color, _ink);
    expect(_topSide(deco).width, 1.5);
    expect(tester.widget<Text>(find.text('✓')).style?.color, _paper);
  });

  testWidgets('LedgerCheckbox 未选：paper 底 + hairStrong 边 + ink 字', (tester) async {
    await tester.pumpWidget(
      _darkApp(LedgerCheckbox(value: false, onChanged: (bool _) {})),
    );
    final BoxDecoration deco = _decorationsOf(
      tester,
      find.byType(LedgerCheckbox),
    ).firstWhere((BoxDecoration d) => _topSide(d).width == 1.5);
    expect(deco.color, _paper);
    expect(_topSide(deco).color, _hairStrong);
    expect(tester.widget<Text>(find.text('○')).style?.color, _ink);
  });

  testWidgets('DayGrid 的 CustomPainter 拿到深色 token（构造器显式传入）', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'dark-widget-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _today),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(DensityProfile.comfortable),
          home: const Scaffold(body: DayGrid(date: _today)),
        ),
      ),
    );
    await _settle(tester);

    final List<ThemeTokens> seen = <ThemeTokens>[];
    for (final CustomPaint paint in tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    )) {
      final Object? value = _tokensOf(paint.painter ?? const _NullPainter());
      if (value is ThemeTokens) {
        seen.add(value);
      }
    }
    expect(
      seen,
      isNotEmpty,
      reason: '没有任何 painter 带 tokens 字段 ⇒ CustomPainter 取色路径未接线',
    );
    for (final ThemeTokens t in seen) {
      expect(t.paper, _paper);
      expect(t.card, _card);
      expect(t.ink, _ink);
    }

    // 收掉网格自己的定时器，避免 pollute 后续用例。
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// `CustomPaint.painter` 可为 null；给 `_tokensOf` 一个确定的无字段对象。
final class _NullPainter extends CustomPainter {
  const _NullPainter();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}