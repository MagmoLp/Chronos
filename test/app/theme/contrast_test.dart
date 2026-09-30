import 'dart:math' as math;

import 'package:chronos/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('contrastRatio matches known WCAG values', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
      closeTo(1, 0.001),
    );
    // The v1 START button that the audit flagged (white on #22C55E, 2.28:1).
    expect(
      contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF22C55E)),
      closeTo(2.28, 0.01),
    );
  });

  for (final (name, theme) in [
    ('light', ChronosTheme.light),
    ('dark', ChronosTheme.dark),
  ]) {
    group('$name theme', () {
      final s = theme.colorScheme;
      final c = theme.extension<ChronosColors>()!;

      final textPairs = <String, (Color, Color)>{
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onSecondaryContainer/secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'onTertiary/tertiary': (s.onTertiary, s.tertiary),
        'onTertiaryContainer/tertiaryContainer': (
          s.onTertiaryContainer,
          s.tertiaryContainer,
        ),
        'onError/error': (s.onError, s.error),
        'onErrorContainer/errorContainer': (
          s.onErrorContainer,
          s.errorContainer,
        ),
        'onInverseSurface/inverseSurface': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
        'inversePrimary/inverseSurface': (s.inversePrimary, s.inverseSurface),
        'onSuccess/success': (c.onSuccess, c.success),
        'onSuccessContainer/successContainer': (
          c.onSuccessContainer,
          c.successContainer,
        ),
        'onLive/liveContainer': (c.onLive, c.liveContainer),
        'onOpen/open': (c.onOpen, c.open),
        'onOpenContainer/openContainer': (c.onOpenContainer, c.openContainer),
        'onWarning/warning': (c.onWarning, c.warning),
        'onWarningContainer/warningContainer': (
          c.onWarningContainer,
          c.warningContainer,
        ),
        'onPrimaryFixed/primaryFixed': (s.onPrimaryFixed, s.primaryFixed),
        'onSecondaryFixed/secondaryFixed': (
          s.onSecondaryFixed,
          s.secondaryFixed,
        ),
        'onTertiaryFixed/tertiaryFixed': (s.onTertiaryFixed, s.tertiaryFixed),
      };
      final surfaces = <String, Color>{
        'surface': s.surface,
        'surfaceContainerLowest': s.surfaceContainerLowest,
        'surfaceContainerLow': s.surfaceContainerLow,
        'surfaceContainer': s.surfaceContainer,
        'surfaceContainerHigh': s.surfaceContainerHigh,
        'surfaceContainerHighest': s.surfaceContainerHighest,
      };
      for (final entry in surfaces.entries) {
        textPairs['onSurface/${entry.key}'] = (s.onSurface, entry.value);
        textPairs['onSurfaceVariant/${entry.key}'] = (
          s.onSurfaceVariant,
          entry.value,
        );
        // Text buttons, links and status text sit directly on surfaces.
        textPairs['primary/${entry.key}'] = (s.primary, entry.value);
        textPairs['error/${entry.key}'] = (s.error, entry.value);
        textPairs['open/${entry.key}'] = (c.open, entry.value);
        textPairs['success/${entry.key}'] = (c.success, entry.value);
      }

      for (final pair in textPairs.entries) {
        test('text pair ${pair.key} is at least 4.5:1', () {
          final (fg, bg) = pair.value;
          expect(
            contrastRatio(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: pair.key,
          );
        });
      }

      test('UI boundaries and indicators are at least 3:1', () {
        expect(contrastRatio(s.outline, s.surface), greaterThanOrEqualTo(3));
        expect(
          contrastRatio(s.outline, s.surfaceContainerLow),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrastRatio(s.outline, s.surfaceContainerHighest),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrastRatio(s.onSurfaceVariant, s.surfaceContainerHighest),
          greaterThanOrEqualTo(3),
          reason: 'input underline on a filled field',
        );
        expect(
          contrastRatio(c.liveIndicator, c.liveContainer),
          greaterThanOrEqualTo(3),
        );
      });

      test('job palette is at least 3:1 against surface and cards', () {
        expect(c.jobPalette, hasLength(ChronosColors.jobColorCount));
        for (final color in c.jobPalette) {
          expect(
            contrastRatio(color, s.surface),
            greaterThanOrEqualTo(3),
            reason: '$color on surface',
          );
          expect(
            contrastRatio(color, s.surfaceContainerLow),
            greaterThanOrEqualTo(3),
            reason: '$color on card',
          );
        }
      });
    });
  }
}
