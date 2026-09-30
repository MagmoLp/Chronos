import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shows a floating snackbar with an "Undo" action, replacing the current one.
///
/// It auto-dismisses after [duration]; with TalkBack/Switch Access active
/// (`MediaQuery.accessibleNavigation`) it stays until closed so the action
/// stays reachable. Returns the controller, e.g. to react to
/// `closed` (commit the change once the undo window has passed).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 6),
}) {
  final messenger = ScaffoldMessenger.of(context);
  final accessible = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      persist: accessible,
      showCloseIcon: accessible,
      action: SnackBarAction(
        label: AppLocalizations.of(context).commonUndo,
        onPressed: onUndo,
      ),
    ),
  );
}
