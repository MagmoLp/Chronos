// Shared test helpers for the Chronos reproduction suite.
//
// - Stubs the flutter_local_notifications Android method channel and records
//   every call (method + arguments) so tests can count notification posts.
// - Boots the app exactly like lib/main.dart does (same provider wiring) but
//   without runApp, so tests can pump ChronosApp.
// - Optionally loads the real Roboto + MaterialIcons fonts shipped with the
//   Flutter SDK so text metrics (and therefore overflow pixel counts) are
//   close to a real Android device instead of the square "FlutterTest" glyphs.
// - Collects every FlutterError (e.g. RenderFlex overflows) without failing the
//   test so the numbers can be reported.

import 'dart:io';

import 'package:chronos/main.dart';
import 'package:chronos/providers/settings_provider.dart';
import 'package:chronos/providers/timer_provider.dart';
import 'package:chronos/providers/work_entries_provider.dart';
import 'package:chronos/services/notification_service.dart';
import 'package:chronos/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notifChannel = MethodChannel('dexterous.com/flutter/local_notifications');

/// Every call that reached the (stubbed) native notification plugin.
final List<MethodCall> notificationCalls = [];

int countNotif(String method) =>
    notificationCalls.where((c) => c.method == method).length;

/// Registers the Android implementation of flutter_local_notifications (the
/// generated plugin registrant is not run under flutter_test) and installs a
/// method-channel stub that records every call.
void installNotificationStub() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  notificationCalls.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(notifChannel, (call) async {
    notificationCalls.add(call);
    switch (call.method) {
      case 'initialize':
      case 'requestNotificationsPermission':
        return true;
      case 'getNotificationAppLaunchDetails':
        return null;
      default:
        return null;
    }
  });
}

bool _fontsLoaded = false;

