import '../core/local_date.dart';

/// An hourly wage of a job, valid from [validFrom] until the next rate.
final class WageRate {
  /// Creates a wage rate.
  const WageRate({
    required this.id,
    required this.jobId,
    required this.validFrom,
    required this.centsPerHour,
  });

  /// Database id.
  final int id;

  /// Job this rate belongs to.
  final int jobId;

  /// First local date on which this rate applies.
  final LocalDate validFrom;

  /// Wage in cents per hour.
  final int centsPerHour;

  /// Copy with the given fields replaced.
  WageRate copyWith({
    int? id,
    int? jobId,
    LocalDate? validFrom,
    int? centsPerHour,
  }) => WageRate(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    validFrom: validFrom ?? this.validFrom,
    centsPerHour: centsPerHour ?? this.centsPerHour,
  );

  @override
  bool operator ==(Object other) =>
      other is WageRate &&
      other.id == id &&
      other.jobId == jobId &&
      other.validFrom == validFrom &&
      other.centsPerHour == centsPerHour;

  @override
  int get hashCode => Object.hash(id, jobId, validFrom, centsPerHour);

  @override
  String toString() =>
      'WageRate(job $jobId, $centsPerHour ct/h from $validFrom)';
}

/// The rate (cents/hour) that applies on [date]: the rate with the latest
/// `validFrom` on or before [date].
///
/// Dates before the first rate fall back to the earliest rate, so backdated
/// shifts still get a wage. Returns `null` only if [rates] is empty.
int? rateForDate(Iterable<WageRate> rates, LocalDate date) =>
    wageRateForDate(rates, date)?.centsPerHour;

/// The [WageRate] entry that applies on [date] (same rule as
/// [rateForDate]), e.g. to show "15,00 €/h seit 01.01.2026".
WageRate? wageRateForDate(Iterable<WageRate> rates, LocalDate date) {
  WageRate? best;
  WageRate? earliest;
  for (final rate in rates) {
    if (earliest == null || rate.validFrom.isBefore(earliest.validFrom)) {
      earliest = rate;
    }
    if (rate.validFrom.isOnOrBefore(date) &&
        (best == null || rate.validFrom.isAfter(best.validFrom))) {
      best = rate;
    }
  }
  return best ?? earliest;
}
