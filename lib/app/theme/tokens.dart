import 'package:flutter/material.dart';

/// Spacing tokens on the 4 dp grid (docs/research/ux-audit.md, §4).
abstract final class ChronosSpace {
  /// 4 dp.
  static const double s4 = 4;

  /// 8 dp: gap between related elements.
  static const double s8 = 8;

  /// 12 dp.
  static const double s12 = 12;

  /// 16 dp: card padding, compact screen margin.
  static const double s16 = 16;

  /// 24 dp: gap between sections, wide screen margin, hero padding.
  static const double s24 = 24;

  /// 32 dp.
  static const double s32 = 32;

  /// 48 dp.
  static const double s48 = 48;
}

/// Corner radius tokens (docs/research/ux-audit.md, §3).
abstract final class ChronosRadius {
  /// 4 dp: grouped list inner corners, badges, snackbar.
  static const double extraSmall = 4;

  /// 8 dp: chips, tooltips, date block.
  static const double small = 8;

  /// 12 dp: list cards, inputs, menus.
  static const double medium = 12;

  /// 16 dp: stat cards, FAB, the "Finish" button morph target.
  static const double large = 16;

  /// 20 dp: outer corners of grouped list sections.
  static const double largeIncreased = 20;

  /// 28 dp: hero card, dialogs, bottom-sheet top corners.
  static const double extraLarge = 28;
}

/// Ready-made [BorderRadius] values for the [ChronosRadius] tokens.
abstract final class ChronosCorners {
  /// [ChronosRadius.extraSmall] on all corners.
  static const BorderRadius extraSmall = BorderRadius.all(
    Radius.circular(ChronosRadius.extraSmall),
  );

  /// [ChronosRadius.small] on all corners.
  static const BorderRadius small = BorderRadius.all(
    Radius.circular(ChronosRadius.small),
  );

  /// [ChronosRadius.medium] on all corners.
  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(ChronosRadius.medium),
  );

  /// [ChronosRadius.large] on all corners.
  static const BorderRadius large = BorderRadius.all(
    Radius.circular(ChronosRadius.large),
  );

  /// [ChronosRadius.largeIncreased] on all corners.
  static const BorderRadius largeIncreased = BorderRadius.all(
    Radius.circular(ChronosRadius.largeIncreased),
  );

  /// [ChronosRadius.extraLarge] on all corners.
  static const BorderRadius extraLarge = BorderRadius.all(
    Radius.circular(ChronosRadius.extraLarge),
  );

  /// [ChronosRadius.extraLarge] on the top corners only (bottom sheets).
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(ChronosRadius.extraLarge),
  );
}

/// Sizes and window-size breakpoints (docs/research/ux-audit.md, §4 and
/// "Adaptive navigation").
abstract final class ChronosLayout {
  /// Below this width the window is *compact* (NavigationBar).
  static const double compactWidth = 600;

  /// From this width on the window is *expanded* (list-detail layouts).
  static const double expandedWidth = 840;

  /// Below this height the window is *compact height* (phone landscape):
  /// NavigationRail instead of a bottom bar.
  static const double compactHeight = 480;

  /// Maximum width of readable content, centred.
  static const double contentMaxWidth = 840;

  /// Maximum width of a single form/hero column on medium windows.
  static const double paneMaxWidth = 560;

  /// Screen margin on compact windows.
  static const double marginCompact = ChronosSpace.s16;

  /// Screen margin on medium and larger windows.
  static const double marginWide = ChronosSpace.s24;

  /// Minimum touch target.
  static const double minTapTarget = 48;

  /// Height of standard filled buttons (≥ the 48 dp touch target).
  static const double buttonHeight = 48;

  /// Height of primary actions (Start / Finish).
  static const double primaryButtonHeight = 56;

  /// Height of the hero action on Today.
  static const double heroButtonHeight = 64;

  /// NavigationBar height.
  static const double navigationBarHeight = 80;

  /// Collapsed NavigationRail width.
  static const double navigationRailWidth = 80;

  /// One-line list row.
  static const double listRow1 = 56;

  /// Two-line list row (shift row).
  static const double listRow2 = 72;

  /// Three-line list row.
  static const double listRow3 = 88;

  /// Screen margin for a window of the given [width].
  static double marginFor(double width) =>
      width < compactWidth ? marginCompact : marginWide;
}

/// Motion tokens (docs/research/ux-audit.md, §6).
abstract final class ChronosMotion {
  /// Rolling digit slide.
  static const Duration digitRoll = Duration(milliseconds: 250);

  /// Chips, checkboxes, shape morph.
  static const Duration short = Durations.short4;

  /// Hero container change (idle ↔ running).
  static const Duration medium = Durations.medium2;

  /// Sheets and default transitions.
  static const Duration long = Durations.medium4;

  /// Entering elements.
  static const Curve enter = Easing.emphasizedDecelerate;

  /// Exiting elements.
  static const Curve exit = Easing.emphasizedAccelerate;

  /// In-place changes.
  static const Curve standard = Easing.standard;
}
