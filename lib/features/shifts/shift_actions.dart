import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../domain/errors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/undo_snack_bar.dart';

/// The localized message for a failed shift/payout action, or `null` when
/// nothing should be shown ([ChronosErrorCode.busy]: another action of the
/// same controller is still running).
String? shiftsErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ChronosException) return l10n.errorSaveFailed;
  return switch (error.code) {
    ChronosErrorCode.busy => null,
    ChronosErrorCode.shiftNotFound => l10n.shiftsErrorNotFound,
    ChronosErrorCode.shiftIsRunning => l10n.shiftsErrorRunning,
    ChronosErrorCode.shiftAlreadyRunning => l10n.shiftsErrorAlreadyRunning,
    ChronosErrorCode.jobNotFound => l10n.shiftsErrorJobNotFound,
    ChronosErrorCode.noWageRate => l10n.shiftsErrorNoWage,
    ChronosErrorCode.invalidShift => l10n.shiftsErrorInvalid,
    ChronosErrorCode.startInFuture => l10n.shiftsErrorInvalid,
    ChronosErrorCode.nothingToPayOut => l10n.payoutNothingOpen,
    ChronosErrorCode.invalidAmount => l10n.payoutErrorAmount,
    _ => l10n.errorGeneric,
  };
}

/// Shows [error] of a list action in [messenger] (unless it is `busy`) and
/// records unexpected errors in the error log.
void reportShiftsError(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  ProviderContainer container,
  Object error,
  StackTrace stack,
) {
  if (error is! ChronosException) {
    unawaited(
      container.read(errorLogProvider).record(error, stack, context: 'shifts'),
    );
  }
  final message = shiftsErrorMessage(l10n, error);
  if (message == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Flips the paid state of shift [shiftId] and offers Undo in the snackbar
/// of [context]'s page.
Future<void> togglePaidWithUndo(BuildContext context, int shiftId) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final shifts = container.read(shiftsControllerProvider.notifier);
  try {
    final token = await shifts.togglePaid(shiftId);
    unawaited(HapticFeedback.selectionClick());
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: token.paid ? l10n.shiftsMarkedPaid : l10n.shiftsMarkedOpen,
      onUndo: () => unawaited(
        shifts
            .undoPaid(token)
            .catchError(
              (Object e, StackTrace st) =>
                  reportShiftsError(messenger, l10n, container, e, st),
            ),
      ),
    );
  } on Object catch (e, st) {
    reportShiftsError(messenger, l10n, container, e, st);
  }
}

/// Deletes shift [shiftId] (soft delete) and offers Undo in the snackbar of
/// [context]'s page. Returns whether the shift was deleted.
///
/// [onRestored] runs when Undo brings the shift back.
Future<bool> deleteShiftWithUndo(
  BuildContext context,
  int shiftId, {
  VoidCallback? onRestored,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final shifts = container.read(shiftsControllerProvider.notifier);
  try {
    final token = await shifts.delete([shiftId]);
    if (context.mounted) {
      showUndoSnackBar(
        context,
        message: l10n.shiftsDeleted,
        onUndo: () {
          onRestored?.call();
          unawaited(
            shifts
                .undoDelete(token)
                .catchError(
                  (Object e, StackTrace st) =>
                      reportShiftsError(messenger, l10n, container, e, st),
                ),
          );
        },
      );
    }
    return true;
  } on Object catch (e, st) {
    reportShiftsError(messenger, l10n, container, e, st);
    return false;
  }
}
