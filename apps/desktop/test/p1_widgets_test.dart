import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/theme/app_fonts.dart';
import 'package:actlog/src/theme/app_theme.dart';
import 'package:actlog/src/theme/density_profile.dart';
import 'package:actlog/src/widgets/priority_chips.dart';

/// 弹出对话框后捕获返回值。
///
/// 单独记 `returned` 是因为「用户点了取消」和「还没返回」都是 null，
/// 不加这个标志会把「取消」误判成「尚未结束」。
class _Harness<T> {
  T? value;
  bool returned = false;
}

Future<_Harness<T>> _open<T>(
  WidgetTester tester,
  Future<T?> Function(BuildContext context) open,
) async {
  final harness = _Harness<T>();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                harness.value = await open(context);
                harness.returned = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return harness;
}

/// 返回当前键盘焦点落在第几个宫格上；不在宫格上则返回 -1。
///
/// 焦点节点挂在 `InkWell` 内部的 `Focus` 元素上，context 不等于格子元素本身，
/// 所以要沿祖先链回溯，判断焦点是否落在某个格子的子树内。
int _focusedCellIndex(Finder cells) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return -1;
  final cellElements = cells.evaluate().toList(growable: false);
  for (var i = 0; i < cellElements.length; i++) {
    if (_hasAncestor(focusContext as Element, cellElements[i])) return i;
  }
  return -1;
}

