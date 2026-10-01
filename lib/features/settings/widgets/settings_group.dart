import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Maximum width of settings content (single, centred column).
const double kSettingsMaxWidth = 640;

/// A scrollable settings body: centred column of at most
/// [kSettingsMaxWidth], with the screen margin and safe-area insets.
class SettingsListView extends StatelessWidget {
  /// Creates the list.
  const SettingsListView({
    super.key,
    required this.children,
    this.bottomPadding = ChronosSpace.s24,
  });

  /// Groups and other content.
  final List<Widget> children;

  /// Extra space at the end (e.g. room for a FAB).
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final margin = ChronosLayout.marginFor(width);
        final side = math.max(margin, (width - kSettingsMaxWidth) / 2);
        return ListView(
          padding: EdgeInsets.fromLTRB(
            side + safe.left,
            ChronosSpace.s8,
            side + safe.right,
            bottomPadding + safe.bottom,
          ),
          children: children,
        );
      },
    );
  }
}

/// A group of settings rows in the Android 16 style: a heading, then the
/// rows on tonal surfaces separated by 2 dp, with large outer and small
/// inner corners. No card nesting.
class SettingsGroup extends StatelessWidget {
  /// Creates a group.
  const SettingsGroup({super.key, this.title, required this.children});

  /// Heading (optional).
  final String? title;

  /// The rows (typically [ListTile]s).
  final List<Widget> children;

  static const Radius _outer = Radius.circular(ChronosRadius.largeIncreased);
  static const Radius _inner = Radius.circular(ChronosRadius.extraSmall);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = children.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ChronosSpace.s16,
              ChronosSpace.s24,
              ChronosSpace.s16,
              ChronosSpace.s8,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!,
                style: text.titleSmall?.copyWith(color: scheme.primary),
              ),
            ),
          )
        else
          const SizedBox(height: ChronosSpace.s16),
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
            child: Material(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? _outer : _inner,
                  bottom: i == count - 1 ? _outer : _inner,
                ),
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

/// A settings row with a title and a control below it (e.g. a
/// [SegmentedButton] that needs the full width).
class SettingsControlTile extends StatelessWidget {
  /// Creates the row.
  const SettingsControlTile({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
  });

  /// Title.
  final String title;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional explanation below the control.
  final String? subtitle;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChronosSpace.s16,
        ChronosSpace.s12,
        ChronosSpace.s16,
        ChronosSpace.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: ChronosSpace.s16),
              ],
              Expanded(
                child: Text(
                  title,
                  style: text.bodyLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: ChronosSpace.s12),
          child,
          if (subtitle != null) ...[
            const SizedBox(height: ChronosSpace.s8),
            Text(
              subtitle!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
