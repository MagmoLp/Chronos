import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chronos_colors.dart';
import 'chronos_text_styles.dart';
import 'color_schemes.dart';
import 'tokens.dart';

/// Builds the Material 3 themes of the "Navy Night / Sky Day" design system.
///
/// ```dart
/// MaterialApp(
///   theme: ChronosTheme.light,
///   darkTheme: ChronosTheme.dark,
///   themeMode: themeMode,
/// )
/// ```
///
/// Uses the system font (Roboto on Android) with tabular figures on every
/// text role, tonal surfaces instead of shadows and the component themes from
/// docs/research/ux-audit.md, Design system §7.
abstract final class ChronosTheme {
  /// The light theme ("Sky Day").
  static final ThemeData light = build(chronosLightScheme, ChronosColors.light);

  /// The dark theme ("Navy Night").
  static final ThemeData dark = build(chronosDarkScheme, ChronosColors.dark);

  /// Status and navigation bar style for a screen of the given [brightness]:
  /// transparent bars (edge-to-edge) with icons that contrast the surface.
  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  /// Builds a complete theme from a [scheme] and matching semantic [colors].
  ///
  /// Public so that a future "wallpaper colours" option can pass a dynamic
  /// scheme while keeping the component themes.
  static ThemeData build(ColorScheme scheme, ChronosColors colors) {
    // Complete styles (geometry + colour) so component themes and custom
    // roles carry real sizes; ThemeData alone only adds geometry lazily in
    // Theme.of().
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: scheme,
    );
    final colored = scheme.brightness == Brightness.dark
        ? typography.white
        : typography.black;
    final textTheme = _withTabularFigures(
      typography.englishLike.merge(colored),
    );
    final chronosText = ChronosTextStyles.fromTextTheme(textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      typography: typography,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[colors, chronosText],
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        systemOverlayStyle: overlayStyleFor(scheme.brightness),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: ChronosLayout.navigationBarHeight,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        elevation: 0,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        minWidth: ChronosLayout.navigationRailWidth,
        groupAlignment: -1,
        selectedIconTheme: IconThemeData(
          size: 24,
          color: scheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: scheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.large),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, ChronosLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: ChronosSpace.s24),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, ChronosLayout.minTapTarget),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.small),
        labelStyle: textTheme.labelLarge,
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
        iconTheme: IconThemeData(size: 18, color: scheme.onSurfaceVariant),
      ),
      inputDecorationTheme: _inputTheme(scheme, textTheme),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        tileColor: Colors.transparent,
        selectedColor: scheme.onSecondaryContainer,
        selectedTileColor: scheme.secondaryContainer,
        titleTextStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsetsDirectional.only(
          start: ChronosSpace.s16,
          end: ChronosSpace.s16,
        ),
        minVerticalPadding: ChronosSpace.s8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant,
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: ChronosCorners.sheetTop,
        ),
        constraints: const BoxConstraints(maxWidth: 640),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: ChronosCorners.extraLarge,
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        closeIconColor: scheme.onInverseSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: ChronosCorners.extraSmall,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.large),
        extendedTextStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: ChronosCorners.medium,
        ),
        textStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: ChronosCorners.medium),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: ChronosCorners.small,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
    );
  }

  static InputDecorationThemeData _inputTheme(
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    const radius = BorderRadius.vertical(
      top: Radius.circular(ChronosRadius.medium),
    );
    UnderlineInputBorder border(Color color, [double width = 1]) =>
        UnderlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: border(scheme.onSurfaceVariant),
      enabledBorder: border(scheme.onSurfaceVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      disabledBorder: border(scheme.onSurface.withValues(alpha: 0.38)),
      helperMaxLines: 3,
      errorMaxLines: 3,
      hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  static TextTheme _withTabularFigures(TextTheme t) {
    TextStyle? f(TextStyle? s) => s?.copyWith(fontFeatures: tabularFigures);
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }
}

/// Light theme (same as [ChronosTheme.light]).
ThemeData buildLightTheme() => ChronosTheme.light;

/// Dark theme (same as [ChronosTheme.dark]).
ThemeData buildDarkTheme() => ChronosTheme.dark;

/// Button styles for the few emphasised actions. Merge them into a button via
/// its `style:` parameter; everything else comes from the theme.
abstract final class ChronosButtonStyles {
  /// Primary action (Finish, Save in sheets): 56 dp tall.
  static ButtonStyle primary(BuildContext context) => FilledButton.styleFrom(
    minimumSize: const Size(64, ChronosLayout.primaryButtonHeight),
    textStyle: Theme.of(context).textTheme.titleMedium,
  );

  /// Hero action (Start shift on Today): 64 dp tall, full width if the
  /// parent allows it.
  static ButtonStyle hero(BuildContext context) => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(ChronosLayout.heroButtonHeight),
    textStyle: Theme.of(context).textTheme.titleMedium,
  );

  /// Destructive filled button (e.g. confirm "Delete" in a dialog).
  static ButtonStyle destructive(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
    );
  }
}

/// Shortcuts to the design-system values of the ambient theme.
extension ChronosThemeContext on BuildContext {
  /// `Theme.of(this).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// `Theme.of(this).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Semantic colours ([ChronosColors]).
  ChronosColors get chronosColors => ChronosColors.of(this);

  /// Custom type roles ([ChronosTextStyles]).
  ChronosTextStyles get chronosText => ChronosTextStyles.of(this);
}
