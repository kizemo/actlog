import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:actlog/src/app_version.dart';
import 'package:actlog/src/theme/app_fonts.dart';

/// Task 46 · W1 判别性守卫（撤掉本轮修复即红）。
///
/// 两件事：
/// 1. **版本口径统一到 `1.0.0` + build `1`**：`app_version.dart` 的常量、
///    `pubspec.yaml` 的 `version:`、以及安装器口径必须同源，不许一处 0.1.0。
/// 2. **随包 CJK 衬线真的覆盖中文字符**：D-6 的根因是 `display` 栈里的
///    `Noto Serif SC` 没随包 ⇒ 中文标题落到系统宋体。只断言「文件存在」或
///    「字节数很大」挡不住这种缺陷（空壳字体 / 拉丁子集都能过）⇒ 必须**解析
///    `cmap` 表**看码点是否真有字形。
void main() {
  final Directory root = _packageRoot();
  final String pubspecText =
      File('${root.path}/pubspec.yaml').readAsStringSync();

  group('Task 46 版本口径', () {
    test('::T46-V1:: pubspec 的 version 与 kAppVersion / kAppBuildNumber 逐字一致', () {
      final RegExpMatch? match = RegExp(
        r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
        multiLine: true,
      ).firstMatch(pubspecText);
      expect(match, isNotNull, reason: 'pubspec.yaml 里没找到 `version: x.y.z+n` 行');

      expect(
        match!.group(0)!.trim(),
        'version: 1.0.0+1',
        reason: 'pubspec 版本必须逐字是 `version: 1.0.0+1`（安装器 make_installer.ps1 '
            '默认 -Version 1.0.0，三者必须同口径）',
      );
      expect(match.group(1), '1.0.0', reason: 'pubspec 的语义化版本段');
      expect(match.group(2), '1', reason: 'pubspec 的构建号段');
      expect(kAppVersion, '1.0.0', reason: '应用自报版本必须与 pubspec 同口径');
      expect(kAppBuildNumber, '1', reason: '构建号');
      expect(
        kAppVersionFull,
        '1.0.0+1',
        reason: '关于页 / 设置页显示的合并串',
      );
      expect(match.group(1), kAppVersion);
      expect(match.group(2), kAppBuildNumber);
    });
  });

  group('Task 46 随包 CJK 衬线（D-6）', () {
    const String serifAsset = 'assets/fonts/NotoSerifSC-Regular.ttf';
    final File serif = File('${root.path}/$serifAsset');

    test('::T46-V2:: 随包衬线 TTF 的 cmap 覆盖 中 / 知 / 行', () {
      expect(
        serif.existsSync(),
        isTrue,
        reason: '缺随包衬线 $serifAsset ⇒ 中文 display 仍会落到系统宋体 SimSun（D-6 未闭合）',
      );
      final List<int> bytes = serif.readAsBytesSync();
      expect(
        bytes.sublist(0, 4),
        <int>[0x00, 0x01, 0x00, 0x00],
        reason: '$serifAsset 不是 TrueType sfnt（magic 00010000）',
      );

      final _TtfProbe probe = _TtfProbe(bytes);
      expect(
        probe.subtableFormats,
        isNotEmpty,
        reason: '$serifAsset 没有可解析的 cmap 子表（format 4 / 12 至少一个）',
      );

      const Map<int, String> required = <int, String>{
        0x4E2D: '中',
        0x77E5: '知',
        0x884C: '行',
      };
      final List<String> missing = <String>[];
      required.forEach((int codePoint, String char) {
        if (!probe.covers(codePoint)) {
          missing.add('$char(U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')})');
        }
      });
      expect(
        missing,
        isEmpty,
        reason: '$serifAsset 的 cmap 不覆盖 ${missing.join('、')} ⇒ '
            '中文标题会缺字 / 回退系统宋体，「随包衬线」只是名义上的',
      );
    });

    test('::T46-V3:: 随包衬线是全量 CJK 字体，不是拉丁子集', () {
      final List<int> bytes = serif.readAsBytesSync();
      final _TtfProbe probe = _TtfProbe(bytes);
      expect(
        probe.glyphCount,
        greaterThanOrEqualTo(20000),
        reason: '$serifAsset 只有 ${probe.glyphCount} 个 glyph ⇒ 是子集（全量 Noto Serif SC '
            '是数万 glyph 级），中文覆盖必不完整',
      );
    });

    test('::T46-V4:: pubspec 把 family Noto Serif SC 指向随包文件', () {
      expect(
        pubspecText,
        contains('- family: Noto Serif SC'),
        reason: '缺 `- family: Noto Serif SC` 声明 ⇒ Flutter 不认识该族，'
            'display 栈里的 `Noto Serif SC` 仍回退系统字体',
      );
      expect(
        pubspecText,
        contains('asset: $serifAsset'),
        reason: '声明里没有 $serifAsset',
      );
      final int familyIdx = pubspecText.indexOf('- family: Noto Serif SC');
      final int assetIdx = pubspecText.indexOf('asset: $serifAsset');
      expect(
        assetIdx,
        greaterThan(familyIdx),
        reason: 'asset 行必须在 family 行之后（YAML 缩进归属）',
      );
      expect(
        assetIdx - familyIdx,
        lessThan(400),
        reason: 'family 与 asset 距离过远 ⇒ 大概率落到了别的族下面',
      );
    });

    test('::T46-V5:: display 栈里 Noto Serif SC 排在 SimSun 之前', () {
      final List<String> stack = <String>[
        AppFonts.display,
        ...AppFonts.displayFallback,
      ];
      final int serifIdx = stack.indexOf('Noto Serif SC');
      final int simSunIdx = stack.indexOf('SimSun');
      expect(
        serifIdx,
        greaterThanOrEqualTo(0),
        reason: 'display 栈里没有 Noto Serif SC ⇒ 中文标题无随包衬线可用',
      );
      expect(simSunIdx, greaterThanOrEqualTo(0), reason: 'SimSun 兜底被删掉了');
      expect(
        serifIdx,
        lessThan(simSunIdx),
        reason: '顺序反了：SimSun（系统宋体）会先命中，随包衬线等于没生效',
      );
    });

    test('::T46-V6:: 五份 OFL 齐全，衬线那份是 OFL 1.1 全文', () {
      final Directory licDir = Directory('${root.path}/assets/fonts/licenses');
      expect(licDir.existsSync(), isTrue);
      final List<String> names = licDir
          .listSync()
          .map((FileSystemEntity e) => e.path.split(RegExp(r'[/\\]')).last)
          .toList();
      expect(
        names.length,
        5,
        reason: '许可必须五份（inter / fraunces / jetbrainsmono / notosanssc / notoserifsc），'
            '现有：${names.join('、')}',
      );
      final File serifLicense = File('${licDir.path}/OFL-notoserifsc.txt');
      expect(
        serifLicense.existsSync(),
        isTrue,
        reason: '缺 OFL-notoserifsc.txt ⇒ OFL 要求重分发时附带许可',
      );
      final String body = serifLicense.readAsStringSync();
      expect(body.contains('SIL OPEN FONT LICENSE'), isTrue);
      expect(
        body.contains('SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007'),
        isTrue,
        reason: '衬线许可缺 OFL 1.1 正文标题（不得是凭记忆改写的文本）',
      );
      expect(serifLicense.lengthSync(), greaterThan(1000));
    });
  });
}

