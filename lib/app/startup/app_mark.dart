import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The Chronos mark (hourglass on a tonal disc) for the splash screen and
/// onboarding. Decorative: excluded from semantics.
class AppMark extends StatelessWidget {
  /// Creates the mark with the given edge length.
  const AppMark({super.key, this.size = 96});

  /// Diameter in dp.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hourglass_top_rounded,
            size: size * 0.5,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
