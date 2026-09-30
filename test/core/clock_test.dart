import 'package:chronos/core/clock.dart';
import 'package:chronos/core/local_date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clockProvider defaults to the zone clock', () {
    final fixed = DateTime.utc(2026, 9, 30, 10);
    withClock(Clock.fixed(fixed), () {
      final container = ProviderContainer.test();
      expect(container.read(clockProvider).now(), fixed);
    });
  });

  test('clockProvider can be overridden', () {
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2030))),
      ],
    );
    expect(container.read(clockProvider).now(), DateTime.utc(2030));
  });

  test('nowUtc and today', () {
    final c = Clock.fixed(DateTime(2026, 9, 30, 23, 30));
    expect(c.nowUtc().isUtc, isTrue);
    expect(c.nowUtc(), DateTime(2026, 9, 30, 23, 30).toUtc());
    expect(c.today(), LocalDate(2026, 9, 30));
  });
}
