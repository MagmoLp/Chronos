import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/work_entry.dart';
import '../providers/settings_provider.dart';
import '../providers/work_entries_provider.dart';
import '../widgets/animated_card.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';

class WorkLogScreen extends StatelessWidget {
  const WorkLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<WorkEntriesProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppThemeData.background,
      appBar: AppBar(
        title: Text(l10n?.workTimeLog ?? 'Arbeitszeit-Protokoll'),
        actions: [
          AnimatedIconButton(
            onPressed: () => _showAddEntryDialog(context),
            icon: Icons.add,
            backgroundColor: AppThemeData.surface,
          ),
          const SizedBox(width: 8),
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
        child: entries.entries.isEmpty
            ? _buildEmptyState(context)
            : _buildEntriesList(context, entries, settings.hourlyWage),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemeData.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_off_outlined,
              size: 64,
              color: AppThemeData.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.noEntries ?? 'Keine Einträge vorhanden',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppThemeData.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, WorkEntriesProvider entries, double hourlyWage) {
    final l10n = AppLocalizations.of(context);
    final sortedEntries = entries.entries.toList();

    // Group entries by start-month (overnight entries belong to start month)
    final Map<String, List<WorkEntry>> grouped = {};
    for (final entry in sortedEntries) {
      final key = '${entry.startTime.year}-${entry.startTime.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    // Keys are already in descending order because sortedEntries is sorted newest-first
    final groupKeys = grouped.keys.toList();

    // Build flat list of headers + entries
    final List<Widget> items = [];
    for (final key in groupKeys) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      items.add(_buildMonthHeader(context, year, month));
      for (final entry in grouped[key]!) {
        final earnings = entry.calculateEarnings(hourlyWage);
        items.add(_buildEntryItem(context, entry, earnings, entries, l10n));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      children: items,
    );
  }

  Widget _buildMonthHeader(BuildContext context, int year, int month) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime(year, month);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', locale).format(date);
    final label = (year == now.year) ? monthName : '$monthName $year';

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppThemeData.electricBlue,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppThemeData.electricBlue.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryItem(
    BuildContext context,
    WorkEntry entry,
    double earnings,
    WorkEntriesProvider entries,
    AppLocalizations? l10n,
  ) {
    return AnimatedListItem(
      onTap: () => _showEntryOptions(context, entry),
      onLongPress: () => _showEntryOptions(context, entry),
      isSelected: entry.isPaid,
      leading: GestureDetector(
        onTap: () => _handleTogglePaid(context, entry, entries),
        child: AnimatedContainer(
          duration: AppThemeData.animationMedium,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(
              color: entry.isPaid
                ? AppThemeData.success
                : AppThemeData.textSecondary.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: entry.isPaid ? AppThemeData.success.withOpacity(0.2) : null,
          ),
          child: entry.isPaid
            ? const Icon(Icons.check, color: AppThemeData.success, size: 18)
            : null,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            entry.formattedDuration,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeData.textPrimary,
            ),
          ),
          if (entry.isPaid)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppThemeData.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n?.paid ?? 'Abgerechnet',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatEntryDate(entry),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemeData.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.formattedTimeRange,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemeData.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n?.earned ?? 'Verdient'}: ${earnings.toStringAsFixed(2)} €',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemeData.electricBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatEntryDate(WorkEntry entry) {
    final s = entry.startTime;
    final e = entry.endTime;
    if (entry.isOvernightShift) {
      final startStr = '${s.day.toString().padLeft(2, '0')}.';
      final endStr = '${e.day.toString().padLeft(2, '0')}.${e.month.toString().padLeft(2, '0')}.${e.year}';
      return '$startStr – $endStr';
    }
    return '${s.day.toString().padLeft(2, '0')}.${s.month.toString().padLeft(2, '0')}.${s.year}';
  }

  Future<void> _handleTogglePaid(
    BuildContext context,
    WorkEntry entry,
    WorkEntriesProvider entries,
  ) async {
    if (!entry.isPaid) {
      entries.togglePaidStatus(entry.id);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeData.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeData.radiusLarge),
        ),
        title: Text(
          l10n?.unmarkPaidTitle ?? 'Abrechnung aufheben?',
          style: const TextStyle(color: AppThemeData.textPrimary),
        ),
        content: Text(
          l10n?.unmarkPaidContent ?? 'Diesen Eintrag wirklich als nicht abgerechnet markieren?',
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

    if (confirmed == true && context.mounted) {
      entries.togglePaidStatus(entry.id);
    }
  }

  Future<void> _showEntryOptions(BuildContext context, WorkEntry entry) async {
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeData.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppThemeData.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppThemeData.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedListItem(
                onTap: () {
                  Navigator.pop(context);
                  _showEditEntryDialog(context, entry);
                },
                leading: const Icon(Icons.edit, color: AppThemeData.electricBlue),
                child: Text(
                  l10n?.editEntry ?? 'Eintrag bearbeiten',
                  style: const TextStyle(color: AppThemeData.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedListItem(
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, entry);
                },
                leading: const Icon(Icons.delete, color: AppThemeData.error),
                child: Text(
                  l10n?.delete ?? 'Löschen',
                  style: const TextStyle(color: AppThemeData.error),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WorkEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final entriesProvider = context.read<WorkEntriesProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppThemeData.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeData.radiusLarge),
        ),
        title: Text(
          l10n?.delete ?? 'Löschen',
          style: const TextStyle(color: AppThemeData.textPrimary),
        ),
        content: Text(
          l10n?.confirmDelete ?? 'Diesen Eintrag wirklich löschen?',
          style: const TextStyle(color: AppThemeData.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              l10n?.cancel ?? 'Abbrechen',
              style: const TextStyle(color: AppThemeData.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.error,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(l10n?.delete ?? 'Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await entriesProvider.deleteEntry(entry.id);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n?.entryDeleted ?? 'Eintrag gelöscht'),
          backgroundColor: AppThemeData.success,
        ),
      );
    }
  }

  Future<void> _showAddEntryDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    
    DateTime selectedDate = now;
    TimeOfDay startTime = TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 16, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppThemeData.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeData.radiusLarge),
          ),
          title: Text(
            l10n?.addEntry ?? 'Eintrag hinzufügen',
            style: const TextStyle(color: AppThemeData.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogListTile(
                context,
                title: l10n?.date ?? 'Datum',
                subtitle: _formatDate(selectedDate),
                icon: Icons.calendar_today,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppThemeData.electricBlue,
                          surface: AppThemeData.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              _buildDialogListTile(
                context,
                title: l10n?.startTime ?? 'Startzeit',
                subtitle: startTime.format(context),
                icon: Icons.access_time,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppThemeData.electricBlue,
                          surface: AppThemeData.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => startTime = picked);
                  }
                },
              ),
              _buildDialogListTile(
                context,
                title: l10n?.endTime ?? 'Endzeit',
                subtitle: endTime.format(context),
                icon: Icons.access_time,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppThemeData.electricBlue,
                          surface: AppThemeData.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => endTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n?.cancel ?? 'Abbrechen',
                style: const TextStyle(color: AppThemeData.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.electricBlue,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final startDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  startTime.hour,
                  startTime.minute,
                );
                // If end <= start, treat as overnight (next day)
                DateTime endDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  endTime.hour,
                  endTime.minute,
                );
                if (!endDateTime.isAfter(startDateTime)) {
                  endDateTime = endDateTime.add(const Duration(days: 1));
                }

                final date = DateTime(
                  startDateTime.year,
                  startDateTime.month,
                  startDateTime.day,
                );

                final entry = WorkEntry(
                  id: const Uuid().v4(),
                  date: date,
                  startTime: startDateTime,
                  endTime: endDateTime,
                );

                await context.read<WorkEntriesProvider>().saveEntry(entry);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n?.entrySaved ?? 'Eintrag gespeichert'),
                      backgroundColor: AppThemeData.success,
                    ),
                  );
                }
              },
              child: Text(l10n?.save ?? 'Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedListItem(
      onTap: onTap,
      leading: Icon(icon, color: AppThemeData.electricBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppThemeData.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppThemeData.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditEntryDialog(BuildContext context, WorkEntry entry) async {
    final l10n = AppLocalizations.of(context);
    
    DateTime selectedDate = entry.date;
    TimeOfDay startTime = TimeOfDay.fromDateTime(entry.startTime);
    TimeOfDay endTime = TimeOfDay.fromDateTime(entry.endTime);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppThemeData.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeData.radiusLarge),
          ),
          title: Text(
            l10n?.editEntry ?? 'Eintrag bearbeiten',
            style: const TextStyle(color: AppThemeData.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogListTile(
                context,
                title: l10n?.date ?? 'Datum',
                subtitle: _formatDate(selectedDate),
                icon: Icons.calendar_today,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppThemeData.electricBlue,
                          surface: AppThemeData.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              _buildDialogListTile(
                context,
                title: l10n?.startTime ?? 'Startzeit',
                subtitle: startTime.format(context),
                icon: Icons.access_time,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppThemeData.electricBlue,
                          surface: AppThemeData.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => startTime = picked);
                  }
                },
              ),
              _buildDialogListTile(
                context,
                title: l10n?.endTime ?? 'Endzeit',
                subtitle: endTime.format(context),
                icon: Icons.access_time,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppThemeData.electricBlue,
                          surface: AppThemeData.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => endTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n?.cancel ?? 'Abbrechen',
                style: const TextStyle(color: AppThemeData.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.electricBlue,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final startDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  startTime.hour,
                  startTime.minute,
                );
                // If end <= start, treat as overnight (next day)
                DateTime endDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  endTime.hour,
                  endTime.minute,
                );
                if (!endDateTime.isAfter(startDateTime)) {
                  endDateTime = endDateTime.add(const Duration(days: 1));
                }

                final date = DateTime(
                  startDateTime.year,
                  startDateTime.month,
                  startDateTime.day,
                );

                final updatedEntry = entry.copyWith(
                  date: date,
                  startTime: startDateTime,
                  endTime: endDateTime,
                );

                await context.read<WorkEntriesProvider>().saveEntry(updatedEntry);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n?.entrySaved ?? 'Eintrag gespeichert'),
                      backgroundColor: AppThemeData.success,
                    ),
                  );
                }
              },
              child: Text(l10n?.save ?? 'Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
