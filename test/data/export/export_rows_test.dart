import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/export/export.dart';
import 'package:chronos/domain/job.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/shifts.dart';

void main() {
  const jobs = [
    Job(id: 1, uuid: 'a', name: 'Catering', colorArgb: kDefaultJobColorArgb),
    Job(id: 2, uuid: 'b', name: 'Bar', colorArgb: kDefaultJobColorArgb),
  ];

  final nightShift = doneShift(
    id: 3,
    start: local(2026, 9, 29, 18),
    end: local(2026, 9, 30, 2),
    breakMs: 30 * 60000,
    tips: 250,
    paid: true,
    note: 'Gala',
  );
  final early = doneShift(
    id: 1,
    start: local(2026, 9, 28, 8),
    end: local(2026, 9, 28, 16, 15),
  );
  final otherJob = doneShift(
    id: 2,
    jobId: 2,
    start: local(2026, 9, 28, 17),
    end: local(2026, 9, 28, 20),
  );
  final deleted = doneShift(
    id: 4,
    start: local(2026, 9, 27, 8),
    end: local(2026, 9, 27, 9),
    deletedAt: local(2026, 9, 30),
  );

  test('oldest first, deleted shifts dropped, job names resolved', () {
    final rows = exportRowsFromShifts([
      nightShift,
      otherJob,
      deleted,
      early,
    ], jobs: jobs);
    expect(rows.map((r) => r.jobName), ['Catering', 'Bar', 'Catering']);
    expect(rows.first.date, LocalDate(2026, 9, 28));
    expect(rows.first.start, DateTime(2026, 9, 28, 8));
    expect(rows.first.workedMs, 8 * 3600000 + 15 * 60000);
    expect(rows.first.amountCents, 12375);

    final night = rows.last;
    expect(night.endsNextDay, isTrue);
    expect(night.breakMinutes, 30);
    expect(night.workedMs, 7 * 3600000 + 30 * 60000);
    expect(night.amountCents, 11250);
    expect(night.tipsCents, 250);
    expect(night.paid, isTrue);
    expect(night.note, 'Gala');
  });

  test('filters by job and falls back for unknown jobs', () {
    final rows = exportRowsFromShifts(
      [nightShift, otherJob, early],
      jobs: jobs.take(1),
      jobId: 2,
      unknownJobName: '?',
    );
    expect(rows, hasLength(1));
    expect(rows.single.jobName, '?');
  });

  test('totals sum exact values', () {
    final rows = exportRowsFromShifts([nightShift, early, otherJob], jobs: jobs);
    final totals = ExportTotals.of(rows);
    expect(totals.count, 3);
    expect(totals.breakMinutes, 30);
    expect(totals.workedMs, 67500000);
    expect(totals.amountCents, 12375 + 4500 + 11250);
    expect(totals.tipsCents, 250);
    expect(ExportTotals.of(const []).isEmpty, isTrue);
  });

  test('rounding helpers are half-up', () {
    expect(roundedMinutes(29999), 0);
    expect(roundedMinutes(30000), 1);
    expect(hundredthsOfHour(27900000), 775);
    expect(hundredthsOfHour(18000), 1); // 0.005 h rounds up
    expect(hundredthsOfHour(17999), 0);
  });
}
