import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../domain/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';

/// Opens the dialog to set the monthly goal/limit (amount + type) or switch
/// it off.
Future<void> showMonthlyGoalDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const MonthlyGoalDialog(),
);

enum _GoalChoice { off, goal, limit }

/// Monthly goal/limit editor.
class MonthlyGoalDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const MonthlyGoalDialog({super.key});

  @override
  ConsumerState<MonthlyGoalDialog> createState() => _MonthlyGoalDialogState();
}

class _MonthlyGoalDialogState extends ConsumerState<MonthlyGoalDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late _GoalChoice _choice;
  int? _cents;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _cents = settings.monthlyGoalCents;
    _choice = _cents == null
        ? _GoalChoice.off
        : settings.monthlyGoalType == MonthlyGoalType.limit
        ? _GoalChoice.limit
        : _GoalChoice.goal;
  }

  Future<void> _save() async {
    if (_choice != _GoalChoice.off &&
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    final settings = ref.read(settingsProvider.notifier);
    try {
      await switch (_choice) {
        _GoalChoice.off => settings.setMonthlyGoal(null),
        _GoalChoice.goal => settings.setMonthlyGoal(
          _cents,
          type: MonthlyGoalType.goal,
        ),
        _GoalChoice.limit => settings.setMonthlyGoal(
          _cents,
          type: MonthlyGoalType.limit,
        ),
      };
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e, st) {
      await ref.read(errorLogProvider).record(e, st, context: 'goal');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final off = _choice == _GoalChoice.off;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.settingsGoal),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioGroup<_GoalChoice>(
              groupValue: _choice,
              onChanged: (c) {
                if (c != null && !_saving) setState(() => _choice = c);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (choice, label, help) in [
                    (
                      _GoalChoice.off,
                      l10n.settingsGoalOff,
                      l10n.settingsGoalHelpOff,
                    ),
                    (
                      _GoalChoice.goal,
                      l10n.settingsGoalTypeGoal,
                      l10n.settingsGoalHelpGoal,
                    ),
                    (
                      _GoalChoice.limit,
                      l10n.settingsGoalTypeLimit,
                      l10n.settingsGoalHelpLimit,
                    ),
                  ])
                    RadioListTile<_GoalChoice>(
                      value: choice,
                      enabled: !_saving,
                      contentPadding: EdgeInsets.zero,
                      title: Text(label),
                      subtitle: Text(
                        help,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!off) ...[
              const SizedBox(height: ChronosSpace.s16),
              MoneyField(
                value: _cents,
                label: l10n.settingsGoalAmount,
                required: true,
                allowZero: false,
                enabled: !_saving,
                textInputAction: TextInputAction.done,
                onChanged: (c) => _cents = c,
                onSubmitted: (_) => _save(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Opens the "Arbeitest du noch?" reminder choice (Aus / 6 / 8 / 10 / 12 h).
Future<void> showReminderDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const ReminderDialog());

/// Reminder delay choice; selecting an option saves it and closes.
class ReminderDialog extends ConsumerWidget {
  /// Creates the dialog.
  const ReminderDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(settingsProvider).reminderHours;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.settingsReminder),
      contentPadding: const EdgeInsets.only(top: ChronosSpace.s16),
      content: RadioGroup<int>(
        groupValue: current,
        onChanged: (hours) async {
          if (hours == null) return;
          final navigator = Navigator.of(context);
          await ref.read(settingsProvider.notifier).setReminderHours(hours);
          if (navigator.mounted) navigator.pop();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChronosSpace.s24),
              child: Text(l10n.settingsReminderHelp),
            ),
            const SizedBox(height: ChronosSpace.s8),
            for (final hours in AppSettings.reminderHourOptions)
              RadioListTile<int>(
                value: hours,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ChronosSpace.s16,
                ),
                title: Text(
                  hours == 0
                      ? l10n.settingsReminderOff
                      : l10n.settingsReminderHours(hours),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}
