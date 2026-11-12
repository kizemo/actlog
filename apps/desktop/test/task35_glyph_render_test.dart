// =============================================================================
// task35 · 四维优先级标记的**渲染层像素证据**
// =============================================================================
// 为什么需要这份证据：
//   `priority_marks.dart` 里的四个字形（▲ ▽ ◆ ◇）**不在 Inter 里**，实际显示
//   全靠 `fontFamilyFallback` 里的 `Noto Sans SC` 兜底。字体 cmap 层面已经确认
//   Noto Sans SC 四个码位俱全（reports/task35-glyph-cmap.py），但「cmap 有」
//   不等于「屏幕上画得出来」—— 排版的族回退链、字形选择都可能单独出错。
//
//   本机工作站处于锁定态，屏幕 DC 全黑、`PrintWindow` 对 Flutter 窗返回空白，
//   拿不到真实窗口截图。所以这里用 Flutter 的测试渲染环境：**加载真实字体**
//   （`FontLoader` 注册成与 `AppFonts` 完全一致的族名），用**真实的行 widget**
//   排 5 行（Q1/Q2/Q3/Q4 + 未分级），把 RepaintBoundary 渲成 PNG 落盘。
//   产物：`build/task35-t14/task35_glyph_render.png`（build 目录不入库）。
//
// 这条测试不做视觉断言（无法断言"看起来像三角"），它的价值是：
//   1）结构断言：null 象限不渲染标记（0 枚），四个象限各 2 枚；
//   2）产出可被 **人眼** 复核的 PNG，并把「非空白」量化（颜色数 / 墨迹像素数）。
// =============================================================================

import 'dart:io';
import 'dart:ui' as ui;

import 'package:actlog/src/providers.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/app_tokens.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/priority_marks.dart';
import 'package:actlog/src/widgets/timeline/unscheduled_strip.dart';
import 'package:core_db/core_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 在 riverpod 3 迁到了 misc.dart（与 `timeline_day_grid_test.dart` 同款导入）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定的日历日：`UnscheduledStrip` 只按起止时刻筛选，日期本身不参与渲染。
const String _date = '2026-11-12';

/// 导出目录（build 不入库；测试自己建）。
const String _outDir = 'build/task35-t14';

/// 导出文件名。
const String _outName = 'task35_glyph_render.png';

/// 五行的标题与象限：前四条覆盖 Q1～Q4，最后一条 `quadrant == null` 证明不渲染。
///
/// 标题里写清象限名，人眼复核 PNG 时能与「行首两枚字形」直接对照，
/// 不必回头查代码。
const List<({String title, String? code})> _fixtures = <({String title, String? code})>[
  (title: 'Q1 重要且紧急：写周报', code: 'Q1'),
  (title: 'Q2 重要不紧急：读书 30 页', code: 'Q2'),
  (title: 'Q3 紧急不重要：回邮件', code: 'Q3'),
  (title: 'Q4 不重要不紧急：刷视频', code: 'Q4'),
  (title: '未分级：随手记一条', code: null),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 字体在 `setUpAll` 里加载：`FontLoader.load()` 走引擎侧真实异步，
  // 放进 testWidgets 的 fake async 区里等会有挂死风险（golden_toolkit 同款做法）。
  setUpAll(() async {
    await _loadAppFonts();
  });

  testWidgets('结构：四个象限各 2 枚字形，未分级 0 枚', (WidgetTester tester) async {
    await _pumpFiveRows(tester, null);
    expect(find.byType(UnscheduledStrip), findsNWidgets(5));
    // 未分级那一行不画标记 ⇒ 4 个 PriorityMarks，不是 5 个。
    expect(find.byType(PriorityMarks), findsNWidgets(4));
    expect(find.text(kMarkImportant), findsNWidgets(2)); // Q1 + Q2
    expect(find.text(kMarkNotImportant), findsNWidgets(2)); // Q3 + Q4
    expect(find.text(kMarkUrgent), findsNWidgets(2)); // Q1 + Q3
    expect(find.text(kMarkNotUrgent), findsNWidgets(2)); // Q2 + Q4
    expect(find.text('未分级：随手记一条'), findsOneWidget);
  });

  testWidgets('渲染：导出 PNG 并量化非空白程度', (WidgetTester tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(660, 460));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpFiveRows(tester, boundaryKey);
    await tester.pumpAndSettle();

    final RenderObject? renderObject = boundaryKey.currentContext?.findRenderObject();
    expect(renderObject, isA<RenderRepaintBoundary>());
    final RenderRepaintBoundary boundary = renderObject! as RenderRepaintBoundary;
    expect(boundary.size.width, greaterThan(100));
    expect(boundary.size.height, greaterThan(100));

    final Directory dir = Directory(_outDir)..createSync(recursive: true);
    final File png = File('${dir.path}/$_outName');

    int width = 0;
    int height = 0;
    int variety = 0;
    int inkPixels = 0;

    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      width = image.width;
      height = image.height;
      final ByteData? encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(encoded, isNotNull, reason: 'toImage → PNG 编码返回 null');
      png.writeAsBytesSync(encoded!.buffer.asUint8List());

      final ByteData? raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(raw, isNotNull, reason: 'toImage → rawRgba 返回 null');
      final ({int variety, int ink}) stats = _sample(raw!, image.width, image.height);
      variety = stats.variety;
      inkPixels = stats.ink;
      image.dispose();
    });

    // 文件真的落盘了，且不是几十字节的空壳。
    expect(png.existsSync(), isTrue, reason: 'PNG 未生成：${png.path}');
    final int bytes = png.lengthSync();
    expect(bytes, greaterThan(2000), reason: 'PNG 仅 $bytes 字节，疑似空白图');
    expect(width, greaterThan(0));
    expect(height, greaterThan(0));

    // 「非空白」的量化下限：底色 + 芯片底 + 边框 + 墨色文字/字形必然产生多种颜色。
    expect(variety, greaterThan(5), reason: 'PNG 颜色种类仅 $variety，疑似单色图');
    expect(inkPixels, greaterThan(500), reason: 'PNG 墨迹像素仅 $inkPixels，疑似空白图');
  });
}

