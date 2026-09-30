import 'dart:async';
import 'dart:convert';

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/features/review/review_page.dart';
import 'package:chronos/platform/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/startup/app_harness.dart';
import '../../fixtures/legacy_v1.dart';

final LegacyRawData _legacy = LegacyRawData(
  workEntries: LegacyV1.workEntries,
  appSettings: LegacyV1.settingsGerman,
);

/// Harness after a v1 migration: review items and failed entries exist.
Future<AppHarness> _migrated() async {
  final h = AppHarness(legacy: _legacy);
  await h.read(legacyMigratorProvider).run(defaultJobName: 'Mein Job');
  return h;
}

Future<AppHarness> _pump(
  WidgetTester tester, {
  AppHarness? harness,
  TestConfig config = const TestConfig(),
}) async {
  final h = harness ?? await _migrated();
  await pumpOnHarness(tester, h, const ReviewPage(), config: config);
  return h;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settleApp(tester);
}

void main() {
  testWidgets('lists the shifts to check with their reasons', (tester) async {
    final h = await _pump(tester);
    final items = await h.read(reviewRepositoryProvider).getItems();
    expect(items, isNotEmpty);

    expect(find.text('Einträge prüfen'), findsOneWidget);
    expect(find.textContaining('nichts automatisch geändert'), findsOneWidget);
    expect(
      find.text('Zu prüfende Schichten (${items.length})'),
      findsOneWidget,
    );
    expect(find.text('Passt so'), findsNWidgets(items.length));
    expect(find.text('Bearbeiten'), findsNWidgets(items.length));
    // Reasons from the v1 fixture.
    expect(
      find.text('Genau 23 oder 24 Stunden – das Ende stimmt vielleicht nicht'),
      findsOneWidget,
    );
    expect(find.text('Doppelter Eintrag aus der alten Version'), findsWidgets);
    expect(find.text('Gleiche Zeiten wie eine andere Schicht'), findsWidgets);
    expect(
      find.text('Am Tag der Zeitumstellung – prüf die Uhrzeiten'),
      findsWidgets,
    );
  });

  testWidgets('"Passt so" removes one entry', (tester) async {
    final h = await _pump(tester);
    final before = await h.read(reviewRepositoryProvider).getItems();
    await _tap(tester, find.text('Passt so').first);
    final after = await h.read(reviewRepositoryProvider).getItems();
    expect(after, hasLength(before.length - 1));
    expect(find.text('Passt so'), findsNWidgets(after.length));
  });

  testWidgets('"Alle als geprüft markieren" asks, then clears the list', (
    tester,
  ) async {
    final h = await _pump(tester);
    final count = (await h.read(reviewRepositoryProvider).getItems()).length;
    await _tap(tester, find.text('Alle als geprüft markieren'));
    expect(find.text('$count Einträge als geprüft markieren?'), findsOneWidget);

    // Cancel keeps everything.
    await tester.tap(find.text('Abbrechen'));
    await settleApp(tester);
    expect(await h.read(reviewRepositoryProvider).getItems(), hasLength(count));

    await _tap(tester, find.text('Alle als geprüft markieren'));
    await tester.tap(
      find.widgetWithText(FilledButton, 'Alle als geprüft markieren'),
    );
    await settleApp(tester);
    expect(await h.read(reviewRepositoryProvider).getItems(), isEmpty);
    expect(find.text('Passt so'), findsNothing);
    // The failed entries stay visible.
    expect(find.text('Nicht übernommen (${LegacyV1.broken})'), findsOneWidget);
  });

  testWidgets('failed v1 entries: reason, origin and raw data', (tester) async {
    await _pump(tester);
    expect(find.text('Nicht übernommen (${LegacyV1.broken})'), findsOneWidget);
    expect(find.text('Die Startzeit ist unlesbar'), findsOneWidget);
    expect(find.text('Die Endzeit fehlt'), findsOneWidget);
    expect(find.text('Der Eintrag ist unlesbar'), findsOneWidget);
    expect(find.text('Das Ende liegt nicht nach dem Start'), findsOneWidget);
    expect(find.text('work_entries[9]'), findsOneWidget);
    expect(find.textContaining('kaputt'), findsOneWidget);
  });

  testWidgets('"Rohdaten teilen" shares the raw v1 data', (tester) async {
    final h = await _pump(tester);
    await _tap(tester, find.text('Rohdaten teilen'));
    final shared = h.share.sharedFiles.single;
    expect(shared.mimeType, ShareMimeTypes.json);
    final json = jsonDecode(
      h.share.savedTexts[ReviewPage.rawDataFileName]!,
    ) as Map<String, Object?>;
    expect(json['work_entries'], LegacyV1.workEntries);
  });

  testWidgets('a failed share is reported', (tester) async {
    final h = await _pump(tester);
    h.share.failNextSave = true;
    await _tap(tester, find.text('Rohdaten teilen'));
    expect(
      find.text('Die Datei konnte nicht erstellt werden.'),
      findsOneWidget,
    );
  });

  testWidgets('a shift deleted meanwhile drops off the list', (tester) async {
    final h = await _pump(tester);
    final items = await h.read(reviewRepositoryProvider).getItems();
    expect(find.text('Passt so'), findsNWidgets(items.length));
    await h.read(shiftRepositoryProvider).softDelete([items.first.shiftId]);
    await settleApp(tester);
    expect(find.text('Passt so'), findsNWidgets(items.length - 1));
    expect(find.text('Diese Schicht wurde gelöscht.'), findsNothing);
  });

  testWidgets('"Bearbeiten" opens the editor', (tester) async {
    await _pump(tester);
    await _tap(tester, find.text('Bearbeiten').first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing to check: empty state', (tester) async {
    await _pump(tester, harness: AppHarness());
    expect(find.text('Alles geprüft'), findsOneWidget);
    expect(find.text('Passt so'), findsNothing);
  });

  testWidgets('opens as its own page with a back button', (tester) async {
    final h = await _migrated();
    await pumpOnHarness(
      tester,
      h,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => unawaited(openReviewPage(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settleApp(tester);
    expect(find.byType(ReviewPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settleApp(tester);
    expect(find.byType(ReviewPage), findsNothing);
  });

  group('layout', () {
    testWidgets('no overflow in every configuration', (tester) async {
      for (final config in TestConfig.matrix()) {
        await _pump(tester, config: config);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('empty state without overflow', (tester) async {
      for (final config in TestConfig.matrix(textScales: const [2.0])) {
        await _pump(tester, harness: AppHarness(), config: config);
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
