import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/job.dart';
import '../../domain/shift.dart';

/// Everything outside the database that must follow the running shift:
/// the ongoing notification and the "still working?" reminder.
///
/// The controllers call [shiftChanged] after every change of the running
/// shift (start, pause, resume, adjusted start, finish, undo, discard,
/// restore, wage change, data import/wipe) and from `reconcile()` at app
/// start/resume – never periodically. Implementations post once per call.
abstract interface class ShiftSideEffects {
  /// The running shift is now [running] (with its [job]); `null` = none.
  Future<void> shiftChanged(Shift? running, Job? job);
}

/// Does nothing (default until the platform layer is wired in, and tests).
class NoopShiftSideEffects implements ShiftSideEffects {
  /// Creates the no-op implementation.
  const NoopShiftSideEffects();

  @override
  Future<void> shiftChanged(Shift? running, Job? job) async {}
}

/// Side effects of running-shift changes. The app overrides this with the
/// notification/reminder implementation from `lib/platform`.
final shiftSideEffectsProvider = Provider<ShiftSideEffects>(
  (ref) => const NoopShiftSideEffects(),
  name: 'shiftSideEffectsProvider',
);
