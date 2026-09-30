import 'package:chronos/widgets/money_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Form host so validation can be triggered.
Widget _form(GlobalKey<FormState> key, Widget field) => Padding(
  padding: const EdgeInsets.all(16),
  child: Form(
    key: key,
    child: Column(children: <Widget>[field, const TextField()]),
  ),
);

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

void main() {
  testWidgets('shows the initial value formatted with the currency symbol', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    await pumpApp(
      tester,
      _form(key, const MoneyField(value: 1500, label: 'Stundenlohn')),
    );
    expect(find.text('15,00'), findsOneWidget);
    expect(find.text('€'), findsOneWidget);
    expect(find.text('Stundenlohn'), findsOneWidget);

    await pumpApp(
      tester,
      _form(key, const MoneyField(value: 123456, label: 'Rate')),
      config: const TestConfig(locale: Locale('en')),
    );
    expect(find.text('1,234.56'), findsOneWidget);
  });

  testWidgets('accepts comma and dot, reports cents and reformats on blur', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    final values = <int?>[];
    await pumpApp(tester, _form(key, MoneyField(onChanged: values.add)));
    await tester.enterText(find.byType(MoneyField), '15,5');
    expect(values.last, 1550);
    await tester.enterText(find.byType(MoneyField), '15.5');
    expect(values.last, 1550);
    await tester.enterText(find.byType(MoneyField), '1.234,5');
    expect(values.last, 123450);
    await _blur(tester);
    expect(find.text('1.234,50'), findsOneWidget);
    expect(key.currentState!.validate(), isTrue);
  });

  testWidgets('filters letters and signs while typing', (tester) async {
    final key = GlobalKey<FormState>();
    await pumpApp(tester, _form(key, const MoneyField()));
    await tester.enterText(find.byType(MoneyField), '-1a2');
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('validation messages', (tester) async {
    final key = GlobalKey<FormState>();
    String? seen;
    await pumpApp(
      tester,
      _form(
        key,
        MoneyField(
          required: true,
          allowZero: false,
          validator: (cents) {
            seen = '$cents';
            return cents != null && cents > 100000 ? 'Zu hoch' : null;
          },
        ),
      ),
    );
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Bitte gib einen Wert ein'), findsOneWidget);

    await tester.enterText(find.byType(MoneyField), '1,2,3');
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Gib einen Betrag wie 15,50 ein'), findsOneWidget);

    await tester.enterText(find.byType(MoneyField), '0');
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Der Betrag muss größer als 0 sein'), findsOneWidget);

    await tester.enterText(find.byType(MoneyField), '2000');
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Zu hoch'), findsOneWidget);
    expect(seen, '200000');

    await tester.enterText(find.byType(MoneyField), '13,90');
    expect(key.currentState!.validate(), isTrue);
  });

  testWidgets('validates on blur', (tester) async {
    final key = GlobalKey<FormState>();
    await pumpApp(
      tester,
      _form(key, const MoneyField()),
      config: const TestConfig(locale: Locale('en')),
    );
    await tester.enterText(find.byType(MoneyField), '1.234');
    await _blur(tester);
    expect(find.text('Enter an amount like 15.50'), findsOneWidget);
  });

  testWidgets('parent value changes replace the text while unfocused', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    await pumpApp(tester, _form(key, const MoneyField(value: 1000)));
    expect(find.text('10,00'), findsOneWidget);
    await pumpApp(tester, _form(key, const MoneyField(value: 258750)));
    expect(find.text('2.587,50'), findsOneWidget);
  });

  testWidgets('no overflow and accessible in every configuration', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    for (final config in TestConfig.matrix()) {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: _form(
            key,
            const MoneyField(
              value: 1500,
              label: 'Stundenlohn',
              helperText: 'Brutto pro Stunde',
              required: true,
            ),
          ),
        ),
        config: config,
      );
    }
    for (final brightness in Brightness.values) {
      await pumpApp(
        tester,
        _form(key, const MoneyField(value: 1500, label: 'Stundenlohn')),
        config: TestConfig(brightness: brightness),
      );
      await expectMeetsAccessibilityGuidelines(tester);
    }
  });
}
