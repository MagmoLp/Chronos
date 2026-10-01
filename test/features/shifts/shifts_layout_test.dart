import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/features/shifts/payout_sheet.dart';
import 'package:chronos/features/shifts/shift_editor.dart';
import 'package:chronos/features/shifts/shift_row.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shifts_test_utils.dart';

/// Two jobs, a running shift, long notes, tips, breaks, an overnight shift,
/// an overlap and two months.
Future<void> _seedRich(ProviderHarness h) async {
  final cafe = await h.job(name: 'Catering Müller & Söhne');
  final bar = await h.job(name: 'Eventhalle', centsPerHour: 1390);
  await addShift(
    h,
    cafe,
    LocalDate(2026, 9, 29),
    (h: 8, m: 0),
    (h: 16, m: 15),
    breakMinutes: 30,
    tipsCents: 12550,
    note: 'Hochzeit im Schlossgarten, danach noch Aufbau für Montag',
  );
  await addShift(h, bar, LocalDate(2026, 9, 29), (h: 15, m: 0), (h: 23, m: 0));
  await addShift(
    h,
    bar,
    LocalDate(2026, 9, 26),
    (h: 18, m: 0),
    (h: 2, m: 0),
    paid: true,
  );
  for (var day = 1; day <= 12; day++) {
    await addShift(
      h,
      cafe,
      LocalDate(2026, 8, day * 2),
      (h: 9, m: 0),
      (h: 17, m: 30),
      breakMinutes: 45,
      paid: day.isEven,
    );
  }
  await h
      .read(shiftRepositoryProvider)
      .start(cafe.id, startUtc: DateTime(2026, 9, 30, 17, 2).toUtc());
}

Future<void> _scrollThrough(WidgetTester tester, Object context) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 3; i++) {
    await tester.drag(scrollable, const Offset(0, -500), warnIfMissed: false);
    await tester.pumpAndSettle();
    expectNoLayoutErrors(tester, context);
  }
}

void main() {
  group('Shifts page has no layout errors', () {
    for (final config in TestConfig.matrix()) {
      testWidgets('with data, $config', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: _seedRich,
        );
        expect(find.byKey(ShiftsPageKeys.runningTile), findsOneWidget);
        await _scrollThrough(tester, config);
        await settle(tester);
      });

      testWidgets('empty, $config', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: (h) => h.job(),
        );
        expect(find.byType(FilledButton), findsOneWidget);
        await _scrollThrough(tester, config);
        await settle(tester);
      });
    }
  });

  group('Shift editor has no layout errors', () {
    for (final config in TestConfig.matrix()) {
      testWidgets('$config', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: _seedRich,
        );
        // At 200 % text on small screens the first row starts below the fold.
        for (
          var i = 0;
          find.byType(ShiftRow).evaluate().isEmpty && i < 10;
          i++
        ) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.byType(ShiftRow).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ShiftRow).first);
        await settle(tester);
        expectNoLayoutErrors(tester, config);
        expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);
        // The overlap with the other shift that day is listed.
        expect(find.byKey(ShiftEditorKeys.issues), findsOneWidget);
        await tester.ensureVisible(find.byKey(ShiftEditorKeys.duplicate));
        await tester.pumpAndSettle();
        expectNoLayoutErrors(tester, config);
        expect(find.byKey(ShiftEditorKeys.save).hitTestable(), findsOneWidget);

        // A new shift with the automatic next-day note.
        await tester.tap(find.byTooltip(l10nFor(config.locale).commonClose));
        await settle(tester);
        await tester.tap(find.byKey(ShiftsPageKeys.fab));
        await settle(tester);
        await typeInto(tester, ShiftEditorKeys.end, '0600');
        expectNoLayoutErrors(tester, config);
      });
    }
  });

  group('Payout sheet has no layout errors', () {
    for (final config in TestConfig.matrix()) {
      testWidgets('$config', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: _seedRich,
        );
        await tester.tap(find.byKey(ShiftsPageKeys.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.payments_outlined));
        await settle(tester);
        expectNoLayoutErrors(tester, config);
        expect(find.byKey(PayoutSheetKeys.sheet), findsOneWidget);
        await tester.ensureVisible(find.byKey(PayoutSheetKeys.note));
        await tester.pumpAndSettle();
        expectNoLayoutErrors(tester, config);
        expect(
          find.byKey(PayoutSheetKeys.submit).hitTestable(),
          findsOneWidget,
        );
      });
    }
  });

  group('accessibility guidelines', () {
    for (final brightness in Brightness.values) {
      final config = TestConfig(
        brightness: brightness,
        size: TestScreens.phoneLarge,
      );

      testWidgets('list, ${brightness.name}', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: _seedRich,
        );
        await expectMeetsAccessibilityGuidelines(tester);
        await settle(tester);
      });

      testWidgets('empty, ${brightness.name}', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: (h) => h.job(),
        );
        await expectMeetsAccessibilityGuidelines(tester);
      });

      testWidgets('editor, ${brightness.name}', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: _seedRich,
        );
        await tester.tap(find.byType(ShiftRow).first);
        await settle(tester);
        await expectMeetsAccessibilityGuidelines(tester);
        await settle(tester);
      });

      testWidgets('whole editor on a tablet, ${brightness.name}', (
        tester,
      ) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: TestConfig(
            brightness: brightness,
            size: TestScreens.tabletPortrait,
          ),
          seed: _seedRich,
        );
        await tester.tap(find.byType(ShiftRow).first);
        await settle(tester);
        expect(
          find.byKey(ShiftEditorKeys.duplicate).hitTestable(),
          findsOneWidget,
        );
        await expectMeetsAccessibilityGuidelines(tester);
        await settle(tester);
      });

      testWidgets('new shift with auto next day, ${brightness.name}', (
        tester,
      ) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: (h) async {
            final job = await h.job();
            await addShift(
              h,
              job,
              LocalDate(2026, 9, 1),
              (h: 8, m: 0),
              (h: 16, m: 0),
            );
          },
        );
        await tester.tap(find.byKey(ShiftsPageKeys.fab));
        await settle(tester);
        await typeInto(tester, ShiftEditorKeys.end, '0600');
        await expectMeetsAccessibilityGuidelines(tester);
        await settle(tester);
      });

      testWidgets('payout sheet, ${brightness.name}', (tester) async {
        await pumpFeature(
          tester,
          const ShiftsPage(),
          now: kShiftsNow,
          config: config,
          seed: _seedRich,
        );
        await tester.tap(find.byKey(ShiftsPageKeys.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.payments_outlined));
        await settle(tester);
        await expectMeetsAccessibilityGuidelines(tester);
        await settle(tester);
      });
    }
  });
}
