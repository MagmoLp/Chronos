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
}