/// 注册与 `AppFonts` **逐字一致**的族名，让兜底链在测试环境里也成立。
///
/// 只注册真正参与本图渲染的两族：`body`（Inter）与其首个兜底（Noto Sans SC）。
/// 四个字形不在 Inter 里 ⇒ 实际画它们的一定是 Noto Sans SC。
Future<void> _loadAppFonts() async {
  await _registerFont(AppFonts.body, <String>['assets/fonts/Inter-400.ttf']);
  await _registerFont(
    AppFonts.bodyFallback.first,
    <String>['assets/fonts/NotoSansSC-Regular.ttf'],
  );
}

/// 从 rootBundle 读字体字节并以 [family] 注册。
///
/// 兜底：极端情况下（测试资产清单未收字体）直接读工程内的 ttf，
/// 保证这条测试的判据不依赖 asset manifest 的细节。
Future<void> _registerFont(String family, List<String> assetPaths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in assetPaths) {
    loader.addFont(_fontBytes(path));
  }
  await loader.load();
}

Future<ByteData> _fontBytes(String assetPath) async {
  try {
    return await rootBundle.load(assetPath);
  } on Exception {
    final File file = File(assetPath);
    expect(file.existsSync(), isTrue, reason: '字体文件不存在：$assetPath');
    return ByteData.sublistView(file.readAsBytesSync());
  }
}

/// 每一行都用**真实行 widget** `UnscheduledStrip`（内部 `_chip` → `PriorityMarks`）。
///
/// 每行独立一个 `ProviderScope`，把 `planItemsProvider` 钉成「只有这一条」的
/// `AsyncData`，保证 5 行各占一行、互不干扰（真实的 `Wrap` 会把窄芯片并排）。
Future<void> _pumpFiveRows(WidgetTester tester, GlobalKey? boundaryKey) async {
  final Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(DensityProfile.comfortable),
    home: Scaffold(
      backgroundColor: AppTokens.paper,
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            width: 560,
            color: AppTokens.paper,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'task35 · 四维优先级标记渲染证据 · 5 行（Q1–Q4 + 未分级）',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontFamilyFallback: AppFonts.bodyFallback,
                    fontSize: 12,
                    color: AppTokens.ink,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < _fixtures.length; i++)
                  ProviderScope(
                    overrides: <Override>[
                      planItemsProvider.overrideWithValue(
                        AsyncData<List<PlanItemData>>(<PlanItemData>[_rowOf(i)]),
                      ),
                    ],
                    child: UnscheduledStrip(key: ValueKey<String>('task35-row-$i')),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(app);
  await tester.pump();
}

/// 第 [index] 条夹具 → drift 行实体（`plannedStart/plannedEnd` 全 null ⇒ 落在未排期带）。
PlanItemData _rowOf(int index) {
  final ({String title, String? code}) fixture = _fixtures[index];
  return PlanItemData(
    id: 'task35-row-$index',
    date: _date,
    title: fixture.title,
    detail: '',
    sourceType: 'manual',
    quadrant: fixture.code,
    domain: 'work',
    status: 'planned',
    resultNote: '',
    isHabitRef: 0,
    createdAt: 0,
    updatedAt: 0,
    originDeviceId: 'task35-render',
    rev: 1,
  );
}

/// 统计 RGBA 图的颜色种类数与「墨迹」像素数（与底色 `AppTokens.paper` 不同的像素）。
({int variety, int ink}) _sample(ByteData rgba, int width, int height) {
  const int bgR = 0xF6;
  const int bgG = 0xF4;
  const int bgB = 0xEF;
  final Set<int> colors = <int>{};
  int ink = 0;
  final int total = width * height;
  for (int i = 0; i < total; i++) {
    final int offset = i * 4;
    final int r = rgba.getUint8(offset);
    final int g = rgba.getUint8(offset + 1);
    final int b = rgba.getUint8(offset + 2);
    colors.add((r << 16) | (g << 8) | b);
    if (r != bgR || g != bgG || b != bgB) {
      ink++;
    }
  }
  return (variety: colors.length, ink: ink);
}