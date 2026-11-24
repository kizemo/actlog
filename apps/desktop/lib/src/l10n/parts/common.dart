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

  /// 标题（表单字段名 / 分组标题）。
  String get commonTitle;

  /// 保存（表单主按钮）。
  String get commonSave;

  /// 删除（破坏性动作按钮）。
  String get commonDelete;

  /// 关闭（关掉浮层 / 对话框的按钮，不是关窗口）。
  String get commonClose;

  // ---------------------------------------------------------------------------
  // 二元取值 / 动作 / 优先级轴 / 单位（Task 63 轮二：W3–W7 共用短词）
  //
  // 这几条在 2 个以上波次里同句同义出现，因此集中在 common part，
  // 各波次直接复用，不再自建同形键。
  // ---------------------------------------------------------------------------

  /// 二元轴的肯定取值：是。
  String get commonYes;

  /// 二元轴的否定取值：否。
  String get commonNo;

  /// 确认（动作按钮）。注意 `confirm` 的 zh 是「确定」，两者不可互换。
  String get commonConfirmAction;

  /// 清除（把已分级打回未分级 / 清空选择）。
  String get commonClear;

  /// 清除优先级（完整措辞，用于芯片与提示文案）。
  String get commonClearPriority;

  /// 优先级轴：重要。
  String get commonAxisImportant;

  /// 优先级轴：不重要。
  String get commonAxisNotImportant;

  /// 优先级轴：紧急。
  String get commonAxisUrgent;

  /// 优先级轴：不紧急。
  String get commonAxisNotUrgent;

  /// 次数单位（显示层用；落库值 `次` 不随语言变）。
  String get commonUnitTimes;

  /// 天数单位。
  String get commonUnitDay;

  /// 周数单位。
  String get commonUnitWeek;
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

  @override
  String get commonTitle => '标题';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonClose => '关闭';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonConfirmAction => '确认';

  @override
  String get commonClear => '清除';

  @override
  String get commonClearPriority => '清除优先级';

  @override
  String get commonAxisImportant => '重要';

  @override
  String get commonAxisNotImportant => '不重要';

  @override
  String get commonAxisUrgent => '紧急';

  @override
  String get commonAxisNotUrgent => '不紧急';

  @override
  String get commonUnitTimes => '次';

  @override
  String get commonUnitDay => '天';

  @override
  String get commonUnitWeek => '周';
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

  @override
  String get commonTitle => 'Title';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonConfirmAction => 'Confirm';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClearPriority => 'Clear priority';

  @override
  String get commonAxisImportant => 'Important';

  @override
  String get commonAxisNotImportant => 'Not important';

  @override
  String get commonAxisUrgent => 'Urgent';

  @override
  String get commonAxisNotUrgent => 'Not urgent';

  @override
  String get commonUnitTimes => 'times';

  @override
  String get commonUnitDay => 'days';

  @override
  String get commonUnitWeek => 'weeks';
}