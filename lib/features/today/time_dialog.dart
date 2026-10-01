import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/time_field.dart';

/// Asks for a time of day ("Früher angefangen?", "seit 08:02" tapped):
/// typed input ("0815", "8:15", "8"), ±15-minute steppers and the clock
/// picker. Resolves to `null` when cancelled.
Future<ClockTime?> showTodayTimeDialog(
  BuildContext context, {
  required ClockTime initial,
  required String title,
  String? label,
}) => showDialog<ClockTime>(
  context: context,
  builder: (_) => TodayTimeDialog(initial: initial, title: title, label: label),
);

/// The dialog behind [showTodayTimeDialog].
class TodayTimeDialog extends StatefulWidget {
  /// Creates the dialog.
  const TodayTimeDialog({
    super.key,
    required this.initial,
    required this.title,
    this.label,
  });

  /// Preselected time.
  final ClockTime initial;

  /// Question as the title.
  final String title;

  /// Field label.
  final String? label;

  @override
  State<TodayTimeDialog> createState() => _TodayTimeDialogState();
}

class _TodayTimeDialogState extends State<TodayTimeDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ClockTime _value = widget.initial;

  Future<void> _confirm() async {
    // Commit text that was typed but not submitted yet.
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.value();
    if (!mounted || !(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TimeField(
          value: _value,
          label: widget.label,
          onChanged: (time) => setState(() => _value = time),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _confirm, child: Text(l10n.commonOk)),
      ],
    );
  }
}
