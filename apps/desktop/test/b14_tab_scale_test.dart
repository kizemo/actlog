// =============================================================================
// B14 · 档位标签条「760 宽实际缩放比例」实测（契约：docs\b14-dispatch.md L50-53）
// =============================================================================
// 派工书原文（L50-53）：
//   「**宽度红线**：标签条有 `FittedBox(scaleDown)`（F3），加二字后 760 宽会触发
//    缩放 ⇒ 若衬线 12px 标签缩放后 < 11px，则把 `_tabPadding` 从 18 回调到 14，
//    或字号维持 12 但允许标签两字一行。
//    **回报里必须给出「760 宽下实际缩放比例」这个数字**（从 widget 尺寸断言取，
//    不许目测）。」
//
// 量具（全部取自 widget 的 layout / paint 数据，不看截图）：
//   1) 绘制比：标签条 `FittedBox` 的 child（自然宽 Row）在**自然坐标**上取两点，
//      `localToGlobal` 后的距离 ÷ 自然距离 = 该轴的实际渲染比例
//      （`RenderFittedBox.applyPaintTransform` 的等比缩放体现在这里）；
//   2) 布局期望：`BoxFit.scaleDown` 的语义只有两种 —— 自然宽 ≤ 可用宽 ⇒ 比例
//      1.0；否则 = 可用宽 ÷ 自然宽。**期望值只由 layout 尺寸算出**，与量具 1
//      对撞 ⇒ 两条独立路径必须一致（这是本文件的核心交叉校验）；
//   3) 字号：标签 `Text.style.fontSize`（盘上实现 = 15）× 量具 1
//      = **标签的实际显示字号**。
//
// 为什么不能用「FittedBox.layout 宽 ÷ child.layout 宽」当比例：`scaleDown` 下
// `RenderFittedBox.performLayout` 会把自身尺寸撑到可用宽（
// `constraints.loosen().constrainSizeAndAttemptToPreserveAspectRatio(...)`），
// 而 child 仍按自然尺寸布局且**不缩放** ⇒ 该比值是 3.70 之类的假信号（实测已证）。
//
// 阈值判据**写进断言**（不只打印）：派工书红线 = 缩放后 < 11px，故
//   `displayFontSize >= 11.0` 必须成立；等价形式 `ratio >= 11 ÷ fontSize`。
//
// 为什么从 widget 取字号而不抄派工书：派工书 L52 / L165 的「衬线 12px」是 B13
// 之前的旧值，盘上 `_tabFontSize = 15`（`goal_blueprint_matrix.dart:181`，B13
// 收口时已加大）。**以盘上实现为准**，本文件不写死 12 / 15。
//
// 用例与派工书的对应关系：
//  T1  760 宽中文态：实测缩放比例 + 实际显示字号 vs 11px 红线（主判据）；
//  T2  1440 宽中文态：对照值（不缩放 ⇒ 比例 1.0，自然宽与 760 组一致）；
//  T3  760 宽英文态：最长标签（`Short-term Goal`）的显示字号 vs 11px 红线；
//  T4  320 宽：量具自检 —— 确实触发 scaleDown，两条路径读数一致；
//  T5  真页面 760 窗口：卡片内边距吃掉宽度后，实测可用宽 / 缩放比例仍不触红线。
// =============================================================================

import 'package:actlog/src/data/goal_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/goals_blueprint_page.dart';
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/goal_blueprint_matrix.dart';
import 'package:actlog/src/widgets/goal_year_matrix.dart' show GoalServesIndex;
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart'
    show ActLogDatabase, openInMemoryActLogDatabase;
import 'package:core_domain/core_domain.dart' show GoalHorizon;
import 'package:flutter/material.dart';
// `RenderFittedBox` 不在 `widgets.dart` 的 show 列表里，必须直接引 rendering。
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_harness.dart';

/// 四个档位标签的 key 片段（顺序即渲染顺序）。
const List<String> _horizonKeys = <String>['ultimate', 'long', 'mid', 'short'];

/// 派工书 L52 的宽度红线：缩放后的标签字号不得低于此值（px）。
///
/// **这个数不是本文件发明的**：它逐字来自派工书「缩放后 < 11px」的判据。
const double _redLineFontPx = 11;

/// 某个档位标签（`TextButton`）。
Finder _tab(String horizonKey) =>
    find.byKey(ValueKey<String>('goal-blueprint-tab-$horizonKey'));

