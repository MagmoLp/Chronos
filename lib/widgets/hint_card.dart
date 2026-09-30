import 'package:flutter/material.dart';

import '../app/theme/theme.dart';
import '../l10n/app_localizations.dart';

/// Tone of a [HintCard].
enum HintTone {
  /// Neutral information (secondary container).
  info,

  /// Something needs attention (amber warning container).
  warning,
}

/// Inline banner for conditional hints ("3 übernommene Einträge prüfen",
/// "Benachrichtigungen sind aus"), with an optional action and dismiss button.
class HintCard extends StatelessWidget {
  /// Creates a hint card.
  const HintCard({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = HintTone.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  }) : assert(
         actionLabel == null || onAction != null,
         'An action label needs onAction.',
       );

  /// Body text.
  final String message;

  /// Optional bold first line.
  final String? title;

  /// Leading icon; defaults to info / warning icons by [tone].
  final IconData? icon;

  /// Colour tone.
  final HintTone tone;

  /// Label of the action button (e.g. "Einstellungen öffnen").
  final String? actionLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  /// Shows a close button when set.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = ChronosColors.of(context);
    final text = Theme.of(context).textTheme;
    final (background, foreground) = switch (tone) {
      HintTone.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      HintTone.warning => (colors.warningContainer, colors.onWarningContainer),
    };
    final leading =
        icon ??
        (tone == HintTone.warning
            ? Icons.warning_amber_rounded
            : Icons.info_outline);

    return Material(
      color: background,
      shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.large),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          ChronosSpace.s16,
          ChronosSpace.s12,
          ChronosSpace.s4,
          ChronosSpace.s4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(leading, color: foreground),
            ),
            const SizedBox(width: ChronosSpace.s12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: actionLabel == null ? ChronosSpace.s8 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (title != null)
                      Text(
                        title!,
                        style: text.titleSmall?.copyWith(color: foreground),
                      ),
                    Text(
                      message,
                      style: text.bodyMedium?.copyWith(color: foreground),
                    ),
                    if (actionLabel != null)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: foreground,
                          ),
                          child: Text(actionLabel!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                color: foreground,
                tooltip: AppLocalizations.of(context).commonDismiss,
                icon: const Icon(Icons.close),
              )
            else
              const SizedBox(width: ChronosSpace.s12),
          ],
        ),
      ),
    );
  }
}
