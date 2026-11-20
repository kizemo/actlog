// =============================================================================
// l10n part：跨页共用词（W1 波次拥有本文件）
// =============================================================================
// 只收「同一句在多个页面都要用、且语义完全一样」的短词。一旦某个页面需要
// 不同的措辞，就应该在自己那一页的 part 里另立一条，不要改这里 —— 改这里会
// 悄悄改掉其它页面的显示。
// =============================================================================

/// 跨页共用文案。
abstract class CommonL10n {
  /// 取消。
  String get cancel;

  /// 确认（确定 / OK）。
  String get confirm;

  /// 当前程序路径。
  String get executablePath;

  /// 操作失败（附带原因）。
  String get operationFailed;

  /// 复制（关于页里专指仓库 URL）。
  String get copy;

  /// 已复制。
  String get copied;

  /// 打开。
  String get open;
}

/// 跨页共用文案：简体中文。
mixin CommonZhL10n implements CommonL10n {
  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get executablePath => '当前程序路径';

  @override
  String get operationFailed => '操作失败';

  @override
  String get copy => '复制地址';

  @override
  String get copied => '已复制';

  @override
  String get open => '打开';
}

/// 跨页共用文案：English。
mixin CommonEnL10n implements CommonL10n {
  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get executablePath => 'Executable path';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get copy => 'Copy URL';

  @override
  String get copied => 'Copied';

  @override
  String get open => 'Open';
}