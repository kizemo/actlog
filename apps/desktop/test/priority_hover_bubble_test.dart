// apps/desktop/test/priority_hover_bubble_test.dart
//
// 四维优先级「悬停气泡」的行为契约。三个渲染点（`day_grid` /
// `unscheduled_strip` / `todo_rail_panel`）共用同一个组件，落库路径也共用
// `planItem.setQuadrant`，所以这里用「真库 + 真仓储 + 真 ProviderContainer」
// 的可写夹具来验，而不是造假仓库 —— `ActLogRepositories` 是 `final class`，
// 本来也无法继承。
//
// 本文件的 `_Slot` 逐行照抄 `day_grid._chipBody` 的 `if (quadrant != null)`
// 分支与 `_setQuadrant` 的调用形态，用来证明「点了气泡 ⇒ 真落库 ⇒ 流回流 ⇒
// 字形回写」这条链路在真实调用点成立。
import 'package:actlog/src/providers.dart';
import 'package:actlog/src/widgets/priority_hover_bubble.dart';
import 'package:actlog/src/widgets/priority_marks.dart';
import 'package:core_data/core_data.dart';
import 'package:core_db/core_db.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 只在 misc.dart 导出（3.5.0 起 flutter_riverpod.dart 不再带它）。
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// 夹具日：与 `habit_checkin_strip_test.dart` 同一口径。
const String _day = '2026-11-09';

/// 气泡本体（外层卡片的 `ValueKey`，见 `_bubbleCard`）。
///
/// 用 getter 而不是顶层常量：`find.byKey` 是方法调用，不能进 const 表达式。
Finder get _bubble =>
    find.byKey(const ValueKey<String>('priority-hover-bubble'));

/// 夹具：内存真库 + 真仓储 + 可读 `planItemsProvider` 的容器。
final class _Harness {
  _Harness._(this.db, this.repos, this.container);

  final ActLogDatabase db;
  final ActLogRepositories repos;
  final ProviderContainer container;

  static _Harness create() {
    final db = openInMemoryActLogDatabase();
    final repos = ActLogRepositories(db, deviceId: 'bubble-test');
    final container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_day),
        repositoriesProvider.overrideWithValue(repos),
        selectedDateProvider.overrideWith((ref) => _day),
      ],
    );
    // `addTearDown` 按 LIFO 执行 ⇒ 先登记关库、后登记销毁容器，
    // 实际顺序是「先 dispose 容器、再 db.close」。反过来会永久挂起：
    // 容器仍持有 drift 流订阅时 `db.close()` 永远等不到流收尾。
    addTearDown(db.close);
    addTearDown(container.dispose);
    return _Harness._(db, repos, container);
  }

  /// 挂上 `_Slot`。锚点放在左上角内侧，保证 344px 气泡向右展开时不越界
  /// （越界会让 `_shouldFlipLeft` 翻转，增加与断言无关的变量）。
  Future<void> mount(WidgetTester tester, String id) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, top: 120),
                child: _Slot(id: id),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 照抄 `day_grid._chipBody`：未分级**不渲染任何标记**（不是渲染空标记）。
