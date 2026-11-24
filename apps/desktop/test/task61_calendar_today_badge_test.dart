// apps/desktop/test/task61_calendar_today_badge_test.dart
//
// Task 61 W2 · F6 疑点判定与回归锁定：英文态「今天」角标 `Today`（5 字符单词）
// 与月历格里的**日号**是否视觉重叠。
//
// 装置口径：
//   - 固定月份 `2026-11` + 固定「今天」`2026-11-24` ⇒ **不依赖** `DateTime.now()`，
//     每次跑出来的数字完全一致；
//   - 四个容器宽度 420 / 600 / 800 / 1680 逻辑像素；用 `tester.view.physicalSize`
//     把测试视口撑到同样宽（否则 1680 会被 800 宽的默认视口夹回来）；
//   - 每种语言各渲染一遍，用 `tester.getRect` 取「日号 Text」与「角标 Text」
//     两个矩形，算相交与否。
//
// 断言一律断**字面量**：日号断 `'24'`、英文角标断 `'Today'`、中文角标断 `'今'`；
// 绝不用 `find.text(t.xxx)`（同义反复，见计划 §47.3 铁律 1）。英文态另有
// **阴性对照**（英文态 `今` 一处都找不到 / 中文态 `Today` 一处都找不到）。
//
// 结论、12 行原始几何与修复归属见 `reports\task61-f6-today-badge.md`。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/widgets/calendar_month_view.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 固定月份。
const String _month = '2026-11';

/// 固定「今天」（本轮真实日期 2026-11-24）。
const String _today = '2026-11-24';

/// 「今天」格的日号字面量（`2026-11-24` → `24`，不补零）。
const String _dayNumberText = '24';

/// 扫描用的容器宽度（逻辑像素）。
const List<int> _widths = <int>[420, 600, 800, 1680];

/// 矩形四元组（左、上、右、下）。
typedef _Rect4 = (double, double, double, double);

/// **中文态基线**：实测的「今天」格两个矩形 —— 日号 + 「今」角标。
///
/// 中文态的排版**不得**被英文态的修复带动（日号 Rect 逐像素不变是硬约束），
/// 所以这组数字是硬基线：逐个相等才算过。容差 0.05px 只吃 double 的舍入。
const Map<int, (_Rect4, _Rect4)> _zhBaseline = <int, (_Rect4, _Rect4)>{
  420: (
    (75.90, 265.00, 104.10, 285.00),
    (102.50, 265.00, 114.00, 281.00),
  ),
  600: (
    (114.47, 265.00, 142.67, 285.00),
    (153.93, 265.00, 165.43, 281.00),
  ),
  800: (
    (157.33, 265.00, 185.53, 285.00),
    (211.07, 265.00, 222.57, 281.00),
  ),
  1680: (
    (345.90, 265.00, 374.10, 285.00),
    (462.50, 265.00, 474.00, 281.00),
  ),
};

/// 一格「今天」的实测几何。
class _Geometry {
  const _Geometry({
    required this.containerWidth,
    required this.cellWidth,
    required this.innerWidth,
    required this.dayNumber,
    required this.badge,
  });

  /// 容器宽度（逻辑像素）。
  final double containerWidth;

  /// 格宽（网格一列的宽度，含格内 1px margin）。
  final double cellWidth;

  /// 格内可用宽（Stack 的宽度 = 格宽 − 2×margin 1 − 2×padding 3 − 2×border 2）。
  final double innerWidth;

  /// 日号 Text 的矩形。
  final Rect dayNumber;

  /// 「今天」角标 Text 的矩形。
  final Rect badge;

  /// 两个矩形的交集（空 ⇒ 不相交）。
  Rect get overlap => dayNumber.intersect(badge);

  /// 是否视觉重叠。
  bool get overlaps => dayNumber.overlaps(badge);

  /// 单行摘要（写进断言失败信息里）。
  String describe(String label) {
    return '$label W=${containerWidth.toStringAsFixed(1)} '
        'cellW=${cellWidth.toStringAsFixed(2)} '
        'innerW=${innerWidth.toStringAsFixed(2)} '
        'day=[${dayNumber.left.toStringAsFixed(2)},'
        '${dayNumber.top.toStringAsFixed(2)},'
        '${dayNumber.right.toStringAsFixed(2)},'
        '${dayNumber.bottom.toStringAsFixed(2)}] '
        'badge=[${badge.left.toStringAsFixed(2)},'
        '${badge.top.toStringAsFixed(2)},'
        '${badge.right.toStringAsFixed(2)},'
        '${badge.bottom.toStringAsFixed(2)}] '
        'overlapW=${overlap.width.toStringAsFixed(2)} '
        'overlapH=${overlap.height.toStringAsFixed(2)} '
        'overlaps=$overlaps';
  }
}

