import 'package:flutter/material.dart';

import '../app/theme/theme.dart';
import '../core/format.dart';

/// Leading date badge of a shift row: day number over short weekday
/// ("30" / "Mi"), in a small rounded tonal box.
///
/// Announced as the full date ("Mittwoch, 30. September 2026").
class DateBlock extends StatelessWidget {
  /// Creates a date block for the local calendar [date].
  const DateBlock({super.key, required this.date, this.highlighted = false});

  /// Local date to show (time of day is ignored).
  final DateTime date;

  /// Emphasises the block (e.g. today) with the primary container colour.
  final bool highlighted;

  /// Minimum edge length (dp).
  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final background = highlighted
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = highlighted
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final secondary = highlighted
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      label: fmt.dateLong(date),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: size, minHeight: size),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: ChronosCorners.small,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChronosSpace.s4,
              vertical: ChronosSpace.s4,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    fmt.dayOfMonth(date),
                    style: text.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    fmt.weekdayShort(date),
                    style: text.labelSmall?.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
