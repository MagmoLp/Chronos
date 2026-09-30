import 'package:flutter/material.dart';

import '../app/theme/theme.dart';

/// Friendly placeholder for an empty screen or list: icon, title, optional
/// message and up to two actions (e.g. "Schicht starten" and
/// "Schicht nachtragen").
///
/// Scrolls when space is short (landscape, 200 % text), so it never
/// overflows.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
  });

  /// Illustrative icon shown in a tonal circle.
  final IconData icon;

  /// Short headline ("Noch keine Schichten").
  final String title;

  /// Optional explanation below the title.
  final String? message;

  /// Primary action, typically a [FilledButton].
  final Widget? action;

  /// Secondary action, typically a [TextButton].
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ChronosSpace.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(ChronosSpace.s16),
                    child: Icon(
                      icon,
                      size: 40,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ChronosSpace.s16),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: ChronosSpace.s8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: ChronosSpace.s24),
                action!,
              ],
              if (secondaryAction != null) ...<Widget>[
                const SizedBox(height: ChronosSpace.s8),
                secondaryAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
