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
}
