import 'dart:io';

import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/shell/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Task 48 判别性测试：顶栏品牌位按主题亮暗选**两份真实资产**之一。
///
/// 纪律（契约 §3.1 / §4）：
/// * 亮 / 暗各锁定一个 `AssetImage.assetName` —— 分支删掉或资产名写反必红；
/// * 两份 PNG 都是 8 位 RGBA（颜色类型 6）、IHDR 宽高逐字相同、**alpha 逐像素一致**
///   （真解 IDAT，不退化成「透明像素比例相同」的弱判据）；
/// * 暗色主题下渲染不抛异常，品牌位仍有非零尺寸，且没有挤坏顶栏布局。
///
/// 为什么不解码成 `ui.Image`：widget 测试里走真实 asset 通道会挂住；
/// 这里一律读字节做纯几何校验（`flutter test` 的工作目录就是 package 根）。

/// 浅色主题品牌资产（黑字标）。
const String _lightAssetName = 'assets/brand_mark.png';

/// 暗色主题品牌资产（白字标，与浅色同几何，仅 RGB 换白）。
const String _darkAssetName = 'assets/brand_mark_dark.png';

/// 挂一个只含顶栏的最小宿主（`window_manager` 完全不参与：顶栏只吃注入的回调）。
Future<void> _pumpBar(WidgetTester tester, {required ThemeData theme}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: AppTopBar(isMaximized: ValueNotifier<bool>(false))),
    ),
  );
}

/// 读文件字节（路径相对 package 根）。
List<int> _readAsset(String name) => File(name).readAsBytesSync();

/// PNG 大端 32 位整数（偏移量相对文件头）。
int _beUint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

/// Paeth 预测器（PNG 规范 §9.4，滤波类型 4）。
int _paeth(int a, int b, int c) {
  final int p = a + b - c;
  final int pa = (p - a).abs();
  final int pb = (p - b).abs();
  final int pc = (p - c).abs();
  if (pa <= pb && pa <= pc) {
    return a;
  }
  if (pb <= pc) {
    return b;
  }
  return c;
}

/// 把 PNG 的 IDAT 解出来并逐行反滤波，返回**按行优先顺序**的 alpha 字节。
///
/// 只支持本仓库这两份资产的实际格式（8 位、颜色类型 6、非隔行），格式不符直接红。
List<int> _alphaChannel(List<int> png) {
  final int width = _beUint32(png, 16);
  final int height = _beUint32(png, 20);
  final int bitDepth = png[24];
  final int colorType = png[25];
  final int interlace = png[28];
  expect(bitDepth, 8, reason: '本校验只支持 8 位深');
  expect(colorType, 6, reason: '本校验只支持 RGBA（颜色类型 6）');
  expect(interlace, 0, reason: '本校验只支持非隔行 PNG');

  // 收集所有 IDAT 块（长 PNG 会被切成多块）。
  final List<int> idat = <int>[];
  int offset = 8;
  while (offset + 8 <= png.length) {
    final int length = _beUint32(png, offset);
    final String type =
        String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    if (type == 'IDAT') {
      idat.addAll(png.sublist(offset + 8, offset + 8 + length));
    }
    if (type == 'IEND') {
      break;
    }
    offset += 12 + length;
  }
  expect(idat, isNotEmpty, reason: 'IDAT 块缺失');

  final List<int> raw = ZLibDecoder().convert(idat);

  const int bpp = 4; // 8 位 RGBA ⇒ 每像素 4 字节
  final int stride = width * bpp;
  expect(
    raw.length,
    height * (stride + 1),
    reason: '解压长度与 IHDR 不符（扫描线 = 1 滤波字节 + 像素行）',
  );

  final List<int> alpha = <int>[];
  List<int> previous = List<int>.filled(stride, 0);
  int cursor = 0;
  for (int y = 0; y < height; y++) {
    final int filter = raw[cursor++];
    final List<int> current = List<int>.filled(stride, 0);
    for (int x = 0; x < stride; x++) {
      final int value = raw[cursor + x];
      final int left = x >= bpp ? current[x - bpp] : 0;
      final int up = previous[x];
      final int upLeft = x >= bpp ? previous[x - bpp] : 0;
      final int predictor;
      switch (filter) {
        case 0:
          predictor = 0;
        case 1:
          predictor = left;
        case 2:
          predictor = up;
        case 3:
          predictor = (left + up) >> 1;
        case 4:
          predictor = _paeth(left, up, upLeft);
        default:
          fail('未知 PNG 滤波类型 $filter（第 $y 行）');
      }
      current[x] = (value + predictor) & 0xFF;
    }
    cursor += stride;
    for (int x = 3; x < stride; x += bpp) {
      alpha.add(current[x]);
    }
    previous = current;
  }
  return alpha;
}