/// 以指定宽度 + 语言渲染月视图并量出「今天」格的几何。
Future<_Geometry> _measure(
  WidgetTester tester,
  AppLanguage language,
  double width, {
  String badgeText = 'Today',
  List<CalendarDaySummary> days = const <CalendarDaySummary>[],
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 600);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    l10nScope(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: CalendarMonthView(
                month: _month,
                days: days,
                today: _today,
              ),
            ),
          ),
        ),
      ),
      language: language,
    ),
  );
  await tester.pump();

  final Finder cell = find.byKey(const ValueKey<String>('day-$_today'));
  final double cellWidth = tester.getRect(cell).width;
  final double innerWidth = tester.getRect(
    find.descendant(of: cell, matching: find.byType(Stack)),
  ).width;
  final Rect dayNumber = tester.getRect(
    find.descendant(of: cell, matching: find.text(_dayNumberText)),
  );
  final Rect badge = tester.getRect(
    find.descendant(of: cell, matching: find.text(badgeText)),
  );

  return _Geometry(
    containerWidth: width,
    cellWidth: cellWidth,
    innerWidth: innerWidth,
    dayNumber: dayNumber,
    badge: badge,
  );
}

/// 断言一个矩形与基线四元组逐个相等（容差 0.05px）。
void _expectRect(Rect actual, _Rect4 baseline, String label) {
  expect(actual.left, closeTo(baseline.$1, 0.05), reason: '$label left');
  expect(actual.top, closeTo(baseline.$2, 0.05), reason: '$label top');
  expect(actual.right, closeTo(baseline.$3, 0.05), reason: '$label right');
  expect(actual.bottom, closeTo(baseline.$4, 0.05), reason: '$label bottom');
}

/// 那天带形状徽标（`●`）时用的摘要。
const List<CalendarDaySummary> _withShapeBadge = <CalendarDaySummary>[
  CalendarDaySummary(date: '2026-11-24', planDone: 1, planTotal: 2),
];

