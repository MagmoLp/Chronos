import 'package:flutter/material.dart';

/// Semantic colours that Material 3's [ColorScheme] does not have.
///
/// Obtain with `ChronosColors.of(context)` (or `context.chronosColors`).
/// Values follow docs/research/ux-audit.md, Design system §1.
@immutable
class ChronosColors extends ThemeExtension<ChronosColors> {
  /// Creates a full set of semantic colours.
  const ChronosColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.liveContainer,
    required this.onLive,
    required this.liveIndicator,
    required this.open,
    required this.onOpen,
    required this.openContainer,
    required this.onOpenContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.jobPalette,
  });

  /// "Sky Day" semantic colours.
  static const ChronosColors light = ChronosColors(
    success: Color(0xFF1B6B3A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFC4EFCF),
    onSuccessContainer: Color(0xFF002110),
    liveContainer: Color(0xFF87CEEB),
    onLive: Color(0xFF002A48),
    liveIndicator: Color(0xFF14548C),
    open: Color(0xFF7A4A00),
    onOpen: Color(0xFFFFFFFF),
    openContainer: Color(0xFFFFDDB0),
    onOpenContainer: Color(0xFF2B1800),
    warning: Color(0xFF7A4A00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFDDB0),
    onWarningContainer: Color(0xFF2B1800),
    jobPalette: <Color>[
      Color(0xFF1F6FB2),
      Color(0xFF00796B),
      Color(0xFF9A6200),
      Color(0xFFB03A5B),
      Color(0xFF6A4FB3),
      Color(0xFF2E7D32),
    ],
  );

  /// "Navy Night" semantic colours.
  static const ChronosColors dark = ChronosColors(
    success: Color(0xFF8FD8A5),
    onSuccess: Color(0xFF00391C),
    successContainer: Color(0xFF0E5130),
    onSuccessContainer: Color(0xFFC4EFCF),
    liveContainer: Color(0xFF0F3E63),
    onLive: Color(0xFFCFE8F7),
    liveIndicator: Color(0xFF9CCFF5),
    open: Color(0xFFF3BD6E),
    onOpen: Color(0xFF432C00),
    openContainer: Color(0xFF5E3F00),
    onOpenContainer: Color(0xFFFFDDB0),
    warning: Color(0xFFF3BD6E),
    onWarning: Color(0xFF432C00),
    warningContainer: Color(0xFF5E3F00),
    onWarningContainer: Color(0xFFFFDDB0),
    jobPalette: <Color>[
      Color(0xFF8CC4F2),
      Color(0xFF6FD6C6),
      Color(0xFFF3BD6E),
      Color(0xFFF4A7BC),
      Color(0xFFC8B6FF),
      Color(0xFF9ED79A),
    ],
  );

  /// Number of job colours; job colour indices are taken modulo this value.
  static const int jobColorCount = 6;

  /// "Paid" icon, payout confirmations.
  final Color success;

  /// Content on [success].
  final Color onSuccess;

  /// Background of the "paid" chip.
  final Color successContainer;

  /// Content on [successContainer].
  final Color onSuccessContainer;

  /// Background of the running-shift hero card.
  final Color liveContainer;

  /// Text and icons on [liveContainer].
  final Color onLive;

  /// Static "recording" dot (never pulsing).
  final Color liveIndicator;

  /// "Unpaid / open" status (amber).
  final Color open;

  /// Content on [open].
  final Color onOpen;

  /// Background of the "unpaid" chip.
  final Color openContainer;

  /// Content on [openContainer].
  final Color onOpenContainer;

  /// Warnings (e.g. monthly cap at 80 %), amber.
  final Color warning;

  /// Content on [warning].
  final Color onWarning;

  /// Background of warning banners.
  final Color warningContainer;

  /// Content on [warningContainer].
  final Color onWarningContainer;

  /// Six job colours for job dots and chart series (≥ 3:1 against surface).
  final List<Color> jobPalette;

  /// Colour of the job with palette index [index] (wraps around).
  Color jobColor(int index) => jobPalette[index % jobPalette.length];

  /// The [ChronosColors] of the ambient theme.
  ///
  /// Falls back to [light] / [dark] (by brightness) when the theme has no
  /// extension, so widgets never crash in bare test harnesses.
  static ChronosColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ChronosColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  ChronosColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? liveContainer,
    Color? onLive,
    Color? liveIndicator,
    Color? open,
    Color? onOpen,
    Color? openContainer,
    Color? onOpenContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    List<Color>? jobPalette,
  }) {
    return ChronosColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      liveContainer: liveContainer ?? this.liveContainer,
      onLive: onLive ?? this.onLive,
      liveIndicator: liveIndicator ?? this.liveIndicator,
      open: open ?? this.open,
      onOpen: onOpen ?? this.onOpen,
      openContainer: openContainer ?? this.openContainer,
      onOpenContainer: onOpenContainer ?? this.onOpenContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      jobPalette: jobPalette ?? this.jobPalette,
    );
  }

  @override
  ChronosColors lerp(ChronosColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    final palette = <Color>[
      for (var i = 0; i < jobPalette.length; i++)
        i < other.jobPalette.length
            ? l(jobPalette[i], other.jobPalette[i])
            : jobPalette[i],
    ];
    return ChronosColors(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      liveContainer: l(liveContainer, other.liveContainer),
      onLive: l(onLive, other.onLive),
      liveIndicator: l(liveIndicator, other.liveIndicator),
      open: l(open, other.open),
      onOpen: l(onOpen, other.onOpen),
      openContainer: l(openContainer, other.openContainer),
      onOpenContainer: l(onOpenContainer, other.onOpenContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      jobPalette: palette,
    );
  }
}
