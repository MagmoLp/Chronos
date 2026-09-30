import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../l10n/app_localizations.dart';

/// A form field showing a local date ("Mi., 30. Sept. 2026"); tapping it
/// opens the Material date picker limited to [firstDate]…[lastDate].
class DateField extends StatelessWidget {
  /// Creates the field.
  const DateField({
    super.key,
    required this.label,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.enabled = true,
  });

  /// Field label ("Datum").
  final String label;

  /// Selected date.
  final LocalDate date;

  /// Earliest selectable date.
  final LocalDate firstDate;

  /// Latest selectable date.
  final LocalDate lastDate;

  /// Called with a newly picked date.
  final ValueChanged<LocalDate> onChanged;

  /// Whether the field reacts to taps.
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final first = LocalDate.min(firstDate, date);
    final last = LocalDate.max(lastDate, date);
    final picked = await showDatePicker(
      context: context,
      initialDate: date.toLocalDateTime(),
      firstDate: first.toLocalDateTime(),
      lastDate: last.toLocalDateTime(),
      helpText: label,
    );
    if (picked == null) return;
    final value = LocalDate.fromDateTime(picked);
    if (value != date) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final local = date.toLocalDateTime();
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label, ${fmt.dateLong(local)}',
      hint: l10n.editorPickDate,
      excludeSemantics: true,
      onTap: enabled ? () => _pick(context) : null,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ChronosRadius.medium),
        ),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(fmt.dateMedium(local)),
        ),
      ),
    );
  }
}
