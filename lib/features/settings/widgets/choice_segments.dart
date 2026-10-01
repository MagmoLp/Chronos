import 'package:flutter/material.dart';

/// One option of [ChoiceSegments].
@immutable
class ChoiceSegment<T> {
  /// Creates an option.
  const ChoiceSegment({required this.value, required this.label, this.icon});

  /// The value selected by this option.
  final T value;

  /// Visible label.
  final String label;

  /// Optional icon.
  final IconData? icon;
}

/// A single-choice [SegmentedButton] that stacks its segments vertically
/// when the labels do not fit side by side (narrow windows, 200 % text), so
/// labels are never cut or broken mid-word.
class ChoiceSegments<T> extends StatelessWidget {
  /// Creates the control.
  const ChoiceSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = true,
  });

  /// The options.
  final List<ChoiceSegment<T>> segments;

  /// The selected value.
  final T selected;

  /// Called with the newly selected value; `null` disables the control.
  final ValueChanged<T>? onChanged;

  /// Whether the horizontal button fills the available width.
  final bool expand;

  /// Horizontal space a segment needs besides its label: padding (2 × 12)
  /// and border.
  static const double _padding = 2 * 12 + 2;

  /// The selection check mark (or a segment icon) plus its gap.
  static const double _icon = 18 + 8;

  /// Whether segments with [labels] fit side by side into [maxWidth]
  /// (with room for the check mark unless [withIcon] is false).
  static bool labelsFit(
    BuildContext context,
    List<String> labels,
    double maxWidth, {
    bool withIcon = true,
  }) {
    if (!maxWidth.isFinite) return true;
    final style =
        Theme.of(context).segmentedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{}) ??
        Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final perSegment = maxWidth / labels.length;
    final chrome = _padding + (withIcon ? _icon : 0);
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final needed = painter.width + chrome;
      painter.dispose();
      if (needed > perSegment) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labels = [for (final s in segments) s.label];
        final hasIcons = segments.any((s) => s.icon != null);
        final width = constraints.maxWidth;
        // Side by side with check mark → side by side without it (the
        // selection stays visible through the fill) → stacked.
        final withCheck = labelsFit(context, labels, width);
        final horizontal =
            withCheck ||
            (!hasIcons && labelsFit(context, labels, width, withIcon: false));
        final button = SegmentedButton<T>(
          direction: horizontal ? Axis.horizontal : Axis.vertical,
          showSelectedIcon: withCheck || !horizontal,
          expandedInsets: horizontal && expand ? EdgeInsets.zero : null,
          segments: [
            for (final s in segments)
              ButtonSegment<T>(
                value: s.value,
                label: Text(s.label),
                icon: s.icon == null ? null : Icon(s.icon),
              ),
          ],
          selected: {selected},
          onSelectionChanged: onChanged == null
              ? null
              : (values) => onChanged!(values.single),
        );
        if (horizontal || !width.isFinite) return button;
        // A tight width makes the stacked segments span the full width.
        return SizedBox(width: width, child: button);
      },
    );
  }
}
