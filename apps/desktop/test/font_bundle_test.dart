import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:actlog/src/theme/app_fonts.dart';

/// 一条 `pubspec.yaml` 里 `flutter.fonts` 的声明：族名 + 字重 + 资源路径。
class _FontDecl {
  const _FontDecl(this.family, this.weight, this.asset);

  final String family;
  final int weight;
  final String asset;
}

/// 包的根目录（`apps/desktop`）：从当前目录向上找 `name: actlog` 的 pubspec。
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

/// 行首缩进宽度（空格数）。
int _indentOf(String line) {
  int n = 0;
  while (n < line.length && line[n] == ' ') {
    n++;
  }
  return n;
}

/// 找到**顶层**键（缩进 0）的行号；找不到返回 -1。
///
/// ★ 必须按缩进定位：`pubspec.yaml` 里 `dependencies:` 下也有一个 `flutter:`，
/// 只按 `trim()` 匹配会命中那个缩进 2 的同名键，解析结果全空。
int _findTopLevelKey(List<String> lines, String key) {
  for (int i = 0; i < lines.length; i++) {
    if (_indentOf(lines[i]) == 0 && lines[i].trim() == '$key:') {
      return i;
    }
  }
  return -1;
}

/// 在 `flutter:` 块内找到子键（如 `fonts:` / `assets:`）的行号；找不到返回 -1。
int _findChildKey(List<String> lines, int parentIdx, String key) {
  for (int i = parentIdx + 1; i < lines.length; i++) {
    final String line = lines[i];
    if (line.trim().isEmpty) {
      continue;
    }
    final int indent = _indentOf(line);
    if (indent == 0) {
      return -1; // 出了 flutter: 块
    }
    if (indent == 2 && line.trim() == '$key:') {
      return i;
    }
  }
  return -1;
}

/// 解析 `flutter.fonts` 段（行级解析，避免为本守卫测试引入 yaml 依赖）。
List<_FontDecl> _parseFonts(String text) {
  final List<String> lines = text.split('\n');
  final int flutterIdx = _findTopLevelKey(lines, 'flutter');
  if (flutterIdx < 0) {
    return <_FontDecl>[];
  }
  final int fontsIdx = _findChildKey(lines, flutterIdx, 'fonts');
  if (fontsIdx < 0) {
    return <_FontDecl>[];
  }
  final int fontsIndent = _indentOf(lines[fontsIdx]);
  final List<_FontDecl> out = <_FontDecl>[];
  String family = '';
  String asset = '';
  for (int i = fontsIdx + 1; i < lines.length; i++) {
    final String line = lines[i];
    if (line.trim().isEmpty) {
      continue;
    }
    if (_indentOf(line) <= fontsIndent) {
      break;
    }
    final String t = line.trim();
    if (t.startsWith('- family:')) {
      family = t.substring('- family:'.length).trim();
      asset = '';
    } else if (t.startsWith('- asset:')) {
      asset = t.substring('- asset:'.length).trim();
    } else if (t.startsWith('weight:') && family.isNotEmpty && asset.isNotEmpty) {
      out.add(_FontDecl(family, int.parse(t.substring('weight:'.length).trim()), asset));
      asset = '';
    }
  }
  return out;
}

