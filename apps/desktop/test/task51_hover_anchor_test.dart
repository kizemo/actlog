// apps/desktop/test/task51_hover_anchor_test.dart
//
// Task 51 · W1 · 诉求 1 的验收面：
//   「鼠标悬停任务，显示的悬浮信息窗口，要显示在光标左下角或右下角，保持一定
//     距离，不要遮掩当条任务，避免左键和右键点击失效。」
//
// 三条判别性用例，各盯一件事，坏掉时能直接指到成因：
//   A 跟随光标 —— 卡片位置由**指针坐标**决定，不再由 chip 右缘决定；
//   B 不遮当条 —— 硬约束「卡片顶边 ≥ chip 下缘 + 8px」无条件成立；
//   C 不抢焦点 —— 打开卡片不 `requestFocus`，焦点只在指针进入卡片本体时才转移。
//
// 为什么不经由 `DayGrid` 挂载：这三条全是 `SlotHoverCard` 自身的几何与焦点
// 语义，裸 pump 它一只控件，chip 的位置和尺寸都是本文件说了算（300,200 起，
// 320×40），断言能写成精确值而不是「比大小」；整条时间轴的联动已由
// `task50_timeline_lines_test.dart` 的悬停用例覆盖，不必重复搭真库。
//
// 关于 `tester.getRect(卡片)`：卡片挂在 `CompositedTransformFollower` 下，
// 而 `RenderFollowerLayer.applyPaintTransform` 会把 `getCurrentTransform()`
// 乘进变换链 ⇒ 只要该帧已经画过（`pump` 之后），读到的是**跟随后的真实坐标**，
// 不是 overlay 里的原始 (0,0)。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/timeline/slot_hover_card.dart';

import 'l10n_harness.dart';

/// 条目与卡片的共同标题（chip 与卡片各渲染一次，故只能按 key 定位）。
const String _title = '写交付报告';

const ValueKey<String> _hoverCard = ValueKey<String>('slot-hover-card');
const ValueKey<String> _hoverCardTitle = ValueKey<String>(
  'slot-hover-card-title',
);
const ValueKey<String> _chip = ValueKey<String>('task51-chip');

/// chip 在视口里的落点（左上角），以及尺寸。
const Offset _chipOrigin = Offset(300, 200);
const Size _chipSize = Size(320, 40);

/// 视口：宽到能「右侧放得下 260 宽」，高到正常落位不会触发翻上方。
const Size _viewport = Size(1200, 900);

/// 悬停卡片的固定宽度（`kSlotHoverCardWidth` 的本地副本，改常量不会让本文件
/// 变成 `closeTo` 之外的断言也一起漂）。
const double _cardWidth = kSlotHoverCardWidth;

/// 光标左下 / 右下时卡片与光标的间隙（与实现里的 `_kCursorGapX` 同值）。
const double _cursorGapX = 12;

/// 卡片与当条 chip 的最小净空（与实现里的 `_kChipClearance` 同值）。
const double _chipClearance = 8;

