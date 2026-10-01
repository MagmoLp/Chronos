import 'package:chronos/app/startup/wage_check_page.dart';
import 'package:chronos/domain/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

final WagePlausibility _tooHigh = checkWagePlausibility(125000);
final WagePlausibility _tooLow = checkWagePlausibility(300);

Future<AppHarness> _pump(
  WidgetTester tester,
  WagePlausibility check, {
  TestConfig config = const TestConfig(),
}) async {
  final h = AppHarness();
  await pumpOnHarness(tester, h, WageCheckPage(check: check), config: config);
  return h;
}

void main() {
  test('the fixture is what v1 produced', () {
    expect(_tooHigh.issue, WageIssue.tooHigh);
    expect(_tooHigh.suggestedCentsPerHour, 1250);
    expect(_tooLow.issue, WageIssue.tooLow);
    expect(_tooLow.suggestedCentsPerHour, isNull);
  });

  testWidgets('too high: explains the lost comma, suggests 12,50', (
    tester,
  ) async {
    await _pump(tester, _tooHigh);
    expect(
      find.text('1.250,00\u00A0€/h übernommen – stimmt das?'),
      findsOneWidget,
    );
    expect(find.textContaining('Komma verschluckt'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '12,50'), findsOneWidget);
    expect(find.text('Diesen Lohn verwenden'), findsOneWidget);
    expect(find.text('1.250,00\u00A0€/h beibehalten'), findsOneWidget);
  });

  testWidgets('too low: no suggestion, the field starts empty', (tester) async {
    await _pump(tester, _tooLow);
    expect(find.text('3,00\u00A0€/h übernommen – stimmt das?'), findsOneWidget);
    expect(
      find.text('Das ist ungewöhnlich niedrig für einen Stundenlohn.'),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('English', (tester) async {
    await _pump(
      tester,
      _tooHigh,
      config: const TestConfig(locale: Locale('en')),
    );
    expect(
      find.text('€1,250.00/h taken over – is that right?'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, '12.50'), findsOneWidget);
    expect(find.text('Keep €1,250.00/h'), findsOneWidget);
  });

  group('layout', () {
    testWidgets('no overflow in every configuration', (tester) async {
      for (final config in TestConfig.matrix()) {
        await _pump(tester, _tooHigh, config: config);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    for (final brightness in Brightness.values) {
      testWidgets('accessibility guidelines (${brightness.name})', (
        tester,
      ) async {
        await _pump(
          tester,
          _tooHigh,
          config: TestConfig(brightness: brightness),
        );
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }
  });
}
