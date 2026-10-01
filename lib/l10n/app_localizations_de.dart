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
  String get exportTitle => 'Exportieren';

  @override
  String get exportRange => 'Zeitraum';

  @override
  String get exportRangeThisWeek => 'Diese Woche';

  @override
  String get exportRangeThisMonth => 'Dieser Monat';

  @override
  String get exportRangeLastMonth => 'Letzter Monat';

  @override
  String get exportRangeCustom => 'Zeitraum wählen';

  @override
  String exportRangeValue(String start, String end) {
    return '$start – $end';
  }

  @override
  String get exportJob => 'Job';

  @override
  String get exportAllJobs => 'Alle Jobs';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get exportFormatPdfHelp =>
      'Stundenzettel mit Summen und Unterschriftszeilen – fertig zum Abgeben.';

  @override
  String get exportFormatCsvHelp => 'Tabelle für Excel oder Google Tabellen.';

  @override
  String get exportName => 'Dein Name (optional)';

  @override
  String get exportNameHelp => 'Steht oben auf dem Stundenzettel';

  @override
  String get exportIncludeNotes => 'Notizen einschließen';

  @override
  String exportSummary(int count, String hours, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten · $hours · $amount',
      one: '1 Schicht · $hours · $amount',
    );
    return '$_temp0';
  }

  @override
  String get exportEmpty => 'In diesem Zeitraum gibt es keine Schichten.';

  @override
  String get exportPreparing => 'Wird erstellt…';

  @override
  String get exportFailed =>
      'Das Exportieren hat nicht geklappt. Bitte versuch es noch einmal.';

  @override
  String get exportFileBase => 'stundenzettel';

  @override
  String exportSubject(String period) {
    return 'Stundenzettel $period';
  }

  @override
  String get exportColDate => 'Datum';

  @override
  String get exportColStart => 'Start';

  @override
  String get exportColEnd => 'Ende';

  @override
  String get exportColBreak => 'Pause';

  @override
  String get exportColBreakMinutes => 'Pause (min)';

  @override
  String get exportColHours => 'Stunden';

  @override
  String get exportColRate => 'Stundenlohn';

  @override
  String get exportColRateShort => 'Lohn';

  @override
  String get exportColAmount => 'Betrag';

  @override
  String get exportColTips => 'Trinkgeld';

  @override
  String get exportColStatus => 'Status';

  @override
  String get exportColJob => 'Job';

  @override
  String get exportColNote => 'Notiz';

  @override
  String get exportTotal => 'Summe';

  @override
  String get exportPdfTitle => 'Stundenzettel';

  @override
  String get exportPdfName => 'Name';

  @override
  String get exportPdfPeriod => 'Zeitraum';

  @override
  String exportPdfRowDate(String weekday, String date) {
    return '$weekday $date';
  }

  @override
  String get exportPdfSignatureEmployee =>
      'Datum, Unterschrift Arbeitnehmer:in';

  @override
  String get exportPdfSignatureEmployer => 'Datum, Unterschrift Arbeitgeber:in';

  @override
  String exportPdfCreatedOn(String date) {
    return 'Erstellt am $date mit Chronos';
  }

  @override
  String exportPdfPage(int page, int count) {
    return 'Seite $page von $count';
  }

  @override
  String get insightsPeriodWeek => 'Woche';

  @override
  String get insightsPeriodMonth => 'Monat';

  @override
  String get insightsPeriodYear => 'Jahr';

  @override
  String get insightsPeriodChoice => 'Zeitraum-Länge';

  @override
  String get insightsPrevious => 'Vorheriger Zeitraum';

  @override
  String get insightsNext => 'Nächster Zeitraum';

  @override
  String insightsWeekTitle(String start, String end, String year) {
    return '$start – $end $year';
  }

  @override
  String get insightsStatHours => 'Stunden';

  @override
  String get insightsStatEarned => 'Verdient';

  @override
  String get insightsStatOpen => 'Offen';

  @override
  String get insightsStatAverage => 'Ø Stundenlohn inkl. Trinkgeld';

  @override
  String get insightsStatTips => 'Trinkgeld';

  @override
  String insightsShiftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten',
      one: '1 Schicht',
      zero: 'Keine Schichten',
    );
    return '$_temp0';
  }

  @override
  String get insightsNoValue => '–';

  @override
  String get insightsChartDays => 'Verdienst pro Tag';

  @override
  String get insightsChartMonths => 'Verdienst pro Monat';

  @override
  String get insightsChartHint => 'Tippe auf einen Balken für Details';

  @override
  String insightsChartSelection(String label, String amount, String hours) {
    return '$label: $amount · $hours';
  }

  @override
  String insightsChartBar(String label, String amount, String hours) {
    return '$label: $amount, $hours';
  }

  @override
  String get insightsChartEmpty =>
      'In diesem Zeitraum gibt es noch keine Schichten.';

  @override
  String insightsAxisEuros(String value) {
    return '$value €';
  }

  @override
  String get insightsGoalTitle => 'Monatsziel';

  @override
  String get insightsLimitTitle => 'Monatsgrenze';

  @override
  String insightsGoalProgress(String earned, String target) {
    return '$earned / $target';
  }

  @override
  String insightsGoalRemaining(String amount) {
    return 'Noch $amount';
  }

  @override
  String get insightsGoalReached => 'Ziel erreicht';

  @override
  String insightsLimitRemaining(String amount) {
    return 'Noch $amount bis zur Grenze';
  }

  @override
  String insightsLimitWarning(String amount) {
    return 'Fast an der Grenze – noch $amount';
  }

  @override
  String insightsLimitExceeded(String amount) {
    return 'Grenze um $amount überschritten';
  }

  @override
  String insightsGoalMonth(String month) {
    return 'Aktueller Monat: $month';
  }

  @override
  String get insightsGoalSetUp => 'Monatsziel oder -grenze festlegen';

  @override
  String get insightsByJob => 'Nach Job';

  @override
  String insightsJobLine(String hours, String amount) {
    return '$hours · $amount';
  }

  @override
  String get insightsPayouts => 'Auszahlungen';

  @override
  String get insightsPayoutsEmpty =>
      'In diesem Zeitraum gibt es keine Auszahlungen.';

  @override
  String insightsPayoutMore(String amount) {
    return '$amount mehr als erwartet';
  }

  @override
  String insightsPayoutLess(String amount) {
    return '$amount weniger als erwartet';
  }

  @override
  String get insightsPayoutExact => 'Wie erwartet';

  @override
  String get insightsExport => 'Diesen Zeitraum exportieren';

  @override
  String get settingsSectionGeneral => 'Allgemein';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsSectionWork => 'Arbeit';

  @override
  String get settingsJobs => 'Jobs & Stundenlohn';

  @override
  String settingsJobsOne(String name, String rate) {
    return '$name · $rate';
  }

  @override
  String settingsJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jobs',
      one: '1 Job',
      zero: 'Noch keine Jobs',
    );
    return '$_temp0';
  }

  @override
  String get settingsGoal => 'Monatsziel oder -grenze';

  @override
  String get settingsGoalOff => 'Aus';

  @override
  String settingsGoalGoalValue(String amount) {
    return 'Ziel: $amount';
  }

  @override
  String settingsGoalLimitValue(String amount) {
    return 'Grenze: $amount';
  }

  @override
  String get settingsGoalTypeGoal => 'Ziel';

  @override
  String get settingsGoalTypeLimit => 'Grenze';

  @override
  String get settingsGoalAmount => 'Betrag pro Monat';

  @override
  String get settingsGoalHelpOff => 'Kein Fortschrittsbalken in der Übersicht.';

  @override
  String get settingsGoalHelpGoal =>
      'Zeigt, wie nah du deinem Monatsziel bist.';

  @override
  String get settingsGoalHelpLimit =>
      'Warnt ab 80 % – z. B. bei der Minijob-Grenze von 603 €.';

  @override
  String get settingsReminder => 'Erinnerung „Arbeitest du noch?“';

  @override
  String get settingsReminderOff => 'Aus';

  @override
  String settingsReminderHours(int hours) {
    return 'Nach $hours h';
  }

  @override
  String get settingsReminderHelp =>
      'Erinnert dich, wenn eine Schicht nach dieser Zeit noch läuft.';

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsNotificationsOn => 'Erlaubt';

  @override
  String get settingsNotificationsOnHint =>
      'Laufende Schicht und Erinnerungen erscheinen in der Statusleiste';

  @override
  String get settingsNotificationsOffTitle => 'Ausgeschaltet';

  @override
  String get settingsNotificationsOff =>
      'Die laufende Schicht erscheint nicht in der Statusleiste. Tippe hier, um Benachrichtigungen zu erlauben.';

  @override
  String get settingsNotificationsOpen => 'Systemeinstellungen öffnen';

  @override
  String get settingsSectionData => 'Daten';

  @override
  String get dataExport => 'Exportieren';

  @override
  String get dataExportSubtitle => 'PDF-Stundenzettel oder CSV-Tabelle';

  @override
  String get dataBackupCreate => 'Backup erstellen';

  @override
  String get dataBackupCreateSubtitle => 'Alle Daten als Datei sichern';

  @override
  String dataBackupSubject(String date) {
    return 'Chronos-Backup $date';
  }

  @override
  String get dataBackupRestore => 'Backup wiederherstellen';

  @override
  String get dataBackupRestoreSubtitle => 'Aus einer Chronos-Backup-Datei';

  @override
  String get dataBackupPickTitle => 'Chronos-Backup auswählen';

  @override
  String get dataRestoreTitle => 'Dieses Backup wiederherstellen?';

  @override
  String dataRestoreCreated(String date) {
    return 'Erstellt am $date';
  }

  @override
  String dataRestoreRange(String start, String end) {
    return 'Schichten vom $start bis $end';
  }

  @override
  String dataCountShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten',
      one: '1 Schicht',
    );
    return '$_temp0';
  }

  @override
  String dataCountJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jobs',
      one: '1 Job',
    );
    return '$_temp0';
  }

  @override
  String dataCountPayouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Auszahlungen',
      one: '1 Auszahlung',
    );
    return '$_temp0';
  }

  @override
  String get dataRestoreExplain =>
      '„Ersetzen“ löscht zuerst deine aktuellen Daten. „Zusammenführen“ ergänzt nur, was fehlt.';

  @override
  String get dataRestoreReplace => 'Ersetzen';

  @override
  String get dataRestoreMerge => 'Zusammenführen';

  @override
  String dataRestoreDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backup wiederhergestellt · $count Schichten',
      one: 'Backup wiederhergestellt · 1 Schicht',
      zero: 'Backup wiederhergestellt',
    );
    return '$_temp0';
  }

  @override
  String dataMergeDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten hinzugefügt',
      one: '1 Schicht hinzugefügt',
      zero: 'Nichts Neues – alles war schon da',
    );
    return '$_temp0';
  }

  @override
  String get dataRestoreInvalid =>
      'Diese Datei ist kein gültiges Chronos-Backup.';

  @override
  String get dataRestoreNewer =>
      'Dieses Backup stammt aus einer neueren Chronos-Version. Bitte aktualisiere zuerst die App.';

  @override
  String get dataRestoreTooLarge => 'Diese Datei ist zu groß für ein Backup.';

  @override
  String get dataDeleteAll => 'Alle Daten löschen';

  @override
  String get dataDeleteAllSubtitle =>
      'Vorher wird automatisch eine Sicherung gespeichert';

  @override
  String dataDeleteTitle(String shifts, String jobs) {
    return '$shifts und $jobs löschen?';
  }

  @override
  String get dataDeleteMessage =>
      'Auszahlungen werden ebenfalls gelöscht. Vorher wird eine Sicherung auf dem Gerät gespeichert, und du kannst es direkt danach rückgängig machen.';

  @override
  String get dataDeleted => 'Alle Daten gelöscht';

  @override
  String get dataNothingToDelete => 'Es gibt keine Daten zum Löschen.';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get aboutVersion => 'Version';

  @override
  String aboutVersionValue(String version, String build) {
    return '$version (Build $build)';
  }

  @override
  String get aboutPrivacy => 'Datenschutzerklärung';

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutErrorReport => 'Fehlerbericht teilen';

  @override
  String get aboutErrorReportSubtitle =>
      'Lokales Fehlerprotokoll – wird nur gesendet, wenn du es teilst';

  @override
  String get aboutErrorReportEmpty => 'Keine Fehler protokolliert';

  @override
  String get aboutErrorReportSubject => 'Chronos-Fehlerbericht';

  @override
  String get aboutFileBase => 'fehlerbericht';

  @override
  String jobsRateSince(String rate, String date) {
    return '$rate seit $date';
  }

  @override
  String get jobsAdd => 'Job hinzufügen';

  @override
  String get jobsActiveSection => 'Aktiv';

  @override
  String get jobsArchivedSection => 'Archiviert';

  @override
  String get jobsNewTitle => 'Neuer Job';

  @override
  String get jobsEditTitle => 'Job bearbeiten';

  @override
  String get jobsName => 'Name';

  @override
  String get jobsNameHint => 'z. B. Café Müller';

  @override
  String get jobsColor => 'Farbe';

  @override
  String get jobsColorBlue => 'Blau';

  @override
  String get jobsColorTeal => 'Petrol';

  @override
  String get jobsColorOchre => 'Ocker';

  @override
  String get jobsColorRaspberry => 'Himbeere';

  @override
  String get jobsColorViolet => 'Violett';

  @override
  String get jobsColorGreen => 'Grün';

  @override
  String get jobsRate => 'Stundenlohn';

  @override
  String get jobsRateNewHelp =>
      'Spätere Lohnänderungen kannst du mit Startdatum ergänzen.';

  @override
  String get jobsRounding => 'Rundung der Stoppuhr-Schichten';

  @override
  String get jobsRoundingOff => 'Aus';

  @override
  String get jobsRoundingHelp =>
      'Start und Ende werden beim Beenden auf den nächsten Schritt gerundet. Selbst eingetragene Schichten werden nie gerundet.';

  @override
  String get jobsRateHistory => 'Lohnhistorie';

  @override
  String jobsRateFrom(String date) {
    return 'ab $date';
  }

  @override
  String get jobsRateCurrent => 'Aktuell';

  @override
  String get jobsRateAdd => 'Neuer Lohn ab …';

  @override
  String get jobsRateDelete => 'Lohn löschen';

  @override
  String get jobsRateDeleteLast =>
      'Der letzte Lohn kann nicht gelöscht werden.';

  @override
  String get jobsRateDeleted => 'Lohn gelöscht';

  @override
  String get jobsRateDialogTitle => 'Neuer Stundenlohn';

  @override
  String get jobsRateValidFrom => 'Gültig ab';

  @override
  String get jobsRateRecalc => 'Offene Schichten ab diesem Datum neu berechnen';

  @override
  String get jobsRateRecalcHelp =>
      'Bezahlte Schichten behalten immer ihren Lohn.';

  @override
  String jobsRateSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lohn gespeichert · $count Schichten neu berechnet',
      one: 'Lohn gespeichert · 1 Schicht neu berechnet',
      zero: 'Lohn gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get jobsArchive => 'Job archivieren';

  @override
  String get jobsUnarchive => 'Job wiederherstellen';

  @override
  String get jobsArchiveHelp =>
      'Archivierte Jobs behalten ihre Schichten, werden aber beim Starten und Nachtragen nicht mehr angeboten.';

  @override
  String get jobsArchiveLastActive => 'Mindestens ein Job muss aktiv bleiben.';

  @override
  String jobsArchived(String name) {
    return '$name archiviert';
  }

  @override
  String jobsUnarchived(String name) {
    return '$name ist wieder aktiv';
  }

  @override
  String get jobsDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get privacyUpdated =>
      'Zuletzt aktualisiert: 30. September 2026 (gilt ab Version 2.0)';

  @override
  String get privacyIntro =>
      'Diese Datenschutzerklärung gilt für die Android-App Chronos – Stundenlohn Tracker, entwickelt von Paul Hübner.';

  @override
  String get privacyShortTitle => 'Kurz gesagt';

  @override
  String get privacyShortBody =>
      'Alles, was du in Chronos eingibst, bleibt auf deinem Gerät. Es gibt kein Konto, keine Werbung, keine Analyse und kein Tracking. Die App hat keine Internet-Berechtigung und sendet nichts an den Entwickler oder an Dritte.';

  @override
  String get privacyStoredTitle => 'Welche Daten die App speichert';

  @override
  String get privacyStoredIntro =>
      'Chronos speichert ausschließlich im privaten Speicherbereich der App auf deinem Gerät:';

  @override
  String get privacyStoredShifts =>
      'Schichten mit Start, Ende, Pausen, Trinkgeld, Notizen und dem Status „offen/bezahlt“,';

  @override
  String get privacyStoredJobs =>
      'Jobs mit Namen, Farbe, Stundenlohn und Lohnhistorie,';

  @override
  String get privacyStoredPayouts => 'erfasste Auszahlungen,';

  @override
  String get privacyStoredSettings =>
      'Einstellungen (z. B. Sprache, Design, Monatsziel, Erinnerung),';

  @override
  String get privacyStoredErrorLog =>
      'ein lokales Fehlerprotokoll mit technischen Fehlermeldungen zur Fehlersuche.';

  @override
  String get privacyStoredNoAccess =>
      'Der Entwickler hat auf diese Daten keinen Zugriff.';

  @override
  String get privacyExceptionsTitle => 'Ausnahmen, die du selbst steuerst';

  @override
  String get privacyAutoBackupTitle => 'Android-Sicherung (Auto Backup)';

  @override
  String get privacyAutoBackupBody =>
      'Ist in den Android-Einstellungen deines Geräts die Sicherung eingeschaltet, sichert Android die Daten von Chronos (Datenbank und Einstellungen) automatisch in deinem eigenen Google-Konto und stellt sie bei einer Neuinstallation oder beim Umzug auf ein neues Gerät wieder her. Das ist eine Funktion des Betriebssystems, die Google für dich bereitstellt; der Entwickler kann diese Sicherungen nicht einsehen. Ab Android 9 sind sie mit deiner Displaysperre Ende-zu-Ende verschlüsselt. Du kannst die Sicherung in den Android-Einstellungen (meist unter „System“ bzw. „Google“ → „Sicherung“) ausschalten und bestehende Sicherungen in deinem Google-Konto löschen. Beim direkten Übertragen auf ein neues Gerät (Kabel oder WLAN) werden dieselben Daten mitgenommen.';

  @override
  String get privacyExportTitle => 'Export, Backup-Datei und Fehlerbericht';

  @override
  String get privacyExportBody =>
      'Nur wenn du es ausdrücklich auslöst, erstellt Chronos eine Datei (PDF-Stundenzettel, CSV, Backup als JSON oder das Fehlerprotokoll) und öffnet das Android-Teilen-Menü. Du entscheidest, an welche App oder welchen Empfänger die Datei geht (z. B. E-Mail, Messenger, Cloud-Speicher). Für die weitere Verarbeitung gelten dann die Bestimmungen dieses Dienstes.';

  @override
  String get privacyRestoreTitle => 'Backup wiederherstellen';

  @override
  String get privacyRestoreBody =>
      'Über die Dateiauswahl von Android liest Chronos nur die eine Datei, die du auswählst.';

  @override
  String get privacyPermissionsTitle => 'Benachrichtigungen und Berechtigungen';

  @override
  String get privacyPermissionNotifications =>
      'Benachrichtigungen anzeigen (optional): für die laufende Schicht mit Stoppuhr und die Erinnerung „Arbeitest du noch?“. Die Benachrichtigungen werden auf dem Gerät erzeugt; es wird kein Push-Dienst verwendet. Ohne diese Berechtigung funktioniert die App normal weiter.';

  @override
  String get privacyPermissionBoot =>
      'Nach dem Gerätestart ausführen: damit eine geplante Erinnerung nach einem Neustart erneut geplant wird.';

  @override
  String get privacyPermissionsNone =>
      'Chronos fordert keine Berechtigungen für Internet, Standort, Kontakte, Kamera oder den gemeinsamen Speicher an.';

  @override
  String get privacyNoSharingTitle =>
      'Keine Weitergabe, keine Werbung, kein Tracking';

  @override
  String get privacyNoSharingBody =>
      'Chronos enthält keine Werbung, keine Analyse-Tools, keine Tracking-SDKs und keine Absturzberichte an externe Server. Es werden keine Daten verkauft oder an Dritte weitergegeben.';

  @override
  String get privacyDeleteTitle => 'Daten löschen';

  @override
  String get privacyDeleteBody =>
      'In der App unter „Einstellungen → Daten → Alle Daten löschen“, oder indem du die App deinstallierst bzw. in den Android-Einstellungen ihren Speicher löschst. Sicherungen in deinem Google-Konto verwaltest du in den Google- bzw. Android-Einstellungen.';

  @override
  String get privacyChangesTitle => 'Änderungen';

  @override
  String get privacyChangesBody =>
      'Wenn sich an dieser Erklärung etwas ändert, wird diese Seite aktualisiert. Maßgeblich ist das Datum oben.';

  @override
  String get privacyContactTitle => 'Kontakt';

  @override
  String get privacyContactBody =>
      'Bei Fragen zum Datenschutz erreichst du mich unter: paulvincent.huebner@gmail.com';

  @override
  String get todayEarnedToday => 'Heute verdient';

  @override
  String get todayOpenLabel => 'Offen';

  @override
  String get todayOpenTotal => 'Offen gesamt';

  @override
  String get todayThisShift => 'Davon diese Schicht';

  @override
  String todayShiftsHours(int count, String hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten · $hours',
      one: '1 Schicht · $hours',
    );
    return '$_temp0';
  }

  @override
  String get todayNothingOpen => 'Keine offenen Schichten';

  @override
  String get todayRecordPayout => 'Auszahlung erfassen';

  @override
  String todayStatusWithJob(String status, String job) {
    return '$status · $job';
  }

  @override
  String todayPausedSince(String time) {
    return 'Pausiert seit $time';
  }

  @override
  String todaySince(String time) {
    return 'seit $time';
  }

  @override
  String get todayAdjustStart => 'Startzeit ändern';

  @override
  String todayWorkedSemantics(String duration) {
    return 'Gearbeitet: $duration';
  }

  @override
  String todayBreak(String duration) {
    return 'Pause $duration';
  }

  @override
  String get todayStartShift => 'Schicht starten';

  @override
  String get todayStartedEarlier => 'Früher angefangen?';

  @override
  String get todayStartTimeHelp => 'Wann hast du angefangen?';

  @override
  String get todayChooseJob => 'Job wählen';

  @override
  String todayJobSemantics(String job) {
    return 'Job: $job';
  }

  @override
  String get todayPause => 'Pause';

  @override
  String get todayResume => 'Fortsetzen';

  @override
  String get todayFinish => 'Beenden';

  @override
  String get todayThisWeek => 'Diese Woche';

  @override
  String todayWeekFigures(String hours, String amount) {
    return '$hours · $amount';
  }

  @override
  String get todayLastShift => 'Letzte Schicht';

  @override
  String todayLastShiftDetails(String date, String times, String duration) {
    return '$date, $times · $duration';
  }

  @override
  String get todayShiftsTodayTitle => 'Heutige Schichten';

  @override
  String get todayNoShiftsToday => 'Heute noch keine abgeschlossene Schicht.';

  @override
  String todayReviewHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count übernommene Einträge prüfen',
      one: '1 übernommenen Eintrag prüfen',
    );
    return '$_temp0';
  }

  @override
  String get todayReviewAction => 'Prüfen';

  @override
  String get todayNotificationsOff =>
      'Benachrichtigungen sind aus – die laufende Schicht erscheint nicht auf dem Sperrbildschirm.';

  @override
  String get todayPrimerTitle => 'Deine Schicht auf dem Sperrbildschirm';

  @override
  String get todayPrimerBody =>
      'Während eine Schicht läuft, zeigt Chronos sie in einer stillen Benachrichtigung. Dort kannst du pausieren oder beenden, ohne die App zu öffnen. Im Hintergrund läuft nichts.';

  @override
  String get todayPrimerAllow => 'Benachrichtigungen erlauben';

  @override
  String get todayPrimerLater => 'Nicht jetzt';

  @override
  String get todayOverlapTitle => 'Überschneidung mit einer Schicht';

  @override
  String todayOverlapMessage(String shifts) {
    return 'Diese Startzeit überschneidet sich mit: $shifts';
  }

  @override
  String get todayOverlapStartAnyway => 'Trotzdem starten';

  @override
  String get todayOverlapChangeAnyway => 'Trotzdem ändern';

  @override
  String todayStartChanged(String time) {
    return 'Start auf $time geändert';
  }

  @override
  String get todayErrorStartInFuture =>
      'Die Startzeit darf nicht in der Zukunft liegen.';

  @override
  String get todayErrorStartAfterBreak =>
      'Der Start muss vor Beginn der laufenden Pause liegen.';

  @override
  String get todayErrorAlreadyRunning => 'Es läuft bereits eine Schicht.';

  @override
  String get todayErrorNoRunningShift => 'Es läuft keine Schicht.';

  @override
  String get todayErrorNoWage =>
      'Für diesen Job ist noch kein Stundenlohn hinterlegt. Trag ihn in den Einstellungen ein.';

  @override
  String get todayErrorJobNotFound => 'Diesen Job gibt es nicht mehr.';

  @override
  String get todayErrorShiftNotFound => 'Diese Schicht gibt es nicht mehr.';

  @override
  String todayShiftSaved(String duration, String amount) {
    return 'Schicht gespeichert · $duration · $amount';
  }

  @override
  String get todayShiftDiscarded => 'Schicht verworfen';

  @override
  String get todayFinishSheetTitle => 'Schicht beenden';

  @override
  String get todayFinishStart => 'Start';

  @override
  String get todayFinishEnd => 'Ende';

  @override
  String todayFinishRoundedTimes(String recorded, String billed) {
    return 'Erfasst $recorded, abgerechnet $billed';
  }

  @override
  String todayFinishRoundingNote(int minutes) {
    return 'Auf $minutes Minuten gerundet (Job-Einstellung)';
  }

  @override
  String todayFinishBilledEnd(String time) {
    return 'Abgerechnet: $time';
  }

  @override
  String todayFinishEndDate(String date) {
    return 'am $date';
  }

  @override
  String get todayFinishBreak => 'Pause';

  @override
  String get todayMinutesUnit => 'min';

  @override
  String get todayFinishWorked => 'Arbeitszeit';

  @override
  String todayFinishCalculation(String duration, String rate) {
    return '$duration × $rate';
  }

  @override
  String get todayFinishTips => 'Trinkgeld (optional)';

  @override
  String get todayFinishNote => 'Notiz (optional)';

  @override
  String get todayFinishKeepRunning => 'Weiterlaufen lassen';

  @override
  String get todayFinishErrorEndNotAfterStart =>
      'Das Ende muss nach dem Start liegen.';

  @override
  String get todayFinishErrorBreakTooLong =>
      'Die Pause muss kürzer als die Schicht sein.';

  @override
  String get todayFinishErrorEndInFuture =>
      'Das Ende darf nicht in der Zukunft liegen.';

  @override
  String get todayDiscardTitle => 'Schicht verwerfen?';

  @override
  String get todayDiscardMessage =>
      'Die laufende Schicht wird nicht gespeichert. Direkt danach kannst du das noch rückgängig machen.';

  @override
  String get shiftsAddShift => 'Schicht';

  @override
  String get shiftsAddShiftTooltip => 'Schicht hinzufügen';

  @override
  String get shiftsFilterLabel => 'Schichten anzeigen';

  @override
  String shiftsRunningSince(String time) {
    return 'Läuft seit $time';
  }

  @override
  String shiftsPausedSince(String time) {
    return 'Pausiert seit $time';
  }

  @override
  String get shiftsRunningOpenToday => 'Auf „Heute“ öffnen';

  @override
  String shiftsMonthOpen(String amount) {
    return '$amount offen';
  }

  @override
  String shiftsBreak(String duration) {
    return 'Pause $duration';
  }

  @override
  String shiftsTips(String amount) {
    return 'Trinkgeld $amount';
  }

  @override
  String shiftsTimeRangeSpoken(String start, String end) {
    return '$start bis $end';
  }

  @override
  String shiftsTimeRangeSpokenNextDay(String start, String end) {
    return '$start bis $end am nächsten Tag';
  }

  @override
  String get shiftsEmptyTitle => 'Noch keine Schichten';

  @override
  String get shiftsEmptyMessage =>
      'Starte eine Schicht auf „Heute“ oder trag eine nach, die du schon gearbeitet hast.';

  @override
  String get shiftsStartShift => 'Schicht starten';

  @override
  String get shiftsAddPastShift => 'Schicht nachtragen';

  @override
  String get shiftsEmptyOpenTitle => 'Keine offenen Schichten';

  @override
  String get shiftsEmptyOpenMessage => 'Alles ist bezahlt.';

  @override
  String get shiftsEmptyPaidTitle => 'Noch keine bezahlten Schichten';

  @override
  String get shiftsEmptyPaidMessage =>
      'Markier Schichten als bezahlt oder erfasse eine Auszahlung.';

  @override
  String get shiftsShowAll => 'Alle Schichten anzeigen';

  @override
  String get shiftsMarkPaid => 'Als bezahlt markieren';

  @override
  String get shiftsMarkOpen => 'Als offen markieren';

  @override
  String get shiftsMarkedPaid => 'Als bezahlt markiert';

  @override
  String get shiftsMarkedOpen => 'Als offen markiert';

  @override
  String get shiftsDeleted => 'Schicht gelöscht';

  @override
  String shiftsSaved(String duration, String amount) {
    return 'Schicht gespeichert · $duration · $amount';
  }

  @override
  String get shiftsErrorNotFound => 'Diese Schicht gibt es nicht mehr.';

  @override
  String get shiftsErrorRunning =>
      'Die laufende Schicht kannst du auf „Heute“ ändern.';

  @override
  String get shiftsErrorAlreadyRunning => 'Es läuft schon eine andere Schicht.';

  @override
  String get shiftsErrorJobNotFound => 'Diesen Job gibt es nicht mehr.';

  @override
  String get shiftsErrorNoWage =>
      'Für diesen Job ist noch kein Stundenlohn hinterlegt.';

  @override
  String get shiftsErrorInvalid => 'Bitte prüf deine Eingaben.';

  @override
  String get editorTitleNew => 'Neue Schicht';

  @override
  String get editorTitleEdit => 'Schicht bearbeiten';

  @override
  String get editorJob => 'Job';

  @override
  String get editorDate => 'Datum';

  @override
  String get editorPickDate => 'Datum wählen';

  @override
  String get editorStart => 'Start';

  @override
  String get editorEnd => 'Ende';

  @override
  String get editorEndsNextDay => 'Endet am nächsten Tag';

  @override
  String get editorEndsNextDayAuto =>
      'Automatisch eingeschaltet, weil das Ende vor dem Start liegt';

  @override
  String get editorBreak => 'Pause';

  @override
  String editorBreakLess(int minutes) {
    return '$minutes Minuten weniger Pause';
  }

  @override
  String editorBreakMore(int minutes) {
    return '$minutes Minuten mehr Pause';
  }

  @override
  String get editorBreakInvalid => 'Gib die Pause in ganzen Minuten ein';

  @override
  String get editorTips => 'Trinkgeld';

  @override
  String get editorNote => 'Notiz';

  @override
  String get editorStatus => 'Status';

  @override
  String editorPreview(String duration, String rate, String amount) {
    return '$duration × $rate = $amount';
  }

  @override
  String editorPreviewSpoken(String duration, String rate, String amount) {
    return '$duration zu $rate ergibt $amount';
  }

  @override
  String editorPreviewTips(String amount) {
    return 'plus $amount Trinkgeld';
  }

  @override
  String get editorErrorEndNotAfterStart =>
      'Das Ende muss nach dem Start liegen.';

  @override
  String get editorErrorBreakTooLong =>
      'Die Pause muss kürzer als die Schicht sein.';

  @override
  String editorWarningLong(String duration) {
    return 'Länger als 16 Stunden ($duration)';
  }

  @override
  String editorWarningOverlap(String date, String time) {
    return 'Überschneidet sich mit $date · $time';
  }

  @override
  String editorWarningOverlapRunning(String time) {
    return 'Überschneidet sich mit der laufenden Schicht (seit $time)';
  }

  @override
  String get editorWarningFuture => 'Beginnt in der Zukunft';

  @override
  String get editorConfirmTitle => 'Trotzdem speichern?';

  @override
  String get editorConfirmSave => 'Trotzdem speichern';

  @override
  String get editorDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get editorDiscardMessage =>
      'Deine Änderungen an dieser Schicht gehen verloren.';

  @override
  String get editorKeepEditing => 'Weiter bearbeiten';

  @override
  String get editorCopyNotice =>
      'Kopie für heute angelegt. Pass sie an oder lösch sie wieder.';

  @override
  String get payoutTitle => 'Auszahlung erfassen';

  @override
  String get payoutAllJobs => 'Alle Jobs';

  @override
  String get payoutUntil => 'Bis einschließlich';

  @override
  String payoutSummary(int count, String hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten',
      one: '1 Schicht',
    );
    return '$_temp0 · $hours';
  }

  @override
  String get payoutExpected => 'Erwartet';

  @override
  String get payoutReceived => 'Erhalten';

  @override
  String get payoutDifference => 'Differenz';

  @override
  String payoutDifferencePositive(String amount) {
    return '+$amount';
  }

  @override
  String get payoutPaidOn => 'Ausgezahlt am';

  @override
  String payoutSubmit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten als bezahlt markieren',
      one: '1 Schicht als bezahlt markieren',
    );
    return '$_temp0';
  }

  @override
  String get payoutNothingOpen =>
      'Bis zu diesem Datum gibt es keine offenen Schichten.';

  @override
  String payoutRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten als bezahlt markiert',
      one: '1 Schicht als bezahlt markiert',
    );
    return '$_temp0';
  }

  @override
  String get payoutErrorAmount => 'Der erhaltene Betrag ist ungültig.';

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
