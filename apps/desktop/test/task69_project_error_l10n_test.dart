// apps/desktop/test/task69_project_error_l10n_test.dart
//
// Task 69 · 项目页错误文案本地化：数据层不带中文 ⇒ 英文态零 CJK。
//
// 本文件钉七条：
//   T1：空项目名 / 空任务标题 / 非法来源类型 ⇒ 抛的是**带错误码**的可判别异
//       常，错误载荷（message / toString）里零 CJK；
//   T2：既有契约不变 —— 空名仍按 `ArgumentError` 被拒（`task56` 的 T8 断言
//       照样成立）；
//   T3：四条错误码 ⇒ 界面层映射到 l10n 的那一句（英文态逐条零 CJK）；
//   T4：中文态逐字等于改动前的原文（四条，一字不差）；
//   T5：store 源码里再无中文字面量（逐行抽字面量扫 CJK）；
//   T6：四条错误码在 store 源码里都有落点（第四条的落点是私有 helper）；
//   T7：非校验类异常与实体缺失异常的既有行为不变。
import 'dart:io';

import 'package:actlog/src/data/project_store.dart';
import 'package:actlog/src/l10n/app_localizations.dart';
import 'package:actlog/src/pages/projects_page.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart' hide Todo;
import 'package:core_domain/core_domain.dart' show PlanSourceType;
import 'package:flutter_test/flutter_test.dart';

/// CJK 判定：汉字 + 中日韩标点 + 全角字符。
final RegExp _cjk = RegExp(r'[\u3000-\u303f\u4e00-\u9fff\uff00-\uffef]');

/// store 源码（`flutter test` 的工作目录 = 包根 `apps\desktop`）。
final File _storeSource = File('lib/src/data/project_store.dart');

/// 行内的单引号 / 双引号字面量。
final RegExp _literal = RegExp(r'''('([^'\\\n]|\\.)*')|("([^"\\\n]|\\.)*")''');

