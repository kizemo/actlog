// apps/desktop/test/today_pinned_date_bar_test.dart
//
// Task 39 · W1 · 指令 1：顶部日期条不随正文垂直滚动（吸顶）。
//
// 证据口径（`AGENTS.md` R5）：几何断言才算证据，截图不算。所以本文件只断三件事：
//   1. 滚动**前后**吸顶头的 `Rect.top` 差 ≤ 1px（它根本没进滚动区）；
//   2. 同一段时间里正文首行 `Rect.top` 显著上移（证明「真的滚了」，
//      否则「头没动」可以靠「根本没滚动」假绿）；
//   3. 不给 `pinnedHeader` 时结构与引入该参数之前一致：`bodyKey` 仍在滚动区内、
//      正文仍能滚到底（不因为加了分支把滚动能力弄丢）。
//
// 为什么组件级而不是 `ShellHost` 级：`ShellHost` 依赖 `window_manager`，
// 在 widget 测试里拿不到真实窗口，`app.dart` 的 `_pinnedHeader()` 接线无法在此坐实 ——
// 这一条在 `reports/task39-w1-report.md` 里单列为「未坐实 + 重取方法」。
// 这里覆盖的是**能力层**：`LedgerPaper` / `LedgerShell` 一旦拿到 `pinnedHeader`，
// 头就必须真的不滚。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/widgets/shell/ledger_paper.dart';
import 'package:actlog/src/widgets/shell/ledger_shell.dart';

const ValueKey<String> _kHeader = ValueKey<String>('pinned-probe');

/// 账页自己那条纵向滚动区。LedgerShell 里还另有一条横向的（NavRail），
/// 只认 LedgerPaper 内部这一条，否则 drag 会报歧义。
final Finder _paperScroller = find.descendant(
  of: find.byType(LedgerPaper),
  matching: find.byType(SingleChildScrollView),
);

/// 正文探针：第 [i] 行。
ValueKey<String> _probe(int i) => ValueKey<String>('content-probe-$i');

int _probeCount = 0;

/// 高过视口的正文：每行 40px × [rows]，足矣让滚动区真的产生可滚动量。
Widget _tallBody(int rows) {
  _probeCount = rows;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < rows; i++)
        SizedBox(
          key: _probe(i),
          height: 40,
          child: Text('第 $i 行'),
        ),
    ],
  );
}

const Widget _header = Text('吸顶日期条', key: _kHeader);

void _useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 滚一下正文，返回 `[滚动前头 top, 滚动后头 top, 滚动前行 top, 滚动后行 top]`。
Future<List<double>> _scrollAndMeasure(WidgetTester tester) async {
  final Finder scroller = _paperScroller;
  final double headBefore = tester.getRect(find.byKey(_kHeader)).top;
  final double lineBefore = tester.getTopLeft(find.byKey(_probe(0))).dy;

  await tester.drag(scroller, const Offset(0, -300));
  await tester.pump();

  final double headAfter = tester.getRect(find.byKey(_kHeader)).top;
  final double lineAfter = tester.getTopLeft(find.byKey(_probe(0))).dy;
  return <double>[headBefore, headAfter, lineBefore, lineAfter];
}

void main() {
  testWidgets('① LedgerPaper 带 pinnedHeader：头纹丝不动，正文上移', (tester) async {
    _useSurface(tester, const Size(1600, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerPaper(pinnedHeader: _header, child: _tallBody(60)),
        ),
      ),
    );
    await tester.pump();

    final List<double> m = await _scrollAndMeasure(tester);

    expect(
      (m[1] - m[0]).abs(),
      lessThanOrEqualTo(1),
      reason: '吸顶头在滚动区之外，纵向滚动不许改变它的位置',
    );
    expect(
      m[2] - m[3],
      greaterThan(50),
      reason: '同一段时间里正文必须真的滚了，否则「头没动」是假绿',
    );
  });

  testWidgets('② LedgerShell 带 pinnedHeader（窄视口）：头同样不动', (tester) async {
    // 900 < narrowBreakpoint(1280) ⇒ 走 `_buildNarrow`，
    // 那里 `LedgerPaper` 的 `padding` 与 `maxWidth` 都和宽屏分支不同。
    _useSurface(tester, const Size(900, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: LedgerShell(
          content: _tallBody(60),
          currentNavId: 'today',
          pinnedHeader: _header,
        ),
      ),
    );
    await tester.pump();

    final List<double> m = await _scrollAndMeasure(tester);

    expect((m[1] - m[0]).abs(), lessThanOrEqualTo(1));
    expect(m[2] - m[3], greaterThan(50));
  });

  testWidgets('③ 不给 pinnedHeader：结构与旧版一致，正文仍能滚到底', (tester) async {
    _useSurface(tester, const Size(1600, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LedgerPaper(child: _tallBody(60))),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(LedgerPaper.bodyKey),
      findsOneWidget,
      reason: '`bodyKey` 必须仍在（`shell_ledger_shell_test` 用它读 maxWidth）',
    );
    expect(
      find.descendant(
        of: _paperScroller,
        matching: find.byKey(LedgerPaper.bodyKey),
      ),
      findsOneWidget,
      reason: '`bodyKey` 必须在滚动区内，不能被我挪到外面',
    );

    await tester.drag(_paperScroller, const Offset(0, -10000));
    await tester.pump();

    final Rect viewport = tester.getRect(_paperScroller);
    final Rect last = tester.getRect(find.byKey(_probe(_probeCount - 1)));
    expect(
      last.bottom,
      lessThanOrEqualTo(viewport.bottom + 0.5),
      reason: '无吸顶头时正文必须一直能滚到最后一行（滚动能力没被分支吃掉）',
    );
  });

  testWidgets('④ LedgerShell 不带 pinnedHeader：今日页真机形态不变', (tester) async {
    _useSurface(tester, const Size(1600, 900));
    await tester.pumpWidget(
      const MaterialApp(
        home: LedgerShell(content: Text('正文'), currentNavId: 'today'),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: _paperScroller,
        matching: find.byKey(LedgerPaper.bodyKey),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(LedgerPaper.bodyKey),
        matching: find.text('正文'),
      ),
      findsOneWidget,
    );
  });
}
