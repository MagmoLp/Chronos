import 'package:flutter/material.dart';

import '../app/theme/theme.dart';
import '../l10n/app_localizations.dart';

/// A Material 3 confirmation dialog with a cancel and a confirm action.
///
/// Use it only for irreversible or bulk actions (single deletions use Undo).
/// Prefer [showConfirmDialog].
class ConfirmDialog extends StatelessWidget {
  /// Creates the dialog.
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.message,
    this.cancelLabel,
    this.icon,
    this.destructive = false,
  });

  /// Question as a title ("214 Schichten und 2 Jobs löschen?").
  final String title;

  /// Supporting text.
  final String? message;

  /// Label of the confirm button ("Löschen").
  final String confirmLabel;

  /// Label of the cancel button; defaults to "Abbrechen" / "Cancel".
  final String? cancelLabel;

  /// Optional hero icon above the title.
  final IconData? icon;

  /// Styles the confirm button in the error colour.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      // Title and message scroll together when space is short (landscape,
      // 200 % text); the actions stay visible.
      scrollable: true,
      icon: icon == null ? null : Icon(icon),
      title: Text(title),
      content: message == null ? null : Text(message!),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive ? ChronosButtonStyles.destructive(context) : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Shows a [ConfirmDialog] and resolves to `true` only if the user confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String? cancelLabel,
  IconData? icon,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      destructive: destructive,
    ),
  );
  return result ?? false;
}