/// `onSplitTodos` 的哑实现（本文件不触发拆分）。
void _noop(GoalRow _) {}

/// 一次「标签条缩放」实测的完整读数。
class _TabScale {
  const _TabScale({
    required this.group,
    required this.window,
    required this.stripWidth,
    required this.availableWidth,
    required this.naturalWidth,
    required this.fittedWidth,
    required this.axisScaleX,
    required this.axisScaleY,
    required this.fontSize,
    required this.labelWidths,
  });

  /// 组名（打印用，便于报告里对齐）。
  final String group;

  /// 视口逻辑宽度（`tester.view.physicalSize.width ÷ devicePixelRatio`）。
  final double window;

  /// 标签条外层 `Container`（key = `goal-blueprint-tab-strip`）的 layout 宽。
  final double stripWidth;

  /// `FittedBox` 收到的最大宽度约束（= 标签条宽 − 左内边距 4）。
  final double availableWidth;

  /// 标签条**未缩放**的自然宽（`FittedBox` 的 child Row layout 宽）。
  final double naturalWidth;

  /// `FittedBox` 自身的 layout 宽（`scaleDown` 会把它撑到可用宽）。
  ///
  /// **只作背景信息**，不参与比例计算（见文件头「为什么不能用 layout 宽比」）。
  final double fittedWidth;

  /// 量具 1（X 轴）：child 自然坐标两点 `localToGlobal` 距离 ÷ 自然距离。
  final double axisScaleX;

  /// 量具 1（Y 轴）：同上，纵向。与 [axisScaleX] 相等 ⇒ 等比、不是拉扁。
  final double axisScaleY;

  /// 标签 `Text.style.fontSize`（未缩放字号；盘上 = 15）。
  final double fontSize;

  /// 每个档位标签的**自然**字形宽（未缩放；`RenderParagraph.size.width`）。
  final Map<String, double> labelWidths;

  /// **实测缩放比例**（绘制变换，判据用这个数）。
  double get scale => axisScaleX;

  /// 量具 2：`BoxFit.scaleDown` 的期望比例，只用 layout 尺寸算。
  double get expectedScale =>
      naturalWidth <= availableWidth + 1e-6 ? 1.0 : availableWidth / naturalWidth;

  /// 标签的**实际显示字号** = 未缩放字号 × 实测比例。
  double get displayFontSize => fontSize * scale;

  /// 红线判据：显示字号是否 ≥ 11px。
  bool get clearsRedLine => displayFontSize >= _redLineFontPx - 1e-9;

  /// 红线判据的等价形式：比例下限 = 11 ÷ 字号。
  double get requiredScale => _redLineFontPx / fontSize;

  /// 显示字号恰好 = 11px 时的「可用宽」下限（比它更窄才触红线）。
  ///
  /// 窗口宽 = 该值 + 4（矩阵级标签条左内边距），报告里据此给临界窗口。
  double get criticalAvailableWidth => naturalWidth * requiredScale;

  /// 单行机读摘要（`flutter test` 输出里可直接抄进报告）。
  String describe() {
    final StringBuffer out = StringBuffer('[B14-TAB-SCALE] group=$group')
      ..write(' window=${window.toStringAsFixed(1)}')
      ..write(' strip=${stripWidth.toStringAsFixed(1)}')
      ..write(' available=${availableWidth.toStringAsFixed(1)}')
      ..write(' natural=${naturalWidth.toStringAsFixed(1)}')
      ..write(' fitted=${fittedWidth.toStringAsFixed(1)}')
      ..write(' scale=${scale.toStringAsFixed(6)}')
      ..write(' scaleY=${axisScaleY.toStringAsFixed(6)}')
      ..write(' expected=${expectedScale.toStringAsFixed(6)}')
      ..write(' font=${fontSize.toStringAsFixed(2)}')
      ..write(' display=${displayFontSize.toStringAsFixed(2)}')
      ..write(' requiredScale=${requiredScale.toStringAsFixed(6)}')
      ..write(' criticalAvailable=${criticalAvailableWidth.toStringAsFixed(1)}')
      ..write(' redLine=${_redLineFontPx.toStringAsFixed(2)}')
      ..write(' verdict=${clearsRedLine ? 'PASS' : 'FAIL'}');
    labelWidths.forEach((String key, double width) {
      out.write(' [${key}_natural=${width.toStringAsFixed(1)}]');
    });
    return out.toString();
  }
}

