import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/legacy/legacy_models.dart';
import '../../domain/review.dart';
import 'core_providers.dart';
import 'shift_providers.dart';

/// Migrated shifts to review ("N übernommene Einträge prüfen").
final reviewItemsProvider = StreamProvider<List<ReviewItem>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchItems(),
  name: 'reviewItemsProvider',
);

/// v1 entries that could not be imported.
final legacyFailuresProvider = StreamProvider<List<LegacyFailure>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchLegacyFailures(),
  name: 'legacyFailuresProvider',
);

/// The migrated wage if it still needs confirmation ("1250,00 €/h – stimmt
/// das?"), else `null`.
final pendingWageCheckProvider = FutureProvider<WagePlausibility?>(
  (ref) => ref.watch(legacyMigratorProvider).pendingWageCheck(),
  name: 'pendingWageCheckProvider',
);

/// Review list and wage question actions.
final reviewControllerProvider = NotifierProvider<ReviewController, bool>(
  ReviewController.new,
  name: 'reviewControllerProvider',
);

/// Dismiss review items, fix or confirm the migrated wage.
class ReviewController extends BusyNotifier {
  /// "Passt so": removes the item of [shiftId].
  Future<void> dismiss(int shiftId) =>
      runBusy(() => ref.read(reviewRepositoryProvider).dismiss(shiftId));

  /// Removes all review items.
  Future<void> dismissAll() =>
      runBusy(() => ref.read(reviewRepositoryProvider).dismissAll());

  /// Corrects the migrated wage (job rate, snapshots and amounts of all
  /// migrated shifts). Returns the number of updated shifts.
  Future<int> fixWage(int centsPerHour) => runBusy(() async {
    final count = await ref
        .read(legacyMigratorProvider)
        .correctWage(centsPerHour);
    ref.invalidate(pendingWageCheckProvider);
    await notifyShiftSideEffects(ref);
    return count;
  });

  /// Keeps the migrated wage as it is.
  Future<void> confirmWage() => runBusy(() async {
    await ref.read(legacyMigratorProvider).confirmWage();
    ref.invalidate(pendingWageCheckProvider);
  });
}
