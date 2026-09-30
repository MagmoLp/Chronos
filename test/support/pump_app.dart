// Shared helpers for widget tests: pump a widget inside a fully themed and
// localised MaterialApp, switch screen sizes, and fail loudly on layout
// errors (RenderFlex overflow) and accessibility guideline violations.

import 'dart:async';
import 'dart:io';

import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical screen sizes (dp) every screen must handle without overflow.
abstract final class TestScreens {
  /// Small phone, portrait.
  static const Size phoneSmall = Size(360, 640);

  /// Large phone, portrait.
  static const Size phoneLarge = Size(412, 915);

  /// Small phone, landscape (compact height → NavigationRail).
  static const Size landscapeSmall = Size(800, 360);

  /// Large phone, landscape.
  static const Size landscapeLarge = Size(915, 412);

  /// 10" tablet, portrait.
  static const Size tabletPortrait = Size(800, 1280);

  /// 10" tablet, landscape.
  static const Size tabletLandscape = Size(1280, 800);

  /// All presets, keyed by a readable name.
  static const Map<String, Size> all = <String, Size>{
    '360x640': phoneSmall,
    '412x915': phoneLarge,
    '800x360': landscapeSmall,
    '915x412': landscapeLarge,
    '800x1280': tabletPortrait,
    '1280x800': tabletLandscape,
  };
}

/// One rendering configuration of a widget test.
@immutable
class TestConfig {
  /// Creates a configuration.
  const TestConfig({
    this.brightness = Brightness.light,
    this.locale = const Locale('de'),
    this.size = TestScreens.phoneSmall,
    this.textScale = 1.0,
  });

  /// Light or dark theme.
  final Brightness brightness;

  /// App locale.
  final Locale locale;

  /// Logical screen size.
  final Size size;

  /// Linear text scale factor (1.0 or 2.0 for 200 %).
  final double textScale;

  @override
  String toString() =>
      '${brightness.name}/${locale.languageCode}/${size.width.toInt()}x${size.height.toInt()}/'
      '${textScale}x';

  /// The full matrix: both themes × both locales × all screens × 1.0/2.0 text.
  static Iterable<TestConfig> matrix({
    Iterable<Size>? sizes,
    Iterable<double> textScales = const <double>[1.0, 2.0],
  }) sync* {
    for (final brightness in const <Brightness>[
      Brightness.light,
      Brightness.dark,
    ]) {
      for (final locale in AppLocalizations.supportedLocales) {
        for (final size in sizes ?? TestScreens.all.values) {
          for (final scale in textScales) {
            yield TestConfig(
              brightness: brightness,
              locale: locale,
              size: size,
              textScale: scale,
            );
          }
        }
      }
    }
  }
}

/// Sets the logical screen size (device pixel ratio 1) until the test ends.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Wraps [child] in a themed, localised [MaterialApp].
///
/// [use24HourFormat] defaults to the Android locale default (24 h for German,
/// 12 h for English).
Widget buildTestApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('de'),
  double textScale = 1.0,
  bool? use24HourFormat,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  bool wrapInScaffold = true,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ChronosTheme.light,
    darkTheme: ChronosTheme.dark,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        alwaysUse24HourFormat: use24HourFormat ?? locale.languageCode != 'en',
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
      ),
      child: app!,
    ),
    home: wrapInScaffold ? Scaffold(body: child) : child,
  );
}

/// Pumps [child] with the given configuration and fails the test if a layout
/// error (e.g. "A RenderFlex overflowed by 12 pixels") was reported.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  TestConfig config = const TestConfig(),
  bool? use24HourFormat,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  bool wrapInScaffold = true,
  bool settle = true,
}) async {
  setScreenSize(tester, config.size);
  await tester.pumpWidget(
    buildTestApp(
      child,
      brightness: config.brightness,
      locale: config.locale,
      textScale: config.textScale,
      use24HourFormat: use24HourFormat,
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
      wrapInScaffold: wrapInScaffold,
    ),
  );
  if (settle) await tester.pumpAndSettle();
  expectNoLayoutErrors(tester, config);
}

/// Fails with a readable message if the last frames reported an exception,
/// typically a RenderFlex overflow.
void expectNoLayoutErrors(WidgetTester tester, [Object? context]) {
  final error = tester.takeException();
  if (error != null) {
    fail(
      'Layout/render error${context == null ? '' : ' in $context'}:\n$error',
    );
  }
}

/// Runs the Android tap-target, labelled tap-target and (optionally) text
/// contrast guidelines on the current screen.
Future<void> expectMeetsAccessibilityGuidelines(
  WidgetTester tester, {
  bool textContrast = true,
}) async {
  final handle = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    if (textContrast) {
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
  } finally {
    handle.dispose();
  }
}

/// The [AppLocalizations] for [locale] (for building expected strings).
AppLocalizations l10nFor(Locale locale) => lookupAppLocalizations(locale);

bool _fontsLoaded = false;

/// Loads the real Roboto and Material Icons fonts from the Flutter SDK so
/// that text metrics are close to a device. Optional: without it tests use
/// the square "FlutterTest" glyphs, which are wider and therefore stricter
/// for overflow checks.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final file in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(
      Future<ByteData>.value(
        ByteData.sublistView(File('$dir/$file').readAsBytesSync()),
      ),
    );
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(
          File('$dir/MaterialIcons-Regular.otf').readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
  _fontsLoaded = true;
}

/// Records every [Timer] created inside [run], so tests can assert that no
/// timer is pending (e.g. while the app is in the background).
class TimerTracker {
  final List<Timer> _timers = <Timer>[];

  /// Number of timers created so far.
  int get created => _timers.length;

  /// Number of timers that have not fired or been cancelled yet.
  int get pending => _timers.where((t) => t.isActive).length;

  /// Runs [body] in a zone that records timer creation.
  Future<T> run<T>(Future<T> Function() body) {
    return runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          final timer = parent.createTimer(zone, duration, callback);
          _timers.add(timer);
          return timer;
        },
        createPeriodicTimer: (self, parent, zone, period, callback) {
          final timer = parent.createPeriodicTimer(zone, period, callback);
          _timers.add(timer);
          return timer;
        },
      ),
    );
  }
}
