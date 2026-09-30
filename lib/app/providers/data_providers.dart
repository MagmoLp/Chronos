import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/backup/backup_models.dart';
import '../../data/backup/data_wipe_service.dart';
import 'core_providers.dart';
import 'settings_providers.dart';
import 'shift_providers.dart';

/// A backup ready to be shared or saved.
final class BackupFile {
  /// Creates a backup file.
  const BackupFile({required this.fileName, required this.json});

  /// Suggested file name, e.g. `chronos-backup-2026-09-30.json`.
  final String fileName;

  /// File contents.
  final String json;
}

/// Backup, restore and "delete all data".
final dataControllerProvider = NotifierProvider<DataController, bool>(
  DataController.new,
  name: 'dataControllerProvider',
);

/// Data management actions (Settings → Daten).
class DataController extends BusyNotifier {
  /// Builds a JSON backup of all data and the settings.
  Future<BackupFile> exportBackup() => runBusy(() async {
    final backup = ref.read(backupServiceProvider);
    final version = await ref.read(appVersionProvider.future);
    final map = await backup.export(
      appVersion: version,
      settings: ref.read(settingsProvider),
    );
    final date = ref.read(clockProvider).today().toIso8601String();
    return BackupFile(
      fileName: 'chronos-backup-$date.json',
      json: backup.encode(map),
    );
  });

  /// Parses and validates a chosen backup file (for the summary dialog).
  /// Throws `ChronosException` (`backupInvalid` / `backupNewerFormat`).
  BackupContents readBackup(String json) =>
      ref.read(backupServiceProvider).parse(json);

  /// Restores [contents]. In [ImportMode.replace] the backup's settings
  /// (language, theme, goal, reminder) are applied too.
  Future<ImportResult> importBackup(BackupContents contents, ImportMode mode) =>
      runBusy(() async {
        final result = await ref
            .read(backupServiceProvider)
            .import(contents, mode);
        final restored = result.settings;
        if (mode == ImportMode.replace && restored != null) {
          final settings = ref.read(settingsProvider.notifier);
          await settings.replace(
            restored.copyWith(
              onboardingDone: true,
              notificationPrimerShown: ref
                  .read(settingsProvider)
                  .notificationPrimerShown,
            ),
          );
        }
        await notifyShiftSideEffects(ref);
        return result;
      });

  /// How much data exists (for the confirmation dialog).
  Future<DataCounts> counts() => ref.read(dataWipeServiceProvider).counts();

  /// Deletes all data after writing an automatic snapshot. Keep the result
  /// for [undoWipe].
  Future<WipeResult> wipeAll() => runBusy(() async {
    final version = await ref.read(appVersionProvider.future);
    final result = await ref
        .read(dataWipeServiceProvider)
        .wipeAll(appVersion: version, settings: ref.read(settingsProvider));
    await notifyShiftSideEffects(ref);
    return result;
  });

  /// Restores the data deleted by [wipeAll].
  Future<ImportResult> undoWipe(WipeResult result) => runBusy(() async {
    final restored = await ref.read(dataWipeServiceProvider).undo(result);
    await notifyShiftSideEffects(ref);
    return restored;
  });
}