/// 搭一只裸 `SlotHoverCard`：chip 固定在 ([_chipOrigin], [_chipSize])。
///
/// [focusOwner] 非空时套一层 `Focus`，用来验证「悬停不抢焦点」。
Future<void> _pumpCard(
  WidgetTester tester, {
  String detail = '',
  String note = '',
  FocusNode? focusOwner,
}) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget body = Padding(
    padding: const EdgeInsets.only(
      left: 300,
      top: 200,
    ),
    child: SizedBox(
      width: _chipSize.width,
      height: _chipSize.height,
      child: SlotHoverCard(
        title: _title,
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        detail: detail,
        note: note,
        stateLabel: '计划',
        levelLabel: '重要且紧急',
        child: SizedBox(
          key: _chip,
          width: _chipSize.width,
          height: _chipSize.height,
          child: const ColoredBox(
            color: Color(0xFFF0EDE5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_title),
            ),
          ),
        ),
      ),
    ),
  );
  if (focusOwner != null) {
    body = Focus(focusNode: focusOwner, child: body);
  }

  await tester.pumpWidget(
    // Task 63 FIX-4：`AppLocalizations.of` 走严格 `L10nScope.of`，补祖先。
    l10nScope(
      MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: body),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 一只鼠标指针，初始停在 chip 之外。
Future<TestGesture> _pointer(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer(location: const Offset(10, 10));
  addTearDown(gesture.removePointer);
  return gesture;
}

/// 走完「卡片出现 → 量高度 → 用实测高度重排一次」这三帧。
Future<void> _settleCard(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

/// 收尾：把指针挪走、跨过 200ms 宽限期把卡片收起，再卸树（不留 pending timer）。
Future<void> _quiesce(WidgetTester tester, TestGesture gesture) async {
  await gesture.moveTo(const Offset(10, 10));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('Task 51 · 诉求 1：悬停浮窗锚在光标右下 / 左下，不遮当条、不抢焦点', () {
    testWidgets('Task 51 · A：卡片跟着光标走（不再锚死 chip 右缘）', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester);
      final Rect chipRect = tester.getRect(find.byKey(_chip));
      expect(chipRect.topLeft, _chipOrigin);
      expect(chipRect.size, _chipSize);
      // 关闭态零尺寸零文本（`SizedBox.shrink()`）。
      expect(find.byKey(_hoverCard), findsNothing);
      expect(find.byKey(_hoverCardTitle), findsNothing);

      final TestGesture gesture = await _pointer(tester);
      // 落在 chip 内靠左的位置。
      await gesture.moveTo(chipRect.topLeft + const Offset(40, 20));
      await _settleCard(tester);

      expect(find.byKey(_hoverCard), findsOneWidget);
      final Rect first = tester.getRect(find.byKey(_hoverCard));
      // 「右下」：左缘 = 光标右 12px。
      expect(
        first.left,
        closeTo(chipRect.left + 40 + _cursorGapX, 1),
        reason: '卡片该落在光标右侧 12px，而不是 chip 右缘外侧',
      );
      expect(first.width, closeTo(_cardWidth, 0.01));
      // 硬约束同帧成立（细节由用例 B 单独判）。
      expect(first.top, greaterThanOrEqualTo(chipRect.bottom + _chipClearance - 0.01));

      // 同一条 chip 内再横向挪 120px：卡片必须跟着走，且位移量≈光标位移量。
      await gesture.moveTo(chipRect.topLeft + const Offset(160, 20));
      await _settleCard(tester);

      final Rect second = tester.getRect(find.byKey(_hoverCard));
      expect(
        (second.topLeft - first.topLeft).distance,
        greaterThan(20),
        reason: '卡片位置没跟着光标变 ⇒ 仍然是锚在 chip 自身几何上',
      );
      expect(
        second.left,
        closeTo(chipRect.left + 160 + _cursorGapX, 1),
        reason: '卡片左缘应等于光标右移后的新位置 + 12px',
      );

      await _quiesce(tester, gesture);
      // 收起后回到零文本：`find.byKey(slot-hover-card-title)` 必须消失。
      expect(find.byKey(_hoverCard), findsNothing);
      expect(find.byKey(_hoverCardTitle), findsNothing);
    });

    testWidgets('Task 51 · B：卡片顶边 ≥ chip 下缘 + 8px（不遮当条任务）', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, detail: '把 a–h 八项逐条落成证据', note: '[结论]按时完成');
      final Rect chipRect = tester.getRect(find.byKey(_chip));

      final TestGesture gesture = await _pointer(tester);
      // 指针落在 chip **上半部**：若照「光标下 14px」裸落位，卡片会压住 chip
      // 下半段 —— 这条用例正是拿这个位置做判别。
      await gesture.moveTo(chipRect.topLeft + const Offset(60, 6));
      await _settleCard(tester);

      expect(find.byKey(_hoverCard), findsOneWidget);
      final Rect cardRect = tester.getRect(find.byKey(_hoverCard));
      expect(
        cardRect.top,
        greaterThanOrEqualTo(chipRect.bottom + _chipClearance - 0.01),
        reason: '卡片顶边不得高于 chip 下缘 8px，否则会盖住当条任务、吃掉左/右键',
      );
      expect(cardRect.overlaps(chipRect), isFalse);

      // 指针挪到 chip 下沿附近，硬约束仍然成立（卡片不许「跟着光标」缩回去）。
      await gesture.moveTo(
        chipRect.topLeft + Offset(60, _chipSize.height - 2),
      );
      await _settleCard(tester);
      final Rect moved = tester.getRect(find.byKey(_hoverCard));
      expect(moved.top, greaterThanOrEqualTo(chipRect.bottom + _chipClearance - 0.01));

      await _quiesce(tester, gesture);
    });

    testWidgets('Task 51 · C：悬停出卡不抢焦点；指针进卡才要焦点、Esc 后焦点归还', (
      WidgetTester tester,
    ) async {
      final FocusNode owner = FocusNode(debugLabel: 'task51-owner');
      addTearDown(owner.dispose);
      await _pumpCard(tester, focusOwner: owner);
      owner.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(owner));

      final Rect chipRect = tester.getRect(find.byKey(_chip));
      final TestGesture gesture = await _pointer(tester);
      await gesture.moveTo(chipRect.center);
      await _settleCard(tester);

      expect(find.byKey(_hoverCard), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus,
        same(owner),
        reason: '打开卡片就 requestFocus 会让左键/右键打到浮窗上（点击失效的成因）',
      );

      // 正向对照：指针真的进入卡片本体 ⇒ 此时才请求焦点（Esc 才有接收者）。
      final Rect cardRect = tester.getRect(find.byKey(_hoverCard));
      await gesture.moveTo(cardRect.topLeft + const Offset(40, 20));
      await _settleCard(tester);
      expect(
        FocusManager.instance.primaryFocus,
        isNot(same(owner)),
        reason: '指针进了卡片却没把焦点交给它 ⇒ Esc 收不起来',
      );

      // Esc 收起，并把打开前的焦点还回去。
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(_hoverCard), findsNothing);
      expect(
        FocusManager.instance.primaryFocus,
        same(owner),
        reason: '收起卡片必须把焦点还给打开前的节点（`_returnFocus`）',
      );

      await _quiesce(tester, gesture);
    });
  });
}