/// 「改动前」版式的**测试内复刻**：居中日号 + 右上角 `Positioned` 角标。
///
/// 用途：证明本装置有判别力 —— 同一套字体、同一套格内几何下，复刻版必然
/// 与 `Today` 相交（角标宽 57.5px ≫ 单字角标），而现行控件不相交。
///
/// 注意：这是**测试内**的复刻件，**不碰** `widgets\calendar_month_view.dart`。
class _LegacyTodayCell extends StatelessWidget {
  const _LegacyTodayCell();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeTokens t = context.tokens;
    return Container(
      height: 52,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: t.ink, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Text(
                _dayNumberText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: t.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              'Today',
              style: theme.textTheme.labelSmall?.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('英文态：日号与「Today」角标在四个容器宽度下都不相交', (tester) async {
    for (final int width in _widths) {
      final _Geometry en = await _measure(tester, AppLanguage.en, width.toDouble());

      expect(
        en.overlaps,
        isFalse,
        reason: '英文态角标不得与日号重叠：${en.describe('EN')}',
      );
      expect(
        en.overlap.height,
        0,
        reason: '竖直方向必须彻底错开（overlapH 恒为 0）：${en.describe('EN')}',
      );
      expect(
        en.badge.top >= en.dayNumber.bottom,
        isTrue,
        reason: '角标必须在日号下一行：${en.describe('EN')}',
      );

      // 同一天带形状徽标（`●`）时同样不许重叠，也不许把格高撑爆
      // （RenderFlex 溢出会直接让本用例红）。
      final _Geometry enShape = await _measure(
        tester,
        AppLanguage.en,
        width.toDouble(),
        days: _withShapeBadge,
      );
      expect(
        enShape.overlaps,
        isFalse,
        reason: '带形状徽标时也不得重叠：${enShape.describe('EN+SHAPE')}',
      );
      expect(
        enShape.overlap.height,
        0,
        reason: '带形状徽标时竖直方向仍须错开：${enShape.describe('EN+SHAPE')}',
      );
    }
  });

  testWidgets('中文态：日号与「今」角标的矩形与基线逐像素相同', (tester) async {
    for (final int width in _widths) {
      final _Geometry zh = await _measure(
        tester,
        AppLanguage.zh,
        width.toDouble(),
        badgeText: '今',
      );
      final (_Rect4, _Rect4) baseline = _zhBaseline[width]!;

      _expectRect(zh.dayNumber, baseline.$1, 'W=$width 日号');
      _expectRect(zh.badge, baseline.$2, 'W=$width「今」角标');

      // 格内可用宽也跟着钉住：格宽 − 2×margin(1) − 2×padding(3) − 2×border(2)。
      expect(
        zh.innerWidth,
        closeTo(zh.cellWidth - 12, 0.05),
        reason: 'W=$width 格内可用宽：${zh.describe('ZH')}',
      );
    }
  });

  testWidgets('英文态：日号仍在原位（与中文态逐像素相同），只有角标挪了行', (tester) async {
    for (final int width in _widths) {
      final _Geometry en = await _measure(tester, AppLanguage.en, width.toDouble());
      final _Geometry zh = await _measure(
        tester,
        AppLanguage.zh,
        width.toDouble(),
        badgeText: '今',
      );

      _expectRect(en.dayNumber, _zhBaseline[width]!.$1, 'W=$width 英文态日号');
      expect(
        en.badge.top,
        greaterThan(zh.badge.top),
        reason: '英文态角标必须落到日号下方一行：EN=${en.describe('EN')} '
            'ZH=${zh.describe('ZH')}',
      );
    }
  });

  testWidgets('阴性对照：英文态没有「今」，中文态没有「Today」', (tester) async {
    await _measure(tester, AppLanguage.en, 800);
    expect(
      find.text('今'),
      findsNothing,
      reason: '英文态不该残留中文角标',
    );
    expect(find.text('Today'), findsOneWidget);

    await _measure(tester, AppLanguage.zh, 800, badgeText: '今');
    expect(
      find.text('Today'),
      findsNothing,
      reason: '中文态不该残留英文角标',
    );
    expect(find.text('今'), findsOneWidget);
  });

  testWidgets('装置判别力：复刻「改动前」版式时英文角标与日号相交', (tester) async {
    // 改动前（角标贴右上角、日号居中）的重叠宽度：420 → 28.20、600 → 28.20、
    // 800 → 20.46；1680 够宽 ⇒ 本来就不相交（交集宽为负）。
    const Map<int, double> legacyOverlapWidth = <int, double>{
      420: 28.20,
      600: 28.20,
      800: 20.46,
      1680: -42.40,
    };

    // 改动前哪些宽度真的相交（F6 的触发宽度集合）。
    const Map<int, bool> legacyOverlaps = <int, bool>{
      420: true,
      600: true,
      800: true,
      1680: false,
    };

    for (final int width in _widths) {
      final _Geometry en = await _measure(tester, AppLanguage.en, width.toDouble());

      // 复刻版：与生产控件同样的格宽、同样的格内几何，只是角标回到右上角。
      await tester.pumpWidget(
        l10nScope(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: en.cellWidth,
                  child: const _LegacyTodayCell(),
                ),
              ),
            ),
          ),
          language: AppLanguage.en,
        ),
      );
      await tester.pump();

      final Rect legacyDay = tester.getRect(find.text(_dayNumberText));
      final Rect legacyBadge = tester.getRect(find.text('Today'));
      final double legacyOverlap =
          legacyDay.intersect(legacyBadge).width;

      expect(
        legacyOverlap,
        closeTo(legacyOverlapWidth[width]!, 0.05),
        reason: 'W=$width 复刻版重叠宽度应与改动前实测一致：'
            'day=${legacyDay.toString()} badge=${legacyBadge.toString()} '
            'overlapW=${legacyOverlap.toStringAsFixed(2)}',
      );
      expect(
        legacyDay.overlaps(legacyBadge),
        legacyOverlaps[width]!,
        reason: 'W=$width 复刻版的相交判定应与改动前实测一致：'
            'day=${legacyDay.toString()} badge=${legacyBadge.toString()} '
            'overlapW=${legacyOverlap.toStringAsFixed(2)}',
      );
      expect(
        en.overlaps,
        isFalse,
        reason: '现行控件在 W=$width 必须不相交：${en.describe('EN')}',
      );
    }
  });
}
