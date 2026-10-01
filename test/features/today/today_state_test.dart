import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/features/today/today_state.dart';
import 'package:chronos/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/shifts.dart';
import '../../fixtures/test_clock.dart';
import '../../support/feature_harness.dart';

void main() {
  group('resolvePastStart', () {
    final now = local(2026, 9, 30, 10, 0, 30);

    test('a time earlier today is taken as is', () {
      expect(
        resolvePastStart((hour: 7, minute: 45), now: now),
        local(2026, 9, 30, 7, 45),
      );
      expect(
        resolvePastStart((hour: 10, minute: 0), now: now),
        local(2026, 9, 30, 10, 0),
      );
    });

    test('a time later today is rejected as future', () {
      expect(resolvePastStart((hour: 10, minute: 1), now: now), isNull);
      expect(resolvePastStart((hour: 21, minute: 0), now: now), isNull);
    });

    test('a late evening time after midnight means yesterday', () {
      final afterMidnight = local(2026, 9, 30, 0, 30);
      expect(
        resolvePastStart((hour: 23, minute: 0), now: afterMidnight),
        local(2026, 9, 29, 23, 0),
      );
      // More than 12 hours back is not "earlier" but the future.
      expect(
        resolvePastStart((hour: 12, minute: 0), now: afterMidnight),
        isNull,
      );
    });
  });

  group('resolveFinishEnd', () {
    test('an end earlier today is taken as is (even before the start)', () {
      final start = local(2026, 9, 30, 8);
      final now = local(2026, 9, 30, 16, 30);
      expect(
        resolveFinishEnd((hour: 16, minute: 15), start: start, now: now),
        local(2026, 9, 30, 16, 15),
      );
      expect(
        resolveFinishEnd((hour: 7, minute: 0), start: start, now: now),
        local(2026, 9, 30, 7, 0),
      );
    });

    test(
      'a night shift ends on the previous evening if that is after start',
      () {
        final start = local(2026, 9, 29, 22);
        final now = local(2026, 9, 30, 2);
        expect(
          resolveFinishEnd((hour: 23, minute: 30), start: start, now: now),
          local(2026, 9, 29, 23, 30),
        );
        expect(
          resolveFinishEnd((hour: 1, minute: 30), start: start, now: now),
          local(2026, 9, 30, 1, 30),
        );
      },
    );

    test('an end later today stays in the future', () {
      final start = local(2026, 9, 30, 8);
      final now = local(2026, 9, 30, 10);
      expect(
        resolveFinishEnd((hour: 11, minute: 0), start: start, now: now),
        local(2026, 9, 30, 11),
      );
    });
  });

  group('tick schedules', () {
    final start = DateTime.utc(2026, 9, 30, 6);
    final ticker = DateTime.utc(2000);

    test('cents: exactly when the next cent is earned, none while paused', () {
      final clock = TestClock(DateTime.utc(2026, 9, 30, 8));
      final shift = runningShift(start: start);
      // 2 h at 15 €/h = 30,00 €; 30,01 € is reached (half-up) 1.2 s later.
      expect(
        centTicks(shift, clock.clock)(ticker),
        ticker.add(const Duration(milliseconds: 1200)),
      );
      clock.advance(const Duration(milliseconds: 1200));
      expect(
        centTicks(shift, clock.clock)(ticker),
        ticker.add(const Duration(milliseconds: 2400)),
      );
      final paused = runningShift(
        start: start,
        pausedAt: DateTime.utc(2026, 9, 30, 7),
      );
      expect(centTicks(paused, clock.clock)(ticker), isNull);
    });

    test('seconds: on the next full worked second, none while paused', () {
      final clock = TestClock(DateTime.utc(2026, 9, 30, 8, 0, 0, 300));
      final shift = runningShift(start: start);
      expect(
        secondTicks(shift, clock.clock)(ticker),
        ticker.add(const Duration(milliseconds: 700)),
      );
      final paused = runningShift(
        start: start,
        pausedAt: DateTime.utc(2026, 9, 30, 7),
      );
      expect(secondTicks(paused, clock.clock)(ticker), isNull);
    });

    test('break: next displayed minute while paused, none while running', () {
      final clock = TestClock(DateTime.utc(2026, 9, 30, 7, 10, 40));
      final paused = runningShift(
        start: start,
        pausedAt: DateTime.utc(2026, 9, 30, 7),
      );
      // 10:40 break shows "0:11" (half-up); "0:12" from 11:30, 50 s later.
      expect(
        breakTicks(paused, clock.clock)(ticker),
        ticker.add(const Duration(seconds: 50)),
      );
      expect(
        breakTicks(runningShift(start: start), clock.clock)(ticker),
        isNull,
      );
    });
  });

  test('clockTimeOf is the local wall-clock time', () {
    expect(clockTimeOf(local(2026, 9, 30, 8, 2)), (hour: 8, minute: 2));
  });

  group('todayStartJobProvider', () {
    test(
      'default job until a chip selection, which it then remembers',
      () async {
        final h = ProviderHarness(kFeatureNow);
        final first = await h.job(name: 'Catering');
        final second = await h.job(name: 'Eventhalle');
        h.keepAlive(todayStartJobProvider);
        expect(await h.settle(todayStartJobProvider), first);

        h.read(todaySelectedJobIdProvider.notifier).select(second.id);
        expect(await h.settle(todayStartJobProvider), second);

        // An archived selection falls back to the default job.
        await h.read(jobRepositoryProvider).setArchived(second.id, true);
        expect(await h.settle(todayStartJobProvider), first);
      },
    );
  });

  test('error messages: busy is ignored, codes are localized', () {
    final l10n = lookupAppLocalizations(const Locale('de'));
    expect(
      todayErrorMessage(l10n, const ChronosException(ChronosErrorCode.busy)),
      isNull,
    );
    expect(
      todayErrorMessage(
        l10n,
        const ChronosException(ChronosErrorCode.startInFuture),
      ),
      l10n.todayErrorStartInFuture,
    );
    expect(
      todayErrorMessage(
        l10n,
        const ChronosException(ChronosErrorCode.shiftAlreadyRunning),
      ),
      l10n.todayErrorAlreadyRunning,
    );
    expect(
      todayErrorMessage(
        l10n,
        const ChronosException(ChronosErrorCode.backupInvalid),
      ),
      l10n.errorSaveFailed,
    );
  });
}