/// [element] 的祖先链里是否包含 [ancestor]（含自身）。
bool _hasAncestor(Element element, Element ancestor) {
  if (identical(element, ancestor)) return true;
  var found = false;
  element.visitAncestorElements((ancestorElement) {
    if (identical(ancestorElement, ancestor)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  group('QuadrantPickerDialog', () {
    testWidgets('2×2 宫格渲染四个象限', (tester) async {
      await _open<QuadrantPick>(
        tester,
        (context) => QuadrantPickerDialog.show(
          context,
          selected: null,
          mode: PriorityDisplayMode.quadrant,
        ),
      );
      final cells = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(cells, findsNWidgets(4));
    });

    testWidgets('点击未选中的格子返回该象限', (tester) async {
      final first = QuadrantStyle.all.values.first.quadrant;
      final harness = await _open<QuadrantPick>(
        tester,
        (context) => QuadrantPickerDialog.show(
          context,
          selected: null,
          mode: PriorityDisplayMode.quadrant,
        ),
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(harness.returned, isTrue);
      expect(harness.value, isNotNull);
      expect(harness.value!.value, first);
    });

    testWidgets('再次点击已选中的格子返回清空标记', (tester) async {
      final first = QuadrantStyle.all.values.first.quadrant;
      final harness = await _open<QuadrantPick>(
        tester,
        (context) => QuadrantPickerDialog.show(
          context,
          selected: first,
          mode: PriorityDisplayMode.quadrant,
        ),
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(harness.returned, isTrue);
      expect(harness.value, isNotNull, reason: '取消要返回 null，清空要返回 QuadrantPick(null)');
      expect(harness.value!.value, isNull);
    });

    testWidgets('点「取消」返回 null，与清空区分开', (tester) async {
      final harness = await _open<QuadrantPick>(
        tester,
        (context) => QuadrantPickerDialog.show(
          context,
          selected: Quadrant.q1,
          mode: PriorityDisplayMode.quadrant,
        ),
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(harness.returned, isTrue);
      expect(harness.value, isNull);
    });

    testWidgets('键盘可达：Tab 能聚焦到宫格，Enter 能确认选择', (tester) async {
      final harness = await _open<QuadrantPick>(
        tester,
        (context) => QuadrantPickerDialog.show(
          context,
          selected: null,
          mode: PriorityDisplayMode.quadrant,
        ),
      );

      final cells = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );

      // 一路 Tab，直到焦点落在宫格里的某个格子上。
      var focusedIndex = -1;
      for (var i = 0; i < 12 && focusedIndex < 0; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        focusedIndex = _focusedCellIndex(cells);
      }
      expect(
        focusedIndex,
        isNot(-1),
        reason: '键盘必须能 Tab 到象限格（验收标准：键盘可达）',
      );

      // Enter = 激活当前聚焦的格子。
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(harness.returned, isTrue);
      expect(harness.value, isNotNull);
      expect(
        harness.value!.value,
        QuadrantStyle.all.values.toList()[focusedIndex].quadrant,
        reason: '确认的必须是当前聚焦的那一格',
      );
    });
  });

  group('AbcPickerDialog', () {
    testWidgets('三个 ABC 档位 + 清除项都在', (tester) async {
      await _open<AbcPick>(
        tester,
        (context) => AbcPickerDialog.show(context, selected: null),
      );
      expect(
        find.byType(SimpleDialogOption),
        findsNWidgets(AbcStyle.all.length + 1),
      );
    });

    testWidgets('点击未选中的档位返回该档位', (tester) async {
      final first = AbcStyle.all.values.first.priority;
      final harness = await _open<AbcPick>(
        tester,
        (context) => AbcPickerDialog.show(context, selected: null),
      );
      await tester.tap(find.byType(SimpleDialogOption).first);
      await tester.pumpAndSettle();
      expect(harness.value, isNotNull);
      expect(harness.value!.value, first);
    });

    testWidgets('再次点击已选中的档位返回清空标记', (tester) async {
      final first = AbcStyle.all.values.first.priority;
      final harness = await _open<AbcPick>(
        tester,
        (context) => AbcPickerDialog.show(context, selected: first),
      );
      await tester.tap(find.byType(SimpleDialogOption).first);
      await tester.pumpAndSettle();
      expect(harness.value, isNotNull);
      expect(harness.value!.value, isNull);
    });

    // D-4 定案探针：`priority_chips.dart:245` 的档位标签只写
    // `TextStyle(fontWeight: FontWeight.w700)`，没有 `fontFamily`。
    // 裸 `TextStyle` 的 `inherit` 为 true ⇒ `Text.build` 会
    // `DefaultTextStyle.of(context).style.merge(style)`，族名从环境继承。
    //
    // 所以这条用例**必须挂项目主题**（`AppTheme.light(DensityProfile.comfortable)`，
    // 与 `lib/src/app.dart:56` 一致）。用裸 `MaterialApp` 只能看到默认 Roboto 主题，
    // 会把「测试脚手架没主题」误判成「实现丢了字体族」。
    testWidgets('ABC 档位标签解析后的字体族是 Inter（不是 Roboto）', (tester) async {
      final String label = AbcStyle.all.values.first.label;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(DensityProfile.comfortable),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      AbcPickerDialog.show(context, selected: null),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // `RenderParagraph.text` 是 `DefaultTextStyle.merge(style)` 之后的实际绘制样式，
      // 也就是「这一帧真的拿这个族名去查字体」。
      final RenderParagraph paragraph =
          tester.renderObject<RenderParagraph>(find.text(label));
      final TextSpan span = paragraph.text as TextSpan;
      final String? family = span.style?.fontFamily;

      expect(
        family,
        AppFonts.body,
        reason: '档位「$label」解析后的 fontFamily 实测为「$family」，'
            '期望「${AppFonts.body}」⇒ 裸 TextStyle 应在 DefaultTextStyle 上继承族名；'
            '落 Roboto（或 null）说明环境文字样式没带 AppFonts.body',
      );
      expect(
        span.style?.fontWeight,
        FontWeight.w700,
        reason: '实测 fontWeight = ${span.style?.fontWeight}；'
            'w700 是既定选择（Noto Sans SC 只有 400 一档，靠合成粗，见 D-5）',
      );
    });
  });

  group('PriorityTagChip', () {
    Future<void> pumpChip(
      WidgetTester tester,
      PriorityDisplayMode mode, {
      Quadrant? quadrant,
      PriorityAbc? priorityAbc,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriorityTagChip(
              mode: mode,
              quadrant: quadrant,
              priorityAbc: priorityAbc,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('四象限模式显示象限标签', (tester) async {
      await pumpChip(
        tester,
        PriorityDisplayMode.quadrant,
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.a,
      );
      expect(
        find.text(
          PriorityDisplay.labelFor(
            PriorityDisplayMode.quadrant,
            quadrant: Quadrant.q1,
            priorityAbc: PriorityAbc.a,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ABC 模式忽略象限，只显示 ABC 标签', (tester) async {
      await pumpChip(
        tester,
        PriorityDisplayMode.abc,
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.a,
      );
      expect(
        find.text(
          PriorityDisplay.labelFor(
            PriorityDisplayMode.abc,
            quadrant: Quadrant.q1,
            priorityAbc: PriorityAbc.a,
          ),
        ),
        findsOneWidget,
      );
      // 同一份数据（Q1 + A）在两种模式下渲染出的文案必须不同，
      // 否则「切换模式」就只是换了个按钮图标。
      final quadrantLabel = PriorityDisplay.labelFor(
        PriorityDisplayMode.quadrant,
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.a,
      );
      final abcLabel = PriorityDisplay.labelFor(
        PriorityDisplayMode.abc,
        quadrant: Quadrant.q1,
        priorityAbc: PriorityAbc.a,
      );
      expect(quadrantLabel, isNot(equals(abcLabel)));
    });

    testWidgets('两种模式表头提示互不相同', (tester) async {
      expect(
        PriorityDisplay.headerHint(PriorityDisplayMode.quadrant),
        isNot(equals(PriorityDisplay.headerHint(PriorityDisplayMode.abc))),
      );
      expect(
        PriorityDisplay.headerHint(PriorityDisplayMode.quadrant),
        contains('Q1'),
      );
    });
  });
}