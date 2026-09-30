import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/widgets/confirm_dialog.dart';
import 'package:chronos/widgets/undo_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// A button that opens the confirm dialog and stores the result.
class _Opener extends StatelessWidget {
  const _Opener({required this.onResult, this.destructive = false});

  final ValueChanged<bool> onResult;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () async {
          final result = await showConfirmDialog(
            context,
            title: '214 Schichten und 2 Jobs löschen?',
            message: 'Vorher wird automatisch eine Sicherung angelegt. Du kannst den Schritt rückgängig machen.',
            confirmLabel: 'Löschen',
            icon: Icons.delete_outline,
            destructive: destructive,
          );
          onResult(result);
        },
        child: const Text('Öffnen'),
      ),
    );
  }
}

void main() {
  group('showConfirmDialog', () {
    testWidgets('resolves true on confirm, false on cancel and outside tap', (
      tester,
    ) async {
      final results = <bool>[];
      await pumpApp(tester, _Opener(onResult: results.add));

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      expect(find.text('214 Schichten und 2 Jobs löschen?'), findsOneWidget);
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(results, [true, false, false]);
    });

    testWidgets('destructive variant uses the error colours', (tester) async {
      for (final brightness in Brightness.values) {
        await pumpApp(
          tester,
          _Opener(onResult: (_) {}, destructive: true),
          config: TestConfig(brightness: brightness),
        );
        await tester.tap(find.text('Öffnen'));
        await tester.pumpAndSettle();
        final scheme = brightness == Brightness.light
            ? ChronosTheme.light.colorScheme
            : ChronosTheme.dark.colorScheme;
        final button = find.ancestor(
          of: find.text('Löschen'),
          matching: find.byType(FilledButton),
        );
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)).first,
        );
        expect(material.color, scheme.error);
        await expectMeetsAccessibilityGuidelines(tester);
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('dialog fits every screen and text scale', (tester) async {
      for (final config in TestConfig.matrix()) {
        await pumpApp(
          tester,
          _Opener(onResult: (_) {}, destructive: true),
          config: config,
        );
        await tester.tap(find.text('Öffnen'));
        await tester.pumpAndSettle();
        expectNoLayoutErrors(tester, config);
        await tester.tap(find.text(l10nFor(config.locale).commonCancel));
        await tester.pumpAndSettle();
      }
    });
  });

  group('showUndoSnackBar', () {
    Widget host(void Function(BuildContext) onPressed) => Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () => onPressed(context),
          child: const Text('Aktion'),
        ),
      ),
    );

    testWidgets(
      'shows the message with a working undo action and auto-dismisses',
      (tester) async {
        var undone = 0;
        await pumpApp(
          tester,
          host(
            (context) => showUndoSnackBar(
              context,
              message: 'Schicht gelöscht',
              onUndo: () => undone++,
            ),
          ),
        );
        await tester.tap(find.text('Aktion'));
        await tester.pumpAndSettle();
        expect(find.text('Schicht gelöscht'), findsOneWidget);
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.persist, isFalse);
        await tester.tap(find.text('Rückgängig'));
        await tester.pumpAndSettle();
        expect(undone, 1);

        await tester.tap(find.text('Aktion'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 7));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        expect(undone, 1);
      },
    );

    testWidgets('replaces the current snackbar', (tester) async {
      var n = 0;
      await pumpApp(
        tester,
        host(
          (context) => showUndoSnackBar(
            context,
            message: 'Nachricht ${++n}',
            onUndo: () {},
          ),
        ),
      );
      await tester.tap(find.text('Aktion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aktion'));
      await tester.pumpAndSettle();
      expect(find.text('Nachricht 1'), findsNothing);
      expect(find.text('Nachricht 2'), findsOneWidget);
    });

    testWidgets('stays with a close button while a screen reader is active', (
      tester,
    ) async {
      await pumpApp(
        tester,
        host(
          (context) => showUndoSnackBar(
            context,
            message: 'Schicht gelöscht',
            onUndo: () {},
          ),
        ),
        accessibleNavigation: true,
        config: const TestConfig(locale: Locale('en')),
      );
      await tester.tap(find.text('Aktion'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Schicht gelöscht'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).showCloseIcon,
        isTrue,
      );
    });

    testWidgets('floating snackbar is readable in both themes', (tester) async {
      for (final brightness in Brightness.values) {
        await pumpApp(
          tester,
          host(
            (context) => showUndoSnackBar(
              context,
              message: 'Schicht gelöscht',
              onUndo: () {},
            ),
          ),
          config: TestConfig(brightness: brightness),
        );
        await tester.tap(find.text('Aktion'));
        await tester.pumpAndSettle();
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(SnackBar),
                matching: find.byType(Material),
              )
              .first,
        );
        final scheme = brightness == Brightness.light
            ? ChronosTheme.light.colorScheme
            : ChronosTheme.dark.colorScheme;
        expect(material.color, scheme.inverseSurface);
        await expectMeetsAccessibilityGuidelines(tester);
        ScaffoldMessenger.of(tester.element(find.text('Aktion')))
            .removeCurrentSnackBar();
        await tester.pumpAndSettle();
      }
    });
  });
}
