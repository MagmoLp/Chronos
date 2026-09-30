import 'package:chronos/core/format.dart';
import 'package:chronos/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Stateful host that feeds changes back into the field, like an editor.
class _Host extends StatefulWidget {
  const _Host({
    super.key,
    required this.initial,
    required this.log,
    this.formKey,
  });

  final ClockTime? initial;
  final List<ClockTime> log;
  final GlobalKey<FormState>? formKey;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late ClockTime? value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: <Widget>[
            TimeField(
              label: 'Start',
              value: value,
              onChanged: (t) {
                widget.log.add(t);
                setState(() => value = t);
              },
            ),
            const TextField(),
          ],
        ),
      ),
    );
  }
}

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Finder get _input => find.byType(TextFormField);

void main() {
  testWidgets('shows the value per locale and 12/24-hour setting', (
    tester,
  ) async {
    final log = <ClockTime>[];
    await pumpApp(tester, _Host(initial: (hour: 8, minute: 0), log: log));
    expect(find.text('08:00'), findsOneWidget);

    await pumpApp(
      tester,
      _Host(
        key: const ValueKey<String>('en'),
        initial: (hour: 16, minute: 30),
        log: log,
      ),
      config: const TestConfig(locale: Locale('en')),
    );
    expect(find.textContaining(RegExp(r'^4:30\sPM$')), findsOneWidget);
  });

  testWidgets('reformats the shown time when the locale changes', (
    tester,
  ) async {
    final log = <ClockTime>[];
    const key = ValueKey<String>('host');
    await pumpApp(
      tester,
      _Host(key: key, initial: (hour: 16, minute: 30), log: log),
    );
    expect(find.text('16:30'), findsOneWidget);
    await pumpApp(
      tester,
      _Host(key: key, initial: (hour: 16, minute: 30), log: log),
      config: const TestConfig(locale: Locale('en')),
    );
    expect(find.textContaining(RegExp(r'^4:30\sPM$')), findsOneWidget);
    expect(log, isEmpty);
  });

  testWidgets('typed input is committed on blur and on submit', (tester) async {
    final log = <ClockTime>[];
    await pumpApp(tester, _Host(initial: (hour: 8, minute: 0), log: log));

    await tester.enterText(_input, '0930');
    expect(log, isEmpty, reason: 'nothing is committed while typing');
    await _blur(tester);
    expect(log.single, (hour: 9, minute: 30));
    expect(find.text('09:30'), findsOneWidget);

    await tester.enterText(_input, '16');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(log.last, (hour: 16, minute: 0));
    expect(find.text('16:00'), findsOneWidget);
  });

  testWidgets('invalid input shows an error and is not committed', (
    tester,
  ) async {
    final log = <ClockTime>[];
    final key = GlobalKey<FormState>();
    await pumpApp(
      tester,
      _Host(initial: (hour: 8, minute: 0), log: log, formKey: key),
    );
    await tester.enterText(_input, '25');
    await _blur(tester);
    expect(log, isEmpty);
    expect(find.text('Gib eine Uhrzeit wie 08:15 ein'), findsOneWidget);
    expect(key.currentState!.validate(), isFalse);
  });

  testWidgets('steppers move by 15 minutes and wrap around midnight', (
    tester,
  ) async {
    final log = <ClockTime>[];
    await pumpApp(tester, _Host(initial: (hour: 23, minute: 50), log: log));
    await tester.tap(find.byTooltip('15 Minuten später'));
    await tester.pump();
    expect(log.last, (hour: 0, minute: 5));
    expect(find.text('00:05'), findsOneWidget);
    await tester.tap(find.byTooltip('15 Minuten früher'));
    await tester.tap(find.byTooltip('15 Minuten früher'));
    await tester.pump();
    expect(log.last, (hour: 23, minute: 35));

    for (final tooltip in ['15 Minuten später', '15 Minuten früher']) {
      final size = tester.getSize(find.byTooltip(tooltip));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('stepper starts from the typed text when it is valid', (
    tester,
  ) async {
    final log = <ClockTime>[];
    await pumpApp(tester, _Host(initial: null, log: log));
    await tester.enterText(_input, '930');
    await tester.tap(find.byTooltip('15 Minuten später'));
    await tester.pump();
    expect(log.last, (hour: 9, minute: 45));
  });

  testWidgets('picker button opens the Material time picker', (tester) async {
    final log = <ClockTime>[];
    await pumpApp(tester, _Host(initial: (hour: 8, minute: 0), log: log));
    await tester.tap(find.byTooltip('Uhrzeit wählen'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(log, isEmpty);
  });

  testWidgets('no overflow and accessible in every configuration', (
    tester,
  ) async {
    for (final config in TestConfig.matrix()) {
      await pumpApp(
        tester,
        const _Host(initial: (hour: 8, minute: 0), log: <ClockTime>[]),
        config: config,
      );
    }
    for (final brightness in Brightness.values) {
      await pumpApp(
        tester,
        const _Host(initial: (hour: 8, minute: 0), log: <ClockTime>[]),
        config: TestConfig(brightness: brightness),
      );
      await expectMeetsAccessibilityGuidelines(tester);
    }
  });
}
