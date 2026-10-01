import '../../domain/errors.dart';
import '../../l10n/app_localizations.dart';

/// The user-facing message for a refused job/data action.
String chronosErrorText(AppLocalizations l10n, ChronosErrorCode code) =>
    switch (code) {
      ChronosErrorCode.emptyName => l10n.errorRequired,
      ChronosErrorCode.lastActiveJob => l10n.jobsArchiveLastActive,
      ChronosErrorCode.noWageRate => l10n.jobsRateDeleteLast,
      ChronosErrorCode.invalidAmount => l10n.errorAmountNotPositive,
      ChronosErrorCode.backupInvalid => l10n.dataRestoreInvalid,
      ChronosErrorCode.backupNewerFormat => l10n.dataRestoreNewer,
      _ => l10n.errorGeneric,
    };
