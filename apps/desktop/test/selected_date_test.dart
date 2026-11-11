import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:actlog/src/providers.dart';

void main() {
  test('selectedDateProvider 初值跟随 todayProvider（测试可 override）', () {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue('2026-11-07')],
    );
    expect(container.read(selectedDateProvider), '2026-11-07');
    container.dispose();
  });

  test('selectedDateProvider 可被改写（切日 / 回今天）', () {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue('2026-11-07')],
    );
    container.read(selectedDateProvider.notifier).state = '2026-11-03';
    expect(container.read(selectedDateProvider), '2026-11-03');
    container.dispose();
  });
}
