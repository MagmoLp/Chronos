import 'dart:async';

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/provider_harness.dart';
import 'fakes.dart';
import 'pump_app.dart';

export '../fixtures/provider_harness.dart';
export 'fakes.dart';
export 'pump_app.dart';

/// Default "now" for feature tests: Wednesday 30 Sep 2026, 10:00 in Berlin.
final DateTime kFeatureNow = DateTime.utc(2026, 9, 30, 8);

/// A pumped feature with its data harness and platform fakes.
class FeatureHarness {
  FeatureHarness._(this.data, this.notifications, this.share);

  /// Database, clock, settings store, side-effects recorder, container.
  final ProviderHarness data;

  /// Recorded notification calls.
  final FakeNotificationService notifications;

  /// Recorded shares.
  final FakeShareService share;

  /// The provider container used by the widget tree.
  ProviderContainer get container => data.container;

  /// Reads a provider.
  T read<T>(ProviderListenable<T> provider) => data.read(provider);
}

/// Pumps [child] (a page or any widget) inside a themed, localised
/// MaterialApp backed by a real in-memory database, a test clock at [now],
/// in-memory settings and fake platform services.
///
/// [seed] runs before the first frame (create jobs, shifts, settings);
/// use `h.read(...)` to reach repositories/controllers. Pass
/// `wrapInScaffold: true` for widgets that are not pages.
Future<FeatureHarness> pumpFeature(
  WidgetTester tester,
  Widget child, {
  DateTime? now,
  TestConfig config = const TestConfig(),
  FutureOr<void> Function(ProviderHarness h)? seed,
  List<Override> overrides = const [],
  LegacyRawData legacy = const LegacyRawData(),
  bool wrapInScaffold = false,
  bool? use24HourFormat,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  bool settle = true,
}) async {
  final notifications = FakeNotificationService();
  final share = FakeShareService(tempDir());
  final harness = ProviderHarness(
    now ?? kFeatureNow,
    legacy: legacy,
    overrides: [
      notificationServiceProvider.overrideWithValue(notifications),
      shareServiceProvider.overrideWithValue(share),
      appInfoServiceProvider.overrideWithValue(fakeAppInfoService()),
      ...overrides,
    ],
  );
  if (seed != null) await seed(harness);
  setScreenSize(tester, config.size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: buildTestApp(
        child,
        brightness: config.brightness,
        locale: config.locale,
        textScale: config.textScale,
        use24HourFormat: use24HourFormat,
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
        wrapInScaffold: wrapInScaffold,
      ),
    ),
  );
  if (settle) await settleData(tester);
  expectNoLayoutErrors(tester, config);
  return FeatureHarness._(harness, notifications, share);
}

/// Lets database streams deliver and the UI settle (use after actions that
/// write to the database).
Future<void> settleData(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