/// 读取当前 widget 树上标签条的缩放读数。
///
/// [window] 只用于打印与「标签条不超视口」的断言；比例本身全部来自
/// `RenderFittedBox` / `RenderBox` 的 paint 与 layout 数据。
_TabScale _measureTabStrip(
  WidgetTester tester, {
  required String group,
  required double window,
}) {
  final Finder strip =
      find.byKey(const ValueKey<String>('goal-blueprint-tab-strip'));
  expect(strip, findsOneWidget, reason: '$group：标签条必须渲染（key 名不得改）');

  // 标签条里只有一个 `FittedBox`（整条兜底那个）；日期列的 FittedBox 在表格里。
  final Finder fittedFinder =
      find.descendant(of: strip, matching: find.byType(FittedBox));
  expect(
    fittedFinder,
    findsOneWidget,
    reason: '$group：标签条必须恰好一个 FittedBox（多/少都说明结构变了）',
  );

  final RenderFittedBox fitted =
      tester.renderObject<RenderFittedBox>(fittedFinder);
  final RenderBox child = fitted.child!;
  expect(child.hasSize, isTrue, reason: '$group：FittedBox 的 child 必须完成布局');

  // 量具 1：把 child 的自然坐标系映射到全局，横向/纵向各测一次比例。
  // `localToGlobal` 会串上 `RenderFittedBox.applyPaintTransform` 的缩放矩阵。
  final Offset origin = child.localToGlobal(Offset.zero);
  final double axisScaleX =
      (child.localToGlobal(Offset(child.size.width, 0)).dx - origin.dx) /
          child.size.width;
  final double axisScaleY =
      (child.localToGlobal(Offset(0, child.size.height)).dy - origin.dy) /
          child.size.height;

  // 量具 3 的输入端：标签字号 + 每个标签的自然字形宽。
  final Map<String, double> labelWidths = <String, double>{};
  double fontSize = 0;
  for (final String horizonKey in _horizonKeys) {
    final Finder label =
        find.descendant(of: _tab(horizonKey), matching: find.byType(Text));
    expect(
      label,
      findsOneWidget,
      reason: '$group：$horizonKey 标签必须只有一个 Text',
    );
    final double? size = tester.widget<Text>(label).style?.fontSize;
    expect(
      size,
      isNotNull,
      reason: '$group：$horizonKey 标签字号必须显式钉死（否则量不出显示字号）',
    );
    if (fontSize == 0) {
      fontSize = size!;
    } else {
      expect(
        size,
        closeTo(fontSize, 1e-9),
        reason: '$group：四个档位标签必须同一字号（$horizonKey 为 $size）',
      );
    }
    labelWidths[horizonKey] = tester.getSize(label).width;
  }

  return _TabScale(
    group: group,
    window: window,
    stripWidth: tester.getSize(strip).width,
    availableWidth: fitted.constraints.maxWidth,
    naturalWidth: child.size.width,
    fittedWidth: fitted.size.width,
    axisScaleX: axisScaleX,
    axisScaleY: axisScaleY,
    fontSize: fontSize,
    labelWidths: labelWidths,
  );
}

/// 两条路径必须给出同一个比例，且都等于 `scaleDown` 的 layout 期望。
void _expectScaleConsistent(_TabScale s, String label) {
  expect(
    s.axisScaleY,
    closeTo(s.axisScaleX, 1e-6),
    reason: '$label：纵向比 ${s.axisScaleY} 必须等于横向比 ${s.axisScaleX}（等比缩放）',
  );
  expect(
    s.scale,
    closeTo(s.expectedScale, 1e-6),
    reason: '$label：实测比例 ${s.scale} 必须等于 layout 期望 ${s.expectedScale}'
        '（可用宽 ${s.availableWidth} / 自然宽 ${s.naturalWidth}）',
  );
}

