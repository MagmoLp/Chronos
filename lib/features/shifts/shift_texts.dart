import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/time.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../domain/validation.dart';
import '../../l10n/app_localizations.dart';

/// Presentation helpers shared by the Shifts list, the editor and the payout
/// sheet (text only, no business rules).
class ShiftTexts {
  /// Creates the helper for one build.
  ShiftTexts(this.l10n, this.fmt);

  /// Helper for [context].
  factory ShiftTexts.of(BuildContext context) =>
      ShiftTexts(AppLocalizations.of(context), Fmt.of(context));

  /// Strings.
  final AppLocalizations l10n;

  /// Formatter.
  final Fmt fmt;

  /// Separator between summary parts ("7:45 h · 116,25 €").
  static const String separator = ' · ';

  /// Break length in whole minutes (rounded half-up, for display).
  static int breakMinutes(int breakMs) =>
      (breakMs + msPerMinute ~/ 2) ~/ msPerMinute;

  /// "08:00–16:15" ("+1" when the end is on a later day).
  String timeRange(Shift shift) =>
      fmt.timeRange(shift.startUtc.toLocal(), shift.endUtc!.toLocal());

  /// "08:00–16:15 · 7:45 h".
  String title(Shift shift) =>
      '${timeRange(shift)}$separator${fmt.durationHm(shift.workedMs)}';

  /// Secondary facts of a shift: job, break, tips, note.
  List<String> details(Shift shift, {String? jobName}) => <String>[
    ?jobName,
    if (shift.breakMs > 0)
      l10n.shiftsBreak(fmt.minutes(breakMinutes(shift.breakMs))),
    if (shift.tipsCents > 0) l10n.shiftsTips(fmt.money(shift.tipsCents)),
    if (shift.note case final note? when note.trim().isNotEmpty)
      note.trim().replaceAll(RegExp(r'\s+'), ' '),
  ];

  /// Spoken time range: "08:00 bis 16:15 (am nächsten Tag)".
  String timeRangeSpoken(Shift shift) {
    final start = shift.startUtc.toLocal();
    final end = shift.endUtc!.toLocal();
    return shift.endsOnLaterDay
        ? l10n.shiftsTimeRangeSpokenNextDay(fmt.time(start), fmt.time(end))
        : l10n.shiftsTimeRangeSpoken(fmt.time(start), fmt.time(end));
  }

  /// Full screen-reader label of a shift row.
  String rowLabel(Shift shift, {String? jobName}) => <String>[
    fmt.dateLong(shift.startUtc.toLocal()),
    timeRangeSpoken(shift),
    fmt.durationSpoken(shift.workedMs),
    ...details(shift, jobName: jobName),
    fmt.money(shift.earnedCents),
    shift.isPaid ? l10n.statusPaid : l10n.statusOpen,
  ].join(', ');

  /// Month header summary: "42,5 h · 637,50 € · 318,75 € offen".
  String monthSummary({
    required int workedMs,
    required int earnedCents,
    required int openCents,
  }) => <String>[
    fmt.hours(workedMs),
    fmt.money(earnedCents),
    if (openCents > 0) l10n.shiftsMonthOpen(fmt.money(openCents)),
  ].join(separator);

  /// Text of an editor validation error.
  String error(ShiftError error) => switch (error) {
    ShiftError.endNotAfterStart => l10n.editorErrorEndNotAfterStart,
    ShiftError.breakNotShorterThanDuration => l10n.editorErrorBreakTooLong,
    ShiftError.negativeBreak ||
    ShiftError.negativeTips => l10n.shiftsErrorInvalid,
  };

  /// Text of an editor validation warning (names the overlapping shift).
  String warning(ShiftWarning warning) => switch (warning) {
    LongerThan16h(:final durationMs) => l10n.editorWarningLong(
      fmt.durationHm(durationMs),
    ),
    OverlapsWith(:final shift) when shift.endUtc == null =>
      l10n.editorWarningOverlapRunning(fmt.time(shift.startUtc.toLocal())),
    OverlapsWith(:final shift) => l10n.editorWarningOverlap(
      fmt.dateShort(shift.startUtc.toLocal()),
      timeRange(shift),
    ),
    StartsInFuture() => l10n.editorWarningFuture,
  };
}

/// Theme colour of [job] (stored as the light palette value; mapped to the
/// palette of the current brightness).
Color jobColorOf(BuildContext context, Job job) {
  final colors = ChronosColors.of(context);
  final index = ChronosColors.light.jobPalette.indexWhere(
    (c) => c.toARGB32() == job.colorArgb,
  );
  return index >= 0 ? colors.jobColor(index) : Color(job.colorArgb);
}