void main() {
  late ActLogDatabase db;
  late ActLogRepositories repos;
  late ProjectStore store;

  setUp(() {
    db = openInMemoryActLogDatabase();
    repos = ActLogRepositories(db, deviceId: 'task69-project-error-l10n');
    store = ProjectStore(repos);
  });

  tearDown(() async {
    await db.close();
  });

  test('T1：空项目名 ⇒ 带错误码的异常，载荷零 CJK', () async {
    Object? caught;
    try {
      await store.createProject(name: '   ');
    } on Object catch (error) {
      caught = error;
    }
    expect(caught, isA<ProjectValidationError>());
    final ProjectValidationError error = caught! as ProjectValidationError;
    expect(error.code, ProjectValidationError.nameRequired);
    expect(
      _cjk.hasMatch('${error.message}'),
      isFalse,
      reason: '错误 message 里不能有中文',
    );
    expect(
      _cjk.hasMatch(error.toString()),
      isFalse,
      reason: '错误 toString 里不能有中文',
    );
  });

  test('T1：空任务标题 ⇒ 带错误码的异常，载荷零 CJK', () async {
    Object? caught;
    try {
      await store.createMilestone(projectId: 'p1', title: '   ');
    } on Object catch (error) {
      caught = error;
    }
    expect(caught, isA<ProjectValidationError>());
    final ProjectValidationError error = caught! as ProjectValidationError;
    expect(error.code, ProjectValidationError.taskTitleRequired);
    expect(_cjk.hasMatch('${error.message}'), isFalse);
    expect(_cjk.hasMatch(error.toString()), isFalse);
  });

  test('T1：非法来源类型 ⇒ 带错误码的异常，载荷零 CJK', () async {
    Object? caught;
    try {
      await store.scheduleToDay(
        date: '2026-11-25',
        sourceType: PlanSourceType.manual,
        sourceId: 'p1',
        title: 'x',
      );
    } on Object catch (error) {
      caught = error;
    }
    expect(caught, isA<ProjectValidationError>());
    final ProjectValidationError error = caught! as ProjectValidationError;
    expect(error.code, ProjectValidationError.sourceTypeInvalid);
    expect(_cjk.hasMatch('${error.message}'), isFalse);
    expect(_cjk.hasMatch(error.toString()), isFalse);
  });

  test('T2：既有契约不变 —— 空名 / 空标题仍按 ArgumentError 被拒', () async {
    await expectLater(store.createProject(name: '   '), throwsArgumentError);
    await expectLater(
      store.createMilestone(projectId: 'p1', title: '   '),
      throwsArgumentError,
    );
  });

  test('T3/T4：四条错误码 ⇒ 英文态零 CJK，中文态逐字不变', () {
    final Map<String, String> zhExpected = <String, String>{
      ProjectValidationError.nameRequired: '项目名称不能为空',
      ProjectValidationError.taskTitleRequired: '任务标题不能为空',
      ProjectValidationError.sourceTypeInvalid: '只接受 project / increment',
      ProjectValidationError.dateFormatInvalid: '日期必须是 YYYY-MM-DD 格式',
    };
    final Map<String, String> enExpected = <String, String>{
      ProjectValidationError.nameRequired:
          AppLocalizations.en.projectsNameRequired,
      ProjectValidationError.taskTitleRequired:
          AppLocalizations.en.projectsTaskTitleRequired,
      ProjectValidationError.sourceTypeInvalid:
          AppLocalizations.en.projectsSourceTypeInvalid,
      ProjectValidationError.dateFormatInvalid:
          AppLocalizations.en.projectsInvalidDateFormat,
    };
    expect(zhExpected.length, 4);
    expect(enExpected.length, 4);
    for (final MapEntry<String, String> entry in zhExpected.entries) {
      final ProjectValidationError error = ProjectValidationError(entry.key);
      final String en = projectErrorMessage(AppLocalizations.en, error);
      final String zh = projectErrorMessage(AppLocalizations.zh, error);
      expect(en, enExpected[entry.key], reason: '英文映射到了别的文案：$entry');
      expect(_cjk.hasMatch(en), isFalse, reason: '英文态不能有中文：$en');
      expect(en.trim(), isNotEmpty);
      expect(zh, entry.value, reason: '中文态逐字变了：$entry');
      expect(zh, isNot(en), reason: '中英同值：$entry');
    }
  });

  test('T5：store 源码里再无中文字面量', () {
    expect(
      _storeSource.existsSync(),
      isTrue,
      reason: '跑测试时的工作目录必须是 apps\\desktop',
    );
    final List<String> lines = _storeSource.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      for (final RegExpMatch match in _literal.allMatches(lines[i])) {
        expect(
          _cjk.hasMatch(match.group(0)!),
          isFalse,
          reason: '第 ${i + 1} 行还有中文字面量：${match.group(0)}',
        );
      }
    }
  });

  test('T6：四条错误码在 store 源码里都有落点', () {
    final String source = _storeSource.readAsStringSync();
    for (final String name in <String>[
      'nameRequired',
      'taskTitleRequired',
      'sourceTypeInvalid',
      'dateFormatInvalid',
    ]) {
      expect(
        source,
        contains('ProjectValidationError.$name'),
        reason: 'store 里没有用到 ProjectValidationError.$name',
      );
    }
  });

  test('T7：非校验类异常与实体缺失异常的既有行为不变', () {
    expect(
      projectErrorMessage(AppLocalizations.zh, ArgumentError('boom')),
      'boom',
    );
    expect(
      projectErrorMessage(AppLocalizations.zh, const FormatException('bad')),
      'bad',
    );
    expect(
      projectErrorMessage(
        AppLocalizations.zh,
        const MissingEntityException(
          kind: MissingEntityException.milestoneKind,
          id: 'm1',
        ),
      ),
      '任务 m1 不存在',
    );
    expect(
      projectErrorMessage(
        AppLocalizations.en,
        const MissingEntityException(
          kind: MissingEntityException.milestoneKind,
          id: 'm1',
        ),
      ),
      'Task m1 does not exist',
    );
  });
}
