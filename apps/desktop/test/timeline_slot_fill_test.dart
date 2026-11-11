// apps/desktop/test/timeline_slot_fill_test.dart
//
// B2 方格时间轴 · 回填结果 → 条目状态（纯函数层，不碰数据库 / 不碰 provider）。
//
// 盯 `slotStatusAfterFill`（`slot_fill.dart:73`）的四条分支与两条边界：
//   1. 勾了「完成」⇒ `done`，且**优先于**任何结论（写「取消」也还是 done）；
//   2. 结论含「顺延到明天」⇒ `deferred`；
//   3. 结论含「取消」⇒ `cancelled`；
//   4. 其余结论 ⇒ 保持原状态。
// 两条边界：原状态是未知取值 ⇒ `pending` 兜底；进展串反解失败（`ResultNote`
// 走 `_raw` 分支，outcome 为空）⇒ 同样保持原状态，不能被误判成取消 / 顺延。
//
// 状态断言一律比对 `PlanStatus` 枚举本体，不比对 `.code` 字符串 ——
// 这里的契约是「返回哪个枚举值」，`code` 有它自己的测试（`core_data` 侧）。
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/slot_fill.dart';

/// 构造一条「没勾完成、结论为 [outcome]」的回填结果。
SlotFillEdit _notDone(String outcome) =>
    SlotFillEdit(done: false, note: '[结论]$outcome');

void main() {
  group('回填后的条目状态 slotStatusAfterFill', () {
    test('勾了「完成」⇒ done，且压过任何结论', () {
      expect(
        slotStatusAfterFill(
          const SlotFillEdit(done: true, note: ''),
          'pending',
        ),
        PlanStatus.done,
      );
      // 「完成」优先于「取消」：用户既按完成又填了取消，落库必须是 done。
      expect(slotStatusAfterFill(_done('取消'), 'pending'), PlanStatus.done);
      expect(slotStatusAfterFill(_done('顺延到明天'), 'pending'), PlanStatus.done);
      // 原状态本来就是 done，也不能被降级。
      expect(slotStatusAfterFill(_done('随便'), 'done'), PlanStatus.done);
    });

    test('结论「顺延到明天」⇒ deferred（原状态不阻碍）', () {
      expect(slotStatusAfterFill(_notDone('顺延到明天'), 'pending'),
          PlanStatus.deferred);
      expect(slotStatusAfterFill(_notDone('顺延到明天'), 'done'),
          PlanStatus.deferred);
    });

    test('结论「取消」⇒ cancelled', () {
      expect(
          slotStatusAfterFill(_notDone('取消'), 'pending'), PlanStatus.cancelled);
      expect(slotStatusAfterFill(_notDone('取消'), 'done'), PlanStatus.cancelled);
    });

    test('其余结论 ⇒ 原样保持原状态', () {
      expect(slotStatusAfterFill(_notDone('写完了引言'), 'pending'),
          PlanStatus.pending);
      expect(
          slotStatusAfterFill(_notDone('写完了引言'), 'done'), PlanStatus.done);
      expect(slotStatusAfterFill(_notDone('写完了引言'), 'cancelled'),
          PlanStatus.cancelled);
      expect(slotStatusAfterFill(_notDone('写完了引言'), 'deferred'),
          PlanStatus.deferred);
    });

    test('原状态取值未知 ⇒ pending 兜底，不抛异常', () {
      // `ResultNote.parse` 认的是「结论段**正好等于**取消 / 顺延到明天」，
      // 「取消明天」这类只是包含关键字的结论必须走保持分支。
      expect(slotStatusAfterFill(_notDone('取消明天'), 'weird-status'),
          PlanStatus.pending);
      expect(slotStatusAfterFill(_notDone('顺延到下周'), ''),
          PlanStatus.pending);
    });

    test('进展串反解失败（_raw）⇒ 保持原状态，不误判成取消 / 顺延', () {
      // 空串：`ResultNote.parse` 返回空结构，outcome 为空。
      expect(ResultNote.parse('').outcome, isEmpty);
      expect(slotStatusAfterFill(const SlotFillEdit(done: false, note: ''),
          'done'), PlanStatus.done);
      // 纯文本串：解析不成分段结构，整体落 `_raw`，outcome 仍为空。
      expect(ResultNote.parse('取消').outcome, isEmpty);
      expect(slotStatusAfterFill(const SlotFillEdit(done: false, note: '取消'),
          'pending'), PlanStatus.pending);
    });
  });
}

/// 构造一条「勾了完成 + 结论为 [outcome]」的回填结果。
SlotFillEdit _done(String outcome) =>
    SlotFillEdit(done: true, note: '[结论]$outcome');