void main() {
  testWidgets('浅色主题：品牌位用黑字标 assets/brand_mark.png', (WidgetTester tester) async {
    await _pumpBar(tester, theme: AppTheme.light(DensityProfile.comfortable));

    final Finder mark = find.byKey(AppTopBar.brandMarkKey);
    expect(mark, findsOneWidget);

    final Image image = tester.widget<Image>(mark);
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, _lightAssetName);
    expect(image.height, 16);
  });

  testWidgets('暗色主题：品牌位用白字标 assets/brand_mark_dark.png', (WidgetTester tester) async {
    await _pumpBar(tester, theme: AppTheme.dark(DensityProfile.comfortable));

    final Finder mark = find.byKey(AppTopBar.brandMarkKey);
    expect(mark, findsOneWidget);

    final Image image = tester.widget<Image>(mark);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      _darkAssetName,
      reason: '暗色主题必须换成白字标；分支丢失或资产名写反都会落回黑字标',
    );
    expect(image.height, 16);
  });

  testWidgets('暗色主题渲染不抛异常：品牌位 16 高、宽度按 231:76 等比、顶栏布局不挤', (
    WidgetTester tester,
  ) async {
    await _pumpBar(tester, theme: AppTheme.dark(DensityProfile.comfortable));

    // widget 测试默认跑假异步，`Image.asset` 的图不会被解码 ⇒ 品牌位宽度恒为 0。
    // 这里显式把资产解出来，才能量到**真实**的等比宽度（≈48.63）。
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(_darkAssetName),
        tester.element(find.byType(AppTopBar)),
      );
    });
    await tester.pump();

    // Row 溢出会在测试里记成异常 ⇒ 这里必须为空。
    expect(tester.takeException(), isNull);

    final Rect bar = tester.getRect(find.byType(AppTopBar));
    final Rect mark = tester.getRect(find.byKey(AppTopBar.brandMarkKey));
    final Rect drag = tester.getRect(find.byKey(AppTopBar.dragAreaKey));
    final Rect close = tester.getRect(find.byKey(AppTopBar.closeButtonKey));

    expect(mark.height, 16);
    expect(mark.width, greaterThan(0));
    // 新字标 231×76（≈3.04:1）⇒ 16 高时宽 ≈48.63（旧素材 64×32 只有 32 宽）。
    // 精确到浮点：Image 按 intrinsic 比例算宽，没有像素吸附 ⇒ 3696/76 = 48.63157894736842。
    expect(
      mark.width,
      moreOrLessEquals(231 / 76 * 16, epsilon: 1e-9),
      reason: '实测宽度 ${mark.width}',
    );

    // 字符串装配没被挤坏：左内边距 16、字标 → 拖拽区 → 关闭钮 依次不重叠。
    expect(mark.left - bar.left, closeTo(16, 0.01));
    expect(mark.right, lessThanOrEqualTo(drag.left));
    expect(drag.right, lessThanOrEqualTo(close.left));
    expect(drag.width, greaterThan(400), reason: '拖拽区实测宽 ${drag.width}');
    // 三钮仍贴顶栏右端（宽度变宽没把右侧挤出去）。
    expect(bar.right - close.right, lessThan(0.01));
    expect(bar.width, 800);
  });

  test('两份品牌资产都是 RGBA 且 IHDR 宽高逐字相同', () {
    for (final String name in <String>[_lightAssetName, _darkAssetName]) {
      final List<int> png = _readAsset(name);
      expect(png.length, greaterThan(24), reason: '$name 太短');
      expect(
        png.sublist(0, 8),
        <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: '$name 不是合法 PNG 签名',
      );
      expect(
        png.sublist(12, 16),
        <int>[0x49, 0x48, 0x44, 0x52],
        reason: '$name 缺 IHDR',
      );
      // 颜色类型 6 = RGBA（透明底纯形）；位深 8。
      expect(png[25], 6, reason: '$name 颜色类型应为 6（RGBA）');
      expect(png[24], 8, reason: '$name 位深应为 8');
      // 已知几何：两份都是 231×76。
      expect(_beUint32(png, 16), 231, reason: '$name 宽');
      expect(_beUint32(png, 20), 76, reason: '$name 高');
    }
  });

  test('两份品牌资产的 alpha 通道逐像素一致（真解 PNG，不退化为比例判据）', () {
    final List<int> light = _alphaChannel(_readAsset(_lightAssetName));
    final List<int> dark = _alphaChannel(_readAsset(_darkAssetName));

    expect(light.length, 231 * 76);
    expect(dark.length, light.length);

    // 判据不能被「两张都全透明」骗过：字标必须有实际墨迹。
    final int inked = light.where((int a) => a > 0).length;
    expect(inked, greaterThan(1000), reason: '浅色字标非透明像素仅 $inked 个');

    int differing = 0;
    int firstDiffering = -1;
    for (int i = 0; i < light.length; i++) {
      if (light[i] != dark[i]) {
        differing++;
        if (firstDiffering < 0) {
          firstDiffering = i;
        }
      }
    }
    expect(
      differing,
      0,
      reason: 'alpha 差异 $differing 个像素（首个下标 $firstDiffering）'
          '：两份资产应只换 RGB，几何/透明度必须一致',
    );
  });

  test('pubspec.yaml 的 assets 段确实声明了 brand_mark_dark.png', () {
    final List<String> lines = File('pubspec.yaml').readAsLinesSync();
    final bool declared = lines.any(
      (String line) => line.trimLeft().startsWith('- assets/brand_mark_dark.png'),
    );
    expect(declared, isTrue, reason: 'pubspec.yaml 缺 assets/brand_mark_dark.png 条目');
    // 黑字标那条也必须在（两份资产都在 assets 段里，不是只剩一份）。
    expect(
      lines.any((String line) => line.trimLeft() == '- assets/brand_mark.png'),
      isTrue,
    );
  });

  test('品牌位不靠染色实现：源码里没有 srcIn / BlendMode / 硬编码色值', () {
    final String source =
        File('lib/src/widgets/shell/app_top_bar.dart').readAsStringSync();
    // 禁用做法：`Image.asset(color: ...) + BlendMode.srcIn`（抗锯齿边缘二次相乘发虚）。
    expect(source.contains('srcIn'), isFalse);
    expect(source.contains('BlendMode'), isFalse);
    // 颜色由 PNG 自带 ⇒ 文件里不得出现 `Color(0x...)` 字面量。
    expect(RegExp(r'Color\(0x').hasMatch(source), isFalse);
    // 两份资产名都必须是源码里出现的字面量（各一支分支）。
    expect(source.contains(_lightAssetName), isTrue);
    expect(source.contains(_darkAssetName), isTrue);
  });
}