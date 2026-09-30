import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/local_date.dart';
import '../../data/payout_repository.dart';
import '../../domain/payout.dart';
import 'core_providers.dart';
import 'shift_providers.dart';

/// All payouts, newest first.
final payoutsProvider = StreamProvider<List<Payout>>(
  (ref) => ref.watch(payoutRepositoryProvider).watchPayouts(),
  name: 'payoutsProvider',
);

/// Key of [payoutPreviewProvider]: shifts up to and including [until],
/// of [jobId] (`null` = all jobs).
typedef PayoutQuery = ({LocalDate until, int? jobId});

/// Live preview for the payout sheet ("23 Schichten · 172,5 h · Erwartet").
final payoutPreviewProvider = StreamProvider.autoDispose
    .family<PayoutSelection, PayoutQuery>(
      (ref, query) => ref
          .watch(payoutRepositoryProvider)
          .watchPreview(until: query.until, jobId: query.jobId),
      name: 'payoutPreviewProvider',
    );

/// Payout actions.
final payoutControllerProvider = NotifierProvider<PayoutController, bool>(
  PayoutController.new,
  name: 'payoutControllerProvider',
);

/// Preview, create and undo payouts.
class PayoutController extends BusyNotifier {
  PayoutRepository get _payouts => ref.read(payoutRepositoryProvider);

  /// What a payout would settle (one-off read).
  Future<PayoutSelection> preview({required LocalDate until, int? jobId}) =>
      _payouts.preview(until: until, jobId: jobId);

  /// Records the payout and marks its shifts paid. [receivedCents] defaults
  /// to the expected amount, [paidOn] to today.
  Future<Payout> create({
    required LocalDate until,
    int? jobId,
    int? receivedCents,
    LocalDate? paidOn,
    String? note,
  }) => runBusy(
    () => _payouts.create(
      until: until,
      jobId: jobId,
      receivedCents: receivedCents,
      paidOn: paidOn,
      note: note,
    ),
  );

  /// Undo: reopens the shifts and removes the payout.
  Future<int> undo(Payout payout) => runBusy(() => _payouts.undo(payout.id));
}
