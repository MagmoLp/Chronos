import 'package:clock/clock.dart';

/// A controllable clock for tests: starts at [start] and only moves when
/// told to.
class TestClock {
  /// Creates a clock frozen at [start].
  TestClock(DateTime start) : _now = start.toUtc();

  DateTime _now;

  /// The current test time (UTC).
  DateTime get now => _now;

  /// A [Clock] reading this test clock.
  late final Clock clock = Clock(() => _now);

  /// Moves the clock forward by [duration].
  void advance(Duration duration) => _now = _now.add(duration);

  /// Sets the clock to [instant].
  void set(DateTime instant) => _now = instant.toUtc();
}