/// 解析 `flutter.assets` 段的条目列表。
List<String> _parseAssets(String text) {
  final List<String> lines = text.split('\n');
  final int flutterIdx = _findTopLevelKey(lines, 'flutter');
  if (flutterIdx < 0) {
    return <String>[];
  }
  final int assetsIdx = _findChildKey(lines, flutterIdx, 'assets');
  if (assetsIdx < 0) {
    return <String>[];
  }
  final int assetsIndent = _indentOf(lines[assetsIdx]);
  final List<String> out = <String>[];
  for (int i = assetsIdx + 1; i < lines.length; i++) {
    final String line = lines[i];
    if (line.trim().isEmpty) {
      continue;
    }
    if (_indentOf(line) <= assetsIndent) {
      break;
    }
    final String t = line.trim();
    if (t.startsWith('- ')) {
      out.add(t.substring(2).trim());
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// TrueType `name` 表的最小解析器（大端）。
//
// 为什么必须解析：`pubspec.yaml` 的 `family:` 与字体文件内部的**排版族名**
// 不一致时，Flutter 不会报错，只会静默回退到系统字体 ⇒「打包了但没生效」。
// 只看文件存在 + magic 是挡不住这种缺陷的。
//
// 口径（上游 handoff 记载的坑）：Google Fonts 的静态实例 nameID 1 可能是
// 旧式族名（`Inter Medium` / `Fraunces SemiBold` / `Noto Sans SC Thin`），
// **nameID 16 才是排版族名** ⇒ 判族名时 16 优先、1 交叉。
// ---------------------------------------------------------------------------

/// 读入字体文件后解析出的 `name` 表：nameID → 文本。
Map<int, String> _readNameTable(List<int> bytes) {
  final int numTables = _u16(bytes, 4);
  int nameOffset = -1;
  for (int i = 0; i < numTables; i++) {
    final int rec = 12 + i * 16;
    final String tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
    if (tag == 'name') {
      nameOffset = _u32(bytes, rec + 8);
      break;
    }
  }
  if (nameOffset < 0) {
    return <int, String>{};
  }
  final int count = _u16(bytes, nameOffset + 2);
  final int stringOffset = _u16(bytes, nameOffset + 4);
  final Map<int, String> best = <int, String>{};
  final Set<int> preferred = <int>{};
  for (int i = 0; i < count; i++) {
    final int rec = nameOffset + 6 + i * 12;
    final int platformId = _u16(bytes, rec);
    final int languageId = _u16(bytes, rec + 4);
    final int nameId = _u16(bytes, rec + 6);
    final int length = _u16(bytes, rec + 8);
    final int offset = _u16(bytes, rec + 10);
    final int start = nameOffset + stringOffset + offset;
    final String text =
        _decodeName(platformId, bytes.sublist(start, start + length)).trim();
    final bool isPreferred = platformId == 3 && languageId == 0x0409;
    if (!best.containsKey(nameId) || (isPreferred && !preferred.contains(nameId))) {
      best[nameId] = text;
      if (isPreferred) {
        preferred.add(nameId);
      }
    }
  }
  return best;
}

int _u16(List<int> b, int o) => (b[o] << 8) | b[o + 1];

int _u32(List<int> b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

/// name 表的字符串编码：platform 0/3 是 UTF-16BE，其余按 Latin-1。
String _decodeName(int platformId, List<int> raw) {
  if (platformId == 0 || platformId == 3) {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i + 1 < raw.length; i += 2) {
      sb.writeCharCode((raw[i] << 8) | raw[i + 1]);
    }
    return sb.toString();
  }
  return String.fromCharCodes(raw);
}

/// 排版族名：nameID 16 优先，退回 nameID 1。
String _typographicFamily(Map<int, String> names) => names[16] ?? names[1] ?? '';

/// 64 位内容指纹（双向 32 位 FNV-1a）。只用于判定「两个文件是否字节相同」，
/// 不用于任何安全目的 —— 全域测试不允许为一个测试引入 crypto 依赖。
String _contentFingerprint(List<int> bytes) {
  int fwd = 0x811c9dc5;
  int rev = 0x9e3779b9;
  final int n = bytes.length;
  for (int i = 0; i < n; i++) {
    fwd = ((fwd ^ bytes[i]) * 0x01000193) & 0xFFFFFFFF;
    rev = ((rev ^ bytes[n - 1 - i]) * 0x01000193) & 0xFFFFFFFF;
  }
  return fwd.toRadixString(16).padLeft(8, '0') +
      rev.toRadixString(16).padLeft(8, '0');
}

/// 族名 → 许可证文件名的比对键：去掉 `ofl-` 前缀、`.txt` 后缀与非字母数字。
///
/// 这样 `JetBrains Mono` 既能匹配 `OFL-jetbrainsmono.txt`，
/// 也能匹配 `OFL-jetbrains_mono.txt`（两族同名的两份许可都合法）。
String _licenseSlug(String name) {
  String base = name.toLowerCase();
  if (base.endsWith('.txt')) {
    base = base.substring(0, base.length - 4);
  }
  if (base.startsWith('ofl-')) {
    base = base.substring(4);
  }
  return base.replaceAll(RegExp('[^a-z0-9]'), '');
}

/// 从 `TOKENS.md` 正文里取一条 CSS 字体栈 token，解析成族名列表。
///
/// 形如 `--f-display:"Fraunces","Noto Serif SC",...,serif;`
/// ⇒ `['Fraunces', 'Noto Serif SC', ..., 'serif']`（剥引号、去空项）。
///
/// 找不到 token 行时**必须失败**：静默跳过会让「设计真源改了名、代码没跟上」
/// 这类漂移在全绿下存活。
List<String> _parseCssStack(String markdown, String token) {
  final String prefix = '--$token:';
  String? raw;
  for (final String line in markdown.split('\n')) {
    final String trimmed = line.trim();
    if (trimmed.startsWith(prefix)) {
      raw = trimmed.substring(prefix.length);
      break;
    }
  }
  if (raw == null) {
    fail('TOKENS.md §2 里没找到 `--$token:` 行（设计真源改了名或格式？）');
  }
  String body = raw.trim();
  if (body.endsWith(';')) {
    body = body.substring(0, body.length - 1);
  }
  return body
      .split(',')
      .map((String s) => s.trim().replaceAll('"', ''))
      .where((String s) => s.isNotEmpty)
      .toList();
}

/// 字体打包守卫（Task 20 · ③ / Task 21 · N4）。
///
/// 口径：`TOKENS.md` §8 要求「桌面端缺字库时必须自带」——
/// 这条守卫保证「pubspec 声明了」与「文件真的在盘上」「族名真的对得上」
/// 三者不脱节，否则 Flutter 会**静默回退到系统字体**（打包了但没生效）。
void main() {
  final Directory root = _packageRoot();
  final String pubspecText =
      File('${root.path}/pubspec.yaml').readAsStringSync();
  final List<_FontDecl> decls = _parseFonts(pubspecText);
  final List<String> assets = _parseAssets(pubspecText);

  /// 同一路径的 name 表只解析一次（Noto 的 CJK 字体有 10 MB）。
  final Map<String, Map<int, String>> nameCache = <String, Map<int, String>>{};
  Map<int, String> namesOf(String asset) => nameCache.putIfAbsent(
        asset,
        () => _readNameTable(File('${root.path}/$asset').readAsBytesSync()),
      );

  final Directory licDir = Directory('${root.path}/assets/fonts/licenses');
  List<String> licenseFileNames() => licDir
      .listSync()
      .map((FileSystemEntity e) => e.path.split(RegExp(r'[/\\]')).last)
      .toList();

  group('字体打包守卫', () {
    test('四个字体族都在 flutter.fonts 里声明', () {
      final Set<String> families =
          decls.map((_FontDecl d) => d.family).toSet();
      expect(
        families,
        containsAll(<String>['Inter', 'Fraunces', 'JetBrains Mono', 'Noto Sans SC']),
      );
      expect(families.length, 4, reason: '不得有多余或拼错的字体族');
    });

    test('族名与 AppFonts 常量逐字一致', () {
      final Set<String> families =
          decls.map((_FontDecl d) => d.family).toSet();
      expect(families.contains(AppFonts.body), isTrue);
      expect(families.contains(AppFonts.display), isTrue);
      expect(families.contains(AppFonts.mono), isTrue);
      expect(
        AppFonts.bodyFallback.contains('Noto Sans SC'),
        isTrue,
        reason: 'CJK 兜底族必须已随包自带',
      );
    });

    test('每个声明的字体文件都真实存在，且是合法 TTF', () {
      expect(decls, isNotEmpty);
      for (final _FontDecl d in decls) {
        final File file = File('${root.path}/${d.asset}');
        expect(file.existsSync(), isTrue, reason: '缺文件：${d.asset}');
        final List<int> head = file.readAsBytesSync().sublist(0, 4);
        expect(
          head,
          <int>[0x00, 0x01, 0x00, 0x00],
          reason: '${d.asset} 不是 TrueType（magic 00010000）',
        );
        expect(file.lengthSync(), greaterThan(1000), reason: '${d.asset} 过小');
      }
    });

    test('::N4-A:: pubspec 的 family 与字体文件排版族名逐字一致', () {
      expect(decls, isNotEmpty);
      for (final _FontDecl d in decls) {
        final Map<int, String> names = namesOf(d.asset);
        final String typographic = _typographicFamily(names);
        expect(
          typographic,
          d.family,
          reason: '${d.asset}：name 表排版族名（nameID 16，缺失则退 1）= '
              '「$typographic」，pubspec 声明「${d.family}」'
              '⇒ Flutter 找不到该族，界面会静默回退到系统字体（打包了但没生效）',
        );
      }
    });

    test('::N4-B:: 同一族不同 weight 不得指向字节完全相同的文件', () {
      final Map<String, Map<String, String>> seen =
          <String, Map<String, String>>{};
      for (final _FontDecl d in decls) {
        final String fp = _contentFingerprint(
          File('${root.path}/${d.asset}').readAsBytesSync(),
        );
        final Map<String, String> perFamily =
            seen.putIfAbsent(d.family, () => <String, String>{});
        expect(
          perFamily.containsKey(fp),
          isFalse,
          reason: '${d.asset}（weight ${d.weight}）与 '
              '${perFamily[fp]} 字节完全相同 ⇒ 「${d.weight}」只是副本，'
              '该字重在 ${d.family} 里不会真正生效',
        );
        perFamily[fp] = d.asset;
      }
    });

    test('::N4-C:: Noto Sans SC 是 Regular 静态实例，不是可变字体的 Thin', () {
      final List<_FontDecl> noto =
          decls.where((_FontDecl d) => d.family == 'Noto Sans SC').toList();
      expect(noto, isNotEmpty, reason: 'CJK 兜底族必须随包自带');
      for (final _FontDecl d in noto) {
        final Map<int, String> names = namesOf(d.asset);
        expect(
          names[2],
          'Regular',
          reason: '${d.asset} 的 nameID 2（subfamily）= 「${names[2]}」，应为 Regular',
        );
        expect(
          names[17] ?? names[2],
          'Regular',
          reason: '${d.asset} 的 nameID 17（typo-subfamily）= 「${names[17]}」'
              '⇒ 由可变字体实例化时没把名称改成 Regular，'
              '可变字体默认实例是 Thin（发丝字重）',
        );
        final Iterable<String> stale =
            names.entries.where((MapEntry<int, String> e) => e.value.contains('Thin'))
                .map((MapEntry<int, String> e) => 'nameID ${e.key}=「${e.value}」');
        expect(
          stale,
          isEmpty,
          reason: '${d.asset} 的 name 表仍残留 Thin 字样：${stale.join('、')}',
        );
      }
    });

    test('::N4-D:: 四族 OFL 许可证逐族齐全', () {
      expect(licDir.existsSync(), isTrue);
      final List<String> names = licenseFileNames();
      final Set<String> slugs = names.map(_licenseSlug).toSet();
      for (final String family in decls.map((_FontDecl d) => d.family).toSet()) {
        expect(
          slugs.contains(_licenseSlug(family)),
          isTrue,
          reason: '缺「$family」的 OFL 许可证（licenses/ 现有：${names.join('、')}）'
              '⇒ OFL 要求重分发时附带许可',
        );
      }
    });

    test('同一资源不被重复声明', () {
      final Set<String> paths = decls.map((_FontDecl d) => d.asset).toSet();
      expect(paths.length, decls.length);
    });

    test('每个字体声明都带显式 weight', () {
      for (final _FontDecl d in decls) {
        expect(d.weight, greaterThanOrEqualTo(100));
        expect(d.weight, lessThanOrEqualTo(900));
        expect(d.weight % 100, 0);
      }
    });

    test('未参与打包的字体文件（可变字体 / CJK 子集）不被声明进包', () {
      expect(
        assets,
        isNot(contains('assets/fonts/')),
        reason: '声明整个目录会把目录下所有文件（含将来新增的源文件 / 中间产物）'
            '一并打进包，绕过本文件的逐文件核对口径',
      );
      final Set<String> declared = decls.map((_FontDecl d) => d.asset).toSet();
      for (final String unused in <String>[
        'NotoSansSC-VF.ttf',
        'NotoSansSC-400.ttf',
      ]) {
        expect(
          declared.any((String a) => a.endsWith(unused)),
          isFalse,
          reason: '$unused 不进包（VF 是源文件，400 是 Thin 子集）',
        );
      }
    });

    test('OFL 许可证随包分发', () {
      expect(assets, contains('assets/fonts/licenses/'));
      expect(licDir.existsSync(), isTrue);
      final List<String> names = licenseFileNames();
      expect(names.length, greaterThanOrEqualTo(4));
      for (final String n in names) {
        expect(n.toLowerCase(), endsWith('.txt'));
        final File f = File('${licDir.path}/$n');
        expect(f.lengthSync(), greaterThan(1000), reason: '$n 太小');
        final String body = f.readAsStringSync();
        // 下载失败的残渣（jsdelivr 的 "Couldn't find the requested file"）也算无效许可。
        expect(
          body.contains('SIL Open Font License'),
          isTrue,
          reason: '$n 不是有效的 OFL 许可正文',
        );
        expect(
          body.contains('SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007'),
          isTrue,
          reason: '$n 缺 OFL 1.1 正文标题（不得是凭记忆改写的法律文本）',
        );
      }
    });

    test('::N4-E:: 三族字体栈与 TOKENS.md §2 逐字一致', () {
      final File tokens =
          File('${root.parent.parent.path}/design-demos/TOKENS.md');
      expect(
        tokens.existsSync(),
        isTrue,
        reason: '找不到设计真源 ${tokens.path}（§2 是字体栈的唯一真源）',
      );
      final String markdown = tokens.readAsStringSync();

      void checkStack(String token, String primary, List<String> fallbacks) {
        final List<String> stack = _parseCssStack(markdown, token);
        expect(stack, isNotEmpty, reason: '`--$token` 解析结果为空');
        expect(
          stack.first,
          primary,
          reason: 'TOKENS.md §2 `--$token` 首选族「${stack.first}」'
              '≠ AppFonts「$primary」⇒ 代码与设计真源脱节',
        );
        expect(
          stack.sublist(1),
          fallbacks,
          reason: 'TOKENS.md §2 `--$token` 兜底栈 ${stack.sublist(1)}'
              '≠ AppFonts 兜底栈 $fallbacks（族名、顺序、长度都必须逐字一致；'
              '把不随包的族名换成随包族名会让中文 display 从宋体变无衬线，见 D-6）',
        );
      }

      checkStack('f-display', AppFonts.display, AppFonts.displayFallback);
      checkStack('f-body', AppFonts.body, AppFonts.bodyFallback);
      checkStack('f-mono', AppFonts.mono, AppFonts.monoFallback);
    });

    test('::N4-F:: OFL 许可在运行时资源包里可加载（payload 级守卫）', () async {
      // `rootBundle` 需要 binding；`flutter test` 会把 pubspec 声明的 assets
      // 打进 `build/unit_test_assets`，所以这条读的是**资源包**而不是磁盘源目录。
      TestWidgetsFlutterBinding.ensureInitialized();
      final List<String> names = licenseFileNames();
      for (final String family in decls.map((_FontDecl d) => d.family).toSet()) {
        final Iterable<String> matches = names
            .where((String n) => _licenseSlug(n) == _licenseSlug(family));
        expect(
          matches,
          isNotEmpty,
          reason: '磁盘上没有「$family」的许可文件（licenses/ 现有：${names.join('、')}）',
        );
        final String asset = 'assets/fonts/licenses/${matches.first}';
        late ByteData data;
        try {
          data = await rootBundle.load(asset);
        } catch (error) {
          fail('「$family」的许可 `$asset` 在**运行时资源包**里加载不到'
              '（磁盘上有、包里没有 ⇒ `assets:` 声明与包内容脱节）：$error');
        }
        expect(
          data.lengthInBytes,
          greaterThan(1000),
          reason: '$asset 在包里只有 ${data.lengthInBytes} B',
        );
        final String body = utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        expect(
          body.contains('SIL Open Font License'),
          isTrue,
          reason: '$asset（包内）不是有效的 OFL 正文',
        );
        expect(
          body.contains('SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007'),
          isTrue,
          reason: '$asset（包内）缺 OFL 1.1 正文标题',
        );
      }
    });

    // T-C 的前置条件在**声明期**求值：Release 产物不存在时，本条以 `skip` 计入
    // （compact reporter 显示 `~N`），而不是静默 PASS。理由：`printOnFailure`
    // 只在失败时输出，绿跑里「未生效」不可见 ⇒ `flutter clean` 后守卫会无声消失。
    final Directory payloadLic = Directory(
      '${root.path}/build/windows/x64/runner/Release'
      '/data/flutter_assets/assets/fonts/licenses',
    );
    final bool hasReleasePayload = payloadLic.existsSync();

    test(
      '::N4-G:: 构建产物 payload 内四份 OFL 齐全'
      '（Release 产物不存在时显式 skip，不静默通过）',
      () {
        final List<String> names = payloadLic
            .listSync()
            .map((FileSystemEntity e) => e.path.split(RegExp(r'[/\\]')).last)
            .toList();
        expect(
          names.length,
          greaterThanOrEqualTo(4),
          reason: '构建产物里的许可只有 ${names.length} 份：${names.join('、')}',
        );
        for (final String family in decls.map((_FontDecl d) => d.family).toSet()) {
          final Iterable<String> matches = names
              .where((String n) => _licenseSlug(n) == _licenseSlug(family));
          expect(
            matches,
            isNotEmpty,
            reason: '构建产物缺「$family」的 OFL（payload 现有：${names.join('、')}）'
                '⇒ 装出来的包缺许可',
          );
          final File f = File('${payloadLic.path}/${matches.first}');
          expect(f.lengthSync(), greaterThan(1000), reason: '${f.path} 过小');
        }
      },
      skip: hasReleasePayload
          ? false
          : 'Release 产物目录不存在：${payloadLic.path}'
              '（本条以 skip 计入，不代表通过；重打包后必须复跑）',
    );
  });
}