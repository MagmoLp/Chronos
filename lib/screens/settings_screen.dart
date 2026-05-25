import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/work_entries_provider.dart';
import '../widgets/animated_card.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppThemeData.background,
      appBar: AppBar(
        backgroundColor: AppThemeData.background,
        title: Text(l10n?.settings ?? 'Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: settings.isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildLanguageSection(context, settings, l10n),
                  const SizedBox(height: 24),
                  _buildWageSection(context, settings, l10n),
                  const SizedBox(height: 24),
                  _buildDeleteAllSection(context, l10n),
                  const SizedBox(height: 32),
                  // Info section
                  Center(
                    child: Text(
                      'Chronos v1.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeData.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, SettingsProvider settings, AppLocalizations? l10n) {
    return HighlightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.language ?? 'Sprache',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemeData.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  context,
                  label: 'Deutsch',
                  value: AppLanguage.german,
                  selected: settings.language == AppLanguage.german,
                  onTap: () => settings.setLanguage(AppLanguage.german),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  context,
                  label: 'English',
                  value: AppLanguage.english,
                  selected: settings.language == AppLanguage.english,
                  onTap: () => settings.setLanguage(AppLanguage.english),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required AppLanguage value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppThemeData.animationMedium,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: selected
              ? AppThemeData.electricBlue.withOpacity(0.2)
              : AppThemeData.surfaceLight,
          borderRadius: BorderRadius.circular(AppThemeData.radiusSmall),
          border: Border.all(
            color: selected
                ? AppThemeData.electricBlue
                : Colors.transparent,
            width: selected ? 2 : 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_circle,
                color: AppThemeData.electricBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? AppThemeData.electricBlue
                    : AppThemeData.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWageSection(BuildContext context, SettingsProvider settings, AppLocalizations? l10n) {
    return HighlightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.hourlyWage ?? 'Stundenlohn (€)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemeData.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _WageInputField(
            initialValue: settings.hourlyWage,
            onWageChanged: (value) => settings.setHourlyWage(value),
            hintText: l10n?.enterWage ?? 'Lohn eingeben',
            suffixText: '/ ${l10n?.hours ?? 'h'}',
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.wageExample ?? 'Beispiel: 15 oder 15.50',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemeData.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAllSection(BuildContext context, AppLocalizations? l10n) {
    return HighlightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datenverwaltung',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemeData.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedCard(
            onTap: () => _showDeleteAllConfirmation(context, l10n),
            backgroundColor: AppThemeData.error.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.delete_forever,
                  color: AppThemeData.error,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alle Einträge löschen',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppThemeData.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Löscht alle Arbeitszeiteinträge unwiderruflich',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemeData.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppThemeData.error.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAllConfirmation(BuildContext context, AppLocalizations? l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAllDialog(l10n: l10n),
    );

    if (confirmed == true && context.mounted) {
      await context.read<WorkEntriesProvider>().deleteAllEntries();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alle Einträge gelöscht'),
            backgroundColor: AppThemeData.success,
          ),
        );
      }
    }
  }
}

class _DeleteAllDialog extends StatefulWidget {
  final AppLocalizations? l10n;
  const _DeleteAllDialog({required this.l10n});

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = _controller.text.trim();
    final isValid = input == 'Löschen' || input == 'Loeschen';
    final l10n = widget.l10n;

    return AlertDialog(
      backgroundColor: AppThemeData.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeData.radiusLarge),
      ),
      title: Text(
        'Alle Daten löschen?',
        style: const TextStyle(color: AppThemeData.error),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diese Aktion kann nicht rückgängig gemacht werden. Alle Arbeitszeiteinträge werden unwiderruflich gelöscht.',
            style: const TextStyle(color: AppThemeData.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            'Zum Bestätigen gebe das Wort "Löschen" ein:',
            style: const TextStyle(color: AppThemeData.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppThemeData.textPrimary),
            decoration: InputDecoration(
              hintText: 'Löschen',
              hintStyle: TextStyle(color: AppThemeData.textSecondary.withOpacity(0.5)),
              filled: true,
              fillColor: AppThemeData.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppThemeData.radiusMedium),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppThemeData.radiusMedium),
                borderSide: const BorderSide(color: AppThemeData.error, width: 2),
              ),
            ),
          ),
        ],
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
          onPressed: isValid ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeData.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppThemeData.error.withOpacity(0.3),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(l10n?.delete ?? 'Löschen'),
        ),
      ],
    );
  }
}

// Separate StatefulWidget for wage input to prevent focus loss
class _WageInputField extends StatefulWidget {
  final double initialValue;
  final Function(double) onWageChanged;
  final String? hintText;
  final String? suffixText;

  const _WageInputField({
    required this.initialValue,
    required this.onWageChanged,
    this.hintText,
    this.suffixText,
  });

  @override
  State<_WageInputField> createState() => _WageInputFieldState();
}

class _WageInputFieldState extends State<_WageInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppThemeData.textPrimary),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Lohn eingeben',
        hintStyle: const TextStyle(color: AppThemeData.textSecondary),
        prefixIcon: const Icon(Icons.euro, color: AppThemeData.electricBlue),
        filled: true,
        fillColor: AppThemeData.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeData.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeData.radiusMedium),
          borderSide: const BorderSide(color: AppThemeData.electricBlue, width: 2),
        ),
        suffixText: widget.suffixText,
        suffixStyle: const TextStyle(color: AppThemeData.textSecondary),
      ),
      onChanged: (value) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          widget.onWageChanged(parsed);
        }
      },
    );
  }
}
