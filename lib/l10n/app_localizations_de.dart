// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Chronos';

  @override
  String get navToday => 'Heute';

  @override
  String get navShifts => 'Schichten';

  @override
  String get navInsights => 'Übersicht';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDuplicate => 'Duplizieren';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDiscard => 'Verwerfen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonExport => 'Exportieren';

  @override
  String get commonDismiss => 'Ausblenden';

  @override
  String get commonMoreOptions => 'Weitere Optionen';

  @override
  String get commonOpenSettings => 'Einstellungen öffnen';

  @override
  String get commonLoading => 'Wird geladen …';

  @override
  String get commonAll => 'Alle';

  @override
  String get statusPaid => 'Bezahlt';

  @override
  String get statusOpen => 'Offen';

  @override
  String get statusRunning => 'Läuft';

  @override
  String get statusPaused => 'Pausiert';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String formatToday(String date) {
    return 'Heute, $date';
  }

  @override
  String formatHours(String value) {
    return '$value h';
  }

  @override
  String formatMinutes(String value) {
    return '$value min';
  }

  @override
  String formatRatePerHour(String amount) {
    return '$amount/h';
  }

  @override
  String durationSpokenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String durationSpokenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String durationSpokenHoursMinutes(String hours, String minutes) {
    return '$hours $minutes';
  }

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuch es noch einmal.';

  @override
  String get errorLoadFailed => 'Deine Daten konnten nicht geladen werden.';

  @override
  String get errorSaveFailed =>
      'Speichern hat nicht geklappt. Bitte versuch es noch einmal.';

  @override
  String get errorRequired => 'Bitte gib einen Wert ein';

  @override
  String errorInvalidAmount(String example) {
    return 'Gib einen Betrag wie $example ein';
  }

  @override
  String get errorAmountNotPositive => 'Der Betrag muss größer als 0 sein';

  @override
  String errorInvalidTime(String example) {
    return 'Gib eine Uhrzeit wie $example ein';
  }

  @override
  String get timeFieldPick => 'Uhrzeit wählen';

  @override
  String timeFieldEarlier(int minutes) {
    return '$minutes Minuten früher';
  }

  @override
  String timeFieldLater(int minutes) {
    return '$minutes Minuten später';
  }

  @override
  String get startupLoading => 'Chronos startet …';

  @override
  String startupMigratedNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge aus Chronos 1 übernommen',
      one: '1 Eintrag aus Chronos 1 übernommen',
    );
    return '$_temp0';
  }

  @override
  String get startupMigratedReview => 'Prüfen';

  @override
  String get onboardingDefaultJobName => 'Mein Job';

  @override
  String get onboardingWelcomeTitle =>
      'Schichten erfassen. Lohn live wachsen sehen.';

  @override
  String get onboardingWelcomeBody =>
      'Funktioniert offline. Deine Daten bleiben auf deinem Handy.';

  @override
  String get onboardingStart => 'Los geht’s';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get onboardingJobTitle => 'Dein Job';

  @override
  String get onboardingJobSubtitle =>
      'Trag deinen Stundenlohn ein. Alles andere kannst du später ändern.';

  @override
  String get onboardingNameLabel => 'Name (optional)';

  @override
  String get onboardingRateLabel => 'Stundenlohn';

  @override
  String get onboardingRateHelper => 'Brutto pro Stunde';

  @override
  String get onboardingMoreJobsLater =>
      'Weitere Jobs kannst du später in den Einstellungen anlegen.';

  @override
  String wageCheckTitle(String rate) {
    return '$rate übernommen – stimmt das?';
  }

  @override
  String get wageCheckTooHigh =>
      'Das ist ungewöhnlich hoch. Die alte Version hat manchmal das Komma verschluckt, aus 12,50 wurde dann 1250.';

  @override
  String get wageCheckTooLow =>
      'Das ist ungewöhnlich niedrig für einen Stundenlohn.';

  @override
  String get wageCheckUnusuallyHigh =>
      'Das ist ungewöhnlich hoch für einen Stundenlohn.';

  @override
  String get wageCheckFieldLabel => 'Richtiger Stundenlohn';

  @override
  String get wageCheckFieldHelper =>
      'Gilt für den Job und alle übernommenen Schichten.';

  @override
  String get wageCheckFix => 'Diesen Lohn verwenden';

  @override
  String wageCheckKeep(String rate) {
    return '$rate beibehalten';
  }

  @override
  String wageCheckFixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stundenlohn korrigiert · $count Schichten angepasst',
      one: 'Stundenlohn korrigiert · 1 Schicht angepasst',
      zero: 'Stundenlohn korrigiert',
    );
    return '$_temp0';
  }

  @override
  String wageCheckConfirmTitle(String rate) {
    return '$rate – stimmt das?';
  }

  @override
  String get wageCheckConfirmYes => 'Ja, stimmt';

  @override
  String get wageCheckConfirmEdit => 'Ändern';

  @override
  String get recoveryTitle => 'Chronos konnte nicht starten';

  @override
  String get recoveryMessage =>
      'Deine Daten konnten nicht geladen werden. Es wurde nichts gelöscht. Versuch es noch einmal oder teile die Rohdaten und einen Fehlerbericht, damit sich das Problem beheben lässt.';

  @override
  String get recoveryShareRawData => 'Rohdaten teilen';

  @override
  String get recoveryShareErrorReport => 'Fehlerbericht teilen';

  @override
  String get recoveryDetails => 'Technische Details';

  @override
  String get recoveryRawDataSubject => 'Chronos-Rohdaten';

  @override
  String get recoveryErrorReportSubject => 'Chronos-Fehlerbericht';

  @override
  String get recoveryShareFailed => 'Die Datei konnte nicht erstellt werden.';

  @override
  String get reviewTitle => 'Einträge prüfen';

  @override
  String get reviewIntro =>
      'Diese Einträge aus der alten Version sehen ungewöhnlich aus. Prüf sie und korrigiere sie bei Bedarf – es wurde nichts automatisch geändert.';

  @override
  String reviewSectionShifts(int count) {
    return 'Zu prüfende Schichten ($count)';
  }

  @override
  String reviewShiftSummary(String times, String duration) {
    return '$times · $duration';
  }

  @override
  String get reviewReasonTooLong => 'Länger als 16 Stunden';

  @override
  String get reviewReasonExactly23or24h =>
      'Genau 23 oder 24 Stunden – das Ende stimmt vielleicht nicht';

  @override
  String get reviewReasonDuplicateTimes =>
      'Gleiche Zeiten wie eine andere Schicht';

  @override
  String get reviewReasonDuplicateLegacyId =>
      'Doppelter Eintrag aus der alten Version';

  @override
  String get reviewReasonOverlap =>
      'Überschneidet sich mit einer anderen Schicht';

  @override
  String get reviewReasonDstDay =>
      'Am Tag der Zeitumstellung – prüf die Uhrzeiten';

  @override
  String get reviewDismiss => 'Passt so';

  @override
  String get reviewDismissAll => 'Alle als geprüft markieren';

  @override
  String reviewDismissAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge als geprüft markieren?',
      one: '1 Eintrag als geprüft markieren?',
    );
    return '$_temp0';
  }

  @override
  String get reviewDismissAllMessage =>
      'Die Schichten bleiben unverändert, nur die Hinweise verschwinden.';

  @override
  String get reviewShiftDeleted => 'Diese Schicht wurde gelöscht.';

  @override
  String reviewSectionFailures(int count) {
    return 'Nicht übernommen ($count)';
  }

  @override
  String get reviewFailuresIntro =>
      'Diese Einträge konnten nicht gelesen werden. Sie sind nicht verloren: Die Originaldaten bleiben auf deinem Handy und lassen sich teilen.';

  @override
  String get reviewFailureInvalidJson =>
      'Die gespeicherten Daten sind unlesbar';

  @override
  String get reviewFailureNotAList => 'Die Liste der Einträge ist unlesbar';

  @override
  String get reviewFailureNotAnObject => 'Der Eintrag ist unlesbar';

  @override
  String get reviewFailureMissingStart => 'Die Startzeit fehlt';

  @override
  String get reviewFailureInvalidStart => 'Die Startzeit ist unlesbar';

  @override
  String get reviewFailureMissingEnd => 'Die Endzeit fehlt';

  @override
  String get reviewFailureInvalidEnd => 'Die Endzeit ist unlesbar';

  @override
  String get reviewFailureEndNotAfterStart =>
      'Das Ende liegt nicht nach dem Start';

  @override
  String get reviewFailureInvalidActiveSession =>
      'Die laufende Sitzung ist unlesbar';

  @override
  String get reviewFailureRunningShiftExists =>
      'Es lief bereits eine andere Schicht';

  @override
  String get reviewFailureInvalidSettings =>
      'Die Einstellungen waren unlesbar – es gelten die Standardwerte';

  @override
  String get reviewFailureInsertFailed =>
      'Der Eintrag konnte nicht gespeichert werden';

  @override
  String get reviewEmptyTitle => 'Alles geprüft';

  @override
  String get reviewEmptyMessage =>
      'Es gibt keine Einträge aus der alten Version mehr zu prüfen.';

  @override
  String get notificationChannelRunningName => 'Laufende Schicht';

  @override
  String get notificationChannelRunningDescription =>
      'Zeigt die laufende Schicht mit Stoppuhr.';

  @override
  String get notificationChannelRemindersName => 'Erinnerungen';

  @override
  String get notificationChannelRemindersDescription =>
      'Fragt nach langen Schichten, ob du noch arbeitest.';

  @override
  String get notificationRunningTitle => 'Schicht läuft';

  @override
  String notificationRunningTitleWithJob(String job) {
    return 'Schicht läuft · $job';
  }

  @override
  String notificationRunningBody(String time, String rate) {
    return 'seit $time · $rate';
  }

  @override
  String notificationPausedBody(String time) {
    return 'Pausiert seit $time';
  }

  @override
  String get notificationActionPause => 'Pause';

  @override
  String get notificationActionResume => 'Fortsetzen';

  @override
  String get notificationActionFinish => 'Beenden';

  @override
  String get notificationReminderTitle => 'Arbeitest du noch?';

  @override
  String notificationReminderBody(String time) {
    return 'Deine Schicht läuft seit $time. Tippe auf „Beenden“, wenn du fertig bist.';
  }
}
