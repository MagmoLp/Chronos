import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/features/shifts/payout_sheet.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shifts_test_utils.dart';

const String _nb = '\u00A0';

/// Café (15 €/h): open 28 Sep 8 h, open 1 Sep 4 h (break 30 → 3:30 h),
/// paid 25 Sep. Bar (12 €/h): open 27 Sep 5 h.
Future<({Job cafe, Job bar})> _seed(ProviderHarness h) async {
  final cafe = await h.job(name: 'Café');
  final bar = await h.job(name: 'Bar', centsPerHour: 1200);
  await addShift(h, cafe, LocalDate(2026, 9, 28), (h: 8, m: 0), (h: 16, m: 0));
  await addShift(
    h,
    cafe,
    LocalDate(2026, 9, 1),
    (h: 8, m: 0),
    (h: 12, m: 0),
    breakMinutes: 30,
  );
  await addShift(
    h,
    cafe,
    LocalDate(2026, 9, 25),
    (h: 8, m: 0),
    (h: 12, m: 0),
    paid: true,
  );
  await addShift(h, bar, LocalDate(2026, 9, 27), (h: 17, m: 0), (h: 22, m: 0));
  return (cafe: cafe, bar: bar);
}

/// Pumps the Shifts page and opens the payout sheet from the menu.
Future<FeatureHarness> _open(
  WidgetTester tester, {
  Future<void> Function(ProviderHarness h)? seed,
  Locale locale = const Locale('de'),
}) async {
  final f = await pumpFeature(
    tester,
    const ShiftsPage(),
    now: kShiftsNow,
    config: TestConfig(size: TestScreens.phoneLarge, locale: locale),
    seed: seed ?? _seed,
  );
  await tester.tap(find.byKey(ShiftsPageKeys.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.payments_outlined));
  await settle(tester);
  expect(find.byKey(PayoutSheetKeys.sheet), findsOneWidget);
  return f;
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

String _received(WidgetTester tester) => tester
    .widget<EditableText>(inputOf(PayoutSheetKeys.received))
    .controller
    .text;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  testWidgets('previews all open shifts of all jobs up to today', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Auszahlung erfassen'), findsOneWidget);
    // 8 h + 3:30 h + 5 h = 16,5 h; 120 + 52,50 + 60 = 232,50 €.
    expect(_text(tester, PayoutSheetKeys.summary), '3 Schichten · 16,5 h');
    expect(_text(tester, PayoutSheetKeys.expected), '232,50$_nb€');
    expect(_received(tester), '232,50');
    expect(_text(tester, PayoutSheetKeys.difference), '0,00$_nb€');
    expect(find.text('3 Schichten als bezahlt markieren'), findsOneWidget);
    // Dates default to today.
    expect(find.text('Mi., 30. Sept. 2026'), findsNWidgets(2));
  });

  testWidgets('one job only', (tester) async {
    await _open(tester);
    await _tap(tester, find.byKey(PayoutSheetKeys.job));
    await tester.tap(find.text('Bar').last);
    await settle(tester);
    expect(_text(tester, PayoutSheetKeys.summary), '1 Schicht · 5 h');
    expect(_text(tester, PayoutSheetKeys.expected), '60,00$_nb€');
    expect(_received(tester), '60,00');
    expect(find.text('1 Schicht als bezahlt markieren'), findsOneWidget);
  });

  testWidgets('"up to and including" limits the shifts', (tester) async {
    await _open(tester);
    await _tap(tester, find.byKey(PayoutSheetKeys.until));
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(_text(tester, PayoutSheetKeys.summary), '1 Schicht · 3,5 h');
    expect(_text(tester, PayoutSheetKeys.expected), '52,50$_nb€');
  });

  testWidgets('received differing from expected shows the difference', (
    tester,
  ) async {
    await _open(tester);
    await typeInto(tester, PayoutSheetKeys.received, '200');
    expect(_text(tester, PayoutSheetKeys.difference), '-32,50$_nb€');
    await typeInto(tester, PayoutSheetKeys.received, '250,5');
    expect(_text(tester, PayoutSheetKeys.difference), '+18,00$_nb€');
  });

  testWidgets('marks the shifts paid, records the payout, and undo reverts', (
    tester,
  ) async {
    final f = await _open(tester);
    await typeInto(tester, PayoutSheetKeys.received, '230');
    await typeInto(tester, PayoutSheetKeys.note, 'Lohn September');
    await _tap(tester, find.byKey(PayoutSheetKeys.submit));

    expect(find.byKey(PayoutSheetKeys.sheet), findsNothing);
    expect(find.text('3 Schichten als bezahlt markiert'), findsOneWidget);
    final shifts = await doneShifts(f);
    expect(shifts.where((s) => !s.isPaid), isEmpty);
    final payouts = await f.read(payoutRepositoryProvider).getPayouts();
    expect(payouts, hasLength(1));
    final payout = payouts.single;
    expect(payout.expectedCents, 23250);
    expect(payout.receivedCents, 23000);
    expect(payout.jobId, isNull);
    expect(payout.untilDate, kToday);
    expect(payout.paidOn, kToday);
    expect(payout.note, 'Lohn September');
    expect(shifts.where((s) => s.payoutId == payout.id), hasLength(3));

    await tester.tap(find.text('Rückgängig'));
    await settle(tester);
    expect((await doneShifts(f)).where((s) => !s.isPaid), hasLength(3));
    expect(await f.read(payoutRepositoryProvider).getPayouts(), isEmpty);
  });

  testWidgets('received amount follows the expected sum until edited', (
    tester,
  ) async {
    final f = await _open(tester);
    await _tap(tester, find.byKey(PayoutSheetKeys.job));
    await tester.tap(find.text('Café').last);
    await settle(tester);
    expect(_received(tester), '172,50');
    await _tap(tester, find.byKey(PayoutSheetKeys.submit));
    final payout = (await f.read(payoutRepositoryProvider).getPayouts()).single;
    expect(payout.receivedCents, 17250);
    expect(payout.jobId, isNotNull);
    // Bar stays open.
    expect((await doneShifts(f)).where((s) => !s.isPaid), hasLength(1));
  });

  testWidgets('without open shifts shows a hint instead of the button', (
    tester,
  ) async {
    await _open(
      tester,
      seed: (h) async {
        final job = await h.job();
        await addShift(
          h,
          job,
          LocalDate(2026, 9, 28),
          (h: 8, m: 0),
          (h: 16, m: 0),
          paid: true,
        );
      },
    );
    expect(find.byKey(PayoutSheetKeys.nothingOpen), findsOneWidget);
    expect(
      find.text('Bis zu diesem Datum gibt es keine offenen Schichten.'),
      findsOneWidget,
    );
    expect(find.byKey(PayoutSheetKeys.submit), findsNothing);
    // One job: no job selector.
    expect(find.byKey(PayoutSheetKeys.job), findsNothing);
  });

  testWidgets('showPayoutSheet preselects a job', (tester) async {
    late Job bar;
    await pumpFeature(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showPayoutSheet(context, jobId: bar.id),
            child: const Text('open'),
          ),
        ),
      ),
      now: kShiftsNow,
      wrapInScaffold: true,
      seed: (h) async => bar = (await _seed(h)).bar,
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(_text(tester, PayoutSheetKeys.summary), '1 Schicht · 5 h');
  });

  testWidgets('English texts', (tester) async {
    await _open(tester, locale: const Locale('en'));
    expect(find.text('Record payout'), findsOneWidget);
    expect(_text(tester, PayoutSheetKeys.summary), '3 shifts · 16.5 h');
    expect(find.text('Mark 3 shifts as paid'), findsOneWidget);
  });
}
