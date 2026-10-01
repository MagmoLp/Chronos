import 'dart:convert';

import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/features/recovery/recovery_screen.dart';
import 'package:chronos/platform/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/startup/app_harness.dart';
import '../../fixtures/legacy_v1.dart';

final LegacyRawData _legacy = LegacyRawData(
  workEntries: LegacyV1.workEntries,
  appSettings: LegacyV1.settingsGerman,
);

Future<AppHarness> _pump(
  WidgetTester tester, {
  TestConfig config = const TestConfig(),
  LegacyRawData legacy = const LegacyRawData(),
}) async {
  final h = AppHarness(legacy: legacy);
  await pumpOnHarness(
    tester,
    h,
    RecoveryScreen(error: StateError('database disk image is malformed')),
    config: config,
  );
  return h;
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await settleApp(tester);
}

void main() {
  testWidgets('explains the situation and offers the three actions', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Chronos konnte nicht starten'), findsOneWidget);
    expect(find.textContaining('Es wurde nichts gelöscht'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Rohdaten teilen'), findsOneWidget);
    expect(find.text('Fehlerbericht teilen'), findsOneWidget);
  });

  testWidgets('"Rohdaten teilen" shares the raw v1 values as JSON', (
    tester,
  ) async {
    final h = await _pump(tester, legacy: _legacy);
    await _tapButton(tester, 'Rohdaten teilen');

    final shared = h.share.sharedFiles.single;
    expect(shared.mimeType, ShareMimeTypes.json);
    expect(shared.subject, 'Chronos-Rohdaten');
    expect(shared.path, endsWith(RecoveryScreen.rawDataFileName));
    final json = jsonDecode(
      h.share.savedTexts[RecoveryScreen.rawDataFileName]!,
    ) as Map<String, Object?>;
    expect(json['work_entries'], LegacyV1.workEntries);
    expect(json['app_settings'], LegacyV1.settingsGerman);
  });

  testWidgets('"Fehlerbericht teilen" shares the error log', (tester) async {
    final h = AppHarness();
    await h.errorLog.record(
      StateError('boom'),
      StackTrace.current,
      context: 'bootstrap',
    );
    await pumpOnHarness(tester, h, RecoveryScreen(error: StateError('boom')));
    await _tapButton(tester, 'Fehlerbericht teilen');

    final shared = h.share.sharedFiles.single;
    expect(shared.mimeType, ShareMimeTypes.text);
    expect(shared.subject, 'Chronos-Fehlerbericht');
    final report = h.share.savedTexts[RecoveryScreen.errorReportFileName]!;
    expect(report, contains('bootstrap'));
    expect(report, contains('boom'));
  });

  testWidgets('an empty log still reports the start error', (tester) async {
    final h = await _pump(tester);
    await _tapButton(tester, 'Fehlerbericht teilen');
    expect(
      h.share.savedTexts[RecoveryScreen.errorReportFileName],
      contains('database disk image is malformed'),
    );
  });

  testWidgets('a failed share says so and can be tried again', (tester) async {
    final h = await _pump(tester, legacy: _legacy);
    h.share.failNextSave = true;
    await _tapButton(tester, 'Rohdaten teilen');
    expect(
      find.text('Die Datei konnte nicht erstellt werden.'),
      findsOneWidget,
    );
    expect(h.share.sharedFiles, isEmpty);
    expect(await h.errorLog.read(), contains('recovery.share'));

    await _tapButton(tester, 'Rohdaten teilen');
    expect(h.share.sharedFiles, hasLength(1));
  });

  testWidgets('unreadable v1 data: the share fails gracefully', (tester) async {
    final h = await _pump(tester);
    h.legacySource.fail = true;
    await _tapButton(tester, 'Rohdaten teilen');
    expect(
      find.text('Die Datei konnte nicht erstellt werden.'),
      findsOneWidget,
    );
    expect(h.share.sharedFiles, isEmpty);
  });

  testWidgets('technical details on demand', (tester) async {
    await _pump(tester);
    expect(find.textContaining('malformed'), findsNothing);
    await _tapButton(tester, 'Technische Details');
    expect(find.textContaining('malformed'), findsOneWidget);
  });

  testWidgets('English', (tester) async {
    await _pump(tester, config: const TestConfig(locale: Locale('en')));
    expect(find.text("Chronos couldn't start"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Share raw data'), findsOneWidget);
    expect(find.text('Share error report'), findsOneWidget);
  });

  group('layout', () {
    testWidgets('no overflow in every configuration', (tester) async {
      for (final config in TestConfig.matrix()) {
        await _pump(tester, config: config);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    for (final brightness in Brightness.values) {
      testWidgets('accessibility guidelines (${brightness.name})', (
        tester,
      ) async {
        await _pump(tester, config: TestConfig(brightness: brightness));
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }
  });
}
