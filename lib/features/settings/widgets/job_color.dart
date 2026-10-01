import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Stored job colours are the ARGB values of the *light* job palette
/// (`ChronosColors.light.jobPalette`). These helpers map them to the palette
/// of the current theme, so a job keeps "its" colour in dark mode.
abstract final class JobColors {
  /// Palette index of the stored [argb], or `null` for a colour outside the
  /// palette (e.g. from an old backup).
  static int? indexOf(int argb) {
    final palette = ChronosColors.light.jobPalette;
    for (var i = 0; i < palette.length; i++) {
      if (palette[i].toARGB32() == argb) return i;
    }
    return null;
  }

  /// The value to store for palette entry [index].
  static int argbFor(int index) =>
      ChronosColors.light.jobColor(index).toARGB32();

  /// The colour to paint for the stored [argb] in the current theme.
  static Color resolve(BuildContext context, int argb) {
    final index = indexOf(argb);
    return index == null ? Color(argb) : ChronosColors.of(context).jobColor(index);
  }
}

/// A small filled circle in a job's colour (decorative; pair it with the
/// job name).
class JobColorDot extends StatelessWidget {
  /// Creates the dot.
  const JobColorDot({super.key, required this.colorArgb, this.size = 12});

  /// Stored job colour.
  final int colorArgb;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: JobColors.resolve(context, colorArgb),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
