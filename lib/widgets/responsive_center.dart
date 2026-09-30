import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/theme.dart';

/// Centres content horizontally at most [maxWidth] wide (840 dp by default)
/// with the window-size margin (16 dp compact, 24 dp wider).
class ResponsiveCenter extends StatelessWidget {
  /// Creates a centred, width-limited box around [child].
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = ChronosLayout.contentMaxWidth,
    this.applyMargin = true,
    this.alignment = Alignment.topCenter,
  });

  /// The content.
  final Widget child;

  /// Maximum content width in dp (excluding margins).
  final double maxWidth;

  /// Whether to add the horizontal screen margin.
  final bool applyMargin;

  /// Vertical placement of the content.
  final AlignmentGeometry alignment;

  /// Horizontal padding that centres content of at most [maxWidth] in a
  /// viewport of [width], never less than the screen margin.
  static double horizontalPaddingFor(
    double width, {
    double maxWidth = ChronosLayout.contentMaxWidth,
    bool applyMargin = true,
  }) {
    final margin = applyMargin ? ChronosLayout.marginFor(width) : 0.0;
    return math.max(margin, (width - maxWidth) / 2);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final margin = applyMargin ? ChronosLayout.marginFor(width) : 0.0;
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth + 2 * margin),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Sliver version of [ResponsiveCenter] for [CustomScrollView]s.
class SliverResponsiveCenter extends StatelessWidget {
  /// Pads [sliver] so its content is centred and at most [maxWidth] wide.
  const SliverResponsiveCenter({
    super.key,
    required this.sliver,
    this.maxWidth = ChronosLayout.contentMaxWidth,
    this.applyMargin = true,
  });

  /// The content sliver.
  final Widget sliver;

  /// Maximum content width in dp.
  final double maxWidth;

  /// Whether to keep at least the screen margin.
  final bool applyMargin;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final padding = ResponsiveCenter.horizontalPaddingFor(
          constraints.crossAxisExtent,
          maxWidth: maxWidth,
          applyMargin: applyMargin,
        );
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: sliver,
        );
      },
    );
  }
}
