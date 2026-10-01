import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../data/backup/backup_models.dart';
import '../../domain/errors.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share_service.dart';
import '../../widgets/widgets.dart';
import 'error_text.dart';

void _snack(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows a refused action ([ChronosException]) as its localized message;
/// anything else is logged and shown as a generic error. Busy is ignored.
Future<void> _logAndReport(
  ErrorLog log,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Object error,
  StackTrace stack,
  String where,
) async {
  if (error is ChronosException) {
    if (error.code == ChronosErrorCode.busy) return;
    _snack(messenger, chronosErrorText(l10n, error.code));
    return;
  }
  await log.record(error, stack, context: where);
  _snack(messenger, l10n.errorGeneric);
}

/// "Backup erstellen": builds the JSON backup and opens the share sheet.
Future<void> createBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final fmt = Fmt.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final share = ref.read(shareServiceProvider);
  final log = ref.read(errorLogProvider);
  final clock = ref.read(clockProvider);
  final controller = ref.read(dataControllerProvider.notifier);
  try {
    final backup = await controller.exportBackup();
    final file = await share.saveTextToTemp(backup.fileName, backup.json);
    await share.shareFile(
      file.path,
      mimeType: ShareMimeTypes.json,
      subject: l10n.dataBackupSubject(fmt.dateNumeric(clock.now().toLocal())),
    );
  } on Object catch (e, st) {
    await _logAndReport(log, messenger, l10n, e, st, 'backup');
  }
}

/// "Backup wiederherstellen": pick a file → summary → replace/merge →
/// snackbar. Invalid or newer files show a localized error.
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(dataControllerProvider.notifier);
  final share = ref.read(shareServiceProvider);
  final log = ref.read(errorLogProvider);
  try {
    final PickedFile? picked;
    try {
      picked = await share.pickBackupFile(
        dialogTitle: l10n.dataBackupPickTitle,
      );
    } on PickedFileTooLargeException {
      _snack(messenger, l10n.dataRestoreTooLarge);
      return;
    }
    if (picked == null || !context.mounted) return;

    final BackupContents contents;
    try {
      contents = controller.readBackup(picked.decodeText());
    } on FormatException {
      _snack(messenger, l10n.dataRestoreInvalid);
      return;
    }

    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (_) => RestoreBackupDialog(summary: contents.summary),
    );
    if (mode == null) return;
    final result = await controller.importBackup(contents, mode);
    _snack(
      messenger,
      mode == ImportMode.replace
          ? l10n.dataRestoreDone(result.shiftsAdded)
          : l10n.dataMergeDone(result.shiftsAdded),
    );
  } on Object catch (e, st) {
    await _logAndReport(log, messenger, l10n, e, st, 'restore');
  }
}

/// "Alle Daten löschen": counts → destructive confirmation → wipe (with an
/// automatic snapshot) → snackbar with Undo.
Future<void> deleteAllData(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(dataControllerProvider.notifier);
  final log = ref.read(errorLogProvider);
  try {
    final counts = await controller.counts();
    if (!context.mounted) return;
    if (counts.isEmpty) {
      _snack(messenger, l10n.dataNothingToDelete);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.dataDeleteTitle(
        l10n.dataCountShifts(counts.shifts),
        l10n.dataCountJobs(counts.jobs),
      ),
      message: l10n.dataDeleteMessage,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_forever_outlined,
      destructive: true,
    );
    if (!confirmed) return;
    final result = await controller.wipeAll();
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.dataDeleted,
      onUndo: () async {
        try {
          await controller.undoWipe(result);
        } on Object catch (e, st) {
          if (e is ChronosException && e.code == ChronosErrorCode.busy) return;
          await log.record(e, st, context: 'undoWipe');
          _snack(messenger, l10n.errorGeneric);
        }
      },
    );
  } on Object catch (e, st) {
    await _logAndReport(log, messenger, l10n, e, st, 'wipe');
  }
}

/// Summary of a backup before restoring: date, counts, shift range, and
/// the choice between replace and merge (pops the [ImportMode]).
class RestoreBackupDialog extends StatelessWidget {
  /// Creates the dialog.
  const RestoreBackupDialog({super.key, required this.summary});

  /// What the backup contains.
  final BackupSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final first = summary.firstShiftUtc;
    final last = summary.lastShiftUtc;
    final exported = summary.exportedAt;
    Widget line(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(bottom: ChronosSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: ChronosSpace.s12),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
    return AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.settings_backup_restore),
      title: Text(l10n.dataRestoreTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (exported != null)
            line(
              Icons.event_outlined,
              l10n.dataRestoreCreated(fmt.dateNumeric(exported.toLocal())),
            ),
          line(Icons.list_alt, l10n.dataCountShifts(summary.shiftCount)),
          line(Icons.work_outline, l10n.dataCountJobs(summary.jobCount)),
          line(
            Icons.payments_outlined,
            l10n.dataCountPayouts(summary.payoutCount),
          ),
          if (first != null && last != null)
            line(
              Icons.date_range_outlined,
              l10n.dataRestoreRange(
                fmt.dateNumeric(first.toLocal()),
                fmt.dateNumeric(last.toLocal()),
              ),
            ),
          const SizedBox(height: ChronosSpace.s8),
          Text(
            l10n.dataRestoreExplain,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ImportMode.merge),
          child: Text(l10n.dataRestoreMerge),
        ),
        FilledButton(
          style: ChronosButtonStyles.destructive(context),
          onPressed: () => Navigator.of(context).pop(ImportMode.replace),
          child: Text(l10n.dataRestoreReplace),
        ),
      ],
    );
  }
}
