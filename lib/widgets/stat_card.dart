import 'package:flutter/material.dart';

import '../app/theme/theme.dart';

/// Key figure on a tonal card: label, large value, optional caption
/// ("Stunden · 42,5 h"). Read as one unit by screen readers.
///
/// A top-level card; never place it inside another card.
class StatCard extends StatelessWidget {
  /// Creates a stat card.
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.valueColor,
    this.onTap,
  });

  /// What the number is ("Verdient").
  final String label;

  /// The formatted number ("637,50 €").
  final String value;

  /// Optional supporting line below the value.
  final String? caption;

  /// Optional icon before the label.
  final IconData? icon;

  /// Colour of the value; defaults to onSurface.
  final Color? valueColor;

  /// Makes the whole card tappable (e.g. "Offen" → record payout).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final styles = ChronosTextStyles.of(context);

    final content = Padding(
      padding: const EdgeInsets.all(ChronosSpace.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: ChronosSpace.s8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ChronosSpace.s8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: styles.statValue.copyWith(
                color: valueColor ?? scheme.onSurface,
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: ChronosSpace.s4),
            Text(
              caption!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: Card(
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}
