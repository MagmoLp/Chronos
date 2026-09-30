import 'package:chronos/widgets/live_ticker.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Runs [body] with a clock that starts at [start] and advances with the
/// test's fake time, while recording every timer that is created.
Future<void> _withFakeWallClock(
  DateTime start,
  TimerTracker timers,
  Future<void> Function() body,
) {
  final fake = clock;
  final origin = fake.now();
  return timers.run(
    () =>
        withClock(Clock(() => start.add(fake.now().difference(origin))), body),
  );
}

/// Pumps [total] in 100 ms frames, so every timer tick produces its own
/// frame (as it would on a device).
Future<void> _pumpInSteps(WidgetTester tester, Duration total) async {
  for (
    var t = Duration.zero;
    t < total;
    t += const Duration(milliseconds: 100)
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _bare(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

/// Moves the app through the real lifecycle sequence to [target].
void _goTo(WidgetTester tester, AppLifecycleState target) {
  const order = <AppLifecycleState>[
    AppLifecycleState.resumed,
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  final current = tester.binding.lifecycleState ?? AppLifecycleState.resumed;
  var i = order.indexOf(current);
  final j = order.indexOf(target);
  while (i != j) {
    i += j > i ? 1 : -1;
    tester.binding.handleAppLifecycleStateChanged(order[i]);
  }
}

void main() {
  test('nextFullSecond is strictly after now', () {
    expect(
      LiveTicker.nextFullSecond(DateTime.utc(2026, 9, 30, 8, 0, 0, 400)),
      DateTime.utc(2026, 9, 30, 8, 0, 1),
    );
    expect(
      LiveTicker.nextFullSecond(DateTime.utc(2026, 9, 30, 8)),
      DateTime.utc(2026, 9, 30, 8, 0, 1),
    );
    expect(
      LiveTicker.nextFullSecond(DateTime(2026, 9, 30, 8, 0, 59, 999)),
      DateTime(2026, 9, 30, 8, 1),
    );
  });

  testWidgets('rebuilds exactly on every wall-clock second', (tester) async {
    final timers = TimerTracker();
    final ticks = <DateTime>[];
    await _withFakeWallClock(
      DateTime(2026, 9, 30, 8, 0, 0, 400),
      timers,
      () async {
        await tester.pumpWidget(
          _bare(
            LiveTicker(
              builder: (context, now) {
                ticks.add(now);
                return Text('${now.second}');
              },
            ),
          ),
        );
        expect(ticks.single, DateTime(2026, 9, 30, 8, 0, 0, 400));
        await tester.pump(const Duration(milliseconds: 599));
        expect(ticks, hasLength(1));
        await tester.pump(const Duration(milliseconds: 1));
        expect(ticks.last, DateTime(2026, 9, 30, 8, 0, 1));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(ticks.skip(1), [
          DateTime(2026, 9, 30, 8, 0, 1),
          DateTime(2026, 9, 30, 8, 0, 2),
          DateTime(2026, 9, 30, 8, 0, 3),
          DateTime(2026, 9, 30, 8, 0, 4),
        ]);
        expect(timers.pending, 1);
        await tester.pumpWidget(_bare(const SizedBox()));
        expect(timers.pending, 0, reason: 'dispose cancels the timer');
      },
    );
  });

  testWidgets(
    'custom schedule ticks when the next cent is earned, at most 4× per second',
    (tester) async {
      final timers = TimerTracker();
      final start = DateTime(2026, 9, 30, 8);
      final ticks = <Duration>[];
      // 15 €/h → one cent every 2.4 s.
      DateTime nextCent(DateTime now) {
        final elapsed = now.difference(start).inMilliseconds;
        return start.add(Duration(milliseconds: (elapsed ~/ 2400 + 1) * 2400));
      }

      await _withFakeWallClock(start, timers, () async {
        await tester.pumpWidget(
          _bare(
            LiveTicker(
              nextTick: nextCent,
              builder: (context, now) {
                ticks.add(now.difference(start));
                return const SizedBox();
              },
            ),
          ),
        );
        await _pumpInSteps(tester, const Duration(seconds: 10));
        expect(ticks, const [
          Duration.zero,
          Duration(milliseconds: 2400),
          Duration(milliseconds: 4800),
          Duration(milliseconds: 7200),
          Duration(milliseconds: 9600),
        ]);

        // A schedule that asks for 100 ticks per second is throttled to 4.
        ticks.clear();
        await tester.pumpWidget(
          _bare(
            LiveTicker(
              nextTick: (now) => now.add(const Duration(milliseconds: 10)),
              builder: (context, now) {
                ticks.add(now.difference(start));
                return const SizedBox();
              },
            ),
          ),
        );
        ticks.clear();
        await _pumpInSteps(tester, const Duration(seconds: 1));
        expect(ticks, hasLength(4));

        // A schedule that returns null stops ticking.
        await tester.pumpWidget(
          _bare(
            LiveTicker(
              nextTick: (_) => null,
              builder: (_, _) => const SizedBox(),
            ),
          ),
        );
        expect(timers.pending, 0);
      });
    },
  );

  testWidgets(
    'no timers while the app is hidden or paused; refreshes on resume',
    (tester) async {
      final timers = TimerTracker();
      var builds = 0;
      DateTime? lastNow;
      await _withFakeWallClock(DateTime(2026, 9, 30, 8), timers, () async {
        _goTo(tester, AppLifecycleState.resumed);
        await tester.pumpWidget(
          _bare(
            LiveTicker(
              builder: (context, now) {
                builds++;
                lastNow = now;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(timers.pending, 1);

        _goTo(tester, AppLifecycleState.inactive);
        await tester.pump();
        expect(timers.pending, 1, reason: 'inactive apps are still visible');

        _goTo(tester, AppLifecycleState.hidden);
        await tester.pump();
        expect(timers.pending, 0, reason: 'hidden: no timer');

        _goTo(tester, AppLifecycleState.paused);
        final buildsWhilePaused = builds;
        await tester.pump(const Duration(minutes: 30));
        expect(timers.pending, 0, reason: 'paused: no timer');
        expect(builds, buildsWhilePaused, reason: 'no work in the background');

        _goTo(tester, AppLifecycleState.resumed);
        await tester.pump();
        expect(
          builds,
          buildsWhilePaused + 1,
          reason: 'rebuilds right away on resume',
        );
        expect(
          lastNow,
          DateTime(2026, 9, 30, 8, 30),
          reason: 'with the fresh time',
        );
        expect(timers.pending, 1);
        await tester.pumpWidget(_bare(const SizedBox()));
      });
    },
  );

  testWidgets(
    'no timers while tickers are disabled (inactive tab / covered route)',
    (tester) async {
      final timers = TimerTracker();
      var builds = 0;
      Widget host({required bool enabled}) => _bare(
        TickerMode(
          enabled: enabled,
          child: LiveTicker(
            builder: (context, now) {
              builds++;
              return const SizedBox();
            },
          ),
        ),
      );
      await _withFakeWallClock(DateTime(2026, 9, 30, 8), timers, () async {
        await tester.pumpWidget(host(enabled: false));
        expect(timers.pending, 0);
        final before = builds;
        await tester.pump(const Duration(seconds: 10));
        expect(builds, before);

        await tester.pumpWidget(host(enabled: true));
        expect(timers.pending, 1);
        await tester.pumpWidget(host(enabled: false));
        expect(timers.pending, 0);
        await tester.pumpWidget(_bare(const SizedBox()));
      });
    },
  );

  testWidgets('no timers inside a non-selected IndexedStack child', (
    tester,
  ) async {
    final timers = TimerTracker();
    Widget host(int index) => _bare(
      IndexedStack(
        index: index,
        children: <Widget>[
          const SizedBox(),
          LiveTicker(builder: (context, now) => const SizedBox()),
        ],
      ),
    );
    await _withFakeWallClock(DateTime(2026, 9, 30, 8), timers, () async {
      await tester.pumpWidget(host(0));
      expect(timers.pending, 0);
      await tester.pumpWidget(host(1));
      expect(timers.pending, 1);
      await tester.pumpWidget(_bare(const SizedBox()));
    });
  });

  testWidgets('enabled: false builds once and never schedules', (tester) async {
    final timers = TimerTracker();
    var builds = 0;
    await _withFakeWallClock(DateTime(2026, 9, 30, 8), timers, () async {
      await tester.pumpWidget(
        _bare(
          LiveTicker(
            enabled: false,
            builder: (context, now) {
              builds++;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(builds, 1);
      expect(timers.created, 0);
      await tester.pumpWidget(_bare(const SizedBox()));
    });
  });
}
