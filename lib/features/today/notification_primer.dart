import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

/// Explains the lock-screen notification before the system permission
/// dialog (first "Schicht starten"). Resolves to `true` if the user wants
/// to allow notifications, `false` for "Nicht jetzt" or when dismissed.
Future<bool> showNotificationPrimer(BuildContext context) async {
  final allow = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const NotificationPrimerSheet(),
  );
  return allow ?? false;
}

/// Content of the notification permission explanation.
class NotificationPrimerSheet extends StatelessWidget {
  /// Creates the sheet.
  const NotificationPrimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ChronosSpace.s24,
        0,
        ChronosSpace.s24,
        ChronosSpace.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.notifications_active_outlined,
            size: 32,
            color: scheme.primary,
          ),
          const SizedBox(height: ChronosSpace.s16),
          Semantics(
            header: true,
            child: Text(
              l10n.todayPrimerTitle,
              textAlign: TextAlign.center,
              style: text.headlineSmall,
            ),
          ),
          const SizedBox(height: ChronosSpace.s12),
          Text(
            l10n.todayPrimerBody,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: ChronosSpace.s24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ChronosButtonStyles.primary(context),
            child: Text(l10n.todayPrimerAllow, textAlign: TextAlign.center),
          ),
          const SizedBox(height: ChronosSpace.s8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.todayPrimerLater),
          ),
        ],
      ),
    );
  }
}
