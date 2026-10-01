import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/onboarding_page.dart';
import '../../features/recovery/recovery_screen.dart';
import '../providers/providers.dart';
import '../theme/theme.dart';
import 'home_shell.dart';
import 'splash_screen.dart';
import 'wage_check_page.dart';

/// Decides what the app shows, from the start sequence and the data:
///
/// 1. start sequence running ([bootstrapProvider] loading) → [SplashScreen];
/// 2. start failed → [RecoveryScreen] (retry, share raw data / error log);
/// 3. no active job ([onboardingNeededProvider]) → [OnboardingPage]
///    (also again after "Alle Daten löschen");
/// 4. migrated wage looks wrong ([pendingWageCheckProvider]) →
///    [WageCheckPage];
/// 5. otherwise → [HomeShell] with the three tabs.
///
/// Re-evaluates whenever these providers change; stages cross-fade.
class StartupGate extends ConsumerWidget {
  /// Creates the gate.
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : ChronosMotion.medium,
      switchInCurve: ChronosMotion.standard,
      switchOutCurve: ChronosMotion.standard,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: <Widget>[...previous, ?current],
      ),
      child: _stage(ref),
    );
  }

  Widget _stage(WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    if (boot.isLoading) {
      return const SplashScreen(key: ValueKey<String>('splash'));
    }
    if (boot.hasError) {
      return RecoveryScreen(
        key: const ValueKey<String>('recovery'),
        error: boot.error!,
        stackTrace: boot.stackTrace,
      );
    }

    // Only after the start sequence: the migration must have run before the
    // data below is read.
    final onboarding = ref.watch(onboardingNeededProvider);
    if (!onboarding.hasValue) {
      if (onboarding.hasError) {
        return RecoveryScreen(
          key: const ValueKey<String>('recovery'),
          error: onboarding.error!,
          stackTrace: onboarding.stackTrace,
        );
      }
      return const SplashScreen(key: ValueKey<String>('splash'));
    }
    if (onboarding.requireValue) {
      return const OnboardingPage(key: ValueKey<String>('onboarding'));
    }

    final wage = ref.watch(pendingWageCheckProvider);
    final check = wage.value;
    if (check != null) {
      return WageCheckPage(
        key: const ValueKey<String>('wageCheck'),
        check: check,
      );
    }
    if (wage.isLoading && !wage.hasValue) {
      return const SplashScreen(key: ValueKey<String>('splash'));
    }
    // A failed wage check never blocks the app (it is asked again next time).
    return const HomeShell(key: ValueKey<String>('home'));
  }
}
