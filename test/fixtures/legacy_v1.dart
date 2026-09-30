import 'dart:convert';

/// Realistic v1.0.0 shared_preferences values (format of
/// `lib/services/storage_service.dart`, `lib/models/*.dart` in tag v1.0.0).
///
/// Timestamps are local wall-clock ISO strings without offset, exactly as
/// `DateTime.toIso8601String()` wrote them on the phone.
abstract final class LegacyV1 {
  /// v1 settings: German, dark, 15,00 €/h.
  static const String settingsGerman =
      '{"language":"german","theme":"dark","hourlyWage":15.0}';

  /// v1 settings after the comma bug: "12,50" became 1250 €/h.
  static const String settings1250 =
      '{"language":"english","theme":"light","hourlyWage":1250.0}';

  /// A running v1 session.
  static const String activeSession = '2026-09-30T07:45:00.000';

  /// Millisecond-timestamp id of a timer entry (used twice: duplicate id).
  static const String timerId = '1716712345678';

  /// UUID id of a manual entry.
  static const String manualId = '3f1c2a9e-5b7d-4c1e-9a2f-6d8e0b4c7a11';

  static Map<String, Object?> _entry(
    String? id,
    String start,
    String end, {
    Object? isPaid = false,
    bool withPaid = true,
  }) => {
    'id': ?id,
    'date': start.length >= 10
        ? '${start.substring(0, 10)}T00:00:00.000'
        : start,
    'startTime': start,
    'endTime': end,
    if (withPaid) 'isPaid': isPaid,
  };

  /// The elements of `work_entries`, in storage order.
  static final List<Object?> entries = [
    // 0: normal timer entry (8:15 h), unpaid.
    _entry(timerId, '2026-05-26T08:00:00.000', '2026-05-26T16:15:00.000'),
    // 1: manual entry with UUID, paid.
    _entry(
      manualId,
      '2026-05-27T09:00:00.000',
      '2026-05-27T13:30:00.000',
      isPaid: true,
    ),
    // 2: night shift over midnight.
    _entry(
      '1716900000000',
      '2026-06-05T22:00:00.000',
      '2026-06-06T06:00:00.000',
    ),
    // 3: typo end 08:00 < start 09:00 silently became a 23 h shift in v1.
    _entry(
      '1717000000000',
      '2026-06-10T09:00:00.000',
      '2026-06-11T08:00:00.000',
    ),
    // 4: shift on the spring DST switch day.
    _entry(
      '1711700000000',
      '2026-03-29T08:00:00.000',
      '2026-03-29T16:00:00.000',
    ),
    // 5: night shift into the autumn DST switch (2025).
    _entry(
      '1761400000000',
      '2025-10-25T22:00:00.000',
      '2025-10-26T06:00:00.000',
    ),
    // 6: duplicate id (v1 overwrote by id).
    _entry(timerId, '2026-05-28T08:00:00.000', '2026-05-28T12:00:00.000'),
    // 7: exact duplicate of entry 0 (double tap on save).
    _entry(
      '9b1f0d2e-1111-4a4a-8b8b-000000000001',
      '2026-05-26T08:00:00.000',
      '2026-05-26T16:15:00.000',
    ),
    // 8: isPaid missing (old entries).
    _entry(
      '1717100000000',
      '2026-06-12T10:00:00.000',
      '2026-06-12T14:00:00.000',
      withPaid: false,
    ),
    // 9: corrupted start time.
    _entry('1717200000000', 'kaputt', '2026-06-13T14:00:00.000'),
    // 10: end time missing.
    {'id': '1717300000000', 'startTime': '2026-06-14T10:00:00.000'},
    // 11: not an object at all.
    42,
    // 12: end before start.
    _entry('x', '2026-06-15T10:00:00.000', '2026-06-15T09:00:00.000'),
    // 13: id missing, paid.
    _entry(
      null,
      '2026-06-16T10:00:00.000',
      '2026-06-16T12:00:00.000',
      isPaid: true,
    ),
  ];

  /// The `work_entries` string.
  static final String workEntries = jsonEncode(entries);

  /// Number of importable entries in [entries].
  static const int importable = 10;

  /// Number of broken entries in [entries].
  static const int broken = 4;
}
