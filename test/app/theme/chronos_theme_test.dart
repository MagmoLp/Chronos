import 'package:chronos/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, brightness) in [
    ('light', ChronosTheme.light, Brightness.light),
    ('dark', ChronosTheme.dark, Brightness.dark),
  ]) {
    group('$name theme', () {
      final s = theme.colorScheme;

      test('is Material 3 with the matching brightness and scheme', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(s.brightness, brightness);
        expect(
          s,
          brightness == Brightness.light
              ? chronosLightScheme
              : chronosDarkScheme,
        );
        expect(theme.scaffoldBackgroundColor, s.surface);
      });

      test('carries both theme extensions', () {
        final colors = theme.extension<ChronosColors>();
        expect(
          colors,
          brightness == Brightness.light
              ? ChronosColors.light
              : ChronosColors.dark,
        );
        expect(theme.extension<ChronosTextStyles>(), isNotNull);
      });

      test('uses the system font with tabular figures on every role', () {
        final t = theme.textTheme;
        for (final style in [
          t.displayLarge,
          t.displaySmall,
          t.headlineSmall,
          t.titleLarge,
          t.titleMedium,
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.labelSmall,
        ]) {
          expect(
            style!.fontFeatures,
            contains(const FontFeature.tabularFigures()),
          );
          // No bundled font: the platform default family (Roboto on Android).
          expect(style.fontFamily, anyOf(isNull, 'Roboto'));
        }
        // Styles carry real sizes (component themes use them directly).
        expect(t.titleLarge!.fontSize, 22);
        expect(t.labelMedium!.fontSize, 12);
        expect(theme.appBarTheme.titleTextStyle!.fontSize, 22);
        expect(theme.dialogTheme.titleTextStyle!.fontSize, 24);
        final custom = theme.extension<ChronosTextStyles>()!;
        expect(custom.statValue.fontSize, 24);
        expect(custom.amountLarge.fontSize, 36);
        expect(custom.amount.fontSize, 16);
        expect(custom.bodyNumbers.fontSize, 14);
        expect(custom.moneyHero.fontSize, 57);
        expect(custom.moneyHero.fontWeight, FontWeight.w600);
        expect(custom.moneyHeroLarge.fontSize, 72);
        expect(custom.timer.fontSize, 22);
        expect(
          custom.amount.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      });

      test('component themes follow the design system', () {
        final card = theme.cardTheme;
        expect(card.elevation, 0);
        expect(card.color, s.surfaceContainerLow);
        expect(
          (card.shape! as RoundedRectangleBorder).borderRadius,
          ChronosCorners.large,
        );

        final filled = theme.filledButtonTheme.style!;
        expect(
          filled.minimumSize!.resolve(<WidgetState>{})!.height,
          greaterThanOrEqualTo(48),
        );

        expect(theme.navigationBarTheme.height, 80);
        expect(theme.navigationBarTheme.backgroundColor, s.surfaceContainer);
        expect(
          theme.navigationBarTheme.labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
        );
        expect(
          theme.navigationRailTheme.labelType,
          NavigationRailLabelType.all,
        );

        final sheet = theme.bottomSheetTheme;
        expect(sheet.showDragHandle, isTrue);
        expect(sheet.modalBackgroundColor, s.surfaceContainerLow);
        expect(
          (sheet.shape! as RoundedRectangleBorder).borderRadius,
          ChronosCorners.sheetTop,
        );

        expect(theme.dialogTheme.backgroundColor, s.surfaceContainerHigh);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
        expect(theme.snackBarTheme.backgroundColor, s.inverseSurface);
        expect(theme.snackBarTheme.actionTextColor, s.inversePrimary);

        final input = theme.inputDecorationTheme;
        expect(input.filled, isTrue);
        expect(input.fillColor, s.surfaceContainerHighest);
      });

      test('system bars are transparent with contrasting icons', () {
        final style = theme.appBarTheme.systemOverlayStyle!;
        expect(style.statusBarColor, Colors.transparent);
        expect(
          style.statusBarIconBrightness,
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
        );
        expect(
          style.systemNavigationBarIconBrightness,
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
        );
        expect(ChronosTheme.overlayStyleFor(brightness), style);
      });
    });
  }

  test('buildLightTheme/buildDarkTheme return the cached themes', () {
    expect(identical(buildLightTheme(), ChronosTheme.light), isTrue);
    expect(identical(buildDarkTheme(), ChronosTheme.dark), isTrue);
  });

  test('ChronosColors lerps every token and wraps job colours', () {
    final mid = ChronosColors.light.lerp(ChronosColors.dark, 0.5);
    expect(
      mid.success,
      Color.lerp(ChronosColors.light.success, ChronosColors.dark.success, 0.5),
    );
    expect(mid.jobPalette, hasLength(6));
    expect(
      ChronosColors.light.lerp(ChronosColors.dark, 1).liveContainer,
      ChronosColors.dark.liveContainer,
    );
    expect(ChronosColors.light.jobColor(7), ChronosColors.light.jobPalette[1]);
    expect(
      ChronosColors.light.copyWith(success: ChronosColors.dark.success).success,
      ChronosColors.dark.success,
    );
  });

  test('ChronosTextStyles lerp and copyWith', () {
    final a = ChronosTheme.light.extension<ChronosTextStyles>()!;
    final b = a.copyWith(timer: a.timer.copyWith(fontSize: 30));
    expect(a.lerp(b, 1).timer.fontSize, 30);
    expect(ChronosTextStyles.scaled(a.moneyHero, 0.5).fontSize, 28.5);
  });

  testWidgets('context shortcuts resolve the theme extensions', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: ChronosTheme.dark,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(ctx.chronosColors, ChronosColors.dark);
    expect(ctx.colorScheme, ChronosTheme.dark.colorScheme);
    expect(ctx.chronosText.moneyHero.fontSize, 57);
    expect(ctx.textTheme.bodyLarge!.fontFeatures, isNotEmpty);
  });

  testWidgets('ChronosColors.of falls back by brightness without extension', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(ChronosColors.of(ctx), ChronosColors.dark);
    expect(ChronosTextStyles.of(ctx).timer.fontSize, 22);
  });

  test('layout helpers', () {
    expect(ChronosLayout.marginFor(360), 16);
    expect(ChronosLayout.marginFor(700), 24);
  });
}
