import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../core/time.dart';
import '../../data/export/export.dart';
import '../../l10n/app_localizations.dart';

/// "01.09.2026 – 30.09.2026" for an export range.
String exportRangeText(AppLocalizations l10n, Fmt fmt, LocalDateRange range) =>
    l10n.exportRangeValue(
      fmt.dateNumeric(range.start.toLocalDateTime()),
      fmt.dateNumeric(range.endInclusive.toLocalDateTime()),
    );

/// Localized CSV header and status texts.
CsvLabels csvLabelsFor(AppLocalizations l10n) => CsvLabels(
  date: l10n.exportColDate,
  start: l10n.exportColStart,
  end: l10n.exportColEnd,
  breakMinutes: l10n.exportColBreakMinutes,
  hours: l10n.exportColHours,
  rate: l10n.exportColRate,
  amount: l10n.exportColAmount,
  tips: l10n.exportColTips,
  status: l10n.exportColStatus,
  job: l10n.exportColJob,
  note: l10n.exportColNote,
  paid: l10n.statusPaid,
  open: l10n.statusOpen,
  total: l10n.exportTotal,
);

/// Localized PDF texts.
TimesheetLabels timesheetLabelsFor(AppLocalizations l10n) => TimesheetLabels(
  title: l10n.exportPdfTitle,
  name: l10n.exportPdfName,
  job: l10n.exportColJob,
  period: l10n.exportPdfPeriod,
  date: l10n.exportColDate,
  start: l10n.exportColStart,
  end: l10n.exportColEnd,
  breakTime: l10n.exportColBreak,
  hours: l10n.exportColHours,
  rate: l10n.exportColRateShort,
  amount: l10n.exportColAmount,
  note: l10n.exportColNote,
  total: l10n.exportTotal,
  signatureEmployee: l10n.exportPdfSignatureEmployee,
  signatureEmployer: l10n.exportPdfSignatureEmployer,
  createdOn: l10n.exportPdfCreatedOn,
  pageOf: l10n.exportPdfPage,
);

/// Locale-aware value formatting for the PDF, backed by [Fmt].
TimesheetFormat timesheetFormatFor(AppLocalizations l10n, Fmt fmt) =>
    TimesheetFormat(
      date: (d) => fmt.dateNumeric(d.toLocalDateTime()),
      rowDate: (d) => l10n.exportPdfRowDate(
        fmt.weekdayShort(d.toLocalDateTime()),
        fmt.dateNumeric(d.toLocalDateTime()),
      ),
      time: fmt.time,
      hours: (ms) => fmt.hoursDecimal(ms, minFractionDigits: 2),
      minutes: fmt.minutes,
      money: fmt.money,
    );

/// File name of an export, e.g. `chronos_stundenzettel_2026-09-01_2026-09-30.pdf`.
String exportFileName(
  AppLocalizations l10n,
  LocalDateRange range,
  String extension,
) =>
    'chronos_${l10n.exportFileBase}_${range.start.toIso8601String()}_'
    '${range.endInclusive.toIso8601String()}.$extension';

/// The export range presets of the sheet.
enum ExportRangePreset {
  /// Monday–Sunday of today.
  thisWeek,

  /// The current calendar month.
  thisMonth,

  /// The previous calendar month.
  lastMonth,

  /// A range picked with the date range picker.
  custom;

  /// The range of this preset relative to [today] (`null` for [custom]).
  LocalDateRange? rangeFor(LocalDate today) => switch (this) {
    thisWeek => LocalDateRange.week(today),
    thisMonth => LocalDateRange.monthOf(today),
    lastMonth => LocalDateRange.monthOf(today.firstOfMonth.addMonths(-1)),
    custom => null,
  };

  /// The preset whose range is [range] on [today], else [custom].
  static ExportRangePreset match(LocalDateRange range, LocalDate today) {
    for (final preset in values) {
      if (preset.rangeFor(today) == range) return preset;
    }
    return custom;
  }
}
