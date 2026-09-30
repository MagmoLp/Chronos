import 'dart:convert';

import '../../core/money.dart';
import '../../domain/app_settings.dart';
import 'legacy_models.dart';

/// v1's default hourly wage (15,00 €) when `app_settings` is missing.
const int kLegacyDefaultWageCents = 1500;

/// Parses v1 `work_entries` element by element; one bad element never
/// affects the others.
///
/// v1 format: JSON list of `{id, date, startTime, endTime, isPaid}` with
/// local ISO timestamps without offset (`2026-05-26T08:00:00.000`). They are
/// read as device-local time and converted to UTC.
({List<ParsedLegacyEntry> entries, List<LegacyFailure> failures})
parseLegacyWorkEntries(Object? raw) {
  final entries = <ParsedLegacyEntry>[];
  final failures = <LegacyFailure>[];
  if (raw == null) return (entries: entries, failures: failures);

  Object? decoded;
  try {
    decoded = raw is String ? jsonDecode(raw) : raw;
  } on FormatException catch (e) {
    failures.add(
      LegacyFailure(
        origin: 'work_entries',
        raw: raw.toString(),
        code: LegacyErrorCode.invalidJson,
        message: e.message,
      ),
    );
    return (entries: entries, failures: failures);
  }
  if (decoded is! List) {
    failures.add(
      LegacyFailure(
        origin: 'work_entries',
        raw: _encode(raw),
        code: LegacyErrorCode.notAList,
      ),
    );
    return (entries: entries, failures: failures);
  }

  for (var i = 0; i < decoded.length; i++) {
    final element = decoded[i];
    final origin = 'work_entries[$i]';
    final rawElement = _encode(element);
    LegacyFailure fail(LegacyErrorCode code, [String? message]) =>
        LegacyFailure(
          origin: origin,
          raw: rawElement,
          code: code,
          message: message,
        );
    try {
      if (element is! Map) {
        failures.add(fail(LegacyErrorCode.notAnObject));
        continue;
      }
      final startRaw = element['startTime'];
      if (startRaw == null) {
        failures.add(fail(LegacyErrorCode.missingStartTime));
        continue;
      }
      final start = _parseDateTime(startRaw);
      if (start == null) {
        failures.add(fail(LegacyErrorCode.invalidStartTime, '$startRaw'));
        continue;
      }
      final endRaw = element['endTime'];
      if (endRaw == null) {
        failures.add(fail(LegacyErrorCode.missingEndTime));
        continue;
      }
      final end = _parseDateTime(endRaw);
      if (end == null) {
        failures.add(fail(LegacyErrorCode.invalidEndTime, '$endRaw'));
        continue;
      }
      if (!end.isAfter(start)) {
        failures.add(fail(LegacyErrorCode.endNotAfterStart));
        continue;
      }
      final id = element['id'];
      entries.add(
        ParsedLegacyEntry(
          origin: origin,
          raw: rawElement,
          legacyId: id?.toString(),
          startUtc: start,
          endUtc: end,
          isPaid: _parseBool(element['isPaid']),
        ),
      );
    } on Object catch (e) {
      failures.add(fail(LegacyErrorCode.notAnObject, e.toString()));
    }
  }
  return (entries: entries, failures: failures);
}

/// Parses v1 `app_settings` (`{language, theme, hourlyWage}`).
///
/// Missing settings mean v1 defaults (15,00 €/h). Unreadable settings also
/// fall back to 15,00 €/h and are reported as a failure.
({int wageCents, AppLanguage? language, LegacyFailure? failure})
parseLegacySettings(Object? raw) {
  if (raw == null) {
    return (wageCents: kLegacyDefaultWageCents, language: null, failure: null);
  }
  LegacyFailure fail(String? message) => LegacyFailure(
    origin: 'app_settings',
    raw: _encode(raw),
    code: LegacyErrorCode.invalidSettings,
    message: message,
  );
  try {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) {
      return (
        wageCents: kLegacyDefaultWageCents,
        language: null,
        failure: fail('not an object'),
      );
    }
    final language = switch (decoded['language']) {
      'german' => AppLanguage.de,
      'english' => AppLanguage.en,
      _ => null,
    };
    final wageRaw = decoded['hourlyWage'];
    if (wageRaw == null) {
      return (
        wageCents: kLegacyDefaultWageCents,
        language: language,
        failure: null,
      );
    }
    final wage = switch (wageRaw) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.trim().replaceAll(',', '.')),
      _ => null,
    };
    if (wage == null || wage.isNaN || wage.isInfinite || wage < 0) {
      return (
        wageCents: kLegacyDefaultWageCents,
        language: language,
        failure: fail('hourlyWage: $wageRaw'),
      );
    }
    return (wageCents: centsFromEuros(wage), language: language, failure: null);
  } on Object catch (e) {
    return (
      wageCents: kLegacyDefaultWageCents,
      language: null,
      failure: fail(e.toString()),
    );
  }
}

/// Parses v1 `active_session` (local ISO start of the running session).
({DateTime? startUtc, LegacyFailure? failure}) parseLegacyActiveSession(
  Object? raw,
) {
  if (raw == null) return (startUtc: null, failure: null);
  final start = _parseDateTime(raw);
  if (start == null) {
    return (
      startUtc: null,
      failure: LegacyFailure(
        origin: 'active_session',
        raw: _encode(raw),
        code: LegacyErrorCode.invalidActiveSession,
      ),
    );
  }
  return (startUtc: start, failure: null);
}

/// ISO string → UTC instant. Strings without offset are device-local time
/// (v1 format); strings with `Z`/offset are respected.
DateTime? _parseDateTime(Object? value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value.trim());
  return parsed?.toUtc();
}

bool _parseBool(Object? value) => switch (value) {
  true => true,
  'true' => true,
  1 => true,
  _ => false,
};

String _encode(Object? value) {
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } on Object {
    return value.toString();
  }
}
