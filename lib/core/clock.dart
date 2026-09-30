import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_date.dart';

export 'package:clock/clock.dart';

/// The app's time source. Never call `DateTime.now()` directly.
///
/// Defaults to the zone clock (`package:clock`), so `withClock` works in
/// tests; widget and provider tests override it with a fixed or fake clock.
final clockProvider = Provider<Clock>((ref) => clock, name: 'clockProvider');

/// Convenience accessors on [Clock].
extension ClockX on Clock {
  /// The current instant in UTC.
  DateTime nowUtc() => this.now().toUtc();

  /// Today's local calendar date.
  LocalDate today() => LocalDate.ofInstant(this.now());
}