/// Loads Roboto (all weights we need) and MaterialIcons from the SDK cache.
Future<void> loadRealFonts() async {
  if (_fontsLoaded) return;
  final root = Platform.environment['FLUTTER_ROOT'] ??
      (throw StateError('FLUTTER_ROOT is not set (flutter test normally sets it)'));
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in [
    'Roboto-Thin.ttf',
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]) {
    final bytes = File('$dir/$f').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await roboto.load();
  // lib/screens/home_screen.dart:137 uses fontFamily 'RobotoMono', which is NOT
  // bundled (pubspec has no fonts section). On Android an unknown family falls
  // back to the system default (Roboto), so emulate that fallback here.
  final mono = FontLoader('RobotoMono');
  for (final f in ['Roboto-Light.ttf', 'Roboto-Regular.ttf']) {
    mono.addFont(Future.value(ByteData.view(File('$dir/$f').readAsBytesSync().buffer)));
  }
  await mono.load();
  final icons = FontLoader('MaterialIcons');
  icons.addFont(Future.value(ByteData.view(
      File('$dir/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icons.load();
  _fontsLoaded = true;
}

class AppHarness {
  AppHarness(this.settings, this.entries, this.timer);
  final SettingsProvider settings;
  final WorkEntriesProvider entries;
  final TimerProvider timer;

  Widget get app => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: entries),
          ChangeNotifierProvider.value(value: timer),
        ],
        child: const ChronosApp(),
      );

  /// Stops the periodic timer so flutter_test does not complain about pending
  /// timers at the end of the test.
  Future<void> dispose(WidgetTester tester) async {
    if (timer.isRunning) {
      await timer.stop();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }
}

/// Mirrors lib/main.dart:14-45 (minus runApp).
Future<AppHarness> bootApp(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  // StorageService is a singleton that caches its SharedPreferences instance;
  // refresh it so each test sees its own mock store.
  await StorageService().init();
  final settings = SettingsProvider();
  await settings.loadSettings();
  final entries = WorkEntriesProvider();
  await entries.loadEntries();
  await NotificationService().init();
  final timer = TimerProvider();
  timer.setHourlyWage(settings.hourlyWage);
  await timer.loadActiveSession();
  return AppHarness(settings, entries, timer);
}

String settingsJson({String language = 'german', String theme = 'dark', double wage = 15.0}) =>
    '{"language":"$language","theme":"$theme","hourlyWage":$wage}';

/// A few realistic entries (JSON string for prefs key 'work_entries').
String sampleEntriesJson() {
  final now = DateTime.now();
  final d0 = DateTime(now.year, now.month, now.day);
  final list = <Map<String, Object>>[];
  for (var i = 0; i < 6; i++) {
    final day = d0.subtract(Duration(days: i * 9));
    final start = day.add(const Duration(hours: 8));
    final end = day.add(Duration(hours: 16, minutes: i * 15));
    list.add({
      'id': 'e$i',
      'date': day.toIso8601String(),
      'startTime': start.toIso8601String(),
      'endTime': end.toIso8601String(),
      'isPaid': i.isOdd,
    });
  }
  // overnight shift
  final ds = d0.subtract(const Duration(days: 3));
  list.add({
    'id': 'night',
    'date': ds.toIso8601String(),
    'startTime': ds.add(const Duration(hours: 22)).toIso8601String(),
    'endTime': ds.add(const Duration(hours: 30)).toIso8601String(),
    'isPaid': false,
  });
  return _encode(list);
}

String _encode(List<Map<String, Object>> list) {
  final b = StringBuffer('[');
  for (var i = 0; i < list.length; i++) {
    if (i > 0) b.write(',');
    b.write('{');
    var first = true;
    list[i].forEach((k, v) {
      if (!first) b.write(',');
      first = false;
      b.write('"$k":');
      b.write(v is String ? '"$v"' : '$v');
    });
    b.write('}');
  }
  b.write(']');
  return b.toString();
}

/// Sets the logical screen size (dpr 3.0) and optional text scale.
void setScreen(WidgetTester tester, Size logical,
    {double textScale = 1.0, double dpr = 3.0, FakeViewPadding? padding}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  if (padding != null) tester.view.padding = padding;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
}

void resetScreen(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.view.resetPadding();
  tester.view.resetViewInsets();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
  tester.platformDispatcher.clearPlatformBrightnessTestValue();
}

class CapturedError {
  CapturedError(this.summary, this.full);
  final String summary;
  final String full;
}

/// Captures FlutterErrors while [body] runs. Always restores the handler.
/// Errors are stringified immediately (while the offending elements are still
/// active) - stringifying later triggers "deactivated widget's ancestor".
Future<List<CapturedError>> captureErrors(Future<void> Function() body) async {
  final errors = <CapturedError>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    String full;
    try {
      full = d.toString();
    } catch (e) {
      full = d.exceptionAsString();
    }
    errors.add(CapturedError(_summarize(d, full), full));
  };
  try {
    await body();
  } finally {
    FlutterError.onError = old;
  }
  return errors;
}

/// One-line summary: "A RenderFlex overflowed by 123 pixels on the bottom.  @ lib/screens/home_screen.dart:57:18"
String _summarize(FlutterErrorDetails d, String full) {
  final msg = d.exceptionAsString().split('\n').first.trim();
  final m = RegExp(r'The relevant error-causing widget was:\s*\n\s*\S+\s*\n\s*(\S+)').firstMatch(full);
  var where = '';
  if (m != null) {
    where = m.group(1)!.trim().replaceAll(RegExp(r'^.*?file://\S*?/lib/'), 'lib/');
  }
  return where.isEmpty ? msg : '$msg  @ $where';
}

/// Text of every painted paragraph (includes AppBar titles, hints, buttons,
/// dialogs, snackbars ...).
List<String> visibleTexts(WidgetTester tester) {
  final out = <String>[];
  final seen = Set<RenderObject>.identity();
  for (final r in tester.allRenderObjects) {
    if (!seen.add(r)) continue;
    if (r is RenderParagraph) {
      final t = r.text.toPlainText().trim();
      if (t.isNotEmpty) out.add(t);
    } else if (r is RenderEditable) {
      final t = r.text?.toPlainText().trim() ?? '';
      if (t.isNotEmpty) out.add('[input] $t');
    }
  }
  return out;
}