// ---------------------------------------------------------------------------
// 最小 sfnt / cmap 读取器（只回答「这个码点有没有字形」）。
//
// 为什么不用第三方包：本仓库对新增依赖极谨慎（关于页 / 离线优先都要审），
// 而这里只需要 40 行大端解析。format 4（BMP 分段）与 format 12（分组）
// 是 CJK 字体必备的两种子表，其余格式顺带支持以便断言失败时报得清。
// ---------------------------------------------------------------------------

int _u8(List<int> b, int o) => b[o];

int _u16(List<int> b, int o) => (b[o] << 8) | b[o + 1];

int _u32(List<int> b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

class _TtfProbe {
  _TtfProbe(this.bytes) {
    final int numTables = _u16(bytes, 4);
    for (int i = 0; i < numTables; i++) {
      final int rec = 12 + i * 16;
      final String tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
      if (tag == 'cmap') {
        _cmapOffset = _u32(bytes, rec + 8);
      } else if (tag == 'maxp') {
        _maxpOffset = _u32(bytes, rec + 8);
      }
    }
    if (_cmapOffset < 0) {
      return;
    }
    final int count = _u16(bytes, _cmapOffset + 2);
    final Set<int> seen = <int>{};
    for (int i = 0; i < count; i++) {
      final int rec = _cmapOffset + 4 + i * 8;
      final int subtable = _cmapOffset + _u32(bytes, rec + 4);
      if (seen.add(subtable)) {
        _subtables.add(subtable);
      }
    }
  }

  final List<int> bytes;
  int _cmapOffset = -1;
  int _maxpOffset = -1;
  final List<int> _subtables = <int>[];

  /// 各子表的 `format`（报错时给线索用）。
  List<int> get subtableFormats =>
      _subtables.map((int o) => _u16(bytes, o)).toList();

  /// `maxp.numGlyphs`；没有 `maxp` 表返回 0。
  int get glyphCount => _maxpOffset < 0 ? 0 : _u16(bytes, _maxpOffset + 4);

  /// 该字体是否有码点 [codePoint] 的字形。
  bool covers(int codePoint) {
    for (final int base in _subtables) {
      switch (_u16(bytes, base)) {
        case 0:
          if (codePoint < 256 && _u8(bytes, base + 6 + codePoint) != 0) {
            return true;
          }
          break;
        case 4:
          if (_format4Covers(base, codePoint)) {
            return true;
          }
          break;
        case 6:
          final int first = _u16(bytes, base + 6);
          final int entryCount = _u16(bytes, base + 8);
          if (codePoint >= first && codePoint < first + entryCount) {
            final int glyph =
                _u16(bytes, base + 10 + (codePoint - first) * 2);
            if (glyph != 0) {
              return true;
            }
          }
          break;
        case 12:
          if (_format12Covers(base, codePoint)) {
            return true;
          }
          break;
        default:
          break;
      }
    }
    return false;
  }

  bool _format4Covers(int base, int codePoint) {
    if (codePoint > 0xFFFF) {
      return false;
    }
    final int segCountX2 = _u16(bytes, base + 6);
    final int segCount = segCountX2 ~/ 2;
    final int endBase = base + 14;
    final int startBase = endBase + segCountX2 + 2;
    final int deltaBase = startBase + segCountX2;
    final int rangeBase = deltaBase + segCountX2;
    for (int seg = 0; seg < segCount; seg++) {
      final int end = _u16(bytes, endBase + seg * 2);
      if (end < codePoint) {
        continue;
      }
      final int start = _u16(bytes, startBase + seg * 2);
      if (start > codePoint) {
        return false;
      }
      final int delta = _u16(bytes, deltaBase + seg * 2);
      final int rangeOffset = _u16(bytes, rangeBase + seg * 2);
      if (rangeOffset == 0) {
        return ((codePoint + delta) & 0xFFFF) != 0;
      }
      final int glyphAddr =
          rangeBase + seg * 2 + rangeOffset + (codePoint - start) * 2;
      if (glyphAddr + 1 >= bytes.length) {
        return false;
      }
      final int glyph = _u16(bytes, glyphAddr);
      return glyph != 0 && ((glyph + delta) & 0xFFFF) != 0;
    }
    return false;
  }

  bool _format12Covers(int base, int codePoint) {
    final int nGroups = _u32(bytes, base + 12);
    for (int g = 0; g < nGroups; g++) {
      final int rec = base + 16 + g * 12;
      final int start = _u32(bytes, rec);
      if (codePoint < start) {
        return false;
      }
      if (codePoint <= _u32(bytes, rec + 4)) {
        return true;
      }
    }
    return false;
  }
}

/// 包根（`apps/desktop`）：从当前目录向上找 `name: actlog` 的 pubspec。
Directory _packageRoot() {
  Directory dir = Directory.current;
  while (true) {
    final File pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('name: actlog')) {
      return dir;
    }
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('找不到 actlog 包根（cwd=${Directory.current.path}）');
    }
    dir = parent;
  }
}