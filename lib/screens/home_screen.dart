import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/work_entry.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/work_entries_provider.dart';
import '../widgets/animated_money_display.dart';
import '../widgets/animated_card.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final timer = context.watch<TimerProvider>();
    final entries = context.watch<WorkEntriesProvider>();
    final l10n = AppLocalizations.of(context);

    if (settings.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Keep timer's hourly wage in sync for notification display
    timer.setHourlyWage(settings.hourlyWage);
    
    final currentEarnings = timer.getCurrentEarnings(settings.hourlyWage);
    final totalOpenEarnings = entries.totalOpenEarnings(settings.hourlyWage) + currentEarnings;

    return Scaffold(
      backgroundColor: AppThemeData.background,
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'Gehaltszähler'),
        actions: [
          AnimatedIconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: Icons.settings,
            backgroundColor: AppThemeData.surface,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Current Earnings Card - Large
              _buildEarningsCard(
                context,
                label: l10n?.currentEarnings ?? 'Aktueller Verdienst',
                amount: currentEarnings,
                isLarge: true,
              ),
              // Total Earnings Card - Medium
              _buildEarningsCard(
                context,
                label: l10n?.totalOpenEarnings ?? 'Gesamter offener Betrag',
                amount: totalOpenEarnings,
                isLarge: false,
              ),
              // Timer Display
              _buildTimerDisplay(context, timer.elapsed, timer.isRunning),
              // Control Buttons
              _buildControlButtons(context, timer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, {
    required String label,
    required double amount,
    required bool isLarge,
  }) {
    return HighlightCard(
      accentColor: isLarge ? AppThemeData.electricBlue : null,
      padding: const EdgeInsets.all(28),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemeData.textSecondary,
              fontSize: isLarge ? 18 : 14,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedMoneyDisplay(
            amount: amount,
            style: isLarge
              ? Theme.of(context).textTheme.headlineLarge
              : Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context, Duration elapsed, bool isRunning) {
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return AnimatedContainer(
      duration: AppThemeData.animationMedium,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: isRunning
          ? AppThemeData.electricBlue.withOpacity(0.15)
          : AppThemeData.surface,
        borderRadius: BorderRadius.circular(AppThemeData.radiusPill),
        border: isRunning
          ? Border.all(color: AppThemeData.electricBlue.withOpacity(0.3), width: 2)
          : null,
      ),
      child: Text(
        '$hours:$minutes:$seconds',
        style: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w300,
          fontFamily: 'RobotoMono',
          color: AppThemeData.textPrimary,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, TimerProvider timer) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Start Button - Green pill
        AnimatedButton(
          onPressed: timer.isRunning ? null : () => timer.start(),
          backgroundColor: timer.isRunning
            ? AppThemeData.surfaceLight
            : AppThemeData.success,
          isFullWidth: false,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, size: 28),
              const SizedBox(width: 8),
              Text(
                l10n?.start ?? 'START',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
        // Stop Button - Red pill
        AnimatedButton(
          onPressed: timer.isRunning ? () => _showStopConfirmation(context, timer) : null,
          backgroundColor: timer.isRunning
            ? AppThemeData.error
            : AppThemeData.surfaceLight,
          isFullWidth: false,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stop, size: 28),
              const SizedBox(width: 8),
              Text(
                l10n?.stop ?? 'STOP',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Rounds [time] to the nearest quarter hour.
  /// Minutes 0–6  → round down to previous quarter (e.g. 08:06 → 08:00)
  /// Minutes 7–14 → round up to next quarter    (e.g. 08:07 → 08:15)
  DateTime _roundToQuarter(DateTime time) {
    final totalMinutes = time.hour * 60 + time.minute;
    final remainder = totalMinutes % 15;
    final rounded = remainder < 7
        ? totalMinutes - remainder
        : totalMinutes + (15 - remainder);
    final base = DateTime(time.year, time.month, time.day);
    return base.add(Duration(minutes: rounded));
  }

  Future<void> _showStopConfirmation(BuildContext context, TimerProvider timer) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeData.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeData.radiusLarge),
        ),
        title: Text(
          l10n?.confirmStopTitle ?? 'Timer stoppen?',
          style: const TextStyle(color: AppThemeData.textPrimary),
        ),
        content: Text(
          l10n?.confirmStop ?? 'Sind Sie sicher, dass Sie stoppen möchten?',
          style: const TextStyle(color: AppThemeData.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n?.cancel ?? 'Abbrechen',
              style: const TextStyle(color: AppThemeData.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.electricBlue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(l10n?.confirm ?? 'Bestätigen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // WICHTIG: Werte VOR stop() speichern, da stop() _startTime null setzt!
      final originalStartTime = timer.startTime;
      final endTime = await timer.stop();

      if (endTime != null &&
          originalStartTime != null &&
          context.mounted) {
        const minDuration = Duration(minutes: 15);
        final entries = context.read<WorkEntriesProvider>();

        final roundedStart = _roundToQuarter(originalStartTime);
        final roundedEnd = _roundToQuarter(endTime);
        final roundedDuration = roundedEnd.difference(roundedStart);

        if (roundedDuration < minDuration) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.tooShortEntry ?? 'Zeit zu kurz (unter 15 Min). Es wurde nicht gespeichert.',
              ),
              backgroundColor: AppThemeData.error,
            ),
          );
          return;
        }

        final startDate = DateTime(
          roundedStart.year,
          roundedStart.month,
          roundedStart.day,
        );

        await entries.saveEntry(
          WorkEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: startDate,
            startTime: roundedStart,
            endTime: roundedEnd,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.workSaved ?? 'Arbeitszeit gespeichert'),
            backgroundColor: AppThemeData.success,
          ),
        );
      }
    }
  }
}
