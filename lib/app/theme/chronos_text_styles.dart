import 'package:flutter/material.dart';

/// Tabular (fixed-width) digits so numbers never jitter horizontally.
const List<FontFeature> tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

/// App-specific type roles on top of the Material 3 [TextTheme]
/// (docs/research/ux-audit.md, Design system §2). All roles use tabular
/// figures. Colours are inherited from the text theme (onSurface); widgets
/// override them for coloured surfaces (e.g. `ChronosColors.onLive`).
@immutable
class ChronosTextStyles extends ThemeExtension<ChronosTextStyles> {
  /// Creates the set of custom type roles.
  const ChronosTextStyles({
    required this.moneyHero,
    required this.moneyHeroLarge,
    required this.amountLarge,
    required this.statValue,
    required this.timer,
    required this.amount,
    required this.bodyNumbers,
    required this.smallNumbers,
  });

  /// Derives the custom roles from a Material 3 [textTheme] (system font).
  factory ChronosTextStyles.fromTextTheme(TextTheme textTheme) {
    TextStyle base(TextStyle? style) =>
        (style ?? const TextStyle()).copyWith(fontFeatures: tabularFigures);
    return ChronosTextStyles(
      moneyHero: base(textTheme.displayLarge).copyWith(
        fontSize: 57,
        height: 64 / 57,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      moneyHeroLarge: base(textTheme.displayLarge).copyWith(
        fontSize: 72,
        height: 80 / 72,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      amountLarge: base(textTheme.displaySmall)
          .copyWith(fontWeight: FontWeight.w500),
      statValue: base(textTheme.headlineSmall)
          .copyWith(fontWeight: FontWeight.w500),
      timer: base(textTheme.titleLarge)
          .copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w500),
      amount: base(textTheme.titleMedium).copyWith(fontWeight: FontWeight.w500),
      bodyNumbers: base(textTheme.bodyMedium),
      smallNumbers: base(textTheme.bodySmall),
    );
  }

  /// Running-shift amount, 57/64 sp, w600 (compact windows).
  final TextStyle moneyHero;

  /// Running-shift amount, 72/80 sp, w600 (expanded windows).
  final TextStyle moneyHeroLarge;

  /// Idle hero (unpaid balance), displaySmall 36/44 w500.
  final TextStyle amountLarge;

  /// Stat card values and sheet totals, headlineSmall 24/32 w500.
  final TextStyle statValue;

  /// Live timer "3:11:42", 22/28 w500.
  final TextStyle timer;

  /// Trailing amounts in list rows, titleMedium 16/24 w500.
  final TextStyle amount;

  /// Numbers inside body text, bodyMedium.
  final TextStyle bodyNumbers;

  /// Small numbers (month summaries, chart labels), bodySmall.
  final TextStyle smallNumbers;

  /// The [ChronosTextStyles] of the ambient theme (derived on the fly if the
  /// theme has no extension).
  static ChronosTextStyles of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ChronosTextStyles>() ??
        ChronosTextStyles.fromTextTheme(theme.textTheme);
  }

  @override
  ChronosTextStyles copyWith({
    TextStyle? moneyHero,
    TextStyle? moneyHeroLarge,
    TextStyle? amountLarge,
    TextStyle? statValue,
    TextStyle? timer,
    TextStyle? amount,
    TextStyle? bodyNumbers,
    TextStyle? smallNumbers,
  }) {
    return ChronosTextStyles(
      moneyHero: moneyHero ?? this.moneyHero,
      moneyHeroLarge: moneyHeroLarge ?? this.moneyHeroLarge,
      amountLarge: amountLarge ?? this.amountLarge,
      statValue: statValue ?? this.statValue,
      timer: timer ?? this.timer,
      amount: amount ?? this.amount,
      bodyNumbers: bodyNumbers ?? this.bodyNumbers,
      smallNumbers: smallNumbers ?? this.smallNumbers,
    );
  }

  @override
  ChronosTextStyles lerp(ChronosTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return ChronosTextStyles(
      moneyHero: l(moneyHero, other.moneyHero),
      moneyHeroLarge: l(moneyHeroLarge, other.moneyHeroLarge),
      amountLarge: l(amountLarge, other.amountLarge),
      statValue: l(statValue, other.statValue),
      timer: l(timer, other.timer),
      amount: l(amount, other.amount),
      bodyNumbers: l(bodyNumbers, other.bodyNumbers),
      smallNumbers: l(smallNumbers, other.smallNumbers),
    );
  }

  /// Scales [style] to [factor] of its size (e.g. cents at 0.6× the hero).
  static TextStyle scaled(TextStyle style, double factor) =>
      style.copyWith(fontSize: (style.fontSize ?? 14) * factor);
}
