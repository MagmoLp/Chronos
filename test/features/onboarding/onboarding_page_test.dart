import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/features/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/startup/app_harness.dart';

Future<AppHarness> _pump(
  WidgetTester tester, {
  TestConfig config = const TestConfig(),
}) async {
  final h = AppHarness();
  await pumpOnHarness(tester, h, const OnboardingPage(), config: config);
  return h;
}

Future<void> _toJobStep(
  WidgetTester tester, {
  String label = 'Los geht’s',
}) async {
  final next = find.text(label);
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _done(WidgetTester tester, {String label = 'Fertig'}) async {
  final done = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(done);
  await tester.tap(done);
  await settleApp(tester);
}

void main() {
  group('flow', () {
    testWidgets('welcome → job step and back', (tester) async {
      await _pump(tester);
      expect(
        find.text('Schichten erfassen. Lohn live wachsen sehen.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Schritt 1 von 2'), findsOneWidget);

      await _toJobStep(tester);
      expect(find.text('Dein Job'), findsOneWidget);
      expect(find.bySemanticsLabel('Schritt 2 von 2'), findsOneWidget);
      expect(_field('Name (optional)'), findsOneWidget);
      expect(_field('Stundenlohn'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Dein Job'), findsNothing);
      expect(find.text('Los geht’s'), findsOneWidget);
    });

    testWidgets('system back on the job step returns to the welcome step', (
      tester,
    ) async {
      await _pump(tester);
      await _toJobStep(tester);
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.text('Los geht’s'), findsOneWidget);
    });

    testWidgets('the hourly rate is required', (tester) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await _done(tester);
      expect(find.text('Bitte gib einen Wert ein'), findsOneWidget);
      expect(await h.read(jobRepositoryProvider).getJobs(), isEmpty);
    });

    testWidgets('0 is not a wage', (tester) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await tester.enterText(_field('Stundenlohn'), '0');
      await _done(tester);
      expect(find.text('Der Betrag muss größer als 0 sein'), findsOneWidget);
      expect(await h.read(jobRepositoryProvider).getJobs(), isEmpty);
    });

    testWidgets('comma: name and rate are saved, onboarding done', (
      tester,
    ) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await tester.enterText(_field('Name (optional)'), '  Catering Müller ');
      await tester.enterText(_field('Stundenlohn'), '13,90');
      await _done(tester);

      final jobs = await h.read(jobRepositoryProvider).getJobs();
      expect(jobs.single.name, 'Catering Müller');
      final rate = await h
          .read(jobRepositoryProvider)
          .rateFor(jobs.single.id, h.read(clockProvider).today());
      expect(rate, 1390);
      expect(h.read(settingsProvider).onboardingDone, isTrue);
    });

    testWidgets('dot as separator and the default name (English)', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        config: const TestConfig(locale: Locale('en')),
      );
      await _toJobStep(tester, label: 'Get started');
      await tester.enterText(_field('Hourly rate'), '12.5');
      await _done(tester, label: 'Done');
      final jobs = await h.read(jobRepositoryProvider).getJobs();
      expect(jobs.single.name, 'My job');
      final rate = await h
          .read(jobRepositoryProvider)
          .rateFor(jobs.single.id, h.read(clockProvider).today());
      expect(rate, 1250);
    });

    testWidgets('German default name "Mein Job"; dot also works', (
      tester,
    ) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await tester.enterText(_field('Stundenlohn'), '15.00');
      await _done(tester);
      final jobs = await h.read(jobRepositoryProvider).getJobs();
      expect(jobs.single.name, 'Mein Job');
    });

    testWidgets('an unusual wage asks first; "Ändern" keeps editing', (
      tester,
    ) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await tester.enterText(_field('Stundenlohn'), '1250');
      await _done(tester);
      expect(find.text('1.250,00\u00A0€/h – stimmt das?'), findsOneWidget);
      expect(
        find.text('Das ist ungewöhnlich hoch für einen Stundenlohn.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ändern'));
      await settleApp(tester);
      expect(await h.read(jobRepositoryProvider).getJobs(), isEmpty);
      expect(find.text('Dein Job'), findsOneWidget);
    });

    testWidgets('an unusual wage can be confirmed', (tester) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await tester.enterText(_field('Stundenlohn'), '3');
      await _done(tester);
      expect(
        find.text('Das ist ungewöhnlich niedrig für einen Stundenlohn.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ja, stimmt'));
      await settleApp(tester);
      final jobs = await h.read(jobRepositoryProvider).getJobs();
      expect(jobs, hasLength(1));
    });

    testWidgets('a double tap creates one job', (tester) async {
      final h = await _pump(tester);
      await _toJobStep(tester);
      await tester.enterText(_field('Stundenlohn'), '14');
      final done = find.widgetWithText(FilledButton, 'Fertig');
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pump();
      await tester.tap(done, warnIfMissed: false);
      await settleApp(tester);
      expect(await h.read(jobRepositoryProvider).getJobs(), hasLength(1));
    });

    testWidgets(
      'keyboard: "next" on the name moves to the rate, "done" saves',
      (tester) async {
        final h = await _pump(tester);
        await _toJobStep(tester);
        await tester.tap(_field('Name (optional)'));
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        await tester.enterText(_field('Stundenlohn'), '14,50');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settleApp(tester);
        expect(await h.read(jobRepositoryProvider).getJobs(), hasLength(1));
      },
    );
  });

  group('layout', () {
    testWidgets('both steps without overflow in every configuration', (
      tester,
    ) async {
      for (final config in TestConfig.matrix()) {
        await _pump(tester, config: config);
        await _toJobStep(
          tester,
          label: config.locale.languageCode == 'de'
              ? 'Los geht’s'
              : 'Get started',
        );
        expectNoLayoutErrors(tester, '$config job step');
        // Fresh tree for the next configuration.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    for (final brightness in Brightness.values) {
      testWidgets('accessibility guidelines (${brightness.name})', (
        tester,
      ) async {
        await _pump(tester, config: TestConfig(brightness: brightness));
        await expectMeetsAccessibilityGuidelines(tester);
        await _toJobStep(tester);
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }

    testWidgets('tablet: centred card on a tonal background', (tester) async {
      await _pump(
        tester,
        config: const TestConfig(size: TestScreens.tabletPortrait),
      );
      expect(find.byType(Card), findsOneWidget);
      final card = tester.getRect(find.byType(Card));
      expect(card.width, lessThanOrEqualTo(560));
      expect(card.center.dx, closeTo(TestScreens.tabletPortrait.width / 2, 1));
    });

    testWidgets('phone landscape: mark beside the text', (tester) async {
      await _pump(
        tester,
        config: const TestConfig(size: TestScreens.landscapeSmall),
      );
      final title = tester.getRect(
        find.text('Schichten erfassen. Lohn live wachsen sehen.'),
      );
      final button = tester.getRect(find.text('Los geht’s'));
      expect(title.left, greaterThan(150));
      expect(button.top, greaterThan(title.top));
    });
  });
}
