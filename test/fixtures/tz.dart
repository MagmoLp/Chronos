/// Time-zone helpers for tests that depend on the Europe/Berlin rules.
library;

/// Whether the test process runs with `TZ=Europe/Berlin` (or an equivalent
/// zone with the same 2026 rules: CET, CEST from 29 Mar to 25 Oct).
bool get isBerlinTz =>
    DateTime(2026, 1, 15, 12).timeZoneOffset == const Duration(hours: 1) &&
    DateTime(2026, 3, 28, 12).timeZoneOffset == const Duration(hours: 1) &&
    DateTime(2026, 3, 29, 12).timeZoneOffset == const Duration(hours: 2) &&
    DateTime(2026, 10, 24, 12).timeZoneOffset == const Duration(hours: 2) &&
    DateTime(2026, 10, 25, 12).timeZoneOffset == const Duration(hours: 1);

/// `skip:` value for tests that only make sense under Europe/Berlin.
Object get skipUnlessBerlin => isBerlinTz
    ? false
    : 'needs TZ=Europe/Berlin (run: TZ=Europe/Berlin flutter test)';
