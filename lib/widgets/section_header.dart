import 'package:flutter/material.dart';

import '../app/theme/theme.dart';

/// Heading of a list section or month group, marked as a semantic header so
/// screen-reader users can jump between sections.
///
/// ```dart
/// SectionHeader('September 2026', subtitle: '42,5 h · 637,50 € · 318,75 € offen')
/// ```
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      ChronosSpace.s16,
      ChronosSpace.s16,
      ChronosSpace.s16,
      ChronosSpace.s8,
    ),
  });

  /// Heading text, sentence case (titleSmall).
  final String title;

  /// Optional summary line below the heading (bodySmall).
  final String? subtitle;

  /// Optional trailing widget, e.g. a [TextButton].
  final Widget? trailing;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: text.titleSmall?.copyWith(color: scheme.onSurface),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: ChronosSpace.s8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
