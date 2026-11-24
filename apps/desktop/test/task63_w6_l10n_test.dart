// apps/desktop/test/task63_w6_l10n_test.dart
//
// Task 63 批次二 W6：录入对话框（习惯 / 手写待办 / 循环任务 / 右轨规则）
// 与预估时长单位选择器的中英双态口径。
//
// 这里钉住四件事：
//   1. zh 逐字不变（旧代码里的字面量原样钉住，改一个字就红）；
//   2. en 各句与 zh 逐字不同，且不含 CJK 残留；
//   3. 插值方法真的把参数插进去（不是把占位符当常量发出去）；
//   4. 同句复用不误用到「形近但不同字」的键（`每日` ≠ `每天`）。
//
// 断言一律写字面量，不写 `find.text(t.xxx)` 那种同义反复（派工书 §47.3）。
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// `[一-龥]` 覆盖常用汉字区；en 文案里出现任何一个都算漏翻。
final RegExp _cjk = RegExp(r'[\u4e00-\u9fff]');

void main() {
  final AppLocalizations zh = AppLocalizations.zh;
  final AppLocalizations en = AppLocalizations.en;

  group('预估时长单位档位', () {
    test('zh 五档逐字不变', () {
      expect(zh.dialogEstUnitMinute, '分钟');
      expect(zh.dialogEstUnitHour, '小时');
      expect(zh.dialogEstUnitDay, '日');
      expect(zh.dialogEstUnitWeek, '周');
      expect(zh.dialogEstUnitMonth, '月');
    });

    test('en 五档给英文缩写', () {
      expect(en.dialogEstUnitMinute, 'min');
      expect(en.dialogEstUnitHour, 'hr');
      expect(en.dialogEstUnitDay, 'day');
      expect(en.dialogEstUnitWeek, 'wk');
      expect(en.dialogEstUnitMonth, 'mo');
    });

    test('zh 与 en 逐档不同', () {
      expect(zh.dialogEstUnitMinute, isNot(en.dialogEstUnitMinute));
      expect(zh.dialogEstUnitHour, isNot(en.dialogEstUnitHour));
      expect(zh.dialogEstUnitDay, isNot(en.dialogEstUnitDay));
      expect(zh.dialogEstUnitWeek, isNot(en.dialogEstUnitWeek));
      expect(zh.dialogEstUnitMonth, isNot(en.dialogEstUnitMonth));
    });
  });

  group('习惯录入面板', () {
    test('zh 逐字不变', () {
      expect(zh.dialogHabitCreate, '添加习惯');
      expect(zh.dialogHabitNameLabel, '习惯名（必填）');
      expect(zh.dialogHabitNoteLabel, '说明（可选）');
      expect(zh.dialogHabitSchedule, '排程');
      expect(zh.dialogHabitDaily, '每天');
      expect(zh.dialogHabitEvery, '每隔');
      expect(zh.dialogHabitWeekday, '星期');
      expect(zh.dialogHabitStartDate, '起始日期');
      expect(zh.dialogHabitDailyMin, '每日至少完成');
      expect(zh.dialogHabitNameRequired, '习惯名不能为空');
      expect(zh.dialogHabitWeekdayRequired, '请至少选择一个星期');
    });

    test('en 全部换成英文且不含汉字', () {
      final List<String> values = <String>[
        en.dialogHabitCreate,
        en.dialogHabitNameLabel,
        en.dialogHabitNoteLabel,
        en.dialogHabitSchedule,
        en.dialogHabitDaily,
        en.dialogHabitEvery,
        en.dialogHabitWeekday,
        en.dialogHabitStartDate,
        en.dialogHabitDailyMin,
        en.dialogHabitNameRequired,
        en.dialogHabitWeekdayRequired,
        en.dialogHabitCreateSubtitle,
      ];
      for (final String value in values) {
        expect(_cjk.hasMatch(value), isFalse, reason: '漏翻：$value');
      }
      expect(en.dialogHabitCreate, 'Add habit');
      expect(en.dialogHabitDailyMin, 'Minimum per day');
    });

    test('警告串带上原始错误', () {
      expect(
        zh.dialogHabitSavedWarn('磁盘只读'),
        '习惯已保存，但未能自动加入日计划：磁盘只读',
      );
      expect(
        en.dialogHabitSavedWarn('disk read-only'),
        'Habit saved, but it could not be added to the plan: disk read-only',
      );
    });
  });

  group('手写待办面板', () {
    test('zh 逐字不变', () {
      expect(zh.dialogTodoCreateTitle, '手写一条');
      expect(zh.dialogTodoTitleHint, '要做什么？');
      expect(zh.dialogTodoEstLabel, '预估时间（可选）');
      expect(zh.dialogTodoEstHint, '例如 25');
      expect(zh.dialogTodoPriorityLabel, '优先级（可选）');
      expect(zh.dialogTodoPullToday, '同时捞入今天');
      expect(zh.dialogTodoSaving, '保存中…');
      expect(zh.dialogTodoTitleRequired, '标题不能为空');
      expect(zh.dialogTodoEstInvalid, '预估时间要填正数，或留空');
      expect(zh.dialogTodoPullTitle, '从待办池捞');
      expect(zh.dialogTodoPoolEmpty, '待办池是空的');
      expect(zh.dialogTodoPulling, '捞入中…');
      expect(zh.dialogTodoPull, '捞入');
    });

    test('en 不含汉字，且与 zh 不同', () {
      expect(_cjk.hasMatch(en.dialogTodoCreateTitle), isFalse);
      expect(_cjk.hasMatch(en.dialogTodoPoolEmpty), isFalse);
      expect(_cjk.hasMatch(en.dialogTodoPull), isFalse);
      expect(zh.dialogTodoCreateTitle, isNot(en.dialogTodoCreateTitle));
      expect(zh.dialogTodoPoolEmpty, isNot(en.dialogTodoPoolEmpty));
      expect(en.dialogTodoPull, 'Pull in');
    });

    test('副标题把目标日期插进去', () {
      expect(
        zh.dialogTodoCreateSubtitle('2026-11-09'),
        '先存进待办池；勾选后同时落进 2026-11-09 的计划。',
      );
      expect(
        zh.dialogTodoPullSubtitle('2026-11-09'),
        '捞进 2026-11-09 的计划；待办池本身不会被删。',
      );
      expect(en.dialogTodoCreateSubtitle('2026-11-09'), contains('2026-11-09'));
      expect(en.dialogTodoPullSubtitle('2026-11-09'), contains('2026-11-09'));
    });
  });

  group('循环任务面板', () {
    test('zh 逐字不变', () {
      expect(zh.dialogRecurringCreateTitle, '添加循环任务');
      expect(zh.dialogRecurringCreateSubtitle, '按星期与开始时刻，自动排进每一天的计划');
      expect(zh.dialogRecurringTitleLabel, '标题（必填）');
      expect(zh.dialogRecurringStartLabel, '开始 HH:mm（06:00 起）');
      expect(zh.dialogRecurringDurationLabel, '时长（分钟）');
      expect(zh.dialogRecurringNoteLabel, '备注（可选）');
      expect(zh.dialogRecurringSaveConfirm, '确认保存');
      expect(zh.dialogRecurringWeekdayRequired, '至少要选一个星期');
      expect(zh.dialogRecurringTimeInvalid, '开始时刻要写成 HH:mm（例如 09:00）');
      expect(zh.dialogRecurringDurationInvalid, '时长必须是 1..1440 之间的整数（分钟）');
    });

    test('校验与纠正提示带上参数', () {
      expect(zh.dialogRecurringBadDate('2026-13-01'), contains('2026-13-01'));
      expect(
        zh.dialogRecurringMergedWeekday('周一'),
        '已把 周一 并入重复日，以便今天就出现在计划里',
      );
      expect(
        zh.dialogRecurringTimeClamped('06:00', '06:00'),
        '开始时刻早于 06:00，已改到 06:00（时间轴只显示 06:00 之后）',
      );
      expect(en.dialogRecurringBadDate('2026-13-01'), contains('2026-13-01'));
      expect(en.dialogRecurringMergedWeekday('Mon'), contains('Mon'));
    });

    test('en 不含汉字', () {
      final List<String> values = <String>[
        en.dialogRecurringCreateTitle,
        en.dialogRecurringCreateSubtitle,
        en.dialogRecurringTitleLabel,
        en.dialogRecurringStartLabel,
        en.dialogRecurringDurationLabel,
        en.dialogRecurringNoteLabel,
        en.dialogRecurringSaveConfirm,
        en.dialogRecurringWeekdayRequired,
        en.dialogRecurringTimeInvalid,
        en.dialogRecurringDurationInvalid,
      ];
      for (final String value in values) {
        expect(_cjk.hasMatch(value), isFalse, reason: '漏翻：$value');
      }
      expect(en.dialogRecurringCreateTitle, 'Add recurring task');
      expect(en.dialogRecurringSaveConfirm, 'Confirm save');
    });
  });

  group('右轨「循环任务」面板', () {
    test('zh 逐字不变', () {
      expect(zh.dialogRecurringSection, '规则');
      expect(zh.dialogRecurringLoading, '读取规则…');
      expect(zh.dialogRecurringNone, '还没有循环规则');
      expect(zh.dialogRecurringNoneHint, '点右上角 ＋ 添加一条');
      expect(zh.dialogRecurringDeleteTitle, '删除循环任务');
      expect(zh.dialogRuleActiveOn, '启用中');
      expect(zh.dialogRuleActiveOff, '已停用');
      expect(zh.dialogRuleDisable, '停用');
      expect(zh.dialogRuleEnable, '启用');
    });

    test('计数行与摘要行按原格式拼', () {
      expect(zh.dialogRecurringCount(3), '共 3 条规则 · 命中日自动排入计划');
      expect(
        zh.dialogRecurringSummary('周一', 30, zh.dialogRuleActiveOn),
        '周一 · 30 分钟 · 启用中',
      );
      expect(
        en.dialogRecurringSummary('Mon', 30, en.dialogRuleActiveOff),
        'Mon · 30 min · Disabled',
      );
    });

    test('删除确认把规则标题带进去', () {
      expect(
        zh.dialogRecurringDeleteMessage('晨读'),
        '「晨读」将从循环任务列表中移除，之后不再自动排入计划；已经排入计划的条目会保留。',
      );
      expect(en.dialogRecurringDeleteMessage('Read'), contains('Read'));
    });

    test('错误串保留原始错误正文', () {
      expect(zh.dialogRuleActionFailed('boom'), '规则操作失败：boom');
      expect(zh.dialogAutoScheduleFailed('boom'), '自动排程失败：boom');
      expect(zh.dialogRecurringLoadFailed('boom'), '规则读取失败：boom');
      expect(en.dialogRuleActionFailed('boom'), 'Rule action failed: boom');
      expect(en.dialogAutoScheduleFailed('boom'), contains('boom'));
      expect(en.dialogRecurringLoadFailed('boom'), contains('boom'));
    });

    test('「每日」与「每天」是两个键，不许合并', () {
      expect(zh.dialogRecurringDaily, '每日');
      expect(zh.dialogHabitDaily, '每天');
      expect(zh.dialogRecurringDaily, isNot(zh.dialogHabitDaily));
      expect(en.dialogRecurringDaily, isNot(en.dialogHabitDaily));
      expect(_cjk.hasMatch(en.dialogRecurringDaily), isFalse);
    });
  });

  group('预估时长芯片', () {
    test('zh 逐字不变', () {
      expect(zh.dialogDurationCustom, '自定义…');
      expect(zh.dialogDurationCustomHint, '自定义时长：点「+ 手写」里输入分钟数');
    });

    test('en 与 zh 不同且不含汉字', () {
      expect(_cjk.hasMatch(en.dialogDurationCustom), isFalse);
      expect(_cjk.hasMatch(en.dialogDurationCustomHint), isFalse);
      expect(zh.dialogDurationCustom, isNot(en.dialogDurationCustom));
      expect(en.dialogDurationCustom, 'Custom…');
    });
  });

  group('跨波复用的共享键（本轮不得另立同形键）', () {
    test('按钮与单位复用 common / domain 的既有文案', () {
      expect(zh.commonSave, '保存');
      expect(zh.cancel, '取消');
      expect(zh.commonClose, '关闭');
      expect(zh.commonDelete, '删除');
      expect(zh.commonUnitTimes, '次');
      expect(zh.commonUnitDay, '天');
      expect(zh.commonUnitWeek, '周');
      expect(en.commonUnitTimes, isNot(zh.commonUnitTimes));
    });

    test('星期全称列表两侧各有七项且 zh 逐字不变', () {
      expect(zh.domainWeekdayFull, <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日']);
      expect(en.domainWeekdayFull, hasLength(7));
      expect(en.domainWeekdayFull.first, isNot(zh.domainWeekdayFull.first));
    });
  });
}