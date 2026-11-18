// 应用版本与对外地址的**单一常量源**。
//
// 为什么手写常量而不是运行期读 `pubspec.yaml`：pubspec 不进产物包，装好的
// exe 旁边没有它；`package_info_plus` 又要引依赖（本波零新依赖）。
// 防线放在测试里：`test/task39_about_version_test.dart` 直接读 pubspec 并断言
// 两边一致，只改一处就红。

/// 语义化版本号（不含构建号）。
const String kAppVersion = '0.1.0';

/// 构建号（pubspec 的 `+` 后缀）。
const String kAppBuildNumber = '1';

/// `0.1.0+1` 形式，关于页与设置页都显示这一个。
const String kAppVersionFull = '$kAppVersion+$kAppBuildNumber';

/// 产品仓库地址（`AGENTS.md` 记录的 public 仓库，默认分支 `main`）。
const String kAppRepositoryUrl = 'https://github.com/kizemo/actlog';

/// 开发者 GitHub 主页。
const String kAppDeveloperUrl = 'https://github.com/kizemo';

/// 开发者代号。
const String kAppDeveloperName = 'kizemo';

/// 另一款软件：Alpha File Manager（已确认存在）。
const String kAlphaFileManagerUrl =
    'https://github.com/kizemo/alpha-file-manager';

/// PageWeaver：`kizemo/weavepage` 存在，但仓库与产品名的对应关系**未核实**。
///
/// 核实不了就不写死结论 —— 关于页会如实标注「仓库地址待核实」。
const String kPageWeaverUrl = 'https://github.com/kizemo/weavepage';

/// `kPageWeaverUrl` 与 PageWeaver 的对应关系是否已坐实。
const bool kPageWeaverVerified = false;

/// 比较两个版本号；返回 `1` 表示 [a] 比 [b] 新，`-1` 更旧，`0` 相同。
///
/// 口径：去掉 `v`/`V` 前缀与 `+` 构建号，按点分段做**数值**比较，缺段补 0。
/// 非数字段一律当 0（不抛异常 —— 版本号是外部输入，不能让它崩掉界面）。
int compareVersions(String a, String b) {
  final List<int> left = _versionParts(a);
  final List<int> right = _versionParts(b);
  final int length = left.length > right.length ? left.length : right.length;
  for (int i = 0; i < length; i++) {
    final int l = i < left.length ? left[i] : 0;
    final int r = i < right.length ? right[i] : 0;
    if (l != r) {
      return l > r ? 1 : -1;
    }
  }
  return 0;
}

List<int> _versionParts(String raw) {
  final String cleaned = raw
      .trim()
      .replaceFirst(RegExp('^[vV]'), '')
      .split('+')
      .first;
  return cleaned
      .split('.')
      .map((String part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
}