/// 直接挂矩阵（形状抄 `b13_polish_test.dart:119-153`）。
///
/// 只放一个空领域行：本文件只量**标签条**的缩放，不需要真实目标。
Future<void> _pumpMatrix(
  WidgetTester tester, {
  required double width,
  AppLocalizations? t,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalBlueprintMatrix(
            t: t ?? AppLocalizations.zh,
            rows: const <GoalBlueprintRow>[
              GoalBlueprintRow(
                domainKey: 'career',
                cells: <GoalHorizon, List<GoalRow>>{},
              ),
            ],
            serves: const GoalServesIndex(
              <String, List<GoalRow>>{},
              <String, List<GoalRow>>{},
            ),
            tracksCount: const <String, int>{},
            onSplitTodos: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 挂起人生蓝图**真页面** + 真库（形状抄 `b13_polish_test.dart:158-193`）。
Future<void> _pumpPage(
  WidgetTester tester, {
  required ActLogRepositories repos,
  required double width,
  AppLanguage language = AppLanguage.zh,
}) async {
  tester.view.physicalSize = Size(width, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(DensityProfile.comfortable),
      home: l10nScope(
        ProviderScope(
          overrides: <Override>[
            currentPreferencesProvider.overrideWithValue(AppPreferences.defaults),
            todayProvider.overrideWithValue('2026-11-25'),
            repositoriesProvider.overrideWithValue(repos),
            goalStoreProvider.overrideWithValue(GoalStore(repos)),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: GoalsBlueprintPage(
                key: const ValueKey<String>('b14-tab-scale-page'),
              ),
            ),
          ),
        ),
        language: language,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('T1 760 宽中文态：实测缩放比例与实际显示字号（红线判据）',
      (WidgetTester tester) async {
    await _pumpMatrix(tester, width: 760);
    final _TabScale s = _measureTabStrip(tester, group: 'zh-760', window: 760);
    debugPrint(s.describe());

    // 标签条不许超出视口（760 是派工书点名的窄视口）。
    expect(
      s.stripWidth,
      lessThanOrEqualTo(760 + 0.01),
      reason: 'T1：标签条宽 ${s.stripWidth} 超出 760 视口',
    );
    _expectScaleConsistent(s, 'T1');
    // 主判据：760 宽下的**实测缩放比例**。
    expect(
      s.naturalWidth,
      lessThanOrEqualTo(s.availableWidth + 1e-6),
      reason: 'T1：自然宽 ${s.naturalWidth} ≤ 可用宽 ${s.availableWidth}'
          ' ⇒ scaleDown 不生效，比例必须是 1.0',
    );
    expect(
      s.scale,
      closeTo(1.0, 1e-6),
      reason: 'T1：760 宽下实测缩放比例 = ${s.scale.toStringAsFixed(6)}，应为 1.0',
    );
    // 红线判据（阈值参与断言，不只打印）。
    expect(
      s.clearsRedLine,
      isTrue,
      reason: 'T1：实测比例 ${s.scale} ⇒ 显示字号 ${s.displayFontSize}'
          ' 必须 ≥ $_redLineFontPx px（红线下限比例 ${s.requiredScale}）',
    );
    expect(
      s.scale,
      greaterThanOrEqualTo(s.requiredScale - 1e-9),
      reason: 'T1：比例 ${s.scale} 必须 ≥ 红线下限 ${s.requiredScale}'
          '（= $_redLineFontPx ÷ ${s.fontSize}）',
    );
  });

  testWidgets('T2 1440 宽中文态：对照值不缩放（比例 1.0）', (WidgetTester tester) async {
    await _pumpMatrix(tester, width: 1440);
    final _TabScale s =
        _measureTabStrip(tester, group: 'zh-1440', window: 1440);
    debugPrint(s.describe());

    expect(
      s.stripWidth,
      closeTo(1440, 0.01),
      reason: 'T2：宽视口下标签条应铺满可用宽（实测 ${s.stripWidth}）',
    );
    _expectScaleConsistent(s, 'T2');
    expect(
      s.scale,
      closeTo(1.0, 1e-6),
      reason: 'T2：1440 宽对照组的实测比例 = ${s.scale.toStringAsFixed(6)}，应为 1.0',
    );
    expect(
      s.displayFontSize,
      closeTo(s.fontSize, 1e-6),
      reason: 'T2：不缩放 ⇒ 显示字号 = 未缩放字号 ${s.fontSize}',
    );
  });

  testWidgets('T3 760 宽英文态：最长标签显示字号仍 ≥ 11px', (WidgetTester tester) async {
    await _pumpMatrix(tester, width: 760, t: AppLocalizations.en);
    final _TabScale s = _measureTabStrip(tester, group: 'en-760', window: 760);
    debugPrint(s.describe());

    _expectScaleConsistent(s, 'T3');
    expect(
      s.stripWidth,
      lessThanOrEqualTo(760 + 0.01),
      reason: 'T3：英文态标签条宽 ${s.stripWidth} 超出 760 视口',
    );
    // 英文标签比中文长（`Short-term Goal` 16 字符）⇒ 这里真的会缩放；
    // 红线与语言无关，判据只有一条：显示字号 ≥ 11px。
    expect(
      s.displayFontSize,
      greaterThanOrEqualTo(_redLineFontPx),
      reason: 'T3：英文态实测比例 ${s.scale} ⇒ 显示字号 ${s.displayFontSize}'
          ' 必须 ≥ $_redLineFontPx px',
    );
  });

  testWidgets('T4 320 宽：量具自检（确实触发 scaleDown 且两路径一致）',
      (WidgetTester tester) async {
    await _pumpMatrix(tester, width: 320);
    final _TabScale s = _measureTabStrip(tester, group: 'zh-320', window: 320);
    debugPrint(s.describe());

    // 若这一组也读出 1.0，说明量具根本量不到缩放 ⇒ 前面几组的 1.0 是假信号。
    expect(
      s.scale,
      lessThan(1.0),
      reason: 'T4：320 宽（可用 ${s.availableWidth} < 自然宽 ${s.naturalWidth}）'
          ' 必须真的缩放，实测比例 ${s.scale} 却未小于 1',
    );
    _expectScaleConsistent(s, 'T4');
    // 缩放时 FittedBox 的布局宽 = 可用宽（= 自然宽 × 比例，±0.01 取整）。
    expect(
      s.fittedWidth,
      closeTo(s.naturalWidth * s.scale, 0.01),
      reason: 'T4：FittedBox 宽 ${s.fittedWidth} 应 = 自然宽 ${s.naturalWidth}'
          ' × 比例 ${s.scale}',
    );
  });

  testWidgets('T5 真页面 760 窗口：卡片内边距吃掉宽度后仍不触红线',
      (WidgetTester tester) async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    addTearDown(db.close);
    await _pumpPage(
      tester,
      repos: ActLogRepositories(db, deviceId: 'b14-tab-scale-test'),
      width: 760,
    );

    final _TabScale s =
        _measureTabStrip(tester, group: 'page-760', window: 760);
    debugPrint(s.describe());

    expect(
      s.availableWidth,
      lessThan(760),
      reason: 'T5：真页面里卡片内边距必然吃掉宽度（实测可用宽 ${s.availableWidth}）',
    );
    _expectScaleConsistent(s, 'T5');
    expect(
      s.scale,
      closeTo(1.0, 1e-6),
      reason: 'T5：真页面 760 窗口下实测比例 = ${s.scale.toStringAsFixed(6)}，应为 1.0',
    );
    expect(
      s.displayFontSize,
      greaterThanOrEqualTo(_redLineFontPx),
      reason: 'T5：真页面实测显示字号 ${s.displayFontSize} 必须 ≥ $_redLineFontPx px',
    );
  });

  testWidgets('T6 真页面 760 窗口英文态：最薄余量也取自实测（不许推算）',
      (WidgetTester tester) async {
    final ActLogDatabase db = openInMemoryActLogDatabase();
    addTearDown(db.close);
    await _pumpPage(
      tester,
      repos: ActLogRepositories(db, deviceId: 'b14-tab-scale-test-en'),
      width: 760,
      language: AppLanguage.en,
    );

    final _TabScale s =
        _measureTabStrip(tester, group: 'page-760-en', window: 760);
    debugPrint(s.describe());

    // 英文标签的长自然宽必须真的出现，否则说明语言没切过去（会给出假的 1.0）。
    expect(
      s.naturalWidth,
      greaterThan(700),
      reason: 'T6：英文四标签自然宽应远大于中文（实测 ${s.naturalWidth}），'
          '过小说明 l10n 没生效',
    );
    expect(
      s.naturalWidth,
      greaterThan(s.availableWidth),
      reason: 'T6：真页面可用宽 ${s.availableWidth} < 英文自然宽 ${s.naturalWidth}'
          ' ⇒ 这里必须真的缩放',
    );
    _expectScaleConsistent(s, 'T6');
    expect(
      s.scale,
      lessThan(1.0),
      reason: 'T6：英文真页面必须缩放，实测比例 ${s.scale} 却为 1',
    );
    // 红线判据：与语言无关，显示字号 ≥ 11px。
    expect(
      s.clearsRedLine,
      isTrue,
      reason: 'T6：英文真页面实测比例 ${s.scale} ⇒ 显示字号 ${s.displayFontSize}'
          ' 必须 ≥ $_redLineFontPx px（下限比例 ${s.requiredScale}）',
    );
  });
}