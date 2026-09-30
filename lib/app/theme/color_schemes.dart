import 'package:flutter/material.dart';

/// Brand anchors of the "Navy Night / Sky Day" design system.
///
/// These are not part of the [ColorScheme]; they are used for the launcher
/// icon, splash screen and marketing surfaces. In-app UI must use the scheme
/// or `ChronosColors` instead.
abstract final class ChronosBrand {
  /// Icon background and splash accent.
  static const Color navy = Color(0xFF001F3F);

  /// Light-mode live state colour (also `ChronosColors.liveContainer`).
  static const Color sky = Color(0xFF87CEEB);

  /// Seed / signal blue (light-mode primary).
  static const Color signal = Color(0xFF14548C);

  /// Splash background in light mode (= light surface).
  static const Color splashDay = Color(0xFFF6F9FC);

  /// Splash background in dark mode (= dark surface).
  static const Color splashNight = Color(0xFF0B1320);
}

/// Light scheme "Sky Day" (docs/research/ux-audit.md, Design system §1).
///
/// All text pairs are at least 4.5:1 (verified by
/// `test/app/theme/contrast_test.dart`). The *fixed* roles are identical in
/// both schemes, as Material 3 requires.
const ColorScheme chronosLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF14548C),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFCFE8F7),
  onPrimaryContainer: Color(0xFF002A48),
  primaryFixed: Color(0xFFCFE8F7),
  primaryFixedDim: Color(0xFF9CCFF5),
  onPrimaryFixed: Color(0xFF002A48),
  onPrimaryFixedVariant: Color(0xFF0F3E63),
  secondary: Color(0xFF3F6178),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFD3E7F4),
  onSecondaryContainer: Color(0xFF0C2C40),
  secondaryFixed: Color(0xFFD3E7F4),
  secondaryFixedDim: Color(0xFFB5C9DA),
  onSecondaryFixed: Color(0xFF0C2C40),
  onSecondaryFixedVariant: Color(0xFF2A3E52),
  tertiary: Color(0xFF7A4A00),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFDDB0),
  onTertiaryContainer: Color(0xFF2B1800),
  tertiaryFixed: Color(0xFFFFDDB0),
  tertiaryFixedDim: Color(0xFFF3BD6E),
  onTertiaryFixed: Color(0xFF2B1800),
  onTertiaryFixedVariant: Color(0xFF5E3F00),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFF6F9FC),
  onSurface: Color(0xFF0F1A26),
  surfaceDim: Color(0xFFD3DEE8),
  surfaceBright: Color(0xFFF6F9FC),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFEFF4F9),
  surfaceContainer: Color(0xFFE9F0F6),
  surfaceContainerHigh: Color(0xFFE2EBF3),
  surfaceContainerHighest: Color(0xFFDBE5EF),
  onSurfaceVariant: Color(0xFF43505E),
  outline: Color(0xFF6E7B88),
  outlineVariant: Color(0xFFC3CFDA),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF25313D),
  onInverseSurface: Color(0xFFEAF1F8),
  inversePrimary: Color(0xFF9CCFF5),
  surfaceTint: Color(0xFF14548C),
);

/// Dark scheme "Navy Night" (docs/research/ux-audit.md, Design system §1).
const ColorScheme chronosDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF9CCFF5),
  onPrimary: Color(0xFF00324F),
  primaryContainer: Color(0xFF0F3E63),
  onPrimaryContainer: Color(0xFFCFE8F7),
  primaryFixed: Color(0xFFCFE8F7),
  primaryFixedDim: Color(0xFF9CCFF5),
  onPrimaryFixed: Color(0xFF002A48),
  onPrimaryFixedVariant: Color(0xFF0F3E63),
  secondary: Color(0xFFB5C9DA),
  onSecondary: Color(0xFF1F3344),
  secondaryContainer: Color(0xFF2A3E52),
  onSecondaryContainer: Color(0xFFD3E7F4),
  secondaryFixed: Color(0xFFD3E7F4),
  secondaryFixedDim: Color(0xFFB5C9DA),
  onSecondaryFixed: Color(0xFF0C2C40),
  onSecondaryFixedVariant: Color(0xFF2A3E52),
  tertiary: Color(0xFFF3BD6E),
  onTertiary: Color(0xFF432C00),
  tertiaryContainer: Color(0xFF5E3F00),
  onTertiaryContainer: Color(0xFFFFDDB0),
  tertiaryFixed: Color(0xFFFFDDB0),
  tertiaryFixedDim: Color(0xFFF3BD6E),
  onTertiaryFixed: Color(0xFF2B1800),
  onTertiaryFixedVariant: Color(0xFF5E3F00),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF0B1320),
  onSurface: Color(0xFFE3E9F0),
  surfaceDim: Color(0xFF0B1320),
  surfaceBright: Color(0xFF2B394B),
  surfaceContainerLowest: Color(0xFF070C14),
  surfaceContainerLow: Color(0xFF111B2A),
  surfaceContainer: Color(0xFF152131),
  surfaceContainerHigh: Color(0xFF1B2738),
  surfaceContainerHighest: Color(0xFF233142),
  onSurfaceVariant: Color(0xFFB9C6D3),
  outline: Color(0xFF8894A1),
  outlineVariant: Color(0xFF37475A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE3E9F0),
  onInverseSurface: Color(0xFF1C2733),
  inversePrimary: Color(0xFF14548C),
  surfaceTint: Color(0xFF9CCFF5),
);