class _Slot extends ConsumerWidget {
  const _Slot({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PlanItemData> rows =
        ref.watch(planItemsProvider).asData?.value ?? const <PlanItemData>[];
    final PlanItemData? row = _findById(rows, id);
    if (row == null) {
      return const SizedBox(height: 20, width: 120);
    }
    // drift 列存的是 `Q1`..`Q4` 字符串，转回领域枚举才进得去组件。
    final Quadrant? quadrant = Quadrant.fromCode(row.quadrant);
    if (quadrant == null) {
      return const SizedBox(height: 20, width: 120);
    }
    return PriorityHoverBubble(
      quadrant: quadrant,
      title: row.title,
      // 与 `day_grid._setQuadrant` 同一调用：真写库，再由
      // `planItemsProvider` 回流驱动字形回写。
      onChanged: (Quadrant? next) {
        ref.read(repositoriesProvider).planItem.setQuadrant(row.id, next);
      },
    );
  }
}

PlanItemData? _findById(List<PlanItemData> rows, String id) {
  for (final PlanItemData row in rows) {
    if (row.id == id) {
      return row;
    }
  }
  return null;
}

/// 把上一轮异步（drift 流查询、provider 重算、写库）全部推完。
///
/// 刻意**不用** `pumpAndSettle`：加载态可能是无限重复动画，
/// `pumpAndSettle` 永远等不到稳定，会一路挂到超时（同 `p1_e2e_test.dart`）。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// 收尾：drift 在 StreamProvider 被 dispose 时会排一个 0 长度 timer，
/// 框架在 tearDown **之前**就检查 pending timer ⇒ 必须在用例体内跑完这帧。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 用鼠标指针悬停到 [target] 中心，触发 `MouseRegion.onEnter`。
Future<void> _hover(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('未分级条目（day_grid 形状）：一个标记都不渲染、不出气泡', (tester) async {
    final harness = _Harness.create();
    final String id = await harness.repos.planItem.create(
      date: _day,
      title: '写周报',
    );

    await harness.mount(tester, id);
    await _settle(tester);

    // 计划条目存在，但 `quadrant == null` ⇒ 标记通道整条不存在。
    expect(find.byType(PriorityHoverBubble), findsNothing);
    expect(find.byType(PriorityMarks), findsNothing);
    // 两条轴都走 Material Icon：按图标查（四枚含填充 / 空心）才证明「一枚都没画」。
    expect(find.byIcon(kMarkImportant), findsNothing);
    expect(find.byIcon(kMarkNotImportant), findsNothing);
    expect(find.byIcon(kMarkUrgent), findsNothing);
    expect(find.byIcon(kMarkNotUrgent), findsNothing);
    expect(_bubble, findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('未分级直挂气泡：零尺寸、无字形、悬停不弹气泡', (tester) async {
    // 本组件对 `quadrant == null` 的自身契约：退化成与 `PriorityMarks`
    // 完全一致的零尺寸占位，**不留占位、不出气泡**。
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PriorityHoverBubble(quadrant: null, title: '空'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PriorityMarks), findsOneWidget);
    expect(tester.getSize(find.byType(PriorityMarks)), Size.zero);
    expect(find.byIcon(kMarkImportant), findsNothing);
    expect(find.byIcon(kMarkNotImportant), findsNothing);
    expect(find.byIcon(kMarkUrgent), findsNothing);
    expect(find.byIcon(kMarkNotUrgent), findsNothing);

    await _hover(tester, find.byType(PriorityHoverBubble));
    expect(_bubble, findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('悬停已分级标记：气泡给出象限结论与两维取值', (tester) async {
    final harness = _Harness.create();
    final String id = await harness.repos.planItem.create(
      date: _day,
      title: '写复盘',
      quadrant: Quadrant.q1,
    );

    await harness.mount(tester, id);
    await _settle(tester);
    // 惰性构建：没悬停时 overlay 子节点根本不存在，基线计数不受污染。
    expect(_bubble, findsNothing);

    await _hover(tester, find.byType(PriorityMarks));

    expect(_bubble, findsOneWidget);
    // 抬头：象限代号 + 计划名。
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('写复盘'), findsOneWidget);
    // 两维取值：维度名 + 选中的那枚芯片，各一处。
    expect(find.text('紧急'), findsNWidgets(2));
    expect(find.text('重要'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('priority-urgent-on')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('priority-important-on')),
      findsOneWidget,
    );
    // 人话结论 + 行动建议。
    expect(find.text('重要且紧急'), findsOneWidget);
    expect(find.text('立即做'), findsOneWidget);
    expect(find.textContaining('马上处理'), findsOneWidget);

    await _flushTimers(tester);
  });

  testWidgets('气泡内点「不重要」：真落库为 Q3，并驱动字形回写', (tester) async {
    final harness = _Harness.create();
    final String id = await harness.repos.planItem.create(
      date: _day,
      title: '写复盘',
      quadrant: Quadrant.q1,
    );

    await harness.mount(tester, id);
    await _settle(tester);
    await _hover(tester, find.byType(PriorityMarks));
    expect(_bubble, findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('priority-important-off')),
    );
    await _settle(tester);

    // 仓库层：真库该行的 quadrant 已经变了（证明 `setQuadrant` 被调用）。
    final List<PlanItemData> rows = await harness.repos.planItem.listRange(
      _day,
      _day,
    );
    expect(rows.single.quadrant, Quadrant.q3.code);

    // 流回流：气泡结论换成 Q3，主通道标记由「重要」换成「不重要」。
    expect(find.text('Q3'), findsOneWidget);
    expect(find.text('紧急不重要'), findsOneWidget);
    // 气泡与主通道**同 key**：主通道 1 枚（`-not-important`）+ 气泡「不重要」
    // 芯片 1 枚 ⇒ 2 枚。同轴同图标、只差填充之下，key 是唯一能分开两态的凭据。
    expect(find.byKey(kMarkNotImportantSpec.key), findsNWidgets(2));
    // 气泡里「重要」那枚芯片**始终**渲染自己的标记（只是未选中），
    // 所以绝不能断言它消失 —— 它是重要性轴的另一半。
    expect(find.byKey(kMarkImportantSpec.key), findsOneWidget);
    // 紧急度轴同理：主通道实心铃 + 气泡「紧急」芯片 = 2；「不紧急」只在芯片里。
    expect(find.byIcon(kMarkUrgent), findsNWidgets(2));
    expect(find.byIcon(kMarkNotUrgent), findsOneWidget);
    // 同轴同图标、只差填充：两枚 spec 共用同一个 `icon`，`filled` 取反；
    // 落到画面上就是主通道换成了空心星，实心星只剩气泡里那枚芯片。
    expect(kMarkImportantSpec.icon, kMarkNotImportantSpec.icon);
    expect(kMarkImportantSpec.filled, isNot(kMarkNotImportantSpec.filled));
    expect(find.byIcon(kMarkImportant), findsOneWidget); // 只剩气泡「重要」芯片
    expect(find.byIcon(kMarkNotImportant), findsNWidgets(2)); // 主通道 + 芯片

    await _flushTimers(tester);
  });

  testWidgets('Esc 关闭气泡', (tester) async {
    final harness = _Harness.create();
    final String id = await harness.repos.planItem.create(
      date: _day,
      title: '排下周计划',
      quadrant: Quadrant.q2,
    );

    await harness.mount(tester, id);
    await _settle(tester);
    await _hover(tester, find.byType(PriorityMarks));
    expect(_bubble, findsOneWidget);

    // 打开时已把焦点交给气泡（post-frame），Esc 由气泡自己的
    // `Focus.onKeyEvent` 处理。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(_bubble, findsNothing);

    await _flushTimers(tester);
  });

  testWidgets('点标记本身可开合气泡', (tester) async {
    final harness = _Harness.create();
    final String id = await harness.repos.planItem.create(
      date: _day,
      title: '回邮件',
      quadrant: Quadrant.q4,
    );

    await harness.mount(tester, id);
    await _settle(tester);

    await tester.tap(find.byType(PriorityMarks), warnIfMissed: false);
    await tester.pump();
    expect(_bubble, findsOneWidget);

    await tester.tap(find.byType(PriorityMarks), warnIfMissed: false);
    await tester.pump();
    expect(_bubble, findsNothing);

    await _flushTimers(tester);
  });
}
